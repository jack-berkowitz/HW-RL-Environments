`timescale 1ns/1ps

module clk_ratio_div_tb;
  localparam int CLK_PERIOD = 10;
  localparam int HALF_PERIOD = 5;

  logic clk;
  logic rst_n;
  logic en_i;
  logic test_mode_en_i;
  logic [3:0] div_i;
  logic div_valid_i;
  logic div_ready_o;
  logic clk_o;
  logic [3:0] cycl_count_o;

  clk_ratio_div dut (
    .clk_i(clk),
    .rst_ni(rst_n),
    .en_i(en_i),
    .test_mode_en_i(test_mode_en_i),
    .div_i(div_i),
    .div_valid_i(div_valid_i),
    .div_ready_o(div_ready_o),
    .clk_o(clk_o),
    .cycl_count_o(cycl_count_o)
  );

  initial begin
    clk = 1'b0;
    forever #(CLK_PERIOD/2) clk = ~clk;
  end

  int errors = 0;
  time last_rise, last_fall;
  int rise_count = 0;
  int fall_count = 0;

  always @(posedge clk_o) begin
    rise_count++;
    last_rise = $time;
  end
  always @(negedge clk_o) begin
    fall_count++;
    last_fall = $time;
  end

  task automatic tb_error(input string req, input string msg);
    errors++;
    $display("ERROR [%s]: %s at time %0t", req, msg, $time);
  endtask

  task automatic wait_for_rise(input int timeout_cycles = 1000);
    int start = rise_count;
    int cycles = 0;
    while (rise_count == start && cycles < timeout_cycles) begin
      @(posedge clk);
      cycles++;
    end
    if (rise_count == start) tb_error("TIMEOUT", "wait_for_rise timeout");
  endtask

  task automatic wait_for_fall(input int timeout_cycles = 1000);
    int start = fall_count;
    int cycles = 0;
    while (fall_count == start && cycles < timeout_cycles) begin
      @(posedge clk);
      cycles++;
    end
    if (fall_count == start) tb_error("TIMEOUT", "wait_for_fall timeout");
  endtask

  task automatic do_reset(input int cycles = 4);
    @(negedge clk);
    rst_n = 1'b0;
    en_i = 1'b1;
    div_valid_i = 1'b0;
    div_i = 0;
    repeat (cycles) @(posedge clk);
    @(negedge clk);
    rst_n = 1'b1;
  endtask

  task automatic request_div(input int new_div, output int wait_cycles, output time ready_time, output time first_rise_time);
    int cycles;
    time t_ready;
    @(negedge clk);
    div_i = new_div[3:0];
    div_valid_i = 1'b1;
    cycles = 0;
    while (1) begin
      @(negedge clk);
      if (div_ready_o) begin
        t_ready = $time - (CLK_PERIOD/2);
        break;
      end
      cycles++;
      if (cycles > 1000) begin
        tb_error("H1", "div_ready_o timeout");
        break;
      end
    end
    wait_cycles = cycles;
    ready_time = t_ready;
    div_valid_i = 1'b0;
    wait_for_rise(1000);
    first_rise_time = last_rise;
  endtask

  task automatic check_clock(input int div, input int num_periods = 3);
    time t1, t2, t3;
    int high, low, period;
    repeat (2) wait_for_rise();
    for (int i = 0; i < num_periods; i++) begin
      t1 = last_rise;
      wait_for_fall();
      t2 = last_fall;
      wait_for_rise();
      t3 = last_rise;
      high = t2 - t1;
      low = t3 - t2;
      period = t3 - t1;
      if (div >= 2) begin
        if (period != div * CLK_PERIOD) tb_error("P1", $sformatf("div %0d period %0d ns expected %0d", div, period, div*CLK_PERIOD));
        if (high * 2 != period) tb_error("P2", $sformatf("div %0d high %0d ns period %0d", div, high, period));
        if (low * 2 != period) tb_error("P2", $sformatf("div %0d low %0d ns period %0d", div, low, period));
      end else begin
        if (period != CLK_PERIOD) tb_error("P3", $sformatf("div %0d period %0d ns expected %0d", div, period, CLK_PERIOD));
      end
    end
  endtask

  task automatic check_counter(input int div, input int num_cycles = 10);
    int expected;
    int val;
    if (div <= 1) begin
      repeat (num_cycles) begin
        @(negedge clk);
        if (cycl_count_o !== 0) tb_error("C2", $sformatf("div %0d cycl_count_o = %0d expected 0", div, cycl_count_o));
      end
    end else begin
      @(negedge clk);
      val = cycl_count_o;
      if (val >= div) tb_error("C1", $sformatf("div %0d cycl_count_o = %0d out of range", div, val));
      for (int i = 1; i < num_cycles; i++) begin
        @(negedge clk);
        expected = (val + 1) % div;
        if (cycl_count_o !== expected) begin
          tb_error("C1", $sformatf("div %0d cycl_count_o = %0d expected %0d", div, cycl_count_o, expected));
        end
        val = cycl_count_o;
      end
    end
  endtask

  initial begin
    rst_n = 1'b0;
    en_i = 1'b1;
    test_mode_en_i = 1'b0;
    div_i = 0;
    div_valid_i = 1'b0;
    errors = 0;

    @(posedge clk);
    @(posedge clk);

    do_reset(4);

    // H1: div_ready_o low while div_valid_i low
    repeat (20) begin
      @(posedge clk);
      if (div_ready_o !== 0) tb_error("H1", "div_ready_o high while div_valid_i low");
    end

    // Test initial pass-through div=0
    check_clock(0);
    check_counter(0);

    // Test div=1
    begin
      int wait_cycles; time ready_time, first_rise;
      request_div(1, wait_cycles, ready_time, first_rise);
      if (first_rise - ready_time > 3 * 1 * CLK_PERIOD) tb_error("G1", $sformatf("div 1 gap %0d ns > 30", first_rise - ready_time));
      check_clock(1);
      check_counter(1);
    end

    // Test all divisors 2..15
    for (int d = 2; d <= 15; d++) begin
      int wait_cycles; time ready_time, first_rise;
      request_div(d, wait_cycles, ready_time, first_rise);
      if (first_rise - ready_time > 3 * d * CLK_PERIOD) tb_error("G1", $sformatf("div %0d gap %0d ns > %0d", d, first_rise - ready_time, 3*d*CLK_PERIOD));
      check_clock(d);
      check_counter(d);
    end

    // Test change to 0 and 1 for tight G1 bound
    for (int d = 0; d <= 1; d++) begin
      int wait_cycles; time ready_time, first_rise;
      request_div(4, wait_cycles, ready_time, first_rise);
      request_div(d, wait_cycles, ready_time, first_rise);
      if (first_rise - ready_time > 3 * 1 * CLK_PERIOD) tb_error("G1", $sformatf("div %0d gap %0d ns > 30", d, first_rise - ready_time));
      check_clock(d);
    end

    // H3: same-value request no gating
    begin
      int wait_cycles; time ready_time, first_rise;
      time t_before;
      request_div(4, wait_cycles, ready_time, first_rise);
      check_clock(4);
      wait_for_rise();
      t_before = last_rise;
      @(negedge clk);
      div_i = 4;
      div_valid_i = 1'b1;
      wait_cycles = 0;
      while (1) begin
        @(negedge clk);
        if (div_ready_o) begin
          ready_time = $time - (CLK_PERIOD/2);
          break;
        end
        wait_cycles++;
        if (wait_cycles > 10) begin
          tb_error("H3", "same-value request not granted immediately");
          break;
        end
      end
      if (wait_cycles != 0) tb_error("H3", $sformatf("same-value wait %0d cycles expected 0", wait_cycles));
      div_valid_i = 1'b0;
      wait_for_rise();
      if (last_rise - t_before != 4 * CLK_PERIOD) tb_error("H3", $sformatf("same-value gated: period %0d ns expected %0d", last_rise - t_before, 4*CLK_PERIOD));
    end

    // H4: deferred request during gating
    begin
      int wait_cycles; time ready_time, first_rise;
      request_div(4, wait_cycles, ready_time, first_rise);
      @(negedge clk);
      div_i = 8;
      div_valid_i = 1'b1;
      wait_cycles = 0;
      while (1) begin
        @(negedge clk);
        if (div_ready_o) begin
          ready_time = $time - (CLK_PERIOD/2);
          break;
        end
        wait_cycles++;
        if (wait_cycles > 100) begin
          tb_error("H4", "first change not accepted");
          break;
        end
      end
      div_valid_i = 1'b0;
      @(negedge clk);
      div_i = 2;
      div_valid_i = 1'b1;
      wait_cycles = 0;
      while (1) begin
        @(negedge clk);
        if (div_ready_o) begin
          ready_time = $time - (CLK_PERIOD/2);
          break;
        end
        wait_cycles++;
        if (wait_cycles > 100) begin
          tb_error("H4", "second change not accepted during gating");
          break;
        end
      end
      div_valid_i = 1'b0;
      wait_for_rise(1000);
      check_clock(2);
    end

    // E1/E2/E3: Enable tests
    begin
      int wait_cycles; time ready_time, first_rise;
      time t_rise, t_fall;
      int high_width;
      request_div(5, wait_cycles, ready_time, first_rise);
      check_clock(5);
      wait_for_rise();
      t_rise = last_rise;
      @(negedge clk);
      en_i = 1'b0;
      wait_for_fall();
      t_fall = last_fall;
      high_width = t_fall - t_rise;
      if (high_width * 2 != 5 * CLK_PERIOD) tb_error("E3", $sformatf("final high pulse width %0d ns expected %0d", high_width, 5*CLK_PERIOD/2));
      begin
        int start_rise = rise_count;
        repeat (100) @(posedge clk);
        if (rise_count != start_rise) tb_error("E1", $sformatf("rising edges while disabled: %0d", rise_count - start_rise));
        if (clk_o !== 1'b0) tb_error("E3", "clk_o not low after disable");
      end
      @(negedge clk);
      en_i = 1'b1;
      check_clock(5);
    end

    // C3: counter across change
    begin
      int wait_cycles; time ready_time, first_rise;
      request_div(4, wait_cycles, ready_time, first_rise);
      check_clock(4);
      request_div(8, wait_cycles, ready_time, first_rise);
      wait_for_rise(1000);
      check_counter(8, 12);
      request_div(4, wait_cycles, ready_time, first_rise);
      wait_for_rise(1000);
      check_counter(4, 12);
    end

    // R1/R2: Reset tests
    begin
      int wait_cycles; time ready_time, first_rise;
      request_div(4, wait_cycles, ready_time, first_rise);
      check_clock(4);
      @(negedge clk);
      rst_n = 1'b0;
      begin
        int start_rise = rise_count;
        repeat (100) @(posedge clk);
        if (rise_count != start_rise) tb_error("R1", $sformatf("rising edges during reset: %0d", rise_count - start_rise));
      end
      @(negedge clk);
      rst_n = 1'b1;
      check_clock(0);
      check_counter(0);
    end

    if (errors == 0) $display("RESULT: PASS");
    else $display("RESULT: FAIL");
    $finish;
  end

  initial begin
    #4_000_000;
    $display("RESULT: FAIL (watchdog)");
    $finish;
  end

endmodule
