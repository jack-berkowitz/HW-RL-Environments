module stream_realign_tb;

// ---------------------------------------------------------------------------
// PROVIDED PLUMBING -- moves beats, checks nothing.
// ---------------------------------------------------------------------------
  logic clk = 1'b0;
  always #5 clk = ~clk;

  int bfm_cycle = 0;
  always @(posedge clk) if (rst_n) bfm_cycle <= bfm_cycle + 1;

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
// CHECKER AND STIMULUS
// ---------------------------------------------------------------------------
// Reference model: for each line the first beat fixes R = countones(strb_i)
// and is retained (R1). Each later beat owes an output iff last_i or strb_i
// != 0 (R2/R6), with value (cur << 8R) | (ret >> 8(4-R)) (R2/R5). Beats in
// lines containing a silently consumed beat get their data masked off (L4);
// only their count is checked. Transparent beats owe pop_data == push_data
// (P1); their strobe is never checked (L3/P2).
// ---------------------------------------------------------------------------

  typedef struct packed {
    bit          check;    // 0 = count-only (line contains a silent beat, L4)
    bit          realign;  // mode the beat was produced in
    logic [31:0] data;     // expected pop_data_o
  } exp_t;

  exp_t        exp_q [$];
  int          failed    = 0;
  int          edge_cnt  = 0;
  int          live_cnt  = 0;
  bit          m_in_line = 0;
  bit          m_silent  = 0;
  int          m_R       = 0;
  logic [31:0] m_ret     = '0;

  always @(posedge clk) edge_cnt <= edge_cnt + 1;

  task automatic fail(input string msg);
    if (failed == 0) $display("TB FAIL: %s", msg);
    failed = 1;
  endtask

  // Queue a beat and update the reference model.
  task automatic xsend(input logic [31:0] data, input bit first, input bit last,
                       input bit do_realign, input logic [3:0] lstrb,
                       input logic [3:0] dstrb = 4'hF);
    bfm_send(data, first, last, do_realign, lstrb, dstrb);
    if (!do_realign) begin
      exp_t e;
      e.check = 1'b1; e.realign = 1'b0; e.data = data;
      exp_q.push_back(e);
    end else if (first) begin
      m_in_line = 1'b1;                 // R1: retained, no output owed
      m_silent  = 1'b0;
      m_R       = $countones(lstrb);    // R4: fixed for the line
      m_ret     = data;
    end else if (m_in_line) begin
      if (last || (lstrb != 4'h0)) begin
        exp_t e;
        e.data    = (data << (8*m_R)) | (m_ret >> (8*(4-m_R)));
        e.check   = !m_silent;          // L4: data undefined after a silent beat
        e.realign = 1'b1;
        exp_q.push_back(e);
      end else begin
        m_silent = 1'b1;                // R2: consumed, no output owed
      end
      m_ret = data;
      if (last) m_in_line = 1'b0;
    end
  endtask

  task automatic phase_end(input string name);
    bfm_idle();
    if (exp_q.size() != 0)
      fail($sformatf("R2/R6 [%s]: %0d owed output beat(s) never produced",
                     name, exp_q.size()));
    repeat (3) @(posedge clk);
    if (qvalid === 1'b1)
      fail($sformatf("R2 [%s]: pop_valid_o asserted with nothing owed", name));
  endtask

  // ---- output-side and transparency checks (sampled at the rising edge) ----
  always @(posedge clk) begin
    if (!rst_n) begin
      // X1: with inputs quiet, nothing may be originated while reset is low.
      // Guard on edge_cnt: outputs are unknown before the first clock edge.
      if (edge_cnt >= 2 && qvalid !== 1'b0)
        fail("X1: pop_valid_o not low while rst_ni is low (inputs quiet)");
    end else if (!clr) begin
      if (qvalid && qready) begin
        if (exp_q.size() == 0) begin
          fail("R1/R2: output beat produced with none owed");
        end else begin
          automatic exp_t e = exp_q.pop_front();
          if (e.realign && (qstrb !== 4'hF))
            fail("R3: pop_strb_o not all ones on a realign-mode output beat");
          if (e.check && (qdata !== e.data))
            fail(e.realign ? "R2/R5: realigned output data mismatch"
                           : "P1: transparent-mode output data mismatch");
        end
      end
      if (!ra) begin
        // P1: transparent on data path and handshake (strobe is L3, unchecked).
        if (qvalid !== pvalid)
          fail("P1: pop_valid_o does not follow push_valid_i while realign_i low");
        if (pvalid) begin
          if (qdata !== pdata)
            fail("P1: pop_data_o does not equal push_data_i while realign_i low");
          if (pready !== qready)
            fail("P1: push_ready_o does not follow pop_ready_i while realign_i low");
        end
      end
    end
  end

  // ---- X3 liveness: with pop_ready high an offer must be taken in 16 cycles ----
  always @(posedge clk) begin
    if (rst_n && !clr && pvalid && qready) begin
      if (pready) live_cnt <= 0;
      else begin
        if (live_cnt >= 16)
          fail("X3: offered beat not accepted within 16 cycles with pop_ready_i high");
        live_cnt <= live_cnt + 1;
      end
    end else begin
      live_cnt <= 0;
    end
  end

  // ---- stimulus ----
  initial begin
    bfm_reset(5);

    // B: transparent, sink always ready (partial push_strb: L3/P2, unchecked)
    xsend(32'h11111110, 0, 0, 0, 4'hF);
    xsend(32'h22222221, 0, 0, 0, 4'hF, 4'b0011);
    xsend(32'h33333332, 0, 0, 0, 4'hF, 4'b0101);
    xsend(32'h44444443, 0, 0, 0, 4'hF);
    phase_end("transparent");

    // C: transparent under backpressure (P1: push_ready must follow pop_ready)
    @(negedge clk); bfm_ready(0);
    xsend(32'h55555554, 0, 0, 0, 4'hF);
    xsend(32'h66666665, 0, 0, 0, 4'hF);
    xsend(32'h77777776, 0, 0, 0, 4'hF);
    repeat (8) @(posedge clk);
    @(negedge clk); bfm_ready(1);
    phase_end("transparent backpressure");

    // D: realign R=1; later strb_i values differ from the first (R4)
    xsend(32'h10000001, 1, 0, 1, 4'b0001);
    xsend(32'h20000002, 0, 0, 1, 4'b1111);
    xsend(32'h30000003, 0, 0, 1, 4'b0010);
    xsend(32'h40000004, 0, 0, 1, 4'b0100);
    xsend(32'h50000005, 0, 1, 1, 4'b1000);
    phase_end("realign R=1");

    // E: R=0 (empty first strobe skips the first beat entirely)
    xsend(32'hA0000001, 1, 0, 1, 4'b0000);
    xsend(32'hB0000002, 0, 0, 1, 4'b1111);
    xsend(32'hC0000003, 0, 1, 1, 4'b0000);
    phase_end("realign R=0");

    // F: R=4 (fully set strobe: delayed by a whole beat, NOT modulo)
    xsend(32'hD0000001, 1, 0, 1, 4'b1111);
    xsend(32'hE0000002, 0, 0, 1, 4'b0001);
    xsend(32'hF0000003, 0, 1, 1, 4'b0011);
    phase_end("realign R=4");

    // G: R=2 with last beat whose strb_i is clear (R6)
    xsend(32'h12000001, 1, 0, 1, 4'b0011);
    xsend(32'h22000002, 0, 0, 1, 4'b1111);
    xsend(32'h32000003, 0, 0, 1, 4'b0100);
    xsend(32'h42000004, 0, 1, 1, 4'b0000);
    phase_end("realign R=2 last-strb0");

    // H: two-beat line, R=3
    xsend(32'h51000001, 1, 0, 1, 4'b0111);
    xsend(32'h61000002, 0, 1, 1, 4'b0000);
    phase_end("realign R=3 short line");

    // I: silently consumed beats -- count checked (R2 iff), data not (L4)
    xsend(32'h71000001, 1, 0, 1, 4'b0001);
    xsend(32'h72000002, 0, 0, 1, 4'b1111);
    xsend(32'h73000003, 0, 0, 1, 4'b0000);   // silent: consumed, no output
    xsend(32'h74000004, 0, 0, 1, 4'b0101);
    xsend(32'h75000005, 0, 1, 1, 4'b0000);   // R6 under silence
    phase_end("realign silent mid-line");
    xsend(32'h81000001, 1, 0, 1, 4'b0010);
    xsend(32'h82000002, 0, 0, 1, 4'b0000);   // silent right after first
    xsend(32'h83000003, 0, 1, 1, 4'b0000);
    phase_end("realign silent after first");

    // J: realign under backpressure (data still checked; L1 left free)
    @(negedge clk); bfm_ready(0);
    xsend(32'h91000001, 1, 0, 1, 4'b0011);
    xsend(32'h92000002, 0, 0, 1, 4'b1111);
    xsend(32'h93000003, 0, 0, 1, 4'b1111);
    xsend(32'h94000004, 0, 1, 1, 4'b1111);
    repeat (10) @(posedge clk);
    @(negedge clk); bfm_ready(1);
    phase_end("realign backpressure");

    // K: clear mid-line (X2): a stale retained beat must not leak into the
    // next line's outputs.
    xsend(32'hAA000001, 1, 0, 1, 4'b0001);   // line left open, retained = AB
    xsend(32'hAB000002, 0, 0, 1, 4'b1111);
    phase_end("pre-clear");
    bfm_clear();
    xsend(32'hBA000001, 1, 0, 1, 4'b0011);
    xsend(32'hBB000002, 0, 0, 1, 4'b1111);
    xsend(32'hBC000003, 0, 1, 1, 4'b1111);
    phase_end("after clear");

    // L: asynchronous reset mid-line (X1/X2)
    xsend(32'hCA000001, 1, 0, 1, 4'b0001);   // line left open, retained = CB
    xsend(32'hCB000002, 0, 0, 1, 4'b1111);
    phase_end("pre-reset");
    bfm_reset(4);
    xsend(32'hDA000001, 1, 0, 1, 4'b0001);
    xsend(32'hDB000002, 0, 0, 1, 4'b1111);
    xsend(32'hDC000003, 0, 1, 1, 4'b1111);
    phase_end("after reset");

    // M: interleave transparent beats between realign lines
    xsend(32'hEA000001, 1, 0, 1, 4'b0110);
    xsend(32'hEB000002, 0, 1, 1, 4'b1111);
    xsend(32'hEC000003, 0, 0, 0, 4'hF);
    xsend(32'hED000004, 0, 0, 0, 4'hF, 4'b0110);
    xsend(32'hEE000005, 1, 0, 1, 4'b1000);
    xsend(32'hEF000006, 0, 1, 1, 4'b1111);
    phase_end("interleave");

    repeat (10) @(posedge clk);
    if (failed == 0) $display("RESULT: PASS");
    else             $display("RESULT: FAIL");
    $finish;
  end

endmodule
