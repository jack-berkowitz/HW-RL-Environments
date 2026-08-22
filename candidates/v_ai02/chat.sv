module stream_realign_tb;

  // ---------------------------------------------------------------------------
  // PROVIDED PLUMBING -- moves beats, checks nothing.
  // ---------------------------------------------------------------------------

  // ---- clock ---------------------------------------------------------------
  logic clk = 1'b0;
  always #5 clk = ~clk;

  int bfm_cycle = 0;
  always @(posedge clk)
    if (rst_n)
      bfm_cycle <= bfm_cycle + 1;

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
    @(negedge clk);
    clr = 1'b1;
    @(negedge clk);
    clr = 1'b0;
    repeat (2) @(posedge clk);
  endtask

  // ---- signals and the design under test ----------------------------------
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
    .clk_i(clk),
    .rst_ni(rst_n),
    .clear_i(clr),
    .realign_i(ra),
    .first_i(fst),
    .last_i(lst),
    .strb_i(strb),
    .push_data_i(pdata),
    .push_strb_i(pstrb),
    .push_valid_i(pvalid),
    .push_ready_o(pready),
    .pop_data_o(qdata),
    .pop_strb_o(qstrb),
    .pop_valid_o(qvalid),
    .pop_ready_i(qready)
  );

  // ---- what you queue ------------------------------------------------------
  typedef struct packed {
    logic [31:0] data;
    logic [3:0]  dstrb;
    logic        first;
    logic        last;
    logic        realign;
    logic [3:0]  lstrb;
  } bfm_beat_t;

  bfm_beat_t bfm_q [$];

  task automatic bfm_send(
    input logic [31:0] data,
    input bit          first,
    input bit          last,
    input bit          do_realign,
    input logic [3:0]  lstrb,
    input logic [3:0]  dstrb = 4'hF
  );
    bfm_beat_t b;

    b.data    = data;
    b.dstrb   = dstrb;
    b.first   = first;
    b.last    = last;
    b.realign = do_realign;
    b.lstrb   = lstrb;

    bfm_q.push_back(b);
  endtask

  task automatic bfm_ready(input bit v);
    qready = v;
  endtask

  // Waits until everything queued has been offered and taken.
  task automatic bfm_idle(input int max_cycles = 400);
    for (int t = 0; t < max_cycles; t++) begin
      @(posedge clk);
      if (bfm_q.size() == 0 && !pvalid)
        break;
    end
    repeat (6) @(posedge clk);
  endtask

  // ---- the driver ----------------------------------------------------------
  logic bfm_hs;

  always @(posedge clk)
    bfm_hs <= (rst_n && !clr) ? (pvalid & pready) : 1'b0;

  always @(negedge clk) begin
    if (!rst_n) begin
      pvalid = 1'b0;
    end else begin
      if (bfm_hs && bfm_q.size() > 0) begin
        void'(bfm_q.pop_front());
        pvalid = 1'b0;
      end

      if (!pvalid && bfm_q.size() > 0) begin
        pdata  = bfm_q[0].data;
        pstrb  = bfm_q[0].dstrb;
        fst    = bfm_q[0].first;
        lst    = bfm_q[0].last;
        strb   = bfm_q[0].lstrb;
        ra     = bfm_q[0].realign;
        pvalid = 1'b1;
      end
    end
  end


  // =========================================================================
  // CHECKER
  // =========================================================================

  logic        verdict_done = 1'b0;

  logic        model_line_active = 1'b0;
  logic [31:0] model_retained = '0;
  int          model_rot = 0;

  logic [31:0] exp_data_q [$];

  int live_stall_cycles = 0;


  // -------------------------------------------------------------------------
  // Failure reporting
  // -------------------------------------------------------------------------
  task automatic tb_fail(
    input string clause_name,
    input string message
  );
    if (!verdict_done) begin
      verdict_done = 1'b1;
      $display("FAILURE [%s]: %s", clause_name, message);
      $display("RESULT: FAIL");
      $finish;
    end
  endtask


  // -------------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------------
  function automatic int popcount4(input logic [3:0] v);
    int n;

    n = 0;
    if (v[0]) n++;
    if (v[1]) n++;
    if (v[2]) n++;
    if (v[3]) n++;

    return n;
  endfunction


  function automatic logic [31:0] realign_value(
    input logic [31:0] current_data,
    input logic [31:0] retained_data,
    input int          rotation
  );
    logic [31:0] left_part;
    logic [31:0] right_part;

    left_part  = current_data  << (8 * rotation);
    right_part = retained_data >> (8 * (4 - rotation));

    return left_part | right_part;
  endfunction


  function automatic logic [3:0] rotation_mask(input int rotation);
    case (rotation)
      0: rotation_mask = 4'b0000;
      1: rotation_mask = 4'b1000;
      2: rotation_mask = 4'b1010;
      3: rotation_mask = 4'b1101;
      4: rotation_mask = 4'b1111;
      default: rotation_mask = 4'b0000;
    endcase
  endfunction


  // -------------------------------------------------------------------------
  // Main scoreboard
  //
  // Expected realigned values are entered into exp_data_q when the
  // corresponding input beat actually handshakes.  Thus stalls do not advance
  // the reference model.
  // -------------------------------------------------------------------------
  always @(posedge clk) begin : scoreboard
    automatic logic [31:0] next_value;
    automatic int new_rotation;

    if (!rst_n) begin
      model_line_active = 1'b0;
      model_retained    = '0;
      model_rot         = 0;
      exp_data_q.delete();
      live_stall_cycles = 0;

      if (qvalid !== 1'b0)
        tb_fail("X1", "pop_valid_o asserted while asynchronous reset is active");

    end else if (clr) begin
      model_line_active = 1'b0;
      model_retained    = '0;
      model_rot         = 0;
      exp_data_q.delete();
      live_stall_cycles = 0;

    end else begin

      // ---------------------------------------------------------------------
      // X3 -- input liveness.
      //
      // H3 explicitly says push_ready_o is meaningless if no beat is offered,
      // so count only while pvalid is asserted.  Reset the counter whenever
      // the sink is not continuously ready.
      // ---------------------------------------------------------------------
      if (!qready || !pvalid || pready) begin
        live_stall_cycles = 0;
      end else begin
        if (live_stall_cycles >= 15)
          tb_fail(
            "X3",
            "input beat was not accepted within 16 cycles while pop_ready_i remained high"
          );

        live_stall_cycles = live_stall_cycles + 1;
      end


      // ---------------------------------------------------------------------
      // P1 -- true pass-through.
      //
      // Do NOT inspect qstrb here: P2/L3 explicitly make that unconstrained.
      // ---------------------------------------------------------------------
      if (!ra) begin
        if (qvalid !== pvalid)
          tb_fail(
            "P1",
            $sformatf(
              "pass-through valid mismatch: push_valid_i=%0b pop_valid_o=%0b",
              pvalid, qvalid
            )
          );

        if (pvalid) begin
          if (pready !== qready)
            tb_fail(
              "P1",
              $sformatf(
                "pass-through ready mismatch: push_ready_o=%0b pop_ready_i=%0b",
                pready, qready
              )
            );

          if (qdata !== pdata)
            tb_fail(
              "P1",
              $sformatf(
                "pass-through data mismatch: expected %08x got %08x",
                pdata, qdata
              )
            );
        end
      end


      // ---------------------------------------------------------------------
      // Update the realignment reference model only when an input beat moves.
      // ---------------------------------------------------------------------
      if (pvalid && pready && ra) begin

        if (fst) begin
          // R1/R4 -- first beat establishes rotation and is retained.
          new_rotation = popcount4(strb);

          model_rot         = new_rotation;
          model_retained    = pdata;
          model_line_active = 1'b1;

        end else if (model_line_active) begin

          // R2/R6 -- output iff current line strobe is nonzero OR this is last.
          if (lst || (strb != 4'b0000)) begin
            next_value = realign_value(
              pdata,
              model_retained,
              model_rot
            );

            exp_data_q.push_back(next_value);
          end

          // Every consumed beat becomes the retained beat, including one
          // silently consumed because strb_i == 0.
          model_retained = pdata;

          if (lst)
            model_line_active = 1'b0;
        end
      end


      // ---------------------------------------------------------------------
      // Check realigned output.
      //
      // P2/L3 mean qstrb is deliberately NOT checked in pass-through mode.
      // R3 requires all ones whenever a realigned output exists.
      // ---------------------------------------------------------------------
      if (ra && qvalid) begin

        if (qstrb !== 4'hF)
          tb_fail(
            "R3",
            $sformatf(
              "realigned output strobe must be 4'hF, got %x",
              qstrb
            )
          );

        if (exp_data_q.size() == 0)
          tb_fail(
            "R1/R2",
            $sformatf(
              "unexpected realigned output beat %08x; no output is due",
              qdata
            )
          );

        if (qdata !== exp_data_q[0])
          tb_fail(
            "R2/R4/R5",
            $sformatf(
              "realigned data mismatch: expected %08x got %08x (rotation=%0d)",
              exp_data_q[0], qdata, model_rot
            )
          );
      end


      // An output beat moves only on the output handshake.
      if (ra && qvalid && qready && exp_data_q.size() > 0)
        void'(exp_data_q.pop_front());

    end
  end


  // -------------------------------------------------------------------------
  // Wait for all queued input and all expected realigned output to drain.
  //
  // X3 gives an explicit input liveness bound.  The larger total bound here
  // prevents faulty designs that drop outputs from hanging the testbench.
  // -------------------------------------------------------------------------
  task automatic tb_wait_all(input int max_cycles = 200);
    bit completed;

    completed = 1'b0;

    for (int t = 0; t < max_cycles; t++) begin
      @(posedge clk);

      if ((bfm_q.size() == 0) &&
          !pvalid &&
          (exp_data_q.size() == 0) &&
          !qvalid) begin
        completed = 1'b1;
        break;
      end
    end

    if (!completed) begin
      if (bfm_q.size() != 0 || pvalid)
        tb_fail(
          "X3",
          "queued input traffic failed to drain"
        );
      else
        tb_fail(
          "R2",
          "an expected realigned output beat was never produced"
        );
    end

    repeat (3) @(posedge clk);
  endtask


  // -------------------------------------------------------------------------
  // Send one three-beat realigned line for the requested rotation.
  //
  // The first-beat masks are intentionally not all low-order-contiguous.
  // Rotation must be POPCOUNT(strb_i), not an encoded position.
  //
  // Subsequent strb_i values deliberately differ from the first beat so R4
  // is checked as well.
  //
  // The last beat uses strb_i == 0, exercising R6.
  // -------------------------------------------------------------------------
  task automatic test_rotation(input int rotation);
    logic [31:0] d0;
    logic [31:0] d1;
    logic [31:0] d2;
    logic [3:0]  first_mask;

    first_mask = rotation_mask(rotation);

    d0 = 32'h03020100 + (rotation * 32'h10101010);
    d1 = 32'h07060504 + (rotation * 32'h10101010);
    d2 = 32'h0B0A0908 + (rotation * 32'h10101010);

    // first beat: fixes R, no output
    bfm_send(
      d0,
      1'b1,
      1'b0,
      1'b1,
      first_mask,
      4'b0001
    );

    // Non-first beat: must produce output.  Current strb is deliberately
    // four bits set regardless of the line's original rotation.
    bfm_send(
      d1,
      1'b0,
      1'b0,
      1'b1,
      4'b1111,
      4'b0010
    );

    // Last beat: must produce output despite an empty strb_i.
    bfm_send(
      d2,
      1'b0,
      1'b1,
      1'b1,
      4'b0000,
      4'b0100
    );

    tb_wait_all();
  endtask


  // -------------------------------------------------------------------------
  // Explicit asynchronous-reset check.
  //
  // Put pass-through qvalid high while the sink is stalled, then assert reset
  // on a falling clock edge.  A truly asynchronous reset drops qvalid before
  // the next rising edge.
  // -------------------------------------------------------------------------
  task automatic test_async_reset();
    bit saw_async_drop;
    bit got_offer;

    saw_async_drop = 1'b0;
    got_offer      = 1'b0;

    bfm_ready(1'b0);

    bfm_send(
      32'hA55A_C33C,
      1'b0,
      1'b0,
      1'b0,
      4'b1010,
      4'b0101
    );

    for (int t = 0; t < 20; t++) begin
      @(posedge clk);
      if (pvalid) begin
        got_offer = 1'b1;
        break;
      end
    end

    if (!got_offer)
      tb_fail(
        "P1/X3",
        "could not establish a stalled pass-through beat for reset test"
      );

    if (qvalid !== 1'b1)
      tb_fail(
        "P1",
        "stalled pass-through beat did not assert pop_valid_o"
      );

    @(negedge clk);
    rst_n = 1'b0;

    fork : async_reset_wait
      begin
        @(negedge qvalid);
        saw_async_drop = 1'b1;
      end
      begin
        @(posedge clk);
      end
    join_any
    disable async_reset_wait;

    // If the transition happened so quickly that the event watcher missed it,
    // the current value being low is still sufficient.  A synchronous-only
    // design will ordinarily still be high when the rising-edge branch wins.
    if (!saw_async_drop && qvalid !== 1'b0)
      tb_fail(
        "X1",
        "pop_valid_o did not clear asynchronously before the next rising edge"
      );

    repeat (2) begin
      @(posedge clk);
      if (qvalid !== 1'b0)
        tb_fail(
          "X1",
          "pop_valid_o asserted while rst_ni was low"
        );
    end

    @(negedge clk);
    rst_n  = 1'b1;
    qready = 1'b1;

    // The BFM may re-offer the pass-through beat that reset interrupted.
    tb_wait_all();
  endtask


  // =========================================================================
  // STIMULUS
  // =========================================================================

  initial begin
    // -----------------------------------------------------------------------
    // Initial reset
    // -----------------------------------------------------------------------
    bfm_reset(5);
    bfm_ready(1'b1);


    // -----------------------------------------------------------------------
    // P1/P2/L3 -- pass-through.
    //
    // push_strb values vary deliberately.  qstrb is NOT checked.
    // -----------------------------------------------------------------------
    bfm_send(
      32'h0123_4567,
      1'b0,
      1'b0,
      1'b0,
      4'b0000,
      4'b0001
    );

    bfm_send(
      32'h89AB_CDEF,
      1'b1,
      1'b0,
      1'b0,
      4'b1111,
      4'b1010
    );

    bfm_send(
      32'h1357_9BDF,
      1'b0,
      1'b1,
      1'b0,
      4'b0101,
      4'b0000
    );

    tb_wait_all();


    // -----------------------------------------------------------------------
    // P1 under backpressure.
    //
    // In pass-through mode the two handshakes must literally be the same
    // handshake.
    // -----------------------------------------------------------------------
    bfm_ready(1'b0);

    bfm_send(
      32'hCAFE_BABE,
      1'b0,
      1'b0,
      1'b0,
      4'b0011,
      4'b0110
    );

    repeat (4) @(posedge clk);

    bfm_ready(1'b1);
    tb_wait_all();


    // -----------------------------------------------------------------------
    // X1 -- asynchronous reset while qvalid is known high.
    // -----------------------------------------------------------------------
    test_async_reset();


    // -----------------------------------------------------------------------
    // R1-R6 -- all five legal rotation values.
    //
    // Especially important:
    //   R=0 => output is current beat
    //   R=4 => output is retained beat
    // -----------------------------------------------------------------------
    test_rotation(0);
    test_rotation(1);
    test_rotation(2);
    test_rotation(3);
    test_rotation(4);


    // -----------------------------------------------------------------------
    // R2 -- zero strb_i on an ordinary non-last beat silently consumes it.
    //
    // R5 additionally requires the following output to use that consumed beat
    // as the new retained beat.
    //
    // push_strb is intentionally the opposite of the line gate in several
    // places: push_strb_i has no specified realignment meaning.
    // -----------------------------------------------------------------------
    bfm_send(
      32'h1312_1110,
      1'b1,
      1'b0,
      1'b1,
      4'b0101,              // popcount = 2
      4'b0000
    );

    bfm_send(
      32'h1716_1514,
      1'b0,
      1'b0,
      1'b1,
      4'b0000,              // MUST NOT produce output
      4'b1111
    );

    bfm_send(
      32'h1B1A_1918,
      1'b0,
      1'b0,
      1'b1,
      4'b0010,              // MUST produce output
      4'b0000
    );

    bfm_send(
      32'h1F1E_1D1C,
      1'b0,
      1'b1,
      1'b1,
      4'b0000,              // last forces output
      4'b0101
    );

    tb_wait_all();


    // -----------------------------------------------------------------------
    // L1 -- first beat while sink not ready.
    //
    // We deliberately make NO assertion about whether the first input is
    // accepted during these cycles.  Both choices are legal.  R1 still says
    // the first beat itself must not create an output.
    // -----------------------------------------------------------------------
    bfm_ready(1'b0);

    bfm_send(
      32'h2322_2120,
      1'b1,
      1'b0,
      1'b1,
      4'b1101,              // rotation 3
      4'b0011
    );

    repeat (5) @(posedge clk);

    bfm_ready(1'b1);

    // Let the first beat complete if the implementation chose to stall it.
    bfm_idle(40);

    // Finish the line.
    bfm_send(
      32'h2726_2524,
      1'b0,
      1'b1,
      1'b1,
      4'b0000,
      4'b1000
    );

    tb_wait_all();


    // -----------------------------------------------------------------------
    // X2 -- synchronous clear in the middle of a line.
    //
    // After clear, a fresh first beat must establish a completely new line
    // and rotation.
    // -----------------------------------------------------------------------
    bfm_send(
      32'h3332_3130,
      1'b1,
      1'b0,
      1'b1,
      4'b1000,              // old rotation = 1
      4'b1111
    );

    tb_wait_all();

    bfm_clear();

    bfm_send(
      32'h4342_4140,
      1'b1,
      1'b0,
      1'b1,
      4'b1111,              // new rotation = 4
      4'b0001
    );

    bfm_send(
      32'h4746_4544,
      1'b0,
      1'b1,
      1'b1,
      4'b0000,
      4'b0010
    );

    tb_wait_all();


    // -----------------------------------------------------------------------
    // Reset must also discard an in-progress line.
    // -----------------------------------------------------------------------
    bfm_send(
      32'h5352_5150,
      1'b1,
      1'b0,
      1'b1,
      4'b0011,              // rotation 2
      4'b1111
    );

    tb_wait_all();

    bfm_reset(3);

    bfm_send(
      32'h6362_6160,
      1'b1,
      1'b0,
      1'b1,
      4'b1000,              // new rotation 1
      4'b0000
    );

    bfm_send(
      32'h6766_6564,
      1'b0,
      1'b1,
      1'b1,
      4'b0000,
      4'b1111
    );

    tb_wait_all();


    // -----------------------------------------------------------------------
    // Successful verdict
    // -----------------------------------------------------------------------
    if (!verdict_done) begin
      verdict_done = 1'b1;
      $display("RESULT: PASS");
      $finish;
    end
  end


  // ---------------------------------------------------------------------------
  // WATCHDOG
  // ---------------------------------------------------------------------------
  initial begin
    #2_000_000;

    if (!verdict_done) begin
      verdict_done = 1'b1;
      $display("FAILURE [Termination/X3]: watchdog expired before a verdict");
      $display("RESULT: FAIL");
      $finish;
    end
  end

endmodule