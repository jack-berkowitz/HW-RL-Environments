// =============================================================================
// rob_iface.sv  --  PORT DEFINITION ONLY (no implementation)
// =============================================================================
// Task: implement a Reorder Buffer with 2-wide dispatch, out-of-order
//       completion, in-order 2-wide commit, and misprediction flush.
//
// -----------------------------------------------------------------------------
// PARAMETERS
// -----------------------------------------------------------------------------
//   DEPTH   : number of ROB entries. Legal: 8, 16, 32, 64. Must be a power of 2.
//   PC_W    : width of the program counter / branch target fields.
//   TAG_W   : width of the destination (physical register) tag.
//   VAL_W   : width of the result value.
//   IDX_W   : DERIVED. Do not override. IDX_W = $clog2(DEPTH).
//   CNT_W   : DERIVED. Do not override. CNT_W = $clog2(DEPTH+1).
//
//   Lane-indexed ports are packed 2-D: lane 0 occupies bits [0], lane 1 bits [1],
//   e.g. dispatch_pc[1] is lane 1's PC. LANE 0 IS ALWAYS OLDER THAN LANE 1.
//
// -----------------------------------------------------------------------------
// ENTRY LIFECYCLE
// -----------------------------------------------------------------------------
//   An entry is ALLOCATED at dispatch, becomes COMPLETE when a writeback names
//   it, and is freed when it COMMITS from the head or is SQUASHED by a flush.
//   The ROB is a circular buffer: `head` is the oldest live entry, `tail` is the
//   next index to allocate. Indices wrap modulo DEPTH.
//
//   "Age" is always relative to head: entry i is YOUNGER than entry j iff
//   ((i - head) mod DEPTH) > ((j - head) mod DEPTH).
//
// -----------------------------------------------------------------------------
// TIMING CONTRACT  (this is the part that must be exact)
// -----------------------------------------------------------------------------
//   ALL OUTPUTS ARE COMBINATIONAL functions of the registered ROB state and, for
//   dispatch_rob_idx only, of the current dispatch_valid. There is no output
//   register stage anywhere in this module.
//
//   State (entry contents, head, tail, occupancy) updates only on a rising clk
//   edge. Consequences that must hold exactly:
//     * An entry marked complete at edge N is eligible to commit in cycle N+1,
//       NOT in cycle N. commit_valid never depends on complete_valid.
//     * An entry allocated at edge N cannot commit in cycle N.
//
//   rst_n is ACTIVE-LOW and SYNCHRONOUS. On a rising edge with rst_n==0 the ROB
//   empties: head=tail=0, free_entries=DEPTH, rob_empty=1, rob_full=0.
//
// -----------------------------------------------------------------------------
// DISPATCH  (2 lanes, atomic group allocation)
// -----------------------------------------------------------------------------
//   dispatch_ready = (free_entries >= 2). It is INDEPENDENT of dispatch_valid --
//   deliberately, so there is no combinational path from valid to ready. A group
//   is therefore accepted only when at least 2 entries are free, even if only
//   one lane is valid. Up to one entry may sit unused at the top of the buffer;
//   that is intended, not a bug.
//
//   A lane allocates iff (dispatch_ready && dispatch_valid[lane]). Allocation is
//   COMPACTED -- lanes take consecutive indices in lane order, skipping invalid
//   lanes:
//       dispatch_rob_idx[0] = tail
//       dispatch_rob_idx[1] = tail + (dispatch_valid[0] ? 1 : 0)
//   dispatch_rob_idx[lane] is meaningful only when the lane actually allocates;
//   otherwise it is DON'T CARE.
//
//   tail advances by the number of allocating lanes. Each allocated entry
//   records dispatch_pc, dispatch_dest_tag and dispatch_is_branch, and starts
//   NOT complete.
//
// -----------------------------------------------------------------------------
// COMPLETE / WRITEBACK  (2 lanes, any order, any index)
// -----------------------------------------------------------------------------
//   complete_valid[lane] marks entry complete_rob_idx[lane] as complete and
//   latches complete_value and complete_exception into it. Completions may
//   arrive in any order relative to program order and relative to each other.
//
//   complete_mispredict / complete_actual_target are recorded only for entries
//   whose dispatch_is_branch was 1; for non-branch entries they are ignored.
//   They are bookkeeping only -- this module never initiates a flush itself.
//
//   A completion whose target entry is being SQUASHED by a flush in the SAME
//   cycle is DROPPED. It must not be latched and then squashed, and it must not
//   resurrect a squashed entry.
//
//   The testbench never completes an unallocated entry, never completes the same
//   entry twice, and never completes an entry that is already complete. Behaviour
//   in those cases is unspecified.
//
// -----------------------------------------------------------------------------
// COMMIT  (2 lanes, strictly in order, from the head)
// -----------------------------------------------------------------------------
//   commit_valid[0] = head entry is allocated AND complete.
//   commit_valid[1] = commit_valid[0] AND head+1 is allocated AND complete
//                     AND the entry committing on lane 0 has commit_exception==0
//                     AND head+1 survives any flush asserted this cycle.
//   So commit is CONTIGUOUS (lane 1 never commits without lane 0) and STOPS AT
//   AN EXCEPTION: an entry that commits with commit_exception==1 is the last
//   entry to commit in that cycle. The ROB does not flush itself on an
//   exception; reporting it is the whole job, and the core reacts via flush.
//
//   COMMIT/FLUSH OVERLAP. A lane may only commit an entry that SURVIVES a flush
//   asserted in the same cycle -- an entry cannot both commit and be squashed.
//   head is never younger than flush_rob_idx, so lane 0 is never affected. Lane 1
//   is affected in exactly one case: flush_valid==1 && flush_rob_idx==head, which
//   makes head+1 strictly younger than the flush point and therefore squashed.
//   In that case commit_valid[1] MUST be 0 even if head+1 is complete.
//
//   commit_rob_idx / commit_dest_tag / commit_value / commit_exception carry the
//   committing entry's recorded fields, and are DON'T CARE on a lane whose
//   commit_valid is 0. head advances by the number of committing lanes.
//
//   An entry must never commit twice, never commit before it is complete, and
//   never commit out of program order.
//
// -----------------------------------------------------------------------------
// FLUSH / MISPREDICTION RECOVERY
// -----------------------------------------------------------------------------
//   On a rising edge with flush_valid==1, every entry STRICTLY YOUNGER than
//   flush_rob_idx is squashed. The entry AT flush_rob_idx SURVIVES and commits
//   normally -- it is the mispredicting branch itself. tail becomes
//   flush_rob_idx + 1.
//
//   Flush and commit may occur in the same cycle and are independent: commit
//   drains the head, flush truncates the tail. If flush_rob_idx is the head and
//   the head also commits that cycle, the ROB ends up empty.
//
//   The testbench only issues flush_rob_idx values that name a currently
//   allocated entry. Flushing an unallocated or already-committed index is
//   unspecified.
//
// -----------------------------------------------------------------------------
// STATUS
// -----------------------------------------------------------------------------
//   free_entries : number of unallocated entries, 0..DEPTH (CNT_W bits).
//   rob_full     : free_entries == 0.
//   rob_empty    : free_entries == DEPTH.
//   Note rob_full is NOT the inverse of dispatch_ready: with exactly one entry
//   free the ROB is neither full nor ready.
// =============================================================================

