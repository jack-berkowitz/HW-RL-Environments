// =============================================================================
// axi4_xbar_liveness_tb.sv -- NEGATIVE-CONTROL harness for d_nw01. NEVER SHIPPED.
// =============================================================================
// This is NOT the task's checker. It is the rig that proves the liveness
// monitor works, built and run BEFORE the full checker, per the standing
// procedure in CATALOG_V3_HARD.md:
//
//   A checker whose failure mode is SILENCE must be validated against a
//   known-failing input before it is trusted.
//
// It is deliberately minimal -- read channel only, no data scoreboard, no
// ordering checks -- because its only job is to answer three questions:
//
//   1. does LM_STALL fire on a genuinely deadlocked crossbar?
//   2. does LM_STARVE fire on a starved-but-live crossbar, WITHOUT LM_STALL?
//   3. does neither fire on the correct reference, including when arbitration
//      is slow but fair?
//
// Question 3 matters as much as the first two. A monitor that trips on slowness
// would silently encode one arbitration policy into the contract, which is what
// the second-source rule exists to prevent.
//
// SLOW_SLAVE inflates every slave's response latency without making any slave
// unfair, which is the "slow but fair" case for question 3.
// =============================================================================

`timescale 1ns/1ps
`include "liveness_monitor.svh"

module axi4_xbar_liveness_tb
  import axi4_xbar_pkg::*;
