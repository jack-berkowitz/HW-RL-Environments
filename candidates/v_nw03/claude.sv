// ===========================================================================
// frame_arb_mux_tb.sv -- specification-driven testbench for frame_arb_mux
//
// There is no selection output and S6 forbids inferring one from s_tready_o, so
// every output beat is attributed by BOOKKEEPING: each beat is given a tdata
// value that is unique for the whole run (a bijection of a global counter), and
// the checker looks that value up among the per-input queues of beats that have
// actually transferred on the inputs.  Nothing here reads s_tready_o as a grant.
//
// Checks:  S2  a frame may be a single beat -- exercised, not assumed
//          S3  frame atomicity: no other input's beat between first and last
//          S4  tdata/tkeep/tuser forwarded unmodified, per-input order kept,
//              m_tlast_o high on exactly the beats that carried s_tlast_i
//          S5  every beat of a completed input frame appears exactly once
//          S5a a frame abandoned at the source is NOT counted as a loss
//          S8  none of the above changes under arbitrary back-pressure
//          S10 every input begins a frame within any 16 completed frames
//          S12 reset: m_tvalid_o low after release, and nothing from before
//              reset appears afterwards
//
// Deliberately NOT checked: which input is selected and on what basis (S9),
// latency (S11), promptness of s_tready_o, the payload while m_tvalid_o is low,
// whether frames may abut on the output, and any pattern on tkeep.
// ===========================================================================
module frame_arb_mux_tb;

  localparam int S_COUNT    = 4;
  localparam int DATA_WIDTH = 32;
  localparam int USER_WIDTH = 1;
  localparam int KEEP_W     = DATA_WIDTH/8;

  // -------------------------------------------------------------------------
  // signals -- packed, matching the port declarations exactly
  // -------------------------------------------------------------------------
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

  // -------------------------------------------------------------------------
  // PROVIDED PLUMBING -- moves beats, checks nothing.
  // -------------------------------------------------------------------------
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

  // -------------------------------------------------------------------------
  // DUT
  // -------------------------------------------------------------------------
  frame_arb_mux #(
      .S_COUNT(S_COUNT), .DATA_WIDTH(DATA_WIDTH), .USER_WIDTH(USER_WIDTH)
  ) dut (
      .clk_i(clk), .rst_i(rst),
      .s_tdata_i(s_tdata), .s_tkeep_i(s_tkeep), .s_tvalid_i(s_tvalid),
      .s_tready_o(s_tready), .s_tlast_i(s_tlast), .s_tuser_i(s_tuser),
      .m_tdata_o(m_tdata), .m_tkeep_o(m_tkeep), .m_tvalid_o(m_tvalid),
      .m_tready_i(m_tready), .m_tlast_o(m_tlast), .m_tuser_o(m_tuser));

  int cyc = 0;
  always @(posedge clk) if (!rst) cyc <= cyc + 1;

  // -------------------------------------------------------------------------
  // bookkeeping
  // -------------------------------------------------------------------------
  int    errs = 0;
  string phase_name = "startup";

  task automatic oops(input string req_id, input string msg);
    errs = errs + 1;
    if (errs <= 20)
      $display("FAIL [%s] cycle %0d, phase '%s': %s", req_id, cyc, phase_name, msg);
    if (errs == 21) $display("... further diagnostics suppressed");
  endtask

  typedef struct packed {
    logic [DATA_WIDTH-1:0] data;
    logic [KEEP_W-1:0]     keep;
    logic [USER_WIDTH-1:0] user;
    logic                  last;
  } beat_t;

  beat_t inq [S_COUNT][$];          // beats that transferred in, awaiting output
  bit    partial [S_COUNT];         // an unterminated frame is in flight (S5a)
  bit    forbidden [logic [DATA_WIDTH-1:0]];   // discarded by reset (S12)

  int  cur_src   = -1;              // output frame in progress, -1 if none
  bit  mid_frame = 1'b0;
  int  out_beats = 0, out_frames = 0;

  int  frame_src [$];               // sources of completed output frames (S10)
  bit  fair_collect = 1'b0;

  // unique payload generator: gseq * odd constant is a bijection on 32 bits, so
  // no two beats in the whole run ever carry the same tdata
  int  gseq = 0;
  function automatic logic [DATA_WIDTH-1:0] next_data();
    gseq = gseq + 1;
    return DATA_WIDTH'(32'(gseq) * 32'h9E37_79B9);
  endfunction

  int lfsr = 32'h1357_9BDF;
  function automatic int rnd();
    lfsr = (lfsr * 32'd1103515245 + 32'd12345);
    return (lfsr >>> 8) & 32'h00FF_FFFF;
  endfunction

  // -------------------------------------------------------------------------
  // MONITOR
  //   input transfers are recorded first, so a design with zero latency that
  //   forwards a beat in the cycle it arrives is handled correctly.
  // -------------------------------------------------------------------------
  always @(posedge clk) begin
    automatic beat_t b, e;
    automatic int    owner, deep;

    if (rst) begin
      // S12: everything taken in before or during reset is discarded, and must
      // not appear on the output afterwards
      for (int k = 0; k < S_COUNT; k++) begin
        while (inq[k].size() > 0) begin
          b = inq[k].pop_front();
          forbidden[b.data] = 1'b1;
        end
        partial[k] = 1'b0;
      end
      cur_src   = -1;
      mid_frame = 1'b0;
    end else begin
      // ---- input beats (S1)
      for (int k = 0; k < S_COUNT; k++)
        if (s_tvalid[k] === 1'b1 && s_tready[k] === 1'b1) begin
          b.data = s_tdata[k];
          b.keep = s_tkeep[k];
          b.user = s_tuser[k];
          b.last = s_tlast[k];
          inq[k].push_back(b);
          partial[k] = !b.last;
        end

      // ---- output beat (S1)
      if (m_tvalid === 1'b1 && m_tready === 1'b1) begin
        out_beats = out_beats + 1;
        if (forbidden.exists(m_tdata) != 0) begin
          oops("S12", $sformatf(
            "output beat %08h transferred on an input before or during reset and must not appear afterwards",
            m_tdata));
        end else begin
          owner = -1;
          if (mid_frame) begin
            // S3: this beat must be the next beat of the frame in progress
            if (inq[cur_src].size() > 0 && inq[cur_src][0].data === m_tdata) begin
              owner = cur_src;
            end else begin
              owner = -1;
              for (int k = 0; k < S_COUNT; k++)
                if (owner < 0 && inq[k].size() > 0 && inq[k][0].data === m_tdata)
                  owner = k;
              if (owner >= 0)
                oops("S3", $sformatf(
                  "output beat %08h comes from input %0d while the frame from input %0d is still open",
                  m_tdata, owner, cur_src));
              else begin
                deep = -1;
                for (int k = 0; k < S_COUNT; k++)
                  for (int i = 1; i < inq[k].size(); i++)
                    if (deep < 0 && inq[k][i].data === m_tdata) deep = k;
                if (deep >= 0)
                  oops("S4", $sformatf(
                    "output beat %08h is out of order: input %0d has earlier beats still unsent",
                    m_tdata, deep));
                else
                  oops("S5", $sformatf(
                    "output beat %08h was never offered on any input, or has already been sent once",
                    m_tdata));
              end
            end
          end else begin
            // start of a frame: find the input whose next unsent beat this is
            for (int k = 0; k < S_COUNT; k++)
              if (owner < 0 && inq[k].size() > 0 && inq[k][0].data === m_tdata)
                owner = k;
            if (owner < 0) begin
              deep = -1;
              for (int k = 0; k < S_COUNT; k++)
                for (int i = 1; i < inq[k].size(); i++)
                  if (deep < 0 && inq[k][i].data === m_tdata) deep = k;
              if (deep >= 0)
                oops("S4", $sformatf(
                  "output beat %08h is out of order: input %0d has earlier beats still unsent",
                  m_tdata, deep));
              else
                oops("S5", $sformatf(
                  "output beat %08h was never offered on any input, or has already been sent once",
                  m_tdata));
            end
          end

          if (owner >= 0) begin
            e = inq[owner].pop_front();
            // S4: every field forwarded unmodified, across its full width
            if (m_tkeep !== e.keep)
              oops("S4", $sformatf("beat %08h: m_tkeep_o is %0h, the input carried %0h",
                                   m_tdata, m_tkeep, e.keep));
            if (m_tuser !== e.user)
              oops("S4", $sformatf("beat %08h: m_tuser_o is %0h, the input carried %0h",
                                   m_tdata, m_tuser, e.user));
            if (m_tlast !== e.last)
              oops("S4", $sformatf("beat %08h: m_tlast_o is %b, the input beat had s_tlast_i %b",
                                   m_tdata, m_tlast, e.last));
            if (e.last) begin
              mid_frame  = 1'b0;
              out_frames = out_frames + 1;
              if (fair_collect) frame_src.push_back(owner);
              cur_src = -1;
            end else begin
              mid_frame = 1'b1;
              cur_src   = owner;
            end
          end
        end
      end
    end
  end

  // -------------------------------------------------------------------------
  // input drivers, one process per input
  // -------------------------------------------------------------------------
  bit drv_run     [S_COUNT];
  bit drv_partial [S_COUNT];
  int drv_frames  [S_COUNT];

  for (genvar k = 0; k < S_COUNT; k++) begin : g_drv
    initial begin
      int nbeats, i;
      logic [DATA_WIDTH-1:0] d;
      logic [KEEP_W-1:0]     kp;
      drv_run[k]     = 1'b0;
      drv_partial[k] = 1'b0;
      drv_frames[k]  = 0;
      forever begin
        if (drv_partial[k]) begin
          // S5a: two beats of a frame that is never completed
          for (i = 0; i < 2; i++) begin
            d  = next_data();
            kp = KEEP_W'(d);
            bfm_send(k, d, kp, 1'b0, USER_WIDTH'(d[4]));
          end
          drv_partial[k] = 1'b0;
          bfm_idle(k);
        end else if (drv_run[k]) begin
          nbeats = 1 + (rnd() % 4);        // S2: length 1 is included
          for (i = 0; i < nbeats; i++) begin
            d  = next_data();
            kp = KEEP_W'(d);
            bfm_send(k, d, kp, (i == nbeats-1) ? 1'b1 : 1'b0, USER_WIDTH'(d[4]));
          end
          drv_frames[k] = drv_frames[k] + 1;
          if (!drv_run[k] && !drv_partial[k]) bfm_idle(k);
        end else begin
          @(negedge clk);
          s_tvalid[k] = 1'b0;
        end
      end
    end
  end

  // ---- output-side ready pattern (S8) ---------------------------------------
  int bp_mode = 0;                  // 0 = always ready, 1 = random, 2 = never
  initial begin
    m_tready = 1'b0;
    forever begin
      @(negedge clk);
      case (bp_mode)
        0:       m_tready = 1'b1;
        1:       m_tready = ((rnd() % 4) != 0) ? 1'b1 : 1'b0;
        2:       m_tready = 1'b0;
        default: m_tready = 1'b1;
      endcase
    end
  end

  // -------------------------------------------------------------------------
  // helpers
  // -------------------------------------------------------------------------
  task automatic set_phase(input string nm);
    @(negedge clk);
    phase_name = nm;
  endtask

  task automatic run_all(input bit on);
    @(negedge clk);
    for (int k = 0; k < S_COUNT; k++) drv_run[k] = on;
  endtask

  // Waits for the design to drain what it owes, then reports anything left.
  task automatic drain_and_check(input int budget);
    int t;
    bit quiet;
    bp_mode = 0;
    for (t = 0; t < budget; t++) begin
      @(posedge clk);
      quiet = 1'b1;
      for (int k = 0; k < S_COUNT; k++)
        if (inq[k].size() > 0) quiet = 1'b0;
      if (quiet) break;
    end
    @(negedge clk);
    for (int k = 0; k < S_COUNT; k++) begin
      automatic bit has_last = 1'b0;
      for (int i = 0; i < inq[k].size(); i++) if (inq[k][i].last) has_last = 1'b1;
      if (has_last)
        oops("S5", $sformatf(
          "input %0d has %0d beat(s) of a COMPLETED frame that never appeared on the output",
          k, inq[k].size()));
      else if (inq[k].size() > 0 && !partial[k])
        oops("S5", $sformatf("input %0d has %0d beat(s) that never appeared on the output",
                             k, inq[k].size()));
      // a partial frame still held is S5a and is not a failure
    end
  endtask

  // -------------------------------------------------------------------------
  // STIMULUS
  // -------------------------------------------------------------------------
  initial begin
    int nsrc;
    bit [S_COUNT-1:0] seen;

    for (int k = 0; k < S_COUNT; k++) begin
      s_tvalid[k] = 1'b0; s_tdata[k] = '0; s_tkeep[k] = '0;
      s_tlast[k] = 1'b0; s_tuser[k] = '0;
    end

    bfm_reset(4);

    // ---------------- S12: idle after reset --------------------------------
    set_phase("S12 state after reset is released");
    @(posedge clk);
    if (m_tvalid !== 1'b0)
      oops("S12", "m_tvalid_o is high on the first cycle after rst_i was released");

    // ---------------- S2/S4: one input at a time ---------------------------
    set_phase("S2/S4 single-beat and multi-beat frames, one input at a time");
    bp_mode = 0;
    for (int k = 0; k < S_COUNT; k++) begin
      @(negedge clk) drv_run[k] = 1'b1;
      repeat (60) @(posedge clk);
      @(negedge clk) drv_run[k] = 1'b0;
      drain_and_check(400);
    end
    if (out_frames < 4)
      oops("S5", $sformatf("only %0d frames reached the output from four inputs offering", out_frames));

    // ---------------- S3: all inputs contending ----------------------------
    set_phase("S3 four inputs contending, sink always ready");
    run_all(1'b1);
    repeat (400) @(posedge clk);
    run_all(1'b0);
    drain_and_check(2000);

    // ---------------- S8: arbitrary back-pressure --------------------------
    set_phase("S8 the same under random back-pressure");
    bp_mode = 1;
    run_all(1'b1);
    repeat (1500) @(posedge clk);
    run_all(1'b0);
    drain_and_check(4000);

    set_phase("S8 the sink stalled for a long stretch, then released");
    bp_mode = 2;
    run_all(1'b1);
    repeat (200) @(posedge clk);
    bp_mode = 0;
    repeat (400) @(posedge clk);
    run_all(1'b0);
    drain_and_check(4000);

    // ---------------- S10: bounded fairness --------------------------------
    set_phase("S10 every input begins a frame within any 16 completed frames");
    bp_mode = 0;
    run_all(1'b1);
    repeat (40) @(posedge clk);       // let the load become continuous
    frame_src.delete();
    fair_collect = 1'b1;
    for (int t = 0; t < 20000; t++) begin
      @(posedge clk);
      if (frame_src.size() >= 200) break;
    end
    fair_collect = 1'b0;
    run_all(1'b0);
    if (frame_src.size() < 64) begin
      oops("S10", $sformatf(
        "only %0d frames completed under continuous load from all four inputs; fairness cannot be met",
        frame_src.size()));
    end else begin
      for (int i = 0; i + 16 <= frame_src.size(); i++) begin
        seen = '0;
        for (int j = i; j < i + 16; j++) seen[frame_src[j]] = 1'b1;
        if (seen !== {S_COUNT{1'b1}}) begin
          for (int k = 0; k < S_COUNT; k++)
            if (!seen[k])
              oops("S10", $sformatf(
                "input %0d began no frame in the 16 completed frames %0d..%0d",
                k, i, i + 15));
          i = frame_src.size();       // one report is enough
        end
      end
    end
    drain_and_check(4000);

    // ---------------- S5a then S12 -----------------------------------------
    set_phase("S5a a frame abandoned at the source may be held indefinitely");
    @(negedge clk) drv_partial[2] = 1'b1;
    repeat (200) @(posedge clk);
    // nothing is owed here: the design may hold those beats forever
    for (int k = 0; k < S_COUNT; k++)
      if (k != 2 && inq[k].size() > 0)
        oops("S5", $sformatf("input %0d still holds beats that were not part of a partial frame", k));

    // Reset must also discard a beat the design is holding because the sink
    // refused it -- otherwise a stale beat reappears after release.
    set_phase("S12 reset while the sink is stalled and beats are held inside");
    bp_mode = 2;
    run_all(1'b1);
    repeat (60) @(posedge clk);
    run_all(1'b0);
    repeat (20) @(posedge clk);
    bfm_reset(4);
    @(posedge clk);
    if (m_tvalid !== 1'b0)
      oops("S12", "m_tvalid_o is high on the first cycle after rst_i was released");
    nsrc = out_frames;
    run_all(1'b1);
    repeat (400) @(posedge clk);
    run_all(1'b0);
    drain_and_check(2000);
    if (out_frames <= nsrc)
      oops("S5", "no frame reached the output after the reset");

    if (errs == 0) begin
      $display("checked %0d beats in %0d frames", out_beats, out_frames);
      $display("RESULT: PASS");
    end else begin
      $display("%0d failure(s); %0d beats in %0d frames", errs, out_beats, out_frames);
      $display("RESULT: FAIL");
    end
    $finish;
  end

endmodule