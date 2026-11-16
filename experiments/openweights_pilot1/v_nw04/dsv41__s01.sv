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

  // ---- idle everything at time zero ----------------------------------------
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
  // OUR CHECKING CODE
  // ---------------------------------------------------------------------------
  int errors = 0;

  function automatic logic [47:0] get_sec96(input logic [95:0] ts);
    get_sec96 = ts[95:48];
  endfunction

  function automatic logic [29:0] get_ns96(input logic [95:0] ts);
    get_ns96 = ts[45:16];
  endfunction

  function automatic logic [15:0] get_fns96(input logic [95:0] ts);
    get_fns96 = ts[15:0];
  endfunction

  function automatic logic [47:0] get_ns64(input logic [63:0] ts);
    get_ns64 = ts[63:16];
  endfunction

  function automatic logic [15:0] get_fns64(input logic [63:0] ts);
    get_fns64 = ts[15:0];
  endfunction

  function automatic longint calc_inc96(input logic [95:0] prev, input logic [95:0] curr);
    longint prev_total, curr_total, inc;
    logic [47:0] psec, csec;
    logic [29:0] pns, cns;
    logic [15:0] pfns, cfns;
    psec = get_sec96(prev); csec = get_sec96(curr);
    pns = get_ns96(prev); cns = get_ns96(curr);
    pfns = get_fns96(prev); cfns = get_fns96(curr);
    prev_total = longint'(pns) * 65536 + longint'(pfns);
    curr_total = longint'(cns) * 65536 + longint'(cfns);
    inc = (longint'(csec) - longint'(psec)) * 64'd65536000000000 + (curr_total - prev_total);
    calc_inc96 = inc;
  endfunction

  function automatic longint calc_inc64(input logic [63:0] prev, input logic [63:0] curr);
    longint pns, cns, pfns, cfns, inc;
    pns = get_ns64(prev); cns = get_ns64(curr);
    pfns = get_fns64(prev); cfns = get_fns64(curr);
    inc = (cns - pns) * 65536 + (cfns - pfns);
    calc_inc64 = inc;
  endfunction

  task automatic check_default_increments(input int N);
    logic [95:0] prev96, curr96;
    logic [63:0] prev64, curr64;
    longint inc96, inc64;
    longint P, D;
    int i;
    int drift_count96, drift_count64;
    int last_drift96, last_drift64;
    P = 6*65536 + 16'h6666;
    D = 2;
    drift_count96 = 0; drift_count64 = 0;
    last_drift96 = -1000; last_drift64 = -1000;
    repeat (8) @(posedge clk);
    @(negedge clk);
    prev96 = ts96; prev64 = ts64;
    for (i=1; i<=N; i++) begin
      @(posedge clk);
      @(negedge clk);
      curr96 = ts96; curr64 = ts64;
      if (curr96[47:46] != 2'b00) begin errors++; $display("FAIL: F1 default cycle %0d bits 47:46", i); end
      if (get_ns96(curr96) >= 1000000000) begin errors++; $display("FAIL: W1 default cycle %0d ns96 >= 1e9", i); end
      inc96 = calc_inc96(prev96, curr96);
      inc64 = calc_inc64(prev64, curr64);
      if (inc96 == P + D) begin
        drift_count96++;
        if (last_drift96 != -1000 && (i - last_drift96) != 5) begin errors++; $display("FAIL: D2 default drift96 gap %0d at cycle %0d", i - last_drift96, i); end
        last_drift96 = i;
      end else if (inc96 != P) begin
        errors++; $display("FAIL: I2 default inc96 %0d not P or P+D at cycle %0d", inc96, i);
      end
      if (inc64 == P + D) begin
        drift_count64++;
        if (last_drift64 != -1000 && (i - last_drift64) != 5) begin errors++; $display("FAIL: D2 default drift64 gap %0d at cycle %0d", i - last_drift64, i); end
        last_drift64 = i;
      end else if (inc64 != P) begin
        errors++; $display("FAIL: I2 default inc64 %0d not P or P+D at cycle %0d", inc64, i);
      end
      prev96 = curr96; prev64 = curr64;
    end
    if (drift_count96 != N/5) begin errors++; $display("FAIL: D2 default drift count96 %0d expected %0d", drift_count96, N/5); end
    if (drift_count64 != N/5) begin errors++; $display("FAIL: D2 default drift count64 %0d expected %0d", drift_count64, N/5); end
  endtask

  task automatic check_increments(input int N, input longint P, input longint D, input int rate, input string label);
    logic [95:0] prev96, curr96;
    logic [63:0] prev64, curr64;
    longint inc96, inc64;
    int i;
    int drift_count96, drift_count64;
    int last_drift96, last_drift64;
    drift_count96 = 0; drift_count64 = 0;
    last_drift96 = -1000; last_drift64 = -1000;
    @(negedge clk);
    prev96 = ts96; prev64 = ts64;
    for (i=1; i<=N; i++) begin
      @(posedge clk);
      @(negedge clk);
      curr96 = ts96; curr64 = ts64;
      if (curr96[47:46] != 2'b00) begin errors++; $display("FAIL: F1 %s cycle %0d bits 47:46", label, i); end
      if (get_ns96(curr96) >= 1000000000) begin errors++; $display("FAIL: W1 %s cycle %0d ns96 >= 1e9", label, i); end
      inc96 = calc_inc96(prev96, curr96);
      inc64 = calc_inc64(prev64, curr64);
      if (inc96 == P + D) begin
        drift_count96++;
        if (last_drift96 != -1000 && (i - last_drift96) != rate) begin errors++; $display("FAIL: D2 %s drift96 gap %0d expected %0d at cycle %0d", label, i - last_drift96, rate, i); end
        last_drift96 = i;
      end else if (inc96 != P) begin
        errors++; $display("FAIL: I1 %s inc96 %0d not P(%0d) or P+D(%0d) at cycle %0d", label, inc96, P, P+D, i);
      end
      if (inc64 == P + D) begin
        drift_count64++;
        if (last_drift64 != -1000 && (i - last_drift64) != rate) begin errors++; $display("FAIL: D2 %s drift64 gap %0d expected %0d at cycle %0d", label, i - last_drift64, rate, i); end
        last_drift64 = i;
      end else if (inc64 != P) begin
        errors++; $display("FAIL: I1 %s inc64 %0d not P(%0d) or P+D(%0d) at cycle %0d", label, inc64, P, P+D, i);
      end
      prev96 = curr96; prev64 = curr64;
    end
    if (drift_count96 != N/rate) begin errors++; $display("FAIL: D2 %s drift count96 %0d expected %0d", label, drift_count96, N/rate); end
    if (drift_count64 != N/rate) begin errors++; $display("FAIL: D2 %s drift count64 %0d expected %0d", label, drift_count64, N/rate); end
  endtask

  task automatic test_adjust(input logic [3:0] ns, input logic [15:0] fns, input logic [15:0] count, input longint P, input int obs_cycles, input string label);
    logic [95:0] prev96, curr96;
    logic [63:0] prev64, curr64;
    longint inc96, inc64, adj_val;
    logic signed [3:0] sns;
    int i;
    int adj_inc_count96, adj_inc_count64;
    int adj_active_count;
    int first_adj_inc96, last_adj_inc96;
    int first_adj_inc64, last_adj_inc64;
    int first_active, last_active;
    sns = ns;
    adj_val = longint'(sns) * 65536 + longint'(fns);
    adj_inc_count96 = 0; adj_inc_count64 = 0;
    adj_active_count = 0;
    first_adj_inc96 = -1; last_adj_inc96 = -1;
    first_adj_inc64 = -1; last_adj_inc64 = -1;
    first_active = -1; last_active = -1;

    @(negedge clk);
    adj_ns = ns; adj_fns = fns; adj_count = count; adj_valid = 1'b1;
    prev96 = ts96; prev64 = ts64;
    @(posedge clk);
    @(negedge clk);
    adj_valid = 1'b0;
    for (i=1; i<=obs_cycles; i++) begin
      if (i > 1) begin
        @(posedge clk);
        @(negedge clk);
      end
      curr96 = ts96; curr64 = ts64;
      inc96 = calc_inc96(prev96, curr96);
      inc64 = calc_inc64(prev64, curr64);
      if (inc96 == P + adj_val) begin
        adj_inc_count96++;
        if (first_adj_inc96 == -1) first_adj_inc96 = i;
        last_adj_inc96 = i;
      end else if (inc96 != P) begin
        errors++; $display("FAIL: A2 %s inc96 %0d not P or P+adj at cycle %0d", label, inc96, i);
      end
      if (inc64 == P + adj_val) begin
        adj_inc_count64++;
        if (first_adj_inc64 == -1) first_adj_inc64 = i;
        last_adj_inc64 = i;
      end else if (inc64 != P) begin
        errors++; $display("FAIL: A2 %s inc64 %0d not P or P+adj at cycle %0d", label, inc64, i);
      end
      if (adj_active) begin
        adj_active_count++;
        if (first_active == -1) first_active = i;
        last_active = i;
      end
      if (ts_step != adj_active) begin
        errors++; $display("FAIL: A4 %s ts_step %b != adj_active %b at cycle %0d", label, ts_step, adj_active, i);
      end
      prev96 = curr96; prev64 = curr64;
    end
    if (adj_inc_count96 != count) begin errors++; $display("FAIL: A2 %s adj_inc_count96 %0d expected %0d", label, adj_inc_count96, count); end
    if (adj_inc_count64 != count) begin errors++; $display("FAIL: A2 %s adj_inc_count64 %0d expected %0d", label, adj_inc_count64, count); end
    if (adj_active_count != count) begin errors++; $display("FAIL: A3 %s adj_active_count %0d expected %0d", label, adj_active_count, count); end
    if (count > 0) begin
      if (last_adj_inc96 - first_adj_inc96 + 1 != count) begin errors++; $display("FAIL: A2 %s adj increments96 not consecutive", label); end
      if (last_adj_inc64 - first_adj_inc64 + 1 != count) begin errors++; $display("FAIL: A2 %s adj increments64 not consecutive", label); end
      if (last_active - first_active + 1 != count) begin errors++; $display("FAIL: A3 %s adj_active not consecutive", label); end
    end
  endtask

  task automatic test_set96_with_drift(input logic [47:0] sec, input logic [29:0] ns, input logic [15:0] fns, input longint P, input longint D, input int rate);
    logic [95:0] set_val, prev96, curr96;
    logic [63:0] prev64, curr64;
    longint inc96, inc64;
    int i;
    int step_count;
    int drift_count96, drift_count64;
    int last_drift96, last_drift64;
    set_val = {sec, 2'b00, ns, fns};
    @(negedge clk);
    prev96 = ts96; prev64 = ts64;
    set_ts96 = set_val; set_ts96_valid = 1'b1;
    @(posedge clk);
    @(negedge clk);
    set_ts96_valid = 1'b0;
    if (ts96 != set_val) begin errors++; $display("FAIL: S1 set96 value %h expected %h", ts96, set_val); end
    curr64 = ts64;
    inc64 = calc_inc64(prev64, curr64);
    if (inc64 != P && inc64 != P + D) begin errors++; $display("FAIL: S4 set96 disturbed ts64 inc %0d", inc64); end
    step_count = 0;
    if (ts_step) step_count++;
    for (i=0; i<10; i++) begin
      @(posedge clk);
      @(negedge clk);
      if (ts_step) step_count++;
    end
    if (step_count != 1) begin errors++; $display("FAIL: S3 set96 ts_step count %0d", step_count); end
    drift_count96 = 0; drift_count64 = 0;
    last_drift96 = -1000; last_drift64 = -1000;
    @(negedge clk);
    prev96 = ts96; prev64 = ts64;
    for (i=1; i<=30; i++) begin
      @(posedge clk);
      @(negedge clk);
      curr96 = ts96; curr64 = ts64;
      inc96 = calc_inc96(prev96, curr96);
      inc64 = calc_inc64(prev64, curr64);
      if (inc96 == P + D) begin
        drift_count96++;
        if (last_drift96 != -1000 && (i - last_drift96) != rate) begin errors++; $display("FAIL: D2 set96 post drift96 gap %0d at i=%0d", i - last_drift96, i); end
        last_drift96 = i;
      end else if (inc96 != P) begin
        errors++; $display("FAIL: I1 set96 post inc96 %0d not P or P+D at i=%0d", inc96, i);
      end
      if (inc64 == P + D) begin
        drift_count64++;
        if (last_drift64 != -1000 && (i - last_drift64) != rate) begin errors++; $display("FAIL: D2 set96 post drift64 gap %0d at i=%0d", i - last_drift64, i); end
        last_drift64 = i;
      end else if (inc64 != P) begin
        errors++; $display("FAIL: S4 set96 post inc64 %0d not P or P+D at i=%0d", inc64, i);
      end
      prev96 = curr96; prev64 = curr64;
    end
    if (drift_count96 != 30/rate) begin errors++; $display("FAIL: D2 set96 post drift count96 %0d expected %0d", drift_count96, 30/rate); end
    if (drift_count64 != 30/rate) begin errors++; $display("FAIL: S4 set96 post drift count64 %0d expected %0d", drift_count64, 30/rate); end
  endtask

  task automatic test_set64_with_drift(input logic [47:0] ns, input logic [15:0] fns, input longint P, input longint D, input int rate);
    logic [63:0] set_val, prev64, curr64;
    logic [95:0] prev96, curr96;
    longint inc96, inc64;
    int i;
    int step_count;
    int drift_count96, drift_count64;
    int last_drift96, last_drift64;
    set_val = {ns, fns};
    @(negedge clk);
    prev96 = ts96; prev64 = ts64;
    set_ts64 = set_val; set_ts64_valid = 1'b1;
    @(posedge clk);
    @(negedge clk);
    set_ts64_valid = 1'b0;
    if (ts64 != set_val) begin errors++; $display("FAIL: S2 set64 value %h expected %h", ts64, set_val); end
    curr96 = ts96;
    inc96 = calc_inc96(prev96, curr96);
    if (inc96 != P && inc96 != P + D) begin errors++; $display("FAIL: S4 set64 disturbed ts96 inc %0d", inc96); end
    step_count = 0;
    if (ts_step) step_count++;
    for (i=0; i<10; i++) begin
      @(posedge clk);
      @(negedge clk);
      if (ts_step) step_count++;
    end
    if (step_count != 1) begin errors++; $display("FAIL: S3 set64 ts_step count %0d", step_count); end
    drift_count96 = 0; drift_count64 = 0;
    last_drift96 = -1000; last_drift64 = -1000;
    @(negedge clk);
    prev96 = ts96; prev64 = ts64;
    for (i=1; i<=30; i++) begin
      @(posedge clk);
      @(negedge clk);
      curr96 = ts96; curr64 = ts64;
      inc96 = calc_inc96(prev96, curr96);
      inc64 = calc_inc64(prev64, curr64);
      if (inc96 == P + D) begin
        drift_count96++;
        if (last_drift96 != -1000 && (i - last_drift96) != rate) begin errors++; $display("FAIL: D2 set64 post drift96 gap %0d at i=%0d", i - last_drift96, i); end
        last_drift96 = i;
      end else if (inc96 != P) begin
        errors++; $display("FAIL: S4 set64 post inc96 %0d not P or P+D at i=%0d", inc96, i);
      end
      if (inc64 == P + D) begin
        drift_count64++;
        if (last_drift64 != -1000 && (i - last_drift64) != rate) begin errors++; $display("FAIL: D2 set64 post drift64 gap %0d at i=%0d", i - last_drift64, i); end
        last_drift64 = i;
      end else if (inc64 != P) begin
        errors++; $display("FAIL: I1 set64 post inc64 %0d not P or P+D at i=%0d", inc64, i);
      end
      prev96 = curr96; prev64 = curr64;
    end
    if (drift_count96 != 30/rate) begin errors++; $display("FAIL: S4 set64 post drift count96 %0d expected %0d", drift_count96, 30/rate); end
    if (drift_count64 != 30/rate) begin errors++; $display("FAIL: D2 set64 post drift count64 %0d expected %0d", drift_count64, 30/rate); end
  endtask

  task automatic test_adj_independence(input bit set96);
    logic [95:0] prev96, curr96;
    logic [63:0] prev64, curr64;
    longint inc_unset;
    int i;
    int adj_count_unset;
    int first_adj, last_adj;
    logic [95:0] set96_val;
    logic [63:0] set64_val;
    longint P;
    longint adj_val;
    P = 655360;
    adj_val = 1000;
    adj_count_unset = 0;
    first_adj = -1; last_adj = -1;
    set96_val = {48'd0, 2'b00, 30'd1000, 16'd0};
    set64_val = {48'd2000, 16'd0};

    @(negedge clk);
    adj_ns = 0; adj_fns = 1000; adj_count = 10; adj_valid = 1;
    if (set96) prev64 = ts64; else prev96 = ts96;
    for (i=1; i<=30; i++) begin
      @(posedge clk);
      @(negedge clk);
      if (i == 1) adj_valid = 0;
      if (i == 4) begin
        if (set96) begin set_ts96 = set96_val; set_ts96_valid = 1; end
        else begin set_ts64 = set64_val; set_ts64_valid = 1; end
      end
      if (i == 5) begin
        if (set96) set_ts96_valid = 0; else set_ts64_valid = 0;
      end
      if (set96) begin
        curr64 = ts64;
        inc_unset = calc_inc64(prev64, curr64);
        prev64 = curr64;
      end else begin
        curr96 = ts96;
        inc_unset = calc_inc96(prev96, curr96);
        prev96 = curr96;
      end
      if (inc_unset == P + adj_val) begin
        adj_count_unset++;
        if (first_adj == -1) first_adj = i;
        last_adj = i;
      end else if (inc_unset != P) begin
        errors++; $display("FAIL: S4 adj_ind set96=%b inc_unset %0d not P or P+adj at i=%0d", set96, inc_unset, i);
      end
    end
    if (adj_count_unset != 10) begin errors++; $display("FAIL: S4 adj_ind set96=%b adj_count_unset %0d expected 10", set96, adj_count_unset); end
    if (last_adj - first_adj + 1 != 10) begin errors++; $display("FAIL: S4 adj_ind set96=%b adj increments not consecutive", set96); end
  endtask

  task automatic test_wrap96();
    logic [95:0] set_val;
    int i;
    int pps_count;
    set_val = {48'd0, 2'b00, 30'd999_999_990, 16'd0};
    @(negedge clk);
    set_ts96 = set_val; set_ts96_valid = 1;
    @(posedge clk);
    @(negedge clk);
    set_ts96_valid = 0;
    if (ts96 != set_val) begin errors++; $display("FAIL: S1 wrap96 set value %h expected %h", ts96, set_val); end
    pps_count = 0;
    for (i=0; i<20; i++) begin
      @(posedge clk);
      @(negedge clk);
      if (pps) pps_count++;
      if (ts96[47:46] != 2'b00) begin errors++; $display("FAIL: F1 wrap96 bits 47:46 at i=%0d", i); end
      if (get_ns96(ts96) >= 1000000000) begin errors++; $display("FAIL: W1 wrap96 ns >= 1e9 at i=%0d", i); end
    end
    if (get_sec96(ts96) != 1) begin errors++; $display("FAIL: W1 wrap96 seconds %0d expected 1", get_sec96(ts96)); end
    if (get_ns96(ts96) >= 1000000000) begin errors++; $display("FAIL: W1 wrap96 final ns >= 1e9"); end
    if (pps_count != 1) begin errors++; $display("FAIL: W3 wrap96 pps_count %0d expected 1", pps_count); end
  endtask

  task automatic test_wrap64();
    logic [63:0] set_val;
    int i;
    int pps_count;
    set_val = {48'd999_999_990, 16'd0};
    @(negedge clk);
    set_ts64 = set_val; set_ts64_valid = 1;
    @(posedge clk);
    @(negedge clk);
    set_ts64_valid = 0;
    if (ts64 != set_val) begin errors++; $display("FAIL: S2 wrap64 set value %h expected %h", ts64, set_val); end
    repeat(5) @(posedge clk);
    @(negedge clk);
    if (get_ns64(ts64) < 1000000000) begin errors++; $display("FAIL: W2 wrap64 ns %0d < 1e9 after warm-up", get_ns64(ts64)); end
    pps_count = 0;
    for (i=0; i<10; i++) begin
      @(posedge clk);
      @(negedge clk);
      if (pps) pps_count++;
      if (get_ns64(ts64) < 1000000000) begin errors++; $display("FAIL: W2 wrap64 ns dropped below 1e9 at i=%0d", i); end
    end
    if (pps_count != 0) begin errors++; $display("FAIL: W3 wrap64 pps_count %0d expected 0", pps_count); end
  endtask

  // ---------------------------------------------------------------------------
  // MAIN TEST SEQUENCE
  // ---------------------------------------------------------------------------
  initial begin
    // 1. Default test
    bfm_reset(5);
    check_default_increments(100);

    // 2. Period test
    bfm_period(10, 16'h8000);
    bfm_wait(10);
    check_increments(20, 10*65536 + 16'h8000, 2, 5, "period");

    // 3. Disable drift
    bfm_drift(0, 0, 1);
    bfm_wait(10);
    check_increments(10, 10*65536 + 16'h8000, 0, 1, "drift_off");

    // 4. Offset tests
    test_adjust(0, 1000, 7, 688128, 30, "adj_pos");
    test_adjust(4'hF, 16'hFC18, 5, 688128, 30, "adj_neg");
    test_adjust(0, 1000, 0, 688128, 20, "adj_zero");

    // 5. Reset test
    bfm_reset(5);
    if (ts96 != 0) begin errors++; $display("FAIL: R2 reset ts96 not zero"); end
    if (ts64 != 0) begin errors++; $display("FAIL: R2 reset ts64 not zero"); end
    if (adj_active != 0) begin errors++; $display("FAIL: R2 reset adj_active not zero"); end
    check_default_increments(50);

    // 6. Set tests with drift
    bfm_reset(5);
    bfm_wait(9);
    bfm_period(10, 0);
    bfm_wait(10);
    bfm_drift(0, 100, 3);
    bfm_wait(10);
    test_set96_with_drift(0, 1000, 0, 655360, 100, 3);
    test_set64_with_drift(2000, 0, 655360, 100, 3);

    // 7. Adj independence with set
    bfm_reset(5);
    bfm_wait(9);
    bfm_period(10, 0);
    bfm_wait(10);
    bfm_drift(0, 0, 1);
    bfm_wait(10);
    test_adj_independence(1'b1); // set96, check ts64

    bfm_reset(5);
    bfm_wait(9);
    bfm_period(10, 0);
    bfm_wait(10);
    bfm_drift(0, 0, 1);
    bfm_wait(10);
    test_adj_independence(1'b0); // set64, check ts96

    // 8. Wrap tests
    bfm_reset(5);
    bfm_wait(9);
    bfm_drift(0, 0, 1);
    bfm_wait(10);
    bfm_period(10, 0);
    bfm_wait(10);
    test_wrap96();

    bfm_reset(5);
    bfm_wait(9);
    bfm_drift(0, 0, 1);
    bfm_wait(10);
    bfm_period(10, 0);
    bfm_wait(10);
    test_wrap64();

    // Final verdict
    if (errors == 0) $display("RESULT: PASS");
    else $display("RESULT: FAIL");
    $finish;
  end

endmodule
