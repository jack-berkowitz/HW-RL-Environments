`timescale 1ns/1ps

module frame_arb_mux_tb;

  localparam int S_COUNT    = 4;
  localparam int DATA_WIDTH = 32;
  localparam int USER_WIDTH = 1;
  localparam int KEEP_WIDTH = DATA_WIDTH/8;

  logic clk;
  logic rst;

  logic [S_COUNT-1:0][DATA_WIDTH-1:0] s_tdata;
  logic [S_COUNT-1:0][KEEP_WIDTH-1:0] s_tkeep;
  logic [S_COUNT-1:0]                 s_tvalid;
  logic [S_COUNT-1:0]                 s_tready;
  logic [S_COUNT-1:0]                 s_tlast;
  logic [S_COUNT-1:0][USER_WIDTH-1:0] s_tuser;

  logic [DATA_WIDTH-1:0] m_tdata;
  logic [KEEP_WIDTH-1:0] m_tkeep;
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

  // ---------------------------------------------------------------------------
  // PROVIDED PLUMBING -- moves beats, checks nothing.
  // ---------------------------------------------------------------------------
  // ---- clock -----------------------------------------------------------------
  initial begin clk = 1'b0; forever #5 clk = ~clk; end

  // ---- reset -----------------------------------------------------------------
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

  // ---------------------------------------------------------------------------
  // Failure reporting and watchdog.
  // ---------------------------------------------------------------------------
  bit finished;

  task automatic fail(input string requirement, input string detail);
    if (!finished) begin
      finished = 1'b1;
      $display("%s: %s", requirement, detail);
      $display("RESULT: FAIL");
      $finish;
    end
  endtask

  initial begin
    #20_000_000;
    if (!finished) begin
      finished = 1'b1;
      $display("S5: watchdog expired before all accepted frames were observed");
      $display("RESULT: FAIL");
      $finish;
    end
  end

  // ---------------------------------------------------------------------------
  // Output backpressure.  All changes are on the falling edge.
  // sink_mode: 0 = never ready, 1 = always ready, 2 = patterned backpressure.
  // ---------------------------------------------------------------------------
  int          sink_mode;
  int          ready_cycles;
  logic [15:0] ready_lfsr;

  always @(negedge clk) begin
    if (rst) begin
      m_tready    = 1'b0;
      ready_lfsr  = 16'hace1;
      ready_cycles = 0;
    end else begin
      ready_cycles = ready_cycles + 1;
      ready_lfsr = {ready_lfsr[14:0],
                    ready_lfsr[15] ^ ready_lfsr[13] ^
                    ready_lfsr[12] ^ ready_lfsr[10]};
      case (sink_mode)
        0: m_tready = 1'b0;
        1: m_tready = 1'b1;
        default: begin
          // Includes multi-cycle stalls as well as less regular stalls.
          if ((ready_cycles % 29) < 7)
            m_tready = 1'b0;
          else
            m_tready = (ready_lfsr[2:0] != 3'b000);
        end
      endcase
    end
  end

  // ---------------------------------------------------------------------------
  // Scoreboard.
  //
  // Every input handshake is recorded at the tail of that input's queue.  An
  // output frame remains associated with one queue until its expected TLAST.
  // Stimulus data values are globally unique beat tags, so attributing the
  // first beat of a frame to a head-of-queue entry is unambiguous; integrity
  // checking still compares every field at full width.
  // ---------------------------------------------------------------------------
  typedef struct packed {
    logic [DATA_WIDTH-1:0] data;
    logic [KEEP_WIDTH-1:0] keep;
    logic                  last;
    logic [USER_WIDTH-1:0] user;
  } beat_t;

  beat_t exp_q [0:S_COUNT-1][$];

  bit out_active;
  int out_k;

  bit    stall_active;
  beat_t stall_beat;
  bit    prev_rst;

  // Fairness state (S10).
  bit fairness_active;
  int fairness_frames;
  int fair_hist[$];
  bit stop_fairness;

  always @(posedge clk) begin
    automatic beat_t in_beat;
    automatic beat_t exp_beat;
    automatic int j;
    automatic int found;
    automatic int found_k;
    automatic int discarded;
    automatic int mask;

    if (rst) begin
      // S12: input beats from before or during reset are deliberately forgotten.
      for (j = 0; j < S_COUNT; j = j + 1)
        exp_q[j].delete();
      out_active  = 1'b0;
      out_k       = 0;
      stall_active = 1'b0;
      prev_rst    = 1'b1;
    end else begin
      // S12: the first post-release cycle must not present a valid output beat.
      if (prev_rst && (m_tvalid !== 1'b0))
        fail("S12", "m_tvalid_o was not low on the first cycle after reset release");
      prev_rst = 1'b0;

      // AXI4-Stream stability while a beat is backpressured (S8).
      if (stall_active) begin
        if (m_tvalid !== 1'b1)
          fail("S8", "m_tvalid_o was withdrawn before a stalled beat transferred");
        else if ((m_tdata !== stall_beat.data) ||
                 (m_tkeep !== stall_beat.keep) ||
                 (m_tlast !== stall_beat.last) ||
                 (m_tuser !== stall_beat.user))
          fail("S8", "an output beat changed while m_tready_i was low");
      end

      // Record input transfers before checking the output, permitting a legal
      // same-edge input/output transfer with no assumed internal latency.
      for (j = 0; j < S_COUNT; j = j + 1) begin
        if (s_tvalid[j] && s_tready[j]) begin
          in_beat.data = s_tdata[j];
          in_beat.keep = s_tkeep[j];
          in_beat.last = s_tlast[j];
          in_beat.user = s_tuser[j];
          exp_q[j].push_back(in_beat);
        end
      end

      if (m_tvalid && m_tready) begin
        // At a frame boundary, locate the unique accepted head beat.  Once
        // chosen, out_k cannot change until the expected final beat (S3).
        if (!out_active) begin
          found   = 0;
          found_k = -1;
          for (j = 0; j < S_COUNT; j = j + 1) begin
            if (exp_q[j].size() != 0) begin
              if ((m_tdata === exp_q[j][0].data) &&
                  (m_tkeep === exp_q[j][0].keep) &&
                  (m_tlast === exp_q[j][0].last) &&
                  (m_tuser === exp_q[j][0].user)) begin
                found   = found + 1;
                found_k = j;
              end
            end
          end

          if (found == 0)
            fail("S4", "output beat did not match any accepted input head beat");
          if (found > 1)
            fail("S4", "output beat attribution was ambiguous");

          out_k      = found_k;
          out_active = 1'b1;
        end

        if (exp_q[out_k].size() == 0)
          fail("S5", "output duplicated a beat or continued a frame without input data");

        exp_beat = exp_q[out_k].pop_front();

        // S4: complete payload/sideband integrity, input order, and TLAST.
        if (m_tdata !== exp_beat.data)
          fail("S4", "tdata was modified, duplicated, or reordered");
        if (m_tkeep !== exp_beat.keep)
          fail("S4", "tkeep was not forwarded unmodified");
        if (m_tuser !== exp_beat.user)
          fail("S4", "tuser was not forwarded unmodified");
        if (m_tlast !== exp_beat.last)
          fail("S4", "tlast did not correspond to the accepted input beat");

        if (exp_beat.last) begin
          out_active = 1'b0;

          if (fairness_active) begin
            fairness_frames = fairness_frames + 1;
            fair_hist.push_back(out_k);
            if (fair_hist.size() > 16)
              discarded = fair_hist.pop_front();

            // Every sliding window of 16 completed frames must contain all
            // four sources.  Selection order within the window is irrelevant.
            if (fair_hist.size() == 16) begin
              mask = 0;
              for (j = 0; j < 16; j = j + 1)
                mask[fair_hist[j]] = 1'b1;
              if (mask != 15)
                fail("S10", "an input began no frame in a 16-completed-frame window");
            end
          end
        end
      end

      stall_active = m_tvalid && !m_tready;
      if (stall_active) begin
        stall_beat.data = m_tdata;
        stall_beat.keep = m_tkeep;
        stall_beat.last = m_tlast;
        stall_beat.user = m_tuser;
      end
    end
  end

  // ---------------------------------------------------------------------------
  // Stimulus helpers.
  // ---------------------------------------------------------------------------
  int unsigned seq_ctr [0:S_COUNT-1];

  task automatic send_frame(input int k, input int nbeats);
    automatic int i;
    automatic logic [DATA_WIDTH-1:0] d;
    automatic logic [KEEP_WIDTH-1:0] kp;
    automatic logic u;

    for (i = 0; i < nbeats; i = i + 1) begin
      // Unique per input and across inputs; counters are not reset by S12 tests.
      d = 32'h4000_0000 + (k * 32'h0010_0000) + seq_ctr[k];
      seq_ctr[k] = seq_ctr[k] + 1;

      case (seq_ctr[k] % 8)
        0: kp = 4'h0;
        1: kp = 4'h1;
        2: kp = 4'h2;
        3: kp = 4'h4;
        4: kp = 4'h8;
        5: kp = 4'hf;
        6: kp = 4'ha;
        default: kp = 4'h5;
      endcase
      u = seq_ctr[k] & 1;

      bfm_send(k, d, kp, (i == nbeats-1), u);
    end
  endtask

  task automatic wait_drained(input int max_cycles);
    automatic int cycles;
    automatic int j;
    automatic bit empty;

    cycles = 0;
    empty  = 1'b0;
    while (!empty && (cycles < max_cycles)) begin
      @(negedge clk);
      empty = 1'b1;
      for (j = 0; j < S_COUNT; j = j + 1) begin
        if (exp_q[j].size() != 0)
          empty = 1'b0;
      end
      if (out_active)
        empty = 1'b0;
      cycles = cycles + 1;
    end

    if (!empty)
      fail("S5", "accepted complete frames were not drained exactly once");
  endtask

  // Continuously offer complete frames on one input until stopped.  Valid stays
  // asserted across beats and frame boundaries; stopping occurs only after the
  // current frame has completed.
  task automatic fairness_driver(input int k);
    automatic int seq_no;
    automatic int frame_no;
    automatic int frame_len;
    automatic int b;
    automatic logic [DATA_WIDTH-1:0] d;
    automatic logic [KEEP_WIDTH-1:0] kp;
    automatic logic u;

    seq_no   = 0;
    frame_no = 0;

    while (!stop_fairness) begin
      frame_len = 1 + ((frame_no + (2*k)) % 4);
      for (b = 0; b < frame_len; b = b + 1) begin
        d  = 32'hf000_0000 | (k << 20) | seq_no;
        kp = 4'b0001 << ((seq_no + k) % 4);
        u  = seq_no & 1;
        seq_no = seq_no + 1;
        bfm_send(k, d, kp, (b == frame_len-1), u);
      end
      frame_no = frame_no + 1;
    end

    bfm_idle(k);
  endtask

  task automatic run_fairness();
    automatic int cycles;

    sink_mode       = 1;
    fairness_frames = 0;
    fair_hist.delete();
    stop_fairness   = 1'b0;

    // Ensure ready is high before the continuous-load interval begins.
    repeat (2) @(posedge clk);
    fairness_active = 1'b1;

    fork
      fairness_driver(0);
      fairness_driver(1);
      fairness_driver(2);
      fairness_driver(3);
      begin
        cycles = 0;
        while ((fairness_frames < 40) && (cycles < 100000)) begin
          @(posedge clk);
          cycles = cycles + 1;
        end
        if (fairness_frames < 40)
          fail("S10", "continuous offered load did not produce sufficient forward progress");

        @(negedge clk);
        stop_fairness   = 1'b1;
        fairness_active = 1'b0;
      end
    join
  endtask

  // ---------------------------------------------------------------------------
  // Test sequence.
  // ---------------------------------------------------------------------------
  int init_k;

  initial begin
    finished        = 1'b0;
    sink_mode       = 0;
    m_tready        = 1'b0;
    ready_cycles    = 0;
    ready_lfsr      = 16'hace1;

    s_tdata         = '0;
    s_tkeep         = '0;
    s_tvalid        = '0;
    s_tlast         = '0;
    s_tuser         = '0;

    out_active      = 1'b0;
    out_k           = 0;
    stall_active    = 1'b0;
    prev_rst        = 1'b1;
    fairness_active = 1'b0;
    fairness_frames = 0;
    stop_fairness   = 1'b0;
    fair_hist.delete();

    for (init_k = 0; init_k < S_COUNT; init_k = init_k + 1) begin
      seq_ctr[init_k] = 0;
      exp_q[init_k].delete();
    end

    bfm_reset(4);
    sink_mode = 2;

    // S2/S4/S5: single-beat frames on every input, with TLAST on the only beat.
    for (init_k = 0; init_k < S_COUNT; init_k = init_k + 1) begin
      send_frame(init_k, 1);
      bfm_idle(init_k);
      wait_drained(5000);
    end

    // Multi-beat frame under patterned mid-frame backpressure.
    send_frame(0, 5);
    bfm_idle(0);
    wait_drained(5000);

    // Concurrent frames, including back-to-back frames on individual inputs.
    // This exercises atomicity without assuming any selection order.
    fork
      begin
        send_frame(0, 3);
        send_frame(0, 2);
        bfm_idle(0);
      end
      begin
        send_frame(1, 1);
        send_frame(1, 4);
        bfm_idle(1);
      end
      begin
        send_frame(2, 2);
        send_frame(2, 3);
        bfm_idle(2);
      end
      begin
        send_frame(3, 4);
        send_frame(3, 1);
        bfm_idle(3);
      end
    join
    wait_drained(10000);

    // S12: stop the sink after a frame has been offered, then reset with any
    // still-buffered portion present.  No pre-reset beat may leak out later.
    sink_mode = 1;
    send_frame(2, 4);
    sink_mode = 0;
    bfm_idle(2);
    bfm_reset(3);
    sink_mode = 1;

    repeat (12) @(posedge clk);

    // The design must also operate normally after reset.
    send_frame(3, 2);
    bfm_idle(3);
    wait_drained(5000);

    // S10: all inputs continuously loaded and output always ready.
    run_fairness();
    wait_drained(20000);

    // Allow any erroneous duplicate or stale post-reset beat to expose itself.
    sink_mode = 1;
    repeat (20) @(negedge clk);

    if (!finished) begin
      finished = 1'b1;
      $display("RESULT: PASS");
      $finish;
    end
  end

endmodule
