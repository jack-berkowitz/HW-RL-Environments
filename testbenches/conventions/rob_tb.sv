// =============================================================================
// rob_tb.sv -- self-checking testbench for `rob` (see rob_iface.sv)
// =============================================================================
// Reference model: a plain software mirror of the circular buffer (per-entry
// alloc/done/payload arrays plus head/tail/count integers) maintained by the
// testbench. It is algorithmic bookkeeping, not an RTL re-implementation: no
// clocked always blocks, no pointer arithmetic copied from a hardware design.
//
// The model alone is NOT the whole check. Every dispatched instruction is also
// tagged with a monotonically increasing SEQUENCE NUMBER, and the commit stream
// is graded against that sequence independently of the model:
//
//   * commit order   -- the seq committing on each lane must be exactly the next
//                       one expected. This single check catches out-of-order
//                       commit, skipped entries AND double-commit at once (a
//                       repeat commits a seq below the expected one).
//   * payload        -- dest_tag/value/exception are shadowed per seq at
//                       dispatch/completion and re-checked at commit, so a ROB
//                       that commits the right seq with another entry's data is
//                       still caught.
//   * completeness   -- an entry may not commit unless the model saw it marked
//                       complete on an earlier edge.
//   * flush accounting -- after a flush, free_entries must match exactly, and
//                       the seq counter rolls back to the survivor, so any
//                       squashed instruction that later commits shows up as an
//                       order violation.
//
// This redundancy is deliberate: a bug in the model cannot silently excuse the
// same bug in the DUT, because the two checks are derived differently.
//
// SystemVerilog subset: the scoreboard is procedural (module-level unpacked
// arrays + queues of packed vectors) rather than class-based. That was forced
// when this was authored under Icarus; it is now a deliberate choice, because
// the resulting harness runs unmodified under BOTH Verilator and Icarus, which
// gives a free 4-state cross-check against Verilator's 2-state engine.
// See CONVENTIONS.md (repo root).
//
// Run (Verilator is the supported path). NOTE: the command below is written
// with a leading "$ " on purpose -- a comment whose first word is the tool's
// own name is parsed as a metacomment pragma and errors out (BADVLTPRAGMA).
//   $ verilator --binary --timing -j 0 -Wno-fatal --x-assign unique --x-initial unique --top-module rob_tb -Mdir obj_dir -o sim rob_tb.sv rob.sv
//   $ obj_dir/sim
// Parameter override: -GDEPTH=32 under Verilator (bare name, NOT
// -Grob_tb.DEPTH=32, which errors), or -P rob_tb.DEPTH=32 under Icarus.
//
// Final line is exactly one of:
//   TEST_RESULT: PASS
//   TEST_RESULT: FAIL: <reason>
// =============================================================================

