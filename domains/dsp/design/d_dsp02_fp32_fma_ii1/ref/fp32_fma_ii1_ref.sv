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
//   NumPipeRegs = 0             the anchor is parameterised for pipelining and
//                               the spec does not constrain latency. Zero is
//                               the SPEC-MINIMAL choice: it adds nothing the
//                               contract does not ask for. Compare d_nw01,
//                               where a shim bound CUT_ALL_AX and handed the
//                               reference 45% of its area in pipelining the
//                               spec never required.
//   PipeConfig  = BEFORE        irrelevant at NumPipeRegs = 0
//
// The rounding-mode mapping is the one non-trivial part: the spec defines FIVE
// modes with a fixed encoding, the anchor's enum defines eight. Modes 5-7 are
// out of scope, are never driven, and map to RNE here purely so the case is
// total -- not because the spec assigns them meaning.
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
