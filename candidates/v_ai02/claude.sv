// =============================================================================
// stream_realign_tb.sv
// -----------------------------------------------------------------------------
// Decides whether a stream_realign implementation obeys spec/stream_realign_spec.
//
// Checking strategy
// -----------------
// Every check is driven from a MODEL of the contract, not from a picture of any
// particular implementation:
//
//   * Output beats are collected by a monitor at the rising edge, in order, into
//     a queue. Nothing is ever identified by matching on its data value -- the
//     Nth observed beat is compared with the Nth modelled beat. Data repeats
//     across a line, so value matching would mis-attribute.
//
//   * For each line the model computes, from the clause text alone, WHICH beats
//     produce output (R2/R6), WHAT each one carries (R2's join at the rotation),
//     and what the strobe must be (R3). The count is checked separately from
//     the values, because a wrong count and a wrong value are different clauses.
//
//   * R5 is additionally checked at the byte level for the long lines: the
//     line's input bytes are numbered and the output bytes must be exactly
//     those from index 4-R onward. That is a different statement from R2's
//     per-beat formula and catches a retained beat that never updates.
//
// Where the contract grants latitude, nothing is sampled at all
// -----------------------------------------------------------
//   L1  push_ready_o during a line's first beat is never examined. The liveness
//       check (X3) only runs while pop_ready_i is high, which is the only
//       condition X3 itself states, and the pass-through check of
//       push_ready_o is gated on push_valid_i because H3 says the signal
//       carries no meaning otherwise.
//   L2  pop_data_o and pop_strb_o are read ONLY in a cycle where pop_valid_o
//       and pop_ready_i are both high. A design emitting anything at all on an
//       idle bus is invisible to this testbench.
//
// Nothing here requires a particular latency, a particular arbitration between
// the two roles of strb_i, or any behaviour on a beat the contract leaves
// unconstrained (a silently consumed beat's effect on the retained value is
// NOT modelled -- lines that contain one are checked for output COUNT only,
// which is what R2 and R6 actually pin down).
// =============================================================================

module stream_realign_tb;

