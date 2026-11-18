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

  // Only translations which have passed the A-bit check are installed.  The
  // remaining permission bits are retained because access type, privilege,
  // SUM and MXR can change without a TLB flush.
  typedef struct packed {
    logic        valid;
    logic        g;
    logic [15:0] asid;
    logic [26:0] vpn;
    logic [43:0] ppn;
    logic [1:0]  level;
    logic        r;
    logic        w;
    logic        x;
    logic        u;
    logic        d;
  } tlb_entry_t;

  tlb_entry_t itlb_q [0:15];
  tlb_entry_t dtlb_q [0:15];

  logic [3:0] itlb_rr_q;
  logic [3:0] dtlb_rr_q;

  logic       itlb_hit;
  logic       dtlb_hit;
  tlb_entry_t itlb_hit_entry;
  tlb_entry_t dtlb_hit_entry;
  logic [55:0] itlb_hit_pa;
  logic [55:0] dtlb_hit_pa;
  logic        itlb_hit_fault;
  logic        dtlb_hit_fault;

  logic [3:0] itlb_victim;
  logic [3:0] dtlb_victim;
  logic       itlb_invalid_seen;
  logic       dtlb_invalid_seen;

  typedef enum logic [2:0] {
    S_IDLE  = 3'd0,
    S_REQ   = 3'd1,
    S_WAIT  = 3'd2,
    S_PROC  = 3'd3,
    S_ABORT = 3'd4
  } state_t;

  state_t state_q;

  logic        walk_is_fetch_q;
  logic        walk_is_store_q;
  logic [63:0] walk_vaddr_q;
  logic [1:0]  walk_priv_q;
  logic        walk_sum_q;
  logic        walk_mxr_q;
  logic [15:0] walk_asid_q;
  logic [43:0] walk_root_q;
  logic [55:0] walk_a_q;
  logic [1:0]  walk_level_q;
  logic [63:0] walk_pte_q;

  logic [63:0] walk_pte;
  logic [8:0]  walk_vpn;
  logic [55:0] walk_pte_addr;
  logic        walk_pte_leaf;
  logic        walk_pte_bad;
  logic        walk_pte_misaligned;
  logic        walk_pte_perm_fault;
  logic        walk_pte_fault;
  logic [55:0] walk_success_pa;

  logic        pmp_match_found;
  logic        pmp_read_allow;
  logic [55:0] pmp_end_addr;
  logic [7:0][53:0] pmp_prev_addr;

  function automatic logic tlb_tag_match(
    input tlb_entry_t  entry,
    input logic [26:0] vpn
  );
    begin
      case (entry.level)
        2'd2:    tlb_tag_match = entry.vpn[26:18] == vpn[26:18];
        2'd1:    tlb_tag_match = entry.vpn[26:9]  == vpn[26:9];
        default: tlb_tag_match = entry.vpn        == vpn;
      endcase
    end
  endfunction

  function automatic logic [55:0] compose_pa(
    input logic [43:0] ppn,
    input logic [1:0]  level,
    input logic [63:0] va
  );
    begin
      case (level)
        2'd2:    compose_pa = {ppn[43:18], va[29:0]};
        2'd1:    compose_pa = {ppn[43:9],  va[20:0]};
        default: compose_pa = {ppn,        va[11:0]};
      endcase
    end
  endfunction

  function automatic logic [8:0] vpn_at_level(
    input logic [63:0] va,
    input logic [1:0]  level
  );
    begin
      case (level)
        2'd2:    vpn_at_level = va[38:30];
        2'd1:    vpn_at_level = va[29:21];
        default: vpn_at_level = va[20:12];
      endcase
    end
  endfunction

  function automatic logic permissions_fault(
    input logic       r,
    input logic       w,
    input logic       x,
    input logic       u,
    input logic       a,
    input logic       d,
    input logic       is_fetch,
    input logic       is_store,
    input logic [1:0] priv,
    input logic       sum,
    input logic       mxr
  );
    begin
      permissions_fault = 1'b0;

      if (!a)
        permissions_fault = 1'b1;

      if (is_fetch) begin
        if (!x)
          permissions_fault = 1'b1;
        if ((priv == 2'b00) && !u)
          permissions_fault = 1'b1;
        if ((priv == 2'b01) && u)
          permissions_fault = 1'b1;
      end else begin
        if (is_store) begin
          if (!w || !d)
            permissions_fault = 1'b1;
        end else begin
          if (!(r || (x && mxr)))
            permissions_fault = 1'b1;
        end

        if ((priv == 2'b00) && !u)
          permissions_fault = 1'b1;
        if ((priv == 2'b01) && u && !sum)
          permissions_fault = 1'b1;
      end
    end
  endfunction

  // Match the complete eight-byte walker read.  For NAPOT, the low encoded
  // address bits through the first zero are excluded from the comparison.
  function automatic logic pmp_entry_match(
    input logic [55:0] start_addr,
    input logic [55:0] end_addr,
    input logic [7:0]  cfg,
    input logic [53:0] pmpaddr,
    input logic [53:0] prev_pmpaddr
  );
    logic [53:0] napot_mask;
    logic        seen_zero;
    logic [55:0] tor_base;
    logic [55:0] tor_top;
    integer      j;
    begin
      napot_mask = 54'd0;
      seen_zero  = 1'b0;
      tor_base   = {prev_pmpaddr, 2'b00};
      tor_top    = {pmpaddr,      2'b00};

      for (j = 0; j < 54; j = j + 1) begin
        if (!seen_zero) begin
          napot_mask[j] = 1'b1;
          if (!pmpaddr[j])
            seen_zero = 1'b1;
        end
      end

      case (cfg[4:3])
        2'b01: begin                         // TOR
          pmp_entry_match = (start_addr >= tor_base) &&
                            (end_addr   <  tor_top);
        end
        2'b10: begin                         // NA4
          pmp_entry_match = (start_addr[55:2] == pmpaddr) &&
                            (end_addr[55:2]   == pmpaddr);
        end
        2'b11: begin                         // NAPOT
          pmp_entry_match =
            ((start_addr[55:2] & ~napot_mask) ==
             (pmpaddr          & ~napot_mask)) &&
            ((end_addr[55:2] & ~napot_mask) ==
             (pmpaddr        & ~napot_mask));
        end
        default: pmp_entry_match = 1'b0;     // OFF
      endcase
    end
  endfunction

  // Fully associative lookups.
  always_comb begin
    itlb_hit       = 1'b0;
    itlb_hit_entry = '0;
    for (int i = 0; i < 16; i = i + 1) begin
      if (!itlb_hit && itlb_q[i].valid &&
          (itlb_q[i].g || (itlb_q[i].asid == asid_i)) &&
          tlb_tag_match(itlb_q[i], fetch_vaddr_i[38:12])) begin
        itlb_hit       = 1'b1;
        itlb_hit_entry = itlb_q[i];
      end
    end
  end

  always_comb begin
    dtlb_hit       = 1'b0;
    dtlb_hit_entry = '0;
    for (int i = 0; i < 16; i = i + 1) begin
      if (!dtlb_hit && dtlb_q[i].valid &&
          (dtlb_q[i].g || (dtlb_q[i].asid == asid_i)) &&
          tlb_tag_match(dtlb_q[i], lsu_vaddr_i[38:12])) begin
        dtlb_hit       = 1'b1;
        dtlb_hit_entry = dtlb_q[i];
      end
    end
  end

  assign itlb_hit_pa = compose_pa(itlb_hit_entry.ppn,
                                  itlb_hit_entry.level,
                                  fetch_vaddr_i);
  assign dtlb_hit_pa = compose_pa(dtlb_hit_entry.ppn,
                                  dtlb_hit_entry.level,
                                  lsu_vaddr_i);

  assign itlb_hit_fault = permissions_fault(
    itlb_hit_entry.r, itlb_hit_entry.w, itlb_hit_entry.x,
    itlb_hit_entry.u, 1'b1, itlb_hit_entry.d,
    1'b1, 1'b0, priv_lvl_i, sum_i, mxr_i
  );

  assign dtlb_hit_fault = permissions_fault(
    dtlb_hit_entry.r, dtlb_hit_entry.w, dtlb_hit_entry.x,
    dtlb_hit_entry.u, 1'b1, dtlb_hit_entry.d,
    1'b0, lsu_is_store_i, ld_st_priv_lvl_i, sum_i, mxr_i
  );

  // Prefer an invalid entry.  Once full, use round-robin.  Advancing from the
  // actual victim also makes a cold fill spread correctly when old entries
  // were already resident.
  always_comb begin
    itlb_victim       = itlb_rr_q;
    itlb_invalid_seen = 1'b0;
    for (int i = 0; i < 16; i = i + 1) begin
      if (!itlb_invalid_seen && !itlb_q[i].valid) begin
        itlb_victim       = i[3:0];
        itlb_invalid_seen = 1'b1;
      end
    end
  end

  always_comb begin
    dtlb_victim       = dtlb_rr_q;
    dtlb_invalid_seen = 1'b0;
    for (int i = 0; i < 16; i = i + 1) begin
      if (!dtlb_invalid_seen && !dtlb_q[i].valid) begin
        dtlb_victim       = i[3:0];
        dtlb_invalid_seen = 1'b1;
      end
    end
  end

  assign walk_vpn      = vpn_at_level(walk_vaddr_q, walk_level_q);
  assign walk_pte_addr = walk_a_q + {44'd0, walk_vpn, 3'b000};
  assign walk_pte      = (state_q == S_PROC) ? walk_pte_q : mem_rdata_i;

  assign walk_pte_leaf = walk_pte[1] || walk_pte[3];
  assign walk_pte_bad  = !walk_pte[0] ||
                         (walk_pte[2] && !walk_pte[1]);

  assign walk_pte_misaligned =
      ((walk_level_q == 2'd1) && (|walk_pte[18:10])) ||
      ((walk_level_q == 2'd2) && (|walk_pte[27:10]));

  assign walk_pte_perm_fault = permissions_fault(
    walk_pte[1], walk_pte[2], walk_pte[3], walk_pte[4],
    walk_pte[6], walk_pte[7],
    walk_is_fetch_q, walk_is_store_q,
    walk_priv_q, walk_sum_q, walk_mxr_q
  );

  assign walk_pte_fault = walk_pte_bad ||
                          (walk_pte_leaf &&
                           (walk_pte_misaligned || walk_pte_perm_fault)) ||
                          (!walk_pte_leaf && (walk_level_q == 2'd0));

  assign walk_success_pa = compose_pa(walk_pte[53:10],
                                      walk_level_q,
                                      walk_vaddr_q);

  // Lowest-numbered matching PMP entry wins.  No match denies the read.
  assign pmp_end_addr = walk_pte_addr + 56'd7;

  always_comb begin
    pmp_prev_addr   = '0;
    pmp_match_found = 1'b0;
    pmp_read_allow  = 1'b0;

    for (int p = 1; p < 8; p = p + 1)
      pmp_prev_addr[p] = pmpaddr_i[p-1];

    for (int p = 0; p < 8; p = p + 1) begin
      if (!pmp_match_found &&
          pmp_entry_match(walk_pte_addr, pmp_end_addr,
                          pmpcfg_i[p], pmpaddr_i[p],
                          pmp_prev_addr[p])) begin
        pmp_match_found = 1'b1;
        pmp_read_allow  = pmpcfg_i[p][0];
      end
    end
  end

  assign mem_req_o       = rst_ni && (state_q == S_REQ) && pmp_read_allow;
  assign mem_addr_o      = walk_pte_addr;
  assign mem_tag_valid_o = 1'b0;
  assign mem_kill_o      = 1'b0;

  assign lsu_dtlb_hit_o  = dtlb_hit;
  assign lsu_dtlb_ppn_o  = dtlb_hit ? dtlb_hit_entry.ppn : 44'd0;
  assign itlb_miss_o     = rst_ni && fetch_req_i &&
                           enable_translation_i && !itlb_hit;
  assign dtlb_miss_o     = rst_ni && lsu_req_i &&
                           en_ld_st_translation_i && !dtlb_hit;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      state_q          <= S_IDLE;
      itlb_rr_q        <= 4'd0;
      dtlb_rr_q        <= 4'd0;

      walk_is_fetch_q  <= 1'b0;
      walk_is_store_q  <= 1'b0;
      walk_vaddr_q     <= 64'd0;
      walk_priv_q      <= 2'd0;
      walk_sum_q       <= 1'b0;
      walk_mxr_q       <= 1'b0;
      walk_asid_q      <= 16'd0;
      walk_root_q      <= 44'd0;
      walk_a_q         <= 56'd0;
      walk_level_q     <= 2'd0;
      walk_pte_q       <= 64'd0;

      lsu_valid_o      <= 1'b0;
      lsu_paddr_o      <= 56'd0;
      lsu_exc_valid_o  <= 1'b0;
      lsu_exc_cause_o  <= 64'd0;
      lsu_exc_tval_o   <= 64'd0;
      fetch_valid_o    <= 1'b0;
      fetch_paddr_o    <= 56'd0;
      fetch_exc_valid_o<= 1'b0;
      fetch_exc_cause_o<= 64'd0;
      fetch_exc_tval_o <= 64'd0;

      for (int k = 0; k < 16; k = k + 1) begin
        itlb_q[k].valid <= 1'b0;
        dtlb_q[k].valid <= 1'b0;
      end
    end else begin
      // Retirement is a one-cycle pulse.  A fault retires with both valid and
      // exception-valid asserted.
      lsu_valid_o       <= 1'b0;
      lsu_exc_valid_o   <= 1'b0;
      fetch_valid_o     <= 1'b0;
      fetch_exc_valid_o <= 1'b0;

      // Narrowed flushes are conservatively implemented as full flushes.
      if (flush_tlb_i) begin
        itlb_rr_q <= 4'd0;
        dtlb_rr_q <= 4'd0;
        for (int k = 0; k < 16; k = k + 1) begin
          itlb_q[k].valid <= 1'b0;
          dtlb_q[k].valid <= 1'b0;
        end
      end

      case (state_q)
        S_IDLE: begin
          if (lsu_req_i) begin
            if (!en_ld_st_translation_i) begin
              lsu_valid_o     <= 1'b1;
              lsu_paddr_o     <= lsu_vaddr_i[55:0];
              lsu_exc_cause_o <= 64'd0;
              lsu_exc_tval_o  <= 64'd0;
            end else if (dtlb_hit) begin
              lsu_valid_o <= 1'b1;
              if (dtlb_hit_fault) begin
                lsu_paddr_o      <= 56'd0;
                lsu_exc_valid_o  <= 1'b1;
                lsu_exc_cause_o  <= lsu_is_store_i ? 64'd15 : 64'd13;
                lsu_exc_tval_o   <= lsu_vaddr_i;
              end else begin
                lsu_paddr_o      <= dtlb_hit_pa;
                lsu_exc_cause_o  <= 64'd0;
                lsu_exc_tval_o   <= 64'd0;
              end
            end else begin
              state_q         <= S_REQ;
              walk_is_fetch_q <= 1'b0;
              walk_is_store_q <= lsu_is_store_i;
              walk_vaddr_q    <= lsu_vaddr_i;
              walk_priv_q     <= ld_st_priv_lvl_i;
              walk_sum_q      <= sum_i;
              walk_mxr_q      <= mxr_i;
              walk_asid_q     <= asid_i;
              walk_root_q     <= satp_ppn_i;
              walk_a_q        <= {satp_ppn_i, 12'b0};
              walk_level_q    <= 2'd2;
            end
          end else if (fetch_req_i) begin
            if (!enable_translation_i) begin
              fetch_valid_o     <= 1'b1;
              fetch_paddr_o     <= fetch_vaddr_i[55:0];
              fetch_exc_cause_o <= 64'd0;
              fetch_exc_tval_o  <= 64'd0;
            end else if (itlb_hit) begin
              fetch_valid_o <= 1'b1;
              if (itlb_hit_fault) begin
                fetch_paddr_o      <= 56'd0;
                fetch_exc_valid_o  <= 1'b1;
                fetch_exc_cause_o  <= 64'd12;
                fetch_exc_tval_o   <= fetch_vaddr_i;
              end else begin
                fetch_paddr_o      <= itlb_hit_pa;
                fetch_exc_cause_o  <= 64'd0;
                fetch_exc_tval_o   <= 64'd0;
              end
            end else begin
              state_q         <= S_REQ;
              walk_is_fetch_q <= 1'b1;
              walk_is_store_q <= 1'b0;
              walk_vaddr_q    <= fetch_vaddr_i;
              walk_priv_q     <= priv_lvl_i;
              walk_sum_q      <= sum_i;
              walk_mxr_q      <= mxr_i;
              walk_asid_q     <= asid_i;
              walk_root_q     <= satp_ppn_i;
              walk_a_q        <= {satp_ppn_i, 12'b0};
              walk_level_q    <= 2'd2;
            end
          end
        end

        S_REQ: begin
          if (flush_i) begin
            // If the current read was granted but has not responded, drain it
            // before restarting so its response cannot be mistaken for a new
            // level's response.
            walk_a_q      <= {walk_root_q, 12'b0};
            walk_level_q  <= 2'd2;
            if (pmp_read_allow && mem_gnt_i && !mem_rvalid_i)
              state_q <= S_ABORT;
            else
              state_q <= S_REQ;
          end else if (!pmp_read_allow) begin
            state_q <= S_IDLE;
            if (walk_is_fetch_q) begin
              fetch_valid_o      <= 1'b1;
              fetch_paddr_o      <= 56'd0;
              fetch_exc_valid_o  <= 1'b1;
              fetch_exc_cause_o  <= 64'd1;
              fetch_exc_tval_o   <= walk_vaddr_q;
            end else begin
              lsu_valid_o      <= 1'b1;
              lsu_paddr_o      <= 56'd0;
              lsu_exc_valid_o  <= 1'b1;
              lsu_exc_cause_o  <= walk_is_store_q ? 64'd7 : 64'd5;
              lsu_exc_tval_o   <= walk_vaddr_q;
            end
          end else if (mem_gnt_i) begin
            if (mem_rvalid_i) begin
              walk_pte_q <= mem_rdata_i;
              state_q    <= S_PROC;
            end else begin
              state_q <= S_WAIT;
            end
          end
        end

        S_WAIT, S_PROC: begin
          if (flush_i) begin
            walk_a_q     <= {walk_root_q, 12'b0};
            walk_level_q <= 2'd2;
            state_q      <= S_REQ;
          end else if ((state_q == S_PROC) || mem_rvalid_i) begin
            if (walk_pte_fault) begin
              state_q <= S_IDLE;
              if (walk_is_fetch_q) begin
                fetch_valid_o      <= 1'b1;
                fetch_paddr_o      <= 56'd0;
                fetch_exc_valid_o  <= 1'b1;
                fetch_exc_cause_o  <= 64'd12;
                fetch_exc_tval_o   <= walk_vaddr_q;
              end else begin
                lsu_valid_o      <= 1'b1;
                lsu_paddr_o      <= 56'd0;
                lsu_exc_valid_o  <= 1'b1;
                lsu_exc_cause_o  <= walk_is_store_q ? 64'd15 : 64'd13;
                lsu_exc_tval_o   <= walk_vaddr_q;
              end
            end else if (walk_pte_leaf) begin
              state_q <= S_IDLE;
              if (walk_is_fetch_q) begin
                fetch_valid_o     <= 1'b1;
                fetch_paddr_o     <= walk_success_pa;
                fetch_exc_cause_o <= 64'd0;
                fetch_exc_tval_o  <= 64'd0;

                itlb_q[itlb_victim].valid <= 1'b1;
                itlb_q[itlb_victim].g     <= walk_pte[5];
                itlb_q[itlb_victim].asid  <= walk_asid_q;
                itlb_q[itlb_victim].vpn   <= walk_vaddr_q[38:12];
                itlb_q[itlb_victim].ppn   <= walk_pte[53:10];
                itlb_q[itlb_victim].level <= walk_level_q;
                itlb_q[itlb_victim].r     <= walk_pte[1];
                itlb_q[itlb_victim].w     <= walk_pte[2];
                itlb_q[itlb_victim].x     <= walk_pte[3];
                itlb_q[itlb_victim].u     <= walk_pte[4];
                itlb_q[itlb_victim].d     <= walk_pte[7];
                itlb_rr_q                 <= itlb_victim + 4'd1;
              end else begin
                lsu_valid_o     <= 1'b1;
                lsu_paddr_o     <= walk_success_pa;
                lsu_exc_cause_o <= 64'd0;
                lsu_exc_tval_o  <= 64'd0;

                dtlb_q[dtlb_victim].valid <= 1'b1;
                dtlb_q[dtlb_victim].g     <= walk_pte[5];
                dtlb_q[dtlb_victim].asid  <= walk_asid_q;
                dtlb_q[dtlb_victim].vpn   <= walk_vaddr_q[38:12];
                dtlb_q[dtlb_victim].ppn   <= walk_pte[53:10];
                dtlb_q[dtlb_victim].level <= walk_level_q;
                dtlb_q[dtlb_victim].r     <= walk_pte[1];
                dtlb_q[dtlb_victim].w     <= walk_pte[2];
                dtlb_q[dtlb_victim].x     <= walk_pte[3];
                dtlb_q[dtlb_victim].u     <= walk_pte[4];
                dtlb_q[dtlb_victim].d     <= walk_pte[7];
                dtlb_rr_q                 <= dtlb_victim + 4'd1;
              end
            end else begin
              walk_a_q     <= {walk_pte[53:10], 12'b0};
              walk_level_q <= walk_level_q - 2'd1;
              state_q      <= S_REQ;
            end
          end
        end

        S_ABORT: begin
          if (mem_rvalid_i) begin
            walk_a_q     <= {walk_root_q, 12'b0};
            walk_level_q <= 2'd2;
            state_q      <= S_REQ;
          end
        end

        default: state_q <= S_IDLE;
      endcase
    end
  end

endmodule
