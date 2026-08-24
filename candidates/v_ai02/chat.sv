module stream_realign_tb;

  // ---------------------------------------------------------------------------
  // PROVIDED PLUMBING -- moves beats, checks nothing.
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
    .clk_i(clk), .rst_ni(rst_n), .clear_i(clr), .realign_i(ra), .first_i(fst),
    .last_i(lst), .strb_i(strb), .push_data_i(pdata), .push_strb_i(pstrb),
    .push_valid_i(pvalid), .push_ready_o(pready), .pop_data_o(qdata),
    .pop_strb_o(qstrb), .pop_valid_o(qvalid), .pop_ready_i(qready)
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

  task automatic bfm_send(input logic [31:0] data, input bit first, input bit last,
                          input bit do_realign, input logic [3:0] lstrb,
                          input logic [3:0] dstrb = 4'hF);
    bfm_beat_t b;
    b.data = data;
    b.dstrb = dstrb;
    b.first = first;
    b.last = last;
    b.realign = do_realign;
    b.lstrb = lstrb;
    bfm_q.push_back(b);
  endtask

  task automatic bfm_ready(input bit v);
    qready = v;
  endtask

  task automatic bfm_idle(input int max_cycles = 400);
    int t;
    bit done;
    done = 1'b0;
    for (t = 0; t < max_cycles; t++) begin
      @(posedge clk);
      if (bfm_q.size() == 0 && !pvalid) begin
        done = 1'b1;
        break;
      end
    end
    if (!done) begin
      fail_now("X3", "queued input did not become idle");
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
        pdata = bfm_q[0].data;
        pstrb = bfm_q[0].dstrb;
        fst = bfm_q[0].first;
        lst = bfm_q[0].last;
        strb = bfm_q[0].lstrb;
        ra = bfm_q[0].realign;
        pvalid = 1'b1;
      end
    end
  end

  // ---------------------------------------------------------------------------
  // CHECKER
  // ---------------------------------------------------------------------------

  typedef struct packed {
    logic [31:0] data_a;
    logic [31:0] data_b;
    logic        allow_b;
  } exp_pop_t;

  exp_pop_t exp_pop_q[$];
  exp_pop_t exp_push;
  exp_pop_t exp_chk;

  logic        model_have_line;
  logic [31:0] model_retained_a;
  logic [31:0] model_retained_b;
  logic        model_two_retained;
  int          model_rot;

  int offer_wait;
  int realign_inputs;
  int realign_outputs;
  int pass_inputs;
  int pass_outputs;

  bit verdict_printed = 1'b0;
  bit seen_posedge = 1'b0;

  function automatic int rotation_count(input logic [3:0] x);
    int c;
    begin
      c = int'(x[0]) + int'(x[1]) + int'(x[2]) + int'(x[3]);
      rotation_count = c;
    end
  endfunction

  function automatic logic [31:0] joined_data(
    input logic [31:0] current_data,
    input logic [31:0] retained_data,
    input int rot
  );
    begin
      case (rot)
        0: joined_data = current_data;
        1: joined_data = {current_data[23:0], retained_data[31:24]};
        2: joined_data = {current_data[15:0], retained_data[31:16]};
        3: joined_data = {current_data[7:0],  retained_data[31:8]};
        4: joined_data = retained_data;
        default: joined_data = 32'hxxxx_xxxx;
      endcase
    end
  endfunction

  task automatic fail_now(input string clause_name, input string msg);
    if (!verdict_printed) begin
      verdict_printed = 1'b1;
      $display("FAIL %s: %s", clause_name, msg);
      $display("RESULT: FAIL");
      $finish;
    end
  endtask

  task automatic pass_now();
    if (!verdict_printed) begin
      verdict_printed = 1'b1;
      $display("RESULT: PASS");
      $finish;
    end
  endtask

  task automatic safe_ready(input bit v);
    @(negedge clk);
    qready = v;
  endtask

  task automatic wait_expected_empty(input int max_cycles, input string clause_name);
    int t;
    bit done;
    done = 1'b0;
    for (t = 0; t < max_cycles; t++) begin
      @(posedge clk);
      if (exp_pop_q.size() == 0) begin
        done = 1'b1;
        break;
      end
    end
    if (!done)
      fail_now(clause_name, "expected realigned output did not complete");
    repeat (6) @(posedge clk);
  endtask

  always @(posedge clk)
    seen_posedge = 1'b1;

  // X1 is sampled after a rising edge, never at time zero. Inputs are quiet
  // whenever reset is asserted by the stimulus.
  always @(negedge clk) begin
    if (seen_posedge && !rst_n && !pvalid) begin
      if (qvalid !== 1'b0)
        fail_now("X1", "output valid remained asserted during reset with quiet input");
    end
  end

  // Scoreboard and protocol checks. The input handshake is processed before
  // the output handshake so a zero-latency realigned output is accepted.
  always @(posedge clk) begin
    if (!rst_n) begin
      exp_pop_q.delete();
      model_have_line = 1'b0;
      model_retained_a = '0;
      model_retained_b = '0;
      model_two_retained = 1'b0;
      model_rot = 0;
      offer_wait = 0;
    end else if (clr) begin
      exp_pop_q.delete();
      model_have_line = 1'b0;
      model_retained_a = '0;
      model_retained_b = '0;
      model_two_retained = 1'b0;
      model_rot = 0;
      offer_wait = 0;
    end else begin

      // X3: only applies while the sink is held ready.
      if (pvalid && qready) begin
        if (pready) begin
          offer_wait = 0;
        end else begin
          offer_wait = offer_wait + 1;
          if (offer_wait >= 16)
            fail_now("X3", "offered input beat was not accepted within 16 cycles");
        end
      end else begin
        offer_wait = 0;
      end

      // P1/H3: transparent-mode data and handshake. H3 says ready carries no
      // meaning without an offer, so pready is compared only while pvalid=1.
      if (!ra) begin
        if (qvalid !== pvalid)
          fail_now("P1", "pop_valid_o does not follow push_valid_i in transparent mode");

        if (pvalid) begin
          if (pready !== qready)
            fail_now("P1/H3", "push_ready_o does not follow pop_ready_i while a transparent beat is offered");

          if (qdata !== pdata)
            fail_now("P1", "transparent-mode data was modified");
        end
      end

      // Input-side model for realignment mode.
      if (pvalid && pready) begin
        if (!ra) begin
          pass_inputs = pass_inputs + 1;
        end else begin
          realign_inputs = realign_inputs + 1;

          if (fst) begin
            // R1/R4: first beat is retained and fixes rotation. It owes no output.
            model_have_line = 1'b1;
            model_retained_a = pdata;
            model_retained_b = pdata;
            model_two_retained = 1'b0;
            model_rot = rotation_count(strb);

            if (lst)
              model_have_line = 1'b0;

          end else if (model_have_line) begin
            if (lst || (strb != 4'b0000)) begin
              // R2: an output is owed. L4 may have left two legal retained
              // values after one silently-consumed beat, so accept either.
              exp_push.data_a = joined_data(pdata, model_retained_a, model_rot);
              exp_push.data_b = joined_data(pdata, model_retained_b, model_rot);
              exp_push.allow_b = model_two_retained &&
                                 (exp_push.data_a != exp_push.data_b);
              exp_pop_q.push_back(exp_push);

              // For a produced beat, the current beat is the retained beat for
              // the next normal join; this is required by R5 when no beat is
              // silently consumed.
              model_retained_a = pdata;
              model_retained_b = pdata;
              model_two_retained = 1'b0;

              if (lst)
                model_have_line = 1'b0;

            end else begin
              // R2: no output. L4 permits either keeping the prior retained beat
              // or replacing it with this silently-consumed beat.
              model_retained_b = pdata;
              model_two_retained = 1'b1;
            end
          end
        end
      end

      // Output-side checking.
      if (qvalid && qready) begin
        if (!ra) begin
          // P1 has already established that this is the same handshake and data.
          pass_outputs = pass_outputs + 1;
        end else begin
          if (exp_pop_q.size() == 0)
            fail_now("R1/R2", "realign mode produced an output beat when none was owed");

          exp_chk = exp_pop_q.pop_front();

          if ((qdata !== exp_chk.data_a) &&
              !(exp_chk.allow_b && (qdata === exp_chk.data_b))) begin
            if (exp_chk.allow_b) begin
              fail_now(
                "R2/R4/R5",
                $sformatf(
                  "realigned data mismatch: got %08h expected %08h or %08h",
                  qdata, exp_chk.data_a, exp_chk.data_b
                )
              );
            end else begin
              fail_now(
                "R2/R4/R5",
                $sformatf(
                  "realigned data mismatch: got %08h expected %08h",
                  qdata, exp_chk.data_a
                )
              );
            end
          end

          if (qstrb !== 4'hF)
            fail_now("R3", $sformatf("realigned output strobe was %h instead of F", qstrb));

          realign_outputs = realign_outputs + 1;
        end
      end
    end
  end

  // ---------------------------------------------------------------------------
  // DIRECTED STIMULUS
  // ---------------------------------------------------------------------------
  initial begin
    int base_pass_in;
    int base_pass_out;
    int base_real_out;

    pass_inputs = 0;
    pass_outputs = 0;
    realign_inputs = 0;
    realign_outputs = 0;

    // Establish defined state. The reset checker intentionally ignores time zero.
    bfm_reset(5);
    repeat (2) @(posedge clk);

    // -----------------------------------------------------------------------
    // P1/P2/L3: transparent mode. Vary push_strb_i and strb_i deliberately;
    // only data and handshake are constrained in this mode.
    // -----------------------------------------------------------------------
    base_pass_in = pass_inputs;
    base_pass_out = pass_outputs;

    bfm_send(32'h1122_3344, 1'b0, 1'b0, 1'b0, 4'b0000, 4'b0001);
    bfm_send(32'h5566_7788, 1'b1, 1'b0, 1'b0, 4'b1010, 4'b0101);
    bfm_send(32'h99AA_BBCC, 1'b0, 1'b1, 1'b0, 4'b1111, 4'b1000);
    bfm_idle(100);

    if ((pass_inputs - base_pass_in) != 3 ||
        (pass_outputs - base_pass_out) != 3)
      fail_now("P1", "transparent-mode beat count mismatch");

    // Transparent-mode backpressure: qvalid must still follow pvalid, data must
    // remain transparent, and the input handshake must wait for qready.
    safe_ready(1'b0);
    bfm_send(32'hD4C3_B2A1, 1'b0, 1'b1, 1'b0, 4'b0011, 4'b0010);
    repeat (5) @(posedge clk);
    safe_ready(1'b1);
    bfm_idle(100);

    // -----------------------------------------------------------------------
    // R=0. First beat produces nothing; later beats output current data.
    // The final beat has strb_i=0 to exercise R6 as well.
    // -----------------------------------------------------------------------
    bfm_clear();
    base_real_out = realign_outputs;

    bfm_send(32'h4433_2211, 1'b1, 1'b0, 1'b1, 4'b0000, 4'b0001);
    bfm_send(32'h8877_6655, 1'b0, 1'b0, 1'b1, 4'b1000, 4'b0101);
    bfm_send(32'hCCBB_AA99, 1'b0, 1'b1, 1'b1, 4'b0000, 4'b0010);
    bfm_idle(150);
    wait_expected_empty(150, "R1/R2/R6");

    if ((realign_outputs - base_real_out) != 2)
      fail_now("R1/R2", "R=0 line produced the wrong number of output beats");

    // -----------------------------------------------------------------------
    // R=1 from popcount(0100), not from bit position/numeric value. Later
    // strb_i values change but the rotation must remain fixed by the first beat.
    // -----------------------------------------------------------------------
    bfm_clear();
    base_real_out = realign_outputs;

    bfm_send(32'h4433_2211, 1'b1, 1'b0, 1'b1, 4'b0100, 4'b0011);
    bfm_send(32'h8877_6655, 1'b0, 1'b0, 1'b1, 4'b1111, 4'b0101);
    bfm_send(32'hCCBB_AA99, 1'b0, 1'b1, 1'b1, 4'b0011, 4'b1000);
    bfm_idle(150);
    wait_expected_empty(150, "R2/R4/R5");

    if ((realign_outputs - base_real_out) != 2)
      fail_now("R2", "R=1 line produced the wrong number of output beats");

    // -----------------------------------------------------------------------
    // R=2 from popcount(1001), with a four-beat byte stream to stress carrying
    // bytes across multiple beat boundaries.
    // -----------------------------------------------------------------------
    bfm_clear();
    base_real_out = realign_outputs;

    bfm_send(32'h0403_0201, 1'b1, 1'b0, 1'b1, 4'b1001, 4'b0001);
    bfm_send(32'h0807_0605, 1'b0, 1'b0, 1'b1, 4'b0001, 4'b0010);
    bfm_send(32'h0C0B_0A09, 1'b0, 1'b0, 1'b1, 4'b1000, 4'b0100);
    bfm_send(32'h100F_0E0D, 1'b0, 1'b1, 1'b1, 4'b0010, 4'b1000);
    bfm_idle(150);
    wait_expected_empty(150, "R2/R4/R5");

    if ((realign_outputs - base_real_out) != 3)
      fail_now("R2/R5", "R=2 line produced the wrong number of output beats");

    // -----------------------------------------------------------------------
    // R=3.
    // -----------------------------------------------------------------------
    bfm_clear();
    base_real_out = realign_outputs;

    bfm_send(32'hA4A3_A2A1, 1'b1, 1'b0, 1'b1, 4'b0111, 4'b0101);
    bfm_send(32'hB4B3_B2B1, 1'b0, 1'b0, 1'b1, 4'b0001, 4'b0010);
    bfm_send(32'hC4C3_C2C1, 1'b0, 1'b1, 1'b1, 4'b0100, 4'b1000);
    bfm_idle(150);
    wait_expected_empty(150, "R2/R4/R5");

    if ((realign_outputs - base_real_out) != 2)
      fail_now("R2", "R=3 line produced the wrong number of output beats");

    // -----------------------------------------------------------------------
    // R=4 is explicitly NOT modulo four. Each output is the retained prior beat.
    // -----------------------------------------------------------------------
    bfm_clear();
    base_real_out = realign_outputs;

    bfm_send(32'h1357_9BDF, 1'b1, 1'b0, 1'b1, 4'b1111, 4'b0001);
    bfm_send(32'h2468_ACE0, 1'b0, 1'b0, 1'b1, 4'b0001, 4'b0010);
    bfm_send(32'h0BAD_F00D, 1'b0, 1'b1, 1'b1, 4'b0010, 4'b0100);
    bfm_idle(150);
    wait_expected_empty(150, "R2/R4/R5");

    if ((realign_outputs - base_real_out) != 2)
      fail_now("R2", "R=4 line produced the wrong number of output beats");

    // -----------------------------------------------------------------------
    // R2/L4/R6: one silently-consumed middle beat. It MUST produce no output.
    // The next last beat has strb_i=0 and MUST produce one. Its data may legally
    // use either retained interpretation allowed by L4; the checker accepts both.
    // -----------------------------------------------------------------------
    bfm_clear();
    base_real_out = realign_outputs;

    bfm_send(32'h4030_2010, 1'b1, 1'b0, 1'b1, 4'b0011, 4'b0001);
    bfm_send(32'h8070_6050, 1'b0, 1'b0, 1'b1, 4'b0000, 4'b0010);
    bfm_idle(150);

    if ((realign_outputs - base_real_out) != 0)
      fail_now("R1/R2", "first/silently-consumed beats incorrectly produced output");

    bfm_send(32'hC0B0_A090, 1'b0, 1'b1, 1'b1, 4'b0000, 4'b0100);
    bfm_idle(150);
    wait_expected_empty(150, "R6/L4");

    if ((realign_outputs - base_real_out) != 1)
      fail_now("R2/R6", "last beat with clear strb_i did not produce exactly one output");

    // -----------------------------------------------------------------------
    // R1: first and last asserted together still names the first beat; R1 says
    // the first beat produces no output. Clear afterward before beginning a line.
    // -----------------------------------------------------------------------
    bfm_clear();
    base_real_out = realign_outputs;

    bfm_send(32'hFACE_CAFE, 1'b1, 1'b1, 1'b1, 4'b1111, 4'b0001);
    bfm_idle(100);

    if ((realign_outputs - base_real_out) != 0)
      fail_now("R1", "a first beat produced an output beat");

    // -----------------------------------------------------------------------
    // X2: synchronous clear must discard retained state. Start an old line,
    // clear it, then verify a new line uses only the new first beat/rotation.
    // -----------------------------------------------------------------------
    bfm_clear();
    bfm_send(32'hDEAD_BEEF, 1'b1, 1'b0, 1'b1, 4'b1111, 4'b1111);
    bfm_idle(100);

    bfm_clear();
    base_real_out = realign_outputs;
    bfm_send(32'h1122_3344, 1'b1, 1'b0, 1'b1, 4'b0100, 4'b0001);
    bfm_send(32'h5566_7788, 1'b0, 1'b1, 1'b1, 4'b1000, 4'b0010);
    bfm_idle(150);
    wait_expected_empty(150, "X2/R2");

    if ((realign_outputs - base_real_out) != 1)
      fail_now("X2", "new line after clear produced the wrong output count");

    // -----------------------------------------------------------------------
    // X1: asynchronous reset must likewise discard a retained first beat.
    // -----------------------------------------------------------------------
    bfm_clear();
    bfm_send(32'hAAAA_5555, 1'b1, 1'b0, 1'b1, 4'b0011, 4'b0101);
    bfm_idle(100);

    bfm_reset(4);
    repeat (2) @(posedge clk);

    base_real_out = realign_outputs;
    bfm_send(32'h0A0B_0C0D, 1'b1, 1'b0, 1'b1, 4'b0111, 4'b0001);
    bfm_send(32'h1A1B_1C1D, 1'b0, 1'b1, 1'b1, 4'b0001, 4'b0010);
    bfm_idle(150);
    wait_expected_empty(150, "X1/R2");

    if ((realign_outputs - base_real_out) != 1)
      fail_now("X1", "new line after reset produced the wrong output count");

    // Final clean state and verdict.
    bfm_clear();
    repeat (4) @(posedge clk);

    if (exp_pop_q.size() != 0)
      fail_now("R2", "expected-output queue was not empty at end of test");

    pass_now();
  end

  // ---- watchdog ------------------------------------------------------------
  initial begin
    #2_000_000;
    fail_now("Termination/X3", "watchdog: no verdict reached");
  end

endmodule