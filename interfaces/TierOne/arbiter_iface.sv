// =============================================================================
// arbiter_iface.sv  --  PORT DEFINITION ONLY (no implementation)
// =============================================================================
// Task: implement a single-cycle arbiter supporting three selectable policies.
//
// -----------------------------------------------------------------------------
// PARAMETERS
// -----------------------------------------------------------------------------
//   NUM_REQ : number of requesters. Legal: 2, 4, 8, 16.
//   VARIANT : arbitration policy.
//               0 = FIXED_PRIORITY
//               1 = ROUND_ROBIN
//               2 = MATRIX  (least-recently-granted)
//   IDX_W   : DERIVED. Do not override. IDX_W = $clog2(NUM_REQ).
//
// -----------------------------------------------------------------------------
// TIMING CONTRACT  (this is the part that must be exact)
// -----------------------------------------------------------------------------
//   grant / grant_valid / grant_idx are COMBINATIONAL functions of `req` and of
//   the arbiter's internal priority state. They respond in the SAME cycle the
//   request is presented -- there is no registered-output latency cycle.
//
//   The internal priority state is updated on a rising clk edge IFF
//   rst_n==1 && grant_valid==1 in that cycle. I.e. a grant that is asserted is
//   considered TAKEN in that cycle; there is no separate accept/ack input.
//   When grant_valid==0 the priority state holds.
//
//   rst_n is ACTIVE-LOW and SYNCHRONOUS. On a rising edge with rst_n==0 the
//   priority state returns to its reset value (defined per variant below).
//
// -----------------------------------------------------------------------------
// OUTPUT ENCODING  (applies to all variants)
// -----------------------------------------------------------------------------
//   req == 0  ->  grant == 0, grant_valid == 0, grant_idx is DON'T CARE.
//   req != 0  ->  grant_valid == 1 and `grant` is exactly ONE-HOT.
//                 grant must be a subset of req: (grant & ~req) == 0.
//                 grant_idx is the index of the set bit of `grant`, i.e.
//                 grant == (1 << grant_idx).
//   The arbiter must never grant to a non-requester and must never grant to
//   more than one requester in the same cycle.
//
// -----------------------------------------------------------------------------
// VARIANT 0 -- FIXED_PRIORITY
// -----------------------------------------------------------------------------
//   Index 0 is the HIGHEST priority, index NUM_REQ-1 the lowest.
//   grant = lowest set index of req. Stateless: the priority order never
//   changes, so a continuously-requesting index 0 legitimately starves all
//   higher indices. (The testbench asserts that this starvation DOES occur --
//   a "fair" fixed-priority arbiter is a spec violation.)
//
// -----------------------------------------------------------------------------
// VARIANT 1 -- ROUND_ROBIN
// -----------------------------------------------------------------------------
//   State: rr_ptr, an index in 0..NUM_REQ-1. Reset value: 0.
//   Grant: scan i = rr_ptr, rr_ptr+1, ..., wrapping mod NUM_REQ, and grant the
//          FIRST i with req[i]==1. (So rr_ptr itself has highest priority.)
//   Update on a taken grant to index g:  rr_ptr <= (g + 1) mod NUM_REQ.
//   Consequence to match exactly: out of reset with req == all-ones, the grant
//   sequence is 0,1,2,...,NUM_REQ-1,0,1,...
//
// -----------------------------------------------------------------------------
// VARIANT 2 -- MATRIX (least-recently-granted)
// -----------------------------------------------------------------------------
//   State: W[i][j] for all i != j, where W[i][j]==1 means "i currently outranks
//          j". Reset value: W[i][j] = (i < j), i.e. index 0 initially outranks
//          everyone, reproducing fixed priority on the first grant.
//   Grant: grant index i iff req[i]==1 AND for every j != i with req[j]==1,
//          W[i][j]==1. (The relation is a total order, so exactly one such i
//          exists whenever req != 0.)
//   Update on a taken grant to index g:
//          for all j != g:  W[g][j] <= 0   (g becomes lowest priority)
//          for all j != g:  W[j][g] <= 1
//   This yields least-recently-granted-first ordering.
//
// -----------------------------------------------------------------------------
// FAIRNESS REQUIREMENT (VARIANT 1 and 2 only)
// -----------------------------------------------------------------------------
//   If req[i] is held high continuously, index i must be granted within at most
//   NUM_REQ consecutive cycles, regardless of what the other requesters do.
//   The testbench checks this bound explicitly.
// =============================================================================

module arbiter #(
    parameter int NUM_REQ = 4,   // 2 / 4 / 8 / 16
    parameter int VARIANT = 1,   // 0=fixed, 1=round-robin, 2=matrix
    // derived -- do not override
    parameter int IDX_W   = $clog2(NUM_REQ)
) (
    input  logic               clk,
    input  logic               rst_n,

    input  logic [NUM_REQ-1:0] req,

    output logic [NUM_REQ-1:0] grant,        // one-hot, subset of req
    output logic               grant_valid,  // |req
    output logic [IDX_W-1:0]   grant_idx     // index of the set bit of grant
);

    // IMPLEMENTATION INTENTIONALLY OMITTED.

endmodule
