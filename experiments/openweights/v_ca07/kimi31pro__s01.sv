module clk_ratio_div_tb;
  timeunit 1ns;
  timeprecision 1ps;

  localparam longint CLK_PERIOD_NS = 10;
  localparam longint CLK_HALF_NS   = 5;

  logic       clk_i;
  logic       rst_ni;
  logic       en_i;
  logic       test_mode_en_i;
  logic [3:0] div_i;
  logic       div_valid_i;
  logic       div_ready_o;
  logic       clk_o;
  logic [3:0] cycl_count_o;

  int errors = 0;

  longint rise_count = 0;
  longint fall_count = 0;
  longint ready_count = 0;
  time last_rise_time = 0;
  time last_fall_time = 0;
  time last_ready_time = 0;

  // Every recorded entry is an actual output edge, with its raw timestamp.
  time edge_times[$];
  bit  edge_levels[$];

  int main_d;
  int main_a;
  int main_b;
  int current_div;

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
      edge_times.push_back($time);
      edge_levels.push_back(clk_o);
      if (clk_o === 1'b1) begin
        rise_count = rise_count + 1;
        last_rise_time = $time;
      end else begin
        fall_count = fall_count + 1;
        last_fall_time = $time;
      end
    end
  end

  always @(posedge div_ready_o) begin
    ready_count = ready_count + 1;
    last_ready_time = $time;
  end

  task automatic report_failure(input string requirement, input string detail);
    begin
      errors = errors + 1;
      $display("FAIL %s: %s", requirement, detail);
    end
  endtask

  task automatic finish_if_bad;
    begin
      if (errors != 0) begin
        $display("RESULT: FAIL");
        $finish;
      end
    end
  endtask

  task automatic bfm_reset(input int cycles);
    begin
      @(negedge clk_i);
      rst_ni = 1'b0;
      repeat (cycles) @(posedge clk_i);
      @(negedge clk_i);
      rst_ni = 1'b1;
    end
  endtask

  // Analyze a contiguous set of edges. No interval is quantized to clk_i
  // cycles: odd-divisor phases must retain their half-cycle component.
  task automatic analyze_stream(
    input int    d,
    input string period_requirement,
    input string duty_requirement
  );
    int n;
    int i;
    int previous_rise;
    int period_count;
    int phase_count;
    longint dt;
    longint required_period;
    longint required_half;
    begin
      n = edge_times.size();
      previous_rise = -1;
      period_count = 0;
      phase_count = 0;

      if (d <= 1)
        required_period = CLK_PERIOD_NS;
      else
        required_period = d * CLK_PERIOD_NS;
      required_half = d * CLK_HALF_NS;

      if (n < 6) begin
        report_failure(period_requirement,
          $sformatf("divisor %0d produced too few output edges (%0d)", d, n));
        return;
      end

      for (i = 0; i < n; i = i + 1) begin
        if (edge_levels[i]) begin
          if (previous_rise >= 0) begin
            period_count = period_count + 1;
            dt = edge_times[i] - edge_times[previous_rise];
            if (dt != required_period) begin
              report_failure(period_requirement,
                $sformatf("divisor %0d rise-to-rise interval %0d ns, required %0d ns",
                          d, dt, required_period));
              return;
            end
          end
          previous_rise = i;
        end
      end

      for (i = 1; i < n; i = i + 1) begin
        if (edge_levels[i] == edge_levels[i-1]) begin
          report_failure(duty_requirement,
            $sformatf("divisor %0d produced consecutive edges of the same direction", d));
          return;
        end

        if (d >= 2) begin
          phase_count = phase_count + 1;
          dt = edge_times[i] - edge_times[i-1];
          if (dt != required_half) begin
            report_failure(duty_requirement,
              $sformatf("divisor %0d %s phase was %0d ns, required %0d ns",
                        d, edge_levels[i-1] ? "high" : "low",
                        dt, required_half));
            return;
          end
        end
      end

      if (period_count < 3) begin
        report_failure(period_requirement,
          $sformatf("divisor %0d supplied only %0d complete periods",
                    d, period_count));
        return;
      end

      if ((d >= 2) && (phase_count < 4)) begin
        report_failure(duty_requirement,
          $sformatf("divisor %0d supplied too few complete phases", d));
        return;
      end
    end
  endtask

  task automatic measure_stream(
    input int    d,
    input string period_requirement,
    input string duty_requirement
  );
    int observation_cycles;
    begin
      edge_times.delete();
      edge_levels.delete();

      if (d <= 1)
        observation_cycles = 60;
      else
        observation_cycles = 12*d + 20;

      repeat (observation_cycles) @(posedge clk_i);
      analyze_stream(d, period_requirement, duty_requirement);
    end
  endtask

  task automatic check_h1;
    int i;
    begin
      div_valid_i = 1'b0;
      for (i = 0; i < 20; i = i + 1) begin
        @(posedge clk_i);
        if (div_ready_o !== 1'b0) begin
          report_failure("H1",
            "div_ready_o was not low while div_valid_i was deasserted");
          return;
        end
        @(negedge clk_i);
        if (div_ready_o !== 1'b0) begin
          report_failure("H1",
            "div_ready_o was not low while div_valid_i was deasserted");
          return;
        end
      end
    end
  endtask

  // Offer one different-value request. The returned grant timestamp is the
  // actual rising edge of div_ready_o, not the request assertion time.
  task automatic offer_change(
    input  int  newd,
    output bit  accepted,
    output time grant_time,
    output int  waited
  );
    longint ready_before;
    time observed_time;
    begin
      accepted = 1'b0;
      grant_time = 0;
      waited = 0;
      observed_time = 0;

      @(negedge clk_i);
      ready_before = ready_count;
      div_i = newd[3:0];
      div_valid_i = 1'b1;

      while ((waited < 500) && !accepted) begin
        @(posedge clk_i);
        observed_time = $time;
        if (div_ready_o === 1'b1)
          accepted = 1'b1;
        else
          waited = waited + 1;
      end

      @(negedge clk_i);
      if (ready_count > ready_before)
        grant_time = last_ready_time;
      else if (accepted)
        grant_time = observed_time;

      div_valid_i = 1'b0;
      div_i = newd[3:0];
    end
  endtask

  // Check only the G1 upper bound. No particular shorter gating duration is
  // required. G2 checking permits an already-running old high phase to finish,
  // but rejects a truncated or stretched old pulse.
  task automatic check_resume(
    input int  newd,
    input int  oldd,
    input time grant_time
  );
    int new_period_cycles;
    int maximum_gap_cycles;
    int wait_cycle;
    int i;
    int fall_index;
    int previous_rise;
    bit found;
    time first_rise;
    longint gap;
    longint old_high_width;
    begin
      if (newd <= 1)
        new_period_cycles = 1;
      else
        new_period_cycles = newd;

      maximum_gap_cycles = 3 * new_period_cycles;
      found = 1'b0;
      first_rise = 0;

      for (wait_cycle = 0;
           (wait_cycle < maximum_gap_cycles + 5) && !found;
           wait_cycle = wait_cycle + 1) begin
        for (i = 0; i < edge_times.size(); i = i + 1) begin
          if (!found && edge_levels[i] &&
              (edge_times[i] >= grant_time)) begin
            found = 1'b1;
            first_rise = edge_times[i];
          end
        end
        if (!found)
          @(posedge clk_i);
      end

      if (!found) begin
        report_failure("G1",
          $sformatf("no rising edge resumed within the bound for new divisor %0d",
                    newd));
        return;
      end

      gap = first_rise - grant_time;
      if (gap > maximum_gap_cycles * CLK_PERIOD_NS) begin
        report_failure("G1",
          $sformatf("gap from div_ready_o was %0d ns; bound was %0d ns for divisor %0d",
                    gap, maximum_gap_cycles * CLK_PERIOD_NS, newd));
        return;
      end

      fall_index = -1;
      for (i = 0; i < edge_times.size(); i = i + 1) begin
        if (!edge_levels[i] &&
            (edge_times[i] > grant_time) &&
            (edge_times[i] < first_rise) &&
            (fall_index < 0)) begin
          fall_index = i;
        end
      end

      if ((fall_index >= 0) && (oldd >= 2)) begin
        previous_rise = -1;
        for (i = 0; i < fall_index; i = i + 1) begin
          if (edge_levels[i])
            previous_rise = i;
        end

        if (previous_rise >= 0) begin
          old_high_width =
            edge_times[fall_index] - edge_times[previous_rise];
          if (old_high_width != oldd * CLK_HALF_NS) begin
            report_failure("G2",
              $sformatf("old divisor %0d high pulse across gating was %0d ns, required %0d ns",
                        oldd, old_high_width, oldd * CLK_HALF_NS));
            return;
          end
        end
      end
    end
  endtask

  task automatic change_div(input int newd, input int oldd);
    bit accepted;
    time grant_time;
    int waited;
    begin
      edge_times.delete();
      edge_levels.delete();

      offer_change(newd, accepted, grant_time, waited);
      if (!accepted) begin
        report_failure("H1",
          $sformatf("change from divisor %0d to %0d was never granted",
                    oldd, newd));
        return;
      end

      check_resume(newd, oldd, grant_time);
    end
  endtask

  task automatic test_same_value(input int d);
    bit granted;
    int observation_cycles;
    begin
      edge_times.delete();
      edge_levels.delete();

      repeat (3) @(posedge clk_i);

      @(negedge clk_i);
      div_i = d[3:0];
      div_valid_i = 1'b1;
      granted = 1'b0;

      @(posedge clk_i);
      if (div_ready_o === 1'b1)
        granted = 1'b1;

      @(negedge clk_i);
      if (div_ready_o === 1'b1)
        granted = 1'b1;
      div_valid_i = 1'b0;

      if (!granted) begin
        report_failure("H3",
          $sformatf("same-value request at divisor %0d was not granted in the same cycle",
                    d));
        return;
      end

      if (d <= 1)
        observation_cycles = 50;
      else
        observation_cycles = 8*d + 20;

      repeat (observation_cycles) @(posedge clk_i);

      // Any gating or malformed interval spanning the request is a failure,
      // even if the eventually resumed clock has the right nominal ratio.
      analyze_stream(d, "H3", "H3");
    end
  endtask

  task automatic check_counter(input int d, input string sequence_requirement);
    logic [3:0] previous_value;
    logic [3:0] current_value;
    int i;
    int next_value;
    begin
      if (d <= 1) begin
        for (i = 0; i < 20; i = i + 1) begin
          @(negedge clk_i);
          if (cycl_count_o !== 4'd0) begin
            report_failure("C2",
              $sformatf("cycl_count_o was %0d in pass-through at divisor %0d",
                        cycl_count_o, d));
            return;
          end
        end
      end else begin
        @(negedge clk_i);
        previous_value = cycl_count_o;

        if (((^previous_value) === 1'bx) || (previous_value >= d)) begin
          report_failure(sequence_requirement,
            $sformatf("counter value %0d was outside 0..%0d",
                      previous_value, d-1));
          return;
        end

        for (i = 0; i < 2*d + 4; i = i + 1) begin
          @(negedge clk_i);
          current_value = cycl_count_o;
          next_value = previous_value + 1;
          if (next_value == d)
            next_value = 0;

          if (current_value !== next_value[3:0]) begin
            report_failure(sequence_requirement,
              $sformatf("at divisor %0d counter advanced %0d -> %0d, expected %0d",
                        d, previous_value, current_value, next_value));
            return;
          end
          previous_value = current_value;
        end
      end
    end
  endtask

  task automatic test_deferred_request;
    bit first_accepted;
    bit second_accepted;
    time first_grant;
    time second_grant;
    int first_wait;
    int second_wait;
    begin
      // The source is divisor 4. Divisor 8 provides a substantial interval in
      // which the second request can remain offered while the first gates.
      edge_times.delete();
      edge_levels.delete();

      offer_change(8, first_accepted, first_grant, first_wait);
      if (!first_accepted) begin
        report_failure("H1", "initial 4 -> 8 request was not accepted");
        return;
      end

      // Hold this second offer stable until it is accepted; never re-offer it.
      offer_change(3, second_accepted, second_grant, second_wait);
      if (!second_accepted) begin
        report_failure("H4",
          "a request offered during an earlier transition was not eventually accepted");
        return;
      end

      check_resume(3, 8, second_grant);
    end
  endtask

  task automatic test_enable(input int d);
    int i;
    int search_budget;
    bit found_high;
    time final_rise;
    longint rises_before;
    longint final_width;
    begin
      found_high = 1'b0;
      search_budget = 20*d + 20;

      // Disable during a high phase, without using clk_o as a testbench clock.
      for (i = 0; (i < search_budget) && !found_high; i = i + 1) begin
        @(negedge clk_i);
        if ((clk_o === 1'b1) &&
            (last_rise_time > last_fall_time) &&
            (($time - last_rise_time) < d * CLK_HALF_NS)) begin
          found_high = 1'b1;
        end
      end

      if (!found_high) begin
        report_failure("E3",
          $sformatf("could not observe a high phase to disable at divisor %0d", d));
        return;
      end

      final_rise = last_rise_time;
      rises_before = rise_count;
      en_i = 1'b0;

      repeat (100) @(posedge clk_i);

      if (rise_count != rises_before) begin
        report_failure("E1",
          $sformatf("rising edges occurred while en_i was low at divisor %0d", d));
        return;
      end

      if (last_fall_time <= final_rise) begin
        report_failure("E3",
          $sformatf("final high pulse did not complete at divisor %0d; output may be stuck high",
                    d));
        return;
      end

      final_width = last_fall_time - final_rise;
      if (final_width != d * CLK_HALF_NS) begin
        report_failure("E3",
          $sformatf("final high pulse at divisor %0d was %0d ns, required %0d ns",
                    d, final_width, d * CLK_HALF_NS));
        return;
      end

      for (i = 0; i < 40; i = i + 1) begin
        @(negedge clk_i);
        if (clk_o !== 1'b0) begin
          report_failure("E3",
            "clk_o was not low after the final pulse completed while disabled");
          return;
        end
      end

      @(negedge clk_i);
      en_i = 1'b1;
      measure_stream(d, "E2", "E2");
    end
  endtask

  task automatic test_reset;
    longint rises_at_reset;
    time assertion_time;
    begin
      @(negedge clk_i);
      assertion_time = $time;
      rst_ni = 1'b0;
      rises_at_reset = rise_count;

      repeat (12) @(posedge clk_i);

      // Ignore only a possible same-timestep edge at assertion; any later
      // rising edge while reset remains asserted violates R1.
      if ((rise_count != rises_at_reset) &&
          (last_rise_time > assertion_time)) begin
        report_failure("R1", "a rising clk_o edge occurred while rst_ni was low");
        return;
      end

      @(negedge clk_i);
      rst_ni = 1'b1;

      // div_i intentionally still contains the previously programmed value.
      measure_stream(0, "R2", "R2");
      if (errors != 0)
        return;
      check_counter(0, "C2");
    end
  endtask

  initial begin
    rst_ni = 1'b0;
    en_i = 1'b1;
    test_mode_en_i = 1'b0;
    div_i = 4'd0;
    div_valid_i = 1'b0;
    current_div = 0;

    repeat (2) @(posedge clk_i);
    bfm_reset(4);

    check_h1();
    finish_if_bad();

    measure_stream(0, "P3", "P3");
    finish_if_bad();
    check_counter(0, "C2");
    finish_if_bad();
    test_same_value(0);
    finish_if_bad();

    // Exercise every divisor, including both pass-through encodings and every
    // odd divisor through 15. Each same-value request also checks H3.
    for (main_d = 1; main_d <= 15; main_d = main_d + 1) begin
      change_div(main_d, current_div);
      finish_if_bad();
      current_div = main_d;

      if (main_d <= 1)
        measure_stream(main_d, "P3", "P3");
      else
        measure_stream(main_d, "P1", "P2");
      finish_if_bad();

      check_counter(main_d, "C1");
      finish_if_bad();

      test_same_value(main_d);
      finish_if_bad();
    end

    // Exercise every ordered, different-value pair in 0..8. In particular,
    // every transition to 0 or 1 checks the exact three-cycle G1 limit.
    for (main_a = 0; main_a <= 8; main_a = main_a + 1) begin
      for (main_b = 0; main_b <= 8; main_b = main_b + 1) begin
        if (main_a != main_b) begin
          if (current_div != main_a) begin
            change_div(main_a, current_div);
            finish_if_bad();
            current_div = main_a;
          end

          change_div(main_b, current_div);
          finish_if_bad();
          current_div = main_b;
        end
      end
    end

    // Directed C3 check: start sampling as soon as the 4 -> 8 clock resumes.
    change_div(4, current_div);
    finish_if_bad();
    current_div = 4;
    measure_stream(4, "P1", "P2");
    finish_if_bad();

    change_div(8, current_div);
    finish_if_bad();
    current_div = 8;
    check_counter(8, "C3");
    finish_if_bad();
    measure_stream(8, "P1", "P2");
    finish_if_bad();

    // A second request remains offered throughout an earlier transition.
    change_div(4, current_div);
    finish_if_bad();
    current_div = 4;

    test_deferred_request();
    finish_if_bad();
    current_div = 3;
    measure_stream(3, "P1", "P2");
    finish_if_bad();
    check_counter(3, "C1");
    finish_if_bad();

    // E3 is checked at both an even and an odd divisor. The odd case ensures
    // that the final half-integer high phase is measured in raw time.
    change_div(4, current_div);
    finish_if_bad();
    current_div = 4;
    measure_stream(4, "P1", "P2");
    finish_if_bad();
    test_enable(4);
    finish_if_bad();

    change_div(5, current_div);
    finish_if_bad();
    current_div = 5;
    measure_stream(5, "P1", "P2");
    finish_if_bad();
    test_enable(5);
    finish_if_bad();

    // Configure a non-default ratio, then reset and require pass-through.
    change_div(4, current_div);
    finish_if_bad();
    current_div = 4;
    measure_stream(4, "P1", "P2");
    finish_if_bad();

    test_reset();
    finish_if_bad();
    current_div = 0;

    check_h1();
    finish_if_bad();

    $display("RESULT: PASS");
    $finish;
  end

  // This watchdog depends only on the testbench clock generator and simulation
  // time, never on clk_o or on any DUT handshake.
  initial begin
    #4_000_000;
    $display("WATCHDOG: simulation time limit expired");
    $display("RESULT: FAIL");
    $finish;
  end

endmodule
