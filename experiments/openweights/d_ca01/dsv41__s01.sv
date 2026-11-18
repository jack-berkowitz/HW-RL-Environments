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
  localparam int unsigned WORD_BYTES  = DATA_W / 8;
  localparam int unsigned BYTE_OFF    = $clog2(WORD_BYTES);
  localparam int unsigned BLOCK_BYTES = BLOCK_WORDS * WORD_BYTES;
  localparam int unsigned BLOCK_OFF   = $clog2(BLOCK_BYTES);
  localparam int unsigned SET_IDX_W   = $clog2(SETS);
  localparam int unsigned TAG_W       = 32 - BLOCK_OFF - SET_IDX_W;
  localparam int unsigned WAY_IDX_W   = $clog2(WAYS);
  localparam int unsigned MISS_ID_W   = $clog2(MAX_MISSES);
  localparam int unsigned MISS_CNT_W  = $clog2(MAX_MISSES + 1);
  localparam int unsigned RSP_DEPTH   = 4;
  localparam int unsigned RSP_PTR_W   = $clog2(RSP_DEPTH);

  // Cache arrays
  logic [DATA_W-1:0] data_array [SETS][WAYS][BLOCK_WORDS];
  logic [TAG_W-1:0]  tag_array  [SETS][WAYS];
  logic              valid_array[SETS][WAYS];
  logic              dirty_array[SETS][WAYS];

  // Miss queue
  logic                    miss_valid      [MAX_MISSES];
  logic [31:0]             miss_block_addr [MAX_MISSES];
  logic [3:0]              miss_id         [MAX_MISSES];
  logic                    miss_op         [MAX_MISSES];
  logic [1:0]              miss_word_idx   [MAX_MISSES];
  logic [DATA_W-1:0]       miss_store_data [MAX_MISSES];
  logic [WORD_BYTES-1:0]   miss_store_mask [MAX_MISSES];
  logic [MISS_CNT_W-1:0]   miss_count;
  logic [MISS_ID_W-1:0]    miss_rr;

  // Replacement
  logic [WAY_IDX_W-1:0] rr_way [SETS];

  // Response FIFO
  logic [3:0]              rsp_fifo_id   [RSP_DEPTH];
  logic [DATA_W-1:0]       rsp_fifo_data [RSP_DEPTH];
  logic [RSP_PTR_W-1:0]    rsp_head;
  logic [RSP_PTR_W-1:0]    rsp_tail;
  logic [RSP_PTR_W:0]      rsp_count;

  // Memory state machine
  typedef enum logic [2:0] {
    MEM_IDLE,
    MEM_REQ_WR,
    MEM_WR_DATA,
    MEM_REQ_RD,
    MEM_RD_DATA,
    MEM_APPLY_STORE,
    MEM_FINALIZE
  } mem_state_t;
  mem_state_t mem_state;

  logic [MISS_ID_W-1:0] proc_idx;
  logic [SET_IDX_W-1:0] proc_set;
  logic [WAY_IDX_W-1:0] proc_way;
  logic [31:0]          mem_addr;
  logic [1:0]           beat_cnt;

  // Combinational request analysis
  logic                    req_is_hit;
  logic [WAY_IDX_W-1:0]    req_hit_way;
  logic [SET_IDX_W-1:0]    req_set;
  logic [TAG_W-1:0]        req_tag;
  logic [1:0]              req_word_idx;
  logic [31:0]             req_block_addr;
  logic                    req_pending_same;
  logic                    hit_ready;
  logic                    miss_ready;
  logic                    fill_write;
  logic                    enq_hit;
  logic                    enq_miss;
  logic                    deq;
  logic [MISS_ID_W-1:0]    miss_free_idx;
  logic                    miss_free_found;
  logic                    miss_accept;
  logic                    hit_conflict;

  // Miss selection for memory controller
  logic                    start_miss;
  logic [MISS_ID_W-1:0]    start_idx;
  logic [SET_IDX_W-1:0]    start_set;
  logic [31:0]             start_block_addr;
  logic [WAY_IDX_W-1:0]    start_way;
  logic                    start_need_wb;

  // Byte mask expansion
  function automatic [DATA_W-1:0] expand_mask(input [WORD_BYTES-1:0] mask);
    integer i;
    begin
      for (i = 0; i < WORD_BYTES; i = i + 1) begin
        expand_mask[i*8 +: 8] = {8{mask[i]}};
      end
    end
  endfunction

  // Response FIFO outputs
  assign rsp_valid_o = (rsp_count > 0);
  assign rsp_id_o    = rsp_fifo_id[rsp_head];
  assign rsp_data_o  = rsp_fifo_data[rsp_head];

  // Memory outputs
  assign mem_req_valid_o = (mem_state == MEM_REQ_WR) || (mem_state == MEM_REQ_RD);
  assign mem_req_we_o    = (mem_state == MEM_REQ_WR);
  assign mem_req_addr_o  = mem_addr;
  assign mem_wr_valid_o  = (mem_state == MEM_WR_DATA);
  assign mem_wr_data_o   = data_array[proc_set][proc_way][beat_cnt];
  assign mem_rd_ready_o  = (mem_state == MEM_RD_DATA);

  // Combinational request analysis
  always_comb begin
    integer i, w;
    req_set        = (req_addr_i >> BLOCK_OFF) & (SETS - 1);
    req_tag        = req_addr_i >> (BLOCK_OFF + SET_IDX_W);
    req_word_idx   = (req_addr_i >> BYTE_OFF) & (BLOCK_WORDS - 1);
    req_block_addr = req_addr_i & ~(BLOCK_BYTES - 1);

    req_is_hit = 1'b0;
    req_hit_way = '0;
    for (w = 0; w < WAYS; w = w + 1) begin
      if (valid_array[req_set][w] && (tag_array[req_set][w] == req_tag)) begin
        req_is_hit  = 1'b1;
        req_hit_way = w[WAY_IDX_W-1:0];
      end
    end

    req_pending_same = 1'b0;
    for (i = 0; i < MAX_MISSES; i = i + 1) begin
      if (miss_valid[i] && (miss_block_addr[i] == req_block_addr)) begin
        req_pending_same = 1'b1;
      end
    end
  end

  // Free miss slot
  always_comb begin
    integer i;
    miss_free_idx   = '0;
    miss_free_found = 1'b0;
    for (i = 0; i < MAX_MISSES; i = i + 1) begin
      if (!miss_valid[i] && !miss_free_found) begin
        miss_free_idx   = i[MISS_ID_W-1:0];
        miss_free_found = 1'b1;
      end
    end
  end

  // Miss selection and victim choice
  always_comb begin
    integer i, idx, w;
    logic found;

    start_miss       = 1'b0;
    start_idx        = '0;
    start_block_addr = '0;
    start_set        = '0;
    start_way        = '0;
    start_need_wb    = 1'b0;

    found = 1'b0;
    for (i = 0; i < MAX_MISSES; i = i + 1) begin
      idx = (miss_rr + i) % MAX_MISSES;
      if (!found && miss_valid[idx]) begin
        found     = 1'b1;
        start_miss = 1'b1;
        start_idx  = idx[MISS_ID_W-1:0];
      end
    end

    if (start_miss) begin
      start_block_addr = miss_block_addr[start_idx];
      start_set        = (start_block_addr >> BLOCK_OFF) & (SETS - 1);
      start_way        = rr_way[start_set];

      found = 1'b0;
      for (w = 0; w < WAYS; w = w + 1) begin
        if (!valid_array[start_set][w] && !found) begin
          start_way = w[WAY_IDX_W-1:0];
          found     = 1'b1;
        end
      end
      start_need_wb = valid_array[start_set][start_way] && dirty_array[start_set][start_way];
    end
  end

  // Fill write indicator
  assign fill_write = (mem_state == MEM_RD_DATA) && mem_rd_valid_i && mem_rd_ready_o;

  // Response enqueue / dequeue
  assign enq_miss = (mem_state == MEM_FINALIZE) && (rsp_count < RSP_DEPTH);
  assign deq      = rsp_valid_o && rsp_ready_i;

  // Request acceptance
  assign hit_ready  = (rsp_count < RSP_DEPTH) && !enq_miss && (!req_op_i || !fill_write);
  assign miss_ready = (miss_count < MAX_MISSES) && !req_pending_same;
  assign req_ready_o = req_valid_i && (req_is_hit ? hit_ready : miss_ready);

  assign enq_hit    = req_valid_i && req_ready_o && req_is_hit;
  assign miss_accept = req_valid_i && req_ready_o && !req_is_hit;

  // Conflict: store hit to the exact victim way while starting an eviction
  assign hit_conflict = start_miss && req_valid_i && req_ready_o && req_is_hit &&
                        req_op_i && (req_set == start_set) && (req_hit_way == start_way);

  // Sequential logic
  always_ff @(posedge clk_i or negedge rst_ni) begin
    integer s, w, m, r;

    if (!rst_ni) begin
      mem_state <= MEM_IDLE;
      beat_cnt  <= 0;
      proc_idx  <= '0;
      proc_set  <= '0;
      proc_way  <= '0;
      mem_addr  <= '0;
      miss_count <= '0;
      miss_rr    <= '0;
      rsp_head   <= '0;
      rsp_tail   <= '0;
      rsp_count  <= '0;

      for (s = 0; s < SETS; s = s + 1) begin
        rr_way[s] <= '0;
        for (w = 0; w < WAYS; w = w + 1) begin
          valid_array[s][w] <= 1'b0;
          dirty_array[s][w] <= 1'b0;
          tag_array[s][w]   <= '0;
        end
      end

      for (m = 0; m < MAX_MISSES; m = m + 1) begin
        miss_valid[m]      <= 1'b0;
        miss_block_addr[m] <= '0;
        miss_id[m]         <= '0;
        miss_op[m]         <= 1'b0;
        miss_word_idx[m]   <= '0;
        miss_store_data[m] <= '0;
        miss_store_mask[m] <= '0;
      end

      for (r = 0; r < RSP_DEPTH; r = r + 1) begin
        rsp_fifo_id[r]   <= '0;
        rsp_fifo_data[r] <= '0;
      end
    end else begin
      // Response FIFO dequeue
      if (deq) begin
        rsp_head <= rsp_head + 1;
      end

      // Response FIFO enqueue
      if (enq_hit) begin
        rsp_fifo_id[rsp_tail] <= req_id_i;
        if (req_op_i == 1'b0) begin
          rsp_fifo_data[rsp_tail] <= data_array[req_set][req_hit_way][req_word_idx];
        end else begin
          rsp_fifo_data[rsp_tail] <= '0;
        end
        rsp_tail <= rsp_tail + 1;
      end else if (enq_miss) begin
        rsp_fifo_id[rsp_tail] <= miss_id[proc_idx];
        if (miss_op[proc_idx] == 1'b0) begin
          rsp_fifo_data[rsp_tail] <= data_array[proc_set][proc_way][miss_word_idx[proc_idx]];
        end else begin
          rsp_fifo_data[rsp_tail] <= '0;
        end
        rsp_tail <= rsp_tail + 1;
      end

      // Update response count
      rsp_count <= rsp_count + (enq_hit ? 1 : 0) + (enq_miss ? 1 : 0) - (deq ? 1 : 0);

      // Update miss count
      miss_count <= miss_count + (miss_accept ? 1 : 0) - (enq_miss ? 1 : 0);

      // Request acceptance
      if (req_valid_i && req_ready_o) begin
        if (req_is_hit) begin
          if (req_op_i == 1'b1) begin
            data_array[req_set][req_hit_way][req_word_idx] <=
              (data_array[req_set][req_hit_way][req_word_idx] & ~expand_mask(req_mask_i)) |
              (req_data_i & expand_mask(req_mask_i));
            dirty_array[req_set][req_hit_way] <= 1'b1;
          end
        end else begin
          miss_valid[miss_free_idx]      <= 1'b1;
          miss_block_addr[miss_free_idx] <= req_block_addr;
          miss_id[miss_free_idx]         <= req_id_i;
          miss_op[miss_free_idx]         <= req_op_i;
          miss_word_idx[miss_free_idx]   <= req_word_idx;
          miss_store_data[miss_free_idx] <= req_data_i;
          miss_store_mask[miss_free_idx] <= req_mask_i;
        end
      end

      // Memory state machine
      case (mem_state)
        MEM_IDLE: begin
          if (start_miss && !hit_conflict) begin
            proc_idx <= start_idx;
            proc_set <= start_set;
            proc_way <= start_way;

            if (start_need_wb) begin
              mem_addr <= {tag_array[start_set][start_way], start_set, {BLOCK_OFF{1'b0}}};
              valid_array[start_set][start_way] <= 1'b0;
              dirty_array[start_set][start_way] <= 1'b0;
              mem_state <= MEM_REQ_WR;
            end else begin
              mem_addr <= start_block_addr;
              valid_array[start_set][start_way] <= 1'b0;
              dirty_array[start_set][start_way] <= 1'b0;
              mem_state <= MEM_REQ_RD;
            end
            beat_cnt <= 0;
          end
        end

        MEM_REQ_WR: begin
          if (mem_req_ready_i) begin
            mem_state <= MEM_WR_DATA;
            beat_cnt  <= 0;
          end
        end

        MEM_WR_DATA: begin
          if (mem_wr_ready_i) begin
            if (beat_cnt == BLOCK_WORDS - 1) begin
              mem_addr  <= miss_block_addr[proc_idx];
              mem_state <= MEM_REQ_RD;
              beat_cnt  <= 0;
            end else begin
              beat_cnt <= beat_cnt + 1;
            end
          end
        end

        MEM_REQ_RD: begin
          if (mem_req_ready_i) begin
            mem_state <= MEM_RD_DATA;
            beat_cnt  <= 0;
          end
        end

        MEM_RD_DATA: begin
          if (mem_rd_valid_i && mem_rd_ready_o) begin
            data_array[proc_set][proc_way][beat_cnt] <= mem_rd_data_i;

            if (beat_cnt == BLOCK_WORDS - 1) begin
              if (miss_op[proc_idx]) begin
                mem_state <= MEM_APPLY_STORE;
              end else begin
                mem_state <= MEM_FINALIZE;
              end
            end else begin
              beat_cnt <= beat_cnt + 1;
            end
          end
        end

        MEM_APPLY_STORE: begin
          data_array[proc_set][proc_way][miss_word_idx[proc_idx]] <=
            (data_array[proc_set][proc_way][miss_word_idx[proc_idx]] & ~expand_mask(miss_store_mask[proc_idx])) |
            (miss_store_data[proc_idx] & expand_mask(miss_store_mask[proc_idx]));
          mem_state <= MEM_FINALIZE;
        end

        MEM_FINALIZE: begin
          if (rsp_count < RSP_DEPTH) begin
            tag_array[proc_set][proc_way]   <= miss_block_addr[proc_idx] >> (BLOCK_OFF + SET_IDX_W);
            valid_array[proc_set][proc_way] <= 1'b1;
            dirty_array[proc_set][proc_way] <= miss_op[proc_idx];
            miss_valid[proc_idx]            <= 1'b0;
            miss_rr                         <= (proc_idx + 1) % MAX_MISSES;
            rr_way[proc_set]                <= (proc_way + 1) % WAYS;
            mem_state                       <= MEM_IDLE;
          end
        end
      endcase
    end
  end

endmodule
