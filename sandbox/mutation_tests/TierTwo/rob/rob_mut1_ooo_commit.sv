// =============================================================================
// rob.sv -- MUTANT 1: out-of-order commit (throwaway) (harness validation only, NOT a candidate)
// =============================================================================
// Implements interfaces/TierTwo/rob_iface.sv exactly. This exists to prove the
// testbench passes something correct and fails deliberate mutants; it must
// never be placed in candidates/.
//
// Structure: circular buffer of DEPTH entries with head/tail pointers and a
// separate occupancy counter. The counter (rather than wrap bits on the
// pointers) generates free_entries directly, which is what dispatch_ready,
// rob_full and rob_empty all sit on.
//
// The one genuinely fiddly part is age comparison for flush. Indices wrap, so
// "younger than flush_rob_idx" is meaningless in absolute terms; everything is
// compared in head-relative space, rel(i) = (i - head) mod DEPTH. Because DEPTH
// is a power of two that subtraction wraps for free in IDX_W bits.
// =============================================================================

module rob #(
    parameter int DEPTH = 16,
    parameter int PC_W  = 32,
    parameter int TAG_W = 6,
    parameter int VAL_W = 32,
    // derived -- do not override
    parameter int IDX_W = $clog2(DEPTH),
    parameter int CNT_W = $clog2(DEPTH+1)
) (
    input  logic                    clk,
    input  logic                    rst_n,

    input  logic [1:0]              dispatch_valid,
    output logic                    dispatch_ready,
    input  logic [1:0][PC_W-1:0]    dispatch_pc,
    input  logic [1:0][TAG_W-1:0]   dispatch_dest_tag,
    input  logic [1:0]              dispatch_is_branch,
    output logic [1:0][IDX_W-1:0]   dispatch_rob_idx,

    input  logic [1:0]              complete_valid,
    input  logic [1:0][IDX_W-1:0]   complete_rob_idx,
    input  logic [1:0][VAL_W-1:0]   complete_value,
    input  logic [1:0]              complete_exception,
    input  logic [1:0]              complete_mispredict,
    input  logic [1:0][PC_W-1:0]    complete_actual_target,

    output logic [1:0]              commit_valid,
    output logic [1:0][IDX_W-1:0]   commit_rob_idx,
    output logic [1:0][TAG_W-1:0]   commit_dest_tag,
    output logic [1:0][VAL_W-1:0]   commit_value,
    output logic [1:0]              commit_exception,

    input  logic                    flush_valid,
    input  logic [IDX_W-1:0]        flush_rob_idx,

    output logic                    rob_full,
    output logic                    rob_empty,
    output logic [CNT_W-1:0]        free_entries
);

    // ---------------------------------------------------------------------
    // state
    // ---------------------------------------------------------------------
    logic                e_alloc  [DEPTH];   // entry is live
    logic                e_done   [DEPTH];   // entry is complete
    logic [PC_W-1:0]     e_pc     [DEPTH];
    logic [TAG_W-1:0]    e_tag    [DEPTH];
    logic                e_branch [DEPTH];
    logic [VAL_W-1:0]    e_val    [DEPTH];
    logic                e_exc    [DEPTH];
    logic                e_mispr  [DEPTH];
    logic [PC_W-1:0]     e_target [DEPTH];

    logic [IDX_W-1:0]    head, tail;
    logic [CNT_W-1:0]    count;              // allocated entries

    // ---------------------------------------------------------------------
    // status (combinational)
    // ---------------------------------------------------------------------
    assign free_entries = CNT_W'(DEPTH) - count;
    assign rob_full     = (count == CNT_W'(DEPTH));
    assign rob_empty    = (count == '0);
    assign dispatch_ready = (free_entries >= CNT_W'(2));

    // ---------------------------------------------------------------------
    // dispatch index assignment (compacted, lane 0 older)
    // ---------------------------------------------------------------------
    assign dispatch_rob_idx[0] = tail;
    assign dispatch_rob_idx[1] = tail + IDX_W'(dispatch_valid[0] ? 1 : 0);

    logic disp0, disp1;
    assign disp0 = dispatch_ready && dispatch_valid[0];
    assign disp1 = dispatch_ready && dispatch_valid[1];

    logic [CNT_W-1:0] n_alloc;
    assign n_alloc = CNT_W'((disp0 ? 1 : 0) + (disp1 ? 1 : 0));

    // ---------------------------------------------------------------------
    // flush point in head-relative space (declared here: commit needs it too)
    // ---------------------------------------------------------------------
    logic [IDX_W-1:0] rel_flush;
    assign rel_flush = flush_rob_idx - head;

    // ---------------------------------------------------------------------
    // commit (combinational, from head, contiguous, stops at an exception)
    // ---------------------------------------------------------------------
    logic [IDX_W-1:0] head1;
    assign head1 = head + IDX_W'(1);

    // head is never younger than flush_rob_idx, so only lane 1 can collide with
    // a same-cycle flush -- and only when the flush point IS the head.
    logic head1_squashed;
    assign head1_squashed = flush_valid && (rel_flush == '0);

    assign commit_valid[0] = e_alloc[head] && e_done[head];
    // MUTANT 1: lane 1 no longer requires lane 0 to be committing, so a
    // completed head+1 can retire while the head is still waiting -> commit
    // leaves program order.
    assign commit_valid[1] = !e_exc[head]
                          && !head1_squashed
                          && e_alloc[head1] && e_done[head1];

    assign commit_rob_idx[0]   = head;
    assign commit_rob_idx[1]   = head1;
    assign commit_dest_tag[0]  = e_tag[head];
    assign commit_dest_tag[1]  = e_tag[head1];
    assign commit_value[0]     = e_val[head];
    assign commit_value[1]     = e_val[head1];
    assign commit_exception[0] = e_exc[head];
    assign commit_exception[1] = e_exc[head1];

    logic [CNT_W-1:0] n_commit;
    assign n_commit = CNT_W'((commit_valid[0] ? 1 : 0) + (commit_valid[1] ? 1 : 0));

    // ---------------------------------------------------------------------
    // flush: squash everything strictly younger than flush_rob_idx.
    // Compared in head-relative space so wrapping is handled.
    // ---------------------------------------------------------------------
    function automatic logic squashed(input logic [IDX_W-1:0] idx);
        logic [IDX_W-1:0] rel;
        rel = idx - head;
        return flush_valid && e_alloc[idx] && (rel > rel_flush);
    endfunction

    // number of entries surviving a flush: head..flush_rob_idx inclusive
    logic [CNT_W-1:0] surviving;
    assign surviving = CNT_W'(rel_flush) + CNT_W'(1);

    // ---------------------------------------------------------------------
    // sequential state
    // ---------------------------------------------------------------------
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            head  <= '0;
            tail  <= '0;
            count <= '0;
            for (int i = 0; i < DEPTH; i++) begin
                e_alloc[i] <= 1'b0;
                e_done[i]  <= 1'b0;
            end
        end else begin
            // ---- completion: latch into the entry unless it is being squashed
            for (int L = 0; L < 2; L++) begin
                if (complete_valid[L] && !squashed(complete_rob_idx[L])) begin
                    e_done[complete_rob_idx[L]] <= 1'b1;
                    e_val [complete_rob_idx[L]] <= complete_value[L];
                    e_exc [complete_rob_idx[L]] <= complete_exception[L];
                    if (e_branch[complete_rob_idx[L]]) begin
                        e_mispr [complete_rob_idx[L]] <= complete_mispredict[L];
                        e_target[complete_rob_idx[L]] <= complete_actual_target[L];
                    end
                end
            end

            // ---- commit: free the committed entries
            if (commit_valid[0]) e_alloc[head]  <= 1'b0;
            if (commit_valid[1]) e_alloc[head1] <= 1'b0;
            head <= head + IDX_W'(n_commit);

            // ---- flush wins over dispatch for the tail
            if (flush_valid) begin
                for (int i = 0; i < DEPTH; i++)
                    if (squashed(IDX_W'(i))) begin
                        e_alloc[i] <= 1'b0;
                        e_done[i]  <= 1'b0;
                    end
                tail  <= flush_rob_idx + IDX_W'(1);
                count <= surviving - n_commit;
            end else begin
                // ---- dispatch
                if (disp0) begin
                    e_alloc [dispatch_rob_idx[0]] <= 1'b1;
                    e_done  [dispatch_rob_idx[0]] <= 1'b0;
                    e_pc    [dispatch_rob_idx[0]] <= dispatch_pc[0];
                    e_tag   [dispatch_rob_idx[0]] <= dispatch_dest_tag[0];
                    e_branch[dispatch_rob_idx[0]] <= dispatch_is_branch[0];
                    e_exc   [dispatch_rob_idx[0]] <= 1'b0;
                    e_mispr [dispatch_rob_idx[0]] <= 1'b0;
                end
                if (disp1) begin
                    e_alloc [dispatch_rob_idx[1]] <= 1'b1;
                    e_done  [dispatch_rob_idx[1]] <= 1'b0;
                    e_pc    [dispatch_rob_idx[1]] <= dispatch_pc[1];
                    e_tag   [dispatch_rob_idx[1]] <= dispatch_dest_tag[1];
                    e_branch[dispatch_rob_idx[1]] <= dispatch_is_branch[1];
                    e_exc   [dispatch_rob_idx[1]] <= 1'b0;
                    e_mispr [dispatch_rob_idx[1]] <= 1'b0;
                end
                tail  <= tail + IDX_W'(n_alloc);
                count <= count + n_alloc - n_commit;
            end
        end
    end

endmodule
