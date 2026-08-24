// =============================================================================
// axis_switch_oq_tb.sv  --  SCORING TESTBENCH for d_nw03. Never shipped.
// =============================================================================
// Checks spec/axis_switch_oq_iface.sv.
//
// DRIVER DISCIPLINE, carried from d_ca01 where four separate harness defects
// each produced the same observable -- a working design that appears to stop
// responding:
//   - every DUT input is driven from a REGISTER or a constant; no combinational
//     path from a DUT output back to a DUT input;
//   - transfers are observed by MONOTONIC COUNTERS, never by a level flag that
//     is stale for a cycle afterwards;
//   - the input generators are clocked FSMs, not reactive processes. That also
//     matters for C1: a rate check is only as sharp as the load the harness can
//     offer, and a task-based driver cannot saturate.
//
// ORACLE. Frame content is a pure function of (src, seq, beat) evaluated
// identically by the generator and the scoreboard, so there is no modelled
// state to get wrong. Frame LENGTH is a pure function of (src, dest, seq).
//
// COVERAGE FLOORS MEASURE STIMULUS. Every floor counts something this harness
// chose to drive. Which input wins an output is a design choice (L1) and is a
// METRIC, never a floor.
// =============================================================================
`include "liveness_monitor.svh"

module axis_switch_oq_tb #(
  parameter int unsigned S_COUNT = 4,
  parameter int unsigned M_COUNT = 4,
  parameter int unsigned DATA_W  = 32,
  parameter int unsigned SEED    = 1
);
  // plusarg-guarded stimulus-variation dump; a normal run is unaffected
  initial if ($test$plusargs("vcd")) begin
    $dumpfile("dump.vcd");
    $dumpvars(0, axis_switch_oq_tb);
  end


  localparam int unsigned KEEP_W  = DATA_W/8;
  localparam int unsigned DEST_W  = $clog2(M_COUNT);
  localparam int unsigned MAXBEAT = 8;   // spec R6 -- the bound is exercised, not just stated

  // Watchdog. The soak drives 400 frames per input at up to 6 beats; a correct
  // design finishes well inside 100k cycles. 1 000 000 is ~10x the worst
  // plausible correct design -- sized to turn a hang into a verdict, never to
  // measure speed. C3's monitor is what judges progress and its limits are
  // deliberately loose for the same reason.
  localparam int unsigned WATCHDOG_CYCLES = 1_000_000;

  int    errors, checks, phase;
  string fail_reason;

  task automatic note_fail(input string msg);
    errors++;
    if (fail_reason == "") fail_reason = msg;
    $display("[FAIL] phase %0d: %s", phase, msg);
  endtask
  task automatic chk(input logic cond, input string msg);
    checks++;
    if (!cond) note_fail(msg);
  endtask

  `LM_DECLARE(S_COUNT)

  logic clk, rst_n;
  initial begin clk = 1'b0; forever #5 clk = ~clk; end

  // ---------------------------------------------------------------- DUT
  logic [S_COUNT-1:0]            s_valid, s_ready, s_last;
  logic [S_COUNT*DATA_W-1:0]     s_data;
  logic [S_COUNT*KEEP_W-1:0]     s_keep;
  logic [S_COUNT*DEST_W-1:0]     s_dest;
  logic [M_COUNT-1:0]            m_valid, m_ready, m_last;
  logic [M_COUNT*DATA_W-1:0]     m_data;
  logic [M_COUNT*KEEP_W-1:0]     m_keep;

  axis_switch_oq #(.S_COUNT(S_COUNT), .M_COUNT(M_COUNT), .DATA_W(DATA_W)) dut (
     .clk_i(clk), .rst_ni(rst_n)
    ,.s_valid_i(s_valid), .s_ready_o(s_ready), .s_data_i(s_data)
    ,.s_keep_i(s_keep), .s_last_i(s_last), .s_dest_i(s_dest)
    ,.m_valid_o(m_valid), .m_ready_i(m_ready), .m_data_o(m_data)
    ,.m_keep_o(m_keep), .m_last_o(m_last)
  );

  // ---------------------------------------------------------------- payload
  // Pure function of (src, seq, beat). Low 8 bits carry src, seq and beat so a
  // narrow configuration still identifies all three; the upper bits are filled
  // so DATA_W=32 exercises the full width -- a generator that leaves the top
  // half zero lets a design that drops it pass, which is a recorded defect.
  function automatic [31:0] pay32(input int unsigned s, input int unsigned sq, input int unsigned bt);
    pay32 = { ~(16'(sq*7 + bt*3 + s)), 8'(sq), 3'(bt), 3'(sq), 2'(s) };
  endfunction
  function automatic [DATA_W-1:0] payload(input int unsigned s, input int unsigned sq, input int unsigned bt);
    payload = DATA_W'(pay32(s, sq, bt));
  endfunction
  function automatic int unsigned nbeats(input int unsigned s, input int unsigned m, input int unsigned sq);
    nbeats = 1 + ((s*7 + m*3 + sq*5) % MAXBEAT);
  endfunction
  // last beat may carry a partial keep; every earlier beat is all-ones
  function automatic [KEEP_W-1:0] keepof(input int unsigned s, input int unsigned sq,
                                         input int unsigned bt, input int unsigned nb);
    if (KEEP_W == 1)            keepof = '1;
    else if (bt != nb-1)        keepof = '1;
    else                        keepof = KEEP_W'((32'h1 << (1 + ((sq + s) % KEEP_W))) - 1);
  endfunction

  // ---------------------------------------------------------------- generators
  // One clocked FSM per input. Registers only -- remedy 1.
  logic              g_en   [S_COUNT];      // may start new frames
  logic [DEST_W-1:0] g_dest [S_COUNT];      // where this input sends
  logic              g_act  [S_COUNT];      // mid-frame
  int unsigned       g_seq  [S_COUNT][M_COUNT];
  int unsigned       g_cur  [S_COUNT];      // seq of the frame in flight
  // The frame's OWN destination, latched at start. Reading g_dest at completion
  // instead attributes the frame to whatever the stimulus last selected, which
  // corrupts every per-(src,dest) count the moment the soak retargets an input
  // mid-frame.
  int unsigned       g_fd   [S_COUNT];
  int unsigned       g_bt   [S_COUNT];
  int unsigned       g_nb   [S_COUNT];
  int unsigned       g_sent [S_COUNT][M_COUNT];   // frames fully accepted
  // Frames STARTED. The routing check must key on this, not on g_sent: L2
  // leaves buffering free, so a cut-through design delivers a frame's first
  // beat before that frame has been fully accepted on the input side. Checking
  // "fully accepted" instead forbids cut-through, which the spec explicitly
  // permits -- an over-constraint the reference itself caught.
  int unsigned       g_started [S_COUNT][M_COUNT];

  logic [S_COUNT-1:0]        sv_r, sl_r;
  logic [S_COUNT*DATA_W-1:0] sd_r;
  logic [S_COUNT*KEEP_W-1:0] sk_r;
  logic [S_COUNT*DEST_W-1:0] sde_r;
  assign s_valid = sv_r; assign s_last = sl_r;
  assign s_data  = sd_r; assign s_keep = sk_r; assign s_dest = sde_r;

  logic [M_COUNT-1:0] mr_r;
  assign m_ready = mr_r;

  int accepts_r, delivers_r, cycle_r;

  // ---------------------------------------------------------------- scoreboard
  int unsigned  exp_seq [S_COUNT][M_COUNT];   // next frame expected at m from s
  logic         o_busy  [M_COUNT];            // mid-frame on this output
  int unsigned  o_src   [M_COUNT];
  int unsigned  o_seq   [M_COUNT];
  int unsigned  o_bt    [M_COUNT];
  int unsigned  o_nb    [M_COUNT];
  int           sb_route_err, sb_data_err, sb_keep_err, sb_atom_err, sb_order_err, sb_len_err;
  int unsigned  dlv_frames [S_COUNT][M_COUNT];
  int           lat_min, lat_max, lat_n;

  // C1 window
  logic         c1_arm;
  int           c1_beats, c1_cycles;

  logic [S_COUNT-1:0] lm_off, lm_srv;

  int cov_frames, cov_multibeat, cov_partial_keep, cov_contend, cov_hol, cov_c1;
  int cov_maxlen;
  logic cov_pair [S_COUNT][M_COUNT];

  integer si, mi, bi;
  int     n_acc, n_dlv, n_maxlen;
  int     maxlen_r;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      sv_r <= '0; sl_r <= '0; sd_r <= '0; sk_r <= '0; sde_r <= '0;
      accepts_r <= 0; delivers_r <= 0; cycle_r <= 0;
      sb_route_err <= 0; sb_data_err <= 0; sb_keep_err <= 0;
      sb_atom_err <= 0; sb_order_err <= 0; sb_len_err <= 0;
      c1_beats <= 0; c1_cycles <= 0; maxlen_r <= 0;
      lat_min <= 1000000; lat_max <= 0; lat_n <= 0;
      for (si = 0; si < int'(S_COUNT); si++) begin
        g_act[si] <= 1'b0; g_bt[si] <= 0; g_nb[si] <= 1; g_cur[si] <= 0; g_fd[si] <= 0;
        for (mi = 0; mi < int'(M_COUNT); mi++) begin
          g_seq[si][mi] <= 0; g_sent[si][mi] <= 0; g_started[si][mi] <= 0;
          exp_seq[si][mi] <= 0; dlv_frames[si][mi] <= 0;
        end
      end
      for (mi = 0; mi < int'(M_COUNT); mi++) begin o_busy[mi] <= 1'b0; o_bt[mi] <= 0; end
    end
    else begin
      // Per-cycle transfer tallies. These MUST be accumulated in blocking
      // temporaries and applied once: `x <= x + 1` inside a port loop is a
      // non-blocking assignment evaluated N times against the SAME old value,
      // so the last iteration wins and the counter caps at ONE PER CYCLE
      // however many ports transferred. That is not a small error -- it made a
      // switch delivering four beats a cycle measure 0.93, which is exactly the
      // number a fully serialised design would produce. A rate check built on
      // it would have passed the capability-reduced control.
      n_acc = 0; n_dlv = 0; n_maxlen = 0;
      cycle_r <= cycle_r + 1;
      if (c1_arm) c1_cycles <= c1_cycles + 1;

      // ---- input generators ------------------------------------------------
      for (si = 0; si < int'(S_COUNT); si++) begin
        automatic int unsigned d = g_act[si] ? g_fd[si] : int'(g_dest[si]);
        if (!g_act[si]) begin
          if (g_en[si]) begin
            automatic int unsigned sq = g_seq[si][d];
            g_act[si] <= 1'b1; g_cur[si] <= sq; g_bt[si] <= 0; g_fd[si] <= d;
            g_started[si][d] <= g_started[si][d] + 1;
            if (nbeats(si, d, sq) == MAXBEAT) n_maxlen = n_maxlen + 1;
            g_nb[si]  <= nbeats(si, d, sq);
            sv_r[si]  <= 1'b1;
            sl_r[si]  <= (nbeats(si, d, sq) == 1);
            sd_r[si*DATA_W +: DATA_W] <= payload(si, sq, 0);
            sk_r[si*KEEP_W +: KEEP_W] <= keepof(si, sq, 0, nbeats(si, d, sq));
            sde_r[si*DEST_W +: DEST_W] <= DEST_W'(d);
          end
          else sv_r[si] <= 1'b0;
        end
        else if (s_valid[si] && s_ready[si]) begin
          n_acc = n_acc + 1;
          if (g_bt[si] == g_nb[si]-1) begin
            // frame accepted in full
            g_act[si]        <= 1'b0;
            g_seq[si][d]     <= g_seq[si][d] + 1;
            g_sent[si][d]    <= g_sent[si][d] + 1;
            sv_r[si]         <= 1'b0;
            sl_r[si]         <= 1'b0;
          end
          else begin
            automatic int unsigned nb2 = g_bt[si] + 1;
            g_bt[si] <= nb2;
            sl_r[si] <= (nb2 == g_nb[si]-1);
            sd_r[si*DATA_W +: DATA_W] <= payload(si, g_cur[si], nb2);
            sk_r[si*KEEP_W +: KEEP_W] <= keepof(si, g_cur[si], nb2, g_nb[si]);
          end
        end
      end

      // ---- output monitors --------------------------------------------------
      for (mi = 0; mi < int'(M_COUNT); mi++) begin
        if (m_valid[mi] && m_ready[mi]) begin
          automatic logic [DATA_W-1:0] dw = m_data[mi*DATA_W +: DATA_W];
          automatic logic [KEEP_W-1:0] kw = m_keep[mi*KEEP_W +: KEEP_W];
          automatic int unsigned src = int'(dw[1:0]);
          n_dlv = n_dlv + 1;

          if (!o_busy[mi]) begin
            // frame start
            if (src >= int'(S_COUNT)) sb_route_err <= sb_route_err + 1;
            else begin
              automatic int unsigned sq = exp_seq[src][mi];
              automatic int unsigned nb = nbeats(src, mi, sq);
              // R3: it must have been sent to THIS output, and R5 fixes which
              // frame is next from this source to this output.
              if (g_started[src][mi] <= sq) sb_route_err <= sb_route_err + 1;
              if (dw !== payload(src, sq, 0)) sb_data_err <= sb_data_err + 1;
              if (kw !== keepof(src, sq, 0, nb)) sb_keep_err <= sb_keep_err + 1;
              o_src[mi] <= src; o_seq[mi] <= sq; o_nb[mi] <= nb; o_bt[mi] <= 1;
              if (m_last[mi]) begin
                if (nb != 1) sb_len_err <= sb_len_err + 1;
                exp_seq[src][mi]    <= sq + 1;
                dlv_frames[src][mi] <= dlv_frames[src][mi] + 1;
                o_busy[mi] <= 1'b0;
              end
              else o_busy[mi] <= 1'b1;
            end
          end
          else begin
            // R4: mid-frame beats must come from the SAME source
            if (src != o_src[mi]) sb_atom_err <= sb_atom_err + 1;
            else begin
              if (dw !== payload(o_src[mi], o_seq[mi], o_bt[mi])) sb_data_err <= sb_data_err + 1;
              if (kw !== keepof(o_src[mi], o_seq[mi], o_bt[mi], o_nb[mi])) sb_keep_err <= sb_keep_err + 1;
              if (m_last[mi]) begin
                if (o_bt[mi] != o_nb[mi]-1) sb_len_err <= sb_len_err + 1;
                exp_seq[o_src[mi]][mi]    <= o_seq[mi] + 1;
                dlv_frames[o_src[mi]][mi] <= dlv_frames[o_src[mi]][mi] + 1;
                o_busy[mi] <= 1'b0;
              end
              else begin
                if (o_bt[mi] >= o_nb[mi]-1) sb_len_err <= sb_len_err + 1;
                o_bt[mi] <= o_bt[mi] + 1;
              end
            end
          end
        end
      end

      accepts_r  <= accepts_r  + n_acc;
      delivers_r <= delivers_r + n_dlv;
      if (c1_arm) c1_beats <= c1_beats + n_dlv;
      maxlen_r <= maxlen_r + n_maxlen;

      if (rst_n) begin `LM_TICK(lm_off, lm_srv) end
    end
  end

  // C3: an input is "offered" while it has frames accepted but not delivered.
  always_comb begin
    lm_off = '0; lm_srv = '0;
    for (int s = 0; s < int'(S_COUNT); s++) begin
      automatic int unsigned sent = 0, dlv = 0;
      for (int m = 0; m < int'(M_COUNT); m++) begin sent += g_sent[s][m]; dlv += dlv_frames[s][m]; end
      lm_off[s] = (sent > dlv);
    end
    for (int m = 0; m < int'(M_COUNT); m++)
      if (m_valid[m] && m_ready[m] && m_last[m])
        lm_srv[int'(m_data[m*DATA_W +: DATA_W][1:0])] = 1'b1;
  end

  // ---------------------------------------------------------------- helpers
  task automatic idle(input int n); for (int k = 0; k < n; k++) @(negedge clk); endtask

  task automatic all_off();
    @(negedge clk);
    for (int s = 0; s < int'(S_COUNT); s++) g_en[s] = 1'b0;
  endtask

  task automatic drain(input int limit);
    int k; k = 0;
    while ((delivers_r != accepts_r || |m_valid) && (k < limit)) begin @(negedge clk); k++; end
    if (delivers_r != accepts_r)
      note_fail($sformatf("drain timeout: %0d beats accepted, %0d delivered", accepts_r, delivers_r));
  endtask

  int total_frames;
  always_comb begin
    total_frames = 0;
    for (int s = 0; s < int'(S_COUNT); s++)
      for (int m = 0; m < int'(M_COUNT); m++) total_frames += int'(g_sent[s][m]);
  end

  logic [31:0] lfsr;
  task automatic roll(); lfsr = {lfsr[30:0], lfsr[31]^lfsr[21]^lfsr[1]^lfsr[0]}; endtask

  int snap;

  initial begin
    errors = 0; checks = 0; phase = 0; fail_reason = "";
    cov_frames = 0; cov_multibeat = 0; cov_partial_keep = 0;
    cov_contend = 0; cov_hol = 0; cov_c1 = 0; cov_maxlen = 0;
    for (int s = 0; s < int'(S_COUNT); s++) begin
      g_en[s] = 1'b0; g_dest[s] = '0;
      for (int m = 0; m < int'(M_COUNT); m++) cov_pair[s][m] = 1'b0;
    end
    mr_r = '1; c1_arm = 1'b0;
    lfsr = (SEED == 0) ? 32'h1 : 32'(SEED);

    if (!((S_COUNT == 2 || S_COUNT == 4) && (M_COUNT == 2 || M_COUNT == 4) &&
          (DATA_W == 8 || DATA_W == 32))) begin
      $display("TEST_RESULT: FAIL: illegal parameter combination S_COUNT=%0d M_COUNT=%0d DATA_W=%0d",
               S_COUNT, M_COUNT, DATA_W);
      $finish;
    end

    rst_n = 1'b0; idle(8); @(negedge clk); rst_n = 1'b1; idle(4);

    // ============ P1: every input reaches every output ====================
    // Binds S_COUNT and M_COUNT structurally: a design that serves only input 0,
    // or routes everything to output 0, cannot pass this.
    phase = 1;
    for (int m = 0; m < int'(M_COUNT); m++) begin
      for (int s = 0; s < int'(S_COUNT); s++) begin
        @(negedge clk);
        g_dest[s] = DEST_W'(m); g_en[s] = 1'b1;
        cov_pair[s][m] = 1'b1;
      end
      idle(120);
      all_off();
      drain(4000);
    end
    for (int s = 0; s < int'(S_COUNT); s++)
      for (int m = 0; m < int'(M_COUNT); m++)
        chk(dlv_frames[s][m] > 0,
            $sformatf("input %0d never delivered a frame to output %0d", s, m));

    // ============ P2: contention on ONE output, frame atomicity ============
    phase = 2;
    @(negedge clk);
    for (int s = 0; s < int'(S_COUNT); s++) begin g_dest[s] = '0; g_en[s] = 1'b1; end
    cov_contend++;
    idle(400);
    all_off(); drain(8000);
    chk(sb_atom_err == 0, "R4: beats from two inputs interleaved on one output");

    // ============ P3: C2, head-of-line blocking ============================
    phase = 3;
    @(negedge clk);
    mr_r = '1; mr_r[0] = 1'b0;                 // output 0 will not accept
    g_dest[0] = '0; g_en[0] = 1'b1;            // input 0 backlogged to it
    if (S_COUNT > 1 && M_COUNT > 1) begin
      g_dest[1] = DEST_W'(1); g_en[1] = 1'b1;  // input 1 to a ready output
      snap = int'(dlv_frames[1][1]);
      idle(300);
      cov_hol++;
      chk(int'(dlv_frames[1][1]) > snap,
          "C2: an input to a ready output made no progress while another output was blocked");
    end
    @(negedge clk); mr_r = '1;
    all_off(); drain(20000);

    // ============ P4: C1, disjoint pairs in parallel =======================
    phase = 4;
    @(negedge clk);
    for (int s = 0; s < int'(S_COUNT); s++) begin
      g_dest[s] = DEST_W'(s % M_COUNT); g_en[s] = 1'b1;
    end
    idle(20);                                   // let the pipeline fill
    @(negedge clk); c1_arm = 1'b1;
    idle(600);
    @(negedge clk); c1_arm = 1'b0;
    cov_c1++;
    all_off(); drain(20000);

    // ============ P5: randomized soak ======================================
    phase = 5;
    for (int r = 0; r < 240; r++) begin
      @(negedge clk);
      for (int s = 0; s < int'(S_COUNT); s++) begin
        roll();
        g_dest[s] = DEST_W'(lfsr[5:2] % M_COUNT);
        g_en[s]   = 1'b1;
        cov_pair[s][lfsr[5:2] % M_COUNT] = 1'b1;
      end
      idle(24);
    end
    all_off(); drain(200000);

    // ============ results ==================================================
    phase = 6;
    cov_frames = total_frames; cov_maxlen = maxlen_r;
    for (int s = 0; s < int'(S_COUNT); s++)
      for (int m = 0; m < int'(M_COUNT); m++) begin
        chk(dlv_frames[s][m] == g_sent[s][m],
            $sformatf("R3: input %0d output %0d -- %0d frames accepted, %0d delivered",
                      s, m, g_sent[s][m], dlv_frames[s][m]));
        if (g_sent[s][m] > 0) cov_multibeat++;
      end
    chk(sb_route_err == 0, "R3: a frame arrived at an output it was not sent to");
    chk(sb_data_err  == 0, "R3: a delivered beat did not match what was sent");
    chk(sb_keep_err  == 0, "R3: a delivered beat's keep did not match what was sent");
    chk(sb_atom_err  == 0, "R4: beats from two inputs interleaved on one output");
    chk(sb_len_err   == 0, "R3: a delivered frame had the wrong beat count");
    chk(delivers_r == accepts_r,
        $sformatf("R3: %0d beats accepted, %0d delivered", accepts_r, delivers_r));

    // C1 -- an ABSOLUTE rate, never a ratio. See the spec clause.
    //
    // GATED ONLY WHERE IT CAN DISCRIMINATE. The floor is 2.0 beats/cycle and
    // the ceiling at S_COUNT=M_COUNT=2 is 2.0, so at the small configurations a
    // correct design cannot clear it and the floor would be failing correct
    // hardware -- the recorded trap where a reordering floor failed the vendored
    // reference and had to be removed. At 2x2 the rate is reported and is NOT
    // capability evidence, which is stated rather than left to be assumed.
    $display("METRIC: c1_rate beats=%0d cycles=%0d gated=%0d",
             c1_beats, c1_cycles, (S_COUNT >= 4 && M_COUNT >= 4) ? 1 : 0);
    if (c1_cycles == 0) note_fail("C1: measurement window never ran");
    else if (S_COUNT >= 4 && M_COUNT >= 4)
      chk((c1_beats * 10) >= (c1_cycles * 20),
          $sformatf("C1: aggregate rate %0d beats / %0d cycles is below the floor of 2.0 beats/cycle",
                    c1_beats, c1_cycles));

    `LM_CHECK(note_fail)

    $display("METRIC: frames total=%0d", cov_frames);
    $display("METRIC: beats accepted=%0d delivered=%0d cycles=%0d", accepts_r, delivers_r, cycle_r);

    // ---- coverage floors, all stimulus-side -------------------------------
    begin
      automatic int pairs = 0;
      for (int s = 0; s < int'(S_COUNT); s++)
        for (int m = 0; m < int'(M_COUNT); m++) if (cov_pair[s][m]) pairs++;
      if (pairs < int'(S_COUNT*M_COUNT))
        $display("COVERAGE HOLE: only %0d of %0d input/output pairs driven", pairs, S_COUNT*M_COUNT);
      if (cov_frames < 200)  $display("COVERAGE HOLE: only %0d frames driven", cov_frames);
      if (cov_maxlen  < 1)   $display("COVERAGE HOLE: no maximum-length frame driven");
      if (cov_contend < 1)   $display("COVERAGE HOLE: same-output contention never driven");
      if (cov_hol     < 1)   $display("COVERAGE HOLE: head-of-line condition never created");
      if (cov_c1      < 1)   $display("COVERAGE HOLE: C1 window never driven");
      if ((pairs < int'(S_COUNT*M_COUNT)) || (cov_frames < 200) || (cov_contend < 1) || (cov_maxlen < 1) ||
          (cov_hol < 1) || (cov_c1 < 1))
        note_fail("coverage floors not met -- the run did not exercise the target conditions");
    end

    if (checks < 10)
      note_fail($sformatf("only %0d checks ran -- the run did not reach the contract", checks));

    $display("METRIC: checks n=%0d", checks);
    if (errors == 0) $display("TEST_RESULT: PASS");
    else             $display("TEST_RESULT: FAIL: %s", fail_reason);
    $finish;
  end

  initial begin
    repeat (WATCHDOG_CYCLES) @(posedge clk);
    $display("TEST_RESULT: FAIL: watchdog at %0d cycles, phase %0d", WATCHDOG_CYCLES, phase);
    $finish;
  end

endmodule
