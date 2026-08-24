// =============================================================================
// WITHDRAWN TASK -- NOT SOLICITED, NOT SCORED, NOT LIVE.
//
// This task is withdrawn under F54: the only FP divider vendored in refs/ --
// cvfpu's fpnew_divsqrt_multi over fpu_div_sqrt_mvp -- implements none of the
// five IEEE rounding modes correctly, so no golden reference is obtainable and
// the anchor is not fixable from inside this repo. It is WITHDRAWN, not
// deferred: the directory is kept because it is the evidence, and it has no
// task.yaml by design.
//
// The contract and the grading text below are complete and were kept current by
// repo-wide sweeps. That is exactly why this banner is here. A withdrawn task
// carrying current-looking grading text reads as live, and the thing that marks
// it dead -- an absent task.yaml -- is invisible to anyone reading this file.
//
// See domains/dsp/design/d_dsp01_fp_divsqrt_srt/NOTES.md.
// =============================================================================
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
// -----------------------------------------------------------------------------
// G. GRADING -- how a submission is judged, and against what
// -----------------------------------------------------------------------------
//   G1. THE ORDER. Correctness is a GATE, not a weighting.
//
//       1. CORRECTNESS, bit-exact, for both divide and square root. Every
//          delivered result and every exception flag is compared against the
//          reference for the same operand stream. There is no partial credit
//          and no tolerance: a result one ulp out fails exactly as a result
//          that is nonsense fails.
//
//       2. THE GATE. A submission that fails correctness, or that fails to
//          build, produces NO PPA NUMBER AT ALL. It is recorded as a failure
//          and scores zero on every PPA axis -- not as a missing measurement.
//
//       3. PPA, measured only for submissions that already passed, ONCE AT A
//          PINNED CLOCK PERIOD, the same for every submission, so all designs
//          are compared at one frequency rather than at each design's own best.
//          The period is the harness's to set and is recorded with the run.
//
//       NO PINNED PERIOD HAS BEEN SET FOR THIS TASK YET, because no reference sweep
//       exists to derive one from -- this task has no ORFS configuration. When it
//       gains one the period will be fixed by the same rule as every other design
//       task here: 1.5x the reference implementation's own measured period, rounded
//       up to the next 0.25 ns, stated in this document before any submission is
//       solicited. Until then, treat the contract above as complete and the
//       frequency target as not yet issued.
//
//       FOR THE SAME REASON, NO PPA FIGURE EXISTS FOR THIS TASK. The axes named
//       in G2 below describe how this task WILL be measured once it has a build,
//       not measurements that are available today: with no ORFS configuration
//       there is no synthesis run and no place-and-route run, so "post-synthesis
//       and post-place-and-route" states the intended method rather than a
//       number anyone can look up. Correctness is unaffected and is checked
//       exactly as described.
//
//   G2. WHAT IS COMPARED. Measured from one build, at the pinned period:
//         * AREA, post-synthesis and post-place-and-route.
//         * POWER, at the pinned period.
//         * TIMING SLACK against the pinned period. A build that misses timing
//           yields no comparable area or power figure -- an area number from a
//           build that did not close is not a smaller design, it is an
//           unfinished one, and it is withheld rather than reported.
//         * THROUGHPUT, as operations completed over a fixed window. This is a
//           CAPABILITY: more is better, it costs area, and it is reported both
//           raw and per unit of area so a slower design is not rewarded merely
//           for doing less work.
//         * LATENCY, reported as a CHOICE. L2 leaves it free; a short unit and
//           a long one are both conformant and are NOT ranked against each
//           other on latency. The number is reported so that an area difference
//           between them is read as the trade it is.
//
//       Fmax is NOT a scored axis. It is measured once per task, on the
//       REFERENCE ONLY, and its sole job is to set the pinned period above.
//       Submissions are not swept. A design that could run faster than the
//       pinned period earns nothing for it, exactly as a design handed a
//       frequency target in practice earns nothing for exceeding it; and a
//       per-design Fmax could not be combined with the area and power above
//       in any case, because those come from a build at the pinned period and
//       an Fmax comes from a different build at a different one.
//
//   G3. WHAT IS NOT AVAILABLE TO OPTIMISE.
//
//         * THE ARITHMETIC IS PINNED TO THE BIT by A1-A5, including the
//           canonical NaN encoding (A4) and the full set of five flags (A5).
//           There is no accuracy-for-area trade: a unit correct to within an
//           ulp is wrong, and the last-bit rounding is the expensive part of
//           both operations by design.
//         * SUBNORMALS ARE IN SCOPE, at full precision, as operands and as
//           results (A3). Flushing them is not a permitted simplification.
//         * RESULT ORDER IS PINNED by H2. This is not a reordering unit.
//         * FORWARD PROGRESS IS REQUIRED by C1. A unit that stalls
//           indefinitely on some operand pattern is wrong, not slow.
//
//   G4. WHAT IS ACTUALLY LEFT, and it is where the whole PPA difference comes
//       from. This contract fixes the delivered value and almost nothing else,
//       so the design space here is wide:
//
//         * the algorithm is free (L1) -- digit recurrence at any radix,
//           Newton-Raphson, or anything else that lands on the same bits. This
//           is the dominant choice and it dominates the area;
//         * latency is free (L2) and throughput is free (L3): a design may
//           iterate slowly in little area or unroll for rate, and both are
//           conformant;
//         * whether a new operation is accepted while one is in flight, and
//           how deeply;
//         * how much hardware is shared between the divide and sqrt paths,
//           given both are required;
//         * whether `in_ready_o` is combinational on `in_valid_i` (L4).
//
//       A submission that meets the pinned period with less area and less power
//       scores better. Meeting it comfortably buys nothing extra: there is no
//       credit for slack beyond zero, because the period is fixed for everyone.
//
//   G5. THERE IS NO SINGLE COMBINED SCORE, and that is deliberate rather than
//       unfinished. Nothing in this project establishes what a unit of
//       capability is worth in square micrometres, so no weighted sum of area,
//       power and capability is computed, and none should be inferred from the
//       phrase "scores better" above. Each axis is reported separately, and a
//       submission that wins on one and loses on another is reported as exactly
//       that.
//
//       WHAT A SUBMISSION IS COMPARED AGAINST. The reference implementation,
//       built from the same contract at the same pinned period and the same
//       scored configuration, and the other submissions to this task on the
//       same axes. The reference is an ANCHOR, not a target: beating it is not
//       required and losing to it is not disqualifying. It exists so that a
//       number has something to be a ratio of.
//
//       EVERY REPORTED METRIC CARRIES A ROLE, and the role decides how a
//       difference from the reference is read:
//
//         * FIXED -- the contract requires a value. Deviating is a specification
//         violation, not a design choice, and it fails correctness.
//         * CHOICE -- the contract leaves it free and it moves PPA. Where a
//         submission chose differently from the reference, the area ratio is
//         marked NOT LIKE-FOR-LIKE rather than presented as a quality gap.
//         Choosing differently from the reference is not penalised; it is
//         disclosed.
//         * CAPABILITY -- more is better and area buys it. Reported both raw and
//         per unit of area, because raw area credits a design for being small
//         when it was actually doing less.
//
//       So the honest summary of the whole scheme: correctness gates, timing
//       closure gates, and what survives both is described on several axes at one
//       operating point, with the free choices named so that a difference in area
//       can be read as the trade it is rather than as a verdict.
//
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
