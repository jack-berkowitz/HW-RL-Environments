// ===========================================================================
// clk_ratio_div_tb.sv -- decides whether a clk_ratio_div obeys the contract.
//
// NOTE ON THE TASK TEXT: the trailing "What to produce" section and the
// provided plumbing are leftovers from a different task (id_width_conv). They
// name SLV_ID_W, s_arvalid, m_rready and an AXI port map, none of which exist
// here. What is kept from that plumbing is its timing discipline -- drive after
// @(negedge clk), sample at @(posedge clk) -- and its watchdog.
//
// EVERYTHING IS TIMED FROM clk_i. clk_o is never used as a clock and never
// waited on without a bound: a faulty unit can stop it entirely, and a
// testbench that blocks on it stops with it. The only thing attached to clk_o
// is a passive edge recorder that timestamps transitions; if clk_o never moves,
// that recorder simply never fires and the bounded waits below still expire.
//
// P4, THE OBLIGATION ON THE MEASURER. Period and duty are measured in TIME, in
// nanoseconds, never by counting clk_i rising edges. clk_i's period is 10 ns,
// so every half-period is an exact integer of ns even at odd divisors: divisor
// 3 is high for 15 ns, divisor 5 for 25 ns, divisor 7 for 35 ns. Counting input
// edges instead would truncate those to 1, 2 and 3 cycles and report 33%, 40%
// and 43% duty -- a clean, self-consistent, wrong answer that would reject
// conforming hardware at all seven odd divisors.
//
// G1 AND L2 ARE A PAIR. Only G1's upper bound is checked, and it is measured
// from the cycle div_ready_o rises, never from the assertion of div_valid_i --
// the handshake wait is not gating. How long gating ACTUALLY lasts below the
// bound is L2's to choose, so nothing here requires a particular duration; a
// unit that resumes in two-thirds of the bound passes exactly as one that sits
// at it. The bound carries a half-clk_i-cycle tolerance because a resume edge
// may legitimately land on a falling edge of clk_i; that tolerance is smaller
// than one cycle, so a unit gating a whole cycle too long is still caught.
//
// ALSO DELIBERATELY NOT CHECKED, because the contract frees it:
//   L1  the phase of clk_o relative to clk_i -- only intervals are examined;
//   L3  when div_ready_o rises for a change to a different value (H3 fixes
//       only the same-value case, and that is the only timing checked);
//   L4  how long H4's deferral lasts -- only that it is eventually accepted;
//   L5  cycl_count_o while the output is gated or disabled. C1/C3 are checked
//       only from the first clk_o rising edge after the clock has resumed;
//   P3  any difference between divisor 0 and 1 -- both are period 1;
//   X2  the sub-cycle duty in pass-through, where clk_o follows clk_i;
//   X4  test_mode_en_i, pinned low.
// ===========================================================================

