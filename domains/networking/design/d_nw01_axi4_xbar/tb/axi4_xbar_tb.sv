// =============================================================================
// axi4_xbar_tb.sv -- self-checking checker for `axi4_xbar` (d_nw01)
// =============================================================================
// NEVER SHIPPED TO A SUBMISSION.
//
// Built on top of the liveness monitor, which was validated against known-bad
// inputs BEFORE this file existed -- see NOTES.md § NEGATIVE CONTROL.
//
// THREE THINGS THIS CHECKER DELIBERATELY DOES NOT DO
// --------------------------------------------------
// Each would look correct while quietly failing a correct crossbar.
//
// 1. IT DOES NOT CHECK GLOBAL RESPONSE ORDER. AXI requires ordering per ID and
//    explicitly permits responses with different IDs to interleave in any
//    order. The scoreboard is therefore a FIFO PER (master, ID) PAIR, never one
//    queue per master. A global-order check would pass this reference -- whose
//    arbitration happens to produce one particular interleaving -- and fail a
//    correct crossbar that interleaves differently. That is the
//    rediscover-the-reference failure in its purest form.
//
// 2. IT DOES NOT CHECK RESPONSE TIMING OR LATENCY. Slaves here deliberately
//    respond at different rates so that cross-ID reordering actually happens
//    and any accidental global-order assumption is exposed rather than hidden.
//
// 3. IT DOES NOT REQUIRE ANY PARTICULAR ARBITRATION. Fairness is checked only
//    by the liveness monitor's starvation bound, which is measured relative to
//    progress elsewhere.
//
// WHAT IT DOES CHECK
// ------------------
//   per-ID ordering, read data content and source, RLAST beat counts,
//   B responses, DECERR beat counts on unmapped addresses, W-beat contiguity
//   per slave port (AXI4 has no WID, so W bursts must not interleave), and
//   forward progress.
// =============================================================================

`timescale 1ns/1ps
`include "liveness_monitor.svh"

module axi4_xbar_tb
  import axi4_xbar_pkg::*;
