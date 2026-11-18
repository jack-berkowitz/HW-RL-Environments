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
  // Testbench bookkeeping and exact arithmetic
  // ---------------------------------------------------------------------------

  localparam int MAX_HIST = 4096;
  localparam longint signed P_DEFAULT = 64'd419430;  // 6 ns + 16'h6666
  localparam longint signed P_PERIOD1 = 64'd688128;  // 10 ns + 16'h8000
  localparam longint signed P_BASE    = 64'd524288;  // 8 ns exactly
  localparam longint signed SECOND_FNS = 64'd65536000000000;

  logic [95:0] h96   [0:MAX_HIST-1];
  logic [63:0] h64   [0:MAX_HIST-1];
  logic        hstep [0:MAX_HIST-1];
  logic        hact  [0:MAX_HIST-1];
  logic        hpps  [0:MAX_HIST-1];
  int hs = 0;

  // Sampling before the DUT's nonblocking updates gives one coherent sample
  // per rising edge. All DUT inputs change on the opposite edge.
  always @(posedge clk) begin
    if (!rst) begin
      if (hs < MAX_HIST) begin
        h96[hs]   = ts96;
        h64[hs]   = ts64;
        hstep[hs] = ts_step;
        hact[hs]  = adj_active;
        hpps[hs]  = pps;
        hs = hs + 1;
      end
    end
  end

  task automatic fail(input string clause, input string message);
    begin
      $display("FAIL [%s] %s (cycle %0d, history %0d)",
               clause, message, bfm_cycle, hs);
      $display("RESULT: FAIL");
      $finish;
    end
  endtask

  task automatic need(input logic condition, input string clause,
                      input string message);
    begin
      if (condition !== 1'b1)
        fail(clause, message);
    end
  endtask

  task automatic clear_history;
    begin
      @(negedge clk);
      hs = 0;
    end
  endtask

  function automatic longint unsigned value96(input logic [95:0] v);
    longint unsigned seconds;
    longint unsigned nanoseconds;
    begin
      seconds = v[95:48];
      nanoseconds = v[45:16];
      value96 = (seconds * 64'd1000000000 + nanoseconds) * 64'd65536
                + v[15:0];
    end
  endfunction

  function automatic longint unsigned value64(input logic [63:0] v);
    longint unsigned nanoseconds;
    begin
      nanoseconds = v[63:16];
      value64 = nanoseconds * 64'd65536 + v[15:0];
    end
  endfunction

  function automatic longint signed delta96(input int index);
    longint signed now_value;
    longint signed old_value;
    begin
      now_value = value96(h96[index]);
      old_value = value96(h96[index-1]);
      delta96 = now_value - old_value;
    end
  endfunction

  function automatic longint signed delta64(input int index);
    longint signed now_value;
    longint signed old_value;
    begin
      now_value = value64(h64[index]);
      old_value = value64(h64[index-1]);
      delta64 = now_value - old_value;
    end
  endfunction

  function automatic longint signed base_delta(input int which_base,
                                                input int index);
    begin
      if (which_base == 0)
        base_delta = delta96(index);
      else
        base_delta = delta64(index);
    end
  endfunction

  task automatic need_room(input int last_index);
    begin
      need(hs > last_index && hs < MAX_HIST, "TB",
           "insufficient or overflowing sample history");
    end
  endtask

  task automatic check_no_flags(input int last_index);
    int i;
    begin
      for (i = 0; i <= last_index; i = i + 1) begin
        need(hact[i] === 1'b0, "A3", "adj_active_o asserted without an adjustment");
        need(hstep[i] === 1'b0, "A4/S3", "unexpected ts_step_o pulse");
        need(hpps[i] === 1'b0, "W3", "pps_o asserted without a one-second wrap");
      end
    end
  endtask

  // Check the reset defaults independently on each accumulator.
  task automatic check_default_sequence(input int first_index,
                                        input int last_index);
    int which_base;
    int i;
    int events;
    int last_event;
    longint signed d;
    begin
      need_room(last_index);
      for (which_base = 0; which_base < 2; which_base = which_base + 1) begin
        events = 0;
        last_event = -10000;
        for (i = first_index; i <= last_index; i = i + 1) begin
          d = base_delta(which_base, i);
          need(d == P_DEFAULT || d == P_DEFAULT + 2,
               "I1/I2", "increment is not the default period plus optional default drift");
          if (d == P_DEFAULT + 2) begin
            if (events != 0)
              need(i - last_event == 5, "D2/R2",
                   "default drift events are not spaced by exactly five increments");
            events = events + 1;
            last_event = i;
          end
        end
        need(events >= 3, "D2/R2", "too few default drift events observed");
        need(last_index - last_event < 5, "D2",
             "missing default drift event at end of observation window");
      }
    end
  endtask

  // A period change has only old-period and new-period increments. Adoption
  // may differ between bases, but must occur within eight cycles on each.
  task automatic check_period_transition(input longint signed old_period,
                                         input longint signed new_period,
                                         input int last_index);
    int which_base;
    int i;
    int adopted;
    longint signed d;
    begin
      need_room(last_index);
      for (which_base = 0; which_base < 2; which_base = which_base + 1) begin
        adopted = -1;
        for (i = 2; i <= last_index; i = i + 1) begin
          d = base_delta(which_base, i);
          if (adopted < 0) begin
            if (d == new_period)
              adopted = i;
            else
              need(d == old_period, "I1/I2",
                   "period transition produced an increment other than old or new period");
          end else begin
            need(d == new_period, "I2",
                 "base reverted to the old period after adopting the new period");
          end
        end
        need(adopted >= 2, "I2/L1", "period_valid_i was not adopted");
        need(adopted <= 10, "L1", "period adoption exceeded eight cycles");
      }
    end
  endtask

  task automatic check_constant_period(input longint signed period_value,
                                       input int first_index,
                                       input int last_index);
    int which_base;
    int i;
    longint signed d;
    begin
      need_room(last_index);
      for (which_base = 0; which_base < 2; which_base = which_base + 1)
        for (i = first_index; i <= last_index; i = i + 1) begin
          d = base_delta(which_base, i);
          need(d == period_value, "I1/D1",
               "increment differs from the selected period with zero drift");
        end
    end
  endtask

  // Check a transition from zero drift to a nonzero signed drift.
  task automatic check_drift_transition(input longint signed period_value,
                                        input longint signed drift_value,
                                        input int rate,
                                        input int last_index);
    int which_base;
    int i;
    int events;
    int first_event;
    int last_event;
    longint signed d;
    begin
      need_room(last_index);
      for (which_base = 0; which_base < 2; which_base = which_base + 1) begin
        events = 0;
        first_event = -1;
        last_event = -10000;
        for (i = 2; i <= last_index; i = i + 1) begin
          d = base_delta(which_base, i);
          need(d == period_value || d == period_value + drift_value,
               "I1/D3", "illegal increment during signed drift test");
          if (d == period_value + drift_value) begin
            if (events == 0)
              first_event = i;
            else
              need(i - last_event == rate, "D2",
                   "drift spacing differs from drift_rate_i on an individual base");
            events = events + 1;
            last_event = i;
          end else begin
            need(events != 0 || i <= 10, "L1",
                 "base remained without drift beyond the adoption bound");
          end
        end
        need(first_event >= 2, "D1/D2", "drift_valid_i had no effect");
        need(first_event <= 10, "L1", "first drift effect exceeded eight cycles");
        need(events >= 4, "D2", "too few drift events to establish the rate");
        need(last_index - last_event < rate, "D2",
             "missing drift event at end of observation window");
      }
    end
  endtask

  // Offset adjustment: exact count and consecutiveness on each base, plus
  // exact adj_active_o/ts_step_o cycle counts without requiring alignment.
  task automatic check_adjustment(input longint signed period_value,
                                  input longint signed adjustment,
                                  input int expected_count,
                                  input int last_index);
    int which_base;
    int i;
    int count_seen;
    int first_seen;
    int last_seen;
    int active_count;
    int active_first;
    int active_last;
    longint signed d;
    begin
      need_room(last_index);

      active_count = 0;
      active_first = -1;
      active_last = -1;
      for (i = 0; i <= last_index; i = i + 1) begin
        need(hpps[i] === 1'b0, "W3", "unexpected pps_o during adjustment");
        need(hstep[i] === hact[i], "A4",
             "ts_step_o and adj_active_o differ during an offset adjustment");
        if (hact[i] === 1'b1) begin
          if (active_count == 0)
            active_first = i;
          active_count = active_count + 1;
          active_last = i;
        end else begin
          need(hact[i] === 1'b0, "A3", "adj_active_o is unknown");
        end
      end
      need(active_count == expected_count, "A3",
           "adj_active_o was not asserted for exactly adj_count_i cycles");
      if (expected_count != 0)
        need(active_last - active_first + 1 == expected_count, "A3",
             "adj_active_o cycles were not consecutive");

      for (which_base = 0; which_base < 2; which_base = which_base + 1) begin
        count_seen = 0;
        first_seen = -1;
        last_seen = -1;
        for (i = 2; i <= last_index; i = i + 1) begin
          d = base_delta(which_base, i);
          need(d == period_value || d == period_value + adjustment,
               "I1/A5", "illegal increment during counted offset adjustment");
          if (d == period_value + adjustment) begin
            if (count_seen == 0)
              first_seen = i;
            count_seen = count_seen + 1;
            last_seen = i;
          end
        end
        need(count_seen == expected_count, "A2",
             "base did not receive exactly adj_count_i adjusted increments");
        if (expected_count != 0) begin
          need(last_seen - first_seen + 1 == expected_count, "A2",
               "adjusted increments were not consecutive");
          need(first_seen <= 10, "L1",
               "first adjusted increment exceeded the eight-cycle adoption bound");
        end
      end
    end
  endtask

  // ---------------------------------------------------------------------------
  // Stimulus
  // ---------------------------------------------------------------------------

  int i;
  int steps;
  int pulses;
  int wrap_index;
  longint signed d;

  initial begin
    // Initial reset and default period/drift measurement. Delta index 9 is
    // increment cycle 9, so none of the eight warm-up cycles is included.
    bfm_reset();
    hs = 0;
    bfm_wait(40);
    @(negedge clk);
    need_room(39);
    need(h96[0] == 96'd0 && h64[0] == 64'd0, "R2",
         "reset did not leave both timestamp bases at zero");
    check_default_sequence(9, 38);
    check_no_flags(39);

    // Remove drift, then replace the period with a fractionally exact value.
    clear_history();
    bfm_drift(4'h0, 16'h0000, 16'd5);
    bfm_wait(14);
    @(negedge clk);
    check_constant_period(P_DEFAULT, 11, hs-1);
    check_no_flags(hs-1);

    clear_history();
    bfm_period(4'd10, 16'h8000);
    bfm_wait(18);
    @(negedge clk);
    check_period_transition(P_DEFAULT, P_PERIOD1, hs-1);
    check_no_flags(hs-1);

    clear_history();
    bfm_period(4'd8, 16'h0000);
    bfm_wait(18);
    @(negedge clk);
    check_period_transition(P_PERIOD1, P_BASE, hs-1);
    check_no_flags(hs-1);

    // Positive and negative signed drift, measured separately on each base.
    clear_history();
    bfm_drift(4'h0, 16'h0003, 16'd4);
    bfm_wait(38);
    @(negedge clk);
    check_drift_transition(P_BASE, 3, 4, hs-1);
    check_no_flags(hs-1);

    clear_history();
    bfm_drift(4'h0, 16'h0000, 16'd4);
    bfm_wait(14);
    @(negedge clk);
    check_constant_period(P_BASE, 11, hs-1);

    clear_history();
    bfm_drift(4'hF, 16'hFFFB, 16'd3); // signed 20-bit -5 fns
    bfm_wait(36);
    @(negedge clk);
    check_drift_transition(P_BASE, -5, 3, hs-1);
    check_no_flags(hs-1);

    clear_history();
    bfm_drift(4'h0, 16'h0000, 16'd3);
    bfm_wait(14);
    @(negedge clk);
    check_constant_period(P_BASE, 11, hs-1);

    // Positive, negative, and zero-count offset adjustments.
    clear_history();
    bfm_adjust(4'h0, 16'h0007, 16'd5);
    bfm_wait(24);
    @(negedge clk);
    check_adjustment(P_BASE, 7, 5, hs-1);

    clear_history();
    bfm_adjust(4'hF, 16'hFFF7, 16'd3); // signed 20-bit -9 fns
    bfm_wait(22);
    @(negedge clk);
    check_adjustment(P_BASE, -9, 3, hs-1);

    clear_history();
    bfm_adjust(4'h0, 16'h0007, 16'd0);
    bfm_wait(16);
    @(negedge clk);
    check_adjustment(P_BASE, 7, 0, hs-1);

    // S1/S3: immediate 96-bit set, one step pulse, and no disturbance of ts64.
    clear_history();
    bfm_set96(48'd2, 30'd123456789, 16'h1234);
    bfm_wait(12);
    @(negedge clk);
    need_room(13);
    need(h96[2] == {48'd2, 2'b00, 30'd123456789, 16'h1234}, "S1",
         "set_ts96_i value was not visible immediately");
    steps = 0;
    for (i = 0; i < hs; i = i + 1) begin
      if (hstep[i] === 1'b1)
        steps = steps + 1;
      need(hact[i] === 1'b0, "A3", "adj_active_o asserted by a timestamp set");
      need(hpps[i] === 1'b0, "W3", "timestamp set caused pps_o");
    end
    need(steps == 1, "S3", "set_ts96_valid_i did not cause exactly one ts_step_o cycle");
    for (i = 1; i < hs; i = i + 1)
      need(delta64(i) == P_BASE, "S4", "setting ts96 disturbed ts64");
    for (i = 7; i < hs; i = i + 1)
      need(delta96(i) == P_BASE, "I1/X2c",
           "ts96 increment wrong after the post-set warm-up window");

    // S2/S3/S4 in the opposite direction.
    clear_history();
    bfm_set64(48'd123456, 16'hABCD);
    bfm_wait(12);
    @(negedge clk);
    need_room(13);
    need(h64[2] == {48'd123456, 16'hABCD}, "S2",
         "set_ts64_i value was not visible immediately");
    steps = 0;
    for (i = 0; i < hs; i = i + 1) begin
      if (hstep[i] === 1'b1)
        steps = steps + 1;
      need(hact[i] === 1'b0, "A3", "adj_active_o asserted by a timestamp set");
      need(hpps[i] === 1'b0, "W3", "timestamp set caused pps_o");
    end
    need(steps == 1, "S3", "set_ts64_valid_i did not cause exactly one ts_step_o cycle");
    for (i = 1; i < hs; i = i + 1)
      need(delta96(i) == P_BASE, "S4", "setting ts64 disturbed ts96");
    for (i = 7; i < hs; i = i + 1)
      need(delta64(i) == P_BASE, "I1/X2c",
           "ts64 increment wrong after the post-set warm-up window");

    // Reach the one-second boundary through S1. The wrap is allowed to occur
    // inside the four-cycle post-set increment warm-up, so inspect the whole
    // interval but apply exact period checks only from the fifth increment.
    clear_history();
    bfm_set96(48'd7, 30'd999999990, 16'h0000);
    bfm_wait(16);
    @(negedge clk);
    need_room(17);
    need(h96[2] == {48'd7, 2'b00, 30'd999999990, 16'h0000}, "S1",
         "near-second set value was not installed");
    pulses = 0;
    wrap_index = -1;
    for (i = 0; i < hs; i = i + 1) begin
      need(h96[i][47:46] == 2'b00, "F1", "reserved ts96 bits are nonzero");
      need(h96[i][45:16] < 30'd1000000000, "W1",
           "ts96 nanoseconds field reached or exceeded one billion");
      if (hpps[i] === 1'b1) begin
        pulses = pulses + 1;
        wrap_index = i;
      end else begin
        need(hpps[i] === 1'b0, "W3", "pps_o is unknown");
      end
      need(hstep[i] === (i == 2 || i == 1 ? hstep[i] : 1'b0), "S3/A4",
           "unexpected extra ts_step_o pulse after set");
    end
    need(pulses == 1, "W3", "wrap did not produce exactly one pps_o cycle");
    need(wrap_index > 0, "W1", "no wrap transition was observed");
    need(h96[wrap_index][95:48] == h96[wrap_index-1][95:48] + 48'd1,
         "W1", "seconds field did not increase by exactly one at wrap");
    for (i = 3; i < hs; i = i + 1) begin
      if (i != wrap_index)
        need(h96[i][95:48] == h96[i-1][95:48], "W1/W3",
             "seconds changed without the unique wrap pulse");
    end
    for (i = 7; i < hs; i = i + 1)
      need(delta96(i) == P_BASE, "W1/I1",
           "exact total timestamp advance across/after wrap is wrong");
    for (i = 1; i < hs; i = i + 1)
      need(delta64(i) == P_BASE, "S4", "near-second ts96 set disturbed ts64");

    // ts64 must cross the same numerical boundary without wrapping.
    clear_history();
    bfm_set64(48'd999999992, 16'h0000);
    bfm_wait(14);
    @(negedge clk);
    need_room(15);
    need(h64[2] == {48'd999999992, 16'h0000}, "S2",
         "near-second ts64 set failed");
    for (i = 7; i < hs; i = i + 1)
      need(delta64(i) == P_BASE, "W2",
           "ts64 wrapped or advanced incorrectly at one billion ns");
    need(h64[hs-1][63:16] > 48'd1000000000, "W2",
         "ts64 did not retain a nanoseconds value above one billion");
    for (i = 1; i < hs; i = i + 1)
      need(delta96(i) == P_BASE, "S4", "ts64 set disturbed ts96");
    for (i = 0; i < hs; i = i + 1)
      need(hpps[i] === 1'b0, "W3", "ts64 crossing one second asserted pps_o");

    // Reset with an adjustment still owed: it must cancel the adjustment and
    // restore every default. Again discard cycles 1 through 8 after reset.
    clear_history();
    bfm_adjust(4'h0, 16'h0007, 16'd30);
    bfm_wait(4);
    bfm_reset();
    hs = 0;
    bfm_wait(40);
    @(negedge clk);
    need_room(39);
    need(h96[0] == 96'd0 && h64[0] == 64'd0, "R2",
         "second reset did not clear both bases");
    check_default_sequence(9, 38);
    check_no_flags(39);

    $display("All exact period, drift, adjustment, set, wrap, and reset checks passed.");
    $display("RESULT: PASS");
    $finish;
  end

endmodule
