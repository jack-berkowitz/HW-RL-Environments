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

  // ---- watchdog --------------------------------------------------------------
  initial begin
    #20_000_000;
    $display("RESULT: FAIL (watchdog: no forward progress)");
    $finish;
  end

  // ---------------------------------------------------------------------------
  // Scoreboard
  // ---------------------------------------------------------------------------
  // Every accepted input beat is queued on its own input.  An output frame may
  // start from any nonempty queue; once started, only that queue may supply
  // beats until the expected last beat.  Input handshakes are recorded before
  // output handshakes at each edge, permitting zero-latency implementations.
  // ---------------------------------------------------------------------------

  typedef struct packed {
    logic [DATA_WIDTH-1:0] data;
    logic [KEEP_WIDTH-1:0] keep;
    logic                  last;
    logic [USER_WIDTH-1:0] user;
  } beat_t;

  beat_t expect_q [S_COUNT][$];

  logic frame_active;
  int   active_src;

  logic prev_rst;

  logic hold_pending;
  beat_t hold_beat;

  logic fair_mode;
  int   fair_completed;
  int   fair_src_q[$];

  logic [S_COUNT-1:0] fair_stop;
  logic [S_COUNT-1:0] fair_driver_done;

  int unsigned seq_ctr [S_COUNT];
  logic reset_probe_done;

  task automatic die(input string req, input string msg);
    begin
      $display("%s: %s", req, msg);
      $display("RESULT: FAIL");
      $finish;
    end
  endtask

  function automatic bit output_matches(input beat_t b);
    begin
      output_matches =
          (m_tdata === b.data) &&
          (m_tkeep === b.keep) &&
          (m_tlast === b.last) &&
          (m_tuser === b.user);
    end
  endfunction

  // Multiplication by an odd constant and XOR are bijections on 32 bits.  The
  // resulting data is therefore globally unique for each (sequence,input),
  // while varying across the full data width.  This makes source attribution
  // unambiguous without relying on any arbitration policy.
  function automatic logic [DATA_WIDTH-1:0] make_data(
      input int k,
      input int unsigned n
  );
    logic [31:0] raw;
    begin
      raw = {n[29:0], k[1:0]};
      make_data = (raw * 32'h9E3779B1) ^ 32'hA5C35A7E;
    end
  endfunction

  function automatic logic [KEEP_WIDTH-1:0] make_keep(input int unsigned n);
    begin
      make_keep = n[3:0] ^ 4'h5;
    end
  endfunction

  task automatic offer_next(input int k, input logic is_final);
    automatic int unsigned n;
    automatic logic [DATA_WIDTH-1:0] d;
    automatic logic [KEEP_WIDTH-1:0] kp;
    automatic logic [USER_WIDTH-1:0] ur;
    begin
      n = seq_ctr[k];
      seq_ctr[k] = n + 1;
      d  = make_data(k, n);
      kp = make_keep(n);
      ur = n[0] ^ k[0];
      bfm_send(k, d, kp, is_final, ur);
    end
  endtask

  task automatic send_frame(input int k, input int len);
    automatic int b;
    begin
      for (b = 0; b < len; b = b + 1) begin
        offer_next(k, b == len-1);
      end
    end
  endtask

  task automatic send_series(input int k, input int frame_count);
    automatic int f;
    begin
      for (f = 0; f < frame_count; f = f + 1) begin
        send_frame(k, 1 + ((f+k) % 4));
      end
    end
  endtask

  task automatic sink_pattern;
    automatic int n;
    begin
      for (n = 0; n < 36; n = n + 1) begin
        bfm_ready((n % 6) >= 2);
        repeat (1 + (n % 3)) @(posedge clk);
      end
      bfm_ready(1'b1);
    end
  endtask

  task automatic fairness_driver(input int k);
    automatic int f;
    automatic int len;
    begin
      f = 0;
      while (!fair_stop[k]) begin
        len = 1 + ((f + 2*k) % 4);
        send_frame(k, len);
        f = f + 1;
      end
      bfm_idle(k);
      fair_driver_done[k] = 1'b1;
    end
  endtask

  task automatic wait_drained;
    automatic int total;
    automatic int k;
    automatic bit empty;
    begin
      empty = 1'b0;
      while (!empty) begin
        @(negedge clk);
        total = 0;
        for (k = 0; k < S_COUNT; k = k + 1) begin
          total = total + expect_q[k].size();
        end
        empty = !rst && (total == 0) && !frame_active;
      end
    end
  endtask

  task automatic fair_note_start(input int src);
    begin
      if (fair_mode)
        fair_src_q.push_back(src);
    end
  endtask

  task automatic fair_note_done;
    automatic int n;
    automatic logic [S_COUNT-1:0] seen;
    begin
      if (fair_mode) begin
        fair_completed = fair_completed + 1;

        // Retain exactly the starts associated with the latest 16 completed
        // frames.  The current frame's start is already in the queue.
        while (fair_src_q.size() > 16) begin
          void'(fair_src_q.pop_front());
        end

        if (fair_src_q.size() == 16) begin
          seen = '0;
          for (n = 0; n < 16; n = n + 1) begin
            seen[fair_src_q[n]] = 1'b1;
          end
          if (seen !== {S_COUNT{1'b1}}) begin
            die("S10",
                $sformatf("16-frame window ending at output frame %0d did not start a frame from every input (seen=%b)",
                          fair_completed, seen));
          end
        end
      end
    end
  endtask

  // ---------------------------------------------------------------------------
  // Transfer monitor and requirement checks
  // ---------------------------------------------------------------------------
  always @(posedge clk) begin : transfer_monitor
    automatic beat_t in_beat;
    automatic beat_t exp_beat;
    automatic int j;
    automatic int found;

    if (rst) begin
      for (j = 0; j < S_COUNT; j = j + 1)
        expect_q[j].delete();

      frame_active = 1'b0;
      active_src   = 0;
      hold_pending = 1'b0;
      prev_rst     = 1'b1;
      fair_src_q.delete();
    end else begin
      // S12: valid must be low on the first cycle following reset release.
      if (prev_rst && (m_tvalid !== 1'b0)) begin
        die("S12", "m_tvalid_o was not low on the first cycle after reset");
      end

      // AXI4-Stream backpressure: a stalled output beat must remain valid and
      // stable through the edge on which it eventually transfers.
      if (hold_pending) begin
        if (m_tvalid !== 1'b1) begin
          die("S8", "m_tvalid_o dropped while an output beat was stalled");
        end else if ((m_tdata !== hold_beat.data) ||
                     (m_tkeep !== hold_beat.keep) ||
                     (m_tlast !== hold_beat.last) ||
                     (m_tuser !== hold_beat.user)) begin
          die("S8", "output payload changed while backpressured");
        end
      end

      // S1/S6: every input handshake is accepted into the model independently
      // of output selection.  Ready is never treated as a grant.
      for (j = 0; j < S_COUNT; j = j + 1) begin
        if (s_tvalid[j] && s_tready[j]) begin
          in_beat.data = s_tdata[j];
          in_beat.keep = s_tkeep[j];
          in_beat.last = s_tlast[j];
          in_beat.user = s_tuser[j];
          expect_q[j].push_back(in_beat);
        end
      end

      if (m_tvalid && m_tready) begin
        if (frame_active) begin
          // S3: once started, a frame cannot be interleaved with another input.
          if (expect_q[active_src].size() == 0) begin
            die("S5",
                $sformatf("duplicate or unexpected output beat during frame from input %0d",
                          active_src));
          end

          exp_beat = expect_q[active_src][0];
          if (!output_matches(exp_beat)) begin
            die("S3/S4",
                $sformatf("frame atomicity, order, payload, or last mismatch: expected input %0d data=%08x keep=%x last=%0b user=%0b, got data=%08x keep=%x last=%0b user=%0b",
                          active_src, exp_beat.data, exp_beat.keep,
                          exp_beat.last, exp_beat.user,
                          m_tdata, m_tkeep, m_tlast, m_tuser));
          end

          exp_beat = expect_q[active_src].pop_front();
          if (m_tlast) begin
            frame_active = 1'b0;
            fair_note_done();
          end
        end else begin
          // Selection order is unconstrained: find the unique input whose next
          // accepted beat is exactly the output beat.
          found = -1;
          for (j = 0; j < S_COUNT; j = j + 1) begin
            if (expect_q[j].size() != 0) begin
              exp_beat = expect_q[j][0];
              if (output_matches(exp_beat)) begin
                if (found == -1)
                  found = j;
                else
                  die("S4", "ambiguous output attribution despite unique stimulus tags");
              end
            end
          end

          if (found == -1) begin
            die("S4",
                $sformatf("output beat matches no input's next accepted beat: data=%08x keep=%x last=%0b user=%0b",
                          m_tdata, m_tkeep, m_tlast, m_tuser));
          end

          active_src = found;
          exp_beat   = expect_q[found].pop_front();
          fair_note_start(found);

          if (m_tlast) begin
            // Includes a legal single-beat frame.
            frame_active = 1'b0;
            fair_note_done();
          end else begin
            frame_active = 1'b1;
          end
        end
      end

      hold_pending = m_tvalid && !m_tready;
      if (m_tvalid && !m_tready) begin
        hold_beat.data = m_tdata;
        hold_beat.keep = m_tkeep;
        hold_beat.last = m_tlast;
        hold_beat.user = m_tuser;
      end

      prev_rst = 1'b0;
    end
  end

  // ---------------------------------------------------------------------------
  // Stimulus
  // ---------------------------------------------------------------------------
  initial begin : main_test
    automatic int k;
    automatic int wait_cycles;

    s_tdata  = '0;
    s_tkeep  = '0;
    s_tvalid = '0;
    s_tlast  = '0;
    s_tuser  = '0;
    m_tready = 1'b0;

    frame_active = 1'b0;
    active_src   = 0;
    prev_rst     = 1'b1;
    hold_pending = 1'b0;

    fair_mode        = 1'b0;
    fair_completed   = 0;
    fair_stop        = '0;
    fair_driver_done = '0;
    reset_probe_done = 1'b0;

    for (k = 0; k < S_COUNT; k = k + 1)
      seq_ctr[k] = 0;

    bfm_reset(4);
    bfm_ready(1'b1);

    // Single-beat frame: last is present on the first and only beat.
    send_frame(0, 1);
    bfm_idle(0);
    wait_drained();

    // Multi-beat ordering and sideband integrity.
    send_frame(1, 5);
    bfm_idle(1);
    wait_drained();

    // Concurrent frames of differing lengths, with no selection-order assumption.
    fork
      begin
        send_frame(0, 3);
        bfm_idle(0);
      end
      begin
        send_frame(1, 1);
        bfm_idle(1);
      end
      begin
        send_frame(2, 4);
        bfm_idle(2);
      end
      begin
        send_frame(3, 2);
        bfm_idle(3);
      end
    join
    wait_drained();

    // Sustained concurrent traffic with arbitrary output backpressure.
    fork
      begin
        send_series(0, 5);
        bfm_idle(0);
      end
      begin
        send_series(1, 5);
        bfm_idle(1);
      end
      begin
        send_series(2, 5);
        bfm_idle(2);
      end
      begin
        send_series(3, 5);
        bfm_idle(3);
      end
      begin
        sink_pattern();
      end
    join
    bfm_ready(1'b1);
    wait_drained();

    // Reset with output backpressure.  If the implementation accepts the probe
    // beat, it is pending and must be discarded by reset.  If it applies no
    // input ready while the output is blocked, release backpressure so the
    // source can finish legally; no readiness promptness is required.
    bfm_ready(1'b0);
    reset_probe_done = 1'b0;
    fork
      begin
        send_frame(2, 1);
        bfm_idle(2);
        reset_probe_done = 1'b1;
      end
    join_none

    wait_cycles = 0;
    while (!reset_probe_done && (wait_cycles < 20)) begin
      @(negedge clk);
      wait_cycles = wait_cycles + 1;
    end

    if (!reset_probe_done) begin
      bfm_ready(1'b1);
      while (!reset_probe_done)
        @(negedge clk);
    end

    bfm_reset(3);
    bfm_ready(1'b1);

    // Fresh post-reset traffic also ensures that a pre-reset beat cannot be
    // mistaken for a newly accepted one: all stimulus tags remain unique.
    send_frame(3, 1);
    bfm_idle(3);
    wait_drained();

    send_frame(0, 2);
    bfm_idle(0);
    wait_drained();

    // S10: all sources now offer unlimited complete frames without dropping
    // valid between frames, and ready remains high throughout the checked
    // interval.  Forty frames provide several overlapping 16-frame windows.
    bfm_ready(1'b1);
    fair_stop        = '0;
    fair_driver_done = '0;
    fair_completed   = 0;
    fair_src_q.delete();
    fair_mode        = 1'b1;

    fork
      fairness_driver(0);
      fairness_driver(1);
      fairness_driver(2);
      fairness_driver(3);
    join_none

    while (fair_completed < 40)
      @(negedge clk);

    // Stop checking fairness before removing continuous offered load.  Each
    // driver observes its stop request only at a frame boundary.
    fair_mode = 1'b0;
    for (k = 0; k < S_COUNT; k = k + 1)
      fair_stop[k] = 1'b1;

    while (!(&fair_driver_done))
      @(negedge clk);

    wait_drained();

    // Allow any spurious duplicate valid beat to transfer and be detected.
    repeat (10) @(negedge clk);

    $display("RESULT: PASS");
    $finish;
  end

endmodule
