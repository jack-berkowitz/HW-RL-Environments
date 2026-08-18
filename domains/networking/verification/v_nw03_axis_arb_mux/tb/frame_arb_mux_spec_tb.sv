// =============================================================================
// frame_arb_mux_spec_tb.sv -- REFERENCE TESTBENCH for v_nw03. NEVER SHIPPED.
// =============================================================================
// Establishes the kill ceiling. Written against spec/frame_arb_mux_spec.md
// only; every check cites the clause it enforces, and no check rests on
// anything §7 declares out of scope.
//
// DRIVER DISCIPLINE (CONVENTIONS.md). All generator state is advanced with
// NONBLOCKING assignment from the clock edge that accepted a beat. A blocking
// assignment here would update the driven data in the same active region the
// design samples in, and the design would see the next beat instead of the one
// it accepted -- the exact race that made a correct DUT look inert on v_ca05.
//
// The output carries no source identifier -- the port map has none -- so the
// checker recovers a beat's origin from a tag the testbench itself placed in
// the LOW bits of tdata, then compares the FULL beat against that input's
// expectation. The tag is low on purpose: a design that corrupts high payload
// bits is then caught as a payload mismatch rather than becoming unattributable.
// =============================================================================

module frame_arb_mux_tb;

  // ---- scored configuration (spec §8) ---------------------------------------
  localparam int S  = 4;
  localparam int DW = 32;
  localparam int UW = 1;
  localparam int KW = DW/8;

  localparam int FAIR_WINDOW = 16;   // S10

  typedef struct packed {
    logic [DW-1:0] data;
    logic [KW-1:0] keep;
    logic [UW-1:0] user;
    logic          last;
  } beat_t;

  logic clk = 1'b0, rst = 1'b1;
  always #5 clk = ~clk;

  logic [S-1:0][DW-1:0] s_tdata;
  logic [S-1:0][KW-1:0] s_tkeep;
  logic [S-1:0]         s_tvalid, s_tready, s_tlast;
  logic [S-1:0][UW-1:0] s_tuser;

  logic [DW-1:0] m_tdata;
  logic [KW-1:0] m_tkeep;
  logic          m_tvalid, m_tlast;
  logic          m_tready = 1'b1;
  logic [UW-1:0] m_tuser;

  frame_arb_mux #(.S_COUNT(S), .DATA_WIDTH(DW), .USER_WIDTH(UW)) dut (
    .clk_i(clk), .rst_i(rst),
    .s_tdata_i(s_tdata), .s_tkeep_i(s_tkeep), .s_tvalid_i(s_tvalid),
    .s_tready_o(s_tready), .s_tlast_i(s_tlast), .s_tuser_i(s_tuser),
    .m_tdata_o(m_tdata), .m_tkeep_o(m_tkeep), .m_tvalid_o(m_tvalid),
    .m_tready_i(m_tready), .m_tlast_o(m_tlast), .m_tuser_o(m_tuser)
  );

  // ---- failure reporting ----------------------------------------------------
  int unsigned n_fail = 0;
  task automatic fail(input string clause, input string msg);
    n_fail = n_fail + 1;
    if (n_fail <= 50) $display("FAIL [%s] %s (t=%0t)", clause, msg, $time);
  endtask

  // ---- generator ------------------------------------------------------------
  logic [DW-1:0] cur_data [S];
  logic [KW-1:0] cur_keep [S];
  logic [UW-1:0] cur_user [S];
  logic          cur_last [S];
  int unsigned   cur_len  [S], cur_beat [S], seq [S], gap_cnt [S];

  logic  run_en       = 1'b0;   // offer beats at all
  logic  gap_en       = 1'b0;   // idle cycles between frames
  logic  force_single = 1'b0;   // drive the single-beat corner (S2)
  logic  drain_mode   = 1'b0;   // finish the frame in progress, then stop
  logic  done_f       [S];      // this input has reached a frame boundary
  string phase        = "init";

  // stimulus-side coverage only -- a correct design cannot score zero on any
  // of these, so none of them is gating a design choice (rule 4).
  int unsigned cov_single_frames = 0, cov_frames_in [S];
  int unsigned cov_stall_midframe = 0, cov_resets = 0;
  int unsigned cov_hi_payload = 0, cov_partial_keep = 0, cov_frames_phaseC = 0;

  for (genvar k = 0; k < S; k++) begin : g_drive
    assign s_tdata[k]  = cur_data[k];
    assign s_tkeep[k]  = cur_keep[k];
    assign s_tuser[k]  = cur_user[k];
    assign s_tlast[k]  = cur_last[k];
    assign s_tvalid[k] = run_en && !done_f[k] && (gap_cnt[k] == 0);
  end

  // Blocking form, used ONLY from the initial block at a negedge, where there
  // is no sampling edge to race.
  task automatic seed_beat(input int unsigned k);
    cur_len[k]  = force_single ? 1 : (1 + $urandom_range(0, 4));
    cur_beat[k] = 0;
    seq[k]      = seq[k] + 1;
    cur_data[k] = {16'($urandom), 12'(seq[k]), 4'(k)};
    cur_keep[k] = ($urandom_range(0, 3) == 0) ? KW'($urandom) : {KW{1'b1}};
    cur_user[k] = UW'($urandom);
    cur_last[k] = (cur_len[k] == 1);
    gap_cnt[k]  = 0;
  endtask

  // ---- scoreboard and checks ------------------------------------------------
  beat_t exp_q [S][$];
  int unsigned n_in [S], n_out [S];
  int unsigned since_start [S];       // completed frames since input k started one
  logic        fair_armed  = 1'b0;

  logic        owner_valid = 1'b0;
  int unsigned owner       = 0;
  int unsigned frames_out  = 0;
  // S10's frame-start detector is deliberately INDEPENDENT of S3's owner
  // tracking. Deriving it from owner_valid made an atomicity violation report
  // itself as a fairness violation: interleaving keeps owner_valid asserted, no
  // start is ever registered, and every input's counter runs away. One defect,
  // reported against the wrong clause.
  logic        prev_last   = 1'b1;
  // Beats the design had taken in when reset was asserted. S12 says none of
  // them may appear afterwards; keeping them lets the checker NAME that clause
  // instead of reporting the resulting misalignment as a payload mismatch.
  logic [DW-1:0] discarded [$];

  always @(posedge clk) begin
    if (rst) begin
      prev_last <= 1'b1;
      // S12: the design discards everything in flight, so the model must too.
      // Clearing here is what makes a surviving pre-reset beat surface as an
      // output beat with no expectation behind it.
      for (int k = 0; k < S; k++) begin
        while (exp_q[k].size() > 0) discarded.push_back(exp_q[k].pop_front().data);
      end
      owner_valid <= 1'b0;
    end else begin

      // ---- input side: record what the design took ---------------------------
      for (int k = 0; k < S; k++) begin
        if (s_tvalid[k] && s_tready[k]) begin
          automatic beat_t b;
          b.data = cur_data[k]; b.keep = cur_keep[k];
          b.user = cur_user[k]; b.last = cur_last[k];
          exp_q[k].push_back(b);
          n_in[k] = n_in[k] + 1;
          if (cur_last[k]) begin
            cov_frames_in[k] = cov_frames_in[k] + 1;
            if (cur_len[k] == 1) cov_single_frames = cov_single_frames + 1;
            // Quiesce on a FRAME BOUNDARY -- now required by S5a. Dropping
            // valid mid-frame leaves the design holding an incomplete frame,
            // which it is entitled to keep waiting on.
            //
            // This comment used to call that "a testbench defect". THAT WAS
            // WRONG: an independent submission hit the identical wall, so the
            // omission was in the specification. S5 is now qualified and S5a
            // states the case explicitly.
            if (drain_mode) done_f[k] <= 1'b1;
          end

          // ---- advance the generator, NONBLOCKING (see header) --------------
          begin
            automatic int unsigned nbeat = cur_beat[k] + 1;
            automatic int unsigned nlen  = cur_len[k];
            automatic int unsigned nseq  = seq[k] + 1;
            automatic logic [DW-1:0] ndata;
            automatic logic [KW-1:0] nkeep;
            automatic logic [UW-1:0] nuser;
            if (nbeat >= nlen) begin              // frame done, start another
              nlen  = force_single ? 1 : (1 + $urandom_range(0, 4));
              nbeat = 0;
              gap_cnt[k] <= gap_en ? $urandom_range(0, 3) : 0;
            end
            ndata = {16'($urandom), 12'(nseq), 4'(k)};
            nkeep = ($urandom_range(0, 3) == 0) ? KW'($urandom) : {KW{1'b1}};
            nuser = UW'($urandom);
            cur_len[k]  <= nlen;
            cur_beat[k] <= nbeat;
            seq[k]      <= nseq;
            cur_data[k] <= ndata;
            cur_keep[k] <= nkeep;
            cur_user[k] <= nuser;
            cur_last[k] <= (nbeat == nlen - 1);
            if (|ndata[DW-1:16])     cov_hi_payload   = cov_hi_payload + 1;
            if (nkeep != {KW{1'b1}}) cov_partial_keep = cov_partial_keep + 1;
          end
        end else if (gap_cnt[k] != 0) begin
          gap_cnt[k] <= gap_cnt[k] - 1;
        end
      end

      // ---- output side -------------------------------------------------------
      if (m_tvalid && m_tready) begin
        automatic int unsigned src = m_tdata[3:0];
        automatic beat_t e;
        automatic int di = -1;
        for (int j = 0; j < discarded.size(); j++)
          if (di < 0 && discarded[j] === m_tdata) di = j;
        if (di >= 0) begin
          fail("S12", $sformatf("beat %h was taken in before reset and appeared after it", m_tdata));
          discarded.delete(di);
        end else if (src >= S) begin
          fail("S4", $sformatf("output beat carries source tag %0d; no such input", src));
        end else if (exp_q[src].size() == 0) begin
          fail("S5", $sformatf("output beat attributed to input %0d with nothing outstanding", src));
        end else begin
          e = exp_q[src].pop_front();
          n_out[src] = n_out[src] + 1;

          if (m_tdata !== e.data)
            fail("S4", $sformatf("input %0d tdata: expected %h got %h", src, e.data, m_tdata));
          if (m_tkeep !== e.keep)
            fail("S4", $sformatf("input %0d tkeep: expected %h got %h", src, e.keep, m_tkeep));
          if (m_tuser !== e.user)
            fail("S4", $sformatf("input %0d tuser: expected %h got %h", src, e.user, m_tuser));
          if (m_tlast !== e.last)
            fail("S4", $sformatf("input %0d tlast: expected %b got %b", src, e.last, m_tlast));

          // ---- S10 frame-start detection (independent of S3) ------------------
          if (prev_last) since_start[src] = 0;
          prev_last <= m_tlast;

          // ---- S3 frame atomicity ---------------------------------------------
          if (!owner_valid) begin
            owner       <= src;
            owner_valid <= 1'b1;
          end else if (src != owner) begin
            fail("S3", $sformatf("mid-frame switch: frame from input %0d interrupted by input %0d",
                                 owner, src));
          end

          if (m_tlast) begin
            owner_valid <= 1'b0;
            frames_out = frames_out + 1;
            if (phase == "C:fairness") cov_frames_phaseC = cov_frames_phaseC + 1;
            for (int k = 0; k < S; k++) since_start[k] = since_start[k] + 1;
            if (fair_armed) begin
              for (int k = 0; k < S; k++)
                if (since_start[k] > FAIR_WINDOW)
                  fail("S10", $sformatf("input %0d has started no frame in %0d completed output frames (window %0d)",
                                        k, since_start[k], FAIR_WINDOW));
            end
          end
        end
      end
    end
  end

  // ---- stimulus -------------------------------------------------------------
  task automatic wait_frames(input int unsigned n);
    int unsigned target = frames_out + n;
    while (frames_out < target) @(posedge clk);
  endtask

  initial begin
    for (int k = 0; k < S; k++) begin
      cur_len[k] = 1; cur_beat[k] = 0; seq[k] = 0; gap_cnt[k] = 0;
      cur_data[k] = '0; cur_keep[k] = '1; cur_user[k] = '0; cur_last[k] = 1'b1;
      n_in[k] = 0; n_out[k] = 0; since_start[k] = 0; cov_frames_in[k] = 0;
      done_f[k] = 1'b0;
    end
    m_tready = 1'b1;
    repeat (4) @(posedge clk);
    @(negedge clk);
    rst = 1'b0;
    for (int k = 0; k < S; k++) seed_beat(k);
    run_en = 1'b1;

    phase = "A:mixed";
    wait_frames(60);

    // S2's single-beat corner, forced rather than left to chance.
    phase = "B:single-beat";
    force_single = 1'b1;
    wait_frames(40);
    force_single = 1'b0;

    // S10's stated precondition: continuous load, ready high throughout.
    phase = "C:fairness";
    @(negedge clk) m_tready = 1'b1;
    gap_en = 1'b0;
    repeat (20) @(posedge clk);
    fair_armed = 1'b1;
    wait_frames(220);
    fair_armed = 1'b0;

    // Directed backpressure. Random stalls rarely land where it matters; these
    // are placed mid-frame by construction.
    phase = "D:backpressure";
    for (int i = 0; i < 14; i++) begin
      while (!owner_valid) @(posedge clk);
      @(negedge clk) m_tready = 1'b0;
      repeat (5 + i) begin @(posedge clk); cov_stall_midframe = cov_stall_midframe + 1; end
      @(negedge clk) m_tready = 1'b1;
      wait_frames(4);
    end

    phase = "E:gaps";
    gap_en = 1'b1;
    fork
      forever @(negedge clk) m_tready = ($urandom_range(0, 3) != 0);
      wait_frames(80);
    join_any
    disable fork;
    @(negedge clk) m_tready = 1'b1;
    gap_en = 1'b0;

    // ---- S12: reset with beats held inside the design ------------------------
    // Backpressure first so the design's internal storage is occupied, then go
    // quiet at the inputs and reset. What must not survive is what the design
    // was already holding.
    phase = "F:reset";
    @(negedge clk) m_tready = 1'b0;
    repeat (8) @(posedge clk);
    run_en = 1'b0;
    repeat (2) @(posedge clk);
    @(negedge clk) rst = 1'b1;
    cov_resets = cov_resets + 1;
    repeat (3) @(posedge clk);
    @(negedge clk);
    rst     = 1'b0;
    m_tready = 1'b1;
    @(posedge clk);
    if (m_tvalid !== 1'b0)
      fail("S12", "m_tvalid_o high on the first cycle after reset release");
    @(negedge clk);
    for (int k = 0; k < S; k++) begin seed_beat(k); done_f[k] = 1'b0; end
    run_en = 1'b1;
    wait_frames(40);

    // ---- drain ---------------------------------------------------------------
    phase = "G:drain";
    @(negedge clk) m_tready = 1'b1;
    drain_mode = 1'b1;
    begin
      automatic int guard = 0;
      while (!(done_f[0] && done_f[1] && done_f[2] && done_f[3]) && guard < 5000) begin
        @(posedge clk); guard++;
      end
      if (guard >= 5000) fail("S5", "inputs did not reach a frame boundary while draining");
    end
    repeat (300) @(posedge clk);

    for (int k = 0; k < S; k++)
      if (exp_q[k].size() != 0)
        fail("S5", $sformatf("input %0d: %0d beats accepted and never emitted",
                             k, exp_q[k].size()));

    // ---- coverage floors, all stimulus-side (rule 2, rule 4) ----------------
    if (cov_single_frames < 20)
      fail("FLOOR", $sformatf("single-beat frames offered: %0d < 20", cov_single_frames));
    for (int k = 0; k < S; k++)
      if (cov_frames_in[k] < 20)
        fail("FLOOR", $sformatf("frames offered on input %0d: %0d < 20", k, cov_frames_in[k]));
    if (cov_stall_midframe < 50)
      fail("FLOOR", $sformatf("mid-frame stall cycles: %0d < 50", cov_stall_midframe));
    if (cov_resets < 1)
      fail("FLOOR", "no reset applied while the design held beats");
    if (cov_hi_payload < 20)
      fail("FLOOR", $sformatf("beats with non-zero tdata[31:16]: %0d < 20", cov_hi_payload));
    if (cov_partial_keep < 20)
      fail("FLOOR", $sformatf("beats with partial tkeep: %0d < 20", cov_partial_keep));
    if (cov_frames_phaseC < 200)
      fail("FLOOR", $sformatf("frames completed under continuous load: %0d < 200", cov_frames_phaseC));

    $display("METRIC: frames_out %0d", frames_out);
    $display("METRIC: beats_in [0]=%0d [1]=%0d [2]=%0d [3]=%0d", n_in[0], n_in[1], n_in[2], n_in[3]);
    $display("METRIC: beats_out [0]=%0d [1]=%0d [2]=%0d [3]=%0d", n_out[0], n_out[1], n_out[2], n_out[3]);
    $display("METRIC: cov single=%0d stalls=%0d hi_payload=%0d partial_keep=%0d phaseC=%0d",
             cov_single_frames, cov_stall_midframe, cov_hi_payload, cov_partial_keep, cov_frames_phaseC);

    if (n_fail == 0) $display("RESULT: PASS");
    else             $display("RESULT: FAIL (%0d failures)", n_fail);
    $finish;
  end

  // ---- watchdog (S13) -------------------------------------------------------
  initial begin
    #20_000_000;
    $display("RESULT: FAIL (watchdog fired in phase %s; no forward progress)", phase);
    $finish;
  end

endmodule
