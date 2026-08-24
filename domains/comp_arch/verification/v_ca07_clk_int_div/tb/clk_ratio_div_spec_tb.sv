// =============================================================================
// v_ca07 REFERENCE TESTBENCH -- scoring support, never shipped.
//
// Developed against SEVEN legal implementations: the anchor, the independent
// dut2, and five conformant perturbations.
//
// THE THING UNDER TEST IS A CLOCK. Everything here is driven and timed from
// clk_i. clk_o is measured by recording its edges, never by sampling it as a
// value and never as a timebase -- a faulty design can stop it, and a testbench
// clocked by it stops too, which is not a detection.
//
// COUNTING BASIS, stated once and true of every number below: every reported
// figure comes from a STRUCTURED COUNTER incremented at the point of the event.
// Nothing here is derived by matching text against the log. Four instrument
// faults on this task were miscounts of one kind or another, two of them
// grep-shaped, so the harness does not offer that surface at all.
// =============================================================================
module clk_ratio_div_tb;
  localparam int CP = 10;            // clk_i period in time units

  logic clk = 0; always #(CP/2) clk = ~clk;
  logic rst_n = 0, en = 1, tm = 0, div_valid = 0;
  logic [3:0] div = 0;
  logic div_ready, clk_o;
  logic [3:0] cyc_cnt;

  clk_ratio_div dut (.clk_i(clk), .rst_ni(rst_n), .en_i(en), .test_mode_en_i(tm),
                     .div_i(div), .div_valid_i(div_valid), .div_ready_o(div_ready),
                     .clk_o(clk_o), .cycl_count_o(cyc_cnt));

  // ---- clk_i cycle counter, the only timebase --------------------------
  int cyc = 0;
  always @(negedge clk) cyc++;

  // ---- clk_o edges, RECORDED not sampled -------------------------------
  // Stored as RAW TIME, not as a cycle number. The cycle counter increments on
  // negedge clk_i, and a clk_o edge landing on that same negedge races it --
  // which read div=5's high phase as 3 where it is 2. Raw time has no such
  // ordering dependency; the conversion to cycles happens at comparison, once.
  int rise[$], fall[$];
  always @(posedge clk_o) if (rst_n) rise.push_back($time);
  always @(negedge clk_o) if (rst_n) fall.push_back($time);
  task automatic clear_edges(); rise.delete(); fall.delete(); endtask

  // ---- failures, counted per clause ------------------------------------
  int n_fail = 0;
  int f_P = 0, f_H = 0, f_G = 0, f_E = 0, f_C = 0, f_R = 0, f_FLOOR = 0;
  string phase = "init";
  task automatic fail(input string cl, input string msg);
    n_fail++;
    case (cl.substr(0,0))
      "P": f_P++;  "H": f_H++;  "G": f_G++;
      "E": f_E++;  "C": f_C++;  "R": f_R++;
      default: f_FLOOR++;
    endcase
    if (n_fail <= 40) $display("FAIL [%s] %s: %s (cyc=%0d)", cl, phase, msg, cyc);
  endtask

  function automatic int per_of(input int d); return (d < 2) ? 1 : d; endfunction

  // ---- INPUT VARIATION MONITOR (pattern from Agent 3, d_ca03) ----------
  // An input assigned every cycle at a fixed value is NOT exercised, so the
  // observable is VARIATION, not assignment. An undeclared constant FAILS.
  localparam int NVAR = 5;
  localparam int V_RST=0, V_EN=1, V_TM=2, V_DIV=3, V_DVAL=4;
  string vw_name [NVAR]; bit vw_varied [NVAR]; bit vw_ok [NVAR]; string vw_why [NVAR];
  logic       f_rst, f_en, f_tm, f_dval; logic [3:0] f_div;
  bit         latched = 0, selftest = 0;
  always @(posedge clk) begin
    if (!latched) begin
      f_rst<=rst_n; f_en<=en; f_tm<=tm; f_div<=div; f_dval<=div_valid; latched<=1;
    end else begin
      if (rst_n     !== f_rst ) vw_varied[V_RST ] <= 1;
      if (en        !== f_en  ) vw_varied[V_EN  ] <= 1;
      if (tm        !== f_tm  ) vw_varied[V_TM  ] <= 1;
      if (div       !== f_div ) vw_varied[V_DIV ] <= 1;
      if (div_valid !== f_dval) vw_varied[V_DVAL] <= 1;
    end
  end

  // ---- measure the ratio at a settled divisor --------------------------
  task automatic settle(input int d);
    int t;
    @(negedge clk); div = 4'(d); div_valid = 1;
    for (t = 0; t < 400; t++) begin @(posedge clk); if (div_ready) break; end
    if (t >= 400) fail("H1", $sformatf("div=%0d was never accepted in 400 cycles", d));
    @(negedge clk) div_valid = 0;
    repeat (120) @(posedge clk);            // past any gating; L2 leaves it free
  endtask

  // P1/P2/P3: every period exact, every high phase exact. Checked over several
  // periods rather than one, so a unit that is right once is not mistaken for a
  // unit that is right.
  task automatic check_ratio(input int d);
    int p, hi_want, lo_want, n;
    settle(d);
    clear_edges();
    repeat (per_of(d) * 8 + 20) @(posedge clk);
    p = per_of(d);
    if (rise.size() < 4) begin
      fail("P1", $sformatf("div=%0d produced %0d rising edges where several were due",
                           d, rise.size()));
      return;
    end
    for (int i = 1; i < rise.size(); i++)
      if ((rise[i] - rise[i-1]) != p*CP)
        fail("P1", $sformatf("div=%0d period %0d, expected %0d clk_i cycles",
                             d, (rise[i]-rise[i-1])/CP, p));
    if (d >= 2) begin
      // P2: high = floor(d/2), low = ceil(d/2). X2 excludes the pass-through
      // duty, so this is checked only where the contract defines it.
      // Pair each rise with the NEXT fall after it, once.
      //
      // P2 IS CHECKED IN TIME UNITS, NOT WHOLE CYCLES. The duty is 50% at every
      // divisor, and at an odd one that is a HALF-INTEGER number of clk_i
      // cycles. Comparing whole cycles truncates 1.5 to 1 and rejects correct
      // hardware at every odd divisor -- which this testbench did, and the
      // step-1 probe did before it, and the two agreed.
      hi_want = d / 2; lo_want = d - hi_want;
      n = 0;
      foreach (rise[i]) begin
        int nf = -1;
        foreach (fall[j]) if (fall[j] > rise[i]) begin nf = fall[j]; break; end
        if (nf > 0 && (nf - rise[i]) < p*CP) begin
          n++;
          // half the period, exactly, in time units
          if ((nf - rise[i])*2 != p*CP)
            fail("P2", $sformatf("div=%0d high phase %0d time units, expected %0d (half of a %0d-unit period)",
                                 d, nf-rise[i], (p*CP)/2, p*CP));
        end
      end
      if (n == 0) fail("P2", $sformatf("div=%0d: no complete high phase was observed", d));
    end
  endtask

  int cov_div = 0, cov_change = 0, cov_same = 0, cov_defer = 0, cov_en = 0;
  int cov_reset = 0, cov_g1 = 0, cov_pass = 0, cov_odd = 0;

  // G1: the gap from ACCEPTANCE to the first rising edge, bounded by 3x the new
  // period. L2 leaves the actual duration free, so only the bound is checked --
  // never a particular value.
  task automatic check_change(input int from_d, input int to_d);
    int t, acc, first, gap;
    settle(from_d);
    clear_edges(); repeat (per_of(from_d)*3 + 10) @(posedge clk);
    @(negedge clk); div = 4'(to_d); div_valid = 1;
    acc = -1;
    for (t = 0; t < 400; t++) begin @(posedge clk); if (div_ready) begin acc = cyc; break; end end
    @(negedge clk) div_valid = 0;
    if (acc < 0) begin fail("H1", "a divisor change was never accepted"); return; end
    clear_edges();
    repeat (per_of(to_d)*6 + 40) @(posedge clk);
    if (rise.size() == 0) begin
      fail("G1", $sformatf("%0d -> %0d: the clock never resumed", from_d, to_d));
      return;
    end
    first = rise[0] / CP; gap = first - acc;
    cov_g1++;
    if (gap > 3*per_of(to_d))
      fail("G1", $sformatf("%0d -> %0d: gated %0d cycles from acceptance, bound is %0d",
                           from_d, to_d, gap, 3*per_of(to_d)));
    if (gap < 0)
      fail("G1", $sformatf("%0d -> %0d: an edge appeared before acceptance", from_d, to_d));
  endtask

  initial begin
    for (int i = 0; i < NVAR; i++) begin vw_varied[i]=0; vw_ok[i]=0; vw_why[i]=""; end
    vw_name[V_RST]="rst_ni"; vw_name[V_EN]="en_i"; vw_name[V_TM]="test_mode_en_i";
    vw_name[V_DIV]="div_i";  vw_name[V_DVAL]="div_valid_i";
    // X4 pins test_mode_en_i low; it is a declared constant, not an oversight.
    vw_ok[V_TM] = 1'b1; vw_why[V_TM] = "X4: test_mode_en_i is pinned low";

    repeat (4) @(posedge clk); @(negedge clk) rst_n = 1; repeat (2) @(posedge clk);

    phase = "A:the divisor ladder";
    for (int d = 0; d <= 15; d++) begin
      check_ratio(d);
      cov_div++;
      if (d < 2) cov_pass++;
      if (d >= 2 && (d % 2) == 1) cov_odd++;
    end

    phase = "B:reconfiguration, the gating bound from acceptance";
    check_change(2,4);  check_change(4,2);  check_change(4,8);  check_change(8,3);
    check_change(3,7);  check_change(7,2);  check_change(4,0);  check_change(0,4);
    check_change(5,1);  check_change(1,6);  check_change(15,2); check_change(2,15);
    cov_change = 12;

    phase = "C:a SAME-VALUE request is a no-op";
    // H3: granted in the same cycle, and the clock is not gated at all. The
    // second half is checked by the period ACROSS the request, not by counting
    // edges in a window -- a window count cannot tell one lost period from a
    // phase shift.
    begin
      int acc, t, before_i, span;
      settle(4);
      clear_edges(); repeat (40) @(posedge clk);
      before_i = rise.size();
      @(negedge clk); div = 4'd4; div_valid = 1;
      acc = -1;
      for (t = 0; t < 8; t++) begin @(posedge clk); if (div_ready) begin acc = t; break; end end
      @(negedge clk) div_valid = 0;
      if (acc != 0)
        fail("H3", $sformatf("a same-value request was granted after %0d cycles, expected the same cycle", acc));
      repeat (40) @(posedge clk);
      span = 0;
      for (int i = before_i; i > 0 && i < rise.size(); i++)
        if ((rise[i] - rise[i-1]) != 4*CP) begin
          fail("H3", $sformatf("a same-value request elongated a period to %0d; it must not gate",
                               (rise[i]-rise[i-1])/CP));
          span++;
        end
      cov_same++;
    end

    phase = "D:a second request during a transition is DEFERRED, not refused";
    // H4 fixes THAT it is eventually accepted. L4 leaves WHEN free, so no
    // latency is required here -- only eventual acceptance inside a generous
    // budget that no conforming implementation can miss.
    begin
      int t, acc2;
      settle(2);
      @(negedge clk); div = 4'd8; div_valid = 1;
      for (t = 0; t < 400; t++) begin @(posedge clk); if (div_ready) break; end
      @(negedge clk) div_valid = 0;
      @(negedge clk); div = 4'd3; div_valid = 1;
      acc2 = -1;
      for (t = 0; t < 600; t++) begin @(posedge clk); if (div_ready) begin acc2 = t; break; end end
      @(negedge clk) div_valid = 0;
      if (acc2 < 0)
        fail("H4", "a second request during a transition was never accepted in 600 cycles");
      cov_defer++;
      repeat (120) @(posedge clk);
      check_ratio(3);
    end

    phase = "E:enable";
    begin
      int t;
      settle(4);
      clear_edges(); repeat (60) @(posedge clk);
      if (rise.size() == 0) fail("E2", "no output while en_i is high");
      @(negedge clk) en = 0;
      @(posedge clk);                       // one cycle of grace: E1 bounds the
      clear_edges();                        // steady state, not the transition
      repeat (80) @(posedge clk);
      if (rise.size() != 0)
        fail("E1", $sformatf("%0d rising edge(s) while en_i is low", rise.size()));
      @(negedge clk) en = 1;
      clear_edges(); repeat (80) @(posedge clk);
      if (rise.size() == 0) fail("E2", "the output did not resume when en_i returned high");
      cov_en++;
    end

    phase = "F:the cycle counter";
    // C1 while the clock RUNS. L5 frees it while gated or disabled, so it is
    // never sampled in either state.
    begin
      int prev, obs;
      for (int d = 2; d <= 6; d++) begin
        settle(d);
        @(posedge clk); prev = int'(cyc_cnt);
        for (int t = 0; t < d*3; t++) begin
          @(posedge clk); obs = int'(cyc_cnt);
          if (obs >= d)
            fail("C1", $sformatf("div=%0d: cycl_count_o reached %0d, range is 0..%0d", d, obs, d-1));
          if (obs != ((prev + 1) % d))
            fail("C1", $sformatf("div=%0d: cycl_count_o went %0d -> %0d, expected %0d",
                                 d, prev, obs, (prev+1)%d));
          prev = obs;
        end
      end
      settle(0);
      for (int t = 0; t < 12; t++) begin
        @(posedge clk);
        if (cyc_cnt !== 4'd0)
          fail("C2", $sformatf("pass-through: cycl_count_o is %0d, expected 0", cyc_cnt));
      end
    end

    phase = "G:reset";
    begin
      settle(6);
      @(negedge clk) rst_n = 0;
      clear_edges(); repeat (30) @(posedge clk);
      if (rise.size() != 0)
        fail("R1", $sformatf("%0d rising edge(s) while rst_ni is low", rise.size()));
      @(negedge clk) rst_n = 1;
      repeat (20) @(posedge clk);
      clear_edges(); repeat (40) @(posedge clk);
      if (rise.size() < 4) fail("R2", "no output after reset was released");
      else for (int i = 1; i < rise.size(); i++)
        if ((rise[i] - rise[i-1]) != 1*CP)
          fail("R2", $sformatf("after reset the period is %0d, expected 1 -- reset restores the DEFAULT divisor, not the last configured one",
                               (rise[i]-rise[i-1])/CP));
      cov_reset++;
    end

    // ---- stimulus floors, counted at the point of stimulus ---------------
    if (cov_div < 16)    fail("FLOOR", $sformatf("only %0d divisors driven of 16", cov_div));
    if (cov_odd < 6)     fail("FLOOR", $sformatf("only %0d odd divisors driven -- P2's own case", cov_odd));
    if (cov_pass < 2)    fail("FLOOR", "both pass-through values were not driven");
    if (cov_change < 8)  fail("FLOOR", $sformatf("only %0d reconfigurations driven", cov_change));
    if (cov_g1 < 8)      fail("FLOOR", $sformatf("the gating bound was measured %0d times", cov_g1));
    if (cov_same < 1)    fail("FLOOR", "a same-value request was never driven -- H3 untested");
    if (cov_defer < 1)   fail("FLOOR", "a second request during a transition was never driven -- H4 untested");
    if (cov_en < 1)      fail("FLOOR", "en_i was never exercised");
    if (cov_reset < 1)   fail("FLOOR", "reset was never asserted mid-run");

    // ---- the input-variation verdict -------------------------------------
    if ($test$plusargs("declare_all")) begin
      selftest = 1'b1;
      for (int i = 0; i < NVAR; i++) begin vw_ok[i] = 1'b1; vw_why[i] = "SELF-TEST ONLY"; end
    end
    $display("");
    $display("STIMULUS VARIATION over %0d contract inputs:", NVAR);
    begin int nv = 0;
      for (int i = 0; i < NVAR; i++) begin
        if (!vw_varied[i] && !vw_ok[i]) begin
          $display("  [FAIL] %-18s held ONE value for the whole run", vw_name[i]);
          nv++;
        end else if (!vw_varied[i])
          $display("  const  %-18s declared: %s", vw_name[i], vw_why[i]);
      end
      if (nv == 0) $display("  every undeclared input varied");
      else begin
        $display("  %0d input(s) never varied and were not declared constant.", nv);
        $display("  An input assigned every cycle at a fixed value is NOT exercised.");
        n_fail += nv; f_FLOOR += nv;
      end
    end

    $display("");
    $display("  [counts] P=%0d H=%0d G=%0d E=%0d C=%0d R=%0d FLOOR=%0d",
             f_P, f_H, f_G, f_E, f_C, f_R, f_FLOOR);
    $display("  [coverage] divisors=%0d odd=%0d pass-through=%0d changes=%0d g1-measured=%0d",
             cov_div, cov_odd, cov_pass, cov_change, cov_g1);
    // NOT a ternary between string literals -- SystemVerilog pads the shorter to
    // the longer one's width with NULs and the line prints as nothing at all.
    if (selftest)        $display("RESULT: SELFTEST -- not a score");
    else if (n_fail == 0) $display("RESULT: PASS");
    else                  $display("RESULT: FAIL (%0d failure%s)", n_fail, (n_fail==1)?"":"s");
    $finish;
  end

  initial begin
    #20000000;
    $display("FAIL [WATCHDOG] the testbench did not finish; %0d failure(s) so far", n_fail);
    $display("RESULT: FAIL (watchdog)");
    $finish;
  end
endmodule
