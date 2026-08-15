// =============================================================================
// async_fifo_cdc_tb.sv -- self-checking checker for `async_fifo_cdc` (d_ca04)
// =============================================================================
// NEVER SHIPPED TO A SUBMISSION.
//
// TWO CLOCK DOMAINS. This is the first two-clock harness in the project and the
// structure is deliberate:
//
//   * Timescale is 1ps/1ps and half-periods are integers in picoseconds, so
//     ratios like 5000:5100 (near-equal, slowly drifting past each other) are
//     expressible. That drift case is where false-full and false-empty bugs
//     live, and it cannot be written with 1ns resolution.
//
//   * The scoreboard has ONE WRITER PER INDEX. `wr_idx` is incremented only by
//     the write-domain monitor and `rd_idx` only by the read-domain monitor.
//     No variable is written from both domains, so there is no cross-domain
//     race in the checker itself -- which would otherwise be indistinguishable
//     from a CDC bug in the DUT.
//
//   * Drivers are clocked processes gated by enables set from a single
//     sequencer. Driving valid/ready from the sequencer directly would put
//     stimulus edges in the wrong domain.
//
// LATENCY IS NEVER CHECKED. Crossing latency depends on SYNC_STAGES and on the
// ratio of two unrelated clocks, so no fixed number could be right. Only
// liveness is bounded.
//
// Build with --binary --timing --x-assign unique --x-initial unique, top module
// async_fifo_cdc_tb, -GDATA_W / -GLOG_DEPTH / -GSYNC_STAGES.
//
// Final line is exactly one of:
//   TEST_RESULT: PASS
//   TEST_RESULT: FAIL: <reason>
// =============================================================================

