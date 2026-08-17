// =============================================================================
// frame_arb_mux_spec_tb.sv -- REFERENCE TESTBENCH for v_nw03. NEVER SHIPPED.
// =============================================================================
// Establishes the kill ceiling. Written from spec/frame_arb_mux_spec.md only;
// every check cites the clause it enforces, and no check rests on anything §7
// declares out of scope.
//
// Driver discipline (CONVENTIONS.md): stimulus advances ONLY on the clock edge
// that accepts a beat, by nonblocking assignment. Nothing changes in the same
// timestep the design samples.
//
// The output carries no source identifier -- the port map has none -- so the
// checker identifies an output beat's origin from a tag the testbench itself
// placed in the LOW bits of tdata, and then compares the FULL beat against that
// input's expectation. The tag is low so that a design corrupting high payload
// bits is caught as a payload mismatch rather than becoming unattributable.
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

  // ---- dut ------------------------------------------------------------------
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

  // ---- failures -------------------------------------------------------------
  int unsigned n_fail = 0;
  task automatic fail(input string clause, input string msg);
    n_fail++;
    if (n_fail <= 30) $display("FAIL [%s] %s  (t=%0t)", clause, msg, $time);
  endtask

  // ---- generator state ------------------------------------------------------
  logic [DW-1:0] cur_data [S];
  logic [KW-1:0] cur_keep [S];
  logic [UW-1:0] cur_user [S];
  logic          cur_last [S];
  logic          cur_val  [S];
  int unsigned   cur_len  [S], cur_beat [S], seq [S], gap [S];

  logic          gap_en  = 1'b0;     // idle cycles between frames
  logic          force_single = 1'b0; // drive the single-beat corner
  string         phase = "init";

  // stimulus-side coverage (rule 4: a correct design cannot score zero here)
  int unsigned cov_single_frames = 0, cov_frames_in [S];
  int unsigned cov_stall_midframe = 0, cov_resets = 0;
  int unsigned cov_hi_payload = 0, cov_partial_keep = 0, cov_frames_phaseC = 0;

  function automatic logic [DW-1:0] mk_data(input int unsigned k,
                                            input int unsigned sq);
    // [3:0] source tag, [15:4] sequence, [31:16] payload the low bits cannot
    // reconstruct -- so a design that drops high bits fails S4 rather than
    // becoming unidentifiable.
    return {16'($urandom), 12'(sq), 4'(k)};
  endfunction

  task automatic new_beat(input int unsigned k);
    if (cur_beat[k] >= cur_len[k]) begin      // start a new frame
      cur_len[k]  = force_single ? 1 : (1 + ($urandom_range(0, 4)));
      cur_beat[k] = 0;
      gap[k]      = gap_en ? $urandom_range(0, 3) : 0;
    end
    cur_data[k] = mk_data(k, seq[k]);
    cur_keep[k] = ($urandom_range(0, 3) == 0) ? KW'($urandom) : {KW{1'b1}};
    cur_user[k] = UW'($urandom);
    cur_last[k] = (cur_beat[k] == cur_len[k] - 1);
    seq[k]      = seq[k] + 1;
    if (|cur_data[k][DW-1:16])       cov_hi_payload++;
    if (cur_keep[k] != {KW{1'b1}})   cov_partial_keep++;
  endtask

  for (genvar k = 0; k < S; k++) begin : g_drive
    assign s_tdata[k]  = cur_data[k];
    assign s_tkeep[k]  = cur_keep[k];
    assign s_tuser[k]  = cur_user[k];
    assign s_tlast[k]  = cur_last[k];
    assign s_tvalid[k] = cur_val[k];
  end

  // ---- scoreboard -----------------------------------------------------------
  beat_t exp_q [S][$];
  int unsigned n_in [S], n_out [S];

  // S10 bookkeeping: completed output frames since each input last STARTED one.
  int unsigned since_start [S];
  logic        fair_armed = 1'b0;

  // output frame ownership (S3)
  logic        owner_valid = 1'b0;
  int unsigned owner;
  int unsigned frames_out = 0;

  always @(posedge clk) begin
    if (rst) begin
      // S12: everything in flight is discarded. Clearing the model here is what
      // makes a surviving pre-reset beat show up as an unmatched output beat.
      for (int k = 0; k < S; k++) exp_q[k].delete();
      owner_valid <= 1'b0;
    end else begin
      // ---- accept side: record what the design took in --------------------
      for (int k = 0; k < S; k++) begin
        if (s_tvalid[k] && s_tready[k]) begin
          beat_t b;
          b.data = cur_data[k]; b.keep = cur_keep[k];
          b.user = cur_user[k]; b.last = cur_last[k];
          exp_q[k].push_back(b);
          n_in[k]++;
          if (cur_last[k] && cur_len[k] == 1) cov_single_frames++;
          if (cur_last[k])                    cov_frames_in[k]++;
        end
      end

      // ---- output side ------------------------------------------------------
      if (m_tvalid && m_tready) begin
        automatic int unsigned src = m_tdata[3:0];
        automatic beat_t       e;
        if (src >= S) begin
          fail("S4", $sformatf("output beat carries source tag %0d, no such input", src));
        end else if (exp_q[src].size() == 0) begin
          fail("S5", $sformatf("output beat from input %0d with nothing outstanding "
                               , src));
        end else begin
          e = exp_q[src].pop_front();
          n_out[src]++;
          if (m_tdata !== e.data)
            fail("S4", $sformatf("input %0d tdata: expected %h got %h", src, e.data, m_tdata));
          if (m_tkeep !== e.keep)
            fail("S4", $sformatf("input %0d tkeep: expected %h got %h", src, e.keep, m_tkeep));
          if (m_tuser !== e.user)
            fail("S4", $sformatf("input %0d tuser: expected %h got %h", src, e.user, m_tuser));
          if (m_tlast !== e.last)
            fail("S4", $sformatf("input %0d tlast: expected %b got %b", src, e.last, m_tlast));

          // ---- S3 frame atomicity -------------------------------------------
          if (!owner_valid) begin
            owner <= src; owner_valid <= 1'b1;
            for (int k = 0; k < S; k++)
              since_start[k] <= (k == src) ? 0 : since_start[k];
          end else if (src != owner) begin
            fail("S3", $sformatf("mid-frame switch: frame from input %0d interrupted by input %0d",
                                 owner, src));
          end

          if (m_tlast) begin
            owner_valid <= 1'b0;
            frames_out++;
            if (phase == "C:fairness") cov_frames_phaseC++;
            // S10: one more completed frame since every input's last start.
            for (int k = 0; k < S; k++) begin
              if (!(owner_valid && k == owner) && !( !owner_valid && k == src))
                since_start[k] <= since_start[k] + 1;
            end
            if (fair_armed) begin
              for (int k = 0; k < S; k++)
                if (since_start[k] > FAIR_WINDOW)
                  fail("S10", $sformatf("input %0d has not started a frame in %0d completed frames (window %0d)",
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
      cur_len[k] = 0; cur_beat[k] = 0; seq[k] = 0; gap[k] = 0;
      cur_val[k] = 1'b0; n_in[k] = 0; n_out[k] = 0;
      since_start[k] = 0; cov_frames_in[k] = 0;
    end
    m_tready = 1'b1;
    repeat (4) @(posedge clk);
    @(negedge clk) rst = 1'b0;
    for (int k = 0; k < S; k++) begin new_beat(k); cur_val[k] = 1'b1; end

    // -- A: mixed lengths, no backpressure ------------------------------------
    phase = "A:mixed";
    wait_frames(60);

    // -- B: the single-beat corner (S2), forced rather than hoped for ---------
    phase = "B:single-beat";
    force_single = 1'b1;
    wait_frames(40);
    force_single = 1'b0;

    // -- C: continuous load, ready high -- S10's stated precondition ----------
    phase = "C:fairness";
    @(negedge clk) m_tready = 1'b1;
    gap_en = 1'b0;
    repeat (20) @(posedge clk);
    fair_armed = 1'b1;
    wait_frames(220);
    fair_armed = 1'b0;

    // -- D: directed backpressure, including stalls on the tlast beat ---------
    phase = "D:backpressure";
    for (int i = 0; i < 14; i++) begin
      // stall until a frame is in progress, so the stall lands mid-frame
      while (!owner_valid) @(posedge clk);
      @(negedge clk) m_tready = 1'b0;
      repeat (5 + i) begin @(posedge clk); cov_stall_midframe++; end
      @(negedge clk) m_tready = 1'b1;
      wait_frames(4);
    end

    // -- E: idle gaps between frames + random backpressure --------------------
    phase = "E:gaps";
    gap_en = 1'b1;
    fork
      forever @(negedge clk) m_tready = ($urandom_range(0, 3) != 0);
      wait_frames(80);
    join_any
    disable fork;
    @(negedge clk) m_tready = 1'b1;
    gap_en = 1'b0;

    // -- F: reset with beats in flight (S12) ----------------------------------
    phase = "F:reset";
    wait_frames(3);
    @(negedge clk) rst = 1'b1;
    cov_resets++;
    repeat (3) @(posedge clk);
    @(negedge clk) rst = 1'b0;
    @(posedge clk);
    if (m_tvalid !== 1'b0)
      fail("S12", "m_tvalid_o high on the first cycle after reset release");
    // restart the generators; anything the design kept from before reset now
    // has no expectation to match and trips S5.
    for (int k = 0; k < S; k++) begin
      cur_beat[k] = 0; cur_len[k] = 0; new_beat(k); cur_val[k] = 1'b1;
    end
    wait_frames(40);

    // -- drain ----------------------------------------------------------------
    phase = "G:drain";
    for (int k = 0; k < S; k++) cur_val[k] = 1'b0;
    @(negedge clk) m_tready = 1'b1;
    repeat (200) @(posedge clk);

    // ---- S5 accounting ------------------------------------------------------
    for (int k = 0; k < S; k++) begin
      if (exp_q[k].size() != 0)
        fail("S5", $sformatf("input %0d: %0d beats accepted but never emitted",
                             k, exp_q[k].size()));
    end

    // ---- coverage floors (rule 2 / rule 4: all stimulus-side) --------------
    if (cov_single_frames < 20) fail("FLOOR", $sformatf("single-beat frames offered: %0d < 20", cov_single_frames));
    for (int k = 0; k < S; k++)
      if (cov_frames_in[k] < 20) fail("FLOOR", $sformatf("frames offered on input %0d: %0d < 20", k, cov_frames_in[k]));
    if (cov_stall_midframe < 50)  fail("FLOOR", $sformatf("mid-frame stall cycles: %0d < 50", cov_stall_midframe));
    if (cov_resets < 1)           fail("FLOOR", "no reset applied with beats in flight");
    if (cov_hi_payload < 20)      fail("FLOOR", $sformatf("beats with non-zero tdata[31:16]: %0d < 20", cov_hi_payload));
    if (cov_partial_keep < 20)    fail("FLOOR", $sformatf("beats with partial tkeep: %0d < 20", cov_partial_keep));
    if (cov_frames_phaseC < 200)  fail("FLOOR", $sformatf("frames under continuous load: %0d < 200", cov_frames_phaseC));

    $display("METRIC: frames_out %0d", frames_out);
    $display("METRIC: beats_in [0]=%0d [1]=%0d [2]=%0d [3]=%0d", n_in[0], n_in[1], n_in[2], n_in[3]);
    $display("METRIC: beats_out [0]=%0d [1]=%0d [2]=%0d [3]=%0d", n_out[0], n_out[1], n_out[2], n_out[3]);
    $display("METRIC: cov single_frames=%0d stalls=%0d hi_payload=%0d partial_keep=%0d phaseC_frames=%0d",
             cov_single_frames, cov_stall_midframe, cov_hi_payload, cov_partial_keep, cov_frames_phaseC);

    if (n_fail == 0) $display("RESULT: PASS");
    else             $display("RESULT: FAIL (%0d failures)", n_fail);
    $finish;
  end

  // ---- watchdog (S13) -------------------------------------------------------
  initial begin
    #20_000_000;
    $display("RESULT: FAIL (watchdog: no forward progress, phase %s)", phase);
    $finish;
  end

endmodule
