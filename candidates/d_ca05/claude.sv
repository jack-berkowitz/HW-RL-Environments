// =============================================================================
// d_ca05 -- miss_handler_arb
//
// Every declaration is at module scope or at the top of its block, ahead of any
// statement, for T10/slang.
//
// Notes on the three clauses that contradict intuition:
//   F2  arbitration is a plain priority encoder scanned from the highest index
//       down, so the LOWEST index wins and starves the rest. No fairness state.
//   F3  the two comparators are independent reductions over nested bit ranges,
//       so an address match implies an index match; neither is masked by the
//       other and neither excludes the port being served.
//   F8  the atomic is examined BEFORE the flush request, so flush_i asserted
//       with amo_req_i.req takes the atomic's non-acknowledging walk. That is
//       the only ordering that yields F5, F7 and F8 from one flush sequencer.
// =============================================================================
/* verilator lint_off UNUSEDSIGNAL */
module miss_handler_arb
  import miss_handler_arb_pkg::*;
#(
    parameter int unsigned NR_PORTS = 4
) (
    input  logic clk,
    input  logic rst_n,

    input  logic flush_i,
    output logic flush_ack_o,
    output logic miss_o,
    input  logic busy_i,

    input  logic [NR_PORTS-1:0][$bits(miss_req_t)-1:0] miss_req_i,
    output logic [NR_PORTS-1:0]       bypass_gnt_o,
    output logic [NR_PORTS-1:0]       bypass_valid_o,
    output logic [NR_PORTS-1:0][63:0] bypass_data_o,
    output logic [NR_PORTS-1:0]       miss_gnt_o,
    output logic [NR_PORTS-1:0]       active_serving_o,
    output logic [63:0]               critical_word_o,
    output logic                      critical_word_valid_o,

    input  logic [NR_PORTS-1:0][55:0] mshr_addr_i,
    output logic [NR_PORTS-1:0]       mshr_addr_matches_o,
    output logic [NR_PORTS-1:0]       mshr_index_matches_o,

    input  amo_req_t  amo_req_i,
    output amo_resp_t amo_resp_o,

    output axi_req_t axi_bypass_req_o,
    input  axi_rsp_t axi_bypass_rsp_i,

    output axi_req_t axi_data_req_o,
    input  axi_rsp_t axi_data_rsp_i,

    output logic [SET_ASSOC-1:0]        req_o,
    output logic [INDEX_WIDTH-1:0]      addr_o,
    output cache_line_t                 data_o,
    output cl_be_t                      be_o,
    input  cache_line_t [SET_ASSOC-1:0] data_i,
    output logic                        we_o
);

  // --------------------------------------------------------------------------
  // derived geometry
  // --------------------------------------------------------------------------
  localparam int unsigned NUM_BEATS  = LINE_WIDTH / AXI_DATA_W;         // 2
  localparam int unsigned SET_BITS   = INDEX_WIDTH - OFFSET_WIDTH;      // 8
  localparam int unsigned WAY_BITS   = $clog2(SET_ASSOC);               // 3
  localparam int unsigned PORT_BITS  = (NR_PORTS > 1) ? $clog2(NR_PORTS) : 1;
  localparam logic [2:0]  BEAT_SIZE  = 3'd3;                            // 8 bytes
  localparam int unsigned BEAT_BITS  = $clog2(NUM_BEATS + 1);
  localparam logic [BEAT_BITS-1:0]  LAST_BEAT = BEAT_BITS'(NUM_BEATS - 1);
  localparam logic [SET_BITS-1:0]   LAST_SET  = SET_BITS'(NUM_WORDS - 1);

  typedef enum logic [4:0] {
    IDLE,
    FLUSH_RD, FLUSH_WR, FLUSH_END,
    MISS_RD,  MISS_SEL,
    EVICT_AW, EVICT_W, EVICT_B,
    MISS_AR,  MISS_R,   MISS_WR,
    BYP_AR,   BYP_R,
    BYP_AW,   BYP_W,    BYP_B,
    AMO_AW,   AMO_W,    AMO_WAIT
  } state_e;

  // --------------------------------------------------------------------------
  // state
  // --------------------------------------------------------------------------
  state_e                     state_q, state_d;
  logic [SET_BITS-1:0]        flush_cnt_q, flush_cnt_d;
  logic                       flush_ack_en_q, flush_ack_en_d;   // F5 vs F7/F8
  logic                       amo_after_q,    amo_after_d;
  logic                       mshr_valid_q,   mshr_valid_d;
  logic [63:0]                mshr_addr_q,    mshr_addr_d;
  logic [PORT_BITS-1:0]       serve_q,        serve_d;
  logic [WAY_BITS-1:0]        way_q,          way_d;
  logic [WAY_BITS-1:0]        repl_q,         repl_d;
  logic [LINE_WIDTH-1:0]      line_q,         line_d;
  logic [TAG_WIDTH-1:0]       ev_tag_q,       ev_tag_d;
  logic                       ev_need_q,      ev_need_d;
  logic [BEAT_BITS-1:0]       beat_q,         beat_d;
  logic                       b_seen_q,       b_seen_d;
  logic                       r_seen_q,       r_seen_d;
  logic [63:0]                amo_res_q,      amo_res_d;
  logic [63:0]                byp_data_q,     byp_data_d;

  // --------------------------------------------------------------------------
  // request unpacking and the two priority encoders (F2)
  // --------------------------------------------------------------------------
  // miss_req_t is packed, so its fields occupy fixed bit positions. Slicing
  // them out explicitly avoids relying on how a tool reinterprets a vector as
  // a packed struct inside a variable-indexed array.
  localparam int unsigned RQ_W      = $bits(miss_req_t);
  localparam int unsigned RQ_BYPASS = 0;
  localparam int unsigned RQ_WDATA  = RQ_BYPASS + 1;
  localparam int unsigned RQ_WE     = RQ_WDATA  + 64;
  localparam int unsigned RQ_SIZE   = RQ_WE     + 1;
  localparam int unsigned RQ_BE     = RQ_SIZE   + 2;
  localparam int unsigned RQ_ADDR   = RQ_BE     + 8;
  localparam int unsigned RQ_VALID  = RQ_ADDR   + 64;

  logic [NR_PORTS-1:0]       rq_valid;
  logic [NR_PORTS-1:0]       rq_bypass;
  logic [NR_PORTS-1:0]       rq_we;
  logic [NR_PORTS-1:0][63:0] rq_addr;
  logic [NR_PORTS-1:0][63:0] rq_wdata;
  logic [NR_PORTS-1:0][7:0]  rq_be;
  logic [NR_PORTS-1:0][1:0]  rq_size;
  logic                     miss_pend;
  logic [PORT_BITS-1:0]     miss_port;
  logic                     byp_pend;
  logic [PORT_BITS-1:0]     byp_port;

  // Flatten the port once, then slice the 1-D vector. Indexing the outer
  // dimension of the packed 2-D port directly is avoided deliberately.
  logic [NR_PORTS*RQ_W-1:0] rq_flat;
  assign rq_flat = miss_req_i;

  always_comb begin
    for (int unsigned i = 0; i < NR_PORTS; i++) begin
      rq_valid [i] = rq_flat[i*RQ_W + RQ_VALID];
      rq_bypass[i] = rq_flat[i*RQ_W + RQ_BYPASS];
      rq_we    [i] = rq_flat[i*RQ_W + RQ_WE];
      rq_addr  [i] = rq_flat[i*RQ_W + RQ_ADDR  +: 64];
      rq_wdata [i] = rq_flat[i*RQ_W + RQ_WDATA +: 64];
      rq_be    [i] = rq_flat[i*RQ_W + RQ_BE    +: 8];
      rq_size  [i] = rq_flat[i*RQ_W + RQ_SIZE  +: 2];
    end
  end

  // Strict lowest-index priority (F2): the scan runs upward and the first
  // requester found wins, so a continuously-requesting low port locks out every
  // higher one. There is no fairness state anywhere in this module.
  always_comb begin
    miss_pend = 1'b0;
    miss_port = '0;
    byp_pend  = 1'b0;
    byp_port  = '0;
    for (int unsigned i = 0; i < NR_PORTS; i++) begin
      if (rq_valid[i] && !rq_bypass[i] && !miss_pend) begin
        miss_pend = 1'b1;
        miss_port = PORT_BITS'(i);
      end
      if (rq_valid[i] && rq_bypass[i] && !byp_pend) begin
        byp_pend = 1'b1;
        byp_port = PORT_BITS'(i);
      end
    end
  end

  // --------------------------------------------------------------------------
  // F3 -- MSHR interrogation.
  // Two independent comparisons over nested ranges. addr[55:4] contains
  // addr[11:4], so an address match implies an index match; the index output is
  // never cleared because the address matched. No port is excluded, including
  // the one whose miss is in flight.
  // --------------------------------------------------------------------------
  for (genvar gi = 0; gi < NR_PORTS; gi++) begin : g_mshr
    assign mshr_addr_matches_o[gi] =
        mshr_valid_q && (mshr_addr_i[gi][55:OFFSET_WIDTH] ==
                         mshr_addr_q[55:OFFSET_WIDTH]);
    assign mshr_index_matches_o[gi] =
        mshr_valid_q && (mshr_addr_i[gi][INDEX_WIDTH-1:OFFSET_WIDTH] ==
                         mshr_addr_q[INDEX_WIDTH-1:OFFSET_WIDTH]);
  end

  // --------------------------------------------------------------------------
  // AMO -> AXI ATOP encoding (A7). Every mapping keeps atop[5:4] != 2'b00 so
  // the transaction is an atomic write and the memory returns both a B and an
  // R beat; the R carries the pre-operation value.
  // --------------------------------------------------------------------------
  function automatic logic [5:0] atop_of(input amo_t op);
    logic [5:0] r;
    r = 6'b110000;                       // ATOPSWAP
    case (op)
      AMO_ADD:  r = 6'b100000;           // LOAD, little-endian, ADD
      AMO_AND:  r = 6'b100001;           // LOAD, CLR   (operand inverted below)
      AMO_XOR:  r = 6'b100010;           // LOAD, EOR
      AMO_OR:   r = 6'b100011;           // LOAD, SET
      AMO_MAX:  r = 6'b100100;           // LOAD, SMAX
      AMO_MIN:  r = 6'b100101;           // LOAD, SMIN
      AMO_MAXU: r = 6'b100110;           // LOAD, UMAX
      AMO_MINU: r = 6'b100111;           // LOAD, UMIN
      AMO_SWAP: r = 6'b110000;           // ATOPSWAP
      AMO_CAS1: r = 6'b110001;           // ATOPCMP
      AMO_CAS2: r = 6'b110001;
      AMO_LR:   r = 6'b100000;           // read-modify-write with a zero addend
      AMO_SC:   r = 6'b110000;
      default:  r = 6'b110000;
    endcase
    return r;
  endfunction

  logic [63:0] amo_operand;
  logic [7:0]  amo_strb;
  assign amo_operand = (amo_req_i.amo_op == AMO_AND) ? ~amo_req_i.operand_b :
                       (amo_req_i.amo_op == AMO_LR)  ? 64'd0 :
                                                       amo_req_i.operand_b;
  assign amo_strb = (amo_req_i.size == 2'b11) ? 8'hFF :
                    (amo_req_i.size == 2'b10) ? (amo_req_i.operand_a[2] ? 8'hF0 : 8'h0F)
                                              : 8'hFF;

  // --------------------------------------------------------------------------
  // way selection for a refill: an invalid way if one exists, otherwise the
  // replacement counter. Only the second case can require an eviction.
  // --------------------------------------------------------------------------
  logic                 has_invalid;
  logic [WAY_BITS-1:0]  invalid_way;
  always_comb begin
    has_invalid = 1'b0;
    invalid_way = '0;
    for (int unsigned w = SET_ASSOC; w > 0; w--) begin
      if (!data_i[w-1].valid) begin
        has_invalid = 1'b1;
        invalid_way = WAY_BITS'(w - 1);
      end
    end
  end

  // --------------------------------------------------------------------------
  // the FSM
  // --------------------------------------------------------------------------
  logic [$clog2(LINE_WIDTH)-1:0] beat_off;
  logic [63:0] line_addr;
  logic [63:0] evict_addr;
  // beat_q * AXI_DATA_W, with AXI_DATA_W = 64 a shift of 6
  assign beat_off   = {beat_q[0], 6'd0};
  assign line_addr  = {mshr_addr_q[63:OFFSET_WIDTH], {OFFSET_WIDTH{1'b0}}};
  assign evict_addr = {{(64 - TAG_WIDTH - INDEX_WIDTH){1'b0}}, ev_tag_q,
                       mshr_addr_q[INDEX_WIDTH-1:OFFSET_WIDTH],
                       {OFFSET_WIDTH{1'b0}}};

  always_comb begin
    // ---- defaults ----
    state_d        = state_q;
    flush_cnt_d    = flush_cnt_q;
    flush_ack_en_d = flush_ack_en_q;
    amo_after_d    = amo_after_q;
    mshr_valid_d   = mshr_valid_q;
    mshr_addr_d    = mshr_addr_q;
    serve_d        = serve_q;
    way_d          = way_q;
    repl_d         = repl_q;
    line_d         = line_q;
    ev_tag_d       = ev_tag_q;
    ev_need_d      = ev_need_q;
    beat_d         = beat_q;
    b_seen_d       = b_seen_q;
    r_seen_d       = r_seen_q;
    amo_res_d      = amo_res_q;
    byp_data_d     = byp_data_q;

    flush_ack_o           = 1'b0;
    miss_o                = 1'b0;
    bypass_gnt_o          = '0;
    bypass_valid_o        = '0;
    bypass_data_o         = '0;
    miss_gnt_o            = '0;
    active_serving_o      = '0;
    critical_word_o       = '0;
    critical_word_valid_o = 1'b0;
    amo_resp_o.ack        = 1'b0;
    amo_resp_o.result     = amo_res_q;

    req_o  = '0;
    addr_o = '0;
    data_o = '0;
    be_o   = '0;
    we_o   = 1'b0;

    axi_bypass_req_o = '0;
    axi_data_req_o   = '0;

    case (state_q)

      // ----------------------------------------------------------------------
      IDLE: begin
        // Priority: refill, then bypass, then the atomic, then a plain flush.
        // The atomic is tested BEFORE flush_i so that the two asserted together
        // take the non-acknowledging walk -- F8.
        if (miss_pend) begin
          serve_d      = miss_port;
          mshr_addr_d  = rq_addr[miss_port];
          mshr_valid_d = 1'b1;
          miss_o       = 1'b1;
          miss_gnt_o[miss_port] = 1'b1;
          state_d      = MISS_RD;
        end else if (byp_pend) begin
          serve_d  = byp_port;
          mshr_addr_d = rq_addr[byp_port];
          bypass_gnt_o[byp_port] = 1'b1;
          state_d  = rq_we[byp_port] ? BYP_AW : BYP_AR;
        end else if (!busy_i && amo_req_i.req) begin
          // F6/F7/F8: flush first, and this walk never acknowledges.
          flush_ack_en_d = 1'b0;
          amo_after_d    = 1'b1;
          flush_cnt_d    = '0;
          state_d        = FLUSH_RD;
        end else if (!busy_i && flush_i) begin
          // F5: a genuine flush acknowledges.
          flush_ack_en_d = 1'b1;
          amo_after_d    = 1'b0;
          flush_cnt_d    = '0;
          state_d        = FLUSH_RD;
        end
      end

      // ---- F4: the walk. One read then one write per set, all 256 sets in
      // ascending order. 512 requests, 256 writes, and one trailing state, so
      // 513 cycles from entry to idle. No eviction happens here: F4 pins the
      // cost as an absolute, and a walk that wrote back dirty lines would cost
      // a data-dependent amount.
      FLUSH_RD: begin
        req_o   = {SET_ASSOC{1'b1}};
        addr_o  = {flush_cnt_q, {OFFSET_WIDTH{1'b0}}};
        we_o    = 1'b0;
        state_d = FLUSH_WR;
      end

      FLUSH_WR: begin
        req_o        = {SET_ASSOC{1'b1}};
        addr_o       = {flush_cnt_q, {OFFSET_WIDTH{1'b0}}};
        we_o         = 1'b1;
        data_o.valid = 1'b0;
        data_o.dirty = 1'b0;
        be_o.vldrty  = {SET_ASSOC{1'b1}};
        if (flush_cnt_q == LAST_SET) begin
          state_d = FLUSH_END;
        end else begin
          flush_cnt_d = flush_cnt_q + 1'b1;
          state_d     = FLUSH_RD;
        end
      end

      FLUSH_END: begin
        flush_ack_o = flush_ack_en_q;             // F5 pulses, F7/F8 do not
        if (amo_after_q) begin
          b_seen_d    = 1'b0;
          r_seen_d    = 1'b0;
          amo_after_d = 1'b0;
          state_d     = AMO_AW;
        end else begin
          state_d = IDLE;
        end
      end

      // ---- refill --------------------------------------------------------
      MISS_RD: begin
        active_serving_o[serve_q] = 1'b1;
        req_o   = {SET_ASSOC{1'b1}};
        addr_o  = mshr_addr_q[INDEX_WIDTH-1:0];
        we_o    = 1'b0;
        state_d = MISS_SEL;
      end

      MISS_SEL: begin
        active_serving_o[serve_q] = 1'b1;
        if (has_invalid) begin
          way_d     = invalid_way;
          ev_need_d = 1'b0;
        end else begin
          way_d     = repl_q;
          ev_need_d = data_i[repl_q].valid && data_i[repl_q].dirty;
          ev_tag_d  = data_i[repl_q].tag;
          line_d    = data_i[repl_q].data;
          repl_d    = repl_q + 1'b1;
        end
        beat_d  = '0;
        state_d = (!has_invalid && data_i[repl_q].valid && data_i[repl_q].dirty)
                  ? EVICT_AW : MISS_AR;
        ev_need_d = (!has_invalid && data_i[repl_q].valid && data_i[repl_q].dirty);
      end

      EVICT_AW: begin
        active_serving_o[serve_q]  = 1'b1;
        axi_data_req_o.aw_valid    = 1'b1;
        axi_data_req_o.aw.addr     = evict_addr;
        axi_data_req_o.aw.len      = 8'(NUM_BEATS - 1);
        axi_data_req_o.aw.size     = BEAT_SIZE;
        axi_data_req_o.aw.burst    = 2'b01;
        axi_data_req_o.aw.cache    = 4'b0010;
        if (axi_data_rsp_i.aw_ready) begin
          beat_d  = '0;
          state_d = EVICT_W;
        end
      end

      EVICT_W: begin
        active_serving_o[serve_q] = 1'b1;
        axi_data_req_o.w_valid    = 1'b1;
        axi_data_req_o.w.data     = line_q[beat_off +: AXI_DATA_W];
        axi_data_req_o.w.strb     = {(AXI_DATA_W/8){1'b1}};
        axi_data_req_o.w.last     = (beat_q == LAST_BEAT);
        if (axi_data_rsp_i.w_ready) begin
          if (beat_q == LAST_BEAT) state_d = EVICT_B;
          else                     beat_d  = beat_q + 1'b1;
        end
      end

      EVICT_B: begin
        active_serving_o[serve_q] = 1'b1;
        axi_data_req_o.b_ready    = 1'b1;
        if (axi_data_rsp_i.b_valid) begin
          beat_d  = '0;
          state_d = MISS_AR;
        end
      end

      MISS_AR: begin
        active_serving_o[serve_q] = 1'b1;
        axi_data_req_o.ar_valid   = 1'b1;
        axi_data_req_o.ar.addr    = line_addr;
        axi_data_req_o.ar.len     = 8'(NUM_BEATS - 1);
        axi_data_req_o.ar.size    = BEAT_SIZE;
        axi_data_req_o.ar.burst   = 2'b01;
        axi_data_req_o.ar.cache   = 4'b0010;
        if (axi_data_rsp_i.ar_ready) begin
          beat_d  = '0;
          state_d = MISS_R;
        end
      end

      MISS_R: begin
        active_serving_o[serve_q] = 1'b1;
        axi_data_req_o.r_ready    = 1'b1;
        if (axi_data_rsp_i.r_valid) begin
          line_d[beat_off +: AXI_DATA_W] = axi_data_rsp_i.r.data;
          // A3: forward the requested word as it arrives, ahead of the array
          // write. Which beat carries it is the offset bit above the beat size.
          if (beat_q == BEAT_BITS'(mshr_addr_q[3])) begin
            critical_word_o       = axi_data_rsp_i.r.data;
            critical_word_valid_o = 1'b1;
          end
          if (axi_data_rsp_i.r.last || (beat_q == LAST_BEAT)) state_d = MISS_WR;
          else                                                beat_d  = beat_q + 1'b1;
        end
      end

      MISS_WR: begin
        active_serving_o[serve_q] = 1'b1;
        req_o        = '0;
        req_o[way_q] = 1'b1;
        addr_o       = mshr_addr_q[INDEX_WIDTH-1:0];
        we_o         = 1'b1;
        data_o.tag   = mshr_addr_q[TAG_WIDTH+INDEX_WIDTH-1:INDEX_WIDTH];
        data_o.data  = line_q;
        data_o.valid = 1'b1;
        data_o.dirty = 1'b0;
        be_o.tag     = '1;
        be_o.data    = '1;
        be_o.vldrty  = '0;
        be_o.vldrty[way_q] = 1'b1;
        mshr_valid_d = 1'b0;
        state_d      = IDLE;
      end

      // ---- bypass --------------------------------------------------------
      BYP_AR: begin
        axi_bypass_req_o.ar_valid = 1'b1;
        axi_bypass_req_o.ar.addr  = mshr_addr_q;
        axi_bypass_req_o.ar.len   = 8'd0;
        axi_bypass_req_o.ar.size  = {1'b0, rq_size[serve_q]};
        axi_bypass_req_o.ar.burst = 2'b01;
        if (axi_bypass_rsp_i.ar_ready) state_d = BYP_R;
      end

      BYP_R: begin
        axi_bypass_req_o.r_ready = 1'b1;
        if (axi_bypass_rsp_i.r_valid) begin
          bypass_valid_o[serve_q] = 1'b1;
          bypass_data_o[serve_q]  = axi_bypass_rsp_i.r.data;
          state_d                 = IDLE;
        end
      end

      BYP_AW: begin
        axi_bypass_req_o.aw_valid = 1'b1;
        axi_bypass_req_o.aw.addr  = mshr_addr_q;
        axi_bypass_req_o.aw.len   = 8'd0;
        axi_bypass_req_o.aw.size  = {1'b0, rq_size[serve_q]};
        axi_bypass_req_o.aw.burst = 2'b01;
        byp_data_d                = rq_wdata[serve_q];
        if (axi_bypass_rsp_i.aw_ready) state_d = BYP_W;
      end

      BYP_W: begin
        axi_bypass_req_o.w_valid = 1'b1;
        axi_bypass_req_o.w.data  = byp_data_q;
        axi_bypass_req_o.w.strb  = rq_be[serve_q];
        axi_bypass_req_o.w.last  = 1'b1;
        if (axi_bypass_rsp_i.w_ready) state_d = BYP_B;
      end

      BYP_B: begin
        axi_bypass_req_o.b_ready = 1'b1;
        if (axi_bypass_rsp_i.b_valid) begin
          bypass_valid_o[serve_q] = 1'b1;
          bypass_data_o[serve_q]  = '0;
          state_d                 = IDLE;
        end
      end

      // ---- atomic (A7): an ATOP write, and BOTH a B and an R are consumed --
      AMO_AW: begin
        axi_bypass_req_o.aw_valid = 1'b1;
        axi_bypass_req_o.aw.addr  = amo_req_i.operand_a;
        axi_bypass_req_o.aw.len   = 8'd0;
        axi_bypass_req_o.aw.size  = {1'b0, amo_req_i.size};
        axi_bypass_req_o.aw.burst = 2'b01;
        axi_bypass_req_o.aw.atop  = atop_of(amo_req_i.amo_op);
        if (axi_bypass_rsp_i.aw_ready) state_d = AMO_W;
      end

      AMO_W: begin
        axi_bypass_req_o.w_valid = 1'b1;
        axi_bypass_req_o.w.data  = amo_operand;
        axi_bypass_req_o.w.strb  = amo_strb;
        axi_bypass_req_o.w.last  = 1'b1;
        if (axi_bypass_rsp_i.w_ready) begin
          b_seen_d = 1'b0;
          r_seen_d = 1'b0;
          state_d  = AMO_WAIT;
        end
      end

      AMO_WAIT: begin
        // Waiting only for B hangs against a memory that also returns R (T7).
        axi_bypass_req_o.b_ready = ~b_seen_q;
        axi_bypass_req_o.r_ready = ~r_seen_q;
        if (axi_bypass_rsp_i.b_valid && !b_seen_q) b_seen_d = 1'b1;
        if (axi_bypass_rsp_i.r_valid && !r_seen_q) begin
          r_seen_d  = 1'b1;
          amo_res_d = axi_bypass_rsp_i.r.data;
        end
        if ((b_seen_q || axi_bypass_rsp_i.b_valid) &&
            (r_seen_q || axi_bypass_rsp_i.r_valid)) begin
          amo_resp_o.ack    = 1'b1;
          amo_resp_o.result = (r_seen_q) ? amo_res_q : axi_bypass_rsp_i.r.data;
          b_seen_d          = 1'b0;
          r_seen_d          = 1'b0;
          state_d           = IDLE;
        end
      end

      default: state_d = IDLE;
    endcase
  end

  // --------------------------------------------------------------------------
  // A5: asynchronous assert, synchronous release. A reset mid-operation
  // discards; nothing drains.
  // --------------------------------------------------------------------------
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state_q        <= IDLE;
      flush_cnt_q    <= '0;
      flush_ack_en_q <= 1'b0;
      amo_after_q    <= 1'b0;
      mshr_valid_q   <= 1'b0;
      mshr_addr_q    <= '0;
      serve_q        <= '0;
      way_q          <= '0;
      repl_q         <= '0;
      line_q         <= '0;
      ev_tag_q       <= '0;
      ev_need_q      <= 1'b0;
      beat_q         <= '0;
      b_seen_q       <= 1'b0;
      r_seen_q       <= 1'b0;
      amo_res_q      <= '0;
      byp_data_q     <= '0;
    end else begin
      state_q        <= state_d;
      flush_cnt_q    <= flush_cnt_d;
      flush_ack_en_q <= flush_ack_en_d;
      amo_after_q    <= amo_after_d;
      mshr_valid_q   <= mshr_valid_d;
      mshr_addr_q    <= mshr_addr_d;
      serve_q        <= serve_d;
      way_q          <= way_d;
      repl_q         <= repl_d;
      line_q         <= line_d;
      ev_tag_q       <= ev_tag_d;
      ev_need_q      <= ev_need_d;
      beat_q         <= beat_d;
      b_seen_q       <= b_seen_d;
      r_seen_q       <= r_seen_d;
      amo_res_q      <= amo_res_d;
      byp_data_q     <= byp_data_d;
    end
  end

endmodule
/* verilator lint_on UNUSEDSIGNAL */