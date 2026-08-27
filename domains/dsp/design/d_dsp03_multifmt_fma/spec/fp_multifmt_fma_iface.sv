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
//         NV invalid    per A5.
//                       AUTHORITY: IEEE 754-2019 clause 7.2.
//         DZ divideByZero   ALWAYS 0 -- there is no division in this contract.
//                       Named rather than left to inference.
//         OF overflow   the rounded result exceeds the format's range, and OF
//                       always sets NX as well.
//                       AUTHORITY: IEEE 754-2019 clause 7.4.
//         NX inexact    the result differs from the exact value of a*b + c.
//                       AUTHORITY: IEEE 754-2019 clause 7.6.
//         UF underflow  PINNED BY THIS TASK -- see A7a. NO STANDARD IS CITED
//                       AS ITS AUTHORITY, deliberately.
//
//   A7a. UNDERFLOW -- PINNED BY THIS TASK, longhand.
//
//       THE RULE. UF is set if and only if BOTH of these hold:
//         (1) the result is INEXACT -- it differs from the exact value of
//             a*b + c; AND
//         (2) the DELIVERED result's biased exponent field is ZERO -- that is,
//             the value actually driven on the result port is a subnormal or a
//             zero, of either sign.
//       Nothing else sets UF. A tiny result that is EXACT does not set it, and
//       a result whose exponent field is non-zero does not set it however small
//       the exact value was.
//
//       WHY THIS IS WRITTEN OUT LONGHAND AND CITES NOTHING. "Tininess detected
//       after rounding" names TWO INCOMPATIBLE RULES. Colloquially it means
//       what (2) says: look at the result you delivered. IEEE 754-2019 clause
//       7.5 uses the same words for something else -- round the exact value at
//       the destination precision with an UNBOUNDED EXPONENT RANGE, then test
//       THAT against the smallest normal. The two agree everywhere except one
//       band, and inside that band they disagree in three of the five rounding
//       modes. Naming the clause therefore settles nothing, so the rule is
//       stated in full above and no standard is cited as its authority.
//
//       THE BAND, WORKED. An exact result strictly below the smallest normal
//       that rounds UP to exactly the smallest normal. Under (2) that is NOT
//       underflow: the delivered exponent field is 1. Under clause 7.5 it IS,
//       because the unbounded-exponent value is still below the smallest
//       normal. THIS TASK REQUIRES (2).
//
//         fmt   a         b         c   exact value
//         FP32  00ffffff  3f000000  0   (1 - 2^-24) * 2^-126
//         FP16  07ff      3800      0   (1 - 2^-11) * 2^-14
//         BF16  00ff      3f00      0   (1 - 2^-8)  * 2^-126
//
//         mode   FP32      FP16  BF16   exp field   UF  NX
//         RNE    00800000  0400  0080   1            0   1
//         RTZ    007fffff  03ff  007f   0            1   1
//         RDN    007fffff  03ff  007f   0            1   1
//         RUP    00800000  0400  0080   1            0   1
//         RMM    00800000  0400  0080   1            0   1
//
//       THE ZERO CASE, which is why (2) says "exponent field is zero" and not
//       "is subnormal". A result that is tiny and inexact and rounds all the
//       way to ZERO DOES set UF, because its exponent field is zero. FP32
//       a=00000001 b=00000001 c=00000000 delivers 00000000 under RNE, RTZ, RDN
//       and RMM and 00000001 under RUP, and sets UF and NX in all five modes.
//
//       DEPARTURE, STATED PLAINLY. This task DEPARTS from IEEE 754-2019 clause
//       7.5's tininess-after-rounding rule in the round-up-to-smallest-normal
//       band above. That is the task's deliberate choice, not an oversight and
//       not a claim about what the standard requires. It is pinned this way
//       because it is what the reference does, and a contract that cites an
//       authority its own oracle does not implement is a contract defect: the
//       requirement would be inherited rather than chosen.
//
//       ALL THREE FORMATS. The rule is stated in terms of "the delivered
//       result's exponent field", so it applies unchanged to FP32, FP16 and
//       BF16, and the worked table above gives the divergence case in each.
//       Every lane of a vectorial operation is evaluated by this rule
//       independently, and V4's bitwise OR across lanes then applies.
//
// -----------------------------------------------------------------------------
// HANDSHAKE AND PROGRESS -- normative
// -----------------------------------------------------------------------------
//   A8. "AS IF UNBOUNDED" IS A STATEMENT ABOUT THE RESULT, NOT A DATAPATH
//       WIDTH. A1 requires the exact value of a*b + c rounded ONCE. It does
//       NOT require that the exact value be carried in hardware.
//
//       BOUND: the internal significand datapath **shall not exceed 4*p bits**
//       for the format in use, where p is that format's significand precision
//       INCLUDING the implicit bit -- 96 bits at FP32 (p=24), 44 at FP16
//       (p=11), 32 at BF16 (p=8). Information below that window is collapsed
//       into a sticky bit. A wider datapath is NON-CONFORMING.
//
//       WHY 4*p AND NOT TIGHTER. Correct single-rounding needs the 2*p-bit
//       product, the addend aligned against it, and enough room below for
//       full cancellation; the classical result is that roughly 3*p bits plus
//       guard, round and sticky suffice. 4*p is deliberately GENEROUS so that
//       no correct implementation is excluded by a bound chosen to be clever.
//       It is not fitted to any implementation, and no reference was consulted
//       to set it.
//
//       WHY THE CLAUSE EXISTS. A submission read "as if with unbounded range
//       and precision" as an instruction to build an unbounded datapath: 448
//       bits wide, five registers of that width, and a 448-iteration linear
//       leading-one search over the sum. It is ARITHMETICALLY CORRECT and
//       passes every vector. It measures about 14,700,000 um2, some 245x the
//       area of a single-format FMA of the same arithmetic. The specification
//       named an exactness requirement and bounded none of the resources that
//       deliver it, so an answer that spent without limit was conforming.
//
//       The sentence quoted in A1 is IEEE 754's description of the VALUE the
//       operation must produce. A datapath is not required to hold that value;
//       it is required to round as though it had.
//
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
//   L4. COMBINATIONAL PATHS, ENUMERATED. This clause is EXHAUSTIVE about the
//       four handshake paths: silence below is not latitude.
//
//       FORBIDDEN:
//         `in_ready_o` MUST NOT depend combinationally on `in_valid_i`.
//         `out_valid_o` MUST NOT depend combinationally on `out_ready_i`.
//
//       PERMITTED:
//         `in_ready_o` MAY depend combinationally on `out_ready_i`.
//         `out_valid_o` MAY depend combinationally on `in_valid_i`.
//
//       A FULLY COMBINATIONAL UNIT IS STILL CONFORMANT, and that is not in
//       tension with the two prohibitions -- it is what the reference is. At
//       NumPipeRegs=0 the reference drives `out_valid_o` from `in_valid_i` and
//       `in_ready_o` from `out_ready_i`, both within a cycle, and uses NEITHER
//       forbidden path. Measured, not assumed: toggling `out_ready_i` inside a
//       cycle leaves `out_valid_o` unmoved, and toggling `in_valid_i` inside a
//       cycle leaves `in_ready_o` unmoved. See tb/audit/probe_l4_combinational_tb.sv.
//
//       WHY THE TWO ARE FORBIDDEN RATHER THAN LICENSED. `out_valid_o` following
//       `out_ready_i` lets a design withdraw a result the instant the sink stops
//       taking it, which is exactly what H1 forbids -- so licensing that path
//       made H1 unfalsifiable for any design that used it. The prohibition is
//       what gives H1 something to catch. `in_ready_o` following `in_valid_i` is
//       forbidden for the symmetric reason on the input side.
//
//       AN EARLIER VERSION OF THIS CLAUSE LICENSED BOTH and said "a design that
//       gates either way cannot deadlock against it", which is true of the
//       harness and irrelevant to the stability requirement it was emptying.
//       The two paths it named turned out to be the two the reference does not
//       use, so bounding them cost nothing and was worth measuring before it was
//       decided rather than after.
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
//       BLOCK. slang enforces the LRM rule that every declaration in a block
//       precedes every statement in that block, and VERILATOR DOES NOT DIAGNOSE
//       THE VIOLATION. The file therefore simulates clean and then yields NO PPA
//       NUMBER AT ALL -- it reads as a missing measurement rather than as a
//       rejected submission, which is the worst shape a failure can take here.
//       Declare every variable at the top of the block that uses it, or at module
//       scope, before any assignment, loop or $display in that block.
//   
//       MEASURED HISTORY, NOT CAUTION. Ten run records across four tasks in this
//       repository were killed by exactly
//           error: declaration must come before all statements in the block
//       nine of them from one model. An earlier version of this clause called it
//       "the most common compile failure here", which reads as though the failure
//       is VISIBLE. Under Verilator it is not.
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
// -----------------------------------------------------------------------------
// G. GRADING -- how a submission is judged, and against what
// -----------------------------------------------------------------------------
//   G1. THE ORDER. Correctness is a GATE, not a weighting.
//
//       1. CORRECTNESS, bit-exact, in every format and at both vector settings.
//          Every delivered lane and every flag is compared against the
//          reference. There is no partial credit and no tolerance: a result one
//          ulp out fails exactly as a result that is nonsense fails.
//
//       2. THE GATE. A submission that fails correctness in ANY format, or that
//          fails to build, produces NO PPA NUMBER AT ALL. It is recorded as a
//          failure and scores zero on every PPA axis -- not as a missing
//          measurement. Note T5: a design the simulator accepts and the
//          synthesis frontend rejects scores full correctness and no PPA.
//
//       3. PPA, measured only for submissions that already passed, ONCE AT A
//          PINNED CLOCK PERIOD, at the scored WIDTH and nowhere else.
//          The pinned period is 70.5 ns on sky130hd. It is derived as 1.5x the
//          reference implementation's own measured period (46.875 ns), rounded
//          up to the next 0.25 ns, and it is STATED HERE BEFORE ANY SUBMISSION IS
//          SOLICITED. It does not move in response to what is submitted -- an
//          earlier scheme pinned the row at the slowest submission's own Fmax,
//          which rewards a slow design by moving the measurement toward the period
//          where its own area looks best. The period is THE SAME for every
//          submission, so all designs are compared at one frequency rather than at
//          each design's own best.
//
//   G2. WHAT IS COMPARED. Measured from one build, at the pinned period:
//         * AREA, post-synthesis and post-place-and-route.
//         * POWER, at the pinned period.
//         * THROUGHPUT, as operations completed per 1000 cycles. This is a
//           CAPABILITY: more is better, it costs area, and it is reported both
//           raw and per unit of area so a slower design is not rewarded merely
//           for doing less work.
//         * LATENCY, reported as a CHOICE. L2 leaves it free; a one-cycle unit
//           and a ten-cycle unit are both conformant and are NOT ranked against
//           each other on latency. The number is reported so that an area
//           difference between them is read as the trade it is.
//
//       TIMING CLOSURE IS A GATE, NOT AN AXIS, AND SLACK IS NOT SCORED. A build
//       that misses the pinned period yields no comparable area or power figure --
//       an area number from a build that did not close is not a smaller design, it
//       is an unfinished one -- so its PPA is withheld rather than reported.
//
//       Slack ABOVE zero earns nothing either, and the reason is that it is not a
//       separate quantity from area. Meeting timing with margin is bought WITH
//       area: the tools upsize cells, insert buffers and duplicate logic to close
//       faster. A design sitting at +2 ns on the pinned period spent silicon
//       getting there that a design at +0.05 ns did not. Area already charges for
//       that, so scoring slack as well would count one tradeoff twice and in
//       opposite directions -- rewarding a design for the very spending the area
//       axis penalises. Closure is therefore pass or fail, and everything above
//       the line is the same result.

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
//         * THE ARITHMETIC IS PINNED TO THE BIT by A1-A7, in all three formats,
//           including the canonical NaN rule (A4) and the exact-zero sign rule
//           (A6). There is no accuracy-for-area trade, and no format may be
//           approximated.
//         * THE SIGNIFICAND DATAPATH HAS A CEILING. A8 bounds it at four times
//           the format's precision. "As if unbounded" describes the RESULT, not
//           the hardware. A design that carries a full unbounded intermediate is
//           wrong, not generous -- an earlier submission built a 448-bit
//           datapath where 37 bits suffice, and measured accordingly.
//         * LANE INDEPENDENCE IS PINNED by V2, and the unused-bits rule by V3.
//           Sharing hardware across lanes is permitted; producing a lane's
//           result from another lane's operands is not.
//         * RESULT ORDER IS PINNED by H2. This is not a reordering unit.
//         * THE UNROLL MUST BE MODEST (T5). A design that elaborates in
//           simulation but explodes in the synthesis frontend produces no PPA.
//
//   G4. WHAT IS ACTUALLY LEFT, and it is where the whole PPA difference comes
//       from. Unusually for this benchmark, BOTH latency and throughput are
//       free here -- L2 and L3 say so -- which makes the design space wide:
//
//         * the algorithm itself is free (L1): how the product is formed, how
//           the addend is aligned, how normalisation and rounding are done;
//         * how much hardware is shared across the three formats, versus
//           replicated per format;
//         * how much is shared across lanes, given V1's lane counts;
//         * pipeline depth, which is free and costs area against frequency;
//         * whether a new operation is accepted while a previous one is in
//           flight, and how deeply.
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
