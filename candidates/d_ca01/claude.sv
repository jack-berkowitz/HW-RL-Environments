// =============================================================================
// nonblocking_dcache.sv
//
// Set-associative, write-back, write-allocate data cache that keeps accepting
// requests while misses are outstanding.
//
// Shape of the design
// -------------------
//   * Tag/valid/dirty/data arrays, WAYS-way, SETS sets, BLOCK_WORDS words per
//     line. A lookup is combinational from req_addr_i, so a hit is answered
//     from a registered response one cycle after it is accepted.
//
//   * A miss table of MAX_MISSES entries. One entry per pending miss, holding
//     the line address, the requesting id, the word index, and -- for a store
//     -- ONE word of store data and its byte mask (C4). No block data is held
//     per miss: fill beats are written straight into the data array.
//
//   * A single memory engine, because M3 permits one memory transaction at a
//     time. It picks a waiting miss round-robin, evicts the victim (copying it
//     to the ONE writeback line buffer if dirty), runs the writeback, then the
//     fill. That is two lines of block data in the whole design: the writeback
//     buffer, and the line being filled in place in the array.
//
//   * Responses come from a single registered slot, fed by the miss table
//     first and by hits second. rsp_valid_o is registered and never looks at
//     rsp_ready_i (R1b).
//
// How the interesting clauses are met
// -----------------------------------
//   C1  A miss occupies a table entry, not the pipeline. MAX_MISSES distinct
//       lines can be accepted with memory frozen.
//   C2  Hit acceptance is independent of miss-table occupancy, so a hit is
//       accepted and answered underneath outstanding fills.
//   C3  Both arbiters -- which miss to service, which response to emit -- are
//       round-robin, so no entry can be passed over indefinitely. Miss
//       responses outrank hits, so a stream of hits cannot starve a fill.
//   R5  A request whose line already has a table entry is not accepted until
//       that entry retires, so same-line traffic is serialised; everything
//       resident is applied to the array in acceptance order.
//
// Serialisation note: in the cycle the memory engine picks a victim, no
// request is accepted. That is what keeps a store hit from landing on a line
// that is being copied into the writeback buffer in the same cycle.
// =============================================================================

