// =============================================================================
// softmax_tb.sv -- self-checking testbench for `softmax` (see softmax_iface.sv)
// =============================================================================
// Reference model: the mathematical definition evaluated in double-precision
// `real` arithmetic inside the testbench --
//     m = max_j x[j];  p[i] = exp(x[i]-m) / sum_j exp(x[j]-m)
// using $exp. This is plain math, not an RTL model of the DUT.
//
// Bit-exact comparison is deliberately NOT used: a hardware softmax is always
// an approximation. The checks are the explicit tolerances A1..A5 documented in
// softmax_iface.sv, all expressed in Q0.16 LSBs.
//
// Override parameters at compile time, e.g.
//   iverilog -g2012 -o sim -P softmax_tb.NUM_ELEMENTS=16 softmax_tb.sv softmax.sv
//
// Final line is exactly one of:
//   TEST_RESULT: PASS
//   TEST_RESULT: FAIL: <reason>
// =============================================================================

`timescale 1ns/1ps

module softmax_tb;

    // ---------------- configuration ----------------
    parameter int NUM_ELEMENTS        = 8;    // 4 / 8 / 16
    parameter int RANDOM_VECTORS      = 1500; // >= 1000 required
    parameter int MAX_ERRORS_REPORTED = 15;

    localparam int IN_W     = 16;
    localparam int OUT_W    = 16;
    localparam int IN_FRAC  = 12;
    localparam int OUT_FRAC = 16;

    localparam real IN_SCALE  = 4096.0;    // 2^IN_FRAC
    localparam real OUT_SCALE = 65536.0;   // 2^OUT_FRAC

    // ---- explicit error tolerances, in Q0.16 LSBs (see iface header) ----
    localparam int TOL_ABS_LSB   = 656;    // A1: 0.01 absolute, per element
    localparam int TOL_SUM_LSB   = 1312;   // A2: 0.02 on sum(out) vs 1.0
    localparam int TOL_TIE_LSB   = 64;     // A3: equal inputs -> equal outputs
    localparam int TOL_ORDER_LSB = 1312;   // A4: order preservation slack
    localparam int TOL_SHIFT_LSB = 1312;   // A5: shift invariance, per element

    localparam int MAX_LAT = 64*NUM_ELEMENTS + 64;

    localparam logic signed [IN_W-1:0] IN_MAX = 16'sh7FFF; // +7.99976
    localparam logic signed [IN_W-1:0] IN_MIN = 16'sh8000; // -8.0

    // ---------------- DUT connections ----------------
    logic                          clk = 1'b0;
    logic                          rst_n;
    logic                          start;
    logic [NUM_ELEMENTS*IN_W-1:0]  in_vec;
    logic                          busy, done;
    logic [NUM_ELEMENTS*OUT_W-1:0] out_vec;

    softmax #(
        .NUM_ELEMENTS (NUM_ELEMENTS)
    ) dut (
        .clk (clk), .rst_n (rst_n),
        .start (start), .in_vec (in_vec),
        .busy (busy), .done (done), .out_vec (out_vec)
    );

    always #5 clk = ~clk;

    // ---------------- bookkeeping ----------------
    int    errors = 0;
    int    checks = 0;
    int    worst_abs_err = 0;
    int    worst_sum_err = 0;
    string fail_reason = "";
    string phase = "init";

    task automatic note_fail(input string why);
        errors++;
        if (fail_reason == "") fail_reason = why;
        if (errors <= MAX_ERRORS_REPORTED)
            $display("[FAIL] t=%0t phase=%s : %s", $time, phase, why);
        else if (errors == MAX_ERRORS_REPORTED + 1)
            $display("[FAIL] ... further failures suppressed");
    endtask

    function automatic int iabs(input int v); return (v < 0) ? -v : v; endfunction

    // ---------------- vectors ----------------
    logic signed [IN_W-1:0] x     [0:NUM_ELEMENTS-1];  // current stimulus
    int                     obs   [0:NUM_ELEMENTS-1];  // captured DUT outputs (LSBs)
    int                     obs2  [0:NUM_ELEMENTS-1];  // for shift-invariance
    real                    p     [0:NUM_ELEMENTS-1];  // exact reference probabilities

    function automatic void pack_in();
        for (int i = 0; i < NUM_ELEMENTS; i++)
            in_vec[i*IN_W +: IN_W] = x[i];
    endfunction

    // ---------------- reference: exact real-valued softmax ----------------
    function automatic void ref_softmax();
        real xr [0:NUM_ELEMENTS-1];
        real m, s;
        for (int i = 0; i < NUM_ELEMENTS; i++)
            xr[i] = real'(x[i]) / IN_SCALE;
        m = xr[0];
        for (int i = 1; i < NUM_ELEMENTS; i++)
            if (xr[i] > m) m = xr[i];
        s = 0.0;
        for (int i = 0; i < NUM_ELEMENTS; i++) begin
            p[i] = $exp(xr[i] - m);   // in (0,1], no overflow possible
            s   += p[i];
        end
        for (int i = 0; i < NUM_ELEMENTS; i++)
            p[i] = p[i] / s;
    endfunction

    // =========================================================================
    // Transaction driver + handshake checker. Captures out_vec into `obs`.
    // =========================================================================
    task automatic run_dut(input string ctx);
        int lat;
        bit finished;
        // wait for idle
        lat = 0;
        while (busy === 1'b1) begin
            @(posedge clk); #1;
            lat++;
            if (lat > MAX_LAT + 4) begin
                note_fail($sformatf("%s: busy never deasserted", ctx));
                return;
            end
        end

        pack_in();
        start = 1'b1;
        #1;
        if (done === 1'b1)
            note_fail($sformatf("%s: done asserted in the accepting cycle", ctx));
        @(posedge clk);
        #1;                       // drive strictly after the sampling edge
        start  = 1'b0;
        // in_vec must have been captured -- scramble it
        for (int i = 0; i < NUM_ELEMENTS*IN_W; i += 32)
            in_vec[i +: 16] = 16'($urandom());

        lat      = 1;
        finished = 1'b0;
        while (!finished) begin
            if (done === 1'b1) begin
                finished = 1'b1;
                if (busy !== 1'b1)
                    note_fail($sformatf("%s: busy must be 1 in the done cycle", ctx));
                for (int i = 0; i < NUM_ELEMENTS; i++)
                    obs[i] = int'(out_vec[i*OUT_W +: OUT_W]);
            end else begin
                if (busy !== 1'b1)
                    note_fail($sformatf("%s: busy deasserted at cycle %0d before done", ctx, lat));
                if (lat == 1) start = 1'b1;      // start-while-busy must be ignored
                else if (lat == 2) start = 1'b0;
                if (lat > MAX_LAT) begin
                    note_fail($sformatf("%s: no done within %0d cycles", ctx, MAX_LAT));
                    return;
                end
                @(posedge clk); #1;
                lat++;
            end
        end

        @(posedge clk); #1;
        if (done !== 1'b0) note_fail($sformatf("%s: done high for more than one cycle", ctx));
        if (busy !== 1'b0) note_fail($sformatf("%s: busy still set the cycle after done", ctx));
        for (int i = 0; i < NUM_ELEMENTS; i++)
            if (int'(out_vec[i*OUT_W +: OUT_W]) != obs[i])
                note_fail($sformatf("%s: out_vec[%0d] not held stable after done", ctx, i));
        start = 1'b0;
    endtask

    // =========================================================================
    // Accuracy checks A1..A4 on the captured `obs` against reference `p`
    // =========================================================================
    task automatic check_accuracy(input string ctx);
        int  sum_o, e;
        real expected_lsb;
        checks++;
        ref_softmax();

        // A1: per-element absolute error
        sum_o = 0;
        for (int i = 0; i < NUM_ELEMENTS; i++) begin
            expected_lsb = p[i] * OUT_SCALE;
            e = iabs(obs[i] - int'(expected_lsb + 0.5));
            if (e > worst_abs_err) worst_abs_err = e;
            if (e > TOL_ABS_LSB)
                note_fail($sformatf("%s: A1 element %0d out=%0d (%.6f) expected %.1f (%.6f) err=%0d LSB > tol %0d",
                                    ctx, i, obs[i], real'(obs[i])/OUT_SCALE,
                                    expected_lsb, p[i], e, TOL_ABS_LSB));
            sum_o += obs[i];
        end

        // A2: normalisation
        e = iabs(sum_o - 65536);
        if (e > worst_sum_err) worst_sum_err = e;
        if (e > TOL_SUM_LSB)
            note_fail($sformatf("%s: A2 sum(out)=%0d (%.6f) deviates %0d LSB from 1.0 > tol %0d",
                                ctx, sum_o, real'(sum_o)/OUT_SCALE, e, TOL_SUM_LSB));

        // A3 / A4: tie consistency and order preservation
        for (int i = 0; i < NUM_ELEMENTS; i++)
            for (int j = 0; j < NUM_ELEMENTS; j++) begin
                if (i == j) continue;
                if (x[i] == x[j]) begin
                    if (iabs(obs[i] - obs[j]) > TOL_TIE_LSB)
                        note_fail($sformatf("%s: A3 equal inputs %0d,%0d gave %0d vs %0d",
                                            ctx, i, j, obs[i], obs[j]));
                end else if (x[i] > x[j]) begin
                    if (obs[i] < obs[j] - TOL_ORDER_LSB)
                        note_fail($sformatf("%s: A4 in[%0d]=%0d > in[%0d]=%0d but out %0d < %0d",
                                            ctx, i, x[i], j, x[j], obs[i], obs[j]));
                end
            end
    endtask

    // convenience: drive the current x, then check it
    task automatic run_and_check(input string ctx);
        run_dut(ctx);
        check_accuracy(ctx);
    endtask

    // ---- A5: shift invariance. Runs x, then x+shift, compares. ----
    task automatic check_shift_invariance(input int shift_lsb, input string ctx);
        int save [0:NUM_ELEMENTS-1];
        int lo, hi;
        // only legal if every shifted element stays representable
        lo = 32767; hi = -32768;
        for (int i = 0; i < NUM_ELEMENTS; i++) begin
            if (int'(x[i]) < lo) lo = int'(x[i]);
            if (int'(x[i]) > hi) hi = int'(x[i]);
        end
        if (lo + shift_lsb < -32768 || hi + shift_lsb > 32767) return;

        run_dut({ctx, "-base"});
        check_accuracy({ctx, "-base"});
        for (int i = 0; i < NUM_ELEMENTS; i++) begin
            save[i] = obs[i];
            x[i]    = IN_W'(int'(x[i]) + shift_lsb);
        end
        run_dut({ctx, "-shifted"});
        check_accuracy({ctx, "-shifted"});
        checks++;
        for (int i = 0; i < NUM_ELEMENTS; i++)
            if (iabs(save[i] - obs[i]) > TOL_SHIFT_LSB)
                note_fail($sformatf("%s: A5 shift by %0d LSB changed element %0d from %0d to %0d (> tol %0d)",
                                    ctx, shift_lsb, i, save[i], obs[i], TOL_SHIFT_LSB));
        // restore
        for (int i = 0; i < NUM_ELEMENTS; i++)
            x[i] = IN_W'(int'(x[i]) - shift_lsb);
    endtask

    task automatic set_all(input logic signed [IN_W-1:0] v);
        for (int i = 0; i < NUM_ELEMENTS; i++) x[i] = v;
    endtask

    task automatic do_reset();
        start = 1'b0; in_vec = '0;
        rst_n = 1'b0;
        repeat (3) @(posedge clk);
        #1;
        if (busy !== 1'b0) note_fail("busy not 0 during reset");
        if (done !== 1'b0) note_fail("done not 0 during reset");
        rst_n = 1'b1;
        @(posedge clk); #1;
    endtask

    // ---------------- stimulus ----------------
    int    uniform_lsb;
    int    tmp;

    initial begin
        if (NUM_ELEMENTS != 4 && NUM_ELEMENTS != 8 && NUM_ELEMENTS != 16) begin
            $display("TEST_RESULT: FAIL: illegal NUM_ELEMENTS=%0d", NUM_ELEMENTS); $finish;
        end

        do_reset();
        uniform_lsb = 65536 / NUM_ELEMENTS;

        // ------------------------------------------------------------------
        // C1: ALL-EQUAL inputs -> exactly uniform 1/N. Checked at several
        //     values including both representable extremes.
        // ------------------------------------------------------------------
        phase = "C1-all-equal";
        begin
            logic signed [IN_W-1:0] vals [0:5];
            vals[0] = 16'sd0;        // 0.0
            vals[1] = IN_MAX;        // +7.99976
            vals[2] = IN_MIN;        // -8.0
            vals[3] = 16'sd4096;     // +1.0
            vals[4] = -16'sd4096;    // -1.0
            vals[5] = 16'sd1;        // +1 LSB
            for (int k = 0; k < 6; k++) begin
                set_all(vals[k]);
                run_and_check($sformatf("all-equal(%0d)", vals[k]));
                for (int i = 0; i < NUM_ELEMENTS; i++)
                    if (iabs(obs[i] - uniform_lsb) > TOL_ABS_LSB)
                        note_fail($sformatf("all-equal(%0d): element %0d = %0d, expected ~%0d",
                                            vals[k], i, obs[i], uniform_lsb));
            end
        end

        // ------------------------------------------------------------------
        // C2: ONE DOMINANT input -> near one-hot distribution
        // ------------------------------------------------------------------
        phase = "C2-one-dominant";
        for (int d = 0; d < NUM_ELEMENTS; d++) begin
            set_all(IN_MIN);
            x[d] = IN_MAX;
            run_and_check($sformatf("dominant(%0d)", d));
            if (obs[d] < 65536 - TOL_ABS_LSB - 1)
                note_fail($sformatf("dominant(%0d): winner=%0d, expected near full scale", d, obs[d]));
            for (int i = 0; i < NUM_ELEMENTS; i++)
                if (i != d && obs[i] > TOL_ABS_LSB)
                    note_fail($sformatf("dominant(%0d): loser %0d = %0d, expected ~0", d, i, obs[i]));
        end

        // dominant by a SMALL margin (a few LSBs) -- must NOT be one-hot
        phase = "C2b-narrow-margin";
        for (int m = 1; m <= 4; m++) begin
            set_all(16'sd0);
            x[0] = IN_W'(m);
            run_and_check($sformatf("narrow-margin(%0d)", m));
            if (obs[0] > uniform_lsb + 4*TOL_ABS_LSB)
                note_fail($sformatf("narrow-margin(%0d): winner %0d far above uniform %0d",
                                    m, obs[0], uniform_lsb));
        end

        // ------------------------------------------------------------------
        // C3: ALL-NEGATIVE inputs (result must still normalise to 1.0)
        // ------------------------------------------------------------------
        phase = "C3-all-negative";
        for (int i = 0; i < NUM_ELEMENTS; i++)
            x[i] = IN_W'(-4096 - 256*i);              // -1.0, -1.0625, ...
        run_and_check("all-negative-ramp");
        for (int i = 0; i < NUM_ELEMENTS; i++)
            x[i] = IN_W'(-32768 + 100*i);             // clustered at the bottom
        run_and_check("all-negative-extreme");
        set_all(-16'sd8192);
        x[0] = -16'sd8191;
        run_and_check("all-negative-near-tie");

        // ------------------------------------------------------------------
        // C4: ALL-POSITIVE inputs
        // ------------------------------------------------------------------
        phase = "C4-all-positive";
        for (int i = 0; i < NUM_ELEMENTS; i++)
            x[i] = IN_W'(4096 + 256*i);
        run_and_check("all-positive-ramp");
        for (int i = 0; i < NUM_ELEMENTS; i++)
            x[i] = IN_W'(32767 - 100*i);
        run_and_check("all-positive-extreme");

        // ------------------------------------------------------------------
        // C5: NEAR-ZERO inputs -- +/- a few LSBs. Output must be near uniform;
        //     this catches implementations that collapse small differences.
        // ------------------------------------------------------------------
        phase = "C5-near-zero";
        for (int mag = 1; mag <= 8; mag = mag*2) begin
            for (int i = 0; i < NUM_ELEMENTS; i++)
                x[i] = IN_W'((i % 2) ? mag : -mag);
            run_and_check($sformatf("near-zero(+/-%0d)", mag));
            for (int i = 0; i < NUM_ELEMENTS; i++)
                if (iabs(obs[i] - uniform_lsb) > TOL_ABS_LSB)
                    note_fail($sformatf("near-zero(+/-%0d): element %0d = %0d, expected ~%0d",
                                        mag, i, obs[i], uniform_lsb));
        end
        // strictly zero except one 1-LSB bump
        set_all(16'sd0);
        x[NUM_ELEMENTS-1] = 16'sd1;
        run_and_check("near-zero-single-lsb");

        // ------------------------------------------------------------------
        // C6: TIES for the maximum (2-way, and half the vector)
        // ------------------------------------------------------------------
        phase = "C6-ties";
        set_all(IN_MIN);
        x[0] = IN_MAX; x[1] = IN_MAX;
        run_and_check("two-way-max-tie");
        if (iabs(obs[0] - obs[1]) > TOL_TIE_LSB)
            note_fail("two-way max tie produced unequal outputs");
        if (iabs(obs[0] - 32768) > TOL_ABS_LSB)
            note_fail($sformatf("two-way max tie: expected ~0.5 each, got %0d", obs[0]));

        set_all(-16'sd4096);
        for (int i = 0; i < NUM_ELEMENTS/2; i++) x[i] = 16'sd4096;
        run_and_check("half-tie");

        // ------------------------------------------------------------------
        // C7: extreme dynamic range and alternating extremes
        // ------------------------------------------------------------------
        phase = "C7-extremes";
        for (int i = 0; i < NUM_ELEMENTS; i++)
            x[i] = (i % 2) ? IN_MAX : IN_MIN;
        run_and_check("alternating-extremes");
        for (int i = 0; i < NUM_ELEMENTS; i++)
            x[i] = IN_W'(-32768 + i*(65535/(NUM_ELEMENTS-1)));  // full-range ramp
        run_and_check("full-range-ramp");
        // monotone ramp must produce monotone outputs (A4 covers it, but assert
        // strict ordering here where the gaps are far larger than the slack)
        for (int i = 0; i < NUM_ELEMENTS-1; i++)
            if (obs[i] > obs[i+1] + TOL_ORDER_LSB)
                note_fail($sformatf("full-range-ramp not monotone at %0d (%0d then %0d)",
                                    i, obs[i], obs[i+1]));

        // ------------------------------------------------------------------
        // C8: SHIFT INVARIANCE (A5) on a spread of base vectors
        // ------------------------------------------------------------------
        phase = "C8-shift-invariance";
        for (int i = 0; i < NUM_ELEMENTS; i++) x[i] = IN_W'(i*128);
        check_shift_invariance( 4096, "shift+1.0");
        check_shift_invariance(-4096, "shift-1.0");
        check_shift_invariance(   17, "shift+17lsb");
        for (int i = 0; i < NUM_ELEMENTS; i++) x[i] = IN_W'(-2048 + i*37);
        check_shift_invariance( 8192, "shift+2.0");
        check_shift_invariance(-8192, "shift-2.0");
        set_all(16'sd0);
        check_shift_invariance( 4096, "shift-uniform");

        // ------------------------------------------------------------------
        // C9: reset while a softmax is in flight
        // ------------------------------------------------------------------
        phase = "C9-reset-inflight";
        set_all(16'sd100);
        pack_in();
        start = 1'b1;
        @(posedge clk); #1;
        start = 1'b0;
        @(posedge clk); #1;
        rst_n = 1'b0;
        repeat (2) @(posedge clk); #1;
        if (busy !== 1'b0) note_fail("reset did not clear busy");
        if (done !== 1'b0) note_fail("reset did not clear done");
        rst_n = 1'b1;
        @(posedge clk); #1;
        set_all(16'sd0);
        run_and_check("post-reset");

        // ------------------------------------------------------------------
        // R1: constrained-random regression
        // ------------------------------------------------------------------
        phase = "R1-random";
        for (int v = 0; v < RANDOM_VECTORS; v++) begin
            case ((v / 250) % 6)
                0: begin // full-range uniform
                    for (int i = 0; i < NUM_ELEMENTS; i++)
                        x[i] = IN_W'($urandom());
                end
                1: begin // tightly clustered near zero (fine resolution regime)
                    for (int i = 0; i < NUM_ELEMENTS; i++)
                        x[i] = IN_W'($urandom_range(0, 64) - 32);
                end
                2: begin // clustered around a random offset (shift-sensitive)
                    tmp = $urandom_range(0, 40000) - 20000;
                    for (int i = 0; i < NUM_ELEMENTS; i++)
                        x[i] = IN_W'(tmp + $urandom_range(0, 2048) - 1024);
                end
                3: begin // one spike, rest low  (near one-hot)
                    for (int i = 0; i < NUM_ELEMENTS; i++)
                        x[i] = IN_W'($urandom_range(0, 4096) - 32768);
                    x[$urandom_range(0, NUM_ELEMENTS-1)] = IN_W'($urandom_range(20000, 32767));
                end
                4: begin // many duplicates -> exercises A3
                    tmp = int'(IN_W'($urandom()));
                    for (int i = 0; i < NUM_ELEMENTS; i++)
                        x[i] = ($urandom_range(0,1)) ? IN_W'(tmp) : IN_W'($urandom());
                end
                5: begin // all negative / all positive halves
                    for (int i = 0; i < NUM_ELEMENTS; i++)
                        x[i] = ($urandom_range(0,1))
                             ? IN_W'(-$urandom_range(1, 32768))
                             : IN_W'( $urandom_range(0, 32767));
                end
            endcase
            run_and_check($sformatf("rand%0d", v));
        end

        // ------------------------------------------------------------------
        phase = "final";
        if (checks < 1000)
            note_fail($sformatf("insufficient coverage: only %0d checks executed", checks));

        if (errors == 0) begin
            $display("// info: %0d vector checks; worst per-element error %0d LSB (tol %0d), worst sum error %0d LSB (tol %0d)",
                     checks, worst_abs_err, TOL_ABS_LSB, worst_sum_err, TOL_SUM_LSB);
            $display("TEST_RESULT: PASS");
        end else
            $display("TEST_RESULT: FAIL: %s (%0d failing checks of %0d)",
                     fail_reason, errors, checks);
        $finish;
    end

    initial begin
        #500_000_000;
        $display("TEST_RESULT: FAIL: timeout -- testbench did not complete");
        $finish;
    end

endmodule
