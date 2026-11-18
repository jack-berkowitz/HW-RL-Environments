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
  initial begin
    #2_000_000;
    $display("RESULT: FAIL (watchdog: no verdict reached)");
    $finish;
  end

  // ---------------------------------------------------------------------------
  // CHECKING AND STIMULUS
  // ---------------------------------------------------------------------------

  typedef struct packed {
    logic [31:0] data0;
    logic [31:0] data1;
    logic        has_alt;
  } exp_t;

  exp_t exp_q [$];

  function automatic logic [3:0] strb_for_R(input int R);
    begin
      case (R)
        0: strb_for_R = 4'h0;
        1: strb_for_R = 4'h1;
        2: strb_for_R = 4'h3;
        3: strb_for_R = 4'h7;
        4: strb_for_R = 4'hF;
        default: strb_for_R = 4'hF;
      endcase
    end
  endfunction

  function automatic logic [31:0] rot_out(input logic [31:0] cur,
                                          input logic [31:0] ret,
                                          input int R);
    logic [31:0] a;
    logic [31:0] b;
    begin
      if (R <= 0)       a = cur;
      else if (R >= 4)  a = 32'h0;
      else              a = cur << (8 * R);

      if (R >= 4)       b = ret;
      else if (R <= 0)  b = 32'h0;
      else              b = ret >> (8 * (4 - R));

      rot_out = a | b;
    end
  endfunction

  task automatic fail(input string clause, input string msg);
    begin
      $display("RESULT: FAIL (%s: %s)", clause, msg);
      $finish;
    end
  endtask

  task automatic add_exp(input logic [31:0] d0,
                         input logic [31:0] d1,
                         input bit alt);
    exp_t e;
    begin
      e.data0   = d0;
      e.data1   = d1;
      e.has_alt = alt;
      exp_q.push_back(e);
    end
  endtask

  task automatic set_ready(input bit v);
    begin
      @(negedge clk);
      qready = v;
    end
  endtask

  task automatic wait_input_accepted(input int max_cycles, input string ctx);
    bit ok;
    int t;
    begin
      ok = 1'b0;
      for (t = 0; t < max_cycles; t = t + 1) begin
        @(posedge clk);
        if (bfm_q.size() == 0 && !pvalid) begin
          ok = 1'b1;
          break;
        end
      end
      if (!ok) fail("X3", {ctx, ": beat not accepted within bound"});
    end
  endtask

  task automatic drain(input int max_cycles, input string ctx);
    bit done;
    int t;
    begin
      done = 1'b0;
      for (t = 0; t < max_cycles; t = t + 1) begin
        @(posedge clk);
        if (bfm_q.size() == 0 && !pvalid && exp_q.size() == 0) begin
          done = 1'b1;
          break;
        end
      end

      if (!done) begin
        if (bfm_q.size() != 0 || pvalid)
          fail("X3", {ctx, ": input not accepted"});
        else
          fail("R2/R5", {ctx, ": missing output beat(s)"});
      end

      repeat (16) @(posedge clk);

      if (exp_q.size() != 0)
        fail("R2/R5", {ctx, ": missing output beat(s) after drain"});
    end
  endtask

  task automatic run_simple_line(input int R,
                                 input int nbeats,
                                 input logic [31:0] base,
                                 input bit last_clear);
    int i;
    logic [31:0] cur;
    logic [31:0] ret;
    logic [31:0] out;
    logic [3:0]  s;
    begin
      ret = base;
      bfm_send(base, 1'b1, 1'b0, 1'b1, strb_for_R(R), 4'h5);

      for (i = 1; i < nbeats; i = i + 1) begin
        cur = base ^ (32'h11111111 * i);

        if (i == nbeats - 1 && last_clear)
          s = 4'h0;
        else
          s = 4'hF;

        out = rot_out(cur, ret, R);
        add_exp(out, out, 1'b0);

        bfm_send(cur, 1'b0, (i == nbeats - 1), 1'b1, s, 4'h5);
        ret = cur;
      end
    end
  endtask

  task automatic run_silent_test(input int R, input logic [31:0] base);
    logic [31:0] first_d;
    logic [31:0] silent_d;
    logic [31:0] last_d;
    logic [31:0] out_a;
    logic [31:0] out_b;
    begin
      first_d  = base;
      silent_d = base ^ 32'h22222222;
      last_d   = base ^ 32'h33333333;

      bfm_send(first_d, 1'b1, 1'b0, 1'b1, strb_for_R(R), 4'h5);
      bfm_send(silent_d, 1'b0, 1'b0, 1'b1, 4'h0, 4'h5);

      out_a = rot_out(last_d, silent_d, R);
      out_b = rot_out(last_d, first_d,  R);
      add_exp(out_a, out_b, 1'b1);

      bfm_send(last_d, 1'b0, 1'b1, 1'b1, 4'h0, 4'h5);
    end
  endtask

  task automatic test_liveness();
    logic [31:0] d;
    begin
      set_ready(1'b1);
      d = 32'h70000000;
      add_exp(d, d, 1'b0);
      bfm_send(d, 1'b0, 1'b0, 1'b0, 4'hF, 4'hF);
      wait_input_accepted(16, "X3 liveness");
      drain(100, "X3 liveness drain");
    end
  endtask

  task automatic test_pass_through();
    int i;
    logic [31:0] d;
    begin
      set_ready(1'b1);

      for (i = 0; i < 4; i = i + 1) begin
        d = 32'h10000000 + (i * 32'h11111111);
        add_exp(d, d, 1'b0);
        bfm_send(d, (i == 0), (i == 3), 1'b0, 4'h5, 4'h5);
      end
      drain(200, "P1 pass-through data");

      set_ready(1'b0);
      for (i = 0; i < 2; i = i + 1) begin
        d = 32'h20000000 + (i * 32'h01010101);
        add_exp(d, d, 1'b0);
        bfm_send(d, 1'b0, 1'b0, 1'b0, 4'hA, 4'h3);
      end

      repeat (3) @(posedge clk);

      set_ready(1'b1);
      drain(200, "P1 pass-through backpressure");
    end
  endtask

  task automatic test_realign_rotations();
    int r;
    begin
      set_ready(1'b1);
      for (r = 0; r <= 4; r = r + 1) begin
        run_simple_line(r, 5, 32'h30000000 + (r * 32'h01010101), 1'b0);
        drain(400, $sformatf("R5/R2 rotation R=%0d", r));
      end
    end
  endtask

  task automatic test_silent();
    begin
      set_ready(1'b1);

      run_silent_test(2, 32'h40000000);
      drain(400, "R2/L4/R6 silent R=2");

      run_silent_test(4, 32'h50000000);
      drain(400, "R2/L4/R6 silent R=4");
    end
  endtask

  task automatic test_realign_backpressure();
    logic [31:0] first_d;
    logic [31:0] cur;
    logic [31:0] out;
    begin
      set_ready(1'b0);

      first_d = 32'h60000000;
      cur     = 32'h61000000;

      bfm_send(first_d, 1'b1, 1'b0, 1'b1, 4'h3, 4'h5);
      repeat (3) @(posedge clk);

      out = rot_out(cur, first_d, 2);
      add_exp(out, out, 1'b0);
      bfm_send(cur, 1'b0, 1'b1, 1'b1, 4'hF, 4'h5);

      set_ready(1'b1);
      drain(400, "L1 realign backpressure");
    end
  endtask

  task automatic test_clear();
    logic [31:0] old_first;
    logic [31:0] new_first;
    logic [31:0] cur;
    logic [31:0] out;
    begin
      set_ready(1'b1);

      old_first = 32'hA1B2C3D4;
      new_first = 32'h55667788;
      cur       = 32'h11223344;

      bfm_send(old_first, 1'b1, 1'b0, 1'b1, 4'hF, 4'h5);
      drain(100, "clear setup");

      bfm_clear();

      bfm_send(new_first, 1'b1, 1'b0, 1'b1, 4'hF, 4'h5);
      out = rot_out(cur, new_first, 4);
      add_exp(out, out, 1'b0);
      bfm_send(cur, 1'b0, 1'b1, 1'b1, 4'hF, 4'h5);

      drain(200, "X2 clear retained");
    end
  endtask

  task automatic test_reset();
    logic [31:0] old_first;
    logic [31:0] new_first;
    logic [31:0] cur;
    logic [31:0] out;
    begin
      set_ready(1'b1);

      old_first = 32'hDEADBEEF;
      new_first = 32'hCAFEBABE;
      cur       = 32'h01234567;

      bfm_send(old_first, 1'b1, 1'b0, 1'b1, 4'hF, 4'h5);
      drain(100, "reset setup");

      bfm_reset(3);

      bfm_send(new_first, 1'b1, 1'b0, 1'b1, 4'hF, 4'h5);
      out = rot_out(cur, new_first, 4);
      add_exp(out, out, 1'b0);
      bfm_send(cur, 1'b0, 1'b1, 1'b1, 4'hF, 4'h5);

      drain(200, "X1 reset retained");
    end
  endtask

  // ---- output checker --------------------------------------------------------
  always @(posedge clk) begin
    automatic exp_t e;
    if (rst_n) begin
      if (qvalid && qready) begin
        if (exp_q.size() == 0) begin
          fail("R2/R5", "unexpected output beat");
        end else begin
          e = exp_q.pop_front();

          if (!(qdata === e.data0) &&
              !(e.has_alt && (qdata === e.data1))) begin
            fail("R2/R5", "output data mismatch");
          end

          if (ra && (qstrb !== 4'hF)) begin
            fail("R3", "pop_strb_o not all ones while realigning");
          end
        end
      end
    end
  end

  // ---- transparent-mode handshake/data checker ------------------------------
  always @(posedge clk) begin
    if (rst_n && !clr && !ra) begin
      if (qvalid !== pvalid) begin
        fail("P1", "pop_valid_o does not follow push_valid_i");
      end

      if (pvalid) begin
        if (pready !== qready) begin
          fail("P1", "push_ready_o does not follow pop_ready_i while offering");
        end
        if (qdata !== pdata) begin
          fail("P1", "pop_data_o does not equal push_data_i");
        end
      end
    end
  end

  // ---- test sequence ---------------------------------------------------------
  initial begin
    bfm_reset(5);

    test_liveness();
    test_pass_through();
    test_realign_rotations();
    test_silent();
    test_realign_backpressure();
    test_clear();
    test_reset();

    drain(400, "final");

    if (exp_q.size() != 0)
      fail("final", "expected outputs remain");

    $display("RESULT: PASS");
    $finish;
  end

endmodule
