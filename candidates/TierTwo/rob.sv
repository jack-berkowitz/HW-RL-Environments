module rob #(
    parameter int DEPTH = 16,
    parameter int PC_W  = 32,
    parameter int TAG_W = 6,
    parameter int VAL_W = 32,
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
    input  logic [1:0][VAL_W-1:0]    complete_value,
    input  logic [1:0]              complete_exception,
    input  logic [1:0]              complete_mispredict,
    input  logic [1:0][PC_W-1:0]     complete_actual_target,

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

    typedef struct packed {
        logic                 allocated;
        logic                 complete;
        logic [PC_W-1:0]      pc;
        logic [TAG_W-1:0]     dest_tag;
        logic [VAL_W-1:0]     value;
        logic                 exception;
        logic                 is_branch;
        logic                 mispredict;
        logic [PC_W-1:0]      actual_target;
    } rob_entry_t;

    rob_entry_t entries [0:DEPTH-1];

    logic [IDX_W-1:0] head;
    logic [IDX_W-1:0] tail;

    logic [IDX_W-1:0] head_next;
    logic [IDX_W-1:0] tail_next;
    logic [CNT_W-1:0] free_entries_next;

    integer k;

    // -------------------------------------------------------------------------
    // Circular increment.
    // DEPTH is a power of two, so IDX_W bits naturally wrap.
    // -------------------------------------------------------------------------
    function automatic [IDX_W-1:0] inc_idx(
        input [IDX_W-1:0] idx
    );
        inc_idx = idx + 1'b1;
    endfunction

    // -------------------------------------------------------------------------
    // Distance from h to idx in the circular ROB.
    //
    // Result is 0..DEPTH-1.
    // -------------------------------------------------------------------------
    function automatic integer distance(
        input [IDX_W-1:0] idx,
        input [IDX_W-1:0] h
    );
        begin
            if (idx >= h)
                distance = idx - h;
            else
                distance = idx + DEPTH - h;
        end
    endfunction

    // -------------------------------------------------------------------------
    // Combinational outputs.
    // -------------------------------------------------------------------------
    always_comb begin
        dispatch_ready = (free_entries >= 2);

        rob_full  = (free_entries == 0);
        rob_empty = (free_entries == DEPTH);

        // Compact allocation indices.
        dispatch_rob_idx[0] = tail;

        if (dispatch_valid[0])
            dispatch_rob_idx[1] = inc_idx(tail);
        else
            dispatch_rob_idx[1] = tail;

        // Defaults are don't-care by specification when commit_valid=0.
        commit_valid     = 2'b00;
        commit_rob_idx   = '0;
        commit_dest_tag  = '0;
        commit_value     = '0;
        commit_exception = '0;

        // Lane 0: head must be allocated and complete.
        if (entries[head].allocated &&
            entries[head].complete) begin

            commit_valid[0]     = 1'b1;
            commit_rob_idx[0]   = head;
            commit_dest_tag[0]  = entries[head].dest_tag;
            commit_value[0]     = entries[head].value;
            commit_exception[0] = entries[head].exception;

            // Lane 1 requires:
            //   * lane 0 commits
            //   * lane 0 has no exception
            //   * next entry is allocated and complete
            //   * next entry survives a flush
            if (!entries[head].exception) begin
                if (entries[inc_idx(head)].allocated &&
                    entries[inc_idx(head)].complete &&
                    !(flush_valid && (flush_rob_idx == head))) begin

                    commit_valid[1]     = 1'b1;
                    commit_rob_idx[1]   = inc_idx(head);
                    commit_dest_tag[1]  = entries[inc_idx(head)].dest_tag;
                    commit_value[1]     = entries[inc_idx(head)].value;
                    commit_exception[1] = entries[inc_idx(head)].exception;
                end
            end
        end
    end

    // -------------------------------------------------------------------------
    // Next-state logic.
    // -------------------------------------------------------------------------
    always_comb begin : next_state

        integer alloc_count;
        integer commit_count;
        integer live_count_after_flush;
        integer flush_distance;
        integer new_free;

        alloc_count = 0;

        if (dispatch_ready) begin
            if (dispatch_valid[0])
                alloc_count = alloc_count + 1;

            if (dispatch_valid[1])
                alloc_count = alloc_count + 1;
        end

        commit_count = 0;

        if (commit_valid[0])
            commit_count = commit_count + 1;

        if (commit_valid[1])
            commit_count = commit_count + 1;

        head_next = head;
        tail_next = tail;

        if (commit_count == 1)
            head_next = inc_idx(head);
        else if (commit_count == 2)
            head_next = inc_idx(inc_idx(head));

        if (flush_valid) begin
            // flush_rob_idx itself survives.
            //
            // Number of live entries from old head through flush point:
            //     distance(head, flush) + 1
            //
            // Then remove entries committing this cycle.
            flush_distance = distance(flush_rob_idx, head);

            live_count_after_flush =
                flush_distance + 1 - commit_count;

            if (live_count_after_flush < 0)
                live_count_after_flush = 0;

            new_free = DEPTH - live_count_after_flush;

            free_entries_next = new_free;

            // Tail is immediately after the surviving flush entry.
            tail_next = inc_idx(flush_rob_idx);
        end
        else begin
            // Normal occupancy:
            //
            // free' = free - allocations + commits
            //
            // Allocations are accepted only when free >= 2.
            new_free = free_entries - alloc_count + commit_count;

            free_entries_next = new_free;

            if (alloc_count == 1)
                tail_next = inc_idx(tail);
            else if (alloc_count == 2)
                tail_next = inc_idx(inc_idx(tail));
        end
    end

    // -------------------------------------------------------------------------
    // Sequential state.
    // -------------------------------------------------------------------------
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            head         <= '0;
            tail         <= '0;
            free_entries <= DEPTH;

            for (k = 0; k < DEPTH; k = k + 1) begin
                entries[k].allocated     <= 1'b0;
                entries[k].complete      <= 1'b0;
                entries[k].pc            <= '0;
                entries[k].dest_tag      <= '0;
                entries[k].value         <= '0;
                entries[k].exception     <= 1'b0;
                entries[k].is_branch     <= 1'b0;
                entries[k].mispredict    <= 1'b0;
                entries[k].actual_target <= '0;
            end
        end
        else begin
            head         <= head_next;
            tail         <= tail_next;
            free_entries <= free_entries_next;

            // -------------------------------------------------------------
            // Commit/free.
            // -------------------------------------------------------------
            if (commit_valid[0]) begin
                entries[commit_rob_idx[0]].allocated <= 1'b0;
                entries[commit_rob_idx[0]].complete  <= 1'b0;
            end

            if (commit_valid[1]) begin
                entries[commit_rob_idx[1]].allocated <= 1'b0;
                entries[commit_rob_idx[1]].complete  <= 1'b0;
            end

            // -------------------------------------------------------------
            // Flush.
            //
            // Anything strictly younger than flush_rob_idx is squashed.
            // The flush entry itself survives.
            // -------------------------------------------------------------
            if (flush_valid) begin
                for (k = 0; k < DEPTH; k = k + 1) begin
                    if (entries[k].allocated &&
                        (k != flush_rob_idx) &&
                        (distance(k, head) >
                         distance(flush_rob_idx, head))) begin

                        entries[k].allocated <= 1'b0;
                        entries[k].complete  <= 1'b0;
                    end
                end
            end

            // -------------------------------------------------------------
            // Dispatch.
            //
            // Dispatch allocations are younger than a simultaneous flush,
            // so they do not survive that flush.
            // -------------------------------------------------------------
            if (dispatch_ready && !flush_valid) begin

                if (dispatch_valid[0]) begin
                    entries[dispatch_rob_idx[0]].allocated     <= 1'b1;
                    entries[dispatch_rob_idx[0]].complete      <= 1'b0;
                    entries[dispatch_rob_idx[0]].pc            <= dispatch_pc[0];
                    entries[dispatch_rob_idx[0]].dest_tag      <= dispatch_dest_tag[0];
                    entries[dispatch_rob_idx[0]].value         <= '0;
                    entries[dispatch_rob_idx[0]].exception     <= 1'b0;
                    entries[dispatch_rob_idx[0]].is_branch     <= dispatch_is_branch[0];
                    entries[dispatch_rob_idx[0]].mispredict    <= 1'b0;
                    entries[dispatch_rob_idx[0]].actual_target <= '0;
                end

                if (dispatch_valid[1]) begin
                    entries[dispatch_rob_idx[1]].allocated     <= 1'b1;
                    entries[dispatch_rob_idx[1]].complete      <= 1'b0;
                    entries[dispatch_rob_idx[1]].pc            <= dispatch_pc[1];
                    entries[dispatch_rob_idx[1]].dest_tag      <= dispatch_dest_tag[1];
                    entries[dispatch_rob_idx[1]].value         <= '0;
                    entries[dispatch_rob_idx[1]].exception     <= 1'b0;
                    entries[dispatch_rob_idx[1]].is_branch     <= dispatch_is_branch[1];
                    entries[dispatch_rob_idx[1]].mispredict    <= 1'b0;
                    entries[dispatch_rob_idx[1]].actual_target <= '0;
                end
            end

            // -------------------------------------------------------------
            // Completion lane 0.
            //
            // Drop it if its entry is strictly younger than the flush point.
            // -------------------------------------------------------------
            if (complete_valid[0]) begin
                if (!flush_valid ||
                    (complete_rob_idx[0] == flush_rob_idx) ||
                    (distance(complete_rob_idx[0], head) <=
                     distance(flush_rob_idx, head))) begin

                    entries[complete_rob_idx[0]].complete   <= 1'b1;
                    entries[complete_rob_idx[0]].value      <= complete_value[0];
                    entries[complete_rob_idx[0]].exception  <= complete_exception[0];

                    if (entries[complete_rob_idx[0]].is_branch) begin
                        entries[complete_rob_idx[0]].mispredict    <= complete_mispredict[0];
                        entries[complete_rob_idx[0]].actual_target <= complete_actual_target[0];
                    end
                end
            end

            // -------------------------------------------------------------
            // Completion lane 1.
            // -------------------------------------------------------------
            if (complete_valid[1]) begin
                if (!flush_valid ||
                    (complete_rob_idx[1] == flush_rob_idx) ||
                    (distance(complete_rob_idx[1], head) <=
                     distance(flush_rob_idx, head))) begin

                    entries[complete_rob_idx[1]].complete   <= 1'b1;
                    entries[complete_rob_idx[1]].value      <= complete_value[1];
                    entries[complete_rob_idx[1]].exception  <= complete_exception[1];

                    if (entries[complete_rob_idx[1]].is_branch) begin
                        entries[complete_rob_idx[1]].mispredict    <= complete_mispredict[1];
                        entries[complete_rob_idx[1]].actual_target <= complete_actual_target[1];
                    end
                end
            end
        end
    end

endmodule
