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

  localparam int unsigned NUM_SETS = NUM_WORDS; // 256

  // ---------------------------------------------------------------------------
  // Decoded requesters
  // ---------------------------------------------------------------------------
  miss_req_t req [NR_PORTS];
  logic [NR_PORTS-1:0] miss_req_vec;
  logic [NR_PORTS-1:0] bypass_req_vec;

  // ---------------------------------------------------------------------------
  // Main FSM
  // ---------------------------------------------------------------------------
  typedef enum logic [3:0] {
    M_IDLE,
    M_FLUSH_R,
    M_FLUSH_W,
    M_MISS_RD,
    M_MISS_DECIDE,
    M_EVICT_AW_W0,
    M_EVICT_W1,
    M_EVICT_B,
    M_MISS_AR,
    M_MISS_R,
    M_MISS_WR,
    M_AMO_AW,
    M_AMO_WAIT
  } main_state_t;

  main_state_t main_state_q;

  logic [7:0] flush_idx_q;
  logic       amo_pending_q;
  amo_req_t   amo_req_q;

  logic       mshr_valid_q;
  logic [55:0] mshr_addr_q;

  logic [63:0] miss_addr_q;
  logic [NR_PORTS-1:0] serving_port_q;

  logic [2:0] victim_way_q;
  logic       evict_dirty_q;
  logic [TAG_WIDTH-1:0] evict_tag_q;
  logic [LINE_WIDTH-1:0] evict_data_q;
  logic       evict_aw_done_q;
  logic       evict_w0_done_q;

  logic [LINE_WIDTH-1:0] line_data_q;
  logic       r_count_q;

  logic       amo_aw_done_q;
  logic       amo_w_done_q;
  logic       amo_b_done_q;
  logic       amo_r_done_q;
  logic [63:0] amo_result_q;

  // ---------------------------------------------------------------------------
  // Bypass FSM
  // ---------------------------------------------------------------------------
  typedef enum logic [2:0] {
    B_IDLE,
    B_AR,
    B_R,
    B_WRITE,
    B_B
  } bypass_state_t;

  bypass_state_t bypass_state_q;

  logic [NR_PORTS-1:0] bypass_port_q;
  miss_req_t           bypass_req_q;
  logic                b_aw_done_q;
  logic                b_w_done_q;

  // ---------------------------------------------------------------------------
  // Arbitration / acceptance
  // ---------------------------------------------------------------------------
  logic [NR_PORTS-1:0] miss_sel;
  logic [NR_PORTS-1:0] bypass_sel;
  logic [31:0]         miss_idx;
  logic [31:0]         bypass_idx;

  logic flush_start;
  logic amo_start;
  logic miss_start;
  logic bypass_accept;

  logic [2:0] victim_way_sel;

  integer i;

  // ---------------------------------------------------------------------------
  // Victim way choice
  // ---------------------------------------------------------------------------
  function automatic logic [2:0] victim_way_f(input cache_line_t [SET_ASSOC-1:0] lines);
    logic [2:0] sel;
    sel = 3'd0;
    for (int unsigned k = 0; k < SET_ASSOC; k++) begin
      if (!lines[k].valid) begin
        sel = k[2:0];
      end
    end
    return sel;
  endfunction

  assign victim_way_sel = victim_way_f(data_i);

  // ---------------------------------------------------------------------------
  // Request decoding and strict lowest-index priority arbitration
  // ---------------------------------------------------------------------------
  always_comb begin
    miss_req_vec   = '0;
    bypass_req_vec = '0;

    for (i = 0; i < NR_PORTS; i++) begin
      req[i] = miss_req_t'(miss_req_i[i]);
      if (req[i].valid) begin
        if (req[i].bypass) bypass_req_vec[i] = 1'b1;
        else               miss_req_vec[i]   = 1'b1;
      end
    end
  end

  always_comb begin
    miss_sel   = '0;
    bypass_sel = '0;
    miss_idx   = 0;
    bypass_idx = 0;

    for (i = 0; i < NR_PORTS; i++) begin
      if (miss_req_vec[i] && (miss_sel == '0)) begin
        miss_sel[i] = 1'b1;
        miss_idx    = i;
      end
    end

    for (i = 0; i < NR_PORTS; i++) begin
      if (bypass_req_vec[i] && (bypass_sel == '0)) begin
        bypass_sel[i] = 1'b1;
        bypass_idx    = i;
      end
    end
  end

  always_comb begin
    flush_start = (main_state_q == M_IDLE) && flush_i && !busy_i;

    // F9: a non-bypass miss wins over an atomic taken in the same cycle.
    amo_start = (main_state_q == M_IDLE) && !flush_i && amo_req_i.req &&
                !busy_i && (miss_sel == '0);

    // Flush has priority over a miss. busy_i does NOT gate miss handling.
    miss_start = (main_state_q == M_IDLE) && (miss_sel != '0) &&
                 !(flush_i && !busy_i);

    // Bypass is separately arbitrated. It cannot start while the atomic
    // engine is actively using the bypass AXI port.
    bypass_accept = (bypass_state_q == B_IDLE) && (bypass_sel != '0) &&
                    !((main_state_q == M_AMO_AW) || (main_state_q == M_AMO_WAIT));
  end

  // ---------------------------------------------------------------------------
  // Main state machine
  // ---------------------------------------------------------------------------
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      main_state_q   <= M_IDLE;
      flush_idx_q    <= 8'd0;
      amo_pending_q  <= 1'b0;
      amo_req_q      <= '0;

      mshr_valid_q   <= 1'b0;
      mshr_addr_q    <= '0;
      miss_addr_q    <= '0;
      serving_port_q <= '0;

      victim_way_q   <= 3'd0;
      evict_dirty_q  <= 1'b0;
      evict_tag_q    <= '0;
      evict_data_q   <= '0;
      evict_aw_done_q <= 1'b0;
      evict_w0_done_q <= 1'b0;

      line_data_q    <= '0;
      r_count_q      <= 1'b0;

      amo_aw_done_q  <= 1'b0;
      amo_w_done_q   <= 1'b0;
      amo_b_done_q   <= 1'b0;
      amo_r_done_q   <= 1'b0;
      amo_result_q   <= '0;
    end else begin
      case (main_state_q)
        M_IDLE: begin
          if (flush_start) begin
            main_state_q  <= M_FLUSH_R;
            flush_idx_q   <= 8'd0;
            amo_pending_q <= amo_req_i.req;
            if (amo_req_i.req) amo_req_q <= amo_req_i;
          end else if (miss_start) begin
            main_state_q   <= M_MISS_RD;
            miss_addr_q    <= req[miss_idx].addr;
            mshr_addr_q    <= req[miss_idx].addr[55:0];
            mshr_valid_q   <= 1'b1;
            serving_port_q <= miss_sel;
            amo_pending_q  <= 1'b0; // F9: pending atomic is cleared
          end else if (amo_start) begin
            main_state_q  <= M_FLUSH_R;
            flush_idx_q   <= 8'd0;
            amo_pending_q <= 1'b1;
            amo_req_q     <= amo_req_i;
          end
        end

        M_FLUSH_R: begin
          main_state_q <= M_FLUSH_W;
        end

        M_FLUSH_W: begin
          if (flush_idx_q == NUM_SETS-1) begin
            if (amo_pending_q) begin
              main_state_q   <= M_AMO_AW;
              amo_pending_q  <= 1'b0;
              amo_aw_done_q  <= 1'b0;
              amo_w_done_q   <= 1'b0;
              amo_b_done_q   <= 1'b0;
              amo_r_done_q   <= 1'b0;
            end else begin
              main_state_q <= M_IDLE;
            end
          end else begin
            flush_idx_q  <= flush_idx_q + 1'b1;
            main_state_q <= M_FLUSH_R;
          end
        end

        M_MISS_RD: begin
          main_state_q <= M_MISS_DECIDE;
        end

        M_MISS_DECIDE: begin
          victim_way_q  <= victim_way_sel;
          evict_tag_q   <= data_i[victim_way_sel].tag;
          evict_data_q  <= data_i[victim_way_sel].data;
          evict_dirty_q <= data_i[victim_way_sel].dirty;

          if (data_i[victim_way_sel].dirty) begin
            main_state_q    <= M_EVICT_AW_W0;
            evict_aw_done_q <= 1'b0;
            evict_w0_done_q <= 1'b0;
          end else begin
            main_state_q <= M_MISS_AR;
          end
        end

        M_EVICT_AW_W0: begin
          if (axi_data_rsp_i.aw_ready) evict_aw_done_q <= 1'b1;
          if (axi_data_rsp_i.w_ready)  evict_w0_done_q <= 1'b1;

          if ((evict_aw_done_q || axi_data_rsp_i.aw_ready) &&
              (evict_w0_done_q || axi_data_rsp_i.w_ready)) begin
            main_state_q <= M_EVICT_W1;
          end
        end

        M_EVICT_W1: begin
          if (axi_data_rsp_i.w_ready) main_state_q <= M_EVICT_B;
        end

        M_EVICT_B: begin
          if (axi_data_rsp_i.b_valid) main_state_q <= M_MISS_AR;
        end

        M_MISS_AR: begin
          if (axi_data_rsp_i.ar_ready) begin
            main_state_q <= M_MISS_R;
            line_data_q  <= '0;
            r_count_q    <= 1'b0;
          end
        end

        M_MISS_R: begin
          if (axi_data_rsp_i.r_valid) begin
            if (!r_count_q) begin
              line_data_q[63:0] <= axi_data_rsp_i.r.data;
              r_count_q         <= 1'b1;
              if (axi_data_rsp_i.r.last) main_state_q <= M_MISS_WR;
            end else begin
              line_data_q[127:64] <= axi_data_rsp_i.r.data;
              if (axi_data_rsp_i.r.last) main_state_q <= M_MISS_WR;
            end
          end
        end

        M_MISS_WR: begin
          main_state_q   <= M_IDLE;
          mshr_valid_q   <= 1'b0;
          serving_port_q <= '0;
        end

        M_AMO_AW: begin
          if (bypass_state_q == B_IDLE) begin
            if (axi_bypass_rsp_i.aw_ready) amo_aw_done_q <= 1'b1;
            if (axi_bypass_rsp_i.w_ready)  amo_w_done_q  <= 1'b1;

            if ((amo_aw_done_q || axi_bypass_rsp_i.aw_ready) &&
                (amo_w_done_q || axi_bypass_rsp_i.w_ready)) begin
              main_state_q <= M_AMO_WAIT;
              amo_b_done_q <= 1'b0;
              amo_r_done_q <= 1'b0;
            end
          end
        end

        M_AMO_WAIT: begin
          if (axi_bypass_rsp_i.b_valid) amo_b_done_q <= 1'b1;
          if (axi_bypass_rsp_i.r_valid) begin
            amo_r_done_q <= 1'b1;
            amo_result_q <= axi_bypass_rsp_i.r.data;
          end

          if ((amo_b_done_q || axi_bypass_rsp_i.b_valid) &&
              (amo_r_done_q || axi_bypass_rsp_i.r_valid)) begin
            main_state_q <= M_IDLE;
          end
        end

        default: main_state_q <= M_IDLE;
      endcase
    end
  end

  // ---------------------------------------------------------------------------
  // Bypass state machine
  // ---------------------------------------------------------------------------
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      bypass_state_q <= B_IDLE;
      bypass_port_q  <= '0;
      bypass_req_q   <= '0;
      b_aw_done_q    <= 1'b0;
      b_w_done_q     <= 1'b0;
    end else begin
      case (bypass_state_q)
        B_IDLE: begin
          if (bypass_accept) begin
            bypass_port_q <= bypass_sel;
            bypass_req_q  <= req[bypass_idx];
            b_aw_done_q   <= 1'b0;
            b_w_done_q    <= 1'b0;
            if (req[bypass_idx].we) bypass_state_q <= B_WRITE;
            else                    bypass_state_q <= B_AR;
          end
        end

        B_AR: begin
          if (axi_bypass_rsp_i.ar_ready) bypass_state_q <= B_R;
        end

        B_R: begin
          if (axi_bypass_rsp_i.r_valid) bypass_state_q <= B_IDLE;
        end

        B_WRITE: begin
          if (axi_bypass_rsp_i.aw_ready) b_aw_done_q <= 1'b1;
          if (axi_bypass_rsp_i.w_ready)  b_w_done_q  <= 1'b1;

          if ((b_aw_done_q || axi_bypass_rsp_i.aw_ready) &&
              (b_w_done_q || axi_bypass_rsp_i.w_ready)) begin
            bypass_state_q <= B_B;
          end
        end

        B_B: begin
          if (axi_bypass_rsp_i.b_valid) bypass_state_q <= B_IDLE;
        end

        default: bypass_state_q <= B_IDLE;
      endcase
    end
  end

  // ---------------------------------------------------------------------------
  // Array port
  // ---------------------------------------------------------------------------
  always_comb begin
    req_o  = '0;
    addr_o = '0;
    data_o = '0;
    be_o   = '0;
    we_o   = 1'b0;

    case (main_state_q)
      M_FLUSH_R: begin
        req_o  = '1;
        addr_o = {flush_idx_q, 4'b0};
        we_o   = 1'b0;
      end

      M_FLUSH_W: begin
        req_o  = '1;
        addr_o = {flush_idx_q, 4'b0};
        we_o   = 1'b1;
        data_o = '0;
        be_o.vldrty = '1;
        be_o.tag    = '1;
        be_o.data   = '1;
      end

      M_MISS_RD: begin
        req_o  = '1;
        addr_o = miss_addr_q[11:0];
        we_o   = 1'b0;
      end

      M_MISS_WR: begin
        req_o = '0;
        req_o[victim_way_q] = 1'b1;
        addr_o = miss_addr_q[11:0];
        we_o   = 1'b1;

        data_o.tag   = miss_addr_q[55:12];
        data_o.data  = line_data_q;
        data_o.valid = 1'b1;
        data_o.dirty = 1'b0;

        be_o.tag    = '1;
        be_o.data   = '1;
        be_o.vldrty = '0;
        be_o.vldrty[victim_way_q] = 1'b1;
      end

      default: begin
        req_o  = '0;
        addr_o = '0;
        data_o = '0;
        be_o   = '0;
        we_o   = 1'b0;
      end
    endcase
  end

  // ---------------------------------------------------------------------------
  // AXI data port
  // ---------------------------------------------------------------------------
  always_comb begin
    axi_data_req_o = '0;

    case (main_state_q)
      M_EVICT_AW_W0: begin
        axi_data_req_o.aw_valid = !evict_aw_done_q;
        axi_data_req_o.w_valid  = !evict_w0_done_q;

        axi_data_req_o.aw.id    = '0;
        axi_data_req_o.aw.addr  = {evict_tag_q, miss_addr_q[11:4], 4'b0};
        axi_data_req_o.aw.len   = 8'd1;
        axi_data_req_o.aw.size  = 3'b011;
        axi_data_req_o.aw.burst = 2'b01;

        axi_data_req_o.w.data   = evict_data_q[63:0];
        axi_data_req_o.w.strb   = '1;
        axi_data_req_o.w.last   = 1'b0;
      end

      M_EVICT_W1: begin
        axi_data_req_o.w_valid = 1'b1;
        axi_data_req_o.w.data  = evict_data_q[127:64];
        axi_data_req_o.w.strb  = '1;
        axi_data_req_o.w.last  = 1'b1;
      end

      M_EVICT_B: begin
        axi_data_req_o.b_ready = 1'b1;
      end

      M_MISS_AR: begin
        axi_data_req_o.ar_valid = 1'b1;
        axi_data_req_o.ar.id    = '0;
        axi_data_req_o.ar.addr  = {miss_addr_q[55:4], 4'b0};
        axi_data_req_o.ar.len   = 8'd1;
        axi_data_req_o.ar.size  = 3'b011;
        axi_data_req_o.ar.burst = 2'b01;
      end

      M_MISS_R: begin
        axi_data_req_o.r_ready = 1'b1;
      end

      default: begin
        axi_data_req_o = '0;
      end
    endcase
  end

  // ---------------------------------------------------------------------------
  // AXI bypass port
  // ---------------------------------------------------------------------------
  always_comb begin
    axi_bypass_req_o = '0;

    if ((main_state_q == M_AMO_AW) && (bypass_state_q == B_IDLE)) begin
      // Atomic write leaves as an AXI ATOP.
      axi_bypass_req_o.aw_valid = !amo_aw_done_q;
      axi_bypass_req_o.w_valid  = !amo_w_done_q;

      axi_bypass_req_o.aw.id    = '0;
      axi_bypass_req_o.aw.addr  = amo_req_q.operand_a;
      axi_bypass_req_o.aw.len   = 8'd0;
      axi_bypass_req_o.aw.size  = {1'b0, amo_req_q.size};
      axi_bypass_req_o.aw.burst = 2'b00;
      axi_bypass_req_o.aw.atop  = {2'b00, amo_req_q.amo_op};

      axi_bypass_req_o.w.data = amo_req_q.operand_b;
      axi_bypass_req_o.w.strb = '1;
      axi_bypass_req_o.w.last = 1'b1;
    end else if (main_state_q == M_AMO_WAIT) begin
      axi_bypass_req_o.b_ready = 1'b1;
      axi_bypass_req_o.r_ready = 1'b1;
    end else begin
      case (bypass_state_q)
        B_AR: begin
          axi_bypass_req_o.ar_valid = 1'b1;
          axi_bypass_req_o.ar.id    = '0;
          axi_bypass_req_o.ar.addr  = bypass_req_q.addr;
          axi_bypass_req_o.ar.len   = 8'd0;
          axi_bypass_req_o.ar.size  = {1'b0, bypass_req_q.size};
          axi_bypass_req_o.ar.burst = 2'b01;
        end

        B_R: begin
          axi_bypass_req_o.r_ready = 1'b1;
        end

        B_WRITE: begin
          axi_bypass_req_o.aw_valid = !b_aw_done_q;
          axi_bypass_req_o.w_valid  = !b_w_done_q;

          axi_bypass_req_o.aw.id    = '0;
          axi_bypass_req_o.aw.addr  = bypass_req_q.addr;
          axi_bypass_req_o.aw.len   = 8'd0;
          axi_bypass_req_o.aw.size  = {1'b0, bypass_req_q.size};
          axi_bypass_req_o.aw.burst = 2'b01;

          axi_bypass_req_o.w.data = bypass_req_q.wdata;
          axi_bypass_req_o.w.strb = bypass_req_q.be;
          axi_bypass_req_o.w.last = 1'b1;
        end

        B_B: begin
          axi_bypass_req_o.b_ready = 1'b1;
        end

        default: begin
          axi_bypass_req_o = '0;
        end
      endcase
    end
  end

  // ---------------------------------------------------------------------------
  // Requester-side outputs
  // ---------------------------------------------------------------------------
  always_comb begin
    miss_gnt_o = '0;
    if (miss_start) miss_gnt_o = miss_sel;

    active_serving_o = serving_port_q;

    critical_word_o       = '0;
    critical_word_valid_o = 1'b0;

    if ((main_state_q == M_MISS_R) && axi_data_rsp_i.r_valid) begin
      if (r_count_q == miss_addr_q[3]) begin
        critical_word_valid_o = 1'b1;
        critical_word_o       = axi_data_rsp_i.r.data;
      end
    end

    miss_o = |miss_gnt_o;
  end

  always_comb begin
    bypass_gnt_o   = '0;
    bypass_valid_o = '0;
    bypass_data_o  = '0;

    if (bypass_accept) bypass_gnt_o = bypass_sel;

    if ((bypass_state_q == B_R) && axi_bypass_rsp_i.r_valid) begin
      bypass_valid_o = bypass_port_q;
      for (i = 0; i < NR_PORTS; i++) begin
        if (bypass_port_q[i]) bypass_data_o[i] = axi_bypass_rsp_i.r.data;
      end
    end

    if ((bypass_state_q == B_B) && axi_bypass_rsp_i.b_valid) begin
      bypass_valid_o = bypass_port_q;
    end
  end

  // ---------------------------------------------------------------------------
  // MSHR interrogation
  // ---------------------------------------------------------------------------
  always_comb begin
    mshr_addr_matches_o  = '0;
    mshr_index_matches_o = '0;

    for (i = 0; i < NR_PORTS; i++) begin
      mshr_addr_matches_o[i] =
          mshr_valid_q && (mshr_addr_i[i][55:4] == mshr_addr_q[55:4]);

      mshr_index_matches_o[i] =
          mshr_valid_q && (mshr_addr_i[i][11:4] == mshr_addr_q[11:4]);
    end
  end

  // ---------------------------------------------------------------------------
  // Flush acknowledgement
  // ---------------------------------------------------------------------------
  assign flush_ack_o = (main_state_q == M_FLUSH_W) &&
                       (flush_idx_q == NUM_SETS-1) &&
                       !amo_pending_q;

  // ---------------------------------------------------------------------------
  // Atomic response
  // ---------------------------------------------------------------------------
  always_comb begin
    amo_resp_o.ack    = 1'b0;
    amo_resp_o.result = amo_result_q;

    if (main_state_q == M_AMO_WAIT) begin
      if (axi_bypass_rsp_i.r_valid) begin
        amo_resp_o.result = axi_bypass_rsp_i.r.data;
      end

      if ((amo_b_done_q || axi_bypass_rsp_i.b_valid) &&
          (amo_r_done_q || axi_bypass_rsp_i.r_valid)) begin
        amo_resp_o.ack = 1'b1;
      end
    end
  end

endmodule
