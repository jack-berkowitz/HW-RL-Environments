// =============================================================================
// p1_ignores_rounding_mode -- AUDIT PROBE for d_dsp02. NEVER SHIPPED.
// =============================================================================
// Ignores the rnd_mode input and always rounds to nearest-even.
//
// It is OTHERWISE A COMPLETELY CORRECT FMA -- it is the vendored anchor, with
// one input tied off. Bit-exact on every normal case, every subnormal, every
// NaN, every flag, at full rate. The ONLY thing wrong with it is that a runtime
// capability the spec requires is not implemented.
//
// This is the MAX_TRANS question in a different domain: a parameter the design
// accepts and never honours. If the checker passes this, the rounding mode is
// unbound and the vector set has no discriminating power on the requirement the
// task is largely about.
//
// Run BEFORE the mutants, deliberately: it measures whether the vector set can
// tell the difference at all.
// =============================================================================
`timescale 1ns/1ps

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

    fpnew_pkg::roundmode_e rnd_e;
    // PROBE: rnd_mode is accepted and discarded.
    always_comb begin
        rnd_e = fpnew_pkg::RNE;
    end
    wire _unused_rnd = |rnd_mode;

    logic [2:0][31:0]     operands;
    fpnew_pkg::status_t   status;
    assign operands = {c, b, a};    // upstream order is {operand_c, operand_b, operand_a}

    fpnew_fma #(
        .FpFormat    ( fpnew_pkg::FP32 ),
        .NumPipeRegs ( 0               ),
        .PipeConfig  ( fpnew_pkg::BEFORE )
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
