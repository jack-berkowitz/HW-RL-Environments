module route_xbar_tb;

  // ---------------------------------------------------------------------------
  // PROVIDED PLUMBING -- moves beats, checks nothing.
  // ---------------------------------------------------------------------------
  localparam int N_IN = 4, N_OUT = 4, DW = 32, SW = 2, IW = 2;
  localparam int MAX_PENDING = 2048;

  // ---- clock ---------------------------------------------------------------
  logic clk = 1'b0;
  always #5 clk = ~clk;

  int bfm_cycle = 0;
  always @(posedge clk) if (rst_n) bfm_cycle <= bfm_cycle + 1;

  // ---- reset ---------------------------------------------------------------
  logic rst_n = 1'b0;

  task automatic bfm_reset(input int cycles = 5);
    @(negedge clk);
    rst_n = 1'b0;
    repeat (cycles) @(posedge clk);
    @(negedge clk);
    rst_n = 1'b1;
  endtask

  // ---- signals and DUT -----------------------------------------------------
  logic [N_IN*DW-1:0]  in_data;
  logic [N_IN*SW-1:0]  in_sel;
  logic [N_IN-1:0]     in_valid, in_ready;
  logic [N_OUT*DW-1:0] out_data;
  logic [N_OUT*IW-1:0] out_idx;
  logic [N_OUT-1:0]    out_valid, out_ready;

  route_xbar #(
    .N_IN(N_IN), .N_OUT(N_OUT), .DATA_W(DW), .SEL_W(SW), .IDX_W(IW)
  ) dut (
    .clk_i(clk), .rst_ni(rst_n),
    .in_data_i(in_data), .in_sel_i(in_sel),
    .in_valid_i(in_valid), .in_ready_o(in_ready),
    .out_data_o(out_data), .out_idx_o(out_idx),
    .out_valid_o(out_valid), .out_ready_i(out_ready)
  );

  function automatic logic [DW-1:0] bfm_odata(input int j);
    return out_data[j*DW +: DW];
  endfunction

  function automatic logic [IW-1:0] bfm_oidx(input int j);
    return out_idx[j*IW +: IW];
  endfunction

  // ---- what stimulus drives -----------------------------------------------
  logic [N_IN-1:0] bfm_offer;
  logic [DW-1:0]   bfm_next_data [N_IN];
  logic [SW-1:0]   bfm_next_sel  [N_IN];

  logic [N_IN-1:0] bfm_accepted;
  always @(posedge clk)
    bfm_accepted <= (rst_n ? (in_valid & in_ready) : '0);

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
  // VERDICT HANDLING
  // ---------------------------------------------------------------------------
  bit verdict_done = 1'b0;

  task automatic fail_now(input string msg);
    if (!verdict_done) begin
      verdict_done = 1'b1;
      $display("FAIL: %s", msg);
      $display("RESULT: FAIL");
      $finish;
    end
  endtask

  task automatic pass_now;
    if (!verdict_done) begin
      verdict_done = 1'b1;
      $display("RESULT: PASS");
      $finish;
    end
  endtask

  initial begin
    #2_000_000;
    if (!verdict_done) begin
      verdict_done = 1'b1;
      $display("FAIL: watchdog expired before a verdict (termination requirement)");
      $display("RESULT: FAIL");
      $finish;
    end
  end

  // ---------------------------------------------------------------------------
  // SCOREBOARD AND CONTINUOUS CHECKS
  // ---------------------------------------------------------------------------
  // Fixed-size per-(output,input) FIFOs avoid value matching. The source index
  // supplied by the DUT chooses the exact FIFO that must contain the result.
  logic [DW-1:0] exp_mem [N_OUT][N_IN][MAX_PENDING];
  int exp_head [N_OUT][N_IN];
  int exp_tail [N_OUT][N_IN];
  int exp_count[N_OUT][N_IN];
  int pending_total = 0;

  int out_xfers[N_OUT];
  int wait_age[N_IN];

  // A3 held-offer tracking.
  bit hold_active[N_OUT];
  logic [DW-1:0] hold_data[N_OUT];
  logic [IW-1:0] hold_idx[N_OUT];

  // A2 targeted fairness checker controls.
  bit fair_active = 1'b0;
  int fair_target = 0;
  int fair_size = 0;
  logic [N_IN-1:0] fair_members = '0;
  int fair_gap[N_IN];
  int fair_transfer_count = 0;

  always @(posedge clk) begin
    if (!rst_n) begin
      if (out_valid !== '0)
        fail_now("X1: out_valid_o asserted while asynchronous active-low reset is held low");

      pending_total = 0;
      fair_transfer_count = 0;

      for (int j = 0; j < N_OUT; j++) begin
        out_xfers[j] = 0;
        hold_active[j] = 1'b0;
        hold_data[j] = '0;
        hold_idx[j] = '0;

        for (int k = 0; k < N_IN; k++) begin
          exp_head[j][k] = 0;
          exp_tail[j][k] = 0;
          exp_count[j][k] = 0;
        end
      end

      for (int k = 0; k < N_IN; k++) begin
        wait_age[k] = 0;
        fair_gap[k] = 0;
      end

    end else begin

      // X3: if the selected output remains ready, a continuously presented beat
      // may not miss 32 consecutive acceptance opportunities.
      for (int k = 0; k < N_IN; k++) begin
        if (in_valid[k]) begin
          automatic int dst;
          dst = in_sel[k*SW +: SW];

          if ((dst >= 0) && (dst < N_OUT) && out_ready[dst]) begin
            if (in_ready[k]) begin
              wait_age[k] = 0;
            end else begin
              wait_age[k] = wait_age[k] + 1;

              if (wait_age[k] >= 32)
                fail_now("X3: an offered beat with a continuously-ready destination was not accepted within 32 cycles");
            end
          end else begin
            wait_age[k] = 0;
          end
        end else begin
          wait_age[k] = 0;
        end
      end

      // Record all input handshakes first. This permits a legal zero-latency
      // implementation to accept and deliver on the same rising edge.
      for (int k = 0; k < N_IN; k++) begin
        if (in_valid[k] && in_ready[k]) begin
          automatic int dst;
          dst = in_sel[k*SW +: SW];

          if ((dst < 0) || (dst >= N_OUT))
            fail_now("R1: accepted beat carried a destination outside the configured output range");

          if (exp_count[dst][k] >= MAX_PENDING)
            fail_now("R4: scoreboard capacity exhausted; DUT accepted an implausibly large undrained backlog");

          exp_mem[dst][k][exp_tail[dst][k]]
            = in_data[k*DW +: DW];

          if (exp_tail[dst][k] == MAX_PENDING-1)
            exp_tail[dst][k] = 0;
          else
            exp_tail[dst][k] = exp_tail[dst][k] + 1;

          exp_count[dst][k] = exp_count[dst][k] + 1;
          pending_total = pending_total + 1;
        end
      end

      // A3: once an output has been offered while stalled, it is irrevocable.
      for (int j = 0; j < N_OUT; j++) begin
        if (hold_active[j]) begin

          if (!out_valid[j])
            fail_now("A3: out_valid_o was withdrawn before the stalled beat was accepted");

          if (bfm_odata(j) !== hold_data[j])
            fail_now("A3: out_data_o changed while out_valid_o was held against backpressure");

          if (bfm_oidx(j) !== hold_idx[j])
            fail_now("A3: out_idx_o changed while out_valid_o was held against backpressure");

          if (out_valid[j] && out_ready[j])
            hold_active[j] = 1'b0;

        end else if (out_valid[j] && !out_ready[j]) begin
          hold_active[j] = 1'b1;
          hold_data[j] = bfm_odata(j);
          hold_idx[j] = bfm_oidx(j);
        end
      end

      // Check every output transfer against the exact per-source FIFO.
      for (int j = 0; j < N_OUT; j++) begin
        if (out_valid[j] && out_ready[j]) begin
          automatic int src;
          src = bfm_oidx(j);

          out_xfers[j] = out_xfers[j] + 1;

          if ((src < 0) || (src >= N_IN))
            fail_now("R3: out_idx_o did not name a valid input on an output transfer");

          if (exp_count[j][src] <= 0)
            fail_now("R1/R3/R4: output transfer has no accepted outstanding beat for the reported source and destination");

          if (bfm_odata(j) !==
              exp_mem[j][src][exp_head[j][src]])
            fail_now("R2/R5: output payload is modified or same-input/same-output acceptance order was not preserved");

          if (exp_head[j][src] == MAX_PENDING-1)
            exp_head[j][src] = 0;
          else
            exp_head[j][src] = exp_head[j][src] + 1;

          exp_count[j][src] = exp_count[j][src] - 1;
          pending_total = pending_total - 1;

          // A2 is checked only during phases in which the chosen member set is
          // deliberately kept continuously offering to the target output.
          if (fair_active && (j == fair_target)) begin
            fair_transfer_count = fair_transfer_count + 1;

            for (int k = 0; k < N_IN; k++) begin
              if (fair_members[k]) begin
                fair_gap[k] = fair_gap[k] + 1;

                if (k == src)
                  fair_gap[k] = 0;

                if (fair_gap[k] >= fair_size)
                  fail_now("A2: a continuously competing input missed the bounded fairness window");
              end
            end
          end
        end
      end
    end
  end

  // ---------------------------------------------------------------------------
  // STIMULUS HELPERS
  // ---------------------------------------------------------------------------
  task automatic wait_accept_mask(
    input logic [N_IN-1:0] mask,
    input int limit,
    input string clause_msg
  );
    automatic logic [N_IN-1:0] remaining;
    automatic int cycles;

    remaining = mask;
    cycles = 0;

    while ((remaining != '0) && (cycles < limit)) begin
      @(posedge clk);

      for (int k = 0; k < N_IN; k++) begin
        if (remaining[k] &&
            in_valid[k] &&
            in_ready[k]) begin
          bfm_offer[k] = 1'b0;
          remaining[k] = 1'b0;
        end
      end

      cycles = cycles + 1;
    end

    if (remaining != '0)
      fail_now(clause_msg);
  endtask


  task automatic wait_pending_empty(
    input int limit,
    input string clause_msg
  );
    automatic int cycles;

    cycles = 0;

    while (cycles < limit) begin
      @(negedge clk);

      if ((pending_total == 0) &&
          (in_valid == '0))
        return;

      cycles = cycles + 1;
    end

    fail_now(clause_msg);
  endtask


  task automatic burst_one_input(
    input int k,
    input int dst,
    input int nbeats,
    input logic [DW-1:0] base_data
  );
    automatic int accepted;
    automatic int cycles;

    accepted = 0;
    cycles = 0;

    @(posedge clk);

    bfm_next_sel[k] = dst[SW-1:0];
    bfm_next_data[k] = base_data;
    bfm_offer[k] = 1'b1;

    while ((accepted < nbeats) &&
           (cycles < (nbeats*40 + 64))) begin

      @(posedge clk);

      if (in_valid[k] && in_ready[k]) begin
        accepted = accepted + 1;

        if (accepted == nbeats) begin
          bfm_offer[k] = 1'b0;
        end else begin
          bfm_next_data[k] = base_data + accepted;
        end
      end

      cycles = cycles + 1;
    end

    if (accepted != nbeats)
      fail_now("X3: same-input burst did not make the required acceptance progress");
  endtask


  // ---------------------------------------------------------------------------
  // DIRECTED TEST PROGRAM
  // ---------------------------------------------------------------------------
  int stim_seq[N_IN];

  initial begin : test_program
    int cycles;
    int before_xfers;
    int held_wait;
    bit saw_stalled_valid;

    // Initial reset and clean release.
    bfm_reset(5);
    repeat (3) @(posedge clk);


    // -----------------------------------------------------------------------
    // Phase 1:
    // Simultaneous one-beat traffic to four distinct outputs.
    // -----------------------------------------------------------------------
    @(posedge clk);

    for (int k = 0; k < N_IN; k++) begin
      bfm_next_data[k] = 32'h1000_0000 + k;
      bfm_next_sel[k] = k[SW-1:0];
      bfm_offer[k] = 1'b1;
    end

    wait_accept_mask(
      4'b1111,
      40,
      "X3/I2: independent ready destinations failed to accept all offered beats within the liveness bound"
    );

    @(negedge clk);
    bfm_ready('1);

    wait_pending_empty(
      512,
      "R4/I1: accepted independent-output beats were not all delivered exactly once"
    );


    // -----------------------------------------------------------------------
    // Phase 2:
    // Back-to-back burst from one input to one output.
    // Unique payloads expose R5 ordering faults.
    // -----------------------------------------------------------------------
    burst_one_input(
      0,
      1,
      12,
      32'h2000_0000
    );

    @(negedge clk);
    bfm_ready('1);

    wait_pending_empty(
      1024,
      "R4/R5: same-input same-output burst did not drain exactly once and in acceptance order"
    );


    // -----------------------------------------------------------------------
    // Phase 3:
    // Two-way bounded fairness.
    // Starting rotation is deliberately unconstrained.
    // -----------------------------------------------------------------------
    @(posedge clk);

    for (int k = 0; k < N_IN; k++) begin
      stim_seq[k] = 0;
      bfm_offer[k] = 1'b0;
    end

    bfm_next_sel[0] = 2;
    bfm_next_sel[1] = 2;

    bfm_next_data[0] = 32'h3000_0000;
    bfm_next_data[1] = 32'h3100_0000;

    bfm_offer[0] = 1'b1;
    bfm_offer[1] = 1'b1;

    // Let both offers become established.
    repeat (2) begin
      @(posedge clk);

      for (int k = 0; k < 2; k++) begin
        if (in_valid[k] && in_ready[k]) begin
          stim_seq[k] = stim_seq[k] + 1;

          bfm_next_data[k] =
            (k == 0 ? 32'h3000_0000 :
                      32'h3100_0000)
            + stim_seq[k];
        end
      end
    end

    @(negedge clk);

    fair_members = 4'b0011;
    fair_target = 2;
    fair_size = 2;
    fair_transfer_count = 0;

    for (int k = 0; k < N_IN; k++)
      fair_gap[k] = 0;

    fair_active = 1'b1;

    cycles = 0;

    while ((fair_transfer_count < 20) &&
           (cycles < 1024)) begin

      @(posedge clk);

      for (int k = 0; k < 2; k++) begin
        if (in_valid[k] && in_ready[k]) begin
          stim_seq[k] = stim_seq[k] + 1;

          bfm_next_data[k] =
            (k == 0 ? 32'h3000_0000 :
                      32'h3100_0000)
            + stim_seq[k];
        end
      end

      cycles = cycles + 1;
    end

    if (fair_transfer_count < 20)
      fail_now("A2/R4: two-way contention failed to produce enough output transfers to exercise the fairness bound");

    @(negedge clk);
    fair_active = 1'b0;

    @(posedge clk);
    bfm_offer[0] = 1'b0;
    bfm_offer[1] = 1'b0;

    wait_pending_empty(
      4096,
      "R4: two-way fairness phase left accepted beats undelivered"
    );


    // -----------------------------------------------------------------------
    // Phase 4:
    // Four-way bounded fairness.
    // Every four consecutive transfers must contain every source.
    // -----------------------------------------------------------------------
    @(posedge clk);

    for (int k = 0; k < N_IN; k++) begin
      stim_seq[k] = 0;
      bfm_next_sel[k] = 3;
      bfm_next_data[k] =
        32'h4000_0000 + (k << 20);
      bfm_offer[k] = 1'b1;
    end

    repeat (2) begin
      @(posedge clk);

      for (int k = 0; k < N_IN; k++) begin
        if (in_valid[k] && in_ready[k]) begin
          stim_seq[k] = stim_seq[k] + 1;

          bfm_next_data[k] =
            32'h4000_0000 +
            (k << 20) +
            stim_seq[k];
        end
      end
    end

    @(negedge clk);

    fair_members = 4'b1111;
    fair_target = 3;
    fair_size = 4;
    fair_transfer_count = 0;

    for (int k = 0; k < N_IN; k++)
      fair_gap[k] = 0;

    fair_active = 1'b1;

    cycles = 0;

    while ((fair_transfer_count < 32) &&
           (cycles < 1536)) begin

      @(posedge clk);

      for (int k = 0; k < N_IN; k++) begin
        if (in_valid[k] && in_ready[k]) begin
          stim_seq[k] = stim_seq[k] + 1;

          bfm_next_data[k] =
            32'h4000_0000 +
            (k << 20) +
            stim_seq[k];
        end
      end

      cycles = cycles + 1;
    end

    if (fair_transfer_count < 32)
      fail_now("A2/R4: four-way contention failed to produce enough output transfers to exercise the fairness bound");

    @(negedge clk);
    fair_active = 1'b0;

    @(posedge clk);
    bfm_offer = '0;

    wait_pending_empty(
      8192,
      "R4: four-way fairness phase left accepted beats undelivered"
    );


    // -----------------------------------------------------------------------
    // Phase 5:
    // One blocked output/input must not block unrelated traffic.
    // Also exercises A3 whenever the DUT exposes a stalled valid.
    // -----------------------------------------------------------------------
    @(negedge clk);
    bfm_ready(4'b1110);

    before_xfers = out_xfers[1];

    @(posedge clk);

    bfm_next_data[0] = 32'h5000_0000;
    bfm_next_sel[0] = 0;
    bfm_offer[0] = 1'b1;

    bfm_next_data[1] = 32'h5100_0000;
    bfm_next_sel[1] = 1;
    bfm_offer[1] = 1'b1;

    // I2 / X3:
    // input 1's destination is ready even though input 0's is stalled.
    cycles = 0;

    while ((bfm_offer[1] != 1'b0) &&
           (cycles < 40)) begin

      @(posedge clk);

      if (in_valid[1] && in_ready[1])
        bfm_offer[1] = 1'b0;

      // If input 0 was accepted into buffering, stop after that one beat.
      if (in_valid[0] && in_ready[0])
        bfm_offer[0] = 1'b0;

      cycles = cycles + 1;
    end

    if (bfm_offer[1] != 1'b0)
      fail_now("I2/X3: an input bound for a ready output was blocked by another input whose output was stalled");


    // I1:
    // output 1 must make progress while output 0 remains blocked.
    cycles = 0;

    while ((out_xfers[1] == before_xfers) &&
           (cycles < 2048)) begin

      @(posedge clk);

      if (in_valid[0] && in_ready[0])
        bfm_offer[0] = 1'b0;

      cycles = cycles + 1;
    end

    if (out_xfers[1] == before_xfers)
      fail_now("I1: a stalled output prevented an unrelated ready output from making progress");


    // Keep the stall a little longer to exercise A3.
    repeat (8) begin
      @(posedge clk);

      if (in_valid[0] && in_ready[0])
        bfm_offer[0] = 1'b0;
    end

    @(negedge clk);
    bfm_ready('1);


    // If the blocked input had not yet been accepted, it is now subject to X3.
    cycles = 0;

    while ((bfm_offer[0] != 1'b0) &&
           (cycles < 40)) begin

      @(posedge clk);

      if (in_valid[0] && in_ready[0])
        bfm_offer[0] = 1'b0;

      cycles = cycles + 1;
    end

    if (bfm_offer[0] != 1'b0)
      fail_now("X3: formerly blocked input was not accepted within 32 cycles after its output became continuously ready");

    wait_pending_empty(
      4096,
      "R4/I1: backpressure/independence phase failed to deliver every accepted beat exactly once"
    );


    // -----------------------------------------------------------------------
    // Phase 6:
    // Reset while attempting to hold an output valid.
    // -----------------------------------------------------------------------
    @(negedge clk);
    bfm_ready('1);

    before_xfers = out_xfers[2];

    @(posedge clk);

    stim_seq[2] = 0;
    bfm_next_sel[2] = 2;
    bfm_next_data[2] = 32'h6000_0000;
    bfm_offer[2] = 1'b1;


    // Build a short stream.
    cycles = 0;

    while (((out_xfers[2] - before_xfers) < 3) &&
           (cycles < 256)) begin

      @(posedge clk);

      if (in_valid[2] && in_ready[2]) begin
        stim_seq[2] = stim_seq[2] + 1;

        bfm_next_data[2] =
          32'h6000_0000 +
          stim_seq[2];
      end

      cycles = cycles + 1;
    end


    // Stall output 2.
    @(negedge clk);
    out_ready[2] = 1'b0;

    saw_stalled_valid = 1'b0;
    held_wait = 0;

    while (!saw_stalled_valid &&
           (held_wait < 128)) begin

      @(posedge clk);

      if (out_valid[2] &&
          !out_ready[2]) begin

        saw_stalled_valid = 1'b1;
        bfm_offer[2] = 1'b0;

      end else if (in_valid[2] &&
                   in_ready[2]) begin

        stim_seq[2] = stim_seq[2] + 1;

        bfm_next_data[2] =
          32'h6000_0000 +
          stim_seq[2];
      end

      held_wait = held_wait + 1;
    end


    if (!saw_stalled_valid) begin
      @(posedge clk);
      bfm_offer[2] = 1'b0;
    end


    // Assert active-low reset on the opposite clock edge.
    @(negedge clk);

    rst_n = 1'b0;
    out_ready = '1;

    repeat (4) @(posedge clk);

    @(negedge clk);
    rst_n = 1'b1;


    // X2:
    // no pre-reset accepted or held beat may survive reset.
    repeat (20) @(posedge clk);

    if (pending_total != 0)
      fail_now("X2: reset did not clear all outstanding delivery obligations");


    // -----------------------------------------------------------------------
    // Phase 7:
    // Explicit four-way X3 liveness under contention.
    // -----------------------------------------------------------------------
    @(negedge clk);
    bfm_ready('1);

    @(posedge clk);

    for (int k = 0; k < N_IN; k++) begin
      bfm_next_sel[k] = 0;

      bfm_next_data[k] =
        32'h7000_0000 +
        (k << 16);

      bfm_offer[k] = 1'b1;
    end

    wait_accept_mask(
      4'b1111,
      40,
      "X3: under four-way contention to a continuously-ready output, at least one offered beat missed the 32-cycle acceptance bound"
    );

    wait_pending_empty(
      4096,
      "R4: final liveness phase accepted beats that were not delivered exactly once"
    );


    // Final quiet period catches delayed duplicates or stale traffic.
    repeat (20) @(posedge clk);

    if (pending_total != 0)
      fail_now("R4: outstanding beat remained at end of test");

    pass_now();
  end

endmodule