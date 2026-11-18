// =============================================================================
// sv39_mmu.sv — d_ca03 submission
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

  // ------------------------------------------------------------------
  // Types
  // ------------------------------------------------------------------
  typedef struct packed {
    logic        vld;
    logic [1:0]  level;   // 0=4KB, 1=2MB, 2=1GB
    logic        g;
    logic        u;
    logic        r;
    logic        w;
    logic        x;
    logic        a;
    logic        d;
    logic [15:0] asid;
    logic [26:0] vpn;
    logic [43:0] ppn;
  } tlb_e_t;

  typedef enum logic [1:0] {
    P_IDLE = 2'd0,
    P_RET  = 2'd1,
    P_WAIT = 2'd2
  } pstate_t;

  typedef enum logic [1:0] {
    W_IDLE = 2'd0,
    W_REQ  = 2'd1,
    W_WAIT = 2'd2
  } wstate_t;

  // ------------------------------------------------------------------
  // Registers
  // ------------------------------------------------------------------
  tlb_e_t itlb_q [0:15];
  tlb_e_t dtlb_q [0:15];
  logic [3:0] itlb_rr_q, dtlb_rr_q;

  pstate_t lsu_st_q, fetch_st_q;

  logic [63:0] lsu_va_q;
  logic        lsu_str_q;
  logic [1:0]  lsu_priv_q;
  logic        lsu_sum_q, lsu_mxr_q;

  logic [63:0] f_va_q;
  logic [1:0]  f_priv_q;
  logic        f_sum_q, f_mxr_q;

  logic        lsu_exc_q, f_exc_q;
  logic [63:0] lsu_cause_q, f_cause_q;
  logic [55:0] lsu_pa_q, f_pa_q;
  logic [63:0] lsu_tval_q, f_tval_q;

  wstate_t     w_st_q;
  logic        w_fetch_q;
  logic [1:0]  w_level_q;
  logic [55:0] w_base_q;
  logic        w_discard_q;
  logic [63:0] w_va_q;
  logic        w_is_store_q;
  logic [1:0]  w_priv_q;
  logic        w_sum_q, w_mxr_q;

  // ------------------------------------------------------------------
  // Functions
  // ------------------------------------------------------------------
  function automatic logic perm_chk(
    input logic r, input logic w, input logic x,
    input logic u, input logic a, input logic d,
    input logic is_fetch, input logic is_store,
    input logic [1:0] priv,
    input logic sum, input logic mxr
  );
    logic ok;
  begin
    ok = 1'b1;
    if (is_fetch)
      ok = x;
    else if (is_store)
      ok = w;
    else
      ok = r || (x && mxr);
    if (priv == 2'b00) begin
      ok = ok && u;
    end else if (priv == 2'b01) begin
      if (u)
        ok = is_fetch ? 1'b0 : (ok && sum);
    end
    ok = ok && a;
    if (is_store)
      ok = ok && d;
    perm_chk = ok;
  end
  endfunction

  function automatic logic pmp_read_ok(input logic [55:0] addr);
    logic        ok;
    logic        fnd;
    logic        m;
    logic [1:0]  mode;
    logic [55:0] tbase;
    logic [55:0] ttop;
    logic [63:0] a64;
    logic [63:0] p64;
    logic [53:0] prev;
    int unsigned t;
    int unsigned j;
  begin
    ok   = 1'b0;
    fnd  = 1'b0;
    prev = 54'd0;
    for (int unsigned n = 0; n < 8; n++) begin
      mode = pmpcfg_i[n][4:3];
      m = 1'b0;
      case (mode)
        2'b01: begin
          tbase = {prev, 2'b00};
          ttop  = {pmpaddr_i[n], 2'b00};
          m = (addr >= tbase) && (addr < ttop);
        end
        2'b10: begin
          m = (addr[55:2] == pmpaddr_i[n]);
        end
        2'b11: begin
          t = 0;
          for (j = 0; j < 54; j++) begin
            if (j == t && pmpaddr_i[n][j])
              t = j + 1;
          end
          a64 = {8'd0, addr};
          p64 = {8'd0, pmpaddr_i[n], 2'b00};
          m = (a64 >> (t + 3)) == (p64 >> (t + 3));
        end
        default: m = 1'b0;
      endcase
      if (!fnd && mode != 2'b00 && m) begin
        fnd = 1'b1;
        ok  = pmpcfg_i[n][0];
      end
      prev = pmpaddr_i[n];
    end
    pmp_read_ok = ok;
  end
  endfunction

  // ------------------------------------------------------------------
  // Combinational: TLB lookup
  // ------------------------------------------------------------------
  logic        d_hit_any, i_hit_any;
  tlb_e_t      d_hit_e, i_hit_e;

  always_comb begin
    logic dm;
    logic dfnd;
    logic im;
    logic ifnd;
    d_hit_any = 1'b0;
    d_hit_e   = '0;
    dfnd      = 1'b0;
    for (int unsigned k = 0; k < 16; k++) begin
      dm = 1'b0;
      case (dtlb_q[k].level)
        2'd2:    dm = (dtlb_q[k].vpn[26:18] == lsu_vaddr_i[38:30]);
        2'd1:    dm = (dtlb_q[k].vpn[26:9]  == lsu_vaddr_i[38:21]);
        default: dm = (dtlb_q[k].vpn        == lsu_vaddr_i[38:12]);
      endcase
      if (!dfnd && dtlb_q[k].vld &&
          (dtlb_q[k].g || (dtlb_q[k].asid == asid_i)) && dm) begin
        dfnd      = 1'b1;
        d_hit_any = 1'b1;
        d_hit_e   = dtlb_q[k];
      end
    end
    i_hit_any = 1'b0;
    i_hit_e   = '0;
    ifnd      = 1'b0;
    for (int unsigned k = 0; k < 16; k++) begin
      im = 1'b0;
      case (itlb_q[k].level)
        2'd2:    im = (itlb_q[k].vpn[26:18] == fetch_vaddr_i[38:30]);
        2'd1:    im = (itlb_q[k].vpn[26:9]  == fetch_vaddr_i[38:21]);
        default: im = (itlb_q[k].vpn        == fetch_vaddr_i[38:12]);
      endcase
      if (!ifnd && itlb_q[k].vld &&
          (itlb_q[k].g || (itlb_q[k].asid == asid_i)) && im) begin
        ifnd      = 1'b1;
        i_hit_any = 1'b1;
        i_hit_e   = itlb_q[k];
      end
    end
  end

  // ------------------------------------------------------------------
  // Combinational: hit PA and permission
  // ------------------------------------------------------------------
  logic [55:0] d_hit_pa, i_hit_pa;
  logic        d_hit_perm, i_hit_perm;

  always_comb begin
    case (d_hit_e.level)
      2'd2:    d_hit_pa = {d_hit_e.ppn[43:18], lsu_vaddr_i[29:0]};
      2'd1:    d_hit_pa = {d_hit_e.ppn[43:9],  lsu_vaddr_i[20:0]};
      default: d_hit_pa = {d_hit_e.ppn,        lsu_vaddr_i[11:0]};
    endcase
  end

  always_comb begin
    case (i_hit_e.level)
      2'd2:    i_hit_pa = {i_hit_e.ppn[43:18], fetch_vaddr_i[29:0]};
      2'd1:    i_hit_pa = {i_hit_e.ppn[43:9],  fetch_vaddr_i[20:0]};
      default: i_hit_pa = {i_hit_e.ppn,        fetch_vaddr_i[11:0]};
    endcase
  end

  assign d_hit_perm = perm_chk(d_hit_e.r, d_hit_e.w, d_hit_e.x, d_hit_e.u,
                               d_hit_e.a, d_hit_e.d,
                               1'b0, lsu_is_store_i, ld_st_priv_lvl_i, sum_i, mxr_i);

  assign i_hit_perm = perm_chk(i_hit_e.r, i_hit_e.w, i_hit_e.x, i_hit_e.u,
                               i_hit_e.a, i_hit_e.d,
                               1'b1, 1'b0, priv_lvl_i, sum_i, mxr_i);

  // ------------------------------------------------------------------
  // Combinational: miss detection (for fast walk start)
  // ------------------------------------------------------------------
  logic lsu_miss_now, fetch_miss_now;

  assign lsu_miss_now   = (lsu_st_q   == P_IDLE) && lsu_req_i   &&
                          en_ld_st_translation_i   && !d_hit_any;
  assign fetch_miss_now = (fetch_st_q == P_IDLE) && fetch_req_i &&
                          enable_translation_i     && !i_hit_any;

  // ------------------------------------------------------------------
  // Combinational: walker address and PMP check
  // ------------------------------------------------------------------
  logic [8:0]  w_idx;
  logic [55:0] w_pte_addr;
  logic        w_pmp_ok;

  always_comb begin
    case (w_level_q)
      2'd2:    w_idx = w_va_q[38:30];
      2'd1:    w_idx = w_va_q[29:21];
      default: w_idx = w_va_q[20:12];
    endcase
    w_pte_addr = {w_base_q[55:12], w_idx, 3'b000};
    w_pmp_ok   = pmp_read_ok(w_pte_addr);
  end

  // ------------------------------------------------------------------
  // Combinational: PTE decode
  // ------------------------------------------------------------------
  logic        pte_v, pte_r, pte_w, pte_x, pte_u, pte_g, pte_a, pte_d;
  logic [43:0] pte_ppn;
  logic        pte_leaf, pte_bad, pte_misaligned, pte_perm_ok;

  assign pte_v    = mem_rdata_i[0];
  assign pte_r    = mem_rdata_i[1];
  assign pte_w    = mem_rdata_i[2];
  assign pte_x    = mem_rdata_i[3];
  assign pte_u    = mem_rdata_i[4];
  assign pte_g    = mem_rdata_i[5];
  assign pte_a    = mem_rdata_i[6];
  assign pte_d    = mem_rdata_i[7];
  assign pte_ppn  = mem_rdata_i[53:10];
  assign pte_leaf = pte_r || pte_x;
  assign pte_bad  = (!pte_v) || (pte_w && !pte_r);

  always_comb begin
    case (w_level_q)
      2'd2:    pte_misaligned = (pte_ppn[17:0] != 18'd0);
      2'd1:    pte_misaligned = (pte_ppn[8:0]  != 9'd0);
      default: pte_misaligned = 1'b0;
    endcase
  end

  assign pte_perm_ok = perm_chk(pte_r, pte_w, pte_x, pte_u, pte_a, pte_d,
                                w_fetch_q, w_is_store_q, w_priv_q, w_sum_q, w_mxr_q);

  // ------------------------------------------------------------------
  // Combinational: walk PA
  // ------------------------------------------------------------------
  logic [55:0] w_pa;

  always_comb begin
    case (w_level_q)
      2'd2:    w_pa = {pte_ppn[43:18], w_va_q[29:0]};
      2'd1:    w_pa = {pte_ppn[43:9],  w_va_q[20:0]};
      default: w_pa = {pte_ppn,        w_va_q[11:0]};
    endcase
  end

  // ------------------------------------------------------------------
  // Combinational: fault causes
  // ------------------------------------------------------------------
  logic [63:0] w_pf_cause, w_af_cause;

  assign w_pf_cause = w_fetch_q    ? 64'd12 : (w_is_store_q ? 64'd15 : 64'd13);
  assign w_af_cause = w_fetch_q    ? 64'd1  : (w_is_store_q ? 64'd7  : 64'd5);

  // ------------------------------------------------------------------
  // Combinational: install entry
  // ------------------------------------------------------------------
  tlb_e_t w_install_e;

  always_comb begin
    w_install_e        = '0;
    w_install_e.vld    = 1'b1;
    w_install_e.level  = w_level_q;
    w_install_e.g      = pte_g;
    w_install_e.u      = pte_u;
    w_install_e.r      = pte_r;
    w_install_e.w      = pte_w;
    w_install_e.x      = pte_x;
    w_install_e.a      = pte_a;
    w_install_e.d      = pte_d;
    w_install_e.asid   = asid_i;
    w_install_e.vpn    = w_va_q[38:12];
    w_install_e.ppn    = pte_ppn;
  end

  // ------------------------------------------------------------------
  // Combinational: victim selection
  // ------------------------------------------------------------------
  logic [3:0] d_victim, i_victim;
  logic       d_victim_inv, i_victim_inv;

  always_comb begin
    d_victim     = dtlb_rr_q;
    d_victim_inv = 1'b0;
    for (int unsigned k = 0; k < 16; k++) begin
      if (!d_victim_inv && !dtlb_q[k].vld) begin
        d_victim_inv = 1'b1;
        d_victim     = k[3:0];
      end
    end
  end

  always_comb begin
    i_victim     = itlb_rr_q;
    i_victim_inv = 1'b0;
    for (int unsigned k = 0; k < 16; k++) begin
      if (!i_victim_inv && !itlb_q[k].vld) begin
        i_victim_inv = 1'b1;
        i_victim     = k[3:0];
      end
    end
  end

  // ------------------------------------------------------------------
  // Sequential logic
  // ------------------------------------------------------------------
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      for (int unsigned k = 0; k < 16; k++) begin
        itlb_q[k] <= '0;
        dtlb_q[k] <= '0;
      end
      itlb_rr_q   <= 4'd0;
      dtlb_rr_q   <= 4'd0;
      lsu_st_q    <= P_IDLE;
      lsu_va_q    <= 64'd0;
      lsu_str_q   <= 1'b0;
      lsu_priv_q  <= 2'd0;
      lsu_sum_q   <= 1'b0;
      lsu_mxr_q   <= 1'b0;
      lsu_exc_q   <= 1'b0;
      lsu_cause_q <= 64'd0;
      lsu_pa_q    <= 56'd0;
      lsu_tval_q  <= 64'd0;
      fetch_st_q  <= P_IDLE;
      f_va_q      <= 64'd0;
      f_priv_q    <= 2'd0;
      f_sum_q     <= 1'b0;
      f_mxr_q     <= 1'b0;
      f_exc_q     <= 1'b0;
      f_cause_q   <= 64'd0;
      f_pa_q      <= 56'd0;
      f_tval_q    <= 64'd0;
      w_st_q      <= W_IDLE;
      w_fetch_q   <= 1'b0;
      w_level_q   <= 2'd0;
      w_base_q    <= 56'd0;
      w_discard_q <= 1'b0;
      w_va_q      <= 64'd0;
      w_is_store_q <= 1'b0;
      w_priv_q    <= 2'd0;
      w_sum_q     <= 1'b0;
      w_mxr_q     <= 1'b0;
    end else begin
      // ==============================================================
      // TLB flush (C2)
      // ==============================================================
      if (flush_tlb_i) begin
        for (int unsigned k = 0; k < 16; k++) begin
          itlb_q[k].vld <= 1'b0;
          dtlb_q[k].vld <= 1'b0;
        end
      end

      // ==============================================================
      // Walker FSM
      // ==============================================================
      case (w_st_q)
        W_IDLE: begin
          if (lsu_miss_now) begin
            w_fetch_q    <= 1'b0;
            w_va_q       <= lsu_vaddr_i;
            w_is_store_q <= lsu_is_store_i;
            w_priv_q     <= ld_st_priv_lvl_i;
            w_sum_q      <= sum_i;
            w_mxr_q      <= mxr_i;
            w_level_q    <= 2'd2;
            w_base_q     <= {satp_ppn_i, 12'd0};
            w_st_q       <= W_REQ;
          end else if (fetch_miss_now) begin
            w_fetch_q    <= 1'b1;
            w_va_q       <= fetch_vaddr_i;
            w_is_store_q <= 1'b0;
            w_priv_q     <= priv_lvl_i;
            w_sum_q      <= sum_i;
            w_mxr_q      <= mxr_i;
            w_level_q    <= 2'd2;
            w_base_q     <= {satp_ppn_i, 12'd0};
            w_st_q       <= W_REQ;
          end else if (lsu_st_q == P_WAIT) begin
            w_fetch_q    <= 1'b0;
            w_va_q       <= lsu_va_q;
            w_is_store_q <= lsu_str_q;
            w_priv_q     <= lsu_priv_q;
            w_sum_q      <= lsu_sum_q;
            w_mxr_q      <= lsu_mxr_q;
            w_level_q    <= 2'd2;
            w_base_q     <= {satp_ppn_i, 12'd0};
            w_st_q       <= W_REQ;
          end else if (fetch_st_q == P_WAIT) begin
            w_fetch_q    <= 1'b1;
            w_va_q       <= f_va_q;
            w_is_store_q <= 1'b0;
            w_priv_q     <= f_priv_q;
            w_sum_q      <= f_sum_q;
            w_mxr_q      <= f_mxr_q;
            w_level_q    <= 2'd2;
            w_base_q     <= {satp_ppn_i, 12'd0};
            w_st_q       <= W_REQ;
          end
        end

        W_REQ: begin
          if (flush_i && mem_gnt_i) begin
            w_st_q      <= W_WAIT;
            w_discard_q <= 1'b1;
          end else if (flush_i) begin
            w_level_q   <= 2'd2;
            w_base_q    <= {satp_ppn_i, 12'd0};
            w_discard_q <= 1'b0;
          end else if (!w_pmp_ok) begin
            // PMP access fault (A8, A7)
            if (w_fetch_q) begin
              f_exc_q     <= 1'b1;
              f_cause_q   <= w_af_cause;
              f_tval_q    <= w_va_q;
              f_pa_q      <= 56'd0;
              fetch_st_q  <= P_RET;
            end else begin
              lsu_exc_q   <= 1'b1;
              lsu_cause_q <= w_af_cause;
              lsu_tval_q  <= w_va_q;
              lsu_pa_q    <= 56'd0;
              lsu_st_q    <= P_RET;
            end
            w_st_q <= W_IDLE;
          end else if (mem_gnt_i) begin
            w_st_q <= W_WAIT;
          end
        end

        W_WAIT: begin
          if (flush_i) begin
            w_discard_q <= 1'b1;
          end
          if (mem_rvalid_i) begin
            if (w_discard_q || flush_i) begin
              // Discard stale response, restart walk (C3)
              w_discard_q <= 1'b0;
              w_level_q   <= 2'd2;
              w_base_q    <= {satp_ppn_i, 12'd0};
              w_st_q      <= W_REQ;
            end else if (pte_bad || (pte_leaf && pte_misaligned)) begin
              // Page fault (A1, A3)
              if (w_fetch_q) begin
                f_exc_q     <= 1'b1;
                f_cause_q   <= w_pf_cause;
                f_tval_q    <= w_va_q;
                f_pa_q      <= 56'd0;
                fetch_st_q  <= P_RET;
              end else begin
                lsu_exc_q   <= 1'b1;
                lsu_cause_q <= w_pf_cause;
                lsu_tval_q  <= w_va_q;
                lsu_pa_q    <= 56'd0;
                lsu_st_q    <= P_RET;
              end
              w_st_q <= W_IDLE;
            end else if (pte_leaf) begin
              // Aligned leaf
              if (pte_perm_ok) begin
                // Success: install and deliver
                if (w_fetch_q) begin
                  itlb_q[i_victim] <= w_install_e;
                  if (!i_victim_inv)
                    itlb_rr_q <= i_victim + 4'd1;
                  f_exc_q    <= 1'b0;
                  f_pa_q     <= w_pa;
                  fetch_st_q <= P_RET;
                end else begin
                  dtlb_q[d_victim] <= w_install_e;
                  if (!d_victim_inv)
                    dtlb_rr_q <= d_victim + 4'd1;
                  lsu_exc_q <= 1'b0;
                  lsu_pa_q  <= w_pa;
                  lsu_st_q  <= P_RET;
                end
                w_st_q <= W_IDLE;
              end else begin
                // Permission page fault (A4, A5)
                if (w_fetch_q) begin
                  f_exc_q     <= 1'b1;
                  f_cause_q   <= w_pf_cause;
                  f_tval_q    <= w_va_q;
                  f_pa_q      <= 56'd0;
                  fetch_st_q  <= P_RET;
                end else begin
                  lsu_exc_q   <= 1'b1;
                  lsu_cause_q <= w_pf_cause;
                  lsu_tval_q  <= w_va_q;
                  lsu_pa_q    <= 56'd0;
                  lsu_st_q    <= P_RET;
                end
                w_st_q <= W_IDLE;
              end
            end else begin
              // Non-leaf: descend or fault
              if (w_level_q == 2'd0) begin
                if (w_fetch_q) begin
                  f_exc_q     <= 1'b1;
                  f_cause_q   <= w_pf_cause;
                  f_tval_q    <= w_va_q;
                  f_pa_q      <= 56'd0;
                  fetch_st_q  <= P_RET;
                end else begin
                  lsu_exc_q   <= 1'b1;
                  lsu_cause_q <= w_pf_cause;
                  lsu_tval_q  <= w_va_q;
                  lsu_pa_q    <= 56'd0;
                  lsu_st_q    <= P_RET;
                end
                w_st_q <= W_IDLE;
              end else begin
                w_base_q  <= {pte_ppn, 12'd0};
                w_level_q <= w_level_q - 2'd1;
                w_st_q    <= W_REQ;
              end
            end
          end
        end

        default: begin
          w_st_q <= W_IDLE;
        end
      endcase

      // ==============================================================
      // LSU port FSM
      // ==============================================================
      case (lsu_st_q)
        P_IDLE: begin
          if (lsu_req_i) begin
            lsu_va_q   <= lsu_vaddr_i;
            lsu_str_q  <= lsu_is_store_i;
            lsu_priv_q <= ld_st_priv_lvl_i;
            lsu_sum_q  <= sum_i;
            lsu_mxr_q  <= mxr_i;
            if (!en_ld_st_translation_i) begin
              // Bare mode (C1)
              lsu_pa_q  <= lsu_vaddr_i[55:0];
              lsu_exc_q <= 1'b0;
              lsu_st_q  <= P_RET;
            end else if (d_hit_any) begin
              // TLB hit (A9)
              if (d_hit_perm) begin
                lsu_pa_q  <= d_hit_pa;
                lsu_exc_q <= 1'b0;
              end else begin
                lsu_exc_q   <= 1'b1;
                lsu_cause_q <= lsu_is_store_i ? 64'd15 : 64'd13;
                lsu_tval_q  <= lsu_vaddr_i;
                lsu_pa_q    <= 56'd0;
              end
              lsu_st_q <= P_RET;
            end else begin
              lsu_st_q <= P_WAIT;
            end
          end
        end
        P_RET: begin
          lsu_st_q <= P_IDLE;
        end
        P_WAIT: begin
          // Walker delivers — handled in walker FSM
        end
        default: begin
          lsu_st_q <= P_IDLE;
        end
      endcase

      // ==============================================================
      // Fetch port FSM
      // ==============================================================
      case (fetch_st_q)
        P_IDLE: begin
          if (fetch_req_i) begin
            f_va_q   <= fetch_vaddr_i;
            f_priv_q <= priv_lvl_i;
            f_sum_q  <= sum_i;
            f_mxr_q  <= mxr_i;
            if (!enable_translation_i) begin
              // Bare mode (C1)
              f_pa_q     <= fetch_vaddr_i[55:0];
              f_exc_q    <= 1'b0;
              fetch_st_q <= P_RET;
            end else if (i_hit_any) begin
              // TLB hit (A9)
              if (i_hit_perm) begin
                f_pa_q  <= i_hit_pa;
                f_exc_q <= 1'b0;
              end else begin
                f_exc_q    <= 1'b1;
                f_cause_q  <= 64'd12;
                f_tval_q   <= fetch_vaddr_i;
                f_pa_q     <= 56'd0;
              end
              fetch_st_q <= P_RET;
            end else begin
              fetch_st_q <= P_WAIT;
            end
          end
        end
        P_RET: begin
          fetch_st_q <= P_IDLE;
        end
        P_WAIT: begin
          // Walker delivers — handled in walker FSM
        end
        default: begin
          fetch_st_q <= P_IDLE;
        end
      endcase
    end
  end

  // ------------------------------------------------------------------
  // Output assignments
  // ------------------------------------------------------------------
  assign lsu_valid_o       = (lsu_st_q == P_RET);
  assign lsu_paddr_o       = lsu_pa_q;
  assign lsu_exc_valid_o   = (lsu_st_q == P_RET) && lsu_exc_q;
  assign lsu_exc_cause_o   = lsu_cause_q;
  assign lsu_exc_tval_o    = lsu_tval_q;

  assign fetch_valid_o     = (fetch_st_q == P_RET);
  assign fetch_paddr_o     = f_pa_q;
  assign fetch_exc_valid_o = (fetch_st_q == P_RET) && f_exc_q;
  assign fetch_exc_cause_o = f_cause_q;
  assign fetch_exc_tval_o  = f_tval_q;

  assign lsu_dtlb_hit_o    = (lsu_st_q == P_IDLE) && lsu_req_i &&
                             en_ld_st_translation_i && d_hit_any;
  assign lsu_dtlb_ppn_o    = d_hit_e.ppn;

  assign dtlb_miss_o       = lsu_miss_now;
  assign itlb_miss_o       = fetch_miss_now;

  assign mem_req_o         = (w_st_q == W_REQ) && w_pmp_ok;
  assign mem_addr_o        = w_pte_addr;
  assign mem_tag_valid_o   = 1'b0;
  assign mem_kill_o        = 1'b0;

endmodule
