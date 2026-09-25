// =============================================================================
// nonblocking_dcache -- set-associative, write-back, write-allocate, non-blocking
//
// Organisation
//   * Tag / valid / dirty / data arrays in flops. One shared read port serves
//     load hits, load replays and writeback beats (never two at once).
//   * Miss tracking: an age-ordered, collapsing request queue (RQ). A request
//     that misses is appended; each entry holds id, op, line, word and one word
//     of store data + mask (C4: no block data is buffered per miss).
//   * One memory engine (M3), serving misses strictly oldest-line-first:
//       IDLE -> (select victim) -> [WB_REQ -> WB_DAT] -> F_REQ -> F_DAT -> REPLAY
//     Fill beats are written straight into the victim way (it is invalidated at
//     selection, so nothing can hit it meanwhile). On the last beat the line is
//     installed and every RQ entry for that line is marked ready; REPLAY then
//     answers them oldest-first through the normal hit datapath.
//   * Hits are answered (C2) in every engine state except the three one-cycle
//     hazards below and REPLAY, which lasts only as long as the replays.
//
// Ordering (R5)
//   A queued (not-ready) entry exists only for a line that is NOT resident, so a
//   hit can never overtake an older queued request to the same word. Acceptance
//   is blocked on the victim-select cycle, the install cycle, and during REPLAY,
//   which closes the only windows where that invariant could break.
//
// Liveness (C3)
//   Lines are fetched oldest-first; the writeback read port has priority over
//   load hits so a hit stream cannot starve an eviction; replays have priority
//   over new requests.
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

  localparam int unsigned NB    = DATA_W / 8;
  localparam int unsigned BOFF  = $clog2(NB);
  localparam int unsigned LOFF  = BOFF + unsigned'($clog2(BLOCK_WORDS));   // line offset bits
  localparam int unsigned SB    = $clog2(SETS);
  localparam int unsigned TAG_W = 32 - LOFF - SB;
  localparam int unsigned WB    = $clog2(WAYS);
  // Request slots: 2x the distinct-line floor, so secondary misses to lines
  // already pending do not eat into the C1 capacity. Never more than the 16
  // ids that can be in flight (R6).
  localparam int unsigned RQ_D  = (2 * MAX_MISSES > 16) ? 16 : 2 * MAX_MISSES;
  localparam int unsigned RQ_IW = $clog2(RQ_D);
  localparam int unsigned RQ_CW = $clog2(RQ_D + 1);

  typedef struct packed {
    logic [3:0]        id;
    logic              op;
    logic [TAG_W-1:0]  tag;
    logic [SB-1:0]     set;
    logic [1:0]        word;
    logic [DATA_W-1:0] data;
    logic [NB-1:0]     mask;
  } rq_t;

  typedef enum logic [2:0] {S_IDLE, S_WBREQ, S_WBDAT, S_FREQ, S_FDAT, S_REPLAY} st_t;

  // ---------------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------------
  logic [DATA_W-1:0] data_q  [SETS][WAYS][BLOCK_WORDS];
  logic [TAG_W-1:0]  tag_q   [SETS][WAYS];
  logic [WAYS-1:0]   valid_q [SETS];
  logic [WAYS-1:0]   dirty_q [SETS];

  rq_t               rq_q    [RQ_D];
  logic [RQ_D-1:0]   rq_rdy_q;
  logic [RQ_CW-1:0]  rq_cnt_q;

  st_t               st_q;
  logic [SB-1:0]     e_set_q;
  logic [TAG_W-1:0]  e_tag_q;
  logic [TAG_W-1:0]  e_vtag_q;
  logic [WB-1:0]     e_way_q;
  logic [1:0]        e_beat_q;
  logic [2:0]        wb_rd_q;
  logic [1:0]        wb_tx_q;
  logic              wb_v_q;
  logic [DATA_W-1:0] wb_buf_q;
  logic [WB-1:0]     rr_q;

  logic [3:0]        f_id_q   [2];
  logic [DATA_W-1:0] f_data_q [2];
  logic              f_wr_q, f_rd_q;
  logic [1:0]        f_cnt_q;

  // ---------------------------------------------------------------------------
  // Combinational
  // ---------------------------------------------------------------------------
  logic [1:0]        r_word;
  logic [SB-1:0]     r_set;
  logic [TAG_W-1:0]  r_tag;
  logic              hit;
  logic [WB-1:0]     hit_way;

  logic              rp_any;
  logic              rp_found;
  logic [RQ_IW-1:0]  rp_idx;
  rq_t               rp_e;
  rq_t               rq0;
  rq_t               new_e;

  logic [WB-1:0]     vict;
  logic              vict_inv;

  logic              sel_go, inst, mem_wr_fire, wb_ld;
  logic              f_space, rq_space, acc_ok;
  logic              acc, acc_hit, acc_miss, do_rp;

  logic [SB-1:0]     rd_set;
  logic [WB-1:0]     rd_way;
  logic [1:0]        rd_word;
  logic [DATA_W-1:0] rd_data;

  logic              st_we;
  logic [SB-1:0]     st_set;
  logic [WB-1:0]     st_way;
  logic [1:0]        st_word;
  logic [DATA_W-1:0] st_data;
  logic [NB-1:0]     st_mask;

  logic              f_push, f_pop;
  logic [3:0]        f_push_id;

  assign r_word = req_addr_i[BOFF +: 2];
  assign r_set  = req_addr_i[LOFF +: SB];
  assign r_tag  = req_addr_i[31 -: TAG_W];

  always_comb begin
    hit     = 1'b0;
    hit_way = '0;
    for (int unsigned w = 0; w < WAYS; w++) begin
      if (valid_q[r_set][w] && tag_q[r_set][w] == r_tag) begin
        hit     = 1'b1;
        hit_way = WB'(w);
      end
    end
  end

  // oldest ready entry (queue is age-ordered from index 0)
  always_comb begin
    rp_idx   = '0;
    rp_found = 1'b0;
    for (int unsigned i = 0; i < RQ_D; i++) begin
      if (!rp_found && rq_rdy_q[i]) begin
        rp_idx   = RQ_IW'(i);
        rp_found = 1'b1;
      end
    end
  end
  assign rp_any = |rq_rdy_q;
  assign rp_e   = rq_q[rp_idx];
  assign rq0    = rq_q[0];

  // victim: first invalid way, else round-robin (L1)
  always_comb begin
    vict     = rr_q;
    vict_inv = 1'b0;
    for (int unsigned w = 0; w < WAYS; w++) begin
      if (!vict_inv && !valid_q[rq0.set][w]) begin
        vict     = WB'(w);
        vict_inv = 1'b1;
      end
    end
  end

  assign sel_go      = (st_q == S_IDLE) && (rq_cnt_q != '0);
  assign inst        = (st_q == S_FDAT) && mem_rd_valid_i && (e_beat_q == 2'd3);
  assign mem_wr_fire = mem_wr_valid_o && mem_wr_ready_i;
  assign wb_ld       = (st_q == S_WBDAT) && (wb_rd_q < 3'd4) && (!wb_v_q || mem_wr_fire);
  assign f_space     = (f_cnt_q < 2'd2);
  assign rq_space    = (rq_cnt_q < RQ_CW'(RQ_D));
  assign acc_ok      = !sel_go && !inst && (st_q != S_REPLAY);

  assign req_ready_o = acc_ok && (hit ? (f_space && (req_op_i || !wb_ld)) : rq_space);
  assign acc         = req_valid_i && req_ready_o;
  assign acc_hit     = acc && hit;
  assign acc_miss    = acc && !hit;
  assign do_rp       = (st_q == S_REPLAY) && rp_any && f_space;

  // shared read port: writeback > replay > hit
  always_comb begin
    if (wb_ld) begin
      rd_set = e_set_q; rd_way = e_way_q; rd_word = wb_rd_q[1:0];
    end else if (st_q == S_REPLAY) begin
      rd_set = e_set_q; rd_way = e_way_q; rd_word = rp_e.word;
    end else begin
      rd_set = r_set;   rd_way = hit_way; rd_word = r_word;
    end
  end
  assign rd_data = data_q[rd_set][rd_way][rd_word];

  // store write port: hit store or replayed store (never both)
  assign st_we   = (acc_hit && req_op_i) || (do_rp && rp_e.op);
  assign st_set  = do_rp ? e_set_q    : r_set;
  assign st_way  = do_rp ? e_way_q    : hit_way;
  assign st_word = do_rp ? rp_e.word  : r_word;
  assign st_data = do_rp ? rp_e.data  : req_data_i;
  assign st_mask = do_rp ? rp_e.mask  : req_mask_i;

  assign new_e.id   = req_id_i;
  assign new_e.op   = req_op_i;
  assign new_e.tag  = r_tag;
  assign new_e.set  = r_set;
  assign new_e.word = r_word;
  assign new_e.data = req_data_i;
  assign new_e.mask = req_mask_i;

  // response FIFO (2 entries); store response data is free (R3)
  assign f_push    = acc_hit || do_rp;
  assign f_push_id = do_rp ? rp_e.id : req_id_i;
  assign f_pop     = rsp_valid_o && rsp_ready_i;

  assign rsp_valid_o = (f_cnt_q != 2'd0);
  assign rsp_id_o    = f_id_q[f_rd_q];
  assign rsp_data_o  = f_data_q[f_rd_q];

  // memory port
  assign mem_req_valid_o = (st_q == S_WBREQ) || (st_q == S_FREQ);
  assign mem_req_we_o    = (st_q == S_WBREQ);
  assign mem_req_addr_o  = {(st_q == S_WBREQ) ? e_vtag_q : e_tag_q, e_set_q, {LOFF{1'b0}}};
  assign mem_rd_ready_o  = (st_q == S_FDAT);
  assign mem_wr_valid_o  = (st_q == S_WBDAT) && wb_v_q;
  assign mem_wr_data_o   = wb_buf_q;

  // ---------------------------------------------------------------------------
  // Data and tag arrays (no reset)
  // ---------------------------------------------------------------------------
  always_ff @(posedge clk_i) begin
    if (st_q == S_FDAT && mem_rd_valid_i)
      data_q[e_set_q][e_way_q][e_beat_q] <= mem_rd_data_i;
    if (st_we) begin
      for (int unsigned b = 0; b < NB; b++)
        if (st_mask[b]) data_q[st_set][st_way][st_word][8*b +: 8] <= st_data[8*b +: 8];
    end
    if (inst) tag_q[e_set_q][e_way_q] <= e_tag_q;
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      for (int unsigned s = 0; s < SETS; s++) begin
        valid_q[s] <= '0;
        dirty_q[s] <= '0;
      end
    end else begin
      if (sel_go) valid_q[rq0.set][vict] <= 1'b0;
      if (inst) begin
        valid_q[e_set_q][e_way_q] <= 1'b1;
        dirty_q[e_set_q][e_way_q] <= 1'b0;
      end
      if (st_we) dirty_q[st_set][st_way] <= 1'b1;
    end
  end

  // ---------------------------------------------------------------------------
  // Request queue. Remove (replay), append (miss) and mark-ready (install) are
  // mutually exclusive by construction.
  // ---------------------------------------------------------------------------
  always_ff @(posedge clk_i) begin
    if (do_rp) begin
      for (int unsigned i = 0; i < RQ_D - 1; i++)
        if (i >= 32'(rp_idx)) rq_q[i] <= rq_q[i+1];
    end else if (acc_miss) begin
      for (int unsigned i = 0; i < RQ_D; i++)
        if (i == 32'(rq_cnt_q)) rq_q[i] <= new_e;
    end
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      rq_rdy_q <= '0;
      rq_cnt_q <= '0;
    end else if (do_rp) begin
      for (int unsigned i = 0; i < RQ_D - 1; i++)
        if (i >= 32'(rp_idx)) rq_rdy_q[i] <= rq_rdy_q[i+1];
      rq_rdy_q[RQ_D-1] <= 1'b0;
      rq_cnt_q <= rq_cnt_q - 1'b1;
    end else if (acc_miss) begin
      rq_cnt_q <= rq_cnt_q + 1'b1;
    end else if (inst) begin
      for (int unsigned i = 0; i < RQ_D; i++)
        if (i < 32'(rq_cnt_q) && rq_q[i].set == e_set_q && rq_q[i].tag == e_tag_q)
          rq_rdy_q[i] <= 1'b1;
    end
  end

  // ---------------------------------------------------------------------------
  // Memory engine
  // ---------------------------------------------------------------------------
  always_ff @(posedge clk_i) begin
    if (sel_go) begin
      e_set_q  <= rq0.set;
      e_tag_q  <= rq0.tag;
      e_way_q  <= vict;
      e_vtag_q <= tag_q[rq0.set][vict];
    end
    if (st_q == S_FDAT && mem_rd_valid_i) e_beat_q <= e_beat_q + 1'b1;
    else if (st_q == S_FREQ)              e_beat_q <= 2'd0;
    if (wb_ld) wb_buf_q <= rd_data;
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      st_q    <= S_IDLE;
      rr_q    <= '0;
      wb_rd_q <= '0;
      wb_tx_q <= '0;
      wb_v_q  <= 1'b0;
    end else begin
      case (st_q)
        S_IDLE: begin
          if (sel_go) begin
            rr_q <= rr_q + 1'b1;
            st_q <= (valid_q[rq0.set][vict] && dirty_q[rq0.set][vict]) ? S_WBREQ : S_FREQ;
          end
        end
        S_WBREQ: begin
          wb_rd_q <= '0;
          wb_tx_q <= '0;
          wb_v_q  <= 1'b0;
          if (mem_req_ready_i) st_q <= S_WBDAT;
        end
        S_WBDAT: begin
          if (wb_ld) begin
            wb_v_q  <= 1'b1;
            wb_rd_q <= wb_rd_q + 1'b1;
          end else if (mem_wr_fire) begin
            wb_v_q  <= 1'b0;
          end
          if (mem_wr_fire) begin
            wb_tx_q <= wb_tx_q + 1'b1;
            if (wb_tx_q == 2'd3) st_q <= S_FREQ;
          end
        end
        S_FREQ:   if (mem_req_ready_i) st_q <= S_FDAT;
        S_FDAT:   if (inst) st_q <= S_REPLAY;
        S_REPLAY: if (!rp_any) st_q <= S_IDLE;
        default:  st_q <= S_IDLE;
      endcase
    end
  end

  // ---------------------------------------------------------------------------
  // Response FIFO
  // ---------------------------------------------------------------------------
  always_ff @(posedge clk_i) begin
    if (f_push) begin
      f_id_q[f_wr_q]   <= f_push_id;
      f_data_q[f_wr_q] <= rd_data;
    end
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      f_wr_q  <= 1'b0;
      f_rd_q  <= 1'b0;
      f_cnt_q <= '0;
    end else begin
      if (f_push) f_wr_q <= ~f_wr_q;
      if (f_pop)  f_rd_q <= ~f_rd_q;
      f_cnt_q <= f_cnt_q + {1'b0, f_push} - {1'b0, f_pop};
    end
  end

endmodule