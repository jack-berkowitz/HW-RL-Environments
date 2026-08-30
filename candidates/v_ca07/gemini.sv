module clk_ratio_div_tb;

  // ---- Signals and Instantiation -------------------------------------------
  logic       clk_i;
  logic       rst_ni;
  logic       en_i;
  logic       test_mode_en_i;
  logic [3:0] div_i;
  logic       div_valid_i;
  logic       div_ready_o;
  logic       clk_o;
  logic [3:0] cycl_count_o;

  clk_ratio_div dut (.*);

  // ---- Utilities -----------------------------------------------------------
  function automatic real abs(real v);
    return (v < 0) ? -v : v;
  endfunction

  task automatic fail(string msg);
    $display("RESULT: FAIL (%s)", msg);
    $finish;
  endtask

  // ---- Clock & Watchdog ----------------------------------------------------
  initial begin
    clk_i = 1'b0;
    forever #5 clk_i = ~clk_i;
  end

  initial begin
    #4_000_000;
    fail("watchdog: no forward progress");
  end

  // ---- Testbench State -----------------------------------------------------
  logic steady_state = 0;
  logic is_disabled = 0;
  int current_div = 0;
  int old_div = 0;

  // ---- Continuous Checkers -------------------------------------------------

  // H1: div_ready_o is low while div_valid_i is low
  always @(posedge clk_i) begin
    if (rst_ni && !div_valid_i && div_ready_o) begin
      fail("H1: div_ready_o is high while div_valid_i is low");
    end
  end

  // P1, P2, P4: Edge monitors
  realtime r_rise = -1.0;
  realtime r_fall = -1.0;
  realtime r_rise_prev = -1.0;
  
  always @(posedge clk_o) begin
    if (rst_ni) begin
      r_rise_prev = r_rise;
      r_rise = $realtime;
      if (steady_state && !is_disabled && r_fall > 0) begin
         automatic real low_t = r_rise - r_fall;
         automatic real exp_p = (current_div < 2) ? 10.0 : current_div * 10.0;
         if (current_div >= 2) begin
           if (abs(low_t - exp_p/2.0) > 0.1) fail("P2: low duty cycle incorrect");
         end
      end
      if (steady_state && !is_disabled && r_rise_prev > 0) begin
         automatic real per = r_rise - r_rise_prev;
         automatic real exp_p = (current_div < 2) ? 10.0 : current_div * 10.0;
         if (abs(per - exp_p) > 0.1) fail("P1: period incorrect");
      end
    end
  end

  always @(negedge clk_o) begin
    if (rst_ni) begin
      r_fall = $realtime;
      if (r_rise > 0) begin
         automatic real hw = r_fall - r_rise;
         automatic real exp_hw_old = (old_div < 2) ? 5.0 : (old_div * 10.0 / 2.0);
         automatic real exp_hw_new = (current_div < 2) ? 5.0 : (current_div * 10.0 / 2.0);
         
         if (steady_state && !is_disabled) begin
            if (current_div >= 2) begin
              if (abs(hw - exp_hw_new) > 0.1) fail("P2: high duty cycle incorrect");
            end
         end else begin
            // G2 / E3 check: During transitions or disable, any high pulse must be a valid full pulse
            if (abs(hw - exp_hw_old) > 0.1 && abs(hw - exp_hw_new) > 0.1) begin
               fail("G2/E3: Emitted a partial pulse or stopped high");
            end
         end
      end
    end
  end

  // C1, C2, C3: Cycle counter monitor
  logic [3:0] prev_cyc = 0;
  always @(negedge clk_i) begin
    if (rst_ni) begin
      if (current_div == 0 || current_div == 1) begin
        if (cycl_count_o !== 0) fail("C2: cycl_count_o not 0 in pass-through");
      end else begin
        if (cycl_count_o >= current_div) fail("C1/C3: cycl_count_o exceeded div_i - 1");
        
        if (steady_state && !is_disabled) begin
          automatic logic [3:0] exp_cyc = (prev_cyc + 1 == current_div) ? 0 : (prev_cyc + 1);
          if (cycl_count_o !== exp_cyc) fail("C1: cycl_count_o did not advance correctly");
        end
      end
    end
    prev_cyc = cycl_count_o;
  end

  // ---- Tasks ---------------------------------------------------------------
  task automatic change_div(input logic [3:0] new_div);
    automatic int wc = 0;
    automatic realtime ready_time;
    automatic real gap;
    automatic real exp_per;
    automatic real max_gap;
    automatic int wait_time;

    old_div = current_div;
    steady_state = 0;
    
    @(negedge clk_i);
    div_i = new_div;
    div_valid_i = 1'b1;
    
    while (1) begin
      @(posedge clk_i);
      if (div_ready_o) begin
        ready_time = $realtime;
        break;
      end
      wc++;
    end
    current_div = new_div;
    @(negedge clk_i);
    div_valid_i = 1'b0;

    if (new_div == old_div) begin
      // H3: same-value request granted immediately
      if (wc > 0) fail("H3: Same-value request not granted immediately");
    end else begin
      exp_per = (new_div < 2) ? 10.0 : new_div * 10.0;
      max_gap = 3.0 * exp_per;
      wait_time = $rtoi(max_gap + 10.0);
      fork
        begin
          @(posedge clk_o);
          gap = $realtime - ready_time;
        end
        begin
          #(wait_time);
          fail("G1: gap to first rising edge exceeded bound or stopped high");
        end
      join_any
      disable fork;
      
      if (gap > max_gap + 0.1) fail("G1: gap to first rising edge exceeded bound");
    end
    
    repeat (new_div * 4 + 10) @(posedge clk_i);
    r_rise_prev = -1.0;
    r_rise = -1.0;
    r_fall = -1.0;
    steady_state = 1;
  endtask

  task automatic test_h4();
    automatic int wait_cycles = 0;
    old_div = current_div;
    steady_state = 0;
    
    // Request 1: transition to 8
    @(negedge clk_i);
    div_i = 8;
    div_valid_i = 1;
    while(1) begin
      @(posedge clk_i);
      if (div_ready_o) break;
    end
    current_div = 8;
    
    @(negedge clk_i);
    div_valid_i = 0;
    
    // Request 2: offer new change during transition gating
    @(negedge clk_i);
    div_i = 5;
    div_valid_i = 1;
    while (1) begin
      @(posedge clk_i);
      if (div_ready_o) break;
      wait_cycles++;
    end
    current_div = 5;
    @(negedge clk_i);
    div_valid_i = 0;
    
    if (wait_cycles == 0) fail("H4: Second request was not deferred");
    
    repeat (current_div * 4 + 10) @(posedge clk_i);
    r_rise_prev = -1.0;
    r_rise = -1.0;
    r_fall = -1.0;
    steady_state = 1;
  endtask

  task automatic test_enable();
    automatic int wait_time;
    @(negedge clk_i);
    en_i = 1'b0;
    is_disabled = 1;
    steady_state = 0;
    
    // Wait max half-period for any active pulse to complete width correctly
    wait_time = $rtoi(current_div * 10.0 + 10.0);
    #(wait_time);
    if (clk_o !== 1'b0) fail("E3: Output left high after disable");
    
    begin
      automatic int rises = 0;
      fork
        begin
          @(posedge clk_o);
          rises++;
        end
        begin
          repeat (20) @(posedge clk_i);
        end
      join_any
      disable fork;
      if (rises > 0) fail("E1: Rising edge occurred while disabled");
    end
    
    @(negedge clk_i);
    en_i = 1'b1;
    is_disabled = 0;
    
    begin
      automatic int rises = 0;
      fork
        begin
          @(posedge clk_o);
          rises++;
        end
        begin
          repeat (current_div * 4 + 10) @(posedge clk_i);
        end
      join_any
      disable fork;
      if (rises == 0) fail("E2: Output did not resume after enable");
    end
    
    repeat (current_div * 4 + 10) @(posedge clk_i);
    r_rise_prev = -1.0;
    r_rise = -1.0;
    r_fall = -1.0;
    steady_state = 1;
  endtask

  task automatic test_reset();
    @(negedge clk_i);
    rst_ni = 0;
    is_disabled = 1;
    steady_state = 0;
    
    begin
      automatic int rises = 0;
      fork
        begin
          @(posedge clk_o);
          rises++;
        end
        begin
          repeat (10) @(posedge clk_i);
        end
      join_any
      disable fork;
      if (rises > 0) fail("R1: Rising edge occurred while reset");
    end
    
    @(negedge clk_i);
    rst_ni = 1;
    is_disabled = 0;
    current_div = 0;
    old_div = 0;
    
    repeat (10) @(posedge clk_i);
    r_rise_prev = -1.0;
    r_rise = -1.0;
    r_fall = -1.0;
    steady_state = 1;
    
    // Check it's pass-through logic (R2)
    repeat (10) @(posedge clk_i);
  endtask

  // ---- Main Test Sequence --------------------------------------------------
  initial begin
    en_i = 1;
    test_mode_en_i = 0;
    div_i = 0;
    div_valid_i = 0;
    
    @(posedge clk_i);
    @(negedge clk_i);
    rst_ni = 1;
    
    repeat (10) @(posedge clk_i);
    steady_state = 1;
    
    for (int d = 2; d <= 15; d++) begin
      change_div(d[3:0]);
    end
    
    change_div(5);
    change_div(2);
    change_div(7);
    change_div(12);
    change_div(3);
    
    change_div(0);
    change_div(1);
    
    // Same-value request check covered dynamically inside change_div routine
    change_div(1);
    
    test_h4();
    
    test_enable();
    
    test_reset();
    
    $display("RESULT: PASS");
    $finish;
  end

endmodule