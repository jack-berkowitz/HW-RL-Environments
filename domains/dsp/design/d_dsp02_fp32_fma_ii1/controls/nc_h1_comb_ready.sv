// nc_h1_comb_ready -- d_dsp02 NEGATIVE CONTROL for H1. Never shipped.
//
// H1 says: `in_ready` MUST NOT depend combinationally on `in_valid`. This gates
// in_ready with in_valid and is otherwise the reference verbatim.
//
// WHY IT EXISTS. H1 appeared ZERO times in this task's checker and the whole
// testbench contained exactly one sub-cycle delay, the timeout. Nothing could
// observe the combinational path, and nothing else catches it either: a
// transfer still happens exactly when valid and ready are both high, so every
// vector, flag, latency and II=1 check passes unchanged. It is invisible to
// every check that looks at WHAT was delivered rather than WHEN.
//
// The same clause had the same gap on d_nw01, closed with a mid-cycle probe and
// validated by nc_l_comb_ready. This is that control, carried across.
//
// PREDICTION: every configuration SHOULD FAIL in phase H1, naming H1, on
// in_ready. If it passes, the probe is not observing the combinational path.
//
// POLARITY: NO CROSSOVER. The violation is structural.
`timescale 1ns/1ps

// =============================================================================
// fp32_fma_ii1_ref.sv -- REFERENCE SHIM for d_dsp02. NEVER SHIPPED.
// =============================================================================
// Binds the vendored PULP cvfpu `fpnew_fma` to the flat interface the spec
// ships. Renaming and enum mapping only -- no arithmetic, no buffering, no
// handshake logic of its own.
//
// CONFIGURATION CHOICES THIS SHIM MAKES, recorded because they are NOT part of
// the contract and a candidate never had to compete with them:
//
//   FpFormat    = FP32          fixed by the task
//   NumPipeRegs = 3             PINNED BY SPEC S1 (rule 18). Was 0; a
//                               combinational FMA misses timing at 30 ns and
//                               no submission would ship it, so a baseline
//                               there measured nothing.
//                               the spec does not constrain latency. Zero is
//                               the SPEC-MINIMAL choice: it adds nothing the
//                               contract does not ask for. Compare d_nw01,
//                               where a shim bound CUT_ALL_AX and handed the
//                               reference 45% of its area in pipelining the
//                               spec never required.
//   PipeConfig  = DISTRIBUTED   spreads the three boundaries across the four
//                               dataflow segments. S1a leaves placement free,
//                               so this is the reference's choice, not a
//                               requirement.
//
// The rounding-mode mapping is the one non-trivial part: the spec defines FIVE
// modes with a fixed encoding, the anchor's enum defines eight. Modes 5-7 are
// out of scope, are never driven, and map to RNE here purely so the case is
// total -- not because the spec assigns them meaning.
// =============================================================================

`timescale 1ns/1ps

module fp32_fma_ii1_h1_inner (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        in_valid,
    output logic        in_ready,
    input  logic [31:0] a,
    input  logic [31:0] b,
    input  logic [31:0] c,
    input  logic [2:0]  rnd_mode,
    output logic        out_valid,
    input  logic        out_ready,
    output logic [31:0] result,
    output logic        flag_invalid,
    output logic        flag_overflow,
    output logic        flag_underflow,
    output logic        flag_inexact
);

    fpnew_pkg::roundmode_e rnd_e;
    always_comb begin
        case (rnd_mode)
            3'd0:    rnd_e = fpnew_pkg::RNE;
            3'd1:    rnd_e = fpnew_pkg::RTZ;
            3'd2:    rnd_e = fpnew_pkg::RDN;
            3'd3:    rnd_e = fpnew_pkg::RUP;
            3'd4:    rnd_e = fpnew_pkg::RMM;
            default: rnd_e = fpnew_pkg::RNE;   // 5-7 out of scope, never driven
        endcase
    end

    logic [2:0][31:0]     operands;
    fpnew_pkg::status_t   status;
    assign operands = {c, b, a};    // upstream order is {operand_c, operand_b, operand_a}

    fpnew_fma #(
        .FpFormat    ( fpnew_pkg::FP32 ),
        .NumPipeRegs ( 3               ),   // S1: the SCORED configuration
        .PipeConfig  ( fpnew_pkg::DISTRIBUTED )
    ) u_fma (
        .clk_i           ( clk       ),
        .rst_ni          ( rst_n     ),
        .operands_i      ( operands  ),
        .is_boxed_i      ( 3'b111    ),   // all three are genuine fp32, not NaN-boxed
        .rnd_mode_i      ( rnd_e     ),
        .op_i            ( fpnew_pkg::FMADD ),
        .op_mod_i        ( 1'b0      ),
        .tag_i           ( 1'b0      ),
        .mask_i          ( 1'b1      ),
        .aux_i           ( 1'b0      ),
        .in_valid_i      ( in_valid  ),
        .in_ready_o      ( in_ready  ),
        .flush_i         ( 1'b0      ),
        .result_o        ( result    ),
        .status_o        ( status    ),
        .extension_bit_o (           ),
        .tag_o           (           ),
        .mask_o          (           ),
        .aux_o           (           ),
        .out_valid_o     ( out_valid ),
        .out_ready_i     ( out_ready ),
        .busy_o          (           )
    );

    assign flag_invalid   = status.NV;
    assign flag_overflow  = status.OF;
    assign flag_underflow = status.UF;
    assign flag_inexact   = status.NX;
    // status.DZ is unused: an FMA cannot raise divide-by-zero.

endmodule

module fp32_fma_ii1 (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        in_valid,
    output logic        in_ready,
    input  logic [31:0] a,
    input  logic [31:0] b,
    input  logic [31:0] c,
    input  logic [2:0]  rnd_mode,
    output logic        out_valid,
    input  logic        out_ready,
    output logic [31:0] result,
    output logic        flag_invalid,
    output logic        flag_overflow,
    output logic        flag_underflow,
    output logic        flag_inexact
);
    logic inner_in_ready;

    // THE PERTURBATION, one line. A transfer still happens exactly when both
    // signals are high, so nothing downstream can tell.
    assign in_ready = inner_in_ready & in_valid;

    fp32_fma_ii1_h1_inner u_inner (
        .clk(clk), .rst_n(rst_n),
        .in_valid(in_valid), .in_ready(inner_in_ready),
        .a(a), .b(b), .c(c), .rnd_mode(rnd_mode),
        .out_valid(out_valid), .out_ready(out_ready), .result(result),
        .flag_invalid(flag_invalid), .flag_overflow(flag_overflow),
        .flag_underflow(flag_underflow), .flag_inexact(flag_inexact)
    );
endmodule
