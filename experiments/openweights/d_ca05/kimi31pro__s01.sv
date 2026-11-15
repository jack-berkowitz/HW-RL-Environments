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

  localparam int unsigned PORT_W = (NR_PORTS > 1) ? $clog2(NR_PORTS) : 1;
  localparam int unsigned WAY_W  = $clog2(SET_ASSOC);

  typedef enum logic [4:0] {
    ST_IDLE,
    ST_FLUSH_READ,
    ST_FLUSH_WRITE,
    ST_BYP_AW,
    ST_BYP_W,
    ST_BYP_B,
    ST_BYP_AR,
    ST_BYP_R,
    ST_MISS_READ,
    ST_MISS_SELECT,
    ST_WB_AW,
    ST_WB_W,
    ST_WB_B,
    ST_REF_AR,
    ST_REF_R,
    ST_REF_WRITE,
    ST_AMO_AW,
    ST_AMO_W,
    ST_AMO_RESP
  } state_t;

  state_t state;

  miss_req_t miss_req [NR_PORTS];
  miss_req_t req_hold;
  amo_req_t  amo_hold;

  logic [PORT_W-1:0] serv_port;
  logic [PORT_W-1:0] bypass_sel_idx;
  logic [PORT_W-1:0] miss_sel_idx;
  logic              bypass_sel_valid;
  logic              miss_sel_valid;

  logic do_flush;
  logic do_bypass;
  logic do_miss;
  logic do_amo;

  logic        mshr_valid;
  logic [55:0] mshr_addr;

  logic [7:0] flush_count;
  logic       flush_ack_flag;
  logic       amo_pending;

  logic [WAY_W-1:0] selected_way;
  logic [WAY_W-1:0] repl_way;
  logic             repl_found_invalid;
  cache_line_t      repl_line;
  cache_line_t      evict_line;

  logic [LINE_WIDTH-1:0] line_data;
  logic [LINE_WIDTH-1:0] refill_line;
  logic                  beat_count;

  logic        amo_b_seen;
  logic        amo_r_seen;
  logic [63:0] amo_result;

  function automatic logic [5:0] atop_encode(input amo_t op);
    begin
      atop_encode = 6'b000000;
      case (op)
        AMO_SWAP: atop_encode = 6'b110000;
        AMO_ADD:  atop_encode = 6'b010000;
        AMO_AND:  atop_encode = 6'b010001;
        AMO_OR:   atop_encode = 6'b010011;
        AMO_XOR:  atop_encode = 6'b010010;
        AMO_MAX:  atop_encode = 6'b010100;
        AMO_MIN:  atop_encode = 6'b010101;
        AMO_MAXU: atop_encode = 6'b010110;
        AMO_MINU: atop_encode = 6'b010111;
        AMO_CAS1,
        AMO_CAS2: atop_encode = 6'b110001;
        default:  atop_encode = 6'b000000;
      endcase
    end
  endfunction

  function automatic logic [7:0] atomic_strb(
      input logic [1:0] size,
      input logic [2:0] addr
  );
    begin
      case (size)
        2'd0:    atomic_strb = 8'b0000_0001 << addr;
        2'd1:    atomic_strb = 8'b0000_0011 << {addr[2:1], 1'b0};
        2'd2:    atomic_strb = 8'b0000_1111 << {addr[2], 2'b00};
        default: atomic_strb = 8'b1111_1111;
      endcase
    end
  endfunction

  /* Unpack the requester interface. */
  always_comb begin
    for (int unsigned p = 0; p < NR_PORTS; p++) begin
      miss_req[p] = miss_req_t'(miss_req_i[p]);
    end
  end

  /* Independent strict-priority selection for the two request classes. */
  always_comb begin
    bypass_sel_valid = 1'b0;
    miss_sel_valid   = 1'b0;
    bypass_sel_idx   = '0;
    miss_sel_idx     = '0;

    for (int unsigned p = 0; p < NR_PORTS; p++) begin
      if (!bypass_sel_valid && miss_req[p].valid && miss_req[p].bypass) begin
        bypass_sel_valid = 1'b1;
        bypass_sel_idx   = PORT_W'(p);
      end
      if (!miss_sel_valid && miss_req[p].valid && !miss_req[p].bypass) begin
        miss_sel_valid = 1'b1;
        miss_sel_idx   = PORT_W'(p);
      end
    end
  end

  /* Work selection and request acknowledgements. */
  always_comb begin
    do_flush  = 1'b0;
    do_bypass = 1'b0;
    do_miss   = 1'b0;
    do_amo    = 1'b0;

    if (rst_n && state == ST_IDLE) begin
      do_flush = flush_i && !busy_i;
      do_bypass = !do_flush && bypass_sel_valid;
      do_miss = !do_flush && !do_bypass && miss_sel_valid;
      do_amo = !do_flush && !do_bypass && !do_miss && !busy_i &&
               (amo_pending || amo_req_i.req);
    end

    bypass_gnt_o = '0;
    miss_gnt_o   = '0;

    for (int unsigned p = 0; p < NR_PORTS; p++) begin
      bypass_gnt_o[p] = do_bypass && (bypass_sel_idx == PORT_W'(p));
      miss_gnt_o[p]   = do_miss && (miss_sel_idx == PORT_W'(p));
    end

    miss_o = |miss_gnt_o;
  end

  /* MSHR interrogation.  The two comparisons deliberately overlap. */
  always_comb begin
    mshr_addr_matches_o  = '0;
    mshr_index_matches_o = '0;
    active_serving_o     = '0;

    if (mshr_valid) begin
      active_serving_o[serv_port] = 1'b1;
      for (int unsigned p = 0; p < NR_PORTS; p++) begin
        mshr_addr_matches_o[p] =
            (mshr_addr_i[p][55:4] == mshr_addr[55:4]);
        mshr_index_matches_o[p] =
            (mshr_addr_i[p][11:4] == mshr_addr[11:4]);
      end
    end
  end

  /* Lowest-numbered invalid way, falling back to way zero. */
  always_comb begin
    repl_way           = '0;
    repl_found_invalid = 1'b0;

    for (int unsigned w = 0; w < SET_ASSOC; w++) begin
      if (!repl_found_invalid && !data_i[w].valid) begin
        repl_way           = WAY_W'(w);
        repl_found_invalid = 1'b1;
      end
    end

    repl_line = data_i[repl_way];
  end

  /* Merge a store miss into the returning line. */
  always_comb begin
    refill_line = line_data;
    if (req_hold.we) begin
      for (int unsigned b = 0; b < 8; b++) begin
        if (req_hold.be[b]) begin
          if (req_hold.addr[3]) begin
            refill_line[64 + b*8 +: 8] = req_hold.wdata[b*8 +: 8];
          end else begin
            refill_line[b*8 +: 8] = req_hold.wdata[b*8 +: 8];
          end
        end
      end
    end
  end

  /* All combinational output channels and the cache-array port. */
  always_comb begin
    flush_ack_o          = 1'b0;
    bypass_valid_o       = '0;
    bypass_data_o        = '0;
    critical_word_o      = '0;
    critical_word_valid_o = 1'b0;

    axi_bypass_req_o = '0;
    axi_data_req_o   = '0;

    req_o  = '0;
    addr_o = '0;
    data_o = '0;
    be_o   = '0;
    we_o   = 1'b0;

    if (state == ST_FLUSH_WRITE && flush_count == 8'hff &&
        flush_ack_flag) begin
      flush_ack_o = 1'b1;
    end

    case (state)
      ST_FLUSH_READ: begin
        req_o  = {SET_ASSOC{1'b1}};
        addr_o = {flush_count, 4'b0000};
        we_o   = 1'b0;
      end

      ST_FLUSH_WRITE: begin
        req_o       = {SET_ASSOC{1'b1}};
        addr_o      = {flush_count, 4'b0000};
        we_o        = 1'b1;
        data_o      = '0;
        be_o.vldrty = {SET_ASSOC{1'b1}};
      end

      ST_BYP_AW: begin
        axi_bypass_req_o.aw_valid = 1'b1;
        axi_bypass_req_o.aw.id    = '0;
        axi_bypass_req_o.aw.addr  = req_hold.addr;
        axi_bypass_req_o.aw.len   = 8'd0;
        axi_bypass_req_o.aw.size  = {1'b0, req_hold.size};
        axi_bypass_req_o.aw.burst = 2'b01;
      end

      ST_BYP_W: begin
        axi_bypass_req_o.w_valid = 1'b1;
        axi_bypass_req_o.w.data  = req_hold.wdata;
        axi_bypass_req_o.w.strb  = req_hold.be;
        axi_bypass_req_o.w.last  = 1'b1;
      end

      ST_BYP_B: begin
        axi_bypass_req_o.b_ready = 1'b1;
        if (axi_bypass_rsp_i.b_valid) begin
          bypass_valid_o[serv_port] = 1'b1;
        end
      end

      ST_BYP_AR: begin
        axi_bypass_req_o.ar_valid = 1'b1;
        axi_bypass_req_o.ar.id    = '0;
        axi_bypass_req_o.ar.addr  = req_hold.addr;
        axi_bypass_req_o.ar.len   = 8'd0;
        axi_bypass_req_o.ar.size  = {1'b0, req_hold.size};
        axi_bypass_req_o.ar.burst = 2'b01;
      end

      ST_BYP_R: begin
        axi_bypass_req_o.r_ready = 1'b1;
        if (axi_bypass_rsp_i.r_valid) begin
          bypass_valid_o[serv_port] = 1'b1;
          bypass_data_o[serv_port]  = axi_bypass_rsp_i.r.data;
        end
      end

      ST_MISS_READ: begin
        req_o  = {SET_ASSOC{1'b1}};
        addr_o = {mshr_addr[11:4], 4'b0000};
        we_o   = 1'b0;
      end

      ST_WB_AW: begin
        axi_data_req_o.aw_valid = 1'b1;
        axi_data_req_o.aw.id    = '0;
        axi_data_req_o.aw.addr  =
            {8'b0, evict_line.tag, mshr_addr[11:4], 4'b0000};
        axi_data_req_o.aw.len   = 8'd1;
        axi_data_req_o.aw.size  = 3'd3;
        axi_data_req_o.aw.burst = 2'b01;
      end

      ST_WB_W: begin
        axi_data_req_o.w_valid = 1'b1;
        axi_data_req_o.w.strb  = 8'hff;
        axi_data_req_o.w.last  = beat_count;
        if (beat_count) begin
          axi_data_req_o.w.data = evict_line.data[127:64];
        end else begin
          axi_data_req_o.w.data = evict_line.data[63:0];
        end
      end

      ST_WB_B: begin
        axi_data_req_o.b_ready = 1'b1;
      end

      ST_REF_AR: begin
        axi_data_req_o.ar_valid = 1'b1;
        axi_data_req_o.ar.id    = '0;
        axi_data_req_o.ar.addr  = {8'b0, mshr_addr[55:4], 4'b0000};
        axi_data_req_o.ar.len   = 8'd1;
        axi_data_req_o.ar.size  = 3'd3;
        axi_data_req_o.ar.burst = 2'b01;
      end

      ST_REF_R: begin
        axi_data_req_o.r_ready = 1'b1;
        if (axi_data_rsp_i.r_valid && beat_count == req_hold.addr[3]) begin
          critical_word_valid_o = 1'b1;
          critical_word_o       = axi_data_rsp_i.r.data;
        end
      end

      ST_REF_WRITE: begin
        req_o[selected_way]       = 1'b1;
        addr_o                    = {mshr_addr[11:4], 4'b0000};
        we_o                      = 1'b1;
        data_o.tag                = mshr_addr[55:12];
        data_o.data               = refill_line;
        data_o.valid              = 1'b1;
        data_o.dirty              = req_hold.we;
        be_o.tag                  = '1;
        be_o.data                 = '1;
        be_o.vldrty[selected_way] = 1'b1;
      end

      ST_AMO_AW: begin
        axi_bypass_req_o.aw_valid = 1'b1;
        axi_bypass_req_o.aw.id    = '0;
        axi_bypass_req_o.aw.addr  = amo_hold.operand_a;
        axi_bypass_req_o.aw.len   = 8'd0;
        axi_bypass_req_o.aw.size  = {1'b0, amo_hold.size};
        axi_bypass_req_o.aw.burst = 2'b01;
        axi_bypass_req_o.aw.atop  = atop_encode(amo_hold.amo_op);
      end

      ST_AMO_W: begin
        axi_bypass_req_o.w_valid = 1'b1;
        if (amo_hold.amo_op == AMO_AND) begin
          axi_bypass_req_o.w.data = ~amo_hold.operand_b;
        end else begin
          axi_bypass_req_o.w.data = amo_hold.operand_b;
        end
        axi_bypass_req_o.w.strb =
            atomic_strb(amo_hold.size, amo_hold.operand_a[2:0]);
        axi_bypass_req_o.w.last = 1'b1;
      end

      ST_AMO_RESP: begin
        axi_bypass_req_o.b_ready = 1'b1;
        axi_bypass_req_o.r_ready = 1'b1;
      end

      default: begin
      end
    endcase
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state          <= ST_IDLE;
      req_hold       <= '0;
      amo_hold       <= '0;
      serv_port      <= '0;
      mshr_valid     <= 1'b0;
      mshr_addr      <= '0;
      flush_count    <= '0;
      flush_ack_flag <= 1'b0;
      amo_pending    <= 1'b0;
      selected_way   <= '0;
      evict_line     <= '0;
      line_data      <= '0;
      beat_count     <= 1'b0;
      amo_b_seen     <= 1'b0;
      amo_r_seen     <= 1'b0;
      amo_result     <= '0;
      amo_resp_o     <= '0;
    end else begin
      amo_resp_o.ack <= 1'b0;

      case (state)
        ST_IDLE: begin
          if (do_flush) begin
            state          <= ST_FLUSH_READ;
            flush_count    <= 8'd0;
            flush_ack_flag <= !amo_req_i.req;
            if (amo_req_i.req) begin
              amo_hold    <= amo_req_i;
              amo_pending <= 1'b1;
            end
          end else if (do_bypass) begin
            req_hold  <= miss_req[bypass_sel_idx];
            serv_port <= bypass_sel_idx;
            if (miss_req[bypass_sel_idx].we) begin
              state <= ST_BYP_AW;
            end else begin
              state <= ST_BYP_AR;
            end
          end else if (do_miss) begin
            req_hold    <= miss_req[miss_sel_idx];
            serv_port   <= miss_sel_idx;
            mshr_addr   <= miss_req[miss_sel_idx].addr[55:0];
            mshr_valid  <= 1'b1;
            state       <= ST_MISS_READ;
            amo_pending <= 1'b0;
          end else if (do_amo) begin
            if (amo_pending) begin
              state <= ST_AMO_AW;
            end else begin
              amo_hold       <= amo_req_i;
              amo_pending    <= 1'b1;
              flush_count    <= 8'd0;
              flush_ack_flag <= 1'b0;
              state          <= ST_FLUSH_READ;
            end
          end
        end

        ST_FLUSH_READ: begin
          state <= ST_FLUSH_WRITE;
        end

        ST_FLUSH_WRITE: begin
          if (flush_count == 8'hff) begin
            state          <= ST_IDLE;
            flush_ack_flag <= 1'b0;
          end else begin
            flush_count <= flush_count + 8'd1;
            state       <= ST_FLUSH_READ;
          end
        end

        ST_BYP_AW: begin
          if (axi_bypass_rsp_i.aw_ready) begin
            state <= ST_BYP_W;
          end
        end

        ST_BYP_W: begin
          if (axi_bypass_rsp_i.w_ready) begin
            state <= ST_BYP_B;
          end
        end

        ST_BYP_B: begin
          if (axi_bypass_rsp_i.b_valid) begin
            state <= ST_IDLE;
          end
        end

        ST_BYP_AR: begin
          if (axi_bypass_rsp_i.ar_ready) begin
            state <= ST_BYP_R;
          end
        end

        ST_BYP_R: begin
          if (axi_bypass_rsp_i.r_valid) begin
            state <= ST_IDLE;
          end
        end

        ST_MISS_READ: begin
          state <= ST_MISS_SELECT;
        end

        ST_MISS_SELECT: begin
          selected_way <= repl_way;
          evict_line   <= repl_line;
          if (repl_line.valid && repl_line.dirty) begin
            state <= ST_WB_AW;
          end else begin
            state <= ST_REF_AR;
          end
        end

        ST_WB_AW: begin
          if (axi_data_rsp_i.aw_ready) begin
            beat_count <= 1'b0;
            state      <= ST_WB_W;
          end
        end

        ST_WB_W: begin
          if (axi_data_rsp_i.w_ready) begin
            if (beat_count) begin
              state <= ST_WB_B;
            end else begin
              beat_count <= 1'b1;
            end
          end
        end

        ST_WB_B: begin
          if (axi_data_rsp_i.b_valid) begin
            state <= ST_REF_AR;
          end
        end

        ST_REF_AR: begin
          if (axi_data_rsp_i.ar_ready) begin
            beat_count <= 1'b0;
            line_data  <= '0;
            state      <= ST_REF_R;
          end
        end

        ST_REF_R: begin
          if (axi_data_rsp_i.r_valid) begin
            if (beat_count) begin
              line_data[127:64] <= axi_data_rsp_i.r.data;
              state             <= ST_REF_WRITE;
            end else begin
              line_data[63:0] <= axi_data_rsp_i.r.data;
              beat_count      <= 1'b1;
            end
          end
        end

        ST_REF_WRITE: begin
          mshr_valid <= 1'b0;
          state      <= ST_IDLE;
        end

        ST_AMO_AW: begin
          if (axi_bypass_rsp_i.aw_ready) begin
            state <= ST_AMO_W;
          end
        end

        ST_AMO_W: begin
          if (axi_bypass_rsp_i.w_ready) begin
            amo_b_seen <= 1'b0;
            amo_r_seen <= 1'b0;
            state      <= ST_AMO_RESP;
          end
        end

        ST_AMO_RESP: begin
          if (axi_bypass_rsp_i.b_valid) begin
            amo_b_seen <= 1'b1;
          end
          if (axi_bypass_rsp_i.r_valid) begin
            amo_r_seen <= 1'b1;
            amo_result <= axi_bypass_rsp_i.r.data;
          end

          if ((axi_bypass_rsp_i.b_valid || amo_b_seen) &&
              (axi_bypass_rsp_i.r_valid || amo_r_seen)) begin
            state          <= ST_IDLE;
            amo_pending    <= 1'b0;
            amo_b_seen     <= 1'b0;
            amo_r_seen     <= 1'b0;
            amo_resp_o.ack <= 1'b1;
            if (axi_bypass_rsp_i.r_valid) begin
              amo_resp_o.result <= axi_bypass_rsp_i.r.data;
            end else begin
              amo_resp_o.result <= amo_result;
            end
          end
        end

        default: begin
          state       <= ST_IDLE;
          mshr_valid  <= 1'b0;
          amo_pending <= 1'b0;
        end
      endcase
    end
  end

endmodule
