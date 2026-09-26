// =============================================================================
// miss_handler_arb -- d_ca05
//
// A reconstruction of CVA6's std_cache miss_handler, including the pieces it
// instantiates (bypass arbiter, two AXI adapters, 8-bit replacement LFSR),
// flattened into one module and specialised to what each instance is actually
// driven with:
//
//   * main FSM      : INIT walk after reset, IDLE priority AMO < flush < miss,
//                     MISS/MISS_REPL/REQ_CACHELINE/SAVE_CACHELINE refill,
//                     WB_CACHELINE_{MISS,FLUSH} eviction, FLUSH_REQ_STATUS /
//                     FLUSHING walk (one read + one write per clean set),
//                     AMO_REQ / AMO_WAIT_RESP.
//   * serve_amo     : the one bit that produces F7 and F8. An atomic taken in
//                     IDLE sets it before the walk, the flush branch in the same
//                     IDLE cycle leaves it set, and the walk's completion
//                     acknowledges only when it is clear. A miss in the same
//                     cycle clears it (F9).
//   * bypass arbiter: strict lowest-index priority over the NR_PORTS requesters
//                     plus the AMO port (highest index, lowest priority), one
//                     transaction at a time (F2).
//   * bypass adapter: single-beat AXI reads/writes and ATOP writes; an ATOP
//                     that returns data consumes B and then R (A7).
//   * refill adapter: 2-beat INCR cacheline reads and dirty-line evictions,
//                     forwarding the requested word as it arrives (A3).
//   * MSHR matching : address and index compared independently against the
//                     held miss, no exclusion of the requester being served
//                     (F3 a, b).
// =============================================================================
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

  // ---------------------------------------------------------------------------
  // Constants and types
  // ---------------------------------------------------------------------------
  localparam int unsigned NB    = NR_PORTS + 1;                  // + AMO port
  localparam int unsigned SELW  = $clog2(NB);
  localparam int unsigned IDW   = (NR_PORTS > 1) ? $clog2(NR_PORTS) : 1;
  localparam int unsigned AW56  = TAG_WIDTH + INDEX_WIDTH;       // 56

  localparam logic [1:0] BURST_FIXED = 2'b00;
  localparam logic [1:0] BURST_INCR  = 2'b01;
  localparam logic [3:0] CACHE_MOD   = 4'b0010;
  localparam logic [1:0] RESP_EXOKAY = 2'b01;

  typedef struct packed {
    logic        req;
    amo_t        amo;
    logic [3:0]  id;
    logic [63:0] addr;
    logic        we;
    logic [63:0] wdata;
    logic [7:0]  be;
    logic [1:0]  size;
  } byp_req_t;

  typedef struct packed {
    logic        gnt;
    logic        valid;
    logic [63:0] rdata;
  } byp_rsp_t;

  typedef struct packed {
    logic            valid;
    logic [IDW-1:0]  id;
    logic [AW56-1:0] addr;
    logic            we;
    logic [7:0]      be;
    logic [63:0]     wdata;
  } mshr_t;

  typedef enum logic [3:0] {
    IDLE, FLUSHING, WB_CACHELINE_FLUSH, FLUSH_REQ_STATUS, WB_CACHELINE_MISS,
    MISS, REQ_CACHELINE, MISS_REPL, SAVE_CACHELINE, INIT, AMO_REQ, AMO_WAIT_RESP
  } st_t;

  typedef enum logic [2:0] {
    B_IDLE, B_WAIT_B, B_WAIT_AW, B_WAIT_W, B_WAIT_R, B_COMPLETE, B_WAIT_AMO_R
  } bst_t;

  typedef enum logic [2:0] {
    D_IDLE, D_WAIT_B, D_WAIT_W, D_WAIT_W_AW, D_WAIT_AW_BURST, D_WAIT_R, D_COMPLETE
  } dst_t;

  // ---------------------------------------------------------------------------
  // Functions
  // ---------------------------------------------------------------------------
  function automatic logic [5:0] atop_from_amo(input amo_t amo);
    case (amo)
      AMO_SWAP: return 6'b110000;
      AMO_ADD:  return 6'b100000;
      AMO_AND:  return 6'b100001;     // CLR, operand inverted upstream
      AMO_OR:   return 6'b100011;     // SET
      AMO_XOR:  return 6'b100010;     // EOR
      AMO_MAX:  return 6'b100100;     // SMAX
      AMO_MAXU: return 6'b100110;     // UMAX
      AMO_MIN:  return 6'b100101;     // SMIN
      AMO_MINU: return 6'b100111;     // UMIN
      default:  return 6'b000000;
    endcase
  endfunction

  function automatic logic amo_returns_data(input amo_t amo);
    logic [5:0] a;
    a = atop_from_amo(amo);
    return (a[5:4] == 2'b10) || (a[5:4] == 2'b11);
  endfunction

  function automatic logic [63:0] data_align(input logic [2:0] off, input logic [63:0] d);
    case (off)
      3'd1:    return {d[55:0], d[63:56]};
      3'd2:    return {d[47:0], d[63:48]};
      3'd3:    return {d[39:0], d[63:40]};
      3'd4:    return {d[31:0], d[63:32]};
      3'd5:    return {d[23:0], d[63:24]};
      3'd6:    return {d[15:0], d[63:16]};
      3'd7:    return {d[7:0],  d[63:8]};
      default: return d;
    endcase
  endfunction

  // ---------------------------------------------------------------------------
  // Declarations
  // ---------------------------------------------------------------------------
  miss_req_t [NR_PORTS-1:0] mreq;

  // main FSM
  st_t                   state_q, state_d;
  mshr_t                 mshr_q, mshr_d;
  logic [INDEX_WIDTH-1:0] cnt_q, cnt_d;
  logic [SET_ASSOC-1:0]  evict_way_q, evict_way_d;
  logic [TAG_WIDTH-1:0]  evict_tag_q, evict_tag_d;
  logic [LINE_WIDTH-1:0] evict_data_q, evict_data_d;
  logic                  serve_amo_q, serve_amo_d;

  logic [SET_ASSOC-1:0]  dirty_way, valid_way;
  logic [SET_ASSOC-1:0]  first_dirty, first_invalid;
  logic [2:0]            first_dirty_bin;

  // LFSR
  logic [7:0]            lfsr_q;
  logic                  lfsr_en;
  logic                  lfsr_in;

  // refill adapter interface
  logic                  dm_req, dm_we, dm_gnt, dm_valid;
  logic [63:0]           dm_addr;
  logic [LINE_WIDTH-1:0] dm_wdata;
  logic [15:0]           dm_be;

  // refill adapter state
  dst_t                  d_st_q, d_st_d;
  logic                  d_cnt_q, d_cnt_d;
  logic                  d_off_q, d_off_d;
  logic [1:0][63:0]      d_line_q, d_line_d;
  logic                  d_idx;

  // AMO port into the bypass arbiter
  byp_req_t              amo_breq;
  logic [63:0]           amo_opb;

  // bypass arbiter
  byp_req_t [NB-1:0]     arb_req;
  byp_rsp_t [NB-1:0]     arb_rsp;
  logic                  arb_serving_q, arb_serving_d;
  logic [SELW-1:0]       sel_q, sel_d;
  byp_req_t              areq_q, areq_d;
  byp_req_t              br;           // arbiter -> bypass adapter
  byp_rsp_t              bs;           // bypass adapter -> arbiter

  // bypass adapter state
  bst_t                  b_st_q, b_st_d;
  logic [63:0]           b_line_q, b_line_d;
  amo_t                  b_amo_q, b_amo_d;

  // ---------------------------------------------------------------------------
  // Requests
  // ---------------------------------------------------------------------------
  always_comb begin
    for (int unsigned i = 0; i < NR_PORTS; i++) begin
      mreq[i]              = miss_req_t'(miss_req_i[i]);
      arb_req[i]           = '0;
      arb_req[i].req       = mreq[i].valid & mreq[i].bypass;
      arb_req[i].amo       = AMO_NONE;
      arb_req[i].id        = {2'b10, i[1:0]};
      arb_req[i].addr      = mreq[i].addr;
      arb_req[i].we        = mreq[i].we;
      arb_req[i].wdata     = mreq[i].wdata;
      arb_req[i].be        = mreq[i].be;
      arb_req[i].size      = mreq[i].size;
      bypass_gnt_o[i]      = arb_rsp[i].gnt;
      bypass_valid_o[i]    = arb_rsp[i].valid;
      bypass_data_o[i]     = arb_rsp[i].rdata;
    end
    arb_req[NR_PORTS] = amo_breq;
  end

  // ---------------------------------------------------------------------------
  // MSHR matching -- F3: independent comparisons, requester not excluded
  // ---------------------------------------------------------------------------
  // the index comparison is a sub-range of the address comparison and is shared
  logic [NR_PORTS-1:0] idx_eq;
  always_comb begin
    for (int unsigned i = 0; i < NR_PORTS; i++) begin
      idx_eq[i] = mshr_addr_i[i][INDEX_WIDTH-1:OFFSET_WIDTH] == mshr_q.addr[INDEX_WIDTH-1:OFFSET_WIDTH];
      mshr_index_matches_o[i] = mshr_q.valid && idx_eq[i];
      mshr_addr_matches_o[i]  = mshr_q.valid && idx_eq[i]
                              && (mshr_addr_i[i][55:INDEX_WIDTH] == mshr_q.addr[55:INDEX_WIDTH]);
    end
  end

  // ---------------------------------------------------------------------------
  // Way selection helpers
  // ---------------------------------------------------------------------------
  always_comb begin
    first_dirty     = '0;
    first_invalid   = '0;
    first_dirty_bin = '0;
    for (int unsigned w = 0; w < SET_ASSOC; w++) begin
      dirty_way[w] = data_i[w].valid & data_i[w].dirty;
      valid_way[w] = data_i[w].valid;
    end
    for (int w = SET_ASSOC - 1; w >= 0; w--) begin
      if (dirty_way[w]) begin
        first_dirty     = '0;
        first_dirty[w]  = 1'b1;
        first_dirty_bin = w[2:0];
      end
      if (!valid_way[w]) begin
        first_invalid    = '0;
        first_invalid[w] = 1'b1;
      end
    end
  end

  // ---------------------------------------------------------------------------
  // Refill-miss selection: lowest-index requester with a non-bypass miss
  // ---------------------------------------------------------------------------
  logic            miss_any;
  logic [IDW-1:0]  miss_idx;
  mshr_t           miss_new;

  always_comb begin
    miss_any = 1'b0;
    miss_idx = '0;
    for (int i = NR_PORTS - 1; i >= 0; i--) begin
      if (mreq[i].valid && !mreq[i].bypass) begin
        miss_any = 1'b1;
        miss_idx = i[IDW-1:0];
      end
    end
  end

  always_comb begin
    miss_new       = '0;
    miss_new.valid = 1'b1;
    miss_new.id    = miss_idx;
    miss_new.we    = mreq[miss_idx].we;
    miss_new.addr  = mreq[miss_idx].addr[AW56-1:0];
    miss_new.wdata = mreq[miss_idx].wdata;
    miss_new.be    = mreq[miss_idx].be;
  end

  // ---------------------------------------------------------------------------
  // Request-side outputs of the FSM (kept apart from the response side so the
  // dataflow FSM -> adapter/arbiter -> FSM is visibly acyclic)
  // ---------------------------------------------------------------------------
  always_comb begin
    dm_req   = 1'b0;
    dm_addr  = '0;
    dm_wdata = '0;
    dm_we    = 1'b0;
    dm_be    = '0;
    if (state_q == REQ_CACHELINE) begin
      dm_req  = 1'b1;
      dm_addr = {{(64 - AW56){1'b0}}, mshr_q.addr};
    end else if (state_q == WB_CACHELINE_FLUSH || state_q == WB_CACHELINE_MISS) begin
      dm_req   = 1'b1;
      dm_addr  = {{(64 - AW56){1'b0}}, evict_tag_q, cnt_q[INDEX_WIDTH-1:OFFSET_WIDTH], {OFFSET_WIDTH{1'b0}}};
      dm_be    = '1;
      dm_we    = 1'b1;
      dm_wdata = evict_data_q;
    end
  end

  always_comb begin
    amo_breq      = '0;
    amo_breq.amo  = AMO_NONE;
    amo_breq.size = 2'b11;
    amo_breq.id   = 4'b1011;
    amo_opb       = '0;
    if (state_q == AMO_REQ) begin
      amo_breq.req   = 1'b1;
      amo_breq.amo   = amo_req_i.amo_op;
      amo_breq.addr  = amo_req_i.operand_a;
      amo_breq.we    = (amo_req_i.amo_op != AMO_LR);
      amo_breq.size  = amo_req_i.size;
      amo_opb        = (amo_req_i.amo_op == AMO_AND) ? ~amo_req_i.operand_b : amo_req_i.operand_b;
      amo_breq.wdata = data_align(amo_req_i.operand_a[2:0], amo_opb);
      if (amo_req_i.size == 2'b11)             amo_breq.be = 8'hFF;
      else if (amo_req_i.operand_a[2:0] == '0) amo_breq.be = 8'h0F;
      else                                     amo_breq.be = 8'hF0;
    end
  end

  // ---------------------------------------------------------------------------
  // Main FSM
  // ---------------------------------------------------------------------------
  always_comb begin
    req_o  = '0;
    addr_o = '0;
    data_o = '0;
    be_o   = '0;
    we_o   = 1'b0;

    miss_gnt_o       = '0;
    active_serving_o = '0;
    active_serving_o[mshr_q.id] = mshr_q.valid;

    lfsr_en = 1'b0;

    flush_ack_o = 1'b0;
    miss_o      = 1'b0;

    amo_resp_o = '0;

    state_d      = state_q;
    cnt_d        = cnt_q;
    evict_way_d  = evict_way_q;
    evict_tag_d  = evict_tag_q;
    evict_data_d = evict_data_q;
    mshr_d       = mshr_q;
    serve_amo_d  = serve_amo_q;

    case (state_q)
      IDLE: begin
        // lowest priority: the atomic (flush first, then the operation)
        if (amo_req_i.req && !busy_i) begin
          if (!serve_amo_q) begin
            state_d     = FLUSH_REQ_STATUS;
            serve_amo_d = 1'b1;
            cnt_d       = '0;
          end else begin
            state_d     = AMO_REQ;
            serve_amo_d = 1'b0;
          end
        end
        // a flush; serve_amo_d is deliberately left as the AMO branch set it,
        // which is what suppresses the acknowledgement in F8
        if (flush_i && !busy_i) begin
          state_d = FLUSH_REQ_STATUS;
          cnt_d   = '0;
        end
        // highest priority: a refill miss, lowest port first (F9)
        if (miss_any) begin
          state_d     = MISS;
          serve_amo_d = 1'b0;
          mshr_d      = miss_new;
        end
      end

      MISS: begin
        req_o   = '1;
        addr_o  = mshr_q.addr[INDEX_WIDTH-1:0];
        state_d = MISS_REPL;
        miss_o  = 1'b1;
      end

      MISS_REPL: begin
        if (&valid_way) begin
          lfsr_en     = 1'b1;
          evict_way_d = SET_ASSOC'(1'b1) << lfsr_q[2:0];
          if (data_i[lfsr_q[2:0]].dirty) begin
            state_d      = WB_CACHELINE_MISS;
            evict_tag_d  = data_i[lfsr_q[2:0]].tag;
            evict_data_d = data_i[lfsr_q[2:0]].data;
            cnt_d        = mshr_q.addr[INDEX_WIDTH-1:0];
          end else begin
            state_d = REQ_CACHELINE;
          end
        end else begin
          evict_way_d = first_invalid;
          state_d     = REQ_CACHELINE;
        end
      end

      REQ_CACHELINE: begin
        if (dm_gnt) begin
          state_d = SAVE_CACHELINE;
          miss_gnt_o[mshr_q.id] = 1'b1;
        end
      end

      SAVE_CACHELINE: begin
        if (dm_valid) begin
          addr_o       = mshr_q.addr[INDEX_WIDTH-1:0];
          req_o        = evict_way_q;
          we_o         = 1'b1;
          be_o         = '1;
          be_o.vldrty  = evict_way_q;
          data_o.tag   = mshr_q.addr[AW56-1:INDEX_WIDTH];
          data_o.data  = LINE_WIDTH'(d_line_q);
          data_o.valid = 1'b1;
          data_o.dirty = 1'b0;
          if (mshr_q.we) begin
            for (int b = 0; b < 8; b++) begin
              if (mshr_q.be[b])
                data_o.data[{mshr_q.addr[3], 6'd0} + {b[3:0], 3'd0} +: 8] = mshr_q.wdata[8*b +: 8];
            end
            data_o.dirty = 1'b1;
          end
          mshr_d.valid = 1'b0;
          state_d      = IDLE;
        end
      end

      WB_CACHELINE_FLUSH, WB_CACHELINE_MISS: begin
        if (dm_gnt) begin
          addr_o       = cnt_q;
          req_o        = SET_ASSOC'(1);
          we_o         = 1'b1;
          data_o.valid = 1'b0;               // invalidate on flush
          be_o.vldrty  = evict_way_q;
          state_d      = (state_q == WB_CACHELINE_MISS) ? MISS : FLUSH_REQ_STATUS;
        end
      end

      FLUSH_REQ_STATUS: begin
        req_o   = '1;
        addr_o  = cnt_q;
        state_d = FLUSHING;
      end

      FLUSHING: begin
        if (|dirty_way) begin
          evict_way_d  = first_dirty;
          evict_tag_d  = data_i[first_dirty_bin].tag;
          evict_data_d = data_i[first_dirty_bin].data;
          state_d      = WB_CACHELINE_FLUSH;
        end else begin
          cnt_d       = cnt_q + INDEX_WIDTH'(16'd1 << OFFSET_WIDTH);
          state_d     = FLUSH_REQ_STATUS;
          addr_o      = cnt_q;
          req_o       = SET_ASSOC'(1);
          be_o.vldrty = '1;
          we_o        = 1'b1;
          if (cnt_q[INDEX_WIDTH-1:OFFSET_WIDTH] == (INDEX_WIDTH - OFFSET_WIDTH)'(NUM_WORDS - 1)) begin
            flush_ack_o = ~serve_amo_q;      // F5 / F7 / F8
            state_d     = IDLE;
          end
        end
      end

      INIT: begin
        addr_o      = cnt_q;
        req_o       = SET_ASSOC'(1);
        we_o        = 1'b1;
        be_o.vldrty = '1;
        cnt_d       = cnt_q + INDEX_WIDTH'(16'd1 << OFFSET_WIDTH);
        if (cnt_q[INDEX_WIDTH-1:OFFSET_WIDTH] == (INDEX_WIDTH - OFFSET_WIDTH)'(NUM_WORDS - 1))
          state_d = IDLE;
      end

      AMO_REQ: begin
        if (arb_rsp[NR_PORTS].gnt) state_d = AMO_WAIT_RESP;
      end

      AMO_WAIT_RESP: begin
        if (arb_rsp[NR_PORTS].valid) begin
          state_d        = IDLE;
          amo_resp_o.ack = 1'b1;
          if (amo_req_i.size == 2'b10) begin
            amo_resp_o.result = amo_req_i.operand_a[2]
                              ? {{32{arb_rsp[NR_PORTS].rdata[63]}}, arb_rsp[NR_PORTS].rdata[63:32]}
                              : {{32{arb_rsp[NR_PORTS].rdata[31]}}, arb_rsp[NR_PORTS].rdata[31:0]};
          end else begin
            amo_resp_o.result = arb_rsp[NR_PORTS].rdata;
          end
        end
      end

      default: state_d = IDLE;
    endcase
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state_q      <= INIT;
      mshr_q       <= '0;
      cnt_q        <= '0;
      evict_way_q  <= '0;
      evict_tag_q  <= '0;
      evict_data_q <= '0;
      serve_amo_q  <= 1'b0;
    end else begin
      state_q      <= state_d;
      mshr_q       <= mshr_d;
      cnt_q        <= cnt_d;
      evict_way_q  <= evict_way_d;
      evict_tag_q  <= evict_tag_d;
      evict_data_q <= evict_data_d;
      serve_amo_q  <= serve_amo_d;
    end
  end

  // ---------------------------------------------------------------------------
  // Replacement LFSR (8-bit, seed 0)
  // ---------------------------------------------------------------------------
  assign lfsr_in = !(lfsr_q[7] ^ lfsr_q[3] ^ lfsr_q[2] ^ lfsr_q[1]);

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n)       lfsr_q <= '0;
    else if (lfsr_en) lfsr_q <= {lfsr_q[6:0], lfsr_in};
  end

  // ---------------------------------------------------------------------------
  // Bypass arbiter -- strict lowest-index priority, one transaction at a time
  // ---------------------------------------------------------------------------
  logic arb_any;

  always_comb begin
    sel_d   = sel_q;
    arb_any = 1'b0;
    for (int i = NB - 1; i >= 0; i--) begin
      if (arb_req[i].req) begin
        sel_d   = i[SELW-1:0];
        arb_any = 1'b1;
      end
    end
    if (arb_serving_q) sel_d = sel_q;
    areq_d = arb_serving_q ? areq_q : arb_req[sel_d];
    br     = areq_d;
  end

  always_comb begin
    arb_serving_d = arb_serving_q;
    arb_rsp       = '0;
    arb_rsp[sel_q].rdata = bs.rdata;
    if (!arb_serving_q) begin
      if (arb_any) arb_serving_d = 1'b1;
      arb_rsp[sel_d].gnt = bs.gnt;
    end else begin
      arb_rsp[sel_q] = bs;
      if (bs.valid) arb_serving_d = 1'b0;
    end
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      arb_serving_q <= 1'b0;
      sel_q         <= '0;
      areq_q        <= '0;
    end else begin
      arb_serving_q <= arb_serving_d;
      sel_q         <= sel_d;
      areq_q        <= areq_d;
    end
  end

  // ---------------------------------------------------------------------------
  // Bypass AXI adapter -- single-beat reads, writes and ATOP writes
  // ---------------------------------------------------------------------------
  always_comb begin
    axi_bypass_req_o          = '0;
    axi_bypass_req_o.aw.addr  = br.addr;
    axi_bypass_req_o.aw.size  = {1'b0, br.size};
    axi_bypass_req_o.aw.burst = BURST_FIXED;
    axi_bypass_req_o.aw.cache = CACHE_MOD;
    axi_bypass_req_o.aw.id    = br.id;
    axi_bypass_req_o.aw.atop  = atop_from_amo(br.amo);
    axi_bypass_req_o.ar.addr  = br.addr;
    axi_bypass_req_o.ar.size  = {1'b0, br.size};
    axi_bypass_req_o.ar.burst = BURST_FIXED;
    axi_bypass_req_o.ar.cache = CACHE_MOD;
    axi_bypass_req_o.ar.id    = br.id;
    axi_bypass_req_o.w.data   = br.wdata;
    axi_bypass_req_o.w.strb   = br.be;

    bs       = '0;
    bs.rdata = b_line_q;
    b_st_d   = b_st_q;
    b_line_d = b_line_q;
    b_amo_d  = b_amo_q;

    case (b_st_q)
      B_IDLE: begin
        if (br.req) begin
          if (br.we) begin
            axi_bypass_req_o.aw_valid = 1'b1;
            axi_bypass_req_o.w_valid  = 1'b1;
            axi_bypass_req_o.aw.lock  = (br.amo == AMO_SC);
            axi_bypass_req_o.w.last   = 1'b1;
            bs.gnt = axi_bypass_rsp_i.aw_ready & axi_bypass_rsp_i.w_ready;
            case ({axi_bypass_rsp_i.aw_ready, axi_bypass_rsp_i.w_ready})
              2'b11:   b_st_d = B_WAIT_B;
              2'b01:   b_st_d = B_WAIT_AW;
              2'b10:   b_st_d = B_WAIT_W;
              default: b_st_d = B_IDLE;
            endcase
            if (axi_bypass_rsp_i.aw_ready) b_amo_d = br.amo;
          end else begin
            axi_bypass_req_o.ar_valid = 1'b1;
            axi_bypass_req_o.ar.lock  = (br.amo == AMO_LR);
            bs.gnt = axi_bypass_rsp_i.ar_ready;
            if (axi_bypass_rsp_i.ar_ready) b_st_d = B_WAIT_R;
          end
        end
      end

      B_WAIT_AW: begin
        axi_bypass_req_o.aw_valid = 1'b1;
        if (axi_bypass_rsp_i.aw_ready) begin
          bs.gnt  = 1'b1;
          b_st_d  = B_WAIT_B;
          b_amo_d = br.amo;
        end
      end

      B_WAIT_W: begin
        axi_bypass_req_o.w_valid = 1'b1;
        axi_bypass_req_o.w.last  = 1'b1;
        if (axi_bypass_rsp_i.w_ready) begin
          bs.gnt = 1'b1;
          b_st_d = B_WAIT_B;
        end
      end

      B_WAIT_B: begin
        if (axi_bypass_rsp_i.b_valid) begin
          axi_bypass_req_o.b_ready = 1'b1;
          if (amo_returns_data(b_amo_q)) begin
            if (axi_bypass_rsp_i.r_valid) begin
              axi_bypass_req_o.r_ready = 1'b1;
              bs.valid = 1'b1;
              bs.rdata = axi_bypass_rsp_i.r.data;
              b_st_d   = B_IDLE;
            end else begin
              b_st_d = B_WAIT_AMO_R;
            end
          end else begin
            bs.valid = 1'b1;
            b_st_d   = B_IDLE;
            if (b_amo_q == AMO_SC)
              bs.rdata = (axi_bypass_rsp_i.b.resp == RESP_EXOKAY) ? 64'd0 : 64'd1;
          end
        end
      end

      B_WAIT_AMO_R: begin
        axi_bypass_req_o.r_ready = 1'b1;
        if (axi_bypass_rsp_i.r_valid) begin
          bs.valid = 1'b1;
          bs.rdata = axi_bypass_rsp_i.r.data;
          b_st_d   = B_IDLE;
        end
      end

      B_WAIT_R: begin
        axi_bypass_req_o.r_ready = 1'b1;
        if (axi_bypass_rsp_i.r_valid) begin
          b_line_d = axi_bypass_rsp_i.r.data;
          if (axi_bypass_rsp_i.r.last) b_st_d = B_COMPLETE;
        end
      end

      B_COMPLETE: begin
        bs.valid = 1'b1;
        b_st_d   = B_IDLE;
      end

      default: b_st_d = B_IDLE;
    endcase
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      b_st_q   <= B_IDLE;
      b_line_q <= '0;
      b_amo_q  <= AMO_NONE;
    end else begin
      b_st_q   <= b_st_d;
      b_line_q <= b_line_d;
      b_amo_q  <= b_amo_d;
    end
  end

  // ---------------------------------------------------------------------------
  // Refill AXI adapter -- 2-beat INCR cacheline reads and evictions
  // ---------------------------------------------------------------------------
  assign d_idx = ~d_cnt_q;                 // beat index = BURST_SIZE - cnt

  always_comb begin
    axi_data_req_o           = '0;
    axi_data_req_o.aw.addr   = dm_addr;
    axi_data_req_o.aw.size   = 3'b011;
    axi_data_req_o.aw.burst  = BURST_INCR;
    axi_data_req_o.aw.cache  = CACHE_MOD;
    axi_data_req_o.aw.id     = 4'b1100;
    axi_data_req_o.ar.addr   = {dm_addr[63:OFFSET_WIDTH], {OFFSET_WIDTH{1'b0}}};
    axi_data_req_o.ar.size   = 3'b011;
    axi_data_req_o.ar.burst  = BURST_INCR;
    axi_data_req_o.ar.cache  = CACHE_MOD;
    axi_data_req_o.ar.id     = 4'b1100;
    axi_data_req_o.w.data    = dm_wdata[63:0];
    axi_data_req_o.w.strb    = dm_be[7:0];

    dm_gnt   = 1'b0;
    dm_valid = 1'b0;
    critical_word_o       = axi_data_rsp_i.r.data;
    critical_word_valid_o = 1'b0;

    d_st_d   = d_st_q;
    d_cnt_d  = d_cnt_q;
    d_off_d  = d_off_q;
    d_line_d = d_line_q;

    case (d_st_q)
      D_IDLE: begin
        d_cnt_d = 1'b0;
        if (dm_req) begin
          if (dm_we) begin
            axi_data_req_o.aw_valid = 1'b1;
            axi_data_req_o.w_valid  = 1'b1;
            axi_data_req_o.aw.len   = 8'd1;
            d_cnt_d = !axi_data_rsp_i.w_ready;
            case ({axi_data_rsp_i.aw_ready, axi_data_rsp_i.w_ready})
              2'b11:   d_st_d = D_WAIT_W;
              2'b01:   d_st_d = D_WAIT_W_AW;
              2'b10:   d_st_d = D_WAIT_W;
              default: d_st_d = D_IDLE;
            endcase
          end else begin
            axi_data_req_o.ar_valid = 1'b1;
            axi_data_req_o.ar.len   = 8'd1;
            dm_gnt  = axi_data_rsp_i.ar_ready;
            d_cnt_d = 1'b1;
            if (axi_data_rsp_i.ar_ready) begin
              d_st_d  = D_WAIT_R;
              d_off_d = dm_addr[3];
            end
          end
        end
      end

      D_WAIT_W_AW: begin
        axi_data_req_o.w_valid  = 1'b1;
        axi_data_req_o.w.last   = !d_cnt_q;
        axi_data_req_o.w.data   = d_idx ? dm_wdata[127:64] : dm_wdata[63:0];
        axi_data_req_o.w.strb   = d_idx ? dm_be[15:8]      : dm_be[7:0];
        axi_data_req_o.aw_valid = 1'b1;
        axi_data_req_o.aw.len   = 8'd1;
        case ({axi_data_rsp_i.aw_ready, axi_data_rsp_i.w_ready})
          2'b01: begin
            if (!d_cnt_q) d_st_d  = D_WAIT_AW_BURST;
            else          d_cnt_d = 1'b0;
          end
          2'b10: d_st_d = D_WAIT_W;
          2'b11: begin
            if (!d_cnt_q) begin
              d_st_d = D_WAIT_B;
              dm_gnt = 1'b1;
            end else begin
              d_st_d  = D_WAIT_W;
              d_cnt_d = 1'b0;
            end
          end
          default: ;
        endcase
      end

      D_WAIT_AW_BURST: begin
        axi_data_req_o.aw_valid = 1'b1;
        axi_data_req_o.aw.len   = 8'd1;
        if (axi_data_rsp_i.aw_ready) begin
          d_st_d = D_WAIT_B;
          dm_gnt = 1'b1;
        end
      end

      D_WAIT_W: begin
        axi_data_req_o.w_valid = 1'b1;
        axi_data_req_o.w.data  = d_idx ? dm_wdata[127:64] : dm_wdata[63:0];
        axi_data_req_o.w.strb  = d_idx ? dm_be[15:8]      : dm_be[7:0];
        if (!d_cnt_q) begin
          axi_data_req_o.w.last = 1'b1;
          if (axi_data_rsp_i.w_ready) begin
            d_st_d = D_WAIT_B;
            dm_gnt = 1'b1;
          end
        end else if (axi_data_rsp_i.w_ready) begin
          d_cnt_d = 1'b0;
        end
      end

      D_WAIT_B: begin
        if (axi_data_rsp_i.b_valid) begin
          axi_data_req_o.b_ready = 1'b1;
          dm_valid = 1'b1;
          d_st_d   = D_IDLE;
        end
      end

      D_WAIT_R: begin
        axi_data_req_o.r_ready = 1'b1;
        if (axi_data_rsp_i.r_valid) begin
          critical_word_valid_o = (d_idx == d_off_q);
          d_line_d[d_idx]       = axi_data_rsp_i.r.data;
          if (axi_data_rsp_i.r.last) d_st_d = D_COMPLETE;
          d_cnt_d = d_cnt_q - 1'b1;
        end
      end

      D_COMPLETE: begin
        dm_valid = 1'b1;
        d_st_d   = D_IDLE;
      end

      default: d_st_d = D_IDLE;
    endcase
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      d_st_q   <= D_IDLE;
      d_cnt_q  <= 1'b0;
      d_off_q  <= 1'b0;
      d_line_q <= '0;
    end else begin
      d_st_q   <= d_st_d;
      d_cnt_q  <= d_cnt_d;
      d_off_q  <= d_off_d;
      d_line_q <= d_line_d;
    end
  end

endmodule