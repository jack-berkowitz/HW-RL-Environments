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

  // ---- the driver ------------------------------------------------------------
  logic bfm_hs;
  always @(posedge clk) bfm_hs <= (rst_n && !clr) ? (pvalid & pready) : 1'b0;

  always @(negedge clk) begin
    if (!rst_n) begin
      pvalid = 1'b0;
    end else begin
      if (bfm_hs && bfm_q.size() > 0) begin
        void'(bfm_q.pop_front());
        pvalid = 1'b0;
      end
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
  // Checking and stimulus
  // ---------------------------------------------------------------------------

  typedef struct packed {
    logic [31:0] data;
    logic [31:0] alt_data;
    logic        alt_ok;
    logic        realign;
  } expected_t;

  expected_t expected_q [$];

  task automatic fail(input string clause, input string detail);
    $display("FAIL: %s: %s (time=%0t)", clause, detail, $time);
    $display("RESULT: FAIL");
    $finish;
  endtask

  task automatic expect_one(input logic [31:0] data, input bit is_realign);
    expected_t e;
    e.data     = data;
    e.alt_data = '0;
    e.alt_ok   = 1'b0;
    e.realign  = is_realign;
    expected_q.push_back(e);
  endtask

  // Used only where L4 permits either retained-beat choice.
  task automatic expect_either(input logic [31:0] data,
                               input logic [31:0] alt_data);
    expected_t e;
    e.data     = data;
    e.alt_data = alt_data;
    e.alt_ok   = 1'b1;
    e.realign  = 1'b1;
    expected_q.push_back(e);
  endtask

  function automatic logic [3:0] rotation_strobe(input int r);
    case (r)
      0: rotation_strobe = 4'b0000;
      1: rotation_strobe = 4'b0001;
      2: rotation_strobe = 4'b0101; // popcount, not a numeric rotation field
      3: rotation_strobe = 4'b1011;
      default: rotation_strobe = 4'b1111;
    endcase
  endfunction

  function automatic logic [31:0] joined_data(input logic [31:0] current,
                                               input logic [31:0] retained,
                                               input int r);
    if (r == 0)
      joined_data = current;
    else if (r == 4)
      joined_data = retained;
    else
      joined_data = (current << (8*r)) | (retained >> (8*(4-r)));
  endfunction

  // Check payload whenever valid is asserted, but account for a transfer only
  // on an actual output handshake. No payload requirement is imposed when
  // qvalid is low (L2), and transparent-mode strobes are deliberately ignored.
  always @(posedge clk) begin
    automatic expected_t e;
    if (rst_n && !clr && qvalid) begin
      if (expected_q.size() == 0) begin
        fail("R1/R2/P1", "unexpected output beat");
      end else begin
        e = expected_q[0];
        if (qdata !== e.data && (!e.alt_ok || qdata !== e.alt_data)) begin
          $display("Observed data %08x, expected %08x%s%08x",
                   qdata, e.data, e.alt_ok ? " or " : "", e.alt_data);
          fail("P1/R2/R4/R5", "output data mismatch");
        end
        if (e.realign && qstrb !== 4'hF)
          fail("R3", "realigning output strobe is not all ones");
        if (qready)
          void'(expected_q.pop_front());
      end
    end
  end

  // Transparent mode has a combinational, identical data-path handshake.
  always @(posedge clk) begin
    if (rst_n && !clr && pvalid && !ra) begin
      if (qvalid !== pvalid)
        fail("P1", "pop_valid_o does not follow push_valid_i");
      if (pready !== qready)
        fail("P1", "push_ready_o does not follow pop_ready_i");
      if (qdata !== pdata)
        fail("P1", "transparent data mismatch");
    end
  end

  // X3 applies only while the output sink is ready. In particular, this does
  // not constrain acceptance of a first beat while qready is low (L1).
  int offer_age = 0;
  always @(posedge clk) begin
    if (!rst_n || clr || !pvalid || !qready) begin
      offer_age = 0;
    end else if (pready) begin
      offer_age = 0;
    end else begin
      offer_age = offer_age + 1;
      if (offer_age > 16)
        fail("X3", "offered beat was not accepted within 16 cycles");
    end
  end

  task automatic drain_and_check(input string label_text);
    bfm_idle(400);
    repeat (10) @(posedge clk);
    if (bfm_q.size() != 0 || pvalid)
      fail("X3", {"input did not become idle after ", label_text});
    if (expected_q.size() != 0)
      fail("R1/R2/R6/P1", {"missing output beat(s) after ", label_text});
  endtask

  // A complete line with no silently consumed beats. This checks both rotation
  // extremes, all intermediate rotations, byte order, and retention across
  // several beat boundaries.
  task automatic make_full_line(input int r, input logic [31:0] base);
    logic [31:0] a, b, c, d;
    a = base;
    b = base + 32'h01020304;
    c = base + 32'h11223344;
    d = base + 32'h10203040;

    bfm_send(a, 1, 0, 1, rotation_strobe(r), 4'h0);
    expect_one(joined_data(b, a, r), 1);
    bfm_send(b, 0, 0, 1, 4'b0001, 4'h5);
    expect_one(joined_data(c, b, r), 1);
    bfm_send(c, 0, 0, 1, 4'b1111, 4'hA);
    expect_one(joined_data(d, c, r), 1);
    bfm_send(d, 0, 1, 1, 4'b0010, 4'h3);
  endtask

  initial begin
    logic [31:0] a, b, c, d, e;

    // Do not sample at time zero: X1 defines behaviour from the first edge.
    repeat (2) @(posedge clk);
    if (qvalid !== 1'b0)
      fail("X1", "output valid while reset is asserted with quiet inputs");

    bfm_reset();

    // Transparent mode under backpressure, with a partial input strobe. The
    // output strobe is intentionally not checked (P2/L3).
    @(negedge clk);
    bfm_ready(1'b0);
    expect_one(32'h01234567, 0);
    bfm_send(32'h01234567, 0, 0, 0, 4'h0, 4'h3);
    repeat (4) @(posedge clk);
    @(negedge clk);
    bfm_ready(1'b1);
    drain_and_check("transparent backpressure");

    // Several transparent transfers, again with strobes that distinguish the
    // two permitted L3 implementations.
    expect_one(32'h89ABCDEF, 0);
    bfm_send(32'h89ABCDEF, 0, 0, 0, 4'hF, 4'h0);
    expect_one(32'hA5A55A5A, 0);
    bfm_send(32'hA5A55A5A, 1, 0, 0, 4'h0, 4'h6);
    expect_one(32'hDEADBEEF, 0);
    bfm_send(32'hDEADBEEF, 0, 1, 0, 4'h0, 4'h9);
    drain_and_check("transparent transfers");

    // Every rotation, including R=0 (current beat) and R=4 (whole-beat delay).
    for (int r = 0; r <= 4; r++) begin
      make_full_line(r, 32'h10000000 + 32'h01000000*r);
      drain_and_check($sformatf("full line at rotation %0d", r));
    end

    // Exercise L1 in both permitted forms: hold the sink not ready around the
    // first beat. No acceptance requirement is made until qready is raised.
    @(negedge clk);
    bfm_ready(1'b0);
    make_full_line(3, 32'hC0000000);
    repeat (4) @(posedge clk);
    @(negedge clk);
    bfm_ready(1'b1);
    drain_and_check("first beat with sink not ready");

    // R4: later strb_i values must not change the rotation selected by the
    // first beat. The final clear strobe also checks R6.
    a = 32'h03020100;
    b = 32'h13121110;
    c = 32'h23222120;
    d = 32'h33323130;
    bfm_send(a, 1, 0, 1, 4'b0101, 4'hF); // fixed R=2
    expect_one(joined_data(b, a, 2), 1);
    bfm_send(b, 0, 0, 1, 4'b1111, 4'hF);
    expect_one(joined_data(c, b, 2), 1);
    bfm_send(c, 0, 0, 1, 4'b0001, 4'hF);
    expect_one(joined_data(d, c, 2), 1);
    bfm_send(d, 0, 1, 1, 4'b0000, 4'hF); // last forces output
    drain_and_check("fixed rotation and last with clear strobe");

    // R2 suppression and L4. Beat c is silently consumed. The next output may
    // join against either c or b, but there must still be exactly one output.
    a = 32'h44332211;
    b = 32'h88776655;
    c = 32'hCCBBAA99;
    d = 32'h00FFEEDD;
    e = 32'h55667788;
    bfm_send(a, 1, 0, 1, 4'b0001, 4'hF); // R=1
    expect_one(joined_data(b, a, 1), 1);
    bfm_send(b, 0, 0, 1, 4'b0001, 4'hF);
    bfm_send(c, 0, 0, 1, 4'b0000, 4'hF); // no expected output
    expect_either(joined_data(d, c, 1), joined_data(d, b, 1));
    bfm_send(d, 0, 0, 1, 4'b0010, 4'hF);
    expect_one(joined_data(e, d, 1), 1);
    bfm_send(e, 0, 1, 1, 4'b0000, 4'hF);
    drain_and_check("silent consumption");

    // R1 takes precedence for a first beat, even if last is also asserted.
    bfm_send(32'hFEEDFACE, 1, 1, 1, 4'b1111, 4'hF);
    drain_and_check("first-only line");

    // X2: discard a retained first beat and require a genuinely new line.
    bfm_send(32'h11111111, 1, 0, 1, 4'b0101, 4'hF);
    drain_and_check("line before clear");
    bfm_clear();
    make_full_line(2, 32'h60000000);
    drain_and_check("line after clear");

    // X1: asynchronous reset also discards retained state. Check only with
    // quiet inputs, since combinational pass-through is not reset-gated.
    bfm_send(32'h22222222, 1, 0, 1, 4'b1111, 4'hF);
    drain_and_check("line before reset");
    @(negedge clk);
    rst_n = 1'b0;
    repeat (2) begin
      @(posedge clk);
      if (qvalid !== 1'b0)
        fail("X1", "retained/output state survived asynchronous reset");
    end
    @(negedge clk);
    rst_n = 1'b1;
    repeat (2) @(posedge clk);

    make_full_line(4, 32'h70000000);
    drain_and_check("line after reset");

    // A final transparent transfer checks that mode changes leave no stale
    // realignment state or output behind.
    expect_one(32'hCAFEBABE, 0);
    bfm_send(32'hCAFEBABE, 0, 1, 0, 4'h0, 4'h2);
    drain_and_check("final transparent transfer");

    $display("RESULT: PASS");
    $finish;
  end

endmodule
