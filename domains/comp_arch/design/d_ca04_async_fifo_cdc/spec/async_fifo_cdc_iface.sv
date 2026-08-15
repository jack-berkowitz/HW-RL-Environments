// =============================================================================
// async_fifo_cdc_iface.sv  --  PORT DEFINITION ONLY (no implementation)
// =============================================================================
// Task: implement an asynchronous FIFO that carries data across a clock domain
// crossing. The write port is clocked by `wr_clk`, the read port by `rd_clk`,
// and THE TWO CLOCKS ARE UNRELATED -- no fixed ratio, no phase relationship, no
// common source. Your design must be correct at every ratio, including ratios
// close to 1 where the two edges drift slowly past each other.
//
// This is the only two-clock task in the design set. Everything difficult about
// it follows from that: a multi-bit value sampled across the boundary while it
// is changing can be latched inconsistently, and no amount of data checking on
// one side alone will reveal it.
//
// -----------------------------------------------------------------------------
// PARAMETERS
// -----------------------------------------------------------------------------
//   DATA_W      : payload width in bits. Legal: 8, 32, 64.
//   LOG_DEPTH   : FIFO depth is 2**LOG_DEPTH entries. Legal: 2, 3, 4.
//                 Depth is a power of two by construction; do not support
//                 non-power-of-two depths.
//   SYNC_STAGES : number of synchroniser flops on each value crossing the
//                 boundary. Legal: 2, 3.
//   Any other value of any parameter is ILLEGAL and need not be handled.
//
// -----------------------------------------------------------------------------
// PORTS AND HANDSHAKE
// -----------------------------------------------------------------------------
//   Standard valid/ready on each side, each in ITS OWN clock domain.
//   A beat transfers on a rising edge of that side's clock at which both valid
//   and ready are high.
//
//   H1. `wr_ready` MUST NOT depend combinationally on `wr_valid`, and
//       `rd_valid` MUST NOT depend combinationally on `rd_ready`.
//   H2. Once `wr_valid` is asserted the producer holds it, and holds `wr_data`
//       stable, until the beat is accepted. The checker honours this.
//   H3. When `rd_valid` is high and `rd_ready` is low, `rd_valid` must REMAIN
//       high and `rd_data` must remain STABLE until the beat is accepted.
//
// -----------------------------------------------------------------------------
// WHAT THE FIFO MUST DO
// -----------------------------------------------------------------------------
//   C1. NO LOSS. Every beat accepted on the write side is eventually delivered
//       on the read side.
//   C2. NO DUPLICATION. Delivered exactly once.
//   C3. ORDER PRESERVED. Beat N in is beat N out. This is a FIFO.
//   C4. NO OVERFLOW. `wr_ready` must be low whenever accepting another beat
//       would overwrite an entry that has not yet been read. With 2**LOG_DEPTH
//       entries the FIFO must accept at least 2**LOG_DEPTH beats before
//       backpressuring, and must never accept more than it can hold.
//   C5. NO UNDERFLOW / NO PHANTOM DATA. `rd_valid` must be low unless a beat
//       written on the other side is genuinely available. It must NEVER assert
//       on the strength of a pointer value that is still in flight through the
//       synchronisers -- that is the classic false-empty/false-full bug and it
//       only appears at particular clock ratios.
//   C6. CORRECT AT ANY RATIO. All of the above hold for arbitrary, unrelated
//       `wr_clk` and `rd_clk` frequencies and phases. The checker exercises
//       fast-write/slow-read, slow-write/fast-read, near-equal-but-drifting,
//       and integer ratios in both directions.
//
// -----------------------------------------------------------------------------
// CDC REQUIREMENT -- normative, and the point of the task
// -----------------------------------------------------------------------------
//   Any multi-bit value that crosses between the domains must be encoded so
//   that AT MOST ONE BIT CHANGES per increment (a Gray code is the standard
//   choice), and must then be resynchronised through SYNC_STAGES flops in the
//   receiving domain before use.
//
//   Passing a plain binary counter through a synchroniser is INCORRECT even
//   though it will appear to work in a zero-delay simulation: several bits
//   change at once, and the receiving domain can latch a value that was never
//   architecturally present. Do not do it.
//
//   The payload itself does NOT need to be synchronised. It is written in the
//   source domain and only read once the pointer that covers it has safely
//   crossed, so it is already stable by construction.
//
// -----------------------------------------------------------------------------
// RESET -- read this carefully, it is the subtlest part of the contract
// -----------------------------------------------------------------------------
//   `wr_rst_n` and `rd_rst_n` are ACTIVE-LOW.
//
//   R1. THE TWO RESETS ARE ASSERTED SIMULTANEOUSLY. This is a power-on reset:
//       both domains go into reset together. You may rely on that.
//   R2. DE-ASSERTION IS PER-DOMAIN AND NOT SIMULTANEOUS. `wr_rst_n` is released
//       synchronously to `wr_clk` and `rd_rst_n` synchronously to `rd_clk`, so
//       one side can leave reset several cycles before the other. Your design
//       must tolerate that: the side that comes out first must not emit or
//       accept anything that violates C1-C5 while the other is still held.
//   R3. WARM RESET IS OUT OF SCOPE. Resetting one domain while the other keeps
//       running is ILLEGAL, is never exercised, and its behaviour is
//       unconstrained. Do not spend hardware supporting it.
//   R4. Coming out of reset the FIFO is EMPTY: `rd_valid` == 0, and `wr_ready`
//       becomes 1 within 16 `wr_clk` cycles of `wr_rst_n` releasing.
//   R5. While `rd_rst_n` is low, `rd_valid` == 0.
//
// -----------------------------------------------------------------------------
// LATENCY AND THROUGHPUT
// -----------------------------------------------------------------------------
//   NEITHER IS CONSTRAINED AND NEITHER IS CHECKED. Crossing latency depends on
//   SYNC_STAGES and on the ratio between two unrelated clocks, so no fixed
//   number could be correct. Throughput likewise.
//
//   The only timing requirement is LIVENESS: with `wr_valid` held high and
//   `rd_ready` held high, the FIFO must not stall permanently. Concretely, a
//   beat accepted on the write side must become visible on the read side within
//   64 `rd_clk` cycles, and `wr_ready` must recover within 64 `wr_clk` cycles of
//   the read side draining.
//
// =============================================================================

module async_fifo_cdc #(
    parameter int DATA_W      = 32,   // 8 / 32 / 64
    parameter int LOG_DEPTH   = 3,    // 2 / 3 / 4  -> depth 4 / 8 / 16
    parameter int SYNC_STAGES = 2     // 2 / 3
) (
    // ---- write domain ----
    input  logic              wr_clk,
    input  logic              wr_rst_n,
    input  logic              wr_valid,
    output logic              wr_ready,
    input  logic [DATA_W-1:0] wr_data,

    // ---- read domain ----
    input  logic              rd_clk,
    input  logic              rd_rst_n,
    output logic              rd_valid,
    input  logic              rd_ready,
    output logic [DATA_W-1:0] rd_data
);

    // IMPLEMENTATION INTENTIONALLY OMITTED.

endmodule
