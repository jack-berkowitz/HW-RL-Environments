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

// ---------------------------------------------------------------------------
// Checking state and stimulus helpers.
// ---------------------------------------------------------------------------

  typedef struct {
    logic [DW-1:0] data;
    int unsigned   tag;
  } beat_t;

  // Accepted beats, in acceptance order for each (input, output) pair.
  beat_t pending [N_IN][N_OUT][$];

  logic verdict = 1'b0;
  logic mon_started = 1'b0;

  logic [N_OUT-1:0] prev_stall;
  logic [DW-1:0]    prev_data [N_OUT];
  logic [IW-1:0]    prev_idx  [N_OUT];

  int unsigned gen_count [N_IN];
  int unsigned accept_serial;

  logic stress_mode;
  logic [N_IN-1:0] live_mask;
  int live_age [N_IN];

  logic fair_active;
  logic [N_IN-1:0] fair_mask;
  int fair_output;
  int fair_size;
  int fair_count;
  int fair_q[$];

  int out_xfer_count [N_OUT];

  task automatic fail(input string clause, input string detail);
    if (!verdict) begin
      verdict = 1'b1;
      $display("[%0t] %s violation: %s", $time, clause, detail);
      $display("RESULT: FAIL");
      $finish;
    end
  endtask

  function automatic logic [DW-1:0] payload_for(input int k, input int unsigned n);
    logic [DW-1:0] v;
    v = 32'hA000_0000;
    v = v | ((k & 3) << 20);
    v = v | (n & 32'h000f_ffff);
    return v;
  endfunction

  function automatic int count_pending();
    automatic int total;
    automatic int a;
    automatic int b;
    total = 0;
    for (a = 0; a < N_IN; a = a + 1)
      for (b = 0; b < N_OUT; b = b + 1)
        total = total + pending[a][b].size();
    return total;
  endfunction

  // Start a continuing offer on an otherwise idle input. The plumbing, rather
  // than this task, owns in_valid/in_data/in_sel and therefore enforces H2.
  task automatic prime_input(input int k, input int sel);
    gen_count[k] = gen_count[k] + 1;
    bfm_next_data[k] = payload_for(k, gen_count[k]);
    bfm_next_sel[k] = sel;
    bfm_offer[k] = 1'b1;
  endtask

// ---------------------------------------------------------------------------
// Protocol monitor and scoreboard.
//
// Input acceptances are entered before output transfers are removed. This is
// important for a legal zero-latency combinational implementation, where the
// same rising edge can both accept and deliver a beat.
// ---------------------------------------------------------------------------

  always @(posedge clk) begin : check_on_clock
    automatic logic [N_IN-1:0] acc_now;
    automatic int k;
    automatic int j;
    automatic int src;
    automatic int m;
    automatic int q;
    automatic int found;
    automatic beat_t nb;
    automatic beat_t db;

    acc_now = '0;

    if (!rst_n) begin
      prev_stall = '0;
      fair_q.delete();
      fair_count = 0;

      for (k = 0; k < N_IN; k = k + 1) begin
        live_age[k] = 0;
        for (j = 0; j < N_OUT; j = j + 1)
          pending[k][j].delete();
      end

      for (j = 0; j < N_OUT; j = j + 1) begin
        out_xfer_count[j] = 0;
        prev_data[j] = '0;
        prev_idx[j] = '0;
      end

      // Inputs are quiet during reset. Checking at the first rising edge after
      // asynchronous assertion also distinguishes a register that has actually
      // been cleared asynchronously from one that waits for this edge.
      if (mon_started && (in_valid === '0) && (out_valid !== '0))
        fail("X1", "out_valid_o is nonzero while reset is asserted with quiet inputs");
    end else if (mon_started) begin

      // A3: a previously stalled offer must still be present and unchanged.
      for (j = 0; j < N_OUT; j = j + 1) begin
        if (prev_stall[j]) begin
          if (!out_valid[j])
            fail("A3", $sformatf("output %0d withdrew a stalled offer", j));
          else if ((bfm_odata(j) !== prev_data[j]) ||
                   (bfm_oidx(j)  !== prev_idx[j]))
            fail("A3", $sformatf("output %0d changed data or source while stalled", j));
        end
      end

      acc_now = in_valid & in_ready;

      // Record every accepted beat. Also prepare a fresh payload for the next
      // beat; the plumbing does not install it until the current offer moves.
      for (k = 0; k < N_IN; k = k + 1) begin
        if (acc_now[k]) begin
          nb.data = in_data[k*DW +: DW];
          nb.tag = accept_serial;
          accept_serial = accept_serial + 1;
          pending[k][in_sel[k*SW +: SW]].push_back(nb);

          gen_count[k] = gen_count[k] + 1;
          bfm_next_data[k] = payload_for(k, gen_count[k]);
          if (stress_mode)
            bfm_next_sel[k] = $urandom_range(N_OUT-1, 0);
        end
      end

      // Check delivered beats by source/output bookkeeping, not by searching
      // for a matching payload.
      for (j = 0; j < N_OUT; j = j + 1) begin
        if (out_valid[j] && out_ready[j]) begin
          out_xfer_count[j] = out_xfer_count[j] + 1;
          src = bfm_oidx(j);

          if (pending[src][j].size() == 0) begin
            fail("R1/R3/R4/R6",
                 $sformatf("output %0d delivered source %0d with no accepted beat owed there",
                           j, src));
          end else begin
            db = pending[src][j].pop_front();
            if (db.data !== bfm_odata(j)) begin
              fail("R1/R2/R3/R5",
                   $sformatf("output %0d source %0d: expected %08x (accept tag %0d), got %08x",
                             j, src, db.data, db.tag, bfm_odata(j)));
            end
          end

          if (fair_active && (j == fair_output)) begin
            if (!fair_mask[src])
              fail("A2/R3", $sformatf("fairness set on output %0d contains no input %0d",
                                      j, src));

            fair_q.push_back(src);
            if (fair_q.size() > fair_size)
              m = fair_q.pop_front();

            if (fair_q.size() == fair_size) begin
              for (m = 0; m < N_IN; m = m + 1) begin
                if (fair_mask[m]) begin
                  found = 0;
                  for (q = 0; q < fair_q.size(); q = q + 1)
                    if (fair_q[q] == m)
                      found = 1;
                  if (!found)
                    fail("A2", $sformatf(
                         "input %0d absent from a window of %0d transfers on output %0d",
                         m, fair_size, j));
                end
              end
            end
            fair_count = fair_count + 1;
          end
        end
      end

      // Save only information associated with a valid offer. Payload and index
      // are deliberately ignored whenever valid is low.
      for (j = 0; j < N_OUT; j = j + 1) begin
        prev_stall[j] = out_valid[j] && !out_ready[j];
        if (out_valid[j]) begin
          prev_data[j] = bfm_odata(j);
          prev_idx[j] = bfm_oidx(j);
        end
      end

      // X3 is checked only in phases where the bound outputs are held ready.
      for (k = 0; k < N_IN; k = k + 1) begin
        if (!live_mask[k] || !in_valid[k]) begin
          live_age[k] = 0;
        end else begin
          if (live_age[k] >= 32)
            fail("X3", $sformatf("input %0d was not accepted within 32 cycles", k));
          else if (acc_now[k])
            live_age[k] = 0;
          else
            live_age[k] = live_age[k] + 1;
        end
      end
    end
  end

// ---------------------------------------------------------------------------
// Phase helpers. All external stimulus changes on falling edges.
// ---------------------------------------------------------------------------

  task automatic fresh_reset();
    automatic int c;
    @(negedge clk);
    bfm_offer = '0;
    stress_mode = 1'b0;
    live_mask = '0;
    fair_active = 1'b0;
    out_ready = '1;

    bfm_reset(5);
    out_ready = '1;

    // X2: no pre-reset delivery may reappear, and an idle unit may not invent
    // one. No sample is taken before the first clock edge.
    for (c = 0; c < 4; c = c + 1) begin
      @(negedge clk);
      if (out_valid !== '0)
        fail("X2/R6", "a beat appeared after reset with no post-reset acceptance");
    end
  endtask

  task automatic stop_and_drain();
    automatic int c;
    automatic int quiet;

    @(negedge clk);
    bfm_offer = '0;
    stress_mode = 1'b0;
    live_mask = '0;
    fair_active = 1'b0;
    out_ready = '1;

    quiet = 0;
    for (c = 0; (c < 8000) && (quiet < 3); c = c + 1) begin
      @(negedge clk);
      if ((in_valid === '0) && (count_pending() == 0) && (out_valid === '0))
        quiet = quiet + 1;
      else
        quiet = 0;
    end

    if (quiet < 3)
      fail("R4/X3", $sformatf(
           "drain failed: in_valid=%b out_valid=%b pending=%0d",
           in_valid, out_valid, count_pending()));
  endtask

  // Continuously offer the specified set to one ready output. Any starting
  // rotation is accepted; only sliding windows of exactly |S| transfers are
  // constrained.
  task automatic run_fair(input logic [N_IN-1:0] mask,
                          input int output_no,
                          input int target);
    automatic int k;
    automatic int c;

    fresh_reset();
    @(negedge clk);
    out_ready = '1;

    fair_mask = mask;
    fair_output = output_no;
    fair_size = 0;
    fair_count = 0;
    fair_active = 1'b0;
    fair_q.delete();

    for (k = 0; k < N_IN; k = k + 1) begin
      if (mask[k]) begin
        fair_size = fair_size + 1;
        prime_input(k, output_no);
      end
    end
    live_mask = mask;

    // Do not start the fairness windows until every member is actually
    // offering. Earlier transfers are still checked by the scoreboard.
    c = 0;
    while (((in_valid & mask) !== mask) && (c < 40)) begin
      @(negedge clk);
      c = c + 1;
    end
    if ((in_valid & mask) !== mask)
      fail("X3", "the source offers did not become established");

    fair_q.delete();
    fair_count = 0;
    fair_active = 1'b1;

    c = 0;
    while ((fair_count < target) && (c < 1500)) begin
      @(negedge clk);
      c = c + 1;
    end

    if (fair_count < target)
      fail("A2/R4/X3", $sformatf(
           "only %0d of %0d requested transfers occurred on output %0d",
           fair_count, target, output_no));

    fair_active = 1'b0;
    live_mask = '0;
    stop_and_drain();
  endtask

  // Random routing, sustained contention, and random backpressure. The
  // scoreboard checks routing, payload, source, ordering, and exact delivery;
  // the protocol monitor checks every stalled offer.
  task automatic run_stress();
    automatic int k;
    automatic int c;

    fresh_reset();
    @(negedge clk);
    stress_mode = 1'b1;
    out_ready = '1;
    for (k = 0; k < N_IN; k = k + 1)
      prime_input(k, $urandom_range(N_OUT-1, 0));

    for (c = 0; c < 700; c = c + 1) begin
      @(negedge clk);
      out_ready = $urandom;
      if ((c % 37) == 0)
        out_ready = '0;
      if ((c % 41) == 0)
        out_ready = '1;
    end

    stop_and_drain();
  endtask

  // Inputs 0 and 1 encounter a non-ready output. Inputs 2 and 3 must still be
  // accepted and must move beats on output 1. No assumption is made that a
  // stalled output asserts valid: a compliant design may defer that offer.
  task automatic run_independence();
    automatic int base_count;
    automatic int c;

    fresh_reset();
    @(negedge clk);
    out_ready = 4'b1110;       // output 0 blocked; all others ready
    prime_input(0, 0);
    prime_input(1, 0);

    repeat (6) @(negedge clk);

    prime_input(2, 1);
    prime_input(3, 1);
    live_mask = 4'b1100;
    base_count = out_xfer_count[1];

    c = 0;
    while (((out_xfer_count[1] - base_count) < 12) && (c < 1024)) begin
      @(negedge clk);
      c = c + 1;
    end

    if ((out_xfer_count[1] - base_count) < 12)
      fail("I1/I2", "a blocked output/input prevented progress on independent input/output paths");

    live_mask = '0;
    stop_and_drain();
  endtask

  // Create long stalled offers where the implementation chooses to expose
  // them, then add competing requesters. A3 itself is checked every cycle by
  // the monitor, including throughout the randomized stress phase.
  task automatic run_hold();
    automatic int c;

    fresh_reset();
    @(negedge clk);
    out_ready = 4'b0111;       // output 3 not ready
    prime_input(0, 3);

    repeat (6) @(negedge clk);
    prime_input(1, 3);
    prime_input(2, 3);
    prime_input(3, 1);

    for (c = 0; c < 24; c = c + 1) begin
      @(negedge clk);
      out_ready[3] = 1'b0;
    end

    @(negedge clk);
    out_ready = '1;
    repeat (8) @(negedge clk);
    stop_and_drain();
  endtask

  // Reset while traffic and, for implementations that expose it, a stalled
  // output offer are present. Reset discards all obligations; nothing may leak
  // into the post-reset idle interval.
  task automatic run_reset_recovery();
    automatic int c;

    fresh_reset();
    @(negedge clk);
    out_ready = 4'b1011;       // output 2 not ready
    prime_input(0, 2);
    prime_input(1, 2);

    repeat (8) @(negedge clk);
    bfm_offer = '0;
    stress_mode = 1'b0;
    live_mask = '0;
    fair_active = 1'b0;

    bfm_reset(5);
    out_ready = '1;

    for (c = 0; c < 8; c = c + 1) begin
      @(negedge clk);
      if (out_valid !== '0)
        fail("X2", "a pre-reset beat survived reset");
    end

    stop_and_drain();
  endtask

// ---------------------------------------------------------------------------
// Test sequence.
// ---------------------------------------------------------------------------

  initial begin : main_stimulus
    automatic int k;

    verdict = 1'b0;
    mon_started = 1'b1;
    stress_mode = 1'b0;
    live_mask = '0;
    fair_active = 1'b0;
    fair_mask = '0;
    fair_output = 0;
    fair_size = 0;
    fair_count = 0;
    prev_stall = '0;
    accept_serial = 0;

    for (k = 0; k < N_IN; k = k + 1) begin
      gen_count[k] = 0;
      live_age[k] = 0;
    end

    // Several tied-set sizes and starting outputs. No particular winner or
    // rotation phase is required.
    run_fair(4'b0011, 0, 24);
    run_fair(4'b1110, 1, 30);
    run_fair(4'b1111, 2, 40);

    run_stress();
    run_independence();
    run_hold();
    run_reset_recovery();

    if (!verdict) begin
      verdict = 1'b1;
      $display("All routing, handshake, arbitration, independence, and reset checks completed.");
      $display("RESULT: PASS");
      $finish;
    end
  end

endmodule
