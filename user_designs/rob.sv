// =============================================================================
// rob.sv -- 2-wide Reorder Buffer. Implements interfaces/TierTwo/rob_iface.sv.
// =============================================================================
// Built on the user's generic multi-port `queue` primitive, which is kept
// essentially intact -- it already provides exactly the structure this contract
// wants:
//   * a circular buffer with head/tail and a `last_op_write` bit to disambiguate
//     full from empty when the pointers coincide (-> free_entries/full/empty)
//   * COMPACTED multi-port allocation: write_ptrs[0]=tail and
//     write_ptrs[i+1]=write_ptrs[i]+1 only for lanes that actually write, which
//     is the iface's dispatch_rob_idx rule verbatim
//   * head-side multi-port read/accept -> in-order 2-wide commit
//   * `restore_ptr`/`restore` -> flush (tail := flush_rob_idx+1)
//   * the mem_out/mem_in backdoor -> out-of-order writeback into allocated
//     entries, which is what the original core used it for (CDB writeback)
//
// Two targeted changes inside `queue`, both forced by this contract and marked
// at the site:
//   1. on restore it held `head`; here flush and commit are explicitly
//      independent and may occur in the same cycle, so head must still advance.
//   2. `restore_is_full` is now sampled against head_next rather than head, for
//      the same reason, and the ROB drives it with a real computation instead of
//      the original's constant 1'b1 (which assumed the branch never retires in
//      the squash cycle -- here it can).
// =============================================================================

