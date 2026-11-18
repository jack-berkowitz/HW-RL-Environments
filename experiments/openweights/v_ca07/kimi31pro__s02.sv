`timescale 1ns/1ps

// Testbench for the clk_ratio_div port map and specification supplied above.
module id_width_conv_tb;

  localparam time CLK_PERIOD = 10;
  localparam time CLK_HALF   = 5;

  logic       clk_i;
  logic       rst_ni;
  logic       en_i;
  logic       test_mode_en_i;
  logic [3:0] div_i;
  logic       div_valid_i;
  logic       div_ready_o;
  logic       clk_o;
  logic [3:0] cycl_count_o;

  clk_ratio_div dut (
    .clk_i          (clk_i),
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
    clk_i = 1'b0;
    forever #5 clk_i = ~clk_i;
  end

  int error_count;
  int current_div;

  // Edge timestamps are the primary measurements.  The testbench never uses
  // clk_o as a clock and never infers its period from sampled values.
  time rise_times[$];
  time fall_times[$];

  // Samples are used only for level checks such as G2 and the low-at-rest
  // portion of E3, never for period or duty measurement.
  time  sample_times[$];
  logic sample_values[$];

  always @(posedge clk_o)
    rise_times.push_back($time);

  always @(negedge clk_o)
    fall_times.push_back($time);

  always @(posedge clk_i or negedge clk_i) begin
    sample_times.push_back($time);
    sample_values.push_back(clk_o);
  end

  task automatic report_fail(input string req, input string detail);
    begin
      error_count = error_count + 1;
      $display("FAIL %s: %s", req, detail);
    end
  endtask

  task automatic bfm_reset(input int cycles = 4);
    begin
      @(negedge clk_i);
      rst_ni = 1'b0;
      repeat (cycles) @(posedge clk_i);
      @(negedge clk_i);
      rst_ni = 1'b1;
    end
  endtask

  // Find the first recorded rise strictly later than origin.  Polling is
  // timed exclusively by clk_i and is bounded even if clk_o stops.
  task automatic wait_rise_after(
    input  time origin,
    input  int  budget,
    output bit  found,
    output time stamp
  );
    automatic int waited;
    automatic int k;
    begin
      found  = 1'b0;
      stamp  = 0;
      waited = 0;
      while (!found && waited <= budget) begin
        for (k = 0; k < rise_times.size(); k = k + 1) begin
          if (rise_times[k] > origin) begin
            found = 1'b1;
            stamp = rise_times[k];
            break;
          end
        end
        if (!found) begin
          @(posedge clk_i);
          waited = waited + 1;
        end
      end
    end
  endtask

  task automatic wait_fall_after(
    input  time origin,
    input  int  budget,
    output bit  found,
    output time stamp
  );
    automatic int waited;
    automatic int k;
    begin
      found  = 1'b0;
      stamp  = 0;
      waited = 0;
      while (!found && waited <= budget) begin
        for (k = 0; k < fall_times.size(); k = k + 1) begin
          if (fall_times[k] > origin) begin
            found = 1'b1;
            stamp = fall_times[k];
            break;
          end
        end
        if (!found) begin
          @(posedge clk_i);
          waited = waited + 1;
        end
      end
    end
  endtask

  task automatic latest_rise_at_or_before(
    input  time limit_time,
    output bit  found,
    output time stamp
  );
    automatic int k;
    begin
      found = 1'b0;
      stamp = 0;
      for (k = 0; k < rise_times.size(); k = k + 1) begin
        if (rise_times[k] <= limit_time) begin
          found = 1'b1;
          stamp = rise_times[k];
        end
      end
    end
  endtask

  // Offer one divisor and hold it stable until acceptance, satisfying H2.
  task automatic request_div(
    input  logic [3:0] target,
    input  int         budget,
    output bit         accepted,
    output int         waited,
    output time        valid_time,
    output time        ready_time
  );
    begin
      accepted   = 1'b0;
      waited     = 0;
      valid_time = 0;
      ready_time = 0;

      @(negedge clk_i);
      div_i       = target;
      div_valid_i = 1'b1;
      valid_time  = $time;

      while (waited < budget && !accepted) begin
        @(posedge clk_i);
        if (div_ready_o === 1'b1) begin
          accepted   = 1'b1;
          ready_time = $time;
        end else begin
          waited = waited + 1;
        end
      end

      @(negedge clk_i);
      div_valid_i = 1'b0;
    end
  endtask

  task automatic check_ready_low;
    automatic int k;
    automatic bit bad;
    begin
      bad = 1'b0;
      for (k = 0; k < 20; k = k + 1) begin
        @(posedge clk_i);
        if (div_ready_o !== 1'b0)
          bad = 1'b1;
      end
      if (bad)
        report_fail("H1", "div_ready_o was not low across 20 cycles with div_valid_i low");
    end
  endtask

  task automatic check_low_samples(
    input time   start_time,
    input time   end_time,
    input bit    include_end,
    input string req
  );
    automatic int  k;
    automatic bit  bad;
    automatic time bad_time;
    begin
      bad      = 1'b0;
      bad_time = 0;
      for (k = 0; k < sample_times.size(); k = k + 1) begin
        if (sample_times[k] > start_time &&
            ((include_end && sample_times[k] <= end_time) ||
             (!include_end && sample_times[k] < end_time))) begin
          if (!bad && sample_values[k] !== 1'b0) begin
            bad      = 1'b1;
            bad_time = sample_times[k];
          end
        end
      end
      if (bad)
        report_fail(req, $sformatf("clk_o was not low at %0t", bad_time));
    end
  endtask

  // Check the counter only while the output clock is running.  No value is
  // required while gated or disabled (L5).
  task automatic check_counter(
    input int d,
    input int cycles,
    input bit fresh_change
  );
    automatic logic [3:0] prev;
    automatic logic [3:0] cur;
    automatic int         k;
    automatic int         expected;
    automatic bit         bad;
    begin
      bad = 1'b0;

      if (d <= 1) begin
        for (k = 0; k < cycles; k = k + 1) begin
          @(negedge clk_i);
          if (!bad && cycl_count_o !== 4'd0) begin
            bad = 1'b1;
            report_fail("C2",
              $sformatf("cycl_count_o=%0d in pass-through", cycl_count_o));
          end
        end
      end else begin
        @(negedge clk_i);
        prev = cycl_count_o;
        if (prev >= d) begin
          bad = 1'b1;
          report_fail("C1",
            $sformatf("counter value %0d outside 0..%0d", prev, d-1));
          if (fresh_change)
            report_fail("C3", "counter did not enter the new divisor range");
        end

        for (k = 0; k < cycles; k = k + 1) begin
          @(negedge clk_i);
          cur = cycl_count_o;
          if (prev + 1 >= d)
            expected = 0;
          else
            expected = prev + 1;

          if (!bad && cur !== expected[3:0]) begin
            bad = 1'b1;
            report_fail("C1",
              $sformatf("counter advanced %0d -> %0d, expected %0d at div %0d",
                        prev, cur, expected, d));
            if (fresh_change)
              report_fail("C3", "counter retained a partial old-divisor cycle");
          end
          prev = cur;
        end
      end
    end
  endtask

  // Measure raw intervals between edges.  For d>=2, both phases must be
  // exactly d*5 ns.  Pass-through deliberately has no duty check (X2).
  task automatic check_running_from(
    input time   first_rise,
    input int    d,
    input int    periods,
    input string period_req,
    input string duty_req
  );
    automatic time r0;
    automatic time f0;
    automatic time r1;
    automatic bit  ok;
    automatic int  p;
    automatic int  budget;
    begin
      r0     = first_rise;
      budget = 4 * ((d <= 1) ? 1 : d) + 20;

      for (p = 0; p < periods; p = p + 1) begin
        if (d <= 1) begin
          wait_rise_after(r0, budget, ok, r1);
          if (!ok) begin
            report_fail(period_req, "no subsequent rising edge in pass-through");
            return;
          end
          if (r1 - r0 != CLK_PERIOD)
            report_fail(period_req,
              $sformatf("pass-through period %0t, expected %0t",
                        r1-r0, CLK_PERIOD));
          r0 = r1;
        end else begin
          wait_fall_after(r0, budget, ok, f0);
          if (!ok) begin
            report_fail(duty_req,
              $sformatf("no falling edge after rise at %0t, div %0d", r0, d));
            return;
          end

          if (f0 - r0 != d * CLK_HALF)
            report_fail(duty_req,
              $sformatf("high phase %0t at div %0d, expected %0t",
                        f0-r0, d, d*CLK_HALF));

          wait_rise_after(f0, budget, ok, r1);
          if (!ok) begin
            report_fail(period_req,
              $sformatf("no next rising edge after fall at %0t, div %0d",
                        f0, d));
            return;
          end

          if (r1 - f0 != d * CLK_HALF)
            report_fail(duty_req,
              $sformatf("low phase %0t at div %0d, expected %0t",
                        r1-f0, d, d*CLK_HALF));

          if (r1 - r0 != d * CLK_PERIOD)
            report_fail(period_req,
              $sformatf("period %0t at div %0d, expected %0t",
                        r1-r0, d, d*CLK_PERIOD));

          r0 = r1;
        end
      end
    end
  endtask

  // A real change: check G1 from div_ready_o, not from div_valid_i.  No
  // particular gating duration below the bound is required.
  task automatic do_change(input int target);
    automatic bit  accepted;
    automatic bit  found;
    automatic int  waited;
    automatic int  period_cycles;
    automatic time valid_time;
    automatic time ready_time;
    automatic time resume_time;
    automatic time gap;
    begin
      period_cycles = (target <= 1) ? 1 : target;
      request_div(target[3:0], 100, accepted, waited,
                  valid_time, ready_time);

      if (!accepted) begin
        report_fail("H1",
          $sformatf("change to divisor %0d was not accepted", target));
        return;
      end

      // Extra timeout slack merely permits detection and diagnosis of an
      // over-bound edge.  The contractual comparison below is exact.
      wait_rise_after(ready_time, 3*period_cycles + 8,
                      found, resume_time);

      if (!found) begin
        report_fail("G1",
          $sformatf("no rising edge within the bound after change to %0d",
                    target));
        check_low_samples(ready_time, $time, 1'b1, "G2");
        return;
      end

      gap = resume_time - ready_time;
      if (gap > 3 * period_cycles * CLK_PERIOD)
        report_fail("G1",
          $sformatf("gap from ready %0t at div %0d, bound %0t",
                    gap, target, 3*period_cycles*CLK_PERIOD));

      check_low_samples(ready_time, resume_time, 1'b0, "G2");

      // Do this immediately after resumption; edge checks below use the
      // historical timestamp log and therefore remain valid.
      check_counter(target, (target <= 1) ? 6 : 2*target+4, 1'b1);

      if (target <= 1)
        check_running_from(resume_time, target, 2, "P3", "P3");
      else
        check_running_from(resume_time, target, 2, "P1", "P2");
    end
  endtask

  task automatic check_same_value(input int d);
    automatic bit  accepted;
    automatic bit  anchor_ok;
    automatic int  waited;
    automatic time valid_time;
    automatic time ready_time;
    automatic time anchor;
    begin
      latest_rise_at_or_before($time, anchor_ok, anchor);
      request_div(d[3:0], 30, accepted, waited, valid_time, ready_time);

      if (!accepted)
        report_fail("H3",
          $sformatf("same-value request at divisor %0d was not granted", d));
      else if (waited != 0)
        report_fail("H3",
          $sformatf("same-value request at divisor %0d waited %0d cycles",
                    d, waited));

      // Starting before the offer makes any inserted gating visible as a
      // malformed interval, including gating that ends after acceptance.
      if (anchor_ok)
        check_running_from(anchor, d, 3, "H3", "H3");
      else
        report_fail("H3", "no output edge available before same-value request");
    end
  endtask

  task automatic check_deferred_request;
    automatic bit  accepted1;
    automatic bit  accepted2;
    automatic bit  found;
    automatic int  waited1;
    automatic int  waited2;
    automatic time valid1;
    automatic time valid2;
    automatic time ready1;
    automatic time ready2;
    automatic time resume_time;
    automatic time gap;
    begin
      // Start an uncontended 4 -> 8 change.
      request_div(4'd8, 100, accepted1, waited1, valid1, ready1);
      if (!accepted1) begin
        report_fail("H1", "first request in deferral test was not accepted");
        return;
      end

      // Offer 3 while the first change is still in its gating interval, and
      // keep the offer asserted without re-offering it.
      request_div(4'd3, 200, accepted2, waited2, valid2, ready2);
      if (!accepted2) begin
        report_fail("H4", "request offered during a transition was not accepted");
        return;
      end

      // L4 fixes no deferral duration, so waited2 is deliberately not checked.
      wait_rise_after(ready2, 3*3 + 8, found, resume_time);
      if (!found) begin
        report_fail("G1", "no resumed clock after deferred change to divisor 3");
        return;
      end

      gap = resume_time - ready2;
      if (gap > 3 * 3 * CLK_PERIOD)
        report_fail("G1",
          $sformatf("deferred-change gap %0t exceeds %0t",
                    gap, 3*3*CLK_PERIOD));

      check_low_samples(ready2, resume_time, 1'b0, "G2");
      check_counter(3, 10, 1'b1);
      check_running_from(resume_time, 3, 2, "P1", "P2");
    end
  endtask

  task automatic check_enable(input int d);
    automatic bit  ok;
    automatic bit  fall_ok;
    automatic bit  high_seen;
    automatic bit  rise_seen;
    automatic int  attempts;
    automatic int  k;
    automatic time origin;
    automatic time rise_time;
    automatic time fall_time;
    automatic time disable_time;
    automatic time enable_time;
    automatic time end_time;
    automatic time rest_start;
    begin
      // Synchronize to a high pulse so E3 tests the final pulse width rather
      // than imposing a whole-cycle deadline after en_i falls.
      high_seen = 1'b0;
      attempts  = 0;
      origin    = $time;
      rise_time = 0;

      while (!high_seen && attempts < 3) begin
        wait_rise_after(origin, 4*d+20, ok, rise_time);
        if (!ok) begin
          report_fail("E1", "output was not running before disable test");
          return;
        end
        @(negedge clk_i);
        if (clk_o === 1'b1)
          high_seen = 1'b1;
        else
          origin = rise_time;
        attempts = attempts + 1;
      end

      if (!high_seen) begin
        report_fail("E3", "could not observe a high pulse before disabling");
        return;
      end

      disable_time = $time;
      en_i = 1'b0;

      wait_fall_after(rise_time, 4*d+20, fall_ok, fall_time);
      if (!fall_ok) begin
        report_fail("E3", "final high pulse did not complete after disable");
        rest_start = disable_time;
      end else begin
        if (fall_time - rise_time != d * CLK_HALF)
          report_fail("E3",
            $sformatf("final high pulse %0t at div %0d, expected %0t",
                      fall_time-rise_time, d, d*CLK_HALF));
        rest_start = fall_time;
      end

      // E1: remain disabled for 100 input cycles.  This also supplies ample
      // input-edge samples for the low-at-rest half of E3.
      repeat (100) @(posedge clk_i);
      end_time = $time;

      rise_seen = 1'b0;
      for (k = 0; k < rise_times.size(); k = k + 1) begin
        if (rise_times[k] > disable_time && rise_times[k] <= end_time)
          rise_seen = 1'b1;
      end
      if (rise_seen)
        report_fail("E1", "rising edge occurred while en_i was low");

      check_low_samples(rest_start, end_time, 1'b1, "E3");

      @(negedge clk_i);
      en_i        = 1'b1;
      enable_time = $time;

      wait_rise_after(enable_time, 10*d+50, ok, rise_time);
      if (!ok) begin
        report_fail("E2",
          $sformatf("output did not resume at divisor %0d", d));
        return;
      end

      check_counter(d, 2*d+4, 1'b0);
      check_running_from(rise_time, d, 2, "E2", "E2");
    end
  endtask

  task automatic check_reset_behavior;
    automatic time check_origin;
    automatic time end_time;
    automatic time release_time;
    automatic time rise_time;
    automatic bit  rise_seen;
    automatic bit  ok;
    automatic int  k;
    begin
      // div_i intentionally remains at the previously configured value.
      @(negedge clk_i);
      rst_ni       = 1'b0;
      div_valid_i  = 1'b0;

      // X1 excludes only the interval before the first input edge.
      @(posedge clk_i);
      check_origin = $time;
      repeat (4) @(posedge clk_i);
      @(negedge clk_i);
      end_time = $time;

      rise_seen = 1'b0;
      for (k = 0; k < rise_times.size(); k = k + 1) begin
        if (rise_times[k] >= check_origin && rise_times[k] <= end_time)
          rise_seen = 1'b1;
      end
      if (rise_seen)
        report_fail("R1", "rising edge occurred while rst_ni was low");

      rst_ni       = 1'b1;
      release_time = $time;

      wait_rise_after(release_time, 40, ok, rise_time);
      if (!ok) begin
        report_fail("R2", "no output clock after reset release");
        return;
      end

      // The pre-reset configuration was divisor 4; period one proves that
      // reset restored the default rather than retaining that configuration.
      check_running_from(rise_time, 0, 3, "R2", "R2");
      check_counter(0, 8, 1'b0);
    end
  endtask

  task automatic run_suite;
    automatic int  d;
    automatic int  from_div;
    automatic int  to_div;
    automatic bit  ok;
    automatic time first_rise;
    begin
      current_div = 0;

      check_ready_low();

      wait_rise_after($time, 40, ok, first_rise);
      if (!ok)
        report_fail("P3", "no pass-through clock after initial reset");
      else
        check_running_from(first_rise, 0, 3, "P3", "P3");

      check_counter(0, 8, 1'b0);
      check_same_value(0);

      // Steady-state period, duty and counter checks over the whole port range.
      for (d = 1; d <= 15; d = d + 1) begin
        do_change(d);
        current_div = d;
        if (d == 5)
          check_same_value(5);
      end

      // Every ordered change in the range for which G1 was characterized.
      for (from_div = 0; from_div <= 8; from_div = from_div + 1) begin
        for (to_div = 0; to_div <= 8; to_div = to_div + 1) begin
          if (to_div != from_div) begin
            if (current_div != from_div) begin
              do_change(from_div);
              current_div = from_div;
            end
            do_change(to_div);
            current_div = to_div;
          end
        end
      end

      if (current_div != 4) begin
        do_change(4);
        current_div = 4;
      end
      check_same_value(4);

      // Directed new-range counter transition, followed by deferral.
      do_change(8);
      current_div = 8;
      do_change(4);
      current_div = 4;
      check_deferred_request();
      current_div = 3;

      do_change(4);
      current_div = 4;
      check_enable(4);

      do_change(5);
      current_div = 5;
      check_enable(5);

      // R2 specifically starts from a configured, non-default divisor.
      do_change(4);
      current_div = 4;
      check_reset_behavior();
      current_div = 0;

      check_ready_low();
    end
  endtask

  initial begin : main_process
    error_count    = 0;
    current_div    = 0;
    rst_ni         = 1'b0;
    en_i           = 1'b1;
    test_mode_en_i = 1'b0;
    div_i          = 4'd0;
    div_valid_i    = 1'b0;

    bfm_reset(4);
    run_suite();

    if (error_count == 0)
      $display("RESULT: PASS");
    else
      $display("RESULT: FAIL");
    $finish;
  end

  // Independent of clk_o and of all DUT handshake progress.
  initial begin
    #4_000_000;
    $display("FAIL WATCHDOG: testbench time limit expired");
    $display("RESULT: FAIL");
    $finish;
  end

endmodule
