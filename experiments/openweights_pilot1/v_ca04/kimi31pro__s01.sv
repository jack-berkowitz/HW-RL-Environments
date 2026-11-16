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
        if (bfm_accepted[k]) in_valid[k] = 1'b0;
        if (!in_valid[k] && bfm_offer[k]) begin
          in_data[k*DW +: DW] = bfm_next_data[k];
          in_sel [k*SW +: SW] = bfm_next_sel[k];
          in_valid[k]         = 1'b1;
        end
      end
    end
  end

  task automatic bfm_ready(input logic [N_OUT-1:0] v); out_ready = v; endtask

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

// ---------------------------------------------------------------------------
// Checking and stimulus
// ---------------------------------------------------------------------------

  localparam int DRAIN_LIMIT = 2500;
  localparam int PHASE_LIMIT = 3000;

  typedef logic [DW-1:0] payload_t;

  // Accepted but not yet delivered beats, in acceptance order for each
  // (input, output) pair.
  payload_t pending_q [N_IN][N_OUT][$];
  int pending;

  int accept_count    [N_IN];
  int out_xfer_count  [N_OUT];
  int delivered_count;
  int gen_no          [N_IN];
  int live_cnt        [N_IN];

  // Previous-cycle output offers which were backpressured.
  logic               hold_v [N_OUT];
  logic [DW-1:0]      hold_d [N_OUT];
  logic [IW-1:0]      hold_i [N_OUT];

  bit finished;
  bit quiet_check;
  bit independence_active;

  // Directed fairness-window checking.
  bit                 fair_en;
  int                 fair_j;
  int                 fair_m;
  logic [N_IN-1:0]    fair_mask;
  int                 fair_q[$];

  task automatic fail(input string clause, input string detail);
    begin
      if (!finished) begin
        finished = 1'b1;
        $display("[%0t] CHECK FAILED [%s] %s", $time, clause, detail);
        $display("RESULT: FAIL");
        $finish;
      end
    end
  endtask

  function automatic logic [DW-1:0] make_payload(input int k, input int n);
    make_payload = 32'hC0000000 | ((k & 3) << 24) | (n & 32'h00FFFFFF);
  endfunction

  function automatic int count_mask(input logic [N_IN-1:0] m);
    begin
      count_mask = 0;
      for (int k = 0; k < N_IN; k++)
        if (m[k]) count_mask = count_mask + 1;
    end
  endfunction

  task automatic prime_offer(input int k, input int s);
    begin
      bfm_next_sel[k]  = s;
      bfm_next_data[k] = make_payload(k, gen_no[k]);
      gen_no[k]        = gen_no[k] + 1;
      bfm_offer[k]     = 1'b1;
    end
  endtask

  task automatic clear_model;
    begin
      for (int a = 0; a < N_IN; a++)
        for (int b = 0; b < N_OUT; b++)
          pending_q[a][b].delete();
      pending = 0;
      fair_q.delete();
    end
  endtask

  task automatic note_accept(input int k);
    automatic int s;
    automatic payload_t d;
    begin
      s = in_sel[k*SW +: SW];
      d = in_data[k*DW +: DW];
      pending_q[k][s].push_back(d);
      pending = pending + 1;
      accept_count[k] = accept_count[k] + 1;

      // Prepare a fresh payload for the driver's next offer. This does not
      // alter the currently offered beat.
      bfm_next_data[k] = make_payload(k, gen_no[k]);
      gen_no[k] = gen_no[k] + 1;
    end
  endtask

  task automatic check_fair_transfer(input int j, input int src);
    automatic logic all_now;
    automatic logic [N_IN-1:0] seen;
    automatic int idx;
    begin
      if (fair_en && (j == fair_j)) begin
        all_now = 1'b1;
        for (int k = 0; k < N_IN; k++) begin
          if (fair_mask[k]) begin
            if (!in_valid[k] || (in_sel[k*SW +: SW] != fair_j))
              all_now = 1'b0;
          end
        end

        if (!all_now) begin
          fair_q.delete();
        end else begin
          fair_q.push_back(src);
          if (fair_q.size() > fair_m)
            idx = fair_q.pop_front();

          if (fair_q.size() == fair_m) begin
            seen = '0;
            for (int q = 0; q < fair_q.size(); q++) begin
              idx = fair_q[q];
              if ((idx >= 0) && (idx < N_IN))
                seen[idx] = 1'b1;
            end
            if (seen !== fair_mask) begin
              fail("A2", $sformatf(
                "output %0d: %0d consecutive transfers served inputs %b, expected every member of %b",
                j, fair_m, seen, fair_mask));
            end
          end
        end
      end
    end
  endtask

  task automatic note_transfer(input int j);
    automatic int src;
    automatic payload_t expected_data;
    automatic payload_t got_data;
    begin
      src      = bfm_oidx(j);
      got_data = bfm_odata(j);

      if (pending_q[src][j].size() == 0) begin
        fail("R6/R4", $sformatf(
          "output %0d transferred data %08x with source %0d, but no accepted beat is owed on that route (R1/R3 may be the root cause)",
          j, got_data, src));
      end else begin
        expected_data = pending_q[src][j].pop_front();
        if (got_data !== expected_data) begin
          fail("R2/R5", $sformatf(
            "output %0d, source %0d: delivered %08x, oldest accepted undelivered payload is %08x (also check R1/R3)",
            j, src, got_data, expected_data));
        end
        pending = pending - 1;
        delivered_count = delivered_count + 1;
      end

      out_xfer_count[j] = out_xfer_count[j] + 1;
      check_fair_transfer(j, src);
    end
  endtask

  // All interface sampling is done at the rising edge.
  always @(posedge clk) begin
    if (!rst_n) begin
      clear_model();
      for (int k = 0; k < N_IN; k++) begin
        live_cnt[k] = 0;
        if (k < N_OUT) hold_v[k] = 1'b0;
      end

      // Inputs are quiet whenever this testbench asserts reset, so even a
      // combinational implementation must not originate an output offer.
      if (out_valid !== '0)
        fail("X1", "out_valid was nonzero while reset was asserted with quiet inputs");
    end else begin
      if (quiet_check && (out_valid !== '0))
        fail("X2", "a beat survived reset or was originated while the unit was quiet");

      // A3: an offer which was valid and not ready at the preceding edge must
      // still be present and unchanged now, even if ready has since risen.
      for (int j = 0; j < N_OUT; j++) begin
        if (hold_v[j]) begin
          if (!out_valid[j])
            fail("A3", $sformatf("output %0d withdrew a backpressured offer", j));
          else if (bfm_odata(j) !== hold_d[j])
            fail("A3", $sformatf("output %0d changed payload while backpressured", j));
          else if (bfm_oidx(j) !== hold_i[j])
            fail("A3", $sformatf("output %0d changed source index while backpressured", j));
        end
      end

      // X3. A low ready interval restarts the bound, since the clause applies
      // only while the bound output is continuously ready.
      for (int k = 0; k < N_IN; k++) begin
        if (!in_valid[k] || in_ready[k]) begin
          live_cnt[k] = 0;
        end else if (out_ready[in_sel[k*SW +: SW]]) begin
          live_cnt[k] = live_cnt[k] + 1;
          if (live_cnt[k] >= 32) begin
            if (independence_active)
              fail("I2/X3", $sformatf(
                "input %0d was not accepted within 32 cycles although its output was ready; possible head-of-line blocking", k));
            else
              fail("X3", $sformatf(
                "input %0d was not accepted within 32 cycles with its bound output continuously ready", k));
          end
        end else begin
          live_cnt[k] = 0;
        end
      end

      // Acceptances are entered first so that a legal zero-latency,
      // combinational accept-and-deliver on this same edge is handled.
      for (int k = 0; k < N_IN; k++)
        if (in_valid[k] && in_ready[k])
          note_accept(k);

      for (int j = 0; j < N_OUT; j++)
        if (out_valid[j] && out_ready[j])
          note_transfer(j);

      for (int j = 0; j < N_OUT; j++) begin
        hold_v[j] = out_valid[j] && !out_ready[j];
        if (out_valid[j]) begin
          hold_d[j] = bfm_odata(j);
          hold_i[j] = bfm_oidx(j);
        end
      end
    end
  end

  task automatic drain_all(input int max_cycles);
    automatic int t;
    automatic bit done;
    begin
      bfm_offer = '0;
      @(negedge clk);
      out_ready = '1;
      done = 1'b0;

      for (t = 0; t < max_cycles && !done; t++) begin
        @(negedge clk);
        if ((in_valid == '0) && (out_valid == '0) && (pending == 0))
          done = 1'b1;
      end

      if (!done)
        fail("R4", $sformatf(
          "drain timed out with pending=%0d, in_valid=%b, out_valid=%b; an accepted beat was lost or never delivered",
          pending, in_valid, out_valid));
    end
  endtask

  task automatic offer_one(input int k, input int s);
    automatic int base;
    automatic int t;
    automatic bit got;
    begin
      @(negedge clk);
      out_ready = '1;
      prime_offer(k, s);
      base = accept_count[k];
      got = 1'b0;

      for (t = 0; t < 40 && !got; t++) begin
        @(posedge clk);
        if (accept_count[k] > base) begin
          got = 1'b1;
          bfm_offer[k] = 1'b0;
        end
      end

      if (!got)
        fail("X3", $sformatf("single beat on input %0d was not accepted", k));

      drain_all(DRAIN_LIMIT);
    end
  endtask

  task automatic run_fair(
    input int j,
    input logic [N_IN-1:0] mask,
    input int transfers
  );
    automatic int base;
    automatic int t;
    automatic bit done;
    begin
      drain_all(DRAIN_LIMIT);

      @(negedge clk);
      out_ready = '1;
      bfm_offer = '0;
      fair_q.delete();
      fair_j    = j;
      fair_mask = mask;
      fair_m    = count_mask(mask);

      for (int k = 0; k < N_IN; k++)
        if (mask[k]) prime_offer(k, j);

      fair_en = 1'b1;
      base = out_xfer_count[j];
      done = 1'b0;

      for (t = 0; t < PHASE_LIMIT && !done; t++) begin
        @(posedge clk);
        if ((out_xfer_count[j] - base) >= transfers)
          done = 1'b1;
      end

      @(negedge clk);
      fair_en = 1'b0;
      bfm_offer = '0;

      if (!done)
        fail("R4", $sformatf(
          "timed out waiting for %0d contended transfers on output %0d; only %0d occurred",
          transfers, j, out_xfer_count[j] - base));

      drain_all(DRAIN_LIMIT);
    end
  endtask

  task automatic run_backpressure(
    input int j,
    input int first_k,
    input int second_k
  );
    automatic int t;
    automatic bit saw_valid;
    begin
      drain_all(DRAIN_LIMIT);

      @(negedge clk);
      out_ready = '1;
      out_ready[j] = 1'b0;
      bfm_offer = '0;
      prime_offer(first_k, j);
      saw_valid = 1'b0;

      // A compliant implementation need not assert valid while ready is low,
      // so absence of an offer here is not itself a failure.
      for (t = 0; t < 40 && !saw_valid; t++) begin
        @(posedge clk);
        if (out_valid[j]) saw_valid = 1'b1;
      end

      if (saw_valid) begin
        // Introduce another contender only after the first offer exists.
        // Re-arbitrating or changing the visible beat now violates A3.
        @(negedge clk);
        prime_offer(second_k, j);
        repeat (6) @(posedge clk);

        @(negedge clk);
        out_ready[j] = 1'b1;
        repeat (4) @(posedge clk);
      end

      @(negedge clk);
      out_ready = '1;
      bfm_offer = '0;
      drain_all(DRAIN_LIMIT);
    end
  endtask

  task automatic run_independence;
    automatic int base_d1, base_d2, base_d3;
    automatic int base_a1, base_a2, base_a3;
    automatic int t;
    automatic bit done;
    begin
      drain_all(DRAIN_LIMIT);

      @(negedge clk);
      out_ready = 4'b1110;  // output 0 stopped, all others ready
      bfm_offer = '0;
      prime_offer(0, 0);

      // Let input 0 establish a persistent blocked offer.
      repeat (4) @(posedge clk);

      @(negedge clk);
      prime_offer(1, 1);
      prime_offer(2, 2);
      prime_offer(3, 3);
      independence_active = 1'b1;

      base_d1 = out_xfer_count[1];
      base_d2 = out_xfer_count[2];
      base_d3 = out_xfer_count[3];
      base_a1 = accept_count[1];
      base_a2 = accept_count[2];
      base_a3 = accept_count[3];
      done = 1'b0;

      for (t = 0; t < PHASE_LIMIT && !done; t++) begin
        @(posedge clk);
        if (((out_xfer_count[1] - base_d1) >= 6) &&
            ((out_xfer_count[2] - base_d2) >= 6) &&
            ((out_xfer_count[3] - base_d3) >= 6))
          done = 1'b1;
      end

      if (!done) begin
        if ((accept_count[1] == base_a1) ||
            (accept_count[2] == base_a2) ||
            (accept_count[3] == base_a3))
          fail("I2", "a blocked input prevented another input from being accepted");
        else
          fail("I1", "stopped output 0 prevented transfers on one or more ready outputs");
      end

      @(negedge clk);
      independence_active = 1'b0;
      bfm_offer = '0;
      out_ready = '1;
      drain_all(DRAIN_LIMIT);
    end
  endtask

  task automatic run_async_reset_check;
    automatic int base;
    automatic int t;
    automatic bit got;
    automatic bit quiet;
    begin
      drain_all(DRAIN_LIMIT);

      // Accept traffic with ready high, then stop ready before the next edge.
      // A registered implementation will consequently hold an output offer;
      // a combinational implementation may already have delivered it. Both
      // latitudes are allowed.
      @(negedge clk);
      out_ready = '1;
      bfm_offer = '0;
      prime_offer(0, 0);
      base = accept_count[0];
      got = 1'b0;

      for (t = 0; t < 40 && !got; t++) begin
        @(posedge clk);
        if (accept_count[0] > base) begin
          got = 1'b1;
          bfm_offer[0] = 1'b0;
        end
      end

      if (!got)
        fail("X3", "could not establish a beat for the reset check");

      // Wait until every offered beat has been taken before asserting reset;
      // the source never withdraws an unaccepted offer.
      quiet = 1'b0;
      for (t = 0; t < 40 && !quiet; t++) begin
        @(negedge clk);
        if (in_valid == '0) quiet = 1'b1;
      end
      if (!quiet)
        fail("H2/X3", "input did not become quiet after its offered beats were accepted");

      out_ready = '1;
      out_ready[0] = 1'b0;
      @(posedge clk);

      // Assert reset between active edges. At the next rising edge an
      // asynchronously reset design has already removed any held valid.
      @(negedge clk);
      rst_n = 1'b0;
      repeat (3) @(posedge clk);

      @(negedge clk);
      out_ready = '1;
      rst_n = 1'b1;
      quiet_check = 1'b1;
      repeat (2) @(posedge clk);
      @(negedge clk);
      quiet_check = 1'b0;

      drain_all(DRAIN_LIMIT);
    end
  endtask

  // ---- test sequence --------------------------------------------------------
  initial begin
    finished = 1'b0;
    quiet_check = 1'b0;
    independence_active = 1'b0;
    fair_en = 1'b0;
    fair_j = 0;
    fair_m = 0;
    fair_mask = '0;
    pending = 0;
    delivered_count = 0;

    for (int k = 0; k < N_IN; k++) begin
      accept_count[k] = 0;
      gen_no[k] = 1;
      live_cnt[k] = 0;
      hold_v[k] = 1'b0;
      hold_d[k] = '0;
      hold_i[k] = '0;
      if (k < N_OUT) out_xfer_count[k] = 0;
    end

    bfm_reset(5);

    // X2: no delivery is owed immediately after reset.
    quiet_check = 1'b1;
    repeat (2) @(posedge clk);
    @(negedge clk);
    quiet_check = 1'b0;

    // Exercise every input/output binding, with bookkeeping rather than any
    // assumed latency.
    for (int k = 0; k < N_IN; k++)
      for (int j = 0; j < N_OUT; j++)
        offer_one(k, j);

    // Full contention on every output. Only the fairness window is checked;
    // neither the initial rotation nor a particular rotation order is assumed.
    for (int j = 0; j < N_OUT; j++)
      run_fair(j, 4'b1111, 20);

    // Smaller contender sets check that the bound scales with |S|.
    run_fair(0, 4'b0011, 12);
    run_fair(1, 4'b1100, 12);
    run_fair(1, 4'b0101, 12);
    run_fair(2, 4'b0111, 16);
    run_fair(3, 4'b1011, 16);

    // Backpressure and late-arriving contenders exercise offer stability.
    run_backpressure(0, 3, 0);
    run_backpressure(1, 0, 3);
    run_backpressure(2, 2, 1);
    run_backpressure(3, 1, 2);

    // One stopped output and one blocked input must not stall the others.
    run_independence();

    // Finish with reset while a registered design may hold a beat, followed
    // by a quiet interval to catch post-reset phantom or stale deliveries.
    run_async_reset_check();

    drain_all(DRAIN_LIMIT);

    if (!finished) begin
      $display("All routing, ordering, arbitration, backpressure, independence, reset, and liveness checks completed.");
      finished = 1'b1;
      $display("RESULT: PASS");
      $finish;
    end
  end

endmodule
