// =============================================================================
// nonblocking_dcache -- set-associative, write-back, write-allocate,
// non-blocking data cache. Hits are answered while misses are outstanding;
// up to MAX_MISSES distinct-line misses are tracked simultaneously (one
// MSHR per line, one request per MSHR); memory transactions are strictly
// serial (M3). Block-data buffering outside the arrays is exactly two lines
// (fill buffer + writeback buffer) plus one merged store word per MSHR (C4).
// =============================================================================
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
  localparam int unsigned BYTE_OFF = $clog2(DATA_W/8);
  localparam int unsigned BLK_OFF  = $clog2(BLOCK_WORDS) + BYTE_OFF;
  localparam int unsigned SET_BITS = $clog2(SETS);
  localparam int unsigned TAG_W    = 32 - SET_BITS - BLK_OFF;
  localparam int unsigned WOFF_W   = $clog2(BLOCK_WORDS);
  localparam int unsigned FDEPTH   = 4;
  localparam int unsigned FCW      = $clog2(FDEPTH+1);
  localparam int unsigned MW       = ($clog2(MAX_MISSES) > 0) ? $clog2(MAX_MISSES) : 1;
  localparam int unsigned WW       = ($clog2(WAYS)       > 0) ? $clog2(WAYS)       : 1;

  // byte-masked merge
  function automatic logic [DATA_W-1:0] merge(
    input logic [DATA_W-1:0]     old_d,
    input logic [DATA_W-1:0]     new_d,
    input logic [DATA_W/8-1:0]   msk);
    logic [DATA_W-1:0] r;
    int b;
    for (b = 0; b < DATA_W/8; b++)
      r[b*8 +: 8] = msk[b] ? new_d[b*8 +: 8] : old_d[b*8 +: 8];
    return r;
  endfunction

  // ---- tag / data arrays ---------------------------------------------------
  logic [TAG_W-1:0]    tag_arr [SETS][WAYS];
  logic                vld_arr [SETS][WAYS];
  logic                drt_arr [SETS][WAYS];
  logic [DATA_W-1:0]   dat_arr [SETS][WAYS][BLOCK_WORDS];
  logic [WW-1:0]       rr_arr  [SETS];          // round-robin victim pointer

  // ---- MSHRs (tracking only: no block data held per miss) ------------------
  logic                m_vld [MAX_MISSES];
  logic [31:0]         m_blk [MAX_MISSES];
  logic [3:0]          m_id  [MAX_MISSES];
  logic                m_we  [MAX_MISSES];
  logic [WOFF_W-1:0]   m_off [MAX_MISSES];
  logic [DATA_W-1:0]   m_sd  [MAX_MISSES];
  logic [DATA_W/8-1:0] m_sm  [MAX_MISSES];

  // ---- memory FSM ----------------------------------------------------------
  typedef enum logic [2:0] {
    S_IDLE, S_WB_REQ, S_WB_DATA, S_FILL_REQ, S_FILL_DATA, S_FINISH
  } state_t;
  state_t              state;
  logic [MW-1:0]       cur_m;
  logic [WW-1:0]       v_way;
  logic [TAG_W-1:0]    v_tag;
  logic [SET_BITS-1:0] v_set;
  logic [DATA_W-1:0]   wb_buf   [BLOCK_WORDS];  // C4: one writeback line
  logic [DATA_W-1:0]   fill_buf [BLOCK_WORDS];  // C4: one fill line
  logic [WOFF_W-1:0]   beat;

  // ---- response FIFO -------------------------------------------------------
  logic [3:0]        f_id  [FDEPTH];
  logic [DATA_W-1:0] f_dat [FDEPTH];
  logic [FCW-1:0]    f_cnt;

  // ---- request decode (combinational) --------------------------------------
  logic [TAG_W-1:0]     r_tag;
  logic [SET_BITS-1:0]  r_set;
  logic [WOFF_W-1:0]    r_off;
  logic [31:0]          r_blk;

  always_comb begin
    r_tag = req_addr_i[31      -: TAG_W];
    r_set = req_addr_i[BLK_OFF +: SET_BITS];
    r_off = req_addr_i[BYTE_OFF+: WOFF_W];
    r_blk = {req_addr_i[31:BLK_OFF], {BLK_OFF{1'b0}}};
  end

  // ---- hit detection -------------------------------------------------------
  logic [WAYS-1:0] hit_oh;
  always_comb begin
    int w2;
    hit_oh = '0;
    for (w2 = 0; w2 < WAYS; w2++)
      hit_oh[w2] = vld_arr[r_set][w2] && (tag_arr[r_set][w2] == r_tag);
  end
  logic is_hit;
  assign is_hit = |hit_oh;

  // ---- MSHR status ---------------------------------------------------------
  logic        any_mshr;
  logic        m_free;
  logic [MW-1:0] free_idx;
  logic        m_match;
  always_comb begin
    int m3;
    any_mshr = 1'b0;
    for (m3 = 0; m3 < MAX_MISSES; m3++) any_mshr = any_mshr | m_vld[m3];
    free_idx = '0;
    m_free   = 1'b0;
    for (m3 = MAX_MISSES-1; m3 >= 0; m3--)
      if (!m_vld[m3]) begin free_idx = MW'(m3); m_free = 1'b1; end
    m_match = 1'b0;
    for (m3 = 0; m3 < MAX_MISSES; m3++)
      if (m_vld[m3] && (m_blk[m3] == r_blk)) m_match = 1'b1;
  end

  // ---- oldest-MSHR selection (lowest valid index) --------------------------
  logic        m_found;
  logic [MW-1:0] sel_m;
  always_comb begin
    int m4;
    sel_m = '0;
    m_found = 1'b0;
    for (m4 = MAX_MISSES-1; m4 >= 0; m4--)
      if (m_vld[m4]) begin sel_m = MW'(m4); m_found = 1'b1; end
  end

  // ---- victim selection (first invalid way, else round-robin) --------------
  logic [SET_BITS-1:0] e_set;
  logic [WW-1:0]       e_way;
  logic                e_dirty;
  always_comb begin
    int w5;
    e_set = m_blk[sel_m][BLK_OFF +: SET_BITS];
    e_way = rr_arr[e_set];
    for (w5 = WAYS-1; w5 >= 0; w5--)
      if (!vld_arr[e_set][w5]) e_way = WW'(w5);
    e_dirty = drt_arr[e_set][e_way];
  end

  // ---- flow control --------------------------------------------------------
  logic evict_cyc, fin_cyc;
  assign evict_cyc = (state == S_IDLE) && any_mshr;
  assign fin_cyc   = (state == S_FINISH);

  // L5: req_ready may depend combinationally on req_valid_i / payload.
  // A miss needs a free MSHR and must not collide with a pending miss on
  // the same line (this also preserves R5 same-address ordering).
  assign req_ready_o = !evict_cyc && !fin_cyc && (f_cnt <= (FDEPTH-2)) &&
                       (is_hit || (m_free && !m_match));

  // ---- response FIFO interface ---------------------------------------------
  logic push, pop, fin_go;
  logic [3:0]       push_id;
  logic [DATA_W-1:0] push_dat;
  assign fin_go = (state == S_FINISH) && (f_cnt < FDEPTH);
  assign pop    = (f_cnt != '0) && rsp_ready_i;

  logic [WW-1:0]     hit_idx;
  logic [DATA_W-1:0] hit_data;
  always_comb begin
    int w6;
    hit_idx  = '0;
    hit_data = '0;
    for (w6 = 0; w6 < WAYS; w6++) begin
      if (hit_oh[w6]) begin
        hit_idx  = WW'(w6);
        hit_data = dat_arr[r_set][w6][r_off];
      end
    end
    if (req_valid_i && req_ready_o && is_hit) begin
      push = 1'b1; push_id = req_id_i; push_dat = hit_data;
    end else if (fin_go) begin
      push = 1'b1; push_id = m_id[cur_m];
      push_dat = m_we[cur_m] ?
                   merge(fill_buf[m_off[cur_m]], m_sd[cur_m], m_sm[cur_m]) :
                   fill_buf[m_off[cur_m]];
    end else begin
      push = 1'b0; push_id = '0; push_dat = '0;
    end
  end

  assign rsp_valid_o = (f_cnt != '0);   // R1b: no combinational path from rsp_ready_i
  assign rsp_id_o    = f_id[0];
  assign rsp_data_o  = f_dat[0];

  // ---- memory port outputs -------------------------------------------------
  assign mem_req_valid_o = (state == S_WB_REQ)   || (state == S_FILL_REQ);
  assign mem_req_we_o    =  (state == S_WB_REQ);
  assign mem_req_addr_o  = (state == S_WB_REQ) ?
                             {v_tag, v_set, {BLK_OFF{1'b0}}} : m_blk[cur_m];
  assign mem_wr_valid_o  = (state == S_WB_DATA);
  assign mem_wr_data_o   = wb_buf[beat];
  assign mem_rd_ready_o  = (state == S_FILL_DATA);

  // ---- request path: hit store / miss allocation ---------------------------
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      // no state owned by this block needs reset
    end else begin
      if (req_valid_i && req_ready_o) begin
        if (is_hit) begin
          if (req_op_i) begin
            dat_arr[r_set][hit_idx][r_off] <=
              merge(dat_arr[r_set][hit_idx][r_off], req_data_i, req_mask_i);
            drt_arr[r_set][hit_idx] <= 1'b1;
          end
        end else begin
          m_vld[free_idx] <= 1'b1;
          m_blk[free_idx] <= r_blk;
          m_id [free_idx] <= req_id_i;
          m_we [free_idx] <= req_op_i;
          m_off[free_idx] <= r_off;
          m_sd [free_idx] <= req_data_i;
          m_sm [free_idx] <= req_mask_i;
        end
      end
    end
  end

  // ---- memory FSM ----------------------------------------------------------
  always_ff @(posedge clk_i or negedge rst_ni) begin
    int si, wi, bi;
    if (!rst_ni) begin
      state  <= S_IDLE;
      cur_m  <= '0;
      v_way  <= '0;
      v_tag  <= '0;
      v_set  <= '0;
      beat   <= '0;
      for (si = 0; si < SETS; si++) begin
        rr_arr[si] <= '0;
        for (wi = 0; wi < WAYS; wi++) begin
          vld_arr[si][wi] <= 1'b0;
          drt_arr[si][wi] <= 1'b0;
        end
      end
      for (bi = 0; bi < MAX_MISSES; bi++) m_vld[bi] <= 1'b0;
    end else begin
      case (state)
        S_IDLE: begin
          if (m_found) begin
            // eviction cycle: snapshot victim, invalidate it immediately.
            // req_ready is held low this cycle so no hit store can race
            // the snapshot.
            cur_m  <= sel_m;
            v_set  <= e_set;
            v_way  <= e_way;
            v_tag  <= tag_arr[e_set][e_way];
            for (bi = 0; bi < BLOCK_WORDS; bi++)
              wb_buf[bi] <= dat_arr[e_set][e_way][bi];
            vld_arr[e_set][e_way] <= 1'b0;
            rr_arr[e_set]         <= e_way + 1'b1;
            beat  <= '0;
            state <= e_dirty ? S_WB_REQ : S_FILL_REQ;
          end
        end
        S_WB_REQ: begin
          if (mem_req_ready_i) begin beat <= '0; state <= S_WB_DATA; end
        end
        S_WB_DATA: begin
          if (mem_wr_ready_i) begin
            if (beat == BLOCK_WORDS-1) begin
              beat  <= '0;
              state <= S_FILL_REQ;
            end else begin
              beat <= beat + 1'b1;
            end
          end
        end
        S_FILL_REQ: begin
          if (mem_req_ready_i) begin beat <= '0; state <= S_FILL_DATA; end
        end
        S_FILL_DATA: begin
          if (mem_rd_valid_i) begin
            fill_buf[beat] <= mem_rd_data_i;
            if (beat == BLOCK_WORDS-1) state <= S_FINISH;
            else                       beat  <= beat + 1'b1;
          end
        end
        S_FINISH: begin
          if (fin_go) begin
            for (bi = 0; bi < BLOCK_WORDS; bi++) begin
              if (m_we[cur_m] && (m_off[cur_m] == WOFF_W'(bi)))
                dat_arr[v_set][v_way][bi] <=
                  merge(fill_buf[bi], m_sd[cur_m], m_sm[cur_m]);
              else
                dat_arr[v_set][v_way][bi] <= fill_buf[bi];
            end
            tag_arr[v_set][v_way] <= m_blk[cur_m][31 -: TAG_W];
            vld_arr[v_set][v_way] <= 1'b1;
            drt_arr[v_set][v_way] <= m_we[cur_m];
            m_vld[cur_m]          <= 1'b0;
            state                 <= S_IDLE;
          end
        end
        default: state <= S_IDLE;
      endcase
    end
  end

  // ---- response FIFO update ------------------------------------------------
  always_ff @(posedge clk_i or negedge rst_ni) begin
    int fi;
    if (!rst_ni) begin
      f_cnt <= '0;
    end else begin
      if (pop) begin
        for (fi = 0; fi < FDEPTH-1; fi++) begin
          f_id [fi] <= f_id [fi+1];
          f_dat[fi] <= f_dat[fi+1];
        end
      end
      if (push) begin
        f_id [pop ? (f_cnt - 1) : f_cnt] <= push_id;
        f_dat[pop ? (f_cnt - 1) : f_cnt] <= push_dat;
      end
      if (push && !pop)      f_cnt <= f_cnt + 1'b1;
      else if (!push && pop) f_cnt <= f_cnt - 1'b1;
    end
  end

endmodule
