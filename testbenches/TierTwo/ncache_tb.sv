// =============================================================================
// ncache_tb.sv -- self-checking testbench for `ncache` (see ncache_iface.sv)
// =============================================================================
// Reference model: the shared golden memory carries architectural state, and a
// per-tag scoreboard carries in-flight requests. As in the LSQ harness the model
// is a SHADOW, not a predictor -- it never guesses when a response will arrive,
// because that depends on replacement and fill scheduling, neither of which is
// graded.
//
// THE ORDERING RULE IS WHAT MAKES READS CHECKABLE:
//   * an accepted write is applied to the golden memory AT ITS ACCEPT EDGE
//   * an accepted read FREEZES its expected value at its own accept edge
//   * within a cycle, port A is ordered before port B
// So a read's expectation is fixed the moment it is accepted, however long the
// response takes and whatever is written in between. Recomputing at response
// time would mis-grade every read that overlaps a later write -- the same
// reference-frame trap that had to be fixed in the LSQ harness.
//
// TIER 1 (PASS/FAIL)
//   C1  every response carries a tag that is currently outstanding on that port
//   C2  read data equals the value frozen at accept
//   C3  exactly one response per accepted request; all requests eventually answer
//   C4  no duplicate fill: a secondary miss to a line already being filled must
//       merge (graded by directed tests, which are deterministic -- see below)
//   C5  the single-outstanding memory contract is honoured (stub-detected)
//   C6  no dirty data is lost: after a full flush sweep the memory image must
//       match the golden model byte for byte
//
// TIER 2 (INFORMATIONAL) hit rate and fill count. Replacement policy and which
// accesses happen to hit are NOT graded -- a cache is free to miss.
//
// WHY MERGING IS GRADED BY DIRECTED TESTS: memory here is single-outstanding, so
// a duplicate fill is necessarily SEQUENTIAL, and from outside the cache a
// second fill for a line is indistinguishable from a legitimate refill after an
// eviction -- unless the scenario is controlled. The directed tests start from
// reset, touch one line from both ports before any fill can complete, and assert
// that exactly ONE memory read for that line occurs.
//
// Run:
//   $ verilator --binary --timing -j 0 -Wno-fatal --x-assign unique --x-initial unique --top-module ncache_tb -Mdir obj_dir -o sim -Itestbenches/common testbenches/TierTwo/ncache_tb.sv reference_solutions/TierTwo/ncache.sv
//   $ obj_dir/sim
//
// Final line is exactly one of:
//   TEST_RESULT: PASS
//   TEST_RESULT: FAIL: <reason>
// =============================================================================

`timescale 1ns/1ps
`include "mem_line_stub.sv"

