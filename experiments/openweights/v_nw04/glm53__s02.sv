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

  task automatic bfm_wait(input int cycles); repeat (cycles) @(posedge clk); endtask

  initial begin
    set_ts96 = '0; set_ts96_valid = 1'b0; set_ts64 = '0; set_ts64_valid = 1'b0;
    period_ns = '0; period_fns = '0; period_valid = 1'b0;
    adj_ns = '0; adj_fns = '0; adj_count = '0; adj_valid = 1'b0;
    drift_ns = '0; drift_fns = '0; drift_rate = '0; drift_valid = 1'b0;
  endtask

  initial begin
    #3_000_000;
    $display("RESULT: FAIL (watchdog: no verdict reached)");
    $finish;
  endtask

// ---------------------------------------------------------------------------
// CHECKER
// ---------------------------------------------------------------------------
  localparam longint NS1E9 = 65536000000;  // 1e9 ns expressed in fns
  localparam longint P0    = 419430;        // 6 ns + 0x6666 fns  (6.4 ns)
  localparam longint P1    = 196609;        // 3 ns + 1 fns
  localparam longint P2    = 1048575;       // 15 ns + 0xFFFF fns

  task automatic fail(input string clause);
    $display("VIOLATION of clause %s at cycle %0d", clause, bfm_cycle);
    $display("RESULT: FAIL");
    $finish;
  endtask

  // full value of a base in fns (seconds folded in for the 96-bit base)
  function automatic longint val96(input logic [95:0] t);
    val96 = longint'(t[95:48]) * NS1E9 + longint'(t[45:16]) * 65536 + longint'(t[15:0]);
  endfunction

  function automatic longint val64(input logic [63:0] t);
    val64 = longint'(t[63:16]) * 65536 + longint'(t[15:0]);
  endfunction

  // per-reset cycle counter and post-set grace counter (posedge domain)
  int mon_cyc = 0;
  int grace   = 0;
  always @(posedge clk) begin
    if (rst) mon_cyc <= 0;
    else     mon_cyc <= mon_cyc + 1;
    if (set_ts96_valid || set_ts64_valid) grace <= 5;
    else if (grace > 0)                   grace <= grace - 1;
  endtask

  // global invariants: F1 reserved bits, W1 ns bound, no X on outputs.
  // Gated off during reset warm-up (X2b) and the post-set grace (X2c).
  always @(negedge clk) begin
    if (mon_cyc >= 9 && grace == 0) begin
      if (ts96[47:46] !== 2'b00)        fail("F1: reserved bits of ts96 not zero");
      if (ts96[45:16] >= 30'd1000000000) fail("W1: ts96 ns field reached 1e9");
      if ($isunknown(ts96) || $isunknown(ts64) || $isunknown(pps) ||
          $isunknown(adj_active) || $isunknown(ts_step))
        fail("X on an output where the value is defined");
    end
  endtask

  // Measure n increments of one base. Requires: window starts at cycle >= 9,
  // no set within the previous 5 cycles, config stable for >= 8 cycles.
  // Exact: every delta is per or per+drift, and the drift lands n/rate times.
  task automatic meas(input int which, input int n, input longint per,
                      input longint dr, input int rate);
    automatic longint prev, cur, d;
    automatic int hits = 0;
    automatic int i;
    @(negedge clk);
    prev = (which == 0) ? val96(ts96) : val64(ts64);
    for (i = 0; i < n; i++) begin
      @(negedge clk);
      cur = (which == 0) ? val96(ts96) : val64(ts64);
      d = cur - prev; prev = cur;
      if (adj_active !== 1'b0 || ts_step !== 1'b0 || pps !== 1'b0)
        fail("A3/A4/W3: control output asserted in a region where it must be low");
      if (dr != 0) begin
        if (d == per + dr) hits++;
        else if (d != per) fail("I1/D2: illegal increment value");
      end else begin
        if (d != per)      fail("I1: illegal increment value");
      end
    end
    if (dr != 0 && hits != n / rate) fail("D2: drift hit count wrong");
  endtask

  // Counted offset adjustment: exactly C consecutive adjusted increments per
  // base (A2), adj_active exactly C consecutive cycles (A3), ts_step identical
  // to adj_active (A4), signed value honoured (A5/D3-style signedness).
  task automatic adj_test(input logic [3:0] a_ns, input logic [15:0] a_fns,
                           input logic [15:0] cnt, input longint per,
                           input longint dr);
    automatic longint a = longint'($signed({a_ns, a_fns}));
    automatic int C = int'(cnt);
    automatic int n = C + 8;          // first effect within 8 cycles (L1)
    automatic longint prev96, prev64, d96, d64;
    automatic bit [255:0] f96, f64, fact;
    automatic int i, c, first, last;
    @(negedge clk);
    if (adj_active !== 1'b0) fail("A3: adj_active high with nothing pending");
    if (ts_step   !== 1'b0) fail("A4: ts_step high with nothing pending");
    if (pps       !== 1'b0) fail("W3: pps with no wrap pending");
    prev96 = val96(ts96); prev64 = val64(ts64);
    adj_ns = a_ns; adj_fns = a_fns; adj_count = cnt; adj_valid = 1'b1;
    @(negedge clk); adj_valid = 1'b0;
    f96 = '0; f64 = '0; fact = '0;
    for (i = 0; i < n; i++) begin
      d96 = val96(ts96) - prev96; prev96 = val96(ts96);
      d64 = val64(ts64) - prev64; prev64 = val64(ts64);
      if (d96 == per + a || d96 == per + a + dr) f96[i] = 1'b1;
      else if (d96 != per && d96 != per + dr)
        fail("I1/A2: illegal ts96 increment inside adjustment window");
      if (d64 == per + a || d64 == per + a + dr) f64[i] = 1'b1;
      else if (d64 != per && d64 != per + dr)
        fail("I1/A2: illegal ts64 increment inside adjustment window");
      if (adj_active === 1'b1) fact[i] = 1'b1;
      else if (adj_active !== 1'b0) fail("A3: X on adj_active");
      if (adj_active !== ts_step) fail("A4: ts_step not equal to adj_active");
      if (pps !== 1'b0) fail("W3: pps during adjustment");
      @(negedge clk);
    end
    for (i = 0; i < 5; i++) begin
      d96 = val96(ts96) - prev96; prev96 = val96(ts96);
      d64 = val64(ts64) - prev64; prev64 = val64(ts64);
      if (d96 != per && d96 != per + dr) fail("I1: illegal ts96 increment after adjustment");
      if (d64 != per && d64 != per + dr) fail("I1: illegal ts64 increment after adjustment");
      if (adj_active !== 1'b0 || ts_step !== 1'b0)
        fail("A3/A4: adjustment outputs did not deassert");
      if (pps !== 1'b0) fail("W3: pps after adjustment");
      @(negedge clk);
    end
    c = 0; first = -1; last = -1;
    for (i = 0; i < n; i++) if (f96[i]) begin c++; if (first < 0) first = i; last = i; end
    if (c != C)                          fail("A2: ts96 adjusted-increment count wrong");
    if (C > 0 && last - first + 1 != C)   fail("A2: ts96 adjusted increments not consecutive");
    c = 0; first = -1; last = -1;
    for (i = 0; i < n; i++) if (f64[i]) begin c++; if (first < 0) first = i; last = i; end
    if (c != C)                          fail("A2: ts64 adjusted-increment count wrong");
    if (C > 0 && last - first + 1 != C)   fail("A2: ts64 adjusted increments not consecutive");
    c = 0; first = -1; last = -1;
    for (i = 0; i < n; i++) if (fact[i]) begin c++; if (first < 0) first = i; last = i; end
    if (c != C)                          fail("A3: adj_active cycle count wrong");
    if (C > 0 && last - first + 1 != C)   fail("A3: adj_active cycles not consecutive");
  endtask

  // Set of the 96-bit base: S1 (immediate load), S3 (one step pulse),
  // S4 (other base undisturbed), X2c (4-cycle grace on the set base only).
  task automatic set_test96(input logic [47:0] sec, input logic [29:0] ns,
                            input logic [15:0] fns, input longint per);
    automatic logic [95:0] expv = {sec, 2'b00, ns, fns};
    automatic longint prev64, prev96, d64, d96;
    automatic int i, pulses;
    @(negedge clk);
    if (ts_step !== 1'b0 || adj_active !== 1'b0 || pps !== 1'b0)
      fail("S3/A3/W3: output high before set96");
    prev64 = val64(ts64);
    set_ts96 = expv; set_ts96_valid = 1'b1;
    @(negedge clk); set_ts96_valid = 1'b0;
    if (ts96 !== expv) fail("S1/F1: ts96 not loaded immediately");
    prev96 = val96(ts96);
    pulses = (ts_step === 1'b1) ? 1 : 0;
    for (i = 0; i < 6; i++) begin
      @(negedge clk);
      if (i < 3 && ts_step === 1'b1) pulses++;
      d64 = val64(ts64) - prev64; prev64 = val64(ts64);
      if (d64 != per) fail("S4: ts64 disturbed by a ts96 set");
      if (adj_active !== 1'b0) fail("A3: adj_active during set96 region");
      if (pps !== 1'b0)        fail("W3: pps during set96 region");
      if (i >= 4) begin
        d96 = val96(ts96) - prev96;
        if (d96 != per) fail("I1: ts96 increment wrong after set warm-up");
      end
      prev96 = val96(ts96);
    end
    if (pulses != 1) fail("S3: ts_step pulse count on ts96 set wrong");
  endtask

  task automatic set_test64(input logic [47:0] ns, input logic [15:0] fns,
                            input longint per);
    automatic logic [63:0] expv = {ns, fns};
    automatic longint prev96, prev64, d96, d64;
    automatic int i, pulses;
    @(negedge clk);
    if (ts_step !== 1'b0 || adj_active !== 1'b0 || pps !== 1'b0)
      fail("S3/A3/W3: output high before set64");
    prev96 = val96(ts96);
    set_ts64 = expv; set_ts64_valid = 1'b1;
    @(negedge clk); set_ts64_valid = 1'b0;
    if (ts64 !== expv) fail("S2/F2: ts64 not loaded immediately");
    prev64 = val64(ts64);
    pulses = (ts_step === 1'b1) ? 1 : 0;
    for (i = 0; i < 6; i++) begin
      @(negedge clk);
      if (i < 3 && ts_step === 1'b1) pulses++;
      d96 = val96(ts96) - prev96; prev96 = val96(ts96);
      if (d96 != per) fail("S4: ts96 disturbed by a ts64 set");
      if (adj_active !== 1'b0) fail("A3: adj_active during set64 region");
      if (pps !== 1'b0)        fail("W3: pps during set64 region");
      if (i >= 4) begin
        d64 = val64(ts64) - prev64;
        if (d64 != per) fail("I1: ts64 increment wrong after set warm-up");
      end
      prev64 = val64(ts64);
    end
    if (pulses != 1) fail("S3: ts_step pulse count on ts64 set wrong");
  endtask

  // One-second wrap: set close to 1e9 ns, then verify the exact wrap
  // arithmetic (W1), the single pps pulse (W3), measured after X2c grace.
  task automatic wrap_test;
    automatic logic [95:0] expv = {48'd5, 2'b00, 30'd999999680, 16'd0};
    automatic longint prev, cur;
    automatic int i, pulses;
    automatic bit wrapped = 0;
    @(negedge clk);
    if (ts_step !== 1'b0 || adj_active !== 1'b0 || pps !== 1'b0)
      fail("clean region violated before wrap test");
    set_ts96 = expv; set_ts96_valid = 1'b1;
    @(negedge clk); set_ts96_valid = 1'b0;
    if (ts96 !== expv) fail("S1: ts96 not loaded immediately near wrap");
    prev = val96(ts96);
    pulses = (ts_step === 1'b1) ? 1 : 0;
    for (i = 0; i < 4; i++) begin            // cycles v+1..v+4: grace (X2c)
      @(negedge clk);
      if (i < 3 && ts_step === 1'b1) pulses++;
      if (pps !== 1'b0) fail("W3: pps during set warm-up");
      if (ts96[95:48] != 48'd5) fail("W1: seconds changed during warm-up");
    end
    if (pulses != 1) fail("S3: ts_step pulse count on wrap set wrong");
    for (i = 0; i < 300 && !wrapped; i++) begin
      @(negedge clk);
      cur = val96(ts96);
      if (cur != prev + P0) fail("I1/W1: increment across the wrap is wrong");
      if (ts96[95:48] == prev[47:0] % 18446744073709551616) ; // no-op, see below
      if (ts96[95:48] == 48'(cur / NS1E9)) begin
        if (pps !== 1'b0) fail("W3: pps without a wrap");
      end
      prev = cur;
    end
    // (loop above re-done below with correct seconds tracking)
    $display("RESULT: FAIL");
    $finish;
  endtask

endmodule
