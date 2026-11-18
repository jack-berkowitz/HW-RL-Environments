// =============================================================================
// d_ca05 -- miss_handler_arb : multi-requester cache miss handler
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
  // Types
  // ---------------------------------------------------------------------------
  typedef enum logic [3:0] {
    IDLE,
    FLUSH,
    MISS_READ_SET,
    MISS_AR,
    MISS_R,
    MISS_WRITE,
    AMO_ISSUE,
    AMO_WAIT
  } state_t;

  typedef enum logic [1:0] {
    BYPASS_IDLE,
    BYPASS_SEND,
    BYPASS_WAIT
  } bypass_state_t;

  // ---------------------------------------------------------------------------
  // Request unpacking
  // ---------------------------------------------------------------------------
  miss_req_t miss_req [NR_PORTS];

  always_comb begin
    for (int i = 0; i < NR_PORTS; i++) begin
      miss_req[i] = miss_req_t'(miss_req_i[i]);
    end
  end

  // ---------------------------------------------------------------------------
  // Main FSM state
  // ---------------------------------------------------------------------------
  state_t state_q, state_d;

  // Flush
  logic [7:0] flush_cnt_q, flush_cnt_d;
  logic       flush_phase_q, flush_phase_d;
  logic       amo_pending_q, amo_pending_d;
  logic       flush_ack_pending_q, flush_ack_pending_d;

  // Miss / refill
  logic                   miss_in_flight_q, miss_in_flight_d;
  logic [63:0]            miss_addr_q, miss_addr_d;
  logic [NR_PORTS-1:0]    miss_port_q, miss_port_d;
  logic                   miss_we_q, miss_we_d;
  logic [7:0]             miss_be_q, miss_be_d;
  logic [1:0]             miss_size_q, miss_size_d;
  logic [63:0]            miss_wdata_q, miss_wdata_d;
  logic [1:0]             r_beat_cnt_q, r_beat_cnt_d;
  logic [127:0]           line_data_q, line_data_d;
  logic [SET_ASSOC-1:0]   miss_way_q, miss_way_d;

  // AMO
  logic [3:0]  amo_op_q, amo_op_d;
  logic [1:0]  amo_size_q, amo_size_d;
  logic [63:0] amo_addr_q, amo_addr_d;
  logic [63:0] amo_operand_b_q, amo_operand_b_d;
  logic [63:0] amo_result_q, amo_result_d;
  logic        amo_b_done_q, amo_b_done_d;
  logic        amo_r_done_q, amo_r_done_d;

  // Bypass FSM
  bypass_state_t bypass_state_q, bypass_state_d;

  logic [NR_PORTS-1:0] bypass_port_q, bypass_port_d;
  logic [63:0]         bypass_addr_q, bypass_addr_d;
  logic                bypass_we_q, bypass_we_d;
  logic [63:0]         bypass_wdata_q, bypass_wdata_d;
  logic [7:0]          bypass_be_q, bypass_be_d;
  logic [1:0]          bypass_size_q, bypass_size_d;

  // Combinational helpers
  logic [NR_PORTS-1:0] miss_gnt_comb;
  logic [NR_PORTS-1:0] bypass_gnt_comb;
  logic [NR_PORTS-1:0] miss_req_valid;
  logic [NR_PORTS-1:0] bypass_req_valid;
  logic                bypass_axi_busy;
  logic [63:0]         merged_data;

  // ---------------------------------------------------------------------------
  // Combinational logic
  // ---------------------------------------------------------------------------
  always_comb begin
    // Defaults
    state_d = state_q;
    flush_cnt_d = flush_cnt_q;
    flush_phase_d = flush_phase_q;
    amo_pending_d = amo_pending_q;
    flush_ack_pending_d = flush_ack_pending_q;

    miss_in_flight_d = miss_in_flight_q;
    miss_addr_d = miss_addr_q;
    miss_port_d = miss_port_q;
    miss_we_d = miss_we_q;
    miss_be_d = miss_be_q;
    miss_size_d = miss_size_q;
    miss_wdata_d = miss_wdata_q;
    r_beat_cnt_d = r_beat_cnt_q;
    line_data_d = line_data_q;
    miss_way_d = miss_way_q;

    amo_op_d = amo_op_q;
    amo_size_d = amo_size_q;
    amo_addr_d = amo_addr_q;
    amo_operand_b_d = amo_operand_b_q;
    amo_result_d = amo_result_q;
    amo_b_done_d = amo_b_done_q;
    amo_r_done_d = amo_r_done_q;

    bypass_state_d = bypass_state_q;
    bypass_port_d = bypass_port_q;
    bypass_addr_d = bypass_addr_q;
    bypass_we_d = bypass_we_q;
    bypass_wdata_d = bypass_wdata_q;
    bypass_be_d = bypass_be_q;
    bypass_size_d = bypass_size_q;

    // Output defaults
    axi_data_req_o = '0;
    axi_bypass_req_o = '0;

    req_o = '0;
    addr_o = '0;
    data_o = '0;
    be_o = '0;
    we_o = 1'b0;

    flush_ack_o = 1'b0;
    miss_gnt_o = '0;
    bypass_gnt_o = '0;
    bypass_valid_o = '0;
    bypass_data_o = '0;

    amo_resp_o.ack = 1'b0;
    amo_resp_o.result = amo_result_q;

    critical_word_o = '0;
    critical_word_valid_o = 1'b0;

    miss_o = miss_in_flight_q;
    active_serving_o = miss_in_flight_q ? miss_port_q : '0;

    // MSHR match outputs
    for (int i = 0; i < NR_PORTS; i++) begin
      mshr_addr_matches_o[i] = miss_in_flight_q &&
                               (mshr_addr_i[i][55:4] == miss_addr_q[55:4]);
      mshr_index_matches_o[i] = miss_in_flight_q &&
                                (mshr_addr_i[i][11:4] == miss_addr_q[11:4]);
    end

    // Request valid bits
    for (int i = 0; i < NR_PORTS; i++) begin
      miss_req_valid[i] = miss_req[i].valid && !miss_req[i].bypass;
      bypass_req_valid[i] = miss_req[i].valid && miss_req[i].bypass;
    end

    // Bypass AXI port busy with atomic?
    bypass_axi_busy = (state_q == AMO_ISSUE) || (state_q == AMO_WAIT);

    // Miss arbitration (strict lowest index, non-bypass only)
    miss_gnt_comb = '0;
    if (state_q == IDLE && !flush_i && (|miss_req_valid)) begin
      for (int i = 0; i < NR_PORTS; i++) begin
        if (miss_req_valid[i] && !(|miss_gnt_comb)) begin
          miss_gnt_comb[i] = 1'b1;
        end
      end
    end
    miss_gnt_o = miss_gnt_comb;

    // Bypass arbitration (strict lowest index)
    bypass_gnt_comb = '0;
    if (bypass_state_q == BYPASS_IDLE && !bypass_axi_busy) begin
      for (int i = 0; i < NR_PORTS; i++) begin
        if (bypass_req_valid[i] && !(|bypass_gnt_comb)) begin
          bypass_gnt_comb[i] = 1'b1;
        end
      end
    end
    bypass_gnt_o = bypass_gnt_comb;

    // -------------------------------------------------------------------------
    // Main FSM
    // -------------------------------------------------------------------------
    unique case (state_q)
      IDLE: begin
        if (flush_i && !busy_i) begin
          // Genuine flush (possibly combined with atomic)
          state_d = FLUSH;
          flush_cnt_d = 0;
          flush_phase_d = 0;
          if (amo_req_i.req) begin
            // F8: flush + atomic same cycle -> no ack, atomic pending
            amo_pending_d = 1'b1;
            flush_ack_pending_d = 1'b0;
            amo_op_d = amo_req_i.amo_op;
            amo_size_d = amo_req_i.size;
            amo_addr_d = amo_req_i.operand_a;
            amo_operand_b_d = amo_req_i.operand_b;
          end else begin
            amo_pending_d = 1'b0;
            flush_ack_pending_d = 1'b1;
          end
        end else if (|miss_gnt_comb) begin
          // Miss wins over atomic (F9)
          state_d = MISS_READ_SET;
          miss_in_flight_d = 1'b1;
          miss_port_d = miss_gnt_comb;
          amo_pending_d = 1'b0;
          flush_ack_pending_d = 1'b0;
          for (int i = 0; i < NR_PORTS; i++) begin
            if (miss_gnt_comb[i]) begin
              miss_addr_d = miss_req[i].addr;
              miss_we_d = miss_req[i].we;
              miss_be_d = miss_req[i].be;
              miss_size_d = miss_req[i].size;
              miss_wdata_d = miss_req[i].wdata;
            end
          end
        end else if (amo_req_i.req && !busy_i) begin
          // Atomic-induced flush
          state_d = FLUSH;
          flush_cnt_d = 0;
          flush_phase_d = 0;
          amo_pending_d = 1'b1;
          flush_ack_pending_d = 1'b0;
          amo_op_d = amo_req_i.amo_op;
          amo_size_d = amo_req_i.size;
          amo_addr_d = amo_req_i.operand_a;
          amo_operand_b_d = amo_req_i.operand_b;
        end
      end

      FLUSH: begin
        // Array walk: read then write for each set
        req_o = {SET_ASSOC{1'b1}};
        addr_o = {flush_cnt_q, 4'b0};
        we_o = flush_phase_q;
        if (flush_phase_q) begin
          be_o.vldrty = {SET_ASSOC{1'b1}};
        end else begin
          be_o.vldrty = '0;
        end

        if (flush_cnt_q == 8'd255 && flush_phase_q == 1'b1) begin
          // Last write
          if (flush_ack_pending_q && !amo_pending_q) begin
            flush_ack_o = 1'b1;
          end
          if (amo_pending_q) begin
            state_d = AMO_ISSUE;
          end else begin
            state_d = IDLE;
          end
          flush_cnt_d = 0;
          flush_phase_d = 0;
          amo_pending_d = 1'b0;
          flush_ack_pending_d = 1'b0;
        end else begin
          if (flush_phase_q == 1'b0) begin
            flush_phase_d = 1'b1;
          end else begin
            flush_phase_d = 1'b0;
            flush_cnt_d = flush_cnt_q + 1'b1;
          end
        end
      end

      MISS_READ_SET: begin
        // Read the set to select a way
        req_o = {SET_ASSOC{1'b1}};
        addr_o = {miss_addr_q[11:4], 4'b0};
        we_o = 1'b0;
        state_d = MISS_AR;
      end

      MISS_AR: begin
        // Choose replacement way (first invalid, else way 0)
        miss_way_d = '0;
        for (int i = 0; i < SET_ASSOC; i++) begin
          if (!data_i[i].valid) begin
            miss_way_d[i] = 1'b1;
            break;
          end
        end
        if (miss_way_d == '0) begin
          miss_way_d[0] = 1'b1;
        end

        // Issue AXI read for the cacheline
        axi_data_req_o.ar_valid = 1'b1;
        axi_data_req_o.ar.addr = {miss_addr_q[63:4], 4'b0};
        axi_data_req_o.ar.len = 8'd1;
        axi_data_req_o.ar.size = 3'd3;
        axi_data_req_o.ar.burst = 2'b01;
        axi_data_req_o.ar.id = '0;
        axi_data_req_o.r_ready = 1'b1;

        if (axi_data_rsp_i.ar_ready) begin
          state_d = MISS_R;
          r_beat_cnt_d = 0;
        end
      end

      MISS_R: begin
        axi_data_req_o.r_ready = 1'b1;
        if (axi_data_rsp_i.r_valid) begin
          if (r_beat_cnt_q == 0) begin
            line_data_d[63:0] = axi_data_rsp_i.r.data;
          end else begin
            line_data_d[127:64] = axi_data_rsp_i.r.data;
          end

          // Forward critical word
          if (r_beat_cnt_q == miss_addr_q[3]) begin
            critical_word_o = axi_data_rsp_i.r.data;
            critical_word_valid_o = 1'b1;
          end

          if (axi_data_rsp_i.r.last) begin
            state_d = MISS_WRITE;
          end else begin
            r_beat_cnt_d = r_beat_cnt_q + 1'b1;
          end
        end
      end

      MISS_WRITE: begin
        // Write the refilled line into the selected way
        req_o = miss_way_q;
        addr_o = {miss_addr_q[11:4], 4'b0};
        we_o = 1'b1;

        merged_data = line_data_q[63:0];
        if (miss_we_q) begin
          if (miss_addr_q[3] == 1'b0) begin
            for (int b = 0; b < 8; b++) begin
              if (miss_be_q[b]) begin
                merged_data[b*8 +: 8] = miss_wdata_q[b*8 +: 8];
              end
            end
            data_o.data = {line_data_q[127:64], merged_data};
          end else begin
            for (int b = 0; b < 8; b++) begin
              if (miss_be_q[b]) begin
                merged_data[b*8 +: 8] = miss_wdata_q[b*8 +: 8];
              end
            end
            data_o.data = {merged_data, line_data_q[63:0]};
          end
        end else begin
          data_o.data = line_data_q;
        end

        data_o.tag = miss_addr_q[55:12];
        data_o.valid = 1'b1;
        data_o.dirty = 1'b0;

        be_o.tag = '1;
        be_o.data = '1;
        be_o.vldrty = miss_way_q;

        state_d = IDLE;
        miss_in_flight_d = 1'b0;
      end

      AMO_ISSUE: begin
        // Issue AXI ATOP write on bypass port
        axi_bypass_req_o.aw_valid = 1'b1;
        axi_bypass_req_o.aw.addr = amo_addr_q;
        axi_bypass_req_o.aw.len = 8'd0;
        axi_bypass_req_o.aw.size = amo_size_q;
        axi_bypass_req_o.aw.burst = 2'b01;
        axi_bypass_req_o.aw.atop = {2'b00, amo_op_q};
        axi_bypass_req_o.aw.id = '0;

        axi_bypass_req_o.w_valid = 1'b1;
        axi_bypass_req_o.w.data = amo_operand_b_q;
        axi_bypass_req_o.w.strb = 8'hFF;
        axi_bypass_req_o.w.last = 1'b1;

        axi_bypass_req_o.b_ready = 1'b1;
        axi_bypass_req_o.r_ready = 1'b1;

        if (axi_bypass_rsp_i.aw_ready && axi_bypass_rsp_i.w_ready) begin
          state_d = AMO_WAIT;
          amo_b_done_d = 1'b0;
          amo_r_done_d = 1'b0;
        end
      end

      AMO_WAIT: begin
        axi_bypass_req_o.b_ready = 1'b1;
        axi_bypass_req_o.r_ready = 1'b1;

        if (axi_bypass_rsp_i.b_valid) begin
          amo_b_done_d = 1'b1;
        end
        if (axi_bypass_rsp_i.r_valid) begin
          amo_r_done_d = 1'b1;
          amo_result_d = axi_bypass_rsp_i.r.data;
        end

        if ((amo_b_done_q || axi_bypass_rsp_i.b_valid) &&
            (amo_r_done_q || axi_bypass_rsp_i.r_valid)) begin
          amo_resp_o.ack = 1'b1;
          amo_resp_o.result = axi_bypass_rsp_i.r_valid ?
                              axi_bypass_rsp_i.r.data : amo_result_q;
          state_d = IDLE;
        end
      end

      default: state_d = IDLE;
    endcase

    // -------------------------------------------------------------------------
    // Bypass FSM
    // -------------------------------------------------------------------------
    unique case (bypass_state_q)
      BYPASS_IDLE: begin
        if (|bypass_gnt_comb) begin
          bypass_state_d = BYPASS_SEND;
          bypass_port_d = bypass_gnt_comb;
          for (int i = 0; i < NR_PORTS; i++) begin
            if (bypass_gnt_comb[i]) begin
              bypass_addr_d = miss_req[i].addr;
              bypass_we_d = miss_req[i].we;
              bypass_wdata_d = miss_req[i].wdata;
              bypass_be_d = miss_req[i].be;
              bypass_size_d = miss_req[i].size;
            end
          end
        end
      end

      BYPASS_SEND: begin
        if (!bypass_we_q) begin
          // Single-beat read
          axi_bypass_req_o.ar_valid = 1'b1;
          axi_bypass_req_o.ar.addr = bypass_addr_q;
          axi_bypass_req_o.ar.len = 8'd0;
          axi_bypass_req_o.ar.size = bypass_size_q;
          axi_bypass_req_o.ar.burst = 2'b01;
          axi_bypass_req_o.ar.id = '0;
          axi_bypass_req_o.r_ready = 1'b1;

          if (axi_bypass_rsp_i.ar_ready) begin
            bypass_state_d = BYPASS_WAIT;
          end
        end else begin
          // Single-beat write
          axi_bypass_req_o.aw_valid = 1'b1;
          axi_bypass_req_o.aw.addr = bypass_addr_q;
          axi_bypass_req_o.aw.len = 8'd0;
          axi_bypass_req_o.aw.size = bypass_size_q;
          axi_bypass_req_o.aw.burst = 2'b01;
          axi_bypass_req_o.aw.atop = '0;
          axi_bypass_req_o.aw.id = '0;

          axi_bypass_req_o.w_valid = 1'b1;
          axi_bypass_req_o.w.data = bypass_wdata_q;
          axi_bypass_req_o.w.strb = bypass_be_q;
          axi_bypass_req_o.w.last = 1'b1;

          axi_bypass_req_o.b_ready = 1'b1;

          if (axi_bypass_rsp_i.aw_ready && axi_bypass_rsp_i.w_ready) begin
            bypass_state_d = BYPASS_WAIT;
          end
        end
      end

      BYPASS_WAIT: begin
        if (!bypass_we_q) begin
          axi_bypass_req_o.r_ready = 1'b1;
          if (axi_bypass_rsp_i.r_valid) begin
            bypass_valid_o = bypass_port_q;
            for (int i = 0; i < NR_PORTS; i++) begin
              if (bypass_port_q[i]) begin
                bypass_data_o[i] = axi_bypass_rsp_i.r.data;
              end
            end
            bypass_state_d = BYPASS_IDLE;
          end
        end else begin
          axi_bypass_req_o.b_ready = 1'b1;
          if (axi_bypass_rsp_i.b_valid) begin
            bypass_valid_o = bypass_port_q;
            bypass_state_d = BYPASS_IDLE;
          end
        end
      end

      default: bypass_state_d = BYPASS_IDLE;
    endcase
  end

  // ---------------------------------------------------------------------------
  // Sequential state
  // ---------------------------------------------------------------------------
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state_q <= IDLE;
      flush_cnt_q <= '0;
      flush_phase_q <= 1'b0;
      amo_pending_q <= 1'b0;
      flush_ack_pending_q <= 1'b0;

      miss_in_flight_q <= 1'b0;
      miss_addr_q <= '0;
      miss_port_q <= '0;
      miss_we_q <= 1'b0;
      miss_be_q <= '0;
      miss_size_q <= '0;
      miss_wdata_q <= '0;
      r_beat_cnt_q <= '0;
      line_data_q <= '0;
      miss_way_q <= '0;

      amo_op_q <= '0;
      amo_size_q <= '0;
      amo_addr_q <= '0;
      amo_operand_b_q <= '0;
      amo_result_q <= '0;
      amo_b_done_q <= 1'b0;
      amo_r_done_q <= 1'b0;

      bypass_state_q <= BYPASS_IDLE;
      bypass_port_q <= '0;
      bypass_addr_q <= '0;
      bypass_we_q <= 1'b0;
      bypass_wdata_q <= '0;
      bypass_be_q <= '0;
      bypass_size_q <= '0;
    end else begin
      state_q <= state_d;
      flush_cnt_q <= flush_cnt_d;
      flush_phase_q <= flush_phase_d;
      amo_pending_q <= amo_pending_d;
      flush_ack_pending_q <= flush_ack_pending_d;

      miss_in_flight_q <= miss_in_flight_d;
      miss_addr_q <= miss_addr_d;
      miss_port_q <= miss_port_d;
      miss_we_q <= miss_we_d;
      miss_be_q <= miss_be_d;
      miss_size_q <= miss_size_d;
      miss_wdata_q <= miss_wdata_d;
      r_beat_cnt_q <= r_beat_cnt_d;
      line_data_q <= line_data_d;
      miss_way_q <= miss_way_d;

      amo_op_q <= amo_op_d;
      amo_size_q <= amo_size_d;
      amo_addr_q <= amo_addr_d;
      amo_operand_b_q <= amo_operand_b_d;
      amo_result_q <= amo_result_d;
      amo_b_done_q <= amo_b_done_d;
      amo_r_done_q <= amo_r_done_d;

      bypass_state_q <= bypass_state_d;
      bypass_port_q <= bypass_port_d;
      bypass_addr_q <= bypass_addr_d;
      bypass_we_q <= bypass_we_d;
      bypass_wdata_q <= bypass_wdata_d;
      bypass_be_q <= bypass_be_d;
      bypass_size_q <= bypass_size_d;
    end
  end

endmodule
