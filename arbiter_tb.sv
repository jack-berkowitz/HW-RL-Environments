// =============================================================================
// arbiter_tb.sv -- self-checking testbench for `arbiter` (see arbiter_iface.sv)
// =============================================================================
// Reference model: the three policies expressed directly as the algorithms in
// the spec, using plain loops over integer arrays in TB functions (scan for
// first set bit / total-order comparison over a boolean matrix). No RTL, no
// clocked always blocks -- state advances only when the TB explicitly calls
// ref_update() after an edge it has already predicted a grant for.
//
// In addition to per-cycle equality against the reference, the TB checks
// policy-independent structural invariants on EVERY cycle (one-hot, subset of
// req, idx/onehot agreement, valid == |req) and quantitative fairness /
// starvation properties over long windows.
//
// Override parameters at compile time, e.g.
//   iverilog -g2012 -o sim -P arbiter_tb.NUM_REQ=8 -P arbiter_tb.VARIANT=2 \
//            arbiter_tb.sv arbiter.sv
//
// Final line is exactly one of:
//   TEST_RESULT: PASS
//   TEST_RESULT: FAIL: <reason>
// =============================================================================

`timescale 1ns/1ps

module arbiter_tb;

    // ---------------- configuration ----------------
    parameter int NUM_REQ             = 4;    // 2 / 4 / 8 / 16
    parameter int VARIANT             = 1;    // 0=fixed, 1=round-robin, 2=matrix
    parameter int RANDOM_VECTORS      = 4000; // >= 1000 required
    parameter int MAX_ERRORS_REPORTED = 20;

    localparam int IDX_W = $clog2(NUM_REQ);

    // ---------------- DUT connections ----------------
    logic               clk = 1'b0;
    logic               rst_n;
    logic [NUM_REQ-1:0] req;
    logic [NUM_REQ-1:0] grant;
    logic               grant_valid;
    logic [IDX_W-1:0]   grant_idx;

    arbiter #(
        .NUM_REQ (NUM_REQ),
        .VARIANT (VARIANT)
    ) dut (
        .clk (clk), .rst_n (rst_n),
        .req (req),
        .grant (grant), .grant_valid (grant_valid), .grant_idx (grant_idx)
    );

    always #5 clk = ~clk;

    // ---------------- bookkeeping ----------------
    int    errors = 0;
    int    checks = 0;
    string fail_reason = "";
    string phase = "init";

    task automatic note_fail(input string why);
        errors++;
        if (fail_reason == "") fail_reason = why;
        if (errors <= MAX_ERRORS_REPORTED)
            $display("[FAIL] t=%0t phase=%s : %s", $time, phase, why);
        else if (errors == MAX_ERRORS_REPORTED + 1)
            $display("[FAIL] ... further failures suppressed");
    endtask

    // =========================================================================
    // Reference model
    // =========================================================================
    int  ref_rr_ptr;                       // variant 1
    bit  ref_W [0:NUM_REQ-1][0:NUM_REQ-1]; // variant 2: ref_W[i][j] = i outranks j

    function automatic void ref_reset();
        ref_rr_ptr = 0;
        for (int i = 0; i < NUM_REQ; i++)
            for (int j = 0; j < NUM_REQ; j++)
                ref_W[i][j] = (i < j);
    endfunction

    // returns granted index, or -1 if req == 0
    function automatic int ref_grant_idx(input logic [NUM_REQ-1:0] r);
        int i;
        bit wins;
        if (r == '0) return -1;
        case (VARIANT)
            0: begin // fixed priority: lowest set index
                for (int k = 0; k < NUM_REQ; k++)
                    if (r[k]) return k;
            end
            1: begin // round robin: first set index scanning from rr_ptr
                for (int k = 0; k < NUM_REQ; k++) begin
                    i = (ref_rr_ptr + k) % NUM_REQ;
                    if (r[i]) return i;
                end
            end
            2: begin // matrix: the unique requester that outranks all others
                for (int k = 0; k < NUM_REQ; k++) begin
                    if (r[k]) begin
                        wins = 1'b1;
                        for (int j = 0; j < NUM_REQ; j++)
                            if (j != k && r[j] && !ref_W[k][j]) wins = 1'b0;
                        if (wins) return k;
                    end
                end
            end
        endcase
        return -1; // unreachable for a well-formed model
    endfunction

    function automatic void ref_update(input int g);
        if (g < 0) return;
        case (VARIANT)
            1: ref_rr_ptr = (g + 1) % NUM_REQ;
            2: begin
                for (int j = 0; j < NUM_REQ; j++) begin
                    if (j != g) begin
                        ref_W[g][j] = 1'b0;
                        ref_W[j][g] = 1'b1;
                    end
                end
            end
            default: ; // fixed priority is stateless
        endcase
    endfunction

    // =========================================================================
    // Checking
    // =========================================================================
    int  grant_count [0:NUM_REQ-1];   // histogram, reset per experiment
    int  cycle_num = 0;

    // Observation of the grant that was actually issued DURING the last cycle()
    // call, sampled before the clock edge. Directed tests must use these rather
    // than the live DUT outputs, which have already moved on to the next cycle
    // by the time cycle() returns.
    int                 obs_idx;    // -1 when no grant
    logic               obs_valid;
    logic [NUM_REQ-1:0] obs_grant;

    // structural invariants that hold for every variant, every cycle
    task automatic check_structural(input logic [NUM_REQ-1:0] r);
        int ones;
        checks++;
        ones = 0;
        for (int i = 0; i < NUM_REQ; i++) if (grant[i] === 1'b1) ones++;

        if (grant_valid !== (r != '0))
            note_fail($sformatf("grant_valid=%0b but req=0x%0h", grant_valid, r));

        if (r == '0) begin
            if (grant !== '0)
                note_fail($sformatf("grant=0x%0h with req==0 (must be 0)", grant));
        end else begin
            if (ones != 1)
                note_fail($sformatf("grant=0x%0h is not one-hot (req=0x%0h)", grant, r));
            if ((grant & ~r) != '0)
                note_fail($sformatf("grant=0x%0h not a subset of req=0x%0h", grant, r));
            if (ones == 1 && grant !== (NUM_REQ'(1) << grant_idx))
                note_fail($sformatf("grant_idx=%0d disagrees with grant=0x%0h",
                                    grant_idx, grant));
        end
    endtask

    // Apply `r`, check combinational response in the SAME cycle, then take the
    // edge and advance both models.
    task automatic cycle(input logic [NUM_REQ-1:0] r);
        int exp_idx;
        req = r;
        #1; // settle: still the same cycle, no edge taken yet
        exp_idx   = ref_grant_idx(r);
        obs_valid = grant_valid;
        obs_grant = grant;
        obs_idx   = grant_valid ? int'(grant_idx) : -1;
        check_structural(r);
        if (exp_idx < 0) begin
            // covered by check_structural
        end else begin
            if (grant !== (NUM_REQ'(1) << exp_idx))
                note_fail($sformatf("req=0x%0h: grant=0x%0h expected 0x%0h (idx %0d)",
                                    r, grant, NUM_REQ'(1) << exp_idx, exp_idx));
            else
                grant_count[exp_idx]++;
        end
        @(posedge clk);
        ref_update(exp_idx);
        cycle_num++;
        #1;
    endtask

    task automatic do_reset();
        req = '0;
        rst_n = 1'b0;
        repeat (3) @(posedge clk);
        #1;
        ref_reset();
        rst_n = 1'b1;
        @(posedge clk);
        #1;
        cycle_num++;
    endtask

    function automatic void clear_hist();
        for (int i = 0; i < NUM_REQ; i++) grant_count[i] = 0;
    endfunction

    // ---------------- stimulus ----------------
    logic [NUM_REQ-1:0] r;
    int    total, min_c, max_c;
    int    since;

    initial begin
        if (NUM_REQ != 2 && NUM_REQ != 4 && NUM_REQ != 8 && NUM_REQ != 16) begin
            $display("TEST_RESULT: FAIL: illegal NUM_REQ=%0d", NUM_REQ); $finish;
        end
        if (VARIANT < 0 || VARIANT > 2) begin
            $display("TEST_RESULT: FAIL: illegal VARIANT=%0d", VARIANT); $finish;
        end

        clear_hist();
        do_reset();

        // ------------------------------------------------------------------
        // C1: idle -- no requests must produce no grant, held for many cycles
        // ------------------------------------------------------------------
        phase = "C1-idle";
        repeat (8) cycle('0);

        // ------------------------------------------------------------------
        // C2: each requester alone (walking one-hot), twice around
        // ------------------------------------------------------------------
        phase = "C2-single";
        for (int rep = 0; rep < 2; rep++)
            for (int i = 0; i < NUM_REQ; i++) begin
                cycle(NUM_REQ'(1) << i);
                if (!obs_valid || obs_idx != i)
                    note_fail($sformatf("lone requester %0d not granted (got idx %0d valid=%0b)",
                                        i, obs_idx, obs_valid));
            end

        // ------------------------------------------------------------------
        // C3: simultaneous ALL requests -- exact grant ORDER is checked
        //     against the variant's defined sequence for 4*NUM_REQ cycles.
        // ------------------------------------------------------------------
        phase = "C3-simultaneous-all";
        do_reset();
        clear_hist();
        for (int k = 0; k < 4*NUM_REQ; k++) begin
            cycle('1);
            // spec consequence checks (independent of the reference model)
            if (VARIANT == 0 && obs_idx != 0)
                note_fail($sformatf("fixed priority granted %0d with all requesting", obs_idx));
            if (VARIANT == 1 && obs_idx != (k % NUM_REQ))
                note_fail($sformatf("round-robin: cycle %0d granted %0d expected %0d",
                                    k, obs_idx, k % NUM_REQ));
            if (VARIANT == 2 && obs_idx != (k % NUM_REQ))
                note_fail($sformatf("matrix: cycle %0d granted %0d expected %0d",
                                    k, obs_idx, k % NUM_REQ));
        end
        // fairness under full contention
        if (VARIANT != 0) begin
            min_c = 1<<30; max_c = 0;
            for (int i = 0; i < NUM_REQ; i++) begin
                if (grant_count[i] < min_c) min_c = grant_count[i];
                if (grant_count[i] > max_c) max_c = grant_count[i];
            end
            if (min_c != 4 || max_c != 4)
                note_fail($sformatf("full contention over 4*N cycles: grants not 4 each (min=%0d max=%0d)",
                                    min_c, max_c));
        end else begin
            // fixed priority MUST starve: nobody but index 0 may be granted
            for (int i = 1; i < NUM_REQ; i++)
                if (grant_count[i] != 0)
                    note_fail($sformatf("fixed priority granted index %0d under full contention", i));
        end

        // ------------------------------------------------------------------
        // C4: all pairwise simultaneous request patterns (2-hot), each held
        //     for 2*NUM_REQ cycles so rotation state is exercised
        // ------------------------------------------------------------------
        phase = "C4-pairs";
        for (int a = 0; a < NUM_REQ; a++)
            for (int b = a+1; b < NUM_REQ; b++) begin
                r = (NUM_REQ'(1) << a) | (NUM_REQ'(1) << b);
                clear_hist();
                for (int k = 0; k < 2*NUM_REQ; k++) cycle(r);
                if (VARIANT != 0) begin
                    if (grant_count[a] == 0 || grant_count[b] == 0)
                        note_fail($sformatf("pair (%0d,%0d): one side never granted", a, b));
                end
                // no third party may ever be granted
                for (int i = 0; i < NUM_REQ; i++)
                    if (i != a && i != b && grant_count[i] != 0)
                        note_fail($sformatf("pair (%0d,%0d): granted outsider %0d", a, b, i));
            end

        // ------------------------------------------------------------------
        // C5: STARVATION BOUND. Requester `victim` requests continuously while
        //     every other requester also hammers randomly. For round-robin and
        //     matrix the victim must be granted at least once in every window
        //     of NUM_REQ consecutive cycles. Checked for every choice of victim.
        // ------------------------------------------------------------------
        phase = "C5-starvation";
        if (VARIANT != 0) begin
            for (int victim = 0; victim < NUM_REQ; victim++) begin
                do_reset();
                since = 0;
                for (int k = 0; k < 40*NUM_REQ; k++) begin
                    r = NUM_REQ'($urandom()) | (NUM_REQ'(1) << victim);
                    cycle(r);
                    if (obs_valid && obs_idx == victim) since = 0;
                    else since++;
                    if (since > NUM_REQ)
                        note_fail($sformatf("starvation: victim %0d ungranted for %0d cycles (bound %0d)",
                                            victim, since, NUM_REQ));
                end
            end
        end else begin
            // fixed priority: index 0 held high must lock out every other index
            do_reset();
            clear_hist();
            for (int k = 0; k < 40*NUM_REQ; k++)
                cycle(NUM_REQ'($urandom()) | NUM_REQ'(1));
            for (int i = 1; i < NUM_REQ; i++)
                if (grant_count[i] != 0)
                    note_fail($sformatf("fixed priority: index %0d granted while index 0 requesting", i));
        end

        // ------------------------------------------------------------------
        // C6: requester drops out immediately after being granted -- the
        //     rotation pointer must still have advanced past it.
        // ------------------------------------------------------------------
        phase = "C6-dropout";
        do_reset();
        for (int k = 0; k < 6*NUM_REQ; k++) begin
            r = '1;
            // remove whoever was granted last cycle from the request vector
            if (k > 0 && obs_valid) r = ~obs_grant;
            cycle(r);
        end

        // ------------------------------------------------------------------
        // C7: request gaps -- state must HOLD across idle cycles (no update
        //     when grant_valid==0)
        // ------------------------------------------------------------------
        phase = "C7-gaps";
        do_reset();
        for (int k = 0; k < 4*NUM_REQ; k++) begin
            cycle('1);
            repeat ($urandom_range(1,4)) cycle('0);
        end

        // ------------------------------------------------------------------
        // C8: reset in the middle of contention restores the reset priority
        // ------------------------------------------------------------------
        phase = "C8-reset-midstream";
        repeat (3*NUM_REQ) cycle('1);
        do_reset();
        cycle('1);
        if (obs_idx != 0)
            note_fail($sformatf("after reset, all-requesting must grant index 0 (got %0d)", obs_idx));

        // ------------------------------------------------------------------
        // C9: single-cycle request pulses (grant must be combinational -- a
        //     one-cycle request must be served in that very cycle)
        // ------------------------------------------------------------------
        phase = "C9-pulse";
        for (int i = NUM_REQ-1; i >= 0; i--) begin
            cycle('0);
            cycle(NUM_REQ'(1) << i);
            if (!obs_valid || obs_idx != i)
                note_fail($sformatf("single-cycle pulse from %0d not served combinationally (got idx %0d valid=%0b)",
                                    i, obs_idx, obs_valid));
        end

        // ------------------------------------------------------------------
        // R1: constrained-random regression
        // ------------------------------------------------------------------
        phase = "R1-random";
        do_reset();
        clear_hist();
        for (int v = 0; v < RANDOM_VECTORS; v++) begin
            case ((v / 250) % 5)
                0: r = NUM_REQ'($urandom());                       // uniform
                1: r = '1;                                          // saturated
                2: r = NUM_REQ'($urandom()) & NUM_REQ'($urandom()); // sparse
                3: r = NUM_REQ'(1) << $urandom_range(0, NUM_REQ-1); // one-hot
                4: r = (v % 7 == 0) ? '0 : NUM_REQ'($urandom());    // with idle gaps
            endcase
            cycle(r);
            if ($urandom_range(0, 499) == 0) do_reset();
        end

        // aggregate fairness over the random run (RR/matrix only)
        if (VARIANT != 0) begin
            total = 0;
            for (int i = 0; i < NUM_REQ; i++) total += grant_count[i];
            if (total > 0) begin
                min_c = 1<<30; max_c = 0;
                for (int i = 0; i < NUM_REQ; i++) begin
                    if (grant_count[i] < min_c) min_c = grant_count[i];
                    if (grant_count[i] > max_c) max_c = grant_count[i];
                end
                // requests are statistically symmetric across indices, so grant
                // shares must be too; a 3x spread indicates a biased policy
                if (min_c * 3 < max_c)
                    note_fail($sformatf("random traffic: grant distribution too skewed (min=%0d max=%0d over %0d grants)",
                                        min_c, max_c, total));
            end
        end

        // ------------------------------------------------------------------
        phase = "final";
        if (checks < 1000)
            note_fail($sformatf("insufficient coverage: only %0d checks executed", checks));

        if (errors == 0)
            $display("TEST_RESULT: PASS");
        else
            $display("TEST_RESULT: FAIL: %s (%0d failing checks of %0d)",
                     fail_reason, errors, checks);
        $finish;
    end

    initial begin
        #50_000_000;
        $display("TEST_RESULT: FAIL: timeout -- testbench did not complete");
        $finish;
    end

endmodule
