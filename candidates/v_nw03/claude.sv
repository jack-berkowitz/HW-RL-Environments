// ===========================================================================
// frame_arb_mux_tb.sv -- self-checking testbench for frame_arb_mux.
//
// S6 IS THE STRUCTURAL PROBLEM. There is no selection output and none is
// inferable from s_tready_o, so an output beat cannot be attributed to an input
// by watching the handshake. Attribution is therefore by a tag this testbench
// controls: DATA_WIDTH is 32 and S4 requires tdata to be forwarded unmodified,
// so every beat's tdata IS a globally unique sequence number, and the source,
// keep, user, last and frame of a beat are looked up from it. That is
// bookkeeping via a tag I assigned, not content matching of a value that
// repeats. s_tready_o is never read as a grant anywhere in this file.
//
// S4 ORDER, CHEAPLY. Sequence numbers increase per input, so "the beats of an
// input appear on the output in the order they transferred" is equivalent to
// "the sequence numbers seen for that input strictly increase" -- PROVIDED
// every beat is emitted exactly once, which S5 checks separately. The two
// together pin exact order with one integer per input.
//
// WHAT IS DELIBERATELY NOT CHECKED, because the contract frees it:
//   1  selection order -- only S10's window is checked, and it passes a bursty
//      arbiter that serves four frames from one input before moving on;
//   2  latency -- every wait is a bounded retry, never a required cycle count;
//   3  promptness of s_tready_o -- never required high, for any reason;
//   4  m_tdata_o / m_tkeep_o / m_tuser_o while m_tvalid_o is low -- the output
//      is sampled ONLY on a transfer;
//   5  whether a frame may start in the same cycle the previous one ends, and
//      how many idle cycles separate frames -- neither is examined;
//   6  internal structure, including whether inputs are buffered at all;
//   7  any particular tkeep pattern -- only that what arrived leaves with it.
//
// S7 is honoured: fields change only on the negative edge following the edge on
// which the previous beat transferred, so an offered beat is never withdrawn or
// altered. S5a is honoured: every frame started is completed before its source
// stops, and a partial frame held by the design is never read as a loss.
// ===========================================================================

