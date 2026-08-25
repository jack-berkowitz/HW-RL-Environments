// nc_g_itlb_one_entry.sv -- d_ca03 CAPACITY-REDUCED CONTROL.
// Never shipped, never scored as a submission.
//
// PURPOSE. Every other control here except nc_b and nc_c is a correctness
// perturbation: wrong everywhere. This one answers a different question -- IS
// THE INSTRUCTION TLB'S PINNED CAPACITY LOAD-BEARING? T9 previously recorded
// that it was not checkable, on the strength of a COLD 16-page fill under which
// the reference itself retains one entry. That measurement was right and the
// conclusion drawn from it was wrong: the anchor's replacement tree advances
// only on a lookup hit (cva6_tlb.sv:436), so the cold fill was measuring the
// replacement policy, not the capacity. Sequence E's phase 9 re-touches each
// page after installing it, and the reference then retains all 16. This control
// exists to show that the resulting check DISCRIMINATES rather than merely
// passing.
//
// THE PERTURBATION. The instruction TLB is instantiated with `ITLB_ENTRIES
// entries; the data TLB keeps 16. NOTHING ELSE DIFFERS from the second source.
// The ports stay full width, so the design receives every request, answers
// every one correctly, and simply discards capacity -- which is the shape a
// real under-provisioning submission would take, and the shape that the cycle
// axis alone cannot refuse.
//
// PREDICTION, stated before running.
//   `ITLB_ENTRIES = 16 -- identical to tb/sv39_mmu_alt_ref.sv in every respect.
//                Should PASS, 0 failing checks, instr replay reads 0.
//   `ITLB_ENTRIES = 1  -- the 16-page instruction replay (steps 157..172) finds
//                one page resident and walks the other fifteen, so T9's first
//                assertion fires. THE PER-STEP T1 SURFACE SHOULD BE CLEAN: a
//                miss walks and returns the same translation, so valid, paddr,
//                exc_valid and cause all still match. Should FAIL, and fail on
//                T9 ALONE. If it also fails per-step checks the control is
//                perturbing more than capacity and is not isolated.
//
// POLARITY, AND WHY IT IS INVERTED FROM d_ai01's nc_g. In nc_g the TASK varies
// -- HEIGHT is 4 or 8 -- and the control passes at the small geometry because
// there its literal equals the parameter. d_ca03 has ONE configuration: P1 says
// so and P2 pins the storage, so there is no second task geometry to run at.
// What varies here is the CONTROL'S OWN literal, and the polarity therefore
// inverts: it FAILS at the small capacity and PASSES at the large one. Stated
// rather than quietly flipped.
//
// If it passes at BOTH, the task does not discriminate on instruction TLB
// capacity and T9 needs a clause change rather than a label change.

// REGENERATED from tb/sv39_mmu_alt_ref.sv after A8 was rewritten from
// measurement. The first version was derived before that change and still
// carried a final-address PMP check the reference does not perform, so it failed
// step 195 at BOTH capacities -- a stale derived artifact reporting a defect that
// belonged to its source, not to the perturbation under test. Regenerate this
// file whenever the second source changes; it is a copy with one literal altered.

`ifndef ITLB_ENTRIES
  `define ITLB_ENTRIES 1
