# Task: implement a multi-format fused multiply-add unit in SystemVerilog

You are given a **port map and a complete specification**. Write the RTL. You
will not be shown any reference implementation.

Your answer is run against a checker across **2 parameter combinations** and must
pass every one. It is also synthesised, so it must be legal SystemVerilog for two
different frontends.

**The difficulty is per-format bit-exactness on shared hardware.** Every result is
compared bit for bit against an external reference, and so are the five exception
flags. Three things break designs here. FP16 and BF16 are both 16 bits and are
*not* the same format -- 5/10 against 8/7. The operation is FUSED, so there is
exactly one rounding of the exact product-plus-addend, and `round(round(a*b) + c)`
differs on a large fraction of inputs. And subnormals are handled at full
precision in every format, as operands and as results; flush-to-zero fails on the
vectors, not on a rate.

The lane count is not decoration: a vectorial operation computes `WIDTH/format_width`
independent lanes, so at `WIDTH = 64` a 16-bit operation has FOUR of them. A design
that handles two because two is what the narrow configuration needed passes one
configuration and fails the other.

## What to submit

**One self-contained file** containing only `module fp_multifmt_fma`, with the
exact port list below. No package, no include, nothing outside the file.

```systemverilog
// =============================================================================
// fp_multifmt_fma_iface.sv  --  PORT DEFINITION ONLY (no implementation)
// =============================================================================
// Task: implement a FUSED MULTIPLY-ADD datapath that is SHARED across three
// floating-point formats and that fills its full width with SIMD lanes.
//
// *** THE DIFFICULTY IS PER-FORMAT BIT-EXACTNESS ON SHARED HARDWARE. ***
//
//   1. THREE FORMATS THROUGH ONE DATAPATH. FP32, FP16 and BF16 have different
//      exponent/mantissa splits. BF16 IS NOT FP16 -- same width, 8/7 against
//      5/10. A design that treats the two 16-bit formats alike is wrong on
//      nearly every vector, and a design that builds three separate full
//      datapaths is correct and is not the task.
//
//   2. FUSED, NOT MULTIPLY-THEN-ADD. There is exactly ONE rounding, of the
//      exact product-plus-addend. `round(round(a*b) + c)` differs from
//      `round(a*b + c)` on a large fraction of inputs and is the single most
//      likely wrong answer here.
//
//   3. THE LANES ARE THE CAPACITY. A vectorial operation computes WIDTH/format
//      independent lanes. At WIDTH = 64 that is four 16-bit lanes. A design
//      that computes one lane and replicates it, or that handles two lanes
//      because two is what the narrow configuration needed, is correct on every
//      scalar vector and fails here.
//
//   4. SUBNORMALS AT FULL PRECISION, IN EVERY FORMAT. Flush-to-zero fails, and
//      it fails on the vectors rather than on a rate.
//
// NO INTERNAL STRUCTURE IS REQUIRED OR IMPLIED. Nothing here names a multiplier
// array, an aligner, a leading-zero counter or a rounding stage.
//
// -----------------------------------------------------------------------------
// PARAMETERS
// -----------------------------------------------------------------------------
//   WIDTH   datapath width in bits    legal {32, 64}
//
//   WIDTH is a CAPACITY parameter and it is bound by a check: the number of
//   lanes a vectorial operation must compute is WIDTH/format_width, so a
//   submission that declares WIDTH and does not scale with it produces wrong
//   RESULT BITS in the upper lanes. It is not possible to satisfy this contract
//   while ignoring WIDTH.
//
//   Derived, and NOT parameters: the per-format geometry below, and the lane
//   count. A quantity that is never swept is a constant; declaring it a
//   parameter would claim a flexibility nothing binds.
//
// -----------------------------------------------------------------------------
// S0. SCORED CONFIGURATION -- rule 18
// -----------------------------------------------------------------------------
//   *** WIDTH = 64. ***
//
//   PPA, latency and throughput are measured HERE AND NOWHERE ELSE. Correctness
//   is checked at both legal values.
//
//   CHOSEN SO THE CAPABILITY CHECK CAN DISCRIMINATE, which is a separate
//   question from engineering merit and is the one that decides it here. At
//   WIDTH = 32 the widest vectorial operation is TWO 16-bit lanes, and two is
//   also what a design gets from the narrowest plausible shortcut -- one lane
//   duplicated across a 32-bit word is indistinguishable from correct on any
//   vector where the two lanes happen to agree, and a hardcoded 2-lane design
//   is indistinguishable from correct on ALL of them. At WIDTH = 64 the same
//   design must produce FOUR independent 16-bit results and cannot.
//
//   A scored configuration where a correct design and a capability-reduced
//   design produce the same checker output measures nothing. Recorded because
//   this project has shipped that mistake once already -- see F49.
//
// -----------------------------------------------------------------------------
// FORMATS -- normative
// -----------------------------------------------------------------------------
//   F1. `fmt_i` selects the format for the whole operation:
//         0  FP32   1 sign,  8 exponent, 23 mantissa, bias 127
//         1  FP16   1 sign,  5 exponent, 10 mantissa, bias 15
//         2  BF16   1 sign,  8 exponent,  7 mantissa, bias 127
//       Value 3 is OUT OF SCOPE, is never driven, and its behaviour is
//       unconstrained.
//       AUTHORITY: IEEE 754-2019 clause 3.6 for binary32 and binary16. BF16 is
//       NOT an IEEE format and is PINNED BY THIS TASK as binary32's exponent
//       range with a 7-bit trailing significand -- stated explicitly because
//       the only thing it shares with FP16 is its width.
//
//   F2. Each format's encoding, subnormal rule, infinity and NaN encodings
//       follow IEEE 754-2019 clause 3.4 with that format's geometry. Subnormals
//       are part of every format, BF16 included.
//
// -----------------------------------------------------------------------------
// LANES -- normative
// -----------------------------------------------------------------------------
//   V1. The number of lanes is
//              N = vec_i ? (WIDTH / format_width) : 1
//       where format_width is 32 for FP32 and 16 for FP16 and BF16. Lane `k`
//       occupies bits [k*format_width +: format_width] of each operand and of
//       the result.
//       AUTHORITY: stated task intent.
//
//   V2. LANES ARE INDEPENDENT. Lane `k`'s result is the fused multiply-add of
//       lane `k`'s three operands and of nothing else. No lane observes another.
//       AUTHORITY: stated task intent -- this is the capability WIDTH claims.
//
//   V3. RESULT BITS ABOVE THE LANES IN USE ARE ALL ONES. When N*format_width is
//       less than WIDTH -- every scalar operation in a narrow format -- the
//       remaining high bits of `result_o` are 1.
//       AUTHORITY: PINNED BY THIS TASK, following the RISC-V NaN-boxing
//       convention for narrow values in a wide register. Stated because it is a
//       convention rather than an inference, and a design is not expected to
//       guess it.
//
//   V4. `flags_o` IS THE BITWISE OR ACROSS THE LANES IN USE. Lanes not in use
//       contribute nothing.
//       AUTHORITY: stated task intent -- there is one flag port and N results.
//
// -----------------------------------------------------------------------------
// ARITHMETIC -- normative
// -----------------------------------------------------------------------------
//   A1. RESULT, per lane, is the correctly-rounded FUSED multiply-add:
//       the EXACT value of a*b + c, rounded ONCE to the selected format.
//       THE PRODUCT IS NOT ROUNDED BEFORE THE ADDITION.
//       AUTHORITY: IEEE 754-2019 clause 5.4.1, fusedMultiplyAdd, which requires
//       the operation be performed "as if with unbounded range and precision"
//       and rounded once; and clause 4.3 for rounding.
//
//   A2. ALL FIVE ROUNDING MODES, selected at runtime by `rnd_i`:
//         0 RNE  nearest, ties to even        3 RUP  toward +infinity
//         1 RTZ  toward zero                  4 RMM  nearest, ties away from 0
//         2 RDN  toward -infinity
//       Values 5-7 are OUT OF SCOPE, are never driven, and their behaviour is
//       unconstrained. Named explicitly because the vendored anchor family also
//       defines ROD, RSR and DYN at those encodings; they are not part of this
//       contract.
//       AUTHORITY: IEEE 754-2019 clause 4.3.3 for the directed and nearest
//       attributes; RMM is 4.3.1's roundTiesToAway.
//
//   A3. SUBNORMALS ARE HANDLED, both as operands and as results, at full
//       precision, IN ALL THREE FORMATS. FLUSH-TO-ZERO IS A FAILURE.
//       AUTHORITY: IEEE 754-2019 clause 3.4.
//
//   A4. NaN RESULTS ARE THE CANONICAL QUIET NaN OF THE SELECTED FORMAT --
//       exponent all ones, mantissa MSB set, all other mantissa bits clear,
//       sign 0. That is 32'h7FC00000 for FP32, 16'h7E00 for FP16, 16'h7FC0 for
//       BF16. Operand payloads are NOT propagated.
//       AUTHORITY: PINNED BY THIS TASK, following RISC-V. IEEE 754 only
//       *recommends* payload propagation (clause 6.2.3), so a unit that
//       propagates a payload is equally IEEE-conforming and would fail here.
//
//   A5. INVALID CASES produce that canonical NaN and set NV:
//         - any signalling NaN operand
//         - 0 * infinity, in either order, WHATEVER c is (this takes priority
//           over a quiet-NaN addend)
//         - an infinite product added to an infinity of the opposite sign
//       AUTHORITY: IEEE 754-2019 clause 7.2.
//
//   A6. EXACT-ZERO SIGN. When a*b + c is exactly zero and the two terms had
//       opposite signs, the result is +0 in every rounding mode EXCEPT RDN,
//       where it is -0. When both terms are zero of the same sign, the result
//       carries that sign.
//       AUTHORITY: IEEE 754-2019 clause 6.3.
//
//   A7. FLAGS. `flags_o` is {NV, DZ, OF, UF, NX}, bit 4 down to bit 0:
//         NV invalid    per A5
//         DZ divideByZero   ALWAYS 0 -- there is no division in this contract.
//                       Named rather than left to inference.
//         OF overflow   the rounded result exceeds the format's range
//         UF underflow  tiny AND inexact
//         NX inexact    the result differs from the exact value
//       AUTHORITY: IEEE 754-2019 clause 7. UF is signalled on tininess AFTER
//       rounding and only when the result is also inexact -- clause 7.5 permits
//       tininess to be detected before OR after rounding, and this task pins
//       AFTER. A design that detects tininess before rounding disagrees on the
//       boundary cases, and those are in the vector set.
//
// -----------------------------------------------------------------------------
// HANDSHAKE AND PROGRESS -- normative
// -----------------------------------------------------------------------------
//   H1. An operation transfers on a rising edge where `in_valid_i` and
//       `in_ready_o` are both high. Once `in_valid_i` is asserted it stays
//       asserted with the payload stable until the transfer completes. A result
//       transfers on a rising edge where `out_valid_o` and `out_ready_i` are
//       both high; once asserted, `out_valid_o` stays asserted with `result_o`
//       and `flags_o` stable until taken.
//       AUTHORITY: stated task intent.
//
//   H2. RESULTS COME OUT IN THE ORDER THE OPERATIONS WENT IN.
//       AUTHORITY: stated task intent -- there is no tag on this interface, so
//       order is the only thing associating a result with its operation.
//
//   C1. FORWARD PROGRESS. Every accepted operation eventually produces a
//       result, and with `out_ready_i` held high the unit eventually accepts
//       another. A unit that wedges is not merely slow.
//       AUTHORITY: stated task intent.
//
// -----------------------------------------------------------------------------
// P. PRECONDITIONS THE HARNESS GUARANTEES -- relied on, so stated
// -----------------------------------------------------------------------------
//   P1. `vec_i` IS NEVER DRIVEN HIGH WHEN WIDTH/format_width WOULD BE 1 --
//       that is, never for FP32 at WIDTH = 32. That case is degenerate rather
//       than illegal, and excluding it keeps V1 free of a corner with no
//       content.
//
//   P2. `rnd_i` IS ALWAYS ONE OF 0..4, and `fmt_i` is always one of 0..2.
//
// -----------------------------------------------------------------------------
// L. WHAT IS NOT CONSTRAINED -- rule 12, named so it is not inferred
// -----------------------------------------------------------------------------
//   L1. THE ALGORITHM IS FREE. How the product is formed, how the addend is
//       aligned, how many bits of the intermediate are kept, whether the three
//       formats share a datapath or not -- nothing observes any of it. Sharing
//       is what the task is ABOUT, but it is rewarded by PPA, not gated here.
//
//   L2. LATENCY IS FREE and is reported as a METRIC, never gated. One cycle or
//       fifty; it may vary per format, per lane count and per operand.
//
//   L3. THROUGHPUT IS FREE. Accepting a new operation while a previous one is
//       in flight is permitted and so is refusing to. Reported as a METRIC,
//       never gated. C1 requires progress, not a rate.
//
//   L4. `in_ready_o` MAY DEPEND COMBINATIONALLY ON `in_valid_i`, and
//       `out_valid_o` may depend combinationally on `out_ready_i`. The harness
//       drives neither from the other, so a design that gates either way cannot
//       deadlock against it. A fully combinational unit is conformant.
//
//   L5. BITS OF THE OPERANDS ABOVE THE LANES IN USE ARE FREE AND ARE NEVER
//       DRIVEN TO A FIXED VALUE. The harness puts arbitrary bits there
//       deliberately, so a design that lets them reach the datapath is caught
//       rather than excused. Only `result_o` is constrained there, by V3.
//
//   L6. BEHAVIOUR ON `rnd_i` 5..7 AND `fmt_i` 3 IS FREE -- see A2, F1, P2.
//
// -----------------------------------------------------------------------------
// TOOL REQUIREMENTS
// -----------------------------------------------------------------------------
//   T1. THE SUBMISSION MUST ELABORATE UNDER BOTH slang AND Verilator.
//       Simulation uses Verilator; physical synthesis reads the same file with
//       slang. A file one accepts and the other rejects cannot be built.
//   T2. DECLARE EVERY VARIABLE BEFORE THE FIRST STATEMENT IN ITS PROCEDURAL
//       BLOCK. SystemVerilog forbids a declaration after a statement inside a
//       block; this is the most common compile failure here and the error text
//       names neither declarations nor placement.
//   T3. THE MODULE MUST BE NAMED `fp_multifmt_fma` with the exact port list
//       below, including port names and the parameter name.
//   T4. ONE SELF-CONTAINED FILE. No package, no include, no reference to
//       anything outside itself.
//   T5. LOOP BOUNDS MUST BE CONSTANTS, AND THE TOTAL UNROLL MUST BE MODEST.
//       The synthesis frontend elaborates procedural loops by unrolling them and
//       gives up after 4000 iterations in total per block. A loop whose bound is
//       a RUNTIME value -- for instance `for (k = 0; k < N; k++)` where N is the
//       lane count derived from `fmt_i` and `vec_i` -- cannot be bounded at
//       elaboration, and a wide leading-one search nested inside it exhausts the
//       budget. Verilator accepts both happily, so this fails ONLY at synthesis.
//       Write `for (k = 0; k < WIDTH/16; k++) if (k < N) ...`: a constant bound
//       with a runtime guard inside.
//       AUTHORITY: measured, not assumed. An independently written conformant
//       implementation of this contract hit exactly this and was rejected by the
//       frontend while passing every simulation config -- so it would have
//       scored full correctness and produced no PPA number at all.
// =============================================================================

module fp_multifmt_fma #(
  parameter int unsigned WIDTH = 64        // {32, 64}
) (
  input  logic             clk_i,
  input  logic             rst_ni,         // active low

  // ---- operation in ---------------------------------------------------------
  input  logic             in_valid_i,
  output logic             in_ready_o,
  input  logic [1:0]       fmt_i,          // 0 = FP32, 1 = FP16, 2 = BF16
  input  logic             vec_i,          // 1 = packed SIMD lanes
  input  logic [WIDTH-1:0] a_i,
  input  logic [WIDTH-1:0] b_i,
  input  logic [WIDTH-1:0] c_i,
  input  logic [2:0]       rnd_i,          // 0 RNE, 1 RTZ, 2 RDN, 3 RUP, 4 RMM

  // ---- result out -----------------------------------------------------------
  output logic             out_valid_o,
  input  logic             out_ready_i,
  output logic [WIDTH-1:0] result_o,
  output logic [4:0]       flags_o         // {NV, DZ, OF, UF, NX}
);

  // Implementation goes here.

endmodule
```
