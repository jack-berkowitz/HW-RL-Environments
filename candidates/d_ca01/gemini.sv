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
  
  localparam int BYTE_OFFSET_W = $clog2(DATA_W / 8);
  localparam int WORD_W = 2; // clog2(4)
  localparam int SET_W = $clog2(SETS);
  localparam int TAG_W = 32 - SET_W - WORD_W - BYTE_OFFSET_W;

  // ---------------------------------------------------------------------------
  // Structures & Enums
  // ---------------------------------------------------------------------------
  typedef enum logic [2:0] {
      M_IDLE,
      M_PENDING,       // Waiting for Mem Arbiter
      M_MEM_ACTIVE,    // Owned by Mem Arbiter
      M_REPLAY         // Memory complete, waiting to update cache & respond
  } mshr_state_e;

  typedef struct {
      mshr_state_e state;
      logic [31:0] req_addr;
      logic [3:0]  req_id;
      logic        req_op;
      logic [DATA_W-1:0] req_data;
      logic [(DATA_W/8)-1:0] req_mask;
      logic [SET_W-1:0] set_idx;
      logic [$clog2(WAYS)-1:0] way_idx;
      logic [TAG_W-1:0] victim_tag;
      logic dirty_victim;
      logic [DATA_W-1:0] victim_buf [4];
      logic [DATA_W-1:0] fill_buf [4];
  } mshr_t;

  typedef enum logic [2:0] {
      MEM_IDLE,
      MEM_REQ_WB,
      MEM_DATA_WB,
      MEM_REQ_FILL,
      MEM_DATA_FILL
  } mem_fsm_e;

  // ---------------------------------------------------------------------------
  // State elements
  // ---------------------------------------------------------------------------
  logic                   valid_arr [SETS][WAYS];
  logic                   dirty_arr [SETS][WAYS];
  logic [TAG_W-1:0]       tag_arr   [SETS][WAYS];
  logic [DATA_W-1:0]      data_arr  [SETS][WAYS][4];
  logic [$clog2(WAYS)-1:0] rr_cnt   [SETS];

  mshr_t mshr [MAX_MISSES];

  mem_fsm_e mem_state;
  logic [$clog2(MAX_MISSES)-1:0] mem_mshr_idx;
  logic [$clog2(MAX_MISSES)-1:0] mem_rr_ptr;
  logic [2:0] mem_beat_cnt;

  // ---------------------------------------------------------------------------
  // Mask helper
  // ---------------------------------------------------------------------------
  function automatic logic [DATA_W-1:0] apply_mask(
      input logic [DATA_W-1:0] old_data,
      input logic [DATA_W-1:0] new_data,
      input logic [(DATA_W/8)-1:0] mask
  );
      logic [DATA_W-1:0] res;
      int i;
      for (i = 0; i < DATA_W/8; i = i + 1) begin
          if (mask[i])
              res[i*8 +: 8] = new_data[i*8 +: 8];
          else
              res[i*8 +: 8] = old_data[i*8 +: 8];
      end
      return res;
  endfunction

  // ---------------------------------------------------------------------------
  // Address Decoding
  // ---------------------------------------------------------------------------
  logic [WORD_W-1:0] req_word_idx;
  logic [SET_W-1:0]  req_set_idx;
  logic [TAG_W-1:0]  req_tag;
  logic [31:0]       req_block_addr;

  assign req_word_idx   = req_addr_i[BYTE_OFFSET_W +: WORD_W];
  assign req_set_idx    = req_addr_i[BYTE_OFFSET_W + WORD_W +: SET_W];
  assign req_tag        = req_addr_i[31 : 32-TAG_W];
  assign req_block_addr = req_addr_i & ~((1 << (WORD_W+BYTE_OFFSET_W)) - 1);

  // ---------------------------------------------------------------------------
  // Combinational status signals
  // ---------------------------------------------------------------------------
  logic cpu_hit;
  logic [$clog2(WAYS)-1:0] hit_way;

  logic mshr_conflict;
  logic mshr_idle_avail;
  logic [$clog2(MAX_MISSES)-1:0] alloc_idx;

  logic mshr_replay_req;
  logic [$clog2(MAX_MISSES)-1:0] replay_idx;

  always_comb begin
      int w;
      cpu_hit = 0;
      hit_way = 0;
      for (w = 0; w < WAYS; w = w + 1) begin
          if (valid_arr[req_set_idx][w] && tag_arr[req_set_idx][w] == req_tag) begin
              cpu_hit = 1;
              hit_way = w;
          end
      end
  end

  always_comb begin
      int i;
      logic [31:0] m_block_addr;
      mshr_conflict = 0;
      for (i = 0; i < MAX_MISSES; i = i + 1) begin
          if (mshr[i].state != M_IDLE) begin
              m_block_addr = mshr[i].req_addr & ~((1 << (WORD_W+BYTE_OFFSET_W)) - 1);
              if (m_block_addr == req_block_addr) begin
                  mshr_conflict = 1;
              end
          end
      end
  end

  always_comb begin
      int i;
      mshr_idle_avail = 0;
      alloc_idx = 0;
      for (i = 0; i < MAX_MISSES; i = i + 1) begin
          if (mshr[i].state == M_IDLE) begin
              mshr_idle_avail = 1;
              alloc_idx = i;
              break;
          end
      end
  end

  always_comb begin
      int i;
      mshr_replay_req = 0;
      replay_idx = 0;
      for (i = 0; i < MAX_MISSES; i = i + 1) begin
          if (mshr[i].state == M_REPLAY) begin
              mshr_replay_req = 1;
              replay_idx = i;
              break;
          end
      end
  end

  // ---------------------------------------------------------------------------
  // Cache Action Arbitration
  // ---------------------------------------------------------------------------
  logic do_replay;
  logic do_cpu_hit;
  logic do_cpu_miss;

  assign do_replay   = mshr_replay_req && rsp_ready_i;
  assign do_cpu_hit  = !mshr_replay_req && req_valid_i && !mshr_conflict && cpu_hit && rsp_ready_i;
  assign do_cpu_miss = !mshr_replay_req && req_valid_i && !mshr_conflict && !cpu_hit && mshr_idle_avail;

  assign req_ready_o =
      (mshr_conflict)   ? 1'b0 :
      (mshr_replay_req) ? 1'b0 : 
      (cpu_hit)         ? rsp_ready_i :
      (mshr_idle_avail);

  // ---------------------------------------------------------------------------
  // Outputs
  // ---------------------------------------------------------------------------
  always_comb begin
      rsp_valid_o = 0;
      rsp_id_o    = 0;
      rsp_data_o  = 0;

      if (mshr_replay_req) begin
          logic [WORD_W-1:0] w_idx;
          w_idx = mshr[replay_idx].req_addr[BYTE_OFFSET_W +: WORD_W];
          rsp_valid_o = 1;
          rsp_id_o    = mshr[replay_idx].req_id;
          rsp_data_o  = mshr[replay_idx].fill_buf[w_idx];
      end else if (!mshr_conflict && req_valid_i && cpu_hit) begin
          rsp_valid_o = 1;
          rsp_id_o    = req_id_i;
          rsp_data_o  = data_arr[req_set_idx][hit_way][req_word_idx];
      end
  end

  always_comb begin
      mem_req_valid_o = 0;
      mem_req_we_o    = 0;
      mem_req_addr_o  = 0;
      mem_rd_ready_o  = 0;
      mem_wr_valid_o  = 0;
      mem_wr_data_o   = 0;

      if (mem_state == MEM_REQ_WB) begin
          mem_req_valid_o = 1;
          mem_req_we_o    = 1;
          mem_req_addr_o  = {mshr[mem_mshr_idx].victim_tag, mshr[mem_mshr_idx].set_idx, {(WORD_W+BYTE_OFFSET_W){1'b0}}};
      end else if (mem_state == MEM_REQ_FILL) begin
          mem_req_valid_o = 1;
          mem_req_we_o    = 0;
          mem_req_addr_o  = mshr[mem_mshr_idx].req_addr & ~((1 << (WORD_W+BYTE_OFFSET_W)) - 1);
      end else if (mem_state == MEM_DATA_WB) begin
          mem_wr_valid_o  = 1;
          mem_wr_data_o   = mshr[mem_mshr_idx].victim_buf[mem_beat_cnt];
      end else if (mem_state == MEM_DATA_FILL) begin
          mem_rd_ready_o  = 1;
      end
  end

  // ---------------------------------------------------------------------------
  // Main Sequential Logic
  // ---------------------------------------------------------------------------
  always_ff @(posedge clk_i or negedge rst_ni) begin
      int s, w, i;
      logic [$clog2(WAYS)-1:0] vic_way;
      logic [WORD_W-1:0] rep_word_idx;

      logic mem_arb_found;
      int mem_arb_selected;
      int mem_arb_idx;

      if (!rst_ni) begin
          for (s = 0; s < SETS; s = s + 1) begin
              rr_cnt[s] <= 0;
              for (w = 0; w < WAYS; w = w + 1) begin
                  valid_arr[s][w] <= 0;
              end
          end
          for (i = 0; i < MAX_MISSES; i = i + 1) begin
              mshr[i].state <= M_IDLE;
          end
          mem_state <= MEM_IDLE;
          mem_rr_ptr <= 0;
      end else begin

          // ---- 1. Replay MSHR (Priority 1) ----
          if (do_replay) begin
              rep_word_idx = mshr[replay_idx].req_addr[BYTE_OFFSET_W +: WORD_W];

              for (w = 0; w < BLOCK_WORDS; w = w + 1) begin
                  if (w == rep_word_idx && mshr[replay_idx].req_op == 1'b1) begin
                      data_arr[mshr[replay_idx].set_idx][mshr[replay_idx].way_idx][w] <= apply_mask(
                          mshr[replay_idx].fill_buf[w],
                          mshr[replay_idx].req_data,
                          mshr[replay_idx].req_mask
                      );
                  end else begin
                      data_arr[mshr[replay_idx].set_idx][mshr[replay_idx].way_idx][w] <= mshr[replay_idx].fill_buf[w];
                  end
              end

              tag_arr[mshr[replay_idx].set_idx][mshr[replay_idx].way_idx]   <= mshr[replay_idx].req_addr[31 : 32-TAG_W];
              valid_arr[mshr[replay_idx].set_idx][mshr[replay_idx].way_idx] <= 1'b1;
              dirty_arr[mshr[replay_idx].set_idx][mshr[replay_idx].way_idx] <= mshr[replay_idx].req_op;

              mshr[replay_idx].state <= M_IDLE;
          end

          // ---- 2. CPU Actions (Priority 2) ----
          if (do_cpu_hit) begin
              if (req_op_i == 1'b1) begin
                  data_arr[req_set_idx][hit_way][req_word_idx] <= apply_mask(
                      data_arr[req_set_idx][hit_way][req_word_idx],
                      req_data_i,
                      req_mask_i
                  );
                  dirty_arr[req_set_idx][hit_way] <= 1'b1;
              end
          end else if (do_cpu_miss) begin
              vic_way = rr_cnt[req_set_idx];

              mshr[alloc_idx].state        <= M_PENDING;
              mshr[alloc_idx].req_addr     <= req_addr_i;
              mshr[alloc_idx].req_id       <= req_id_i;
              mshr[alloc_idx].req_op       <= req_op_i;
              mshr[alloc_idx].req_data     <= req_data_i;
              mshr[alloc_idx].req_mask     <= req_mask_i;
              mshr[alloc_idx].set_idx      <= req_set_idx;
              mshr[alloc_idx].way_idx      <= vic_way;
              mshr[alloc_idx].victim_tag   <= tag_arr[req_set_idx][vic_way];
              mshr[alloc_idx].dirty_victim <= valid_arr[req_set_idx][vic_way] && dirty_arr[req_set_idx][vic_way];

              for (w = 0; w < BLOCK_WORDS; w = w + 1) begin
                  mshr[alloc_idx].victim_buf[w] <= data_arr[req_set_idx][vic_way][w];
              end

              valid_arr[req_set_idx][vic_way] <= 1'b0;
              rr_cnt[req_set_idx] <= (rr_cnt[req_set_idx] == WAYS - 1) ? 0 : rr_cnt[req_set_idx] + 1;
          end

          // ---- 3. Memory Arbiter FSM ----
          case (mem_state)
              MEM_IDLE: begin
                  mem_arb_found = 0;
                  mem_arb_selected = 0;
                  for (i = 0; i < MAX_MISSES; i = i + 1) begin
                      mem_arb_idx = (mem_rr_ptr + i) % MAX_MISSES;
                      if (mshr[mem_arb_idx].state == M_PENDING) begin
                          mem_arb_found = 1;
                          mem_arb_selected = mem_arb_idx;
                          break;
                      end
                  end

                  if (mem_arb_found) begin
                      mem_mshr_idx <= mem_arb_selected;
                      mem_rr_ptr   <= (mem_arb_selected == MAX_MISSES - 1) ? 0 : mem_arb_selected + 1;
                      mshr[mem_arb_selected].state <= M_MEM_ACTIVE; 
                      if (mshr[mem_arb_selected].dirty_victim) begin
                          mem_state <= MEM_REQ_WB;
                      end else begin
                          mem_state <= MEM_REQ_FILL;
                      end
                      mem_beat_cnt <= 0;
                  end
              end

              MEM_REQ_WB: begin
                  if (mem_req_ready_i) begin
                      mem_state <= MEM_DATA_WB;
                      mem_beat_cnt <= 0;
                  end
              end

              MEM_DATA_WB: begin
                  if (mem_wr_ready_i) begin
                      if (mem_beat_cnt == BLOCK_WORDS - 1) begin
                          mem_state <= MEM_REQ_FILL;
                      end else begin
                          mem_beat_cnt <= mem_beat_cnt + 1;
                      end
                  end
              end

              MEM_REQ_FILL: begin
                  if (mem_req_ready_i) begin
                      mem_state <= MEM_DATA_FILL;
                      mem_beat_cnt <= 0;
                  end
              end

              MEM_DATA_FILL: begin
                  if (mem_rd_valid_i) begin
                      mshr[mem_mshr_idx].fill_buf[mem_beat_cnt] <= mem_rd_data_i;
                      if (mem_beat_cnt == BLOCK_WORDS - 1) begin
                          mem_state <= MEM_IDLE;
                          mshr[mem_mshr_idx].state <= M_REPLAY;
                      end else begin
                          mem_beat_cnt <= mem_beat_cnt + 1;
                      end
                  end
              end
          endcase
      end
  end

endmodule