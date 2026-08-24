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

  task automatic bfm_wait(input int cycles);
    repeat (cycles) @(posedge clk);
  endtask

  initial begin
    set_ts96 = '0;
    set_ts96_valid = 1'b0;
    set_ts64 = '0;
    set_ts64_valid = 1'b0;

    period_ns = '0;
    period_fns = '0;
    period_valid = 1'b0;

    adj_ns = '0;
    adj_fns = '0;
    adj_count = '0;
    adj_valid = 1'b0;

    drift_ns = '0;
    drift_fns = '0;
    drift_rate = '0;
    drift_valid = 1'b0;
  end

  initial begin
    #3_000_000;
    $display("FAIL [termination]: watchdog expired before a verdict");
    $display("RESULT: FAIL");
    $finish;
  end

  // ---------------------------------------------------------------------------
  // CHECKER / MODEL
  // ---------------------------------------------------------------------------

  localparam longint signed FNS_PER_NS  = 64'sd65536;
  localparam longint signed FNS_PER_SEC = 64'sd65536000000000;

  localparam longint signed P_DEF =
      64'sh0000_0000_0006_6666;

  localparam longint signed P_TEST =
      64'sh0000_0000_0005_2222;

  localparam longint signed P_FRAC =
      64'sh0000_0000_0001_0001;

  function automatic longint signed flat96(input logic [95:0] v);
    longint signed sec_v;
    longint signed ns_v;
    longint signed fns_v;
    begin
      sec_v = v[95:48];
      ns_v = v[45:16];
      fns_v = v[15:0];

      flat96 =
          (sec_v * FNS_PER_SEC) +
          (ns_v * FNS_PER_NS) +
          fns_v;
    end
  endfunction

  function automatic longint signed flat64(input logic [63:0] v);
    longint signed ns_v;
    longint signed fns_v;
    begin
      ns_v = v[63:16];
      fns_v = v[15:0];

      flat64 =
          (ns_v * FNS_PER_NS) +
          fns_v;
    end
  endfunction

  function automatic longint signed signed20(
      input logic [3:0] ns,
      input logic [15:0] fns
  );
    logic signed [19:0] raw_v;
    begin
      raw_v = {ns, fns};
      signed20 = $signed(raw_v);
    end
  endfunction

  task automatic fail_clause(
      input string clause_name,
      input string detail
  );
    begin
      $display(
          "FAIL [%s] cycle=%0d: %s",
          clause_name,
          bfm_cycle,
          detail
      );
      $display("RESULT: FAIL");
      $finish;
    end
  endtask

  task automatic check_reset_state;
    begin
      if (ts96 !== 96'b0)
        fail_clause(
            "R2",
            "ts96 was not zero when reset was released"
        );

      if (ts64 !== 64'b0)
        fail_clause(
            "R2",
            "ts64 was not zero when reset was released"
        );

      if (adj_active !== 1'b0)
        fail_clause(
            "R2/A3",
            "adj_active remained asserted after reset"
        );

      if (ts_step !== 1'b0)
        fail_clause(
            "R2/A4",
            "ts_step remained asserted after reset"
        );
    end
  endtask

  task automatic verify_drift_pattern(
      input longint signed period_u,
      input longint signed drift_u,
      input int rate_v,
      input int ncycles,
      input string tag
  );
    longint signed prev96_u;
    longint signed prev64_u;
    longint signed cur96_u;
    longint signed cur64_u;
    longint signed d96_u;
    longint signed d64_u;

    int i;
    int last96;
    int last64;
    int first96;
    int first64;
    int hits96;
    int hits64;

    begin
      last96 = -1;
      last64 = -1;
      first96 = -1;
      first64 = -1;
      hits96 = 0;
      hits64 = 0;

      @(negedge clk);

      prev96_u = flat96(ts96);
      prev64_u = flat64(ts64);

      for (i = 0; i < ncycles; i = i + 1) begin
        @(negedge clk);

        cur96_u = flat96(ts96);
        cur64_u = flat64(ts64);

        d96_u = cur96_u - prev96_u;
        d64_u = cur64_u - prev64_u;

        if (ts96[47:46] !== 2'b00)
          fail_clause(
              "F1",
              "reserved bits [47:46] of ts96 were not zero"
          );

        if (adj_active !== 1'b0)
          fail_clause(
              "A3",
              "adj_active asserted with no offset adjustment pending"
          );

        if (ts_step !== 1'b0)
          fail_clause(
              "A4/S3",
              "ts_step asserted without an adjustment or set"
          );

        if (pps !== 1'b0)
          fail_clause(
              "W3",
              "pps asserted without a one-second ts96 wrap"
          );

        if (d96_u == (period_u + drift_u)) begin
          if (first96 < 0)
            first96 = i;

          if ((last96 >= 0) &&
              ((i - last96) != rate_v))
            fail_clause(
                tag,
                "ts96 drift hits were not exactly drift_rate cycles apart"
            );

          last96 = i;
          hits96 = hits96 + 1;
        end
        else if (d96_u != period_u) begin
          fail_clause(
              "I1/I2/D2",
              "ts96 increment was neither period nor period+drift"
          );
        end

        if (d64_u == (period_u + drift_u)) begin
          if (first64 < 0)
            first64 = i;

          if ((last64 >= 0) &&
              ((i - last64) != rate_v))
            fail_clause(
                tag,
                "ts64 drift hits were not exactly drift_rate cycles apart"
            );

          last64 = i;
          hits64 = hits64 + 1;
        end
        else if (d64_u != period_u) begin
          fail_clause(
              "I1/I2/D2",
              "ts64 increment was neither period nor period+drift"
          );
        end

        prev96_u = cur96_u;
        prev64_u = cur64_u;
      end

      if ((hits96 < 2) || (hits64 < 2))
        fail_clause(
            tag,
            "too few drift applications were observed"
        );

      if ((first96 < 0) || (first96 >= rate_v))
        fail_clause(
            tag,
            "ts96 did not contain one drift hit in the first drift_rate observations"
        );

      if ((first64 < 0) || (first64 >= rate_v))
        fail_clause(
            tag,
            "ts64 did not contain one drift hit in the first drift_rate observations"
        );
    end
  endtask

  task automatic verify_constant(
      input longint signed period_u,
      input int ncycles,
      input string tag
  );
    longint signed prev96_u;
    longint signed prev64_u;
    longint signed cur96_u;
    longint signed cur64_u;
    longint signed d96_u;
    longint signed d64_u;

    int i;

    begin
      @(negedge clk);

      prev96_u = flat96(ts96);
      prev64_u = flat64(ts64);

      for (i = 0; i < ncycles; i = i + 1) begin
        @(negedge clk);

        cur96_u = flat96(ts96);
        cur64_u = flat64(ts64);

        d96_u = cur96_u - prev96_u;
        d64_u = cur64_u - prev64_u;

        if (d96_u != period_u)
          fail_clause(
              tag,
              "ts96 increment did not equal the exact programmed period"
          );

        if (d64_u != period_u)
          fail_clause(
              tag,
              "ts64 increment did not equal the exact programmed period"
          );

        if (ts96[47:46] !== 2'b00)
          fail_clause(
              "F1",
              "reserved bits [47:46] of ts96 were not zero"
          );

        if (adj_active !== 1'b0)
          fail_clause(
              "A3",
              "adj_active asserted while idle"
          );

        if (ts_step !== 1'b0)
          fail_clause(
              "A4/S3",
              "ts_step asserted while idle"
          );

        if (pps !== 1'b0)
          fail_clause(
              "W3",
              "pps asserted without a wrap"
          );

        prev96_u = cur96_u;
        prev64_u = cur64_u;
      end
    end
  endtask

  task automatic test_period_latency(
      input longint signed old_p,
      input logic [3:0] new_ns,
      input logic [15:0] new_fns,
      input longint signed new_p
  );
    longint signed prev96_u;
    longint signed prev64_u;
    longint signed cur96_u;
    longint signed cur64_u;
    longint signed d96_u;
    longint signed d64_u;

    int i;
    int first96;
    int first64;

    bit seen96;
    bit seen64;

    begin
      first96 = -1;
      first64 = -1;

      seen96 = 1'b0;
      seen64 = 1'b0;

      @(negedge clk);

      prev96_u = flat96(ts96);
      prev64_u = flat64(ts64);

      period_ns = new_ns;
      period_fns = new_fns;
      period_valid = 1'b1;

      for (i = 0; i <= 8; i = i + 1) begin
        @(negedge clk);

        cur96_u = flat96(ts96);
        cur64_u = flat64(ts64);

        d96_u = cur96_u - prev96_u;
        d64_u = cur64_u - prev64_u;

        if (i == 0)
          period_valid = 1'b0;

        if (d96_u == new_p) begin
          if (!seen96) begin
            seen96 = 1'b1;
            first96 = i;
          end
        end
        else if (d96_u == old_p) begin
          if (seen96)
            fail_clause(
                "I2",
                "ts96 reverted to the old period after adopting the new period"
            );
        end
        else begin
          fail_clause(
              "I1/I2",
              "ts96 showed an illegal increment during period adoption"
          );
        end

        if (d64_u == new_p) begin
          if (!seen64) begin
            seen64 = 1'b1;
            first64 = i;
          end
        end
        else if (d64_u == old_p) begin
          if (seen64)
            fail_clause(
                "I2",
                "ts64 reverted to the old period after adopting the new period"
            );
        end
        else begin
          fail_clause(
              "I1/I2",
              "ts64 showed an illegal increment during period adoption"
          );
        end

        if ((adj_active !== 1'b0) ||
            (ts_step !== 1'b0))
          fail_clause(
              "A3/A4",
              "period update spuriously asserted adjustment status"
          );

        if (pps !== 1'b0)
          fail_clause(
              "W3",
              "period update spuriously asserted pps"
          );

        prev96_u = cur96_u;
        prev64_u = cur64_u;
      end

      if (first96 < 0)
        fail_clause(
            "L1/I2",
            "ts96 did not adopt the new period within 8 cycles"
        );

      if (first64 < 0)
        fail_clause(
            "L1/I2",
            "ts64 did not adopt the new period within 8 cycles"
        );
    end
  endtask

  task automatic test_drift_rate1_latency(
      input longint signed period_u,
      input logic [3:0] new_ns,
      input logic [15:0] new_fns,
      input longint signed new_drift
  );
    longint signed prev96_u;
    longint signed prev64_u;
    longint signed cur96_u;
    longint signed cur64_u;
    longint signed d96_u;
    longint signed d64_u;

    int i;
    int first96;
    int first64;

    bit seen96;
    bit seen64;

    begin
      first96 = -1;
      first64 = -1;

      seen96 = 1'b0;
      seen64 = 1'b0;

      @(negedge clk);

      prev96_u = flat96(ts96);
      prev64_u = flat64(ts64);

      drift_ns = new_ns;
      drift_fns = new_fns;
      drift_rate = 16'd1;
      drift_valid = 1'b1;

      for (i = 0; i <= 8; i = i + 1) begin
        @(negedge clk);

        cur96_u = flat96(ts96);
        cur64_u = flat64(ts64);

        d96_u = cur96_u - prev96_u;
        d64_u = cur64_u - prev64_u;

        if (i == 0)
          drift_valid = 1'b0;

        if (d96_u == (period_u + new_drift)) begin
          if (!seen96) begin
            seen96 = 1'b1;
            first96 = i;
          end
        end
        else if (d96_u == period_u) begin
          if (seen96)
            fail_clause(
                "D1/D2",
                "ts96 lost a rate-1 drift after adopting it"
            );
        end
        else begin
          fail_clause(
              "I1/D1",
              "ts96 showed an illegal increment during drift adoption"
          );
        end

        if (d64_u == (period_u + new_drift)) begin
          if (!seen64) begin
            seen64 = 1'b1;
            first64 = i;
          end
        end
        else if (d64_u == period_u) begin
          if (seen64)
            fail_clause(
                "D1/D2",
                "ts64 lost a rate-1 drift after adopting it"
            );
        end
        else begin
          fail_clause(
              "I1/D1",
              "ts64 showed an illegal increment during drift adoption"
          );
        end

        if ((adj_active !== 1'b0) ||
            (ts_step !== 1'b0))
          fail_clause(
              "A3/A4",
              "drift update spuriously asserted adjustment status"
          );

        if (pps !== 1'b0)
          fail_clause(
              "W3",
              "drift update spuriously asserted pps"
          );

        prev96_u = cur96_u;
        prev64_u = cur64_u;
      end

      if (first96 < 0)
        fail_clause(
            "L1/D1",
            "ts96 did not adopt rate-1 drift within 8 cycles"
        );

      if (first64 < 0)
        fail_clause(
            "L1/D1",
            "ts64 did not adopt rate-1 drift within 8 cycles"
        );
    end
  endtask

  task automatic test_adjustment(
      input logic [3:0] off_ns,
      input logic [15:0] off_fns,
      input logic [15:0] count_v,
      input longint signed period_u,
      input string tag
  );
    longint signed off_u;
    longint signed prev96_u;
    longint signed prev64_u;
    longint signed cur96_u;
    longint signed cur64_u;
    longint signed d96_u;
    longint signed d64_u;

    int want;
    int window_v;
    int i;
    int start96;
    int start64;
    int run96;
    int run64;
    int active_run;

    bit seen96;
    bit seen64;
    bit done96;
    bit done64;
    bit active_seen;
    bit active_done;

    begin
      off_u = signed20(off_ns, off_fns);

      want = count_v;
      window_v = want + 24;

      start96 = -1;
      start64 = -1;

      run96 = 0;
      run64 = 0;

      active_run = 0;

      seen96 = 1'b0;
      seen64 = 1'b0;

      done96 = 1'b0;
      done64 = 1'b0;

      active_seen = 1'b0;
      active_done = 1'b0;

      @(negedge clk);

      prev96_u = flat96(ts96);
      prev64_u = flat64(ts64);

      adj_ns = off_ns;
      adj_fns = off_fns;
      adj_count = count_v;
      adj_valid = 1'b1;

      for (i = 0; i < window_v; i = i + 1) begin
        @(negedge clk);

        cur96_u = flat96(ts96);
        cur64_u = flat64(ts64);

        d96_u = cur96_u - prev96_u;
        d64_u = cur64_u - prev64_u;

        if (i == 0)
          adj_valid = 1'b0;

        if (d96_u == (period_u + off_u)) begin
          if (done96)
            fail_clause(
                "A2",
                "ts96 adjustment increments were not consecutive"
            );

          if (!seen96) begin
            seen96 = 1'b1;
            start96 = i;
          end

          run96 = run96 + 1;
        end
        else if (d96_u == period_u) begin
          if (seen96 && !done96)
            done96 = 1'b1;
        end
        else begin
          fail_clause(
              tag,
              "ts96 increment had an illegal adjustment value"
          );
        end

        if (d64_u == (period_u + off_u)) begin
          if (done64)
            fail_clause(
                "A2",
                "ts64 adjustment increments were not consecutive"
            );

          if (!seen64) begin
            seen64 = 1'b1;
            start64 = i;
          end

          run64 = run64 + 1;
        end
        else if (d64_u == period_u) begin
          if (seen64 && !done64)
            done64 = 1'b1;
        end
        else begin
          fail_clause(
              tag,
              "ts64 increment had an illegal adjustment value"
          );
        end

        if (adj_active === 1'b1) begin
          if (active_done)
            fail_clause(
                "A3",
                "adj_active was not one consecutive run"
            );

          if (!active_seen)
            active_seen = 1'b1;

          active_run = active_run + 1;
        end
        else begin
          if (active_seen && !active_done)
            active_done = 1'b1;
        end

        if (ts_step !== adj_active)
          fail_clause(
              "A4",
              "ts_step did not exactly match adj_active during an adjustment-only test"
          );

        if (pps !== 1'b0)
          fail_clause(
              "W3",
              "pps asserted without a wrap during adjustment test"
          );

        prev96_u = cur96_u;
        prev64_u = cur64_u;
      end

      if (want == 0) begin
        if (seen96 || seen64)
          fail_clause(
              "A2",
              "zero-count adjustment changed a timestamp increment"
          );

        if (active_seen)
          fail_clause(
              "A3",
              "zero-count adjustment asserted adj_active"
          );
      end
      else begin
        if (!seen96 || (run96 != want))
          fail_clause(
              "A2",
              "ts96 did not receive exactly adj_count adjusted increments"
          );

        if (!seen64 || (run64 != want))
          fail_clause(
              "A2",
              "ts64 did not receive exactly adj_count adjusted increments"
          );

        if ((start96 < 0) || (start96 > 8))
          fail_clause(
              "L1/A2",
              "ts96 adjustment did not begin within 8 cycles"
          );

        if ((start64 < 0) || (start64 > 8))
          fail_clause(
              "L1/A2",
              "ts64 adjustment did not begin within 8 cycles"
          );

        if (!active_seen || (active_run != want))
          fail_clause(
              "A3",
              "adj_active was not asserted for exactly adj_count cycles"
          );
      end
    end
  endtask

  task automatic issue_set96_check(
      input logic [47:0] sec_v,
      input logic [29:0] ns_v,
      input logic [15:0] fns_v,
      input longint signed other_period
  );
    logic [95:0] want96;
    longint signed before64_u;
    longint signed after64_u;

    begin
      want96 = {sec_v, 2'b00, ns_v, fns_v};

      @(negedge clk);

      before64_u = flat64(ts64);

      set_ts96 = want96;
      set_ts96_valid = 1'b1;

      @(negedge clk);

      after64_u = flat64(ts64);

      set_ts96_valid = 1'b0;

      if (ts96 !== want96)
        fail_clause(
            "S1/F1",
            "ts96 did not show the exact set value on the accepting cycle"
        );

      if ((after64_u - before64_u) != other_period)
        fail_clause(
            "S4",
            "setting ts96 disturbed ts64"
        );

      if (ts_step !== 1'b1)
        fail_clause(
            "S3",
            "ts_step was not asserted on a ts96 set"
        );

      if (pps !== 1'b0)
        fail_clause(
            "W3",
            "a set operation itself spuriously asserted pps"
        );
    end
  endtask

  task automatic issue_set64_check(
      input logic [47:0] ns_v,
      input logic [15:0] fns_v,
      input longint signed other_period
  );
    logic [63:0] want64;
    longint signed before96_u;
    longint signed after96_u;

    begin
      want64 = {ns_v, fns_v};

      @(negedge clk);

      before96_u = flat96(ts96);

      set_ts64 = want64;
      set_ts64_valid = 1'b1;

      @(negedge clk);

      after96_u = flat96(ts96);

      set_ts64_valid = 1'b0;

      if (ts64 !== want64)
        fail_clause(
            "S2/F2",
            "ts64 did not show the exact set value on the accepting cycle"
        );

      if ((after96_u - before96_u) != other_period)
        fail_clause(
            "S4",
            "setting ts64 disturbed ts96"
        );

      if (ts_step !== 1'b1)
        fail_clause(
            "S3",
            "ts_step was not asserted on a ts64 set"
        );

      if (pps !== 1'b0)
        fail_clause(
            "W3",
            "a set operation itself spuriously asserted pps"
        );
    end
  endtask

  task automatic ignore_set_warmup_and_check_step;
    int i;

    begin
      for (i = 0; i < 4; i = i + 1) begin
        @(negedge clk);

        if (ts_step !== 1'b0)
          fail_clause(
              "S3",
              "ts_step lasted more than one cycle after a set"
          );
      end
    end
  endtask

  task automatic test_wrap96(
      input longint signed period_u
  );
    logic [47:0] prev_sec;
    logic [47:0] exp_sec;
    logic [29:0] exp_ns;
    logic [15:0] exp_fns;
    logic [95:0] exp96;

    longint signed prev_sub;
    longint signed next_sub;
    longint signed ns_now;

    int i;

    bit found_wrap;
    bit exp_pps;

    begin
      issue_set96_check(
          48'd7,
          30'd999999900,
          16'h8000,
          period_u
      );

      ignore_set_warmup_and_check_step();

      if (ts96[47:46] !== 2'b00)
        fail_clause(
            "F1",
            "ts96 reserved bits were nonzero before wrap test"
        );

      if (ts96[45:16] >= 30'd1000000000)
        fail_clause(
            "W1",
            "ts96 nanoseconds field was already outside the legal range"
        );

      prev_sec = ts96[95:48];

      ns_now = ts96[45:16];

      prev_sub =
          (ns_now * FNS_PER_NS) +
          ts96[15:0];

      found_wrap = 1'b0;
      i = 0;

      while ((i < 80) && !found_wrap) begin
        @(negedge clk);

        next_sub = prev_sub + period_u;

        exp_sec = prev_sec;
        exp_pps = 1'b0;

        if (next_sub >= FNS_PER_SEC) begin
          next_sub = next_sub - FNS_PER_SEC;
          exp_sec = prev_sec + 48'd1;
          exp_pps = 1'b1;
        end

        exp_ns = next_sub / FNS_PER_NS;
        exp_fns = next_sub % FNS_PER_NS;

        exp96 = {
            exp_sec,
            2'b00,
            exp_ns,
            exp_fns
        };

        if (ts96 !== exp96)
          fail_clause(
              "W1/I1",
              "ts96 did not perform the exact one-second wrap arithmetic"
          );

        if (pps !== exp_pps)
          fail_clause(
              "W3",
              "pps did not exactly coincide with the ts96 one-second wrap"
          );

        if ((ts_step !== 1'b0) ||
            (adj_active !== 1'b0))
          fail_clause(
              "A3/A4/S3",
              "status pulse asserted spuriously during wrap test"
          );

        if (exp_pps)
          found_wrap = 1'b1;

        prev_sec = exp_sec;
        prev_sub = next_sub;

        i = i + 1;
      end

      if (!found_wrap)
        fail_clause(
            "W1/W3",
            "no one-second wrap was observed after setting ts96 near the boundary"
        );

      @(negedge clk);

      if (pps !== 1'b0)
        fail_clause(
            "W3",
            "pps remained asserted for more than one cycle"
        );
    end
  endtask

  task automatic test_no_wrap64(
      input longint signed period_u
  );
    longint signed prev_u;
    longint signed cur_u;
    longint signed next_u;
    longint signed threshold_u;

    int i;
    bit crossed;

    begin
      issue_set64_check(
          48'd999999900,
          16'h4000,
          period_u
      );

      ignore_set_warmup_and_check_step();

      threshold_u =
          64'sd1000000000 *
          FNS_PER_NS;

      prev_u = flat64(ts64);

      crossed = 1'b0;
      i = 0;

      while ((i < 80) && !crossed) begin
        @(negedge clk);

        cur_u = flat64(ts64);

        next_u = prev_u + period_u;

        if (cur_u != next_u)
          fail_clause(
              "W2/I1",
              "ts64 did not continue linearly through the one-second boundary"
          );

        if ((prev_u < threshold_u) &&
            (cur_u >= threshold_u))
          crossed = 1'b1;

        if (pps !== 1'b0)
          fail_clause(
              "W3",
              "ts64 crossing one second incorrectly asserted pps"
          );

        prev_u = cur_u;
        i = i + 1;
      end

      if (!crossed)
        fail_clause(
            "W2",
            "ts64 did not cross the one-second numeric boundary as a linear counter"
        );
    end
  endtask

  task automatic test_reset_cancels_adjustment;
    int i;
    bit saw_active;

    begin
      bfm_adjust(
          4'h0,
          16'h8000,
          16'd100
      );

      saw_active = 1'b0;
      i = 0;

      while ((i < 16) && !saw_active) begin
        @(negedge clk);

        if (adj_active === 1'b1)
          saw_active = 1'b1;

        i = i + 1;
      end

      if (!saw_active)
        fail_clause(
            "A3/L1",
            "adjustment never became active before reset-cancellation test"
        );

      rst = 1'b1;

      repeat (3)
        @(posedge clk);

      @(negedge clk);

      rst = 1'b0;

      check_reset_state();

      for (i = 0; i < 12; i = i + 1) begin
        @(negedge clk);

        if (adj_active !== 1'b0)
          fail_clause(
              "R2",
              "reset did not cancel the remaining offset adjustment"
          );

        if (ts_step !== 1'b0)
          fail_clause(
              "R2/A4",
              "ts_step asserted after reset cancelled an adjustment"
          );
      end

      verify_drift_pattern(
          P_DEF,
          64'sd2,
          5,
          30,
          "R2/D2"
      );
    end
  endtask


  // ---------------------------------------------------------------------------
  // STIMULUS
  // ---------------------------------------------------------------------------

  initial begin

    // -------------------------------------------------------------------------
    // 1) Reset state and exact default increment/drift.
    //    Measurement starts only after the X2b reset warm-up window.
    // -------------------------------------------------------------------------

    bfm_reset(5);

    check_reset_state();

    bfm_wait(12);

    verify_drift_pattern(
        P_DEF,
        64'sd2,
        5,
        40,
        "I2/D2/R2"
    );


    // -------------------------------------------------------------------------
    // 2) Remove drift and test period control.
    //
    //    The two timestamp bases are allowed to adopt the period on different
    //    cycles, so test_period_latency() observes each base independently.
    // -------------------------------------------------------------------------

    bfm_reset(4);

    check_reset_state();

    bfm_wait(12);

    bfm_drift(
        4'h0,
        16'h0000,
        16'd3
    );

    bfm_wait(12);

    verify_constant(
        P_DEF,
        6,
        "D1/I2"
    );

    test_period_latency(
        P_DEF,
        4'h5,
        16'h2222,
        P_TEST
    );

    verify_constant(
        P_TEST,
        5,
        "I2/L1"
    );


    // -------------------------------------------------------------------------
    // 3) Drift adoption.
    //
    //    rate=1 makes the effect observable on every increment after the base
    //    independently adopts the new drift setting.
    // -------------------------------------------------------------------------

    test_drift_rate1_latency(
        P_TEST,
        4'h0,
        16'h0007,
        64'sd7
    );

    verify_drift_pattern(
        P_TEST,
        64'sd7,
        1,
        10,
        "D1/D2/L1"
    );


    // -------------------------------------------------------------------------
    // 4) Periodic drift spacing and signed drift.
    // -------------------------------------------------------------------------

    bfm_drift(
        4'h0,
        16'h0011,
        16'd4
    );

    bfm_wait(12);

    verify_drift_pattern(
        P_TEST,
        64'sd17,
        4,
        40,
        "D2"
    );

    // Signed 20-bit value:
    //
    //     {4'hF, 16'hFFFD} == -3 fns

    bfm_drift(
        4'hF,
        16'hFFFD,
        16'd3
    );

    bfm_wait(12);

    verify_drift_pattern(
        P_TEST,
        -64'sd3,
        3,
        36,
        "D2/D3"
    );


    // -------------------------------------------------------------------------
    // 5) Exact fractional arithmetic.
    //
    //    Program a period of:
    //
    //       1 ns + 1 fns
    //
    //    This directly exercises the 2^-16 ns fractional resolution.
    // -------------------------------------------------------------------------

    bfm_reset(4);

    check_reset_state();

    bfm_wait(12);

    bfm_drift(
        4'h0,
        16'h0000,
        16'd7
    );

    bfm_wait(12);

    bfm_period(
        4'h1,
        16'h0001
    );

    bfm_wait(12);

    verify_constant(
        P_FRAC,
        24,
        "F3/I1/I2"
    );


    // -------------------------------------------------------------------------
    // 6) Counted positive adjustment.
    //
    //    16'h0101 == 257, intentionally exceeding 8 bits so an implementation
    //    using too-small an adjustment counter is detected.
    // -------------------------------------------------------------------------

    bfm_reset(4);

    check_reset_state();

    bfm_wait(12);

    bfm_drift(
        4'h0,
        16'h0000,
        16'd3
    );

    bfm_wait(12);

    bfm_period(
        4'h5,
        16'h2222
    );

    bfm_wait(12);

    test_adjustment(
        4'h0,
        16'h8000,
        16'h0101,
        P_TEST,
        "A1/A2/A3/A4"
    );


    // -------------------------------------------------------------------------
    // 7) Signed negative adjustment and the zero-count boundary.
    //
    //    {4'hE,16'hC000} is -1.25 ns in signed 20-bit fixed-point.
    // -------------------------------------------------------------------------

    test_adjustment(
        4'hE,
        16'hC000,
        16'd7,
        P_TEST,
        "A2/A5"
    );

    test_adjustment(
        4'h0,
        16'h4000,
        16'd0,
        P_TEST,
        "A2/A3"
    );


    // -------------------------------------------------------------------------
    // 8) Timestamp set behavior.
    //
    //    Verify exact set format, one-cycle ts_step, and independence of the
    //    timestamp base that was not set.
    // -------------------------------------------------------------------------

    bfm_reset(4);

    check_reset_state();

    bfm_wait(12);

    bfm_drift(
        4'h0,
        16'h0000,
        16'd3
    );

    bfm_wait(12);

    bfm_period(
        4'h5,
        16'h2222
    );

    bfm_wait(12);

    issue_set96_check(
        48'h0000_0000_0012,
        30'd123456789,
        16'hA55A,
        P_TEST
    );

    ignore_set_warmup_and_check_step();

    verify_constant(
        P_TEST,
        5,
        "S1/S4/X2c"
    );

    issue_set64_check(
        48'd2345678901,
        16'h5AA5,
        P_TEST
    );

    ignore_set_warmup_and_check_step();

    verify_constant(
        P_TEST,
        5,
        "S2/S4/X2c"
    );


    // -------------------------------------------------------------------------
    // 9) One-second wrap.
    //
    //    ts96 must wrap its ns field at 1,000,000,000 and pulse pps.
    //    ts64 must continue linearly through the same numeric boundary.
    // -------------------------------------------------------------------------

    test_wrap96(P_TEST);

    bfm_wait(6);

    test_no_wrap64(P_TEST);


    // -------------------------------------------------------------------------
    // 10) Reset cancellation and restoration.
    //
    //     Begin a long adjustment, reset while it is active, and confirm:
    //
    //       * the remaining adjustment is cancelled,
    //       * period returns to the default,
    //       * drift returns to +2 fns,
    //       * drift rate returns to 5.
    // -------------------------------------------------------------------------

    bfm_reset(4);

    check_reset_state();

    bfm_wait(12);

    bfm_drift(
        4'h0,
        16'h0000,
        16'd3
    );

    bfm_wait(12);

    test_reset_cancels_adjustment();


    // -------------------------------------------------------------------------
    // All checks passed.
    // -------------------------------------------------------------------------

    $display("RESULT: PASS");
    $finish;

  end

endmodule