`timescale 1ns/1ps
//=============================================================================
// clk_ratio_div_tb -- self-checking testbench for the runtime-configurable
// integer clock divider.
//
// Everything is timed from clk_i. clk_o is never used as a clock and never
// merely sampled: its edges are timestamped and the PERIOD, the DUTY SPLIT
// and the GATING GAP are checked as time intervals (P4). All waits are
// bounded, so the bench terminates under any implementation.
//=============================================================================
module clk_ratio_div_tb;

  // ------------------------------------------------------------- clock -----
  logic clk;
  initial begin clk = 1'b0; forever #5 clk = ~clk; end   // 10 ns period

  // --------------------------------------------------------------- DUT -----
  logic       rst_ni;
  logic       en_i;
  logic       test_mode_en_i;
  logic [3:0] div_i;
  logic       div_valid_i;
  logic       div_ready_o;
  logic       clk_o;
  logic [3:0] cycl_count_o;

  clk_ratio_div dut (
    .clk_i          (clk),
    .rst_ni         (rst_ni),
    .en_i           (en_i),
    .test_mode_en_i (test_mode_en_i),
    .div_i          (div_i),
    .div_valid_i    (div_valid_i),
    .div_ready_o    (div_ready_o),
    .clk_o          (clk_o),
    .cycl_count_o   (cycl_count_o)
  );

  initial begin
    rst_ni         = 1'b0;
    en_i           = 1'b1;
    test_mode_en_i = 1'b0;
    div_i          = 4'd0;
    div_valid_i    = 1'b0;
  end

  // -------------------------------------------------- edge bookkeeping ------
  int      errors      = 0;
  int      rise_cnt    = 0;
  realtime t_last_rise = 0.0;
  realtime t_last_fall = 0.0;

  always @(posedge clk_o) begin rise_cnt++;  t_last_rise = $realtime; end
  always @(negedge clk_o) begin              t_last_fall = $realtime; end

  task automatic fail(input string tag, input string msg);
    errors++;
    $display("FAIL %s: %s", tag, msg);
  endtask

  // Wait for a clk_o edge, but never longer than `budget` clk_i cycles.
  // (Termination guarantee: a dead clk_o cannot hang the bench.)
  task automatic wait_edge(input bit rising, input int budget,
                           output realtime t, output bit ok);
    ok = 1'b0;
    fork
      begin
        if (rising) @(posedge clk_o);
        else        @(negedge clk_o);
        t  = $realtime;
        ok = 1'b1;
      end
      begin
        repeat (budget) @(posedge clk);
      end
    join_any
    disable fork;
  endtask

  // Offer a divisor (H2 obeyed: div_i held stable while valid is high).
  // trdy = time of the clk_i posedge on which div_ready_o was seen high.
  task automatic req_div(input int d, output bit acc, output int waited,
                         output realtime trdy);
    acc = 1'b0; waited = 0; trdy = 0.0;
    @(negedge clk);
    div_i = d[3:0];
    div_valid_i = 1'b1;
    while (waited < 120) begin
      @(posedge clk);
      if (div_ready_o === 1'b1) begin
        acc  = 1'b1;
        trdy = $realtime;
        break;
      end
      waited++;
    end
    @(negedge clk);
    div_valid_i = 1'b0;
  endtask

  // H1: div_ready_o is low while div_valid_i is low.
  task automatic check_h1;
    for (int i = 0; i < 20; i++) begin
      @(posedge clk);
      if (div_ready_o !== 1'b0)
        fail("H1", "div_ready_o high while div_valid_i low");
    end
  endtask

  // G1/G2 for a change to `newd` from `oldd`, measured FROM the cycle
  // div_ready_o rose (trdy). Only the EXACT upper bound is checked; the
  // actual duration below it is free (L2).
  task automatic check_gating(input int newd, input int oldd,
                              input realtime trdy);
    realtime tr, w;
    bit ok;
    int budget;
    budget = 3*newd + 20;
    wait_edge(1'b1, budget, tr, ok);
    if (!ok) begin
      if (clk_o === 1'b1)
        fail("G2", $sformatf("clk_o stuck high across change to div %0d", newd));
      else
        fail("G1", $sformatf("div %0d: no rising edge within %0d clk_i cycles of div_ready_o",
                             newd, 3*newd));
      return;
    end
    // G1: gap from the div_ready_o cycle to the first rise <= 3 * new period.
    // +5.5 ns lets the first rise land on a clk_i falling edge (odd divisors).
    if ((tr - trdy) > 3.0 * newd * 10.0 + 5.5)
      fail("G1", $sformatf("div %0d: gating gap %0.1f ns exceeds bound %0d ns",
                           newd, real'(tr - trdy), 30*newd));
    // G2: a fall inside the gating window must close a FULL-width high phase
    // (no partial pulse, and not a stop-high). Widths are half-periods, so a
    // runt is distinguishable from a legitimate phase tail.
    if (t_last_fall > trdy && t_last_fall < tr) begin
      w = t_last_fall - t_last_rise;
      if (w < 5.0 * ((oldd < newd) ? oldd : newd) - 2.0)
        fail("G2", $sformatf("div %0d: partial pulse of %0.1f ns across the change",
                             newd, real'(w)));
    end
  endtask

  // P1/P2/P3/E2/R2: period and duty measured IN TIME (P4). Duty is only
  // checked for div >= 2 (X2 excludes pass-through duty).
  task automatic check_period_duty(input int d, input string tag);
    realtime t1, tf, t2;
    bit ok;
    real period, th;
    wait_edge(1'b1, 400, t1, ok);
    if (!ok) begin fail(tag, "no rising edge on clk_o"); return; end
    wait_edge(1'b0, 400, tf, ok);
    if (!ok) begin fail(tag, "no falling edge after a rising edge"); return; end
    wait_edge(1'b1, 400, t2, ok);
    if (!ok) begin fail(tag, "no second rising edge on clk_o"); return; end
    period = real'(t2 - t1);
    th     = real'(tf - t1);
    if (d >= 2) begin
      if (period < d*10.0 - 1.5 || period > d*10.0 + 1.5)
        fail(tag, $sformatf("div %0d: period %0.1f ns, expected %0d ns", d, period, d*10));
      if (th < period/2.0 - 1.5 || th > period/2.0 + 1.5)
        fail("P2", $sformatf("div %0d: high phase %0.1f ns of %0.1f ns period (not 50%%)",
                             d, th, period));
    end else begin
      if (period < 8.5 || period > 11.5)
        fail(tag, $sformatf("pass-through div %0d: period %0.1f ns, expected 10 ns",
                            d, period));
    end
  endtask

  // C1/C3: counter advances once per clk_i cycle and wraps at the divisor.
  // Sampled on the negedge (opposite the edge that updates it).
  task automatic check_count(input int d, input string tag);
    int n, prev, v;
    if (d < 2) return;
    n = 2*d + 6;
    @(negedge clk);
    prev = cycl_count_o;
    if (prev >= d)
      fail(tag, $sformatf("div %0d: cycl_count_o %0d out of range 0..%0d", d, prev, d-1));
    for (int i = 1; i < n; i++) begin
      @(negedge clk);
      v = cycl_count_o;
      if (v >= d)
        fail(tag, $sformatf("div %0d: cycl_count_o %0d out of range 0..%0d", d, v, d-1));
      else if (v != ((prev + 1) % d))
        fail(tag, $sformatf("div %0d: cycl_count_o %0d after %0d, expected +1 mod %0d",
                            d, v, prev, d));
      prev = v;
    end
  endtask

  // C2: counter constantly 0 in pass-through.
  task automatic check_c2;
    for (int i = 0; i < 12; i++) begin
      @(negedge clk);
      if (cycl_count_o !== 4'd0)
        fail("C2", $sformatf("cycl_count_o %0d in pass-through", cycl_count_o));
    end
  endtask

  // H3: same-value request granted in the same cycle, output NOT gated.
  task automatic test_h3(input int d);
    bit acc; int waited; realtime trdy, tr; bit ok;
    req_div(d, acc, waited, trdy);
    if (!acc)
      fail("H3", $sformatf("same-value request (div %0d) never accepted", d));
    else if (waited != 0)
      fail("H3", $sformatf("same-value request (div %0d) granted %0d cycles late",
                           d, waited));
    wait_edge(1'b1, d + 6, tr, ok);
    if (!ok || (tr - trdy) > d*10.0 + 5.5)
      fail("H3", $sformatf("div %0d: output gated across a same-value request", d));
  endtask

  // H4: a second request offered while the first is still gating is deferred,
  // then accepted (duration of the deferral is free -- L4).
  task automatic test_h4;
    bit a1, a2; int w1, w2; realtime t1, t2;
    req_div(6, a1, w1, t1);
    if (!a1) begin
      fail("H4", "first request (to div 6) never accepted");
      return;
    end
    @(negedge clk);
    div_i       = 4'd3;
    div_valid_i = 1'b1;
    w2 = 0; a2 = 1'b0; t2 = 0.0;
    while (w2 < 100) begin
      @(posedge clk);
      if (div_ready_o === 1'b1) begin a2 = 1'b1; t2 = $realtime; break; end
      w2++;
    end
    @(negedge clk);
    div_valid_i = 1'b0;
    if (!a2)
      fail("H4", "second request during a transition never accepted");
    else begin
      check_gating(3, 6, t2);
      check_period_duty(3, "P1");
      check_count(3, "C3");
    end
  endtask

  // E1/E2/E3 at divisor d (used with odd d=5 and even d=4).
  task automatic test_e(input int d);
    realtime t1, tf; bit ok; int r0;
    // E3: drop en_i mid-high-pulse; the pulse must complete at FULL width.
    wait_edge(1'b1, 400, t1, ok);
    if (!ok) begin fail("E3", "no rising edge before disable test"); return; end
    @(negedge clk);          // first clk_i negedge after the rise: mid-pulse
    en_i = 1'b0;             // for every d >= 2, even or odd
    wait_edge(1'b0, 400, tf, ok);
    if (!ok)
      fail("E3", "clk_o never fell after en_i dropped")
    else if ((tf - t1) < d*5.0 - 2.0 || (tf - t1) > d*5.0 + 2.0)
      fail("E3", $sformatf("div %0d: final high pulse %0.1f ns, expected %0d ns",
                           d, real'(tf - t1), d*5));
    // E1 (+ rest of E3): no rising edges for 100 cycles, output rests low.
    r0 = rise_cnt;
    for (int i = 0; i < 100; i++) begin
      @(posedge clk);
      @(negedge clk);
      if (clk_o !== 1'b0)
        fail("E3", "clk_o high at rest while en_i low");
    end
    if (rise_cnt != r0)
      fail("E1", "rising edge on clk_o while en_i low");
    // E2: resumes at the configured divisor.
    @(negedge clk);
    en_i = 1'b1;
    check_period_duty(d, "E2");
    check_count(d, "C1");
  endtask

  // R1/R2: reset kills the output; release restores the DEFAULT divisor.
  task automatic test_r;
    int r0;
    @(negedge clk);
    rst_ni = 1'b0;
    r0 = rise_cnt;
    repeat (12) @(posedge clk);
    if (rise_cnt != r0)
      fail("R1", "rising edge on clk_o while rst_ni low");
    @(negedge clk);
    rst_ni = 1'b1;
    check_period_duty(1, "R2");   // back to pass-through, period 1
    check_c2();
  endtask

  // ------------------------------------------------------------- main -------
  initial begin : main
    bit acc; int waited; realtime trdy; bit ok; realtime t;
    int prev_d;

    repeat (3) @(posedge clk);
    @(negedge clk);
    rst_ni = 1'b1;

    check_h1();

    // Output runs after reset with the default divisor 0 (R2 / P3).
    wait_edge(1'b1, 40, t, ok);
    if (!ok) fail("R2", "no clk_o activity after reset release (default divisor 0)");

    test_h3(0);                    // H3 on the default value
    check_period_duty(0, "P3");
    check_c2();

    req_div(1, acc, waited, trdy);  // 0 -> 1
    if (!acc) fail("H1", "request for divisor 1 never accepted");
    else begin
      check_gating(1, 0, trdy);
      check_period_duty(1, "P3");
      check_c2();
    end

    // Sweep every divisor 2..15: G1/G2 on each change, then P1/P2 in time,
    // then C1/C3 on the counter, then H3 at that value.
    prev_d = 1;
    for (int d = 2; d <= 15; d++) begin
      req_div(d, acc, waited, trdy);
      if (!acc) fail("H1", $sformatf("request for divisor %0d never accepted", d));
      else begin
        check_gating(d, prev_d, trdy);
        check_period_duty(d, "P1");
        check_count(d, "C3");
        test_h3(d);
        prev_d = d;
      end
    end

    // Jump transitions, including to pass-through where the G1 bound (3
    // cycles) is exactly attained on conforming units.
    req_div(0, acc, waited, trdy);
    if (!acc) fail("H1", "request for divisor 0 never accepted");
    else begin
      check_gating(0, prev_d, trdy);
      check_period_duty(0, "P3");
      check_c2();
      prev_d = 0;
    end

    req_div(9, acc, waited, trdy);
    if (!acc) fail("H1", "request for divisor 9 never accepted");
    else begin
      check_gating(9, 0, trdy);
      check_period_duty(9, "P1");
      check_count(9, "C1");
      prev_d = 9;
    end

    req_div(1, acc, waited, trdy);
    if (!acc) fail("H1", "request for divisor 1 never accepted");
    else begin
      check_gating(1, 9, trdy);
      check_period_duty(1, "P3");
      check_c2();
      prev_d = 1;
    end

    test_h4();                      // ends at div 3, running

    req_div(5, acc, waited, trdy);  // E-clauses at an odd divisor
    if (!acc) fail("H1", "request for divisor 5 never accepted");
    else begin
      check_gating(5, 3, trdy);
      test_e(5);
    end

    req_div(4, acc, waited, trdy);  // E-clauses at an even divisor
    if (!acc) fail("H1", "request for divisor 4 never accepted");
    else begin
      check_gating(4, 5, trdy);
      test_e(4);
    end

    test_r();

    if (errors == 0) $display("RESULT: PASS");
    else              $display("RESULT: FAIL");
    $finish;
  end

  // Watchdog: fires no matter what the design does.
  initial begin
    #4_000_000;
    $display("RESULT: FAIL (watchdog: test did not complete)");
    $finish;
  end

endmodule
