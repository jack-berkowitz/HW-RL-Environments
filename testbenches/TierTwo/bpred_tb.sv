// =============================================================================
// bpred_tb.sv -- self-checking testbench for `bpred` (see bpred_iface.sv)
// =============================================================================
// TWO-TIER GRADING, deliberately kept apart:
//
//   TIER 1 (PASS/FAIL) -- protocol and speculative-state correctness.
//     P1  a BTB hit may only occur for a PC that was previously updated as a
//         control-transfer instruction. (Tag+set together cover the whole PC, so
//         a hit identifies the PC uniquely -- a "wrong PC" hit is impossible by
//         construction and a stale hit is therefore a real bug.)
//     P2  a hit's is_return must match the type last written for that PC
//     P3  a non-return hit must replay the target last written for that PC
//     P4  a return hit must return the modelled RAS top, ras[sp-1]
//     P5  predict_taken must equal the modelled 2-bit counter's MSB for a
//         conditional branch, and 1 for a call or return
//     P6  ghr_snapshot must equal {ras_sp, ghr} of the model, every cycle --
//         this is what continuously grades the speculative GHR shift, the RAS
//         push/pop, and the exact restore
//     P7  BTB allocate-on-first-encounter (directed, conflict-free PC set)
//
//   TIER 2 (INFORMATIONAL, never pass/fail) -- misprediction rate on three
//   synthetic traces. Reported so implementations can be compared, but a
//   protocol-correct predictor with poor accuracy PASSES, exactly as PPA is
//   scored separately from correctness in Milestone 1.
//
// WHAT IS NOT GRADED: BTB replacement choice and conflict misses. A finite BTB
// is allowed to miss whenever it likes; what it may never do is claim a hit and
// return the wrong data. So the model FOLLOWS the DUT's hit/miss decisions and
// grades the data, rather than predicting hits. P7 is what stops a DUT gaming
// that by never allocating -- and it is exactly mutant 3.
//
// The model tracks GHR/RAS/PHT exactly (all deterministic from the spec) and is
// therefore a genuine independent reference for everything except replacement.
//
// SystemVerilog subset: procedural, no classes -- runs under Verilator AND
// Icarus. See testbenches/TierTwo/NOTES.md.
//
// Run:
//   $ verilator --binary --timing -j 0 -Wno-fatal --x-assign unique --x-initial unique --top-module bpred_tb -Mdir obj_dir -o sim testbenches/TierTwo/bpred_tb.sv reference_solutions/TierTwo/bpred.sv
//   $ obj_dir/sim
//
// Final line is exactly one of:
//   TEST_RESULT: PASS
//   TEST_RESULT: FAIL: <reason>
// =============================================================================