`endif

// -----------------------------------------------------------------------------
// One fully-associative TLB bank. 16 entries, per P2.
// -----------------------------------------------------------------------------
module sv39_ctl_tlb #(
  parameter int unsigned N = 16
) (
  input  logic        clk_i,
  input  logic        rst_ni,
  input  logic        flush_i,          // full flush; C2 permits treating any
                                        // narrowed flush as a full one
  input  logic [15:0] asid_i,

  input  logic [26:0] lu_vpn_i,
  output logic        lu_hit_o,
  output logic [43:0] lu_ppn_o,
  output logic [1:0]  lu_lvl_o,
  output logic [6:0]  lu_perm_o,

  input  logic        wr_en_i,
  input  logic [26:0] wr_vpn_i,
  input  logic [43:0] wr_ppn_i,
  input  logic [1:0]  wr_lvl_i,
  input  logic [6:0]  wr_perm_i
);

  logic [N-1:0]  vld;
  logic [15:0]   e_asid [N];
  logic [26:0]   e_vpn  [N];
  logic [1:0]    e_lvl  [N];
  logic [43:0]   e_ppn  [N];
  logic [6:0]    e_perm [N];   // {D,A,G,U,X,W,R} == pte[7:1]

  // ---- lookup: all 16 in parallel, lowest index wins ------------------------
  logic [N-1:0] mtc;

  always_comb begin
    for (int unsigned k = 0; k < N; k++) begin
      logic tag_eq;
      logic asid_ok;
      // A10: a G=1 entry is valid for every ASID; a G=0 entry only for its own.
      asid_ok = e_perm[k][4] || (e_asid[k] == asid_i);
      // compare only as much of the VPN as the entry's page size covers (A2)
      unique case (e_lvl[k])
        2'd0:    tag_eq = (e_vpn[k][26:0]  == lu_vpn_i[26:0]);
        2'd1:    tag_eq = (e_vpn[k][26:9]  == lu_vpn_i[26:9]);
        default: tag_eq = (e_vpn[k][26:18] == lu_vpn_i[26:18]);
      endcase
      mtc[k] = vld[k] && asid_ok && tag_eq;
    end
  end

  always_comb begin
    lu_hit_o  = 1'b0;
    lu_ppn_o  = '0;
    lu_lvl_o  = 2'd0;
    lu_perm_o = '0;
    for (int unsigned k = 0; k < N; k++) begin
      if (mtc[k] && !lu_hit_o) begin
        lu_hit_o  = 1'b1;
        lu_ppn_o  = e_ppn[k];
        lu_lvl_o  = e_lvl[k];
        lu_perm_o = e_perm[k];
      end
    end
  end

  // ---- victim selection: an invalid slot if there is one, else round robin --
  // A9 leaves the replacement policy free and unscored. Round robin is chosen
  // because it needs a 4-bit counter and no per-entry age state.
  logic [$clog2(N)-1:0] rr;
  logic [$clog2(N)-1:0] vict;
  logic       have_free;

  always_comb begin
    have_free = 1'b0;
    vict      = rr;
    for (int unsigned k = 0; k < N; k++) begin
      if (!vld[k] && !have_free) begin
        have_free = 1'b1;
        vict      = k[$clog2(N)-1:0];
      end
    end
  end

  always_ff @(posedge clk_i) begin
    if (!rst_ni) begin
      vld <= '0;
      rr  <= '0;
    end else if (flush_i) begin
      vld <= '0;                       // one cycle, all 16 -- see the header
    end else if (wr_en_i) begin
      vld[vict]    <= 1'b1;
      e_asid[vict] <= asid_i;
      e_vpn [vict] <= wr_vpn_i;
      e_lvl [vict] <= wr_lvl_i;
      e_ppn [vict] <= wr_ppn_i;
      e_perm[vict] <= wr_perm_i;
      if (!have_free) rr <= rr + 1'b1;
    end
  end
endmodule

// -----------------------------------------------------------------------------
// The unit.
// -----------------------------------------------------------------------------
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

  // ===========================================================================
  // functions
  // ===========================================================================

  // A2: a leaf at level i contributes its PPN with the low 9*i bits replaced by
  // the corresponding VPN bits.
  function automatic logic [43:0] mk_ppn (input logic [43:0] ppn,
                                          input logic [26:0] vpn,
                                          input logic [1:0]  lvl);
    unique case (lvl)
      2'd0:    mk_ppn = ppn;
      2'd1:    mk_ppn = {ppn[43:9],  vpn[8:0]};
      default: mk_ppn = {ppn[43:18], vpn[17:0]};
    endcase
  endfunction

  // A3: a leaf at level i>0 with any low 9*i PPN bit set is misaligned.
  function automatic logic misaligned (input logic [43:0] ppn,
                                        input logic [1:0]  lvl);
    unique case (lvl)
      2'd0:    misaligned = 1'b0;
      2'd1:    misaligned = (ppn[8:0]  != 9'd0);
      default: misaligned = (ppn[17:0] != 18'd0);
    endcase
  endfunction

  // A4 and A5, applied to the leaf's stored permission field.
  // perm = {D,A,G,U,X,W,R}
  function automatic logic perm_ok (input logic [6:0] p,
                                     input logic       is_fetch,
                                     input logic       is_store,
                                     input logic [1:0] pv);
    logic pr, pw, px, pu, pa, pd;
    pr = p[0]; pw = p[1]; px = p[2]; pu = p[3]; pa = p[5]; pd = p[6];
    perm_ok = 1'b1;
    if (!pa) begin
      perm_ok = 1'b0;                                       // A5: A=0 always faults
    end else if (is_fetch) begin
      if      (!px)                        perm_ok = 1'b0;  // A4: fetch needs X
      else if (pv == 2'b00 && !pu)         perm_ok = 1'b0;  // U-mode needs U
      else if (pv == 2'b01 &&  pu)         perm_ok = 1'b0;  // S: U page never exec
    end else begin
      if      (pv == 2'b00 && !pu)             perm_ok = 1'b0;
      else if (pv == 2'b01 && pu && !sum_i)    perm_ok = 1'b0;
      else if (is_store && !pw)                perm_ok = 1'b0;
      else if (is_store && !pd)                perm_ok = 1'b0;  // A5: D=0 on store
      else if (!is_store && !(pr || (px && mxr_i))) perm_ok = 1'b0;
    end
  endfunction

  // A8. Eight regions, compared in parallel, lowest matching index decides.
  // No match denies -- see G-6 in the header.
  function automatic logic pmp_ok (input logic [55:0] addr,
                                    input logic        need_r,
                                    input logic        need_w,
                                    input logic        need_x);
    logic        found, allow, mt;
    logic [53:0] a54, lo, msk;
    int unsigned nm1;
    a54   = addr[55:2];
    found = 1'b0;
    allow = 1'b0;
    for (int unsigned n = 0; n < 8; n++) begin
      if (!found && pmpcfg_i[n][4:3] != 2'b00) begin
        mt  = 1'b0;
        nm1 = (n == 0) ? 0 : n - 1;
        if (pmpcfg_i[n][4:3] == 2'b01) begin                    // TOR
          lo = (n == 0) ? 54'd0 : pmpaddr_i[nm1];
          mt = (a54 >= lo) && (a54 < pmpaddr_i[n]);
        end else if (pmpcfg_i[n][4:3] == 2'b10) begin           // NA4
          mt = (a54 == pmpaddr_i[n]);
        end else begin                                          // NAPOT
          // trailing-ones run plus one bit: pmpaddr ^ (pmpaddr+1) sets exactly
          // the bits the region's size makes don't-care.
          msk = pmpaddr_i[n] ^ (pmpaddr_i[n] + 54'd1);
          mt  = ((a54 & ~msk) == (pmpaddr_i[n] & ~msk));
        end
        if (mt) begin
          found = 1'b1;
          allow = (!need_r || pmpcfg_i[n][0]) &&
                  (!need_w || pmpcfg_i[n][1]) &&
                  (!need_x || pmpcfg_i[n][2]);
        end
      end
    end
    pmp_ok = found ? allow : 1'b0;
  endfunction

  // ===========================================================================
  // the two TLB banks
  // ===========================================================================
  wire [26:0] ls_vpn = lsu_vaddr_i  [38:12];
  wire [26:0] if_vpn = fetch_vaddr_i[38:12];

  logic        ins_d_en, ins_i_en;
  logic [26:0] ins_vpn;
  logic [43:0] ins_ppn;
  logic [1:0]  ins_lvl;
  logic [6:0]  ins_perm;

  logic        d_hit, i_hit;
  logic [43:0] d_ppn, i_ppn;
  logic [1:0]  d_lvl, i_lvl;
  logic [6:0]  d_perm, i_perm;

  sv39_ctl_tlb #(.N(16)) u_dtlb (
    .clk_i, .rst_ni, .flush_i(flush_tlb_i), .asid_i,
    .lu_vpn_i(ls_vpn), .lu_hit_o(d_hit), .lu_ppn_o(d_ppn),
    .lu_lvl_o(d_lvl), .lu_perm_o(d_perm),
    .wr_en_i(ins_d_en), .wr_vpn_i(ins_vpn), .wr_ppn_i(ins_ppn),
    .wr_lvl_i(ins_lvl), .wr_perm_i(ins_perm)
  );

  sv39_ctl_tlb #(.N(`ITLB_ENTRIES)) u_itlb (
    .clk_i, .rst_ni, .flush_i(flush_tlb_i), .asid_i,
    .lu_vpn_i(if_vpn), .lu_hit_o(i_hit), .lu_ppn_o(i_ppn),
    .lu_lvl_o(i_lvl), .lu_perm_o(i_perm),
    .wr_en_i(ins_i_en), .wr_vpn_i(ins_vpn), .wr_ppn_i(ins_ppn),
    .wr_lvl_i(ins_lvl), .wr_perm_i(ins_perm)
  );

  // ===========================================================================
  // walker
  // ===========================================================================
  typedef enum logic [1:0] { S_IDLE, S_REQ, S_GNT, S_RV } st_e;
  st_e         st;
  logic [1:0]  w_lvl;
  logic [43:0] w_base;      // PPN of the table being indexed
  logic [26:0] w_vpn;
  logic [63:0] w_va;
  logic        w_fetch, w_store;
  logic [55:0] w_addr_q;

  // held faults, one per requester, so a fault on one side cannot block the
  // other. Held rather than pulsed so a request that faults is not re-walked
  // every cycle it stays asserted.
  logic        fl_hold, fi_hold;
  logic [63:0] fl_cause, fi_cause;

  wire [8:0]  w_idx     = (w_lvl == 2'd2) ? w_vpn[26:18]
                        : (w_lvl == 2'd1) ? w_vpn[17:9]
                                          : w_vpn[8:0];
  wire [55:0] w_addr_nx = {w_base, 12'd0} + {44'd0, w_idx, 3'd0};
  wire        w_rd_ok   = pmp_ok(w_addr_nx, 1'b1, 1'b0, 1'b0);   // A8, walker read

  wire ls_need = lsu_req_i   && en_ld_st_translation_i && !d_hit;
  wire if_need = fetch_req_i && enable_translation_i   && !i_hit;

  // ---- PTE decode -----------------------------------------------------------
  wire        p_v    = mem_rdata_i[0];
  wire        p_r    = mem_rdata_i[1];
  wire        p_w    = mem_rdata_i[2];
  wire        p_x    = mem_rdata_i[3];
  wire [43:0] p_ppn  = mem_rdata_i[53:10];
  wire [6:0]  p_perm = mem_rdata_i[7:1];

  wire        dec_bad  = !p_v || (p_w && !p_r);          // A1 invalid, F3 reserved
  wire        dec_leaf = p_r || p_x;                     // A1
  wire        dec_mis  = misaligned(p_ppn, w_lvl);       // A3
  wire        dec_take = (st == S_RV) && mem_rvalid_i;

  // a well-formed leaf is installed and delivered by the hit path; A4/A5 and the
  // final PMP check happen there, so they are written once for hit and walk both
  wire        dec_install = dec_take && !dec_bad && dec_leaf && !dec_mis;
  // everything else that terminates the walk is a page fault the walker reports
  wire        dec_pfault  = dec_take && (dec_bad || (dec_leaf && dec_mis) ||
                                         (!dec_leaf && w_lvl == 2'd0));

  always_comb begin
    ins_d_en = dec_install && !w_fetch;
    ins_i_en = dec_install &&  w_fetch;
    ins_vpn  = w_vpn;
    ins_ppn  = p_ppn;
    ins_lvl  = w_lvl;
    ins_perm = p_perm;
  end

  wire [63:0] pf_cause = w_fetch ? 64'd12 : (w_store ? 64'd15 : 64'd13);   // A6
  wire [63:0] af_cause = w_fetch ? 64'd1  : (w_store ? 64'd7  : 64'd5 );   // A6

  always_ff @(posedge clk_i) begin
    if (!rst_ni) begin
      st      <= S_IDLE;
      fl_hold <= 1'b0;
      fi_hold <= 1'b0;
      w_lvl   <= 2'd2;
      w_base  <= '0;
      w_vpn   <= '0;
      w_va    <= '0;
      w_fetch <= 1'b0;
      w_store <= 1'b0;
      w_addr_q<= '0;
    end else if (flush_i) begin
      // C3: abort the in-flight walk. The TLBs are NOT emptied, and the held
      // faults go with the abort so a re-walk re-derives them.
      st      <= S_IDLE;
      fl_hold <= 1'b0;
      fi_hold <= 1'b0;
    end else begin
      if (fl_hold && !lsu_req_i)   fl_hold <= 1'b0;
      if (fi_hold && !fetch_req_i) fi_hold <= 1'b0;

      unique case (st)
        S_IDLE: begin
          // G-8: LSU wins.
          if (ls_need && !fl_hold) begin
            w_fetch <= 1'b0; w_store <= lsu_is_store_i;
            w_va    <= lsu_vaddr_i;  w_vpn <= ls_vpn;
            w_lvl   <= 2'd2;         w_base <= satp_ppn_i;   // A1
            st      <= S_REQ;
          end else if (if_need && !fi_hold) begin
            w_fetch <= 1'b1; w_store <= 1'b0;
            w_va    <= fetch_vaddr_i; w_vpn <= if_vpn;
            w_lvl   <= 2'd2;          w_base <= satp_ppn_i;
            st      <= S_REQ;
          end
        end

        S_REQ: begin
          if (!w_rd_ok) begin
            // A7/A8: the walker's own read is checked before the entry it
            // returns can be interpreted, so this beats any page fault.
            if (w_fetch) begin fi_hold <= 1'b1; fi_cause <= af_cause; end
            else         begin fl_hold <= 1'b1; fl_cause <= af_cause; end
            st <= S_IDLE;
          end else begin
            w_addr_q <= w_addr_nx;
            st       <= mem_gnt_i ? S_RV : S_GNT;
          end
        end

        S_GNT: if (mem_gnt_i) st <= S_RV;

        S_RV: if (mem_rvalid_i) begin
          if (dec_pfault) begin
            if (w_fetch) begin fi_hold <= 1'b1; fi_cause <= pf_cause; end
            else         begin fl_hold <= 1'b1; fl_cause <= pf_cause; end
            st <= S_IDLE;
          end else if (dec_leaf) begin
            st <= S_IDLE;                    // installed; the hit path delivers
          end else begin
            w_lvl  <= w_lvl - 2'd1;          // A1: descend
            w_base <= p_ppn;
            st     <= S_REQ;
          end
        end
      endcase
    end
  end

  assign mem_req_o       = (st == S_REQ) && w_rd_ok;
  assign mem_addr_o      = (st == S_REQ) ? w_addr_nx : w_addr_q;
  assign mem_tag_valid_o = 1'b0;   // G-1
  assign mem_kill_o      = 1'b0;   // G-1

  assign itlb_miss_o = if_need;    // T2: not scored
  assign dtlb_miss_o = ls_need;

  // ===========================================================================
  // delivery -- one place per side, shared by hits and completed walks
  // ===========================================================================
  wire [43:0] ls_ppn_f = mk_ppn(d_ppn, ls_vpn, d_lvl);
  wire [55:0] ls_pa    = {ls_ppn_f, lsu_vaddr_i[11:0]};             // A2
  wire        ls_perm  = perm_ok(d_perm, 1'b0, lsu_is_store_i, ld_st_priv_lvl_i);
  // A8 as MEASURED: only the walker's own reads are PMP-checked, and they need
  // R. The final translated address is NOT checked -- a warm TLB hit with R
  // denied translates, issuing no read (tb/audit/probe_pmp_tb.sv). This file
  // originally took the architectural reading and checked the final address by
  // access type; that was gap G-3, and the spec now decides against it.
  wire        ls_pmp   = 1'b1;

  wire [43:0] if_ppn_f = mk_ppn(i_ppn, if_vpn, i_lvl);
  wire [55:0] if_pa    = {if_ppn_f, fetch_vaddr_i[11:0]};
  wire        if_perm  = perm_ok(i_perm, 1'b1, 1'b0, priv_lvl_i);
  wire        if_pmp   = 1'b1;                                     // A8, see above

  always_comb begin
    lsu_valid_o     = 1'b0;
    lsu_paddr_o     = '0;
    lsu_dtlb_hit_o  = 1'b0;
    lsu_dtlb_ppn_o  = '0;
    lsu_exc_valid_o = 1'b0;
    lsu_exc_cause_o = '0;
    lsu_exc_tval_o  = '0;

    if (lsu_req_i) begin
      if (fl_hold) begin
        lsu_valid_o     = 1'b1;                        // A11
        lsu_exc_valid_o = 1'b1;
        lsu_exc_cause_o = fl_cause;
        lsu_exc_tval_o  = lsu_vaddr_i;                 // G-2
      end else if (!en_ld_st_translation_i) begin
        lsu_valid_o = 1'b1;                            // C1 bare, no PMP (G-5)
        lsu_paddr_o = lsu_vaddr_i[55:0];
      end else if (d_hit) begin
        lsu_dtlb_hit_o = 1'b1;
        lsu_dtlb_ppn_o = ls_ppn_f;
        if (!ls_perm) begin
          lsu_valid_o     = 1'b1;                      // A11
          lsu_paddr_o     = ls_pa;                     // A11: unconstrained
          lsu_exc_valid_o = 1'b1;                      // A4/A5 -> A6 page fault
          lsu_exc_cause_o = lsu_is_store_i ? 64'd15 : 64'd13;
          lsu_exc_tval_o  = lsu_vaddr_i;
        end else if (!ls_pmp) begin
          lsu_valid_o     = 1'b1;                      // A11
          lsu_paddr_o     = ls_pa;                     // A11: unconstrained
          lsu_exc_valid_o = 1'b1;                      // A8 -> A6 access fault
          lsu_exc_cause_o = lsu_is_store_i ? 64'd7 : 64'd5;
          lsu_exc_tval_o  = lsu_vaddr_i;
        end else begin
          lsu_valid_o = 1'b1;
          lsu_paddr_o = ls_pa;
        end
      end
    end
  end

  always_comb begin
    fetch_valid_o     = 1'b0;
    fetch_paddr_o     = '0;
    fetch_exc_valid_o = 1'b0;
    fetch_exc_cause_o = '0;
    fetch_exc_tval_o  = '0;

    if (fetch_req_i) begin
      if (fi_hold) begin
        fetch_valid_o     = 1'b1;                      // A11
        fetch_exc_valid_o = 1'b1;
        fetch_exc_cause_o = fi_cause;
        fetch_exc_tval_o  = fetch_vaddr_i;
      end else if (!enable_translation_i) begin
        fetch_valid_o = 1'b1;
        fetch_paddr_o = fetch_vaddr_i[55:0];
      end else if (i_hit) begin
        if (!if_perm) begin
          fetch_valid_o     = 1'b1;                    // A11
          fetch_paddr_o     = if_pa;                   // A11: unconstrained
          fetch_exc_valid_o = 1'b1;
          fetch_exc_cause_o = 64'd12;
          fetch_exc_tval_o  = fetch_vaddr_i;
        end else if (!if_pmp) begin
          fetch_valid_o     = 1'b1;                    // A11
          fetch_paddr_o     = if_pa;                   // A11: unconstrained
          fetch_exc_valid_o = 1'b1;
          fetch_exc_cause_o = 64'd1;
          fetch_exc_tval_o  = fetch_vaddr_i;
        end else begin
          fetch_valid_o = 1'b1;
          fetch_paddr_o = if_pa;
        end
      end
    end
  end

  // C2 narrowing inputs and C5's out-of-scope inputs are read so the port list
  // is complete without a lint waiver; a full flush is a conforming
  // implementation of a narrowed one, so the values do not steer anything.
  wire _unused = &{1'b0, asid_to_be_flushed_i, vaddr_to_be_flushed_i,
                   lsu_vaddr_i[63:39], fetch_vaddr_i[63:39]};
endmodule
