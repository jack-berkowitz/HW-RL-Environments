// ===========================================================================
// route_xbar_tb.sv  --  specification-driven testbench for route_xbar
//
// Strategy
// --------
//   * A per-(input,output) reference FIFO is filled at every input handshake
//     and drained at every output handshake, keyed by out_idx_o.  That single
//     model decides R1 (misroute), R2 (payload), R3 (wrong source index),
//     R4 (loss / duplication) and R5 (per-pair ordering) at once, with no
//     assumption at all about latency (L1) or about whether an output is
//     registered or combinational (L3):  accepts are recorded before
//     deliveries in the same cycle, so a zero-latency design is fine too.
//   * A3 is checked by remembering the previous rising edge: an output that
//     offered while not ready must still offer the same data / idx next edge.
//   * A2 is checked at the output, on the out_idx_o sequence, over windows of
//     |S| consecutive transfers while a known set S is continuously offering.
//     That is rotation-agnostic, so L2 is not constrained.
//   * X3 gives a per-input age counter, restarted whenever the bound output
//     is not ready, so it never fires spuriously; it is what catches a design
//     that accepts nothing, and it backs up the I1/I2 back-pressure phase.
//   * Everything is driven from the falling edge and sampled at the rising
//     edge; the verdict is printed unconditionally at the end.
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
  //                        FROM HERE ON: MY OWN CODE
  // =========================================================================

  // ---- verdict bookkeeping -------------------------------------------------
  int err_count = 0;
  int msg_count = 0;

  task automatic tb_fail(input string clause, input string what);
    err_count = err_count + 1;
    if (msg_count < 40) begin
      msg_count = msg_count + 1;
      $display("VIOLATION [%s] t=%0t cyc=%0d : %s", clause, $time, bfm_cycle, what);
    end
    if (err_count >= 100) begin
      $display("SUMMARY: aborting after %0d violations", err_count);
      $display("RESULT: FAIL");
      $finish;
    end
  endtask

  // ---- reference model: one FIFO per (input,output) pair --------------------
  // Absolute head/tail counters, storage indexed modulo QD.  Only a couple of
  // beats per pair are ever outstanding, so QD is never a constraint.
  localparam int QD = 1024;
  logic [DW-1:0] q_data [N_IN][N_OUT][QD];
  int            q_head [N_IN][N_OUT];
  int            q_tail [N_IN][N_OUT];

  int acc_cnt [N_IN];
  int del_cnt [N_OUT];
  int total_acc = 0;
  int total_del = 0;

  task automatic q_push(input int k, input int j, input logic [DW-1:0] d);
    q_data[k][j][q_tail[k][j] % QD] = d;
    q_tail[k][j] = q_tail[k][j] + 1;
  endtask

  // ---- flags the stimulus raises (always at a falling edge) ----------------
  logic            x1_en    = 1'b0;   // check "quiet while reset is low"
  logic            x2_en    = 1'b0;   // check "owes nothing after reset"
  logic            live_en  = 1'b0;   // check X3
  logic            fair_arm = 1'b0;   // check A2
  int              fair_out = 0;      // output under fairness observation
  logic [N_IN-1:0] fair_mask = '1;    // the set S

  // ---- previous rising-edge sample, for A3 ---------------------------------
  logic [N_OUT-1:0] pv_valid;
  logic [N_OUT-1:0] pv_ready;
  logic [DW-1:0]    pv_data [N_OUT];
  logic [IW-1:0]    pv_idx  [N_OUT];
  logic             pv_have = 1'b0;

  // ---- X3 age counters and A2 history --------------------------------------
  int age [N_IN];
  int fair_run = 0;
  int fair_hist [512];
  int fair_n = 0;

  // =========================================================================
  // THE MONITOR.  Samples at the rising edge, which is the edge the design
  // uses; accepts are folded into the model before deliveries so that a
  // combinational (zero-latency) design is handled correctly.
  // =========================================================================
  always @(posedge clk) begin
    if (!rst_n) begin
      pv_have = 1'b0;
      fair_run = 0;
      for (int k = 0; k < N_IN; k++) begin
        age[k]     = 0;
        acc_cnt[k] = 0;
        for (int j = 0; j < N_OUT; j++) begin
          q_head[k][j] = 0;
          q_tail[k][j] = 0;
        end
      end
      for (int j = 0; j < N_OUT; j++) del_cnt[j] = 0;
      total_acc = 0;
      total_del = 0;
      // X1: with the inputs held quiet there is no combinational path to
      // excuse an asserted output.  (Enabled only after clock edges have
      // occurred, so this never reads the pre-first-edge unknown state.)
      if (x1_en && (out_valid !== {N_OUT{1'b0}}))
        tb_fail("X1", $sformatf("out_valid_o = %b while rst_ni is low and no input is offering", out_valid));
    end else begin

      // ---- X2 : after reset the crossbar holds no beat and owes nothing ----
      if (x2_en && (out_valid !== {N_OUT{1'b0}}))
        tb_fail("X2", $sformatf("out_valid_o = %b just after reset release with nothing ever accepted", out_valid));

      // ---- A3 : an offered beat may not be withdrawn or re-aimed -----------
      if (pv_have) begin
        for (int j = 0; j < N_OUT; j++) begin
          if (pv_valid[j] === 1'b1 && pv_ready[j] !== 1'b1) begin
            if (out_valid[j] !== 1'b1)
              tb_fail("A3", $sformatf("out_valid_o[%0d] was asserted with out_ready_i[%0d] low and has been withdrawn before the handshake", j, j));
            else if (bfm_odata(j) !== pv_data[j])
              tb_fail("A3", $sformatf("output %0d changed its payload while stalled: had %h, now %h", j, pv_data[j], bfm_odata(j)));
            else if (bfm_oidx(j) !== pv_idx[j])
              tb_fail("A3", $sformatf("output %0d was re-aimed while stalled: out_idx_o was %0d, now %0d", j, pv_idx[j], bfm_oidx(j)));
          end
        end
      end

      // ---- input handshakes: record what was accepted ----------------------
      for (int k = 0; k < N_IN; k++) begin
        if (in_valid[k] === 1'b1 && in_ready[k] === 1'b1) begin
          automatic int s = int'(in_sel[k*SW +: SW]);
          q_push(k, s, in_data[k*DW +: DW]);
          acc_cnt[k] = acc_cnt[k] + 1;
          total_acc  = total_acc + 1;
        end
      end

      // ---- output handshakes: check against the model ----------------------
      for (int j = 0; j < N_OUT; j++) begin
        if (out_valid[j] === 1'b1 && out_ready[j] === 1'b1) begin
          automatic logic [DW-1:0] d = bfm_odata(j);
          automatic int            src;
          del_cnt[j] = del_cnt[j] + 1;
          total_del  = total_del + 1;
          if ($isunknown(bfm_oidx(j))) begin
            tb_fail("R3", $sformatf("output %0d completed a beat with out_idx_o = %b", j, bfm_oidx(j)));
          end else begin
            src = int'(bfm_oidx(j));
            if ($isunknown(d))
              tb_fail("R2", $sformatf("output %0d completed a beat with payload %h", j, d));
            if (q_head[src][j] == q_tail[src][j]) begin
              tb_fail("R1/R3/R4", $sformatf("output %0d completed a beat (payload %h) naming input %0d as its source, but no beat accepted from input %0d was bound for output %0d and still owed -- misroute, wrong out_idx_o, or a second delivery of the same beat", j, d, src, src, j));
            end else begin
              automatic logic [DW-1:0] e = q_data[src][j][q_head[src][j] % QD];
              q_head[src][j] = q_head[src][j] + 1;
              if (d !== e)
                tb_fail("R2/R5", $sformatf("output %0d, source input %0d: expected payload %h (the oldest beat still owed for that pair) but got %h -- payload modified, or beats from one input to one output delivered out of order", j, src, e, d));
            end
          end
        end
      end

      // ---- X3 : offered, bound output continuously ready, not accepted -----
      for (int k = 0; k < N_IN; k++) begin
        automatic int s = int'(in_sel[k*SW +: SW]);
        if      (in_valid[k] !== 1'b1)      age[k] = 0;   // not offering
        else if (in_ready[k] === 1'b1)      age[k] = 0;   // taken
        else if (out_ready[s] !== 1'b1)     age[k] = 0;   // bound output not ready: clock restarts
        else begin
          age[k] = age[k] + 1;
          if (live_en && age[k] > 40) begin
            tb_fail("X3", $sformatf("input %0d has offered a beat bound for output %0d for %0d consecutive cycles with that output continuously ready, and has not been accepted", k, s, age[k]));
            age[k] = 0;                                   // re-arm rather than spam
          end
        end
      end

      // ---- A2 : record the source of every transfer on the watched output --
      // while every member of S (and only members of S) is offering to it.
      begin
        automatic bit cond;
        cond = 1'b1;
        for (int k = 0; k < N_IN; k++) begin
          automatic int s = int'(in_sel[k*SW +: SW]);
          if (fair_mask[k]) begin
            if (in_valid[k] !== 1'b1 || s != fair_out) cond = 1'b0;
          end else begin
            if (in_valid[k] === 1'b1 && s == fair_out)  cond = 1'b0;
          end
        end
        if (out_ready[fair_out] !== 1'b1) cond = 1'b0;
        if (fair_arm && cond) fair_run = fair_run + 1;
        else                  fair_run = 0;
        // fair_run >= 20 lets any beat accepted before the set settled drain
        // out first, whatever the pipeline depth (L1).
        if (fair_arm && fair_run >= 20 &&
            out_valid[fair_out] === 1'b1 && out_ready[fair_out] === 1'b1 &&
            !$isunknown(bfm_oidx(fair_out)) && fair_n < 512) begin
          fair_hist[fair_n] = int'(bfm_oidx(fair_out));
          fair_n = fair_n + 1;
        end
      end

      // ---- remember this edge for the A3 check next time -------------------
      pv_valid = out_valid;
      pv_ready = out_ready;
      for (int j = 0; j < N_OUT; j++) begin
        pv_data[j] = bfm_odata(j);
        pv_idx [j] = bfm_oidx(j);
      end
      pv_have = 1'b1;
    end
  end

  // =========================================================================
  // STIMULUS GENERATION
  // The payload of every beat in the whole run is unique, so a mismatch is
  // never ambiguous.  Loaded at the rising edge on which the previous beat
  // was taken, i.e. before the falling edge at which the plumbing picks it
  // up -- never mid-offer, so H2 is respected.
  // =========================================================================
  int unsigned data_ctr = 0;
  logic          sel_rand = 1'b0;
  logic [SW-1:0] sel_fix [N_IN];

  int unsigned rnd_s = 32'h1234_5678;
  function automatic int unsigned rnd_next();
    rnd_s = rnd_s ^ (rnd_s << 13);
    rnd_s = rnd_s ^ (rnd_s >> 17);
    rnd_s = rnd_s ^ (rnd_s << 5);
    return rnd_s;
  endfunction

  task automatic gen_load(input int k);
    automatic int unsigned r;
    data_ctr = data_ctr + 1;
    bfm_next_data[k] = {k[7:0], data_ctr[23:0]};
    if (sel_rand) begin
      r = rnd_next();
      bfm_next_sel[k] = r[SW-1:0];
    end else begin
      bfm_next_sel[k] = sel_fix[k];
    end
  endtask

  always @(posedge clk) begin
    if (!rst_n) begin
      for (int k = 0; k < N_IN; k++) gen_load(k);
    end else begin
      for (int k = 0; k < N_IN; k++)
        if (in_valid[k] === 1'b1 && in_ready[k] === 1'b1) gen_load(k);
    end
  end

  // =========================================================================
  // HELPERS
  // =========================================================================
  task automatic wait_neg(input int n);
    repeat (n) @(negedge clk);
  endtask

  task automatic set_sel(input int k, input int j);
    automatic int jj = j;
    sel_fix[k] = jj[SW-1:0];
  endtask

  function automatic int pcount(input logic [N_IN-1:0] m);
    automatic int c = 0;
    for (int i = 0; i < N_IN; i++) if (m[i]) c = c + 1;
    return c;
  endfunction

  // A2 is "every member of S at least once in every |S| consecutive transfers
  // on output j".  Checked as a sliding window over the recorded out_idx_o
  // sequence, which fixes the window without fixing the phase (L2).
  task automatic fair_check(input int j, input logic [N_IN-1:0] m);
    automatic int w = pcount(m);
    automatic logic [N_IN-1:0] seen;
    automatic int i;
    $display("NOTE: A2 window check on output %0d, S = %b, %0d transfers observed", j, m, fair_n);
    if (fair_n < w) return;                 // nothing conclusive; other checks cover it
    for (i = 0; i + w <= fair_n; i++) begin
      seen = '0;
      for (int q = 0; q < w; q++) seen[fair_hist[i+q][SW-1:0]] = 1'b1;
      if ((seen & m) !== m) begin
        tb_fail("A2", $sformatf("output %0d: across the %0d consecutive transfers starting at transfer #%0d only inputs %b were served, although all of %b were continuously offering beats bound for it", j, w, i, seen, m));
        return;                             // one report is enough
      end
    end
  endtask

  task automatic fair_reset(input int j, input logic [N_IN-1:0] m);
    fair_arm  = 1'b0;
    fair_n    = 0;
    fair_out  = j;
    fair_mask = m;
  endtask

  // =========================================================================
  // THE RUN
  // =========================================================================
  int snap_a [N_IN];
  int snap_d [N_OUT];

  initial begin
    // static setup at time 0 (nothing here is touched by the plumbing)
    for (int k = 0; k < N_IN; k++) begin
      sel_fix[k] = k[SW-1:0];
      snap_a[k]  = 0;
    end
    for (int j = 0; j < N_OUT; j++) snap_d[j] = 0;

    // ---- X1 : quiet while reset is asserted ------------------------------
    // Reset is already low.  Wait for real clock edges first -- before any
    // edge the design's registers hold nothing defined.
    wait_neg(3);
    x1_en = 1'b1;
    wait_neg(6);
    x1_en = 1'b0;

    // ---- release reset ---------------------------------------------------
    bfm_reset(4);
    x2_en   = 1'b1;
    live_en = 1'b1;
    wait_neg(10);          // still no offers: the crossbar must stay silent
    x2_en = 1'b0;

    // ---- phase A : one input per output, everything ready ----------------
    bfm_ready('1);
    sel_rand = 1'b0;
    for (int k = 0; k < N_IN; k++) set_sel(k, k);
    bfm_offer = '1;
    wait_neg(40);

    // ---- phase A' : rotate the mapping, so a "sel is ignored" design and a
    //                 "out_idx is the output number" design both show up ---
    for (int k = 0; k < N_IN; k++) set_sel(k, (k + 1) % N_OUT);
    wait_neg(40);
    for (int k = 0; k < N_IN; k++) set_sel(k, (k + 2) % N_OUT);
    wait_neg(40);
    for (int k = 0; k < N_IN; k++) set_sel(k, (k + 3) % N_OUT);
    wait_neg(40);

    // ---- phase B1 : A2 with S = all four inputs, on output 0 -------------
    fair_reset(0, 4'b1111);
    for (int k = 0; k < N_IN; k++) set_sel(k, 0);
    bfm_ready('1);
    wait_neg(10);
    fair_arm = 1'b1;
    wait_neg(180);
    fair_arm = 1'b0;
    fair_check(0, 4'b1111);

    // ---- phase B2 : A2 with S = {1,3}, on output 3 -----------------------
    // The two-member window is the sharp one: it forbids serving the same
    // input twice running while the other is waiting.
    fair_reset(3, 4'b1010);
    set_sel(0, 0); set_sel(1, 3); set_sel(2, 2); set_sel(3, 3);
    wait_neg(30);
    fair_arm = 1'b1;
    wait_neg(180);
    fair_arm = 1'b0;
    fair_check(3, 4'b1010);
    fair_reset(0, 4'b1111);

    // ---- phase C : one output stops accepting (I1, I2) -------------------
    for (int k = 0; k < N_IN; k++) set_sel(k, k);
    bfm_ready('1);
    wait_neg(20);                       // let the previous phase drain
    bfm_ready(4'b1110);                 // output 0 accepts nothing
    wait_neg(10);
    for (int k = 0; k < N_IN; k++) snap_a[k] = acc_cnt[k];
    for (int j = 0; j < N_OUT; j++) snap_d[j] = del_cnt[j];
    wait_neg(256);
    // X3 alone guarantees at least 8 acceptances per unblocked input in this
    // window, so 4 cannot fail a conforming design however slow it is.
    for (int k = 1; k < N_IN; k++)
      if (acc_cnt[k] - snap_a[k] < 4)
        tb_fail("I2", $sformatf("input %0d (bound for output %0d, which was ready throughout) was accepted only %0d times in 256 cycles while input 0 was stalled on the one output that was not ready -- head-of-line blocking across inputs", k, k, acc_cnt[k]-snap_a[k]));
    for (int j = 1; j < N_OUT; j++)
      if (del_cnt[j] - snap_d[j] < 4)
        tb_fail("I1", $sformatf("output %0d completed only %0d beats in 256 cycles while output 0 was the only one not accepting -- a stalled output is holding up the others", j, del_cnt[j]-snap_d[j]));
    bfm_ready('1);
    wait_neg(60);

    // ---- phase D : stalls with contention (A3) ---------------------------
    set_sel(0, 0); set_sel(1, 0); set_sel(2, 1); set_sel(3, 1);
    wait_neg(20);
    repeat (6) begin
      bfm_ready('1);
      wait_neg(6);
      bfm_ready('0);                    // everything stops accepting
      wait_neg(12);
    end
    bfm_ready('1);
    wait_neg(20);
    set_sel(0, 2); set_sel(1, 2); set_sel(2, 2); set_sel(3, 2);
    wait_neg(10);
    repeat (5) begin
      bfm_ready(4'b1011);               // output 2 alone stalls, under 4-way contention
      wait_neg(14);
      bfm_ready('1);
      wait_neg(6);
    end
    bfm_ready('1);
    wait_neg(40);

    // ---- phase E : random selectors, random back-pressure ----------------
    sel_rand = 1'b1;
    wait_neg(10);
    for (int i = 0; i < 500; i++) begin
      automatic int unsigned r = rnd_next();
      bfm_ready(r[N_OUT-1:0]);
      bfm_offer = r[11:8] | 4'b0011;
      @(negedge clk);
    end
    sel_rand = 1'b0;

    // ---- drain -----------------------------------------------------------
    bfm_offer = '0;
    bfm_ready('1);
    wait_neg(400);

    // ---- R4 : nothing accepted may be left undelivered --------------------
    for (int k = 0; k < N_IN; k++)
      for (int j = 0; j < N_OUT; j++)
        if (q_tail[k][j] != q_head[k][j])
          tb_fail("R4", $sformatf("%0d beat(s) accepted on input %0d bound for output %0d were never delivered (first one still owed: payload %h)", q_tail[k][j]-q_head[k][j], k, j, q_data[k][j][q_head[k][j] % QD]));

    if (out_valid !== {N_OUT{1'b0}})
      tb_fail("R4/A3", $sformatf("out_valid_o = %b after a long drain with every output ready and nothing owed", out_valid));

    if (total_acc == 0)
      tb_fail("X3", "the design never accepted a single beat");

    $display("SUMMARY: accepted=%0d delivered=%0d violations=%0d", total_acc, total_del, err_count);
    if (err_count == 0) $display("RESULT: PASS");
    else                $display("RESULT: FAIL");
    $finish;
  end

endmodule