// =============================================================================
// nonblocking_dcache.sv
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

  // ---------------------------------------------------------------------------
  // Cache Arrays
  // ---------------------------------------------------------------------------
  logic [31:0]       tag_array   [SETS][WAYS];
  logic              valid_array [SETS][WAYS];
  logic              dirty_array [SETS][WAYS];
  logic [DATA_W-1:0] data_array  [SETS][WAYS][4];
  logic [$clog2(WAYS)-1:0] rr_counter  [SETS];

  // ---------------------------------------------------------------------------
  // Writeback Buffer (Max 1 Cache Line per C4)
  // ---------------------------------------------------------------------------
  logic              wb_valid;
  logic [31:0]       wb_addr;
  logic [DATA_W-1:0] wb_data [4];

  // ---------------------------------------------------------------------------
  // MSHRs (Max MAX_MISSES distinct lines per C1)
  // ---------------------------------------------------------------------------
  typedef enum logic [1:0] {
      MSHR_FREE,
      MSHR_WAIT_MEM_REQ,
      MSHR_FETCHING,
      MSHR_REPLAYING
  } mshr_state_e;

  mshr_state_e             mshr_state      [MAX_MISSES];
  logic [31:0]             mshr_addr       [MAX_MISSES];
  logic [$clog2(WAYS)-1:0] mshr_way        [MAX_MISSES];
  logic                    mshr_has_store  [MAX_MISSES];
  logic [DATA_W-1:0]       mshr_store_data [MAX_MISSES];
  logic [(DATA_W/8)-1:0]   mshr_store_mask [MAX_MISSES];

  // ---------------------------------------------------------------------------
  // Pending Request Tracking (indexed by req_id_i)
  // ---------------------------------------------------------------------------
  logic                            pending_valid    [16];
  logic [$clog2(MAX_MISSES)-1:0]   pending_mshr_idx [16];
  logic                            pending_op       [16];
  logic [1:0]                      pending_word     [16];
  logic [31:0]                     pending_seq      [16];
  logic [31:0]                     global_seq;

  // ---------------------------------------------------------------------------
  // Memory Controller State
  // ---------------------------------------------------------------------------
  typedef enum logic [1:0] {
      MEM_IDLE,
      MEM_WB_REQ,
      MEM_WB_DATA,
      MEM_FILL_REQ,
      MEM_FILL_DATA
  } mem_state_e;

  mem_state_e                      mem_state;
  logic [1:0]                      mem_beat_cnt;
  logic [$clog2(MAX_MISSES)-1:0]   active_fill_mshr;
  logic [DATA_W-1:0]               fill_buffer [4];

  logic                            fill_write_en;
  logic [$clog2(MAX_MISSES)-1:0]   fill_write_mshr;

  // ---------------------------------------------------------------------------
  // Stage 1 Pipeline Registers
  // ---------------------------------------------------------------------------
  logic                  s1_valid;
  logic [3:0]            s1_id;
  logic                  s1_op;
  logic [31:0]           s1_addr;
  logic [DATA_W-1:0]     s1_data;
  logic [(DATA_W/8)-1:0] s1_mask;

  logic [$clog2(SETS)-1:0] s1_set;
  logic [27:0]             s1_tag;
  assign s1_set = s1_addr[4 +: $clog2(SETS)];
  assign s1_tag = s1_addr[31:4];

  // ---------------------------------------------------------------------------
  // Stage 1 Hit Detection
  // ---------------------------------------------------------------------------
  logic hit;
  logic [$clog2(WAYS)-1:0] hit_way_idx;

  always_comb begin
      integer w;
      hit = 0;
      hit_way_idx = 0;
      for (w=0; w<WAYS; w=w+1) begin
          if (valid_array[s1_set][w] && tag_array[s1_set][w][31:4] == s1_tag) begin
              hit = 1;
              hit_way_idx = w;
          end
      end
  end

  // ---------------------------------------------------------------------------
  // MSHR Allocation & Collision Checking
  // ---------------------------------------------------------------------------
  logic alloc_mshr_valid;
  logic [$clog2(MAX_MISSES)-1:0] alloc_mshr_idx;

  always_comb begin
      integer i;
      alloc_mshr_valid = 0;
      alloc_mshr_idx = 0;
      for (i=0; i<MAX_MISSES; i=i+1) begin
          if (mshr_state[i] == MSHR_FREE) begin
              alloc_mshr_valid = 1;
              alloc_mshr_idx = i;
              break;
          end
      end
  end

  logic same_line_miss;
  logic [$clog2(MAX_MISSES)-1:0] same_line_mshr_idx;
  logic same_line_stall;

  always_comb begin
      integer i;
      same_line_miss = 0;
      same_line_mshr_idx = 0;
      same_line_stall = 0;
      for (i=0; i<MAX_MISSES; i=i+1) begin
          if (mshr_state[i] != MSHR_FREE && mshr_addr[i][31:4] == s1_addr[31:4]) begin
              same_line_miss = 1;
              same_line_mshr_idx = i;
              if (mshr_state[i] == MSHR_REPLAYING) begin
                  same_line_stall = 1;
              end else if (s1_op == 1 && mshr_has_store[i]) begin
                  same_line_stall = 1;
              end
          end
      end
  end

  logic [$clog2(WAYS)-1:0] victim_way_idx;
  logic victim_dirty;
  assign victim_way_idx = rr_counter[s1_set];
  assign victim_dirty = valid_array[s1_set][victim_way_idx] && dirty_array[s1_set][victim_way_idx];

  logic s1_can_allocate;
  assign s1_can_allocate = (same_line_miss && !same_line_stall) || 
                           (!same_line_miss && alloc_mshr_valid && (!victim_dirty || !wb_valid));

  // ---------------------------------------------------------------------------
  // Replay Arbiter (Selects oldest ready pending request)
  // ---------------------------------------------------------------------------
  logic replay_valid;
  logic [3:0] replay_id;

  always_comb begin
      integer i;
      logic [31:0] min_seq;
      replay_valid = 0;
      replay_id = 0;
      min_seq = '1;
      for (i=0; i<16; i=i+1) begin
          if (pending_valid[i] && mshr_state[pending_mshr_idx[i]] == MSHR_REPLAYING) begin
              if (pending_seq[i] <= min_seq) begin
                  replay_valid = 1;
                  replay_id = i;
                  min_seq = pending_seq[i];
              end
          end
      end
  end

  logic [$clog2(MAX_MISSES)-1:0] rep_mshr;
  logic rep_op;
  logic [$clog2(SETS)-1:0] rep_set;
  logic [$clog2(WAYS)-1:0] rep_way;
  logic [1:0] rep_word;

  assign rep_mshr = pending_mshr_idx[replay_id];
  assign rep_op   = pending_op[replay_id];
  assign rep_set  = mshr_addr[rep_mshr][4 +: $clog2(SETS)];
  assign rep_way  = mshr_way[rep_mshr];
  assign rep_word = pending_word[replay_id];

  // ---------------------------------------------------------------------------
  // Response Arbitration
  // ---------------------------------------------------------------------------
  logic replay_fire;
  logic s1_hit_fire;
  logic s1_miss_fire;
  logic s1_stall;

  assign replay_fire = replay_valid && rsp_ready_i;
  assign s1_hit_fire = s1_valid && hit && !replay_valid && rsp_ready_i && (!fill_write_en || s1_op == 0);
  assign s1_miss_fire = s1_valid && !hit && s1_can_allocate;
  assign s1_stall = s1_valid && !(s1_hit_fire || s1_miss_fire);

  assign req_ready_o = !s1_valid || !s1_stall;

  assign rsp_valid_o = replay_valid ? 1'b1 :
                       (s1_valid && hit && (!fill_write_en || s1_op == 0)) ? 1'b1 : 1'b0;
  
  assign rsp_id_o    = replay_valid ? replay_id : s1_id;

  assign rsp_data_o  = replay_valid ? 
                       (rep_op == 1 ? '0 : data_array[rep_set][rep_way][rep_word]) :
                       (s1_op == 1 ? '0 : data_array[s1_set][hit_way_idx][s1_addr[3:2]]);

  // ---------------------------------------------------------------------------
  // MSHR Pending Tracker
  // ---------------------------------------------------------------------------
  logic mshr_has_pending [MAX_MISSES];
  always_comb begin
      integer m, i;
      for (m=0; m<MAX_MISSES; m=m+1) begin
          mshr_has_pending[m] = 0;
          for (i=0; i<16; i=i+1) begin
              if (pending_valid[i] && pending_mshr_idx[i] == m) begin
                  if (!(replay_fire && replay_id == i)) begin
                      mshr_has_pending[m] = 1;
                  end
              end
          end
      end
  end

  // ---------------------------------------------------------------------------
  // Write Port Combinational Prep
  // ---------------------------------------------------------------------------
  logic [DATA_W-1:0] rep_mod_data;
  logic [DATA_W-1:0] s1_mod_data;

  always_comb begin
      integer b;
      rep_mod_data = data_array[rep_set][rep_way][rep_word];
      for (b=0; b<DATA_W/8; b=b+1) begin
          if (mshr_store_mask[rep_mshr][b]) begin
              rep_mod_data[b*8 +: 8] = mshr_store_data[rep_mshr][b*8 +: 8];
          end
      end
      
      s1_mod_data = data_array[s1_set][hit_way_idx][s1_addr[3:2]];
      for (b=0; b<DATA_W/8; b=b+1) begin
          if (s1_mask[b]) begin
              s1_mod_data[b*8 +: 8] = s1_data[b*8 +: 8];
          end
      end
  end

  // ---------------------------------------------------------------------------
  // Sequential Pipeline & State Machines
  // ---------------------------------------------------------------------------
  always_ff @(posedge clk_i or negedge rst_ni) begin
      integer s, w, i, m;
      if (!rst_ni) begin
          s1_valid <= 0;
          mem_state <= MEM_IDLE;
          mem_beat_cnt <= 0;
          wb_valid <= 0;
          global_seq <= 0;
          fill_write_en <= 0;
          
          for (i=0; i<MAX_MISSES; i=i+1) begin
              mshr_state[i] <= MSHR_FREE;
          end
          for (i=0; i<16; i=i+1) begin
              pending_valid[i] <= 0;
          end
          for (s=0; s<SETS; s=s+1) begin
              rr_counter[s] <= 0;
              for (w=0; w<WAYS; w=w+1) begin
                  valid_array[s][w] <= 0;
              end
          end
      end else begin
          
          // ---- Stage 1 Request Intake ----
          if (req_ready_o) begin
              s1_valid <= req_valid_i;
              s1_id    <= req_id_i;
              s1_op    <= req_op_i;
              s1_addr  <= req_addr_i;
              s1_data  <= req_data_i;
              s1_mask  <= req_mask_i;
          end else if (s1_hit_fire || s1_miss_fire) begin
              s1_valid <= 0;
          end
          
          // ---- MSHR Allocation and Hit Processing ----
          if (s1_miss_fire) begin
              if (!same_line_miss) begin
                  if (victim_dirty) begin
                      wb_valid <= 1;
                      wb_addr <= tag_array[s1_set][victim_way_idx];
                      wb_data[0] <= data_array[s1_set][victim_way_idx][0];
                      wb_data[1] <= data_array[s1_set][victim_way_idx][1];
                      wb_data[2] <= data_array[s1_set][victim_way_idx][2];
                      wb_data[3] <= data_array[s1_set][victim_way_idx][3];
                  end
                  
                  valid_array[s1_set][victim_way_idx] <= 0;
                  rr_counter[s1_set] <= rr_counter[s1_set] + 1;
                  
                  mshr_state[alloc_mshr_idx] <= MSHR_WAIT_MEM_REQ;
                  mshr_addr[alloc_mshr_idx] <= {s1_addr[31:4], 4'b0000};
                  mshr_way[alloc_mshr_idx] <= victim_way_idx;
                  
                  if (s1_op == 1) begin
                      mshr_has_store[alloc_mshr_idx] <= 1;
                      mshr_store_data[alloc_mshr_idx] <= s1_data;
                      mshr_store_mask[alloc_mshr_idx] <= s1_mask;
                  end else begin
                      mshr_has_store[alloc_mshr_idx] <= 0;
                  end
                  
                  pending_mshr_idx[s1_id] <= alloc_mshr_idx;
              end else begin
                  if (s1_op == 1) begin
                      mshr_has_store[same_line_mshr_idx] <= 1;
                      mshr_store_data[same_line_mshr_idx] <= s1_data;
                      mshr_store_mask[same_line_mshr_idx] <= s1_mask;
                  end
                  pending_mshr_idx[s1_id] <= same_line_mshr_idx;
              end
              
              pending_valid[s1_id] <= 1;
              pending_op[s1_id] <= s1_op;
              pending_word[s1_id] <= s1_addr[3:2];
              pending_seq[s1_id] <= global_seq;
              global_seq <= global_seq + 1;
          end
          
          if (replay_fire) begin
              pending_valid[replay_id] <= 0;
          end
          
          for (m=0; m<MAX_MISSES; m=m+1) begin
              if (mshr_state[m] == MSHR_REPLAYING && !mshr_has_pending[m]) begin
                  mshr_state[m] <= MSHR_FREE;
              end
          end

          // ---- Cache Array Write Arbitration ----
          if (fill_write_en) begin
              logic [$clog2(SETS)-1:0] fw_set;
              logic [$clog2(WAYS)-1:0] fw_way;
              fw_set = mshr_addr[fill_write_mshr][4 +: $clog2(SETS)];
              fw_way = mshr_way[fill_write_mshr];
              
              data_array[fw_set][fw_way][0] <= fill_buffer[0];
              data_array[fw_set][fw_way][1] <= fill_buffer[1];
              data_array[fw_set][fw_way][2] <= fill_buffer[2];
              data_array[fw_set][fw_way][3] <= fill_buffer[3];
              valid_array[fw_set][fw_way] <= 1;
              dirty_array[fw_set][fw_way] <= 0;
              tag_array[fw_set][fw_way] <= mshr_addr[fill_write_mshr];
          end else if (replay_fire && rep_op == 1) begin
              data_array[rep_set][rep_way][rep_word] <= rep_mod_data;
              dirty_array[rep_set][rep_way] <= 1;
          end else if (s1_hit_fire && s1_op == 1) begin
              data_array[s1_set][hit_way_idx][s1_addr[3:2]] <= s1_mod_data;
              dirty_array[s1_set][hit_way_idx] <= 1;
          end
          
          // ---- Memory Controller State Machine ----
          fill_write_en <= 0;
          
          case (mem_state)
              MEM_IDLE: begin
                  if (wb_valid) begin
                      mem_state <= MEM_WB_REQ;
                  end else begin
                      logic found_req;
                      found_req = 0;
                      for (i=0; i<MAX_MISSES; i=i+1) begin
                          if (mshr_state[i] == MSHR_WAIT_MEM_REQ) begin
                              mem_state <= MEM_FILL_REQ;
                              active_fill_mshr <= i;
                              found_req = 1;
                              break;
                          end
                      end
                  end
              end
              
              MEM_WB_REQ: begin
                  if (mem_req_ready_i) begin
                      mem_state <= MEM_WB_DATA;
                      mem_beat_cnt <= 0;
                  end
              end
              
              MEM_WB_DATA: begin
                  if (mem_wr_ready_i) begin
                      if (mem_beat_cnt == 3) begin
                          mem_state <= MEM_IDLE;
                          wb_valid <= 0;
                      end else begin
                          mem_beat_cnt <= mem_beat_cnt + 1;
                      end
                  end
              end
              
              MEM_FILL_REQ: begin
                  if (mem_req_ready_i) begin
                      mem_state <= MEM_FILL_DATA;
                      mem_beat_cnt <= 0;
                      mshr_state[active_fill_mshr] <= MSHR_FETCHING;
                  end
              end
              
              MEM_FILL_DATA: begin
                  if (mem_rd_valid_i) begin
                      fill_buffer[mem_beat_cnt] <= mem_rd_data_i;
                      if (mem_beat_cnt == 3) begin
                          mem_state <= MEM_IDLE;
                          fill_write_en <= 1;
                          fill_write_mshr <= active_fill_mshr;
                          mshr_state[active_fill_mshr] <= MSHR_REPLAYING;
                      end else begin
                          mem_beat_cnt <= mem_beat_cnt + 1;
                      end
                  end
              end
          endcase
      end
  end

  // ---- Memory Port Output Assignments ----
  assign mem_req_valid_o = (mem_state == MEM_WB_REQ) || (mem_state == MEM_FILL_REQ);
  assign mem_req_we_o    = (mem_state == MEM_WB_REQ);
  assign mem_req_addr_o  = (mem_state == MEM_WB_REQ) ? wb_addr : mshr_addr[active_fill_mshr];
  
  assign mem_rd_ready_o  = (mem_state == MEM_FILL_DATA);
  
  assign mem_wr_valid_o  = (mem_state == MEM_WB_DATA);
  assign mem_wr_data_o   = wb_data[mem_beat_cnt];

endmodule