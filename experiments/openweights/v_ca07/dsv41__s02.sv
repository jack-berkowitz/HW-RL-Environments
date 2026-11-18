`timescale 1ns/1ps

module clk_ratio_div_tb;

  logic clk_i;
  logic rst_ni;
  logic en_i;
  logic test_mode_en_i;
  logic [3:0] div_i;
  logic div_valid_i;
  logic div_ready_o;
  logic clk_o;
  logic [3:0] cycl_count_o;

  // DUT instantiation
  clk_ratio_div dut (
    .clk_i(clk_i),
    .rst_ni(rst_ni),
    .en_i(en_i),
    .test_mode_en_i(test_mode_en_i),
    .div_i(div_i),
    .div_valid_i(div_valid_i),
    .div_ready_o(div_ready_o),
    .clk_o(clk_o),
    .cycl_count_o(cycl_count_o)
  );

  // Clock generation (10 ns period)
  initial begin
    clk_i = 1'b0;
    forever #5 clk_i = ~clk_i;
  end

  // Watchdog
  initial begin
    #4_000_000;
    $display("RESULT: FAIL (watchdog: no forward progress)");
    $finish;
  end

  // Reset task
  task automatic bfm_reset(input int cycles = 4);
    @(negedge clk_i);
    rst_ni = 1'b0;
    repeat (cycles) @(posedge clk_i);
    @(negedge clk_i);
    rst_ni = 1'b1;
  endtask

  // Edge monitoring
  realtime last_rise_time;
  realtime last_fall_time;
  int rise_count;
  int fall_count;
  realtime last_high_width;

  initial begin
    last_rise_time = 0.0;
    last_fall_time = 0.0;
    rise_count = 0;
    fall_count = 0;
    last_high_width = 0.0;
  end

  always @(posedge clk_o) begin
    last_rise_time = $realtime;
    rise_count = rise_count + 1;
  end

  always @(negedge clk_o) begin
    last_fall_time = $realtime;
    fall_count = fall_count + 1;
    if (last_rise_time != 0.0) begin
      last_high_width = last_fall_time - last_rise_time;
    end
  end

  // Failure counter and task
  int fail_count;
  initial fail_count = 0;

  task automatic fail(input string req, input string msg);
    fail_count = fail_count + 1;
    $display("FAIL: %s - %s", req, msg);
  endtask

  // Wait for rising edge of clk_o with timeout (polled on negedge clk_i)
  task automatic wait_rise(input int timeout_cycles, output bit found, output realtime t);
    int start_count;
    int cycles;
    start_count = rise_count;
    cycles = 0;
    found = 0;
    t = 0.0;
    while (cycles < timeout_cycles) begin
      @(negedge clk_i);
      if (rise_count != start_count) begin
        found = 1;
        t = last_rise_time;
        break;
      end
      cycles = cycles + 1;
    end
  endtask

  // Wait for falling edge of clk_o with timeout
  task automatic wait_fall(input int timeout_cycles, output bit found, output realtime t);
    int start_count;
    int cycles;
    start_count = fall_count;
    cycles = 0;
    found = 0;
    t = 0.0;
    while (cycles < timeout_cycles) begin
      @(negedge clk_i);
      if (fall_count != start_count) begin
        found = 1;
        t = last_fall_time;
        break;
      end
      cycles = cycles + 1;
    end
  endtask

  // Measure period between two consecutive rising edges
  task automatic measure_period(input int timeout_cycles, output realtime period, output bit ok);
    bit found1, found2;
    realtime t1, t2;
    wait_rise(timeout_cycles, found1, t1);
    if (!found1) begin ok = 0; period = 0.0; return; end
    wait_rise(timeout_cycles, found2, t2);
    if (!found2) begin ok = 0; period = 0.0; return; end
    period = t2 - t1;
    ok = 1;
  endtask

  // Measure high and low time of one period
  task automatic measure_duty(input int timeout_cycles, output realtime high, output realtime low, output bit ok);
    bit found1, found2, found3;
    realtime t1, t2, t3;
    wait_rise(timeout_cycles, found1, t1);
    if (!found1) begin ok = 0; high = 0.0; low = 0.0; return; end
    wait_fall(timeout_cycles, found2, t2);
    if (!found2) begin ok = 0; high = 0.0; low = 0.0; return; end
    wait_rise(timeout_cycles, found3, t3);
    if (!found3) begin ok = 0; high = 0.0; low = 0.0; return; end
    high = t2 - t1;
    low = t3 - t2;
    ok = 1;
  endtask

  // Request a divisor change
  task automatic request_div(input logic [3:0] d, output int wait_cycles, output bit accepted, output realtime rtime);
    wait_cycles = 0;
    accepted = 0;
    rtime = 0.0;
    @(negedge clk_i);
    div_i = d;
    div_valid_i = 1'b1;
    while (1) begin
      @(posedge clk_i);
      if (div_ready_o) begin
        accepted = 1;
        rtime = $realtime;
        break;
      end
      wait_cycles = wait_cycles + 1;
      if (wait_cycles > 100) break;
    end
    @(negedge clk_i);
    div_valid_i = 1'b0;
  endtask

  // Check last high pulse width for G2/E3
  task automatic check_last_pulse(input realtime rtime, input logic [3:0] old_div, output bit ok);
    realtime width;
    realtime expected;
    bit found;
    realtime t_fall;
    ok = 1;
    if (old_div <= 1) return; // not specified for pass-through
    expected = (old_div * 10.0) / 2.0;
    if (clk_o) begin
      // pulse in progress, wait for fall with timeout
      wait_fall(100, found, t_fall);
      if (!found) begin
        ok = 0;
        $display("FAIL: G2/E3 no falling edge after ready, pulse stuck high");
        return;
      end
      width = t_fall - last_rise_time;
    end else begin
      width = last_high_width;
    end
    if (width < expected - 1.0 || width > expected + 1.0) begin
      ok = 0;
      $display("FAIL: G2/E3 high pulse width %0.2f, expected %0.2f at div %0d", width, expected, old_div);
    end
  endtask

  // Active divisor
  logic [3:0] active_div;
  initial active_div = 0;

  // Continuous H1 check
  always @(posedge clk_i) begin
    if (rst_ni && !div_valid_i && div_ready_o) begin
      fail("H1", "div_ready_o high while div_valid_i low");
    end
  end

  // Main test sequence
  initial begin
    // Initialize
    en_i = 1'b1;
    test_mode_en_i = 1'b0;
    div_i = 4'd0;
    div_valid_i = 1'b0;
    rst_ni = 1'b0;

    @(negedge clk_i);
    bfm_reset(4);

    repeat (2) @(posedge clk_i);

    // Test R2: after reset, default divisor 0 (pass-through)
    begin
      realtime period;
      bit ok;
      measure_period(100, period, ok);
      if (!ok) fail("R2", "no rising edge after reset");
      else if (period < 9.0 || period > 11.0) fail("R2", $sformatf("period %0.2f not 10 ns after reset", period));
    end

    // Test P3: pass-through for div 0 and 1
    begin
      realtime period;
      bit ok;
      measure_period(100, period, ok);
      if (!ok) fail("P3", "no rising edge for div 0");
      else if (period < 9.0 || period > 11.0) fail("P3", $sformatf("div 0 period %0.2f not 10 ns", period));
    end
    begin
      int wait_cycles;
      bit acc;
      realtime rtime;
      request_div(4'd1, wait_cycles, acc, rtime);
      if (!acc) fail("P3", "div 1 request not accepted");
      else begin
        realtime period;
        bit ok;
        measure_period(100, period, ok);
        if (!ok) fail("P3", "no rising edge for div 1");
        else if (period < 9.0 || period > 11.0) fail("P3", $sformatf("div 1 period %0.2f not 10 ns", period));
        active_div = 1;
      end
    end

    // Test P1, P2 for divisors 2..8
    for (int d = 2; d <= 8; d = d + 1) begin
      int wait_cycles;
      bit acc;
      realtime rtime;
      logic [3:0] old_div;
      old_div = active_div;
      request_div(d[3:0], wait_cycles, acc, rtime);
      if (!acc) begin
        fail("P1", $sformatf("request to div %0d not accepted", d));
      end else begin
        // Check G1: gap from ready to first rise
        bit found;
        realtime first_rise;
        wait_rise(200, found, first_rise);
        if (!found) begin
          fail("G1", $sformatf("no rising edge after change to div %0d", d));
        end else begin
          realtime gap;
          realtime limit;
          gap = first_rise - rtime;
          limit = 3.0 * ((d <= 1) ? 1 : d) * 10.0;
          if (gap > limit + 1.0) begin
            fail("G1", $sformatf("gap %0.2f ns > limit %0.2f ns for change to div %0d", gap, limit, d));
          end
        end
        // Check G2: last pulse width
        begin
          bit ok_pulse;
          check_last_pulse(rtime, old_div, ok_pulse);
          if (!ok_pulse) fail("G2", $sformatf("last pulse width wrong for change to div %0d", d));
        end
        // Measure new period and duty
        begin
          realtime period, high, low;
          bit ok_period, ok_duty;
          measure_period(200, period, ok_period);
          if (!ok_period) fail("P1", $sformatf("no period for div %0d", d));
          else begin
            realtime expected_period = d * 10.0;
            if (period < expected_period - 1.0 || period > expected_period + 1.0) begin
              fail("P1", $sformatf("div %0d period %0.2f, expected %0.2f", d, period, expected_period));
            end
          end
          measure_duty(200, high, low, ok_duty);
          if (!ok_duty) fail("P2", $sformatf("no duty for div %0d", d));
          else begin
            realtime expected_high = (d * 10.0) / 2.0;
            if (high < expected_high - 1.0 || high > expected_high + 1.0) begin
              fail("P2", $sformatf("div %0d high %0.2f, expected %0.2f", d, high, expected_high));
            end
            if (low < expected_high - 1.0 || low > expected_high + 1.0) begin
              fail("P2", $sformatf("div %0d low %0.2f, expected %0.2f", d, low, expected_high));
            end
          end
        end
        active_div = d[3:0];
      end
    end

    // Test C1: cycl_count_o for div 4
    begin
      int wait_cycles;
      bit acc;
      realtime rtime;
      request_div(4'd4, wait_cycles, acc, rtime);
      if (!acc) fail("C1", "div 4 request not accepted");
      else begin
        repeat (4) @(posedge clk_i);
        logic [3:0] samples[8];
        for (int i = 0; i < 8; i = i + 1) begin
          @(negedge clk_i);
          samples[i] = cycl_count_o;
        end
        bit valid_seq;
        valid_seq = 0;
        for (int offset = 0; offset < 4; offset = offset + 1) begin
          bit match;
          match = 1;
          for (int i = 0; i < 8; i = i + 1) begin
            if (samples[i] != ((offset + i) % 4)) match = 0;
          end
          if (match) valid_seq = 1;
        end
        if (!valid_seq) begin
          fail("C1", $sformatf("cycl_count_o sequence invalid for div 4: %0d %0d %0d %0d %0d %0d %0d %0d",
            samples[0], samples[1], samples[2], samples[3], samples[4], samples[5], samples[6], samples[7]));
        end
        active_div = 4;
      end
    end

    // Test C2: cycl_count_o for div 0 and 1
    begin
      int wait_cycles;
      bit acc;
      realtime rtime;
      request_div(4'd0, wait_cycles, acc, rtime);
      if (!acc) fail("C2", "div 0 request not accepted");
      else begin
        repeat (4) @(posedge clk_i);
        for (int i = 0; i < 10; i = i + 1) begin
          @(negedge clk_i);
          if (cycl_count_o != 0) fail("C2", $sformatf("cycl_count_o not 0 for div 0: %0d", cycl_count_o));
        end
        active_div = 0;
      end
    end
    begin
      int wait_cycles;
      bit acc;
      realtime rtime;
      request_div(4'd1, wait_cycles, acc, rtime);
      if (!acc) fail("C2", "div 1 request not accepted");
      else begin
        repeat (4) @(posedge clk_i);
        for (int i = 0; i < 10; i = i + 1) begin
          @(negedge clk_i);
          if (cycl_count_o != 0) fail("C2", $sformatf("cycl_count_o not 0 for div 1: %0d", cycl_count_o));
        end
        active_div = 1;
      end
    end

    // Test C3: change 4->8, check counter sequence
    begin
      int wait_cycles;
      bit acc;
      realtime rtime;
      request_div(4'd4, wait_cycles, acc, rtime);
      if (!acc) fail("C3", "div 4 request not accepted");
      else begin
        active_div = 4;
        request_div(4'd8, wait_cycles, acc, rtime);
        if (!acc) fail("C3", "div 8 request not accepted");
        else begin
          bit found;
          realtime first_rise;
          wait_rise(200, found, first_rise);
          if (!found) fail("C3", "no rising edge after change to 8");
          else begin
            logic [3:0] samples[8];
            for (int i = 0; i < 8; i = i + 1) begin
              @(negedge clk_i);
              samples[i] = cycl_count_o;
            end
            bit valid_seq;
            valid_seq = 0;
            for (int offset = 0; offset < 8; offset = offset + 1) begin
              bit match;
              match = 1;
              for (int i = 0; i < 8; i = i + 1) begin
                if (samples[i] != ((offset + i) % 8)) match = 0;
              end
              if (match) valid_seq = 1;
            end
            if (!valid_seq) begin
              fail("C3", $sformatf("cycl_count_o sequence invalid after 4->8: %0d %0d %0d %0d %0d %0d %0d %0d",
                samples[0], samples[1], samples[2], samples[3], samples[4], samples[5], samples[6], samples[7]));
            end
          end
          active_div = 8;
        end
      end
    end

    // Test H3: same-value request for div 4
    begin
      int wait_cycles;
      bit acc;
      realtime rtime;
      request_div(4'd4, wait_cycles, acc, rtime);
      if (!acc) fail("H3", "div 4 request not accepted");
      else begin
        active_div = 4;
        bit found;
        realtime t1;
        wait_rise(100, found, t1);
        if (!found) fail("H3", "no rising edge before same-value request");
        else begin
          request_div(4'd4, wait_cycles, acc, rtime);
          if (!acc) fail("H3", "same-value request not accepted");
          else begin
            if (wait_cycles != 0) fail("H3", $sformatf("same-value request waited %0d cycles, expected 0", wait_cycles));
            bit found2;
            realtime t2;
            wait_rise(100, found2, t2);
            if (!found2) fail("H3", "no rising edge after same-value request");
            else begin
              realtime period = t2 - t1;
              if (period < 39.0 || period > 41.0) fail("H3", $sformatf("same-value request gated: period %0.2f, expected 40", period));
            end
          end
        end
      end
    end

    // Test H4: request during transition
    begin
      int wait_cycles;
      bit acc;
      realtime rtime;
      request_div(4'd4, wait_cycles, acc, rtime);
      if (!acc) fail("H4", "div 4 request not accepted");
      else begin
        active_div = 4;
        @(negedge clk_i);
        div_i = 4'd8;
        div_valid_i = 1'b1;
        while (1) begin
          @(posedge clk_i);
          if (div_ready_o) break;
        end
        @(negedge clk_i);
        div_valid_i = 1'b0;
        @(negedge clk_i);
        div_i = 4'd3;
        div_valid_i = 1'b1;
        wait_cycles = 0;
        acc = 0;
        while (1) begin
          @(posedge clk_i);
          if (div_ready_o) begin
            acc = 1;
            break;
          end
          wait_cycles = wait_cycles + 1;
          if (wait_cycles > 200) break;
        end
        if (!acc) fail("H4", "second request during transition not accepted");
        else begin
          @(negedge clk_i);
          div_valid_i = 1'b0;
          bit found;
          realtime first_rise;
          wait_rise(200, found, first_rise);
          if (!found) fail("H4", "no rising edge after second request");
          else begin
            realtime period;
            bit ok;
            measure_period(200, period, ok);
            if (!ok) fail("H4", "no period after second request");
            else if (period < 29.0 || period > 31.0) fail("H4", $sformatf("final period %0.2f, expected 30 for div 3", period));
            active_div = 3;
          end
        end
      end
    end

    // Test G1/G2 for various transitions
    // 3->5
    begin
      int wait_cycles;
      bit acc;
      realtime rtime;
      logic [3:0] old_div;
      request_div(4'd3, wait_cycles, acc, rtime);
      if (!acc) fail("G1", "div 3 request not accepted");
      else begin
        active_div = 3;
        old_div = active_div;
        request_div(4'd5, wait_cycles, acc, rtime);
        if (!acc) fail("G1", "div 5 request not accepted");
        else begin
          bit found;
          realtime first_rise;
          wait_rise(200, found, first_rise);
          if (!found) fail("G1", "no rising edge for 3->5");
          else begin
            realtime gap = first_rise - rtime;
            realtime limit = 3.0 * 5 * 10.0;
            if (gap > limit + 1.0) fail("G1", $sformatf("3->5 gap %0.2f > %0.2f", gap, limit));
          end
          bit ok_pulse;
          check_last_pulse(rtime, old_div, ok_pulse);
          if (!ok_pulse) fail("G2", "3->5 pulse width wrong");
          realtime period;
          bit ok;
          measure_period(200, period, ok);
          if (!ok) fail("P1", "no period for div 5");
          else if (period < 49.0 || period > 51.0) fail("P1", $sformatf("div 5 period %0.2f", period));
          active_div = 5;
        end
      end
    end
    // 5->3
    begin
      int wait_cycles;
      bit acc;
      realtime rtime;
      logic [3:0] old_div = active_div;
      request_div(4'd3, wait_cycles, acc, rtime);
      if (!acc) fail("G1", "div 3 request not accepted");
      else begin
        bit found;
        realtime first_rise;
        wait_rise(200, found, first_rise);
        if (!found) fail("G1", "no rising edge for 5->3");
        else begin
          realtime gap = first_rise - rtime;
          realtime limit = 3.0 * 3 * 10.0;
          if (gap > limit + 1.0) fail("G1", $sformatf("5->3 gap %0.2f > %0.2f", gap, limit));
        end
        bit ok_pulse;
        check_last_pulse(rtime, old_div, ok_pulse);
        if (!ok_pulse) fail("G2", "5->3 pulse width wrong");
        realtime period;
        bit ok;
        measure_period(200, period, ok);
        if (!ok) fail("P1", "no period for div 3");
        else if (period < 29.0 || period > 31.0) fail("P1", $sformatf("div 3 period %0.2f", period));
        active_div = 3;
      end
    end
    // 4->0
    begin
      int wait_cycles;
      bit acc;
      realtime rtime;
      logic [3:0] old_div;
      request_div(4'd4, wait_cycles, acc, rtime);
      if (!acc) fail("G1", "div 4 request not accepted");
      else begin
        active_div = 4;
        old_div = active_div;
        request_div(4'd0, wait_cycles, acc, rtime);
        if (!acc) fail("G1", "div 0 request not accepted");
        else begin
          bit found;
          realtime first_rise;
          wait_rise(200, found, first_rise);
          if (!found) fail("G1", "no rising edge for 4->0");
          else begin
            realtime gap = first_rise - rtime;
            realtime limit = 3.0 * 1 * 10.0;
            if (gap > limit + 1.0) fail("G1", $sformatf("4->0 gap %0.2f > %0.2f", gap, limit));
          end
          bit ok_pulse;
          check_last_pulse(rtime, old_div, ok_pulse);
          if (!ok_pulse) fail("G2", "4->0 pulse width wrong");
          realtime period;
          bit ok;
          measure_period(200, period, ok);
          if (!ok) fail("P3", "no period for div 0");
          else if (period < 9.0 || period > 11.0) fail("P3", $sformatf("div 0 period %0.2f", period));
          active_div = 0;
        end
      end
    end
    // 0->4
    begin
      int wait_cycles;
      bit acc;
      realtime rtime;
      logic [3:0] old_div = active_div;
      request_div(4'd4, wait_cycles, acc, rtime);
      if (!acc) fail("G1", "div 4 request not accepted");
      else begin
        bit found;
        realtime first_rise;
        wait_rise(200, found, first_rise);
        if (!found) fail("G1", "no rising edge for 0->4");
        else begin
          realtime gap = first_rise - rtime;
          realtime limit = 3.0 * 4 * 10.0;
          if (gap > limit + 1.0) fail("G1", $sformatf("0->4 gap %0.2f > %0.2f", gap, limit));
        end
        bit ok_pulse;
        check_last_pulse(rtime, old_div, ok_pulse);
        if (!ok_pulse) fail("G2", "0->4 pulse width wrong");
        realtime period;
        bit ok;
        measure_period(200, period, ok);
        if (!ok) fail("P1", "no period for div 4");
        else if (period < 39.0 || period > 41.0) fail("P1", $sformatf("div 4 period %0.2f", period));
        active_div = 4;
      end
    end

    // Test E1: en_i low -> no rising edges
    begin
      int start_count;
      en_i = 1'b0;
      start_count = rise_count;
      repeat (100) @(posedge clk_i);
      if (rise_count != start_count) fail("E1", "rising edges occurred while en_i low");
    end
    // Test E2: en_i high -> resumes at configured divisor (currently 4)
    begin
      en_i = 1'b1;
      bit found;
      realtime t1;
      wait_rise(100, found, t1);
      if (!found) fail("E2", "no rising edge after en_i high");
      else begin
        realtime period;
        bit ok;
        measure_period(200, period, ok);
        if (!ok) fail("E2", "no period after en_i high");
        else if (period < 39.0 || period > 41.0) fail("E2", $sformatf("period %0.2f after en_i high, expected 40", period));
      end
    end
    // Test E3: disabling does not truncate a pulse (while high)
    begin
      int wait_cycles;
      bit acc;
      realtime rtime;
      request_div(4'd4, wait_cycles, acc, rtime);
      if (!acc) fail("E3", "div 4 request not accepted");
      else begin
        active_div = 4;
        bit found;
        realtime t1;
        wait_rise(100, found, t1);
        if (!found) fail("E3", "no rising edge before disable");
        else begin
          @(negedge clk_i);
          en_i = 1'b0;
          bit found_fall;
          realtime t_fall;
          wait_fall(100, found_fall, t_fall);
          if (!found_fall) fail("E3", "no falling edge after disable");
          else begin
            realtime width = t_fall - t1;
            if (width < 19.0 || width > 21.0) fail("E3", $sformatf("high pulse width %0.2f, expected 20", width));
          end
          int start_count = rise_count;
          repeat (40) @(posedge clk_i);
          if (rise_count != start_count) fail("E3", "rising edges occurred after disable");
        end
      end
    end
    // Test E3: disabling while low
    begin
      en_i = 1'b1;
      bit found;
      realtime t1;
      wait_fall(100, found, t1);
      if (!found) fail("E3", "no falling edge before disable low");
      else begin
        @(negedge clk_i);
        en_i = 1'b0;
        int start_count = rise_count;
        repeat (40) @(posedge clk_i);
        if (rise_count != start_count) fail("E3", "rising edges occurred after disable low");
      end
      en_i = 1'b1;
    end

    // Test R1: reset while running, check no rising edges
    begin
      en_i = 1'b1;
      int wait_cycles;
      bit acc;
      realtime rtime;
      request_div(4'd4, wait_cycles, acc, rtime);
      if (!acc) fail("R1", "div 4 request not accepted");
      else begin
        active_div = 4;
        bit found;
        realtime t1;
        wait_rise(100, found, t1);
        if (!found) fail("R1", "no rising edge before reset");
        else begin
          @(negedge clk_i);
          rst_ni = 1'b0;
          int start_count = rise_count;
          repeat (10) @(posedge clk_i);
          if (rise_count != start_count) fail("R1", "rising edges occurred during reset");
          @(negedge clk_i);
          rst_ni = 1'b1;
          repeat (2) @(posedge clk_i);
          realtime period;
          bit ok;
          measure_period(100, period, ok);
          if (!ok) fail("R2", "no rising edge after reset release");
          else if (period < 9.0 || period > 11.0) fail("R2", $sformatf("period %0.2f after reset, expected 10", period));
          active_div = 0;
        end
      end
    end

    // Final result
    if (fail_count == 0) $display("RESULT: PASS");
    else $display("RESULT: FAIL");
    $finish;
  end

endmodule
