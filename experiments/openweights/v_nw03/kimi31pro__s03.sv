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
  // PROVIDED PLUMBING
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
                          input logic [KEEP_WIDTH-1:0]       keep,
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
  // Every generated data word is a globally unique bookkeeping token.  The
  // token identifies the input-handshake record; it is not used to search for
  // a matching value among repeated payloads.  Per-input queues independently
  // enforce the order in which beats transferred on each input.
  // ---------------------------------------------------------------------------
  localparam int ST_PENDING = 0;
  localparam int ST_EMITTED = 1;
  localparam int ST_FLUSHED = 2;

  typedef struct {
    logic [DATA_WIDTH-1:0] tag;
    logic [DATA_WIDTH-1:0] data;
    logic [KEEP_WIDTH-1:0] keep;
    logic                  last;
    logic [USER_WIDTH-1:0] user;
    int                    src;
    int                    epoch;
    int                    state;
  } beat_t;

  beat_t beat_info[int unsigned];
  beat_t exp_q[S_COUNT][$];

  int unsigned next_tag;
  int          epoch;
  int          pending_total;
  int          error_count;

  logic frame_active;
  int   frame_src;

  logic                  release_pending;
  logic                  hold_active;
  logic [DATA_WIDTH-1:0] hold_data;
  logic [KEEP_WIDTH-1:0] hold_keep;
  logic                  hold_last;
  logic [USER_WIDTH-1:0] hold_user;

  logic fair_enable;
  logic fair_stop;
  logic fair_error_reported;
  int   fair_count;
  int   fair_hist[$];

  task automatic note_fail(input string req, input string msg);
    $display("ERROR %s: %s (time=%0t)", req, msg, $time);
    error_count = error_count + 1;
  endtask

  task automatic report_and_finish;
    if (error_count == 0)
      $display("RESULT: PASS");
    else
      $display("RESULT: FAIL");
    $finish;
  endtask

  // S1/S2: book every input transfer.  S3/S4/S5: check every output transfer.
  // S8: also check that a stalled output beat remains asserted and stable.
  // S10: maintain a sliding window of sixteen completed output frames.
  // S12: flush all pre-reset bookkeeping and check the first released cycle.
  always @(posedge clk) begin : monitor_beats
    automatic beat_t b;
    automatic beat_t head_b;
    automatic int unsigned out_tag;
    automatic int src;
    automatic int mask;
    automatic int h;
    automatic int discarded;

    if (rst) begin
      for (int qk = 0; qk < S_COUNT; qk = qk + 1) begin
        for (int qe = 0; qe < exp_q[qk].size(); qe = qe + 1) begin
          b = exp_q[qk][qe];
          if (b.state == ST_PENDING) begin
            b.state = ST_FLUSHED;
            beat_info[b.tag] = b;
          end
        end
        exp_q[qk].delete();
      end
      pending_total   = 0;
      frame_active    = 1'b0;
      hold_active     = 1'b0;
      release_pending = 1'b1;
      epoch           = epoch + 1;
    end else begin
      if (release_pending) begin
        if (m_tvalid)
          note_fail("S12", "m_tvalid_o was high on the first cycle after reset release");
        release_pending = 1'b0;
      end

      if (hold_active) begin
        if (!m_tvalid) begin
          note_fail("S8", "m_tvalid_o dropped while an output beat was backpressured");
        end else if ((m_tdata !== hold_data) ||
                     (m_tkeep !== hold_keep) ||
                     (m_tlast !== hold_last) ||
                     (m_tuser !== hold_user)) begin
          note_fail("S8", "output payload or TLAST changed while backpressured");
        end
      end

      hold_active = 1'b0;
      if (m_tvalid && !m_tready) begin
        hold_data   = m_tdata;
        hold_keep   = m_tkeep;
        hold_last   = m_tlast;
        hold_user   = m_tuser;
        hold_active = 1'b1;
      end

      // Record inputs before the output so a combinational pass-through beat,
      // transferring on both sides at this edge, is already booked.
      for (int ik = 0; ik < S_COUNT; ik = ik + 1) begin
        if (s_tvalid[ik] && s_tready[ik]) begin
          b.tag   = s_tdata[ik];
          b.data  = s_tdata[ik];
          b.keep  = s_tkeep[ik];
          b.last  = s_tlast[ik];
          b.user  = s_tuser[ik];
          b.src   = ik;
          b.epoch = epoch;
          b.state = ST_PENDING;
          beat_info[b.tag] = b;
          exp_q[ik].push_back(b);
          pending_total = pending_total + 1;
        end
      end

      if (m_tvalid && m_tready) begin
        out_tag = m_tdata;

        if (!beat_info.exists(out_tag)) begin
          note_fail("S4",
                    $sformatf("output tag %08x has no corresponding input transfer",
                              out_tag));
        end else begin
          b = beat_info[out_tag];

          if ((b.epoch != epoch) || (b.state == ST_FLUSHED)) begin
            note_fail("S12",
                      $sformatf("pre-reset beat tag %08x appeared after reset",
                                out_tag));
          end else if (b.state != ST_PENDING) begin
            note_fail("S5",
                      $sformatf("beat tag %08x was duplicated on the output",
                                out_tag));
          end else begin
            src = b.src;

            if (!frame_active) begin
              frame_active = 1'b1;
              frame_src    = src;
            end else if (src != frame_src) begin
              note_fail("S3",
                        $sformatf("frame source changed from input %0d to input %0d",
                                  frame_src, src));
            end

            if (exp_q[src].size() == 0) begin
              note_fail("S5",
                        $sformatf("output tag %08x had no pending beat on input %0d",
                                  out_tag, src));
            end else if (exp_q[src][0].tag != out_tag) begin
              note_fail("S4",
                        $sformatf("input %0d beat order violated: expected tag %08x, got %08x",
                                  src, exp_q[src][0].tag, out_tag));
            end else begin
              head_b = exp_q[src].pop_front();
            end

            if ((m_tdata !== b.data) ||
                (m_tkeep !== b.keep) ||
                (m_tuser !== b.user) ||
                (m_tlast !== b.last)) begin
              note_fail("S4",
                        $sformatf("field mismatch for tag %08x: data %08x/%08x keep %x/%x user %x/%x last %b/%b",
                                  out_tag, m_tdata, b.data, m_tkeep, b.keep,
                                  m_tuser, b.user, m_tlast, b.last));
            end

            b.state = ST_EMITTED;
            beat_info[out_tag] = b;
            pending_total = pending_total - 1;

            if (m_tlast) begin
              if (fair_enable) begin
                fair_hist.push_back(frame_src);
                fair_count = fair_count + 1;

                if (fair_hist.size() == 16) begin
                  mask = 0;
                  for (h = 0; h < 16; h = h + 1)
                    mask = mask | (1 << fair_hist[h]);

                  if ((mask != ((1 << S_COUNT) - 1)) &&
                      !fair_error_reported) begin
                    note_fail("S10",
                              $sformatf("window ending at completed frame %0d omitted an input (source mask %x)",
                                        fair_count, mask));
                    fair_error_reported = 1'b1;
                  end
                  discarded = fair_hist.pop_front();
                end
              end
              frame_active = 1'b0;
            end else if (b.last) begin
              // Resynchronise after an already-reported bad TLAST.
              frame_active = 1'b0;
            end
          end
        end
      end
    end
  end

  // Wait for every accepted, complete frame to drain.  No finite latency is
  // imposed here; the independent watchdog handles a design that stops.
  task automatic drain_expected;
    while (((pending_total != 0) || frame_active) && (error_count == 0))
      @(negedge clk);
  endtask

  function automatic logic [KEEP_WIDTH-1:0] pattern_keep(input int value);
    case (value % 4)
      0:       pattern_keep = 4'hf;
      1:       pattern_keep = 4'h5;
      2:       pattern_keep = 4'ha;
      default: pattern_keep = 4'h0;
    endcase
  endfunction

  task automatic send_tagged(input int                    k,
                             input logic                  last_value,
                             input logic [KEEP_WIDTH-1:0] keep_value,
                             input logic [USER_WIDTH-1:0] user_value);
    logic [DATA_WIDTH-1:0] d;
    d = 32'h1000_0000 + next_tag;
    next_tag = next_tag + 1;
    bfm_send(k, d, keep_value, last_value, user_value);
  endtask

  // Complete every frame before removing valid.  Length one is included, as
  // are varied KEEP and USER values and back-to-back frames.
  task automatic drive_traffic(input int k, input int frame_total);
    int f;
    int b;
    int len;
    logic user_value;
    for (f = 0; f < frame_total; f = f + 1) begin
      len = 1 + ((f + k) % 4);
      for (b = 0; b < len; b = b + 1) begin
        user_value = (((f + b + k) % 2) == 1);
        send_tagged(k, (b == len-1), pattern_keep(f*3+b+k), user_value);
      end
    end
    bfm_idle(k);
  endtask

  task automatic ready_stress(input int cycles);
    int r;
    logic value;
    for (r = 0; r < cycles; r = r + 1) begin
      if (((r % 29) < 7) || ((r % 11) == 10))
        value = 1'b0;
      else
        value = 1'b1;
      bfm_ready(value);
    end
  endtask

  // Valid remains continuously asserted between frames until fair_stop is
  // requested.  A stop request is acted upon only at a frame boundary.
  task automatic fair_driver(input int k);
    int f;
    int b;
    int len;
    logic user_value;
    f = 0;
    while (!fair_stop) begin
      len = 1 + ((f + k) % 3);
      for (b = 0; b < len; b = b + 1) begin
        user_value = (((f + b + k) % 2) == 1);
        send_tagged(k, (b == len-1), pattern_keep(f+b+k), user_value);
      end
      f = f + 1;
    end
    bfm_idle(k);
  endtask

  // ---------------------------------------------------------------------------
  // Test sequence
  // ---------------------------------------------------------------------------
  initial begin
    s_tdata  = '0;
    s_tkeep  = '0;
    s_tvalid = '0;
    s_tlast  = '0;
    s_tuser  = '0;
    m_tready = 1'b0;

    next_tag            = 1;
    epoch               = 0;
    pending_total       = 0;
    error_count         = 0;
    frame_active        = 1'b0;
    frame_src           = 0;
    release_pending     = 1'b0;
    hold_active         = 1'b0;
    fair_enable         = 1'b0;
    fair_stop           = 1'b0;
    fair_error_reported = 1'b0;
    fair_count          = 0;
    fair_hist.delete();

    bfm_reset(5);
    bfm_ready(1'b1);

    // Concurrent framed traffic: integrity, ordering, atomicity, and drain.
    fork
      drive_traffic(0, 6);
      drive_traffic(1, 6);
      drive_traffic(2, 6);
      drive_traffic(3, 6);
    join
    drain_expected();
    if (error_count != 0) report_and_finish();

    // Repeated backpressure, including multi-cycle stalls while frames are in
    // progress.  No assumption is made about which input is selected.
    fork
      begin
        fork
          drive_traffic(0, 8);
          drive_traffic(1, 8);
          drive_traffic(2, 8);
          drive_traffic(3, 8);
        join
      end
      ready_stress(420);
    join
    bfm_ready(1'b1);
    drain_expected();
    if (error_count != 0) report_and_finish();

    // S10: all four sources offer complete frames continuously and the sink is
    // held ready until the fairness measurement has finished.
    bfm_ready(1'b1);
    @(negedge clk);
    fair_hist.delete();
    fair_count          = 0;
    fair_error_reported = 1'b0;
    fair_stop           = 1'b0;
    fair_enable         = 1'b1;

    fork
      fair_driver(0);
      fair_driver(1);
      fair_driver(2);
      fair_driver(3);
      begin
        while (fair_count < 80)
          @(negedge clk);
        fair_enable = 1'b0;
        fair_stop   = 1'b1;
      end
    join

    drain_expected();
    if (error_count != 0) report_and_finish();

    // S12: leave any not-yet-emitted pre-reset traffic stalled, synchronously
    // reset it away, then send distinctly tagged post-reset traffic.
    fork
      drive_traffic(0, 2);
      drive_traffic(1, 2);
      drive_traffic(2, 2);
      drive_traffic(3, 2);
    join
    bfm_ready(1'b0);
    bfm_reset(4);
    bfm_ready(1'b1);

    fork
      drive_traffic(0, 3);
      drive_traffic(1, 3);
      drive_traffic(2, 3);
      drive_traffic(3, 3);
    join
    drain_expected();
    if (error_count != 0) report_and_finish();

    // Allow any spurious late duplicate to be observed before passing.
    repeat (20) @(negedge clk);
    report_and_finish();
  end

  // Independent, unconditional termination.
  initial begin
    #20_000_000;
    $display("ERROR S5: watchdog expired while awaiting required output progress");
    $display("RESULT: FAIL");
    $finish;
  end

endmodule
