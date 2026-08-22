// ===========================================================================
// stream_realign_tb.sv -- specification-driven testbench for stream_realign
//
// Checks:  H2 (source obligation, met by the provided driver)
//          P1  data-path + handshake transparency while realign_i is low
//          R1  first beat of a line produces no output
//          R2  output iff last_i | strb_i!=0, value = rotation join
//          R3  pop_strb_o all ones on every realigned output beat
//          R4  rotation fixed for the line, taken from strb_i at first beat
//          R5  byte stream preserved (implied by R2 value + ordering)
//          R6  last beat with clear strobe still produces its beat
//          X1  pop_valid_o low while rst_ni low
//          X2  clear_i returns the unit to its starting condition
//          X3  liveness: beat accepted within 16 cycles with pop_ready_i high
//
// Deliberately NOT checked (latitude L1/L2/L3):
//          L1  whether a line's first beat is taken while the sink is stalled
//          L2  pop_data_o / pop_strb_o in any cycle where pop_valid_o is low
//          L3  pop_strb_o on beats produced while realign_i is low
// ===========================================================================
module stream_realign_tb;

  // -------------------------------------------------------------------------
  // PROVIDED PLUMBING -- moves beats, checks nothing.
  // -------------------------------------------------------------------------

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

  // -------------------------------------------------------------------------
  // VERDICT PLUMBING
  // -------------------------------------------------------------------------
  bit    verdict_done = 1'b0;
  string phase_name   = "startup";
  int    phase_cnt    = 0;

  task automatic set_phase(input string nm);
    phase_name = nm;
    phase_cnt  = phase_cnt + 1;
  endtask

  task automatic tb_fail(input string clause_id, input string detail);
    if (!verdict_done) begin
      verdict_done = 1'b1;
      $display("--------------------------------------------------------------");
      $display("  time    : %0t   (cycle %0d)", $time, bfm_cycle);
      $display("  phase   : %s", phase_name);
      $display("  clause  : %s", clause_id);
      $display("  detail  : %s", detail);
      $display("--------------------------------------------------------------");
      $display("RESULT: FAIL");
    end
    $finish;
  endtask

  // -------------------------------------------------------------------------
  // REFERENCE MODEL
  // -------------------------------------------------------------------------

  // Rotation R = number of set bits in strb_i, 0..4, NOT taken modulo 4.
  function automatic int popcnt4(input logic [3:0] v);
    int n;
    n = 0;
    for (int i = 0; i < 4; i++) if (v[i] === 1'b1) n = n + 1;
    return n;
  endfunction

  // pop_data_o = (push_data_i << 8R) | (retained >> 8(4-R)), shifts >=32 -> 0
  function automatic logic [31:0] join_rot(input logic [31:0] cur,
                                           input logic [31:0] ret,
                                           input int rot);
    logic [31:0] hi;
    logic [31:0] lo;
    hi = (rot >= 4) ? 32'h0000_0000 : (cur << (8*rot));
    lo = (rot <= 0) ? 32'h0000_0000 : (ret >> (8*(4-rot)));
    return hi | lo;
  endfunction

  // Expected output beats, in order.  Identified by seq_no, never by value.
  typedef struct packed {
    logic [31:0] data;      // required pop_data_o
    logic [31:0] seq_no;    // bookkeeping identity
    logic        chk_strb;  // 1 => R3 applies (realigned beat)
  } exp_rec_t;

  exp_rec_t exp_q [$];
  int exp_pushed = 0;
  int exp_popped = 0;

  task automatic exp_push(input logic [31:0] d, input bit strict_strb);
    exp_rec_t e;
    e.data     = d;
    e.seq_no   = exp_pushed;
    e.chk_strb = strict_strb;
    exp_q.push_back(e);
    exp_pushed = exp_pushed + 1;
  endtask

  // model state
  logic [31:0] mdl_ret  = 32'd0;   // retained beat
  int          mdl_rot  = 0;       // R, fixed for the line (R4)
  int          stall_ct = 0;       // X3 counter
  bit          p1_en    = 1'b0;    // strict P1 checking window

  task automatic mdl_reset();
    exp_q.delete();
    mdl_ret  = 32'd0;
    mdl_rot  = 0;
    stall_ct = 0;
  endtask

  // -------------------------------------------------------------------------
  // MONITOR / SCOREBOARD -- samples handshakes AT the rising edge
  // -------------------------------------------------------------------------
  always @(posedge clk) begin
    if (!rst_n) begin
      mdl_reset();                               // X1/X2 starting condition
    end else if (clr) begin
      mdl_reset();                               // X2
    end else begin

      // ---- P1: while realign_i is low the handshake is the same handshake
      if (p1_en && ra === 1'b0) begin
        if (pvalid === 1'b1) begin
          if (qvalid !== 1'b1)
            tb_fail("P1", "push_valid_i high but pop_valid_o low with realign_i low");
          else if (qdata !== pdata)
            tb_fail("P1", $sformatf("pop_data_o=%08h but push_data_i=%08h with realign_i low",
                                    qdata, pdata));
          else if (pready !== qready)
            tb_fail("P1", $sformatf(
              "push_ready_o=%b does not follow pop_ready_i=%b with realign_i low (if push_ready_o never rises at all, X3 is violated too)",
              pready, qready));
        end else if (qvalid === 1'b1) begin
          tb_fail("P1", "pop_valid_o high while push_valid_i low with realign_i low");
        end
      end

      // ---- input handshake (H1): fold the accepted beat into the model
      if (pvalid === 1'b1 && pready === 1'b1) begin
        if (ra !== 1'b1) begin
          // P1: transparent on the data path; pop_strb_o unchecked (P2 / L3)
          exp_push(pdata, 1'b0);
        end else if (fst === 1'b1) begin
          // R1: consumed and retained, no output.  R4: rotation latched here.
          mdl_rot = popcnt4(strb);
          mdl_ret = pdata;
        end else begin
          // R2 / R6: output iff last_i or strb_i non-zero
          if (lst === 1'b1 || strb !== 4'h0)
            exp_push(join_rot(pdata, mdl_ret, mdl_rot), 1'b1);
          mdl_ret = pdata;
        end
      end

      // ---- output handshake (H1): check against the model
      if (qvalid === 1'b1 && qready === 1'b1) begin
        if (exp_q.size() == 0) begin
          tb_fail("R1/R2", $sformatf(
            "output beat produced when none was due (pop_data_o=%08h): a first beat must produce no output and a beat with last_i low and strb_i zero must produce none either",
            qdata));
        end else begin
          automatic exp_rec_t e = exp_q.pop_front();
          exp_popped = exp_popped + 1;
          if (qdata !== e.data && e.chk_strb === 1'b1)
            tb_fail("R2/R4/R5", $sformatf(
              "output beat #%0d: pop_data_o=%08h, expected %08h (rotation R=%0d for this line)",
              e.seq_no, qdata, e.data, mdl_rot));
          else if (qdata !== e.data)
            tb_fail("P1", $sformatf(
              "pass-through beat #%0d came out as %08h, expected %08h -- realign_i low must be transparent on the data path",
              e.seq_no, qdata, e.data));
          else if (e.chk_strb === 1'b1 && qstrb !== 4'hF)
            tb_fail("R3", $sformatf(
              "output beat #%0d: pop_strb_o=%04b while realign_i high, must be 1111",
              e.seq_no, qstrb));
        end
      end

      // ---- X3: liveness, only counted while the sink is ready
      if (pvalid === 1'b1 && qready === 1'b1 && pready !== 1'b1) begin
        stall_ct = stall_ct + 1;
        if (stall_ct > 16)
          tb_fail("X3", "input beat not accepted within 16 cycles with pop_ready_i held high");
      end else begin
        stall_ct = 0;
      end
    end
  end

  // ---- X1: pop_valid_o must not be asserted while rst_ni is low
  always @(clk) begin
    if (rst_n === 1'b0 && qvalid === 1'b1)
      tb_fail("X1", "pop_valid_o asserted while rst_ni is low");
  end

  // -------------------------------------------------------------------------
  // STIMULUS HELPERS
  // -------------------------------------------------------------------------

  // Distinct, position-tagged bytes so a lost/duplicated/reordered byte shows up.
  function automatic logic [31:0] beat_pat(input int tag, input int idx);
    logic [31:0] d;
    int t;
    d = 32'd0;
    for (int j = 0; j < 4; j++) begin
      t = tag + 4*idx + j;
      d[8*j +: 8] = t[7:0];
    end
    return d;
  endfunction

  // A line: first beat carrying the rotation strobe, then n_body beats, last marked.
  // Body beats carry strb_i = F (non-zero, and different from the first beat's
  // strobe, so a design that re-samples the rotation is caught) and
  // push_strb_i = 5 (non-zero too, so the R2 gate reads the same either way,
  // while R3 still demands an all-ones output strobe).
  task automatic send_line(input logic [3:0] rot_strb, input int tag, input int n_body);
    bfm_send(beat_pat(tag, 0), 1'b1, 1'b0, 1'b1, rot_strb, 4'hF);
    for (int k = 1; k <= n_body; k++)
      bfm_send(beat_pat(tag, k), 1'b0, (k == n_body), 1'b1, 4'hF, 4'h5);
  endtask

  // clear_i, then insist the unit is back at its starting condition: with
  // nothing offered, nothing may be presented on the output either.
  task automatic clear_and_check();
    bfm_clear();
    for (int t = 0; t < 4; t++) begin
      @(posedge clk);
      if (qvalid === 1'b1 && pvalid !== 1'b1)
        tb_fail("X2", "pop_valid_o asserted after clear_i with nothing offered on the input");
    end
  endtask

  // Drain, then insist that every offered beat was taken and every expected
  // output beat was produced.
  task automatic settle(input int extra = 12);
    @(negedge clk);
    bfm_ready(1'b1);
    bfm_idle();
    repeat (extra) @(posedge clk);
    @(negedge clk);
    if (bfm_q.size() != 0)
      tb_fail("X3", $sformatf("%0d offered beat(s) were never accepted", bfm_q.size()));
    if (exp_q.size() != 0)
      tb_fail("R2/R6", $sformatf(
        "%0d expected output beat(s) never produced -- a beat after the first must produce an output when last_i is high or strb_i is non-zero",
        exp_q.size()));
  endtask

  // -------------------------------------------------------------------------
  // STIMULUS
  // -------------------------------------------------------------------------
  initial begin
    bfm_ready(1'b1);
    bfm_reset(5);

    // ================= P1 : pass-through ==================================
    // A warm-up with the strict P1 window still closed, so a design that simply
    // never accepts anything is reported against X3 rather than against P1.
    set_phase("X3 liveness warm-up");
    bfm_send(32'h0BADC0DE, 1'b0, 1'b0, 1'b0, 4'hF, 4'hF);
    bfm_send(32'h5EED1234, 1'b0, 1'b0, 1'b0, 4'hF, 4'h1);
    settle();

    set_phase("P1 pass-through, realign_i low");
    @(negedge clk); p1_en = 1'b1;
    bfm_send(32'h11223344, 1'b0, 1'b0, 1'b0, 4'h0, 4'h5);
    bfm_send(32'hDEADBEEF, 1'b0, 1'b0, 1'b0, 4'hF, 4'h0);
    bfm_send(32'h0F1E2D3C, 1'b0, 1'b1, 1'b0, 4'h3, 4'hF);
    bfm_send(32'hA5A50F0F, 1'b1, 1'b0, 1'b0, 4'h9, 4'hA);   // first_i is inert here
    bfm_send(32'h00000000, 1'b0, 1'b0, 1'b0, 4'hF, 4'h0);
    settle();

    set_phase("P1 pass-through under back-pressure");
    @(negedge clk); bfm_ready(1'b0);
    bfm_send(32'hCAFEF00D, 1'b0, 1'b0, 1'b0, 4'hF, 4'h9);
    repeat (6) @(posedge clk);          // pop_valid_o must track push_valid_i,
    @(negedge clk); bfm_ready(1'b1);    // push_ready_o must track pop_ready_i
    settle();
    @(negedge clk); p1_en = 1'b0;
    clear_and_check();

    // ================= R : realignment ====================================
    set_phase("R rotation 4 (strb_i=1111): output is the retained beat");
    send_line(4'hF, 16, 3);
    settle();

    set_phase("R rotation 2 (strb_i=0011)");
    send_line(4'b0011, 48, 3);
    settle();

    set_phase("R rotation 2 from a scattered strobe (strb_i=1010, popcount not position)");
    send_line(4'b1010, 80, 3);
    settle();

    set_phase("R rotation 1 (strb_i=0001)");
    send_line(4'b0001, 112, 3);
    settle();

    set_phase("R rotation 3 (strb_i=0111)");
    send_line(4'b0111, 144, 4);
    settle();

    set_phase("R rotation 0 (strb_i=0000): output is the current beat");
    send_line(4'b0000, 176, 3);
    settle();

    set_phase("R short line: first beat plus a single last beat");
    send_line(4'b0011, 208, 1);
    settle();

    // ================= R6 : last beat with a clear strobe =================
    set_phase("R6 last beat with strb_i=0 (rotation 4)");
    bfm_send(beat_pat(8, 0), 1'b1, 1'b0, 1'b1, 4'hF, 4'hF);
    bfm_send(beat_pat(8, 1), 1'b0, 1'b0, 1'b1, 4'hF, 4'h5);
    bfm_send(beat_pat(8, 2), 1'b0, 1'b1, 1'b1, 4'h0, 4'h0);
    settle();

    set_phase("R6 last beat with strb_i=0 (rotation 2)");
    bfm_send(beat_pat(40, 0), 1'b1, 1'b0, 1'b1, 4'b0011, 4'hF);
    bfm_send(beat_pat(40, 1), 1'b0, 1'b0, 1'b1, 4'hF,    4'h5);
    bfm_send(beat_pat(40, 2), 1'b0, 1'b1, 1'b1, 4'h0,    4'h0);
    settle();
    clear_and_check();

    // ================= R2 : the gate ======================================
    // A middle beat with a clear strobe and last_i low must produce nothing.
    set_phase("R2 middle beat with strb_i=0 and last_i low produces no output");
    bfm_send(beat_pat(72, 0), 1'b1, 1'b0, 1'b1, 4'hF, 4'hF);
    bfm_send(beat_pat(72, 1), 1'b0, 1'b0, 1'b1, 4'hF, 4'h5);
    bfm_send(beat_pat(72, 2), 1'b0, 1'b0, 1'b1, 4'h0, 4'h0);   // swallowed
    settle();
    clear_and_check();

    // ================= back-pressure while realigning =====================
    set_phase("realignment with the sink stalled at the start of the line");
    @(negedge clk); bfm_ready(1'b0);
    send_line(4'b0111, 104, 4);
    repeat (20) @(posedge clk);        // L1: taking the first beat here is optional
    @(negedge clk); bfm_ready(1'b1);
    settle();

    set_phase("realignment with pop_ready_i toggling every cycle");
    send_line(4'b0011, 136, 5);
    for (int t = 0; t < 26; t++) begin
      @(negedge clk);
      bfm_ready(t[0]);
    end
    @(negedge clk); bfm_ready(1'b1);
    settle();

    // ================= X2 : clear =========================================
    set_phase("X2 clear_i drops the retained beat and the line in progress");
    bfm_send(beat_pat(168, 0), 1'b1, 1'b0, 1'b1, 4'b0011, 4'hF);  // first beat only
    settle();                                                     // nothing due
    clear_and_check();
    send_line(4'hF, 200, 2);
    settle();

    // ================= X1 : reset mid-flight ==============================
    set_phase("X1 reset with a line in progress, then a fresh line");
    bfm_send(beat_pat(24, 0), 1'b1, 1'b0, 1'b1, 4'b0001, 4'hF);
    settle();
    bfm_reset(4);
    send_line(4'b0111, 56, 3);
    settle();

    // ================= P1 again, after realignment ========================
    clear_and_check();
    set_phase("P1 pass-through after realignment");
    @(negedge clk); p1_en = 1'b1;
    bfm_send(32'h13579BDF, 1'b0, 1'b0, 1'b0, 4'h6, 4'h3);
    bfm_send(32'h2468ACE0, 1'b0, 1'b1, 1'b0, 4'h0, 4'hC);
    settle();
    @(negedge clk); p1_en = 1'b0;

    if (!verdict_done) begin
      $display("checked %0d output beats across %0d phases", exp_popped, phase_cnt);
      $display("RESULT: PASS");
    end
    $finish;
  end

endmodule