`timescale 1ps/1ps

module async_fifo_cdc_tb;

    parameter int DATA_W      = 32;    // 8 / 32 / 64
    parameter int LOG_DEPTH   = 3;     // 2 / 3 / 4
    parameter int SYNC_STAGES = 2;     // 2 / 3
    parameter int MAX_ERRORS_REPORTED = 20;
    parameter int MIN_CHECKS  = 2000;
    parameter int BEATS_PER_PHASE = 600;

    localparam int DEPTH = 1 << LOG_DEPTH;
    localparam int MAXQ  = 65536;

    // ---------------- clocks: half-periods in ps, changed between phases ----
    int wr_half = 5000;
    int rd_half = 5000;
    logic wr_clk = 1'b0;
    logic rd_clk = 1'b0;
    always #(wr_half) wr_clk = ~wr_clk;
    always #(rd_half) rd_clk = ~rd_clk;

    logic              wr_rst_n, rd_rst_n;
    logic              wr_valid, wr_ready;
    logic [DATA_W-1:0] wr_data;
    logic              rd_valid, rd_ready;
    logic [DATA_W-1:0] rd_data;

    async_fifo_cdc #(
        .DATA_W(DATA_W), .LOG_DEPTH(LOG_DEPTH), .SYNC_STAGES(SYNC_STAGES)
    ) dut (
        .wr_clk(wr_clk), .wr_rst_n(wr_rst_n), .wr_valid(wr_valid),
        .wr_ready(wr_ready), .wr_data(wr_data),
        .rd_clk(rd_clk), .rd_rst_n(rd_rst_n), .rd_valid(rd_valid),
        .rd_ready(rd_ready), .rd_data(rd_data));

    // ---------------- bookkeeping ----------------
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

    // ---------------- scoreboard: one writer per index ----------------
    logic [DATA_W-1:0] model [0:MAXQ-1];
    int wr_idx = 0;          // written ONLY by the write-domain monitor
    int rd_idx = 0;          // written ONLY by the read-domain monitor

    // ---------------- coverage ----------------
    int cov_full = 0;        // wr_ready low while wr_valid high (backpressure)
    int cov_empty = 0;       // rd_valid low while rd_ready high (starved)
    int cov_wr_stall = 0, cov_rd_stall = 0;
    int cov_phases = 0;
    int cov_depth_reached = 0;   // occupancy actually hit DEPTH
    int cov_stagger = 0;         // reset released at different times per domain
    int occ_max = 0;

    // ---------------- write-domain driver + monitor ----------------
    bit wr_en = 1'b0;
    int wr_weight = 90;      // percent of cycles wr_valid is offered

    always_ff @(posedge wr_clk) begin
        if (!wr_rst_n) begin
            wr_valid <= 1'b0;
            wr_data  <= '0;
        end else begin
            // H2: hold valid and data until accepted.
            if (wr_valid && !wr_ready) begin
                // keep both stable -- deliberately do nothing
                cov_wr_stall++;
                cov_full++;
            end else begin
                if (wr_en && ($urandom_range(0,99) < wr_weight)) begin
                    wr_valid <= 1'b1;
                    wr_data  <= DATA_W'(wr_idx + 32'h1000_0000);
                end else begin
                    wr_valid <= 1'b0;
                end
            end
        end
    end

    // Accepted write beats are recorded here, in the write domain.
    always_ff @(posedge wr_clk) begin
        if (wr_rst_n && wr_valid && wr_ready) begin
            model[wr_idx % MAXQ] <= wr_data;
            wr_idx <= wr_idx + 1;
        end
    end

    // ---------------- read-domain driver + monitor ----------------
    bit rd_en = 1'b0;
    int rd_weight = 90;      // percent of cycles rd_ready is asserted

    always_ff @(posedge rd_clk) begin
        if (!rd_rst_n) rd_ready <= 1'b0;
        else           rd_ready <= rd_en && ($urandom_range(0,99) < rd_weight);
    end

    logic prev_rd_valid, prev_rd_ready;
    logic [DATA_W-1:0] prev_rd_data;

    always_ff @(posedge rd_clk) begin
        if (!rd_rst_n) begin
            prev_rd_valid <= 1'b0;
            prev_rd_ready <= 1'b0;
        end else begin
            // R5 is checked in the sequencer; here: H3 stability under backpressure
            if (prev_rd_valid && !prev_rd_ready) begin
                if (!rd_valid)
                    note_fail("rd_valid dropped while the beat was unaccepted (H3)");
                else if (rd_data !== prev_rd_data)
                    note_fail("rd_data changed under backpressure (H3)");
            end
            if (!rd_valid && rd_ready) cov_empty++;
            if (rd_valid && !rd_ready) cov_rd_stall++;

            // ---- accepted read beat: C1/C2/C3 ----
            if (rd_valid && rd_ready) begin
                checks++;
                if (rd_idx >= wr_idx) begin
                    // C5: data appeared that was never written on the other side
                    note_fail($sformatf(
                        "phantom beat %0d: read side delivered data with only %0d writes accepted (C5)",
                        rd_idx, wr_idx));
                end else if (rd_data !== model[rd_idx % MAXQ]) begin
                    note_fail($sformatf(
                        "beat %0d: rd_data=0x%0h expected 0x%0h (C1/C3)",
                        rd_idx, rd_data, model[rd_idx % MAXQ]));
                end
                rd_idx <= rd_idx + 1;
            end

            prev_rd_valid <= rd_valid;
            prev_rd_ready <= rd_ready;
            prev_rd_data  <= rd_data;
        end
    end

    // ---------------- occupancy: COVERAGE ONLY, never an assertion ---------
    // wr_idx advances in the write domain and rd_idx in the read domain, so
    // their difference has NO consistent value at any single sampling point:
    // sampled on wr_clk it sees a stale rd_idx and OVERSTATES occupancy.
    //
    // An earlier version of this checker asserted `occ <= DEPTH` here as the C4
    // overflow check and reported overflow on a correct FIFO. That was the
    // checker measuring an unmeasurable cross-domain quantity, not a DUT bug.
    //
    // C4 is still enforced, just through its OBSERVABLE consequences rather
    // than through an internal count: a FIFO that overflows either delivers
    // wrong data (caught by the C1/C3 comparison), loses beats (caught by the
    // drain-completeness check at the end of every phase), or delivers beats
    // that were never written (caught by the C5 phantom check). Those are real
    // per-beat observations in a single domain and they cannot race.
    int occ;
    always_comb occ = wr_idx - rd_idx;
    always_ff @(posedge wr_clk) begin
        if (wr_rst_n) begin
            if (occ > occ_max) occ_max <= occ;
            if (occ >= DEPTH) cov_depth_reached++;   // approximate, coverage only
        end
    end

    // ---------------- reset, honouring R1 and R2 ----------------
    // R1: both resets asserted SIMULTANEOUSLY.
    // R2: released per-domain, synchronised to that domain's own clock, and
    //     deliberately at DIFFERENT times -- the spec permits one side to leave
    //     reset several cycles before the other, so the checker must actually
    //     do it rather than assume simultaneity.
    task automatic do_reset(input int wr_extra, input int rd_extra);
        wr_en = 1'b0; rd_en = 1'b0;
        wr_rst_n = 1'b0;                    // simultaneous assertion
        rd_rst_n = 1'b0;
        repeat (6) @(posedge wr_clk);
        repeat (6) @(posedge rd_clk);
        if (rd_valid !== 1'b0) note_fail("rd_valid asserted while rd_rst_n low (R5)");
        // indices are only safe to clear while BOTH monitors are quiescent
        wr_idx = 0; rd_idx = 0; occ_max = 0;
        if (wr_extra != rd_extra) cov_stagger++;
        fork
            begin repeat (wr_extra) @(posedge wr_clk); @(negedge wr_clk); wr_rst_n = 1'b1; end
            begin repeat (rd_extra) @(posedge rd_clk); @(negedge rd_clk); rd_rst_n = 1'b1; end
        join
        repeat (4) @(posedge wr_clk);
        repeat (4) @(posedge rd_clk);
    endtask

    // ---------------- one traffic phase ----------------
    task automatic run_phase(input string nm, input int wh, input int rh,
                             input int ww, input int rw,
                             input int wr_extra, input int rd_extra);
        int guard;
        phase = nm;
        wr_half = wh; rd_half = rh;
        wr_weight = ww; rd_weight = rw;
        do_reset(wr_extra, rd_extra);

        if (wr_ready !== 1'b1) begin
            guard = 0;
            while (wr_ready !== 1'b1 && guard < 16) begin @(posedge wr_clk); guard++; end
            if (wr_ready !== 1'b1)
                note_fail("wr_ready did not assert within 16 wr_clk cycles of reset release (R4)");
        end

        wr_en = 1'b1; rd_en = 1'b1;
        guard = 0;
        while (wr_idx < BEATS_PER_PHASE && guard < 400*BEATS_PER_PHASE) begin
            @(posedge wr_clk); guard++;
        end
        if (wr_idx < BEATS_PER_PHASE)
            note_fail($sformatf("only %0d of %0d beats accepted (liveness, write side)",
                                wr_idx, BEATS_PER_PHASE));
        wr_en = 1'b0;

        // Let the write side QUIESCE before snapshotting wr_idx. Clearing
        // wr_en stops new beats being offered, but a beat already asserted and
        // waiting for wr_ready (H2 requires holding it) will still be accepted
        // afterwards and will advance wr_idx. Draining against a wr_idx that is
        // still moving leaves that last beat sitting in the FIFO, and the
        // end-of-phase "rd_valid must be low" check then fails on a correct DUT.
        guard = 0;
        while (wr_valid && guard < 256) begin @(posedge wr_clk); guard++; end
        repeat (4) @(posedge wr_clk);

        // drain: read side must deliver everything written
        guard = 0;
        while (rd_idx < wr_idx && guard < 400*BEATS_PER_PHASE) begin
            @(posedge rd_clk); guard++;
        end
        if (rd_idx < wr_idx)
            note_fail($sformatf("drain incomplete: %0d of %0d beats delivered (C1/liveness)",
                                rd_idx, wr_idx));
        rd_en = 1'b0;
        repeat (8) @(posedge rd_clk);
        if (rd_valid !== 1'b0)
            note_fail("rd_valid still asserted after the FIFO was fully drained (C2/C5)");
        cov_phases++;
    endtask

    // ---------------- main ----------------
    initial begin
        if (DATA_W != 8 && DATA_W != 32 && DATA_W != 64) begin
            $display("TEST_RESULT: FAIL: illegal DATA_W=%0d (legal: 8,32,64)", DATA_W); $finish;
        end
        if (LOG_DEPTH < 2 || LOG_DEPTH > 4) begin
            $display("TEST_RESULT: FAIL: illegal LOG_DEPTH=%0d (legal: 2,3,4)", LOG_DEPTH); $finish;
        end
        if (SYNC_STAGES != 2 && SYNC_STAGES != 3) begin
            $display("TEST_RESULT: FAIL: illegal SYNC_STAGES=%0d (legal: 2,3)", SYNC_STAGES); $finish;
        end

        wr_rst_n = 1'b0; rd_rst_n = 1'b0;
        wr_valid = 1'b0; rd_ready = 1'b0; wr_data = '0;

        //        name                 wr_half rd_half  ww  rw  wrX rdX
        run_phase("A-equal",              5000,   5000,  90, 90,  2,  2);
        run_phase("B-fast-wr-slow-rd",    2000,   9000,  95, 90,  3,  9);
        run_phase("C-slow-wr-fast-rd",    9000,   2000,  90, 95,  9,  3);
        run_phase("D-near-equal-drift",   5000,   5100,  95, 95,  1,  7);
        run_phase("E-odd-ratio",          3000,   7000,  85, 60,  5,  2);
        run_phase("F-wr-burst-rd-slow",   2500,   8000, 100, 25,  4,  6);
        run_phase("G-rd-hungry",          8000,   2500,  35,100,  6,  4);

        phase = "final";
        $display("METRIC: beats_checked=%0d phases=%0d peak_occupancy_estimate=%0d (DEPTH=%0d)",
                 checks, cov_phases, occ_max, DEPTH);
        $display("METRIC: wr_stall_cycles=%0d rd_stall_cycles=%0d", cov_wr_stall, cov_rd_stall);

        begin
            int cov_missing;
            cov_missing = 0;
            $display("// coverage: full=%0d empty=%0d wr_stall=%0d rd_stall=%0d",
                     cov_full, cov_empty, cov_wr_stall, cov_rd_stall);
            $display("// coverage: phases=%0d depth_reached=%0d stagger=%0d",
                     cov_phases, cov_depth_reached, cov_stagger);
            if (cov_full          == 0) begin cov_missing++; $display("// COVERAGE HOLE: FIFO never backpressured the writer"); end
            if (cov_empty         == 0) begin cov_missing++; $display("// COVERAGE HOLE: reader never starved on an empty FIFO"); end
            if (cov_rd_stall      == 0) begin cov_missing++; $display("// COVERAGE HOLE: read side never backpressured"); end
            if (cov_depth_reached == 0) begin cov_missing++; $display("// COVERAGE HOLE: FIFO never approached full occupancy"); end
            if (cov_stagger       == 0) begin cov_missing++; $display("// COVERAGE HOLE: resets never released at staggered times"); end
            if (cov_phases        <  7) begin cov_missing++; $display("// COVERAGE HOLE: only %0d of 7 clock-ratio phases completed", cov_phases); end
            if (cov_missing > 0)
                note_fail($sformatf("%0d coverage holes -- run did not exercise the target hazards",
                                    cov_missing));
        end

        if (checks < MIN_CHECKS)
            note_fail($sformatf("insufficient coverage: only %0d beats checked", checks));

        if (errors == 0) $display("TEST_RESULT: PASS");
        else $display("TEST_RESULT: FAIL: %s (%0d failing checks of %0d)",
                      fail_reason, errors, checks);
        $finish;
    end

    initial begin
        #2_000_000_000;
        $display("// watchdog fired in phase=%s wr_idx=%0d rd_idx=%0d", phase, wr_idx, rd_idx);
        $display("TEST_RESULT: FAIL: timeout -- checker did not complete (phase=%s)", phase);
        $finish;
    end

endmodule
