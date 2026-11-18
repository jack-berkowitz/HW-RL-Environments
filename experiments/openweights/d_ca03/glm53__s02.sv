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

  // ---------------------------------------------------------------------
  // Types and internal state
  // ---------------------------------------------------------------------
  typedef struct packed {
    logic        valid;
    logic [15:0] asid;
    logic        global;
    logic [26:0] vpn;   // va[38:12]
    logic [1:0]  level; // 0 = 4kB, 1 = 2MB, 2 = 1GB
    logic [43:0] ppn;
    logic        r;
    logic        w;
    logic        x;
    logic        u;
    logic        d;
  } tlb_entry_t;

  typedef enum logic [1:0] { W_IDLE, W_REQ, W_WAIT, W_CHK } w_state_e;

  tlb_entry_t dtlb_q [0:15];
  tlb_entry_t itlb_q [0:15];
  logic [3:0] rr_dtlb_q, rr_itlb_q;

  w_state_e   w_state_q;
  logic [1:0]  w_level_q;
  logic [55:0] w_base_q;
  logic [63:0] w_pte_q;
  logic        w_port_q;      // 0 = lsu, 1 = fetch

  logic        lsu_busy_q, fetch_busy_q;
  logic        lsu_pending_q, fetch_pending_q;
  logic [63:0] lsu_va_q, fetch_va_q;
  logic        lsu_store_q;
  logic [1:0]  lsu_priv_q, fetch_priv_q;
  logic        lsu_sum_q, fetch_sum_q;
  logic        lsu_mxr_q, fetch_mxr_q;
  logic [15:0] lsu_asid_q, fetch_asid_q;

  logic        lsu_valid_q, fetch_valid_q;
  logic [55:0] lsu_paddr_q, fetch_paddr_q;
  logic        lsu_exc_valid_q, fetch_exc_valid_q;
  logic [63:0] lsu_exc_cause_q, fetch_exc_cause_q;
  logic [63:0] lsu_exc_tval_q, fetch_exc_tval_q;

  // combinational nets
  tlb_entry_t  dhit, ihit;
  logic        d_hit_fault, i_hit_fault;
  logic [63:0] d_hit_cause, i_hit_cause;
  logic [55:0] d_hit_pa,    i_hit_pa;
  logic [55:0] w_tbl_addr;
  logic [8:0]  w_vpn_sel;
  logic [63:0] w_va;
  logic        w_is_fetch, w_is_store;
  logic [1:0]  w_priv;
  logic        w_sum, w_mxr;
  logic [15:0] w_asid;
  logic        w_acc_denied, w_leaf, w_pf, w_ptr_continue, w_fault;
  logic [63:0] w_cause;
  logic [55:0] w_pa;
  logic [43:0] w_ppn;
  tlb_entry_t  w_entry;
  logic [3:0]  w_victim_d, w_victim_i;
  logic        w_install_d, w_install_i;

  // ---------------------------------------------------------------------
  // Functions
  // ---------------------------------------------------------------------
  // PMP match for entry n against a physical address.
  function automatic logic pmp_match(input int unsigned n, input logic [55:0] pa);
    logic [55:0] lo, hi;
    int unsigned t;
    pmp_match = 1'b0;
    case (pmpcfg_i[n][4:3])
      2'b00: pmp_match = 1'b0;                                    // OFF
      2'b01: pmp_match = (pa[55:2] == pmpaddr_i[n]);             // NA4
      2'b10: begin                                                // NAPOT
        t = 54;
        for (int unsigned i = 53; i >= 0; i--) begin
          if (pmpaddr_i[n][i] == 1'b0) t = i;                     // lowest zero
        end
        if (t >= 54) pmp_match = 1'b1;                            // all ones: everything
        else         pmp_match = ((pa >> (t + 2)) == (56'(pmpaddr_i[n]) >> t));
      end
      default: begin                                             // TOR
        hi = {pmpaddr_i[n], 2'b00};
        lo = (n == 0) ? 56'b0 : {pmpaddr_i[n-1], 2'b00};
        pmp_match = (pa >= lo) && (pa < hi);
      end
    endcase
  endfunction

  // Walker read permission: lowest matching entry wins; no match denies.
  function automatic logic pmp_read_ok(input logic [55:0] pa);
    logic found;
    pmp_read_ok = 1'b0;
    found = 1'b0;
    for (int unsigned n = 0; n < 8; n++) begin
      if (!found && pmp_match(n, pa)) begin
        found = 1'b1;
        pmp_read_ok = pmpcfg_i[n][0];                            // R bit
      end
    end
  endfunction

  // Permission check on a leaf (A4).
  function automatic logic perm_ok(
    input logic r, input logic w, input logic x, input logic u,
    input logic is_store, input logic is_fetch,
    input logic mxr, input logic sum, input logic [1:0] priv);
    perm_ok = 1'b1;
    if (priv == 2'b00) begin
      if (!u) perm_ok = 1'b0;
    end else if (priv == 2'b01) begin
      if (u) begin
        if (is_fetch)     perm_ok = 1'b0;   // never executable in S-mode
        else if (!sum)    perm_ok = 1'b0;
      end
    end
    if (is_fetch) begin
      if (!x) perm_ok = 1'b0;
    end else if (is_store) begin
      if (!w) perm_ok = 1'b0;
    end else begin
      if (!(r || (x && mxr))) perm_ok = 1'b0;
    end
  endfunction

  // Physical address for a leaf at the given level (A2).
  function automatic logic [55:0] leaf_pa(
    input logic [43:0] ppn, input logic [63:0] va, input logic [1:0] level);
    case (level)
      2'd0:    leaf_pa = {ppn,          va[11:0]};
      2'd1:    leaf_pa = {ppn[43:9],  va[20:12], va[11:0]};
      default: leaf_pa = {ppn[43:18], va[29:12], va[11:0]};
    endcase
  endfunction

  // Fully associative lookup; later (higher index) hit wins.
  function automatic tlb_entry_t tlb_lookup(input logic is_i, input logic [63:0] va);
    tlb_entry_t e, c;
    logic [26:0] vpn, m;
    e = '0;
    vpn = va[38:12];
    for (int unsigned n = 0; n < 16; n++) begin
      c = is_i ? itlb_q[n] : dtlb_q[n];
      case (c.level)
        2'd0:    m = 27'h07FF_FFFF;
        2'd1:    m = 27'h07FF_FF00;
        default: m = 27'h07FC_0000;
      endcase
      if (c.valid && (c.global || (c.asid == asid_i)) &&
          ((c.vpn & m) == (vpn & m))) e = c;
    end
    return e;
  endfunction

  // ---------------------------------------------------------------------
  // Combinational logic
  // ---------------------------------------------------------------------
  assign dhit = tlb_lookup(1'b0, lsu_vaddr_i);
  assign ihit = tlb_lookup(1'b1, fetch_vaddr_i);

  // hit-path results (permission / dirty re-checked per request, A4/A5)
  always_comb begin
    d_hit_fault = 1'b0; d_hit_cause = '0; d_hit_pa = '0;
    if (dhit.valid) begin
      if (!perm_ok(dhit.r, dhit.w, dhit.x, dhit.u,
                   lsu_is_store_i, 1'b0, mxr_i, sum_i, ld_st_priv_lvl_i) ||
          (lsu_is_store_i && !dhit.d)) begin
        d_hit_fault = 1'b1;
        d_hit_cause = lsu_is_store_i ? 64'd15 : 64'd13;
      end else begin
        d_hit_pa = leaf_pa(dhit.ppn, lsu_vaddr_i, dhit.level);
      end
    end
  end

  always_comb begin
    i_hit_fault = 1'b0; i_hit_cause = '0; i_hit_pa = '0;
    if (ihit.valid) begin
      if (!perm_ok(ihit.r, ihit.w, ihit.x, ihit.u,
                   1'b0, 1'b1, mxr_i, sum_i, priv_lvl_i)) begin
        i_hit_fault = 1'b1;
        i_hit_cause = 64'd12;
      end else begin
        i_hit_pa = leaf_pa(ihit.ppn, fetch_vaddr_i, ihit.level);
      end
    end
  end

  // walker context
  assign w_va        = w_port_q ? fetch_va_q  : lsu_va_q;
  assign w_is_fetch  = w_port_q;
  assign w_is_store  = (~w_port_q) & lsu_store_q;
  assign w_priv      = w_port_q ? fetch_priv_q : lsu_priv_q;
  assign w_sum       = w_port_q ? fetch_sum_q  : lsu_sum_q;
  assign w_mxr       = w_port_q ? fetch_mxr_q  : lsu_mxr_q;
  assign w_asid      = w_port_q ? fetch_asid_q : lsu_asid_q;

  always_comb begin
    case (w_level_q)
      2'd2:    w_vpn_sel = w_va[38:30];
      2'd1:    w_vpn_sel = w_va[29:21];
      default: w_vpn_sel = w_va[20:12];
    endcase
    w_tbl_addr = w_base_q + (56'(w_vpn_sel) << 3);
  end

  assign mem_addr_o = w_tbl_addr;
  assign mem_req_o  = (w_state_q == W_REQ);

  // walker check-stage analysis (A1, A3, A4, A5, A7, A8)
  always_comb begin
    w_ppn          = w_pte_q[53:10];
    w_leaf         = w_pte_q[1] | w_pte_q[3];
    w_acc_denied   = !pmp_read_ok(w_tbl_addr);
    w_pf           = 1'b0;
    w_ptr_continue = 1'b0;
    w_fault        = 1'b0;
    w_cause        = '0;
    w_pa           = '0;
    w_entry        = '0;
    if (w_acc_denied) begin
      w_fault = 1'b1;                       // access fault has priority (A7)
      w_cause = w_is_fetch ? 64'd1 : (w_is_store ? 64'd7 : 64'd5);
    end else begin
      if (!w_pte_q[0] || (w_pte_q[2] && !w_pte_q[1])) begin
        w_pf = 1'b1;                       // invalid or reserved encoding
      end else if (!w_leaf) begin
        if (w_level_q == 2'd0) w_pf = 1'b1; // pointer past level 0
        else                   w_ptr_continue = 1'b1;
      end else begin
        case (w_level_q)
          2'd1:    if (|w_ppn[8:0])  w_pf = 1'b1;  // misaligned superpage
          2'd2:    if (|w_ppn[17:0]) w_pf = 1'b1;
          default: ;
        endcase
        if (!w_pf && !w_pte_q[6]) w_pf = 1'b1;                    // A = 0
        if (!w_pf && w_is_store && !w_pte_q[7]) w_pf = 1'b1;      // D = 0
        if (!w_pf && !perm_ok(w_pte_q[1], w_pte_q[2], w_pte_q[3], w_pte_q[4],
                              w_is_store, w_is_fetch, w_mxr, w_sum, w_priv))
          w_pf = 1'b1;
      end
      if (w_pf) begin
        w_fault = 1'b1;
        w_cause = w_is_fetch ? 64'd12 : (w_is_store ? 64'd15 : 64'd13);
      end else if (!w_ptr_continue) begin
        w_pa    = leaf_pa(w_ppn, w_va, w_level_q);
        w_entry = '{valid: 1'b1, asid: w_asid, global: w_pte_q[5],
                    vpn: w_va[38:12], level: w_level_q, ppn: w_ppn,
                    r: w_pte_q[1], w: w_pte_q[2], x: w_pte_q[3],
                    u: w_pte_q[4], d: w_pte_q[7]};
      end
    end
  end

  // install conditions and victim selection
  assign w_install_d = (w_state_q == W_CHK) && !flush_i && !w_ptr_continue &&
                       !w_fault && !w_port_q;
  assign w_install_i = (w_state_q == W_CHK) && !flush_i && !w_ptr_continue &&
                       !w_fault &&  w_port_q;

  always_comb begin
    w_victim_d = rr_dtlb_q;
    w_victim_i = rr_itlb_q;
    for (int unsigned n = 0; n < 16; n++) begin
      if (!dtlb_q[n].valid) w_victim_d = 4'(n);
      if (!itlb_q[n].valid) w_victim_i = 4'(n);
    end
  end

  // ---------------------------------------------------------------------
  // Sequential logic: control / walker / port state
  // ---------------------------------------------------------------------
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      lsu_busy_q <= 1'b0;  fetch_busy_q <= 1'b0;
      lsu_pending_q <= 1'b0; fetch_pending_q <= 1'b0;
      lsu_va_q <= '0; fetch_va_q <= '0; lsu_store_q <= 1'b0;
      lsu_priv_q <= '0; fetch_priv_q <= '0;
      lsu_sum_q <= 1'b0; fetch_sum_q <= 1'b0;
      lsu_mxr_q <= 1'b0; fetch_mxr_q <= 1'b0;
      lsu_asid_q <= '0; fetch_asid_q <= '0;
      lsu_valid_q <= 1'b0; fetch_valid_q <= 1'b0;
      lsu_paddr_q <= '0; fetch_paddr_q <= '0;
      lsu_exc_valid_q <= 1'b0; fetch_exc_valid_q <= 1'b0;
      lsu_exc_cause_q <= '0; fetch_exc_cause_q <= '0;
      lsu_exc_tval_q <= '0; fetch_exc_tval_q <= '0;
      w_state_q <= W_IDLE; w_level_q <= '0; w_base_q <= '0;
      w_pte_q <= '0; w_port_q <= 1'b0;
    end else begin
      lsu_valid_q   <= 1'b0;   // valid is a one-cycle retirement pulse
      fetch_valid_q <= 1'b0;

      // ---------------- walker FSM ----------------
      case (w_state_q)
        W_IDLE: begin
          if (!flush_i) begin
            if (lsu_pending_q) begin
              w_port_q <= 1'b0;
              w_level_q <= 2'd2;
              w_base_q <= {satp_ppn_i, 12'b0};
              w_state_q <= W_REQ;
            end else if (fetch_pending_q) begin
              w_port_q <= 1'b1;
              w_level_q <= 2'd2;
              w_base_q <= {satp_ppn_i, 12'b0};
              w_state_q <= W_REQ;
            end
          end
        end
        W_REQ: begin
          if (flush_i) begin
            w_state_q <= W_IDLE;              // abort; pending stays -> restart
          end else if (mem_gnt_i) begin
            if (mem_rvalid_i) begin
              w_pte_q <= mem_rdata_i;
              w_state_q <= W_CHK;
            end else begin
              w_state_q <= W_WAIT;
            end
          end
        end
        W_WAIT: begin
          if (flush_i) begin
            w_state_q <= W_IDLE;
          end else if (mem_rvalid_i) begin
            w_pte_q <= mem_rdata_i;
            w_state_q <= W_CHK;
          end
        end
        W_CHK: begin
          if (flush_i) begin
            w_state_q <= W_IDLE;              // aborted; will be re-walked
          end else if (w_ptr_continue) begin
            w_base_q  <= {w_pte_q[53:10], 12'b0};
            w_level_q <= w_level_q - 2'd1;
            w_state_q <= W_REQ;
          end else begin
            w_state_q <= W_IDLE;
            if (!w_port_q) begin
              lsu_valid_q     <= 1'b1;        // faults retire too (A11)
              lsu_exc_valid_q <= w_fault;
              lsu_exc_cause_q <= w_cause;
              lsu_exc_tval_q  <= lsu_va_q;
              lsu_paddr_q     <= w_fault ? 56'b0 : w_pa;
              lsu_busy_q      <= 1'b0;
              lsu_pending_q   <= 1'b0;
            end else begin
              fetch_valid_q     <= 1'b1;
              fetch_exc_valid_q <= w_fault;
              fetch_exc_cause_q <= w_cause;
              fetch_exc_tval_q  <= fetch_va_q;
              fetch_paddr_q     <= w_fault ? 56'b0 : w_pa;
              fetch_busy_q      <= 1'b0;
              fetch_pending_q   <= 1'b0;
            end
          end
        end
        default: w_state_q <= W_IDLE;
      endcase

      // ---------------- LSU accept ----------------
      if (!lsu_busy_q && !lsu_pending_q && lsu_req_i && !lsu_valid_q) begin
        if (!en_ld_st_translation_i) begin
          lsu_valid_q     <= 1'b1;            // BARE mode (C1)
          lsu_exc_valid_q <= 1'b0;
          lsu_paddr_q     <= lsu_vaddr_i[55:0];
          lsu_exc_tval_q  <= lsu_vaddr_i;
        end else if (dhit.valid) begin
          lsu_valid_q     <= 1'b1;            // TLB hit
          lsu_exc_valid_q <= d_hit_fault;
          lsu_exc_cause_q <= d_hit_cause;
          lsu_exc_tval_q  <= lsu_vaddr_i;
          lsu_paddr_q     <= d_hit_fault ? 56'b0 : d_hit_pa;
        end else begin
          lsu_busy_q    <= 1'b1;               // miss: walk
          lsu_pending_q <= 1'b1;
          lsu_va_q      <= lsu_vaddr_i;
          lsu_store_q   <= lsu_is_store_i;
          lsu_priv_q    <= ld_st_priv_lvl_i;
          lsu_sum_q     <= sum_i;
          lsu_mxr_q     <= mxr_i;
          lsu_asid_q    <= asid_i;
        end
      end

      // ---------------- fetch accept ----------------
      if (!fetch_busy_q && !fetch_pending_q && fetch_req_i && !fetch_valid_q) begin
        if (!enable_translation_i) begin
          fetch_valid_q     <= 1'b1;
          fetch_exc_valid_q <= 1'b0;
          fetch_paddr_q     <= fetch_vaddr_i[55:0];
          fetch_exc_tval_q  <= fetch_vaddr_i;
        end else if (ihit.valid) begin
          fetch_valid_q     <= 1'b1;
          fetch_exc_valid_q <= i_hit_fault;
          fetch_exc_cause_q <= i_hit_cause;
          fetch_exc_tval_q  <= fetch_vaddr_i;
          fetch_paddr_q     <= i_hit_fault ? 56'b0 : i_hit_pa;
        end else begin
          fetch_busy_q    <= 1'b1;
          fetch_pending_q <= 1'b1;
          fetch_va_q      <= fetch_vaddr_i;
          fetch_priv_q    <= priv_lvl_i;
          fetch_sum_q     <= sum_i;
          fetch_mxr_q     <= mxr_i;
          fetch_asid_q    <= asid_i;
        end
      end
    end
  end

  // ---------------------------------------------------------------------
  // Sequential logic: TLB arrays (single writer)
  // ---------------------------------------------------------------------
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      for (int unsigned n = 0; n < 16; n++) begin
        dtlb_q[n] <= '0;
        itlb_q[n] <= '0;
      end
      rr_dtlb_q <= '0;
      rr_itlb_q <= '0;
    end else if (flush_tlb_i) begin
      for (int unsigned n = 0; n < 16; n++) begin
        dtlb_q[n].valid <= 1'b0;             // full flush (C2)
        itlb_q[n].valid <= 1'b0;
      end
    end else begin
      if (w_install_d) begin
        dtlb_q[w_victim_d] <= w_entry;
        rr_dtlb_q <= rr_dtlb_q + 4'd1;
      end
      if (w_install_i) begin
        itlb_q[w_victim_i] <= w_entry;
        rr_itlb_q <= rr_itlb_q + 4'd1;
      end
    end
  end

  // ---------------------------------------------------------------------
  // Outputs
  // ---------------------------------------------------------------------
  assign lsu_valid_o      = lsu_valid_q;
  assign lsu_paddr_o      = lsu_paddr_q;
  assign lsu_exc_valid_o  = lsu_exc_valid_q;
  assign lsu_exc_cause_o  = lsu_exc_cause_q;
  assign lsu_exc_tval_o   = lsu_exc_tval_q;
  assign fetch_valid_o     = fetch_valid_q;
  assign fetch_paddr_o     = fetch_paddr_q;
  assign fetch_exc_valid_o = fetch_exc_valid_q;
  assign fetch_exc_cause_o = fetch_exc_cause_q;
  assign fetch_exc_tval_o  = fetch_exc_tval_q;

  // unscored reporting ports (T2)
  assign lsu_dtlb_hit_o  = dhit.valid;
  assign lsu_dtlb_ppn_o  = dhit.ppn;
  assign dtlb_miss_o     = lsu_pending_q;
  assign itlb_miss_o     = fetch_pending_q;
  assign mem_tag_valid_o = 1'b0;
  assign mem_kill_o      = 1'b0;

  // unused narrowing inputs (full flush is conservative, C2)
  logic unused_inputs;
  assign unused_inputs = ^{asid_to_be_flushed_i, vaddr_to_be_flushed_i};

endmodule
