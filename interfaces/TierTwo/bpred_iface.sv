// =============================================================================
// bpred_iface.sv  --  PORT DEFINITION ONLY (no implementation)
// =============================================================================
// Task: implement a gshare branch predictor with a tagged BTB, a return address
//       stack, and externally-checkpointed speculative-state recovery.
//
// This module is graded in TWO TIERS. Read GRADING at the bottom before
// optimising anything: prediction accuracy is NOT pass/fail, and a predictor
// that is highly accurate but mishandles recovery FAILS.
//
// -----------------------------------------------------------------------------
// PARAMETERS
// -----------------------------------------------------------------------------
//   PC_W       : program counter width. Default 32.
//   GHR_W      : global history register width. Default 8.
//   PHT_ENTRIES: pattern history table entries. Must equal 2**GHR_W.
//   BTB_SETS   : BTB sets. Power of 2. Default 16.
//   BTB_WAYS   : BTB associativity. Default 2.
//   RAS_DEPTH  : return address stack depth. Power of 2. Default 8.
//   RAS_PTR_W  : DERIVED. $clog2(RAS_DEPTH).
//   SNAP_W     : DERIVED. GHR_W + RAS_PTR_W -- see SNAPSHOT below.
//
//   Instructions are 4 bytes and PCs are 4-byte aligned.
//
// -----------------------------------------------------------------------------
// SNAPSHOT / RESTORE  (resolved ambiguity -- read this)
// -----------------------------------------------------------------------------
//   The port list carries ONE recovery value, but both the GHR and the RAS
//   pointer are speculative state and both must be recoverable. `ghr_snapshot`
//   therefore carries the whole speculative-state checkpoint, packed as
//
//       ghr_snapshot = { ras_sp, ghr }      // ras_sp in the high RAS_PTR_W bits
//
//   and `restore_ghr_value` is the same packing. The name is kept from the
//   original port list; treat it as "speculative state snapshot".
//
//   ghr_snapshot is the state BEFORE this cycle's prediction is applied, so the
//   core can store it alongside the branch and hand it straight back on a
//   misprediction.
//
// -----------------------------------------------------------------------------
// BTB
// -----------------------------------------------------------------------------
//   Set index  = predict_pc[2 +: $clog2(BTB_SETS)]
//   Tag        = predict_pc[2 + $clog2(BTB_SETS) +: TAG_W]
//   Each entry holds valid, tag, target and a 2-bit TYPE, written at update.
//
//   TYPE encoding: 2'd0 = BRANCH (conditional), 2'd1 = CALL, 2'd2 = RETURN.
//
//   ALLOCATE ON FIRST ENCOUNTER: an update naming a control-transfer
//   instruction must install a BTB entry for that PC. A subsequent predict for
//   the same PC, with no conflicting update in between, must HIT and replay the
//   recorded target.
//
//   Replacement policy within a set is IMPLEMENTATION DEFINED and is not graded.
//   Neither is index/tag aliasing between two different PCs -- that is an
//   inherent property of a finite BTB, not a bug. What IS graded: when the
//   predictor claims a hit, the data it returns must be right.
//
// -----------------------------------------------------------------------------
// RAS
// -----------------------------------------------------------------------------
//   A circular array of RAS_DEPTH entries with a wrapping pointer `ras_sp`
//   pointing at the next push slot. There is no full/empty tracking; the
//   pointer simply wraps. This makes the state exactly recoverable from the
//   pointer alone, which is what the snapshot relies on.
//
//     push : ras[ras_sp] <= predict_pc + 4 ;  ras_sp <= ras_sp + 1
//     pop  : ras_sp <= ras_sp - 1 ;  the popped value is ras[ras_sp - 1]
//
//   Pushes and pops happen at PREDICT time, driven by the BTB entry's type, and
//   are therefore speculative.
//
// -----------------------------------------------------------------------------
// PREDICT  (combinational, single cycle)
// -----------------------------------------------------------------------------
//   predict_valid     = BTB hit for predict_pc. On a miss the predictor has no
//                       reason to believe this is a branch: predict_valid=0,
//                       predict_taken=0, predict_is_return=0, predict_target is
//                       DON'T CARE, and NO speculative state changes.
//   predict_is_return = hit && type == RETURN
//   predict_taken     = hit ? ((type == BRANCH) ? pht[idx][1] : 1'b1) : 1'b0
//                       -- calls and returns are unconditional.
//   predict_target    = predict_is_return ? ras[ras_sp - 1] : btb_target
//   ghr_snapshot      = { ras_sp, ghr }   (pre-update, as above)
//
//   PHT index = predict_pc[2 +: GHR_W] ^ ghr        (this is the gshare hash)
//
// -----------------------------------------------------------------------------
// SPECULATIVE STATE UPDATE  (at the clock edge)
// -----------------------------------------------------------------------------
//   Priority: RESTORE WINS over everything speculative.
//
//   if (restore_valid)         ras_sp <= restore.ras_sp, and NO speculative
//                              push, pop or speculative shift happens.
//                              ghr <= restore.ghr, EXCEPT that when a
//                              conditional-branch update lands in the same
//                              cycle the branch's true outcome is folded in:
//                                  ghr <= {restore.ghr[GHR_W-2:0], update_taken}
//                              so recovery ends with architecturally correct
//                              history rather than history missing this branch.
//   else if (predict_valid)    type == BRANCH -> ghr <= {ghr[GHR_W-2:0], predict_taken}
//                              type == CALL   -> RAS push
//                              type == RETURN -> RAS pop
//                              (a call or return does NOT shift the GHR)
//   else                       hold.
//
//   The predictor never derives history from the update path -- the core owns
//   recovery and supplies whatever corrected value it wants in restore.
//
// -----------------------------------------------------------------------------
// UPDATE  (ground truth from execute/commit; non-speculative)
// -----------------------------------------------------------------------------
//   update_valid, update_pc, update_taken, update_target,
//   update_is_branch, update_is_call, update_is_return.
//
//   TYPE resolution, in this order: is_call -> CALL, else is_return -> RETURN,
//   else is_branch -> BRANCH, else NOT a control instruction (no BTB write, no
//   PHT training).
//
//   BTB : allocate or refresh the entry for update_pc with update_target and
//         the resolved type, for all three control types.
//   PHT : trained ONLY for type BRANCH, as a 2-bit saturating counter --
//         increment (max 3) when update_taken, decrement (min 0) otherwise.
//
//   PHT TRAINING INDEX uses the EFFECTIVE history for this cycle, i.e. the
//   restored value when a restore lands in the same cycle:
//       eff_ghr   = restore_valid ? restore.ghr : ghr
//       train_idx = update_pc[2 +: GHR_W] ^ eff_ghr
//   A branch therefore trains at the SAME index it predicted with, which is the
//   whole point of checkpointing the history. This is also why `restore` is the
//   channel the core uses to hand a branch's checkpoint back when it RESOLVES,
//   not only when it mispredicts: it is the only path by which the predictor can
//   learn which history a given update belongs to. A core that never supplies it
//   still works, but trains at a shifted index and predicts poorly -- which shows
//   up in the tier-2 accuracy score, not as a tier-1 failure.
//
//   Update and restore are independent and may occur in the same cycle.
//
// -----------------------------------------------------------------------------
// RESET
// -----------------------------------------------------------------------------
//   rst_n is ACTIVE-LOW and SYNCHRONOUS. After reset: all BTB entries invalid,
//   ghr = 0, ras_sp = 0, every PHT counter = 2'd1 (weakly not-taken), and every
//   RAS ENTRY = 0. The RAS contents are reset too, so that a return predicted
//   before anything has been pushed has a defined result (it reads ras[sp-1],
//   which wraps to the top of the array) rather than leaking stale state.
//
// -----------------------------------------------------------------------------
// GRADING (two tiers -- do not conflate them)
// -----------------------------------------------------------------------------
//   TIER 1, PASS/FAIL -- protocol and state correctness only:
//     * RAS push on a predicted call, pop on a predicted return, nested chains,
//       and exact pointer restore on squash.
//     * GHR speculative shift at predict time and exact restore.
//     * BTB allocate-on-first-encounter and correct target replay on a hit.
//     * A hit must never return a stale or wrong target/type.
//
//   TIER 2, INFORMATIONAL -- misprediction rate on synthetic traces. Reported,
//   never pass/fail. A predictor with poor accuracy but correct protocol PASSES.
// =============================================================================