#(
    parameter int NUM_MST   = 4,
    parameter int NUM_SLV   = 2,
    parameter int MAX_TRANS = 8,
    parameter int N_TXN     = 1500,   // transactions per master
    parameter int MAX_ERRORS_REPORTED = 20
);

    localparam int NID  = 4;     // distinct IDs each master uses -- >1 so that
                                 // cross-ID interleaving genuinely occurs
    localparam int QD   = 64;    // per-(master,ID) expectation queue depth
    localparam addr_t UNMAPPED = 32'h8000_0000;   // matches no rule

    logic clk = 1'b0, rst_n;
    always #5 clk = ~clk;

    slv_req_t  [NUM_MST-1:0] mst_req;
    slv_resp_t [NUM_MST-1:0] mst_resp;
    mst_req_t  [NUM_SLV-1:0] slv_req;
    mst_resp_t [NUM_SLV-1:0] slv_resp;
    xbar_rule_t [NUM_SLV-1:0] addr_map;

    axi4_xbar #(.NUM_MST(NUM_MST), .NUM_SLV(NUM_SLV), .MAX_TRANS(MAX_TRANS)) dut (
        .clk(clk), .rst_n(rst_n), .mst_req(mst_req), .mst_resp(mst_resp),
        .slv_req(slv_req), .slv_resp(slv_resp), .addr_map(addr_map));

    int    errors = 0, checks = 0;
    string fail_reason = "", phase = "init";
    task automatic note_fail(input string why);
        errors++;
        if (fail_reason == "") fail_reason = why;
        if (errors <= MAX_ERRORS_REPORTED)
            $display("[FAIL] t=%0t phase=%s : %s", $time, phase, why);
        else if (errors == MAX_ERRORS_REPORTED + 1)
            $display("[FAIL] ... further failures suppressed");
    endtask

    `LM_DECLARE(NUM_MST)

    // ---- address map ------------------------------------------------------
    initial for (int s = 0; s < NUM_SLV; s++) begin
        addr_map[s].mst_port   = s[$clog2(8)-1:0];
        addr_map[s].start_addr = addr_t'(s * 32'h0001_0000);
        addr_map[s].end_addr   = addr_t'((s + 1) * 32'h0001_0000);
    end

    // Read data a slave returns is a pure function of address and beat index,
    // so the checker can verify the crossbar fetched from the RIGHT slave and
    // delivered the RIGHT beats without modelling memory contents.
    function automatic data_t expected_beat(input addr_t a, input int beat);
        return data_t'({a[31:4], 4'h0} + data_t'(beat) * 64'h0100_0000_0000_0001);
    endfunction

    // =========================================================================
    // SCOREBOARD: one FIFO per (master, ID). Never per master.
    // =========================================================================
    addr_t rq_addr [0:NUM_MST-1][0:NID-1][0:QD-1];
    int    rq_len  [0:NUM_MST-1][0:NID-1][0:QD-1];
    bit    rq_dec  [0:NUM_MST-1][0:NID-1][0:QD-1];
    int    rq_head [0:NUM_MST-1][0:NID-1];
    int    rq_tail [0:NUM_MST-1][0:NID-1];
    int    rq_beat [0:NUM_MST-1][0:NID-1];

    bit    wq_dec  [0:NUM_MST-1][0:NID-1][0:QD-1];
    int    wq_head [0:NUM_MST-1][0:NID-1];
    int    wq_tail [0:NUM_MST-1][0:NID-1];

    int cov_rd_ok = 0, cov_rd_dec = 0, cov_wr_ok = 0, cov_wr_dec = 0;
    int cov_burst_gt1 = 0, cov_cross_id = 0, cov_same_id_two_slv = 0;
    int last_rid [0:NUM_MST-1];

    // ---- traffic generation ------------------------------------------------
    int  txn_sent [0:NUM_MST-1];
    int  outstanding_r [0:NUM_MST-1];
    int  outstanding_w [0:NUM_MST-1];
    logic [NUM_MST-1:0] ar_hold, aw_hold;
    slv_id_t nxt_id  [0:NUM_MST-1];
    addr_t   nxt_addr[0:NUM_MST-1];
    int      nxt_len [0:NUM_MST-1];
    bit      nxt_dec [0:NUM_MST-1];
    int      w_left  [0:NUM_MST-1];
    addr_t   w_addr  [0:NUM_MST-1];

    for (genvar m = 0; m < NUM_MST; m++) begin : g_mst
        always_comb begin
            mst_req[m]          = '0;
            mst_req[m].r_ready  = 1'b1;
            mst_req[m].b_ready  = 1'b1;
            mst_req[m].ar_valid = ar_hold[m];
            mst_req[m].ar.id    = nxt_id[m];
            mst_req[m].ar.addr  = nxt_addr[m];
            mst_req[m].ar.len   = 8'(nxt_len[m]);
            mst_req[m].ar.size  = 3'd3;
            mst_req[m].ar.burst = BURST_INCR;
            mst_req[m].aw_valid = aw_hold[m];
            mst_req[m].aw.id    = nxt_id[m];
            mst_req[m].aw.addr  = nxt_addr[m];
            mst_req[m].aw.len   = 8'(nxt_len[m]);
            mst_req[m].aw.size  = 3'd3;
            mst_req[m].aw.burst = BURST_INCR;
            mst_req[m].w_valid  = (w_left[m] > 0);
            mst_req[m].w.data   = expected_beat(w_addr[m], 0);
            mst_req[m].w.strb   = '1;
            mst_req[m].w.last   = (w_left[m] == 1);
        end
    end

    // ---- slave models: different rates so cross-ID reordering really happens
    int      s_rbeats [0:NUM_SLV-1];
    int      s_rdelay [0:NUM_SLV-1];
    mst_id_t s_rid    [0:NUM_SLV-1];
    addr_t   s_raddr  [0:NUM_SLV-1];
    int      s_rn     [0:NUM_SLV-1];
    int      s_wbeats [0:NUM_SLV-1];
    mst_id_t s_wid    [0:NUM_SLV-1];
    bit      s_bpend  [0:NUM_SLV-1];
    // W-contiguity tracking: which transaction's beats are in flight here
    int      s_w_inflight [0:NUM_SLV-1];

    for (genvar s = 0; s < NUM_SLV; s++) begin : g_slv
        localparam int RATE = (s % 2 == 0) ? 0 : 4;   // slave 1 is slower
        always_comb begin
            slv_resp[s]          = '0;
            slv_resp[s].ar_ready = (s_rbeats[s] == 0);
            slv_resp[s].aw_ready = (s_wbeats[s] == 0) && !s_bpend[s];
            slv_resp[s].w_ready  = (s_wbeats[s] > 0);
            slv_resp[s].r_valid  = (s_rbeats[s] != 0) && (s_rdelay[s] == 0);
            slv_resp[s].r.id     = s_rid[s];
            slv_resp[s].r.data   = expected_beat(s_raddr[s], s_rn[s] - s_rbeats[s]);
            slv_resp[s].r.resp   = RESP_OKAY;
            slv_resp[s].r.last   = (s_rbeats[s] == 1);
            slv_resp[s].b_valid  = s_bpend[s];
            slv_resp[s].b.id     = s_wid[s];
            slv_resp[s].b.resp   = RESP_OKAY;
        end

        always_ff @(posedge clk) begin
            if (!rst_n) begin
                s_rbeats[s] <= 0; s_rdelay[s] <= 0; s_wbeats[s] <= 0;
                s_bpend[s] <= 1'b0; s_w_inflight[s] <= -1;
            end else begin
                // reads
                if (slv_req[s].ar_valid && slv_resp[s].ar_ready) begin
                    s_rbeats[s] <= int'(slv_req[s].ar.len) + 1;
                    s_rn[s]     <= int'(slv_req[s].ar.len) + 1;
                    s_rid[s]    <= slv_req[s].ar.id;
                    s_raddr[s]  <= slv_req[s].ar.addr;
                    s_rdelay[s] <= RATE;
                end else if (s_rdelay[s] > 0) s_rdelay[s] <= s_rdelay[s] - 1;
                else if (slv_resp[s].r_valid && slv_req[s].r_ready) begin
                    s_rbeats[s] <= s_rbeats[s] - 1;
                    s_rdelay[s] <= RATE;
                end
                // writes
                if (slv_req[s].aw_valid && slv_resp[s].aw_ready) begin
                    s_wbeats[s] <= int'(slv_req[s].aw.len) + 1;
                    s_wid[s]    <= slv_req[s].aw.id;
                    s_w_inflight[s] <= int'(slv_req[s].aw.id);
                end
                if (slv_req[s].w_valid && slv_resp[s].w_ready) begin
                    // CAUTION 2: AXI4 has no WID. W beats for a transaction must
                    // arrive contiguously; a crossbar that interleaves W bursts
                    // from different masters onto one slave is broken in a way a
                    // data-only scoreboard would not notice.
                    if (s_wbeats[s] == 0)
                        note_fail($sformatf("slave %0d: W beat with no AW outstanding (O3)", s));
                    if (slv_req[s].w.last != (s_wbeats[s] == 1))
                        note_fail($sformatf(
                            "slave %0d: WLAST on beat %0d of a %0d-beat write (O3)",
                            s, s_wbeats[s], s_wbeats[s]));
                    s_wbeats[s] <= s_wbeats[s] - 1;
                    if (s_wbeats[s] == 1) s_bpend[s] <= 1'b1;
                end
                if (s_bpend[s] && slv_req[s].b_ready) s_bpend[s] <= 1'b0;
            end
        end
    end

    // =========================================================================
    // response checking
    // =========================================================================
    always_ff @(posedge clk) if (rst_n) begin
        for (int m = 0; m < NUM_MST; m++) begin
            automatic int i;
            // ---- read data ----
            if (mst_resp[m].r_valid && mst_req[m].r_ready) begin
                i = int'(mst_resp[m].r.id);
                checks++;
                if (i >= NID) begin
                    note_fail($sformatf("master %0d: R with id %0d outside the issued set", m, i));
                end else if (rq_head[m][i] == rq_tail[m][i]) begin
                    note_fail($sformatf("master %0d id %0d: R beat with no outstanding read", m, i));
                end else begin
                    if (rq_dec[m][i][rq_head[m][i] % QD]) begin
                        // CAUTION 3: DECERR is a BEAT-COUNT property. An unmapped
                        // read must still return ARLEN+1 beats, each DECERR, with
                        // RLAST on the last. Returning one beat and dropping the
                        // rest wedges a master waiting on RLAST.
                        if (mst_resp[m].r.resp !== RESP_DECERR)
                            note_fail($sformatf(
                                "master %0d id %0d: unmapped read returned resp=%0b, expected DECERR (D2)",
                                m, i, mst_resp[m].r.resp));
                    end else begin
                        if (mst_resp[m].r.resp !== RESP_OKAY)
                            note_fail($sformatf("master %0d id %0d: mapped read returned resp=%0b",
                                                m, i, mst_resp[m].r.resp));
                        if (mst_resp[m].r.data !== expected_beat(rq_addr[m][i][rq_head[m][i] % QD],
                                                                rq_beat[m][i]))
                            note_fail($sformatf(
                                "master %0d id %0d beat %0d: data=0x%0h expected 0x%0h (C1)",
                                m, i, rq_beat[m][i], mst_resp[m].r.data,
                                expected_beat(rq_addr[m][i][rq_head[m][i] % QD], rq_beat[m][i])));
                    end
                    // beat counting and RLAST placement -- the same check for
                    // mapped and unmapped, which is the point of caution 3
                    if (mst_resp[m].r.last !== (rq_beat[m][i] == rq_len[m][i][rq_head[m][i] % QD]))
                        note_fail($sformatf(
                            "master %0d id %0d: RLAST on beat %0d of a %0d-beat burst (O4/D2)",
                            m, i, rq_beat[m][i], rq_len[m][i][rq_head[m][i] % QD] + 1));
                    if (mst_resp[m].r.last) begin
                        if (rq_dec[m][i][rq_head[m][i] % QD]) cov_rd_dec++; else cov_rd_ok++;
                        if (rq_len[m][i][rq_head[m][i] % QD] > 0) cov_burst_gt1++;
                        rq_head[m][i] <= rq_head[m][i] + 1;
                        rq_beat[m][i] <= 0;
                    end else rq_beat[m][i] <= rq_beat[m][i] + 1;
                    if (last_rid[m] != i) begin cov_cross_id++; last_rid[m] <= i; end
                end
            end
            // ---- write response ----
            if (mst_resp[m].b_valid && mst_req[m].b_ready) begin
                i = int'(mst_resp[m].b.id);
                checks++;
                if (i >= NID) note_fail($sformatf("master %0d: B with id %0d outside the issued set", m, i));
                else if (wq_head[m][i] == wq_tail[m][i])
                    note_fail($sformatf("master %0d id %0d: B with no outstanding write", m, i));
                else begin
                    if (wq_dec[m][i][wq_head[m][i] % QD]) begin
                        if (mst_resp[m].b.resp !== RESP_DECERR)
                            note_fail($sformatf(
                                "master %0d id %0d: unmapped write returned resp=%0b, expected DECERR (D2)",
                                m, i, mst_resp[m].b.resp));
                        cov_wr_dec++;
                    end else begin
                        if (mst_resp[m].b.resp !== RESP_OKAY)
                            note_fail($sformatf("master %0d id %0d: mapped write returned resp=%0b",
                                                m, i, mst_resp[m].b.resp));
                        cov_wr_ok++;
                    end
                    wq_head[m][i] <= wq_head[m][i] + 1;
                end
            end
        end
    end

    // ---- liveness masks ----------------------------------------------------
    logic [NUM_MST-1:0] lm_off, lm_srv;
    for (genvar m = 0; m < NUM_MST; m++) begin : g_mask
        assign lm_off[m] = (outstanding_r[m] > 0) || (outstanding_w[m] > 0)
                           || (mst_req[m].ar_valid && !mst_resp[m].ar_ready)
                           || (mst_req[m].aw_valid && !mst_resp[m].aw_ready);
        assign lm_srv[m] = (mst_resp[m].r_valid && mst_req[m].r_ready && mst_resp[m].r.last)
                           || (mst_resp[m].b_valid && mst_req[m].b_ready);
    end
    always_ff @(posedge clk) if (rst_n) begin
        `LM_TICK(lm_off, lm_srv)
    end

    // ---- request issue -----------------------------------------------------
    int seed_q;
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            for (int m = 0; m < NUM_MST; m++) begin
                ar_hold[m] <= 1'b0; aw_hold[m] <= 1'b0;
                txn_sent[m] <= 0; outstanding_r[m] <= 0; outstanding_w[m] <= 0;
                w_left[m] <= 0; nxt_id[m] <= '0; nxt_len[m] <= 0;
                nxt_addr[m] <= '0; nxt_dec[m] <= 1'b0; last_rid[m] <= -1;
                for (int i = 0; i < NID; i++) begin
                    rq_head[m][i] <= 0; rq_tail[m][i] <= 0; rq_beat[m][i] <= 0;
                    wq_head[m][i] <= 0; wq_tail[m][i] <= 0;
                end
            end
        end else begin
            for (int m = 0; m < NUM_MST; m++) begin
                // record accepted requests into the per-(master,ID) queue
                if (mst_req[m].ar_valid && mst_resp[m].ar_ready) begin
                    rq_addr[m][int'(nxt_id[m])][rq_tail[m][int'(nxt_id[m])] % QD] <= nxt_addr[m];
                    rq_len [m][int'(nxt_id[m])][rq_tail[m][int'(nxt_id[m])] % QD] <= nxt_len[m];
                    rq_dec [m][int'(nxt_id[m])][rq_tail[m][int'(nxt_id[m])] % QD] <= nxt_dec[m];
                    rq_tail[m][int'(nxt_id[m])] <= rq_tail[m][int'(nxt_id[m])] + 1;
                    outstanding_r[m] <= outstanding_r[m] + 1;
                    ar_hold[m] <= 1'b0;
                    txn_sent[m] <= txn_sent[m] + 1;
                end
                if (mst_req[m].aw_valid && mst_resp[m].aw_ready) begin
                    wq_dec[m][int'(nxt_id[m])][wq_tail[m][int'(nxt_id[m])] % QD] <= nxt_dec[m];
                    wq_tail[m][int'(nxt_id[m])] <= wq_tail[m][int'(nxt_id[m])] + 1;
                    outstanding_w[m] <= outstanding_w[m] + 1;
                    aw_hold[m] <= 1'b0;
                    w_left[m]  <= nxt_len[m] + 1;
                    w_addr[m]  <= nxt_addr[m];
                    txn_sent[m] <= txn_sent[m] + 1;
                end
                if (mst_req[m].w_valid && mst_resp[m].w_ready) w_left[m] <= w_left[m] - 1;
                if (mst_resp[m].r_valid && mst_req[m].r_ready && mst_resp[m].r.last)
                    outstanding_r[m] <= outstanding_r[m] - 1
                        + ((mst_req[m].ar_valid && mst_resp[m].ar_ready) ? 1 : 0);
                if (mst_resp[m].b_valid && mst_req[m].b_ready)
                    outstanding_w[m] <= outstanding_w[m] - 1
                        + ((mst_req[m].aw_valid && mst_resp[m].aw_ready) ? 1 : 0);

                // launch the next request
                if (!ar_hold[m] && !aw_hold[m] && w_left[m] == 0
                    && txn_sent[m] < N_TXN
                    && outstanding_r[m] < MAX_TRANS && outstanding_w[m] < MAX_TRANS) begin
                    // Two INDEPENDENT draws. An earlier version used one, with
                    // r<8 meaning unmapped and r<50 meaning read -- so every
                    // unmapped request was also a read and the unmapped-WRITE
                    // path was never exercised at all. The coverage floor caught
                    // it, which is what the floor is for.
                    automatic int r    = $urandom_range(0, 99);   // mapped vs not
                    automatic int rw   = $urandom_range(0, 99);   // read vs write
                    nxt_id[m]   <= slv_id_t'($urandom_range(0, NID-1));
                    nxt_len[m]  <= $urandom_range(0, 3);
                    if (r < 8) begin           // unmapped -> must DECERR
                        nxt_addr[m] <= UNMAPPED + addr_t'($urandom_range(0, 255) * 8);
                        nxt_dec[m]  <= 1'b1;
                    end else begin
                        nxt_addr[m] <= addr_t'($urandom_range(0, NUM_SLV-1) * 32'h0001_0000
                                               + $urandom_range(0, 1023) * 8);
                        nxt_dec[m]  <= 1'b0;
                    end
                    if (rw < 50) ar_hold[m] <= 1'b1; else aw_hold[m] <= 1'b1;
                end
            end
        end
    end

    // ---- main --------------------------------------------------------------
    int guard;
    initial begin
        if (NUM_MST != 2 && NUM_MST != 4) begin
            $display("TEST_RESULT: FAIL: illegal NUM_MST=%0d (legal: 2,4 -- the widened id field caps it at 4)", NUM_MST); $finish;
        end
        if (NUM_SLV != 2 && NUM_SLV != 4) begin
            $display("TEST_RESULT: FAIL: illegal NUM_SLV=%0d (legal: 2,4)", NUM_SLV); $finish;
        end
        if (MAX_TRANS != 2 && MAX_TRANS != 8) begin
            $display("TEST_RESULT: FAIL: illegal MAX_TRANS=%0d (legal: 2,8)", MAX_TRANS); $finish;
        end

        phase = "reset";
        rst_n = 1'b0;
        repeat (10) @(posedge clk);
        if (|{mst_resp[0].r_valid, mst_resp[0].b_valid})
            note_fail("response valid asserted while rst_n low (R1)");
        rst_n = 1'b1;

        phase = "all-to-all";
        guard = 0;
        while (guard < 400*N_TXN) begin
            automatic bit done = 1'b1;
            for (int m = 0; m < NUM_MST; m++)
                if (txn_sent[m] < N_TXN || outstanding_r[m] > 0 || outstanding_w[m] > 0)
                    done = 1'b0;
            if (done) break;
            @(posedge clk); guard++;
        end
        repeat (200) @(posedge clk);

        phase = "final";
        $display("METRIC: checks=%0d", checks);
        `LM_CHECK(note_fail)

        begin
            int miss; miss = 0;
            $display("// coverage: rd_ok=%0d rd_decerr=%0d wr_ok=%0d wr_decerr=%0d",
                     cov_rd_ok, cov_rd_dec, cov_wr_ok, cov_wr_dec);
            $display("// coverage: multi_beat_bursts=%0d cross_id_switches=%0d",
                     cov_burst_gt1, cov_cross_id);
            if (cov_rd_ok  == 0) begin miss++; $display("// COVERAGE HOLE: no successful read"); end
            if (cov_wr_ok  == 0) begin miss++; $display("// COVERAGE HOLE: no successful write"); end
            if (cov_rd_dec == 0) begin miss++; $display("// COVERAGE HOLE: no unmapped read (DECERR path untested)"); end
            if (cov_wr_dec == 0) begin miss++; $display("// COVERAGE HOLE: no unmapped write"); end
            if (cov_burst_gt1 == 0) begin miss++; $display("// COVERAGE HOLE: no multi-beat burst"); end
            // If responses never switched ID at a master, the run never
            // exercised cross-ID interleaving and a global-order scoreboard
            // would have passed. That is precisely the blind spot.
            if (cov_cross_id < 100) begin miss++; $display("// COVERAGE HOLE: too little cross-ID interleaving (%0d switches)", cov_cross_id); end
            if (miss > 0) note_fail($sformatf("%0d coverage holes", miss));
        end

        if (checks < 2000) note_fail($sformatf("insufficient coverage: only %0d checks", checks));
        if (errors == 0) $display("TEST_RESULT: PASS");
        else $display("TEST_RESULT: FAIL: %s (%0d failing checks of %0d)", fail_reason, errors, checks);
        $finish;
    end

    initial begin
        #200_000_000;
        $display("// watchdog: phase=%s checks=%0d", phase, checks);
        $display("TEST_RESULT: FAIL: timeout -- checker did not complete (phase=%s)", phase);
        $finish;
    end

endmodule
