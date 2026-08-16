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
//   2. THROUGHPUT AS A CAPABILITY, NOT A SPEED. See C3. Latency is free;
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
//        * UNDERFLOW is raised only when the result is tiny AFTER rounding AND
//          inexact. A tiny but exact result does NOT raise it. (IEEE permits
//          detecting tininess before rounding; this task requires after -- see
//          A6.)
//        * OVERFLOW always raises `inexact` as well.
//        * `invalid` always yields the canonical quiet NaN as the result.
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
//   A6. TININESS IS DETECTED AFTER ROUNDING. A result that is tiny before
//       rounding but rounds up to the smallest normal is NOT underflow. The
//       vector set contains cases where before- and after-rounding detection
//       disagree, so this is checked and not merely stated.
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
//       *** LATENCY IS NOT CONSTRAINED AND NOT CHECKED. *** Pipeline as deeply
//       as you like. C3 constrains only how often a new operation can START.
//       The distinction between DELAY (free) and RATE (required) is the whole
//       of this requirement.
//
//       Raw throughput in results per cycle is REPORTED as a METRIC and never
//       gates: it is the product of rate, latency and stalling, and gating it
//       would fail a correct design that trades speed for area.
//
// -----------------------------------------------------------------------------
// HANDSHAKE
// -----------------------------------------------------------------------------
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
