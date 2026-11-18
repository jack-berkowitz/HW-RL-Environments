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
  typedef struct packed {
    logic [31:0] data;     // expected pop_data_o
    logic        chk_data; // compare data?  (0 when L4 taints the line)
    logic        chk_strb; // require pop_strb_o == 4'hF?  (realign outputs only)
  } exp_t;

  exp_t exp_q [$];

  logic [31:0] m_ret;      // retained beat
  int           m_rot;     // rotation R, fixed at the line's first beat (R4)
  bit           m_line;    // a line is in progress
  bit           m_taint;   // line contains a silently consumed beat (L4)
  int           offer_cnt; // cycles a beat has been offered with sink ready (X3)

  task automatic tb_fail(input string why);
    $display("RESULT: FAIL (%s)", why);
    $finish;
  endtask

  task automatic tb_drain_check(input string why);
    if (exp_q.size() != 0) tb_fail(why);
  endtask

  function automatic int popcnt4(input logic [3:0] s);
    return s[0] + s[1] + s[2] + s[3];
  endfunction

  function automatic logic [3:0] rot_strb(input int r);
    case (r)
      0: return 4'h0;
      1: return 4'h1;
      2: return 4'h3;
      3: return 4'h7;
      default: return 4'hF;
    endcase
  endfunction

  // Sample everything AT the rising edge; the driver drives at negedge.
  always @(posedge clk) begin
    automatic logic        in_hs, out_hs;
    automatic logic [63:0] hi_w, lo_w;
    automatic exp_t        e;
    in_hs  = pvalid & pready;
    out_hs = qvalid & qready;
    if (!rst_n) begin
      exp_q.delete(); m_line = 0; m_taint = 0; offer_cnt = 0;
    end else if (clr) begin
      // X2: clear returns the unit to its starting condition
      exp_q.delete(); m_line = 0; m_taint = 0; offer_cnt = 0;
    end else begin
      // ---- model the input side ----
      if (in_hs) begin
        if (!ra) begin
          // P1: transparent -- same beat must appear on the output.
          // pop_strb_o here is latitude L3: deliberately not checked.
          e.data = pdata; e.chk_data = 1'b1; e.chk_strb = 1'b0;
          exp_q.push_back(e);
        end else begin
          if (fst) begin
            // R1: first beat is consumed and retained, produces no output.
            // R4: rotation fixed here, from strb_i's popcount.
            m_ret = pdata; m_rot = popcnt4(strb);
            m_line = 1'b1; m_taint = 1'b0;
          end else if (m_line) begin
            if (lst || (strb != 4'h0)) begin
              // R2/R6: output owed.  Formula straight from the spec:
              //   (push_data << 8R) | (retained >> 8(4-R)), 32-bit shifts.
              hi_w = {32'b0, pdata} << (8 * m_rot);
              lo_w = {32'b0, m_ret} >> (8 * (4 - m_rot));
              e.data = hi_w[31:0] | lo_w[31:0];
              e.chk_data = !m_taint;  // L4: data unspecified after a silent beat
              e.chk_strb = 1'b1;      // R3: all ones while realigning
              exp_q.push_back(e);
              m_ret = pdata;
            end else begin
              // silently consumed: no output under EITHER L4 reading,
              // but the retained beat is now ambiguous -> stop checking data.
              m_taint = 1'b1;
            end
          end
        end
      end
      // ---- check the output side ----
      if (out_hs) begin
        if (exp_q.size() == 0)
          tb_fail("unexpected output beat -- R2 'iff' / P1 / R1 violated");
        e = exp_q.pop_front();
        if (e.chk_data && (qdata !== e.data))
          tb_fail("pop_data_o mismatch -- R2/R5 (byte order or rotation)");
        if (e.chk_strb && (qstrb !== 4'hF))
          tb_fail("pop_strb_o not all ones while realigning -- R3");
      end
      // ---- P1 handshake coupling (transparent mode only) ----
      if (pvalid && !ra) begin
        if (qvalid !== 1'b1)
          tb_fail("pop_valid_o does not follow push_valid_i -- P1");
        if (pready !== qready)
          tb_fail("push_ready_o does not follow pop_ready_i -- P1");
      end
      // ---- X3 liveness: sink ready => beat accepted within 16 cycles ----
      if (pvalid && qready) begin
        if (!pready) begin
          offer_cnt++;
          if (offer_cnt > 16) tb_fail("beat not accepted within 16 cycles -- X3");
        end else begin
          offer_cnt = 0;
        end
      end else begin
        offer_cnt = 0;
      end
    end
  end

  // ---------------------------------------------------------------------------
  // STIMULUS
  // ---------------------------------------------------------------------------
  initial begin
    bfm_reset();

    // X1: after reset, with inputs quiet, nothing is originated.
    repeat (3) @(posedge clk);
    if (qvalid !== 1'b0) tb_fail("pop_valid_o high after reset -- X1");

    // ---- P1: transparent traffic, with a backpressure gap in the middle ----
    for (int i = 0; i < 8; i++)
      bfm_send(32'h5100_0000 + i, 1'b0, 1'b0, 1'b0, 4'hF, 4'hF);
    bfm_ready(0);
    repeat (4) @(posedge clk);
    bfm_ready(1);
    // partial push_strb in transparent mode: output strobe is L3 latitude,
    // so we must accept all-ones OR passthrough -- we check neither.
    for (int i = 8; i < 16; i++)
      bfm_send(32'h5100_0000 + i, 1'b0, 1'b0, 1'b0, 4'hF, 4'h3);
    bfm_idle();
    tb_drain_check("P1: transparent output beats missing");

    // ---- P1 backpressure: sink not ready => input must not move ----
    bfm_ready(0);
    bfm_send(32'h5200_0001, 1'b0, 1'b0, 1'b0, 4'hF, 4'hF);
    repeat (15) @(posedge clk);   // checker asserts pready==0 throughout
    bfm_ready(1);
    bfm_idle();
    tb_drain_check("P1: backpressured transparent beat lost");

    // ---- R: one full line per rotation 0..4 ----
    // Non-first beats carry varying non-zero strb_i values, to catch designs
    // that re-derive the rotation mid-line (R4) or gate on the wrong strobe.
    // The final beat has strb_i==0 and last_i==1: exercises R6.
    for (int rr = 0; rr <= 4; rr++) begin
      bfm_send(32'hA000_0000 + rr*16, 1'b1, 1'b0, 1'b1, rot_strb(rr), 4'hF);
      for (int j = 1; j <= 4; j++)
        bfm_send(32'hA100_0000 + rr*16 + j, 1'b0, 1'b0, 1'b1,
                 (j==1) ? 4'h1 : (j==2) ? 4'h3 : (j==3) ? 4'hC : 4'hF, 4'hF);
      bfm_send(32'hA200_0000 + rr, 1'b0, 1'b1, 1'b1, 4'h0, 4'hF);
      bfm_idle();
      tb_drain_check("R2: realign output beats missing");
    end

    // ---- R1: a first beat marked last still produces NO output ----
    bfm_send(32'hA300_0001, 1'b1, 1'b1, 1'b1, 4'h2, 4'hF);
    bfm_idle();
    tb_drain_check("R1: first beat of a line produced an output");

    // ---- L4/R2 count: silent beat produces no output; the last beat after
    //      it still must (R6).  Data after the silent beat is unchecked. ----
    bfm_send(32'hA400_0001, 1'b1, 1'b0, 1'b1, 4'h1, 4'hF);
    bfm_send(32'hA400_0002, 1'b0, 1'b0, 1'b1, 4'h0, 4'hF); // silently consumed
    bfm_send(32'hA400_0003, 1'b0, 1'b1, 1'b1, 4'h0, 4'hF); // R6: output owed
    bfm_idle();
    tb_drain_check("R2/R6: output for last beat missing after silent beat");

    // ---- mode switch back to transparent (retained beat must not leak) ----
    for (int i = 0; i < 4; i++)
      bfm_send(32'h5300_0000 + i, 1'b0, 1'b0, 1'b0, 4'hF, 4'hF);
    bfm_idle();
    tb_drain_check("P1: transparent outputs missing after realign lines");

    // ---- X2: clear between lines ----
    bfm_send(32'hA500_0001, 1'b1, 1'b0, 1'b1, 4'h7, 4'hF);
    bfm_send(32'hA500_0002, 1'b0, 1'b0, 1'b1, 4'hF, 4'hF);
    bfm_idle();
    tb_drain_check("R2: output missing before clear test");
    bfm_clear();
    bfm_send(32'hA600_0001, 1'b1, 1'b0, 1'b1, 4'h0, 4'hF); // new line, R = 0
    bfm_send(32'hA600_0002, 1'b0, 1'b1, 1'b1, 4'hF, 4'hF);
    bfm_idle();
    tb_drain_check("X2/R2: outputs missing after clear");

    // ---- X2: clear in the middle of a line, then a fresh line ----
    bfm_send(32'hA700_0001, 1'b1, 1'b0, 1'b1, 4'h3, 4'hF);
    bfm_send(32'hA700_0002, 1'b0, 1'b0, 1'b1, 4'h0, 4'hF); // silent beat
    bfm_idle();
    bfm_clear();
    bfm_send(32'hA800_0001, 1'b1, 1'b0, 1'b1, 4'h1, 4'hF); // new line, R = 1
    bfm_send(32'hA800_0002, 1'b0, 1'b1, 1'b1, 4'hF, 4'hF);
    bfm_idle();
    tb_drain_check("X2/R2: outputs missing after mid-line clear");

    $display("RESULT: PASS");
    $finish;
  end

endmodule
