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
  // CHECKER
  // ---------------------------------------------------------------------------
  bit fail = 0;
  bit check_exp = 1;
  logic [31:0] exp_q_data [$];
  logic [3:0]  exp_q_strb [$];
  logic [31:0] obs_q_data [$];
  logic [3:0]  obs_q_strb [$];
  int out_count = 0;

  task automatic clear_state();
    exp_q_data.delete();
    exp_q_strb.delete();
    obs_q_data.delete();
    obs_q_strb.delete();
    out_count = 0;
    check_exp = 1;
  endtask

  task automatic check_idle();
    bfm_idle();
    if (bfm_q.size() > 0) begin
      $display("FAIL: X3 timeout, %0d beats not accepted", bfm_q.size());
      fail = 1;
    end
  endtask

  always @(posedge clk) begin
    if (rst_n) begin
      if (!ra) begin
        // Transparent mode (P1, L3)
        if (qvalid !== pvalid) begin
          $display("FAIL: P1 pop_valid_o (%b) != push_valid_i (%b) in transparent mode", qvalid, pvalid);
          fail = 1;
        end
        if (pvalid && pready !== qready) begin
          $display("FAIL: P1 push_ready_o (%b) != pop_ready_i (%b) in transparent mode", pready, qready);
          fail = 1;
        end
        if (qvalid && qdata !== pdata) begin
          $display("FAIL: P1 pop_data_o (%h) != push_data_i (%h) in transparent mode", qdata, pdata);
          fail = 1;
        end
        if (qvalid) begin
          if (qstrb !== pstrb && qstrb !== 4'hF) begin
            $display("FAIL: L3 pop_strb_o (%h) not pstrb (%h) or 4'hF in transparent mode", qstrb, pstrb);
            fail = 1;
          end
        end
      end else begin
        // Realign mode (R3, R2/R5)
        if (qvalid && qstrb !== 4'hF) begin
          $display("FAIL: R3 pop_strb_o (%h) != 4'hF in realign mode", qstrb);
          fail = 1;
        end
        if (qvalid) begin
          if (check_exp) begin
            if (exp_q_data.size() == 0) begin
              $display("FAIL: Unexpected output beat: data=%h strb=%h", qdata, qstrb);
              fail = 1;
            end else begin
              if (qdata !== exp_q_data[0]) begin
                $display("FAIL: R2/R5 pop_data_o mismatch: got %h, expected %h", qdata, exp_q_data[0]);
                fail = 1;
              end
              if (qstrb !== exp_q_strb[0]) begin
                $display("FAIL: R3 pop_strb_o mismatch: got %h, expected %h", qstrb, exp_q_strb[0]);
                fail = 1;
              end
            end
          end
        end
        if (qvalid && qready) begin
          out_count++;
          obs_q_data.push_back(qdata);
          obs_q_strb.push_back(qstrb);
          if (check_exp && exp_q_data.size() > 0) begin
            void'(exp_q_data.pop_front());
            void'(exp_q_strb.pop_front());
          end
        end
      end
    end
  end

  // ---------------------------------------------------------------------------
  // STIMULUS
  // ---------------------------------------------------------------------------
  initial begin
    bfm_reset();
    clear_state();

    // Test 1: Transparent pass-through
    $display("Test 1: Transparent pass-through");
    ra = 0;
    bfm_send(32'h11223344, 0, 0, 0, 4'hF, 4'hA);
    bfm_send(32'h55667788, 0, 0, 0, 4'hF, 4'h5);
    bfm_send(32'h99AABBCC, 0, 0, 0, 4'hF, 4'h0);
    check_idle();
    if (fail) $display("Test 1 FAILED"); else $display("Test 1 PASSED");
    if (fail) begin $display("RESULT: FAIL"); $finish; end

    // Test 2: Realign R=0
    $display("Test 2: Realign R=0");
    bfm_reset();
    clear_state();
    ra = 1;
    bfm_send(32'h11223344, 1, 0, 1, 4'hF);
    bfm_send(32'h55667788, 0, 0, 1, 4'hF);
    bfm_send(32'h99AABBCC, 0, 1, 1, 4'hF);
    exp_q_data.push_back(32'h55667788);
    exp_q_strb.push_back(4'hF);
    exp_q_data.push_back(32'h99AABBCC);
    exp_q_strb.push_back(4'hF);
    check_idle();
    if (exp_q_data.size() > 0) begin
      $display("FAIL: Test 2 missing outputs, %0d expected left", exp_q_data.size());
      fail = 1;
    end
    if (fail) $display("Test 2 FAILED"); else $display("Test 2 PASSED");
    if (fail) begin $display("RESULT: FAIL"); $finish; end

    // Test 3: Realign R=1
    $display("Test 3: Realign R=1");
    bfm_reset();
    clear_state();
    ra = 1;
    bfm_send(32'h11223344, 1, 0, 1, 4'h1);
    bfm_send(32'h55667788, 0, 0, 1, 4'hF);
    bfm_send(32'h99AABBCC, 0, 1, 1, 4'hF);
    exp_q_data.push_back(32'h66778811);
    exp_q_strb.push_back(4'hF);
    exp_q_data.push_back(32'hAABBCC55);
    exp_q_strb.push_back(4'hF);
    check_idle();
    if (exp_q_data.size() > 0) begin
      $display("FAIL: Test 3 missing outputs, %0d expected left", exp_q_data.size());
      fail = 1;
    end
    if (fail) $display("Test 3 FAILED"); else $display("Test 3 PASSED");
    if (fail) begin $display("RESULT: FAIL"); $finish; end

    // Test 4: Realign R=4
    $display("Test 4: Realign R=4");
    bfm_reset();
    clear_state();
    ra = 1;
    bfm_send(32'h11223344, 1, 0, 1, 4'h0);
    bfm_send(32'h55667788, 0, 0, 1, 4'hF);
    bfm_send(32'h99AABBCC, 0, 1, 1, 4'hF);
    exp_q_data.push_back(32'h11223344);
    exp_q_strb.push_back(4'hF);
    exp_q_data.push_back(32'h55667788);
    exp_q_strb.push_back(4'hF);
    check_idle();
    if (exp_q_data.size() > 0) begin
      $display("FAIL: Test 4 missing outputs, %0d expected left", exp_q_data.size());
      fail = 1;
    end
    if (fail) $display("Test 4 FAILED"); else $display("Test 4 PASSED");
    if (fail) begin $display("RESULT: FAIL"); $finish; end

    // Test 5: R6 - last beat with strb=0
    $display("Test 5: R6 last beat strb=0");
    bfm_reset();
    clear_state();
    ra = 1;
    bfm_send(32'h11223344, 1, 0, 1, 4'h1);
    bfm_send(32'h55667788, 0, 1, 1, 4'h0);
    exp_q_data.push_back(32'h66778811);
    exp_q_strb.push_back(4'hF);
    check_idle();
    if (exp_q_data.size() > 0) begin
      $display("FAIL: Test 5 missing outputs, %0d expected left", exp_q_data.size());
      fail = 1;
    end
    if (fail) $display("Test 5 FAILED"); else $display("Test 5 PASSED");
    if (fail) begin $display("RESULT: FAIL"); $finish; end

    // Test 6: Silent consume produces no output
    $display("Test 6: Silent consume");
    bfm_reset();
    clear_state();
    ra = 1;
    check_exp = 0;
    bfm_send(32'h11223344, 1, 0, 1, 4'h1);
    bfm_send(32'h55667788, 0, 0, 1, 4'h0);
    bfm_send(32'h99AABBCC, 0, 1, 1, 4'hF);
    check_idle();
    if (out_count != 1) begin
      $display("FAIL: R2 silent consume produced %0d outputs, expected 1", out_count);
      fail = 1;
    end else begin
      if (obs_q_data.size() > 0) begin
        logic [31:0] d = obs_q_data[0];
        if (d !== 32'hAABBCC55 && d !== 32'hAABBCC11) begin
          $display("FAIL: R2/L4 silent consume output data %h not one of {AABBCC55, AABBCC11}", d);
          fail = 1;
        end
      end
    end
    check_exp = 1;
    if (fail) $display("Test 6 FAILED"); else $display("Test 6 PASSED");
    if (fail) begin $display("RESULT: FAIL"); $finish; end

    // Test 7: R4 - rotation fixed
    $display("Test 7: R4 rotation fixed");
    bfm_reset();
    clear_state();
    ra = 1;
    bfm_send(32'h11223344, 1, 0, 1, 4'h1);
    bfm_send(32'h55667788, 0, 0, 1, 4'h3);
    bfm_send(32'h99AABBCC, 0, 1, 1, 4'h5);
    exp_q_data.push_back(32'h66778811);
    exp_q_strb.push_back(4'hF);
    exp_q_data.push_back(32'hAABBCC55);
    exp_q_strb.push_back(4'hF);
    check_idle();
    if (exp_q_data.size() > 0) begin
      $display("FAIL: Test 7 missing outputs, %0d expected left", exp_q_data.size());
      fail = 1;
    end
    if (fail) $display("Test 7 FAILED"); else $display("Test 7 PASSED");
    if (fail) begin $display("RESULT: FAIL"); $finish; end

    // Test 8: Clear
    $display("Test 8: Clear");
    bfm_reset();
    clear_state();
    ra = 1;
    bfm_send(32'h11223344, 1, 0, 1, 4'h1);
    bfm_send(32'h55667788, 0, 0, 1, 4'hF);
    exp_q_data.push_back(32'h66778811);
    exp_q_strb.push_back(4'hF);
    check_idle();
    if (exp_q_data.size() > 0) begin
      $display("FAIL: Test 8 missing outputs before clear, %0d expected left", exp_q_data.size());
      fail = 1;
    end
    bfm_clear();
    bfm_send(32'hAABBCCDD, 1, 0, 1, 4'h2);
    bfm_send(32'hEEFF0011, 0, 1, 1, 4'hF);
    exp_q_data.push_back(32'h0011AABB);
    exp_q_strb.push_back(4'hF);
    check_idle();
    if (exp_q_data.size() > 0) begin
      $display("FAIL: Test 8 missing outputs after clear, %0d expected left", exp_q_data.size());
      fail = 1;
    end
    if (fail) $display("Test 8 FAILED"); else $display("Test 8 PASSED");
    if (fail) begin $display("RESULT: FAIL"); $finish; end

    // Test 9: Async reset
    $display("Test 9: Async reset");
    bfm_reset();
    clear_state();
    ra = 1;
    bfm_ready(0);
    bfm_send(32'h11223344, 1, 0, 1, 4'h1);
    bfm_send(32'h55667788, 0, 0, 1, 4'hF);
    for (int i = 0; i < 100; i++) begin
      @(posedge clk);
      if (qvalid && bfm_q.size() == 0) break;
    end
    if (!qvalid) begin
      $display("FAIL: Test 9 timeout waiting for qvalid");
      fail = 1;
    end else if (qdata !== 32'h66778811) begin
      $display("FAIL: Test 9 pending output data %h != 66778811", qdata);
      fail = 1;
    end
    @(negedge clk);
    rst_n = 1'b0;
    repeat (3) @(posedge clk);
    @(negedge clk);
    if (qvalid) begin
      $display("FAIL: X1 qvalid still high during reset");
      fail = 1;
    end
    rst_n = 1'b1;
    repeat (2) @(posedge clk);
    bfm_ready(1);
    bfm_send(32'hAABBCCDD, 1, 0, 1, 4'h2);
    bfm_send(32'hEEFF0011, 0, 1, 1, 4'hF);
    exp_q_data.push_back(32'h0011AABB);
    exp_q_strb.push_back(4'hF);
    check_idle();
    if (exp_q_data.size() > 0) begin
      $display("FAIL: Test 9 missing outputs, %0d expected left", exp_q_data.size());
      fail = 1;
    end
    if (fail) $display("Test 9 FAILED"); else $display("Test 9 PASSED");
    if (fail) begin $display("RESULT: FAIL"); $finish; end

    // Test 10: L1 - first beat with qready=0
    $display("Test 10: L1 first beat qready=0");
    bfm_reset();
    clear_state();
    ra = 1;
    bfm_ready(0);
    bfm_send(32'h11223344, 1, 0, 1, 4'h1);
    bfm_send(32'h55667788, 0, 1, 1, 4'hF);
    repeat (5) @(posedge clk);
    bfm_ready(1);
    exp_q_data.push_back(32'h66778811);
    exp_q_strb.push_back(4'hF);
    check_idle();
    if (exp_q_data.size() > 0) begin
      $display("FAIL: Test 10 missing outputs, %0d expected left", exp_q_data.size());
      fail = 1;
    end
    if (fail) $display("Test 10 FAILED"); else $display("Test 10 PASSED");
    if (fail) begin $display("RESULT: FAIL"); $finish; end

    // Test 11: Backpressure
    $display("Test 11: Backpressure");
    bfm_reset();
    clear_state();
    ra = 1;
    bfm_ready(0);
    bfm_send(32'h11223344, 1, 0, 1, 4'h1);
    bfm_send(32'h55667788, 0, 0, 1, 4'hF);
    bfm_send(32'h99AABBCC, 0, 1, 1, 4'hF);
    for (int i = 0; i < 100; i++) begin
      @(posedge clk);
      if (qvalid) break;
    end
    if (!qvalid) begin
      $display("FAIL: Test 11 timeout waiting for qvalid");
      fail = 1;
    end else if (qdata !== 32'h66778811) begin
      $display("FAIL: Test 11 pending output data %h != 66778811", qdata);
      fail = 1;
    end
    bfm_ready(1);
    exp_q_data.push_back(32'h66778811);
    exp_q_strb.push_back(4'hF);
    exp_q_data.push_back(32'hAABBCC55);
    exp_q_strb.push_back(4'hF);
    check_idle();
    if (exp_q_data.size() > 0) begin
      $display("FAIL: Test 11 missing outputs, %0d expected left", exp_q_data.size());
      fail = 1;
    end
    if (fail) $display("Test 11 FAILED"); else $display("Test 11 PASSED");
    if (fail) begin $display("RESULT: FAIL"); $finish; end

    // All tests passed
    $display("RESULT: PASS");
    $finish;
  end
endmodule
