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

  localparam int unsigned TLB_ENTRIES = 16;

  typedef enum logic [1:0] {
    WALK_IDLE,
    WALK_REQ,
    WALK_WAIT,
    WALK_DRAIN
  } walk_state_t;

  /*
   * TLB entry format.  The two TLBs are deliberately separate and each has
   * exactly sixteen fully-associative entries, as required by P2.
   */
  logic                    itlb_valid_q [0:TLB_ENTRIES-1];
  logic [26:0]             itlb_vpn_q   [0:TLB_ENTRIES-1];
  logic [43:0]             itlb_ppn_q   [0:TLB_ENTRIES-1];
  logic [1:0]              itlb_level_q [0:TLB_ENTRIES-1];
  logic [15:0]             itlb_asid_q  [0:TLB_ENTRIES-1];
  logic [7:0]              itlb_flags_q [0:TLB_ENTRIES-1];

  logic                    dtlb_valid_q [0:TLB_ENTRIES-1];
  logic [26:0]             dtlb_vpn_q   [0:TLB_ENTRIES-1];
  logic [43:0]             dtlb_ppn_q   [0:TLB_ENTRIES-1];
  logic [1:0]              dtlb_level_q [0:TLB_ENTRIES-1];
  logic [15:0]             dtlb_asid_q  [0:TLB_ENTRIES-1];
  logic [7:0]              dtlb_flags_q [0:TLB_ENTRIES-1];

  logic [3:0]              itlb_repl_q;
  logic [3:0]              dtlb_repl_q;

  /* Current walk/request context. */
  walk_state_t             walk_state_q;
  logic                    walk_fetch_q;
  logic                    walk_store_q;
  logic [63:0]             walk_va_q;
  logic [1:0]              walk_priv_q;
  logic                    walk_sum_q;
  logic                    walk_mxr_q;
  logic [15:0]             walk_asid_q;
  logic [43:0]             walk_root_ppn_q;
  logic [1:0]              walk_level_q;
  logic [55:0]             walk_addr_q;

  /* Lookup results for the currently presented requests. */
  logic                    itlb_hit_c;
  logic [3:0]              itlb_hit_idx_c;
  logic [55:0]             itlb_pa_c;
  logic                    itlb_perm_ok_c;

  logic                    dtlb_hit_c;
  logic [3:0]              dtlb_hit_idx_c;
  logic [55:0]             dtlb_pa_c;
  logic                    dtlb_perm_ok_c;

  /* Walker-side PTE decode. */
  logic                    pte_v_c;
  logic                    pte_r_c;
  logic                    pte_w_c;
  logic                    pte_x_c;
  logic                    pte_u_c;
  logic                    pte_a_c;
  logic                    pte_d_c;
  logic                    pte_leaf_c;
  logic                    pte_reserved_c;
  logic [43:0]             pte_ppn_c;
  logic                    pte_super_misaligned_c;
  logic                    pte_perm_ok_c;
  logic [55:0]             pte_pa_c;
  logic [55:0]             next_pte_addr_c;
  logic                    walk_pmp_allow_c;

  logic                    itlb_free_found_c;
  logic [3:0]              itlb_install_idx_c;
  logic                    dtlb_free_found_c;
  logic [3:0]              dtlb_install_idx_c;

  function automatic logic vpn_matches(
    input logic [26:0] stored_vpn,
    input logic [1:0]  level,
    input logic [63:0] va
  );
    begin
      case (level)
        2'd2: vpn_matches = (stored_vpn[26:18] == va[38:30]);
        2'd1: vpn_matches = (stored_vpn[26:9]  == va[38:21]);
        default: vpn_matches = (stored_vpn == va[38:12]);
      endcase
    end
  endfunction

  function automatic logic [55:0] make_paddr(
    input logic [43:0] ppn,
    input logic [1:0]  level,
    input logic [63:0] va
  );
    logic [43:0] final_ppn;
    begin
      final_ppn = ppn;
      case (level)
        2'd2: final_ppn[17:0] = va[29:12];
        2'd1: final_ppn[8:0]  = va[20:12];
        default: final_ppn = ppn;
      endcase
      make_paddr = {final_ppn, va[11:0]};
    end
  endfunction

  function automatic logic [55:0] pte_address(
    input logic [43:0] table_ppn,
    input logic [63:0] va,
    input logic [1:0]  level
  );
    logic [8:0] vpn_sel;
    logic [55:0] base;
    logic [55:0] offs;
    begin
      case (level)
        2'd2: vpn_sel = va[38:30];
        2'd1: vpn_sel = va[29:21];
        default: vpn_sel = va[20:12];
      endcase
      base = {table_ppn, 12'b0};
      offs = {{44{1'b0}}, vpn_sel, 3'b000};
      pte_address = base + offs;
    end
  endfunction

  function automatic logic permission_ok(
    input logic [7:0] flags,
    input logic       is_fetch,
    input logic       is_store,
    input logic [1:0] priv,
    input logic       sum,
    input logic       mxr
  );
    logic r;
    logic w;
    logic x;
    logic u;
    logic a;
    logic d;
    logic access_ok;
    logic priv_ok;
    begin
      r = flags[1];
      w = flags[2];
      x = flags[3];
      u = flags[4];
      a = flags[6];
      d = flags[7];

      access_ok = 1'b0;
      if (is_fetch) begin
        access_ok = x;
      end
      else if (is_store) begin
        access_ok = w;
      end
      else begin
        access_ok = r || (mxr && x);
      end

      priv_ok = 1'b1;
      if (priv == 2'b00) begin
        priv_ok = u;
      end
      else if (priv == 2'b01) begin
        if (u) begin
          if (is_fetch) begin
            priv_ok = 1'b0;
          end
          else begin
            priv_ok = sum;
          end
        end
      end

      permission_ok = access_ok && priv_ok && a;
      if (is_store) begin
        permission_ok = permission_ok && d;
      end
    end
  endfunction

  function automatic logic [63:0] page_fault_cause(
    input logic is_fetch,
    input logic is_store
  );
    begin
      if (is_fetch) begin
        page_fault_cause = 64'd12;
      end
      else if (is_store) begin
        page_fault_cause = 64'd15;
      end
      else begin
        page_fault_cause = 64'd13;
      end
    end
  endfunction

  function automatic logic [63:0] access_fault_cause(
    input logic is_fetch,
    input logic is_store
  );
    begin
      if (is_fetch) begin
        access_fault_cause = 64'd1;
      end
      else if (is_store) begin
        access_fault_cause = 64'd7;
      end
      else begin
        access_fault_cause = 64'd5;
      end
    end
  endfunction

  /*
   * PMP check for the walker's 8-byte read.  The first PMP entry whose region
   * overlaps the access has priority.  The whole 8-byte access must fit in the
   * region and R must be set.  No match denies.
   */
  function automatic logic pmp_read_allowed(input logic [55:0] addr);
    integer e;
    integer j;
    integer ones;
    logic matched;
    logic stop_count;
    logic [1:0] mode;
    logic [56:0] access_lo;
    logic [56:0] access_hi;
    logic [56:0] low_bound;
    logic [56:0] high_bound;
    logic [56:0] prev_top;
    logic [56:0] enc_addr;
    logic [56:0] enc_mask;
    logic [56:0] region_size;
    begin
      pmp_read_allowed = 1'b0;
      matched = 1'b0;
      access_lo = {1'b0, addr};
      access_hi = {1'b0, addr} + 57'd8;
      prev_top = 57'd0;

      for (e = 0; e < 8; e = e + 1) begin
        mode = pmpcfg_i[e][4:3];
        low_bound = 57'd0;
        high_bound = 57'd0;
        enc_addr = {3'b000, pmpaddr_i[e]};
        enc_mask = 57'd0;
        region_size = 57'd0;
        ones = 0;
        stop_count = 1'b0;

        case (mode)
          2'b01: begin
            low_bound = prev_top;
            high_bound = {1'b0, pmpaddr_i[e], 2'b00};
          end

          2'b10: begin
            low_bound = {1'b0, pmpaddr_i[e], 2'b00};
            high_bound = low_bound + 57'd4;
          end

          2'b11: begin
            for (j = 0; j < 54; j = j + 1) begin
              if (!stop_count) begin
                if (pmpaddr_i[e][j]) begin
                  ones = ones + 1;
                end
                else begin
                  stop_count = 1'b1;
                end
              end
            end

            if (ones >= 53) begin
              low_bound = 57'd0;
              high_bound = (57'd1 << 56);
            end
            else begin
              if (ones != 0) begin
                enc_mask = (57'd1 << ones) - 57'd1;
              end
              region_size = (57'd1 << (ones + 3));
              low_bound = (enc_addr & (~enc_mask)) << 2;
              high_bound = low_bound + region_size;
            end
          end

          default: begin
            low_bound = 57'd0;
            high_bound = 57'd0;
          end
        endcase

        if ((!matched) && (mode != 2'b00) &&
            (access_lo < high_bound) && (access_hi > low_bound)) begin
          matched = 1'b1;
          if ((access_lo >= low_bound) &&
              (access_hi <= high_bound) &&
              pmpcfg_i[e][0]) begin
            pmp_read_allowed = 1'b1;
          end
          else begin
            pmp_read_allowed = 1'b0;
          end
        end

        prev_top = {1'b0, pmpaddr_i[e], 2'b00};
      end
    end
  endfunction

  /* Fully-associative ITLB lookup. */
  always_comb begin : p_itlb_lookup
    integer i;

    itlb_hit_c = 1'b0;
    itlb_hit_idx_c = 4'd0;
    itlb_pa_c = 56'd0;
    itlb_perm_ok_c = 1'b0;

    for (i = 0; i < TLB_ENTRIES; i = i + 1) begin
      if ((!itlb_hit_c) && itlb_valid_q[i] &&
          (itlb_flags_q[i][5] || (itlb_asid_q[i] == asid_i)) &&
          vpn_matches(itlb_vpn_q[i], itlb_level_q[i], fetch_vaddr_i)) begin
        itlb_hit_c = 1'b1;
        itlb_hit_idx_c = i;
        itlb_pa_c = make_paddr(itlb_ppn_q[i], itlb_level_q[i], fetch_vaddr_i);
        itlb_perm_ok_c = permission_ok(
            itlb_flags_q[i], 1'b1, 1'b0, priv_lvl_i, sum_i, mxr_i);
      end
    end
  end

  /* Fully-associative DTLB lookup. */
  always_comb begin : p_dtlb_lookup
    integer i;

    dtlb_hit_c = 1'b0;
    dtlb_hit_idx_c = 4'd0;
    dtlb_pa_c = 56'd0;
    dtlb_perm_ok_c = 1'b0;

    for (i = 0; i < TLB_ENTRIES; i = i + 1) begin
      if ((!dtlb_hit_c) && dtlb_valid_q[i] &&
          (dtlb_flags_q[i][5] || (dtlb_asid_q[i] == asid_i)) &&
          vpn_matches(dtlb_vpn_q[i], dtlb_level_q[i], lsu_vaddr_i)) begin
        dtlb_hit_c = 1'b1;
        dtlb_hit_idx_c = i;
        dtlb_pa_c = make_paddr(dtlb_ppn_q[i], dtlb_level_q[i], lsu_vaddr_i);
        dtlb_perm_ok_c = permission_ok(
            dtlb_flags_q[i], 1'b0, lsu_is_store_i,
            ld_st_priv_lvl_i, sum_i, mxr_i);
      end
    end
  end

  /* Prefer invalid entries, otherwise use a round-robin victim. */
  always_comb begin : p_install_pick
    integer i;

    itlb_free_found_c = 1'b0;
    itlb_install_idx_c = itlb_repl_q;
    dtlb_free_found_c = 1'b0;
    dtlb_install_idx_c = dtlb_repl_q;

    for (i = 0; i < TLB_ENTRIES; i = i + 1) begin
      if ((!itlb_free_found_c) && (!itlb_valid_q[i])) begin
        itlb_free_found_c = 1'b1;
        itlb_install_idx_c = i;
      end
      if ((!dtlb_free_found_c) && (!dtlb_valid_q[i])) begin
        dtlb_free_found_c = 1'b1;
        dtlb_install_idx_c = i;
      end
    end
  end

  /* PTE decode and current-walk derived values. */
  always_comb begin : p_pte_decode
    pte_v_c = mem_rdata_i[0];
    pte_r_c = mem_rdata_i[1];
    pte_w_c = mem_rdata_i[2];
    pte_x_c = mem_rdata_i[3];
    pte_u_c = mem_rdata_i[4];
    pte_a_c = mem_rdata_i[6];
    pte_d_c = mem_rdata_i[7];
    pte_ppn_c = mem_rdata_i[53:10];
    pte_leaf_c = pte_r_c || pte_x_c;
    pte_reserved_c = pte_w_c && (!pte_r_c);

    pte_super_misaligned_c = 1'b0;
    if (walk_level_q == 2'd2) begin
      pte_super_misaligned_c = |pte_ppn_c[17:0];
    end
    else if (walk_level_q == 2'd1) begin
      pte_super_misaligned_c = |pte_ppn_c[8:0];
    end

    pte_perm_ok_c = permission_ok(
        mem_rdata_i[7:0], walk_fetch_q, walk_store_q,
        walk_priv_q, walk_sum_q, walk_mxr_q);

    pte_pa_c = make_paddr(pte_ppn_c, walk_level_q, walk_va_q);

    next_pte_addr_c = pte_address(
        pte_ppn_c, walk_va_q, walk_level_q - 2'd1);

    walk_pmp_allow_c = pmp_read_allowed(walk_addr_q);
  end

  /* Unscored reporting signals are made faithful to this implementation. */
  always_comb begin : p_reporting
    lsu_dtlb_hit_o = 1'b0;
    lsu_dtlb_ppn_o = 44'd0;
    dtlb_miss_o = 1'b0;
    itlb_miss_o = 1'b0;

    if (lsu_req_i && en_ld_st_translation_i) begin
      lsu_dtlb_hit_o = dtlb_hit_c;
      dtlb_miss_o = !dtlb_hit_c;
      if (dtlb_hit_c) begin
        lsu_dtlb_ppn_o = dtlb_pa_c[55:12];
      end
    end

    if (fetch_req_i && enable_translation_i) begin
      itlb_miss_o = !itlb_hit_c;
    end
  end

  /* External memory request channel. */
  always_comb begin : p_mem
    mem_req_o = 1'b0;
    mem_addr_o = walk_addr_q;
    mem_tag_valid_o = 1'b0;
    mem_kill_o = 1'b0;

    if ((walk_state_q == WALK_REQ) &&
        walk_pmp_allow_c &&
        (!flush_i)) begin
      mem_req_o = 1'b1;
    end
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin : p_seq
    integer i;

    if (!rst_ni) begin
      lsu_valid_o <= 1'b0;
      lsu_paddr_o <= 56'd0;
      lsu_exc_valid_o <= 1'b0;
      lsu_exc_cause_o <= 64'd0;
      lsu_exc_tval_o <= 64'd0;

      fetch_valid_o <= 1'b0;
      fetch_paddr_o <= 56'd0;
      fetch_exc_valid_o <= 1'b0;
      fetch_exc_cause_o <= 64'd0;
      fetch_exc_tval_o <= 64'd0;

      walk_state_q <= WALK_IDLE;
      walk_fetch_q <= 1'b0;
      walk_store_q <= 1'b0;
      walk_va_q <= 64'd0;
      walk_priv_q <= 2'd0;
      walk_sum_q <= 1'b0;
      walk_mxr_q <= 1'b0;
      walk_asid_q <= 16'd0;
      walk_root_ppn_q <= 44'd0;
      walk_level_q <= 2'd2;
      walk_addr_q <= 56'd0;

      itlb_repl_q <= 4'd0;
      dtlb_repl_q <= 4'd0;

      for (i = 0; i < TLB_ENTRIES; i = i + 1) begin
        itlb_valid_q[i] <= 1'b0;
        itlb_vpn_q[i] <= 27'd0;
        itlb_ppn_q[i] <= 44'd0;
        itlb_level_q[i] <= 2'd0;
        itlb_asid_q[i] <= 16'd0;
        itlb_flags_q[i] <= 8'd0;

        dtlb_valid_q[i] <= 1'b0;
        dtlb_vpn_q[i] <= 27'd0;
        dtlb_ppn_q[i] <= 44'd0;
        dtlb_level_q[i] <= 2'd0;
        dtlb_asid_q[i] <= 16'd0;
        dtlb_flags_q[i] <= 8'd0;
      end
    end
    else begin
      /* Retirement outputs are one-cycle pulses. */
      lsu_valid_o <= 1'b0;
      lsu_exc_valid_o <= 1'b0;
      fetch_valid_o <= 1'b0;
      fetch_exc_valid_o <= 1'b0;

      /* A TLB flush is conservatively implemented as a full flush. */
      if (flush_tlb_i) begin
        for (i = 0; i < TLB_ENTRIES; i = i + 1) begin
          itlb_valid_q[i] <= 1'b0;
          dtlb_valid_q[i] <= 1'b0;
        end
        itlb_repl_q <= 4'd0;
        dtlb_repl_q <= 4'd0;
      end

      /*
       * flush_i aborts a walk but does not drop its latched request.  If a
       * memory request has already been granted, drain that response before
       * restarting so an old response cannot be mistaken for the new walk.
       */
      if (flush_i && (walk_state_q != WALK_IDLE)) begin
        if ((walk_state_q == WALK_WAIT) ||
            (walk_state_q == WALK_DRAIN)) begin
          if (mem_rvalid_i) begin
            walk_level_q <= 2'd2;
            walk_addr_q <= pte_address(walk_root_ppn_q, walk_va_q, 2'd2);
            walk_state_q <= WALK_REQ;
          end
          else begin
            walk_state_q <= WALK_DRAIN;
          end
        end
        else begin
          walk_level_q <= 2'd2;
          walk_addr_q <= pte_address(walk_root_ppn_q, walk_va_q, 2'd2);
          walk_state_q <= WALK_REQ;
        end
      end
      else begin
        case (walk_state_q)
          WALK_IDLE: begin
            /* LSU gets priority if both request ports are presented together. */
            if (lsu_req_i && (!flush_tlb_i)) begin
              if (!en_ld_st_translation_i) begin
                lsu_valid_o <= 1'b1;
                lsu_paddr_o <= lsu_vaddr_i[55:0];
                lsu_exc_valid_o <= 1'b0;
              end
              else if (dtlb_hit_c) begin
                lsu_valid_o <= 1'b1;
                lsu_exc_tval_o <= lsu_vaddr_i;
                if (dtlb_perm_ok_c) begin
                  lsu_paddr_o <= dtlb_pa_c;
                  lsu_exc_valid_o <= 1'b0;
                end
                else begin
                  lsu_exc_valid_o <= 1'b1;
                  lsu_exc_cause_o <= page_fault_cause(1'b0, lsu_is_store_i);
                end
              end
              else begin
                walk_fetch_q <= 1'b0;
                walk_store_q <= lsu_is_store_i;
                walk_va_q <= lsu_vaddr_i;
                walk_priv_q <= ld_st_priv_lvl_i;
                walk_sum_q <= sum_i;
                walk_mxr_q <= mxr_i;
                walk_asid_q <= asid_i;
                walk_root_ppn_q <= satp_ppn_i;
                walk_level_q <= 2'd2;
                walk_addr_q <= pte_address(satp_ppn_i, lsu_vaddr_i, 2'd2);
                walk_state_q <= WALK_REQ;
              end
            end
            else if (fetch_req_i && (!flush_tlb_i)) begin
              if (!enable_translation_i) begin
                fetch_valid_o <= 1'b1;
                fetch_paddr_o <= fetch_vaddr_i[55:0];
                fetch_exc_valid_o <= 1'b0;
              end
              else if (itlb_hit_c) begin
                fetch_valid_o <= 1'b1;
                fetch_exc_tval_o <= fetch_vaddr_i;
                if (itlb_perm_ok_c) begin
                  fetch_paddr_o <= itlb_pa_c;
                  fetch_exc_valid_o <= 1'b0;
                end
                else begin
                  fetch_exc_valid_o <= 1'b1;
                  fetch_exc_cause_o <= page_fault_cause(1'b1, 1'b0);
                end
              end
              else begin
                walk_fetch_q <= 1'b1;
                walk_store_q <= 1'b0;
                walk_va_q <= fetch_vaddr_i;
                walk_priv_q <= priv_lvl_i;
                walk_sum_q <= sum_i;
                walk_mxr_q <= mxr_i;
                walk_asid_q <= asid_i;
                walk_root_ppn_q <= satp_ppn_i;
                walk_level_q <= 2'd2;
                walk_addr_q <= pte_address(satp_ppn_i, fetch_vaddr_i, 2'd2);
                walk_state_q <= WALK_REQ;
              end
            end
          end

          WALK_REQ: begin
            if (!walk_pmp_allow_c) begin
              if (walk_fetch_q) begin
                fetch_valid_o <= 1'b1;
                fetch_exc_valid_o <= 1'b1;
                fetch_exc_cause_o <= access_fault_cause(1'b1, 1'b0);
                fetch_exc_tval_o <= walk_va_q;
              end
              else begin
                lsu_valid_o <= 1'b1;
                lsu_exc_valid_o <= 1'b1;
                lsu_exc_cause_o <= access_fault_cause(1'b0, walk_store_q);
                lsu_exc_tval_o <= walk_va_q;
              end
              walk_state_q <= WALK_IDLE;
            end
            else if (mem_req_o && mem_gnt_i) begin
              walk_state_q <= WALK_WAIT;
            end
          end

          WALK_WAIT: begin
            if (mem_rvalid_i) begin
              if ((!pte_v_c) || pte_reserved_c) begin
                if (walk_fetch_q) begin
                  fetch_valid_o <= 1'b1;
                  fetch_exc_valid_o <= 1'b1;
                  fetch_exc_cause_o <= page_fault_cause(1'b1, 1'b0);
                  fetch_exc_tval_o <= walk_va_q;
                end
                else begin
                  lsu_valid_o <= 1'b1;
                  lsu_exc_valid_o <= 1'b1;
                  lsu_exc_cause_o <= page_fault_cause(1'b0, walk_store_q);
                  lsu_exc_tval_o <= walk_va_q;
                end
                walk_state_q <= WALK_IDLE;
              end
              else if (pte_leaf_c) begin
                if (pte_super_misaligned_c || (!pte_perm_ok_c)) begin
                  if (walk_fetch_q) begin
                    fetch_valid_o <= 1'b1;
                    fetch_exc_valid_o <= 1'b1;
                    fetch_exc_cause_o <= page_fault_cause(1'b1, 1'b0);
                    fetch_exc_tval_o <= walk_va_q;
                  end
                  else begin
                    lsu_valid_o <= 1'b1;
                    lsu_exc_valid_o <= 1'b1;
                    lsu_exc_cause_o <= page_fault_cause(1'b0, walk_store_q);
                    lsu_exc_tval_o <= walk_va_q;
                  end
                  walk_state_q <= WALK_IDLE;
                end
                else begin
                  if (walk_fetch_q) begin
                    fetch_valid_o <= 1'b1;
                    fetch_paddr_o <= pte_pa_c;
                    fetch_exc_valid_o <= 1'b0;

                    if (!flush_tlb_i) begin
                      itlb_valid_q[itlb_install_idx_c] <= 1'b1;
                      itlb_vpn_q[itlb_install_idx_c] <= walk_va_q[38:12];
                      itlb_ppn_q[itlb_install_idx_c] <= pte_ppn_c;
                      itlb_level_q[itlb_install_idx_c] <= walk_level_q;
                      itlb_asid_q[itlb_install_idx_c] <= walk_asid_q;
                      itlb_flags_q[itlb_install_idx_c] <= mem_rdata_i[7:0];
                      itlb_repl_q <= itlb_install_idx_c + 4'd1;
                    end
                  end
                  else begin
                    lsu_valid_o <= 1'b1;
                    lsu_paddr_o <= pte_pa_c;
                    lsu_exc_valid_o <= 1'b0;

                    if (!flush_tlb_i) begin
                      dtlb_valid_q[dtlb_install_idx_c] <= 1'b1;
                      dtlb_vpn_q[dtlb_install_idx_c] <= walk_va_q[38:12];
                      dtlb_ppn_q[dtlb_install_idx_c] <= pte_ppn_c;
                      dtlb_level_q[dtlb_install_idx_c] <= walk_level_q;
                      dtlb_asid_q[dtlb_install_idx_c] <= walk_asid_q;
                      dtlb_flags_q[dtlb_install_idx_c] <= mem_rdata_i[7:0];
                      dtlb_repl_q <= dtlb_install_idx_c + 4'd1;
                    end
                  end
                  walk_state_q <= WALK_IDLE;
                end
              end
              else begin
                if (walk_level_q == 2'd0) begin
                  if (walk_fetch_q) begin
                    fetch_valid_o <= 1'b1;
                    fetch_exc_valid_o <= 1'b1;
                    fetch_exc_cause_o <= page_fault_cause(1'b1, 1'b0);
                    fetch_exc_tval_o <= walk_va_q;
                  end
                  else begin
                    lsu_valid_o <= 1'b1;
                    lsu_exc_valid_o <= 1'b1;
                    lsu_exc_cause_o <= page_fault_cause(1'b0, walk_store_q);
                    lsu_exc_tval_o <= walk_va_q;
                  end
                  walk_state_q <= WALK_IDLE;
                end
                else begin
                  walk_level_q <= walk_level_q - 2'd1;
                  walk_addr_q <= next_pte_addr_c;
                  walk_state_q <= WALK_REQ;
                end
              end
            end
          end

          WALK_DRAIN: begin
            if (mem_rvalid_i) begin
              walk_level_q <= 2'd2;
              walk_addr_q <= pte_address(walk_root_ppn_q, walk_va_q, 2'd2);
              walk_state_q <= WALK_REQ;
            end
          end

          default: begin
            walk_state_q <= WALK_IDLE;
          end
        endcase
      end
    end
  end

endmodule