`timescale 1ns/1ps

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
  // Reference model and checks
  // ---------------------------------------------------------------------------

  typedef struct packed {
    logic [31:0] data0;
    logic [31:0] data1;
    logic        alt_ok;    // permits the other L4 retention choice
    logic        realign;   // transparent-mode output strobe is not checked
  } expected_t;

  expected_t expected_q [$];

  int          rotation = 0;
  logic        line_active = 1'b0;
  logic [31:0] retained = '0;
  logic [31:0] retained_before_silent = '0;
  logic        silent_run = 1'b0;
  int          offer_age = 0;

  task automatic fail(input string clause, input string detail);
    $display("Violation of %s: %s (time=%0t, cycle=%0d)",
             clause, detail, $time, bfm_cycle);
    $display("RESULT: FAIL");
    $finish;
  endtask

  function automatic int count_strobe(input logic [3:0] s);
    int n;
    begin
      n = 0;
      for (int k = 0; k < 4; k++) n += s[k];
      count_strobe = n;
    end
  endfunction

  function automatic logic [31:0] joined_data(
      input logic [31:0] current_data,
      input logic [31:0] old_data,
      input int r);
    logic [31:0] current_part;
    logic [31:0] old_part;
    begin
      current_part = (r >= 4) ? 32'b0 : (current_data << (8*r));
      old_part     = (r <= 0) ? 32'b0 : (old_data >> (8*(4-r)));
      joined_data  = current_part | old_part;
    end
  endfunction

  // Expected beats are entered when an input beat is actually accepted.  This
  // handles both combinational and registered implementations, and avoids
  // treating an offered-but-unaccepted realignment beat as consumed.
  always @(posedge clk) begin
    automatic logic in_hs;
    automatic logic out_hs;
    automatic logic make_output;
    automatic logic [31:0] new_data0;
    automatic logic [31:0] new_data1;
    automatic expected_t new_entry;
    automatic expected_t observed_entry;

    in_hs       = 1'b0;
    out_hs      = 1'b0;
    make_output = 1'b0;
    new_data0   = 32'b0;
    new_data1   = 32'b0;
    new_entry   = '0;

    if (!rst_n || clr) begin
      expected_q.delete();
      rotation = 0;
      line_active = 1'b0;
      retained = 32'b0;
      retained_before_silent = 32'b0;
      silent_run = 1'b0;
      offer_age = 0;
    end else begin
      // P1 is a combinational transparency requirement, including while the
      // transparent input is backpressured.  No transparent strobe check is
      // made: P2/L3 deliberately leave it free.
      if (!ra) begin
        if (qvalid !== pvalid)
          fail("P1", "pop_valid_o does not follow push_valid_i in transparent mode");
        if (pready !== qready)
          fail("P1", "push_ready_o does not follow pop_ready_i in transparent mode");
        if (pvalid && (qdata !== pdata))
          fail("P1", "transparent data differs from push_data_i");
      end

      // X3, measured only while the sink is held ready.  The source holds each
      // offer unchanged, so age also measures a design that never accepts.
      if (pvalid && qready && !pready) begin
        offer_age = offer_age + 1;
        if (offer_age > 16)
          fail("X3", "an offered beat was not accepted within 16 cycles");
      end else begin
        offer_age = 0;
      end

      in_hs  = pvalid && pready;
      out_hs = qvalid && qready;

      if (in_hs) begin
        if (!ra) begin
          new_entry.data0  = pdata;
          new_entry.data1  = pdata;
          new_entry.alt_ok = 1'b0;
          new_entry.realign = 1'b0;
          expected_q.push_back(new_entry);
        end else if (fst) begin
          // R1/R4: consume and retain the first beat, and latch its rotation.
          rotation = count_strobe(strb);
          retained = pdata;
          line_active = 1'b1;
          silent_run = 1'b0;
        end else if (line_active) begin
          make_output = lst || (strb != 4'b0);

          if (make_output) begin
            new_data0 = joined_data(pdata, retained, rotation);
            new_data1 = new_data0;

            // After one or more silent beats, L4 permits joining against
            // either the newest silent beat or the beat retained before the
            // silent run.  The output count remains exact in either case.
            if (silent_run)
              new_data1 = joined_data(pdata, retained_before_silent, rotation);

            new_entry.data0   = new_data0;
            new_entry.data1   = new_data1;
            new_entry.alt_ok  = silent_run;
            new_entry.realign = 1'b1;
            expected_q.push_back(new_entry);

            retained = pdata;
            silent_run = 1'b0;
          end else begin
            if (!silent_run)
              retained_before_silent = retained;
            silent_run = 1'b1;
            retained = pdata;
          end

          if (lst)
            line_active = 1'b0;
        end
      end

      if (out_hs) begin
        if (expected_q.size() == 0) begin
          fail("R1/R2/P1",
               "an output beat handshook when no output beat was owed");
        end else begin
          observed_entry = expected_q[0];
          void'(expected_q.pop_front());

          if ((qdata !== observed_entry.data0) &&
              (!observed_entry.alt_ok || (qdata !== observed_entry.data1))) begin
            if (observed_entry.realign)
              fail("R2/R4/R5",
                   $sformatf("bad realigned data: got %08x, expected %08x%s%08x",
                             qdata, observed_entry.data0,
                             observed_entry.alt_ok ? " or " : "",
                             observed_entry.alt_ok ? observed_entry.data1 : 32'b0));
            else
              fail("P1", $sformatf("bad transparent data: got %08x, expected %08x",
                                   qdata, observed_entry.data0));
          end

          if (observed_entry.realign && (qstrb !== 4'hF))
            fail("R3", $sformatf("realigned output strobe was %x, not F", qstrb));
        end
      end
    end
  end

  // Wait for all offered beats, then allow ample time for any registered output.
  task automatic drain_and_check;
    int t;
    bit became_idle;
    begin
      became_idle = 1'b0;
      for (t = 0; t < 120; t++) begin
        @(posedge clk);
        if ((bfm_q.size() == 0) && !pvalid) begin
          became_idle = 1'b1;
          break;
        end
      end

      if (!became_idle)
        fail("X3/H1", "input stream did not become idle; a beat was never accepted");

      repeat (24) @(posedge clk);

      if (expected_q.size() != 0) begin
        if (expected_q[0].realign)
          fail("R2/R6", "one or more required realigned output beats were not produced");
        else
          fail("P1", "one or more transparent output beats were not produced");
      end
    end
  endtask

  task automatic send_full_line(input int r);
    logic [3:0] first_strobe;
    logic [31:0] a;
    logic [31:0] b;
    logic [31:0] c;
    logic [31:0] d;
    begin
      case (r)
        0: first_strobe = 4'b0000;
        1: first_strobe = 4'b0001;
        2: first_strobe = 4'b0011;
        3: first_strobe = 4'b0111;
        default: first_strobe = 4'b1111;
      endcase

      a = 32'h10203040 + r;
      b = 32'h51627384 + r;
      c = 32'h95A6B7C8 + r;
      d = 32'hD9EAFB0C + r;

      bfm_send(a, 1'b1, 1'b0, 1'b1, first_strobe, 4'h3);
      // Deliberately vary strb_i after the first beat: R4 requires the line's
      // original rotation to remain in force.
      bfm_send(b, 1'b0, 1'b0, 1'b1, 4'b0001, 4'h0);
      bfm_send(c, 1'b0, 1'b0, 1'b1, 4'b0110, 4'h5);
      // A clear strobe on the last beat still owes an output (R6).
      bfm_send(d, 1'b0, 1'b1, 1'b1, 4'b0000, 4'hA);
      drain_and_check();
    end
  endtask

  // ---------------------------------------------------------------------------
  // Directed stimulus
  // ---------------------------------------------------------------------------
  initial begin
    automatic int r;

    bfm_reset();
    if (qvalid !== 1'b0)
      fail("X1", "an output remained valid after reset with quiet inputs");

    // Transparent data and handshake, including a partial push strobe.  The
    // output strobe is intentionally never compared in this mode.
    bfm_send(32'h01234567, 1'b0, 1'b0, 1'b0, 4'hF, 4'h3);
    bfm_send(32'h89ABCDEF, 1'b0, 1'b1, 1'b0, 4'h0, 4'hA);
    drain_and_check();

    // Exercise transparent backpressure.  In particular, push_ready_o must be
    // low and pop_valid_o/data must still reflect the offered input.
    @(negedge clk);
    bfm_ready(1'b0);
    bfm_send(32'hDEADBEEF, 1'b0, 1'b0, 1'b0, 4'hF, 4'h1);
    repeat (4) @(posedge clk);
    if (!pvalid)
      fail("H2", "test source failed to present its backpressured beat");
    @(negedge clk);
    bfm_ready(1'b1);
    drain_and_check();

    // Every rotation, including the non-modulo R=4 case and the R=0 case.
    for (r = 0; r <= 4; r++)
      send_full_line(r);

    // Silent beats must be consumed without output.  Two consecutive silent
    // beats exercise both L4 retention choices without preferring either.
    bfm_send(32'h00112233, 1'b1, 1'b0, 1'b1, 4'b0011, 4'hF); // R=2
    bfm_send(32'h44556677, 1'b0, 1'b0, 1'b1, 4'b1111, 4'h0); // output
    bfm_send(32'h8899AABB, 1'b0, 1'b0, 1'b1, 4'b0000, 4'hF); // silent
    bfm_send(32'hCCDDEEFF, 1'b0, 1'b0, 1'b1, 4'b0000, 4'hF); // silent
    bfm_send(32'h13579BDF, 1'b0, 1'b1, 1'b1, 4'b0000, 4'h2); // R6 output
    drain_and_check();

    // L1: a first beat is offered while the sink is not ready.  The design may
    // accept it immediately or wait; neither choice is checked.  In either
    // case it must produce no output and must retain it for the next beat.
    @(negedge clk);
    bfm_ready(1'b0);
    bfm_send(32'hA0B0C0D0, 1'b1, 1'b0, 1'b1, 4'b0111, 4'h6); // R=3
    repeat (3) @(posedge clk);
    bfm_send(32'h11223344, 1'b0, 1'b1, 1'b1, 4'b0000, 4'h9);
    @(negedge clk);
    bfm_ready(1'b1);
    drain_and_check();

    // clear_i must discard line state.  A fresh line afterwards must work from
    // its own first-beat rotation and retained data.
    bfm_send(32'hCAFEBABE, 1'b1, 1'b0, 1'b1, 4'b0001, 4'hF);
    drain_and_check();
    bfm_clear();
    if (qvalid !== 1'b0)
      fail("X2", "clear_i left an output/line transaction pending");
    send_full_line(4);

    // Reset in the middle of a line, then verify a clean restart.
    bfm_send(32'h0BADF00D, 1'b1, 1'b0, 1'b1, 4'b1111, 4'hF);
    drain_and_check();
    bfm_reset();
    if (qvalid !== 1'b0)
      fail("X1", "reset did not return the unit to its starting condition");
    send_full_line(1);

    // Return to transparent mode after realignment to ensure no retained byte
    // or registered valid contaminates the combinational path.
    bfm_send(32'h55AA33CC, 1'b0, 1'b0, 1'b0, 4'hF, 4'h4);
    bfm_send(32'hF00D1234, 1'b0, 1'b1, 1'b0, 4'hF, 4'h7);
    drain_and_check();

    $display("All stream_realign checks completed.");
    $display("RESULT: PASS");
    $finish;
  end

endmodule
