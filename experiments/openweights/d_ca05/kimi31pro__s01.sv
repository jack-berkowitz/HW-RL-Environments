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
    FL_READ,
    FL_WRITE,
    MISS_READ,
    MISS_DECIDE,
    EVICT_AW,
    EVICT_W,
    EVICT_B,
    REFILL_AR,
    REFILL_R,
    REFILL_WRITE,
    BYPASS_REQ,
    BYPASS_RESP,
    AMO_REQ,
    AMO_RESP,
    AMO_ACK
  } state_e;

  state_e state_q, state_d;

  miss_req_t req_dec [NR_PORTS-1:0];

  logic                         sel_miss_valid;
  logic                         sel_bypass_valid;
  logic [$clog2(NR_PORTS)-1:0]  sel_miss_idx;
  logic [$clog2(NR_PORTS)-1:0]  sel_bypass_idx;

  miss_req_t miss_req_q;
  miss_req_t bypass_req_q;
  logic [$clog2(NR_PORTS)-1:0] bypass_port_q;
  logic [NR_PORTS-1:0] serving_q;
  logic mshr_valid_q;

  logic [7:0] flush_cnt_q;
  logic       flush_ack_pending_q;
  logic       amo_pending_q;
  amo_req_t   amo_req_q;

  logic aw_sent_q;
  logic w_sent_q;
  logic ar_sent_q;
  logic b_seen_q;
  logic r_seen_q;
  logic [63:0] amo_result_q;

  logic [2:0] evict_way_q;
  logic [63:0] evict_addr_q;
  logic [LINE_WIDTH-1:0] evict_data_q;
  logic evict_beat_q;

  logic [LINE_WIDTH-1:0] refill_data_q;
  logic refill_beat_q;

  logic [2:0] selected_way;
  logic       selected_invalid;
  logic       invalid_found;

  cache_line_t refill_line;
  logic [LINE_WIDTH-1:0] merged_refill_data;

  genvar g;
  generate
    for (g = 0; g < NR_PORTS; g++) begin : gen_req_decode
      assign req_dec[g] = miss_req_t'(miss_req_i[g]);
    end
  endgenerate

  function automatic logic [5:0] amo_to_atop(input amo_t op);
    begin
      unique case (op)
        AMO_SWAP: amo_to_atop = 6'b110000;
        AMO_ADD:  amo_to_atop = 6'b100000;
        AMO_AND:  amo_to_atop = 6'b010001;
        AMO_OR:   amo_to_atop = 6'b010011;
        AMO_XOR:  amo_to_atop = 6'b010010;
        AMO_MAX:  amo_to_atop = 6'b100100;
        AMO_MAXU: amo_to_atop = 6'b100110;
        AMO_MIN:  amo_to_atop = 6'b100101;
        AMO_MINU: amo_to_atop = 6'b100111;
        default:  amo_to_atop = 6'b000000;
      endcase
    end
  endfunction

  function automatic logic [7:0] amo_strb(
    input logic [1:0] size,
    input logic [2:0] addr_low
  );
    logic [7:0] base;
    begin
      unique case (size)
        2'd0: base = 8'h01;
        2'd1: base = 8'h03;
        2'd2: base = 8'h0f;
        default: base = 8'hff;
      endcase
      amo_strb = base << addr_low;
    end
  endfunction

  /* Descending iteration leaves the lowest requesting index selected. */
  always_comb begin
    sel_miss_valid   = 1'b0;
    sel_bypass_valid = 1'b0;
    sel_miss_idx     = '0;
    sel_bypass_idx   = '0;

    for (int unsigned i = 0; i < NR_PORTS; i++) begin
      if (req_dec[i].valid && !req_dec[i].bypass) begin
        sel_miss_valid = 1'b1;
        sel_miss_idx   = $clog2(NR_PORTS)'(i);
      end
      if (req_dec[i].valid && req_dec[i].bypass) begin
        sel_bypass_valid = 1'b1;
        sel_bypass_idx   = $clog2(NR_PORTS)'(i);
      end
    end
  end

  always_comb begin
    selected_way     = 3'd0;
    selected_invalid = 1'b0;
    invalid_found    = 1'b0;

    for (int unsigned w = 0; w < SET_ASSOC; w++) begin
      if (!data_i[w].valid && !invalid_found) begin
        selected_way     = 3'(w);
        selected_invalid = 1'b1;
        invalid_found    = 1'b1;
      end
    end
  end

  always_comb begin
    merged_refill_data = refill_data_q;
    if (miss_req_q.we) begin
      for (int unsigned b = 0; b < 8; b++) begin
        if (miss_req_q.be[b]) begin
          merged_refill_data[{miss_req_q.addr[3], 6'b0} + b*8 +: 8]
            = miss_req_q.wdata[b*8 +: 8];
        end
      end
    end

    refill_line       = '0;
    refill_line.tag   = miss_req_q.addr[55:12];
    refill_line.data  = merged_refill_data;
    refill_line.valid = 1'b1;
    refill_line.dirty = miss_req_q.we;
  end

  always_comb begin
    state_d = state_q;

    unique case (state_q)
      IDLE: begin
        if (flush_i && !busy_i) begin
          state_d = FL_READ;
        end else if (sel_miss_valid) begin
          state_d = MISS_READ;
        end else if (sel_bypass_valid) begin
          state_d = BYPASS_REQ;
        end else if (amo_req_i.req && !busy_i) begin
          state_d = FL_READ;
        end
      end

      FL_READ: state_d = FL_WRITE;

      FL_WRITE: begin
        if (flush_cnt_q == 8'hff) begin
          state_d = amo_pending_q ? AMO_REQ : IDLE;
        end else begin
          state_d = FL_READ;
        end
      end

      MISS_READ: state_d = MISS_DECIDE;

      MISS_DECIDE: begin
        if (!selected_invalid && data_i[selected_way].valid
            && data_i[selected_way].dirty) begin
          state_d = EVICT_AW;
        end else begin
          state_d = REFILL_AR;
        end
      end

      EVICT_AW: begin
        if (axi_data_rsp_i.aw_ready)
          state_d = EVICT_W;
      end

      EVICT_W: begin
        if (axi_data_rsp_i.w_ready && evict_beat_q)
          state_d = EVICT_B;
      end

      EVICT_B: begin
        if (axi_data_rsp_i.b_valid)
          state_d = REFILL_AR;
      end

      REFILL_AR: begin
        if (axi_data_rsp_i.ar_ready)
          state_d = REFILL_R;
      end

      REFILL_R: begin
        if (axi_data_rsp_i.r_valid && axi_data_rsp_i.r.last)
          state_d = REFILL_WRITE;
      end

      REFILL_WRITE: state_d = IDLE;

      BYPASS_REQ: begin
        if (bypass_req_q.we) begin
          if ((aw_sent_q || axi_bypass_rsp_i.aw_ready)
              && (w_sent_q || axi_bypass_rsp_i.w_ready)) begin
            state_d = BYPASS_RESP;
          end
        end else begin
          if (ar_sent_q || axi_bypass_rsp_i.ar_ready)
            state_d = BYPASS_RESP;
        end
      end

      BYPASS_RESP: begin
        if (bypass_req_q.we) begin
          if (axi_bypass_rsp_i.b_valid)
            state_d = IDLE;
        end else begin
          if (axi_bypass_rsp_i.r_valid)
            state_d = IDLE;
        end
      end

      AMO_REQ: begin
        if (amo_req_q.amo_op == AMO_LR) begin
          if (ar_sent_q || axi_bypass_rsp_i.ar_ready)
            state_d = AMO_RESP;
        end else begin
          if ((aw_sent_q || axi_bypass_rsp_i.aw_ready)
              && (w_sent_q || axi_bypass_rsp_i.w_ready)) begin
            state_d = AMO_RESP;
          end
        end
      end

      AMO_RESP: begin
        if ((b_seen_q || axi_bypass_rsp_i.b_valid
             || amo_req_q.amo_op == AMO_LR)
            && (r_seen_q || axi_bypass_rsp_i.r_valid)) begin
          state_d = AMO_ACK;
        end
      end

      AMO_ACK: state_d = IDLE;

      default: state_d = IDLE;
    endcase
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state_q             <= IDLE;
      miss_req_q          <= '0;
      bypass_req_q        <= '0;
      bypass_port_q       <= '0;
      serving_q           <= '0;
      mshr_valid_q        <= 1'b0;
      flush_cnt_q         <= '0;
      flush_ack_pending_q <= 1'b0;
      amo_pending_q       <= 1'b0;
      amo_req_q           <= '0;
      aw_sent_q           <= 1'b0;
      w_sent_q            <= 1'b0;
      ar_sent_q           <= 1'b0;
      b_seen_q            <= 1'b0;
      r_seen_q            <= 1'b0;
      amo_result_q        <= '0;
      evict_way_q         <= '0;
      evict_addr_q        <= '0;
      evict_data_q        <= '0;
      evict_beat_q        <= 1'b0;
      refill_data_q       <= '0;
      refill_beat_q       <= 1'b0;
    end else begin
      state_q <= state_d;

      unique case (state_q)
        IDLE: begin
          aw_sent_q <= 1'b0;
          w_sent_q  <= 1'b0;
          ar_sent_q <= 1'b0;
          b_seen_q  <= 1'b0;
          r_seen_q  <= 1'b0;

          if (flush_i && !busy_i) begin
            flush_cnt_q         <= '0;
            flush_ack_pending_q <= !amo_req_i.req;
            amo_pending_q       <= amo_req_i.req;
            if (amo_req_i.req)
              amo_req_q <= amo_req_i;
          end else if (sel_miss_valid) begin
            miss_req_q    <= req_dec[sel_miss_idx];
            serving_q     <= NR_PORTS'(1'b1) << sel_miss_idx;
            mshr_valid_q  <= 1'b1;
            refill_data_q <= '0;
            refill_beat_q <= 1'b0;
          end else if (sel_bypass_valid) begin
            bypass_req_q  <= req_dec[sel_bypass_idx];
            bypass_port_q <= sel_bypass_idx;
          end else if (amo_req_i.req && !busy_i) begin
            flush_cnt_q         <= '0;
            flush_ack_pending_q <= 1'b0;
            amo_pending_q       <= 1'b1;
            amo_req_q           <= amo_req_i;
          end
        end

        FL_WRITE: begin
          if (flush_cnt_q != 8'hff)
            flush_cnt_q <= flush_cnt_q + 1'b1;
          else
            flush_ack_pending_q <= 1'b0;
        end

        MISS_DECIDE: begin
          evict_way_q   <= selected_way;
          evict_addr_q  <= {data_i[selected_way].tag,
                            miss_req_q.addr[11:4], 4'b0};
          evict_data_q  <= data_i[selected_way].data;
          evict_beat_q  <= 1'b0;
          refill_beat_q <= 1'b0;
        end

        EVICT_W: begin
          if (axi_data_rsp_i.w_ready)
            evict_beat_q <= 1'b1;
        end

        REFILL_R: begin
          if (axi_data_rsp_i.r_valid) begin
            if (refill_beat_q)
              refill_data_q[127:64] <= axi_data_rsp_i.r.data;
            else
              refill_data_q[63:0] <= axi_data_rsp_i.r.data;
            refill_beat_q <= 1'b1;
          end
        end

        REFILL_WRITE: begin
          serving_q    <= '0;
          mshr_valid_q <= 1'b0;
        end

        BYPASS_REQ: begin
          if (axi_bypass_rsp_i.aw_ready)
            aw_sent_q <= 1'b1;
          if (axi_bypass_rsp_i.w_ready)
            w_sent_q <= 1'b1;
          if (axi_bypass_rsp_i.ar_ready)
            ar_sent_q <= 1'b1;
        end

        AMO_REQ: begin
          if (axi_bypass_rsp_i.aw_ready)
            aw_sent_q <= 1'b1;
          if (axi_bypass_rsp_i.w_ready)
            w_sent_q <= 1'b1;
          if (axi_bypass_rsp_i.ar_ready)
            ar_sent_q <= 1'b1;
        end

        AMO_RESP: begin
          if (axi_bypass_rsp_i.b_valid)
            b_seen_q <= 1'b1;
          if (axi_bypass_rsp_i.r_valid) begin
            r_seen_q     <= 1'b1;
            amo_result_q <= axi_bypass_rsp_i.r.data;
          end
        end

        AMO_ACK: begin
          amo_pending_q <= 1'b0;
        end

        default: begin
        end
      endcase
    end
  end

  always_comb begin
    flush_ack_o          = 1'b0;
    miss_o               = 1'b0;
    bypass_gnt_o         = '0;
    bypass_valid_o       = '0;
    bypass_data_o        = '0;
    miss_gnt_o           = '0;
    active_serving_o     = serving_q;
    critical_word_o      = '0;
    critical_word_valid_o = 1'b0;

    mshr_addr_matches_o  = '0;
    mshr_index_matches_o = '0;

    amo_resp_o       = '0;
    amo_resp_o.result = amo_result_q;

    axi_bypass_req_o = '0;
    axi_data_req_o   = '0;

    req_o  = '0;
    addr_o = '0;
    data_o = '0;
    be_o   = '0;
    we_o   = 1'b0;

    for (int unsigned i = 0; i < NR_PORTS; i++) begin
      if (mshr_valid_q) begin
        mshr_addr_matches_o[i] =
            (mshr_addr_i[i][55:4] == miss_req_q.addr[55:4]);
        mshr_index_matches_o[i] =
            (mshr_addr_i[i][11:4] == miss_req_q.addr[11:4]);
      end
    end

    if (state_q == IDLE && !flush_i && sel_miss_valid)
      miss_o = 1'b1;

    if (state_q == IDLE && !flush_i && !sel_miss_valid
        && sel_bypass_valid) begin
      bypass_gnt_o[sel_bypass_idx] = 1'b1;
    end

    if (state_q == FL_READ || state_q == FL_WRITE) begin
      req_o  = {SET_ASSOC{1'b1}};
      addr_o = {flush_cnt_q, 4'b0};
      if (state_q == FL_WRITE) begin
        we_o       = 1'b1;
        be_o.vldrty = {SET_ASSOC{1'b1}};
      end
    end

    if (state_q == FL_WRITE && flush_cnt_q == 8'hff
        && flush_ack_pending_q) begin
      flush_ack_o = 1'b1;
    end

    if (state_q == MISS_READ) begin
      req_o  = {SET_ASSOC{1'b1}};
      addr_o = miss_req_q.addr[11:0];
    end

    if (state_q == REFILL_WRITE) begin
      req_o        = SET_ASSOC'(1'b1) << evict_way_q;
      addr_o       = miss_req_q.addr[11:0];
      data_o       = refill_line;
      we_o         = 1'b1;
      be_o.tag     = '1;
      be_o.data    = '1;
      be_o.vldrty  = SET_ASSOC'(1'b1) << evict_way_q;
      miss_gnt_o   = serving_q;
    end

    if (state_q == REFILL_R && axi_data_rsp_i.r_valid
        && refill_beat_q == miss_req_q.addr[3]) begin
      critical_word_o       = axi_data_rsp_i.r.data;
      critical_word_valid_o = 1'b1;
    end

    /* Refill AXI read. */
    if (state_q == REFILL_AR) begin
      axi_data_req_o.ar.id     = '0;
      axi_data_req_o.ar.addr   = {miss_req_q.addr[63:4], 4'b0};
      axi_data_req_o.ar.len    = 8'(LINE_WIDTH/AXI_DATA_W - 1);
      axi_data_req_o.ar.size   = 3'd3;
      axi_data_req_o.ar.burst  = 2'b01;
      axi_data_req_o.ar.lock   = 1'b0;
      axi_data_req_o.ar.cache  = 4'b0011;
      axi_data_req_o.ar.prot   = '0;
      axi_data_req_o.ar.qos    = '0;
      axi_data_req_o.ar.region = '0;
      axi_data_req_o.ar.user   = '0;
      axi_data_req_o.ar_valid  = 1'b1;
    end

    if (state_q == REFILL_R)
      axi_data_req_o.r_ready = 1'b1;

    /* Dirty-line eviction. */
    if (state_q == EVICT_AW) begin
      axi_data_req_o.aw.id     = '0;
      axi_data_req_o.aw.addr   = evict_addr_q;
      axi_data_req_o.aw.len    = 8'(LINE_WIDTH/AXI_DATA_W - 1);
      axi_data_req_o.aw.size   = 3'd3;
      axi_data_req_o.aw.burst  = 2'b01;
      axi_data_req_o.aw.lock   = 1'b0;
      axi_data_req_o.aw.cache  = 4'b0011;
      axi_data_req_o.aw.prot   = '0;
      axi_data_req_o.aw.qos    = '0;
      axi_data_req_o.aw.region = '0;
      axi_data_req_o.aw.atop   = '0;
      axi_data_req_o.aw.user   = '0;
      axi_data_req_o.aw_valid  = 1'b1;
    end

    if (state_q == EVICT_W) begin
      axi_data_req_o.w.data = evict_beat_q ? evict_data_q[127:64]
                                           : evict_data_q[63:0];
      axi_data_req_o.w.strb  = '1;
      axi_data_req_o.w.last  = evict_beat_q;
      axi_data_req_o.w.user  = '0;
      axi_data_req_o.w_valid = 1'b1;
    end

    if (state_q == EVICT_B)
      axi_data_req_o.b_ready = 1'b1;

    /* Ordinary uncached bypass access. */
    if (state_q == BYPASS_REQ) begin
      if (bypass_req_q.we) begin
        axi_bypass_req_o.aw.id     = 4'(bypass_port_q);
        axi_bypass_req_o.aw.addr   = bypass_req_q.addr;
        axi_bypass_req_o.aw.len    = '0;
        axi_bypass_req_o.aw.size   = {1'b0, bypass_req_q.size};
        axi_bypass_req_o.aw.burst  = 2'b01;
        axi_bypass_req_o.aw.lock   = 1'b0;
        axi_bypass_req_o.aw.cache  = '0;
        axi_bypass_req_o.aw.prot   = '0;
        axi_bypass_req_o.aw.qos    = '0;
        axi_bypass_req_o.aw.region = '0;
        axi_bypass_req_o.aw.atop   = '0;
        axi_bypass_req_o.aw.user   = '0;
        axi_bypass_req_o.aw_valid  = !aw_sent_q;

        axi_bypass_req_o.w.data  = bypass_req_q.wdata;
        axi_bypass_req_o.w.strb  = bypass_req_q.be;
        axi_bypass_req_o.w.last  = 1'b1;
        axi_bypass_req_o.w.user  = '0;
        axi_bypass_req_o.w_valid = !w_sent_q;
      end else begin
        axi_bypass_req_o.ar.id     = 4'(bypass_port_q);
        axi_bypass_req_o.ar.addr   = bypass_req_q.addr;
        axi_bypass_req_o.ar.len    = '0;
        axi_bypass_req_o.ar.size   = {1'b0, bypass_req_q.size};
        axi_bypass_req_o.ar.burst  = 2'b01;
        axi_bypass_req_o.ar.lock   = 1'b0;
        axi_bypass_req_o.ar.cache  = '0;
        axi_bypass_req_o.ar.prot   = '0;
        axi_bypass_req_o.ar.qos    = '0;
        axi_bypass_req_o.ar.region = '0;
        axi_bypass_req_o.ar.user   = '0;
        axi_bypass_req_o.ar_valid  = !ar_sent_q;
      end
    end

    if (state_q == BYPASS_RESP) begin
      if (bypass_req_q.we) begin
        axi_bypass_req_o.b_ready = 1'b1;
        if (axi_bypass_rsp_i.b_valid)
          bypass_valid_o[bypass_port_q] = 1'b1;
      end else begin
        axi_bypass_req_o.r_ready = 1'b1;
        if (axi_bypass_rsp_i.r_valid) begin
          bypass_valid_o[bypass_port_q] = 1'b1;
          bypass_data_o[bypass_port_q]  = axi_bypass_rsp_i.r.data;
        end
      end
    end

    /* Atomic accesses use the bypass port and return both B and R. */
    if (state_q == AMO_REQ) begin
      if (amo_req_q.amo_op == AMO_LR) begin
        axi_bypass_req_o.ar.id     = '0;
        axi_bypass_req_o.ar.addr   = amo_req_q.operand_a;
        axi_bypass_req_o.ar.len    = '0;
        axi_bypass_req_o.ar.size   = {1'b0, amo_req_q.size};
        axi_bypass_req_o.ar.burst  = 2'b01;
        axi_bypass_req_o.ar.lock   = 1'b1;
        axi_bypass_req_o.ar.cache  = '0;
        axi_bypass_req_o.ar.prot   = '0;
        axi_bypass_req_o.ar.qos    = '0;
        axi_bypass_req_o.ar.region = '0;
        axi_bypass_req_o.ar.user   = '0;
        axi_bypass_req_o.ar_valid  = !ar_sent_q;
      end else begin
        axi_bypass_req_o.aw.id     = '0;
        axi_bypass_req_o.aw.addr   = amo_req_q.operand_a;
        axi_bypass_req_o.aw.len    = '0;
        axi_bypass_req_o.aw.size   = {1'b0, amo_req_q.size};
        axi_bypass_req_o.aw.burst  = 2'b01;
        axi_bypass_req_o.aw.lock   = (amo_req_q.amo_op == AMO_SC);
        axi_bypass_req_o.aw.cache  = '0;
        axi_bypass_req_o.aw.prot   = '0;
        axi_bypass_req_o.aw.qos    = '0;
        axi_bypass_req_o.aw.region = '0;
        axi_bypass_req_o.aw.atop   = amo_to_atop(amo_req_q.amo_op);
        axi_bypass_req_o.aw.user   = '0;
        axi_bypass_req_o.aw_valid  = !aw_sent_q;

        axi_bypass_req_o.w.data  = amo_req_q.operand_b;
        axi_bypass_req_o.w.strb  = amo_strb(amo_req_q.size,
                                            amo_req_q.operand_a[2:0]);
        axi_bypass_req_o.w.last  = 1'b1;
        axi_bypass_req_o.w.user  = '0;
        axi_bypass_req_o.w_valid = !w_sent_q;
      end
    end

    if (state_q == AMO_RESP) begin
      axi_bypass_req_o.b_ready = 1'b1;
      axi_bypass_req_o.r_ready = 1'b1;
    end

    if (state_q == AMO_ACK) begin
      amo_resp_o.ack    = 1'b1;
      amo_resp_o.result = amo_result_q;
    end
  end

endmodule
