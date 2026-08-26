// ===========================================================================
// stream_realign_tb -- specification-driven testbench for stream_realign
//
// Verdict: one "RESULT: PASS" or "RESULT: FAIL" line, then $finish.
//
// Checking strategy
// -----------------
//   * Every input handshake and every output handshake is recorded at the
//     rising edge (H1).  A reference model then derives, from the recorded
//     input beats alone, the exact sequence of output beats the contract owes
//     (R1, R2, R4, R5, R6, P1) and compares it against what was observed.
//   * Latitude is never required in either direction:
//       L1  - acceptance is never required while pop_ready_i is low.
//       L2  - pop_data_o / pop_strb_o are only ever sampled on a handshake.
//       L3  - pop_strb_o is never compared while realign_i is low.
//       L4  - the retained beat is modelled as a SET of candidates; after a
//             silently consumed beat both readings are accepted.  Only the
//             output COUNT is held to R2's "if and only if".
// ===========================================================================
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
// END OF PROVIDED PLUMBING -- everything below is checking.
// ---------------------------------------------------------------------------

  // ---- recorded traffic ----------------------------------------------------
  typedef struct packed {
    logic [31:0] data;      // push_data_i
    logic [3:0]  dstrb;     // push_strb_i  (recorded, never required)
    logic [3:0]  lstrb;     // strb_i
    logic        is_first;
    logic        is_last;
    logic        rlgn;
  } in_rec_t;

  typedef struct packed {
    logic [31:0] data;
    logic [3:0]  sstrb;
  } out_rec_t;

  in_rec_t  in_q  [$];
  out_rec_t out_q [$];

  // ---- error accounting ----------------------------------------------------
  // err_mon is written only by the concurrent monitor block; err_chk only by
  // the stimulus/checking initial block.  Single writer each.
  int err_mon = 0;
  int err_chk = 0;

  bit pt_en     = 1'b0;   // transparent-mode concurrent checks armed
  bit seen_edge = 1'b0;   // at least one rising edge has happened (X1 caveat)
  int live_cnt  = 0;      // X3 stall counter

  // candidate retained values (L4: a silently consumed beat may or may not
  // replace the retained beat, so the model tracks every possibility)
  logic [31:0] cand [0:15];
  int          ncand = 0;

  task automatic mon_err(input string clause, input string msg);
    err_mon++;
    if (err_mon <= 30) $display("[%0t] VIOLATION (%s): %s", $time, clause, msg);
  endtask

  task automatic chk_err(input string clause, input string msg);
    err_chk++;
    if (err_chk <= 30) $display("[%0t] VIOLATION (%s): %s", $time, clause, msg);
  endtask

  task automatic push_in(input logic [31:0] d, input logic [3:0] ds,
                         input logic [3:0] ls, input bit f, input bit l,
                         input bit rl);
    in_rec_t ir;
    ir.data = d; ir.dstrb = ds; ir.lstrb = ls;
    ir.is_first = f; ir.is_last = l; ir.rlgn = rl;
    in_q.push_back(ir);
  endtask

  task automatic push_out(input logic [31:0] d, input logic [3:0] s);
    out_rec_t orc;
    orc.data = d; orc.sstrb = s;
    out_q.push_back(orc);
  endtask

  // R2's join, with the "a shift of 32 or more yields zero" rule made explicit
  // and the two extremes (R=0 -> current beat, R=4 -> retained beat) falling
  // out of it rather than being special-cased.
  function automatic logic [31:0] mix_beats(input logic [31:0] cur,
                                            input logic [31:0] ret,
                                            input int r);
    logic [31:0] hi;
    logic [31:0] lo;
    hi = (r >= 4) ? 32'h0000_0000 : (cur << (8*r));
    lo = (r <= 0) ? 32'h0000_0000 : (ret >> (8*(4-r)));
    return hi | lo;
  endfunction

  function automatic int popc4(input logic [3:0] s);
    return int'(s[0]) + int'(s[1]) + int'(s[2]) + int'(s[3]);
  endfunction

  // -------------------------------------------------------------------------
  // Concurrent monitor: records handshakes, plus X1 / P1-handshake / X3.
  // -------------------------------------------------------------------------
  always @(posedge clk) begin
    seen_edge <= 1'b1;

    // ---- H1: record moves ----
    if (rst_n && !clr && pvalid && pready)
      push_in(pdata, pstrb, strb, fst, lst, ra);
    if (rst_n && !clr && qvalid && qready)
      push_out(qdata, qstrb);

    // ---- X1: with the inputs quiet, reset originates nothing.
    // Skipped at the very first rising edge, where registers hold no defined
    // value; and only ever evaluated with push_valid_i low, so a purely
    // combinational input-to-output path is not being blamed on reset.
    if (seen_edge && !rst_n && !pvalid && qvalid)
      mon_err("X1", "pop_valid_o asserted while rst_ni is low and nothing is offered");

    // ---- P1: with realign_i low the two handshakes are the same handshake.
    // pop_strb_o is deliberately NOT examined here (L3).
    if (rst_n && !clr && pt_en && !ra) begin
      if (qvalid !== pvalid)
        mon_err("P1", $sformatf("pop_valid_o=%b does not follow push_valid_i=%b with realign_i low",
                                qvalid, pvalid));
      if (pvalid && (pready !== qready))
        mon_err("P1", $sformatf("push_ready_o=%b does not follow pop_ready_i=%b with realign_i low",
                                pready, qready));
      if (pvalid && qvalid && qready && (qdata !== pdata))
        mon_err("P1", $sformatf("pop_data_o=%08h != push_data_i=%08h with realign_i low",
                                qdata, pdata));
    end

    // ---- X3: with pop_ready_i high, an offered beat is accepted within 16
    // cycles.  The counter is cleared whenever the sink is not ready, so no
    // acceptance is ever demanded under backpressure (L1).
    if (!rst_n || clr || !pvalid || !qready) live_cnt <= 0;
    else if (pready)                        live_cnt <= 0;
    else begin
      live_cnt <= live_cnt + 1;
      if (live_cnt == 16)
        mon_err("X3", "offered beat not accepted within 16 cycles with pop_ready_i held high");
    end
  end

  // -------------------------------------------------------------------------
  // Reference model / scoreboard, run once at the end.
  // -------------------------------------------------------------------------
  task automatic verify();
    in_rec_t  b;
    out_rec_t o;
    int oi;
    int r;
    int k;
    bit in_line;
    bit ok;
    bit ran_dry;
    logic [31:0] exp0;

    oi = 0; r = 0; in_line = 1'b0; ncand = 0; ran_dry = 1'b0;

    for (int i = 0; i < in_q.size(); i++) begin
      b = in_q[i];

      if (!b.rlgn) begin
        // ---- P1: transparent on the data path, one output per input beat.
        // pop_strb_o is not examined (P2 / L3).
        if (oi >= out_q.size()) begin
          chk_err("P1", $sformatf("input beat %0d (realign_i low) produced no output beat", i));
          ran_dry = 1'b1;
          break;
        end
        o = out_q[oi];
        if (o.data !== b.data)
          chk_err("P1", $sformatf("beat %0d: pop_data_o=%08h, expected push_data_i=%08h",
                                  i, o.data, b.data));
        oi++;
        in_line = 1'b0; ncand = 0;

      end else if (b.is_first) begin
        // ---- R1: no output beat; consumed and retained.  R4: rotation fixed
        // here for the whole line, and NOT taken modulo the beat width.
        r = popc4(b.lstrb);
        ncand = 1; cand[0] = b.data;
        in_line = 1'b1;

      end else if (!in_line) begin
        // No first beat of a line has arrived: the contract places no
        // requirement here, so nothing is checked.

      end else if (b.is_last || (b.lstrb != 4'h0)) begin
        // ---- R2 / R6: an output beat is owed.
        if (oi >= out_q.size()) begin
          chk_err("R2/R6", $sformatf("input beat %0d owed an output beat (last_i=%b strb_i=%h), none produced",
                                     i, b.is_last, b.lstrb));
          ran_dry = 1'b1;
          break;
        end
        o = out_q[oi];
        ok = 1'b0;
        for (k = 0; k < ncand; k++)
          if (o.data === mix_beats(b.data, cand[k], r)) ok = 1'b1;
        if (!ok) begin
          exp0 = mix_beats(b.data, cand[0], r);
          chk_err("R2/R4/R5", $sformatf("beat %0d (R=%0d): pop_data_o=%08h, expected %08h from current=%08h retained=%08h%s",
                                        i, r, o.data, exp0, b.data, cand[0],
                                        (ncand > 1) ? " (either L4 reading accepted)" : ""));
        end
        // ---- R3: all ones on every output beat produced while realigning,
        // whatever push_strb_i carried.
        if (o.sstrb !== 4'hF)
          chk_err("R3", $sformatf("beat %0d: pop_strb_o=%h while realigning, must be 4'hF (push_strb_i was %h)",
                                  i, o.sstrb, b.dstrb));
        oi++;
        ncand = 1; cand[0] = b.data;
        if (b.is_last) in_line = 1'b0;

      end else begin
        // ---- R2: silently consumed (after the first, strb_i clear, last_i
        // low).  No output is owed.  L4: whether it replaces the retained beat
        // is free, so both possibilities are carried forward.
        if (ncand < 16) begin cand[ncand] = b.data; ncand++; end
      end
    end

    if (!ran_dry && (oi != out_q.size()))
      chk_err("R1/R2", $sformatf("%0d output beats observed, exactly %0d owed (R2 is an if-and-only-if)",
                                 out_q.size(), oi));
  endtask

  // -------------------------------------------------------------------------
  // Stimulus
  // -------------------------------------------------------------------------
  initial begin
    bfm_ready(1'b1);
    bfm_reset(5);
    repeat (4) @(posedge clk);

    // === R = 4 : fully set strobe is NOT modulo 4 -- the stream is delayed by
    // === a whole beat.  push_strb_i is driven partial and clear throughout to
    // === confirm it neither gates anything (R2) nor reaches the output (R3).
    bfm_send(32'h0001_0203, 1'b1, 1'b0, 1'b1, 4'hF, 4'hF);
    bfm_send(32'h0405_0607, 1'b0, 1'b0, 1'b1, 4'hF, 4'h5);
    bfm_send(32'h0809_0A0B, 1'b0, 1'b0, 1'b1, 4'hF, 4'h0);
    bfm_send(32'h0C0D_0E0F, 1'b0, 1'b1, 1'b1, 4'hF, 4'h9);
    bfm_idle();

    // === R = 2, with strb_i varying after the first beat (R4) and a final
    // === beat whose strb_i is entirely clear (R6).
    bfm_clear();
    bfm_send(32'hA0A1_A2A3, 1'b1, 1'b0, 1'b1, 4'h3, 4'h5);
    bfm_send(32'hB0B1_B2B3, 1'b0, 1'b0, 1'b1, 4'hF, 4'h5);
    bfm_send(32'hC0C1_C2C3, 1'b0, 1'b0, 1'b1, 4'h1, 4'hF);
    bfm_send(32'hD0D1_D2D3, 1'b0, 1'b1, 1'b1, 4'h0, 4'h5);
    bfm_idle();

    // === R = 0 : the first beat is skipped entirely and each output beat is
    // === the current input beat.
    bfm_clear();
    bfm_send(32'h1111_2222, 1'b1, 1'b0, 1'b1, 4'h0, 4'hF);
    bfm_send(32'h3333_4444, 1'b0, 1'b0, 1'b1, 4'hF, 4'h3);
    bfm_send(32'h5555_6666, 1'b0, 1'b0, 1'b1, 4'h7, 4'hF);
    bfm_send(32'h7777_8888, 1'b0, 1'b1, 1'b1, 4'h0, 4'hA);
    bfm_idle();

    // === R = 1, including a silently consumed beat (R2 owes no output for it;
    // === L4 leaves the retained beat free) followed by a normal beat and a
    // === last beat with a clear strobe.
    bfm_clear();
    bfm_send(32'h1122_3344, 1'b1, 1'b0, 1'b1, 4'h1, 4'hF);
    bfm_send(32'h5566_7788, 1'b0, 1'b0, 1'b1, 4'hF, 4'h3);
    bfm_send(32'h99AA_BBCC, 1'b0, 1'b0, 1'b1, 4'h0, 4'hF);  // silently consumed
    bfm_send(32'hDDEE_FF00, 1'b0, 1'b0, 1'b1, 4'h8, 4'hF);
    bfm_send(32'h1357_9BDF, 1'b0, 1'b1, 1'b1, 4'h0, 4'hF);
    bfm_idle();

    // === R = 3 across output backpressure: nothing may be lost, duplicated or
    // === reordered (R5).  No acceptance is required while the sink is not
    // === ready (L1).
    bfm_clear();
    bfm_send(32'hFEDC_BA98, 1'b1, 1'b0, 1'b1, 4'h7, 4'hF);
    bfm_send(32'h7654_3210, 1'b0, 1'b0, 1'b1, 4'hF, 4'hF);
    bfm_send(32'h0F1E_2D3C, 1'b0, 1'b0, 1'b1, 4'hF, 4'hA);
    bfm_send(32'h4B5A_6978, 1'b0, 1'b1, 1'b1, 4'hF, 4'hF);
    @(negedge clk); bfm_ready(1'b0);
    repeat (6) @(posedge clk);
    @(negedge clk); bfm_ready(1'b1);
    bfm_idle();

    // === Transparent mode (P1).  The output strobe is never compared here (L3)
    // === and push_strb_i is driven partial and clear to make that explicit.
    bfm_clear();
    pt_en = 1'b1;
    bfm_send(32'hCAFE_0001, 1'b0, 1'b0, 1'b0, 4'hF, 4'h5);
    bfm_send(32'hCAFE_0002, 1'b0, 1'b0, 1'b0, 4'h3, 4'h0);
    bfm_send(32'hCAFE_0003, 1'b0, 1'b0, 1'b0, 4'h0, 4'hF);
    bfm_send(32'hCAFE_0004, 1'b1, 1'b1, 1'b0, 4'hF, 4'hA);
    bfm_idle();

    // Transparent mode under backpressure: push_ready_o follows pop_ready_i.
    bfm_send(32'hBEEF_0001, 1'b0, 1'b0, 1'b0, 4'hF, 4'hF);
    bfm_send(32'hBEEF_0002, 1'b0, 1'b0, 1'b0, 4'hF, 4'h6);
    @(negedge clk); bfm_ready(1'b0);
    repeat (5) @(posedge clk);
    @(negedge clk); bfm_ready(1'b1);
    bfm_idle();
    pt_en = 1'b0;

    // === X1: asynchronous reset part-way through, then a fresh line.
    bfm_clear();
    bfm_send(32'hAAAA_0001, 1'b1, 1'b0, 1'b1, 4'h3, 4'hF);
    bfm_send(32'hAAAA_0002, 1'b0, 1'b0, 1'b1, 4'hF, 4'hF);
    bfm_idle();
    bfm_reset(3);
    repeat (3) @(posedge clk);
    bfm_send(32'h1234_5678, 1'b1, 1'b0, 1'b1, 4'h1, 4'hF);
    bfm_send(32'h9ABC_DEF0, 1'b0, 1'b1, 1'b1, 4'hF, 4'h5);
    bfm_idle();

    // === X2: clear_i abandons a line in progress; the next line must stand
    // === on its own and produce no extra beat.
    bfm_send(32'h5A5A_0001, 1'b1, 1'b0, 1'b1, 4'hF, 4'hF);
    bfm_idle();
    bfm_clear();
    bfm_send(32'h6B6B_0001, 1'b1, 1'b0, 1'b1, 4'h3, 4'hF);
    bfm_send(32'h6B6B_0002, 1'b0, 1'b1, 1'b1, 4'hF, 4'hF);
    bfm_idle();

    // === Verdict ===
    repeat (10) @(posedge clk);
    verify();

    $display("[%0t] summary: %0d input beats accepted, %0d output beats observed, %0d violations",
             $time, in_q.size(), out_q.size(), err_mon + err_chk);
    if ((err_mon + err_chk) == 0) $display("RESULT: PASS");
    else                          $display("RESULT: FAIL");
    $finish;
  end

endmodule