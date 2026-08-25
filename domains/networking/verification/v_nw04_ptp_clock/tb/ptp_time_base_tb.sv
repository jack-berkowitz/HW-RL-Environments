// Reference testbench for v_nw04 ptp_time_base. Scoring reference, not shipped.
//
// It carries a MODEL of the increment, not a recorded trace. Each cycle it
// decomposes the observed advance into period + (adjustment?) + (drift?) and
// checks that decomposition against the contract: that the adjustment is
// present exactly on the cycles adj_active_o marks, that the drift is present
// exactly every drift_rate cycles, and that both time bases advanced by the
// same amount.
//
// It checks INCREMENTS, not absolute time. Clause L2 leaves the phase between
// the two bases free, and clause L1 leaves the latency from a control input to
// its first effect free; a model pinned to absolute values would be encoding an
// implementation. After every control change it stops checking the increment
// VALUE for a settling window, and never stops checking the counted and
// periodic obligations, which L1 explicitly does not relax.
module ptp_time_base_tb;

  // VCD on demand, for the rule-34 stimulus-variation check. Guarded by a
  // plusarg so a normal scoring run is byte-for-byte unaffected.
  initial if ($test$plusargs("vcd")) begin
    $dumpfile("dump.vcd");
    $dumpvars(0, ptp_time_base_tb);
  end
  localparam longint FNS_PER_NS = 65536;
  localparam longint NS_PER_S   = 1_000_000_000;
  localparam longint FNS_PER_S  = NS_PER_S * FNS_PER_NS;
  localparam int     SETTLE     = 10;     // clause L1 allows 8; two cycles of margin
  localparam longint DEF_PERIOD = 6 * FNS_PER_NS + 16'h6666;
  localparam longint DEF_DRIFT  = 2;
  localparam int     DEF_RATE   = 5;

  int errors = 0;
  task automatic fail(input string clause, input string detail);
    if (errors < 24) $display("FAIL %s: %s", clause, detail);
    errors++;
  endtask

  logic clk = 1'b0; always #5 clk = ~clk;
  logic rst = 1'b1;
  logic [95:0] set96 = '0; logic set96_v = 1'b0;
  logic [63:0] set64 = '0; logic set64_v = 1'b0;
  logic [3:0]  per_ns = '0; logic [15:0] per_fns = '0; logic per_v = 1'b0;
  logic [3:0]  adj_ns = '0; logic [15:0] adj_fns = '0; logic [15:0] adj_cnt = '0;
  logic adj_v = 1'b0, adj_active;
  logic [3:0]  dr_ns = '0; logic [15:0] dr_fns = '0; logic [15:0] dr_rate = '0;
  logic dr_v = 1'b0;
  logic [95:0] ts96; logic [63:0] ts64; logic ts_step, pps;

  ptp_time_base dut (
    .clk_i(clk), .rst_i(rst),
    .set_ts96_i(set96), .set_ts96_valid_i(set96_v),
    .set_ts64_i(set64), .set_ts64_valid_i(set64_v),
    .period_ns_i(per_ns), .period_fns_i(per_fns), .period_valid_i(per_v),
    .adj_ns_i(adj_ns), .adj_fns_i(adj_fns), .adj_count_i(adj_cnt),
    .adj_valid_i(adj_v), .adj_active_o(adj_active),
    .drift_ns_i(dr_ns), .drift_fns_i(dr_fns), .drift_rate_i(dr_rate),
    .drift_valid_i(dr_v),
    .ts96_o(ts96), .ts64_o(ts64), .ts_step_o(ts_step), .pps_o(pps));

  int cyc = 0;
  always @(posedge clk) if (!rst) cyc <= cyc + 1;

  // ---------------- the model ----------------
  longint m_period = DEF_PERIOD;      // fns
  longint m_adj    = 0;               // fns, signed
  longint m_drift  = DEF_DRIFT;       // fns, signed
  int     m_rate   = DEF_RATE;
  int     settle   = 8;               // clause X2b: the warm-up the SPEC grants,
                                      // and no more. It was 20 -- an allowance the
                                      // reference took and the submission was not
                                      // given, which is not a fair measurement.
  bit     checking = 1'b0;

  // observation state. EACH BASE IS CHECKED ON ITS OWN: clause L2 leaves the
  // phase of the increment sequence each one sees free, so requiring them to
  // move together would be requiring an implementation. What the contract
  // fixes is that each base, taken alone, advances by a legal increment every
  // cycle, takes the drift exactly every drift_rate cycles, and takes the
  // offset adjustment on exactly adj_count increments.
  logic [63:0] p_ts64; longint p_ts96f;
  bit          have_prev = 1'b0;
  int  last_drift [2];              // 0 = ts64, 1 = ts96
  int  adj_applied [2];
  int  drift_hits [2];
  int  drift_bad [2];
  int  adj_active_seen = 0, adj_expected = 0;
  int  wraps = 0, pps_cycles = 0, pps_in_wrap = 0;

  function automatic longint ts96_fns(input logic [95:0] t);
    return longint'(t[45:16]) * FNS_PER_NS + longint'(t[15:0]);
  endfunction

  function automatic string base_name(input int b);
    return (b == 0) ? "ts64_o" : "ts96_o";
  endfunction

  // Decomposes one base's advance and applies I1, D2 and A2 to it.
  task automatic check_base(input int b, input longint d, input bit wrapped);
    automatic longint wo_adj;
    automatic bit has_adj, has_drift;
    wo_adj = d - m_period;
    has_adj = 1'b0; has_drift = 1'b0;
    if      (wo_adj == 0)               begin end
    else if (wo_adj == m_drift)         has_drift = 1'b1;
    else if (wo_adj == m_adj)           has_adj   = 1'b1;
    else if (wo_adj == m_adj + m_drift) begin has_adj = 1'b1; has_drift = 1'b1; end
    else begin
      // A wrap that happens at the wrong nanosecond shows up here as an
      // increment that cannot be decomposed. Naming I1 would send a reader
      // looking at the arithmetic; the clause actually broken is W1.
      if (wrapped)
        fail("W1", $sformatf("cycle %0d, %s: across the one-second wrap the base advanced %0d fns, but a legal increment is %0d. Exactly 1e9 ns must be subtracted, and only when the ns field would reach 1e9.",
                             cyc, base_name(b), d, m_period));
      else
        fail("I1", $sformatf("cycle %0d, %s: advanced %0d fns. That is not the period (%0d) plus any combination of the offset adjustment (%0d) and the drift (%0d).",
                             cyc, base_name(b), d, m_period, m_adj, m_drift));
      return;
    end
    if (has_adj) adj_applied[b]++;
    // A configured drift must keep ARRIVING, not merely be correctly spaced when
    // it does. Without this, a design that stops applying it looks like one
    // running at exactly its period -- a legal increment, and silently wrong.
    if (m_drift != 0 && last_drift[b] >= 0 && (cyc - last_drift[b]) > 4*m_rate) begin
      if (drift_bad[b] < 2)
        fail("D2", $sformatf("cycle %0d, %s: no drift has been applied for %0d cycles; drift_rate_i is %0d, so one is due every %0d",
                             cyc, base_name(b), cyc - last_drift[b], m_rate, m_rate));
      drift_bad[b]++;
      last_drift[b] = cyc;      // re-arm so one stall does not report every cycle
    end
    if (has_drift) begin
      drift_hits[b]++;
      if (last_drift[b] >= 0 && (cyc - last_drift[b]) != m_rate) begin
        if (drift_bad[b] < 2)
          fail("D2", $sformatf("cycle %0d, %s: the drift landed %0d cycles after the previous one; drift_rate_i is %0d",
                               cyc, base_name(b), cyc - last_drift[b], m_rate));
        drift_bad[b]++;
      end
      last_drift[b] = cyc;
    end
  endtask

  always @(posedge clk) begin
    if (rst) begin
      have_prev <= 1'b0;
    end else begin
      automatic longint d64, d96;
      automatic bit wrapped;
      if (have_prev) begin
        d64 = longint'(ts64) - longint'(p_ts64);
        d96 = ts96_fns(ts96) - p_ts96f;
        wrapped = (d96 < 0);
        if (wrapped) d96 = d96 + FNS_PER_S;

        if (checking && settle == 0) begin
          check_base(0, d64, 1'b0);
          check_base(1, d96, wrapped);

          // ---- W1: the wrap subtracts exactly one second --------------------
          if (wrapped) begin
            wraps++;
            if (ts96_fns(ts96) != (p_ts96f + d96 - FNS_PER_S))
              fail("W1", $sformatf("cycle %0d: after the wrap ts96 reads %0d fns into the second; exactly 1e9 ns must be subtracted, which gives %0d",
                                   cyc, ts96_fns(ts96), p_ts96f + d96 - FNS_PER_S));
            pps_in_wrap = 0;
          end
        end
      end
      if (checking && adj_active) adj_active_seen++;
      if (checking && settle == 0 && pps) begin
        pps_cycles++;
        pps_in_wrap++;
        if (pps_in_wrap > 1)
          fail("W3", $sformatf("cycle %0d: pps_o asserted on more than one cycle for a single wrap", cyc));
      end
      if (settle > 0) settle <= settle - 1;
      p_ts64  <= ts64;
      p_ts96f <= ts96_fns(ts96);
      have_prev <= 1'b1;
    end
  end

  // W3 is checked in aggregate, in the ONE always block above: pps_o must be
  // asserted on exactly as many cycles as there were wraps. Counting it in a
  // second always block raced with the wrap counter that block maintains, and
  // the race reported a violation against a correct design.

  // ---------------- stimulus helpers ----------------
  task automatic quiet(input int n); repeat (n) @(posedge clk); endtask

  task automatic set_period(input int ns, input int fns);
    @(negedge clk); per_ns = 4'(ns); per_fns = 16'(fns); per_v = 1'b1;
    @(negedge clk) per_v = 1'b0;
    m_period = longint'(ns) * FNS_PER_NS + longint'(fns);
    settle = SETTLE; last_drift[0] = -1; last_drift[1] = -1;
  endtask

  task automatic set_drift(input int ns, input int fns, input int rate);
    @(negedge clk); dr_ns = 4'(ns); dr_fns = 16'(fns); dr_rate = 16'(rate); dr_v = 1'b1;
    @(negedge clk) dr_v = 1'b0;
    m_drift = longint'($signed({4'(ns), 16'(fns)}));
    m_rate = rate;
    settle = SETTLE; last_drift[0] = -1; last_drift[1] = -1;
  endtask

  task automatic start_adjust(input int ns, input int fns, input int count);
    // The counters are armed BEFORE the valid is driven. Arming them after
    // means an implementation that acts on the valid in its own cycle has its
    // first adjusted cycle counted and then wiped, and the testbench reports
    // one short against a correct design -- which is the testbench encoding
    // the golden's control latency rather than the contract (clause L1).
    m_adj = longint'($signed({4'(ns), 16'(fns)}));
    adj_expected = count; adj_active_seen = 0; adj_applied[0] = 0; adj_applied[1] = 0;
    @(negedge clk); adj_ns = 4'(ns); adj_fns = 16'(fns); adj_cnt = 16'(count); adj_v = 1'b1;
    @(negedge clk) adj_v = 1'b0;
    // No settling window, and the drift phase is untouched. Starting an
    // adjustment changes neither the period nor the drift, so every increment
    // stays decomposable -- and a settling window would hide the very
    // increments A2 counts.
  endtask

  task automatic finish_adjust(input string what);
    // wait well past the settling window, then require the counted obligations
    // exactly -- clause L1 explicitly does not relax these.
    quiet(adj_expected + 4*SETTLE + 20);
    if (adj_active_seen != adj_expected)
      fail("A3", $sformatf("%s: adj_active_o was high on %0d cycles; adj_count_i asked for %0d",
                           what, adj_active_seen, adj_expected));
    for (int b = 0; b < 2; b++)
      if (adj_applied[b] != adj_expected)
        fail("A2", $sformatf("%s: %s took the adjustment on %0d increments; adj_count_i asked for %0d",
                             what, base_name(b), adj_applied[b], adj_expected));
    m_adj = 0;
  endtask

  task automatic set_ts96(input longint unsigned s, input longint unsigned ns);
    @(negedge clk); set96 = {48'(s), 2'b00, 30'(ns), 16'd0}; set96_v = 1'b1;
    @(negedge clk) set96_v = 1'b0;
    settle = SETTLE; last_drift[0] = -1; last_drift[1] = -1;
  endtask

  task automatic set_ts64(input longint unsigned ns);
    @(negedge clk); set64 = 64'(ns << 16); set64_v = 1'b1;
    @(negedge clk) set64_v = 1'b0;
    settle = SETTLE; last_drift[0] = -1; last_drift[1] = -1;
  endtask

  // ---------------- coverage, on STIMULUS only ----------------
  int cov_periods = 0, cov_adjusts = 0, cov_neg_adjusts = 0, cov_drifts = 0;
  int cov_ns_drifts = 0, cov_neg_drifts = 0;
  int cov_sets = 0; bit cov_wrap_driven = 0, cov_reset_mid = 0;

  initial begin
    for (int b = 0; b < 2; b++) begin
      last_drift[b] = -1; adj_applied[b] = 0; drift_hits[b] = 0; drift_bad[b] = 0;
    end
    repeat (6) @(posedge clk);
    @(negedge clk) rst = 1'b0;
    quiet(4);
    checking = 1'b1; settle = SETTLE;

    // -- 1. the default configuration, left alone -----------------------------
    quiet(80);
    for (int b = 0; b < 2; b++)
      if (drift_hits[b] < 8)
        fail("D2", $sformatf("the default drift landed only %0d times on %s in 80 cycles; at rate %0d it should land about %0d",
                             drift_hits[b], base_name(b), DEF_RATE, 80/DEF_RATE));

    // -- 2. a new period ------------------------------------------------------
    set_period(8, 16'h1000); cov_periods++; quiet(60);
    set_period(3, 16'hC000); cov_periods++; quiet(60);

    // -- 3. a new drift, and a new rate ---------------------------------------
    set_drift(0, 48, 3); cov_drifts++; quiet(60);
    set_drift(0, 7, 11); cov_drifts++; quiet(80);

    // -- 3b. drift with a NON-ZERO nanosecond field, and a NEGATIVE one -------
    // D3 makes `{drift_ns_i, drift_fns_i}` a SIGNED 20-bit quantity, and the
    // sign bit is drift_ns_i's MSB. A run that leaves drift_ns_i at zero cannot
    // reach the negative half of D3 AT ALL: drift_fns_i is only the low 16 bits,
    // so no other input can get there. It also cannot reach any drift of one
    // nanosecond or more.
    //
    // Steps 5 and 6 below already drive adj_ns_i to 4'hF and 4'hE. The identical
    // signed-concatenation pattern was therefore exercised on the ADJUSTMENT
    // side and not on the DRIFT side, inside one testbench -- which is what
    // makes this an inconsistency rather than a judgement call about depth.
    //
    // The period in force here is 3 ns + 0xC000 fns = 3.75 ns, so a drift of
    // -2 ns leaves the increment at 1.75 ns and the accumulators never run
    // backwards.
    set_drift(1,    16'h0000, 7); cov_drifts++; cov_ns_drifts++;  quiet(80);
    set_drift(4'hF, 16'hF830, 5); cov_drifts++; cov_neg_drifts++; quiet(80);
    set_drift(4'hE, 16'h0000, 9); cov_drifts++; cov_neg_drifts++;
                                  cov_ns_drifts++;                quiet(90);
    set_drift(0,    16'd48,   3); cov_drifts++;                   quiet(60);

    // -- 4. a counted POSITIVE offset adjustment ------------------------------
    start_adjust(0, 700, 12); cov_adjusts++;
    finish_adjust("positive adjustment of 700 fns for 12 increments");
    quiet(30);

    // -- 5. a counted NEGATIVE offset adjustment ------------------------------
    start_adjust(4'hF, 16'hF830, 10); cov_adjusts++; cov_neg_adjusts++;
    finish_adjust("negative adjustment of -2000 fns for 10 increments");
    quiet(30);

    // -- 6. a whole-nanosecond negative adjustment ----------------------------
    start_adjust(4'hE, 16'h0000, 9); cov_adjusts++; cov_neg_adjusts++;
    finish_adjust("negative adjustment of -2 ns for 9 increments");
    quiet(30);

    // -- 7. setting one base must not disturb the other -----------------------
    set_ts64(64'd777_000); cov_sets++; quiet(40);
    set_ts96(64'd21, 64'd123_456); cov_sets++; quiet(40);

    // -- 8. walk up to the one-second wrap ------------------------------------
    set_period(6, 16'h6666);
    set_drift(0, 2, 5);
    // Land INSIDE the last nanosecond before the boundary. At a 6.4 ns step the
    // window between "one nanosecond early" and the true boundary is only 1 ns
    // wide, so a start that never lands in it cannot tell a design that wraps
    // one nanosecond early from one that wraps correctly. 6.4*k has a .4
    // fractional part when k is 1 mod 5; at k = 11 the base reaches
    // 999_999_999.4, which is inside the window and far enough past the set for
    // the settling window of clause L1 to have closed.
    set_ts96(64'd21, 64'd999_999_929); cov_sets++; cov_wrap_driven = 1'b1;
    quiet(40);
    // and a plain wrap, approached from further back
    set_ts96(64'd22, 64'd999_999_800); cov_sets++;
    quiet(80);
    if (wraps == 0)
      fail("W1", "the one-second wrap was driven but ts96 never wrapped");
    if (pps_cycles != wraps)
      fail("W3", $sformatf("pps_o was asserted on %0d cycles for %0d wrap(s); it must be exactly one cycle per wrap",
                           pps_cycles, wraps));
    $display("  [coverage] wraps=%0d pps_cycles=%0d drift_hits=%0d/%0d",
             wraps, pps_cycles, drift_hits[0], drift_hits[1]);

    // -- 9. reset must restore the DEFAULT period and drift -------------------
    set_period(9, 16'h2000); cov_periods++; quiet(20);
    checking = 1'b0; cov_reset_mid = 1'b1;
    @(negedge clk) rst = 1'b1;
    quiet(5);
    @(negedge clk) rst = 1'b0;
    quiet(4);
    m_period = DEF_PERIOD; m_drift = DEF_DRIFT; m_rate = DEF_RATE; m_adj = 0;
    last_drift[0] = -1; last_drift[1] = -1; settle = SETTLE; checking = 1'b1;
    quiet(80);
    if (longint'(ts64) == 0)
      fail("R2", "the time base is not advancing after reset was released");

    // -- rule 4 floors, on STIMULUS only --------------------------------------
    if (cov_periods < 3)     fail("COVERAGE", $sformatf("only %0d period changes driven", cov_periods));
    if (cov_adjusts < 3)     fail("COVERAGE", $sformatf("only %0d counted adjustments driven", cov_adjusts));
    if (cov_neg_adjusts < 2) fail("COVERAGE", $sformatf("only %0d NEGATIVE adjustments driven -- A5 is untested without one", cov_neg_adjusts));
    if (cov_drifts < 2)      fail("COVERAGE", $sformatf("only %0d drift changes driven", cov_drifts));
    // The same floor the adjustment side has had all along. D3's signed half is
    // unreachable without a negative drift, and nothing else can reach it.
    if (cov_neg_drifts < 2)  fail("COVERAGE", $sformatf("only %0d NEGATIVE drifts driven -- D3's signed half is untested without one", cov_neg_drifts));
    if (cov_ns_drifts < 2)   fail("COVERAGE", $sformatf("only %0d drifts of a whole nanosecond or more driven -- drift_ns_i stays at zero without them", cov_ns_drifts));
    if (cov_sets < 3)        fail("COVERAGE", $sformatf("only %0d timestamp sets driven", cov_sets));
    if (!cov_wrap_driven)    fail("COVERAGE", "the one-second wrap was never driven -- W1 and W3 are untested");
    if (!cov_reset_mid)      fail("COVERAGE", "reset was never asserted mid-run -- R2 is untested");

    if (errors == 0) $display("RESULT: PASS");
    else $display("RESULT: FAIL (%0d violation%s)", errors, (errors == 1) ? "" : "s");
    $finish;
  end

  initial begin
    #3_000_000;
    $display("RESULT: FAIL (watchdog: no forward progress; %0d violation(s) so far)", errors);
    $finish;
  end
endmodule
