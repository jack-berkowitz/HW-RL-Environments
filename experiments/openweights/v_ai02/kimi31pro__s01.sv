module stream_realign_tb;

// ---------------------------------------------------------------------------
// PROVIDED PLUMBING -- moves beats, checks nothing.
// ---------------------------------------------------------------------------
// This exists so you spend your effort on checking rather than on handshake
// mechanics. It has been compiled and run against a correct design.
//
// What it does: generates the clock, sequences reset, connects the design, and
// presents queued beats one at a time -- holding each offer unchanged until it
// is taken, which is what clause H2 requires of a source.
//
// What it does NOT do: it computes no expected value, models no rotation, keeps
// no byte stream, and draws no conclusion from any signal.
//
// TWO THINGS WORTH KNOWING, both of which cost real time to find:
//
//   * The driver is an ALWAYS BLOCK, not a loop you pump from your stimulus.
//     A pumped loop only services the edges it happens to be waiting on, and
//     every edge you wait on elsewhere is one where a beat can be accepted
//     unnoticed -- after which you re-present a beat the design already took.
//
//   * Sample a handshake AT the rising edge. `push_ready_o` read at the falling
//     edge is not necessarily the value the design used.
// ---------------------------------------------------------------------------

  // ---- clock ---------------------------------------------------------------
  logic clk = 1'b0;
  always #5 clk = ~clk;

  int bfm_cycle = 0;
  always @(posedge clk) if (rst_n) bfm_cycle <= bfm_cycle + 1;

  // ---- reset ---------------------------------------------------------------
  logic rst_n = 1'b0;          // ASYNCHRONOUS, ACTIVE LOW
  logic clr   = 1'b0;          // synchronous, active high

  task automatic bfm_reset(input int cycles = 5);
    @(negedge clk);
    rst_n = 1'b0;
    repeat (cycles) @(posedge clk);
    @(negedge clk);
    rst_n = 1'b1;
  endtask

  task automatic bfm_clear();
    @(negedge clk) clr = 1'b1;
    @(negedge clk) clr = 1'b0;
    repeat (2) @(posedge clk);
  endtask

  // ---- signals and the design under test ------------------------------------
  logic        ra = 1'b0, fst = 1'b0, lst = 1'b0;
  logic [3:0]  strb = 4'hF;
  logic [31:0] pdata = '0;
  logic [3:0]  pstrb = 4'hF;
  logic        pvalid = 1'b0, pready;
  logic [31:0] qdata;
  logic [3:0]  qstrb;
  logic        qvalid;
  logic        qready = 1'b1;

  stream_realign dut (
    .clk_i(clk), .rst_ni(rst_n), .clear_i(clr), .realign_i(ra), .first_i(fst),
    .last_i(lst), .strb_i(strb), .push_data_i(pdata), .push_strb_i(pstrb),
    .push_valid_i(pvalid), .push_ready_o(pready), .pop_data_o(qdata),
    .pop_strb_o(qstrb), .pop_valid_o(qvalid), .pop_ready_i(qready));

  // ---- what you queue --------------------------------------------------------
  typedef struct packed {
    logic [31:0] data;   // push_data_i
    logic [3:0]  dstrb;  // push_strb_i
    logic        first;  // first_i
    logic        last;   // last_i
    logic        realign;// realign_i
    logic [3:0]  lstrb;  // strb_i presented with this beat
  } bfm_beat_t;

  bfm_beat_t bfm_q [$];

  task automatic bfm_send(input logic [31:0] data, input bit first, input bit last,
                          input bit do_realign, input logic [3:0] lstrb,
                          input logic [3:0] dstrb = 4'hF);
    bfm_beat_t b;
    b.data = data; b.dstrb = dstrb; b.first = first; b.last = last;
    b.realign = do_realign; b.lstrb = lstrb;
    bfm_q.push_back(b);
  endtask

  task automatic bfm_ready(input bit v); qready = v; endtask

  // Waits until everything queued has been offered and taken.
  task automatic bfm_idle(input int max_cycles = 400);
    for (int t = 0; t < max_cycles; t++) begin
      @(posedge clk);
      if (bfm_q.size() == 0 && !pvalid) break;
    end
    repeat (6) @(posedge clk);
  endtask

  // ---- the driver ------------------------------------------------------------
  logic bfm_hs;
  always @(posedge clk) bfm_hs <= (rst_n && !clr) ? (pvalid & pready) : 1'b0;

  always @(negedge clk) begin
    if (!rst_n) begin
      pvalid = 1'b0;
    end else begin
      if (bfm_hs && bfm_q.size() > 0) begin void'(bfm_q.pop_front()); pvalid = 1'b0; end
      if (!pvalid && bfm_q.size() > 0) begin
        pdata = bfm_q[0].data;  pstrb = bfm_q[0].dstrb; fst = bfm_q[0].first;
        lst   = bfm_q[0].last;  strb  = bfm_q[0].lstrb; ra  = bfm_q[0].realign;
        pvalid = 1'b1;
      end
    end
  end

  // ---- watchdog --------------------------------------------------------------
  // Yours to keep. It fires regardless of what the design does: one of the
  // faulty designs never accepts anything, and without this your testbench
  // hangs instead of reporting. A hang is not a verdict.
  initial begin
    #2_000_000;
    $display("RESULT: FAIL (watchdog: no verdict reached)");
    $finish;
  end

// ---------------------------------------------------------------------------
// Reference model and checking
// ---------------------------------------------------------------------------

  bit finished = 1'b0;

  task automatic fail(input string clause, input string detail);
    begin
      if (!finished) begin
        finished = 1'b1;
        $display("FAIL [%s] %s", clause, detail);
        $display("RESULT: FAIL");
        $finish;
      end
    end
  endtask

  function automatic int unsigned rotation_of(input logic [3:0] s);
    automatic int unsigned n;
    automatic int j;
    begin
      n = 0;
      for (j = 0; j < 4; j = j + 1)
        if (s[j]) n = n + 1;
      rotation_of = n;
    end
  endfunction

  function automatic logic [31:0] join_data(
    input logic [31:0] cur,
    input logic [31:0] ret,
    input int unsigned rot
  );
    begin
      if (rot == 0)
        join_data = cur;
      else if (rot == 4)
        join_data = ret;
      else
        join_data = (cur << (rot * 8)) | (ret >> ((4 - rot) * 8));
    end
  endfunction

  typedef struct packed {
    logic [31:0] data;
    logic [31:0] other_data;
    logic        has_other;
  } expected_t;

  expected_t expected_q [$];

  logic        model_open;
  int unsigned model_rot;

  // These two retained-beat models represent the two choices allowed by L4.
  // They are identical except across silently consumed beats.
  logic [31:0] ret_replace;
  logic [31:0] ret_keep;

  int offer_wait = 0;

  always @(posedge clk) begin : scoreboard_proc
    automatic expected_t new_exp;
    automatic expected_t front_exp;

    if (!rst_n || clr) begin
      expected_q.delete();
      model_open = 1'b0;
      model_rot  = 0;
      ret_replace = 32'b0;
      ret_keep    = 32'b0;
      offer_wait  = 0;
    end else begin
      // P1: transparent mode has combinational data and handshake behaviour.
      // Deliberately no transparent-mode strobe check: L3 permits either choice.
      if (!ra) begin
        if (qvalid !== pvalid)
          fail("P1", "pop_valid_o does not follow push_valid_i in transparent mode");

        // H3 makes push_ready_o meaningless when no beat is offered.
        if (pvalid && (pready !== qready))
          fail("P1", "push_ready_o does not follow pop_ready_i in transparent mode");

        if (pvalid && qvalid && (qdata !== pdata)) begin
          $display("Transparent data mismatch: offered=%08h observed=%08h", pdata, qdata);
          fail("P1", "transparent data path is not transparent");
        end
      end

      // Account for an accepted input before checking an output on the same
      // edge: a combinational implementation can produce that output now.
      if (pvalid && pready && ra) begin
        if (fst) begin
          model_open  = 1'b1;
          model_rot   = rotation_of(strb);
          ret_replace = pdata;
          ret_keep    = pdata;
          // R1: deliberately no expected output is queued.
        end else if (model_open) begin
          if (lst || (strb != 4'h0)) begin
            new_exp.data       = join_data(pdata, ret_replace, model_rot);
            new_exp.other_data = join_data(pdata, ret_keep, model_rot);
            new_exp.has_other  = (new_exp.data != new_exp.other_data);
            expected_q.push_back(new_exp);

            // Every output-producing beat becomes the retained beat under
            // either L4 interpretation.
            ret_replace = pdata;
            ret_keep    = pdata;
          end else begin
            // R2: silently consumed, with no output. Only the replacement
            // model changes; the keep model implements the other L4 choice.
            ret_replace = pdata;
          end
        end
      end

      // Check realigned output beats by queue position, never by searching for
      // a matching data value.
      if (ra && qvalid) begin
        if (expected_q.size() > 0) begin
          front_exp = expected_q[0];

          if (front_exp.has_other) begin
            if ((qdata !== front_exp.data) &&
                (qdata !== front_exp.other_data)) begin
              $display("Realign data mismatch: observed=%08h replace-model=%08h keep-model=%08h",
                       qdata, front_exp.data, front_exp.other_data);
              fail("R2/R4/R5", "wrong rotation, retained beat, or byte ordering");
            end
          end else begin
            if (qdata !== front_exp.data) begin
              $display("Realign data mismatch: observed=%08h expected=%08h R=%0d",
                       qdata, front_exp.data, model_rot);
              fail("R2/R4/R5", "wrong rotation, retained beat, or byte ordering");
            end
          end

          if (qstrb !== 4'hF) begin
            $display("Realign strobe mismatch: observed=%h expected=F", qstrb);
            fail("R3", "realigned output strobe is not all ones");
          end
        end

        if (qready) begin
          if (expected_q.size() == 0) begin
            $display("Unexpected realigned output handshake: data=%08h strb=%h first=%b last=%b line_strb=%h",
                     qdata, qstrb, fst, lst, strb);
            if (pvalid && pready && fst)
              fail("R1", "the first beat of a line produced an output beat");
            else
              fail("R2", "an output beat was produced when none was owed");
          end else begin
            void'(expected_q.pop_front());
          end
        end
      end

      // X3: an offer may wait at most sixteen rising edges with the sink ready.
      // The sixteenth edge is allowed to be the accepting edge.
      if (pvalid && qready && !pready) begin
        if (offer_wait >= 15)
          fail("X3", "input beat was not accepted within 16 cycles with pop_ready_i high");
        else
          offer_wait = offer_wait + 1;
      end else begin
        offer_wait = 0;
      end
    end
  end

// ---------------------------------------------------------------------------
// Stimulus helpers
// ---------------------------------------------------------------------------

  task automatic drain_phase(input string missing_clause);
    automatic int k;
    begin
      bfm_idle(400);

      // Allow ample time for registered as well as combinational implementations.
      for (k = 0; k < 100; k = k + 1) begin
        @(negedge clk);
        if ((expected_q.size() == 0) && (bfm_q.size() == 0) && !pvalid)
          break;
      end

      // Also catch extra outputs arriving just after the last expected one.
      repeat (6) @(posedge clk);
      @(negedge clk);

      if ((bfm_q.size() != 0) || pvalid)
        fail("X3", "queued input was not accepted");

      if (expected_q.size() != 0)
        fail(missing_clause, "one or more required output beats were never produced");

      if (qvalid !== 1'b0)
        fail("R1/R2", "output valid remained asserted after all expected beats drained");
    end
  endtask

  task automatic queue_full_line(
    input logic [3:0]  first_strb,
    input logic [31:0] w0,
    input logic [31:0] w1,
    input logic [31:0] w2,
    input logic [31:0] w3
  );
    begin
      // Later strb_i values deliberately differ from the first beat's strobe:
      // they gate output, but must not change the rotation fixed by R4.
      bfm_send(w0, 1'b1, 1'b0, 1'b1, first_strb, 4'h0);
      bfm_send(w1, 1'b0, 1'b0, 1'b1, 4'h1,       4'h1);
      bfm_send(w2, 1'b0, 1'b0, 1'b1, 4'hE,       4'hA);
      bfm_send(w3, 1'b0, 1'b1, 1'b1, 4'h4,       4'h5);
    end
  endtask

  // Accept an output-producing second beat, then lower pop_ready_i at the next
  // falling edge. A combinational implementation has already transferred its
  // output; a registered implementation can have a pending output. Both are
  // supported, and the latter gives reset/clear an observable pending beat.
  task automatic queue_output_and_stall(input logic [31:0] w);
    automatic int guard;
    begin
      bfm_send(w, 1'b0, 1'b0, 1'b1, 4'h1, 4'h3);
      guard = 0;
      while ((bfm_hs !== 1'b1) && (guard < 40)) begin
        @(negedge clk);
        guard = guard + 1;
      end
      if (bfm_hs !== 1'b1)
        fail("X3", "could not establish the reset/clear test output beat");
      qready = 1'b0;
    end
  endtask

  task automatic clear_phase();
    begin
      qready = 1'b1;

      // Establish a retained first beat.
      bfm_send(32'h90919293, 1'b1, 1'b0, 1'b1, 4'h1, 4'h0);
      drain_phase("R1");

      queue_output_and_stall(32'h94959697);
      @(negedge clk);

      bfm_clear();
      @(negedge clk);

      if (qvalid !== 1'b0)
        fail("X2", "clear_i did not remove a pending output beat");

      if (expected_q.size() != 0)
        fail("X2", "output state survived clear_i");

      qready = 1'b1;

      // A complete fresh line must work normally after clear.
      queue_full_line(4'h7,
                      32'hA0A1A2A3, 32'hA4A5A6A7,
                      32'hA8A9AAAB, 32'hACADAEAF);
      drain_phase("X2");
    end
  endtask

  task automatic reset_phase();
    begin
      qready = 1'b1;

      bfm_send(32'hB0B1B2B3, 1'b1, 1'b0, 1'b1, 4'h3, 4'h0);
      drain_phase("R1");

      queue_output_and_stall(32'hB4B5B6B7);

      // Assert reset between rising edges. If an output is pending, an
      // asynchronous reset removes it before the next rising edge. Checking
      // at that next edge still sees a synchronous design's old valid value.
      @(negedge clk);
      rst_n = 1'b0;

      @(posedge clk);
      if (qvalid !== 1'b0)
        fail("X1", "output state was not cleared asynchronously by rst_ni");

      repeat (2) @(posedge clk);
      @(negedge clk);
      rst_n  = 1'b1;
      qready = 1'b1;

      queue_full_line(4'hF,
                      32'hC0C1C2C3, 32'hC4C5C6C7,
                      32'hC8C9CACB, 32'hCCCDCECF);
      drain_phase("X1");
    end
  endtask

// ---------------------------------------------------------------------------
// Directed stimulus
// ---------------------------------------------------------------------------

  initial begin
    // Do not sample at time zero. By this falling edge, at least two rising
    // edges have occurred with reset asserted and all inputs quiet.
    repeat (2) @(posedge clk);
    @(negedge clk);
    if (qvalid !== 1'b0)
      fail("X1", "pop_valid_o was not low after reset had been asserted at a clock edge");

    bfm_reset(3);
    qready = 1'b1;

    // Transparent mode, including partial push strobes. No requirement is
    // placed on qstrb in this mode.
    bfm_send(32'h01234567, 1'b0, 1'b0, 1'b0, 4'h0, 4'h0);
    bfm_send(32'h89ABCDEF, 1'b0, 1'b1, 1'b0, 4'hF, 4'h5);
    bfm_send(32'hA5A55A5A, 1'b0, 1'b0, 1'b0, 4'h3, 4'hA);
    drain_phase("P1");

    // Transparent-mode backpressure: valid and ready must remain the same
    // handshake rather than becoming an independent registered stream.
    @(negedge clk);
    qready = 1'b0;
    bfm_send(32'hDEADBEEF, 1'b0, 1'b0, 1'b0, 4'h0, 4'h6);
    repeat (3) @(posedge clk);
    @(negedge clk);
    qready = 1'b1;
    drain_phase("P1");

    // A one-beat line still owes no output, even with last_i asserted.
    bfm_send(32'h0F0E0D0C, 1'b1, 1'b1, 1'b1, 4'hF, 4'h0);

    // Exercise every rotation, including both non-modulo extremes R=0 and R=4.
    // All data words are unique, making loss, duplication and reordering visible.
    queue_full_line(4'h0,
                    32'h00010203, 32'h04050607,
                    32'h08090A0B, 32'h0C0D0E0F);
    queue_full_line(4'h1,
                    32'h10111213, 32'h14151617,
                    32'h18191A1B, 32'h1C1D1E1F);
    queue_full_line(4'h3,
                    32'h20212223, 32'h24252627,
                    32'h28292A2B, 32'h2C2D2E2F);
    queue_full_line(4'h7,
                    32'h30313233, 32'h34353637,
                    32'h38393A3B, 32'h3C3D3E3F);
    queue_full_line(4'hF,
                    32'h40414243, 32'h44454647,
                    32'h48494A4B, 32'h4C4D4E4F);
    drain_phase("R2/R5");

    // R6: last_i owes an output even when strb_i is completely clear.
    bfm_send(32'h60616263, 1'b1, 1'b0, 1'b1, 4'h3, 4'h0);
    bfm_send(32'h64656667, 1'b0, 1'b1, 1'b1, 4'h0, 4'h0);
    drain_phase("R6");

    // R2/L4: the middle beat must be silently consumed. The final output may
    // join against either the middle beat or the original retained beat.
    bfm_send(32'h70717273, 1'b1, 1'b0, 1'b1, 4'h3, 4'h0);
    bfm_send(32'h74757677, 1'b0, 1'b0, 1'b1, 4'h0, 4'hF);
    bfm_send(32'h78797A7B, 1'b0, 1'b1, 1'b1, 4'h1, 4'h2);
    drain_phase("R2");

    // L1: with the sink stopped, either immediate or deferred acceptance of
    // the first beat is accepted. No acceptance check is made until ready returns.
    @(negedge clk);
    qready = 1'b0;
    bfm_send(32'h80818283, 1'b1, 1'b0, 1'b1, 4'h1, 4'h0);
    bfm_send(32'h84858687, 1'b0, 1'b0, 1'b1, 4'hE, 4'h4);
    bfm_send(32'h88898A8B, 1'b0, 1'b1, 1'b1, 4'h0, 4'h8);
    repeat (4) @(posedge clk);
    @(negedge clk);
    qready = 1'b1;
    drain_phase("R2/R6");

    clear_phase();
    reset_phase();

    if (!finished) begin
      finished = 1'b1;
      $display("RESULT: PASS");
      $finish;
    end
  end

endmodule
