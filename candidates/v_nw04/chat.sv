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
  logic        ts_step, pps;

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
    .ts96_o(ts96), .ts64_o(ts64),
    .ts_step_o(ts_step), .pps_o(pps)
  );

  task automatic bfm_period(
    input logic [3:0] ns,
    input logic [15:0] fns
  );
    @(negedge clk);
    period_ns = ns;
    period_fns = fns;
    period_valid = 1'b1;

    @(negedge clk);
    period_valid = 1'b0;
  endtask

  task automatic bfm_adjust(
    input logic [3:0] ns,
    input logic [15:0] fns,
    input logic [15:0] count
  );
    @(negedge clk);
    adj_ns = ns;
    adj_fns = fns;
    adj_count = count;
    adj_valid = 1'b1;

    @(negedge clk);
    adj_valid = 1'b0;
  endtask

  task automatic bfm_drift(
    input logic [3:0] ns,
    input logic [15:0] fns,
    input logic [15:0] rate
  );
    @(negedge clk);
    drift_ns = ns;
    drift_fns = fns;
    drift_rate = rate;
    drift_valid = 1'b1;

    @(negedge clk);
    drift_valid = 1'b0;
  endtask

  task automatic bfm_set96(
    input logic [47:0] sec,
    input logic [29:0] ns,
    input logic [15:0] fns
  );
    @(negedge clk);
    set_ts96 = {sec, 2'b00, ns, fns};
    set_ts96_valid = 1'b1;

    @(negedge clk);
    set_ts96_valid = 1'b0;
  endtask

  task automatic bfm_set64(
    input logic [47:0] ns,
    input logic [15:0] fns
  );
    @(negedge clk);
    set_ts64 = {ns, fns};
    set_ts64_valid = 1'b1;

    @(negedge clk);
    set_ts64_valid = 1'b0;
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
    $display("RESULT: FAIL (watchdog: no verdict reached)");
    $finish;
  end

  // ---------------------------------------------------------------------------
  // CHECKER / REFERENCE HELPERS
  // ---------------------------------------------------------------------------

  localparam longint signed RESET_PERIOD_FNS =
      64'sd419430;                 // {6,16'h6666}

  localparam longint signed ONE_SECOND_FNS =
      64'sd65536000000000;         // 1e9 * 65536

  localparam longint signed PER_325_FNS =
      64'sd212992;                 // 3.25 ns

  localparam longint signed PER_4_FNS =
      64'sd262144;                 // 4 ns

  localparam longint signed PER_1_FNS =
      64'sd65536;                  // 1 ns

  int errors = 0;
  int fail_prints = 0;

  task automatic fail_clause(
    input string clause_name,
    input string msg
  );
    begin
      errors = errors + 1;

      if (fail_prints < 60)
        $display(
          "FAIL [%s] cycle=%0d: %s",
          clause_name,
          bfm_cycle,
          msg
        );

      fail_prints = fail_prints + 1;
    end
  endtask

  function automatic longint signed u20_fns(
    input logic [3:0] ns_v,
    input logic [15:0] fns_v
  );
    logic [19:0] tmp;

    begin
      tmp = {ns_v, fns_v};
      u20_fns = tmp;
    end
  endfunction

  function automatic longint signed s20_fns(
    input logic [3:0] ns_v,
    input logic [15:0] fns_v
  );
    logic signed [19:0] tmp;

    begin
      tmp = {ns_v, fns_v};
      s20_fns = tmp;
    end
  endfunction

  function automatic longint signed t64_fns(
    input logic [63:0] t
  );
    begin
      t64_fns = t;
    end
  endfunction

  function automatic longint signed t96_fns(
    input logic [95:0] t
  );
    longint signed sec_v;
    longint signed ns_v;
    longint signed fn_v;

    begin
      sec_v = t[95:48];
      ns_v  = t[45:16];
      fn_v  = t[15:0];

      t96_fns =
          sec_v * ONE_SECOND_FNS +
          ns_v * 64'sd65536 +
          fn_v;
    end
  endfunction

  // ---------------------------------------------------------------------------
  // RESET DEFAULTS
  // ---------------------------------------------------------------------------

  task automatic check_default_run(input int ncyc);
    longint signed prev96;
    longint signed prev64;
    longint signed cur96;
    longint signed cur64;
    longint signed d96;
    longint signed d64;

    int i;
    int c96;
    int c64;
    int last96;
    int last64;

    begin
      c96 = 0;
      c64 = 0;
      last96 = -1;
      last64 = -1;

      @(negedge clk);

      prev96 = t96_fns(ts96);
      prev64 = t64_fns(ts64);

      for (i = 0; i < ncyc; i = i + 1) begin
        @(negedge clk);

        cur96 = t96_fns(ts96);
        cur64 = t64_fns(ts64);

        d96 = cur96 - prev96;
        d64 = cur64 - prev64;

        if (ts96[47:46] !== 2'b00)
          fail_clause(
            "F1",
            "reserved bits [47:46] of ts96_o are not zero"
          );

        if (d96 == RESET_PERIOD_FNS + 64'sd2) begin
          c96 = c96 + 1;

          if ((last96 >= 0) && ((i - last96) != 5))
            fail_clause(
              "D2",
              $sformatf(
                "ts96 default drift spacing was %0d, expected 5",
                i - last96
              )
            );

          last96 = i;

        end else if (d96 != RESET_PERIOD_FNS) begin
          fail_clause(
            "I1/I2/R2",
            $sformatf(
              "ts96 default increment=%0d fns",
              d96
            )
          );
        end

        if (d64 == RESET_PERIOD_FNS + 64'sd2) begin
          c64 = c64 + 1;

          if ((last64 >= 0) && ((i - last64) != 5))
            fail_clause(
              "D2",
              $sformatf(
                "ts64 default drift spacing was %0d, expected 5",
                i - last64
              )
            );

          last64 = i;

        end else if (d64 != RESET_PERIOD_FNS) begin
          fail_clause(
            "I1/I2/R2",
            $sformatf(
              "ts64 default increment=%0d fns",
              d64
            )
          );
        end

        if (adj_active !== 1'b0)
          fail_clause(
            "A3/R2",
            "adj_active_o asserted with no active adjustment"
          );

        if (ts_step !== 1'b0)
          fail_clause(
            "A4/S3",
            "ts_step_o asserted without set or adjustment"
          );

        if (pps !== 1'b0)
          fail_clause(
            "W3",
            "pps_o asserted far from a one-second wrap"
          );

        prev96 = cur96;
        prev64 = cur64;
      end

      if (c96 != (ncyc / 5))
        fail_clause(
          "D2/R2",
          $sformatf(
            "ts96 saw %0d default drift events in %0d cycles",
            c96,
            ncyc
          )
        );

      if (c64 != (ncyc / 5))
        fail_clause(
          "D2/R2",
          $sformatf(
            "ts64 saw %0d default drift events in %0d cycles",
            c64,
            ncyc
          )
        );
    end
  endtask

  task automatic configure_drift_zero;
    begin
      bfm_drift(
        4'h0,
        16'h0000,
        16'd3
      );

      // Change live inputs after valid. Correct DUT must use latched values.
      drift_ns = 4'h7;
      drift_fns = 16'ha55a;
      drift_rate = 16'd9;

      bfm_wait(8);
    end
  endtask

  // ---------------------------------------------------------------------------
  // PERIOD UPDATE
  // ---------------------------------------------------------------------------

  task automatic test_period_change(
    input logic [3:0] new_ns,
    input logic [15:0] new_fns,
    input longint signed old_per
  );
    longint signed new_per;
    longint signed prev96;
    longint signed prev64;
    longint signed cur96;
    longint signed cur64;
    longint signed d96;
    longint signed d64;

    int i;
    int first96;
    int first64;

    bit seen96;
    bit seen64;

    begin
      new_per = u20_fns(new_ns, new_fns);

      first96 = -1;
      first64 = -1;

      seen96 = 1'b0;
      seen64 = 1'b0;

      @(negedge clk);

      prev96 = t96_fns(ts96);
      prev64 = t64_fns(ts64);

      period_ns = new_ns;
      period_fns = new_fns;
      period_valid = 1'b1;

      for (i = 0; i < 12; i = i + 1) begin
        @(negedge clk);

        cur96 = t96_fns(ts96);
        cur64 = t64_fns(ts64);

        d96 = cur96 - prev96;
        d64 = cur64 - prev64;

        if (i == 0) begin
          period_valid = 1'b0;

          // The valid command must have captured the payload.
          period_ns = 4'h7;
          period_fns = 16'hbeef;
        end

        if (!seen96) begin
          if (d96 == new_per) begin
            seen96 = 1'b1;
            first96 = i;

          end else if (d96 != old_per) begin
            fail_clause(
              "I2",
              $sformatf(
                "ts96 illegal period-transition increment %0d",
                d96
              )
            );
          end

        end else if (d96 != new_per) begin
          fail_clause(
            "I2",
            "ts96 returned to old/illegal period after new period took effect"
          );
        end

        if (!seen64) begin
          if (d64 == new_per) begin
            seen64 = 1'b1;
            first64 = i;

          end else if (d64 != old_per) begin
            fail_clause(
              "I2",
              $sformatf(
                "ts64 illegal period-transition increment %0d",
                d64
              )
            );
          end

        end else if (d64 != new_per) begin
          fail_clause(
            "I2",
            "ts64 returned to old/illegal period after new period took effect"
          );
        end

        if (ts_step !== 1'b0)
          fail_clause(
            "A4/S3",
            "period update spuriously asserted ts_step_o"
          );

        if (adj_active !== 1'b0)
          fail_clause(
            "A3",
            "period update spuriously asserted adj_active_o"
          );

        prev96 = cur96;
        prev64 = cur64;
      end

      if (!seen96)
        fail_clause(
          "I2/L1",
          "ts96 never reflected the replacement period"
        );

      if (!seen64)
        fail_clause(
          "I2/L1",
          "ts64 never reflected the replacement period"
        );

      if ((first96 > 4) && (first64 > 4))
        fail_clause(
          "L1",
          $sformatf(
            "first visible period effect was later than 4 cycles (ts96=%0d ts64=%0d)",
            first96,
            first64
          )
        );
    end
  endtask

  // ---------------------------------------------------------------------------
  // DRIFT
  // ---------------------------------------------------------------------------

  task automatic test_drift_latency_rate1(
    input longint signed per_v
  );
    longint signed prev96;
    longint signed prev64;
    longint signed cur96;
    longint signed cur64;
    longint signed d96;
    longint signed d64;
    longint signed new_delta;

    int i;
    int first96;
    int first64;

    bit seen96;
    bit seen64;

    begin
      new_delta = per_v + 64'sd13;

      first96 = -1;
      first64 = -1;

      seen96 = 1'b0;
      seen64 = 1'b0;

      @(negedge clk);

      prev96 = t96_fns(ts96);
      prev64 = t64_fns(ts64);

      drift_ns = 4'h0;
      drift_fns = 16'h000d;
      drift_rate = 16'd1;
      drift_valid = 1'b1;

      for (i = 0; i < 12; i = i + 1) begin
        @(negedge clk);

        cur96 = t96_fns(ts96);
        cur64 = t64_fns(ts64);

        d96 = cur96 - prev96;
        d64 = cur64 - prev64;

        if (i == 0) begin
          drift_valid = 1'b0;

          // D1 requires the complete command to be latched.
          drift_ns = 4'h7;
          drift_fns = 16'h1234;
          drift_rate = 16'd9;
        end

        if (!seen96) begin
          if (d96 == new_delta) begin
            seen96 = 1'b1;
            first96 = i;

          end else if (d96 != per_v) begin
            fail_clause(
              "D1/D2",
              $sformatf(
                "ts96 illegal rate-1 drift transition delta %0d",
                d96
              )
            );
          end

        end else if (d96 != new_delta) begin
          fail_clause(
            "D2",
            "ts96 rate-1 drift was not applied on every increment"
          );
        end

        if (!seen64) begin
          if (d64 == new_delta) begin
            seen64 = 1'b1;
            first64 = i;

          end else if (d64 != per_v) begin
            fail_clause(
              "D1/D2",
              $sformatf(
                "ts64 illegal rate-1 drift transition delta %0d",
                d64
              )
            );
          end

        end else if (d64 != new_delta) begin
          fail_clause(
            "D2",
            "ts64 rate-1 drift was not applied on every increment"
          );
        end

        prev96 = cur96;
        prev64 = cur64;
      end

      if (!seen96)
        fail_clause(
          "D1/D2/L1",
          "ts96 never reflected rate-1 drift command"
        );

      if (!seen64)
        fail_clause(
          "D1/D2/L1",
          "ts64 never reflected rate-1 drift command"
        );

      if ((first96 > 4) && (first64 > 4))
        fail_clause(
          "L1",
          $sformatf(
            "first visible drift effect was later than 4 cycles (ts96=%0d ts64=%0d)",
            first96,
            first64
          )
        );
    end
  endtask

  task automatic check_drift_pattern(
    input logic [3:0] d_ns,
    input logic [15:0] d_fns,
    input int rate_v,
    input longint signed per_v,
    input int ncyc
  );
    longint signed drift_v;
    longint signed prev96;
    longint signed prev64;
    longint signed cur96;
    longint signed cur64;
    longint signed d96;
    longint signed d64;

    int i;
    int c96;
    int c64;
    int last96;
    int last64;

    begin
      drift_v = s20_fns(d_ns, d_fns);

      bfm_drift(
        d_ns,
        d_fns,
        rate_v[15:0]
      );

      // D1 requires the command payload/rate to be latched.
      drift_ns = 4'h6;
      drift_fns = 16'hd00d;
      drift_rate = 16'd9;

      bfm_wait(8);

      c96 = 0;
      c64 = 0;

      last96 = -1;
      last64 = -1;

      @(negedge clk);

      prev96 = t96_fns(ts96);
      prev64 = t64_fns(ts64);

      for (i = 0; i < ncyc; i = i + 1) begin
        @(negedge clk);

        cur96 = t96_fns(ts96);
        cur64 = t64_fns(ts64);

        d96 = cur96 - prev96;
        d64 = cur64 - prev64;

        if (d96 == per_v + drift_v) begin
          c96 = c96 + 1;

          if ((last96 >= 0) && ((i - last96) != rate_v))
            fail_clause(
              "D2",
              $sformatf(
                "ts96 drift spacing=%0d expected=%0d",
                i - last96,
                rate_v
              )
            );

          last96 = i;

        end else if (d96 != per_v) begin
          fail_clause(
            "I1/D3",
            $sformatf(
              "ts96 illegal drift increment %0d, period=%0d drift=%0d",
              d96,
              per_v,
              drift_v
            )
          );
        end

        if (d64 == per_v + drift_v) begin
          c64 = c64 + 1;

          if ((last64 >= 0) && ((i - last64) != rate_v))
            fail_clause(
              "D2",
              $sformatf(
                "ts64 drift spacing=%0d expected=%0d",
                i - last64,
                rate_v
              )
            );

          last64 = i;

        end else if (d64 != per_v) begin
          fail_clause(
            "I1/D3",
            $sformatf(
              "ts64 illegal drift increment %0d, period=%0d drift=%0d",
              d64,
              per_v,
              drift_v
            )
          );
        end

        if (ts_step !== 1'b0)
          fail_clause(
            "A4/S3",
            "drift update/use spuriously asserted ts_step_o"
          );

        if (adj_active !== 1'b0)
          fail_clause(
            "A3",
            "drift update/use spuriously asserted adj_active_o"
          );

        prev96 = cur96;
        prev64 = cur64;
      end

      if (c96 != (ncyc / rate_v))
        fail_clause(
          "D2",
          $sformatf(
            "ts96 drift count=%0d expected=%0d",
            c96,
            ncyc / rate_v
          )
        );

      if (c64 != (ncyc / rate_v))
        fail_clause(
          "D2",
          $sformatf(
            "ts64 drift count=%0d expected=%0d",
            c64,
            ncyc / rate_v
          )
        );
    end
  endtask

  // ---------------------------------------------------------------------------
  // COUNTED ADJUSTMENT
  // ---------------------------------------------------------------------------

  task automatic run_adjust_case(
    input logic [3:0] a_ns,
    input logic [15:0] a_fns,
    input int cnt,
    input longint signed per_v
  );
    longint signed adj_v;
    longint signed prev96;
    longint signed prev64;
    longint signed cur96;
    longint signed cur64;
    longint signed d96;
    longint signed d64;

    int span;
    int i;
    int c96;
    int c64;
    int ca;
    int first96;
    int first64;
    int st96;
    int st64;
    int sta;

    begin
      adj_v = s20_fns(a_ns, a_fns);

      span = cnt + 12;

      c96 = 0;
      c64 = 0;
      ca = 0;

      first96 = -1;
      first64 = -1;

      st96 = 0;
      st64 = 0;
      sta = 0;

      @(negedge clk);

      prev96 = t96_fns(ts96);
      prev64 = t64_fns(ts64);

      adj_ns = a_ns;
      adj_fns = a_fns;
      adj_count = cnt[15:0];
      adj_valid = 1'b1;

      for (i = 0; i < span; i = i + 1) begin
        @(negedge clk);

        cur96 = t96_fns(ts96);
        cur64 = t64_fns(ts64);

        d96 = cur96 - prev96;
        d64 = cur64 - prev64;

        if (i == 0) begin
          adj_valid = 1'b0;

          // A1 requires both the adjustment and its count to be latched.
          adj_ns = 4'h7;
          adj_fns = 16'h55aa;
          adj_count = 16'd1;
        end

        if (d96 == per_v + adj_v) begin
          if (cnt == 0)
            fail_clause(
              "A2",
              "ts96 applied a zero-count adjustment"
            );

          c96 = c96 + 1;

          if (first96 < 0)
            first96 = i;

          if (st96 == 2)
            fail_clause(
              "A2",
              "ts96 adjusted increments were not consecutive"
            );

          st96 = 1;

        end else if (d96 == per_v) begin
          if (st96 == 1)
            st96 = 2;

        end else begin
          fail_clause(
            "I1/A5",
            $sformatf(
              "ts96 illegal adjustment increment %0d, expected %0d or %0d",
              d96,
              per_v,
              per_v + adj_v
            )
          );
        end

        if (d64 == per_v + adj_v) begin
          if (cnt == 0)
            fail_clause(
              "A2",
              "ts64 applied a zero-count adjustment"
            );

          c64 = c64 + 1;

          if (first64 < 0)
            first64 = i;

          if (st64 == 2)
            fail_clause(
              "A2",
              "ts64 adjusted increments were not consecutive"
            );

          st64 = 1;

        end else if (d64 == per_v) begin
          if (st64 == 1)
            st64 = 2;

        end else begin
          fail_clause(
            "I1/A5",
            $sformatf(
              "ts64 illegal adjustment increment %0d, expected %0d or %0d",
              d64,
              per_v,
              per_v + adj_v
            )
          );
        end

        if (adj_active === 1'b1) begin
          if (cnt == 0)
            fail_clause(
              "A3",
              "adj_active_o asserted for zero-count adjustment"
            );

          ca = ca + 1;

          if (sta == 2)
            fail_clause(
              "A3",
              "adj_active_o cycles were not consecutive"
            );

          sta = 1;

        end else if (adj_active === 1'b0) begin
          if (sta == 1)
            sta = 2;

        end else begin
          fail_clause(
            "A3",
            "adj_active_o is X/Z"
          );
        end

        if (ts_step !== adj_active)
          fail_clause(
            "A4",
            "without a set, ts_step_o did not exactly match adj_active_o"
          );

        prev96 = cur96;
        prev64 = cur64;
      end

      if (c96 != cnt)
        fail_clause(
          "A2",
          $sformatf(
            "ts96 adjusted increment count=%0d expected=%0d",
            c96,
            cnt
          )
        );

      if (c64 != cnt)
        fail_clause(
          "A2",
          $sformatf(
            "ts64 adjusted increment count=%0d expected=%0d",
            c64,
            cnt
          )
        );

      if (ca != cnt)
        fail_clause(
          "A3",
          $sformatf(
            "adj_active_o count=%0d expected=%0d",
            ca,
            cnt
          )
        );

      if ((cnt > 0) &&
          (first96 < 0) &&
          (first64 < 0))
        fail_clause(
          "L1",
          "adjustment never became visible"
        );

      if ((cnt > 0) &&
          (first96 > 4) &&
          (first64 > 4))
        fail_clause(
          "L1",
          $sformatf(
            "first visible adjustment effect was later than 4 cycles (ts96=%0d ts64=%0d)",
            first96,
            first64
          )
        );
    end
  endtask

  // ---------------------------------------------------------------------------
  // SIMULTANEOUS OFFSET + DRIFT
  // ---------------------------------------------------------------------------

  task automatic test_combined_adjust_and_drift(
    input longint signed per_v
  );
    longint signed prev96;
    longint signed prev64;
    longint signed cur96;
    longint signed cur64;
    longint signed d96;
    longint signed d64;
    longint signed adj_v;
    longint signed drift_v;

    int i;
    int ac96;
    int ac64;
    int dc96;
    int dc64;
    int lastd96;
    int lastd64;
    int ast96;
    int ast64;

    begin
      adj_v = 64'sd100;
      drift_v = 64'sd7;

      bfm_drift(
        4'h0,
        16'h0007,
        16'd3
      );

      bfm_wait(8);

      ac96 = 0;
      ac64 = 0;
      dc96 = 0;
      dc64 = 0;

      lastd96 = -1;
      lastd64 = -1;

      ast96 = 0;
      ast64 = 0;

      @(negedge clk);

      prev96 = t96_fns(ts96);
      prev64 = t64_fns(ts64);

      adj_ns = 4'h0;
      adj_fns = 16'h0064;
      adj_count = 16'd9;
      adj_valid = 1'b1;

      for (i = 0; i < 24; i = i + 1) begin
        @(negedge clk);

        cur96 = t96_fns(ts96);
        cur64 = t64_fns(ts64);

        d96 = cur96 - prev96;
        d64 = cur64 - prev64;

        if (i == 0) begin
          adj_valid = 1'b0;

          adj_ns = 4'h7;
          adj_fns = 16'h55aa;
          adj_count = 16'd1;
        end

        if ((d96 == per_v + adj_v) ||
            (d96 == per_v + adj_v + drift_v)) begin

          ac96 = ac96 + 1;

          if (ast96 == 2)
            fail_clause(
              "I1/A2",
              "ts96 adjustment was not consecutive when drift overlapped"
            );

          ast96 = 1;

        end else if ((d96 == per_v) ||
                     (d96 == per_v + drift_v)) begin

          if (ast96 == 1)
            ast96 = 2;

        end else begin
          fail_clause(
            "I1",
            $sformatf(
              "ts96 did not form period+adjustment+drift correctly: delta=%0d",
              d96
            )
          );
        end

        if ((d64 == per_v + adj_v) ||
            (d64 == per_v + adj_v + drift_v)) begin

          ac64 = ac64 + 1;

          if (ast64 == 2)
            fail_clause(
              "I1/A2",
              "ts64 adjustment was not consecutive when drift overlapped"
            );

          ast64 = 1;

        end else if ((d64 == per_v) ||
                     (d64 == per_v + drift_v)) begin

          if (ast64 == 1)
            ast64 = 2;

        end else begin
          fail_clause(
            "I1",
            $sformatf(
              "ts64 did not form period+adjustment+drift correctly: delta=%0d",
              d64
            )
          );
        end

        if ((d96 == per_v + drift_v) ||
            (d96 == per_v + adj_v + drift_v)) begin

          dc96 = dc96 + 1;

          if ((lastd96 >= 0) &&
              ((i - lastd96) != 3))
            fail_clause(
              "D2",
              "ts96 drift spacing changed while adjustment overlapped"
            );

          lastd96 = i;
        end

        if ((d64 == per_v + drift_v) ||
            (d64 == per_v + adj_v + drift_v)) begin

          dc64 = dc64 + 1;

          if ((lastd64 >= 0) &&
              ((i - lastd64) != 3))
            fail_clause(
              "D2",
              "ts64 drift spacing changed while adjustment overlapped"
            );

          lastd64 = i;
        end

        if (ts_step !== adj_active)
          fail_clause(
            "A4",
            "ts_step_o did not match adj_active_o in combined adjustment/drift test"
          );

        prev96 = cur96;
        prev64 = cur64;
      end

      if (ac96 != 9)
        fail_clause(
          "A2/I1",
          $sformatf(
            "ts96 combined-case adjustment count=%0d expected 9",
            ac96
          )
        );

      if (ac64 != 9)
        fail_clause(
          "A2/I1",
          $sformatf(
            "ts64 combined-case adjustment count=%0d expected 9",
            ac64
          )
        );

      if (dc96 != 8)
        fail_clause(
          "D2/I1",
          $sformatf(
            "ts96 combined-case drift count=%0d expected 8",
            dc96
          )
        );

      if (dc64 != 8)
        fail_clause(
          "D2/I1",
          $sformatf(
            "ts64 combined-case drift count=%0d expected 8",
            dc64
          )
        );
    end
  endtask

  // ---------------------------------------------------------------------------
  // SETTING AND INDEPENDENCE
  // ---------------------------------------------------------------------------

  task automatic test_set_independence(
    input longint signed per_v
  );
    longint signed prev64;
    longint signed cur64;
    longint signed prev96;
    longint signed cur96;

    logic [95:0] wanted96;
    logic [63:0] wanted64;

    begin
      wanted96 =
          {48'd2, 2'b00, 30'd123456789, 16'h1357};

      @(negedge clk);

      prev64 = t64_fns(ts64);

      set_ts96 = wanted96;
      set_ts96_valid = 1'b1;

      @(negedge clk);

      cur64 = t64_fns(ts64);
      set_ts96_valid = 1'b0;

      if (ts96 !== wanted96)
        fail_clause(
          "S1/F1",
          "set_ts96_valid_i did not set ts96_o exactly"
        );

      if ((cur64 - prev64) != per_v)
        fail_clause(
          "S4",
          $sformatf(
            "setting ts96 disturbed ts64 increment: got %0d expected %0d",
            cur64 - prev64,
            per_v
          )
        );

      if (ts_step !== 1'b1)
        fail_clause(
          "S3",
          "ts_step_o was not asserted on 96-bit set cycle"
        );

      if (pps !== 1'b0)
        fail_clause(
          "W3",
          "setting ts96 without wrapping spuriously asserted pps_o"
        );

      @(negedge clk);

      if (ts_step !== 1'b0)
        fail_clause(
          "S3",
          "ts_step_o lasted more than one cycle after 96-bit set"
        );

      wanted64 =
          {48'd345678901, 16'h2468};

      prev96 = t96_fns(ts96);

      set_ts64 = wanted64;
      set_ts64_valid = 1'b1;

      @(negedge clk);

      cur96 = t96_fns(ts96);
      set_ts64_valid = 1'b0;

      if (ts64 !== wanted64)
        fail_clause(
          "S2/F2",
          "set_ts64_valid_i did not set ts64_o exactly"
        );

      if ((cur96 - prev96) != per_v)
        fail_clause(
          "S4",
          $sformatf(
            "setting ts64 disturbed ts96 increment: got %0d expected %0d",
            cur96 - prev96,
            per_v
          )
        );

      if (ts_step !== 1'b1)
        fail_clause(
          "S3",
          "ts_step_o was not asserted on 64-bit set cycle"
        );

      @(negedge clk);

      if (ts_step !== 1'b0)
        fail_clause(
          "S3",
          "ts_step_o lasted more than one cycle after 64-bit set"
        );
    end
  endtask

  task automatic test_drift_survives_set96(
    input longint signed per_v
  );
    longint signed prev64;
    longint signed cur64;
    longint signed d64;
    longint signed drift_v;

    int i;
    int cnt;
    int last_i;

    begin
      drift_v = 64'sd11;

      bfm_drift(
        4'h0,
        16'h000b,
        16'd4
      );

      bfm_wait(8);

      cnt = 0;
      last_i = -1;

      @(negedge clk);

      prev64 = t64_fns(ts64);

      for (i = 0; i < 16; i = i + 1) begin
        if (i == 5) begin
          set_ts96 =
              {48'd4, 2'b00, 30'd1000, 16'h0000};

          set_ts96_valid = 1'b1;
        end

        @(negedge clk);

        cur64 = t64_fns(ts64);
        d64 = cur64 - prev64;

        if (i == 5)
          set_ts96_valid = 1'b0;

        if (d64 == per_v + drift_v) begin
          cnt = cnt + 1;

          if ((last_i >= 0) &&
              ((i - last_i) != 4))
            fail_clause(
              "S4/D2",
              "setting ts96 changed ts64 drift spacing"
            );

          last_i = i;

        end else if (d64 != per_v) begin
          fail_clause(
            "S4/I1",
            $sformatf(
              "setting ts96 disturbed ts64 delta: %0d",
              d64
            )
          );
        end

        if (i == 5) begin
          if (ts_step !== 1'b1)
            fail_clause(
              "S3",
              "ts_step_o missing on set during drift test"
            );

        end else if (ts_step !== 1'b0) begin
          fail_clause(
            "S3",
            "ts_step_o asserted outside set during drift continuity test"
          );
        end

        prev64 = cur64;
      end

      if (cnt != 4)
        fail_clause(
          "S4/D2",
          $sformatf(
            "drift count across ts96 set was %0d expected 4",
            cnt
          )
        );
    end
  endtask

  task automatic test_adjust_survives_set96(
    input longint signed per_v
  );
    longint signed prev64;
    longint signed cur64;
    longint signed d64;
    longint signed adj_v;

    int i;
    int cnt;
    int active_cnt;
    int st;

    begin
      adj_v = 64'sd8;

      cnt = 0;
      active_cnt = 0;
      st = 0;

      @(negedge clk);

      prev64 = t64_fns(ts64);

      adj_ns = 4'h0;
      adj_fns = 16'h0008;
      adj_count = 16'd20;
      adj_valid = 1'b1;

      for (i = 0; i < 32; i = i + 1) begin
        @(negedge clk);

        cur64 = t64_fns(ts64);
        d64 = cur64 - prev64;

        if (i == 0)
          adj_valid = 1'b0;

        if (d64 == per_v + adj_v) begin
          cnt = cnt + 1;

          if (st == 2)
            fail_clause(
              "S4/A2",
              "ts64 adjustment became nonconsecutive across ts96 set"
            );

          st = 1;

        end else if (d64 == per_v) begin
          if (st == 1)
            st = 2;

        end else begin
          fail_clause(
            "S4/I1",
            $sformatf(
              "ts64 illegal delta during set/adjust interaction: %0d",
              d64
            )
          );
        end

        if (adj_active === 1'b1)
          active_cnt = active_cnt + 1;

        if (i == 5) begin
          set_ts96 =
              {48'd5, 2'b00, 30'd2000, 16'h0000};

          set_ts96_valid = 1'b1;
        end

        if (i == 6)
          set_ts96_valid = 1'b0;

        if (i == 6) begin
          if (ts_step !== 1'b1)
            fail_clause(
              "S3/A4",
              "ts_step_o missing when set overlaps adjustment"
            );

        end else if (ts_step !== adj_active) begin
          fail_clause(
            "A4",
            "ts_step_o did not match adj_active_o outside injected set cycle"
          );
        end

        prev64 = cur64;
      end

      if (cnt != 20)
        fail_clause(
          "S4/A2",
          $sformatf(
            "setting ts96 disturbed ts64 adjustment count: %0d expected 20",
            cnt
          )
        );

      if (active_cnt != 20)
        fail_clause(
          "S4/A3",
          $sformatf(
            "setting ts96 disturbed adj_active count: %0d expected 20",
            active_cnt
          )
        );
    end
  endtask

  // ---------------------------------------------------------------------------
  // FRACTIONAL ARITHMETIC
  // ---------------------------------------------------------------------------

  task automatic test_fractional_carry;
    begin
      configure_drift_zero();

      test_period_change(
        4'h0,
        16'h0003,
        PER_1_FNS
      );

      bfm_wait(8);

      bfm_set64(
        48'd100,
        16'hfffe
      );

      if (ts64 !== {48'd100, 16'hfffe})
        fail_clause(
          "S2",
          "fractional-carry setup set64 failed"
        );

      @(negedge clk);

      if (ts64[63:16] !== 48'd101)
        fail_clause(
          "F2/I1",
          $sformatf(
            "fractional carry produced ns=%0d expected 101",
            ts64[63:16]
          )
        );

      if (ts64[15:0] !== 16'h0001)
        fail_clause(
          "F3/I1",
          $sformatf(
            "fractional carry produced fns=0x%04x expected 0x0001",
            ts64[15:0]
          )
        );

      // Cross the second boundary by just one fractional unit:
      // 999999999.fffe + 3 fns => next second, 0.0001.
      bfm_set96(
        48'd6,
        30'd999999999,
        16'hfffe
      );

      if (pps !== 1'b0)
        fail_clause(
          "W3",
          "set near fractional wrap spuriously asserted pps_o"
        );

      @(negedge clk);

      if (ts96 !==
          {48'd7, 2'b00, 30'd0, 16'h0001})
        fail_clause(
          "F1/F3/W1",
          "fractional one-second wrap did not land at sec+1, ns=0, fns=1"
        );

      if (pps !== 1'b1)
        fail_clause(
          "W3",
          "pps_o missing on fractional one-second wrap"
        );

      @(negedge clk);

      if (ts96 !==
          {48'd7, 2'b00, 30'd0, 16'h0004})
        fail_clause(
          "F1/F3/I1",
          "ts96 did not continue exactly after fractional wrap"
        );

      if (pps !== 1'b0)
        fail_clause(
          "W3",
          "pps_o lasted more than one cycle after fractional wrap"
        );
    end
  endtask

  // ---------------------------------------------------------------------------
  // ONE-SECOND WRAP / PPS
  // ---------------------------------------------------------------------------

  task automatic test_wrap_and_pps;
    longint signed model_sub;
    longint signed per_v;
    longint signed model_sec;
    longint signed model_ns64;
    longint signed model_fns64;

    int i;
    bit wrap_now;

    begin
      configure_drift_zero();

      test_period_change(
        4'h4,
        16'h0000,
        64'sd3
      );

      bfm_wait(8);

      per_v = 64'sd262144;

      bfm_set96(
        48'd7,
        30'd999999990,
        16'h0000
      );

      if (ts96 !==
          {48'd7, 2'b00, 30'd999999990, 16'h0000})
        fail_clause(
          "S1",
          "wrap test setup set96 failed"
        );

      if (pps !== 1'b0)
        fail_clause(
          "W3",
          "pps_o asserted merely because set96 was near boundary"
        );

      model_sec = 7;

      model_sub =
          64'sd999999990 *
          64'sd65536;

      for (i = 0; i < 6; i = i + 1) begin
        @(negedge clk);

        model_sub = model_sub + per_v;
        wrap_now = 1'b0;

        if (model_sub >= ONE_SECOND_FNS) begin
          model_sub =
              model_sub -
              ONE_SECOND_FNS;

          model_sec =
              model_sec + 1;

          wrap_now = 1'b1;
        end

        if (ts96[95:48] != model_sec)
          fail_clause(
            "W1/F1",
            $sformatf(
              "ts96 seconds=%0d expected=%0d",
              ts96[95:48],
              model_sec
            )
          );

        if (ts96[47:46] !== 2'b00)
          fail_clause(
            "F1",
            "ts96 reserved bits nonzero during wrap test"
          );

        if (ts96[45:16] !=
            (model_sub / 64'sd65536))
          fail_clause(
            "W1/F1",
            $sformatf(
              "ts96 ns=%0d expected=%0d",
              ts96[45:16],
              model_sub / 64'sd65536
            )
          );

        if (ts96[15:0] !=
            (model_sub % 64'sd65536))
          fail_clause(
            "F3/W1",
            $sformatf(
              "ts96 fns=%0d expected=%0d",
              ts96[15:0],
              model_sub % 64'sd65536
            )
          );

        if (pps !== wrap_now)
          fail_clause(
            "W3",
            $sformatf(
              "pps_o=%0b expected=%0b on wrap-model cycle",
              pps,
              wrap_now
            )
          );
      end

      // Move ts96 safely away from its own wrap while checking ts64.
      bfm_set96(
        48'd8,
        30'd1000,
        16'h0000
      );

      bfm_set64(
        48'd999999990,
        16'h0000
      );

      model_ns64 = 999999990;
      model_fns64 = 0;

      for (i = 0; i < 5; i = i + 1) begin
        @(negedge clk);

        model_fns64 =
            model_fns64 +
            per_v;

        model_ns64 =
            999999990 +
            (model_fns64 / 64'sd65536);

        if (ts64[63:16] != model_ns64)
          fail_clause(
            "W2/F2",
            $sformatf(
              "ts64 ns=%0d expected=%0d (must not wrap at 1 second)",
              ts64[63:16],
              model_ns64
            )
          );

        if (ts64[15:0] !=
            (model_fns64 % 64'sd65536))
          fail_clause(
            "F3/W2",
            "ts64 fractional field mismatch in no-wrap test"
          );
      end

      if (ts64[63:16] < 48'd1000000000)
        fail_clause(
          "W2",
          "ts64 wrapped at the one-second boundary"
        );
    end
  endtask

  // ---------------------------------------------------------------------------
  // RESET WHILE ADJUSTMENT IS OUTSTANDING
  // ---------------------------------------------------------------------------

  task automatic test_reset_cancels_adjustment;
    begin
      configure_drift_zero();

      test_period_change(
        4'h2,
        16'h0000,
        PER_4_FNS
      );

      bfm_wait(8);

      bfm_adjust(
        4'h0,
        16'h0100,
        16'd100
      );

      bfm_wait(10);

      bfm_reset(4);

      if (ts96 !== 96'd0)
        fail_clause(
          "R2",
          "reset did not leave ts96_o at zero"
        );

      if (ts64 !== 64'd0)
        fail_clause(
          "R2",
          "reset did not leave ts64_o at zero"
        );

      if (adj_active !== 1'b0)
        fail_clause(
          "R2/A3",
          "reset did not cancel outstanding adjustment activity"
        );

      check_default_run(10);
    end
  endtask

  // ---------------------------------------------------------------------------
  // TEST SEQUENCE
  // ---------------------------------------------------------------------------

  initial begin
    bfm_reset(5);

    if (ts96 !== 96'd0)
      fail_clause(
        "R2",
        "ts96_o not zero after reset release"
      );

    if (ts64 !== 64'd0)
      fail_clause(
        "R2",
        "ts64_o not zero after reset release"
      );

    // Reset defaults:
    // period = {6,16'h6666}, drift = +2 fns, drift rate = 5.
    check_default_run(20);

    // Disable observable drift and replace period.
    configure_drift_zero();

    test_period_change(
      4'h3,
      16'h4000,
      RESET_PERIOD_FNS
    );

    bfm_wait(8);

    // L1 for drift is easy to observe using rate=1.
    test_drift_latency_rate1(
      PER_325_FNS
    );

    // Positive and negative drift.
    check_drift_pattern(
      4'h0,
      16'h0007,
      4,
      PER_325_FNS,
      20
    );

    check_drift_pattern(
      4'hf,
      16'hfffb,
      3,
      PER_325_FNS,
      15
    );

    // Clean setup for adjustment tests.
    configure_drift_zero();

    test_period_change(
      4'h4,
      16'h0000,
      PER_325_FNS
    );

    bfm_wait(8);

    // Positive adjustment: +1.5 ns, exactly 7 increments.
    run_adjust_case(
      4'h1,
      16'h8000,
      7,
      PER_4_FNS
    );

    // Negative adjustment: -1.25 ns, exactly 5 increments.
    run_adjust_case(
      4'he,
      16'hc000,
      5,
      PER_4_FNS
    );

    // Zero count must mean zero adjusted increments and zero active cycles.
    run_adjust_case(
      4'h1,
      16'h0000,
      0,
      PER_4_FNS
    );

    // I1: period + adjustment + drift must really be summed.
    test_combined_adjust_and_drift(
      PER_4_FNS
    );

    configure_drift_zero();

    // S1-S4.
    test_set_independence(
      PER_4_FNS
    );

    // Setting one accumulator must not perturb the drift schedule.
    test_drift_survives_set96(
      PER_4_FNS
    );

    configure_drift_zero();

    // Setting one accumulator must not perturb an outstanding adjustment.
    test_adjust_survives_set96(
      PER_4_FNS
    );

    // Exercise the full 16-bit adjustment-count boundary.
    test_period_change(
      4'h1,
      16'h0000,
      PER_4_FNS
    );

    bfm_wait(8);

    bfm_set96(
      48'd0,
      30'd1000,
      16'h0000
    );

    bfm_set64(
      48'd1000,
      16'h0000
    );

    run_adjust_case(
      4'h0,
      16'h0001,
      65535,
      PER_1_FNS
    );

    // Exact 1/65536 ns arithmetic.
    test_fractional_carry();

    // W1-W3 and F1-F3 at the second boundary.
    test_wrap_and_pps();

    // R2: restore defaults and cancel adjustment still owed.
    test_reset_cancels_adjustment();

    if (errors == 0)
      $display("RESULT: PASS");
    else
      $display("RESULT: FAIL");

    $finish;
  end

endmodule