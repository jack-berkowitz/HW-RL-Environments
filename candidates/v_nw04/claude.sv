// ===========================================================================
//  ptp_time_base_tb.sv
//
//  Self-checking testbench for ptp_time_base.
//
//  Method
//  ------
//  A negedge monitor records, once per cycle, the full state of both time
//  bases (ts96 flattened to a single linear fns count, ts64 raw) plus
//  ts_step_o / adj_active_o / pps_o.  Nothing is decided while stimulus runs;
//  every check is exact integer arithmetic on that log afterwards.
//
//  Each base is examined ON ITS OWN (I1, D2, L2): the per-cycle difference of
//  its own log must equal an exact legal increment, and the cycles carrying
//  the drift and the offset adjustment are recovered from that base's own
//  deltas.  Nothing compares ts96 against ts64, and nothing requires a
//  particular latency behind a valid.
//
//  Excluded windows are honoured rather than worked around:
//    X2b  cycles 1..8 after EVERY reset are skipped -- measurement of a base
//         starts at cycle 9 at the earliest (WARM below is 10, so the first
//         difference examined is the increment of cycle 11).
//    X2c  the four cycles after a set are skipped ON THE BASE THAT WAS SET,
//         and only on that base: the other base is checked straight through
//         the set, which is what makes S4 testable.
//    L1   every analysis window opens at least 24 cycles after any control
//         change, comfortably past the 8-cycle per-base bound.
// ===========================================================================
`timescale 1ns/1ps

module ptp_time_base_tb;

  // -------------------------------------------------------------------------
  // PROVIDED PLUMBING -- drives the module, checks nothing.
  // -------------------------------------------------------------------------

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

  // -------------------------------------------------------------------------
  // END OF PROVIDED PLUMBING -- everything below is the testbench proper.
  // -------------------------------------------------------------------------

  // ---- the numbers this testbench uses -------------------------------------
  // Every increment is expressed in fns (2^-16 ns), exactly.  The four
  // possible increments in any phase are kept mutually distinct so a delta
  // identifies unambiguously which of drift / adjustment it carries.
  localparam int     MAXC  = 8000;

  localparam longint P_DEF = 64'sd419430;      // 4'h6 / 16'h6666, reset period
  localparam longint D_DEF = 64'sd2;           // 4'h0 / 16'h0002, reset drift
  localparam int     R_DEF = 5;                //                  reset rate

  localparam longint P_ALT = 64'sd524289;      // 4'h8 / 16'h0001
  localparam longint D_ALT = -64'sd100;        // 4'hF / 16'hFF9C  (signed, D3)
  localparam int     R_ALT = 7;

  localparam longint A_POS =  64'sd65536;      // 4'h1 / 16'h0000
  localparam int     N_POS = 9;
  localparam longint A_NEG = -64'sd65536;      // 4'hF / 16'h0000  (signed, A5)
  localparam int     N_NEG = 13;

  // Excluded windows, each at least the contract's allowance plus margin.
  localparam int     WARM  = 10;               // X2b: cycles 1..8 unconstrained
  localparam int     SETW  = 6;                // X2c: 4 cycles, on that base only
  localparam int     SETTLE = 24;              // L1: 8 cycles, per base

  // ---- verdict bookkeeping -------------------------------------------------
  int err_count = 0;
  int msg_count = 0;

  task automatic note_fail(input string clause, input string msg);
    err_count = err_count + 1;
    if (msg_count < 30) begin
      msg_count = msg_count + 1;
      $display("VIOLATION [%s] %s", clause, msg);
    end
  endtask

  // ---- the log -------------------------------------------------------------
  // Sample i holds the state left behind by rising edge i, captured on the
  // following falling edge -- the edge opposite the one the design samples.
  logic [127:0] s_lin  [0:MAXC-1];   // ts96 as one linear fns count
  logic [63:0]  s_t64  [0:MAXC-1];
  logic [47:0]  s_sec  [0:MAXC-1];
  logic [29:0]  s_ns   [0:MAXC-1];
  logic [1:0]   s_rsv  [0:MAXC-1];
  logic         s_step [0:MAXC-1];
  logic         s_act  [0:MAXC-1];
  logic         s_pps  [0:MAXC-1];
  logic         s_mask [0:MAXC-1];   // cycles excluded from the global sweep
  int mon_n = 0;                     // read by the stimulus at posedge only

  initial begin : mask_init
    int i;
    for (i = 0; i < MAXC; i++) s_mask[i] = 1'b0;
  end

  always @(negedge clk) begin : monitor
    logic [127:0] vsec, vns;
    if (mon_n < MAXC) begin
      vsec = {80'd0, ts96[95:48]};
      vns  = {98'd0, ts96[45:16]};
      s_sec [mon_n] = ts96[95:48];
      s_rsv [mon_n] = ts96[47:46];
      s_ns  [mon_n] = ts96[45:16];
      s_lin [mon_n] = vsec * 128'd65536000000000 + (vns << 16) + {112'd0, ts96[15:0]};
      s_t64 [mon_n] = ts64;
      s_step[mon_n] = ts_step;
      s_act [mon_n] = adj_active;
      s_pps [mon_n] = pps;
      mon_n = mon_n + 1;
    end
  end

  task automatic mask_range(input int lo, input int hi);
    int i;
    for (i = lo; i <= hi; i++) if (i >= 0 && i < MAXC) s_mask[i] = 1'b1;
  endtask

  // ---- one cycle's advance of one base, exactly ----------------------------
  // base 0 = ts96 (linear), base 1 = ts64.  The subtraction is modular and the
  // low 64 bits reinterpreted as signed, so a retarding increment reads back
  // as the negative number it is.
  function automatic longint get_delta(input int base, input int i);
    logic [127:0] w;
    logic [63:0]  n;
    if (base == 0) begin
      w = s_lin[i] - s_lin[i-1];
      n = w[63:0];
    end else begin
      n = s_t64[i] - s_t64[i-1];
    end
    return $signed(n);
  endfunction

  // ---- the central check ---------------------------------------------------
  // Over [lo,hi], for ONE base:
  //   * every increment is exactly P, P+D, P+A or P+A+D          (I1, I2, F3)
  //   * the increments carrying D are spaced exactly R apart, and no window of
  //     R consecutive increments lacks one                            (D2)
  //   * the increments carrying A number exactly acount and are consecutive
  //                                                                (A2, A5)
  task automatic check_region(input int base, input int lo, input int hi,
                              input longint P, input longint D, input int R,
                              input longint A, input int acount,
                              input string tag);
    longint dv;
    int i;
    int dpos [$];
    int apos [$];
    string bn;
    bn = (base == 0) ? "ts96" : "ts64";
    if (lo < 1 || hi >= mon_n || hi < lo) begin
      note_fail("TB", $sformatf("%s: internal window error", tag));
      return;
    end
    for (i = lo; i <= hi; i++) begin
      dv = get_delta(base, i);
      if (dv == P) begin
        // plain period
      end else if (dv == P + D) begin
        dpos.push_back(i);
      end else if (acount > 0 && dv == P + A) begin
        apos.push_back(i);
      end else if (acount > 0 && dv == P + A + D) begin
        dpos.push_back(i);
        apos.push_back(i);
      end else begin
        note_fail("I1", $sformatf(
          "%s: %s advanced by %0d fns at cycle %0d; the only legal increments there are %0d (period), %0d (period+drift)%s%s",
          tag, bn, dv, i, P, P + D,
          (acount > 0) ? $sformatf(", %0d (period+adj)", P + A) : "",
          (acount > 0) ? $sformatf(", %0d (period+adj+drift)", P + A + D) : ""));
        return;   // one message is enough; the verdict is already decided
      end
    end
    // ---- drift cadence: exactly one in every R consecutive increments (D2)
    if (dpos.size() == 0) begin
      note_fail("D2", $sformatf(
        "%s: %s took no drift-carrying increment in %0d cycles; one in every %0d is required",
        tag, bn, hi - lo + 1, R));
    end else begin
      if (dpos[0] - lo >= R)
        note_fail("D2", $sformatf(
          "%s: %s went %0d increments (cycles %0d..%0d) with no drift; one in every %0d is required",
          tag, bn, dpos[0] - lo, lo, dpos[0] - 1, R));
      if (hi - dpos[dpos.size()-1] >= R)
        note_fail("D2", $sformatf(
          "%s: %s went %0d increments after cycle %0d with no drift; one in every %0d is required",
          tag, bn, hi - dpos[dpos.size()-1], dpos[dpos.size()-1], R));
      for (i = 1; i < dpos.size(); i++)
        if (dpos[i] - dpos[i-1] != R) begin
          note_fail("D2", $sformatf(
            "%s: %s drift landed at cycles %0d and %0d, a spacing of %0d; drift_rate is %0d",
            tag, bn, dpos[i-1], dpos[i], dpos[i] - dpos[i-1], R));
          break;
        end
    end
    // ---- offset adjustment: exactly acount consecutive increments (A2)
    if (acount > 0) begin
      if (apos.size() != acount)
        note_fail("A2", $sformatf(
          "%s: %s took the offset adjustment on %0d increments, adj_count_i was %0d",
          tag, bn, apos.size(), acount));
      for (i = 1; i < apos.size(); i++)
        if (apos[i] != apos[i-1] + 1) begin
          note_fail("A2", $sformatf(
            "%s: %s adjusted increments are not consecutive (cycle %0d then %0d)",
            tag, bn, apos[i-1], apos[i]));
          break;
        end
    end
  endtask

  // ---- ts_step_o / adj_active_o must be idle here --------------------------
  task automatic check_quiet(input int lo, input int hi, input string tag);
    int i;
    for (i = lo; i <= hi; i++) begin
      if (s_step[i] !== 1'b0) begin
        note_fail("A4", $sformatf(
          "%s: ts_step_o asserted at cycle %0d with no adjustment and no set in progress", tag, i));
        return;
      end
      if (s_act[i] !== 1'b0) begin
        note_fail("A3", $sformatf(
          "%s: adj_active_o asserted at cycle %0d with no adjustment in progress", tag, i));
        return;
      end
    end
  endtask

  // ---- exactly one run, of exactly want_len cycles -------------------------
  // Length and contiguity only: where the run sits relative to the adjusted
  // increments is left free by L2.
  task automatic check_run(input int lo, input int hi, input int which,
                           input int want_len, input string clause,
                           input string sig, input string tag);
    int i, runs, cur, start_i;
    logic v;
    runs = 0; cur = 0; start_i = 0;
    for (i = lo; i <= hi; i++) begin
      v = (which == 0) ? s_step[i] : s_act[i];
      if (v === 1'b1) begin
        if (cur == 0) start_i = i;
        cur = cur + 1;
      end else if (cur > 0) begin
        runs = runs + 1;
        if (cur != want_len)
          note_fail(clause, $sformatf("%s: %s was asserted for %0d consecutive cycles from cycle %0d, expected exactly %0d",
                                      tag, sig, cur, start_i, want_len));
        cur = 0;
      end
    end
    if (cur > 0) begin
      runs = runs + 1;
      if (cur != want_len)
        note_fail(clause, $sformatf("%s: %s was asserted for %0d consecutive cycles from cycle %0d, expected exactly %0d",
                                    tag, sig, cur, start_i, want_len));
    end
    if (runs != 1)
      note_fail(clause, $sformatf("%s: %s formed %0d separate assertion runs, expected exactly 1",
                                  tag, sig, runs));
  endtask

  // ---- exactly one ts_step cycle for a set (S3) ----------------------------
  task automatic check_step_once(input int lo, input int hi, input string tag);
    int i, c;
    c = 0;
    for (i = lo; i <= hi; i++) begin
      if (s_step[i] === 1'b1) c = c + 1;
      if (s_act[i] !== 1'b0)
        note_fail("A3", $sformatf("%s: adj_active_o asserted at cycle %0d, no adjustment was ordered", tag, i));
    end
    if (c != 1)
      note_fail("S3", $sformatf("%s: ts_step_o was asserted on %0d cycles, a set must raise it for exactly 1", tag, c));
  endtask

  // ---- the set landed, exactly (S1/S2) -------------------------------------
  // X2c states the written value is visible immediately and only the increment
  // FOLLOWING it is unconstrained, so the value itself must appear verbatim on
  // some cycle of the window.
  task automatic check_set(input int base, input int lo, input int hi,
                           input logic [127:0] want96, input logic [63:0] want64,
                           input string clause, input string tag);
    int i;
    int ok;
    ok = 0;
    for (i = lo; i <= hi && ok == 0; i++) begin
      if (base == 0) begin
        if (s_lin[i] == want96) ok = 1;
      end else begin
        if (s_t64[i] == want64) ok = 1;
      end
    end
    if (ok == 0)
      note_fail(clause, $sformatf("%s: the time base never took the value it was set to", tag));
  endtask

  // ---- the one-second boundary, swept over the whole run -------------------
  //   * the ns field of ts96 never reaches 1e9                        (W1)
  //   * seconds only ever advance by one, and only on a wrap          (W1)
  //   * pps_o is one cycle long, once per wrap, and never otherwise   (W3)
  //   * the reserved bits of ts96 are zero                            (F1)
  task automatic check_global();
    int i, j, k, cur, hit;
    int wraps [$];
    int ppsr  [$];
    for (i = 0; i < mon_n; i++) begin
      if (!s_mask[i]) begin
        if (s_ns[i] >= 30'd1000000000)
          note_fail("W1", $sformatf("cycle %0d: the ns field of ts96_o reached %0d; it must never reach 1000000000",
                                    i, s_ns[i]));
        if (s_rsv[i] !== 2'b00)
          note_fail("F1", $sformatf("cycle %0d: ts96_o[47:46] is not 2'b00", i));
      end
    end
    for (i = 1; i < mon_n; i++)
      if (!s_mask[i] && !s_mask[i-1] && (s_sec[i] !== s_sec[i-1])) begin
        if (s_sec[i] !== s_sec[i-1] + 48'd1)
          note_fail("W1", $sformatf("cycle %0d: the seconds field jumped from %0d to %0d", i, s_sec[i-1], s_sec[i]));
        else
          wraps.push_back(i);
      end
    cur = 0;
    for (i = 0; i < mon_n; i++) begin
      if (!s_mask[i] && s_pps[i] === 1'b1) cur = cur + 1;
      else begin
        if (cur > 0) begin
          if (cur != 1)
            note_fail("W3", $sformatf("pps_o was asserted for %0d consecutive cycles ending at cycle %0d, expected exactly 1",
                                      cur, i - 1));
          ppsr.push_back(i - cur);
        end
        cur = 0;
      end
    end
    if (cur > 0) begin
      if (cur != 1) note_fail("W3", $sformatf("pps_o was asserted for %0d consecutive cycles at the end of the run", cur));
      ppsr.push_back(mon_n - cur);
    end
    if (wraps.size() != 1)
      note_fail("W1", $sformatf("%0d one-second wraps observed, the stimulus produces exactly 1", wraps.size()));
    if (ppsr.size() != wraps.size())
      note_fail("W3", $sformatf("pps_o pulsed %0d times but %0d one-second wraps occurred",
                                ppsr.size(), wraps.size()));
    for (j = 0; j < wraps.size(); j++) begin
      hit = 0;
      for (k = 0; k < ppsr.size(); k++)
        if (ppsr[k] >= wraps[j] - 3 && ppsr[k] <= wraps[j] + 3) hit = 1;
      if (hit == 0)
        note_fail("W3", $sformatf("the wrap at cycle %0d was not marked by pps_o", wraps[j]));
    end
  endtask

  // -------------------------------------------------------------------------
  // Stimulus.  Window bookkeeping is read at a RISING edge, where mon_n is
  // stable; reading it at the falling edge would race the monitor.  Counters
  // are armed BEFORE a valid is presented, never after (L1).
  // -------------------------------------------------------------------------
  initial begin : stimulus
    int kr, ka, kb, kc;
    logic [127:0] want96;
    logic [63:0]  want64;

    // ===================== reset, and the pinned defaults ==================
    bfm_reset(5);
    @(posedge clk); kr = mon_n;       // sample kr is cycle 1 after reset
    mask_range(0, kr + WARM - 1);     // X2b: cycles 1..8 are not measurable
    bfm_wait(WARM + 160);
    @(posedge clk); ka = mon_n;
    // R2: reset left both bases at zero, so by cycle 11 they have only had a
    // handful of increments -- a base that was not cleared reads enormously
    // larger than this.
    if (s_lin[kr + WARM] > 128'd1000 * 128'd419430)
      note_fail("R2", $sformatf("ts96_o reads %0d fns shortly after reset; reset must leave it at zero",
                                s_lin[kr + WARM][63:0]));
    if (s_t64[kr + WARM] > 64'd1000 * 64'd419430)
      note_fail("R2", $sformatf("ts64_o reads %0d fns shortly after reset; reset must leave it at zero",
                                s_t64[kr + WARM]));
    // 6.4 ns per cycle exactly, 2 fns of drift on one increment in every 5.
    check_region(0, kr + WARM, ka-1, P_DEF, D_DEF, R_DEF, 64'sd0, 0, "reset defaults");
    check_region(1, kr + WARM, ka-1, P_DEF, D_DEF, R_DEF, 64'sd0, 0, "reset defaults");
    check_quiet(kr + WARM, ka-1, "reset defaults");

    // ===================== a new period and a negative drift ===============
    bfm_period(4'h8, 16'h0001);              // 8 ns + 1 fns
    bfm_drift (4'hF, 16'hFF9C, 16'd7);       // -100 fns, one in 7
    bfm_wait(SETTLE);                        // clear of the L1 latency bound
    @(posedge clk); ka = mon_n;
    bfm_wait(180);
    @(posedge clk); kb = mon_n;
    check_region(0, ka, kb-1, P_ALT, D_ALT, R_ALT, 64'sd0, 0, "steered period/drift");
    check_region(1, ka, kb-1, P_ALT, D_ALT, R_ALT, 64'sd0, 0, "steered period/drift");
    check_quiet(ka, kb-1, "steered period/drift");

    // ===================== counted offset adjustment, positive =============
    @(posedge clk); ka = mon_n;              // armed BEFORE the valid
    bfm_adjust(4'h1, 16'h0000, 16'(N_POS));  // +1 ns on 9 increments
    bfm_wait(90);
    @(posedge clk); kb = mon_n;
    check_region(0, ka+1, kb-1, P_ALT, D_ALT, R_ALT, A_POS, N_POS, "positive adjustment");
    check_region(1, ka+1, kb-1, P_ALT, D_ALT, R_ALT, A_POS, N_POS, "positive adjustment");
    check_run(ka, kb-1, 1, N_POS, "A3", "adj_active_o", "positive adjustment");
    check_run(ka, kb-1, 0, N_POS, "A4", "ts_step_o",    "positive adjustment");

    // ===================== counted offset adjustment, negative =============
    @(posedge clk); ka = mon_n;
    bfm_adjust(4'hF, 16'h0000, 16'(N_NEG));  // -1 ns on 13 increments
    bfm_wait(90);
    @(posedge clk); kb = mon_n;
    check_region(0, ka+1, kb-1, P_ALT, D_ALT, R_ALT, A_NEG, N_NEG, "negative adjustment");
    check_region(1, ka+1, kb-1, P_ALT, D_ALT, R_ALT, A_NEG, N_NEG, "negative adjustment");
    check_run(ka, kb-1, 1, N_NEG, "A3", "adj_active_o", "negative adjustment");
    check_run(ka, kb-1, 0, N_NEG, "A4", "ts_step_o",    "negative adjustment");

    // ===================== set ts64 across one second (S2, S4, W2) =========
    @(posedge clk); ka = mon_n;
    mask_range(ka, ka + SETW);
    want64 = {48'd999_999_800, 16'd0};
    bfm_set64(48'd999_999_800, 16'd0);
    bfm_wait(90);                            // ~720 ns: well past the boundary
    @(posedge clk); kb = mon_n;
    check_set(1, ka+1, ka + SETW, 128'd0, want64, "S2", "set of ts64");
    check_step_once(ka, ka + SETW, "set of ts64");
    // X2c has elapsed: ts64 has no seconds field and must sail through 1e9 ns.
    check_region(1, ka + SETW + 1, kb-1, P_ALT, D_ALT, R_ALT, 64'sd0, 0, "ts64 past one second");
    if (!(s_t64[kb-1][63:16] > 48'd1_000_000_000))
      note_fail("W2", $sformatf("ts64_o fell back to %0d ns instead of running past one second",
                                s_t64[kb-1][63:16]));
    // S4: the other base was NOT set, so X2c does not cover it -- check it
    // straight through the window.
    check_region(0, ka, kb-1, P_ALT, D_ALT, R_ALT, 64'sd0, 0, "ts96 while ts64 was set");
    check_quiet(ka + SETW + 1, kb-1, "after set of ts64");

    // ===================== set ts96 up against the wrap (S1, W1, W3) =======
    @(posedge clk); ka = mon_n;
    mask_range(ka, ka + SETW);
    want96 = 128'd3 * 128'd65536000000000 + (128'd999_999_800 << 16);
    bfm_set96(48'd3, 30'd999_999_800, 16'd0);
    bfm_wait(100);                           // the wrap lands ~25 cycles in,
    @(posedge clk); kb = mon_n;              // well after the X2c window
    check_set(0, ka+1, ka + SETW, want96, 64'd0, "S1", "set of ts96");
    check_step_once(ka, ka + SETW, "set of ts96");
    // Across the wrap the base must still advance by exactly one increment:
    // the linear value ignores the field split, so a wrap that subtracts
    // anything other than exactly 1e9 ns shows up as an illegal increment.
    check_region(0, ka + SETW + 1, kb-1, P_ALT, D_ALT, R_ALT, 64'sd0, 0, "ts96 across the wrap");
    check_region(1, ka, kb-1, P_ALT, D_ALT, R_ALT, 64'sd0, 0, "ts64 while ts96 was set");
    check_quiet(ka + SETW + 1, kb-1, "across the wrap");
    if (s_sec[kb-1] !== 48'd4)
      note_fail("W1", $sformatf("the seconds field reads %0d after the one-second wrap, expected 4", s_sec[kb-1]));

    // ===================== reset cancels what is still owed (R2) ===========
    @(posedge clk); kc = mon_n;
    bfm_adjust(4'h2, 16'h0000, 16'd400);     // 400 increments still owed...
    bfm_wait(12);
    bfm_reset(5);                            // ...and then reset lands
    @(posedge clk); kr = mon_n;
    mask_range(kc, kr + WARM - 1);
    bfm_wait(WARM + 160);
    @(posedge clk); ka = mon_n;
    if (s_lin[kr + WARM] > 128'd1000 * 128'd419430)
      note_fail("R2", $sformatf("ts96_o reads %0d fns after reset; reset must leave it at zero",
                                s_lin[kr + WARM][63:0]));
    if (s_t64[kr + WARM] > 64'd1000 * 64'd419430)
      note_fail("R2", $sformatf("ts64_o reads %0d fns after reset; reset must leave it at zero",
                                s_t64[kr + WARM]));
    // Back to 6.4 ns, drift 2 fns, rate 5 -- and nothing owed from before.
    check_region(0, kr + WARM, ka-1, P_DEF, D_DEF, R_DEF, 64'sd0, 0, "after reset");
    check_region(1, kr + WARM, ka-1, P_DEF, D_DEF, R_DEF, 64'sd0, 0, "after reset");
    check_quiet(kr + WARM, ka-1, "after reset");

    // ===================== verdict =========================================
    check_global();

    if (err_count == 0) $display("RESULT: PASS");
    else                $display("RESULT: FAIL (%0d violation%s)", err_count, (err_count == 1) ? "" : "s");
    $finish;
  end

endmodule