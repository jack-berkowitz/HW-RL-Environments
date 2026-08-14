// =============================================================================
// int8_requant_iface.sv  --  PORT DEFINITION ONLY (no implementation)
// =============================================================================
// Task: implement INT32 -> INT8 requantisation, the fixed-point rescaling stage
// that sits between an integer MAC array and the next quantised layer.
//
// For each lane independently:
//
//        result = clamp( RSHIFT( DHIMUL(acc, mult), shift ) + zp,
//                        -128, +127 )
//
// where DHIMUL and RSHIFT are defined EXACTLY in "ARITHMETIC" below. This is a
// BIT-EXACT task: there is no error tolerance. Every legal input has exactly
// one correct output, and the checker compares against it exactly.
//
// -----------------------------------------------------------------------------
// PARAMETERS
// -----------------------------------------------------------------------------
//   LANES : number of independent requantisation lanes. Legal: 1, 2, 4, 8.
//           Any other value is ILLEGAL and need not be handled.
//           Lanes are fully independent -- there is no interaction between them
//           and no cross-lane reduction of any kind.
//
// -----------------------------------------------------------------------------
// PORT PACKING
// -----------------------------------------------------------------------------
//   Lane i occupies the i-th slice of each vector, lane 0 in the least
//   significant bits:
//     acc    : lane i = acc   [i*32 +: 32]   signed  int32
//     mult   : lane i = mult  [i*32 +: 32]   signed  int32, see PRECONDITIONS
//     shift  : lane i = shift [i*5  +:  5]   unsigned, 0..31
//     zp     : lane i = zp    [i*8  +:  8]   signed  int8
//     result : lane i = result[i*8  +:  8]   signed  int8
//   Every input is PER-LANE, including the zero point -- this is per-channel
//   requantisation, so each lane carries its own scale, shift and zero point.
//
// -----------------------------------------------------------------------------
// PRECONDITIONS ON INPUTS  (guaranteed by the caller -- do NOT add logic to
//                           police these; behaviour when violated is
//                           unconstrained and is never checked)
// -----------------------------------------------------------------------------
//   P1. mult is NORMALISED:  2^30 <= mult <= 2^31 - 1.  Always strictly
//       positive. (This is the standard normalised fixed-point multiplier: a
//       Q0.31 value in [0.5, 1.0).)
//   P2. shift is in 0..31. All 32 encodings of the 5-bit field are legal.
//   P3. zp is a signed int8 in [-128, +127], independently per lane.
//   P4. acc may be ANY signed int32, including INT32_MIN and INT32_MAX.
//
// -----------------------------------------------------------------------------
// ARITHMETIC  -- normative. Implement exactly this; any technique is legal.
// -----------------------------------------------------------------------------
// All intermediate arithmetic below is EXACT (no truncation) unless a step
// says otherwise. A 64-bit product is sufficient throughout.
//
//   STEP 1 -- DHIMUL(acc, mult):  doubling high multiply, rounded.
//
//       p     = acc * mult                       // exact signed 64-bit
//       nudge = (p >= 0) ?  2^30
//                        : (1 - 2^30)            // NOTE the +1. It matters.
//       DHIMUL = (p + nudge) / 2^31              // division TRUNCATES TOWARD
//                                                // ZERO, not toward -infinity
//
//       Conceptually this computes acc * (mult / 2^31) -- i.e. scaling by a
//       Q0.31 fraction -- and rounds the result to an integer.
//
//       ** TIE RULE, STEP 1: exact halves round toward POSITIVE INFINITY. **
//            +3.5 -> +4      -3.5 -> -3
//            +4.5 -> +5      -4.5 -> -4
//       That asymmetry is produced by the "+1" in the negative nudge combined
//       with truncation toward zero. It is deliberate. Do not "fix" it into a
//       symmetric rule -- and note it is NOT the same rule as step 2.
//
//       Non-tie values round to nearest in the ordinary symmetric way.
//
//   STEP 2 -- RSHIFT(x, shift):  arithmetic right shift, rounded.
//
//       if shift == 0:  RSHIFT = x
//       else:
//           mask      = (1 << shift) - 1
//           remainder = x & mask                 // two's-complement AND
//           threshold = (mask >> 1) + (x < 0 ? 1 : 0)
//           RSHIFT    = (x >>> shift) + ((remainder > threshold) ? 1 : 0)
//                       // >>> is ARITHMETIC (sign-extending) right shift
//
//       ** TIE RULE, STEP 2: exact halves round AWAY FROM ZERO. **
//            +1.5 -> +2      -1.5 -> -2
//            +2.5 -> +3      -2.5 -> -3
//       This IS symmetric about zero, unlike step 1. The "+1" added to the
//       threshold for negative x is what makes it symmetric; dropping it turns
//       the rule into round-half-toward-zero for negatives.
//
//   STEP 3 -- bias:      biased = RSHIFT_result + zp   (this lane's zp)
//                        (exact; may transiently exceed the int8 range)
//
//   STEP 4 -- clamp:     result = min(127, max(-128, biased))
//                        SATURATING, never wrapping. A biased value of +200
//                        becomes +127, NOT -56.
//
//   The two steps use DIFFERENT tie rules on purpose. A design that applies one
//   uniform rounding mode to both will be correct on most inputs and wrong on
//   exact ties, which is precisely what the checker looks for.
//
// -----------------------------------------------------------------------------
// HANDSHAKE CONTRACT
// -----------------------------------------------------------------------------
//   Standard valid/ready on both sides. A BEAT transfers on a rising clk edge
//   at which valid && ready are both high.
//
//   H1. in_ready MUST NOT depend combinationally on in_valid. (out_ready may
//       influence in_ready; that is a legal backpressure path.) This forbids
//       the combinational loop, not backpressure.
//   H2. Once in_valid is asserted it must remain asserted until the beat is
//       accepted, and acc/mult/shift/zp must remain stable across that time.
//       The checker honours this; you may rely on it.
//   H3. When out_valid is high and out_ready is low, out_valid must REMAIN high
//       and `result` must remain STABLE until the beat is accepted. No dropping
//       and no re-ordering under backpressure.
//   H4. ORDERING: results are emitted in exactly the order the inputs were
//       accepted. Beat N in produces beat N out.
//   H5. No input beat may be dropped, duplicated, or reordered.
//
// -----------------------------------------------------------------------------
// LATENCY
// -----------------------------------------------------------------------------
//   Latency is IMPLEMENTATION-DEFINED and is NOT checked. Pipeline it, or don't.
//   The only requirement is liveness with an upper bound: within 64 cycles of an
//   input beat being accepted, the corresponding output beat must become
//   AVAILABLE (out_valid high for it).
//
//   That bound is measured to AVAILABILITY, not to acceptance. Time spent
//   waiting because the consumer is holding out_ready low does NOT count against
//   it -- backpressure is the consumer's choice, not a latency failure.
//
//   Throughput is NOT constrained. A design accepting one beat every 8 cycles is
//   correct (it will simply score worse on nothing -- throughput is not scored).
//   The checker never asserts an exact cycle count.
//
// -----------------------------------------------------------------------------
// RESET
// -----------------------------------------------------------------------------
//   rst_n is ACTIVE-LOW and SYNCHRONOUS.
//
//   R1. While rst_n is low, and in the first cycle after it is released:
//         out_valid == 0.
//   R2. in_ready may be 0 or 1 after reset -- both are legal. If 0, it must
//       become 1 within 64 cycles with no input offered.
//   R3. Reset asserted mid-stream DISCARDS all in-flight work. After release,
//       the very next accepted beat is treated as beat 0 of a fresh stream:
//       no stale result may be emitted, and the ordering guarantee (H4)
//       restarts. `result` content while out_valid == 0 is a don't-care.
//
// =============================================================================

module int8_requant #(
    parameter int LANES = 4          // 1 / 2 / 4 / 8
) (
    input  logic                  clk,
    input  logic                  rst_n,

    // input stream
    input  logic                  in_valid,
    output logic                  in_ready,
    input  logic [LANES*32-1:0]   acc,          // signed int32 per lane
    input  logic [LANES*32-1:0]   mult,         // signed int32 per lane, >= 2^30
    input  logic [LANES*5-1:0]    shift,        // unsigned 0..31 per lane
    input  logic [LANES*8-1:0]    zp,           // signed int8 per lane

    // output stream
    output logic                  out_valid,
    input  logic                  out_ready,
    output logic [LANES*8-1:0]    result        // signed int8 per lane
);

    // IMPLEMENTATION INTENTIONALLY OMITTED.

endmodule
