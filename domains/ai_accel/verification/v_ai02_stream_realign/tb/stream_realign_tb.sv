// Reference testbench for v_ai02 stream_realign. Scoring reference, not shipped.
//
// It carries a MODEL of the byte stream, not a recorded trace: the rotation the
// strobe names, the beat the unit is holding, and -- per line -- the whole byte
// sequence that went in against the whole byte sequence that came out. Every
// expected value is computed from the stimulus alone.
//
// The driver is an ALWAYS BLOCK so no rising edge goes unserviced, and it never
// withdraws an offer, which is what clause H2 requires of the source.
module stream_realign_tb;
  localparam int LIVE = 16;             // clause X3

  int errors = 0;
  task automatic fail(input string clause, input string detail);
    if (errors < 24) $display("FAIL %s: %s", clause, detail);
    errors++;
  endtask

  logic clk = 1'b0; always #5 clk = ~clk;
  logic rst_n = 1'b0, clr = 1'b0;
  logic ra = 1'b0, fst = 1'b0, lst = 1'b0;
  logic [3:0]  strb = 4'hF;
  logic [31:0] pdata = '0; logic [3:0] pstrb = 4'hF; logic pvalid = 1'b0;
  logic pready;
  logic [31:0] qdata; logic [3:0] qstrb; logic qvalid; logic qready = 1'b1;

  stream_realign dut (
    .clk_i(clk), .rst_ni(rst_n), .clear_i(clr), .realign_i(ra), .first_i(fst),
    .last_i(lst), .strb_i(strb), .push_data_i(pdata), .push_strb_i(pstrb),
    .push_valid_i(pvalid), .push_ready_o(pready), .pop_data_o(qdata),
    .pop_strb_o(qstrb), .pop_valid_o(qvalid), .pop_ready_i(qready));

  int cyc = 0; always @(posedge clk) if (rst_n) cyc <= cyc + 1;

  // =========================== the model ===================================
  typedef struct packed {
    logic [31:0] data;  logic [3:0] strb;
    logic        first; logic last; logic realign; logic [3:0] lstrb;
  } beat_t;

  beat_t       txq [$];          // queued to send
  beat_t       inflight [$];     // accepted, still owed an output beat
  logic [31:0] m_held;           // the beat the unit should be holding
  logic [2:0]  m_rot;            // the rotation captured at the line's first beat, 0..4
  int          n_acc = 0, n_out = 0;

  // per line, for R5
  logic [7:0]  line_in  [$];
  logic [7:0]  line_out [$];
  int          line_start = 0;   // byte index the line begins at
  bit          line_bytes_valid = 1'b1;

  // The rotation is the LITERAL popcount, 0 through 4 -- not taken modulo the
  // beat width. A full strobe gives 4, which shifts by a whole beat: the output
  // is then the previously held beat, and the line begins at byte 0. Truncating
  // this to two bits collapses 4 onto 0 and gets the aligned case exactly
  // backwards.
  function automatic logic [2:0] rot_of(input logic [3:0] s);
    automatic int n = 0;
    for (int i = 0; i < 4; i++) n += int'(s[i]);
    return 3'(n);
  endfunction

  // One formula covers every rotation, including both extremes: at r = 0 the
  // second term shifts right by 32 and vanishes, leaving the current beat; at
  // r = 4 the first term shifts left by 32 and vanishes, leaving the held one.
  function automatic logic [31:0] join_beats(input logic [31:0] cur,
                                             input logic [31:0] prev,
                                             input logic [2:0] r);
    automatic logic [31:0] hi = (int'(r) >= 4) ? 32'd0 : (cur  << (8*int'(r)));
    automatic logic [31:0] lo = (int'(r) == 0) ? 32'd0 : (prev >> (8*(4-int'(r))));
    return hi | lo;
  endfunction

  // ---- accept side, then deliver side, in ONE ordered block --------------
  // With no register on the output path a beat can be accepted and delivered in
  // the same cycle, and two separate always blocks would leave it to chance
  // whether the accept is recorded first.
  always @(posedge clk) if (rst_n && !clr) begin
    if (pvalid && pready) begin
      automatic beat_t b = txq[0];
      n_acc++;
      if (b.realign && b.first) begin
        m_held = b.data;
        m_rot  = rot_of(b.lstrb);
        line_start = 4 - int'(m_rot);   // 0 for a full strobe, 4 for an empty one
        line_in.delete(); line_out.delete(); line_bytes_valid = 1'b1;
        for (int i = 0; i < 4; i++) line_in.push_back(b.data[8*i +: 8]);
      end else if (!b.realign || b.last || (|b.lstrb)) begin
        // R2: an output beat is owed only when last_i is high or strb_i is
        // non-zero on this beat.
        inflight.push_back(b);
        if (b.realign) for (int i = 0; i < 4; i++) line_in.push_back(b.data[8*i +: 8]);
      end else begin
        // consumed with no output owed; its bytes do not reach the sink, so the
        // byte-preservation check does not apply to this line.
        line_bytes_valid = 1'b0;
      end
    end

    if (qvalid && qready) begin
      n_out++;
      if (inflight.size() == 0)
        fail("R1", $sformatf("cycle %0d: an output beat (%08x) appeared that no accepted input beat calls for. A line's first beat produces no output.",
                             cyc, qdata));
      else begin
        automatic beat_t b = inflight[0];
        automatic logic [31:0] want  = b.realign ? join_beats(b.data, m_held, m_rot) : b.data;
        // R3 binds ONLY while realigning; the transparent-mode output strobe
        // is latitude (L3). This used to read `b.realign ? 4'hF : b.strb`,
        // requiring pass-through in transparent mode -- which the anchor never
        // does, and which the second implementation always does. Either
        // requirement makes one of two correct designs non-conforming, so the
        // check is confined to the mode where the contract is definite.
        automatic logic [3:0]  wstrb = 4'hF;
        if (qdata !== want)
          fail(b.realign ? "R2" : "P1",
               $sformatf("cycle %0d: output beat is %08x, expected %08x -- input %08x joined with the held beat %08x at rotation %0d",
                         cyc, qdata, want, b.data, m_held, m_rot));
        if (b.realign && qstrb !== wstrb)
          fail("R3",
               $sformatf("cycle %0d: output strobe is %b, expected %b", cyc, qstrb, wstrb));
        if (b.realign) begin
          for (int i = 0; i < 4; i++) line_out.push_back(qdata[8*i +: 8]);
          m_held = b.data;
        end
        void'(inflight.pop_front());
      end
    end
  end

  always @(posedge clk) if (!rst_n && qvalid)
    fail("X1", "pop_valid_o is asserted while rst_ni is low");

  // R5: the whole byte sequence of a line, checked at the line's end.
  task automatic check_line(input string what);
    if (line_out.size() == 0 || !line_bytes_valid) return;
    for (int i = 0; i < line_out.size(); i++) begin
      if (line_start + i >= line_in.size()) break;
      if (line_out[i] !== line_in[line_start + i]) begin
        fail("R5", $sformatf("%s: output byte %0d is %02x, but the line's byte %0d is %02x. The output must be the input bytes from the line's first byte onward, with none lost, duplicated or reordered.",
                             what, i, line_out[i], line_start + i, line_in[line_start + i]));
        return;
      end
    end
  endtask

  // =========================== the driver ==================================
  logic hs;
  always @(posedge clk) hs <= (rst_n && !clr) ? (pvalid & pready) : 1'b0;

  always @(negedge clk) begin
    if (!rst_n) begin
      pvalid = 1'b0;
    end else begin
      if (hs && txq.size() > 0) begin void'(txq.pop_front()); pvalid = 1'b0; end
      if (!pvalid && txq.size() > 0) begin
        pdata = txq[0].data;  pstrb = txq[0].strb;  fst = txq[0].first;
        lst   = txq[0].last;  strb  = txq[0].lstrb; ra  = txq[0].realign;
        pvalid = 1'b1;
      end
    end
  end

  // =========================== stimulus =====================================
  int cov_beats = 0, cov_lines = 0, cov_partial_strb = 0, cov_stalls = 0;
  bit cov_rot [5];
  bit cov_passthrough = 0, cov_empty_last = 0, cov_clear = 0, cov_reset = 0;

  task automatic push_line(input bit do_realign, input logic [3:0] lstrb, input int n,
                           input logic [31:0] base, input logic [3:0] dstrb = 4'hF,
                           input int run_strb = -1);   // -1 = same as lstrb
    for (int i = 0; i < n; i++) begin
      beat_t b;
      b.data    = base + 32'(i * 32'h04040404);
      b.strb    = dstrb;
      b.first   = (i == 0);
      b.last    = (i == n - 1);
      b.realign = do_realign;
      b.lstrb   = (i == 0 || run_strb < 0) ? lstrb : 4'(run_strb);
      txq.push_back(b);
      cov_beats++;
    end
    if (do_realign) begin cov_lines++; cov_rot[int'(rot_of(lstrb))] = 1'b1; end
    else cov_passthrough = 1'b1;
    if (dstrb != 4'hF) cov_partial_strb++;
  endtask

  task automatic drain(input string what);
    for (int t = 0; t < 400; t++) begin
      @(posedge clk);
      if (txq.size() == 0 && !pvalid && inflight.size() == 0) break;
    end
    repeat (6) @(posedge clk);
    if (txq.size() != 0 || pvalid)
      fail("X3", $sformatf("%s: the input stream stalled with %0d beat(s) still to send",
                           what, txq.size() + (pvalid ? 1 : 0)));
    if (inflight.size() != 0)
      fail("R5", $sformatf("%s: %0d accepted beat(s) never produced an output beat",
                           what, inflight.size()));
    check_line(what);
    line_in.delete(); line_out.delete();
  endtask

  task automatic do_clear();
    cov_clear = 1'b1;
    @(negedge clk) clr = 1'b1;
    @(negedge clk) clr = 1'b0;
    inflight.delete(); line_in.delete(); line_out.delete();
    repeat (2) @(posedge clk);
  endtask

  initial begin
    for (int i = 0; i < 5; i++) cov_rot[i] = 1'b0;
    repeat (5) @(posedge clk);
    @(negedge clk) rst_n = 1'b1;
    repeat (2) @(posedge clk);

    // -- 1. pass-through --------------------------------------------------
    push_line(1'b0, 4'hF, 5, 32'h03020100);
    drain("pass-through");
    do_clear();

    // -- 2. every rotation the strobe can name ----------------------------
    push_line(1'b1, 4'b1111, 5, 32'h13121110); drain("aligned line, rotation 0"); do_clear();
    push_line(1'b1, 4'b1110, 5, 32'h23222120); drain("line at byte 1");          do_clear();
    push_line(1'b1, 4'b1100, 6, 32'h33323130); drain("line at byte 2");          do_clear();
    push_line(1'b1, 4'b1000, 6, 32'h43424140); drain("line at byte 3");          do_clear();
    // an EMPTY strobe at a line's first beat: rotation 0, so the line begins at
    // byte 4 and the first beat is skipped outright.
    // The first beat's strobe fixes the rotation; later beats need a non-zero
    // strobe of their own or R2 suppresses their output entirely.
    push_line(1'b1, 4'b0000, 5, 32'hC3C2C1C0, 4'hF, 'hF);
    drain("empty strobe at the first beat, rotation 0"); do_clear();

    // -- 3. a PARTIAL input strobe: R3 fixes the output strobe regardless --
    push_line(1'b1, 4'b1100, 4, 32'h53525150, 4'b0011);
    drain("partial input strobe");
    do_clear();

    // -- 4. a final beat whose strobe is empty (R6) -----------------------
    begin
      beat_t b;
      cov_empty_last = 1'b1;
      b.data = 32'h63626160; b.strb = 4'hF; b.first = 1'b1; b.last = 1'b0;
      b.realign = 1'b1; b.lstrb = 4'b1100; txq.push_back(b); cov_beats++;
      b.data = 32'h67666564; b.first = 1'b0; txq.push_back(b); cov_beats++;
      b.data = 32'h6B6A6968; b.last = 1'b1; b.lstrb = 4'b0000; txq.push_back(b); cov_beats++;
      cov_lines++;
    end
    drain("final beat with an empty strobe");
    do_clear();

    // -- 5. the sink stalls mid-line --------------------------------------
    cov_stalls++;
    push_line(1'b1, 4'b1110, 6, 32'h73727170);
    repeat (4) @(posedge clk);
    @(negedge clk) qready = 1'b0;
    repeat (10) @(posedge clk);
    @(negedge clk) qready = 1'b1;
    drain("with the sink stalled mid-line");
    do_clear();

    // -- 6. back-to-back lines with different rotations, no clear between --
    push_line(1'b1, 4'b1110, 4, 32'h83828180);
    push_line(1'b1, 4'b1000, 4, 32'h93929190);
    drain("two lines back to back");
    do_clear();

    // -- 7. reset mid-stream ----------------------------------------------
    cov_reset = 1'b1;
    push_line(1'b1, 4'b1100, 6, 32'hA3A2A1A0);
    repeat (5) @(posedge clk);
    @(negedge clk) rst_n = 1'b0;
    repeat (4) @(posedge clk);
    @(negedge clk) rst_n = 1'b1;
    txq.delete(); inflight.delete(); line_in.delete(); line_out.delete();
    repeat (3) @(posedge clk);
    push_line(1'b1, 4'b1110, 5, 32'hB3B2B1B0);
    drain("after a mid-stream reset");

    // -- rule 4 floors, on STIMULUS only ----------------------------------
    if (cov_beats < 45)      fail("COVERAGE", $sformatf("only %0d beats offered", cov_beats));
    if (cov_lines < 6)       fail("COVERAGE", $sformatf("only %0d realigned lines driven", cov_lines));
    if (cov_partial_strb < 1)fail("COVERAGE", "the input strobe was never partial -- R3 is untested");
    if (cov_stalls < 1)      fail("COVERAGE", "the sink was never stalled");
    if (!cov_passthrough)    fail("COVERAGE", "pass-through was never exercised");
    if (!cov_empty_last)     fail("COVERAGE", "no line ended with an empty strobe -- R6 is untested");
    if (!cov_clear)          fail("COVERAGE", "clear_i was never asserted");
    if (!cov_reset)          fail("COVERAGE", "reset was never asserted mid-stream");
    for (int i = 0; i < 5; i++)
      if (!cov_rot[i]) fail("COVERAGE", $sformatf("rotation %0d was never driven", i));

    if (errors == 0) $display("RESULT: PASS");
    else $display("RESULT: FAIL (%0d violation%s)", errors, (errors == 1) ? "" : "s");
    $display("  [coverage] beats=%0d accepted=%0d output=%0d lines=%0d", cov_beats, n_acc, n_out, cov_lines);
    $finish;
  end

  initial begin
    #2_000_000;
    $display("RESULT: FAIL (watchdog: no forward progress; %0d violation(s) so far)", errors);
    $finish;
  end
endmodule
