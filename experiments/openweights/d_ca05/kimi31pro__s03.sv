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

  typedef enum logic [3:0] {
    S_IDLE,
    S_FLUSH_READ,
    S_FLUSH_INV,
    S_MISS_READ,
    S_MISS_SELECT,
    S_WB_AW,
    S_WB_W,
    S_WB_B,
    S_MISS_AR,
    S_MISS_R,
    S_MISS_WRITE,
    S_AMO_ISSUE,
    S_AMO_WAIT
  } state_e;

  typedef enum logic [1:0] {
    BP_IDLE,
    BP_READ,
    BP_WRITE
  } bp_state_e;

  state_e    state_q;
  bp_state_e bp_state_q;

  miss_req_t miss_req [NR_PORTS-1:0];

  logic                     miss_sel_valid;
  logic                     bypass_sel_valid;
  logic [PORT_W-1:0]        miss_sel;
  logic [PORT_W-1:0]        bypass_sel;
  logic                     take_miss;
  logic                     start_flush;
  logic                     start_amo;
  logic                     flush_start_for_amo;
  logic                     bp_take;
  logic                     amo_bus_active;

  logic [7:0]               flush_cnt_q;
  logic                     flush_for_amo_q;
  logic                     flush_lines_valid_q;
  cache_line_t [SET_ASSOC-1:0] flush_lines_q;
  cache_line_t [SET_ASSOC-1:0] flush_scan_lines;
  cache_line_t [SET_ASSOC-1:0] flush_lines_clear;
  logic                     flush_dirty_found;
  logic [WAY_W-1:0]         flush_dirty_way;

  logic                     mshr_valid_q;
  logic [63:0]              mshr_addr_q;
  logic [63:0]              mshr_wdata_q;
  logic [7:0]               mshr_be_q;
  logic                     mshr_we_q;
  logic [PORT_W-1:0]        mshr_port_q;
  logic [WAY_W-1:0]         mshr_way_q;

  logic [WAY_W-1:0]         repl_way;
  logic                     repl_invalid_found;
  logic                     repl_dirty;

  logic [LINE_WIDTH-1:0]    line_buffer_q;
  logic [LINE_WIDTH-1:0]    refill_line;
  logic                     refill_beat_q;

  logic                     wb_from_flush_q;
  logic [63:0]              wb_addr_q;
  logic [LINE_WIDTH-1:0]    wb_data_q;
  logic                     wb_beat_q;

  logic [PORT_W-1:0]        bp_port_q;
  logic [63:0]              bp_addr_q;
  logic [63:0]              bp_wdata_q;
  logic [7:0]               bp_be_q;
  logic [1:0]               bp_size_q;
  logic                     bp_aw_sent_q;
  logic                     bp_w_sent_q;
  logic                     bp_ar_sent_q;

  amo_t                     amo_op_q;
  logic [1:0]               amo_size_q;
  logic [63:0]              amo_operand_a_q;
  logic [63:0]              amo_operand_b_q;
  logic                     amo_aw_sent_q;
  logic                     amo_w_sent_q;
  logic                     amo_b_seen_q;
  logic                     amo_r_seen_q;
  logic [63:0]              amo_result_q;

  function automatic logic [5:0] amo_atop(input amo_t op);
    begin
      amo_atop = 6'b000000;
      case (op)
        AMO_SWAP:         amo_atop = 6'b110000;
        AMO_ADD:          amo_atop = 6'b100000;
        AMO_AND:          amo_atop = 6'b100001;
        AMO_XOR:          amo_atop = 6'b100010;
        AMO_OR:           amo_atop = 6'b100011;
        AMO_MAX:          amo_atop = 6'b100100;
        AMO_MIN:          amo_atop = 6'b100101;
        AMO_MAXU:         amo_atop = 6'b100110;
        AMO_MINU:         amo_atop = 6'b100111;
        AMO_CAS1, AMO_CAS2: amo_atop = 6'b110001;
        default:          amo_atop = 6'b000000;
      endcase
    end
  endfunction

  function automatic logic [7:0] amo_strb(
      input logic [1:0] size,
      input logic [2:0] offset
  );
    begin
      case (size)
        2'd0:    amo_strb = 8'b00000001 << offset;
        2'd1:    amo_strb = 8'b00000011 << offset;
        2'd2:    amo_strb = 8'b00001111 << offset;
        default: amo_strb = 8'b11111111;
      endcase
    end
  endfunction

  generate
    for (genvar g = 0; g < NR_PORTS; g++) begin : gen_request_unpack
      assign miss_req[g] = miss_req_t'(miss_req_i[g]);
    end
  endgenerate

  // Both request classes use fixed, lowest-index priority.
  always_comb begin
    miss_sel_valid = 1'b0;
    miss_sel       = '0;
    for (int unsigned i = 0; i < NR_PORTS; i++) begin
      if (!miss_sel_valid && miss_req[i].valid && !miss_req[i].bypass) begin
        miss_sel_valid = 1'b1;
        miss_sel       = PORT_W'(i);
      end
    end
  end

  always_comb begin
    bypass_sel_valid = 1'b0;
    bypass_sel       = '0;
    for (int unsigned i = 0; i < NR_PORTS; i++) begin
      if (!bypass_sel_valid && miss_req[i].valid && miss_req[i].bypass) begin
        bypass_sel_valid = 1'b1;
        bypass_sel       = PORT_W'(i);
      end
    end
  end

  // A genuine flush has priority over misses. An atomic, in contrast, is
  // considered only when no refill request is present.
  always_comb begin
    take_miss           = 1'b0;
    start_flush         = 1'b0;
    start_amo           = 1'b0;
    flush_start_for_amo = 1'b0;

    if (rst_n && state_q == S_IDLE) begin
      if (flush_i && !busy_i) begin
        start_flush         = 1'b1;
        flush_start_for_amo = amo_req_i.req;
      end else if (miss_sel_valid) begin
        take_miss = 1'b1;
      end else if (amo_req_i.req && !busy_i) begin
        start_amo           = 1'b1;
        flush_start_for_amo = 1'b1;
      end
    end
  end

  // The two comparisons deliberately overlap, and no requester is excluded.
  always_comb begin
    mshr_addr_matches_o  = '0;
    mshr_index_matches_o = '0;
    if (mshr_valid_q) begin
      for (int unsigned i = 0; i < NR_PORTS; i++) begin
        mshr_addr_matches_o[i] =
            (mshr_addr_i[i][55:4] == mshr_addr_q[55:4]);
        mshr_index_matches_o[i] =
            (mshr_addr_i[i][11:4] == mshr_addr_q[11:4]);
      end
    end
  end

  // Prefer an invalid way; way zero is the deterministic fallback.
  always_comb begin
    repl_way           = '0;
    repl_invalid_found = 1'b0;
    for (int unsigned i = 0; i < SET_ASSOC; i++) begin
      if (!repl_invalid_found && !data_i[i].valid) begin
        repl_way           = WAY_W'(i);
        repl_invalid_found = 1'b1;
      end
    end
    repl_dirty = data_i[repl_way].valid && data_i[repl_way].dirty;
  end

  // On the first inspection of a set, data_i is the synchronous array read
  // result. The saved copy is used only when dirty ways require writebacks.
  always_comb begin
    flush_scan_lines  = flush_lines_valid_q ? flush_lines_q : data_i;
    flush_lines_clear = flush_scan_lines;
    flush_dirty_found = 1'b0;
    flush_dirty_way   = '0;

    for (int unsigned i = 0; i < SET_ASSOC; i++) begin
      if (!flush_dirty_found &&
          flush_scan_lines[i].valid && flush_scan_lines[i].dirty) begin
        flush_dirty_found = 1'b1;
        flush_dirty_way   = WAY_W'(i);
      end
    end

    if (flush_dirty_found)
      flush_lines_clear[flush_dirty_way].dirty = 1'b0;
  end

  // Merge a store miss into the returning line.
  always_comb begin
    refill_line = line_buffer_q;
    if (mshr_we_q) begin
      for (int unsigned j = 0; j < AXI_DATA_W/8; j++) begin
        if (mshr_be_q[j]) begin
          refill_line[(mshr_addr_q[3] ? 64 : 0) + j*8 +: 8] =
              mshr_wdata_q[j*8 +: 8];
        end
      end
    end
  end

  assign bp_take = rst_n && (bp_state_q == BP_IDLE) && bypass_sel_valid &&
                   (state_q != S_AMO_ISSUE) && (state_q != S_AMO_WAIT);

  assign amo_bus_active =
      ((state_q == S_AMO_ISSUE) || (state_q == S_AMO_WAIT)) &&
      (bp_state_q == BP_IDLE);

  // Cache-array port, refill AXI port, MSHR status, and flush/AMO responses.
  always_comb begin
    flush_ack_o           = 1'b0;
    miss_o                = take_miss;
    miss_gnt_o            = '0;
    active_serving_o      = '0;
    critical_word_o       = '0;
    critical_word_valid_o = 1'b0;
    amo_resp_o            = '0;

    req_o  = '0;
    addr_o = '0;
    data_o = '0;
    be_o   = '0;
    we_o   = 1'b0;

    axi_data_req_o = '0;

    if (take_miss)
      miss_gnt_o[miss_sel] = 1'b1;

    if (mshr_valid_q)
      active_serving_o[mshr_port_q] = 1'b1;

    case (state_q)
      S_FLUSH_READ: begin
        req_o  = '1;
        addr_o = {flush_cnt_q, 4'b0000};
        we_o   = 1'b0;
      end

      S_FLUSH_INV: begin
        // Dirty ways are written back before this set is invalidated. A clean
        // set therefore costs exactly one read and one write array access.
        if (!flush_dirty_found) begin
          req_o       = '1;
          addr_o      = {flush_cnt_q, 4'b0000};
          data_o      = '0;
          be_o.vldrty = '1;
          we_o        = 1'b1;

          if (flush_cnt_q == 8'hff && !flush_for_amo_q)
            flush_ack_o = 1'b1;
        end
      end

      S_MISS_READ: begin
        req_o  = '1;
        addr_o = mshr_addr_q[INDEX_WIDTH-1:0];
        we_o   = 1'b0;
      end

      S_WB_AW: begin
        axi_data_req_o.aw.id     = '0;
        axi_data_req_o.aw.addr   = wb_addr_q;
        axi_data_req_o.aw.len    = 8'd1;
        axi_data_req_o.aw.size   = 3'd3;
        axi_data_req_o.aw.burst  = 2'b01;
        axi_data_req_o.aw_valid  = 1'b1;
      end

      S_WB_W: begin
        axi_data_req_o.w.data  = wb_beat_q ? wb_data_q[127:64]
                                           : wb_data_q[63:0];
        axi_data_req_o.w.strb  = '1;
        axi_data_req_o.w.last  = wb_beat_q;
        axi_data_req_o.w_valid = 1'b1;
      end

      S_WB_B: begin
        axi_data_req_o.b_ready = 1'b1;
      end

      S_MISS_AR: begin
        axi_data_req_o.ar.id     = axi_id_t'(mshr_port_q);
        axi_data_req_o.ar.addr   = {mshr_addr_q[63:4], 4'b0000};
        axi_data_req_o.ar.len    = 8'd1;
        axi_data_req_o.ar.size   = 3'd3;
        axi_data_req_o.ar.burst  = 2'b01;
        axi_data_req_o.ar_valid  = 1'b1;
      end

      S_MISS_R: begin
        axi_data_req_o.r_ready = 1'b1;
        if (axi_data_rsp_i.r_valid &&
            (refill_beat_q == mshr_addr_q[3])) begin
          critical_word_o       = axi_data_rsp_i.r.data;
          critical_word_valid_o = 1'b1;
        end
      end

      S_MISS_WRITE: begin
        req_o                    = '0;
        req_o[mshr_way_q]        = 1'b1;
        addr_o                   = mshr_addr_q[INDEX_WIDTH-1:0];
        data_o.tag               = mshr_addr_q[55:12];
        data_o.data              = refill_line;
        data_o.valid             = 1'b1;
        data_o.dirty             = mshr_we_q;
        be_o.tag                 = '1;
        be_o.data                = '1;
        be_o.vldrty              = '0;
        be_o.vldrty[mshr_way_q]  = 1'b1;
        we_o                     = 1'b1;
      end

      default: begin
      end
    endcase

    if (amo_bus_active &&
        (amo_b_seen_q || axi_bypass_rsp_i.b_valid) &&
        (amo_r_seen_q || axi_bypass_rsp_i.r_valid)) begin
      amo_resp_o.ack = 1'b1;
      amo_resp_o.result = axi_bypass_rsp_i.r_valid
                        ? axi_bypass_rsp_i.r.data
                        : amo_result_q;
    end
  end

  // Bypass AXI port. An atomic owns this port only after any previously
  // accepted normal bypass transaction has completed.
  always_comb begin
    axi_bypass_req_o = '0;
    bypass_gnt_o     = '0;
    bypass_valid_o   = '0;
    bypass_data_o    = '0;

    if (bp_take)
      bypass_gnt_o[bypass_sel] = 1'b1;

    if (amo_bus_active) begin
      if (state_q == S_AMO_ISSUE) begin
        axi_bypass_req_o.aw.id    = '0;
        axi_bypass_req_o.aw.addr  = amo_operand_a_q;
        axi_bypass_req_o.aw.len   = 8'd0;
        axi_bypass_req_o.aw.size  = {1'b0, amo_size_q};
        axi_bypass_req_o.aw.burst = 2'b01;
        axi_bypass_req_o.aw.atop  = amo_atop(amo_op_q);
        axi_bypass_req_o.aw_valid = !amo_aw_sent_q;

        axi_bypass_req_o.w.data =
            (amo_op_q == AMO_AND) ? ~amo_operand_b_q : amo_operand_b_q;
        axi_bypass_req_o.w.strb =
            amo_strb(amo_size_q, amo_operand_a_q[2:0]);
        axi_bypass_req_o.w.last  = 1'b1;
        axi_bypass_req_o.w_valid = !amo_w_sent_q;
      end

      // ATOP writes return both channels; either may arrive first.
      axi_bypass_req_o.b_ready = 1'b1;
      axi_bypass_req_o.r_ready = 1'b1;
    end else begin
      case (bp_state_q)
        BP_READ: begin
          axi_bypass_req_o.ar.id     = axi_id_t'(bp_port_q);
          axi_bypass_req_o.ar.addr   = bp_addr_q;
          axi_bypass_req_o.ar.len    = 8'd0;
          axi_bypass_req_o.ar.size   = {1'b0, bp_size_q};
          axi_bypass_req_o.ar.burst  = 2'b01;
          axi_bypass_req_o.ar_valid  = !bp_ar_sent_q;
          axi_bypass_req_o.r_ready   = 1'b1;

          if (axi_bypass_rsp_i.r_valid) begin
            bypass_valid_o[bp_port_q] = 1'b1;
            bypass_data_o[bp_port_q]  = axi_bypass_rsp_i.r.data;
          end
        end

        BP_WRITE: begin
          axi_bypass_req_o.aw.id     = axi_id_t'(bp_port_q);
          axi_bypass_req_o.aw.addr   = bp_addr_q;
          axi_bypass_req_o.aw.len    = 8'd0;
          axi_bypass_req_o.aw.size   = {1'b0, bp_size_q};
          axi_bypass_req_o.aw.burst  = 2'b01;
          axi_bypass_req_o.aw_valid  = !bp_aw_sent_q;

          axi_bypass_req_o.w.data    = bp_wdata_q;
          axi_bypass_req_o.w.strb    = bp_be_q;
          axi_bypass_req_o.w.last    = 1'b1;
          axi_bypass_req_o.w_valid   = !bp_w_sent_q;
          axi_bypass_req_o.b_ready   = 1'b1;

          if (axi_bypass_rsp_i.b_valid)
            bypass_valid_o[bp_port_q] = 1'b1;
        end

        default: begin
        end
      endcase
    end
  end

  // Main refill/flush/atomic sequencer.
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state_q             <= S_IDLE;
      flush_cnt_q         <= '0;
      flush_for_amo_q     <= 1'b0;
      flush_lines_valid_q <= 1'b0;
      mshr_valid_q        <= 1'b0;
      mshr_port_q         <= '0;
      amo_aw_sent_q       <= 1'b0;
      amo_w_sent_q        <= 1'b0;
      amo_b_seen_q        <= 1'b0;
      amo_r_seen_q        <= 1'b0;
      amo_result_q        <= '0;
    end else begin
      case (state_q)
        S_IDLE: begin
          if (start_flush || start_amo) begin
            state_q             <= S_FLUSH_READ;
            flush_cnt_q         <= '0;
            flush_for_amo_q     <= flush_start_for_amo;
            flush_lines_valid_q <= 1'b0;

            if (flush_start_for_amo) begin
              amo_op_q        <= amo_req_i.amo_op;
              amo_size_q      <= amo_req_i.size;
              amo_operand_a_q <= amo_req_i.operand_a;
              amo_operand_b_q <= amo_req_i.operand_b;
              amo_aw_sent_q   <= 1'b0;
              amo_w_sent_q    <= 1'b0;
              amo_b_seen_q    <= 1'b0;
              amo_r_seen_q    <= 1'b0;
              amo_result_q    <= '0;
            end
          end else if (take_miss) begin
            state_q       <= S_MISS_READ;
            mshr_valid_q  <= 1'b1;
            mshr_addr_q   <= miss_req[miss_sel].addr;
            mshr_wdata_q  <= miss_req[miss_sel].wdata;
            mshr_be_q     <= miss_req[miss_sel].be;
            mshr_we_q     <= miss_req[miss_sel].we;
            mshr_port_q   <= miss_sel;
          end
        end

        S_FLUSH_READ: begin
          state_q <= S_FLUSH_INV;
        end

        S_FLUSH_INV: begin
          if (flush_dirty_found) begin
            flush_lines_q       <= flush_lines_clear;
            flush_lines_valid_q <= 1'b1;
            wb_from_flush_q     <= 1'b1;
            wb_addr_q <= {
                8'b0,
                flush_scan_lines[flush_dirty_way].tag,
                flush_cnt_q,
                4'b0000
            };
            wb_data_q <= flush_scan_lines[flush_dirty_way].data;
            state_q   <= S_WB_AW;
          end else begin
            flush_lines_valid_q <= 1'b0;
            if (flush_cnt_q == 8'hff) begin
              if (flush_for_amo_q) begin
                state_q       <= S_AMO_ISSUE;
                amo_aw_sent_q <= 1'b0;
                amo_w_sent_q  <= 1'b0;
                amo_b_seen_q  <= 1'b0;
                amo_r_seen_q  <= 1'b0;
              end else begin
                state_q <= S_IDLE;
              end
            end else begin
              flush_cnt_q <= flush_cnt_q + 1'b1;
              state_q     <= S_FLUSH_READ;
            end
          end
        end

        S_MISS_READ: begin
          state_q <= S_MISS_SELECT;
        end

        S_MISS_SELECT: begin
          mshr_way_q <= repl_way;
          if (repl_dirty) begin
            wb_from_flush_q <= 1'b0;
            wb_addr_q <= {
                8'b0,
                data_i[repl_way].tag,
                mshr_addr_q[11:4],
                4'b0000
            };
            wb_data_q <= data_i[repl_way].data;
            state_q   <= S_WB_AW;
          end else begin
            state_q <= S_MISS_AR;
          end
        end

        S_WB_AW: begin
          if (axi_data_rsp_i.aw_ready) begin
            wb_beat_q <= 1'b0;
            state_q   <= S_WB_W;
          end
        end

        S_WB_W: begin
          if (axi_data_rsp_i.w_ready) begin
            if (wb_beat_q) begin
              state_q <= S_WB_B;
            end else begin
              wb_beat_q <= 1'b1;
            end
          end
        end

        S_WB_B: begin
          if (axi_data_rsp_i.b_valid)
            state_q <= wb_from_flush_q ? S_FLUSH_INV : S_MISS_AR;
        end

        S_MISS_AR: begin
          if (axi_data_rsp_i.ar_ready) begin
            refill_beat_q <= 1'b0;
            state_q       <= S_MISS_R;
          end
        end

        S_MISS_R: begin
          if (axi_data_rsp_i.r_valid) begin
            if (refill_beat_q)
              line_buffer_q[127:64] <= axi_data_rsp_i.r.data;
            else
              line_buffer_q[63:0] <= axi_data_rsp_i.r.data;

            if (axi_data_rsp_i.r.last || refill_beat_q) begin
              state_q <= S_MISS_WRITE;
            end else begin
              refill_beat_q <= 1'b1;
            end
          end
        end

        S_MISS_WRITE: begin
          mshr_valid_q <= 1'b0;
          state_q      <= S_IDLE;
        end

        S_AMO_ISSUE: begin
          if (amo_bus_active) begin
            if (axi_bypass_rsp_i.aw_ready)
              amo_aw_sent_q <= 1'b1;
            if (axi_bypass_rsp_i.w_ready)
              amo_w_sent_q <= 1'b1;

            if ((amo_aw_sent_q || axi_bypass_rsp_i.aw_ready) &&
                (amo_w_sent_q  || axi_bypass_rsp_i.w_ready))
              state_q <= S_AMO_WAIT;
          end
        end

        S_AMO_WAIT: begin
        end

        default: begin
          state_q             <= S_IDLE;
          mshr_valid_q        <= 1'b0;
          flush_lines_valid_q <= 1'b0;
        end
      endcase

      if (amo_bus_active) begin
        if (axi_bypass_rsp_i.b_valid)
          amo_b_seen_q <= 1'b1;

        if (axi_bypass_rsp_i.r_valid) begin
          amo_r_seen_q <= 1'b1;
          amo_result_q <= axi_bypass_rsp_i.r.data;
        end

        if ((amo_b_seen_q || axi_bypass_rsp_i.b_valid) &&
            (amo_r_seen_q || axi_bypass_rsp_i.r_valid))
          state_q <= S_IDLE;
      end
    end
  end

  // Independent single-access bypass adapter.
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      bp_state_q   <= BP_IDLE;
      bp_port_q    <= '0;
      bp_aw_sent_q <= 1'b0;
      bp_w_sent_q  <= 1'b0;
      bp_ar_sent_q <= 1'b0;
    end else begin
      case (bp_state_q)
        BP_IDLE: begin
          if (bp_take) begin
            bp_port_q    <= bypass_sel;
            bp_addr_q    <= miss_req[bypass_sel].addr;
            bp_wdata_q   <= miss_req[bypass_sel].wdata;
            bp_be_q      <= miss_req[bypass_sel].be;
            bp_size_q    <= miss_req[bypass_sel].size;
            bp_aw_sent_q <= 1'b0;
            bp_w_sent_q  <= 1'b0;
            bp_ar_sent_q <= 1'b0;
            bp_state_q   <= miss_req[bypass_sel].we ? BP_WRITE : BP_READ;
          end
        end

        BP_READ: begin
          if (axi_bypass_rsp_i.ar_ready)
            bp_ar_sent_q <= 1'b1;
          if (axi_bypass_rsp_i.r_valid)
            bp_state_q <= BP_IDLE;
        end

        BP_WRITE: begin
          if (axi_bypass_rsp_i.aw_ready)
            bp_aw_sent_q <= 1'b1;
          if (axi_bypass_rsp_i.w_ready)
            bp_w_sent_q <= 1'b1;
          if (axi_bypass_rsp_i.b_valid)
            bp_state_q <= BP_IDLE;
        end

        default: begin
          bp_state_q <= BP_IDLE;
        end
      endcase
    end
  end

endmodule
