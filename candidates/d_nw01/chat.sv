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

    localparam int Q_PTR_W = (MAX_TRANS > 1) ? $clog2(MAX_TRANS) : 1;
    localparam int Q_CNT_W = $clog2(MAX_TRANS + 1);

    localparam logic [1:0] RESP_DECERR = 2'b11;

    // ---------------------------------------------------------------------
    // Address metadata queues.  These track accepted transactions without
    // buffering burst data, so their depth can scale with MAX_TRANS.
    // ---------------------------------------------------------------------
    slv_aw_t aw_q [0:NUM_MST-1][0:MAX_TRANS-1];
    slv_ar_t ar_q [0:NUM_MST-1][0:MAX_TRANS-1];

    logic [Q_PTR_W-1:0] aw_wr_ptr_q [0:NUM_MST-1];
    logic [Q_PTR_W-1:0] aw_rd_ptr_q [0:NUM_MST-1];
    logic [Q_CNT_W-1:0] aw_count_q  [0:NUM_MST-1];

    logic [Q_PTR_W-1:0] ar_wr_ptr_q [0:NUM_MST-1];
    logic [Q_PTR_W-1:0] ar_rd_ptr_q [0:NUM_MST-1];
    logic [Q_CNT_W-1:0] ar_count_q  [0:NUM_MST-1];

    // ---------------------------------------------------------------------
    // Write execution state.
    //
    // W has no ID in AXI4, so each master consumes its accepted AWs in order.
    // The current W burst is decoupled from older B responses: after WLAST, a
    // new write may start even while previous B responses remain outstanding.
    // ---------------------------------------------------------------------
    logic                wtxn_active_q [0:NUM_MST-1];
    logic                wtxn_decerr_q [0:NUM_MST-1];
    logic [1:0]          wtxn_target_q [0:NUM_MST-1];
    logic [SLV_ID_W-1:0] wtxn_id_q     [0:NUM_MST-1];

    // At most one issued write per ID.  This simple restriction guarantees
    // AXI per-ID B ordering even when different IDs use different slaves.
    logic                wr_id_busy_q     [0:NUM_MST-1][0:(1<<SLV_ID_W)-1];
    logic                wr_resp_ready_q  [0:NUM_MST-1][0:(1<<SLV_ID_W)-1];
    logic                wr_id_decerr_q   [0:NUM_MST-1][0:(1<<SLV_ID_W)-1];
    logic [1:0]          wr_id_target_q   [0:NUM_MST-1][0:(1<<SLV_ID_W)-1];

    // A local decode-error B is metadata only; W data is never buffered.
    logic                dec_b_pending_q [0:NUM_MST-1];
    logic [SLV_ID_W-1:0] dec_b_id_q      [0:NUM_MST-1];

    // One B holding register per master guarantees a stable output under
    // upstream backpressure.  B storage is one beat, not a burst buffer.
    logic                b_hold_valid_q [0:NUM_MST-1];
    slv_b_t              b_hold_q       [0:NUM_MST-1];

    // Registered B source selection.  Selection may inspect VALID, but READY
    // is driven only from the registered selection on the following cycle.
    logic                b_sel_valid_q [0:NUM_MST-1];
    logic [1:0]          b_sel_s_q     [0:NUM_MST-1];
    logic [1:0]          b_rr_q        [0:NUM_MST-1];
    logic                b_local_turn_q[0:NUM_MST-1];
    logic                b_pick_found_c[0:NUM_MST-1];
    logic [1:0]          b_pick_s_c    [0:NUM_MST-1];

    // A slave accepts no second AW until the previous WLAST has crossed.  This
    // preserves slave-side AW/W association without W-data storage.
    logic                slv_w_busy_q  [0:NUM_SLV-1];
    logic [1:0]          slv_w_owner_q [0:NUM_SLV-1];

    // ---------------------------------------------------------------------
    // Read state.  Reads are issued one at a time per master; accepted ARs may
    // continue to queue to MAX_TRANS.  This is strictly ordered across IDs,
    // which is permitted by O2 and automatically satisfies O1/O4.
    // ---------------------------------------------------------------------
    logic                rd_active_q [0:NUM_MST-1];
    logic                rd_decerr_q [0:NUM_MST-1];
    logic [1:0]          rd_target_q [0:NUM_MST-1];
    logic [SLV_ID_W-1:0] rd_id_q     [0:NUM_MST-1];
    logic [7:0]          rd_len_q    [0:NUM_MST-1];
    logic [7:0]          rd_beat_q   [0:NUM_MST-1];

    // ---------------------------------------------------------------------
    // Registered per-slave AW/AR grants.  Holding the selected queue head until
    // handshake satisfies output stability when a slave backpressures.
    // ---------------------------------------------------------------------
    logic       aw_sel_valid_q [0:NUM_SLV-1];
    logic [1:0] aw_sel_m_q     [0:NUM_SLV-1];
    logic [1:0] aw_rr_q        [0:NUM_SLV-1];

    logic       ar_sel_valid_q [0:NUM_SLV-1];
    logic [1:0] ar_sel_m_q     [0:NUM_SLV-1];
    logic [1:0] ar_rr_q        [0:NUM_SLV-1];

    logic       aw_head_mapped_c [0:NUM_MST-1];
    logic [1:0] aw_head_target_c [0:NUM_MST-1];
    logic       ar_head_mapped_c [0:NUM_MST-1];
    logic [1:0] ar_head_target_c [0:NUM_MST-1];

    logic       aw_pick_found_c [0:NUM_SLV-1];
    logic [1:0] aw_pick_m_c     [0:NUM_SLV-1];
    logic       ar_pick_found_c [0:NUM_SLV-1];
    logic [1:0] ar_pick_m_c     [0:NUM_SLV-1];

    // Handshake/event bookkeeping.
    logic aw_push_c [0:NUM_MST-1];
    logic aw_pop_c  [0:NUM_MST-1];
    logic ar_push_c [0:NUM_MST-1];
    logic ar_pop_c  [0:NUM_MST-1];

    logic aw_decerr_start_c [0:NUM_MST-1];
    logic ar_decerr_start_c [0:NUM_MST-1];

    logic aw_issue_fire_c [0:NUM_SLV-1];
    logic ar_issue_fire_c [0:NUM_SLV-1];
    logic w_last_fire_c   [0:NUM_SLV-1];

    logic dec_w_last_fire_c [0:NUM_MST-1];
    logic dec_b_capture_c   [0:NUM_MST-1];
    logic b_capture_c       [0:NUM_MST-1];
    logic b_out_fire_c      [0:NUM_MST-1];
    logic local_r_fire_c    [0:NUM_MST-1];
    logic slave_r_last_c    [0:NUM_MST-1];

    // ---------------------------------------------------------------------
    // Address decode helpers.
    // ---------------------------------------------------------------------
    function automatic logic decode_hit(input addr_t addr);
        integer r;
        begin
            decode_hit = 1'b0;
            for (r = 0; r < NUM_SLV; r = r + 1) begin
                if ((!decode_hit) &&
                    (addr >= addr_map[r].start_addr) &&
                    (addr <  addr_map[r].end_addr)) begin
                    decode_hit = 1'b1;
                end
            end
        end
    endfunction

    function automatic logic [1:0] decode_port(input addr_t addr);
        integer r;
        logic found;
        begin
            decode_port = 2'b00;
            found = 1'b0;
            for (r = 0; r < NUM_SLV; r = r + 1) begin
                if ((!found) &&
                    (addr >= addr_map[r].start_addr) &&
                    (addr <  addr_map[r].end_addr)) begin
                    decode_port = addr_map[r].mst_port;
                    found = 1'b1;
                end
            end
        end
    endfunction

    // ---------------------------------------------------------------------
    // Queue-head decode.
    // ---------------------------------------------------------------------
    always_comb begin : p_head_decode
        integer m;

        for (m = 0; m < NUM_MST; m = m + 1) begin
            aw_head_mapped_c[m] = 1'b0;
            aw_head_target_c[m] = 2'b00;
            ar_head_mapped_c[m] = 1'b0;
            ar_head_target_c[m] = 2'b00;

            if (aw_count_q[m] != 0) begin
                aw_head_mapped_c[m] = decode_hit(aw_q[m][aw_rd_ptr_q[m]].addr);
                aw_head_target_c[m] = decode_port(aw_q[m][aw_rd_ptr_q[m]].addr);
            end

            if (ar_count_q[m] != 0) begin
                ar_head_mapped_c[m] = decode_hit(ar_q[m][ar_rd_ptr_q[m]].addr);
                ar_head_target_c[m] = decode_port(ar_q[m][ar_rd_ptr_q[m]].addr);
            end
        end
    end

    // ---------------------------------------------------------------------
    // Per-slave fair AW/AR candidate selection.
    // ---------------------------------------------------------------------
    always_comb begin : p_addr_pick
        integer s;
        integer k;
        integer idx;

        for (s = 0; s < NUM_SLV; s = s + 1) begin
            aw_pick_found_c[s] = 1'b0;
            aw_pick_m_c[s] = 2'b00;
            ar_pick_found_c[s] = 1'b0;
            ar_pick_m_c[s] = 2'b00;

            for (k = 0; k < NUM_MST; k = k + 1) begin
                idx = aw_rr_q[s] + k;
                if (idx >= NUM_MST) begin
                    idx = idx - NUM_MST;
                end

                if ((!aw_pick_found_c[s]) &&
                    (!slv_w_busy_q[s]) &&
                    (!wtxn_active_q[idx]) &&
                    (aw_count_q[idx] != 0) &&
                    aw_head_mapped_c[idx] &&
                    (aw_head_target_c[idx] == s[1:0]) &&
                    (!wr_id_busy_q[idx][aw_q[idx][aw_rd_ptr_q[idx]].id])) begin
                    aw_pick_found_c[s] = 1'b1;
                    aw_pick_m_c[s] = idx[1:0];
                end
            end

            for (k = 0; k < NUM_MST; k = k + 1) begin
                idx = ar_rr_q[s] + k;
                if (idx >= NUM_MST) begin
                    idx = idx - NUM_MST;
                end

                if ((!ar_pick_found_c[s]) &&
                    (!rd_active_q[idx]) &&
                    (ar_count_q[idx] != 0) &&
                    ar_head_mapped_c[idx] &&
                    (ar_head_target_c[idx] == s[1:0])) begin
                    ar_pick_found_c[s] = 1'b1;
                    ar_pick_m_c[s] = idx[1:0];
                end
            end
        end
    end

    // ---------------------------------------------------------------------
    // Per-master B source selection.  A selected slave held BVALID before it
    // was selected, so AXI requires it to keep the B payload stable until the
    // registered READY is asserted on the following cycle.
    // ---------------------------------------------------------------------
    always_comb begin : p_b_pick
        integer m;
        integer k;
        integer sidx;
        integer om;
        logic [1:0] origin;
        logic [SLV_ID_W-1:0] bid;

        for (m = 0; m < NUM_MST; m = m + 1) begin
            b_pick_found_c[m] = 1'b0;
            b_pick_s_c[m] = 2'b00;

            for (k = 0; k < NUM_SLV; k = k + 1) begin
                sidx = b_rr_q[m] + k;
                if (sidx >= NUM_SLV) begin
                    sidx = sidx - NUM_SLV;
                end

                origin = slv_resp[sidx].b.id[MST_ID_W-1 -: MST_IDX_W];
                bid = slv_resp[sidx].b.id[SLV_ID_W-1:0];
                om = origin;

                if ((!b_pick_found_c[m]) &&
                    slv_resp[sidx].b_valid &&
                    (om == m) &&
                    wr_id_busy_q[m][bid] &&
                    wr_resp_ready_q[m][bid] &&
                    (!wr_id_decerr_q[m][bid]) &&
                    (wr_id_target_q[m][bid] == sidx[1:0])) begin
                    b_pick_found_c[m] = 1'b1;
                    b_pick_s_c[m] = sidx[1:0];
                end
            end
        end
    end

    // ---------------------------------------------------------------------
    // Combinational routing and handshakes.
    // ---------------------------------------------------------------------
    always_comb begin : p_route
        integer m;
        integer s;
        integer selm;
        integer owner;
        integer srcs;
        integer om;
        logic [1:0] r_origin;
        logic [SLV_ID_W-1:0] rid;

        for (m = 0; m < NUM_MST; m = m + 1) begin
            mst_resp[m] = '0;

            aw_push_c[m] = 1'b0;
            aw_pop_c[m] = 1'b0;
            ar_push_c[m] = 1'b0;
            ar_pop_c[m] = 1'b0;
            aw_decerr_start_c[m] = 1'b0;
            ar_decerr_start_c[m] = 1'b0;
            dec_w_last_fire_c[m] = 1'b0;
            dec_b_capture_c[m] = 1'b0;
            b_capture_c[m] = 1'b0;
            b_out_fire_c[m] = 1'b0;
            local_r_fire_c[m] = 1'b0;
            slave_r_last_c[m] = 1'b0;

            if (rst_n) begin
                mst_resp[m].aw_ready = (aw_count_q[m] < MAX_TRANS);
                mst_resp[m].ar_ready = (ar_count_q[m] < MAX_TRANS);
            end

            aw_push_c[m] = rst_n && mst_req[m].aw_valid && mst_resp[m].aw_ready;
            ar_push_c[m] = rst_n && mst_req[m].ar_valid && mst_resp[m].ar_ready;

            // An unmapped AW starts locally only when its ID is free and the
            // single local DECERR-B metadata slot is available.
            if (rst_n &&
                (!wtxn_active_q[m]) &&
                (!dec_b_pending_q[m]) &&
                (aw_count_q[m] != 0) &&
                (!aw_head_mapped_c[m]) &&
                (!wr_id_busy_q[m][aw_q[m][aw_rd_ptr_q[m]].id])) begin
                aw_decerr_start_c[m] = 1'b1;
                aw_pop_c[m] = 1'b1;
            end

            if (rst_n &&
                (!rd_active_q[m]) &&
                (ar_count_q[m] != 0) &&
                (!ar_head_mapped_c[m])) begin
                ar_decerr_start_c[m] = 1'b1;
                ar_pop_c[m] = 1'b1;
            end

            // Current local decode-error W burst is consumed without storage.
            if (rst_n && wtxn_active_q[m] && wtxn_decerr_q[m]) begin
                mst_resp[m].w_ready = 1'b1;
                if (mst_req[m].w_valid && mst_req[m].w.last) begin
                    dec_w_last_fire_c[m] = 1'b1;
                end
            end

            // Stable one-beat B output register.
            if (rst_n && b_hold_valid_q[m]) begin
                mst_resp[m].b_valid = 1'b1;
                mst_resp[m].b = b_hold_q[m];
                b_out_fire_c[m] = mst_req[m].b_ready;
            end

            // Local DECERR B can be secured into the holding register as soon
            // as it is free.  No master READY is needed for this capture.
            if (rst_n &&
                (!b_hold_valid_q[m]) &&
                dec_b_pending_q[m] &&
                ((!b_sel_valid_q[m]) || b_local_turn_q[m])) begin
                dec_b_capture_c[m] = 1'b1;
            end

            // Local DECERR read response stream.
            if (rst_n && rd_active_q[m] && rd_decerr_q[m]) begin
                mst_resp[m].r_valid = 1'b1;
                mst_resp[m].r = '0;
                mst_resp[m].r.id = rd_id_q[m];
                mst_resp[m].r.data = '0;
                mst_resp[m].r.resp = RESP_DECERR;
                mst_resp[m].r.last = (rd_beat_q[m] == rd_len_q[m]);
                mst_resp[m].r.user = '0;
                local_r_fire_c[m] = mst_req[m].r_ready;
            end
        end

        for (s = 0; s < NUM_SLV; s = s + 1) begin
            slv_req[s] = '0;
            aw_issue_fire_c[s] = 1'b0;
            ar_issue_fire_c[s] = 1'b0;
            w_last_fire_c[s] = 1'b0;

            // Stable held AW grant.
            if (rst_n && aw_sel_valid_q[s]) begin
                selm = aw_sel_m_q[s];
                slv_req[s].aw_valid = 1'b1;
                // mst_aw_t differs from slv_aw_t only by the two MSB ID bits.
                slv_req[s].aw = {aw_sel_m_q[s], aw_q[selm][aw_rd_ptr_q[selm]]};

                if (slv_resp[s].aw_ready) begin
                    aw_issue_fire_c[s] = 1'b1;
                    aw_pop_c[selm] = 1'b1;
                end
            end

            // Stable held AR grant.
            if (rst_n && ar_sel_valid_q[s]) begin
                selm = ar_sel_m_q[s];
                slv_req[s].ar_valid = 1'b1;
                slv_req[s].ar = {ar_sel_m_q[s], ar_q[selm][ar_rd_ptr_q[selm]]};

                if (slv_resp[s].ar_ready) begin
                    ar_issue_fire_c[s] = 1'b1;
                    ar_pop_c[selm] = 1'b1;
                end
            end

            // W follows the AW owner until WLAST.
            if (rst_n && slv_w_busy_q[s]) begin
                owner = slv_w_owner_q[s];
                if (wtxn_active_q[owner] &&
                    (!wtxn_decerr_q[owner]) &&
                    (wtxn_target_q[owner] == s[1:0])) begin
                    slv_req[s].w = mst_req[owner].w;
                    slv_req[s].w_valid = mst_req[owner].w_valid;
                    mst_resp[owner].w_ready = slv_resp[s].w_ready;

                    if (mst_req[owner].w_valid &&
                        slv_resp[s].w_ready &&
                        mst_req[owner].w.last) begin
                        w_last_fire_c[s] = 1'b1;
                    end
                end
            end

            // Registered B-source READY.  It does not depend combinationally
            // on the slave's current b_valid.
            for (m = 0; m < NUM_MST; m = m + 1) begin
                if (rst_n &&
                    b_sel_valid_q[m] &&
                    (!b_hold_valid_q[m]) &&
                    ((!dec_b_pending_q[m]) || (!b_local_turn_q[m])) &&
                    (b_sel_s_q[m] == s[1:0])) begin
                    slv_req[s].b_ready = 1'b1;
                    if (slv_resp[s].b_valid) begin
                        b_capture_c[m] = 1'b1;
                    end
                end
            end

            // Read response routing.  The stored target makes the source unique
            // for each master, so no response arbiter is required.
            r_origin = slv_resp[s].r.id[MST_ID_W-1 -: MST_IDX_W];
            rid = slv_resp[s].r.id[SLV_ID_W-1:0];
            om = r_origin;

            if ((om >= 0) && (om < NUM_MST)) begin
                if (rst_n &&
                    rd_active_q[om] &&
                    (!rd_decerr_q[om]) &&
                    (rd_target_q[om] == s[1:0]) &&
                    (rid == rd_id_q[om])) begin
                    // READY depends on stored routing and upstream READY, not RVALID.
                    slv_req[s].r_ready = mst_req[om].r_ready;
                    if (slv_resp[s].r_valid) begin
                        mst_resp[om].r_valid = 1'b1;
                        mst_resp[om].r = slv_r_t'(slv_resp[s].r);
                        if (mst_req[om].r_ready && slv_resp[s].r.last) begin
                            slave_r_last_c[om] = 1'b1;
                        end
                    end
                end
            end
        end
    end

    // ---------------------------------------------------------------------
    // Sequential state.
    // ---------------------------------------------------------------------
    always_ff @(posedge clk) begin : p_seq
        integer m;
        integer s;
        integer idn;
        integer selm;
        integer owner;
        integer srcs;
        logic [SLV_ID_W-1:0] bid;

        if (!rst_n) begin
            for (m = 0; m < NUM_MST; m = m + 1) begin
                aw_wr_ptr_q[m] <= '0;
                aw_rd_ptr_q[m] <= '0;
                aw_count_q[m] <= '0;
                ar_wr_ptr_q[m] <= '0;
                ar_rd_ptr_q[m] <= '0;
                ar_count_q[m] <= '0;

                wtxn_active_q[m] <= 1'b0;
                wtxn_decerr_q[m] <= 1'b0;
                wtxn_target_q[m] <= 2'b00;
                wtxn_id_q[m] <= '0;

                dec_b_pending_q[m] <= 1'b0;
                dec_b_id_q[m] <= '0;

                b_hold_valid_q[m] <= 1'b0;
                b_hold_q[m] <= '0;
                b_sel_valid_q[m] <= 1'b0;
                b_sel_s_q[m] <= 2'b00;
                b_rr_q[m] <= 2'b00;
                b_local_turn_q[m] <= 1'b0;

                rd_active_q[m] <= 1'b0;
                rd_decerr_q[m] <= 1'b0;
                rd_target_q[m] <= 2'b00;
                rd_id_q[m] <= '0;
                rd_len_q[m] <= 8'b0;
                rd_beat_q[m] <= 8'b0;

                for (idn = 0; idn < (1<<SLV_ID_W); idn = idn + 1) begin
                    wr_id_busy_q[m][idn] <= 1'b0;
                    wr_resp_ready_q[m][idn] <= 1'b0;
                    wr_id_decerr_q[m][idn] <= 1'b0;
                    wr_id_target_q[m][idn] <= 2'b00;
                end
            end

            for (s = 0; s < NUM_SLV; s = s + 1) begin
                slv_w_busy_q[s] <= 1'b0;
                slv_w_owner_q[s] <= 2'b00;

                aw_sel_valid_q[s] <= 1'b0;
                aw_sel_m_q[s] <= 2'b00;
                aw_rr_q[s] <= 2'b00;

                ar_sel_valid_q[s] <= 1'b0;
                ar_sel_m_q[s] <= 2'b00;
                ar_rr_q[s] <= 2'b00;
            end
        end
        else begin
            // -------------------------------------------------------------
            // Accepted address queues.
            // -------------------------------------------------------------
            for (m = 0; m < NUM_MST; m = m + 1) begin
                if (aw_push_c[m]) begin
                    aw_q[m][aw_wr_ptr_q[m]] <= mst_req[m].aw;
                    aw_wr_ptr_q[m] <= aw_wr_ptr_q[m] + 1'b1;
                end
                if (aw_pop_c[m]) begin
                    aw_rd_ptr_q[m] <= aw_rd_ptr_q[m] + 1'b1;
                end
                case ({aw_push_c[m], aw_pop_c[m]})
                    2'b10: aw_count_q[m] <= aw_count_q[m] + 1'b1;
                    2'b01: aw_count_q[m] <= aw_count_q[m] - 1'b1;
                    default: aw_count_q[m] <= aw_count_q[m];
                endcase

                if (ar_push_c[m]) begin
                    ar_q[m][ar_wr_ptr_q[m]] <= mst_req[m].ar;
                    ar_wr_ptr_q[m] <= ar_wr_ptr_q[m] + 1'b1;
                end
                if (ar_pop_c[m]) begin
                    ar_rd_ptr_q[m] <= ar_rd_ptr_q[m] + 1'b1;
                end
                case ({ar_push_c[m], ar_pop_c[m]})
                    2'b10: ar_count_q[m] <= ar_count_q[m] + 1'b1;
                    2'b01: ar_count_q[m] <= ar_count_q[m] - 1'b1;
                    default: ar_count_q[m] <= ar_count_q[m];
                endcase

                // Start a local decode-error write and reserve its ID.
                if (aw_decerr_start_c[m]) begin
                    wtxn_active_q[m] <= 1'b1;
                    wtxn_decerr_q[m] <= 1'b1;
                    wtxn_target_q[m] <= 2'b00;
                    wtxn_id_q[m] <= aw_q[m][aw_rd_ptr_q[m]].id;

                    wr_id_busy_q[m][aw_q[m][aw_rd_ptr_q[m]].id] <= 1'b1;
                    wr_resp_ready_q[m][aw_q[m][aw_rd_ptr_q[m]].id] <= 1'b0;
                    wr_id_decerr_q[m][aw_q[m][aw_rd_ptr_q[m]].id] <= 1'b1;
                end

                // Finish local W and create a local B obligation.
                if (dec_w_last_fire_c[m]) begin
                    wtxn_active_q[m] <= 1'b0;
                    dec_b_pending_q[m] <= 1'b1;
                    dec_b_id_q[m] <= wtxn_id_q[m];
                    wr_resp_ready_q[m][wtxn_id_q[m]] <= 1'b1;
                end

                // Capture local DECERR B into the stable output register.
                if (dec_b_capture_c[m]) begin
                    b_hold_valid_q[m] <= 1'b1;
                    b_hold_q[m].id <= dec_b_id_q[m];
                    b_hold_q[m].resp <= RESP_DECERR;
                    b_hold_q[m].user <= '0;

                    dec_b_pending_q[m] <= 1'b0;
                    wr_id_busy_q[m][dec_b_id_q[m]] <= 1'b0;
                    wr_resp_ready_q[m][dec_b_id_q[m]] <= 1'b0;
                    wr_id_decerr_q[m][dec_b_id_q[m]] <= 1'b0;
                    b_local_turn_q[m] <= 1'b0;
                end

                // Master accepts the held B response.
                if (b_hold_valid_q[m] && b_out_fire_c[m]) begin
                    b_hold_valid_q[m] <= 1'b0;
                end

                // Latch a slave B source when no source is already held.
                if (!b_sel_valid_q[m]) begin
                    if (b_pick_found_c[m]) begin
                        b_sel_valid_q[m] <= 1'b1;
                        b_sel_s_q[m] <= b_pick_s_c[m];
                    end
                end

                // Capture selected mapped B response.
                if (b_capture_c[m]) begin
                    srcs = b_sel_s_q[m];
                    bid = slv_resp[srcs].b.id[SLV_ID_W-1:0];

                    b_hold_valid_q[m] <= 1'b1;
                    b_hold_q[m] <= slv_b_t'(slv_resp[srcs].b);
                    b_sel_valid_q[m] <= 1'b0;

                    if (srcs == (NUM_SLV-1)) begin
                        b_rr_q[m] <= 2'b00;
                    end
                    else begin
                        b_rr_q[m] <= srcs[1:0] + 1'b1;
                    end

                    wr_id_busy_q[m][bid] <= 1'b0;
                    wr_resp_ready_q[m][bid] <= 1'b0;
                    wr_id_decerr_q[m][bid] <= 1'b0;
                    b_local_turn_q[m] <= 1'b1;
                end

                // Start a local decode-error read.
                if (ar_decerr_start_c[m]) begin
                    rd_active_q[m] <= 1'b1;
                    rd_decerr_q[m] <= 1'b1;
                    rd_target_q[m] <= 2'b00;
                    rd_id_q[m] <= ar_q[m][ar_rd_ptr_q[m]].id;
                    rd_len_q[m] <= ar_q[m][ar_rd_ptr_q[m]].len;
                    rd_beat_q[m] <= 8'b0;
                end

                // Local DECERR R progression.
                if (rd_active_q[m] && rd_decerr_q[m] && local_r_fire_c[m]) begin
                    if (rd_beat_q[m] == rd_len_q[m]) begin
                        rd_active_q[m] <= 1'b0;
                        rd_decerr_q[m] <= 1'b0;
                        rd_beat_q[m] <= 8'b0;
                    end
                    else begin
                        rd_beat_q[m] <= rd_beat_q[m] + 1'b1;
                    end
                end

                if (slave_r_last_c[m]) begin
                    rd_active_q[m] <= 1'b0;
                    rd_decerr_q[m] <= 1'b0;
                end
            end

            // -------------------------------------------------------------
            // Slave-side arbiters and current W ownership.
            // -------------------------------------------------------------
            for (s = 0; s < NUM_SLV; s = s + 1) begin
                if (aw_sel_valid_q[s]) begin
                    if (aw_issue_fire_c[s]) begin
                        selm = aw_sel_m_q[s];
                        aw_sel_valid_q[s] <= 1'b0;

                        if (selm == (NUM_MST-1)) begin
                            aw_rr_q[s] <= 2'b00;
                        end
                        else begin
                            aw_rr_q[s] <= selm[1:0] + 1'b1;
                        end

                        wtxn_active_q[selm] <= 1'b1;
                        wtxn_decerr_q[selm] <= 1'b0;
                        wtxn_target_q[selm] <= s[1:0];
                        wtxn_id_q[selm] <= aw_q[selm][aw_rd_ptr_q[selm]].id;

                        wr_id_busy_q[selm][aw_q[selm][aw_rd_ptr_q[selm]].id] <= 1'b1;
                        wr_resp_ready_q[selm][aw_q[selm][aw_rd_ptr_q[selm]].id] <= 1'b0;
                        wr_id_decerr_q[selm][aw_q[selm][aw_rd_ptr_q[selm]].id] <= 1'b0;
                        wr_id_target_q[selm][aw_q[selm][aw_rd_ptr_q[selm]].id] <= s[1:0];

                        slv_w_busy_q[s] <= 1'b1;
                        slv_w_owner_q[s] <= selm[1:0];
                    end
                end
                else if (aw_pick_found_c[s]) begin
                    aw_sel_valid_q[s] <= 1'b1;
                    aw_sel_m_q[s] <= aw_pick_m_c[s];
                end

                if (ar_sel_valid_q[s]) begin
                    if (ar_issue_fire_c[s]) begin
                        selm = ar_sel_m_q[s];
                        ar_sel_valid_q[s] <= 1'b0;

                        if (selm == (NUM_MST-1)) begin
                            ar_rr_q[s] <= 2'b00;
                        end
                        else begin
                            ar_rr_q[s] <= selm[1:0] + 1'b1;
                        end

                        rd_active_q[selm] <= 1'b1;
                        rd_decerr_q[selm] <= 1'b0;
                        rd_target_q[selm] <= s[1:0];
                        rd_id_q[selm] <= ar_q[selm][ar_rd_ptr_q[selm]].id;
                        rd_len_q[selm] <= ar_q[selm][ar_rd_ptr_q[selm]].len;
                        rd_beat_q[selm] <= 8'b0;
                    end
                end
                else if (ar_pick_found_c[s]) begin
                    ar_sel_valid_q[s] <= 1'b1;
                    ar_sel_m_q[s] <= ar_pick_m_c[s];
                end

                // WLAST frees both the master W executor and slave W owner.
                if (w_last_fire_c[s]) begin
                    owner = slv_w_owner_q[s];
                    slv_w_busy_q[s] <= 1'b0;
                    wtxn_active_q[owner] <= 1'b0;
                    wr_resp_ready_q[owner][wtxn_id_q[owner]] <= 1'b1;
                end
            end
        end
    end

endmodule