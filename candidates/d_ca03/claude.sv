// =============================================================================
// sv39_mmu.sv -- implementation of the d_ca03 contract.
//
// Structure:
//   * two 16-entry fully-associative TLBs (P2), parallel tag compare, one
//     cycle of registered lookup result;
//   * one shared three-level page-table walker with alternating port priority;
//   * PMP checked combinationally on every address the walker is about to read,
//     and only there (A8), before the request is issued, so an access fault
//     pre-empts any page fault the entry could have produced (A7);
//   * all permission / A / D checks (A4, A5) applied on the delivered path, so
//     a TLB hit and a fresh walk fault identically (A9);
//   * single-cycle flush of both TLBs (flush_tlb_i clears the valid vector);
//   * flush_i aborts the walk, swallows any outstanding memory response, and
//     the walk restarts on its own because the requester's req stays asserted
//     and still misses (C3, T5).
//
// Retirement follows A11: valid_o means "retired", and a faulting request
// asserts valid_o and exc_valid_o in the same cycle.
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
  localparam logic [1:0] PS_4K = 2'd0;   // level 0 leaf
  localparam logic [1:0] PS_2M = 2'd1;   // level 1 leaf
  localparam logic [1:0] PS_1G = 2'd2;   // level 2 leaf

  // stored permission vector: {G, D, A, U, X, W, R}
  localparam int unsigned PB_R = 0;
  localparam int unsigned PB_W = 1;
  localparam int unsigned PB_X = 2;
  localparam int unsigned PB_U = 3;
  localparam int unsigned PB_A = 4;
  localparam int unsigned PB_D = 5;
  localparam int unsigned PB_G = 6;

  typedef enum logic [2:0] {
    PTW_IDLE,   // no walk in flight
    PTW_GNT,    // driving mem_req_o for pptr_q, waiting for mem_gnt_i
    PTW_RVLD,   // granted, waiting for mem_rvalid_i
    PTW_KILL,   // flushed with a read outstanding: discard the response
    PTW_PF,     // one cycle of page-fault retirement
    PTW_AF      // one cycle of access-fault retirement (PMP)
  } ptw_state_e;

  // ---------------------------------------------------------------------------
  // helper functions -- every declaration precedes every statement (T6)
  // ---------------------------------------------------------------------------

  // Tag compare for one TLB entry. Superpages ignore the VPN fields they do
  // not translate; a global entry matches under any ASID (A10).
  function automatic logic tlb_entry_match(
      input logic        e_vld,
      input logic [15:0] e_asid,
      input logic [26:0] e_vpn,
      input logic [1:0]  e_size,
      input logic        e_glb,
      input logic [15:0] c_asid,
      input logic [26:0] c_vpn
  );
    logic m2;
    logic m1;
    logic m0;
    logic am;
    m2 = (e_vpn[26:18] == c_vpn[26:18]);
    m1 = (e_vpn[17:9]  == c_vpn[17:9]);
    m0 = (e_vpn[8:0]   == c_vpn[8:0]);
    am = e_glb | (e_asid == c_asid);
    return e_vld & am & m2 &
           ((e_size == PS_1G) | (m1 & ((e_size == PS_2M) | m0)));
  endfunction

  // A2: the leaf PPN with its low 9*i bits replaced by the corresponding VPN
  // bits of the virtual address, plus the page offset.
  function automatic logic [55:0] compose_paddr(
      input logic [43:0] e_ppn,
      input logic [1:0]  e_size,
      input logic [63:0] va
  );
    logic [43:0] p;
    p = e_ppn;
    if (e_size == PS_1G) begin
      p[17:0] = va[29:12];
    end else if (e_size == PS_2M) begin
      p[8:0] = va[20:12];
    end
    return {p, va[11:0]};
  endfunction

  // A4 + A5: permission, U/SUM/MXR and A/D checking on a leaf entry.
  function automatic logic leaf_fault(
      input logic [6:0] perm,
      input logic       is_fetch,
      input logic       is_store,
      input logic [1:0] priv,
      input logic       sum,
      input logic       mxr
  );
    logic f;
    f = 1'b0;
    if (!perm[PB_A]) f = 1'b1;                                  // A5
    if ((priv == 2'b00) && !perm[PB_U]) f = 1'b1;               // U mode needs U
    if ((priv == 2'b01) &&  perm[PB_U] && (is_fetch || !sum)) begin
      f = 1'b1;                                                 // S mode, SUM
    end
    if (is_fetch) begin
      if (!perm[PB_X]) f = 1'b1;
    end else if (is_store) begin
      if (!perm[PB_W]) f = 1'b1;
      if (!perm[PB_D]) f = 1'b1;                                // A5
    end else begin
      if (!(perm[PB_R] | (perm[PB_X] & mxr))) f = 1'b1;         // MXR
    end
    return f;
  endfunction

  // A8: PMP on a walker read. Lowest matching region decides and must grant R;
  // no matching region denies.
  function automatic logic pmp_read_ok(input logic [55:0] addr);
    logic [53:0] a;
    logic [53:0] prev;
    logic [53:0] top;
    logic [53:0] msk;
    logic [1:0]  md;
    logic        mt;
    logic        done;
    logic        ok;
    a    = addr[55:2];
    prev = 54'd0;
    done = 1'b0;
    ok   = 1'b0;
    for (int unsigned i = 0; i < 8; i++) begin
      md  = pmpcfg_i[i][4:3];
      top = pmpaddr_i[i];
      msk = ~(top ^ (top + 54'd1));   // NAPOT: 0 over the ignored low bits
      mt  = 1'b0;
      if (md == 2'd1) begin
        mt = (a >= prev) && (a < top);              // TOR
      end else if (md == 2'd2) begin
        mt = (a == top);                            // NA4
      end else if (md == 2'd3) begin
        mt = (((a ^ top) & msk) == 54'd0);          // NAPOT
      end
      if (!done && (md != 2'd0) && mt) begin
        done = 1'b1;
        ok   = pmpcfg_i[i][0];        // R; the walker only ever reads
      end
      prev = top;
    end
    return ok;
  endfunction

  // Replacement policy is free (A9). This one is plain round-robin: the victim
  // is the counter, and the counter advances on every install. That is what
  // makes T4/T9 pass on both TLBs -- sixteen consecutive installs take the
  // sixteen indices rr, rr+1, ... rr+15, which are distinct whatever the TLB
  // held beforehand, so a sixteen-page fill is always fully resident and a
  // seventeenth page always displaces one of them. Preferring an invalid entry
  // first does NOT have that property: a jump to a low invalid index can wrap
  // the counter back onto an entry the same fill just wrote, leaving fifteen
  // pages resident out of sixteen and failing the replay.

  // ---------------------------------------------------------------------------
  // TLB storage (P2: 16 + 16 entries, fully associative, no second level)
  // ---------------------------------------------------------------------------
  logic [15:0]        itlb_vld_q;
  logic [15:0][15:0]  itlb_asid_q;
  logic [15:0][26:0]  itlb_vpn_q;
  logic [15:0][1:0]   itlb_sz_q;
  logic [15:0][43:0]  itlb_ppn_q;
  logic [15:0][6:0]   itlb_perm_q;
  logic [3:0]         itlb_rr_q;

  logic [15:0]        dtlb_vld_q;
  logic [15:0][15:0]  dtlb_asid_q;
  logic [15:0][26:0]  dtlb_vpn_q;
  logic [15:0][1:0]   dtlb_sz_q;
  logic [15:0][43:0]  dtlb_ppn_q;
  logic [15:0][6:0]   dtlb_perm_q;
  logic [3:0]         dtlb_rr_q;

  // ---------------------------------------------------------------------------
  // combinational lookup
  // ---------------------------------------------------------------------------
  logic [26:0] fetch_vpn;
  logic [26:0] lsu_vpn;

  logic        itlb_hit;
  logic [43:0] itlb_ppn;
  logic [1:0]  itlb_sz;
  logic [6:0]  itlb_perm;

  logic        dtlb_hit;
  logic [43:0] dtlb_ppn;
  logic [1:0]  dtlb_sz;
  logic [6:0]  dtlb_perm;

  assign fetch_vpn = fetch_vaddr_i[38:12];
  assign lsu_vpn   = lsu_vaddr_i[38:12];

  always_comb begin
    itlb_hit  = 1'b0;
    itlb_ppn  = 44'd0;
    itlb_sz   = PS_4K;
    itlb_perm = 7'd0;
    for (int unsigned i = 0; i < 16; i++) begin
      if (tlb_entry_match(itlb_vld_q[i], itlb_asid_q[i], itlb_vpn_q[i],
                          itlb_sz_q[i], itlb_perm_q[i][PB_G],
                          asid_i, fetch_vpn)) begin
        itlb_hit  = 1'b1;
        itlb_ppn  = itlb_ppn_q[i];
        itlb_sz   = itlb_sz_q[i];
        itlb_perm = itlb_perm_q[i];
      end
    end
  end

  always_comb begin
    dtlb_hit  = 1'b0;
    dtlb_ppn  = 44'd0;
    dtlb_sz   = PS_4K;
    dtlb_perm = 7'd0;
    for (int unsigned i = 0; i < 16; i++) begin
      if (tlb_entry_match(dtlb_vld_q[i], dtlb_asid_q[i], dtlb_vpn_q[i],
                          dtlb_sz_q[i], dtlb_perm_q[i][PB_G],
                          asid_i, lsu_vpn)) begin
        dtlb_hit  = 1'b1;
        dtlb_ppn  = dtlb_ppn_q[i];
        dtlb_sz   = dtlb_sz_q[i];
        dtlb_perm = dtlb_perm_q[i];
      end
    end
  end

  // ---------------------------------------------------------------------------
  // registered request / lookup result
  // ---------------------------------------------------------------------------
  logic        lsu_req_q;
  logic [63:0] lsu_vaddr_q;
  logic        lsu_is_store_q;
  logic        dtlb_hit_q;
  logic [43:0] dtlb_ppn_q_r;
  logic [1:0]  dtlb_sz_q_r;
  logic [6:0]  dtlb_perm_q_r;

  logic        fetch_req_q;
  logic [63:0] fetch_vaddr_q;
  logic        itlb_hit_q;
  logic [43:0] itlb_ppn_q_r;
  logic [1:0]  itlb_sz_q_r;
  logic [6:0]  itlb_perm_q_r;

  // ---------------------------------------------------------------------------
  // page table walker
  // ---------------------------------------------------------------------------
  ptw_state_e  ptw_q, ptw_d;
  logic [55:0] pptr_q, pptr_d;
  logic [1:0]  lvl_q, lvl_d;
  logic        instr_q, instr_d;
  logic        store_q, store_d;
  logic [26:0] wvpn_q, wvpn_d;
  logic [15:0] wasid_q, wasid_d;
  logic        prio_fetch_q, prio_fetch_d;

  logic        itlb_we;
  logic        dtlb_we;
  logic [3:0]  itlb_vic;
  logic [3:0]  dtlb_vic;

  logic        itlb_start;
  logic        dtlb_start;
  logic        ptw_start;

  logic        pte_ready;
  logic        pte_v, pte_r, pte_w, pte_x, pte_u, pte_g, pte_a, pte_d;
  logic [43:0] pte_ppn;
  logic [6:0]  upd_perm;
  logic        pte_leaf;
  logic        pte_bad;
  logic        pte_misaligned;

  assign pte_v   = mem_rdata_i[0];
  assign pte_r   = mem_rdata_i[1];
  assign pte_w   = mem_rdata_i[2];
  assign pte_x   = mem_rdata_i[3];
  assign pte_u   = mem_rdata_i[4];
  assign pte_g   = mem_rdata_i[5];
  assign pte_a   = mem_rdata_i[6];
  assign pte_d   = mem_rdata_i[7];
  assign pte_ppn = mem_rdata_i[53:10];

  assign upd_perm = {pte_g, pte_d, pte_a, pte_u, pte_x, pte_w, pte_r};

  // F3: V=0 is invalid, W=1 R=0 is a reserved encoding.
  assign pte_bad  = (!pte_v) | (pte_w & ~pte_r);
  assign pte_leaf = pte_r | pte_x;
  // A3: a superpage leaf whose PPN is not aligned to its own size faults.
  assign pte_misaligned = ((lvl_q == 2'd2) && (pte_ppn[17:0] != 18'd0)) ||
                          ((lvl_q == 2'd1) && (pte_ppn[8:0]  !=  9'd0));

  // One PMP instance, evaluated on the registered pointer -- which is exactly
  // the address driven on mem_addr_o, so every address the walker reads is
  // checked and nothing else is (A8). Checking a combinationally computed
  // next-pointer instead would need a second comparator set and would make this
  // always_comb block read a signal derived from its own output.
  logic pmp_ok;
  assign pmp_ok = pmp_read_ok(pptr_q);

  assign pte_ready = mem_rvalid_i &&
                     ((ptw_q == PTW_RVLD) ||
                      ((ptw_q == PTW_GNT) && pmp_ok && mem_gnt_i));

  assign itlb_start = enable_translation_i   && fetch_req_i && !itlb_hit;
  assign dtlb_start = en_ld_st_translation_i && lsu_req_i   && !dtlb_hit;

  assign itlb_vic = itlb_rr_q;
  assign dtlb_vic = dtlb_rr_q;

  always_comb begin
    ptw_d        = ptw_q;
    pptr_d       = pptr_q;
    lvl_d        = lvl_q;
    instr_d      = instr_q;
    store_d      = store_q;
    wvpn_d       = wvpn_q;
    wasid_d      = wasid_q;
    prio_fetch_d = prio_fetch_q;

    mem_req_o    = 1'b0;
    itlb_we      = 1'b0;
    dtlb_we      = 1'b0;
    ptw_start    = 1'b0;

    case (ptw_q)

      PTW_IDLE: begin
        // Alternating priority between the two ports: whichever was served
        // last yields, so neither port can starve the other.
        if (!flush_i && (dtlb_start || itlb_start)) begin
          if (dtlb_start && !(itlb_start && prio_fetch_q)) begin
            ptw_start    = 1'b1;
            instr_d      = 1'b0;
            store_d      = lsu_is_store_i;
            wvpn_d       = lsu_vpn;
            wasid_d      = asid_i;
            lvl_d        = 2'd2;
            pptr_d       = {satp_ppn_i, lsu_vpn[26:18], 3'b000};
            prio_fetch_d = 1'b1;
          end else if (itlb_start) begin
            ptw_start    = 1'b1;
            instr_d      = 1'b1;
            store_d      = 1'b0;
            wvpn_d       = fetch_vpn;
            wasid_d      = asid_i;
            lvl_d        = 2'd2;
            pptr_d       = {satp_ppn_i, fetch_vpn[26:18], 3'b000};
            prio_fetch_d = 1'b0;
          end
        end
        if (ptw_start) ptw_d = PTW_GNT;
      end

      PTW_GNT: begin
        // A7/A8: the walker's own read is checked before it is issued, so an
        // access fault pre-empts whatever the entry would have said.
        if (!pmp_ok) begin
          ptw_d = PTW_AF;
        end else begin
          mem_req_o = 1'b1;
          if (mem_gnt_i && !pte_ready) ptw_d = PTW_RVLD;
        end
      end

      PTW_RVLD: begin
        // handled by the pte_ready block below
      end

      PTW_KILL: begin
        if (mem_rvalid_i) ptw_d = PTW_IDLE;
      end

      default: begin                              // PTW_PF, PTW_AF
        ptw_d = PTW_IDLE;
      end

    endcase

    // -- interpret a returned entry (A1) -------------------------------------
    if (pte_ready) begin
      if (pte_bad) begin
        ptw_d = PTW_PF;
      end else if (pte_leaf) begin
        if (pte_misaligned) begin
          ptw_d = PTW_PF;
        end else begin
          // Install unconditionally; A4/A5 are applied on the delivered path
          // so that a hit and a fresh walk fault identically (A9).
          if (instr_q) itlb_we = 1'b1;
          else         dtlb_we = 1'b1;
          ptw_d = PTW_IDLE;
        end
      end else if (lvl_q == 2'd0) begin
        ptw_d = PTW_PF;                           // ran past level 0
      end else begin
        lvl_d  = lvl_q - 2'd1;
        pptr_d = {pte_ppn,
                  (lvl_q == 2'd2) ? wvpn_q[17:9] : wvpn_q[8:0],
                  3'b000};
        ptw_d  = PTW_GNT;                         // PMP is checked there
      end
    end

    // -- C3: flush_i aborts the walk; the request is re-walked because it is
    //    still asserted and still misses.
    if (flush_i) begin
      itlb_we = 1'b0;
      dtlb_we = 1'b0;
      case (ptw_q)
        PTW_GNT: begin
          if (mem_req_o && mem_gnt_i && !pte_ready) ptw_d = PTW_KILL;
          else                                      ptw_d = PTW_IDLE;
        end
        PTW_RVLD: begin
          ptw_d = mem_rvalid_i ? PTW_IDLE : PTW_KILL;
        end
        PTW_KILL: begin
          ptw_d = mem_rvalid_i ? PTW_IDLE : PTW_KILL;
        end
        default: begin
          ptw_d = PTW_IDLE;
        end
      endcase
    end
  end

  // V3: 8-byte aligned physical address, held stable until the grant.
  assign mem_addr_o      = pptr_q;
  assign mem_tag_valid_o = 1'b0;                  // T2: unconstrained
  assign mem_kill_o      = 1'b0;                  // T2: unconstrained

  // ---------------------------------------------------------------------------
  // sequential state
  // ---------------------------------------------------------------------------
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      ptw_q        <= PTW_IDLE;
      pptr_q       <= 56'd0;
      lvl_q        <= 2'd2;
      instr_q      <= 1'b0;
      store_q      <= 1'b0;
      wvpn_q       <= 27'd0;
      wasid_q      <= 16'd0;
      prio_fetch_q <= 1'b0;
    end else begin
      ptw_q        <= ptw_d;
      pptr_q       <= pptr_d;
      lvl_q        <= lvl_d;
      instr_q      <= instr_d;
      store_q      <= store_d;
      wvpn_q       <= wvpn_d;
      wasid_q      <= wasid_d;
      prio_fetch_q <= prio_fetch_d;
    end
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      lsu_req_q      <= 1'b0;
      lsu_vaddr_q    <= 64'd0;
      lsu_is_store_q <= 1'b0;
      dtlb_hit_q     <= 1'b0;
      dtlb_ppn_q_r   <= 44'd0;
      dtlb_sz_q_r    <= PS_4K;
      dtlb_perm_q_r  <= 7'd0;
      fetch_req_q    <= 1'b0;
      fetch_vaddr_q  <= 64'd0;
      itlb_hit_q     <= 1'b0;
      itlb_ppn_q_r   <= 44'd0;
      itlb_sz_q_r    <= PS_4K;
      itlb_perm_q_r  <= 7'd0;
    end else begin
      lsu_req_q      <= lsu_req_i;
      lsu_vaddr_q    <= lsu_vaddr_i;
      lsu_is_store_q <= lsu_is_store_i;
      // flush_tlb_i also drops the captured hit, so no result is delivered
      // from an entry the flush removed. flush_i does not touch the TLBs (C3).
      dtlb_hit_q     <= dtlb_hit & ~flush_tlb_i;
      dtlb_ppn_q_r   <= dtlb_ppn;
      dtlb_sz_q_r    <= dtlb_sz;
      dtlb_perm_q_r  <= dtlb_perm;
      fetch_req_q    <= fetch_req_i;
      fetch_vaddr_q  <= fetch_vaddr_i;
      itlb_hit_q     <= itlb_hit & ~flush_tlb_i;
      itlb_ppn_q_r   <= itlb_ppn;
      itlb_sz_q_r    <= itlb_sz;
      itlb_perm_q_r  <= itlb_perm;
    end
  end

  // TLB arrays. C2: flush_tlb_i empties both in one cycle and wins over a
  // concurrent install.
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      itlb_vld_q <= 16'd0;
      dtlb_vld_q <= 16'd0;
      itlb_rr_q  <= 4'd0;
      dtlb_rr_q  <= 4'd0;
    end else begin
      if (itlb_we) begin
        itlb_vld_q[itlb_vic]  <= 1'b1;
        itlb_asid_q[itlb_vic] <= wasid_q;
        itlb_vpn_q[itlb_vic]  <= wvpn_q;
        itlb_sz_q[itlb_vic]   <= lvl_q;
        itlb_ppn_q[itlb_vic]  <= pte_ppn;
        itlb_perm_q[itlb_vic] <= upd_perm;
        itlb_rr_q             <= itlb_rr_q + 4'd1;
      end
      if (dtlb_we) begin
        dtlb_vld_q[dtlb_vic]  <= 1'b1;
        dtlb_asid_q[dtlb_vic] <= wasid_q;
        dtlb_vpn_q[dtlb_vic]  <= wvpn_q;
        dtlb_sz_q[dtlb_vic]   <= lvl_q;
        dtlb_ppn_q[dtlb_vic]  <= pte_ppn;
        dtlb_perm_q[dtlb_vic] <= upd_perm;
        dtlb_rr_q             <= dtlb_rr_q + 4'd1;
      end
      if (flush_tlb_i) begin
        itlb_vld_q <= 16'd0;
        dtlb_vld_q <= 16'd0;
      end
    end
  end

  // ---------------------------------------------------------------------------
  // data port (A11)
  // ---------------------------------------------------------------------------
  logic        dfault;
  logic [55:0] dpaddr;
  logic        ptw_pf_data;
  logic        ptw_af_data;

  assign dpaddr = compose_paddr(dtlb_ppn_q_r, dtlb_sz_q_r, lsu_vaddr_q);
  assign dfault = leaf_fault(dtlb_perm_q_r, 1'b0, lsu_is_store_q,
                             ld_st_priv_lvl_i, sum_i, mxr_i);
  assign ptw_pf_data = (ptw_q == PTW_PF) && !instr_q;
  assign ptw_af_data = (ptw_q == PTW_AF) && !instr_q;

  always_comb begin
    lsu_valid_o     = 1'b0;
    lsu_paddr_o     = lsu_vaddr_q[55:0];
    lsu_exc_valid_o = 1'b0;
    lsu_exc_cause_o = 64'd0;
    lsu_exc_tval_o  = lsu_vaddr_q;

    if (!en_ld_st_translation_i) begin
      lsu_valid_o = lsu_req_q;                    // C1: bare mode
    end else begin
      lsu_paddr_o = dpaddr;
      if (lsu_req_q && dtlb_hit_q) begin
        lsu_valid_o = 1'b1;
        if (dfault) begin
          lsu_exc_valid_o = 1'b1;
          lsu_exc_cause_o = lsu_is_store_q ? 64'd15 : 64'd13;
        end
      end else if (ptw_pf_data) begin
        lsu_valid_o     = 1'b1;
        lsu_exc_valid_o = 1'b1;
        lsu_exc_cause_o = store_q ? 64'd15 : 64'd13;
        lsu_paddr_o     = 56'd0;
      end else if (ptw_af_data) begin
        lsu_valid_o     = 1'b1;
        lsu_exc_valid_o = 1'b1;
        lsu_exc_cause_o = store_q ? 64'd7 : 64'd5;   // A8
        lsu_paddr_o     = 56'd0;
      end
    end
  end

  // ---------------------------------------------------------------------------
  // fetch port (A11)
  // ---------------------------------------------------------------------------
  logic        ffault;
  logic [55:0] fpaddr;
  logic        ptw_pf_instr;
  logic        ptw_af_instr;

  assign fpaddr = compose_paddr(itlb_ppn_q_r, itlb_sz_q_r, fetch_vaddr_q);
  assign ffault = leaf_fault(itlb_perm_q_r, 1'b1, 1'b0,
                             priv_lvl_i, sum_i, mxr_i);
  assign ptw_pf_instr = (ptw_q == PTW_PF) && instr_q;
  assign ptw_af_instr = (ptw_q == PTW_AF) && instr_q;

  always_comb begin
    fetch_valid_o     = 1'b0;
    fetch_paddr_o     = fetch_vaddr_q[55:0];
    fetch_exc_valid_o = 1'b0;
    fetch_exc_cause_o = 64'd0;
    fetch_exc_tval_o  = fetch_vaddr_q;

    if (!enable_translation_i) begin
      fetch_valid_o = fetch_req_q;                // C1: bare mode
    end else begin
      fetch_paddr_o = fpaddr;
      if (fetch_req_q && itlb_hit_q) begin
        fetch_valid_o = 1'b1;
        if (ffault) begin
          fetch_exc_valid_o = 1'b1;
          fetch_exc_cause_o = 64'd12;
        end
      end else if (ptw_pf_instr) begin
        fetch_valid_o     = 1'b1;
        fetch_exc_valid_o = 1'b1;
        fetch_exc_cause_o = 64'd12;
        fetch_paddr_o     = 56'd0;
      end else if (ptw_af_instr) begin
        fetch_valid_o     = 1'b1;
        fetch_exc_valid_o = 1'b1;
        fetch_exc_cause_o = 64'd1;                // A8
        fetch_paddr_o     = 56'd0;
      end
    end
  end

  // ---------------------------------------------------------------------------
  // reporting outputs (T2: not scored)
  // ---------------------------------------------------------------------------
  assign lsu_dtlb_hit_o = dtlb_hit_q;
  assign lsu_dtlb_ppn_o = dpaddr[55:12];
  assign itlb_miss_o    = itlb_start;
  assign dtlb_miss_o    = dtlb_start;

  // Deliberately unread: the two flush-narrowing inputs (C2 permits treating
  // every flush as a full flush), the sign-extension bits of both virtual
  // addresses (F1), and the RSW / reserved fields of a PTE (F3).
  logic unused_ok;
  assign unused_ok = |{asid_to_be_flushed_i,
                       vaddr_to_be_flushed_i,
                       lsu_vaddr_i[63:39],
                       fetch_vaddr_i[63:39],
                       mem_rdata_i[63:54],
                       mem_rdata_i[9:8]};

endmodule