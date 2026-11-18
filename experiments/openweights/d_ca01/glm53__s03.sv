module nonblocking_dcache #(
  parameter int unsigned DATA_W     = 32,   // {32, 64}
  parameter int unsigned SETS       = 16,   // {8, 16}
  parameter int unsigned WAYS       = 4,    // {2, 4}
  parameter int unsigned MAX_MISSES = 8     // {2, 8}
) (
  input  logic                     clk_i,
  input  logic                     rst_ni,        // active low, asynchronous assert

  input  logic                     req_valid_i,
  output logic                     req_ready_o,
  input  logic [3:0]               req_id_i,
  input  logic                     req_op_i,      // 0 = LOAD, 1 = STORE
  input  logic [31:0]              req_addr_i,    // byte address, word aligned
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

  // ---------------- localparams ----------------
  localparam int unsigned BLOCK_WORDS = 4;               // fixed by contract
  localparam int unsigned BPW   = DATA_W/8;              // bytes per word
  localparam int unsigned OFF_W = $clog2(BLOCK_WORDS*BPW);
  localparam int unsigned IDX_W = $clog2(SETS);
  localparam int unsigned TAG_W = 32 - OFF_W - IDX_W;
  localparam int unsigned WAY_W = $clog2(WAYS);
  localparam int unsigned NM    = MAX_MISSES + 1;        // MSHR count
  localparam int unsigned APW   = (NM <= 2) ? 1 : $clog2(NM);
  localparam int unsigned RD    = 8;                     // response fifo depth

  localparam logic [2:0] S_IDLE = 3'd0;
  localparam logic [2:0] S_WBQ  = 3'd1;  // writeback request
  localparam logic [2:0] S_WBD  = 3'd2;  // writeback data beats
  localparam logic [2:0] S_FQ    = 3'd3;  // fill request
  localparam logic [2:0] S_FD    = 3'd4;  // fill data beats
  localparam logic [2:0] S_CMT   = 3'd5;  // commit line into arrays

  // ---------------- arrays ----------------
  logic [SETS-1:0][WAYS-1:0]                     tagv_q, tagd_q;
  logic [SETS-1:0][WAYS-1:0][TAG_W-1:0]          tag_q;
  logic [SETS-1:0][WAYS-1:0][BLOCK_WORDS-1:0][DATA_W-1:0] data_q;
  logic [SETS-1:0][WAY_W-1:0]                    rr_q;   // round-robin victim

  // ---------------- MSHRs (tracking only: no block data) ----------------
  logic [NM-1:0]            m_v_q;
  logic [NM-1:0][31:0]      m_addr_q;   // block-aligned
  logic [NM-1:0][3:0]       m_id_q;
  logic [NM-1:0]            m_op_q;
  logic [NM-1:0][1:0]       m_woff_q;
  logic [NM-1:0][DATA_W-1:0] m_data_q;  // merged store word (<=1 word per miss)
  logic [NM-1:0][BPW-1:0]   m_mask_q;

  logic [APW-1:0] alloc_q, serve_q;

  // ---------------- fill / writeback buffers (the only 2 block-data lines) --
  logic [BLOCK_WORDS-1:0][DATA_W-1:0] fill_q, wb_q;
  logic [1:0] fcnt_q, wcnt_q;
  logic [31:0] wb_addr_q;

  // in-service MSHR snapshot
  logic [APW-1:0]    cur_idx_q;
  logic [31:0]       cur_addr_q;
  logic [3:0]        cur_id_q;
  logic              cur_op_q;
  logic [1:0]        cur_woff_q;
  logic [DATA_W-1:0] cur_data_q;
  logic [BPW-1:0]    cur_mask_q;
  logic [IDX_W-1:0]  cur_set_q;
  logic [TAG_W-1:0]  cur_tag_q;
  logic [WAY_W-1:0]  vway_q;

  // ---------------- response fifo ----------------
  logic [RD-1:0][3:0]       rf_id_q;
  logic [RD-1:0][DATA_W-1:0] rf_data_q;
  logic [3:0] rf_head_q, rf_tail_q, rf_cnt_q;

  logic [2:0] state_q;

  // ---------------- byte-mask merge ----------------
  function automatic logic [DATA_W-1:0] merge_w(
    input logic [DATA_W-1:0] oldd,
    input logic [DATA_W-1:0] neww,
    input logic [BPW-1:0]   msk
  );
    logic [DATA_W-1:0] r;
    int unsigned b;
    r = oldd;
    for (b = 0; b < BPW; b++)
      if (msk[b]) r[b*8 +: 8] = neww[b*8 +: 8];
    return r;
  endfunction

  // ---------------- combinational request / select logic ----------------
  logic [31:0]      r_blk;
  logic [IDX_W-1:0] r_set;
  logic [TAG_W-1:0] r_tag;
  logic [1:0]       r_woff;
  logic             req_hit;
  logic [WAY_W-1:0] hit_way;
  logic [DATA_W-1:0] hit_rdata;
  logic             blk_busy;
  logic             free_found;
  logic [APW-1:0]   free_idx;
  logic             sel_found;
  logic [APW-1:0]   sel_idx;
  logic [IDX_W-1:0] sel_set;
  logic [WAY_W-1:0] sel_vway;
  logic             sel_dirty;
  logic             any_m;
  logic             start_cycle;
  logic             can_acc;
  logic             rsp_pop, push_hit, push_cmt;
  logic [DATA_W-1:0] cmt_word, cmt_rdata;
  int unsigned w, i, j;

  always_comb begin
    r_blk  = {req_addr_i[31:OFF_W], {OFF_W{1'b0}}};
    r_set  = req_addr_i[OFF_W +: IDX_W];
    r_tag  = req_addr_i[31 -: TAG_W];
    r_woff = req_addr_i[OFF_W-1 -: 2];      // BLOCK_WORDS == 4

    // tag lookup
    req_hit = 1'b0;
    hit_way = '0;
    for (w = 0; w < WAYS; w++) begin
      if (tagv_q[r_set][w] && (tag_q[r_set][w] == r_tag)) begin
        req_hit = 1'b1;
        hit_way = WAY_W'(w);
      end
    end
    hit_rdata = data_q[r_set][hit_way][r_woff];

    // secondary miss to a block already being tracked -> stall
    blk_busy = 1'b0;
    for (i = 0; i < NM; i++) begin
      if (m_v_q[i] && (m_addr_q[i][31:OFF_W] == req_addr_i[31:OFF_W]))
        blk_busy = 1'b1;
    end

    // free MSHR, circular from alloc pointer
    free_found = 1'b0;
    free_idx   = '0;
    for (i = 0; i < NM; i++) begin
      j = (alloc_q + i) % NM;
      if (!free_found && !m_v_q[j]) begin
        free_found = 1'b1;
        free_idx   = APW'(j);
      end
    end

    // oldest-served MSHR, circular from serve pointer (fair, no starvation)
    sel_found = 1'b0;
    sel_idx   = '0;
    for (i = 0; i < NM; i++) begin
      j = (serve_q + i) % NM;
      if (!sel_found && m_v_q[j]) begin
        sel_found = 1'b1;
        sel_idx   = APW'(j);
      end
    end
    any_m = sel_found;

    sel_set   = m_addr_q[sel_idx][OFF_W +: IDX_W];
    sel_vway  = rr_q[sel_set];
    sel_dirty = tagv_q[sel_set][sel_vway] && tagd_q[sel_set][sel_vway];

    // one stall cycle when a miss service starts (victim tag is invalidated)
    start_cycle = (state_q == S_IDLE) && any_m;

    can_acc = (rf_cnt_q < RD) && !start_cycle && (state_q != S_CMT)
              && (req_hit || (!blk_busy && free_found));

    rsp_pop  = (rf_cnt_q != 0) && rsp_ready_i;
    push_hit = req_valid_i && can_acc && req_hit;
    push_cmt = (state_q == S_CMT) && (rf_cnt_q < RD);

    cmt_word  = merge_w(fill_q[cur_woff_q], cur_data_q, cur_mask_q);
    cmt_rdata = cur_op_q ? cmt_word : fill_q[cur_woff_q];
  end

  // ---------------- outputs ----------------
  assign req_ready_o      = can_acc;
  assign rsp_valid_o      = (rf_cnt_q != 4'd0);   // no comb dependence on rsp_ready_i
  assign rsp_id_o         = rf_id_q[rf_head_q[2:0]];
  assign rsp_data_o       = rf_data_q[rf_head_q[2:0]];
  assign mem_req_valid_o  = (state_q == S_WBQ) || (state_q == S_FQ);
  assign mem_req_we_o     = (state_q == S_WBQ);
  assign mem_req_addr_o   = (state_q == S_WBQ) ? wb_addr_q : cur_addr_q;
  assign mem_rd_ready_o   = (state_q == S_FD);
  assign mem_wr_valid_o   = (state_q == S_WBD);
  assign mem_wr_data_o    = wb_q[wcnt_q];

  // ---------------- sequential ----------------
  always_ff @(posedge clk_i or negedge rst_ni) begin
    int unsigned s, wi, k;
    if (!rst_ni) begin
      state_q <= S_IDLE;
      for (s = 0; s < SETS; s++) begin
        rr_q[s] <= '0;
        for (wi = 0; wi < WAYS; wi++) begin
          tagv_q[s][wi] <= 1'b0;
          tagd_q[s][wi] <= 1'b0;
        end
      end
      for (k = 0; k < NM; k++) m_v_q[k] <= 1'b0;
      alloc_q   <= '0;
      serve_q   <= '0;
      rf_head_q <= '0;
      rf_tail_q <= '0;
      rf_cnt_q  <= '0;
      fcnt_q    <= '0;
      wcnt_q    <= '0;
    end else begin
      // ---- response fifo push/pop ----
      if (push_hit || push_cmt) begin
        rf_id_q[rf_tail_q[2:0]]   <= push_hit ? req_id_i : cur_id_q;
        rf_data_q[rf_tail_q[2:0]] <= push_hit ? hit_rdata : cmt_rdata;
        rf_tail_q <= rf_tail_q + 4'd1;
      end
      if (rsp_pop) rf_head_q <= rf_head_q + 4'd1;
      rf_cnt_q <= rf_cnt_q + ((push_hit || push_cmt) ? 4'd1 : 4'd0)
                           - (rsp_pop ? 4'd1 : 4'd0);

      // ---- request accept ----
      if (req_valid_i && can_acc) begin
        if (req_hit) begin
          if (req_op_i) begin
            data_q[r_set][hit_way][r_woff] <=
              merge_w(data_q[r_set][hit_way][r_woff], req_data_i, req_mask_i);
            tagd_q[r_set][hit_way] <= 1'b1;
          end
        end else begin
          m_v_q[free_idx]    <= 1'b1;
          m_addr_q[free_idx] <= r_blk;
          m_id_q[free_idx]   <= req_id_i;
          m_op_q[free_idx]   <= req_op_i;
          m_woff_q[free_idx] <= r_woff;
          m_data_q[free_idx] <= req_data_i;
          m_mask_q[free_idx] <= req_mask_i;
          alloc_q <= (free_idx == APW'(NM-1)) ? '0 : (free_idx + 1'b1);
        end
      end

      // ---- miss service FSM (one memory transaction at a time) ----
      case (state_q)
        S_IDLE: begin
          if (any_m) begin
            cur_idx_q  <= sel_idx;
            cur_addr_q <= m_addr_q[sel_idx];
            cur_id_q   <= m_id_q[sel_idx];
            cur_op_q   <= m_op_q[sel_idx];
            cur_woff_q <= m_woff_q[sel_idx];
            cur_data_q <= m_data_q[sel_idx];
            cur_mask_q <= m_mask_q[sel_idx];
            cur_set_q  <= sel_set;
            cur_tag_q  <= m_addr_q[sel_idx][31 -: TAG_W];
            vway_q     <= sel_vway;
            // invalidate victim now: no hit can touch it during WB/FILL
            tagv_q[sel_set][sel_vway] <= 1'b0;
            serve_q <= (sel_idx == APW'(NM-1)) ? '0 : (sel_idx + 1'b1);
            if (sel_dirty) begin
              wb_q      <= data_q[sel_set][sel_vway];
              wb_addr_q <= {tag_q[sel_set][sel_vway], sel_set, {OFF_W{1'b0}}};
              state_q   <= S_WBQ;
            end else begin
              state_q <= S_FQ;
            end
          end
        end
        S_WBQ: begin
          if (mem_req_ready_i) begin
            wcnt_q  <= '0;
            state_q <= S_WBD;
          end
        end
        S_WBD: begin
          if (mem_wr_ready_i) begin
            if (wcnt_q == 2'd3) state_q <= S_FQ;
            else                wcnt_q <= wcnt_q + 2'd1;
          end
        end
        S_FQ: begin
          if (mem_req_ready_i) begin
            fcnt_q  <= '0;
            state_q <= S_FD;
          end
        end
        S_FD: begin
          if (mem_rd_valid_i) begin
            fill_q[fcnt_q] <= mem_rd_data_i;
            if (fcnt_q == 2'd3) state_q <= S_CMT;
            else                 fcnt_q <= fcnt_q + 2'd1;
          end
        end
        S_CMT: begin
          if (rf_cnt_q < RD) begin
            for (k = 0; k < BLOCK_WORDS; k++) begin
              data_q[cur_set_q][vway_q][k] <=
                (cur_op_q && (k[1:0] == cur_woff_q)) ? cmt_word : fill_q[k];
            end
            tagv_q[cur_set_q][vway_q] <= 1'b1;
            tagd_q[cur_set_q][vway_q] <= cur_op_q;
            tag_q[cur_set_q][vway_q]  <= cur_tag_q;
            rr_q[cur_set_q] <= (vway_q == WAY_W'(WAYS-1)) ? '0 : (vway_q + 1'b1);
            m_v_q[cur_idx_q] <= 1'b0;
            state_q <= S_IDLE;
          end
        end
        default: state_q <= S_IDLE;
      endcase
    end
  end

endmodule
