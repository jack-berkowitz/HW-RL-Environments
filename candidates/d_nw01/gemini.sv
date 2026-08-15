// =============================================================================
// axi4_xbar.sv  --  Full AXI4 Crossbar Implementation
// =============================================================================

import axi4_xbar_pkg::*;

module axi4_xbar #(
    parameter int NUM_MST       = 2,  // Masters attached (2 / 4)
    parameter int NUM_SLV       = 2,  // Slaves attached (2 / 4)
    parameter int MAX_TRANS     = 8,  // Outstanding transactions per master (2 / 8)
    parameter int MAX_BURST_LEN = 3  // Max burst length supported (3 / 255)
) (
    input  logic                     clk,
    input  logic                     rst_n,

    // ---- master side: NUM_MST masters drive these -------------------------
    input  slv_req_t  [NUM_MST-1:0] mst_req,
    output slv_resp_t [NUM_MST-1:0] mst_resp,

    // ---- slave side: NUM_SLV slaves are driven by these --------------------
    output mst_req_t  [NUM_SLV-1:0] slv_req,
    input  mst_resp_t [NUM_SLV-1:0] slv_resp,

    // ---- address map ------------------------------------------------------
    input  xbar_rule_t [NUM_SLV-1:0] addr_map
);

    localparam int DECERR_SLV = NUM_SLV; // Internal slave index for decode errors
    localparam int DEST_W     = $clog2(NUM_SLV + 1);

    // -------------------------------------------------------------------------
    // Address Decoder Function
    // -------------------------------------------------------------------------
    function automatic logic [DEST_W-1:0] decode_addr(
        input addr_t addr,
        input xbar_rule_t [NUM_SLV-1:0] map
    );
        for (int unsigned s = 0; s < NUM_SLV; s++) begin
            if (addr >= map[s].start_addr && addr < map[s].end_addr) begin
                return map[s].mst_port[DEST_W-1:0];
            end
        end
        return DECERR_SLV[DEST_W-1:0];
    endfunction

    // -------------------------------------------------------------------------
    // Per-Master Port Processing Logic
    // -------------------------------------------------------------------------
    // AW / W / B signals per master
    logic [NUM_MST-1:0]               mst_aw_req_valid;
    slv_aw_t [NUM_MST-1:0]            mst_aw_req_payload;
    logic [DEST_W-1:0]                mst_aw_req_dest [NUM_MST-1:0];

    logic [NUM_MST-1:0]               mst_w_req_valid;
    w_t [NUM_MST-1:0]                 mst_w_req_payload;
    logic [DEST_W-1:0]                mst_w_req_dest [NUM_MST-1:0];

    logic [DEST_W-1:0]                mst_b_expected_dest [NUM_MST-1:0];
    logic [NUM_MST-1:0]               mst_b_order_empty;

    // AR / R signals per master
    logic [NUM_MST-1:0]               mst_ar_req_valid;
    slv_ar_t [NUM_MST-1:0]            mst_ar_req_payload;
    logic [DEST_W-1:0]                mst_ar_req_dest [NUM_MST-1:0];

    logic [DEST_W-1:0]                mst_r_expected_dest [NUM_MST-1:0];
    logic [NUM_MST-1:0]               mst_r_order_empty;

    // Local DECERR response signals
    logic [NUM_MST-1:0]               decerr_b_valid;
    slv_b_t [NUM_MST-1:0]             decerr_b_payload;
    logic [NUM_MST-1:0]               decerr_b_ready;

    logic [NUM_MST-1:0]               decerr_r_valid;
    slv_r_t [NUM_MST-1:0]             decerr_r_payload;
    logic [NUM_MST-1:0]               decerr_r_ready;

    genvar m;
    generate
        for (m = 0; m < NUM_MST; m++) begin : gen_master_logic

            // ------------------- Write Address (AW) Pipeline -----------------
            logic [DEST_W-1:0] aw_decoded_dest;
            assign aw_decoded_dest = decode_addr(mst_req[m].aw.addr, addr_map);

            logic aw_fifo_full, aw_fifo_empty;
            slv_aw_t aw_fifo_out_payload;
            logic [DEST_W-1:0] aw_fifo_out_dest;

            xbar_fifo #(
                .T(struct packed { slv_aw_t payload; logic [DEST_W-1:0] dest; }),
                .DEPTH(MAX_TRANS)
            ) u_aw_fifo (
                .clk(clk), .rst_n(rst_n),
                .push(mst_req[m].aw_valid && !aw_fifo_full),
                .din({mst_req[m].aw, aw_decoded_dest}),
                .pop(mst_aw_req_valid[m] && (
                    (mst_aw_req_dest[m] < NUM_SLV && slv_req[mst_aw_req_dest[m]].aw_valid && slv_resp[mst_aw_req_dest[m]].aw_ready) ||
                    (mst_aw_req_dest[m] == DECERR_SLV)
                )),
                .dout({aw_fifo_out_payload, aw_fifo_out_dest}),
                .empty(aw_fifo_empty),
                .full(aw_fifo_full),
                .count()
            );

            assign mst_resp[m].aw_ready = !aw_fifo_full;
            assign mst_aw_req_valid[m]  = !aw_fifo_empty;
            assign mst_aw_req_payload[m]= aw_fifo_out_payload;
            assign mst_aw_req_dest[m]   = aw_fifo_out_dest;

            // Track W destination and B response order
            logic w_dest_fifo_full, w_dest_fifo_empty;
            logic b_order_fifo_full, b_order_fifo_empty;

            xbar_fifo #(.T(logic [DEST_W-1:0]), .DEPTH(MAX_TRANS)) u_w_dest_fifo (
                .clk(clk), .rst_n(rst_n),
                .push(mst_req[m].aw_valid && !aw_fifo_full),
                .din(aw_decoded_dest),
                .pop(mst_req[m].w_valid && mst_resp[m].w_ready && mst_req[m].w.last),
                .dout(mst_w_req_dest[m]),
                .empty(w_dest_fifo_empty),
                .full(w_dest_fifo_full),
                .count()
            );

            assign mst_w_req_valid[m]   = mst_req[m].w_valid && !w_dest_fifo_empty;
            assign mst_w_req_payload[m] = mst_req[m].w;

            xbar_fifo #(.T(logic [DEST_W-1:0]), .DEPTH(MAX_TRANS)) u_b_order_fifo (
                .clk(clk), .rst_n(rst_n),
                .push(mst_req[m].aw_valid && !aw_fifo_full),
                .din(aw_decoded_dest),
                .pop(mst_resp[m].b_valid && mst_req[m].b_ready),
                .dout(mst_b_expected_dest[m]),
                .empty(b_order_fifo_empty),
                .full(b_order_fifo_full),
                .count()
            );

            assign mst_b_order_empty[m] = b_order_fifo_empty;

            // Local Write DECERR logic
            logic decerr_aw_pop;
            assign decerr_aw_pop = mst_aw_req_valid[m] && (mst_aw_req_dest[m] == DECERR_SLV);

            logic decerr_b_fifo_full, decerr_b_fifo_empty;
            slv_id_t decerr_aw_id_q;

            always_ff @(posedge clk) begin
                if (decerr_aw_pop) decerr_aw_id_q <= mst_aw_req_payload[m].id;
            end

            xbar_fifo #(.T(slv_id_t), .DEPTH(MAX_TRANS)) u_decerr_b_fifo (
                .clk(clk), .rst_n(rst_n),
                .push(mst_req[m].w_valid && mst_resp[m].w_ready && mst_req[m].w.last && (mst_w_req_dest[m] == DECERR_SLV)),
                .din(decerr_aw_id_q),
                .pop(decerr_b_ready[m] && decerr_b_valid[m]),
                .dout(decerr_b_payload[m].id),
                .empty(decerr_b_fifo_empty),
                .full(decerr_b_fifo_full),
                .count()
            );

            assign decerr_b_payload[m].resp = RESP_DECERR;
            assign decerr_b_payload[m].user = '0;
            assign decerr_b_valid[m]        = !decerr_b_fifo_empty;

            // Write Response (B) Routing to Master
            always_comb begin
                mst_resp[m].b_valid = 1'b0;
                mst_resp[m].b       = '0;
                decerr_b_ready[m]   = 1'b0;

                if (!b_order_fifo_empty) begin
                    if (mst_b_expected_dest[m] == DECERR_SLV) begin
                        mst_resp[m].b_valid = decerr_b_valid[m];
                        mst_resp[m].b       = decerr_b_payload[m];
                        decerr_b_ready[m]   = mst_req[m].b_ready;
                    end else begin
                        automatic int s = mst_b_expected_dest[m];
                        if (slv_resp[s].b_valid && (slv_resp[s].b.id[MST_ID_W-1:SLV_ID_W] == m[MST_IDX_W-1:0])) begin
                            mst_resp[m].b_valid = 1'b1;
                            mst_resp[m].b.id    = slv_resp[s].b.id[SLV_ID_W-1:0];
                            mst_resp[m].b.resp  = slv_resp[s].b.resp;
                            mst_resp[m].b.user  = slv_resp[s].b.user;
                        end
                    end
                end
            end

            // ------------------- Read Address (AR) Pipeline ------------------
            logic [DEST_W-1:0] ar_decoded_dest;
            assign ar_decoded_dest = decode_addr(mst_req[m].ar.addr, addr_map);

            logic ar_fifo_full, ar_fifo_empty;
            slv_ar_t ar_fifo_out_payload;
            logic [DEST_W-1:0] ar_fifo_out_dest;

            xbar_fifo #(
                .T(struct packed { slv_ar_t payload; logic [DEST_W-1:0] dest; }),
                .DEPTH(MAX_TRANS)
            ) u_ar_fifo (
                .clk(clk), .rst_n(rst_n),
                .push(mst_req[m].ar_valid && !ar_fifo_full),
                .din({mst_req[m].ar, ar_decoded_dest}),
                .pop(mst_ar_req_valid[m] && (
                    (mst_ar_req_dest[m] < NUM_SLV && slv_req[mst_ar_req_dest[m]].ar_valid && slv_resp[mst_ar_req_dest[m]].ar_ready) ||
                    (mst_ar_req_dest[m] == DECERR_SLV)
                )),
                .dout({ar_fifo_out_payload, ar_fifo_out_dest}),
                .empty(ar_fifo_empty),
                .full(ar_fifo_full),
                .count()
            );

            assign mst_resp[m].ar_ready = !ar_fifo_full;
            assign mst_ar_req_valid[m]  = !ar_fifo_empty;
            assign mst_ar_req_payload[m]= ar_fifo_out_payload;
            assign mst_ar_req_dest[m]   = ar_fifo_out_dest;

            // Track R response order
            logic r_order_fifo_full, r_order_fifo_empty;

            xbar_fifo #(.T(logic [DEST_W-1:0]), .DEPTH(MAX_TRANS)) u_r_order_fifo (
                .clk(clk), .rst_n(rst_n),
                .push(mst_req[m].ar_valid && !ar_fifo_full),
                .din(ar_decoded_dest),
                .pop(mst_resp[m].r_valid && mst_req[m].r_ready && mst_resp[m].r.last),
                .dout(mst_r_expected_dest[m]),
                .empty(r_order_fifo_empty),
                .full(r_order_fifo_full),
                .count()
            );

            assign mst_r_order_empty[m] = r_order_fifo_empty;

            // Local Read DECERR logic
            logic decerr_ar_pop;
            assign decerr_ar_pop = mst_ar_req_valid[m] && (mst_ar_req_dest[m] == DECERR_SLV);

            logic decerr_r_fifo_full, decerr_r_fifo_empty;
            slv_id_t decerr_r_id;
            logic [7:0] decerr_r_len;
            logic [7:0] decerr_r_cnt;

            xbar_fifo #(.T(struct packed { slv_id_t id; logic [7:0] len; }), .DEPTH(MAX_TRANS)) u_decerr_r_fifo (
                .clk(clk), .rst_n(rst_n),
                .push(decerr_ar_pop),
                .din({mst_ar_req_payload[m].id, mst_ar_req_payload[m].len}),
                .pop(decerr_r_valid[m] && decerr_r_ready[m] && (decerr_r_cnt == decerr_r_len)),
                .dout({decerr_r_id, decerr_r_len}),
                .empty(decerr_r_fifo_empty),
                .full(decerr_r_fifo_full),
                .count()
            );

            always_ff @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    decerr_r_cnt <= '0;
                end else if (decerr_r_valid[m] && decerr_r_ready[m]) begin
                    if (decerr_r_cnt == decerr_r_len) decerr_r_cnt <= '0;
                    else decerr_r_cnt <= decerr_r_cnt + 1'b1;
                end
            end

            assign decerr_r_valid[m]        = !decerr_r_fifo_empty;
            assign decerr_r_payload[m].id   = decerr_r_id;
            assign decerr_r_payload[m].data = '0;
            assign decerr_r_payload[m].resp = RESP_DECERR;
            assign decerr_r_payload[m].last = (decerr_r_cnt == decerr_r_len);
            assign decerr_r_payload[m].user = '0;

            // Read Data/Response (R) Routing to Master
            always_comb begin
                mst_resp[m].r_valid = 1'b0;
                mst_resp[m].r       = '0;
                decerr_r_ready[m]   = 1'b0;

                if (!r_order_fifo_empty) begin
                    if (mst_r_expected_dest[m] == DECERR_SLV) begin
                        mst_resp[m].r_valid = decerr_r_valid[m];
                        mst_resp[m].r       = decerr_r_payload[m];
                        decerr_r_ready[m]   = mst_req[m].r_ready;
                    end else begin
                        automatic int s = mst_r_expected_dest[m];
                        if (slv_resp[s].r_valid && (slv_resp[s].r.id[MST_ID_W-1:SLV_ID_W] == m[MST_IDX_W-1:0])) begin
                            mst_resp[m].r_valid = 1'b1;
                            mst_resp[m].r.id    = slv_resp[s].r.id[SLV_ID_W-1:0];
                            mst_resp[m].r.data  = slv_resp[s].r.data;
                            mst_resp[m].r.resp  = slv_resp[s].r.resp;
                            mst_resp[m].r.last  = slv_resp[s].r.last;
                            mst_resp[m].r.user  = slv_resp[s].r.user;
                        end
                    end
                end
            end

        end
    endgenerate

    // -------------------------------------------------------------------------
    // Per-Slave Port Processing Logic (Arbitration & Crossbar Interconnect)
    // -------------------------------------------------------------------------
    genvar s;
    generate
        for (s = 0; s < NUM_SLV; s++) begin : gen_slave_logic

            // --- AW Arbitration ---
            logic [NUM_MST-1:0] aw_req_vec;
            for (genvar m_idx = 0; m_idx < NUM_MST; m_idx++) begin : gen_aw_req
                assign aw_req_vec[m_idx] = mst_aw_req_valid[m_idx] && (mst_aw_req_dest[m_idx] == s);
            end

            logic [NUM_MST-1:0]       aw_gnt_vec;
            logic [$clog2(NUM_MST)-1:0] aw_gnt_idx;
            logic                     aw_gnt_valid;

            rr_arbiter #(.N(NUM_MST)) u_aw_arb (
                .clk(clk), .rst_n(rst_n),
                .req(aw_req_vec),
                .gnt_ack(slv_req[s].aw_valid && slv_resp[s].aw_ready),
                .gnt(aw_gnt_vec),
                .gnt_idx(aw_gnt_idx),
                .gnt_valid(aw_gnt_valid)
            );

            assign slv_req[s].aw_valid = aw_gnt_valid;
            assign slv_req[s].aw.id    = {aw_gnt_idx[MST_IDX_W-1:0], mst_aw_req_payload[aw_gnt_idx].id};
            assign slv_req[s].aw.addr  = mst_aw_req_payload[aw_gnt_idx].addr;
            assign slv_req[s].aw.len   = mst_aw_req_payload[aw_gnt_idx].len;
            assign slv_req[s].aw.size  = mst_aw_req_payload[aw_gnt_idx].size;
            assign slv_req[s].aw.burst = mst_aw_req_payload[aw_gnt_idx].burst;
            assign slv_req[s].aw.lock  = mst_aw_req_payload[aw_gnt_idx].lock;
            assign slv_req[s].aw.cache = mst_aw_req_payload[aw_gnt_idx].cache;
            assign slv_req[s].aw.prot  = mst_aw_req_payload[aw_gnt_idx].prot;
            assign slv_req[s].aw.qos   = mst_aw_req_payload[aw_gnt_idx].qos;
            assign slv_req[s].aw.region= mst_aw_req_payload[aw_gnt_idx].region;
            assign slv_req[s].aw.atop  = mst_aw_req_payload[aw_gnt_idx].atop;
            assign slv_req[s].aw.user  = mst_aw_req_payload[aw_gnt_idx].user;

            // Track active master order for W channel
            logic slv_w_order_empty, slv_w_order_full;
            logic [$clog2(NUM_MST)-1:0] active_w_mst;

            xbar_fifo #(.T(logic [$clog2(NUM_MST)-1:0]), .DEPTH(MAX_TRANS * NUM_MST)) u_slv_w_order_fifo (
                .clk(clk), .rst_n(rst_n),
                .push(slv_req[s].aw_valid && slv_resp[s].aw_ready),
                .din(aw_gnt_idx),
                .pop(slv_req[s].w_valid && slv_resp[s].w_ready && slv_req[s].w.last),
                .dout(active_w_mst),
                .empty(slv_w_order_empty),
                .full(slv_w_order_full),
                .count()
            );

            // --- W Channel Routing ---
            assign slv_req[s].w_valid = !slv_w_order_empty && mst_w_req_valid[active_w_mst] && (mst_w_req_dest[active_w_mst] == s);
            assign slv_req[s].w       = mst_w_req_payload[active_w_mst];

            // --- B Channel Ready Propagation ---
            always_comb begin
                slv_req[s].b_ready = 1'b0;
                if (slv_resp[s].b_valid) begin
                    automatic int target_m = slv_resp[s].b.id[MST_ID_W-1:SLV_ID_W];
                    if (!mst_b_order_empty[target_m] && (mst_b_expected_dest[target_m] == s)) begin
                        slv_req[s].b_ready = mst_req[target_m].b_ready;
                    end
                end
            end

            // --- AR Arbitration ---
            logic [NUM_MST-1:0] ar_req_vec;
            for (genvar m_idx = 0; m_idx < NUM_MST; m_idx++) begin : gen_ar_req
                assign ar_req_vec[m_idx] = mst_ar_req_valid[m_idx] && (mst_ar_req_dest[m_idx] == s);
            end

            logic [NUM_MST-1:0]       ar_gnt_vec;
            logic [$clog2(NUM_MST)-1:0] ar_gnt_idx;
            logic                     ar_gnt_valid;

            rr_arbiter #(.N(NUM_MST)) u_ar_arb (
                .clk(clk), .rst_n(rst_n),
                .req(ar_req_vec),
                .gnt_ack(slv_req[s].ar_valid && slv_resp[s].ar_ready),
                .gnt(ar_gnt_vec),
                .gnt_idx(ar_gnt_idx),
                .gnt_valid(ar_gnt_valid)
            );

            assign slv_req[s].ar_valid = ar_gnt_valid;
            assign slv_req[s].ar.id    = {ar_gnt_idx[MST_IDX_W-1:0], mst_ar_req_payload[ar_gnt_idx].id};
            assign slv_req[s].ar.addr  = mst_ar_req_payload[ar_gnt_idx].addr;
            assign slv_req[s].ar.len   = mst_ar_req_payload[ar_gnt_idx].len;
            assign slv_req[s].ar.size  = mst_ar_req_payload[ar_gnt_idx].size;
            assign slv_req[s].ar.burst = mst_ar_req_payload[ar_gnt_idx].burst;
            assign slv_req[s].ar.lock  = mst_ar_req_payload[ar_gnt_idx].lock;
            assign slv_req[s].ar.cache = mst_ar_req_payload[ar_gnt_idx].cache;
            assign slv_req[s].ar.prot  = mst_ar_req_payload[ar_gnt_idx].prot;
            assign slv_req[s].ar.qos   = mst_ar_req_payload[ar_gnt_idx].qos;
            assign slv_req[s].ar.region= mst_ar_req_payload[ar_gnt_idx].region;
            assign slv_req[s].ar.user  = mst_ar_req_payload[ar_gnt_idx].user;

            // --- R Channel Ready Propagation ---
            always_comb begin
                slv_req[s].r_ready = 1'b0;
                if (slv_resp[s].r_valid) begin
                    automatic int target_m = slv_resp[s].r.id[MST_ID_W-1:SLV_ID_W];
                    if (!mst_r_order_empty[target_m] && (mst_r_expected_dest[target_m] == s)) begin
                        slv_req[s].r_ready = mst_req[target_m].r_ready;
                    end
                end
            end

        end
    endgenerate

    // -------------------------------------------------------------------------
    // Global W Ready per Master
    // -------------------------------------------------------------------------
    generate
        for (m = 0; m < NUM_MST; m++) begin : gen_w_ready
            always_comb begin
                mst_resp[m].w_ready = 1'b0;
                if (mst_w_req_valid[m]) begin
                    if (mst_w_req_dest[m] == DECERR_SLV) begin
                        mst_resp[m].w_ready = 1'b1;
                    end else begin
                        automatic int s = mst_w_req_dest[m];
                        if (!gen_slave_logic[s].slv_w_order_empty &&
                            (gen_slave_logic[s].active_w_mst == m)) begin
                            mst_resp[m].w_ready = slv_resp[s].w_ready;
                        end
                    end
                end
            end
        end
    endgenerate

