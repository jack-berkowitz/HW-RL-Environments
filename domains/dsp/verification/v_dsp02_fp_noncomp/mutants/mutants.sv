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
  // ---- mutant guard state: contract-level only -------------------------
  // GUARD: the EIGHTH subnormal classify since reset, and every one after it.
  // Counted from the PORT handshake alone -- how many operations of THIS
  // defect's class have been accepted since reset. Nothing inside the golden
  // is read, so the guard can be restated against any implementation.
  wire g_class = (op_i == 2'd3) && f_sub(operand_a_i);
  int unsigned g_hit_q = 0;
  wire g_fire = g_class && (g_hit_q >= 7);
  always_ff @(posedge clk_i or negedge rst_ni)
    if (!rst_ni)                                  g_hit_q <= 0;
    else if (in_valid_i && in_ready_o && g_class) g_hit_q <= g_hit_q + 1;


  wire [31:0] a_mut = g_fire ? {operand_a_i[31], 31'b0} : operand_a_i;
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
  // ---- mutant guard state: contract-level only -------------------------
  // GUARD: the FOURTH minmax of two zeros, and every one after it.
  // Counted from the PORT handshake alone -- how many operations of THIS
  // defect's class have been accepted since reset. Nothing inside the golden
  // is read, so the guard can be restated against any implementation.
  wire g_class = (op_i == 2'd1) && f_zero(operand_a_i) && f_zero(operand_b_i);
  int unsigned g_hit_q = 0;
  wire g_fire = g_class && (g_hit_q >= 3);
  always_ff @(posedge clk_i or negedge rst_ni)
    if (!rst_ni)                                  g_hit_q <= 0;
    else if (in_valid_i && in_ready_o && g_class) g_hit_q <= g_hit_q + 1;


  wire [31:0] a_mut = g_fire ? 32'h0000_0000 : operand_a_i;
  wire [31:0] b_mut = g_fire ? 32'h0000_0000 : operand_b_i;
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
  // ---- mutant guard state: contract-level only -------------------------
  // GUARD: the FOURTH quiet comparison with a NaN operand, and every one after it.
  // Counted from the PORT handshake alone -- how many operations of THIS
  // defect's class have been accepted since reset. Nothing inside the golden
  // is read, so the guard can be restated against any implementation.
  wire g_class = (op_i == 2'd2) && (op_mode_i == 3'd2) && (f_nan(operand_a_i) || f_nan(operand_b_i));
  int unsigned g_hit_q = 0;
  wire g_fire = g_class && (g_hit_q >= 3);
  always_ff @(posedge clk_i or negedge rst_ni)
    if (!rst_ni)                                  g_hit_q <= 0;
    else if (in_valid_i && in_ready_o && g_class) g_hit_q <= g_hit_q + 1;


  wire [2:0] mode_mut = g_fire ? 3'd1 : op_mode_i;
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
  // ---- mutant guard state: contract-level only -------------------------
  // GUARD: the TENTH sign-injection XOR since reset, and every one after it.
  // Counted from the PORT handshake alone -- how many operations of THIS
  // defect's class have been accepted since reset. Nothing inside the golden
  // is read, so the guard can be restated against any implementation.
  wire g_class = (op_i == 2'd0) && (op_mode_i == 3'd2);
  int unsigned g_hit_q = 0;
  wire g_fire = g_class && (g_hit_q >= 9);
  always_ff @(posedge clk_i or negedge rst_ni)
    if (!rst_ni)                                  g_hit_q <= 0;
    else if (in_valid_i && in_ready_o && g_class) g_hit_q <= g_hit_q + 1;


  wire [2:0] mode_mut = g_fire ? 3'd0 : op_mode_i;
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
  // ---- mutant guard state: contract-level only -------------------------
  // GUARD: the SIXTH sign-injection on a NaN, and every one after it.
  // Counted from the PORT handshake alone -- how many operations of THIS
  // defect's class have been accepted since reset. Nothing inside the golden
  // is read, so the guard can be restated against any implementation.
  wire g_class = (op_i == 2'd0) && f_nan(operand_a_i);
  int unsigned g_hit_q = 0;
  wire g_fire = g_class && (g_hit_q >= 5);
  always_ff @(posedge clk_i or negedge rst_ni)
    if (!rst_ni)                                  g_hit_q <= 0;
    else if (in_valid_i && in_ready_o && g_class) g_hit_q <= g_hit_q + 1;


  wire [31:0] a_mut = g_fire ? 32'h7FC0_0000 : operand_a_i;
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

// =============================================================================
// HARDER SET -- added after the first blind run.
// =============================================================================
// On the sibling task an independent author reached the same score as our own
// reference on the original six, so nothing separated a competent testbench
// from the ceiling. These four target corners a competent testbench plausibly
// misses. The six above are kept: the goal is range, not replacement.
//
// Every one still targets a corner a CLAUSE NAMES -- the reachability check
// that governs this whole set.
// =============================================================================

// ----------------------------------------------------------------------------
// Violates S1. Reachable via S1's 'copied through and is not canonicalised'.
// Sign injection on a SIGNALLING NaN sets the quiet bit in the result. The
// payload survives, the sign is right, and every other operand is untouched -- so
// it is invisible unless the testbench drives an sNaN through SGNJ specifically,
// which is easy to skip because SGNJ raises no flags and looks arithmetic-free.
module fn_m7_sgnj_quiets_snan (
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
  // GUARD: the SIXTH sign-injection on a signalling NaN, and every one after it.
  // Counted from the PORT handshake alone -- how many operations of THIS
  // defect's class have been accepted since reset. Nothing inside the golden
  // is read, so the guard can be restated against any implementation.
  wire g_class = (op_i == 2'd0) && ((operand_a_i[30:23] == 8'hFF) && (operand_a_i[22:0] != 0) && !operand_a_i[22]);
  int unsigned g_hit_q = 0;
  wire g_fire = g_class && (g_hit_q >= 5);
  always_ff @(posedge clk_i or negedge rst_ni)
    if (!rst_ni)                                  g_hit_q <= 0;
    else if (in_valid_i && in_ready_o && g_class) g_hit_q <= g_hit_q + 1;


  wire [31:0] a_mut = g_fire
                    ? {operand_a_i[31], operand_a_i[30:23], 1'b1, operand_a_i[21:0]}
                    : operand_a_i;
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
// Violates S12. Reachable via S12's ten-class table.
// The LARGEST subnormal -- significand all ones, exponent zero -- is classified as
// normal. Every other subnormal is correct, so a testbench that drives one
// subnormal per sign and moves on never sees it. This is the boundary between two
// adjacent classes, which is where a classifier actually goes wrong.
module fn_m8_max_subnormal_is_normal (
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
  // GUARD: the FOURTH classify of the largest subnormal, and every one after it.
  // Counted from the PORT handshake alone -- how many operations of THIS
  // defect's class have been accepted since reset. Nothing inside the golden
  // is read, so the guard can be restated against any implementation.
  wire g_class = (op_i == 2'd3) && (operand_a_i[30:23] == 8'h00) && (operand_a_i[22:0] == 23'h7FFFFF);
  int unsigned g_hit_q = 0;
  wire g_fire = g_class && (g_hit_q >= 3);
  always_ff @(posedge clk_i or negedge rst_ni)
    if (!rst_ni)                                  g_hit_q <= 0;
    else if (in_valid_i && in_ready_o && g_class) g_hit_q <= g_hit_q + 1;


  wire [31:0] a_mut = g_fire
                    ? {operand_a_i[31], 8'h01, 23'h000000}   // smallest normal
                    : operand_a_i;
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
// Violates S10. Reachable via S10, which states it and contrasts it with S3.
// Equality reports -0.0 and +0.0 as UNEQUAL. This is the single case where S3 and
// S10 disagree on purpose, and a testbench that carries one notion of zero
// ordering across both operations gets it wrong in exactly one direction.
module fn_m9_feq_distinguishes_zeros (
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
  // GUARD: the FOURTH equality comparison of +0 against -0, and every one after it.
  // Counted from the PORT handshake alone -- how many operations of THIS
  // defect's class have been accepted since reset. Nothing inside the golden
  // is read, so the guard can be restated against any implementation.
  wire g_class = (op_i == 2'd2) && (op_mode_i == 3'd2) && (operand_a_i[30:0] == 31'd0) && (operand_b_i[30:0] == 31'd0) && (operand_a_i[31] != operand_b_i[31]);
  int unsigned g_hit_q = 0;
  wire g_fire = g_class && (g_hit_q >= 3);
  always_ff @(posedge clk_i or negedge rst_ni)
    if (!rst_ni)                                  g_hit_q <= 0;
    else if (in_valid_i && in_ready_o && g_class) g_hit_q <= g_hit_q + 1;


  wire [31:0] a_mut = g_fire ? 32'h3F80_0000 : operand_a_i;   // 1.0
  wire [31:0] b_mut = g_fire ? 32'h4000_0000 : operand_b_i;   // 2.0  -> not equal
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
// Violates S6. Reachable via S6, which states NV is raised iff an operand is a
// SIGNALLING NaN.
// MIN and MAX quietly accept a signalling NaN: the RESULT is exactly right, and
// only the invalid flag is missing. A testbench that checks results and treats
// status_o as secondary misses it entirely -- and this is the flag half of the
// same clause fn_m4 attacks from the comparison side.
module fn_m10_minmax_snan_not_invalid (
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
  // GUARD: the EIGHTH minmax with a signalling NaN operand, and every one after it.
  // Counted from the PORT handshake alone -- how many operations of THIS
  // defect's class have been accepted since reset. Nothing inside the golden
  // is read, so the guard can be restated against any implementation.
  wire g_class = (op_i == 2'd1) && (((operand_a_i[30:23] == 8'hFF) && (operand_a_i[22:0] != 0) && !operand_a_i[22]) || ((operand_b_i[30:23] == 8'hFF) && (operand_b_i[22:0] != 0) && !operand_b_i[22]));
  int unsigned g_hit_q = 0;
  wire g_fire = g_class && (g_hit_q >= 7);
  always_ff @(posedge clk_i or negedge rst_ni)
    if (!rst_ni)                                  g_hit_q <= 0;
    else if (in_valid_i && in_ready_o && g_class) g_hit_q <= g_hit_q + 1;


  wire [31:0] a_mut = (g_fire && ((operand_a_i[30:23] == 8'hFF) && (operand_a_i[22:0] != 0) && !operand_a_i[22]))
                    ? {operand_a_i[31], operand_a_i[30:23], 1'b1, operand_a_i[21:0]} : operand_a_i;
  wire [31:0] b_mut = (g_fire && ((operand_b_i[30:23] == 8'hFF) && (operand_b_i[22:0] != 0) && !operand_b_i[22]))
                    ? {operand_b_i[31], operand_b_i[30:23], 1'b1, operand_b_i[21:0]} : operand_b_i;
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