`timescale 1ns/1ps

module bpred_tb;

    // ---------------- configuration ----------------
    parameter int PC_W                = 32;
    parameter int GHR_W               = 8;
    parameter int PHT_ENTRIES         = 256;
    parameter int BTB_SETS            = 16;
    parameter int BTB_WAYS            = 2;
    parameter int RAS_DEPTH           = 8;
    parameter int RANDOM_CYCLES       = 16000;  // >= 10000 required
    parameter int TRACE_BRANCHES      = 4000;   // per accuracy pattern
    parameter int MAX_ERRORS_REPORTED = 20;

    localparam int RAS_PTR_W = $clog2(RAS_DEPTH);
    localparam int SNAP_W    = GHR_W + RAS_PTR_W;
    localparam int SET_W     = $clog2(BTB_SETS);

    localparam logic [1:0] T_BRANCH = 2'd0;
    localparam logic [1:0] T_CALL   = 2'd1;
    localparam logic [1:0] T_RETURN = 2'd2;

    // ---------------- DUT connections ----------------
    logic              clk = 1'b0;
    logic              rst_n;

    logic [PC_W-1:0]   predict_pc;
    logic              predict_valid, predict_taken, predict_is_return;
    logic [PC_W-1:0]   predict_target;
    logic [SNAP_W-1:0] ghr_snapshot;

    logic              update_valid, update_taken;
    logic [PC_W-1:0]   update_pc, update_target;
    logic              update_is_branch, update_is_call, update_is_return;

    logic              restore_valid;
    logic [SNAP_W-1:0] restore_ghr_value;

    bpred #(.PC_W(PC_W), .GHR_W(GHR_W), .PHT_ENTRIES(PHT_ENTRIES),
            .BTB_SETS(BTB_SETS), .BTB_WAYS(BTB_WAYS), .RAS_DEPTH(RAS_DEPTH)) dut (
        .clk(clk), .rst_n(rst_n),
        .predict_pc(predict_pc), .predict_valid(predict_valid),
        .predict_taken(predict_taken), .predict_target(predict_target),
        .predict_is_return(predict_is_return), .ghr_snapshot(ghr_snapshot),
        .update_valid(update_valid), .update_pc(update_pc),
        .update_taken(update_taken), .update_target(update_target),
        .update_is_branch(update_is_branch), .update_is_call(update_is_call),
        .update_is_return(update_is_return),
        .restore_valid(restore_valid), .restore_ghr_value(restore_ghr_value)
    );

    always #5 clk = ~clk;

    // ---------------- bookkeeping ----------------
    int    errors = 0, checks = 0, d_errors = 0, cyc = 0;
    string fail_reason = "";
    string phase = "init";

    task automatic note_fail(input string s);
        errors++;
        if (fail_reason == "") fail_reason = s;
        if (errors <= MAX_ERRORS_REPORTED)
            $display("[FAIL] cyc=%0d t=%0t phase=%s : %s", cyc, $time, phase, s);
        else if (errors == MAX_ERRORS_REPORTED + 1)
            $display("[FAIL] ... further failures suppressed");
    endtask

    // ---------------- coverage ----------------
    int cov_hit, cov_miss, cov_ras_push, cov_ras_pop, cov_restore;
    int cov_restore_with_update, cov_nested_depth, cov_pht_sat_hi, cov_pht_sat_lo;
    int cov_type_change, cov_ghr_shift, cov_ret_pred;

    // =========================================================================
    // PC pool. The low PCs are spread one per BTB set so the directed tests are
    // conflict-free; the high PCs deliberately collide with them to exercise
    // replacement (whose choice is NOT graded).
    // =========================================================================
    localparam int NPC = 24;
    logic [PC_W-1:0] pcs [0:NPC-1];

    task automatic build_pcs();
        for (int i = 0; i < 16; i++) pcs[i] = PC_W'(32'h0000_1000 + i*4);        // 16 sets
        for (int i = 0; i < 8;  i++) pcs[16+i] = PC_W'(32'h0000_2000 + i*4);     // collide
    endtask

    // =========================================================================
    // Reference model (exact for GHR / RAS / PHT; follows the DUT for BTB hits)
    // =========================================================================
    logic [GHR_W-1:0]     m_ghr;
    logic [RAS_PTR_W-1:0] m_ras_sp;
    logic [PC_W-1:0]      m_ras [0:RAS_DEPTH-1];
    logic [1:0]           m_pht [0:PHT_ENTRIES-1];

    // last control-flow update seen per pooled PC (BTB *contents* reference)
    logic            k_seen [0:NPC-1];
    logic [PC_W-1:0] k_tgt  [0:NPC-1];
    logic [1:0]      k_type [0:NPC-1];

    task automatic model_reset();
        m_ghr    = '0;
        m_ras_sp = '0;
        for (int i = 0; i < PHT_ENTRIES; i++) m_pht[i] = 2'd1;
        for (int i = 0; i < RAS_DEPTH;   i++) m_ras[i] = '0;
    endtask

    task automatic knowledge_reset();
        for (int i = 0; i < NPC; i++) k_seen[i] = 1'b0;
    endtask

    function automatic int pc_slot(input logic [PC_W-1:0] pc);
        for (int i = 0; i < NPC; i++) if (pcs[i] == pc) return i;
        return -1;
    endfunction

    function automatic int pht_idx(input logic [PC_W-1:0] pc, input logic [GHR_W-1:0] h);
        return int'(pc[2 +: GHR_W] ^ h);
    endfunction

    // =========================================================================
    // Per-cycle grading of the combinational prediction
    // =========================================================================
    int  ps;                 // pool slot of predict_pc, -1 if not pooled
    logic [1:0] exp_type;
    logic exp_taken;
    logic [PC_W-1:0] exp_tgt;

    task automatic check_predict();
        checks++;

        // P6: the whole speculative state, every cycle
        if (ghr_snapshot !== {m_ras_sp, m_ghr})
            note_fail($sformatf("P6 ghr_snapshot=0x%0h expected 0x%0h (ras_sp=%0d ghr=0x%02h)",
                                ghr_snapshot, {m_ras_sp, m_ghr}, m_ras_sp, m_ghr));

        ps = pc_slot(predict_pc);
        if (predict_valid !== 1'b1) begin
            cov_miss++;
            return;                      // a miss is always permitted
        end
        cov_hit++;

        // P1
        if (ps < 0 || !k_seen[ps]) begin
            note_fail($sformatf("P1 BTB hit for pc=0x%08h which was never updated as a control instruction",
                                predict_pc));
            return;
        end
        exp_type = k_type[ps];

        // P2
        if (predict_is_return !== (exp_type == T_RETURN))
            note_fail($sformatf("P2 pc=0x%08h predict_is_return=%0b but its last update type was %0d",
                                predict_pc, predict_is_return, exp_type));

        // P3 / P4
        if (exp_type == T_RETURN) begin
            exp_tgt = m_ras[m_ras_sp - RAS_PTR_W'(1)];
            cov_ret_pred++;
            if (predict_target !== exp_tgt)
                note_fail($sformatf("P4 return at pc=0x%08h target=0x%08h expected RAS top 0x%08h (sp=%0d)",
                                    predict_pc, predict_target, exp_tgt, m_ras_sp));
        end else begin
            if (predict_target !== k_tgt[ps])
                note_fail($sformatf("P3 pc=0x%08h target=0x%08h expected last-updated 0x%08h",
                                    predict_pc, predict_target, k_tgt[ps]));
        end

        // P5
        exp_taken = (exp_type == T_BRANCH) ? m_pht[pht_idx(predict_pc, m_ghr)][1] : 1'b1;
        if (predict_taken !== exp_taken)
            note_fail($sformatf("P5 pc=0x%08h predict_taken=%0b expected %0b (type=%0d pht[%0d]=%0d ghr=0x%02h)",
                                predict_pc, predict_taken, exp_taken, exp_type,
                                pht_idx(predict_pc, m_ghr), m_pht[pht_idx(predict_pc, m_ghr)], m_ghr));
    endtask

    // =========================================================================
    // Model advance at the edge (mirrors the spec's priority exactly)
    // =========================================================================
    task automatic model_update();
        logic [GHR_W-1:0] eff_ghr;
        int us, pi;

        // ---- speculative state: restore beats the speculative update ----
        eff_ghr = restore_valid ? restore_ghr_value[GHR_W-1:0] : m_ghr;

        if (restore_valid) begin
            if (update_valid && !update_is_call && !update_is_return && update_is_branch)
                m_ghr = {restore_ghr_value[GHR_W-2:0], update_taken};
            else
                m_ghr = restore_ghr_value[GHR_W-1:0];
            m_ras_sp = restore_ghr_value[GHR_W +: RAS_PTR_W];
            cov_restore++;
            if (update_valid) cov_restore_with_update++;
        end else if (predict_valid && ps >= 0 && k_seen[ps]) begin
            case (k_type[ps])
                T_BRANCH: begin
                    m_ghr = {m_ghr[GHR_W-2:0], exp_taken};
                    cov_ghr_shift++;
                end
                T_CALL: begin
                    m_ras[m_ras_sp] = predict_pc + PC_W'(4);
                    m_ras_sp        = m_ras_sp + RAS_PTR_W'(1);
                    cov_ras_push++;
                end
                default: begin
                    m_ras_sp = m_ras_sp - RAS_PTR_W'(1);
                    cov_ras_pop++;
                end
            endcase
        end

        // ---- non-speculative training ----
        if (update_valid && (update_is_branch || update_is_call || update_is_return)) begin
            us = pc_slot(update_pc);
            if (us >= 0) begin
                logic [1:0] nt;
                if (update_is_call)        nt = T_CALL;
                else if (update_is_return) nt = T_RETURN;
                else                       nt = T_BRANCH;
                if (k_seen[us] && k_type[us] != nt) cov_type_change++;
                k_seen[us] = 1'b1;
                k_tgt [us] = update_target;
                k_type[us] = nt;

                if (nt == T_BRANCH) begin
                    pi = pht_idx(update_pc, eff_ghr);
                    if (update_taken) begin
                        if (m_pht[pi] == 2'd3) cov_pht_sat_hi++;
                        else m_pht[pi] = m_pht[pi] + 2'd1;
                    end else begin
                        if (m_pht[pi] == 2'd0) cov_pht_sat_lo++;
                        else m_pht[pi] = m_pht[pi] - 2'd1;
                    end
                end
            end
        end
    endtask

    // =========================================================================
    // Cycle
    // =========================================================================
    localparam logic [PC_W-1:0] NULL_PC = 32'h0000_0000;   // never updated -> always a miss

    task automatic idle_inputs();
        predict_pc        = NULL_PC;
        update_valid      = 1'b0;
        update_pc         = '0;
        update_taken      = 1'b0;
        update_target     = '0;
        update_is_branch  = 1'b0;
        update_is_call    = 1'b0;
        update_is_return  = 1'b0;
        restore_valid     = 1'b0;
        restore_ghr_value = '0;
    endtask

    task automatic step();
        #1;
        check_predict();
        @(posedge clk);
        model_update();
        cyc++;
        #1;
    endtask

    task automatic do_reset();
        idle_inputs();
        rst_n = 1'b0;
        repeat (3) @(posedge clk);
        #1;
        if (ghr_snapshot !== '0) note_fail("ghr_snapshot not zero during reset");
        rst_n = 1'b1;
        @(posedge clk);
        model_reset();
        knowledge_reset();
        cyc++;
        #1;
    endtask

    // convenience: one update-only cycle
    task automatic do_update(input logic [PC_W-1:0] pc, input logic tk,
                             input logic [PC_W-1:0] tgt, input logic [1:0] ty);
        idle_inputs();
        update_valid     = 1'b1;
        update_pc        = pc;
        update_taken     = tk;
        update_target    = tgt;
        update_is_branch = (ty == T_BRANCH);
        update_is_call   = (ty == T_CALL);
        update_is_return = (ty == T_RETURN);
        step();
    endtask

    // one predict-only cycle
    task automatic do_predict(input logic [PC_W-1:0] pc);
        idle_inputs();
        predict_pc = pc;
        step();
    endtask

    task automatic idle_steps(input int n);
        for (int k = 0; k < n; k++) begin idle_inputs(); step(); end
    endtask

    // =========================================================================
    // Directed suite (Tier 1)
    // =========================================================================
    logic [SNAP_W-1:0] snap0, snap1;
    logic [PC_W-1:0]   t0, t1, t2;

    task automatic directed_suite();

        // ---- D1: allocate on first encounter, then replay the target (P7) ----
        phase = "D1-btb-allocate-first-encounter";
        do_reset();
        do_predict(pcs[0]);
        if (predict_valid !== 1'b0)
            note_fail("D1: BTB hit for a PC that has never been updated");
        do_update(pcs[0], 1'b1, PC_W'(32'hDEAD_0000), T_BRANCH);
        idle_inputs(); predict_pc = pcs[0]; #1;
        if (predict_valid !== 1'b1)
            note_fail("P7 D1: no BTB hit on the predict after the very first update for that PC (allocate-on-first-encounter failed)");
        if (predict_target !== PC_W'(32'hDEAD_0000))
            note_fail($sformatf("D1: replayed target 0x%08h expected 0xDEAD0000", predict_target));
        step();

        // several distinct PCs, one per set, must all allocate and replay
        for (int i = 1; i < 8; i++)
            do_update(pcs[i], 1'b1, PC_W'(32'hBEEF_0000 + i), T_BRANCH);
        for (int i = 1; i < 8; i++) begin
            idle_inputs(); predict_pc = pcs[i]; #1;
            if (predict_valid !== 1'b1)
                note_fail($sformatf("P7 D1: pc=0x%08h missed after being updated", pcs[i]));
            if (predict_target !== PC_W'(32'hBEEF_0000 + i))
                note_fail($sformatf("D1: pc=0x%08h target=0x%08h expected 0x%08h",
                                    pcs[i], predict_target, 32'hBEEF_0000 + i));
            step();
        end

        // ---- D2: RAS push/pop over a nested call chain ----
        phase = "D2-ras-nested";
        do_reset();
        do_update(pcs[1], 1'b1, PC_W'(32'h4000_0000), T_CALL);
        do_update(pcs[2], 1'b1, PC_W'(32'h4000_0100), T_CALL);
        do_update(pcs[3], 1'b1, PC_W'(32'h4000_0200), T_CALL);
        do_update(pcs[4], 1'b1, PC_W'(0),             T_RETURN);
        // three nested calls
        do_predict(pcs[1]);
        do_predict(pcs[2]);
        do_predict(pcs[3]);
        cov_nested_depth = 3;
        // three returns must unwind in LIFO order
        for (int i = 0; i < 3; i++) begin
            idle_inputs(); predict_pc = pcs[4]; #1;
            if (predict_is_return !== 1'b1) note_fail("D2: return PC did not predict as a return");
            step();                        // P4 inside check_predict grades the target
        end

        // ---- D3: speculative GHR shift, then exact restore ----
        phase = "D3-ghr-shift-and-restore";
        do_reset();
        do_update(pcs[5], 1'b1, PC_W'(32'h5000_0000), T_BRANCH);
        // train it strongly taken so predict_taken is stable
        for (int i = 0; i < 4; i++) do_update(pcs[5], 1'b1, PC_W'(32'h5000_0000), T_BRANCH);
        // Shift real history in FIRST. Checkpointing a zero GHR would make the
        // restore check vacuous -- a restore bug that shifts or masks the value
        // maps 0 to 0 and would sail through.
        for (int i = 0; i < 3; i++) do_predict(pcs[5]);
        idle_inputs(); predict_pc = pcs[5]; #1;
        snap0 = ghr_snapshot;                       // checkpoint before this branch
        if (snap0 === SNAP_W'(0))
            note_fail("D3: checkpoint is zero, so the restore check would be vacuous -- test setup failed");
        step();
        // shift a few more predictions in
        for (int i = 0; i < 3; i++) do_predict(pcs[5]);
        idle_inputs(); #1;
        if (ghr_snapshot === snap0)
            note_fail("D3: GHR did not change across four predicted branches");
        step();
        // restore
        idle_inputs();
        restore_valid = 1'b1; restore_ghr_value = snap0;
        step();
        idle_inputs(); #1;
        if (ghr_snapshot !== snap0)
            note_fail($sformatf("D3: restore did not land on the checkpoint -- ghr_snapshot=0x%0h expected 0x%0h",
                                ghr_snapshot, snap0));
        step();

        // ---- D4: RAS pointer restored on squash, contents intact ----
        phase = "D4-ras-restore";
        do_reset();
        do_update(pcs[1], 1'b1, PC_W'(32'h4000_0000), T_CALL);
        do_update(pcs[4], 1'b1, PC_W'(0),             T_RETURN);
        do_predict(pcs[1]);                          // push #1
        idle_inputs(); predict_pc = NULL_PC; #1;
        snap0 = ghr_snapshot;                        // checkpoint with one entry
        step();
        do_predict(pcs[1]);                          // push #2 (speculative)
        do_predict(pcs[1]);                          // push #3 (speculative)
        idle_inputs();
        restore_valid = 1'b1; restore_ghr_value = snap0;   // squash the two pushes
        step();
        idle_inputs(); #1;
        if (ghr_snapshot !== snap0)
            note_fail($sformatf("D4: RAS pointer not restored (snapshot 0x%0h vs 0x%0h)",
                                ghr_snapshot, snap0));
        step();
        // the surviving entry must still be the one pushed before the checkpoint
        idle_inputs(); predict_pc = pcs[4]; #1;
        if (predict_target !== pcs[1] + PC_W'(4))
            note_fail($sformatf("D4: after restore the RAS top is 0x%08h, expected 0x%08h",
                                predict_target, pcs[1] + 4));
        step();

        // ---- D5: restore takes priority over a same-cycle speculative update --
        phase = "D5-restore-priority";
        do_reset();
        for (int i = 0; i < 4; i++) do_update(pcs[5], 1'b1, PC_W'(32'h5000_0000), T_BRANCH);
        for (int i = 0; i < 3; i++) do_predict(pcs[5]);   // non-zero history
        idle_inputs(); predict_pc = NULL_PC; #1;
        snap0 = ghr_snapshot;
        if (snap0 === SNAP_W'(0))
            note_fail("D5: checkpoint is zero, so the restore check would be vacuous -- test setup failed");
        step();
        // predict a branch AND restore in the same cycle: the restore must win
        idle_inputs();
        predict_pc        = pcs[5];
        restore_valid     = 1'b1;
        restore_ghr_value = snap0;
        step();
        idle_inputs(); #1;
        if (ghr_snapshot !== snap0)
            note_fail($sformatf("D5: state after a restore+predict cycle is 0x%0h, expected the checkpoint 0x%0h (restore must win over the speculative update, and must land exactly)",
                                ghr_snapshot, snap0));
        step();

        // ---- D6: PHT saturation, and training under a same-cycle restore ----
        phase = "D6-pht-train";
        do_reset();
        do_update(pcs[6], 1'b1, PC_W'(32'h6000_0000), T_BRANCH);
        for (int i = 0; i < 6; i++) do_update(pcs[6], 1'b1, PC_W'(32'h6000_0000), T_BRANCH);
        idle_inputs(); predict_pc = pcs[6]; #1;
        if (predict_taken !== 1'b1)
            note_fail("D6: strongly-taken training did not produce a taken prediction");
        step();
        for (int i = 0; i < 6; i++) do_update(pcs[6], 1'b0, PC_W'(32'h6000_0000), T_BRANCH);
        idle_inputs(); predict_pc = pcs[6]; #1;
        if (predict_taken !== 1'b0)
            note_fail("D6: strongly-not-taken training did not produce a not-taken prediction");
        step();
        // train while restoring in the same cycle (the recovery path)
        idle_inputs();
        update_valid = 1'b1; update_pc = pcs[6]; update_taken = 1'b1;
        update_target = PC_W'(32'h6000_0000); update_is_branch = 1'b1;
        restore_valid = 1'b1; restore_ghr_value = SNAP_W'(0);
        step();

        // ---- D7: a BTB entry's type can be rewritten by a later update ----
        phase = "D7-type-change";
        do_reset();
        do_update(pcs[7], 1'b1, PC_W'(32'h7000_0000), T_BRANCH);
        idle_inputs(); predict_pc = pcs[7]; #1;
        if (predict_is_return !== 1'b0) note_fail("D7: branch mis-typed as return");
        step();
        do_update(pcs[7], 1'b1, PC_W'(0), T_RETURN);
        idle_inputs(); predict_pc = pcs[7]; #1;
        if (predict_is_return !== 1'b1) note_fail("D7: type not updated to RETURN");
        step();

        // ---- D8: an unknown PC must not disturb any speculative state ----
        phase = "D8-miss-is-inert";
        do_reset();
        do_update(pcs[1], 1'b1, PC_W'(32'h4000_0000), T_CALL);
        do_predict(pcs[1]);
        idle_inputs(); predict_pc = NULL_PC; #1;
        snap0 = ghr_snapshot;
        step();
        for (int i = 0; i < 6; i++) do_predict(PC_W'(32'h9000_0000 + i*4));
        idle_inputs(); #1;
        if (ghr_snapshot !== snap0)
            note_fail($sformatf("D8: BTB misses changed the speculative state (0x%0h vs 0x%0h)",
                                ghr_snapshot, snap0));
        step();
    endtask

    // =========================================================================
    // Randomized suite (Tier 1)
    // =========================================================================
    localparam int SNAPHIST = 16;
    logic [SNAP_W-1:0] snap_hist [0:SNAPHIST-1];
    int                snap_n;

    task automatic random_suite();
        int p, r;
        phase = "R1-random";
        do_reset();
        snap_n = 0;
        for (int i = 0; i < SNAPHIST; i++) snap_hist[i] = '0;

        for (int v = 0; v < RANDOM_CYCLES; v++) begin
            idle_inputs();

            // predict from the pool most of the time, sometimes an unknown PC
            r = $urandom_range(0, 9);
            if (r < 7) predict_pc = pcs[$urandom_range(0, NPC-1)];
            else if (r < 9) predict_pc = NULL_PC;
            else predict_pc = PC_W'(32'h9000_0000 + $urandom_range(0, 64)*4);

            // update a pooled PC fairly often, with a random control type
            if ($urandom_range(0, 9) < 6) begin
                p = $urandom_range(0, NPC-1);
                update_valid  = 1'b1;
                update_pc     = pcs[p];
                update_taken  = 1'($urandom_range(0, 1));
                update_target = PC_W'(32'hC000_0000 + p*64);
                case ($urandom_range(0, 9))
                    0, 1:    begin update_is_call   = 1'b1; end
                    2, 3:    begin update_is_return = 1'b1; end
                    default: begin update_is_branch = 1'b1; end
                endcase
            end

            // restore to a previously observed snapshot every so often
            if (snap_n > 0 && $urandom_range(0, 39) == 0) begin
                restore_valid     = 1'b1;
                restore_ghr_value = snap_hist[$urandom_range(0, snap_n-1)];
            end

            // record snapshots to restore to later
            if ($urandom_range(0, 7) == 0) begin
                snap_hist[snap_n % SNAPHIST] = ghr_snapshot;
                if (snap_n < SNAPHIST) snap_n++;
            end

            step();
        end
    endtask

    // =========================================================================
    // Tier 2: accuracy on synthetic traces (INFORMATIONAL ONLY)
    // =========================================================================
    int trace_pred [0:2];    // predictions made
    int trace_miss [0:2];    // mispredictions

    // Run one branch through predict -> update in lockstep, recovering on a
    // misprediction exactly as a core would: restore the pre-branch checkpoint
    // with the true outcome shifted in.
    task automatic trace_branch(input int which, input logic [PC_W-1:0] pc,
                                input logic actual_taken);
        logic [SNAP_W-1:0] snap;
        logic              pred_taken;

        idle_inputs();
        predict_pc = pc;
        #1;
        snap       = ghr_snapshot;
        pred_taken = predict_valid ? predict_taken : 1'b0;
        trace_pred[which]++;
        if (pred_taken !== actual_taken) trace_miss[which]++;
        step();

        // train, and recover if we were wrong
        idle_inputs();
        update_valid     = 1'b1;
        update_pc        = pc;
        update_taken     = actual_taken;
        update_target    = pc + PC_W'(64);
        update_is_branch = 1'b1;
        // Hand the branch's checkpoint back on EVERY resolve. That is what lets
        // the predictor train at the same index it predicted with; supplying it
        // only on mispredicts trains at a shifted index and the predictor learns
        // a one-position-lagged correlation instead of the pattern.
        restore_valid     = 1'b1;
        restore_ghr_value = snap;
        step();
    endtask

    task automatic accuracy_suite();
        logic [PC_W-1:0] pc;
        logic tk;
        int pat;

        phase = "T2-accuracy";
        for (int i = 0; i < 3; i++) begin trace_pred[i] = 0; trace_miss[i] = 0; end

        // pattern 0: tight loop, 15 taken then 1 not-taken
        do_reset();
        pc = pcs[8];
        do_update(pc, 1'b1, pc + PC_W'(64), T_BRANCH);
        for (int i = 0; i < TRACE_BRANCHES; i++)
            trace_branch(0, pc, ((i % 16) != 15));

        // pattern 1: unpredictable ~50/50
        do_reset();
        pc = pcs[9];
        do_update(pc, 1'b1, pc + PC_W'(64), T_BRANCH);
        for (int i = 0; i < TRACE_BRANCHES; i++)
            trace_branch(1, pc, 1'($urandom_range(0, 1)));

        // pattern 2: period-6 correlated pattern -- learnable from history alone,
        // which is what a gshare GHR is for
        do_reset();
        pc = pcs[10];
        do_update(pc, 1'b1, pc + PC_W'(64), T_BRANCH);
        for (int i = 0; i < TRACE_BRANCHES; i++) begin
            pat = i % 6;
            tk  = (pat == 0 || pat == 1 || pat == 3);
            trace_branch(2, pc, tk);
        end
    endtask

    // =========================================================================
    // Report
    // =========================================================================
    task automatic report();
        int cov_missing;
        real r0, r1, r2;

        $display("// ---- functional coverage (tier 1) ----");
        $display("//   BTB hits=%0d misses=%0d", cov_hit, cov_miss);
        $display("//   RAS push=%0d pop=%0d  return predictions=%0d",
                 cov_ras_push, cov_ras_pop, cov_ret_pred);
        $display("//   GHR speculative shifts=%0d", cov_ghr_shift);
        $display("//   restores=%0d (with a same-cycle update=%0d)",
                 cov_restore, cov_restore_with_update);
        $display("//   PHT saturated hi=%0d lo=%0d  BTB type changes=%0d",
                 cov_pht_sat_hi, cov_pht_sat_lo, cov_type_change);

        r0 = (trace_pred[0] > 0) ? 100.0*real'(trace_miss[0])/real'(trace_pred[0]) : 0.0;
        r1 = (trace_pred[1] > 0) ? 100.0*real'(trace_miss[1])/real'(trace_pred[1]) : 0.0;
        r2 = (trace_pred[2] > 0) ? 100.0*real'(trace_miss[2])/real'(trace_pred[2]) : 0.0;
        $display("// ---- ACCURACY (tier 2, INFORMATIONAL -- never pass/fail) ----");
        $display("//   loop (15T/1N)      : %0d/%0d mispredicted = %.2f%%", trace_miss[0], trace_pred[0], r0);
        $display("//   unpredictable 50/50: %0d/%0d mispredicted = %.2f%%", trace_miss[1], trace_pred[1], r1);
        $display("//   correlated period-6: %0d/%0d mispredicted = %.2f%%", trace_miss[2], trace_pred[2], r2);
        $display("//   ACCURACY_SCORE loop=%.2f random=%.2f correlated=%.2f", r0, r1, r2);

        cov_missing = 0;
        if (cov_hit        == 0) begin cov_missing++; $display("// COVERAGE HOLE: BTB never hit"); end
        if (cov_miss       == 0) begin cov_missing++; $display("// COVERAGE HOLE: BTB never missed"); end
        if (cov_ras_push   == 0) begin cov_missing++; $display("// COVERAGE HOLE: RAS never pushed"); end
        if (cov_ras_pop    == 0) begin cov_missing++; $display("// COVERAGE HOLE: RAS never popped"); end
        if (cov_ret_pred   == 0) begin cov_missing++; $display("// COVERAGE HOLE: no return prediction graded"); end
        if (cov_ghr_shift  == 0) begin cov_missing++; $display("// COVERAGE HOLE: GHR never shifted"); end
        if (cov_restore    == 0) begin cov_missing++; $display("// COVERAGE HOLE: never restored"); end
        if (cov_restore_with_update == 0) begin cov_missing++; $display("// COVERAGE HOLE: no restore+update in the same cycle"); end
        if (cov_pht_sat_hi == 0) begin cov_missing++; $display("// COVERAGE HOLE: PHT never saturated high"); end
        if (cov_type_change== 0) begin cov_missing++; $display("// COVERAGE HOLE: a BTB entry's type was never rewritten"); end
        if (cov_missing > 0)
            note_fail($sformatf("%0d coverage holes -- the run did not exercise the target behaviours", cov_missing));

        if (checks < 10000)
            note_fail($sformatf("insufficient coverage: only %0d graded prediction cycles", checks));

        if (errors == 0) begin
            $display("// info: %0d graded prediction cycles", checks);
            $display("TEST_RESULT: PASS");
        end else
            $display("TEST_RESULT: FAIL: %s (%0d failing checks of %0d; directed=%0d randomized=%0d)",
                     fail_reason, errors, checks, d_errors, errors - d_errors);
    endtask

    // =========================================================================
    // Main
    // =========================================================================
    initial begin
        if (PHT_ENTRIES != (1 << GHR_W)) begin
            $display("TEST_RESULT: FAIL: PHT_ENTRIES=%0d must equal 2**GHR_W=%0d",
                     PHT_ENTRIES, 1 << GHR_W);
            $finish;
        end
        if (RANDOM_CYCLES < 10000) begin
            $display("TEST_RESULT: FAIL: RANDOM_CYCLES=%0d below the required 10000", RANDOM_CYCLES);
            $finish;
        end

        cov_hit=0; cov_miss=0; cov_ras_push=0; cov_ras_pop=0; cov_restore=0;
        cov_restore_with_update=0; cov_nested_depth=0; cov_pht_sat_hi=0;
        cov_pht_sat_lo=0; cov_type_change=0; cov_ghr_shift=0; cov_ret_pred=0;

        build_pcs();
        model_reset();
        knowledge_reset();

        directed_suite();
        d_errors = errors;
        $display("// directed suite: %0d checks, %0d failing", checks, d_errors);

        random_suite();
        $display("// randomized suite: %0d cycles, %0d failing checks",
                 RANDOM_CYCLES, errors - d_errors);

        accuracy_suite();
        report();
        $finish;
    end

    initial begin
        #(40 * 10 * (RANDOM_CYCLES + 12*TRACE_BRANCHES + 4000));
        $display("// timeout state: phase=%s cyc=%0d checks=%0d", phase, cyc, checks);
        $display("TEST_RESULT: FAIL: timeout -- testbench did not complete (phase %s)", phase);
        $finish;
    end

endmodule
