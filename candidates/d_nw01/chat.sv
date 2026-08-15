module axi4_xbar
  import axi4_xbar_pkg::*;
#(
    parameter int NUM_MST   = 2,   // 2 / 4
    parameter int NUM_SLV   = 2,   // 2 / 4
    parameter int MAX_TRANS = 8    // 2 / 8
) (
    input  logic clk,
    input  logic rst_n,

    input  slv_req_t  [NUM_MST-1:0] mst_req,
    output slv_resp_t [NUM_MST-1:0] mst_resp,

    output mst_req_t  [NUM_SLV-1:0] slv_req,
    input  mst_resp_t [NUM_SLV-1:0] slv_resp,

    input  xbar_rule_t [NUM_SLV-1:0] addr_map
);

    // -------------------------------------------------------------------------
    // Helpers
    // -------------------------------------------------------------------------

    function automatic mst_id_t widen_id (
        input int unsigned master_idx,
        input slv_id_t     id
    );
        mst_id_t v;
        begin
            v = '0;
            v[SLV_ID_W-1:0] = id;
            v[MST_ID_W-1 -: MST_IDX_W] =
                master_idx[MST_IDX_W-1:0];
            widen_id = v;
        end
    endfunction


    function automatic mst_aw_t widen_aw (
        input slv_aw_t     a,
        input int unsigned master_idx
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


    function automatic mst_ar_t widen_ar (
        input slv_ar_t     a,
        input int unsigned master_idx
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


    // -------------------------------------------------------------------------
    // Address decode
    // -------------------------------------------------------------------------

    logic [NUM_MST-1:0] aw_mapped;
    logic [NUM_MST-1:0] ar_mapped;

    logic [MST_IDX_W-1:0] aw_target [NUM_MST-1:0];
    logic [MST_IDX_W-1:0] ar_target [NUM_MST-1:0];

    always_comb begin
        for (int m = 0; m < NUM_MST; m++) begin
            aw_mapped[m] = 1'b0;
            ar_mapped[m] = 1'b0;

            aw_target[m] = '0;
            ar_target[m] = '0;

            for (int r = 0; r < NUM_SLV; r++) begin

                if ((mst_req[m].aw.addr >= addr_map[r].start_addr) &&
                    (mst_req[m].aw.addr <  addr_map[r].end_addr)   &&
                    (addr_map[r].mst_port < NUM_SLV)) begin

                    aw_mapped[m] = 1'b1;
                    aw_target[m] =
                        addr_map[r].mst_port[MST_IDX_W-1:0];
                end

                if ((mst_req[m].ar.addr >= addr_map[r].start_addr) &&
                    (mst_req[m].ar.addr <  addr_map[r].end_addr)   &&
                    (addr_map[r].mst_port < NUM_SLV)) begin

                    ar_mapped[m] = 1'b1;
                    ar_target[m] =
                        addr_map[r].mst_port[MST_IDX_W-1:0];
                end
            end
        end
    end


    // =========================================================================
    // WRITE PATH
    // =========================================================================

    // Per-master state.
    typedef enum logic [1:0] {
        MW_IDLE,
        MW_MAPPED,
        MW_LOCAL_W,
        MW_LOCAL_B
    } mw_state_t;

    mw_state_t mw_state [NUM_MST-1:0];

    slv_id_t  local_w_id   [NUM_MST-1:0];
    user_t    local_w_user [NUM_MST-1:0];


    // Per-slave write state.
    typedef enum logic [1:0] {
        SW_IDLE,
        SW_AW,
        SW_DATA,
        SW_B
    } sw_state_t;

    sw_state_t sw_state [NUM_SLV-1:0];

    logic [MST_IDX_W-1:0] sw_owner [NUM_SLV-1:0];
    logic [MST_IDX_W-1:0] sw_rr    [NUM_SLV-1:0];

    mst_aw_t sw_aw_hold [NUM_SLV-1:0];


    // =========================================================================
    // READ PATH
    // =========================================================================

    typedef enum logic {
        MR_IDLE,
        MR_MAPPED
    } mr_mapped_state_t;

    // A separate local-read bit makes the 3 logical states explicit without
    // relying on enum encoding tricks.
    logic mr_busy_mapped [NUM_MST-1:0];
    logic mr_busy_local  [NUM_MST-1:0];

    slv_id_t local_r_id   [NUM_MST-1:0];
    user_t   local_r_user [NUM_MST-1:0];

    // 1..256 beats.
    logic [8:0] local_r_left [NUM_MST-1:0];


    typedef enum logic [1:0] {
        SR_IDLE,
        SR_AR,
        SR_DATA
    } sr_state_t;

    sr_state_t sr_state [NUM_SLV-1:0];

    logic [MST_IDX_W-1:0] sr_owner [NUM_SLV-1:0];
    logic [MST_IDX_W-1:0] sr_rr    [NUM_SLV-1:0];

    mst_ar_t sr_ar_hold [NUM_SLV-1:0];


    // -------------------------------------------------------------------------
    // Combinational datapath / handshakes
    // -------------------------------------------------------------------------

    always_comb begin

        // ---------------------------------------------------------------------
        // Defaults
        // ---------------------------------------------------------------------

        for (int m = 0; m < NUM_MST; m++) begin
            mst_resp[m] = '0;
        end

        for (int s = 0; s < NUM_SLV; s++) begin
            slv_req[s] = '0;
        end


        if (rst_n) begin

            // =================================================================
            // AW admission
            //
            // Arbitration uses a rotating TOKEN, not valid-dependent priority.
            // Therefore aw_ready never depends on that master's aw_valid.
            // =================================================================

            for (int m = 0; m < NUM_MST; m++) begin
                if (mw_state[m] == MW_IDLE) begin

                    // Unmapped AW can always be accepted locally.
                    if (!aw_mapped[m]) begin
                        mst_resp[m].aw_ready = 1'b1;
                    end
                    else begin
                        for (int s = 0; s < NUM_SLV; s++) begin
                            if ((aw_target[m] == s) &&
                                (sw_state[s] == SW_IDLE) &&
                                (sw_rr[s] == m)) begin

                                mst_resp[m].aw_ready = 1'b1;
                            end
                        end
                    end
                end
            end


            // =================================================================
            // Mapped write channels
            // =================================================================

            for (int s = 0; s < NUM_SLV; s++) begin

                // -------------------------------------------------------------
                // AW
                // -------------------------------------------------------------
                if (sw_state[s] == SW_AW) begin
                    slv_req[s].aw       = sw_aw_hold[s];
                    slv_req[s].aw_valid = 1'b1;
                end

                // -------------------------------------------------------------
                // W
                //
                // Owner is fixed for the complete burst, so W cannot be
                // associated with a different AW.
                // -------------------------------------------------------------
                if (sw_state[s] == SW_DATA) begin
                    for (int m = 0; m < NUM_MST; m++) begin
                        if (sw_owner[s] == m) begin
                            slv_req[s].w       = mst_req[m].w;
                            slv_req[s].w_valid = mst_req[m].w_valid;

                            mst_resp[m].w_ready =
                                slv_resp[s].w_ready;
                        end
                    end
                end

                // -------------------------------------------------------------
                // B
                //
                // Only one write from this master can be outstanding, so the
                // reserved owner is exactly the master encoded into the ID.
                // -------------------------------------------------------------
                if (sw_state[s] == SW_B) begin
                    for (int m = 0; m < NUM_MST; m++) begin
                        if (sw_owner[s] == m) begin

                            mst_resp[m].b_valid =
                                slv_resp[s].b_valid;

                            mst_resp[m].b.id =
                                slv_resp[s].b.id[SLV_ID_W-1:0];

                            mst_resp[m].b.resp =
                                slv_resp[s].b.resp;

                            mst_resp[m].b.user =
                                slv_resp[s].b.user;

                            slv_req[s].b_ready =
                                mst_req[m].b_ready;
                        end
                    end
                end
            end


            // =================================================================
            // Local DECERR writes
            // =================================================================

            for (int m = 0; m < NUM_MST; m++) begin

                if (mw_state[m] == MW_LOCAL_W) begin
                    // Consume the whole write burst.
                    mst_resp[m].w_ready = 1'b1;
                end

                if (mw_state[m] == MW_LOCAL_B) begin
                    mst_resp[m].b_valid = 1'b1;

                    mst_resp[m].b.id   = local_w_id[m];
                    mst_resp[m].b.resp = RESP_DECERR;
                    mst_resp[m].b.user = local_w_user[m];
                end
            end


            // =================================================================
            // AR admission
            //
            // Independent round-robin token from the write side.
            // =================================================================

            for (int m = 0; m < NUM_MST; m++) begin
                if (!mr_busy_mapped[m] && !mr_busy_local[m]) begin

                    if (!ar_mapped[m]) begin
                        mst_resp[m].ar_ready = 1'b1;
                    end
                    else begin
                        for (int s = 0; s < NUM_SLV; s++) begin
                            if ((ar_target[m] == s) &&
                                (sr_state[s] == SR_IDLE) &&
                                (sr_rr[s] == m)) begin

                                mst_resp[m].ar_ready = 1'b1;
                            end
                        end
                    end
                end
            end


            // =================================================================
            // Mapped reads
            // =================================================================

            for (int s = 0; s < NUM_SLV; s++) begin

                // -------------------------------------------------------------
                // AR
                // -------------------------------------------------------------
                if (sr_state[s] == SR_AR) begin
                    slv_req[s].ar       = sr_ar_hold[s];
                    slv_req[s].ar_valid = 1'b1;
                end

                // -------------------------------------------------------------
                // R burst
                //
                // The slave remains reserved until LAST actually transfers.
                // Hence a burst cannot be interleaved with another transaction
                // through this slave-side read slot.
                // -------------------------------------------------------------
                if (sr_state[s] == SR_DATA) begin
                    for (int m = 0; m < NUM_MST; m++) begin
                        if (sr_owner[s] == m) begin

                            mst_resp[m].r_valid =
                                slv_resp[s].r_valid;

                            mst_resp[m].r.id =
                                slv_resp[s].r.id[SLV_ID_W-1:0];

                            mst_resp[m].r.data =
                                slv_resp[s].r.data;

                            mst_resp[m].r.resp =
                                slv_resp[s].r.resp;

                            mst_resp[m].r.last =
                                slv_resp[s].r.last;

                            mst_resp[m].r.user =
                                slv_resp[s].r.user;

                            slv_req[s].r_ready =
                                mst_req[m].r_ready;
                        end
                    end
                end
            end


            // =================================================================
            // Local DECERR reads
            // =================================================================

            for (int m = 0; m < NUM_MST; m++) begin
                if (mr_busy_local[m]) begin
                    mst_resp[m].r_valid = 1'b1;

                    mst_resp[m].r.id   = local_r_id[m];
                    mst_resp[m].r.data = '0;
                    mst_resp[m].r.resp = RESP_DECERR;

                    mst_resp[m].r.last =
                        (local_r_left[m] == 9'd1);

                    mst_resp[m].r.user =
                        local_r_user[m];
                end
            end
        end
    end


    // -------------------------------------------------------------------------
    // Sequential control
    // -------------------------------------------------------------------------

    always_ff @(posedge clk) begin

        if (!rst_n) begin

            // -----------------------------------------------------------------
            // Masters
            // -----------------------------------------------------------------

            for (int m = 0; m < NUM_MST; m++) begin
                mw_state[m] <= MW_IDLE;

                local_w_id[m]   <= '0;
                local_w_user[m] <= '0;

                mr_busy_mapped[m] <= 1'b0;
                mr_busy_local[m]  <= 1'b0;

                local_r_id[m]   <= '0;
                local_r_user[m] <= '0;
                local_r_left[m] <= '0;
            end


            // -----------------------------------------------------------------
            // Slave-side slots
            // -----------------------------------------------------------------

            for (int s = 0; s < NUM_SLV; s++) begin

                sw_state[s] <= SW_IDLE;
                sw_owner[s] <= '0;
                sw_rr[s]    <= '0;
                sw_aw_hold[s] <= '0;

                sr_state[s] <= SR_IDLE;
                sr_owner[s] <= '0;
                sr_rr[s]    <= '0;
                sr_ar_hold[s] <= '0;
            end
        end

        else begin

            // =================================================================
            // Per-slave WRITE state machines
            // =================================================================

            for (int s = 0; s < NUM_SLV; s++) begin

                case (sw_state[s])

                    // ---------------------------------------------------------
                    // Free slot: rotate round-robin token every free cycle.
                    //
                    // Because it rotates even when the token owner is idle,
                    // an idle master cannot block contenders behind it.
                    // ---------------------------------------------------------
                    SW_IDLE: begin

                        if (sw_rr[s] == NUM_MST-1)
                            sw_rr[s] <= '0;
                        else
                            sw_rr[s] <= sw_rr[s] + 1'b1;


                        // The token owner may claim the slot.
                        for (int m = 0; m < NUM_MST; m++) begin
                            if ((sw_rr[s] == m) &&
                                (mw_state[m] == MW_IDLE) &&
                                aw_mapped[m] &&
                                (aw_target[m] == s) &&
                                mst_req[m].aw_valid) begin

                                sw_state[s] <= SW_AW;
                                sw_owner[s] <= m[MST_IDX_W-1:0];

                                sw_aw_hold[s] <=
                                    widen_aw(mst_req[m].aw, m);

                                mw_state[m] <= MW_MAPPED;
                            end
                        end
                    end


                    // ---------------------------------------------------------
                    // Hold forwarded AW stable until accepted.
                    // ---------------------------------------------------------
                    SW_AW: begin
                        if (slv_resp[s].aw_ready) begin
                            sw_state[s] <= SW_DATA;
                        end
                    end


                    // ---------------------------------------------------------
                    // Route exactly this master's W stream until WLAST.
                    // ---------------------------------------------------------
                    SW_DATA: begin
                        if (slv_req[s].w_valid &&
                            slv_resp[s].w_ready &&
                            slv_req[s].w.last) begin

                            sw_state[s] <= SW_B;
                        end
                    end


                    // ---------------------------------------------------------
                    // Hold the reservation through response acceptance.
                    // ---------------------------------------------------------
                    SW_B: begin
                        if (slv_resp[s].b_valid &&
                            slv_req[s].b_ready) begin

                            sw_state[s] <= SW_IDLE;

                            for (int m = 0; m < NUM_MST; m++) begin
                                if (sw_owner[s] == m)
                                    mw_state[m] <= MW_IDLE;
                            end
                        end
                    end


                    default: begin
                        sw_state[s] <= SW_IDLE;
                    end

                endcase
            end


            // =================================================================
            // Per-master LOCAL WRITE decode-error handling
            // =================================================================

            for (int m = 0; m < NUM_MST; m++) begin

                case (mw_state[m])

                    MW_IDLE: begin
                        // Mapped requests are captured by the selected slave
                        // state machine above.
                        //
                        // An unmapped request is accepted locally.
                        if (!aw_mapped[m] &&
                            mst_req[m].aw_valid) begin

                            mw_state[m] <= MW_LOCAL_W;

                            local_w_id[m]   <= mst_req[m].aw.id;
                            local_w_user[m] <= mst_req[m].aw.user;
                        end
                    end


                    MW_LOCAL_W: begin
                        if (mst_req[m].w_valid &&
                            mst_req[m].w.last) begin

                            mw_state[m] <= MW_LOCAL_B;
                        end
                    end


                    MW_LOCAL_B: begin
                        if (mst_req[m].b_ready) begin
                            mw_state[m] <= MW_IDLE;
                        end
                    end


                    MW_MAPPED: begin
                        // Completion handled by the owning slave state machine.
                    end

                    default: begin
                        mw_state[m] <= MW_IDLE;
                    end

                endcase
            end


            // =================================================================
            // Per-slave READ state machines
            // =================================================================

            for (int s = 0; s < NUM_SLV; s++) begin

                case (sr_state[s])

                    SR_IDLE: begin

                        if (sr_rr[s] == NUM_MST-1)
                            sr_rr[s] <= '0;
                        else
                            sr_rr[s] <= sr_rr[s] + 1'b1;


                        for (int m = 0; m < NUM_MST; m++) begin
                            if ((sr_rr[s] == m) &&
                                !mr_busy_mapped[m] &&
                                !mr_busy_local[m] &&
                                ar_mapped[m] &&
                                (ar_target[m] == s) &&
                                mst_req[m].ar_valid) begin

                                sr_state[s] <= SR_AR;
                                sr_owner[s] <= m[MST_IDX_W-1:0];

                                sr_ar_hold[s] <=
                                    widen_ar(mst_req[m].ar, m);

                                mr_busy_mapped[m] <= 1'b1;
                            end
                        end
                    end


                    // Hold AR until downstream accepts it.
                    SR_AR: begin
                        if (slv_resp[s].ar_ready) begin
                            sr_state[s] <= SR_DATA;
                        end
                    end


                    // Keep this slot reserved for the entire burst.
                    SR_DATA: begin
                        if (slv_resp[s].r_valid &&
                            slv_req[s].r_ready &&
                            slv_resp[s].r.last) begin

                            sr_state[s] <= SR_IDLE;

                            for (int m = 0; m < NUM_MST; m++) begin
                                if (sr_owner[s] == m)
                                    mr_busy_mapped[m] <= 1'b0;
                            end
                        end
                    end


                    default: begin
                        sr_state[s] <= SR_IDLE;
                    end

                endcase
            end


            // =================================================================
            // Per-master local READ decode-error handling
            // =================================================================

            for (int m = 0; m < NUM_MST; m++) begin

                // -------------------------------------------------------------
                // Accept an unmapped AR locally.
                // -------------------------------------------------------------
                if (!mr_busy_mapped[m] &&
                    !mr_busy_local[m]  &&
                    !ar_mapped[m]      &&
                    mst_req[m].ar_valid) begin

                    mr_busy_local[m] <= 1'b1;

                    local_r_id[m]   <= mst_req[m].ar.id;
                    local_r_user[m] <= mst_req[m].ar.user;

                    // ARLEN is beats-1.
                    local_r_left[m] <=
                        {1'b0, mst_req[m].ar.len} + 9'd1;
                end

                // -------------------------------------------------------------
                // Advance one synthetic DECERR R beat per accepted transfer.
                // -------------------------------------------------------------
                else if (mr_busy_local[m] &&
                         mst_req[m].r_ready) begin

                    if (local_r_left[m] == 9'd1) begin
                        local_r_left[m] <= '0;
                        mr_busy_local[m] <= 1'b0;
                    end
                    else begin
                        local_r_left[m] <=
                            local_r_left[m] - 9'd1;
                    end
                end
            end
        end
    end

endmodule