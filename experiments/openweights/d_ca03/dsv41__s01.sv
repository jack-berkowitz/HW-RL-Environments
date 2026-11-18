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
  // TLB storage: 16 fully-associative entries each side, exact 4 KiB VPN tags.
  // ---------------------------------------------------------------------------
  logic [15:0] itlb_valid, dtlb_valid;
  logic [15:0] itlb_global, dtlb_global;
  logic [15:0] itlb_r, itlb_w, itlb_x, itlb_u, itlb_a, itlb_d;
  logic [15:0] dtlb_r, dtlb_w, dtlb_x, dtlb_u, dtlb_a, dtlb_d;
  logic [15:0][15:0] itlb_asid, dtlb_asid;
  logic [15:0][26:0] itlb_vpn, dtlb_vpn;
  logic [15:0][43:0] itlb_ppn, dtlb_ppn;
  logic [3:0] itlb_rr, dtlb_rr;

  // ---------------------------------------------------------------------------
  // FSM and request latches
  // ---------------------------------------------------------------------------
  localparam logic [2:0] IDLE     = 3'd0;
  localparam logic [2:0] START    = 3'd1;
  localparam logic [2:0] WALK_REQ = 3'd2;
  localparam logic [2:0] WALK_WAIT= 3'd3;
  localparam logic [2:0] DONE     = 3'd4;

  logic [2:0] state;
  logic       hold_lsu, hold_fetch;

  logic       req_is_fetch;
  logic       req_is_store;
  logic [63:0] req_va;
  logic [1:0] req_priv;
  logic       req_sum, req_mxr, req_trans_en;

  logic [55:0] walk_a;
  logic [1:0]  walk_level;
  logic [8:0]  walk_vpn;
  logic [55:0] walk_addr;

  logic [55:0] result_paddr;
  logic        result_exc;
  logic [63:0] result_cause;

  // ---------------------------------------------------------------------------
  // PMP check for walker reads.  Only the R bit matters to the walker.
  // Lowest-numbered matching entry wins.  No match denies.
  // ---------------------------------------------------------------------------
  function automatic logic pmp_allow_read(
    input logic [55:0] addr,
    input logic [7:0][7:0] cfg,
    input logic [7:0][53:0] pmpaddr
  );
    integer i, j;
    logic [55:0] lower, upper, base, size, mask;
    logic [5:0] n;
    logic found;
    logic match;
    logic matched;
    logic allow;
    logic [1:0] mode;
    begin
      matched = 1'b0;
      allow   = 1'b0;

      for (i = 0; i < 8; i = i + 1) begin
        mode  = cfg[i][4:3];
        match = 1'b0;

        if (mode == 2'd1) begin // TOR
          if (i == 0) lower = 56'd0;
          else        lower = {pmpaddr[i-1], 2'b00};
          upper = {pmpaddr[i], 2'b00};
          if (addr >= lower && addr < upper) match = 1'b1;
        end
        else if (mode == 2'd2) begin // NA4
          base = {pmpaddr[i], 2'b00};
          if (addr >= base && addr < base + 56'd4) match = 1'b1;
        end
        else if (mode == 2'd3) begin // NAPOT
          n     = 6'd0;
          found = 1'b0;
          for (j = 0; j < 54; j = j + 1) begin
            if (!found) begin
              if (pmpaddr[i][j] == 1'b0) found = 1'b1;
              else                       n = n + 6'd1;
            end
          end

          if (!found) begin
            match = 1'b1; // all ones: covers the whole address space
          end
          else if (n >= 54) begin
            match = 1'b1;
          end
          else begin
            mask  = (56'd1 << (n + 1)) - 56'd1;
            base  = ({2'b00, pmpaddr[i]} & ~mask) << 2;
            size  = 56'd1 << (n + 2);
            upper = base + size;
            if (addr >= base && addr < upper) match = 1'b1;
          end
        end

        if (match && !matched) begin
          matched = 1'b1;
          allow   = cfg[i][0]; // R bit
        end
      end

      if (!matched) allow = 1'b0;
      return allow;
    end
  endfunction

  // ---------------------------------------------------------------------------
  // Permission / A-D check for a leaf PTE.
  // Returns 1 if the access must fault.
  // ---------------------------------------------------------------------------
  function automatic logic perm_fault(
    input logic is_fetch,
    input logic is_store,
    input logic [1:0] priv,
    input logic sum,
    input logic mxr,
    input logic r,
    input logic w,
    input logic x,
    input logic u,
    input logic a,
    input logic d
  );
    logic fault;
    begin
      fault = 1'b0;

      if (!a)          fault = 1'b1;
      if (w && !r)     fault = 1'b1; // reserved encoding
      if (is_store && !d) fault = 1'b1;

      if (is_fetch) begin
        if (!x) fault = 1'b1;
        if (priv == 2'b00 && !u) fault = 1'b1;
        if (priv == 2'b01 &&  u) fault = 1'b1; // supervisor never executes U pages
      end
      else begin
        if (is_store) begin
          if (!w) fault = 1'b1;
        end
        else begin
          if (!(r || (x && mxr))) fault = 1'b1;
        end

        if (priv == 2'b00 && !u) fault = 1'b1;
        if (priv == 2'b01 && u && !sum) fault = 1'b1;
      end

      return fault;
    end
  endfunction

  // ---------------------------------------------------------------------------
  // TLB lookup
  // ---------------------------------------------------------------------------
  logic       itlb_hit, dtlb_hit;
  logic [3:0] itlb_hit_idx, dtlb_hit_idx;

  always_comb begin
    integer i;
    itlb_hit     = 1'b0;
    itlb_hit_idx = 4'd0;
    dtlb_hit     = 1'b0;
    dtlb_hit_idx = 4'd0;

    for (i = 0; i < 16; i = i + 1) begin
      if (!itlb_hit && !flush_tlb_i && itlb_valid[i] &&
          (itlb_global[i] || itlb_asid[i] == asid_i) &&
          itlb_vpn[i] == req_va[38:12]) begin
        itlb_hit     = 1'b1;
        itlb_hit_idx = i[3:0];
      end

      if (!dtlb_hit && !flush_tlb_i && dtlb_valid[i] &&
          (dtlb_global[i] || dtlb_asid[i] == asid_i) &&
          dtlb_vpn[i] == req_va[38:12]) begin
        dtlb_hit     = 1'b1;
        dtlb_hit_idx = i[3:0];
      end
    end
  end

  // ---------------------------------------------------------------------------
  // Walker address generation
  // ---------------------------------------------------------------------------
  always_comb begin
    case (walk_level)
      2'd2: walk_vpn = req_va[38:30];
      2'd1: walk_vpn = req_va[29:21];
      2'd0: walk_vpn = req_va[20:12];
      default: walk_vpn = 9'd0;
    endcase
  end

  assign walk_addr = walk_a + {44'd0, walk_vpn, 3'b0};

  // ---------------------------------------------------------------------------
  // Memory interface
  // ---------------------------------------------------------------------------
  assign mem_req_o  = (state == WALK_REQ) &&
                      pmp_allow_read(walk_addr, pmpcfg_i, pmpaddr_i);
  assign mem_addr_o = walk_addr;

  assign mem_tag_valid_o = 1'b0;
  assign mem_kill_o      = 1'b0;

  // ---------------------------------------------------------------------------
  // Outputs
  // ---------------------------------------------------------------------------
  assign lsu_valid_o      = (state == DONE) && !req_is_fetch;
  assign lsu_paddr_o      = result_paddr;
  assign lsu_exc_valid_o  = (state == DONE) && !req_is_fetch && result_exc;
  assign lsu_exc_cause_o  = result_cause;
  assign lsu_exc_tval_o   = req_va;

  assign fetch_valid_o     = (state == DONE) && req_is_fetch;
  assign fetch_paddr_o     = result_paddr;
  assign fetch_exc_valid_o = (state == DONE) && req_is_fetch && result_exc;
  assign fetch_exc_cause_o = result_cause;
  assign fetch_exc_tval_o  = req_va;

  assign lsu_dtlb_hit_o = (state == START) && !req_is_fetch && dtlb_hit;
  assign lsu_dtlb_ppn_o = dtlb_hit ? dtlb_ppn[dtlb_hit_idx] : 44'd0;

  assign itlb_miss_o = (state == START) &&  req_is_fetch && !itlb_hit;
  assign dtlb_miss_o = (state == START) && !req_is_fetch && !dtlb_hit;

  // ---------------------------------------------------------------------------
  // Sequential FSM
  // ---------------------------------------------------------------------------
  always_ff @(posedge clk_i or negedge rst_ni) begin
    logic [63:0] pte;
    logic [43:0] ppn;
    logic [55:0] pa;
    logic        fault;
    logic        found_invalid;
    logic [3:0]  victim;
    integer      i;

    if (!rst_ni) begin
      state            <= IDLE;
      hold_lsu         <= 1'b0;
      hold_fetch       <= 1'b0;

      req_is_fetch     <= 1'b0;
      req_is_store     <= 1'b0;
      req_va           <= 64'd0;
      req_priv         <= 2'd0;
      req_sum          <= 1'b0;
      req_mxr          <= 1'b0;
      req_trans_en     <= 1'b0;

      walk_a           <= 56'd0;
      walk_level       <= 2'd0;

      result_paddr     <= 56'd0;
      result_exc       <= 1'b0;
      result_cause     <= 64'd0;

      itlb_valid       <= 16'd0;
      dtlb_valid       <= 16'd0;
      itlb_rr          <= 4'd0;
      dtlb_rr          <= 4'd0;
    end
    else begin
      // Clear held-request markers once the requester drops its request.
      if (!lsu_req_i)   hold_lsu   <= 1'b0;
      if (!fetch_req_i) hold_fetch <= 1'b0;

      case (state)
        IDLE: begin
          if (lsu_req_i && !hold_lsu) begin
            req_is_fetch <= 1'b0;
            req_is_store <= lsu_is_store_i;
            req_va       <= lsu_vaddr_i;
            req_priv     <= ld_st_priv_lvl_i;
            req_sum      <= sum_i;
            req_mxr      <= mxr_i;
            req_trans_en <= en_ld_st_translation_i;
            state        <= START;
          end
          else if (fetch_req_i && !hold_fetch) begin
            req_is_fetch <= 1'b1;
            req_is_store <= 1'b0;
            req_va       <= fetch_vaddr_i;
            req_priv     <= priv_lvl_i;
            req_sum      <= 1'b0;
            req_mxr      <= 1'b0;
            req_trans_en <= enable_translation_i;
            state        <= START;
          end
        end

        START: begin
          if (!req_trans_en) begin
            // BARE mode
            result_paddr <= req_va[55:0];
            result_exc   <= 1'b0;
            result_cause <= 64'd0;
            state        <= DONE;
          end
          else if (req_is_fetch) begin
            if (itlb_hit) begin
              if (perm_fault(1'b1, 1'b0, req_priv, 1'b0, 1'b0,
                             itlb_r[itlb_hit_idx], itlb_w[itlb_hit_idx],
                             itlb_x[itlb_hit_idx], itlb_u[itlb_hit_idx],
                             itlb_a[itlb_hit_idx], itlb_d[itlb_hit_idx])) begin
                result_exc   <= 1'b1;
                result_cause <= 64'd12;
                result_paddr <= 56'd0;
              end
              else begin
                result_exc   <= 1'b0;
                result_cause <= 64'd0;
                result_paddr <= {itlb_ppn[itlb_hit_idx], req_va[11:0]};
              end
              state <= DONE;
            end
            else begin
              walk_a     <= {satp_ppn_i, 12'd0};
              walk_level <= 2'd2;
              state      <= WALK_REQ;
            end
          end
          else begin
            if (dtlb_hit) begin
              if (perm_fault(1'b0, req_is_store, req_priv, req_sum, req_mxr,
                             dtlb_r[dtlb_hit_idx], dtlb_w[dtlb_hit_idx],
                             dtlb_x[dtlb_hit_idx], dtlb_u[dtlb_hit_idx],
                             dtlb_a[dtlb_hit_idx], dtlb_d[dtlb_hit_idx])) begin
                result_exc   <= 1'b1;
                result_cause <= req_is_store ? 64'd15 : 64'd13;
                result_paddr <= 56'd0;
              end
              else begin
                result_exc   <= 1'b0;
                result_cause <= 64'd0;
                result_paddr <= {dtlb_ppn[dtlb_hit_idx], req_va[11:0]};
              end
              state <= DONE;
            end
            else begin
              walk_a     <= {satp_ppn_i, 12'd0};
              walk_level <= 2'd2;
              state      <= WALK_REQ;
            end
          end
        end

        WALK_REQ: begin
          if (flush_i) begin
            // C3: abort in-flight walk and restart it.
            state <= START;
          end
          else if (!pmp_allow_read(walk_addr, pmpcfg_i, pmpaddr_i)) begin
            result_exc   <= 1'b1;
            result_cause <= req_is_fetch ? 64'd1 :
                            (req_is_store ? 64'd7 : 64'd5);
            result_paddr <= 56'd0;
            state        <= DONE;
          end
          else if (mem_gnt_i) begin
            state <= WALK_WAIT;
          end
        end

        WALK_WAIT: begin
          if (flush_i) begin
            // C3: abort in-flight walk and restart it.
            state <= START;
          end
          else if (mem_rvalid_i) begin
            pte = mem_rdata_i;

            if (!pte[0]) begin
              // Invalid PTE
              result_exc   <= 1'b1;
              result_cause <= req_is_fetch ? 64'd12 :
                              (req_is_store ? 64'd15 : 64'd13);
              result_paddr <= 56'd0;
              state        <= DONE;
            end
            else if (pte[2] && !pte[1]) begin
              // W=1, R=0: reserved encoding
              result_exc   <= 1'b1;
              result_cause <= req_is_fetch ? 64'd12 :
                              (req_is_store ? 64'd15 : 64'd13);
              result_paddr <= 56'd0;
              state        <= DONE;
            end
            else if (pte[1] || pte[3]) begin
              // Leaf PTE
              fault = 1'b0;

              // Misaligned superpage check
              if (walk_level == 2'd2 && (pte[53:10] & 18'h3FFFF) != 0)
                fault = 1'b1;
              if (walk_level == 2'd1 && (pte[53:10] & 9'h1FF) != 0)
                fault = 1'b1;

              // Build final PPN
              ppn = pte[53:10];
              if (walk_level == 2'd2)
                ppn[17:0] = req_va[29:12];
              else if (walk_level == 2'd1)
                ppn[8:0] = req_va[20:12];

              pa = {ppn, req_va[11:0]};

              // Permission and A/D checks
              if (perm_fault(req_is_fetch, req_is_store, req_priv,
                             req_sum, req_mxr,
                             pte[1], pte[2], pte[3], pte[4], pte[6], pte[7]))
                fault = 1'b1;

              if (fault) begin
                result_exc   <= 1'b1;
                result_cause <= req_is_fetch ? 64'd12 :
                                (req_is_store ? 64'd15 : 64'd13);
                result_paddr <= 56'd0;
                state        <= DONE;
              end
              else begin
                result_exc   <= 1'b0;
                result_cause <= 64'd0;
                result_paddr <= pa;

                // Install into the appropriate TLB.
                if (req_is_fetch) begin
                  found_invalid = 1'b0;
                  victim        = itlb_rr;
                  for (i = 0; i < 16; i = i + 1) begin
                    if (!itlb_valid[i] && !found_invalid) begin
                      victim        = i[3:0];
                      found_invalid = 1'b1;
                    end
                  end

                  itlb_valid[victim]  <= 1'b1;
                  itlb_vpn[victim]    <= req_va[38:12];
                  itlb_ppn[victim]    <= ppn;
                  itlb_asid[victim]   <= asid_i;
                  itlb_global[victim] <= pte[5];
                  itlb_r[victim]      <= pte[1];
                  itlb_w[victim]      <= pte[2];
                  itlb_x[victim]      <= pte[3];
                  itlb_u[victim]      <= pte[4];
                  itlb_a[victim]      <= pte[6];
                  itlb_d[victim]      <= pte[7];
                  itlb_rr             <= victim + 4'd1;
                end
                else begin
                  found_invalid = 1'b0;
                  victim        = dtlb_rr;
                  for (i = 0; i < 16; i = i + 1) begin
                    if (!dtlb_valid[i] && !found_invalid) begin
                      victim        = i[3:0];
                      found_invalid = 1'b1;
                    end
                  end

                  dtlb_valid[victim]  <= 1'b1;
                  dtlb_vpn[victim]    <= req_va[38:12];
                  dtlb_ppn[victim]    <= ppn;
                  dtlb_asid[victim]   <= asid_i;
                  dtlb_global[victim] <= pte[5];
                  dtlb_r[victim]      <= pte[1];
                  dtlb_w[victim]      <= pte[2];
                  dtlb_x[victim]      <= pte[3];
                  dtlb_u[victim]      <= pte[4];
                  dtlb_a[victim]      <= pte[6];
                  dtlb_d[victim]      <= pte[7];
                  dtlb_rr             <= victim + 4'd1;
                end

                state <= DONE;
              end
            end
            else begin
              // Non-leaf pointer
              if (walk_level == 2'd0) begin
                result_exc   <= 1'b1;
                result_cause <= req_is_fetch ? 64'd12 :
                                (req_is_store ? 64'd15 : 64'd13);
                result_paddr <= 56'd0;
                state        <= DONE;
              end
              else begin
                walk_a     <= {pte[53:10], 12'd0};
                walk_level <= walk_level - 2'd1;
                state      <= WALK_REQ;
              end
            end
          end
        end

        DONE: begin
          if (req_is_fetch) hold_fetch <= 1'b1;
          else              hold_lsu   <= 1'b1;
          state <= IDLE;
        end

        default: state <= IDLE;
      endcase

      // Full TLB flush (C2 allows treating any narrowed flush as a full flush).
      if (flush_tlb_i) begin
        itlb_valid <= 16'd0;
        dtlb_valid <= 16'd0;
        itlb_rr    <= 4'd0;
        dtlb_rr    <= 4'd0;
      end
    end
  end

endmodule
