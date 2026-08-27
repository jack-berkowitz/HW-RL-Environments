// =============================================================================
// miss_handler_arb.sv
// 
// Synthesizable multi-requester cache miss handler supporting strict 
// lowest-index arbitration, MSHR tracking, array flushing, and atomics.
// =============================================================================

import miss_handler_arb_pkg::*;

module miss_handler_arb #(
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

    typedef enum logic [3:0] {
        IDLE,
        REFILL_AR,
        REFILL_R,
        REFILL_WRITE,
        BYPASS_REQ,
        BYPASS_WAIT,
        FLUSH_READ,
        FLUSH_WRITE,
        FLUSH_ACK,
        AMO_REQ,
        AMO_WAIT
    } state_e;

    // Registers
    state_e state_q, state_d;
    logic [7:0] flush_cnt_q, flush_cnt_d;
    logic amo_flush_q, amo_flush_d;
    logic mshr_valid_q, mshr_valid_d;
    logic [$clog2(NR_PORTS)-1:0] mshr_port_q, mshr_port_d;
    logic [$clog2(NR_PORTS)-1:0] bypass_port_q, bypass_port_d;
    miss_req_t miss_req_q, miss_req_d;
    amo_req_t amo_req_q, amo_req_d;
    logic [127:0] line_q, line_d;
    logic beat_cnt_q, beat_cnt_d;
    
    logic aw_sent_q, aw_sent_d;
    logic w_sent_q, w_sent_d;
    logic amo_b_done_q, amo_b_done_d;
    logic amo_r_done_q, amo_r_done_d;
    logic [63:0] amo_r_data_q, amo_r_data_d;

    // Arbitration logic variables
    logic miss_val;
    logic bypass_val;
    logic [$clog2(NR_PORTS)-1:0] miss_idx;
    logic [$clog2(NR_PORTS)-1:0] bypass_idx;
    integer i, j;

    always_comb begin
        miss_val = 0;
        miss_idx = 0;
        bypass_val = 0;
        bypass_idx = 0;
        
        // F2: Strict lowest-index priority (starves higher ports)
        for (i = NR_PORTS - 1; i >= 0; i--) begin
            if (miss_req_i[i].valid) begin
                if (miss_req_i[i].bypass) begin
                    bypass_val = 1'b1;
                    bypass_idx = i[$clog2(NR_PORTS)-1:0];
                end else begin
                    miss_val = 1'b1;
                    miss_idx = i[$clog2(NR_PORTS)-1:0];
                end
            end
        end
    end

    // FSM and Data Path Logic
    always_comb begin
        state_d       = state_q;
        flush_cnt_d   = flush_cnt_q;
        amo_flush_d   = amo_flush_q;
        mshr_valid_d  = mshr_valid_q;
        mshr_port_d   = mshr_port_q;
        bypass_port_d = bypass_port_q;
        miss_req_d    = miss_req_q;
        amo_req_d     = amo_req_q;
        line_d        = line_q;
        beat_cnt_d    = beat_cnt_q;
        aw_sent_d     = aw_sent_q;
        w_sent_d      = w_sent_q;
        amo_b_done_d  = amo_b_done_q;
        amo_r_done_d  = amo_r_done_q;
        amo_r_data_d  = amo_r_data_q;

        miss_gnt_o            = '0;
        bypass_gnt_o          = '0;
        bypass_valid_o        = '0;
        bypass_data_o         = '0;
        flush_ack_o           = 1'b0;
        miss_o                = 1'b0;
        amo_resp_o.ack        = 1'b0;
        amo_resp_o.result     = '0;

        req_o                 = '0;
        addr_o                = '0;
        we_o                  = 1'b0;
        be_o                  = '0;
        data_o                = '0;

        axi_bypass_req_o      = '0;
        axi_data_req_o        = '0;

        // Default critical word logic
        critical_word_o       = axi_data_rsp_i.r.data;
        critical_word_valid_o = (state_q == REFILL_R) && axi_data_rsp_i.r_valid && (miss_req_q.addr[3] == beat_cnt_q);

        case (state_q)
            IDLE: begin
                if (miss_val) begin
                    state_d      = REFILL_AR;
                    mshr_valid_d = 1'b1;
                    mshr_port_d  = miss_idx;
                    miss_req_d   = miss_req_i[miss_idx];
                    miss_o       = 1'b1;
                end else if (bypass_val) begin
                    state_d      = BYPASS_REQ;
                    bypass_port_d= bypass_idx;
                    miss_req_d   = miss_req_i[bypass_idx];
                    aw_sent_d    = 1'b0;
                    w_sent_d     = 1'b0;
                    bypass_gnt_o[bypass_idx] = 1'b1;
                end else if (amo_req_i.req && !busy_i) begin
                    state_d      = FLUSH_READ;
                    amo_req_d    = amo_req_i;
                    amo_flush_d  = 1'b1;
                    flush_cnt_d  = '0;
                end else if (flush_i && !busy_i) begin
                    state_d      = FLUSH_READ;
                    amo_flush_d  = 1'b0;
                    flush_cnt_d  = '0;
                end
            end

            REFILL_AR: begin
                axi_data_req_o.ar_valid = 1'b1;
                axi_data_req_o.ar.addr  = {miss_req_q.addr[63:4], 4'b0000};
                axi_data_req_o.ar.len   = 8'd1;
                axi_data_req_o.ar.size  = 3'd3;
                axi_data_req_o.ar.burst = 2'd1;
                
                if (axi_data_rsp_i.ar_ready) begin
                    state_d    = REFILL_R;
                    beat_cnt_d = 1'b0;
                end
            end

            REFILL_R: begin
                axi_data_req_o.r_ready = 1'b1;
                if (axi_data_rsp_i.r_valid) begin
                    if (beat_cnt_q == 1'b0) begin
                        line_d[63:0] = axi_data_rsp_i.r.data;
                        beat_cnt_d   = 1'b1;
                    end else begin
                        line_d[127:64] = axi_data_rsp_i.r.data;
                    end
                    if (axi_data_rsp_i.r.last) begin
                        state_d = REFILL_WRITE;
                    end
                end
            end

            REFILL_WRITE: begin
                req_o        = miss_req_q.be;
                we_o         = 1'b1;
                addr_o       = miss_req_q.addr[15:4];
                data_o.tag   = miss_req_q.addr[59:16];
                data_o.data  = line_q;
                data_o.valid = 1'b1;
                data_o.dirty = 1'b0;
                be_o.tag     = '1;
                be_o.data    = '1;
                be_o.vldrty  = miss_req_q.be;

                miss_gnt_o[mshr_port_q] = 1'b1;
                mshr_valid_d = 1'b0;
                state_d      = IDLE;
            end

            BYPASS_REQ: begin
                if (miss_req_q.we) begin
                    axi_bypass_req_o.aw_valid = !aw_sent_q;
                    axi_bypass_req_o.aw.addr  = miss_req_q.addr;
                    axi_bypass_req_o.aw.size  = miss_req_q.size;
                    axi_bypass_req_o.aw.burst = 2'd1;
                    
                    axi_bypass_req_o.w_valid  = !w_sent_q;
                    axi_bypass_req_o.w.data   = miss_req_q.wdata;
                    axi_bypass_req_o.w.strb   = miss_req_q.be;
                    axi_bypass_req_o.w.last   = 1'b1;
                    
                    if (axi_bypass_rsp_i.aw_ready) aw_sent_d = 1'b1;
                    if (axi_bypass_rsp_i.w_ready)  w_sent_d  = 1'b1;
                    
                    if ((aw_sent_q || axi_bypass_rsp_i.aw_ready) && (w_sent_q || axi_bypass_rsp_i.w_ready)) begin
                        state_d = BYPASS_WAIT;
                    end
                end else begin
                    axi_bypass_req_o.ar_valid = 1'b1;
                    axi_bypass_req_o.ar.addr  = miss_req_q.addr;
                    axi_bypass_req_o.ar.size  = miss_req_q.size;
                    axi_bypass_req_o.ar.burst = 2'd1;
                    
                    if (axi_bypass_rsp_i.ar_ready) begin
                        state_d = BYPASS_WAIT;
                    end
                end
            end

            BYPASS_WAIT: begin
                if (miss_req_q.we) begin
                    axi_bypass_req_o.b_ready = 1'b1;
                    if (axi_bypass_rsp_i.b_valid) begin
                        bypass_valid_o[bypass_port_q] = 1'b1;
                        state_d = IDLE;
                    end
                end else begin
                    axi_bypass_req_o.r_ready = 1'b1;
                    if (axi_bypass_rsp_i.r_valid) begin
                        bypass_valid_o[bypass_port_q] = 1'b1;
                        bypass_data_o[bypass_port_q]  = axi_bypass_rsp_i.r.data;
                        state_d = IDLE;
                    end
                end
            end

            FLUSH_READ: begin
                req_o  = '1;
                we_o   = 1'b0;
                addr_o = { {(INDEX_WIDTH-8){1'b0}}, flush_cnt_q };
                state_d = FLUSH_WRITE;
            end

            FLUSH_WRITE: begin
                req_o        = '1;
                we_o         = 1'b1;
                addr_o       = { {(INDEX_WIDTH-8){1'b0}}, flush_cnt_q };
                data_o.valid = 1'b0;
                data_o.dirty = 1'b0;
                be_o.vldrty  = '1;
                
                flush_cnt_d  = flush_cnt_q + 8'd1;
                
                if (flush_cnt_q == 8'hFF) begin
                    if (amo_flush_q) begin
                        state_d      = AMO_REQ;
                        aw_sent_d    = 1'b0;
                        w_sent_d     = 1'b0;
                        amo_b_done_d = 1'b0;
                        amo_r_done_d = 1'b0;
                    end else begin
                        state_d = FLUSH_ACK;
                    end
                end else begin
                    state_d = FLUSH_READ;
                end
            end

            FLUSH_ACK: begin
                flush_ack_o = 1'b1;
                state_d     = IDLE;
            end

            AMO_REQ: begin
                axi_bypass_req_o.aw_valid = !aw_sent_q;
                axi_bypass_req_o.aw.addr  = amo_req_q.operand_a;
                axi_bypass_req_o.aw.size  = amo_req_q.size;
                axi_bypass_req_o.aw.burst = 2'd1;
                axi_bypass_req_o.aw.atop  = {2'b00, amo_req_q.amo_op};
                
                axi_bypass_req_o.w_valid  = !w_sent_q;
                axi_bypass_req_o.w.data   = amo_req_q.operand_b;
                axi_bypass_req_o.w.strb   = ((16'h1 << (1 << amo_req_q.size)) - 1) << amo_req_q.operand_a[2:0];
                axi_bypass_req_o.w.last   = 1'b1;
                
                if (axi_bypass_rsp_i.aw_ready) aw_sent_d = 1'b1;
                if (axi_bypass_rsp_i.w_ready)  w_sent_d  = 1'b1;
                
                if ((aw_sent_q || axi_bypass_rsp_i.aw_ready) && (w_sent_q || axi_bypass_rsp_i.w_ready)) begin
                    state_d = AMO_WAIT;
                end
            end

            AMO_WAIT: begin
                axi_bypass_req_o.b_ready = 1'b1;
                axi_bypass_req_o.r_ready = 1'b1;
                
                if (axi_bypass_rsp_i.b_valid) amo_b_done_d = 1'b1;
                if (axi_bypass_rsp_i.r_valid) begin
                    amo_r_done_d = 1'b1;
                    amo_r_data_d = axi_bypass_rsp_i.r.data;
                end
                
                if (amo_b_done_d && amo_r_done_d) begin
                    amo_resp_o.ack    = 1'b1;
                    amo_resp_o.result = (axi_bypass_rsp_i.r_valid) ? axi_bypass_rsp_i.r.data : amo_r_data_q;
                    state_d           = IDLE;
                end
            end

            default: state_d = IDLE;
        endcase
    end

    // MSHR Interrogation Outputs
    always_comb begin
        mshr_addr_matches_o  = '0;
        mshr_index_matches_o = '0;
        if (mshr_valid_q) begin
            for (j = 0; j < NR_PORTS; j++) begin
                if (mshr_addr_i[j][55:4] == miss_req_q.addr[55:4]) begin
                    mshr_addr_matches_o[j]  = 1'b1;
                    mshr_index_matches_o[j] = 1'b1;
                end else if (mshr_addr_i[j][11:4] == miss_req_q.addr[11:4]) begin
                    mshr_index_matches_o[j] = 1'b1;
                end
            end
        end
    end

    // Active Serving Output Tracker
    always_comb begin
        active_serving_o = '0;
        if (mshr_valid_q) begin
            active_serving_o[mshr_port_q] = 1'b1;
        end
        if (state_q == BYPASS_REQ || state_q == BYPASS_WAIT) begin
            active_serving_o[bypass_port_q] = 1'b1;
        end
    end

    // State Updates
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_q       <= IDLE;
            mshr_valid_q  <= 1'b0;
            flush_cnt_q   <= '0;
            amo_flush_q   <= 1'b0;
            mshr_port_q   <= '0;
            bypass_port_q <= '0;
            miss_req_q    <= '0;
            amo_req_q     <= '0;
            line_q        <= '0;
            beat_cnt_q    <= 1'b0;
            aw_sent_q     <= 1'b0;
            w_sent_q      <= 1'b0;
            amo_b_done_q  <= 1'b0;
            amo_r_done_q  <= 1'b0;
            amo_r_data_q  <= '0;
        end else begin
            state_q       <= state_d;
            mshr_valid_q  <= mshr_valid_d;
            flush_cnt_q   <= flush_cnt_d;
            amo_flush_q   <= amo_flush_d;
            mshr_port_q   <= mshr_port_d;
            bypass_port_q <= bypass_port_d;
            miss_req_q    <= miss_req_d;
            amo_req_q     <= amo_req_d;
            line_q        <= line_d;
            beat_cnt_q    <= beat_cnt_d;
            aw_sent_q     <= aw_sent_d;
            w_sent_q      <= w_sent_d;
            amo_b_done_q  <= amo_b_done_d;
            amo_r_done_q  <= amo_r_done_d;
            amo_r_data_q  <= amo_r_data_d;
        end
    end

endmodule