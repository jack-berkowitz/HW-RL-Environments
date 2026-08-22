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
// CHECKER LOGIC
// ---------------------------------------------------------------------------

  bit failed = 0;
  task automatic fail(string msg);
    if (!failed) begin
      $display("RESULT: FAIL (%0s)", msg);
      failed = 1;
      $finish;
    end
  endtask

  // Expected transaction queue
  typedef struct {
    logic [31:0] data;
    logic [3:0]  strb;
    bit          is_realign;
    bit          is_first; // just for bookkeeping/L1
  } exp_t;
  exp_t exp_q[$];

  // Monitor state for realign
  logic [31:0] retained_beat = 0;
  int rotation_r = 0;
  bit in_line = 0;

  function automatic int count_ones(logic [3:0] val);
    int c = 0;
    for (int i = 0; i < 4; i++) if (val[i]) c++;
    return c;
  endfunction

  function automatic logic [31:0] compute_realign(logic [31:0] cur, logic [31:0] ret, int r);
    logic [63:0] shifted;
    if (r == 0) return cur;
    if (r == 4) return ret;
    shifted = {cur, ret} >> (8 * (4 - r));
    return shifted[31:0];
  endfunction

  // Model the expected stream
  always @(posedge clk) begin
    if (!rst_n || clr) begin
      in_line = 0;
      retained_beat = 0;
      rotation_r = 0;
      exp_q.delete();
    end else if (pvalid && pready) begin
      if (!ra) begin
        // P1: pass-through
        exp_t e;
        e.data = pdata;
        e.strb = pstrb;
        e.is_realign = 0;
        e.is_first = 0;
        exp_q.push_back(e);
      end else begin
        // R1: Realign mode
        if (fst) begin
          in_line = 1;
          rotation_r = count_ones(strb);
          retained_beat = pdata;
          // No output expected for first beat
          
          // L1: Can be accepted without pop_ready_i. We won't check pop_ready here.
        end else if (in_line) begin
          // R2: after first, produces output iff last_i is high or strb_i != 0
          if (lst || strb != 0) begin
            exp_t e;
            e.data = compute_realign(pdata, retained_beat, rotation_r);
            e.strb = 4'hF; // R3: all ones
            e.is_realign = 1;
            e.is_first = 0;
            exp_q.push_back(e);
          end
          retained_beat = pdata;
          if (lst) begin
            in_line = 0;
          end
        end
      end
    end
  end

  // Checking the output
  always @(posedge clk) begin
    if (!rst_n) begin
      // X1: pop_valid_o must be low during reset
      if (qvalid) fail("X1: pop_valid_o asserted while rst_ni is low");
    end else begin
      // When valid is asserted, check against expected queue if a handshake happens
      if (qvalid && qready) begin
        if (exp_q.size() == 0) begin
          fail("Unexpected output handshake, queue empty");
        end else begin
          automatic exp_t e = exp_q.pop_front();
          if (qdata !== e.data) begin
            $display("Expected %x, got %x", e.data, qdata);
            fail("Data mismatch");
          end
          if (e.is_realign) begin
            if (qstrb !== 4'hF) fail("R3: pop_strb_o not all ones during realign");
          end else begin
            // P2/L3: pass-through strb is either push_strb_i or 4'hF
            if (qstrb !== e.strb && qstrb !== 4'hF) fail("P2/L3: pop_strb_o invalid in pass-through");
          end
        end
      end
    end
  end

  // X3: Liveness check
  int wait_cycles = 0;
  always @(posedge clk) begin
    if (rst_n && !clr) begin
      if (pvalid && qready && !pready) begin
        wait_cycles++;
        if (wait_cycles > 16) fail("X3: liveness bound exceeded, push_ready_o not asserted within 16 cycles");
      end else if (pvalid && pready) begin
        wait_cycles = 0;
      end else if (!pvalid) begin
        wait_cycles = 0;
      end
    end else begin
      wait_cycles = 0;
    end
  end

// ---------------------------------------------------------------------------
// STIMULUS
// ---------------------------------------------------------------------------
  initial begin
    // Reset system
    bfm_ready(1'b1);
    bfm_reset();
    
    // 1. Pass-through mode (P1, P2)
    bfm_send(32'h11223344, 0, 0, 0, 4'h0, 4'hA);
    bfm_send(32'h55667788, 0, 0, 0, 4'h0, 4'h5);
    bfm_idle();

    // 2. Realign Mode R=1 (R1, R2, R3, R4, R5, R6)
    bfm_send(32'hAABBCCDD, 1, 0, 1, 4'h1, 4'hF); // R=1
    bfm_send(32'h11223344, 0, 0, 1, 4'h2, 4'hF); // Should produce output
    bfm_send(32'h55667788, 0, 1, 1, 4'h0, 4'hF); // R6: last_i high with 0 strb
    bfm_idle();
    
    // 3. Realign Mode R=4 (skip first beat output fully, 1 cycle delay basically)
    bfm_send(32'h11111111, 1, 0, 1, 4'hF, 4'hF); // R=4
    bfm_send(32'h22222222, 0, 0, 1, 4'hF, 4'hF); 
    bfm_send(32'h33333333, 0, 1, 1, 4'hF, 4'hF); 
    bfm_idle();
    
    // 4. Realign Mode R=0 (current beat only)
    bfm_send(32'h44444444, 1, 0, 1, 4'h0, 4'hF); // R=0
    bfm_send(32'h55555555, 0, 0, 1, 4'hF, 4'hF); 
    bfm_send(32'h66666666, 0, 1, 1, 4'hF, 4'hF); 
    bfm_idle();

    // 5. Test L1 (backpressure on first beat)
    bfm_ready(1'b0);
    bfm_send(32'h77777777, 1, 0, 1, 4'h3, 4'hF);
    #100;
    bfm_ready(1'b1);
    bfm_send(32'h88888888, 0, 1, 1, 4'hF, 4'hF);
    bfm_idle();

    // 6. Test Clear (X2)
    bfm_send(32'h99999999, 1, 0, 1, 4'h3, 4'hF);
    bfm_idle();
    bfm_clear();
    // After clear, state should be reset. 
    // Sending a new pass-through should work immediately without finishing the old line
    bfm_send(32'hAABBAABB, 0, 0, 0, 4'h0, 4'hF);
    bfm_idle();

    // 7. Verify we didn't leave anything in queue
    if (exp_q.size() != 0) fail("Test finished but expected items remain in queue");

    if (!failed) begin
      $display("RESULT: PASS");
      $finish;
    end
  end

endmodule