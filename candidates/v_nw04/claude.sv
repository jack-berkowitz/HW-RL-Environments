// =============================================================================
// ptp_time_base_tb.sv
// -----------------------------------------------------------------------------
// Decides whether a ptp_time_base implementation obeys the specification.
//
// Why there is no cycle-exact reference model
// -------------------------------------------
// L1 leaves the delay from a control valid to its first effect free (up to 4
// cycles) and L2 leaves the relative phase of ts96_o and ts64_o free, along
// with the alignment of adj_active_o against the increments it marks. A model
// that predicted a value per cycle would be predicting things the contract does
// not fix. So instead every check is on the SEQUENCE OF INCREMENTS each base
// takes, measured as the difference between consecutive samples of that base:
//
//   * every increment must be exactly period, or period+drift, or period+adj,
//     or period+adj+drift -- computed in fns, with no tolerance (I1)
//   * the increments carrying the drift must be exactly drift_rate apart (D2)
//   * the increments carrying the offset must be exactly adj_count of them and
//     consecutive (A2)
//
// Each base is analysed ON ITS OWN, so a design that hands ts64 the same
// increment sequence a few cycles after ts96 is indistinguishable from one that
// hands both the same cycle -- which is what L2 requires. The stimulus values
// are chosen so the four possible increments are all distinct, which is what
// makes a measured delta classifiable at all.
//
// Where the contract grants latitude, nothing is sampled
// ------------------------------------------------------
//   L1  Control changes are followed by a long settling wait before any window
//       is recorded; for adj_valid, whose effect must land inside the window,
//       the run of adjusted increments is SEARCHED for rather than expected at
//       a fixed offset.
//   L2  No check ever compares ts96_o against ts64_o, or compares the position
//       of adj_active_o against the position of the adjusted increments. Only
//       the LENGTH of the adj_active_o run is checked (A3), which the contract
//       does fix.
//
// pps_o is checked by counting -- one pulse per wrap, each exactly one cycle
// long -- rather than by requiring it in the same sampled cycle as the wrap,
// since the contract does not pin that alignment either.
//
// Termination: every wait is a bounded loop and the watchdog fires regardless.
// =============================================================================

module ptp_time_base_tb;

