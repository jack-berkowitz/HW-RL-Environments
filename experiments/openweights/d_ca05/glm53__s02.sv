// =============================================================================
// d_ca05 -- miss_handler_arb : multi-requester cache miss handler
// =============================================================================
module miss_handler_arb
  import miss_handler_arb_pkg::*;
#(
  parameter int unsigned NR_PORTS = 4
) (
    input  logic clk,
    input  logic rst_n,                     // active low, asynchronous assert

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
  // internal types
  // --------------------------------------------------------------------------
  typedef enum logic [3:0] {
    S_IDLE,
    S_FLUSH,        // F4 invalidate walk
    S_AMO_ISSUE,    // A7 ATOP write issue
    S_AMO_RESP,     // A7 consume both B and R
    S_VICTIM,       // set read data available, pick victim way
    S_WB_ISSUE,     // evict a dirty victim (AW + 2 W beats)
    S_WB_WAIT_B,
    S_REFILL_ISSUE, // AR for the cacheline
    S_REFILL_DATA,  // 2 R beats
    S_REFILL_STORE  // write the line into the array
  } state_e;

  typedef enum logic [1:0] {
    BP_IDLE,
    BP_REQ,      // issue AR, or AW + single W beat
    BP_WAIT_R,
    BP_WAIT_B
  } bp_state_e;

  localparam int unsigned PORT_SEL_W = (NR_PORTS > 1) ? $clog2(NR_PORTS) : 1;

  // --------------------------------------------------------------------------
  // helpers
  // --------------------------------------------------------------------------
  // RISC-V AMO -> AXI ATOP (A7).  Fetch-type operations follow the AMBA AXI5
  // ATOP operation table; AMO_AND maps onto AtomicFetch CLR with the operand
  // inverted (old & b == old & ~(~b)).
  function automatic logic [5:0] amo_to_atop(input amo_t op);
    case (op)
      AMO_SWAP: amo_to_atop = 6'b01_0000;  // AtomicSwap SWAP
      AMO_ADD:  amo_to_atop = 6'b11_0000;  // AtomicFetch ADD
      AMO_XOR:  amo_to_atop = 6'b11_0010;  // AtomicFetch EOR
      AMO_OR:   amo_to_atop = 6'b11_0011;  // AtomicFetch SET
      AMO_AND:  amo_to_atop = 6'b11_0001;  // AtomicFetch CLR
      AMO_MAX:  amo_to_atop = 6'b11_0100;  // AtomicFetch SMAX
      AMO_MIN:  amo_to_atop = 6'b11_0101;  // AtomicFetch SMIN
      AMO_MAXU: amo_to_atop = 6'b11_0110;  // AtomicFetch UMAX
      AMO_MINU: amo_to_atop = 6'b11_0111;  // AtomicFetch UMIN
      AMO_CAS1: amo_to_atop = 6'b10_0001;  // AtomicCompare, smaller
      AMO_CAS2: amo_to_atop = 6'b10_0010;  // AtomicCompare, larger
      default:  amo_to_atop = 6'b00_0000;
    endcase
  endfunction

  // byte lanes covered by an access of 2**size bytes at lane offset addr_lo
  function automatic logic [7:0] size_strb(input logic [1:0] size, input logic [2:0] addr_lo);
    case (size)
      2'b00:   size_strb = 8'b0000_0001 << addr_lo;
      2'b01:   size_strb = 8'b0000_0011 << addr_lo;
      2'b10:   size_strb = 8'b0000_1111 << addr_lo;
      default: size_strb = 8'b1111_1111;
    endcase
  endfunction

  // --------------------------------------------------------------------------
  // state
  // --------------------------------------------------------------------------
  state_e    state_q, state_d;
  bp_state_e bp_state_q, bp_state_d;

  logic [8:0] flush_cnt_q, flush_cnt_d;   // counts the 512 walk accesses
  logic       ack_flush_q, ack_flush_d;   // F5/F7/F8: may this walk ack?
  logic       flush_ack_q, flush_ack_d;

  logic                  mshr_valid_q, mshr_valid_d;
  logic [55:0]           mshr_addr_q, mshr_addr_d;
  logic [PORT_SEL_W-1:0] mshr_port_q, mshr_port_d;

  logic [SET_ASSOC-1:0]  victim_way_q, victim_way_d;
  logic                  victim_dirty_q, victim_dirty_d;
  logic [TAG_WIDTH-1:0]  victim_tag_q, victim_tag_d;
  logic [LINE_WIDTH-1:0] victim_data_q, victim_data_d;
  logic [2:0]            rr_cnt_q, rr_cnt_d;

  logic [LINE_WIDTH-1:0] line_q, line_d;
  logic                  refill_beat_q, refill_beat_d;

  logic wb_aw_done_q, wb_aw_done_d;
  logic wb_w_done_q,  wb_w_done_d;
  logic wb_beat_q,    wb_beat_d;

  logic        amo_pending_q, amo_pending_d;
  amo_t        amo_op_q, amo_op_d;
  logic [1:0]  amo_size_q, amo_size_d;
  logic [63:0] amo_addr_q, amo_addr_d;
  logic [63:0] amo_data_q, amo_data_d;
  logic        amo_aw_done_q, amo_aw_done_d;
  logic        amo_w_done_q,  amo_w_done_d;
  logic        amo_b_seen_q,  amo_b_seen_d;
  logic        amo_r_seen_q,  amo_r_seen_d;
  logic [63:0] amo_result_q, amo_result_d;
  logic        amo_ack_q,    amo_ack_d;

  logic [PORT_SEL_W-1:0] bp_port_q, bp_port_d;
  logic [63:0] bp_addr_q,  bp_addr_d;
  logic [63:0] bp_wdata_q, bp_wdata_d;
  logic [7:0]  bp_be_q,    bp_be_d;
  logic [1:0]  bp_size_q,  bp_size_d;
  logic        bp_we_q,    bp_we_d;
  logic        bp_aw_done_q, bp_aw_done_d;
  logic        bp_w_done_q,  bp_w_done_d;
  logic        bp_valid_q, bp_valid_d;
  logic [63:0] bp_rdata_q, bp_rdata_d;

  // combinational
  miss_req_t [NR_PORTS-1:0] miss_req;
  logic [NR_PORTS-1:0] bp_request, miss_request;
  logic bp_sel_valid, miss_sel_valid;
  logic [PORT_SEL_W-1:0] bp_sel, miss_sel;
  logic flush_start, amo_take, walk_start;
  logic amo_owns_bypass;
  logic [SET_ASSOC-1:0] victim_oh;
  logic victim_found_invalid;
  logic victim_dirty_c;
  logic [TAG_WIDTH-1:0] victim_tag_c;
  logic [LINE_WIDTH-1:0] victim_data_c;
  logic wb_aw_fire, wb_w_fire;
  logic amo_aw_fire, amo_w_fire;
  logic bp_aw_fire, bp_w_fire;

  // --------------------------------------------------------------------------
  // request unpacking and arbitration -- strict lowest-index priority (F2)
  // --------------------------------------------------------------------------
  always_comb begin
    for (int unsigned i = 0; i < NR_PORTS; i++) begin
      miss_req[i]     = miss_req_t'(miss_req_i[i]);
      bp_request[i]   = miss_req[i].valid &&  miss_req[i].bypass;
      miss_request[i]  = miss_req[i].valid && !miss_req[i].bypass;
    end
  end

  always_comb begin
    bp_sel       = '0;
    bp_sel_valid = 1'b0;
    for (int unsigned i = 0; i < NR_PORTS; i++) begin
      if (bp_request[i] && !bp_sel_valid) begin
        bp_sel       = PORT_SEL_W'(i);
        bp_sel_valid = 1'b1;
      end
    end
    miss_sel       = '0;
    miss_sel_valid = 1'b0;
    for (int unsigned i = 0; i < NR_PORTS; i++) begin
      if (miss_request[i] && !miss_sel_valid) begin
        miss_sel       = PORT_SEL_W'(i);
        miss_sel_valid = 1'b1;
      end
    end
  end

  // walk entry (A4: busy_i gates flush and atomic, never miss handling)
  assign amo_owns_bypass = (state_q == S_AMO_ISSUE) || (state_q == S_AMO_RESP);
  assign flush_start = flush_i && !busy_i && (state_q == S_IDLE) && !flush_ack_q;
  assign amo_take    = amo_req_i.req && !busy_i && (state_q == S_IDLE) && !flush_start
                      && !miss_sel_valid && !amo_ack_q;  // F9: a miss wins
  assign walk_start  = flush_start || amo_take;

  // grants
  always_comb begin
    bypass_gnt_o = '0;
    if ((bp_state_q == BP_IDLE) && !amo_owns_bypass && bp_sel_valid) begin
      bypass_gnt_o[bp_sel] = 1'b1;
    end
    miss_gnt_o = '0;
    if ((state_q == S_IDLE) && !walk_start && miss_sel_valid) begin
      miss_gnt_o[miss_sel] = 1'b1;
    end
  end

  // --------------------------------------------------------------------------
  // victim selection: first invalid way, else a round-robin way
  // --------------------------------------------------------------------------
  always_comb begin
    victim_oh            = '0;
    victim_found_invalid = 1'b0;
    for (int unsigned i = 0; i < SET_ASSOC; i++) begin
      if (!data_i[i].valid && !victim_found_invalid) begin
        victim_oh            = SET_ASSOC'(1) << i;
        victim_found_invalid = 1'b1;
      end
    end
    if (!victim_found_invalid) begin
      victim_oh = SET_ASSOC'(1) << rr_cnt_q;
    end
    victim_dirty_c = 1'b0;
    victim_tag_c   = '0;
    victim_data_c  = '0;
    for (int unsigned i = 0; i < SET_ASSOC; i++) begin
      if (victim_oh[i]) begin
        victim_dirty_c = data_i[i].dirty;
        victim_tag_c   = data_i[i].tag;
        victim_data_c  = data_i[i].data;
      end
    end
  end

  // --------------------------------------------------------------------------
  // main FSM
  // --------------------------------------------------------------------------
  always_comb begin
    state_d        = state_q;
    flush_cnt_d    = flush_cnt_q;
    ack_flush_d    = ack_flush_q;
    flush_ack_d    = 1'b0;
    mshr_valid_d   = mshr_valid_q;
    mshr_addr_d    = mshr_addr_q;
    mshr_port_d    = mshr_port_q;
    victim_way_d   = victim_way_q;
    victim_dirty_d = victim_dirty_q;
    victim_tag_d   = victim_tag_q;
    victim_data_d  = victim_data_q;
    rr_cnt_d       = rr_cnt_q;
    line_d         = line_q;
    refill_beat_d  = refill_beat_q;
    wb_aw_done_d   = wb_aw_done_q;
    wb_w_done_d    = wb_w_done_q;
    wb_beat_d      = wb_beat_q;
    amo_pending_d  = amo_pending_q;
    amo_op_d       = amo_op_q;
    amo_size_d     = amo_size_q;
    amo_addr_d     = amo_addr_q;
    amo_data_d     = amo_data_q;
    amo_aw_done_d  = amo_aw_done_q;
    amo_w_done_d   = amo_w_done_q;
    amo_b_seen_d   = amo_b_seen_q;
    amo_r_seen_d   = amo_r_seen_q;
    amo_result_d   = amo_result_q;
    amo_ack_d      = 1'b0;

    case (state_q)
      // --------------------------------------------------------------------
      S_IDLE: begin
        if (walk_start) begin
          state_d       = S_FLUSH;
          flush_cnt_d   = 9'd0;
          // F5/F7/F8: only a flush requested on its own acks; one requested
          // in the same cycle as an atomic never does.
          ack_flush_d   = flush_start && !amo_req_i.req;
          amo_aw_done_d = 1'b0;
          amo_w_done_d  = 1'b0;
          amo_b_seen_d  = 1'b0;
          amo_r_seen_d  = 1'b0;
          if (amo_req_i.req) begin
            amo_pending_d = 1'b1;
            amo_op_d      = amo_req_i.amo_op;
            amo_size_d    = amo_req_i.size;
            amo_addr_d    = amo_req_i.operand_a;
            amo_data_d    = amo_req_i.operand_b;
          end
        end else if (miss_sel_valid) begin
          // accept the miss into the MSHR; the set was read this cycle
          state_d      = S_VICTIM;
          mshr_valid_d = 1'b1;
          mshr_addr_d  = miss_req[miss_sel].addr[55:0];
          mshr_port_d  = miss_sel;
          refill_beat_d = 1'b0;
        end
      end
      // --------------------------------------------------------------------
      S_FLUSH: begin
        // F4: one array access per cycle, read then write per set
        flush_cnt_d = flush_cnt_q + 9'd1;
        // an atomic arriving mid-walk is served directly after the walk
        if (amo_req_i.req) begin
          amo_pending_d = 1'b1;
          amo_op_d      = amo_req_i.amo_op;
          amo_size_d    = amo_req_i.size;
          amo_addr_d    = amo_req_i.operand_a;
          amo_data_d    = amo_req_i.operand_b;
        end
        if (flush_cnt_q == 9'd511) begin
          flush_ack_d = ack_flush_q;      // one-cycle pulse, F5/F7/F8
          flush_cnt_d = 9'd0;
          if (amo_pending_d) state_d = S_AMO_ISSUE;
          else              state_d = S_IDLE;
        end
      end
      // --------------------------------------------------------------------
      S_VICTIM: begin
        victim_way_d   = victim_oh;
        victim_dirty_d = victim_dirty_c;
        victim_tag_d   = victim_tag_c;
        victim_data_d  = victim_data_c;
        wb_aw_done_d   = 1'b0;
        wb_w_done_d    = 1'b0;
        wb_beat_d      = 1'b0;
        if (!victim_found_invalid) rr_cnt_d = rr_cnt_q + 3'd1;
        if (victim_dirty_c) state_d = S_WB_ISSUE;      // A2: evict dirty lines
        else                state_d = S_REFILL_ISSUE;
      end
      // --------------------------------------------------------------------
      S_WB_ISSUE: begin
        if (wb_aw_fire) wb_aw_done_d = 1'b1;
        if (wb_w_fire) begin
          wb_beat_d   = wb_beat_q + 1'b1;
          if (wb_beat_q == 1'b1) wb_w_done_d = 1'b1;
        end
        if (wb_aw_done_d && wb_w_done_d) state_d = S_WB_WAIT_B;
      end
      // --------------------------------------------------------------------
      S_WB_WAIT_B: begin
        if (axi_data_rsp_i.b_valid) state_d = S_REFILL_ISSUE;
      end
      // --------------------------------------------------------------------
      S_REFILL_ISSUE: begin
        if (axi_data_rsp_i.ar_ready) begin
          state_d       = S_REFILL_DATA;
          refill_beat_d = 1'b0;
        end
      end
      // --------------------------------------------------------------------
      S_REFILL_DATA: begin
        if (axi_data_rsp_i.r_valid) begin        // r_ready is high in this state
          refill_beat_d = refill_beat_q + 1'b1;
          line_d        = {axi_data_rsp_i.r.data, line_q[63:0]};
          if (refill_beat_q == 1'b1) state_d = S_REFILL_STORE;
        end
      end
      // --------------------------------------------------------------------
      S_REFILL_STORE: begin
        state_d      = S_IDLE;
        mshr_valid_d = 1'b0;                     // F3: matches retire with it
      end
      // --------------------------------------------------------------------
      S_AMO_ISSUE: begin
        if (amo_aw_fire) amo_aw_done_d = 1'b1;
        if (amo_w_fire)  amo_w_done_d  = 1'b1;
        if (amo_aw_done_d && amo_w_done_d) begin
          state_d      = S_AMO_RESP;
          amo_b_seen_d = 1'b0;
          amo_r_seen_d = 1'b0;
        end
      end
      // --------------------------------------------------------------------
      S_AMO_RESP: begin
        // A7: consume BOTH the B beat and the R beat
        if (axi_bypass_rsp_i.b_valid) amo_b_seen_d = 1'b1;
        if (axi_bypass_rsp_i.r_valid) begin
          amo_r_seen_d = 1'b1;
          amo_result_d = axi_bypass_rsp_i.r.data;  // pre-operation value
        end
        if (amo_b_seen_d && amo_r_seen_d) begin
          state_d       = S_IDLE;
          amo_pending_d = 1'b0;
          amo_ack_d     = 1'b1;
        end
      end
      // --------------------------------------------------------------------
      default: state_d = S_IDLE;
    endcase
  end

  // --------------------------------------------------------------------------
  // bypass FSM (uncached single accesses)
  // --------------------------------------------------------------------------
  always_comb begin
    bp_state_d   = bp_state_q;
    bp_port_d    = bp_port_q;
    bp_addr_d    = bp_addr_q;
    bp_wdata_d   = bp_wdata_q;
    bp_be_d      = bp_be_q;
    bp_size_d    = bp_size_q;
    bp_we_d      = bp_we_q;
    bp_aw_done_d = bp_aw_done_q;
    bp_w_done_d  = bp_w_done_q;
    bp_valid_d   = 1'b0;
    bp_rdata_d   = bp_rdata_q;

    case (bp_state_q)
      BP_IDLE: begin
        if (bp_sel_valid && !amo_owns_bypass) begin
          bp_state_d   = BP_REQ;
          bp_port_d    = bp_sel;
          bp_addr_d    = miss_req[bp_sel].addr;
          bp_wdata_d   = miss_req[bp_sel].wdata;
          bp_be_d      = miss_req[bp_sel].be;
          bp_size_d    = miss_req[bp_sel].size;
          bp_we_d      = miss_req[bp_sel].we;
          bp_aw_done_d = 1'b0;
          bp_w_done_d  = 1'b0;
        end
      end
      BP_REQ: begin
        if (bp_we_q) begin
          if (bp_aw_fire) bp_aw_done_d = 1'b1;
          if (bp_w_fire)  bp_w_done_d  = 1'b1;
          if (bp_aw_done_d && bp_w_done_d) bp_state_d = BP_WAIT_B;
        end else begin
          if (axi_bypass_rsp_i.ar_ready) bp_state_d = BP_WAIT_R;
        end
      end
      BP_WAIT_R: begin
        if (axi_bypass_rsp_i.r_valid) begin
          bp_state_d = BP_IDLE;
          bp_valid_d = 1'b1;
          bp_rdata_d = axi_bypass_rsp_i.r.data;
        end
      end
      BP_WAIT_B: begin
        if (axi_bypass_rsp_i.b_valid) begin
          bp_state_d = BP_IDLE;
          bp_valid_d = 1'b1;
        end
      end
      default: bp_state_d = BP_IDLE;
    endcase
  end

  // handshake fires
  assign wb_aw_fire = (state_q == S_WB_ISSUE) && !wb_aw_done_q && axi_data_rsp_i.aw_ready;
  assign wb_w_fire  = (state_q == S_WB_ISSUE) && !wb_w_done_q  && axi_data_rsp_i.w_ready;
  assign amo_aw_fire = (state_q == S_AMO_ISSUE) && (bp_state_q == BP_IDLE)
                       && !amo_aw_done_q && axi_bypass_rsp_i.aw_ready;
  assign amo_w_fire  = (state_q == S_AMO_ISSUE) && (bp_state_q == BP_IDLE)
                       && !amo_w_done_q  && axi_bypass_rsp_i.w_ready;
  assign bp_aw_fire = (bp_state_q == BP_REQ) && bp_we_q && !bp_aw_done_q
                      && axi_bypass_rsp_i.aw_ready;
  assign bp_w_fire  = (bp_state_q == BP_REQ) && bp_we_q && !bp_w_done_q
                      && axi_bypass_rsp_i.w_ready;

  // --------------------------------------------------------------------------
  // array port (A6)
  // --------------------------------------------------------------------------
  always_comb begin
    req_o  = '0;
    addr_o = '0;
    data_o = '0;
    be_o   = '0;
    we_o   = 1'b0;

    case (state_q)
      S_IDLE: begin
        // read the target set in the grant cycle to pick a victim
        if (miss_sel_valid && !walk_start) begin
          req_o  = '1;
          addr_o = {miss_req[miss_sel].addr[11:4], 4'b0000};
        end
      end
      S_FLUSH: begin
        // F4: ascending sets, one read then one write per set, vldrty on all
        // ways for the write (clears valid/dirty)
        req_o  = '1;
        addr_o = {flush_cnt_q[8:1], 4'b0000};
        we_o   = flush_cnt_q[0];
        if (flush_cnt_q[0]) be_o.vldrty = '1;
      end
      S_REFILL_STORE: begin
        req_o       = victim_way_q;
        addr_o      = {mshr_addr_q[11:4], 4'b0000};
        we_o        = 1'b1;
        be_o.tag    = '1;
        be_o.data   = '1;
        be_o.vldrty = victim_way_q;
        data_o.tag  = mshr_addr_q[55:12];
        data_o.data = line_q;
        data_o.valid  = 1'b1;
        data_o.dirty  = 1'b0;
      end
      default: ;
    endcase
  end

  // --------------------------------------------------------------------------
  // AXI data port: cacheline reads and evictions (A2)
  // --------------------------------------------------------------------------
  always_comb begin
    axi_data_req_o = '0;   // id/lock/cache/prot/qos/region/user default to 0

    case (state_q)
      S_WB_ISSUE: begin
        if (!wb_aw_done_q) begin
          axi_data_req_o.aw_valid = 1'b1;
          axi_data_req_o.aw.addr  = {8'b0, victim_tag_q, mshr_addr_q[11:4], 4'b0};
          axi_data_req_o.aw.len   = 8'd1;
          axi_data_req_o.aw.size  = 3'd3;
          axi_data_req_o.aw.burst = 2'b01;
        end
        if (!wb_w_done_q) begin
          axi_data_req_o.w_valid = 1'b1;
          axi_data_req_o.w.data  = wb_beat_q ? victim_data_q[127:64] : victim_data_q[63:0];
          axi_data_req_o.w.strb  = '1;
          axi_data_req_o.w.last  = wb_beat_q;
        end
      end
      S_WB_WAIT_B: begin
        axi_data_req_o.b_ready = 1'b1;
      end
      S_REFILL_ISSUE: begin
        axi_data_req_o.ar_valid  = 1'b1;
        axi_data_req_o.ar.addr   = {8'b0, mshr_addr_q[55:4], 4'b0};
        axi_data_req_o.ar.len    = 8'd1;   // LINE_WIDTH / AXI_DATA_W - 1
        axi_data_req_o.ar.size   = 3'd3;
        axi_data_req_o.ar.burst  = 2'b01;
      end
      S_REFILL_DATA: begin
        axi_data_req_o.r_ready = 1'b1;
      end
      default: ;
    endcase
  end

  // --------------------------------------------------------------------------
  // AXI bypass port: uncached accesses and atomics (A7)
  // --------------------------------------------------------------------------
  always_comb begin
    axi_bypass_req_o = '0;  // id/lock/cache/prot/qos/region/user default to 0

    case (bp_state_q)
      BP_REQ: begin
        if (!bp_we_q) begin
          axi_bypass_req_o.ar_valid = 1'b1;
          axi_bypass_req_o.ar.addr  = bp_addr_q;
          axi_bypass_req_o.ar.len   = 8'd0;
          axi_bypass_req_o.ar.size  = {1'b0, bp_size_q};
          axi_bypass_req_o.ar.burst = 2'b01;
        end else begin
          if (!bp_aw_done_q) begin
            axi_bypass_req_o.aw_valid = 1'b1;
            axi_bypass_req_o.aw.addr  = bp_addr_q;
            axi_bypass_req_o.aw.len   = 8'd0;
            axi_bypass_req_o.aw.size  = {1'b0, bp_size_q};
            axi_bypass_req_o.aw.burst = 2'b01;
          end
          if (!bp_w_done_q) begin
            axi_bypass_req_o.w_valid = 1'b1;
            axi_bypass_req_o.w.data  = bp_wdata_q;
            axi_bypass_req_o.w.strb  = bp_be_q;
            axi_bypass_req_o.w.last  = 1'b1;
          end
        end
      end
      BP_WAIT_R: axi_bypass_req_o.r_ready = 1'b1;
      BP_WAIT_B: axi_bypass_req_o.b_ready = 1'b1;
      default: ;
    endcase

    // the atomic shares the bypass AXI port; it waits for the bypass machine
    if (state_q == S_AMO_ISSUE && bp_state_q == BP_IDLE) begin
      if (!amo_aw_done_q) begin
        axi_bypass_req_o.aw_valid = 1'b1;
        axi_bypass_req_o.aw.addr  = amo_addr_q;
        axi_bypass_req_o.aw.len   = 8'd0;
        axi_bypass_req_o.aw.size  = {1'b0, amo_size_q};
        axi_bypass_req_o.aw.burst = 2'b01;
        axi_bypass_req_o.aw.atop  = amo_to_atop(amo_op_q);
      end
      if (!amo_w_done_q) begin
        axi_bypass_req_o.w_valid = 1'b1;
        axi_bypass_req_o.w.data  = (amo_op_q == AMO_AND) ? ~amo_data_q : amo_data_q;
        axi_bypass_req_o.w.strb  = size_strb(amo_size_q, amo_addr_q[2:0]);
        axi_bypass_req_o.w.last  = 1'b1;
      end
    end
    if (state_q == S_AMO_RESP) begin
      axi_bypass_req_o.b_ready = 1'b1;
      axi_bypass_req_o.r_ready = 1'b1;
    end
  end

  // --------------------------------------------------------------------------
  // MSHR interrogation (F3) and per-port status
  // --------------------------------------------------------------------------
  always_comb begin
    for (int unsigned i = 0; i < NR_PORTS; i++) begin
      // F3(a): the index field is a sub-range of the address field, so an
      // address match implies an index match.  F3(b): the port being served
      // is not excluded.
      mshr_addr_matches_o[i]  = mshr_valid_q && (mshr_addr_i[i][55:4] == mshr_addr_q[55:4]);
      mshr_index_matches_o[i] = mshr_valid_q && (mshr_addr_i[i][11:4] == mshr_addr_q[11:4]);
      active_serving_o[i]     = mshr_valid_q && (PORT_SEL_W'(i) == mshr_port_q);
    end
  end

  // --------------------------------------------------------------------------
  // bypass response routing
  // --------------------------------------------------------------------------
  always_comb begin
    bypass_valid_o = '0;
    bypass_valid_o[bp_port_q] = bp_valid_q;
    bypass_data_o = '0;
    bypass_data_o[bp_port_q] = bp_rdata_q;
  end

  // --------------------------------------------------------------------------
  // output assignments
  // --------------------------------------------------------------------------
  assign flush_ack_o = flush_ack_q;
  assign miss_o      = (state_q != S_IDLE);   // miss handler occupied
  assign amo_resp_o  = {amo_ack_q, amo_result_q};

  // A3: forward the requested word as it arrives, ahead of the array write
  assign critical_word_valid_o = (state_q == S_REFILL_DATA) && axi_data_rsp_i.r_valid
                                 && (refill_beat_q == mshr_addr_q[3]);
  assign critical_word_o = critical_word_valid_o ? axi_data_rsp_i.r.data : '0;

  // --------------------------------------------------------------------------
  // sequential
  // --------------------------------------------------------------------------
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state_q        <= S_IDLE;
      flush_cnt_q    <= 9'd0;
      ack_flush_q    <= 1'b0;
      flush_ack_q    <= 1'b0;
      mshr_valid_q   <= 1'b0;
      mshr_addr_q    <= 56'd0;
      mshr_port_q    <= '0;
      victim_way_q   <= '0;
      victim_dirty_q <= 1'b0;
      victim_tag_q   <= '0;
      victim_data_q  <= '0;
      rr_cnt_q       <= 3'd0;
      line_q         <= '0;
      refill_beat_q  <= 1'b0;
      wb_aw_done_q   <= 1'b0;
      wb_w_done_q    <= 1'b0;
      wb_beat_q      <= 1'b0;
      amo_pending_q  <= 1'b0;
      amo_op_q       <= AMO_NONE;
      amo_size_q     <= 2'd0;
      amo_addr_q     <= 64'd0;
      amo_data_q     <= 64'd0;
      amo_aw_done_q  <= 1'b0;
      amo_w_done_q   <= 1'b0;
      amo_b_seen_q   <= 1'b0;
      amo_r_seen_q   <= 1'b0;
      amo_result_q   <= 64'd0;
      amo_ack_q      <= 1'b0;
    end else begin
      state_q        <= state_d;
      flush_cnt_q    <= flush_cnt_d;
      ack_flush_q    <= ack_flush_d;
      flush_ack_q    <= flush_ack_d;
      mshr_valid_q   <= mshr_valid_d;
      mshr_addr_q    <= mshr_addr_d;
      mshr_port_q    <= mshr_port_d;
      victim_way_q   <= victim_way_d;
      victim_dirty_q <= victim_dirty_d;
      victim_tag_q   <= victim_tag_d;
      victim_data_q  <= victim_data_d;
      rr_cnt_q       <= rr_cnt_d;
      line_q         <= line_d;
      refill_beat_q  <= refill_beat_d;
      wb_aw_done_q   <= wb_aw_done_d;
      wb_w_done_q    <= wb_w_done_d;
      wb_beat_q      <= wb_beat_d;
      amo_pending_q  <= amo_pending_d;
      amo_op_q       <= amo_op_d;
      amo_size_q     <= amo_size_d;
      amo_addr_q     <= amo_addr_d;
      amo_data_q     <= amo_data_d;
      amo_aw_done_q  <= amo_aw_done_d;
      amo_w_done_q   <= amo_w_done_d;
      amo_b_seen_q   <= amo_b_seen_d;
      amo_r_seen_q   <= amo_r_seen_d;
      amo_result_q   <= amo_result_d;
      amo_ack_q      <= amo_ack_d;
    end
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      bp_state_q   <= BP_IDLE;
      bp_port_q    <= '0;
      bp_addr_q    <= 64'd0;
      bp_wdata_q   <= 64'd0;
      bp_be_q      <= 8'd0;
      bp_size_q    <= 2'd0;
      bp_we_q      <= 1'b0;
      bp_aw_done_q <= 1'b0;
      bp_w_done_q  <= 1'b0;
      bp_valid_q   <= 1'b0;
      bp_rdata_q   <= 64'd0;
    end else begin
      bp_state_q   <= bp_state_d;
      bp_port_q    <= bp_port_d;
      bp_addr_q    <= bp_addr_d;
      bp_wdata_q   <= bp_wdata_d;
      bp_be_q      <= bp_be_d;
      bp_size_q    <= bp_size_d;
      bp_we_q      <= bp_we_d;
      bp_aw_done_q <= bp_aw_done_d;
      bp_w_done_q  <= bp_w_done_d;
      bp_valid_q   <= bp_valid_d;
      bp_rdata_q   <= bp_rdata_d;
    end
  end

endmodule
