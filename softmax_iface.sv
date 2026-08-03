// =============================================================================
// softmax_iface.sv  --  PORT DEFINITION ONLY (no implementation)
// =============================================================================
// Task: implement a fixed-point softmax over NUM_ELEMENTS values.
//
//        out[i] = exp(in[i]) / sum_{j} exp(in[j])
//
// This is an APPROXIMATE function in hardware. The testbench does NOT require
// bit-exactness against a floating-point exp(); it applies the explicit error
// tolerances stated at the bottom of this header. Any implementation technique
// is legal (LUT, piecewise-linear, CORDIC, shift-add exp2, Newton-Raphson
// reciprocal, ...) as long as it lands inside those tolerances.
//
// -----------------------------------------------------------------------------
// PARAMETERS
// -----------------------------------------------------------------------------
//   NUM_ELEMENTS : vector length. Legal: 4, 8, 16.
//   IN_W         : DERIVED, fixed at 16. Input element width.
//   OUT_W        : DERIVED, fixed at 16. Output element width.
//   IN_FRAC      : DERIVED, fixed at 12. Input fractional bits.
//   OUT_FRAC     : DERIVED, fixed at 16. Output fractional bits.
//   Do not override the derived parameters; they define the number formats.
//
// -----------------------------------------------------------------------------
// NUMBER FORMATS
// -----------------------------------------------------------------------------
//   INPUT  : signed Q4.12  in 16 bits (1 sign bit + 3 integer bits + 12 frac).
//            real value = $signed(raw) / 4096.0
//            representable range [-8.0, +8.0 - 2^-12], resolution 2^-12.
//
//   OUTPUT : unsigned Q0.16 in 16 bits (0 integer bits + 16 fractional bits).
//            real value = raw / 65536.0
//            representable range [0.0, 1.0 - 2^-16].
//            Note 1.0 is NOT representable: a probability of 1.0 must be
//            emitted as 16'hFFFF (the saturated maximum). The tolerances below
//            accommodate this.
//
// -----------------------------------------------------------------------------
// PORT PACKING
// -----------------------------------------------------------------------------
//   in_vec  : element i occupies bits [i*IN_W  +: IN_W ], i.e. element 0 is in
//             the least-significant 16 bits. Each element is signed Q4.12.
//   out_vec : element i occupies bits [i*OUT_W +: OUT_W]. Each element is
//             unsigned Q0.16.
//
// -----------------------------------------------------------------------------
// HANDSHAKE / TIMING CONTRACT  (identical in shape to multiplier_iface.sv)
// -----------------------------------------------------------------------------
//   rst_n is ACTIVE-LOW and SYNCHRONOUS. After reset: busy==0, done==0.
//
//   Call the cycle in which (start==1 && busy==0) is sampled at a rising clk
//   edge "cycle 0" -- that edge ACCEPTS the transaction.
//     * in_vec must be CAPTURED at that edge. It is NOT required to remain
//       stable afterwards; the testbench actively scrambles it, and the DUT
//       must still produce the right result.
//     * In cycles 1 .. L-1 : busy==1, done==0.
//     * In cycle L         : busy==1, done==1, and out_vec holds the result.
//                            done must be high for EXACTLY ONE cycle.
//     * In cycle L+1       : busy==0, done==0, and a new start may be accepted.
//   Latency L is implementation-defined, subject to
//     1 <= L <= 64*NUM_ELEMENTS + 64.
//   start asserted while busy==1 MUST BE IGNORED.
//   out_vec must be HELD STABLE from the done cycle until the next accepted
//   transaction.
//
// -----------------------------------------------------------------------------
// ACCURACY REQUIREMENTS  (the testbench checks exactly these, in Q0.16 LSBs;
//                         1 LSB = 2^-16 = 0.0000152587890625)
// -----------------------------------------------------------------------------
//   Let p[i] be the exact real softmax of the exact real input values, and
//   let o[i] = out_vec element i (an integer count of Q0.16 LSBs).
//
//   A1. PER-ELEMENT ABSOLUTE ERROR
//         | o[i] - p[i]*65536 |  <=  656 LSB    (i.e. 0.01 absolute)
//       for every i. Absolute (not relative) error is used because relative
//       error is meaningless for the near-zero outputs that dominate a softmax.
//
//   A2. NORMALISATION
//         | (sum over i of o[i]) - 65536 |  <=  1312 LSB   (i.e. 0.02)
//       The outputs must actually form a probability distribution.
//
//   A3. TIE CONSISTENCY
//       If in[i] == in[j] (identical raw input words) then
//         | o[i] - o[j] |  <=  64 LSB
//       Equal inputs must produce equal outputs to within rounding.
//
//   A4. ORDER PRESERVATION
//       If in[i] > in[j] (as signed Q4.12) then
//         o[i]  >=  o[j] - 1312 LSB
//       A larger input may never map to a meaningfully smaller probability.
//
//   A5. SHIFT INVARIANCE
//       softmax(x + c) == softmax(x) for any constant c. The testbench applies
//       shifts that keep every element inside the representable input range and
//       requires the two output vectors to agree within 1312 LSB per element.
//
//   No output may exceed 16'hFFFF (structurally guaranteed by the port width).
// =============================================================================

module softmax #(
    parameter int NUM_ELEMENTS = 8,   // 4 / 8 / 16
    // derived -- do not override; these define the fixed-point formats
    parameter int IN_W         = 16,
    parameter int OUT_W        = 16,
    parameter int IN_FRAC      = 12,
    parameter int OUT_FRAC     = 16
) (
    input  logic                            clk,
    input  logic                            rst_n,

    input  logic                            start,
    input  logic [NUM_ELEMENTS*IN_W-1:0]    in_vec,   // signed Q4.12 per element

    output logic                            busy,
    output logic                            done,     // one-cycle pulse
    output logic [NUM_ELEMENTS*OUT_W-1:0]   out_vec   // unsigned Q0.16 per element
);

    // IMPLEMENTATION INTENTIONALLY OMITTED.

endmodule