module nonblocking_dcache #(
  parameter int unsigned DATA_W     = 32,   // {32, 64}
  parameter int unsigned SETS       = 16,   // {8, 16}
  parameter int unsigned WAYS       = 4,    // {2, 4}
  parameter int unsigned MAX_MISSES = 8     // {2, 8}
) (
  input  logic                     clk_i,
  input  logic                     rst_ni,        // active low, asynchronous assert

  // ---- request ------------------------------------------------------------
  input  logic                     req_valid_i,
  output logic                     req_ready_o,
  input  logic [3:0]               req_id_i,      // ID_W = 4
  input  logic                     req_op_i,      // 0 = LOAD, 1 = STORE
  input  logic [31:0]              req_addr_i,    // ADDR_W = 32, byte address, word aligned
  input  logic [DATA_W-1:0]        req_data_i,    // STORE data
  input  logic [(DATA_W/8)-1:0]    req_mask_i,    // STORE byte enables

  // ---- response -----------------------------------------------------------
  output logic                     rsp_valid_o,
  input  logic                     rsp_ready_i,
  output logic [3:0]               rsp_id_o,
  output logic [DATA_W-1:0]        rsp_data_o,

  // ---- memory: request ----------------------------------------------------
  output logic                     mem_req_valid_o,
  input  logic                     mem_req_ready_i,
  output logic                     mem_req_we_o,  // 0 = fill, 1 = writeback
  output logic [31:0]              mem_req_addr_o,// block aligned

  // ---- memory: fill data in ----------------------------------------------
  input  logic                     mem_rd_valid_i,
  output logic                     mem_rd_ready_o,
  input  logic [DATA_W-1:0]        mem_rd_data_i,

  // ---- memory: writeback data out ----------------------------------------
  output logic                     mem_wr_valid_o,
  input  logic                     mem_wr_ready_i,
  output logic [DATA_W-1:0]        mem_wr_data_o
);

  // ---------------------------------------------------------------------------
  // geometry
  // ---------------------------------------------------------------------------
  localparam int unsigned BLOCK_WORDS = 4;

  localparam int unsigned NBYTES  = DATA_W / 8;
  localparam int unsigned OFF_B   = $clog2(NBYTES);         // byte-in-word bits
  localparam int unsigned BLK_B   = $clog2(BLOCK_WORDS);    // word-in-block bits
  localparam int unsigned SET_B   = $clog2(SETS);
  localparam int unsigned TAG_LSB = OFF_B + BLK_B + SET_B;
  localparam int unsigned TAG_B   = 32 - TAG_LSB;
  localparam int unsigned WAY_B   = $clog2(WAYS);
  localparam int unsigned MSH_B   = $clog2(MAX_MISSES);
  localparam int unsigned BASE_B  = OFF_B + BLK_B;          // block-alignment zeros

  // miss-table entry states
  localparam logic [1:0] E_WAIT = 2'd0;   // waiting to be given to memory
  localparam logic [1:0] E_BUSY = 2'd1;   // memory engine is servicing it
  localparam logic [1:0] E_DONE = 2'd2;   // line resident, response owed

  // unsigned increments, so no signed/unsigned mixing in the arithmetic below
  localparam logic [MSH_B-1:0] MSH_ONE = MSH_B'(1);
  localparam logic [WAY_B-1:0] WAY_ONE = WAY_B'(1);
  localparam logic [BLK_B-1:0] BLK_ONE = BLK_B'(1);
  localparam logic [BLK_B-1:0] BLK_LAST = BLK_B'(BLOCK_WORDS - 1);

  // memory engine states
  localparam logic [2:0] MS_IDLE   = 3'd0;
  localparam logic [2:0] MS_WB_REQ = 3'd1;
  localparam logic [2:0] MS_WB_DAT = 3'd2;
  localparam logic [2:0] MS_FL_REQ = 3'd3;
  localparam logic [2:0] MS_FL_DAT = 3'd4;

  // ---------------------------------------------------------------------------
  // storage
  // ---------------------------------------------------------------------------
  logic [SETS-1:0][WAYS-1:0]              valid_q;
  logic [SETS-1:0][WAYS-1:0]              dirty_q;
  logic [SETS-1:0][WAYS-1:0][TAG_B-1:0]   tag_q;
  logic [DATA_W-1:0]                      data_q [SETS][WAYS][BLOCK_WORDS];
  logic [SETS-1:0][WAY_B-1:0]             vic_ptr_q;      // round-robin victim

  logic [MAX_MISSES-1:0]                  m_valid_q;
  logic [MAX_MISSES-1:0][1:0]             m_state_q;
  logic [MAX_MISSES-1:0][TAG_B-1:0]       m_tag_q;
  logic [MAX_MISSES-1:0][SET_B-1:0]       m_set_q;
  logic [MAX_MISSES-1:0][BLK_B-1:0]       m_word_q;
  logic [MAX_MISSES-1:0][3:0]             m_id_q;
  logic [MAX_MISSES-1:0]                  m_op_q;
  logic [MAX_MISSES-1:0][DATA_W-1:0]      m_data_q;       // store word, then result
  logic [MAX_MISSES-1:0][NBYTES-1:0]      m_mask_q;

  logic [2:0]                             ms_q;
  logic [MSH_B-1:0]                        ms_ent_q;
  logic [SET_B-1:0]                        ms_set_q;
  logic [WAY_B-1:0]                        ms_way_q;
  logic [TAG_B-1:0]                        ms_tag_q;
  logic [31:0]                             ms_wbaddr_q;
  logic [BLK_B-1:0]                        beat_q;
  logic [DATA_W-1:0]                       wb_buf_q [BLOCK_WORDS];

  logic                                    rsp_valid_q;
  logic [3:0]                              rsp_id_q;
  logic [DATA_W-1:0]                       rsp_data_q;

  logic [MSH_B-1:0]                        svc_ptr_q;
  logic [MSH_B-1:0]                        rsp_ptr_q;

  // ---------------------------------------------------------------------------
  // combinational nets (all declared here, so no procedural block declares
  // anything after a statement -- T2)
  // ---------------------------------------------------------------------------
  logic [BLK_B-1:0]   req_word;
  logic [SET_B-1:0]   req_set;
  logic [TAG_B-1:0]   req_tag;

  logic               hit;
  logic [WAY_B-1:0]   hit_way;
  logic [DATA_W-1:0]  hit_rdata;

  logic               line_busy;
  logic               alloc_ok;
  logic [MSH_B-1:0]   alloc_idx;

  logic               svc_val;
  logic [MSH_B-1:0]   svc_idx;
  logic [MSH_B-1:0]   svc_k;
  int                 svc_t;
  logic [SET_B-1:0]   svc_set;

  logic               rsp_sel_val;
  logic [MSH_B-1:0]   rsp_sel_idx;
  logic [MSH_B-1:0]   rsp_k;
  int                 rsp_t;

  logic [WAY_B-1:0]   vic_way;
  logic               vic_dirty;

  logic [DATA_W-1:0]  fill_word;
  logic [31:0]        fill_addr;

  logic               rsp_free;
  logic               mem_start;
  logic               acc_hit;
  logic               acc_miss;

  // ---------------------------------------------------------------------------
  // request decode and lookup
  // ---------------------------------------------------------------------------
  assign req_word = req_addr_i[OFF_B         +: BLK_B];
  assign req_set  = req_addr_i[OFF_B + BLK_B +: SET_B];
  assign req_tag  = req_addr_i[TAG_LSB       +: TAG_B];

  always_comb begin
    hit     = 1'b0;
    hit_way = '0;
    for (int w = 0; w < int'(WAYS); w++) begin
      if (valid_q[req_set][w] && (tag_q[req_set][w] == req_tag)) begin
        hit     = 1'b1;
        hit_way = WAY_B'(unsigned'(w));
      end
    end
  end

  assign hit_rdata = data_q[req_set][hit_way][req_word];

  // a line with a miss-table entry is not resident, so it is not offered a
  // second entry; the second request waits until the first retires (R5)
  always_comb begin
    line_busy = 1'b0;
    for (int i = 0; i < int'(MAX_MISSES); i++) begin
      if (m_valid_q[i] && (m_set_q[i] == req_set) && (m_tag_q[i] == req_tag)) begin
        line_busy = 1'b1;
      end
    end
  end

  always_comb begin
    alloc_ok  = 1'b0;
    alloc_idx = '0;
    for (int i = int'(MAX_MISSES) - 1; i >= 0; i--) begin
      if (!m_valid_q[i]) begin
        alloc_ok  = 1'b1;
        alloc_idx = MSH_B'(unsigned'(i));
      end
    end
  end

  // ---------------------------------------------------------------------------
  // arbiters -- both round-robin, which is what keeps C3 true
  // ---------------------------------------------------------------------------
  always_comb begin
    svc_val = 1'b0;
    svc_idx = '0;
    svc_k   = '0;
    svc_t   = 0;
    for (int i = int'(MAX_MISSES) - 1; i >= 0; i--) begin
      svc_t = int'(svc_ptr_q) + i;
      if (svc_t >= int'(MAX_MISSES)) svc_t = svc_t - int'(MAX_MISSES);
      svc_k = MSH_B'(unsigned'(svc_t));
      if (m_valid_q[svc_k] && (m_state_q[svc_k] == E_WAIT)) begin
        svc_val = 1'b1;
        svc_idx = svc_k;
      end
    end
  end

  assign svc_set = m_set_q[svc_idx];

  always_comb begin
    rsp_sel_val = 1'b0;
    rsp_sel_idx = '0;
    rsp_k       = '0;
    rsp_t       = 0;
    for (int i = int'(MAX_MISSES) - 1; i >= 0; i--) begin
      rsp_t = int'(rsp_ptr_q) + i;
      if (rsp_t >= int'(MAX_MISSES)) rsp_t = rsp_t - int'(MAX_MISSES);
      rsp_k = MSH_B'(unsigned'(rsp_t));
      if (m_valid_q[rsp_k] && (m_state_q[rsp_k] == E_DONE)) begin
        rsp_sel_val = 1'b1;
        rsp_sel_idx = rsp_k;
      end
    end
  end

  // ---------------------------------------------------------------------------
  // victim choice for the miss the engine is about to service
  // ---------------------------------------------------------------------------
  always_comb begin
    vic_way = vic_ptr_q[svc_set];
    for (int w = int'(WAYS) - 1; w >= 0; w--) begin
      if (!valid_q[svc_set][w]) vic_way = WAY_B'(unsigned'(w));
    end
    vic_dirty = valid_q[svc_set][vic_way] & dirty_q[svc_set][vic_way];
  end

  // ---------------------------------------------------------------------------
  // acceptance
  // ---------------------------------------------------------------------------
  assign rsp_free  = (~rsp_valid_q) | rsp_ready_i;
  assign mem_start = (ms_q == MS_IDLE) & svc_val;

  assign acc_hit  = req_valid_i & hit & rsp_free & (~rsp_sel_val) & (~mem_start);
  assign acc_miss = req_valid_i & (~hit) & (~line_busy) & alloc_ok & (~mem_start);

  // L5 permits this to look at req_valid_i; it does not need to.
  assign req_ready_o = hit ? (rsp_free & (~rsp_sel_val) & (~mem_start))
                           : ((~line_busy) & alloc_ok & (~mem_start));

  // ---------------------------------------------------------------------------
  // memory port
  // ---------------------------------------------------------------------------
  assign fill_addr = {ms_tag_q, ms_set_q, {BASE_B{1'b0}}};

  assign mem_req_valid_o = (ms_q == MS_WB_REQ) | (ms_q == MS_FL_REQ);
  assign mem_req_we_o    = (ms_q == MS_WB_REQ);
  assign mem_req_addr_o  = (ms_q == MS_WB_REQ) ? ms_wbaddr_q : fill_addr;

  assign mem_wr_valid_o  = (ms_q == MS_WB_DAT);
  assign mem_wr_data_o   = wb_buf_q[beat_q];

  assign mem_rd_ready_o  = (ms_q == MS_FL_DAT);

  // the arriving beat, with this miss's store word merged into it if this is
  // the beat that store belongs to
  always_comb begin
    fill_word = mem_rd_data_i;
    if (m_op_q[ms_ent_q] && (beat_q == m_word_q[ms_ent_q])) begin
      for (int b = 0; b < int'(NBYTES); b++) begin
        if (m_mask_q[ms_ent_q][b]) fill_word[b*8 +: 8] = m_data_q[ms_ent_q][b*8 +: 8];
      end
    end
  end

  // ---------------------------------------------------------------------------
  // response port -- registered, never a function of rsp_ready_i (R1b)
  // ---------------------------------------------------------------------------
  assign rsp_valid_o = rsp_valid_q;
  assign rsp_id_o    = rsp_id_q;
  assign rsp_data_o  = rsp_data_q;

  // ---------------------------------------------------------------------------
  // state
  // ---------------------------------------------------------------------------
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      valid_q     <= '0;
      dirty_q     <= '0;
      vic_ptr_q   <= '0;
      m_valid_q   <= '0;
      m_state_q   <= '0;
      ms_q        <= MS_IDLE;
      ms_ent_q    <= '0;
      beat_q      <= '0;
      rsp_valid_q <= 1'b0;
      rsp_id_q    <= '0;
      rsp_data_q  <= '0;
      svc_ptr_q   <= '0;
      rsp_ptr_q   <= '0;
    end else begin
      // ---- response slot: miss responses outrank hits ----------------------
      if (rsp_free) begin
        if (rsp_sel_val) begin
          rsp_valid_q            <= 1'b1;
          rsp_id_q               <= m_id_q[rsp_sel_idx];
          rsp_data_q             <= m_data_q[rsp_sel_idx];
          m_valid_q[rsp_sel_idx] <= 1'b0;
          rsp_ptr_q              <= rsp_sel_idx + MSH_ONE;
        end else if (acc_hit) begin
          rsp_valid_q <= 1'b1;
          rsp_id_q    <= req_id_i;
          rsp_data_q  <= hit_rdata;      // store response data is free (R3)
        end else begin
          rsp_valid_q <= 1'b0;
        end
      end

      // ---- store hit --------------------------------------------------------
      if (acc_hit && req_op_i) begin
        for (int b = 0; b < int'(NBYTES); b++) begin
          if (req_mask_i[b]) begin
            data_q[req_set][hit_way][req_word][b*8 +: 8] <= req_data_i[b*8 +: 8];
          end
        end
        dirty_q[req_set][hit_way] <= 1'b1;
      end

      // ---- miss allocation --------------------------------------------------
      if (acc_miss) begin
        m_valid_q[alloc_idx] <= 1'b1;
        m_state_q[alloc_idx] <= E_WAIT;
        m_tag_q[alloc_idx]   <= req_tag;
        m_set_q[alloc_idx]   <= req_set;
        m_word_q[alloc_idx]  <= req_word;
        m_id_q[alloc_idx]    <= req_id_i;
        m_op_q[alloc_idx]    <= req_op_i;
        m_data_q[alloc_idx]  <= req_data_i;
        m_mask_q[alloc_idx]  <= req_op_i ? req_mask_i : '0;
      end

      // ---- memory engine ----------------------------------------------------
      case (ms_q)
        MS_IDLE: begin
          if (svc_val) begin
            m_state_q[svc_idx] <= E_BUSY;
            ms_ent_q           <= svc_idx;
            ms_set_q           <= svc_set;
            ms_way_q           <= vic_way;
            ms_tag_q           <= m_tag_q[svc_idx];
            svc_ptr_q          <= svc_idx + MSH_ONE;
            vic_ptr_q[svc_set] <= vic_ptr_q[svc_set] + WAY_ONE;

            // the victim leaves now: nothing can hit it while it is in motion
            valid_q[svc_set][vic_way] <= 1'b0;
            dirty_q[svc_set][vic_way] <= 1'b0;
            tag_q[svc_set][vic_way]   <= m_tag_q[svc_idx];

            if (vic_dirty) begin
              for (int b = 0; b < int'(BLOCK_WORDS); b++) begin
                wb_buf_q[b] <= data_q[svc_set][vic_way][b];
              end
              ms_wbaddr_q <= {tag_q[svc_set][vic_way], svc_set, {BASE_B{1'b0}}};
              ms_q        <= MS_WB_REQ;
            end else begin
              ms_q <= MS_FL_REQ;
            end
          end
        end

        MS_WB_REQ: begin
          if (mem_req_ready_i) begin
            beat_q <= '0;
            ms_q   <= MS_WB_DAT;
          end
        end

        MS_WB_DAT: begin
          if (mem_wr_ready_i) begin
            beat_q <= beat_q + BLK_ONE;
            if (beat_q == BLK_LAST) ms_q <= MS_FL_REQ;
          end
        end

        MS_FL_REQ: begin
          if (mem_req_ready_i) begin
            beat_q <= '0;
            ms_q   <= MS_FL_DAT;
          end
        end

        MS_FL_DAT: begin
          if (mem_rd_valid_i) begin
            data_q[ms_set_q][ms_way_q][beat_q] <= fill_word;
            if ((beat_q == m_word_q[ms_ent_q]) && !m_op_q[ms_ent_q]) begin
              m_data_q[ms_ent_q] <= mem_rd_data_i;   // the load's answer
            end
            beat_q <= beat_q + BLK_ONE;
            if (beat_q == BLK_LAST) begin
              valid_q[ms_set_q][ms_way_q] <= 1'b1;
              dirty_q[ms_set_q][ms_way_q] <= m_op_q[ms_ent_q];
              m_state_q[ms_ent_q]         <= E_DONE;
              ms_q                        <= MS_IDLE;
            end
          end
        end

        default: ms_q <= MS_IDLE;
      endcase
    end
  end

endmodule