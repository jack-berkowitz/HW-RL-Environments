// =============================================================================
// d_ca05 -- miss_handler_arb
// =============================================================================

module miss_handler_arb
  import miss_handler_arb_pkg::*;
#(
    parameter int unsigned NR_PORTS = 4
) (
    input  logic clk,
    input  logic rst_n,

    // ---- flush ---------------------------------------------------------------
    input  logic flush_i,
    output logic flush_ack_o,
    output logic miss_o,
    input  logic busy_i,

    // ---- requesters ----------------------------------------------------------
    input  logic [NR_PORTS-1:0][$bits(miss_req_t)-1:0] miss_req_i,
    output logic [NR_PORTS-1:0]       bypass_gnt_o,
    output logic [NR_PORTS-1:0]       bypass_valid_o,
    output logic [NR_PORTS-1:0][63:0] bypass_data_o,
    output logic [NR_PORTS-1:0]       miss_gnt_o,
    output logic [NR_PORTS-1:0]       active_serving_o,
    output logic [63:0]               critical_word_o,
    output logic                      critical_word_valid_o,

    // ---- MSHR interrogation --------------------------------------------------
    input  logic [NR_PORTS-1:0][55:0] mshr_addr_i,
    output logic [NR_PORTS-1:0]       mshr_addr_matches_o,
    output logic [NR_PORTS-1:0]       mshr_index_matches_o,

    // ---- atomics -------------------------------------------------------------
    input  amo_req_t  amo_req_i,
    output amo_resp_t amo_resp_o,

    // ---- AXI: bypass path ----------------------------------------------------
    output axi_req_t axi_bypass_req_o,
    input  axi_rsp_t axi_bypass_rsp_i,

    // ---- AXI: refill path ----------------------------------------------------
    output axi_req_t axi_data_req_o,
    input  axi_rsp_t axi_data_rsp_i,

    // ---- the cache array -----------------------------------------------------
    output logic [SET_ASSOC-1:0]        req_o,
    output logic [INDEX_WIDTH-1:0]      addr_o,
    output cache_line_t                 data_o,
    output cl_be_t                      be_o,
    input  cache_line_t [SET_ASSOC-1:0] data_i,
    output logic                        we_o
);

  // Cast miss_req_i array for easier member access
  miss_req_t [NR_PORTS-1:0] miss_req;
  for (genvar i = 0; i < NR_PORTS; i++) begin : gen_miss_req
    assign miss_req[i] = miss_req_i[i];
  end

  // Arbitration Logic (Strict lowest-index priority, starving allowed)
  logic has_bypass;
  logic [$clog2(NR_PORTS)-1:0] bypass_idx;
  logic has_refill;
  logic [$clog2(NR_PORTS)-1:0] refill_idx;
  
  always_comb begin
    has_bypass = 0;
    bypass_idx = 0;
    for (int i = NR_PORTS-1; i >= 0; i--) begin
      if (miss_req[i].valid && miss_req[i].bypass) begin
        has_bypass = 1;
        bypass_idx = i[$clog2(NR_PORTS)-1:0];
      end
    end
    
    has_refill = 0;
    refill_idx = 0;
    for (int i = NR_PORTS-1; i >= 0; i--) begin
      if (miss_req[i].valid && !miss_req[i].bypass) begin
        has_refill = 1;
        refill_idx = i[$clog2(NR_PORTS)-1:0];
      end
    end
  end

  // State Enums
  typedef enum logic [4:0] {
    ST_IDLE,
    ST_FLUSH_READ,
    ST_FLUSH_CHECK,
    ST_FLUSH_EVICT_AW,
    ST_FLUSH_EVICT_W0,
    ST_FLUSH_EVICT_W1,
    ST_FLUSH_EVICT_B,
    ST_FLUSH_WRITE_DO,
    ST_REFILL_READ,
    ST_REFILL_CHECK,
    ST_REFILL_EVICT_AW,
    ST_REFILL_EVICT_W0,
    ST_REFILL_EVICT_W1,
    ST_REFILL_EVICT_B,
    ST_REFILL_AR,
    ST_REFILL_R0,
    ST_REFILL_R1,
    ST_REFILL_WRITE,
    ST_AMO_ISSUE
  } state_t;
  state_t state, next_state;

  typedef enum logic [1:0] {
    NORMAL_FLUSH,
    AMO_FLUSH,
    F8_CORNER
  } flush_mode_t;
  flush_mode_t flush_mode;

  typedef enum logic [3:0] {
    ST_BYPASS_IDLE,
    ST_BYPASS_AW,
    ST_BYPASS_W,
    ST_BYPASS_B,
    ST_BYPASS_AR,
    ST_BYPASS_R,
    ST_BYPASS_AMO_AW,
    ST_BYPASS_AMO_W,
    ST_BYPASS_AMO_RESP
  } bypass_state_t;
  bypass_state_t bypass_state, next_bypass_state;

  // Registered states & intermediate variables
  logic in_flight;
  logic [$clog2(NR_PORTS)-1:0] served_req;
  logic [63:0] miss_addr_reg;
  logic [7:0]  flush_idx;
  logic [7:0]  flush_dirty_ways_reg;
  cache_line_t [SET_ASSOC-1:0] flush_data_reg;
  logic [2:0]  victim_idx_reg;
  logic [127:0] refill_data_reg;
  logic amo_issue_req_reg;

  logic [$clog2(NR_PORTS)-1:0] bypass_req_idx_reg;
  logic [63:0] bypass_addr_reg;
  logic [1:0]  bypass_size_reg;
  logic        bypass_we_reg;
  logic [63:0] bypass_wdata_reg;
  logic [7:0]  bypass_be_reg;

  logic amo_b_done, amo_r_done;
  logic [63:0] amo_result_reg;

  // Combinational intermediates
  logic [2:0] evict_idx;
  logic [7:0] flush_dirty_ways_comb;
  logic [SET_ASSOC-1:0] invalid_ways;
  logic [2:0] refill_victim_idx;
  logic [7:0] rem_dirty;
  logic [7:0] amo_strb;
  logic amo_done_pulse;

  axi_req_t data_req, bypass_req;

  // Helper logic evaluation
  always_comb begin
    evict_idx = 0;
    for (int w = SET_ASSOC-1; w >= 0; w--) begin
      if (flush_dirty_ways_reg[w]) evict_idx = w[2:0];
    end
    
    for (int w = 0; w < 8; w++) begin
      flush_dirty_ways_comb[w] = data_i[w].valid & data_i[w].dirty;
    end
    
    for (int w = 0; w < SET_ASSOC; w++) begin
      invalid_ways[w] = !data_i[w].valid;
    end
    
    refill_victim_idx = 0;
    if (invalid_ways != 0) begin
      for (int w = SET_ASSOC-1; w >= 0; w--) begin
        if (invalid_ways[w]) refill_victim_idx = w[2:0];
      end
    end

    if (amo_req_i.size == 2) amo_strb = 8'h0F << amo_req_i.operand_a[2:0];
    else amo_strb = 8'hFF;
  end

  // Miss o
  assign miss_o = (state == ST_IDLE && has_refill);

  // MSHR Outputs
  assign active_serving_o = in_flight ? (1 << served_req) : 0;
  
  always_comb begin
    for (int i = 0; i < NR_PORTS; i++) begin
      // Both match outputs assert concurrently; index is subset of address.
      // Unit currently being served is included.
      mshr_addr_matches_o[i]  = in_flight && (mshr_addr_i[i][55:4] == miss_addr_reg[55:4]);
      mshr_index_matches_o[i] = in_flight && (mshr_addr_i[i][11:4] == miss_addr_reg[11:4]);
    end
  end

  // Sequential assignments
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state <= ST_IDLE;
      flush_mode <= NORMAL_FLUSH;
      in_flight <= 0;
      served_req <= 0;
      amo_issue_req_reg <= 0;
      flush_idx <= 0;
      flush_dirty_ways_reg <= 0;
      victim_idx_reg <= 0;
      
      bypass_state <= ST_BYPASS_IDLE;
      amo_b_done <= 0;
      amo_r_done <= 0;
    end else begin
      state <= next_state;
      bypass_state <= next_bypass_state;

      // --- Main FSM Reg Updates ---
      case (state)
        ST_IDLE: begin
          if (has_refill) begin
            in_flight <= 1;
            served_req <= refill_idx;
            miss_addr_reg <= miss_req[refill_idx].addr;
          end else if (flush_i && amo_req_i.req && !busy_i) begin
            flush_idx <= 0;
            flush_mode <= F8_CORNER;
          end else if (flush_i && !busy_i) begin
            flush_idx <= 0;
            flush_mode <= NORMAL_FLUSH;
          end else if (amo_req_i.req && !busy_i) begin
            flush_idx <= 0;
            flush_mode <= AMO_FLUSH;
          end
        end

        ST_FLUSH_CHECK: begin
          if (flush_dirty_ways_comb != 0) begin
            flush_dirty_ways_reg <= flush_dirty_ways_comb;
            flush_data_reg <= data_i;
          end else begin
            if (flush_idx != 255) flush_idx <= flush_idx + 1;
          end
        end

        ST_FLUSH_EVICT_B: begin
          if (axi_data_rsp_i.b_valid) begin
            flush_dirty_ways_reg[evict_idx] <= 1'b0;
          end
        end

        ST_FLUSH_WRITE_DO: begin
          if (flush_idx != 255) flush_idx <= flush_idx + 1;
        end

        ST_REFILL_CHECK: begin
          victim_idx_reg <= refill_victim_idx;
          if (data_i[refill_victim_idx].valid && data_i[refill_victim_idx].dirty) begin
            flush_data_reg <= data_i;
          end
        end

        ST_REFILL_R0: begin
          if (axi_data_rsp_i.r_valid) refill_data_reg[63:0] <= axi_data_rsp_i.r.data;
        end

        ST_REFILL_R1: begin
          if (axi_data_rsp_i.r_valid) refill_data_reg[127:64] <= axi_data_rsp_i.r.data;
        end

        ST_REFILL_WRITE: begin
          in_flight <= 0;
        end

        ST_AMO_ISSUE: begin
          amo_issue_req_reg <= 1;
          if (amo_done_pulse) amo_issue_req_reg <= 0;
        end
      endcase

      // --- Bypass FSM Reg Updates ---
      case (bypass_state)
        ST_BYPASS_IDLE: begin
          if (has_bypass) begin
            bypass_req_idx_reg <= bypass_idx;
            bypass_addr_reg <= miss_req[bypass_idx].addr;
            bypass_size_reg <= miss_req[bypass_idx].size;
            bypass_we_reg <= miss_req[bypass_idx].we;
            bypass_wdata_reg <= miss_req[bypass_idx].wdata;
            bypass_be_reg <= miss_req[bypass_idx].be;
          end else if (amo_issue_req_reg) begin
            amo_b_done <= 0;
            amo_r_done <= 0;
          end
        end
        ST_BYPASS_AMO_RESP: begin
          if (axi_bypass_rsp_i.b_valid) amo_b_done <= 1;
          if (axi_bypass_rsp_i.r_valid) begin
            amo_r_done <= 1;
            amo_result_reg <= axi_bypass_rsp_i.r.data;
          end
        end
      endcase
    end
  end

  // Combinational next state and output formulation
  always_comb begin
    next_state = state;
    
    req_o  = 0;
    addr_o = 0;
    we_o   = 0;
    be_o   = '0;
    data_o = '0;
    
    flush_ack_o = 0;
    miss_gnt_o  = '0;
    critical_word_o = '0;
    critical_word_valid_o = 0;
    
    data_req = '0;
    data_req.aw.size = 3'b011;
    data_req.aw.burst = 2'b01;
    data_req.ar.size = 3'b011;
    data_req.ar.burst = 2'b01;

    rem_dirty = '0;

    // ----- MAIN FSM (Refills, Flush, AMO-Flush) -----
    case (state)
      ST_IDLE: begin
        if (has_refill) begin
          next_state = ST_REFILL_READ;
        end else if (flush_i && amo_req_i.req && !busy_i) begin
          next_state = ST_FLUSH_READ;
        end else if (flush_i && !busy_i) begin
          next_state = ST_FLUSH_READ;
        end else if (amo_req_i.req && !busy_i) begin
          next_state = ST_FLUSH_READ;
        end
      end

      ST_FLUSH_READ: begin
        req_o = 8'hFF;
        addr_o = flush_idx;
        we_o = 0;
        next_state = ST_FLUSH_CHECK;
      end

      ST_FLUSH_CHECK: begin
        if (flush_dirty_ways_comb != 0) begin
          next_state = ST_FLUSH_EVICT_AW;
        end else begin
          req_o = 8'hFF;
          addr_o = flush_idx;
          we_o = 1;
          be_o.vldrty = 8'hFF;
          be_o.data = '0;
          be_o.tag = '0;
          data_o.valid = 0;
          data_o.dirty = 0;
          
          if (flush_idx == 255) begin
            if (flush_mode == NORMAL_FLUSH) flush_ack_o = 1;
            if (flush_mode == AMO_FLUSH) next_state = ST_AMO_ISSUE;
            else next_state = ST_IDLE; // F8 corner silently returns
          end else begin
            next_state = ST_FLUSH_READ;
          end
        end
      end

      ST_FLUSH_EVICT_AW: begin
        data_req.aw.valid = 1;
        data_req.aw.addr  = {flush_data_reg[evict_idx].tag, flush_idx, 4'b0000};
        data_req.aw.len   = 1;
        if (axi_data_rsp_i.aw_ready) next_state = ST_FLUSH_EVICT_W0;
      end
      
      ST_FLUSH_EVICT_W0: begin
        data_req.w.valid = 1;
        data_req.w.data  = flush_data_reg[evict_idx].data[63:0];
        data_req.w.last  = 0;
        if (axi_data_rsp_i.w_ready) next_state = ST_FLUSH_EVICT_W1;
      end
      
      ST_FLUSH_EVICT_W1: begin
        data_req.w.valid = 1;
        data_req.w.data  = flush_data_reg[evict_idx].data[127:64];
        data_req.w.last  = 1;
        if (axi_data_rsp_i.w_ready) next_state = ST_FLUSH_EVICT_B;
      end
      
      ST_FLUSH_EVICT_B: begin
        data_req.b_ready = 1;
        if (axi_data_rsp_i.b_valid) begin
          rem_dirty = flush_dirty_ways_reg;
          rem_dirty[evict_idx] = 1'b0;
          if (rem_dirty == 0) next_state = ST_FLUSH_WRITE_DO;
          else next_state = ST_FLUSH_EVICT_AW;
        end
      end

      ST_FLUSH_WRITE_DO: begin
        req_o = 8'hFF;
        addr_o = flush_idx;
        we_o = 1;
        be_o.vldrty = 8'hFF;
        be_o.data = '0;
        be_o.tag = '0;
        data_o.valid = 0;
        data_o.dirty = 0;
        
        if (flush_idx == 255) begin
          if (flush_mode == NORMAL_FLUSH) flush_ack_o = 1;
          if (flush_mode == AMO_FLUSH) next_state = ST_AMO_ISSUE;
          else next_state = ST_IDLE; // F8 corner
        end else begin
          next_state = ST_FLUSH_READ;
        end
      end

      ST_REFILL_READ: begin
        req_o = 8'hFF;
        addr_o = miss_addr_reg[15:4];
        we_o = 0;
        next_state = ST_REFILL_CHECK;
      end

      ST_REFILL_CHECK: begin
        if (data_i[refill_victim_idx].valid && data_i[refill_victim_idx].dirty) begin
          next_state = ST_REFILL_EVICT_AW;
        end else begin
          next_state = ST_REFILL_AR;
        end
      end

      ST_REFILL_EVICT_AW: begin
        data_req.aw.valid = 1;
        data_req.aw.addr  = {flush_data_reg[victim_idx_reg].tag, miss_addr_reg[15:4], 4'b0000};
        data_req.aw.len   = 1;
        if (axi_data_rsp_i.aw_ready) next_state = ST_REFILL_EVICT_W0;
      end
      
      ST_REFILL_EVICT_W0: begin
        data_req.w.valid = 1;
        data_req.w.data  = flush_data_reg[victim_idx_reg].data[63:0];
        data_req.w.last  = 0;
        if (axi_data_rsp_i.w_ready) next_state = ST_REFILL_EVICT_W1;
      end
      
      ST_REFILL_EVICT_W1: begin
        data_req.w.valid = 1;
        data_req.w.data  = flush_data_reg[victim_idx_reg].data[127:64];
        data_req.w.last  = 1;
        if (axi_data_rsp_i.w_ready) next_state = ST_REFILL_EVICT_B;
      end
      
      ST_REFILL_EVICT_B: begin
        data_req.b_ready = 1;
        if (axi_data_rsp_i.b_valid) next_state = ST_REFILL_AR;
      end

      ST_REFILL_AR: begin
        data_req.ar.valid = 1;
        data_req.ar.addr = {miss_addr_reg[63:4], 4'b0000};
        data_req.ar.len = 1;
        if (axi_data_rsp_i.ar_ready) next_state = ST_REFILL_R0;
      end

      ST_REFILL_R0: begin
        data_req.r_ready = 1;
        critical_word_valid_o = axi_data_rsp_i.r_valid && (miss_addr_reg[3] == 0);
        critical_word_o = axi_data_rsp_i.r.data;
        if (axi_data_rsp_i.r_valid) next_state = ST_REFILL_R1;
      end

      ST_REFILL_R1: begin
        data_req.r_ready = 1;
        critical_word_valid_o = axi_data_rsp_i.r_valid && (miss_addr_reg[3] == 1);
        critical_word_o = axi_data_rsp_i.r.data;
        if (axi_data_rsp_i.r_valid) next_state = ST_REFILL_WRITE;
      end

      ST_REFILL_WRITE: begin
        req_o = (1 << victim_idx_reg);
        addr_o = miss_addr_reg[15:4];
        we_o = 1;
        be_o.vldrty = (1 << victim_idx_reg);
        be_o.data = '1;
        be_o.tag = '1;
        data_o.valid = 1;
        data_o.dirty = 0;
        data_o.tag = miss_addr_reg[55:12];
        data_o.data = refill_data_reg;
        
        miss_gnt_o[served_req] = 1;
        next_state = ST_IDLE;
      end

      ST_AMO_ISSUE: begin
        if (amo_done_pulse) next_state = ST_IDLE;
      end
    endcase
  end

  // ----- BYPASS FSM (Uncached & Atomics) -----
  always_comb begin
    next_bypass_state = bypass_state;
    bypass_req = '0;
    bypass_req.aw.burst = 2'b01;
    bypass_req.ar.burst = 2'b01;
    
    bypass_gnt_o = '0;
    bypass_valid_o = '0;
    bypass_data_o = '0;
    
    amo_done_pulse = 0;
    amo_resp_o.ack = 0;
    amo_resp_o.result = '0;

    case (bypass_state)
      ST_BYPASS_IDLE: begin
        if (has_bypass) begin
          bypass_gnt_o[bypass_idx] = 1;
          if (miss_req[bypass_idx].we) next_bypass_state = ST_BYPASS_AW;
          else next_bypass_state = ST_BYPASS_AR;
        end else if (amo_issue_req_reg) begin
          next_bypass_state = ST_BYPASS_AMO_AW;
        end
      end
      
      ST_BYPASS_AW: begin
        bypass_req.aw.valid = 1;
        bypass_req.aw.addr = bypass_addr_reg;
        bypass_req.aw.size = bypass_size_reg;
        bypass_req.aw.len = 0;
        bypass_req.aw.atop = 0;
        if (axi_bypass_rsp_i.aw_ready) next_bypass_state = ST_BYPASS_W;
      end
      
      ST_BYPASS_W: begin
        bypass_req.w.valid = 1;
        bypass_req.w.data = bypass_wdata_reg;
        bypass_req.w.strb = bypass_be_reg;
        bypass_req.w.last = 1;
        if (axi_bypass_rsp_i.w_ready) next_bypass_state = ST_BYPASS_B;
      end
      
      ST_BYPASS_B: begin
        bypass_req.b_ready = 1;
        if (axi_bypass_rsp_i.b_valid) begin
          bypass_valid_o[bypass_req_idx_reg] = 1;
          next_bypass_state = ST_BYPASS_IDLE;
        end
      end

      ST_BYPASS_AR: begin
        bypass_req.ar.valid = 1;
        bypass_req.ar.addr = bypass_addr_reg;
        bypass_req.ar.size = bypass_size_reg;
        bypass_req.ar.len = 0;
        if (axi_bypass_rsp_i.ar_ready) next_bypass_state = ST_BYPASS_R;
      end

      ST_BYPASS_R: begin
        bypass_req.r_ready = 1;
        if (axi_bypass_rsp_i.r_valid) begin
          bypass_valid_o[bypass_req_idx_reg] = 1;
          bypass_data_o[bypass_req_idx_reg] = axi_bypass_rsp_i.r.data;
          next_bypass_state = ST_BYPASS_IDLE;
        end
      end

      ST_BYPASS_AMO_AW: begin
        bypass_req.aw.valid = 1;
        bypass_req.aw.addr = amo_req_i.operand_a;
        bypass_req.aw.size = amo_req_i.size;
        bypass_req.aw.len = 0;
        bypass_req.aw.atop = {2'b00, amo_req_i.amo_op};
        if (axi_bypass_rsp_i.aw_ready) next_bypass_state = ST_BYPASS_AMO_W;
      end

      ST_BYPASS_AMO_W: begin
        bypass_req.w.valid = 1;
        bypass_req.w.data = amo_req_i.operand_b;
        bypass_req.w.strb = amo_strb;
        bypass_req.w.last = 1;
        if (axi_bypass_rsp_i.w_ready) next_bypass_state = ST_BYPASS_AMO_RESP;
      end

      ST_BYPASS_AMO_RESP: begin
        bypass_req.b_ready = !amo_b_done;
        bypass_req.r_ready = !amo_r_done;
        
        if ((axi_bypass_rsp_i.b_valid || amo_b_done) && 
            (axi_bypass_rsp_i.r_valid || amo_r_done)) begin
          amo_done_pulse = 1;
          amo_resp_o.ack = 1;
          amo_resp_o.result = (axi_bypass_rsp_i.r_valid) ? axi_bypass_rsp_i.r.data : amo_result_reg;
          next_bypass_state = ST_BYPASS_IDLE;
        end
      end
    endcase
  end

  // Tie off physical interfaces
  assign axi_data_req_o = data_req;
  assign axi_bypass_req_o = bypass_req;

endmodule