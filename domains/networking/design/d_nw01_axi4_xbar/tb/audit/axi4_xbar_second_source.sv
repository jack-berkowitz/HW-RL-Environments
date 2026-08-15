// =============================================================================
// axi4_xbar_second_source.sv -- SECOND SOURCE. NEVER SHIPPED.
// =============================================================================
// NOT AN ORACLE. A falsifier. Its only job is to fail, and if it fails the
// CHECKER is wrong, not this file.
//
// It exists because C1 and C2 are new normative checks derived from
// measurements of one implementation, and nothing had ever passed them except
// the module they were measured from. A check tuned to one design's numbers is
// a rediscover-the-reference test, and the only way to find out is to write a
// correct crossbar that is structurally unlike the anchor and see whether the
// checker still accepts it.
//
// DELIBERATE DIFFERENCES FROM THE VENDORED ANCHOR
// -----------------------------------------------
//   anchor (PULP axi_xbar)          this file
//   ------------------------------  ------------------------------------------
//   per-master demux + per-slave    ONE flat routing matrix; no demux/mux
//     mux hierarchy                   hierarchy at all
//   rr_arb_tree                     rotating-priority mask arbiter, written out
//   spill registers on AW/AR        NO channel registers anywhere
//     (CUT_ALL_AX)
//   id_queue structures             flat per-(master,ID) counter + destination
//   MAX_TRANS+1 observable          EXACTLY MAX_TRANS observable outstanding
//     outstanding
//
// The last two are the point. If C1 were pinned to the anchor's buffering this
// file would fail it, and if C2's threshold were pinned to the anchor's exact
// arbitration ratio this file would fail that.
//
// Correctness obligations it still meets: ID widening, address decode with
// DECERR, per-ID ordering (O1), cross-ID freedom (O2), W contiguity (O3),
// R contiguity (O4), and liveness (L1/L2) via rotating priority everywhere.
// =============================================================================

