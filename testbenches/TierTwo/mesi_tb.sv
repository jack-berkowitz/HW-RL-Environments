// =============================================================================
// mesi_tb.sv -- self-checking testbench for `mesi_top` (see mesi_iface.sv)
// =============================================================================
// TWO CHECKERS, both required, deliberately independent of each other:
//
//   I. STATE INVARIANT, evaluated EVERY CYCLE over debug_state, per line:
//        I1  a line is never M or E in both caches at once
//        I2  a line is never M or E in one cache while S in the other
//        I3  a line is never M in one cache while valid at all in the other
//        I4  a line never appears twice in one cache's set
//      This needs the tag, not just the state -- see the iface note.
//
//  II. DATA / ORDERING, from the golden memory:
//      Each core is blocking and single-outstanding, so at most two operations
//      overlap at any moment. A read is therefore legal iff it returns either
//        * the value as of the moment the read was ISSUED (i.e. the last write
//          that had already COMPLETED), or
//        * the value of a write on the OTHER core that overlapped it
//      Anything else -- a stale line, a lost flush, a value never written -- is
//      unreachable under any global order and fails. Values are unique per
//      write, so a returned value identifies exactly which write was observed.
//
//  III. no dirty data lost: after a flush sweep the memory image must match the
//      golden model byte for byte.
//
// TIER 2 (INFORMATIONAL): bus transaction counts by type and memory traffic.
// A protocol-correct implementation that generates MORE traffic than necessary
// still PASSES -- that is what the traffic score is for, and it is how the
// "BusRd downgrades to I instead of S" mutant is meant to be noticed.
//
// The address pool is tiny and shared on purpose (8 lines over 4 sets, two per
// set) so both cores collide constantly, ping-pong is the norm, and the
// associativity is still exercised.
//
// Run:
//   $ verilator --binary --timing -j 0 -Wno-fatal --x-assign unique --x-initial unique --top-module mesi_tb -Mdir obj_dir -o sim -Itestbenches/common testbenches/TierTwo/mesi_tb.sv reference_solutions/TierTwo/mesi_top.sv
//   $ obj_dir/sim
//
// Final line is exactly one of:
//   TEST_RESULT: PASS
//   TEST_RESULT: FAIL: <reason>
// =============================================================================

`timescale 1ns/1ps
`include "mem_line_stub.sv"

