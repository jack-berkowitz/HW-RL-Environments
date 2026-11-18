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
      bfm_next_sel[k] = '0;
    end
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

  typedef struct packed {
    logic [DW-1:0] data;
    logic [IW-1:0] src;
  } exp_t;

  exp_t pending [N_OUT][$];

  int accept_total = 0;
  int deliver_total = 0;
  int seq_no [N_IN];
  int offer_age [N_IN];

  logic [N_OUT-1:0] prev_valid;
  logic [N_OUT-1:0] prev_ready;
  logic [DW-1:0] prev_data [N_OUT];
  logic [IW-1:0] prev_idx [N_OUT];

  logic fair_active;
  int fair_out;
  int fair_size;
  logic [N_IN-1:0] fair_mask;
  int fair_count;
  int fair_hist [4];

  function automatic logic [DW-1:0] mk_data(input int k, input int n);
    return 32'hA0000000 | (k << 26) | n;
  endfunction

  task automatic fail(input string clause, input string msg);
    begin
      $display("FAIL %s at cycle %0d: %s", clause, bfm_cycle, msg);
      $display("RESULT: FAIL");
      $finish;
    end
  endtask

  // Generate a fresh payload for the next beat only after the current one has
  // been accepted. bfm_next_data is not itself sampled by the design.
  always @(posedge clk) begin
    if (rst_n) begin
      for (int k = 0; k < N_IN; k++) begin
        if (in_valid[k] && in_ready[k]) begin
          seq_no[k] = seq_no[k] + 1;
          bfm_next_data[k] = mk_data(k, seq_no[k]);
        end
      end
    end
  end

  always @(posedge clk) begin : scoreboard
    automatic exp_t e;
    automatic int found;
    automatic int first;
    automatic int m;
    automatic int h;
    automatic logic [N_IN-1:0] seen;

    if (!rst_n) begin
      // Inputs are quiet whenever the stimulus asserts reset, so even a
      // combinational implementation must not complete an output transfer.
      if (out_valid !== '0)
        fail("X1", "out_valid was nonzero while reset was asserted with quiet inputs");

      for (int j = 0; j < N_OUT; j++) begin
        pending[j].delete();
        prev_valid[j] = 1'b0;
        prev_ready[j] = 1'b0;
        prev_data[j] = '0;
        prev_idx[j] = '0;
      end
      accept_total = 0;
      deliver_total = 0;
      fair_count = 0;
      for (int k = 0; k < N_IN; k++)
        offer_age[k] = 0;
    end else begin
      // A3: an offered, unaccepted output beat cannot be withdrawn or changed.
      for (int j = 0; j < N_OUT; j++) begin
        if (prev_valid[j] && !prev_ready[j]) begin
          if (out_valid[j] !== 1'b1)
            fail("A3", $sformatf("output %0d withdrew a valid beat", j));
          if ((bfm_odata(j) !== prev_data[j]) || (bfm_oidx(j) !== prev_idx[j]))
            fail("A3", $sformatf("output %0d changed data or source under backpressure", j));
        end
      end

      // Record acceptances first, allowing a legal zero-latency implementation
      // to accept and deliver the same beat at this edge.
      for (int k = 0; k < N_IN; k++) begin
        if (in_valid[k] && in_ready[k]) begin
          e.data = in_data[k*DW +: DW];
          e.src = k;
          pending[in_sel[k*SW +: SW]].push_back(e);
          accept_total = accept_total + 1;
        end
      end

      for (int j = 0; j < N_OUT; j++) begin
        if (out_valid[j] && out_ready[j]) begin
          // Find the oldest undelivered beat from this source to this output.
          // Beats from other sources are explicitly allowed to bypass it.
          first = -1;
          for (m = 0; m < pending[j].size(); m++) begin
            if ((first < 0) && (pending[j][m].src == bfm_oidx(j)))
              first = m;
          end

          if (first < 0) begin
            fail("R1/R3/R4/R6",
                 $sformatf("output %0d delivered source %0d with no matching accepted beat",
                           j, bfm_oidx(j)));
          end

          e = pending[j][first];
          if (e.data !== bfm_odata(j))
            fail("R2/R5",
                 $sformatf("output %0d source %0d delivered wrong or out-of-order payload",
                           j, bfm_oidx(j)));

          pending[j].delete(first);
          deliver_total = deliver_total + 1;

          if (fair_active && (j == fair_out)) begin
            for (h = 0; h < 3; h++)
              fair_hist[h] = fair_hist[h+1];
            fair_hist[3] = bfm_oidx(j);
            fair_count = fair_count + 1;

            if (fair_count >= fair_size) begin
              seen = '0;
              for (h = 4-fair_size; h < 4; h++)
                seen[fair_hist[h]] = 1'b1;
              if (seen != fair_mask)
                fail("A2",
                     $sformatf("output %0d violated the %0d-transfer fairness window",
                               j, fair_size));
            end
          end
        end
      end

      // X3: count only cycles in which the offer is held and its selected
      // output is ready. The 32nd such cycle is the last permitted one.
      for (int k = 0; k < N_IN; k++) begin
        if (!in_valid[k] || in_ready[k] ||
            !out_ready[in_sel[k*SW +: SW]]) begin
          offer_age[k] = 0;
        end else begin
          if (offer_age[k] >= 31)
            fail("X3", $sformatf("input %0d was not accepted within 32 cycles", k));
          else
            offer_age[k] = offer_age[k] + 1;
        end
      end

      for (int j = 0; j < N_OUT; j++) begin
        prev_valid[j] = out_valid[j];
        prev_ready[j] = out_ready[j];
        prev_data[j] = bfm_odata(j);
        prev_idx[j] = bfm_oidx(j);
      end
    end
  end

  task automatic wait_deliveries(input int amount, input int limit);
    automatic int start;
    automatic int t;
    begin
      start = deliver_total;
      t = 0;
      while ((t < limit) && ((deliver_total - start) < amount)) begin
        @(negedge clk);
        t = t + 1;
      end
      if ((deliver_total - start) < amount)
        fail("R4/X3", $sformatf("timed out waiting for %0d deliveries", amount));
    end
  endtask

  task automatic quiesce;
    automatic int t;
    begin
      @(negedge clk);
      bfm_offer = '0;
      fair_active = 1'b0;
      bfm_ready('1);
      t = 0;
      while ((t < 2000) &&
             ((in_valid !== '0) || (out_valid !== '0) ||
              (accept_total != deliver_total))) begin
        @(negedge clk);
        t = t + 1;
      end
      if (accept_total != deliver_total)
        fail("R4", "accepted beats were not delivered exactly once while draining");
      if ((in_valid !== '0) || (out_valid !== '0))
        fail("X3/A3", "interface did not become idle while all outputs were ready");
    end
  endtask

  task automatic run_contention(input logic [N_IN-1:0] mask,
                                input int j,
                                input int amount);
    automatic int size;
    begin
      quiesce();
      @(negedge clk);
      size = 0;
      for (int k = 0; k < N_IN; k++) begin
        bfm_next_sel[k] = j;
        bfm_offer[k] = mask[k];
        if (mask[k]) size = size + 1;
      end
      bfm_ready('1);
      fair_out = j;
      fair_mask = mask;
      fair_size = size;
      fair_count = 0;
      fair_active = 1'b1;
      wait_deliveries(amount, 1000);
      quiesce();
    end
  endtask

  initial begin
    fair_active = 1'b0;
    fair_out = 0;
    fair_size = 0;
    fair_mask = '0;
    fair_count = 0;
    prev_valid = '0;
    prev_ready = '0;
    for (int k = 0; k < N_IN; k++) begin
      seq_no[k] = 0;
      offer_age[k] = 0;
    end

    // Initial reset is also the quiet-input X1 test.
    bfm_reset(6);
    for (int k = 0; k < N_IN; k++)
      bfm_next_data[k] = mk_data(k, seq_no[k]);

    // Exercise every input/output pairing, with several outstanding beats.
    for (int round = 0; round < 4; round++) begin
      quiesce();
      @(negedge clk);
      bfm_ready('1);
      for (int k = 0; k < N_IN; k++) begin
        bfm_next_sel[k] = (k + round) % N_OUT;
        bfm_offer[k] = 1'b1;
      end
      wait_deliveries(40, 1000);
    end
    quiesce();

    // Deterministic backpressure on every output, interspersed with traffic.
    @(negedge clk);
    for (int k = 0; k < N_IN; k++) begin
      bfm_next_sel[k] = (k + 1) % N_OUT;
      bfm_offer[k] = 1'b1;
    end
    for (int t = 0; t < 100; t++) begin
      case (t % 5)
        0: bfm_ready(4'b1010);
        1: bfm_ready(4'b0101);
        2: bfm_ready(4'b0011);
        3: bfm_ready(4'b1100);
        default: bfm_ready(4'b1111);
      endcase
      @(negedge clk);
    end
    quiesce();

    // Hold a contended output under backpressure long enough to catch both
    // withdrawal and re-arbitration of an already offered beat.
    @(negedge clk);
    bfm_ready(4'b1011); // output 2 stalled
    for (int k = 0; k < N_IN; k++) begin
      bfm_next_sel[k] = 2;
      bfm_offer[k] = 1'b1;
    end
    begin
      automatic int t;
      t = 0;
      while ((t < 50) && (out_valid[2] !== 1'b1)) begin
        @(negedge clk);
        t = t + 1;
      end
      if (out_valid[2] !== 1'b1)
        fail("X3", "no beat was offered on a contended output");
    end
    repeat (12) @(negedge clk);
    bfm_ready('1);
    wait_deliveries(24, 1000);
    quiesce();

    // I1/I2: input 0 is blocked behind output 0. The other three inputs and
    // outputs must nevertheless continue to transfer.
    @(negedge clk);
    bfm_ready(4'b1110);
    bfm_next_sel[0] = 0;
    bfm_offer[0] = 1'b1;
    repeat (4) @(negedge clk);
    for (int k = 1; k < N_IN; k++) begin
      bfm_next_sel[k] = k;
      bfm_offer[k] = 1'b1;
    end
    begin
      automatic int start;
      automatic int t;
      start = deliver_total;
      t = 0;
      while ((t < 60) && ((deliver_total - start) < 3)) begin
        @(negedge clk);
        t = t + 1;
      end
      if ((deliver_total - start) < 3)
        fail("I1/I2", "a blocked input/output stopped independent traffic");
    end
    quiesce();

    // Full contention on every output checks A2 without assuming a starting
    // rotation. Additional subset sizes check the exact |S| window.
    for (int j = 0; j < N_OUT; j++)
      run_contention(4'b1111, j, 40);
    run_contention(4'b0011, 0, 32);
    run_contention(4'b0101, 1, 32);
    run_contention(4'b0111, 2, 36);
    run_contention(4'b1011, 3, 36);

    // Assert reset with traffic and offered output beats present. Any beat
    // surviving reset must be rejected as an unaccepted/owed delivery.
    quiesce();
    @(negedge clk);
    bfm_ready('0);
    for (int k = 0; k < N_IN; k++) begin
      bfm_next_sel[k] = k;
      bfm_offer[k] = 1'b1;
    end
    repeat (10) @(negedge clk);
    bfm_offer = '0;
    bfm_reset(5);
    bfm_ready('1);
    repeat (5) begin
      @(negedge clk);
      if (out_valid !== '0)
        fail("X2", "a beat or output offer survived reset");
    end

    // A final ordinary traffic phase detects bookkeeping damage after reset.
    @(negedge clk);
    for (int k = 0; k < N_IN; k++) begin
      bfm_next_sel[k] = N_OUT-1-k;
      bfm_offer[k] = 1'b1;
    end
    wait_deliveries(32, 1000);
    quiesce();

    $display("RESULT: PASS");
    $finish;
  end

endmodule
