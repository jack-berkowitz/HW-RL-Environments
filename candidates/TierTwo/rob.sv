// =============================================================================
// rob.sv
// =============================================================================
// 2-wide Reorder Buffer
//
// Features:
//   - Circular ROB
//   - 2-wide atomic/compacted dispatch
//   - Out-of-order completion
//   - In-order 2-wide commit
//   - Exception stopping commit
//   - Misprediction flush
//   - Same-cycle flush/commit handling
//   - Same-cycle completion/flush handling
//
// Timing:
//   - All outputs are combinational from registered state.
//   - Completion at cycle N is eligible for commit in cycle N+1.
//   - Dispatch at cycle N is not eligible for commit until N+1.
//
// =============================================================================

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

    // =========================================================================
    // ROB ENTRY
    // =========================================================================

    typedef struct packed {
        logic                    allocated;
        logic                    complete;

        logic [PC_W-1:0]         pc;
        logic [TAG_W-1:0]        dest_tag;

        logic [VAL_W-1:0]        value;
        logic                    exception;

        logic                    is_branch;
        logic                    mispredict;
        logic [PC_W-1:0]         actual_target;
    } rob_entry_t;

    rob_entry_t rob [0:DEPTH-1];

    // =========================================================================
    // POINTER / OCCUPANCY STATE
    // =========================================================================

    logic [IDX_W-1:0] head;
    logic [IDX_W-1:0] tail;

    logic [CNT_W-1:0] occupancy;

    logic [IDX_W-1:0] head_next;
    logic [IDX_W-1:0] tail_next;
    logic [CNT_W-1:0] occupancy_next;

    // Number of dispatch lanes which actually allocate.
    logic [1:0] dispatch_count;

    // Number of entries which commit this cycle.
    logic [1:0] commit_count;

    // =========================================================================
    // HELPER FUNCTIONS
    // =========================================================================

    // Circular increment.
    //
    // Since DEPTH is a power of two, IDX_W bits naturally wrap around.
    function automatic logic [IDX_W-1:0] idx_add(
        input logic [IDX_W-1:0] idx,
        input int unsigned      amount
    );
        logic [IDX_W-1:0] amount_idx;
        begin
            amount_idx = amount;
            idx_add = idx + amount_idx;
        end
    endfunction

    // Distance from head.
    //
    // Because DEPTH is a power of two and IDX_W=$clog2(DEPTH),
    // subtraction naturally performs modulo-DEPTH arithmetic.
    function automatic logic [IDX_W-1:0] age_from_head(
        input logic [IDX_W-1:0] idx
    );
        begin
            age_from_head = idx - head;
        end
    endfunction

    // Is an index strictly younger than flush_rob_idx?
    //
    // Age is relative to head:
    //
    //       head ---> ... ---> flush ---> younger entries ---> tail
    //
    // Therefore an entry is younger iff its circular age is greater than
    // the age of the flush entry.
    function automatic logic is_younger_than_flush(
        input logic [IDX_W-1:0] idx
    );
        logic [IDX_W-1:0] idx_age;
        logic [IDX_W-1:0] flush_age;

        begin
            idx_age   = age_from_head(idx);
            flush_age = age_from_head(flush_rob_idx);

            is_younger_than_flush = (idx_age > flush_age);
        end
    endfunction

    // =========================================================================
    // STATUS OUTPUTS
    // =========================================================================

    always_comb begin
        free_entries = DEPTH - occupancy;

        rob_full  = (free_entries == 0);
        rob_empty = (free_entries == DEPTH);

        // Deliberately independent of dispatch_valid.
        dispatch_ready = (free_entries >= 2);
    end

    // =========================================================================
    // DISPATCH INDEX OUTPUTS
    // =========================================================================
    //
    // Compacted allocation:
    //
    //   valid = 01:
    //       lane 0 -> tail
    //
    //   valid = 10:
    //       lane 1 -> tail
    //
    //   valid = 11:
    //       lane 0 -> tail
    //       lane 1 -> tail + 1
    //
    // dispatch_rob_idx is don't-care for lanes which don't allocate.
    //
    // The specification additionally says this output is combinationally
    // dependent on dispatch_valid.

    always_comb begin
        dispatch_rob_idx = '0;

        if (dispatch_ready) begin
            if (dispatch_valid[0]) begin
                dispatch_rob_idx[0] = tail;
            end

            if (dispatch_valid[1]) begin
                if (dispatch_valid[0])
                    dispatch_rob_idx[1] = idx_add(tail, 1);
                else
                    dispatch_rob_idx[1] = tail;
            end
        end
    end

    // =========================================================================
    // COMMIT LOGIC
    // =========================================================================
    //
    // IMPORTANT:
    //
    // We inspect the CURRENT registered ROB state only.
    //
    // Therefore a completion occurring on this cycle cannot cause commit_valid
    // to assert on this same cycle.
    //
    // This is the key requirement for:
    //
    //   "An entry marked complete at edge N is eligible to commit in cycle N+1."
    //
    // -------------------------------------------------------------------------
    //
    // Lane 0:
    //   head must be allocated and complete.
    //
    // Lane 1:
    //   lane 0 must commit
    //   head+1 must be allocated and complete
    //   lane 0 must not have an exception
    //   head+1 must survive a flush occurring this cycle
    //
    // The only relevant flush case for lane 1 is:
    //
    //   flush_valid && flush_rob_idx == head
    //
    // because the specification guarantees head is never younger than the
    // flush point.
    // =========================================================================

    always_comb begin
        commit_valid     = '0;
        commit_rob_idx   = '0;
        commit_dest_tag  = '0;
        commit_value     = '0;
        commit_exception = '0;

        // -------------------------------------------------------------
        // Commit lane 0
        // -------------------------------------------------------------

        if (rob[head].allocated && rob[head].complete) begin

            // Head is guaranteed to survive the flush according to the
            // interface contract.
            commit_valid[0]     = 1'b1;
            commit_rob_idx[0]   = head;
            commit_dest_tag[0]  = rob[head].dest_tag;
            commit_value[0]     = rob[head].value;
            commit_exception[0] = rob[head].exception;
        end

        // -------------------------------------------------------------
        // Commit lane 1
        // -------------------------------------------------------------

        if (commit_valid[0] &&
            !commit_exception[0] &&
            rob[idx_add(head, 1)].allocated &&
            rob[idx_add(head, 1)].complete) begin

            // If the flush point is head, head+1 is strictly younger and
            // must not commit.
            if (!(flush_valid && (flush_rob_idx == head))) begin
                commit_valid[1]     = 1'b1;
                commit_rob_idx[1]   = idx_add(head, 1);
                commit_dest_tag[1]  = rob[idx_add(head, 1)].dest_tag;
                commit_value[1]     = rob[idx_add(head, 1)].value;
                commit_exception[1] = rob[idx_add(head, 1)].exception;
            end
        end
    end

    // =========================================================================
    // NEXT-STATE CONTROL
    // =========================================================================

    always_comb begin

        // -------------------------------------------------------------
        // Dispatch count
        // -------------------------------------------------------------

        dispatch_count = 2'd0;

        if (dispatch_ready) begin
            dispatch_count =
                {1'b0, dispatch_valid[0]} +
                {1'b0, dispatch_valid[1]};
        end

        // -------------------------------------------------------------
        // Commit count
        // -------------------------------------------------------------

        commit_count =
            {1'b0, commit_valid[0]} +
            {1'b0, commit_valid[1]};

        // -------------------------------------------------------------
        // Default pointer behavior
        // -------------------------------------------------------------

        head_next      = head;
        tail_next      = tail;
        occupancy_next = occupancy;

        // -------------------------------------------------------------
        // HEAD
        // -------------------------------------------------------------
        //
        // Flush does NOT move head.
        //
        // Commit advances head normally.
        //
        // Therefore:
        //
        //     head_next = head + commit_count
        //

        if (commit_count != 0)
            head_next = idx_add(head, commit_count);

        // -------------------------------------------------------------
        // TAIL / OCCUPANCY
        // -------------------------------------------------------------
        //
        // Flush has priority over normal tail allocation.
        //
        // If no flush:
        //     tail += dispatch_count
        //
        // If flush:
        //     tail = flush_rob_idx + 1
        //
        // Entries allocated in the same cycle as a flush are younger than
        // the flush point and therefore disappear. Consequently dispatch
        // does not contribute to the post-flush occupancy.
        //
        // The number of surviving entries after a flush is:
        //
        //     distance(head, flush_rob_idx) + 1
        //
        // minus anything committed this cycle.
        // -------------------------------------------------------------

        if (flush_valid) begin

            tail_next = idx_add(flush_rob_idx, 1);

            // Number of live entries from head through flush_rob_idx,
            // inclusive.
            //
            // age_from_head(flush_rob_idx) is:
            //
            //   0 if flush is head
            //   1 if flush is head+1
            //   ...
            //
            // Thus number of surviving entries before commit =
            // age + 1.
            occupancy_next =
                age_from_head(flush_rob_idx) + 1;

            // Commit removes entries from the front at this same edge.
            occupancy_next =
                occupancy_next - commit_count;

        end
        else begin

            // Normal circular-buffer operation.
            occupancy_next =
                occupancy
                + dispatch_count
                - commit_count;

            tail_next =
                idx_add(tail, dispatch_count);
        end
    end

    // =========================================================================
    // SEQUENTIAL ROB STATE
    // =========================================================================

    integer i;

    always_ff @(posedge clk) begin

        // ---------------------------------------------------------------------
        // Synchronous active-low reset
        // ---------------------------------------------------------------------

        if (!rst_n) begin

            head      <= '0;
            tail      <= '0;
            occupancy <= DEPTH;

            for (i = 0; i < DEPTH; i = i + 1) begin
                rob[i].allocated      <= 1'b0;
                rob[i].complete       <= 1'b0;

                rob[i].pc             <= '0;
                rob[i].dest_tag      <= '0;

                rob[i].value          <= '0;
                rob[i].exception      <= 1'b0;

                rob[i].is_branch      <= 1'b0;
                rob[i].mispredict     <= 1'b0;
                rob[i].actual_target  <= '0;
            end
        end

        // ---------------------------------------------------------------------
        // Normal operation
        // ---------------------------------------------------------------------

        else begin

            // =================================================================
            // POINTER / OCCUPANCY UPDATE
            // =================================================================

            head      <= head_next;
            tail      <= tail_next;
            occupancy <= occupancy_next;

            // =================================================================
            // FLUSH
            // =================================================================
            //
            // Clear every entry strictly younger than flush_rob_idx.
            //
            // We do this before/alongside allocation/completion logic below.
            // A completion targeting one of these entries is explicitly
            // prevented from being written later in this same clock edge.
            // =================================================================

            if (flush_valid) begin

                for (i = 0; i < DEPTH; i = i + 1) begin

                    if (rob[i].allocated &&
                        is_younger_than_flush(i[IDX_W-1:0])) begin

                        rob[i].allocated <= 1'b0;
                        rob[i].complete  <= 1'b0;

                        rob[i].pc             <= '0;
                        rob[i].dest_tag       <= '0;
                        rob[i].value          <= '0;
                        rob[i].exception      <= 1'b0;
                        rob[i].is_branch      <= 1'b0;
                        rob[i].mispredict     <= 1'b0;
                        rob[i].actual_target  <= '0;
                    end
                end
            end

            // =================================================================
            // DISPATCH / ALLOCATION
            // =================================================================
            //
            // Only allocate when dispatch_ready is asserted.
            //
            // If flush_valid is simultaneously asserted, the allocated entries
            // are younger than the flush point and are therefore discarded.
            //
            // We still perform the allocation here because it is the natural
            // interpretation of the dispatch transaction at this edge; the
            // flush logic above and tail recovery make those entries dead after
            // the edge.
            // =================================================================

            if (dispatch_ready) begin

                if (dispatch_valid[0]) begin

                    rob[dispatch_rob_idx[0]].allocated     <= 1'b1;
                    rob[dispatch_rob_idx[0]].complete      <= 1'b0;

                    rob[dispatch_rob_idx[0]].pc            <= dispatch_pc[0];
                    rob[dispatch_rob_idx[0]].dest_tag      <= dispatch_dest_tag[0];

                    rob[dispatch_rob_idx[0]].value         <= '0;
                    rob[dispatch_rob_idx[0]].exception     <= 1'b0;

                    rob[dispatch_rob_idx[0]].is_branch     <= dispatch_is_branch[0];
                    rob[dispatch_rob_idx[0]].mispredict    <= 1'b0;
                    rob[dispatch_rob_idx[0]].actual_target <= '0;
                end

                if (dispatch_valid[1]) begin

                    rob[dispatch_rob_idx[1]].allocated     <= 1'b1;
                    rob[dispatch_rob_idx[1]].complete      <= 1'b0;

                    rob[dispatch_rob_idx[1]].pc            <= dispatch_pc[1];
                    rob[dispatch_rob_idx[1]].dest_tag      <= dispatch_dest_tag[1];

                    rob[dispatch_rob_idx[1]].value         <= '0;
                    rob[dispatch_rob_idx[1]].exception     <= 1'b0;

                    rob[dispatch_rob_idx[1]].is_branch     <= dispatch_is_branch[1];
                    rob[dispatch_rob_idx[1]].mispredict    <= 1'b0;
                    rob[dispatch_rob_idx[1]].actual_target <= '0;
                end
            end

            // =================================================================
            // COMMIT / FREE
            // =================================================================
            //
            // Entries are freed when they commit.
            //
            // This is done independently of flush because commit and flush
            // operate on opposite ends of the ROB.
            //
            // If the same entry is both the flush point and commits, it survives
            // the flush but is then freed by commit, exactly as required.
            // =================================================================

            if (commit_valid[0]) begin

                rob[commit_rob_idx[0]].allocated <= 1'b0;
                rob[commit_rob_idx[0]].complete  <= 1'b0;
            end

            if (commit_valid[1]) begin

                rob[commit_rob_idx[1]].allocated <= 1'b0;
                rob[commit_rob_idx[1]].complete  <= 1'b0;
            end

            // =================================================================
            // COMPLETE / WRITEBACK
            // =================================================================
            //
            // Completion is applied to the CURRENT ROB entry.
            //
            // A completion is dropped when its target is strictly younger
            // than the flush point in the same cycle.
            //
            // This prevents:
            //
            //   completion -> squashed entry
            //
            // from accidentally reviving an entry.
            //
            // A completion for flush_rob_idx itself is allowed.
            //
            // A completion for an entry committing this cycle is also harmless
            // under the stated testbench contract because a complete entry is
            // never completed twice. More importantly, commit_valid is based on
            // the old registered state, so the completion cannot cause a new
            // commit until the next cycle.
            // =================================================================

            if (complete_valid[0]) begin

                if (!(flush_valid &&
                      is_younger_than_flush(complete_rob_idx[0]))) begin

                    rob[complete_rob_idx[0]].complete <= 1'b1;
                    rob[complete_rob_idx[0]].value    <= complete_value[0];
                    rob[complete_rob_idx[0]].exception <= complete_exception[0];

                    if (rob[complete_rob_idx[0]].is_branch) begin
                        rob[complete_rob_idx[0]].mispredict =
                            complete_mispredict[0];

                        rob[complete_rob_idx[0]].actual_target =
                            complete_actual_target[0];
                    end
                end
            end

            if (complete_valid[1]) begin

                if (!(flush_valid &&
                      is_younger_than_flush(complete_rob_idx[1]))) begin

                    rob[complete_rob_idx[1]].complete <= 1'b1;
                    rob[complete_rob_idx[1]].value    <= complete_value[1];
                    rob[complete_rob_idx[1]].exception <= complete_exception[1];

                    if (rob[complete_rob_idx[1]].is_branch) begin
                        rob[complete_rob_idx[1]].mispredict =
                            complete_mispredict[1];

                        rob[complete_rob_idx[1]].actual_target =
                            complete_actual_target[1];
                    end
                end
            end
        end
    end

endmodule