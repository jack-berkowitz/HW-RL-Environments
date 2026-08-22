module ptp_time_base_tb;
// ---------------------------------------------------------------------------
// PROVIDED PLUMBING -- drives the module, checks nothing.
// ---------------------------------------------------------------------------
  // ---- clock ---------------------------------------------------------------
  logic clk = 1'b0;
  always #5 clk = ~clk;

  // A free-running cycle count, for your own bookkeeping and messages.
  int bfm_cycle = 0;
  always @(posedge clk) if (!rst) bfm_cycle <= bfm_cycle + 1;

  // ---- reset ---------------------------------------------------------------
  logic rst = 1'b1;      // SYNCHRONOUS, ACTIVE HIGH

  task automatic bfm_reset(input int cycles = 5);
    @(negedge clk);
    rst = 1'b1;
    repeat (cycles) @(posedge clk);
    @(negedge clk);
    rst = 1'b0;
  endtask

  // ---- signals and the design under test -----------------------------------
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
    .adj_ns_i(adj_ns), .adj_fns_i(adj_fns), .adj_count_i(adj_count),
    .adj_valid_i(adj_valid), .adj_active_o(adj_active),
    .drift_ns_i(drift_ns), .drift_fns_i(drift_fns), .drift_rate_i(drift_rate),
    .drift_valid_i(drift_valid),
    .ts96_o(ts96), .ts64_o(ts64), .ts_step_o(ts_step), .pps_o(pps));

  // ---- presenting a control input ------------------------------------------
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

  // ---- watchdog ------------------------------------------------------------
  initial begin
    #3_000_000;
    $display("RESULT: FAIL (watchdog: no verdict reached)");
    $finish;
  end

