// ---------------------------------------------------------------------------
// clk_ratio_div_tb -- self-checking testbench for clk_ratio_div.
//
// All stimulus is driven and all time is measured from clk_i.  clk_o is never
// used as a clock: its edges are timestamped and the INTERVALS between them
// are checked (P1/P2 in raw time, G1's gap from the cycle div_ready_o rises,
// etc.).  Every wait on clk_o is bounded by a clk_i-cycle budget, so a design
// that stops clk_o cannot hang the bench.
// ---------------------------------------------------------------------------
`timescale 1ns/1ps

module clk_ratio_div_tb;

  localparam real TCLK = 10.0;   // clk_i period in ns

  // ---- clock / reset ------------------------------------------------------
  logic clk;
  initial begin clk = 1'b0; forever #5 clk = ~clk; end

  logic rst_n;
  initial rst_n = 1'b0;

  // ---- DUT ----------------------------------------------------------------
  logic       en, tmode, div_valid;
  logic [3:0] div_i;
  wire        div_ready, clk_o;
  wire [3:0]  cycl_count_o;

  clk_ratio_div dut (
    .clk_i           (clk),
    .rst_ni          (rst_n),
    .en_i            (en),
    .test_mode_en_i  (tmode),
    .div_i           (div_i),
    .div_valid_i     (div_valid),
    .div_ready_o     (div_ready),
    .clk_o           (clk_o),
    .cycl_count_o    (cycl_count_o)
  );

  int errors = 0;

  function automatic real absg(input real r);
    return (r < 0.0) ? -r : r;
  endfunction

  task automatic fail(input string tag, input string msg);
    errors++;
    $display("FAIL %0s: %0s", tag, msg);
  endtask

  // ---- edge bookkeeping on clk_o (timestamps, never a clock) --------------
  int  n_rises = 0;
  real last_rise_t = 0.0;
  always @(posedge clk_o) begin
    n_rises     = n_rises + 1;
    last_rise_t = $realtime;
  end

  real  eq_t[$];       // timestamp of every clk_o transition
  logic eq_v[$];       // value clk_o took at that transition
  always @(clk_o) begin
    eq_t.push_back($realtime);
    eq_v.push_back(clk_o);
  end

  // div_ready_o rise monitor: records the exact rise time (works whether the
  // DUT raises it combinationally or out of an NBA at a posedge).
  int  n_ready_rises = 0;
  real t_ready_mon   = 0.0;
  always @(posedge div_ready) begin
    n_ready_rises = n_ready_rises + 1;
    t_ready_mon   = $realtime;
  end

  // ---- bounded waits on clk_o (budget in clk_i cycles) ---------------------
  task automatic wait_rise_o(input int budget, output real t);
    t = -1.0;
    fork
      begin @(posedge clk_o); t = $realtime; end
      begin repeat (budget) @(posedge clk); t = -1.0; end
    join_any
    disable fork;
  endtask

  task automatic wait_fall_o(input int budget, output real t);
    t = -1.0;
    fork
      begin @(negedge clk_o); t = $realtime; end
      begin repeat (budget) @(posedge clk); t = -1.0; end
    join_any
    disable fork;
  endtask

  task automatic wait_any_o(input int budget, output real t, output logic v);
    t = -1.0; v = 1'bx;
    fork
      begin @(posedge clk_o); t = $realtime; v = 1'b1; end
      begin @(negedge clk_o); t = $realtime; v = 1'b0; end
      begin repeat (budget) @(posedge clk); t = -1.0; end
    join_any
    disable fork;
  endtask

  // ---- handshake: offer a divisor, hold it stable (H2), report grant time.
  //      t_ready = start of the clk_i cycle in which div_ready_o rose
  //                (G1's origin), t_grant = raw rise time, t_assert = when
  //      div_valid_i was asserted.
  task automatic offer_div(input int d, input int budget,
                           output real t_ready, output real t_grant,
                           output real t_assert);
    automatic int n0;
    @(negedge clk);
    div_i     = d[3:0];
    div_valid = 1'b1;
    t_assert  = $realtime;
    n0        = n_ready_rises;
    t_ready   = -1.0;
    t_grant   = -1.0;
    for (int w = 0; w < budget; w++) begin
      @(posedge clk);
      if (n_ready_rises > n0) begin
        t_grant = t_ready_mon;
        t_ready = 1.0 * int'(t_ready_mon / TCLK) * TCLK; // floor to cycle start
        break;
      end
    end
    @(negedge clk);
    div_valid = 1'b0;
  endtask

  // ---- change to divisor b and check G1 / G2 ------------------------------
  task automatic change_and_check(input int b);
    automatic real t_ready, t_grant, t_assert, t_rise, t_f;
    automatic int  per, i;
    per = (b <= 1) ? 1 : b;
    offer_div(b, 300, t_ready, t_grant, t_assert);
    if (t_ready < 0.0) begin
      fail("H1", $sformatf("request for div %0d never granted", b));
      return;
    end
    // G1: gap from the cycle div_ready_o rises to the first rising edge of
    // the new clock, at most 3 x new period (+ half a cycle of alignment
    // slack for edges that land on clk_i falling edges).
    wait_rise_o(3*per + 25, t_rise);
    if (t_rise < 0.0) begin
      fail("G1", $sformatf("no rising edge of clk_o after change to %0d", b));
      return;
    end
    if ((t_rise - t_ready) > (3.0*per + 0.5)*TCLK + 0.05)
      fail("G1", $sformatf("gating gap %0.3f ns after change to %0d exceeds bound %0.1f ns",
                           t_rise - t_ready, b, 3.0*per*TCLK));
    // G2: no rising edge before t_rise is inherent (t_rise is the first).
    // A high phase already in progress at the grant may complete, but only
    // within half a period -- it must not stop high.
    for (i = 0; i < eq_t.size(); i++) begin
      if (eq_t[i] > t_grant + 0.05 && eq_t[i] < t_rise - 0.05 &&
          eq_v[i] == 1'b0) begin
        if (eq_t[i] - t_grant > per*TCLK/2.0 + TCLK/2.0 + 0.05)
          fail("G2", "clk_o stayed high well into the gating interval");
        i = eq_t.size();
      end
    end
    // G2: the first pulse after resume must be a full half period (no partial
    // pulse).  Skipped in pass-through, whose sub-cycle duty is not a
    // property of this unit (X2).
    if (b > 1) begin
      wait_fall_o(3*per + 25, t_f);
      if (t_f > 0.0 && absg(t_f - t_rise - per*TCLK/2.0) > 0.05)
        fail("G2", "first pulse after resume is not a full half period");
    end
  endtask

  // ---- P1 / P2: period and duty measured in raw time -----------------------
  task automatic check_periods(input int d, input int nper);
    automatic real t1, t2, t3;
    for (int k = 0; k < nper; k++) begin
      wait_rise_o(4*d + 25, t1);
      wait_fall_o(4*d + 25, t2);
      wait_rise_o(4*d + 25, t3);
      if (t1 < 0.0 || t2 < 0.0 || t3 < 0.0) begin
        fail("P1", $sformatf("timeout waiting for clk_o edges at div %0d", d));
        return;
      end
      if (absg(t3 - t1 - d*TCLK) > 0.05)
        fail("P1", $sformatf("period %0.3f ns at div %0d, expected %0.1f",
                             t3 - t1, d, d*TCLK));
      if (absg(t2 - t1 - d*TCLK/2.0) > 0.05)
        fail("P2", $sformatf("high phase %0.3f ns at div %0d, expected %0.1f",
                             t2 - t1, d, d*TCLK/2.0));
      if (absg(t3 - t2 - d*TCLK/2.0) > 0.05)
        fail("P2", $sformatf("low phase %0.3f ns at div %0d, expected %0.1f",
                             t3 - t2, d, d*TCLK/2.0));
    end
  endtask

  // ---- P3: pass-through period is one input cycle (duty excluded, X2) ------
  task automatic check_passthrough;
    automatic real t1, t3;
    wait_rise_o(30, t1);
    wait_rise_o(30, t3);
    if (t1 < 0.0 || t3 < 0.0)
      fail("P3", "no clk_o edges in pass-through");
    else if (absg(t3 - t1 - TCLK) > 0.05)
      fail("P3", $sformatf("pass-through period %0.3f ns, expected %0.1f",
                           t3 - t1, TCLK));
  endtask

  // ---- C1: counter cycles 0..d-1 (phase-agnostic) --------------------------
  task automatic check_counter(input int d);
    automatic logic [3:0] s[$];
    automatic bit ok;
    ok = 1'b1;
    for (int k = 0; k <= d; k++) begin
      @(posedge clk);
      s.push_back(cycl_count_o);
    end
    for (int k = 0; k < d && ok; k++) begin
      if (int'(s[k]) >= d) begin
        fail("C1", $sformatf("cycl_count_o value %0d out of range at div %0d",
                             s[k], d));
        ok = 1'b0;
      end else if (int'(s[k+1]) != ((int'(s[k]) + 1) % d)) begin
        fail("C1", $sformatf("cycl_count_o %0d -> %0d is not +1 mod %0d",
                             s[k], s[k+1], d));
        ok = 1'b0;
      end
    end
  endtask

  // ---- C2: counter constantly 0 in pass-through -----------------------------
  task automatic check_c2;
    for (int k = 0; k < 10; k++) begin
      @(posedge clk);
      if (cycl_count_o !== 4'd0) begin
        fail("C2", "cycl_count_o not 0 in pass-through");
        k = 10;
      end
    end
  endtask

  // ---- H1: div_ready_o low while div_valid_i low ---------------------------
  task automatic check_h1;
    for (int k = 0; k < 20; k++) begin
      @(posedge clk);
      if (div_ready !== 1'b0) begin
        fail("H1", "div_ready_o high while div_valid_i low");
        k = 20;
      end
    end
  endtask

  // ---- H3: same-value request granted in the same cycle, no gating ---------
  task automatic check_h3(input int d);
    automatic real t_ready, t_grant, t_assert, t_rise;
    automatic int  per;
    per = (d <= 1) ? 1 : d;
    offer_div(d, 300, t_ready, t_grant, t_assert);
    if (t_grant < 0.0) begin
      fail("H1", "same-value request never granted");
      return;
    end
    if (t_grant > t_assert + TCLK - 0.05)
      fail("H3", "same-value request not granted in the same cycle");
    // no gating: the next rising edge arrives within one period
    wait_rise_o(per + 10, t_rise);
    if (t_rise < 0.0)
      fail("H3", "no rising edge after a same-value request");
    else if ((t_rise - t_ready) > (per + 0.5)*TCLK + 0.05)
      fail("H3", "output gated across a same-value request");
  endtask

  // ---- H4: a request offered during a transition is deferred, not refused ---
  task automatic check_h4;
    automatic int n0, w;
    @(negedge clk);
    div_i     = 4'd15;
    div_valid = 1'b1;
    n0 = n_ready_rises; w = 0;
    while (w < 300) begin
      @(posedge clk);
      if (n_ready_rises > n0) break;
      w++;
    end
    if (w >= 300) begin
      fail("H1", "first request (to 15) never granted");
      @(negedge clk); div_valid = 1'b0;
      return;
    end
    // second request, offered while the first is still gating; div_i changes
    // only after div_ready_o rose for the first (H2 respected)
    @(negedge clk);
    div_i = 4'd6;
    n0 = n_ready_rises; w = 0;
    while (w < 300) begin
      @(posedge clk);
      if (n_ready_rises > n0) break;
      w++;
    end
    @(negedge clk); div_valid = 1'b0;
    if (w >= 300) begin
      fail("H4", "request offered during a transition never accepted");
      return;
    end
    check_periods(6, 2);   // final divisor is in force
  endtask

  // ---- E1 / E2 / E3 ---------------------------------------------------------
  task automatic en_tests(input int d);
    automatic real t1, tw, half;
    automatic logic v;
    automatic int  att, n0;
    half = d*TCLK/2.0;
    // E3: the high phase in progress when en_i falls completes at full width.
    // Retry a few times so we actually catch a high phase.
    att = 0;
    while (att < 6) begin
      @(negedge clk); en = 1'b0;
      wait_any_o(2*d + 6, t1, v);
      if (t1 > 0.0 && v == 1'b0) begin
        tw = t1 - last_rise_t;             // full width of the final pulse
        if (absg(tw - half) > 0.05)
          fail("E3", $sformatf("final high pulse %0.3f ns at div %0d, expected %0.1f",
                               tw, d, half));
        att = 100;
      end else if (t1 > 0.0 && v == 1'b1) begin
        fail("E1", "rising edge on clk_o while en_i low");
        att = 100;
      end else begin
        if (clk_o !== 1'b0) begin
          fail("E3", "clk_o stuck high after en_i low");
          att = 100;
        end else begin
          // en fell during a low phase: re-enable and try again
          @(negedge clk); en = 1'b1;
          repeat (2*d + 2) @(posedge clk);
          att++;
        end
      end
    end
    if (att != 100) begin
      @(negedge clk); en = 1'b0;
      repeat (2*d + 2) @(posedge clk);
    end
    // E1: zero rising edges in 100 cycles while disabled
    n0 = n_rises;
    repeat (100) @(posedge clk);
    if (n_rises != n0)
      fail("E1", "rising edges on clk_o while en_i low");
    // E3 (second half): low on all input edges once at rest
    for (int k = 0; k < 40; k++) begin
      @(posedge clk);
      if (clk_o !== 1'b0) begin
        fail("E3", "clk_o not low at rest after en_i low");
        k = 40;
      end
    end
    // E2: resumes at the configured divisor
    @(negedge clk); en = 1'b1;
    check_periods(d, 2);
  endtask

  // ---- C3: after an accepted change the counter uses the new range ---------
  task automatic check_c3;
    automatic logic [3:0] s[$];
    automatic real t_ready, t_grant, t_assert, t_rise;
    automatic bit ok;
    offer_div(4, 300, t_ready, t_grant, t_assert);   // 8 -> 4
    if (t_ready < 0.0) begin
      fail("H1", "request (to 4) never granted");
      return;
    end
    wait_rise_o(20, t_rise);                        // wait for resume (L5)
    if (t_rise < 0.0) begin
      fail("G1", "no resume after change 8->4");
      return;
    end
    for (int k = 0; k < 12; k++) begin
      @(posedge clk);
      s.push_back(cycl_count_o);
    end
    ok = 1'b1;
    for (int k = 0; k < 11 && ok; k++) begin
      if (int'(s[k]) > 3) begin
        fail("C3", $sformatf("cycl_count_o %0d outside new range after 8->4 change", s[k]));
        ok = 1'b0;
      end else if (int'(s[k+1]) != ((int'(s[k]) + 1) % 4)) begin
        fail("C3", "cycl_count_o not counting mod the new divisor after change");
        ok = 1'b0;
      end
    end
  endtask

  // ---- R1 / R2 --------------------------------------------------------------
  task automatic check_r2;
    automatic int n0;
    @(negedge clk); rst_n = 1'b0;
    @(posedge clk); n0 = n_rises;
    repeat (4) @(posedge clk);
    if (n_rises != n0)
      fail("R1", "rising edge on clk_o while rst_ni low");
    @(negedge clk); rst_n = 1'b1;
    repeat (5) @(posedge clk);
    check_passthrough();   // R2: default divisor (pass-through) after reset
    check_c2();
  endtask

  // ---- main sequence ---------------------------------------------------------
  initial begin
    en        = 1'b1;
    tmode     = 1'b0;
    div_valid = 1'b0;
    div_i     = 4'd0;

    repeat (3) @(posedge clk);
    begin
      automatic int n0;
      @(posedge clk); n0 = n_rises;
      repeat (5) @(posedge clk);
      if (n_rises != n0)
        fail("R1", "rising edge on clk_o during reset");
    end
    @(negedge clk); rst_n = 1'b1;
    repeat (5) @(posedge clk);

    // default divisor after reset is pass-through
    check_passthrough();
    check_c2();
    check_h1();

    // divisors 2..8: G1/G2 on each change, period and duty in raw time
    for (int d = 2; d <= 8; d++) begin
      change_and_check(d);
      check_periods(d, 3);
      if (d == 3 || d == 4 || d == 8) check_counter(d);
    end
    // divisors 9..15: P1/P2 hold for every divisor of 2 or more
    for (int d = 9; d <= 15; d++) begin
      change_and_check(d);
      check_periods(d, 2);
    end

    // P3: 0 and 1 are pass-through
    change_and_check(1); check_passthrough(); check_c2();
    change_and_check(0); check_passthrough(); check_c2();

    // H3: same-value requests
    check_h3(0);
    change_and_check(4);
    check_h3(4);

    // G1/G2 sweep over all ordered pairs in 0..8
    for (int a = 0; a <= 8; a++) begin
      change_and_check(a);
      for (int b = 0; b <= 8; b++) begin
        if (b != a) change_and_check(b);
      end
    end

    // H4: deferred request (leaves divisor 6)
    check_h4();

    // enable behaviour at an even and an odd divisor
    change_and_check(4); check_periods(4, 1); en_tests(4);
    change_and_check(5); check_periods(5, 1); en_tests(5);

    // C3: 8 -> 4, counter immediately in the new range
    change_and_check(8); check_periods(8, 1);
    check_c3();

    // R1 / R2
    check_r2();

    if (errors == 0) $display("RESULT: PASS");
    else              $display("RESULT: FAIL");
    $finish;
  end

  // ---- watchdog: fires no matter what the design does ------------------------
  initial begin
    #4_000_000;
    $display("RESULT: FAIL (watchdog: no forward progress)");
    $finish;
  end

endmodule
