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
// Reference model and transaction-level scoreboard
// ---------------------------------------------------------------------------

  // d0 and d1 are normally identical. After silently consumed beats they are
  // the two values permitted by L4: retaining the silent beat, or leaving the
  // previous retained beat in place.
  typedef struct packed {
    logic [31:0] d0;
    logic [31:0] d1;
    logic        check_realign_strb;
  } exp_t;

  exp_t exp_q [$];

  int errors = 0;
  int offer_wait = 0;
  bit checks_en = 1'b0;

  bit line_open = 1'b0;
  int rotation = 0;
  logic [31:0] ret_fresh = 32'b0; // silently consumed beats replace retention
  logic [31:0] ret_saved = 32'b0; // silently consumed beats do not replace it

  task automatic record_error(input string msg);
    errors = errors + 1;
    $display("CHECK FAILURE at %0t: %s", $time, msg);
  endtask

  task automatic fail_now();
    $display("RESULT: FAIL");
    $finish;
  endtask

  function automatic int rotation_of(input logic [3:0] s);
    int i;
    begin
      rotation_of = 0;
      for (i = 0; i < 4; i = i + 1)
        rotation_of = rotation_of + (s[i] ? 1 : 0);
    end
  endfunction

  function automatic [31:0] joined(
    input logic [31:0] cur,
    input logic [31:0] prev,
    input int r
  );
    logic [31:0] cur_part;
    logic [31:0] prev_part;
    begin
      // Explicit extremes avoid relying on oversized shifts of a 32-bit value.
      if (r == 4)
        cur_part = 32'b0;
      else
        cur_part = cur << (8*r);

      if (r == 0)
        prev_part = 32'b0;
      else
        prev_part = prev >> (8*(4-r));

      joined = cur_part | prev_part;
    end
  endfunction

  task automatic model_input();
    exp_t e;
    bit make_output;
    begin
      if (!ra) begin
        // P1: transparent data path. The transparent-mode strobe is deliberately
        // not modeled or checked (P2/L3).
        e.d0 = pdata;
        e.d1 = pdata;
        e.check_realign_strb = 1'b0;
        exp_q.push_back(e);
      end else if (fst) begin
        // R1/R4: the first beat fixes the rotation and is only retained.
        rotation = rotation_of(strb);
        ret_fresh = pdata;
        ret_saved = pdata;
        line_open = !lst;
      end else if (line_open) begin
        make_output = lst || (strb != 4'b0000);

        if (make_output) begin
          e.d0 = joined(pdata, ret_fresh, rotation);
          e.d1 = joined(pdata, ret_saved, rotation);
          e.check_realign_strb = 1'b1;
          exp_q.push_back(e);
        end

        // Both L4 readings are tracked. They reconverge on every beat that
        // produces an output.
        ret_fresh = pdata;
        if (make_output)
          ret_saved = pdata;

        if (lst)
          line_open = 1'b0;
      end
      // Behaviour after a missing first beat is unspecified, so no expectation
      // is generated for that case.
    end
  endtask

  task automatic model_output();
    exp_t e;
    begin
      if (exp_q.size() == 0) begin
        record_error($sformatf(
          "P1/R1/R2: unexpected output beat, data=%08x strb=%x", qdata, qstrb));
      end else begin
        e = exp_q.pop_front();

        if ((qdata !== e.d0) && (qdata !== e.d1)) begin
          record_error($sformatf(
            "P1/R2/R4/R5: output data mismatch: got %08x, permitted %08x or %08x",
            qdata, e.d0, e.d1));
        end

        if (e.check_realign_strb && (qstrb !== 4'hF)) begin
          record_error($sformatf(
            "R3: realigned output strobe must be all ones, got %x", qstrb));
        end
      end
    end
  endtask

  // All handshakes are sampled at the rising edge. Input bookkeeping is done
  // before output bookkeeping so a combinational, same-cycle output is handled
  // as well as a registered output.
  always @(posedge clk) begin
    if (!rst_n || clr) begin
      exp_q.delete();
      line_open = 1'b0;
      offer_wait = 0;
    end else if (checks_en) begin
      if (!ra) begin
        if (qvalid !== pvalid)
          record_error("P1: transparent pop_valid_o does not follow push_valid_i");

        // H3 makes ready meaningless when nothing is offered, so only compare
        // the ready path during an actual offer.
        if (pvalid && (pready !== qready))
          record_error("P1: transparent push_ready_o does not follow pop_ready_i");

        if (qvalid && (qdata !== pdata))
          record_error($sformatf(
            "P1: transparent data mismatch: got %08x, offered %08x",
            qdata, pdata));
      end

      if (pvalid && pready)
        model_input();

      if (qvalid && qready)
        model_output();

      // X3 applies while the output sink is ready. Backpressure intervals do
      // not count against the input-acceptance bound.
      if (!qready || !pvalid || (pvalid && pready)) begin
        offer_wait = 0;
      end else begin
        offer_wait = offer_wait + 1;
        if (offer_wait == 17)
          record_error("X3: offered beat was not accepted within 16 cycles");
      end
    end
  end

// ---------------------------------------------------------------------------
// Stimulus helpers
// ---------------------------------------------------------------------------

  task automatic set_ready(input bit v);
    @(negedge clk);
    qready = v;
  endtask

  task automatic wait_complete(input string tag);
    int t;
    bit done;
    begin
      done = 1'b0;
      for (t = 0; t < 500; t = t + 1) begin
        @(negedge clk);
        if ((bfm_q.size() == 0) && !pvalid && (exp_q.size() == 0)) begin
          done = 1'b1;
          break;
        end
      end

      if (!done) begin
        if ((bfm_q.size() != 0) || pvalid)
          record_error($sformatf(
            "%s: X3/H1 timeout waiting for input acceptance", tag));
        else
          record_error($sformatf(
            "%s: P1/R2 timeout waiting for required output beats", tag));
        fail_now();
      end

      // Catch late or extra outputs, including outputs for first or silently
      // consumed beats.
      repeat (8) @(negedge clk);
      if (errors != 0)
        fail_now();
    end
  endtask

  // Four input beats produce three output beats. Later strb_i values have
  // popcounts different from the first beat, checking that R remains fixed.
  // The final beat has strb_i==0 and last_i==1, also exercising R6.
  task automatic run_line(
    input logic [3:0] s0,
    input logic [31:0] b0,
    input logic [31:0] b1,
    input logic [31:0] b2,
    input logic [31:0] b3
  );
    begin
      bfm_send(b0, 1'b1, 1'b0, 1'b1, s0,   4'h2);
      bfm_send(b1, 1'b0, 1'b0, 1'b1, 4'h1, 4'h0);
      bfm_send(b2, 1'b0, 1'b0, 1'b1, 4'hE, 4'h5);
      bfm_send(b3, 1'b0, 1'b1, 1'b1, 4'h0, 4'hA);
      wait_complete("R1-R6 realigned line");
    end
  endtask

// ---------------------------------------------------------------------------
// Directed verification
// ---------------------------------------------------------------------------

  initial begin
    bfm_reset();
    checks_en = 1'b1;

    // P1/P2/L3: transparent data and handshakes, with partial and empty input
    // strobes. No requirement is placed on qstrb in this mode.
    bfm_send(32'h11223344, 1'b0, 1'b0, 1'b0, 4'h0, 4'h5);
    bfm_send(32'h89ABCDEF, 1'b1, 1'b0, 1'b0, 4'hF, 4'hA);
    bfm_send(32'h01020304, 1'b0, 1'b1, 1'b0, 4'h3, 4'h0);
    wait_complete("P1 transparent data path");

    // Transparent backpressure: valid must still follow the offered input,
    // ready must not run ahead of the sink, and the source beat is held by the
    // provided driver until the actual rising-edge handshake.
    set_ready(1'b0);
    bfm_send(32'hDEADBEEF, 1'b0, 1'b0, 1'b0, 4'h0, 4'h3);
    repeat (5) @(posedge clk);
    set_ready(1'b1);
    wait_complete("P1 transparent backpressure");

    // L1: with the sink stopped, either immediate acceptance of the first beat
    // or holding it until this point is accepted. Both implementations must
    // produce the same single output once the second beat completes the line.
    set_ready(1'b0);
    bfm_send(32'h03020100, 1'b1, 1'b0, 1'b1, 4'b0101, 4'hF);
    repeat (4) @(posedge clk);
    set_ready(1'b1);
    bfm_send(32'h07060504, 1'b0, 1'b1, 1'b1, 4'h0, 4'h0);
    wait_complete("L1 first-beat acceptance latitude");

    // Every rotation, including both extremes. Bytes within each group are
    // distinct so dropped, duplicated, reordered, and incorrectly joined bytes
    // are visible. Non-contiguous first strobes distinguish popcount from the
    // numeric strobe value or its bit position.
    run_line(4'b0000, // R=0: output is the current beat
             32'h03020100, 32'h07060504, 32'h0B0A0908, 32'h0F0E0D0C);

    run_line(4'b1000, // R=1
             32'h13121110, 32'h17161514, 32'h1B1A1918, 32'h1F1E1D1C);

    run_line(4'b1001, // R=2
             32'h23222120, 32'h27262524, 32'h2B2A2928, 32'h2F2E2D2C);

    run_line(4'b1101, // R=3
             32'h33323130, 32'h37363534, 32'h3B3A3938, 32'h3F3E3D3C);

    run_line(4'b1111, // R=4: output is the retained beat, not R=0
             32'h43424140, 32'h47464544, 32'h4B4A4948, 32'h4F4E4D4C);

    // R1 takes precedence on a beat that is simultaneously first and last:
    // it is consumed and retained, and produces no output.
    bfm_send(32'hA0A1A2A3, 1'b1, 1'b1, 1'b1, 4'b0111, 4'h0);
    wait_complete("R1 simultaneous first and last");

    // R2/R6/L4: the middle beat must be consumed without an output because
    // strb_i==0 and last_i==0, despite push_strb_i being all ones. The final
    // beat must produce exactly one output despite both strobes being clear.
    // Its two permitted data values differ according to the L4 retention choice.
    bfm_send(32'h03020100, 1'b1, 1'b0, 1'b1, 4'b0101, 4'hF);
    bfm_send(32'h13121110, 1'b0, 1'b0, 1'b1, 4'b0000, 4'hF);
    bfm_send(32'h23222120, 1'b0, 1'b1, 1'b1, 4'b0000, 4'h0);
    wait_complete("R2 silent consumption, R6 last, and L4");

    // X2: clear while a line has retained state, then run a complete new line.
    bfm_send(32'h55667788, 1'b1, 1'b0, 1'b1, 4'b0111, 4'hF);
    wait_complete("X2 setup with retained beat");
    bfm_clear();
    @(negedge clk);
    if (qvalid !== 1'b0)
      record_error("X2: clear did not return the unit to a quiet starting state");

    run_line(4'b0011,
             32'h03020100, 32'h07060504, 32'h0B0A0908, 32'h0F0E0D0C);

    // X1: reset is also exercised after retained state exists. Inputs are quiet
    // throughout reset, and no time-zero output assumptions are made.
    bfm_send(32'hCAFEBABE, 1'b1, 1'b0, 1'b1, 4'b1111, 4'hF);
    wait_complete("X1 setup with retained beat");
    bfm_reset();
    if (qvalid !== 1'b0)
      record_error("X1: output valid remained asserted after quiet reset");

    run_line(4'b0101,
             32'h03020100, 32'h07060504, 32'h0B0A0908, 32'h0F0E0D0C);

    repeat (4) @(negedge clk);
    if (errors != 0)
      fail_now();

    $display("RESULT: PASS");
    $finish;
  end

endmodule
