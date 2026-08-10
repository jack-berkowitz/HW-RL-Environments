// =============================================================================
// multiplier_iface.sv  --  PORT DEFINITION ONLY (no implementation)
// =============================================================================
// Task: implement an integer multiplier with a start/done handshake.
//
// -----------------------------------------------------------------------------
// PARAMETERS
// -----------------------------------------------------------------------------
//   BIT_WIDTH   : operand width in bits. Legal: 8, 16, 32.
//   SIGNED_MODE : 0 = a and b are UNSIGNED  -> product is unsigned
//                 1 = a and b are TWO'S COMPLEMENT SIGNED -> product is signed
//   PROD_W      : DERIVED. Do not override. PROD_W = 2*BIT_WIDTH.
//
// -----------------------------------------------------------------------------
// FUNCTION
// -----------------------------------------------------------------------------
//   product must be the EXACT full-width product of a and b. It is never
//   truncated, rounded or saturated -- 2*BIT_WIDTH bits always suffice.
//
//   SIGNED_MODE == 0 : product = a * b, both operands in [0, 2^BIT_WIDTH - 1].
//                      Result range [0, (2^BIT_WIDTH - 1)^2].
//   SIGNED_MODE == 1 : product = a * b interpreted as two's complement, both
//                      operands in [-2^(BIT_WIDTH-1), 2^(BIT_WIDTH-1) - 1],
//                      product in two's complement over PROD_W bits.
//                      Note the corner case min*min = +2^(2*BIT_WIDTH-2), which
//                      is representable in PROD_W bits and must NOT overflow.
//                      Likewise min * -1 = +2^(BIT_WIDTH-1) must be positive.
//
// -----------------------------------------------------------------------------
// HANDSHAKE / TIMING CONTRACT
// -----------------------------------------------------------------------------
//   rst_n is ACTIVE-LOW and SYNCHRONOUS. After reset: busy==0, done==0.
//
//   Call the cycle in which (start==1 && busy==0) is sampled at a rising clk
//   edge "cycle 0" -- that edge ACCEPTS the transaction.
//     * a and b must be CAPTURED at that edge. They are NOT required to remain
//       stable afterwards; the testbench actively drives them to unrelated
//       values in later cycles, and the DUT must still produce the right result.
//     * In cycles 1 .. L-1 : busy==1, done==0.
//     * In cycle L         : busy==1, done==1, and `product` holds the result.
//                            done must be high for EXACTLY ONE cycle.
//     * In cycle L+1       : busy==0, done==0, and a new start may be accepted.
//   The latency L is chosen by the implementation and may vary, subject to
//   1 <= L <= 4*BIT_WIDTH + 8. (So a fully-combinational multiply registered
//   once, a pipelined tree, or an iterative shift-add are all legal.)
//
//   start asserted while busy==1 MUST BE IGNORED: it may not corrupt the
//   in-flight transaction and may not enqueue a second one.
//
//   `product` must be HELD STABLE from the cycle done is asserted until the
//   next transaction is accepted.
//
//   Only ONE transaction may be in flight at a time; the DUT is not required to
//   accept a new operand pair before done.
// =============================================================================

module multiplier #(
    parameter int BIT_WIDTH   = 16,  // 8 / 16 / 32
    parameter int SIGNED_MODE = 1,   // 0 = unsigned, 1 = signed
    // derived -- do not override
    parameter int PROD_W      = 2*BIT_WIDTH
) (
    input  logic                 clk,
    input  logic                 rst_n,

    input  logic                 start,
    input  logic [BIT_WIDTH-1:0] a,
    input  logic [BIT_WIDTH-1:0] b,

    output logic                 busy,
    output logic                 done,     // one-cycle pulse
    output logic [PROD_W-1:0]    product
);

    // IMPLEMENTATION INTENTIONALLY OMITTED.

endmodule
