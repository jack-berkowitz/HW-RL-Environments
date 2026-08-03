// =============================================================================
// multiplier_tb.sv -- self-checking TB for `multiplier` (see multiplier_iface.sv)
// =============================================================================
// Reference model: the expected product is computed arithmetically in the
// testbench from the magnitudes of the operands (sign is stripped, magnitudes
// are multiplied, the sign is reapplied by two's complement negation). This is
// plain integer math, not a second RTL multiplier.
//
// The TB also enforces the handshake contract: one-cycle done pulse, busy
// shape, latency bound, operand capture at the accepting edge (operands are
// deliberately scrambled afterwards), start-while-busy ignored, and product
// hold between transactions.
//
// Override parameters at compile time, e.g.
//   iverilog -g2012 -o sim -P multiplier_tb.BIT_WIDTH=32 \
//            -P multiplier_tb.SIGNED_MODE=0 multiplier_tb.sv multiplier.sv
//
// Final line is exactly one of:
//   TEST_RESULT: PASS
//   TEST_RESULT: FAIL: <reason>
// =============================================================================

`timescale 1ns/1ps

module multiplier_tb;

    // ---------------- configuration ----------------
    parameter int BIT_WIDTH           = 16;   // 8 / 16 / 32
    parameter int SIGNED_MODE         = 1;    // 0 = unsigned, 1 = signed
    parameter int RANDOM_VECTORS      = 3000; // >= 1000 required
    parameter int MAX_ERRORS_REPORTED = 20;

    localparam int PROD_W    = 2*BIT_WIDTH;
    localparam int MAX_LAT   = 4*BIT_WIDTH + 8;

    // ---------------- DUT connections ----------------
    logic                 clk = 1'b0;
    logic                 rst_n;
    logic                 start;
    logic [BIT_WIDTH-1:0] a, b;
    logic                 busy, done;
    logic [PROD_W-1:0]    product;

    multiplier #(
        .BIT_WIDTH   (BIT_WIDTH),
        .SIGNED_MODE (SIGNED_MODE)
    ) dut (
        .clk (clk), .rst_n (rst_n),
        .start (start), .a (a), .b (b),
        .busy (busy), .done (done), .product (product)
    );

    always #5 clk = ~clk;

    // ---------------- bookkeeping ----------------
    int    errors = 0;
    int    checks = 0;
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

    // =========================================================================
    // Reference: magnitude multiply + sign reapplication.
    // =========================================================================
    function automatic logic [PROD_W-1:0] ref_product(input logic [BIT_WIDTH-1:0] av,
                                                      input logic [BIT_WIDTH-1:0] bv);
        logic [BIT_WIDTH-1:0] ma, mb;
        logic                 sa, sb, neg;
        logic [PROD_W-1:0]    mag;
        if (SIGNED_MODE == 0) begin
            // unsigned: widen both operands with zeros and multiply
            return ({{BIT_WIDTH{1'b0}}, av} * {{BIT_WIDTH{1'b0}}, bv});
        end else begin
            sa = av[BIT_WIDTH-1];
            sb = bv[BIT_WIDTH-1];
            // Magnitude via two's complement negation. This is exact for every
            // input including the most-negative value: there ~av+1 == av, whose
            // UNSIGNED reading is 2^(BIT_WIDTH-1) == |min|.
            ma = sa ? (~av + 1'b1) : av;
            mb = sb ? (~bv + 1'b1) : bv;
            // zero-extend the magnitudes, then multiply as unsigned
            mag = {{BIT_WIDTH{1'b0}}, ma} * {{BIT_WIDTH{1'b0}}, mb};
            neg = sa ^ sb;
            return neg ? (~mag + 1'b1) : mag;
        end
    endfunction

    // human-readable operand rendering for messages
    function automatic longint ref_as_int(input logic [BIT_WIDTH-1:0] v);
        if (SIGNED_MODE == 1 && v[BIT_WIDTH-1])
            return -longint'({{(64-BIT_WIDTH){1'b0}}, (~v + 1'b1)});
        else
            return longint'({{(64-BIT_WIDTH){1'b0}}, v});
    endfunction

    // =========================================================================
    // Transaction driver + handshake checker
    // =========================================================================
    int  lat_min = 1<<30;
    int  lat_max = 0;

    task automatic do_transaction(input logic [BIT_WIDTH-1:0] av,
                                  input logic [BIT_WIDTH-1:0] bv);
        logic [PROD_W-1:0] exp;
        int                lat;
        bit                finished;
        exp = ref_product(av, bv);
        checks++;

        // wait until the DUT is idle
        lat = 0;
        while (busy === 1'b1) begin
            @(posedge clk); #1;
            lat++;
            if (lat > MAX_LAT + 4) begin
                note_fail("busy never deasserted before a new transaction");
                return;
            end
        end

        // cycle 0: present start + operands
        start = 1'b1;
        a = av; b = bv;
        #1;
        if (done === 1'b1)
            note_fail("done asserted in the accepting cycle (latency must be >= 1)");
        @(posedge clk);
        #1; // drive strictly after the sampling edge -- never at it
        // operands must have been captured by now -- scramble them
        start = 1'b0;
        a = BIT_WIDTH'($urandom());
        b = BIT_WIDTH'($urandom());

        // cycles 1..L
        lat      = 1;
        finished = 1'b0;
        while (!finished) begin
            if (done === 1'b1) begin
                finished = 1'b1;
                if (busy !== 1'b1)
                    note_fail("busy must still be 1 in the cycle done is asserted");
                if (product !== exp)
                    note_fail($sformatf("%0d * %0d : product=0x%0h expected 0x%0h",
                                        ref_as_int(av), ref_as_int(bv), product, exp));
                if (lat < lat_min) lat_min = lat;
                if (lat > lat_max) lat_max = lat;
            end else begin
                if (busy !== 1'b1)
                    note_fail($sformatf("busy deasserted at cycle %0d before done", lat));
                // start while busy must be ignored
                if (lat == 1) begin
                    start = 1'b1;
                    a = ~av; b = ~bv;
                end else if (lat == 2) begin
                    start = 1'b0;
                    a = BIT_WIDTH'($urandom());
                    b = BIT_WIDTH'($urandom());
                end
                if (lat > MAX_LAT) begin
                    note_fail($sformatf("no done within %0d cycles (latency bound)", MAX_LAT));
                    return;
                end
                @(posedge clk); #1;
                lat++;
            end
        end

        // cycle L+1: done must have dropped, busy must be clear, product held
        @(posedge clk); #1;
        if (done !== 1'b0)
            note_fail("done was high for more than one cycle");
        if (busy !== 1'b0)
            note_fail("busy still asserted the cycle after done");
        if (product !== exp)
            note_fail("product not held stable after done");
        start = 1'b0;
    endtask

    task automatic do_reset();
        start = 1'b0; a = '0; b = '0;
        rst_n = 1'b0;
        repeat (3) @(posedge clk);
        #1;
        if (busy !== 1'b0) note_fail("busy not 0 during reset");
        if (done !== 1'b0) note_fail("done not 0 during reset");
        rst_n = 1'b1;
        @(posedge clk); #1;
        if (busy !== 1'b0) note_fail("busy not 0 after reset");
        if (done !== 1'b0) note_fail("done not 0 after reset");
    endtask

    // ---------------- corner operand set ----------------
    localparam int NCORNER = 14;
    logic [BIT_WIDTH-1:0] corner [0:NCORNER-1];

    function automatic void build_corners();
        corner[0]  = '0;                                        // 0
        corner[1]  = BIT_WIDTH'(1);                             // 1
        corner[2]  = BIT_WIDTH'(2);                             // 2
        corner[3]  = BIT_WIDTH'(3);
        corner[4]  = '1;                                        // all ones (-1 signed)
        corner[5]  = {1'b0, {(BIT_WIDTH-1){1'b1}}};             // signed max / 2^(W-1)-1
        corner[6]  = {1'b1, {(BIT_WIDTH-1){1'b0}}};             // signed min / 2^(W-1)
        corner[7]  = {1'b1, {(BIT_WIDTH-2){1'b0}}, 1'b1};       // min+1
        corner[8]  = {{(BIT_WIDTH-1){1'b1}}, 1'b0};             // -2 signed / max-1
        corner[9]  = BIT_WIDTH'(1) << (BIT_WIDTH/2);            // sqrt-ish power of two
        corner[10] = (BIT_WIDTH'(1) << (BIT_WIDTH/2)) - 1'b1;   // low half ones
        corner[11] = {(BIT_WIDTH/2){2'b01}};                    // 0x5555...
        corner[12] = {(BIT_WIDTH/2){2'b10}};                    // 0xAAAA...
        corner[13] = BIT_WIDTH'(1) << (BIT_WIDTH-2);            // 2^(W-2)
    endfunction

    // ---------------- stimulus ----------------
    logic [BIT_WIDTH-1:0] ra, rb;

    initial begin
        if (BIT_WIDTH != 8 && BIT_WIDTH != 16 && BIT_WIDTH != 32) begin
            $display("TEST_RESULT: FAIL: illegal BIT_WIDTH=%0d", BIT_WIDTH); $finish;
        end
        if (SIGNED_MODE != 0 && SIGNED_MODE != 1) begin
            $display("TEST_RESULT: FAIL: illegal SIGNED_MODE=%0d", SIGNED_MODE); $finish;
        end

        build_corners();
        do_reset();

        // ------------------------------------------------------------------
        // C1: zero and identity
        // ------------------------------------------------------------------
        phase = "C1-zero-identity";
        do_transaction('0, '0);
        do_transaction('0, '1);
        do_transaction('1, '0);
        do_transaction(BIT_WIDTH'(1), BIT_WIDTH'(1));
        for (int i = 0; i < NCORNER; i++) begin
            do_transaction('0, corner[i]);
            do_transaction(corner[i], '0);
            do_transaction(BIT_WIDTH'(1), corner[i]);
            do_transaction(corner[i], BIT_WIDTH'(1));
        end

        // ------------------------------------------------------------------
        // C2: full cross product of all corner operands (both orders)
        //     Covers, for SIGNED_MODE==1: min*min, min*(-1), min*max,
        //     (-1)*(-1), max*max, and every sign quadrant.
        // ------------------------------------------------------------------
        phase = "C2-corner-cross";
        for (int i = 0; i < NCORNER; i++)
            for (int j = 0; j < NCORNER; j++)
                do_transaction(corner[i], corner[j]);

        // ------------------------------------------------------------------
        // C3: named extreme cases, checked with explicit expectations
        // ------------------------------------------------------------------
        phase = "C3-extremes";
        if (SIGNED_MODE == 1) begin
            // min * min = +2^(2W-2)
            do_transaction({1'b1, {(BIT_WIDTH-1){1'b0}}}, {1'b1, {(BIT_WIDTH-1){1'b0}}});
            if (product !== (PROD_W'(1) << (PROD_W-2)))
                note_fail("signed min*min != 2^(2W-2)");
            // min * -1 = +2^(W-1)
            do_transaction({1'b1, {(BIT_WIDTH-1){1'b0}}}, '1);
            if (product !== (PROD_W'(1) << (BIT_WIDTH-1)))
                note_fail("signed min*(-1) != 2^(W-1)");
            // -1 * -1 = 1
            do_transaction('1, '1);
            if (product !== PROD_W'(1))
                note_fail("signed (-1)*(-1) != 1");
            // max * max
            do_transaction({1'b0, {(BIT_WIDTH-1){1'b1}}}, {1'b0, {(BIT_WIDTH-1){1'b1}}});
        end else begin
            // max * max = 2^2W - 2^(W+1) + 1
            do_transaction('1, '1);
            if (product !== ('1 - (PROD_W'(1) << (BIT_WIDTH+1)) + PROD_W'(2)))
                note_fail("unsigned max*max incorrect");
        end

        // ------------------------------------------------------------------
        // C4: powers of two (single-bit operands) -- exact shift results
        // ------------------------------------------------------------------
        phase = "C4-powers-of-two";
        for (int i = 0; i < BIT_WIDTH; i++)
            for (int j = 0; j < BIT_WIDTH; j += (BIT_WIDTH > 8 ? 3 : 1))
                do_transaction(BIT_WIDTH'(1) << i, BIT_WIDTH'(1) << j);

        // ------------------------------------------------------------------
        // C5: back-to-back transactions with no idle cycle between them
        // ------------------------------------------------------------------
        phase = "C5-back-to-back";
        for (int i = 0; i < 64; i++)
            do_transaction(BIT_WIDTH'($urandom()), BIT_WIDTH'($urandom()));

        // ------------------------------------------------------------------
        // C6: reset in the middle of an in-flight multiply
        // ------------------------------------------------------------------
        phase = "C6-reset-inflight";
        start = 1'b1; a = '1; b = '1;
        @(posedge clk); #1;
        start = 1'b0;
        @(posedge clk); #1;
        rst_n = 1'b0;
        repeat (2) @(posedge clk); #1;
        if (busy !== 1'b0) note_fail("reset did not clear busy");
        if (done !== 1'b0) note_fail("reset did not clear done");
        rst_n = 1'b1;
        @(posedge clk); #1;
        do_transaction(BIT_WIDTH'(7), BIT_WIDTH'(9));

        // ------------------------------------------------------------------
        // C7: exhaustive operand space for BIT_WIDTH == 8
        // ------------------------------------------------------------------
        if (BIT_WIDTH == 8) begin
            phase = "C7-exhaustive-8bit";
            for (int i = 0; i < 256; i++)
                for (int j = 0; j < 256; j++)
                    do_transaction(BIT_WIDTH'(i), BIT_WIDTH'(j));
        end

        // ------------------------------------------------------------------
        // R1: constrained-random regression
        // ------------------------------------------------------------------
        phase = "R1-random";
        for (int v = 0; v < RANDOM_VECTORS; v++) begin
            case ((v / 300) % 5)
                0: begin // uniform full range
                    ra = BIT_WIDTH'($urandom()); rb = BIT_WIDTH'($urandom());
                end
                1: begin // small magnitudes (sign-flip sensitive)
                    ra = BIT_WIDTH'($urandom_range(0, 15));
                    rb = BIT_WIDTH'($urandom_range(0, 15));
                    if (SIGNED_MODE == 1 && $urandom_range(0,1)) ra = ~ra + 1'b1;
                    if (SIGNED_MODE == 1 && $urandom_range(0,1)) rb = ~rb + 1'b1;
                end
                2: begin // near the extremes
                    ra = {1'b1, {(BIT_WIDTH-1){1'b0}}} + BIT_WIDTH'($urandom_range(0,3));
                    rb = {1'b0, {(BIT_WIDTH-1){1'b1}}} - BIT_WIDTH'($urandom_range(0,3));
                end
                3: begin // one corner, one random
                    ra = corner[$urandom_range(0, NCORNER-1)];
                    rb = BIT_WIDTH'($urandom());
                end
                4: begin // sparse bit patterns
                    ra = BIT_WIDTH'($urandom()) & BIT_WIDTH'($urandom());
                    rb = BIT_WIDTH'($urandom()) & BIT_WIDTH'($urandom());
                end
            endcase
            do_transaction(ra, rb);
        end

        // ------------------------------------------------------------------
        phase = "final";
        if (checks < 1000)
            note_fail($sformatf("insufficient coverage: only %0d transactions", checks));

        if (errors == 0) begin
            $display("// info: %0d transactions, latency observed %0d..%0d cycles",
                     checks, lat_min, lat_max);
            $display("TEST_RESULT: PASS");
        end else
            $display("TEST_RESULT: FAIL: %s (%0d failing checks of %0d)",
                     fail_reason, errors, checks);
        $finish;
    end

    initial begin
        #2_000_000_000;
        $display("TEST_RESULT: FAIL: timeout -- testbench did not complete");
        $finish;
    end

endmodule
