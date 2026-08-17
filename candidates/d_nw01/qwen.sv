// =============================================================================
// axi4_xbar.sv -- AXI4 Crossbar Implementation
// =============================================================================

module rr_arbiter #(parameter int N = 4) (
    input  logic             clk,
    input  logic             rst_n,
    input  logic [N-1:0]     req,
    output logic [N-1:0]     gnt
);
    logic [$clog2(N)-1:0] last_gnt;
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            last_gnt <= 0;
        end else if (|gnt && |req) begin
            for (int i = 1; i < N; i++) begin
                int idx = (last_gnt + i) % N;
                if (req[idx]) begin
                    last_gnt <= idx;
                    break;
                end
            end
        end
    end
    
    always_comb begin
        gnt = 0;
        for (int i = 0; i < N; i++) begin
            int idx = (last_gnt + 1 + i) % N;
            if (req[idx]) begin
                gnt[idx] = 1;
                break;
            end
        end
        // Fallback to ensure grant if req is high but loop missed (safety)
        if (gnt == 0 && req != 0) begin
            for (int i = 0; i < N; i++) begin
                if (req[i]) begin
                    gnt[i] = 1;
                    break;
                end
            end
        end
    end
endmodule

module axi4_xbar
  import axi4_xbar_pkg::*;