// ---------------------------------------------------------------------------
// TESTBENCH CHECKING LOGIC
// ---------------------------------------------------------------------------

  // Utility to print fail and terminate
  task automatic fail(string reason);
    $display("RESULT: FAIL (%s)", reason);
    $finish;
  endtask

  // Decoding functions for F1, F2
  function automatic logic [47:0] ts96_sec(logic [95:0] ts); return ts[95:48]; endfunction
  function automatic logic [29:0] ts96_ns(logic [95:0] ts);  return ts[45:16]; endfunction
  function automatic logic [15:0] ts96_fns(logic [95:0] ts); return ts[15:0]; endfunction
  
  function automatic logic [47:0] ts64_ns(logic [63:0] ts);  return ts[63:16]; endfunction
  function automatic logic [15:0] ts64_fns(logic [63:0] ts); return ts[15:0]; endfunction

  // Convert to absolute 128-bit FNS quantities for easy delta calculation
  function automatic logic [127:0] val96_to_fns(logic [95:0] ts);
    return (128'(ts96_sec(ts)) * 1000000000 * 65536) + (128'(ts96_ns(ts)) * 65536) + 128'(ts96_fns(ts));
  endfunction

  function automatic logic [127:0] val64_to_fns(logic [63:0] ts);
    return (128'(ts64_ns(ts)) * 65536) + 128'(ts64_fns(ts));
  endfunction
  
  function automatic logic [63:0] signed_20bit_to_fns(logic [3:0] ns, logic [15:0] fns);
    logic [19:0] combined;
    combined = {ns, fns};
    return 64'(signed'(combined));
  endfunction

  // --- Checking states ---
  logic test_running = 0;
  
  logic [127:0] prev_ts96_val;
  logic [127:0] prev_ts64_val;
  logic         prev_ts96_valid;
  logic         prev_ts64_valid;

  // Expected operating parameters
  longint expected_period;
  longint expected_drift;
  int     expected_drift_rate;
  
  // Outstanding adjustment state
  longint expected_adj;
  int     adj96_rem;
  int     adj64_rem;
  int     adj_active_rem;
  logic   adj_active_in_progress;
  logic   adj_active_seen_first;

  int     drift_ctr_96;
  int     drift_ctr_64;

  logic   expect_pps;
  logic   expect_step_96;
  logic   expect_step_64;

  // To tolerate up to 4 cycles of delay for settings
  int     period_change_grace;
  int     drift_change_grace;
  
  // Track continuous pps/step assertions
  int     pps_assertions;
  int     step_assertions;
  int     expected_step_assertions;

  // Monitors
  always @(posedge clk) begin
    if (rst) begin
      prev_ts96_valid <= 0;
      prev_ts64_valid <= 0;
      
      expected_period <= 64'h66666; // 6 ns, 0x6666 fns
      expected_drift  <= 64'h00002;
      expected_drift_rate <= 5;
      
      adj96_rem <= 0;
      adj64_rem <= 0;
      adj_active_rem <= 0;
      adj_active_in_progress <= 0;
      adj_active_seen_first <= 0;
      
      drift_ctr_96 <= 0;
      drift_ctr_64 <= 0;

      period_change_grace <= 0;
      drift_change_grace <= 0;
      
      expect_pps <= 0;
      expect_step_96 <= 0;
      expect_step_64 <= 0;
      pps_assertions <= 0;
      step_assertions <= 0;
      expected_step_assertions <= 0;

      if (ts96 !== '0 || ts64 !== '0)
        fail("R2: Reset did not zero the accumulators.");
    end else if (test_running) begin
      automatic logic [127:0] curr_ts96_val = val96_to_fns(ts96);
      automatic logic [127:0] curr_ts64_val = val64_to_fns(ts64);
      
      // Checking F1: static bit format
      if (ts96[47:46] !== 2'b00) fail("F1: ts96_o format bits 47:46 are not zero.");
      
      // Checking W1: ns never reaches 1B
      if (ts96_ns(ts96) >= 1000000000) fail("W1: ts96_o ns field reached or exceeded 1 000 000 000.");
      
      // Checking W3: pps_o exactly one cycle on wrap
      if (pps) pps_assertions++;
      
      if (ts_step) step_assertions++;

      if (period_change_grace > 0) period_change_grace--;
      if (drift_change_grace > 0) drift_change_grace--;

      if (prev_ts96_valid && !expect_step_96) begin
        automatic longint delta96 = curr_ts96_val - prev_ts96_val;
        automatic logic is_drift = 0;
        automatic logic is_adj = 0;
        automatic longint expected_delta;
        
        drift_ctr_96++;
        if (drift_ctr_96 == expected_drift_rate) begin
          is_drift = 1;
          drift_ctr_96 = 0;
        end else if (drift_ctr_96 > expected_drift_rate) begin
           if (drift_change_grace == 0) fail("D2: Drift spacing violated for ts96");
           drift_ctr_96 = 1; // Resync on change
        end

        if (adj96_rem > 0) begin
           // Check if adjustment has started for this base
           // We'll optimistically consume an adjustment if it matches
           // The stricter enforcement comes from the overall count.
           is_adj = 1; 
        end
        
        expected_delta = expected_period;
        if (is_drift) expected_delta += expected_drift;
        if (is_adj)   expected_delta += expected_adj;

        if (delta96 != expected_delta) begin
           if (is_adj && delta96 == (expected_delta - expected_adj)) begin
              // Adjustment hasn't hit this base yet, wait
           end else if (period_change_grace > 0 || drift_change_grace > 0) begin
              // Pending parameter changes, forgive mismatch temporarily and attempt to resync
           end else begin
              fail($sformatf("I1/D2/A2: ts96 increment mismatch. Expected %0d, got %0d", expected_delta, delta96));
           end
        end else begin
           if (is_adj) adj96_rem--;
        end
      end
      
      if (prev_ts64_valid && !expect_step_64) begin
        automatic longint delta64 = curr_ts64_val - prev_ts64_val;
        automatic logic is_drift = 0;
        automatic logic is_adj = 0;
        automatic longint expected_delta;
        
        drift_ctr_64++;
        if (drift_ctr_64 == expected_drift_rate) begin
          is_drift = 1;
          drift_ctr_64 = 0;
        end else if (drift_ctr_64 > expected_drift_rate) begin
           if (drift_change_grace == 0) fail("D2: Drift spacing violated for ts64");
           drift_ctr_64 = 1;
        end

        if (adj64_rem > 0) is_adj = 1;
        
        expected_delta = expected_period;
        if (is_drift) expected_delta += expected_drift;
        if (is_adj)   expected_delta += expected_adj;

        if (delta64 != expected_delta) begin
           if (is_adj && delta64 == (expected_delta - expected_adj)) begin
              // Adjustment hasn't hit this base yet, wait
           end else if (period_change_grace > 0 || drift_change_grace > 0) begin
              // Pending
           end else begin
              fail($sformatf("I1/D2/A2: ts64 increment mismatch. Expected %0d, got %0d", expected_delta, delta64));
           end
        end else begin
           if (is_adj) adj64_rem--;
        end
      end

      // adj_active tracking (A3)
      if (adj_active) begin
         if (!adj_active_seen_first) begin
            adj_active_seen_first = 1;
            adj_active_in_progress = 1;
         end else if (!adj_active_in_progress) begin
            fail("A3: adj_active_o was asserted non-consecutively.");
         end
         
         if (adj_active_rem > 0) adj_active_rem--;
         else fail("A3: adj_active_o asserted for more than adj_count_i cycles.");
      end else begin
         if (adj_active_in_progress) begin
            adj_active_in_progress = 0; // finished
            if (adj_active_rem > 0) fail("A3: adj_active_o deasserted before adj_count_i cycles completed.");
         end
      end

      prev_ts96_val <= curr_ts96_val;
      prev_ts96_valid <= 1;
      prev_ts64_val <= curr_ts64_val;
      prev_ts64_valid <= 1;
      
      expect_pps <= 0;
      expect_step_96 <= 0;
      expect_step_64 <= 0;
    end
  end

  // --- Main Test Sequence ---
  initial begin
    bfm_wait(5);
    bfm_reset();
    
    test_running = 1;
    bfm_wait(20);
    
    // Check initial reset state conditions
    if (expected_period != 64'h66666) fail("R2: Period did not reset.");

    // 1. Change Period
    period_change_grace = 4;
    expected_period = 64'h88000;
    bfm_period(4'h8, 16'h8000);
    bfm_wait(10);
    
    // 2. Change Drift
    drift_change_grace = 4;
    expected_drift = -64'h00010; // -16 fns
    expected_drift_rate = 3;
    bfm_drift(4'hF, 16'hFFF0, 16'd3); // -16 fns signed
    bfm_wait(15);
    
    // 3. Offset Adjustment
    adj_active_rem = 10;
    adj96_rem = 10;
    adj64_rem = 10;
    adj_active_seen_first = 0;
    expected_step_assertions = step_assertions + 10;
    expected_adj = signed_20bit_to_fns(4'h1, 16'h0000); // +1 ns per cycle
    bfm_adjust(4'h1, 16'h0000, 16'd10);
    
    bfm_wait(20); // wait out the adjustment and latency
    if (adj96_rem != 0 || adj64_rem != 0 || adj_active_rem != 0) fail("A2/A3: Offset adjustment counts were not fully exhausted.");
    if (step_assertions != expected_step_assertions) fail("A4: ts_step_o not asserted exactly adj_count_i times during adjustment.");

    // 4. Set Time Base 96
    expected_step_assertions = step_assertions + 1;
    expect_step_96 = 1;
    bfm_set96(48'h0, 30'h3B9ACA00 - 30'd20, 16'h0); // Set close to 1 sec to trigger wrap soon
    bfm_wait(5);
    if (step_assertions != expected_step_assertions) fail("S3: ts_step_o not asserted exactly once for set_ts96.");

    // 5. Set Time Base 64
    expected_step_assertions = step_assertions + 1;
    expect_step_64 = 1;
    bfm_set64(48'h0, 16'h0);
    bfm_wait(5);
    if (step_assertions != expected_step_assertions) fail("S3: ts_step_o not asserted exactly once for set_ts64.");
    
    // 6. Test Wrap (W1, W3)
    // We set ts96 close to 1s earlier, let it run out the clock
    bfm_wait(30); 
    if (pps_assertions != 1) fail("W3: pps_o was not asserted exactly once during the 1-second wrap.");

    $display("RESULT: PASS");
    $finish;
  end

endmodule