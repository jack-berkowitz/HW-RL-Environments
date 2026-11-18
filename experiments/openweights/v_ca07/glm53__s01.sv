`timescale 1ns/1ps
// ---------------------------------------------------------------------------
// Self-checking testbench for clk_ratio_div.
// Drives and times everything from clk_i; measures clk_o by edge timestamps.
// ---------------------------------------------------------------------------
module clk_ratio_div_tb;

  logic clk;
  initial begin clk = 1'b0; forever #5 clk = ~clk; end

  logic       rst_n;
  logic       en;
  logic [3:0] div;
  logic       div_valid;
  logic       test_mode;
  logic       div_ready;
  logic       clk_o;
  logic [3:0] cycl_count;

  clk_ratio_div dut (
    .clk_i(clk), .rst_ni(rst_n), .en_i(en), .test_mode_en_i(test_mode),
    .div_i(div), .div_valid_i(div_valid),
    .div_ready_o(div_ready), .clk_o(clk_o), .cycl_count_o(cycl_count)
  );

  int errors = 0;
  task automatic fail(input string req, input string msg);
    errors = errors + 1;
    $display("FAIL %0s: %0s", req, msg);
  endtask

  // ---- edge monitors: timestamps only, clean 0->1 / 1->0 transitions ----
  int     mon_en   = 0;
  int     rise_cnt = 0, fall_cnt = 0;
  longint t_rise = 0, t_fall = 0, ready_t = 0;
  longint rise_q[$];
  longint fall_q[$];
  logic   prev_o   = 1'bx;
  logic   prev_rdy = 1'bx;

  always @(clk_o) begin
    if (mon_en) begin
      if (clk_o === 1'b1 && prev_o === 1'b0) begin
        rise_cnt = rise_cnt + 1;
        t_rise   = $time;
        rise_q.push_back(longint'($time));
        if (rise_q.size() > 64) rise_q.pop_front();
      end
      if (clk_o === 1'b0 && prev_o === 1'b1) begin
        fall_cnt = fall_cnt + 1;
        t_fall   = $time;
        fall_q.push_back(longint'($time));
        if (fall_q.size() > 64) fall_q.pop_front();
      end
    end
    prev_o = clk_o;
  end

  always @(div_ready) begin
    if (mon_en && div_ready === 1'b1 && prev_rdy !== 1'b1) ready_t = $time;
    prev_rdy = div_ready;
  end

  // start of the clk_i cycle containing time t (posedges sit at 5 mod 10)
  function automatic longint cyc_start(input longint t);
    longint k;
    k = (t - 5) / 10;
    return k * 10 + 5;
  endfunction

  // Wait for the first rise/fall at or after time t (ge=1) or strictly
  // after it (ge=0), with a bound in clk_i cycles. Never hangs.
  task automatic next_ev(input longint t, input bit is_rise, input bit ge,
                         input int cycles, output bit ok, output longint te);
    int i, lim, j;
    ok = 1'b0;
    te = 0;
    lim = cycles + 2;
    i = 0;
    while (i < lim) begin
      if (is_rise) begin
        for (j = 0; j < rise_q.size(); j++) begin
          if ((ge && rise_q[j] >= t) || (!ge && rise_q[j] > t)) begin
            te = rise_q[j]; ok = 1'b1; break;
          end
        end
      end else begin
        for (j = 0; j < fall_q.size(); j++) begin
          if ((ge && fall_q[j] >= t) || (!ge && fall_q[j] > t)) begin
            te = fall_q[j]; ok = 1'b1; break;
          end
        end
      end
      if (ok) break;
      @(negedge clk);
      i = i + 1;
    end
  endtask

  // Offer a divisor; hold it stable (H2) until granted. Reports grant and
  // how many polls elapsed before it (0 = same cycle).
  task automatic set_div(input int d, input int budget,
                         output bit acc, output int waited);
    int i;
    acc = 0;
    waited = 0;
    @(negedge clk);
    div = d;
    div_valid = 1'b1;
    i = 0;
    while (i < budget) begin
      @(negedge clk);
      if (div_ready === 1'b1) begin
        acc = 1;
        waited = i;
        break;
      end
      i = i + 1;
    end
    div_valid = 1'b0;
  endtask

  // P1/P2/P3: period and, for div>=2, the 50/50 split, measured in time.
  task automatic run_at(input int d);
    int per;
    longint anchor, t1, f1, t2, f2, t3;
    bit ok;
    per = (d <= 1) ? 1 : d;
    anchor = $time;
    next_ev(anchor, 1'b1, 1'b1, 3*per + 40, ok, t1);
    if (!ok) begin fail("P1", $sformatf("no clk_o rise at divisor %0d", d)); return; end
    next_ev(t1, 1'b0, 1'b0, 3*per + 40, ok, f1);
    if (!ok) begin fail("P2", $sformatf("no clk_o fall at divisor %0d", d)); return; end
    next_ev(f1, 1'b1, 1'b0, 3*per + 40, ok, t2);
    if (!ok) begin fail("P1", "clk_o stopped (no rise)"); return; end
    next_ev(t2, 1'b0, 1'b0, 3*per + 40, ok, f2);
    if (!ok) begin fail("P2", "clk_o stopped (no fall)"); return; end
    next_ev(f2, 1'b1, 1'b0, 3*per + 40, ok, t3);
    if (!ok) begin fail("P1", "clk_o stopped (no rise)"); return; end
    if ((t2 - t1) < per*10 - 2 || (t2 - t1) > per*10 + 2)
      fail("P1", $sformatf("period %0d ns at divisor %0d (want %0d)", t2-t1, d, per*10));
    if ((t3 - t2) < per*10 - 2 || (t3 - t2) > per*10 + 2)
      fail("P1", $sformatf("period %0d ns at divisor %0d", t3-t2, d));
    if (d >= 2) begin
      if ((f1 - t1) < d*5 - 2 || (f1 - t1) > d*5 + 2)
        fail("P2", $sformatf("high time %0d ns at divisor %0d (want %0d)", f1-t1, d, d*5));
      if ((f2 - t2) < d*5 - 2 || (f2 - t2) > d*5 + 2)
        fail("P2", $sformatf("high time %0d ns at divisor %0d", f2-t2, d));
      if ((t2 - f1) < d*5 - 2 || (t2 - f1) > d*5 + 2)
        fail("P2", $sformatf("low time %0d ns at divisor %0d", t2-f1, d));
      if ((t3 - f2) < d*5 - 2 || (t3 - f2) > d*5 + 2)
        fail("P2", $sformatf("low time %0d ns at divisor %0d", t3-f2, d));
    end
  endtask

  // C1: counts 0..d-1, advancing once per clk_i cycle, wrapping at d.
  task automatic check_count(input int d, input string req);
    int prev, cur, i, j, n;
    int seen[16];
    for (j = 0; j < 16; j = j + 1) seen[j] = 0;
    n = 3*d + 2;
    prev = -1;
    for (i = 0; i < n; i++) begin
      @(negedge clk);
      cur = cycl_count;
      if (cur >= d) begin
        fail(req, $sformatf("cycl_count %0d out of range 0..%0d at divisor %0d", cur, d-1, d));
        return;
      end
      if (prev >= 0) begin
        if (!((prev == d-1 && cur == 0) || (cur == prev + 1))) begin
          fail(req, $sformatf("cycl_count %0d -> %0d is not +1 mod %0d", prev, cur, d));
          return;
        end
      end
      seen[cur] = 1;
      prev = cur;
    end
    for (j = 0; j < d; j = j + 1) begin
      if (seen[j] == 0) begin
        fail(req, $sformatf("cycl_count value %0d never appears at divisor %0d", j, d));
        return;
      end
    end
  endtask

  // C2: pass-through counter is constantly 0.
  task automatic check_pt_count();
    int i;
    for (i = 0; i < 20; i++) begin
      @(negedge clk);
      if (cycl_count !== 4'd0) begin
        fail("C2", "cycl_count_o not constantly 0 in pass-through");
        return;
      end
    end
  endtask

  // H3: no gap between consecutive rises around a same-value request.
  task automatic h3_gap_check(input longint t_a, input longint t_b, input int per);
    int j;
    longint prev_t, cur_t;
    bit first;
    first = 1'b1;
    prev_t = 0;
    for (j = 0; j < rise_q.size(); j++) begin
      if (rise_q[j] >= t_a && rise_q[j] <= t_b) begin
        cur_t = rise_q[j];
        if (!first) begin
          if (cur_t - prev_t > per*10 + 2)
            fail("H3", $sformatf("output gated across same-value request (gap %0d ns)", cur_t - prev_t));
        end
        first = 1'b0;
        prev_t = cur_t;
      end
    end
  endtask

  // Post-grant verification: G1 (bound from the div_ready cycle), G2, C3,
  // then P1/P2 and C1/C2 at the new divisor.
  task automatic verify_after_change(input int b, input string req);
    int per, i, prev, cur;
    bit ok;
    longint tready, tstart, tfr, tfw;
    per = (b <= 1) ? 1 : b;
    tready = ready_t;
    tstart = cyc_start(tready);
    next_ev(tready, 1'b1, 1'b1, 3*per + 25, ok, tfr);
    if (!ok) begin
      fail("G1", $sformatf("clk_o never resumed after change to divisor %0d", b));
      return;
    end
    if ((tfr - tstart) > 3*per*10 + 2)
      fail("G1", $sformatf("gating gap %0d ns exceeds %0d ns for divisor %0d",
                           tfr - tstart, 3*per*10, b));
    if (b >= 2) begin
      // C3: from the resume, count runs over the new range immediately.
      prev = -1;
      for (i = 0; i < 2*b + 6; i++) begin
        @(negedge clk);
        cur = cycl_count;
        if (i > 0) begin
          if (cur >= b)
            fail("C3", $sformatf("cycl_count %0d outside new range 0..%0d", cur, b - 1));
          if (prev >= 0) begin
            if (!((prev == b - 1 && cur == 0) || (cur == prev + 1)))
              fail("C3", $sformatf("cycl_count %0d -> %0d is not +1 mod %0d", prev, cur, b));
          end
        end
        prev = cur;
      end
      // G2: no partial pulse, output not left high.
      next_ev(tfr, 1'b0, 1'b0, 3*per + 15, ok, tfw);
      if (!ok)
        fail("G2", $sformatf("clk_o left high after resume at divisor %0d", b));
      else if (tfw - tfr < b*5 - 2)
        fail("G2", $sformatf("partial pulse %0d ns at divisor %0d", tfw - tfr, b));
    end
    run_at(b);
    if (b <= 1) check_pt_count();
    else check_count(b, "C1");
  endtask

  task automatic change_to(input int b, input string req);
    bit acc;
    int waited;
    set_div(b, 120, acc, waited);
    if (!acc) begin
      fail(req, $sformatf("change to divisor %0d never granted", b));
      return;
    end
    verify_after_change(b, req);
  endtask

  // E1/E2/E3 at divisor d (d >= 2 so the half period is unambiguous).
  task automatic e_test(input int d);
    int i, pre;
    bit ok;
    longint tr, tfw;
    next_ev($time, 1'b1, 1'b1, 3*d + 12, ok, tr);
    if (!ok) begin
      fail("E1", $sformatf("no clk_o rise at divisor %0d before disable", d));
      return;
    end
    en = 1'b0;                       // driven on the negedge we detected the rise
    // E3: the high phase in progress completes at full width.
    next_ev(tr, 1'b0, 1'b0, 3*d + 12, ok, tfw);
    if (!ok) begin
      if (clk_o === 1'b1) fail("E3", "clk_o left high after en_i low");
    end else if (tfw - tr < d*5 - 2 || tfw - tr > d*5 + 2) begin
      fail("E3", $sformatf("final pulse width %0d ns at divisor %0d (want %0d)", tfw-tr, d, d*5));
    end
    // E3: low once at rest.
    for (i = 0; i < 40; i++) begin
      @(negedge clk);
      if (clk_o !== 1'b0) begin
        fail("E3", "clk_o not low while disabled");
        break;
      end
    end
    // E1: no rising edge while disabled (>= 100 cycles total).
    pre = rise_cnt;
    for (i = 0; i < 60; i++) @(negedge clk);
    if (rise_cnt != pre) fail("E1", "rising edge on clk_o while en_i low");
    // E2: resumes at the configured divisor.
    @(negedge clk);
    en = 1'b1;
    run_at(d);
  endtask

  // ---- watchdog ----
  initial begin
    #4_000_000;
    $display("RESULT: FAIL (watchdog: no forward progress)");
    $finish;
  end

  // ---- main stimulus ----
  initial begin : main_stim
    bit acc, ok;
    int waited, c, i, a, b, curd;
    longint t_a, t_b;

    en        = 1'b1;
    div_valid = 1'b0;
    div       = 4'd0;
    test_mode = 1'b0;
    rst_n     = 1'b0;

    repeat (4) @(posedge clk);
    @(negedge clk);
    rst_n = 1'b1;
    mon_en = 1'b1;
    repeat (5) @(negedge clk);

    // H1: div_ready low while div_valid low.
    for (i = 0; i < 20; i++) begin
      @(negedge clk);
      if (div_ready !== 1'b0) begin
        fail("H1", "div_ready_o high while div_valid_i low");
        break;
      end
    end

    // P3 / R2: default divisor 0 is pass-through, period one clk_i cycle.
    run_at(0);
    check_pt_count();

    // P3: divisor 1 is pass-through too.
    change_to(1, "P3");
    curd = 1;

    // H1 again after a completed transfer.
    repeat (2) @(negedge clk);
    for (i = 0; i < 20; i++) begin
      @(negedge clk);
      if (div_ready !== 1'b0) begin
        fail("H1", "div_ready_o high while div_valid_i low");
        break;
      end
    end

    // P1/P2/C1/C3/G1/G2 for every divisor 2..15.
    for (i = 2; i <= 15; i++) begin
      change_to(i, "P1");
      curd = i;
    end

    // H3: same-value request granted in the same cycle, no gating.
    change_to(4, "H3");
    curd = 4;
    next_ev($time, 1'b1, 1'b1, 24, ok, t_a);
    if (!ok) fail("H3", "no clk_o rise before same-value request");
    else begin
      set_div(4, 10, acc, waited);
      if (!acc) fail("H3", "same-value request never granted");
      else if (waited != 0) fail("H3", "same-value grant not in the same cycle");
      next_ev($time, 1'b1, 1'b1, 24, ok, t_b);
      if (!ok) fail("H3", "clk_o stopped after same-value request");
      else h3_gap_check(t_a, t_b, 4);
    end

    // H4: a request offered while a first change is still gating is
    // deferred, not refused.
    set_div(8, 120, acc, waited);
    if (!acc) fail("H4", "first change (to 8) never granted");
    set_div(3, 200, acc, waited);
    if (!acc) fail("H4", "request offered during gating was refused");
    verify_after_change(3, "H4");
    curd = 3;

    // E1/E2/E3.
    change_to(4, "E1");
    e_test(4);
    change_to(5, "E1");
    e_test(5);
    curd = 5;

    // R1/R2.
    change_to(4, "R1");
    curd = 4;
    c = rise_cnt;
    @(negedge clk);
    rst_n = 1'b0;
    for (i = 0; i < 10; i++) @(posedge clk);
    if (rise_cnt != c) fail("R1", "rising edge on clk_o while rst_ni low");
    @(negedge clk);
    rst_n = 1'b1;
    repeat (5) @(negedge clk);
    run_at(0);            // R2: back to the default divisor
    check_pt_count();
    curd = 0;

    // G1/G2 across the ordered pairs of divisors 0..8.
    for (a = 0; a <= 8; a++) begin
      if (curd != a) begin
        change_to(a, "G1");
        curd = a;
      end
      for (b = 0; b <= 8; b++) begin
        if (b == a) continue;
        change_to(b, "G1");
        change_to(a, "G1");
        curd = a;
      end
    end

    if (errors == 0) $display("RESULT: PASS");
    else             $display("RESULT: FAIL");
    $finish;
  end

endmodule