// ---------------------------------------------------------------------------
// PROVIDED PLUMBING -- moves beats, checks nothing.
// ---------------------------------------------------------------------------

  // ---- clock ---------------------------------------------------------------
  logic clk = 1'b0;
  always #5 clk = ~clk;

  int bfm_cycle = 0;
  always @(posedge clk) if (rst_n) bfm_cycle <= bfm_cycle + 1;

  // ---- reset ---------------------------------------------------------------
  logic rst_n = 1'b0;          // ASYNCHRONOUS, ACTIVE LOW
  logic clr   = 1'b0;          // synchronous, active high

  task automatic bfm_reset(input int cycles = 5);
    @(negedge clk);
    rst_n = 1'b0;
    repeat (cycles) @(posedge clk);
    @(negedge clk);
    rst_n = 1'b1;
  endtask

  task automatic bfm_clear();
    @(negedge clk) clr = 1'b1;
    @(negedge clk) clr = 1'b0;
    repeat (2) @(posedge clk);
  endtask

  // ---- signals and the design under test ------------------------------------
  logic        ra = 1'b0, fst = 1'b0, lst = 1'b0;
  logic [3:0]  strb = 4'hF;
  logic [31:0] pdata = '0;
  logic [3:0]  pstrb = 4'hF;
  logic        pvalid = 1'b0, pready;
  logic [31:0] qdata;
  logic [3:0]  qstrb;
  logic        qvalid;
  logic        qready = 1'b1;

  stream_realign dut (
    .clk_i(clk), .rst_ni(rst_n), .clear_i(clr), .realign_i(ra), .first_i(fst),
    .last_i(lst), .strb_i(strb), .push_data_i(pdata), .push_strb_i(pstrb),
    .push_valid_i(pvalid), .push_ready_o(pready), .pop_data_o(qdata),
    .pop_strb_o(qstrb), .pop_valid_o(qvalid), .pop_ready_i(qready));

  // ---- what you queue --------------------------------------------------------
  typedef struct packed {
    logic [31:0] data;   // push_data_i
    logic [3:0]  dstrb;  // push_strb_i
    logic        first;  // first_i
    logic        last;   // last_i
    logic        realign;// realign_i
    logic [3:0]  lstrb;  // strb_i presented with this beat
  } bfm_beat_t;

  bfm_beat_t bfm_q [$];

  task automatic bfm_send(input logic [31:0] data, input bit first, input bit last,
                          input bit do_realign, input logic [3:0] lstrb,
                          input logic [3:0] dstrb = 4'hF);
    bfm_beat_t b;
    b.data = data; b.dstrb = dstrb; b.first = first; b.last = last;
    b.realign = do_realign; b.lstrb = lstrb;
    bfm_q.push_back(b);
  endtask

  task automatic bfm_ready(input bit v); qready = v; endtask

  // Waits until everything queued has been offered and taken.
  task automatic bfm_idle(input int max_cycles = 400);
    for (int t = 0; t < max_cycles; t++) begin
      @(posedge clk);
      if (bfm_q.size() == 0 && !pvalid) break;
    end
    repeat (6) @(posedge clk);
  endtask

  // ---- the driver ------------------------------------------------------------
  logic bfm_hs;
  always @(posedge clk) bfm_hs <= (rst_n && !clr) ? (pvalid & pready) : 1'b0;

  always @(negedge clk) begin
    if (!rst_n) begin
      pvalid = 1'b0;
    end else begin
      if (bfm_hs && bfm_q.size() > 0) begin void'(bfm_q.pop_front()); pvalid = 1'b0; end
      if (!pvalid && bfm_q.size() > 0) begin
        pdata = bfm_q[0].data;  pstrb = bfm_q[0].dstrb; fst = bfm_q[0].first;
        lst   = bfm_q[0].last;  strb  = bfm_q[0].lstrb; ra  = bfm_q[0].realign;
        pvalid = 1'b1;
      end
    end
  end

  // ---- watchdog --------------------------------------------------------------
  initial begin
    #2_000_000;
    $display("RESULT: FAIL (watchdog: no verdict reached)");
    $finish;
  end

// ---------------------------------------------------------------------------
// END OF PROVIDED PLUMBING -- everything below is the checker.
// ---------------------------------------------------------------------------

  int  nfail = 0;
  int  nchecks = 0;

  task automatic err(input string clause, input string msg);
    begin
      nfail = nfail + 1;
      if (nfail <= 40)
        $display("VIOLATION [%s] cycle %0d: %s", clause, bfm_cycle, msg);
    end
  endtask

  // ---- observation ----------------------------------------------------------
  // Output beats, in order. Recorded ONLY on a completed output handshake, so
  // pop_data_o / pop_strb_o are never read in a cycle L2 leaves free.
  logic [31:0] obs_d [$];
  logic [3:0]  obs_s [$];

  bit chk_pt   = 1'b0;   // enable the pass-through equality checks (P1)
  int live_cnt = 0;

  always @(posedge clk) begin
    if (!rst_n) begin
      // X1: asynchronous active-low reset must hold pop_valid_o deasserted
      if (qvalid === 1'b1)
        err("X1", "pop_valid_o asserted while rst_ni is low");
      live_cnt <= 0;
    end else if (!clr) begin
      if (qvalid === 1'b1 && qready === 1'b1) begin
        obs_d.push_back(qdata);
        obs_s.push_back(qstrb);
      end

      // X3: with pop_ready_i high a beat must be accepted within 16 cycles
      if (pvalid === 1'b1 && qready === 1'b1) begin
        if (pready === 1'b1) live_cnt <= 0;
        else begin
          live_cnt <= live_cnt + 1;
          if (live_cnt > 16)
            err("X3", "input beat not accepted within 16 cycles with pop_ready_i held high");
        end
      end else live_cnt <= 0;

      // P1: with realign_i low the unit is transparent and the two handshakes
      // are one handshake. push_ready_o is only meaningful when a beat is
      // offered (H3), so it is only compared then.
      if (chk_pt && ra === 1'b0) begin
        if (qvalid !== pvalid)
          err("P1", $sformatf("pass-through: pop_valid_o=%b but push_valid_i=%b", qvalid, pvalid));
        if (pvalid === 1'b1) begin
          if (pready !== qready)
            err("P1", $sformatf("pass-through: push_ready_o=%b but pop_ready_i=%b", pready, qready));
          if (qvalid === 1'b1 && qready === 1'b1) begin
            if (qdata !== pdata)
              err("P1", $sformatf("pass-through: pop_data_o=%08h but push_data_i=%08h", qdata, pdata));
            if (qstrb !== pstrb)
              err("P1", $sformatf("pass-through: pop_strb_o=%b but push_strb_i=%b", qstrb, pstrb));
          end
        end
      end
    end
  end

  // ---- line under construction ----------------------------------------------
  logic [31:0] tl_d [$];   // push_data_i per beat
  logic [3:0]  tl_s [$];   // strb_i      per beat
  logic [3:0]  tl_p [$];   // push_strb_i per beat
  bit          tl_l [$];   // last_i      per beat
  logic [31:0] exp_d [$];  // modelled output beats

  task automatic tl_new();
    begin
      tl_d.delete(); tl_s.delete(); tl_p.delete(); tl_l.delete();
    end
  endtask

  task automatic tl_add(input logic [31:0] d, input logic [3:0] s,
                        input logic [3:0] p, input bit is_last);
    begin
      tl_d.push_back(d); tl_s.push_back(s); tl_p.push_back(p); tl_l.push_back(is_last);
    end
  endtask

  task automatic set_ready(input bit v);
    begin
      @(negedge clk);
      qready = v;
    end
  endtask

  // Run a realign line and check it.
  //   chk_val : compare output VALUES. Left off for lines containing a beat the
  //             contract lets the design silently consume, since the effect of
  //             such a beat on the retained value is not specified -- only the
  //             output COUNT is pinned down there, by R2 and R6.
  //   cnt_cl  : which clause a wrong output count indicts for this line.
  //   bp      : exercise the line under output backpressure.
  task automatic tl_run(input string nm, input bit chk_val,
                        input string cnt_cl, input bit bp);
    int i, j, n, r, nb;
    logic [31:0] ret, t1, t2, e;
    logic [7:0] ib [$];
    logic [7:0] ob [$];
    begin
      n = tl_d.size();
      r = $countones(tl_s[0]);       // rotation = SET BITS, not modulo 4 (R4)

      // ---- model the expected output beats -------------------------------
      exp_d.delete();
      ret = tl_d[0];                 // R1: first beat is consumed and retained
      for (i = 1; i < n; i++) begin
        if (tl_l[i] || (tl_s[i] != 4'h0)) begin      // R2 / R6
          t1 = tl_d[i] << (8*r);                     // shift >= 32 yields zero
          t2 = ret     >> (8*(4-r));
          e  = t1 | t2;
          exp_d.push_back(e);
        end
        ret = tl_d[i];
      end

      // ---- drive ----------------------------------------------------------
      obs_d.delete(); obs_s.delete();
      for (i = 0; i < n; i++)
        bfm_send(tl_d[i], (i == 0), tl_l[i], 1'b1, tl_s[i], tl_p[i]);

      if (bp) begin
        for (i = 0; i < 140; i++) begin
          @(negedge clk);
          qready = ((i % 3) != 0);
        end
        @(negedge clk); qready = 1'b1;
      end
      bfm_idle(600);
      repeat (25) @(posedge clk);

      // ---- check ----------------------------------------------------------
      nchecks = nchecks + 1;
      if (obs_d.size() != exp_d.size()) begin
        // one output per input beat means the line's first beat produced one
        if (obs_d.size() == n && exp_d.size() == n-1)
          err("R1", $sformatf("%s: %0d input beats produced %0d output beats -- the line's first beat must produce none",
                              nm, n, obs_d.size()));
        else
          err(cnt_cl, $sformatf("%s: expected %0d output beat(s), observed %0d",
                                nm, exp_d.size(), obs_d.size()));
      end

      for (i = 0; i < obs_d.size(); i++) begin
        if (obs_s[i] !== 4'hF)
          err("R3", $sformatf("%s: output beat %0d has pop_strb_o=%b, must be all ones while realigning",
                              nm, i, obs_s[i]));
        if (chk_val && i < exp_d.size()) begin
          if (obs_d[i] !== exp_d[i])
            err("R2", $sformatf("%s: output beat %0d is %08h, contract gives %08h (R=%0d)",
                                nm, i, obs_d[i], exp_d[i], r));
        end
      end

      // ---- R5: byte stream, independently of R2's per-beat formula --------
      if (chk_val && obs_d.size() == exp_d.size() && exp_d.size() == n-1) begin
        for (i = 0; i < n; i++)
          for (j = 0; j < 4; j++) ib.push_back(tl_d[i][j*8 +: 8]);
        for (i = 0; i < obs_d.size(); i++)
          for (j = 0; j < 4; j++) ob.push_back(obs_d[i][j*8 +: 8]);
        nb = ob.size();
        for (i = 0; i < nb; i++) begin
          if ((4-r+i) < ib.size()) begin
            if (ob[i] !== ib[4-r+i])
              err("R5", $sformatf("%s: output byte %0d is %02h, line input byte %0d is %02h (R=%0d, stream must start at byte %0d)",
                                  nm, i, ob[i], 4-r+i, ib[4-r+i], r, 4-r));
          end
        end
      end
    end
  endtask

  // ---- pass-through -----------------------------------------------------------
  task automatic run_passthrough(input string nm, input bit bp);
    int i;
    logic [31:0] d [$];
    logic [3:0]  s [$];
    begin
      d.push_back(32'h0123_4567); s.push_back(4'hF);
      d.push_back(32'h89AB_CDEF); s.push_back(4'b0011);
      d.push_back(32'hFFFF_FFFF); s.push_back(4'b1000);
      d.push_back(32'h0000_0000); s.push_back(4'b0000);
      d.push_back(32'hA5A5_5A5A); s.push_back(4'b1010);
      d.push_back(32'hDEAD_BEEF); s.push_back(4'hF);

      obs_d.delete(); obs_s.delete();
      chk_pt = 1'b1;
      for (i = 0; i < d.size(); i++)
        bfm_send(d[i], 1'b0, (i == d.size()-1), 1'b0, 4'hF, s[i]);

      if (bp) begin
        for (i = 0; i < 90; i++) begin
          @(negedge clk);
          qready = ((i % 4) != 0);
        end
        @(negedge clk); qready = 1'b1;
      end
      bfm_idle(600);
      repeat (15) @(posedge clk);
      chk_pt = 1'b0;

      nchecks = nchecks + 1;
      if (obs_d.size() != d.size())
        err("P1", $sformatf("%s: offered %0d beats in pass-through, %0d appeared on the output",
                            nm, d.size(), obs_d.size()));
      for (i = 0; i < obs_d.size() && i < d.size(); i++) begin
        if (obs_d[i] !== d[i])
          err("P1", $sformatf("%s: beat %0d appeared as %08h, push_data_i was %08h", nm, i, obs_d[i], d[i]));
        if (obs_s[i] !== s[i])
          err("P1", $sformatf("%s: beat %0d strobe appeared as %b, push_strb_i was %b", nm, i, obs_s[i], s[i]));
      end
    end
  endtask

  // ---- stimulus ---------------------------------------------------------------
  initial begin
    int i;
    logic [31:0] base;

    qready = 1'b1;
    bfm_reset(5);
    repeat (4) @(posedge clk);

    // -------- P: pass-through, with and without backpressure ---------------
    run_passthrough("passthrough", 1'b0);
    run_passthrough("passthrough+bp", 1'b1);

    // -------- R: rotation 4 (a full strobe is 4, NOT 0) --------------------
    // strb_i on later beats is varied and non-zero: it must gate output (R2)
    // without disturbing the rotation fixed at the first beat (R4).
    tl_new();
    tl_add(32'h1122_3344, 4'hF,    4'b0101, 1'b0);
    tl_add(32'h5566_7788, 4'b0001, 4'b0011, 1'b0);
    tl_add(32'h99AA_BBCC, 4'hF,    4'b1000, 1'b0);
    tl_add(32'hDDEE_FF00, 4'b0110, 4'b0001, 1'b0);
    tl_add(32'h1357_9BDF, 4'b1111, 4'b0100, 1'b1);
    tl_run("R=4 (full strobe)", 1'b1, "R2", 1'b0);

    // -------- R: rotation 0 (empty strobe: output is the current beat) -----
    tl_new();
    tl_add(32'hAAAA_0001, 4'h0,    4'b0101, 1'b0);
    tl_add(32'hBBBB_0002, 4'b1111, 4'b0011, 1'b0);
    tl_add(32'hCCCC_0003, 4'b0010, 4'b1000, 1'b0);
    tl_add(32'hDDDD_0004, 4'b1100, 4'b0001, 1'b0);
    tl_add(32'hEEEE_0005, 4'b0001, 4'b0100, 1'b1);
    tl_run("R=0 (empty strobe)", 1'b1, "R2", 1'b0);

    // -------- R: rotation 1, 2, 3 ------------------------------------------
    tl_new();
    tl_add(32'h0403_0201, 4'b0100, 4'b0101, 1'b0);   // R = 1
    tl_add(32'h0807_0605, 4'b1111, 4'b0011, 1'b0);
    tl_add(32'h0C0B_0A09, 4'b0011, 4'b1000, 1'b0);
    tl_add(32'h100F_0E0D, 4'b1000, 4'b0001, 1'b0);
    tl_add(32'h1413_1211, 4'b0111, 4'b0100, 1'b1);
    tl_run("R=1", 1'b1, "R2", 1'b0);

    tl_new();
    tl_add(32'h2423_2221, 4'b1010, 4'b0101, 1'b0);   // R = 2
    tl_add(32'h2827_2625, 4'b1111, 4'b0011, 1'b0);
    tl_add(32'h2C2B_2A29, 4'b0001, 4'b1000, 1'b0);
    tl_add(32'h302F_2E2D, 4'b1110, 4'b0001, 1'b0);
    tl_add(32'h3433_3231, 4'b0100, 4'b0100, 1'b0);
    tl_add(32'h3837_3635, 4'b1111, 4'b0010, 1'b1);
    tl_run("R=2 (strobe 1010)", 1'b1, "R2", 1'b0);

    // same popcount, different bit pattern -- R is the COUNT of set bits
    tl_new();
    tl_add(32'h4443_4241, 4'b0011, 4'b0101, 1'b0);   // R = 2 as well
    tl_add(32'h4847_4645, 4'b1000, 4'b0011, 1'b0);
    tl_add(32'h4C4B_4A49, 4'b0111, 4'b1000, 1'b0);
    tl_add(32'h504F_4E4D, 4'b1111, 4'b0010, 1'b1);
    tl_run("R=2 (strobe 0011)", 1'b1, "R2", 1'b0);

    tl_new();
    tl_add(32'h6463_6261, 4'b1101, 4'b0101, 1'b0);   // R = 3
    tl_add(32'h6867_6665, 4'b1111, 4'b0011, 1'b0);
    tl_add(32'h6C6B_6A69, 4'b0100, 4'b1000, 1'b0);
    tl_add(32'h706F_6E6D, 4'b0011, 4'b0001, 1'b0);
    tl_add(32'h7473_7271, 4'b1110, 4'b0100, 1'b0);
    tl_add(32'h7877_7675, 4'b0001, 4'b0010, 1'b1);
    tl_run("R=3", 1'b1, "R2", 1'b0);

    // -------- R1: the first beat of a line produces no output --------------
    tl_new();
    tl_add(32'h8182_8384, 4'b0110, 4'b0101, 1'b0);   // R = 2
    tl_add(32'h8586_8788, 4'b1111, 4'b0011, 1'b1);
    tl_run("two-beat line", 1'b1, "R1", 1'b0);

    // -------- R2 / R6: the strobe gates output on every beat ---------------
    // beat 1 has an empty strobe and is not last  -> no output
    // beat 2 has an empty strobe and IS last      -> output anyway (R6)
    // Values are not checked: a silently consumed beat's effect on the
    // retained value is not something the contract states.
    tl_new();
    tl_add(32'h9192_9394, 4'b0011, 4'b0101, 1'b0);
    tl_add(32'h9596_9798, 4'b0000, 4'b0011, 1'b0);
    tl_add(32'h999A_9B9C, 4'b0000, 4'b1000, 1'b1);
    tl_run("empty strobe mid-line, empty strobe on last", 1'b0, "R2", 1'b0);

    tl_new();
    tl_add(32'hA1A2_A3A4, 4'b1110, 4'b0101, 1'b0);
    tl_add(32'hA5A6_A7A8, 4'b0000, 4'b0011, 1'b0);
    tl_add(32'hA9AA_ABAC, 4'b1111, 4'b1000, 1'b0);
    tl_add(32'hADAE_AFB0, 4'b0000, 4'b0001, 1'b1);
    tl_run("two gated beats, one of them last", 1'b0, "R6", 1'b0);

    // -------- backpressure over a realigned line ---------------------------
    tl_new();
    tl_add(32'hC1C2_C3C4, 4'b1011, 4'b0101, 1'b0);   // R = 3
    tl_add(32'hC5C6_C7C8, 4'b1111, 4'b0011, 1'b0);
    tl_add(32'hC9CA_CBCC, 4'b0110, 4'b1000, 1'b0);
    tl_add(32'hCDCE_CFD0, 4'b0001, 4'b0001, 1'b0);
    tl_add(32'hD1D2_D3D4, 4'b1100, 4'b0100, 1'b0);
    tl_add(32'hD5D6_D7D8, 4'b1111, 4'b0010, 1'b1);
    tl_run("R=3 under backpressure", 1'b1, "R2", 1'b1);

    // -------- X2: clear returns the unit to its starting condition ---------
    // A line is started and abandoned part way; after clear a complete line
    // must come out exactly as if nothing had preceded it.
    bfm_send(32'hDEAD_0001, 1'b1, 1'b0, 1'b1, 4'b1111, 4'b0101);
    bfm_send(32'hDEAD_0002, 1'b0, 1'b0, 1'b1, 4'b1111, 4'b0011);
    bfm_idle(400);
    obs_d.delete(); obs_s.delete();
    bfm_clear();
    repeat (4) @(posedge clk);
    if (obs_d.size() != 0)
      err("X2", $sformatf("clear_i produced %0d spurious output beat(s)", obs_d.size()));

    tl_new();
    tl_add(32'hE1E2_E3E4, 4'b0010, 4'b0101, 1'b0);   // R = 1
    tl_add(32'hE5E6_E7E8, 4'b1111, 4'b0011, 1'b0);
    tl_add(32'hE9EA_EBEC, 4'b1001, 4'b1000, 1'b0);
    tl_add(32'hEDEE_EFF0, 4'b1111, 4'b0010, 1'b1);
    tl_run("line after clear_i", 1'b1, "X2", 1'b0);

    // -------- X1: reset asserted with an output pending --------------------
    set_ready(1'b0);
    bfm_send(32'hF1F2_F3F4, 1'b1, 1'b0, 1'b1, 4'b1111, 4'b0101);
    bfm_send(32'hF5F6_F7F8, 1'b0, 1'b0, 1'b1, 4'b1111, 4'b0011);
    repeat (30) @(posedge clk);
    bfm_q.delete();
    @(negedge clk);
    rst_n = 1'b0;                      // asynchronous, mid-cycle
    repeat (4) @(posedge clk);         // monitor checks pop_valid_o each edge
    set_ready(1'b1);
    bfm_reset(5);
    repeat (4) @(posedge clk);

    // -------- one more good line after reset, to prove it still works ------
    obs_d.delete(); obs_s.delete();
    tl_new();
    tl_add(32'h1020_3040, 4'b0111, 4'b0101, 1'b0);   // R = 3
    tl_add(32'h5060_7080, 4'b1111, 4'b0011, 1'b0);
    tl_add(32'h90A0_B0C0, 4'b1010, 4'b1000, 1'b1);
    tl_run("line after reset", 1'b1, "R2", 1'b0);

    // -------- verdict -------------------------------------------------------
    if (obs_d.size() == 0 && nfail == 0)
      err("X3", "no output beat was ever observed from any line");

    $display("checks run: %0d, violations: %0d", nchecks, nfail);
    if (nfail == 0) $display("RESULT: PASS");
    else            $display("RESULT: FAIL");
    $finish;
  end

endmodule