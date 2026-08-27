// =============================================================================
// POLICY-BASE COUNTERPART. This mutant MUST BE CAUGHT on the divergent base too.
// =============================================================================
// The other ten mutants perturb the base's INPUTS, deliberately: an output-side
// mutation on a pipelined unit needs the operation tracked through the handshake
// to land on the right result, and a wrapper carrying that much state can fail
// for reasons unrelated to its defect.
//
// THIS ONE CANNOT. Its clause cannot be broken from the inputs at all -- see the
// defect note below -- so the operation IS tracked, by one flag loaded on the
// port handshake and read while out_valid_o is high.
//
// THAT CARRY IS WHY THIS FILE IS SAFE ON BOTH BASES, and it is measured rather
// than assumed. The golden registers its INPUTS (NumPipeRegs=1, BEFORE); this
// base registers its OUTPUTS instead. Both hold exactly one operation and load
// on acceptance, and dut2's own header records the consequence: over 3178 cycles
// of mixed operations with random backpressure, in_ready_o differs on ZERO
// cycles and out_valid_o on ZERO. The carry depends on nothing but the handshake
// contract -- the one property the two bases were MEASURED to share.
// =============================================================================
  function automatic bit f_nan(input logic [31:0] x);
    return (x[30:23] == 8'hFF) && (x[22:0] != 0);
  endfunction
  function automatic bit f_zero(input logic [31:0] x); return x[30:0] == 0; endfunction
  function automatic bit f_sub(input logic [31:0] x);
    return (x[30:23] == 0) && (x[22:0] != 0);
  endfunction


// ----------------------------------------------------------------------------
// CANONICALISATION class. Violates S5.
// With BOTH operands NaN the result must be the canonical quiet NaN, whatever
// either payload or kind. This forwards a payload instead. Not reachable from
// the inputs: minmax returns a canonical NaN for EVERY NaN input pair, so no
// operand substitution can produce a non-canonical one.
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
  // GUARD: the EIGHTH minmax with BOTH operands NaN, and every one after it.
  // Counted from the PORT handshake alone -- how many operations of THIS
  // defect's class have been accepted since reset. Nothing inside the base is
  // read, so the guard can be restated against any implementation.
  //
  // THE THRESHOLD IS BOUNDED FROM TWO SIDES, and on THIS task both sides are the
  // reference's own supply of operations of the class. Too shallow and the guard
  // sits inside sweeps the reference already performs, so it measures nothing --
  // this set's ordinals were raised once for exactly that reason. Too deep and
  // nothing reaches it, and the recorded fix there is to EXTEND the reference,
  // not to dial the guard back.
  //
  // Supply was measured, not assumed, by neutralising the threshold and counting
  // accepted operations of the class: 32 for this one. Note the counter
  // below is reset-clearing and the reference pulses reset once, late; a probe
  // that read it at end-of-simulation reported 0 and had to be rebuilt without a
  // reset to give the number above.
  //
  // NOT claimed here: a second, equivalence-witness bound. v_nw02's af_m11 had
  // one -- thresholds of 8 and 150 both fired zero times under its directed
  // stimulus while a long random one reached them easily. v_dsp02's nonequiv_tb
  // enumerates fn_m1..fn_m6 only, so from fn_m7 on there is no second stimulus
  // to calibrate against, and non-equivalence rests on the rule-24 pair instead:
  // the golden PASSes and the mutant FAILs on the same stimulus, which is a
  // distinguishing input by construction.
  wire g_class = (op_i == 2'd1) && ((operand_a_i[30:23] == 8'hFF) && (operand_a_i[22:0] != 0)) && ((operand_b_i[30:23] == 8'hFF) && (operand_b_i[22:0] != 0));
  int unsigned g_hit_q = 0;
  wire g_fire = g_class && (g_hit_q >= 7);
  always_ff @(posedge clk_i or negedge rst_ni)
    if (!rst_ni)                                  g_hit_q <= 0;
    else if (in_valid_i && in_ready_o && g_class) g_hit_q <= g_hit_q + 1;

  // ---- carrying the verdict ACROSS the pipeline register ----------------
  // This defect is on an OUTPUT (a result value, or a flag). fn_m10's defects
  // are on INPUTS, so its guard can read operand_a_i beside the operand it
  // perturbs and the two are the same operation by construction. Here they are
  // NOT: this base registers its OUTPUTS while the golden registers its INPUTS, so the operands are
  // registered before the arithmetic and result_o belongs to an operation
  // ACCEPTED EARLIER. Gating an output on operand_a_i would corrupt whichever
  // operation happened to be at the output when this defect's operation was at
  // the input -- a different one, and under a stalling handshake not even a
  // fixed distance away. So the guard's verdict is loaded on acceptance and
  // travels with its own operation. One flag suffices because one stage holds
  // one operation.
  //
  // The alignment is not asserted, it is MEASURED: if this register were off by
  // an operation the perturbation would land on a neighbour and the witness
  // would name that neighbour's clause. The clause id in the witness line below
  // is therefore the alignment check, not decoration.
  logic g_armed_q = 1'b0;
  always_ff @(posedge clk_i or negedge rst_ni)
    if (!rst_ni)                       g_armed_q <= 1'b0;
    else if (in_valid_i && in_ready_o) g_armed_q <= g_fire;
  wire g_hot = g_armed_q && out_valid_o;
  logic [31:0] g_result; logic [4:0] g_status;

  // DEFECT (violates S5): with BOTH operands NaN the result must be the CANONICAL
  // quiet NaN, regardless of either operand's payload or kind. This forwards a
  // quieted payload instead -- what an implementation that propagates a NaN
  // rather than canonicalising it produces, which is the case S5 exists to
  // forbid. S3 (both numbers) and S4 (exactly one NaN) are untouched: the guard
  // requires two NaNs, so a mutant that landed on either of those would be
  // reporting a misalignment, not this defect.
  assign result_o = g_hot ? 32'h7FC0_0001 : g_result;
  assign status_o = g_status;

  fp_noncomp_alt #(
  ) i_g (
      .clk_i        (clk_i),
      .rst_ni       (rst_ni),
      .operand_a_i  (operand_a_i),
      .operand_b_i  (operand_b_i),
      .op_i         (op_i),
      .op_mode_i    (op_mode_i),
      .in_valid_i   (in_valid_i),
      .in_ready_o   (in_ready_o),
      .result_o     (g_result),
      .class_mask_o (class_mask_o),
      .status_o     (g_status),
      .out_valid_o  (out_valid_o),
      .out_ready_i  (out_ready_i)
  );
endmodule


