// ===========================================================================
//  route_xbar_tb -- specification-driven testbench for route_xbar
//
//  Checks: H (handshake, as a source obligation), R1..R5, A1..A3, I1, I2,
//          X1..X3.  Deliberately blind to L1 (latency), L2 (starting
//          rotation) and L3 (registered vs combinational outputs).
// ===========================================================================
module route_xbar_tb;

  // -------------------------------------------------------------------------
  // PROVIDED PLUMBING -- moves beats, checks nothing.
  // -------------------------------------------------------------------------

  localparam int N_IN = 4, N_OUT = 4, DW = 32, SW = 2, IW = 2;

  // ---- clock ---------------------------------------------------------------
  logic clk = 1'b0;
  always #5 clk = ~clk;

  int bfm_cycle = 0;
  always @(posedge clk) if (rst_n) bfm_cycle <= bfm_cycle + 1;

  // ---- reset ---------------------------------------------------------------
  logic rst_n = 1'b0;        // ASYNCHRONOUS, ACTIVE LOW

  task automatic bfm_reset(input int cycles = 5);
    @(negedge clk);
    rst_n = 1'b0;
    repeat (cycles) @(posedge clk);
    @(negedge clk);
    rst_n = 1'b1;
  endtask

  // ---- signals and the design under test -----------------------------------
  logic [N_IN*DW-1:0]  in_data;
  logic [N_IN*SW-1:0]  in_sel;
  logic [N_IN-1:0]     in_valid, in_ready;
  logic [N_OUT*DW-1:0] out_data;
  logic [N_OUT*IW-1:0] out_idx;
  logic [N_OUT-1:0]    out_valid, out_ready;

  route_xbar #(.N_IN(N_IN), .N_OUT(N_OUT), .DATA_W(DW), .SEL_W(SW), .IDX_W(IW)) dut (
    .clk_i(clk), .rst_ni(rst_n),
    .in_data_i(in_data), .in_sel_i(in_sel), .in_valid_i(in_valid), .in_ready_o(in_ready),
    .out_data_o(out_data), .out_idx_o(out_idx), .out_valid_o(out_valid),
    .out_ready_i(out_ready));

  // Convenience slicers.
  function automatic logic [DW-1:0] bfm_odata(input int j); return out_data[j*DW +: DW]; endfunction
  function automatic logic [IW-1:0] bfm_oidx (input int j); return out_idx [j*IW +: IW]; endfunction

  // ---- what you drive ------------------------------------------------------
  logic [N_IN-1:0]  bfm_offer;
  logic [DW-1:0]    bfm_next_data [N_IN];
  logic [SW-1:0]    bfm_next_sel  [N_IN];

  logic [N_IN-1:0]  bfm_accepted;
  always @(posedge clk) bfm_accepted <= (rst_n ? (in_valid & in_ready) : '0);

  always @(negedge clk) begin
    if (!rst_n) begin
      in_valid = '0;
    end else begin
      for (int k = 0; k < N_IN; k++) begin
        if (bfm_accepted[k]) in_valid[k] = 1'b0;          // that beat is gone
        if (!in_valid[k] && bfm_offer[k]) begin           // start the next one
          in_data[k*DW +: DW] = bfm_next_data[k];
          in_sel [k*SW +: SW] = bfm_next_sel[k];
          in_valid[k]         = 1'b1;
        end
      end
    end
  end

  task automatic bfm_ready(input logic [N_OUT-1:0] v); out_ready = v; endtask

  // ---- idle everything at time zero ----------------------------------------
  initial begin
    in_data = '0; in_sel = '0; in_valid = '0; out_ready = '1; bfm_offer = '0;
    for (int k = 0; k < N_IN; k++) begin bfm_next_data[k] = '0; bfm_next_sel[k] = '0; end
  end

  // ---- watchdog ------------------------------------------------------------
  initial begin
    #2_000_000;
    $display("RESULT: FAIL (watchdog: no verdict reached)");
    $finish;
  end

  // =========================================================================
  //  CHECKER
  // =========================================================================
  //
  //  Every beat driven carries a payload that no other beat in the whole run
  //  carries (a strictly increasing counter through an odd -- hence bijective
  //  -- multiplier).  That payload is therefore a name for the beat, and the
  //  bookkeeping below is indexed by it: which input took it, which output it
  //  was addressed to, and how many beats of that same (input,output) pair
  //  were taken before it.  Nothing is ever identified by matching content
  //  against content.
  //
  //  Note on A1: the port map gives each output one payload, one index and one
  //  valid, so "at most one input's beat moves on a given output per cycle" is
  //  structural -- there is no way for a design to present two.  What is
  //  checkable, and is checked, is that the one beat presented is a beat that
  //  was really accepted, from the input out_idx_o claims, in order (R1-R5).
  // -------------------------------------------------------------------------

  localparam int NPAIR       = N_IN * N_OUT;
  localparam int MAX_ERR     = 40;
  localparam int STALL_LIMIT = 40;   // X3 says 32; a little slack, so that a
                                     // design is never failed for being merely
                                     // slower than a fixed phase would suggest

  int err_cnt = 0;
  int acc_cnt = 0;
  int del_cnt = 0;

  // ---- per-beat bookkeeping, keyed by the beat's unique payload -------------
  int mt_src [logic [DW-1:0]];   // input it was accepted on
  int mt_dst [logic [DW-1:0]];   // output its selector named
  int mt_seq [logic [DW-1:0]];   // position within its (input,output) pair
  bit mt_got [logic [DW-1:0]];   // already delivered once

  int pair_push [NPAIR];
  int pair_pop  [NPAIR];

  // ---- payload generator ---------------------------------------------------
  int unsigned pay_ctr = 0;

  // ---- stimulus configuration, consumed by the feeder below ----------------
  int            cfg_mode = 0;      // 0 = fixed selector per input, 1 = random
  logic [SW-1:0] cfg_sel [N_IN];

  // ---- windowed statistics -------------------------------------------------
  bit stat_en = 1'b0;
  int acc_per_in  [N_IN];
  int del_per_out [N_OUT];

  // ---- fairness capture ----------------------------------------------------
  bit fair_en = 1'b0;
  int fair_j  = 0;
  int fair_q [$];

  // ---- check enables -------------------------------------------------------
  bit x1_en = 1'b0;   // "no out_valid while reset is low"
  bit x2_en = 1'b0;   // "nothing owed after reset"
  bit sb_en = 1'b1;   // scoreboard live

  // ---- previous-cycle samples, for the A3 stability check ------------------
  bit               p_ok = 1'b0;
  logic [N_OUT-1:0] p_ovalid, p_oready;
  logic [DW-1:0]    p_odata [N_OUT];
  logic [IW-1:0]    p_oidx  [N_OUT];

  // ---- X3 ------------------------------------------------------------------
  int stall_cnt [N_IN];

  // ---- X1 ------------------------------------------------------------------
  int rst_hot = 0;

  // -------------------------------------------------------------------------
  task automatic flag_err(input string cl, input string msg);
    err_cnt = err_cnt + 1;
    if (err_cnt <= MAX_ERR)
      $display("[cycle %0d] VIOLATION of clause %s: %s", bfm_cycle, cl, msg);
    if (err_cnt == MAX_ERR) begin
      $display("(too many violations to be worth listing; stopping here)");
      $display("RESULT: FAIL");
      $finish;
    end
  endtask

  // -------------------------------------------------------------------------
  //  The monitor.  Everything is sampled AT the rising edge, which is the
  //  value the design itself used; nothing here drives a signal the design
  //  samples on this edge (bfm_next_* is only ever read by the driver, at the
  //  falling edge).
  // -------------------------------------------------------------------------
  always @(posedge clk) begin
    automatic logic [N_IN-1:0] acc = '0;
    automatic logic [DW-1:0]   dv  = '0;
    automatic int              sv  = 0;
    automatic int              iv  = 0;
    automatic int              prv = 0;
    automatic int              k   = 0;
    automatic int              j   = 0;
    automatic bit              known = 1'b0;

    if (!rst_n) begin
      // ---- X1 -------------------------------------------------------------
      // Counted, not edge-triggered, so that a single settling cycle at the
      // moment reset is pulled is never mistaken for a design that ignores it.
      if (out_valid !== {N_OUT{1'b0}}) rst_hot = rst_hot + 1;
      else                             rst_hot = 0;
      if (x1_en && (rst_hot == 2))
        flag_err("X1", "out_valid_o stays asserted while rst_ni is low");
      p_ok = 1'b0;
      for (k = 0; k < N_IN; k++) stall_cnt[k] = 0;
    end else begin
      rst_hot = 0;

      // ---- A3: an offered beat may not be withdrawn or re-aimed ------------
      if (p_ok) begin
        for (j = 0; j < N_OUT; j++) begin
          if (p_ovalid[j] && !p_oready[j]) begin
            if (!out_valid[j])
              flag_err("A3", $sformatf(
                "out_valid_o[%0d] was dropped before out_ready_i[%0d] was ever seen", j, j));
            else if (bfm_odata(j) !== p_odata[j])
              flag_err("A3", $sformatf(
                "out_data_o[%0d] changed (%08h -> %08h) while the beat was still being offered",
                j, p_odata[j], bfm_odata(j)));
            else if (bfm_oidx(j) !== p_oidx[j])
              flag_err("A3", $sformatf(
                "out_idx_o[%0d] was re-aimed (%0d -> %0d) while the beat was still being offered",
                j, p_oidx[j], bfm_oidx(j)));
          end
        end
      end

      // ---- X2: after reset the crossbar owes no delivery -------------------
      if (x2_en && (out_valid !== {N_OUT{1'b0}}))
        flag_err("X2", "an output offers a beat although nothing has been accepted since reset");

      // ---- input side: record what was accepted ---------------------------
      acc = in_valid & in_ready;
      for (k = 0; k < N_IN; k++) begin
        if (acc[k] && sb_en) begin
          dv  = in_data[k*DW +: DW];
          sv  = int'(in_sel[k*SW +: SW]);
          prv = k*N_OUT + sv;
          acc_cnt = acc_cnt + 1;
          if (stat_en) acc_per_in[k] = acc_per_in[k] + 1;
          if (mt_src.exists(dv) != 0)
            flag_err("TB", "payload uniqueness broken -- testbench bug, not a design fault");
          mt_src[dv] = k;
          mt_dst[dv] = sv;
          mt_seq[dv] = pair_push[prv];
          mt_got[dv] = 1'b0;
          pair_push[prv] = pair_push[prv] + 1;
        end
      end

      // ---- output side: check what was delivered --------------------------
      for (j = 0; j < N_OUT; j++) begin
        if (out_valid[j] && out_ready[j]) begin
          dv = bfm_odata(j);
          iv = int'(bfm_oidx(j));
          if (stat_en) del_per_out[j] = del_per_out[j] + 1;
          if (fair_en && (j == fair_j)) fair_q.push_back(iv);
          if (sb_en) begin
            del_cnt = del_cnt + 1;
            known = (mt_src.exists(dv) != 0);
            if (!known) begin
              flag_err("R2/R4", $sformatf(
                "output %0d delivered payload %08h, which was never accepted on any input (payload modified in flight, or a beat invented)",
                j, dv));
            end else if (mt_got[dv]) begin
              flag_err("R4", $sformatf(
                "output %0d delivered payload %08h a second time", j, dv));
            end else if (mt_dst[dv] != j) begin
              flag_err("R1", $sformatf(
                "payload %08h was accepted on input %0d with in_sel_i=%0d but was delivered on output %0d",
                dv, mt_src[dv], mt_dst[dv], j));
            end else if (mt_src[dv] != iv) begin
              flag_err("R3", $sformatf(
                "payload %08h was accepted on input %0d but out_idx_o[%0d] names input %0d",
                dv, mt_src[dv], j, iv));
            end else begin
              prv = mt_src[dv]*N_OUT + mt_dst[dv];
              if (mt_seq[dv] != pair_pop[prv])
                flag_err("R5", $sformatf(
                  "input %0d -> output %0d delivered out of order: the beat accepted %0d-th arrived where the %0d-th was due",
                  mt_src[dv], j, mt_seq[dv], pair_pop[prv]));
              mt_got[dv] = 1'b1;
              if (mt_seq[dv] + 1 > pair_pop[prv]) pair_pop[prv] = mt_seq[dv] + 1;
            end
          end
        end
      end

      // ---- X3: a beat whose output is ready must be taken -----------------
      for (k = 0; k < N_IN; k++) begin
        sv = int'(in_sel[k*SW +: SW]);
        if (in_valid[k] && out_ready[sv] && !in_ready[k]) begin
          stall_cnt[k] = stall_cnt[k] + 1;
          if (stall_cnt[k] > STALL_LIMIT) begin
            flag_err("X3", $sformatf(
              "input %0d has been offering a beat bound for output %0d for %0d consecutive cycles with that output continuously ready, and it has not been accepted",
              k, sv, stall_cnt[k]));
            stall_cnt[k] = 0;
          end
        end else begin
          stall_cnt[k] = 0;
        end
      end

      // ---- feed the driver: payload and selector for the NEXT beat --------
      // Updated only where a new beat is about to start, so the offer already
      // in front of the design is never disturbed (H2).
      for (k = 0; k < N_IN; k++) begin
        if (!in_valid[k] || acc[k]) begin
          pay_ctr = pay_ctr + 1;
          bfm_next_data[k] = pay_ctr * 32'h9E37_79B1;
          bfm_next_sel[k]  = (cfg_mode == 1) ? SW'($urandom_range(0, N_OUT-1)) : cfg_sel[k];
        end
      end

      // ---- keep this cycle for the next A3 comparison ---------------------
      p_ovalid = out_valid;
      p_oready = out_ready;
      for (j = 0; j < N_OUT; j++) begin
        p_odata[j] = bfm_odata(j);
        p_oidx[j]  = bfm_oidx(j);
      end
      p_ok = 1'b1;
    end
  end

  // -------------------------------------------------------------------------
  //  A2.  |S| consecutive transfers on the observed output must contain every
  //  member of S.  This is phase-independent, so it says nothing about L2.
  // -------------------------------------------------------------------------
  task automatic check_fairness(input int s_size, input logic [3:0] mask_in);
    int n;
    int bad;
    n   = fair_q.size();
    bad = 0;
    $display("[cycle %0d] A2 window check on output %0d: %0d transfers, contending set %b",
             bfm_cycle, fair_j, n, mask_in);
    if (n < 8) begin
      $display("  (too few transfers observed to judge fairness; not counted against the design)");
      return;
    end
    for (int w = 0; w + s_size <= n; w++) begin
      automatic logic [3:0] seen = 4'b0000;
      for (int t = 0; t < s_size; t++) seen[fair_q[w+t]] = 1'b1;
      if (seen !== mask_in) begin
        bad = bad + 1;
        if (bad <= 3)
          flag_err("A2", $sformatf(
            "output %0d: the %0d consecutive transfers starting at transfer #%0d served inputs %b, not every member of the continuously-offering set %b",
            fair_j, s_size, w, seen, mask_in));
      end
    end
  endtask

  // -------------------------------------------------------------------------
  //  Stimulus helpers
  // -------------------------------------------------------------------------
  task automatic clear_stats();
    for (int k = 0; k < N_IN;  k++) acc_per_in[k]  = 0;
    for (int j = 0; j < N_OUT; j++) del_per_out[j] = 0;
  endtask

  // Set the configuration a full cycle before the offers go up, so the first
  // beat of a phase already carries that phase's selector.
  task automatic start_phase(input logic [N_IN-1:0]  offers,
                             input logic [N_OUT-1:0] rdy,
                             input int s0, input int s1, input int s2, input int s3,
                             input int mode);
    @(negedge clk);
    cfg_mode  = mode;
    cfg_sel[0] = SW'(s0); cfg_sel[1] = SW'(s1);
    cfg_sel[2] = SW'(s2); cfg_sel[3] = SW'(s3);
    bfm_ready(rdy);
    @(posedge clk);
    @(negedge clk);
    bfm_offer = offers;
  endtask

  // Stop starting new beats, open every output, let everything settle.
  task automatic go_idle(input int cycles);
    @(negedge clk);
    bfm_offer = '0;
    bfm_ready('1);
    repeat (cycles) @(posedge clk);
  endtask

  // -------------------------------------------------------------------------
  //  The run
  // -------------------------------------------------------------------------
  initial begin
    int j;
    int k;

    cfg_mode = 0;
    cfg_sel[0] = 2'd0; cfg_sel[1] = 2'd1; cfg_sel[2] = 2'd2; cfg_sel[3] = 2'd3;
    clear_stats();
    for (j = 0; j < NPAIR; j++) begin pair_push[j] = 0; pair_pop[j] = 0; end
    for (k = 0; k < N_IN;  k++) stall_cnt[k] = 0;

    bfm_reset(5);

    // --- X2: nothing was accepted, so nothing may be offered --------------
    x2_en = 1'b1;
    repeat (10) @(posedge clk);
    @(negedge clk);
    x2_en = 1'b0;

    // --- straight-through: every input to its own output ------------------
    start_phase(4'b1111, 4'b1111, 0, 1, 2, 3, 0);
    repeat (60) @(posedge clk);

    // --- permuted: every input to somebody else's output ------------------
    go_idle(30);
    start_phase(4'b1111, 4'b1111, 1, 2, 3, 0, 0);
    repeat (60) @(posedge clk);
    go_idle(30);
    start_phase(4'b1111, 4'b1111, 3, 0, 1, 2, 0);
    repeat (60) @(posedge clk);

    // --- A2 with |S| = 4 : all four inputs onto output 0 ------------------
    go_idle(40);
    start_phase(4'b1111, 4'b1111, 0, 0, 0, 0, 0);
    repeat (40) @(posedge clk);          // let the rotation reach steady state
    @(negedge clk);
    fair_j = 0; fair_q.delete(); fair_en = 1'b1;
    repeat (200) @(posedge clk);
    @(negedge clk);
    fair_en = 1'b0;
    check_fairness(4, 4'b1111);

    // --- A2 with |S| = 2 : inputs 1 and 3 onto output 2 -------------------
    go_idle(40);
    start_phase(4'b1010, 4'b1111, 0, 2, 0, 2, 0);
    repeat (40) @(posedge clk);
    @(negedge clk);
    fair_j = 2; fair_q.delete(); fair_en = 1'b1;
    repeat (120) @(posedge clk);
    @(negedge clk);
    fair_en = 1'b0;
    check_fairness(2, 4'b1010);

    // --- I1 / I2 : output 0 refuses everything for a long while -----------
    go_idle(40);
    start_phase(4'b1111, 4'b1110, 0, 1, 2, 3, 0);
    @(negedge clk);
    clear_stats();
    stat_en = 1'b1;
    repeat (80) @(posedge clk);
    @(negedge clk);
    stat_en = 1'b0;
    for (j = 1; j < N_OUT; j++)
      if (del_per_out[j] < 5)
        flag_err("I1", $sformatf(
          "output 0 was held not-ready for 80 cycles and output %0d managed only %0d transfers in that window: a stalled output is blocking the others",
          j, del_per_out[j]));
    for (k = 1; k < N_IN; k++)
      if (acc_per_in[k] < 5)
        flag_err("I2", $sformatf(
          "input 0 is stalled on a not-ready output and input %0d was accepted only %0d times in 80 cycles: head-of-line blocking across inputs",
          k, acc_per_in[k]));

    // --- A3 : a lone offer on a stalled output, then contention for it ----
    go_idle(40);
    start_phase(4'b0010, 4'b0111, 3, 3, 3, 3, 0);   // only input 1, output 3 shut
    repeat (12) @(posedge clk);
    @(negedge clk);
    bfm_offer = 4'b1111;                            // now everybody wants output 3
    repeat (30) @(posedge clk);
    @(negedge clk);
    bfm_ready('1);
    repeat (40) @(posedge clk);

    // --- random selectors against random backpressure ---------------------
    go_idle(40);
    start_phase(4'b1111, 4'b1111, 0, 1, 2, 3, 1);
    for (j = 0; j < 400; j++) begin
      @(negedge clk);
      if ($urandom_range(0, 3) == 0) bfm_ready(4'($urandom_range(0, 15)));
      @(posedge clk);
    end
    @(negedge clk);
    cfg_mode = 0;

    // --- R4 : drain, and account for every beat ---------------------------
    go_idle(200);
    if (del_cnt != acc_cnt)
      flag_err("R4", $sformatf(
        "%0d beats were accepted but %0d were delivered: %0d beat(s) went missing",
        acc_cnt, del_cnt, acc_cnt - del_cnt));

    // --- X1 / X2 : reset with beats in flight -----------------------------
    // Fill the crossbar with beats it cannot get rid of, then pull reset.
    @(negedge clk);
    sb_en = 1'b0;          // beats from here on are legitimately discarded
    start_phase(4'b1111, 4'b0000, 0, 0, 0, 0, 0);
    repeat (20) @(posedge clk);
    @(negedge clk);
    x1_en     = 1'b1;
    bfm_offer = '0;
    bfm_reset(6);
    @(negedge clk);
    x1_en = 1'b0;
    bfm_ready('1);
    x2_en = 1'b1;
    repeat (20) @(posedge clk);
    @(negedge clk);
    x2_en = 1'b0;

    // --- verdict ----------------------------------------------------------
    if (acc_cnt < 50 || del_cnt < 50)
      flag_err("X3", $sformatf(
        "the crossbar barely moved: %0d beats accepted, %0d delivered over the whole run",
        acc_cnt, del_cnt));

    $display("--- %0d beats accepted, %0d delivered, %0d violations ---",
             acc_cnt, del_cnt, err_cnt);
    if (err_cnt == 0) $display("RESULT: PASS");
    else              $display("RESULT: FAIL");
    $finish;
  end

endmodule