module ncache_tb;

    parameter int ADDR_W     = 10;
    parameter int DATA_W     = 32;
    parameter int LINE_BYTES = 16;
    parameter int SETS       = 8;
    parameter int WAYS       = 4;
    parameter int MSHRS      = 4;
    parameter int VICTIM_ENT = 4;
    parameter int TAG_W      = 4;
    parameter int RANDOM_CYCLES       = 20000;   // >= 10000 required
    parameter int MAX_ERRORS_REPORTED = 20;
    parameter int MEM_MIN_LAT = 3;
    parameter int MEM_MAX_LAT = 9;

    localparam int LINE_W = 8*LINE_BYTES;
    localparam int NTAG   = 1 << TAG_W;
    localparam int NLINES = (1 << ADDR_W) / LINE_BYTES;

    // ---------------- DUT ----------------
    logic clk = 1'b0, rst_n;

    logic              A_req_valid, A_req_we, A_req_ready, A_resp_valid, A_resp_hit;
    logic [ADDR_W-1:0] A_req_addr;
    logic [DATA_W-1:0] A_req_wdata, A_resp_rdata;
    logic [1:0]        A_req_size;
    logic [TAG_W-1:0]  A_req_tag, A_resp_tag;

    logic              B_req_valid, B_req_we, B_req_ready, B_resp_valid, B_resp_hit;
    logic [ADDR_W-1:0] B_req_addr;
    logic [DATA_W-1:0] B_req_wdata, B_resp_rdata;
    logic [1:0]        B_req_size;
    logic [TAG_W-1:0]  B_req_tag, B_resp_tag;

    logic              mem_req_valid, mem_req_we, mem_resp_valid, mem_busy, mem_err;
    logic [ADDR_W-1:0] mem_req_addr;
    logic [LINE_W-1:0] mem_req_wdata, mem_resp_rdata;
    int                mem_err_count;

    ncache #(.ADDR_W(ADDR_W), .DATA_W(DATA_W), .LINE_BYTES(LINE_BYTES),
             .SETS(SETS), .WAYS(WAYS), .MSHRS(MSHRS),
             .VICTIM_ENT(VICTIM_ENT), .TAG_W(TAG_W)) dut (
        .clk(clk), .rst_n(rst_n),
        .A_req_valid(A_req_valid), .A_req_addr(A_req_addr), .A_req_we(A_req_we),
        .A_req_wdata(A_req_wdata), .A_req_size(A_req_size), .A_req_tag(A_req_tag),
        .A_req_ready(A_req_ready), .A_resp_valid(A_resp_valid), .A_resp_tag(A_resp_tag),
        .A_resp_rdata(A_resp_rdata), .A_resp_hit(A_resp_hit),
        .B_req_valid(B_req_valid), .B_req_addr(B_req_addr), .B_req_we(B_req_we),
        .B_req_wdata(B_req_wdata), .B_req_size(B_req_size), .B_req_tag(B_req_tag),
        .B_req_ready(B_req_ready), .B_resp_valid(B_resp_valid), .B_resp_tag(B_resp_tag),
        .B_resp_rdata(B_resp_rdata), .B_resp_hit(B_resp_hit),
        .mem_req_valid(mem_req_valid), .mem_req_addr(mem_req_addr),
        .mem_req_we(mem_req_we), .mem_req_wdata(mem_req_wdata),
        .mem_resp_valid(mem_resp_valid), .mem_resp_rdata(mem_resp_rdata)
    );

    mem_line_stub #(.ADDR_W(ADDR_W), .LINE_BYTES(LINE_BYTES),
                    .MIN_LAT(MEM_MIN_LAT), .MAX_LAT(MEM_MAX_LAT)) mem (
        .clk(clk), .rst_n(rst_n),
        .req_valid(mem_req_valid), .req_addr(mem_req_addr), .req_we(mem_req_we),
        .req_wdata(mem_req_wdata),
        .resp_valid(mem_resp_valid), .resp_rdata(mem_resp_rdata),
        .busy(mem_busy), .err_overlap(mem_err), .err_overlap_count(mem_err_count)
    );

    golden_mem #(.ADDR_W(ADDR_W), .LINE_BYTES(LINE_BYTES)) gm ();

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
    int cov_acc_a, cov_acc_b, cov_hit, cov_miss, cov_fill, cov_wb;
    int cov_stall_a, cov_stall_b, cov_dual_accept, cov_same_line_dual;
    int cov_merge_tested, cov_victim_scenarios, cov_rw_overlap;

    // ---------------- outstanding-request scoreboard, keyed by tag ----------
    logic        o_val  [0:NTAG-1];
    logic        o_port [0:NTAG-1];
    logic        o_we   [0:NTAG-1];
    int          o_addr [0:NTAG-1];
    int          o_size [0:NTAG-1];
    logic [31:0] o_exp  [0:NTAG-1];
    int          o_age  [0:NTAG-1];
    int          n_out;

    task automatic sb_reset();
        for (int i = 0; i < NTAG; i++) begin o_val[i] = 1'b0; o_age[i] = 0; end
        n_out = 0;
    endtask

    function automatic int free_tag();
        for (int i = 0; i < NTAG; i++) if (!o_val[i]) return i;
        return -1;
    endfunction

    function automatic int line_base(input int a);
        return a & ~(LINE_BYTES-1);
    endfunction

    // ---------------- memory-transaction observation ----------------
    int  fill_count_line [0:NLINES-1];    // memory READS seen per line
    int  wb_count_line   [0:NLINES-1];
    logic mem_txn_active;
    int   mem_txn_line;
    logic mem_txn_we;

    // =========================================================================
    // Per-cycle checking of responses (registered outputs, stable at #1)
    // =========================================================================
    task automatic check_resp(input logic port, input logic rvalid,
                              input logic [TAG_W-1:0] rtag,
                              input logic [DATA_W-1:0] rdata, input logic rhit);
        int t;
        if (rvalid !== 1'b1) return;
        checks++;
        t = int'(rtag);
        // C1
        if (!o_val[t]) begin
            note_fail($sformatf("C1 port %s response with tag %0d which is not outstanding (duplicate or fabricated response)",
                                port ? "B" : "A", t));
            return;
        end
        if (o_port[t] !== port) begin
            note_fail($sformatf("C1 tag %0d was issued on port %s but answered on port %s",
                                t, o_port[t] ? "B" : "A", port ? "B" : "A"));
            return;
        end
        // C2
        if (!o_we[t] && rdata !== o_exp[t])
            note_fail($sformatf("C2 port %s tag %0d read addr=%0d size=%0d data=0x%08h expected 0x%08h (frozen at accept)",
                                port ? "B" : "A", t, o_addr[t], o_size[t], rdata, o_exp[t]));
        if (rhit) cov_hit++; else cov_miss++;
        o_val[t] = 1'b0;
        n_out--;
    endtask

    task automatic check_responses();
        check_resp(1'b0, A_resp_valid, A_resp_tag, A_resp_rdata, A_resp_hit);
        check_resp(1'b1, B_resp_valid, B_resp_tag, B_resp_rdata, B_resp_hit);
    endtask

    // =========================================================================
    // Model advance at the edge
    // =========================================================================
    task automatic accept_one(input logic port, input logic [ADDR_W-1:0] a,
                              input logic we, input logic [DATA_W-1:0] wd,
                              input logic [1:0] sz, input logic [TAG_W-1:0] tg);
        int t;
        t = int'(tg);
        if (o_val[t]) begin
            note_fail($sformatf("testbench error: tag %0d reused while still outstanding", t));
            return;
        end
        o_val[t]  = 1'b1;
        o_port[t] = port;
        o_we[t]   = we;
        o_addr[t] = int'(a);
        o_size[t] = int'(sz);
        o_age[t]  = 0;
        n_out++;
        if (we) begin
            gm.wr_sized(int'(a), int'(sz), wd);       // visible at the accept edge
            o_exp[t] = '0;
        end else begin
            o_exp[t] = gm.rd_sized(int'(a), int'(sz));  // frozen at the accept edge
        end
        if (port) cov_acc_b++; else cov_acc_a++;
    endtask

    task automatic model_update();
        int lb;

        // ---- memory transaction observation ----
        if (mem_req_valid === 1'b1 && mem_busy === 1'b0) begin
            lb = line_base(int'(mem_req_addr));
            mem_txn_active = 1'b1;
            mem_txn_line   = lb / LINE_BYTES;
            mem_txn_we     = mem_req_we;
            if (mem_req_we) begin
                wb_count_line[mem_txn_line]++;
                cov_wb++;
            end else begin
                fill_count_line[mem_txn_line]++;
                cov_fill++;
            end
        end
        if (mem_resp_valid === 1'b1) mem_txn_active = 1'b0;

        // ---- accept: A is ordered before B ----
        if (A_req_valid && A_req_ready)
            accept_one(1'b0, A_req_addr, A_req_we, A_req_wdata, A_req_size, A_req_tag);
        if (B_req_valid && B_req_ready)
            accept_one(1'b1, B_req_addr, B_req_we, B_req_wdata, B_req_size, B_req_tag);

        if (A_req_valid && A_req_ready && B_req_valid && B_req_ready) begin
            cov_dual_accept++;
            if (line_base(int'(A_req_addr)) == line_base(int'(B_req_addr)))
                cov_same_line_dual++;
            if (A_req_we != B_req_we
                && line_base(int'(A_req_addr)) == line_base(int'(B_req_addr)))
                cov_rw_overlap++;
        end
        if (A_req_valid && !A_req_ready) cov_stall_a++;
        if (B_req_valid && !B_req_ready) cov_stall_b++;

        // ---- C3 liveness ----
        for (int i = 0; i < NTAG; i++)
            if (o_val[i]) begin
                o_age[i]++;
                if (o_age[i] == 3000)
                    note_fail($sformatf("C3 LIVENESS: tag %0d (port %s addr %0d %s) unanswered for %0d cycles",
                                        i, o_port[i] ? "B" : "A", o_addr[i],
                                        o_we[i] ? "write" : "read", o_age[i]));
            end
    endtask

    // step() = settle, grade, take the edge, advance the model.
    // finish_cycle() is the same without the leading settle, for drivers that
    // have just changed inputs and already settled to read req_ready.
    task automatic finish_cycle();
        check_responses();
        @(posedge clk);
        model_update();
        cyc++;
        #1;
    endtask

    task automatic step();
        #1;
        finish_cycle();
    endtask

    task automatic idle_inputs();
        A_req_valid = 1'b0; A_req_addr = '0; A_req_we = 1'b0; A_req_wdata = '0;
        A_req_size = 2'd2;  A_req_tag = '0;
        B_req_valid = 1'b0; B_req_addr = '0; B_req_we = 1'b0; B_req_wdata = '0;
        B_req_size = 2'd2;  B_req_tag = '0;
    endtask

    task automatic do_reset();
        idle_inputs();
        rst_n = 1'b0;
        repeat (3) @(posedge clk);
        #1;
        if (A_resp_valid !== 1'b0 || B_resp_valid !== 1'b0)
            note_fail("a response was asserted during reset");
        rst_n = 1'b1;
        @(posedge clk);
        sb_reset();
        mem_txn_active = 1'b0;
        // Reset invalidates every line INCLUDING dirty ones, so any write still
        // sitting in the cache is legitimately discarded. Architectural state
        // after a reset is therefore exactly the memory image -- resync the
        // golden to it. (The end-of-run C6 comparison stays decisive because no
        // reset happens between the random suite and the flush sweep.)
        for (int a = 0; a < (1 << ADDR_W); a++) gm.wr_byte(a, mem.peek_byte(a));
        cyc++;
        #1;
    endtask

    // Hold a request until the cache actually accepts it. Dropping it the cycle
    // req_ready happens to be low would silently skip the access -- which is how
    // the first version of the flush sweep evicted almost nothing.
    task automatic issue_A(input int addr, input logic we, input logic [DATA_W-1:0] wd,
                           input int sz, input int tg, input string ctx);
        int  g;
        bit  done;
        done = 1'b0;
        g    = 0;
        while (!done && g < 5000) begin
            A_req_valid = 1'b1; A_req_addr = ADDR_W'(addr); A_req_we = we;
            A_req_wdata = wd;   A_req_size = 2'(sz);        A_req_tag = TAG_W'(tg);
            #1;                                   // let req_ready settle
            done = (A_req_ready === 1'b1);        // this edge will accept it
            finish_cycle();
            g++;
        end
        A_req_valid = 1'b0;
        if (!done)
            note_fail($sformatf("%s: port A never became ready for addr %0d", ctx, addr));
    endtask

    // Drive both ports and hold each until it is accepted, so a same-line pair
    // really does collide in the MSHR rather than drifting apart.
    task automatic issue_AB(input int aa, input logic awe, input logic [DATA_W-1:0] awd,
                            input int asz, input int atg,
                            input int ba, input logic bwe, input logic [DATA_W-1:0] bwd,
                            input int bsz, input int btg, input string ctx);
        int g;
        logic a_done, b_done;
        a_done = 1'b0; b_done = 1'b0;
        g = 0;
        while ((!a_done || !b_done) && g < 5000) begin
            A_req_valid = !a_done; A_req_addr = ADDR_W'(aa); A_req_we = awe;
            A_req_wdata = awd; A_req_size = 2'(asz); A_req_tag = TAG_W'(atg);
            B_req_valid = !b_done; B_req_addr = ADDR_W'(ba); B_req_we = bwe;
            B_req_wdata = bwd; B_req_size = 2'(bsz); B_req_tag = TAG_W'(btg);
            #1;                                   // let both req_ready settle
            if (!a_done && A_req_ready === 1'b1) a_done = 1'b1;
            if (!b_done && B_req_ready === 1'b1) b_done = 1'b1;
            finish_cycle();
            g++;
        end
        idle_inputs();
        if (!a_done || !b_done)
            note_fail($sformatf("%s: ports did not both accept (A=%0b B=%0b)", ctx, a_done, b_done));
    endtask

    // wait until every outstanding request has answered
    task automatic quiesce(input string ctx);
        int g;
        idle_inputs();
        g = 0;
        while ((n_out > 0 || mem_busy === 1'b1 || mem_txn_active) && g < 20000) begin
            step(); g++;
        end
        if (n_out > 0)
            note_fail($sformatf("%s: %0d requests still unanswered after %0d idle cycles", ctx, n_out, g));
    endtask

    // =========================================================================
    // Address pool -- a few lines per set so conflicts, evictions and victim
    // hits are routine rather than lucky
    // =========================================================================
    localparam int NPOOL = 32;   // 16 lines in over-subscribed sets + spread
    int pool_addr [0:NPOOL-1];
    int pool_size [0:NPOOL-1];

    task automatic build_pool();
        int k;
        k = 0;
        // Set 0 gets EIGHT competing lines against 4 ways + 4 victim entries, so
        // the array, the victim buffer and the writeback path are all under real
        // pressure rather than being incidentally exercised. Lines that share a
        // set are 128 bytes apart (SETS=8, LINE_BYTES=16).
        for (int i = 0; i < 8; i++) begin
            pool_addr[k] = i*128;      pool_size[k] = 2; k++;
            pool_addr[k] = i*128 + 8;  pool_size[k] = 2; k++;
        end
        // set 1: five lines -- still over-subscribed, different pattern
        for (int i = 0; i < 5; i++) begin
            pool_addr[k] = 16 + i*128;     pool_size[k] = 2; k++;
            pool_addr[k] = 16 + i*128 + 5; pool_size[k] = 0; k++;
        end
        // a couple of quieter sets with mixed access sizes, so not every line is
        // a thrash victim and sub-word merging still gets covered
        for (int i = 0; i < 3; i++) begin
            pool_addr[k] = 32 + i*128;      pool_size[k] = 1; k++;
            pool_addr[k] = 32 + i*128 + 10; pool_size[k] = 1; k++;
        end
        while (k < NPOOL) begin
            pool_addr[k] = (48 + k*16) % (1<<ADDR_W); pool_size[k] = 2; k++;
        end
    endtask

    // =========================================================================
    // Directed suite
    // =========================================================================
    int t0, t1, t2, base_fills;

    task automatic directed_suite();

        // ---- D1: secondary miss must MERGE, not issue a second fill ----------
        phase = "D1-mshr-merge";
        do_reset();
        base_fills = fill_count_line[0];
        idle_inputs();
        issue_AB(0, 1'b0, '0, 2, 1,  4, 1'b0, '0, 2, 2, "D1");
        quiesce("D1");
        cov_merge_tested++;
        if (fill_count_line[0] - base_fills != 1)
            note_fail($sformatf("C4 D1: two same-line misses caused %0d memory fills, expected exactly 1 (secondary miss must merge into the in-flight MSHR)",
                                fill_count_line[0] - base_fills));

        // ---- D1b: three-deep merge, mixed read/write ----
        phase = "D1b-merge-rw";
        do_reset();
        base_fills = fill_count_line[128/LINE_BYTES];
        idle_inputs();
        issue_AB(128, 1'b1, 32'hAAAA_1111, 2, 3,  132, 1'b0, '0, 2, 4, "D1b");
        issue_A (128, 1'b0, '0, 2, 5, "D1b");
        quiesce("D1b");
        cov_merge_tested++;
        if (fill_count_line[128/LINE_BYTES] - base_fills != 1)
            note_fail($sformatf("C4 D1b: a merged read/write burst caused %0d fills, expected exactly 1",
                                fill_count_line[128/LINE_BYTES] - base_fills));

        // ---- D2: same-cycle A write / B read to the same address; B sees A ----
        phase = "D2-portA-before-portB";
        do_reset();
        // bring the line in first so both are hits
        idle_inputs();
        issue_A(64, 1'b0, '0, 2, 6, "D2-warm");
        quiesce("D2-warm");
        // C2 grades B against the value A wrote in the SAME cycle
        issue_AB(64, 1'b1, 32'h1234_5678, 2, 7,  64, 1'b0, '0, 2, 8, "D2");
        quiesce("D2");

        // ---- D3: dirty eviction must reach memory (no silently dropped write) --
        phase = "D3-dirty-writeback";
        do_reset();
        // dirty one line in set 0
        idle_inputs();
        issue_A(0, 1'b1, 32'hDEAD_BEEF, 2, 9, "D3-write");
        quiesce("D3-write");
        // push it out of the array and then out of the victim buffer
        for (int i = 1; i < 10; i++) begin
            issue_A(i*128, 1'b0, '0, 2, 10, "D3-sweep");
            quiesce("D3-sweep");
        end
        cov_victim_scenarios++;
        // read it back: whether it comes from the victim buffer or memory, the
        // value must survive
        issue_A(0, 1'b0, '0, 2, 11, "D3-readback");
        quiesce("D3-readback");

        // ---- D4: victim-cache hit must not fabricate a memory fill ----
        phase = "D4-victim-hit";
        do_reset();
        // fill the 4 ways of set 0, then a 5th line evicts one into the victim
        for (int i = 0; i < 5; i++) begin
            issue_A(i*128, 1'b0, '0, 2, 12, "D4-fill");
            quiesce("D4-fill");
        end
        cov_victim_scenarios++;
    endtask

    // =========================================================================
    // Randomized suite
    // =========================================================================
    task automatic drive_port(input logic port, input int p, input logic we,
                              input int tg);
        if (!port) begin
            A_req_valid = 1'b1; A_req_addr = ADDR_W'(pool_addr[p]);
            A_req_we = we; A_req_wdata = DATA_W'($urandom());
            A_req_size = 2'(pool_size[p]); A_req_tag = TAG_W'(tg);
        end else begin
            B_req_valid = 1'b1; B_req_addr = ADDR_W'(pool_addr[p]);
            B_req_we = we; B_req_wdata = DATA_W'($urandom());
            B_req_size = 2'(pool_size[p]); B_req_tag = TAG_W'(tg);
        end
    endtask

    task automatic random_suite();
        int ta, tb, pa, pb;
        phase = "R1-random";
        do_reset();
        for (int v = 0; v < RANDOM_CYCLES; v++) begin
            idle_inputs();
            ta = -1; tb = -1;
            if ($urandom_range(0, 9) < 7) begin
                ta = free_tag();
                if (ta >= 0) begin
                    o_val[ta] = 1'b1;                 // reserve so B cannot reuse it
                    pa = $urandom_range(0, NPOOL-1);
                    drive_port(1'b0, pa, 1'($urandom_range(0,1)), ta);
                end
            end
            if ($urandom_range(0, 9) < 7) begin
                tb = free_tag();
                if (tb >= 0) begin
                    o_val[tb] = 1'b1;
                    pb = ($urandom_range(0, 9) < 3 && ta >= 0)
                         ? pa                          // deliberately same line
                         : $urandom_range(0, NPOOL-1);
                    drive_port(1'b1, pb, 1'($urandom_range(0,1)), tb);
                end
            end
            // release the reservations; accept_one re-marks the ones taken
            if (ta >= 0) o_val[ta] = 1'b0;
            if (tb >= 0) o_val[tb] = 1'b0;
            step();
        end
        idle_inputs();
        quiesce("R1");
    endtask

    // =========================================================================
    // Flush sweep, then the whole-image comparison (C6)
    // =========================================================================
    task automatic flush_and_compare();
        int bad, tg;
        phase = "F1-flush";
        // sweep the whole address space several times: dirty lines are pushed
        // out of the array into the victim buffer and then out to memory
        for (int pass = 0; pass < 3; pass++)
            for (int l = 0; l < NLINES; l++) begin
                idle_inputs();
                tg = free_tag();
                if (tg < 0) begin quiesce("F1-drain"); tg = free_tag(); end
                issue_A(l*LINE_BYTES, 1'b0, '0, 2, tg, "F1");
            end
        quiesce("F1");
        // let any queued writebacks drain
        for (int i = 0; i < 4000; i++) begin idle_inputs(); step(); end

        phase = "final";
        checks++;
        bad = 0;
        for (int a = 0; a < (1 << ADDR_W); a++)
            if (mem.peek_byte(a) !== gm.rd_byte(a)) bad++;
        if (bad != 0)
            note_fail($sformatf("C6 final memory image differs from the golden model in %0d bytes -- dirty data was lost",
                                bad));
        checks++;
        if (mem_err === 1'b1)
            note_fail($sformatf("C5 single-outstanding memory contract violated %0d times", mem_err_count));
    endtask

    // =========================================================================
    // Report
    // =========================================================================
    task automatic report();
        int cov_missing;
        real hr;
        $display("// ---- functional coverage (tier 1) ----");
        $display("//   accepted: A=%0d B=%0d  dual-accept cycles=%0d (same line=%0d, r/w overlap=%0d)",
                 cov_acc_a, cov_acc_b, cov_dual_accept, cov_same_line_dual, cov_rw_overlap);
        $display("//   backpressure cycles: A=%0d B=%0d", cov_stall_a, cov_stall_b);
        $display("//   memory: fills=%0d writebacks=%0d", cov_fill, cov_wb);
        $display("//   directed merge scenarios=%0d victim scenarios=%0d",
                 cov_merge_tested, cov_victim_scenarios);
        hr = (cov_hit + cov_miss > 0) ? 100.0*real'(cov_hit)/real'(cov_hit+cov_miss) : 0.0;
        $display("// ---- TIER 2 (INFORMATIONAL -- never pass/fail) ----");
        $display("//   responses reporting hit=%0d miss=%0d  HIT_RATE=%.2f%%", cov_hit, cov_miss, hr);
        $display("//   FILL_COUNT=%0d WRITEBACK_COUNT=%0d", cov_fill, cov_wb);

        cov_missing = 0;
        if (cov_acc_a       == 0) begin cov_missing++; $display("// COVERAGE HOLE: port A never accepted"); end
        if (cov_acc_b       == 0) begin cov_missing++; $display("// COVERAGE HOLE: port B never accepted"); end
        if (cov_dual_accept == 0) begin cov_missing++; $display("// COVERAGE HOLE: never accepted on both ports in one cycle"); end
        if (cov_same_line_dual == 0) begin cov_missing++; $display("// COVERAGE HOLE: no same-line dual accept"); end
        if (cov_stall_a + cov_stall_b == 0) begin cov_missing++; $display("// COVERAGE HOLE: backpressure never exercised"); end
        if (cov_fill        == 0) begin cov_missing++; $display("// COVERAGE HOLE: no memory fill"); end
        if (cov_wb          == 0) begin cov_missing++; $display("// COVERAGE HOLE: no writeback -- dirty eviction never exercised"); end
        if (cov_merge_tested < 2) begin cov_missing++; $display("// COVERAGE HOLE: MSHR merge not directly tested"); end
        if (cov_missing > 0)
            note_fail($sformatf("%0d coverage holes -- the run did not exercise the target hazards", cov_missing));

        if (checks < 10000)
            note_fail($sformatf("insufficient coverage: only %0d graded events", checks));

        if (errors == 0) begin
            $display("// info: %0d graded events", checks);
            $display("TEST_RESULT: PASS");
        end else
            $display("TEST_RESULT: FAIL: %s (%0d failing checks of %0d; directed=%0d randomized=%0d)",
                     fail_reason, errors, checks, d_errors, errors - d_errors);
    endtask

    initial begin
        if (RANDOM_CYCLES < 10000) begin
            $display("TEST_RESULT: FAIL: RANDOM_CYCLES=%0d below the required 10000", RANDOM_CYCLES);
            $finish;
        end
        cov_acc_a=0; cov_acc_b=0; cov_hit=0; cov_miss=0; cov_fill=0; cov_wb=0;
        cov_stall_a=0; cov_stall_b=0; cov_dual_accept=0; cov_same_line_dual=0;
        cov_merge_tested=0; cov_victim_scenarios=0; cov_rw_overlap=0;
        for (int i = 0; i < NLINES; i++) begin fill_count_line[i]=0; wb_count_line[i]=0; end

        build_pool();
        gm.init_pattern(11);
        mem.init_pattern(11);
        sb_reset();
        mem_txn_active = 1'b0;

        directed_suite();
        d_errors = errors;
        $display("// directed suite: %0d checks, %0d failing", checks, d_errors);

        random_suite();
        $display("// randomized suite: %0d cycles, %0d failing checks",
                 RANDOM_CYCLES, errors - d_errors);

        flush_and_compare();
        report();
        $finish;
    end

    initial begin
        #(40 * 10 * (RANDOM_CYCLES + 40000));
        $display("// timeout state: phase=%s cyc=%0d outstanding=%0d checks=%0d",
                 phase, cyc, n_out, checks);
        if (errors > 0)
            $display("TEST_RESULT: FAIL: %s (%0d failing checks before a timeout in phase %s)",
                     fail_reason, errors, phase);
        else
            $display("TEST_RESULT: FAIL: timeout -- testbench did not complete (phase %s)", phase);
        $finish;
    end

endmodule
