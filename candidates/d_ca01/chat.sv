module nonblocking_dcache #(
  parameter int unsigned DATA_W     = 32,
  parameter int unsigned SETS       = 16,
  parameter int unsigned WAYS       = 4,
  parameter int unsigned MAX_MISSES = 8
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
  localparam int unsigned BYTE_W      = DATA_W / 8;
  localparam int unsigned WORD_OFF_W  = $clog2(BYTE_W);
  localparam int unsigned BLOCK_BYTES = BLOCK_WORDS * BYTE_W;
  localparam int unsigned BLOCK_OFF_W = $clog2(BLOCK_BYTES);
  localparam int unsigned SET_W       = $clog2(SETS);
  localparam int unsigned TAG_W       = 32 - BLOCK_OFF_W - SET_W;
  localparam int unsigned WAY_IDX_W   = (WAYS > 1) ? $clog2(WAYS) : 1;
  localparam int unsigned MISS_IDX_W  =
      (MAX_MISSES > 1) ? $clog2(MAX_MISSES) : 1;

  typedef enum logic [2:0] {
    S_IDLE,
    S_WB_REQ,
    S_WB_DATA,
    S_FILL_REQ,
    S_FILL_DATA
  } state_t;

  logic                      line_valid_q
      [0:SETS-1][0:WAYS-1];
  logic                      line_dirty_q
      [0:SETS-1][0:WAYS-1];
  logic [TAG_W-1:0]          line_tag_q
      [0:SETS-1][0:WAYS-1];
  logic [DATA_W-1:0]         line_data_q
      [0:SETS-1][0:WAYS-1][0:BLOCK_WORDS-1];
  logic [WAY_IDX_W-1:0]      repl_q
      [0:SETS-1];

  logic                      miss_valid_q
      [0:MAX_MISSES-1];
  logic [31:0]               miss_block_q
      [0:MAX_MISSES-1];
  logic [3:0]                miss_id_q
      [0:MAX_MISSES-1];
  logic                      miss_op_q
      [0:MAX_MISSES-1];
  logic [1:0]                miss_word_q
      [0:MAX_MISSES-1];
  logic [DATA_W-1:0]         miss_store_data_q
      [0:MAX_MISSES-1];
  logic [BYTE_W-1:0]         miss_store_mask_q
      [0:MAX_MISSES-1];

  logic [MISS_IDX_W-1:0]     miss_rr_q;

  state_t                    state_q;

  logic [MISS_IDX_W-1:0]     svc_miss_idx_q;
  logic [SET_W-1:0]          svc_set_q;
  logic [WAY_IDX_W-1:0]      svc_way_q;
  logic [31:0]               svc_victim_addr_q;
  logic [1:0]                wb_beat_q;
  logic [1:0]                fill_beat_q;
  logic [DATA_W-1:0]         svc_load_word_q;

  /*
   * Completed responses are stored by request ID.  Because R6 guarantees
   * that two requests with the same ID are never simultaneously in flight,
   * each ID needs at most one completed response slot.
   */
  logic [15:0]               rsp_pending_valid_q;
  logic [DATA_W-1:0]         rsp_pending_data_q [0:15];

  logic [3:0]                rsp_rr_q;

  logic                      rsp_hold_valid_q;
  logic [3:0]                rsp_hold_id_q;
  logic [DATA_W-1:0]         rsp_hold_data_q;

  logic [31:0]               req_block_addr;
  logic [SET_W-1:0]          req_set;
  logic [TAG_W-1:0]          req_tag;
  logic [1:0]                req_word;

  logic                      req_hit_found;
  logic [WAY_IDX_W-1:0]      req_hit_way;

  logic                      req_pending_same_line;

  logic                      free_miss_found;
  logic [MISS_IDX_W-1:0]     free_miss_idx;

  logic                      miss_pick_found;
  logic [MISS_IDX_W-1:0]     miss_pick_idx;

  logic [SET_W-1:0]          start_set;
  logic [WAY_IDX_W-1:0]      start_way;
  logic                      start_victim_valid;
  logic                      start_victim_dirty;
  logic [31:0]               start_victim_addr;

  logic                      service_needs_start;

  logic                      rsp_pick_found;
  logic [3:0]                rsp_pick_idx;

  function automatic logic [DATA_W-1:0] apply_mask(
    input logic [DATA_W-1:0] old_word,
    input logic [DATA_W-1:0] new_word,
    input logic [BYTE_W-1:0] byte_mask
  );
    integer b;

    begin
      apply_mask = old_word;

      for (b = 0; b < BYTE_W; b = b + 1) begin
        if (byte_mask[b]) begin
          apply_mask[b*8 +: 8] =
              new_word[b*8 +: 8];
        end
      end
    end
  endfunction

  /*
   * Address decomposition.
   */
  always_comb begin : p_req_decode
    req_block_addr = {
      req_addr_i[31:BLOCK_OFF_W],
      {BLOCK_OFF_W{1'b0}}
    };

    req_set  =
        req_addr_i[BLOCK_OFF_W +: SET_W];

    req_tag  =
        req_addr_i[31 -: TAG_W];

    req_word =
        req_addr_i[WORD_OFF_W +: 2];
  end

  /*
   * Cache lookup, pending-line detection and free miss entry search.
   *
   * A request to a line which already has a miss outstanding is held at
   * the input until that line completes.  This gives simple and strict
   * ordering for requests to the same word without requiring an
   * unbounded merge queue.
   */
  always_comb begin : p_req_lookup
    integer w;
    integer m;

    req_hit_found         = 1'b0;
    req_hit_way           = '0;
    req_pending_same_line = 1'b0;

    free_miss_found       = 1'b0;
    free_miss_idx         = '0;

    for (w = 0; w < WAYS; w = w + 1) begin
      if ((!req_hit_found) &&
          line_valid_q[req_set][w] &&
          (line_tag_q[req_set][w] == req_tag)) begin

        req_hit_found = 1'b1;
        req_hit_way   = w;
      end
    end

    for (m = 0; m < MAX_MISSES; m = m + 1) begin
      if (miss_valid_q[m] &&
          (miss_block_q[m] == req_block_addr)) begin
        req_pending_same_line = 1'b1;
      end

      if ((!free_miss_found) &&
          (!miss_valid_q[m])) begin
        free_miss_found = 1'b1;
        free_miss_idx   = m;
      end
    end
  end

  /*
   * Round-robin miss scheduler.
   *
   * Service priority rotates after every selected miss.  This matters for
   * C3: continuously arriving requests must not be able to keep recycling
   * low-numbered miss entries while starving older high-numbered entries.
   */
  always_comb begin : p_miss_pick
    integer k;
    integer idx;

    miss_pick_found = 1'b0;
    miss_pick_idx   = '0;
    idx             = 0;

    for (k = 0; k < MAX_MISSES; k = k + 1) begin
      idx = miss_rr_q + k;

      if (idx >= MAX_MISSES) begin
        idx = idx - MAX_MISSES;
      end

      if ((!miss_pick_found) &&
          miss_valid_q[idx]) begin
        miss_pick_found = 1'b1;
        miss_pick_idx   = idx;
      end
    end
  end

  /*
   * Select a cache way only when a queued miss actually begins service.
   *
   * Delaying victim selection is important: MAX_MISSES can be larger than
   * WAYS, and all outstanding misses are allowed to map to the same set.
   * Reserving a way at initial miss acceptance would therefore incorrectly
   * limit the number of misses which could be tracked.
   *
   * Invalid ways are preferred.  Once a set is full, a simple round-robin
   * replacement pointer is used.
   */
  always_comb begin : p_victim_pick
    integer w;
    logic invalid_found;

    start_set          = '0;
    start_way          = '0;
    start_victim_valid = 1'b0;
    start_victim_dirty = 1'b0;
    start_victim_addr  = 32'b0;
    invalid_found      = 1'b0;

    if (miss_pick_found) begin
      start_set =
          miss_block_q[miss_pick_idx]
              [BLOCK_OFF_W +: SET_W];

      start_way = repl_q[start_set];

      for (w = 0; w < WAYS; w = w + 1) begin
        if ((!invalid_found) &&
            (!line_valid_q[start_set][w])) begin
          invalid_found = 1'b1;
          start_way     = w;
        end
      end

      start_victim_valid =
          line_valid_q[start_set][start_way];

      start_victim_dirty =
          line_dirty_q[start_set][start_way];

      if (line_valid_q[start_set][start_way]) begin
        start_victim_addr = {
          line_tag_q[start_set][start_way],
          start_set,
          {BLOCK_OFF_W{1'b0}}
        };
      end
    end
  end

  /*
   * Round-robin arbitration among completed responses.
   */
  always_comb begin : p_rsp_pick
    integer k;
    integer idx;

    rsp_pick_found = 1'b0;
    rsp_pick_idx   = 4'b0;
    idx            = 0;

    for (k = 0; k < 16; k = k + 1) begin
      idx = rsp_rr_q + k;

      if (idx >= 16) begin
        idx = idx - 16;
      end

      if ((!rsp_pick_found) &&
          rsp_pending_valid_q[idx]) begin
        rsp_pick_found = 1'b1;
        rsp_pick_idx   = idx;
      end
    end
  end

  /*
   * Request acceptance.
   *
   * Hits do not require a free miss entry, so a full miss table does not
   * block hit-under-miss.
   *
   * When the memory engine is idle with a queued miss, one cycle is reserved
   * to choose and invalidate its victim.  This prevents a same-cycle cache hit
   * from modifying the victim after the writeback decision was made.
   */
  always_comb begin : p_req_ready
    service_needs_start =
        (state_q == S_IDLE) &&
        miss_pick_found;

    req_ready_o = 1'b0;

    if (rst_ni &&
        (!service_needs_start)) begin

      if (req_pending_same_line) begin
        req_ready_o = 1'b0;
      end
      else if (req_hit_found) begin
        req_ready_o = 1'b1;
      end
      else if (free_miss_found) begin
        req_ready_o = 1'b1;
      end
    end
  end

  /*
   * Registered/held response interface.
   *
   * Once valid is asserted, ID and data remain unchanged until transfer.
   */
  always_comb begin : p_rsp_outputs
    rsp_valid_o = rsp_hold_valid_q;
    rsp_id_o    = rsp_hold_id_q;
    rsp_data_o  = rsp_hold_data_q;
  end

  /*
   * Single-transaction memory interface.
   */
  always_comb begin : p_mem_outputs
    mem_req_valid_o = 1'b0;
    mem_req_we_o    = 1'b0;
    mem_req_addr_o  = 32'b0;

    mem_rd_ready_o  = 1'b0;

    mem_wr_valid_o  = 1'b0;
    mem_wr_data_o   = '0;

    case (state_q)
      S_WB_REQ: begin
        mem_req_valid_o = 1'b1;
        mem_req_we_o    = 1'b1;
        mem_req_addr_o  = svc_victim_addr_q;
      end

      S_WB_DATA: begin
        mem_wr_valid_o = 1'b1;

        /*
         * The victim way remains invalid until the writeback is complete,
         * so its data can be streamed directly out of the cache array.
         * No extra whole-line writeback buffer is needed.
         */
        mem_wr_data_o =
            line_data_q
                [svc_set_q]
                [svc_way_q]
                [wb_beat_q];
      end

      S_FILL_REQ: begin
        mem_req_valid_o = 1'b1;
        mem_req_we_o    = 1'b0;

        mem_req_addr_o =
            miss_block_q[svc_miss_idx_q];
      end

      S_FILL_DATA: begin
        mem_rd_ready_o = 1'b1;
      end

      default: begin
      end
    endcase
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin : p_seq
    integer s;
    integer w;
    integer m;
    integer r;

    if (!rst_ni) begin
      state_q           <= S_IDLE;
      svc_miss_idx_q    <= '0;
      svc_set_q         <= '0;
      svc_way_q         <= '0;
      svc_victim_addr_q <= 32'b0;
      wb_beat_q         <= 2'b0;
      fill_beat_q       <= 2'b0;
      svc_load_word_q   <= '0;

      miss_rr_q         <= '0;

      rsp_pending_valid_q <= 16'b0;
      rsp_rr_q            <= 4'b0;

      rsp_hold_valid_q    <= 1'b0;
      rsp_hold_id_q       <= 4'b0;
      rsp_hold_data_q     <= '0;

      /*
       * Only tag validity is architecturally required for the power-up
       * condition, but clearing the associated control state as well keeps
       * simulation deterministic.
       */
      for (s = 0; s < SETS; s = s + 1) begin
        repl_q[s] <= '0;

        for (w = 0; w < WAYS; w = w + 1) begin
          line_valid_q[s][w] <= 1'b0;
          line_dirty_q[s][w] <= 1'b0;
          line_tag_q[s][w]   <= '0;
        end
      end

      for (m = 0; m < MAX_MISSES; m = m + 1) begin
        miss_valid_q[m]      <= 1'b0;
        miss_block_q[m]      <= 32'b0;
        miss_id_q[m]         <= 4'b0;
        miss_op_q[m]         <= 1'b0;
        miss_word_q[m]       <= 2'b0;
        miss_store_data_q[m] <= '0;
        miss_store_mask_q[m] <= '0;
      end

      for (r = 0; r < 16; r = r + 1) begin
        rsp_pending_data_q[r] <= '0;
      end
    end
    else begin

      /*
       * ------------------------------------------------------------------
       * Response retirement
       * ------------------------------------------------------------------
       */
      if (rsp_hold_valid_q &&
          rsp_ready_i) begin
        rsp_hold_valid_q <= 1'b0;
      end

      /*
       * If the output register is empty, or its current response is being
       * consumed on this edge, install the next completed response.
       */
      if (((!rsp_hold_valid_q) ||
           rsp_ready_i) &&
          rsp_pick_found) begin

        rsp_hold_valid_q <= 1'b1;

        rsp_hold_id_q <=
            rsp_pick_idx;

        rsp_hold_data_q <=
            rsp_pending_data_q[rsp_pick_idx];

        rsp_pending_valid_q[rsp_pick_idx] <=
            1'b0;

        rsp_rr_q <=
            rsp_pick_idx + 4'd1;
      end

      /*
       * ------------------------------------------------------------------
       * CPU request acceptance
       * ------------------------------------------------------------------
       */
      if (req_valid_i &&
          req_ready_o) begin

        if (req_hit_found) begin

          /*
           * A hit completes immediately into the response holding structure;
           * it does not wait for any outstanding miss.
           */
          rsp_pending_valid_q[req_id_i] <=
              1'b1;

          if (req_op_i) begin
            line_data_q
                [req_set]
                [req_hit_way]
                [req_word]
              <= apply_mask(
                   line_data_q
                       [req_set]
                       [req_hit_way]
                       [req_word],
                   req_data_i,
                   req_mask_i
                 );

            if (|req_mask_i) begin
              line_dirty_q
                  [req_set]
                  [req_hit_way]
                <= 1'b1;
            end

            /*
             * STORE response data is unconstrained.
             */
            rsp_pending_data_q[req_id_i] <=
                '0;
          end
          else begin
            rsp_pending_data_q[req_id_i] <=
                line_data_q
                    [req_set]
                    [req_hit_way]
                    [req_word];
          end
        end
        else begin

          /*
           * A distinct-line miss consumes only metadata plus the one
           * permitted merged-store word/mask.
           *
           * Victim selection is deliberately deferred until service time.
           */
          miss_valid_q[free_miss_idx] <=
              1'b1;

          miss_block_q[free_miss_idx] <=
              req_block_addr;

          miss_id_q[free_miss_idx] <=
              req_id_i;

          miss_op_q[free_miss_idx] <=
              req_op_i;

          miss_word_q[free_miss_idx] <=
              req_word;

          miss_store_data_q[free_miss_idx] <=
              req_data_i;

          miss_store_mask_q[free_miss_idx] <=
              req_mask_i;
        end
      end

      /*
       * ------------------------------------------------------------------
       * Memory service engine
       * ------------------------------------------------------------------
       */
      case (state_q)

        /*
         * Pick an outstanding miss and reserve a victim.
         */
        S_IDLE: begin
          if (miss_pick_found) begin
            svc_miss_idx_q <=
                miss_pick_idx;

            svc_set_q <=
                start_set;

            svc_way_q <=
                start_way;

            svc_victim_addr_q <=
                start_victim_addr;

            /*
             * Rotate miss priority immediately.  The selected entry remains
             * valid until its fill actually completes.
             */
            miss_rr_q <=
                miss_pick_idx + 1'b1;

            /*
             * Once selected for replacement, the victim is no longer a
             * resident cache hit.  Its data remains untouched so a dirty
             * line can be streamed directly to memory.
             */
            line_valid_q[start_set][start_way] <=
                1'b0;

            line_dirty_q[start_set][start_way] <=
                1'b0;

            if (start_victim_valid &&
                start_victim_dirty) begin
              state_q <= S_WB_REQ;
            end
            else begin
              state_q <= S_FILL_REQ;
            end
          end
        end

        /*
         * Dirty victim transaction request.
         */
        S_WB_REQ: begin
          if (mem_req_valid_o &&
              mem_req_ready_i) begin
            wb_beat_q <= 2'b0;
            state_q   <= S_WB_DATA;
          end
        end

        /*
         * Exactly four ascending writeback beats.
         */
        S_WB_DATA: begin
          if (mem_wr_valid_o &&
              mem_wr_ready_i) begin

            if (wb_beat_q == 2'd3) begin
              state_q <= S_FILL_REQ;
            end
            else begin
              wb_beat_q <=
                  wb_beat_q + 2'd1;
            end
          end
        end

        /*
         * Fill transaction request.
         */
        S_FILL_REQ: begin
          if (mem_req_valid_o &&
              mem_req_ready_i) begin
            fill_beat_q     <= 2'b0;
            svc_load_word_q <= '0;
            state_q         <= S_FILL_DATA;
          end
        end

        /*
         * Exactly four ascending fill beats.
         *
         * Beats are written directly into the invalid reserved cache way,
         * avoiding a per-miss block buffer.
         */
        S_FILL_DATA: begin
          if (mem_rd_valid_i &&
              mem_rd_ready_o) begin

            /*
             * STORE miss: merge the pending store into its addressed word as
             * that fill word arrives.
             */
            if (miss_op_q[svc_miss_idx_q] &&
                (fill_beat_q ==
                 miss_word_q[svc_miss_idx_q])) begin

              line_data_q
                  [svc_set_q]
                  [svc_way_q]
                  [fill_beat_q]
                <= apply_mask(
                     mem_rd_data_i,
                     miss_store_data_q[svc_miss_idx_q],
                     miss_store_mask_q[svc_miss_idx_q]
                   );
            end
            else begin
              line_data_q
                  [svc_set_q]
                  [svc_way_q]
                  [fill_beat_q]
                <= mem_rd_data_i;
            end

            /*
             * LOAD miss: retain only the requested word until the entire line
             * has arrived.  The line is not made valid early.
             */
            if ((!miss_op_q[svc_miss_idx_q]) &&
                (fill_beat_q ==
                 miss_word_q[svc_miss_idx_q])) begin

              svc_load_word_q <=
                  mem_rd_data_i;
            end

            if (fill_beat_q == 2'd3) begin

              /*
               * The complete block has landed; only now expose the cache line.
               */
              line_tag_q
                  [svc_set_q]
                  [svc_way_q]
                <= miss_block_q
                       [svc_miss_idx_q]
                       [31 -: TAG_W];

              line_valid_q
                  [svc_set_q]
                  [svc_way_q]
                <= 1'b1;

              if (miss_op_q[svc_miss_idx_q] &&
                  (|miss_store_mask_q[svc_miss_idx_q])) begin
                line_dirty_q
                    [svc_set_q]
                    [svc_way_q]
                  <= 1'b1;
              end
              else begin
                line_dirty_q
                    [svc_set_q]
                    [svc_way_q]
                  <= 1'b0;
              end

              repl_q[svc_set_q] <=
                  svc_way_q + 1'b1;

              /*
               * Produce the response belonging to the original miss request.
               */
              rsp_pending_valid_q
                  [miss_id_q[svc_miss_idx_q]]
                <= 1'b1;

              if (miss_op_q[svc_miss_idx_q]) begin
                /*
                 * STORE response data is unconstrained.
                 */
                rsp_pending_data_q
                    [miss_id_q[svc_miss_idx_q]]
                  <= '0;
              end
              else if (miss_word_q[svc_miss_idx_q] ==
                       2'd3) begin
                /*
                 * Requested word is the final beat, so use the current input
                 * rather than the old svc_load_word_q value.
                 */
                rsp_pending_data_q
                    [miss_id_q[svc_miss_idx_q]]
                  <= mem_rd_data_i;
              end
              else begin
                rsp_pending_data_q
                    [miss_id_q[svc_miss_idx_q]]
                  <= svc_load_word_q;
              end

              /*
               * The miss is no longer outstanding once its complete line has
               * arrived and its response has been made ready.
               */
              miss_valid_q[svc_miss_idx_q] <=
                  1'b0;

              state_q <=
                  S_IDLE;
            end
            else begin
              fill_beat_q <=
                  fill_beat_q + 2'd1;
            end
          end
        end

        default: begin
          state_q <= S_IDLE;
        end
      endcase
    end
  end

endmodule