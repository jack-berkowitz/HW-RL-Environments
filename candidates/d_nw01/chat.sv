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

    localparam int PTR_W =
        (MAX_TRANS <= 2) ? 1 : $clog2(MAX_TRANS);

    localparam int CNT_W =
        $clog2(MAX_TRANS + 1);

    localparam int SRC_W =
        $clog2(NUM_SLV + 1);

    typedef logic [MST_IDX_W-1:0] mst_index_t;
    typedef logic [SRC_W-1:0]     src_index_t;


    /*
     * ========================================================================
     * Request metadata FIFOs
     * ========================================================================
     *
     * These store transaction metadata only.  W and R data beats are not
     * buffered here.
     */

    typedef struct packed {
        slv_aw_t   aw;
        logic      mapped;
        mst_index_t target;
    } aw_meta_t;

    typedef struct packed {
        slv_ar_t   ar;
        logic      mapped;
        mst_index_t target;
    } ar_meta_t;


    aw_meta_t aw_fifo_q [0:NUM_MST-1][0:MAX_TRANS-1];
    ar_meta_t ar_fifo_q [0:NUM_MST-1][0:MAX_TRANS-1];

    logic [PTR_W-1:0] aw_head_q [0:NUM_MST-1];
    logic [PTR_W-1:0] aw_tail_q [0:NUM_MST-1];
    logic [CNT_W-1:0] aw_count_q [0:NUM_MST-1];

    logic [PTR_W-1:0] ar_head_q [0:NUM_MST-1];
    logic [PTR_W-1:0] ar_tail_q [0:NUM_MST-1];
    logic [CNT_W-1:0] ar_count_q [0:NUM_MST-1];

    aw_meta_t aw_head_c [0:NUM_MST-1];
    ar_meta_t ar_head_c [0:NUM_MST-1];


    /*
     * Outstanding transaction counts.
     */
    logic [CNT_W-1:0] wr_out_count_q [0:NUM_MST-1];
    logic [CNT_W-1:0] rd_out_count_q [0:NUM_MST-1];

    logic [CNT_W:0] total_out_c [0:NUM_MST-1];


    /*
     * One outstanding transaction per ID per direction.
     *
     * This is intentionally stricter than AXI requires, but preserves O1
     * across different destination slaves without any response reorder buffer.
     *
     * There are 16 possible slave-side IDs.
     */
    logic [15:0] wr_id_busy_q [0:NUM_MST-1];
    logic [15:0] rd_id_busy_q [0:NUM_MST-1];


    /*
     * When exactly one outstanding-capacity slot remains, this registered turn
     * bit chooses whether AW or AR may use it.  Thus the two channels cannot
     * overbook the final slot, while neither channel can starve.
     */
    logic cap_turn_q [0:NUM_MST-1];


    /*
     * ========================================================================
     * Address decode
     * ========================================================================
     */

    logic       aw_dec_mapped_c [0:NUM_MST-1];
    logic       ar_dec_mapped_c [0:NUM_MST-1];

    mst_index_t aw_dec_target_c [0:NUM_MST-1];
    mst_index_t ar_dec_target_c [0:NUM_MST-1];


    always_comb begin : decode_comb
        integer m;
        integer r;

        for (m = 0; m < NUM_MST; m = m + 1) begin

            aw_head_c[m] = aw_fifo_q[m][aw_head_q[m]];
            ar_head_c[m] = ar_fifo_q[m][ar_head_q[m]];

            aw_dec_mapped_c[m] = 1'b0;
            ar_dec_mapped_c[m] = 1'b0;

            aw_dec_target_c[m] = '0;
            ar_dec_target_c[m] = '0;

            for (r = 0; r < NUM_SLV; r = r + 1) begin

                if (
                    (mst_req[m].aw.addr >= addr_map[r].start_addr) &&
                    (mst_req[m].aw.addr <  addr_map[r].end_addr)
                ) begin
                    aw_dec_mapped_c[m] =
                        1'b1;

                    aw_dec_target_c[m] =
                        addr_map[r].mst_port[MST_IDX_W-1:0];
                end

                if (
                    (mst_req[m].ar.addr >= addr_map[r].start_addr) &&
                    (mst_req[m].ar.addr <  addr_map[r].end_addr)
                ) begin
                    ar_dec_mapped_c[m] =
                        1'b1;

                    ar_dec_target_c[m] =
                        addr_map[r].mst_port[MST_IDX_W-1:0];
                end

            end
        end
    end


    /*
     * ========================================================================
     * ID conversion helpers
     * ========================================================================
     */

    function automatic mst_aw_t widen_aw(
        input slv_aw_t     x,
        input mst_index_t  master
    );
        mst_aw_t y;

        begin
            y = '0;

            y.id     = {master, x.id};
            y.addr   = x.addr;
            y.len    = x.len;
            y.size   = x.size;
            y.burst  = x.burst;
            y.lock   = x.lock;
            y.cache  = x.cache;
            y.prot   = x.prot;
            y.qos    = x.qos;
            y.region = x.region;
            y.atop   = x.atop;
            y.user   = x.user;

            widen_aw = y;
        end
    endfunction


    function automatic mst_ar_t widen_ar(
        input slv_ar_t     x,
        input mst_index_t  master
    );
        mst_ar_t y;

        begin
            y = '0;

            y.id     = {master, x.id};
            y.addr   = x.addr;
            y.len    = x.len;
            y.size   = x.size;
            y.burst  = x.burst;
            y.lock   = x.lock;
            y.cache  = x.cache;
            y.prot   = x.prot;
            y.qos    = x.qos;
            y.region = x.region;
            y.user   = x.user;

            widen_ar = y;
        end
    endfunction


    function automatic slv_b_t narrow_b(
        input mst_b_t x
    );
        slv_b_t y;

        begin
            y = '0;

            y.id   = x.id[SLV_ID_W-1:0];
            y.resp = x.resp;
            y.user = x.user;

            narrow_b = y;
        end
    endfunction


    function automatic slv_r_t narrow_r(
        input mst_r_t x
    );
        slv_r_t y;

        begin
            y = '0;

            y.id   = x.id[SLV_ID_W-1:0];
            y.data = x.data;
            y.resp = x.resp;
            y.last = x.last;
            y.user = x.user;

            narrow_r = y;
        end
    endfunction


    /*
     * ========================================================================
     * Input acceptance
     * ========================================================================
     */

    logic aw_ready_c [0:NUM_MST-1];
    logic ar_ready_c [0:NUM_MST-1];

    logic aw_push_c [0:NUM_MST-1];
    logic ar_push_c [0:NUM_MST-1];

    logic cap_aw_ok_c [0:NUM_MST-1];
    logic cap_ar_ok_c [0:NUM_MST-1];


    always_comb begin : input_accept_comb
        integer m;

        for (m = 0; m < NUM_MST; m = m + 1) begin

            total_out_c[m] =
                wr_out_count_q[m] +
                rd_out_count_q[m];

            cap_aw_ok_c[m] = 1'b0;
            cap_ar_ok_c[m] = 1'b0;

            /*
             * Two or more free transaction slots: both channels may accept.
             */
            if (total_out_c[m] <= (MAX_TRANS - 2)) begin

                cap_aw_ok_c[m] = 1'b1;
                cap_ar_ok_c[m] = 1'b1;

            end
            /*
             * Exactly one slot remains.
             */
            else if (total_out_c[m] < MAX_TRANS) begin

                if (!cap_turn_q[m])
                    cap_aw_ok_c[m] = 1'b1;
                else
                    cap_ar_ok_c[m] = 1'b1;

            end

            aw_ready_c[m] =
                rst_n &&
                cap_aw_ok_c[m] &&
                (aw_count_q[m] < MAX_TRANS) &&
                !wr_id_busy_q[m][mst_req[m].aw.id];

            ar_ready_c[m] =
                rst_n &&
                cap_ar_ok_c[m] &&
                (ar_count_q[m] < MAX_TRANS) &&
                !rd_id_busy_q[m][mst_req[m].ar.id];

            aw_push_c[m] =
                mst_req[m].aw_valid &&
                aw_ready_c[m];

            ar_push_c[m] =
                mst_req[m].ar_valid &&
                ar_ready_c[m];

        end
    end


    /*
     * ========================================================================
     * Write-data ownership
     * ========================================================================
     *
     * Only one dispatched write transaction per source master is allowed at a
     * time.  Its metadata FIFO may nevertheless contain MAX_TRANS accepted AWs.
     *
     * A destination slave is reserved from AW handshake through WLAST.
     */

    logic       wr_active_q [0:NUM_MST-1];
    logic       wr_mapped_q [0:NUM_MST-1];

    mst_index_t wr_target_q [0:NUM_MST-1];
    slv_id_t    wr_id_q     [0:NUM_MST-1];

    logic       wr_owner_valid_q [0:NUM_SLV-1];
    mst_index_t wr_owner_q       [0:NUM_SLV-1];


    /*
     * Local DECERR write response.
     */
    logic    local_b_pending_q [0:NUM_MST-1];
    slv_id_t local_b_id_q      [0:NUM_MST-1];


    /*
     * Local DECERR read generator.
     */
    logic       local_r_active_q [0:NUM_MST-1];
    slv_id_t    local_r_id_q     [0:NUM_MST-1];
    logic [8:0] local_r_left_q   [0:NUM_MST-1];


    logic decerr_wr_start_c [0:NUM_MST-1];
    logic decerr_rd_start_c [0:NUM_MST-1];


    always_comb begin : decerr_start_comb
        integer m;

        for (m = 0; m < NUM_MST; m = m + 1) begin

            decerr_wr_start_c[m] =
                rst_n &&
                (aw_count_q[m] != 0) &&
                !aw_head_c[m].mapped &&
                !wr_active_q[m] &&
                !local_b_pending_q[m];

            decerr_rd_start_c[m] =
                rst_n &&
                (ar_count_q[m] != 0) &&
                !ar_head_c[m].mapped &&
                !local_r_active_q[m];

        end
    end


    /*
     * ========================================================================
     * AW / AR round-robin arbitration
     * ========================================================================
     */

    mst_index_t aw_rr_q [0:NUM_SLV-1];
    mst_index_t ar_rr_q [0:NUM_SLV-1];

    logic       aw_lock_valid_q [0:NUM_SLV-1];
    logic       ar_lock_valid_q [0:NUM_SLV-1];

    mst_index_t aw_lock_m_q [0:NUM_SLV-1];
    mst_index_t ar_lock_m_q [0:NUM_SLV-1];

    logic       aw_sel_valid_c [0:NUM_SLV-1];
    logic       ar_sel_valid_c [0:NUM_SLV-1];

    mst_index_t aw_sel_m_c [0:NUM_SLV-1];
    mst_index_t ar_sel_m_c [0:NUM_SLV-1];

    logic aw_issue_c [0:NUM_SLV-1];
    logic ar_issue_c [0:NUM_SLV-1];

    logic aw_pop_c [0:NUM_MST-1];
    logic ar_pop_c [0:NUM_MST-1];


    always_comb begin : request_select_comb
        integer s;
        integer j;
        integer idx;
        integer m;

        for (s = 0; s < NUM_SLV; s = s + 1) begin

            aw_sel_valid_c[s] = 1'b0;
            ar_sel_valid_c[s] = 1'b0;

            aw_sel_m_c[s] = '0;
            ar_sel_m_c[s] = '0;


            /*
             * AW selection.
             *
             * A locked selection is retained until the slave accepts it.
             */
            if (aw_lock_valid_q[s]) begin

                m = aw_lock_m_q[s];

                if (
                    (aw_count_q[m] != 0) &&
                    aw_head_c[m].mapped &&
                    (aw_head_c[m].target == mst_index_t'(s)) &&
                    !wr_active_q[m] &&
                    !wr_owner_valid_q[s]
                ) begin
                    aw_sel_valid_c[s] = 1'b1;
                    aw_sel_m_c[s]     = aw_lock_m_q[s];
                end

            end
            else if (!wr_owner_valid_q[s]) begin

                for (j = 0; j < NUM_MST; j = j + 1) begin

                    idx = aw_rr_q[s] + j;

                    if (idx >= NUM_MST)
                        idx = idx - NUM_MST;

                    if (
                        !aw_sel_valid_c[s] &&
                        (aw_count_q[idx] != 0) &&
                        aw_head_c[idx].mapped &&
                        (aw_head_c[idx].target == mst_index_t'(s)) &&
                        !wr_active_q[idx]
                    ) begin
                        aw_sel_valid_c[s] = 1'b1;
                        aw_sel_m_c[s]     = mst_index_t'(idx);
                    end

                end
            end


            /*
             * AR selection.
             */
            if (ar_lock_valid_q[s]) begin

                m = ar_lock_m_q[s];

                if (
                    (ar_count_q[m] != 0) &&
                    ar_head_c[m].mapped &&
                    (ar_head_c[m].target == mst_index_t'(s))
                ) begin
                    ar_sel_valid_c[s] = 1'b1;
                    ar_sel_m_c[s]     = ar_lock_m_q[s];
                end

            end
            else begin

                for (j = 0; j < NUM_MST; j = j + 1) begin

                    idx = ar_rr_q[s] + j;

                    if (idx >= NUM_MST)
                        idx = idx - NUM_MST;

                    if (
                        !ar_sel_valid_c[s] &&
                        (ar_count_q[idx] != 0) &&
                        ar_head_c[idx].mapped &&
                        (ar_head_c[idx].target == mst_index_t'(s))
                    ) begin
                        ar_sel_valid_c[s] = 1'b1;
                        ar_sel_m_c[s]     = mst_index_t'(idx);
                    end

                end
            end


            aw_issue_c[s] =
                rst_n &&
                aw_sel_valid_c[s] &&
                slv_resp[s].aw_ready;

            ar_issue_c[s] =
                rst_n &&
                ar_sel_valid_c[s] &&
                slv_resp[s].ar_ready;

        end


        for (m = 0; m < NUM_MST; m = m + 1) begin

            aw_pop_c[m] =
                decerr_wr_start_c[m];

            ar_pop_c[m] =
                decerr_rd_start_c[m];

            for (s = 0; s < NUM_SLV; s = s + 1) begin

                if (
                    aw_issue_c[s] &&
                    (aw_sel_m_c[s] == mst_index_t'(m))
                )
                    aw_pop_c[m] = 1'b1;

                if (
                    ar_issue_c[s] &&
                    (ar_sel_m_c[s] == mst_index_t'(m))
                )
                    ar_pop_c[m] = 1'b1;

            end

        end
    end


    /*
     * ========================================================================
     * W routing
     * ========================================================================
     */

    logic w_ready_c [0:NUM_MST-1];
    logic w_fire_c  [0:NUM_MST-1];


    always_comb begin : write_data_control_comb
        integer m;
        integer s;
        integer owner;

        for (m = 0; m < NUM_MST; m = m + 1)
            w_ready_c[m] = 1'b0;


        /*
         * Unmapped write: consume W locally.
         */
        for (m = 0; m < NUM_MST; m = m + 1) begin

            if (
                wr_active_q[m] &&
                !wr_mapped_q[m]
            )
                w_ready_c[m] = rst_n;

        end


        /*
         * Mapped write: selected destination's WREADY.
         */
        for (s = 0; s < NUM_SLV; s = s + 1) begin

            if (wr_owner_valid_q[s]) begin

                owner = wr_owner_q[s];

                w_ready_c[owner] =
                    rst_n &&
                    slv_resp[s].w_ready;

            end

        end


        for (m = 0; m < NUM_MST; m = m + 1) begin

            w_fire_c[m] =
                rst_n &&
                mst_req[m].w_valid &&
                w_ready_c[m];

        end
    end


    /*
     * ========================================================================
     * B response arbitration
     * ========================================================================
     */

    src_index_t b_rr_q [0:NUM_MST-1];
    src_index_t r_rr_q [0:NUM_MST-1];

    logic       b_lock_valid_q [0:NUM_MST-1];
    logic       r_lock_valid_q [0:NUM_MST-1];

    src_index_t b_lock_src_q [0:NUM_MST-1];
    src_index_t r_lock_src_q [0:NUM_MST-1];

    logic       b_sel_valid_c [0:NUM_MST-1];
    logic       r_sel_valid_c [0:NUM_MST-1];

    src_index_t b_sel_src_c [0:NUM_MST-1];
    src_index_t r_sel_src_c [0:NUM_MST-1];

    slv_b_t b_payload_c [0:NUM_MST-1];
    slv_r_t r_payload_c [0:NUM_MST-1];


    always_comb begin : response_select_comb
        integer m;
        integer j;
        integer idx;

        for (m = 0; m < NUM_MST; m = m + 1) begin

            b_sel_valid_c[m] = 1'b0;
            r_sel_valid_c[m] = 1'b0;

            b_sel_src_c[m] = '0;
            r_sel_src_c[m] = '0;

            b_payload_c[m] = '0;
            r_payload_c[m] = '0;


            /*
             * --------------------------------------------------------------
             * B
             * --------------------------------------------------------------
             */
            if (b_lock_valid_q[m]) begin

                idx = b_lock_src_q[m];

                if (idx < NUM_SLV) begin

                    if (
                        slv_resp[idx].b_valid &&
                        (
                            slv_resp[idx].b.id[
                                MST_ID_W-1 -: MST_IDX_W
                            ] ==
                            mst_index_t'(m)
                        )
                    ) begin
                        b_sel_valid_c[m] = 1'b1;
                        b_sel_src_c[m]   = b_lock_src_q[m];
                        b_payload_c[m]   = narrow_b(slv_resp[idx].b);
                    end

                end
                else begin

                    if (local_b_pending_q[m]) begin
                        b_sel_valid_c[m] = 1'b1;
                        b_sel_src_c[m]   = b_lock_src_q[m];

                        b_payload_c[m].id   = local_b_id_q[m];
                        b_payload_c[m].resp = RESP_DECERR;
                        b_payload_c[m].user = '0;
                    end

                end

            end
            else begin

                for (j = 0; j < (NUM_SLV + 1); j = j + 1) begin

                    idx = b_rr_q[m] + j;

                    if (idx >= (NUM_SLV + 1))
                        idx = idx - (NUM_SLV + 1);

                    if (!b_sel_valid_c[m]) begin

                        if (idx < NUM_SLV) begin

                            if (
                                slv_resp[idx].b_valid &&
                                (
                                    slv_resp[idx].b.id[
                                        MST_ID_W-1 -: MST_IDX_W
                                    ] ==
                                    mst_index_t'(m)
                                )
                            ) begin
                                b_sel_valid_c[m] = 1'b1;
                                b_sel_src_c[m]   = src_index_t'(idx);
                                b_payload_c[m]   = narrow_b(slv_resp[idx].b);
                            end

                        end
                        else if (local_b_pending_q[m]) begin

                            b_sel_valid_c[m] = 1'b1;
                            b_sel_src_c[m]   = src_index_t'(NUM_SLV);

                            b_payload_c[m].id   = local_b_id_q[m];
                            b_payload_c[m].resp = RESP_DECERR;
                            b_payload_c[m].user = '0;

                        end

                    end

                end

            end


            /*
             * --------------------------------------------------------------
             * R
             * --------------------------------------------------------------
             */
            if (r_lock_valid_q[m]) begin

                idx = r_lock_src_q[m];

                if (idx < NUM_SLV) begin

                    if (
                        slv_resp[idx].r_valid &&
                        (
                            slv_resp[idx].r.id[
                                MST_ID_W-1 -: MST_IDX_W
                            ] ==
                            mst_index_t'(m)
                        )
                    ) begin
                        r_sel_valid_c[m] = 1'b1;
                        r_sel_src_c[m]   = r_lock_src_q[m];
                        r_payload_c[m]   = narrow_r(slv_resp[idx].r);
                    end

                end
                else begin

                    if (local_r_active_q[m]) begin

                        r_sel_valid_c[m] = 1'b1;
                        r_sel_src_c[m]   = r_lock_src_q[m];

                        r_payload_c[m].id   = local_r_id_q[m];
                        r_payload_c[m].data = '0;
                        r_payload_c[m].resp = RESP_DECERR;
                        r_payload_c[m].last =
                            (local_r_left_q[m] == 9'd1);
                        r_payload_c[m].user = '0;

                    end

                end

            end
            else begin

                for (j = 0; j < (NUM_SLV + 1); j = j + 1) begin

                    idx = r_rr_q[m] + j;

                    if (idx >= (NUM_SLV + 1))
                        idx = idx - (NUM_SLV + 1);

                    if (!r_sel_valid_c[m]) begin

                        if (idx < NUM_SLV) begin

                            if (
                                slv_resp[idx].r_valid &&
                                (
                                    slv_resp[idx].r.id[
                                        MST_ID_W-1 -: MST_IDX_W
                                    ] ==
                                    mst_index_t'(m)
                                )
                            ) begin
                                r_sel_valid_c[m] = 1'b1;
                                r_sel_src_c[m]   = src_index_t'(idx);
                                r_payload_c[m]   = narrow_r(slv_resp[idx].r);
                            end

                        end
                        else if (local_r_active_q[m]) begin

                            r_sel_valid_c[m] = 1'b1;
                            r_sel_src_c[m]   = src_index_t'(NUM_SLV);

                            r_payload_c[m].id   = local_r_id_q[m];
                            r_payload_c[m].data = '0;
                            r_payload_c[m].resp = RESP_DECERR;
                            r_payload_c[m].last =
                                (local_r_left_q[m] == 9'd1);
                            r_payload_c[m].user = '0;

                        end

                    end

                end

            end

        end
    end


    /*
     * ========================================================================
     * External port generation
     * ========================================================================
     */

    always_comb begin : output_comb
        integer m;
        integer s;
        integer owner;
        integer src;

        mst_resp = '0;
        slv_req  = '0;


        /*
         * --------------------------------------------------------------
         * Master-facing acceptance and responses.
         * --------------------------------------------------------------
         */
        for (m = 0; m < NUM_MST; m = m + 1) begin

            mst_resp[m].aw_ready =
                aw_ready_c[m];

            mst_resp[m].ar_ready =
                ar_ready_c[m];

            mst_resp[m].w_ready =
                w_ready_c[m];

            mst_resp[m].b_valid =
                rst_n &&
                b_sel_valid_c[m];

            mst_resp[m].b =
                b_payload_c[m];

            mst_resp[m].r_valid =
                rst_n &&
                r_sel_valid_c[m];

            mst_resp[m].r =
                r_payload_c[m];

        end


        /*
         * --------------------------------------------------------------
         * AW / AR request fabric.
         * --------------------------------------------------------------
         */
        for (s = 0; s < NUM_SLV; s = s + 1) begin

            if (aw_sel_valid_c[s]) begin

                m = aw_sel_m_c[s];

                slv_req[s].aw_valid =
                    rst_n;

                slv_req[s].aw =
                    widen_aw(
                        aw_head_c[m].aw,
                        aw_sel_m_c[s]
                    );

            end


            if (ar_sel_valid_c[s]) begin

                m = ar_sel_m_c[s];

                slv_req[s].ar_valid =
                    rst_n;

                slv_req[s].ar =
                    widen_ar(
                        ar_head_c[m].ar,
                        ar_sel_m_c[s]
                    );

            end

        end


        /*
         * --------------------------------------------------------------
         * W fabric.
         * --------------------------------------------------------------
         */
        for (s = 0; s < NUM_SLV; s = s + 1) begin

            if (wr_owner_valid_q[s]) begin

                owner = wr_owner_q[s];

                slv_req[s].w_valid =
                    rst_n &&
                    mst_req[owner].w_valid;

                slv_req[s].w =
                    mst_req[owner].w;

            end

        end


        /*
         * --------------------------------------------------------------
         * BREADY / RREADY response return routing.
         * --------------------------------------------------------------
         */
        for (m = 0; m < NUM_MST; m = m + 1) begin

            if (b_sel_valid_c[m]) begin

                src = b_sel_src_c[m];

                if (src < NUM_SLV) begin
                    slv_req[src].b_ready =
                        rst_n &&
                        mst_req[m].b_ready;
                end

            end


            if (r_sel_valid_c[m]) begin

                src = r_sel_src_c[m];

                if (src < NUM_SLV) begin
                    slv_req[src].r_ready =
                        rst_n &&
                        mst_req[m].r_ready;
                end

            end

        end

    end


    /*
     * ========================================================================
     * Response completion signals
     * ========================================================================
     */

    logic b_handshake_c [0:NUM_MST-1];
    logic r_handshake_c [0:NUM_MST-1];

    logic b_done_c [0:NUM_MST-1];
    logic r_done_c [0:NUM_MST-1];


    always_comb begin : response_handshake_comb
        integer m;

        for (m = 0; m < NUM_MST; m = m + 1) begin

            b_handshake_c[m] =
                rst_n &&
                b_sel_valid_c[m] &&
                mst_req[m].b_ready;

            r_handshake_c[m] =
                rst_n &&
                r_sel_valid_c[m] &&
                mst_req[m].r_ready;

            b_done_c[m] =
                b_handshake_c[m];

            r_done_c[m] =
                r_handshake_c[m] &&
                r_payload_c[m].last;

        end
    end


    /*
     * ========================================================================
     * Sequential state
     * ========================================================================
     *
     * Reset is synchronous, active-low.
     */

    always_ff @(posedge clk) begin : state_ff
        integer m;
        integer s;

        if (!rst_n) begin

            for (m = 0; m < NUM_MST; m = m + 1) begin

                aw_head_q[m]  <= '0;
                aw_tail_q[m]  <= '0;
                aw_count_q[m] <= '0;

                ar_head_q[m]  <= '0;
                ar_tail_q[m]  <= '0;
                ar_count_q[m] <= '0;

                wr_out_count_q[m] <= '0;
                rd_out_count_q[m] <= '0;

                wr_id_busy_q[m] <= '0;
                rd_id_busy_q[m] <= '0;

                cap_turn_q[m] <= 1'b0;

                wr_active_q[m] <= 1'b0;
                wr_mapped_q[m] <= 1'b0;
                wr_target_q[m] <= '0;
                wr_id_q[m]     <= '0;

                local_b_pending_q[m] <= 1'b0;
                local_b_id_q[m]      <= '0;

                local_r_active_q[m] <= 1'b0;
                local_r_id_q[m]     <= '0;
                local_r_left_q[m]   <= '0;

                b_rr_q[m] <= '0;
                r_rr_q[m] <= '0;

                b_lock_valid_q[m] <= 1'b0;
                r_lock_valid_q[m] <= 1'b0;

                b_lock_src_q[m] <= '0;
                r_lock_src_q[m] <= '0;

            end


            for (s = 0; s < NUM_SLV; s = s + 1) begin

                wr_owner_valid_q[s] <= 1'b0;
                wr_owner_q[s]       <= '0;

                aw_rr_q[s] <= '0;
                ar_rr_q[s] <= '0;

                aw_lock_valid_q[s] <= 1'b0;
                ar_lock_valid_q[s] <= 1'b0;

                aw_lock_m_q[s] <= '0;
                ar_lock_m_q[s] <= '0;

            end

        end
        else begin

            /*
             * --------------------------------------------------------------
             * Per-master input FIFOs and accounting.
             * --------------------------------------------------------------
             */
            for (m = 0; m < NUM_MST; m = m + 1) begin

                /*
                 * Last-slot arbitration is state-based, not valid-based.
                 */
                if (total_out_c[m] == (MAX_TRANS - 1))
                    cap_turn_q[m] <= ~cap_turn_q[m];


                /*
                 * AW FIFO push.
                 */
                if (aw_push_c[m]) begin

                    aw_fifo_q[m][aw_tail_q[m]].aw <=
                        mst_req[m].aw;

                    aw_fifo_q[m][aw_tail_q[m]].mapped <=
                        aw_dec_mapped_c[m];

                    aw_fifo_q[m][aw_tail_q[m]].target <=
                        aw_dec_target_c[m];

                    aw_tail_q[m] <=
                        aw_tail_q[m] + 1'b1;

                end


                /*
                 * AW FIFO pop.
                 */
                if (aw_pop_c[m])
                    aw_head_q[m] <=
                        aw_head_q[m] + 1'b1;


                case ({aw_push_c[m], aw_pop_c[m]})

                    2'b10:
                        aw_count_q[m] <=
                            aw_count_q[m] + 1'b1;

                    2'b01:
                        aw_count_q[m] <=
                            aw_count_q[m] - 1'b1;

                    default:
                        aw_count_q[m] <=
                            aw_count_q[m];

                endcase


                /*
                 * AR FIFO push.
                 */
                if (ar_push_c[m]) begin

                    ar_fifo_q[m][ar_tail_q[m]].ar <=
                        mst_req[m].ar;

                    ar_fifo_q[m][ar_tail_q[m]].mapped <=
                        ar_dec_mapped_c[m];

                    ar_fifo_q[m][ar_tail_q[m]].target <=
                        ar_dec_target_c[m];

                    ar_tail_q[m] <=
                        ar_tail_q[m] + 1'b1;

                end


                /*
                 * AR FIFO pop.
                 */
                if (ar_pop_c[m])
                    ar_head_q[m] <=
                        ar_head_q[m] + 1'b1;


                case ({ar_push_c[m], ar_pop_c[m]})

                    2'b10:
                        ar_count_q[m] <=
                            ar_count_q[m] + 1'b1;

                    2'b01:
                        ar_count_q[m] <=
                            ar_count_q[m] - 1'b1;

                    default:
                        ar_count_q[m] <=
                            ar_count_q[m];

                endcase


                /*
                 * Write outstanding count.
                 */
                case ({aw_push_c[m], b_done_c[m]})

                    2'b10:
                        wr_out_count_q[m] <=
                            wr_out_count_q[m] + 1'b1;

                    2'b01:
                        wr_out_count_q[m] <=
                            wr_out_count_q[m] - 1'b1;

                    default:
                        wr_out_count_q[m] <=
                            wr_out_count_q[m];

                endcase


                /*
                 * Read outstanding count.
                 */
                case ({ar_push_c[m], r_done_c[m]})

                    2'b10:
                        rd_out_count_q[m] <=
                            rd_out_count_q[m] + 1'b1;

                    2'b01:
                        rd_out_count_q[m] <=
                            rd_out_count_q[m] - 1'b1;

                    default:
                        rd_out_count_q[m] <=
                            rd_out_count_q[m];

                endcase


                /*
                 * Same-ID serialization.
                 */
                if (aw_push_c[m])
                    wr_id_busy_q[m][mst_req[m].aw.id] <=
                        1'b1;

                if (b_done_c[m])
                    wr_id_busy_q[m][b_payload_c[m].id] <=
                        1'b0;


                if (ar_push_c[m])
                    rd_id_busy_q[m][mst_req[m].ar.id] <=
                        1'b1;

                if (r_done_c[m])
                    rd_id_busy_q[m][r_payload_c[m].id] <=
                        1'b0;


                /*
                 * ----------------------------------------------------------
                 * Local decode-error write begins.
                 * ----------------------------------------------------------
                 */
                if (decerr_wr_start_c[m]) begin

                    wr_active_q[m] <= 1'b1;
                    wr_mapped_q[m] <= 1'b0;

                    wr_id_q[m] <=
                        aw_head_c[m].aw.id;

                end


                /*
                 * ----------------------------------------------------------
                 * Local decode-error read begins.
                 * ----------------------------------------------------------
                 */
                if (decerr_rd_start_c[m]) begin

                    local_r_active_q[m] <=
                        1'b1;

                    local_r_id_q[m] <=
                        ar_head_c[m].ar.id;

                    local_r_left_q[m] <=
                        {1'b0, ar_head_c[m].ar.len} +
                        9'd1;

                end


                /*
                 * ----------------------------------------------------------
                 * WLAST retires write-data ownership.
                 * ----------------------------------------------------------
                 */
                if (
                    w_fire_c[m] &&
                    mst_req[m].w.last
                ) begin

                    if (
                        wr_active_q[m] &&
                        wr_mapped_q[m]
                    ) begin

                        wr_owner_valid_q[
                            wr_target_q[m]
                        ] <= 1'b0;

                        wr_active_q[m] <= 1'b0;

                    end
                    else if (
                        wr_active_q[m] &&
                        !wr_mapped_q[m]
                    ) begin

                        wr_active_q[m] <= 1'b0;

                        local_b_pending_q[m] <=
                            1'b1;

                        local_b_id_q[m] <=
                            wr_id_q[m];

                    end

                end


                /*
                 * Local DECERR B accepted.
                 */
                if (
                    b_handshake_c[m] &&
                    (
                        b_sel_src_c[m] ==
                        src_index_t'(NUM_SLV)
                    )
                ) begin

                    local_b_pending_q[m] <=
                        1'b0;

                end


                /*
                 * Local DECERR R accepted.
                 */
                if (
                    r_handshake_c[m] &&
                    (
                        r_sel_src_c[m] ==
                        src_index_t'(NUM_SLV)
                    )
                ) begin

                    if (local_r_left_q[m] == 9'd1) begin

                        local_r_left_q[m]   <= '0;
                        local_r_active_q[m] <= 1'b0;

                    end
                    else begin

                        local_r_left_q[m] <=
                            local_r_left_q[m] -
                            9'd1;

                    end

                end


                /*
                 * ----------------------------------------------------------
                 * B response stall lock and round robin.
                 * ----------------------------------------------------------
                 */
                if (b_lock_valid_q[m]) begin

                    if (b_handshake_c[m]) begin

                        b_lock_valid_q[m] <=
                            1'b0;

                        if (
                            b_sel_src_c[m] ==
                            src_index_t'(NUM_SLV)
                        )
                            b_rr_q[m] <= '0;
                        else
                            b_rr_q[m] <=
                                b_sel_src_c[m] +
                                1'b1;

                    end

                end
                else if (b_sel_valid_c[m]) begin

                    if (b_handshake_c[m]) begin

                        if (
                            b_sel_src_c[m] ==
                            src_index_t'(NUM_SLV)
                        )
                            b_rr_q[m] <= '0;
                        else
                            b_rr_q[m] <=
                                b_sel_src_c[m] +
                                1'b1;

                    end
                    else if (!mst_req[m].b_ready) begin

                        b_lock_valid_q[m] <=
                            1'b1;

                        b_lock_src_q[m] <=
                            b_sel_src_c[m];

                    end

                end


                /*
                 * ----------------------------------------------------------
                 * R response stall lock and round robin.
                 *
                 * The lock is only for a stalled beat. Different IDs may
                 * interleave, as AXI permits.
                 * ----------------------------------------------------------
                 */
                if (r_lock_valid_q[m]) begin

                    if (r_handshake_c[m]) begin

                        r_lock_valid_q[m] <=
                            1'b0;

                        if (
                            r_sel_src_c[m] ==
                            src_index_t'(NUM_SLV)
                        )
                            r_rr_q[m] <= '0;
                        else
                            r_rr_q[m] <=
                                r_sel_src_c[m] +
                                1'b1;

                    end

                end
                else if (r_sel_valid_c[m]) begin

                    if (r_handshake_c[m]) begin

                        if (
                            r_sel_src_c[m] ==
                            src_index_t'(NUM_SLV)
                        )
                            r_rr_q[m] <= '0;
                        else
                            r_rr_q[m] <=
                                r_sel_src_c[m] +
                                1'b1;

                    end
                    else if (!mst_req[m].r_ready) begin

                        r_lock_valid_q[m] <=
                            1'b1;

                        r_lock_src_q[m] <=
                            r_sel_src_c[m];

                    end

                end

            end


            /*
             * --------------------------------------------------------------
             * Mapped AW issues establish W ownership.
             * --------------------------------------------------------------
             */
            for (s = 0; s < NUM_SLV; s = s + 1) begin

                if (aw_issue_c[s]) begin

                    m = aw_sel_m_c[s];

                    wr_owner_valid_q[s] <=
                        1'b1;

                    wr_owner_q[s] <=
                        aw_sel_m_c[s];

                    wr_active_q[m] <=
                        1'b1;

                    wr_mapped_q[m] <=
                        1'b1;

                    wr_target_q[m] <=
                        mst_index_t'(s);

                    wr_id_q[m] <=
                        aw_head_c[m].aw.id;

                end


                /*
                 * ----------------------------------------------------------
                 * AW arbitration output stability / fairness.
                 * ----------------------------------------------------------
                 */
                if (aw_lock_valid_q[s]) begin

                    if (aw_issue_c[s]) begin

                        aw_lock_valid_q[s] <=
                            1'b0;

                        if (
                            aw_sel_m_c[s] ==
                            mst_index_t'(NUM_MST - 1)
                        )
                            aw_rr_q[s] <= '0;
                        else
                            aw_rr_q[s] <=
                                aw_sel_m_c[s] +
                                1'b1;

                    end

                end
                else if (aw_sel_valid_c[s]) begin

                    if (aw_issue_c[s]) begin

                        if (
                            aw_sel_m_c[s] ==
                            mst_index_t'(NUM_MST - 1)
                        )
                            aw_rr_q[s] <= '0;
                        else
                            aw_rr_q[s] <=
                                aw_sel_m_c[s] +
                                1'b1;

                    end
                    else if (!slv_resp[s].aw_ready) begin

                        aw_lock_valid_q[s] <=
                            1'b1;

                        aw_lock_m_q[s] <=
                            aw_sel_m_c[s];

                    end

                end


                /*
                 * ----------------------------------------------------------
                 * AR arbitration output stability / fairness.
                 * ----------------------------------------------------------
                 */
                if (ar_lock_valid_q[s]) begin

                    if (ar_issue_c[s]) begin

                        ar_lock_valid_q[s] <=
                            1'b0;

                        if (
                            ar_sel_m_c[s] ==
                            mst_index_t'(NUM_MST - 1)
                        )
                            ar_rr_q[s] <= '0;
                        else
                            ar_rr_q[s] <=
                                ar_sel_m_c[s] +
                                1'b1;

                    end

                end
                else if (ar_sel_valid_c[s]) begin

                    if (ar_issue_c[s]) begin

                        if (
                            ar_sel_m_c[s] ==
                            mst_index_t'(NUM_MST - 1)
                        )
                            ar_rr_q[s] <= '0;
                        else
                            ar_rr_q[s] <=
                                ar_sel_m_c[s] +
                                1'b1;

                    end
                    else if (!slv_resp[s].ar_ready) begin

                        ar_lock_valid_q[s] <=
                            1'b1;

                        ar_lock_m_q[s] <=
                            ar_sel_m_c[s];

                    end

                end

            end

        end
    end

endmodule