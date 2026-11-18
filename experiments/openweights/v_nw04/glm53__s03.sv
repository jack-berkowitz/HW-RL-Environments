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
// CHECKER
// ---------------------------------------------------------------------------
  // pinned values (fns units; 1 ns = 65536 fns)
  localparam logic signed [127:0] P0 = 128'sd419430;   // 6 ns + 0x6666 fns
  localparam logic signed [127:0] P2 = 128'sd229376;   // 3 ns + 0x8000 fns
  localparam logic signed [127:0] D0 = 128'sd2;        // default drift

  logic [127:0]        m_f96  [0:199999];
  logic [63:0]         m_f64  [0:199999];
  logic signed [127:0] m_d96  [0:199999];
  logic signed [63:0]  m_d64  [0:199999];
  logic m_wr  [0:199999];
  logic m_aa  [0:199999];
  logic m_st  [0:199999];
  logic m_pp  [0:199999];
  logic m_fmt [0:199999];
  logic m_nsok[0:199999];

  logic [127:0] f96_prev;
  logic [63:0]  f64_prev;
  logic [47:0]  sec_prev;

  int fail = 0;

  function automatic logic [127:0] full96val(input logic [47:0] s,
                                             input logic [29:0] n,
                                             input logic [15:0] f);
    logic [127:0] r;
    r = {80'd0, s} * 128'd65536000000 + {98'd0, n} * 128'd65536 + {112'd0, f};
    return r;
  endfunction

  // sample outputs on the negedge (stable, off the sampling edge);
  // record k holds the increment applied at rising edge k
  always @(negedge clk) begin
    automatic logic [47:0]  c_sec;
    automatic logic [29:0]  c_ns;
    automatic logic [15:0]  c_fns;
    automatic logic [127:0] c_f96;
    automatic logic [63:0]  c_f64;
    automatic logic w;
    c_sec = ts96[95:48];
    c_ns  = ts96[45:16];
    c_fns = ts96[15:0];
    c_f96 = {80'd0, c_sec} * 128'd65536000000
          + {98'd0, c_ns}  * 128'd65536
          + {112'd0, c_fns};
    c_f64 = ts64[63:16] * 64'd65536 + {48'd0, ts64[15:0]};
    w = (c_sec == sec_prev + 48'd1);          // W1 wrap: seconds carried
    m_f96[bfm_cycle] = c_f96;
    m_f64[bfm_cycle] = c_f64;
    m_wr [bfm_cycle] = w;
    m_aa [bfm_cycle] = adj_active;
    m_st [bfm_cycle] = ts_step;
    m_pp [bfm_cycle] = pps;
    m_fmt[bfm_cycle] = (ts96[47:46] == 2'b00);
    m_nsok[bfm_cycle]= (c_ns < 30'd1000000000);
    m_d96[bfm_cycle] = $signed(c_f96 - f96_prev) + (w ? 128'sd65536000000 : 128'sd0);
    m_d64[bfm_cycle] = $signed(c_f64 - f64_prev);
    f96_prev = c_f96;
    f64_prev = c_f64;
    sec_prev = c_sec;
  end

  task automatic xfail(input string cl, input int c);
    fail = fail + 1;
    if (fail <= 20) $display("Violation %0d (cycle %0d): %s", fail, c, cl);
  endtask

  task automatic mwait(input int target);
    while (bfm_cycle < target) @(negedge clk);
  endtask

  function automatic logic signed [127:0] getd(input int b, input int c);
    logic signed [127:0] r;
    if (b == 96) r = m_d96[c];
    else         r = {{64{m_d64[c][63]}}, m_d64[c]};
    return r;
  endfunction

  // deltas must be P or P+D; drift records exactly every 'rate', count exact
  task automatic chk_pat(input int b, input int a, input int e,
                         input logic signed [127:0] P,
                         input logic signed [127:0] D,
                         input int rate, input string cl);
    automatic int c, last, cnt, n;
    begin
      n = e - a + 1; last = -1; cnt = 0;
      for (c = a; c <= e; c++) begin
        if (getd(b, c) == P + D) begin
          cnt = cnt + 1;
          if (last >= 0 && (c - last) != rate) xfail(cl, c);
          last = c;
        end else if (getd(b, c) != P) xfail(cl, c);
      end
      if (cnt != n / rate) xfail(cl, e);
    end
  endtask

  task automatic chk_flat(input int b, input int a, input int e,
                          input logic signed [127:0] P, input string cl);
    automatic int c;
    begin
      for (c = a; c <= e; c++) if (getd(b, c) != P) xfail(cl, c);
    end
  endtask

  task automatic chk_mix(input int b, input int a, input int e,
                         input logic signed [127:0] v0, input logic signed [127:0] v1,
                         input logic signed [127:0] v2, input logic signed [127:0] v3,
                         input string cl);
    automatic int c;
    begin
      for (c = a; c <= e; c++)
        if (getd(b,c) != v0 && getd(b,c) != v1 &&
            getd(b,c) != v2 && getd(b,c) != v3) xfail(cl, c);
    end
  endtask

  task automatic chk_out(input int a, input int e, input logic ea, input logic es,
                         input logic ep, input string cl);
    automatic int c;
    begin
      for (c = a; c <= e; c++) begin
        if (m_aa[c] !== ea) xfail(cl, c);
        if (m_st[c] !== es) xfail(cl, c);
        if (m_pp[c] !== ep) xfail(cl, c);
      end
    end
  endtask

  task automatic chk_aapp0(input int a, input int e);
    automatic int c;
    begin
      for (c = a; c <= e; c++) begin
        if (m_aa[c] !== 1'b0) xfail("A3: unexpected adj_active", c);
        if (m_pp[c] !== 1'b0) xfail("W3: unexpected pps", c);
      end
    end
  endtask

  // exactly cnt consecutive increments of P+A, starting within 8 cycles of V
  task automatic chk_adj(input int b, input int V, input int cnt,
                         input logic signed [127:0] P,
                         input logic signed [127:0] A, input string cl);
    automatic int c, s;
    begin
      s = -1;
      for (c = V; c <= V+8 && s < 0; c++)
        if (getd(b, c) == P + A) s = c;
      if (s < 0) xfail(cl, V);
      else begin
        for (c = V; c < s; c++)        if (getd(b, c) != P)     xfail(cl, c);
        for (c = s; c < s+cnt; c++)    if (getd(b, c) != P + A) xfail(cl, c);
        if (getd(b, s+cnt) != P) xfail(cl, s+cnt);
      end
    end
  endtask

  // adj_active: exactly cnt consecutive cycles; ts_step mirrors it (A4)
  task automatic chk_adj_run(input int V, input int cnt);
    automatic int c, lastc, n;
    begin
      lastc = -100; n = 0;
      for (c = V; c <= V+30; c++) begin
        if (m_aa[c] === 1'b1) begin
          if (n > 0 && c != lastc + 1) xfail("A3: adj_active not consecutive", c);
          lastc = c; n = n + 1;
        end
        if (m_st[c] !== m_aa[c]) xfail("A4: ts_step must equal adj_active", c);
        if (m_pp[c] !== 1'b0)   xfail("W3: pps during adjustment", c);
      end
      if (n != cnt) xfail("A3: adj_active cycle count", V);
    end
  endtask

  task automatic chk_set96(input int V, input logic [47:0] s,
                           input logic [29:0] n, input logic [15:0] f);
    automatic logic [127:0] want;
    automatic int c, nstep;
    begin
      want = full96val(s, n, f);
      if (m_f96[V] !== want && m_f96[V+1] !== want)
        xfail("S1: set_ts96 did not take effect", V);
      nstep = 0;
      for (c = V-2; c <= V+10; c++) begin
        if (m_st[c] === 1'b1) nstep = nstep + 1;
        if (m_pp[c] !== 1'b0) xfail("W3: pps on set96", c);
        if (m_aa[c] !== 1'b0) xfail("A3: adj_active during set96", c);
      end
      if (nstep != 1) xfail("S3: ts_step pulse count at set96", V);
    end
  endtask

  task automatic chk_set64(input int V, input logic [47:0] n, input logic [15:0] f);
    automatic logic [63:0] want;
    automatic int c, nstep;
    begin
      want = n * 64'd65536 + {48'd0, f};
      if (m_f64[V] !== want && m_f64[V+1] !== want)
        xfail("S2: set_ts64 did not take effect", V);
      nstep = 0;
      for (c = V-2; c <= V+10; c++) begin
        if (m_st[c] === 1'b1) nstep = nstep + 1;
        if (m_pp[c] !== 1'b0) xfail("W3: pps on set64", c);
        if (m_aa[c] !== 1'b0) xfail("A3: adj_active during set64", c);
      end
      if (nstep != 1) xfail("S3: ts_step pulse count at set64", V);
    end
  endtask

  // exactly one W1 wrap in [a..e], pps on it alone, no step/adj
  task automatic chk_wrap(input int a, input int e);
    automatic int c, nwr, wc;
    begin
      nwr = 0; wc = -1;
      for (c = a; c <= e; c++) begin
        if (m_wr[c] === 1'b1) begin nwr = nwr + 1; wc = c; end
        if (m_pp[c] !== m_wr[c]) xfail("W3: pps must fire exactly on the wrap", c);
        if (m_st[c] !== 1'b0)    xfail("A4: ts_step at wrap", c);
        if (m_aa[c] !== 1'b0)    xfail("A3: adj_active at wrap", c);
      end
      if (nwr != 1) xfail("W1: expected exactly one one-second wrap", e);
      else begin
        if (m_f96[wc] < 128'd65536000000 * 128'd6 ||
            m_f96[wc] >= 128'd65536000000 * 128'd7)
          xfail("W1: seconds field did not advance by one at wrap", wc);
      end
    end
  endtask

// ---------------------------------------------------------------------------
// TEST SEQUENCE
// ---------------------------------------------------------------------------
  initial begin : main
    automatic int V;
    automatic int base;
    automatic int c;

    // T1: reset leaves zero; default period 6.4ns + drift 2fns every 5
    bfm_reset();
    mwait(12);
    if (m_f96[0] !== 128'd0) xfail("R2: ts96 not zero at reset release", 0);
    if (m_f64[0] !== 64'd0)   xfail("R2: ts64 not zero at reset release", 0);
    mwait(110);
    chk_pat(96, 10, 109, P0, D0, 5, "I2/D2: default period+drift, ts96");
    chk_pat(64, 10, 109, P0, D0, 5, "I2/D2: default period+drift, ts64");
    chk_out(10, 109, 1'b0, 1'b0, 1'b0, "A3/A4/W3: stray output during free run");

    // T2: period change to 3.5 ns (L1 latency window, then exact)
    bfm_period(4'h3, 16'h8000);
    V = bfm_cycle;
    mwait(V + 9);
    chk_mix(96, V+1, V+8, P0, P0+D0, P2, P2+D0, "I2: period change transition ts96");
    chk_mix(64, V+1, V+8, P0, P0+D0, P2, P2+D0, "I2: period change transition ts64");
    chk_mix(96, V+8, V+8, P2, P2+D0, P2, P2, "L1: period change must land within 8 cycles ts96");
    chk_mix(64, V+8, V+8, P2, P2+D0, P2, P2, "L1: period change must land within 8 cycles ts64");
    mwait(V + 109);
    chk_pat(96, V+9, V+108, P2, D0, 5, "I2/D2: new period, drift cadence ts96");
    chk_pat(64, V+9, V+108, P2, D0, 5, "I2/D2: new period, drift cadence ts64");
    chk_out(V+9, V+108, 1'b0, 1'b0, 1'b0, "A3/A4/W3: stray output after period change");

    // T3: drift change to +256 fns every 7
    bfm_drift(4'h0, 16'h0100, 16'd7);
    V = bfm_cycle;
    mwait(V + 9);
    chk_mix(96, V+1, V+8, P2, P2+D0, P2+128'sd256, P2, "D1: drift change transition ts96");
    chk_mix(64, V+1, V+8, P2, P2+D0, P2+128'sd256, P2, "D1: drift change transition ts64");
    chk_mix(96, V+8, V+8, P2, P2+128'sd256, P2, P2, "L1: drift change must land within 8 cycles ts96");
    chk_mix(64, V+8, V+8, P2, P2+128'sd256, P2, P2, "L1: drift change must land within 8 cycles ts64");
    mwait(V + 114);
    chk_pat(96, V+9, V+113, P2, 128'sd256, 7, "D2: drift 256fns every 7, ts96");
    chk_pat(64, V+9, V+113, P2, 128'sd256, 7, "D2: drift 256fns every 7, ts64");
    chk_out(V+9, V+113, 1'b0, 1'b0, 1'b0, "A3/A4/W3: stray output after drift change");

    // T3b: signed (negative) drift: 20'hFFF00 = -512 fns, every 6
    bfm_drift(4'hF, 16'hFF00, 16'd6);
    V = bfm_cycle;
    mwait(V + 9);
    chk_mix(96, V+1, V+8, P2, P2+128'sd256, P2-128'sd512, P2, "D3: neg drift transition ts96");
    chk_mix(64, V+1, V+8, P2, P2+128'sd256, P2-128'sd512, P2, "D3: neg drift transition ts64");
    chk_mix(96, V+8, V+8, P2, P2-128'sd512, P2, P2, "L1: neg drift must land within 8 cycles ts96");
    chk_mix(64, V+8, V+8, P2, P2-128'sd512, P2, P2, "L1: neg drift must land within 8 cycles ts64");
    mwait(V + 129);
    chk_pat(96, V+9, V+128, P2, -128'sd512, 6, "D3: drift -512fns every 6, ts96");
    chk_pat(64, V+9, V+128, P2, -128'sd512, 6, "D3: drift -512fns every 6, ts64");
    chk_out(V+9, V+128, 1'b0, 1'b0, 1'b0, "A3/A4/W3: stray output after neg drift");

    // T4: zero drift -> uniform increments
    bfm_drift(4'h0, 16'h0000, 16'd7);
    V = bfm_cycle;
    mwait(V + 49);
    chk_flat(96, V+9, V+48, P2, "D1: zero drift ts96");
    chk_flat(64, V+9, V+48, P2, "D1: zero drift ts64");
    chk_out(V+9, V+48, 1'b0, 1'b0, 1'b0, "A3/A4/W3: stray output after zero drift");

    // T5: counted offset +1 ns, exactly 10 consecutive increments
    bfm_adjust(4'h1, 16'h0000, 16'd10);
    V = bfm_cycle;
    mwait(V + 31);
    chk_adj(96, V, 10, P2, 128'sd65536, "A2: adj +1ns x10 ts96");
    chk_adj(64, V, 10, P2, 128'sd65536, "A2: adj +1ns x10 ts64");
    chk_adj_run(V, 10);

    // T5b: fns-resolution adj +1 fns, exactly 3
    bfm_adjust(4'h0, 16'h0001, 16'd3);
    V = bfm_cycle;
    mwait(V + 31);
    chk_adj(96, V, 3, P2, 128'sd1, "A5/I1: adj +1fns x3 ts96");
    chk_adj(64, V, 3, P2, 128'sd1, "A5/I1: adj +1fns x3 ts64");
    chk_adj_run(V, 3);

    // T6: signed negative adj -1 ns (20'hF0000), exactly 6
    bfm_adjust(4'hF, 16'h0000, 16'd6);
    V = bfm_cycle;
    mwait(V + 31);
    chk_adj(96, V, 6, P2, -128'sd65536, "A5: adj -1ns x6 ts96");
    chk_adj(64, V, 6, P2, -128'sd65536, "A5: adj -1ns x6 ts64");
    chk_adj_run(V, 6);

    // T7: set ts96; ts64 must be undisturbed (S4)
    bfm_set96(48'd100, 30'd123, 16'd456);
    V = bfm_cycle;
    mwait(V + 35);
    chk_set96(V, 48'd100, 30'd123, 16'd456);
    chk_flat(64, V+1, V+30, P2, "S4: set96 must not disturb ts64");
    chk_flat(96, V+6, V+30, P2, "I1: ts96 increments after set");
    chk_aapp0(V, V+30);

    // T8: set ts64; ts96 must be undisturbed (S4)
    bfm_set64(48'd777, 16'd99);
    V = bfm_cycle;
    mwait(V + 35);
    chk_set64(V, 48'd777, 16'd99);
    chk_flat(96, V+1, V+30, P2, "S4: set64 must not disturb ts96");
    chk_flat(64, V+6, V+30, P2, "I1: ts64 increments after set");
    chk_aapp0(V, V+30);

    // T9: one-second wrap on ts96 (reached via set, sampled past X2c window)
    bfm_set96(48'd5, 30'd999_999_900, 16'd0);
    V = bfm_cycle;
    mwait(V + 55);
    chk_set96(V, 48'd5, 30'd999_999_900, 16'd0);
    chk_flat(64, V+1, V+50, P2, "S4/W2: ts64 unaffected during wrap test");
    chk_flat(96, V+6, V+50, P2, "W1: exact 1e9 subtraction at wrap, ts96");
    chk_wrap(V+6, V+50);

    // T10: ts64 must NOT wrap at one second (W2)
    bfm_set64(48'd999_999_999, 16'd65535);
    V = bfm_cycle;
    mwait(V + 45);
    chk_set64(V, 48'd999_999_999, 16'd65535);
    chk_flat(96, V+1, V+40, P2, "S4: set64 must not disturb ts96");
    chk_flat(64, V+6, V+40, P2, "W2: ts64 must not wrap at one second");
    chk_aapp0(V, V+40);
    if (m_f64[V+40] <= 64'd65536000000000)
      xfail("W2: ts64 ns field did not pass 1e9", V+40);

    // T11: reset during a mid-flight adjustment cancels everything (R2)
    bfm_adjust(4'h2, 16'h0000, 16'd200);
    V = bfm_cycle;
    bfm_wait(15);
    bfm_reset(5);
    base = bfm_cycle;
    mwait(base + 115);
    if (m_f96[base] !== 128'd0) xfail("R2: ts96 not zero after mid-adj reset", base);
    if (m_f64[base] !== 64'd0)   xfail("R2: ts64 not zero after mid-adj reset", base);
    chk_out(base+10, base+114, 1'b0, 1'b0, 1'b0,
            "R2/A3: reset must cancel the owed adjustment");
    chk_pat(96, base+10, base+109, P0, D0, 5, "R2/I2/D2: defaults restored ts96");
    chk_pat(64, base+10, base+109, P0, D0, 5, "R2/I2/D2: defaults restored ts64");

    // global sweep: F1 reserved bits, W1 ns bound
    for (c = 1; c < bfm_cycle; c++) begin
      if (c == base) continue;               // record written during reset (X1)
      if (m_fmt[c]  !== 1'b1) xfail("F1: ts96 reserved bits not zero", c);
      if (m_nsok[c] !== 1'b1) xfail("W1: ts96 ns field reached 1e9", c);
    end

    if (fail == 0) $display("RESULT: PASS");
    else begin
      $display("RESULT: FAIL");
      $display("  (%0d violation(s) detected)", fail);
    end
    $finish;
  end

endmodule