module mesi_tb;

    parameter int ADDR_W     = 10;
    parameter int DATA_W     = 32;
    parameter int LINE_BYTES = 16;
    parameter int SETS       = 4;
    parameter int WAYS       = 2;
    parameter int RANDOM_OPS = 12000;   // CPU operations, >> the 10000 floor
    parameter int MAX_ERRORS_REPORTED = 20;
    parameter int MEM_MIN_LAT = 2;
    parameter int MEM_MAX_LAT = 8;

    localparam int LINE_W = 8*LINE_BYTES;
    localparam int OFF_W  = $clog2(LINE_BYTES);
    localparam int SET_W  = $clog2(SETS);
    localparam int LTAG_W = ADDR_W - OFF_W - SET_W;
    localparam int ENT_W  = LTAG_W + 2;
    localparam int NL     = SETS*WAYS;
    localparam int NSTATE = 2*NL;

    localparam logic [1:0] ST_I = 2'd0, ST_S = 2'd1, ST_E = 2'd2, ST_M = 2'd3;

    // ---------------- DUT ----------------
    logic clk = 1'b0, rst_n;

    logic              c0_req_valid, c0_req_we, c0_resp_valid;
    logic [ADDR_W-1:0] c0_req_addr;
    logic [DATA_W-1:0] c0_req_wdata, c0_resp_rdata;
    logic              c1_req_valid, c1_req_we, c1_resp_valid;
    logic [ADDR_W-1:0] c1_req_addr;
    logic [DATA_W-1:0] c1_req_wdata, c1_resp_rdata;

    logic              bus_req_valid, bus_req_core_id, bus_grant;
    logic [1:0]        bus_req_type;
    logic [ADDR_W-1:0] bus_req_addr;
    logic              bus_snoop_hit, bus_snoop_hitm, bus_data_valid;
    logic [LINE_W-1:0] bus_data;

    logic              mem_req_valid, mem_req_we, mem_resp_valid, mem_busy, mem_err;
    logic [ADDR_W-1:0] mem_req_addr;
    logic [LINE_W-1:0] mem_req_wdata, mem_resp_rdata;
    int                mem_err_count;

    logic [NSTATE*ENT_W-1:0] debug_state;

    mesi_top #(.ADDR_W(ADDR_W), .DATA_W(DATA_W), .LINE_BYTES(LINE_BYTES),
               .SETS(SETS), .WAYS(WAYS)) dut (
        .clk(clk), .rst_n(rst_n),
        .c0_req_valid(c0_req_valid), .c0_req_addr(c0_req_addr), .c0_req_we(c0_req_we),
        .c0_req_wdata(c0_req_wdata), .c0_resp_valid(c0_resp_valid),
        .c0_resp_rdata(c0_resp_rdata),
        .c1_req_valid(c1_req_valid), .c1_req_addr(c1_req_addr), .c1_req_we(c1_req_we),
        .c1_req_wdata(c1_req_wdata), .c1_resp_valid(c1_resp_valid),
        .c1_resp_rdata(c1_resp_rdata),
        .bus_req_valid(bus_req_valid), .bus_req_type(bus_req_type),
        .bus_req_addr(bus_req_addr), .bus_req_core_id(bus_req_core_id),
        .bus_grant(bus_grant), .bus_snoop_hit(bus_snoop_hit),
        .bus_snoop_hitm(bus_snoop_hitm), .bus_data(bus_data),
        .bus_data_valid(bus_data_valid),
        .mem_req_valid(mem_req_valid), .mem_req_addr(mem_req_addr),
        .mem_req_we(mem_req_we), .mem_req_wdata(mem_req_wdata),
        .mem_resp_valid(mem_resp_valid), .mem_resp_rdata(mem_resp_rdata),
        .debug_state(debug_state)
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

    // ---------------- coverage / traffic ----------------
    int cov_ops[0:1], cov_rd[0:1], cov_wr[0:1];
    int cov_bus[0:2];              // BusRd / BusRdX / BusUpgr
    int cov_hitm, cov_hit_shared, cov_mem_rd, cov_mem_wr;
    int cov_both_outstanding, cov_same_line_conc, cov_conc_seen;
    int cov_m_observed, cov_e_observed, cov_s_shared_both;
    int cov_peer_M_to_S_on_busrd, cov_peer_M_to_I_on_busrd;

    // =========================================================================
    // Address pool: 8 lines over 4 sets (two per set), 32-bit words inside
    // =========================================================================
    localparam int NLINE_POOL = 8;
    localparam int NPOOL      = 16;
    int pool_addr [0:NPOOL-1];
    int line_addr [0:NLINE_POOL-1];

    task automatic build_pool();
        int k;
        k = 0;
        for (int i = 0; i < NLINE_POOL; i++) line_addr[i] = i*LINE_BYTES;
        for (int i = 0; i < NLINE_POOL; i++) begin
            pool_addr[k] = i*LINE_BYTES;     k++;
            pool_addr[k] = i*LINE_BYTES + 4; k++;
        end
    endtask

    // =========================================================================
    // I. state invariant, every cycle
    // =========================================================================
    function automatic logic [1:0] st_of(input int c, input int l);
        return debug_state[(c*NL + l)*ENT_W +: 2];
    endfunction
    function automatic logic [LTAG_W-1:0] tg_of(input int c, input int l);
        return debug_state[(c*NL + l)*ENT_W + 2 +: LTAG_W];
    endfunction

    // state of a given line address in a given core, ST_I if absent
    function automatic logic [1:0] state_of_addr(input int c, input int a);
        int s;
        s = (a >> OFF_W) & (SETS-1);
        for (int w = 0; w < WAYS; w++)
            if (st_of(c, s*WAYS+w) != ST_I
                && tg_of(c, s*WAYS+w) == LTAG_W'(a >> (OFF_W+SET_W)))
                return st_of(c, s*WAYS+w);
        return ST_I;
    endfunction

    task automatic check_invariant();
        logic [1:0] s0, s1;
        int dup;
        checks++;
        for (int i = 0; i < NLINE_POOL; i++) begin
            s0 = state_of_addr(0, line_addr[i]);
            s1 = state_of_addr(1, line_addr[i]);
            if (s0 == ST_M || s1 == ST_M) cov_m_observed++;
            if (s0 == ST_E || s1 == ST_E) cov_e_observed++;
            if (s0 == ST_S && s1 == ST_S) cov_s_shared_both++;

            // I1
            if ((s0 == ST_M || s0 == ST_E) && (s1 == ST_M || s1 == ST_E))
                note_fail($sformatf("I1 line 0x%0h is %0s in core0 AND %0s in core1 -- exclusive ownership violated",
                                    line_addr[i], s0 == ST_M ? "M" : "E", s1 == ST_M ? "M" : "E"));
            // I2
            if (((s0 == ST_M || s0 == ST_E) && s1 == ST_S)
             || ((s1 == ST_M || s1 == ST_E) && s0 == ST_S))
                note_fail($sformatf("I2 line 0x%0h is exclusive in one core (c0=%0d c1=%0d) while SHARED in the other",
                                    line_addr[i], s0, s1));
            // I3
            if ((s0 == ST_M && s1 != ST_I) || (s1 == ST_M && s0 != ST_I))
                note_fail($sformatf("I3 line 0x%0h is M in one core while still valid in the other (c0=%0d c1=%0d)",
                                    line_addr[i], s0, s1));
        end
        // I4: a line must not be present twice within one cache's set
        for (int c = 0; c < 2; c++)
            for (int s = 0; s < SETS; s++) begin
                dup = 0;
                for (int w = 0; w < WAYS; w++)
                    for (int w2 = w+1; w2 < WAYS; w2++)
                        if (st_of(c, s*WAYS+w) != ST_I && st_of(c, s*WAYS+w2) != ST_I
                            && tg_of(c, s*WAYS+w) == tg_of(c, s*WAYS+w2)) dup++;
                if (dup != 0)
                    note_fail($sformatf("I4 core%0d set %0d holds the same tag in two ways", c, s));
            end
    endtask

    // =========================================================================
    // II. per-core driver + data checker
    // =========================================================================
    localparam int NALLOW = 12;

    int          d_state [0:1];      // 0 idle, 1 outstanding
    int          d_addr  [0:1];
    logic        d_we    [0:1];
    logic [31:0] d_wd    [0:1];
    logic [31:0] d_pre   [0:1];      // value as of issue
    logic [31:0] d_allow [0:1][0:NALLOW-1];
    int          d_nallow[0:1];
    int          d_gap   [0:1];
    int          d_age   [0:1];
    int          ops_done;
    logic [31:0] wr_ctr;             // unique value generator

    task automatic drv_reset();
        for (int c = 0; c < 2; c++) begin
            d_state[c] = 0; d_gap[c] = 0; d_nallow[c] = 0; d_age[c] = 0;
        end
        ops_done = 0;
    endtask

    task automatic start_op(input int c, input int p, input logic we);
        d_state[c]  = 1;
        d_addr[c]   = pool_addr[p];
        d_we[c]     = we;
        d_wd[c]     = we ? (32'hC0DE_0000 | wr_ctr) : '0;
        if (we) wr_ctr = wr_ctr + 1;
        d_pre[c]    = gm.rd_sized(d_addr[c], 2);
        d_nallow[c] = 0;
        d_age[c]    = 0;
        cov_ops[c]++;
        if (we) cov_wr[c]++; else cov_rd[c]++;
    endtask

    task automatic drive_cores();
        for (int c = 0; c < 2; c++) begin
            if (c == 0) begin
                c0_req_valid = (d_state[0] == 1);
                c0_req_addr  = ADDR_W'(d_addr[0]);
                c0_req_we    = d_we[0];
                c0_req_wdata = d_wd[0];
            end else begin
                c1_req_valid = (d_state[1] == 1);
                c1_req_addr  = ADDR_W'(d_addr[1]);
                c1_req_we    = d_we[1];
                c1_req_wdata = d_wd[1];
            end
        end
    endtask

    // While a read is outstanding, any overlapping write on the OTHER core is a
    // value it could legitimately observe.
    task automatic collect_concurrent();
        for (int c = 0; c < 2; c++) begin
            int o;
            o = 1 - c;
            if (d_state[c] == 1 && !d_we[c] && d_state[o] == 1 && d_we[o]
                && d_addr[o] == d_addr[c]) begin
                logic dup;
                dup = 1'b0;
                for (int i = 0; i < d_nallow[c]; i++)
                    if (d_allow[c][i] === d_wd[o]) dup = 1'b1;
                if (!dup && d_nallow[c] < NALLOW) begin
                    d_allow[c][d_nallow[c]] = d_wd[o];
                    d_nallow[c]++;
                    cov_conc_seen++;
                end
            end
        end
        if (d_state[0] == 1 && d_state[1] == 1) begin
            cov_both_outstanding++;
            if (d_addr[0] == d_addr[1]) cov_same_line_conc++;
        end
    endtask

    task automatic check_core_resp(input int c, input logic rvalid,
                                   input logic [DATA_W-1:0] rdata);
        logic ok;
        if (rvalid !== 1'b1) return;
        if (d_state[c] != 1) begin
            note_fail($sformatf("core%0d responded with no request outstanding", c));
            return;
        end
        checks++;
        if (!d_we[c]) begin
            ok = (rdata === d_pre[c]);
            for (int i = 0; i < d_nallow[c]; i++)
                if (rdata === d_allow[c][i]) ok = 1'b1;
            if (!ok) begin
                string extra;
                extra = "";
                for (int i = 0; i < d_nallow[c]; i++)
                    extra = {extra, $sformatf(" 0x%08h", d_allow[c][i])};
                note_fail($sformatf("COHERENCE core%0d read addr 0x%0h returned 0x%08h; legal values were 0x%08h (as of issue)%s%s",
                                    c, d_addr[c], rdata, d_pre[c],
                                    d_nallow[c] > 0 ? " or concurrent write(s)" : "", extra));
            end
        end else begin
            // a write becomes globally visible when it completes
            gm.wr_sized(d_addr[c], 2, d_wd[c]);
        end
        d_state[c] = 0;
        d_gap[c]   = $urandom_range(0, 3);
        ops_done++;
    endtask

    // =========================================================================
    // Bus / memory traffic observation
    // =========================================================================
    logic prev_bus_grant;
    logic prev_mem_busy;
    logic last_mem_we;
    logic [1:0] cur_bus_type;
    logic       cur_hitm;
    int         cur_peer;
    int         cur_line;
    logic [1:0] peer_state_at_grant;

    task automatic observe_traffic();
        if (bus_grant === 1'b1) begin
            cov_bus[int'(bus_req_type)]++;
            cur_bus_type = bus_req_type;
            cur_peer     = bus_req_core_id ? 0 : 1;
            cur_line     = int'(bus_req_addr);
            peer_state_at_grant = state_of_addr(cur_peer, cur_line);
        end
        if (bus_snoop_hitm === 1'b1) cov_hitm++;
        if (bus_snoop_hit  === 1'b1 && bus_snoop_hitm !== 1'b1) cov_hit_shared++;
        // informational: did a peer holding M end up in S (spec) or I (the
        // traffic-wasting variant) after a BusRd?
        if (bus_req_valid !== 1'b1 && prev_bus_grant !== 1'bx
            && cur_bus_type == 2'd0 && peer_state_at_grant == ST_M) begin
            logic [1:0] now;
            now = state_of_addr(cur_peer, cur_line);
            if (now == ST_S) cov_peer_M_to_S_on_busrd++;
            else if (now == ST_I) cov_peer_M_to_I_on_busrd++;
            peer_state_at_grant = ST_I;    // consume
        end
        // Count on the memory's BUSY rising edge, i.e. one count per ACCEPTED
        // transaction. Counting "req_valid && !busy" instead would depend on how
        // the DUT shapes req_valid (a one-cycle pulse vs. held high), which is
        // not something the spec pins down and not something worth grading.
        if (mem_req_valid === 1'b1) last_mem_we = mem_req_we;
        if (mem_busy === 1'b1 && prev_mem_busy === 1'b0) begin
            if (last_mem_we) cov_mem_wr++; else cov_mem_rd++;
        end
        prev_mem_busy = mem_busy;
    endtask

    // =========================================================================
    // Cycle
    // =========================================================================
    task automatic step();
        #1;
        check_invariant();
        // Collect BEFORE grading: a write outstanding on the other core right
        // now is a value this read may legitimately observe, including on the
        // very cycle the read completes.
        collect_concurrent();
        check_core_resp(0, c0_resp_valid, c0_resp_rdata);
        check_core_resp(1, c1_resp_valid, c1_resp_rdata);
        observe_traffic();
        // A response seen this cycle means the request is done, so drop
        // req_valid NOW -- before the edge. Holding it through the response
        // cycle would let the cache latch the very same request a second time.
        drive_cores();
        @(posedge clk);
        cyc++;
        for (int c = 0; c < 2; c++)
            if (d_state[c] == 1) begin
                d_age[c]++;
                if (d_age[c] == 4000)
                    note_fail($sformatf("LIVENESS: core%0d request to 0x%0h (%s) unanswered for %0d cycles",
                                        c, d_addr[c], d_we[c] ? "write" : "read", d_age[c]));
            end
        #1;
    endtask

    task automatic idle_inputs();
        c0_req_valid = 1'b0; c0_req_addr = '0; c0_req_we = 1'b0; c0_req_wdata = '0;
        c1_req_valid = 1'b0; c1_req_addr = '0; c1_req_we = 1'b0; c1_req_wdata = '0;
    endtask

    task automatic do_reset();
        idle_inputs();
        rst_n = 1'b0;
        repeat (3) @(posedge clk);
        #1;
        rst_n = 1'b1;
        @(posedge clk);
        drv_reset();
        // a reset drops every cached line including M ones, so architectural
        // state afterwards is the memory image
        for (int a = 0; a < (1 << ADDR_W); a++) gm.wr_byte(a, mem.peek_byte(a));
        cyc++;
        #1;
    endtask

    // run one operation on one core to completion
    task automatic op(input int c, input int addr, input logic we,
                      input logic [31:0] wd, input string ctx);
        int g;
        d_state[c] = 1; d_addr[c] = addr; d_we[c] = we;
        d_wd[c] = wd; d_pre[c] = gm.rd_sized(addr, 2);
        d_nallow[c] = 0; d_age[c] = 0;
        cov_ops[c]++; if (we) cov_wr[c]++; else cov_rd[c]++;
        g = 0;
        while (d_state[c] == 1 && g < 4000) begin
            drive_cores();
            step();
            g++;
        end
        idle_inputs();
        if (d_state[c] == 1)
            note_fail($sformatf("%s: core%0d op never completed", ctx, c));
    endtask

    task automatic idle_steps(input int n);
        for (int k = 0; k < n; k++) begin idle_inputs(); step(); end
    endtask

    // =========================================================================
    // Directed suite
    // =========================================================================
    task automatic directed_suite();
        logic [1:0] s0, s1;

        // ---- D1: core1 reads a line core0 holds in M -> flush + both in S ----
        phase = "D1-busrd-hitm";
        do_reset();
        op(0, 0, 1'b1, 32'hAAAA_0001, "D1");           // core0 writes -> M
        idle_steps(2);
        s0 = state_of_addr(0, 0);
        if (s0 !== ST_M) note_fail($sformatf("D1: core0 should hold the line in M after a write, got %0d", s0));
        op(1, 0, 1'b0, '0, "D1");                      // core1 reads -> BusRd
        idle_steps(2);
        s0 = state_of_addr(0, 0); s1 = state_of_addr(1, 0);
        if (!(s0 == ST_S && s1 == ST_S))
            note_fail($sformatf("D1: after BusRd on a line held M, expected both cores in S, got c0=%0d c1=%0d (the owner must downgrade to S, not I)",
                                s0, s1));

        // ---- D2: core1 writes a line core0 holds in S -> invalidate ----
        phase = "D2-busupgr-invalidate";
        op(1, 0, 1'b1, 32'hBBBB_0002, "D2");
        idle_steps(2);
        s0 = state_of_addr(0, 0); s1 = state_of_addr(1, 0);
        if (!(s0 == ST_I && s1 == ST_M))
            note_fail($sformatf("D2: after a write by core1 to a shared line, expected c0=I c1=M, got c0=%0d c1=%0d",
                                s0, s1));
        op(0, 0, 1'b0, '0, "D2");                      // core0 must see the new value

        // ---- D3: exclusive read then silent E->M ----
        phase = "D3-exclusive-then-silent-upgrade";
        do_reset();
        op(0, 16, 1'b0, '0, "D3");                     // nobody else has it -> E
        idle_steps(2);
        s0 = state_of_addr(0, 16);
        if (s0 !== ST_E)
            note_fail($sformatf("D3: a read miss with no sharer should install E, got %0d", s0));
        begin
            int b_before;
            b_before = cov_bus[0] + cov_bus[1] + cov_bus[2];
            op(0, 16, 1'b1, 32'hCCCC_0003, "D3");      // E -> M, silently
            idle_steps(2);
            if (cov_bus[0] + cov_bus[1] + cov_bus[2] != b_before)
                note_fail("D3: a write to a line held in E generated a bus transaction; E->M must be silent");
            if (state_of_addr(0, 16) !== ST_M)
                note_fail("D3: E->M upgrade did not reach M");
        end

        // ---- D4: re-read a line already held in E needs no bus traffic ----
        phase = "D4-no-bus-on-hit";
        do_reset();
        op(1, 32, 1'b0, '0, "D4");
        idle_steps(2);
        begin
            int b_before;
            b_before = cov_bus[0] + cov_bus[1] + cov_bus[2];
            op(1, 32, 1'b0, '0, "D4");
            idle_steps(2);
            if (cov_bus[0] + cov_bus[1] + cov_bus[2] != b_before)
                note_fail("D4: re-reading a line already held generated a bus transaction");
        end

        // ---- D5: both cores contend for the same line in the same cycle ----
        phase = "D5-simultaneous-contention";
        do_reset();
        for (int r = 0; r < 6; r++) begin
            int g;
            d_state[0] = 1; d_addr[0] = 48; d_we[0] = 1'b1;
            d_wd[0] = 32'hD000_0000 + r; d_pre[0] = gm.rd_sized(48, 2);
            d_nallow[0] = 0; d_age[0] = 0; cov_ops[0]++; cov_wr[0]++;
            d_state[1] = 1; d_addr[1] = 48; d_we[1] = 1'b0;
            d_wd[1] = '0; d_pre[1] = gm.rd_sized(48, 2);
            d_nallow[1] = 0; d_age[1] = 0; cov_ops[1]++; cov_rd[1]++;
            g = 0;
            while ((d_state[0] == 1 || d_state[1] == 1) && g < 4000) begin
                drive_cores(); step(); g++;
            end
            idle_inputs();
            if (d_state[0] == 1 || d_state[1] == 1)
                note_fail("D5: simultaneous contention did not complete -- arbiter starvation?");
        end
    endtask

    // =========================================================================
    // Randomized suite -- heavy ping-pong on a tiny shared pool
    // =========================================================================
    task automatic random_suite();
        int guard;
        phase = "R1-random";
        do_reset();
        guard = 0;
        while (ops_done < RANDOM_OPS && guard < 200*RANDOM_OPS) begin
            for (int c = 0; c < 2; c++)
                if (d_state[c] == 0) begin
                    if (d_gap[c] > 0) d_gap[c]--;
                    else start_op(c, $urandom_range(0, NPOOL-1),
                                  1'($urandom_range(0, 1)));
                end
            drive_cores();
            step();
            guard++;
        end
        // Drain: let anything still in flight finish, or its write would land
        // in the cache after the testbench stopped tracking it.
        guard = 0;
        while ((d_state[0] == 1 || d_state[1] == 1) && guard < 20000) begin
            drive_cores(); step(); guard++;
        end
        idle_inputs();
        if (d_state[0] == 1 || d_state[1] == 1)
            note_fail("R1: an operation never completed during drain");
        if (ops_done < RANDOM_OPS)
            note_fail($sformatf("R1: only %0d of %0d operations completed", ops_done, RANDOM_OPS));
    endtask

    // =========================================================================
    // Flush sweep, then whole-image comparison
    // =========================================================================
    task automatic flush_and_compare();
        int bad;
        phase = "F1-flush";
        // read every line in the pool from both cores several times: dirty lines
        // get flushed to memory by the snoop/eviction paths
        for (int pass = 0; pass < 3; pass++)
            for (int i = 0; i < NLINE_POOL; i++) begin
                op(0, line_addr[i], 1'b0, '0, "F1");
                op(1, line_addr[i], 1'b0, '0, "F1");
            end
        // evict everything by touching lines that map to the same sets
        for (int i = 0; i < 2*NLINE_POOL; i++) begin
            op(0, ((NLINE_POOL + i) * LINE_BYTES) % (1 << ADDR_W), 1'b0, '0, "F1");
            op(1, ((NLINE_POOL + i) * LINE_BYTES) % (1 << ADDR_W), 1'b0, '0, "F1");
        end
        idle_steps(200);

        phase = "final";
        checks++;
        bad = 0;
        for (int a = 0; a < NLINE_POOL*LINE_BYTES; a++)
            if (mem.peek_byte(a) !== gm.rd_byte(a)) bad++;
        if (bad != 0)
            note_fail($sformatf("final memory image differs from the golden model in %0d bytes -- dirty data was lost",
                                bad));
        checks++;
        if (mem_err === 1'b1)
            note_fail($sformatf("single-outstanding memory contract violated %0d times", mem_err_count));
    endtask

    // =========================================================================
    // Report
    // =========================================================================
    task automatic report();
        int cov_missing, bus_total;
        bus_total = cov_bus[0] + cov_bus[1] + cov_bus[2];
        $display("// ---- functional coverage (tier 1) ----");
        $display("//   ops: core0=%0d (rd %0d / wr %0d)  core1=%0d (rd %0d / wr %0d)",
                 cov_ops[0], cov_rd[0], cov_wr[0], cov_ops[1], cov_rd[1], cov_wr[1]);
        $display("//   both cores outstanding=%0d cycles (same line=%0d) concurrent-write windows=%0d",
                 cov_both_outstanding, cov_same_line_conc, cov_conc_seen);
        $display("//   snoop: HITM=%0d hit-shared=%0d", cov_hitm, cov_hit_shared);
        $display("//   states observed: M=%0d E=%0d both-S=%0d",
                 cov_m_observed, cov_e_observed, cov_s_shared_both);
        $display("// ---- TIER 2 (INFORMATIONAL -- never pass/fail) ----");
        $display("//   BUS_TOTAL=%0d  BusRd=%0d BusRdX=%0d BusUpgr=%0d",
                 bus_total, cov_bus[0], cov_bus[1], cov_bus[2]);
        $display("//   MEM_READS=%0d MEM_WRITES=%0d", cov_mem_rd, cov_mem_wr);
        $display("//   BusRd on an M line -> peer went to S %0d times, to I %0d times",
                 cov_peer_M_to_S_on_busrd, cov_peer_M_to_I_on_busrd);
        $display("//   TRAFFIC_SCORE bus_per_op=%.3f mem_per_op=%.3f",
                 real'(bus_total)/real'(cov_ops[0]+cov_ops[1]),
                 real'(cov_mem_rd+cov_mem_wr)/real'(cov_ops[0]+cov_ops[1]));

        cov_missing = 0;
        if (cov_hitm         == 0) begin cov_missing++; $display("// COVERAGE HOLE: no HITM snoop -- dirty cache-to-cache never exercised"); end
        if (cov_bus[0]       == 0) begin cov_missing++; $display("// COVERAGE HOLE: no BusRd"); end
        if (cov_bus[1]       == 0) begin cov_missing++; $display("// COVERAGE HOLE: no BusRdX"); end
        if (cov_bus[2]       == 0) begin cov_missing++; $display("// COVERAGE HOLE: no BusUpgr -- write-to-shared never exercised"); end
        if (cov_m_observed   == 0) begin cov_missing++; $display("// COVERAGE HOLE: M state never observed"); end
        if (cov_e_observed   == 0) begin cov_missing++; $display("// COVERAGE HOLE: E state never observed"); end
        if (cov_s_shared_both== 0) begin cov_missing++; $display("// COVERAGE HOLE: a line was never shared S/S by both cores"); end
        if (cov_same_line_conc == 0) begin cov_missing++; $display("// COVERAGE HOLE: the cores never contended for the same line concurrently"); end
        if (cov_mem_wr       == 0) begin cov_missing++; $display("// COVERAGE HOLE: no memory writeback"); end
        if (cov_missing > 0)
            note_fail($sformatf("%0d coverage holes -- the run did not exercise the target behaviours", cov_missing));

        if (checks < 10000)
            note_fail($sformatf("insufficient coverage: only %0d graded events", checks));

        if (errors == 0) begin
            $display("// info: %0d graded events, %0d CPU operations", checks, cov_ops[0]+cov_ops[1]);
            $display("TEST_RESULT: PASS");
        end else
            $display("TEST_RESULT: FAIL: %s (%0d failing checks of %0d; directed=%0d randomized=%0d)",
                     fail_reason, errors, checks, d_errors, errors - d_errors);
    endtask

    initial begin
        for (int i = 0; i < 2; i++) begin cov_ops[i]=0; cov_rd[i]=0; cov_wr[i]=0; end
        for (int i = 0; i < 3; i++) cov_bus[i]=0;
        cov_hitm=0; cov_hit_shared=0; cov_mem_rd=0; cov_mem_wr=0;
        cov_both_outstanding=0; cov_same_line_conc=0; cov_conc_seen=0;
        cov_m_observed=0; cov_e_observed=0; cov_s_shared_both=0;
        cov_peer_M_to_S_on_busrd=0; cov_peer_M_to_I_on_busrd=0;
        wr_ctr = 32'd1;
        peer_state_at_grant = ST_I;
        cur_bus_type = 2'd3; cur_peer = 0; cur_line = 0;
        prev_mem_busy = 1'b0; last_mem_we = 1'b0; prev_bus_grant = 1'b0;

        build_pool();
        gm.init_pattern(23);
        mem.init_pattern(23);
        drv_reset();

        directed_suite();
        d_errors = errors;
        $display("// directed suite: %0d checks, %0d failing", checks, d_errors);

        random_suite();
        $display("// randomized suite: %0d ops, %0d failing checks",
                 ops_done, errors - d_errors);

        flush_and_compare();
        report();
        $finish;
    end

    initial begin
        #(40 * 10 * (200*RANDOM_OPS));
        $display("// timeout state: phase=%s cyc=%0d ops=%0d checks=%0d",
                 phase, cyc, ops_done, checks);
        if (errors > 0)
            $display("TEST_RESULT: FAIL: %s (%0d failing checks before a timeout in phase %s)",
                     fail_reason, errors, phase);
        else
            $display("TEST_RESULT: FAIL: timeout -- testbench did not complete (phase %s)", phase);
        $finish;
    end

endmodule
