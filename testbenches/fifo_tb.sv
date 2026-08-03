// =============================================================================
// fifo_tb.sv -- self-checking testbench for `fifo` (see fifo_iface.sv)
// =============================================================================
// Reference model: a plain software queue (array + head/tail/count integers)
// maintained by the testbench. It is algorithmic bookkeeping, not an RTL
// re-implementation: no clocked always blocks, no pointer-wrap arithmetic that
// mirrors a hardware design, no flag registers.
//
// Every cycle the TB predicts commit/drop from the PRE-EDGE model occupancy,
// advances the model, then compares ALL outputs against the model.
//
// Override parameters at compile time, e.g.
//   iverilog -g2012 -o sim -P fifo_tb.DEPTH=32 -P fifo_tb.DATA_WIDTH=8 \
//            -P fifo_tb.ALMOST_FULL_THRESH=28 -P fifo_tb.ALMOST_EMPTY_THRESH=3 \
//            fifo_tb.sv fifo.sv
//
// Final line is exactly one of:
//   TEST_RESULT: PASS
//   TEST_RESULT: FAIL: <reason>
// =============================================================================

`timescale 1ns/1ps

module fifo_tb;

    // ---------------- configuration ----------------
    parameter int DEPTH               = 16;   // 8 / 16 / 32 / 64
    parameter int DATA_WIDTH          = 32;   // 8 / 16 / 32 / 64
    parameter int ALMOST_FULL_THRESH  = 12;
    parameter int ALMOST_EMPTY_THRESH = 4;
    parameter int RANDOM_VECTORS      = 4000; // >= 1000 required
    parameter int MAX_ERRORS_REPORTED = 20;

    localparam int CNT_W = $clog2(DEPTH) + 1;

    // ---------------- DUT connections ----------------
    logic                  clk = 1'b0;
    logic                  rst_n;
    logic                  wr_en;
    logic [DATA_WIDTH-1:0] wr_data;
    logic                  rd_en;
    logic [DATA_WIDTH-1:0] rd_data;
    logic                  full, empty, almost_full, almost_empty;
    logic [CNT_W-1:0]      count;

    fifo #(
        .DEPTH               (DEPTH),
        .DATA_WIDTH          (DATA_WIDTH),
        .ALMOST_FULL_THRESH  (ALMOST_FULL_THRESH),
        .ALMOST_EMPTY_THRESH (ALMOST_EMPTY_THRESH)
    ) dut (
        .clk (clk), .rst_n (rst_n),
        .wr_en (wr_en), .wr_data (wr_data),
        .rd_en (rd_en), .rd_data (rd_data),
        .full (full), .empty (empty),
        .almost_full (almost_full), .almost_empty (almost_empty),
        .count (count)
    );

    always #5 clk = ~clk;

    // ---------------- bookkeeping ----------------
    int  errors      = 0;
    int  checks      = 0;
    string fail_reason = "";
    string phase       = "init";

    task automatic note_fail(input string why);
        errors++;
        if (fail_reason == "") fail_reason = why;
        if (errors <= MAX_ERRORS_REPORTED)
            $display("[FAIL] t=%0t phase=%s : %s", $time, phase, why);
        else if (errors == MAX_ERRORS_REPORTED + 1)
            $display("[FAIL] ... further failures suppressed");
    endtask

    // ---------------- software reference queue ----------------
    logic [DATA_WIDTH-1:0] q_mem [0:DEPTH-1];
    int q_head;   // index of oldest element
    int q_n;      // number of elements

    function automatic void q_reset();
        q_head = 0;
        q_n    = 0;
    endfunction

    function automatic bit q_full();  return (q_n == DEPTH); endfunction
    function automatic bit q_empty(); return (q_n == 0);     endfunction

    function automatic void q_push(input logic [DATA_WIDTH-1:0] d);
        q_mem[(q_head + q_n) % DEPTH] = d;
        q_n++;
    endfunction

    function automatic void q_pop();
        q_head = (q_head + 1) % DEPTH;
        q_n--;
    endfunction

    function automatic logic [DATA_WIDTH-1:0] q_peek();
        return q_mem[q_head];
    endfunction

    // ---------------- output comparison ----------------
    task automatic check_outputs(input string ctx);
        logic exp_full, exp_empty, exp_af, exp_ae;
        checks++;
        exp_full  = (q_n == DEPTH);
        exp_empty = (q_n == 0);
        exp_af    = (q_n >= ALMOST_FULL_THRESH);
        exp_ae    = (q_n <= ALMOST_EMPTY_THRESH);

        if (count !== CNT_W'(q_n))
            note_fail($sformatf("%s: count=%0d expected %0d", ctx, count, q_n));
        if (full !== exp_full)
            note_fail($sformatf("%s: full=%0b expected %0b (count=%0d)", ctx, full, exp_full, q_n));
        if (empty !== exp_empty)
            note_fail($sformatf("%s: empty=%0b expected %0b (count=%0d)", ctx, empty, exp_empty, q_n));
        if (almost_full !== exp_af)
            note_fail($sformatf("%s: almost_full=%0b expected %0b (count=%0d thresh=%0d)",
                                ctx, almost_full, exp_af, q_n, ALMOST_FULL_THRESH));
        if (almost_empty !== exp_ae)
            note_fail($sformatf("%s: almost_empty=%0b expected %0b (count=%0d thresh=%0d)",
                                ctx, almost_empty, exp_ae, q_n, ALMOST_EMPTY_THRESH));
        // FWFT: head must be visible whenever not empty
        if (!exp_empty && (rd_data !== q_peek()))
            note_fail($sformatf("%s: rd_data=0x%0h expected 0x%0h (FWFT head, count=%0d)",
                                ctx, rd_data, q_peek(), q_n));
    endtask

    // ---------------- one driven cycle ----------------
    // Precondition: called while sitting 1ns after a rising edge, model already
    // synchronised with the DUT. Applies stimulus, advances one edge, predicts,
    // and checks.
    task automatic cycle(input bit w, input logic [DATA_WIDTH-1:0] wd, input bit r);
        bit do_wr, do_rd;
        wr_en   = w;
        wr_data = wd;
        rd_en   = r;
        // prediction uses PRE-EDGE occupancy
        do_wr = w && !q_full();
        do_rd = r && !q_empty();
        @(posedge clk);
        if (do_rd) q_pop();
        if (do_wr) q_push(wd);
        #1;
        check_outputs("cycle");
    endtask

    task automatic idle(input int n);
        for (int i = 0; i < n; i++) cycle(1'b0, '0, 1'b0);
    endtask

    task automatic do_reset();
        wr_en = 0; rd_en = 0; wr_data = '0;
        rst_n = 0;
        repeat (3) @(posedge clk);
        #1;
        q_reset();
        check_outputs("in-reset");
        rst_n = 1;
        @(posedge clk);
        #1;
        check_outputs("post-reset");
    endtask

    // ---------------- stimulus ----------------
    logic [DATA_WIDTH-1:0] d;
    int expect_count;

    initial begin
        // parameter sanity (bad benchmark config, not a DUT failure)
        if (DEPTH != 8 && DEPTH != 16 && DEPTH != 32 && DEPTH != 64) begin
            $display("TEST_RESULT: FAIL: illegal DEPTH=%0d", DEPTH); $finish;
        end
        if (DATA_WIDTH != 8 && DATA_WIDTH != 16 && DATA_WIDTH != 32 && DATA_WIDTH != 64) begin
            $display("TEST_RESULT: FAIL: illegal DATA_WIDTH=%0d", DATA_WIDTH); $finish;
        end
        if (ALMOST_FULL_THRESH < 1 || ALMOST_FULL_THRESH > DEPTH ||
            ALMOST_EMPTY_THRESH < 0 || ALMOST_EMPTY_THRESH > DEPTH-1) begin
            $display("TEST_RESULT: FAIL: illegal thresholds"); $finish;
        end

        // ------------------------------------------------------------------
        // C1: reset behaviour
        // ------------------------------------------------------------------
        phase = "C1-reset";
        do_reset();
        idle(3);

        // ------------------------------------------------------------------
        // C2: single write / single read round trip
        // ------------------------------------------------------------------
        phase = "C2-single";
        cycle(1'b1, DATA_WIDTH'('hA5), 1'b0);
        cycle(1'b0, '0, 1'b0);
        cycle(1'b0, '0, 1'b1);
        idle(2);

        // ------------------------------------------------------------------
        // C3: read while empty is dropped (no underflow)
        // ------------------------------------------------------------------
        phase = "C3-read-empty";
        repeat (5) cycle(1'b0, '0, 1'b1);
        if (count !== 0) note_fail("count moved on read-while-empty");

        // ------------------------------------------------------------------
        // C4: fill to full one word per cycle; threshold sweep on the way up
        // ------------------------------------------------------------------
        phase = "C4-fill";
        for (int i = 0; i < DEPTH; i++)
            cycle(1'b1, DATA_WIDTH'(32'h1000_0000 + i), 1'b0);
        if (!full)  note_fail("full not asserted after DEPTH writes");
        if (empty)  note_fail("empty asserted while full");

        // ------------------------------------------------------------------
        // C5: write while full is dropped, data intact
        // ------------------------------------------------------------------
        phase = "C5-write-full";
        repeat (5) cycle(1'b1, DATA_WIDTH'('hDEAD), 1'b0);
        if (count !== CNT_W'(DEPTH)) note_fail("count changed on write-while-full");

        // ------------------------------------------------------------------
        // C6: simultaneous read+write AT FULL -> read wins, write dropped
        // ------------------------------------------------------------------
        phase = "C6-simul-at-full";
        cycle(1'b1, DATA_WIDTH'('hBEEF), 1'b1);
        if (count !== CNT_W'(DEPTH-1))
            note_fail($sformatf("simul r/w at full: count=%0d expected %0d", count, DEPTH-1));

        // ------------------------------------------------------------------
        // C7: simultaneous read+write mid-level -> count holds, both commit
        // ------------------------------------------------------------------
        phase = "C7-simul-mid";
        expect_count = q_n;
        for (int i = 0; i < DEPTH; i++)
            cycle(1'b1, DATA_WIDTH'(32'h2000_0000 + i), 1'b1);
        if (count !== CNT_W'(expect_count))
            note_fail("simul r/w mid-level changed occupancy");

        // drain fully, verifying order the whole way
        phase = "C7-drain";
        while (q_n > 0) cycle(1'b0, '0, 1'b1);
        if (!empty) note_fail("empty not asserted after full drain");

        // ------------------------------------------------------------------
        // C8: simultaneous read+write AT EMPTY -> write wins, read dropped
        // ------------------------------------------------------------------
        phase = "C8-simul-at-empty";
        cycle(1'b1, DATA_WIDTH'('hC0DE), 1'b1);
        if (count !== 1)
            note_fail($sformatf("simul r/w at empty: count=%0d expected 1", count));
        if (rd_data !== DATA_WIDTH'('hC0DE))
            note_fail("word written at empty was not retained (illegal passthrough?)");
        cycle(1'b0, '0, 1'b1); // clean up

        // ------------------------------------------------------------------
        // C9: exact threshold boundaries -- sweep occupancy 0..DEPTH and back
        // ------------------------------------------------------------------
        phase = "C9-thresholds";
        for (int i = 0; i < DEPTH; i++) begin
            cycle(1'b1, DATA_WIDTH'(i), 1'b0);
            if (almost_full !== ((i+1) >= ALMOST_FULL_THRESH))
                note_fail($sformatf("almost_full wrong at count=%0d", i+1));
            if (almost_empty !== ((i+1) <= ALMOST_EMPTY_THRESH))
                note_fail($sformatf("almost_empty wrong at count=%0d", i+1));
        end
        for (int i = DEPTH; i > 0; i--) begin
            cycle(1'b0, '0, 1'b1);
            if (almost_full !== ((i-1) >= ALMOST_FULL_THRESH))
                note_fail($sformatf("almost_full wrong at count=%0d (down)", i-1));
            if (almost_empty !== ((i-1) <= ALMOST_EMPTY_THRESH))
                note_fail($sformatf("almost_empty wrong at count=%0d (down)", i-1));
        end

        // ------------------------------------------------------------------
        // C10: back-to-back wraparound -- fill/drain 4x, then sustained
        //      concurrent r/w at half-occupancy for 6*DEPTH cycles so the
        //      pointers wrap many times.
        // ------------------------------------------------------------------
        phase = "C10-wrap";
        for (int rep = 0; rep < 4; rep++) begin
            for (int i = 0; i < DEPTH; i++)
                cycle(1'b1, DATA_WIDTH'(32'h5A00_0000 + rep*DEPTH + i), 1'b0);
            for (int i = 0; i < DEPTH; i++)
                cycle(1'b0, '0, 1'b1);
        end
        // half-fill then stream
        for (int i = 0; i < DEPTH/2; i++)
            cycle(1'b1, DATA_WIDTH'(32'h7000_0000 + i), 1'b0);
        for (int i = 0; i < 6*DEPTH; i++)
            cycle(1'b1, DATA_WIDTH'(32'h8000_0000 + i), 1'b1);
        while (q_n > 0) cycle(1'b0, '0, 1'b1);

        // ------------------------------------------------------------------
        // C11: back-to-back single-cycle push/pop alternation from empty
        // ------------------------------------------------------------------
        phase = "C11-alternate";
        for (int i = 0; i < 4*DEPTH; i++) begin
            cycle(1'b1, DATA_WIDTH'(32'h9000_0000 + i), 1'b0);
            cycle(1'b0, '0, 1'b1);
        end

        // ------------------------------------------------------------------
        // C12: reset asserted mid-traffic must flush
        // ------------------------------------------------------------------
        phase = "C12-reset-midstream";
        for (int i = 0; i < DEPTH/2; i++)
            cycle(1'b1, DATA_WIDTH'(32'hAA00_0000 + i), 1'b0);
        // reset while a write and a read are both being presented
        wr_en = 1; rd_en = 1; wr_data = DATA_WIDTH'('h1234);
        rst_n = 0;
        @(posedge clk);
        #1;
        q_reset();
        check_outputs("reset-midstream");
        wr_en = 0; rd_en = 0;
        rst_n = 1;
        @(posedge clk); #1;
        check_outputs("post-reset-midstream");
        // and it must work normally afterwards
        for (int i = 0; i < DEPTH; i++)
            cycle(1'b1, DATA_WIDTH'(32'hBB00_0000 + i), 1'b0);
        while (q_n > 0) cycle(1'b0, '0, 1'b1);

        // ------------------------------------------------------------------
        // R1: constrained-random regression
        //     Weighted so that the FIFO spends real time pinned at full and at
        //     empty (where the interesting arbitration lives) rather than
        //     hovering mid-occupancy.
        // ------------------------------------------------------------------
        phase = "R1-random";
        begin
            int w_wr, w_rd;
            bit rw, rr;
            for (int v = 0; v < RANDOM_VECTORS; v++) begin
                // every 200 vectors, re-bias the traffic pattern
                case ((v / 200) % 4)
                    0: begin w_wr = 85; w_rd = 15; end // write-heavy -> sits full
                    1: begin w_wr = 15; w_rd = 85; end // read-heavy  -> sits empty
                    2: begin w_wr = 50; w_rd = 50; end // balanced
                    3: begin w_wr = 90; w_rd = 90; end // both hot -> simultaneous r/w
                endcase
                rw = ($urandom_range(0,99) < w_wr);
                rr = ($urandom_range(0,99) < w_rd);
                d  = DATA_WIDTH'($urandom());
                // sprinkle in boundary data patterns
                case ($urandom_range(0,9))
                    0: d = '0;
                    1: d = '1;
                    2: d = {(DATA_WIDTH/2){2'b01}};
                    3: d = {(DATA_WIDTH/2){2'b10}};
                    default: ;
                endcase
                cycle(rw, d, rr);
                // occasional asynchronous-ish reset injection
                if ($urandom_range(0, 999) == 0) begin
                    wr_en = 0; rd_en = 0;
                    rst_n = 0; @(posedge clk); #1;
                    q_reset(); check_outputs("random-reset");
                    rst_n = 1; @(posedge clk); #1;
                    check_outputs("random-post-reset");
                end
            end
        end

        // ------------------------------------------------------------------
        phase = "final";
        idle(4);

        if (checks < 1000)
            note_fail($sformatf("insufficient coverage: only %0d checks executed", checks));

        if (errors == 0)
            $display("TEST_RESULT: PASS");
        else
            $display("TEST_RESULT: FAIL: %s (%0d failing checks of %0d)",
                     fail_reason, errors, checks);
        $finish;
    end

    // global watchdog
    initial begin
        #20_000_000;
        $display("TEST_RESULT: FAIL: timeout -- testbench did not complete");
        $finish;
    end

endmodule
