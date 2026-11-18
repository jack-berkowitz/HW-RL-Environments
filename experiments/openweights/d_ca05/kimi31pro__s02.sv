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

  typedef enum logic [4:0] {
    IDLE,
    FLUSH_READ,
    FLUSH_WRITE,
    MISS_READ,
    MISS_REPLACE,
    EVICT_AW,
    EVICT_W,
    EVICT_B,
    REFILL_AR,
    REFILL_R,
    BYPASS_REQ,
    BYPASS_RESP,
    AMO_REQ,
    AMO_RESP
  } state_e;

  state_e state_d, state_q;

  miss_req_t miss_req [NR_PORTS];
  miss_req_t mshr_d, mshr_q;

  logic [$clog2(NR_PORTS)-1:0] id_d, id_q;
  logic                        mshr_valid_d, mshr_valid_q;

  logic [7:0] cnt_d, cnt_q;
  logic       flush_d, flush_q;
  logic       serve_amo_d, serve_amo_q;

  logic [2:0] way_d, way_q;
  cache_line_t evict_cl_d, evict_cl_q;
  logic [63:0] refill_low_d, refill_low_q;
  logic        beat_d, beat_q;

  logic aw_sent_d, aw_sent_q;
  logic w_sent_d,  w_sent_q;
  logic ar_sent_d, ar_sent_q;

  logic        amo_b_seen_d, amo_b_seen_q;
  logic        amo_r_seen_d, amo_r_seen_q;
  logic [63:0] amo_result_d, amo_result_q;

  logic [63:0] amo_addr_d, amo_addr_q;
  logic [63:0] amo_data_d, amo_data_q;
  logic [1:0]  amo_size_d, amo_size_q;
  amo_t        amo_op_d, amo_op_q;

  logic       select_found;
  logic       way_found;
  logic [2:0] replacement_way;
  logic [5:0] amo_atop;
  logic [7:0] amo_be;

  integer p;
  integer m;
  integer w;

  for (genvar g = 0; g < NR_PORTS; g++) begin : gen_request_decode
    assign miss_req[g] = miss_req_t'(miss_req_i[g]);
  end

  always_comb begin
    for (m = 0; m < NR_PORTS; m = m + 1) begin
      mshr_addr_matches_o[m] =
          mshr_valid_q && (mshr_addr_i[m][55:4] == mshr_q.addr[55:4]);
      mshr_index_matches_o[m] =
          mshr_valid_q && (mshr_addr_i[m][11:4] == mshr_q.addr[11:4]);
    end
  end

  always_comb begin
    state_d       = state_q;
    mshr_d        = mshr_q;
    id_d          = id_q;
    mshr_valid_d  = mshr_valid_q;
    cnt_d         = cnt_q;
    flush_d       = flush_q;
    serve_amo_d   = serve_amo_q;
    way_d         = way_q;
    evict_cl_d    = evict_cl_q;
    refill_low_d  = refill_low_q;
    beat_d        = beat_q;
    aw_sent_d     = aw_sent_q;
    w_sent_d      = w_sent_q;
    ar_sent_d     = ar_sent_q;
    amo_b_seen_d  = amo_b_seen_q;
    amo_r_seen_d  = amo_r_seen_q;
    amo_result_d  = amo_result_q;
    amo_addr_d    = amo_addr_q;
    amo_data_d    = amo_data_q;
    amo_size_d    = amo_size_q;
    amo_op_d      = amo_op_q;

    flush_ack_o          = 1'b0;
    miss_o               = 1'b0;
    bypass_gnt_o         = '0;
    bypass_valid_o       = '0;
    bypass_data_o        = '0;
    miss_gnt_o           = '0;
    active_serving_o     = '0;
    critical_word_o      = '0;
    critical_word_valid_o = 1'b0;
    amo_resp_o           = '0;

    req_o  = '0;
    addr_o = '0;
    data_o = '0;
    be_o   = '0;
    we_o   = 1'b0;

    select_found   = 1'b0;
    way_found      = 1'b0;
    replacement_way = 3'b000;
    amo_atop       = 6'b000000;
    amo_be         = 8'hff;

    if (mshr_valid_q) begin
      active_serving_o[id_q] = 1'b1;
    end

    axi_bypass_req_o = '0;
    axi_bypass_req_o.aw.addr  = mshr_q.addr;
    axi_bypass_req_o.aw.len   = 8'h00;
    axi_bypass_req_o.aw.size  = {1'b0, mshr_q.size};
    axi_bypass_req_o.aw.burst = 2'b00;
    axi_bypass_req_o.w.data   = mshr_q.wdata;
    axi_bypass_req_o.w.strb   = mshr_q.be;
    axi_bypass_req_o.w.last   = 1'b1;
    axi_bypass_req_o.ar.addr  = mshr_q.addr;
    axi_bypass_req_o.ar.len   = 8'h00;
    axi_bypass_req_o.ar.size  = {1'b0, mshr_q.size};
    axi_bypass_req_o.ar.burst = 2'b00;

    axi_data_req_o = '0;
    axi_data_req_o.aw.addr  = {8'b0, evict_cl_q.tag,
                               mshr_q.addr[11:4], 4'b0};
    axi_data_req_o.aw.len   = 8'd1;
    axi_data_req_o.aw.size  = 3'b011;
    axi_data_req_o.aw.burst = 2'b01;
    axi_data_req_o.w.data   = beat_q ? evict_cl_q.data[127:64]
                                     : evict_cl_q.data[63:0];
    axi_data_req_o.w.strb   = 8'hff;
    axi_data_req_o.w.last   = beat_q;
    axi_data_req_o.ar.addr  = {mshr_q.addr[63:4], 4'b0};
    axi_data_req_o.ar.len   = 8'd1;
    axi_data_req_o.ar.size  = 3'b011;
    axi_data_req_o.ar.burst = 2'b01;

    case (amo_op_q)
      AMO_SWAP: amo_atop = 6'b110000;
      AMO_ADD:  amo_atop = 6'b100000;
      AMO_AND:  amo_atop = 6'b100001;
      AMO_XOR:  amo_atop = 6'b100010;
      AMO_OR:   amo_atop = 6'b100011;
      AMO_MAX:  amo_atop = 6'b100100;
      AMO_MIN:  amo_atop = 6'b100101;
      AMO_MAXU: amo_atop = 6'b100110;
      AMO_MINU: amo_atop = 6'b100111;
      AMO_CAS1,
      AMO_CAS2: amo_atop = 6'b110001;
      default:  amo_atop = 6'b000000;
    endcase

    case (amo_size_q)
      2'd0: amo_be = 8'h01 << amo_addr_q[2:0];
      2'd1: amo_be = 8'h03 << {amo_addr_q[2:1], 1'b0};
      2'd2: amo_be = 8'h0f << {amo_addr_q[2], 2'b00};
      default: amo_be = 8'hff;
    endcase

    case (state_q)
      IDLE: begin
        cnt_d        = '0;
        flush_d      = 1'b0;
        serve_amo_d  = 1'b0;
        mshr_valid_d = 1'b0;
        aw_sent_d    = 1'b0;
        w_sent_d     = 1'b0;
        ar_sent_d    = 1'b0;
        beat_d       = 1'b0;

        for (p = 0; p < NR_PORTS; p = p + 1) begin
          if (!select_found && miss_req[p].valid) begin
            select_found = 1'b1;
            id_d         = p;
            mshr_d       = miss_req[p];

            if (miss_req[p].bypass) begin
              bypass_gnt_o[p] = 1'b1;
              state_d         = BYPASS_REQ;
            end else begin
              miss_gnt_o[p]       = 1'b1;
              active_serving_o[p] = 1'b1;
              miss_o              = 1'b1;
              mshr_valid_d        = 1'b1;
              state_d             = MISS_READ;
            end
          end
        end

        if (!select_found && !busy_i && (flush_i || amo_req_i.req)) begin
          state_d      = FLUSH_READ;
          flush_d      = flush_i;
          serve_amo_d  = amo_req_i.req;
          cnt_d        = '0;

          if (amo_req_i.req) begin
            amo_addr_d = amo_req_i.operand_a;
            amo_data_d = amo_req_i.operand_b;
            amo_size_d = amo_req_i.size;
            amo_op_d   = amo_req_i.amo_op;
          end
        end
      end

      FLUSH_READ: begin
        req_o   = '1;
        addr_o  = {cnt_q, 4'b0000};
        we_o    = 1'b0;
        state_d = FLUSH_WRITE;
      end

      FLUSH_WRITE: begin
        req_o      = '1;
        addr_o     = {cnt_q, 4'b0000};
        we_o       = 1'b1;
        be_o.vldrty = '1;
        data_o     = '0;
        cnt_d      = cnt_q + 1'b1;

        if (cnt_q == 8'hff) begin
          if (serve_amo_q) begin
            state_d    = AMO_REQ;
            aw_sent_d  = 1'b0;
            w_sent_d   = 1'b0;
          end else begin
            state_d     = IDLE;
            flush_ack_o = flush_q;
          end
        end else begin
          state_d = FLUSH_READ;
        end
      end

      MISS_READ: begin
        req_o   = '1;
        addr_o  = mshr_q.addr[INDEX_WIDTH-1:0];
        we_o    = 1'b0;
        state_d = MISS_REPLACE;
      end

      MISS_REPLACE: begin
        for (w = 0; w < SET_ASSOC; w = w + 1) begin
          if (!way_found && !data_i[w].valid) begin
            way_found       = 1'b1;
            replacement_way = w;
          end
        end

        way_d      = replacement_way;
        evict_cl_d = data_i[replacement_way];

        if (data_i[replacement_way].valid &&
            data_i[replacement_way].dirty) begin
          state_d = EVICT_AW;
        end else begin
          state_d = REFILL_AR;
        end
      end

      EVICT_AW: begin
        axi_data_req_o.aw_valid = 1'b1;
        if (axi_data_rsp_i.aw_ready) begin
          state_d = EVICT_W;
          beat_d  = 1'b0;
        end
      end

      EVICT_W: begin
        axi_data_req_o.w_valid = 1'b1;
        if (axi_data_rsp_i.w_ready) begin
          if (beat_q) begin
            state_d = EVICT_B;
          end else begin
            beat_d = 1'b1;
          end
        end
      end

      EVICT_B: begin
        axi_data_req_o.b_ready = 1'b1;
        if (axi_data_rsp_i.b_valid) begin
          state_d = REFILL_AR;
        end
      end

      REFILL_AR: begin
        axi_data_req_o.ar_valid = 1'b1;
        if (axi_data_rsp_i.ar_ready) begin
          state_d = REFILL_R;
          beat_d  = 1'b0;
        end
      end

      REFILL_R: begin
        axi_data_req_o.r_ready = 1'b1;

        if (axi_data_rsp_i.r_valid) begin
          if (!beat_q) begin
            refill_low_d = axi_data_rsp_i.r.data;
            beat_d       = 1'b1;

            if (!mshr_q.addr[3]) begin
              critical_word_o       = axi_data_rsp_i.r.data;
              critical_word_valid_o = 1'b1;
            end
          end else begin
            if (mshr_q.addr[3]) begin
              critical_word_o       = axi_data_rsp_i.r.data;
              critical_word_valid_o = 1'b1;
            end

            req_o          = '0;
            req_o[way_q]   = 1'b1;
            addr_o         = mshr_q.addr[INDEX_WIDTH-1:0];
            we_o           = 1'b1;
            data_o.tag     = mshr_q.addr[55:12];
            data_o.data    = {axi_data_rsp_i.r.data, refill_low_q};
            data_o.valid   = 1'b1;
            data_o.dirty   = 1'b0;
            be_o.tag       = '1;
            be_o.data      = '1;
            be_o.vldrty    = '0;
            be_o.vldrty[way_q] = 1'b1;

            mshr_valid_d = 1'b0;
            state_d      = IDLE;
          end
        end
      end

      BYPASS_REQ: begin
        if (mshr_q.we) begin
          axi_bypass_req_o.aw_valid = !aw_sent_q;
          axi_bypass_req_o.w_valid  = !w_sent_q;

          if (!aw_sent_q && axi_bypass_rsp_i.aw_ready) begin
            aw_sent_d = 1'b1;
          end
          if (!w_sent_q && axi_bypass_rsp_i.w_ready) begin
            w_sent_d = 1'b1;
          end

          if ((aw_sent_q || axi_bypass_rsp_i.aw_ready) &&
              (w_sent_q  || axi_bypass_rsp_i.w_ready)) begin
            state_d = BYPASS_RESP;
          end
        end else begin
          axi_bypass_req_o.ar_valid = !ar_sent_q;

          if (!ar_sent_q && axi_bypass_rsp_i.ar_ready) begin
            ar_sent_d = 1'b1;
          end
          if (ar_sent_q || axi_bypass_rsp_i.ar_ready) begin
            state_d = BYPASS_RESP;
          end
        end
      end

      BYPASS_RESP: begin
        if (mshr_q.we) begin
          axi_bypass_req_o.b_ready = 1'b1;
          if (axi_bypass_rsp_i.b_valid) begin
            bypass_valid_o[id_q] = 1'b1;
            state_d              = IDLE;
          end
        end else begin
          axi_bypass_req_o.r_ready = 1'b1;
          if (axi_bypass_rsp_i.r_valid) begin
            bypass_valid_o[id_q] = 1'b1;
            bypass_data_o[id_q]  = axi_bypass_rsp_i.r.data;
            state_d              = IDLE;
          end
        end
      end

      AMO_REQ: begin
        axi_bypass_req_o.aw.addr  = amo_addr_q;
        axi_bypass_req_o.aw.len   = 8'h00;
        axi_bypass_req_o.aw.size  = {1'b0, amo_size_q};
        axi_bypass_req_o.aw.burst = 2'b00;
        axi_bypass_req_o.aw.atop  = amo_atop;
        axi_bypass_req_o.w.data   = amo_data_q;
        axi_bypass_req_o.w.strb   = amo_be;
        axi_bypass_req_o.w.last   = 1'b1;
        axi_bypass_req_o.aw_valid = !aw_sent_q;
        axi_bypass_req_o.w_valid  = !w_sent_q;

        if (!aw_sent_q && axi_bypass_rsp_i.aw_ready) begin
          aw_sent_d = 1'b1;
        end
        if (!w_sent_q && axi_bypass_rsp_i.w_ready) begin
          w_sent_d = 1'b1;
        end

        if ((aw_sent_q || axi_bypass_rsp_i.aw_ready) &&
            (w_sent_q  || axi_bypass_rsp_i.w_ready)) begin
          state_d      = AMO_RESP;
          amo_b_seen_d = 1'b0;
          amo_r_seen_d = 1'b0;
        end
      end

      AMO_RESP: begin
        axi_bypass_req_o.b_ready = 1'b1;
        axi_bypass_req_o.r_ready = 1'b1;

        if (axi_bypass_rsp_i.b_valid) begin
          amo_b_seen_d = 1'b1;
        end
        if (axi_bypass_rsp_i.r_valid) begin
          amo_r_seen_d = 1'b1;
          amo_result_d = axi_bypass_rsp_i.r.data;
        end

        if ((amo_b_seen_q || axi_bypass_rsp_i.b_valid) &&
            (amo_r_seen_q || axi_bypass_rsp_i.r_valid)) begin
          amo_resp_o.ack = 1'b1;
          amo_resp_o.result = axi_bypass_rsp_i.r_valid
                            ? axi_bypass_rsp_i.r.data
                            : amo_result_q;
          state_d = IDLE;
        end
      end

      default: begin
        state_d = IDLE;
      end
    endcase
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state_q       <= IDLE;
      mshr_q        <= '0;
      id_q          <= '0;
      mshr_valid_q  <= 1'b0;
      cnt_q         <= '0;
      flush_q       <= 1'b0;
      serve_amo_q   <= 1'b0;
      way_q         <= '0;
      evict_cl_q    <= '0;
      refill_low_q  <= '0;
      beat_q        <= 1'b0;
      aw_sent_q     <= 1'b0;
      w_sent_q      <= 1'b0;
      ar_sent_q     <= 1'b0;
      amo_b_seen_q  <= 1'b0;
      amo_r_seen_q  <= 1'b0;
      amo_result_q  <= '0;
      amo_addr_q    <= '0;
      amo_data_q    <= '0;
      amo_size_q    <= '0;
      amo_op_q      <= AMO_NONE;
    end else begin
      state_q       <= state_d;
      mshr_q        <= mshr_d;
      id_q          <= id_d;
      mshr_valid_q  <= mshr_valid_d;
      cnt_q         <= cnt_d;
      flush_q       <= flush_d;
      serve_amo_q   <= serve_amo_d;
      way_q         <= way_d;
      evict_cl_q    <= evict_cl_d;
      refill_low_q  <= refill_low_d;
      beat_q        <= beat_d;
      aw_sent_q     <= aw_sent_d;
      w_sent_q      <= w_sent_d;
      ar_sent_q     <= ar_sent_d;
      amo_b_seen_q  <= amo_b_seen_d;
      amo_r_seen_q  <= amo_r_seen_d;
      amo_result_q  <= amo_result_d;
      amo_addr_q    <= amo_addr_d;
      amo_data_q    <= amo_data_d;
      amo_size_q    <= amo_size_d;
      amo_op_q      <= amo_op_d;
    end
  end

endmodule
