// ===========================================================================
// frame_arb_mux_tb.sv
//
// Self-checking testbench for the framed stream multiplexer, written against
// the specification only.
//
// HOW IT DECIDES
//   * One posedge monitor holds every check.  It folds each input beat into a
//     per-input FIFO model BEFORE it judges an output beat in the same cycle,
//     so a design with zero latency is handled exactly like a deeply pipelined
//     one (S11, out-of-scope 2).
//   * An output beat is attributed to its input by a GLOBALLY UNIQUE tag that
//     the driver puts in tdata -- (input index, sequence number).  No value is
//     ever reused, so a match is bookkeeping, not ambiguous content matching.
//     There is no selection output and none is inferred from s_tready_o (S6).
//   * Frame atomicity (S3) is tracked by remembering which input owns the
//     output frame currently in progress; order (S4) by requiring the matched
//     beat to be at the HEAD of its input's FIFO; loss and duplication (S5) by
//     what is left in the FIFOs at a drain and by output beats whose tag
//     matches nothing outstanding.
//   * Every wait is bounded, so a design that never selects an input produces a
//     verdict rather than a hang.
//
// WHAT IT DELIBERATELY DOES NOT CHECK
//   * Selection order and any policy behind it (S9, out-of-scope 1) -- only
//     S10's 16-frame window, over sliding windows of the observed frame
//     sources.
//   * Latency (S11), promptness of s_tready_o (out-of-scope 3): a low ready is
//     never treated as an error, only a total absence of forward progress.
//   * m_tdata_o / m_tkeep_o / m_tuser_o while m_tvalid_o is low (out-of-scope
//     4) -- they are read only on a transfer.
//   * Whether a new frame starts in the same cycle the previous tlast
//     transfers, or how many idle cycles separate frames (out-of-scope 5).
//   * Internal structure (out-of-scope 6) and any particular tkeep pattern
//     (out-of-scope 7) -- tkeep is only ever compared with what was presented.
//   * A frame abandoned at the source (S5a): the drain check flags only beats
//     of frames whose tlast beat has actually transferred.
//
// NOTE ON THE PROVIDED PLUMBING.  Clock, reset and watchdog are kept verbatim.
// bfm_send, bfm_idle and bfm_ready are replaced, for two reasons that the task
// itself states: bfm_send's acceptance loop is `forever`, which is exactly the
// hang the termination requirement forbids against a design that never selects
// an input; and driving four inputs concurrently needs a per-input driver
// process rather than one blocking call.  The replacements keep the plumbing's
// timing discipline exactly -- present at the falling edge, sample at the
// rising edge -- and they never withdraw an offer, so S7 is respected even when
// a beat is never taken.  m_tready is driven from a single mode-controlled
// falling-edge block, because two processes driving it would race.
// ===========================================================================

