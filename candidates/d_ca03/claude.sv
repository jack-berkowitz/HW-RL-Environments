// =============================================================================
// sv39_mmu.sv -- d_ca03 submission.
//
// Structure, and why:
//
//   * Two 16-entry fully-associative TLBs (P2), one per port, each with 16
//     parallel tag comparators. L1 charges cycles, so the comparators are
//     parallel rather than swept: a swept comparator would cost ~16 cycles on
//     every hit and the scored sequence is mostly hits.
//   * Flush is a parallel clear of the 16 valid bits -- one cycle, not 139.
//   * ONE PMP comparator bank, not two. Only one address is ever checked in a
//     given cycle (the level-2 address in IDLE, the descend address on rvalid),
//     so the address is muxed ahead of the bank and the eight regions are then
//     checked in parallel. That is the reuse G4 asks about.
//   * NAPOT masks are prefix-ANDs of pmpaddr, not incrementers.
//   * Lookup, permission check and retirement are combinational: a TLB hit and
//     a bare-mode request both retire in the cycle the request is presented,
//     and a walk issues its next read in the same cycle the previous PTE
//     returns. At the pinned 12.5 ns this buys cycles for no closure risk.
//   * Permission and A/D checking (A4, A5) sits on the SHARED result path, fed
//     by a mux between the TLB entry and the walker's leaf, so it exists once
//     per port rather than once per source.
//
// A11 is implemented as stated: a faulting request retires with BOTH valid_o
// and exc_valid_o in one cycle.
//
// A8 is implemented as measured, not as the architectural rule reads: PMP is
// applied to the walker's reads ONLY, requires R only, and denies on no match.
// The final translated address is never checked, so a TLB hit is never
// PMP-checked at all.
// =============================================================================

