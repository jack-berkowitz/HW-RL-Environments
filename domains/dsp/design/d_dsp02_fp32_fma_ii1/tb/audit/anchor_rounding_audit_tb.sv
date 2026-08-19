// Drives the d_dsp02 anchor with externally supplied vectors and prints what it
// produces. IT DOES NOT KNOW THE EXPECTED VALUES -- comparison happens in
// Python against an independently computed oracle. If this file carried the
// expected values it would be the same inversion the audit exists to break.
`timescale 1ns/1ps

module fma_audit_tb;

    logic        clk = 0, rst_n = 0;
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
        .flag_underflow(flag_underflow), .flag_inexact(flag_inexact)
    );

    integer fd, code, n;
    logic [31:0] va, vb, vc;
    integer      vm;

    initial begin
        in_valid = 0; out_ready = 1; a = 0; b = 0; c = 0; rnd_mode = 0;
        repeat (4) @(posedge clk);
        rst_n = 1;
        repeat (2) @(posedge clk);

        fd = $fopen("vectors.txt", "r");
        if (fd == 0) begin $display("CANNOT OPEN vectors.txt"); $finish; end

        n = 0;
        while (!$feof(fd)) begin
            code = $fscanf(fd, "%h %h %h %d\n", va, vb, vc, vm);
            if (code != 4) disable_loop: break;

            @(negedge clk);
            a = va; b = vb; c = vc; rnd_mode = vm[2:0]; in_valid = 1;
            // wait for the accept
            do @(posedge clk); while (!in_ready);
            @(negedge clk); in_valid = 0;

            // wait for the result
            while (!out_valid) @(posedge clk);
            $display("DUTOUT %08h %0d %0d %0d %0d",
                     result, flag_inexact, flag_overflow, flag_underflow,
                     flag_invalid);
            @(posedge clk);
            n = n + 1;
        end
        $fclose(fd);
        $display("DUTDONE %0d", n);
        $finish;
    end

    initial begin
        #2000000;
        $display("TIMEOUT");
        $finish;
    end

endmodule
