// =============================================================================
// stream_realign_tb -- specification-driven testbench
//
// Checking strategy
//   * Transaction scoreboard. Every accepted input beat is run through a model
//     of the spec at the rising edge it moves (H1); every beat the model owes
//     (P1, R2, R6) is queued in order and consumed by the next output
//     handshake. Nothing is matched by value; order is the only key.
//   * Latitude is modelled, not ignored:
//       L1  first-beat acceptance under a stalled sink is never checked;
//       L2  payload is only read on an output handshake;
//       L3  pop_strb_o is only checked on realigned beats (R3);
//       L4  after a silently consumed beat the model keeps BOTH candidate
//           retained beats and accepts either join for the next output.
//   * Cycle-level checks only where the spec is cycle-level: P1 (the two
//     handshakes are one handshake), X1 (reset with inputs quiet) and X3
//     (liveness bound with the sink held ready).
// =============================================================================
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
// END OF PROVIDED PLUMBING
// ---------------------------------------------------------------------------

  // ===========================================================================
  // Verdict bookkeeping
  // ===========================================================================
  int  n_err        = 0;
  bit  verdict_done = 1'b0;
  int  n_out_pt     = 0;   // pass-through beats checked
  int  n_out_ra     = 0;   // realigned beats checked
  int  n_amb_seen   = 0;   // realigned beats joined after a silent beat
  int  n_silent     = 0;   // silently consumed beats
  int  n_zero_last  = 0;   // R6 beats (last with strb_i clear) checked

  task automatic report(input string clause, input string msg);
    n_err++;
    if (n_err <= 12)
      $display("ERROR [%s] cycle %0d: %s", clause, bfm_cycle, msg);
    else if (n_err == 13)
      $display("ERROR ... further errors suppressed");
  endtask

  task automatic finish_verdict();
    if (verdict_done) return;
    verdict_done = 1'b1;
    $display("summary: pass-through beats %0d, realigned beats %0d (%0d after a silent beat), silent beats %0d, R6 beats %0d, errors %0d",
             n_out_pt, n_out_ra, n_amb_seen, n_silent, n_zero_last, n_err);
    if (n_err == 0) $display("RESULT: PASS");
    else            $display("RESULT: FAIL");
    $finish;
  endtask

  // ===========================================================================
  // Spec model
  // ===========================================================================
  function automatic int popc(input logic [3:0] s);
    return int'(s[0]) + int'(s[1]) + int'(s[2]) + int'(s[3]);
  endfunction

  // R2: (cur << 8R) | (retained >> 8(4-R)), a shift of 32 or more yields zero
  function automatic logic [31:0] join_beats(input logic [31:0] cur,
                                             input logic [31:0] ret, input int r);
    logic [63:0] a;
    logic [63:0] b;
    a = {32'd0, cur} << (8 * r);
    b = {32'd0, ret} >> (8 * (4 - r));
    return a[31:0] | b[31:0];
  endfunction

  typedef struct {
    bit          is_ra;       // produced while realigning
    logic [31:0] exp_a;       // retained = most recent consumed beat
    logic [31:0] exp_b;       // retained = most recent beat that produced/was first (L4)
    bit          amb;         // a silent beat preceded this one in the line
    logic [31:0] cur;
    logic [31:0] ret_a;
    int          rot;
    logic [3:0]  lstrb;
    bit          zero_last;   // last_i with strb_i clear -- owed only by R6
    int          line_no;
    int          beat_no;
  } exp_t;

  exp_t        sb [$];
  bit          m_in_line = 1'b0;
  int          m_rot     = 0;
  logic [31:0] m_ret_a   = '0;
  logic [31:0] m_ret_b   = '0;
  bit          m_amb     = 1'b0;
  int          m_line    = 0;
  int          m_beat    = 0;
  int          m_edges   = 0;
  int          x3_wait   = 0;

  function automatic string ra_hint(input exp_t e, input logic [31:0] got);
    string h;
    h = "";
    if (e.rot == 4 && got === join_beats(e.cur, e.ret_a, 0))
      h = " -- matches R=0: the rotation was taken modulo 4 (R: a full strobe is R=4)";
    else if (popc(e.lstrb) != e.rot && got === join_beats(e.cur, e.ret_a, popc(e.lstrb)))
      h = " -- matches the rotation of THIS beat's strb_i (R4: R is fixed at the first beat)";
    else if (got === ((e.cur >> (8 * e.rot)) | (e.rot == 0 ? 32'd0 : (e.ret_a << (8 * (4 - e.rot))))))
      h = " -- matches the join with the shift directions swapped (R2)";
    else if (got === e.cur)
      h = " -- equals the current beat unrotated (R2)";
    else if (got === e.ret_a)
      h = " -- equals the retained beat unrotated (R2)";
    else if (sb.size() > 0 && sb[0].is_ra && got === sb[0].exp_a)
      h = " -- matches the NEXT owed beat: this owed beat was never produced (R2/R6)";
    if (e.zero_last) h = {h, " [owed beat was last_i with strb_i clear: R6]"};
    return h;
  endfunction

  // ===========================================================================
  // The checker -- everything sampled at the rising edge, pre-update values
  // ===========================================================================
  always @(posedge clk) begin
    automatic exp_t        e;
    automatic exp_t        ne;
    automatic int          nra;
    automatic logic [31:0] got;
    automatic bit          ok;

    m_edges++;

    if (!rst_n) begin
      // X1: from the first rising edge onward, with inputs quiet, nothing completes
      if (m_edges > 1 && !pvalid && qvalid === 1'b1)
        report("X1", "pop_valid_o high while rst_ni is low and the inputs are quiet");
      sb.delete();
      m_in_line = 1'b0;
      m_amb     = 1'b0;
      x3_wait   = 0;
    end else if (clr) begin
      // X2: clear returns the unit to its starting condition
      if (!pvalid && qvalid === 1'b1 && qready === 1'b1)
        report("X2", "an output beat completed during clear_i with the inputs quiet");
      sb.delete();
      m_in_line = 1'b0;
      m_amb     = 1'b0;
      x3_wait   = 0;
    end else begin
      nra = 0;
      foreach (sb[i]) if (sb[i].is_ra) nra++;

      // ---- P1: with realign_i low the two handshakes are the same handshake
      if (!ra && nra == 0) begin
        if (pvalid && qvalid !== 1'b1)
          report("P1", "realign_i low: push_valid_i high but pop_valid_o low");
        if (pvalid && pready !== qready)
          report("P1", $sformatf("realign_i low: push_ready_o=%b does not follow pop_ready_i=%b", pready, qready));
        if (!pvalid && qvalid === 1'b1)
          report("P1", "realign_i low: pop_valid_o high with nothing offered");
        if (pvalid && qvalid === 1'b1 && qdata !== pdata)
          report("P1", $sformatf("realign_i low: pop_data_o %08h != push_data_i %08h", qdata, pdata));
      end

      // ---- X3: with pop_ready_i held high, an offered beat is taken within 16 cycles
      if (pvalid && pready !== 1'b1 && qready) begin
        x3_wait++;
        if (x3_wait > 16) begin
          report("X3", "beat offered with pop_ready_i high was not accepted within 16 cycles");
          finish_verdict();
        end
      end else begin
        x3_wait = 0;
      end

      // ---- input handshake: run the model
      if (pvalid && pready === 1'b1) begin
        if (!ra) begin
          ne         = '{default: '0};
          ne.is_ra   = 1'b0;
          ne.exp_a   = pdata;
          ne.exp_b   = pdata;
          ne.line_no = -1;
          sb.push_back(ne);
        end else if (fst) begin                          // R1, R4
          m_in_line = 1'b1;
          m_rot     = popc(strb);
          m_ret_a   = pdata;
          m_ret_b   = pdata;
          m_amb     = 1'b0;
          m_line++;
          m_beat    = 0;
        end else if (m_in_line) begin
          m_beat++;
          if (lst || strb != 4'd0) begin                 // R2 / R6: an output is owed
            ne           = '{default: '0};
            ne.is_ra     = 1'b1;
            ne.exp_a     = join_beats(pdata, m_ret_a, m_rot);
            ne.exp_b     = join_beats(pdata, m_ret_b, m_rot);
            ne.amb       = m_amb;
            ne.cur       = pdata;
            ne.ret_a     = m_ret_a;
            ne.rot       = m_rot;
            ne.lstrb     = strb;
            ne.zero_last = lst && strb == 4'd0;
            ne.line_no   = m_line;
            ne.beat_no   = m_beat;
            sb.push_back(ne);
            m_ret_a = pdata;
            m_ret_b = pdata;
            m_amb   = 1'b0;
            if (lst) m_in_line = 1'b0;
          end else begin                                 // silently consumed (L4)
            m_ret_a = pdata;
            m_amb   = 1'b1;
            n_silent++;
          end
        end
        // a realign beat with no line in progress is never sent by this bench
      end

      // ---- output handshake: consume the oldest owed beat
      if (qvalid === 1'b1 && qready) begin
        got = qdata;
        if (sb.size() == 0) begin
          if (ra) report("R1/R2", $sformatf("output beat %08h produced where none is owed (first beat or silently consumed beat)", got));
          else    report("P1",    $sformatf("output beat %08h produced with no input beat to pass through", got));
        end else begin
          e = sb.pop_front();
          if (e.is_ra) begin
            n_out_ra++;
            if (e.amb) n_amb_seen++;
            if (e.zero_last) n_zero_last++;
            if (qstrb !== 4'hF)
              report("R3", $sformatf("pop_strb_o=%04b on a realigned beat (line %0d beat %0d); must be all ones",
                                     qstrb, e.line_no, e.beat_no));
            ok = (got === e.exp_a) || (e.amb && got === e.exp_b);
            if (!ok)
              report(e.amb ? "R2/L4" : "R2/R5",
                     $sformatf("line %0d beat %0d, R=%0d: got %08h, expected %08h%s (cur %08h, retained %08h)%s",
                               e.line_no, e.beat_no, e.rot, got, e.exp_a,
                               e.amb ? $sformatf(" or %08h", e.exp_b) : "",
                               e.cur, e.ret_a, ra_hint(e, got)));
          end else begin
            n_out_pt++;
            if (got !== e.exp_a)
              report("P1", $sformatf("pass-through: got %08h, expected %08h", got, e.exp_a));
          end
        end
      end
    end
  end

  // ===========================================================================
  // Stimulus helpers
  // ===========================================================================
  bit ready_rand = 1'b0;
  int ready_pct  = 70;
  always @(negedge clk) if (ready_rand) qready = ($urandom_range(0, 99) < ready_pct);

  task automatic sink_fixed(input bit v);
    @(negedge clk);
    ready_rand = 1'b0;
    qready     = v;
  endtask

  task automatic sink_random(input int pct);
    @(negedge clk);
    ready_pct  = pct;
    ready_rand = 1'b1;
  endtask

  // Byte-stream data: consecutive byte indices make R5 visible in any dump.
  int byte_ctr = 0;
  function automatic logic [31:0] next_word();
    logic [31:0] w;
    for (int i = 0; i < 4; i++) w[8*i +: 8] = 8'(byte_ctr + i);
    byte_ctr += 4;
    return w;
  endfunction

  // Drain: sink ready, wait for every queued beat to move, then everything owed
  // must have appeared.
  task automatic drain(input string tag);
    sink_fixed(1'b1);
    bfm_idle(40000);
    if (bfm_q.size() != 0 || pvalid)
      report("X3", {tag, ": input beats still pending after drain with pop_ready_i high"});
    if (sb.size() != 0) begin
      report(sb[0].zero_last ? "R6" : (sb[0].is_ra ? "R2" : "P1"),
             $sformatf("%s: %0d owed output beat(s) never produced (oldest: line %0d beat %0d, last&&strb_i==0: %0b)",
                       tag, sb.size(), sb[0].line_no, sb[0].beat_no, sb[0].zero_last));
      @(negedge clk);
      sb.delete();
    end
  endtask

  // One realigned line: first beat + n_mid middle beats + a last beat.
  task automatic send_line(input logic [3:0] first_strb, input int n_mid,
                           input int silent_pct, input bit zero_last_strb,
                           input bit rand_dstrb);
    logic [3:0] s;
    logic [3:0] d;
    d = rand_dstrb ? 4'($urandom) : ~first_strb;          // push_strb_i must not matter
    bfm_send(next_word(), 1'b1, 1'b0, 1'b1, first_strb, d);
    for (int i = 0; i < n_mid; i++) begin
      if ($urandom_range(0, 99) < silent_pct) s = 4'd0;
      else begin
        s = 4'($urandom_range(1, 15));
        if (popc(s) == popc(first_strb)) s = (s == 4'hF) ? 4'h1 : 4'hF;   // R4: differ from the line's rotation
      end
      d = rand_dstrb ? 4'($urandom) : (s == 4'd0 ? 4'hF : 4'h0);         // push_strb_i opposite to strb_i
      bfm_send(next_word(), 1'b0, 1'b0, 1'b1, s, d);
    end
    s = zero_last_strb ? 4'd0 : 4'($urandom_range(1, 15));
    d = rand_dstrb ? 4'($urandom) : 4'h5;
    bfm_send(next_word(), 1'b0, 1'b1, 1'b1, s, d);
  endtask

  task automatic send_passthrough(input int n);
    for (int i = 0; i < n; i++)
      bfm_send(next_word(), 1'b0, 1'($urandom), 1'b0, 4'($urandom), 4'($urandom));
  endtask

  // ===========================================================================
  // Test sequence
  // ===========================================================================
  initial begin
    bfm_reset(5);
    repeat (3) @(posedge clk);

    // ---- 1. pass-through, sink open then stalling (P1, L3 not checked)
    sink_fixed(1'b1);
    send_passthrough(12);
    drain("pass-through open");
    sink_random(50);
    send_passthrough(40);
    drain("pass-through stalled");

    // ---- 2. every first-beat strobe, no silent beats (R, R2, R3, R4, R5)
    sink_fixed(1'b1);
    for (int s = 0; s < 16; s++) send_line(4'(s), 3, 0, 1'b0, 1'b0);
    drain("rotation sweep, open");
    sink_random(60);
    for (int s = 0; s < 16; s++) send_line(4'(s), 4, 0, 1'b0, 1'b1);
    drain("rotation sweep, stalled");

    // ---- 3. last beat with strb_i clear (R6)
    sink_fixed(1'b1);
    for (int s = 0; s < 16; s++) send_line(4'(s), 1, 0, 1'b1, 1'b0);
    for (int s = 0; s < 16; s++) send_line(4'(s), 0, 0, 1'b1, 1'b1);
    drain("R6");

    // ---- 4. silently consumed beats (R2 "only if", L4)
    sink_random(70);
    for (int s = 0; s < 16; s++) send_line(4'(s), 5, 50, 1'b0, 1'b0);
    for (int s = 0; s < 16; s++) send_line(4'(s), 3, 100, 1'b1, 1'b1);
    drain("silent beats");

    // ---- 5. modes interleaved line by line
    sink_random(60);
    for (int i = 0; i < 40; i++) begin
      send_passthrough($urandom_range(1, 3));
      send_line(4'($urandom), $urandom_range(0, 4), 20, 1'($urandom), 1'b1);
    end
    drain("interleaved");

    // ---- 6. clear mid-line, then a fresh line (X2)
    sink_fixed(1'b1);
    bfm_send(next_word(), 1'b1, 1'b0, 1'b1, 4'b0110, 4'hF);
    bfm_send(next_word(), 1'b0, 1'b0, 1'b1, 4'b0001, 4'hF);
    bfm_idle(200);
    bfm_clear();
    repeat (4) @(posedge clk);
    for (int s = 0; s < 16; s += 5) send_line(4'(s), 2, 0, 1'b0, 1'b1);
    drain("after clear");

    // ---- 7. reset asserted mid-offer with the sink stalled (X1)
    sink_fixed(1'b0);
    send_line(4'b1011, 3, 0, 1'b0, 1'b1);
    repeat (12) @(posedge clk);
    fork
      bfm_reset(6);
      begin
        repeat (3) @(posedge clk);       // driver has dropped push_valid_i by now
        bfm_q.delete();
      end
    join
    repeat (4) @(posedge clk);
    sink_fixed(1'b1);
    repeat (8) @(posedge clk);           // nothing may be delivered: no stale word
    for (int s = 0; s < 16; s += 3) send_line(4'(s), 3, 0, 1'b0, 1'b1);
    drain("after reset");

    // ---- 8. long random run
    for (int blk = 0; blk < 6; blk++) begin
      sink_random(blk == 0 ? 100 : 40 + 10 * blk);
      for (int i = 0; i < 200; i++) begin
        if ($urandom_range(0, 3) == 0) send_passthrough($urandom_range(1, 4));
        else send_line(($urandom_range(0, 3) == 0) ? 4'hF : 4'($urandom),
                       $urandom_range(0, 6), $urandom_range(0, 40), 1'($urandom), 1'b1);
      end
      drain("random");
    end

    // ---- non-vacuity: the checks above must actually have run
    if (n_out_ra < 500 || n_out_pt < 100 || n_amb_seen < 20 || n_zero_last < 20)
      report("coverage", "too few beats were checked for the verdict to mean anything");

    finish_verdict();
  end

endmodule