// =============================================================================
// fp32_fma_ii1_iface.sv  --  PORT DEFINITION ONLY (no implementation)
// =============================================================================
// Task: implement an IEEE-754 binary32 FUSED multiply-add, (a * b) + c, with a
// SINGLE rounding of the exact product-sum, sustaining an initiation interval
// of one.
//
// *** TWO REQUIREMENTS CARRY THIS TASK, AND NEITHER IS "GET THE ARITHMETIC
// ROUGHLY RIGHT". ***
//
//   1. BIT-EXACTNESS ACROSS THE CORNER SPACE. Subnormals, the five rounding
//      modes, NaN payloads, signed zero and the tininess boundary are all
//      checked against externally-authored reference RTL. A unit that is
//      correct on normal operands and flushes subnormals, or that honours only
//      round-to-nearest-even, fails.
//
//   2. THROUGHPUT AS A CAPABILITY, NOT A SPEED. See C3. Latency is PINNED
//      at 3 cycles by S1 for scoring;
//      accepting a new operation every cycle is required.
//
// -----------------------------------------------------------------------------
// PARAMETERS
// -----------------------------------------------------------------------------
//   There are no free parameters. The format is binary32 and the interface is
//   fixed. RND_MODE is a RUNTIME INPUT, not a parameter, and every one of the
//   five modes must be honoured -- see R1.
//
// -----------------------------------------------------------------------------
// ARITHMETIC -- normative
// -----------------------------------------------------------------------------
//   A1-A9 ARE CHECKED ANONYMOUSLY. Every arithmetic clause below is observed by
//       the same two comparisons -- result against the reference, and flags
//       against the reference -- and NEITHER MESSAGE CARRIES A CLAUSE ID. So a
//       failure tells you a vector disagreed, not which clause it disagreed
//       with. That is a property of this rig, not of the clauses, and it is
//       stated here so the absence of A-ids in failure output is not read as the
//       A-clauses being unchecked.
//
//   A1. RESULT = round( a*b + c ), where the product a*b is NOT rounded before
//       the addition. There is exactly ONE rounding, applied to the exact
//       product-sum.
//
//       The discriminating case, and it is in the vector set: with
//       a = b = 1 + 2^-12, the exact product is 1 + 2^-11 + 2^-24. The 2^-24
//       term lies beyond the 23-bit mantissa. A unit that rounds the product
//       first loses it, and a subsequent c = -(1 + 2^-11) cancels to exactly
//       ZERO. A fused unit returns 2^-24. Those are different answers.
//
//   A2. ALL FIVE IEEE ROUNDING MODES, selected at runtime by `rnd_mode`:
//         0 RNE  round to nearest, ties to even
//         1 RTZ  round toward zero
//         2 RDN  round toward -infinity
//         3 RUP  round toward +infinity
//         4 RMM  round to nearest, ties away from zero
//       Values 5-7 are OUT OF SCOPE, are never driven, and their behaviour is
//       unconstrained. (The vendored anchor also defines ROD, RSR and DYN;
//       those are not part of this contract.)
//
//   A3. SUBNORMALS ARE HANDLED IN THE PIPELINE. Subnormal operands and
//       subnormal results are computed exactly, at full rate. FLUSH-TO-ZERO IS
//       A FAILURE, and so is a slow path that stalls on them -- the latter
//       fails C3 rather than A3.
//
//   A4. NaN -- PINNED, because IEEE-754 does NOT settle this.
//
//       *** EVERY NaN RESULT IS THE CANONICAL QUIET NaN, EXACTLY 32'h7FC00000. ***
//
//       This holds whatever produced it: a signalling NaN operand, a quiet NaN
//       operand, Inf - Inf, or 0 * Inf. Operand payloads are NOT propagated and
//       the sign bit of a NaN result is always 0.
//
//       IEEE-754 only *recommends* payload propagation; it does not mandate it,
//       and an FMA that propagates an operand's payload is equally conformant.
//       RISC-V mandates the canonical NaN, and this task follows RISC-V. IT IS
//       STATED HERE SO THAT IT IS A CONTRACT TERM RATHER THAN SOMETHING A
//       DESIGN HAS TO GUESS from the reference's behaviour.
//
//       A signalling NaN operand additionally raises `invalid`. A quiet NaN
//       operand alone does not.
//
//   A4b. THE OTHER IMPLEMENTATION-DEFINED CHOICES, pinned for the same reason:
//
//        * OVERFLOW always raises `inexact` as well.
//          AUTHORITY: IEEE 754-2019 clause 7.4.
//        * `invalid` always yields the canonical quiet NaN as the result.
//          AUTHORITY: PINNED BY THIS TASK -- see A4.
//        * UNDERFLOW is pinned by A6 below, longhand, and cites no standard.
//
//        Each of these was verified against the reference across the vector set
//        rather than assumed: 103 underflow cases all inexact and none exact,
//        no overflow without inexact, no invalid without a NaN result, and one
//        single NaN pattern across all 188 NaN results.
//
//   A5. SPECIAL VALUES. Inf - Inf and 0 * Inf raise `invalid` and return a
//       quiet NaN. Signed zero follows IEEE: (-0) + (+0) is +0 in every mode
//       EXCEPT RDN, where it is -0.
//
//   A6. UNDERFLOW -- PINNED BY THIS TASK. NO STANDARD IS CITED AS AUTHORITY,
//       DELIBERATELY; see "why this is written out longhand" below.
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
//       SCOPE NOTE. This module's format is binary32. The FP16 and BF16 rows
//       are shown because the SAME convention is pinned across this project's
//       floating-point tasks and the rule is not binary32-specific -- they are
//       not a requirement on this module, which never sees those formats.
//
//   A7. EXCEPTION FLAGS: `invalid`, `overflow`, `underflow`, `inexact`. Every
//       flag is compared bit-exactly on every vector. There is no divide-by-
//       zero flag -- an FMA cannot raise it.
//
// -----------------------------------------------------------------------------
// C3 -- SUSTAINED ACCEPTANCE RATE, normative and checked
// -----------------------------------------------------------------------------
//   C3. INITIATION INTERVAL OF ONE. With operands offered continuously and
//       results always accepted, the unit must accept a new operation EVERY
//       CYCLE, with no dead cycle.
//
//       K = 1 comes from what this block is FOR: it is the inner cell of a MAC
//       array, and a unit that stalls is unusable in that role. It is not
//       derived from measuring any implementation.
//
//       C3 constrains only how often a new operation can START. The
//       distinction between DELAY and RATE is the whole of this requirement.
//
// -----------------------------------------------------------------------------
// S1 -- THE SCORED CONFIGURATION, normative (rule 18)
// -----------------------------------------------------------------------------
//
//   S1. LATENCY IS PINNED AT 3 CYCLES. A submission shall produce its result
//       exactly 3 clocks after the operands are accepted, sustaining C3's
//       initiation interval of one.
//
//       PPA, latency and throughput are measured ONLY at this configuration.
//       Correctness is unaffected -- the checker verifies the contract, not the
//       depth, and continues to accept any implementation that meets it. This
//       is a SPEC requirement, so building at another depth fails something you
//       were told rather than a hidden assumption.
//
//       *** THIS SUPERSEDES THE EARLIER "LATENCY IS NOT CONSTRAINED" CLAUSE. ***
//       That wording freed an axis whose value is not what this task measures.
//       What is being measured is the ALIGNMENT, NORMALISATION AND ROUNDING
//       STRUCTURE, and pinning depth leaves all of it intact -- a submission
//       still chooses how to align, how to normalise, how to round, and how to
//       distribute its logic across the three stages.
//
//       AUTHORITY FOR THE VALUE (rule 15): the dataflow of an FMA has four
//       natural segments -- classify-and-multiply, align-and-add,
//       normalise (leading-zero count then shift), and round. Three register
//       boundaries is the shallowest depth that places one boundary between
//       each pair, so no segment spans two of them.
//
//       It is NOT chosen because the anchor defaults to it. The anchor's shim
//       bound 0; three is derived from the structure above and from measurement:
//       at depth 0 the design is one combinational cone that MISSES TIMING AT
//       30 ns, so roughly 33 MHz or worse. No submission would ship that, and a
//       baseline nobody would ship measures nothing. Three segments the cone
//       into four.
//
//       MEASURED, AND ONE CLAIM HERE WAS WRONG. This previously read "the
//       shallowest split that clocks competitively against the other tasks
//       here (d_nw01 190 MHz, d_ca04 380 MHz)". The sweep returned
//       78.05 MHz at 12.8125 ns, which is NOT competitive with those, so that
//       clause was a prediction the measurement does not support and it is
//       withdrawn.
//
//       What the measurement does establish: three registers take the design
//       from below 33 MHz to 78 MHz, a 2.4x improvement rather than the ~4x an
//       even four-way split would give. The boundaries land unevenly -- the
//       longest segment still carries about 12.8 ns of logic -- which is a fact
//       about where cvfpu places its DISTRIBUTED registers, not about the
//       choice of depth.
//
//       THE CHOICE STANDS, AND HERE IS WHAT IS CARRYING IT. 78 MHz next to
//       d_nw01's 190 and d_ca04's 380 is the first thing a reader will notice,
//       so the justification is stated rather than left implied.
//
//       CRITERION 1, REPRESENTATIVE OF REAL USE. A pipelined FMA is what ships;
//       a combinational one is not built. Depth 3 is a normal depth for a
//       single-precision FMA in a MAC array, which is the role C3's II=1
//       requirement comes from. The alternative bindings are not more
//       representative -- they are faster or smaller, which is a different
//       property.
//
//       CRITERION 2, EXERCISES THE INTERESTING PART OF THE DESIGN SPACE. This
//       is the one doing the most work here. What this task measures is the
//       ALIGNMENT, NORMALISATION AND ROUNDING STRUCTURE -- the second source
//       needed three attempts to get alignment right, and the mutant set is
//       almost entirely about rounding, tininess, NaN payloads and signed zero.
//       Depth 3 leaves every one of those choices open to a submission: it
//       constrains WHERE the registers fall, not how any of the arithmetic is
//       built. Pinning depth costs the task nothing it was measuring.
//
//       WHY THE FREQUENCY IS NOT THE POINT. An FMA is a far larger
//       combinational block than a FIFO or a crossbar datapath -- 68303 um2
//       against d_ca04's 20101 -- so a lower achievable frequency at comparable
//       depth is arithmetic, not a defect, and comparing frequencies across
//       tasks was never meaningful.
//
//       Nor is frequency compared BETWEEN submissions to this task. That
//       sentence stood here and is withdrawn: Fmax is not a scored axis at all
//       (see G2). Every submission is built at one pinned period and compared on
//       area, power and this task's own axes there. What rule 18 pins the
//       configuration for is to make THOSE comparable, not to make a frequency
//       race fair.
//
//       Criterion 3 -- closes with margin at a period a plausible alternative
//       can also hit -- is met: 12.8125 ns with +0.27 ns slack and DRC clean.
//       Criterion 4 is met by construction, as above.
//
//       Deeper would also clock well and is deliberately not chosen: it costs
//       registers for a rate C3 already guarantees, and the task is not about
//       finding the fastest FMA.
//
//   S1a. REGISTER PLACEMENT WITHIN THE THREE STAGES IS NOT CONSTRAINED.
//       Depth is pinned; where the logic sits between the boundaries is a
//       design choice and is neither checked nor scored.
//
//       Raw throughput in results per cycle is REPORTED as a METRIC and never
//       gates: it is the product of rate, latency and stalling, and gating it
//       would fail a correct design that trades speed for area.
//
// -----------------------------------------------------------------------------
// HANDSHAKE
// -----------------------------------------------------------------------------
//   A9. "AS IF UNBOUNDED" IS A STATEMENT ABOUT THE RESULT, NOT A DATAPATH
//       WIDTH. The exact value of a*b + c must be rounded ONCE; it does NOT
//       have to be CARRIED in hardware.
//
//       BOUND: the internal significand datapath **shall not exceed 96 bits**
//       (4*p, where p = 24 is binary32's significand precision including the
//       implicit bit). Information below that window is collapsed into a
//       sticky bit. A wider datapath is NON-CONFORMING.
//
//       WHY 4*p AND NOT TIGHTER. Correct single rounding needs the 48-bit
//       product, the addend aligned against it, and room below for full
//       cancellation; roughly 3*p plus guard, round and sticky suffices. 4*p
//       is deliberately GENEROUS so no correct implementation is excluded by a
//       bound chosen to be clever, and it was set from that argument rather
//       than from any implementation. For reference only, and consulted AFTER
//       the number was fixed: the three submissions to this task use 32, 48
//       and 76 bits, so none is affected.
//
//       WHY THE CLAUSE EXISTS. On the sibling multi-format task a submission
//       read the same IEEE phrase as an instruction to build an unbounded
//       datapath -- 448 bits, five registers of that width, and a 448-iteration
//       linear leading-one search. Arithmetically correct, passed every vector,
//       and measured about 14,700,000 um2. A specification that names an
//       exactness requirement and bounds none of the resources delivering it
//       makes unlimited spending conforming.
//
//   H1. `in_ready` MUST NOT depend combinationally on `in_valid`.
//       CHECKED, in cycle. The checker toggles `in_valid` BETWEEN clock edges
//       and requires `in_ready` not to move: a combinational path shows up
//       immediately, a registered one cannot. The probe carries a vacuity
//       guard, because an `in_ready` that is low whatever `in_valid` does could
//       not have moved either way and would prove nothing. Nothing is accepted
//       during the probe -- the pulse is withdrawn before the next posedge.
//
//       IT WAS ENFORCED BY NOTHING UNTIL THIS PROBE EXISTED, and no other check
//       could have caught it: a transfer still happens exactly when both
//       signals are high, so every vector, flag, latency and II=1 result is
//       unchanged by the violation.
//   H1b. REPORTED UNDER H3. The check that observes this -- "out_valid dropped
//       while the result was unaccepted (H3)", and result or flags changing
//       under backpressure -- is the same comparison that observes H3, and H3
//       carries its own never-exercised guard.
//
//       `out_valid` MUST NOT depend combinationally on `out_ready`. The
//       consumer may hold `out_ready` low indefinitely, and a design that waits
//       for it before asserting `out_valid` deadlocks against a consumer that
//       waits for `out_valid` before asserting `out_ready`.
//
//       This is H1's rule with the roles swapped, and it is stated because H3
//       is otherwise satisfiable by NEVER OFFERING: a result that is never
//       presented to a stalled consumer cannot be withdrawn from one. H3
//       constrains what happens once a result is offered; H1b is what makes H3
//       reachable. Measured, not argued -- `controls/nc_h3_evades_antecedent.sv`
//       gates `out_valid` on `out_ready`, satisfies every clause as the contract
//       stood before this one, and drives the H3 checker's firing count to zero.
//       AUTHORITY: stated task intent.
//   H2. Once `in_valid` is asserted the producer holds it, and holds the
//       operands stable, until accepted. The checker honours this.
//   H3. When `out_valid` is high and `out_ready` is low, `out_valid` must
//       remain high and the result and flags must remain stable.
//   H4. CHECKED, BUT ITS FAILURE NAMES NO CLAUSE. The result comparison walks
//       the vector set in order, so a reordered result is compared against the
//       wrong vector and fails as "vector %0d: ... result %08h, reference says
//       %08h" -- a message carrying no clause id at all. It is neither grouped
//       under another clause nor unchecked; it is checked anonymously.
//
//       Results are returned IN ORDER. This is not a reordering unit.
//
// -----------------------------------------------------------------------------
// RESET
// -----------------------------------------------------------------------------
//   R1. `rst_n` is ACTIVE-LOW and SYNCHRONOUS.
//   R2. While `rst_n` is low, `out_valid` is 0.
//   R3. REPORTED UNDER R2. A result surviving a reset surfaces as "out_valid
//       asserted while rst_n low (R2)". R3 states the requirement; R2 is where
//       breaking it is reported.
//
//       Reset discards work in flight; no result from before reset may appear
//       afterwards.
// -----------------------------------------------------------------------------
// TOOL REQUIREMENTS -- stated, because a submission cannot pass what it is not told
// -----------------------------------------------------------------------------
//   T1. THE SUBMISSION MUST ELABORATE UNDER BOTH slang AND Verilator.
//       Simulation runs on Verilator; physical synthesis reads the same file
//       with slang. They disagree about what is legal, so a file one accepts and
//       the other rejects cannot be built -- and a submission that cannot be
//       built produces NO PPA NUMBER AT ALL, recorded as a failure rather than
//       as a missing measurement. One frontend accepting a file does not make
//       it legal.
//
//       THIS TASK CARRIED NO SUCH CLAUSE UNTIL NOW, and it has two recorded
//       deaths from a slang-only error while telling submitters nothing about
//       slang being in the path. That is the defect this clause closes.
//
//   T2. DECLARE EVERY VARIABLE BEFORE THE FIRST STATEMENT IN ITS PROCEDURAL
//       BLOCK. slang enforces the LRM rule that every declaration in a block
//       precedes every statement in that block, and VERILATOR DOES NOT DIAGNOSE
//       THE VIOLATION. The file therefore simulates clean and then yields NO PPA
//       NUMBER AT ALL -- it reads as a missing measurement rather than as a
//       rejected submission, which is the worst shape a failure can take here.
//       Declare every variable at the top of the block that uses it, or at
//       module scope, before any assignment, loop or $display in that block.
//
//       MEASURED HISTORY, NOT CAUTION. Ten run records across four tasks in this
//       repository were killed by exactly
//           error: declaration must come before all statements in the block
//       nine of them from one model, and TWO OF THE TEN ARE THIS TASK'S.
//
// -----------------------------------------------------------------------------
// G. GRADING -- how a submission is judged, and against what
// -----------------------------------------------------------------------------
//   G1. THE ORDER. Correctness is a GATE, not a weighting.
//
//       1. CORRECTNESS, bit-exact. Every delivered result and every exception
//          flag is compared against the reference for the same operand stream.
//          There is no partial credit and no tolerance: a result one ulp out
//          fails exactly as a result that is nonsense fails, and a wrong
//          `inexact` bit fails as surely as a wrong mantissa.
//
//       2. THE GATE. A submission that fails correctness, or that fails to
//          build, produces NO PPA NUMBER AT ALL. It is recorded as a failure
//          and scores zero on every PPA axis -- not as a missing measurement.
//
//       3. PPA, measured only for submissions that already passed, ONCE AT A
//          PINNED CLOCK PERIOD.
//          The pinned period is 19.25 ns on sky130hd. It is derived as 1.5x the
//          reference implementation's own measured period (12.8125 ns), rounded
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
//
//       Latency and initiation interval are ALSO reported, but as CONFORMANCE
//       CHECKS rather than as axes: they have expected values and a submission
//       either meets them or fails. See G3.
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
//   G3. WHAT IS NOT AVAILABLE TO OPTIMISE. This contract is unusually tight,
//       and every lever a floating-point design normally trades is already
//       spent. Read this before choosing a micro-architecture.
//
//         * LATENCY IS PINNED AT 3 CYCLES by S1. It is not a metric to
//           minimise and not a budget to spend. Adding a pipeline stage to
//           shorten the critical path CHANGES THE OBSERVABLE SCHEDULE and fails.
//           You cannot buy frequency with depth here -- the usual trade is not
//           on offer.
//         * THROUGHPUT IS PINNED AT ONE RESULT PER CYCLE by C3. There is no
//           rate to raise and none to give up. An iterative unit that takes the
//           same area and answers every fourth cycle is wrong, not cheaper.
//         * THE ARITHMETIC IS PINNED TO THE BIT by A1-A7, including the NaN
//           payload rule (A4) and the underflow rule (A6), which this task pins
//           itself because no standard settles them. There is no
//           accuracy-for-area trade.
//         * THE SIGNIFICAND DATAPATH HAS A CEILING. A9 bounds it at 96 bits.
//           "As if unbounded" describes the RESULT, not the hardware; a design
//           that carries the full unbounded intermediate is wrong, not generous.
//         * THE HANDSHAKE IS PINNED. H1 forbids `in_ready` depending
//           combinationally on `in_valid`, and H4 requires in-order results.
//
//   G4. WHAT IS ACTUALLY LEFT. The contract fixes WHAT is delivered, WHEN, and
//       to the bit. What remains is entirely micro-architectural, and it is
//       where the whole PPA difference comes from:
//
//         * how the multiplier is built -- array, Booth-encoded, compressed --
//           and how the partial products are reduced;
//         * how alignment, addition, normalisation and rounding are structured
//           across the three pinned stages, and what is registered where;
//         * how much logic is shared between the subnormal and normal paths,
//           given A3 requires subnormals handled in the pipeline;
//         * how the five rounding modes are implemented -- a common rounder or
//           separate paths;
//         * how the flag logic is derived, given A7 requires all five flags.
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

`timescale 1ns/1ps

module fp32_fma_ii1 (
    input  logic        clk,
    input  logic        rst_n,

    // ---- operand input ------------------------------------------------------
    input  logic        in_valid,
    output logic        in_ready,
    input  logic [31:0] a,          // IEEE-754 binary32
    input  logic [31:0] b,
    input  logic [31:0] c,
    input  logic [2:0]  rnd_mode,   // 0 RNE, 1 RTZ, 2 RDN, 3 RUP, 4 RMM

    // ---- result output ------------------------------------------------------
    output logic        out_valid,
    input  logic        out_ready,
    output logic [31:0] result,
    output logic        flag_invalid,
    output logic        flag_overflow,
    output logic        flag_underflow,
    output logic        flag_inexact
);
endmodule
