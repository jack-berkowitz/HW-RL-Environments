`timescale 1ns/1ps

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
    @(negedge clk) clr = 1'b1;
    @(negedge clk) clr = 1'b0;
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

  // ---------------------------------------------------------------------------
  // CHECKER / REFERENCE MODEL
  // ---------------------------------------------------------------------------

  typedef struct packed {
    logic [31:0] data;
    logic [3:0]  strobe;
  } exp_beat_t;

  exp_beat_t exp_q [$];

  logic        model_line = 1'b0;
  logic        model_defined = 1'b0;
  logic [31:0] model_retained = '0;
  int          model_rot = 0;
  int          live_wait = 0;
  bit          verdict_done = 1'b0;

  function automatic int popcount4(input logic [3:0] s);
    popcount4 = s[0] + s[1] + s[2] + s[3];
  endfunction

  function automatic logic [31:0] join_at_rotation(
    input logic [31:0] current_beat,
    input logic [31:0] retained_beat,
    input int          rot
  );
    case (rot)
      0: join_at_rotation = current_beat;
      1: join_at_rotation =
           (current_beat << 8) |
           (retained_beat >> 24);
      2: join_at_rotation =
           (current_beat << 16) |
           (retained_beat >> 16);
      3: join_at_rotation =
           (current_beat << 24) |
           (retained_beat >> 8);
      4: join_at_rotation = retained_beat;
      default: join_at_rotation = '0;
    endcase
  endfunction

  function automatic logic [31:0] make_beat(input logic [7:0] base);
    make_beat = {
      base + 8'd3,
      base + 8'd2,
      base + 8'd1,
      base
    };
  endfunction

  task automatic fail_clause(
    input string clause_name,
    input string detail
  );
    if (!verdict_done) begin
      verdict_done = 1'b1;
      $display("FAIL [%s]: %s", clause_name, detail);
      $display("RESULT: FAIL");
      $finish;
    end
  endtask

  // Change sink readiness only on the edge opposite the DUT sampling edge.
  task automatic set_ready_safe(input bit v);
    @(negedge clk);
    bfm_ready(v);
  endtask

  // Wait for all offered input and all modeled output to drain.
  task automatic wait_all(
    input int    max_cycles,
    input string where_text
  );
    automatic int t;
    automatic bit done;

    done = 1'b0;

    for (t = 0; t < max_cycles; t = t + 1) begin
      @(posedge clk);

      if ((bfm_q.size() == 0) &&
          !pvalid &&
          (exp_q.size() == 0) &&
          !qvalid) begin
        done = 1'b1;
        break;
      end
    end

    if (!done) begin
      if ((bfm_q.size() != 0) || pvalid) begin
        fail_clause(
          "X3",
          $sformatf(
            "input did not drain at %s",
            where_text
          )
        );
      end else if (exp_q.size() != 0) begin
        fail_clause(
          "R2",
          $sformatf(
            "required realigned output never appeared at %s",
            where_text
          )
        );
      end else begin
        fail_clause(
          "R1/R2",
          $sformatf(
            "unexpected pop_valid_o remained asserted at %s",
            where_text
          )
        );
      end
    end
  endtask

  task automatic queue_rotation_line(
    input logic [3:0] first_mask,
    input logic [7:0] base
  );
    bfm_send(
      make_beat(base),
      1'b1, 1'b0, 1'b1,
      first_mask,
      4'b0001
    );

    bfm_send(
      make_beat(base + 8'd4),
      1'b0, 1'b0, 1'b1,
      4'b1111,
      4'b0010
    );

    bfm_send(
      make_beat(base + 8'd8),
      1'b0, 1'b0, 1'b1,
      4'b0001,
      4'b0100
    );

    bfm_send(
      make_beat(base + 8'd12),
      1'b0, 1'b1, 1'b1,
      4'b1010,
      4'b1000
    );
  endtask

  // ---------------------------------------------------------------------------
  // MAIN CHECKER
  //
  // Handshakes are sampled at the rising edge, exactly as H1 specifies.
  //
  // An expected beat is inserted before checking the output handshake. This
  // allows both a zero-latency implementation and a registered implementation.
  // ---------------------------------------------------------------------------

  always @(posedge clk) begin
    automatic exp_beat_t eb;

    if (!rst_n) begin
      exp_q.delete();

      model_line     = 1'b0;
      model_defined  = 1'b0;
      model_retained = '0;
      model_rot      = 0;
      live_wait      = 0;

      if (qvalid) begin
        fail_clause(
          "X1",
          "pop_valid_o asserted while rst_ni is low"
        );
      end

    end else if (clr) begin
      exp_q.delete();

      model_line     = 1'b0;
      model_defined  = 1'b0;
      model_retained = '0;
      model_rot      = 0;
      live_wait      = 0;

    end else begin

      // ---------------------------------------------------------------------
      // P1
      //
      // H3 specifically says push_ready_o has no meaning when no input is
      // offered, so ready is checked only while pvalid is high.
      // ---------------------------------------------------------------------
      if (!ra) begin
        if (qvalid !== pvalid) begin
          fail_clause(
            "P1",
            "pop_valid_o does not follow push_valid_i in pass-through mode"
          );
        end

        if (pvalid) begin
          if (pready !== qready) begin
            fail_clause(
              "P1",
              "push_ready_o does not follow pop_ready_i in pass-through mode"
            );
          end

          if (qdata !== pdata) begin
            fail_clause(
              "P1",
              $sformatf(
                "pass-through data mismatch: got %08x expected %08x",
                qdata,
                pdata
              )
            );
          end

          if (qstrb !== pstrb) begin
            fail_clause(
              "P1",
              $sformatf(
                "pass-through strobe mismatch: got %x expected %x",
                qstrb,
                pstrb
              )
            );
          end
        end
      end

      // ---------------------------------------------------------------------
      // X3
      //
      // With pop_ready_i continuously high, an offered beat cannot remain
      // unaccepted for 16 complete sampling opportunities.
      // ---------------------------------------------------------------------
      if (qready && pvalid) begin
        if (pready) begin
          live_wait = 0;
        end else begin
          live_wait = live_wait + 1;

          if (live_wait >= 16) begin
            fail_clause(
              "X3",
              "offered input beat was not accepted within 16 cycles while pop_ready_i stayed high"
            );
          end
        end
      end else begin
        live_wait = 0;
      end

      // ---------------------------------------------------------------------
      // Accepted realignment input.
      // ---------------------------------------------------------------------
      if (pvalid && pready && ra) begin

        if (fst) begin
          // R1:
          // First beat is consumed/retained but does not generate an output.
          //
          // R4:
          // Its strb_i fixes rotation for the entire line.
          model_line     = 1'b1;
          model_defined  = 1'b1;
          model_rot      = popcount4(strb);
          model_retained = pdata;

        end else if (model_line) begin

          // R2 / R6:
          // A post-first beat generates output iff strb_i != 0 OR last_i.
          if (lst || (strb != 4'b0000)) begin
            eb.data =
              join_at_rotation(
                pdata,
                model_retained,
                model_rot
              );

            // R3.
            eb.strobe = 4'hF;

            exp_q.push_back(eb);
          end

          // Even a beat which is silently consumed because its gate is zero
          // becomes the predecessor for the following beat.
          model_retained = pdata;

          if (lst)
            model_line = 1'b0;
        end

        // If a valid first beat has never established a line, the specification
        // deliberately gives no behavior to check, so no expectation is
        // invented here.
      end

      // ---------------------------------------------------------------------
      // Output checking.
      //
      // Only inspect the payload when a real output transaction occurs.
      // Therefore pop_data_o/pop_strb_o with pop_valid_o == 0 remain completely
      // unconstrained as required by L2.
      // ---------------------------------------------------------------------
      if (qvalid && qready && ra) begin

        if (exp_q.size() != 0) begin

          if (qdata !== exp_q[0].data) begin
            fail_clause(
              "R2/R4/R5",
              $sformatf(
                "realigned data mismatch: got %08x expected %08x",
                qdata,
                exp_q[0].data
              )
            );
          end

          if (qstrb !== exp_q[0].strobe) begin
            fail_clause(
              "R3",
              $sformatf(
                "realigned output strobe was %x, expected f",
                qstrb
              )
            );
          end

          void'(exp_q.pop_front());

        end else if (model_defined || (pvalid && fst)) begin
          fail_clause(
            "R1/R2",
            "an output beat was transferred when the specified line model produced none"
          );
        end
      end
    end
  end

  // ---------------------------------------------------------------------------
  // WATCHDOG
  //
  // A design which never accepts anything must fail rather than hang.
  // ---------------------------------------------------------------------------
  initial begin
    #2_000_000;

    if (!verdict_done) begin
      verdict_done = 1'b1;
      $display(
        "FAIL [termination/X3]: watchdog reached before a verdict"
      );
      $display("RESULT: FAIL");
      $finish;
    end
  end

  // ---------------------------------------------------------------------------
  // STIMULUS
  // ---------------------------------------------------------------------------

  initial begin : main_stimulus
    automatic int k;
    automatic bit accepted_while_stalled;

    // -----------------------------------------------------------------------
    // Initial asynchronous-active-low reset / X1.
    // -----------------------------------------------------------------------
    bfm_reset(5);
    @(posedge clk);

    // -----------------------------------------------------------------------
    // P1: ordinary pass-through.
    // -----------------------------------------------------------------------
    set_ready_safe(1'b1);
    @(posedge clk);

    bfm_send(
      32'h44332211,
      1'b0, 1'b0, 1'b0,
      4'b0000,
      4'b0001
    );

    bfm_send(
      32'h88776655,
      1'b1, 1'b0, 1'b0,
      4'b1010,
      4'b1010
    );

    bfm_send(
      32'hCCBBAA99,
      1'b0, 1'b1, 1'b0,
      4'b1111,
      4'b0101
    );

    wait_all(
      60,
      "P1 free-running pass-through"
    );

    // -----------------------------------------------------------------------
    // P1 with sink backpressure.
    //
    // In pass-through mode qvalid must continue to mirror pvalid, payload must
    // remain the offered payload, and pready must mirror qready.
    // -----------------------------------------------------------------------
    set_ready_safe(1'b0);
    @(posedge clk);

    bfm_send(
      32'hDEADBEEF,
      1'b0, 1'b0, 1'b0,
      4'b0110,
      4'b0011
    );

    repeat (4) @(posedge clk);

    set_ready_safe(1'b1);

    wait_all(
      60,
      "P1 pass-through backpressure"
    );

    // -----------------------------------------------------------------------
    // R1-R5: all five legal rotations.
    //
    // Noncontiguous first masks ensure that R is popcount(strb_i), rather than
    // the numerical value of the mask or a leading/trailing-one interpretation.
    //
    // Masks after the first beat deliberately change. If the implementation
    // illegally recomputes R every beat, these cases fail.
    // -----------------------------------------------------------------------
    @(posedge clk);

    queue_rotation_line(
      4'b0000,
      8'h10
    ); // R = 0

    queue_rotation_line(
      4'b1000,
      8'h30
    ); // R = 1

    queue_rotation_line(
      4'b0101,
      8'h50
    ); // R = 2

    queue_rotation_line(
      4'b1011,
      8'h70
    ); // R = 3

    queue_rotation_line(
      4'b1111,
      8'h90
    ); // R = 4 -- specifically NOT zero

    wait_all(
      180,
      "R0..R4 rotation sweep"
    );

    // -----------------------------------------------------------------------
    // R2/R3/R4/R6.
    //
    // First beat establishes R=2.
    //
    // Second beat:
    //   strb_i = 0, last_i = 0
    //   => silently consumed, no output.
    //
    // Third beat:
    //   strb_i != 0
    //   => output, and predecessor must be the SILENTLY CONSUMED second beat.
    //
    // Fourth beat:
    //   strb_i = 0, last_i = 1
    //   => R6 requires output anyway.
    //
    // push_strb_i deliberately disagrees with strb_i. It must not alter the
    // realignment rule, and R3 requires output strobe 4'hF.
    // -----------------------------------------------------------------------
    @(posedge clk);

    bfm_send(
      make_beat(8'hB0),
      1'b1, 1'b0, 1'b1,
      4'b0101,
      4'b0001
    );

    bfm_send(
      make_beat(8'hB4),
      1'b0, 1'b0, 1'b1,
      4'b0000,
      4'b1111
    );

    bfm_send(
      make_beat(8'hB8),
      1'b0, 1'b0, 1'b1,
      4'b0001,
      4'b0000
    );

    bfm_send(
      make_beat(8'hBC),
      1'b0, 1'b1, 1'b1,
      4'b0000,
      4'b0010
    );

    wait_all(
      100,
      "R2 gate / R3 strobe / R6 last override"
    );

    // -----------------------------------------------------------------------
    // L1 + R1.
    //
    // Present only the first beat while qready is low.
    //
    // A conforming DUT may either:
    //   * accept it immediately, or
    //   * wait until qready becomes high.
    //
    // The testbench intentionally requires neither choice.
    //
    // However, R1 still requires the first beat itself to produce no output.
    // -----------------------------------------------------------------------
    set_ready_safe(1'b0);
    @(posedge clk);

    bfm_send(
      make_beat(8'hD0),
      1'b1, 1'b0, 1'b1,
      4'b0010,
      4'b1110
    );

    for (k = 0; k < 5; k = k + 1) begin
      @(posedge clk);

      if (qvalid) begin
        fail_clause(
          "R1",
          "first beat of a line asserted pop_valid_o while no earlier output was pending"
        );
      end
    end

    set_ready_safe(1'b1);

    wait_all(
      50,
      "L1 first-beat acceptance latitude"
    );

    @(posedge clk);

    bfm_send(
      make_beat(8'hD4),
      1'b0, 1'b1, 1'b1,
      4'b0001,
      4'b0000
    );

    wait_all(
      60,
      "line completion after L1 test"
    );

    // -----------------------------------------------------------------------
    // Realignment output backpressure.
    //
    // A DUT may internally buffer the second beat or may stall it. The checker
    // follows actual handshakes and therefore accepts either architecture.
    // -----------------------------------------------------------------------
    @(posedge clk);

    bfm_send(
      make_beat(8'hE0),
      1'b1, 1'b0, 1'b1,
      4'b0110,
      4'b0101
    );

    wait_all(
      50,
      "backpressure setup first beat"
    );

    set_ready_safe(1'b0);
    @(posedge clk);

    bfm_send(
      make_beat(8'hE4),
      1'b0, 1'b1, 1'b1,
      4'b1000,
      4'b1010
    );

    repeat (5) @(posedge clk);

    set_ready_safe(1'b1);

    wait_all(
      80,
      "realignment output backpressure"
    );

    // -----------------------------------------------------------------------
    // X2.
    //
    // Establish an old line, then clear it. If this implementation happens to
    // accept an output-producing beat while the sink is stalled, the test also
    // gets the stronger case of clearing a genuinely pending output.
    // -----------------------------------------------------------------------
    @(posedge clk);

    bfm_send(
      make_beat(8'h20),
      1'b1, 1'b0, 1'b1,
      4'b1000,
      4'b1111
    );

    wait_all(
      50,
      "X2 old-line first beat"
    );

    set_ready_safe(1'b0);
    @(posedge clk);

    bfm_send(
      make_beat(8'h24),
      1'b0, 1'b0, 1'b1,
      4'b0001,
      4'b1111
    );

    repeat (5) @(posedge clk);

    accepted_while_stalled =
      (exp_q.size() != 0);

    if (accepted_while_stalled) begin

      // Allow the BFM to retire the already-accepted source beat while keeping
      // its generated output blocked.
      for (k = 0; k < 4; k = k + 1) begin
        @(posedge clk);

        if (!pvalid)
          break;
      end

      bfm_clear();

      if (qvalid) begin
        fail_clause(
          "X2",
          "pop_valid_o remained asserted after synchronous clear removed pending state"
        );
      end

      set_ready_safe(1'b1);

    end else begin

      // A non-buffering implementation is also legal. Let its beat finish,
      // then clear the still-established line.
      set_ready_safe(1'b1);

      wait_all(
        70,
        "X2 nonbuffering pre-clear completion"
      );

      bfm_clear();
    end

    // -----------------------------------------------------------------------
    // Fresh line after clear.
    //
    // New line uses R=4. Neither the old R=1 nor old retained data may leak
    // into this line.
    // -----------------------------------------------------------------------
    @(posedge clk);

    bfm_send(
      make_beat(8'h40),
      1'b1, 1'b0, 1'b1,
      4'b1111,
      4'b0000
    );

    bfm_send(
      make_beat(8'h44),
      1'b0, 1'b1, 1'b1,
      4'b0001,
      4'b0000
    );

    wait_all(
      70,
      "X2 fresh line after clear"
    );

    // -----------------------------------------------------------------------
    // Reset recovery in the middle of an established line.
    //
    // After reset, start a proper new line rather than relying on behavior for
    // a non-first beat, which the contract deliberately leaves unspecified.
    // -----------------------------------------------------------------------
    @(posedge clk);

    bfm_send(
      make_beat(8'h60),
      1'b1, 1'b0, 1'b1,
      4'b0011,
      4'b1111
    );

    wait_all(
      50,
      "pre-reset first beat"
    );

    bfm_reset(3);

    @(posedge clk);

    bfm_send(
      make_beat(8'hA0),
      1'b1, 1'b0, 1'b1,
      4'b1011,
      4'b0011
    );

    bfm_send(
      make_beat(8'hA4),
      1'b0, 1'b1, 1'b1,
      4'b0001,
      4'b1100
    );

    wait_all(
      70,
      "fresh line after reset"
    );

    // -----------------------------------------------------------------------
    // Success.
    // -----------------------------------------------------------------------
    if (!verdict_done) begin
      verdict_done = 1'b1;
      $display("RESULT: PASS");
      $finish;
    end
  end

endmodule