`timescale 1ns/1ps

module frame_arb_mux_tb;

  localparam int S_COUNT    = 4;
  localparam int DATA_WIDTH = 32;
  localparam int USER_WIDTH = 1;
  localparam int KEEP_W     = DATA_WIDTH/8;

  localparam int MAXB = 6000;    // sequence numbers
  localparam int MAXF = 2500;    // frames

  // =========================================================================
  // PROVIDED PLUMBING -- moves beats, checks nothing.
  // =========================================================================
  logic clk;
  initial begin clk = 1'b0; forever #5 clk = ~clk; end

  logic rst;
  initial rst = 1'b1;

  task automatic bfm_reset(input int cycles = 4);
    @(negedge clk);
    rst = 1'b1;
    repeat (cycles) @(posedge clk);
    @(negedge clk);
    rst = 1'b0;
  endtask

  initial begin
    #20_000_000;
    $display("RESULT: FAIL (watchdog: no forward progress)");
    $finish;
  end

  // =========================================================================
  // DUT connections -- packed, matching the port map exactly
  // =========================================================================
  logic [S_COUNT-1:0][DATA_WIDTH-1:0] s_tdata;
  logic [S_COUNT-1:0][KEEP_W-1:0]     s_tkeep;
  logic [S_COUNT-1:0]                 s_tvalid;
  logic [S_COUNT-1:0]                 s_tready;
  logic [S_COUNT-1:0]                 s_tlast;
  logic [S_COUNT-1:0][USER_WIDTH-1:0] s_tuser;

  logic [DATA_WIDTH-1:0] m_tdata;
  logic [KEEP_W-1:0]     m_tkeep;
  logic                  m_tvalid;
  logic                  m_tready;
  logic                  m_tlast;
  logic [USER_WIDTH-1:0] m_tuser;

  frame_arb_mux #(
    .S_COUNT    (S_COUNT),
    .DATA_WIDTH (DATA_WIDTH),
    .USER_WIDTH (USER_WIDTH)
  ) dut (
    .clk_i      (clk),
    .rst_i      (rst),
    .s_tdata_i  (s_tdata),
    .s_tkeep_i  (s_tkeep),
    .s_tvalid_i (s_tvalid),
    .s_tready_o (s_tready),
    .s_tlast_i  (s_tlast),
    .s_tuser_i  (s_tuser),
    .m_tdata_o  (m_tdata),
    .m_tkeep_o  (m_tkeep),
    .m_tvalid_o (m_tvalid),
    .m_tready_i (m_tready),
    .m_tlast_o  (m_tlast),
    .m_tuser_o  (m_tuser)
  );

  // =========================================================================
  // reporting
  // =========================================================================
  int nerr;
  int nprint;

  task automatic fail(input string cl, input string msg);
    nerr = nerr + 1;
    if (nprint < 40) begin
      nprint = nprint + 1;
      $display("FAIL [%0s] t=%0t : %0s", cl, $time, msg);
    end
  endtask

  // =========================================================================
  // Beat record, indexed by the sequence number carried in tdata.
  // Written at generation by the driver; read by everything.
  // =========================================================================
  int              src_of   [MAXB];
  logic [KEEP_W-1:0] keep_of [MAXB];
  logic            user_of  [MAXB];
  bit              last_of  [MAXB];
  bit              first_of [MAXB];
  int              frame_of [MAXB];
  bit              committed[MAXB];   // monitor: transferred on its input
  bit              emitted  [MAXB];   // monitor: transferred on the output
  bit              voided   [MAXB];   // stimulus: discarded by a reset
  bit              frm_done [MAXF];   // monitor: final beat transferred in

  // =========================================================================
  // Source drivers.  One negative-edge block for all four inputs.  Fields are
  // changed ONLY on the negative edge after the edge that consumed the previous
  // beat, which is exactly S7's obligation.
  // =========================================================================
  int  req_frames  [S_COUNT];   // stimulus-owned
  int  made_frames [S_COUNT];   // driver-owned
  int  gen_left    [S_COUNT];
  int  gen_fid     [S_COUNT];
  int  next_seq;
  int  next_fid;
  int  n_gen;
  logic [S_COUNT-1:0] xfer_r;

  always @(posedge clk) begin
    if (rst) xfer_r <= '0;
    else     xfer_r <= s_tvalid & s_tready;      // S1
  end

  always @(negedge clk) begin
    int k;
    int sq;
    bit is_first;
    if (rst) begin
      for (k = 0; k < S_COUNT; k++) begin
        s_tvalid[k] = 1'b0;
        gen_left[k] = 0;                          // abandon any part-built frame
      end
    end
    else begin
      for (k = 0; k < S_COUNT; k++) begin
        if (xfer_r[k]) begin
          s_tvalid[k] = 1'b0;
          gen_left[k] = gen_left[k] - 1;
          if (gen_left[k] == 0) made_frames[k] = made_frames[k] + 1;
        end
        if (!s_tvalid[k] && (made_frames[k] < req_frames[k]) && (next_seq < MAXB - 4)
            && (next_fid < MAXF - 2)) begin
          is_first = (gen_left[k] == 0);
          if (is_first) begin
            // Lengths cycle 1..5, so single-beat frames (S2) occur regularly.
            gen_left[k] = 1 + (next_fid % 5);
            gen_fid[k]  = next_fid;
            next_fid    = next_fid + 1;
          end
          sq           = next_seq;
          next_seq     = next_seq + 1;
          n_gen        = n_gen + 1;
          src_of[sq]   = k;
          keep_of[sq]  = KEEP_W'($urandom);
          user_of[sq]  = 1'($urandom);
          last_of[sq]  = (gen_left[k] == 1);
          first_of[sq] = is_first;
          frame_of[sq] = gen_fid[k];
          s_tdata[k]   = DATA_WIDTH'(sq);         // the tag S6 forces me to carry
          s_tkeep[k]   = keep_of[sq];
          s_tuser[k]   = user_of[sq];
          s_tlast[k]   = last_of[sq];
          s_tvalid[k]  = 1'b1;
        end
      end
    end
  end

  // =========================================================================
  // Output-side ready.  Driven only here, at the negative edge (S8).
  // =========================================================================
  int rdy_mode;   // stimulus-owned: 0 = always ready, 1 = pattern, 2 = never
  int rdy_cnt;

  always @(negedge clk) begin
    rdy_cnt <= rdy_cnt + 1;
    if      (rdy_mode == 0) m_tready <= 1'b1;
    else if (rdy_mode == 2) m_tready <= 1'b0;
    else                    m_tready <= ((rdy_cnt % 7) < 3);   // long stalls
  end

  // =========================================================================
  // MONITOR.  Samples at the rising edge, so it reads the values that were
  // valid during the cycle the transfer completed on.  The output is examined
  // ONLY on a transfer, never while m_tvalid_o is low.
  // =========================================================================
  int  n_cmt;
  int  n_emt;
  int  cur_owner;                 // -1 when no output frame is in progress
  int  cur_fid;
  int  last_out_seq [S_COUNT];
  int  frm_owner [$];
  bit  rst_r;

  always @(posedge clk) begin
    int k;
    int sq;
    if (rst) begin
      cur_owner <= -1;
    end
    else begin
      // S12: idle on the first cycle after release.
      if (rst_r && (m_tvalid === 1'b1))
        fail("S12", "m_tvalid_o high on the first cycle after rst_i was released");

      // Input beats (S1).
      for (k = 0; k < S_COUNT; k++) begin
        if (s_tvalid[k] && s_tready[k]) begin
          sq = int'(s_tdata[k]);
          committed[sq] = 1'b1;
          n_cmt = n_cmt + 1;
          if (last_of[sq]) frm_done[frame_of[sq]] = 1'b1;
        end
      end

      // Output beats (S1).
      if (m_tvalid && m_tready) begin
        sq = int'(m_tdata);
        if ((sq <= 0) || (sq >= next_seq)) begin
          fail("S4", $sformatf("output beat carries tdata=%08h, which was never offered on any input",
                               m_tdata));
        end
        else if (voided[sq]) begin
          fail("S12", $sformatf("beat %0d, accepted before a reset, appeared on the output after it", sq));
        end
        else if (!committed[sq]) begin
          fail("S5", $sformatf("output beat %0d never transferred on input %0d", sq, src_of[sq]));
        end
        else if (emitted[sq]) begin
          fail("S5", $sformatf("beat %0d (input %0d) delivered more than once", sq, src_of[sq]));
        end
        else begin
          emitted[sq] = 1'b1;
          n_emt = n_emt + 1;

          // S4: payload forwarded unmodified, across the full width.
          if (m_tkeep !== keep_of[sq])
            fail("S4", $sformatf("beat %0d: m_tkeep_o=%0h, offered %0h", sq, m_tkeep, keep_of[sq]));
          if (m_tuser !== user_of[sq])
            fail("S4", $sformatf("beat %0d: m_tuser_o=%0h, offered %0h", sq, m_tuser, user_of[sq]));
          if (m_tlast !== last_of[sq])
            fail("S4", $sformatf("beat %0d: m_tlast_o=%0b, offered %0b", sq, m_tlast, last_of[sq]));

          // S4: per-input order. Sequence numbers rise with transfer order.
          if (sq <= last_out_seq[src_of[sq]])
            fail("S4", $sformatf("beat %0d from input %0d delivered after beat %0d of the same input",
                                 sq, src_of[sq], last_out_seq[src_of[sq]]));
          last_out_seq[src_of[sq]] = sq;

          // S3: frame atomicity.
          if (cur_owner < 0) begin
            if (!first_of[sq])
              fail("S3", $sformatf("output frame began at beat %0d, which is not the first beat of its frame",
                                   sq));
            cur_owner <= src_of[sq];
            cur_fid   <= frame_of[sq];
          end
          else if ((src_of[sq] != cur_owner) || (frame_of[sq] != cur_fid)) begin
            fail("S3", $sformatf("beat %0d (input %0d, frame %0d) interleaved into frame %0d of input %0d",
                                 sq, src_of[sq], frame_of[sq], cur_fid, cur_owner));
          end

          if (m_tlast) begin
            frm_owner.push_back(src_of[sq]);        // S10 evidence
            cur_owner <= -1;
          end
        end
      end
    end
    rst_r <= rst;
  end

  // =========================================================================
  // Stimulus
  // =========================================================================
  int  n_void_gen;   // generated but never transferred in, discarded by reset
  int  n_void_cmt;   // transferred in but never emitted, discarded by reset
  int  p_i, p_j, p_k, guard, fair_a, fair_b;
  logic [S_COUNT-1:0] seen;
  bit  win_bad;

  function automatic bit all_made();
    int k;
    for (k = 0; k < S_COUNT; k++)
      if (made_frames[k] < req_frames[k]) return 1'b0;
    return 1'b1;
  endfunction

  // Everything offered has gone in, and everything in has come out.
  task automatic wait_drain(input int budget, input string nm);
    int g;
    g = 0;
    while (g < budget) begin
      if (all_made() && ((n_cmt + n_void_gen) == n_gen)
                     && ((n_emt + n_void_cmt) == n_cmt)) break;
      @(posedge clk);
      g = g + 1;
    end
    if (g >= budget) begin
      if ((n_cmt + n_void_gen) != n_gen)
        fail("S5", $sformatf("%0s: %0d beat(s) offered were never accepted on any input",
                             nm, n_gen - n_cmt - n_void_gen));
      else
        fail("S5", $sformatf("%0s: %0d beat(s) accepted were never delivered on the output",
                             nm, n_cmt - n_emt - n_void_cmt));
    end
  endtask

  // Add frames to every source. req_frames is read on the negative edge, so it
  // is written here on the positive one.
  task automatic add_frames(input int n0, input int n1, input int n2, input int n3);
    @(posedge clk);
    req_frames[0] = req_frames[0] + n0;
    req_frames[1] = req_frames[1] + n1;
    req_frames[2] = req_frames[2] + n2;
    req_frames[3] = req_frames[3] + n3;
  endtask

  task automatic set_ready_mode(input int m);
    @(posedge clk);
    rdy_mode = m;
  endtask

  initial begin
    nerr = 0; nprint = 0;
    next_seq = 1; next_fid = 0; n_gen = 0; n_cmt = 0; n_emt = 0;
    n_void_gen = 0; n_void_cmt = 0;
    rdy_mode = 0;
    // cur_owner, cur_fid, rst_r and rdy_cnt are driven non-blocking by the
    // monitor and the ready driver; assigning them here too would be a
    // blocking/non-blocking conflict, which Verilator rejects outright.
    // cur_owner is established by the monitor's reset branch on the first edge.
    for (p_i = 0; p_i < S_COUNT; p_i++) begin
      req_frames[p_i]   = 0;
      made_frames[p_i]  = 0;
      gen_left[p_i]     = 0;
      gen_fid[p_i]      = 0;
      last_out_seq[p_i] = 0;
      s_tdata[p_i]      = '0;
      s_tkeep[p_i]      = '0;
      s_tuser[p_i]      = '0;
      s_tlast[p_i]      = 1'b0;
      s_tvalid[p_i]     = 1'b0;
    end
    for (p_i = 0; p_i < MAXB; p_i++) begin
      committed[p_i] = 1'b0;
      emitted[p_i]   = 1'b0;
      voided[p_i]    = 1'b0;
      src_of[p_i]    = 0;
      frame_of[p_i]  = 0;
    end
    for (p_i = 0; p_i < MAXF; p_i++) frm_done[p_i] = 1'b0;

    bfm_reset(6);
    repeat (4) @(posedge clk);

    // ---- phase A: one source, includes single-beat frames (S2, S3, S4) ----
    set_ready_mode(0);
    add_frames(6, 0, 0, 0);
    wait_drain(20000, "phase A, single source");

    // ---- phase B: all four sources, no backpressure -----------------------
    add_frames(8, 8, 8, 8);
    wait_drain(40000, "phase B, four sources");

    // ---- phase C: bounded fairness (S10) ---------------------------------
    // Continuous offered load on every input, m_tready_i high throughout --
    // those are S10's stated preconditions, and it only binds under them.
    set_ready_mode(0);
    fair_a = frm_owner.size();
    add_frames(30, 30, 30, 30);
    wait_drain(60000, "phase C, fairness");
    fair_b = frm_owner.size();
    if ((fair_b - fair_a) < 40) begin
      fail("S10", $sformatf("only %0d frame(s) completed under continuous load; too few to judge fairness",
                            fair_b - fair_a));
    end
    else begin
      win_bad = 1'b0;
      // Skip the first 8 frames as ramp-up: a starving design fails every
      // later window too, so this costs nothing in detection.
      for (p_i = fair_a + 8; (p_i + 16) <= fair_b; p_i++) begin
        if (!win_bad) begin
          seen = '0;
          for (p_j = 0; p_j < 16; p_j++) seen[frm_owner[p_i + p_j]] = 1'b1;
          if (seen !== {S_COUNT{1'b1}}) begin
            fail("S10", $sformatf("16 consecutive output frames from index %0d covered inputs %04b: an input began none",
                                  p_i - fair_a, seen));
            win_bad = 1'b1;
          end
        end
      end
    end

    // ---- phase D: the same, under backpressure (S8) -----------------------
    set_ready_mode(1);
    add_frames(12, 12, 12, 12);
    wait_drain(80000, "phase D, backpressure");

    // ---- phase E: reset with beats in flight (S12) ------------------------
    set_ready_mode(2);                 // shut the output so beats pile up inside
    add_frames(3, 3, 3, 3);
    repeat (60) @(posedge clk);
    // Assert reset FIRST, then void: the monitor ignores everything while rst
    // is high, so nothing can be emitted between the void and the reset.
    @(negedge clk);
    rst = 1'b1;
    for (p_i = 1; p_i < next_seq; p_i++) begin
      if (!voided[p_i]) begin
        if (!committed[p_i]) begin
          voided[p_i] = 1'b1;
          n_void_gen  = n_void_gen + 1;
        end
        else if (!emitted[p_i]) begin
          voided[p_i] = 1'b1;
          n_void_cmt  = n_void_cmt + 1;
        end
      end
    end
    repeat (5) @(posedge clk);
    @(negedge clk);
    rst = 1'b0;
    // Ready high, so any stale beat WILL transfer and be seen.
    set_ready_mode(0);
    repeat (60) @(posedge clk);

    // ---- phase F: the unit works again after reset (S12 second half) ------
    add_frames(6, 6, 6, 6);
    wait_drain(40000, "phase F, after reset");

    // ---- final: no loss (S5), honouring S5a -------------------------------
    // Only frames whose final beat actually transferred in are required; a
    // frame the source abandoned, or one discarded by reset, is exempt.
    guard = 0;
    for (p_i = 1; p_i < next_seq; p_i++) begin
      if (committed[p_i] && !voided[p_i] && frm_done[frame_of[p_i]] && !emitted[p_i]) begin
        guard = guard + 1;
        if (guard <= 5)
          fail("S5", $sformatf("beat %0d of completed frame %0d (input %0d) never appeared on the output",
                               p_i, frame_of[p_i], src_of[p_i]));
      end
    end
    if (guard > 5)
      fail("S5", $sformatf("%0d beat(s) of completed frames were never delivered in total", guard));

    // No frame left half-delivered on the output.
    if (cur_owner >= 0)
      fail("S3", $sformatf("run ended with frame %0d of input %0d started but never finished on the output",
                           cur_fid, cur_owner));

    $display("summary: %0d beat(s) offered, %0d accepted, %0d delivered, %0d output frame(s), %0d failure(s)",
             n_gen, n_cmt, n_emt, frm_owner.size(), nerr);
    if (nerr == 0) $display("RESULT: PASS");
    else           $display("RESULT: FAIL");
    $finish;
  end

endmodule