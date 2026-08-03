// =============================================================================
// fifo_iface.sv  --  PORT DEFINITION ONLY (no implementation)
// =============================================================================
// Task: implement a synchronous (single clock) FIFO with the exact interface
//       and semantics described below.
//
// -----------------------------------------------------------------------------
// PARAMETERS
// -----------------------------------------------------------------------------
//   DEPTH               : number of entries the FIFO can hold. Legal: 8,16,32,64.
//   DATA_WIDTH          : width in bits of wr_data/rd_data. Legal: 8,16,32,64.
//   ALMOST_FULL_THRESH  : integer in [1, DEPTH].     See almost_full below.
//   ALMOST_EMPTY_THRESH : integer in [0, DEPTH-1].   See almost_empty below.
//   CNT_W               : DERIVED. Do not override. Width of `count`.
//                         CNT_W = $clog2(DEPTH)+1 so that `count` can represent
//                         every value in 0..DEPTH inclusive.
//
// -----------------------------------------------------------------------------
// CLOCK / RESET
// -----------------------------------------------------------------------------
//   clk   : all state updates occur on the rising edge of clk.
//   rst_n : ACTIVE-LOW, SYNCHRONOUS reset. While rst_n==0 is sampled at a rising
//           clk edge, the FIFO is flushed: after that edge count==0, empty==1,
//           full==0, almost_empty==1, almost_full==0. Writes and reads presented
//           in a cycle where rst_n==0 are discarded.
//
// -----------------------------------------------------------------------------
// OCCUPANCY / FLAGS  (all are combinational functions of the current occupancy;
//                     they describe the state *before* the next rising edge)
// -----------------------------------------------------------------------------
//   count        : number of valid entries currently stored, 0..DEPTH.
//   empty        : (count == 0)
//   full         : (count == DEPTH)
//   almost_empty : (count <= ALMOST_EMPTY_THRESH)   // note: <=, so it is 1 when empty
//   almost_full  : (count >= ALMOST_FULL_THRESH)    // note: >=, so it is 1 when full
//
// -----------------------------------------------------------------------------
// WRITE PORT
// -----------------------------------------------------------------------------
//   wr_en, wr_data : a write is COMMITTED on a rising clk edge iff
//                      rst_n==1 && wr_en==1 && full==0
//                    (`full` here is the flag value in that same cycle, i.e.
//                    the pre-edge occupancy). wr_data is pushed to the tail.
//   A write presented while full==1 is SILENTLY DROPPED. It must not corrupt
//   stored data, must not change count, and must not wrap the write pointer.
//
// -----------------------------------------------------------------------------
// READ PORT -- FIRST-WORD FALL-THROUGH (FWFT), *NOT* registered-output
// -----------------------------------------------------------------------------
//   rd_data : combinationally presents the value at the HEAD of the FIFO
//             whenever empty==0. It must be valid in the same cycle that
//             empty==0, with no rd_en required and no extra latency cycle.
//             When empty==1, rd_data is DON'T CARE (never checked).
//   rd_en   : a read (pop) is COMMITTED on a rising clk edge iff
//               rst_n==1 && rd_en==1 && empty==0
//             The head entry is removed; after that edge rd_data presents the
//             next entry (if any).
//   A read presented while empty==1 is SILENTLY DROPPED: count must not
//   underflow and the read pointer must not move.
//
// -----------------------------------------------------------------------------
// SIMULTANEOUS READ + WRITE  (wr_en==1 && rd_en==1 on the same edge)
// -----------------------------------------------------------------------------
//   Each side is qualified INDEPENDENTLY by the pre-edge flags, i.e. exactly the
//   two rules above are applied together. Concretely:
//     * count in 1..DEPTH-1 : both commit. count is unchanged. The popped value
//                             is the old head; the new value goes to the tail.
//     * count == DEPTH (full)  : the READ commits, the WRITE IS DROPPED.
//                                Post-edge count == DEPTH-1.
//                                (There is NO "write into the slot being freed"
//                                 bypass -- full blocks the write.)
//     * count == 0 (empty)     : the WRITE commits, the READ IS DROPPED.
//                                Post-edge count == 1.
//                                (There is NO write-to-read passthrough -- the
//                                 word just written is NOT popped in that edge.)
//
// -----------------------------------------------------------------------------
// ORDERING
// -----------------------------------------------------------------------------
//   Strict FIFO order. Data must survive pointer wraparound: after DEPTH pushes
//   and DEPTH pops the FIFO must behave identically to its reset state.
// =============================================================================

module fifo #(
    parameter int DEPTH               = 16,
    parameter int DATA_WIDTH          = 32,
    parameter int ALMOST_FULL_THRESH  = 12,
    parameter int ALMOST_EMPTY_THRESH = 4,
    // derived -- do not override
    parameter int CNT_W               = $clog2(DEPTH) + 1
) (
    input  logic                  clk,
    input  logic                  rst_n,

    // write port
    input  logic                  wr_en,
    input  logic [DATA_WIDTH-1:0] wr_data,

    // read port (first-word fall-through)
    input  logic                  rd_en,
    output logic [DATA_WIDTH-1:0] rd_data,

    // status
    output logic                  full,
    output logic                  empty,
    output logic                  almost_full,
    output logic                  almost_empty,
    output logic [CNT_W-1:0]      count
);

    // IMPLEMENTATION INTENTIONALLY OMITTED.

endmodule
