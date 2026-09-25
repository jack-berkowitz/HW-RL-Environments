// =============================================================================
// sv39_mmu -- d_ca03
//
// Organisation
//   * ITLB and DTLB: 16 entries each, fully associative (P2), looked up
//     combinationally on the live request (hit -> retire in the same cycle).
//     Replacement: true LRU (4-bit rank per entry, updated on every hit and
//     install). LRU guarantees that the N most recently touched pages (N<=16)
//     are resident, so the T4/T9 replays pass for ANY preamble, cold or warm.
//   * One shared walker. It starts combinationally in the cycle a miss is seen
//     (the root address needs only satp and the VA), so no idle cycle is spent
//     per walk. Data misses take priority over instruction misses.
//   * PMP (A8) is applied to every address the walker is about to read, before
//     the read is issued; a denied read faults with the access cause of the
//     ORIGINAL access type (1/5/7) and is never sent to memory. No PMP check is
//     applied to translated addresses or to TLB hits.
//   * Leaf-time checks (as in the reference walker): V, W&!R, misalignment,
//     A, R or X&MXR for data, W&D for stores, X for fetch. Entries that fail
//     are not installed. Hit-time checks: U/SUM (load/store/fetch) and W/D for
//     stores -- so a store that hits an entry installed by a load still faults
//     on D=0 / W=0 without a walk.
//   * Faults from the walker retire through a registered one-cycle pulse with
//     valid_o and exc_valid_o together (A11).
//   * flush_i aborts the walk (draining a granted read); a held request simply
//     misses again and is re-walked (C3). flush_tlb_i clears every valid bit in
//     one cycle and wins over a same-cycle install.
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

  localparam int NE = 16;

  localparam logic [1:0] PRIV_U = 2'b00;
  localparam logic [1:0] PRIV_S = 2'b01;

  typedef struct packed {
    logic [15:0] asid;
    logic [26:0] vpn;
    logic        is1g;
    logic        is2m;
    logic        g;
    logic [43:0] ppn;
    logic        u;
    logic        w;
    logic        d;
  } tlbe_t;

  typedef enum logic [2:0] {W_IDLE, W_REQ, W_WAIT, W_DRAIN, W_FAULT} wst_t;

  // ---------------------------------------------------------------------------
  // Declarations
  // ---------------------------------------------------------------------------
  // TLB storage: index 0 = instruction TLB, 1 = data TLB
  tlbe_t           ent_q   [2][NE];
  logic [NE-1:0]   vld_q   [2];
  logic [3:0]      rank_q  [2][NE];

  logic [26:0]     lu_vpn  [2];
  logic            lu_req  [2];
  logic [NE-1:0]   lu_m    [2];
  logic            lu_hit  [2];
  tlbe_t           lu_e    [2];
  logic [3:0]      lu_rank [2];
  logic            ins     [2];

  // walker
  wst_t            ws_q;
  logic [1:0]      lvl_q;
  logic [43:0]     tppn_q;
  logic [26:0]     wvpn_q;
  logic            winstr_q, wstore_q, gacc_q, facc_q;

  logic            start_i, start_d, start;
  logic [26:0]     st_vpn;
  logic [8:0]      seg;
  logic [55:0]     walk_addr;
  logic            pmp_allow;
  logic            issuing;

  logic [63:0]     pte;
  logic            pte_v, pte_r, pte_w, pte_x, pte_u, pte_g, pte_a, pte_d;
  logic [43:0]     pte_ppn;
  logic            pte_bad, pte_leaf, pte_misal, pte_perm_bad, pte_fault;
  logic            walk_ok_leaf;
  tlbe_t           new_e;

  // PMP
  logic [53:0]     pmp_wa;
  logic [7:0]      pmp_lt, pmp_match;
  logic            pmp_found;

  // ports
  logic            wfault_i, wfault_d;
  logic            daccess_err, iaccess_err, dst_bad;
  logic [55:0]     d_tpa, i_tpa;

  // ---------------------------------------------------------------------------
  // TLB lookup (combinational, AND-OR mux: at most one entry matches)
  // ---------------------------------------------------------------------------
  assign lu_vpn[0] = fetch_vaddr_i[38:12];
  assign lu_vpn[1] = lsu_vaddr_i[38:12];
  assign lu_req[0] = fetch_req_i;
  assign lu_req[1] = lsu_req_i;

  for (genvar t = 0; t < 2; t++) begin : g_tlb
    always_comb begin
      lu_hit[t]  = 1'b0;
      lu_e[t]    = '0;
      lu_rank[t] = '0;
      for (int i = 0; i < NE; i++) begin
        lu_m[t][i] = vld_q[t][i]
                   && (ent_q[t][i].g || ent_q[t][i].asid == asid_i)
                   && (ent_q[t][i].vpn[26:18] == lu_vpn[t][26:18])
                   && (ent_q[t][i].is1g || (ent_q[t][i].vpn[17:9] == lu_vpn[t][17:9]
                        && (ent_q[t][i].is2m || ent_q[t][i].vpn[8:0] == lu_vpn[t][8:0])));
        if (lu_m[t][i]) begin
          lu_hit[t]  = 1'b1;
          lu_e[t]    = lu_e[t] | ent_q[t][i];
          lu_rank[t] = lu_rank[t] | rank_q[t][i];
        end
      end
    end

    assign ins[t] = walk_ok_leaf && (winstr_q == (t == 0));

    // valid bits: reset / flush clear everything; flush beats a same-cycle install
    always_ff @(posedge clk_i or negedge rst_ni) begin
      if (!rst_ni) begin
        vld_q[t] <= '0;
      end else if (flush_tlb_i) begin
        vld_q[t] <= '0;
      end else if (ins[t]) begin
        for (int i = 0; i < NE; i++)
          if (rank_q[t][i] == 4'd15) vld_q[t][i] <= 1'b1;
      end
    end

    // entry payload (no reset)
    always_ff @(posedge clk_i) begin
      if (ins[t] && !flush_tlb_i) begin
        for (int i = 0; i < NE; i++)
          if (rank_q[t][i] == 4'd15) ent_q[t][i] <= new_e;
      end
    end

    // true LRU: rank 0 = most recent, 15 = victim; ranks stay a permutation
    always_ff @(posedge clk_i or negedge rst_ni) begin
      if (!rst_ni) begin
        for (int i = 0; i < NE; i++) rank_q[t][i] <= i[3:0];
      end else if (ins[t] && !flush_tlb_i) begin
        for (int i = 0; i < NE; i++)
          rank_q[t][i] <= (rank_q[t][i] == 4'd15) ? 4'd0 : rank_q[t][i] + 4'd1;
      end else if (lu_req[t] && lu_hit[t]) begin
        for (int i = 0; i < NE; i++) begin
          if (lu_m[t][i])                    rank_q[t][i] <= 4'd0;
          else if (rank_q[t][i] < lu_rank[t]) rank_q[t][i] <= rank_q[t][i] + 4'd1;
        end
      end
    end
  end

  // ---------------------------------------------------------------------------
  // PMP on the walker's read address (S-mode, read access)
  // ---------------------------------------------------------------------------
  assign pmp_wa = walk_addr[55:2];

  always_comb begin
    pmp_found = 1'b0;
    pmp_allow = 1'b0;
    for (int n = 0; n < 8; n++) begin
      pmp_lt[n] = pmp_wa < pmpaddr_i[n];
    end
    for (int n = 0; n < 8; n++) begin
      case (pmpcfg_i[n][4:3])
        2'd1:    pmp_match[n] = ((n == 0) ? 1'b1 : !pmp_lt[(n == 0) ? 0 : n - 1]) && pmp_lt[n];
        2'd2:    pmp_match[n] = (pmp_wa == pmpaddr_i[n]);
        2'd3:    pmp_match[n] = ((pmp_wa ^ pmpaddr_i[n])
                                 & ~(pmpaddr_i[n] ^ (pmpaddr_i[n] + 54'd1))) == 54'd0;
        default: pmp_match[n] = 1'b0;
      endcase
      if (!pmp_found && pmp_match[n]) begin
        pmp_found = 1'b1;
        pmp_allow = pmpcfg_i[n][0];
      end
    end
  end

  // ---------------------------------------------------------------------------
  // Walker
  // ---------------------------------------------------------------------------
  assign start_i = enable_translation_i && fetch_req_i && !lu_hit[0] && !lsu_req_i;
  assign start_d = en_ld_st_translation_i && lsu_req_i && !lu_hit[1];
  assign start   = (ws_q == W_IDLE) && !flush_i && rst_ni && (start_i || start_d);
  // An instruction walk can only start with lsu_req_i low, so selecting on
  // lsu_req_i alone is equivalent and keeps the TLB lookup off the PMP path.
  assign st_vpn  = lsu_req_i ? lsu_vaddr_i[38:12] : fetch_vaddr_i[38:12];

  always_comb begin
    case (lvl_q)
      2'd2:    seg = wvpn_q[26:18];
      2'd1:    seg = wvpn_q[17:9];
      default: seg = wvpn_q[8:0];
    endcase
  end

  assign walk_addr = (ws_q == W_IDLE) ? {satp_ppn_i, st_vpn[26:18], 3'b000}
                                      : {tppn_q, seg, 3'b000};
  assign issuing   = start || (ws_q == W_REQ);

  assign mem_req_o       = issuing && pmp_allow;
  assign mem_addr_o      = walk_addr;
  assign mem_tag_valid_o = (ws_q == W_WAIT);
  assign mem_kill_o      = 1'b0;
  assign itlb_miss_o     = start && !start_d;
  assign dtlb_miss_o     = start && start_d;

  // PTE decode
  assign pte      = mem_rdata_i;
  assign pte_v    = pte[0];
  assign pte_r    = pte[1];
  assign pte_w    = pte[2];
  assign pte_x    = pte[3];
  assign pte_u    = pte[4];
  assign pte_g    = pte[5];
  assign pte_a    = pte[6];
  assign pte_d    = pte[7];
  assign pte_ppn  = pte[53:10];

  assign pte_bad   = !pte_v || (!pte_r && pte_w);
  assign pte_leaf  = pte_r || pte_x;
  assign pte_misal = ((lvl_q == 2'd1) && (pte_ppn[8:0]  != '0))
                  || ((lvl_q == 2'd2) && (pte_ppn[17:0] != '0));
  assign pte_perm_bad = winstr_q ? (!pte_x || !pte_a)
                                 : (!(pte_a && (pte_r || (pte_x && mxr_i)))
                                    || (wstore_q && (!pte_w || !pte_d)));
  assign pte_fault = pte_bad || (pte_leaf ? (pte_misal || pte_perm_bad) : (lvl_q == 2'd0));

  assign walk_ok_leaf = (ws_q == W_WAIT) && mem_rvalid_i && !flush_i
                     && !pte_fault && pte_leaf;

  assign new_e.asid = asid_i;
  assign new_e.vpn  = wvpn_q;
  assign new_e.is1g = (lvl_q == 2'd2);
  assign new_e.is2m = (lvl_q == 2'd1);
  assign new_e.g    = gacc_q || pte_g;
  assign new_e.ppn  = pte_ppn;
  assign new_e.u    = pte_u;
  assign new_e.w    = pte_w;
  assign new_e.d    = pte_d;

  always_ff @(posedge clk_i) begin
    if (start) begin
      wvpn_q   <= st_vpn;
      winstr_q <= !start_d;
      wstore_q <= lsu_is_store_i;
    end
    if (start) begin
      lvl_q  <= 2'd2;
      tppn_q <= satp_ppn_i;
      gacc_q <= 1'b0;
    end else if (ws_q == W_WAIT && mem_rvalid_i && !pte_bad && !pte_leaf) begin
      lvl_q  <= lvl_q - 2'd1;
      tppn_q <= pte_ppn;
      gacc_q <= gacc_q || pte_g;
    end
    if (issuing && !pmp_allow)                       facc_q <= 1'b1;
    else if (ws_q == W_WAIT && mem_rvalid_i)         facc_q <= 1'b0;
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      ws_q <= W_IDLE;
    end else begin
      case (ws_q)
        W_IDLE: begin
          if (start) begin
            if (!pmp_allow)     ws_q <= W_FAULT;
            else if (mem_gnt_i) ws_q <= W_WAIT;
            else                ws_q <= W_REQ;
          end
        end
        W_REQ: begin
          if (!pmp_allow)      ws_q <= W_FAULT;
          else if (flush_i)    ws_q <= mem_gnt_i ? W_DRAIN : W_IDLE;
          else if (mem_gnt_i)  ws_q <= W_WAIT;
        end
        W_WAIT: begin
          if (mem_rvalid_i) begin
            if (flush_i)             ws_q <= W_IDLE;
            else if (pte_fault)      ws_q <= W_FAULT;
            else if (pte_leaf)       ws_q <= W_IDLE;
            else                     ws_q <= W_REQ;
          end else if (flush_i) begin
            ws_q <= W_DRAIN;
          end
        end
        W_DRAIN: if (mem_rvalid_i) ws_q <= W_IDLE;
        W_FAULT: ws_q <= W_IDLE;
        default: ws_q <= W_IDLE;
      endcase
    end
  end

  // ---------------------------------------------------------------------------
  // Load/store port
  // ---------------------------------------------------------------------------
  assign wfault_d = (ws_q == W_FAULT) && !winstr_q;
  assign wfault_i = (ws_q == W_FAULT) &&  winstr_q;

  assign daccess_err = ((ld_st_priv_lvl_i == PRIV_S) && !sum_i && lu_e[1].u)
                    || ((ld_st_priv_lvl_i == PRIV_U) && !lu_e[1].u);
  assign dst_bad     = !lu_e[1].w || !lu_e[1].d || daccess_err;

  assign d_tpa = {lu_e[1].ppn[43:18],
                  lu_e[1].is1g                  ? lsu_vaddr_i[29:21] : lu_e[1].ppn[17:9],
                  (lu_e[1].is1g || lu_e[1].is2m) ? lsu_vaddr_i[20:12] : lu_e[1].ppn[8:0],
                  lsu_vaddr_i[11:0]};

  always_comb begin
    lsu_valid_o     = 1'b0;
    lsu_exc_valid_o = 1'b0;
    lsu_exc_cause_o = '0;
    lsu_paddr_o     = en_ld_st_translation_i ? d_tpa : lsu_vaddr_i[55:0];
    if (rst_ni) begin
      if (wfault_d) begin
        lsu_valid_o     = 1'b1;
        lsu_exc_valid_o = 1'b1;
        lsu_exc_cause_o = facc_q ? (wstore_q ? 64'd7 : 64'd5) : (wstore_q ? 64'd15 : 64'd13);
      end else if (lsu_req_i && !en_ld_st_translation_i) begin
        lsu_valid_o = 1'b1;
      end else if (lsu_req_i && lu_hit[1]) begin
        lsu_valid_o = 1'b1;
        if (lsu_is_store_i ? dst_bad : daccess_err) begin
          lsu_exc_valid_o = 1'b1;
          lsu_exc_cause_o = lsu_is_store_i ? 64'd15 : 64'd13;
        end
      end
    end
  end

  assign lsu_exc_tval_o = lsu_vaddr_i;
  assign lsu_dtlb_hit_o = lsu_req_i && lu_hit[1];
  assign lsu_dtlb_ppn_o = lu_e[1].ppn;

  // ---------------------------------------------------------------------------
  // Fetch port
  // ---------------------------------------------------------------------------
  assign iaccess_err = ((priv_lvl_i == PRIV_U) && !lu_e[0].u)
                    || ((priv_lvl_i == PRIV_S) &&  lu_e[0].u);

  assign i_tpa = {lu_e[0].ppn[43:18],
                  lu_e[0].is1g                  ? fetch_vaddr_i[29:21] : lu_e[0].ppn[17:9],
                  (lu_e[0].is1g || lu_e[0].is2m) ? fetch_vaddr_i[20:12] : lu_e[0].ppn[8:0],
                  fetch_vaddr_i[11:0]};

  always_comb begin
    fetch_valid_o     = 1'b0;
    fetch_exc_valid_o = 1'b0;
    fetch_exc_cause_o = '0;
    fetch_paddr_o     = enable_translation_i ? i_tpa : fetch_vaddr_i[55:0];
    if (rst_ni) begin
      if (wfault_i) begin
        fetch_valid_o     = 1'b1;
        fetch_exc_valid_o = 1'b1;
        fetch_exc_cause_o = facc_q ? 64'd1 : 64'd12;
      end else if (fetch_req_i && !enable_translation_i) begin
        fetch_valid_o = 1'b1;
      end else if (fetch_req_i && lu_hit[0]) begin
        fetch_valid_o = 1'b1;
        if (iaccess_err) begin
          fetch_exc_valid_o = 1'b1;
          fetch_exc_cause_o = 64'd12;
        end
      end
    end
  end

  assign fetch_exc_tval_o = fetch_vaddr_i;

endmodule