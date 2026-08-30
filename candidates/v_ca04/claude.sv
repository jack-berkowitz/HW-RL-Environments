// ===========================================================================
// route_xbar_tb.sv -- decides whether a route_xbar obeys the specification.
//
// IDENTITY.  Every beat carries {s, ~s} with s a counter that only increases.
// The delivered value therefore names exactly one accepted beat -- bookkeeping,
// not content matching.  The redundant half is what lets a CORRUPTED payload
// still be attributed: if the top half or the bottom half still names a known
// beat, the payload was modified (R2) rather than invented (R6).  Without it
// those two look identical and the wrong clause gets named.
//
// THE THREE LATITUDES ARE NOT REQUIRED EITHER WAY:
//   L1 latency   -- nothing asserts a beat appears within n cycles of being
//                   accepted; only X3's acceptance bound is timed, and the
//                   spec pins that at 32.
//   L2 rotation  -- A2 is checked as a WINDOW over |S| transfers, never as a
//                   particular first input or rotation, and the first four
//                   transfers of each fairness phase are skipped so a start-up
//                   rotation cannot fail a correct design.
//   L3 comb/reg  -- acceptances are processed BEFORE deliveries at each edge,
//                   so a beat accepted and delivered in the SAME cycle, which
//                   only a combinational design can do, is recognised instead
//                   of being reported as an un-accepted beat.
//
// Nothing here checks order between different inputs, order between outputs,
// or out_data/out_idx while out_valid is low.  in_ready is only ever read in a
// cycle where that input is offering (H3).
// ===========================================================================