`timescale 1ns/1ps

module axi4_xbar
  import axi4_xbar_pkg::*;
#(
    parameter int NUM_MST   = 2,
    parameter int NUM_SLV   = 2,
    parameter int MAX_TRANS = 8
) (
    input  logic clk,
    input  logic rst_n,
    input  slv_req_t   [NUM_MST-1:0] mst_req,
    output slv_resp_t  [NUM_MST-1:0] mst_resp,
    output mst_req_t   [NUM_SLV-1:0] slv_req,
    input  mst_resp_t  [NUM_SLV-1:0] slv_resp,
    input  xbar_rule_t [NUM_SLV-1:0] addr_map
);

    // The unmapped destination is modelled as one extra "slave" index. That
    // way decode, the per-ID hazard and the W ordering all treat DECERR as an
    // ordinary destination instead of needing a parallel special case -- which
    // is where beat-count bugs live.
    localparam int ERR  = NUM_SLV;          // virtual destination
    localparam int NDST = NUM_SLV + 1;
    localparam int NID  = 1 << SLV_ID_W;
    localparam int WSQD = NUM_MST * MAX_TRANS;   // per-slave AW source queue

    initial if (NUM_MST > 4)
        $error("axi4_xbar: NUM_MST=%0d exceeds the MST_IDX_W=2 cap", NUM_MST);

    // ---------------------------------------------------------------- decode
    function automatic int decode(input addr_t a);
        decode = ERR;
        for (int s = 0; s < NUM_SLV; s++)
            if (a >= addr_map[s].start_addr && a < addr_map[s].end_addr)
                decode = int'(addr_map[s].mst_port);
    endfunction

    // ======================================================================
    // READ PATH
    // ======================================================================
    int  r_out    [0:NUM_MST-1];                 // outstanding reads per master
    int  rid_cnt  [0:NUM_MST-1][0:NID-1];        // per-ID outstanding
    int  rid_dst  [0:NUM_MST-1][0:NID-1];        // per-ID destination (O1 lock)

    int  ar_dst   [0:NUM_MST-1];
    logic [NUM_MST-1:0] ar_ok;                   // may this master's AR go now?

    always_comb begin
        for (int m = 0; m < NUM_MST; m++) begin
            ar_dst[m] = decode(mst_req[m].ar.addr);
            ar_ok[m]  = mst_req[m].ar_valid
                        && (r_out[m] < MAX_TRANS)
                        // O1: a second read with the SAME id may not be sent to
                        // a DIFFERENT destination while the first is in flight,
                        // or the two slaves could answer out of order.
                        && ((rid_cnt[m][int'(mst_req[m].ar.id)] == 0)
                            || (rid_dst[m][int'(mst_req[m].ar.id)] == ar_dst[m]));
        end
    end

    // rotating-priority AR arbiter, one per destination
    int  rr_ar    [0:NDST-1];
    int  ar_win   [0:NDST-1];
    logic [NDST-1:0] ar_win_v;

    always_comb begin
        for (int d = 0; d < NDST; d++) begin
            ar_win[d]   = 0;
            ar_win_v[d] = 1'b0;
            for (int k = 0; k < NUM_MST; k++) begin
                int m; m = (rr_ar[d] + k) % NUM_MST;
                if (!ar_win_v[d] && ar_ok[m] && ar_dst[m] == d) begin
                    ar_win[d]   = m;
                    ar_win_v[d] = 1'b1;
                end
            end
        end
    end

    // ---- per-master read error responder (the ERR destination) -------------
    logic    err_r_busy [0:NUM_MST-1];
    int      err_r_left [0:NUM_MST-1];
    slv_id_t err_r_id   [0:NUM_MST-1];

    // ---- R return: lock a master's R channel to one source until RLAST -----
    // Guarantees O4 contiguity without forbidding cross-ID interleaving, which
    // simply does not occur here. That is permitted, not required.
    int   r_src     [0:NUM_MST-1];     // 0..NUM_SLV-1, or ERR
    logic r_locked  [0:NUM_MST-1];
    int   rr_r      [0:NUM_MST-1];

    int   r_pick    [0:NUM_MST-1];
    logic [NUM_MST-1:0] r_pick_v;

    always_comb begin
        for (int m = 0; m < NUM_MST; m++) begin
            r_pick[m]   = 0;
            r_pick_v[m] = 1'b0;
            if (r_locked[m]) begin
                r_pick[m]   = r_src[m];
                r_pick_v[m] = 1'b1;
            end else begin
                // error responses first if pending, else rotate over slaves
                if (err_r_busy[m]) begin
                    r_pick[m]   = ERR;
                    r_pick_v[m] = 1'b1;
                end else begin
                    for (int k = 0; k < NUM_SLV; k++) begin
                        int s; s = (rr_r[m] + k) % NUM_SLV;
                        if (!r_pick_v[m] && slv_resp[s].r_valid
                            && int'(slv_resp[s].r.id[MST_ID_W-1:SLV_ID_W]) == m) begin
                            r_pick[m]   = s;
                            r_pick_v[m] = 1'b1;
                        end
                    end
                end
            end
        end
    end

    // ======================================================================
    // WRITE PATH
    // ======================================================================
    int  w_out   [0:NUM_MST-1];
    int  wid_cnt [0:NUM_MST-1][0:NID-1];
    int  wid_dst [0:NUM_MST-1][0:NID-1];

    int  aw_dst  [0:NUM_MST-1];
    logic [NUM_MST-1:0] aw_ok;

    // per-master queue of destinations, in AW acceptance order: W beats follow
    // AW order per master (AXI4 has no WID)
    int  awq     [0:NUM_MST-1][0:MAX_TRANS-1];
    int  awq_hd  [0:NUM_MST-1];
    int  awq_tl  [0:NUM_MST-1];
    // per-destination queue of sources, in AW acceptance order at that slave
    int  wsq     [0:NDST-1][0:WSQD-1];
    int  wsq_hd  [0:NDST-1];
    int  wsq_tl  [0:NDST-1];

    always_comb begin
        for (int m = 0; m < NUM_MST; m++) begin
            aw_dst[m] = decode(mst_req[m].aw.addr);
            aw_ok[m]  = mst_req[m].aw_valid
                        && (w_out[m] < MAX_TRANS)
                        && ((awq_tl[m] - awq_hd[m]) < MAX_TRANS)
                        && ((wid_cnt[m][int'(mst_req[m].aw.id)] == 0)
                            || (wid_dst[m][int'(mst_req[m].aw.id)] == aw_dst[m]));
        end
    end

    int  rr_aw   [0:NDST-1];
    int  aw_win  [0:NDST-1];
    logic [NDST-1:0] aw_win_v;

    always_comb begin
        for (int d = 0; d < NDST; d++) begin
            aw_win[d]   = 0;
            aw_win_v[d] = 1'b0;
            for (int k = 0; k < NUM_MST; k++) begin
                int m; m = (rr_aw[d] + k) % NUM_MST;
                if (!aw_win_v[d] && aw_ok[m] && aw_dst[m] == d
                    && ((wsq_tl[d] - wsq_hd[d]) < WSQD)) begin
                    aw_win[d]   = m;
                    aw_win_v[d] = 1'b1;
                end
            end
        end
    end

    // W routing: master m's beats go to awq head; slave d takes from wsq head.
    // Both must agree, which is what keeps a burst contiguous at the slave.
    int   w_dst  [0:NUM_MST-1];
    logic [NUM_MST-1:0] w_go;
    always_comb begin
        for (int m = 0; m < NUM_MST; m++) begin
            w_dst[m] = ERR;
            w_go[m]  = 1'b0;
            if (awq_tl[m] != awq_hd[m]) begin
                w_dst[m] = awq[m][awq_hd[m] % MAX_TRANS];
                if (wsq_tl[w_dst[m]] != wsq_hd[w_dst[m]]
                    && wsq[w_dst[m]][wsq_hd[w_dst[m]] % WSQD] == m)
                    w_go[m] = 1'b1;
            end
        end
    end

    // write error responder
    logic    err_b_busy [0:NUM_MST-1];
    slv_id_t err_b_id   [0:NUM_MST-1];

    int   rr_b [0:NUM_MST-1];
    int   b_pick [0:NUM_MST-1];
    logic [NUM_MST-1:0] b_pick_v;
    always_comb begin
        for (int m = 0; m < NUM_MST; m++) begin
            b_pick[m]   = 0;
            b_pick_v[m] = 1'b0;
            if (err_b_busy[m]) begin
                b_pick[m]   = ERR;
                b_pick_v[m] = 1'b1;
            end else begin
                for (int k = 0; k < NUM_SLV; k++) begin
                    int s; s = (rr_b[m] + k) % NUM_SLV;
                    if (!b_pick_v[m] && slv_resp[s].b_valid
                        && int'(slv_resp[s].b.id[MST_ID_W-1:SLV_ID_W]) == m) begin
                        b_pick[m]   = s;
                        b_pick_v[m] = 1'b1;
                    end
                end
            end
        end
    end

    // ======================================================================
    // OUTPUT WIRING
    // ======================================================================
    always_comb begin
        for (int s = 0; s < NUM_SLV; s++) begin
            slv_req[s] = '0;

            // AR
            slv_req[s].ar_valid  = ar_win_v[s];
            slv_req[s].ar.id     = {mst_id_t'(ar_win[s]) << SLV_ID_W}
                                   | mst_id_t'(mst_req[ar_win[s]].ar.id);
            slv_req[s].ar.addr   = mst_req[ar_win[s]].ar.addr;
            slv_req[s].ar.len    = mst_req[ar_win[s]].ar.len;
            slv_req[s].ar.size   = mst_req[ar_win[s]].ar.size;
            slv_req[s].ar.burst  = mst_req[ar_win[s]].ar.burst;
            slv_req[s].ar.lock   = mst_req[ar_win[s]].ar.lock;
            slv_req[s].ar.cache  = mst_req[ar_win[s]].ar.cache;
            slv_req[s].ar.prot   = mst_req[ar_win[s]].ar.prot;
            slv_req[s].ar.qos    = mst_req[ar_win[s]].ar.qos;
            slv_req[s].ar.region = mst_req[ar_win[s]].ar.region;
            slv_req[s].ar.user   = mst_req[ar_win[s]].ar.user;

            // AW
            slv_req[s].aw_valid  = aw_win_v[s];
            slv_req[s].aw.id     = {mst_id_t'(aw_win[s]) << SLV_ID_W}
                                   | mst_id_t'(mst_req[aw_win[s]].aw.id);
            slv_req[s].aw.addr   = mst_req[aw_win[s]].aw.addr;
            slv_req[s].aw.len    = mst_req[aw_win[s]].aw.len;
            slv_req[s].aw.size   = mst_req[aw_win[s]].aw.size;
            slv_req[s].aw.burst  = mst_req[aw_win[s]].aw.burst;
            slv_req[s].aw.lock   = mst_req[aw_win[s]].aw.lock;
            slv_req[s].aw.cache  = mst_req[aw_win[s]].aw.cache;
            slv_req[s].aw.prot   = mst_req[aw_win[s]].aw.prot;
            slv_req[s].aw.qos    = mst_req[aw_win[s]].aw.qos;
            slv_req[s].aw.region = mst_req[aw_win[s]].aw.region;
            slv_req[s].aw.user   = mst_req[aw_win[s]].aw.user;

            // W -- from the master at the head of this slave's source queue
            slv_req[s].w_valid = 1'b0;
            slv_req[s].w       = '0;
            for (int m = 0; m < NUM_MST; m++)
                if (w_go[m] && w_dst[m] == s && mst_req[m].w_valid) begin
                    slv_req[s].w_valid = 1'b1;
                    slv_req[s].w.data  = mst_req[m].w.data;
                    slv_req[s].w.strb  = mst_req[m].w.strb;
                    slv_req[s].w.last  = mst_req[m].w.last;
                    slv_req[s].w.user  = mst_req[m].w.user;
                end

            // response readies
            slv_req[s].r_ready = 1'b0;
            slv_req[s].b_ready = 1'b0;
            for (int m = 0; m < NUM_MST; m++) begin
                if (r_pick_v[m] && r_pick[m] == s) slv_req[s].r_ready = mst_req[m].r_ready;
                if (b_pick_v[m] && b_pick[m] == s) slv_req[s].b_ready = mst_req[m].b_ready;
            end
        end
    end

    always_comb begin
        for (int m = 0; m < NUM_MST; m++) begin
            mst_resp[m] = '0;

            // AR ready: granted at its destination, and that destination ready
            mst_resp[m].ar_ready = ar_ok[m]
                && ar_win_v[ar_dst[m]] && ar_win[ar_dst[m]] == m
                && ((ar_dst[m] == ERR) ? !err_r_busy[m] : slv_resp[ar_dst[m]].ar_ready);

            mst_resp[m].aw_ready = aw_ok[m]
                && aw_win_v[aw_dst[m]] && aw_win[aw_dst[m]] == m
                && ((aw_dst[m] == ERR) ? !err_b_busy[m] : slv_resp[aw_dst[m]].aw_ready);

            // W ready
            mst_resp[m].w_ready = w_go[m]
                && ((w_dst[m] == ERR) ? 1'b1 : slv_resp[w_dst[m]].w_ready);

            // R
            if (r_pick_v[m] && r_pick[m] == ERR) begin
                mst_resp[m].r_valid = err_r_busy[m];
                mst_resp[m].r.id    = err_r_id[m];
                mst_resp[m].r.data  = '0;
                mst_resp[m].r.resp  = RESP_DECERR;
                mst_resp[m].r.last  = (err_r_left[m] == 1);
            end else if (r_pick_v[m]) begin
                mst_resp[m].r_valid = slv_resp[r_pick[m]].r_valid;
                mst_resp[m].r.id    = slv_id_t'(slv_resp[r_pick[m]].r.id[SLV_ID_W-1:0]);
                mst_resp[m].r.data  = slv_resp[r_pick[m]].r.data;
                mst_resp[m].r.resp  = slv_resp[r_pick[m]].r.resp;
                mst_resp[m].r.last  = slv_resp[r_pick[m]].r.last;
                mst_resp[m].r.user  = slv_resp[r_pick[m]].r.user;
            end

            // B
            if (b_pick_v[m] && b_pick[m] == ERR) begin
                mst_resp[m].b_valid = err_b_busy[m];
                mst_resp[m].b.id    = err_b_id[m];
                mst_resp[m].b.resp  = RESP_DECERR;
            end else if (b_pick_v[m]) begin
                mst_resp[m].b_valid = slv_resp[b_pick[m]].b_valid;
                mst_resp[m].b.id    = slv_id_t'(slv_resp[b_pick[m]].b.id[SLV_ID_W-1:0]);
                mst_resp[m].b.resp  = slv_resp[b_pick[m]].b.resp;
                mst_resp[m].b.user  = slv_resp[b_pick[m]].b.user;
            end
        end
    end

    // ======================================================================
    // STATE
    // ======================================================================
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            for (int d = 0; d < NDST; d++) begin
                rr_ar[d] <= 0; rr_aw[d] <= 0; wsq_hd[d] <= 0; wsq_tl[d] <= 0;
            end
            for (int m = 0; m < NUM_MST; m++) begin
                r_out[m] <= 0; w_out[m] <= 0;
                rr_r[m] <= 0; rr_b[m] <= 0;
                r_locked[m] <= 1'b0; r_src[m] <= 0;
                awq_hd[m] <= 0; awq_tl[m] <= 0;
                err_r_busy[m] <= 1'b0; err_r_left[m] <= 0;
                err_b_busy[m] <= 1'b0;
                for (int i = 0; i < NID; i++) begin
                    rid_cnt[m][i] <= 0; rid_dst[m][i] <= 0;
                    wid_cnt[m][i] <= 0; wid_dst[m][i] <= 0;
                end
            end
        end else begin
            // ---- AR accepted ----
            for (int m = 0; m < NUM_MST; m++) begin
                if (mst_req[m].ar_valid && mst_resp[m].ar_ready) begin
                    r_out[m] <= r_out[m] + 1;
                    rid_cnt[m][int'(mst_req[m].ar.id)] <= rid_cnt[m][int'(mst_req[m].ar.id)] + 1;
                    rid_dst[m][int'(mst_req[m].ar.id)] <= ar_dst[m];
                    rr_ar[ar_dst[m]] <= (m + 1) % NUM_MST;
                    if (ar_dst[m] == ERR) begin
                        err_r_busy[m] <= 1'b1;
                        err_r_left[m] <= int'(mst_req[m].ar.len) + 1;
                        err_r_id[m]   <= mst_req[m].ar.id;
                    end
                end
                // ---- R beat consumed ----
                if (mst_resp[m].r_valid && mst_req[m].r_ready) begin
                    if (mst_resp[m].r.last) begin
                        r_locked[m] <= 1'b0;
                        rr_r[m]     <= (r_pick[m] + 1) % NUM_SLV;
                        r_out[m]    <= r_out[m] - 1
                                       + ((mst_req[m].ar_valid && mst_resp[m].ar_ready) ? 1 : 0);
                        rid_cnt[m][int'(mst_resp[m].r.id)] <=
                            rid_cnt[m][int'(mst_resp[m].r.id)] - 1
                            + ((mst_req[m].ar_valid && mst_resp[m].ar_ready
                                && mst_req[m].ar.id == mst_resp[m].r.id) ? 1 : 0);
                    end else begin
                        r_locked[m] <= 1'b1;
                        r_src[m]    <= r_pick[m];
                    end
                    if (r_pick[m] == ERR) begin
                        err_r_left[m] <= err_r_left[m] - 1;
                        if (err_r_left[m] == 1) err_r_busy[m] <= 1'b0;
                    end
                end

                // ---- AW accepted ----
                if (mst_req[m].aw_valid && mst_resp[m].aw_ready) begin
                    w_out[m] <= w_out[m] + 1;
                    wid_cnt[m][int'(mst_req[m].aw.id)] <= wid_cnt[m][int'(mst_req[m].aw.id)] + 1;
                    wid_dst[m][int'(mst_req[m].aw.id)] <= aw_dst[m];
                    rr_aw[aw_dst[m]] <= (m + 1) % NUM_MST;
                    awq[m][awq_tl[m] % MAX_TRANS] <= aw_dst[m];
                    awq_tl[m] <= awq_tl[m] + 1;
                    wsq[aw_dst[m]][wsq_tl[aw_dst[m]] % WSQD] <= m;
                    wsq_tl[aw_dst[m]] <= wsq_tl[aw_dst[m]] + 1;
                end
                // ---- W beat consumed ----
                if (mst_req[m].w_valid && mst_resp[m].w_ready && mst_req[m].w.last) begin
                    awq_hd[m] <= awq_hd[m] + 1;
                    wsq_hd[w_dst[m]] <= wsq_hd[w_dst[m]] + 1;
                    if (w_dst[m] == ERR) begin
                        err_b_busy[m] <= 1'b1;
                        err_b_id[m]   <= mst_req[m].w.last ? err_b_id[m] : err_b_id[m];
                    end
                end
                // ---- B consumed ----
                if (mst_resp[m].b_valid && mst_req[m].b_ready) begin
                    rr_b[m]  <= (b_pick[m] + 1) % NUM_SLV;
                    w_out[m] <= w_out[m] - 1
                                + ((mst_req[m].aw_valid && mst_resp[m].aw_ready) ? 1 : 0);
                    wid_cnt[m][int'(mst_resp[m].b.id)] <=
                        wid_cnt[m][int'(mst_resp[m].b.id)] - 1
                        + ((mst_req[m].aw_valid && mst_resp[m].aw_ready
                            && mst_req[m].aw.id == mst_resp[m].b.id) ? 1 : 0);
                    if (b_pick[m] == ERR) err_b_busy[m] <= 1'b0;
                end
            end
        end
    end

    // The write error responder needs the id of the AW it is answering. It is
    // captured at AW time rather than at WLAST, because the AW payload is gone
    // by then.
    always_ff @(posedge clk)
        for (int m = 0; m < NUM_MST; m++)
            if (mst_req[m].aw_valid && mst_resp[m].aw_ready && aw_dst[m] == ERR)
                err_b_id[m] <= mst_req[m].aw.id;

endmodule
