# Task: implement an IEEE-754 binary32 fused multiply-add in SystemVerilog

You are given a **port map and a complete specification**. Write the RTL. You
will not be shown any reference implementation.

Your answer is run against a checker on a **single configuration** — this module
declares no parameters — and must pass every one of its 4340 directed and random
vectors. It is also synthesised, so it must be legal SystemVerilog for two
different frontends.

**The difficulty is bit-exactness across the corner space, not the algorithm.**
Every result is compared bit for bit against an external reference, and so are
all four exception flags. Three things break designs here. The operation is
FUSED: there is exactly one rounding, of the exact product-plus-addend, and
`round(round(a*b) + c)` differs on a large fraction of inputs. Subnormals are
handled at full precision as operands and as results; flush-to-zero fails on the
vectors, not on a rate. And the underflow flag is pinned longhand in A6 — read
it rather than assuming a convention, because the two readings of "tininess
after rounding" disagree and this task pins one of them explicitly.

## What to submit

**One self-contained file** containing only `module fp32_fma_ii1`, with the
exact port list below. No package, no include, nothing outside the file.

```systemverilog
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
//       against d_ca04's 20101 -- so a lower Fmax at comparable depth is
//       arithmetic, not a defect, and comparing frequencies across tasks was
//       never meaningful. Fmax is compared BETWEEN SUBMISSIONS TO ONE TASK,
//       which is what rule 18 pins the configuration to make possible.
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
//   H2. Once `in_valid` is asserted the producer holds it, and holds the
//       operands stable, until accepted. The checker honours this.
//   H3. When `out_valid` is high and `out_ready` is low, `out_valid` must
//       remain high and the result and flags must remain stable.
//   H4. Results are returned IN ORDER. This is not a reordering unit.
//
// -----------------------------------------------------------------------------
// RESET
// -----------------------------------------------------------------------------
//   R1. `rst_n` is ACTIVE-LOW and SYNCHRONOUS.
//   R2. While `rst_n` is low, `out_valid` is 0.
//   R3. Reset discards work in flight; no result from before reset may appear
//       afterwards.
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
```
