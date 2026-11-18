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
    .adj_ns_i(adj_ns), .adj_fns_i(adj_fns), .adj_count_i(adj_count),
    .adj_valid_i(adj_valid), .adj_active_o(adj_active),
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
  // Local constants and helpers
  // ---------------------------------------------------------------------------
  localparam logic [127:0] FNS_PER_NS = 128'd65536;
  localparam logic [127:0] NSEC_FNS   = 128'd65536000000000;
  localparam logic [127:0] NSEC       = 128'd1000000000;

  task automatic fail(input string msg);
    $display("RESULT: FAIL (%s)", msg);
    $finish;
  endtask

  function automatic logic [127:0] get_total96();
    logic [127:0] t;
    logic [47:0] sec;
    logic [29:0] ns;
    logic [15:0] fns;
    sec = ts96[95:48];
    ns  = ts96[45:16];
    fns = ts96[15:0];
    t = sec;
    t = t * NSEC_FNS;
    t = t + (ns * FNS_PER_NS);
    t = t + fns;
    return t;
  endfunction

  function automatic logic [127:0] get_total64();
    logic [127:0] t;
    logic [47:0] ns;
    logic [15:0] fns;
    ns  = ts64[63:16];
    fns = ts64[15:0];
    t = ns;
    t = t * FNS_PER_NS;
    t = t + fns;
    return t;
  endfunction

  task automatic wait_neg(input int n);
    repeat (n) @(negedge clk);
  endtask

  // Global format and wrap-format checks
  always @(negedge clk) begin
    if (!rst) begin
      if (ts96[47:46] != 2'b00)
        fail("F1: ts96 reserved bits are not 2'b00");
      if (ts96[45:16] >= 30'd1000000000)
        fail("W1: ts96 ns field reached or exceeded 1e9");
    end
  end

  // ---------------------------------------------------------------------------
  // Test: default period and default drift after reset
  // ---------------------------------------------------------------------------
  task automatic test_default();
    automatic logic signed [127:0] P = 128'sd419430; // 6 ns + 0x6666 fns
    automatic logic signed [127:0] D = 128'sd2;      // default drift
    automatic logic signed [127:0] prev96, prev64, curr96, curr64, d96, d64;
    automatic int i, cnt96, cnt64, first96, second96, first64, second64;

    bfm_reset(5);
    wait_neg(8); // cycles 1..8 are warm-up; start at cycle 9

    prev96 = get_total96();
    prev64 = get_total64();
    cnt96 = 0; cnt64 = 0;
    first96 = -1; second96 = -1;
    first64 = -1; second64 = -1;

    for (i = 0; i < 10; i = i + 1) begin
      @(negedge clk);
      curr96 = get_total96();
      curr64 = get_total64();
      d96 = curr96 - prev96;
      d64 = curr64 - prev64;

      if (d96 != P && d96 != P + D)
        fail("I2/R2: default period/drift 96 delta unexpected");
      if (d64 != P && d64 != P + D)
        fail("I2/R2: default period/drift 64 delta unexpected");

      if (d96 == P + D) begin
        if (cnt96 == 0) first96 = i;
        else if (cnt96 == 1) second96 = i;
        cnt96 = cnt96 + 1;
      end
      if (d64 == P + D) begin
        if (cnt64 == 0) first64 = i;
        else if (cnt64 == 1) second64 = i;
        cnt64 = cnt64 + 1;
      end

      if (pps)       fail("W3: pps asserted without wrap");
      if (ts_step)   fail("S3/A4: ts_step asserted unexpectedly");
      if (adj_active) fail("A3: adj_active asserted unexpectedly");

      prev96 = curr96;
      prev64 = curr64;
    end

    if (cnt96 != 2 || second96 - first96 != 5)
      fail("D2/R2: default drift spacing 96");
    if (cnt64 != 2 || second64 - first64 != 5)
      fail("D2/R2: default drift spacing 64");
  endtask

  // ---------------------------------------------------------------------------
  // Test: period replacement, negative drift, and latching of both
  // ---------------------------------------------------------------------------
  task automatic test_period_drift();
    automatic logic signed [127:0] P = 128'sd725556; // 11 ns + 0x1234
    automatic logic signed [127:0] D = -128'sd65536; // -1 ns
    automatic logic signed [127:0] prev96, prev64, curr96, curr64, d96, d64;
    automatic int i, cnt96, cnt64;
    automatic int first96, second96, third96;
    automatic int first64, second64, third64;

    bfm_reset(5);
    wait_neg(8);

    bfm_period(4'd11, 16'h1234);
    period_ns = 4'd0; period_fns = 16'h0000; // decoy after valid

    bfm_drift(4'hF, 16'h0000, 16'd7); // -1 ns, rate 7
    drift_ns = 4'd0; drift_fns = 16'h0000; drift_rate = 16'd2; // decoy

    wait_neg(9); // allow L1 latency

    prev96 = get_total96();
    prev64 = get_total64();
    cnt96 = 0; cnt64 = 0;
    first96 = -1; second96 = -1; third96 = -1;
    first64 = -1; second64 = -1; third64 = -1;

    for (i = 0; i < 21; i = i + 1) begin // 3 * rate
      @(negedge clk);
      curr96 = get_total96();
      curr64 = get_total64();
      d96 = curr96 - prev96;
      d64 = curr64 - prev64;

      if (d96 != P && d96 != P + D)
        fail("I2/D3: period/drift 96 delta unexpected");
      if (d64 != P && d64 != P + D)
        fail("I2/D3: period/drift 64 delta unexpected");

      if (d96 == P + D) begin
        if (cnt96 == 0) first96 = i;
        else if (cnt96 == 1) second96 = i;
        else if (cnt96 == 2) third96 = i;
        cnt96 = cnt96 + 1;
      end
      if (d64 == P + D) begin
        if (cnt64 == 0) first64 = i;
        else if (cnt64 == 1) second64 = i;
        else if (cnt64 == 2) third64 = i;
        cnt64 = cnt64 + 1;
      end

      if (pps)       fail("W3: pps unexpected");
      if (ts_step)   fail("S3: ts_step unexpected");
      if (adj_active) fail("A3: adj_active unexpected");

      prev96 = curr96;
      prev64 = curr64;
    end

    if (cnt96 != 3 || second96 - first96 != 7 || third96 - second96 != 7)
      fail("D2: drift spacing 96");
    if (cnt64 != 3 || second64 - first64 != 7 || third64 - second64 != 7)
      fail("D2: drift spacing 64");
  endtask

  // ---------------------------------------------------------------------------
  // Test: positive counted offset adjustment, latch, active, and step
  // ---------------------------------------------------------------------------
  task automatic test_adj_pos();
    automatic logic signed [127:0] P = 128'sd655360; // 10 ns
    automatic logic signed [127:0] A = 128'sd200704; // 3 ns + 0x1000
    automatic logic signed [127:0] prev96, prev64, curr96, curr64, d96, d64;
    automatic int i, N;
    automatic int cnt96, cnt64, first96, last96, first64, last64;
    automatic int act_cnt, act_first, act_last;

    bfm_reset(5);
    wait_neg(8);

    bfm_period(4'd10, 16'h0000);
    bfm_drift(4'd0, 16'h0000, 16'd5); // drift = 0
    wait_neg(9);

    @(negedge clk);
    adj_ns = 4'd3; adj_fns = 16'h1000; adj_count = 16'd5; adj_valid = 1'b1;
    prev96 = get_total96();
    prev64 = get_total64();

    @(negedge clk);
    adj_valid = 1'b0;
    adj_ns = 4'd1; adj_fns = 16'h0000; adj_count = 16'd1; // decoy

    N = 8 + 5 + 8;
    cnt96 = 0; cnt64 = 0;
    first96 = -1; last96 = -1;
    first64 = -1; last64 = -1;
    act_cnt = 0; act_first = -1; act_last = -1;

    for (i = 0; i < N; i = i + 1) begin
      if (i > 0) @(negedge clk);
      curr96 = get_total96();
      curr64 = get_total64();
      d96 = curr96 - prev96;
      d64 = curr64 - prev64;

      if (d96 != P && d96 != P + A)
        fail("A2/I1: adj 96 delta unexpected");
      if (d64 != P && d64 != P + A)
        fail("A2/I1: adj 64 delta unexpected");

      if (d96 == P + A) begin
        if (cnt96 == 0) first96 = i;
        last96 = i;
        cnt96 = cnt96 + 1;
      end
      if (d64 == P + A) begin
        if (cnt64 == 0) first64 = i;
        last64 = i;
        cnt64 = cnt64 + 1;
      end

      if (adj_active) begin
        if (act_cnt == 0) act_first = i;
        act_last = i;
        act_cnt = act_cnt + 1;
      end

      if (ts_step != adj_active)
        fail("A4: ts_step != adj_active during adj");
      if (pps)
        fail("W3: pps unexpected during adj");

      prev96 = curr96;
      prev64 = curr64;
    end

    if (cnt96 != 5 || last96 - first96 + 1 != 5)
      fail("A2: adj count/consecutive 96");
    if (cnt64 != 5 || last64 - first64 + 1 != 5)
      fail("A2: adj count/consecutive 64");
    if (act_cnt != 5 || act_last - act_first + 1 != 5)
      fail("A3: adj_active count/consecutive");
  endtask

  // ---------------------------------------------------------------------------
  // Test: negative counted offset adjustment (signed)
  // ---------------------------------------------------------------------------
  task automatic test_adj_neg();
    automatic logic signed [127:0] P = 128'sd655360; // 10 ns
    automatic logic signed [127:0] A = -128'sd131072; // -2 ns
    automatic logic signed [127:0] prev96, prev64, curr96, curr64, d96, d64;
    automatic int i, N;
    automatic int cnt96, cnt64, first96, last96, first64, last64;
    automatic int act_cnt, act_first, act_last;

    bfm_reset(5);
    wait_neg(8);

    bfm_period(4'd10, 16'h0000);
    bfm_drift(4'd0, 16'h0000, 16'd5);
    wait_neg(9);

    @(negedge clk);
    adj_ns = 4'hE; adj_fns = 16'h0000; adj_count = 16'd4; adj_valid = 1'b1;
    prev96 = get_total96();
    prev64 = get_total64();

    @(negedge clk);
    adj_valid = 1'b0;
    adj_ns = 4'd1; adj_fns = 16'h0000; adj_count = 16'd1;

    N = 8 + 4 + 8;
    cnt96 = 0; cnt64 = 0;
    first96 = -1; last96 = -1;
    first64 = -1; last64 = -1;
    act_cnt = 0; act_first = -1; act_last = -1;

    for (i = 0; i < N; i = i + 1) begin
      if (i > 0) @(negedge clk);
      curr96 = get_total96();
      curr64 = get_total64();
      d96 = curr96 - prev96;
      d64 = curr64 - prev64;

      if (d96 != P && d96 != P + A)
        fail("A5/I1: negative adj 96 delta unexpected");
      if (d64 != P && d64 != P + A)
        fail("A5/I1: negative adj 64 delta unexpected");

      if (d96 == P + A) begin
        if (cnt96 == 0) first96 = i;
        last96 = i;
        cnt96 = cnt96 + 1;
      end
      if (d64 == P + A) begin
        if (cnt64 == 0) first64 = i;
        last64 = i;
        cnt64 = cnt64 + 1;
      end

      if (adj_active) begin
        if (act_cnt == 0) act_first = i;
        act_last = i;
        act_cnt = act_cnt + 1;
      end

      if (ts_step != adj_active)
        fail("A4: ts_step != adj_active during negative adj");
      if (pps)
        fail("W3: pps unexpected during negative adj");

      prev96 = curr96;
      prev64 = curr64;
    end

    if (cnt96 != 4 || last96 - first96 + 1 != 4)
      fail("A2: negative adj count/consecutive 96");
    if (cnt64 != 4 || last64 - first64 + 1 != 4)
      fail("A2: negative adj count/consecutive 64");
    if (act_cnt != 4 || act_last - act_first + 1 != 4)
      fail("A3: negative adj_active count/consecutive");
  endtask

  // ---------------------------------------------------------------------------
  // Test: drift latch and spacing per base
  // ---------------------------------------------------------------------------
  task automatic test_drift_latch();
    automatic logic signed [127:0] P = 128'sd524288; // 8 ns
    automatic logic signed [127:0] D = 128'sd65536;  // +1 ns
    automatic logic signed [127:0] prev96, prev64, curr96, curr64, d96, d64;
    automatic int i, cnt96, cnt64;
    automatic int first96, second96, third96;
    automatic int first64, second64, third64;

    bfm_reset(5);
    wait_neg(8);

    bfm_period(4'd8, 16'h0000);
    period_ns = 4'd0; period_fns = 16'h0000; // decoy
    wait_neg(9);

    bfm_drift(4'd1, 16'h0000, 16'd6); // +1 ns, rate 6
    drift_ns = 4'd0; drift_fns = 16'h0000; drift_rate = 16'd2; // decoy
    wait_neg(9);

    prev96 = get_total96();
    prev64 = get_total64();
    cnt96 = 0; cnt64 = 0;
    first96 = -1; second96 = -1; third96 = -1;
    first64 = -1; second64 = -1; third64 = -1;

    for (i = 0; i < 18; i = i + 1) begin // 3 * rate
      @(negedge clk);
      curr96 = get_total96();
      curr64 = get_total64();
      d96 = curr96 - prev96;
      d64 = curr64 - prev64;

      if (d96 != P && d96 != P + D)
        fail("D1/D3: drift 96 delta unexpected");
      if (d64 != P && d64 != P + D)
        fail("D1/D3: drift 64 delta unexpected");

      if (d96 == P + D) begin
        if (cnt96 == 0) first96 = i;
        else if (cnt96 == 1) second96 = i;
        else if (cnt96 == 2) third96 = i;
        cnt96 = cnt96 + 1;
      end
      if (d64 == P + D) begin
        if (cnt64 == 0) first64 = i;
        else if (cnt64 == 1) second64 = i;
        else if (cnt64 == 2) third64 = i;
        cnt64 = cnt64 + 1;
      end

      if (pps)       fail("W3: pps unexpected");
      if (ts_step)   fail("S3: ts_step unexpected");
      if (adj_active) fail("A3: adj_active unexpected");

      prev96 = curr96;
      prev64 = curr64;
    end

    if (cnt96 != 3 || second96 - first96 != 6 || third96 - second96 != 6)
      fail("D2: drift spacing 96");
    if (cnt64 != 3 || second64 - first64 != 6 || third64 - second64 != 6)
      fail("D2: drift spacing 64");
  endtask

  // ---------------------------------------------------------------------------
  // Test: setting each base, ts_step, and independence
  // ---------------------------------------------------------------------------
  task automatic test_set();
    automatic logic signed [127:0] P = 128'sd458752; // 7 ns
    automatic logic signed [127:0] prev96, curr96, d96;
    automatic logic signed [127:0] prev64, curr64, d64;
    automatic logic [95:0] setval96;
    automatic logic [63:0] setval64;
    automatic int i;

    bfm_reset(5);
    wait_neg(8);

    bfm_period(4'd7, 16'h0000);
    bfm_drift(4'd0, 16'h0000, 16'd5); // drift = 0
    wait_neg(9);

    // ---- set ts96 ----
    setval96 = {48'd0, 2'b00, 30'd100, 16'h1234};

    @(negedge clk);
    set_ts96 = setval96;
    set_ts96_valid = 1'b1;
    prev64 = get_total64();

    @(negedge clk);
    set_ts96_valid = 1'b0;

    if (ts96 !== setval96)
      fail("S1: set_ts96 value not visible immediately");
    if (ts_step !== 1'b1)
      fail("S3: ts_step not asserted on set96");

    curr64 = get_total64();
    d64 = curr64 - prev64;
    if (d64 != P)
      fail("S4: ts64 disturbed by set96");

    @(negedge clk);
    if (ts_step !== 1'b0)
      fail("S3: ts_step longer than one cycle after set96");

    wait_neg(5); // past X2c warm-up
    prev96 = get_total96();
    for (i = 0; i < 5; i = i + 1) begin
      @(negedge clk);
      curr96 = get_total96();
      d96 = curr96 - prev96;
      if (d96 != P)
        fail("S1/X2c: ts96 advance after set96");
      if (ts_step)
        fail("S3: ts_step unexpected after set96");
      prev96 = curr96;
    end

    // ---- set ts64 ----
    setval64 = {48'd123456789, 16'hABCD};

    @(negedge clk);
    set_ts64 = setval64;
    set_ts64_valid = 1'b1;
    prev96 = get_total96();

    @(negedge clk);
    set_ts64_valid = 1'b0;

    if (ts64 !== setval64)
      fail("S2: set_ts64 value not visible immediately");
    if (ts_step !== 1'b1)
      fail("S3: ts_step not asserted on set64");

    curr96 = get_total96();
    d96 = curr96 - prev96;
    if (d96 != P)
      fail("S4: ts96 disturbed by set64");

    @(negedge clk);
    if (ts_step !== 1'b0)
      fail("S3: ts_step longer than one cycle after set64");

    wait_neg(5);
    prev64 = get_total64();
    for (i = 0; i < 5; i = i + 1) begin
      @(negedge clk);
      curr64 = get_total64();
      d64 = curr64 - prev64;
      if (d64 != P)
        fail("S2/X2c: ts64 advance after set64");
      if (ts_step)
        fail("S3: ts_step unexpected after set64");
      prev64 = curr64;
    end
  endtask

  // ---------------------------------------------------------------------------
  // Test: reset returns to defaults and cancels adjustment
  // ---------------------------------------------------------------------------
  task automatic test_reset();
    automatic logic signed [127:0] Pdef = 128'sd419430;
    automatic logic signed [127:0] Ddef = 128'sd2;
    automatic logic signed [127:0] prev96, prev64, curr96, curr64, d96, d64;
    automatic int i, cnt96, cnt64, first96, second96, first64, second64;

    bfm_reset(5);
    wait_neg(8);

    bfm_period(4'd12, 16'h0000);
    bfm_drift(4'd1, 16'h0000, 16'd3);
    wait_neg(9);

    bfm_set96(48'd12345, 30'd500000000, 16'h0000);
    bfm_set64(48'd123456789, 16'h0000);

    @(negedge clk);
    adj_ns = 4'd2; adj_fns = 16'h0000; adj_count = 16'd100; adj_valid = 1'b1;
    @(negedge clk);
    adj_valid = 1'b0;

    wait_neg(5);

    bfm_reset(5);
    wait_neg(8);

    if (ts96[95:48] != 48'd0)
      fail("R2: ts96 seconds not reset");
    if (ts96[45:16] > 30'd1000)
      fail("R2: ts96 ns not reset");
    if (ts64[63:16] > 48'd1000)
      fail("R2: ts64 ns not reset");

    prev96 = get_total96();
    prev64 = get_total64();
    cnt96 = 0; cnt64 = 0;
    first96 = -1; second96 = -1;
    first64 = -1; second64 = -1;

    for (i = 0; i < 10; i = i + 1) begin
      @(negedge clk);
      curr96 = get_total96();
      curr64 = get_total64();
      d96 = curr96 - prev96;
      d64 = curr64 - prev64;

      if (d96 != Pdef && d96 != Pdef + Ddef)
        fail("R2: default period/drift 96 after reset");
      if (d64 != Pdef && d64 != Pdef + Ddef)
        fail("R2: default period/drift 64 after reset");

      if (d96 == Pdef + Ddef) begin
        if (cnt96 == 0) first96 = i;
        else if (cnt96 == 1) second96 = i;
        cnt96 = cnt96 + 1;
      end
      if (d64 == Pdef + Ddef) begin
        if (cnt64 == 0) first64 = i;
        else if (cnt64 == 1) second64 = i;
        cnt64 = cnt64 + 1;
      end

      if (adj_active) fail("R2: adj_active not cancelled by reset");
      if (ts_step)    fail("R2: ts_step asserted after reset");
      if (pps)        fail("R2: pps asserted after reset");

      prev96 = curr96;
      prev64 = curr64;
    end

    if (cnt96 != 2 || second96 - first96 != 5)
      fail("R2: default drift spacing 96 after reset");
    if (cnt64 != 2 || second64 - first64 != 5)
      fail("R2: default drift spacing 64 after reset");
  endtask

  // ---------------------------------------------------------------------------
  // Test: one-second wrap, pps, and ts64 non-wrap
  // ---------------------------------------------------------------------------
  task automatic test_wrap();
    automatic logic [127:0] P = 128'd419430; // 6.4 ns
    automatic logic [127:0] prev96, curr96, prev64, curr64, d96, d64;
    automatic logic [47:0] prev_sec, curr_sec;
    automatic logic [29:0] prev_ns, curr_ns;
    automatic logic [15:0] prev_fns, curr_fns;
    automatic logic [127:0] prev_ns_fns;
    automatic int i, pps_cnt;

    bfm_reset(5);
    wait_neg(8);

    bfm_drift(4'd0, 16'h0000, 16'd5); // drift = 0
    wait_neg(9);

    bfm_set64(48'd999999960, 16'h0000);
    bfm_set96(48'd0, 30'd999999960, 16'h0000);

    wait_neg(5); // past X2c warm-up

    prev96 = get_total96();
    prev64 = get_total64();
    prev_sec = ts96[95:48];
    prev_ns  = ts96[45:16];
    prev_fns = ts96[15:0];
    prev_ns_fns = prev_ns * FNS_PER_NS + prev_fns;
    pps_cnt = 0;

    for (i = 0; i < 20; i = i + 1) begin
      @(negedge clk);
      curr96 = get_total96();
      curr64 = get_total64();
      d96 = curr96 - prev96;
      d64 = curr64 - prev64;

      curr_sec = ts96[95:48];
      curr_ns  = ts96[45:16];
      curr_fns = ts96[15:0];

      if (d96 != P)
        fail("I1/W1: ts96 increment near wrap not default period");
      if (d64 != P)
        fail("W2: ts64 increment near wrap not default period");

      if (prev_ns_fns + P >= NSEC_FNS) begin
        if (pps !== 1'b1)
          fail("W3: pps missing on wrap");
        if (curr_sec != prev_sec + 1)
          fail("W1: seconds not incremented on wrap");
        pps_cnt = pps_cnt + 1;
      end else begin
        if (pps !== 1'b0)
          fail("W3: pps asserted without wrap");
        if (curr_sec != prev_sec)
          fail("W1: seconds changed without wrap");
      end

      if (curr64 != prev64 + P)
        fail("W2: ts64 wrapped or wrong increment");

      if (ts_step)
        fail("S3: ts_step unexpected near wrap");

      prev96 = curr96;
      prev64 = curr64;
      prev_sec = curr_sec;
      prev_ns  = curr_ns;
      prev_fns = curr_fns;
      prev_ns_fns = prev_ns * FNS_PER_NS + prev_fns;
    end

    if (pps_cnt != 1)
      fail("W3: pps pulse count not exactly one");
    if (ts64[63:16] <= 48'd1000000000)
      fail("W2: ts64 did not exceed 1e9 ns (no wrap expected)");
  endtask

  // ---------------------------------------------------------------------------
  // Main test sequence
  // ---------------------------------------------------------------------------
  initial begin
    test_default();
    test_period_drift();
    test_adj_pos();
    test_adj_neg();
    test_drift_latch();
    test_set();
    test_reset();
    test_wrap();

    $display("RESULT: PASS");
    $finish;
  end

endmodule
