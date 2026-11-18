module ptp_time_base_tb;

  // ---------------------------------------------------------------------------
  // PROVIDED PLUMBING -- drives the module, checks nothing.
  // ---------------------------------------------------------------------------
  // This exists so you spend your effort on checking rather than on wiring. It
  // has been compiled and run against a correct design.
  //
  // What it does: generates the clock, sequences reset, connects the design, and
  // presents each control input for exactly one cycle, off the sampling edge.
  //
  // What it does NOT do: it keeps no model of the time base, computes no expected
  // value, counts nothing, and draws no conclusion from any output. The
  // arithmetic and every check are yours to write.
  // ---------------------------------------------------------------------------

  // ---- clock ---------------------------------------------------------------
  logic clk = 1'b0;
  always #5 clk = ~clk;

  // A free-running cycle count, for your own bookkeeping and messages.
  int bfm_cycle = 0;
  always @(posedge clk) if (!rst) bfm_cycle <= bfm_cycle + 1;

  // ---- reset ---------------------------------------------------------------
  logic rst = 1'b1;      // SYNCHRONOUS, ACTIVE HIGH

  // Asserts reset, holds it, and releases it OFF the sampling edge, so nothing
  // you or the design samples changes in the same timestep as the change.
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
  // Each of these holds its valid across exactly ONE rising edge, and changes
  // the payload at the negative edge.
  //
  // NOTE ON WHEN TO ARM YOUR OWN COUNTERS: the contract does not fix how many
  // cycles pass between a valid and its first effect. If you reset a counter
  // AFTER calling one of these, a design that acts immediately will already
  // have started and you will lose the first cycle. Arm before you call.

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

  // ---- idle everything at time zero ----------------------------------------
  initial begin
    set_ts96 = '0; set_ts96_valid = 1'b0; set_ts64 = '0; set_ts64_valid = 1'b0;
    period_ns = '0; period_fns = '0; period_valid = 1'b0;
    adj_ns = '0; adj_fns = '0; adj_count = '0; adj_valid = 1'b0;
    drift_ns = '0; drift_fns = '0; drift_rate = '0; drift_valid = 1'b0;
  end

  // ---- watchdog ------------------------------------------------------------
  // Yours to keep. It fires regardless of what the design does, which is what
  // the termination requirement demands: a design that never advances must
  // produce a verdict, and a hang is not a verdict.
  initial begin
    #3_000_000;
    $display("RESULT: FAIL (watchdog: no verdict reached)");
    $finish;
  end

  // ---------------------------------------------------------------------------
  // Exact arithmetic and cycle-bookkeeping checker.
  // ---------------------------------------------------------------------------

  localparam int MAXS = 8192;
  localparam longint signed P0 = 64'sd419430;       // 6 ns + 16'h6666
  localparam longint signed P1 = 64'sd528948;       // 8 ns + 16'h1234
  localparam longint signed PWRAP = 64'sd65537;     // 1 ns + 1 fns
  localparam longint signed SUBSEC = 64'sd65536000000000;

  int errors = 0;
  int abs_cycle = 0;
  int rel_cycle = 0;
  int samp = 0;

  int period_accept = 0;
  int adj_accept = 0;
  int drift_accept = 0;
  int set96_accept = 0;
  int set64_accept = 0;

  logic set_fire = 1'b0;

  logic [95:0] h96 [0:MAXS-1];
  logic [63:0] h64 [0:MAXS-1];
  logic        hstep [0:MAXS-1];
  logic        hactive [0:MAXS-1];
  logic        hpps [0:MAXS-1];
  logic        hsetfire [0:MAXS-1];
  int          habs [0:MAXS-1];
  int          hrel [0:MAXS-1];

  task automatic note_error(input string clause, input string msg);
    begin
      errors = errors + 1;
      if (errors <= 80)
        $display("[%0t] %s: %s", $time, clause, msg);
    end
  endtask

  // Acceptance cycles are recorded at the sampling edge. Outputs are recorded
  // half a cycle later, after all nonblocking updates from that edge.
  always @(posedge clk) begin
    abs_cycle = abs_cycle + 1;
    if (rst) begin
      rel_cycle = 0;
      set_fire = 1'b0;
    end else begin
      rel_cycle = rel_cycle + 1;
      set_fire = set_ts96_valid || set_ts64_valid;
      if (period_valid)   period_accept = abs_cycle;
      if (adj_valid)      adj_accept = abs_cycle;
      if (drift_valid)    drift_accept = abs_cycle;
      if (set_ts96_valid) set96_accept = abs_cycle;
      if (set_ts64_valid) set64_accept = abs_cycle;
    end
  end

  always @(negedge clk) begin
    if (!rst && rel_cycle > 0 && samp < MAXS-1) begin
      samp = samp + 1;
      h96[samp] = ts96;
      h64[samp] = ts64;
      hstep[samp] = ts_step;
      hactive[samp] = adj_active;
      hpps[samp] = pps;
      hsetfire[samp] = set_fire;
      habs[samp] = abs_cycle;
      hrel[samp] = rel_cycle;

      // F1 and W1 apply even during increment warm-up windows.
      if (ts96[47:46] !== 2'b00)
        note_error("F1", $sformatf("cycle %0d: reserved ts96 bits are %b",
                                   rel_cycle, ts96[47:46]));
      if (ts96[45:16] >= 30'd1000000000)
        note_error("W1", $sformatf("cycle %0d: ns field is %0d",
                                   rel_cycle, ts96[45:16]));

      // A4 and S3 completely determine ts_step: adjustment-active cycles and
      // accepted set cycles, with no other sources.
      if (ts_step !== (adj_active | set_fire))
        note_error("A4/S3",
                   $sformatf("cycle %0d: ts_step=%b adj_active=%b set=%b",
                             rel_cycle, ts_step, adj_active, set_fire));

      if ((adj_active !== 1'b0) && (adj_active !== 1'b1))
        note_error("A3", $sformatf("cycle %0d: adj_active is unknown", rel_cycle));
      if ((pps !== 1'b0) && (pps !== 1'b1))
        note_error("W3", $sformatf("cycle %0d: pps is unknown", rel_cycle));
    end
  end

  function automatic int idx_at(input int a);
    int i;
    begin
      idx_at = 0;
      for (i = 1; i <= samp; i = i + 1)
        if ((idx_at == 0) && (habs[i] == a))
          idx_at = i;
    end
  endfunction

  function automatic longint signed delta96(input logic [95:0] prev,
                                             input logic [95:0] cur);
    longint signed prev_sub;
    longint signed cur_sub;
    longint signed sec_d;
    begin
      prev_sub = prev[45:16];
      prev_sub = prev_sub * 64'sd65536 + prev[15:0];
      cur_sub = cur[45:16];
      cur_sub = cur_sub * 64'sd65536 + cur[15:0];
      sec_d = cur[95:48];
      sec_d = sec_d - prev[95:48];
      delta96 = sec_d * SUBSEC + cur_sub - prev_sub;
    end
  endfunction

  function automatic longint signed delta64(input logic [63:0] prev,
                                             input logic [63:0] cur);
    longint signed prev_total;
    longint signed cur_total;
    begin
      prev_total = prev[63:16];
      prev_total = prev_total * 64'sd65536 + prev[15:0];
      cur_total = cur[63:16];
      cur_total = cur_total * 64'sd65536 + cur[15:0];
      delta64 = cur_total - prev_total;
    end
  endfunction

  function automatic logic [95:0] next96(input logic [95:0] prev,
                                          input longint signed inc,
                                          output logic wrapbit);
    longint signed total;
    logic [47:0] sec;
    logic [29:0] ns;
    logic [15:0] f;
    begin
      total = prev[45:16];
      total = total * 64'sd65536 + prev[15:0];
      total = total + inc;
      sec = prev[95:48];
      wrapbit = 1'b0;
      if (total >= SUBSEC) begin
        total = total - SUBSEC;
        sec = sec + 48'd1;
        wrapbit = 1'b1;
      end
      ns = total / 64'sd65536;
      f = total % 64'sd65536;
      next96 = {sec, 2'b00, ns, f};
    end
  endfunction

  // Return only after the history monitor has completed its last negedge sample.
  task automatic wait_and_sample(input int cycles);
    begin
      repeat (cycles) @(posedge clk);
      @(negedge clk);
      @(posedge clk);
    end
  endtask

  task automatic check_delta(input int base, input int c,
                             input longint signed want,
                             input string clause);
    int i;
    int p;
    longint signed got;
    begin
      i = idx_at(c);
      p = idx_at(c-1);
      if ((i == 0) || (p == 0)) begin
        note_error("TB bookkeeping",
                   $sformatf("missing samples for base %0d cycle %0d", base, c));
      end else begin
        if (base == 96)
          got = delta96(h96[p], h96[i]);
        else
          got = delta64(h64[p], h64[i]);
        if (got !== want)
          note_error(clause,
                     $sformatf("base %0d cycle %0d: increment %0d, required %0d",
                               base, c, got, want));
      end
    end
  endtask

  task automatic check_plain(input int base, input int first_c, input int last_c,
                             input longint signed per, input string clause);
    int c;
    begin
      for (c = first_c; c <= last_c; c = c + 1)
        check_delta(base, c, per, clause);
    end
  endtask

  // Check a periodic drift pattern independently on one base. The phase at the
  // beginning of the window is deliberately unconstrained.
  task automatic check_pattern(input int base, input int first_c, input int last_c,
                               input longint signed per,
                               input longint signed drp,
                               input int rate,
                               input string clause);
    int c;
    int i;
    int p;
    int first_drift;
    int prev_drift;
    int last_drift;
    int drift_count;
    longint signed got;
    begin
      first_drift = 0;
      prev_drift = 0;
      last_drift = 0;
      drift_count = 0;

      for (c = first_c; c <= last_c; c = c + 1) begin
        i = idx_at(c);
        p = idx_at(c-1);
        if ((i == 0) || (p == 0)) begin
          note_error("TB bookkeeping",
                     $sformatf("missing pattern sample base %0d cycle %0d", base, c));
        end else begin
          if (base == 96)
            got = delta96(h96[p], h96[i]);
          else
            got = delta64(h64[p], h64[i]);

          if (got === (per + drp)) begin
            drift_count = drift_count + 1;
            if (first_drift == 0)
              first_drift = c;
            if ((prev_drift != 0) && ((c - prev_drift) != rate))
              note_error("D2",
                         $sformatf("base %0d: drift spacing %0d at cycle %0d, required %0d",
                                   base, c-prev_drift, c, rate));
            prev_drift = c;
            last_drift = c;
          end else if (got !== per) begin
            note_error(clause,
                       $sformatf("base %0d cycle %0d: increment %0d, legal values %0d or %0d",
                                 base, c, got, per, per+drp));
          end
        end
      end

      if (drift_count < 2)
        note_error("D2",
                   $sformatf("base %0d: only %0d drift increments in cycles %0d..%0d",
                             base, drift_count, first_c, last_c));
      if ((first_drift != 0) && ((first_drift - first_c) >= rate))
        note_error("D2",
                   $sformatf("base %0d: missing drift at start of measurement window", base));
      if ((last_drift != 0) && ((last_c - last_drift) >= rate))
        note_error("D2",
                   $sformatf("base %0d: missing drift at end of measurement window", base));
    end
  endtask

  // A transition whose old and new increment streams each have one value.
  task automatic check_clean_transition(input int base, input int a,
                                        input longint signed oldinc,
                                        input longint signed newinc,
                                        input string clause);
    int c;
    int i;
    int p;
    int first_new;
    longint signed got;
    begin
      first_new = 0;
      for (c = a; c <= a+8; c = c + 1) begin
        i = idx_at(c);
        p = idx_at(c-1);
        if ((i == 0) || (p == 0)) begin
          note_error("TB bookkeeping", "missing transition samples");
        end else begin
          if (base == 96)
            got = delta96(h96[p], h96[i]);
          else
            got = delta64(h64[p], h64[i]);

          if (first_new == 0) begin
            if (got === newinc)
              first_new = c;
            else if (got !== oldinc)
              note_error(clause,
                         $sformatf("base %0d cycle %0d: illegal transition increment %0d",
                                   base, c, got));
          end
        end
      end

      if (first_new == 0) begin
        note_error("L1",
                   $sformatf("base %0d: control not reflected within 8 cycles after %0d",
                             base, a));
      end else begin
        for (c = first_new; c <= a+12; c = c + 1)
          check_delta(base, c, newinc, clause);
      end
    end
  endtask

  task automatic check_default_to_rate1(input int base, input int a);
    int c;
    int i;
    int p;
    int first_new;
    longint signed got;
    begin
      first_new = 0;
      for (c = a; c <= a+8; c = c + 1) begin
        i = idx_at(c);
        p = idx_at(c-1);
        if (base == 96)
          got = delta96(h96[p], h96[i]);
        else
          got = delta64(h64[p], h64[i]);

        if (first_new == 0) begin
          if (got === (P0 + 16))
            first_new = c;
          else if ((got !== P0) && (got !== (P0 + 2)))
            note_error("I1/D1",
                       $sformatf("base %0d cycle %0d: illegal drift transition increment %0d",
                                 base, c, got));
        end
      end
      if (first_new == 0)
        note_error("D1/D2/L1",
                   $sformatf("base %0d: rate-one drift not adopted within 8 cycles", base));
      else
        for (c = first_new; c <= a+12; c = c + 1)
          check_delta(base, c, P0+16, "D1/D2");
    end
  endtask

  task automatic check_to_negative_drift(input int base, input int a);
    int c;
    int i;
    int p;
    int first_new;
    longint signed got;
    begin
      first_new = 0;
      for (c = a; c <= a+8; c = c + 1) begin
        i = idx_at(c);
        p = idx_at(c-1);
        if (base == 96)
          got = delta96(h96[p], h96[i]);
        else
          got = delta64(h64[p], h64[i]);

        if (first_new == 0) begin
          if (got === (P0 + 16)) begin
            // Old rate-one stream.
          end else if ((got === P0) || (got === (P0 - 2))) begin
            first_new = c;
          end else begin
            note_error("I1/D1/D3",
                       $sformatf("base %0d cycle %0d: illegal signed-drift transition %0d",
                                 base, c, got));
          end
        end
      end

      if (first_new == 0)
        note_error("D1/L1",
                   $sformatf("base %0d: new drift not adopted within 8 cycles", base));
      else begin
        for (c = first_new; c <= a+10; c = c + 1) begin
          i = idx_at(c);
          p = idx_at(c-1);
          if (base == 96)
            got = delta96(h96[p], h96[i]);
          else
            got = delta64(h64[p], h64[i]);
          if ((got !== P0) && (got !== (P0 - 2)))
            note_error("D3",
                       $sformatf("base %0d cycle %0d: increment %0d is not period or period-2",
                                 base, c, got));
        end
      end
    end
  endtask

  task automatic check_adjust(input int base, input int a,
                              input longint signed per,
                              input longint signed adj,
                              input int count);
    int c;
    int i;
    int p;
    int first_adj;
    longint signed got;
    begin
      first_adj = 0;
      for (c = a; c <= a+8; c = c + 1) begin
        i = idx_at(c);
        p = idx_at(c-1);
        if (base == 96)
          got = delta96(h96[p], h96[i]);
        else
          got = delta64(h64[p], h64[i]);

        if (first_adj == 0) begin
          if (got === (per + adj))
            first_adj = c;
          else if (got !== per)
            note_error("A2/I1",
                       $sformatf("base %0d cycle %0d: illegal pre-adjustment increment %0d",
                                 base, c, got));
        end
      end

      if (first_adj == 0) begin
        note_error("A1/A2/L1",
                   $sformatf("base %0d: adjustment did not begin within 8 cycles", base));
      end else begin
        for (c = first_adj; c < first_adj+count; c = c + 1)
          check_delta(base, c, per+adj, "A2/A5");
        for (c = first_adj+count; c <= a+8+count+3; c = c + 1)
          check_delta(base, c, per, "A2 (too many adjusted increments)");
      end
    end
  endtask

  task automatic check_active_pulse(input int a, input int count);
    int c;
    int i;
    int n;
    int first_high;
    int last_high;
    begin
      n = 0;
      first_high = 0;
      last_high = 0;
      for (c = a-2; c <= a+8+count+12; c = c + 1) begin
        i = idx_at(c);
        if (i != 0) begin
          if (hactive[i] === 1'b1) begin
            n = n + 1;
            if (first_high == 0)
              first_high = c;
            last_high = c;
          end else if (hactive[i] !== 1'b0) begin
            note_error("A3", $sformatf("unknown adj_active at cycle %0d", c));
          end
        end
      end

      if (n != count)
        note_error("A3",
                   $sformatf("adjustment at %0d: adj_active high on %0d cycles, required %0d",
                             a, n, count));
      if ((n > 0) && ((last_high-first_high+1) != n))
        note_error("A3",
                   $sformatf("adjustment at %0d: adj_active cycles are not consecutive", a));
      if ((first_high != 0) && (first_high < a))
        note_error("A3", "adj_active was asserted before its adjustment was accepted");
    end
  endtask

  task automatic check_no_active(input int first_c, input int last_c);
    int c;
    int i;
    begin
      for (c = first_c; c <= last_c; c = c + 1) begin
        i = idx_at(c);
        if ((i != 0) && (hactive[i] !== 1'b0))
          note_error("A3/R2", $sformatf("unexpected adj_active at cycle %0d", c));
      end
    end
  endtask

  task automatic check_active_total(input int first_c, input int last_c, input int want);
    int c;
    int i;
    int n;
    begin
      n = 0;
      for (c = first_c; c <= last_c; c = c + 1) begin
        i = idx_at(c);
        if ((i != 0) && (hactive[i] === 1'b1))
          n = n + 1;
      end
      if (n != want)
        note_error("A3",
                   $sformatf("total adj_active cycles %0d, required %0d", n, want));
    end
  endtask

  task automatic check_no_pps(input int first_c, input int last_c);
    int c;
    int i;
    begin
      for (c = first_c; c <= last_c; c = c + 1) begin
        i = idx_at(c);
        if ((i != 0) && (hpps[i] !== 1'b0))
          note_error("W3", $sformatf("spurious pps at cycle %0d", c));
      end
    end
  endtask

  task automatic check_reset_zero;
    begin
      if (ts96 !== 96'd0)
        note_error("R2", $sformatf("ts96 not zero after reset: %024h", ts96));
      if (ts64 !== 64'd0)
        note_error("R2", $sformatf("ts64 not zero after reset: %016h", ts64));
      if (adj_active !== 1'b0)
        note_error("R2", "offset adjustment was not cancelled by reset");
    end
  endtask

  task automatic verify_set96(input int a, input logic [47:0] sec,
                              input logic [29:0] ns, input logic [15:0] f,
                              input longint signed per);
    int i;
    logic [95:0] want;
    begin
      want = {sec, 2'b00, ns, f};
      i = idx_at(a);
      if ((i == 0) || (h96[i] !== want))
        note_error("S1", "ts96 did not visibly take the set value on its acceptance cycle");

      // The other base receives no set warm-up allowance.
      check_plain(64, a, a+8, per, "S4 (setting ts96 disturbed ts64)");
      // Cycles a+1 through a+4 are excluded on the base that was set.
      check_plain(96, a+5, a+10, per, "I1/X2c after set_ts96");
    end
  endtask

  task automatic verify_set64(input int a, input logic [47:0] ns,
                              input logic [15:0] f, input longint signed per);
    int i;
    logic [63:0] want;
    begin
      want = {ns, f};
      i = idx_at(a);
      if ((i == 0) || (h64[i] !== want))
        note_error("S2", "ts64 did not visibly take the set value on its acceptance cycle");

      check_plain(96, a, a+8, per, "S4 (setting ts64 disturbed ts96)");
      check_plain(64, a+5, a+10, per, "I1/X2c after set_ts64");
    end
  endtask

  task automatic verify_wrap(input int reset_base, input int a96, input int a64,
                             input int last_c);
    int c;
    int i;
    int p;
    int wraps;
    longint signed sec_d;
    logic wrapbit;
    logic [95:0] exp96;
    logic [63:0] exp64;
    logic [95:0] set96_want;
    logic [63:0] set64_want;
    begin
      set96_want = {48'd7, 2'b00, 30'd999999950, 16'h1234};
      set64_want = {48'd999999900, 16'h5678};

      i = idx_at(a96);
      if ((i == 0) || (h96[i] !== set96_want))
        note_error("S1", "wrap test: ts96 set value mismatch");
      i = idx_at(a64);
      if ((i == 0) || (h64[i] !== set64_want))
        note_error("S2", "wrap test: ts64 set value mismatch");

      // No wrap is possible before the near-boundary set.
      check_no_pps(reset_base+1, a96);

      wraps = 0;
      for (c = a96+1; c <= last_c; c = c + 1) begin
        i = idx_at(c);
        p = idx_at(c-1);
        wrapbit = 1'b0;

        if (c >= a96+5) begin
          exp96 = next96(h96[p], PWRAP, wrapbit);
          if (h96[i] !== exp96)
            note_error("W1/I1",
                       $sformatf("cycle %0d: ts96 %024h, exact wrapped value %024h",
                                 c, h96[i], exp96));
        end else begin
          // The four post-set increments are unconstrained, but a seconds
          // change still has to correspond to a one-second wrap and pps.
          sec_d = h96[i][95:48];
          sec_d = sec_d - h96[p][95:48];
          if (sec_d == 0)
            wrapbit = 1'b0;
          else if (sec_d == 1)
            wrapbit = 1'b1;
          else
            note_error("W1",
                       $sformatf("cycle %0d: seconds changed by %0d during set warm-up",
                                 c, sec_d));
        end

        if (hpps[i] !== wrapbit)
          note_error("W3",
                     $sformatf("cycle %0d: pps=%b, wrap=%b", c, hpps[i], wrapbit));
        if (wrapbit)
          wraps = wraps + 1;
      end

      if (wraps != 1)
        note_error("W1/W3",
                   $sformatf("observed %0d one-second wraps, required exactly one", wraps));

      // The 64-bit accumulator must continue through 1e9 ns without wrapping.
      for (c = a64+5; c <= last_c; c = c + 1) begin
        i = idx_at(c);
        p = idx_at(c-1);
        exp64 = h64[p] + PWRAP;
        if (h64[i] !== exp64)
          note_error("W2/I1",
                     $sformatf("cycle %0d: ts64 %016h, required %016h",
                               c, h64[i], exp64));
      end

      i = idx_at(last_c);
      if ((i == 0) || (h64[i][63:16] <= 48'd1000000000))
        note_error("W2", "ts64 did not continue beyond one second");
    end
  endtask

  // Change payloads after acceptance. A design that failed to latch them will
  // be exposed by the subsequent exact-increment checks.
  task automatic scramble_period_payload;
    begin
      @(negedge clk);
      period_ns = 4'd0;
      period_fns = 16'd0;
    end
  endtask

  task automatic scramble_drift_payload;
    begin
      @(negedge clk);
      drift_ns = 4'hf;
      drift_fns = 16'hff00;
      drift_rate = 16'd9;
    end
  endtask

  task automatic scramble_adj_payload;
    begin
      @(negedge clk);
      adj_ns = 4'd0;
      adj_fns = 16'd1;
      adj_count = 16'd1;
    end
  endtask

  task automatic run_tests;
    int base0;
    int base1;
    int a0;
    int a1;
    int a96;
    int a64;
    int last_c;
    begin
      // -----------------------------------------------------------------------
      // R2, I2 and default D1/D2/D3. Measurement starts at cycle 9, per X2b.
      // -----------------------------------------------------------------------
      bfm_reset(5);
      base0 = abs_cycle;
      check_reset_zero();
      wait_and_sample(40);

      check_pattern(96, base0+9, base0+40, P0, 2, 5,
                    "I1/I2/D2/D3 (reset defaults)");
      check_pattern(64, base0+9, base0+40, P0, 2, 5,
                    "I1/I2/D2/D3 (reset defaults)");

      // Drift rate one makes every increment show the newly latched drift.
      bfm_drift(4'h0, 16'h0010, 16'd1);
      a0 = drift_accept;
      scramble_drift_payload();
      wait_and_sample(16);
      check_default_to_rate1(96, a0);
      check_default_to_rate1(64, a0);

      // A negative signed drift and a non-default spacing.
      bfm_drift(4'hf, 16'hfffe, 16'd7);
      a0 = drift_accept;
      wait_and_sample(55);
      check_to_negative_drift(96, a0);
      check_to_negative_drift(64, a0);
      check_pattern(96, a0+12, a0+50, P0, -2, 7, "D2/D3");
      check_pattern(64, a0+12, a0+50, P0, -2, 7, "D2/D3");

      // Remove drift so period and offset counts can be observed unambiguously.
      bfm_drift(4'h0, 16'h0000, 16'd5);
      a0 = drift_accept;
      wait_and_sample(30);
      check_plain(96, a0+10, a0+25, P0, "D1/D2 (zero drift)");
      check_plain(64, a0+10, a0+25, P0, "D1/D2 (zero drift)");

      // Exact period replacement, with independent per-base adoption latency.
      bfm_period(4'd8, 16'h1234);
      a0 = period_accept;
      scramble_period_payload();
      wait_and_sample(16);
      check_clean_transition(96, a0, P0, P1, "I2/L1");
      check_clean_transition(64, a0, P0, P1, "I2/L1");
      check_plain(96, a0+9, a0+15, P1, "I2");
      check_plain(64, a0+9, a0+15, P1, "I2");

      // Positive counted adjustment: five, no more and no fewer.
      bfm_adjust(4'h0, 16'h0321, 16'd5);
      a0 = adj_accept;
      scramble_adj_payload();
      wait_and_sample(30);
      check_adjust(96, a0, P1, 20'h00321, 5);
      check_adjust(64, a0, P1, 20'h00321, 5);
      check_active_pulse(a0, 5);

      // Zero is also an exact count.
      bfm_adjust(4'h0, 16'h0123, 16'd0);
      a0 = adj_accept;
      wait_and_sample(18);
      check_plain(96, a0, a0+12, P1, "A2 (zero count)");
      check_plain(64, a0, a0+12, P1, "A2 (zero count)");
      check_no_active(a0-1, a0+15);

      // Signed negative counted adjustment.
      bfm_adjust(4'hf, 16'hfffe, 16'd7);
      a0 = adj_accept;
      wait_and_sample(32);
      check_adjust(96, a0, P1, -2, 7);
      check_adjust(64, a0, P1, -2, 7);
      check_active_pulse(a0, 7);

      // With drift on every increment, this also checks the full sum
      // period + drift + offset rather than merely each term separately.
      bfm_drift(4'h0, 16'h0010, 16'd1);
      a0 = drift_accept;
      wait_and_sample(16);
      check_clean_transition(96, a0, P1, P1+16, "D1/D2/L1");
      check_clean_transition(64, a0, P1, P1+16, "D1/D2/L1");

      bfm_adjust(4'h0, 16'h0003, 16'd4);
      a0 = adj_accept;
      wait_and_sample(28);
      check_adjust(96, a0, P1+16, 3, 4);
      check_adjust(64, a0, P1+16, 3, 4);
      check_active_pulse(a0, 4);

      bfm_drift(4'h0, 16'h0000, 16'd5);
      a0 = drift_accept;
      wait_and_sample(30);
      check_plain(96, a0+10, a0+25, P1, "D1/D2");
      check_plain(64, a0+10, a0+25, P1, "D1/D2");

      // Sets are immediate discontinuities. Only the set base receives the
      // four-cycle increment allowance, and the other base must continue.
      bfm_set96(48'd3, 30'd123456789, 16'habcd);
      a0 = set96_accept;
      wait_and_sample(14);
      verify_set96(a0, 48'd3, 30'd123456789, 16'habcd, P1);

      bfm_set64(48'd987654321, 16'h1234);
      a1 = set64_accept;
      wait_and_sample(14);
      verify_set64(a1, 48'd987654321, 16'h1234, P1);

      check_active_total(base0+1, habs[samp], 16);
      check_no_pps(base0+1, habs[samp]);

      // -----------------------------------------------------------------------
      // Reset with an adjustment still owed. The second reset also verifies
      // that the eight-cycle warm-up exclusion is not being used just once.
      // -----------------------------------------------------------------------
      bfm_adjust(4'h0, 16'h1000, 16'd100);
      wait_and_sample(4);
      bfm_reset(5);
      base1 = abs_cycle;
      check_reset_zero();
      wait_and_sample(45);

      check_pattern(96, base1+9, base1+45, P0, 2, 5,
                    "R2/I2/D2 (defaults after second reset)");
      check_pattern(64, base1+9, base1+45, P0, 2, 5,
                    "R2/I2/D2 (defaults after second reset)");
      check_no_active(base1+1, base1+45);
      check_no_pps(base1+1, base1+45);

      // -----------------------------------------------------------------------
      // Reach the one-second boundary through S1/S2. The period includes one
      // fractional fns so the wrap comparison is exact below one nanosecond.
      // -----------------------------------------------------------------------
      bfm_drift(4'h0, 16'h0000, 16'd5);
      a0 = drift_accept;
      wait_and_sample(30);
      check_plain(96, a0+10, a0+25, P0, "D1/D2 before wrap test");
      check_plain(64, a0+10, a0+25, P0, "D1/D2 before wrap test");

      bfm_period(4'd1, 16'h0001);
      a0 = period_accept;
      wait_and_sample(16);
      check_clean_transition(96, a0, P0, PWRAP, "I2/L1");
      check_clean_transition(64, a0, P0, PWRAP, "I2/L1");

      bfm_set96(48'd7, 30'd999999950, 16'h1234);
      a96 = set96_accept;
      bfm_set64(48'd999999900, 16'h5678);
      a64 = set64_accept;
      wait_and_sample(180);
      last_c = a64 + 180;

      verify_wrap(base1, a96, a64, last_c);
      check_no_active(base1+1, last_c);

      if (errors == 0)
        $display("RESULT: PASS");
      else
        $display("RESULT: FAIL");
      $finish;
    end
  endtask

  initial begin
    run_tests();
  end

endmodule
