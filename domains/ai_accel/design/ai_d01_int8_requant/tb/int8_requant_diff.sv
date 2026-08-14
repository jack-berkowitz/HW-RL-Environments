// =============================================================================
// int8_requant_diff.sv -- diff-rate harness. NEVER SHIPPED.
// =============================================================================
// Instantiates the reference and one mutant side by side under IDENTICAL
// stimulus and reports the fraction of observed cycles on which their outputs
// diverge. This is a mutant-quality measurement, not a correctness check: it
// never decides pass or fail.
//
// What the number means, and does not mean: diff rate measures divergence under
// THIS stimulus. It is not the same thing as difficulty for a checker that has
// to detect the divergence. A mutant can diverge rarely and still be trivially
// caught if the divergence lands on an obvious directed vector, and a mutant can
// diverge often and still be missed by a checker that never looks at the right
// signal. Read it as "how much signal is available", not "how hard this is".
//
// Both DUTs receive the same in_valid/out_ready/data. Each computes its own
// in_ready, so a mutant that mishandles backpressure will also diverge in which
// beats it accepts -- that is a real behavioural difference and is counted.
//
// Prints:  DIFF_RATE: <diverging_cycles> / <observed_cycles> = <ppm>
// =============================================================================

`timescale 1ns/1ps

module int8_requant_diff;

    parameter int LANES     = 4;
    parameter int VEC_COUNT = 2060;
    parameter int BEATS     = 4000;

    logic                clk = 1'b0;
    logic                rst_n;
    logic                in_valid, out_ready;
    logic [LANES*32-1:0] acc, mult;
    logic [LANES*5-1:0]  shift;
    logic [LANES*8-1:0]  zp;

    logic                ref_ready, ref_valid;
    logic [LANES*8-1:0]  ref_result;
    logic                mut_ready, mut_valid;
    logic [LANES*8-1:0]  mut_result;

    int8_requant #(.LANES(LANES)) u_ref (
        .clk(clk), .rst_n(rst_n), .in_valid(in_valid), .in_ready(ref_ready),
        .acc(acc), .mult(mult), .shift(shift), .zp(zp),
        .out_valid(ref_valid), .out_ready(out_ready), .result(ref_result));

    int8_requant_mut #(.LANES(LANES)) u_mut (
        .clk(clk), .rst_n(rst_n), .in_valid(in_valid), .in_ready(mut_ready),
        .acc(acc), .mult(mult), .shift(shift), .zp(zp),
        .out_valid(mut_valid), .out_ready(out_ready), .result(mut_result));

    always #5 clk = ~clk;

    logic [31:0] v_acc  [0:VEC_COUNT-1];
    logic [31:0] v_mult [0:VEC_COUNT-1];
    logic [7:0]  v_shift[0:VEC_COUNT-1];
    logic [7:0]  v_zp   [0:VEC_COUNT-1];

    longint observed = 0;
    longint diverged = 0;

    // Compare the full observable output interface, not just the data word: a
    // mutant that corrupts only out_valid or only in_ready is still divergent.
    always_ff @(posedge clk) begin
        if (rst_n) begin
            observed++;
            if ((ref_valid  !== mut_valid) ||
                (ref_ready  !== mut_ready) ||
                (ref_valid && mut_valid && (ref_result !== mut_result)))
                diverged++;
        end
    end

    task automatic stage(input int base);
        for (int L = 0; L < LANES; L++) begin
            int idx; idx = (base + L) % VEC_COUNT;
            acc  [L*32 +: 32] = v_acc  [idx];
            mult [L*32 +: 32] = v_mult [idx];
            shift[L*5  +:  5] = v_shift[idx][4:0];
            zp   [L*8  +:  8] = v_zp   [idx];
        end
    endtask

    initial begin
        $readmemh("tb/vectors/acc.hex",   v_acc);
        $readmemh("tb/vectors/mult.hex",  v_mult);
        $readmemh("tb/vectors/shift.hex", v_shift);
        $readmemh("tb/vectors/zp.hex",    v_zp);

        in_valid = 0; out_ready = 1; rst_n = 0;
        acc = '0; mult = '0; shift = '0; zp = '0;
        repeat (4) begin @(posedge clk); #1; end
        rst_n = 1;
        @(posedge clk); #1;

        // Traffic deliberately mirrors the checker's: full rate, output
        // backpressure, and input gaps, so protocol mutants get the same
        // opportunity to diverge that arithmetic ones do.
        for (int b = 0; b < BEATS; b++) begin
            stage((b * LANES) % VEC_COUNT);
            in_valid  = 1'b1;
            out_ready = ((b % 7) != 0);          // periodic backpressure
            @(posedge clk); #1;
            if ((b % 11) == 10) begin            // periodic input gap
                in_valid = 1'b0;
                @(posedge clk); #1;
            end
            // Periodic mid-stream reset with work in flight. Without this a
            // reset-scoped bug has NO opportunity to diverge and would score a
            // misleading 0 ppm -- the stimulus, not the mutant, would be the
            // reason nothing showed up.
            if ((b % 500) == 499) begin
                in_valid = 1'b0; out_ready = 1'b0;
                @(posedge clk); #1;
                rst_n = 1'b0;
                repeat (2) begin @(posedge clk); #1; end
                rst_n = 1'b1;
                out_ready = 1'b1;
                repeat (2) begin @(posedge clk); #1; end
            end
        end
        in_valid = 0; out_ready = 1;
        repeat (20) begin @(posedge clk); #1; end

        $display("DIFF_RATE: %0d / %0d = %0d ppm", diverged, observed,
                 (observed == 0) ? 64'd0 : (diverged * 64'd1000000) / observed);
        $finish;
    end

    initial begin
        #10_000_000;
        $display("DIFF_RATE: timeout");
        $finish;
    end

endmodule