#(
    parameter int NUM_MST       = 2,
    parameter int NUM_SLV       = 2,
    parameter int MAX_TRANS     = 8,
    parameter int MAX_BURST_LEN = 3
) (
    input  logic clk,
    input  logic rst_n,

    input  slv_req_t  [NUM_MST-1:0] mst_req,
    output slv_resp_t [NUM_MST-1:0] mst_resp,

    output mst_req_t  [NUM_SLV-1:0] slv_req,
    input  mst_resp_t [NUM_SLV-1:0] slv_resp,

    input  xbar_rule_t [NUM_SLV-1:0] addr_map
);

    // =========================================================================
    // Address Decode
    // =========================================================================
    logic is_decerr_aw[NUM_MST];
    logic [$clog2(NUM_SLV)-1:0] dest_port_aw[NUM_MST];
    logic is_decerr_ar[NUM_MST];
    logic [$clog2(NUM_SLV)-1:0] dest_port_ar[NUM_MST];

    always_comb begin
        for (int i = 0; i < NUM_MST; i++) begin
            is_decerr_aw[i] = 1;
            dest_port_aw[i] = 0;
            is_decerr_ar[i] = 1;
            dest_port_ar[i] = 0;
            for (int k = 0; k < NUM_SLV; k++) begin
                if (mst_req[i].aw.addr >= addr_map[k].start_addr && 
                    mst_req[i].aw.addr < addr_map[k].end_addr) begin
                    is_decerr_aw[i] = 0;
                    dest_port_aw[i] = addr_map[k].mst_port[$clog2(NUM_SLV)-1:0];
                end
                if (mst_req[i].ar.addr >= addr_map[k].start_addr && 
                    mst_req[i].ar.addr < addr_map[k].end_addr) begin
                    is_decerr_ar[i] = 0;
                    dest_port_ar[i] = addr_map[k].mst_port[$clog2(NUM_SLV)-1:0];
                end
            end
        end
    end

    // =========================================================================
    // Outstanding ID Tracking (Per-ID Ordering)
    // =========================================================================
    logic [15:0] outstanding_ids[NUM_MST];
    logic clear_id[NUM_MST];
    slv_id_t clear_id_val[NUM_MST];

    always_comb begin
        for (int i = 0; i < NUM_MST; i++) begin
            clear_id[i] = 0;
            clear_id_val[i] = 0;
            
            // Valid Write response complete
            if (mst_resp[i].b_valid && mst_resp[i].b_ready && decerr_w_state[i] != DW_WAIT_B) begin
                clear_id[i] = 1;
                clear_id_val[i] = mst_resp[i].b.id[SLV_ID_W-1:0];
            end
            // Valid Read response complete
            if (mst_resp[i].r_valid && mst_resp[i].r_ready && mst_resp[i].r.last && decerr_r_state[i] != DR_WAIT_R) begin
                clear_id[i] = 1;
                clear_id_val[i] = mst_resp[i].r.id[SLV_ID_W-1:0];
            end
            // DECERR Write response complete
            if (decerr_w_state[i] == DW_WAIT_B && mst_resp[i].b_ready) begin
                clear_id[i] = 1;
                clear_id_val[i] = decerr_aw_fifo[i][decerr_aw_rd_ptr[i]].id;
            end
            // DECERR Read response complete
            if (decerr_r_state[i] == DR_WAIT_R && mst_resp[i].r_ready && decerr_r_beats_left[i] == 0) begin
                clear_id[i] = 1;
                clear_id_val[i] = decerr_ar_fifo[i][decerr_ar_rd_ptr[i]].id;
            end
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int i = 0; i < NUM_MST; i++) outstanding_ids[i] <= 0;
        end else begin
            for (int i = 0; i < NUM_MST; i++) begin
                if (mst_req[i].aw_valid && mst_resp[i].aw_ready && !is_decerr_aw[i])
                    outstanding_ids[i][mst_req[i].aw.id] <= 1;
                if (mst_req[i].ar_valid && mst_resp[i].ar_ready && !is_decerr_ar[i])
                    outstanding_ids[i][mst_req[i].ar.id] <= 1;
                
                if (clear_id[i])
                    outstanding_ids[i][clear_id_val[i]] <= 0;
            end
        end
    end

    // =========================================================================
    // DECERR Handling State Machines & FIFOs
    // =========================================================================
    typedef struct packed {
        logic [7:0]   len;
        slv_id_t      id;
        user_t        user;
    } decerr_aw_t;

    typedef struct packed {
        logic [7:0]   len;
        slv_id_t      id;
        user_t        user;
    } decerr_ar_t;

    decerr_aw_t decerr_aw_fifo[NUM_MST][8];
    logic [2:0] decerr_aw_wr_ptr[NUM_MST];
    logic [2:0] decerr_aw_rd_ptr[NUM_MST];
    logic [2:0] decerr_aw_count[NUM_MST];

    decerr_ar_t decerr_ar_fifo[NUM_MST][8];
    logic [2:0] decerr_ar_wr_ptr[NUM_MST];
    logic [2:0] decerr_ar_rd_ptr[NUM_MST];
    logic [2:0] decerr_ar_count[NUM_MST];

    typedef enum logic [1:0] { DW_IDLE, DW_WAIT_W, DW_WAIT_B } decerr_w_state_t;
    decerr_w_state_t decerr_w_state[NUM_MST];
    logic [7:0] decerr_w_beats_left[NUM_MST];

    typedef enum logic [1:0] { DR_IDLE, DR_WAIT_R } decerr_r_state_t;
    decerr_r_state_t decerr_r_state[NUM_MST];
    logic [7:0] decerr_r_beats_left[NUM_MST];

    for (genvar i = 0; i < NUM_MST; i++) begin
        // DECERR AW FIFO Push
        always_ff @(posedge clk or negedge rst_n) begin
            if (!rst_n) begin
                decerr_aw_wr_ptr[i] <= 0;
                decerr_aw_count[i] <= 0;
            end else if (mst_req[i].aw_valid && mst_resp[i].aw_ready && is_decerr_aw[i]) begin
                decerr_aw_fifo[i][decerr_aw_wr_ptr[i]] <= '{len: mst_req[i].aw.len, id: mst_req[i].aw.id, user: mst_req[i].aw.user};
                decerr_aw_wr_ptr[i] <= decerr_aw_wr_ptr[i] + 1;
                decerr_aw_count[i] <= decerr_aw_count[i] + 1;
            end
        end

        // DECERR AW FIFO Pop
        always_ff @(posedge clk or negedge rst_n) begin
            if (!rst_n) begin
                decerr_aw_rd_ptr[i] <= 0;
            end else if (decerr_w_state[i] == DW_WAIT_B && mst_resp[i].b_ready) begin
                decerr_aw_rd_ptr[i] <= decerr_aw_rd_ptr[i] + 1;
                decerr_aw_count[i] <= decerr_aw_count[i] - 1;
            end
        end

        // DECERR Write State Machine
        always_ff @(posedge clk or negedge rst_n) begin
            if (!rst_n) begin
                decerr_w_state[i] <= DW_IDLE;
                decerr_w_beats_left[i] <= 0;
            end else begin
                case (decerr_w_state[i])
                    DW_IDLE: begin
                        if (decerr_aw_count[i] > 0) begin
                            decerr_w_state[i] <= DW_WAIT_W;
                            decerr_w_beats_left[i] <= decerr_aw_fifo[i][decerr_aw_rd_ptr[i]].len;
                        end
                    end
                    DW_WAIT_W: begin
                        if (mst_req[i].w_valid && mst_resp[i].w_ready) begin
                            if (decerr_w_beats_left[i] == 0 && mst_req[i].w.last) begin
                                decerr_w_state[i] <= DW_WAIT_B;
                            end else begin
                                decerr_w_beats_left[i] <= decerr_w_beats_left[i] - 1;
                            end
                        end
                    end
                    DW_WAIT_B: begin
                        if (mst_resp[i].b_ready) begin
                            decerr_w_state[i] <= DW_IDLE;
                        end
                    end
                endcase
            end
        end

        // DECERR AR FIFO Push
        always_ff @(posedge clk or negedge rst_n) begin
            if (!rst_n) begin
                decerr_ar_wr_ptr[i] <= 0;
                decerr_ar_count[i] <= 0;
            end else if (mst_req[i].ar_valid && mst_resp[i].ar_ready && is_decerr_ar[i]) begin
                decerr_ar_fifo[i][decerr_ar_wr_ptr[i]] <= '{len: mst_req[i].ar.len, id: mst_req[i].ar.id, user: mst_req[i].ar.user};
                decerr_ar_wr_ptr[i] <= decerr_ar_wr_ptr[i] + 1;
                decerr_ar_count[i] <= decerr_ar_count[i] + 1;
            end
        end

        // DECERR AR FIFO Pop
        always_ff @(posedge clk or negedge rst_n) begin
            if (!rst_n) begin
                decerr_ar_rd_ptr[i] <= 0;
            end else if (decerr_r_state[i] == DR_WAIT_R && mst_resp[i].r_ready && decerr_r_beats_left[i] == 0) begin
                decerr_ar_rd_ptr[i] <= decerr_ar_rd_ptr[i] + 1;
                decerr_ar_count[i] <= decerr_ar_count[i] - 1;
            end
        end

        // DECERR Read State Machine
        always_ff @(posedge clk or negedge rst_n) begin
            if (!rst_n) begin
                decerr_r_state[i] <= DR_IDLE;
                decerr_r_beats_left[i] <= 0;
            end else begin
                case (decerr_r_state[i])
                    DR_IDLE: begin
                        if (decerr_ar_count[i] > 0) begin
                            decerr_r_state[i] <= DR_WAIT_R;
                            decerr_r_beats_left[i] <= decerr_ar_fifo[i][decerr_ar_rd_ptr[i]].len;
                        end
                    end
                    DR_WAIT_R: begin
                        if (mst_resp[i].r_valid && mst_resp[i].r_ready) begin
                            if (decerr_r_beats_left[i] == 0) begin
                                decerr_r_state[i] <= DR_IDLE;
                            end else begin
                                decerr_r_beats_left[i] <= decerr_r_beats_left[i] - 1;
                            end
                        end
                    end
                endcase
            end
        end
    end

    // =========================================================================
    // W Destination Tracking FIFO
    // =========================================================================
    logic [$clog2(NUM_SLV)-1:0] w_dest_fifo[NUM_MST][8];
    logic [2:0] w_dest_wr_ptr[NUM_MST];
    logic [2:0] w_dest_rd_ptr[NUM_MST];
    logic [2:0] w_dest_count[NUM_MST];

    for (genvar i = 0; i < NUM_MST; i++) begin
        always_ff @(posedge clk or negedge rst_n) begin
            if (!rst_n) begin
                w_dest_wr_ptr[i] <= 0;
                w_dest_count[i] <= 0;
            end else if (mst_req[i].aw_valid && mst_resp[i].aw_ready && !is_decerr_aw[i]) begin
                w_dest_fifo[i][w_dest_wr_ptr[i]] <= dest_port_aw[i];
                w_dest_wr_ptr[i] <= w_dest_wr_ptr[i] + 1;
                w_dest_count[i] <= w_dest_count[i] + 1;
            end
        end

        always_ff @(posedge clk or negedge rst_n) begin
            if (!rst_n) begin
                w_dest_rd_ptr[i] <= 0;
            end else if (mst_req[i].w_valid && mst_resp[i].w_ready && mst_req[i].w.last) begin
                w_dest_rd_ptr[i] <= w_dest_rd_ptr[i] + 1;
                w_dest_count[i] <= w_dest_count[i] - 1;
            end
        end
    end

    // =========================================================================
    // Request Arbitration (Master to Slave)
    // =========================================================================
    logic [NUM_MST-1:0] aw_req[NUM_SLV];
    logic [NUM_MST-1:0] aw_gnt[NUM_SLV];
    logic [NUM_MST-1:0] ar_req[NUM_SLV];
    logic [NUM_MST-1:0] ar_gnt[NUM_SLV];
    logic [NUM_MST-1:0] w_req[NUM_SLV];
    logic [NUM_MST-1:0] w_gnt[NUM_SLV];

    for (genvar j = 0; j < NUM_SLV; j++) begin
        for (genvar i = 0; i < NUM_MST; i++) begin
            assign aw_req[j][i] = mst_req[i].aw_valid && !is_decerr_aw[i] && !outstanding_ids[i][mst_req[i].aw.id];
            assign ar_req[j][i] = mst_req[i].ar_valid && !is_decerr_ar[i] && !outstanding_ids[i][mst_req[i].ar.id];
            assign w_req[j][i]  = (w_dest_count[i] > 0) && (w_dest_fifo[i][w_dest_rd_ptr[i]] == j) && mst_req[i].w_valid;
        end

        rr_arbiter #(.N(NUM_MST)) aw_arb_inst (.clk(clk), .rst_n(rst_n), .req(aw_req[j]), .gnt(aw_gnt[j]));
        rr_arbiter #(.N(NUM_MST)) ar_arb_inst (.clk(clk), .rst_n(rst_n), .req(ar_req[j]), .gnt(ar_gnt[j]));
        rr_arbiter #(.N(NUM_MST)) w_arb_inst  (.clk(clk), .rst_n(rst_n), .req(w_req[j]),  .gnt(w_gnt[j]));

        logic [$clog2(NUM_MST)-1:0] aw_gnt_idx, ar_gnt_idx, w_gnt_idx;
        always_comb begin
            aw_gnt_idx = 0; ar_gnt_idx = 0; w_gnt_idx = 0;
            for (int i = 0; i < NUM_MST; i++) begin
                if (aw_gnt[j][i]) aw_gnt_idx = i;
                if (ar_gnt[j][i]) ar_gnt_idx = i;
                if (w_gnt[j][i])  w_gnt_idx = i;
            end
        end

        assign slv_req[j].aw_valid = |aw_gnt[j];
        assign slv_req[j].aw = mst_req[aw_gnt_idx].aw;
        assign slv_req[j].aw.id = {aw_gnt_idx, mst_req[aw_gnt_idx].aw.id};

        assign slv_req[j].ar_valid = |ar_gnt[j];
        assign slv_req[j].ar = mst_req[ar_gnt_idx].ar;
        assign slv_req[j].ar.id = {ar_gnt_idx, mst_req[ar_gnt_idx].ar.id};

        assign slv_req[j].w_valid = |w_gnt[j];
        assign slv_req[j].w = mst_req[w_gnt_idx].w;

        for (genvar i = 0; i < NUM_MST; i++) begin
            assign mst_resp[i].aw_ready = rst_n ? ((is_decerr_aw[i] && decerr_aw_count[i] < 8) || (aw_gnt[dest_port_aw[i]][i] && slv_resp[dest_port_aw[i]].aw_ready)) : 1'b0;
            assign mst_resp[i].ar_ready = rst_n ? ((is_decerr_ar[i] && decerr_ar_count[i] < 8) || (ar_gnt[dest_port_ar[i]][i] && slv_resp[dest_port_ar[i]].ar_ready)) : 1'b0;
        end
    end

    // =========================================================================
    // Response Arbitration (Slave to Master)
    // =========================================================================
    logic [NUM_SLV-1:0] b_req[NUM_MST];
    logic [NUM_SLV-1:0] b_gnt[NUM_MST];
    logic [NUM_SLV-1:0] r_req[NUM_MST];
    logic [NUM_SLV-1:0] r_gnt[NUM_MST];

    for (genvar i = 0; i < NUM_MST; i++) begin
        for (genvar j = 0; j < NUM_SLV; j++) begin
            assign b_req[i][j] = slv_resp[j].b_valid && (slv_resp[j].b.id[MST_ID_W-1 : SLV_ID_W] == i);
            assign r_req[i][j] = slv_resp[j].r_valid && (slv_resp[j].r.id[MST_ID_W-1 : SLV_ID_W] == i);
        end

        rr_arbiter #(.N(NUM_SLV)) b_arb_inst (.clk(clk), .rst_n(rst_n), .req(b_req[i]), .gnt(b_gnt[i]));
        rr_arbiter #(.N(NUM_SLV)) r_arb_inst (.clk(clk), .rst_n(rst_n), .req(r_req[i]), .gnt(r_gnt[i]));

        logic [$clog2(NUM_SLV)-1:0] b_gnt_idx, r_gnt_idx;
        always_comb begin
            b_gnt_idx = 0; r_gnt_idx = 0;
            for (int j = 0; j < NUM_SLV; j++) begin
                if (b_gnt[i][j]) b_gnt_idx = j;
                if (r_gnt[i][j]) r_gnt_idx = j;
            end
        end

        assign mst_resp[i].b_valid = rst_n ? (|b_gnt[i] || (decerr_w_state[i] == DW_WAIT_B)) : 1'b0;
        assign mst_resp[i].r_valid = rst_n ? (|r_gnt[i] || (decerr_r_state[i] == DR_WAIT_R)) : 1'b0;

        always_comb begin
            mst_resp[i].b = '0;
            if (decerr_w_state[i] == DW_WAIT_B) begin
                mst_resp[i].b.resp = RESP_DECERR;
                mst_resp[i].b.id = decerr_aw_fifo[i][decerr_aw_rd_ptr[i]].id;
                mst_resp[i].b.user = decerr_aw_fifo[i][decerr_aw_rd_ptr[i]].user;
            end else if (|b_gnt[i]) begin
                mst_resp[i].b = slv_resp[b_gnt_idx].b;
                mst_resp[i].b.id = slv_resp[b_gnt_idx].b.id[SLV_ID_W-1:0];
            end
        end

        always_comb begin
            mst_resp[i].r = '0;
            if (decerr_r_state[i] == DR_WAIT_R) begin
                mst_resp[i].r.resp = RESP_DECERR;
                mst_resp[i].r.id = decerr_ar_fifo[i][decerr_ar_rd_ptr[i]].id;
                mst_resp[i].r.user = decerr_ar_fifo[i][decerr_ar_rd_ptr[i]].user;
                mst_resp[i].r.last = (decerr_r_beats_left[i] == 0);
                mst_resp[i].r.data = '0;
            end else if (|r_gnt[i]) begin
                mst_resp[i].r = slv_resp[r_gnt_idx].r;
                mst_resp[i].r.id = slv_resp[r_gnt_idx].r.id[SLV_ID_W-1:0];
            end
        end

        for (genvar j = 0; j < NUM_SLV; j++) begin
            assign slv_req[j].b_ready = rst_n ? (b_gnt[i][j] && mst_resp[i].b_ready) : 1'b0;
            assign slv_req[j].r_ready = rst_n ? (r_gnt[i][j] && mst_resp[i].r_ready) : 1'b0;
        end
    end

    // =========================================================================
    // Master W Ready (Combines Xbar arbiter and DECERR state machine)
    // =========================================================================
    for (genvar i = 0; i < NUM_MST; i++) begin
        logic w_ready_from_xbar;
        always_comb begin
            w_ready_from_xbar = 0;
            for (int j = 0; j < NUM_SLV; j++) begin
                if (w_gnt[j][i] && slv_resp[j].w_ready) begin
                    w_ready_from_xbar = 1;
                end
            end
        end
        assign mst_resp[i].w_ready = rst_n ? (w_ready_from_xbar || (decerr_w_state[i] == DW_WAIT_W)) : 1'b0;
    end

endmodule