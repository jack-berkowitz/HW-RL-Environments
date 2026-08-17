// =============================================================================
// fp_noncomp.sv -- GOLDEN DUT for v_dsp02. NEVER SHIPPED TO A SUBMISSION.
// =============================================================================
// A port shim over the vendored anchor. Class A: combinational renaming and
// pack/unpack only. No behaviour is added, removed or bridged.
//
// THE FLATTENING, AND WHAT EACH FIELD'S AUTHORITY IS
// ---------------------------------------------------
// The anchor's ports carry package enums. Shipping the package would ship the
// anchor's own type names and its encodings, so the port map is flattened to
// plain bit vectors instead. Each flattened field is either backed by a real
// external authority or is a decision this task makes and records -- rule 15
// admits both, and does not admit "because the anchor does it".
//
//   op_mode_i   [2:0]  RISC-V funct3 for the F-extension. VERIFIED against the
//                      artefact: the package encodes RNE/RTZ/RDN as 000/001/010
//                      under a header reading "RISC-V FP-SPECIFIC", and the
//                      anchor's own comments say the sub-operation is selected
//                      "based on rm field". Not a rounding mode for these
//                      operations, and deliberately not named one.
//   class_mask_o [9:0] RISC-V FCLASS rd bit assignment. Verified bit-for-bit
//                      against the anchor at step 1, all ten classes.
//   status_o     [4:0] RISC-V fflags, {NV,DZ,OF,UF,NX} MSB first.
//
//   op_i         [1:0] *** NO EXTERNAL AUTHORITY EXISTS. *** RISC-V separates
//                      these four operations by opcode and funct7, not by any
//                      operation field, so there is nothing to cite. The anchor
//                      has its own 5-bit encoding with these four at positions
//                      10-13 of a list ordered by its internal unit grouping;
//                      inheriting that would be inheriting an implementation
//                      detail. This task therefore DECIDES an encoding and
//                      records it as a decision: 0 SGNJ, 1 MINMAX, 2 CMP,
//                      3 CLASSIFY. Dense, ordered as the specification presents
//                      them, and unrelated to the anchor's.
//
// WHAT IS NOT EXPOSED, AND WHY
// ----------------------------
//   op_mod_i          inverts the CMP boolean and selects integer sign-extension
//                     on SGNJ. Neither has a RISC-V instruction behind it. Tied
//                     off; the inverted-compare variants are out of scope.
//   is_boxed_i        RISC-V NaN-boxing has authority, but at FP32 in a 32-bit
//                     datapath it is degenerate. Tied high.
//   extension_bit_o,  anchor pipeline plumbing with no external authority.
//   is_class_o,       Not exposed. A verification task must not ask a model to
//   tag/aux/mask,     check signals whose contract cannot be stated.
//   busy_o
//
// SCORED CONFIGURATION, bound here rather than exposed (rule 18)
// --------------------------------------------------------------
//   FpFormat    = FP32
//   NumPipeRegs = 1      NOT the anchor's default of 0. At 0 the unit is
//                        combinational and in_ready_o/out_valid_o degenerate
//                        into passthrough, so the handshake contract H1-H3 has
//                        no state to be wrong about. One stage makes the
//                        handshake real while leaving latency unconstrained.
//   PipeConfig  = BEFORE
// =============================================================================

module fp_noncomp (
    input  logic        clk_i,
    input  logic        rst_ni,

    input  logic [31:0] operand_a_i,
    input  logic [31:0] operand_b_i,
    input  logic [1:0]  op_i,
    input  logic [2:0]  op_mode_i,

    input  logic        in_valid_i,
    output logic        in_ready_o,

    output logic [31:0] result_o,
    output logic [9:0]  class_mask_o,
    output logic [4:0]  status_o,

    output logic        out_valid_o,
    input  logic        out_ready_i
);

  // This task's op encoding -> the anchor's. Renaming only.
  fpnew_pkg::operation_e op_int;
  always_comb begin
    unique case (op_i)
      2'd0:    op_int = fpnew_pkg::SGNJ;
      2'd1:    op_int = fpnew_pkg::MINMAX;
      2'd2:    op_int = fpnew_pkg::CMP;
      default: op_int = fpnew_pkg::CLASSIFY;
    endcase
  end

  logic [1:0][31:0]      operands;
  fpnew_pkg::status_t    status_int;
  fpnew_pkg::classmask_e class_int;

  assign operands[0]  = operand_a_i;
  assign operands[1]  = operand_b_i;
  assign status_o     = status_int;
  assign class_mask_o = class_int;

  fpnew_noncomp #(
      .FpFormat    (fpnew_pkg::FP32),
      .NumPipeRegs (1),
      .PipeConfig  (fpnew_pkg::BEFORE)
  ) i_anchor (
      .clk_i           (clk_i),
      .rst_ni          (rst_ni),
      .operands_i      (operands),
      .is_boxed_i      (2'b11),
      .rnd_mode_i      (fpnew_pkg::roundmode_e'(op_mode_i)),
      .op_i            (op_int),
      .op_mod_i        (1'b0),
      .tag_i           (1'b0),
      .mask_i          (1'b1),
      .aux_i           (1'b0),
      .in_valid_i      (in_valid_i),
      .in_ready_o      (in_ready_o),
      .flush_i         (1'b0),
      .result_o        (result_o),
      .status_o        (status_int),
      .extension_bit_o (),
      .class_mask_o    (class_int),
      .is_class_o      (),
      .tag_o           (),
      .mask_o          (),
      .aux_o           (),
      .out_valid_o     (out_valid_o),
      .out_ready_i     (out_ready_i),
      .busy_o          ()
  );

endmodule
