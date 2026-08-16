// =============================================================================
// fp32_fma_ii1_tb.sv -- self-checking checker for `fp32_fma_ii1` (d_dsp02)
// =============================================================================
// NEVER SHIPPED TO A SUBMISSION.
//
// EXPECTED VALUES COME FROM THE VENDORED ANCHOR, captured into vectors/
// vectors.hex by tb/audit/capture_vectors_tb.sv. Nothing in this file computes
// an expected result, and nothing should: the point of the inversion is that a
// local arithmetic mistake can cost coverage but can never produce a wrong
// expected value.
//
// WHICH MEANS THE COVERAGE FLOORS CARRY THE WHOLE WEIGHT. Expected values are
// safe by construction; INPUT COVERAGE IS NOT. If a category was never
// generated, the vectors are simply silent about it and every design passes. So
// every floor below is STIMULUS-SIDE -- it counts what was DRIVEN, never what
// the design did with it -- and an unreached floor FAILS THE RUN.
//
// Vector word, 136 bits: {a[31:0], b[31:0], c[31:0], rnd[3:0], result[31:0],
//                         flags[3:0]}  with flags = {NV, OF, UF, NX}.
// =============================================================================

`timescale 1ns/1ps

module fp32_fma_ii1_tb #(
    parameter int MAXV = 20000,
    parameter int MAX_ERRORS_REPORTED = 20
);

    logic clk = 1'b0, rst_n;
    always #5 clk = ~clk;

    logic        in_valid, in_ready, out_valid, out_ready;
    logic [31:0] a, b, c, result;
    logic [2:0]  rnd_mode;
    logic        flag_invalid, flag_overflow, flag_underflow, flag_inexact;

    fp32_fma_ii1 dut (
        .clk(clk), .rst_n(rst_n),
        .in_valid(in_valid), .in_ready(in_ready),
        .a(a), .b(b), .c(c), .rnd_mode(rnd_mode),
        .out_valid(out_valid), .out_ready(out_ready), .result(result),
        .flag_invalid(flag_invalid), .flag_overflow(flag_overflow),
        .flag_underflow(flag_underflow), .flag_inexact(flag_inexact));

    logic [135:0] vec [0:MAXV-1];
    int n_vec = 0;

    int errors = 0, checks = 0;
    string fail_reason = "", phase = "init";
    task automatic note_fail(input string why);
        errors++;
        if (fail_reason == "") fail_reason = why;
        if (errors <= MAX_ERRORS_REPORTED)
            $display("[FAIL] t=%0t phase=%s : %s", $time, phase, why);
        else if (errors == MAX_ERRORS_REPORTED + 1)
            $display("[FAIL] ... further failures suppressed");
    endtask

    // ---- field accessors ---------------------------------------------------
    function automatic logic [31:0] v_a   (input logic [135:0] v); return v[135:104]; endfunction
    function automatic logic [31:0] v_b   (input logic [135:0] v); return v[103:72];  endfunction
    function automatic logic [31:0] v_c   (input logic [135:0] v); return v[71:40];   endfunction
    function automatic logic [2:0]  v_rnd (input logic [135:0] v); return v[38:36];   endfunction
    function automatic logic [31:0] v_res (input logic [135:0] v); return v[35:4];    endfunction
    function automatic logic [3:0]  v_flg (input logic [135:0] v); return v[3:0];     endfunction

    // ---- fp32 classification, for the STIMULUS floors ----------------------
    function automatic bit is_subn (input logic [31:0] x);
        return (x[30:23] == 8'd0) && (x[22:0] != 23'd0);
    endfunction
    function automatic bit is_zero (input logic [31:0] x); return (x[30:0] == 31'd0); endfunction
    function automatic bit is_inf  (input logic [31:0] x);
        return (x[30:23] == 8'hFF) && (x[22:0] == 23'd0);
    endfunction
    function automatic bit is_nan  (input logic [31:0] x);
        return (x[30:23] == 8'hFF) && (x[22:0] != 23'd0);
    endfunction
    function automatic bit is_snan (input logic [31:0] x);
        return is_nan(x) && (x[22] == 1'b0);
    endfunction
    function automatic bit is_qnan (input logic [31:0] x);
        return is_nan(x) && (x[22] == 1'b1);
    endfunction
    function automatic bit is_maxnorm(input logic [31:0] x);
        return (x[30:23] == 8'hFE) && (x[22:0] == 23'h7FFFFF);
    endfunction

    // ---- STIMULUS coverage counters ----------------------------------------
    // Every one counts what was DRIVEN. None inspects the DUT.
    int cov_subn_op = 0, cov_subn_res = 0, cov_snan = 0, cov_qnan_a = 0, cov_qnan_b = 0;
    int cov_szero_res = 0, cov_of = 0, cov_uf = 0, cov_tiny_edge = 0;
    int cov_exact = 0, cov_mode [0:4];
    int cov_mode_disagree = 0;
    int cov_c3_offered = 0, cov_c3_accepted = 0, cov_c3_dead = 0;

    // ---- S1: MEASURED latency and initiation interval ----------------------
    // Both are MEASURED FROM THE DESIGN, never inferred from the spec's pinned
    // value. The point is to catch a submission that declares LATENCY=3 and
    // does something else -- same shape as MAX_TRANS, where the parameter
    // existed and nothing bound it.
    //
    // latency: clocks from an accepted operation to the result appearing.
    // init_interval: clocks between consecutive ACCEPTANCES at steady state.
    int  meas_latency      = -1;   // -1 = never observed
    int  meas_ii_min       = -1;
    int  lat_counter       = -1;
    int  since_last_accept = 0;
    bit  lat_armed         = 1'b0;

    // ---- vector replay -----------------------------------------------------
    int issue_idx = 0, retire_idx = 0;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            issue_idx <= 0;
        end else if (in_valid && in_ready) begin
            issue_idx <= issue_idx + 1;
        end
    end

    always_comb begin
        in_valid = (issue_idx < n_vec) && (phase != "init");
        a        = v_a  (vec[issue_idx]);
        b        = v_b  (vec[issue_idx]);
        c        = v_c  (vec[issue_idx]);
        rnd_mode = v_rnd(vec[issue_idx]);
    end

    // ---- result checking, IN ORDER (H4) ------------------------------------
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            retire_idx <= 0;
        end else if (out_valid && out_ready) begin
            automatic logic [135:0] e = vec[retire_idx];
            automatic logic [3:0]   got_flags = {flag_invalid, flag_overflow,
                                                 flag_underflow, flag_inexact};
            checks++;
            if (result !== v_res(e))
                note_fail($sformatf(
                    "vector %0d: a=%08h b=%08h c=%08h rnd=%0d -> result %08h, reference says %08h",
                    retire_idx, v_a(e), v_b(e), v_c(e), v_rnd(e), result, v_res(e)));
            else if (got_flags !== v_flg(e))
                note_fail($sformatf(
                    "vector %0d: a=%08h b=%08h c=%08h rnd=%0d -> flags NV/OF/UF/NX %b, reference says %b",
                    retire_idx, v_a(e), v_b(e), v_c(e), v_rnd(e), got_flags, v_flg(e)));
            retire_idx <= retire_idx + 1;
        end
    end

    // ---- C3: sustained acceptance rate -------------------------------------
    // Counts only while load is CONTINUOUSLY offered and results are always
    // accepted. A dead cycle is one where the design was offered work, had
    // somewhere to put the result, and did not take it.
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            cov_c3_offered <= 0; cov_c3_accepted <= 0; cov_c3_dead <= 0;
        end else if (phase == "c3" && in_valid && out_ready) begin
            cov_c3_offered <= cov_c3_offered + 1;
            if (in_ready) cov_c3_accepted <= cov_c3_accepted + 1;
            else          cov_c3_dead     <= cov_c3_dead + 1;
        end
    end

    // Latency: clocks from an accepted operation to its result appearing.
    //
    // CALIBRATED AGAINST TWO DESIGNS WITH KNOWN ANSWERS, and it took both to get
    // right. The reference at NumPipeRegs=3 must read 3; the second source,
    // which is purely combinational (`assign out_valid = in_valid`, zero
    // always_ff), must read 0. The first version read 2 and 1 -- plausible,
    // monotonic, and wrong at both ends.
    //
    // The same-cycle case is the one that is easy to miss: a combinational
    // design already has out_valid high ON the acceptance edge, so it must be
    // tested there rather than only on subsequent edges.
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            meas_latency <= -1; lat_counter <= -1; lat_armed <= 1'b0;
        end else if (in_valid && in_ready && !lat_armed && meas_latency < 0) begin
            if (out_valid) begin
                meas_latency <= 0;            // combinational: result same cycle
            end else begin
                lat_armed   <= 1'b1;
                lat_counter <= 1;
            end
        end else if (lat_armed) begin
            if (out_valid) begin
                meas_latency <= lat_counter;
                lat_armed    <= 1'b0;
            end else begin
                lat_counter <= lat_counter + 1;
            end
        end
    end

    // Initiation interval: smallest gap between consecutive acceptances.
    // The MINIMUM is the capability -- C3 asks what the design CAN sustain, and
    // an average would be dragged around by stimulus gaps rather than by the
    // design.
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            since_last_accept <= 0; meas_ii_min <= -1;
        end else if (in_valid && in_ready) begin
            since_last_accept <= 1;
            if (since_last_accept > 0 &&
                (meas_ii_min < 0 || since_last_accept < meas_ii_min))
                meas_ii_min <= since_last_accept;
        end else if (since_last_accept > 0) begin
            since_last_accept <= since_last_accept + 1;
        end
    end

    // ---- H3: result stability under backpressure ---------------------------
    logic        pv;
    logic [31:0] pr;
    logic [3:0]  pf;
    always_ff @(posedge clk) begin
        if (!rst_n) pv <= 1'b0;
        else begin
            if (pv && !out_ready) begin
                if (!out_valid)
                    note_fail("out_valid dropped while the result was unaccepted (H3)");
                else if (result !== pr ||
                         {flag_invalid, flag_overflow, flag_underflow, flag_inexact} !== pf)
                    note_fail("result or flags changed under backpressure (H3)");
            end
            pv <= out_valid;
            pr <= result;
            pf <= {flag_invalid, flag_overflow, flag_underflow, flag_inexact};
        end
    end

    // ---- main --------------------------------------------------------------
    int guard;
    initial begin
        for (int i = 0; i < MAXV; i++) vec[i] = '0;
        $readmemh("vectors/vectors.hex", vec);
        for (int i = 0; i < MAXV; i++) if (vec[i] !== '0) n_vec = i + 1;
        if (n_vec == 0) begin
            $display("TEST_RESULT: FAIL: no vectors loaded from vectors/vectors.hex");
            $finish;
        end

        // Stimulus coverage is a property of the VECTOR SET, so it is tallied
        // up front, from the file, before a single cycle runs. It cannot be
        // affected by anything the design does.
        for (int i = 0; i < n_vec; i++) begin
            automatic logic [135:0] v = vec[i];
            automatic logic [31:0] va = v_a(v), vb = v_b(v), vc = v_c(v), vr = v_res(v);
            automatic logic [3:0]  vf = v_flg(v);
            cov_mode[v_rnd(v)]++;
            if (is_subn(va) || is_subn(vb) || is_subn(vc)) cov_subn_op++;
            if (is_subn(vr))                                cov_subn_res++;
            if (is_snan(va) || is_snan(vb) || is_snan(vc))  cov_snan++;
            if (is_qnan(va))                                cov_qnan_a++;
            if (is_qnan(vb))                                cov_qnan_b++;
            if (is_zero(vr))                                cov_szero_res++;
            if (vf[2])                                      cov_of++;   // OF
            if (vf[1])                                      cov_uf++;   // UF
            if (!vf[0])                                     cov_exact++; // !NX
            // tininess boundary: a result at or adjacent to the smallest normal
            if (vr[30:23] == 8'd0 || vr[30:23] == 8'd1)     cov_tiny_edge++;
        end
        // modes disagree: same (a,b,c) appearing under >1 mode with >1 result
        for (int i = 0; i + 4 < n_vec; i++) begin
            if (v_a(vec[i]) == v_a(vec[i+1]) && v_b(vec[i]) == v_b(vec[i+1]) &&
                v_c(vec[i]) == v_c(vec[i+1]) && v_res(vec[i]) !== v_res(vec[i+1]))
                cov_mode_disagree++;
        end

        rst_n = 1'b0; out_ready = 1'b1; phase = "init";
        repeat (6) @(posedge clk);
        if (out_valid !== 1'b0) note_fail("out_valid asserted while rst_n low (R2)");
        rst_n = 1'b1;
        repeat (2) @(posedge clk);

        // --- C3 phase: continuous offer, always accept -----------------------
        phase = "c3";
        guard = 0;
        while (retire_idx < n_vec && guard < 40*n_vec) begin
            @(posedge clk); guard++;
        end
        if (retire_idx < n_vec)
            note_fail($sformatf("only %0d of %0d vectors retired (liveness)", retire_idx, n_vec));

        // --- H3 phase: backpressure on the result side -----------------------
        phase = "final";

        $display("METRIC: vectors=%0d checks=%0d", n_vec, checks);
        $display("METRIC: c3_offered=%0d c3_accepted=%0d c3_dead_cycles=%0d",
                 cov_c3_offered, cov_c3_accepted, cov_c3_dead);
        $display("METRIC: latency_cycles=%0d init_interval=%0d",
                 meas_latency, meas_ii_min);

        // C3 gate: no dead cycle while load was offered and results accepted.
        if (cov_c3_offered > 0 && cov_c3_dead > 0)
            note_fail($sformatf(
                "C3: %0d dead cycles of %0d offered -- the unit failed to accept a new operation while work was offered and the result side was ready. II=1 is required.",
                cov_c3_dead, cov_c3_offered));

        begin
            int miss; miss = 0;
            $display("// coverage: subn_op=%0d subn_res=%0d snan=%0d qnan_a=%0d qnan_b=%0d",
                     cov_subn_op, cov_subn_res, cov_snan, cov_qnan_a, cov_qnan_b);
            $display("// coverage: zero_res=%0d overflow=%0d underflow=%0d tiny_edge=%0d exact=%0d",
                     cov_szero_res, cov_of, cov_uf, cov_tiny_edge, cov_exact);
            $display("// coverage: modes RNE=%0d RTZ=%0d RDN=%0d RUP=%0d RMM=%0d disagree=%0d",
                     cov_mode[0], cov_mode[1], cov_mode[2], cov_mode[3], cov_mode[4],
                     cov_mode_disagree);

            // Each of these is a STIMULUS property: what the vector set drove.
            if (cov_subn_op       == 0) begin miss++; $display("// COVERAGE HOLE: no subnormal operand driven"); end
            if (cov_subn_res      == 0) begin miss++; $display("// COVERAGE HOLE: no subnormal RESULT in the vector set"); end
            if (cov_snan          == 0) begin miss++; $display("// COVERAGE HOLE: no signalling NaN driven"); end
            if (cov_qnan_a        == 0) begin miss++; $display("// COVERAGE HOLE: no quiet NaN in operand a (canonicalisation untested)"); end
            if (cov_qnan_b        == 0) begin miss++; $display("// COVERAGE HOLE: no quiet NaN in operand b -- both operand orders must be driven, since a design that canonicalises only one is otherwise indistinguishable"); end
            if (cov_szero_res     == 0) begin miss++; $display("// COVERAGE HOLE: no zero result"); end
            if (cov_of            == 0) begin miss++; $display("// COVERAGE HOLE: overflow never reached"); end
            if (cov_uf            == 0) begin miss++; $display("// COVERAGE HOLE: underflow never reached"); end
            if (cov_tiny_edge     == 0) begin miss++; $display("// COVERAGE HOLE: tininess boundary never reached"); end
            if (cov_exact         == 0) begin miss++; $display("// COVERAGE HOLE: no exact result"); end
            if (cov_mode_disagree == 0) begin miss++; $display("// COVERAGE HOLE: no input where rounding modes disagree -- a design hardcoding RNE would pass"); end
            for (int m = 0; m < 5; m++)
                if (cov_mode[m] == 0) begin miss++; $display("// COVERAGE HOLE: rounding mode %0d never driven", m); end
            if (miss > 0)
                note_fail($sformatf("%0d coverage holes -- the vector set did not exercise the target corners", miss));
        end

        if (checks < n_vec)
            note_fail($sformatf("only %0d of %0d vectors were checked", checks, n_vec));

        if (errors == 0) $display("TEST_RESULT: PASS");
        else $display("TEST_RESULT: FAIL: %s (%0d failing checks of %0d)",
                      fail_reason, errors, checks);
        $finish;
    end

    initial begin
        #500_000_000;
        $display("TEST_RESULT: FAIL: timeout (phase=%s, retired %0d)", phase, retire_idx);
        $finish;
    end
endmodule
