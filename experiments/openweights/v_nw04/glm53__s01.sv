module ptp_time_base_tb;

  // ---------------------------------------------------------------------------
  // PROVIDED PLUMBING
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
  // Every rising edge with rst low is recorded.  Sample i (cycle q_cyc[i])
  // holds the DUT outputs as they stand just before that edge, i.e. the state
  // produced by edge i-1.  The per-cycle advance is q[i]-q[i-1], which is the
  // increment applied at edge i-1.  All checks are per base (L2) and start at
  // cycle 10 (X2b) or after the set warm-up (X2c).

  logic [95:0] qraw96[$];
  logic [63:0] qraw64[$];
  logic q_aa[$];
  logic q_st[$];
  logic q_pp[$];
  logic q_v96[$];
  logic q_v64[$];
  int   q_cyc[$];
  int   mycyc;
  int   errors;

  function automatic logic [127:0] tot96(input logic [95:0] t);
    tot96 = t[95:48] * 1000000000 * 65536 + t[45:16] * 65536 + t[15:0];
  endfunction

  function automatic logic [127:0] tot64(input logic [63:0] t);
    tot64 = t[63:16] * 65536 + t[15:0];
  endfunction

  always @(posedge clk) begin
    if (rst) mycyc <= 0;
    else begin
      mycyc <= mycyc + 1;
      qraw96.push_back(ts96);
      qraw64.push_back(ts64);
      q_aa.push_back(adj_active);
      q_st.push_back(ts_step);
      q_pp.push_back(pps);
      q_v96.push_back(set_ts96_valid);
      q_v64.push_back(set_ts64_valid);
      q_cyc.push_back(mycyc + 1);
    end
  end

  task automatic fail(input string msg);
    errors = errors + 1;
    if (errors <= 20) $display("FAIL[%0d]: %s", errors, msg);
  endtask

  // true if sample i carries a checkable delta (post warm-up, same epoch)
  function automatic bit okd(input int i);
    okd = (i > 0) && (q_cyc[i] >= 10) && (q_cyc[i] == q_cyc[i-1] + 1);
  endfunction

  // Steady state: every increment is p or p+d; drift cycles spaced exactly
  // 'rate' apart on each base independently; outputs quiet.
  task automatic chk_steady(input int s0, input int s1,
                            input logic [127:0] p, input logic [127:0] d,
                            input int rate, input string tag);
    int i, l96, l64, n96, n64;
    logic [127:0] dl;
    begin
      l96 = -1; l64 = -1; n96 = 0; n64 = 0;
      for (i = s0; i <= s1; i++) begin
        if (okd(i)) begin
          if (qraw96[i][47:46] !== 2'b00) fail(tag+": F1 reserved bits nonzero");
          dl = tot96(qraw96[i]) - tot96(qraw96[i-1]);
          if (dl == p) begin
            // plain increment
          end else if (d != 0 && dl == p + d) begin
            n96 = n96 + 1;
            if (l96 >= 0 && i - l96 != rate)
              fail(tag+": D2 drift spacing wrong on base96");
            l96 = i;
          end else begin
            fail(tag+": I1 illegal increment on base96");
          end
          dl = tot64(qraw64[i]) - tot64(qraw64[i-1]);
          if (dl == p) begin
            // plain increment
          end else if (d != 0 && dl == p + d) begin
            n64 = n64 + 1;
            if (l64 >= 0 && i - l64 != rate)
              fail(tag+": D2 drift spacing wrong on base64");
            l64 = i;
          end else begin
            fail(tag+": I1 illegal increment on base64");
          end
          if (q_aa[i] !== 1'b0 || q_st[i] !== 1'b0 || q_pp[i] !== 1'b0)
            fail(tag+": A3/A4/S3/W3 unexpected adj_active/ts_step/pps");
        end
      end
      if (d != 0) begin
        if (n96 < 3) fail(tag+": D2 drift never observed on base96");
        if (n64 < 3) fail(tag+": D2 drift never observed on base64");
      end
    end
  endtask

  // Counted offset: exactly c consecutive increments of p+a on each base,
  // adj_active high exactly c consecutive cycles, ts_step == adj_active.
  task automatic chk_adj(input int s0, input int s1, input logic [127:0] p,
                          input logic [127:0] a, input int c, input string tag);
    int i, n96, n64, na, pd96, pd64, pa;
    logic [127:0] dl;
    begin
      n96 = 0; n64 = 0; na = 0; pd96 = -1; pd64 = -1; pa = -1;
      for (i = s0; i <= s1; i++) begin
        if (okd(i)) begin
          dl = tot96(qraw96[i]) - tot96(qraw96[i-1]);
          if (dl == p) begin
          end else if (dl == p + a) begin
            if (n96 > 0 && pd96 != i - 1)
              fail(tag+": A2 adjusted increments not consecutive on base96");
            n96 = n96 + 1; pd96 = i;
          end else begin
            fail(tag+": I1 illegal increment on base96 during adjustment");
          end
          dl = tot64(qraw64[i]) - tot64(qraw64[i-1]);
          if (dl == p) begin
          end else if (dl == p + a) begin
            if (n64 > 0 && pd64 != i - 1)
              fail(tag+": A2 adjusted increments not consecutive on base64");
            n64 = n64 + 1; pd64 = i;
          end else begin
            fail(tag+": I1 illegal increment on base64 during adjustment");
          end
          if (q_aa[i] === 1'b1) begin
            if (na > 0 && pa != i - 1)
              fail(tag+": A3 adj_active cycles not consecutive");
            na = na + 1; pa = i;
          end
          if (q_st[i] !== q_aa[i]) fail(tag+": A4 ts_step differs from adj_active");
          if (q_pp[i] !== 1'b0) fail(tag+": W3 pps during adjustment");
        end
      end
      if (n96 != c) fail(tag+": A2 adjusted increment count wrong on base96");
      if (n64 != c) fail(tag+": A2 adjusted increment count wrong on base64");
      if (na != c) fail(tag+": A3 adj_active cycle count wrong");
    end
  endtask

  // Set of the 96-bit base: value visible, one step pulse, other base keeps
  // advancing by exactly p (S4).
  task automatic chk_set96(input int s0, input int s1, input logic [95:0] val,
                           input logic [127:0] p, input bit chk_other,
                           input bit do_step, input string tag);
    int i, vi, k, found, nst;
    logic [127:0] dl;
    begin
      vi = -1;
      for (i = s0; i <= s1; i++) if (q_v96[i] === 1'b1) vi = i;
      if (vi < 0) fail(tag+": S1 set_ts96_valid not observed");
      else begin
        found = 0;
        for (k = vi; k <= vi + 3 && k < qraw96.size(); k++)
          if (qraw96[k] === val) found = 1;
        if (!found) fail(tag+": S1 set value not visible on ts96");
        if (do_step) begin
          nst = 0;
          for (k = vi; k <= vi + 8 && k < q_st.size(); k++) begin
            if (q_st[k] === 1'b1) nst = nst + 1;
            if (q_pp[k] !== 1'b0) fail(tag+": W3 pps near a set");
          end
          if (nst != 1) fail(tag+": S3 ts_step count on set96 not one");
        end
        if (chk_other) begin
          for (k = vi; k <= vi + 11 && k < qraw64.size(); k++) begin
            if (okd(k)) begin
              dl = tot64(qraw64[k]) - tot64(qraw64[k-1]);
              if (dl != p) fail(tag+": S4 base64 disturbed by set96");
            end
          end
        end
      end
    end
  endtask

  task automatic chk_set64(input int s0, input int s1, input logic [63:0] val,
                           input logic [127:0] p, input bit chk_other,
                           input bit do_step, input string tag);
    int i, vi, k, found, nst;
    logic [127:0] dl;
    begin
      vi = -1;
      for (i = s0; i <= s1; i++) if (q_v64[i] === 1'b1) vi = i;
      if (vi < 0) fail(tag+": S2 set_ts64_valid not observed");
      else begin
        found = 0;
        for (k = vi; k <= vi + 3 && k < qraw64.size(); k++)
          if (qraw64[k] === val) found = 1;
        if (!found) fail(tag+": S2 set value not visible on ts64");
        if (do_step) begin
          nst = 0;
          for (k = vi; k <= vi + 8 && k < q_st.size(); k++) begin
            if (q_st[k] === 1'b1) nst = nst + 1;
            if (q_pp[k] !== 1'b0) fail(tag+": W3 pps near a set");
          end
          if (nst != 1) fail(tag+": S3 ts_step count on set64 not one");
        end
        if (chk_other) begin
          for (k = vi; k <= vi + 11 && k < qraw96.size(); k++) begin
            if (okd(k)) begin
              dl = tot96(qraw96[k]) - tot96(qraw96[k-1]);
              if (dl != p) fail(tag+": S4 base96 disturbed by set64");
            end
          end
        end
      end
    end
  endtask

  // Wrap: from sample i0 (well past the set warm-up) both bases advance by
  // exactly p each cycle; base96 wraps at 1e9 ns with a one-cycle pps, base64
  // does not wrap.
  task automatic chk_wrap(input int i0, input int i1, input logic [127:0] p,
                          input string tag);
    int i;
    logic [63:0] sec, ns_, ns64, fns, f64, pns, pfns;
    logic wrap;
    begin
      pns  = p >> 16;
      pfns = p & 65535;
      sec  = qraw96[i0-1][95:48];
      ns_  = qraw96[i0-1][45:16];
      fns  = {48'b0, qraw96[i0-1][15:0]};
      ns64 = qraw64[i0-1][63:16];
      f64  = {48'b0, qraw64[i0-1][15:0]};
      for (i = i0; i <= i1; i++) begin
        fns = fns + pfns;
        ns_ = ns_ + pns + (fns >> 16);
        fns = fns & 65535;
        wrap = 1'b0;
        if (ns_ >= 1000000000) begin
          ns_ = ns_ - 1000000000;
          sec = sec + 1;
          wrap = 1'b1;
        end
        f64  = f64 + pfns;
        ns64 = ns64 + pns + (f64 >> 16);
        f64  = f64 & 65535;
        if (qraw96[i][47:46] !== 2'b00) fail(tag+": F1 reserved bits nonzero");
        if (qraw96[i][95:48] !== sec[47:0] ||
            qraw96[i][45:16] !== ns_[29:0] ||
            qraw96[i][15:0]  !== fns[15:0])
          fail(tag+": W1/F1 ts96 does not match exact wrap model");
        if (qraw64[i][63:16] !== ns64[47:0] ||
            qraw64[i][15:0]  !== f64[15:0])
          fail(tag+": W2/F2 ts64 must not wrap at one second");
        if (q_pp[i] !== wrap) fail(tag+": W3 pps not exactly on the wrap");
        if (q_aa[i] !== 1'b0 || q_st[i] !== 1'b0)
          fail(tag+": A3/S3 unexpected adj_active/ts_step");
      end
      if (ns64 < 1000000000)
        fail(tag+": W2 ts64 did not cross one second (test setup)");
    end
  endtask

  // ---------------------------------------------------------------------------
  // MAIN SEQUENCE
  // ---------------------------------------------------------------------------
  logic [127:0] P_DEF, P1, A_NEG, A_POS;
  int m0, m1, i, e2, k, nst, vi96, vi64;

  initial begin
    errors = 0;
    mycyc  = 0;
    P_DEF  = 6 * 65536 + 'h6666;   // 6 ns + 0x6666 fns
    P1     = 9 * 65536 + 1;        // 9 ns + 1 fns
    A_NEG  = -5;                    // -5 fns  (signed 20-bit 20'hFFFB)
    A_POS  = 3 * 65536;             // +3 ns

    // ---- PH1: defaults straight out of reset -----------------------------
    bfm_reset(5);
    bfm_wait(45);
    @(negedge clk); m1 = qraw96.size();
    chk_steady(0, m1 - 1, P_DEF, 128'd2, 5, "PH1");

    // ---- PH2: drift off, new period --------------------------------------
    @(negedge clk); m0 = qraw96.size();
    bfm_drift(4'h0, 16'h0000, 16'd1000);
    bfm_period(4'h9, 16'h0001);
    bfm_wait(25);
    @(negedge clk); m1 = qraw96.size();
    chk_steady(m0 + 14, m1 - 1, P1, 128'd0, 0, "PH2");

    // ---- PH3: negative counted offset ------------------------------------
    @(negedge clk); m0 = qraw96.size();
    bfm_adjust(4'h0, 16'hFFFB, 16'd7);
    bfm_wait(50);
    @(negedge clk); m1 = qraw96.size();
    chk_adj(m0, m1 - 1, P1, A_NEG, 7, "PH3");

    // ---- PH4: positive counted offset ------------------------------------
    @(negedge clk); m0 = qraw96.size();
    bfm_adjust(4'h3, 16'h0000, 16'd3);
    bfm_wait(40);
    @(negedge clk); m1 = qraw96.size();
    chk_adj(m0, m1 - 1, P1, A_POS, 3, "PH4");

    // ---- PH5: sets, independence ------------------------------------------
    @(negedge clk); m0 = qraw96.size();
    bfm_set96(48'd7, 30'd100, 16'd200);
    bfm_wait(15);
    @(negedge clk); m1 = qraw96.size();
    chk_set96(m0, m1 - 1, {48'd7, 2'b00, 30'd100, 16'd200}, P1,
              1'b1, 1'b1, "PH5a");
    chk_steady(m0 + 8, m1 - 1, P1, 128'd0, 0, "PH5a-post");

    @(negedge clk); m0 = qraw96.size();
    bfm_set64(48'd500000000, 16'd0);
    bfm_wait(15);
    @(negedge clk); m1 = qraw96.size();
    chk_set64(m0, m1 - 1, {48'd500000000, 16'd0}, P1,
              1'b1, 1'b1, "PH5b");
    chk_steady(m0 + 8, m1 - 1, P1, 128'd0, 0, "PH5b-post");

    // ---- PH6: the one-second wrap -----------------------------------------
    @(negedge clk); m0 = qraw96.size();
    bfm_set96(48'd3, 30'd999999800, 16'd0);
    bfm_set64(48'd999999900, 16'd0);
    bfm_wait(60);
    @(negedge clk); m1 = qraw96.size();
    chk_set96(m0, m1 - 1, {48'd3, 2'b00, 30'd999999800, 16'd0}, P1,
              1'b0, 1'b0, "PH6a");
    chk_set64(m0, m1 - 1, {48'd999999900, 16'd0}, P1,
              1'b0, 1'b0, "PH6b");
    vi96 = -1; vi64 = -1; nst = 0;
    for (k = m0; k < m1; k++) begin
      if (q_v96[k] === 1'b1) vi96 = k;
      if (q_v64[k] === 1'b1) vi64 = k;
    end
    for (k = m0; k <= m0 + 15 && k < q_st.size(); k++)
      if (q_st[k] === 1'b1) nst = nst + 1;
    if (nst != 2) fail("PH6: S3 ts_step count for two sets not two");
    if (vi96 < 0 || vi64 < 0) fail("PH6: set valids not observed");
    else chk_wrap(vi96 + 6, m1 - 1, P1, "PH6");

    // ---- PH7: reset while an adjustment is owed ---------------------------
    @(negedge clk); m0 = qraw96.size();
    bfm_adjust(4'h1, 16'h0000, 16'd200);
    bfm_wait(5);
    bfm_reset(5);
    bfm_wait(45);
    @(negedge clk); m1 = qraw96.size();
    e2 = -1;
    for (i = m0; i < q_cyc.size(); i++) if (q_cyc[i] == 1) e2 = i;
    if (e2 < 0) fail("PH7: R1 reset release not observed");
    else begin
      if (e2 + 1 < qraw96.size()) begin
        if (tot96(qraw96[e2+1]) >= 1000000000 ||
            tot64(qraw64[e2+1]) >= 1000000000)
          fail("PH7: R2 bases did not return to zero");
      end
      chk_steady(e2, m1 - 1, P_DEF, 128'd2, 5, "PH7");
    end

    // ---- verdict -----------------------------------------------------------
    if (errors == 0) $display("RESULT: PASS");
    else             $display("RESULT: FAIL");
    $finish;
  end

endmodule
