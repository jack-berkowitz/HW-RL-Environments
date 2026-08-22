// =============================================================================
// frame_arb_mux_tb.sv
// -----------------------------------------------------------------------------
// Self-checking testbench for frame_arb_mux, S_COUNT=4 DATA_WIDTH=32 USER_WIDTH=1.
//
// How it decides things
// ---------------------
// There is no selection output and none is inferable from s_tready_o (S6), so
// the source of an output frame is recovered from a TAG the testbench itself
// planted in the payload: bits [31:30] of every beat carry its source index.
// That is bookkeeping, not content matching -- every beat is made globally
// unique by (src, frame number, beat number) so nothing is ambiguous.
//
// The model is one queue of beats in input-transfer order, each tagged with its
// source. An output beat is checked against the OLDEST not-yet-emitted beat OF
// ITS OWN SOURCE, which gives S4's per-input ordering while saying nothing
// about order between inputs.
//
// Input recording and output checking live in ONE always @(posedge clk) block,
// inputs first. That way a design with zero latency -- an output beat in the
// same cycle as the input beat that feeds it -- is handled, and a design with
// deep buffering is handled equally, without either being assumed.
//
// Deliberately NOT checked, because the spec leaves them free
// -----------------------------------------------------------
//   S9  / scope 1 : which input goes next. Nothing anywhere compares the source
//                   sequence against an expected order; S10's window is the
//                   only constraint applied.
//   S11 / scope 2 : latency. No check refers to WHEN a beat appears, only to
//                   the order in which beats appear.
//   scope 3       : s_tready_o promptness. Ready is never required to be high.
//                   Sends time out silently rather than failing.
//   scope 4       : m_tdata_o / m_tkeep_o / m_tuser_o are read ONLY in a cycle
//                   where m_tvalid_o and m_tready_i are both high.
//   scope 5       : gaps between frames. Frame boundaries are tracked by
//                   m_tlast_o alone; idle cycles are never counted.
//   scope 6, 7    : internal structure, tkeep patterns. tkeep is generated
//                   varying and only compared against what was sent.
//
// Termination: every wait is a bounded loop, and an independent watchdog
// reports failure and finishes regardless of what the design does. A design
// that never selects an input is reported, not waited on.
// =============================================================================

module frame_arb_mux_tb;

  localparam int S_COUNT    = 4;
  localparam int DATA_WIDTH = 32;
  localparam int USER_WIDTH = 1;
  localparam int KEEP_W     = DATA_WIDTH/8;

  localparam int SEND_LIM   = 4000;   // per-beat bound; NOT a conformance limit
  localparam int FAIR_N     = 64;     // frames collected for the S10 window scan

// ---------------------------------------------------------------------------
// PROVIDED PLUMBING -- moves beats, checks nothing.
// ---------------------------------------------------------------------------
  // ---- clock -----------------------------------------------------------------
  logic clk;
  initial begin clk = 1'b0; forever #5 clk = ~clk; end

  // ---- reset -----------------------------------------------------------------
  logic rst;
  initial rst = 1'b1;

  task automatic bfm_reset(input int cycles = 4);
    @(negedge clk);
    rst = 1'b1;
    repeat (cycles) @(posedge clk);
    @(negedge clk);
    rst = 1'b0;
  endtask

  // ---- signals ---------------------------------------------------------------
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

  initial begin
    s_tdata  = '0;
    s_tkeep  = '0;
    s_tvalid = '0;
    s_tlast  = '0;
    s_tuser  = '0;
    m_tready = 1'b0;
  end

  frame_arb_mux #(
    .S_COUNT(S_COUNT), .DATA_WIDTH(DATA_WIDTH), .USER_WIDTH(USER_WIDTH)
  ) dut (
    .clk_i(clk), .rst_i(rst),
    .s_tdata_i(s_tdata), .s_tkeep_i(s_tkeep), .s_tvalid_i(s_tvalid),
    .s_tready_o(s_tready), .s_tlast_i(s_tlast), .s_tuser_i(s_tuser),
    .m_tdata_o(m_tdata), .m_tkeep_o(m_tkeep), .m_tvalid_o(m_tvalid),
    .m_tready_i(m_tready), .m_tlast_o(m_tlast), .m_tuser_o(m_tuser)
  );

  // ---- input side ------------------------------------------------------------
  task automatic bfm_send(input int                          k,
                          input logic [DATA_WIDTH-1:0]       data,
                          input logic [(DATA_WIDTH/8)-1:0]   keep,
                          input logic                        last,
                          input logic [USER_WIDTH-1:0]       user);
    @(negedge clk);
    s_tdata[k]  = data;
    s_tkeep[k]  = keep;
    s_tlast[k]  = last;
    s_tuser[k]  = user;
    s_tvalid[k] = 1'b1;
    forever begin
      @(posedge clk);
      if (s_tready[k]) break;
    end
  endtask

  task automatic bfm_idle(input int k);
    @(negedge clk);
    s_tvalid[k] = 1'b0;
  endtask

  // ---- output side -----------------------------------------------------------
  task automatic bfm_ready(input logic value);
    @(negedge clk);
    m_tready = value;
  endtask

  // ---- watchdog (S13) --------------------------------------------------------
  initial begin
    #20_000_000;
    $display("RESULT: FAIL (watchdog: no forward progress)");
    $finish;
  end