module bpred #(
    parameter int PC_W        = 32,
    parameter int GHR_W       = 8,
    parameter int PHT_ENTRIES = 256,   // must be 2**GHR_W
    parameter int BTB_SETS    = 16,
    parameter int BTB_WAYS    = 2,
    parameter int RAS_DEPTH   = 8,
    // derived -- do not override
    parameter int RAS_PTR_W   = $clog2(RAS_DEPTH),
    parameter int SNAP_W      = GHR_W + RAS_PTR_W
) (
    input  logic              clk,
    input  logic              rst_n,

    // ---- predict (combinational) ----
    input  logic [PC_W-1:0]   predict_pc,
    output logic              predict_valid,       // BTB hit
    output logic              predict_taken,
    output logic [PC_W-1:0]   predict_target,
    output logic              predict_is_return,
    output logic [SNAP_W-1:0] ghr_snapshot,        // { ras_sp, ghr }, pre-update

    // ---- update (ground truth) ----
    input  logic              update_valid,
    input  logic [PC_W-1:0]   update_pc,
    input  logic              update_taken,
    input  logic [PC_W-1:0]   update_target,
    input  logic              update_is_branch,
    input  logic              update_is_call,
    input  logic              update_is_return,

    // ---- speculative-state recovery ----
    input  logic              restore_valid,
    input  logic [SNAP_W-1:0] restore_ghr_value    // same packing as ghr_snapshot
);

    // IMPLEMENTATION INTENTIONALLY OMITTED.

endmodule