`timescale 1ns/1ps

module route_xbar_tb;

  // =========================================================================
  // PROVIDED PLUMBING -- moves beats, checks nothing.
  // =========================================================================
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
  // Model state.  Everything below the fail task is written only by the
  // monitor; the stimulus writes only tgt_sel, fair_watch, quiet_x2, purge_req
  // and the plumbing's own drive signals.
  // =========================================================================
  int  nerr   = 0;
  int  nprint = 0;

  task automatic fail(input string cl, input string msg);
    nerr = nerr + 1;
    if (nprint < 30) begin
      nprint = nprint + 1;
      $display("FAIL [%0s] cycle=%0d time=%0t : %0s", cl, bfm_cycle, $time, msg);
    end
  endtask

  // accepted-beat records, keyed by the beat's unique payload
  int  rec_in  [logic [31:0]];
  int  rec_out [logic [31:0]];
  bit  rec_dlv [logic [31:0]];

  int          pend_out [N_OUT];        // accepted, not yet delivered, per output
  int          n_pending = 0;
  logic [31:0] last_id  [16];           // per (input,output): last delivered id
  int          acc_cnt  [N_IN];
  int          dlv_cnt  [N_OUT];
  int          tot_acc = 0, tot_dlv = 0;
  logic [31:0] seq_ctr = 32'd0;
  int          x3_cnt  [N_IN];

  // A3 needs the previous edge's picture of every output
  logic [N_OUT-1:0] p_valid, p_ready;
  logic [DW-1:0]    p_data [N_OUT];
  logic [IW-1:0]    p_idx  [N_OUT];
  int               a3_witness = 0;     // times the antecedent actually held
  int               rst_low_cnt = 0;

  // stimulus -> monitor
  int  tgt_sel [N_IN];                  // selector each input should use, -1 random
  int  fair_watch = -1;                 // output whose sources are recorded
  bit  quiet_x2 = 1'b0;                 // a delivery now is an owed beat (X2)
  int  purge_req = 0;

  // monitor -> stimulus
  int  fair_seen = -1;
  int  fair_src [$];
  int  purge_ack = 0;

  // =========================================================================
  // MONITOR.  One block, so the order of events inside a cycle is defined:
  // purge, then reset, then ACCEPTANCES, then deliveries, then A3, then X3.
  // Acceptances precede deliveries so that a combinational design delivering
  // in the same cycle it accepts (L3) is understood rather than accused.
  // =========================================================================
  always @(posedge clk) begin
    int k, j, src, dst;
    logic [31:0] d, c1, c2;
    logic [IW-1:0] ix;

    // The fairness recorder is cleared by the monitor when the stimulus moves
    // the watch, so only one process ever writes the queue.
    if (fair_watch != fair_seen) begin
      fair_src.delete();
      fair_seen = fair_watch;
    end

    // ---- purge, requested by the stimulus around a mid-run reset ----------
    if (purge_req != purge_ack) begin
      rec_in.delete(); rec_out.delete(); rec_dlv.delete();
      for (j = 0; j < N_OUT; j++) pend_out[j] = 0;
      for (j = 0; j < 16; j++) last_id[j] = 32'd0;
      n_pending = 0;
      purge_ack = purge_req;
    end

    if (!rst_n) begin
      // X1: while reset is low the crossbar completes nothing.  Checked only
      // from the second edge: before the first edge the design's registers
      // hold no defined value, and the inputs are held quiet by the plumbing.
      rst_low_cnt = rst_low_cnt + 1;
      if (rst_low_cnt >= 2) begin
        for (j = 0; j < N_OUT; j++)
          if (out_valid[j])
            fail("X1", $sformatf("out_valid[%0d] high while rst_ni low with inputs quiet", j));
      end
      for (k = 0; k < N_IN; k++) x3_cnt[k] = 0;
      p_valid = '0;
    end
    else begin
      rst_low_cnt = 0;

      // ---- acceptances (H1) ------------------------------------------------
      for (k = 0; k < N_IN; k++) begin
        if (in_valid[k] && in_ready[k]) begin
          d = in_data[k*DW +: DW];
          if (rec_in.exists(d)) begin
            fail("R4", $sformatf("payload %08h accepted twice -- testbench identity broken", d));
          end else begin
            rec_in[d]  = k;
            rec_out[d] = int'(in_sel[k*SW +: SW]);
            rec_dlv[d] = 1'b0;
            pend_out[rec_out[d]] = pend_out[rec_out[d]] + 1;
            n_pending = n_pending + 1;
          end
          acc_cnt[k] = acc_cnt[k] + 1;
          tot_acc    = tot_acc + 1;
        end
      end

      // ---- deliveries ------------------------------------------------------
      for (j = 0; j < N_OUT; j++) begin
        if (out_valid[j] && out_ready[j]) begin
          d  = bfm_odata(j);
          ix = bfm_oidx(j);
          dlv_cnt[j] = dlv_cnt[j] + 1;
          tot_dlv    = tot_dlv + 1;

          if (!rec_in.exists(d)) begin
            // Either the payload was modified, or the beat was never accepted.
            // The redundant half of the payload tells them apart.
            c1 = {d[31:16], ~d[31:16]};
            c2 = {~d[15:0],  d[15:0]};
            if (rec_in.exists(c1) && !rec_dlv[c1]) begin
              fail("R2", $sformatf("output %0d delivered %08h; the beat accepted on input %0d was %08h",
                                   j, d, rec_in[c1], c1));
              rec_dlv[c1] = 1'b1;
              pend_out[rec_out[c1]] = pend_out[rec_out[c1]] - 1;
              n_pending = n_pending - 1;
            end
            else if (rec_in.exists(c2) && !rec_dlv[c2]) begin
              fail("R2", $sformatf("output %0d delivered %08h; the beat accepted on input %0d was %08h",
                                   j, d, rec_in[c2], c2));
              rec_dlv[c2] = 1'b1;
              pend_out[rec_out[c2]] = pend_out[rec_out[c2]] - 1;
              n_pending = n_pending - 1;
            end
            else if (quiet_x2) begin
              fail("X2", $sformatf("output %0d delivered %08h after reset; the crossbar owed nothing",
                                   j, d));
            end
            else if (pend_out[j] == 0) begin
              fail("R6", $sformatf("output %0d delivered %08h with no beat outstanding for it",
                                   j, d));
            end
            else begin
              fail("R2", $sformatf("output %0d delivered %08h, which was never accepted", j, d));
            end
          end
          else if (rec_dlv[d]) begin
            fail("R4", $sformatf("beat %08h delivered a second time, on output %0d", d, j));
          end
          else begin
            src = rec_in[d];
            dst = rec_out[d];
            rec_dlv[d] = 1'b1;
            pend_out[dst] = pend_out[dst] - 1;
            n_pending = n_pending - 1;

            if (dst != j)
              fail("R1", $sformatf("beat %08h was bound for output %0d but appeared on output %0d",
                                   d, dst, j));
            if (int'(ix) != src)
              fail("R3", $sformatf("output %0d delivered a beat from input %0d but out_idx says %0d",
                                   j, src, int'(ix)));
            if (d < last_id[src*N_OUT + dst])
              fail("R5", $sformatf("beat %08h from input %0d to output %0d delivered after a later beat",
                                   d, src, dst));
            else
              last_id[src*N_OUT + dst] = d;

            if ((fair_watch == j) && (dst == j)) fair_src.push_back(src);
          end
        end
      end

      // ---- A3: an offered beat may not be withdrawn or re-aimed ------------
      for (j = 0; j < N_OUT; j++) begin
        if (p_valid[j] && !p_ready[j]) begin
          a3_witness = a3_witness + 1;
          if (!out_valid[j])
            fail("A3", $sformatf("output %0d withdrew out_valid before out_ready was seen", j));
          else if (bfm_odata(j) !== p_data[j])
            fail("A3", $sformatf("output %0d changed out_data while its beat was unaccepted", j));
          else if (bfm_oidx(j) !== p_idx[j])
            fail("A3", $sformatf("output %0d changed out_idx while its beat was unaccepted", j));
        end
      end

      // ---- X3: accepted within 32 cycles of continuous readiness ----------
      for (k = 0; k < N_IN; k++) begin
        if (in_valid[k] && in_ready[k]) begin
          x3_cnt[k] = 0;
        end
        else if (in_valid[k] && out_ready[int'(in_sel[k*SW +: SW])]) begin
          x3_cnt[k] = x3_cnt[k] + 1;
          if (x3_cnt[k] > 32) begin
            fail("X3", $sformatf("input %0d offered for %0d cycles with its output continuously ready",
                                 k, x3_cnt[k]));
            x3_cnt[k] = 0;
          end
        end
        else begin
          x3_cnt[k] = 0;
        end
      end

      p_valid = out_valid;
      p_ready = out_ready;
      for (j = 0; j < N_OUT; j++) begin
        p_data[j] = bfm_odata(j);
        p_idx[j]  = bfm_oidx(j);
      end
    end

    // Keep the NEXT beat of every input fresh: on acceptance, because the
    // previous one has just been consumed, and whenever nothing is pending,
    // because that is when a change of target must reach the BFM.
    for (k = 0; k < N_IN; k++) begin
      if ((rst_n && in_valid[k] && in_ready[k]) || !in_valid[k]) begin
        seq_ctr = seq_ctr + 32'd1;
        bfm_next_data[k] = {seq_ctr[15:0], ~seq_ctr[15:0]};
        bfm_next_sel[k]  = (tgt_sel[k] >= 0) ? SW'(tgt_sel[k]) : SW'($urandom_range(3));
      end
    end
  end

  // =========================================================================
  // Stimulus
  // =========================================================================
  task automatic set_targets(input int s0, input int s1, input int s2, input int s3);
    tgt_sel[0] = s0; tgt_sel[1] = s1; tgt_sel[2] = s2; tgt_sel[3] = s3;
  endtask

  // Stop offering, open every output, and wait for the design to empty.
  task automatic drain(input int budget);
    int g;
    @(negedge clk);
    bfm_offer = '0;
    out_ready = '1;
    g = 0;
    while ((g < budget) && ((n_pending != 0) || (in_valid != '0))) begin
      @(negedge clk);
      g = g + 1;
    end
    if (in_valid != '0)
      fail("X3", "a beat was still being offered after the drain window: it was never accepted");
    if (n_pending != 0)
      fail("R4", $sformatf("%0d accepted beat(s) never delivered", n_pending));
  endtask

  // A2: every member of S served at least once in every |S| transfers.
  // The window is what is checked -- never which member goes first (L2).
  task automatic run_fairness(input int outp, input logic [3:0] mask,
                              input int ssz, input int nwant);
    int g, b, i, ndist;
    bit present [4];
    set_targets(outp, outp, outp, outp);
    @(negedge clk);
    fair_watch = outp;
    out_ready  = '1;
    bfm_offer  = mask;
    g = 0;
    while ((g < 6000) && (fair_src.size() < nwant)) begin
      @(negedge clk);
      g = g + 1;
    end
    if (fair_src.size() < nwant) begin
      fail("A2", $sformatf("only %0d transfer(s) on output %0d with %0d inputs offering: cannot be fair",
                           fair_src.size(), outp, ssz));
    end
    else begin
      // Skip the first eight transfers: a design's start-up rotation is L2's
      // to choose, and A2 fixes the window rather than the phase.  A design
      // that is actually unfair fails every later window, so skipping costs
      // nothing in detection.
      for (b = 8; (b + ssz) <= fair_src.size(); b = b + 1) begin
        for (i = 0; i < 4; i++) present[i] = 1'b0;
        for (i = 0; i < ssz; i++) present[fair_src[b+i]] = 1'b1;
        ndist = 0;
        for (i = 0; i < 4; i++) if (present[i]) ndist = ndist + 1;
        if (ndist != ssz) begin
          fail("A2", $sformatf("output %0d: %0d consecutive transfers covered only %0d of %0d offering inputs",
                               outp, ssz, ndist, ssz));
          b = fair_src.size();   // one report is enough
        end
      end
    end
    @(negedge clk);
    fair_watch = -1;
    drain(600);
  endtask

  // I1 / I2: one output held shut must not stop the others, and the input
  // bound to it must not stop the other inputs being accepted.
  task automatic run_independence();
    int i, g;
    int a0 [4];
    int d0 [4];
    set_targets(0, 1, 2, 3);
    @(negedge clk);
    bfm_offer = 4'b1111;
    out_ready = 4'b1110;              // output 0 never accepts
    repeat (30) @(negedge clk);
    for (i = 0; i < 4; i++) begin
      a0[i] = acc_cnt[i];
      d0[i] = dlv_cnt[i];
    end
    repeat (300) @(negedge clk);
    for (i = 1; i < 4; i++) begin
      if ((acc_cnt[i] - a0[i]) < 3)
        fail("I2", $sformatf("input %0d accepted %0d times in 300 cycles while output 0 was shut",
                             i, acc_cnt[i] - a0[i]));
      if ((dlv_cnt[i] - d0[i]) < 3)
        fail("I1", $sformatf("output %0d delivered %0d times in 300 cycles while output 0 was shut",
                             i, dlv_cnt[i] - d0[i]));
    end
    drain(1000);
  endtask

  // X1 / X2: fill the design, reset it, and check it neither completes during
  // reset nor owes anything after it.
  task automatic run_reset_test();
    int i;
    set_targets(0, 1, 2, 3);
    @(negedge clk);
    out_ready = '0;                   // nothing can leave: beats pile up inside
    bfm_offer = 4'b1111;
    repeat (40) @(negedge clk);
    @(negedge clk);
    rst_n     = 1'b0;                 // asynchronous, active low
    quiet_x2  = 1'b1;
    purge_req = purge_req + 1;        // the model forgets; the design must too
    repeat (8) @(posedge clk);
    @(negedge clk);
    bfm_offer = '0;                   // inputs quiet, so only the design speaks
    out_ready = '1;
    @(negedge clk);
    rst_n = 1'b1;
    repeat (40) @(negedge clk);
    quiet_x2 = 1'b0;
    if (purge_ack != purge_req)
      fail("X2", "internal: model purge did not complete");
  endtask

  initial begin
    int ph, i;
    logic [3:0] rmask;

    for (i = 0; i < N_IN; i++) begin
      tgt_sel[i] = -1;
      x3_cnt[i]  = 0;
      acc_cnt[i] = 0;
    end
    for (i = 0; i < N_OUT; i++) begin
      pend_out[i] = 0;
      dlv_cnt[i]  = 0;
      p_data[i]   = '0;
      p_idx[i]    = '0;
    end
    for (i = 0; i < 16; i++) last_id[i] = 32'd0;
    p_valid = '0; p_ready = '0;

    bfm_reset(6);

    // ---- quiet after reset: X2 says nothing is owed, R6 says nothing is
    // ---- invented.  Outputs are open, so anything offered is taken and seen.
    @(negedge clk);
    bfm_offer = '0;
    out_ready = '1;
    quiet_x2  = 1'b1;
    repeat (20) @(negedge clk);
    quiet_x2  = 1'b0;

    // ---- phase 1: every input to a random output, every output open -------
    set_targets(-1, -1, -1, -1);
    @(negedge clk);
    bfm_offer = 4'b1111;
    out_ready = '1;
    repeat (400) @(negedge clk);

    // ---- phase 2: same, with the outputs opening and closing at random.
    // ---- This is what makes A3's antecedent happen.
    for (ph = 0; ph < 500; ph++) begin
      @(negedge clk);
      rmask = $urandom_range(15);
      out_ready = rmask;
      repeat ($urandom_range(3) + 1) @(negedge clk);
    end
    drain(2000);

    // ---- phase 3: fairness with all four inputs on one output -------------
    run_fairness(0, 4'b1111, 4, 80);

    // ---- phase 4: fairness with two inputs on one output ------------------
    run_fairness(1, 4'b0101, 2, 60);

    // ---- phase 5: independence --------------------------------------------
    run_independence();

    // ---- phase 6: reset in the middle of a full crossbar ------------------
    run_reset_test();

    // ---- a last stretch of ordinary traffic, to prove it still works ------
    set_targets(-1, -1, -1, -1);
    @(negedge clk);
    bfm_offer = 4'b1111;
    out_ready = '1;
    repeat (200) @(negedge clk);
    drain(2000);

    // ---- verdict -----------------------------------------------------------
    if (tot_acc == 0)
      fail("X3", "the design never accepted a single beat");
    if (tot_dlv == 0)
      fail("R4", "the design never delivered a single beat");
    if (n_pending != 0)
      fail("R4", $sformatf("%0d accepted beat(s) were never delivered", n_pending));

    $display("stats: accepted=%0d delivered=%0d a3_stall_edges=%0d errors=%0d",
             tot_acc, tot_dlv, a3_witness, nerr);
    if (a3_witness == 0)
      $display("note: no cycle ever had an output offering while not ready; A3 was not exercised");

    if (nerr == 0) $display("RESULT: PASS");
    else           $display("RESULT: FAIL");
    $finish;
  end

endmodule