module queue #(
    parameter type T         = logic[63:0],
    parameter int  PTR_WIDTH = 7,
    parameter type PTR       = logic[PTR_WIDTH-1:0],
    parameter int  CNT_WIDTH = PTR_WIDTH + 1,
    parameter type CNT       = logic[CNT_WIDTH-1:0],
    parameter int  DEPTH     = 1 << PTR_WIDTH,
    parameter int  PORTS     = 3,
    parameter type PORT_CNT  = logic[$clog2(PORTS+1)-1:0]
) (
    input logic clock,
    input logic reset,

    input  T     [PORTS-1:0] write_data,
    input  logic [PORTS-1:0] write_valid,
    output logic [PORTS-1:0] write_space,
    output PTR   [PORTS:0]   write_ptrs,

    input  PTR   restore_ptr,
    input  logic restore_is_full,
    input  logic restore,

    output T     [PORTS-1:0] read_data,
    output logic [PORTS-1:0] read_valid,
    input  logic [PORTS-1:0] read_accept,
    output PTR   [PORTS:0]   read_ptrs,

    output T     [DEPTH-1:0] mem_out,
    input  T     [DEPTH-1:0] mem_in,

    output CNT              occupancy
);

    T [DEPTH-1:0] mem, mem_next;
    PTR head, head_next;  // head = read side
    PTR tail, tail_next;  // tail = write side
    CNT vacancy;
    logic last_op_write, last_op_write_next;

    assign occupancy = tail == head
        ? (last_op_write ? CNT'(DEPTH) : CNT'('0))
        : CNT'(PTR'(tail - head));

    assign vacancy = CNT'(DEPTH) - occupancy;

    // Count actual writes and reads this cycle
    PORT_CNT write_count, read_count;
    always_comb begin
        write_count = '0;
        for (int i = 0; i < PORTS; i++) begin
            if (write_valid[i] && write_space[i])
                write_count = write_count + PORT_CNT'(1);
        end

        read_count = '0;
        for (int i = 0; i < PORTS; i++) begin
            if (read_valid[i] && read_accept[i])
                read_count = read_count + PORT_CNT'(1);
        end
    end

    assign mem_out = mem;

    // Next state logic
    always_comb begin
        mem_next = mem_in;
        head_next = head;
        tail_next = tail;

        // Calculate tail pointers (index 0 is before any writes)
        write_ptrs[0] = tail;

        // Write logic - compute tail pointers and write to memory
        for (int i = 0; i < PORTS; i++) begin
            if (write_valid[i] && write_space[i]) begin
                mem_next[write_ptrs[i]] = write_data[i];
                write_ptrs[i+1] = write_ptrs[i] + PTR'(1);
                tail_next = write_ptrs[i+1];
            end else begin
                write_ptrs[i+1] = write_ptrs[i];
            end
        end

        // Calculate head pointers (index 0 is before any reads)
        read_ptrs[0] = head;

        // Read logic - compute head pointers
        for (int i = 0; i < PORTS; i++) begin
            read_ptrs[i+1] = read_ptrs[i] + PTR'(1);
            if (read_valid[i] && read_accept[i]) begin
                head_next = read_ptrs[i+1];
            end
        end

        // Track last operation type
        last_op_write_next = write_count == read_count ? last_op_write : write_count > read_count;
    end

    // Output logic
    always_comb begin
        for (int i = 0; i < PORTS; i++) begin
            write_space[i] = (CNT'(i) < vacancy);
            read_valid[i] = (CNT'(i) < occupancy);
            read_data[i] = mem[head + PTR'(i)];
        end
    end

    always_ff @(posedge clock) begin
        if (reset) begin
            mem <= '0;
            head <= '0;
            tail <= '0;
            last_op_write <= 1'b0;
        end else if (restore) begin
            mem <= mem_next;  // always apply mem updates (writeback)
            tail <= restore_ptr;
            // CHANGED: commit is independent of flush in this contract, so the
            // head still advances during a restore, and fullness is judged
            // against the POST-commit head.
            head <= head_next;
            last_op_write <= restore_ptr == head_next ? restore_is_full : 1'b0;
        end else begin
            mem <= mem_next;
            head <= head_next;
            tail <= tail_next;
            last_op_write <= last_op_write_next;
        end
    end
endmodule


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

    localparam int LANES = 2;

    typedef struct packed {
        logic              done;           // COMPLETE
        logic              exception;
        logic              is_branch;
        logic              mispredict;
        logic [PC_W-1:0]   actual_target;
        logic [PC_W-1:0]   pc;
        logic [TAG_W-1:0]  dest_tag;
        logic [VAL_W-1:0]  value;
    } rob_entry_t;

    typedef logic [IDX_W-1:0] ptr_t;
    typedef logic [IDX_W:0]   cnt_t;

    rob_entry_t [LANES-1:0] alloc_data;
    logic       [LANES-1:0] alloc_valid;
    logic       [LANES-1:0] alloc_space;
    ptr_t       [LANES:0]   alloc_ptrs;

    rob_entry_t [LANES-1:0] head_data;
    logic       [LANES-1:0] head_valid;     // entry is ALLOCATED
    logic       [LANES-1:0] head_accept;
    ptr_t       [LANES:0]   head_ptrs;

    rob_entry_t [DEPTH-1:0] mem_out, mem_in;
    cnt_t                   occupancy;

    logic                   restore_is_full;

    // -----------------------------------------------------------------------
    // status
    // -----------------------------------------------------------------------
    assign free_entries   = CNT_W'(cnt_t'(DEPTH) - occupancy);
    assign rob_full       = (occupancy == cnt_t'(DEPTH));
    assign rob_empty      = (occupancy == '0);

    // -----------------------------------------------------------------------
    // dispatch -- ready is (free_entries >= 2), INDEPENDENT of dispatch_valid,
    // so allocation of the group is atomic.
    // -----------------------------------------------------------------------
    assign dispatch_ready = alloc_space[1];   // vacancy >= 2

    always_comb begin
        for (int i = 0; i < LANES; i++) begin
            alloc_valid[i] = dispatch_ready && dispatch_valid[i];
            alloc_data[i]  = '0;
            alloc_data[i].done      = 1'b0;
            alloc_data[i].exception = 1'b0;
            alloc_data[i].is_branch = dispatch_is_branch[i];
            alloc_data[i].pc        = dispatch_pc[i];
            alloc_data[i].dest_tag  = dispatch_dest_tag[i];
        end
    end

    assign dispatch_rob_idx[0] = alloc_ptrs[0];
    assign dispatch_rob_idx[1] = alloc_ptrs[1];

    // -----------------------------------------------------------------------
    // age helper: offset of idx from the head, in entries
    // -----------------------------------------------------------------------
    function automatic logic [IDX_W-1:0] age_of(input logic [IDX_W-1:0] idx);
        age_of = idx - head_ptrs[0];
    endfunction

    // an entry is squashed by this cycle's flush iff it is STRICTLY YOUNGER
    // than flush_rob_idx (the entry AT flush_rob_idx survives)
    function automatic logic squashed(input logic [IDX_W-1:0] idx);
        squashed = flush_valid && (age_of(idx) > age_of(flush_rob_idx));
    endfunction

    // -----------------------------------------------------------------------
    // completion -- random-access writeback through the queue's mem backdoor.
    // A completion whose entry is squashed this cycle is DROPPED.
    // -----------------------------------------------------------------------
    always_comb begin
        mem_in = mem_out;
        for (int i = 0; i < LANES; i++) begin
            if (complete_valid[i] && !squashed(complete_rob_idx[i])) begin
                mem_in[complete_rob_idx[i]].done      = 1'b1;
                mem_in[complete_rob_idx[i]].value     = complete_value[i];
                mem_in[complete_rob_idx[i]].exception = complete_exception[i];
                if (mem_out[complete_rob_idx[i]].is_branch) begin
                    mem_in[complete_rob_idx[i]].mispredict    = complete_mispredict[i];
                    mem_in[complete_rob_idx[i]].actual_target = complete_actual_target[i];
                end
            end
        end
    end

    // -----------------------------------------------------------------------
    // commit -- in order from the head, contiguous, stops at an exception, and
    // never commits an entry that this cycle's flush squashes.
    // -----------------------------------------------------------------------
    always_comb begin
        commit_valid[0] = head_valid[0] && head_data[0].done;
        commit_valid[1] = commit_valid[0] &&
                          head_valid[1] && head_data[1].done &&
                          !head_data[0].exception &&
                          !squashed(head_ptrs[1]);

        for (int i = 0; i < LANES; i++) begin
            commit_rob_idx[i]   = head_ptrs[i];
            commit_dest_tag[i]  = head_data[i].dest_tag;
            commit_value[i]     = head_data[i].value;
            commit_exception[i] = head_data[i].exception;
        end
    end

    assign head_accept = commit_valid;

    // -----------------------------------------------------------------------
    // flush -- tail becomes flush_rob_idx+1. The post-flush queue is FULL when
    // the surviving range wraps all the way round, which is the case unless the
    // flushed branch itself retires in this same cycle.
    // -----------------------------------------------------------------------
    always_comb begin
        restore_is_full = 1'b1;
        for (int i = 0; i < LANES; i++)
            if (commit_valid[i] && commit_rob_idx[i] == flush_rob_idx)
                restore_is_full = 1'b0;
    end

    queue #(
        .T         (rob_entry_t),
        .PTR_WIDTH (IDX_W),
        .PORTS     (LANES)
    ) buffer (
        .clock (clk),
        .reset (!rst_n),

        .write_data  (alloc_data),
        .write_valid (alloc_valid),
        .write_space (alloc_space),
        .write_ptrs  (alloc_ptrs),

        .restore_ptr     (flush_rob_idx + ptr_t'(1)),
        .restore_is_full (restore_is_full),
        .restore         (flush_valid),

        .read_data   (head_data),
        .read_valid  (head_valid),
        .read_accept (head_accept),
        .read_ptrs   (head_ptrs),

        .mem_out (mem_out),
        .mem_in  (mem_in),

        .occupancy (occupancy)
    );

endmodule
