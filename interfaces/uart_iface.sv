// =============================================================================
// uart_iface.sv  --  PORT DEFINITION ONLY (no implementation)
// =============================================================================
// Task: implement a full-duplex UART with an independent transmitter and
//       receiver sharing one clock.
//
// -----------------------------------------------------------------------------
// PARAMETERS
// -----------------------------------------------------------------------------
//   CLK_FREQ_HZ : frequency of clk, in Hz.
//   BAUD_RATE   : line rate, in bits per second.
//                 CLK_FREQ_HZ MUST be an exact integer multiple of BAUD_RATE.
//   DATA_BITS   : payload bits per frame. Legal: 7 or 8.
//   PARITY      : 0 = none, 1 = EVEN, 2 = ODD.
//   STOP_BITS   : number of stop bits. Legal: 1 or 2.
//   BIT_CYCLES  : DERIVED. Do not override.
//                 BIT_CYCLES = CLK_FREQ_HZ / BAUD_RATE = clk cycles per bit.
//                 Assume BIT_CYCLES >= 8.
//
// -----------------------------------------------------------------------------
// FRAME FORMAT (both directions)
// -----------------------------------------------------------------------------
//   Line idles HIGH. A frame is, in order:
//     1. START  : exactly one bit period LOW.
//     2. DATA   : DATA_BITS bits, LEAST-SIGNIFICANT BIT FIRST.
//     3. PARITY : present only when PARITY != 0. One bit.
//                   PARITY==1 (EVEN): parity_bit = ^data
//                                     (total number of 1s in DATA+PARITY is even)
//                   PARITY==2 (ODD) : parity_bit = ~(^data)
//     4. STOP   : STOP_BITS bit periods HIGH.
//   Total frame length = 1 + DATA_BITS + (PARITY!=0) + STOP_BITS bit periods.
//   Every bit period is EXACTLY BIT_CYCLES clk cycles long.
//
//   rst_n is ACTIVE-LOW and SYNCHRONOUS. After reset: tx_serial==1 (idle),
//   tx_busy==0, rx_valid==0.
//
// -----------------------------------------------------------------------------
// TRANSMITTER
// -----------------------------------------------------------------------------
//   tx_serial : the serial output. Idles HIGH.
//   tx_start  : a transmit is ACCEPTED on a rising clk edge where
//               (tx_start==1 && tx_busy==0). tx_data is CAPTURED at that edge
//               and is not required to remain stable afterwards (the testbench
//               scrambles it).
//   tx_busy   : must be 1 for the whole frame and must be 0 again no later than
//               2 clk cycles after the final stop bit period ends.
//   Timing    : tx_serial must go LOW (start bit) within 2 clk cycles of the
//               accepting edge. From that first LOW cycle onward, bit k of the
//               frame occupies clk cycles [k*BIT_CYCLES, (k+1)*BIT_CYCLES).
//               The line must be perfectly stable within each bit period -- the
//               testbench checks EVERY clk cycle of EVERY bit, so an off-by-one
//               in the baud divider is detected.
//   tx_start asserted while tx_busy==1 MUST BE IGNORED (no second frame queued,
//   no corruption of the frame in flight).
//   After the frame, tx_serial must return to and stay HIGH until the next
//   accepted transmit.
//
// -----------------------------------------------------------------------------
// RECEIVER
// -----------------------------------------------------------------------------
//   rx_serial : the serial input. Idles HIGH.
//
//   START DETECTION AND GLITCH REJECTION (required):
//     A falling edge on rx_serial is only a CANDIDATE start. The receiver must
//     re-sample rx_serial at the MIDPOINT of the start bit -- approximately
//     BIT_CYCLES/2 cycles after the falling edge. If rx_serial is HIGH at that
//     midpoint, the candidate is a glitch: the receiver MUST abort, MUST NOT
//     assert rx_valid, and must return to idle ready for a new start bit.
//     Consequence the testbench relies on: a LOW pulse shorter than
//     BIT_CYCLES/2 cycles never produces a frame.
//
//   SAMPLING: each subsequent bit is sampled at its midpoint, i.e. roughly
//     falling_edge + (k + 1/2)*BIT_CYCLES for bit k.
//
//   rx_valid : a ONE-CLK-CYCLE pulse marking a completed frame. It must be
//     asserted for EVERY frame that reaches its final stop bit, INCLUDING
//     frames with parity or framing errors.
//     Timing window: rx_valid must occur no earlier than the midpoint of the
//     LAST stop bit and no later than 2 bit periods after the last stop bit
//     period ends. (So all STOP_BITS stop bits must be examined before
//     reporting.)
//
//   rx_data, rx_frame_err, rx_parity_err are only meaningful in the cycle
//   rx_valid is high; the testbench samples them only then.
//     rx_data       : the DATA_BITS payload, LSB-first as received.
//     rx_frame_err  : 1 if ANY of the STOP_BITS stop bits sampled LOW.
//     rx_parity_err : 1 if PARITY!=0 and the received parity bit does not match
//                     the parity computed over the received data bits.
//                     Must be 0 when PARITY==0.
//
//   A BREAK (rx_serial held low across an entire frame) therefore produces
//   rx_valid==1 with rx_data==0 and rx_frame_err==1. The receiver must recover
//   and correctly receive the next frame once the line returns high.
//
//   Back-to-back frames (a new start bit in the very next bit period after the
//   last stop bit) must be received correctly.
//
//   The transmitter and receiver are INDEPENDENT: receiving must not disturb
//   transmission or vice versa.
// =============================================================================

module uart #(
    parameter int CLK_FREQ_HZ = 16_000_000,
    parameter int BAUD_RATE   = 1_000_000,
    parameter int DATA_BITS   = 8,   // 7 or 8
    parameter int PARITY      = 0,   // 0 = none, 1 = even, 2 = odd
    parameter int STOP_BITS   = 1,   // 1 or 2
    // derived -- do not override
    parameter int BIT_CYCLES  = CLK_FREQ_HZ / BAUD_RATE
) (
    input  logic                 clk,
    input  logic                 rst_n,

    // ---- transmitter ----
    input  logic                 tx_start,
    input  logic [DATA_BITS-1:0] tx_data,
    output logic                 tx_busy,
    output logic                 tx_serial,

    // ---- receiver ----
    input  logic                 rx_serial,
    output logic [DATA_BITS-1:0] rx_data,
    output logic                 rx_valid,       // one-cycle pulse
    output logic                 rx_frame_err,
    output logic                 rx_parity_err
);

    // IMPLEMENTATION INTENTIONALLY OMITTED.

endmodule
