// Nonblocking write-back / write-allocate cache.
// Pending misses are served fairly in FIFO order. Victims are selected only
// when a miss reaches the memory engine, so even same-set misses consume no
// reserved cache ways while queued. Resident hits bypass the miss FIFO.
module nonblocking_dcache #(
  parameter int unsigned DATA_W = 32,
  parameter int unsigned SETS = 16,
  parameter int unsigned WAYS = 4,
  parameter int unsigned MAX_MISSES = 8
) (
  input logic clk_i,
  input logic rst_ni,
  input logic req_valid_i,
  output logic req_ready_o,
  input logic [3:0] req_id_i,
  input logic req_op_i,
  input logic [31:0] req_addr_i,
  input logic [DATA_W-1:0] req_data_i,
  input logic [(DATA_W/8)-1:0] req_mask_i,
  output logic rsp_valid_o,
  input logic rsp_ready_i,
  output logic [3:0] rsp_id_o,
  output logic [DATA_W-1:0] rsp_data_o,
  output logic mem_req_valid_o,
  input logic mem_req_ready_i,
  output logic mem_req_we_o,
  output logic [31:0] mem_req_addr_o,
  input logic mem_rd_valid_i,
  output logic mem_rd_ready_o,
  input logic [DATA_W-1:0] mem_rd_data_i,
  output logic mem_wr_valid_o,
  input logic mem_wr_ready_i,
  output logic [DATA_W-1:0] mem_wr_data_o
);
  localparam int unsigned BLOCK_WORDS = 4;
  localparam int unsigned BYTE_W = DATA_W/8;
  localparam int unsigned BYTE_BITS = $clog2(BYTE_W);
  localparam int unsigned LINE_BITS = BYTE_BITS+2;
  localparam int unsigned SET_BITS = $clog2(SETS);
  localparam int unsigned WAY_BITS = $clog2(WAYS);
  localparam int unsigned TAG_BITS = 32-LINE_BITS-SET_BITS;
  localparam int unsigned MISS_BITS = $clog2(MAX_MISSES);

  logic [DATA_W-1:0] data_array [SETS][WAYS][BLOCK_WORDS];
  logic [TAG_BITS-1:0] tags [SETS][WAYS];
  logic valid_line [SETS][WAYS];
  logic dirty_line [SETS][WAYS];
  logic [WAY_BITS-1:0] replacement [SETS];

  // One store word per pending miss, never a block per miss. No fill or
  // writeback line buffers: both transactions access the locked array way.
  logic [MAX_MISSES-1:0] pending_valid;
  logic [31:0] pending_addr [MAX_MISSES];
  logic [3:0] pending_id [MAX_MISSES];
  logic pending_store [MAX_MISSES];
  logic [DATA_W-1:0] pending_data [MAX_MISSES];
  logic [BYTE_W-1:0] pending_mask [MAX_MISSES];
  logic [MISS_BITS-1:0] head_q, tail_q;
  logic [MISS_BITS:0] count_q;

  typedef enum logic [2:0] {IDLE, WB_REQUEST, WB_WORDS,
                           FILL_REQUEST, FILL_WORDS, COMPLETE} state_t;
  state_t state_q;
  logic [SET_BITS-1:0] active_set;
  logic [WAY_BITS-1:0] active_way;
  logic [1:0] beat_q;
  logic [31:0] writeback_addr;

  logic [SET_BITS-1:0] req_set, head_set;
  logic [TAG_BITS-1:0] req_tag;
  logic [1:0] req_word, head_word;
  logic [WAY_BITS-1:0] hit_way, victim_way;
  logic hit, pending_same_line, found_invalid;
  logic response_space, accept_hit, accept_miss, finish_miss;
  logic [DATA_W-1:0] fill_word;

  function automatic logic [DATA_W-1:0] merge_bytes(
    input logic [DATA_W-1:0] old_word,
    input logic [DATA_W-1:0] new_word,
    input logic [BYTE_W-1:0] mask
  );
    logic [DATA_W-1:0] result_word;
    begin
      result_word = old_word;
      for (int unsigned b=0;b<BYTE_W;b++)
        if (mask[b]) result_word[8*b +: 8] = new_word[8*b +: 8];
      return result_word;
    end
  endfunction

  assign req_set = req_addr_i[LINE_BITS +: SET_BITS];
  assign req_tag = req_addr_i[31 -: TAG_BITS];
  assign req_word = req_addr_i[BYTE_BITS +: 2];
  assign head_set = pending_addr[head_q][LINE_BITS +: SET_BITS];
  assign head_word = pending_addr[head_q][BYTE_BITS +: 2];
  assign response_space = !rsp_valid_o || rsp_ready_i;

  always_comb begin
    hit = 1'b0;
    hit_way = '0;
    for (int unsigned w=0;w<WAYS;w++) begin
      if (valid_line[req_set][w] && tags[req_set][w] == req_tag) begin
        hit = 1'b1;
        hit_way = WAY_BITS'(w);
      end
    end
    pending_same_line = 1'b0;
    for (int unsigned m=0;m<MAX_MISSES;m++) begin
      if (pending_valid[m] &&
          pending_addr[m][31:LINE_BITS] == req_addr_i[31:LINE_BITS])
        pending_same_line = 1'b1;
    end
    victim_way = replacement[head_set];
    found_invalid = 1'b0;
    for (int unsigned w=0;w<WAYS;w++) begin
      if (!valid_line[head_set][w] && !found_invalid) begin
        victim_way = WAY_BITS'(w);
        found_invalid = 1'b1;
      end
    end

    req_ready_o = 1'b0;
    if (rst_ni && !pending_same_line) begin
      if (hit) begin
        // Give allocation one array-control cycle and completion one response
        // opportunity. Continuous hits cannot starve the oldest miss.
        req_ready_o = response_space && state_q != COMPLETE &&
                      !(state_q == IDLE && count_q != 0);
      end else req_ready_o = count_q < (MISS_BITS+1)'(MAX_MISSES);
    end
  end
  assign accept_hit = req_valid_i && req_ready_o && hit;
  assign accept_miss = req_valid_i && req_ready_o && !hit;
  assign finish_miss = state_q == COMPLETE && response_space;

  // No new transaction is offered until the previous final beat has moved.
  // Request addresses and write data stay fixed through memory backpressure.
  always_comb begin
    mem_req_valid_o = rst_ni && (state_q == WB_REQUEST || state_q == FILL_REQUEST);
    mem_req_we_o = state_q == WB_REQUEST;
    mem_req_addr_o = state_q == WB_REQUEST ? writeback_addr :
      {pending_addr[head_q][31:LINE_BITS], {LINE_BITS{1'b0}}};
    mem_rd_ready_o = rst_ni && state_q == FILL_WORDS;
    mem_wr_valid_o = rst_ni && state_q == WB_WORDS;
    mem_wr_data_o = data_array[active_set][active_way][beat_q];
    fill_word = mem_rd_data_i;
    if (pending_store[head_q] && beat_q == head_word)
      fill_word = merge_bytes(mem_rd_data_i,pending_data[head_q],pending_mask[head_q]);
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      pending_valid <= '0;
      head_q <= '0; tail_q <= '0; count_q <= '0;
      state_q <= IDLE; active_set <= '0; active_way <= '0;
      beat_q <= '0; writeback_addr <= '0;
      rsp_valid_o <= 1'b0; rsp_id_o <= '0; rsp_data_o <= '0;
      // Only validity / bookkeeping require reset. Block data need not reset.
      for (int unsigned s=0;s<SETS;s++) begin
        replacement[s] <= '0;
        for (int unsigned w=0;w<WAYS;w++) begin
          valid_line[s][w] <= 1'b0;
          dirty_line[s][w] <= 1'b0;
        end
      end
    end else begin
      if (rsp_valid_o && rsp_ready_i) rsp_valid_o <= 1'b0;
      case ({accept_miss,finish_miss})
        2'b10: count_q <= count_q + 1'b1;
        2'b01: count_q <= count_q - 1'b1;
        default: count_q <= count_q;
      endcase
      if (accept_miss) begin
        pending_valid[tail_q] <= 1'b1;
        pending_addr[tail_q] <= req_addr_i;
        pending_id[tail_q] <= req_id_i;
        pending_store[tail_q] <= req_op_i;
        pending_data[tail_q] <= req_data_i;
        pending_mask[tail_q] <= req_mask_i;
        tail_q <= tail_q + 1'b1; // Both legal capacities are powers of two.
      end
      if (accept_hit) begin
        rsp_valid_o <= 1'b1;
        rsp_id_o <= req_id_i;
        rsp_data_o <= req_op_i ? '0 : data_array[req_set][hit_way][req_word];
        if (req_op_i) begin
          data_array[req_set][hit_way][req_word] <=
            merge_bytes(data_array[req_set][hit_way][req_word],req_data_i,req_mask_i);
          if (|req_mask_i) dirty_line[req_set][hit_way] <= 1'b1;
        end
      end
      case (state_q)
        IDLE: if (count_q != 0) begin
          active_set <= head_set;
          active_way <= victim_way;
          replacement[head_set] <= victim_way + 1'b1;
          beat_q <= 0;
          writeback_addr <= {tags[head_set][victim_way],head_set,{LINE_BITS{1'b0}}};
          // Lock the victim by invalidating it. Its data remain intact until
          // writeback finishes; no hit can modify a locked way.
          valid_line[head_set][victim_way] <= 1'b0;
          if (valid_line[head_set][victim_way] && dirty_line[head_set][victim_way])
            state_q <= WB_REQUEST;
          else state_q <= FILL_REQUEST;
        end
        WB_REQUEST: if (mem_req_ready_i) begin
          beat_q <= 0;
          state_q <= WB_WORDS;
        end
        WB_WORDS: if (mem_wr_ready_i) begin
          if (beat_q == 2'd3) begin
            beat_q <= 0;
            state_q <= FILL_REQUEST;
          end else beat_q <= beat_q + 1'b1;
        end
        FILL_REQUEST: if (mem_req_ready_i) begin
          beat_q <= 0;
          state_q <= FILL_WORDS;
        end
        FILL_WORDS: if (mem_rd_valid_i) begin
          data_array[active_set][active_way][beat_q] <= fill_word;
          if (beat_q == 2'd3) begin
            tags[active_set][active_way] <= pending_addr[head_q][31 -: TAG_BITS];
            valid_line[active_set][active_way] <= 1'b1;
            dirty_line[active_set][active_way] <= pending_store[head_q] && (|pending_mask[head_q]);
            state_q <= COMPLETE;
          end else beat_q <= beat_q + 1'b1;
        end
        COMPLETE: if (response_space) begin
          rsp_valid_o <= 1'b1;
          rsp_id_o <= pending_id[head_q];
          rsp_data_o <= pending_store[head_q] ? '0 : data_array[active_set][active_way][head_word];
          pending_valid[head_q] <= 1'b0;
          head_q <= head_q + 1'b1;
          state_q <= IDLE;
        end
        default: state_q <= IDLE;
      endcase
    end
  end
endmodule
