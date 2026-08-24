// ===========================================================================
//  route_xbar_tb.sv
//
//  Self-checking testbench for route_xbar.
//
//  Method
//  ------
//  Every beat carries a globally unique payload, so a delivery can be traced
//  back to the exact acceptance that produced it by BOOKKEEPING rather than by
//  matching on content.  Three maps hold, per payload, the input it was
//  accepted from, the output its selector named, and whether it has been
//  delivered; a queue per (input, output) pair holds acceptance order.  Every
//  delivery is checked against all four.
//
//  What is deliberately NOT checked
//  --------------------------------
//  L1  latency: nothing anywhere requires a beat to appear in any particular
//      cycle, only that it appears.
//  L2  starting rotation: the fairness test looks only at windows of |S|
//      consecutive transfers, which is phase-free -- it accepts any rotation.
//  L3  registered or combinational outputs: every check samples at the rising
//      edge and compares against the previous rising edge, so a zero-latency
//      design and a pipelined one are judged the same way.
//
//  The one thing this testbench must get right about itself is H2: an offer,
//  once made, is held unchanged until it is taken.  The provided driver does
//  that; the payload for the NEXT beat is armed only in the cycle the current
//  one is accepted.
// ===========================================================================
`timescale 1ns/1ps

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

  // -------------------------------------------------------------------------
  // END OF PROVIDED PLUMBING -- everything below is the testbench proper.
  // -------------------------------------------------------------------------

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

  // ---- scoreboard ----------------------------------------------------------
  // Keyed by payload, which is unique for the whole run.
  int src_of [int];                 // input the beat was accepted from
  int dst_of [int];                 // output its selector named
  int dlv_of [int];                 // 1 once delivered
  logic [DW-1:0] ord_q [16][$];     // acceptance order, per (input, output)

  int n_acc = 0, n_dlv = 0;
  int seq_ctr = 0;

  // ---- previous-edge snapshot, for A3 --------------------------------------
  logic [N_OUT-1:0] pv, pr;
  logic [DW-1:0]    pd [N_OUT];
  logic [IW-1:0]    pi [N_OUT];
  int   n_edge = 0;

  // ---- control flags, all driven from the stimulus at a rising edge --------
  int sb_on    = 1;                 // scoreboard active
  int x3_on    = 0;                 // liveness bound applies (all outputs ready)
  int fair_on  = 0;                 // record the transfer order on fair_out
  int fair_out = 0;
  int sel_mode [N_IN];              // -1 random, else a fixed output
  int age [N_IN];                   // cycles this input has been offering unserved
  int idx_seq [$];                  // recorded source indices, for A2

  task automatic arm(input int k);
    seq_ctr = seq_ctr + 1;
    bfm_next_data[k] = {8'(k), 24'(seq_ctr)};
    bfm_next_sel[k]  = (sel_mode[k] < 0) ? 2'($urandom_range(0, 3)) : 2'(sel_mode[k]);
  endtask

  // ---- the checker ---------------------------------------------------------
  always @(posedge clk) begin : chk_blk
    int k, j, s, key, sd, dd, i, found;
    logic [DW-1:0] d;

    if (!rst_n) begin
      // X1: with the inputs held quiet the design must originate nothing.
      // Skipped at the very first edge, where its registers are still unknown.
      if (n_edge >= 1 && (out_valid !== {N_OUT{1'b0}}))
        note_fail("X1", $sformatf("out_valid_o is %b while rst_ni is low", out_valid));
      for (k = 0; k < N_IN; k++) age[k] = 0;
    end else begin
      // ---- A3: an offered beat may not be withdrawn or re-aimed ------------
      if (n_edge >= 1) begin
        for (j = 0; j < N_OUT; j++) begin
          if (pv[j] === 1'b1 && pr[j] === 1'b0) begin
            if (out_valid[j] !== 1'b1)
              note_fail("A3", $sformatf("output %0d withdrew a beat it had offered (out_valid fell before out_ready)", j));
            else if (bfm_odata(j) !== pd[j])
              note_fail("A3", $sformatf("output %0d changed out_data_o under a held valid (%0h -> %0h)", j, pd[j], bfm_odata(j)));
            else if (bfm_oidx(j) !== pi[j])
              note_fail("A3", $sformatf("output %0d re-aimed a held beat: out_idx_o went %0d -> %0d", j, pi[j], bfm_oidx(j)));
          end
        end
      end

      // ---- acceptances ------------------------------------------------------
      for (k = 0; k < N_IN; k++) begin
        if (in_valid[k] === 1'b1 && in_ready[k] === 1'b1) begin
          d   = in_data[k*DW +: DW];
          j   = int'(in_sel[k*SW +: SW]);
          key = int'(d);
          if (sb_on != 0) begin
            if (src_of.exists(key) != 0)
              note_fail("TB", $sformatf("payload %0h reused; the testbench must keep them unique", d));
            src_of[key] = k;
            dst_of[key] = j;
            dlv_of[key] = 0;
            ord_q[k*N_OUT + j].push_back(d);
            n_acc = n_acc + 1;
          end
          arm(k);                      // payload for this input's NEXT beat
          age[k] = 0;
        end else if (in_valid[k] === 1'b1) begin
          age[k] = age[k] + 1;
          if ((x3_on != 0) && (age[k] > 32))
            note_fail("X3", $sformatf("input %0d has been offering for %0d cycles with its output continuously ready; the bound is 32",
                                      k, age[k]));
        end else begin
          age[k] = 0;
        end
      end

      // ---- deliveries -------------------------------------------------------
      for (j = 0; j < N_OUT; j++) begin
        if (out_valid[j] === 1'b1 && out_ready[j] === 1'b1) begin
          d   = bfm_odata(j);
          s   = int'(bfm_oidx(j));
          key = int'(d);
          if ((fair_on != 0) && (j == fair_out)) idx_seq.push_back(s);
          if (sb_on != 0) begin
            if (src_of.exists(key) == 0) begin
              note_fail("R2/R4", $sformatf("output %0d delivered payload %0h, which was never accepted on any input (payload modified, or a beat invented)",
                                           j, d));
            end else begin
              sd = src_of[key];
              dd = dst_of[key];
              if (dd != j)
                note_fail("R1", $sformatf("payload %0h was accepted on input %0d with selector %0d but arrived on output %0d",
                                          d, sd, dd, j));
              if (sd != s)
                note_fail("R3", $sformatf("output %0d delivered payload %0h with out_idx_o=%0d; it was accepted on input %0d",
                                          j, d, s, sd));
              if (dlv_of[key] != 0) begin
                note_fail("R4", $sformatf("payload %0h delivered a second time on output %0d", d, j));
              end else begin
                dlv_of[key] = 1;
                n_dlv = n_dlv + 1;
                // R5: order within one (input, output) pair
                if (ord_q[sd*N_OUT + dd].size() == 0) begin
                  note_fail("R4", $sformatf("payload %0h delivered with nothing outstanding for that pair", d));
                end else if (ord_q[sd*N_OUT + dd][0] !== d) begin
                  note_fail("R5/R4", $sformatf("input %0d -> output %0d delivered %0h while %0h, accepted earlier, had not been delivered (reordered, or the earlier beat was lost)",
                                            sd, dd, d, ord_q[sd*N_OUT + dd][0]));
                  found = -1;                    // drop it anyway, so one swap
                  for (i = 0; i < ord_q[sd*N_OUT + dd].size(); i++)   // does not
                    if (ord_q[sd*N_OUT + dd][i] === d && found < 0) found = i;  // cascade
                  if (found >= 0) ord_q[sd*N_OUT + dd].delete(found);
                end else begin
                  void'(ord_q[sd*N_OUT + dd].pop_front());
                end
              end
            end
          end
        end
      end
    end

    // ---- snapshot for the next edge ---------------------------------------
    pv <= out_valid;
    pr <= out_ready;
    for (j = 0; j < N_OUT; j++) begin
      pd[j] <= bfm_odata(j);
      pi[j] <= bfm_oidx(j);
    end
    n_edge <= n_edge + 1;
  end

  // ---- A2: every member of S served once in every |S| transfers ------------
  task automatic check_fairness(input int members, input int skip, input string tag);
    int i, m, w, seen, hits;
    if (idx_seq.size() < skip + 4*members) begin
      note_fail("TB", $sformatf("%s: only %0d transfers recorded, too few to judge fairness", tag, idx_seq.size()));
      return;
    end
    for (i = skip + members - 1; i < idx_seq.size(); i++) begin
      seen = 0;
      for (w = 0; w < members; w++) seen = seen | (1 << idx_seq[i-w]);
      hits = 0;
      for (m = 0; m < N_IN; m++) if (((seen >> m) & 1) != 0) hits = hits + 1;
      if (hits != members) begin
        note_fail("A2", $sformatf("%s: the %0d transfers ending at transfer %0d came from only %0d of the %0d inputs offering; every member of the set must be served within each window of %0d",
                                  tag, members, i, hits, members, members));
        return;
      end
    end
  endtask

  // ---- helpers -------------------------------------------------------------
  task automatic sb_clear();
    int i;
    src_of.delete();
    dst_of.delete();
    dlv_of.delete();
    for (i = 0; i < 16; i++) ord_q[i].delete();
    n_acc = 0;
    n_dlv = 0;
  endtask

  task automatic check_drained(input string tag);
    int i, left;
    left = 0;
    for (i = 0; i < 16; i++) left = left + ord_q[i].size();
    if (left != 0) begin
      // printed unconditionally: a loss must never be hidden by the message cap
      $display("VIOLATION [R4] %s: %0d beats were accepted and never delivered", tag, left);
      err_count = err_count + 1;
    end
  endtask

  // Stop offering, open every output, and let everything land.
  task automatic drain(input int cycles);
    int k;
    @(posedge clk);
    bfm_offer = '0;
    @(negedge clk);
    out_ready = '1;
    repeat (cycles) @(posedge clk);
  endtask

  task automatic start_inputs(input logic [N_IN-1:0] mask);
    int k;
    @(posedge clk);
    for (k = 0; k < N_IN; k++) if (mask[k] === 1'b1) arm(k);
    bfm_offer = mask;
  endtask

  // -------------------------------------------------------------------------
  // Stimulus
  // -------------------------------------------------------------------------
  initial begin : stimulus
    int i, k, t, before_acc, before_dlv, n2, n3;

    for (k = 0; k < N_IN; k++) begin sel_mode[k] = -1; age[k] = 0; end

    // ===================== X1 / X2: reset ==================================
    bfm_offer = '0;
    bfm_reset(6);                    // checker watches out_valid throughout
    repeat (10) @(posedge clk);      // X2: nothing held, nothing owed
    for (i = 0; i < 10; i++) begin
      @(posedge clk);
      if (out_valid !== {N_OUT{1'b0}})
        note_fail("X2", $sformatf("out_valid_o is %b after reset with no beat ever offered", out_valid));
    end

    // ===================== random traffic, every output ready ==============
    @(negedge clk); out_ready = '1;
    x3_on = 1;
    start_inputs(4'b1111);
    repeat (1500) @(posedge clk);
    x3_on = 0;
    drain(200);
    check_drained("open traffic");
    if (n_acc < 500) note_fail("TB", $sformatf("only %0d beats moved in the open phase", n_acc));

    // ===================== random traffic under backpressure ===============
    start_inputs(4'b1111);
    for (i = 0; i < 2500; i++) begin
      @(negedge clk);
      out_ready = 4'($urandom_range(0, 15));
    end
    drain(400);
    check_drained("backpressure traffic");

    // ===================== A2: four inputs onto one output =================
    for (k = 0; k < N_IN; k++) sel_mode[k] = 0;
    idx_seq.delete();
    fair_out = 0; fair_on = 1;
    @(negedge clk); out_ready = '1;
    start_inputs(4'b1111);
    repeat (400) @(posedge clk);
    fair_on = 0;
    check_fairness(4, 8, "four inputs contending for output 0");
    drain(200);
    check_drained("A2 four-way");

    // ===================== A2: three inputs, and two ======================
    for (k = 0; k < N_IN; k++) sel_mode[k] = 1;
    idx_seq.delete();
    fair_out = 1; fair_on = 1;
    start_inputs(4'b0111);
    repeat (400) @(posedge clk);
    fair_on = 0;
    check_fairness(3, 8, "three inputs contending for output 1");
    drain(200);
    check_drained("A2 three-way");

    for (k = 0; k < N_IN; k++) sel_mode[k] = 3;
    idx_seq.delete();
    fair_out = 3; fair_on = 1;
    start_inputs(4'b1010);           // inputs 1 and 3
    repeat (400) @(posedge clk);
    fair_on = 0;
    check_fairness(2, 8, "two inputs contending for output 3");
    drain(200);
    check_drained("A2 two-way");

    // ===================== I1 / I2: a stalled output blocks nothing =======
    // Inputs 0 and 1 pile into output 0, which never accepts.  Inputs 2 and 3
    // are aimed at outputs 2 and 3, which do.
    sel_mode[0] = 0; sel_mode[1] = 0; sel_mode[2] = 2; sel_mode[3] = 3;
    @(negedge clk); out_ready = 4'b1100;      // output 0 and 1 closed
    start_inputs(4'b1111);
    before_dlv = n_dlv;
    before_acc = n_acc;
    n2 = 0; n3 = 0;
    for (i = 0; i < 600; i++) begin
      @(posedge clk);
      if (out_valid[2] && out_ready[2]) n2 = n2 + 1;
      if (out_valid[3] && out_ready[3]) n3 = n3 + 1;
      if (out_valid[0] && out_ready[0]) note_fail("TB", "output 0 moved a beat while held closed");
    end
    if (n2 < 50)
      note_fail("I1", $sformatf("output 2 delivered only %0d beats in 600 cycles while output 0 was stalled", n2));
    if (n3 < 50)
      note_fail("I2", $sformatf("output 3 delivered only %0d beats in 600 cycles while inputs 0 and 1 were blocked on a stalled output", n3));
    @(negedge clk); out_ready = '1;
    drain(300);
    check_drained("independence");

    // ===================== reset in flight (X1, X2) ========================
    // Fill the design with beats it cannot deliver, then reset.
    sel_mode[0] = 0; sel_mode[1] = 0; sel_mode[2] = 0; sel_mode[3] = 0;
    @(negedge clk); out_ready = '0;
    start_inputs(4'b1111);
    repeat (40) @(posedge clk);
    @(posedge clk); bfm_offer = '0;
    sb_on = 0;                        // beats in flight are discarded by reset
    bfm_reset(6);
    for (i = 0; i < 10; i++) begin
      @(posedge clk);
      if (out_valid !== {N_OUT{1'b0}})
        note_fail("X1", $sformatf("out_valid_o is %b while rst_ni is low, with beats in flight from before the reset", out_valid));
    end
    @(negedge clk); out_ready = '1;
    for (i = 0; i < 20; i++) begin
      @(posedge clk);
      if (out_valid !== {N_OUT{1'b0}})
        note_fail("X2", $sformatf("out_valid_o is %b after reset; a beat from before the reset is still owed", out_valid));
    end
    sb_clear();
    sb_on = 1;

    // ===================== a final open run, to be sure it still works =====
    for (k = 0; k < N_IN; k++) sel_mode[k] = -1;
    x3_on = 1;
    start_inputs(4'b1111);
    repeat (800) @(posedge clk);
    x3_on = 0;
    drain(200);
    check_drained("final traffic");
    if (n_acc < 200) note_fail("TB", $sformatf("only %0d beats moved after the reset", n_acc));

    // ===================== verdict =========================================
    if (err_count == 0) $display("RESULT: PASS");
    else                $display("RESULT: FAIL (%0d violation%s)", err_count, (err_count == 1) ? "" : "s");
    $finish;
  end

endmodule