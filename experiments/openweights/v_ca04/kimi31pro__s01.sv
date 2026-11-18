`timescale 1ns/1ps

module route_xbar_tb;

// ---------------------------------------------------------------------------
// PROVIDED PLUMBING -- moves beats, checks nothing.
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

  function automatic logic [DW-1:0] bfm_odata(input int j);
    return out_data[j*DW +: DW];
  endfunction

  function automatic logic [IW-1:0] bfm_oidx(input int j);
    return out_idx[j*IW +: IW];
  endfunction

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
        if (bfm_accepted[k]) in_valid[k] = 1'b0;
        if (!in_valid[k] && bfm_offer[k]) begin
          in_data[k*DW +: DW] = bfm_next_data[k];
          in_sel [k*SW +: SW] = bfm_next_sel[k];
          in_valid[k]         = 1'b1;
        end
      end
    end
  end

  task automatic bfm_ready(input logic [N_OUT-1:0] v);
    out_ready = v;
  endtask

  initial begin
    in_data = '0; in_sel = '0; in_valid = '0; out_ready = '1; bfm_offer = '0;
    for (int k = 0; k < N_IN; k++) begin
      bfm_next_data[k] = '0;
      bfm_next_sel[k]  = '0;
    end
  end

  // ---- watchdog ------------------------------------------------------------
  initial begin
    #2_000_000;
    $display("RESULT: FAIL (watchdog: no verdict reached)");
    $finish;
  end

// ---------------------------------------------------------------------------
// Scoreboard and protocol checking
// ---------------------------------------------------------------------------

  typedef struct packed {
    logic [DW-1:0] data;
    logic [SW-1:0] sel;
    logic [IW-1:0] src;
    int unsigned   tag;
  } beat_t;

  beat_t pending_q[$];
  beat_t delivered_q[$];

  bit done;
  bit any_clock_edge;
  bit auto_rotate;
  int mon_cycle;
  int unsigned serial;
  int unsigned accept_tag;

  int epoch_accepted;
  int epoch_delivered;
  int accept_count  [N_IN];
  int deliver_count [N_OUT];

  // Output-offer stability state for A3.
  bit           hold_valid [N_OUT];
  logic [DW-1:0] hold_data [N_OUT];
  logic [IW-1:0] hold_idx  [N_OUT];

  // Per-input offer tracking for X3.
  bit           live_active      [N_IN];
  bit           live_ready_chain [N_IN];
  int           live_start       [N_IN];
  int           live_dest        [N_IN];
  logic [DW-1:0] live_data       [N_IN];
  logic [SW-1:0] live_sel        [N_IN];

  // Directed fairness-window state.
  bit fair_en;
  int fair_out;
  int fair_m;
  int fair_transfers;
  logic [N_IN-1:0] fair_mask;
  int fair_hist[$];

  task automatic fail(input string clause, input string detail);
    begin
      if (!done) begin
        done = 1'b1;
        $display("route_xbar_tb: %s at cycle %0d: %s",
                 clause, mon_cycle, detail);
        $display("RESULT: FAIL");
        $finish;
      end
    end
  endtask

  // Every payload is unique, while the scoreboard still uses accepted-beat
  // records rather than treating payload value alone as proof of identity.
  function automatic logic [DW-1:0] fresh_data(input int src);
    begin
      serial = serial + 1;
      fresh_data = (serial << 2) | (src & 3);
    end
  endfunction

  task automatic record_accept(input int k);
    beat_t b;
    begin
      b.data = in_data[k*DW +: DW];
      b.sel  = in_sel [k*SW +: SW];
      b.src  = k;
      b.tag  = accept_tag;
      accept_tag = accept_tag + 1;

      pending_q.push_back(b);
      epoch_accepted = epoch_accepted + 1;
      accept_count[k] = accept_count[k] + 1;

      // Prepare a distinct following beat. These are BFM-side variables; the
      // design-visible payload and selector remain unchanged until negedge.
      bfm_next_data[k] = fresh_data(k);
      if (auto_rotate)
        bfm_next_sel[k] = b.sel + 1'b1;
    end
  endtask

  task automatic record_delivery(input int j);
    beat_t b;
    logic [DW-1:0] d;
    logic [IW-1:0] sx;
    int src;
    int i;
    int first_pos;
    int match_pos;
    int wrong_dest_pos;
    int wrong_src_pos;
    begin
      d  = bfm_odata(j);
      sx = bfm_oidx(j);

      if ($isunknown(sx))
        fail("R3", $sformatf("output %0d transferred with unknown source index", j));
      if ($isunknown(d))
        fail("R2", $sformatf("output %0d transferred with unknown payload", j));

      src = sx;
      first_pos = -1;
      match_pos = -1;
      wrong_dest_pos = -1;
      wrong_src_pos = -1;

      for (i = 0; i < pending_q.size(); i = i + 1) begin
        if ((pending_q[i].src == sx) && (pending_q[i].sel == j)) begin
          if (first_pos < 0)
            first_pos = i;
          if ((match_pos < 0) && (pending_q[i].data == d))
            match_pos = i;
        end

        if ((pending_q[i].src == sx) &&
            (pending_q[i].data == d) &&
            (pending_q[i].sel != j))
          wrong_dest_pos = i;

        if ((pending_q[i].src != sx) &&
            (pending_q[i].data == d) &&
            (pending_q[i].sel == j))
          wrong_src_pos = i;
      end

      if (first_pos < 0) begin
        if (wrong_dest_pos >= 0) begin
          fail("R1", $sformatf(
               "beat from input %0d bound for output %0d appeared on output %0d",
               src, pending_q[wrong_dest_pos].sel, j));
        end else if (wrong_src_pos >= 0) begin
          fail("R3", $sformatf(
               "output %0d named input %0d, but payload belongs to input %0d",
               j, src, pending_q[wrong_src_pos].src));
        end else begin
          // Distinguish a duplicate from a wholly originated beat where the
          // bookkeeping makes that possible.
          for (i = 0; i < delivered_q.size(); i = i + 1) begin
            if ((delivered_q[i].data == d) &&
                (delivered_q[i].src == sx)) begin
              if (delivered_q[i].sel == j)
                fail("R4", $sformatf(
                     "output %0d delivered a beat from input %0d more than once",
                     j, src));
              else
                fail("R1", $sformatf(
                     "already delivered beat appeared on wrong output %0d", j));
            end
          end
          fail("R6", $sformatf(
               "output %0d delivered data %08x from input %0d with no accepted beat",
               j, d, src));
        end
      end else if (pending_q[first_pos].data != d) begin
        if (match_pos >= 0)
          fail("R5", $sformatf(
               "output %0d reordered beats from input %0d", j, src));
        else
          fail("R2", $sformatf(
               "output %0d changed payload from input %0d: expected %08x, got %08x",
               j, src, pending_q[first_pos].data, d));
      end else begin
        b = pending_q[first_pos];
        pending_q.delete(first_pos);
        delivered_q.push_back(b);
        epoch_delivered = epoch_delivered + 1;
        deliver_count[j] = deliver_count[j] + 1;
      end
    end
  endtask

  task automatic fairness_edge(input int j);
    int seen [N_IN];
    int src;
    int i;
    int discarded;
    begin
      src = bfm_oidx(j);

      if ((src < 0) || (src >= N_IN) || !fair_mask[src])
        fail("A2", $sformatf(
             "output %0d served input %0d outside the continuously offering set",
             j, src));

      fair_hist.push_back(src);
      fair_transfers = fair_transfers + 1;

      // Check every sliding window of |S| transfers, not merely disjoint ones.
      if (fair_hist.size() == fair_m) begin
        for (i = 0; i < N_IN; i = i + 1)
          seen[i] = 0;

        for (i = 0; i < fair_hist.size(); i = i + 1)
          seen[fair_hist[i]] = seen[fair_hist[i]] + 1;

        for (i = 0; i < N_IN; i = i + 1) begin
          if (fair_mask[i] && (seen[i] == 0))
            fail("A2", $sformatf(
                 "output %0d omitted input %0d from a window of %0d transfers",
                 j, i, fair_m));
        end

        discarded = fair_hist.pop_front();
      end
    end
  endtask

  task automatic check_liveness(input int k);
    logic [DW-1:0] current_data;
    logic [SW-1:0] current_sel;
    begin
      if (in_valid[k] === 1'b1) begin
        current_data = in_data[k*DW +: DW];
        current_sel  = in_sel [k*SW +: SW];

        if (!live_active[k] ||
            (live_data[k] != current_data) ||
            (live_sel[k] != current_sel)) begin
          live_active[k] = 1'b1;
          live_start[k] = mon_cycle;
          live_data[k] = current_data;
          live_sel[k] = current_sel;
          live_dest[k] = current_sel;
          live_ready_chain[k] = (out_ready[current_sel] === 1'b1);
        end else begin
          if (out_ready[live_dest[k]] !== 1'b1)
            live_ready_chain[k] = 1'b0;
        end

        if (in_ready[k] === 1'b1) begin
          live_active[k] = 1'b0;
        end else if (live_ready_chain[k] &&
                     ((mon_cycle - live_start[k]) > 32)) begin
          fail("X3", $sformatf(
               "input %0d was not accepted within 32 cycles although output %0d stayed ready",
               k, live_dest[k]));
        end
      end else begin
        live_active[k] = 1'b0;
      end
    end
  endtask

  task automatic check_output(input int j);
    begin
      if ($isunknown(out_valid[j]))
        fail("R6", $sformatf("output %0d has unknown valid after reset", j));

      if (hold_valid[j]) begin
        if (out_valid[j] !== 1'b1)
          fail("A3", $sformatf(
               "output %0d withdrew an offered beat before ready", j));
        else if ((bfm_odata(j) !== hold_data[j]) ||
                 (bfm_oidx(j)  !== hold_idx[j]))
          fail("A3", $sformatf(
               "output %0d changed payload or source while stalled", j));
      end

      if ((out_valid[j] === 1'b1) && (out_ready[j] === 1'b1)) begin
        record_delivery(j);
        if (fair_en && (j == fair_out))
          fairness_edge(j);
      end

      if ((out_valid[j] === 1'b1) && (out_ready[j] !== 1'b1)) begin
        hold_valid[j] = 1'b1;
        hold_data[j] = bfm_odata(j);
        hold_idx[j] = bfm_oidx(j);
      end else begin
        hold_valid[j] = 1'b0;
      end
    end
  endtask

  task automatic model_reset_edge;
    int k;
    begin
      // Inputs are quiet during the reset checks. The first ever rising edge
      // is skipped because pre-edge register state is not defined by X1.
      if (any_clock_edge && (in_valid === '0)) begin
        if (out_valid !== '0)
          fail("X1", "output valid was nonzero during reset with quiet inputs");
      end

      pending_q.delete();
      epoch_accepted = 0;
      epoch_delivered = 0;
      fair_hist.delete();

      for (k = 0; k < N_IN; k = k + 1) begin
        accept_count[k] = 0;
        live_active[k] = 1'b0;
        live_ready_chain[k] = 1'b0;
      end

      for (k = 0; k < N_OUT; k = k + 1) begin
        deliver_count[k] = 0;
        hold_valid[k] = 1'b0;
      end
    end
  endtask

  task automatic model_active_edge;
    int k;
    int j;
    begin
      // Acceptance is recorded first: a combinational implementation may
      // legitimately accept and deliver the same beat on one rising edge.
      for (k = 0; k < N_IN; k = k + 1) begin
        if ((in_valid[k] === 1'b1) && (in_ready[k] === 1'b1))
          record_accept(k);
      end

      for (j = 0; j < N_OUT; j = j + 1)
        check_output(j);

      for (k = 0; k < N_IN; k = k + 1)
        check_liveness(k);
    end
  endtask

  always @(posedge clk) begin
    if (!rst_n)
      model_reset_edge();
    else
      model_active_edge();

    any_clock_edge = 1'b1;
    mon_cycle = mon_cycle + 1;
  end

// ---------------------------------------------------------------------------
// Stimulus helpers
// ---------------------------------------------------------------------------

  task automatic drain(input string where);
    int start;
    begin
      @(negedge clk);
      bfm_offer = '0;
      auto_rotate = 1'b0;
      out_ready = '1;

      start = mon_cycle;
      while (((pending_q.size() != 0) ||
              (in_valid !== '0) ||
              (out_valid !== '0)) &&
             ((mon_cycle - start) < 5000)) begin
        @(negedge clk);
      end

      if (in_valid !== '0)
        fail("X3", $sformatf("unaccepted source offer remained after %s", where));
      if (pending_q.size() != 0)
        fail("R4", $sformatf(
             "%0d accepted beats were not delivered after %s",
             pending_q.size(), where));
      if (out_valid !== '0)
        fail("R4/R6", $sformatf("output remained active after %s", where));
      if (epoch_accepted != epoch_delivered)
        fail("R4", $sformatf(
             "accepted/delivered counts differ after %s: %0d/%0d",
             where, epoch_accepted, epoch_delivered));
    end
  endtask

  task automatic run_traffic(input int cycles);
    int t;
    int k;
    logic [15:0] lfsr;
    begin
      @(negedge clk);
      auto_rotate = 1'b1;
      out_ready = '1;
      lfsr = 16'h1;

      for (k = 0; k < N_IN; k = k + 1) begin
        bfm_next_data[k] = fresh_data(k);
        bfm_next_sel[k] = k;
      end
      bfm_offer = '1;

      for (t = 0; t < cycles; t = t + 1) begin
        @(negedge clk);
        lfsr = {lfsr[14:0],
                lfsr[15] ^ lfsr[13] ^ lfsr[12] ^ lfsr[10]};

        if ((t % 19) == 0)
          out_ready = '1;
        else
          out_ready = lfsr[3:0] | (4'b0001 << (t % N_OUT));
      end

      drain("backpressure traffic");
    end
  endtask

  task automatic independence_one(input int stalled);
    int before_a [N_IN];
    int before_d [N_OUT];
    int k;
    begin
      @(negedge clk);
      out_ready = '1;
      out_ready[stalled] = 1'b0;
      auto_rotate = 1'b0;

      for (k = 0; k < N_IN; k = k + 1) begin
        before_a[k] = accept_count[k];
        before_d[k] = deliver_count[k];
        bfm_next_data[k] = fresh_data(k);
        bfm_next_sel[k] = k;
      end
      bfm_offer = '1;

      // Only input `stalled` is bound for the non-ready output. Every other
      // input has a distinct, continuously ready output.
      repeat (96) @(negedge clk);

      for (k = 0; k < N_IN; k = k + 1) begin
        if (k != stalled) begin
          if (accept_count[k] == before_a[k])
            fail("I2", $sformatf(
                 "stalled input %0d prevented acceptance of input %0d",
                 stalled, k));
          if (deliver_count[k] == before_d[k])
            fail("I1", $sformatf(
                 "non-ready output %0d prevented transfers on output %0d",
                 stalled, k));
        end
      end

      drain($sformatf("independence with output %0d stalled", stalled));
    end
  endtask

  task automatic stability_one(input int j);
    int first;
    int k;
    int waited;
    begin
      first = j;

      @(negedge clk);
      out_ready = '1;
      out_ready[j] = 1'b0;
      bfm_offer = '0;
      auto_rotate = 1'b0;
      bfm_next_data[first] = fresh_data(first);
      bfm_next_sel[first] = j;
      bfm_offer[first] = 1'b1;

      // A design is not required to assert valid while ready is low. If it
      // does, however, A3 applies in full; use that opportunity to introduce
      // new contenders and try to make it re-arbitrate the offered beat.
      waited = 0;
      while ((out_valid[j] !== 1'b1) && (waited < 48)) begin
        @(negedge clk);
        waited = waited + 1;
      end

      if (out_valid[j] === 1'b1) begin
        @(negedge clk);
        bfm_offer = '0;
        for (k = 0; k < N_IN; k = k + 1) begin
          if (k != first) begin
            bfm_next_data[k] = fresh_data(k);
            bfm_next_sel[k] = j;
            bfm_offer[k] = 1'b1;
          end
        end

        repeat (10) @(negedge clk);
        bfm_offer = '0;
        out_ready = '1;
      end else begin
        bfm_offer = '0;
        out_ready = '1;
      end

      drain($sformatf("stability test on output %0d", j));
    end
  endtask

  task automatic reset_with_activity;
    begin
      @(negedge clk);
      bfm_offer = '0;
      auto_rotate = 1'b0;
      out_ready = '1;
      out_ready[2] = 1'b0;
      bfm_next_data[1] = fresh_data(1);
      bfm_next_sel[1] = 2;
      bfm_offer[1] = 1'b1;

      repeat (8) @(negedge clk);
      bfm_offer = '0;

      bfm_reset(4);
      out_ready = '1;

      // No pre-reset beat may reappear, and quiet combinational inputs cannot
      // originate one either.
      repeat (8) begin
        @(negedge clk);
        if (out_valid !== '0)
          fail("X2", "a beat survived reset or appeared while all inputs were quiet");
      end
    end
  endtask

  task automatic fairness_one(input int j, input int mask_i);
    int k;
    int target;
    int start;
    begin
      @(negedge clk);
      drain($sformatf("fairness setup output %0d mask %0x", j, mask_i));

      @(negedge clk);
      out_ready = '1;
      auto_rotate = 1'b0;
      bfm_offer = '0;

      fair_out = j;
      fair_mask = mask_i;
      fair_m = 0;
      fair_transfers = 0;
      fair_hist.delete();

      for (k = 0; k < N_IN; k = k + 1) begin
        if (mask_i & (1 << k)) begin
          fair_m = fair_m + 1;
          bfm_next_data[k] = fresh_data(k);
          bfm_next_sel[k] = j;
        end
      end

      target = 8 * fair_m + 8;
      bfm_offer = fair_mask;
      fair_en = 1'b1;

      start = mon_cycle;
      while ((fair_transfers < target) &&
             ((mon_cycle - start) < 4000)) begin
        @(negedge clk);
      end

      if (fair_transfers < target)
        fail("A2/R4", $sformatf(
             "output %0d produced only %0d of %0d transfers for mask %0x",
             j, fair_transfers, target, mask_i));

      fair_en = 1'b0;
      drain($sformatf("fairness output %0d mask %0x", j, mask_i));
    end
  endtask

// ---------------------------------------------------------------------------
// Test sequence
// ---------------------------------------------------------------------------

  initial begin
    done = 1'b0;
    any_clock_edge = 1'b0;
    auto_rotate = 1'b0;
    fair_en = 1'b0;
    mon_cycle = 0;
    serial = 0;
    accept_tag = 0;
    epoch_accepted = 0;
    epoch_delivered = 0;
    pending_q.delete();
    delivered_q.delete();
    fair_hist.delete();

    bfm_reset(5);

    // X2/R6: a quiet, freshly reset unit cannot deliver a beat.
    repeat (4) begin
      @(negedge clk);
      if (out_valid !== '0)
        fail("X2/R6", "output active after reset with no accepted input beat");
    end

    // Routing, payload, source index, ordering, duplication/loss, stability,
    // and same-edge combinational handshakes under varied backpressure.
    run_traffic(450);

    // No global stall and no head-of-line blocking across inputs.
    for (int s = 0; s < N_OUT; s = s + 1)
      independence_one(s);

    // Explicit attempts to make an already offered beat move or disappear.
    for (int j = 0; j < N_OUT; j = j + 1)
      stability_one(j);

    reset_with_activity();

    // Exhaust every nontrivial contender subset on every output. No initial
    // arbitration phase is assumed.
    for (int j = 0; j < N_OUT; j = j + 1) begin
      for (int m = 1; m < (1 << N_IN); m = m + 1) begin
        if ($countones(m) >= 2)
          fairness_one(j, m);
      end
    end

    // Final post-reset traffic and complete drain.
    run_traffic(200);

    if (epoch_accepted == 0)
      fail("X3", "no input beat was ever accepted");
    if (pending_q.size() != 0)
      fail("R4", "accepted beats remained undelivered at the final verdict");

    done = 1'b1;
    $display("route_xbar_tb: accepted %0d and delivered %0d beats since final reset",
             epoch_accepted, epoch_delivered);
    $display("RESULT: PASS");
    $finish;
  end

endmodule