`timescale 1ns/1ps

module rob_tb;

    // ---------------- configuration ----------------
    parameter int DEPTH               = 16;    // 8 / 16 / 32 / 64
    parameter int PC_W                = 32;
    parameter int TAG_W               = 6;
    parameter int VAL_W               = 32;
    parameter int RANDOM_CYCLES       = 12000; // >= 10000 required
    parameter int MAX_ERRORS_REPORTED = 20;

    localparam int IDX_W = $clog2(DEPTH);
    localparam int CNT_W = $clog2(DEPTH+1);
    localparam int SHW   = 4*DEPTH;            // seq-shadow ring, >> max live

    // ---------------- DUT connections ----------------
    logic                  clk = 1'b0;
    logic                  rst_n;

    logic [1:0]            dispatch_valid;
    logic                  dispatch_ready;
    logic [1:0][PC_W-1:0]  dispatch_pc;
    logic [1:0][TAG_W-1:0] dispatch_dest_tag;
    logic [1:0]            dispatch_is_branch;
    logic [1:0][IDX_W-1:0] dispatch_rob_idx;

    logic [1:0]            complete_valid;
    logic [1:0][IDX_W-1:0] complete_rob_idx;
    logic [1:0][VAL_W-1:0] complete_value;
    logic [1:0]            complete_exception;
    logic [1:0]            complete_mispredict;
    logic [1:0][PC_W-1:0]  complete_actual_target;

    logic [1:0]            commit_valid;
    logic [1:0][IDX_W-1:0] commit_rob_idx;
    logic [1:0][TAG_W-1:0] commit_dest_tag;
    logic [1:0][VAL_W-1:0] commit_value;
    logic [1:0]            commit_exception;

    logic                  flush_valid;
    logic [IDX_W-1:0]      flush_rob_idx;

    logic                  rob_full, rob_empty;
    logic [CNT_W-1:0]      free_entries;

    rob #(
        .DEPTH (DEPTH), .PC_W (PC_W), .TAG_W (TAG_W), .VAL_W (VAL_W)
    ) dut (
        .clk (clk), .rst_n (rst_n),
        .dispatch_valid (dispatch_valid), .dispatch_ready (dispatch_ready),
        .dispatch_pc (dispatch_pc), .dispatch_dest_tag (dispatch_dest_tag),
        .dispatch_is_branch (dispatch_is_branch), .dispatch_rob_idx (dispatch_rob_idx),
        .complete_valid (complete_valid), .complete_rob_idx (complete_rob_idx),
        .complete_value (complete_value), .complete_exception (complete_exception),
        .complete_mispredict (complete_mispredict),
        .complete_actual_target (complete_actual_target),
        .commit_valid (commit_valid), .commit_rob_idx (commit_rob_idx),
        .commit_dest_tag (commit_dest_tag), .commit_value (commit_value),
        .commit_exception (commit_exception),
        .flush_valid (flush_valid), .flush_rob_idx (flush_rob_idx),
        .rob_full (rob_full), .rob_empty (rob_empty), .free_entries (free_entries)
    );

    always #5 clk = ~clk;

    // ---------------- bookkeeping ----------------
    int    errors = 0;
    int    checks = 0;
    int    d_errors = 0;                 // errors accumulated during directed phase
    string fail_reason = "";
    string phase = "init";
    int    cyc = 0;

    task automatic note_fail(input string why);
        errors++;
        if (fail_reason == "") fail_reason = why;
        if (errors <= MAX_ERRORS_REPORTED)
            $display("[FAIL] cyc=%0d t=%0t phase=%s : %s", cyc, $time, phase, why);
        else if (errors == MAX_ERRORS_REPORTED + 1)
            $display("[FAIL] ... further failures suppressed");
    endtask

    // ---------------- functional coverage (plain counters) ----------------
    int cov_disp_group [0:2];      // dispatch groups accepted, by width
    int cov_disp_stall;            // valid presented while ready==0
    int cov_full;                  // rob_full observed
    int cov_one_free;              // exactly one entry free (ready==0, !full)
    int cov_commit_w [0:2];        // commit width per cycle
    int cov_ooo_complete;          // completed an entry that was not the head
    int cov_flush_none;            // flush that squashed nothing (at tail)
    int cov_flush_part;            // flush that squashed some but not all
    int cov_flush_all;             // flush at head: squashed everything but head
    int cov_race_cf;               // completion targeting an entry squashed same cycle
    int cov_commit_exc;            // an entry committed with exception
    int cov_mispredict;            // branch completed with mispredict
    int cov_wrap;                  // tail wrapped past DEPTH-1
    int cov_flush_commit;          // flush and commit in the same cycle
    int cov_head_flush_c1;         // flush_rob_idx==head suppressing commit lane 1

    // =========================================================================
    // Reference model  (mirrors the spec, not the DUT)
    // =========================================================================
    logic             m_alloc  [DEPTH];
    logic             m_done   [DEPTH];
    logic [TAG_W-1:0] m_tag    [DEPTH];
    logic             m_branch [DEPTH];
    logic [VAL_W-1:0] m_val    [DEPTH];
    logic             m_exc    [DEPTH];
    int               m_seq    [DEPTH];
    int               m_head, m_tail, m_count;

    // seq-keyed shadow of what each instruction SHOULD commit with
    logic [TAG_W-1:0] sh_tag [SHW];
    logic [VAL_W-1:0] sh_val [SHW];
    logic             sh_exc [SHW];

    int total_commits;       // cumulative across resets (summary only)
    int next_seq;            // next sequence number to hand out at dispatch
    int expect_commit_seq;   // next sequence number that must commit

    // per-entry completion scheduling (testbench side, not part of the model)
    logic pend_active [DEPTH];   // allocated, not yet completed
    int   pend_delay  [DEPTH];   // cycles remaining before it may complete

    function automatic void model_reset();
        for (int i = 0; i < DEPTH; i++) begin
            m_alloc[i]     = 1'b0;
            m_done[i]      = 1'b0;
            pend_active[i] = 1'b0;
            pend_delay[i]  = 0;
        end
        m_head = 0; m_tail = 0; m_count = 0;
        next_seq = 0; expect_commit_seq = 0;
    endfunction

    function automatic int relage(input int idx);
        return (idx - m_head + DEPTH) % DEPTH;
    endfunction

    // does a same-cycle flush squash this index?
    function automatic bit m_squashed(input int idx);
        if (!flush_valid) return 1'b0;
        if (!m_alloc[idx]) return 1'b0;
        return (relage(idx) > relage(int'(flush_rob_idx)));
    endfunction

    // ---- expected combinational outputs, from PRE-EDGE model state ----
    int  e_free;
    bit  e_ready, e_full, e_empty;
    int  e_idx0, e_idx1;
    bit  e_cv0, e_cv1;
    int  e_head1;

    function automatic void model_predict();
        e_free  = DEPTH - m_count;
        e_ready = (e_free >= 2);
        e_full  = (m_count == DEPTH);
        e_empty = (m_count == 0);
        e_idx0  = m_tail;
        e_idx1  = (m_tail + (dispatch_valid[0] ? 1 : 0)) % DEPTH;
        e_head1 = (m_head + 1) % DEPTH;

        e_cv0 = m_alloc[m_head] && m_done[m_head];
        e_cv1 = e_cv0
              && !m_exc[m_head]
              && !(flush_valid && relage(int'(flush_rob_idx)) == 0)
              && m_alloc[e_head1] && m_done[e_head1];
    endfunction

    // =========================================================================
    // Checking
    // =========================================================================
    int obs_seq;

    task automatic check_outputs();
        checks++;

        if (dispatch_ready !== e_ready)
            note_fail($sformatf("dispatch_ready=%0b expected %0b (free=%0d)",
                                dispatch_ready, e_ready, e_free));
        if (free_entries !== CNT_W'(e_free))
            note_fail($sformatf("free_entries=%0d expected %0d",
                                free_entries, e_free));
        if (rob_full !== e_full)
            note_fail($sformatf("rob_full=%0b expected %0b (free=%0d)",
                                rob_full, e_full, e_free));
        if (rob_empty !== e_empty)
            note_fail($sformatf("rob_empty=%0b expected %0b (free=%0d)",
                                rob_empty, e_empty, e_free));

        // allocated index must match the compacted assignment
        if (e_ready && dispatch_valid[0] && dispatch_rob_idx[0] !== IDX_W'(e_idx0))
            note_fail($sformatf("dispatch_rob_idx[0]=%0d expected %0d (tail=%0d)",
                                dispatch_rob_idx[0], e_idx0, m_tail));
        if (e_ready && dispatch_valid[1] && dispatch_rob_idx[1] !== IDX_W'(e_idx1))
            note_fail($sformatf("dispatch_rob_idx[1]=%0d expected %0d (tail=%0d v0=%0b)",
                                dispatch_rob_idx[1], e_idx1, m_tail, dispatch_valid[0]));

        // ---- commit: structural invariants, independent of the model ----
        if (commit_valid[1] === 1'b1 && commit_valid[0] !== 1'b1)
            note_fail("commit lane 1 valid without lane 0 (commit must be contiguous)");

        if (commit_valid !== {e_cv1, e_cv0})
            note_fail($sformatf("commit_valid=%0b expected %0b (head=%0d alloc=%0b done=%0b exc=%0b | h+1 alloc=%0b done=%0b | flush=%0b)",
                                commit_valid, {e_cv1, e_cv0}, m_head,
                                m_alloc[m_head], m_done[m_head], m_exc[m_head],
                                m_alloc[e_head1], m_done[e_head1], flush_valid));

        for (int L = 0; L < 2; L++) begin
            if (commit_valid[L] !== 1'b1) continue;
            begin
                int exp_idx, dut_idx;
                exp_idx = (L == 0) ? m_head : e_head1;
                // Grade the entry the DUT SAYS it committed, not the one the
                // model expected -- otherwise the order and payload checks
                // degenerate into the model checking itself.
                dut_idx = int'(commit_rob_idx[L]);

                // commits only from the head, in order
                if (dut_idx != exp_idx)
                    note_fail($sformatf("commit lane %0d idx=%0d expected head-relative %0d",
                                        L, dut_idx, exp_idx));

                // never commit an entry that is not allocated+complete
                if (!m_alloc[dut_idx])
                    note_fail($sformatf("commit lane %0d: entry %0d is not allocated (already committed or squashed?)",
                                        L, dut_idx));
                if (!m_done[dut_idx])
                    note_fail($sformatf("commit lane %0d: entry %0d committed before completion",
                                        L, dut_idx));

                // program order / no-duplicate, checked against the seq stream
                obs_seq = m_seq[dut_idx];
                if (obs_seq != expect_commit_seq)
                    note_fail($sformatf("commit lane %0d out of program order: got seq %0d, expected seq %0d (idx %0d)",
                                        L, obs_seq, expect_commit_seq, exp_idx));
                else begin
                    // payload integrity, shadowed by seq at dispatch/completion
                    if (commit_dest_tag[L] !== sh_tag[obs_seq % SHW])
                        note_fail($sformatf("seq %0d commit_dest_tag=0x%0h expected 0x%0h",
                                            obs_seq, commit_dest_tag[L], sh_tag[obs_seq % SHW]));
                    if (commit_value[L] !== sh_val[obs_seq % SHW])
                        note_fail($sformatf("seq %0d commit_value=0x%0h expected 0x%0h",
                                            obs_seq, commit_value[L], sh_val[obs_seq % SHW]));
                    if (commit_exception[L] !== sh_exc[obs_seq % SHW])
                        note_fail($sformatf("seq %0d commit_exception=%0b expected %0b",
                                            obs_seq, commit_exception[L], sh_exc[obs_seq % SHW]));
                    expect_commit_seq++;
                    total_commits++;
                end
            end
        end

        // exception must terminate the commit group
        if (commit_valid[0] && commit_exception[0] && commit_valid[1])
            note_fail("commit lane 1 committed behind an exception on lane 0");
    endtask

    // =========================================================================
    // Model advance (at the clock edge), mirroring the spec's ordering
    // =========================================================================
    int n_commit, n_alloc, surviving;

    task automatic model_update();
        n_commit = (e_cv0 ? 1 : 0) + (e_cv1 ? 1 : 0);
        n_alloc  = e_ready ? ((dispatch_valid[0] ? 1 : 0) + (dispatch_valid[1] ? 1 : 0)) : 0;

        // coverage on this cycle's shape
        cov_commit_w[n_commit]++;
        if (e_ready) cov_disp_group[n_alloc]++;
        if (!e_ready && |dispatch_valid) cov_disp_stall++;
        if (e_full) cov_full++;
        if (e_free == 1) cov_one_free++;
        if (flush_valid && n_commit > 0) cov_flush_commit++;
        if (flush_valid && relage(int'(flush_rob_idx)) == 0 &&
            m_alloc[(m_head+1)%DEPTH] && m_done[(m_head+1)%DEPTH]) cov_head_flush_c1++;

        // ---- completion (dropped if squashed this cycle) ----
        for (int L = 0; L < 2; L++) begin
            if (!complete_valid[L]) continue;
            begin
                int ci;
                ci = int'(complete_rob_idx[L]);
                if (m_squashed(ci)) begin
                    cov_race_cf++;
                end else begin
                    if (relage(ci) != 0) cov_ooo_complete++;
                    m_done[ci] = 1'b1;
                    m_val[ci]  = complete_value[L];
                    m_exc[ci]  = complete_exception[L];
                    sh_val[m_seq[ci] % SHW] = complete_value[L];
                    sh_exc[m_seq[ci] % SHW] = complete_exception[L];
                    if (m_branch[ci] && complete_mispredict[L]) cov_mispredict++;
                    if (complete_exception[L]) cov_commit_exc++;
                end
            end
        end

        // ---- commit frees head entries ----
        if (e_cv0) begin m_alloc[m_head] = 1'b0; pend_active[m_head] = 1'b0; end
        if (e_cv1) begin m_alloc[e_head1] = 1'b0; pend_active[e_head1] = 1'b0; end

        // ---- flush truncates the tail; otherwise dispatch extends it ----
        if (flush_valid) begin
            int nsq;
            nsq = 0;
            for (int i = 0; i < DEPTH; i++)
                if (m_squashed(i)) begin
                    m_alloc[i] = 1'b0;
                    m_done[i]  = 1'b0;
                    pend_active[i] = 1'b0;
                    nsq++;
                end
            if (nsq == 0)                     cov_flush_none++;
            else if (relage(int'(flush_rob_idx)) == 0) cov_flush_all++;
            else                              cov_flush_part++;

            surviving = relage(int'(flush_rob_idx)) + 1;
            // sequence numbers are contiguous head..tail, so the survivor fixes
            // where the next dispatched instruction picks up
            next_seq = m_seq[int'(flush_rob_idx)] + 1;
            m_tail   = (int'(flush_rob_idx) + 1) % DEPTH;
            m_count  = surviving - n_commit;
        end else begin
            if (e_ready) begin
                if (dispatch_valid[0]) alloc_entry(e_idx0, 0);
                if (dispatch_valid[1]) alloc_entry(e_idx1, 1);
            end
            if (m_tail + n_alloc >= DEPTH && n_alloc > 0) cov_wrap++;
            m_tail  = (m_tail + n_alloc) % DEPTH;
            m_count = m_count + n_alloc - n_commit;
        end

        m_head = (m_head + n_commit) % DEPTH;
    endtask

    task automatic alloc_entry(input int idx, input int lane);
        m_alloc[idx]  = 1'b1;
        m_done[idx]   = 1'b0;
        m_tag[idx]    = dispatch_dest_tag[lane];
        m_branch[idx] = dispatch_is_branch[lane];
        m_exc[idx]    = 1'b0;
        m_seq[idx]    = next_seq;
        sh_tag[next_seq % SHW] = dispatch_dest_tag[lane];
        sh_val[next_seq % SHW] = '0;
        sh_exc[next_seq % SHW] = 1'b0;
        next_seq++;
        pend_active[idx] = 1'b1;
        pend_delay[idx]  = $urandom_range(0, 6);
    endtask

    // =========================================================================
    // One cycle: settle, check, take the edge, advance the model
    // =========================================================================
    task automatic step();
        #1;                    // settle combinational outputs, same cycle
        model_predict();
        check_outputs();
        @(posedge clk);
        model_update();
        cyc++;
        #1;
    endtask

    task automatic idle_inputs();
        dispatch_valid = '0;
        complete_valid = '0;
        flush_valid    = 1'b0;
        flush_rob_idx  = '0;
        for (int L = 0; L < 2; L++) begin
            dispatch_pc[L]            = '0;
            dispatch_dest_tag[L]      = '0;
            dispatch_is_branch[L]     = 1'b0;
            complete_rob_idx[L]       = '0;
            complete_value[L]         = '0;
            complete_exception[L]     = 1'b0;
            complete_mispredict[L]    = 1'b0;
            complete_actual_target[L] = '0;
        end
    endtask

    task automatic do_reset();
        idle_inputs();
        rst_n = 1'b0;
        repeat (3) @(posedge clk);
        #1;
        check_reset_state();
        rst_n = 1'b1;
        @(posedge clk);
        model_reset();
        cyc++;
        #1;
    endtask

    task automatic check_reset_state();
        if (rob_empty !== 1'b1) note_fail("rob_empty not 1 during reset");
        if (rob_full  !== 1'b0) note_fail("rob_full set during reset");
        if (commit_valid !== 2'b00) note_fail("commit_valid nonzero during reset");
        if (free_entries !== CNT_W'(DEPTH))
            note_fail($sformatf("free_entries=%0d during reset, expected %0d",
                                free_entries, DEPTH));
    endtask

    // =========================================================================
    // Stimulus helpers
    // =========================================================================
    int  live_idx [DEPTH];      // scratch list of live entry indices
    int  n_live;

    function automatic void collect_live();
        n_live = 0;
        for (int k = 0; k < DEPTH; k++) begin
            int i;
            i = (m_head + k) % DEPTH;
            if (m_alloc[i]) begin live_idx[n_live] = i; n_live++; end
        end
    endfunction

    // drive a dispatch group of the requested width with fresh payload
    task automatic drive_dispatch(input int width, input int branch_mask);
        dispatch_valid = 2'(width == 2 ? 2'b11 : (width == 1 ? 2'b01 : 2'b00));
        for (int L = 0; L < 2; L++) begin
            dispatch_pc[L]        = PC_W'($urandom());
            dispatch_dest_tag[L]  = TAG_W'($urandom());
            dispatch_is_branch[L] = ((branch_mask >> L) & 1) != 0;
        end
    endtask

    // pick up to 2 completable entries; prefer NOT the head so completion is
    // genuinely out of order
    task automatic drive_completions(input bit allow_exc);
        int cand [DEPTH];
        int nc, pick;
        complete_valid = '0;
        nc = 0;
        for (int k = 0; k < DEPTH; k++) begin
            int i;
            i = (m_head + k) % DEPTH;
            if (m_alloc[i] && pend_active[i] && !m_done[i] && pend_delay[i] == 0) begin
                cand[nc] = i; nc++;
            end
        end
        // shuffle-lite: rotate the candidate list by a random amount so the head
        // is not preferentially completed first
        if (nc > 1) begin
            int rot, tmp [DEPTH];
            rot = $urandom_range(0, nc-1);
            for (int i = 0; i < nc; i++) tmp[i] = cand[(i + rot) % nc];
            for (int i = 0; i < nc; i++) cand[i] = tmp[i];
        end
        for (int L = 0; L < 2; L++) begin
            if (L >= nc) break;
            pick = cand[L];
            complete_valid[L]         = 1'b1;
            complete_rob_idx[L]       = IDX_W'(pick);
            complete_value[L]         = VAL_W'($urandom());
            complete_exception[L]     = allow_exc && ($urandom_range(0, 31) == 0);
            complete_mispredict[L]    = m_branch[pick] && ($urandom_range(0, 3) == 0);
            complete_actual_target[L] = PC_W'($urandom());
            pend_active[pick]         = 1'b0;   // do not complete it twice
        end
    endtask

    task automatic tick_pend_delays();
        for (int i = 0; i < DEPTH; i++)
            if (m_alloc[i] && pend_active[i] && pend_delay[i] > 0)
                pend_delay[i]--;
    endtask

    // Drain to empty with a hard iteration cap. A broken candidate must produce
    // a FAIL with a diagnosis, never hang the run -- these loops are the only
    // place the testbench could otherwise spin forever.
    task automatic drain_idle(input string ctx);
        int guard;
        idle_inputs();
        guard = 0;
        while (!rob_empty && guard < 40*DEPTH) begin step(); guard++; end
        if (!rob_empty)
            note_fail($sformatf("%s: ROB failed to drain in %0d idle cycles (free=%0d, model_count=%0d, head=%0d)",
                                ctx, guard, free_entries, m_count, m_head));
    endtask

    task automatic drain_active(input string ctx);
        int guard;
        guard = 0;
        while (!rob_empty && guard < 80*DEPTH) begin
            idle_inputs();
            drive_completions(1'b0);
            step();
            tick_pend_delays();
            guard++;
        end
        idle_inputs();
        if (!rob_empty)
            note_fail($sformatf("%s: ROB failed to drain in %0d cycles with completions offered (free=%0d, model_count=%0d, head=%0d)",
                                ctx, guard, free_entries, m_count, m_head));
    endtask

    // =========================================================================
    // Directed corner-case suite
    // =========================================================================
    task automatic directed_suite();
        int idx_a, idx_b, saved, base;

        // ---- D1: fill the ROB completely, observe the stall, then drain ----
        phase = "D1-full-stall-recover";
        do_reset();
        // DEPTH/2 groups of 2 fills it exactly
        for (int g = 0; g < DEPTH/2; g++) begin
            drive_dispatch(2, 0);
            step();
        end
        idle_inputs();
        step();
        if (!rob_full) note_fail("ROB should be full after DEPTH/2 groups of 2");
        if (dispatch_ready) note_fail("dispatch_ready must be 0 when full");
        // present a group while full -- must be rejected, nothing allocated
        saved = m_count;
        drive_dispatch(2, 0);
        step();
        if (m_count != saved) note_fail("dispatch accepted while full");
        idle_inputs();
        // complete everything in reverse order, then drain. The base is
        // captured up front: m_head moves as soon as entries start committing.
        base = m_head;
        for (int k = DEPTH-1; k >= 0; k--) begin
            int i;
            i = (base + k) % DEPTH;
            complete_valid = 2'b01;
            complete_rob_idx[0]   = IDX_W'(i);
            complete_value[0]     = VAL_W'(32'hC0DE_0000 + k);
            complete_exception[0] = 1'b0;
            pend_active[i] = 1'b0;
            step();
            complete_valid = '0;
        end
        drain_idle("D1");

        // ---- D2: back-to-back maximum-width commit ----
        phase = "D2-max-width-commit";
        do_reset();
        for (int g = 0; g < DEPTH/2; g++) begin drive_dispatch(2, 0); step(); end
        idle_inputs();
        // complete all entries (2 per cycle, in order) so commit can run 2-wide.
        // Base captured up front: m_head advances as soon as the first pair
        // commits, so indexing off the live head would skip entries.
        base = m_head;
        for (int k = 0; k < DEPTH; k += 2) begin
            complete_valid = 2'b11;
            for (int L = 0; L < 2; L++) begin
                int i;
                i = (base + k + L) % DEPTH;
                complete_rob_idx[L]   = IDX_W'(i);
                complete_value[L]     = VAL_W'(32'hBEEF_0000 + k + L);
                complete_exception[L] = 1'b0;
                pend_active[i] = 1'b0;
            end
            step();
        end
        drain_idle("D2");

        // ---- D3: completion and flush racing on the SAME index, same cycle ----
        phase = "D3-complete-vs-flush-race";
        do_reset();
        for (int g = 0; g < 4; g++) begin drive_dispatch(2, 2'b10); step(); end
        idle_inputs();
        step();
        collect_live();
        idx_a = live_idx[1];             // the flush point (a branch)
        idx_b = live_idx[n_live-1];      // youngest -- will be squashed
        // complete the youngest at the same edge it gets squashed
        complete_valid        = 2'b01;
        complete_rob_idx[0]   = IDX_W'(idx_b);
        complete_value[0]     = VAL_W'(32'hDEAD_BEEF);
        complete_exception[0] = 1'b0;
        pend_active[idx_b]    = 1'b0;
        flush_valid           = 1'b1;
        flush_rob_idx         = IDX_W'(idx_a);
        step();
        idle_inputs();
        step();
        if (m_alloc[idx_b]) note_fail("squashed entry survived a same-cycle completion");
        drain_active("D3");

        // ---- D4: flush at the tail (nothing to squash) ----
        phase = "D4-flush-at-tail";
        do_reset();
        for (int g = 0; g < 3; g++) begin drive_dispatch(2, 0); step(); end
        idle_inputs();
        step();
        collect_live();
        saved = m_count;
        flush_valid   = 1'b1;
        flush_rob_idx = IDX_W'(live_idx[n_live-1]);   // youngest: squashes nothing
        step();
        idle_inputs();
        step();
        if (m_count != saved) note_fail("flush at tail changed occupancy");
        drain_active("D4");

        // ---- D5: flush at the head (squash everything but the head) ----
        phase = "D5-flush-at-head";
        do_reset();
        for (int g = 0; g < 4; g++) begin drive_dispatch(2, 0); step(); end
        idle_inputs();
        step();
        flush_valid   = 1'b1;
        flush_rob_idx = IDX_W'(m_head);
        step();
        idle_inputs();
        step();
        if (m_count != 1)
            note_fail($sformatf("flush at head left %0d entries, expected exactly 1", m_count));
        drain_active("D5");

        // ---- D6: flush at head while head+1 is complete (commit/squash overlap) ----
        phase = "D6-head-flush-suppresses-lane1";
        do_reset();
        for (int g = 0; g < 3; g++) begin drive_dispatch(2, 0); step(); end
        idle_inputs();
        step();
        collect_live();
        idx_a = live_idx[0];
        idx_b = live_idx[1];
        complete_valid = 2'b11;
        complete_rob_idx[0] = IDX_W'(idx_a); complete_value[0] = VAL_W'(32'h1111);
        complete_rob_idx[1] = IDX_W'(idx_b); complete_value[1] = VAL_W'(32'h2222);
        complete_exception  = 2'b00;
        pend_active[idx_a] = 1'b0; pend_active[idx_b] = 1'b0;
        step();
        idle_inputs();
        // now head and head+1 are both complete; flush AT the head
        flush_valid   = 1'b1;
        flush_rob_idx = IDX_W'(m_head);
        step();                              // check_outputs enforces cv1==0 here
        drain_active("D6");

        // ---- D7: exception stops the commit group ----
        phase = "D7-exception-stops-commit";
        do_reset();
        drive_dispatch(2, 0); step();
        idle_inputs();
        collect_live();
        idx_a = live_idx[0]; idx_b = live_idx[1];
        complete_valid = 2'b11;
        complete_rob_idx[0] = IDX_W'(idx_a); complete_value[0] = VAL_W'(32'hAAAA);
        complete_exception[0] = 1'b1;                    // head raises an exception
        complete_rob_idx[1] = IDX_W'(idx_b); complete_value[1] = VAL_W'(32'hBBBB);
        complete_exception[1] = 1'b0;
        pend_active[idx_a] = 1'b0; pend_active[idx_b] = 1'b0;
        step();
        idle_inputs();
        step();                              // lane 0 commits w/ exc, lane 1 must not
        step();
        drain_idle("D7");

        // ---- D8: index wrap -- push far more than DEPTH instructions through ----
        phase = "D8-index-wrap";
        do_reset();
        for (int g = 0; g < 3*DEPTH; g++) begin
            drive_dispatch(dispatch_ready ? 2 : 0, 0);
            drive_completions(1'b0);
            step();
            complete_valid = '0;
            tick_pend_delays();
        end
        drain_active("D8");
    endtask

    // =========================================================================
    // Randomized suite
    // =========================================================================
    task automatic random_suite();
        int w, fl_pick;
        phase = "R1-random";
        do_reset();
        for (int v = 0; v < RANDOM_CYCLES; v++) begin
            idle_inputs();

            // dispatch: 0/1/2 wide, occasionally branches
            w = $urandom_range(0, 3);
            if (w == 3) w = 2;
            drive_dispatch(w, $urandom_range(0, 3));

            // completions with randomized latency, deliberately out of order
            drive_completions(1'b1);

            // flush roughly every 40 cycles, at a random LIVE index
            if ($urandom_range(0, 39) == 0) begin
                collect_live();
                if (n_live > 0) begin
                    fl_pick = live_idx[$urandom_range(0, n_live-1)];
                    flush_valid   = 1'b1;
                    flush_rob_idx = IDX_W'(fl_pick);
                end
            end

            step();
            tick_pend_delays();

            // occasional full reset
            if ($urandom_range(0, 1999) == 0) do_reset();
        end
        drain_active("R1");
    endtask

    // =========================================================================
    // Main
    // =========================================================================
    int cov_missing;

    initial begin
        if (DEPTH < 8 || (DEPTH & (DEPTH-1)) != 0) begin
            $display("TEST_RESULT: FAIL: illegal DEPTH=%0d (must be a power of 2, >= 8)", DEPTH);
            $finish;
        end
        if (RANDOM_CYCLES < 10000) begin
            $display("TEST_RESULT: FAIL: RANDOM_CYCLES=%0d below the required 10000", RANDOM_CYCLES);
            $finish;
        end

        for (int i = 0; i <= 2; i++) begin cov_disp_group[i] = 0; cov_commit_w[i] = 0; end
        cov_disp_stall=0; cov_full=0; cov_one_free=0; cov_ooo_complete=0;
        cov_flush_none=0; cov_flush_part=0; cov_flush_all=0; cov_race_cf=0;
        cov_commit_exc=0; cov_mispredict=0; cov_wrap=0; cov_flush_commit=0;
        cov_head_flush_c1=0;

        total_commits = 0;
        model_reset();

        directed_suite();
        d_errors = errors;
        $display("// directed suite: %0d checks, %0d failing", checks, d_errors);

        random_suite();
        $display("// randomized suite: %0d cycles, %0d failing checks",
                 RANDOM_CYCLES, errors - d_errors);

        // ------------------------------------------------------------------
        phase = "final";

        $display("// ---- functional coverage ----");
        $display("//   dispatch groups accepted  w0=%0d w1=%0d w2=%0d",
                 cov_disp_group[0], cov_disp_group[1], cov_disp_group[2]);
        $display("//   dispatch stalled (valid & !ready) = %0d", cov_disp_stall);
        $display("//   rob_full cycles=%0d  exactly-one-free cycles=%0d",
                 cov_full, cov_one_free);
        $display("//   commit width  w0=%0d w1=%0d w2=%0d",
                 cov_commit_w[0], cov_commit_w[1], cov_commit_w[2]);
        $display("//   out-of-order completions = %0d", cov_ooo_complete);
        $display("//   flushes: squash-none=%0d partial=%0d all-but-head=%0d",
                 cov_flush_none, cov_flush_part, cov_flush_all);
        $display("//   completion squashed same cycle (race) = %0d", cov_race_cf);
        $display("//   flush+commit same cycle = %0d", cov_flush_commit);
        $display("//   head-flush suppressing commit lane 1 = %0d", cov_head_flush_c1);
        $display("//   exceptions completed=%0d  branch mispredicts=%0d",
                 cov_commit_exc, cov_mispredict);
        $display("//   tail wrap events = %0d", cov_wrap);
        $display("//   instructions committed (cumulative) = %0d", total_commits);

        // A run that never reached the hard states is not a real pass.
        cov_missing = 0;
        if (cov_disp_stall     == 0) begin cov_missing++; $display("// COVERAGE HOLE: never stalled dispatch"); end
        if (cov_full           == 0) begin cov_missing++; $display("// COVERAGE HOLE: ROB never full"); end
        if (cov_commit_w[2]    == 0) begin cov_missing++; $display("// COVERAGE HOLE: never committed 2-wide"); end
        if (cov_ooo_complete   == 0) begin cov_missing++; $display("// COVERAGE HOLE: no out-of-order completion"); end
        if (cov_flush_part     == 0) begin cov_missing++; $display("// COVERAGE HOLE: no partial flush"); end
        if (cov_flush_all      == 0) begin cov_missing++; $display("// COVERAGE HOLE: no flush-at-head"); end
        if (cov_race_cf        == 0) begin cov_missing++; $display("// COVERAGE HOLE: no completion/flush race"); end
        if (cov_wrap           == 0) begin cov_missing++; $display("// COVERAGE HOLE: index never wrapped"); end
        if (cov_commit_exc     == 0) begin cov_missing++; $display("// COVERAGE HOLE: no exception committed"); end
        if (cov_missing > 0)
            note_fail($sformatf("%0d coverage holes -- the run did not exercise the target hazards",
                                cov_missing));

        if (checks < 10000)
            note_fail($sformatf("insufficient coverage: only %0d checked cycles", checks));

        if (errors == 0) begin
            $display("// info: %0d checked cycles, %0d instructions committed", checks, total_commits);
            $display("TEST_RESULT: PASS");
        end else
            $display("TEST_RESULT: FAIL: %s (%0d failing checks of %0d; directed=%0d randomized=%0d)",
                     fail_reason, errors, checks, d_errors, errors - d_errors);
        $finish;
    end

    initial begin
        // ~40x the expected run length: bounded, but never trips on a good DUT
        #(40 * 10 * (RANDOM_CYCLES + 200*DEPTH));
        $display("// timeout state: phase=%s cyc=%0d checks=%0d model_count=%0d head=%0d tail=%0d rob_empty=%0b free=%0d committed=%0d",
                 phase, cyc, checks, m_count, m_head, m_tail, rob_empty,
                 free_entries, expect_commit_seq);
        if (errors > 0)
            $display("TEST_RESULT: FAIL: %s (%0d failing checks before a timeout in phase %s)",
                     fail_reason, errors, phase);
        else
            $display("TEST_RESULT: FAIL: timeout -- testbench did not complete (phase %s)", phase);
        $finish;
    end

endmodule
