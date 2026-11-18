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
    .ts96_o(ts96), .ts64_o(ts64),
    .ts_step_o(ts_step), .pps_o(pps));

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
  // OUR CHECKING
  // ---------------------------------------------------------------------------
  localparam int MAX_CYCLES = 100000;

  int errors;

  // Registered reset, so the monitor does not race with bfm_reset changing rst
  // on a negedge.
  logic rst_q;
  always @(posedge clk) rst_q <= rst;

  // Sampled outputs, indexed by absolute bfm_cycle.
  logic [47:0] sec96_at [0:MAX_CYCLES-1];
  logic [29:0] ns96_at  [0:MAX_CYCLES-1];
  logic [15:0] fns96_at [0:MAX_CYCLES-1];
  logic [47:0] ns64_at  [0:MAX_CYCLES-1];
  logic [15:0] fns64_at [0:MAX_CYCLES-1];
  logic [127:0] total64_at [0:MAX_CYCLES-1];

  logic signed [127:0] diff96_at [0:MAX_CYCLES-1];
  logic signed [127:0] diff64_at [0:MAX_CYCLES-1];
  logic diff96_valid_at [0:MAX_CYCLES-1];
  logic diff64_valid_at [0:MAX_CYCLES-1];

  logic ts_step_at    [0:MAX_CYCLES-1];
  logic adj_active_at [0:MAX_CYCLES-1];
  logic pps_at        [0:MAX_CYCLES-1];

  // Monitor temporaries.
  logic [47:0] mon_sec96, mon_ns64;
  logic [29:0] mon_ns96;
  logic [15:0] mon_fns96, mon_fns64;
  logic [127:0] mon_total96, mon_total64;

  logic [127:0] prev_total96, prev_total64;
  logic prev_valid96, prev_valid64;
  int last_bfm_cycle;
  logic last_rst;

  function automatic logic [127:0] calc96(input logic [95:0] v);
    logic [47:0] sec;
    logic [29:0] ns;
    logic [15:0] fns;
    begin
      sec = v[95:48];
      ns  = v[45:16];
      fns = v[15:0];
      return (sec * 128'd1000000000 * 128'd65536) +
             (ns  * 128'd65536) + fns;
    end
  endfunction

  function automatic logic [127:0] calc64(input logic [63:0] v);
    logic [47:0] ns;
    logic [15:0] fns;
    begin
      ns  = v[63:16];
      fns = v[15:0];
      return (ns * 128'd65536) + fns;
    end
  endfunction

  function automatic logic signed [127:0] signed20(input logic [3:0] ns,
                                                   input logic [15:0] fns);
    logic signed [19:0] v;
    begin
      v = {ns, fns};
      return {{108{v[19]}}, v};
    end
  endfunction

  function automatic logic [127:0] period_fns(input logic [3:0] ns,
                                              input logic [15:0] fns);
    begin
      return (ns * 128'd65536) + fns;
    end
  endfunction

  always @(negedge clk) begin
    if (bfm_cycle < MAX_CYCLES) begin
      if (!rst_q) begin
        mon_sec96  = ts96[95:48];
        mon_ns96   = ts96[45:16];
        mon_fns96  = ts96[15:0];
        mon_ns64   = ts64[63:16];
        mon_fns64  = ts64[15:0];
        mon_total96 = calc96(ts96);
        mon_total64 = calc64(ts64);

        sec96_at[bfm_cycle]  = mon_sec96;
        ns96_at[bfm_cycle]   = mon_ns96;
        fns96_at[bfm_cycle]  = mon_fns96;
        ns64_at[bfm_cycle]   = mon_ns64;
        fns64_at[bfm_cycle]  = mon_fns64;
        total64_at[bfm_cycle] = mon_total64;

        ts_step_at[bfm_cycle]    = ts_step;
        adj_active_at[bfm_cycle] = adj_active;
        pps_at[bfm_cycle]        = pps;

        if (ts96[47:46] != 2'b00) begin
          errors++;
          $display("FAIL F1: ts96 bits 47:46 not zero at cycle %0d", bfm_cycle);
        end
        if (mon_ns96 >= 30'd1000000000) begin
          errors++;
          $display("FAIL W1: ts96 ns >= 1e9 at cycle %0d", bfm_cycle);
        end

        if (prev_valid96 && (bfm_cycle == last_bfm_cycle + 1) && !last_rst) begin
          diff96_at[bfm_cycle] = mon_total96 - prev_total96;
          diff96_valid_at[bfm_cycle] = 1'b1;
        end else begin
          diff96_at[bfm_cycle] = '0;
          diff96_valid_at[bfm_cycle] = 1'b0;
        end

        if (prev_valid64 && (bfm_cycle == last_bfm_cycle + 1) && !last_rst) begin
          diff64_at[bfm_cycle] = mon_total64 - prev_total64;
          diff64_valid_at[bfm_cycle] = 1'b1;
        end else begin
          diff64_at[bfm_cycle] = '0;
          diff64_valid_at[bfm_cycle] = 1'b0;
        end

        prev_total96 = mon_total96;
        prev_total64 = mon_total64;
        prev_valid96 = 1'b1;
        prev_valid64 = 1'b1;
        last_bfm_cycle = bfm_cycle;
        last_rst = 1'b0;
      end else begin
        prev_valid96 = 1'b0;
        prev_valid64 = 1'b0;
        last_rst = 1'b1;
        last_bfm_cycle = bfm_cycle;
      end
    end
  end

  task automatic check_drift_pattern(
      input int c0,
      input int c1,
      input logic [127:0] period,
      input logic signed [127:0] drift,
      input int rate,
      input bit is96,
      input string base_name);
    int i, j, n, sum, c;
    logic signed [127:0] d;
    logic signed [127:0] p_s;
    logic drift_flag[0:200];
    begin
      p_s = period;
      n = c1 - c0 + 1;
      if (n < rate) begin
        errors++;
        $display("FAIL: drift window too short for %s", base_name);
      end

      for (i = 0; i < n; i = i + 1) begin
        c = c0 + i;
        if (is96) begin
          if (!diff96_valid_at[c]) begin
            errors++;
            $display("FAIL: %s diff invalid at cycle %0d", base_name, c);
          end
          d = diff96_at[c];
        end else begin
          if (!diff64_valid_at[c]) begin
            errors++;
            $display("FAIL: %s diff invalid at cycle %0d", base_name, c);
          end
          d = diff64_at[c];
        end

        if (d == p_s) begin
          drift_flag[i] = 1'b0;
        end else if (d == p_s + drift) begin
          drift_flag[i] = 1'b1;
        end else begin
          errors++;
          $display("FAIL I1/D: %s increment %0d at cycle %0d not period or period+drift",
                   base_name, d, c);
          drift_flag[i] = 1'b0;
        end

        if (ts_step_at[c] !== 1'b0) begin
          errors++;
          $display("FAIL A4/S3: %s ts_step high at cycle %0d", base_name, c);
        end
        if (adj_active_at[c] !== 1'b0) begin
          errors++;
          $display("FAIL A3: %s adj_active high at cycle %0d", base_name, c);
        end
        if (pps_at[c] !== 1'b0) begin
          errors++;
          $display("FAIL W3: %s pps high at cycle %0d", base_name, c);
        end
        if (ns96_at[c] >= 30'd1000000000) begin
          errors++;
          $display("FAIL W1: ns>=1e9 at cycle %0d", c);
        end
      end

      for (i = 0; i <= n - rate; i = i + 1) begin
        sum = 0;
        for (j = 0; j < rate; j = j + 1) begin
          sum = sum + drift_flag[i+j];
        end
        if (sum != 1) begin
          errors++;
          $display("FAIL D2: %s drift window at cycle %0d has %0d drifts, expected 1",
                   base_name, c0+i, sum);
        end
      end
    end
  endtask

  task automatic check_adj(
      input int C,
      input int count,
      input logic [127:0] period,
      input logic signed [127:0] adj,
      input bit is96,
      input string base_name);
    int i, c, first_inc, last_inc, count_inc, first_act, last_act, count_act;
    logic signed [127:0] d;
    logic signed [127:0] p_s;
    logic inc_flag[0:100];
    logic act_flag[0:100];
    begin
      p_s = period;

      for (i = 1; i <= 5; i = i + 1) begin
        c = C - i;
        if (c >= 0) begin
          if (adj_active_at[c] !== 1'b0) begin
            errors++;
            $display("FAIL A3: %s adj_active before valid at cycle %0d", base_name, c);
          end
          if (ts_step_at[c] !== 1'b0) begin
            errors++;
            $display("FAIL A4: %s ts_step before valid at cycle %0d", base_name, c);
          end
        end
      end

      for (i = 0; i <= 50; i = i + 1) begin
        c = C + i;
        if (is96) begin
          if (!diff96_valid_at[c]) begin
            errors++;
            $display("FAIL: %s diff invalid at cycle %0d", base_name, c);
          end
          d = diff96_at[c];
        end else begin
          if (!diff64_valid_at[c]) begin
            errors++;
            $display("FAIL: %s diff invalid at cycle %0d", base_name, c);
          end
          d = diff64_at[c];
        end

        if (d == p_s) begin
          inc_flag[i] = 1'b0;
        end else if (d == p_s + adj) begin
          inc_flag[i] = 1'b1;
        end else begin
          errors++;
          $display("FAIL I1/A2: %s increment %0d at cycle %0d not period or period+adj",
                   base_name, d, c);
          inc_flag[i] = 1'b0;
        end

        act_flag[i] = adj_active_at[c];

        if (ts_step_at[c] !== adj_active_at[c]) begin
          errors++;
          $display("FAIL A4: %s ts_step != adj_active at cycle %0d", base_name, c);
        end
        if (ns96_at[c] >= 30'd1000000000) begin
          errors++;
          $display("FAIL W1: ns>=1e9 at cycle %0d", c);
        end
      end

      first_inc = -1;
      count_inc = 0;
      for (i = 0; i <= 50; i = i + 1) begin
        if (inc_flag[i]) begin
          if (first_inc == -1) first_inc = i;
          count_inc = count_inc + 1;
        end
      end

      if (count_inc != count) begin
        errors++;
        $display("FAIL A2: %s adjusted increment count %0d, expected %0d",
                 base_name, count_inc, count);
      end
      if (first_inc == -1) begin
        errors++;
        $display("FAIL A2: %s no adjusted increment", base_name);
      end else begin
        if (first_inc > 8) begin
          errors++;
          $display("FAIL L1: %s first adjusted increment at +%0d > 8",
                   base_name, first_inc);
        end
        last_inc = first_inc + count - 1;
        for (i = first_inc; i <= last_inc; i = i + 1) begin
          if (!inc_flag[i]) begin
            errors++;
            $display("FAIL A2: %s adjusted increments not consecutive at +%0d",
                     base_name, i);
          end
        end
        for (i = 0; i <= 50; i = i + 1) begin
          if (inc_flag[i] && (i < first_inc || i > last_inc)) begin
            errors++;
            $display("FAIL A2: %s extra adjusted increment at +%0d", base_name, i);
          end
        end
      end

      first_act = -1;
      count_act = 0;
      for (i = 0; i <= 50; i = i + 1) begin
        if (act_flag[i]) begin
          if (first_act == -1) first_act = i;
          count_act = count_act + 1;
        end
      end

      if (count_act != count) begin
        errors++;
        $display("FAIL A3: %s adj_active count %0d, expected %0d",
                 base_name, count_act, count);
      end
      if (first_act == -1) begin
        errors++;
        $display("FAIL A3: %s no adj_active", base_name);
      end else begin
        last_act = first_act + count - 1;
        for (i = first_act; i <= last_act; i = i + 1) begin
          if (!act_flag[i]) begin
            errors++;
            $display("FAIL A3: %s adj_active not consecutive at +%0d",
                     base_name, i);
          end
        end
        for (i = 0; i <= 50; i = i + 1) begin
          if (act_flag[i] && (i < first_act || i > last_act)) begin
            errors++;
            $display("FAIL A3: %s extra adj_active at +%0d", base_name, i);
          end
        end
      end
    end
  endtask

  task automatic check_wrap(input int C, input int N, input logic [127:0] period);
    int i, c, wrap_count;
    logic [127:0] prev_ns_fns, expected, expected_ns_fns;
    logic [47:0] expected_sec;
    logic expected_pps;
    begin
      wrap_count = 0;
      for (i = 5; i <= N; i = i + 1) begin
        c = C + i;
        if (!diff96_valid_at[c]) begin
          errors++;
          $display("FAIL: wrap diff invalid at cycle %0d", c);
        end
        if (diff96_at[c] != period) begin
          errors++;
          $display("FAIL I1: wrap increment at cycle %0d is %0d, expected %0d",
                   c, diff96_at[c], period);
        end

        prev_ns_fns = ns96_at[c-1] * 128'd65536 + fns96_at[c-1];
        expected = prev_ns_fns + period;

        if (expected >= 128'd1000000000 * 128'd65536) begin
          expected_ns_fns = expected - 128'd1000000000 * 128'd65536;
          expected_sec = sec96_at[c-1] + 1;
          expected_pps = 1'b1;
          wrap_count = wrap_count + 1;
        end else begin
          expected_ns_fns = expected;
          expected_sec = sec96_at[c-1];
          expected_pps = 1'b0;
        end

        if ((ns96_at[c] * 128'd65536 + fns96_at[c]) != expected_ns_fns) begin
          errors++;
          $display("FAIL W1: ns mismatch at cycle %0d", c);
        end
        if (sec96_at[c] != expected_sec) begin
          errors++;
          $display("FAIL W1: sec mismatch at cycle %0d", c);
        end
        if (pps_at[c] != expected_pps) begin
          errors++;
          $display("FAIL W3: pps mismatch at cycle %0d", c);
        end
        if (ns96_at[c] >= 30'd1000000000) begin
          errors++;
          $display("FAIL W1: ns>=1e9 at cycle %0d", c);
        end
        if (ts_step_at[c] !== 1'b0) begin
          errors++;
          $display("FAIL S3: ts_step high during wrap at cycle %0d", c);
        end
        if (adj_active_at[c] !== 1'b0) begin
          errors++;
          $display("FAIL A3: adj_active high during wrap at cycle %0d", c);
        end
      end

      if (wrap_count < 1) begin
        errors++;
        $display("FAIL W1: no wrap observed in window");
      end
    end
  endtask

  initial begin
    int start_cycle, end_cycle, C, i;
    logic [127:0] default_period, period8, period10, period65;
    logic signed [127:0] default_drift, drift_neg, adj25, adj_neg;

    errors = 0;

    default_period = period_fns(4'h6, 16'h6666);
    default_drift  = signed20(4'h0, 16'h0002);
    period8        = period_fns(4'h8, 16'h8000);
    period10       = period_fns(4'hA, 16'h0000);
    period65       = period_fns(4'h6, 16'h8000);
    drift_neg      = signed20(4'hF, 16'h0000);
    adj25          = signed20(4'h2, 16'h8000);
    adj_neg        = signed20(4'hE, 16'h8000);

    // -----------------------------------------------------------------------
    // Reset, default period and default drift.
    // -----------------------------------------------------------------------
    bfm_reset(5);
    if (ts96 !== 96'd0 || ts64 !== 64'd0) begin
      errors++;
      $display("FAIL R2: bases not zero after reset");
    end

    repeat (8) @(negedge clk);
    start_cycle = bfm_cycle;
    repeat (30) @(negedge clk);
    end_cycle = bfm_cycle;

    check_drift_pattern(start_cycle+1, end_cycle,
                        default_period, default_drift, 5, 1, "ts96");
    check_drift_pattern(start_cycle+1, end_cycle,
                        default_period, default_drift, 5, 0, "ts64");

    // -----------------------------------------------------------------------
    // Period change.
    // -----------------------------------------------------------------------
    bfm_period(4'h8, 16'h8000);
    repeat (10) @(negedge clk);
    start_cycle = bfm_cycle;
    repeat (20) @(negedge clk);
    end_cycle = bfm_cycle;

    check_drift_pattern(start_cycle+1, end_cycle,
                        period8, default_drift, 5, 1, "ts96");
    check_drift_pattern(start_cycle+1, end_cycle,
                        period8, default_drift, 5, 0, "ts64");

    // -----------------------------------------------------------------------
    // Drift change, including negative drift and rate 3.
    // -----------------------------------------------------------------------
    bfm_period(4'hA, 16'h0000);
    repeat (10) @(negedge clk);
    bfm_drift(4'hF, 16'h0000, 3);
    repeat (10) @(negedge clk);
    start_cycle = bfm_cycle;
    repeat (30) @(negedge clk);
    end_cycle = bfm_cycle;

    check_drift_pattern(start_cycle+1, end_cycle,
                        period10, drift_neg, 3, 1, "ts96");
    check_drift_pattern(start_cycle+1, end_cycle,
                        period10, drift_neg, 3, 0, "ts64");

    // -----------------------------------------------------------------------
    // Positive counted offset adjustment.
    // -----------------------------------------------------------------------
    bfm_drift(4'h0, 16'h0000, 5);
    repeat (10) @(negedge clk);
    bfm_period(4'h6, 16'h8000);
    repeat (10) @(negedge clk);

    bfm_adjust(4'h2, 16'h8000, 16'd7);
    C = bfm_cycle;
    repeat (50) @(negedge clk);

    check_adj(C, 7, period65, adj25, 1, "ts96");
    check_adj(C, 7, period65, adj25, 0, "ts64");

    // -----------------------------------------------------------------------
    // Negative counted offset adjustment.
    // -----------------------------------------------------------------------
    bfm_period(4'hA, 16'h0000);
    repeat (10) @(negedge clk);

    bfm_adjust(4'hE, 16'h8000, 16'd5);
    C = bfm_cycle;
    repeat (50) @(negedge clk);

    check_adj(C, 5, period10, adj_neg, 1, "ts96");
    check_adj(C, 5, period10, adj_neg, 0, "ts64");

    // -----------------------------------------------------------------------
    // Reset cancels an outstanding adjustment and restores defaults.
    // -----------------------------------------------------------------------
    bfm_adjust(4'h1, 16'h0000, 16'd100);
    repeat (2) @(negedge clk);
    bfm_reset(5);

    if (ts96 !== 96'd0 || ts64 !== 64'd0) begin
      errors++;
      $display("FAIL R2: bases not zero after reset (cancel adj)");
    end

    repeat (8) @(negedge clk);
    start_cycle = bfm_cycle;
    repeat (20) @(negedge clk);
    end_cycle = bfm_cycle;

    check_drift_pattern(start_cycle+1, end_cycle,
                        default_period, default_drift, 5, 1, "ts96");
    check_drift_pattern(start_cycle+1, end_cycle,
                        default_period, default_drift, 5, 0, "ts64");

    // -----------------------------------------------------------------------
    // Set ts96: immediate value, one-cycle ts_step, ts64 undisturbed.
    // -----------------------------------------------------------------------
    bfm_drift(4'h0, 16'h0000, 5);
    repeat (10) @(negedge clk);

    bfm_set96(48'd1, 30'd123, 16'h4567);
    C = bfm_cycle;
    repeat (10) @(negedge clk);

    if (sec96_at[C] != 48'd1 ||
        ns96_at[C]  != 30'd123 ||
        fns96_at[C] != 16'h4567) begin
      errors++;
      $display("FAIL S1: ts96 not set immediately at cycle %0d", C);
    end
    if (ts_step_at[C] !== 1'b1) begin
      errors++;
      $display("FAIL S3: ts_step not high on set96 at cycle %0d", C);
    end

    for (i = 1; i <= 10; i = i + 1) begin
      if (ts_step_at[C+i] !== 1'b0) begin
        errors++;
        $display("FAIL S3: ts_step extra at cycle %0d", C+i);
      end
      if (adj_active_at[C+i] !== 1'b0) begin
        errors++;
        $display("FAIL A3: adj_active during set at cycle %0d", C+i);
      end
      if (pps_at[C+i] !== 1'b0) begin
        errors++;
        $display("FAIL W3: pps during set at cycle %0d", C+i);
      end
    end

    if (!diff64_valid_at[C] || diff64_at[C] != default_period) begin
      errors++;
      $display("FAIL S4: ts64 disturbed by set96 at cycle %0d", C);
    end

    for (i = 5; i <= 10; i = i + 1) begin
      if (!diff96_valid_at[C+i] || diff96_at[C+i] != default_period) begin
        errors++;
        $display("FAIL I1: ts96 increment after set96 at cycle %0d not period", C+i);
      end
      if (!diff64_valid_at[C+i] || diff64_at[C+i] != default_period) begin
        errors++;
        $display("FAIL S4: ts64 increment at cycle %0d not period", C+i);
      end
    end

    // -----------------------------------------------------------------------
    // Set ts64: immediate value, one-cycle ts_step, ts96 undisturbed.
    // -----------------------------------------------------------------------
    bfm_set64(48'd456, 16'h1234);
    C = bfm_cycle;
    repeat (10) @(negedge clk);

    if (ns64_at[C]  != 48'd456 ||
        fns64_at[C] != 16'h1234) begin
      errors++;
      $display("FAIL S2: ts64 not set immediately at cycle %0d", C);
    end
    if (ts_step_at[C] !== 1'b1) begin
      errors++;
      $display("FAIL S3: ts_step not high on set64 at cycle %0d", C);
    end

    for (i = 1; i <= 10; i = i + 1) begin
      if (ts_step_at[C+i] !== 1'b0) begin
        errors++;
        $display("FAIL S3: ts_step extra at cycle %0d", C+i);
      end
      if (adj_active_at[C+i] !== 1'b0) begin
        errors++;
        $display("FAIL A3: adj_active during set at cycle %0d", C+i);
      end
      if (pps_at[C+i] !== 1'b0) begin
        errors++;
        $display("FAIL W3: pps during set at cycle %0d", C+i);
      end
    end

    if (!diff96_valid_at[C] || diff96_at[C] != default_period) begin
      errors++;
      $display("FAIL S4: ts96 disturbed by set64 at cycle %0d", C);
    end

    for (i = 5; i <= 10; i = i + 1) begin
      if (!diff64_valid_at[C+i] || diff64_at[C+i] != default_period) begin
        errors++;
        $display("FAIL I1: ts64 increment after set64 at cycle %0d not period", C+i);
      end
      if (!diff96_valid_at[C+i] || diff96_at[C+i] != default_period) begin
        errors++;
        $display("FAIL S4: ts96 increment at cycle %0d not period", C+i);
      end
    end

    // -----------------------------------------------------------------------
    // ts64 must not wrap at one second.
    // -----------------------------------------------------------------------
    bfm_set64(48'd999_999_990, 16'h0000);
    C = bfm_cycle;
    repeat (10) @(negedge clk);

    if (ns64_at[C]  != 48'd999_999_990 ||
        fns64_at[C] != 16'h0000) begin
      errors++;
      $display("FAIL S2: ts64 not set for no-wrap test at cycle %0d", C);
    end

    if (total64_at[C+10] <= 128'd1000000000 * 128'd65536) begin
      errors++;
      $display("FAIL W2: ts64 wrapped at 1e9 or did not advance");
    end
    if (ns64_at[C+10] < 48'd1000000000) begin
      errors++;
      $display("FAIL W2: ts64 ns field < 1e9 after crossing");
    end

    for (i = 5; i <= 10; i = i + 1) begin
      if (!diff64_valid_at[C+i] || diff64_at[C+i] != default_period) begin
        errors++;
        $display("FAIL I1: ts64 increment after crossing at cycle %0d not period", C+i);
      end
    end

    // -----------------------------------------------------------------------
    // ts96 one-second wrap and pps.
    // -----------------------------------------------------------------------
    bfm_set96(48'd5, 30'd999_999_800, 16'h0000);
    C = bfm_cycle;
    repeat (50) @(negedge clk);

    if (sec96_at[C] != 48'd5 ||
        ns96_at[C]  != 30'd999_999_800 ||
        fns96_at[C] != 16'h0000) begin
      errors++;
      $display("FAIL S1: ts96 not set for wrap test at cycle %0d", C);
    end
    if (ts_step_at[C] !== 1'b1) begin
      errors++;
      $display("FAIL S3: ts_step not high on wrap set at cycle %0d", C);
    end

    check_wrap(C, 50, default_period);

    for (i = 1; i <= 50; i = i + 1) begin
      if (ts_step_at[C+i] !== 1'b0) begin
        errors++;
        $display("FAIL S3: ts_step extra after wrap set at cycle %0d", C+i);
      end
      if (adj_active_at[C+i] !== 1'b0) begin
        errors++;
        $display("FAIL A3: adj_active after wrap set at cycle %0d", C+i);
      end
    end

    // -----------------------------------------------------------------------
    // Verdict.
    // -----------------------------------------------------------------------
    if (errors == 0) $display("RESULT: PASS");
    else             $display("RESULT: FAIL");
    $finish;
  end

endmodule