#(
    parameter int NUM_MST    = 4,
    parameter int NUM_SLV    = 2,
    parameter int MAX_TRANS  = 8,
    parameter int RUN_CYCLES = 60000,
    parameter int SLOW_SLAVE = 0    // extra response latency, same for all slaves
);

    logic clk = 1'b0, rst_n;
    always #5 clk = ~clk;

    slv_req_t  [NUM_MST-1:0] mst_req;
    slv_resp_t [NUM_MST-1:0] mst_resp;
    mst_req_t  [NUM_SLV-1:0] slv_req;
    mst_resp_t [NUM_SLV-1:0] slv_resp;
    xbar_rule_t [NUM_SLV-1:0] addr_map;

    axi4_xbar #(.NUM_MST(NUM_MST), .NUM_SLV(NUM_SLV), .MAX_TRANS(MAX_TRANS)) dut (
        .clk(clk), .rst_n(rst_n),
        .mst_req(mst_req), .mst_resp(mst_resp),
        .slv_req(slv_req), .slv_resp(slv_resp),
        .addr_map(addr_map));

    int    errors = 0;
    string fail_reason = "";
    task automatic note_fail(input string why);
        errors++;
        if (fail_reason == "") fail_reason = why;
        $display("[FAIL] t=%0t : %s", $time, why);
    endtask

    `LM_DECLARE(NUM_MST)

    // ---- address map: one contiguous 64 KiB window per slave ---------------
    initial begin
        for (int s = 0; s < NUM_SLV; s++) begin
            addr_map[s].mst_port   = s[$clog2(8)-1:0];
            addr_map[s].start_addr = addr_t'(s * 32'h0001_0000);
            addr_map[s].end_addr   = addr_t'((s + 1) * 32'h0001_0000);
        end
    end

    // ---- masters: continuous read pressure, all-to-all ---------------------
    // Every master targets every slave in rotation, so several masters contend
    // for the same slave constantly. That is the traffic the liveness
    // requirement is about.
    //
    // Outputs are COMBINATIONAL off registered state. An earlier version drove
    // valid from inside the same always_ff that consumed the handshake, reading
    // its own pre-update value, and wedged a correct crossbar -- the harness
    // looked exactly like a DUT deadlock.
    int outstanding [0:NUM_MST-1];
    int target      [0:NUM_MST-1];
    logic [NUM_MST-1:0] ar_hold;

    for (genvar m = 0; m < NUM_MST; m++) begin : g_mst
        always_comb begin
            mst_req[m]          = '0;
            mst_req[m].r_ready  = 1'b1;
            mst_req[m].b_ready  = 1'b1;
            mst_req[m].ar_valid = ar_hold[m];
            mst_req[m].ar.id    = slv_id_t'(m);
            mst_req[m].ar.addr  = addr_t'(target[m] * 32'h0001_0000 + 32'h40);
            mst_req[m].ar.len   = 8'd1;            // 2-beat burst
            mst_req[m].ar.size  = 3'd3;
            mst_req[m].ar.burst = BURST_INCR;
        end

        always_ff @(posedge clk) begin
            if (!rst_n) begin
                ar_hold[m]     <= 1'b0;
                outstanding[m] <= 0;
                target[m]      <= m % NUM_SLV;
            end else begin
                // offer whenever we are under the outstanding limit; hold until
                // accepted, as spec H2 requires of a producer
                if (mst_req[m].ar_valid && mst_resp[m].ar_ready) begin
                    target[m] <= (target[m] + 1) % NUM_SLV;
                    ar_hold[m] <= (outstanding[m] + 1 < MAX_TRANS);
                end else if (!mst_req[m].ar_valid) begin
                    ar_hold[m] <= (outstanding[m] < MAX_TRANS);
                end

                // outstanding: +1 on AR accept, -1 on R last
                outstanding[m] <= outstanding[m]
                    + ((mst_req[m].ar_valid && mst_resp[m].ar_ready) ? 1 : 0)
                    - ((mst_resp[m].r_valid && mst_req[m].r_ready
                        && mst_resp[m].r.last) ? 1 : 0);
            end
        end
    end

    // ---- slaves: accept one AR at a time, return len+1 R beats -------------
    int      s_beats [0:NUM_SLV-1];
    int      s_delay [0:NUM_SLV-1];
    mst_id_t s_id    [0:NUM_SLV-1];

    for (genvar s = 0; s < NUM_SLV; s++) begin : g_slv
        always_comb begin
            slv_resp[s]          = '0;
            slv_resp[s].aw_ready = 1'b1;
            slv_resp[s].w_ready  = 1'b1;
            slv_resp[s].ar_ready = (s_beats[s] == 0);
            slv_resp[s].r_valid  = (s_beats[s] != 0) && (s_delay[s] == 0);
            slv_resp[s].r.id     = s_id[s];
            slv_resp[s].r.data   = data_t'(s_beats[s]);
            slv_resp[s].r.resp   = RESP_OKAY;
            slv_resp[s].r.last   = (s_beats[s] == 1);
        end

        always_ff @(posedge clk) begin
            if (!rst_n) begin
                s_beats[s] <= 0; s_delay[s] <= 0; s_id[s] <= '0;
            end else if (slv_req[s].ar_valid && slv_resp[s].ar_ready) begin
                s_beats[s] <= int'(slv_req[s].ar.len) + 1;
                s_id[s]    <= slv_req[s].ar.id;
                s_delay[s] <= SLOW_SLAVE;
            end else if (s_delay[s] > 0) begin
                s_delay[s] <= s_delay[s] - 1;
            end else if (slv_resp[s].r_valid && slv_req[s].r_ready) begin
                s_beats[s] <= s_beats[s] - 1;
                s_delay[s] <= SLOW_SLAVE;
            end
        end
    end

    // ---- liveness masks ----------------------------------------------------
    // offered[m]: master m wants service and has not got it -- either an AR is
    //             asserted and unaccepted, or a read is outstanding.
    // served[m] : a burst completed for master m this cycle.
    logic [NUM_MST-1:0] lm_off, lm_srv;
    for (genvar m = 0; m < NUM_MST; m++) begin : g_mask
        assign lm_off[m] = (mst_req[m].ar_valid && !mst_resp[m].ar_ready)
                           || (outstanding[m] > 0);
        assign lm_srv[m] = mst_resp[m].r_valid && mst_req[m].r_ready
                           && mst_resp[m].r.last;
    end

    always_ff @(posedge clk) if (rst_n) begin
        `LM_TICK(lm_off, lm_srv)
    end

    initial begin
        rst_n = 1'b0;
        repeat (10) @(posedge clk);
        rst_n = 1'b1;
        repeat (RUN_CYCLES) @(posedge clk);

        $display("METRIC: run_cycles=%0d slow_slave=%0d", RUN_CYCLES, SLOW_SLAVE);
        `LM_CHECK(note_fail)

        if (errors == 0) $display("TEST_RESULT: PASS");
        else $display("TEST_RESULT: FAIL: %s", fail_reason);
        $finish;
    end

    initial begin
        #50_000_000;
        $display("TEST_RESULT: FAIL: timeout -- liveness harness did not complete");
        $finish;
    end

endmodule
