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
  // Common translation helpers
  // ---------------------------------------------------------------------------

  function automatic logic vpn_match(
    input logic [26:0] request_vpn,
    input logic [26:0] entry_vpn,
    input logic [1:0]  entry_level
  );
    begin
      case (entry_level)
        2'd0:    vpn_match = (request_vpn == entry_vpn);
        2'd1:    vpn_match = (request_vpn[26:9] == entry_vpn[26:9]);
        default: vpn_match = (request_vpn[26:18] == entry_vpn[26:18]);
      endcase
    end
  endfunction

  function automatic logic [55:0] make_pa(
    input logic [43:0] ppn,
    input logic [1:0]  level,
    input logic [63:0] vaddr
  );
    begin
      case (level)
        2'd0:    make_pa = {ppn, vaddr[11:0]};
        2'd1:    make_pa = {ppn[43:9], vaddr[20:12], vaddr[11:0]};
        default: make_pa = {ppn[43:18], vaddr[29:12], vaddr[11:0]};
      endcase
    end
  endfunction

  function automatic logic permission_ok(
    input logic       pte_r,
    input logic       pte_w,
    input logic       pte_x,
    input logic       pte_u,
    input logic       fetch_access,
    input logic       store_access,
    input logic [1:0] priv,
    input logic       sum,
    input logic       mxr
  );
    logic ok;
    begin
      if (fetch_access)
        ok = pte_x;
      else if (store_access)
        ok = pte_w;
      else
        ok = pte_r || (pte_x && mxr);

      if ((priv == 2'b00) && !pte_u)
        ok = 1'b0;

      if ((priv == 2'b01) && pte_u) begin
        if (fetch_access)
          ok = 1'b0;
        else if (!sum)
          ok = 1'b0;
      end

      permission_ok = ok;
    end
  endfunction

  // ---------------------------------------------------------------------------
  // 16-entry fully associative TLBs
  // ---------------------------------------------------------------------------

  logic [15:0] dtlb_valid;
  logic [15:0] itlb_valid;

  logic [26:0] dtlb_vpn    [0:15];
  logic [43:0] dtlb_ppn    [0:15];
  logic [15:0] dtlb_asid   [0:15];
  logic [1:0]  dtlb_level  [0:15];
  logic        dtlb_global [0:15];
  logic        dtlb_r      [0:15];
  logic        dtlb_w      [0:15];
  logic        dtlb_x      [0:15];
  logic        dtlb_u      [0:15];
  logic        dtlb_d      [0:15];

  logic [26:0] itlb_vpn    [0:15];
  logic [43:0] itlb_ppn    [0:15];
  logic [15:0] itlb_asid   [0:15];
  logic [1:0]  itlb_level  [0:15];
  logic        itlb_global [0:15];
  logic        itlb_r      [0:15];
  logic        itlb_w      [0:15];
  logic        itlb_x      [0:15];
  logic        itlb_u      [0:15];

  logic [3:0] dtlb_rr;
  logic [3:0] itlb_rr;

  logic       dtlb_hit;
  logic [3:0] dtlb_hit_idx;
  logic [1:0] dtlb_hit_level;
  logic [43:0] dtlb_hit_ppn;
  logic       dtlb_hit_r;
  logic       dtlb_hit_w;
  logic       dtlb_hit_x;
  logic       dtlb_hit_u;
  logic       dtlb_hit_d;
  logic [55:0] dtlb_hit_pa;
  logic       dtlb_hit_perm_ok;

  logic       itlb_hit;
  logic [3:0] itlb_hit_idx;
  logic [1:0] itlb_hit_level;
  logic [43:0] itlb_hit_ppn;
  logic       itlb_hit_r;
  logic       itlb_hit_w;
  logic       itlb_hit_x;
  logic       itlb_hit_u;
  logic [55:0] itlb_hit_pa;
  logic       itlb_hit_perm_ok;

  always_comb begin
    dtlb_hit     = 1'b0;
    dtlb_hit_idx = 4'd0;

    for (int unsigned i = 0; i < 16; i++) begin
      if (!dtlb_hit &&
          dtlb_valid[i] &&
          (dtlb_global[i] || (dtlb_asid[i] == asid_i)) &&
          vpn_match(lsu_vaddr_i[38:12], dtlb_vpn[i], dtlb_level[i])) begin
        dtlb_hit     = 1'b1;
        dtlb_hit_idx = i[3:0];
      end
    end

    dtlb_hit_level = 2'd0;
    dtlb_hit_ppn   = 44'd0;
    dtlb_hit_r     = 1'b0;
    dtlb_hit_w     = 1'b0;
    dtlb_hit_x     = 1'b0;
    dtlb_hit_u     = 1'b0;
    dtlb_hit_d     = 1'b0;

    if (dtlb_hit) begin
      dtlb_hit_level = dtlb_level[dtlb_hit_idx];
      dtlb_hit_ppn   = dtlb_ppn[dtlb_hit_idx];
      dtlb_hit_r     = dtlb_r[dtlb_hit_idx];
      dtlb_hit_w     = dtlb_w[dtlb_hit_idx];
      dtlb_hit_x     = dtlb_x[dtlb_hit_idx];
      dtlb_hit_u     = dtlb_u[dtlb_hit_idx];
      dtlb_hit_d     = dtlb_d[dtlb_hit_idx];
    end

    dtlb_hit_pa = make_pa(dtlb_hit_ppn, dtlb_hit_level, lsu_vaddr_i);
    dtlb_hit_perm_ok = permission_ok(
      dtlb_hit_r, dtlb_hit_w, dtlb_hit_x, dtlb_hit_u,
      1'b0, lsu_is_store_i, ld_st_priv_lvl_i, sum_i, mxr_i
    );
  end

  always_comb begin
    itlb_hit     = 1'b0;
    itlb_hit_idx = 4'd0;

    for (int unsigned i = 0; i < 16; i++) begin
      if (!itlb_hit &&
          itlb_valid[i] &&
          (itlb_global[i] || (itlb_asid[i] == asid_i)) &&
          vpn_match(fetch_vaddr_i[38:12], itlb_vpn[i], itlb_level[i])) begin
        itlb_hit     = 1'b1;
        itlb_hit_idx = i[3:0];
      end
    end

    itlb_hit_level = 2'd0;
    itlb_hit_ppn   = 44'd0;
    itlb_hit_r     = 1'b0;
    itlb_hit_w     = 1'b0;
    itlb_hit_x     = 1'b0;
    itlb_hit_u     = 1'b0;

    if (itlb_hit) begin
      itlb_hit_level = itlb_level[itlb_hit_idx];
      itlb_hit_ppn   = itlb_ppn[itlb_hit_idx];
      itlb_hit_r     = itlb_r[itlb_hit_idx];
      itlb_hit_w     = itlb_w[itlb_hit_idx];
      itlb_hit_x     = itlb_x[itlb_hit_idx];
      itlb_hit_u     = itlb_u[itlb_hit_idx];
    end

    itlb_hit_pa = make_pa(itlb_hit_ppn, itlb_hit_level, fetch_vaddr_i);
    itlb_hit_perm_ok = permission_ok(
      itlb_hit_r, itlb_hit_w, itlb_hit_x, itlb_hit_u,
      1'b1, 1'b0, priv_lvl_i, sum_i, mxr_i
    );
  end

  // Prefer an invalid entry, then use round-robin replacement. This spreads a
  // cold fill over all sixteen entries without requiring hit-based PLRU state.
  logic [3:0] dtlb_victim;
  logic [3:0] itlb_victim;
  logic       dtlb_invalid_found;
  logic       itlb_invalid_found;

  always_comb begin
    dtlb_victim        = dtlb_rr;
    dtlb_invalid_found = 1'b0;

    for (int unsigned i = 0; i < 16; i++) begin
      if (!dtlb_invalid_found && !dtlb_valid[i]) begin
        dtlb_victim        = i[3:0];
        dtlb_invalid_found = 1'b1;
      end
    end
  end

  always_comb begin
    itlb_victim        = itlb_rr;
    itlb_invalid_found = 1'b0;

    for (int unsigned i = 0; i < 16; i++) begin
      if (!itlb_invalid_found && !itlb_valid[i]) begin
        itlb_victim        = i[3:0];
        itlb_invalid_found = 1'b1;
      end
    end
  end

  // ---------------------------------------------------------------------------
  // Shared three-level page-table walker
  // ---------------------------------------------------------------------------

  typedef enum logic [1:0] {
    W_IDLE,
    W_REQ,
    W_WAIT,
    W_DRAIN
  } walk_state_t;

  localparam logic OWNER_LSU   = 1'b0;
  localparam logic OWNER_FETCH = 1'b1;

  walk_state_t walk_state;
  logic        walk_owner;
  logic [63:0] walk_vaddr;
  logic        walk_is_store;
  logic [1:0]  walk_priv;
  logic        walk_sum;
  logic        walk_mxr;
  logic [15:0] walk_asid;
  logic [55:0] walk_base;
  logic [1:0]  walk_level;
  logic [55:0] walk_addr;

  always_comb begin
    walk_addr = walk_base;
    case (walk_level)
      2'd2: walk_addr = walk_base + {44'd0, walk_vaddr[38:30], 3'b000};
      2'd1: walk_addr = walk_base + {44'd0, walk_vaddr[29:21], 3'b000};
      default: walk_addr = walk_base + {44'd0, walk_vaddr[20:12], 3'b000};
    endcase
  end

  logic        pte_v;
  logic        pte_r;
  logic        pte_w;
  logic        pte_x;
  logic        pte_u;
  logic        pte_g;
  logic        pte_a;
  logic        pte_d;
  logic [43:0] pte_ppn;
  logic        pte_leaf;
  logic        pte_reserved;
  logic        walk_misaligned;
  logic        walk_perm_ok;
  logic        walk_pte_fault;
  logic [55:0] walk_translated_pa;

  assign pte_v        = mem_rdata_i[0];
  assign pte_r        = mem_rdata_i[1];
  assign pte_w        = mem_rdata_i[2];
  assign pte_x        = mem_rdata_i[3];
  assign pte_u        = mem_rdata_i[4];
  assign pte_g        = mem_rdata_i[5];
  assign pte_a        = mem_rdata_i[6];
  assign pte_d        = mem_rdata_i[7];
  assign pte_ppn      = mem_rdata_i[53:10];
  assign pte_leaf     = pte_r || pte_x;
  assign pte_reserved = pte_w && !pte_r;

  assign walk_misaligned =
      ((walk_level == 2'd2) && (|pte_ppn[17:0])) ||
      ((walk_level == 2'd1) && (|pte_ppn[8:0]));

  assign walk_perm_ok = permission_ok(
    pte_r, pte_w, pte_x, pte_u,
    (walk_owner == OWNER_FETCH),
    ((walk_owner == OWNER_LSU) && walk_is_store),
    walk_priv, walk_sum, walk_mxr
  );

  assign walk_pte_fault =
      !pte_v ||
      pte_reserved ||
      (pte_leaf &&
       (walk_misaligned ||
        !walk_perm_ok ||
        !pte_a ||
        ((walk_owner == OWNER_LSU) && walk_is_store && !pte_d))) ||
      (!pte_leaf && (walk_level == 2'd0));

  assign walk_translated_pa = make_pa(pte_ppn, walk_level, walk_vaddr);

  // ---------------------------------------------------------------------------
  // PMP check for the walker's eight-byte read
  //
  // The first region overlapping any byte of the access determines the result.
  // The complete eight-byte access must be contained in that region and R must
  // be set. No matching region denies the access.
  // ---------------------------------------------------------------------------

  logic        pmp_allow;
  logic        pmp_found;
  logic [57:0] pmp_acc_lo;
  logic [57:0] pmp_acc_hi;
  logic [57:0] pmp_region_lo;
  logic [57:0] pmp_region_hi;
  logic [57:0] pmp_region_size;
  logic [57:0] pmp_raw_base;
  logic        pmp_overlap;
  logic        pmp_contained;
  logic        pmp_counting;
  integer      pmp_napot_ones;

  always_comb begin
    pmp_allow       = 1'b0;
    pmp_found       = 1'b0;
    pmp_acc_lo      = {2'b00, walk_addr};
    pmp_acc_hi      = {2'b00, walk_addr} + 58'd8;
    pmp_region_lo   = 58'd0;
    pmp_region_hi   = 58'd0;
    pmp_region_size = 58'd0;
    pmp_raw_base    = 58'd0;
    pmp_overlap     = 1'b0;
    pmp_contained   = 1'b0;
    pmp_counting    = 1'b0;
    pmp_napot_ones  = 0;

    for (int unsigned p = 0; p < 8; p++) begin
      pmp_region_lo   = 58'd0;
      pmp_region_hi   = 58'd0;
      pmp_region_size = 58'd0;
      pmp_raw_base    = 58'd0;

      if (pmpcfg_i[p][4:3] != 2'd0) begin
        case (pmpcfg_i[p][4:3])
          2'd1: begin // TOR
            if (p == 0)
              pmp_region_lo = 58'd0;
            else
              pmp_region_lo = {2'b00, pmpaddr_i[p-1], 2'b00};
            pmp_region_hi = {2'b00, pmpaddr_i[p], 2'b00};
          end

          2'd2: begin // NA4
            pmp_region_lo = {2'b00, pmpaddr_i[p], 2'b00};
            pmp_region_hi = pmp_region_lo + 58'd4;
          end

          default: begin // NAPOT
            pmp_napot_ones = 0;
            pmp_counting   = 1'b1;

            for (int unsigned b = 0; b < 54; b++) begin
              if (pmp_counting) begin
                if (pmpaddr_i[p][b])
                  pmp_napot_ones = pmp_napot_ones + 1;
                else
                  pmp_counting = 1'b0;
              end
            end

            pmp_raw_base    = {2'b00, pmpaddr_i[p], 2'b00};
            pmp_region_size = 58'd1 << (pmp_napot_ones + 3);
            pmp_region_lo   =
                pmp_raw_base & ~(pmp_region_size - 58'd1);
            pmp_region_hi   = pmp_region_lo + pmp_region_size;
          end
        endcase

        pmp_overlap =
            (pmp_acc_lo < pmp_region_hi) &&
            (pmp_acc_hi > pmp_region_lo);
        pmp_contained =
            (pmp_acc_lo >= pmp_region_lo) &&
            (pmp_acc_hi <= pmp_region_hi);

        if (!pmp_found && pmp_overlap) begin
          pmp_found = 1'b1;
          pmp_allow = pmp_contained && pmpcfg_i[p][0];
        end
      end
    end
  end

  // ---------------------------------------------------------------------------
  // Memory interface and request arbitration
  // ---------------------------------------------------------------------------

  logic lsu_start;
  logic fetch_start;

  assign lsu_start =
      (walk_state == W_IDLE) &&
      lsu_req_i && !lsu_valid_o &&
      en_ld_st_translation_i && !dtlb_hit &&
      !flush_i && !flush_tlb_i;

  assign fetch_start =
      (walk_state == W_IDLE) &&
      fetch_req_i && !fetch_valid_o &&
      enable_translation_i && !itlb_hit &&
      !flush_i && !flush_tlb_i;

  always_comb begin
    mem_req_o  = 1'b0;
    mem_addr_o = 56'd0;

    if (rst_ni && (walk_state == W_REQ) &&
        !flush_i && !flush_tlb_i) begin
      mem_addr_o = walk_addr;
      mem_req_o  = pmp_allow;
    end
  end

  assign mem_tag_valid_o = 1'b0;
  assign mem_kill_o      = 1'b0;

  assign lsu_dtlb_hit_o =
      rst_ni && lsu_req_i && en_ld_st_translation_i && dtlb_hit;
  assign lsu_dtlb_ppn_o = dtlb_hit ? dtlb_hit_pa[55:12] : 44'd0;
  assign itlb_miss_o    = fetch_start;
  assign dtlb_miss_o    = lsu_start;

  // The narrowing inputs are intentionally unused: every TLB flush is a full
  // flush, which is a conservative implementation of C2.
  logic unused_flush_narrowing;
  assign unused_flush_narrowing =
      ^{asid_to_be_flushed_i, vaddr_to_be_flushed_i};

  // ---------------------------------------------------------------------------
  // Retirement, TLB installation, flushing, and walker sequencing
  // ---------------------------------------------------------------------------

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      lsu_valid_o       <= 1'b0;
      lsu_paddr_o       <= 56'd0;
      lsu_exc_valid_o   <= 1'b0;
      lsu_exc_cause_o   <= 64'd0;
      lsu_exc_tval_o    <= 64'd0;

      fetch_valid_o     <= 1'b0;
      fetch_paddr_o     <= 56'd0;
      fetch_exc_valid_o <= 1'b0;
      fetch_exc_cause_o <= 64'd0;
      fetch_exc_tval_o  <= 64'd0;

      dtlb_valid        <= 16'd0;
      itlb_valid        <= 16'd0;
      dtlb_rr           <= 4'd0;
      itlb_rr           <= 4'd0;

      walk_state        <= W_IDLE;
      walk_owner        <= OWNER_LSU;
      walk_vaddr        <= 64'd0;
      walk_is_store     <= 1'b0;
      walk_priv         <= 2'd0;
      walk_sum          <= 1'b0;
      walk_mxr          <= 1'b0;
      walk_asid         <= 16'd0;
      walk_base         <= 56'd0;
      walk_level        <= 2'd2;
    end else begin
      lsu_valid_o       <= 1'b0;
      lsu_exc_valid_o   <= 1'b0;
      fetch_valid_o     <= 1'b0;
      fetch_exc_valid_o <= 1'b0;

      if (flush_tlb_i) begin
        dtlb_valid <= 16'd0;
        itlb_valid <= 16'd0;
        dtlb_rr    <= 4'd0;
        itlb_rr    <= 4'd0;
      end

      // Bare-mode and TLB-hit retirements. A response already asserted blocks
      // re-serving the same level-sensitive request for a second cycle.
      if (lsu_req_i && !lsu_valid_o) begin
        if (!en_ld_st_translation_i) begin
          lsu_valid_o     <= 1'b1;
          lsu_paddr_o     <= lsu_vaddr_i[55:0];
          lsu_exc_valid_o <= 1'b0;
          lsu_exc_cause_o <= 64'd0;
          lsu_exc_tval_o  <= 64'd0;
        end else if (dtlb_hit && !flush_tlb_i) begin
          lsu_valid_o <= 1'b1;

          if (dtlb_hit_perm_ok &&
              !(lsu_is_store_i && !dtlb_hit_d)) begin
            lsu_paddr_o     <= dtlb_hit_pa;
            lsu_exc_valid_o <= 1'b0;
            lsu_exc_cause_o <= 64'd0;
            lsu_exc_tval_o  <= 64'd0;
          end else begin
            lsu_paddr_o     <= 56'd0;
            lsu_exc_valid_o <= 1'b1;
            lsu_exc_cause_o <= lsu_is_store_i ? 64'd15 : 64'd13;
            lsu_exc_tval_o  <= lsu_vaddr_i;
          end
        end
      end

      if (fetch_req_i && !fetch_valid_o) begin
        if (!enable_translation_i) begin
          fetch_valid_o     <= 1'b1;
          fetch_paddr_o     <= fetch_vaddr_i[55:0];
          fetch_exc_valid_o <= 1'b0;
          fetch_exc_cause_o <= 64'd0;
          fetch_exc_tval_o  <= 64'd0;
        end else if (itlb_hit && !flush_tlb_i) begin
          fetch_valid_o <= 1'b1;

          if (itlb_hit_perm_ok) begin
            fetch_paddr_o     <= itlb_hit_pa;
            fetch_exc_valid_o <= 1'b0;
            fetch_exc_cause_o <= 64'd0;
            fetch_exc_tval_o  <= 64'd0;
          end else begin
            fetch_paddr_o     <= 56'd0;
            fetch_exc_valid_o <= 1'b1;
            fetch_exc_cause_o <= 64'd12;
            fetch_exc_tval_o  <= fetch_vaddr_i;
          end
        end
      end

      // A flush aborts the current walk. If a read is already outstanding, its
      // response is drained before the held request is restarted.
      if ((flush_i || flush_tlb_i) && (walk_state != W_IDLE)) begin
        case (walk_state)
          W_REQ: begin
            // mem_req_o is suppressed during a flush, so no new read is accepted.
            walk_state <= W_IDLE;
          end

          W_WAIT: begin
            if (mem_rvalid_i)
              walk_state <= W_IDLE;
            else
              walk_state <= W_DRAIN;
          end

          W_DRAIN: begin
            if (mem_rvalid_i)
              walk_state <= W_IDLE;
          end

          default: walk_state <= W_IDLE;
        endcase
      end else begin
        case (walk_state)
          W_IDLE: begin
            // Fetch has priority when both ports miss simultaneously. The other
            // request remains asserted and starts as soon as the walker is idle.
            if (fetch_start) begin
              walk_owner    <= OWNER_FETCH;
              walk_vaddr    <= fetch_vaddr_i;
              walk_is_store <= 1'b0;
              walk_priv     <= priv_lvl_i;
              walk_sum      <= sum_i;
              walk_mxr      <= mxr_i;
              walk_asid     <= asid_i;
              walk_base     <= {satp_ppn_i, 12'b0};
              walk_level    <= 2'd2;
              walk_state    <= W_REQ;
            end else if (lsu_start) begin
              walk_owner    <= OWNER_LSU;
              walk_vaddr    <= lsu_vaddr_i;
              walk_is_store <= lsu_is_store_i;
              walk_priv     <= ld_st_priv_lvl_i;
              walk_sum      <= sum_i;
              walk_mxr      <= mxr_i;
              walk_asid     <= asid_i;
              walk_base     <= {satp_ppn_i, 12'b0};
              walk_level    <= 2'd2;
              walk_state    <= W_REQ;
            end
          end

          W_REQ: begin
            if (!pmp_allow) begin
              walk_state <= W_IDLE;

              if (walk_owner == OWNER_FETCH) begin
                fetch_valid_o     <= 1'b1;
                fetch_paddr_o     <= 56'd0;
                fetch_exc_valid_o <= 1'b1;
                fetch_exc_cause_o <= 64'd1;
                fetch_exc_tval_o  <= walk_vaddr;
              end else begin
                lsu_valid_o       <= 1'b1;
                lsu_paddr_o       <= 56'd0;
                lsu_exc_valid_o   <= 1'b1;
                lsu_exc_cause_o   <= walk_is_store ? 64'd7 : 64'd5;
                lsu_exc_tval_o    <= walk_vaddr;
              end
            end else if (mem_gnt_i) begin
              walk_state <= W_WAIT;
            end
          end

          W_WAIT: begin
            if (mem_rvalid_i) begin
              if (walk_pte_fault) begin
                walk_state <= W_IDLE;

                if (walk_owner == OWNER_FETCH) begin
                  fetch_valid_o     <= 1'b1;
                  fetch_paddr_o     <= 56'd0;
                  fetch_exc_valid_o <= 1'b1;
                  fetch_exc_cause_o <= 64'd12;
                  fetch_exc_tval_o  <= walk_vaddr;
                end else begin
                  lsu_valid_o       <= 1'b1;
                  lsu_paddr_o       <= 56'd0;
                  lsu_exc_valid_o   <= 1'b1;
                  lsu_exc_cause_o   <= walk_is_store ? 64'd15 : 64'd13;
                  lsu_exc_tval_o    <= walk_vaddr;
                end
              end else if (pte_leaf) begin
                walk_state <= W_IDLE;

                if (walk_owner == OWNER_FETCH) begin
                  fetch_valid_o     <= 1'b1;
                  fetch_paddr_o     <= walk_translated_pa;
                  fetch_exc_valid_o <= 1'b0;
                  fetch_exc_cause_o <= 64'd0;
                  fetch_exc_tval_o  <= 64'd0;

                  itlb_valid[itlb_victim]  <= 1'b1;
                  itlb_vpn[itlb_victim]    <= walk_vaddr[38:12];
                  itlb_ppn[itlb_victim]    <= pte_ppn;
                  itlb_asid[itlb_victim]   <= walk_asid;
                  itlb_level[itlb_victim]  <= walk_level;
                  itlb_global[itlb_victim] <= pte_g;
                  itlb_r[itlb_victim]      <= pte_r;
                  itlb_w[itlb_victim]      <= pte_w;
                  itlb_x[itlb_victim]      <= pte_x;
                  itlb_u[itlb_victim]      <= pte_u;
                  itlb_rr                  <= itlb_victim + 4'd1;
                end else begin
                  lsu_valid_o       <= 1'b1;
                  lsu_paddr_o       <= walk_translated_pa;
                  lsu_exc_valid_o   <= 1'b0;
                  lsu_exc_cause_o   <= 64'd0;
                  lsu_exc_tval_o    <= 64'd0;

                  dtlb_valid[dtlb_victim]  <= 1'b1;
                  dtlb_vpn[dtlb_victim]    <= walk_vaddr[38:12];
                  dtlb_ppn[dtlb_victim]    <= pte_ppn;
                  dtlb_asid[dtlb_victim]   <= walk_asid;
                  dtlb_level[dtlb_victim]  <= walk_level;
                  dtlb_global[dtlb_victim] <= pte_g;
                  dtlb_r[dtlb_victim]      <= pte_r;
                  dtlb_w[dtlb_victim]      <= pte_w;
                  dtlb_x[dtlb_victim]      <= pte_x;
                  dtlb_u[dtlb_victim]      <= pte_u;
                  dtlb_d[dtlb_victim]      <= pte_d;
                  dtlb_rr                  <= dtlb_victim + 4'd1;
                end
              end else begin
                // Valid non-leaf at level 1 or 2: descend one level.
                walk_base  <= {pte_ppn, 12'b0};
                walk_level <= walk_level - 2'd1;
                walk_state <= W_REQ;
              end
            end
          end

          W_DRAIN: begin
            if (mem_rvalid_i)
              walk_state <= W_IDLE;
          end

          default: walk_state <= W_IDLE;
        endcase
      end
    end
  end

endmodule
