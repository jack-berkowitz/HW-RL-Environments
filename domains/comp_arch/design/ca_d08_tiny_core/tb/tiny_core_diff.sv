// =============================================================================
// tiny_core_diff.sv -- diff-rate harness. NEVER SHIPPED.
// =============================================================================
// Reference and mutant run the SAME program from identical initial state, each
// with its own data memory (a divergent store must not corrupt the other core).
// Reports the fraction of active cycles on which their observable interfaces
// differ.
//
// Mutant-quality measurement only; it never decides pass or fail. Diff rate
// measures divergence UNDER THIS STIMULUS and is NOT the same thing as
// difficulty for a checker that has to detect it -- read it as "how much signal
// is available", not "how hard this is".
//
// Prints:  DIFF_RATE: <diverging> / <observed> = <ppm>
// =============================================================================

`timescale 1ns/1ps

module tiny_core_diff;

    parameter int IMEM_AW = 10;
    parameter int DMEM_AW = 10;
    parameter int NUM_PROGS = 20;
    parameter int CYCLES_PER_PROG = 900;

    localparam int IW = 1 << IMEM_AW;
    localparam int DW = 1 << DMEM_AW;

    logic clk = 1'b0, rst_n;
    always #5 clk = ~clk;

    logic [31:0] imem [0:IW-1];
    logic [31:0] dmem_a [0:DW-1];
    logic [31:0] dmem_b [0:DW-1];

    // --- reference ---
    logic [31:0] a_ia, a_da, a_dw, a_rpc, a_rv2, a_rsa, a_rsd;
    logic        a_dq, a_dwe, a_rv, a_rst;
    logic [4:0]  a_rd;
    tiny_core #(.IMEM_AW(IMEM_AW), .DMEM_AW(DMEM_AW)) u_ref (
        .clk(clk), .rst_n(rst_n), .imem_addr(a_ia), .imem_rdata(imem[a_ia[IMEM_AW+1:2]]),
        .dmem_req(a_dq), .dmem_we(a_dwe), .dmem_addr(a_da), .dmem_wdata(a_dw),
        .dmem_rdata(dmem_a[a_da[DMEM_AW+1:2]]),
        .retire_valid(a_rv), .retire_pc(a_rpc), .retire_rd(a_rd), .retire_rd_val(a_rv2),
        .retire_is_store(a_rst), .retire_store_addr(a_rsa), .retire_store_data(a_rsd));

    // --- mutant ---
    logic [31:0] b_ia, b_da, b_dw, b_rpc, b_rv2, b_rsa, b_rsd;
    logic        b_dq, b_dwe, b_rv, b_rst;
    logic [4:0]  b_rd;
    tiny_core_mut #(.IMEM_AW(IMEM_AW), .DMEM_AW(DMEM_AW)) u_mut (
        .clk(clk), .rst_n(rst_n), .imem_addr(b_ia), .imem_rdata(imem[b_ia[IMEM_AW+1:2]]),
        .dmem_req(b_dq), .dmem_we(b_dwe), .dmem_addr(b_da), .dmem_wdata(b_dw),
        .dmem_rdata(dmem_b[b_da[DMEM_AW+1:2]]),
        .retire_valid(b_rv), .retire_pc(b_rpc), .retire_rd(b_rd), .retire_rd_val(b_rv2),
        .retire_is_store(b_rst), .retire_store_addr(b_rsa), .retire_store_data(b_rsd));

    always_ff @(posedge clk) begin
        if (rst_n && a_dq && a_dwe) dmem_a[a_da[DMEM_AW+1:2]] <= a_dw;
        if (rst_n && b_dq && b_dwe) dmem_b[b_da[DMEM_AW+1:2]] <= b_dw;
    end

    longint observed = 0, diverged = 0;

    always_ff @(posedge clk) begin
        if (rst_n) begin
            observed++;
            if ((a_rv !== b_rv) ||
                (a_rv && b_rv && ((a_rpc !== b_rpc) || (a_rd !== b_rd) ||
                                  (a_rv2 !== b_rv2) || (a_rst !== b_rst) ||
                                  (a_rst && ((a_rsa !== b_rsa) || (a_rsd !== b_rsd))))))
                diverged++;
        end
    end

    int p;
    initial begin
        for (p = 0; p < NUM_PROGS; p++) begin
            rst_n = 1'b0;
            for (int i = 0; i < IW; i++) imem[i] = 32'd0;
            for (int i = 0; i < DW; i++) begin dmem_a[i] = 32'd0; dmem_b[i] = 32'd0; end
            $readmemh($sformatf("tb/vectors/prog%02d.hex", p), imem);
            repeat (4) begin @(posedge clk); #1; end
            rst_n = 1'b1;
            repeat (CYCLES_PER_PROG) begin @(posedge clk); #1; end
        end
        rst_n = 1'b0;
        $display("DIFF_RATE: %0d / %0d = %0d ppm", diverged, observed,
                 (observed == 0) ? 64'd0 : (diverged * 64'd1000000) / observed);
        $finish;
    end

    initial begin
        #60_000_000;
        $display("DIFF_RATE: timeout");
        $finish;
    end

endmodule
