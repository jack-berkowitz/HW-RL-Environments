// =============================================================================
// Task: nonblocking_dcache
// =============================================================================

module nonblocking_dcache #(
  parameter int unsigned DATA_W     = 32,   // {32, 64}
  parameter int unsigned SETS       = 16,   // {8, 16}
  parameter int unsigned WAYS       = 4,    // {2, 4}
  parameter int unsigned MAX_MISSES = 8     // {2, 8}
) (
  input  logic                     clk_i,
  input  logic                     rst_ni,

  // ---- request ------------------------------------------------------------
  input  logic                     req_valid_i,
  output logic                     req_ready_o,
  input  logic [3:0]               req_id_i,
  input  logic                     req_op_i,
  input  logic [31:0]              req_addr_i,
  input  logic [DATA_W-1:0]        req_data_i,
  input  logic [(DATA_W/8)-1:0]    req_mask_i,

  // ---- response -----------------------------------------------------------
  output logic                     rsp_valid_o,
  input  logic                     rsp_ready_i,
  output logic [3:0]               rsp_id_o,
  output logic [DATA_W-1:0]        rsp_data_o,

  // ---- memory: request ----------------------------------------------------
  output logic                     mem_req_valid_o,
  input  logic                     mem_req_ready_i,
  output logic                     mem_req_we_o,
  output logic [31:0]              mem_req_addr_o,

  // ---- memory: fill data in ----------------------------------------------
  input  logic                     mem_rd_valid_i,
  output logic                     mem_rd_ready_o,
  input  logic [DATA_W-1:0]        mem_rd_data_i,

  // ---- memory: writeback data out ----------------------------------------
  output logic                     mem_wr_valid_o,
  input  logic                     mem_wr_ready_i,
  output logic [DATA_W-1:0]        mem_wr_data_o
);

  localparam int unsigned BLOCK_WORDS = 4;
  localparam int unsigned BYTE_BITS   = $clog2(DATA_W / 8);
  localparam int unsigned OFFSET_BITS = BYTE_BITS + $clog2(BLOCK_WORDS);
  localparam int unsigned SET_BITS    = $clog2(SETS);
  localparam int unsigned TAG_BITS    = 32 - SET_BITS - OFFSET_BITS;
  localparam int unsigned WAY_BITS    = $clog2(WAYS);

  // ---------------------------------------------------------------------------
  // Types
  // ---------------------------------------------------------------------------
  typedef struct packed {
    logic valid;
    logic dirty;
    logic [TAG_BITS-1:0] tag;
  } tag_t;

  typedef enum logic [1:0] {
    R_IDLE,
    R_ISSUE,
    R_MISS,
    R_DONE
  } req_state_t;

  typedef struct packed {
    logic valid;
    logic [4:0] seq;
    logic op;
    logic [31:0] addr;
    logic [DATA_W-1:0] data;
    logic [(DATA_W/8)-1:0] mask;
    req_state_t state;
    logic [DATA_W-1:0] rsp_data;
  } req_entry_t;

  typedef enum logic [2:0] {
    M_IDLE,
    M_EVICT_REQ,
    M_EVICT_DATA,
    M_FILL_REQ,
    M_FILL_DATA,
    M_FILL_WRITE_CACHE
  } mem_state_t;

  // ---------------------------------------------------------------------------
  // Helper Functions
  // ---------------------------------------------------------------------------
  function automatic logic [SET_BITS-1:0] get_set(input logic [31:0] addr);
    return (addr >> OFFSET_BITS) & ((1 << SET_BITS) - 1);
  endfunction

  function automatic logic [TAG_BITS-1:0] get_tag(input logic [31:0] addr);
    return (addr >> (OFFSET_BITS + SET_BITS));
  endfunction

  function automatic logic [31-OFFSET_BITS:0] get_block(input logic [31:0] addr);
    return (addr >> OFFSET_BITS);
  endfunction

  function automatic logic is_older(input logic [4:0] a, input logic [4:0] b);
    logic [4:0] diff;
    diff = b - a;
    return (diff > 0) && (diff <= 16);
  endfunction

  function automatic logic [31:0] make_addr(input logic [TAG_BITS-1:0] tag, input logic [SET_BITS-1:0] set);
    logic [31:0] res;
    res = '0;
    res = (tag << (SET_BITS + OFFSET_BITS)) | (set << OFFSET_BITS);
    return res;
  endfunction

  // ---------------------------------------------------------------------------
  // State Elements
  // ---------------------------------------------------------------------------
  tag_t tags [SETS][WAYS];
  logic [BLOCK_WORDS*DATA_W-1:0] data_array [SETS][WAYS];
  logic [WAY_BITS-1:0] rr_ptr [SETS];

  req_entry_t req_q [16];
  logic [4:0] seq_counter;

  mem_state_t mem_fsm;
  logic [3:0] mem_req_id;
  logic [SET_BITS-1:0] mem_miss_set;
  logic [TAG_BITS-1:0] mem_miss_tag;
  logic [WAY_BITS-1:0] mem_victim_way;
  logic mem_victim_dirty;
  logic [31:0] mem_victim_addr;
  logic [BLOCK_WORDS*DATA_W-1:0] mem_victim_data;
  logic [BLOCK_WORDS*DATA_W-1:0] mem_fill_data;
  logic [1:0] word_count;

  // ---------------------------------------------------------------------------
  // Logic
  // ---------------------------------------------------------------------------

  // Acceptance logic
  assign req_ready_o = !req_q[req_id_i].valid;

  // Safe to Issue / Ordering Check
  logic [15:0] safe_to_issue;
  always_comb begin
    for (int i = 0; i < 16; i++) begin
      safe_to_issue[i] = 1'b1;
      for (int j = 0; j < 16; j++) begin
        if (req_q[j].valid && (req_q[j].state == R_ISSUE || req_q[j].state == R_MISS) && (i != j)) begin
          if (get_block(req_q[i].addr) == get_block(req_q[j].addr)) begin
            if (is_older(req_q[j].seq, req_q[i].seq)) begin
              safe_to_issue[i] = 1'b0;
            end
          end
        end
      end
    end
  end

  // Best Issue Arbitration
  logic [15:0] issue_cands;
  logic [3:0] best_issue_id;
  logic has_issue;
  always_comb begin
    has_issue = 1'b0;
    best_issue_id = '0;
    for (int i = 0; i < 16; i++) begin
      issue_cands[i] = req_q[i].valid && (req_q[i].state == R_ISSUE) && safe_to_issue[i];
    end
    for (int i = 0; i < 16; i++) begin
      if (issue_cands[i]) begin
        if (!has_issue || is_older(req_q[i].seq, req_q[best_issue_id].seq)) begin
          has_issue = 1'b1;
          best_issue_id = i[3:0];
        end
      end
    end
  end

  // Cache Access Signals
  logic [SET_BITS-1:0] issue_set;
  logic [TAG_BITS-1:0] issue_tag;
  logic [1:0]          issue_word;
  logic                issue_hit;
  logic [WAY_BITS-1:0] issue_hit_way;

  always_comb begin
    issue_set  = get_set(req_q[best_issue_id].addr);
    issue_tag  = get_tag(req_q[best_issue_id].addr);
    issue_word = (req_q[best_issue_id].addr >> BYTE_BITS) & 2'b11;

    issue_hit = 1'b0;
    issue_hit_way = '0;
    for (int w = 0; w < WAYS; w++) begin
      if (tags[issue_set][w].valid && tags[issue_set][w].tag == issue_tag) begin
        issue_hit = 1'b1;
        issue_hit_way = w[WAY_BITS-1:0];
      end
    end
  end

  // Store RMW calculation (combinational)
  logic [BLOCK_WORDS*DATA_W-1:0] next_data_array_line;
  always_comb begin
    logic [DATA_W-1:0] wdata_comb;
    next_data_array_line = data_array[issue_set][issue_hit_way];
    wdata_comb = next_data_array_line[issue_word * DATA_W +: DATA_W];
    for (int b = 0; b < DATA_W/8; b++) begin
      if (req_q[best_issue_id].mask[b]) begin
        wdata_comb[b*8 +: 8] = req_q[best_issue_id].data[b*8 +: 8];
      end
    end
    if (has_issue && issue_hit && req_q[best_issue_id].op == 1'b1) begin
      next_data_array_line[issue_word * DATA_W +: DATA_W] = wdata_comb;
    end
  end

  // Memory Miss Arbitration
  logic [3:0] best_miss_id;
  logic       has_miss;
  always_comb begin
    has_miss = 1'b0;
    best_miss_id = '0;
    for (int i = 0; i < 16; i++) begin
      if (req_q[i].valid && (req_q[i].state == R_MISS)) begin
        if (!has_miss || is_older(req_q[i].seq, req_q[best_miss_id].seq)) begin
          has_miss = 1'b1;
          best_miss_id = i[3:0];
        end
      end
    end
  end

  // Pipeline Arbitration
  logic mem_wants_write;
  logic mem_wants_read;
  logic pipeline_en;
  assign mem_wants_write = (mem_fsm == M_FILL_WRITE_CACHE);
  assign mem_wants_read  = (mem_fsm == M_IDLE && has_miss);
  assign pipeline_en     = has_issue && !mem_wants_write && !mem_wants_read;

  // Output / Response Arbitration
  logic [3:0] best_done_id;
  logic       has_done;
  always_comb begin
    has_done = 1'b0;
    best_done_id = '0;
    for (int i = 0; i < 16; i++) begin
      if (req_q[i].valid && req_q[i].state == R_DONE) begin
        if (!has_done || is_older(req_q[i].seq, req_q[best_done_id].seq)) begin
          has_done = 1'b1;
          best_done_id = i[3:0];
        end
      end
    end
  end

  assign rsp_valid_o = has_done;
  assign rsp_id_o    = best_done_id;
  assign rsp_data_o  = req_q[best_done_id].rsp_data;

  // Memory interface combinational bindings
  logic [31:0] mem_miss_addr;
  assign mem_miss_addr   = make_addr(mem_miss_tag, mem_miss_set);
  assign mem_req_valid_o = (mem_fsm == M_EVICT_REQ) || (mem_fsm == M_FILL_REQ);
  assign mem_req_we_o    = (mem_fsm == M_EVICT_REQ);
  assign mem_req_addr_o  = (mem_fsm == M_EVICT_REQ) ? mem_victim_addr : mem_miss_addr;
  assign mem_wr_valid_o  = (mem_fsm == M_EVICT_DATA);
  assign mem_wr_data_o   = mem_victim_data[word_count * DATA_W +: DATA_W];
  assign mem_rd_ready_o  = (mem_fsm == M_FILL_DATA);

  // ---------------------------------------------------------------------------
  // Sequential Logic
  // ---------------------------------------------------------------------------
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      for (int s = 0; s < SETS; s++) begin
        for (int w = 0; w < WAYS; w++) begin
          tags[s][w].valid <= 1'b0;
        end
        rr_ptr[s] <= '0;
      end
      for (int i = 0; i < 16; i++) begin
        req_q[i].valid <= 1'b0;
      end
      seq_counter <= '0;
      mem_fsm     <= M_IDLE;
      word_count  <= '0;
    end else begin

      // 1. Memory FSM
      case (mem_fsm)
        M_IDLE: begin
          if (has_miss) begin
            logic [SET_BITS-1:0] m_set;
            logic [WAY_BITS-1:0] m_way;
            m_set = get_set(req_q[best_miss_id].addr);
            m_way = rr_ptr[m_set];

            mem_req_id <= best_miss_id;
            mem_miss_set <= m_set;
            mem_miss_tag <= get_tag(req_q[best_miss_id].addr);

            mem_victim_way <= m_way;
            mem_victim_dirty <= tags[m_set][m_way].valid && tags[m_set][m_way].dirty;
            mem_victim_addr <= make_addr(tags[m_set][m_way].tag, m_set);
            mem_victim_data <= data_array[m_set][m_way];

            rr_ptr[m_set] <= rr_ptr[m_set] + 1'b1;

            if (tags[m_set][m_way].valid && tags[m_set][m_way].dirty) begin
              mem_fsm <= M_EVICT_REQ;
            end else begin
              mem_fsm <= M_FILL_REQ;
            end
          end
        end
        M_EVICT_REQ: begin
          if (mem_req_ready_i) mem_fsm <= M_EVICT_DATA;
        end
        M_EVICT_DATA: begin
          if (mem_wr_ready_i) begin
            if (word_count == BLOCK_WORDS - 1) begin
              word_count <= '0;
              mem_fsm <= M_FILL_REQ;
            end else begin
              word_count <= word_count + 1'b1;
            end
          end
        end
        M_FILL_REQ: begin
          if (mem_req_ready_i) mem_fsm <= M_FILL_DATA;
        end
        M_FILL_DATA: begin
          if (mem_rd_valid_i) begin
            mem_fill_data[word_count * DATA_W +: DATA_W] <= mem_rd_data_i;
            if (word_count == BLOCK_WORDS - 1) begin
              word_count <= '0;
              mem_fsm <= M_FILL_WRITE_CACHE;
            end else begin
              word_count <= word_count + 1'b1;
            end
          end
        end
        M_FILL_WRITE_CACHE: begin
          data_array[mem_miss_set][mem_victim_way] <= mem_fill_data;
          tags[mem_miss_set][mem_victim_way].valid <= 1'b1;
          tags[mem_miss_set][mem_victim_way].dirty <= 1'b0;
          tags[mem_miss_set][mem_victim_way].tag   <= mem_miss_tag;

          req_q[mem_req_id].state <= R_ISSUE;
          mem_fsm <= M_IDLE;
        end
      endcase

      // 2. Cache Pipeline Execute
      if (pipeline_en) begin
        if (issue_hit) begin
          if (req_q[best_issue_id].op == 1'b0) begin // LOAD
            req_q[best_issue_id].rsp_data <= next_data_array_line[issue_word * DATA_W +: DATA_W];
          end else begin // STORE
            data_array[issue_set][issue_hit_way] <= next_data_array_line;
            tags[issue_set][issue_hit_way].dirty <= 1'b1;
            req_q[best_issue_id].rsp_data <= '0;
          end
          req_q[best_issue_id].state <= R_DONE;
        end else begin
          req_q[best_issue_id].state <= R_MISS;
        end
      end

      // 3. Retire Responses
      if (rsp_valid_o && rsp_ready_i) begin
        req_q[best_done_id].valid <= 1'b0;
      end

      // 4. Accept New Requests
      if (req_valid_i && req_ready_o) begin
        req_q[req_id_i].valid <= 1'b1;
        req_q[req_id_i].seq   <= seq_counter;
        seq_counter           <= seq_counter + 1'b1;
        req_q[req_id_i].op    <= req_op_i;
        req_q[req_id_i].addr  <= req_addr_i;
        req_q[req_id_i].data  <= req_data_i;
        req_q[req_id_i].mask  <= req_mask_i;
        req_q[req_id_i].state <= R_ISSUE;
      end

    end
  end

endmodule