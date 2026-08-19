module frame_arb_mux_tb;

  localparam int S_COUNT    = 4;
  localparam int DATA_WIDTH = 32;
  localparam int USER_WIDTH = 1;
  localparam int KEEP_WIDTH = DATA_WIDTH/8;

  // --------------------------------------------------------------------------
  // DUT signals -- packed dimensions exactly match the DUT port declarations.
  // --------------------------------------------------------------------------
  logic [S_COUNT-1:0][DATA_WIDTH-1:0] s_tdata;
  logic [S_COUNT-1:0][KEEP_WIDTH-1:0] s_tkeep;
  logic [S_COUNT-1:0]                 s_tvalid;
  logic [S_COUNT-1:0]                 s_tready;
  logic [S_COUNT-1:0]                 s_tlast;
  logic [S_COUNT-1:0][USER_WIDTH-1:0] s_tuser;

  logic [DATA_WIDTH-1:0]              m_tdata;
  logic [KEEP_WIDTH-1:0]              m_tkeep;
  logic                               m_tvalid;
  logic                               m_tready;
  logic                               m_tlast;
  logic [USER_WIDTH-1:0]              m_tuser;

  // --------------------------------------------------------------------------
  // PROVIDED PLUMBING -- moves beats, checks nothing.
  // --------------------------------------------------------------------------
  logic clk;
  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end

  logic rst;
  initial rst = 1'b1;

  task automatic bfm_reset(input int cycles = 4);
    @(negedge clk);
    rst = 1'b1;
    repeat (cycles) @(posedge clk);
    @(negedge clk);
    rst = 1'b0;
  endtask

  task automatic bfm_send(
      input int                        k,
      input logic [DATA_WIDTH-1:0]     data,
      input logic [KEEP_WIDTH-1:0]     keep,
      input logic                      last,
      input logic [USER_WIDTH-1:0]     user
  );
    @(negedge clk);
    s_tdata[k]  = data;
    s_tkeep[k]  = keep;
    s_tlast[k]  = last;
    s_tuser[k]  = user;
    s_tvalid[k] = 1'b1;

    forever begin
      @(posedge clk);
      if (s_tready[k])
        break;
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

  // --------------------------------------------------------------------------
  // Independent watchdog.
  //
  // A total lack of progress with completed input frames outstanding violates
  // S5. During the fairness phase this also prevents a permanently wedged DUT
  // from blocking the overall regression forever.
  // --------------------------------------------------------------------------
  initial begin
    #20_000_000;
    $display("FAIL S5: watchdog expired with no sufficient forward progress");
    $display("RESULT: FAIL");
    $finish;
  end

  // --------------------------------------------------------------------------
  // DUT
  // --------------------------------------------------------------------------
  frame_arb_mux #(
      .S_COUNT    (S_COUNT),
      .DATA_WIDTH (DATA_WIDTH),
      .USER_WIDTH (USER_WIDTH)
  ) dut (
      .clk_i       (clk),
      .rst_i       (rst),

      .s_tdata_i   (s_tdata),
      .s_tkeep_i   (s_tkeep),
      .s_tvalid_i  (s_tvalid),
      .s_tready_o  (s_tready),
      .s_tlast_i   (s_tlast),
      .s_tuser_i   (s_tuser),

      .m_tdata_o   (m_tdata),
      .m_tkeep_o   (m_tkeep),
      .m_tvalid_o  (m_tvalid),
      .m_tready_i  (m_tready),
      .m_tlast_o   (m_tlast),
      .m_tuser_o   (m_tuser)
  );

  // --------------------------------------------------------------------------
  // Scoreboard bookkeeping.
  //
  // Each generated beat gets a unique 24-bit transaction ID in tdata[23:0].
  // The ID is used strictly as a ledger key.  We never search candidate queue
  // entries for a payload that "looks like" the output beat.
  //
  // The full tdata, tkeep, tuser and tlast values are separately stored and
  // checked after the ledger identifies the accepted input transaction.
  // --------------------------------------------------------------------------
  typedef struct {
    logic [DATA_WIDTH-1:0] data;
    logic [KEEP_WIDTH-1:0] keep;
    logic                  last;
    logic [USER_WIDTH-1:0] user;
    int                    src_idx;
    int                    frame_no;
    int                    beat_no;
    int                    epoch_no;
  } beat_rec_t;

  beat_rec_t src_q [S_COUNT][$];
  beat_rec_t ledger [int unsigned];
  bit        emitted [int unsigned];

  int unsigned tx_seq [S_COUNT];

  int in_frame_no [S_COUNT];
  int in_beat_no  [S_COUNT];

  int epoch_id;
  bit was_rst;

  // Output-frame state for S3.
  bit out_frame_active;
  int out_frame_src;
  int out_frame_no;
  int out_frame_start_src;

  // S8 stall-state bookkeeping.
  bit                        stall_hold;
  logic [DATA_WIDTH-1:0]     stall_data;
  logic [KEEP_WIDTH-1:0]     stall_keep;
  logic                      stall_last;
  logic [USER_WIDTH-1:0]     stall_user;

  // Used to deliberately introduce backpressure after a frame has begun.
  int nonlast_output_xfers;

  // Fairness bookkeeping.
  bit fair_mode;
  int fair_hist[$];
  int fair_completed_frames;

  // --------------------------------------------------------------------------
  // Failure helper.  Fail-fast prevents a corrupt DUT from cascading one bad
  // transaction into hundreds of misleading diagnostics.
  // --------------------------------------------------------------------------
  task automatic fail_now(input string req_name, input string msg);
    $display("FAIL %s: %s", req_name, msg);
    $display("RESULT: FAIL");
    $finish;
  endtask

  // --------------------------------------------------------------------------
  // Test-data generation.
  //
  // tdata[23:0]:
  //   [23:22] source number
  //   [21:0]  monotonically increasing per-source transaction number
  //
  // tdata[31:24] is an independent checksum-like byte so corruption of the
  // upper data byte is also explicitly checked rather than being part of the
  // bookkeeping key.
  // --------------------------------------------------------------------------
  function automatic logic [DATA_WIDTH-1:0] make_data(
      input int          k,
      input int unsigned seq_no
  );
    automatic logic [23:0] token_bits;
    automatic logic [7:0]  check_bits;

    token_bits = ((k & 3) << 22) | (seq_no & 22'h3fffff);
    check_bits = 8'hA7 ^
                 token_bits[7:0] ^
                 token_bits[15:8] ^
                 token_bits[23:16];

    make_data = {check_bits, token_bits};
  endfunction

  function automatic logic [KEEP_WIDTH-1:0] make_keep(
      input int unsigned seq_no
  );
    case (seq_no % 6)
      0: make_keep = 4'hf;
      1: make_keep = 4'h5;
      2: make_keep = 4'ha;
      3: make_keep = 4'h3;
      4: make_keep = 4'hc;
      default: make_keep = 4'h9;
    endcase
  endfunction

  function automatic logic [USER_WIDTH-1:0] make_user(
      input int          k,
      input int unsigned seq_no
  );
    make_user = seq_no[0] ^ k[0];
  endfunction

  // --------------------------------------------------------------------------
  // Generate a complete frame on one source.
  //
  // S7 is obeyed by bfm_send: every presented beat remains unchanged until its
  // handshake.  Every frame this task starts is completed.
  // --------------------------------------------------------------------------
  task automatic send_frame(input int k, input int beat_count);
    automatic int b;
    automatic int unsigned seq_no;
    automatic logic [DATA_WIDTH-1:0] data_word;
    automatic logic [KEEP_WIDTH-1:0] keep_word;
    automatic logic [USER_WIDTH-1:0] user_word;
    automatic logic                  last_word;

    for (b = 0; b < beat_count; b = b + 1) begin
      seq_no   = tx_seq[k];
      tx_seq[k] = tx_seq[k] + 1;

      data_word = make_data(k, seq_no);
      keep_word = make_keep(seq_no);
      user_word = make_user(k, seq_no);

      if (b == beat_count-1)
        last_word = 1'b1;
      else
        last_word = 1'b0;

      bfm_send(k, data_word, keep_word, last_word, user_word);
    end
  endtask

  // A mixture of single-beat and multi-beat frames.
  task automatic basic_source(input int k);
    case (k)
      0: begin
        send_frame(0, 1);   // S2 single-beat frame
        send_frame(0, 5);
        send_frame(0, 2);
        send_frame(0, 4);
        bfm_idle(0);
      end

      1: begin
        send_frame(1, 3);
        send_frame(1, 1);   // S2 single-beat frame
        send_frame(1, 6);
        send_frame(1, 2);
        bfm_idle(1);
      end

      2: begin
        send_frame(2, 4);
        send_frame(2, 2);
        send_frame(2, 1);   // S2 single-beat frame
        send_frame(2, 5);
        bfm_idle(2);
      end

      default: begin
        send_frame(3, 2);
        send_frame(3, 6);
        send_frame(3, 3);
        send_frame(3, 1);   // S2 single-beat frame
        bfm_idle(3);
      end
    endcase
  endtask

  // Continuous single-beat frames for S10.
  //
  // s_tvalid never drops between frames: when one bfm_send returns at a
  // positive edge, the next invocation changes the payload at the following
  // negative edge while leaving valid asserted.
  task automatic fairness_source(input int k);
    forever begin
      send_frame(k, 1);
    end
  endtask

  function automatic bit queues_empty();
    automatic int k;

    queues_empty = 1'b1;
    for (k = 0; k < S_COUNT; k = k + 1) begin
      if (src_q[k].size() != 0)
        queues_empty = 1'b0;
    end
  endfunction

  task automatic wait_for_drain();
    while (!queues_empty())
      @(posedge clk);

    // Move away from the sampling edge before the caller proceeds.
    @(negedge clk);
  endtask

  // --------------------------------------------------------------------------
  // Monitor / scoreboard.
  //
  // All handshake decisions are made only at rising edges per S1.
  // s_tready is never interpreted as an arbitration grant (S6).
  // --------------------------------------------------------------------------
  always @(posedge clk) begin : scoreboard_monitor
    automatic int k;
    automatic int j;
    automatic int unsigned token_id;
    automatic beat_rec_t rec_now;
    automatic beat_rec_t exp_rec;
    automatic int dropped_src;
    automatic bit seen_src;
    automatic bit fair_conditions;

    // ------------------------------------------------------------------------
    // S12 -- synchronous reset.
    // ------------------------------------------------------------------------
    if (rst) begin
      if (!was_rst)
        epoch_id = epoch_id + 1;

      // Once reset has already sampled high for one full clock, the interface
      // must be in the idle reset state.
      if (was_rst) begin
        if (m_tvalid !== 1'b0) begin
          fail_now(
              "S12",
              "m_tvalid_o remained asserted while synchronous reset was held"
          );
        end
      end

      for (k = 0; k < S_COUNT; k = k + 1) begin
        src_q[k].delete();
        in_frame_no[k] = 0;
        in_beat_no[k]  = 0;
      end

      out_frame_active = 1'b0;
      stall_hold       = 1'b0;

      fair_hist.delete();
      fair_completed_frames = 0;

    end else begin

      // First rising edge following reset release.
      if (was_rst) begin
        if (m_tvalid !== 1'b0) begin
          fail_now(
              "S12",
              "m_tvalid_o was not low on the first cycle after reset release"
          );
        end
      end

      // ----------------------------------------------------------------------
      // S8 -- once an AXI-Stream beat is offered while READY is low, it must
      // remain offered unchanged.  This is also necessary to prevent a beat
      // from being lost under output backpressure.
      // ----------------------------------------------------------------------
      if (stall_hold) begin
        if (m_tvalid !== 1'b1) begin
          fail_now(
              "S8",
              "m_tvalid_o was withdrawn while an output beat was stalled"
          );
        end

        if ((m_tdata !== stall_data) ||
            (m_tkeep !== stall_keep) ||
            (m_tlast !== stall_last) ||
            (m_tuser !== stall_user)) begin
          fail_now(
              "S8",
              "output payload changed while m_tvalid_o=1 and m_tready_i=0"
          );
        end
      end

      stall_hold = m_tvalid && !m_tready;

      if (m_tvalid && !m_tready) begin
        stall_data = m_tdata;
        stall_keep = m_tkeep;
        stall_last = m_tlast;
        stall_user = m_tuser;
      end

      // ----------------------------------------------------------------------
      // S1/S4 -- record exactly the beats that actually transfer on each input.
      // This is bookkeeping only; READY by itself has no selection meaning.
      // ----------------------------------------------------------------------
      for (k = 0; k < S_COUNT; k = k + 1) begin
        if (s_tvalid[k] && s_tready[k]) begin
          rec_now.data     = s_tdata[k];
          rec_now.keep     = s_tkeep[k];
          rec_now.last     = s_tlast[k];
          rec_now.user     = s_tuser[k];
          rec_now.src_idx  = k;
          rec_now.frame_no = in_frame_no[k];
          rec_now.beat_no  = in_beat_no[k];
          rec_now.epoch_no = epoch_id;

          token_id = s_tdata[k][23:0];

          ledger[token_id] = rec_now;
          src_q[k].push_back(rec_now);

          if (s_tlast[k]) begin
            in_frame_no[k] = in_frame_no[k] + 1;
            in_beat_no[k]  = 0;
          end else begin
            in_beat_no[k] = in_beat_no[k] + 1;
          end
        end
      end

      // ----------------------------------------------------------------------
      // Output transfer -- S1.
      // ----------------------------------------------------------------------
      if (m_tvalid && m_tready) begin
        token_id = m_tdata[23:0];

        // Every output beat must correspond to a beat that really transferred
        // on an input.  Unknown transaction IDs cannot be legitimate output.
        if (!ledger.exists(token_id)) begin
          fail_now(
              "S4",
              $sformatf(
                  "output beat 0x%08x has no accepted input transaction",
                  m_tdata
              )
          );
        end

        rec_now = ledger[token_id];

        // Anything accepted in an older epoch was discarded by reset.
        if (rec_now.epoch_no != epoch_id) begin
          fail_now(
              "S12",
              $sformatf(
                  "pre-reset transaction 0x%06x appeared after reset",
                  token_id
              )
          );
        end

        // S5 -- no duplication.
        if (emitted.exists(token_id)) begin
          if (emitted[token_id]) begin
            fail_now(
                "S5",
                $sformatf(
                    "transaction 0x%06x was emitted more than once",
                    token_id
                )
            );
          end
        end

        // A currently accepted transaction must still be present at the head
        // of its source's ordered queue.
        if ((rec_now.src_idx < 0) ||
            (rec_now.src_idx >= S_COUNT) ||
            (src_q[rec_now.src_idx].size() == 0)) begin
          fail_now(
              "S5",
              $sformatf(
                  "output transaction 0x%06x has no remaining source beat",
                  token_id
              )
          );
        end

        exp_rec = src_q[rec_now.src_idx].pop_front();

        // --------------------------------------------------------------------
        // S4 -- per-input ordering.
        //
        // rec_now identifies the transaction via the ledger; exp_rec is the
        // next transaction that is legally allowed to leave that source.
        // --------------------------------------------------------------------
        if ((rec_now.frame_no != exp_rec.frame_no) ||
            (rec_now.beat_no  != exp_rec.beat_no)) begin
          fail_now(
              "S4",
              $sformatf(
                  "input %0d output order changed: got frame %0d beat %0d, expected frame %0d beat %0d",
                  rec_now.src_idx,
                  rec_now.frame_no,
                  rec_now.beat_no,
                  exp_rec.frame_no,
                  exp_rec.beat_no
              )
          );
        end

        // Full-width payload/sideband integrity.
        if (m_tdata !== exp_rec.data) begin
          fail_now(
              "S4",
              $sformatf(
                  "tdata corruption: got 0x%08x expected 0x%08x",
                  m_tdata,
                  exp_rec.data
              )
          );
        end

        if (m_tkeep !== exp_rec.keep) begin
          fail_now(
              "S4",
              $sformatf(
                  "tkeep corruption on transaction 0x%06x: got 0x%x expected 0x%x",
                  token_id,
                  m_tkeep,
                  exp_rec.keep
              )
          );
        end

        if (m_tuser !== exp_rec.user) begin
          fail_now(
              "S4",
              $sformatf(
                  "tuser corruption on transaction 0x%06x",
                  token_id
              )
          );
        end

        if (m_tlast !== exp_rec.last) begin
          fail_now(
              "S4",
              $sformatf(
                  "tlast mismatch on input %0d frame %0d beat %0d",
                  rec_now.src_idx,
                  rec_now.frame_no,
                  rec_now.beat_no
              )
          );
        end

        // --------------------------------------------------------------------
        // S3 -- frame atomicity.
        //
        // Arbitration order itself is deliberately NOT checked (S9).
        // --------------------------------------------------------------------
        if (!out_frame_active) begin
          out_frame_src       = rec_now.src_idx;
          out_frame_no        = rec_now.frame_no;
          out_frame_start_src = rec_now.src_idx;
        end else begin
          if ((rec_now.src_idx != out_frame_src) ||
              (rec_now.frame_no != out_frame_no)) begin
            fail_now(
                "S3",
                $sformatf(
                    "frame interleaving: active input/frame %0d/%0d, observed %0d/%0d",
                    out_frame_src,
                    out_frame_no,
                    rec_now.src_idx,
                    rec_now.frame_no
                )
            );
          end
        end

        emitted[token_id] = 1'b1;

        if (!m_tlast) begin
          out_frame_active = 1'b1;
          nonlast_output_xfers = nonlast_output_xfers + 1;
        end else begin
          out_frame_active = 1'b0;
        end

        // --------------------------------------------------------------------
        // S10 -- bounded fairness.
        //
        // The fairness stimulus consists exclusively of single-beat frames.
        // Therefore each completed frame's source is also exactly the source
        // that began that frame.
        //
        // Only windows sampled while all four sources are continuously valid
        // and the sink is continuously ready participate in this check.
        // --------------------------------------------------------------------
        fair_conditions = fair_mode &&
                          (&s_tvalid) &&
                          m_tready;

        if (fair_mode && !fair_conditions) begin
          fair_hist.delete();
          fair_completed_frames = 0;
        end

        if (fair_conditions && m_tlast) begin
          fair_hist.push_back(out_frame_start_src);
          fair_completed_frames = fair_completed_frames + 1;

          if (fair_hist.size() > 16)
            dropped_src = fair_hist.pop_front();

          if (fair_hist.size() == 16) begin
            for (k = 0; k < S_COUNT; k = k + 1) begin
              seen_src = 1'b0;

              for (j = 0; j < 16; j = j + 1) begin
                if (fair_hist[j] == k)
                  seen_src = 1'b1;
              end

              if (!seen_src) begin
                fail_now(
                    "S10",
                    $sformatf(
                        "input %0d did not begin a frame within a 16-completed-frame continuous-load window",
                        k
                    )
                );
              end
            end
          end
        end
      end

      // If fairness conditions disappear on a cycle without an output
      // transfer, that also terminates the current continuous-load window.
      if (fair_mode) begin
        if (!((&s_tvalid) && m_tready)) begin
          fair_hist.delete();
          fair_completed_frames = 0;
        end
      end
    end

    was_rst = rst;
  end

  // --------------------------------------------------------------------------
  // Initial state.
  // --------------------------------------------------------------------------
  integer init_k;
  initial begin
    s_tdata  = '0;
    s_tkeep  = '0;
    s_tvalid = '0;
    s_tlast  = '0;
    s_tuser  = '0;
    m_tready = 1'b0;

    epoch_id = 0;
    was_rst  = 1'b0;

    out_frame_active    = 1'b0;
    out_frame_src       = 0;
    out_frame_no        = 0;
    out_frame_start_src = 0;

    stall_hold = 1'b0;
    stall_data = '0;
    stall_keep = '0;
    stall_last = 1'b0;
    stall_user = '0;

    nonlast_output_xfers = 0;

    fair_mode             = 1'b0;
    fair_completed_frames = 0;

    for (init_k = 0; init_k < S_COUNT; init_k = init_k + 1) begin
      tx_seq[init_k]      = 0;
      in_frame_no[init_k] = 0;
      in_beat_no[init_k]  = 0;
    end
  end

  // --------------------------------------------------------------------------
  // Main test.
  //
  // No arbitration order or latency assumption is made anywhere.
  // --------------------------------------------------------------------------
  initial begin : main_test
    automatic int stall_base;

    // ------------------------------------------------------------------------
    // S12 -- initial synchronous reset and mandated first post-reset idle cycle.
    // ------------------------------------------------------------------------
    bfm_reset(4);

    // Output is allowed to remain backpressured initially.  Release it without
    // making any assumption about input READY.
    bfm_ready(1'b1);

    // ------------------------------------------------------------------------
    // S2/S3/S4/S5/S6/S8/S9/S11:
    //
    // All four inputs issue complete frames concurrently.  Lengths vary,
    // single-beat frames are included, and payload/keep/user patterns vary.
    //
    // Because all sources run concurrently, the DUT is free to choose any
    // frame order.  The scoreboard derives legality from accepted input
    // transactions, never from s_tready as a "grant".
    // ------------------------------------------------------------------------
    stall_base = nonlast_output_xfers;

    fork
      begin
        basic_source(0);
      end

      begin
        basic_source(1);
      end

      begin
        basic_source(2);
      end

      begin
        basic_source(3);
      end

      // ----------------------------------------------------------------------
      // S8 -- force backpressure after a multi-beat output frame has actually
      // begun.  READY remains low across several rising edges, then returns.
      //
      // We do not require the DUT to present the next beat while READY is low;
      // latency is explicitly unconstrained by S11.
      // ----------------------------------------------------------------------
      begin
        wait (nonlast_output_xfers > stall_base);
        bfm_ready(1'b0);
        repeat (8) @(posedge clk);
        bfm_ready(1'b1);
      end
    join

    // S5 -- all frames above are complete, so every accepted beat must
    // eventually leave exactly once.
    wait_for_drain();

    // Leave the sink enabled for a few additional clocks.  Any immediate
    // duplicate or unsolicited transfer is caught by the scoreboard.
    repeat (4) @(posedge clk);
    @(negedge clk);

    // ------------------------------------------------------------------------
    // S12 -- reset again after real traffic has flowed.
    //
    // The ledger is intentionally retained across reset epochs.  Therefore if
    // any old transaction reappears after this reset it is detected as S12,
    // even though the normal expected queues are flushed.
    // ------------------------------------------------------------------------
    bfm_reset(4);

    // Let the required first post-reset cycle occur before starting fairness
    // traffic.
    @(posedge clk);
    @(negedge clk);

    m_tready = 1'b1;

    // ------------------------------------------------------------------------
    // S10 -- continuous offered load.
    //
    // Four infinite source threads offer single-beat complete frames.  They
    // are intentionally left running until $finish so no source ever runs out
    // and no shutdown transient weakens the fairness premise.
    // ------------------------------------------------------------------------
    fork
      fairness_source(0);
      fairness_source(1);
      fairness_source(2);
      fairness_source(3);
    join_none

    // Wait until every source really is presenting VALID simultaneously.
    wait (&s_tvalid);

    // Enable fairness checking away from the rising sampling edge.
    @(negedge clk);
    fair_hist.delete();
    fair_completed_frames = 0;
    fair_mode = 1'b1;

    // Check substantially more than one 16-frame window.  The monitor checks
    // every overlapping 16-completed-frame window.
    while (fair_completed_frames < 48)
      @(posedge clk);

    // Let the scoreboard finish processing the final rising edge before PASS.
    @(negedge clk);
    fair_mode = 1'b0;

    $display("RESULT: PASS");
    $finish;
  end

endmodule