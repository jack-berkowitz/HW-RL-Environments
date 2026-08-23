module nonblocking_dcache #(
  parameter int unsigned DATA_W      = 32,
  parameter int unsigned SETS        = 16,
  parameter int unsigned WAYS        = 4,
  parameter int unsigned MAX_MISSES  = 8
) (
  input  logic                      clk_i,
  input  logic                      rst_ni,

  input  logic                      req_valid_i,
  output logic                      req_ready_o,
  input  logic [3:0]                req_id_i,
  input  logic                      req_op_i,
  input  logic [31:0]               req_addr_i,
  input  logic [DATA_W-1:0]         req_data_i,
  input  logic [(DATA_W/8)-1:0]     req_mask_i,

  output logic                      rsp_valid_o,
  input  logic                      rsp_ready_i,
  output logic [3:0]                rsp_id_o,
  output logic [DATA_W-1:0]         rsp_data_o,

  output logic                      mem_req_valid_o,
  input  logic                      mem_req_ready_i,
  output logic                      mem_req_we_o,
  output logic [31:0]               mem_req_addr_o,

  input  logic                      mem_rd_valid_i,
  output logic                      mem_rd_ready_o,
  input  logic [DATA_W-1:0]         mem_rd_data_i,

  output logic                      mem_wr_valid_o,
  input  logic                      mem_wr_ready_i,
  output logic [DATA_W-1:0]         mem_wr_data_o
);

  localparam int unsigned BLOCK_WORDS = 4;
  localparam int unsigned BYTE_W      = DATA_W / 8;
  localparam int unsigned BYTE_OFF_W  = $clog2(BYTE_W);
  localparam int unsigned WORD_OFF_W  = $clog2(BLOCK_WORDS);
  localparam int unsigned BLOCK_OFF_W = BYTE_OFF_W + WORD_OFF_W;
  localparam int unsigned SET_W       = $clog2(SETS);
  localparam int unsigned TAG_W       = 32 - BLOCK_OFF_W - SET_W;
  localparam int unsigned WAY_W       = (WAYS <= 1) ? 1 : $clog2(WAYS);
  localparam int unsigned MISS_W      =
      (MAX_MISSES <= 1) ? 1 : $clog2(MAX_MISSES);

  typedef enum logic [2:0] {
    S_IDLE,
    S_WB_REQ,
    S_WB_DATA,
    S_FILL_REQ,
    S_FILL_DATA
  } mem_state_t;

  logic                      valid_array
                                 [0:SETS-1][0:WAYS-1];
  logic                      dirty_array
                                 [0:SETS-1][0:WAYS-1];
  logic [TAG_W-1:0]          tag_array
                                 [0:SETS-1][0:WAYS-1];
  logic [DATA_W-1:0]         data_array
                                 [0:SETS-1][0:WAYS-1]
                                 [0:BLOCK_WORDS-1];

  logic [WAY_W-1:0]          repl_ptr [0:SETS-1];

  /*
   * Outstanding-miss records.
   *
   * No full cache block is kept per miss.  A miss record contains only
   * metadata, plus at most one store word and byte mask.
   */
  logic                      miss_valid
                                 [0:MAX_MISSES-1];
  logic [31:0]               miss_line_addr
                                 [0:MAX_MISSES-1];
  logic [1:0]                miss_word_idx
                                 [0:MAX_MISSES-1];
  logic [3:0]                miss_id
                                 [0:MAX_MISSES-1];
  logic                      miss_op
                                 [0:MAX_MISSES-1];
  logic [DATA_W-1:0]         miss_store_data
                                 [0:MAX_MISSES-1];
  logic [BYTE_W-1:0]         miss_store_mask
                                 [0:MAX_MISSES-1];

  /*
   * The only complete block buffered outside the cache data array.
   */
  logic [DATA_W-1:0]         fill_buf
                                 [0:BLOCK_WORDS-1];

  mem_state_t                mem_state;

  logic [MISS_W-1:0]         active_miss_idx;
  logic [31:0]               active_line_addr;
  logic [SET_W-1:0]          active_set;
  logic [TAG_W-1:0]          active_tag;
  logic [WAY_W-1:0]          active_way;
  logic [31:0]               victim_line_addr;

  logic [1:0]                mem_beat_count;
  logic [MISS_W-1:0]         miss_sched_ptr;

  logic [31:0]               req_line_addr;
  logic [SET_W-1:0]          req_set;
  logic [TAG_W-1:0]          req_tag;
  logic [1:0]                req_word_idx;

  logic                      req_hit;
  logic [WAY_W-1:0]          req_hit_way;

  logic                      duplicate_miss;
  logic                      free_miss_found;
  logic [MISS_W-1:0]         free_miss_idx;
  logic                      any_miss;

  logic                      sched_found;
  logic [MISS_W-1:0]         sched_idx;
  logic [SET_W-1:0]          sched_set;
  logic [TAG_W-1:0]          sched_tag;
  logic [WAY_W-1:0]          sched_way;
  logic                      sched_victim_valid;
  logic                      sched_victim_dirty;
  logic [31:0]               sched_victim_addr;

  logic                      rsp_slot_available;
  logic                      fill_final_present;
  logic                      fill_complete_now;

  function automatic logic [31:0] block_align(
    input logic [31:0] addr
  );
    block_align = {
      addr[31:BLOCK_OFF_W],
      {BLOCK_OFF_W{1'b0}}
    };
  endfunction

  function automatic logic [SET_W-1:0] addr_set(
    input logic [31:0] addr
  );
    addr_set = addr[BLOCK_OFF_W +: SET_W];
  endfunction

  function automatic logic [TAG_W-1:0] addr_tag(
    input logic [31:0] addr
  );
    addr_tag = addr[31 -: TAG_W];
  endfunction

  function automatic logic [1:0] addr_word(
    input logic [31:0] addr
  );
    addr_word = addr[BYTE_OFF_W +: WORD_OFF_W];
  endfunction

  function automatic logic [DATA_W-1:0] merge_word(
    input logic [DATA_W-1:0] old_word,
    input logic [DATA_W-1:0] new_word,
    input logic [BYTE_W-1:0] byte_mask
  );
    integer b;
    begin
      merge_word = old_word;

      for (b = 0; b < BYTE_W; b = b + 1) begin
        if (byte_mask[b]) begin
          merge_word[(8*b) +: 8] =
              new_word[(8*b) +: 8];
        end
      end
    end
  endfunction

  /*
   * Current-request lookup plus free miss-entry search.
   */
  always_comb begin : request_lookup
    integer i;
    integer w;

    req_line_addr = block_align(req_addr_i);
    req_set       = addr_set(req_addr_i);
    req_tag       = addr_tag(req_addr_i);
    req_word_idx  = addr_word(req_addr_i);

    req_hit     = 1'b0;
    req_hit_way = '0;

    for (w = 0; w < WAYS; w = w + 1) begin
      if ((!req_hit) &&
          valid_array[req_set][w] &&
          (tag_array[req_set][w] == req_tag)) begin
        req_hit     = 1'b1;
        req_hit_way = w;
      end
    end

    duplicate_miss  = 1'b0;
    free_miss_found = 1'b0;
    free_miss_idx   = '0;
    any_miss        = 1'b0;

    for (i = 0; i < MAX_MISSES; i = i + 1) begin
      if (miss_valid[i]) begin
        any_miss = 1'b1;

        if (miss_line_addr[i] == req_line_addr) begin
          duplicate_miss = 1'b1;
        end
      end else if (!free_miss_found) begin
        free_miss_found = 1'b1;
        free_miss_idx   = i;
      end
    end
  end

  /*
   * Select the next outstanding miss using a round-robin starting
   * point.  Victim selection prefers an invalid way, otherwise it
   * uses a per-set round-robin replacement pointer.
   */
  always_comb begin : scheduler_lookup
    integer k;
    integer idx;
    integer w;
    logic invalid_found;

    sched_found        = 1'b0;
    sched_idx          = '0;
    sched_set          = '0;
    sched_tag          = '0;
    sched_way          = '0;
    sched_victim_valid = 1'b0;
    sched_victim_dirty = 1'b0;
    sched_victim_addr  = '0;
    invalid_found      = 1'b0;

    for (k = 0; k < MAX_MISSES; k = k + 1) begin
      idx = miss_sched_ptr + k;

      if (idx >= MAX_MISSES) begin
        idx = idx - MAX_MISSES;
      end

      if ((!sched_found) && miss_valid[idx]) begin
        sched_found = 1'b1;
        sched_idx   = idx;
      end
    end

    if (sched_found) begin
      sched_set = addr_set(miss_line_addr[sched_idx]);
      sched_tag = addr_tag(miss_line_addr[sched_idx]);
      sched_way = repl_ptr[sched_set];

      for (w = 0; w < WAYS; w = w + 1) begin
        if ((!invalid_found) &&
            (!valid_array[sched_set][w])) begin
          invalid_found = 1'b1;
          sched_way     = w;
        end
      end

      sched_victim_valid =
          valid_array[sched_set][sched_way];

      sched_victim_dirty =
          valid_array[sched_set][sched_way] &&
          dirty_array[sched_set][sched_way];

      sched_victim_addr = {
        tag_array[sched_set][sched_way],
        sched_set,
        {BLOCK_OFF_W{1'b0}}
      };
    end
  end

  /*
   * External ready/valid controls.
   *
   * The final fill beat is accepted only when a response slot is
   * available, since completing the fill necessarily creates the
   * response for its originating request.
   */
  always_comb begin : interface_control
    rsp_slot_available =
        (!rsp_valid_o) || rsp_ready_i;

    fill_final_present =
        (mem_state == S_FILL_DATA) &&
        (mem_beat_count == (BLOCK_WORDS-1)) &&
        mem_rd_valid_i;

    mem_req_valid_o = 1'b0;
    mem_req_we_o    = 1'b0;
    mem_req_addr_o  = '0;

    mem_rd_ready_o  = 1'b0;

    mem_wr_valid_o  = 1'b0;
    mem_wr_data_o   = '0;

    case (mem_state)

      S_WB_REQ: begin
        mem_req_valid_o = 1'b1;
        mem_req_we_o    = 1'b1;
        mem_req_addr_o  = victim_line_addr;
      end

      S_WB_DATA: begin
        mem_wr_valid_o = 1'b1;
        mem_wr_data_o =
            data_array
              [active_set]
              [active_way]
              [mem_beat_count];
      end

      S_FILL_REQ: begin
        mem_req_valid_o = 1'b1;
        mem_req_we_o    = 1'b0;
        mem_req_addr_o  = active_line_addr;
      end

      S_FILL_DATA: begin
        if (mem_beat_count == (BLOCK_WORDS-1)) begin
          mem_rd_ready_o = rsp_slot_available;
        end else begin
          mem_rd_ready_o = 1'b1;
        end
      end

      default: begin
        mem_req_valid_o = 1'b0;
      end

    endcase

    fill_complete_now =
        fill_final_present && mem_rd_ready_o;

    /*
     * Starting a pending miss from S_IDLE takes priority for one
     * cycle.  This removes an eviction-vs-hit race and guarantees
     * pending misses continue to make progress even under a stream
     * of hits.
     *
     * Otherwise:
     *   - an access to a line already missing waits for that miss;
     *   - a hit requires response-buffer capacity;
     *   - a new miss requires a free miss record.
     */
    req_ready_o = 1'b0;

    if (!fill_complete_now) begin
      if ((mem_state == S_IDLE) && any_miss) begin
        req_ready_o = 1'b0;
      end else if (duplicate_miss) begin
        req_ready_o = 1'b0;
      end else if (req_hit) begin
        req_ready_o = rsp_slot_available;
      end else begin
        req_ready_o = free_miss_found;
      end
    end
  end

  /*
   * Main sequential state.
   */
  always_ff @(posedge clk_i or negedge rst_ni)
  begin : state_update
    integer s;
    integer w;
    integer i;
    integer b;

    if (!rst_ni) begin

      rsp_valid_o <= 1'b0;
      rsp_id_o    <= '0;
      rsp_data_o  <= '0;

      mem_state        <= S_IDLE;
      active_miss_idx  <= '0;
      active_line_addr <= '0;
      active_set       <= '0;
      active_tag       <= '0;
      active_way       <= '0;
      victim_line_addr <= '0;
      mem_beat_count   <= '0;
      miss_sched_ptr   <= '0;

      for (s = 0; s < SETS; s = s + 1) begin
        repl_ptr[s] <= '0;

        for (w = 0; w < WAYS; w = w + 1) begin
          valid_array[s][w] <= 1'b0;
          dirty_array[s][w] <= 1'b0;
        end
      end

      for (i = 0; i < MAX_MISSES; i = i + 1) begin
        miss_valid[i]      <= 1'b0;
        miss_line_addr[i]  <= '0;
        miss_word_idx[i]   <= '0;
        miss_id[i]         <= '0;
        miss_op[i]         <= 1'b0;
        miss_store_data[i] <= '0;
        miss_store_mask[i] <= '0;
      end

      for (b = 0; b < BLOCK_WORDS; b = b + 1) begin
        fill_buf[b] <= '0;
      end

    end else begin

      /*
       * Retire an existing response when accepted.  A newly
       * generated response later in this same clock cycle replaces
       * it, allowing one response per cycle.
       */
      if (rsp_valid_o && rsp_ready_i) begin
        rsp_valid_o <= 1'b0;
      end

      /*
       * CPU request acceptance.
       */
      if (req_valid_i && req_ready_o) begin

        if (req_hit) begin

          rsp_valid_o <= 1'b1;
          rsp_id_o    <= req_id_i;

          if (req_op_i) begin

            /*
             * STORE hit.
             */
            data_array
              [req_set]
              [req_hit_way]
              [req_word_idx]
            <= merge_word(
                 data_array
                   [req_set]
                   [req_hit_way]
                   [req_word_idx],
                 req_data_i,
                 req_mask_i
               );

            dirty_array
              [req_set]
              [req_hit_way]
            <= 1'b1;

            /*
             * Store response data is unconstrained.
             */
            rsp_data_o <= '0;

          end else begin

            /*
             * LOAD hit.
             */
            rsp_data_o <=
                data_array
                  [req_set]
                  [req_hit_way]
                  [req_word_idx];

          end

        end else begin

          /*
           * New distinct-line miss.  Merely allocate its metadata
           * here; no cache victim is reserved yet.  This is what
           * permits MAX_MISSES outstanding misses without requiring
           * MAX_MISSES blocks of data buffering.
           */
          miss_valid[free_miss_idx]
              <= 1'b1;

          miss_line_addr[free_miss_idx]
              <= req_line_addr;

          miss_word_idx[free_miss_idx]
              <= req_word_idx;

          miss_id[free_miss_idx]
              <= req_id_i;

          miss_op[free_miss_idx]
              <= req_op_i;

          miss_store_data[free_miss_idx]
              <= req_data_i;

          miss_store_mask[free_miss_idx]
              <= req_mask_i;

        end
      end

      case (mem_state)

        /*
         * Pick one tracked miss for memory service.
         */
        S_IDLE: begin

          if (sched_found) begin

            active_miss_idx
                <= sched_idx;

            active_line_addr
                <= miss_line_addr[sched_idx];

            active_set
                <= sched_set;

            active_tag
                <= sched_tag;

            active_way
                <= sched_way;

            victim_line_addr
                <= sched_victim_addr;

            mem_beat_count
                <= '0;

            miss_sched_ptr
                <= sched_idx + 1'b1;

            repl_ptr[sched_set]
                <= sched_way + 1'b1;

            /*
             * Once a way is chosen for eviction it is no longer
             * CPU-visible.  Its data remain physically in the array
             * until any required writeback has consumed all four
             * words.
             */
            if (sched_victim_valid) begin
              valid_array
                [sched_set]
                [sched_way]
              <= 1'b0;
            end

            if (sched_victim_dirty) begin
              mem_state <= S_WB_REQ;
            end else begin
              mem_state <= S_FILL_REQ;
            end

          end
        end

        /*
         * Send a block writeback request for a dirty victim.
         */
        S_WB_REQ: begin

          if (mem_req_valid_o &&
              mem_req_ready_i) begin

            mem_beat_count <= '0;
            mem_state      <= S_WB_DATA;

          end
        end

        /*
         * Send exactly four writeback words, lowest word first.
         */
        S_WB_DATA: begin

          if (mem_wr_valid_o &&
              mem_wr_ready_i) begin

            if (mem_beat_count ==
                (BLOCK_WORDS-1)) begin

              mem_beat_count <= '0;
              mem_state      <= S_FILL_REQ;

            end else begin

              mem_beat_count
                  <= mem_beat_count + 1'b1;

            end
          end
        end

        /*
         * Request the missing block.
         */
        S_FILL_REQ: begin

          if (mem_req_valid_o &&
              mem_req_ready_i) begin

            mem_beat_count <= '0;
            mem_state      <= S_FILL_DATA;

          end
        end

        /*
         * Receive exactly four fill words in ascending order.
         */
        S_FILL_DATA: begin

          if (mem_rd_valid_i &&
              mem_rd_ready_o) begin

            fill_buf[mem_beat_count]
                <= mem_rd_data_i;

            if (mem_beat_count ==
                (BLOCK_WORDS-1)) begin

              /*
               * The fill has completed.
               *
               * Install all four words atomically from the CPU's
               * point of view.  For a STORE miss, merge its byte
               * enables into the addressed fill word.
               *
               * fill_buf contains beats 0..2.  Beat 3 is the
               * currently transferring mem_rd_data_i value.
               */
              for (b = 0;
                   b < BLOCK_WORDS;
                   b = b + 1) begin

                if (miss_op[active_miss_idx] &&
                    (miss_word_idx[active_miss_idx] == b)) begin

                  if (b == (BLOCK_WORDS-1)) begin

                    data_array
                      [active_set]
                      [active_way]
                      [b]
                    <= merge_word(
                         mem_rd_data_i,
                         miss_store_data[active_miss_idx],
                         miss_store_mask[active_miss_idx]
                       );

                  end else begin

                    data_array
                      [active_set]
                      [active_way]
                      [b]
                    <= merge_word(
                         fill_buf[b],
                         miss_store_data[active_miss_idx],
                         miss_store_mask[active_miss_idx]
                       );

                  end

                end else begin

                  if (b == (BLOCK_WORDS-1)) begin

                    data_array
                      [active_set]
                      [active_way]
                      [b]
                    <= mem_rd_data_i;

                  end else begin

                    data_array
                      [active_set]
                      [active_way]
                      [b]
                    <= fill_buf[b];

                  end
                end
              end

              tag_array
                [active_set]
                [active_way]
              <= active_tag;

              valid_array
                [active_set]
                [active_way]
              <= 1'b1;

              dirty_array
                [active_set]
                [active_way]
              <= miss_op[active_miss_idx];

              /*
               * Produce exactly one response for the miss.
               */
              rsp_valid_o
                  <= 1'b1;

              rsp_id_o
                  <= miss_id[active_miss_idx];

              if (miss_op[active_miss_idx]) begin

                rsp_data_o <= '0;

              end else if (
                miss_word_idx[active_miss_idx] ==
                (BLOCK_WORDS-1)
              ) begin

                rsp_data_o <= mem_rd_data_i;

              end else begin

                rsp_data_o <=
                    fill_buf[
                      miss_word_idx[active_miss_idx]
                    ];

              end

              /*
               * Release the miss record only after its line has
               * landed and its response has been generated.
               */
              miss_valid[active_miss_idx]
                  <= 1'b0;

              mem_beat_count
                  <= '0;

              mem_state
                  <= S_IDLE;

            end else begin

              mem_beat_count
                  <= mem_beat_count + 1'b1;

            end
          end
        end

        default: begin
          mem_state <= S_IDLE;
        end

      endcase
    end
  end

endmodule