`timescale 1ns/1ps

module id_width_conv_tb;

  localparam int CLK_PERIOD = 10;

  logic       clk_i;
  logic       rst_ni;
  logic       en_i;
  logic       test_mode_en_i;
  logic [3:0] div_i;
  logic       div_valid_i;
  logic       div_ready_o;
  logic       clk_o;
  logic [3:0] cycl_count_o;

  int errors;
  int current_div;
  int d;
  int a;
  int b;

  // Edge timestamps are used for all clock-period and duty-cycle checks.
  longint clk_o_times[$];
  bit     clk_o_values[$];

  longint ready_rise_times[$];

  // Counter history permits C3 to be checked from the first running cycle,
  // without sampling the counter while it is gated (which L5 leaves free).
  longint     count_times[$];
  logic [3:0] count_values[$];

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

  always @(clk_o) begin
    if ((clk_o === 1'b0) || (clk_o === 1'b1)) begin
      clk_o_times.push_back($time);
      clk_o_values.push_back(clk_o);
    end
  end

  always @(posedge div_ready_o) begin
    ready_rise_times.push_back($time);
  end

  always @(negedge clk_i) begin
    if (!$isunknown(cycl_count_o)) begin
      count_times.push_back($time);
      count_values.push_back(cycl_count_o);
    end
  end

  task automatic fail(input string req, input string msg);
    begin
      errors = errors + 1;
      $display("%s: %s (time %0t)", req, msg, $time);
    end
  endtask

  // Check complete periods whose endpoints lie in [t0,t1].  In particular,
  // high and low widths are compared as raw timestamps, never as counts of
  // clk_i rising edges.  Pass-through deliberately has no duty check (X2).
  task automatic analyze_window(
    input int      divisor,
    input longint  t0,
    input longint  t1,
    input int      min_periods,
    input string   ctx,
    input string   period_req
  );
    int per;
    int i;
    int k;
    int ri;
    int ni;
    longint period_measured;
    longint high_measured;
    longint low_measured;
    longint half_expected;
    bit period_bad;
    bit duty_bad;
    longint rise_times[$];
    int rise_indices[$];
    begin
      per = (divisor < 2) ? 1 : divisor;
      period_bad = 1'b0;
      duty_bad = 1'b0;

      for (i = 0; i < clk_o_times.size(); i = i + 1) begin
        if ((clk_o_times[i] >= t0) &&
            (clk_o_times[i] <= t1) &&
            (clk_o_values[i] == 1'b1)) begin
          rise_times.push_back(clk_o_times[i]);
          rise_indices.push_back(i);
        end
      end

      if (rise_times.size() < (min_periods + 1)) begin
        fail(period_req,
             $sformatf("%s: found only %0d rising edges, need at least %0d",
                       ctx, rise_times.size(), min_periods + 1));
      end
      else begin
        for (k = 0; k < min_periods; k = k + 1) begin
          period_measured = rise_times[k+1] - rise_times[k];
          if (period_measured != (per * CLK_PERIOD)) begin
            period_bad = 1'b1;
          end

          if (divisor >= 2) begin
            ri = rise_indices[k];
            ni = rise_indices[k+1];

            // A normal period consists of exactly one rise, one fall, and
            // the next rise.  This also detects extra or runt pulses.
            if ((ni != (ri + 2)) ||
                (clk_o_values[ri+1] != 1'b0)) begin
              duty_bad = 1'b1;
            end
            else begin
              high_measured = clk_o_times[ri+1] - clk_o_times[ri];
              low_measured  = clk_o_times[ni]   - clk_o_times[ri+1];
              half_expected = (per * CLK_PERIOD) / 2;
              if ((high_measured != half_expected) ||
                  (low_measured  != half_expected)) begin
                duty_bad = 1'b1;
              end
            end
          end
        end

        if (period_bad) begin
          fail(period_req,
               $sformatf("%s: clk_o period is not %0d clk_i cycles",
                         ctx, per));
        end
        if (duty_bad) begin
          fail("P2",
               $sformatf("%s: high/low phases are not each half the period",
                         ctx));
        end
      end
    end
  endtask

  task automatic measure_running(
    input int     divisor,
    input int     min_periods,
    input string  ctx,
    input string  period_req
  );
    int per;
    int wait_cycles;
    longint t0;
    longint t1;
    begin
      per = (divisor < 2) ? 1 : divisor;
      wait_cycles = ((min_periods + 2) * per) + 4;
      t0 = $time;
      repeat (wait_cycles) @(posedge clk_i);
      @(negedge clk_i);
      // Exclude the most recent input cycle so that an output event
      // coincident with the sampling edge cannot race this analysis.
      t1 = $time - CLK_PERIOD;
      analyze_window(divisor, t0, t1, min_periods, ctx, period_req);
    end
  endtask

  task automatic check_counter_live(
    input int    divisor,
    input int    cycles,
    input string ctx
  );
    int i;
    int per;
    logic [3:0] prev;
    logic [3:0] cur;
    logic [3:0] next_count;
    bit bad;
    begin
      per = (divisor < 2) ? 1 : divisor;
      bad = 1'b0;
      prev = 4'd0;
      cur = 4'd0;
      next_count = 4'd0;

      if (divisor < 2) begin
        for (i = 0; i < cycles; i = i + 1) begin
          @(negedge clk_i);
          if (cycl_count_o !== 4'd0) begin
            bad = 1'b1;
          end
        end
        if (bad) begin
          fail("C2", {ctx, ": cycl_count_o is nonzero in pass-through"});
        end
      end
      else begin
        @(negedge clk_i);
        prev = cycl_count_o;
        if (prev >= divisor) begin
          bad = 1'b1;
        end

        for (i = 0; i < cycles; i = i + 1) begin
          @(negedge clk_i);
          cur = cycl_count_o;
          next_count = (prev + 1) % divisor;
          if ((cur >= divisor) || (cur !== next_count)) begin
            bad = 1'b1;
          end
          prev = cur;
        end

        if (bad) begin
          fail("C1",
               $sformatf("%s: counter does not increment modulo %0d",
                         ctx, per));
        end
      end
    end
  endtask

  // Check the new modulus starting with the first counter sample after the
  // output resumes.  Nothing is required of samples before that resume (L5).
  task automatic check_counter_history(
    input int     divisor,
    input longint resume_time,
    input string  ctx
  );
    int i;
    int per;
    int wanted;
    int seen;
    longint t_end;
    logic [3:0] prev;
    logic [3:0] cur;
    logic [3:0] next_count;
    bit have_prev;
    bit bad;
    begin
      per = (divisor < 2) ? 1 : divisor;
      wanted = (2 * per) + 4;
      t_end = resume_time + ((wanted + 3) * CLK_PERIOD);
      seen = 0;
      have_prev = 1'b0;
      bad = 1'b0;
      prev = 4'd0;
      cur = 4'd0;
      next_count = 4'd0;

      for (i = 0; i < count_times.size(); i = i + 1) begin
        if ((count_times[i] > resume_time) &&
            (count_times[i] <= t_end) &&
            (seen < wanted)) begin
          cur = count_values[i];
          seen = seen + 1;

          if (divisor < 2) begin
            if (cur !== 4'd0) begin
              bad = 1'b1;
            end
          end
          else begin
            if (cur >= divisor) begin
              bad = 1'b1;
            end
            if (have_prev) begin
              next_count = (prev + 1) % divisor;
              if (cur !== next_count) begin
                bad = 1'b1;
              end
            end
            prev = cur;
            have_prev = 1'b1;
          end
        end
      end

      if (bad) begin
        if (divisor < 2) begin
          fail("C2", {ctx, ": pass-through counter is not constantly zero"});
        end
        else begin
          fail("C3",
               $sformatf("%s: counter did not immediately count modulo %0d",
                         ctx, divisor));
        end
      end
    end
  endtask

  // Offer a divisor and obey H2: the value remains stable until acceptance.
  // The task is bounded entirely by clk_i and never waits for a clk_o edge.
  task automatic offer_div(
    input  int     new_divisor,
    input  int     budget,
    output bit     accepted,
    output int     waited,
    output longint accept_time
  );
    longint offer_time;
    longint cycle_time;
    longint now_time;
    int i;
    bit seen;
    begin
      accepted = 1'b0;
      waited = 0;
      accept_time = 0;

      @(negedge clk_i);
      div_i = new_divisor;
      div_valid_i = 1'b1;
      offer_time = $time;

      while ((waited < budget) && !accepted) begin
        @(posedge clk_i);
        cycle_time = $time;
        @(negedge clk_i);
        now_time = $time;

        seen = 1'b0;
        for (i = 0; i < ready_rise_times.size(); i = i + 1) begin
          if (!seen &&
              (ready_rise_times[i] >= offer_time) &&
              (ready_rise_times[i] <= now_time)) begin
            accept_time = ready_rise_times[i];
            seen = 1'b1;
          end
        end

        if (seen || (div_ready_o === 1'b1)) begin
          accepted = 1'b1;
          if (!seen) begin
            accept_time = cycle_time;
          end
        end
        else begin
          waited = waited + 1;
        end
      end

      // Still at a negedge, opposite to the design's sampling edge.
      div_valid_i = 1'b0;
    end
  endtask

  // Complete a real divisor change.  G1 uses the actual ready-rise timestamp,
  // not the earlier valid assertion.  No particular gating duration is
  // required below the bound.
  task automatic finish_change(
    input int     new_divisor,
    input longint accept_time,
    input string  ctx
  );
    int per;
    int i;
    int first_index;
    longint first_rise;
    longint limit;
    longint t1;
    bit found;
    bit gating_bad;
    begin
      per = (new_divisor < 2) ? 1 : new_divisor;
      limit = 3 * per * CLK_PERIOD;

      repeat ((3 * per) + 5) @(posedge clk_i);
      @(negedge clk_i);

      found = 1'b0;
      first_rise = 0;
      first_index = -1;
      for (i = 0; i < clk_o_times.size(); i = i + 1) begin
        if (!found &&
            (clk_o_values[i] == 1'b1) &&
            (clk_o_times[i] > accept_time)) begin
          found = 1'b1;
          first_rise = clk_o_times[i];
          first_index = i;
        end
      end

      if (!found) begin
        fail("G1", {ctx, ": no rising edge resumed after acceptance"});
        if (clk_o === 1'b1) begin
          fail("G2", {ctx, ": output stopped high instead of idling low"});
        end
      end
      else begin
        if ((first_rise - accept_time) > limit) begin
          fail("G1",
               $sformatf("%s: gap %0d exceeds bound %0d measured from ready",
                         ctx, first_rise - accept_time, limit));
        end

        // Once a real change is accepted, gating must not consist of a
        // stopped-high interval or other activity before the new clock rises.
        gating_bad = 1'b0;
        for (i = 0; i < clk_o_times.size(); i = i + 1) begin
          if ((clk_o_times[i] > accept_time) &&
              (clk_o_times[i] < first_rise)) begin
            gating_bad = 1'b1;
          end
        end
        if (gating_bad) begin
          fail("G2", {ctx, ": clk_o was not idle low throughout gating"});
        end

        // Include the first resumed pulse, so a malformed resume cannot be
        // hidden by measuring only later steady-state periods.
        repeat (((4 + 2) * per) + 4) @(posedge clk_i);
        @(negedge clk_i);
        t1 = $time - CLK_PERIOD;
        analyze_window(new_divisor, first_rise, t1, 4, ctx,
                       (new_divisor < 2) ? "P3" : "P1");
        check_counter_history(new_divisor, first_rise, ctx);
      end
    end
  endtask

  task automatic change_to(input int new_divisor, input string ctx);
    bit accepted;
    int waited;
    longint accept_time;
    begin
      offer_div(new_divisor, 256, accepted, waited, accept_time);
      if (!accepted) begin
        fail("H1", {ctx, ": divisor request was not accepted"});
      end
      else begin
        finish_change(new_divisor, accept_time, ctx);
      end
    end
  endtask

  task automatic same_value_test(input int divisor);
    int per;
    int waited;
    int errors_before;
    longint accept_time;
    longint t0;
    longint t1;
    bit accepted;
    begin
      per = (divisor < 2) ? 1 : divisor;

      @(negedge clk_i);
      t0 = $time - (2 * per * CLK_PERIOD);

      offer_div(divisor, 16, accepted, waited, accept_time);
      if (!accepted) begin
        fail("H3",
             $sformatf("div %0d: same-value request was not granted", divisor));
      end
      else if (waited != 0) begin
        fail("H3",
             $sformatf("div %0d: same-value grant took %0d cycles, not zero",
                       divisor, waited));
      end

      repeat (((4 + 2) * per) + 4) @(posedge clk_i);
      @(negedge clk_i);
      t1 = $time - CLK_PERIOD;

      errors_before = errors;
      analyze_window(divisor, t0, t1, 4, "same-value continuity",
                     (divisor < 2) ? "P3" : "P1");
      if (errors != errors_before) begin
        fail("H3",
             $sformatf("div %0d: same-value request disturbed clk_o", divisor));
      end
    end
  endtask

  task automatic check_ready_idle;
    int i;
    bit bad;
    begin
      bad = 1'b0;
      for (i = 0; i < 20; i = i + 1) begin
        @(negedge clk_i);
        if (div_ready_o !== 1'b0) begin
          bad = 1'b1;
        end
      end
      if (bad) begin
        fail("H1", "div_ready_o was high while div_valid_i was low");
      end
    end
  endtask

  // The second offer is made immediately after the first acceptance, while a
  // conforming long/short gating implementation is still busy.  Its valid and
  // data remain asserted without re-offering until the bounded task returns.
  task automatic deferred_request_test;
    bit accepted_first;
    bit accepted_second;
    int waited_first;
    int waited_second;
    longint accept_first;
    longint accept_second;
    begin
      offer_div(8, 256, accepted_first, waited_first, accept_first);
      if (!accepted_first) begin
        fail("H1", "H4 setup: first divisor change was not accepted");
      end
      else begin
        offer_div(3, 1024, accepted_second, waited_second, accept_second);
        if (!accepted_second) begin
          fail("H4", "request offered during gating was not eventually accepted");
        end
        else begin
          // L4: no fixed deferral latency is checked.
          finish_change(3, accept_second, "H4 deferred request");
        end
      end
    end
  endtask

  task automatic disable_test(input int divisor);
    int per;
    int i;
    int rise_count;
    longint disable_time;
    longint enable_time;
    longint window_end;
    longint last_rise;
    longint first_fall;
    bit found_high;
    bit found_rise;
    bit found_fall;
    bit low_bad;
    begin
      per = (divisor < 2) ? 1 : divisor;
      found_high = 1'b0;
      disable_time = 0;
      i = 0;

      // Arrange for en_i to fall during a high phase, so E3's final-pulse
      // obligation is actually exercised.
      while (!found_high && (i < ((2 * per) + 4))) begin
        @(negedge clk_i);
        i = i + 1;
        if (clk_o === 1'b1) begin
          found_high = 1'b1;
          en_i = 1'b0;
          disable_time = $time;
        end
      end

      if (!found_high) begin
        @(negedge clk_i);
        en_i = 1'b0;
        disable_time = $time;
        fail("E3", "could not observe a high phase before disabling");
      end

      // E1: exactly the specified 100-cycle no-rising-edge observation.
      repeat (100) @(posedge clk_i);
      @(negedge clk_i);
      window_end = $time;

      rise_count = 0;
      for (i = 0; i < clk_o_times.size(); i = i + 1) begin
        if ((clk_o_values[i] == 1'b1) &&
            (clk_o_times[i] > disable_time) &&
            (clk_o_times[i] <= window_end)) begin
          rise_count = rise_count + 1;
        end
      end
      if (rise_count != 0) begin
        fail("E1",
             $sformatf("div %0d: %0d rising edges while disabled",
                       divisor, rise_count));
      end

      // E3: measure the width of the final high pulse in raw time.  This is
      // deliberately not expressed as a whole-cycle low deadline.
      last_rise = 0;
      first_fall = 0;
      found_rise = 1'b0;
      found_fall = 1'b0;
      for (i = 0; i < clk_o_times.size(); i = i + 1) begin
        if ((clk_o_values[i] == 1'b1) &&
            (clk_o_times[i] <= disable_time)) begin
          last_rise = clk_o_times[i];
          found_rise = 1'b1;
        end
        if (!found_fall &&
            (clk_o_values[i] == 1'b0) &&
            (clk_o_times[i] >= disable_time)) begin
          first_fall = clk_o_times[i];
          found_fall = 1'b1;
        end
      end

      if (found_high) begin
        if (!found_rise || !found_fall) begin
          fail("E3",
               $sformatf("div %0d: final high pulse did not complete", divisor));
        end
        else if ((first_fall - last_rise) != ((per * CLK_PERIOD) / 2)) begin
          fail("E3",
               $sformatf("div %0d: final high width %0d, expected %0d",
                         divisor, first_fall - last_rise,
                         (per * CLK_PERIOD) / 2));
        end
      end

      // Once at rest, check the level as well as the absence of rising edges.
      low_bad = 1'b0;
      for (i = 0; i < 40; i = i + 1) begin
        @(posedge clk_i);
        if (clk_o !== 1'b0) begin
          low_bad = 1'b1;
        end
      end
      @(negedge clk_i);
      if (low_bad) begin
        fail("E3",
             $sformatf("div %0d: clk_o was not low on all 40 resting edges",
                       divisor));
      end

      en_i = 1'b1;
      enable_time = $time;

      // E2 has no exact resume latency; this is only a generous test timeout.
      repeat ((100 * per) + 100) @(posedge clk_i);
      @(negedge clk_i);

      found_rise = 1'b0;
      for (i = 0; i < clk_o_times.size(); i = i + 1) begin
        if ((clk_o_values[i] == 1'b1) &&
            (clk_o_times[i] > enable_time)) begin
          found_rise = 1'b1;
        end
      end
      if (!found_rise) begin
        fail("E2",
             $sformatf("div %0d: output did not resume after enable", divisor));
      end

      measure_running(divisor, 4, "enable resume",
                      (divisor < 2) ? "P3" : "P1");
      check_counter_live(divisor, (2 * per) + 8, "enable resume");
    end
  endtask

  task automatic reset_while_running;
    longint reset_start;
    longint reset_end;
    int i;
    int rise_count;
    begin
      @(negedge clk_i);
      rst_ni = 1'b0;
      reset_start = $time;

      repeat (5) @(posedge clk_i);
      @(negedge clk_i);
      reset_end = $time;
      rst_ni = 1'b1;

      rise_count = 0;
      for (i = 0; i < clk_o_times.size(); i = i + 1) begin
        if ((clk_o_values[i] == 1'b1) &&
            (clk_o_times[i] > reset_start) &&
            (clk_o_times[i] < reset_end)) begin
          rise_count = rise_count + 1;
        end
      end
      if (rise_count != 0) begin
        fail("R1", "a rising clk_o edge occurred while rst_ni was low");
      end
    end
  endtask

  initial begin : main_sequence
    errors = 0;
    current_div = 0;

    rst_ni = 1'b0;
    en_i = 1'b1;
    test_mode_en_i = 1'b0;
    div_i = 4'd0;
    div_valid_i = 1'b0;

    repeat (5) @(posedge clk_i);
    @(negedge clk_i);
    rst_ni = 1'b1;

    // Reset default and H1/H3 behavior.
    check_ready_idle();
    measure_running(0, 4, "reset default", "P3");
    check_counter_live(0, 12, "reset default");
    same_value_test(0);

    // Exercise every divisor, including all odd divisors through 15.
    for (d = 1; d <= 15; d = d + 1) begin
      change_to(d, $sformatf("initial transition to div %0d", d));
      current_div = d;
    end

    // Exercise every ordered real change in 0..8.  Returning to the source
    // before each request avoids turning this into merely a chain of changes.
    for (a = 0; a <= 8; a = a + 1) begin
      if (current_div != a) begin
        change_to(a, $sformatf("setup source div %0d", a));
        current_div = a;
      end

      same_value_test(a);

      for (b = 0; b <= 8; b = b + 1) begin
        if (b != a) begin
          if (current_div != a) begin
            change_to(a, $sformatf("restore source div %0d", a));
            current_div = a;
          end
          change_to(b, $sformatf("ordered change %0d -> %0d", a, b));
          current_div = b;
        end
      end
    end

    // H4: a request during a real transition must eventually be accepted.
    if (current_div != 4) begin
      change_to(4, "H4 setup to div 4");
      current_div = 4;
    end
    deferred_request_test();
    current_div = 3;

    // E1/E2/E3 at both an even and an odd divisor.
    change_to(4, "enable test setup div 4");
    current_div = 4;
    disable_test(4);

    change_to(5, "enable test setup div 5");
    current_div = 5;
    disable_test(5);

    // R1/R2: reset a non-default configuration and verify pass-through returns.
    change_to(4, "reset test setup div 4");
    current_div = 4;
    reset_while_running();
    current_div = 0;
    measure_running(0, 4, "post-reset default divisor", "R2");
    check_counter_live(0, 12, "post-reset pass-through");
    check_ready_idle();

    repeat (2) @(posedge clk_i);
    if (errors == 0) begin
      $display("RESULT: PASS");
    end
    else begin
      $display("RESULT: FAIL");
    end
    $finish;
  end

  initial begin : watchdog
    #4_000_000;
    $display("WATCHDOG: testbench did not complete");
    $display("RESULT: FAIL");
    $finish;
  end

endmodule
