module axi4_xbar
  import axi4_xbar_pkg::*;
#(
    parameter int NUM_MST   = 2,
    parameter int NUM_SLV   = 2,
    parameter int MAX_TRANS = 8
) (
    input  logic clk,
    input  logic rst_n,

    input  slv_req_t  [NUM_MST-1:0] mst_req,
    output slv_resp_t [NUM_MST-1:0] mst_resp,

    output mst_req_t  [NUM_SLV-1:0] slv_req,
    input  mst_resp_t [NUM_SLV-1:0] slv_resp,

    input  xbar_rule_t [NUM_SLV-1:0] addr_map
);

    localparam int QPTR_W    = $clog2(MAX_TRANS);
    localparam int QCNT_W    = $clog2(MAX_TRANS + 1);
    localparam int SLV_SEL_W = $clog2(NUM_SLV);

    // A read burst may contain up to 256 beats.  One full-burst buffer per
    // master lets the crossbar absorb a mapped R burst even if the originating
    // master applies backpressure, so that master cannot wedge a shared slave
    // response channel.
    localparam int RBUF_DEPTH = 256;
    localparam int RBUF_PTR_W = 8;
    localparam int RBUF_CNT_W = 9;


    // =========================================================================
    // Helpers
    // =========================================================================

    function automatic mst_id_t widen_id(
        input logic [MST_IDX_W-1:0] master_idx,
        input slv_id_t              id
    );
        mst_id_t x;
        begin
            x = '0;
            x[SLV_ID_W-1:0] = id;
            x[MST_ID_W-1 -: MST_IDX_W] = master_idx;
            widen_id = x;
        end
    endfunction


    function automatic mst_aw_t widen_aw(
        input slv_aw_t              a,
        input logic [MST_IDX_W-1:0] master_idx
    );
        mst_aw_t x;
        begin
            x = '0;

            x.id     = widen_id(master_idx, a.id);
            x.addr   = a.addr;
            x.len    = a.len;
            x.size   = a.size;
            x.burst  = a.burst;
            x.lock   = a.lock;
            x.cache  = a.cache;
            x.prot   = a.prot;
            x.qos    = a.qos;
            x.region = a.region;
            x.atop   = a.atop;
            x.user   = a.user;

            widen_aw = x;
        end
    endfunction


    function automatic mst_ar_t widen_ar(
        input slv_ar_t              a,
        input logic [MST_IDX_W-1:0] master_idx
    );
        mst_ar_t x;
        begin
            x = '0;

            x.id     = widen_id(master_idx, a.id);
            x.addr   = a.addr;
            x.len    = a.len;
            x.size   = a.size;
            x.burst  = a.burst;
            x.lock   = a.lock;
            x.cache  = a.cache;
            x.prot   = a.prot;
            x.qos    = a.qos;
            x.region = a.region;
            x.user   = a.user;

            widen_ar = x;
        end
    endfunction


    // =========================================================================
    // Per-master address admission FIFOs
    //
    // These FIFOs are the C1 capacity.
    // =========================================================================

    slv_aw_t wr_aw_q
        [NUM_MST-1:0][MAX_TRANS-1:0];

    logic wr_mapped_q
        [NUM_MST-1:0][MAX_TRANS-1:0];

    logic [SLV_SEL_W-1:0] wr_target_q
        [NUM_MST-1:0][MAX_TRANS-1:0];


    slv_ar_t rd_ar_q
        [NUM_MST-1:0][MAX_TRANS-1:0];

    logic rd_mapped_q
        [NUM_MST-1:0][MAX_TRANS-1:0];

    logic [SLV_SEL_W-1:0] rd_target_q
        [NUM_MST-1:0][MAX_TRANS-1:0];


    logic [QPTR_W-1:0] wr_head [NUM_MST-1:0];
    logic [QPTR_W-1:0] wr_tail [NUM_MST-1:0];
    logic [QCNT_W-1:0] wr_count[NUM_MST-1:0];

    logic [QPTR_W-1:0] rd_head [NUM_MST-1:0];
    logic [QPTR_W-1:0] rd_tail [NUM_MST-1:0];
    logic [QCNT_W-1:0] rd_count[NUM_MST-1:0];


    // =========================================================================
    // Decode incoming AW/AR
    // =========================================================================

    logic aw_dec_mapped [NUM_MST-1:0];
    logic ar_dec_mapped [NUM_MST-1:0];

    logic [SLV_SEL_W-1:0]
        aw_dec_target [NUM_MST-1:0];

    logic [SLV_SEL_W-1:0]
        ar_dec_target [NUM_MST-1:0];


    always_comb begin
        for (int m = 0; m < NUM_MST; m++) begin

            aw_dec_mapped[m] = 1'b0;
            aw_dec_target[m] = '0;

            ar_dec_mapped[m] = 1'b0;
            ar_dec_target[m] = '0;

            for (int r = 0; r < NUM_SLV; r++) begin

                if ((mst_req[m].aw.addr >= addr_map[r].start_addr) &&
                    (mst_req[m].aw.addr <  addr_map[r].end_addr)   &&
                    (addr_map[r].mst_port < NUM_SLV)) begin

                    aw_dec_mapped[m] = 1'b1;
                    aw_dec_target[m] =
                        addr_map[r].mst_port[SLV_SEL_W-1:0];
                end


                if ((mst_req[m].ar.addr >= addr_map[r].start_addr) &&
                    (mst_req[m].ar.addr <  addr_map[r].end_addr)   &&
                    (addr_map[r].mst_port < NUM_SLV)) begin

                    ar_dec_mapped[m] = 1'b1;
                    ar_dec_target[m] =
                        addr_map[r].mst_port[SLV_SEL_W-1:0];
                end
            end
        end
    end


    // =========================================================================
    // Master write state
    //
    // Only the HEAD write is active downstream.  Later AWs still occupy FIFO
    // entries, satisfying C1.
    //
    // Stronger-than-required ordering is used: one active write response per
    // master. Hence same-ID ordering is automatic.
    // =========================================================================

    typedef enum logic [2:0] {
        WM_IDLE,
        WM_WAIT_AW,
        WM_SEND_W,
        WM_WAIT_B,
        WM_RESP,
        WM_LOCAL_W
    } wm_state_t;

    wm_state_t wm_state [NUM_MST-1:0];


    // One B response register per master.
    //
    // It lets the crossbar accept the slave's B independently of the master's
    // BREADY. Once a master backpressures its B output, that master stops
    // issuing further writes, so depth one is sufficient.
    logic   b_buf_valid [NUM_MST-1:0];
    slv_b_t b_buf       [NUM_MST-1:0];


    // =========================================================================
    // Master read state
    // =========================================================================

    typedef enum logic [1:0] {
        RM_IDLE,
        RM_WAIT_AR,
        RM_RECV,
        RM_LOCAL
    } rm_state_t;

    rm_state_t rm_state [NUM_MST-1:0];

    logic [8:0] local_r_left [NUM_MST-1:0];


    // =========================================================================
    // Full-burst mapped-read buffers
    // =========================================================================

    slv_r_t rbuf_mem
        [NUM_MST-1:0][RBUF_DEPTH-1:0];

    logic [RBUF_PTR_W-1:0]
        rbuf_head [NUM_MST-1:0];

    logic [RBUF_PTR_W-1:0]
        rbuf_tail [NUM_MST-1:0];

    logic [RBUF_CNT_W-1:0]
        rbuf_count [NUM_MST-1:0];


    // =========================================================================
    // Per-slave write engine
    //
    // A downstream slave accepts only one AW whose W stream has not yet
    // completed. The slot is released at WLAST, NOT at B.
    //
    // This guarantees downstream W ordering without allowing B backpressure
    // to monopolize the slave's AW/W path.
    // =========================================================================

    typedef enum logic [1:0] {
        WS_IDLE,
        WS_AW,
        WS_W
    } ws_state_t;

    ws_state_t ws_state [NUM_SLV-1:0];

    logic [MST_IDX_W-1:0]
        ws_owner [NUM_SLV-1:0];

    logic [MST_IDX_W-1:0]
        aw_rr [NUM_SLV-1:0];

    mst_aw_t aw_hold [NUM_SLV-1:0];


    // =========================================================================
    // Per-slave read-address engine
    //
    // Reservation ends as soon as AR is accepted. Responses are tagged, so
    // multiple masters may have read bursts outstanding to the same slave.
    // =========================================================================

    typedef enum logic {
        RS_IDLE,
        RS_AR
    } rs_state_t;

    rs_state_t rs_state [NUM_SLV-1:0];

    logic [MST_IDX_W-1:0]
        rs_owner [NUM_SLV-1:0];

    logic [MST_IDX_W-1:0]
        ar_rr [NUM_SLV-1:0];

    mst_ar_t ar_hold [NUM_SLV-1:0];


    // =========================================================================
    // Fair arbitration candidates
    // =========================================================================

    logic aw_pick_valid [NUM_SLV-1:0];
    logic ar_pick_valid [NUM_SLV-1:0];

    logic [MST_IDX_W-1:0]
        aw_pick_m [NUM_SLV-1:0];

    logic [MST_IDX_W-1:0]
        ar_pick_m [NUM_SLV-1:0];


    always_comb begin
        for (int s = 0; s < NUM_SLV; s++) begin

            aw_pick_valid[s] = 1'b0;
            aw_pick_m[s]     = '0;

            ar_pick_valid[s] = 1'b0;
            ar_pick_m[s]     = '0;


            for (int k = 0; k < NUM_MST; k++) begin
                int idx;

                // -------------------------------------------------------------
                // AW round-robin scan
                // -------------------------------------------------------------
                idx = (aw_rr[s] + k) % NUM_MST;

                if (!aw_pick_valid[s] &&
                    (wm_state[idx] == WM_WAIT_AW) &&
                    wr_mapped_q[idx][wr_head[idx]] &&
                    (wr_target_q[idx][wr_head[idx]] == s)) begin

                    aw_pick_valid[s] = 1'b1;
                    aw_pick_m[s]     = idx;
                end


                // -------------------------------------------------------------
                // AR round-robin scan
                // -------------------------------------------------------------
                idx = (ar_rr[s] + k) % NUM_MST;

                if (!ar_pick_valid[s] &&
                    (rm_state[idx] == RM_WAIT_AR) &&
                    rd_mapped_q[idx][rd_head[idx]] &&
                    (rd_target_q[idx][rd_head[idx]] == s)) begin

                    ar_pick_valid[s] = 1'b1;
                    ar_pick_m[s]     = idx;
                end
            end
        end
    end


    // =========================================================================
    // Handshake/event signals
    // =========================================================================

    logic aw_accept [NUM_MST-1:0];
    logic ar_accept [NUM_MST-1:0];

    logic aw_down_fire [NUM_SLV-1:0];
    logic ar_down_fire [NUM_SLV-1:0];
    logic wlast_down_fire [NUM_SLV-1:0];

    logic mapped_aw_fire_m [NUM_MST-1:0];
    logic mapped_ar_fire_m [NUM_MST-1:0];
    logic mapped_wlast_m   [NUM_MST-1:0];

    logic b_load [NUM_MST-1:0];
    slv_b_t b_load_data [NUM_MST-1:0];

    logic b_out_fire [NUM_MST-1:0];

    logic local_wlast_m [NUM_MST-1:0];


    logic rbuf_push [NUM_MST-1:0];
    slv_r_t rbuf_push_data [NUM_MST-1:0];

    logic rbuf_pop [NUM_MST-1:0];

    logic mapped_r_last_out [NUM_MST-1:0];

    logic local_r_fire [NUM_MST-1:0];
    logic local_r_last [NUM_MST-1:0];

    logic wr_complete [NUM_MST-1:0];
    logic rd_complete [NUM_MST-1:0];


    // =========================================================================
    // Combinational datapath
    // =========================================================================

    always_comb begin

        // ---------------------------------------------------------------------
        // Global defaults
        // ---------------------------------------------------------------------

        for (int m = 0; m < NUM_MST; m++) begin

            mst_resp[m] = '0;

            aw_accept[m] = 1'b0;
            ar_accept[m] = 1'b0;

            mapped_aw_fire_m[m] = 1'b0;
            mapped_ar_fire_m[m] = 1'b0;
            mapped_wlast_m[m]   = 1'b0;

            local_wlast_m[m] = 1'b0;

            b_load[m]      = 1'b0;
            b_load_data[m] = '0;

            b_out_fire[m] = 1'b0;

            rbuf_push[m]      = 1'b0;
            rbuf_push_data[m] = '0;

            rbuf_pop[m] = 1'b0;

            mapped_r_last_out[m] = 1'b0;

            local_r_fire[m] = 1'b0;
            local_r_last[m] = 1'b0;

            wr_complete[m] = 1'b0;
            rd_complete[m] = 1'b0;


            // -------------------------------------------------------------
            // C1 admission.
            //
            // READY depends only on queue capacity, not corresponding VALID.
            // -------------------------------------------------------------

            mst_resp[m].aw_ready =
                rst_n && (wr_count[m] < MAX_TRANS);

            mst_resp[m].ar_ready =
                rst_n && (rd_count[m] < MAX_TRANS);

            aw_accept[m] =
                mst_resp[m].aw_ready &&
                mst_req[m].aw_valid;

            ar_accept[m] =
                mst_resp[m].ar_ready &&
                mst_req[m].ar_valid;


            // -------------------------------------------------------------
            // Buffered B output
            // -------------------------------------------------------------

            if (rst_n && b_buf_valid[m]) begin
                mst_resp[m].b_valid = 1'b1;
                mst_resp[m].b       = b_buf[m];

                if (mst_req[m].b_ready)
                    b_out_fire[m] = 1'b1;
            end


            // -------------------------------------------------------------
            // Mapped R output from per-master burst FIFO
            // -------------------------------------------------------------

            if (rst_n &&
                (rm_state[m] == RM_RECV) &&
                (rbuf_count[m] != 0)) begin

                mst_resp[m].r_valid =
                    1'b1;

                mst_resp[m].r =
                    rbuf_mem[m][rbuf_head[m]];

                if (mst_req[m].r_ready) begin

                    rbuf_pop[m] =
                        1'b1;

                    if (rbuf_mem[m][rbuf_head[m]].last)
                        mapped_r_last_out[m] = 1'b1;
                end
            end


            // -------------------------------------------------------------
            // Local DECERR read
            // -------------------------------------------------------------

            if (rst_n &&
                (rm_state[m] == RM_LOCAL)) begin

                mst_resp[m].r_valid = 1'b1;

                mst_resp[m].r.id =
                    rd_ar_q[m][rd_head[m]].id;

                mst_resp[m].r.data =
                    '0;

                mst_resp[m].r.resp =
                    RESP_DECERR;

                mst_resp[m].r.last =
                    (local_r_left[m] == 9'd1);

                mst_resp[m].r.user =
                    rd_ar_q[m][rd_head[m]].user;


                if (mst_req[m].r_ready) begin

                    local_r_fire[m] =
                        1'b1;

                    if (local_r_left[m] == 9'd1)
                        local_r_last[m] = 1'b1;
                end
            end
        end


        // ---------------------------------------------------------------------
        // Slave-side defaults
        //
        // Unexpected/stale B/R responses are drained after reset rather than
        // being exposed at a master port.
        // ---------------------------------------------------------------------

        for (int s = 0; s < NUM_SLV; s++) begin

            slv_req[s] = '0;

            aw_down_fire[s]    = 1'b0;
            ar_down_fire[s]    = 1'b0;
            wlast_down_fire[s] = 1'b0;

            slv_req[s].b_ready = rst_n;
            slv_req[s].r_ready = rst_n;


            // -------------------------------------------------------------
            // Stable AW holding register
            // -------------------------------------------------------------

            if (rst_n && (ws_state[s] == WS_AW)) begin

                slv_req[s].aw =
                    aw_hold[s];

                slv_req[s].aw_valid =
                    1'b1;

                if (slv_resp[s].aw_ready) begin

                    aw_down_fire[s] =
                        1'b1;

                    if (ws_owner[s] < NUM_MST)
                        mapped_aw_fire_m[ws_owner[s]] =
                            1'b1;
                end
            end


            // -------------------------------------------------------------
            // W routing
            //
            // Slave is reserved for this owner from AW acceptance through
            // WLAST, so W ordering is unambiguous.
            // -------------------------------------------------------------

            if (rst_n && (ws_state[s] == WS_W)) begin

                int m;

                m = ws_owner[s];

                if (m < NUM_MST) begin

                    slv_req[s].w =
                        mst_req[m].w;

                    slv_req[s].w_valid =
                        mst_req[m].w_valid;

                    // Corresponding READY does not depend on WVALID.
                    mst_resp[m].w_ready =
                        slv_resp[s].w_ready;


                    if (mst_req[m].w_valid &&
                        slv_resp[s].w_ready &&
                        mst_req[m].w.last) begin

                        wlast_down_fire[s] =
                            1'b1;

                        mapped_wlast_m[m] =
                            1'b1;
                    end
                end
            end


            // -------------------------------------------------------------
            // Stable AR holding register
            // -------------------------------------------------------------

            if (rst_n && (rs_state[s] == RS_AR)) begin

                slv_req[s].ar =
                    ar_hold[s];

                slv_req[s].ar_valid =
                    1'b1;

                if (slv_resp[s].ar_ready) begin

                    ar_down_fire[s] =
                        1'b1;

                    if (rs_owner[s] < NUM_MST)
                        mapped_ar_fire_m[rs_owner[s]] =
                            1'b1;
                end
            end
        end


        // ---------------------------------------------------------------------
        // Local decode-error W streams
        // ---------------------------------------------------------------------

        for (int m = 0; m < NUM_MST; m++) begin

            if (rst_n &&
                (wm_state[m] == WM_LOCAL_W)) begin

                // No slave is involved; simply consume the complete W burst.
                mst_resp[m].w_ready =
                    1'b1;

                if (mst_req[m].w_valid &&
                    mst_req[m].w.last) begin

                    local_wlast_m[m] =
                        1'b1;

                    b_load[m] =
                        1'b1;

                    b_load_data[m].id =
                        wr_aw_q[m][wr_head[m]].id;

                    b_load_data[m].resp =
                        RESP_DECERR;

                    b_load_data[m].user =
                        wr_aw_q[m][wr_head[m]].user;
                end
            end
        end


        // ---------------------------------------------------------------------
        // Downstream B routing/capture
        //
        // B is captured into the originating master's one-entry buffer.
        // Slave BREADY therefore does NOT depend on the originating master's
        // BREADY.
        // ---------------------------------------------------------------------

        for (int s = 0; s < NUM_SLV; s++) begin
            int m;

            m =
                slv_resp[s].b.id[
                    MST_ID_W-1 -: MST_IDX_W
                ];

            if (rst_n &&
                (m < NUM_MST) &&
                (wm_state[m] == WM_WAIT_B) &&
                wr_mapped_q[m][wr_head[m]] &&
                (wr_target_q[m][wr_head[m]] == s) &&
                (slv_resp[s].b.id[SLV_ID_W-1:0] ==
                    wr_aw_q[m][wr_head[m]].id)) begin

                // Buffer must be empty in WM_WAIT_B.
                slv_req[s].b_ready =
                    !b_buf_valid[m];

                if (slv_resp[s].b_valid &&
                    slv_req[s].b_ready) begin

                    b_load[m] =
                        1'b1;

                    b_load_data[m].id =
                        slv_resp[s].b.id[SLV_ID_W-1:0];

                    b_load_data[m].resp =
                        slv_resp[s].b.resp;

                    b_load_data[m].user =
                        slv_resp[s].b.user;
                end
            end
        end


        // ---------------------------------------------------------------------
        // Downstream R routing into full-burst per-master FIFOs
        //
        // The slave sees ready whenever storage remains, independent of the
        // originating master's RREADY.
        // ---------------------------------------------------------------------

        for (int s = 0; s < NUM_SLV; s++) begin
            int m;

            m =
                slv_resp[s].r.id[
                    MST_ID_W-1 -: MST_IDX_W
                ];

            if (rst_n &&
                (m < NUM_MST) &&
                (rm_state[m] == RM_RECV) &&
                rd_mapped_q[m][rd_head[m]] &&
                (rd_target_q[m][rd_head[m]] == s) &&
                (slv_resp[s].r.id[SLV_ID_W-1:0] ==
                    rd_ar_q[m][rd_head[m]].id)) begin

                slv_req[s].r_ready =
                    (rbuf_count[m] < RBUF_DEPTH);

                if (slv_resp[s].r_valid &&
                    slv_req[s].r_ready) begin

                    rbuf_push[m] =
                        1'b1;

                    rbuf_push_data[m].id =
                        slv_resp[s].r.id[SLV_ID_W-1:0];

                    rbuf_push_data[m].data =
                        slv_resp[s].r.data;

                    rbuf_push_data[m].resp =
                        slv_resp[s].r.resp;

                    rbuf_push_data[m].last =
                        slv_resp[s].r.last;

                    rbuf_push_data[m].user =
                        slv_resp[s].r.user;
                end
            end
        end


        // ---------------------------------------------------------------------
        // Completion means the RESPONSE has actually been accepted by the
        // originating master.
        //
        // Therefore wr_count/rd_count exactly model outstanding master-side
        // transactions for C1.
        // ---------------------------------------------------------------------

        for (int m = 0; m < NUM_MST; m++) begin

            if ((wm_state[m] == WM_RESP) &&
                b_out_fire[m]) begin

                wr_complete[m] =
                    1'b1;
            end


            if ((rm_state[m] == RM_RECV) &&
                mapped_r_last_out[m]) begin

                rd_complete[m] =
                    1'b1;
            end


            if ((rm_state[m] == RM_LOCAL) &&
                local_r_last[m]) begin

                rd_complete[m] =
                    1'b1;
            end
        end
    end


    // =========================================================================
    // Sequential state
    // =========================================================================

    always_ff @(posedge clk) begin

        if (!rst_n) begin

            // -----------------------------------------------------------------
            // Master-side state
            // -----------------------------------------------------------------

            for (int m = 0; m < NUM_MST; m++) begin

                wr_head[m]  <= '0;
                wr_tail[m]  <= '0;
                wr_count[m] <= '0;

                rd_head[m]  <= '0;
                rd_tail[m]  <= '0;
                rd_count[m] <= '0;

                wm_state[m] <= WM_IDLE;
                rm_state[m] <= RM_IDLE;

                b_buf_valid[m] <= 1'b0;
                b_buf[m]       <= '0;

                local_r_left[m] <= '0;

                rbuf_head[m]  <= '0;
                rbuf_tail[m]  <= '0;
                rbuf_count[m] <= '0;
            end


            // -----------------------------------------------------------------
            // Slave-side state
            // -----------------------------------------------------------------

            for (int s = 0; s < NUM_SLV; s++) begin

                ws_state[s] <= WS_IDLE;
                ws_owner[s] <= '0;
                aw_rr[s]    <= '0;
                aw_hold[s]  <= '0;

                rs_state[s] <= RS_IDLE;
                rs_owner[s] <= '0;
                ar_rr[s]    <= '0;
                ar_hold[s]  <= '0;
            end
        end

        else begin

            // =================================================================
            // Per-master state
            // =================================================================

            for (int m = 0; m < NUM_MST; m++) begin

                // -------------------------------------------------------------
                // AW FIFO insertion
                // -------------------------------------------------------------

                if (aw_accept[m]) begin

                    wr_aw_q[m][wr_tail[m]] <=
                        mst_req[m].aw;

                    wr_mapped_q[m][wr_tail[m]] <=
                        aw_dec_mapped[m];

                    wr_target_q[m][wr_tail[m]] <=
                        aw_dec_target[m];

                    wr_tail[m] <=
                        wr_tail[m] + 1'b1;
                end


                // -------------------------------------------------------------
                // AW FIFO removal only when B has reached the master.
                // -------------------------------------------------------------

                if (wr_complete[m]) begin
                    wr_head[m] <=
                        wr_head[m] + 1'b1;
                end


                case ({aw_accept[m], wr_complete[m]})

                    2'b10:
                        wr_count[m] <=
                            wr_count[m] + 1'b1;

                    2'b01:
                        wr_count[m] <=
                            wr_count[m] - 1'b1;

                    default:
                        wr_count[m] <=
                            wr_count[m];
                endcase


                // -------------------------------------------------------------
                // AR FIFO insertion
                // -------------------------------------------------------------

                if (ar_accept[m]) begin

                    rd_ar_q[m][rd_tail[m]] <=
                        mst_req[m].ar;

                    rd_mapped_q[m][rd_tail[m]] <=
                        ar_dec_mapped[m];

                    rd_target_q[m][rd_tail[m]] <=
                        ar_dec_target[m];

                    rd_tail[m] <=
                        rd_tail[m] + 1'b1;
                end


                // -------------------------------------------------------------
                // AR FIFO removal only after final R reaches the master.
                // -------------------------------------------------------------

                if (rd_complete[m]) begin
                    rd_head[m] <=
                        rd_head[m] + 1'b1;
                end


                case ({ar_accept[m], rd_complete[m]})

                    2'b10:
                        rd_count[m] <=
                            rd_count[m] + 1'b1;

                    2'b01:
                        rd_count[m] <=
                            rd_count[m] - 1'b1;

                    default:
                        rd_count[m] <=
                            rd_count[m];
                endcase


                // -------------------------------------------------------------
                // Write transaction state machine
                // -------------------------------------------------------------

                case (wm_state[m])

                    WM_IDLE: begin

                        if (wr_count[m] != 0) begin

                            if (wr_mapped_q[m][wr_head[m]])
                                wm_state[m] <= WM_WAIT_AW;
                            else
                                wm_state[m] <= WM_LOCAL_W;
                        end
                    end


                    WM_WAIT_AW: begin

                        if (mapped_aw_fire_m[m])
                            wm_state[m] <= WM_SEND_W;
                    end


                    WM_SEND_W: begin

                        if (mapped_wlast_m[m])
                            wm_state[m] <= WM_WAIT_B;
                    end


                    WM_WAIT_B: begin

                        if (b_load[m])
                            wm_state[m] <= WM_RESP;
                    end


                    WM_LOCAL_W: begin

                        if (local_wlast_m[m])
                            wm_state[m] <= WM_RESP;
                    end


                    WM_RESP: begin

                        if (b_out_fire[m])
                            wm_state[m] <= WM_IDLE;
                    end


                    default:
                        wm_state[m] <= WM_IDLE;

                endcase


                // -------------------------------------------------------------
                // B response buffer
                // -------------------------------------------------------------

                if (b_load[m]) begin

                    b_buf_valid[m] <=
                        1'b1;

                    b_buf[m] <=
                        b_load_data[m];
                end
                else if (b_out_fire[m]) begin

                    b_buf_valid[m] <=
                        1'b0;
                end


                // -------------------------------------------------------------
                // Read transaction state
                // -------------------------------------------------------------

                case (rm_state[m])

                    RM_IDLE: begin

                        if (rd_count[m] != 0) begin

                            if (rd_mapped_q[m][rd_head[m]]) begin
                                rm_state[m] <= RM_WAIT_AR;
                            end
                            else begin
                                rm_state[m] <= RM_LOCAL;

                                local_r_left[m] <=
                                    {1'b0,
                                     rd_ar_q[m][rd_head[m]].len}
                                    + 9'd1;
                            end
                        end
                    end


                    RM_WAIT_AR: begin

                        if (mapped_ar_fire_m[m])
                            rm_state[m] <= RM_RECV;
                    end


                    RM_RECV: begin

                        if (mapped_r_last_out[m])
                            rm_state[m] <= RM_IDLE;
                    end


                    RM_LOCAL: begin

                        if (local_r_fire[m]) begin

                            if (local_r_left[m] == 9'd1) begin

                                local_r_left[m] <= '0;
                                rm_state[m]     <= RM_IDLE;

                            end
                            else begin

                                local_r_left[m] <=
                                    local_r_left[m] - 9'd1;
                            end
                        end
                    end


                    default:
                        rm_state[m] <= RM_IDLE;

                endcase


                // -------------------------------------------------------------
                // Mapped read burst FIFO
                // -------------------------------------------------------------

                if (rbuf_push[m]) begin

                    rbuf_mem[m][rbuf_tail[m]] <=
                        rbuf_push_data[m];

                    rbuf_tail[m] <=
                        rbuf_tail[m] + 1'b1;
                end


                if (rbuf_pop[m]) begin

                    rbuf_head[m] <=
                        rbuf_head[m] + 1'b1;
                end


                case ({rbuf_push[m], rbuf_pop[m]})

                    2'b10:
                        rbuf_count[m] <=
                            rbuf_count[m] + 1'b1;

                    2'b01:
                        rbuf_count[m] <=
                            rbuf_count[m] - 1'b1;

                    default:
                        rbuf_count[m] <=
                            rbuf_count[m];
                endcase
            end


            // =================================================================
            // Per-slave write engines
            // =================================================================

            for (int s = 0; s < NUM_SLV; s++) begin

                case (ws_state[s])

                    WS_IDLE: begin

                        if (aw_pick_valid[s]) begin

                            int m;

                            m = aw_pick_m[s];

                            ws_owner[s] <=
                                aw_pick_m[s];

                            aw_hold[s] <=
                                widen_aw(
                                    wr_aw_q[m][wr_head[m]],
                                    aw_pick_m[s]
                                );

                            ws_state[s] <=
                                WS_AW;
                        end
                    end


                    WS_AW: begin

                        if (aw_down_fire[s])
                            ws_state[s] <= WS_W;
                    end


                    WS_W: begin

                        if (wlast_down_fire[s]) begin

                            ws_state[s] <=
                                WS_IDLE;

                            // Fair next starting point.
                            if (ws_owner[s] == NUM_MST-1)
                                aw_rr[s] <= '0;
                            else
                                aw_rr[s] <= ws_owner[s] + 1'b1;
                        end
                    end


                    default:
                        ws_state[s] <= WS_IDLE;

                endcase
            end


            // =================================================================
            // Per-slave AR engines
            // =================================================================

            for (int s = 0; s < NUM_SLV; s++) begin

                case (rs_state[s])

                    RS_IDLE: begin

                        if (ar_pick_valid[s]) begin

                            int m;

                            m = ar_pick_m[s];

                            rs_owner[s] <=
                                ar_pick_m[s];

                            ar_hold[s] <=
                                widen_ar(
                                    rd_ar_q[m][rd_head[m]],
                                    ar_pick_m[s]
                                );

                            rs_state[s] <=
                                RS_AR;
                        end
                    end


                    RS_AR: begin

                        if (ar_down_fire[s]) begin

                            rs_state[s] <=
                                RS_IDLE;

                            if (rs_owner[s] == NUM_MST-1)
                                ar_rr[s] <= '0;
                            else
                                ar_rr[s] <= rs_owner[s] + 1'b1;
                        end
                    end


                    default:
                        rs_state[s] <= RS_IDLE;

                endcase
            end
        end
    end

endmodule