`timescale 1ns/1ps

module clk_ratio_div_tb;

  // clk_i period, and half of it.  Chosen so every half-period of clk_o is an
  // exact integer of ns at every divisor, odd ones included.
  localparam int CLKP = 10;
  localparam int CLKH = 5;

  // =========================================================================
  // clock, reset, watchdog
  // =========================================================================
  logic clk;
  initial begin clk = 1'b0; forever #5 clk = ~clk; end

  logic rst_n;
  initial rst_n = 1'b0;

  task automatic bfm_reset(input int cycles = 4);
    @(negedge clk);
    rst_n = 1'b0;
    repeat (cycles) @(posedge clk);
    @(negedge clk);
    rst_n = 1'b1;
  endtask

  // Fires regardless of what the design does: a faulty unit can stop clk_o.
  initial begin
    #10_000_000;
    $display("RESULT: FAIL (watchdog: no forward progress)");
    $finish;
  end

  // =========================================================================
  // DUT
  // =========================================================================
  logic       en_s;
  logic       tm_s;
  logic [3:0] div_s;
  logic       dv_s;
  logic       ready_o;
  logic       co;
  logic [3:0] cnt_o;

  clk_ratio_div dut (
    .clk_i          (clk),
    .rst_ni         (rst_n),
    .en_i           (en_s),
    .test_mode_en_i (tm_s),
    .div_i          (div_s),
    .div_valid_i    (dv_s),
    .div_ready_o    (ready_o),
    .clk_o          (co),
    .cycl_count_o   (cnt_o)
  );

  // =========================================================================
  // reporting
  // =========================================================================
  int nerr;
  int nprint;

  task automatic fail(input string cl, input string msg);
    nerr = nerr + 1;
    if (nprint < 40) begin
      nprint = nprint + 1;
      $display("FAIL [%0s] t=%0t : %0s", cl, $time, msg);
    end
  endtask

  // =========================================================================
  // Passive edge recorder.  This is the ONLY thing sensitive to clk_o, and it
  // only timestamps -- nothing ever waits on it.
  // =========================================================================
  time ed_t [$];
  bit  ed_v [$];
  bit  rec_en;

  always @(co) begin
    if (rec_en) begin
      ed_t.push_back($time);
      ed_v.push_back(co === 1'b1);
    end
  end

  // H1: div_ready_o is not free-running.  Checked only once div_valid_i has
  // been low for two consecutive cycles, so the cycle in which the offer is
  // withdrawn is never mistaken for a violation.
  int  h1_low_run;
  bit  h1_en;

  always @(posedge clk) begin
    if (!rst_n || dv_s) h1_low_run <= 0;
    else                h1_low_run <= h1_low_run + 1;
    if (rst_n && h1_en && !dv_s && (h1_low_run >= 2) && (ready_o === 1'b1))
      fail("H1", "div_ready_o high while div_valid_i has been low");
  end

  // =========================================================================
  // helpers
  // =========================================================================
  function automatic int per_cyc(input int d);
    return (d < 2) ? 1 : d;               // P3: 0 and 1 are both period 1
  endfunction

  function automatic int per_t(input int d);
    return per_cyc(d) * CLKP;
  endfunction

  function automatic int half_t(input int d);
    return per_cyc(d) * CLKH;             // exact at odd divisors too
  endfunction

  function automatic int first_rise_after(input int base, input time t0);
    int i;
    for (i = base; i < ed_t.size(); i++)
      if (ed_v[i] && (ed_t[i] > t0)) return i;
    return -1;
  endfunction

  function automatic int first_fall_after(input int base, input time t0);
    int i;
    for (i = base; i < ed_t.size(); i++)
      if (!ed_v[i] && (ed_t[i] > t0)) return i;
    return -1;
  endfunction

  function automatic int last_edge_upto(input int base, input time t0);
    int i, k;
    k = -1;
    for (i = base; i < ed_t.size(); i++)
      if (ed_t[i] <= t0) k = i;
    return k;
  endfunction

  task automatic wait_cyc(input int n);
    repeat (n) @(posedge clk);
  endtask

  // =========================================================================
  // The handshake.  H2 is honoured: div_i is held stable while div_valid_i is
  // high, until div_ready_o rises.
  // =========================================================================
  time last_rdy_t;

  task automatic set_div(input int d, input int budget,
                         output bit acc, output int waited);
    int w;
    acc        = 1'b0;
    w          = 0;
    last_rdy_t = 0;
    @(negedge clk);
    div_s = d[3:0];
    dv_s  = 1'b1;
    while (w < budget) begin
      @(posedge clk);
      if (ready_o === 1'b1) begin
        acc        = 1'b1;
        last_rdy_t = $time;
        break;
      end
      w = w + 1;
    end
    @(negedge clk) dv_s = 1'b0;
    waited = w;
  endtask

  // =========================================================================
  // Interval checking.  P1 (period) and P2 (duty), both in TIME.
  // =========================================================================
  task automatic chk_intervals(input int eb, input int d, input bit chk_duty,
                               input string cl_per, input string nm);
    int  i, nrise, gap;
    time prev_rise;
    bit  have_rise;
    nrise     = 0;
    have_rise = 1'b0;
    prev_rise = 0;
    for (i = eb; i < ed_t.size(); i++) begin
      if (ed_v[i]) begin
        if (have_rise) begin
          gap = int'(ed_t[i] - prev_rise);
          if (gap != per_t(d))
            fail(cl_per, $sformatf("%0s: clk_o period %0d ns, expected %0d ns (div %0d)",
                                   nm, gap, per_t(d), d));
        end
        prev_rise = ed_t[i];
        have_rise = 1'b1;
        nrise     = nrise + 1;
      end
      else if (have_rise && chk_duty) begin
        // P2/P4: half the period in TIME.  At odd divisors this is a
        // half-integer number of clk_i cycles and is exact in ns.
        gap = int'(ed_t[i] - prev_rise);
        if (gap != half_t(d))
          fail("P2", $sformatf("%0s: clk_o high for %0d ns, expected %0d ns (div %0d, 50%% duty)",
                               nm, gap, half_t(d), d));
      end
    end
    if (nrise < 3)
      fail(cl_per, $sformatf("%0s: only %0d clk_o rising edge(s) observed at div %0d",
                             nm, nrise, d));
  endtask

  // Settle past any gating, then measure several whole periods.
  task automatic meas_clock(input int d, input string nm);
    int eb;
    wait_cyc(3 * per_cyc(d) + 15);
    eb = ed_t.size();
    wait_cyc(8 * per_cyc(d) + 20);
    chk_intervals(eb, d, (d >= 2), "P1", nm);  // X2: no duty check in pass-through
  endtask

  // C1/C2: sampled at clk_i edges while the output is running.
  task automatic meas_count(input int d, input string nm);
    int i, cur, prev, n;
    bit have_prev;
    have_prev = 1'b0;
    prev      = 0;
    n         = 4 * per_cyc(d) + 12;
    for (i = 0; i < n; i++) begin
      @(posedge clk);
      cur = int'(cnt_o);
      if (d < 2) begin
        if (cur != 0)
          fail("C2", $sformatf("%0s: cycl_count_o=%0d in pass-through, expected 0", nm, cur));
      end
      else begin
        if (cur >= d)
          fail("C1", $sformatf("%0s: cycl_count_o=%0d out of range 0..%0d", nm, cur, d-1));
        else if (have_prev && (cur != ((prev + 1) % d)))
          fail("C1", $sformatf("%0s: cycl_count_o went %0d -> %0d, expected %0d (div %0d)",
                               nm, prev, cur, (prev + 1) % d, d));
        have_prev = 1'b1;
        prev      = cur;
      end
    end
  endtask

  // =========================================================================
  // A change of divisor, with G1's bound and G2.
  // =========================================================================
  task automatic change_div(input int newd, input int oldd, input string nm);
    bit  acc;
    int  w, eb, idx, fidx, lidx, wt, gap, bnd;
    bit  was_high;
    eb = ed_t.size();
    set_div(newd, 300, acc, w);
    if (!acc) begin
      // H4: a request is deferred and then accepted; it is never refused.
      fail("H4", $sformatf("%0s: div_ready_o never rose within 300 cycles for div %0d",
                           nm, newd));
      return;
    end
    if (newd == oldd) return;             // H3 handles the same-value case

    // G1: measured from the cycle div_ready_o rose, NOT from div_valid_i.
    bnd  = 3 * per_t(newd);
    wt   = 0;
    idx  = -1;
    while ((wt < (3 * per_cyc(newd) + 40)) && (idx < 0)) begin
      idx = first_rise_after(eb, last_rdy_t);
      if (idx < 0) begin
        @(posedge clk);
        wt = wt + 1;
      end
    end
    if (idx < 0) begin
      fail("G1", $sformatf("%0s: no clk_o rising edge within %0d ns of div_ready_o (bound %0d ns, div %0d)",
                           nm, (3 * per_cyc(newd) + 40) * CLKP, bnd, newd));
      // G2: an output that stopped HIGH has no rising edge for E1-style checks
      // to see, so it is worth naming separately.
      if (co === 1'b1)
        fail("G2", $sformatf("%0s: clk_o stopped high while gated", nm));
    end
    else begin
      gap = int'(ed_t[idx] - last_rdy_t);
      // Only the BOUND is checked.  A shorter gap is L2's choice and passes.
      if (gap > (bnd + CLKH))
        fail("G1", $sformatf("%0s: gap from div_ready_o to first clk_o rise is %0d ns, bound is %0d ns (3 x period of div %0d)",
                             nm, gap, bnd, newd));
      // G2: if clk_o was high when the change was taken, the high phase in
      // progress may finish, but no longer than half the OLD period.
      lidx = last_edge_upto(eb, last_rdy_t);
      was_high = (lidx >= 0) ? ed_v[lidx] : 1'b0;
      if (was_high) begin
        fidx = first_fall_after(eb, last_rdy_t);
        if (fidx >= 0) begin
          gap = int'(ed_t[fidx] - last_rdy_t);
          if (gap > (half_t(oldd) + CLKP))
            fail("G2", $sformatf("%0s: clk_o stayed high %0d ns after div_ready_o, more than half the old period (%0d ns)",
                                 nm, gap, half_t(oldd)));
        end
      end
    end
  endtask

  // =========================================================================
  // Enable: E1, E2, E3.
  // =========================================================================
  task automatic test_enable(input int d, input string nm);
    int i, eb, nrise, li, ri;
    int hi_w;
    // E3 measures the width of the FINAL high pulse, which is half the period
    // whatever the divisor.  It is deliberately not written as a whole-cycle
    // deadline: at an odd divisor the tail runs past any such grace.
    @(negedge clk) en_s = 1'b0;
    wait_cyc(per_cyc(d) + 6);             // let the pulse in progress finish

    eb = ed_t.size();
    wait_cyc(100);
    nrise = 0;
    for (i = eb; i < ed_t.size(); i++) if (ed_v[i]) nrise = nrise + 1;
    if (nrise != 0)
      fail("E1", $sformatf("%0s: %0d clk_o rising edge(s) in 100 cycles with en_i low",
                           nm, nrise));

    // E3, second obligation: the output is left LOW, which E1 cannot see.
    for (i = 0; i < 40; i++) begin
      @(posedge clk);
      if (co !== 1'b0) begin
        fail("E3", $sformatf("%0s: clk_o not low at rest with en_i low", nm));
        i = 40;
      end
    end

    // E3, first obligation: the last pulse completed at its full width.
    li = ed_t.size() - 1;
    if (li < 1) begin
      fail("E3", $sformatf("%0s: too few clk_o edges recorded to judge the final pulse", nm));
    end
    else if (ed_v[li]) begin
      fail("E3", $sformatf("%0s: the last clk_o edge is a rise -- the output was left high", nm));
    end
    else begin
      ri = li - 1;
      if (!ed_v[ri]) begin
        fail("E3", $sformatf("%0s: two falling edges in a row on clk_o", nm));
      end
      else begin
        hi_w = int'(ed_t[li] - ed_t[ri]);
        if (hi_w != half_t(d))
          fail("E3", $sformatf("%0s: final high pulse %0d ns, expected a full half-period of %0d ns (div %0d)",
                               nm, hi_w, half_t(d), d));
      end
    end

    // E2: resumes at the configured divisor.
    @(negedge clk) en_s = 1'b1;
    meas_clock(d, $sformatf("%0s: after re-enable", nm));
    meas_count(d, $sformatf("%0s: after re-enable", nm));
  endtask

  // =========================================================================
  // Stimulus
  // =========================================================================
  int  sw_list [16];
  int  pr_list [6];
  int  si, pi, pj, cur_div, eb0, i0, w0, nrise0;
  bit  acc0;

  initial begin
    nerr = 0; nprint = 0;
    rec_en = 1'b0; h1_en = 1'b0; h1_low_run = 0;
    en_s = 1'b1; tm_s = 1'b0; div_s = 4'd0; dv_s = 1'b0;
    last_rdy_t = 0;

    sw_list = '{2,3,4,5,6,7,8,9,10,11,12,13,14,15,1,0};
    pr_list = '{0,1,2,3,5,8};

    bfm_reset(6);
    wait_cyc(4);
    rec_en = 1'b1;
    h1_en  = 1'b1;
    wait_cyc(2);

    // ---- after reset the divisor is 0: pass-through (P3, C2) -------------
    cur_div = 0;
    meas_clock(0, "after reset, default divisor");
    meas_count(0, "after reset, default divisor");

    // ---- H1: div_ready_o stays low while nothing is offered --------------
    // (the always-on checker above watches this the whole run; this window is
    // the measured one -- 20 cycles with div_valid_i deasserted)
    wait_cyc(20);

    // ---- P1/P2/P3, C1/C2 across every divisor 0..15 ----------------------
    for (si = 0; si < 16; si++) begin
      change_div(sw_list[si], cur_div, $sformatf("change %0d -> %0d", cur_div, sw_list[si]));
      cur_div = sw_list[si];
      meas_clock(cur_div, $sformatf("steady div %0d", cur_div));
      meas_count(cur_div, $sformatf("steady div %0d", cur_div));
    end

    // ---- H3: a same-value request is granted immediately and does NOT gate
    change_div(4, cur_div, "set up for H3");
    cur_div = 4;
    wait_cyc(3 * per_cyc(4) + 15);
    eb0 = ed_t.size();
    set_div(4, 300, acc0, w0);
    if (!acc0)
      fail("H3", "same-value request never granted");
    else if (w0 != 0)
      fail("H3", $sformatf("same-value request granted after %0d cycles, expected the same cycle", w0));
    wait_cyc(6 * per_cyc(4));
    // "not gated at all": every period across the request is a full period.
    chk_intervals(eb0, 4, 1'b1, "H3", "H3 same-value request");

    // ---- H4: a request during a transition is deferred, not refused ------
    change_div(8, cur_div, "H4 first change");
    cur_div = 8;
    // Offer a second change immediately, while the first is still gating.
    set_div(3, 400, acc0, w0);
    if (!acc0)
      fail("H4", "a change offered during a transition was never accepted");
    else begin
      cur_div = 3;
      // L4: how long the deferral lasts is free; only acceptance is checked.
      meas_clock(3, "H4 deferred change took effect");
      meas_count(3, "H4 deferred change took effect");
    end

    // ---- E1/E2/E3 at an even and an odd divisor --------------------------
    change_div(4, cur_div, "set up for enable test, even");
    cur_div = 4;
    wait_cyc(3 * per_cyc(4) + 15);
    test_enable(4, "enable at div 4");

    change_div(5, cur_div, "set up for enable test, odd");
    cur_div = 5;
    wait_cyc(3 * per_cyc(5) + 15);
    test_enable(5, "enable at div 5");

    // ---- G1 bound across ordered pairs, including the ones that attain it
    for (pi = 0; pi < 6; pi++) begin
      for (pj = 0; pj < 6; pj++) begin
        if (pr_list[pi] != pr_list[pj]) begin
          change_div(pr_list[pi], cur_div, $sformatf("pair setup -> %0d", pr_list[pi]));
          cur_div = pr_list[pi];
          wait_cyc(3 * per_cyc(cur_div) + 15);
          change_div(pr_list[pj], cur_div,
                     $sformatf("pair %0d -> %0d", cur_div, pr_list[pj]));
          cur_div = pr_list[pj];
          wait_cyc(3 * per_cyc(cur_div) + 10);
        end
      end
    end

    // ---- R1/R2 ------------------------------------------------------------
    change_div(4, cur_div, "set up for reset test");
    cur_div = 4;
    meas_clock(4, "before reset");
    eb0 = ed_t.size();
    @(negedge clk) rst_n = 1'b0;
    wait_cyc(20);
    nrise0 = 0;
    for (i0 = eb0; i0 < ed_t.size(); i0++) if (ed_v[i0]) nrise0 = nrise0 + 1;
    if (nrise0 != 0)
      fail("R1", $sformatf("%0d clk_o rising edge(s) while rst_ni was low", nrise0));
    @(negedge clk) rst_n = 1'b1;
    wait_cyc(6);
    // R2: reset restores the DEFAULT divisor, not the last configured one.
    cur_div = 0;
    meas_clock(0, "after reset, R2 default restored");
    meas_count(0, "after reset, R2 default restored");

    // ---- verdict ---------------------------------------------------------
    $display("summary: %0d failure(s); %0d clk_o edges recorded", nerr, ed_t.size());
    if (nerr == 0) $display("RESULT: PASS");
    else           $display("RESULT: FAIL");
    $finish;
  end

endmodule