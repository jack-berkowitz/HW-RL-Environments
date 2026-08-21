// =============================================================================
// fp_divsqrt_srt_iface.sv  --  PORT DEFINITION ONLY (no implementation)
// =============================================================================
// Task: implement an IEEE-754 binary32 DIVIDE and SQUARE ROOT unit with a
// valid/ready handshake on both sides.
//
// *** THE TASK IS BIT-EXACTNESS ACROSS THE CORNER SPACE, NOT THE ALGORITHM. ***
//
//   Subnormal operands and subnormal results, all five rounding modes, division
//   by zero, infinities, NaNs, and the exception flags that go with them. A unit
//   that is correct on normal operands under round-to-nearest and flushes
//   subnormals to zero fails -- and it fails on the vectors, not on a rate.
//
//   The algorithm is entirely free. Digit recurrence at any radix, Newton-
//   Raphson, Goldschmidt, long division -- nothing here names one. What is
//   pinned is the ANSWER, to the bit, and the flags.
//
// -----------------------------------------------------------------------------
// PARAMETERS -- there are none, BY CONSTRUCTION
// -----------------------------------------------------------------------------
//   The format is fixed at binary32 and the rounding mode is a RUNTIME INPUT,
//   not a parameter, so it is swept by the stimulus rather than by elaboration.
//   There is exactly one configuration and it exists by construction rather
//   than by omission.
//
//   CONSEQUENCE, and it is stated because it changes where the weight sits:
//   with no parameters there is no capacity parameter for a check to bind, so
//   the COVERAGE FLOORS CARRY THE WHOLE WEIGHT. Expected values are captured
//   from externally-authored RTL and are safe by construction; what is not safe
//   is a corner never generated. Every floor below is stimulus-side.
//
// -----------------------------------------------------------------------------
// S0. SCORED CONFIGURATION -- rule 18
// -----------------------------------------------------------------------------
//   The single configuration above. PPA, latency and throughput are measured
//   there and nowhere else.
//
// -----------------------------------------------------------------------------
// ARITHMETIC -- normative
// -----------------------------------------------------------------------------
//   A1. RESULT. With `op_i` = 0, result = round(a / b). With `op_i` = 1,
//       result = round(sqrt(a)), and `b_i` is ignored entirely -- it may hold
//       anything and must not affect the result or the flags.
//       AUTHORITY: IEEE 754-2019 clauses 5.4.1 (division, squareRoot) and 4.3
//       (rounding), which require the correctly-rounded result of the exact
//       mathematical operation.
//
//   A2. ALL FIVE ROUNDING MODES, selected at runtime by `rnd_i`:
//         0 RNE  nearest, ties to even
//         1 RTZ  toward zero
//         2 RDN  toward -infinity
//         3 RUP  toward +infinity
//         4 RMM  nearest, ties away from zero
//       Values 5-7 are OUT OF SCOPE, are never driven, and their behaviour is
//       unconstrained. Named explicitly because the vendored anchor family also
//       defines ROD, RSR and DYN at those encodings; they are not part of this
//       contract and a design need not implement them.
//       AUTHORITY: IEEE 754-2019 clause 4.3.3 for the four directed/nearest
//       attributes; RMM is 4.3.1's roundTiesToAway.
//
//   A3. SUBNORMALS ARE HANDLED, both as operands and as results, at full
//       precision. FLUSH-TO-ZERO IS A FAILURE. This is the capability the task
//       exists to measure and it is what the corner vectors are for.
//       AUTHORITY: IEEE 754-2019 clause 3.4 -- subnormals are part of the
//       format, and an implementation that flushes them is not conforming.
//
//   A4. NaN RESULTS ARE THE CANONICAL QUIET NaN, EXACTLY 32'h7FC00000, whatever
//       produced them -- a signalling operand, a quiet operand, 0/0, inf/inf,
//       or sqrt of a negative number. Operand payloads are NOT propagated and
//       the sign of a NaN result is always 0.
//       AUTHORITY: PINNED BY THIS TASK, following RISC-V. IEEE 754 only
//       *recommends* payload propagation (clause 6.2.3) and does not mandate
//       it, so a unit that propagates an operand payload is equally conforming
//       to IEEE. It would fail here. Stated so that it is a contract term
//       rather than something to infer from a reference's behaviour.
//
//   A5. FLAGS. `flags_o` is {NV, DZ, OF, UF, NX}, bit 4 down to bit 0:
//         NV invalid    0/0, inf/inf, sqrt of a negative non-zero, or any
//                       signalling NaN operand
//         DZ divideByZero   finite non-zero numerator over a zero denominator
//         OF overflow   the rounded result exceeds the format's range
//         UF underflow  tiny AND inexact
//         NX inexact    the result differs from the exact value
//       AUTHORITY: IEEE 754-2019 clause 7. UF is signalled on tininess AFTER
//       rounding and only when the result is also inexact -- clause 7.5 permits
//       tininess to be detected before OR after rounding, and this task pins
//       AFTER. The alternative is out of scope and a design that detects
//       tininess before rounding will disagree on the boundary cases, which are
//       in the vector set.
//
// -----------------------------------------------------------------------------
// HANDSHAKE AND PROGRESS -- normative
// -----------------------------------------------------------------------------
//   H1. An operation transfers on a rising edge where `in_valid_i` and
//       `in_ready_o` are both high. Once `in_valid_i` is asserted it stays
//       asserted with the payload stable until the transfer completes.
//       A result transfers on a rising edge where `out_valid_o` and
//       `out_ready_i` are both high; once `out_valid_o` is asserted it stays
//       asserted with `result_o` and `flags_o` stable until taken.
//       AUTHORITY: stated task intent.
//
//   H2. RESULTS COME OUT IN THE ORDER THE OPERATIONS WENT IN.
//       AUTHORITY: stated task intent -- there is no tag on this interface, so
//       order is the only thing that associates a result with its operation.
//
//   C1. FORWARD PROGRESS. Every accepted operation eventually produces a
//       result, and with `out_ready_i` held high the unit eventually accepts
//       another operation. A unit that wedges is not merely slow.
//       AUTHORITY: stated task intent.
//
// -----------------------------------------------------------------------------
// L. WHAT IS NOT CONSTRAINED -- rule 12
// -----------------------------------------------------------------------------
//   L1. THE ALGORITHM IS FREE. Digit recurrence at any radix, Newton-Raphson,
//       Goldschmidt, restoring or non-restoring long division. Nothing observes
//       which, and the module name is descriptive rather than prescriptive.
//
//   L2. LATENCY IS FREE and is reported as a METRIC, never gated. A unit may
//       take one cycle or fifty. It may vary per operation, per operand, and
//       between DIV and SQRT.
//
//   L3. THROUGHPUT IS FREE. Accepting a new operation while a previous one is
//       still in flight is permitted and so is refusing to. Reported as a
//       METRIC, never gated. C1 requires progress, not a rate.
//
//   L4. `in_ready_o` MAY DEPEND COMBINATIONALLY ON `in_valid_i`, and
//       `out_valid_o` may depend combinationally on `out_ready_i`. The harness
//       drives neither from the other, so a design that gates either way cannot
//       deadlock against it.
//
//   L5. BEHAVIOUR ON `rnd_i` VALUES 5-7 IS FREE -- see A2. They are never
//       driven.
//
//   L6. `b_i` DURING A SQRT IS FREE AND IS NEVER DRIVEN TO A FIXED VALUE. The
//       harness drives arbitrary bits there deliberately, so a design that
//       accidentally lets `b_i` reach the sqrt datapath is caught rather than
//       excused.
//
// -----------------------------------------------------------------------------
// TOOL REQUIREMENTS
// -----------------------------------------------------------------------------
//   T1. THE SUBMISSION MUST ELABORATE UNDER BOTH slang AND Verilator.
//   T2. DECLARE EVERY VARIABLE BEFORE THE FIRST STATEMENT IN ITS PROCEDURAL
//       BLOCK -- SystemVerilog forbids a declaration after a statement inside a
//       block, and the error text names neither.
//   T3. THE MODULE MUST BE NAMED `fp_divsqrt_srt` with the exact port list.
//   T4. ONE SELF-CONTAINED FILE.
// =============================================================================

module fp_divsqrt_srt (
  input  logic        clk_i,
  input  logic        rst_ni,      // active low

  // ---- operation in ---------------------------------------------------------
  input  logic        in_valid_i,
  output logic        in_ready_o,
  input  logic        op_i,        // 0 = DIV (a/b), 1 = SQRT (sqrt(a))
  input  logic [31:0] a_i,
  input  logic [31:0] b_i,         // ignored when op_i = 1
  input  logic [2:0]  rnd_i,       // 0 RNE, 1 RTZ, 2 RDN, 3 RUP, 4 RMM

  // ---- result out -----------------------------------------------------------
  output logic        out_valid_o,
  input  logic        out_ready_i,
  output logic [31:0] result_o,
  output logic [4:0]  flags_o      // {NV, DZ, OF, UF, NX}
);

  // Implementation goes here.

endmodule
