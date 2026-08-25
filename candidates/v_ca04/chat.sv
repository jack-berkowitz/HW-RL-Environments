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

  route_xbar #(
    .N_IN(N_IN),
    .N_OUT(N_OUT),
    .DATA_W(DW),
    .SEL_W(SW),
    .IDX_W(IW)
  ) dut (
    .clk_i(clk),
    .rst_ni(rst_n),
    .in_data_i(in_data),
    .in_sel_i(in_sel),
    .in_valid_i(in_valid),
    .in_ready_o(in_ready),
    .out_data_o(out_data),
    .out_idx_o(out_idx),
    .out_valid_o(out_valid),
    .out_ready_i(out_ready)
  );

  // Convenience slicers.
  function automatic logic [DW-1:0] bfm_odata(input int j);
    return out_data[j*DW +: DW];
  endfunction

  function automatic logic [IW-1:0] bfm_oidx(input int j);
    return out_idx[j*IW +: IW];
  endfunction

  // ---- what you drive ------------------------------------------------------
  logic [N_IN-1:0] bfm_offer;
  logic [DW-1:0]   bfm_next_data [N_IN];
  logic [SW-1:0]   bfm_next_sel  [N_IN];

  // Registered handshake: bfm_accepted[k] is high for the cycle following the
  // rising edge on which input k's beat was taken.
  logic [N_IN-1:0] bfm_accepted;

  always @(posedge clk)
    bfm_accepted <= (rst_n ? (in_valid & in_ready) : '0);

  always @(negedge clk) begin
    if (!rst_n) begin
      in_valid = '0;
    end else begin
      for (int k = 0; k < N_IN; k++) begin
        if (bfm_accepted[k])
          in_valid[k] = 1'b0;

        if (!in_valid[k] && bfm_offer[k]) begin
          in_data[k*DW +: DW] = bfm_next_data[k];
          in_sel[k*SW +: SW]  = bfm_next_sel[k];
          in_valid[k]         = 1'b1;
        end
      end
    end
  end

  task automatic bfm_ready(input logic [N_OUT-1:0] v);
    out_ready = v;
  endtask

  // ---- idle everything at time zero ----------------------------------------
  initial begin
    in_data = '0;
    in_sel = '0;
    in_valid = '0;
    out_ready = '1;
    bfm_offer = '0;

    for (int k = 0; k < N_IN; k++) begin
      bfm_next_data[k] = '0;
      bfm_next_sel[k] = '0;
    end
  end


  // ---------------------------------------------------------------------------
  // TESTBENCH CHECKER
  // ---------------------------------------------------------------------------

  localparam int MAX_Q = 2048;

  logic [DW-1:0] exp_data [0:N_IN-1][0:N_OUT-1][0:MAX_Q-1];
  integer exp_head [0:N_IN-1][0:N_OUT-1];
  integer exp_tail [0:N_IN-1][0:N_OUT-1];

  logic [N_OUT-1:0] stall_hold;
  logic [DW-1:0] stall_data [0:N_OUT-1];
  logic [IW-1:0] stall_idx [0:N_OUT-1];

  integer seq_ctr [0:N_IN-1];

  integer mon_k;
  integer mon_j;
  integer mon_dst;
  integer mon_src;
  integer mon_slot;
  logic [DW-1:0] mon_word;

  bit verdict_done = 1'b0;
  bit first_clock_seen = 1'b0;


  function automatic logic [DW-1:0] tb_idata(input int k);
    return in_data[k*DW +: DW];
  endfunction

  function automatic logic [SW-1:0] tb_isel(input int k);
    return in_sel[k*SW +: SW];
  endfunction

  function automatic logic [DW-1:0] make_data(
      input int k,
      input int j,
      input int n
  );
    logic [DW-1:0] tmp;
    begin
      // Deterministic but bit-dense payloads: across the test run every payload
      // bit takes both values, so R2 is not tested only with sparse counters.
      tmp = 32'hC3A5_C85C;
      tmp = tmp ^ (32'h9E37_79B9 * n);
      tmp = tmp ^ (32'h1020_4081 * k);
      tmp = tmp ^ (32'h0101_0101 * j);
      make_data = tmp;
    end
  endfunction

  function automatic int pending_total;
    int a;
    int b;
    int total_v;
    begin
      total_v = 0;
      for (a = 0; a < N_IN; a = a + 1) begin
        for (b = 0; b < N_OUT; b = b + 1) begin
          total_v = total_v + (exp_tail[a][b] - exp_head[a][b]);
        end
      end
      pending_total = total_v;
    end
  endfunction

  task automatic fail_clause(
      input string clause_name,
      input string detail
  );
    begin
      if (!verdict_done) begin
        verdict_done = 1'b1;
        $display("FAIL [%s] cycle=%0d: %s", clause_name, bfm_cycle, detail);
        $display("RESULT: FAIL");
        $finish;
      end
    end
  endtask

  task automatic pass_test;
    begin
      if (!verdict_done) begin
        verdict_done = 1'b1;
        $display("RESULT: PASS");
        $finish;
      end
    end
  endtask

  // The main scoreboard samples handshakes AT the rising edge.  Accepted input
  // beats are entered before output transfers are checked, so a legal
  // zero-latency combinational transfer can be accepted and delivered on the
  // same edge.
  always @(posedge clk) begin
    if (!rst_n) begin
      for (mon_k = 0; mon_k < N_IN; mon_k = mon_k + 1) begin
        for (mon_j = 0; mon_j < N_OUT; mon_j = mon_j + 1) begin
          exp_head[mon_k][mon_j] = 0;
          exp_tail[mon_k][mon_j] = 0;
        end
      end

      stall_hold = '0;

      // Do not judge the pre-edge value at the very first clock in the
      // simulation: X1 explicitly says the registers are undefined before any
      // clock edge has occurred.  Every later reset edge is checked normally.
      if (first_clock_seen) begin
        if (|(out_valid & out_ready))
          fail_clause("X1", "an output transfer completed while reset was asserted");
      end

      first_clock_seen = 1'b1;

    end else begin
      first_clock_seen = 1'b1;

      // Record every accepted input beat by source and selected output.
      for (mon_k = 0; mon_k < N_IN; mon_k = mon_k + 1) begin
        if (in_valid[mon_k] && in_ready[mon_k]) begin
          mon_dst = tb_isel(mon_k);

          if ((exp_tail[mon_k][mon_dst] - exp_head[mon_k][mon_dst]) >= MAX_Q)
            fail_clause("R4", "testbench pending-beat storage overflowed");

          mon_slot = exp_tail[mon_k][mon_dst] % MAX_Q;
          exp_data[mon_k][mon_dst][mon_slot] = tb_idata(mon_k);
          exp_tail[mon_k][mon_dst] = exp_tail[mon_k][mon_dst] + 1;
        end
      end

      // A3: once an output has made an offer under backpressure, neither valid,
      // payload nor source index may change until ready is sampled high.
      for (mon_j = 0; mon_j < N_OUT; mon_j = mon_j + 1) begin
        if (stall_hold[mon_j]) begin
          if (!out_valid[mon_j])
            fail_clause("A3", "an output withdrew valid while stalled");

          if (bfm_odata(mon_j) !== stall_data[mon_j])
            fail_clause("A3", "an output changed payload while stalled");

          if (bfm_oidx(mon_j) !== stall_idx[mon_j])
            fail_clause("A3", "an output changed source index while stalled");

          if (out_ready[mon_j])
            stall_hold[mon_j] = 1'b0;
        end else begin
          if (out_valid[mon_j] && !out_ready[mon_j]) begin
            stall_hold[mon_j] = 1'b1;
            stall_data[mon_j] = bfm_odata(mon_j);
            stall_idx[mon_j] = bfm_oidx(mon_j);
          end
        end
      end

      // Validate every output transfer.  The output source index selects the
      // bookkeeping FIFO; no search by payload value is performed.
      for (mon_j = 0; mon_j < N_OUT; mon_j = mon_j + 1) begin
        if (out_valid[mon_j] && out_ready[mon_j]) begin
          mon_src = bfm_oidx(mon_j);

          if (exp_head[mon_src][mon_j] == exp_tail[mon_src][mon_j])
            fail_clause(
                "R1/R3/R4",
                "output transferred a beat not owed by the reported source/output pair"
            );

          mon_slot = exp_head[mon_src][mon_j] % MAX_Q;
          mon_word = exp_data[mon_src][mon_j][mon_slot];

          if (bfm_odata(mon_j) !== mon_word)
            fail_clause(
                "R2/R3/R5",
                "output payload/source did not match the next accepted beat for that input/output pair"
            );

          exp_head[mon_src][mon_j] = exp_head[mon_src][mon_j] + 1;
        end
      end
    end
  end


  // ---------------------------------------------------------------------------
  // STIMULUS HELPERS
  // ---------------------------------------------------------------------------

  task automatic set_ready_safe(input logic [N_OUT-1:0] v);
    begin
      @(negedge clk);
      bfm_ready(v);
    end
  endtask

  task automatic stop_all_offers;
    begin
      // bfm_offer is sampled by the provided driver on the falling edge, so it
      // is changed here on a rising edge.  Existing in_valid offers are NOT
      // withdrawn; H2 remains satisfied until the DUT accepts them.
      @(posedge clk);
      bfm_offer = '0;
    end
  endtask

  task automatic drain_all(
      input int max_cycles,
      input string clause_name
  );
    int n;
    bit quiet_seen;
    begin
      stop_all_offers();
      set_ready_safe('1);

      n = 0;
      quiet_seen = 1'b0;

      while ((n < max_cycles) && !quiet_seen) begin
        @(negedge clk);

        if ((in_valid == '0) &&
            (out_valid == '0) &&
            (pending_total() == 0)) begin
          quiet_seen = 1'b1;
        end

        n = n + 1;
      end

      if (!quiet_seen)
        fail_clause(
            clause_name,
            "accepted/offered traffic did not completely drain within the bounded test window"
        );
    end
  endtask

  task automatic send_stream(
      input int k,
      input int j,
      input int beat_count
  );
    int accepted_v;
    int wait_v;
    bit hs_v;
    begin
      accepted_v = 0;
      wait_v = 0;

      @(posedge clk);
      bfm_next_sel[k] = j;
      bfm_next_data[k] = make_data(k, j, seq_ctr[k]);
      bfm_offer[k] = 1'b1;

      while (accepted_v < beat_count) begin
        @(posedge clk);

        hs_v = in_valid[k] && in_ready[k];

        if (in_valid[k]) begin
          if (hs_v) begin
            accepted_v = accepted_v + 1;
            wait_v = 0;
            seq_ctr[k] = seq_ctr[k] + 1;

            if (accepted_v == beat_count) begin
              bfm_offer[k] = 1'b0;
            end else begin
              bfm_next_sel[k] = j;
              bfm_next_data[k] = make_data(k, j, seq_ctr[k]);
            end
          end else begin
            wait_v = wait_v + 1;

            if (wait_v >= 32)
              fail_clause(
                  "X3",
                  "a beat bound for a continuously-ready output was not accepted within 32 cycles"
              );
          end
        end
      end
    end
  endtask

  task automatic test_route_matrix;
    int k;
    int j;
    begin
      set_ready_safe('1);

      // Every input is sent to every output.  Two beats per pair exercise the
      // low-index packing rules as well as routing/payload/index bookkeeping.
      for (k = 0; k < N_IN; k = k + 1) begin
        for (j = 0; j < N_OUT; j = j + 1) begin
          send_stream(k, j, 2);
        end
      end

      drain_all(4096, "R1/R2/R3/R4/R5");
    end
  endtask

  task automatic test_same_input_order;
    begin
      set_ready_safe('1);

      // A longer run from one input to one output directly checks R5.  The
      // scoreboard permits arbitrary latency but never permits this FIFO order
      // to change.
      send_stream(2, 3, 12);

      drain_all(4096, "R4/R5");
    end
  endtask

  task automatic run_fairness(
      input logic [N_IN-1:0] member_mask,
      input int out_j,
      input int transfer_goal,
      input string clause_name
  );
    logic [IW-1:0] hist [0:63];
    int member_count;
    int got;
    int cycles_v;
    int k;
    int w;
    int t;
    bit member_seen;
    begin
      member_count = 0;
      for (k = 0; k < N_IN; k = k + 1) begin
        if (member_mask[k])
          member_count = member_count + 1;
      end

      if ((member_count < 2) || (transfer_goal > 64))
        fail_clause("A2", "internal fairness-test configuration error");

      drain_all(4096, "R4");
      set_ready_safe('1);

      @(posedge clk);
      for (k = 0; k < N_IN; k = k + 1) begin
        if (member_mask[k]) begin
          bfm_next_sel[k] = out_j;
          bfm_next_data[k] = make_data(k, out_j, seq_ctr[k]);
          bfm_offer[k] = 1'b1;
        end
      end

      got = 0;
      cycles_v = 0;

      while ((got < transfer_goal) && (cycles_v < 4096)) begin
        @(posedge clk);

        // Keep the next beat distinct while maintaining a continuous offer.
        for (k = 0; k < N_IN; k = k + 1) begin
          if (member_mask[k] && in_valid[k] && in_ready[k]) begin
            seq_ctr[k] = seq_ctr[k] + 1;
            bfm_next_sel[k] = out_j;
            bfm_next_data[k] = make_data(k, out_j, seq_ctr[k]);
          end
        end

        if (out_valid[out_j] && out_ready[out_j]) begin
          hist[got] = bfm_oidx(out_j);
          got = got + 1;
        end

        cycles_v = cycles_v + 1;
      end

      if (got < transfer_goal)
        fail_clause(
            "A2/I1/R4",
            "continuous contenders did not produce the required bounded set of output transfers"
        );

      // L2 leaves the starting rotation free.  Therefore no particular first
      // source is required.  Instead, inspect every sliding |S|-transfer window.
      for (w = 0; w <= (transfer_goal - member_count); w = w + 1) begin
        for (k = 0; k < N_IN; k = k + 1) begin
          if (member_mask[k]) begin
            member_seen = 1'b0;

            for (t = 0; t < member_count; t = t + 1) begin
              if (hist[w+t] == k)
                member_seen = 1'b1;
            end

            if (!member_seen)
              fail_clause(
                  clause_name,
                  "a continuously-offering contender was absent from a |S|-transfer fairness window"
              );
          end
        end
      end

      bfm_offer = '0;
      drain_all(4096, "R4/A2");
    end
  endtask

  task automatic test_independence;
    int n;
    bit accepted_1;
    bit moved_1;
    begin
      drain_all(4096, "R4");

      // Output 0 is blocked.  Output 1 remains ready.
      set_ready_safe(4'b1110);

      @(posedge clk);
      bfm_next_sel[0] = 0;
      bfm_next_data[0] = make_data(0, 0, seq_ctr[0]);
      bfm_next_sel[1] = 1;
      bfm_next_data[1] = make_data(1, 1, seq_ctr[1]);
      bfm_offer[0] = 1'b1;
      bfm_offer[1] = 1'b1;

      accepted_1 = 1'b0;
      moved_1 = 1'b0;
      n = 0;

      // First eligible rising edge.  Turn off future re-offers immediately;
      // current in_valid beats remain held by the provided driver until taken.
      @(posedge clk);

      if (in_valid[1] && in_ready[1]) begin
        accepted_1 = 1'b1;
        seq_ctr[1] = seq_ctr[1] + 1;
      end

      if (out_valid[1] && out_ready[1])
        moved_1 = 1'b1;

      bfm_offer[0] = 1'b0;
      bfm_offer[1] = 1'b0;

      // I2 + X3: the blocked input/output pair must not prevent input 1 from
      // being accepted within the explicit 32-cycle liveness bound.
      while ((n < 31) && !accepted_1) begin
        @(posedge clk);

        if (in_valid[1] && in_ready[1]) begin
          accepted_1 = 1'b1;
          seq_ctr[1] = seq_ctr[1] + 1;
        end

        if (out_valid[1] && out_ready[1])
          moved_1 = 1'b1;

        n = n + 1;
      end

      if (!accepted_1)
        fail_clause(
            "I2/X3",
            "a blocked unrelated output prevented another input from being accepted within 32 cycles"
        );

      // I1 concerns movement on the independent output.  Its latency is free,
      // so use a generous bounded completion window rather than requiring any
      // particular cycle or combinational/register choice.
      n = 0;
      while ((n < 4096) && !moved_1) begin
        @(posedge clk);

        if (out_valid[1] && out_ready[1])
          moved_1 = 1'b1;

        n = n + 1;
      end

      if (!moved_1)
        fail_clause(
            "I1",
            "a not-ready output prevented a beat from moving on an independent ready output"
        );

      set_ready_safe('1);
      drain_all(4096, "R4/I1/I2");
    end
  endtask

  task automatic test_stall_stability;
    int k;
    int n;
    int hold_cycles;
    bit saw_offer;
    begin
      drain_all(4096, "R4");

      // Hold output 2 blocked and make three inputs contend for it.  Legal
      // implementations are allowed to wait for ready before asserting valid;
      // if they do assert valid, the always-on A3 checker above requires the
      // selected beat to remain immutable throughout the stall.
      set_ready_safe(4'b1011);

      @(posedge clk);
      for (k = 0; k < 3; k = k + 1) begin
        bfm_next_sel[k] = 2;
        bfm_next_data[k] = make_data(k, 2, seq_ctr[k]);
        bfm_offer[k] = 1'b1;
      end

      saw_offer = 1'b0;
      n = 0;

      while ((n < 64) && !saw_offer) begin
        @(posedge clk);

        for (k = 0; k < 3; k = k + 1) begin
          if (in_valid[k] && in_ready[k]) begin
            seq_ctr[k] = seq_ctr[k] + 1;
            bfm_next_sel[k] = 2;
            bfm_next_data[k] = make_data(k, 2, seq_ctr[k]);
          end
        end

        if (out_valid[2])
          saw_offer = 1'b1;

        n = n + 1;
      end

      if (saw_offer) begin
        // Keep the output blocked for several more cycles.  Any withdrawal or
        // re-arbitration of the offered beat is caught by the A3 monitor.
        hold_cycles = 0;
        while (hold_cycles < 8) begin
          @(posedge clk);

          for (k = 0; k < 3; k = k + 1) begin
            if (in_valid[k] && in_ready[k]) begin
              seq_ctr[k] = seq_ctr[k] + 1;
              bfm_next_sel[k] = 2;
              bfm_next_data[k] = make_data(k, 2, seq_ctr[k]);
            end
          end

          hold_cycles = hold_cycles + 1;
        end
      end

      bfm_offer = '0;
      set_ready_safe('1);
      drain_all(4096, "R4/A3");
    end
  endtask

  task automatic test_reset_quiet;
    int k;
    begin
      drain_all(4096, "R4");

      // Assert reset away from the sampling edge and keep all sources quiet.
      @(negedge clk);
      rst_n = 1'b0;

      for (k = 0; k < 3; k = k + 1)
        @(posedge clk);

      @(negedge clk);
      rst_n = 1'b1;

      // X2: no stale delivery may emerge after reset release.
      for (k = 0; k < 8; k = k + 1) begin
        @(posedge clk);

        if (|out_valid)
          fail_clause("X2", "a stale output beat remained after reset release");
      end

      if (pending_total() != 0)
        fail_clause("X2", "scoreboard still contained an owed beat after reset");
    end
  endtask

  // This optional test strengthens the asynchronous-reset check when the DUT
  // architecture permits a buffered beat to be held at an output while every
  // input is already quiet.  A purely combinational legal implementation need
  // not ever create such a state, so absence of the opportunity is not a fail.
  task automatic opportunistic_async_probe;
    int k;
    int n;
    bit all_quiet;
    bit got_internal_hold;
    begin
      drain_all(4096, "R4");
      set_ready_safe(4'b1011);

      @(posedge clk);
      bfm_next_sel[0] = 2;
      bfm_next_data[0] = make_data(0, 2, seq_ctr[0]);
      bfm_offer[0] = 1'b1;

      // Prevent a second beat while preserving the first offer until accepted.
      @(posedge clk);
      if (in_valid[0] && in_ready[0])
        seq_ctr[0] = seq_ctr[0] + 1;
      bfm_offer[0] = 1'b0;

      got_internal_hold = 1'b0;
      n = 0;

      while ((n < 32) && !got_internal_hold) begin
        @(negedge clk);

        all_quiet = 1'b1;
        for (k = 0; k < N_IN; k = k + 1) begin
          if (in_valid[k])
            all_quiet = 1'b0;
        end

        if (all_quiet && out_valid[2] && (pending_total() > 0))
          got_internal_hold = 1'b1;

        n = n + 1;
      end

      if (got_internal_hold) begin
        // The held beat is internal (all inputs are quiet).  Make its output
        // ready at the same off-edge on which reset is asserted.  X1 then
        // requires that no transfer complete at the next rising edge.  A DUT
        // whose state only clears synchronously will expose the stale valid at
        // that edge; an asynchronous reset will have cancelled it beforehand.
        out_ready[2] = 1'b1;
        rst_n = 1'b0;

        repeat (3) @(posedge clk);

        @(negedge clk);
        rst_n = 1'b1;

        set_ready_safe('1);

        repeat (8) begin
          @(posedge clk);
          if (|out_valid)
            fail_clause("X2", "a reset-cancelled buffered beat reappeared after reset");
        end
      end else begin
        set_ready_safe('1);
        drain_all(4096, "R4");
      end
    end
  endtask


  // ---------------------------------------------------------------------------
  // WATCHDOG
  // ---------------------------------------------------------------------------
  initial begin
    #2_000_000;
    if (!verdict_done) begin
      verdict_done = 1'b1;
      $display("FAIL [termination]: watchdog expired before a verdict");
      $display("RESULT: FAIL");
      $finish;
    end
  end


  // ---------------------------------------------------------------------------
  // TEST SEQUENCE
  // ---------------------------------------------------------------------------
  initial begin
    // Initialise checker-side bookkeeping that is not reset by DUT reset.
    for (int k = 0; k < N_IN; k++)
      seq_ctr[k] = 1;

    // Initial reset.  Inputs are quiet, so X1 is observed from the first rising
    // edge onward without imposing requirements on invalid payload/index bits.
    bfm_reset(5);

    // Give the released, empty crossbar a few clocks.  No stale beat may exist.
    repeat (4) begin
      @(posedge clk);
      if (|out_valid)
        fail_clause("X2", "crossbar originated a beat immediately after reset");
    end

    // Basic liveness, all routing destinations, payload preservation, source
    // index reporting, exact-once delivery, and per-input/per-output order.
    test_route_matrix();
    test_same_input_order();

    // Fairness with three different contender-set sizes.  No assumption is made
    // about which source wins first after reset (L2).
    run_fairness(4'b1111, 0, 20, "A2");
    run_fairness(4'b0111, 1, 18, "A2");
    run_fairness(4'b1010, 3, 14, "A2");

    // Backpressure stability and independent-output/input behaviour.
    test_stall_stability();
    test_independence();

    // Reset must leave the crossbar empty and owing no delivery.  The optional
    // probe additionally distinguishes asynchronous clearing when an internal
    // held-beat state is observable without violating H2/X1's quiet-input note.
    opportunistic_async_probe();
    test_reset_quiet();

    // One final drain proves that every accepted beat in the final epoch was
    // delivered exactly once before declaring success.
    drain_all(4096, "R4");

    pass_test();
  end

endmodule