// ---------------------------------------------------------------------------
// PROVIDED PLUMBING -- drives the module, checks nothing.
// ---------------------------------------------------------------------------

  // ---- clock ---------------------------------------------------------------
  logic clk = 1'b0;
  always #5 clk = ~clk;

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
// END OF PROVIDED PLUMBING -- everything below is the checker.
// ---------------------------------------------------------------------------

  // ---- pinned constants, all in fns ----------------------------------------
  localparam longint ONE_SEC = 64'd65536000000000;   // 1e9 ns, in fns
  localparam longint P_DEF   = 64'd419430;           // 4'h6 / 16'h6666
  localparam longint D_DEF   = 64'd2;                // 4'h0 / 16'h0002
  localparam int     R_DEF   = 5;
  localparam longint P1      = 64'd528948;           // 4'h8 / 16'h1234
  localparam longint DR_POS  = 64'd7;                // 4'h0 / 16'h0007
  localparam longint DR_NEG  = -64'd7;               // 4'hF / 16'hFFF9
  localparam longint ADJ_POS = 64'd256;              // 4'h0 / 16'h0100
  localparam longint ADJ_NEG = -64'd4096;            // 4'hF / 16'hF000

  int nerr = 0;

  task automatic err(input string cl, input string msg);
    begin
      nerr = nerr + 1;
      if (nerr <= 40) $display("FAIL [%s] cycle %0d: %s", cl, bfm_cycle, msg);
    end
  endtask

  // ---- monitor ---------------------------------------------------------------
  longint      p64, p96;
  logic [47:0] psec;
  bit          have_prev  = 1'b0;
  bit          rec_en     = 1'b0;
  bit          step_eq_en = 1'b1;   // off only while a set is in flight
  bit          jump_en    = 1'b0;   // off only while a set is in flight
  bit          pps_prev   = 1'b0;
  int          pps_cnt    = 0;

  longint d64q [$];
  longint d96q [$];
  bit     aaq  [$];
  bit     stq  [$];
  bit     ppq  [$];
  bit     wrq  [$];

  always @(posedge clk) begin
    longint      c64, c96, dd64, dd96;
    logic [47:0] csec;
    logic [29:0] cns;
    bit          wrapped;

    if (rst) begin
      have_prev = 1'b0;
      pps_prev  = 1'b0;
    end else begin
      csec    = ts96[95:48];
      cns     = ts96[45:16];
      c64     = longint'(ts64);
      c96     = longint'(cns) * 64'd65536 + longint'(ts96[15:0]);
      wrapped = 1'b0;
      dd64    = 64'd0;
      dd96    = 64'd0;

      // W1: the ns field never reaches one second
      if (cns >= 30'd1000000000)
        err("W1", $sformatf("ts96_o ns field is %0d, which has reached 1e9", cns));

      // W3: a pulse is exactly one cycle, wherever it falls
      if (pps && pps_prev)
        err("W3", "pps_o asserted for more than one consecutive cycle");

      if (have_prev) begin
        dd64 = c64 - p64;
        if (c96 >= p96) dd96 = c96 - p96;
        else begin
          wrapped = 1'b1;
          dd96    = c96 + ONE_SEC - p96;
        end
        if (jump_en) begin
          if (wrapped && (csec !== (psec + 48'd1)))
            err("W1", "the seconds field did not increase by exactly one on the wrap");
          if (!wrapped && (csec !== psec))
            err("W1", "the seconds field changed without a one-second wrap");
        end
        // A4: outside a set, ts_step_o marks exactly the adj_active_o cycles
        if (step_eq_en && (ts_step !== adj_active))
          err("A4", $sformatf("ts_step_o=%b but adj_active_o=%b with no set in flight",
                              ts_step, adj_active));
        if (rec_en) begin
          d64q.push_back(dd64);
          d96q.push_back(dd96);
          aaq.push_back(adj_active);
          stq.push_back(ts_step);
          ppq.push_back(pps);
          wrq.push_back(wrapped);
        end
      end

      if (pps) pps_cnt = pps_cnt + 1;
      pps_prev  = pps;
      p64       = c64;
      p96       = c96;
      psec      = csec;
      have_prev = 1'b1;
    end
  end

  // ---- window control --------------------------------------------------------
  task automatic rec_start();
    begin
      @(negedge clk);
      d64q.delete(); d96q.delete(); aaq.delete();
      stq.delete();  ppq.delete();  wrq.delete();
      rec_en = 1'b1;
    end
  endtask

  task automatic rec_stop();
    begin
      @(negedge clk);
      rec_en = 1'b0;
    end
  endtask

  // ---- analysis --------------------------------------------------------------
  // Which of the four legal increments a measured delta is, or -1.
  function automatic int classify(input longint d, input longint pp,
                                  input longint aa, input longint dd);
    begin
      if      (d == pp)           classify = 0;
      else if (d == (pp + dd))    classify = 1;
      else if (d == (pp + aa))    classify = 2;
      else if (d == (pp + aa + dd)) classify = 3;
      else                        classify = -1;
    end
  endfunction

  // Checks one base's increment sequence over the recorded window.
  //   which : 0 = ts64_o, 1 = ts96_o
  //   bad_cl : clause to name when an increment is not legal at all. The
  //            wrap-attribution below only applies to ts96_o, since wrq[] is a
  //            property of that base and says nothing about ts64_o.
  task automatic check_win(input string nm, input int which,
                           input longint pp, input longint aa, input longint dd,
                           input int rate, input int exp_adj, input string bad_cl);
    int     i, n, cls, first_adj, last_adj, nadj, prev_dr, nbad;
    longint d;
    string  bn;
    begin
      bn        = (which == 0) ? "ts64_o" : "ts96_o";
      n         = (which == 0) ? d64q.size() : d96q.size();
      first_adj = -1;
      last_adj  = -1;
      nadj      = 0;
      prev_dr   = -1;
      nbad      = 0;

      for (i = 0; i < n; i = i + 1) begin
        d   = (which == 0) ? d64q[i] : d96q[i];
        cls = classify(d, pp, aa, dd);
        if (cls < 0) begin
          nbad = nbad + 1;
          if (nbad <= 3) begin
            if ((which == 1) && wrq[i])
              err("W1", $sformatf("%s %s: the wrapping increment is %0d fns, not a legal increment (period %0d)",
                                  nm, bn, d, pp));
            else
              err(bad_cl, $sformatf("%s %s: increment %0d of the window is %0d fns; legal are %0d / %0d / %0d / %0d",
                                  nm, bn, i, d, pp, pp+dd, pp+aa, pp+aa+dd));
          end
        end else begin
          if ((cls == 2) || (cls == 3)) begin
            nadj = nadj + 1;
            if (first_adj < 0) first_adj = i;
            last_adj = i;
          end
          if ((cls == 1) || (cls == 3)) begin
            if (prev_dr >= 0) begin
              if ((i - prev_dr) != rate)
                err("D2", $sformatf("%s %s: drift applied %0d increments apart, drift_rate_i is %0d",
                                    nm, bn, i - prev_dr, rate));
            end
            prev_dr = i;
          end
        end
      end

      if (nadj != exp_adj)
        err("A2", $sformatf("%s %s: the offset reached %0d increments, adj_count_i was %0d",
                            nm, bn, nadj, exp_adj));
      else if ((nadj > 0) && ((last_adj - first_adj + 1) != nadj))
        err("A2", $sformatf("%s %s: the %0d adjusted increments are not consecutive (span %0d)",
                            nm, bn, nadj, last_adj - first_adj + 1));
    end
  endtask

  // A3: adj_active_o is exactly exp_count cycles, and they are consecutive.
  task automatic check_adj_active(input string nm, input int exp_count);
    int i, n, runs, cur, mx;
    begin
      n = aaq.size(); runs = 0; cur = 0; mx = 0;
      for (i = 0; i < n; i = i + 1) begin
        if (aaq[i]) begin
          if (cur == 0) runs = runs + 1;
          cur = cur + 1;
          if (cur > mx) mx = cur;
        end else cur = 0;
      end
      if (exp_count == 0) begin
        if (runs != 0)
          err("A3", $sformatf("%s: adj_active_o asserted with no adjustment outstanding", nm));
      end else begin
        if (runs != 1)
          err("A3", $sformatf("%s: adj_active_o formed %0d separate runs, expected one", nm, runs));
        else if (mx != exp_count)
          err("A3", $sformatf("%s: adj_active_o was high for %0d cycles, adj_count_i was %0d",
                              nm, mx, exp_count));
      end
    end
  endtask

  // Counts ts_step_o cycles in the window (used where a set is in flight).
  function automatic int count_step();
    int i;
    begin
      count_step = 0;
      for (i = 0; i < stq.size(); i = i + 1) if (stq[i]) count_step = count_step + 1;
    end
  endfunction

  function automatic int count_wraps();
    int i;
    begin
      count_wraps = 0;
      for (i = 0; i < wrq.size(); i = i + 1) if (wrq[i]) count_wraps = count_wraps + 1;
    end
  endfunction

  function automatic int count_pps();
    int i;
    begin
      count_pps = 0;
      for (i = 0; i < ppq.size(); i = i + 1) if (ppq[i]) count_pps = count_pps + 1;
    end
  endfunction

  // ---- test program ----------------------------------------------------------
  initial begin
    int p0, p1c, nst, nwr, npp, i;

    // ================= defaults out of reset: I2, D2, R2 ====================
    bfm_reset(5);
    bfm_wait(4);
    p0 = pps_cnt;
    rec_start();
    bfm_wait(140);
    rec_stop();
    check_win("defaults", 0, P_DEF, 64'd0, D_DEF, R_DEF, 0, "I1");
    check_win("defaults", 1, P_DEF, 64'd0, D_DEF, R_DEF, 0, "I1");
    check_adj_active("defaults", 0);
    if (pps_cnt != p0)
      err("W3", "pps_o asserted with no one-second wrap anywhere near");

    // ================= a new nominal period: I2 =============================
    bfm_period(4'h8, 16'h1234);
    bfm_wait(40);
    rec_start();
    bfm_wait(140);
    rec_stop();
    check_win("new period", 0, P1, 64'd0, D_DEF, R_DEF, 0, "I1");
    check_win("new period", 1, P1, 64'd0, D_DEF, R_DEF, 0, "I1");

    // ================= a new drift and rate: D1, D2 =========================
    bfm_drift(4'h0, 16'h0007, 16'd7);
    bfm_wait(40);
    rec_start();
    bfm_wait(140);
    rec_stop();
    check_win("drift +7 rate 7", 0, P1, 64'd0, DR_POS, 7, 0, "I1");
    check_win("drift +7 rate 7", 1, P1, 64'd0, DR_POS, 7, 0, "I1");

    // ================= a negative drift: D3 =================================
    bfm_drift(4'hF, 16'hFFF9, 16'd3);
    bfm_wait(40);
    rec_start();
    bfm_wait(140);
    rec_stop();
    check_win("drift -7 rate 3", 0, P1, 64'd0, DR_NEG, 3, 0, "I1");
    check_win("drift -7 rate 3", 1, P1, 64'd0, DR_NEG, 3, 0, "I1");

    // ================= a counted offset, positive: A1..A4 ===================
    rec_start();                       // armed BEFORE the valid, per L1
    bfm_wait(3);
    bfm_adjust(4'h0, 16'h0100, 16'd20);
    bfm_wait(90);
    rec_stop();
    check_win("offset +256 x20", 0, P1, ADJ_POS, DR_NEG, 3, 20, "I1");
    check_win("offset +256 x20", 1, P1, ADJ_POS, DR_NEG, 3, 20, "I1");
    check_adj_active("offset +256 x20", 20);

    // ================= a counted offset, negative: A5 =======================
    rec_start();
    bfm_wait(3);
    bfm_adjust(4'hF, 16'hF000, 16'd12);
    bfm_wait(90);
    rec_stop();
    check_win("offset -4096 x12", 0, P1, ADJ_NEG, DR_NEG, 3, 12, "I1");
    check_win("offset -4096 x12", 1, P1, ADJ_NEG, DR_NEG, 3, 12, "I1");
    check_adj_active("offset -4096 x12", 12);

    // ================= a count of one: the A2/A3 boundary ===================
    rec_start();
    bfm_wait(3);
    bfm_adjust(4'h0, 16'h0100, 16'd1);
    bfm_wait(60);
    rec_stop();
    check_win("offset +256 x1", 0, P1, ADJ_POS, DR_NEG, 3, 1, "I1");
    check_win("offset +256 x1", 1, P1, ADJ_POS, DR_NEG, 3, 1, "I1");
    check_adj_active("offset +256 x1", 1);

    // ================= setting ts96 does not disturb ts64: S1, S3, S4 =======
    // Repeated at every phase of the drift counter (rate is 3 here): a design
    // that quietly re-phases the drift on a set disturbs the spacing on some
    // phases and not others, so one set at one phase would not settle it.
    for (i = 0; i < 3; i = i + 1) begin
      step_eq_en = 1'b0;
      jump_en    = 1'b0;
      rec_start();
      bfm_wait(3 + i);
      bfm_set96(48'd0, 30'd100, 16'd0);
      bfm_wait(50);
      rec_stop();
      check_win("set96", 0, P1, 64'd0, DR_NEG, 3, 0, "S4");   // ts64 must be untouched
      check_adj_active("set96", 0);
      nst = count_step();
      if (nst != 1)
        err("S3", $sformatf("set_ts96_valid_i raised ts_step_o on %0d cycles, expected exactly one", nst));
      if (ts96[95:48] !== 48'd0)
        err("S1", "the seconds field did not take the value written by set_ts96_i");
      if (ts96[45:16] > 30'd2000)
        err("S1", $sformatf("the ns field is %0d, which is not what set_ts96_i wrote", ts96[45:16]));
      bfm_wait(4);
      step_eq_en = 1'b1;
      jump_en    = 1'b1;
      bfm_wait(6);
    end

    // ================= setting ts64 does not disturb ts96: S2, S3, S4 =======
    for (i = 0; i < 3; i = i + 1) begin
      step_eq_en = 1'b0;
      jump_en    = 1'b0;
      rec_start();
      bfm_wait(3 + i);
      bfm_set64(48'd500, 16'd0);
      bfm_wait(50);
      rec_stop();
      check_win("set64", 1, P1, 64'd0, DR_NEG, 3, 0, "S4");   // ts96 must be untouched
      check_adj_active("set64", 0);
      nst = count_step();
      if (nst != 1)
        err("S3", $sformatf("set_ts64_valid_i raised ts_step_o on %0d cycles, expected exactly one", nst));
      if (ts64[63:16] > 48'd3000)
        err("S2", $sformatf("the ts64_o ns field is %0d, which is not what set_ts64_i wrote", ts64[63:16]));
      bfm_wait(4);
      step_eq_en = 1'b1;
      jump_en    = 1'b1;
      bfm_wait(6);
    end

    // ================= the one-second wrap: W1, W2, W3 ======================
    jump_en    = 1'b0;
    step_eq_en = 1'b0;               // two sets in flight: A4's equality is off
    bfm_set96(48'd7, 30'd999_999_000, 16'd0);
    bfm_set64(48'd999_999_000, 16'd0);
    bfm_wait(12);
    jump_en    = 1'b1;
    step_eq_en = 1'b1;
    p1c = pps_cnt;
    rec_start();
    bfm_wait(170);
    rec_stop();
    // the wrapping increment itself must be exactly a legal increment
    check_win("one-second wrap", 1, P1, 64'd0, DR_NEG, 3, 0, "I1");
    nwr = count_wraps();
    npp = count_pps();
    if (nwr != 1)
      err("W1", $sformatf("%0d one-second wraps occurred in the window, expected exactly one", nwr));
    if (npp != nwr)
      err("W3", $sformatf("pps_o pulsed on %0d cycles for %0d wrap(s)", npp, nwr));
    if (ts96[95:48] !== 48'd8)
      err("W1", $sformatf("the seconds field is %0d after one wrap from 7", ts96[95:48]));
    // W2: ts64_o has no seconds field and must sail past one second
    if (ts64[63:16] < 48'd1_000_000_000)
      err("W2", $sformatf("ts64_o ns field is %0d, so it wrapped at one second", ts64[63:16]));

    // ================= reset cancels an outstanding offset: R2 ==============
    bfm_adjust(4'h0, 16'h0100, 16'd400);
    bfm_wait(10);
    bfm_reset(4);
    @(posedge clk);
    if (ts64 > (5 * P_DEF))
      err("R2", $sformatf("ts64_o reads %0d just after reset, expected to restart from zero", ts64));
    if (ts96[95:48] !== 48'd0)
      err("R2", "the seconds field is not zero after reset");
    if (ts96[45:16] > 30'd2000)
      err("R2", "the ns field did not restart from zero after reset");
    bfm_wait(4);
    rec_start();
    bfm_wait(140);
    rec_stop();
    // defaults restored AND nothing left of the 400-count adjustment
    check_win("after reset", 0, P_DEF, ADJ_POS, D_DEF, R_DEF, 0, "I1");
    check_win("after reset", 1, P_DEF, ADJ_POS, D_DEF, R_DEF, 0, "I1");
    check_adj_active("after reset", 0);

    // ---- verdict --------------------------------------------------------------
    if (nerr == 0) $display("RESULT: PASS");
    else           $display("RESULT: FAIL");
    $finish;
  end

endmodule