// ---------------------------------------------------------------------------
// END OF PROVIDED PLUMBING -- everything below is the checker.
// ---------------------------------------------------------------------------

  // ---- bounded send. A beat that is not accepted is NOT a failure: ready
  // promptness is out of scope. It only stops this testbench from waiting.
  task automatic send_lim(input int                        k,
                          input logic [DATA_WIDTH-1:0]     data,
                          input logic [KEEP_W-1:0]         keep,
                          input logic                      last,
                          input logic [USER_WIDTH-1:0]     user,
                          input int                        lim,
                          output bit                       ok);
    int t;
    begin
      ok = 1'b0;
      @(negedge clk);
      s_tdata[k]  = data;
      s_tkeep[k]  = keep;
      s_tlast[k]  = last;
      s_tuser[k]  = user;
      s_tvalid[k] = 1'b1;
      for (t = 0; t < lim; t = t + 1) begin
        @(posedge clk);
        if (s_tready[k] === 1'b1) begin
          ok = 1'b1;
          break;
        end
      end
    end
  endtask

  // ---- model -----------------------------------------------------------------
  typedef struct packed {
    logic [1:0]            src;
    logic [DATA_WIDTH-1:0] data;
    logic [KEEP_W-1:0]     keep;
    logic                  last;
    logic [USER_WIDTH-1:0] user;
  } rec_t;

  rec_t exp_q [$];        // beats transferred in, not yet seen out
  int   src_seq [$];      // source of each completed output frame (S10 window)

  int  nerr        = 0;
  int  frames_out  = 0;
  int  beats_out   = 0;
  int  beats_in    = 0;
  bit  in_frame    = 1'b0;
  int  cur_src     = 0;
  bit  mon_en      = 1'b0;
  bit  quiet_win   = 1'b0;
  bit  fair_rec    = 1'b0;
  bit  stop_load   = 1'b0;
  bit  send_gaveup = 1'b0;
  bit  rst_d       = 1'b1;
  int  fcnt [S_COUNT];

  task automatic err(input string sid, input string msg);
    begin
      nerr = nerr + 1;
      if (nerr <= 40) $display("FAIL [%s] t=%0t : %s", sid, $time, msg);
    end
  endtask

  // ---- the monitor -----------------------------------------------------------
  // One block, inputs recorded before outputs are checked, so a zero-latency
  // design and a deeply buffered one are both handled.
  always @(posedge clk) begin
    int  k, qi, sidx, j;
    rec_t r, e;

    if (rst === 1'b1) begin
      // S12: reset returns the design to idle and discards what it held.
      exp_q.delete();
      in_frame = 1'b0;
    end else begin
      if (rst_d === 1'b1) begin
        if (m_tvalid !== 1'b0)
          err("S12", "m_tvalid_o is high on the first cycle after rst_i is released");
      end

      // ---- record every input beat that transferred (S1) ----
      for (k = 0; k < S_COUNT; k = k + 1) begin
        if ((s_tvalid[k] === 1'b1) && (s_tready[k] === 1'b1)) begin
          r.src  = k[1:0];
          r.data = s_tdata[k];
          r.keep = s_tkeep[k];
          r.last = s_tlast[k];
          r.user = s_tuser[k];
          exp_q.push_back(r);
          beats_in = beats_in + 1;
        end
      end

      // ---- check every output beat that transferred (S1) ----
      if ((m_tvalid === 1'b1) && (m_tready === 1'b1)) begin
        beats_out = beats_out + 1;
        if (quiet_win) begin
          err("S12", "a beat appeared on the output after reset, with nothing offered since");
        end else if (mon_en) begin
          sidx = int'(m_tdata[DATA_WIDTH-1 -: 2]);
          if (!in_frame) begin
            cur_src = sidx;
          end else if (sidx !== cur_src) begin
            err("S3", $sformatf("a beat tagged input %0d transferred inside a frame from input %0d",
                                sidx, cur_src));
            cur_src = sidx;   // resynchronise so the run keeps producing evidence
          end

          // oldest not-yet-emitted beat of THIS source: gives S4's per-input
          // order without constraining order between inputs (S9/scope 1).
          qi = -1;
          for (j = 0; j < exp_q.size(); j = j + 1)
            if ((qi < 0) && (exp_q[j].src == cur_src[1:0])) qi = j;

          if (qi < 0) begin
            err("S5", $sformatf("output beat tagged input %0d with no such beat outstanding (duplicate or invented)",
                                cur_src));
          end else begin
            e = exp_q[qi];
            if (m_tdata !== e.data)
              err("S4", $sformatf("tdata %08h on the output, %08h went in (input %0d)",
                                  m_tdata, e.data, cur_src));
            if (m_tkeep !== e.keep)
              err("S4", $sformatf("tkeep %b on the output, %b went in (input %0d)",
                                  m_tkeep, e.keep, cur_src));
            if (m_tuser !== e.user)
              err("S4", $sformatf("tuser %b on the output, %b went in (input %0d)",
                                  m_tuser, e.user, cur_src));
            if (m_tlast !== e.last)
              err("S4", $sformatf("m_tlast_o=%b on a beat whose s_tlast_i was %b (input %0d)",
                                  m_tlast, e.last, cur_src));
            exp_q.delete(qi);
          end

          if (m_tlast === 1'b1) begin
            in_frame   = 1'b0;
            frames_out = frames_out + 1;
            if (fair_rec) src_seq.push_back(cur_src);
          end else begin
            in_frame = 1'b1;
          end
        end
      end
    end
    rst_d = rst;
  end

  // ---- stimulus helpers ------------------------------------------------------
  // Every beat is globally unique: {src, frame number, beat number, pattern}.
  function automatic logic [DATA_WIDTH-1:0] mk_data(input int k, input int f, input int b);
    mk_data = {k[1:0], f[13:0], b[7:0], (f[7:0] ^ {b[3:0], ~b[3:0]})};
  endfunction

  function automatic logic [KEEP_W-1:0] mk_keep(input int f, input int b);
    mk_keep = KEEP_W'(((f + b) % 15) + 1);   // varying, never zero; no pattern is required
  endfunction

  function automatic logic mk_user(input int f, input int b);
    mk_user = logic'((f + b) & 1);
  endfunction

  // Sends one complete frame. Returns 0 only if the design stopped accepting,
  // which is not itself a failure (scope 3).
  task automatic send_frame(input int k, input int nbeats, output bit ok);
    int b, f;
    bit bok;
    begin
      ok = 1'b1;
      f  = fcnt[k];
      fcnt[k] = fcnt[k] + 1;
      for (b = 0; b < nbeats; b = b + 1) begin
        send_lim(k, mk_data(k, f, b), mk_keep(f, b), (b == nbeats-1), mk_user(f, b),
                 SEND_LIM, bok);
        if (!bok) begin
          ok = 1'b0;
          send_gaveup = 1'b1;
          break;
        end
      end
    end
  endtask

  task automatic burst_driver(input int k, input int nframes);
    int f;
    bit ok;
    begin
      for (f = 0; f < nframes; f = f + 1) begin
        send_frame(k, 1 + ((f + k) % 5), ok);   // includes single-beat frames (S2)
        if (!ok) break;
      end
      bfm_idle(k);
    end
  endtask

  // Continuous offered load: tvalid never drops between frames (S10's premise).
  task automatic load_driver(input int k);
    int f;
    bit ok;
    begin
      f = 0;
      while (!stop_load) begin
        send_frame(k, 1 + (f % 4), ok);
        if (!ok) break;
        f = f + 1;
      end
      bfm_idle(k);
    end
  endtask

  task automatic ready_wiggle(input int cycles);
    int t;
    begin
      for (t = 0; t < cycles; t = t + 1) begin
        @(negedge clk);
        // long low runs, including across m_tlast_o beats (S8)
        m_tready = ((t % 11) < 6);
      end
      @(negedge clk);
      m_tready = 1'b1;
    end
  endtask

  task automatic wait_drain(input int max_cyc, output bit ok);
    int t;
    begin
      ok = 1'b0;
      for (t = 0; t < max_cyc; t = t + 1) begin
        @(posedge clk);
        if (exp_q.size() == 0) begin
          ok = 1'b1;
          break;
        end
      end
    end
  endtask

  // ---- test program ----------------------------------------------------------
  initial begin
    int  i, w, j, seen, nwin;
    bit  ok;
    bit  any_win_bad;

    for (i = 0; i < S_COUNT; i = i + 1) fcnt[i] = 0;

    // -------------------------------------------------------------- S12 ------
    bfm_reset(4);
    mon_en = 1'b1;
    bfm_ready(1'b1);
    repeat (4) @(posedge clk);

    // --------------------------------------------------- S2 / S4 / S5 --------
    // One input at a time: a single-beat frame, then multi-beat frames.
    send_frame(0, 1, ok);
    send_frame(0, 4, ok);
    send_frame(2, 1, ok);
    send_frame(2, 8, ok);
    bfm_idle(0);
    bfm_idle(2);
    wait_drain(3000, ok);
    if (!ok) err("S5", "beats from single-input frames never appeared on the output");

    // ------------------------------------------------------ S3 / S5 ----------
    // All four inputs offering at once, output always ready.
    fork
      burst_driver(0, 6);
      burst_driver(1, 6);
      burst_driver(2, 6);
      burst_driver(3, 6);
    join
    wait_drain(8000, ok);
    if (!ok)
      err(send_gaveup ? "S10" : "S5",
          $sformatf("%0d beat(s) still undelivered after concurrent traffic drained",
                    exp_q.size()));

    // ------------------------------------------------------------- S8 --------
    // Same traffic with the sink stalling, including across m_tlast_o beats.
    fork
      burst_driver(0, 5);
      burst_driver(1, 5);
      burst_driver(2, 5);
      burst_driver(3, 5);
      ready_wiggle(700);
    join
    bfm_ready(1'b1);
    wait_drain(8000, ok);
    if (!ok)
      err(send_gaveup ? "S10" : "S8",
          $sformatf("%0d beat(s) lost or stuck after output backpressure", exp_q.size()));

    // Long unbroken stall, then release.
    bfm_ready(1'b0);
    fork
      burst_driver(1, 3);
      burst_driver(3, 3);
      begin
        repeat (40) @(posedge clk);
        bfm_ready(1'b1);
      end
    join
    bfm_ready(1'b1);
    wait_drain(8000, ok);
    if (!ok)
      err(send_gaveup ? "S10" : "S8",
          $sformatf("%0d beat(s) lost after a sustained stall", exp_q.size()));

    // ------------------------------------------------------------ S10 --------
    // Continuous offered load on every input, sink always ready.
    bfm_ready(1'b1);
    stop_load = 1'b0;
    fair_rec  = 1'b1;
    fork
      load_driver(0);
      load_driver(1);
      load_driver(2);
      load_driver(3);
      begin
        int t;
        for (t = 0; t < 40000; t = t + 1) begin
          @(posedge clk);
          if (src_seq.size() >= FAIR_N) break;
        end
        stop_load = 1'b1;
      end
    join
    fair_rec = 1'b0;
    bfm_ready(1'b1);
    wait_drain(20000, ok);

    if (src_seq.size() < 16) begin
      err("S10", $sformatf("only %0d frame(s) completed under continuous load on all inputs",
                           src_seq.size()));
    end else begin
      any_win_bad = 1'b0;
      nwin = 0;
      for (w = 0; (w + 16) <= src_seq.size(); w = w + 1) begin
        seen = 0;
        for (j = w; j < (w + 16); j = j + 1) seen = seen | (1 << src_seq[j]);
        nwin = nwin + 1;
        if (seen !== ((1 << S_COUNT) - 1)) begin
          if (!any_win_bad)
            err("S10", $sformatf("in the 16 completed frames at position %0d, only inputs {%b} began a frame",
                                 w, seen[S_COUNT-1:0]));
          any_win_bad = 1'b1;
        end
      end
    end

    // ------------------------------------------------------------- S12 -------
    // Reset with beats held inside the design: none of them may emerge after.
    bfm_reset(4);
    mon_en = 1'b1;
    repeat (4) @(posedge clk);

    bfm_ready(1'b0);               // stall the output so beats stay inside
    send_frame(0, 2, ok);
    send_frame(1, 2, ok);

    @(negedge clk);
    rst = 1'b1;                    // assert reset with that traffic held
    repeat (3) @(posedge clk);
    @(negedge clk);
    s_tvalid = '0;                 // stop offering while the design is in reset
    m_tready = 1'b1;               // and let it drain if it wrongly tries to
    repeat (3) @(posedge clk);
    quiet_win = 1'b1;
    @(negedge clk);
    rst = 1'b0;

    repeat (30) @(posedge clk);    // nothing offered: any output beat is stale
    quiet_win = 1'b0;

    // and the design still works afterwards
    send_frame(2, 3, ok);
    bfm_idle(2);
    wait_drain(3000, ok);
    if (!ok) err("S5", "the design did not deliver a frame sent after reset");

    // ---- verdict --------------------------------------------------------------
    if ((beats_out == 0) || (frames_out == 0))
      err("S5", "no output beat ever transferred");

    if (nerr == 0) $display("RESULT: PASS");
    else           $display("RESULT: FAIL");
    $finish;
  end

endmodule