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

  // --------------------------------------------------------------------------
  // Address Slicing Constants
  // --------------------------------------------------------------------------
  localparam BYTE_OFFSET_BITS = $clog2(DATA_W / 8);
  localparam WORD_IDX_BITS    = $clog2(BLOCK_WORDS);
  localparam OFFSET_BITS      = BYTE_OFFSET_BITS + WORD_IDX_BITS;
  localparam INDEX_BITS       = $clog2(SETS);
  localparam TAG_BITS         = 32 - OFFSET_BITS - INDEX_BITS;

  // --------------------------------------------------------------------------
  // Type Definitions
  // --------------------------------------------------------------------------
  typedef enum logic [1:0] {
      ST_WAIT_MEM,
      ST_FILLING,
      ST_DONE_WAIT_RSP
  } mshr_state_t;

  typedef enum logic [2:0] {
      MEM_IDLE,
      MEM_FILL_REQ,
      MEM_FILL_DATA,
      MEM_INSTALL,
      MEM_WB_REQ,
      MEM_WB_DATA
  } mem_state_t;

  // --------------------------------------------------------------------------
  // Variable Declarations (Placed before ANY procedural blocks)
  // --------------------------------------------------------------------------
  logic [DATA_W-1:0]   data_array [SETS][WAYS][BLOCK_WORDS];
  logic [TAG_BITS-1:0] tag_array  [SETS][WAYS];
  logic                valid_array[SETS][WAYS];
  logic                dirty_array[SETS][WAYS];
  int unsigned         rr_ptr     [SETS];

  logic [MAX_MISSES-1:0]      mshr_valid;
  mshr_state_t                mshr_state      [MAX_MISSES];
  logic [31:0]                mshr_addr       [MAX_MISSES];
  logic [3:0]                 mshr_id         [MAX_MISSES];
  logic                       mshr_op         [MAX_MISSES];
  logic [WORD_IDX_BITS-1:0]   mshr_word_idx   [MAX_MISSES];
  logic [DATA_W-1:0]          mshr_data       [MAX_MISSES];
  logic [(DATA_W/8)-1:0]      mshr_mask       [MAX_MISSES];

  mem_state_t mem_state;
  int active_mshr_idx;
  int mem_word_cnt;

  logic [DATA_W-1:0] fill_buffer [BLOCK_WORDS];
  logic [DATA_W-1:0] wb_buffer   [BLOCK_WORDS];
  logic [31:0]       wb_addr_reg;

  logic rsp_buf_valid;
  logic [3:0] rsp_buf_id;
  logic [DATA_W-1:0] rsp_buf_data;

  logic [INDEX_BITS-1:0]    req_set;
  logic [TAG_BITS-1:0]      req_tag;
  logic [OFFSET_BITS-1:0]   req_offset;
  logic [WORD_IDX_BITS-1:0] req_word_idx;
  logic [31:0]              req_block_addr;

  logic is_hit;
  int hit_way_idx;

  logic mshr_match;
  logic mshr_full;
  int free_mshr_idx;

  logic rsp_q_full;
  logic mshr_wants_rsp;
  int mshr_rdy_idx;

  logic push_rsp;
  logic [3:0] push_id;
  logic [DATA_W-1:0] push_data;

  logic [INDEX_BITS-1:0] inst_set_idx;
  logic [TAG_BITS-1:0]   inst_tag_val;
  int                    inst_vic_way;

  // --------------------------------------------------------------------------
  // Combinational Assignments
  // --------------------------------------------------------------------------
  assign req_offset     = req_addr_i[OFFSET_BITS-1:0];
  assign req_set        = req_addr_i[OFFSET_BITS +: INDEX_BITS];
  assign req_tag        = req_addr_i[32-1 : 32-TAG_BITS];
  assign req_word_idx   = req_addr_i[BYTE_OFFSET_BITS +: WORD_IDX_BITS];
  assign req_block_addr = {req_addr_i[31:OFFSET_BITS], {OFFSET_BITS{1'b0}}};

  assign inst_set_idx = mshr_addr[active_mshr_idx][OFFSET_BITS +: INDEX_BITS];
  assign inst_tag_val = mshr_addr[active_mshr_idx][32-1 : 32-TAG_BITS];
  assign inst_vic_way = rr_ptr[inst_set_idx];

  assign rsp_valid_o = rsp_buf_valid;
  assign rsp_id_o    = rsp_buf_id;
  assign rsp_data_o  = rsp_buf_data;
  
  // Pipeline response queues dynamically
  assign rsp_q_full  = rsp_buf_valid && !rsp_ready_i;

  // Cache is ready when there's no structural hazard preventing request acceptance
  assign req_ready_o = !rsp_q_full && !mshr_match && (mem_state != MEM_INSTALL) &&
                       (is_hit ? !mshr_wants_rsp : !mshr_full);

  // --------------------------------------------------------------------------
  // Combinational Logic Blocks
  // --------------------------------------------------------------------------
  always_comb begin
      is_hit = 0;
      hit_way_idx = 0;
      for (int w = 0; w < WAYS; w++) begin
          if (valid_array[req_set][w] && tag_array[req_set][w] == req_tag) begin
              is_hit = 1;
              hit_way_idx = w;
          end
      end
  end

  always_comb begin
      mshr_match = 0;
      for (int i = 0; i < MAX_MISSES; i++) begin
          if (mshr_valid[i] && mshr_addr[i] == req_block_addr) begin
              mshr_match = 1;
          end
      end
  end

  always_comb begin
      mshr_full = 1;
      free_mshr_idx = 0;
      for (int i = 0; i < MAX_MISSES; i++) begin
          if (!mshr_valid[i]) begin
              mshr_full = 0;
              free_mshr_idx = i;
              break;
          end
      end
  end

  always_comb begin
      mshr_wants_rsp = 0;
      mshr_rdy_idx = 0;
      for (int i = 0; i < MAX_MISSES; i++) begin
          if (mshr_valid[i] && mshr_state[i] == ST_DONE_WAIT_RSP) begin
              mshr_wants_rsp = 1;
              mshr_rdy_idx = i;
              break;
          end
      end
  end

  always_comb begin
      push_rsp  = 0;
      push_id   = '0;
      push_data = '0;

      if (!rsp_q_full) begin
          if (mshr_wants_rsp) begin
              push_rsp  = 1;
              push_id   = mshr_id[mshr_rdy_idx];
              push_data = mshr_data[mshr_rdy_idx];
          end else if (req_valid_i && req_ready_o && is_hit) begin
              push_rsp = 1;
              push_id  = req_id_i;
              if (req_op_i == 0) begin // Load
                  push_data = data_array[req_set][hit_way_idx][req_word_idx];
              end // Store responses carry unconstrained data natively here
          end
      end
  end

  // --------------------------------------------------------------------------
  // Main Sequential Block
  // --------------------------------------------------------------------------
  always_ff @(posedge clk_i or negedge rst_ni) begin
      if (!rst_ni) begin
          mem_state <= MEM_IDLE;
          mem_req_valid_o <= 0;
          mem_rd_ready_o <= 0;
          mem_wr_valid_o <= 0;
          rsp_buf_valid <= 0;
          
          for (int i = 0; i < MAX_MISSES; i++) mshr_valid[i] <= 0;
          for (int s = 0; s < SETS; s++) begin
              rr_ptr[s] <= 0;
              for (int w = 0; w < WAYS; w++) begin
                  valid_array[s][w] <= 0;
                  dirty_array[s][w] <= 0;
              end
          end
      end else begin
          
          // 1. Response Queue Consumption
          if (rsp_buf_valid && rsp_ready_i) begin
              rsp_buf_valid <= 0;
          end

          // 2. Response Allocation
          if (push_rsp) begin
              rsp_buf_valid <= 1;
              rsp_buf_id    <= push_id;
              rsp_buf_data  <= push_data;
              if (mshr_wants_rsp) begin
                  mshr_valid[mshr_rdy_idx] <= 0;
              end
          end

          // 3. Front-End Incoming Requests
          if (req_valid_i && req_ready_o) begin
              if (is_hit) begin
                  if (req_op_i == 1) begin // Store logic
                      dirty_array[req_set][hit_way_idx] <= 1;
                      for (int b = 0; b < DATA_W/8; b++) begin
                          if (req_mask_i[b]) begin
                              data_array[req_set][hit_way_idx][req_word_idx][b*8 +: 8] <= req_data_i[b*8 +: 8];
                          end
                      end
                  end
              end else begin 
                  // Miss -> Allocate MSHR
                  mshr_valid[free_mshr_idx]    <= 1;
                  mshr_state[free_mshr_idx]    <= ST_WAIT_MEM;
                  mshr_addr[free_mshr_idx]     <= req_block_addr;
                  mshr_id[free_mshr_idx]       <= req_id_i;
                  mshr_op[free_mshr_idx]       <= req_op_i;
                  mshr_word_idx[free_mshr_idx] <= req_word_idx;
                  mshr_data[free_mshr_idx]     <= req_data_i;
                  mshr_mask[free_mshr_idx]     <= req_mask_i;
              end
          end

          // 4. Back-End Memory Controller
          case (mem_state)
              MEM_IDLE: begin
                  for (int i = 0; i < MAX_MISSES; i++) begin
                      if (mshr_valid[i] && mshr_state[i] == ST_WAIT_MEM) begin
                          active_mshr_idx <= i;
                          mshr_state[i]   <= ST_FILLING;
                          mem_state       <= MEM_FILL_REQ;
                          mem_req_valid_o <= 1;
                          mem_req_we_o    <= 0;
                          mem_req_addr_o  <= mshr_addr[i];
                          break;
                      end
                  end
              end
              MEM_FILL_REQ: begin
                  if (mem_req_ready_i && mem_req_valid_o) begin
                      mem_req_valid_o <= 0;
                      mem_state       <= MEM_FILL_DATA;
                      mem_rd_ready_o  <= 1;
                      mem_word_cnt    <= 0;
                  end
              end
              MEM_FILL_DATA: begin
                  if (mem_rd_valid_i && mem_rd_ready_o) begin
                      fill_buffer[mem_word_cnt] <= mem_rd_data_i;
                      if (mem_word_cnt == BLOCK_WORDS - 1) begin
                          mem_rd_ready_o <= 0;
                          mem_state      <= MEM_INSTALL;
                      end else begin
                          mem_word_cnt <= mem_word_cnt + 1;
                      end
                  end
              end
              MEM_INSTALL: begin
                  // Wait to identify an eviction victim upon installing a fill, completely resolving capacity limits
                  if (valid_array[inst_set_idx][inst_vic_way] && dirty_array[inst_set_idx][inst_vic_way]) begin
                      wb_addr_reg <= {tag_array[inst_set_idx][inst_vic_way], inst_set_idx, {OFFSET_BITS{1'b0}}};
                      for (int w = 0; w < BLOCK_WORDS; w++) begin
                          wb_buffer[w] <= data_array[inst_set_idx][inst_vic_way][w];
                      end
                      mem_state       <= MEM_WB_REQ;
                      mem_req_valid_o <= 1;
                      mem_req_we_o    <= 1;
                      mem_req_addr_o  <= {tag_array[inst_set_idx][inst_vic_way], inst_set_idx, {OFFSET_BITS{1'b0}}};
                  end else begin
                      mem_state <= MEM_IDLE;
                  end

                  // Install and tag cache block
                  valid_array[inst_set_idx][inst_vic_way] <= 1;
                  dirty_array[inst_set_idx][inst_vic_way] <= (mshr_op[active_mshr_idx] == 1);
                  tag_array[inst_set_idx][inst_vic_way]   <= inst_tag_val;

                  for (int w = 0; w < BLOCK_WORDS; w++) begin
                      if (w == mshr_word_idx[active_mshr_idx] && mshr_op[active_mshr_idx] == 1) begin
                          for (int b = 0; b < DATA_W/8; b++) begin
                              if (mshr_mask[active_mshr_idx][b]) begin
                                  data_array[inst_set_idx][inst_vic_way][w][b*8 +: 8] <= mshr_data[active_mshr_idx][b*8 +: 8];
                              end else begin
                                  data_array[inst_set_idx][inst_vic_way][w][b*8 +: 8] <= fill_buffer[w][b*8 +: 8];
                              end
                          end
                      end else begin
                          data_array[inst_set_idx][inst_vic_way][w] <= fill_buffer[w];
                      end
                  end

                  // Update MSHR state allowing downstream responses
                  mshr_state[active_mshr_idx] <= ST_DONE_WAIT_RSP;
                  if (mshr_op[active_mshr_idx] == 0) begin
                      mshr_data[active_mshr_idx] <= fill_buffer[mshr_word_idx[active_mshr_idx]];
                  end

                  if (rr_ptr[inst_set_idx] == WAYS - 1) begin
                      rr_ptr[inst_set_idx] <= 0;
                  end else begin
                      rr_ptr[inst_set_idx] <= rr_ptr[inst_set_idx] + 1;
                  end
              end
              MEM_WB_REQ: begin
                  if (mem_req_ready_i && mem_req_valid_o) begin
                      mem_req_valid_o <= 0;
                      mem_state       <= MEM_WB_DATA;
                      mem_wr_valid_o  <= 1;
                      mem_word_cnt    <= 0;
                      mem_wr_data_o   <= wb_buffer[0];
                  end
              end
              MEM_WB_DATA: begin
                  if (mem_wr_ready_i && mem_wr_valid_o) begin
                      if (mem_word_cnt == BLOCK_WORDS - 1) begin
                          mem_wr_valid_o <= 0;
                          mem_state      <= MEM_IDLE;
                      end else begin
                          mem_word_cnt  <= mem_word_cnt + 1;
                          mem_wr_data_o <= wb_buffer[mem_word_cnt + 1];
                      end
                  end
              end
              default: mem_state <= MEM_IDLE;
          endcase
      end
  end

endmodule