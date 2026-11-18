// =============================================================================
// miss_handler_arb -- multi-requester cache miss handler (d_ca05)
// //
// Implements F1-F9 / A1-A7 of the contract.  Arbitration is strict
// lowest-index priority (F2), the two MSHR match outputs overlap (F3), the
// flush walk is one read + one write per set over all 256 sets (F4), a
// genuine flush acknowledges once (F5), an AMO forces a full unacknowledged
// walk first (F6/F7), and flush_i coincident with an amo request produces
// no acknowledgement at all (F8).  An incoming miss defers a pending
// atomic (F9).  All declarations precede all statements in every block
// (T10 / slang).
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
  // FSM states
  // ---------------------------------------------------------------------------
  localparam int unsigned PORT_W = (NR_PORTS > 1) ? $clog2(NR_PORTS) : 1;

  typedef enum logic [4:0] {
    S_IDLE,
    S_FLUSH_RD, S_FLUSH_WR, S_FLUSH_END,
    S_BP_AR, S_BP_R, S_BP_AW, S_BP_B,
    S_RF_LOOKUP, S_RF_SEL, S_RF_WB_AR, S_RF_WB_W, S_RF_WB_B,
    S_RF_AR, S_RF_R, S_RF_WR,
    S_AMO_AW, S_AMO_RESP, S_AMO_B, S_AMO_AR, S_AMO_R
  } state_e;

  // ---------------------------------------------------------------------------
  // State registers
  // ---------------------------------------------------------------------------
  state_e            state_q;
  logic [7:0]        flush_set_q;
  logic              flush_amo_q;      // walk was forced by an atomic (F6/F7/F8)
  logic              ack_pending_q;    // genuine flush -> pulse ack at end (F5)
  logic              flush_ack_q;

  logic              mshr_valid_q;
  logic [63:0]       mshr_addr_q;
  logic [PORT_W-1:0] serv_port_q;
  logic              rf_we_q;
  logic [7:0]        rf_be_q;
  logic [63:0]       rf_wdata_q;

  logic [2:0]        victim_way_q;
  logic              victim_dirty_q;
  logic [TAG_WIDTH-1:0] victim_tag_q;
  logic [LINE_WIDTH-1:0] victim_data_q;
  logic              wb_beat_q;
  logic [LINE_WIDTH-1:0] line_buf_q;
  logic              beat_q;

  logic [PORT_W-1:0] bp_port_q;
  logic [63:0]       bp_addr_q;
  logic [7:0]        bp_be_q;
  logic [1:0]        bp_size_q;
  logic              bp_we_q;
  logic [63:0]       bp_wdata_q;
  logic [63:0]       bp_rdata_q;
  logic              bp_done_q;

  logic              aw_done_q, w_done_q;
  logic              amo_b_done_q, amo_r_done_q;
  amo_t              amo_op_q;
  logic [1:0]        amo_size_q;
  logic [63:0]       amo_a_q, amo_b_q;
  logic              amo_ack_q;
  logic [63:0]       amo_result_q;
  logic              miss_o_q;

  // ---------------------------------------------------------------------------
  // Combinational helpers
  // ---------------------------------------------------------------------------
  miss_req_t         req [NR_PORTS];
  int unsigned       bp_win, miss_win;
  logic              bp_any, miss_any;
  logic              miss_accept, amo_accept, flush_accept, bp_accept;
  logic [2:0]        victim_way_c;
  logic [LINE_WIDTH-1:0] merged_line_c;
  logic [5:0]        atop_c;
  logic [63:0]       amo_wdata_c;
  logic              rf_r_fire, rf_w_fire;

  // ---- unpack requests and arbitrate: strict lowest-index priority (F2) ------
  always_comb begin
    for (int i = 0; i < NR_PORTS; i++)
      req[i] = miss_req_t'(miss_req_i[i]);
    bp_any    = 1'b0;
    miss_any  = 1'b0;
    bp_win    = 0;
    miss_win  = 0;
    for (int i = NR_PORTS-1; i >= 0; i--) begin
      if (req[i].valid &&  req[i].bypass) begin bp_any   = 1'b1; bp_win   = i; end
      if (req[i].valid && !req[i].bypass) begin miss_any = 1'b1; miss_win = i; end
    end
    // F9: an incoming miss defers the atomic; the atomic in turn subsumes a
    // same-cycle flush request, which is why F8 yields no acknowledgement.
    miss_accept  = miss_any;
    amo_accept   = !miss_any &&  amo_req_i.req && !busy_i;
    flush_accept = !miss_any && !amo_req_i.req && flush_i && !busy_i;
    bp_accept    = !miss_any && !amo_accept && !flush_accept && bp_any;
  end

  // ---- victim way: lowest invalid way, else way 0 ----------------------------
  always_comb begin
    victim_way_c = 3'd0;
    for (int w = SET_ASSOC-1; w >= 0; w--)
      if (!data_i[w].valid)
        victim_way_c = w[2:0];
  end

  // ---- store merge into the refilled line ------------------------------------
  always_comb begin
    merged_line_c = line_buf_q;
    if (rf_we_q) begin
      for (int b = 0; b < 8; b++)
        if (rf_be_q[b])
          merged_line_c[(mshr_addr_q[3:0] * 8) + b*8 +: 8] = rf_wdata_q[b*8 +: 8];
    end
  end

  // ---- AXI ATOP encoding (A7): memory performs the operation -----------------
  function automatic logic [5:0] atop_encode(amo_t op, logic [1:0] size);
    case (op)
      AMO_ADD:   atop_encode = {4'b0001, size};  // ATOP_ADD
      AMO_AND:   atop_encode = {4'b0010, size};  // ATOP_CLR (data complemented)
      AMO_OR:    atop_encode = {4'b0100, size};  // ATOP_SET
      AMO_XOR:   atop_encode = {4'b0111, size};
      AMO_SWAP:  atop_encode = {4'b0011, size};  // ATOP_EV
      AMO_MAX:   atop_encode = {4'b0101, size};  // ATOP_MAX
      AMO_MAXU:  atop_encode = {4'b1000, size};  // ATOP_SAU
      AMO_MIN:   atop_encode = {4'b0110, size};  // ATOP_MIN
      AMO_MINU:  atop_encode = {4'b1001, size};  // ATOP_LAU
      default:   atop_encode = {4'b0011, size};
    endcase
  endfunction

  always_comb begin
    atop_c      = (amo_op_q == AMO_SC) ? 6'd0 : atop_encode(amo_op_q, amo_size_q);
    amo_wdata_c = (amo_op_q == AMO_AND) ? ~amo_b_q : amo_b_q;
  end

  // ---------------------------------------------------------------------------
  // Output drives
  // ---------------------------------------------------------------------------
  // ---- grants (combinational, on the acceptance cycle) -----------------------
  always_comb begin
    for (int i = 0; i < NR_PORTS; i++) begin
      bypass_gnt_o[i] = bp_accept   && (i == bp_win);
      miss_gnt_o[i]   = miss_accept && (i == miss_win);
    end
  end

  // ---- bypass completion ------------------------------------------------------
  always_comb begin
    for (int i = 0; i < NR_PORTS; i++) begin
      bypass_valid_o[i] = bp_done_q && (i == bp_port_q);
      bypass_data_o[i]  = (bp_done_q && (i == bp_port_q)) ? bp_rdata_q : '0;
    end
  end

  // ---- active serving ---------------------------------------------------------
  always_comb begin
    for (int i = 0; i < NR_PORTS; i++)
      active_serving_o[i] = mshr_valid_q && (i == serv_port_q);
  end

  // ---- MSHR interrogation (F3): address match implies index match, and the
  //      requester being served is NOT excluded ---------------------------------
  always_comb begin
    for (int i = 0; i < NR_PORTS; i++) begin
      mshr_addr_matches_o[i]  = mshr_valid_q &&
                                 (mshr_addr_i[i][55:4]  == mshr_addr_q[55:4]);
      mshr_index_matches_o[i] = mshr_valid_q &&
                                 (mshr_addr_i[i][11:4] == mshr_addr_q[11:4]);
    end
  end

  // ---- critical word forwarding (A3) ------------------------------------------
  assign critical_word_valid_o = (state_q == S_RF_R) &&
                                 axi_data_rsp_i.r_valid &&
                                 (beat_q == mshr_addr_q[3]);
  assign critical_word_o       = axi_data_rsp_i.r.data;

  // ---- flush acknowledgement / miss counter / atomic response -----------------
  assign flush_ack_o      = flush_ack_q;
  assign miss_o           = miss_o_q;
  assign amo_resp_o.ack   = amo_ack_q;
  assign amo_resp_o.result = amo_result_q;

  // ---- the cache array port (A6) ----------------------------------------------
  always_comb begin
    req_o  = '0;
    addr_o = '0;
    we_o   = 1'b0;
    be_o   = '0;
    data_o = '0;
    unique case (state_q)
      S_FLUSH_RD: begin                       // one read per set, all ways
        req_o  = '1;
        addr_o = {flush_set_q, 4'h0};
        we_o   = 1'b0;
      end
      S_FLUSH_WR: begin                       // one write per set, vldrty only
        req_o       = '1;
        addr_o      = {flush_set_q, 4'h0};
        we_o        = 1'b1;
        be_o.vldrty = '1;                     // clears valid+dirty of all ways
      end
      S_RF_LOOKUP: begin
        req_o  = '1;
        addr_o = mshr_addr_q[11:0];
      end
      S_RF_WR: begin
        req_o        = {{(SET_ASSOC-1){1'b0}}, 1'b1} << victim_way_q;
        addr_o       = mshr_addr_q[11:0];
        we_o         = 1'b1;
        be_o.tag     = '1;
        be_o.data    = '1;
        be_o.vldrty  = {{(SET_ASSOC-1){1'b0}}, 1'b1} << victim_way_q;
        data_o.tag   = mshr_addr_q[55:12];
        data_o.data  = merged_line_c;
        data_o.valid = 1'b1;
        data_o.dirty = rf_we_q;
      end
      default: ;
    endcase
  end

  // ---- AXI bypass port ---------------------------------------------------------
  always_comb begin
    axi_bypass_req_o = '0;
    unique case (state_q)
      S_BP_AR: begin
        axi_bypass_req_o.ar_valid = 1'b1;
        axi_bypass_req_o.ar.id    = {2'b00, bp_port_q};
        axi_bypass_req_o.ar.addr  = bp_addr_q;
        axi_bypass_req_o.ar.len   = 8'd0;
        axi_bypass_req_o.ar.size  = {1'b0, bp_size_q};
        axi_bypass_req_o.ar.burst = 2'b01;
      end
      S_BP_R: axi_bypass_req_o.r_ready = 1'b1;
      S_BP_AW: begin
        if (!aw_done_q) begin
          axi_bypass_req_o.aw_valid = 1'b1;
          axi_bypass_req_o.aw.id    = {2'b00, bp_port_q};
          axi_bypass_req_o.aw.addr  = bp_addr_q;
          axi_bypass_req_o.aw.len   = 8'd0;
          axi_bypass_req_o.aw.size  = {1'b0, bp_size_q};
          axi_bypass_req_o.aw.burst = 2'b01;
        end
        if (!w_done_q) begin
          axi_bypass_req_o.w_valid = 1'b1;
          axi_bypass_req_o.w.data  = bp_wdata_q;
          axi_bypass_req_o.w.strb  = bp_be_q;
          axi_bypass_req_o.w.last  = 1'b1;
        end
      end
      S_BP_B: axi_bypass_req_o.b_ready = 1'b1;
      S_AMO_AW: begin
        if (!aw_done_q) begin
          axi_bypass_req_o.aw_valid = 1'b1;
          axi_bypass_req_o.aw.addr  = amo_a_q;
          axi_bypass_req_o.aw.len   = 8'd0;
          axi_bypass_req_o.aw.size  = {1'b0, amo_size_q};
          axi_bypass_req_o.aw.burst = 2'b01;
          axi_bypass_req_o.aw.atop  = atop_c;
        end
        if (!w_done_q) begin
          axi_bypass_req_o.w_valid = 1'b1;
          axi_bypass_req_o.w.data  = amo_wdata_c;
          axi_bypass_req_o.w.strb  = '1;
          axi_bypass_req_o.w.last  = 1'b1;
        end
      end
      S_AMO_RESP: begin
        axi_bypass_req_o.b_ready = 1'b1;
        axi_bypass_req_o.r_ready = 1'b1;
      end
      S_AMO_B: axi_bypass_req_o.b_ready = 1'b1;
      S_AMO_AR: begin
        axi_bypass_req_o.ar_valid = 1'b1;
        axi_bypass_req_o.ar.addr  = amo_a_q;
        axi_bypass_req_o.ar.len  = 8'd0;
        axi_bypass_req_o.ar.size = {1'b0, amo_size_q};
        axi_bypass_req_o.ar.burst = 2'b01;
      end
      S_AMO_R: axi_bypass_req_o.r_ready = 1'b1;
      default: ;
    endcase
  end

  // ---- AXI refill port ---------------------------------------------------------
  always_comb begin
    axi_data_req_o = '0;
    unique case (state_q)
      S_RF_WB_AR: begin
        axi_data_req_o.aw_valid = 1'b1;
        axi_data_req_o.aw.addr  = {8'b0, victim_tag_q, mshr_addr_q[11:4], 4'b0};
        axi_data_req_o.aw.len   = 8'd1;
        axi_data_req_o.aw.size  = 3'd3;
        axi_data_req_o.aw.burst = 2'b01;
      end
      S_RF_WB_W: begin
        axi_data_req_o.w_valid = 1'b1;
        axi_data_req_o.w.data   = wb_beat_q ? victim_data_q[127:64]
                                             : victim_data_q[63:0];
        axi_data_req_o.w.last   = wb_beat_q;
      end
      S_RF_WB_B: axi_data_req_o.b_ready = 1'b1;
      S_RF_AR: begin
        axi_data_req_o.ar_valid = 1'b1;
        axi_data_req_o.ar.addr  = {8'b0, mshr_addr_q[55:4], 4'b0};
        axi_data_req_o.ar.len   = 8'd1;                 // LINE_WIDTH/AXI_DATA_W
        axi_data_req_o.ar.size  = 3'd3;
        axi_data_req_o.ar.burst = 2'b01;
      end
      S_RF_R: axi_data_req_o.r_ready = 1'b1;
      default: ;
    endcase
  end

  // ---------------------------------------------------------------------------
  // Sequential logic
  // ---------------------------------------------------------------------------
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state_q        <= S_IDLE;
      flush_set_q    <= 8'd0;
      flush_amo_q    <= 1'b0;
      ack_pending_q  <= 1'b0;
      flush_ack_q    <= 1'b0;
      mshr_valid_q   <= 1'b0;
      mshr_addr_q    <= 64'd0;
      serv_port_q    <= '0;
      rf_we_q        <= 1'b0;
      rf_be_q        <= 8'd0;
      rf_wdata_q     <= 64'd0;
      victim_way_q   <= 3'd0;
      victim_dirty_q <= 1'b0;
      victim_tag_q   <= '0;
      victim_data_q  <= '0;
      wb_beat_q      <= 1'b0;
      line_buf_q     <= '0;
      beat_q         <= 1'b0;
      bp_port_q      <= '0;
      bp_addr_q      <= 64'd0;
      bp_be_q        <= 8'd0;
      bp_size_q      <= 2'd0;
      bp_we_q        <= 1'b0;
      bp_wdata_q     <= 64'd0;
      bp_rdata_q     <= 64'd0;
      bp_done_q      <= 1'b0;
      aw_done_q      <= 1'b0;
      w_done_q       <= 1'b0;
      amo_b_done_q   <= 1'b0;
      amo_r_done_q   <= 1'b0;
      amo_op_q       <= AMO_NONE;
      amo_size_q     <= 2'd0;
      amo_a_q        <= 64'd0;
      amo_b_q        <= 64'd0;
      amo_ack_q      <= 1'b0;
      amo_result_q   <= 64'd0;
      miss_o_q       <= 1'b0;
    end else begin
      // single-cycle pulses clear by default
      bp_done_q   <= 1'b0;
      amo_ack_q   <= 1'b0;
      flush_ack_q <= 1'b0;
      miss_o_q    <= 1'b0;

      rf_r_fire = (state_q == S_RF_R) && axi_data_rsp_i.r_valid;
      rf_w_fire = (state_q == S_RF_WB_AR) && axi_data_rsp_i.aw_ready;
      // (kept simple; rf_r_fire/rf_w_fire are workspace locals)

      unique case (state_q)
        // ------------------------------------------------------------------
        S_IDLE: begin
          aw_done_q    <= 1'b0;
          w_done_q     <= 1'b0;
          amo_b_done_q <= 1'b0;
          amo_r_done_q <= 1'b0;
          if (miss_accept) begin
            mshr_valid_q <= 1'b1;
            mshr_addr_q  <= req[miss_win].addr;
            serv_port_q  <= miss_win[PORT_W-1:0];
            rf_we_q      <= req[miss_win].we;
            rf_be_q      <= req[miss_win].be;
            rf_wdata_q   <= req[miss_win].wdata;
            miss_o_q     <= 1'b1;
            state_q      <= S_RF_LOOKUP;
          end else if (amo_accept) begin
            // F6: the atomic forces the flush walk first; because the atomic
            // subsumes a same-cycle flush_i, no ack is ever pending (F8).
            flush_amo_q <= 1'b1;
            flush_set_q <= 8'd0;
            amo_op_q    <= amo_req_i.amo_op;
            amo_size_q  <= amo_req_i.size;
            amo_a_q     <= amo_req_i.operand_a;
            amo_b_q     <= amo_req_i.operand_b;
            state_q     <= S_FLUSH_RD;
          end else if (flush_accept) begin
            ack_pending_q <= 1'b1;   // F5: genuine flush acknowledges
            flush_set_q  <= 8'd0;
            state_q      <= S_FLUSH_RD;
          end else if (bp_accept) begin
            bp_port_q  <= bp_win[PORT_W-1:0];
            bp_addr_q  <= req[bp_win].addr;
            bp_be_q    <= req[bp_win].be;
            bp_size_q  <= req[bp_win].size;
            bp_we_q    <= req[bp_win].we;
            bp_wdata_q <= req[bp_win].wdata;
            state_q    <= req[bp_win].we ? S_BP_AW : S_BP_AR;
          end
        end

        // ------------------------------------------------------------------
        // flush walk: 256 sets, one read + one write each (F4)
        S_FLUSH_RD: state_q <= S_FLUSH_WR;
        S_FLUSH_WR: begin
          if (flush_set_q == 8'd255)
            state_q <= S_FLUSH_END;
          else begin
            flush_set_q <= flush_set_q + 8'd1;
            state_q     <= S_FLUSH_RD;
          end
        end
        S_FLUSH_END: begin
          if (ack_pending_q) begin
            flush_ack_q  <= 1'b1;    // F5
            ack_pending_q <= 1'b0;
          end
          if (flush_amo_q) begin
            flush_amo_q <= 1'b0;    // F7: no ack for the AMO-induced walk
            state_q     <= S_AMO_AW; // issued below (LR/SC handled in S_AMO_AW)
          end else begin
            state_q <= S_IDLE;
          end
        end

        // ------------------------------------------------------------------
        // bypass single accesses
        S_BP_AR: if (axi_bypass_rsp_i.ar_ready) state_q <= S_BP_R;
        S_BP_R: begin
          if (axi_bypass_rsp_i.r_valid) begin
            bp_rdata_q <= axi_bypass_rsp_i.r.data;
            bp_done_q  <= 1'b1;
            state_q    <= S_IDLE;
          end
        end
        S_BP_AW: begin
          if (axi_bypass_rsp_i.aw_ready) aw_done_q <= 1'b1;
          if (axi_bypass_rsp_i.w_ready)  w_done_q  <= 1'b1;
          if ((aw_done_q || axi_bypass_rsp_i.aw_ready) &&
              (w_done_q  || axi_bypass_rsp_i.w_ready)) begin
            aw_done_q <= 1'b0;
            w_done_q  <= 1'b0;
            state_q   <= S_BP_B;
          end
        end
        S_BP_B: begin
          if (axi_bypass_rsp_i.b_valid) begin
            bp_done_q <= 1'b1;
            state_q   <= S_IDLE;
          end
        end

        // ------------------------------------------------------------------
        // cacheline refill
        S_RF_LOOKUP: state_q <= S_RF_SEL;
        S_RF_SEL: begin
          victim_way_q  <= victim_way_c;
          victim_dirty_q <= data_i[victim_way_c].dirty;
          victim_tag_q  <= data_i[victim_way_c].tag;
          victim_data_q <= data_i[victim_way_c].data;
          state_q <= data_i[victim_way_c].dirty ? S_RF_WB_AR : S_RF_AR;
        end
        S_RF_WB_AR: begin
          if (axi_data_rsp_i.aw_ready) begin
            wb_beat_q <= 1'b0;
            state_q   <= S_RF_WB_W;
          end
        end
        S_RF_WB_W: begin
          if (axi_data_rsp_i.w_ready) begin
            if (wb_beat_q) state_q <= S_RF_WB_B;
            else           wb_beat_q <= 1'b1;
          end
        end
        S_RF_WB_B: if (axi_data_rsp_i.b_valid) state_q <= S_RF_AR;
        S_RF_AR: begin
          if (axi_data_rsp_i.ar_ready) begin
            beat_q  <= 1'b0;
            state_q <= S_RF_R;
          end
        end
        S_RF_R: begin
          if (axi_data_rsp_i.r_valid) begin
            line_buf_q[{beat_q, 6'd0} +: 64] <= axi_data_rsp_i.r.data;
            beat_q <= beat_q + 1'b1;
            if (axi_data_rsp_i.r.last) state_q <= S_RF_WR;
          end
        end
        S_RF_WR: begin
          mshr_valid_q <= 1'b0;      // match outputs return to zero (F3)
          state_q      <= S_IDLE;
        end

        // ------------------------------------------------------------------
        // atomics (A7): ATOP write consumes BOTH B and R; the R data is the
        // pre-operation value and becomes amo_resp_o.result.
        S_AMO_AW: begin
          if (axi_bypass_rsp_i.aw_ready) aw_done_q <= 1'b1;
          if (axi_bypass_rsp_i.w_ready)  w_done_q  <= 1'b1;
          if ((aw_done_q || axi_bypass_rsp_i.aw_ready) &&
              (w_done_q  || axi_bypass_rsp_i.w_ready)) begin
            aw_done_q <= 1'b0;
            w_done_q  <= 1'b0;
            if (amo_op_q == AMO_LR) state_q <= S_AMO_AR;  // LR: plain read
            else if (amo_op_q == AMO_SC) state_q <= S_AMO_B; // SC: plain write
            else state_q <= S_AMO_RESP;
          end
        end
        S_AMO_RESP: begin
          if (axi_bypass_rsp_i.b_valid) amo_b_done_q <= 1'b1;
          if (axi_bypass_rsp_i.r_valid) begin
            amo_r_done_q <= 1'b1;
            amo_result_q <= axi_bypass_rsp_i.r.data;
          end
          if ((amo_b_done_q || axi_bypass_rsp_i.b_valid) &&
              (amo_r_done_q || axi_bypass_rsp_i.r_valid)) begin
            amo_ack_q    <= 1'b1;
            amo_b_done_q <= 1'b0;
            amo_r_done_q <= 1'b0;
            state_q      <= S_IDLE;
          end
        end
        S_AMO_B: begin
          if (axi_bypass_rsp_i.b_valid) begin
            amo_ack_q  <= 1'b1;
            amo_result_q <= 64'd0;
            state_q    <= S_IDLE;
          end
        end
        S_AMO_AR: if (axi_bypass_rsp_i.ar_ready) state_q <= S_AMO_R;
        S_AMO_R: begin
          if (axi_bypass_rsp_i.r_valid) begin
            amo_ack_q  <= 1'b1;
            amo_result_q <= axi_bypass_rsp_i.r.data;
            state_q    <= S_IDLE;
          end
        end

        default: state_q <= S_IDLE;
      endcase
    end
  end

endmodule
