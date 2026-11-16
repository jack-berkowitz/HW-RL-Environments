module clk_ratio_div_tb;
  timeunit 1ns;
  timeprecision 1ps;

  localparam time CLK_PERIOD = 10;

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

  // Edge histories are timestamps, not samples of clk_o.  All stimulus and all
  // timeouts continue to be driven by clk_i.
  time rise_times[$];
  time fall_times[$];

  always @(posedge clk_o)
    rise_times.push_back($time);

  always @(negedge clk_o)
    fall_times.push_back($time);

  int errors;
  int current_div;

  task automatic note_failure(input string req, input string detail);
    begin
      errors = errors + 1;
      $display("%s: %s", req, detail);
    end
  endtask

  // Measure three consecutive rising edges and, for non-pass-through operation,
  // the two complete high/low phases between them.
  task automatic measure_clock(
    input int    d,
    input string period_req,
    input string duty_req
  );
    automatic int  start_r;
    automatic int  max_cycles;
    automatic int  k;
    automatic int  fidx;
    automatic bit  have_rises;
    automatic bit  have_falls;
    automatic time r0;
    automatic time r1;
    automatic time r2;
    automatic time f0;
    automatic time f1;
    automatic time per;
    automatic time half_per;
    begin
      per        = CLK_PERIOD * ((d <= 1) ? 1 : d);
      half_per   = per / 2;
      start_r    = rise_times.size();
      max_cycles = 10 * ((d <= 1) ? 1 : d) + 40;
      have_rises = 1'b0;

      for (k = 0; k < max_cycles; k = k + 1) begin
        if (rise_times.size() >= start_r + 3) begin
          have_rises = 1'b1;
          break;
        end
        @(posedge clk_i);
      end
      if (rise_times.size() >= start_r + 3)
        have_rises = 1'b1;

      if (!have_rises) begin
        note_failure(period_req,
          $sformatf("div %0d: timed out waiting for three clk_o rising edges", d));
      end else begin
        r0 = rise_times[start_r];
        r1 = rise_times[start_r + 1];
        r2 = rise_times[start_r + 2];

        if ((r1 - r0) != per)
          note_failure(period_req,
            $sformatf("div %0d: period %0t, expected %0t",
                      d, r1-r0, per));
        if ((r2 - r1) != per)
          note_failure(period_req,
            $sformatf("div %0d: period %0t, expected %0t",
                      d, r2-r1, per));

        // X2 excludes pass-through duty-cycle measurement.
        if (d >= 2) begin
          have_falls = 1'b0;
          fidx       = 0;

          for (k = 0; k < max_cycles; k = k + 1) begin
            fidx = 0;
            while ((fidx < fall_times.size()) &&
                   (fall_times[fidx] <= r0))
              fidx = fidx + 1;
            if (fidx + 1 < fall_times.size()) begin
              have_falls = 1'b1;
              break;
            end
            @(posedge clk_i);
          end

          fidx = 0;
          while ((fidx < fall_times.size()) &&
                 (fall_times[fidx] <= r0))
            fidx = fidx + 1;
          if (fidx + 1 < fall_times.size())
            have_falls = 1'b1;

          if (!have_falls) begin
            note_failure(duty_req,
              $sformatf("div %0d: timed out waiting for falling edges", d));
          end else begin
            f0 = fall_times[fidx];
            f1 = fall_times[fidx + 1];

            if (((f0 - r0) != half_per) ||
                ((r1 - f0) != half_per))
              note_failure(duty_req,
                $sformatf("div %0d: first high/low = %0t/%0t, expected %0t/%0t",
                          d, f0-r0, r1-f0, half_per, half_per));

            if (((f1 - r1) != half_per) ||
                ((r2 - f1) != half_per))
              note_failure(duty_req,
                $sformatf("div %0d: second high/low = %0t/%0t, expected %0t/%0t",
                          d, f1-r1, r2-f1, half_per, half_per));
          end
        end
      end
    end
  endtask

  // Called only while the output is running.  Sampling at negedge avoids the
  // DUT's rising-edge update and does not quantise any clk_o measurement.
  task automatic check_counter(
    input int    d,
    input int    cycles,
    input string req
  );
    automatic logic [3:0] prev;
    automatic logic [3:0] exp4;
    automatic int         k;
    begin
      @(negedge clk_i);
      prev = cycl_count_o;

      if (d <= 1) begin
        if (cycl_count_o !== 4'd0)
          note_failure(req, "pass-through counter is not zero");
      end else begin
        if ($isunknown(prev) || (prev >= d))
          note_failure(req,
            $sformatf("div %0d: counter value %0d is outside its range",
                      d, prev));
      end

      for (k = 0; k < cycles; k = k + 1) begin
        @(negedge clk_i);
        if (d <= 1) begin
          if (cycl_count_o !== 4'd0)
            note_failure(req, "pass-through counter changed from zero");
        end else begin
          if (prev == d-1)
            exp4 = 4'd0;
          else
            exp4 = prev + 4'd1;

          if (cycl_count_o !== exp4)
            note_failure(req,
              $sformatf("div %0d: counter %0d followed %0d, expected %0d",
                        d, cycl_count_o, prev, exp4));
          prev = cycl_count_o;
        end
      end
    end
  endtask

  // Offer a real change and hold div_i stable until acceptance.  The returned
  // origin is the ready cycle, deliberately not the valid-assertion cycle.
  task automatic start_change(
    input  int    new_d,
    input  string timeout_req,
    output bit    granted,
    output time   origin,
    output int    rise_base
  );
    automatic int  k;
    automatic time this_cycle;
    begin
      granted   = 1'b0;
      origin    = 0;
      rise_base = 0;

      @(negedge clk_i);
      div_i       = new_d[3:0];
      div_valid_i = 1'b1;

      for (k = 0; k < 256; k = k + 1) begin
        @(posedge clk_i);
        this_cycle = $time;
        @(negedge clk_i);
        if (div_ready_o === 1'b1) begin
          granted = 1'b1;
          origin  = this_cycle;
          break;
        end
      end

      div_valid_i = 1'b0;
      rise_base   = rise_times.size();

      if (!granted)
        note_failure(timeout_req,
          $sformatf("change to div %0d was not accepted", new_d));
    end
  endtask

  task automatic wait_resume(
    input  int  old_d,
    input  int  new_d,
    input  time origin,
    input  int  rise_base,
    output bit  ok
  );
    automatic int  period_cycles;
    automatic int  old_period_cycles;
    automatic int  max_cycles;
    automatic int  k;
    automatic int  fidx;
    automatic time limit;
    automatic time resume_t;
    automatic time last_r;
    automatic time fall_t;
    automatic time old_half;
    automatic bit  found;
    automatic bit  high_at_start;
    begin
      ok                 = 1'b0;
      found              = 1'b0;
      period_cycles      = (new_d <= 1) ? 1 : new_d;
      old_period_cycles  = (old_d <= 1) ? 1 : old_d;
      limit              = 3 * CLK_PERIOD * period_cycles;
      max_cycles         = 3 * period_cycles + 8;
      high_at_start      = (clk_o === 1'b1);
      last_r             = 0;

      if (rise_base > 0)
        last_r = rise_times[rise_base - 1];

      for (k = 0; k < max_cycles; k = k + 1) begin
        if (rise_times.size() > rise_base) begin
          found = 1'b1;
          break;
        end
        @(posedge clk_i);
      end
      if (rise_times.size() > rise_base)
        found = 1'b1;

      if (!found) begin
        note_failure("G1",
          $sformatf("change to div %0d: no resumed rising edge within %0t",
                    new_d, limit));
        if (clk_o !== 1'b0)
          note_failure("G2", "gated output did not remain idle low");
      end else begin
        ok       = 1'b1;
        resume_t = rise_times[rise_base];

        // Exact upper-bound check; no particular shorter duration is required.
        if ((resume_t - origin) > limit)
          note_failure("G1",
            $sformatf("change to div %0d: ready-to-resume gap %0t exceeds %0t",
                      new_d, resume_t-origin, limit));

        // If an old high phase was in progress at acceptance, gating must not
        // truncate it.  Thereafter the first rising edge is the resume edge.
        if (high_at_start && (rise_base > 0)) begin
          fidx = 0;
          while ((fidx < fall_times.size()) &&
                 (fall_times[fidx] <= last_r))
            fidx = fidx + 1;

          if ((fidx < fall_times.size()) &&
              (fall_times[fidx] < resume_t)) begin
            fall_t   = fall_times[fidx];
            old_half = (CLK_PERIOD * old_period_cycles) / 2;
            if ((fall_t - last_r) != old_half)
              note_failure("G2",
                $sformatf("change from div %0d: final old high pulse %0t, expected %0t",
                          old_d, fall_t-last_r, old_half));
          end
        end
      end
    end
  endtask

  task automatic change_div(input int new_d, output bit ok);
    automatic bit  granted;
    automatic time origin;
    automatic int  rise_base;
    automatic int  old_d;
    begin
      ok = 1'b0;
      if (new_d == current_div) begin
        ok = 1'b1;
      end else begin
        old_d = current_div;
        start_change(new_d, "H1", granted, origin, rise_base);
        if (granted) begin
          wait_resume(old_d, new_d, origin, rise_base, ok);
          current_div = new_d;
        end
      end
    end
  endtask

  task automatic check_ready_idle;
    automatic int k;
    begin
      @(negedge clk_i);
      div_valid_i = 1'b0;
      for (k = 0; k < 20; k = k + 1) begin
        @(posedge clk_i);
        @(negedge clk_i);
        if (div_ready_o !== 1'b0)
          note_failure("H1", "div_ready_o was high while div_valid_i was low");
      end
    end
  endtask

  task automatic test_same_value(input int d);
    automatic int  anchor;
    automatic int  k;
    automatic int  max_cycles;
    automatic bit  enough_edges;
    automatic time per;
    begin
      per          = CLK_PERIOD * ((d <= 1) ? 1 : d);
      max_cycles   = 5 * ((d <= 1) ? 1 : d) + 15;
      enough_edges = 1'b0;

      @(posedge clk_i);
      anchor = rise_times.size() - 1;

      @(negedge clk_i);
      div_i       = d[3:0];
      div_valid_i = 1'b1;

      // The request cycle is the intervening posedge.  Sampling at the next
      // negedge also avoids races with a registered ready update.
      @(posedge clk_i);
      @(negedge clk_i);
      if (div_ready_o !== 1'b1)
        note_failure("H3",
          $sformatf("same-value div %0d was not granted in the request cycle", d));
      div_valid_i = 1'b0;

      if (anchor < 0) begin
        note_failure("H3", "no rising-edge reference for same-value request");
      end else begin
        for (k = 0; k < max_cycles; k = k + 1) begin
          if (rise_times.size() >= anchor + 3) begin
            enough_edges = 1'b1;
            break;
          end
          @(posedge clk_i);
        end
        if (rise_times.size() >= anchor + 3)
          enough_edges = 1'b1;

        if (!enough_edges) begin
          note_failure("H3",
            $sformatf("same-value div %0d stopped or gated the output", d));
        end else begin
          if ((rise_times[anchor+1] - rise_times[anchor]) != per)
            note_failure("H3",
              $sformatf("same-value div %0d disturbed the running period", d));
          if ((rise_times[anchor+2] - rise_times[anchor+1]) != per)
            note_failure("H3",
              $sformatf("same-value div %0d disturbed the running period", d));
        end
      end
    end
  endtask

  task automatic test_deferred;
    automatic bit  first_granted;
    automatic bit  second_granted;
    automatic bit  resumed;
    automatic time origin1;
    automatic time origin2;
    automatic int  rise_base1;
    automatic int  rise_base2;
    begin
      // Start an uncontended 4 -> 8 change, then offer 2 while it is gating.
      start_change(8, "H1", first_granted, origin1, rise_base1);
      if (first_granted) begin
        current_div = 8;
        start_change(2, "H4", second_granted, origin2, rise_base2);
        if (second_granted) begin
          wait_resume(8, 2, origin2, rise_base2, resumed);
          current_div = 2;
          if (resumed) begin
            check_counter(2, 8, "C3");
            measure_clock(2, "P1", "P2");
          end
        end
      end
    end
  endtask

  task automatic test_enable(input int d);
    automatic bit  ok;
    automatic bit  high_seen;
    automatic bit  rise_bad;
    automatic bit  low_bad;
    automatic bit  resumed;
    automatic int  k;
    automatic int  base_r;
    automatic int  fidx;
    automatic int  max_cycles;
    automatic time disable_t;
    automatic time last_r;
    automatic time half_per;
    begin
      change_div(d, ok);
      if (ok) begin
        measure_clock(d, "P1", "P2");

        // Disable only after observing a high phase, so E3 measures the width
        // of that complete final pulse rather than imposing a cycle deadline.
        high_seen = 1'b0;
        max_cycles = 4 * d + 12;
        for (k = 0; k < max_cycles; k = k + 1) begin
          @(negedge clk_i);
          if ((clk_o === 1'b1) && (rise_times.size() > 0)) begin
            high_seen = 1'b1;
            break;
          end
        end

        if (!high_seen)
          note_failure("E3",
            $sformatf("div %0d: could not observe a high phase before disable", d));

        en_i      = 1'b0;
        disable_t = $time;
        base_r    = rise_times.size();
        last_r    = 0;
        if (base_r > 0)
          last_r = rise_times[base_r - 1];

        // E1: no rising edge for at least 100 input cycles.
        for (k = 0; k < 100; k = k + 1)
          @(posedge clk_i);

        rise_bad = 1'b0;
        for (k = base_r; k < rise_times.size(); k = k + 1) begin
          if (rise_times[k] >= disable_t)
            rise_bad = 1'b1;
        end
        if (rise_bad)
          note_failure("E1",
            $sformatf("div %0d: rising edge occurred while disabled", d));

        if (high_seen) begin
          fidx = 0;
          while ((fidx < fall_times.size()) &&
                 (fall_times[fidx] <= last_r))
            fidx = fidx + 1;

          if (fidx >= fall_times.size()) begin
            note_failure("E3",
              $sformatf("div %0d: final high phase never completed", d));
          end else begin
            half_per = (CLK_PERIOD * d) / 2;
            if ((fall_times[fidx] - last_r) != half_per)
              note_failure("E3",
                $sformatf("div %0d: final high pulse %0t, expected %0t",
                          d, fall_times[fidx]-last_r, half_per));
          end
        end

        // E3's other half: once at rest the output must not remain high.
        low_bad = 1'b0;
        for (k = 0; k < 40; k = k + 1) begin
          @(posedge clk_i);
          if (clk_o !== 1'b0)
            low_bad = 1'b1;
        end
        if (low_bad)
          note_failure("E3", "disabled output was not low after coming to rest");

        // E2: re-enable and verify the configured ratio again.
        @(negedge clk_i);
        en_i   = 1'b1;
        base_r = rise_times.size();
        resumed = 1'b0;
        max_cycles = 10 * d + 50;

        for (k = 0; k < max_cycles; k = k + 1) begin
          if (rise_times.size() > base_r) begin
            resumed = 1'b1;
            break;
          end
          @(posedge clk_i);
        end
        if (rise_times.size() > base_r)
          resumed = 1'b1;

        if (!resumed)
          note_failure("E2",
            $sformatf("div %0d: output did not resume after enable", d));
        else begin
          measure_clock(d, "E2", "P2");
          check_counter(d, 2*d+4, "C1");
        end
      end
    end
  endtask

  task automatic test_reset;
    automatic bit  ok;
    automatic bit  rise_bad;
    automatic int  base_r;
    automatic int  k;
    automatic time assert_t;
    begin
      if (current_div != 4)
        change_div(4, ok);
      else
        ok = 1'b1;

      if (ok)
        measure_clock(4, "P1", "P2");

      @(negedge clk_i);
      div_valid_i = 1'b0;
      en_i        = 1'b1;
      rst_ni      = 1'b0;
      assert_t    = $time;
      base_r      = rise_times.size();

      for (k = 0; k < 6; k = k + 1)
        @(posedge clk_i);

      rise_bad = 1'b0;
      for (k = base_r; k < rise_times.size(); k = k + 1) begin
        if (rise_times[k] > assert_t)
          rise_bad = 1'b1;
      end
      if (rise_bad)
        note_failure("R1", "clk_o produced a rising edge while reset was low");

      @(negedge clk_i);
      rst_ni      = 1'b1;
      current_div = 0;

      // div_valid_i remains low and div_i still contains 4: pass-through after
      // release therefore demonstrates restoration of the reset default.
      measure_clock(0, "R2", "P2");
      check_counter(0, 8, "C2");
    end
  endtask

  initial begin : main_test
    automatic int d;
    automatic int a;
    automatic int b;
    automatic bit ok;

    errors         = 0;
    current_div    = 0;
    rst_ni         = 1'b0;
    en_i           = 1'b1;
    test_mode_en_i = 1'b0;
    div_i          = 4'd0;
    div_valid_i    = 1'b0;

    // Initial asynchronous reset.
    @(negedge clk_i);
    rst_ni = 1'b0;
    repeat (4) @(posedge clk_i);
    @(negedge clk_i);
    rst_ni      = 1'b1;
    current_div = 0;

    check_ready_idle();

    // Reset default and both members of the degenerate pass-through pair are
    // exercised; duty is deliberately not checked for either one.
    measure_clock(0, "P3", "P2");
    check_counter(0, 8, "C2");

    // Every divisor, including every odd divisor through 15.
    for (d = 1; d <= 15; d = d + 1) begin
      change_div(d, ok);
      if (ok) begin
        if (d >= 2)
          check_counter(d, 2*d+2, "C3");
        else
          check_counter(d, 4, "C2");

        if (d <= 1)
          measure_clock(d, "P3", "P2");
        else
          measure_clock(d, "P1", "P2");

        if (d <= 1)
          check_counter(d, 8, "C2");
        else
          check_counter(d, 2*d+4, "C1");
      end
    end

    // Same-value grants and uninterrupted output at pass-through, even, and
    // odd divisors.
    change_div(0, ok);
    if (ok) test_same_value(0);
    change_div(4, ok);
    if (ok) test_same_value(4);
    change_div(5, ok);
    if (ok) test_same_value(5);

    // Exercise every ordered real change among divisors 0..8.  Only G1's upper
    // bound is checked; resuming anywhere below that bound is accepted.
    for (a = 0; a <= 8; a = a + 1) begin
      for (b = 0; b <= 8; b = b + 1) begin
        if (a != b) begin
          if (current_div != a)
            change_div(a, ok);
          if (current_div == a)
            change_div(b, ok);
        end
      end
    end

    change_div(4, ok);
    if (ok)
      test_deferred();

    test_enable(4);
    test_enable(5);

    test_reset();
    check_ready_idle();

    if (errors == 0)
      $display("RESULT: PASS");
    else
      $display("RESULT: FAIL");
    $finish;
  end

  initial begin : watchdog
    #4_000_000;
    $display("WATCHDOG: testbench time limit expired");
    $display("RESULT: FAIL");
    $finish;
  end

endmodule
