module nonblocking_dcache #(
  parameter int unsigned DATA_W      = 32,
  parameter int unsigned SETS        = 16,
  parameter int unsigned WAYS        = 4,
  parameter int unsigned MAX_MISSES  = 8
) (
  input  logic                     clk_i,
  input  logic                     rst_ni,

  input  logic                     req_valid_i,
  output logic                     req_ready_o,
  input  logic [3:0]               req_id_i,
  input  logic                     req_op_i,
  input  logic [31:0]              req_addr_i,
  input  logic [DATA_W-1:0]        req_data_i,
  input  logic [(DATA_W/8)-1:0]    req_mask_i,

  output logic                     rsp_valid_o,
  input  logic                     rsp_ready_i,
  output logic [3:0]               rsp_id_o,
  output logic [DATA_W-1:0]        rsp_data_o,

  output logic                     mem_req_valid_o,
  input  logic                     mem_req_ready_i,
  output logic                     mem_req_we_o,
  output logic [31:0]              mem_req_addr_o,

  input  logic                     mem_rd_valid_i,
  output logic                     mem_rd_ready_o,
  input  logic [DATA_W-1:0]        mem_rd_data_i,

  output logic                     mem_wr_valid_o,
  input  logic                     mem_wr_ready_i,
  output logic [DATA_W-1:0]        mem_wr_data_o
);

  localparam int unsigned BLOCK_WORDS = 4;
  localparam int unsigned NUM_IDS     = 16;
  localparam int unsigned DATA_BYTES  = DATA_W / 8;
  localparam int unsigned BYTE_OFF_W  = $clog2(DATA_BYTES);
  localparam int unsigned WORD_IDX_W  = 2;
  localparam int unsigned BLOCK_OFF_W = BYTE_OFF_W + WORD_IDX_W;
  localparam int unsigned SET_W       = $clog2(SETS);
  localparam int unsigned WAY_W       = $clog2(WAYS);
  localparam int unsigned TAG_W       = 32 - BLOCK_OFF_W - SET_W;
  localparam logic        MAX_MISSES_LEGAL =
    (MAX_MISSES == 2) || (MAX_MISSES == 8);

  localparam logic [2:0] MEM_IDLE      = 3'd0;
  localparam logic [2:0] MEM_WB_REQ    = 3'd1;
  localparam logic [2:0] MEM_WB_DATA   = 3'd2;
  localparam logic [2:0] MEM_FILL_REQ  = 3'd3;
  localparam logic [2:0] MEM_FILL_DATA = 3'd4;

  // Cache arrays.
  logic [SETS-1:0][WAYS-1:0]                         cache_valid_q;
  logic [SETS-1:0][WAYS-1:0]                         cache_dirty_q;
  logic [SETS-1:0][WAYS-1:0][TAG_W-1:0]             cache_tag_q;
  logic [SETS-1:0][WAYS-1:0][BLOCK_WORDS-1:0]
        [DATA_W-1:0]                                 cache_data_q;
  logic [SETS-1:0][WAY_W-1:0]                       repl_way_q;

  // One request slot per architecturally unique ID. IDs are guaranteed not to
  // be reused while in flight, so the ID itself is a natural slot index.
  logic [NUM_IDS-1:0]                                req_active_q;
  logic [NUM_IDS-1:0]                                req_done_q;
  logic [NUM_IDS-1:0]                                req_op_q;
  logic [NUM_IDS-1:0][31:0]                         req_addr_q;
  logic [NUM_IDS-1:0][DATA_W-1:0]                   req_data_q;
  logic [NUM_IDS-1:0][DATA_BYTES-1:0]               req_mask_q;
  logic [NUM_IDS-1:0][NUM_IDS-1:0]                  req_dep_q;
  logic [NUM_IDS-1:0][DATA_W-1:0]                   req_rsp_data_q;

  // Fair request scheduler.
  logic [3:0]                                        sched_rr_q;
  logic                                              sched_sel_valid_c;
  logic [3:0]                                        sched_sel_id_c;
  logic                                              sched_sel_hit_c;
  logic [WAY_W-1:0]                                 sched_sel_way_c;
  logic [SET_W-1:0]                                 sched_set_c;
  logic [1:0]                                        sched_word_c;
  logic                                              sched_complete_c;
  logic                                              sched_start_miss_c;

  // Victim selection for a newly started miss.
  logic [WAY_W-1:0]                                 victim_way_c;
  logic                                              victim_invalid_found_c;

  // Lower-memory state. Only the currently serviced miss owns block buffers.
  logic [2:0]                                        mem_state_q;
  logic [1:0]                                        mem_beat_q;
  logic [31:0]                                       miss_line_addr_q;
  logic [SET_W-1:0]                                 miss_set_q;
  logic [TAG_W-1:0]                                 miss_tag_q;
  logic [WAY_W-1:0]                                 miss_way_q;
  logic [3:0]                                        miss_req_id_q;
  logic [31:0]                                       wb_line_addr_q;
  logic [BLOCK_WORDS-1:0][DATA_W-1:0]               wb_buf_q;
  logic [BLOCK_WORDS-1:0][DATA_W-1:0]               fill_buf_q;
  logic                                              fill_complete_c;

  // Stable response holding register.
  logic                                              rsp_hold_valid_q;
  logic [3:0]                                        rsp_hold_id_q;
  logic [DATA_W-1:0]                                rsp_hold_data_q;
  logic [3:0]                                        rsp_rr_q;
  logic                                              rsp_pick_valid_c;
  logic [3:0]                                        rsp_pick_id_c;

  // Request acceptance helpers.
  logic                                              store_line_conflict_c;
  logic [NUM_IDS-1:0]                                accept_dep_c;
  logic                                              req_fire_c;

  function automatic logic [31:0] block_addr(input logic [31:0] addr);
    begin
      block_addr = (addr >> BLOCK_OFF_W) << BLOCK_OFF_W;
    end
  endfunction

  function automatic logic [SET_W-1:0] addr_set(input logic [31:0] addr);
    begin
      addr_set = addr[BLOCK_OFF_W +: SET_W];
    end
  endfunction

  function automatic logic [1:0] addr_word(input logic [31:0] addr);
    begin
      addr_word = addr[BYTE_OFF_W +: WORD_IDX_W];
    end
  endfunction

  function automatic logic [TAG_W-1:0] addr_tag(input logic [31:0] addr);
    begin
      addr_tag = addr[31 -: TAG_W];
    end
  endfunction

  function automatic logic [DATA_W-1:0] merge_bytes(
    input logic [DATA_W-1:0]      old_data,
    input logic [DATA_W-1:0]      new_data,
    input logic [DATA_BYTES-1:0]  byte_mask
  );
    integer bi;
    logic [DATA_W-1:0] merged;
    begin
      merged = old_data;
      for (bi = 0; bi < DATA_BYTES; bi = bi + 1) begin
        if (byte_mask[bi]) begin
          merged[bi*8 +: 8] = new_data[bi*8 +: 8];
        end
      end
      merge_bytes = merged;
    end
  endfunction

  // --------------------------------------------------------------------------
  // Fair request scheduler. One pending ID is probed per cycle. If lower
  // memory is busy and that request misses, the round-robin pointer simply
  // advances and another request is probed next cycle. Thus hits are found and
  // answered underneath an arbitrarily long miss without replicating sixteen
  // complete tag-lookup datapaths.
  // --------------------------------------------------------------------------
  always_comb begin : p_sched
    integer cw;
    integer si;
    integer sidx;

    sched_sel_valid_c = 1'b0;
    sched_sel_id_c    = 4'd0;
    sched_sel_hit_c   = 1'b0;
    sched_sel_way_c   = '0;

    for (si = 0; si < NUM_IDS; si = si + 1) begin
      sidx = (sched_rr_q + si) & 15;
      if (!sched_sel_valid_c &&
          req_active_q[sidx] &&
          !req_done_q[sidx] &&
          (req_dep_q[sidx] == '0)) begin
        sched_sel_valid_c = 1'b1;
        sched_sel_id_c    = sidx[3:0];
      end
    end

    sched_set_c  = addr_set(req_addr_q[sched_sel_id_c]);
    sched_word_c = addr_word(req_addr_q[sched_sel_id_c]);

    for (cw = 0; cw < WAYS; cw = cw + 1) begin
      if (sched_sel_valid_c && !sched_sel_hit_c &&
          cache_valid_q[sched_set_c][cw] &&
          (cache_tag_q[sched_set_c][cw] ==
           addr_tag(req_addr_q[sched_sel_id_c]))) begin
        sched_sel_hit_c = 1'b1;
        sched_sel_way_c = cw[WAY_W-1:0];
      end
    end

    sched_complete_c   = sched_sel_valid_c && sched_sel_hit_c;
    sched_start_miss_c = sched_sel_valid_c && !sched_sel_hit_c &&
                         (mem_state_q == MEM_IDLE);
  end

  // --------------------------------------------------------------------------
  // Round-robin victim, preferring an invalid way.
  // --------------------------------------------------------------------------
  always_comb begin : p_victim
    integer vw;

    victim_way_c           = repl_way_q[sched_set_c];
    victim_invalid_found_c = 1'b0;

    for (vw = 0; vw < WAYS; vw = vw + 1) begin
      if (!victim_invalid_found_c && !cache_valid_q[sched_set_c][vw]) begin
        victim_way_c           = vw[WAY_W-1:0];
        victim_invalid_found_c = 1'b1;
      end
    end
  end

  // --------------------------------------------------------------------------
  // Accept logic and same-word ordering dependencies.
  // A second pending store to the same cache line is conservatively stalled;
  // this bounds merged-store buffering to one word per pending line miss.
  // --------------------------------------------------------------------------
  always_comb begin : p_accept
    integer ai;

    store_line_conflict_c = 1'b0;
    if (req_valid_i && req_op_i) begin
      for (ai = 0; ai < NUM_IDS; ai = ai + 1) begin
        if (req_active_q[ai] && !req_done_q[ai] && req_op_q[ai] &&
            (block_addr(req_addr_q[ai]) == block_addr(req_addr_i))) begin
          store_line_conflict_c = 1'b1;
        end
      end
    end

    req_ready_o = MAX_MISSES_LEGAL && !req_active_q[req_id_i] &&
                  !store_line_conflict_c;
    req_fire_c  = req_valid_i && req_ready_o;

    accept_dep_c = '0;
    for (ai = 0; ai < NUM_IDS; ai = ai + 1) begin
      if (req_active_q[ai] && !req_done_q[ai] &&
          (req_addr_q[ai][31:BYTE_OFF_W] == req_addr_i[31:BYTE_OFF_W]) &&
          !(sched_complete_c && (sched_sel_id_c == ai[3:0])) &&
          !(fill_complete_c && (miss_req_id_q == ai[3:0]))) begin
        accept_dep_c[ai] = 1'b1;
      end
    end
  end

  // --------------------------------------------------------------------------
  // Response arbitration. Once a response is presented it is held unchanged
  // until accepted. Selection itself is independent of rsp_ready_i.
  // --------------------------------------------------------------------------
  always_comb begin : p_rsp_pick
    integer ri;
    integer ridx;

    rsp_pick_valid_c = 1'b0;
    rsp_pick_id_c    = 4'd0;

    for (ri = 0; ri < NUM_IDS; ri = ri + 1) begin
      ridx = (rsp_rr_q + ri) & 15;
      if (!rsp_pick_valid_c && req_active_q[ridx] && req_done_q[ridx] &&
          !(rsp_hold_valid_q && (rsp_hold_id_q == ridx[3:0]))) begin
        rsp_pick_valid_c = 1'b1;
        rsp_pick_id_c    = ridx[3:0];
      end
    end
  end

  assign rsp_valid_o = rsp_hold_valid_q;
  assign rsp_id_o    = rsp_hold_id_q;
  assign rsp_data_o  = rsp_hold_data_q;

  // --------------------------------------------------------------------------
  // Lower-memory interface. Requests and data remain stable under backpressure.
  // --------------------------------------------------------------------------
  always_comb begin
    mem_req_valid_o = 1'b0;
    mem_req_we_o    = 1'b0;
    mem_req_addr_o  = 32'd0;
    mem_rd_ready_o  = 1'b0;
    mem_wr_valid_o  = 1'b0;
    mem_wr_data_o   = '0;

    case (mem_state_q)
      MEM_WB_REQ: begin
        mem_req_valid_o = 1'b1;
        mem_req_we_o    = 1'b1;
        mem_req_addr_o  = wb_line_addr_q;
      end

      MEM_WB_DATA: begin
        mem_wr_valid_o = 1'b1;
        mem_wr_data_o  = wb_buf_q[mem_beat_q];
      end

      MEM_FILL_REQ: begin
        mem_req_valid_o = 1'b1;
        mem_req_we_o    = 1'b0;
        mem_req_addr_o  = miss_line_addr_q;
      end

      MEM_FILL_DATA: begin
        mem_rd_ready_o = 1'b1;
      end

      default: begin
      end
    endcase
  end

  assign fill_complete_c = (mem_state_q == MEM_FILL_DATA) &&
                           mem_rd_valid_i && mem_rd_ready_o &&
                           (mem_beat_q == 2'd3);

  // MAX_MISSES is intentionally not used to size block-data storage. The 16
  // architecturally unique IDs provide metadata capacity for every legal value
  // of MAX_MISSES, while M3 permits only one lower-memory transaction at once.
  // --------------------------------------------------------------------------
  // State updates.
  // --------------------------------------------------------------------------
  always_ff @(posedge clk_i or negedge rst_ni) begin : p_state
    integer qd;
    integer mw;

    if (!rst_ni) begin
      cache_valid_q    <= '0;
      cache_dirty_q    <= '0;
      repl_way_q       <= '0;

      req_active_q     <= '0;
      req_done_q       <= '0;
      req_op_q         <= '0;
      req_addr_q       <= '0;
      req_data_q       <= '0;
      req_mask_q       <= '0;
      req_dep_q        <= '0;
      req_rsp_data_q   <= '0;

      sched_rr_q       <= 4'd0;

      mem_state_q      <= MEM_IDLE;
      mem_beat_q       <= 2'd0;
      miss_line_addr_q <= 32'd0;
      miss_set_q       <= '0;
      miss_tag_q       <= '0;
      miss_way_q       <= '0;
      miss_req_id_q    <= 4'd0;
      wb_line_addr_q   <= 32'd0;
      wb_buf_q         <= '0;
      fill_buf_q       <= '0;

      rsp_hold_valid_q <= 1'b0;
      rsp_hold_id_q    <= 4'd0;
      rsp_hold_data_q  <= '0;
      rsp_rr_q         <= 4'd0;
    end
    else begin
      // Probe fairness advances even when the probed request is a miss that
      // cannot start because a lower-memory transaction is already active.
      if (sched_sel_valid_c) begin
        sched_rr_q <= sched_sel_id_c + 4'd1;
      end

      // Retire an accepted response.
      if (rsp_hold_valid_q && rsp_ready_i) begin
        req_active_q[rsp_hold_id_q] <= 1'b0;
        req_done_q[rsp_hold_id_q]   <= 1'b0;
        req_dep_q[rsp_hold_id_q]    <= '0;
        rsp_hold_valid_q            <= 1'b0;
      end

      // Load the response holding register when empty, or refill it on the same
      // edge that the previous response is accepted.
      if ((!rsp_hold_valid_q || rsp_ready_i) && rsp_pick_valid_c) begin
        rsp_hold_valid_q <= 1'b1;
        rsp_hold_id_q    <= rsp_pick_id_c;
        rsp_hold_data_q  <= req_rsp_data_q[rsp_pick_id_c];
        rsp_rr_q         <= rsp_pick_id_c + 4'd1;
      end

      // Complete a resident hit.
      if (sched_complete_c) begin
        req_done_q[sched_sel_id_c] <= 1'b1;

        if (req_op_q[sched_sel_id_c]) begin
          cache_data_q[sched_set_c][sched_sel_way_c][sched_word_c] <=
            merge_bytes(
              cache_data_q[sched_set_c][sched_sel_way_c][sched_word_c],
              req_data_q[sched_sel_id_c],
              req_mask_q[sched_sel_id_c]
            );
          cache_dirty_q[sched_set_c][sched_sel_way_c] <= 1'b1;
          req_rsp_data_q[sched_sel_id_c] <= '0;
        end
        else begin
          req_rsp_data_q[sched_sel_id_c] <=
            cache_data_q[sched_set_c][sched_sel_way_c][sched_word_c];
        end

        for (qd = 0; qd < NUM_IDS; qd = qd + 1) begin
          req_dep_q[qd][sched_sel_id_c] <= 1'b0;
        end
      end

      // Start servicing one miss. The chosen victim is invalidated immediately;
      // if dirty, its block is first copied to the single writeback buffer.
      if (sched_start_miss_c) begin
        miss_line_addr_q <= block_addr(req_addr_q[sched_sel_id_c]);
        miss_set_q       <= sched_set_c;
        miss_tag_q       <= addr_tag(req_addr_q[sched_sel_id_c]);
        miss_way_q       <= victim_way_c;
        miss_req_id_q    <= sched_sel_id_c;
        mem_beat_q       <= 2'd0;

        if (cache_valid_q[sched_set_c][victim_way_c] &&
            cache_dirty_q[sched_set_c][victim_way_c]) begin
          wb_line_addr_q <= {
            cache_tag_q[sched_set_c][victim_way_c],
            sched_set_c,
            {BLOCK_OFF_W{1'b0}}
          };

          for (mw = 0; mw < BLOCK_WORDS; mw = mw + 1) begin
            wb_buf_q[mw] <= cache_data_q[sched_set_c][victim_way_c][mw];
          end

          mem_state_q <= MEM_WB_REQ;
        end
        else begin
          mem_state_q <= MEM_FILL_REQ;
        end

        cache_valid_q[sched_set_c][victim_way_c] <= 1'b0;
        cache_dirty_q[sched_set_c][victim_way_c] <= 1'b0;
      end

      // Lower-memory transaction sequencing.
      case (mem_state_q)
        MEM_IDLE: begin
        end

        MEM_WB_REQ: begin
          if (mem_req_valid_o && mem_req_ready_i) begin
            mem_beat_q  <= 2'd0;
            mem_state_q <= MEM_WB_DATA;
          end
        end

        MEM_WB_DATA: begin
          if (mem_wr_valid_o && mem_wr_ready_i) begin
            if (mem_beat_q == 2'd3) begin
              mem_beat_q  <= 2'd0;
              mem_state_q <= MEM_FILL_REQ;
            end
            else begin
              mem_beat_q <= mem_beat_q + 2'd1;
            end
          end
        end

        MEM_FILL_REQ: begin
          if (mem_req_valid_o && mem_req_ready_i) begin
            mem_beat_q  <= 2'd0;
            mem_state_q <= MEM_FILL_DATA;
          end
        end

        MEM_FILL_DATA: begin
          if (mem_rd_valid_i && mem_rd_ready_o) begin
            fill_buf_q[mem_beat_q] <= mem_rd_data_i;

            if (mem_beat_q == 2'd3) begin
              // Install the completed line in ascending-word order. The final
              // beat is used directly because its nonblocking write to
              // fill_buf_q is not visible until after this edge.
              for (mw = 0; mw < BLOCK_WORDS-1; mw = mw + 1) begin
                cache_data_q[miss_set_q][miss_way_q][mw] <= fill_buf_q[mw];
              end

              cache_data_q[miss_set_q][miss_way_q][BLOCK_WORDS-1] <=
                mem_rd_data_i;

              // The request that caused the fill completes on this edge. A
              // store miss modifies the freshly filled word before the line is
              // made visible as dirty; a load miss returns the requested beat.
              if (req_op_q[miss_req_id_q]) begin
                if (addr_word(req_addr_q[miss_req_id_q]) == 2'd3) begin
                  cache_data_q[miss_set_q][miss_way_q][3] <=
                    merge_bytes(
                      mem_rd_data_i,
                      req_data_q[miss_req_id_q],
                      req_mask_q[miss_req_id_q]
                    );
                end
                else begin
                  cache_data_q[miss_set_q][miss_way_q]
                              [addr_word(req_addr_q[miss_req_id_q])] <=
                    merge_bytes(
                      fill_buf_q[addr_word(req_addr_q[miss_req_id_q])],
                      req_data_q[miss_req_id_q],
                      req_mask_q[miss_req_id_q]
                    );
                end

                cache_dirty_q[miss_set_q][miss_way_q] <= 1'b1;
                req_rsp_data_q[miss_req_id_q]         <= '0;
              end
              else begin
                cache_dirty_q[miss_set_q][miss_way_q] <= 1'b0;

                if (addr_word(req_addr_q[miss_req_id_q]) == 2'd3) begin
                  req_rsp_data_q[miss_req_id_q] <= mem_rd_data_i;
                end
                else begin
                  req_rsp_data_q[miss_req_id_q] <=
                    fill_buf_q[addr_word(req_addr_q[miss_req_id_q])];
                end
              end

              cache_tag_q[miss_set_q][miss_way_q]   <= miss_tag_q;
              cache_valid_q[miss_set_q][miss_way_q] <= 1'b1;
              repl_way_q[miss_set_q]                <= miss_way_q + 1'b1;
              req_done_q[miss_req_id_q]             <= 1'b1;

              for (qd = 0; qd < NUM_IDS; qd = qd + 1) begin
                req_dep_q[qd][miss_req_id_q] <= 1'b0;
              end

              mem_beat_q  <= 2'd0;
              mem_state_q <= MEM_IDLE;
            end
            else begin
              mem_beat_q <= mem_beat_q + 2'd1;
            end
          end
        end

        default: begin
          mem_state_q <= MEM_IDLE;
        end
      endcase

      // Accept a new request after completion-column clears above. The computed
      // dependency mask already excludes operations completing on this edge.
      if (req_fire_c) begin
        req_active_q[req_id_i]   <= 1'b1;
        req_done_q[req_id_i]     <= 1'b0;
        req_op_q[req_id_i]       <= req_op_i;
        req_addr_q[req_id_i]     <= req_addr_i;
        req_data_q[req_id_i]     <= req_data_i;
        req_mask_q[req_id_i]     <= req_mask_i;
        req_dep_q[req_id_i]      <= accept_dep_c;
        req_rsp_data_q[req_id_i] <= '0;
      end
    end
  end

endmodule