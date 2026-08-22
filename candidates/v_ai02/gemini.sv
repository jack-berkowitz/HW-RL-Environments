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
    automatic bfm_beat_t b;
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
// TESTBENCH CHECKERS & STIMULUS
// ---------------------------------------------------------------------------

  task automatic fail(string msg);
    $display("RESULT: FAIL (%s)", msg);
    $finish;
  endtask

  task automatic pass();
    $display("RESULT: PASS");
    $finish;
  endtask

  // ---- X1: Asynchronous Reset Check ----
  always @(negedge clk) begin
    if (!rst_n && qvalid) fail("X1: pop_valid_o asserted while rst_ni is low");
  end

  // ---- X3: Liveness Check ----
  int x3_counter = 0;
  always @(posedge clk) begin
    if (!rst_n || clr) begin
      x3_counter <= 0;
    end else if (pvalid && !pready && qready) begin
      x3_counter <= x3_counter + 1;
      if (x3_counter >= 16) fail("X3: Liveness bound of 16 cycles exceeded");
    end else begin
      x3_counter <= 0;
    end
  end

  // ---- P1: Pass-through Checker ----
  always @(posedge clk) begin
    if (rst_n && !clr && !ra) begin
      if (qvalid !== pvalid) fail("P1: pop_valid_o must strictly follow push_valid_i when transparent");
      if (pvalid) begin
        if (pready !== qready) fail("P1: push_ready_o must follow pop_ready_i when offering a beat");
        if (qvalid && qready) begin
          if (qdata !== pdata) fail("P1: pop_data_o does not match push_data_i in transparent mode");
          if (qstrb !== pstrb) fail("P1: pop_strb_o does not match push_strb_i in transparent mode");
        end
      end
    end
  end

  // ---- R1-R6: Realignment Golden Model & Checking ----
  typedef struct packed {
    logic [31:0] data;
    logic [3:0]  strb;
  } exp_beat_t;
  
  exp_beat_t exp_q [$];

  int R_val = 0;
  logic [31:0] retained_data = '0;
  bit in_line = 0;

  function automatic int count_ones(logic [3:0] s);
    automatic int c = 0;
    for (int i=0; i<4; i++) if (s[i]) c++;
    return c;
  endfunction

  // Input Tracker: Push expected outputs to the queue on successful push handshake
  always @(posedge clk) begin
    if (!rst_n) begin
      exp_q.delete();
      in_line = 0;
    end else if (clr) begin
      exp_q.delete();
      in_line = 0;
    end else if (pvalid && pready && ra) begin
      if (fst) begin
        R_val = count_ones(strb);
        retained_data = pdata;
        in_line = 1;
      end else if (in_line) begin
        if (lst || (strb != 0)) begin
          automatic exp_beat_t e;
          if (R_val == 0) e.data = pdata;
          else if (R_val == 4) e.data = retained_data;
          else e.data = (pdata << (8*R_val)) | (retained_data >> (8*(4-R_val)));
          
          e.strb = 4'hF; // R3 mandates all ones
          exp_q.push_back(e);
        end
        retained_data = pdata;
        if (lst) in_line = 0;
      end
    end
  end

  // Output Checker: Match design outputs against the expected queue on successful pop handshake
  always @(posedge clk) begin
    if (rst_n && !clr && qvalid && qready && ra) begin
      if (exp_q.size() == 0) begin
        fail("R2: Unexpected output beat produced (none expected)");
      end else begin
        automatic exp_beat_t e = exp_q.pop_front();
        if (qdata !== e.data) fail("R2: Realigned pop_data_o mismatch");
        if (qstrb !== e.strb) fail("R3: pop_strb_o is not all ones during realignment");
      end
    end
  end

  // ---- Test Sequence ---------------------------------------------------------
  initial begin
    bfm_reset();

    // 1. P1: Pass-through Test
    bfm_ready(1);
    bfm_send(.data(32'h11111111), .first(0), .last(0), .do_realign(0), .lstrb(4'hF), .dstrb(4'h5));
    bfm_send(.data(32'h22222222), .first(0), .last(0), .do_realign(0), .lstrb(4'hA), .dstrb(4'hA));
    bfm_idle();

    // 2. P1: Backpressure Test
    bfm_ready(0);
    bfm_send(.data(32'h33333333), .first(0), .last(0), .do_realign(0), .lstrb(4'h0), .dstrb(4'hF));
    #50;
    bfm_ready(1);
    bfm_idle();

    // 3. R=0 Test (0 ones in strb on first beat)
    bfm_send(.data(32'hA0A1A2A3), .first(1), .last(0), .do_realign(1), .lstrb(4'b0000));
    bfm_send(.data(32'hB0B1B2B3), .first(0), .last(1), .do_realign(1), .lstrb(4'b1111));
    bfm_idle();

    // 4. R=1 to 4 Tests
    for (int r = 1; r <= 4; r++) begin
      automatic logic [3:0] s = (1 << r) - 1; 
      bfm_send(.data(32'hC0C1C2C3 + r), .first(1), .last(0), .do_realign(1), .lstrb(s));
      bfm_send(.data(32'hD0D1D2D3 + r), .first(0), .last(0), .do_realign(1), .lstrb(4'hF));
      bfm_send(.data(32'hE0E1E2E3 + r), .first(0), .last(1), .do_realign(1), .lstrb(4'hF));
    end
    bfm_idle();

    // 5. R6: last_i high with strb_i completely clear
    bfm_send(.data(32'hF0F1F2F3), .first(1), .last(0), .do_realign(1), .lstrb(4'b0011));
    bfm_send(.data(32'h00000000), .first(0), .last(1), .do_realign(1), .lstrb(4'b0000));
    bfm_idle();

    // 6. X2: Clear behavior mid-line
    bfm_send(.data(32'h12345678), .first(1), .last(0), .do_realign(1), .lstrb(4'b1111));
    #50;
    bfm_clear();
    bfm_send(.data(32'hAABBCCDD), .first(1), .last(0), .do_realign(1), .lstrb(4'b0011));
    bfm_send(.data(32'h11223344), .first(0), .last(1), .do_realign(1), .lstrb(4'b1111));
    bfm_idle();

    // 7. X1 & X2: Async reset behavior mid-line
    bfm_send(.data(32'h55555555), .first(1), .last(0), .do_realign(1), .lstrb(4'b0111));
    #50;
    bfm_reset();
    bfm_send(.data(32'h66666666), .first(1), .last(0), .do_realign(1), .lstrb(4'b0111));
    bfm_send(.data(32'h77777777), .first(0), .last(1), .do_realign(1), .lstrb(4'b1111));
    bfm_idle();

    // 8. L1/X3: Latency & Backpressure behavior (first beat accepted without qready, liveness checking)
    bfm_ready(0);
    bfm_send(.data(32'h88888888), .first(1), .last(0), .do_realign(1), .lstrb(4'b0011));
    #100;
    bfm_ready(1);
    bfm_send(.data(32'h99999999), .first(0), .last(1), .do_realign(1), .lstrb(4'b1111));
    bfm_idle();
    
    // Middle beats with clear strobes silently dropped
    bfm_send(.data(32'h01020304), .first(1), .last(0), .do_realign(1), .lstrb(4'b0111));
    bfm_send(.data(32'h05060708), .first(0), .last(0), .do_realign(1), .lstrb(4'b0000));
    bfm_send(.data(32'h090A0B0C), .first(0), .last(1), .do_realign(1), .lstrb(4'b1111));
    bfm_idle();

    // Verification check for missing expected beats
    if (exp_q.size() != 0) fail("R: Missing output beats at end of test");

    pass();
  end

endmodule