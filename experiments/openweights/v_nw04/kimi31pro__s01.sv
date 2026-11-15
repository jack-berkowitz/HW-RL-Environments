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
    .period_ns_i(period_ns), .period_fns_i(period_fns),
    .period_valid_i(period_valid),
    .adj_ns_i(adj_ns), .adj_fns_i(adj_fns), .adj_count_i(adj_count),
    .adj_valid_i(adj_valid), .adj_active_o(adj_active),
    .drift_ns_i(drift_ns), .drift_fns_i(drift_fns),
    .drift_rate_i(drift_rate), .drift_valid_i(drift_valid),
    .ts96_o(ts96), .ts64_o(ts64), .ts_step_o(ts_step), .pps_o(pps));

  task automatic bfm_period(input logic [3:0] ns, input logic [15:0] fns);
    @(negedge clk); period_ns = ns; period_fns = fns; period_valid = 1'b1;
    @(negedge clk); period_valid = 1'b0;
  endtask

  task automatic bfm_adjust(input logic [3:0] ns, input logic [15:0] fns,
                            input logic [15:0] count);
    @(negedge clk); adj_ns = ns; adj_fns = fns; adj_count = count;
    adj_valid = 1'b1;
    @(negedge clk); adj_valid = 1'b0;
  endtask

  task automatic bfm_drift(input logic [3:0] ns, input logic [15:0] fns,
                           input logic [15:0] rate);
    @(negedge clk); drift_ns = ns; drift_fns = fns; drift_rate = rate;
    drift_valid = 1'b1;
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

  task automatic bfm_wait(input int cycles);
    repeat (cycles) @(posedge clk);
  endtask

  initial begin
    set_ts96 = '0; set_ts96_valid = 1'b0;
    set_ts64 = '0; set_ts64_valid = 1'b0;
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
  // Exact arithmetic and checking
  // ---------------------------------------------------------------------------

  localparam longint signed BASE_INC = 64'sd419430; // 6 * 65536 + 16'h6666
  localparam longint signed NEW_PERIOD_INC = 64'sd524288; // 8 ns exactly
  localparam longint signed ONE_SECOND_FNS = 64'sd65536000000000;

  task automatic die(input string clause, input string detail);
    $display("Violation of %s: %s", clause, detail);
    $display("RESULT: FAIL");
    $finish;
  endtask

  function automatic longint signed value96(input logic [95:0] v);
    longint signed sec_part;
    longint signed ns_part;
    longint signed fns_part;
    sec_part = v[95:48];
    ns_part = v[45:16];
    fns_part = v[15:0];
    value96 = sec_part * ONE_SECOND_FNS + ns_part * 64'sd65536 + fns_part;
  endfunction

  function automatic longint signed value64(input logic [63:0] v);
    value64 = $signed(v);
  endfunction

  task automatic check_format;
    if (ts96[47:46] !== 2'b00)
      die("F1", "the two reserved ts96 bits are not zero");
    if (ts96[45:16] >= 30'd1000000000)
      die("W1/F1", "ts96 nanoseconds field reached or exceeded one second");
  endtask

  // Return from reset before cycle 1, check reset state, then skip generously
  // past the eight unconstrained warm-up cycles.
  task automatic prepare_reset;
    bfm_reset(5);
    if (ts96 !== 96'd0)
      die("R2", "96-bit base was not left at zero by reset");
    if (ts64 !== 64'd0)
      die("R2", "64-bit base was not left at zero by reset");
    if (adj_active !== 1'b0)
      die("R2/A3", "offset adjustment survived reset");
    if (ts_step !== 1'b0)
      die("A4/S3", "ts_step was asserted without an adjustment or set");
    if (pps !== 1'b0)
      die("W3", "pps was asserted without a one-second wrap");

    repeat (16) @(posedge clk);
    @(negedge clk);
  endtask

  // Check the reset period and default signed drift independently on each base.
  task automatic run_default(input int ncycles);
    logic [95:0] prev96;
    logic [63:0] prev64;
    longint signed d96;
    longint signed d64;
    int i;
    int last96;
    int last64;
    int hits96;
    int hits64;

    prev96 = ts96;
    prev64 = ts64;
    last96 = -1;
    last64 = -1;
    hits96 = 0;
    hits64 = 0;

    for (i = 0; i < ncycles; i = i + 1) begin
      @(posedge clk);
      @(negedge clk);
      check_format();

      d96 = value96(ts96) - value96(prev96);
      d64 = value64(ts64) - value64(prev64);

      if (d96 == BASE_INC) begin
        // Ordinary increment.
      end else if (d96 == BASE_INC + 64'sd2) begin
        if (last96 >= 0 && (i - last96) != 5)
          die("D2", "default drift spacing on ts96 was not five increments");
        last96 = i;
        hits96 = hits96 + 1;
      end else begin
        die("I1/I2/D3", $sformatf("illegal default ts96 increment %0d", d96));
      end

      if (d64 == BASE_INC) begin
        // Ordinary increment.
      end else if (d64 == BASE_INC + 64'sd2) begin
        if (last64 >= 0 && (i - last64) != 5)
          die("D2", "default drift spacing on ts64 was not five increments");
        last64 = i;
        hits64 = hits64 + 1;
      end else begin
        die("I1/I2/D3", $sformatf("illegal default ts64 increment %0d", d64));
      end

      if (adj_active)
        die("A3/R2", "adj_active asserted with no outstanding adjustment");
      if (ts_step)
        die("A4/S3", "unexpected ts_step during free running");
      if (pps)
        die("W3", "pps asserted without a wrap");

      prev96 = ts96;
      prev64 = ts64;
    end

    if (hits96 < ncycles / 5)
      die("D2", "too few default drift increments on ts96");
    if (hits64 < ncycles / 5)
      die("D2", "too few default drift increments on ts64");
  endtask

  // Period replacement, allowing eight cycles of independent adoption latency.
  task automatic check_period_change;
    logic [95:0] prev96;
    logic [63:0] prev64;
    longint signed d96;
    longint signed d64;
    int kind96;
    int kind64;
    int age;
    int adopt96;
    int adopt64;
    int last96;
    int last64;
    int hits96;
    int hits64;
    logic adopted96;
    logic adopted64;

    prev96 = ts96;
    prev64 = ts64;
    adopt96 = -1;
    adopt64 = -1;
    last96 = -1;
    last64 = -1;
    hits96 = 0;
    hits64 = 0;
    adopted96 = 1'b0;
    adopted64 = 1'b0;

    period_ns = 4'd8;
    period_fns = 16'd0;
    period_valid = 1'b1;

    for (age = 0; age < 50; age = age + 1) begin
      @(posedge clk);
      @(negedge clk);
      if (age == 0)
        period_valid = 1'b0;

      check_format();
      d96 = value96(ts96) - value96(prev96);
      d64 = value64(ts64) - value64(prev64);

      if (d96 == BASE_INC)
        kind96 = 0;
      else if (d96 == BASE_INC + 64'sd2)
        kind96 = 1;
      else if (d96 == NEW_PERIOD_INC)
        kind96 = 2;
      else if (d96 == NEW_PERIOD_INC + 64'sd2)
        kind96 = 3;
      else
        kind96 = -1;

      if (d64 == BASE_INC)
        kind64 = 0;
      else if (d64 == BASE_INC + 64'sd2)
        kind64 = 1;
      else if (d64 == NEW_PERIOD_INC)
        kind64 = 2;
      else if (d64 == NEW_PERIOD_INC + 64'sd2)
        kind64 = 3;
      else
        kind64 = -1;

      if (kind96 < 0)
        die("I1/I2", $sformatf("bad ts96 increment %0d after period change", d96));
      if (kind64 < 0)
        die("I1/I2", $sformatf("bad ts64 increment %0d after period change", d64));

      if (!adopted96 && kind96 >= 2) begin
        adopted96 = 1'b1;
        adopt96 = age;
      end else if (adopted96 && kind96 < 2) begin
        die("I2", "ts96 reverted to the old period");
      end

      if (!adopted64 && kind64 >= 2) begin
        adopted64 = 1'b1;
        adopt64 = age;
      end else if (adopted64 && kind64 < 2) begin
        die("I2", "ts64 reverted to the old period");
      end

      if (adopted96 && kind96 == 3) begin
        if (last96 >= 0 && age - last96 != 5)
          die("D2", "drift spacing changed when only the period was replaced");
        last96 = age;
        hits96 = hits96 + 1;
      end

      if (adopted64 && kind64 == 3) begin
        if (last64 >= 0 && age - last64 != 5)
          die("D2", "drift spacing changed on ts64 after period replacement");
        last64 = age;
        hits64 = hits64 + 1;
      end

      if (adj_active || ts_step)
        die("A3/A4/S3", "period_valid generated adjustment/step activity");
      if (pps)
        die("W3", "unexpected pps during period test");

      prev96 = ts96;
      prev64 = ts64;
    end

    if (!adopted96 || adopt96 > 8)
      die("L1/I2", "ts96 did not adopt the new period within eight cycles");
    if (!adopted64 || adopt64 > 8)
      die("L1/I2", "ts64 did not adopt the new period within eight cycles");
    if (hits96 < 4 || hits64 < 4)
      die("D2", "insufficient drift activity after period replacement");
  endtask

  // Replace drift by -1 ns with rate 7. The first visible new drift can be
  // as late as adoption cycle 8 followed by seven new-rate increments.
  task automatic check_drift_change;
    logic [95:0] prev96;
    logic [63:0] prev64;
    longint signed d96;
    longint signed d64;
    int kind96;
    int kind64;
    int age;
    int first96;
    int first64;
    int last96;
    int last64;
    int hits96;
    int hits64;
    logic saw_new96;
    logic saw_new64;

    prev96 = ts96;
    prev64 = ts64;
    first96 = -1;
    first64 = -1;
    last96 = -1;
    last64 = -1;
    hits96 = 0;
    hits64 = 0;
    saw_new96 = 1'b0;
    saw_new64 = 1'b0;

    drift_ns = 4'hf;
    drift_fns = 16'h0000;
    drift_rate = 16'd7;
    drift_valid = 1'b1;

    for (age = 0; age < 100; age = age + 1) begin
      @(posedge clk);
      @(negedge clk);
      if (age == 0)
        drift_valid = 1'b0;

      check_format();
      d96 = value96(ts96) - value96(prev96);
      d64 = value64(ts64) - value64(prev64);

      if (d96 == BASE_INC)
        kind96 = 0;
      else if (d96 == BASE_INC + 64'sd2)
        kind96 = 1;
      else if (d96 == BASE_INC - 64'sd65536)
        kind96 = 2;
      else
        kind96 = -1;

      if (d64 == BASE_INC)
        kind64 = 0;
      else if (d64 == BASE_INC + 64'sd2)
        kind64 = 1;
      else if (d64 == BASE_INC - 64'sd65536)
        kind64 = 2;
      else
        kind64 = -1;

      if (kind96 < 0)
        die("D1/D3/I1", $sformatf("bad ts96 increment %0d after drift change", d96));
      if (kind64 < 0)
        die("D1/D3/I1", $sformatf("bad ts64 increment %0d after drift change", d64));

      if (saw_new96 && kind96 == 1)
        die("D1", "old positive drift reappeared on ts96");
      if (saw_new64 && kind64 == 1)
        die("D1", "old positive drift reappeared on ts64");

      if (kind96 == 2) begin
        if (!saw_new96) begin
          saw_new96 = 1'b1;
          first96 = age;
        end else if (age - last96 != 7) begin
          die("D2", "new drift spacing on ts96 was not seven");
        end
        last96 = age;
        hits96 = hits96 + 1;
      end

      if (kind64 == 2) begin
        if (!saw_new64) begin
          saw_new64 = 1'b1;
          first64 = age;
        end else if (age - last64 != 7) begin
          die("D2", "new drift spacing on ts64 was not seven");
        end
        last64 = age;
        hits64 = hits64 + 1;
      end

      if (adj_active || ts_step)
        die("A3/A4/S3", "drift_valid generated adjustment/step activity");
      if (pps)
        die("W3", "unexpected pps during drift test");

      prev96 = ts96;
      prev64 = ts64;
    end

    if (!saw_new96 || first96 > 15)
      die("L1/D1/D2", "new drift was not visible on ts96 within the legal window");
    if (!saw_new64 || first64 > 15)
      die("L1/D1/D2", "new drift was not visible on ts64 within the legal window");
    if (hits96 < 8 || hits64 < 8)
      die("D2", "new drift did not recur at the requested rate");
  endtask

  // Install zero drift and wait beyond both bases' maximum adoption latency.
  task automatic install_zero_drift;
    logic [95:0] prev96;
    logic [63:0] prev64;
    longint signed d96;
    longint signed d64;
    int i;

    drift_ns = 4'd0;
    drift_fns = 16'd0;
    drift_rate = 16'd5;
    drift_valid = 1'b1;

    for (i = 0; i < 25; i = i + 1) begin
      @(posedge clk);
      @(negedge clk);
      if (i == 0)
        drift_valid = 1'b0;
      check_format();
      if (adj_active || ts_step)
        die("A3/A4/S3", "unexpected pulse while installing zero drift");
      if (pps)
        die("W3", "unexpected pps while installing zero drift");
    end

    prev96 = ts96;
    prev64 = ts64;
    for (i = 0; i < 12; i = i + 1) begin
      @(posedge clk);
      @(negedge clk);
      check_format();
      d96 = value96(ts96) - value96(prev96);
      d64 = value64(ts64) - value64(prev64);
      if (d96 != BASE_INC)
        die("D1/I1", "ts96 did not settle to the unadjusted period");
      if (d64 != BASE_INC)
        die("D1/I1", "ts64 did not settle to the unadjusted period");
      if (adj_active || ts_step || pps)
        die("A3/A4/W3", "unexpected status pulse in zero-drift steady state");
      prev96 = ts96;
      prev64 = ts64;
    end
  endtask

  // One counted adjustment. Each base must see exactly count consecutive
  // adjusted increments, while adj_active/ts_step alignment remains free.
  task automatic check_adjust(input logic [19:0] off20, input int count);
    logic [95:0] prev96;
    logic [63:0] prev64;
    longint signed off;
    longint signed target;
    longint signed d96;
    longint signed d64;
    int age;
    int seen96;
    int seen64;
    int start96;
    int start64;
    int active_total;
    logic started96;
    logic started64;
    logic active_closed;

    off = {{44{off20[19]}}, off20};
    target = BASE_INC + off;
    prev96 = ts96;
    prev64 = ts64;
    seen96 = 0;
    seen64 = 0;
    start96 = -1;
    start64 = -1;
    active_total = 0;
    started96 = 1'b0;
    started64 = 1'b0;
    active_closed = 1'b0;

    adj_ns = off20[19:16];
    adj_fns = off20[15:0];
    adj_count = count[15:0];
    adj_valid = 1'b1;

    for (age = 0; age < 50; age = age + 1) begin
      @(posedge clk);
      @(negedge clk);
      if (age == 0)
        adj_valid = 1'b0;

      check_format();
      d96 = value96(ts96) - value96(prev96);
      d64 = value64(ts64) - value64(prev64);

      if (!started96) begin
        if (d96 == target) begin
          started96 = 1'b1;
          start96 = age;
          seen96 = 1;
        end else if (d96 != BASE_INC) begin
          die("A2/I1", $sformatf("illegal ts96 increment %0d during adjustment", d96));
        end
      end else if (seen96 < count) begin
        if (d96 != target)
          die("A2", "ts96 adjusted increments were not consecutive or were too few");
        seen96 = seen96 + 1;
      end else if (d96 != BASE_INC) begin
        die("A2", "ts96 received too many adjusted increments");
      end

      if (!started64) begin
        if (d64 == target) begin
          started64 = 1'b1;
          start64 = age;
          seen64 = 1;
        end else if (d64 != BASE_INC) begin
          die("A2/I1", $sformatf("illegal ts64 increment %0d during adjustment", d64));
        end
      end else if (seen64 < count) begin
        if (d64 != target)
          die("A2", "ts64 adjusted increments were not consecutive or were too few");
        seen64 = seen64 + 1;
      end else if (d64 != BASE_INC) begin
        die("A2", "ts64 received too many adjusted increments");
      end

      if (ts_step !== adj_active)
        die("A4", "ts_step and adj_active differed with no set in progress");

      if (adj_active) begin
        if (active_closed)
          die("A3", "adj_active cycles were not consecutive");
        active_total = active_total + 1;
      end else if (active_total != 0) begin
        active_closed = 1'b1;
      end

      if (pps)
        die("W3", "unexpected pps during counted adjustment");

      prev96 = ts96;
      prev64 = ts64;
    end

    if (!started96 || seen96 != count)
      die("A2", "ts96 did not receive exactly adj_count adjusted increments");
    if (!started64 || seen64 != count)
      die("A2", "ts64 did not receive exactly adj_count adjusted increments");
    if (start96 > 8)
      die("L1", "ts96 began its adjustment later than eight cycles");
    if (start64 > 8)
      die("L1", "ts64 began its adjustment later than eight cycles");
    if (active_total != count)
      die("A3", "adj_active was not asserted for exactly adj_count cycles");
    if (!active_closed)
      die("A3", "adj_active did not deassert after the counted adjustment");
  endtask

  task automatic check_zero_adjust;
    logic [95:0] prev96;
    logic [63:0] prev64;
    int i;

    prev96 = ts96;
    prev64 = ts64;
    adj_ns = 4'd1;
    adj_fns = 16'd0;
    adj_count = 16'd0;
    adj_valid = 1'b1;

    for (i = 0; i < 25; i = i + 1) begin
      @(posedge clk);
      @(negedge clk);
      if (i == 0)
        adj_valid = 1'b0;
      if (value96(ts96) - value96(prev96) != BASE_INC)
        die("A2", "zero-count adjustment changed ts96");
      if (value64(ts64) - value64(prev64) != BASE_INC)
        die("A2", "zero-count adjustment changed ts64");
      if (adj_active || ts_step)
        die("A3/A4", "zero-count adjustment produced active/step pulses");
      if (pps)
        die("W3", "unexpected pps during zero-count adjustment");
      prev96 = ts96;
      prev64 = ts64;
    end
  endtask

  task automatic check_set96;
    logic [95:0] expected96;
    logic [95:0] prev96;
    logic [63:0] prev64;
    int i;

    expected96 = {48'd3, 2'b00, 30'd123456789, 16'h1234};
    prev64 = ts64;
    set_ts96 = expected96;
    set_ts96_valid = 1'b1;

    @(posedge clk);
    @(negedge clk);
    set_ts96_valid = 1'b0;

    check_format();
    if (ts96 !== expected96)
      die("S1", "set_ts96 value was not visible immediately");
    if (!ts_step)
      die("S3", "set_ts96 did not produce a one-cycle ts_step");
    if (adj_active || pps)
      die("S3/W3", "set_ts96 produced an unrelated status pulse");
    if (value64(ts64) - value64(prev64) != BASE_INC)
      die("S4", "setting ts96 disturbed ts64");

    prev96 = ts96;
    prev64 = ts64;

    for (i = 1; i <= 12; i = i + 1) begin
      @(posedge clk);
      @(negedge clk);
      check_format();
      if (ts_step)
        die("S3", "set_ts96 ts_step lasted longer than one cycle");
      if (adj_active || pps)
        die("A3/W3", "unexpected status pulse after set_ts96");
      if (value64(ts64) - value64(prev64) != BASE_INC)
        die("S4", "ts64 was disturbed after set_ts96");
      if (i >= 5 && value96(ts96) - value96(prev96) != BASE_INC)
        die("I1/X2c", "ts96 did not resume exact increments by the fifth cycle");
      prev96 = ts96;
      prev64 = ts64;
    end
  endtask

  task automatic check_set64;
    logic [63:0] expected64;
    logic [95:0] prev96;
    logic [63:0] prev64;
    int i;

    expected64 = {48'd987654321, 16'habcd};
    prev96 = ts96;
    set_ts64 = expected64;
    set_ts64_valid = 1'b1;

    @(posedge clk);
    @(negedge clk);
    set_ts64_valid = 1'b0;

    if (ts64 !== expected64)
      die("S2", "set_ts64 value was not visible immediately");
    if (!ts_step)
      die("S3", "set_ts64 did not produce a one-cycle ts_step");
    if (adj_active || pps)
      die("S3/W3", "set_ts64 produced an unrelated status pulse");
    if (value96(ts96) - value96(prev96) != BASE_INC)
      die("S4", "setting ts64 disturbed ts96");

    prev96 = ts96;
    prev64 = ts64;

    for (i = 1; i <= 12; i = i + 1) begin
      @(posedge clk);
      @(negedge clk);
      check_format();
      if (ts_step)
        die("S3", "set_ts64 ts_step lasted longer than one cycle");
      if (adj_active || pps)
        die("A3/W3", "unexpected status pulse after set_ts64");
      if (value96(ts96) - value96(prev96) != BASE_INC)
        die("S4", "ts96 was disturbed after set_ts64");
      if (i >= 5 && value64(ts64) - value64(prev64) != BASE_INC)
        die("I1/X2c", "ts64 did not resume exact increments by the fifth cycle");
      prev96 = ts96;
      prev64 = ts64;
    end
  endtask

  // Put the wrap beyond the four-cycle set warm-up for an ordinary pipeline,
  // but tolerate a wrap during that warm-up as required by X2c.
  task automatic check_wrap96;
    logic [95:0] expected96;
    logic [95:0] prev96;
    logic [63:0] prev64;
    longint signed d96;
    int i;
    int wraps;

    expected96 = {48'd7, 2'b00, 30'd999999960, 16'h0000};
    prev64 = ts64;
    set_ts96 = expected96;
    set_ts96_valid = 1'b1;

    @(posedge clk);
    @(negedge clk);
    set_ts96_valid = 1'b0;

    if (ts96 !== expected96)
      die("S1", "near-second set value was not visible immediately");
    if (!ts_step)
      die("S3", "near-second set did not raise ts_step");
    if (pps)
      die("W3", "setting ts96 near one second itself asserted pps");
    if (value64(ts64) - value64(prev64) != BASE_INC)
      die("S4", "near-second set of ts96 disturbed ts64");

    prev96 = ts96;
    prev64 = ts64;
    wraps = 0;

    for (i = 1; i <= 40; i = i + 1) begin
      @(posedge clk);
      @(negedge clk);
      check_format();

      if (ts_step)
        die("S3", "ts_step persisted after near-second set");
      if (value64(ts64) - value64(prev64) != BASE_INC)
        die("S4", "ts64 was disturbed during ts96 wrap test");

      if (ts96[95:48] == prev96[95:48]) begin
        if (pps)
          die("W3", "pps asserted without a seconds-field wrap");
      end else if (ts96[95:48] == prev96[95:48] + 48'd1) begin
        if (!pps)
          die("W3", "seconds-field wrap did not assert pps");
        wraps = wraps + 1;
      end else begin
        die("W1", "seconds field did not increase by exactly one at wrap");
      end

      if (i >= 5) begin
        d96 = value96(ts96) - value96(prev96);
        if (ts96[95:48] == prev96[95:48]) begin
          if (d96 != BASE_INC)
            die("I1/W1", "non-wrapping ts96 increment was not exact");
        end else begin
          if (d96 != BASE_INC - ONE_SECOND_FNS)
            die("W1", "wrap did not subtract exactly 1,000,000,000 ns");
        end
      end

      prev96 = ts96;
      prev64 = ts64;
    end

    if (wraps != 1)
      die("W1/W3", "expected exactly one ts96 one-second wrap");
  endtask

  task automatic check_ts64_no_wrap;
    logic [63:0] expected64;
    logic [95:0] prev96;
    logic [63:0] prev64;
    int i;

    expected64 = {48'd999999990, 16'h0000};
    prev96 = ts96;
    set_ts64 = expected64;
    set_ts64_valid = 1'b1;

    @(posedge clk);
    @(negedge clk);
    set_ts64_valid = 1'b0;

    if (ts64 !== expected64)
      die("S2", "near-second ts64 set value was not visible immediately");
    if (!ts_step)
      die("S3", "near-second ts64 set did not raise ts_step");
    if (pps)
      die("W2/W3", "setting ts64 near one second asserted pps");
    if (value96(ts96) - value96(prev96) != BASE_INC)
      die("S4", "setting ts64 disturbed ts96");

    prev96 = ts96;
    prev64 = ts64;

    for (i = 1; i <= 15; i = i + 1) begin
      @(posedge clk);
      @(negedge clk);
      check_format();
      if (ts_step)
        die("S3", "ts_step persisted after ts64 set");
      if (pps)
        die("W2/W3", "ts64 crossing one second asserted pps");
      if (value96(ts96) - value96(prev96) != BASE_INC)
        die("S4", "ts96 was disturbed during ts64 no-wrap test");
      if (i >= 5 && value64(ts64) - value64(prev64) != BASE_INC)
        die("W2/I1", "ts64 did not continue linearly through one second");
      prev96 = ts96;
      prev64 = ts64;
    end

    if (ts64[63:16] <= 48'd1000000000)
      die("W2", "ts64 wrapped or failed to pass one second");
  endtask

  initial begin : main
    // Reset defaults, exact fractional increment, and default drift cadence.
    prepare_reset();
    run_default(100);

    // Period replacement and independent per-base adoption latency.
    check_period_change();

    // Signed drift replacement and a non-default cadence.
    prepare_reset();
    check_drift_change();

    // Counted positive and negative adjustments, including exact pulse counts.
    prepare_reset();
    install_zero_drift();
    check_adjust(20'h10000, 7);  // +1 ns
    check_adjust(20'he0000, 5);  // -2 ns
    check_zero_adjust();

    // Immediate sets, one-cycle steps, warm-up, and base independence.
    check_set96();
    check_set64();

    // One-second boundary and the absence of a corresponding ts64 wrap.
    prepare_reset();
    install_zero_drift();
    check_wrap96();
    check_ts64_no_wrap();

    // Reset with a large adjustment still owed: it must be cancelled, and all
    // reset defaults, including drift value/rate, must return.
    adj_ns = 4'd1;
    adj_fns = 16'd0;
    adj_count = 16'd100;
    adj_valid = 1'b1;
    @(posedge clk);
    @(negedge clk);
    adj_valid = 1'b0;
    repeat (6) begin
      @(posedge clk);
      @(negedge clk);
    end

    prepare_reset();
    run_default(40);

    $display("RESULT: PASS");
    $finish;
  end

endmodule
