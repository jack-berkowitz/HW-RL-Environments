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
  localparam int unsigned BYTE_OFF_W  = $clog2(DATA_W/8);
  localparam int unsigned WORD_OFF_W  = $clog2(BLOCK_WORDS);
  localparam int unsigned SET_IDX_W   = $clog2(SETS);
  localparam int unsigned TAG_W       = 32 - SET_IDX_W - WORD_OFF_W - BYTE_OFF_W;
  localparam int unsigned WAY_IDX_W   = $clog2(WAYS);
  localparam int unsigned MISS_CNT_W  = $clog2(MAX_MISSES+1);
  localparam int unsigned MISS_IDX_W  = $clog2(MAX_MISSES);
  localparam int unsigned RESP_DEPTH  = MAX_MISSES + 8;
  localparam int unsigned RESP_IDX_W  = $clog2(RESP_DEPTH);
  localparam int unsigned RESP_CNT_W  = $clog2(RESP_DEPTH+1);

  // Cache arrays
  logic [DATA_W-1:0] data_array [SETS][WAYS][BLOCK_WORDS];
  logic [TAG_W-1:0]  tag_array  [SETS][WAYS];
  logic              valid_array[SETS][WAYS];
  logic              dirty_array[SETS][WAYS];

  // Miss queue
  logic                     miss_valid     [MAX_MISSES];
  logic [31:0]              miss_block_addr[MAX_MISSES];
  logic [WORD_OFF_W-1:0]    miss_word_idx  [MAX_MISSES];
  logic [3:0]               miss_id        [MAX_MISSES];
  logic                     miss_op        [MAX_MISSES];
  logic [DATA_W-1:0]        miss_data      [MAX_MISSES];
  logic [(DATA_W/8)-1:0]    miss_mask      [MAX_MISSES];
  logic [MISS_CNT_W-1:0]    miss_count;
  logic [MISS_IDX_W-1:0]    rr_miss_ptr;

  // Response queue
  logic [3:0]               rsp_id_mem   [RESP_DEPTH];
  logic [DATA_W-1:0]        rsp_data_mem [RESP_DEPTH];
  logic [RESP_IDX_W-1:0]    rsp_head, rsp_tail;
  logic [RESP_CNT_W-1:0]    rsp_count;

  // State machine
  typedef enum logic [2:0] {IDLE, WB_REQ, WB_DATA, FILL_REQ, FILL_DATA} state_t;
  state_t state;

  // Current miss processing
  logic [MISS_IDX_W-1:0] current_miss_idx;
  logic [31:0]           current_block_addr;
  logic [WORD_OFF_W-1:0] current_word_idx;
  logic [3:0]            current_id;
  logic                  current_op;
  logic [DATA_W-1:0]     current_data;
  logic [(DATA_W/8)-1:0] current_mask;
  logic [SET_IDX_W-1:0]  current_set;
  logic [TAG_W-1:0]      current_tag;
  logic [WAY_IDX_W-1:0]  victim_way;
  logic [31:0]           victim_block_addr;
  logic                  victim_dirty;
  logic                  busy_active;
  logic [31:0]           busy_addr;
  logic [WAY_IDX_W-1:0]  rr_way [SETS];

  // Writeback buffer
  logic [DATA_W-1:0] wb_buffer [BLOCK_WORDS];

  // Fill data capture
  logic [DATA_W-1:0] load_data_reg;
  logic [WORD_OFF_W-1:0] beat_cnt;

  // Combinational signals
  logic start_processing;
  logic miss_complete;
  logic hit;
  logic [WAY_IDX_W-1:0] hit_way;
  logic pending_match;
  logic busy_match;
  logic [31:0] req_block_addr;
  logic [SET_IDX_W-1:0] req_set;
  logic [TAG_W-1:0] req_tag;
  logic [WORD_OFF_W-1:0] req_word;
  logic enq;
  logic [3:0] enq_id;
  logic [DATA_W-1:0] enq_data;
  logic deq;

  // Address decode for request
  assign req_set   = req_addr_i[BYTE_OFF_W+WORD_OFF_W +: SET_IDX_W];
  assign req_word  = req_addr_i[BYTE_OFF_W +: WORD_OFF_W];
  assign req_tag   = req_addr_i[31:BYTE_OFF_W+WORD_OFF_W+SET_IDX_W];
  assign req_block_addr = {req_addr_i[31:BYTE_OFF_W+WORD_OFF_W], {(BYTE_OFF_W+WORD_OFF_W){1'b0}}};

  // Hit detection
  always_comb begin
    integer w;
    hit = 1'b0;
    hit_way = '0;
    for (w = 0; w < WAYS; w++) begin
      if (valid_array[req_set][w] && (tag_array[req_set][w] == req_tag)) begin
        hit = 1'b1;
        hit_way = w[WAY_IDX_W-1:0];
      end
    end
  end

  // Pending miss match
  always_comb begin
    integer i;
    pending_match = 1'b0;
    for (i = 0; i < MAX_MISSES; i++) begin
      if (miss_valid[i] && (miss_block_addr[i] == req_block_addr)) begin
        pending_match = 1'b1;
      end
    end
  end

  assign busy_match = busy_active && (req_block_addr == busy_addr);
  assign start_processing = (state == IDLE) && (miss_count > 0);
  assign miss_complete = (state == FILL_DATA) && mem_rd_valid_i && mem_rd_ready_o && (beat_cnt == BLOCK_WORDS-1);

  // Request ready
  always_comb begin
    req_ready_o = 1'b0;
    if (!start_processing && !miss_complete) begin
      if ((rsp_count + miss_count) < RESP_DEPTH) begin
        if (!pending_match && !busy_match) begin
          if (hit) begin
            req_ready_o = 1'b1;
          end else if (miss_count < MAX_MISSES) begin
            req_ready_o = 1'b1;
          end
        end
      end
    end
  end

  // Response enqueue logic
  always_comb begin
    enq = 1'b0;
    enq_id = 4'b0;
    enq_data = '0;
    if (miss_complete) begin
      enq = 1'b1;
      enq_id = current_id;
      if (current_op == 1'b0) begin // LOAD
        if (beat_cnt == current_word_idx)
          enq_data = mem_rd_data_i;
        else
          enq_data = load_data_reg;
      end else begin
        enq_data = '0;
      end
    end else if (req_valid_i && req_ready_o && hit) begin
      enq = 1'b1;
      enq_id = req_id_i;
      if (req_op_i == 1'b0) begin
        enq_data = data_array[req_set][hit_way][req_word];
      end else begin
        enq_data = '0;
      end
    end
  end

  assign deq = rsp_valid_o && rsp_ready_i;
  assign rsp_valid_o = (rsp_count > 0);
  assign rsp_id_o = rsp_id_mem[rsp_head];
  assign rsp_data_o = rsp_data_mem[rsp_head];

  // Memory interface outputs
  assign mem_req_valid_o = (state == WB_REQ) || (state == FILL_REQ);
  assign mem_req_we_o    = (state == WB_REQ);
  assign mem_req_addr_o  = (state == WB_REQ) ? victim_block_addr : current_block_addr;
  assign mem_rd_ready_o  = (state == FILL_DATA);
  assign mem_wr_valid_o  = (state == WB_DATA);
  assign mem_wr_data_o   = wb_buffer[beat_cnt];

  // Main sequential logic
  always_ff @(posedge clk_i or negedge rst_ni) begin
    integer i, w, b;
    logic [MISS_IDX_W-1:0] alloc_idx;
    logic found;
    logic [MISS_IDX_W-1:0] sel;
    logic sel_found;
    logic [MISS_IDX_W-1:0] idx;
    logic [SET_IDX_W-1:0] set_idx;
    logic [TAG_W-1:0] tag_val;
    logic [WAY_IDX_W-1:0] vway;
    logic vfound;
    logic [31:0] vblock;
    logic [DATA_W-1:0] merged;

    if (!rst_ni) begin
      for (i = 0; i < SETS; i++) begin
        for (w = 0; w < WAYS; w++) begin
          valid_array[i][w] <= 1'b0;
          dirty_array[i][w] <= 1'b0;
        end
        rr_way[i] <= '0;
      end
      for (i = 0; i < MAX_MISSES; i++) begin
        miss_valid[i] <= 1'b0;
      end
      miss_count <= '0;
      rr_miss_ptr <= '0;
      rsp_head <= '0;
      rsp_tail <= '0;
      rsp_count <= '0;
      state <= IDLE;
      busy_active <= 1'b0;
      busy_addr <= 32'b0;
      beat_cnt <= '0;
      load_data_reg <= '0;
    end else begin
      // Response queue dequeue
      if (deq) begin
        rsp_head <= (rsp_head + 1) % RESP_DEPTH;
      end
      // Response queue enqueue
      if (enq) begin
        rsp_id_mem[rsp_tail] <= enq_id;
        rsp_data_mem[rsp_tail] <= enq_data;
        rsp_tail <= (rsp_tail + 1) % RESP_DEPTH;
      end
      // Update response count
      if (deq && enq)
        rsp_count <= rsp_count;
      else if (deq)
        rsp_count <= rsp_count - 1;
      else if (enq)
        rsp_count <= rsp_count + 1;

      // Accept new miss request
      if (req_valid_i && req_ready_o && !hit) begin
        alloc_idx = '0;
        found = 1'b0;
        for (i = 0; i < MAX_MISSES; i++) begin
          if (!miss_valid[i] && !found) begin
            alloc_idx = i[MISS_IDX_W-1:0];
            found = 1'b1;
          end
        end
        if (found) begin
          miss_valid[alloc_idx] <= 1'b1;
          miss_block_addr[alloc_idx] <= req_block_addr;
          miss_word_idx[alloc_idx] <= req_word;
          miss_id[alloc_idx] <= req_id_i;
          miss_op[alloc_idx] <= req_op_i;
          miss_data[alloc_idx] <= req_data_i;
          miss_mask[alloc_idx] <= req_mask_i;
          miss_count <= miss_count + 1;
        end
      end

      // Store hit update
      if (req_valid_i && req_ready_o && hit && req_op_i == 1'b1) begin
        for (b = 0; b < DATA_W/8; b++) begin
          if (req_mask_i[b]) begin
            data_array[req_set][hit_way][req_word][b*8 +: 8] <= req_data_i[b*8 +: 8];
          end
        end
        dirty_array[req_set][hit_way] <= 1'b1;
      end

      // State machine
      case (state)
        IDLE: begin
          if (miss_count > 0) begin
            sel = '0;
            sel_found = 1'b0;
            for (i = 0; i < MAX_MISSES; i++) begin
              idx = rr_miss_ptr + i[MISS_IDX_W-1:0];
              if (idx >= MAX_MISSES) idx = idx - MAX_MISSES;
              if (miss_valid[idx] && !sel_found) begin
                sel = idx;
                sel_found = 1'b1;
              end
            end
            if (sel_found) begin
              set_idx = miss_block_addr[sel][BYTE_OFF_W+WORD_OFF_W +: SET_IDX_W];
              tag_val = miss_block_addr[sel][31:BYTE_OFF_W+WORD_OFF_W+SET_IDX_W];
              vway = '0;
              vfound = 1'b0;
              for (w = 0; w < WAYS; w++) begin
                if (!valid_array[set_idx][w] && !vfound) begin
                  vway = w[WAY_IDX_W-1:0];
                  vfound = 1'b1;
                end
              end
              if (!vfound) vway = rr_way[set_idx];

              current_miss_idx <= sel;
              current_block_addr <= miss_block_addr[sel];
              current_word_idx <= miss_word_idx[sel];
              current_id <= miss_id[sel];
              current_op <= miss_op[sel];
              current_data <= miss_data[sel];
              current_mask <= miss_mask[sel];
              current_set <= set_idx;
              current_tag <= tag_val;
              victim_way <= vway;

              vblock = valid_array[set_idx][vway] ?
                       {tag_array[set_idx][vway], set_idx, {(WORD_OFF_W+BYTE_OFF_W){1'b0}}} : 32'b0;
              victim_block_addr <= vblock;
              busy_addr <= vblock;
              busy_active <= 1'b1;

              if (valid_array[set_idx][vway] && dirty_array[set_idx][vway]) begin
                for (w = 0; w < BLOCK_WORDS; w++) begin
                  wb_buffer[w] <= data_array[set_idx][vway][w];
                end
                state <= WB_REQ;
              end else begin
                state <= FILL_REQ;
              end
              valid_array[set_idx][vway] <= 1'b0;
              rr_way[set_idx] <= (vway + 1) % WAYS;
              beat_cnt <= '0;
              load_data_reg <= '0;
            end
          end
        end

        WB_REQ: begin
          if (mem_req_ready_i) begin
            state <= WB_DATA;
            beat_cnt <= '0;
          end
        end

        WB_DATA: begin
          if (mem_wr_ready_i) begin
            if (beat_cnt == BLOCK_WORDS-1) begin
              state <= FILL_REQ;
              beat_cnt <= '0;
            end else begin
              beat_cnt <= beat_cnt + 1;
            end
          end
        end

        FILL_REQ: begin
          if (mem_req_ready_i) begin
            state <= FILL_DATA;
            beat_cnt <= '0;
          end
        end

        FILL_DATA: begin
          if (mem_rd_valid_i && mem_rd_ready_o) begin
            merged = mem_rd_data_i;
            if (current_op == 1'b1 && beat_cnt == current_word_idx) begin
              for (b = 0; b < DATA_W/8; b++) begin
                if (current_mask[b]) begin
                  merged[b*8 +: 8] = current_data[b*8 +: 8];
                end
              end
            end
            data_array[current_set][victim_way][beat_cnt] <= merged;
            if (beat_cnt == current_word_idx) begin
              load_data_reg <= mem_rd_data_i;
            end
            if (beat_cnt == BLOCK_WORDS-1) begin
              tag_array[current_set][victim_way] <= current_tag;
              valid_array[current_set][victim_way] <= 1'b1;
              dirty_array[current_set][victim_way] <= (current_op == 1'b1) ? 1'b1 : 1'b0;
              miss_valid[current_miss_idx] <= 1'b0;
              miss_count <= miss_count - 1;
              rr_miss_ptr <= (current_miss_idx + 1) % MAX_MISSES;
              busy_active <= 1'b0;
              state <= IDLE;
            end else begin
              beat_cnt <= beat_cnt + 1;
            end
          end
        end
      endcase
    end
  end

endmodule
