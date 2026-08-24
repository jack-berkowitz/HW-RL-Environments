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
// TESTBENCH LOGIC
// ---------------------------------------------------------------------------

  typedef struct {
    logic [31:0] data;
    bit check_strb;
    bit check_data;
  } expected_beat_t;

  expected_beat_t expected_q [$];

  task automatic send_pass(input logic [31:0] data, input logic [3:0] strb = 4'hF);
    expected_beat_t exp;
    exp.data = data;
    exp.check_strb = 0; // L3: not specified
    exp.check_data = 1;
    expected_q.push_back(exp);
    bfm_send(.data(data), .first(0), .last(0), .do_realign(0), .lstrb(0), .dstrb(strb));
  endtask

  logic [31:0] t_retained = 0;
  int t_R = 0;
  bit t_unknown = 0;

  task automatic send_realign(
    input logic [31:0] data,
    input bit first,
    input bit last,
    input logic [3:0] lstrb
  );
    if (first) begin
      // R1: produces no output beat, consumed and retained
      t_R = 0;
      for (int i = 0; i < 4; i++) if (lstrb[i]) t_R++;
      t_retained = data;
      t_unknown = 0;
    end else begin
      // R2 & R6: an output is produced if last_i is high or strb_i is non-zero
      if (last || lstrb != 0) begin
        expected_beat_t exp;
        
        if (t_R == 0) exp.data = data;
        else if (t_R == 4) exp.data = t_retained;
        else exp.data = (data << (8 * t_R)) | (t_retained >> (8 * (4 - t_R)));
        
        exp.check_strb = 1;         // R3: strb must be all ones
        exp.check_data = !t_unknown;// L4: data unknown if preceded by a silently consumed beat
        expected_q.push_back(exp);
        
        t_retained = data;
        t_unknown = 0;
      end else begin
        // Silently consumed beat
        t_unknown = 1;
      end
    end
    
    bfm_send(.data(data), .first(first), .last(last), .do_realign(1), .lstrb(lstrb), .dstrb(4'hF));
  endtask

  always @(posedge clk) begin
    if (rst_n && !clr) begin
      
      // P1 transparent mode checks
      if (!ra) begin
        if (qvalid !== pvalid) begin
          $display("RESULT: FAIL (P1: pop_valid_o does not follow push_valid_i in pass-through)");
          $finish;
        end
        // H3 allows pready to be undefined when pvalid is 0
        if (pvalid && pready !== qready) begin
          $display("RESULT: FAIL (P1: push_ready_o does not follow pop_ready_i in pass-through)");
          $finish;
        end
        if (pvalid && qvalid && qdata !== pdata) begin
          $display("RESULT: FAIL (P1: pop_data_o does not equal push_data_i in pass-through)");
          $finish;
        end
      end

      // Verify outputs and pops from queue
      if (qvalid && qready) begin
        if (expected_q.size() == 0) begin
          $display("RESULT: FAIL (R1/R2: Extra output beat produced unexpectedly)");
          $finish;
        end
        
        begin
          automatic expected_beat_t exp = expected_q.pop_front();
          if (exp.check_data && qdata !== exp.data) begin
            $display("RESULT: FAIL (R2: Data mismatch on realigned output, expected %08x got %08x)", exp.data, qdata);
            $finish;
          end
          if (exp.check_strb && qstrb !== 4'hF) begin
            $display("RESULT: FAIL (R3: Output strobe is not all ones during realignment)");
            $finish;
          end
        end
      end
    end
    
    // X1 Reset checks
    if (!rst_n && !pvalid) begin
      if (qvalid !== 1'b0) begin
        $display("RESULT: FAIL (X1: qvalid is not 0 during reset)");
        $finish;
      end
    end
  end

  // X3 Liveness check
  int liveness_count = 0;
  always @(posedge clk) begin
    if (rst_n && !clr) begin
      if (pvalid && qready && !pready) begin
        liveness_count++;
        if (liveness_count >= 16) begin
          $display("RESULT: FAIL (X3: Liveness bound exceeded; beat not accepted within 16 cycles)");
          $finish;
        end
      end else begin
        liveness_count = 0;
      end
    end else begin
      liveness_count = 0;
    end
  end

  // Generate stimulus sequences covering all aspects
  initial begin
    bfm_ready(1);
    bfm_reset();

    // 1. Pass-through mode (P1)
    send_pass(32'h01020304, 4'hA);
    send_pass(32'h05060708, 4'h0);
    bfm_idle();

    // 2. Realignment, varying rotational configurations R=0, 1, 2, 3, 4
    send_realign(32'h10111213, 1, 0, 4'h0); // R=0
    send_realign(32'h14151617, 0, 0, 4'hF);
    send_realign(32'h18191A1B, 0, 1, 4'hF);
    bfm_idle();

    send_realign(32'h20212223, 1, 0, 4'h1); // R=1
    send_realign(32'h24252627, 0, 0, 4'hF);
    send_realign(32'h28292A2B, 0, 1, 4'hF);
    bfm_idle();

    send_realign(32'h30313233, 1, 0, 4'h3); // R=2
    send_realign(32'h34353637, 0, 0, 4'hF);
    send_realign(32'h38393A3B, 0, 1, 4'hF);
    bfm_idle();

    send_realign(32'h40414243, 1, 0, 4'h7); // R=3
    send_realign(32'h44454647, 0, 0, 4'hF);
    send_realign(32'h48494A4B, 0, 1, 4'hF);
    bfm_idle();

    send_realign(32'h50515253, 1, 0, 4'hF); // R=4
    send_realign(32'h54555657, 0, 0, 4'hF);
    send_realign(32'h58595A5B, 0, 1, 4'hF);
    bfm_idle();

    // 3. Test R6: last_i high with strb_i = 0 forces an output beat
    send_realign(32'h60616263, 1, 0, 4'h3); // R=2
    send_realign(32'h64656667, 0, 0, 4'hF);
    send_realign(32'h68696A6B, 0, 1, 4'h0); // Output produced despite strb=0
    bfm_idle();

    // 4. Test silently consumed beat handling (L4)
    send_realign(32'h70717273, 1, 0, 4'h3); // R=2
    send_realign(32'h74757677, 0, 0, 4'hF); // middle beat
    send_realign(32'h78797A7B, 0, 0, 4'h0); // Silent consume! No output produced.
    send_realign(32'h7C7D7E7F, 0, 1, 4'hF); // output produced, data strictly unconstrained/unchecked.
    bfm_idle();

    // 5. Test L1 latitude allowance: First beat processing behavior when sink is not ready
    bfm_ready(0);
    send_realign(32'h80818283, 1, 0, 4'h3);
    repeat(10) @(posedge clk);
    bfm_ready(1);
    send_realign(32'h84858687, 0, 1, 4'hF);
    bfm_idle();

    // 6. Test single-beat line (first and last asserted simultaneously)
    send_realign(32'hB0B1B2B3, 1, 1, 4'h3); // Valid structurally, outputs nothing
    bfm_idle();

    // 7. Test X2: clear_i returning the unit to its starting condition correctly
    send_realign(32'h90919293, 1, 0, 4'h3);
    bfm_idle();
    bfm_clear();
    
    send_realign(32'hA0A1A2A3, 1, 0, 4'h1);
    send_realign(32'hA4A5A6A7, 0, 1, 4'hF);
    bfm_idle();
    
    // Hold inputs quiet to test persistent reset assertions
    bfm_reset();
    bfm_idle();

    if (expected_q.size() != 0) begin
      $display("RESULT: FAIL (R2: Missing expected output beats at end of test)");
      $finish;
    end
    
    $display("RESULT: PASS");
    $finish;
  end

endmodule