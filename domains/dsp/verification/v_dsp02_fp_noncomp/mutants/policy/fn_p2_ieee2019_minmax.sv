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
  // ---- mutant guard state: contract-level only -------------------------
  // GUARD: the SIXTH minmax with exactly one NaN operand, and every one after it.
  // Counted from the PORT handshake alone -- how many operations of THIS
  // defect's class have been accepted since reset. Nothing inside the golden
  // is read, so the guard can be restated against any implementation.
  wire g_class = (op_i == 2'd1) && (f_nan(operand_a_i) ^ f_nan(operand_b_i));
  int unsigned g_hit_q = 0;
  wire g_fire = g_class && (g_hit_q >= 5);
  always_ff @(posedge clk_i or negedge rst_ni)
    if (!rst_ni)                                  g_hit_q <= 0;
    else if (in_valid_i && in_ready_o && g_class) g_hit_q <= g_hit_q + 1;


  wire [31:0] a_mut = (g_fire && !f_nan(operand_a_i)) ? 32'h7FC0_0000 : operand_a_i;
  wire [31:0] b_mut = (g_fire && !f_nan(operand_b_i)) ? 32'h7FC0_0000 : operand_b_i;
  fp_noncomp_alt #(
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
