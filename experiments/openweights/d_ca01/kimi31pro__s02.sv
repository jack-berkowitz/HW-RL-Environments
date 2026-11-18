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
  localparam int unsigned BYTE_LANES  = DATA_W / 8;
  localparam int unsigned BYTE_OFF_W  = $clog2(BYTE_LANES);
  localparam int unsigned SET_W       = $clog2(SETS);
  localparam int unsigned WAY_W       = $clog2(WAYS);
  localparam int unsigned MSHR_W      = $clog2(MAX_MISSES);
  localparam int unsigned TAG_W       = 32 - SET_W - 2 - BYTE_OFF_W;

  localparam int unsigned RSP_DEPTH   = 16;

  // --------------------------------------------------------------------------
  // Cache arrays
  // --------------------------------------------------------------------------

  logic [DATA_W-1:0] data_array [0:SETS-1][0:WAYS-1][0:BLOCK_WORDS-1];
  logic [TAG_W-1:0]  tag_array  [0:SETS-1][0:WAYS-1];
  logic              valid_array[0:SETS-1][0:WAYS-1];
  logic              dirty_array[0:SETS-1][0:WAYS-1];

  // A busy way has been selected as a victim, but its fill has not committed.
  logic              busy_array [0:SETS-1][0:WAYS-1];

  // --------------------------------------------------------------------------
  // Miss records
  //
  // A record is allocated without selecting a victim.  Consequently, accepting
  // MAX_MISSES misses never requires MAX_MISSES writeback data buffers.
  // --------------------------------------------------------------------------

  typedef enum logic [1:0] {
    MSHR_EMPTY,
    MSHR_PENDING,
    MSHR_COMMIT
  } mshr_state_t;

  mshr_state_t mshr_state[0:MAX_MISSES-1];

  logic [31:0]           mshr_addr[0:MAX_MISSES-1];
  logic [SET_W-1:0]      mshr_set [0:MAX_MISSES-1];
  logic [TAG_W-1:0]      mshr_tag [0:MAX_MISSES-1];
  logic [1:0]            mshr_word[0:MAX_MISSES-1];
  logic [WAY_W-1:0]      mshr_way [0:MAX_MISSES-1];
  logic                  mshr_op  [0:MAX_MISSES-1];
  logic [3:0]            mshr_id  [0:MAX_MISSES-1];
  logic [DATA_W-1:0]     mshr_data[0:MAX_MISSES-1];
  logic [BYTE_LANES-1:0] mshr_mask[0:MAX_MISSES-1];

  // --------------------------------------------------------------------------
  // Memory transaction state and the two permitted block-data buffers
  // --------------------------------------------------------------------------

  typedef enum logic [2:0] {
    MEM_IDLE,
    MEM_WB_REQ,
    MEM_WB_DATA,
    MEM_FILL_REQ,
    MEM_FILL_DATA
  } mem_state_t;

  mem_state_t mem_state;

  logic [MSHR_W-1:0] active_mshr;
  logic [MSHR_W-1:0] sched_rr;

  logic              mem_we_reg;
  logic [31:0]       mem_addr_reg;

  logic [DATA_W-1:0] fill_buf[0:BLOCK_WORDS-1];
  logic [DATA_W-1:0] wb_buf  [0:BLOCK_WORDS-1];

  logic [1:0] fill_beat;
  logic [1:0] wb_beat;

  // --------------------------------------------------------------------------
  // Response FIFO
  // --------------------------------------------------------------------------

  logic [3:0]        rsp_id_fifo  [0:RSP_DEPTH-1];
  logic [DATA_W-1:0] rsp_data_fifo[0:RSP_DEPTH-1];

  logic [3:0] rsp_wptr;
  logic [3:0] rsp_rptr;
  logic [4:0] rsp_count;

  logic       rsp_deq;
  logic       rsp_slot;
  logic       rsp_enq;
  logic [3:0] rsp_enq_id;
  logic [DATA_W-1:0] rsp_enq_data;

  // --------------------------------------------------------------------------
  // Request decode and lookup
  // --------------------------------------------------------------------------

  logic [SET_W-1:0] req_set;
  logic [1:0]       req_word;
  logic [TAG_W-1:0] req_tag;
  logic [31:0]      req_line_addr;

  logic             req_hit;
  logic [WAY_W-1:0] req_hit_way;
  logic             req_pending;
  logic             free_found;
  logic [MSHR_W-1:0] free_idx;

  assign req_set  = req_addr_i[BYTE_OFF_W+2 +: SET_W];
  assign req_word = req_addr_i[BYTE_OFF_W +: 2];
  assign req_tag  = req_addr_i[31 -: TAG_W];
  assign req_line_addr =
      {req_tag, req_set, 2'b00, {BYTE_OFF_W{1'b0}}};

  always_comb begin : request_lookup
    integer w;
    integer m;

    req_hit     = 1'b0;
    req_hit_way = '0;
    req_pending = 1'b0;
    free_found  = 1'b0;
    free_idx    = '0;

    for (w = 0; w < WAYS; w = w + 1) begin
      if (!req_hit &&
          valid_array[req_set][w] &&
          (tag_array[req_set][w] == req_tag)) begin
        req_hit     = 1'b1;
        req_hit_way = w[WAY_W-1:0];
      end
    end

    for (m = 0; m < MAX_MISSES; m = m + 1) begin
      if ((mshr_state[m] != MSHR_EMPTY) &&
          (mshr_addr[m] == req_line_addr)) begin
        req_pending = 1'b1;
      end

      if (!free_found && (mshr_state[m] == MSHR_EMPTY)) begin
        free_found = 1'b1;
        free_idx   = m[MSHR_W-1:0];
      end
    end
  end

  // --------------------------------------------------------------------------
  // Round-robin miss scheduling and victim selection
  // --------------------------------------------------------------------------

  logic              sched_valid;
  logic [MSHR_W-1:0] sched_idx;
  logic [SET_W-1:0]  sched_set;

  logic              sched_victim_found;
  logic [WAY_W-1:0]  sched_victim_way;
  logic              sched_victim_dirty;
  logic [31:0]       sched_victim_addr;
  logic              sched_fire;

  always_comb begin : miss_scheduler
    integer m;
    integer w;
    integer scan_idx;

    sched_valid        = 1'b0;
    sched_idx          = '0;
    sched_set          = '0;
    scan_idx           = 0;

    sched_victim_found = 1'b0;
    sched_victim_way   = '0;
    sched_victim_dirty = 1'b0;
    sched_victim_addr  = 32'b0;

    // MAX_MISSES is a power of two in every legal configuration.  The explicit
    // conditional subtraction also avoids relying on that fact for indexing.
    for (m = 0; m < MAX_MISSES; m = m + 1) begin
      scan_idx = sched_rr + m;
      if (scan_idx >= MAX_MISSES) begin
        scan_idx = scan_idx - MAX_MISSES;
      end

      if (!sched_valid &&
          (mshr_state[scan_idx] == MSHR_PENDING)) begin
        sched_valid = 1'b1;
        sched_idx   = scan_idx[MSHR_W-1:0];
      end
    end

    if (sched_valid) begin
      sched_set = mshr_set[sched_idx];

      // Prefer an invalid, unreserved way.
      for (w = 0; w < WAYS; w = w + 1) begin
        if (!sched_victim_found &&
            !valid_array[sched_set][w] &&
            !busy_array[sched_set][w]) begin
          sched_victim_found = 1'b1;
          sched_victim_way   = w[WAY_W-1:0];
        end
      end

      // Otherwise use the first unreserved way.  Replacement policy is free.
      if (!sched_victim_found) begin
        for (w = 0; w < WAYS; w = w + 1) begin
          if (!sched_victim_found && !busy_array[sched_set][w]) begin
            sched_victim_found = 1'b1;
            sched_victim_way   = w[WAY_W-1:0];
          end
        end
      end

      if (sched_victim_found) begin
        sched_victim_dirty =
            valid_array[sched_set][sched_victim_way] &&
            dirty_array[sched_set][sched_victim_way];

        sched_victim_addr =
            {tag_array[sched_set][sched_victim_way],
             sched_set, 2'b00, {BYTE_OFF_W{1'b0}}};
      end
    end
  end

  // --------------------------------------------------------------------------
  // Fill commit detection
  // --------------------------------------------------------------------------

  logic              commit_valid;
  logic [MSHR_W-1:0] commit_idx;
  logic              commit_fire;
  logic              hit_fire;

  always_comb begin : commit_lookup
    integer m;

    commit_valid = 1'b0;
    commit_idx   = '0;

    for (m = 0; m < MAX_MISSES; m = m + 1) begin
      if (!commit_valid && (mshr_state[m] == MSHR_COMMIT)) begin
        commit_valid = 1'b1;
        commit_idx   = m[MSHR_W-1:0];
      end
    end
  end

  // Do not start another fill while an uncommitted fill still needs fill_buf.
  assign sched_fire = (mem_state == MEM_IDLE) &&
                      sched_valid &&
                      sched_victim_found &&
                      !commit_valid;

  // --------------------------------------------------------------------------
  // Response and request handshakes
  // --------------------------------------------------------------------------

  assign rsp_valid_o = (rsp_count != 5'd0);
  assign rsp_id_o    = rsp_id_fifo[rsp_rptr];
  assign rsp_data_o  = rsp_data_fifo[rsp_rptr];

  assign rsp_deq  = rsp_valid_o && rsp_ready_i;
  assign rsp_slot = (rsp_count < 5'd16) || rsp_deq;

  assign commit_fire = commit_valid && rsp_slot;

  // A scheduling cycle is excluded from request acceptance so that a store hit
  // cannot modify a victim in the same cycle its old contents are captured.
  always_comb begin : request_ready
    req_ready_o = 1'b0;

    if (rst_ni && !sched_fire) begin
      if (req_pending) begin
        req_ready_o = 1'b0;
      end else if (req_hit) begin
        // A fill commit has priority for the single response-enqueue port.
        req_ready_o = !commit_valid && rsp_slot;
      end else if (free_found) begin
        req_ready_o = 1'b1;
      end
    end
  end

  assign hit_fire = req_valid_i && req_ready_o && req_hit;
  assign rsp_enq  = commit_fire || hit_fire;

  assign rsp_enq_id = commit_fire ? mshr_id[commit_idx] : req_id_i;

  always_comb begin : response_data_select
    rsp_enq_data = {DATA_W{1'b0}};

    if (commit_fire) begin
      if (!mshr_op[commit_idx]) begin
        rsp_enq_data = fill_buf[mshr_word[commit_idx]];
      end
    end else if (hit_fire) begin
      if (!req_op_i) begin
        rsp_enq_data = data_array[req_set][req_hit_way][req_word];
      end
    end
  end

  // --------------------------------------------------------------------------
  // Memory port outputs
  // --------------------------------------------------------------------------

  assign mem_req_valid_o = (mem_state == MEM_WB_REQ) ||
                           (mem_state == MEM_FILL_REQ);
  assign mem_req_we_o    = mem_we_reg;
  assign mem_req_addr_o  = mem_addr_reg;

  assign mem_rd_ready_o = (mem_state == MEM_FILL_DATA);

  assign mem_wr_valid_o = (mem_state == MEM_WB_DATA);
  assign mem_wr_data_o  = wb_buf[wb_beat];

  // --------------------------------------------------------------------------
  // Byte-masked store merge
  // --------------------------------------------------------------------------

  function automatic logic [DATA_W-1:0] merge_word(
    input logic [DATA_W-1:0]     old_word,
    input logic [DATA_W-1:0]     store_word,
    input logic [BYTE_LANES-1:0] store_mask
  );
    integer b;
    begin
      merge_word = old_word;
      for (b = 0; b < BYTE_LANES; b = b + 1) begin
        if (store_mask[b]) begin
          merge_word[8*b +: 8] = store_word[8*b +: 8];
        end
      end
    end
  endfunction

  // --------------------------------------------------------------------------
  // Sequential state
  // --------------------------------------------------------------------------

  always_ff @(posedge clk_i or negedge rst_ni) begin : sequential_state
    integer s;
    integer w;
    integer m;
    integer b;

    if (!rst_ni) begin
      mem_state   <= MEM_IDLE;
      active_mshr <= '0;
      sched_rr    <= '0;
      mem_we_reg  <= 1'b0;
      mem_addr_reg<= 32'b0;
      fill_beat   <= 2'b0;
      wb_beat     <= 2'b0;

      rsp_wptr  <= 4'b0;
      rsp_rptr  <= 4'b0;
      rsp_count <= 5'b0;

      for (s = 0; s < SETS; s = s + 1) begin
        for (w = 0; w < WAYS; w = w + 1) begin
          valid_array[s][w] <= 1'b0;
          dirty_array[s][w] <= 1'b0;
          busy_array[s][w]  <= 1'b0;
        end
      end

      for (m = 0; m < MAX_MISSES; m = m + 1) begin
        mshr_state[m] <= MSHR_EMPTY;
      end
    end else begin
      // Response FIFO.  Simultaneous enqueue and dequeue leaves count unchanged.
      if (rsp_enq) begin
        rsp_id_fifo[rsp_wptr]   <= rsp_enq_id;
        rsp_data_fifo[rsp_wptr] <= rsp_enq_data;
        rsp_wptr                <= rsp_wptr + 4'd1;
      end

      if (rsp_deq) begin
        rsp_rptr <= rsp_rptr + 4'd1;
      end

      if (rsp_enq && !rsp_deq) begin
        rsp_count <= rsp_count + 5'd1;
      end else if (!rsp_enq && rsp_deq) begin
        rsp_count <= rsp_count - 5'd1;
      end

      // Accepted hit or new miss.
      if (req_valid_i && req_ready_o) begin
        if (req_hit) begin
          if (req_op_i) begin
            for (b = 0; b < BYTE_LANES; b = b + 1) begin
              if (req_mask_i[b]) begin
                data_array[req_set][req_hit_way][req_word][8*b +: 8]
                    <= req_data_i[8*b +: 8];
              end
            end
            dirty_array[req_set][req_hit_way] <= 1'b1;
          end
        end else begin
          mshr_state[free_idx] <= MSHR_PENDING;
          mshr_addr [free_idx] <= req_line_addr;
          mshr_set  [free_idx] <= req_set;
          mshr_tag  [free_idx] <= req_tag;
          mshr_word [free_idx] <= req_word;
          mshr_way  [free_idx] <= '0;
          mshr_op   [free_idx] <= req_op_i;
          mshr_id   [free_idx] <= req_id_i;
          mshr_data [free_idx] <= req_data_i;
          mshr_mask [free_idx] <= req_mask_i;
        end
      end

      // Select a victim and start its writeback, if needed, or its fill.
      if (sched_fire) begin
        active_mshr        <= sched_idx;
        mshr_way[sched_idx]<= sched_victim_way;
        sched_rr           <= sched_idx + 1'b1;

        valid_array[sched_set][sched_victim_way] <= 1'b0;
        dirty_array[sched_set][sched_victim_way] <= 1'b0;
        busy_array [sched_set][sched_victim_way] <= 1'b1;

        mem_we_reg <= sched_victim_dirty;
        fill_beat  <= 2'b0;
        wb_beat    <= 2'b0;

        if (sched_victim_dirty) begin
          mem_state    <= MEM_WB_REQ;
          mem_addr_reg <= sched_victim_addr;

          for (w = 0; w < BLOCK_WORDS; w = w + 1) begin
            wb_buf[w] <= data_array[sched_set][sched_victim_way][w];
          end
        end else begin
          mem_state    <= MEM_FILL_REQ;
          mem_addr_reg <= mshr_addr[sched_idx];
        end
      end

      // The single outstanding memory transaction.
      case (mem_state)
        MEM_IDLE: begin
        end

        MEM_WB_REQ: begin
          if (mem_req_ready_i) begin
            mem_state <= MEM_WB_DATA;
            wb_beat   <= 2'b0;
          end
        end

        MEM_WB_DATA: begin
          if (mem_wr_ready_i) begin
            if (wb_beat == 2'd3) begin
              mem_state    <= MEM_FILL_REQ;
              mem_we_reg   <= 1'b0;
              mem_addr_reg <= mshr_addr[active_mshr];
              wb_beat      <= 2'b0;
            end else begin
              wb_beat <= wb_beat + 2'd1;
            end
          end
        end

        MEM_FILL_REQ: begin
          if (mem_req_ready_i) begin
            mem_state <= MEM_FILL_DATA;
            fill_beat <= 2'b0;
          end
        end

        MEM_FILL_DATA: begin
          if (mem_rd_valid_i) begin
            fill_buf[fill_beat] <= mem_rd_data_i;

            if (fill_beat == 2'd3) begin
              mem_state              <= MEM_IDLE;
              mshr_state[active_mshr]<= MSHR_COMMIT;
              fill_beat              <= 2'b0;
            end else begin
              fill_beat <= fill_beat + 2'd1;
            end
          end
        end

        default: begin
          mem_state <= MEM_IDLE;
        end
      endcase

      // Commit the completed fill and merge its initiating store, if any.
      if (commit_fire) begin
        for (w = 0; w < BLOCK_WORDS; w = w + 1) begin
          if (mshr_op[commit_idx] &&
              (mshr_word[commit_idx] == w[1:0])) begin
            data_array[mshr_set[commit_idx]]
                      [mshr_way[commit_idx]][w]
                <= merge_word(fill_buf[w],
                              mshr_data[commit_idx],
                              mshr_mask[commit_idx]);
          end else begin
            data_array[mshr_set[commit_idx]]
                      [mshr_way[commit_idx]][w]
                <= fill_buf[w];
          end
        end

        tag_array[mshr_set[commit_idx]][mshr_way[commit_idx]]
            <= mshr_tag[commit_idx];
        valid_array[mshr_set[commit_idx]][mshr_way[commit_idx]]
            <= 1'b1;
        dirty_array[mshr_set[commit_idx]][mshr_way[commit_idx]]
            <= mshr_op[commit_idx];
        busy_array[mshr_set[commit_idx]][mshr_way[commit_idx]]
            <= 1'b0;

        mshr_state[commit_idx] <= MSHR_EMPTY;
      end
    end
  end

endmodule
