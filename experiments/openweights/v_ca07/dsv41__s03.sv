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

  // Clock generation
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

  // Error tracking
  int errors = 0;
  task automatic fail(input string req, input string msg);
    errors++;
    $display("FAIL: %s - %s", req, msg);
  endtask

  task automatic check(input bit cond, input string req, input string msg);
    if (!cond) fail(req, msg);
  endtask

  // clk_o edge monitor
  time pos_times[$];
  time neg_times[$];
  int pos_count = 0;
  int neg_count = 0;
  time last_pos_time = 0;
  time last_neg_time = 0;
  logic clk_o_prev = 1'bx;

  always @(clk_o) begin
    if (clk_o === 1'b1 && clk_o_prev !== 1'b1) begin
      pos_count++;
      last_pos_time = $time;
      pos_times.push_back($time);
    end else if (clk_o === 1'b0 && clk_o_prev !== 1'b0) begin
      neg_count++;
      last_neg_time = $time;
      neg_times.push_back($time);
    end
    clk_o_prev = clk_o;
  end

  // div_ready_o edge monitor
  time ready_rise_times[$];
  int ready_rise_count = 0;
  time last_ready_rise_time = 0;
  logic ready_prev = 1'bx;

  always @(div_ready_o) begin
    if (div_ready_o === 1'b1 && ready_prev !== 1'b1) begin
      ready_rise_count++;
      last_ready_rise_time = $time;
      ready_rise_times.push_back($time);
    end
    ready_prev = div_ready_o;
  end

  // Reset task
  task automatic do_reset();
    @(negedge clk_i);
    rst_ni = 1'b0;
    en_i = 1'b1;
    div_valid_i = 1'b0;
    div_i = 4'd0;
    test_mode_en_i = 1'b0;
    repeat (4) @(posedge clk_i);
    @(negedge clk_i);
    rst_ni = 1'b1;
  endtask

  // Wait for next posedge clk_o
  task automatic wait_posedge(input int timeout_cycles, output bit ok, output time t);
    int cnt = 0;
    int start_count = pos_count;
    ok = 0;
    while (cnt < timeout_cycles) begin
      @(negedge clk_i);
      cnt++;
      if (pos_count > start_count) begin
        t = pos_times[start_count];
        ok = 1;
        break;
      end
    end
  endtask

  // Wait for next negedge clk_o
  task automatic wait_negedge(input int timeout_cycles, output bit ok, output time t);
    int cnt = 0;
    int start_count = neg_count;
    ok = 0;
    while (cnt < timeout_cycles) begin
      @(negedge clk_i);
      cnt++;
      if (neg_count > start_count) begin
        t = neg_times[start_count];
        ok = 1;
        break;
      end
    end
  endtask

  // Wait for posedge clk_o after a given time
  task automatic wait_posedge_after(input time t0, input int timeout_cycles, output bit ok, output time t);
    int cnt = 0;
    ok = 0;
    while (cnt < timeout_cycles) begin
      @(negedge clk_i);
      cnt++;
      if (last_pos_time > t0) begin
        t = last_pos_time;
        ok = 1;
        break;
      end
    end
  endtask

  // Wait for posedge after ready and check that clk_o stays low during gating
  task automatic wait_posedge_after_ready(input time t_ready, input int timeout_cycles, output bit ok, output time t_edge, output bit stayed_low);
    int cnt = 0;
    ok = 0;
    stayed_low = 1;
    while (cnt < timeout_cycles) begin
      @(negedge clk_i);
      cnt++;
      if (last_pos_time > t_ready) begin
        t_edge = last_pos_time;
        ok = 1;
        break;
      end
      if (last_pos_time == t_ready) begin
        stayed_low = 0;
      end
      if (clk_o !== 1'b0) begin
        stayed_low = 0;
      end
    end
  endtask

  // Request a new divisor
  task automatic request_div(input logic [3:0] nd, output int wait_cycles, output bit ok, output time ready_time);
    int start_ready_count;
    int cnt;
    @(negedge clk_i);
    if (div_ready_o !== 1'b0) begin
      fail("H1", "div_ready_o high before asserting div_valid_i");
    end
    div_i = nd;
    div_valid_i = 1'b1;
    start_ready_count = ready_rise_count;
    wait_cycles = 0;
    ok = 0;
    ready_time = 0;
    cnt = 0;
    while (cnt < 200) begin
      @(negedge clk_i);
      cnt++;
      wait_cycles++;
      if (ready_rise_count > start_ready_count) begin
        ok = 1;
        ready_time = ready_rise_times[start_ready_count];
        break;
      end
    end
    @(negedge clk_i);
    div_valid_i = 1'b0;
    repeat (2) @(negedge clk_i);
    if (div_ready_o !== 1'b0) begin
      fail("H1", "div_ready_o not low after div_valid_i deasserted");
    end
  endtask

  // Measure period and duty from a given posedge time
  task automatic measure_from_posedge(input time t_start, input logic [3:0] d, input int num_periods, output bit ok);
    time t_pos;
    time t_neg;
    time t_pos_next;
    time period;
    time high;
    time low;
    int i;
    bit w_ok;
    ok = 1;
    t_pos = t_start;
    for (i = 0; i < num_periods; i++) begin
      wait_negedge(200, w_ok, t_neg);
      if (!w_ok) begin
        fail("P1", "timeout waiting for clk_o negedge");
        ok = 0;
        return;
      end
      wait_posedge(200, w_ok, t_pos_next);
      if (!w_ok) begin
        fail("P1", "timeout waiting for clk_o posedge");
        ok = 0;
        return;
      end
      period = t_pos_next - t_pos;
      high = t_neg - t_pos;
      low = t_pos_next - t_neg;
      if (d == 0 || d == 1) begin
        if (period != 10) begin
          fail("P3", $sformatf("period at div %0d is %0d ns, expected 10 ns", d, int'(period)));
          ok = 0;
        end
      end else begin
        if (period != int'(d) * 10) begin
          fail("P1", $sformatf("period at div %0d is %0d ns, expected %0d ns", d, int'(period), int'(d)*10));
          ok = 0;
        end
        if (high != int'(d) * 5) begin
          fail("P2", $sformatf("high width at div %0d is %0d ns, expected %0d ns", d, int'(high), int'(d)*5));
          ok = 0;
        end
        if (low != int'(d) * 5) begin
          fail("P2", $sformatf("low width at div %0d is %0d ns, expected %0d ns", d, int'(low), int'(d)*5));
          ok = 0;
        end
      end
      t_pos = t_pos_next;
    end
  endtask

  // Check cycle counter
  task automatic check_counter(input logic [3:0] d, input int num_cycles, output bit ok);
    logic [3:0] prev;
    logic [3:0] curr;
    int i;
    ok = 1;
    @(negedge clk_i);
    prev = cycl_count_o;
    for (i = 0; i < num_cycles; i++) begin
      @(negedge clk_i);
      curr = cycl_count_o;
      if (d == 0 || d == 1) begin
        if (curr != 0) begin
          fail("C2", $sformatf("cycl_count_o at div %0d is %0d, expected 0", d, curr));
          ok = 0;
        end
      end else begin
        if (curr >= d) begin
          fail("C1", $sformatf("cycl_count_o at div %0d is %0d, out of range", d, curr));
          ok = 0;
        end
        if (int'(curr) != ((int'(prev) + 1) % int'(d))) begin
          fail("C1", $sformatf("cycl_count_o at div %0d: %0d -> %0d, expected %0d", d, prev, curr, (int'(prev)+1)%int'(d)));
          ok = 0;
        end
      end
      prev = curr;
    end
  endtask

  // Main test sequence
  initial begin
    logic [3:0] current_div;
    bit ok;
    int wait_cycles;
    time ready_time;
    time t_edge;
    bit stayed_low;
    time t_pos;
    time t_neg;
    time t_pos_next;
    time period;
    time high;
    int i;
    logic [3:0] d;
    logic [3:0] d1, d2;
    int limit_ns;
    int period_ns;
    int start_ready;
    int cnt;
    int start_pos;
    int start_pos_rst;

    // Initialize
    rst_ni = 1'b0;
    en_i = 1'b1;
    div_i = 4'd0;
    div_valid_i = 1'b0;
    test_mode_en_i = 1'b0;
    current_div = 4'd0;

    // Reset
    do_reset();

    // H1: div_ready_o low while div_valid_i low
    for (i = 0; i < 20; i++) begin
      @(negedge clk_i);
      if (div_ready_o !== 1'b0) begin
        fail("H1", "div_ready_o high while div_valid_i low");
        break;
      end
    end

    // Check default divisor 0 (R2, C2)
    wait_posedge(100, ok, t_pos);
    if (!ok) fail("P3", "timeout waiting for default clk_o posedge");
    else begin
      measure_from_posedge(t_pos, 4'd0, 2, ok);
      check_counter(4'd0, 4, ok);
    end

    // Test divisors 1..15
    for (d = 1; d <= 15; d++) begin
      request_div(d, wait_cycles, ok, ready_time);
      if (!ok) begin
        fail("H1", $sformatf("timeout waiting for div_ready_o for div %0d", d));
        continue;
      end
      wait_posedge_after_ready(ready_time, 200, ok, t_edge, stayed_low);
      if (!ok) begin
        fail("G1", $sformatf("timeout waiting for first posedge after ready for div %0d", d));
      end else begin
        if (d == 0 || d == 1) limit_ns = 30;
        else limit_ns = 3 * int'(d) * 10;
        if (t_edge - ready_time > limit_ns) begin
          fail("G1", $sformatf("gating gap %0d ns > %0d ns for div %0d", int'(t_edge - ready_time), limit_ns, d));
        end
        if (!stayed_low) begin
          fail("G2", $sformatf("clk_o not low during gating for div %0d", d));
        end
      end
      measure_from_posedge(t_edge, d, 3, ok);
      check_counter(d, d + 2, ok);
      current_div = d;
    end

    // H3: same-value request
    d = current_div;
    @(negedge clk_i);
    t_pos = last_pos_time;
    div_i = d;
    div_valid_i = 1'b1;
    start_ready = ready_rise_count;
    cnt = 0;
    while (cnt < 200 && ready_rise_count == start_ready) begin
      @(negedge clk_i);
      cnt++;
    end
    if (ready_rise_count == start_ready) begin
      fail("H3", "same-value request not granted");
    end else begin
      wait_cycles = cnt;
      ready_time = ready_rise_times[start_ready];
      @(negedge clk_i);
      div_valid_i = 1'b0;
      if (wait_cycles > 2) begin
        fail("H3", $sformatf("same-value request took %0d cycles, expected immediate", wait_cycles));
      end
      wait_posedge_after(ready_time, 200, ok, t_edge);
      if (!ok) fail("H3", "timeout waiting for posedge after same-value request");
      else begin
        if (d == 0 || d == 1) period_ns = 10;
        else period_ns = int'(d) * 10;
        if (t_edge - t_pos > period_ns + 10) begin
          fail("H3", $sformatf("same-value request gated: interval %0d ns > %0d ns", int'(t_edge - t_pos), period_ns + 10));
        end
      end
    end

    // H4: deferred request during gating
    d1 = 8;
    d2 = 4;
    @(negedge clk_i);
    div_i = d1;
    div_valid_i = 1'b1;
    start_ready = ready_rise_count;
    cnt = 0;
    while (cnt < 200 && ready_rise_count == start_ready) begin
      @(negedge clk_i);
      cnt++;
    end
    if (ready_rise_count == start_ready) begin
      fail("H4", "timeout waiting for first ready in deferred test");
    end else begin
      @(negedge clk_i);
      div_i = d2;
      start_ready = ready_rise_count;
      cnt = 0;
      while (cnt < 200 && ready_rise_count == start_ready) begin
        @(negedge clk_i);
        cnt++;
      end
      if (ready_rise_count == start_ready) begin
        fail("H4", "second request during gating not accepted");
      end else begin
        ready_time = ready_rise_times[start_ready];
        wait_posedge_after_ready(ready_time, 200, ok, t_edge, stayed_low);
        if (!ok) fail("G1", "timeout waiting for posedge after deferred ready");
        else begin
          limit_ns = 3 * int'(d2) * 10;
          if (t_edge - ready_time > limit_ns) fail("G1", "deferred gating gap too long");
          if (!stayed_low) fail("G2", "clk_o not low during deferred gating");
        end
        measure_from_posedge(t_edge, d2, 2, ok);
        current_div = d2;
      end
    end
    @(negedge clk_i);
    div_valid_i = 1'b0;
    repeat (2) @(negedge clk_i);
    if (div_ready_o !== 1'b0) fail("H1", "div_ready_o not low after H4 deassert");

    // Enable tests
    d = 5;
    request_div(d, wait_cycles, ok, ready_time);
    if (!ok) fail("E2", "timeout configuring to 5 for enable test");
    else begin
      wait_posedge_after(ready_time, 200, ok, t_edge);
      if (!ok) fail("E2", "timeout waiting for posedge after config to 5");
      else measure_from_posedge(t_edge, d, 2, ok);
    end

    // E3: disable during high phase
    wait_posedge(200, ok, t_pos);
    if (!ok) fail("E3", "timeout waiting for posedge before disable");
    else begin
      @(negedge clk_i);
      en_i = 1'b0;
      wait_negedge(200, ok, t_neg);
      if (!ok) fail("E3", "timeout waiting for negedge after disable");
      else begin
        high = t_neg - t_pos;
        if (high != 5 * 5) begin
          fail("E3", $sformatf("final high pulse width %0d ns, expected 25 ns", int'(high)));
        end
      end
      for (i = 0; i < 40; i++) begin
        @(negedge clk_i);
        if (clk_o !== 1'b0) begin
          fail("E3", "clk_o not low after disable");
          break;
        end
      end
      start_pos = pos_count;
      repeat (100) @(negedge clk_i);
      if (pos_count != start_pos) begin
        fail("E1", "clk_o posedge while en_i low");
      end
    end

    // E2: re-enable and check resumes at divisor 5
    @(negedge clk_i);
    en_i = 1'b1;
    wait_posedge(200, ok, t_pos);
    if (!ok) fail("E2", "timeout waiting for posedge after re-enable");
    else measure_from_posedge(t_pos, 4'd5, 2, ok);

    // Reset tests
    d = 4;
    request_div(d, wait_cycles, ok, ready_time);
    if (!ok) fail("R2", "timeout configuring to 4 before reset");
    else begin
      wait_posedge_after(ready_time, 200, ok, t_edge);
      if (!ok) fail("R2", "timeout waiting for posedge after config to 4");
      else measure_from_posedge(t_edge, d, 2, ok);
    end

    // R1: assert reset, check no posedge
    @(negedge clk_i);
    rst_ni = 1'b0;
    start_pos_rst = pos_count;
    repeat (20) @(negedge clk_i);
    if (pos_count != start_pos_rst) begin
      fail("R1", "clk_o posedge while rst_ni low");
    end
    @(negedge clk_i);
    rst_ni = 1'b1;
    // R2: default divisor 0
    wait_posedge(200, ok, t_pos);
    if (!ok) fail("R2", "timeout waiting for posedge after reset release");
    else begin
      measure_from_posedge(t_pos, 4'd0, 2, ok);
      check_counter(4'd0, 4, ok);
    end

    // Final result
    if (errors == 0) $display("RESULT: PASS");
    else $display("RESULT: FAIL");
    $finish;
  end

endmodule
