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

  initial begin
    #3_000_000;
    $display("RESULT: FAIL (watchdog: no verdict reached)");
    $finish;
  end

// ---------------------------------------------------------------------------
// TESTBENCH CHECKING LOGIC
// ---------------------------------------------------------------------------

  typedef logic signed [63:0] delta_t;

  // Expected parameters for our test sequence
  int expect_p = 0;          // 0 for default 6.4ns, 1 for 7.0ns
  int expect_d = 0;          // 0 for default +2fns, 1 for -5fns
  int active_rate = 5;
  int allow_p_transition = 0;
  int allow_d_transition = 0;

  // Base state tracking
  int dr_count[2] = '{0, 0};
  int dr_phase_locked[2] = '{0, 0};
  int adj_seen[2] = '{0, 0};
  int in_adj[2] = '{0, 0};
  int adj_blocks[2] = '{0, 0};

  // Global counts for outputs
  int adj_active_count = 0;
  int adj_active_blocks = 0;
  int step_alone_count = 0;
  int ts_step_count = 0;
  int pps_count = 0;

  int cyc_rst = 0;
  int cyc_set96 = 100;
  int cyc_set64 = 100;
  logic prev_adj_active = 0;

  logic [63:0] ts64_prev = 0;
  logic [47:0] prev_ts96_sec = 0;
  logic [29:0] prev_ts96_ns = 0;
  logic [15:0] prev_ts96_fns = 0;

  task automatic FAIL(input string msg);
    $display("RESULT: FAIL (%s)", msg);
    $finish;
  endtask

  // Decodes a raw 64-bit signed increment into its component pieces.
  // Because our test values are chosen carefully, there is zero overlap between
  // any valid combination of period, drift, and adjustment.
  function automatic void decode_delta(
    input delta_t d,
    output logic found,
    output logic is_p0, output logic is_p1,
    output logic has_d0, output logic has_d1,
    output logic has_a1
  );
    delta_t p_vals[2]; 
    delta_t d_vals[3];
    delta_t a_vals[2];
    
    found = 0; is_p0 = 0; is_p1 = 0; has_d0 = 0; has_d1 = 0; has_a1 = 0;
    
    p_vals[0] = 419430; // 6.4ns = 6*65536 + 26214
    p_vals[1] = 458752; // 7.0ns = 7*65536
    
    d_vals[0] = 0;
    d_vals[1] = 2;
    d_vals[2] = -5;
    
    a_vals[0] = 0;
    a_vals[1] = 327680; // 5ns = 5*65536
    
    for (int p=0; p<2; p++) begin
      for (int dr=0; dr<3; dr++) begin
        for (int a=0; a<2; a++) begin
          if (d == p_vals[p] + d_vals[dr] + a_vals[a]) begin
            found = 1;
            if (p==0) is_p0 = 1;
            if (p==1) is_p1 = 1;
            if (dr==1) has_d0 = 1;
            if (dr==2) has_d1 = 1;
            if (a==1) has_a1 = 1;
            return;
          end
        end
      end
    end
  endfunction

  task automatic check_base(input int base_idx, input delta_t d);
    logic found, is_p0, is_p1, has_d0, has_d1, has_a1;
    decode_delta(d, found, is_p0, is_p1, has_d0, has_d1, has_a1);
    
    if (!found) FAIL("I1: Invalid increment value observed");
    
    if (!allow_p_transition) begin
      if (expect_p == 0 && !is_p0) FAIL("I2: Period did not match expected P0");
      if (expect_p == 1 && !is_p1) FAIL("I2: Period did not match expected P1");
    end
    
    if (!allow_d_transition) begin
      if (expect_d == 0 && has_d1) FAIL("D1: Saw D1 but expected D0");
      if (expect_d == 1 && has_d0) FAIL("D1: Saw D0 but expected D1");
    end
    
    // Adjustment tracking (A2)
    if (has_a1) begin
      adj_seen[base_idx] = adj_seen[base_idx] + 1;
      if (!in_adj[base_idx]) begin
        in_adj[base_idx] = 1;
        adj_blocks[base_idx] = adj_blocks[base_idx] + 1;
      end
    end else begin
      if (in_adj[base_idx]) in_adj[base_idx] = 0;
    end
    
    // Drift tracking (D2)
    if (allow_d_transition) begin
      dr_phase_locked[base_idx] = 0;
      dr_count[base_idx] = 0;
    end else begin
      dr_count[base_idx] = dr_count[base_idx] + 1;
      if (has_d0 || has_d1) begin
        if (dr_phase_locked[base_idx]) begin
          if (dr_count[base_idx] != active_rate) FAIL("D2: drift spacing wrong");
        end else begin
          dr_phase_locked[base_idx] = 1;
        end
        dr_count[base_idx] = 0;
      end else begin
        if (dr_phase_locked[base_idx] && dr_count[base_idx] >= active_rate) FAIL("D2: missed drift");
      end
    end
  endtask

  always @(negedge clk) begin
    if (rst) begin
      cyc_rst = 0;
      dr_phase_locked[0] = 0;
      dr_phase_locked[1] = 0;
      dr_count[0] = 0;
      dr_count[1] = 0;
      in_adj[0] = 0;
      in_adj[1] = 0;
    end else begin
      cyc_rst = cyc_rst + 1;
    end
    
    if (set_ts96_valid) cyc_set96 = 0;
    else if (!rst) cyc_set96 = cyc_set96 + 1;
    
    if (set_ts64_valid) cyc_set64 = 0;
    else if (!rst) cyc_set64 = cyc_set64 + 1;
    
    if (!rst) begin
      automatic logic [47:0] ts96_sec;
      automatic logic [29:0] ts96_ns;
      automatic logic [15:0] ts96_fns;
      automatic int valid96;
      automatic int valid64;
      
      ts96_sec = ts96[95:48];
      ts96_ns  = ts96[45:16];
      ts96_fns = ts96[15:0];
      
      valid96 = (cyc_rst >= 9) && (cyc_set96 >= 5);
      valid64 = (cyc_rst >= 9) && (cyc_set64 >= 5);
      
      if (valid96) begin
        automatic delta_t d96;
        automatic logic wrap;
        
        wrap = 0;
        if (ts96_ns < prev_ts96_ns) begin
          wrap = 1;
          d96 = {1'b0, ts96_ns, ts96_fns} + (64'd1000000000 * 64'd65536) - {1'b0, prev_ts96_ns, prev_ts96_fns};
          if (ts96_sec != prev_ts96_sec + 1) FAIL("W1: sec did not increment by 1 on wrap");
        end else begin
          d96 = {1'b0, ts96_ns, ts96_fns} - {1'b0, prev_ts96_ns, prev_ts96_fns};
          if (ts96_sec != prev_ts96_sec) FAIL("W1: sec changed without wrap");
        end
        
        if (wrap) begin
          if (!pps) FAIL("W3: pps not asserted on wrap cycle");
        end else begin
          if (pps && cyc_set96 > 5) FAIL("W3: pps asserted without wrap"); 
        end
        
        check_base(0, d96);
        
        if (cyc_rst == 9) begin
          if (ts96_sec != 0 || ts96_ns > 1000) FAIL("R2: ts96 did not reset to near zero");
        end
      end
      
      if (valid64) begin
        automatic delta_t d64;
        d64 = ts64 - ts64_prev;
        check_base(1, d64);
        
        if (cyc_rst == 9) begin
          if (ts64 > (64'd1000 * 64'd65536)) FAIL("R2: ts64 did not reset to near zero");
        end
      end
      
      if (adj_active && !prev_adj_active) adj_active_blocks = adj_active_blocks + 1;
      if (adj_active) adj_active_count = adj_active_count + 1;
      if (ts_step && !adj_active) step_alone_count = step_alone_count + 1;
      if (ts_step) ts_step_count = ts_step_count + 1;
      if (adj_active && !ts_step) FAIL("A4: adj_active asserted but ts_step not");
      if (pps) pps_count = pps_count + 1;
      
      ts64_prev = ts64;
      prev_ts96_sec = ts96[95:48];
      prev_ts96_ns  = ts96[45:16];
      prev_ts96_fns = ts96[15:0];
    end
    prev_adj_active = adj_active;
  end

