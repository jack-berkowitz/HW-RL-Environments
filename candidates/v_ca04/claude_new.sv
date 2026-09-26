// =============================================================================
// route_xbar_tb -- self-checking testbench for the valid/ready crossbar.
//
// Model: one FIFO per (input, output) pair, filled at input handshakes with the
// payload and selector actually on the wires, drained at output handshakes.
// Payloads are unique ({input, selector, sequence}); that encoding is used only
// to NAME a violation, never to match a beat.
//
// Process discipline (a Verilator 5.x hazard, measured: a process that writes a
// variable and then polls it can read a stale copy while another process
// updates it):
//   * every variable a process polls is written by exactly one OTHER process;
//   * the monitor (posedge) owns all model state and its own error count;
//   * the sequencer owns the controls and its own error count;
//   * controls read at the falling edge (bfm_offer, ready modes) are changed at
//     the rising edge, and controls read at the rising edge (fairness window,
//     selector policy, watch flags) are changed at the falling edge.
// =============================================================================
module route_xbar_tb;

// ---------------------------------------------------------------------------
// PROVIDED PLUMBING -- moves beats, checks nothing.
// ---------------------------------------------------------------------------
// This exists so you spend your effort on checking rather than on handshake
// mechanics. It has been compiled and run against a correct design.
//
// What it does: generates the clock, sequences reset, connects the design, and
// keeps each input offering the beat you have put in front of it -- holding the
// offer unchanged until it is taken, which is what clause H2 requires of a
// source, and starting the next one the moment it is.
//
// What it does NOT do: it chooses no payloads, keeps no model of what went
// where, counts nothing, and draws no conclusion from any signal. Routing,
// ordering, delivery, fairness and every check are yours to write.
//
// TWO THINGS WORTH KNOWING, both of which cost real time to find:
//
//   * The driver below is an ALWAYS BLOCK, not a loop you pump from your
//     stimulus. A pumped loop only services the edges it happens to be waiting
//     on, and every edge you wait on elsewhere -- to change a ready line, to
//     bring another input in -- is an edge where a beat can be accepted
//     unnoticed. Keep presenting a beat that has already been taken and the
//     design takes it again, which looks exactly like the design delivering it
//     twice.
//
//   * Sample a handshake AT the rising edge. `in_ready_o` read at the falling
//     edge is not necessarily the value the design used.
// ---------------------------------------------------------------------------

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
  // Set bfm_offer[k] to keep input k offering. Put the payload and selector for
  // the NEXT beat in bfm_next_data[k] / bfm_next_sel[k]; the driver picks them
  // up when it starts a beat, and never mid-offer.
  logic [N_IN-1:0]  bfm_offer;
  logic [DW-1:0]    bfm_next_data [N_IN];
  logic [SW-1:0]    bfm_next_sel  [N_IN];

  // Registered handshake: bfm_accepted[k] is high for the cycle following the
  // rising edge on which input k's beat was taken.
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
  // Yours to keep. It fires regardless of what the design does: one of the
  // faulty designs never accepts anything at all, and without this your
  // testbench hangs instead of reporting. A hang is not a verdict.
  initial begin
    #2_000_000;
    $display("RESULT: FAIL (watchdog: no verdict reached)");
    $finish;
  end

  // ===========================================================================
  // Testbench proper
  // ===========================================================================

  // ---------------------------------------------------------------- failures
  int errs_m = 0, errs_s = 0;               // monitor-owned / sequencer-owned
  int eby_m [string];
  int eby_s [string];

  task automatic fail_m(input string req, input string msg);
    errs_m++;
    if (!eby_m.exists(req)) eby_m[req] = 0;
    eby_m[req]++;
    if (eby_m[req] <= 6) $display("FAIL %s: cycle %0d: %s", req, bfm_cycle, msg);
  endtask

  task automatic fail_s(input string req, input string msg);
    errs_s++;
    if (!eby_s.exists(req)) eby_s[req] = 0;
    eby_s[req]++;
    if (eby_s[req] <= 6) $display("FAIL %s: cycle %0d: %s", req, bfm_cycle, msg);
  endtask

  // ---------------------------------------------------------------- controls (sequencer-owned)
  // selector policy per input: 0..3 fixed output, 4 random
  int pol [N_IN];
  // output ready mode: 0 low, 1 high, 2 random (rdy_pct %)
  int rmode [N_OUT];
  int rdy_pct = 70;
  // fairness window
  int fair_run = 0, fair_out = 0;
  logic [N_IN-1:0] fair_set = '0;
  bit fair_en = 1'b0;
  // X2 quiet window after reset release, and the label for liveness failures
  bit x2_watch = 1'b0;
  bit hol_phase = 1'b0;

  initial begin
    for (int k = 0; k < N_IN; k++) pol[k] = 4;
    for (int j = 0; j < N_OUT; j++) rmode[j] = 1;
  end

  // ---------------------------------------------------------------- ready driver
  always @(negedge clk) begin
    for (int j = 0; j < N_OUT; j++)
      out_ready[j] = (rmode[j] == 1) || (rmode[j] == 2 && $urandom_range(0, 99) < rdy_pct);
  end

  // ---------------------------------------------------------------- payload generator
  // Whenever input k could start a new beat at the coming falling edge, give it a
  // fresh unique payload and a selector from its policy.
  int seq_no = 0;
  always @(posedge clk) begin
    for (int k = 0; k < N_IN; k++) begin
      if (!in_valid[k] || in_ready[k]) begin
        automatic logic [1:0] s;
        s = (pol[k] == 4) ? 2'($urandom_range(0, 3)) : 2'(pol[k]);
        seq_no++;
        bfm_next_sel[k]  = s;
        bfm_next_data[k] = {2'(k), s, 28'(seq_no)};
      end
    end
  end

  // ---------------------------------------------------------------- model (monitor-owned)
  logic [DW-1:0] fifo [N_IN*N_OUT][$];      // accepted, not yet delivered, per (input, output)
  bit            acc_set [logic [DW-1:0]];  // every payload accepted this epoch
  bit            del_set [logic [DW-1:0]];  // every payload delivered this epoch
  bit            dbl_set [logic [DW-1:0]];  // accepted alongside another beat for the same output
  bit            ovt_set [logic [DW-1:0]];  // overtaken by a later beat of the same input and output
  int            n_pend = 0, n_acc = 0, n_del = 0;
  int            n_del_out [N_OUT];
  bit            in_rst = 1'b1;
  int            n_edges = 0;

  // A3 hold tracking
  bit            hold_p [N_OUT];
  logic [DW-1:0] hold_d [N_OUT];
  logic [IW-1:0] hold_i [N_OUT];

  // X3 liveness
  int            live_cnt [N_IN];

  // A2 fairness state
  int            f_last_run = 0;
  int            f_xfers = 0;
  bit            f_warm = 1'b0;
  bit            f_starved = 1'b0;
  logic [N_IN-1:0] f_seen;
  int            f_gap [N_IN];

  function automatic int popcnt4(input logic [N_IN-1:0] v);
    int n;
    n = 0;
    for (int k = 0; k < N_IN; k++) n += int'(v[k]);
    return n;
  endfunction

  // remove one payload from whichever FIFO holds it; returns 1 if found
  function automatic bit fifo_remove(input logic [DW-1:0] p);
    for (int q = 0; q < N_IN * N_OUT; q++)
      for (int e = 0; e < fifo[q].size(); e++)
        if (fifo[q][e] == p) begin fifo[q].delete(e); return 1'b1; end
    return 1'b0;
  endfunction

  always @(posedge clk) begin : monitor
    automatic logic [DW-1:0] p;
    automatic int            i, s, q, need, pos;
    automatic logic [N_OUT-1:0] tgt_seen;
    automatic logic [DW-1:0] tgt_first [N_OUT];
    automatic string         why;
    n_edges++;

    if (!rst_n) begin
      // ------------------------------------------------------------ X1
      if (!in_rst) begin                          // first edge of this reset: model empties (X2)
        for (q = 0; q < N_IN * N_OUT; q++) fifo[q].delete();
        acc_set.delete(); del_set.delete(); dbl_set.delete(); ovt_set.delete();
        n_pend = 0;
        for (int j = 0; j < N_OUT; j++) hold_p[j] = 1'b0;
        for (int k = 0; k < N_IN; k++) live_cnt[k] = 0;
      end
      in_rst = 1'b1;
      // from the first edge onward, with the inputs quiet, nothing may complete
      if (n_edges > 1 && in_valid == '0) begin
        for (int j = 0; j < N_OUT; j++)
          if (out_valid[j] && out_ready[j])
            fail_m("X1", $sformatf("a beat completed on output %0d while rst_ni was low", j));
      end
    end else begin
      in_rst = 1'b0;

      // ------------------------------------------------------------ input handshakes
      tgt_seen = '0;
      for (int k = 0; k < N_IN; k++) begin
        if (in_valid[k] && in_ready[k]) begin
          p = in_data[k*DW +: DW];
          s = int'(in_sel[k*SW +: SW]);
          fifo[k * N_OUT + s].push_back(p);
          acc_set[p] = 1'b1;
          if (tgt_seen[s]) begin dbl_set[p] = 1'b1; dbl_set[tgt_first[s]] = 1'b1; end
          else tgt_first[s] = p;
          tgt_seen[s] = 1'b1;
          n_pend++; n_acc++;
        end
      end

      // ------------------------------------------------------------ output handshakes
      for (int j = 0; j < N_OUT; j++) begin
        if (out_valid[j] && out_ready[j]) begin
          p = out_data[j*DW +: DW];
          i = int'(out_idx[j*IW +: IW]);
          q = i * N_OUT + j;
          n_del++; n_del_out[j]++;
          pos = -1;
          for (int e = 0; e < fifo[q].size(); e++) if (fifo[q][e] == p) begin pos = e; break; end
          if (pos == 0) begin
            void'(fifo[q].pop_front());                       // R1-R4 hold for this beat
            n_pend--;
            del_set[p] = 1'b1;
            if (ovt_set.exists(p))
              fail_m("R5", $sformatf("output %0d delivered %h from input %0d after a later beat of that input", j, p, i));
          end else if (pos > 0 && !x2_watch) begin
            // A later beat has overtaken earlier ones. Whether those were reordered
            // (R5) or lost (R4) is only known later: mark them and decide then.
            for (int e = 0; e < pos; e++) ovt_set[fifo[q][e]] = 1'b1;
            fifo[q].delete(pos);
            n_pend--;
            del_set[p] = 1'b1;
          end else begin
            // name the violation; keep the model consistent afterwards
            if (x2_watch)                 why = "X2";
            else if (!acc_set.exists(p))  why = (fifo[q].size() > 0) ? "R2" : "R6";
            else if (del_set.exists(p))   why = "R4";
            else if (int'(p[29:28]) != j) why = "R1";
            else if (int'(p[31:30]) != i) why = "R3";
            else                          why = "R5";
            if (why == "X2")
              fail_m("X2", $sformatf("output %0d delivered %h after reset release; nothing is owed", j, p));
            else if (why == "R6")
              fail_m("R6", $sformatf("output %0d delivered %h (idx %0d), which was never accepted", j, p, i));
            else if (why == "R2")
              fail_m("R2", $sformatf("output %0d delivered %h (idx %0d); next beat owed from that input is %h",
                                     j, p, i, fifo[q][0]));
            else if (why == "R4")
              fail_m("R4", $sformatf("output %0d delivered %h a second time", j, p));
            else if (why == "R1")
              fail_m("R1", $sformatf("beat %h, accepted for output %0d, delivered on output %0d",
                                     p, int'(p[29:28]), j));
            else if (why == "R3")
              fail_m("R3", $sformatf("output %0d delivered %h with idx %0d; it was accepted on input %0d",
                                     j, p, i, int'(p[31:30])));
            else
              fail_m("R5", $sformatf("output %0d delivered %h from input %0d ahead of an earlier beat %h",
                                     j, p, i, fifo[q][0]));
            if (fifo_remove(p)) n_pend--;
            del_set[p] = 1'b1;
          end

          // ---------------------------------------------------------- A2 fairness
          if (fair_en && j == fair_out && fair_run == f_last_run && fair_set[i]) begin
            need = popcnt4(fair_set);
            f_xfers++;
            for (int k = 0; k < N_IN; k++) begin
              if (!fair_set[k]) continue;
              if (k == i) begin f_seen[k] = 1'b1; f_gap[k] = 0; end
              else if (f_seen[k]) f_gap[k]++;
            end
            if (!f_warm && f_seen == fair_set) begin
              f_warm = 1'b1;                                   // L1/L2: phase and pipeline fill are free
              for (int k = 0; k < N_IN; k++) f_gap[k] = 0;
            end else if (f_warm) begin
              for (int k = 0; k < N_IN; k++)
                if (fair_set[k] && f_gap[k] >= need)
                  fail_m("A2", $sformatf("output %0d: input %0d not served in %0d consecutive transfers with %0d inputs contending",
                                         j, k, f_gap[k], need));
            end
            if (!f_warm && !f_starved && f_xfers > 4 * need + 8) begin
              f_starved = 1'b1;
              fail_m("A2", $sformatf("output %0d: %0d transfers with %0d inputs contending and one never served",
                                     j, f_xfers, need));
            end
          end
        end
      end
      if (fair_run != f_last_run) begin                        // new fairness window
        f_last_run = fair_run; f_xfers = 0; f_warm = 1'b0; f_starved = 1'b0; f_seen = '0;
        for (int k = 0; k < N_IN; k++) f_gap[k] = 0;
      end

      // ------------------------------------------------------------ A3: an offered beat is held
      for (int j = 0; j < N_OUT; j++) begin
        if (hold_p[j] && (!out_valid[j] || out_data[j*DW +: DW] !== hold_d[j] || out_idx[j*IW +: IW] !== hold_i[j]))
          fail_m("A3", $sformatf("output %0d withdrew or changed an offered beat before out_ready (was %h idx %0d, now valid %0b %h idx %0d)",
                                 j, hold_d[j], hold_i[j], out_valid[j], out_data[j*DW +: DW], out_idx[j*IW +: IW]));
        hold_p[j] = out_valid[j] && !out_ready[j];
        hold_d[j] = out_data[j*DW +: DW];
        hold_i[j] = out_idx[j*IW +: IW];
      end

      // ------------------------------------------------------------ X3 (and I2): bounded acceptance
      for (int k = 0; k < N_IN; k++) begin
        if (in_valid[k] && !in_ready[k] && out_ready[int'(in_sel[k*SW +: SW])]) begin
          live_cnt[k]++;
          if (live_cnt[k] == 33) begin
            why = $sformatf("input %0d offering to continuously-ready output %0d not accepted in 32 cycles",
                            k, int'(in_sel[k*SW +: SW]));
            if (hol_phase) fail_m("I2", {why, " while another output was stalled"});
            else           fail_m("X3", why);
          end
        end else begin
          live_cnt[k] = 0;
        end
      end

      // ------------------------------------------------------------ X2: nothing held after release
      if (x2_watch && in_valid == '0 && out_valid != '0)
        fail_m("X2", $sformatf("out_valid %b with no input offering, after reset release", out_valid));
    end
  end

  // ---------------------------------------------------------------- sequencer helpers
  // controls sampled at the FALLING edge change at the RISING edge, and vice versa
  task automatic set_offer(input logic [N_IN-1:0] v);
    @(posedge clk); bfm_offer = v;
  endtask

  task automatic set_rmode(input int j, input int m);
    @(posedge clk); rmode[j] = m;
  endtask

  task automatic set_all_rmode(input int m);
    @(posedge clk); for (int j = 0; j < N_OUT; j++) rmode[j] = m;
  endtask

  task automatic set_pol(input int k, input int v);
    @(negedge clk); pol[k] = v;
  endtask

  // Stop offering, make every output ready, and wait for everything accepted to
  // be delivered. Anything left is lost (R4).
  task automatic drain(input string phase, input int limit);
    int k, c;
    set_offer('0);
    set_all_rmode(1);
    for (c = 0; c < limit && !(n_pend == 0 && in_valid == '0); c++) @(negedge clk);
    if (in_valid != '0)
      fail_s("X3", $sformatf("[%s] offer on inputs %b never accepted with every output ready", phase, in_valid));
    if (n_pend != 0) begin
      for (int q = 0; q < N_IN * N_OUT; q++)
        for (int e = 0; e < fifo[q].size(); e++)
        begin
          string note;
          note = "";
          if (dbl_set.exists(fifo[q][e]))      note = " (accepted in the same cycle as another beat for that output -- A1)";
          else if (ovt_set.exists(fifo[q][e])) note = " (later beats of that input were delivered past it)";
          fail_s("R4", {$sformatf("[%s] beat %h accepted on input %0d for output %0d never delivered",
                                  phase, fifo[q][e], q / N_OUT, q % N_OUT), note});
        end
    end
    repeat (3) @(negedge clk);
  endtask

  // A2 on one output with a given contending set.
  task automatic fair_case(input int j, input logic [N_IN-1:0] set, input int ready_mode, input int xfers);
    int c, d0;
    for (int k = 0; k < N_IN; k++) set_pol(k, set[k] ? j : 4);
    set_rmode(j, ready_mode);
    @(negedge clk);
    fair_out = j; fair_set = set; fair_run = fair_run + 1; fair_en = 1'b1;
    d0 = n_del_out[j];
    set_offer(set);
    for (c = 0; c < 4000 && (n_del_out[j] - d0) < xfers; c++) @(negedge clk);
    if ((n_del_out[j] - d0) < xfers)
      fail_s("X3", $sformatf("output %0d moved only %0d beats in 4000 cycles with inputs %b offering",
                             j, n_del_out[j] - d0, set));
    @(negedge clk);
    fair_en = 1'b0;
    drain($sformatf("fairness out %0d set %b", j, set), 400);
  endtask

  // ---------------------------------------------------------------- sequencer
  initial begin : sequencer
    automatic int c, d1, d2, d3, a0;

    // ===== reset from power-up (X1 checked by the monitor from the first edge)
    bfm_reset(5);
    repeat (3) @(negedge clk);

    // ===== 1. routing, payload, index, order, once-only (R1-R6), all ready
    $display("phase 1: routing");
    for (int k = 0; k < N_IN; k++) set_pol(k, 4);
    set_all_rmode(1);
    set_offer('1);
    repeat (400) @(negedge clk);
    // the same with outputs stalling at random (A3 exercised)
    set_all_rmode(2);
    repeat (1200) @(negedge clk);
    drain("routing", 600);

    // ===== 2. fairness (A2) at every contending-set size, several outputs
    $display("phase 2: fairness");
    fair_case(0, 4'b1111, 1, 80);
    fair_case(1, 4'b1111, 2, 80);
    fair_case(2, 4'b0111, 1, 60);
    fair_case(3, 4'b1011, 2, 60);
    fair_case(0, 4'b0101, 1, 40);
    fair_case(1, 4'b1010, 2, 40);
    fair_case(3, 4'b1100, 1, 40);
    fair_case(2, 4'b1001, 2, 40);

    // ===== 3. independence (I1, I2): one output stalled, others must keep moving
    $display("phase 3: independence");
    @(negedge clk) hol_phase = 1'b1;
    set_all_rmode(1);
    set_rmode(0, 0);
    set_pol(0, 0); set_pol(1, 1); set_pol(2, 2); set_pol(3, 3);
    set_offer('1);
    repeat (40) @(negedge clk);
    d1 = n_del_out[1]; d2 = n_del_out[2]; d3 = n_del_out[3];
    repeat (250) @(negedge clk);
    if (n_del_out[1] - d1 < 20 || n_del_out[2] - d2 < 20 || n_del_out[3] - d3 < 20)
      fail_s("I1", $sformatf("with output 0 stalled, outputs 1/2/3 moved only %0d/%0d/%0d beats in 250 cycles",
                             n_del_out[1] - d1, n_del_out[2] - d2, n_del_out[3] - d3));
    // two inputs stuck behind the stalled output, two free
    set_pol(0, 0); set_pol(1, 0); set_pol(2, 1); set_pol(3, 2);
    repeat (40) @(negedge clk);
    d1 = n_del_out[1]; d2 = n_del_out[2];
    repeat (250) @(negedge clk);
    if (n_del_out[1] - d1 < 20 || n_del_out[2] - d2 < 20)
      fail_s("I1", $sformatf("with output 0 stalled, outputs 1/2 moved only %0d/%0d beats in 250 cycles",
                             n_del_out[1] - d1, n_del_out[2] - d2));
    @(negedge clk) hol_phase = 1'b0;
    drain("independence", 600);

    // ===== 4. reset mid-operation (X1 asynchronous, X2 nothing held after)
    $display("phase 4: reset");
    for (int k = 0; k < N_IN; k++) set_pol(k, 0);
    set_all_rmode(1);
    set_rmode(0, 0);                          // output 0 stalled
    set_offer(4'b0001);                       // exactly one beat on input 0
    set_offer(4'b0000);
    for (c = 0; c < 40 && in_valid[0]; c++) @(negedge clk);
    if (in_valid[0]) begin
      // an unbuffered design holds the offer; let it through so the inputs are quiet
      set_rmode(0, 1);
      for (c = 0; c < 40 && in_valid[0]; c++) @(negedge clk);
    end
    // inputs quiet; a buffering design now holds the beat. Make output 0 ready on
    // the same falling edge that asserts reset: an asynchronous reset drops the
    // beat at once, a synchronous one completes it at the next edge (X1).
    @(posedge clk) rmode[0] = 1;
    @(negedge clk) rst_n = 1'b0;
    repeat (5) @(posedge clk);
    @(negedge clk) rst_n = 1'b1;
    x2_watch = 1'b1;
    repeat (60) @(negedge clk);
    x2_watch = 1'b0;
    // the crossbar works normally afterwards
    a0 = n_acc;
    for (int k = 0; k < N_IN; k++) set_pol(k, 4);
    set_offer('1);
    repeat (200) @(negedge clk);
    if (n_acc - a0 < 50) fail_s("X3", $sformatf("only %0d beats accepted in 200 cycles after reset release", n_acc - a0));
    drain("after reset", 600);

    // ===== 5. long random traffic: selectors, offers and readiness all random
    $display("phase 5: random");
    for (int k = 0; k < N_IN; k++) set_pol(k, 4);
    set_all_rmode(2);
    for (int r = 0; r < 60; r++) begin
      set_offer(4'($urandom_range(1, 15)));
      @(posedge clk) rdy_pct = $urandom_range(20, 100);
      repeat ($urandom_range(20, 120)) @(negedge clk);
    end
    drain("random", 800);

    // ===== verdict
    $display("summary: %0d beats accepted, %0d delivered", n_acc, n_del);
    if (n_acc < 1000) fail_s("X3", $sformatf("only %0d beats accepted over the whole run", n_acc));
    if (errs_m + errs_s == 0) $display("RESULT: PASS");
    else                      $display("RESULT: FAIL");
    $finish;
  end

endmodule