endmodule

// =============================================================================
// Helper Module: Synchronous Register FIFO
// =============================================================================
module xbar_fifo #(
    parameter type T = logic,
    parameter int DEPTH = 8
) (
    input  logic clk,
    input  logic rst_n,
    input  logic push,
    input  T     din,
    input  logic pop,
    output T     dout,
    output logic empty,
    output logic full,
    output logic [$clog2(DEPTH+1)-1:0] count
);
    localparam int ADDR_W = $clog2(DEPTH);
    T mem [0:DEPTH-1];
    logic [ADDR_W-1:0] wr_ptr, rd_ptr;
    logic [$clog2(DEPTH+1)-1:0] cnt;

    assign empty = (cnt == '0);
    assign full  = (cnt == DEPTH);
    assign count = cnt;
    assign dout  = mem[rd_ptr];

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= '0;
            rd_ptr <= '0;
            cnt    <= '0;
        end else begin
            case ({push && !full, pop && !empty})
                2'b10: begin
                    mem[wr_ptr] <= din;
                    wr_ptr      <= (wr_ptr == DEPTH-1) ? '0 : wr_ptr + 1'b1;
                    cnt         <= cnt + 1'b1;
                end
                2'b01: begin
                    rd_ptr      <= (rd_ptr == DEPTH-1) ? '0 : rd_ptr + 1'b1;
                    cnt         <= cnt - 1'b1;
                end
                2'b11: begin
                    mem[wr_ptr] <= din;
                    wr_ptr      <= (wr_ptr == DEPTH-1) ? '0 : wr_ptr + 1'b1;
                    rd_ptr      <= (rd_ptr == DEPTH-1) ? '0 : rd_ptr + 1'b1;
                end
                default: ;
            endcase
        end
    end
endmodule

// =============================================================================
// Helper Module: Round-Robin Arbiter
// =============================================================================
module rr_arbiter #(
    parameter int N = 2
) (
    input  logic                 clk,
    input  logic                 rst_n,
    input  logic [N-1:0]         req,
    input  logic                 gnt_ack,
    output logic [N-1:0]         gnt,
    output logic [$clog2(N)-1:0] gnt_idx,
    output logic                 gnt_valid
);
    logic [$clog2(N)-1:0] last_gnt;

    always_comb begin
        gnt       = '0;
        gnt_idx   = '0;
        gnt_valid = 1'b0;

        for (int unsigned i = 0; i < N; i++) begin
            int unsigned idx;
            idx = (last_gnt + 1 + i) % N;
            if (req[idx]) begin
                gnt[idx]  = 1'b1;
                gnt_idx   = idx[$clog2(N)-1:0];
                gnt_valid = 1'b1;
                break;
            end
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            last_gnt <= '0;
        end else if (gnt_valid && gnt_ack) begin
            last_gnt <= gnt_idx;
        end
    end
endmodule