// =============================================================================
// capture_vectors_tb.sv -- runs the generated INPUTS through the VENDORED ANCHOR
// and writes the vector file the checker will use. NEVER SHIPPED.
// =============================================================================
// THE ANCHOR IS THE ORACLE. This harness is the only thing that produces
// expected values, and it produces them by running externally-authored RTL that
// nobody on this project wrote.
//
// The alternative -- a local model computing expected values, cross-checked
// against the anchor -- leaves a hole: a shared misconception survives the
// cross-check because both sides agree for the same wrong reason. See NOTES.md
// for a worked example from this very task.
//
// Reads  : vectors/inputs.hex   {a, b, c, rnd}                      99 bits
// Writes : vectors/vectors.hex  {a, b, c, rnd, result, flags}      136 bits
//
// The flags order is fixed by the shipped spec, NOT by the anchor's struct
// layout: {NV, OF, UF, NX} with DZ dropped, since an FMA cannot divide by zero.
// =============================================================================

`timescale 1ns/1ps

module capture_vectors_tb;
    import fpnew_pkg::*;

    localparam int MAXV = 20000;
    localparam string IN_FILE  = "vectors/inputs.hex";
    localparam string OUT_FILE = "vectors/vectors.hex";

    logic clk = 1'b0, rst_n = 1'b0;
    always #5 clk = ~clk;

    logic [98:0] inputs [0:MAXV-1];
    int n_vec = 0;

    logic [2:0][31:0] ops;
    roundmode_e       rnd;
    logic [31:0]      result;
    status_t          status;

    fpnew_fma #(.FpFormat(FP32), .NumPipeRegs(0)) u_anchor (
        .clk_i(clk), .rst_ni(rst_n),
        .operands_i(ops), .is_boxed_i(3'b111), .rnd_mode_i(rnd),
        .op_i(FMADD), .op_mod_i(1'b0), .tag_i(1'b0), .mask_i(1'b1), .aux_i(1'b0),
        .in_valid_i(1'b1), .in_ready_o(), .flush_i(1'b0),
        .result_o(result), .status_o(status), .extension_bit_o(), .tag_o(),
        .mask_o(), .aux_o(), .out_valid_o(), .out_ready_i(1'b1), .busy_o());

    // The five IEEE modes only. ROD, RSR and DYN are out of scope for this task
    // and are never generated; if one appears the run stops rather than
    // silently capturing behaviour the spec does not define.
    function automatic roundmode_e decode_rnd(input logic [2:0] r);
        case (r)
            3'd0: return RNE;
            3'd1: return RTZ;
            3'd2: return RDN;
            3'd3: return RUP;
            3'd4: return RMM;
            default: begin
                $display("FATAL: rounding mode %0d is out of scope for this task", r);
                $finish;
                return RNE;
            end
        endcase
    endfunction

    int fd;
    initial begin
        for (int i = 0; i < MAXV; i++) inputs[i] = '0;
        $readmemh(IN_FILE, inputs);
        for (int i = 0; i < MAXV; i++) if (inputs[i] !== '0) n_vec = i + 1;

        rst_n = 1'b0;
        repeat (4) @(posedge clk);
        rst_n = 1'b1;

        fd = $fopen(OUT_FILE, "w");
        if (fd == 0) begin
            $display("FATAL: cannot open %s for writing", OUT_FILE);
            $finish;
        end

        for (int i = 0; i < n_vec; i++) begin
            ops[0] = inputs[i][98:67];
            ops[1] = inputs[i][66:35];
            ops[2] = inputs[i][34:3];
            rnd    = decode_rnd(inputs[i][2:0]);
            #1;   // combinational at NumPipeRegs=0
            // {a, b, c, rnd, result, NV, OF, UF, NX}
            $fwrite(fd, "%08h%08h%08h%01h%08h%01h\n",
                    ops[0], ops[1], ops[2], inputs[i][2:0], result,
                    {status.NV, status.OF, status.UF, status.NX});
        end
        $fclose(fd);
        $display("METRIC: captured=%0d vectors from the anchor", n_vec);
        $display("TEST_RESULT: PASS");
        $finish;
    end
endmodule
