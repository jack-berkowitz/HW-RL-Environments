import axi4_xbar_pkg::*;

module axi4_xbar
  import axi4_xbar_pkg::*;
#(
    parameter int NUM_MST   = 2,
    parameter int NUM_SLV   = 2,
    parameter int MAX_TRANS = 8,
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

    // -------------------------------------------------------------------------
    // Local parameters
    // -------------------------------------------------------------------------
    localparam int MST_BITS = $clog2(NUM_MST);
    localparam int TGT_W    = $clog2(NUM_SLV + 1);
    localparam int DECERR   = NUM_SLV;

    localparam int AW_FIFO_DEPTH = 16;
    localparam int AR_FIFO_DEPTH = 16;
    localparam int W_FIFO_DEPTH  = 4;
    localparam int W_ASSOC_DEPTH = 16;
    localparam int DECERR_B_DEPTH = 16;
    localparam int DECERR_R_DEPTH = 16;

    // -------------------------------------------------------------------------
    // State
    // -------------------------------------------------------------------------
    logic [15:0] read_slot_valid  [NUM_MST];
    logic [15:0] write_slot_valid [NUM_MST];
    logic [15:0] aw_forwarded     [NUM_MST];

    // AW FIFO
    slv_aw_t          aw_fifo_data   [NUM_MST][AW_FIFO_DEPTH];
    logic [TGT_W-1:0] aw_fifo_target [NUM_MST][AW_FIFO_DEPTH];
    logic [3:0]       aw_fifo_head   [NUM_MST];
    logic [3:0]       aw_fifo_tail   [NUM_MST];
    logic [4:0]       aw_fifo_count  [NUM_MST];

    // AR FIFO
    slv_ar_t          ar_fifo_data   [NUM_MST][AR_FIFO_DEPTH];
    logic [TGT_W-1:0] ar_fifo_target [NUM_MST][AR_FIFO_DEPTH];
    logic [3:0]       ar_fifo_head   [NUM_MST];
    logic [3:0]       ar_fifo_tail   [NUM_MST];
    logic [4:0]       ar_fifo_count  [NUM_MST];

    // W FIFO
    w_t               w_fifo_data    [NUM_MST][W_FIFO_DEPTH];
    logic [TGT_W-1:0] w_fifo_target  [NUM_MST][W_FIFO_DEPTH];
    logic [SLV_ID_W-1:0] w_fifo_id   [NUM_MST][W_FIFO_DEPTH];
    logic [1:0]       w_fifo_head    [NUM_MST];
    logic [1:0]       w_fifo_tail    [NUM_MST];
    logic [2:0]       w_fifo_count   [NUM_MST];

    // W association queue
    logic [SLV_ID_W-1:0] w_assoc_id        [NUM_MST][W_ASSOC_DEPTH];
    logic [8:0]          w_assoc_remaining [NUM_MST][W_ASSOC_DEPTH];
    logic [TGT_W-1:0]    w_assoc_target    [NUM_MST][W_ASSOC_DEPTH];
    logic [3:0]          w_assoc_head      [NUM_MST];
    logic [3:0]          w_assoc_tail      [NUM_MST];
    logic [4:0]          w_assoc_count     [NUM_MST];

    // DECERR B FIFO
    logic [SLV_ID_W-1:0] decerr_b_id   [NUM_MST][DECERR_B_DEPTH];
    logic [3:0]          decerr_b_head [NUM_MST];
    logic [3:0]          decerr_b_tail [NUM_MST];
    logic [4:0]          decerr_b_count[NUM_MST];

    // DECERR R FIFO
    logic [SLV_ID_W-1:0] decerr_r_id        [NUM_MST][DECERR_R_DEPTH];
    logic [8:0]          decerr_r_remaining [NUM_MST][DECERR_R_DEPTH];
    logic [3:0]          decerr_r_head      [NUM_MST];
    logic [3:0]          decerr_r_tail      [NUM_MST];
    logic [4:0]          decerr_r_count     [NUM_MST];

    // Arbitration grants
    logic [TGT_W-1:0] grant_b [NUM_MST];
    logic [TGT_W-1:0] grant_r [NUM_MST];
    logic [1:0]       grant_aw [NUM_SLV];
    logic [1:0]       grant_ar [NUM_SLV];
    logic [1:0]       grant_w  [NUM_SLV];

    // Combinational push/pop and decode signals
    logic [NUM_MST-1:0] aw_push, aw_pop;
    logic [NUM_MST-1:0] ar_push, ar_pop;
    logic [NUM_MST-1:0] w_push, w_pop;
    logic [NUM_MST-1:0] w_assoc_push, w_assoc_pop;
    logic [NUM_MST-1:0] decerr_b_push, decerr_b_pop;
    logic [NUM_MST-1:0] decerr_r_push, decerr_r_pop;

    logic [NUM_MST-1:0] aw_dec_valid, ar_dec_valid;
    logic [TGT_W-1:0]   aw_dec_target [NUM_MST];
    logic [TGT_W-1:0]   ar_dec_target [NUM_MST];

    // -------------------------------------------------------------------------
    // ID widening functions
    // -------------------------------------------------------------------------
    function automatic mst_aw_t convert_aw(input slv_aw_t aw, input int m);
        mst_aw_t res;
        res = '0;
        res.id = '0;
        res.id[SLV_ID_W-1:0] = aw.id;
        res.id[SLV_ID_W +: MST_BITS] = m[MST_BITS-1:0];
        res.addr   = aw.addr;
        res.len    = aw.len;
        res.size   = aw.size;
        res.burst  = aw.burst;
        res.lock   = aw.lock;
        res.cache  = aw.cache;
        res.prot   = aw.prot;
        res.qos    = aw.qos;
        res.region = aw.region;
        res.atop   = aw.atop;
        res.user   = aw.user;
        return res;
    endfunction

    function automatic mst_ar_t convert_ar(input slv_ar_t ar, input int m);
        mst_ar_t res;
        res = '0;
        res.id = '0;
        res.id[SLV_ID_W-1:0] = ar.id;
        res.id[SLV_ID_W +: MST_BITS] = m[MST_BITS-1:0];
        res.addr   = ar.addr;
        res.len    = ar.len;
        res.size   = ar.size;
        res.burst  = ar.burst;
        res.lock   = ar.lock;
        res.cache  = ar.cache;
        res.prot   = ar.prot;
        res.qos    = ar.qos;
        res.region = ar.region;
        res.user   = ar.user;
        return res;
    endfunction

    // -------------------------------------------------------------------------
    // Combinational logic
    // -------------------------------------------------------------------------
    always_comb begin
        int m, s;
        logic aw_sel_valid, ar_sel_valid, w_sel_valid;
        logic [1:0] aw_sel_m, ar_sel_m, w_sel_m;
        logic b_sel_valid, r_sel_valid;
        logic [TGT_W-1:0] b_sel_src, r_sel_src;
        logic [MST_BITS-1:0] b_m, r_m;
        logic id_free_aw, w_assoc_space, aw_fifo_space;
        logic id_free_ar, ar_fifo_space, decerr_r_space;
        logic w_assoc_not_empty, w_fifo_space;

        // Default outputs
        for (m = 0; m < NUM_MST; m++) begin
            mst_resp[m] = '0;
        end
        for (s = 0; s < NUM_SLV; s++) begin
            slv_req[s] = '0;
        end

        // Default push/pop
        for (m = 0; m < NUM_MST; m++) begin
            aw_push[m]       = 1'b0;
            aw_pop[m]        = 1'b0;
            ar_push[m]       = 1'b0;
            ar_pop[m]        = 1'b0;
            w_push[m]        = 1'b0;
            w_pop[m]         = 1'b0;
            w_assoc_push[m]  = 1'b0;
            w_assoc_pop[m]   = 1'b0;
            decerr_b_push[m] = 1'b0;
            decerr_b_pop[m]  = 1'b0;
            decerr_r_push[m] = 1'b0;
            decerr_r_pop[m]  = 1'b0;
        end

        // Address decode
        for (m = 0; m < NUM_MST; m++) begin
            aw_dec_valid[m]  = 1'b0;
            aw_dec_target[m] = '0;
            ar_dec_valid[m]  = 1'b0;
            ar_dec_target[m] = '0;
            for (s = 0; s < NUM_SLV; s++) begin
                if (mst_req[m].aw.addr >= addr_map[s].start_addr &&
                    mst_req[m].aw.addr <  addr_map[s].end_addr) begin
                    aw_dec_valid[m]  = 1'b1;
                    aw_dec_target[m] = s[TGT_W-1:0];
                end
                if (mst_req[m].ar.addr >= addr_map[s].start_addr &&
                    mst_req[m].ar.addr <  addr_map[s].end_addr) begin
                    ar_dec_valid[m]  = 1'b1;
                    ar_dec_target[m] = s[TGT_W-1:0];
                end
            end
        end

        // Master ready signals
        for (m = 0; m < NUM_MST; m++) begin
            // AW ready
            id_free_aw    = !write_slot_valid[m][mst_req[m].aw.id];
            w_assoc_space = (w_assoc_count[m] < W_ASSOC_DEPTH);
            if (aw_dec_valid[m]) begin
                aw_fifo_space = (aw_fifo_count[m] < AW_FIFO_DEPTH);
                mst_resp[m].aw_ready = id_free_aw && w_assoc_space && aw_fifo_space;
            end else begin
                mst_resp[m].aw_ready = id_free_aw && w_assoc_space;
            end

            // AR ready
            id_free_ar = !read_slot_valid[m][mst_req[m].ar.id];
            if (ar_dec_valid[m]) begin
                ar_fifo_space = (ar_fifo_count[m] < AR_FIFO_DEPTH);
                mst_resp[m].ar_ready = id_free_ar && ar_fifo_space;
            end else begin
                decerr_r_space = (decerr_r_count[m] < DECERR_R_DEPTH);
                mst_resp[m].ar_ready = id_free_ar && decerr_r_space;
            end

            // W ready
            w_assoc_not_empty = (w_assoc_count[m] > 0);
            if (w_assoc_not_empty) begin
                if (w_assoc_target[m][w_assoc_head[m]] == DECERR) begin
                    mst_resp[m].w_ready = 1'b1;
                end else begin
                    w_fifo_space = (w_fifo_count[m] < W_FIFO_DEPTH);
                    mst_resp[m].w_ready = w_fifo_space;
                end
            end else begin
                mst_resp[m].w_ready = 1'b0;
            end
        end

        // Slave AW/AR/W arbiters
        for (s = 0; s < NUM_SLV; s++) begin
            // AW
            aw_sel_m     = grant_aw[s];
            aw_sel_valid = (aw_fifo_count[aw_sel_m] > 0) &&
                           (aw_fifo_target[aw_sel_m][aw_fifo_head[aw_sel_m]] == s);
            slv_req[s].aw_valid = aw_sel_valid;
            if (aw_sel_valid) begin
                slv_req[s].aw = convert_aw(aw_fifo_data[aw_sel_m][aw_fifo_head[aw_sel_m]], aw_sel_m);
            end

            // AR
            ar_sel_m     = grant_ar[s];
            ar_sel_valid = (ar_fifo_count[ar_sel_m] > 0) &&
                           (ar_fifo_target[ar_sel_m][ar_fifo_head[ar_sel_m]] == s);
            slv_req[s].ar_valid = ar_sel_valid;
            if (ar_sel_valid) begin
                slv_req[s].ar = convert_ar(ar_fifo_data[ar_sel_m][ar_fifo_head[ar_sel_m]], ar_sel_m);
            end

            // W
            w_sel_m     = grant_w[s];
            w_sel_valid = (w_fifo_count[w_sel_m] > 0) &&
                          (w_fifo_target[w_sel_m][w_fifo_head[w_sel_m]] == s) &&
                          aw_forwarded[w_sel_m][w_fifo_id[w_sel_m][w_fifo_head[w_sel_m]]];
            slv_req[s].w_valid = w_sel_valid;
            if (w_sel_valid) begin
                slv_req[s].w = w_fifo_data[w_sel_m][w_fifo_head[w_sel_m]];
            end

            // B ready
            b_m = slv_resp[s].b.id[SLV_ID_W +: MST_BITS];
            slv_req[s].b_ready = (grant_b[b_m] == s) && mst_req[b_m].b_ready;

            // R ready
            r_m = slv_resp[s].r.id[SLV_ID_W +: MST_BITS];
            slv_req[s].r_ready = (grant_r[r_m] == s) && mst_req[r_m].r_ready;
        end

        // Master B/R response routing
        for (m = 0; m < NUM_MST; m++) begin
            // B
            b_sel_src = grant_b[m];
            if (b_sel_src < NUM_SLV) begin
                b_sel_valid = slv_resp[b_sel_src].b_valid &&
                              (slv_resp[b_sel_src].b.id[SLV_ID_W +: MST_BITS] == m);
                mst_resp[m].b_valid = b_sel_valid;
                if (b_sel_valid) begin
                    mst_resp[m].b.id   = slv_resp[b_sel_src].b.id[SLV_ID_W-1:0];
                    mst_resp[m].b.resp = slv_resp[b_sel_src].b.resp;
                    mst_resp[m].b.user = slv_resp[b_sel_src].b.user;
                end
            end else begin
                b_sel_valid = (decerr_b_count[m] > 0);
                mst_resp[m].b_valid = b_sel_valid;
                if (b_sel_valid) begin
                    mst_resp[m].b.id   = decerr_b_id[m][decerr_b_head[m]];
                    mst_resp[m].b.resp = RESP_DECERR;
                    mst_resp[m].b.user = '0;
                end
            end

            // R
            r_sel_src = grant_r[m];
            if (r_sel_src < NUM_SLV) begin
                r_sel_valid = slv_resp[r_sel_src].r_valid &&
                              (slv_resp[r_sel_src].r.id[SLV_ID_W +: MST_BITS] == m);
                mst_resp[m].r_valid = r_sel_valid;
                if (r_sel_valid) begin
                    mst_resp[m].r.id   = slv_resp[r_sel_src].r.id[SLV_ID_W-1:0];
                    mst_resp[m].r.data = slv_resp[r_sel_src].r.data;
                    mst_resp[m].r.resp = slv_resp[r_sel_src].r.resp;
                    mst_resp[m].r.last = slv_resp[r_sel_src].r.last;
                    mst_resp[m].r.user = slv_resp[r_sel_src].r.user;
                end
            end else begin
                r_sel_valid = (decerr_r_count[m] > 0);
                mst_resp[m].r_valid = r_sel_valid;
                if (r_sel_valid) begin
                    mst_resp[m].r.id   = decerr_r_id[m][decerr_r_head[m]];
                    mst_resp[m].r.data = '0;
                    mst_resp[m].r.resp = RESP_DECERR;
                    mst_resp[m].r.last = (decerr_r_remaining[m][decerr_r_head[m]] == 1);
                    mst_resp[m].r.user = '0;
                end
            end
        end

        // Compute push/pop signals
        for (m = 0; m < NUM_MST; m++) begin
            aw_push[m] = mst_req[m].aw_valid && mst_resp[m].aw_ready && aw_dec_valid[m];
            ar_push[m] = mst_req[m].ar_valid && mst_resp[m].ar_ready && ar_dec_valid[m];

            w_push[m] = mst_req[m].w_valid && mst_resp[m].w_ready &&
                        (w_assoc_target[m][w_assoc_head[m]] != DECERR);

            w_assoc_push[m] = mst_req[m].aw_valid && mst_resp[m].aw_ready;
            w_assoc_pop[m]  = mst_req[m].w_valid && mst_resp[m].w_ready &&
                              (w_assoc_remaining[m][w_assoc_head[m]] == 1);

            decerr_b_push[m] = mst_req[m].w_valid && mst_resp[m].w_ready &&
                               (w_assoc_remaining[m][w_assoc_head[m]] == 1) &&
                               (w_assoc_target[m][w_assoc_head[m]] == DECERR);

            decerr_r_push[m] = mst_req[m].ar_valid && mst_resp[m].ar_ready && !ar_dec_valid[m];

            decerr_b_pop[m] = mst_resp[m].b_valid && mst_req[m].b_ready &&
                              (grant_b[m] == NUM_SLV);

            decerr_r_pop[m] = mst_resp[m].r_valid && mst_req[m].r_ready &&
                              (grant_r[m] == NUM_SLV) &&
                              (decerr_r_remaining[m][decerr_r_head[m]] == 1);
        end

        // Compute slave-side pops
        for (s = 0; s < NUM_SLV; s++) begin
            if (slv_req[s].aw_valid && slv_resp[s].aw_ready) begin
                aw_pop[grant_aw[s]] = 1'b1;
            end
            if (slv_req[s].ar_valid && slv_resp[s].ar_ready) begin
                ar_pop[grant_ar[s]] = 1'b1;
            end
            if (slv_req[s].w_valid && slv_resp[s].w_ready) begin
                w_pop[grant_w[s]] = 1'b1;
            end
        end

        // Reset valid outputs
        if (!rst_n) begin
            for (m = 0; m < NUM_MST; m++) begin
                mst_resp[m].b_valid = 1'b0;
                mst_resp[m].r_valid = 1'b0;
            end
            for (s = 0; s < NUM_SLV; s++) begin
                slv_req[s].aw_valid = 1'b0;
                slv_req[s].ar_valid = 1'b0;
                slv_req[s].w_valid  = 1'b0;
            end
        end
    end

    // -------------------------------------------------------------------------
    // Sequential logic
    // -------------------------------------------------------------------------
    always_ff @(posedge clk) begin
        int m, s, id;

        if (!rst_n) begin
            for (m = 0; m < NUM_MST; m++) begin
                read_slot_valid[m]  <= '0;
                write_slot_valid[m] <= '0;
                aw_forwarded[m]     <= '0;

                aw_fifo_head[m]  <= '0;
                aw_fifo_tail[m]  <= '0;
                aw_fifo_count[m] <= '0;

                ar_fifo_head[m]  <= '0;
                ar_fifo_tail[m]  <= '0;
                ar_fifo_count[m] <= '0;

                w_fifo_head[m]  <= '0;
                w_fifo_tail[m]  <= '0;
                w_fifo_count[m] <= '0;

                w_assoc_head[m]  <= '0;
                w_assoc_tail[m]  <= '0;
                w_assoc_count[m] <= '0;

                decerr_b_head[m]  <= '0;
                decerr_b_tail[m]  <= '0;
                decerr_b_count[m] <= '0;

                decerr_r_head[m]  <= '0;
                decerr_r_tail[m]  <= '0;
                decerr_r_count[m] <= '0;

                grant_b[m] <= '0;
                grant_r[m] <= '0;
            end
            for (s = 0; s < NUM_SLV; s++) begin
                grant_aw[s] <= '0;
                grant_ar[s] <= '0;
                grant_w[s]  <= '0;
            end
        end else begin
            // Per-master updates
            for (m = 0; m < NUM_MST; m++) begin
                // AW FIFO
                if (aw_push[m]) begin
                    aw_fifo_data[m][aw_fifo_tail[m]]   <= mst_req[m].aw;
                    aw_fifo_target[m][aw_fifo_tail[m]] <= aw_dec_target[m];
                    aw_fifo_tail[m] <= aw_fifo_tail[m] + 1;
                end
                if (aw_pop[m]) begin
                    aw_fifo_head[m] <= aw_fifo_head[m] + 1;
                end
                aw_fifo_count[m] <= aw_fifo_count[m] + aw_push[m] - aw_pop[m];

                // AR FIFO
                if (ar_push[m]) begin
                    ar_fifo_data[m][ar_fifo_tail[m]]   <= mst_req[m].ar;
                    ar_fifo_target[m][ar_fifo_tail[m]] <= ar_dec_target[m];
                    ar_fifo_tail[m] <= ar_fifo_tail[m] + 1;
                end
                if (ar_pop[m]) begin
                    ar_fifo_head[m] <= ar_fifo_head[m] + 1;
                end
                ar_fifo_count[m] <= ar_fifo_count[m] + ar_push[m] - ar_pop[m];

                // W FIFO
                if (w_push[m]) begin
                    w_fifo_data[m][w_fifo_tail[m]]   <= mst_req[m].w;
                    w_fifo_target[m][w_fifo_tail[m]] <= w_assoc_target[m][w_assoc_head[m]];
                    w_fifo_id[m][w_fifo_tail[m]]     <= w_assoc_id[m][w_assoc_head[m]];
                    w_fifo_tail[m] <= w_fifo_tail[m] + 1;
                end
                if (w_pop[m]) begin
                    w_fifo_head[m] <= w_fifo_head[m] + 1;
                end
                w_fifo_count[m] <= w_fifo_count[m] + w_push[m] - w_pop[m];

                // W association queue
                if (w_assoc_push[m]) begin
                    w_assoc_id[m][w_assoc_tail[m]]        <= mst_req[m].aw.id;
                    w_assoc_remaining[m][w_assoc_tail[m]] <= {1'b0, mst_req[m].aw.len} + 1;
                    w_assoc_target[m][w_assoc_tail[m]]    <= aw_dec_valid[m] ? aw_dec_target[m] : DECERR;
                    w_assoc_tail[m] <= w_assoc_tail[m] + 1;
                end
                if (mst_req[m].w_valid && mst_resp[m].w_ready) begin
                    if (!w_assoc_pop[m]) begin
                        w_assoc_remaining[m][w_assoc_head[m]] <=
                            w_assoc_remaining[m][w_assoc_head[m]] - 1;
                    end
                end
                if (w_assoc_pop[m]) begin
                    w_assoc_head[m] <= w_assoc_head[m] + 1;
                end
                w_assoc_count[m] <= w_assoc_count[m] + w_assoc_push[m] - w_assoc_pop[m];

                // DECERR B FIFO
                if (decerr_b_push[m]) begin
                    decerr_b_id[m][decerr_b_tail[m]] <= w_assoc_id[m][w_assoc_head[m]];
                    decerr_b_tail[m] <= decerr_b_tail[m] + 1;
                end
                if (decerr_b_pop[m]) begin
                    decerr_b_head[m] <= decerr_b_head[m] + 1;
                end
                decerr_b_count[m] <= decerr_b_count[m] + decerr_b_push[m] - decerr_b_pop[m];

                // DECERR R FIFO
                if (decerr_r_push[m]) begin
                    decerr_r_id[m][decerr_r_tail[m]]        <= mst_req[m].ar.id;
                    decerr_r_remaining[m][decerr_r_tail[m]] <= {1'b0, mst_req[m].ar.len} + 1;
                    decerr_r_tail[m] <= decerr_r_tail[m] + 1;
                end
                if (mst_resp[m].r_valid && mst_req[m].r_ready && (grant_r[m] == NUM_SLV)) begin
                    if (!decerr_r_pop[m]) begin
                        decerr_r_remaining[m][decerr_r_head[m]] <=
                            decerr_r_remaining[m][decerr_r_head[m]] - 1;
                    end
                end
                if (decerr_r_pop[m]) begin
                    decerr_r_head[m] <= decerr_r_head[m] + 1;
                end
                decerr_r_count[m] <= decerr_r_count[m] + decerr_r_push[m] - decerr_r_pop[m];

                // Slot valid updates
                for (id = 0; id < 16; id++) begin
                    if (mst_req[m].aw_valid && mst_resp[m].aw_ready && (mst_req[m].aw.id == id)) begin
                        write_slot_valid[m][id] <= 1'b1;
                    end else if (mst_resp[m].b_valid && mst_req[m].b_ready && (mst_resp[m].b.id == id)) begin
                        write_slot_valid[m][id] <= 1'b0;
                        aw_forwarded[m][id]     <= 1'b0;
                    end
                end
                for (id = 0; id < 16; id++) begin
                    if (mst_req[m].ar_valid && mst_resp[m].ar_ready && (mst_req[m].ar.id == id)) begin
                        read_slot_valid[m][id] <= 1'b1;
                    end else if (mst_resp[m].r_valid && mst_req[m].r_ready &&
                                 mst_resp[m].r.last && (mst_resp[m].r.id == id)) begin
                        read_slot_valid[m][id] <= 1'b0;
                    end
                end

                // B grant update
                if (mst_resp[m].b_valid && mst_req[m].b_ready) begin
                    if (grant_b[m] == NUM_SLV) grant_b[m] <= '0;
                    else                       grant_b[m] <= grant_b[m] + 1;
                end else if (!mst_resp[m].b_valid) begin
                    if (grant_b[m] == NUM_SLV) grant_b[m] <= '0;
                    else                       grant_b[m] <= grant_b[m] + 1;
                end

                // R grant update
                if (mst_resp[m].r_valid && mst_req[m].r_ready) begin
                    if (grant_r[m] == NUM_SLV) grant_r[m] <= '0;
                    else                       grant_r[m] <= grant_r[m] + 1;
                end else if (!mst_resp[m].r_valid) begin
                    if (grant_r[m] == NUM_SLV) grant_r[m] <= '0;
                    else                       grant_r[m] <= grant_r[m] + 1;
                end
            end

            // Per-slave arbiter updates
            for (s = 0; s < NUM_SLV; s++) begin
                // AW
                if (slv_req[s].aw_valid && slv_resp[s].aw_ready) begin
                    aw_forwarded[grant_aw[s]][aw_fifo_data[grant_aw[s]][aw_fifo_head[grant_aw[s]]].id] <= 1'b1;
                    if (grant_aw[s] == NUM_MST-1) grant_aw[s] <= '0;
                    else                          grant_aw[s] <= grant_aw[s] + 1;
                end else if (!slv_req[s].aw_valid) begin
                    if (grant_aw[s] == NUM_MST-1) grant_aw[s] <= '0;
                    else                          grant_aw[s] <= grant_aw[s] + 1;
                end

                // AR
                if (slv_req[s].ar_valid && slv_resp[s].ar_ready) begin
                    if (grant_ar[s] == NUM_MST-1) grant_ar[s] <= '0;
                    else                          grant_ar[s] <= grant_ar[s] + 1;
                end else if (!slv_req[s].ar_valid) begin
                    if (grant_ar[s] == NUM_MST-1) grant_ar[s] <= '0;
                    else                          grant_ar[s] <= grant_ar[s] + 1;
                end

                // W
                if (slv_req[s].w_valid && slv_resp[s].w_ready) begin
                    if (grant_w[s] == NUM_MST-1) grant_w[s] <= '0;
                    else                         grant_w[s] <= grant_w[s] + 1;
                end else if (!slv_req[s].w_valid) begin
                    if (grant_w[s] == NUM_MST-1) grant_w[s] <= '0;
                    else                         grant_w[s] <= grant_w[s] + 1;
                end
            end
        end
    end

endmodule
