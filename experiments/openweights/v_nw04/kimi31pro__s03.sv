module ptp_time_base_tb;

  // ---------------------------------------------------------------------------
  // PROVIDED PLUMBING -- drives the module, checks nothing.
  // ---------------------------------------------------------------------------
  logic clk = 1'b0;
  always #5 clk = ~clk;

  int bfm_cycle = 0;
  always @(posedge clk) if (!rst) bfm_cycle <= bfm_cycle + 1;

  logic rst = 1'b1;

  task automatic bfm_reset(input int cycles = 5);
    @(negedge clk);
    rst = 1'b1;
    repeat (cycles) @(posedge clk);
    @(negedge clk);
    rst = 1'b0;
  endtask

  logic [95:0] set_ts96;   logic set_ts96_valid;
  logic [63:0] set_ts64;   logic set_ts64_valid;
  logic [3:0]  period_ns;  logic [15:0] period_fns; logic period_valid;
  logic [3:0]  adj_ns;     logic [15:0] adj_fns;    logic [15:0] adj_count;
  logic        adj_valid;  logic adj_active;
  logic [3:0]  drift_ns;   logic [15:0] drift_fns;  logic [15:0] drift_rate;
  logic        drift_valid;
  logic [95:0] ts96;       logic [63:0] ts64;
  logic        ts_step,    pps;

  ptp_time_base dut (
    .clk_i(clk), .rst_i(rst),
    .set_ts96_i(set_ts96), .set_ts96_valid_i(set_ts96_valid),
    .set_ts64_i(set_ts64), .set_ts64_valid_i(set_ts64_valid),
    .period_ns_i(period_ns), .period_fns_i(period_fns), .period_valid_i(period_valid),
    .adj_ns_i(adj_ns), .adj_fns_i(adj_fns), .adj_count_i(adj_count), .adj_valid_i(adj_valid),
    .adj_active_o(adj_active),
    .drift_ns_i(drift_ns), .drift_fns_i(drift_fns), .drift_rate_i(drift_rate),
    .drift_valid_i(drift_valid),
    .ts96_o(ts96), .ts64_o(ts64), .ts_step_o(ts_step), .pps_o(pps));

  task automatic bfm_period(input logic [3:0] ns, input logic [15:0] fns);
    @(negedge clk); period_ns = ns; period_fns = fns; period_valid = 1'b1;
    @(negedge clk); period_valid = 1'b0;
  endtask

  task automatic bfm_adjust(input logic [3:0] ns, input logic [15:0] fns,
                            input logic [15:0] count);
    @(negedge clk); adj_ns = ns; adj_fns = fns; adj_count = count; adj_valid = 1'b1;
    @(negedge clk); adj_valid = 1'b0;
  endtask

  task automatic bfm_drift(input logic [3:0] ns, input logic [15:0] fns,
                           input logic [15:0] rate);
    @(negedge clk); drift_ns = ns; drift_fns = fns; drift_rate = rate; drift_valid = 1'b1;
    @(negedge clk); drift_valid = 1'b0;
  endtask

  task automatic bfm_set96(input logic [47:0] sec, input logic [29:0] ns,
                           input logic [15:0] fns);
    @(negedge clk); set_ts96 = {sec, 2'b00, ns, fns}; set_ts96_valid = 1'b1;
    @(negedge clk); set_ts96_valid = 1'b0;
  endtask

  task automatic bfm_set64(input logic [47:0] ns, input logic [15:0] fns);
    @(negedge clk); set_ts64 = {ns, fns}; set_ts64_valid = 1'b1;
    @(negedge clk); set_ts64_valid = 1'b0;
  endtask

  task automatic bfm_wait(input int cycles); repeat (cycles) @(posedge clk); endtask

  initial begin
    set_ts96 = '0; set_ts96_valid = 1'b0; set_ts64 = '0; set_ts64_valid = 1'b0;
    period_ns = '0; period_fns = '0; period_valid = 1'b0;
    adj_ns = '0; adj_fns = '0; adj_count = '0; adj_valid = 1'b0;
    drift_ns = '0; drift_fns = '0; drift_rate = '0; drift_valid = 1'b0;
  end

  initial begin
    #3_000_000;
    $display("RESULT: FAIL (watchdog: no verdict reached)");
    $finish;
  end

  // ---------------------------------------------------------------------------
  // Exact reference checking
  // ---------------------------------------------------------------------------

  localparam longint signed P_DEFAULT = 64'd419430; // 6 * 65536 + 16'h6666
  localparam longint signed P_NEW     = 64'd660020; // 10 * 65536 + 16'h1234
  localparam longint signed D_DEFAULT = 64'd2;

  // check_mode:
  // 0 = no increment check
  // 1 = reset-default period and reset-default drift
  // 2 = fixed period, zero drift
  // 3 = old-to-new period transition, zero drift
  // 4 = counted adjustment, zero drift
  // 5 = zero-to-nonzero drift transition
  int check_mode = 0;
  int cyc = 0;
  bit rst_seen = 0;

  longint signed period_cur = P_DEFAULT;
  longint signed period_old = P_DEFAULT;
  longint signed period_new = P_NEW;
  longint signed adj_amount = 0;
  longint signed drift_amount = 0;
  int adj_expected = 0;
  int drift_expected_rate = 1;
  int control_ac = 0;

  longint unsigned previous_value [0:1];
  bit previous_valid = 0;
  logic [47:0] previous_sec;
  logic [29:0] previous_ns;

  bit period_started [0:1];
  int adjustment_number [0:1];
  int adjustment_last_cycle [0:1];
  bit adjustment_done [0:1];
  bit drift_started [0:1];
  int drift_last_cycle [0:1];

  int active_cycles = 0;
  bit active_previous = 0;
  bit active_ended = 0;

  bit set96_pulse = 0;
  bit set64_pulse = 0;
  logic [95:0] accepted_set96;
  logic [63:0] accepted_set64;
  int set96_cycle = 0;
  int set64_cycle = 0;
  bit wrap_seen = 0;

  function automatic longint unsigned timestamp96_value(input logic [95:0] value);
    longint unsigned seconds;
    longint unsigned nanoseconds;
    begin
      seconds = {16'b0, value[95:48]};
      nanoseconds = {34'b0, value[45:16]};
      timestamp96_value = seconds * 64'd65536000000000
                        + (nanoseconds << 16) + value[15:0];
    end
  endfunction

  function automatic longint unsigned timestamp64_value(input logic [63:0] value);
    longint unsigned nanoseconds;
    begin
      nanoseconds = {16'b0, value[63:16]};
      timestamp64_value = (nanoseconds << 16) + value[15:0];
    end
  endfunction

  task automatic fail(input string message);
    begin
      $display("Checker failure at cycle %0d: %s", cyc, message);
      $display("RESULT: FAIL");
      $finish;
    end
  endtask

  task automatic clear_base_state;
    int i;
    begin
      for (i = 0; i < 2; i = i + 1) begin
        period_started[i] = 0;
        adjustment_number[i] = 0;
        adjustment_last_cycle[i] = 0;
        adjustment_done[i] = 0;
        drift_started[i] = 0;
        drift_last_cycle[i] = 0;
      end
    end
  endtask

  task automatic check_one_base(input int index, input longint unsigned current_value);
    longint signed delta;
    longint signed adjusted_increment;
    longint signed drifted_increment;
    bit skip_for_set;
    begin
      delta = $signed(current_value - previous_value[index]);
      skip_for_set = 0;

      if (index == 0 && set96_cycle != 0 && cyc <= set96_cycle + 4)
        skip_for_set = 1;
      if (index == 1 && set64_cycle != 0 && cyc <= set64_cycle + 4)
        skip_for_set = 1;

      if (!skip_for_set) begin
        case (check_mode)
          1: begin
            if (cyc >= 9) begin
              if (delta == P_DEFAULT) begin
                if (drift_started[index] &&
                    cyc - drift_last_cycle[index] >= 5)
                  fail("D2: default drift did not occur exactly every fifth increment");
              end else if (delta == P_DEFAULT + D_DEFAULT) begin
                if (drift_started[index] &&
                    cyc - drift_last_cycle[index] != 5)
                  fail("D2: default drift spacing is not five on an individual base");
                drift_started[index] = 1;
                drift_last_cycle[index] = cyc;
              end else begin
                fail("I1/I2/D2/R2: increment is not the exact reset period plus optional default drift");
              end
              if (!drift_started[index] && cyc > 13)
                fail("D2: no default drift event in the first five measured cycles");
            end
          end

          2: begin
            if (delta != period_cur)
              fail("I1: increment differs exactly from the configured period with zero drift");
          end

          3: begin
            if (!period_started[index]) begin
              if (delta == period_new) begin
                period_started[index] = 1;
              end else if (delta != period_old) begin
                fail("I1/I2: increment is neither the old nor the newly configured period");
              end
              if (!period_started[index] && cyc > control_ac + 8)
                fail("L1/I2: period change was not adopted within eight cycles on each base");
            end else if (delta != period_new) begin
              fail("I2: base reverted to an increment other than the configured period");
            end
          end

          4: begin
            adjusted_increment = period_cur + adj_amount;
            if (delta == adjusted_increment) begin
              if (adjustment_done[index])
                fail("A2: adjustment was applied more than adj_count_i times");
              if (adjustment_number[index] != 0 &&
                  adjustment_last_cycle[index] != cyc - 1)
                fail("A2: adjusted increments were not consecutive");
              adjustment_number[index] = adjustment_number[index] + 1;
              adjustment_last_cycle[index] = cyc;
              if (adjustment_number[index] > adj_expected)
                fail("A2: too many adjusted increments");
              if (adjustment_number[index] == adj_expected)
                adjustment_done[index] = 1;
            end else if (delta == period_cur) begin
              if (adjustment_number[index] != 0 && !adjustment_done[index])
                fail("A2: adjustment ended before exactly adj_count_i increments");
            end else begin
              fail("I1/A5: increment is not period plus the exact signed adjustment");
            end
            if (adjustment_number[index] == 0 && cyc > control_ac + 8)
              fail("L1/A2: counted adjustment did not begin within eight cycles");
          end

          5: begin
            drifted_increment = period_cur + drift_amount;
            if (delta == drifted_increment) begin
              if (drift_started[index] &&
                  cyc - drift_last_cycle[index] != drift_expected_rate)
                fail("D2: drift is not exactly one increment out of every drift_rate_i");
              drift_started[index] = 1;
              drift_last_cycle[index] = cyc;
            end else if (delta == period_cur) begin
              if (drift_started[index] &&
                  cyc - drift_last_cycle[index] >= drift_expected_rate)
                fail("D2: a scheduled drift increment was omitted");
            end else begin
              fail("I1/D3: increment does not contain the exact signed drift");
            end
            if (!drift_started[index] && cyc > control_ac + 8)
              fail("L1/D2: new drift was not adopted within eight cycles");
          end

          default: begin
          end
        endcase
      end
    end
  endtask

  // Capture controls on the edge on which the DUT accepts them.
  always @(posedge clk) begin
    set96_pulse = 0;
    set64_pulse = 0;
    if (rst) begin
      rst_seen = 1;
    end else begin
      if (set_ts96_valid) begin
        set96_pulse = 1;
        accepted_set96 = set_ts96;
        set96_cycle = cyc + 1;
      end
      if (set_ts64_valid) begin
        set64_pulse = 1;
        accepted_set64 = set_ts64;
        set64_cycle = cyc + 1;
      end
      if (period_valid || adj_valid || drift_valid)
        control_ac = cyc + 1;
    end
  end

  // Outputs are examined away from the sampling edge.
  always @(negedge clk) begin
    longint unsigned value96;
    longint unsigned value64;
    logic [47:0] current_sec;
    logic [29:0] current_ns;
    bit wrapped_now;

    if (rst) begin
      cyc = 0;
      previous_valid = 0;
      if (rst_seen && ((ts96 !== 96'b0) || (ts64 !== 64'b0)))
        fail("R2: reset did not leave both timestamp bases at zero");
    end else begin
      cyc = cyc + 1;
      value96 = timestamp96_value(ts96);
      value64 = timestamp64_value(ts64);
      current_sec = ts96[95:48];
      current_ns = ts96[45:16];
      wrapped_now = 0;

      if (ts96[47:46] !== 2'b00)
        fail("F1: reserved bits in ts96_o are not zero");
      if (current_ns >= 30'd1000000000)
        fail("W1: ts96_o nanoseconds field reached or exceeded one second");

      if (set96_pulse && ts96 !== accepted_set96)
        fail("S1: the 96-bit set value was not visible immediately");
      if (set64_pulse && ts64 !== accepted_set64)
        fail("S2: the 64-bit set value was not visible immediately");

      if (ts_step !== (adj_active || set96_pulse || set64_pulse))
        fail("A4/S3: ts_step_o is not exactly adjustment-active cycles plus one-cycle set pulses");

      if (check_mode != 4 && adj_active)
        fail("A3: adj_active_o asserted without a counted adjustment in progress");

      if (check_mode == 4) begin
        if (adj_active) begin
          if (active_ended)
            fail("A3: adj_active_o cycles were not consecutive");
          if (active_cycles != 0 && !active_previous)
            fail("A3: adj_active_o cycles were not consecutive");
          active_cycles = active_cycles + 1;
          if (active_cycles > adj_expected)
            fail("A3: adj_active_o asserted for more than adj_count_i cycles");
        end else if (active_cycles != 0 && active_cycles < adj_expected) begin
          active_ended = 1;
          fail("A3: adj_active_o asserted for fewer than adj_count_i cycles");
        end
        active_previous = adj_active;
      end

      if (previous_valid && !set96_pulse &&
          current_sec == previous_sec + 1'b1 && current_ns < previous_ns) begin
        wrapped_now = 1;
        wrap_seen = 1;
      end

      if (pps !== wrapped_now)
        fail("W3: pps_o was not a single pulse coincident with a one-second wrap");

      if (previous_valid) begin
        check_one_base(0, value96);
        check_one_base(1, value64);
      end

      previous_value[0] = value96;
      previous_value[1] = value64;
      previous_sec = current_sec;
      previous_ns = current_ns;
      previous_valid = 1;
    end
  end

  task automatic start_zero_drift;
    begin
      check_mode = 0;
      bfm_drift(4'h0, 16'h0000, 16'd8);
      bfm_wait(12);
      period_cur = P_DEFAULT;
      clear_base_state();
      check_mode = 2;
      bfm_wait(5);
    end
  endtask

  task automatic run_adjustment(input logic [3:0] ns,
                                input logic [15:0] fns,
                                input int count,
                                input longint signed amount);
    int i;
    begin
      adj_expected = count;
      adj_amount = amount;
      active_cycles = 0;
      active_previous = 0;
      active_ended = 0;
      for (i = 0; i < 2; i = i + 1) begin
        adjustment_number[i] = 0;
        adjustment_last_cycle[i] = 0;
        adjustment_done[i] = 0;
      end
      check_mode = 4;
      bfm_adjust(ns, fns, count[15:0]);
      bfm_wait(count + 14);
      for (i = 0; i < 2; i = i + 1) begin
        if (adjustment_number[i] != count)
          fail("A2: a base did not receive exactly adj_count_i adjusted increments");
      end
      if (active_cycles != count || adj_active)
        fail("A3: adj_active_o did not last exactly adj_count_i consecutive cycles");
      check_mode = 2;
      bfm_wait(2);
    end
  endtask

  task automatic run_drift(input logic [3:0] ns,
                           input logic [15:0] fns,
                           input int rate,
                           input longint signed amount);
    int i;
    begin
      drift_expected_rate = rate;
      drift_amount = amount;
      for (i = 0; i < 2; i = i + 1) begin
        drift_started[i] = 0;
        drift_last_cycle[i] = 0;
      end
      check_mode = 5;
      bfm_drift(ns, fns, rate[15:0]);
      bfm_wait(3 * rate + 14);
      for (i = 0; i < 2; i = i + 1) begin
        if (!drift_started[i])
          fail("D2: no drift adjustment was observed on a base");
      end
      check_mode = 0;
    end
  endtask

  initial begin
    // Reset defaults, exact 6.4 ns arithmetic, and default drift rate five.
    check_mode = 1;
    clear_base_state();
    bfm_reset();
    bfm_wait(24);

    // Remove drift so subsequent increment checks have only one variable.
    start_zero_drift();

    // Period replacement, with independent adoption latency on each base.
    period_old = P_DEFAULT;
    period_new = P_NEW;
    period_started[0] = 0;
    period_started[1] = 0;
    check_mode = 3;
    bfm_period(4'd10, 16'h1234);
    bfm_wait(12);
    if (!period_started[0] || !period_started[1])
      fail("L1/I2: period update was not observed on both bases");
    period_cur = P_NEW;
    check_mode = 2;
    bfm_wait(4);

    // Positive and negative counted adjustments.
    run_adjustment(4'd1, 16'h8000, 5, 64'sd98304);       // +1.5 ns
    run_adjustment(4'he, 16'hc000, 7, -64'sd147456);     // -2.25 ns

    // Independent set operations and their post-set warm-up.
    check_mode = 2;
    bfm_set96(48'd3, 30'd123456789, 16'h1357);
    bfm_wait(9);
    bfm_set64(48'd987654321, 16'h0246);
    bfm_wait(9);

    // Reach a wrap through S1, far enough away to clear X2c's four cycles.
    wrap_seen = 0;
    bfm_set96(48'd5, 30'd999999950, 16'h0000);
    bfm_wait(14);
    if (!wrap_seen)
      fail("W1: setting near one second did not produce a wrap");
    if (ts96[95:48] != 48'd6)
      fail("W1: seconds field did not increase exactly once at the wrap");

    // The 64-bit accumulator must cross the same numerical boundary unchanged.
    bfm_set64(48'd999999990, 16'h0000);
    bfm_wait(14);
    if (ts64[63:16] <= 48'd1000000000)
      fail("W2: ts64_o incorrectly wrapped at one second");

    // Reset while an adjustment is owed: cancellation and all defaults return.
    run_adjustment(4'd0, 16'h1000, 2, 64'sd4096);
    adj_expected = 20;
    adj_amount = 64'sd98304;
    active_cycles = 0;
    active_previous = 0;
    active_ended = 0;
    clear_base_state();
    check_mode = 4;
    bfm_adjust(4'd1, 16'h8000, 16'd20);
    bfm_wait(3);
    check_mode = 0;
    bfm_reset();
    clear_base_state();
    period_cur = P_DEFAULT;
    check_mode = 1;
    bfm_wait(24);

    // Custom positive and negative drift, including exact spacing.
    start_zero_drift();
    period_cur = P_DEFAULT;
    run_drift(4'd0, 16'h0101, 7, 64'sd257);

    // Return to a zero-drift configuration before testing negative drift.
    check_mode = 0;
    bfm_drift(4'd0, 16'h0000, 16'd8);
    bfm_wait(12);
    clear_base_state();
    check_mode = 2;
    bfm_wait(4);
    run_drift(4'hf, 16'hfd00, 4, -64'sd768);

    $display("All exact increment, adjustment, drift, set, wrap, and reset checks passed.");
    $display("RESULT: PASS");
    $finish;
  end

endmodule
