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
  // TLB entry layout (96 bits):
  // [95] V | [94] G | [93:78] ASID | [77:76] level | [75:49] VPN
  // [48:5] PPN | [4] R | [3] W | [2] X | [1] U | [0] D
  // ---------------------------------------------------------------------------
  localparam int unsigned EW = 96;

  logic [15:0][EW-1:0] dtlb_q, dtlb_d, itlb_q, itlb_d;
  logic [3:0] dtlb_rr_q, dtlb_rr_d, itlb_rr_q, itlb_rr_d;

  typedef enum logic [2:0] { IDLE, WALK, DATA, FWAIT, RET } state_e;
  state_e state_q, state_d;

  logic [55:0] walk_addr_q, walk_addr_d;
  logic [1:0]  level_q, level_d;

  logic        r_is_fetch_q, r_is_fetch_d;
  logic [63:0] r_va_q, r_va_d;
  logic        r_store_q, r_store_d;
  logic [1:0]  r_priv_q, r_priv_d;
  logic        r_sum_q, r_sum_d;
  logic        r_mxr_q, r_mxr_d;
  logic [15:0] r_asid_q, r_asid_d;

  logic        ret_fault_q,   ret_fault_d;
  logic        ret_is_lsu_q,  ret_is_lsu_d;
  logic [63:0] ret_cause_q,   ret_cause_d;
  logic [55:0] ret_pa_q,      ret_pa_d;
  logic [63:0] ret_tval_q,    ret_tval_d;

  logic lsu_ret_hold_q,   lsu_ret_hold_d;
  logic fetch_ret_hold_q, fetch_ret_hold_d;

  logic          d_hit, i_hit;
  logic [3:0]    d_hit_idx, i_hit_idx;
  logic [EW-1:0] d_hit_e, i_hit_e;
  logic [26:0]   d_cmp_mask, i_cmp_mask;

  logic          pmp_ok;
  logic          tlb_we, tlb_we_is_lsu;
  logic [3:0]    tlb_we_idx;
  logic [EW-1:0] tlb_we_entry;
  logic [3:0]    d_victim, i_victim;
  logic          d_found_invalid, i_found_invalid;
  logic          misaligned;
  logic          lsu_can, fetch_can, lsu_accept, fetch_accept;
  logic          lsu_hit_ok, i_hit_ok, lsu_bare, fetch_bare;

  // ---------------------------------------------------------------------------
  // Permission check (A4, A5 store-D)
  // ---------------------------------------------------------------------------
  function automatic logic perm_ok(
    input logic       r,
    input logic       w,
    input logic       x,
    input logic       u,
    input logic       d,
    input logic       is_store,
    input logic       is_fetch,
    input logic       mxr,
    input logic       sum,
    input logic [1:0] priv
  );
    logic ok;
    begin
      ok = 1'b1;
      if (is_fetch)
        ok = x;
      else if (is_store)
        ok = w && d;
      else
        ok = r || (x && mxr);
      if (priv == 2'b00) begin
        ok = ok && u;
      end else if (priv == 2'b01) begin
        if (u) begin
          if (is_fetch) ok = 1'b0;
          else          ok = ok && sum;
        end
      end
      perm_ok = ok;
    end
  endfunction

  // ---------------------------------------------------------------------------
  // Physical address from leaf PPN + VA (A2)
  // ---------------------------------------------------------------------------
  function automatic logic [55:0] pa_of(
    input logic [43:0] ppn,
    input logic [26:0] vpn,
    input logic [1:0]  lvl,
    input logic [11:0] off
  );
    logic [43:0] lowmask;
    logic [43:0] vpnx;
    begin
      vpnx = {17'b0, vpn};
      case (lvl)
        2'd0:    lowmask = 44'h00000;
        2'd1:    lowmask = 44'h001FF;
        default: lowmask = 44'h3FFFF;
      endcase
      pa_of = {((ppn & ~lowmask) | (vpnx & lowmask)), off};
    end
  endfunction

  // ---------------------------------------------------------------------------
  // PMP read check on a walker address (A8). Lowest matching entry wins;
  // no match denies. Only the R bit matters, the walker only reads.
  // ---------------------------------------------------------------------------
  function automatic logic pmp_read_ok(input logic [55:0] addr);
    logic          matched;
    logic          ok;
    logic [7:0]    c;
    logic [53:0]   pa;
    logic [55:0]   base;
    logic [55:0]   top;
    int unsigned   t;
    begin
      matched = 1'b0;
      ok      = 1'b0;
      for (int unsigned n = 0; n < 8; n++) begin
        if (!matched) begin
          c  = pmpcfg_i[n];
          pa = pmpaddr_i[n];
          t  = 0;
          for (int unsigned k = 0; k < 54; k++) begin
            if (t == k && pa[k]) t = k + 1;
          end
          case (c[3:2])
            2'b00: matched = matched;               // OFF: never matches
            2'b01: begin                             // TOR
              base = {2'b00, ((n == 0) ? 54'd0 : pmpaddr_i[n-1])} << 2;
              top  = {2'b00, pa} << 2;
              if (addr >= base && addr < top) begin
                matched = 1'b1;
                ok      = c[0];
              end
            end
            2'b10: begin                             // NA4
              if (addr[55:2] == pa) begin
                matched = 1'b1;
                ok      = c[0];
              end
            end
            default: begin                           // NAPOT
              if ((addr >> (t + 3)) == (({2'b00, pa}) >> (t + 1))) begin
                matched = 1'b1;
                ok      = c[0];
              end
            end
          endcase
        end
      end
      pmp_read_ok = ok;
    end
  endfunction

  // ---------------------------------------------------------------------------
  // TLB lookups (parallel, fully associative, G/ASID aware)
  // ---------------------------------------------------------------------------
  always_comb begin
    d_hit     = 1'b0;
    d_hit_idx = 4'd0;
    d_hit_e   = '0;
    for (int unsigned i = 0; i < 16; i++) begin
      if (!d_hit && dtlb_q[i][95]) begin
        case (dtlb_q[i][77:76])
          2'd0:    d_cmp_mask = 27'h7FFFFFF;
          2'd1:    d_cmp_mask = 27'b111111111111111111000000000;
          default: d_cmp_mask = 27'b111111111000000000000000000;
        endcase
        if ((dtlb_q[i][75:49] & d_cmp_mask) == (lsu_vaddr_i[38:12] & d_cmp_mask) &&
            (dtlb_q[i][94] || (dtlb_q[i][93:78] == asid_i))) begin
          d_hit     = 1'b1;
          d_hit_idx = i[3:0];
          d_hit_e   = dtlb_q[i];
        end
      end
    end
  end

  always_comb begin
    i_hit     = 1'b0;
    i_hit_idx = 4'd0;
    i_hit_e   = '0;
    for (int unsigned i = 0; i < 16; i++) begin
      if (!i_hit && itlb_q[i][95]) begin
        case (itlb_q[i][77:76])
          2'd0:    i_cmp_mask = 27'h7FFFFFF;
          2'd1:    i_cmp_mask = 27'b111111111111111111000000000;
          default: i_cmp_mask = 27'b111111111000000000000000000;
        endcase
        if ((itlb_q[i][75:49] & i_cmp_mask) == (fetch_vaddr_i[38:12] & i_cmp_mask) &&
            (itlb_q[i][94] || (itlb_q[i][93:78] == asid_i))) begin
          i_hit     = 1'b1;
          i_hit_idx = i[3:0];
          i_hit_e   = itlb_q[i];
        end
      end
    end
  end

  // ---------------------------------------------------------------------------
  // Victim selection: first invalid, else round-robin
  // ---------------------------------------------------------------------------
  always_comb begin
    d_found_invalid = 1'b0;
    d_victim        = dtlb_rr_q;
    for (int unsigned i = 0; i < 16; i++) begin
      if (!d_found_invalid && !dtlb_q[i][95]) begin
        d_found_invalid = 1'b1;
        d_victim        = i[3:0];
      end
    end
  end

  always_comb begin
    i_found_invalid = 1'b0;
    i_victim        = itlb_rr_q;
    for (int unsigned i = 0; i < 16; i++) begin
      if (!i_found_invalid && !itlb_q[i][95]) begin
        i_found_invalid = 1'b1;
        i_victim        = i[3:0];
      end
    end
  end

  // ---------------------------------------------------------------------------
  // Port arbitration / acceptance
  // ---------------------------------------------------------------------------
  assign lsu_bare   = !en_ld_st_translation_i;
  assign fetch_bare = !enable_translation_i;

  assign lsu_hit_ok = perm_ok(d_hit_e[4], d_hit_e[3], d_hit_e[2], d_hit_e[1],
                              d_hit_e[0], lsu_is_store_i, 1'b0,
                              mxr_i, sum_i, ld_st_priv_lvl_i);
  assign i_hit_ok   = perm_ok(i_hit_e[4], i_hit_e[3], i_hit_e[2], i_hit_e[1],
                              i_hit_e[0], 1'b0, 1'b1,
                              mxr_i, sum_i, priv_lvl_i);

  assign lsu_can   = (state_q == IDLE) && !lsu_ret_hold_q;
  assign fetch_can = (state_q == IDLE) && !fetch_ret_hold_q;

  assign lsu_accept   = lsu_req_i   && lsu_can   && !lsu_bare   && !d_hit;
  assign fetch_accept = fetch_req_i && fetch_can && !fetch_bare && !i_hit && !lsu_accept;

  // ---------------------------------------------------------------------------
  // Walker FSM
  // ---------------------------------------------------------------------------
  always_comb begin
    state_d       = state_q;
    walk_addr_d   = walk_addr_q;
    level_d       = level_q;
    r_is_fetch_d  = r_is_fetch_q;
    r_va_d        = r_va_q;
    r_store_d     = r_store_q;
    r_priv_d      = r_priv_q;
    r_sum_d       = r_sum_q;
    r_mxr_d       = r_mxr_q;
    r_asid_d      = r_asid_q;
    ret_fault_d   = ret_fault_q;
    ret_is_lsu_d  = ret_is_lsu_q;
    ret_cause_d   = ret_cause_q;
    ret_pa_d      = ret_pa_q;
    ret_tval_d    = ret_tval_q;
    tlb_we        = 1'b0;
    tlb_we_is_lsu = !r_is_fetch_q;
    tlb_we_entry  = '0;
    pmp_ok        = pmp_read_ok(walk_addr_q);
    misaligned    = 1'b0;

    case (state_q)
      IDLE: begin
        if (lsu_accept) begin
          r_is_fetch_d = 1'b0;
          r_va_d       = lsu_vaddr_i;
          r_store_d    = lsu_is_store_i;
          r_priv_d     = ld_st_priv_lvl_i;
          r_sum_d      = sum_i;
          r_mxr_d      = mxr_i;
          r_asid_d     = asid_i;
          level_d      = 2'd2;
          walk_addr_d  = {satp_ppn_i, 12'h0};
          state_d      = WALK;
        end else if (fetch_accept) begin
          r_is_fetch_d = 1'b1;
          r_va_d       = fetch_vaddr_i;
          r_store_d    = 1'b0;
          r_priv_d     = priv_lvl_i;
          r_sum_d      = sum_i;
          r_mxr_d      = mxr_i;
          r_asid_d     = asid_i;
          level_d      = 2'd2;
          walk_addr_d  = {satp_ppn_i, 12'h0};
          state_d      = WALK;
        end
      end

      WALK: begin
        if (flush_i) begin
          // abort: restart the walk from the root (C3)
          level_d     = 2'd2;
          walk_addr_d = {satp_ppn_i, 12'h0};
          if (mem_gnt_i) state_d = FWAIT;   // a response is in flight, discard it
        end else if (!pmp_ok) begin
          // access fault on the walker's own read (A7/A8)
          ret_fault_d  = 1'b1;
          ret_is_lsu_d = !r_is_fetch_q;
          ret_cause_d  = r_is_fetch_q ? 64'd1 : (r_store_q ? 64'd7 : 64'd5);
          ret_pa_d     = '0;
          ret_tval_d   = r_va_q;
          state_d      = RET;
        end else if (mem_gnt_i) begin
          state_d = DATA;
        end
      end

      DATA: begin
        if (mem_rvalid_i) begin
          if (flush_i) begin
            level_d     = 2'd2;
            walk_addr_d = {satp_ppn_i, 12'h0};
            state_d     = WALK;
          end else if (!mem_rdata_i[0] || (mem_rdata_i[2] && !mem_rdata_i[1])) begin
            // invalid or reserved encoding -> page fault (A1, F3)
            ret_fault_d  = 1'b1;
            ret_is_lsu_d = !r_is_fetch_q;
            ret_cause_d  = r_is_fetch_q ? 64'd12 : (r_store_q ? 64'd15 : 64'd13);
            ret_pa_d     = '0;
            ret_tval_d   = r_va_q;
            state_d      = RET;
          end else if (mem_rdata_i[1] || mem_rdata_i[3]) begin
            // leaf
            case (level_q)
              2'd1:    misaligned = (mem_rdata_i[18:10] != 10'd0);
              2'd2:    misaligned = (mem_rdata_i[27:10] != 18'd0);
              default: misaligned = 1'b0;
            endcase
            if (misaligned || !mem_rdata_i[6] ||
                (r_store_q && !mem_rdata_i[7]) ||
                !perm_ok(mem_rdata_i[1], mem_rdata_i[2], mem_rdata_i[3],
                         mem_rdata_i[4], mem_rdata_i[7],
                         r_store_q, r_is_fetch_q, r_mxr_q, r_sum_q, r_priv_q)) begin
              // misaligned superpage, A=0, D=0 on store, or permission (A3/A4/A5)
              ret_fault_d  = 1'b1;
              ret_is_lsu_d = !r_is_fetch_q;
              ret_cause_d  = r_is_fetch_q ? 64'd12 : (r_store_q ? 64'd15 : 64'd13);
              ret_pa_d     = '0;
              ret_tval_d   = r_va_q;
              state_d      = RET;
            end else begin
              // install and retire (the unit never writes the PTE, A5)
              tlb_we        = 1'b1;
              tlb_we_is_lsu = !r_is_fetch_q;
              tlb_we_entry  = {1'b1, mem_rdata_i[5], r_asid_q, level_q,
                              r_va_q[38:12], mem_rdata_i[53:10],
                              mem_rdata_i[1], mem_rdata_i[2], mem_rdata_i[3],
                              mem_rdata_i[4], mem_rdata_i[7]};
              ret_fault_d   = 1'b0;
              ret_is_lsu_d  = !r_is_fetch_q;
              ret_pa_d      = pa_of(mem_rdata_i[53:10], r_va_q[38:12],
                                    level_q, r_va_q[11:0]);
              ret_tval_d    = r_va_q;
              state_d       = RET;
            end
          end else if (level_q == 2'd0) begin
            // ran past level 0 without a leaf (A1)
            ret_fault_d  = 1'b1;
            ret_is_lsu_d = !r_is_fetch_q;
            ret_cause_d  = r_is_fetch_q ? 64'd12 : (r_store_q ? 64'd15 : 64'd13);
            ret_pa_d     = '0;
            ret_tval_d   = r_va_q;
            state_d      = RET;
          end else begin
            // non-leaf pointer: descend
            walk_addr_d = {mem_rdata_i[53:10], 12'h0};
            level_d     = level_q - 2'd1;
            state_d     = WALK;
          end
        end
      end

      FWAIT: begin
        if (mem_rvalid_i) begin
          level_d     = 2'd2;
          walk_addr_d = {satp_ppn_i, 12'h0};
          state_d     = WALK;
        end
      end

      RET: state_d = IDLE;

      default: state_d = IDLE;
    endcase
  end

  assign tlb_we_idx = tlb_we_is_lsu ? d_victim : i_victim;

  // ---------------------------------------------------------------------------
  // TLB array next state: flush is a parallel clear (C2, full flush)
  // ---------------------------------------------------------------------------
  always_comb begin
    dtlb_d    = dtlb_q;
    itlb_d    = itlb_q;
    dtlb_rr_d = dtlb_rr_q;
    itlb_rr_d = itlb_rr_q;
    if (flush_tlb_i) begin
      for (int unsigned i = 0; i < 16; i++) begin
        dtlb_d[i][95] = 1'b0;
        itlb_d[i][95] = 1'b0;
      end
    end
    if (tlb_we) begin
      if (tlb_we_is_lsu) begin
        dtlb_d[tlb_we_idx] = tlb_we_entry;
        dtlb_rr_d          = dtlb_rr_q + 4'd1;
      end else begin
        itlb_d[tlb_we_idx] = tlb_we_entry;
        itlb_rr_d          = itlb_rr_q + 4'd1;
      end
    end
  end

  // ---------------------------------------------------------------------------
  // Retirement hold: after a walker retire, do not answer the same asserted
  // req again from the freshly installed entry; clears when req drops.
  // ---------------------------------------------------------------------------
  always_comb begin
    lsu_ret_hold_d =
      ((state_q == RET) && ret_is_lsu_q)  ? 1'b1 :
      (lsu_ret_hold_q && lsu_req_i)       ? 1'b1 : 1'b0;
    fetch_ret_hold_d =
      ((state_q == RET) && !ret_is_lsu_q) ? 1'b1 :
      (fetch_ret_hold_q && fetch_req_i)   ? 1'b1 : 1'b0;
  end

  // ---------------------------------------------------------------------------
  // Outputs (A11: a fault retires with valid_o AND exc_valid_o in one cycle)
  // ---------------------------------------------------------------------------
  assign lsu_valid_o =
    ((state_q == RET) && ret_is_lsu_q && lsu_req_i) ||
    (lsu_req_i && lsu_can && (lsu_bare || (d_hit && lsu_hit_ok)));
  assign lsu_exc_valid_o =
    ((state_q == RET) && ret_is_lsu_q && ret_fault_q && lsu_req_i) ||
    (lsu_req_i && lsu_can && !lsu_bare && d_hit && !lsu_hit_ok);
  assign lsu_paddr_o =
    ((state_q == RET) && ret_is_lsu_q) ? ret_pa_q :
    lsu_bare ? lsu_vaddr_i[55:0] :
    pa_of(d_hit_e[48:5], lsu_vaddr_i[38:12], d_hit_e[77:76], lsu_vaddr_i[11:0]);
  assign lsu_exc_cause_o =
    ((state_q == RET) && ret_is_lsu_q) ? ret_cause_q :
    (lsu_is_store_i ? 64'd15 : 64'd13);
  assign lsu_exc_tval_o =
    ((state_q == RET) && ret_is_lsu_q) ? ret_tval_q : lsu_vaddr_i;

  assign fetch_valid_o =
    ((state_q == RET) && !ret_is_lsu_q && fetch_req_i) ||
    (fetch_req_i && fetch_can && (fetch_bare || (i_hit && i_hit_ok)));
  assign fetch_exc_valid_o =
    ((state_q == RET) && !ret_is_lsu_q && ret_fault_q && fetch_req_i) ||
    (fetch_req_i && fetch_can && !fetch_bare && i_hit && !i_hit_ok);
  assign fetch_paddr_o =
    ((state_q == RET) && !ret_is_lsu_q) ? ret_pa_q :
    fetch_bare ? fetch_vaddr_i[55:0] :
    pa_of(i_hit_e[48:5], fetch_vaddr_i[38:12], i_hit_e[77:76], fetch_vaddr_i[11:0]);
  assign fetch_exc_cause_o =
    ((state_q == RET) && !ret_is_lsu_q) ? ret_cause_q : 64'd12;
  assign fetch_exc_tval_o =
    ((state_q == RET) && !ret_is_lsu_q) ? ret_tval_q : fetch_vaddr_i;

  // implementation-reporting outputs, not scored (T2)
  assign lsu_dtlb_hit_o  = d_hit;
  assign lsu_dtlb_ppn_o  = d_hit_e[48:5];
  assign dtlb_miss_o     = lsu_req_i   && !lsu_bare   && !d_hit;
  assign itlb_miss_o     = fetch_req_i && !fetch_bare && !i_hit;

  // memory port: read-only, only while walking and only if PMP permits (A8)
  assign mem_req_o      = (state_q == WALK) && pmp_ok;
  assign mem_addr_o     = walk_addr_q;
  assign mem_tag_valid_o = 1'b0;
  assign mem_kill_o     = 1'b0;

  // ---------------------------------------------------------------------------
  // Registers
  // ---------------------------------------------------------------------------
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      state_q         <= IDLE;
      walk_addr_q     <= '0;
      level_q         <= 2'd2;
      r_is_fetch_q    <= 1'b0;
      r_va_q          <= '0;
      r_store_q       <= 1'b0;
      r_priv_q         <= 2'b0;
      r_sum_q          <= 1'b0;
      r_mxr_q          <= 1'b0;
      r_asid_q         <= '0;
      ret_fault_q     <= 1'b0;
      ret_is_lsu_q    <= 1'b0;
      ret_cause_q     <= '0;
      ret_pa_q        <= '0;
      ret_tval_q      <= '0;
      lsu_ret_hold_q  <= 1'b0;
      fetch_ret_hold_q <= 1'b0;
      dtlb_rr_q       <= 4'd0;
      itlb_rr_q       <= 4'd0;
      for (int unsigned i = 0; i < 16; i++) begin
        dtlb_q[i] <= '0;
        itlb_q[i] <= '0;
      end
    end else begin
      state_q          <= state_d;
      walk_addr_q      <= walk_addr_d;
      level_q          <= level_d;
      r_is_fetch_q     <= r_is_fetch_d;
      r_va_q           <= r_va_d;
      r_store_q        <= r_store_d;
      r_priv_q         <= r_priv_d;
      r_sum_q          <= r_sum_d;
      r_mxr_q          <= r_mxr_d;
      r_asid_q         <= r_asid_d;
      ret_fault_q      <= ret_fault_d;
      ret_is_lsu_q     <= ret_is_lsu_d;
      ret_cause_q      <= ret_cause_d;
      ret_pa_q         <= ret_pa_d;
      ret_tval_q       <= ret_tval_d;
      lsu_ret_hold_q   <= lsu_ret_hold_d;
      fetch_ret_hold_q <= fetch_ret_hold_d;
      dtlb_rr_q        <= dtlb_rr_d;
      itlb_rr_q        <= itlb_rr_d;
      dtlb_q           <= dtlb_d;
      itlb_q           <= itlb_d;
    end
  end

endmodule