module frame_arb_mux_tb;

  localparam int S_COUNT    = 4;
  localparam int DATA_WIDTH = 32;
  localparam int USER_WIDTH = 1;
  localparam int KEEP_W     = DATA_WIDTH/8;

  localparam int QD         = 8192;   // per-input model depth
  localparam int FAIR_WIN   = 16;     // S10 window
  localparam int HIST_N     = 512;    // recorded frame sources

  // ---------------------------------------------------------------------------
  // PROVIDED PLUMBING -- clock, reset, watchdog.
  // ---------------------------------------------------------------------------
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

  // ---- watchdog --------------------------------------------------------------
  initial begin
    #20_000_000;
    $display("RESULT: FAIL (watchdog: no forward progress)");
    $finish;
  end

  // ---- signals and the design under test -------------------------------------
  logic [S_COUNT-1:0][DATA_WIDTH-1:0] s_tdata;
  logic [S_COUNT-1:0][KEEP_W-1:0]     s_tkeep;
  logic [S_COUNT-1:0]                 s_tvalid;
  logic [S_COUNT-1:0]                 s_tready;
  logic [S_COUNT-1:0]                 s_tlast;
  logic [S_COUNT-1:0][USER_WIDTH-1:0] s_tuser;
  logic [DATA_WIDTH-1:0]              m_tdata;
  logic [KEEP_W-1:0]                  m_tkeep;
  logic                               m_tvalid;
  logic                               m_tready;
  logic                               m_tlast;
  logic [USER_WIDTH-1:0]              m_tuser;

  frame_arb_mux #(
    .S_COUNT(S_COUNT), .DATA_WIDTH(DATA_WIDTH), .USER_WIDTH(USER_WIDTH)
  ) dut (
    .clk_i(clk), .rst_i(rst),
    .s_tdata_i(s_tdata), .s_tkeep_i(s_tkeep), .s_tvalid_i(s_tvalid),
    .s_tready_o(s_tready), .s_tlast_i(s_tlast), .s_tuser_i(s_tuser),
    .m_tdata_o(m_tdata), .m_tkeep_o(m_tkeep), .m_tvalid_o(m_tvalid),
    .m_tready_i(m_tready), .m_tlast_o(m_tlast), .m_tuser_o(m_tuser)
  );

  // ===========================================================================
  // VERDICT BOOKKEEPING
  // ===========================================================================
  int err_cnt = 0;
  int msg_cnt = 0;
  bit abort_all = 1'b0;

  task automatic fail(input string cl, input string msg);
    err_cnt = err_cnt + 1;
    if (msg_cnt < 40) begin
      msg_cnt = msg_cnt + 1;
      $display("VIOLATION [%s] t=%0t : %s", cl, $time, msg);
    end
    if (err_cnt == 60) begin
      $display("SUMMARY: stopping after %0d violations", err_cnt);
      $display("RESULT: FAIL");
      $finish;
    end
  endtask

  // ===========================================================================
  // THE MODEL -- one FIFO per input, of beats that have transferred there
  // ===========================================================================
  typedef struct packed {
    logic [DATA_WIDTH-1:0] data;
    logic [KEEP_W-1:0]     keep;
    logic [USER_WIDTH-1:0] user;
    logic                  last;
    logic [15:0]           fid;
    logic [15:0]           bidx;
  } beat_t;

  beat_t iq_mem [S_COUNT][QD];
  int    iq_h   [S_COUNT];
  int    iq_t   [S_COUNT];
  int    in_fid [S_COUNT];
  int    in_bidx[S_COUNT];
  int    in_beats [S_COUNT];

  int  cur_src = -1;          // input owning the output frame in progress (S3)
  int  out_frames = 0;        // completed output frames
  int  out_beats = 0;

  // S10 history
  bit  fair_rec = 1'b0;
  int  fair_hist [HIST_N];
  int  fair_n = 0;

  // reset checking
  bit  s12_win = 1'b0;        // nothing may appear on the output in this window
  int  rst_edges = 0;
  bit  saw_release = 1'b0;

  function automatic int qsize(input int k);
    return iq_t[k] - iq_h[k];
  endfunction

  function automatic beat_t qget(input int k, input int i);
    return iq_mem[k][(iq_h[k] + i) % QD];
  endfunction

  // Does input k still hold a beat belonging to a frame whose tlast beat has
  // already transferred?  Only those are covered by S5; a partial frame the
  // source abandoned is not (S5a).
  function automatic bit has_complete_pending(input int k);
    for (int i = 0; i < qsize(k); i++)
      if (qget(k, i).last) return 1'b1;
    return 1'b0;
  endfunction

  task automatic find_tag(input logic [DATA_WIDTH-1:0] d,
                          output int src, output int pos);
    src = -1;
    pos = -1;
    for (int k = 0; k < S_COUNT; k++)
      for (int i = 0; i < qsize(k); i++)
        if (qget(k, i).data === d) begin
          src = k;
          pos = i;
          return;
        end
  endtask

  // ===========================================================================
  // THE MONITOR
  // ===========================================================================
  always @(posedge clk) begin
    if (rst) begin
      // S12: reset returns the design to idle and discards everything in it.
      for (int k = 0; k < S_COUNT; k++) begin
        iq_h[k] = 0; iq_t[k] = 0; in_fid[k] = 0; in_bidx[k] = 0;
      end
      cur_src = -1;
      rst_edges <= rst_edges + 1;
      // Judged from the second rising edge in reset: reset is synchronous, so
      // the first edge is the one that clears the design.
      if (rst_edges >= 1 && m_tvalid === 1'b1)
        fail("S12", "m_tvalid_o is high while rst_i is high; reset must return the design to an idle state");
      saw_release <= 1'b1;
    end else begin
      automatic beat_t e;
      automatic int fsrc, fpos;
      automatic beat_t nb;

      // S12: on the first cycle after release m_tvalid_o shall be low
      if (saw_release) begin
        if (m_tvalid === 1'b1)
          fail("S12", "m_tvalid_o is high on the first cycle after rst_i was released");
        saw_release <= 1'b0;
      end
      rst_edges <= 0;

      // S12: in a declared quiet window nothing may appear on the output
      if (s12_win && m_tvalid === 1'b1)
        fail("S12", "a beat appeared on the output after reset; no beat that transferred before or during reset may appear afterwards");

      // ---- 1. input beats transfer (S1) ----------------------------------
      for (int k = 0; k < S_COUNT; k++) begin
        if (s_tvalid[k] === 1'b1 && s_tready[k] === 1'b1) begin
          if (qsize(k) >= QD - 2) begin
            fail("S5", $sformatf("input %0d has accepted more than %0d beats without them appearing on the output", k, QD - 2));
            abort_all = 1'b1;
          end else begin
            nb.data = s_tdata[k];
            nb.keep = s_tkeep[k];
            nb.user = s_tuser[k];
            nb.last = s_tlast[k];
            nb.fid  = 16'(in_fid[k]);
            nb.bidx = 16'(in_bidx[k]);
            iq_mem[k][iq_t[k] % QD] = nb;
            iq_t[k] = iq_t[k] + 1;
            in_beats[k] = in_beats[k] + 1;
            if (s_tlast[k] === 1'b1) begin
              in_fid[k]  = in_fid[k] + 1;
              in_bidx[k] = 0;
            end else begin
              in_bidx[k] = in_bidx[k] + 1;
            end
          end
        end
      end

      // ---- 2. an output beat transfers (S1) ------------------------------
      if (m_tvalid === 1'b1 && m_tready === 1'b1) begin
        out_beats = out_beats + 1;
        find_tag(m_tdata, fsrc, fpos);
        if (fsrc < 0) begin
          // Nothing outstanding carries this tag.  Either the payload was
          // altered, or the beat was already emitted, or it was invented.
          if (cur_src >= 0 && qsize(cur_src) > 0)
            fail("S4", $sformatf("output beat carries tdata=%08h; the next beat owed by the frame in progress (input %0d) carries %08h",
                                 m_tdata, cur_src, qget(cur_src, 0).data));
          else
            fail("S5", $sformatf("output beat carries tdata=%08h, which matches no input beat that has transferred and not yet been emitted (duplicated, invented or altered)",
                                 m_tdata));
          if (m_tlast === 1'b1) begin
            cur_src = -1;
            out_frames = out_frames + 1;
          end
        end else if (cur_src >= 0 && fsrc != cur_src) begin
          fail("S3", $sformatf("output beat comes from input %0d while the frame in progress belongs to input %0d; no other input's beat may transfer between the first and last beat of a frame",
                               fsrc, cur_src));
          cur_src = -1;
        end else if (fpos != 0) begin
          fail("S4", $sformatf("output beat from input %0d is that input's beat %0d of the queue, not the oldest one still owed; beats must appear in the order they transferred",
                               fsrc, fpos));
          // consume it anyway so the model does not cascade
          iq_h[fsrc] = iq_h[fsrc] + 1;
        end else begin
          e = qget(fsrc, 0);
          iq_h[fsrc] = iq_h[fsrc] + 1;
          if (cur_src < 0) cur_src = fsrc;
          // S4: payload complete and unmodified
          if (m_tkeep !== e.keep)
            fail("S4", $sformatf("output beat (input %0d frame %0d beat %0d) carries tkeep=%04b, the input beat carried %04b",
                                 fsrc, e.fid, e.bidx, m_tkeep, e.keep));
          if (m_tuser !== e.user)
            fail("S4", $sformatf("output beat (input %0d frame %0d beat %0d) carries tuser=%0b, the input beat carried %0b",
                                 fsrc, e.fid, e.bidx, m_tuser, e.user));
          // S4: tlast marks exactly the beats that carried s_tlast_i
          if (m_tlast !== e.last)
            fail("S4", $sformatf("output beat (input %0d frame %0d beat %0d) has m_tlast_o=%0b, the input beat had s_tlast_i=%0b",
                                 fsrc, e.fid, e.bidx, m_tlast, e.last));
          if (m_tlast === 1'b1 || e.last === 1'b1) begin
            out_frames = out_frames + 1;
            if (fair_rec && fair_n < HIST_N) begin
              fair_hist[fair_n] = cur_src;
              fair_n = fair_n + 1;
            end
            cur_src = -1;
          end
        end
      end
    end
  end

  // ===========================================================================
  // OUR READINESS -- single driver, changed only at the falling edge (S8)
  // ===========================================================================
  int          rdy_mode = 0;    // 0 = always ready, 1 = random, 2 = held low
  int unsigned lf_rdy = 32'h0BAD_F00D;

  function automatic int unsigned nxt(input int unsigned x);
    automatic int unsigned y = x;
    y = y ^ (y << 13);
    y = y ^ (y >> 17);
    y = y ^ (y << 5);
    return y;
  endfunction

  always @(negedge clk) begin
    lf_rdy = nxt(lf_rdy);
    case (rdy_mode)
      0:       m_tready = 1'b1;
      1:       m_tready = (lf_rdy[0] | lf_rdy[1]);   // ready ~75% of cycles
      default: m_tready = 1'b0;
    endcase
  end

  // ===========================================================================
  // INPUT DRIVERS -- one process per input, so all four can offer at once
  // ===========================================================================
  bit          drv_run  [S_COUNT];
  bit          drv_busy [S_COUNT];
  int          drv_done [S_COUNT];
  int unsigned lf_drv   [S_COUNT];
  int          seq_no   [S_COUNT];
  localparam int SEND_LIMIT = 40000;

  // Offers one beat and returns once it has transferred.  If it is never taken
  // the offer is LEFT STANDING -- withdrawing it would violate S7, and a low
  // ready is not an error (out-of-scope 3).
  task automatic send_beat(input int k, input bit last, output bit took);
    automatic logic [DATA_WIDTH-1:0] d;
    automatic logic [KEEP_W-1:0]     kp;
    automatic logic [USER_WIDTH-1:0] us;
    automatic int t;
    took = 1'b0;
    seq_no[k] = seq_no[k] + 1;
    d  = {8'(k), 24'(seq_no[k])};              // globally unique tag
    kp = KEEP_W'(seq_no[k]) | KEEP_W'(1);
    us = USER_WIDTH'(seq_no[k]);
    @(negedge clk);
    s_tdata[k]  = d;
    s_tkeep[k]  = kp;
    s_tlast[k]  = last;
    s_tuser[k]  = us;
    s_tvalid[k] = 1'b1;
    for (t = 0; t < SEND_LIMIT; t++) begin
      @(posedge clk);
      if (s_tready[k] === 1'b1) begin took = 1'b1; break; end
      if (abort_all) break;
    end
  endtask

  // As send_beat, but gives up after `limit` cycles.  Used only where the
  // point of the phase is what the design is HOLDING, so a design that cannot
  // take the beat at all (because it has no buffering) simply holds nothing.
  task automatic send_beat_lim(input int k, input bit last, input int limit,
                               output bit took);
    automatic logic [DATA_WIDTH-1:0] d;
    automatic logic [KEEP_W-1:0]     kp;
    automatic logic [USER_WIDTH-1:0] us;
    automatic int t;
    took = 1'b0;
    seq_no[k] = seq_no[k] + 1;
    d  = {8'(k), 24'(seq_no[k])};
    kp = KEEP_W'(seq_no[k]) | KEEP_W'(1);
    us = USER_WIDTH'(seq_no[k]);
    @(negedge clk);
    s_tdata[k]  = d;
    s_tkeep[k]  = kp;
    s_tlast[k]  = last;
    s_tuser[k]  = us;
    s_tvalid[k] = 1'b1;
    for (t = 0; t < limit; t++) begin
      @(posedge clk);
      if (s_tready[k] === 1'b1) begin took = 1'b1; break; end
    end
  endtask

  task automatic stop_offering(input int k);
    @(negedge clk);
    s_tvalid[k] = 1'b0;
  endtask

  task automatic send_frame(input int k, input int len);
    automatic bit took;
    drv_busy[k] = 1'b1;
    for (int i = 0; i < len; i++) begin
      send_beat(k, (i == len - 1), took);
      if (!took) begin drv_busy[k] = 1'b0; return; end
    end
    drv_done[k] = drv_done[k] + 1;
    drv_busy[k] = 1'b0;
  endtask

  // drv_run is only sampled between frames, so stopping a driver never leaves
  // a frame half sent unless a beat was never taken.
  task automatic drv_proc(input int k);
    forever begin
      @(negedge clk);
      if (abort_all) return;
      if (drv_run[k]) begin
        automatic int len;
        lf_drv[k] = nxt(lf_drv[k]);
        len = 1 + int'(lf_drv[k] % 6);
        send_frame(k, len);
      end
    end
  endtask

  initial drv_proc(0);
  initial drv_proc(1);
  initial drv_proc(2);
  initial drv_proc(3);

  // ===========================================================================
  // SEQUENCER HELPERS
  // ===========================================================================
  task automatic wait_cycles(input int n);
    repeat (n) @(posedge clk);
  endtask

  task automatic run_all(input bit v);
    @(negedge clk);
    for (int k = 0; k < S_COUNT; k++) drv_run[k] = v;
  endtask

  // Stop offering on every input, once no driver is part way through a frame.
  // Only ever called when the last beat offered has already transferred, so no
  // offer is ever withdrawn (S7).
  task automatic idle_all();
    automatic int t;
    automatic bit busy;
    for (t = 0; t < 3000; t++) begin
      @(negedge clk);
      busy = 1'b0;
      for (int k = 0; k < S_COUNT; k++) if (drv_busy[k]) busy = 1'b1;
      if (!busy) break;
      if (abort_all) break;
    end
    @(negedge clk);
    for (int k = 0; k < S_COUNT; k++) s_tvalid[k] = 1'b0;
  endtask

  // Wait, bounded, until nothing owed remains, then judge S5 / S8.
  task automatic drain_check(input string ctx);
    automatic int t;
    automatic bit pend;
    rdy_mode = 0;
    for (t = 0; t < 4000; t++) begin
      @(negedge clk);
      pend = 1'b0;
      for (int k = 0; k < S_COUNT; k++) if (has_complete_pending(k)) pend = 1'b1;
      if (cur_src >= 0) pend = 1'b1;
      if (!pend) break;
      if (abort_all) break;
    end
    for (int k = 0; k < S_COUNT; k++)
      if (has_complete_pending(k))
        fail("S5", $sformatf("%s: input %0d still holds %0d beat(s) of a frame whose s_tlast_i beat has transferred; every beat of a completed frame must appear on the output",
                             ctx, k, qsize(k)));
    if (cur_src >= 0)
      fail("S8", $sformatf("%s: a frame from input %0d was begun on the output and never finished", ctx, cur_src));
  endtask

  // ===========================================================================
  // THE RUN
  // ===========================================================================
  initial begin
    automatic bit took;
    automatic int i, k, t, f0;
    automatic bit seen [S_COUNT];

    for (k = 0; k < S_COUNT; k++) begin
      s_tvalid[k] = 1'b0;
      s_tdata[k]  = '0;
      s_tkeep[k]  = '0;
      s_tlast[k]  = 1'b0;
      s_tuser[k]  = '0;
      drv_run[k]  = 1'b0;
      drv_done[k] = 0;
      seq_no[k]   = 0;
      in_beats[k] = 0;
      lf_drv[k]   = 32'h1000_0001 + 32'(k) * 32'h3B9A_C9FF;
    end
    rdy_mode = 0;

    // ---- S12: reset, and idle immediately after -------------------------
    bfm_reset(8);
    s12_win = 1'b1;
    wait_cycles(20);
    @(negedge clk);
    s12_win = 1'b0;

    // ---- S2: single-beat frames -----------------------------------------
    for (i = 0; i < 3; i++) send_frame(0, 1);
    idle_all();
    drain_check("single-beat frames");

    // ---- S2/S4: multi-beat frames on one input ---------------------------
    send_frame(0, 2);
    send_frame(0, 5);
    send_frame(0, 1);
    send_frame(0, 3);
    idle_all();
    drain_check("multi-beat frames on one input");

    // ---- S3: one frame from each input, offered in turn ------------------
    for (k = 0; k < S_COUNT; k++) begin
      send_frame(k, 1 + k);
      stop_offering(k);
    end
    idle_all();
    drain_check("one frame from each input");

    // ---- S3/S5: all four inputs offering at once -------------------------
    run_all(1'b1);
    f0 = out_frames;
    for (t = 0; t < 6000; t++) begin
      @(negedge clk);
      if (out_frames - f0 >= 60) break;
    end
    if (out_frames - f0 < 60)
      fail("S5", $sformatf("only %0d frames completed on the output in 6000 cycles with all four inputs offering", out_frames - f0));
    run_all(1'b0);
    idle_all();
    drain_check("four inputs at once");

    // ---- S8: backpressure ------------------------------------------------
    run_all(1'b1);
    rdy_mode = 1;                       // random m_tready
    f0 = out_frames;
    for (t = 0; t < 12000; t++) begin
      @(negedge clk);
      if (out_frames - f0 >= 60) break;
    end
    if (out_frames - f0 < 60)
      fail("S8", $sformatf("only %0d frames completed on the output in 12000 cycles under random backpressure", out_frames - f0));
    // a long stretch with m_tready low, including mid-frame
    rdy_mode = 2;
    wait_cycles(60);
    rdy_mode = 0;
    wait_cycles(40);
    run_all(1'b0);
    idle_all();
    drain_check("backpressure");

    // ---- S10: bounded fairness ------------------------------------------
    // Continuous offered load on every input, m_tready high throughout.
    rdy_mode = 0;
    run_all(1'b1);
    wait_cycles(40);                    // let the load become continuous
    @(negedge clk);
    fair_n = 0;
    fair_rec = 1'b1;
    for (t = 0; t < 8000; t++) begin
      @(negedge clk);
      if (fair_n >= 200) break;
    end
    @(negedge clk);
    fair_rec = 1'b0;
    run_all(1'b0);
    if (fair_n < FAIR_WIN + 4) begin
      fail("S10", $sformatf("only %0d frames completed in 8000 cycles of continuous offered load on all four inputs; fairness cannot be judged and the design is not making progress", fair_n));
    end else begin
      automatic bit reported = 1'b0;
      for (i = 0; i + FAIR_WIN <= fair_n; i++) begin
        for (k = 0; k < S_COUNT; k++) seen[k] = 1'b0;
        for (t = 0; t < FAIR_WIN; t++) seen[fair_hist[i+t]] = 1'b1;
        for (k = 0; k < S_COUNT; k++)
          if (!seen[k] && !reported) begin
            fail("S10", $sformatf("input %0d began no frame in the %0d consecutive completed output frames starting at frame %0d, with all four inputs offering continuously and m_tready_i high",
                                  k, FAIR_WIN, i));
            reported = 1'b1;
          end
      end
    end
    idle_all();
    drain_check("fairness");

    // ---- S5a: a frame abandoned at the source ----------------------------
    // Two beats of a frame transfer and the source then stops.  The design may
    // hold them indefinitely or emit them; neither is a loss, and the drain
    // check must not read it as one.
    send_beat(1, 1'b0, took);
    send_beat(1, 1'b0, took);
    stop_offering(1);
    wait_cycles(60);
    for (k = 0; k < S_COUNT; k++)
      if (has_complete_pending(k))
        fail("S5", $sformatf("a completed frame is owed on input %0d while a partial frame is held", k));
    // now complete the frame; all four beats must appear, in order
    send_beat(1, 1'b0, took);
    send_beat(1, 1'b1, took);
    stop_offering(1);
    drain_check("frame completed after being held");

    // ---- S12: reset while the design is holding beats --------------------
    // The sink stalls first, so a design that buffers its inputs is holding
    // those beats when reset arrives -- which is the only way to see whether
    // reset discards them.  A design that buffers nothing simply never takes
    // them, and the phase is then vacuous rather than wrong.
    rdy_mode = 2;
    send_beat_lim(2, 1'b0, 40, took);
    send_beat_lim(2, 1'b0, 40, took);
    wait_cycles(5);
    // Reset is asserted first and the offer withdrawn only while it is high, so
    // no live design ever sees an offer withdrawn (S7) and the first cycle after
    // release is quiet -- which it must be, since a zero-latency design would
    // otherwise be obliged to assert m_tvalid_o in exactly that cycle.
    @(negedge clk);
    rst = 1'b1;
    @(negedge clk);
    s_tvalid[2] = 1'b0;
    repeat (8) @(posedge clk);
    @(negedge clk);
    rst = 1'b0;
    rdy_mode = 0;
    s12_win = 1'b1;
    wait_cycles(40);
    @(negedge clk);
    s12_win = 1'b0;

    // ---- and the design still works afterwards ---------------------------
    for (k = 0; k < S_COUNT; k++) begin
      send_frame(k, 2 + k);
      stop_offering(k);
    end
    idle_all();
    drain_check("after reset");

    // ---- verdict ---------------------------------------------------------
    $display("SUMMARY: %0d output beats in %0d frames, %0d input beats offered, %0d violations",
             out_beats, out_frames, in_beats[0] + in_beats[1] + in_beats[2] + in_beats[3], err_cnt);
    if (out_beats == 0)
      fail("S5", "not a single beat ever appeared on the output");
    abort_all = 1'b1;
    if (err_cnt == 0) $display("RESULT: PASS");
    else              $display("RESULT: FAIL");
    $finish;
  end

endmodule