// ---------------------------------------------------------------------------
// STIMULUS
// ---------------------------------------------------------------------------

  initial begin
    // Step 1: Warm-up and default state check
    bfm_reset(5);
    bfm_wait(20);
    
    // Step 2: Change period to 7.0ns
    allow_p_transition = 1;
    bfm_period(4'h7, 16'h0000);
    bfm_wait(15);
    expect_p = 1;
    allow_p_transition = 0;
    bfm_wait(20);
    
    // Step 3: Counted adjustment (5ns, 10 counts)
    bfm_adjust(4'h5, 16'h0000, 10);
    bfm_wait(30); 
    
    // Step 4: Change drift to -5fns, rate 3
    allow_d_transition = 1;
    bfm_drift(4'hF, 16'hFFFB, 3); // 20'hFFFFB = -5 signed
    bfm_wait(15);
    expect_d = 1;
    active_rate = 3;
    allow_d_transition = 0;
    bfm_wait(20);
    
    // Step 5: Set96 to just before 1s wrap
    bfm_set96(48'd10, 30'd999_999_850, 16'd0);
    bfm_wait(50); // wrap will occur around +22 cycles
    if (step_alone_count != 1) FAIL("S3: ts_step_o not asserted exactly once for set96");
    if (pps_count != 1) FAIL("W3: pps_o did not fire exactly once");
    
    // Step 6: Set64 and verify independence
    bfm_set64(48'd500, 16'd0);
    bfm_wait(30);
    if (step_alone_count != 2) FAIL("S3: ts_step_o not asserted exactly once for set64");
    
    // Verification of events before reset clears them
    if (adj_seen[0] != 10) FAIL("A2: ts96 didn't see exactly 10 adjustments");
    if (adj_seen[1] != 10) FAIL("A2: ts64 didn't see exactly 10 adjustments");
    if (adj_blocks[0] != 1) FAIL("A2: ts96 adjustment not consecutive");
    if (adj_blocks[1] != 1) FAIL("A2: ts64 adjustment not consecutive");
    if (adj_active_count != 10) FAIL("A3: adj_active_o not asserted exactly 10 times");
    if (adj_active_blocks != 1) FAIL("A3: adj_active_o not consecutive");
    
    // Step 7: Issue large adjustment, then reset to test cancellation (R2)
    bfm_adjust(4'h5, 16'h0000, 1000);
    bfm_wait(3); // allow valid to register and possibly apply a few increments
    
    allow_p_transition = 1;
    allow_d_transition = 1;
    bfm_reset(5);
    // Reset immediately restores parameters
    expect_p = 0;
    expect_d = 0;
    active_rate = 5;
    allow_p_transition = 0;
    allow_d_transition = 0;
    
    begin
      automatic int adj_96_after = adj_seen[0];
      automatic int adj_64_after = adj_seen[1];
      
      bfm_wait(20); // allow normal counting to resume
      
      if (adj_seen[0] != adj_96_after) FAIL("R2: adjustment was not cancelled by reset (ts96)");
      if (adj_seen[1] != adj_64_after) FAIL("R2: adjustment was not cancelled by reset (ts64)");
    end
    
    $display("RESULT: PASS");
    $finish;
  end

endmodule