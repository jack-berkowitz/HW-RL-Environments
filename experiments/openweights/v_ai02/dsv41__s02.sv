module stream_realign_tb;

  // ---------------------------------------------------------------------------
  // PROVIDED PLUMBING -- moves beats, checks nothing.
  // ---------------------------------------------------------------------------
  logic clk = 1'b0;
  always #5 clk = ~clk;

  int bfm_cycle = 0;
  always @(posedge clk) if (rst_n) bfm_cycle <= bfm_cycle + 1;

  logic rst_n = 1'b0;
  logic clr   = 1'b0;

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
    b.data = data; b.dstrb = dstrb; b.first = first; b.last = last;
    b.realign = do_realign; b.lstrb = lstrb;
    bfm_q.push_back(b);
  endtask

  task automatic bfm_ready(input bit v); qready = v; endtask

  task automatic bfm_idle(input int max_cycles = 400);
    for (int t = 0; t < max_cycles; t++) begin
      @(posedge clk);
      if (bfm_q.size() == 0 && !pvalid) break;
    end
    repeat (6) @(posedge clk);
  endtask

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

  initial begin
    #2_000_000;
    $display("RESULT: FAIL (watchdog: no verdict reached)");
    $finish;
  end

  // ---------------------------------------------------------------------------
  // TESTBENCH CHECKING
  // ---------------------------------------------------------------------------

  typedef struct packed {
    logic [31:0] data;
    logic [3:0]  strb;
    logic        check_data;
    logic        check_strb;
  } exp_t;

  exp_t expected_q [$];
  bit checking_enabled = 0;
  bit check_forbid_old = 0;
  logic [31:0] forbid_old_data;
  bit failed = 0;

  task automatic fail(input string msg);
    if (!failed) begin
      failed = 1;
      $display("ERROR: %s", msg);
    end
  endtask

  task automatic push_expected(input logic [31:0] data, input logic [3:0] strb,
                               input bit check_data, input bit check_strb);
    exp_t e;
    e.data = data;
    e.strb = strb;
    e.check_data = check_data;
    e.check_strb = check_strb;
    expected_q.push_back(e);
  endtask

  function automatic logic [31:0] realign_calc(input logic [31:0] cur,
                                               input logic [31:0] prev,
                                               input int R);
    logic [31:0] a, b;
    if (R == 0) a = cur;
    else a = cur << (8 * R);
    if (R == 4) b = prev;
    else b = prev >> (8 * (4 - R));
    return a | b;
  endfunction

  function automatic logic [3:0] strb_for_R(input int R);
    case (R)
      0: return 4'h0;
      1: return 4'h1;
      2: return 4'h3;
      3: return 4'h7;
      4: return 4'hF;
      default: return 4'h0;
    endcase
  endfunction

  // Expected-output monitor
  always @(posedge clk) begin
    if (rst_n && !clr && checking_enabled) begin
      if (qvalid && qready) begin
        if (expected_q.size() == 0) begin
          fail("unexpected output beat");
        end else begin
          automatic exp_t e;
          e = expected_q.pop_front();
          if (e.check_strb && qstrb !== e.strb)
            fail("R3 pop_strb_o not all ones while realigning");
          if (e.check_data && qdata !== e.data)
            fail("R2/R5 pop_data_o mismatch");
        end
      end
    end
  end

  // R3: output strobe must be all ones whenever realigning and a beat moves
  always @(posedge clk) begin
    if (rst_n && !clr && ra && qvalid && qready) begin
      if (qstrb !== 4'hF)
        fail("R3 pop_strb_o not all ones while realigning");
    end
  end

  // Forbid old retained data after clear/reset
  always @(posedge clk) begin
    if (rst_n && !clr && check_forbid_old) begin
      if (qvalid && qready && qdata === forbid_old_data)
        fail("X1/X2 clear/reset did not clear retained state");
    end
  end

  // Pass-through live monitor
  bit check_passthrough = 0;
  always @(posedge clk) begin
    if (rst_n && !clr && check_passthrough) begin
      if (qvalid !== pvalid)
        fail("P1 pop_valid_o does not follow push_valid_i");
      if (pvalid && pready !== qready)
        fail("P1 push_ready_o does not follow pop_ready_i");
      if (qvalid && qdata !== pdata)
        fail("P1 pop_data_o not transparent");
      if (qvalid && qstrb !== 4'hF && qstrb !== pstrb)
        fail("L3 pop_strb_o not allowed in transparent mode");
    end
  end

  // ---------------------------------------------------------------------------
  // Directed tests
  // ---------------------------------------------------------------------------

  task automatic test_passthrough();
    bfm_clear();
    bfm_ready(0);
    check_passthrough = 1;

    bfm_send(32'hA1B2C3D4, 0, 0, 0, 4'h0, 4'h5);
    wait (pvalid == 1'b1);
    repeat (2) @(posedge clk);

    if (pready !== 1'b0) fail("P1 pready not low when qready low");
    if (qvalid !== 1'b1) fail("P1 qvalid not high when pvalid high");
    if (qdata !== 32'hA1B2C3D4) fail("P1 data mismatch with qready low");
    if (qstrb !== 4'hF && qstrb !== 4'h5) fail("L3 strb not allowed");

    bfm_ready(1);
    bfm_idle(50);

    bfm_send(32'h12345678, 1, 1, 0, 4'hF, 4'hA);
    bfm_idle(50);

    check_passthrough = 0;
  endtask

  task automatic test_first_no_output();
    bfm_clear();
    bfm_ready(1);
    expected_q.delete();
    checking_enabled = 1;

    bfm_send(32'h11111111, 1, 0, 1, 4'h1, 4'h5);
    bfm_idle(50);
    repeat (50) @(posedge clk);

    if (expected_q.size() != 0) fail("R1 expected queue not empty");
    checking_enabled = 0;
  endtask

  task automatic test_realign_line(input int R,
                                   input logic [31:0] b0, b1, b2, b3);
    logic [31:0] prev;
    logic [31:0] exp;

    bfm_clear();
    bfm_ready(1);
    expected_q.delete();
    checking_enabled = 1;

    bfm_send(b0, 1, 0, 1, strb_for_R(R), 4'hA);
    prev = b0;

    exp = realign_calc(b1, prev, R);
    push_expected(exp, 4'hF, 1, 1);
    bfm_send(b1, 0, 0, 1, 4'hF, 4'h5);
    prev = b1;

    exp = realign_calc(b2, prev, R);
    push_expected(exp, 4'hF, 1, 1);
    bfm_send(b2, 0, 0, 1, 4'hF, 4'h3);
    prev = b2;

    exp = realign_calc(b3, prev, R);
    push_expected(exp, 4'hF, 1, 1);
    bfm_send(b3, 0, 1, 1, 4'hF, 4'hC);

    bfm_idle(100);
    repeat (50) @(posedge clk);

    if (expected_q.size() != 0) fail("R5 missing output beats");
    checking_enabled = 0;
  endtask

  task automatic test_last_zero_strb();
    logic [31:0] exp;

    bfm_clear();
    bfm_ready(1);
    expected_q.delete();
    checking_enabled = 1;

    bfm_send(32'hAABBCCDD, 1, 0, 1, 4'h1, 4'h5);
    exp = realign_calc(32'h11223344, 32'hAABBCCDD, 1);
    push_expected(exp, 4'hF, 1, 1);
    bfm_send(32'h11223344, 0, 1, 1, 4'h0, 4'hA);

    bfm_idle(100);
    repeat (50) @(posedge clk);

    if (expected_q.size() != 0)
      fail("R6 missing output for last with zero strb");
    checking_enabled = 0;
  endtask

  task automatic test_silent_count();
    bfm_clear();
    bfm_ready(1);
    expected_q.delete();
    checking_enabled = 1;

    bfm_send(32'h11111111, 1, 0, 1, 4'h1, 4'h5);
    bfm_send(32'h22222222, 0, 0, 1, 4'h0, 4'hA);

    push_expected(32'h0, 4'hF, 0, 1); // data wildcard
    bfm_send(32'h33333333, 0, 1, 1, 4'h0, 4'h3);

    bfm_idle(100);
    repeat (50) @(posedge clk);

    if (expected_q.size() != 0)
      fail("R2 missing output for last after silent beat");
    checking_enabled = 0;
  endtask

  task automatic test_clear();
    logic [31:0] old_data;
    logic [31:0] new_data;
    bit accepted;
    int i;

    old_data = 32'hDEADBEEF;
    new_data = 32'h12345678;

    bfm_clear();
    bfm_ready(1);
    expected_q.delete();
    checking_enabled = 0;

    bfm_send(old_data, 1, 0, 1, 4'hF, 4'h5);
    bfm_idle(50);

    bfm_clear();
    check_forbid_old = 1;
    forbid_old_data = old_data;

    bfm_send(new_data, 0, 1, 1, 4'h0, 4'hA);
    accepted = 0;
    for (i = 0; i < 16; i++) begin
      @(posedge clk);
      if (pvalid && pready) begin accepted = 1; break; end
    end
    if (!accepted) fail("X3 liveness: beat not accepted after clear");

    repeat (50) @(posedge clk);
    check_forbid_old = 0;
  endtask

  task automatic test_reset();
    logic [31:0] old_data;
    logic [31:0] new_data;
    bit accepted;
    int i;

    old_data = 32'hCAFEBABE;
    new_data = 32'h87654321;

    bfm_clear();
    bfm_ready(1);
    expected_q.delete();
    checking_enabled = 0;

    bfm_send(old_data, 1, 0, 1, 4'hF, 4'h5);
    bfm_idle(50);

    bfm_reset(5);
    if (qvalid) fail("X1 qvalid high after reset");

    check_forbid_old = 1;
    forbid_old_data = old_data;

    bfm_send(new_data, 0, 1, 1, 4'h0, 4'hA);
    accepted = 0;
    for (i = 0; i < 16; i++) begin
      @(posedge clk);
      if (pvalid && pready) begin accepted = 1; break; end
    end
    if (!accepted) fail("X3 liveness: beat not accepted after reset");

    repeat (50) @(posedge clk);
    check_forbid_old = 0;
  endtask

  task automatic test_liveness();
    int i;
    bit accepted;

    bfm_clear();
    bfm_ready(1);
    expected_q.delete();
    checking_enabled = 0;

    bfm_send(32'h12345678, 1, 0, 1, 4'h1, 4'h5);
    accepted = 0;
    for (i = 0; i < 16; i++) begin
      @(posedge clk);
      if (pvalid && pready) begin accepted = 1; break; end
    end
    if (!accepted) fail("X3 liveness: beat not accepted within 16 cycles");

    bfm_idle(50);
  endtask

  // ---------------------------------------------------------------------------
  // Main sequence
  // ---------------------------------------------------------------------------
  initial begin
    bfm_reset(5);
    repeat (5) @(posedge clk);
    if (qvalid) fail("X1 qvalid high after initial reset");

    test_passthrough();
    test_first_no_output();

    test_realign_line(0, 32'h00000000, 32'h11111111, 32'h22222222, 32'h33333333);
    test_realign_line(1, 32'h00000001, 32'h11111111, 32'h22222222, 32'h33333333);
    test_realign_line(2, 32'h00000002, 32'h11111111, 32'h22222222, 32'h33333333);
    test_realign_line(3, 32'h00000003, 32'h11111111, 32'h22222222, 32'h33333333);
    test_realign_line(4, 32'h00000004, 32'h11111111, 32'h22222222, 32'h33333333);

    test_last_zero_strb();
    test_silent_count();
    test_clear();
    test_reset();
    test_liveness();

    if (failed) $display("RESULT: FAIL");
    else        $display("RESULT: PASS");
    $finish;
  end

endmodule
