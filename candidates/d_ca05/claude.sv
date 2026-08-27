// =============================================================================
// miss_handler_arb.sv -- implementation of the d_ca05 contract.
//
// Five blocks, each with a single always_comb driver:
//   1. the bypass arbiter        -- strict lowest-index priority (F2)
//   2. the bypass AXI adapter    -- single accesses and AXI ATOP atomics (A7)
//   3. the refill AXI adapter    -- cacheline reads and evictions (A2, A3)
//   4. the main FSM              -- misses, the flush walk, atomics (F4-F9)
//   5. the MSHR comparators      -- (F3)
//
// Every variable is declared at module scope or at the head of its block, and
// every loop has a small constant bound, so nothing here depends on a construct
// that Verilator accepts and slang rejects (T10).
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
  // local constants
  // ---------------------------------------------------------------------------
  localparam int unsigned NUM_BEATS  = LINE_WIDTH / AXI_DATA_W;          // 2
  localparam int unsigned BEAT_W     = (NUM_BEATS > 1) ? $clog2(NUM_BEATS) : 1;
  localparam int unsigned WAY_W      = $clog2(SET_ASSOC);                // 3
  localparam int unsigned PORT_W     = (NR_PORTS > 1) ? $clog2(NR_PORTS) : 1;

  localparam logic [1:0] BURST_INCR = 2'b01;
  localparam logic [2:0] SIZE_8B    = 3'b011;
  localparam logic [3:0] ID_BYPASS  = 4'h0;
  localparam logic [3:0] ID_DATA    = 4'h1;

  localparam logic [INDEX_WIDTH-1:0] SET_STEP = (1 << OFFSET_WIDTH);
  localparam logic [INDEX_WIDTH-OFFSET_WIDTH-1:0] LAST_SET = NUM_WORDS - 1;

  // ---------------------------------------------------------------------------
  // helper functions -- declarations precede statements, bounds are constant
  // ---------------------------------------------------------------------------
  function automatic logic [WAY_W-1:0] oh_to_bin(input logic [SET_ASSOC-1:0] oh);
    logic [WAY_W-1:0] r;
    r = '0;
    for (int unsigned i = 0; i < SET_ASSOC; i++) begin
      if (oh[i]) r = i[WAY_W-1:0];
    end
    return r;
  endfunction

  function automatic logic [SET_ASSOC-1:0] first_oh(input logic [SET_ASSOC-1:0] v);
    logic [SET_ASSOC-1:0] r;
    logic                 found;
    r     = '0;
    found = 1'b0;
    for (int unsigned i = 0; i < SET_ASSOC; i++) begin
      if (!found && v[i]) begin
        r[i]  = 1'b1;
        found = 1'b1;
      end
    end
    return r;
  endfunction

  // A7: the operation the memory is asked to perform, in AXI ATOP encoding.
  // atop[5:4] 10 = ATOMICLOAD (returns the pre-operation value on R),
  //           11 = swap / compare;  atop[3] = 0 little-endian;  atop[2:0] = op.
  function automatic logic [5:0] amo_to_atop(input amo_t op);
    logic [5:0] r;
    r = 6'b000000;
    case (op)
      AMO_SWAP: r = 6'b110000;   // ATOMICSWAP
      AMO_ADD:  r = 6'b100000;   // ATOMICLOAD | ADD
      AMO_AND:  r = 6'b100001;   // ATOMICLOAD | CLR   (operand inverted below)
      AMO_XOR:  r = 6'b100010;   // ATOMICLOAD | EOR
      AMO_OR:   r = 6'b100011;   // ATOMICLOAD | SET
      AMO_MAX:  r = 6'b100100;   // ATOMICLOAD | SMAX
      AMO_MIN:  r = 6'b100101;   // ATOMICLOAD | SMIN
      AMO_MAXU: r = 6'b100110;   // ATOMICLOAD | UMAX
      AMO_MINU: r = 6'b100111;   // ATOMICLOAD | UMIN
      AMO_CAS1: r = 6'b110001;   // ATOMICCOMPARE
      AMO_CAS2: r = 6'b110001;
      default:  r = 6'b000000;   // AMO_NONE / LR / SC -> a plain access
    endcase
    return r;
  endfunction

  // ---------------------------------------------------------------------------
  // state
  // ---------------------------------------------------------------------------
  typedef enum logic [3:0] {
    IDLE,
    MISS,
    MISS_REPL,
    REQ_CACHELINE,
    SAVE_CACHELINE,
    WB_CACHELINE_MISS,
    WB_CACHELINE_FLUSH,
    FLUSH_REQ_STATUS,
    FLUSHING,
    AMO_LOAD,
    AMO_SAVE_LOAD
  } state_e;

  typedef struct packed {
    logic              valid;
    logic [55:0]       addr;
    logic              we;
    logic [63:0]       wdata;
    logic [7:0]        be;
    logic [PORT_W-1:0] id;
  } mshr_t;

  state_e state_d, state_q;
  mshr_t  mshr_d,  mshr_q;

  logic [INDEX_WIDTH-1:0] cnt_d, cnt_q;
  logic [SET_ASSOC-1:0]   evict_way_d, evict_way_q;
  cache_line_t            evict_cl_d, evict_cl_q;
  logic                   serve_amo_d, serve_amo_q;
  logic [7:0]             lfsr_d, lfsr_q;
  logic                   lfsr_en;

  miss_req_t [NR_PORTS-1:0] mreq;
  assign mreq = miss_req_i;

  // ---------------------------------------------------------------------------
  // way status of the set currently presented on data_i
  // ---------------------------------------------------------------------------
  logic [SET_ASSOC-1:0] valid_ways, dirty_ways, flush_oh;
  logic [WAY_W-1:0]     flush_bin, lfsr_bin;
  logic [SET_ASSOC-1:0] lfsr_oh;
  logic [7:0]           cl_offset;

  always_comb begin
    for (int unsigned i = 0; i < SET_ASSOC; i++) begin
      valid_ways[i] = data_i[i].valid;
      dirty_ways[i] = data_i[i].valid & data_i[i].dirty;
    end
  end

  assign flush_oh  = first_oh(dirty_ways);
  assign flush_bin = oh_to_bin(flush_oh);
  assign lfsr_bin  = lfsr_q[WAY_W-1:0];
  assign cl_offset = mshr_q.addr[3] ? 8'd64 : 8'd0;

  always_comb begin
    lfsr_oh = '0;
    lfsr_oh[lfsr_bin] = 1'b1;
  end

  // ---------------------------------------------------------------------------
  // bypass adapter interface
  // ---------------------------------------------------------------------------
  logic        bp_req, bp_gnt, bp_valid, bp_we;
  logic [63:0] bp_addr, bp_wdata, bp_rdata;
  logic [7:0]  bp_be;
  logic [1:0]  bp_size;
  logic [5:0]  bp_atop;
  logic        bp_owner_amo_d, bp_owner_amo_q;

  // refill adapter interface
  logic                  d_req, d_gnt, d_valid, d_we;
  logic [63:0]           d_addr;
  logic [LINE_WIDTH-1:0] d_wdata, d_rdata;
  // A3: which beat of the burst is the word the requester actually asked for.
  // It cannot be taken from d_addr, which the walker aligns to the line.
  logic [BEAT_W-1:0]     d_crit;

  // FSM's own bypass request (the atomic)
  logic amo_bp_req;

  // ---------------------------------------------------------------------------
  // 1. BYPASS ARBITER -- F2: strict lowest-index priority, and it starves.
  //
  // The loop breaks on the first requesting port, so a port that requests every
  // cycle is selected every cycle and no higher port is ever reached. That is
  // the contract: every port is SERVABLE -- port 1 wins the moment port 0 goes
  // idle -- but service is not fair, and a round-robin here would fail T2.
  // One transaction is outstanding at a time.
  // ---------------------------------------------------------------------------
  typedef enum logic {ARB_IDLE, ARB_SERVING} arb_e;
  arb_e              arb_d, arb_q;
  logic [PORT_W-1:0] arb_id_d, arb_id_q, arb_sel;
  logic              arb_req, arb_gnt, arb_valid;
  logic [NR_PORTS-1:0] bp_port_req;

  always_comb begin
    for (int unsigned i = 0; i < NR_PORTS; i++) begin
      bp_port_req[i] = mreq[i].valid & mreq[i].bypass;
    end
  end

  // the atomic outranks the requesters for the shared bypass port
  assign arb_gnt   = bp_gnt   & ~amo_bp_req;
  assign arb_valid = bp_valid & ~bp_owner_amo_q;

  always_comb begin
    arb_d          = arb_q;
    arb_id_d       = arb_id_q;
    arb_sel        = arb_id_q;
    arb_req        = 1'b0;
    bypass_gnt_o   = '0;
    bypass_valid_o = '0;
    bypass_data_o  = '0;

    if (arb_q == ARB_IDLE) begin
      for (int unsigned i = 0; i < NR_PORTS; i++) begin
        if (bp_port_req[i]) begin
          arb_req = 1'b1;
          arb_sel = i[PORT_W-1:0];
          break;
        end
      end
      if (arb_req) begin
        bypass_gnt_o[arb_sel] = arb_gnt;
        if (arb_gnt) begin
          arb_id_d = arb_sel;
          arb_d    = ARB_SERVING;
        end
      end
    end else begin
      if (arb_valid) arb_d = ARB_IDLE;
    end

    bypass_valid_o[arb_id_q] = arb_valid;
    bypass_data_o[arb_id_q]  = bp_rdata;
  end

  // ---------------------------------------------------------------------------
  // the atomic's operands, shifted into their 64-bit lane
  // ---------------------------------------------------------------------------
  logic [63:0] amo_op_b, amo_wdata, amo_result, amo_rtrn;
  logic [7:0]  amo_strb_base, amo_strb;
  logic [5:0]  amo_atop;

  assign amo_atop = amo_to_atop(amo_req_i.amo_op);
  // AXI CLR clears the bits set in the operand, so AMO_AND presents the inverse
  assign amo_op_b = (amo_req_i.amo_op == AMO_AND) ? ~amo_req_i.operand_b
                                                  :  amo_req_i.operand_b;
  assign amo_wdata = amo_op_b << {amo_req_i.operand_a[2:0], 3'b000};

  always_comb begin
    case (amo_req_i.size)
      2'b00:   amo_strb_base = 8'h01;
      2'b01:   amo_strb_base = 8'h03;
      2'b10:   amo_strb_base = 8'h0F;
      default: amo_strb_base = 8'hFF;
    endcase
  end
  assign amo_strb = amo_strb_base << amo_req_i.operand_a[2:0];

  // the R beat carries the pre-operation value (A7)
  assign amo_rtrn = amo_req_i.operand_a[2] ? {32'b0, bp_rdata[63:32]}
                                           : {32'b0, bp_rdata[31:0]};
  assign amo_result = (amo_req_i.size == 2'b10)
                    ? {{32{amo_rtrn[31]}}, amo_rtrn[31:0]}
                    : bp_rdata;

  // ---------------------------------------------------------------------------
  // 2. BYPASS AXI ADAPTER -- single-beat accesses (A2) and ATOP atomics (A7).
  //
  // A read expects R only, a write expects B only, and an ATOP expects BOTH a B
  // and an R. Waiting only for B on an atomic hangs, which is what T7 detects,
  // so the two completions are tracked separately and the response is not
  // reported until every beat the transaction expects has arrived.
  // ---------------------------------------------------------------------------
  typedef enum logic [1:0] {B_IDLE, B_AW, B_W, B_RESP} bst_e;
  bst_e        bst_d, bst_q;
  logic        bp_is_rd_d, bp_is_rd_q;
  logic        bp_is_amo_d, bp_is_amo_q;
  logic        b_done_d, b_done_q, r_done_d, r_done_q;
  logic [63:0] bp_rd_d, bp_rd_q;
  logic [63:0] bp_wd_d, bp_wd_q;
  logic [7:0]  bp_st_d, bp_st_q;
  logic        bp_b_ok, bp_r_ok, bp_need_b, bp_need_r;

  // the atomic wins the shared port; a requester simply waits for it
  always_comb begin
    if (amo_bp_req) begin
      bp_req   = 1'b1;
      bp_addr  = amo_req_i.operand_a;
      bp_we    = (amo_req_i.amo_op != AMO_LR);
      bp_wdata = amo_wdata;
      bp_be    = amo_strb;
      bp_size  = amo_req_i.size;
      bp_atop  = amo_atop;
    end else begin
      bp_req   = arb_req;
      bp_addr  = mreq[arb_sel].addr;
      bp_we    = mreq[arb_sel].we;
      bp_wdata = mreq[arb_sel].wdata;
      bp_be    = mreq[arb_sel].be;
      bp_size  = mreq[arb_sel].size;
      bp_atop  = 6'b000000;
    end
  end

  always_comb begin
    bst_d          = bst_q;
    bp_is_rd_d     = bp_is_rd_q;
    bp_is_amo_d    = bp_is_amo_q;
    b_done_d       = b_done_q;
    r_done_d       = r_done_q;
    bp_rd_d        = bp_rd_q;
    bp_wd_d        = bp_wd_q;
    bp_st_d        = bp_st_q;
    bp_owner_amo_d = bp_owner_amo_q;

    bp_gnt   = 1'b0;
    bp_valid = 1'b0;
    bp_rdata = bp_rd_q;

    axi_bypass_req_o = '0;

    bp_need_b = ~bp_is_rd_q;
    bp_need_r = bp_is_rd_q | bp_is_amo_q;
    bp_b_ok   = b_done_q;
    bp_r_ok   = r_done_q;

    case (bst_q)
      B_IDLE: begin
        if (bp_req) begin
          if (!bp_we) begin
            axi_bypass_req_o.ar_valid   = 1'b1;
            axi_bypass_req_o.ar.id      = ID_BYPASS;
            axi_bypass_req_o.ar.addr    = bp_addr;
            axi_bypass_req_o.ar.len     = 8'd0;
            axi_bypass_req_o.ar.size    = {1'b0, bp_size};
            axi_bypass_req_o.ar.burst   = BURST_INCR;
            if (axi_bypass_rsp_i.ar_ready) begin
              bp_gnt         = 1'b1;
              bp_is_rd_d     = 1'b1;
              bp_is_amo_d    = 1'b0;
              bp_owner_amo_d = amo_bp_req;
              b_done_d       = 1'b0;
              r_done_d       = 1'b0;
              bst_d          = B_RESP;
            end
          end else begin
            axi_bypass_req_o.aw_valid = 1'b1;
            axi_bypass_req_o.aw.id    = ID_BYPASS;
            axi_bypass_req_o.aw.addr  = bp_addr;
            axi_bypass_req_o.aw.len   = 8'd0;
            axi_bypass_req_o.aw.size  = {1'b0, bp_size};
            axi_bypass_req_o.aw.burst = BURST_INCR;
            axi_bypass_req_o.aw.atop  = bp_atop;
            axi_bypass_req_o.w_valid  = 1'b1;
            axi_bypass_req_o.w.data   = bp_wdata;
            axi_bypass_req_o.w.strb   = bp_be;
            axi_bypass_req_o.w.last   = 1'b1;

            bp_wd_d = bp_wdata;
            bp_st_d = bp_be;

            if (axi_bypass_rsp_i.aw_ready) begin
              bp_gnt         = 1'b1;
              bp_is_rd_d     = 1'b0;
              bp_is_amo_d    = (bp_atop != 6'b000000);
              bp_owner_amo_d = amo_bp_req;
              b_done_d       = 1'b0;
              r_done_d       = 1'b0;
              bst_d          = axi_bypass_rsp_i.w_ready ? B_RESP : B_W;
            end else if (axi_bypass_rsp_i.w_ready) begin
              bst_d = B_AW;   // data taken first; the address is still held
            end
          end
        end
      end

      // the W beat was accepted before the address
      B_AW: begin
        axi_bypass_req_o.aw_valid = 1'b1;
        axi_bypass_req_o.aw.id    = ID_BYPASS;
        axi_bypass_req_o.aw.addr  = bp_addr;
        axi_bypass_req_o.aw.len   = 8'd0;
        axi_bypass_req_o.aw.size  = {1'b0, bp_size};
        axi_bypass_req_o.aw.burst = BURST_INCR;
        axi_bypass_req_o.aw.atop  = bp_atop;
        if (axi_bypass_rsp_i.aw_ready) begin
          bp_gnt         = 1'b1;
          bp_is_rd_d     = 1'b0;
          bp_is_amo_d    = (bp_atop != 6'b000000);
          bp_owner_amo_d = amo_bp_req;
          b_done_d       = 1'b0;
          r_done_d       = 1'b0;
          bst_d          = B_RESP;
        end
      end

      // the address was accepted before the data
      B_W: begin
        axi_bypass_req_o.w_valid = 1'b1;
        axi_bypass_req_o.w.data  = bp_wd_q;
        axi_bypass_req_o.w.strb  = bp_st_q;
        axi_bypass_req_o.w.last  = 1'b1;
        if (axi_bypass_rsp_i.w_ready) bst_d = B_RESP;
      end

      B_RESP: begin
        // each beat is accepted exactly once: once a completion is recorded
        // its ready drops, so the next transaction's beat is not consumed here
        axi_bypass_req_o.b_ready = bp_need_b & ~b_done_q;
        axi_bypass_req_o.r_ready = bp_need_r & ~r_done_q;

        if (bp_need_b && !b_done_q && axi_bypass_rsp_i.b_valid) bp_b_ok = 1'b1;
        if (bp_need_r && !r_done_q && axi_bypass_rsp_i.r_valid) begin
          bp_r_ok = 1'b1;
          bp_rd_d = axi_bypass_rsp_i.r.data;
        end

        if ((!bp_need_b || bp_b_ok) && (!bp_need_r || bp_r_ok)) begin
          bp_valid = 1'b1;
          if (bp_need_r && !r_done_q && axi_bypass_rsp_i.r_valid) begin
            bp_rdata = axi_bypass_rsp_i.r.data;
          end else begin
            bp_rdata = bp_rd_q;
          end
          b_done_d = 1'b0;
          r_done_d = 1'b0;
          bst_d    = B_IDLE;
        end else begin
          b_done_d = bp_b_ok;
          r_done_d = bp_r_ok;
        end
      end

      default: bst_d = B_IDLE;
    endcase
  end

  // ---------------------------------------------------------------------------
  // 3. REFILL AXI ADAPTER -- cacheline reads and evictions (A2), with the
  //    requested word forwarded as it arrives (A3).
  // ---------------------------------------------------------------------------
  typedef enum logic [1:0] {D_IDLE, D_R, D_W, D_B} dst_e;
  dst_e                    dst_d, dst_q;
  logic [BEAT_W-1:0]       dbeat_d, dbeat_q;
  logic [BEAT_W-1:0]       dcrit_d, dcrit_q;
  logic [NUM_BEATS-1:0][AXI_DATA_W-1:0] dline_d, dline_q;
  logic [NUM_BEATS-1:0][AXI_DATA_W-1:0] dline_mux, dwbuf_d, dwbuf_q;

  always_comb begin
    dst_d          = dst_q;
    dbeat_d        = dbeat_q;
    dcrit_d        = dcrit_q;
    dline_d        = dline_q;
    dwbuf_d        = dwbuf_q;

    d_gnt          = 1'b0;
    d_valid        = 1'b0;
    critical_word_o       = '0;
    critical_word_valid_o = 1'b0;

    axi_data_req_o = '0;

    dline_mux           = dline_q;
    dline_mux[dbeat_q]  = axi_data_rsp_i.r.data;
    d_rdata             = dline_mux;

    case (dst_q)
      D_IDLE: begin
        if (d_req) begin
          if (!d_we) begin
            axi_data_req_o.ar_valid = 1'b1;
            axi_data_req_o.ar.id    = ID_DATA;
            axi_data_req_o.ar.addr  = d_addr;
            axi_data_req_o.ar.len   = 8'(NUM_BEATS - 1);
            axi_data_req_o.ar.size  = SIZE_8B;
            axi_data_req_o.ar.burst = BURST_INCR;
            if (axi_data_rsp_i.ar_ready) begin
              d_gnt   = 1'b1;
              dbeat_d = '0;
              dcrit_d = d_crit;
              dst_d   = D_R;
            end
          end else begin
            axi_data_req_o.aw_valid = 1'b1;
            axi_data_req_o.aw.id    = ID_DATA;
            axi_data_req_o.aw.addr  = d_addr;
            axi_data_req_o.aw.len   = 8'(NUM_BEATS - 1);
            axi_data_req_o.aw.size  = SIZE_8B;
            axi_data_req_o.aw.burst = BURST_INCR;
            if (axi_data_rsp_i.aw_ready) begin
              d_gnt   = 1'b1;
              dbeat_d = '0;
              dwbuf_d = d_wdata;
              dst_d   = D_W;
            end
          end
        end
      end

      D_R: begin
        axi_data_req_o.r_ready = 1'b1;
        if (axi_data_rsp_i.r_valid) begin
          dline_d[dbeat_q] = axi_data_rsp_i.r.data;
          // A3: forward the requested word ahead of the array write
          if (dbeat_q == dcrit_q) begin
            critical_word_valid_o = 1'b1;
            critical_word_o       = axi_data_rsp_i.r.data;
          end
          if (axi_data_rsp_i.r.last) begin
            d_valid = 1'b1;      // d_rdata already merges this final beat
            dst_d   = D_IDLE;
          end else begin
            dbeat_d = dbeat_q + 1'b1;
          end
        end
      end

      D_W: begin
        axi_data_req_o.w_valid = 1'b1;
        axi_data_req_o.w.data  = dwbuf_q[dbeat_q];
        axi_data_req_o.w.strb  = '1;
        axi_data_req_o.w.last  = (dbeat_q == BEAT_W'(NUM_BEATS - 1));
        if (axi_data_rsp_i.w_ready) begin
          if (dbeat_q == BEAT_W'(NUM_BEATS - 1)) dst_d = D_B;
          else                                   dbeat_d = dbeat_q + 1'b1;
        end
      end

      D_B: begin
        axi_data_req_o.b_ready = 1'b1;
        if (axi_data_rsp_i.b_valid) dst_d = D_IDLE;
      end

      default: dst_d = D_IDLE;
    endcase
  end

  // ---------------------------------------------------------------------------
  // 4. THE MAIN FSM
  // ---------------------------------------------------------------------------
  always_comb begin
    state_d     = state_q;
    mshr_d      = mshr_q;
    cnt_d       = cnt_q;
    evict_way_d = evict_way_q;
    evict_cl_d  = evict_cl_q;
    serve_amo_d = serve_amo_q;
    lfsr_en     = 1'b0;

    req_o  = '0;
    addr_o = '0;
    data_o = '0;
    be_o   = '0;
    we_o   = 1'b0;

    flush_ack_o       = 1'b0;
    miss_o            = 1'b0;
    miss_gnt_o        = '0;
    active_serving_o  = '0;
    amo_resp_o.ack    = 1'b0;
    amo_resp_o.result = '0;

    d_req      = 1'b0;
    d_we       = 1'b0;
    d_addr     = '0;
    d_wdata    = '0;
    d_crit     = '0;
    amo_bp_req = 1'b0;

    case (state_q)
      // -----------------------------------------------------------------------
      // The order of the three checks below is the whole of F5/F7/F8/F9.
      //
      // The atomic is evaluated FIRST and, on its first pass, only arms the
      // flush -- it sets serve_amo, which records that the walk about to happen
      // was nobody's request. The flush check that follows re-targets the same
      // state and DELIBERATELY DOES NOT TOUCH serve_amo. So when flush_i and
      // amo_req_i.req arrive together, the walk runs with serve_amo set and the
      // acknowledgement below is suppressed: the flush happens and is never
      // acknowledged (F8). Writing the flush check as an `else if`, or having it
      // clear serve_amo, still passes F5 and F7 and breaks F8 -- which is why
      // the corner is invisible unless the two are exercised together.
      //
      // The miss loop is LAST and clears serve_amo, so an incoming miss both
      // outranks the atomic and discards its pending state (F9).
      // -----------------------------------------------------------------------
      IDLE: begin
        // If the atomic went away before it was served, drop the armed state.
        // Without this serve_amo latches high and silently suppresses the
        // acknowledgement of a LATER genuine flush, which is F5's pulse lost to
        // a stale flag. It cannot disturb F7 or F8: in both, amo_req_i.req is
        // still asserted at every point where this could fire.
        if (!amo_req_i.req) serve_amo_d = 1'b0;

        // A4: busy_i gates the atomic and the flush, but never miss handling.
        if (amo_req_i.req && !busy_i) begin
          if (!serve_amo_q) begin
            state_d     = FLUSH_REQ_STATUS;   // F6: flush the cache first
            serve_amo_d = 1'b1;
            cnt_d       = '0;
          end else begin
            state_d     = AMO_LOAD;           // cache is clean, issue it
            serve_amo_d = 1'b0;
          end
        end

        if (flush_i && !busy_i) begin
          state_d = FLUSH_REQ_STATUS;
          cnt_d   = '0;
        end

        for (int unsigned i = 0; i < NR_PORTS; i++) begin
          if (mreq[i].valid && !mreq[i].bypass) begin
            state_d       = MISS;
            serve_amo_d   = 1'b0;
            miss_gnt_o[i] = 1'b1;
            mshr_d.valid  = 1'b1;
            mshr_d.we     = mreq[i].we;
            mshr_d.id     = i[PORT_W-1:0];
            mshr_d.addr   = mreq[i].addr[55:0];
            mshr_d.wdata  = mreq[i].wdata;
            mshr_d.be     = mreq[i].be;
            break;
          end
        end
      end

      // read the set so the replacement can be chosen
      MISS: begin
        req_o   = '1;
        addr_o  = mshr_q.addr[INDEX_WIDTH-1:0];
        miss_o  = 1'b1;
        state_d = MISS_REPL;
      end

      MISS_REPL: begin
        if (&valid_ways) begin
          lfsr_en     = 1'b1;
          evict_way_d = lfsr_oh;
          if (data_i[lfsr_bin].dirty) begin
            evict_cl_d.tag  = data_i[lfsr_bin].tag;
            evict_cl_d.data = data_i[lfsr_bin].data;
            cnt_d           = mshr_q.addr[INDEX_WIDTH-1:0];
            state_d         = WB_CACHELINE_MISS;
          end else begin
            state_d = REQ_CACHELINE;
          end
        end else begin
          evict_way_d = first_oh(~valid_ways);
          state_d     = REQ_CACHELINE;
        end
      end

      REQ_CACHELINE: begin
        d_req  = 1'b1;
        d_we   = 1'b0;
        d_addr = {8'b0, mshr_q.addr[55:OFFSET_WIDTH], {OFFSET_WIDTH{1'b0}}};
        d_crit = mshr_q.addr[OFFSET_WIDTH-1:3];
        if (d_gnt) begin
          active_serving_o[mshr_q.id] = 1'b1;
          state_d = SAVE_CACHELINE;
        end
      end

      SAVE_CACHELINE: begin
        if (d_valid) begin
          addr_o       = mshr_q.addr[INDEX_WIDTH-1:0];
          req_o        = evict_way_q;
          we_o         = 1'b1;
          be_o.tag     = '1;
          be_o.data    = '1;
          be_o.vldrty  = evict_way_q;
          data_o.tag   = mshr_q.addr[55:INDEX_WIDTH];
          data_o.data  = d_rdata;
          data_o.valid = 1'b1;
          data_o.dirty = 1'b0;
          // a write miss merges its data into the line as it lands
          if (mshr_q.we) begin
            for (int unsigned i = 0; i < 8; i++) begin
              if (mshr_q.be[i]) begin
                data_o.data[cl_offset + i*8 +: 8] = mshr_q.wdata[i*8 +: 8];
              end
            end
            data_o.dirty = 1'b1;
          end
          mshr_d.valid = 1'b0;     // F3: the match outputs fall with it
          state_d      = IDLE;
        end
      end

      // evict the dirty line held in evict_cl_q, then clear its status
      WB_CACHELINE_FLUSH, WB_CACHELINE_MISS: begin
        d_req   = 1'b1;
        d_we    = 1'b1;
        d_addr  = {8'b0, evict_cl_q.tag,
                   cnt_q[INDEX_WIDTH-1:OFFSET_WIDTH], {OFFSET_WIDTH{1'b0}}};
        d_wdata = evict_cl_q.data;
        if (d_gnt) begin
          req_o        = '1;
          addr_o       = cnt_q;
          we_o         = 1'b1;
          data_o.valid = 1'b0;
          data_o.dirty = 1'b0;
          be_o.vldrty  = evict_way_q;
          state_d      = (state_q == WB_CACHELINE_MISS) ? MISS : FLUSH_REQ_STATUS;
        end
      end

      // -----------------------------------------------------------------------
      // F4: the walk. One READ per set here and one WRITE per set in FLUSHING,
      // so 256 sets cost 512 array requests of which 256 are writes, and 513
      // cycles counting the IDLE->here transition. The cost is the contract, not
      // just the end state, so the two accesses are not merged into one.
      // -----------------------------------------------------------------------
      FLUSH_REQ_STATUS: begin
        req_o   = '1;
        addr_o  = cnt_q;
        state_d = FLUSHING;
      end

      FLUSHING: begin
        if (|dirty_ways) begin
          // a dirty way must go to memory before the set can be cleared
          evict_way_d     = flush_oh;
          evict_cl_d.tag  = data_i[flush_bin].tag;
          evict_cl_d.data = data_i[flush_bin].data;
          state_d         = WB_CACHELINE_FLUSH;
        end else begin
          req_o       = '1;
          addr_o      = cnt_q;
          we_o        = 1'b1;
          data_o      = '0;
          be_o.vldrty = '1;          // F4: all SET_ASSOC ways in one write
          cnt_d       = cnt_q + SET_STEP;
          state_d     = FLUSH_REQ_STATUS;
          if (cnt_q[INDEX_WIDTH-1:OFFSET_WIDTH] == LAST_SET) begin
            // F5 acknowledges; F7 and F8 do not, because serve_amo_q records
            // that this walk was not asked for by a flush requester.
            flush_ack_o = ~serve_amo_q;
            state_d     = IDLE;
          end
        end
      end

      // -----------------------------------------------------------------------
      // A7: the atomic leaves as an AXI ATOP write and the memory performs it.
      // -----------------------------------------------------------------------
      AMO_LOAD: begin
        amo_bp_req = 1'b1;
        if (bp_gnt) state_d = AMO_SAVE_LOAD;
      end

      AMO_SAVE_LOAD: begin
        if (bp_valid && bp_owner_amo_q) begin
          amo_resp_o.ack    = 1'b1;
          amo_resp_o.result = amo_result;
          state_d           = IDLE;
        end
      end

      default: state_d = IDLE;
    endcase
  end

  // ---------------------------------------------------------------------------
  // 5. MSHR INTERROGATION -- F3.
  //
  // Two independent comparisons against the same held address. The index field
  // is a SUB-RANGE of the address field, so an address match implies an index
  // match and the two outputs assert TOGETHER -- they are not alternatives, and
  // the index output is NOT cleared when the full address matches (F3a). The
  // requester whose own miss is in flight is NOT excluded (F3b). Both fall to
  // zero with mshr_q.valid when the refill retires.
  // ---------------------------------------------------------------------------
  always_comb begin
    mshr_addr_matches_o  = '0;
    mshr_index_matches_o = '0;
    for (int unsigned i = 0; i < NR_PORTS; i++) begin
      if (mshr_q.valid &&
          (mshr_addr_i[i][55:OFFSET_WIDTH] == mshr_q.addr[55:OFFSET_WIDTH])) begin
        mshr_addr_matches_o[i] = 1'b1;
      end
      if (mshr_q.valid &&
          (mshr_addr_i[i][INDEX_WIDTH-1:OFFSET_WIDTH] ==
           mshr_q.addr[INDEX_WIDTH-1:OFFSET_WIDTH])) begin
        mshr_index_matches_o[i] = 1'b1;
      end
    end
  end

  // ---------------------------------------------------------------------------
  // registers -- A5: asynchronous assert, synchronous release; a reset
  // mid-operation discards rather than drains.
  // ---------------------------------------------------------------------------
  always_comb begin
    lfsr_d = lfsr_q;
    if (lfsr_en) begin
      lfsr_d = {lfsr_q[6:0], lfsr_q[7] ^ lfsr_q[5] ^ lfsr_q[4] ^ lfsr_q[3]};
    end
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state_q        <= IDLE;
      mshr_q         <= '0;
      cnt_q          <= '0;
      evict_way_q    <= '0;
      evict_cl_q     <= '0;
      serve_amo_q    <= 1'b0;
      lfsr_q         <= 8'hA5;
      arb_q          <= ARB_IDLE;
      arb_id_q       <= '0;
      bst_q          <= B_IDLE;
      bp_is_rd_q     <= 1'b0;
      bp_is_amo_q    <= 1'b0;
      b_done_q       <= 1'b0;
      r_done_q       <= 1'b0;
      bp_rd_q        <= '0;
      bp_wd_q        <= '0;
      bp_st_q        <= '0;
      bp_owner_amo_q <= 1'b0;
      dst_q          <= D_IDLE;
      dbeat_q        <= '0;
      dcrit_q        <= '0;
      dline_q        <= '0;
      dwbuf_q        <= '0;
    end else begin
      state_q        <= state_d;
      mshr_q         <= mshr_d;
      cnt_q          <= cnt_d;
      evict_way_q    <= evict_way_d;
      evict_cl_q     <= evict_cl_d;
      serve_amo_q    <= serve_amo_d;
      lfsr_q         <= lfsr_d;
      arb_q          <= arb_d;
      arb_id_q       <= arb_id_d;
      bst_q          <= bst_d;
      bp_is_rd_q     <= bp_is_rd_d;
      bp_is_amo_q    <= bp_is_amo_d;
      b_done_q       <= b_done_d;
      r_done_q       <= r_done_d;
      bp_rd_q        <= bp_rd_d;
      bp_wd_q        <= bp_wd_d;
      bp_st_q        <= bp_st_d;
      bp_owner_amo_q <= bp_owner_amo_d;
      dst_q          <= dst_d;
      dbeat_q        <= dbeat_d;
      dcrit_q        <= dcrit_d;
      dline_q        <= dline_d;
      dwbuf_q        <= dwbuf_d;
    end
  end

endmodule