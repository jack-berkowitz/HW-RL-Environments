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

    localparam int MST_W = $clog2(NUM_MST);
    localparam int SLV_W = $clog2(NUM_SLV);
    localparam int TGT_W = $clog2(NUM_SLV + 1);
    localparam logic [TGT_W-1:0] TGT_LOCAL = NUM_SLV;
    localparam int ID_W = SLV_ID_W;

    // ------------------------------------------------------------------------
    // State registers
    // ------------------------------------------------------------------------
    logic [3:0] out_rd_cnt [NUM_MST];
    logic [3:0] out_wr_cnt [NUM_MST];
    logic       busy_rd [NUM_MST][16];
    logic       busy_wr [NUM_MST][16];

    // AR FIFO
    logic                   ar_fifo_valid [NUM_MST][MAX_TRANS];
    logic [TGT_W-1:0]       ar_fifo_target [NUM_MST][MAX_TRANS];
    logic [3:0]             ar_fifo_id [NUM_MST][MAX_TRANS];
    logic [7:0]             ar_fifo_len [NUM_MST][MAX_TRANS];
    slv_ar_t                ar_fifo_data [NUM_MST][MAX_TRANS];
    logic [2:0]             ar_fifo_head [NUM_MST];
    logic [2:0]             ar_fifo_tail [NUM_MST];
    logic [3:0]             ar_fifo_count [NUM_MST];

    // AW FIFO
    logic                   aw_fifo_valid [NUM_MST][MAX_TRANS];
    logic [TGT_W-1:0]       aw_fifo_target [NUM_MST][MAX_TRANS];
    logic [3:0]             aw_fifo_id [NUM_MST][MAX_TRANS];
    logic [7:0]             aw_fifo_len [NUM_MST][MAX_TRANS];
    logic                   aw_fifo_aw_sent [NUM_MST][MAX_TRANS];
    slv_aw_t                aw_fifo_data [NUM_MST][MAX_TRANS];
    logic [2:0]             aw_fifo_head [NUM_MST];
    logic [2:0]             aw_fifo_tail [NUM_MST];
    logic [3:0]             aw_fifo_count [NUM_MST];

    // W state
    logic       w_active [NUM_MST];
    logic [7:0] w_rem [NUM_MST];

    // Local read state
    logic       local_rd_active [NUM_MST];
    logic [3:0] local_rd_id [NUM_MST];
    logic [7:0] local_rd_rem [NUM_MST];

    // B FIFO (depth 4)
    logic       b_fifo_valid [NUM_MST][4];
    logic [3:0] b_fifo_id [NUM_MST][4];
    logic [1:0] b_fifo_resp [NUM_MST][4];
    logic [0:0] b_fifo_user [NUM_MST][4];
    logic [1:0] b_fifo_head [NUM_MST];
    logic [1:0] b_fifo_tail [NUM_MST];
    logic [2:0] b_fifo_count [NUM_MST];

    // Slave arbiters
    logic               slv_aw_lock [NUM_SLV];
    logic [MST_W-1:0]   slv_aw_lock_mst [NUM_SLV];
    logic [MST_W-1:0]   slv_aw_rr [NUM_SLV];
    logic               slv_ar_lock [NUM_SLV];
    logic [MST_W-1:0]   slv_ar_lock_mst [NUM_SLV];
    logic [MST_W-1:0]   slv_ar_rr [NUM_SLV];
    logic               slv_w_busy [NUM_SLV];
    logic [MST_W-1:0]   slv_w_mst [NUM_SLV];

    // Master R arbiter
    logic               mst_r_lock [NUM_MST];
    logic [TGT_W-1:0]   mst_r_lock_sel [NUM_MST];
    logic [TGT_W-1:0]   mst_r_rr [NUM_MST];
    logic               mst_r_sel_valid [NUM_MST];
    logic [TGT_W-1:0]   mst_r_sel_src [NUM_MST];

    // Master B arbiter
    logic [1:0]         mst_b_rr [NUM_MST];
    logic               mst_b_sel_valid [NUM_MST];
    logic [1:0]         mst_b_sel_slv [NUM_MST];

    // Slave selection signals
    logic               slv_aw_sel_valid [NUM_SLV];
    logic [MST_W-1:0]   slv_aw_sel_mst [NUM_SLV];
    logic               slv_ar_sel_valid [NUM_SLV];
    logic [MST_W-1:0]   slv_ar_sel_mst [NUM_SLV];

    // ------------------------------------------------------------------------
    // Arbitration and selection logic
    // ------------------------------------------------------------------------
    always_comb begin
        integer i, s, m, k;
        logic found;
        logic [TGT_W-1:0] sel_src;

        for (s = 0; s < NUM_SLV; s++) begin
            slv_aw_sel_valid[s] = 1'b0;
            slv_aw_sel_mst[s]   = '0;
            slv_ar_sel_valid[s] = 1'b0;
            slv_ar_sel_mst[s]   = '0;
        end
        for (m = 0; m < NUM_MST; m++) begin
            mst_r_sel_valid[m] = 1'b0;
            mst_r_sel_src[m]   = '0;
            mst_b_sel_valid[m] = 1'b0;
            mst_b_sel_slv[m]   = '0;
        end

        // AW selection per slave
        for (s = 0; s < NUM_SLV; s++) begin
            if (slv_aw_lock[s]) begin
                m = slv_aw_lock_mst[s];
                if (aw_fifo_count[m] > 0 &&
                    aw_fifo_target[m][aw_fifo_head[m]] == s &&
                    !aw_fifo_aw_sent[m][aw_fifo_head[m]] &&
                    !slv_w_busy[s]) begin
                    slv_aw_sel_valid[s] = 1'b1;
                    slv_aw_sel_mst[s]   = m;
                end
            end else if (!slv_w_busy[s]) begin
                found = 1'b0;
                for (k = 0; k < NUM_MST; k++) begin
                    i = (slv_aw_rr[s] + k) % NUM_MST;
                    if (!found &&
                        aw_fifo_count[i] > 0 &&
                        aw_fifo_target[i][aw_fifo_head[i]] == s &&
                        !aw_fifo_aw_sent[i][aw_fifo_head[i]]) begin
                        found = 1'b1;
                        slv_aw_sel_valid[s] = 1'b1;
                        slv_aw_sel_mst[s]   = i;
                    end
                end
            end
        end

        // AR selection per slave
        for (s = 0; s < NUM_SLV; s++) begin
            if (slv_ar_lock[s]) begin
                m = slv_ar_lock_mst[s];
                if (ar_fifo_count[m] > 0 &&
                    ar_fifo_target[m][ar_fifo_head[m]] == s) begin
                    slv_ar_sel_valid[s] = 1'b1;
                    slv_ar_sel_mst[s]   = m;
                end
            end else begin
                found = 1'b0;
                for (k = 0; k < NUM_MST; k++) begin
                    i = (slv_ar_rr[s] + k) % NUM_MST;
                    if (!found &&
                        ar_fifo_count[i] > 0 &&
                        ar_fifo_target[i][ar_fifo_head[i]] == s) begin
                        found = 1'b1;
                        slv_ar_sel_valid[s] = 1'b1;
                        slv_ar_sel_mst[s]   = i;
                    end
                end
            end
        end

        // R selection per master
        for (m = 0; m < NUM_MST; m++) begin
            if (mst_r_lock[m]) begin
                sel_src = mst_r_lock_sel[m];
                if (sel_src == TGT_LOCAL) begin
                    if (local_rd_active[m]) begin
                        mst_r_sel_valid[m] = 1'b1;
                        mst_r_sel_src[m]   = TGT_LOCAL;
                    end
                end else begin
                    s = sel_src;
                    if (slv_resp[s].r_valid && slv_resp[s].r.id[5:4] == m[1:0]) begin
                        mst_r_sel_valid[m] = 1'b1;
                        mst_r_sel_src[m]   = s;
                    end
                end
            end else begin
                if (local_rd_active[m]) begin
                    mst_r_sel_valid[m] = 1'b1;
                    mst_r_sel_src[m]   = TGT_LOCAL;
                end else begin
                    found = 1'b0;
                    for (k = 0; k < NUM_SLV; k++) begin
                        s = (mst_r_rr[m] + k) % NUM_SLV;
                        if (!found && slv_resp[s].r_valid && slv_resp[s].r.id[5:4] == m[1:0]) begin
                            found = 1'b1;
                            mst_r_sel_valid[m] = 1'b1;
                            mst_r_sel_src[m]   = s;
                        end
                    end
                end
            end
        end

        // B selection per master
        for (m = 0; m < NUM_MST; m++) begin
            if (b_fifo_count[m] < 4) begin
                found = 1'b0;
                for (k = 0; k < NUM_SLV; k++) begin
                    s = (mst_b_rr[m] + k) % NUM_SLV;
                    if (!found && slv_resp[s].b_valid && slv_resp[s].b.id[5:4] == m[1:0]) begin
                        found = 1'b1;
                        mst_b_sel_valid[m] = 1'b1;
                        mst_b_sel_slv[m]   = s;
                    end
                end
            end
        end
    end

    // ------------------------------------------------------------------------
    // Output assignments
    // ------------------------------------------------------------------------
    always_comb begin
        integer m, s, i;

        for (m = 0; m < NUM_MST; m++) begin
            // AW ready
            mst_resp[m].aw_ready = (aw_fifo_count[m] < MAX_TRANS) &&
                                   !busy_wr[m][mst_req[m].aw.id] &&
                                   (out_wr_cnt[m] < MAX_TRANS);

            // AR ready
            mst_resp[m].ar_ready = (ar_fifo_count[m] < MAX_TRANS) &&
                                   !busy_rd[m][mst_req[m].ar.id] &&
                                   (out_rd_cnt[m] < MAX_TRANS);

            // W ready
            if (w_active[m] && aw_fifo_count[m] > 0) begin
                if (aw_fifo_target[m][aw_fifo_head[m]] == TGT_LOCAL) begin
                    mst_resp[m].w_ready = 1'b1;
                end else begin
                    s = aw_fifo_target[m][aw_fifo_head[m]];
                    mst_resp[m].w_ready = slv_resp[s].w_ready &&
                                          slv_w_busy[s] &&
                                          (slv_w_mst[s] == m);
                end
            end else begin
                mst_resp[m].w_ready = 1'b0;
            end

            // B valid and data
            mst_resp[m].b_valid = (b_fifo_count[m] > 0);
            if (b_fifo_count[m] > 0) begin
                mst_resp[m].b.id   = b_fifo_id[m][b_fifo_head[m]];
                mst_resp[m].b.resp = b_fifo_resp[m][b_fifo_head[m]];
                mst_resp[m].b.user = b_fifo_user[m][b_fifo_head[m]];
            end else begin
                mst_resp[m].b = '0;
            end

            // R valid and data
            mst_resp[m].r_valid = mst_r_sel_valid[m];
            if (mst_r_sel_valid[m]) begin
                if (mst_r_sel_src[m] == TGT_LOCAL) begin
                    mst_resp[m].r.id   = local_rd_id[m];
                    mst_resp[m].r.data = '0;
                    mst_resp[m].r.resp = RESP_DECERR;
                    mst_resp[m].r.last = (local_rd_rem[m] == 0);
                    mst_resp[m].r.user = '0;
                end else begin
                    s = mst_r_sel_src[m];
                    mst_resp[m].r.id   = slv_resp[s].r.id[3:0];
                    mst_resp[m].r.data = slv_resp[s].r.data;
                    mst_resp[m].r.resp = slv_resp[s].r.resp;
                    mst_resp[m].r.last = slv_resp[s].r.last;
                    mst_resp[m].r.user = slv_resp[s].r.user;
                end
            end else begin
                mst_resp[m].r = '0;
            end
        end

        for (s = 0; s < NUM_SLV; s++) begin
            // AW
            slv_req[s].aw_valid = slv_aw_sel_valid[s];
            if (slv_aw_sel_valid[s]) begin
                m = slv_aw_sel_mst[s];
                slv_req[s].aw.id     = {m[1:0], aw_fifo_data[m][aw_fifo_head[m]].id};
                slv_req[s].aw.addr   = aw_fifo_data[m][aw_fifo_head[m]].addr;
                slv_req[s].aw.len    = aw_fifo_data[m][aw_fifo_head[m]].len;
                slv_req[s].aw.size   = aw_fifo_data[m][aw_fifo_head[m]].size;
                slv_req[s].aw.burst  = aw_fifo_data[m][aw_fifo_head[m]].burst;
                slv_req[s].aw.lock   = aw_fifo_data[m][aw_fifo_head[m]].lock;
                slv_req[s].aw.cache  = aw_fifo_data[m][aw_fifo_head[m]].cache;
                slv_req[s].aw.prot   = aw_fifo_data[m][aw_fifo_head[m]].prot;
                slv_req[s].aw.qos    = aw_fifo_data[m][aw_fifo_head[m]].qos;
                slv_req[s].aw.region = aw_fifo_data[m][aw_fifo_head[m]].region;
                slv_req[s].aw.atop   = aw_fifo_data[m][aw_fifo_head[m]].atop;
                slv_req[s].aw.user   = aw_fifo_data[m][aw_fifo_head[m]].user;
            end else begin
                slv_req[s].aw = '0;
            end

            // AR
            slv_req[s].ar_valid = slv_ar_sel_valid[s];
            if (slv_ar_sel_valid[s]) begin
                m = slv_ar_sel_mst[s];
                slv_req[s].ar.id     = {m[1:0], ar_fifo_data[m][ar_fifo_head[m]].id};
                slv_req[s].ar.addr   = ar_fifo_data[m][ar_fifo_head[m]].addr;
                slv_req[s].ar.len    = ar_fifo_data[m][ar_fifo_head[m]].len;
                slv_req[s].ar.size   = ar_fifo_data[m][ar_fifo_head[m]].size;
                slv_req[s].ar.burst  = ar_fifo_data[m][ar_fifo_head[m]].burst;
                slv_req[s].ar.lock   = ar_fifo_data[m][ar_fifo_head[m]].lock;
                slv_req[s].ar.cache  = ar_fifo_data[m][ar_fifo_head[m]].cache;
                slv_req[s].ar.prot   = ar_fifo_data[m][ar_fifo_head[m]].prot;
                slv_req[s].ar.qos    = ar_fifo_data[m][ar_fifo_head[m]].qos;
                slv_req[s].ar.region = ar_fifo_data[m][ar_fifo_head[m]].region;
                slv_req[s].ar.user   = ar_fifo_data[m][ar_fifo_head[m]].user;
            end else begin
                slv_req[s].ar = '0;
            end

            // W
            slv_req[s].w_valid = 1'b0;
            slv_req[s].w = '0;
            if (slv_w_busy[s]) begin
                m = slv_w_mst[s];
                if (w_active[m] && aw_fifo_count[m] > 0 &&
                    aw_fifo_target[m][aw_fifo_head[m]] == s) begin
                    slv_req[s].w_valid = mst_req[m].w_valid;
                    slv_req[s].w       = mst_req[m].w;
                end
            end

            // B ready
            slv_req[s].b_ready = 1'b0;
            if (slv_resp[s].b_valid) begin
                m = slv_resp[s].b.id[5:4];
                if (mst_b_sel_valid[m] && mst_b_sel_slv[m] == s) begin
                    slv_req[s].b_ready = 1'b1;
                end
            end

            // R ready
            slv_req[s].r_ready = 1'b0;
            for (m = 0; m < NUM_MST; m++) begin
                if (mst_r_sel_valid[m] && mst_r_sel_src[m] == s) begin
                    slv_req[s].r_ready = mst_req[m].r_ready;
                end
            end
        end
    end

    // ------------------------------------------------------------------------
    // Sequential state updates
    // ------------------------------------------------------------------------
    always_ff @(posedge clk) begin
        integer m, s, i, id;
        logic [TGT_W-1:0] target;
        logic [7:0] len;
        logic [MST_W-1:0] sel_m;
        logic [TGT_W-1:0] sel_src;
        logic ar_enq, ar_deq, aw_enq, aw_deq, b_enq, b_deq, r_last;
        logic [3:0] r_id;

        if (!rst_n) begin
            for (m = 0; m < NUM_MST; m++) begin
                out_rd_cnt[m] <= 0;
                out_wr_cnt[m] <= 0;
                w_active[m] <= 0;
                w_rem[m] <= 0;
                local_rd_active[m] <= 0;
                local_rd_id[m] <= 0;
                local_rd_rem[m] <= 0;
                ar_fifo_head[m] <= 0;
                ar_fifo_tail[m] <= 0;
                ar_fifo_count[m] <= 0;
                aw_fifo_head[m] <= 0;
                aw_fifo_tail[m] <= 0;
                aw_fifo_count[m] <= 0;
                b_fifo_head[m] <= 0;
                b_fifo_tail[m] <= 0;
                b_fifo_count[m] <= 0;
                mst_r_lock[m] <= 0;
                mst_r_lock_sel[m] <= 0;
                mst_r_rr[m] <= 0;
                mst_b_rr[m] <= 0;
                for (i = 0; i < 16; i++) begin
                    busy_rd[m][i] <= 0;
                    busy_wr[m][i] <= 0;
                end
                for (i = 0; i < MAX_TRANS; i++) begin
                    ar_fifo_valid[m][i] <= 0;
                    aw_fifo_valid[m][i] <= 0;
                    aw_fifo_aw_sent[m][i] <= 0;
                end
                for (i = 0; i < 4; i++) begin
                    b_fifo_valid[m][i] <= 0;
                end
            end
            for (s = 0; s < NUM_SLV; s++) begin
                slv_aw_lock[s] <= 0;
                slv_aw_lock_mst[s] <= 0;
                slv_aw_rr[s] <= 0;
                slv_ar_lock[s] <= 0;
                slv_ar_lock_mst[s] <= 0;
                slv_ar_rr[s] <= 0;
                slv_w_busy[s] <= 0;
                slv_w_mst[s] <= 0;
            end
        end else begin
            // 1. Master AW enqueue
            for (m = 0; m < NUM_MST; m++) begin
                if (mst_req[m].aw_valid && mst_resp[m].aw_ready) begin
                    target = TGT_LOCAL;
                    for (s = 0; s < NUM_SLV; s++) begin
                        if (mst_req[m].aw.addr >= addr_map[s].start_addr &&
                            mst_req[m].aw.addr <  addr_map[s].end_addr) begin
                            target = s;
                        end
                    end
                    aw_fifo_valid[m][aw_fifo_tail[m]] <= 1'b1;
                    aw_fifo_target[m][aw_fifo_tail[m]] <= target;
                    aw_fifo_id[m][aw_fifo_tail[m]] <= mst_req[m].aw.id;
                    aw_fifo_len[m][aw_fifo_tail[m]] <= mst_req[m].aw.len;
                    aw_fifo_aw_sent[m][aw_fifo_tail[m]] <= (target == TGT_LOCAL);
                    aw_fifo_data[m][aw_fifo_tail[m]] <= mst_req[m].aw;
                    aw_fifo_tail[m] <= (aw_fifo_tail[m] + 1) % MAX_TRANS;
                end
            end

            // 2. Master AR enqueue
            for (m = 0; m < NUM_MST; m++) begin
                if (mst_req[m].ar_valid && mst_resp[m].ar_ready) begin
                    target = TGT_LOCAL;
                    for (s = 0; s < NUM_SLV; s++) begin
                        if (mst_req[m].ar.addr >= addr_map[s].start_addr &&
                            mst_req[m].ar.addr <  addr_map[s].end_addr) begin
                            target = s;
                        end
                    end
                    ar_fifo_valid[m][ar_fifo_tail[m]] <= 1'b1;
                    ar_fifo_target[m][ar_fifo_tail[m]] <= target;
                    ar_fifo_id[m][ar_fifo_tail[m]] <= mst_req[m].ar.id;
                    ar_fifo_len[m][ar_fifo_tail[m]] <= mst_req[m].ar.len;
                    ar_fifo_data[m][ar_fifo_tail[m]] <= mst_req[m].ar;
                    ar_fifo_tail[m] <= (ar_fifo_tail[m] + 1) % MAX_TRANS;
                end
            end

            // 3. AW forwarding handshake
            for (s = 0; s < NUM_SLV; s++) begin
                if (slv_req[s].aw_valid && slv_resp[s].aw_ready) begin
                    m = slv_aw_sel_mst[s];
                    aw_fifo_aw_sent[m][aw_fifo_head[m]] <= 1'b1;
                    slv_w_busy[s] <= 1'b1;
                    slv_w_mst[s] <= m;
                    slv_aw_lock[s] <= 1'b0;
                    slv_aw_rr[s] <= (m + 1) % NUM_MST;
                end else if (slv_req[s].aw_valid && !slv_resp[s].aw_ready) begin
                    slv_aw_lock[s] <= 1'b1;
                    slv_aw_lock_mst[s] <= slv_aw_sel_mst[s];
                end else begin
                    slv_aw_lock[s] <= 1'b0;
                end
            end

            // 4. AR forwarding handshake
            for (s = 0; s < NUM_SLV; s++) begin
                if (slv_req[s].ar_valid && slv_resp[s].ar_ready) begin
                    m = slv_ar_sel_mst[s];
                    ar_fifo_valid[m][ar_fifo_head[m]] <= 1'b0;
                    ar_fifo_head[m] <= (ar_fifo_head[m] + 1) % MAX_TRANS;
                    slv_ar_lock[s] <= 1'b0;
                    slv_ar_rr[s] <= (m + 1) % NUM_MST;
                end else if (slv_req[s].ar_valid && !slv_resp[s].ar_ready) begin
                    slv_ar_lock[s] <= 1'b1;
                    slv_ar_lock_mst[s] <= slv_ar_sel_mst[s];
                end else begin
                    slv_ar_lock[s] <= 1'b0;
                end
            end

            // 5. Local read start
            for (m = 0; m < NUM_MST; m++) begin
                if (!local_rd_active[m] && ar_fifo_count[m] > 0 &&
                    ar_fifo_target[m][ar_fifo_head[m]] == TGT_LOCAL) begin
                    local_rd_active[m] <= 1'b1;
                    local_rd_id[m] <= ar_fifo_id[m][ar_fifo_head[m]];
                    local_rd_rem[m] <= ar_fifo_len[m][ar_fifo_head[m]];
                    ar_fifo_valid[m][ar_fifo_head[m]] <= 1'b0;
                    ar_fifo_head[m] <= (ar_fifo_head[m] + 1) % MAX_TRANS;
                end
            end

            // 6. Local read response handshake
            for (m = 0; m < NUM_MST; m++) begin
                if (local_rd_active[m] && mst_resp[m].r_valid && mst_req[m].r_ready &&
                    mst_r_sel_src[m] == TGT_LOCAL) begin
                    if (local_rd_rem[m] == 0) begin
                        local_rd_active[m] <= 1'b0;
                    end else begin
                        local_rd_rem[m] <= local_rd_rem[m] - 1;
                    end
                end
            end

            // 7. W forwarding handshake and AW FIFO pop
            for (m = 0; m < NUM_MST; m++) begin
                if (w_active[m] && mst_req[m].w_valid && mst_resp[m].w_ready) begin
                    if (w_rem[m] == 0) begin
                        aw_fifo_valid[m][aw_fifo_head[m]] <= 1'b0;
                        aw_fifo_head[m] <= (aw_fifo_head[m] + 1) % MAX_TRANS;
                        w_active[m] <= 1'b0;
                        if (aw_fifo_target[m][aw_fifo_head[m]] == TGT_LOCAL) begin
                            b_fifo_valid[m][b_fifo_tail[m]] <= 1'b1;
                            b_fifo_id[m][b_fifo_tail[m]] <= aw_fifo_id[m][aw_fifo_head[m]];
                            b_fifo_resp[m][b_fifo_tail[m]] <= RESP_DECERR;
                            b_fifo_user[m][b_fifo_tail[m]] <= 1'b0;
                            b_fifo_tail[m] <= (b_fifo_tail[m] + 1) % 4;
                        end else begin
                            slv_w_busy[aw_fifo_target[m][aw_fifo_head[m]]] <= 1'b0;
                        end
                    end else begin
                        w_rem[m] <= w_rem[m] - 1;
                    end
                end else if (!w_active[m] && aw_fifo_count[m] > 0 &&
                             aw_fifo_aw_sent[m][aw_fifo_head[m]]) begin
                    w_active[m] <= 1'b1;
                    w_rem[m] <= aw_fifo_len[m][aw_fifo_head[m]];
                end
            end

            // 8. B response from slave to master FIFO
            for (m = 0; m < NUM_MST; m++) begin
                if (mst_b_sel_valid[m]) begin
                    s = mst_b_sel_slv[m];
                    if (slv_resp[s].b_valid && slv_req[s].b_ready) begin
                        b_fifo_valid[m][b_fifo_tail[m]] <= 1'b1;
                        b_fifo_id[m][b_fifo_tail[m]] <= slv_resp[s].b.id[3:0];
                        b_fifo_resp[m][b_fifo_tail[m]] <= slv_resp[s].b.resp;
                        b_fifo_user[m][b_fifo_tail[m]] <= slv_resp[s].b.user;
                        b_fifo_tail[m] <= (b_fifo_tail[m] + 1) % 4;
                    end
                end
            end

            // 9. B response to master (pop B FIFO)
            for (m = 0; m < NUM_MST; m++) begin
                if (mst_resp[m].b_valid && mst_req[m].b_ready) begin
                    b_fifo_valid[m][b_fifo_head[m]] <= 1'b0;
                    b_fifo_head[m] <= (b_fifo_head[m] + 1) % 4;
                end
            end

            // 10. R response from slave to master (handshake)
            for (m = 0; m < NUM_MST; m++) begin
                if (mst_r_sel_valid[m] && mst_r_sel_src[m] != TGT_LOCAL) begin
                    s = mst_r_sel_src[m];
                    if (slv_resp[s].r_valid && mst_req[m].r_ready) begin
                        mst_r_rr[m] <= (s + 1) % NUM_SLV;
                    end
                end
            end

            // 11. R lock update
            for (m = 0; m < NUM_MST; m++) begin
                if (mst_resp[m].r_valid && !mst_req[m].r_ready) begin
                    mst_r_lock[m] <= 1'b1;
                    mst_r_lock_sel[m] <= mst_r_sel_src[m];
                end else if (mst_resp[m].r_valid && mst_req[m].r_ready) begin
                    mst_r_lock[m] <= 1'b0;
                end else if (!mst_resp[m].r_valid) begin
                    mst_r_lock[m] <= 1'b0;
                end
            end

            // 12. B round-robin update
            for (m = 0; m < NUM_MST; m++) begin
                if (mst_b_sel_valid[m] &&
                    slv_resp[mst_b_sel_slv[m]].b_valid &&
                    slv_req[mst_b_sel_slv[m]].b_ready) begin
                    mst_b_rr[m] <= (mst_b_sel_slv[m] + 1) % NUM_SLV;
                end
            end

            // 13. Update FIFO counts and outstanding/busy tracking
            for (m = 0; m < NUM_MST; m++) begin
                // AR FIFO count
                ar_enq = mst_req[m].ar_valid && mst_resp[m].ar_ready;
                ar_deq = 1'b0;
                for (s = 0; s < NUM_SLV; s++) begin
                    if (slv_req[s].ar_valid && slv_resp[s].ar_ready &&
                        slv_ar_sel_mst[s] == m) ar_deq = 1'b1;
                end
                if (!local_rd_active[m] && ar_fifo_count[m] > 0 &&
                    ar_fifo_target[m][ar_fifo_head[m]] == TGT_LOCAL) ar_deq = 1'b1;
                ar_fifo_count[m] <= ar_fifo_count[m] + (ar_enq ? 1 : 0) - (ar_deq ? 1 : 0);

                // AW FIFO count
                aw_enq = mst_req[m].aw_valid && mst_resp[m].aw_ready;
                aw_deq = 1'b0;
                if (w_active[m] && mst_req[m].w_valid && mst_resp[m].w_ready &&
                    w_rem[m] == 0) aw_deq = 1'b1;
                aw_fifo_count[m] <= aw_fifo_count[m] + (aw_enq ? 1 : 0) - (aw_deq ? 1 : 0);

                // B FIFO count
                b_enq = 1'b0;
                if (w_active[m] && mst_req[m].w_valid && mst_resp[m].w_ready &&
                    w_rem[m] == 0 &&
                    aw_fifo_target[m][aw_fifo_head[m]] == TGT_LOCAL) b_enq = 1'b1;
                if (mst_b_sel_valid[m] &&
                    slv_resp[mst_b_sel_slv[m]].b_valid &&
                    slv_req[mst_b_sel_slv[m]].b_ready) b_enq = 1'b1;
                b_deq = mst_resp[m].b_valid && mst_req[m].b_ready;
                b_fifo_count[m] <= b_fifo_count[m] + (b_enq ? 1 : 0) - (b_deq ? 1 : 0);

                // R last detection
                r_last = 1'b0;
                r_id = 4'd0;
                if (mst_r_sel_valid[m] && mst_r_sel_src[m] != TGT_LOCAL) begin
                    s = mst_r_sel_src[m];
                    if (slv_resp[s].r_valid && mst_req[m].r_ready && slv_resp[s].r.last) begin
                        r_last = 1'b1;
                        r_id = slv_resp[s].r.id[3:0];
                    end
                end
                if (local_rd_active[m] && mst_resp[m].r_valid && mst_req[m].r_ready &&
                    mst_r_sel_src[m] == TGT_LOCAL && local_rd_rem[m] == 0) begin
                    r_last = 1'b1;
                    r_id = local_rd_id[m];
                end

                // Outstanding counters
                out_rd_cnt[m] <= out_rd_cnt[m] + (ar_enq ? 1 : 0) - (r_last ? 1 : 0);
                out_wr_cnt[m] <= out_wr_cnt[m] + (aw_enq ? 1 : 0) - (b_deq ? 1 : 0);

                // Busy read IDs
                for (i = 0; i < 16; i++) begin
                    if (ar_enq && mst_req[m].ar.id == i) begin
                        busy_rd[m][i] <= 1'b1;
                    end else if (r_last && r_id == i) begin
                        busy_rd[m][i] <= 1'b0;
                    end
                end

                // Busy write IDs
                for (i = 0; i < 16; i++) begin
                    if (aw_enq && mst_req[m].aw.id == i) begin
                        busy_wr[m][i] <= 1'b1;
                    end else if (b_deq && b_fifo_id[m][b_fifo_head[m]] == i) begin
                        busy_wr[m][i] <= 1'b0;
                    end
                end
            end
        end
    end

endmodule