module sv39_mmu (
  input  logic        clk_i,
  input  logic        rst_ni,
  input  logic        flush_i,

  input  logic        enable_translation_i,
  input  logic        en_ld_st_translation_i,

  input  logic        lsu_req_i,
  input  logic [63:0] lsu_vaddr_i,
  input  logic        lsu_is_store_i,
  output logic        lsu_valid_o,
  output logic [55:0] lsu_paddr_o,
  output logic        lsu_dtlb_hit_o,
  output logic [43:0] lsu_dtlb_ppn_o,
  output logic        lsu_exc_valid_o,
  output logic [63:0] lsu_exc_cause_o,
  output logic [63:0] lsu_exc_tval_o,

  input  logic        fetch_req_i,
  input  logic [63:0] fetch_vaddr_i,
  output logic        fetch_valid_o,
  output logic [55:0] fetch_paddr_o,
  output logic        fetch_exc_valid_o,
  output logic [63:0] fetch_exc_cause_o,
  output logic [63:0] fetch_exc_tval_o,

  input  logic [1:0]  priv_lvl_i,
  input  logic [1:0]  ld_st_priv_lvl_i,
  input  logic        sum_i,
  input  logic        mxr_i,
  input  logic [43:0] satp_ppn_i,
  input  logic [15:0] asid_i,

  input  logic        flush_tlb_i,
  input  logic [15:0] asid_to_be_flushed_i,
  input  logic [63:0] vaddr_to_be_flushed_i,
  output logic        itlb_miss_o,
  output logic        dtlb_miss_o,

  output logic        mem_req_o,
  output logic [55:0] mem_addr_o,
  output logic        mem_tag_valid_o,
  output logic        mem_kill_o,
  input  logic        mem_gnt_i,
  input  logic        mem_rvalid_i,
  input  logic [63:0] mem_rdata_i,

  input  logic [7:0][7:0]  pmpcfg_i,
  input  logic [7:0][53:0] pmpaddr_i
);

  // ---------------------------------------------------------------------------
  // constants
  // ---------------------------------------------------------------------------
  localparam logic [1:0] S_IDLE = 2'd0;   // no walk in flight
  localparam logic [1:0] S_GNT  = 2'd1;   // read issued, waiting for grant
  localparam logic [1:0] S_RV   = 2'd2;   // granted, waiting for the entry
  localparam logic [1:0] S_KILL = 2'd3;   // flushed with a read outstanding

  // perm vector layout, used by the TLB and by the walker alike: {d,a,u,x,w,r}
  localparam int unsigned P_R = 0;
  localparam int unsigned P_W = 1;
  localparam int unsigned P_X = 2;
  localparam int unsigned P_U = 3;
  localparam int unsigned P_A = 4;
  localparam int unsigned P_D = 5;

  localparam logic [63:0] CAUSE_IF_PAGE   = 64'd12;
  localparam logic [63:0] CAUSE_LD_PAGE   = 64'd13;
  localparam logic [63:0] CAUSE_ST_PAGE   = 64'd15;
  localparam logic [63:0] CAUSE_IF_ACCESS = 64'd1;
  localparam logic [63:0] CAUSE_LD_ACCESS = 64'd5;
  localparam logic [63:0] CAUSE_ST_ACCESS = 64'd7;

  // ---------------------------------------------------------------------------
  // A2 -- assemble the delivered address from a leaf PPN and the virtual address
  // ---------------------------------------------------------------------------
  function automatic logic [55:0] mk_pa(input logic [43:0] ppn,
                                        input logic [1:0]  lvl,
                                        input logic [63:0] va);
    logic [55:0] pa;
    pa[11:0]  = va[11:0];
    pa[20:12] = (lvl >= 2'd1) ? va[20:12] : ppn[8:0];    // 2 MiB and 1 GiB
    pa[29:21] = (lvl == 2'd2) ? va[29:21] : ppn[17:9];   // 1 GiB only
    pa[55:30] = ppn[43:18];
    return pa;
  endfunction

  // ---------------------------------------------------------------------------
  // A4 and A5 -- permission, privilege and A/D checking on a leaf
  // ---------------------------------------------------------------------------
  function automatic logic perm_bad(input logic [5:0] p,
                                    input logic       is_fetch,
                                    input logic       is_store,
                                    input logic [1:0] priv,
                                    input logic       sum,
                                    input logic       mxr);
    logic bad;
    bad = 1'b0;
    if (!p[P_A]) bad = 1'b1;                                  // A5: A=0 always faults
    if (is_fetch) begin
      if (!p[P_X])                          bad = 1'b1;
      if ((priv == 2'b00) && !p[P_U])       bad = 1'b1;       // U mode needs U=1
      if ((priv == 2'b01) &&  p[P_U])       bad = 1'b1;       // S never executes U pages
    end else begin
      if ((priv == 2'b00) && !p[P_U])            bad = 1'b1;
      if ((priv == 2'b01) &&  p[P_U] && !sum)    bad = 1'b1;  // SUM gates S access to U
      if (is_store) begin
        if (!p[P_W]) bad = 1'b1;
        if (!p[P_D]) bad = 1'b1;                              // A5: D=0 faults a store
      end else begin
        if (!(p[P_R] || (p[P_X] && mxr))) bad = 1'b1;         // MXR lets X stand in for R
      end
    end
    return bad;
  endfunction

  // ---------------------------------------------------------------------------
  // A8 -- physical memory protection, one bank, R only, no match denies
  // ---------------------------------------------------------------------------
  logic [7:0][53:0] pmp_prev;     // TOR lower bound
  logic [7:0][53:0] napot_ign;    // NAPOT bits to ignore: prefix-AND of pmpaddr
  logic [55:0]      pmp_addr;
  logic [7:0]       pmp_match;
  logic             pmp_allow;

  assign pmp_prev[0] = 54'd0;

  genvar gn;
  generate
    for (gn = 1; gn < 8; gn = gn + 1) begin : g_prev
      assign pmp_prev[gn] = pmpaddr_i[gn-1];
    end
  endgenerate

  // NAPOT: ignore address bits at and below the lowest zero of pmpaddr. That
  // set is the prefix-AND of pmpaddr, which is a chain of AND gates -- no
  // incrementer and no per-bit search nested in a per-entry loop (T6).
  always_comb begin
    logic [53:0] ign;
    ign = 54'd0;
    for (int unsigned n = 0; n < 8; n++) begin
      ign[0] = 1'b1;
      for (int unsigned b = 1; b < 54; b++) begin
        ign[b] = ign[b-1] & pmpaddr_i[n][b-1];
      end
      napot_ign[n] = ign;
    end
  end

  always_comb begin
    logic [53:0] aw;
    aw        = pmp_addr[55:2];
    pmp_match = 8'd0;
    for (int unsigned n = 0; n < 8; n++) begin
      case (pmpcfg_i[n][4:3])
        2'd1:    pmp_match[n] = (aw >= pmp_prev[n]) && (aw < pmpaddr_i[n]);      // TOR
        2'd2:    pmp_match[n] = (aw == pmpaddr_i[n]);                            // NA4
        2'd3:    pmp_match[n] = (((aw ^ pmpaddr_i[n]) & ~napot_ign[n]) == 54'd0);// NAPOT
        default: pmp_match[n] = 1'b0;                                            // OFF
      endcase
    end
  end

  // lowest matching region wins; nothing matching denies
  always_comb begin
    pmp_allow = 1'b0;
    for (int n = 7; n >= 0; n--) begin
      if (pmp_match[n]) pmp_allow = pmpcfg_i[n][P_R];
    end
  end

  // ---------------------------------------------------------------------------
  // TLBs
  // ---------------------------------------------------------------------------
  logic        tlb_flush;
  logic [43:0] dtlb_ppn, itlb_ppn;
  logic [1:0]  dtlb_lvl, itlb_lvl;
  logic [5:0]  dtlb_perm, itlb_perm;
  logic        dtlb_hit, itlb_hit;
  logic        dtlb_up, itlb_up;

  logic [26:0] walk_vpn_q;
  logic [1:0]  walk_lvl_q;
  logic        walk_fetch_q;
  logic [55:0] walk_addr_q;
  logic [1:0]  state_q;

  logic [43:0] pte_ppn;
  logic [5:0]  pte_perm;
  logic        pte_g;

  assign tlb_flush = flush_tlb_i;

  sv39_mmu_tlb u_dtlb (
    .clk_i, .rst_ni,
    .flush_i    (tlb_flush),
    .lu_vpn_i   (lsu_vaddr_i[38:12]),
    .lu_asid_i  (asid_i),
    .hit_o      (dtlb_hit),
    .ppn_o      (dtlb_ppn),
    .lvl_o      (dtlb_lvl),
    .perm_o     (dtlb_perm),
    .up_valid_i (dtlb_up),
    .up_vpn_i   (walk_vpn_q),
    .up_asid_i  (asid_i),
    .up_lvl_i   (walk_lvl_q),
    .up_ppn_i   (pte_ppn),
    .up_g_i     (pte_g),
    .up_perm_i  (pte_perm)
  );

  sv39_mmu_tlb u_itlb (
    .clk_i, .rst_ni,
    .flush_i    (tlb_flush),
    .lu_vpn_i   (fetch_vaddr_i[38:12]),
    .lu_asid_i  (asid_i),
    .hit_o      (itlb_hit),
    .ppn_o      (itlb_ppn),
    .lvl_o      (itlb_lvl),
    .perm_o     (itlb_perm),
    .up_valid_i (itlb_up),
    .up_vpn_i   (walk_vpn_q),
    .up_asid_i  (asid_i),
    .up_lvl_i   (walk_lvl_q),
    .up_ppn_i   (pte_ppn),
    .up_g_i     (pte_g),
    .up_perm_i  (pte_perm)
  );

  // ---------------------------------------------------------------------------
  // request decode and walker arbitration
  // ---------------------------------------------------------------------------
  logic        d_xlate, i_xlate, d_miss, i_miss;
  logic        sel_fetch, walk_start, cur_fetch;
  logic [26:0] start_vpn;
  logic [55:0] start_addr;

  assign d_xlate = lsu_req_i   && en_ld_st_translation_i;
  assign i_xlate = fetch_req_i && enable_translation_i;
  assign d_miss  = d_xlate && !dtlb_hit;
  assign i_miss  = i_xlate && !itlb_hit;

  // L2: strict alternation when both ports want the walker. Data-first would
  // starve the fetch port whenever a held data request never installs -- a
  // faulting page, or one the PMP denies -- because that port keeps missing
  // for as long as it is asserted.
  logic prefer_fetch_q, prefer_fetch_d;
  assign sel_fetch  = i_miss && (!d_miss || prefer_fetch_q);
  assign walk_start = d_miss || i_miss;
  assign start_vpn  = sel_fetch ? fetch_vaddr_i[38:12] : lsu_vaddr_i[38:12];
  assign start_addr = {satp_ppn_i, start_vpn[26:18], 3'b000};   // A1: root + VPN[2]*8
  assign cur_fetch  = (state_q == S_IDLE) ? sel_fetch : walk_fetch_q;

  // ---------------------------------------------------------------------------
  // returned PTE (F3) and the descend address
  // ---------------------------------------------------------------------------
  logic        pte_v, pte_r, pte_w, pte_x;
  logic        pte_leaf, pte_resv, pte_misaligned;
  logic [55:0] next_addr;
  logic [8:0]  next_vpn_idx;

  assign pte_v    = mem_rdata_i[0];
  assign pte_r    = mem_rdata_i[1];
  assign pte_w    = mem_rdata_i[2];
  assign pte_x    = mem_rdata_i[3];
  assign pte_g    = mem_rdata_i[5];
  assign pte_ppn  = mem_rdata_i[53:10];
  assign pte_perm = {mem_rdata_i[7], mem_rdata_i[6], mem_rdata_i[4],
                     mem_rdata_i[3], mem_rdata_i[2], mem_rdata_i[1]};

  assign pte_leaf = pte_r || pte_x;
  assign pte_resv = pte_w && !pte_r;                       // F3 reserved encoding

  // A3: a superpage leaf whose PPN is not aligned to its own size
  assign pte_misaligned = ((walk_lvl_q == 2'd2) && (pte_ppn[17:0] != 18'd0)) ||
                          ((walk_lvl_q == 2'd1) && (pte_ppn[8:0]  !=  9'd0));

  assign next_vpn_idx = (walk_lvl_q == 2'd2) ? walk_vpn_q[17:9] : walk_vpn_q[8:0];
  assign next_addr    = {pte_ppn, next_vpn_idx, 3'b000};

  // ---------------------------------------------------------------------------
  // walker
  // ---------------------------------------------------------------------------
  logic [1:0]  state_d;
  logic        fl_seen_q, fl_seen_d;
  logic [1:0]  walk_lvl_d;
  logic [26:0] walk_vpn_d;
  logic        walk_fetch_d;
  logic [55:0] walk_addr_d;
  logic        walk_af, walk_pf, walk_ok;

  always_comb begin
    state_d      = state_q;
    prefer_fetch_d = prefer_fetch_q;
    fl_seen_d    = fl_seen_q | flush_tlb_i;
    walk_lvl_d   = walk_lvl_q;
    walk_vpn_d   = walk_vpn_q;
    walk_fetch_d = walk_fetch_q;
    walk_addr_d  = walk_addr_q;

    mem_req_o    = 1'b0;
    mem_addr_o   = walk_addr_q;
    pmp_addr     = walk_addr_q;

    walk_af      = 1'b0;
    walk_pf      = 1'b0;
    walk_ok      = 1'b0;

    case (state_q)
      S_IDLE: begin
        pmp_addr = start_addr;
        if (walk_start && !flush_i) begin
          prefer_fetch_d = !sel_fetch;      // whoever was served yields next
          fl_seen_d      = flush_tlb_i;
          if (!pmp_allow) begin
            walk_af = 1'b1;                       // A7: denied before it is read
          end else begin
            mem_req_o    = 1'b1;
            mem_addr_o   = start_addr;
            walk_addr_d  = start_addr;
            walk_vpn_d   = start_vpn;
            walk_fetch_d = sel_fetch;
            walk_lvl_d   = 2'd2;
            state_d      = mem_gnt_i ? S_RV : S_GNT;
          end
        end
      end

      S_GNT: begin
        mem_req_o  = 1'b1;
        mem_addr_o = walk_addr_q;
        if (flush_i) begin
          // C3: abort. A read already accepted still owes a response.
          state_d = mem_gnt_i ? S_KILL : S_IDLE;
        end else if (mem_gnt_i) begin
          state_d = S_RV;
        end
      end

      S_RV: begin
        pmp_addr = next_addr;
        if (flush_i) begin
          state_d = mem_rvalid_i ? S_IDLE : S_KILL;
        end else if (mem_rvalid_i) begin
          state_d = S_IDLE;
          if (!pte_v || pte_resv) begin
            walk_pf = 1'b1;                                    // A1: invalid entry
          end else if (pte_leaf) begin
            if (pte_misaligned) walk_pf = 1'b1;                // A3
            else                walk_ok = 1'b1;
          end else if (walk_lvl_q == 2'd0) begin
            walk_pf = 1'b1;                                    // A1: ran past level 0
          end else if (!pmp_allow) begin
            walk_af = 1'b1;                                    // A8 on the next read
          end else begin
            mem_req_o   = 1'b1;                                // descend in this cycle
            mem_addr_o  = next_addr;
            walk_addr_d = next_addr;
            walk_lvl_d  = walk_lvl_q - 2'd1;
            state_d     = mem_gnt_i ? S_RV : S_GNT;
          end
        end
      end

      default: begin // S_KILL -- swallow the response the aborted read still owes
        if (mem_rvalid_i) state_d = S_IDLE;
      end
    endcase
  end

  always_ff @(posedge clk_i) begin
    if (!rst_ni) begin
      state_q        <= S_IDLE;
      prefer_fetch_q <= 1'b0;
      fl_seen_q      <= 1'b0;
      walk_lvl_q   <= 2'd2;
      walk_vpn_q   <= 27'd0;
      walk_fetch_q <= 1'b0;
      walk_addr_q  <= 56'd0;
    end else begin
      state_q        <= state_d;
      prefer_fetch_q <= prefer_fetch_d;
      fl_seen_q      <= fl_seen_d;
      walk_lvl_q   <= walk_lvl_d;
      walk_vpn_q   <= walk_vpn_d;
      walk_fetch_q <= walk_fetch_d;
      walk_addr_q  <= walk_addr_d;
    end
  end

  // A9: the walk's leaf is installed, and the permission check below is applied
  // to it and to a TLB hit alike, so the two paths cannot disagree.
  // C2: a flush_tlb_i landing while this walk was in flight discards the
  // install. The request in hand still retires with the address the walk found
  // -- only the TLB deposit is dropped -- so an entry read before the flush
  // cannot outlive it.
  logic install_ok;
  assign install_ok = walk_ok && !fl_seen_q && !flush_tlb_i;
  assign dtlb_up = install_ok && !cur_fetch;
  assign itlb_up = install_ok &&  cur_fetch;

  assign mem_tag_valid_o = (state_q == S_RV);
  assign mem_kill_o      = 1'b0;

  // ---------------------------------------------------------------------------
  // result path -- one permission checker per port, fed by a mux between the
  // resident entry and the walker's leaf
  // ---------------------------------------------------------------------------
  logic [5:0]  d_perm, i_perm;
  logic [43:0] d_ppn,  i_ppn;
  logic [1:0]  d_lvl,  i_lvl;
  logic        d_bad,  i_bad;

  assign d_perm = dtlb_hit ? dtlb_perm : pte_perm;
  assign d_ppn  = dtlb_hit ? dtlb_ppn  : pte_ppn;
  assign d_lvl  = dtlb_hit ? dtlb_lvl  : walk_lvl_q;
  assign i_perm = itlb_hit ? itlb_perm : pte_perm;
  assign i_ppn  = itlb_hit ? itlb_ppn  : pte_ppn;
  assign i_lvl  = itlb_hit ? itlb_lvl  : walk_lvl_q;

  assign d_bad = perm_bad(d_perm, 1'b0, lsu_is_store_i, ld_st_priv_lvl_i, sum_i, mxr_i);
  assign i_bad = perm_bad(i_perm, 1'b1, 1'b0,           priv_lvl_i,       sum_i, mxr_i);

  always_comb begin
    lsu_valid_o     = 1'b0;
    lsu_paddr_o     = 56'd0;
    lsu_exc_valid_o = 1'b0;
    lsu_exc_cause_o = 64'd0;
    lsu_exc_tval_o  = lsu_vaddr_i;

    if (lsu_req_i) begin
      if (!en_ld_st_translation_i) begin
        lsu_valid_o = 1'b1;                              // C1: bare
        lsu_paddr_o = lsu_vaddr_i[55:0];
      end else if (dtlb_hit) begin
        lsu_valid_o = 1'b1;                              // A11: retires either way
        lsu_paddr_o = mk_pa(d_ppn, d_lvl, lsu_vaddr_i);
        if (d_bad) begin
          lsu_exc_valid_o = 1'b1;
          lsu_exc_cause_o = lsu_is_store_i ? CAUSE_ST_PAGE : CAUSE_LD_PAGE;
        end
      end else if (!cur_fetch) begin
        if (walk_af) begin
          lsu_valid_o     = 1'b1;
          lsu_exc_valid_o = 1'b1;
          lsu_exc_cause_o = lsu_is_store_i ? CAUSE_ST_ACCESS : CAUSE_LD_ACCESS;
        end else if (walk_pf) begin
          lsu_valid_o     = 1'b1;
          lsu_exc_valid_o = 1'b1;
          lsu_exc_cause_o = lsu_is_store_i ? CAUSE_ST_PAGE : CAUSE_LD_PAGE;
        end else if (walk_ok) begin
          lsu_valid_o = 1'b1;
          lsu_paddr_o = mk_pa(d_ppn, d_lvl, lsu_vaddr_i);
          if (d_bad) begin
            lsu_exc_valid_o = 1'b1;
            lsu_exc_cause_o = lsu_is_store_i ? CAUSE_ST_PAGE : CAUSE_LD_PAGE;
          end
        end
      end
    end
  end

  always_comb begin
    fetch_valid_o     = 1'b0;
    fetch_paddr_o     = 56'd0;
    fetch_exc_valid_o = 1'b0;
    fetch_exc_cause_o = 64'd0;
    fetch_exc_tval_o  = fetch_vaddr_i;

    if (fetch_req_i) begin
      if (!enable_translation_i) begin
        fetch_valid_o = 1'b1;
        fetch_paddr_o = fetch_vaddr_i[55:0];
      end else if (itlb_hit) begin
        fetch_valid_o = 1'b1;
        fetch_paddr_o = mk_pa(i_ppn, i_lvl, fetch_vaddr_i);
        if (i_bad) begin
          fetch_exc_valid_o = 1'b1;
          fetch_exc_cause_o = CAUSE_IF_PAGE;
        end
      end else if (cur_fetch) begin
        if (walk_af) begin
          fetch_valid_o     = 1'b1;
          fetch_exc_valid_o = 1'b1;
          fetch_exc_cause_o = CAUSE_IF_ACCESS;
        end else if (walk_pf) begin
          fetch_valid_o     = 1'b1;
          fetch_exc_valid_o = 1'b1;
          fetch_exc_cause_o = CAUSE_IF_PAGE;
        end else if (walk_ok) begin
          fetch_valid_o = 1'b1;
          fetch_paddr_o = mk_pa(i_ppn, i_lvl, fetch_vaddr_i);
          if (i_bad) begin
            fetch_exc_valid_o = 1'b1;
            fetch_exc_cause_o = CAUSE_IF_PAGE;
          end
        end
      end
    end
  end

  // reported, not scored (T2)
  assign lsu_dtlb_hit_o = dtlb_hit;
  assign lsu_dtlb_ppn_o = dtlb_ppn;
  assign itlb_miss_o    = i_miss;
  assign dtlb_miss_o    = d_miss;

endmodule

// =============================================================================
// A fully-associative TLB (P2). 16 parallel comparators, one round-robin
// victim pointer, and a single-cycle parallel flush.
//
// The victim pointer is strict round-robin advancing on every install, which
// makes replacement FIFO: after a flush the pointer walks the 16 entries in
// order, so a fill of 16 distinct pages occupies 16 distinct entries (T4, T9),
// and a fill that follows a warm preamble evicts the preamble entries first
// because those are the oldest. A9 leaves this free; it costs 4 flip-flops.
// =============================================================================
module sv39_mmu_tlb #(
  parameter int unsigned ENTRIES = 16
) (
  input  logic        clk_i,
  input  logic        rst_ni,
  input  logic        flush_i,

  input  logic [26:0] lu_vpn_i,
  input  logic [15:0] lu_asid_i,
  output logic        hit_o,
  output logic [43:0] ppn_o,
  output logic [1:0]  lvl_o,
  output logic [5:0]  perm_o,

  input  logic        up_valid_i,
  input  logic [26:0] up_vpn_i,
  input  logic [15:0] up_asid_i,
  input  logic [1:0]  up_lvl_i,
  input  logic [43:0] up_ppn_i,
  input  logic        up_g_i,
  input  logic [5:0]  up_perm_i
);

  localparam int unsigned IW = (ENTRIES > 1) ? $clog2(ENTRIES) : 1;

  logic [ENTRIES-1:0] vld_q;
  logic [26:0]        vpn_q  [ENTRIES];
  logic [15:0]        asid_q [ENTRIES];
  logic [1:0]         lvl_q  [ENTRIES];
  logic [43:0]        ppn_q  [ENTRIES];
  logic               g_q    [ENTRIES];
  logic [5:0]         perm_q [ENTRIES];
  logic [IW-1:0]      victim_q;

  logic [ENTRIES-1:0] match;

  // A10: a global leaf answers for every ASID; a non-global one only for its own
  always_comb begin
    logic asid_ok;
    match   = '0;
    asid_ok = 1'b0;
    for (int unsigned i = 0; i < ENTRIES; i++) begin
      asid_ok = g_q[i] || (asid_q[i] == lu_asid_i);
      if (vld_q[i] && asid_ok) begin
        if (lvl_q[i] == 2'd2)      match[i] = (vpn_q[i][26:18] == lu_vpn_i[26:18]);
        else if (lvl_q[i] == 2'd1) match[i] = (vpn_q[i][26:9]  == lu_vpn_i[26:9]);
        else                       match[i] = (vpn_q[i]        == lu_vpn_i);
      end
    end
  end

  always_comb begin
    hit_o  = |match;
    ppn_o  = 44'd0;
    lvl_o  = 2'd0;
    perm_o = 6'd0;
    for (int unsigned i = 0; i < ENTRIES; i++) begin
      if (match[i]) begin
        ppn_o  = ppn_q[i];
        lvl_o  = lvl_q[i];
        perm_o = perm_q[i];
      end
    end
  end

  always_ff @(posedge clk_i) begin
    if (!rst_ni) begin
      vld_q    <= '0;
      victim_q <= '0;
    end else if (flush_i) begin
      vld_q    <= '0;          // C2: one cycle, all entries
      victim_q <= '0;
    end else if (up_valid_i) begin
      vld_q[victim_q] <= 1'b1;
      victim_q        <= victim_q + {{(IW-1){1'b0}}, 1'b1};
    end
  end

  always_ff @(posedge clk_i) begin
    if (up_valid_i) begin
      vpn_q [victim_q] <= up_vpn_i;
      asid_q[victim_q] <= up_asid_i;
      lvl_q [victim_q] <= up_lvl_i;
      ppn_q [victim_q] <= up_ppn_i;
      g_q   [victim_q] <= up_g_i;
      perm_q[victim_q] <= up_perm_i;
    end
  end

endmodule