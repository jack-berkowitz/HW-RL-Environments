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
  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end

  initial rst = 1'b1;

  task automatic bfm_reset(input int cycles = 4);
    @(negedge clk);
    rst = 1'b1;
    repeat (cycles) @(posedge clk);
    @(negedge clk);
    rst = 1'b0;
  endtask

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

  task automatic bfm_ready(input logic value);
    @(negedge clk);
    m_tready = value;
  endtask

  // ---------------------------------------------------------------------------
  // Scoreboard
  //
  // Every generated beat carries a globally unique token in tdata. The token
  // map identifies the input by bookkeeping; output results are never found by
  // searching for matching payload values. The per-input queues preserve the
  // actual input transfer order.
  // ---------------------------------------------------------------------------
  typedef struct packed {
    logic [DATA_WIDTH-1:0] data;
    logic [KEEP_WIDTH-1:0] keep;
    logic                  last;
    logic [USER_WIDTH-1:0] user;
  } rec_t;

  rec_t src_q [0:S_COUNT-1][$];
  int unsigned tag_src [int unsigned];

  int unsigned next_tag;
  int          pending_count;
  int          errors;

  logic        out_active;
  int          out_src;

  logic                  stall_valid;
  logic [DATA_WIDTH-1:0] stall_data;
  logic [KEEP_WIDTH-1:0] stall_keep;
  logic                  stall_last;
  logic [USER_WIDTH-1:0] stall_user;

  logic rst_prev;

  logic fair_en;
  logic fair_stop;
  int   fair_frames;
  int   fair_cur_src;
  int   fair_hist [0:15];

  logic ready_stop;

  task automatic report_fail(input string req, input string msg);
    begin
      if (errors < 40)
        $display("%s: %s", req, msg);
      errors = errors + 1;
    end
  endtask

  // ---------------------------------------------------------------------------
  // Input bookkeeping, output integrity/atomicity checks, backpressure checks,
  // reset checks, and the sliding-window fairness check.
  // ---------------------------------------------------------------------------
  always @(posedge clk) begin : output_monitor
    automatic int          k;
    automatic int          src;
    automatic int          j;
    automatic int          mask;
    automatic int unsigned in_key;
    automatic int unsigned out_key;
    automatic rec_t        in_rec;
    automatic rec_t        out_rec;
    automatic bit          starts_frame;

    if (rst) begin
      for (k = 0; k < S_COUNT; k = k + 1)
        src_q[k].delete();
      tag_src.delete();
      pending_count = 0;
      out_active    = 1'b0;
      out_src       = -1;
      stall_valid   = 1'b0;
    end else begin
      // S12: m_tvalid must still be low on the first cycle following release.
      if (rst_prev && (m_tvalid !== 1'b0))
        report_fail("S12", "m_tvalid_o was high on the first cycle after reset release");

      // AXI4-Stream stability while the output is backpressured (S8).
      if (stall_valid) begin
        if (m_tvalid !== 1'b1) begin
          report_fail("S8", "m_tvalid_o dropped before a stalled output beat transferred");
        end else begin
          if (m_tdata !== stall_data)
            report_fail("S8", "m_tdata_o changed while the output beat was stalled");
          if (m_tkeep !== stall_keep)
            report_fail("S8", "m_tkeep_o changed while the output beat was stalled");
          if (m_tlast !== stall_last)
            report_fail("S8", "m_tlast_o changed while the output beat was stalled");
          if (m_tuser !== stall_user)
            report_fail("S8", "m_tuser_o changed while the output beat was stalled");
        end
      end

      // Record input transfers before examining the output, permitting a legal
      // zero-latency input-to-output transfer on the same clock edge.
      for (k = 0; k < S_COUNT; k = k + 1) begin
        if ((s_tvalid[k] === 1'b1) && (s_tready[k] === 1'b1)) begin
          in_rec.data = s_tdata[k];
          in_rec.keep = s_tkeep[k];
          in_rec.last = s_tlast[k];
          in_rec.user = s_tuser[k];

          in_key = s_tdata[k];
          src_q[k].push_back(in_rec);
          tag_src[in_key] = k;
          pending_count = pending_count + 1;
        end
      end

      if ((m_tvalid === 1'b1) && (m_tready === 1'b1)) begin
        out_key = m_tdata;

        if (!tag_src.exists(out_key)) begin
          report_fail("S4",
              $sformatf("output token %0h is not an outstanding accepted input beat; corruption, duplication, or stale reset data",
                        m_tdata));
        end else begin
          src = tag_src[out_key];

          if (src_q[src].size() == 0) begin
            report_fail("S5", "output bookkeeping found an empty per-input queue");
          end else begin
            out_rec      = src_q[src][0];
            starts_frame = !out_active;

            // S4: the output must be the next transferred beat on that input.
            if (out_rec.data !== m_tdata)
              report_fail("S4",
                  $sformatf("input %0d beats were reordered: expected token %0h, observed %0h",
                            src, out_rec.data, m_tdata));

            // S3: no other input may contribute a beat during an active frame.
            if (out_active && (out_src != src))
              report_fail("S3",
                  $sformatf("frame from input %0d was interleaved with a beat from input %0d",
                            out_src, src));

            if (m_tdata !== out_rec.data)
              report_fail("S4", "m_tdata_o does not match the complete input beat");
            if (m_tkeep !== out_rec.keep)
              report_fail("S4",
                  $sformatf("m_tkeep_o mismatch on token %0h: expected %0h, observed %0h",
                            out_rec.data, out_rec.keep, m_tkeep));
            if (m_tuser !== out_rec.user)
              report_fail("S4",
                  $sformatf("m_tuser_o mismatch on token %0h: expected %0h, observed %0h",
                            out_rec.data, out_rec.user, m_tuser));
            if (m_tlast !== out_rec.last)
              report_fail("S4",
                  $sformatf("m_tlast_o mismatch on token %0h: expected %0b, observed %0b",
                            out_rec.data, out_rec.last, m_tlast));

            src_q[src].pop_front();
            tag_src.delete(out_key);
            pending_count = pending_count - 1;

            if (starts_frame)
              fair_cur_src = src;

            if (out_rec.last) begin
              // S10: inspect every completed sliding window of 16 frames.
              if (fair_en) begin
                fair_hist[fair_frames % 16] = fair_cur_src;
                fair_frames = fair_frames + 1;

                if (fair_frames >= 16) begin
                  mask = 0;
                  for (j = 0; j < 16; j = j + 1) begin
                    if ((fair_hist[j] >= 0) && (fair_hist[j] < S_COUNT))
                      mask = mask | (1 << fair_hist[j]);
                  end

                  if (mask != ((1 << S_COUNT) - 1))
                    report_fail("S10",
                        $sformatf("window ending at output frame %0d began frames only from inputs mask %0h",
                                  fair_frames, mask));
                end
              end

              out_active = 1'b0;
              out_src    = -1;
            end else begin
              out_active = 1'b1;
              out_src    = src;
            end
          end
        end
      end

      stall_valid = (m_tvalid === 1'b1) && (m_tready !== 1'b1);
      if ((m_tvalid === 1'b1) && (m_tready !== 1'b1)) begin
        stall_data = m_tdata;
        stall_keep = m_tkeep;
        stall_last = m_tlast;
        stall_user = m_tuser;
      end
    end

    rst_prev = rst;
  end

  // ---------------------------------------------------------------------------
  // Traffic generation
  // ---------------------------------------------------------------------------
  task automatic send_auto(input int k,
                           input int beat_index,
                           input int frame_beats);
    automatic logic [DATA_WIDTH-1:0] d;
    automatic logic [KEEP_WIDTH-1:0] kp;
    automatic logic [USER_WIDTH-1:0] u;
    automatic int pat;
    begin
      d = next_tag;
      next_tag = next_tag + 1;

      pat = (d[2:0] + beat_index + k) % 8;
      case (pat)
        0: kp = 4'b0000;
        1: kp = 4'b1111;
        2: kp = 4'b0001;
        3: kp = 4'b0010;
        4: kp = 4'b0100;
        5: kp = 4'b1000;
        6: kp = 4'b0101;
        default: kp = 4'b1010;
      endcase

      u = d[0] ^ beat_index[0] ^ k[0];
      bfm_send(k, d, kp, (beat_index == frame_beats-1), u);
    end
  endtask

  task automatic drive_frame(input int k, input int frame_beats);
    automatic int i;
    begin
      for (i = 0; i < frame_beats; i = i + 1)
        send_auto(k, i, frame_beats);
    end
  endtask

  task automatic drive_functional(input int k);
    begin
      case (k)
        0: begin
          drive_frame(0, 1);
          drive_frame(0, 3);
          drive_frame(0, 2);
        end
        1: begin
          drive_frame(1, 2);
          drive_frame(1, 1);
          drive_frame(1, 4);
        end
        2: begin
          drive_frame(2, 4);
          drive_frame(2, 2);
          drive_frame(2, 1);
        end
        default: begin
          drive_frame(3, 3);
          drive_frame(3, 1);
          drive_frame(3, 2);
        end
      endcase
      bfm_idle(k);
    end
  endtask

  task automatic drive_reset_load(input int k);
    begin
      drive_frame(k, k+2);
      drive_frame(k, 1);
      bfm_idle(k);
    end
  endtask

  task automatic drive_post_reset(input int k);
    begin
      drive_frame(k, (k % 2) + 1);
      bfm_idle(k);
    end
  endtask

  // Deterministic long stalls are mixed with randomized ready behaviour.
  // Periodic forced-ready cycles prevent the stimulus itself from starving a
  // correct implementation.
  task automatic random_ready();
    automatic int n;
    begin
      n = 0;
      while (!ready_stop) begin
        @(negedge clk);
        if (!ready_stop) begin
          if ((n % 29) < 5)
            m_tready = 1'b0;
          else if ((n % 29) == 5)
            m_tready = 1'b1;
          else
            m_tready = ($urandom_range(99, 0) < 65);
          n = n + 1;
        end
      end
    end
  endtask

  // Single-beat frames make every accepted beat a complete further frame.
  // Calling send_auto again immediately keeps valid continuously asserted.
  task automatic continuous_source(input int k);
    begin
      while (!fair_stop)
        send_auto(k, 0, 1);
      bfm_idle(k);
    end
  endtask

  task automatic wait_drained();
    begin
      while (errors == 0) begin
        @(negedge clk);
        if ((pending_count == 0) && !out_active)
          break;
      end
    end
  endtask

  // ---------------------------------------------------------------------------
  // Test sequence
  // ---------------------------------------------------------------------------
  initial begin : main_test
    automatic int i;

    s_tdata  = '0;
    s_tkeep  = '0;
    s_tvalid = '0;
    s_tlast  = '0;
    s_tuser  = '0;
    m_tready = 1'b0;

    next_tag      = 32'h0001_0000;
    pending_count = 0;
    errors        = 0;
    out_active    = 1'b0;
    out_src       = -1;
    stall_valid   = 1'b0;
    rst_prev      = 1'b1;

    fair_en      = 1'b0;
    fair_stop    = 1'b0;
    fair_frames  = 0;
    fair_cur_src = -1;
    ready_stop   = 1'b0;
    for (i = 0; i < 16; i = i + 1)
      fair_hist[i] = -1;

    bfm_reset(4);

    // Concurrent framed traffic, including single-beat frames, with frequent
    // mid-frame and end-of-frame backpressure.
    ready_stop = 1'b0;
    fork
      random_ready();
      begin
        fork
          drive_functional(0);
          drive_functional(1);
          drive_functional(2);
          drive_functional(3);
        join
        @(negedge clk);
        ready_stop = 1'b1;
      end
    join

    bfm_ready(1'b1);
    wait_drained();

    // Load complete frames, then synchronously reset. All pre-reset scoreboard
    // state is deliberately discarded; any subsequently leaked old token fails.
    if (errors == 0) begin
      fork
        drive_reset_load(0);
        drive_reset_load(1);
        drive_reset_load(2);
        drive_reset_load(3);
      join

      // The drivers return from bfm_idle on a falling edge, so this is safe.
      // It also preserves any pending output beat long enough to exercise reset.
      m_tready = 1'b0;
      bfm_reset(3);
      bfm_ready(1'b1);
      repeat (2) @(negedge clk);
    end

    if (errors == 0) begin
      fork
        drive_post_reset(0);
        drive_post_reset(1);
        drive_post_reset(2);
        drive_post_reset(3);
      join
      wait_drained();
    end

    // Continuous offered load on every input and continuously ready output.
    if (errors == 0) begin
      bfm_ready(1'b1);

      fair_frames  = 0;
      fair_cur_src = -1;
      fair_stop    = 1'b0;
      for (i = 0; i < 16; i = i + 1)
        fair_hist[i] = -1;
      fair_en = 1'b1;

      fork
        continuous_source(0);
        continuous_source(1);
        continuous_source(2);
        continuous_source(3);
        begin
          wait ((fair_frames >= 96) || (errors != 0));
          @(negedge clk);
          fair_stop = 1'b1;
          fair_en   = 1'b0;
        end
      join

      // Frames accepted before the load was removed must still drain (S5).
      wait_drained();
    end

    // Allow any erroneous extra/duplicate output beat a few cycles to appear.
    repeat (4) @(negedge clk);

    if (errors == 0)
      $display("RESULT: PASS");
    else
      $display("RESULT: FAIL");
    $finish;
  end

  // Independent, unconditional watchdog.
  initial begin
    #20_000_000;
    $display("S5: watchdog expired before all completed frames drained; S10 progress may also have stalled");
    $display("RESULT: FAIL");
    $finish;
  end

endmodule
