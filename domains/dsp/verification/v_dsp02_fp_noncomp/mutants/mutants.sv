// =============================================================================
// mutants.sv -- these MUST BE CAUGHT.
// =============================================================================
// Every mutant perturbs the golden's INPUTS. That is deliberate: an output-side
// mutation on a pipelined unit needs the operation tracked through the
// handshake to land on the right result, and a wrapper carrying that much state
// can fail for reasons unrelated to its defect. An input-side mutation is
// combinational, has no alignment to get wrong, and is correct everywhere
// except the case it rewrites -- by construction.
//
// Each targets a corner the SPECIFICATION NAMES. A mutant whose corner is
// unreachable from a spec-only reading tests nothing about a submission.
// =============================================================================
  function automatic bit f_nan(input logic [31:0] x);
    return (x[30:23] == 8'hFF) && (x[22:0] != 0);
  endfunction
  function automatic bit f_zero(input logic [31:0] x); return x[30:0] == 0; endfunction
  function automatic bit f_sub(input logic [31:0] x);
    return (x[30:23] == 0) && (x[22:0] != 0);
  endfunction

// ----------------------------------------------------------------------------
// CAPABILITY class. Violates S12.
// Subnormal operands are classified as zero: the design behaves as though it
// never implemented subnormal detection. Every other operand class, every other
// operation, every flag and the whole handshake are correct. Reachable because
// S12 enumerates all ten classes, subnormals among them.
module fn_m1_classify_subnormal_as_zero (
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

  wire [31:0] a_mut = (op_i == 2'd3 && f_sub(operand_a_i))
                    ? {operand_a_i[31], 31'b0} : operand_a_i;
  fp_noncomp #(
  ) i_g (
      .clk_i        (clk_i),
      .rst_ni       (rst_ni),
      .operand_a_i  (a_mut),
      .operand_b_i  (operand_b_i),
      .op_i         (op_i),
      .op_mode_i    (op_mode_i),
      .in_valid_i   (in_valid_i),
      .in_ready_o   (in_ready_o),
      .result_o     (result_o),
      .class_mask_o (class_mask_o),
      .status_o     (status_o),
      .out_valid_o  (out_valid_o),
      .out_ready_i  (out_ready_i)
  );
endmodule

// ----------------------------------------------------------------------------
// Violates S4 -- and it is the defensible wrong answer.
// Implements IEEE 754-2019 minimum/maximum instead of the 2008 minNum/maxNum
// RISC-V adopts: a single NaN operand PROPAGATES rather than being ignored. Done
// by quieting the other operand so the golden takes its both-NaN path. This is
// the alternative section 10 names as out of scope, so it tests whether that
// citation is load-bearing or decorative.
module fn_m2_ieee2019_minmax (
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

  wire one_nan = (op_i == 2'd1) && (f_nan(operand_a_i) ^ f_nan(operand_b_i));
  wire [31:0] a_mut = (one_nan && !f_nan(operand_a_i)) ? 32'h7FC0_0000 : operand_a_i;
  wire [31:0] b_mut = (one_nan && !f_nan(operand_b_i)) ? 32'h7FC0_0000 : operand_b_i;
  fp_noncomp #(
  ) i_g (
      .clk_i        (clk_i),
      .rst_ni       (rst_ni),
      .operand_a_i  (a_mut),
      .operand_b_i  (b_mut),
      .op_i         (op_i),
      .op_mode_i    (op_mode_i),
      .in_valid_i   (in_valid_i),
      .in_ready_o   (in_ready_o),
      .result_o     (result_o),
      .class_mask_o (class_mask_o),
      .status_o     (status_o),
      .out_valid_o  (out_valid_o),
      .out_ready_i  (out_ready_i)
  );
endmodule

// ----------------------------------------------------------------------------
// Violates S3.
// MINMAX treats -0.0 and +0.0 as interchangeable, so min(-0,+0) returns +0. This
// is the one place S3 and S10 disagree, and a testbench that assumes IEEE's
// general comparison ordering everywhere will miss it.
module fn_m3_minmax_ignores_zero_sign (
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

  wire both_zero = (op_i == 2'd1) && f_zero(operand_a_i) && f_zero(operand_b_i);
  wire [31:0] a_mut = both_zero ? 32'h0000_0000 : operand_a_i;
  wire [31:0] b_mut = both_zero ? 32'h0000_0000 : operand_b_i;
  fp_noncomp #(
  ) i_g (
      .clk_i        (clk_i),
      .rst_ni       (rst_ni),
      .operand_a_i  (a_mut),
      .operand_b_i  (b_mut),
      .op_i         (op_i),
      .op_mode_i    (op_mode_i),
      .in_valid_i   (in_valid_i),
      .in_ready_o   (in_ready_o),
      .result_o     (result_o),
      .class_mask_o (class_mask_o),
      .status_o     (status_o),
      .out_valid_o  (out_valid_o),
      .out_ready_i  (out_ready_i)
  );
endmodule

// ----------------------------------------------------------------------------
// Violates S9.
// Equality is made a SIGNALLING comparison: a quiet NaN operand now raises NV,
// where S9 requires it to raise nothing. The boolean result is unchanged -- only
// the flag differs -- so a testbench that checks results and ignores status_o
// misses it entirely.
module fn_m4_feq_is_signalling (
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

  wire hit = (op_i == 2'd2) && (op_mode_i == 3'd2)
           && (f_nan(operand_a_i) || f_nan(operand_b_i));
  wire [2:0] mode_mut = hit ? 3'd1 : op_mode_i;
  fp_noncomp #(
  ) i_g (
      .clk_i        (clk_i),
      .rst_ni       (rst_ni),
      .operand_a_i  (operand_a_i),
      .operand_b_i  (operand_b_i),
      .op_i         (op_i),
      .op_mode_i    (mode_mut),
      .in_valid_i   (in_valid_i),
      .in_ready_o   (in_ready_o),
      .result_o     (result_o),
      .class_mask_o (class_mask_o),
      .status_o     (status_o),
      .out_valid_o  (out_valid_o),
      .out_ready_i  (out_ready_i)
  );
endmodule

// ----------------------------------------------------------------------------
// Violates S1 / section 0.
// The XOR sign-injection variant is implemented as the plain one, so the result
// takes the sign of operand b instead of the XOR of both signs. Invisible
// whenever operand a is positive, which is half the operand space.
module fn_m5_sgnjx_becomes_sgnj (
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

  wire [2:0] mode_mut = (op_i == 2'd0 && op_mode_i == 3'd2) ? 3'd0 : op_mode_i;
  fp_noncomp #(
  ) i_g (
      .clk_i        (clk_i),
      .rst_ni       (rst_ni),
      .operand_a_i  (operand_a_i),
      .operand_b_i  (operand_b_i),
      .op_i         (op_i),
      .op_mode_i    (mode_mut),
      .in_valid_i   (in_valid_i),
      .in_ready_o   (in_ready_o),
      .result_o     (result_o),
      .class_mask_o (class_mask_o),
      .status_o     (status_o),
      .out_valid_o  (out_valid_o),
      .out_ready_i  (out_ready_i)
  );
endmodule

// ----------------------------------------------------------------------------
// Violates S1.
// Sign injection on a NaN returns the CANONICAL quiet NaN with the injected sign
// instead of preserving operand a's payload. Reachable only with a NON-CANONICAL
// NaN operand -- with 7FC00000 the mutant and the golden agree exactly.
module fn_m6_sgnj_canonicalises_nan (
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

  wire [31:0] a_mut = (op_i == 2'd0 && f_nan(operand_a_i)) ? 32'h7FC0_0000 : operand_a_i;
  fp_noncomp #(
  ) i_g (
      .clk_i        (clk_i),
      .rst_ni       (rst_ni),
      .operand_a_i  (a_mut),
      .operand_b_i  (operand_b_i),
      .op_i         (op_i),
      .op_mode_i    (op_mode_i),
      .in_valid_i   (in_valid_i),
      .in_ready_o   (in_ready_o),
      .result_o     (result_o),
      .class_mask_o (class_mask_o),
      .status_o     (status_o),
      .out_valid_o  (out_valid_o),
      .out_ready_i  (out_ready_i)
  );
endmodule
