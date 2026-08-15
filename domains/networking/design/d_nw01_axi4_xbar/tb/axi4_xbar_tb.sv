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
    parameter int MAX_BURST_LEN = 3,   // ARLEN/AWLEN the design must support
    parameter int N_TXN     = 1500,   // transactions per master
    parameter int MAX_ERRORS_REPORTED = 20
);

    // Transactions are scaled so total BEATS stay roughly constant: a 256-beat
    // burst carries 64x the data of a 4-beat one, and sweeping MAX_BURST_LEN
    // without this makes the long configs dominate runtime for no extra
    // coverage.
    localparam int EFF_TXN = (MAX_BURST_LEN >= 64) ? 120 : N_TXN;

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
    int    rq_t0   [0:NUM_MST-1][0:NID-1][0:QD-1];

    bit    wq_dec  [0:NUM_MST-1][0:NID-1][0:QD-1];
    int    wq_head [0:NUM_MST-1][0:NID-1];
    int    wq_tail [0:NUM_MST-1][0:NID-1];

    int cov_rd_ok = 0, cov_rd_dec = 0, cov_wr_ok = 0, cov_wr_dec = 0;
    int cov_burst_gt1 = 0, cov_cross_id = 0, cov_same_id_two_slv = 0;
    int cov_max_len = 0;
    int lat_sum = 0, lat_n = 0, lat_max = 0, cyc = 0;
    int scored_beats = 0, scored_cyc = 0;
    int last_rid [0:NUM_MST-1];

    // ---- MASTER-SIDE BACKPRESSURE (spec L3) --------------------------------
    // L3 requires liveness under response backpressure and was DECORATIVE until
    // now: r_ready and b_ready were hardwired to 1, so the condition it names
    // was never created. A stated requirement with no binding check is the
    // defect class this whole exercise is about.
    //
    // The pattern is free-running and never reads *_valid, so it cannot violate
    // the H1-style rule that a ready must not depend on its own valid, and it
    // cannot wedge the way a handshake-derived stall would.
    logic [15:0] bp_lfsr [0:NUM_MST-1];
    logic [NUM_MST-1:0] bp_r, bp_b;
    always_ff @(posedge clk) begin
        if (!rst_n)
            for (int m = 0; m < NUM_MST; m++) bp_lfsr[m] <= 16'hACE1 + 16'(m * 7919);
        else
            for (int m = 0; m < NUM_MST; m++)
                bp_lfsr[m] <= {bp_lfsr[m][14:0],
                               bp_lfsr[m][15] ^ bp_lfsr[m][13] ^ bp_lfsr[m][12] ^ bp_lfsr[m][10]};
    end
    // ~25 % stall on R, ~25 % on B, independently per master
    always_comb for (int m = 0; m < NUM_MST; m++) begin
        bp_r[m] = (bp_lfsr[m][1:0] != 2'b00);
        bp_b[m] = (bp_lfsr[m][5:4] != 2'b00);
    end
    int bp_r_stalls, bp_b_stalls;
    always_ff @(posedge clk) begin
        if (!rst_n) begin bp_r_stalls <= 0; bp_b_stalls <= 0; end
        else if (tmode == 0) for (int m = 0; m < NUM_MST; m++) begin
            if (mst_resp[m].r_valid && !mst_req[m].r_ready) bp_r_stalls <= bp_r_stalls + 1;
            if (mst_resp[m].b_valid && !mst_req[m].b_ready) bp_b_stalls <= bp_b_stalls + 1;
        end
    end

    // ---- controlled preamble (spec C1/C2) ----------------------------------
    // tmode 0 = the randomised all-to-all phase (everything below behaves as
    // before). 1 = capacity: slaves sink every AR and return nothing, masters
    // accept nothing. 2 = concurrency/throughput: zero-latency slaves, masters
    // drain, addressing chosen by the sequencer. The randomised generator and
    // every scoreboard check are gated off while tmode != 0, so the preamble
    // cannot perturb the phase that does the data checking.
    bit [1:0]           tmode = 2'd0;
    bit                 cap_drain;
    logic [NUM_MST-1:0] cap_en;
    int                 cap_tgt      [0:NUM_MST-1];
    int                 cap_ar_cnt   [0:NUM_MST-1];
    int                 cap_done_cnt [0:NUM_MST-1];

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            for (int m = 0; m < NUM_MST; m++) begin
                cap_ar_cnt[m] <= 0; cap_done_cnt[m] <= 0;
            end
        end else if (tmode != 0) begin
            for (int m = 0; m < NUM_MST; m++) begin
                if (mst_req[m].ar_valid && mst_resp[m].ar_ready)
                    cap_ar_cnt[m] <= cap_ar_cnt[m] + 1;
                if (mst_resp[m].r_valid && mst_req[m].r_ready && mst_resp[m].r.last)
                    cap_done_cnt[m] <= cap_done_cnt[m] + 1;
            end
        end
    end

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
        always_comb if (tmode != 0) begin
            // controlled preamble: single-beat reads at one chosen slave
            mst_req[m]          = '0;
            mst_req[m].r_ready  = cap_drain;
            mst_req[m].b_ready  = cap_drain;
            mst_req[m].ar_valid = cap_en[m];
            mst_req[m].ar.id    = slv_id_t'(m % NID);
            mst_req[m].ar.addr  = addr_t'(cap_tgt[m] * 32'h0001_0000 + 32'h40);
            mst_req[m].ar.len   = 8'd0;
            mst_req[m].ar.size  = 3'd3;
            mst_req[m].ar.burst = BURST_INCR;
        end else begin
            mst_req[m]          = '0;
            mst_req[m].r_ready  = bp_r[m];
            mst_req[m].b_ready  = bp_b[m];
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

    // Preamble slave: a real pipeline -- accepts an AR every cycle and returns
    // an R every cycle. Without this the slave is the bottleneck (one
    // transaction in flight => 0.5 bursts/cycle), the crossbar is never the
    // limiting resource, and C2 cannot fail: a design that serialises all
    // traffic still keeps up with a slave that slow. Measured and confirmed --
    // the serialisation mutant scored 199 % against the one-at-a-time model.
    localparam int PQD = 32;
    mst_id_t pq_id  [0:NUM_SLV-1][0:PQD-1];
    addr_t   pq_adr [0:NUM_SLV-1][0:PQD-1];
    int      pq_hd  [0:NUM_SLV-1];
    int      pq_tl  [0:NUM_SLV-1];

    for (genvar s = 0; s < NUM_SLV; s++) begin : g_pslv
        always_ff @(posedge clk) begin
            if (!rst_n) begin pq_hd[s] <= 0; pq_tl[s] <= 0; end
            else if (tmode == 2'd2) begin
                if (slv_req[s].ar_valid && slv_resp[s].ar_ready) begin
                    pq_id [s][pq_tl[s] % PQD] <= slv_req[s].ar.id;
                    pq_adr[s][pq_tl[s] % PQD] <= slv_req[s].ar.addr;
                    pq_tl[s] <= pq_tl[s] + 1;
                end
                if (slv_resp[s].r_valid && slv_req[s].r_ready) pq_hd[s] <= pq_hd[s] + 1;
            end
        end
    end

    for (genvar s = 0; s < NUM_SLV; s++) begin : g_slv
        localparam int RATE = (s % 2 == 0) ? 0 : 4;   // slave 1 is slower
        always_comb begin
            slv_resp[s]          = '0;
            slv_resp[s].ar_ready = (tmode == 2'd1) ? 1'b1
                                   : (tmode == 2'd2) ? ((pq_tl[s] - pq_hd[s]) < PQD)
                                   : (s_rbeats[s] == 0);
            slv_resp[s].aw_ready = (s_wbeats[s] == 0) && !s_bpend[s];
            slv_resp[s].w_ready  = (s_wbeats[s] > 0);
            slv_resp[s].r_valid  = (tmode == 2'd1) ? 1'b0
                                   : (tmode == 2'd2) ? (pq_tl[s] != pq_hd[s])
                                   : ((s_rbeats[s] != 0) && (s_rdelay[s] == 0));
            slv_resp[s].r.id     = (tmode == 2'd2) ? pq_id[s][pq_hd[s] % PQD] : s_rid[s];
            slv_resp[s].r.data   = (tmode == 2'd2)
                                   ? expected_beat(pq_adr[s][pq_hd[s] % PQD], 0)
                                   : expected_beat(s_raddr[s], s_rn[s] - s_rbeats[s]);
            slv_resp[s].r.resp   = RESP_OKAY;
            slv_resp[s].r.last   = (tmode == 2'd2) ? 1'b1 : (s_rbeats[s] == 1);
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
                if (slv_req[s].ar_valid && slv_resp[s].ar_ready && tmode == 2'd0) begin
                    s_rbeats[s] <= int'(slv_req[s].ar.len) + 1;
                    s_rn[s]     <= int'(slv_req[s].ar.len) + 1;
                    s_rid[s]    <= slv_req[s].ar.id;
                    s_raddr[s]  <= slv_req[s].ar.addr;
                    s_rdelay[s] <= (tmode == 0) ? RATE : 0;
                end else if (s_rdelay[s] > 0) s_rdelay[s] <= s_rdelay[s] - 1;
                else if (slv_resp[s].r_valid && slv_req[s].r_ready) begin
                    s_rbeats[s] <= s_rbeats[s] - 1;
                    s_rdelay[s] <= (tmode == 0) ? RATE : 0;
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
                    if (s_wbeats[s] == 0 && tmode == 0)
                        note_fail($sformatf("slave %0d: W beat with no AW outstanding (O3)", s));
                    if (slv_req[s].w.last != (s_wbeats[s] == 1) && tmode == 0)
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
    always_ff @(posedge clk) if (rst_n && tmode == 0) begin
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
                                "master %0d id %0d beat %0d: data=0x%0h expected 0x%0h (D1/O1)",
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
                        lat_sum <= lat_sum + (cyc - rq_t0[m][i][rq_head[m][i] % QD]);
                        lat_n   <= lat_n + 1;
                        if ((cyc - rq_t0[m][i][rq_head[m][i] % QD]) > lat_max)
                            lat_max <= cyc - rq_t0[m][i][rq_head[m][i] % QD];
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
        cyc <= cyc + 1;
        if (tmode == 0) begin
            scored_cyc <= scored_cyc + 1;
            for (int m = 0; m < NUM_MST; m++)
                if (mst_resp[m].r_valid && mst_req[m].r_ready) scored_beats <= scored_beats + 1;
        end
    end
    always_ff @(posedge clk) if (rst_n && tmode == 0) begin
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
        end else if (tmode == 0) begin
            for (int m = 0; m < NUM_MST; m++) begin
                // record accepted requests into the per-(master,ID) queue
                if (mst_req[m].ar_valid && mst_resp[m].ar_ready) begin
                    if (nxt_len[m] > cov_max_len) cov_max_len <= nxt_len[m];
                    rq_t0  [m][int'(nxt_id[m])][rq_tail[m][int'(nxt_id[m])] % QD] <= cyc;
                    rq_addr[m][int'(nxt_id[m])][rq_tail[m][int'(nxt_id[m])] % QD] <= nxt_addr[m];
                    rq_len [m][int'(nxt_id[m])][rq_tail[m][int'(nxt_id[m])] % QD] <= nxt_len[m];
                    rq_dec [m][int'(nxt_id[m])][rq_tail[m][int'(nxt_id[m])] % QD] <= nxt_dec[m];
                    rq_tail[m][int'(nxt_id[m])] <= rq_tail[m][int'(nxt_id[m])] + 1;
                    outstanding_r[m] <= outstanding_r[m] + 1;
                    ar_hold[m] <= 1'b0;
                    txn_sent[m] <= txn_sent[m] + 1;
                end
                if (mst_req[m].aw_valid && mst_resp[m].aw_ready) begin
                    if (nxt_len[m] > cov_max_len) cov_max_len <= nxt_len[m];
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
                    && txn_sent[m] < EFF_TXN
                    && outstanding_r[m] < MAX_TRANS && outstanding_w[m] < MAX_TRANS) begin
                    // Two INDEPENDENT draws. An earlier version used one, with
                    // r<8 meaning unmapped and r<50 meaning read -- so every
                    // unmapped request was also a read and the unmapped-WRITE
                    // path was never exercised at all. The coverage floor caught
                    // it, which is what the floor is for.
                    automatic int r    = $urandom_range(0, 99);   // mapped vs not
                    automatic int rw   = $urandom_range(0, 99);   // read vs write
                    nxt_id[m]   <= slv_id_t'($urandom_range(0, NID-1));
                    if ($urandom_range(0, 3) == 0)
                        nxt_len[m] <= MAX_BURST_LEN;              // drive the parameter
                    else
                        nxt_len[m] <= $urandom_range(0, MAX_BURST_LEN);
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
    localparam int CWIN = 3000;   // measurement window, cycles
    int guard;
    int c2_one, c2_two, agg_bursts, cap_floor;
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

        // =====================================================================
        // C1 -- OUTSTANDING CAPACITY
        // Slaves accept every AR and return nothing; masters accept nothing.
        // The only thing that can stop a master issuing is the crossbar's own
        // capacity, so the accepted count IS the capacity. A design that
        // hard-codes one transaction per master reports 1 here at every
        // MAX_TRANS and is caught; before this check existed it passed, because
        // the randomised phase throttles offered load to MAX_TRANS and simply
        // waits when ar_ready goes low.
        // =====================================================================
        phase = "capacity";
        tmode = 2'd1; cap_drain = 1'b0;
        for (int m = 0; m < NUM_MST; m++) cap_tgt[m] = m % NUM_SLV;
        cap_en = '1;
        repeat (128 + 32 * MAX_TRANS) @(posedge clk);
        cap_en = '0;
        // THE FLOOR IS HALF OF MAX_TRANS, NOT MAX_TRANS. Observable capacity
        // depends on pipeline depth, not only on the configured queue depth:
        // the vendored anchor reports MAX_TRANS+1 with CUT_ALL_AX and
        // MAX_TRANS-1 with NO_LATENCY, from the SAME MaxMstTrans setting.
        // Requiring MAX_TRANS would fail the second of those -- a correct
        // crossbar differing from the anchor only in buffering -- which is
        // encoding one implementation's pipelining into the contract.
        //
        // Half leaves margin on both sides at MAX_TRANS=8: anchor 9, no-cut
        // anchor 7, floor 4, one-deep design 1.
        //
        // At MAX_TRANS=2 the floor is 1, which looks inert but is not: it is
        // applied PER MASTER, and the interesting failure there is head-of-line
        // blocking rather than depth. Measured at MAX_TRANS=2, all four
        // masters: no-cut anchor 1 1 1 1, one-deep candidate 1 1 0 0 -- in the
        // latter a single un-retiring transaction occupies the per-slave path
        // and every other master targeting that slave is shut out completely.
        // So C1 catches depth at MAX_TRANS=8 and decoupling at MAX_TRANS=2.
        cap_floor = (MAX_TRANS + 1) / 2;
        for (int m = 0; m < NUM_MST; m++) begin
            $display("METRIC: outstanding_master%0d=%0d", m, cap_ar_cnt[m]);
            if (cap_ar_cnt[m] < cap_floor)
                note_fail($sformatf(
                    "master %0d accepted only %0d outstanding reads with no response drained; floor is %0d for MAX_TRANS=%0d (C1)",
                    m, cap_ar_cnt[m], cap_floor, MAX_TRANS));
        end

        // =====================================================================
        // C2 -- CONCURRENT DISJOINT PAIRS
        // One pair alone, then two pairs sharing no endpoint. A crossbar serves
        // them in parallel; a shared-arbiter funnel does not. Requiring only
        // 1.5x of the ideal 2x leaves room for arbitration overhead while still
        // separating parallel from serial by a wide margin.
        // =====================================================================
        phase = "concurrency-1";
        tmode = 2'd2; cap_drain = 1'b1;
        rst_n = 1'b0; repeat (6) @(posedge clk); rst_n = 1'b1;
        cap_tgt[0] = 0; cap_en = '0; cap_en[0] = 1'b1;
        repeat (CWIN) @(posedge clk);
        cap_en = '0; c2_one = cap_done_cnt[0];

        phase = "concurrency-2";
        rst_n = 1'b0; repeat (6) @(posedge clk); rst_n = 1'b1;
        cap_tgt[0] = 0; cap_tgt[1] = 1;
        cap_en = '0; cap_en[0] = 1'b1; cap_en[1] = 1'b1;
        repeat (CWIN) @(posedge clk);
        cap_en = '0; c2_two = cap_done_cnt[0] + cap_done_cnt[1];

        $display("METRIC: disjoint_one_pair=%0d disjoint_two_pairs=%0d speedup_pct=%0d",
                 c2_one, c2_two, (c2_one == 0) ? 0 : (c2_two * 100) / c2_one);
        if (c2_one == 0)
            note_fail("no progress on a single master/slave pair (C2)");
        else if (c2_two * 10 < c2_one * 15)
            note_fail($sformatf(
                "disjoint pairs do not run in parallel: two pairs retired %0d vs %0d for one pair (%0d%%, need >=150%%) -- traffic is serialising through a shared resource (C2)",
                c2_two, c2_one, (c2_two * 100) / c2_one));

        // Aggregate throughput: REPORTED, never gating. The achievable rate
        // depends on the geometry, so no single threshold separates a good
        // design from a bad one across configs -- C1 and C2 are the gates.
        phase = "throughput";
        rst_n = 1'b0; repeat (6) @(posedge clk); rst_n = 1'b1;
        for (int m = 0; m < NUM_MST; m++) cap_tgt[m] = m % NUM_SLV;
        cap_en = '1;
        repeat (CWIN) @(posedge clk);
        cap_en = '0;
        agg_bursts = 0;
        for (int m = 0; m < NUM_MST; m++) agg_bursts += cap_done_cnt[m];
        $display("METRIC: aggregate_bursts_per_1000cyc=%0d", (agg_bursts * 1000) / CWIN);

        // Back to the scored phase from a clean reset.
        tmode = 2'd0; cap_drain = 1'b0;
        rst_n = 1'b0; repeat (10) @(posedge clk); rst_n = 1'b1;

        phase = "all-to-all";
        guard = 0;
        while (guard < 400*EFF_TXN*(MAX_BURST_LEN+1)) begin
            automatic bit done = 1'b1;
            for (int m = 0; m < NUM_MST; m++)
                if (txn_sent[m] < EFF_TXN || outstanding_r[m] > 0 || outstanding_w[m] > 0)
                    done = 1'b0;
            if (done) break;
            @(posedge clk); guard++;
        end
        repeat (200) @(posedge clk);

        phase = "final";
        $display("METRIC: checks=%0d", checks);
        // ---- PPA-adjacent axes. Throughput is the P in PPA and was being
        // treated as diagnostic output; it is reported here as a first-class
        // axis alongside area, power and Fmax. Still ungated -- no flat
        // threshold separates a good design from a bad one across geometries.
        $display("METRIC: scored_beats_per_1000cyc=%0d over %0d cycles",
                 (scored_cyc == 0) ? 0 : (scored_beats * 1000) / scored_cyc, scored_cyc);
        $display("METRIC: read_latency_avg=%0d max=%0d n=%0d",
                 (lat_n == 0) ? 0 : lat_sum / lat_n, lat_max, lat_n);
        begin
            int lo, hi;
            lo = lm_served_count[0]; hi = lm_served_count[0];
            for (int m = 1; m < NUM_MST; m++) begin
                if (lm_served_count[m] < lo) lo = lm_served_count[m];
                if (lm_served_count[m] > hi) hi = lm_served_count[m];
            end
            $display("METRIC: fairness_spread=%0d (min=%0d max=%0d)", hi - lo, lo, hi);
        end
        $display("METRIC: backpressure_stalls r=%0d b=%0d", bp_r_stalls, bp_b_stalls);
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
            if (cov_burst_gt1 == 0 && MAX_BURST_LEN > 0) begin miss++; $display("// COVERAGE HOLE: no multi-beat burst"); end
            $display("// coverage: max_burst_seen=%0d (MAX_BURST_LEN=%0d) bp_r_stalls=%0d bp_b_stalls=%0d",
                     cov_max_len, MAX_BURST_LEN, bp_r_stalls, bp_b_stalls);
            if (cov_max_len < MAX_BURST_LEN) begin
                miss++; $display("// COVERAGE HOLE: never drove a burst of the full MAX_BURST_LEN=%0d (longest was %0d)",
                                 MAX_BURST_LEN, cov_max_len); end
            // L3 is only tested if backpressure actually created stalls.
            if (bp_r_stalls == 0) begin miss++; $display("// COVERAGE HOLE: R backpressure never stalled a response (L3 untested)"); end
            if (bp_b_stalls == 0) begin miss++; $display("// COVERAGE HOLE: B backpressure never stalled a response (L3 untested)"); end
            // If responses never switched ID at a master, the run never
            // exercised cross-ID interleaving and a global-order scoreboard
            // would have passed. That is precisely the blind spot.
            // RATE, not count. The property is "cross-ID reordering genuinely
            // occurred", and the count scales with how many transactions the
            // run performs -- which EFF_TXN deliberately reduces at long bursts
            // to hold total beats constant. A fixed floor of 100 was therefore
            // measuring the harness's own transaction scaling, not the DUT: at
            // MAX_BURST_LEN=255 the reference interleaves at 32 % (76 switches
            // in 240 transactions) and still tripped it. Rate-based, with a
            // small absolute minimum so a tiny run cannot pass vacuously.
            begin
                int min_cross;
                min_cross = (EFF_TXN * NUM_MST) / 32;
                if (min_cross < 20) min_cross = 20;
                if (cov_cross_id < min_cross) begin
                    miss++;
                    $display("// COVERAGE HOLE: too little cross-ID interleaving (%0d switches, need %0d)",
                             cov_cross_id, min_cross);
                end
            end
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
