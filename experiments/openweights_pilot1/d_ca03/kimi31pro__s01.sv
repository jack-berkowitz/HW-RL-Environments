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

  // TLB flags use the original PTE bit positions:
  // [1]=R, [2]=W, [3]=X, [4]=U, [5]=G, [6]=A, [7]=D.
  logic [15:0]   itlb_valid_q, dtlb_valid_q;
  logic [26:0]   itlb_vpn_q   [0:15];
  logic [26:0]   dtlb_vpn_q   [0:15];
  logic [43:0]   itlb_ppn_q   [0:15];
  logic [43:0]   dtlb_ppn_q   [0:15];
  logic [15:0]   itlb_asid_q  [0:15];
  logic [15:0]   dtlb_asid_q  [0:15];
  logic [1:0]    itlb_level_q [0:15];
  logic [1:0]    dtlb_level_q [0:15];
  logic [7:0]    itlb_flags_q [0:15];
  logic [7:0]    dtlb_flags_q [0:15];

  logic [15:0]   itlb_match, dtlb_match;
  logic [3:0]    itlb_rr_q, dtlb_rr_q;
  logic [3:0]    itlb_victim, dtlb_victim;
  logic          itlb_victim_found, dtlb_victim_found;

  logic          itlb_hit, dtlb_hit;
  logic [43:0]   itlb_sel_ppn, dtlb_sel_ppn;
  logic [1:0]    itlb_sel_level, dtlb_sel_level;
  logic [7:0]    itlb_sel_flags, dtlb_sel_flags;

  typedef enum logic [1:0] {S_IDLE, S_REQ, S_WAIT} state_t;
  state_t state_q;

  logic          active_fetch_q;
  logic          active_store_q;
  logic [63:0]   active_vaddr_q;
  logic [1:0]    active_priv_q;
  logic          active_sum_q;
  logic          active_mxr_q;
  logic [15:0]   active_asid_q;
  logic [43:0]   active_root_q;

  logic [55:0]   walk_base_q;
  logic [1:0]    walk_level_q;
  logic          restart_q;
  logic [55:0]   walk_addr;

  logic          pmp_seen;
  logic          pmp_read_ok;

  logic [43:0]   pte_ppn;
  logic          pte_leaf;
  logic          pte_misaligned;
  logic          pte_permissions_ok;
  logic          pte_page_fault;
  logic [55:0]   walk_paddr;

  logic          walk_rsp;
  logic          walk_final;
  logic          walk_install;
  logic          lsu_need_walk;
  logic          fetch_need_walk;

  integer        li;
  integer        vi;
  integer        pk;

  function automatic logic tlb_vpn_match(
    input logic [26:0] entry_vpn,
    input logic [26:0] request_vpn,
    input logic [1:0]  level
  );
    begin
      case (level)
        2'd2:    tlb_vpn_match = entry_vpn[26:18] == request_vpn[26:18];
        2'd1:    tlb_vpn_match = entry_vpn[26:9]  == request_vpn[26:9];
        default: tlb_vpn_match = entry_vpn        == request_vpn;
      endcase
    end
  endfunction

  function automatic logic [55:0] compose_paddr(
    input logic [43:0] ppn,
    input logic [63:0] vaddr,
    input logic [1:0]  level
  );
    begin
      case (level)
        2'd2:    compose_paddr = {ppn[43:18], vaddr[29:0]};
        2'd1:    compose_paddr = {ppn[43:9],  vaddr[20:0]};
        default: compose_paddr = {ppn,        vaddr[11:0]};
      endcase
    end
  endfunction

  function automatic logic permission_ok(
    input logic       is_fetch,
    input logic       is_store,
    input logic [1:0] priv,
    input logic       sum,
    input logic       mxr,
    input logic       pte_r,
    input logic       pte_w,
    input logic       pte_x,
    input logic       pte_u
  );
    logic access_ok;
    logic priv_ok;
    begin
      if (is_fetch)
        access_ok = pte_x;
      else if (is_store)
        access_ok = pte_w;
      else
        access_ok = pte_r || (pte_x && mxr);

      priv_ok = 1'b1;
      if (priv == 2'b00) begin
        priv_ok = pte_u;
      end else if ((priv == 2'b01) && pte_u) begin
        if (is_fetch)
          priv_ok = 1'b0;
        else if (!sum)
          priv_ok = 1'b0;
      end

      permission_ok = access_ok && priv_ok;
    end
  endfunction

  // Match a complete eight-byte walker read. NAPOT regions are at least
  // eight bytes and naturally aligned, so an aligned eight-byte access can
  // be matched by masking the word address. NA4 cannot contain such a read.
  function automatic logic pmp_region_match(
    input integer       idx,
    input logic [55:0]  addr
  );
    logic [1:0]  mode;
    logic [53:0] region_word;
    logic [53:0] napot_mask;
    logic [56:0] region_lo;
    logic [56:0] region_hi;
    logic [56:0] access_lo;
    logic [56:0] access_hi;
    integer      trailing_ones;
    integer      j;
    begin
      mode          = pmpcfg_i[idx][4:3];
      region_word   = pmpaddr_i[idx];
      napot_mask    = 54'd0;
      region_lo     = 57'd0;
      region_hi     = 57'd0;
      access_lo     = {1'b0, addr};
      access_hi     = {1'b0, addr} + 57'd7;
      trailing_ones = 0;
      pmp_region_match = 1'b0;

      case (mode)
        2'd1: begin // TOR
          if (idx == 0)
            region_lo = 57'd0;
          else
            region_lo = {3'b000, pmpaddr_i[idx-1]} << 2;
          region_hi = {3'b000, region_word} << 2;
          pmp_region_match = (access_lo >= region_lo) &&
                             (access_hi < region_hi);
        end

        2'd2: begin // NA4: smaller than the walker's eight-byte read
          pmp_region_match = 1'b0;
        end

        2'd3: begin // NAPOT
          for (j = 0; j < 54; j = j + 1) begin
            if (region_word[j] && (trailing_ones == j))
              trailing_ones = trailing_ones + 1;
          end
          napot_mask = ~((54'h1 << trailing_ones) - 54'h1);
          pmp_region_match =
            (((region_word ^ addr[55:2]) & napot_mask) == 54'd0);
        end

        default: pmp_region_match = 1'b0;
      endcase
    end
  endfunction

  generate
    for (genvar g = 0; g < 16; g = g + 1) begin : gen_tlb_match
      assign itlb_match[g] =
        itlb_valid_q[g] &&
        (itlb_flags_q[g][5] || (itlb_asid_q[g] == asid_i)) &&
        tlb_vpn_match(itlb_vpn_q[g], fetch_vaddr_i[38:12],
                      itlb_level_q[g]);

      assign dtlb_match[g] =
        dtlb_valid_q[g] &&
        (dtlb_flags_q[g][5] || (dtlb_asid_q[g] == asid_i)) &&
        tlb_vpn_match(dtlb_vpn_q[g], lsu_vaddr_i[38:12],
                      dtlb_level_q[g]);
    end
  endgenerate

  // Parallel fully-associative lookup, with a fixed priority in the
  // impossible-but-harmless case of duplicate matching entries.
  always_comb begin
    itlb_hit       = 1'b0;
    itlb_sel_ppn   = 44'd0;
    itlb_sel_level = 2'd0;
    itlb_sel_flags = 8'd0;
    for (li = 0; li < 16; li = li + 1) begin
      if (!itlb_hit && itlb_match[li]) begin
        itlb_hit       = 1'b1;
        itlb_sel_ppn   = itlb_ppn_q[li];
        itlb_sel_level = itlb_level_q[li];
        itlb_sel_flags = itlb_flags_q[li];
      end
    end
  end

  always_comb begin
    dtlb_hit       = 1'b0;
    dtlb_sel_ppn   = 44'd0;
    dtlb_sel_level = 2'd0;
    dtlb_sel_flags = 8'd0;
    for (li = 0; li < 16; li = li + 1) begin
      if (!dtlb_hit && dtlb_match[li]) begin
        dtlb_hit       = 1'b1;
        dtlb_sel_ppn   = dtlb_ppn_q[li];
        dtlb_sel_level = dtlb_level_q[li];
        dtlb_sel_flags = dtlb_flags_q[li];
      end
    end
  end

  // Prefer invalid entries, then use round-robin replacement. This spreads
  // cold fills over all sixteen entries and makes flushing a one-cycle operation.
  always_comb begin
    itlb_victim       = itlb_rr_q;
    itlb_victim_found = 1'b0;
    for (vi = 0; vi < 16; vi = vi + 1) begin
      if (!itlb_victim_found && !itlb_valid_q[vi]) begin
        itlb_victim       = vi[3:0];
        itlb_victim_found = 1'b1;
      end
    end
  end

  always_comb begin
    dtlb_victim       = dtlb_rr_q;
    dtlb_victim_found = 1'b0;
    for (vi = 0; vi < 16; vi = vi + 1) begin
      if (!dtlb_victim_found && !dtlb_valid_q[vi]) begin
        dtlb_victim       = vi[3:0];
        dtlb_victim_found = 1'b1;
      end
    end
  end

  always_comb begin
    walk_addr = walk_base_q;
    case (walk_level_q)
      2'd2: walk_addr = walk_base_q +
                        {{44{1'b0}}, active_vaddr_q[38:30], 3'b000};
      2'd1: walk_addr = walk_base_q +
                        {{44{1'b0}}, active_vaddr_q[29:21], 3'b000};
      default: walk_addr = walk_base_q +
                        {{44{1'b0}}, active_vaddr_q[20:12], 3'b000};
    endcase
  end

  // Lowest-numbered matching PMP entry wins. No match denies the read.
  always_comb begin
    pmp_seen    = 1'b0;
    pmp_read_ok = 1'b0;
    for (pk = 0; pk < 8; pk = pk + 1) begin
      if (!pmp_seen && pmp_region_match(pk, walk_addr)) begin
        pmp_seen    = 1'b1;
        pmp_read_ok = pmpcfg_i[pk][0];
      end
    end
  end

  always_comb begin
    pte_ppn        = mem_rdata_i[53:10];
    pte_leaf       = mem_rdata_i[1] || mem_rdata_i[3];
    pte_misaligned = 1'b0;

    if ((walk_level_q == 2'd1) && (pte_ppn[8:0] != 9'd0))
      pte_misaligned = 1'b1;
    if ((walk_level_q == 2'd2) && (pte_ppn[17:0] != 18'd0))
      pte_misaligned = 1'b1;

    pte_permissions_ok = permission_ok(
      active_fetch_q,
      active_store_q,
      active_priv_q,
      active_sum_q,
      active_mxr_q,
      mem_rdata_i[1],
      mem_rdata_i[2],
      mem_rdata_i[3],
      mem_rdata_i[4]
    );

    pte_page_fault = !mem_rdata_i[0] ||
                     (mem_rdata_i[2] && !mem_rdata_i[1]);

    if (pte_leaf) begin
      if (pte_misaligned || !pte_permissions_ok || !mem_rdata_i[6] ||
          (active_store_q && !mem_rdata_i[7]))
        pte_page_fault = 1'b1;
    end else if (walk_level_q == 2'd0) begin
      pte_page_fault = 1'b1;
    end

    walk_paddr = compose_paddr(pte_ppn, active_vaddr_q, walk_level_q);
  end

  // A response arriving alongside the grant is accepted as well as the usual
  // delayed response. Responses belonging to an aborted walk are drained.
  assign walk_rsp = !flush_i &&
    (((state_q == S_WAIT) && mem_rvalid_i && !restart_q) ||
     ((state_q == S_REQ) && pmp_read_ok && mem_gnt_i && mem_rvalid_i));

  assign walk_final   = pte_page_fault || pte_leaf;
  assign walk_install = walk_rsp && pte_leaf && !pte_page_fault &&
                        !flush_tlb_i;

  assign lsu_need_walk = rst_ni && (state_q == S_IDLE) && lsu_req_i &&
                         en_ld_st_translation_i &&
                         (!dtlb_hit || flush_tlb_i);

  assign fetch_need_walk = rst_ni && (state_q == S_IDLE) && fetch_req_i &&
                           enable_translation_i &&
                           (!itlb_hit || flush_tlb_i);

  assign mem_req_o = rst_ni && (state_q == S_REQ) &&
                     pmp_read_ok && !flush_i;
  assign mem_addr_o      = walk_addr;
  assign mem_tag_valid_o = 1'b0;
  assign mem_kill_o      = 1'b0;

  assign lsu_dtlb_hit_o = dtlb_hit;
  assign lsu_dtlb_ppn_o = dtlb_sel_ppn;
  assign itlb_miss_o = fetch_req_i && enable_translation_i && !itlb_hit;
  assign dtlb_miss_o = lsu_req_i && en_ld_st_translation_i && !dtlb_hit;

  // Retirement, including same-cycle retirement for bare accesses and TLB hits.
  always_comb begin
    lsu_valid_o       = 1'b0;
    lsu_paddr_o       = 56'd0;
    lsu_exc_valid_o   = 1'b0;
    lsu_exc_cause_o   = 64'd0;
    lsu_exc_tval_o    = 64'd0;

    fetch_valid_o     = 1'b0;
    fetch_paddr_o     = 56'd0;
    fetch_exc_valid_o = 1'b0;
    fetch_exc_cause_o = 64'd0;
    fetch_exc_tval_o  = 64'd0;

    if (rst_ni) begin
      if (state_q == S_IDLE) begin
        if (lsu_req_i) begin
          if (!en_ld_st_translation_i) begin
            lsu_valid_o = 1'b1;
            lsu_paddr_o = lsu_vaddr_i[55:0];
          end else if (dtlb_hit && !flush_tlb_i) begin
            lsu_valid_o = 1'b1;
            lsu_paddr_o = compose_paddr(
              dtlb_sel_ppn, lsu_vaddr_i, dtlb_sel_level
            );

            if (!permission_ok(
                  1'b0, lsu_is_store_i, ld_st_priv_lvl_i,
                  sum_i, mxr_i,
                  dtlb_sel_flags[1], dtlb_sel_flags[2],
                  dtlb_sel_flags[3], dtlb_sel_flags[4]) ||
                !dtlb_sel_flags[6] ||
                (lsu_is_store_i && !dtlb_sel_flags[7])) begin
              lsu_exc_valid_o = 1'b1;
              lsu_exc_cause_o = lsu_is_store_i ? 64'd15 : 64'd13;
              lsu_exc_tval_o  = lsu_vaddr_i;
            end
          end
        end

        if (fetch_req_i) begin
          if (!enable_translation_i) begin
            fetch_valid_o = 1'b1;
            fetch_paddr_o = fetch_vaddr_i[55:0];
          end else if (itlb_hit && !flush_tlb_i) begin
            fetch_valid_o = 1'b1;
            fetch_paddr_o = compose_paddr(
              itlb_sel_ppn, fetch_vaddr_i, itlb_sel_level
            );

            if (!permission_ok(
                  1'b1, 1'b0, priv_lvl_i, sum_i, mxr_i,
                  itlb_sel_flags[1], itlb_sel_flags[2],
                  itlb_sel_flags[3], itlb_sel_flags[4]) ||
                !itlb_sel_flags[6]) begin
              fetch_exc_valid_o = 1'b1;
              fetch_exc_cause_o = 64'd12;
              fetch_exc_tval_o  = fetch_vaddr_i;
            end
          end
        end
      end else begin
        // PMP rejection precedes interpretation of any returned PTE.
        if ((state_q == S_REQ) && !pmp_read_ok && !flush_i) begin
          if (active_fetch_q) begin
            fetch_valid_o     = 1'b1;
            fetch_exc_valid_o = 1'b1;
            fetch_exc_cause_o = 64'd1;
            fetch_exc_tval_o  = active_vaddr_q;
          end else begin
            lsu_valid_o       = 1'b1;
            lsu_exc_valid_o   = 1'b1;
            lsu_exc_cause_o   = active_store_q ? 64'd7 : 64'd5;
            lsu_exc_tval_o    = active_vaddr_q;
          end
        end else if (walk_rsp && walk_final) begin
          if (active_fetch_q) begin
            fetch_valid_o = 1'b1;
            if (pte_page_fault) begin
              fetch_exc_valid_o = 1'b1;
              fetch_exc_cause_o = 64'd12;
              fetch_exc_tval_o  = active_vaddr_q;
            end else begin
              fetch_paddr_o = walk_paddr;
            end
          end else begin
            lsu_valid_o = 1'b1;
            if (pte_page_fault) begin
              lsu_exc_valid_o = 1'b1;
              lsu_exc_cause_o = active_store_q ? 64'd15 : 64'd13;
              lsu_exc_tval_o  = active_vaddr_q;
            end else begin
              lsu_paddr_o = walk_paddr;
            end
          end
        end
      end
    end
  end

  always_ff @(posedge clk_i) begin
    if (!rst_ni) begin
      state_q         <= S_IDLE;
      itlb_valid_q    <= 16'd0;
      dtlb_valid_q    <= 16'd0;
      itlb_rr_q       <= 4'd0;
      dtlb_rr_q       <= 4'd0;
      active_fetch_q  <= 1'b0;
      active_store_q  <= 1'b0;
      active_vaddr_q  <= 64'd0;
      active_priv_q   <= 2'd0;
      active_sum_q    <= 1'b0;
      active_mxr_q    <= 1'b0;
      active_asid_q   <= 16'd0;
      active_root_q   <= 44'd0;
      walk_base_q     <= 56'd0;
      walk_level_q    <= 2'd2;
      restart_q       <= 1'b0;
    end else begin
      if (flush_tlb_i) begin
        itlb_valid_q <= 16'd0;
        dtlb_valid_q <= 16'd0;
        itlb_rr_q    <= 4'd0;
        dtlb_rr_q    <= 4'd0;
      end

      if (walk_install) begin
        if (active_fetch_q) begin
          itlb_valid_q[itlb_victim] <= 1'b1;
          itlb_vpn_q[itlb_victim]   <= active_vaddr_q[38:12];
          itlb_ppn_q[itlb_victim]   <= pte_ppn;
          itlb_asid_q[itlb_victim]  <= active_asid_q;
          itlb_level_q[itlb_victim] <= walk_level_q;
          itlb_flags_q[itlb_victim] <= mem_rdata_i[7:0];
          itlb_rr_q                 <= itlb_victim + 4'd1;
        end else begin
          dtlb_valid_q[dtlb_victim] <= 1'b1;
          dtlb_vpn_q[dtlb_victim]   <= active_vaddr_q[38:12];
          dtlb_ppn_q[dtlb_victim]   <= pte_ppn;
          dtlb_asid_q[dtlb_victim]  <= active_asid_q;
          dtlb_level_q[dtlb_victim] <= walk_level_q;
          dtlb_flags_q[dtlb_victim] <= mem_rdata_i[7:0];
          dtlb_rr_q                 <= dtlb_victim + 4'd1;
        end
      end

      case (state_q)
        S_IDLE: begin
          restart_q <= 1'b0;
          if (lsu_need_walk) begin
            active_fetch_q <= 1'b0;
            active_store_q <= lsu_is_store_i;
            active_vaddr_q <= lsu_vaddr_i;
            active_priv_q  <= ld_st_priv_lvl_i;
            active_sum_q   <= sum_i;
            active_mxr_q   <= mxr_i;
            active_asid_q  <= asid_i;
            active_root_q  <= satp_ppn_i;
            walk_base_q    <= {satp_ppn_i, 12'b0};
            walk_level_q   <= 2'd2;
            state_q        <= S_REQ;
          end else if (fetch_need_walk) begin
            active_fetch_q <= 1'b1;
            active_store_q <= 1'b0;
            active_vaddr_q <= fetch_vaddr_i;
            active_priv_q  <= priv_lvl_i;
            active_sum_q   <= sum_i;
            active_mxr_q   <= mxr_i;
            active_asid_q  <= asid_i;
            active_root_q  <= satp_ppn_i;
            walk_base_q    <= {satp_ppn_i, 12'b0};
            walk_level_q   <= 2'd2;
            state_q        <= S_REQ;
          end
        end

        S_REQ: begin
          if (flush_i) begin
            // No read is outstanding in this state; restart immediately.
            walk_base_q  <= {active_root_q, 12'b0};
            walk_level_q <= 2'd2;
            restart_q    <= 1'b0;
            state_q      <= S_REQ;
          end else if (!pmp_read_ok) begin
            state_q <= S_IDLE;
          end else if (mem_gnt_i) begin
            if (mem_rvalid_i) begin
              if (walk_final) begin
                state_q <= S_IDLE;
              end else begin
                walk_base_q  <= {pte_ppn, 12'b0};
                walk_level_q <= walk_level_q - 2'd1;
                state_q      <= S_REQ;
              end
            end else begin
              state_q <= S_WAIT;
            end
          end
        end

        default: begin // S_WAIT
          if (flush_i) begin
            restart_q <= 1'b1;
            if (mem_rvalid_i) begin
              walk_base_q  <= {active_root_q, 12'b0};
              walk_level_q <= 2'd2;
              restart_q    <= 1'b0;
              state_q      <= S_REQ;
            end
          end else if (mem_rvalid_i) begin
            if (restart_q) begin
              // Discard the aborted walk's response before issuing new reads.
              walk_base_q  <= {active_root_q, 12'b0};
              walk_level_q <= 2'd2;
              restart_q    <= 1'b0;
              state_q      <= S_REQ;
            end else if (walk_final) begin
              state_q <= S_IDLE;
            end else begin
              walk_base_q  <= {pte_ppn, 12'b0};
              walk_level_q <= walk_level_q - 2'd1;
              state_q      <= S_REQ;
            end
          end
        end
      endcase
    end
  end

  // Narrowed flush inputs are intentionally unused: every flush is a full flush.
  logic unused_flush_narrowing;
  assign unused_flush_narrowing = ^{asid_to_be_flushed_i,
                                    vaddr_to_be_flushed_i};

endmodule