module rob #(
    parameter int DEPTH = 16,   // 8 / 16 / 32 / 64, power of 2
    parameter int PC_W  = 32,
    parameter int TAG_W = 6,
    parameter int VAL_W = 32,
    // derived -- do not override
    parameter int IDX_W = $clog2(DEPTH),
    parameter int CNT_W = $clog2(DEPTH+1)
) (
    input  logic                    clk,
    input  logic                    rst_n,

    // ---- dispatch (2 lanes, lane 0 older) ----
    input  logic [1:0]              dispatch_valid,
    output logic                    dispatch_ready,
    input  logic [1:0][PC_W-1:0]    dispatch_pc,
    input  logic [1:0][TAG_W-1:0]   dispatch_dest_tag,
    input  logic [1:0]              dispatch_is_branch,
    output logic [1:0][IDX_W-1:0]   dispatch_rob_idx,

    // ---- complete / writeback (2 lanes, out of order) ----
    input  logic [1:0]              complete_valid,
    input  logic [1:0][IDX_W-1:0]   complete_rob_idx,
    input  logic [1:0][VAL_W-1:0]   complete_value,
    input  logic [1:0]              complete_exception,
    input  logic [1:0]              complete_mispredict,
    input  logic [1:0][PC_W-1:0]    complete_actual_target,

    // ---- commit (2 lanes, in order, from head) ----
    output logic [1:0]              commit_valid,
    output logic [1:0][IDX_W-1:0]   commit_rob_idx,
    output logic [1:0][TAG_W-1:0]   commit_dest_tag,
    output logic [1:0][VAL_W-1:0]   commit_value,
    output logic [1:0]              commit_exception,

    // ---- flush / misprediction recovery ----
    input  logic                    flush_valid,
    input  logic [IDX_W-1:0]        flush_rob_idx,

    // ---- status ----
    output logic                    rob_full,
    output logic                    rob_empty,
    output logic [CNT_W-1:0]        free_entries
);

    // IMPLEMENTATION INTENTIONALLY OMITTED.

endmodule
