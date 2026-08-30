module frame_arb_mux_tb;

  localparam int S_COUNT    = 4;
  localparam int DATA_WIDTH = 32;
  localparam int USER_WIDTH = 1;
  localparam int KEEP_WIDTH = DATA_WIDTH / 8;

  localparam int WAIT_LIMIT = 100000;

  // ==========================================================================
  // DUT signals
  // ==========================================================================

  logic clk;
  logic rst;

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


  // ==========================================================================
  // Clock
  // ==========================================================================

  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end


  // ==========================================================================
  // Provided-style BFM
  // ==========================================================================

  initial rst = 1'b1;


  task automatic bfm_reset(
      input integer cycles
  );
    begin
      @(negedge clk);
      rst = 1'b1;

      repeat (cycles)
        @(posedge clk);

      @(negedge clk);
      rst = 1'b0;
    end
  endtask


  task automatic bfm_send(
      input integer                    k,
      input logic [DATA_WIDTH-1:0]     data_v,
      input logic [KEEP_WIDTH-1:0]     keep_v,
      input logic                      last_v,
      input logic [USER_WIDTH-1:0]     user_v
  );
    begin
      @(negedge clk);

      s_tdata[k]  = data_v;
      s_tkeep[k]  = keep_v;
      s_tlast[k]  = last_v;
      s_tuser[k]  = user_v;
      s_tvalid[k] = 1'b1;

      forever begin
        @(posedge clk);

        if (s_tready[k])
          break;
      end
    end
  endtask


  task automatic bfm_idle(
      input integer k
  );
    begin
      @(negedge clk);
      s_tvalid[k] = 1'b0;
    end
  endtask


  task automatic bfm_ready(
      input logic value
  );
    begin
      @(negedge clk);
      m_tready = value;
    end
  endtask


  // ==========================================================================
  // Initial stimulus values
  // ==========================================================================

  initial begin : init_inputs
    integer k;

    s_tdata  = '0;
    s_tkeep  = '0;
    s_tvalid = '0;
    s_tlast  = '0;
    s_tuser  = '0;

    m_tready = 1'b1;

    for (k = 0; k < S_COUNT; k = k + 1) begin
      s_tdata[k] = '0;
      s_tkeep[k] = '0;
      s_tlast[k] = 1'b0;
      s_tuser[k] = '0;
    end
  end


  // ==========================================================================
  // Scoreboard records
  // ==========================================================================

  typedef struct packed {
    logic [DATA_WIDTH-1:0]  data;
    logic [KEEP_WIDTH-1:0]  keep;
    logic                   last;
    logic [USER_WIDTH-1:0]  user;
  } beat_rec_t;


  /*
   * One FIFO for each input.
   *
   * Selection order between inputs is deliberately not predicted.  At the
   * start of an output frame, the current output beat is associated with one
   * of the legal FIFO heads.  Once that source is known, the checker locks to
   * it until TLAST, enforcing S3.
   *
   * All generated beats have unique bookkeeping payloads, so source identity
   * is unambiguous.
   */
  beat_rec_t pending_q [0:S_COUNT-1][$];


  integer fail_count;

  integer accepted_beat_count;
  integer accepted_frame_count;
  integer output_beat_count;
  integer output_frame_count;

  logic   frame_active;
  integer frame_source;


  // ==========================================================================
  // Backpressure stability bookkeeping
  // ==========================================================================

  logic      stalled_offer;
  beat_rec_t stalled_beat;


  // ==========================================================================
  // Fairness bookkeeping
  // ==========================================================================

  logic fair_active;
  logic fair_stop;
  logic fair_check_active;

  logic [S_COUNT-1:0] fair_accept_q;

  integer fair_seq [0:S_COUNT-1];

  integer fair_frame_no;
  integer fair_last_seen [0:S_COUNT-1];

  logic fair_fail_reported;


  // ==========================================================================
  // Miscellaneous phase controls
  // ==========================================================================

  logic atomic_stall_started;


  // ==========================================================================
  // Diagnostics
  // ==========================================================================

  task automatic fail_req(
      input string req_name,
      input string detail
  );
    begin
      fail_count = fail_count + 1;
      $display("FAIL %s: %s", req_name, detail);
    end
  endtask


  // ==========================================================================
  // Beat comparison
  // ==========================================================================

  function automatic logic beat_equal(
      input beat_rec_t                  exp_b,
      input logic [DATA_WIDTH-1:0]      data_v,
      input logic [KEEP_WIDTH-1:0]      keep_v,
      input logic                       last_v,
      input logic [USER_WIDTH-1:0]      user_v
  );
    begin
      beat_equal =
          (exp_b.data === data_v) &&
          (exp_b.keep === keep_v) &&
          (exp_b.last === last_v) &&
          (exp_b.user === user_v);
    end
  endfunction


  // ==========================================================================
  // S10 fairness window
  // ==========================================================================

  task automatic fairness_frame_seen(
      input integer src
  );
    integer k;

    begin
      fair_frame_no =
          fair_frame_no + 1;

      if (
          (src >= 0) &&
          (src < S_COUNT)
      )
        fair_last_seen[src] =
            fair_frame_no;


      /*
       * In every sliding window of 16 completed frames, all four continuously
       * loaded inputs must have begun at least one frame.
       *
       * For this phase every frame is one beat, so its begin and completion
       * occur on the same output transfer.
       */
      if (fair_frame_no >= 16) begin

        for (k = 0; k < S_COUNT; k = k + 1) begin

          if (
              !fair_fail_reported &&
              (
                fair_last_seen[k] <
                (fair_frame_no - 15)
              )
          ) begin

            fair_fail_reported =
                1'b1;

            fail_req(
                "S10",
                "an input was absent from a 16-completed-frame fairness window"
            );

          end

        end

      end
    end
  endtask


  // ==========================================================================
  // Fairness source handshake capture
  // ==========================================================================

  always @(posedge clk) begin
    if (rst)
      fair_accept_q <= '0;
    else
      fair_accept_q <=
          s_tvalid & s_tready;
  end


  // ==========================================================================
  // Continuous fairness source driver
  //
  // All four inputs continuously offer complete one-beat frames.  After each
  // handshake the next bookkeeping payload is installed at the falling edge,
  // so VALID never needs to be withdrawn between frames.
  // ==========================================================================

  always @(negedge clk) begin : fairness_driver
    integer k;

    if (
        fair_active &&
        !rst
    ) begin

      for (k = 0; k < S_COUNT; k = k + 1) begin

        if (!s_tvalid[k]) begin

          if (!fair_stop) begin

            s_tdata[k] =
                32'hA000_0000 |
                (k << 24) |
                fair_seq[k];

            case (k)
              0: s_tkeep[k] = 4'b1111;
              1: s_tkeep[k] = 4'b0011;
              2: s_tkeep[k] = 4'b1100;
              default:
                 s_tkeep[k] = 4'b0101;
            endcase

            s_tlast[k] =
                1'b1;

            s_tuser[k] =
                fair_seq[k][0] ^
                k[0];

            s_tvalid[k] =
                1'b1;

          end

        end
        else if (fair_accept_q[k]) begin

          if (fair_stop) begin

            s_tvalid[k] =
                1'b0;

          end
          else begin

            fair_seq[k] =
                fair_seq[k] + 1;

            s_tdata[k] =
                32'hA000_0000 |
                (k << 24) |
                fair_seq[k];

            case (k)
              0: s_tkeep[k] = 4'b1111;
              1: s_tkeep[k] = 4'b0011;
              2: s_tkeep[k] = 4'b1100;
              default:
                 s_tkeep[k] = 4'b0101;
            endcase

            s_tlast[k] =
                1'b1;

            s_tuser[k] =
                fair_seq[k][0] ^
                k[0];

            /*
             * VALID remains asserted continuously.
             */
            s_tvalid[k] =
                1'b1;

          end

        end

      end

    end
  end


  // ==========================================================================
  // Main passive scoreboard
  // ==========================================================================

  always @(posedge clk) begin : scoreboard
    automatic integer k;
    automatic integer cand;
    automatic integer cand_count;
    automatic integer other_cand;

    automatic beat_rec_t in_b;
    automatic beat_rec_t exp_b;

    if (rst) begin

      for (k = 0; k < S_COUNT; k = k + 1)
        pending_q[k].delete();

      frame_active =
          1'b0;

      frame_source =
          -1;

      stalled_offer =
          1'b0;

    end
    else begin

      // ----------------------------------------------------------------------
      // S1: record actual input transfers first.
      //
      // Processing inputs before the output allows a legal zero-latency path
      // where input and output handshake on the same rising edge.
      // ----------------------------------------------------------------------

      for (k = 0; k < S_COUNT; k = k + 1) begin

        if (
            s_tvalid[k] &&
            s_tready[k]
        ) begin

          in_b.data =
              s_tdata[k];

          in_b.keep =
              s_tkeep[k];

          in_b.last =
              s_tlast[k];

          in_b.user =
              s_tuser[k];

          pending_q[k].push_back(
              in_b
          );

          accepted_beat_count =
              accepted_beat_count + 1;

          if (s_tlast[k])
            accepted_frame_count =
                accepted_frame_count + 1;

        end

      end


      // ----------------------------------------------------------------------
      // S8 / AXI4-Stream backpressure stability.
      //
      // Once the output has presented a valid beat while READY is low, the
      // same offered beat must remain until transfer.
      // ----------------------------------------------------------------------

      if (stalled_offer) begin

        if (!m_tvalid) begin

          fail_req(
              "S8",
              "output withdrew a valid beat while backpressured"
          );

          stalled_offer =
              1'b0;

        end
        else begin

          if (
              !beat_equal(
                  stalled_beat,
                  m_tdata,
                  m_tkeep,
                  m_tlast,
                  m_tuser
              )
          )
            fail_req(
                "S8",
                "output beat changed while m_tready_i was low"
            );


          if (m_tready)
            stalled_offer =
                1'b0;

        end

      end
      else if (
          m_tvalid &&
          !m_tready
      ) begin

        stalled_offer =
            1'b1;

        stalled_beat.data =
            m_tdata;

        stalled_beat.keep =
            m_tkeep;

        stalled_beat.last =
            m_tlast;

        stalled_beat.user =
            m_tuser;

      end


      // ----------------------------------------------------------------------
      // Output transfer
      // ----------------------------------------------------------------------

      if (
          m_tvalid &&
          m_tready
      ) begin

        output_beat_count =
            output_beat_count + 1;


        // --------------------------------------------------------------------
        // A frame is already active: only its selected input may supply the
        // next output beat.
        // --------------------------------------------------------------------

        if (frame_active) begin

          if (
              pending_q[frame_source].size() == 0
          ) begin

            fail_req(
                "S4",
                "output transferred a frame beat before that input beat had transferred"
            );

          end
          else begin

            exp_b =
                pending_q[frame_source][0];


            if (
                beat_equal(
                    exp_b,
                    m_tdata,
                    m_tkeep,
                    m_tlast,
                    m_tuser
                )
            ) begin

              void'(
                  pending_q[
                      frame_source
                  ].pop_front()
              );


              if (m_tlast) begin

                frame_active =
                    1'b0;

                output_frame_count =
                    output_frame_count + 1;

                if (fair_check_active)
                  fairness_frame_seen(
                      frame_source
                  );

                frame_source =
                    -1;

              end

            end
            else begin

              /*
               * Determine whether this is specifically a switch to some other
               * input in the middle of the current frame.
               */
              other_cand =
                  -1;

              for (k = 0; k < S_COUNT; k = k + 1) begin

                if (
                    (k != frame_source) &&
                    (pending_q[k].size() != 0) &&
                    beat_equal(
                        pending_q[k][0],
                        m_tdata,
                        m_tkeep,
                        m_tlast,
                        m_tuser
                    )
                )
                  other_cand =
                      k;

              end


              if (other_cand >= 0)
                fail_req(
                    "S3",
                    "output interleaved a beat from another input inside an active frame"
                );
              else
                fail_req(
                    "S4",
                    "output beat did not equal the next accepted beat of the active frame"
                );

            end

          end

        end


        // --------------------------------------------------------------------
        // No frame active: any input's next accepted beat may legally begin
        // the next output frame.
        // --------------------------------------------------------------------

        else begin

          cand       =
              -1;

          cand_count =
              0;


          for (k = 0; k < S_COUNT; k = k + 1) begin

            if (
                (pending_q[k].size() != 0) &&
                beat_equal(
                    pending_q[k][0],
                    m_tdata,
                    m_tkeep,
                    m_tlast,
                    m_tuser
                )
            ) begin

              cand =
                  k;

              cand_count =
                  cand_count + 1;

            end

          end


          if (cand_count == 0) begin

            /*
             * This includes an originated beat and a duplicated beat whose
             * original copy was already removed from the scoreboard.
             */
            fail_req(
                "S4",
                "output beat did not correspond to any next accepted input beat"
            );

            fail_req(
                "S5",
                "output produced a beat with no remaining exactly-once delivery obligation"
            );

          end
          else begin

            if (cand_count > 1)
              fail_req(
                  "S4",
                  "test bookkeeping encountered an ambiguous output-source match"
              );


            void'(
                pending_q[
                    cand
                ].pop_front()
            );


            if (m_tlast) begin

              output_frame_count =
                  output_frame_count + 1;

              if (fair_check_active)
                fairness_frame_seen(
                    cand
                );

            end
            else begin

              frame_active =
                  1'b1;

              frame_source =
                  cand;

            end

          end

        end

      end

    end
  end


  // ==========================================================================
  // Wait for a given number of output beats
  // ==========================================================================

  task automatic wait_output_beats(
      input integer target,
      input integer budget,
      output bit     reached
  );
    integer n;

    begin
      reached = 1'b0;

      for (n = 0; n < budget; n = n + 1) begin

        @(posedge clk);

        if (output_beat_count >= target) begin
          reached = 1'b1;
          break;
        end

      end
    end
  endtask


  // ==========================================================================
  // Wait until all accepted beats have left the scoreboard
  // ==========================================================================

  task automatic wait_all_delivered(
      input string req_name
  );
    integer n;
    integer k;
    integer total_pending;

    bit done;

    begin
      done =
          1'b0;

      for (n = 0; n < WAIT_LIMIT; n = n + 1) begin

        @(negedge clk);

        total_pending =
            0;

        for (k = 0; k < S_COUNT; k = k + 1)
          total_pending =
              total_pending +
              pending_q[k].size();


        if (
            (total_pending == 0) &&
            !frame_active
        ) begin

          done =
              1'b1;

          break;

        end

      end


      if (!done)
        fail_req(
            req_name,
            "completed input frames retained undelivered beats"
        );


      /*
       * Leave the sink ready for several extra cycles.  A duplicated late
       * output is caught by the passive scoreboard.
       */
      repeat (5)
        @(posedge clk);

    end
  endtask


  // ==========================================================================
  // Clean synchronous reset
  // ==========================================================================

  task automatic clean_reset;
    integer n;

    begin
      /*
       * Called only when all testbench source threads are idle.
       */
      @(negedge clk);

      fair_active      = 1'b0;
      fair_stop        = 1'b0;
      fair_check_active = 1'b0;

      s_tvalid =
          '0;

      m_tready =
          1'b1;

      rst =
          1'b1;


      repeat (4)
        @(posedge clk);


      /*
       * Reset has now been sampled.  S12 requires the unit to be idle.
       */
      @(negedge clk);

      if (m_tvalid)
        fail_req(
            "S12",
            "m_tvalid_o remained asserted after synchronous reset was sampled"
        );


      rst =
          1'b0;


      /*
       * First cycle after release must have m_tvalid_o low.
       */
      @(posedge clk);
      @(negedge clk);

      if (m_tvalid)
        fail_req(
            "S12",
            "m_tvalid_o was high on the first cycle after reset release"
        );


      /*
       * With no post-reset inputs, no stale pre-reset output may emerge.
       */
      for (n = 0; n < 3; n = n + 1) begin

        @(posedge clk);
        @(negedge clk);

        if (m_tvalid)
          fail_req(
              "S12",
              "a stale pre-reset beat appeared after reset"
          );

      end
    end
  endtask


  // ==========================================================================
  // Basic payload, sideband, ordering and single-beat-frame tests
  // ==========================================================================

  task automatic test_basic_integrity;
    begin
      clean_reset();

      bfm_ready(
          1'b1
      );


      // ----------------------------------------------------------------------
      // Three-beat frame on input 0
      // ----------------------------------------------------------------------

      bfm_send(
          0,
          32'hD000_0001,
          4'b1111,
          1'b0,
          1'b0
      );

      bfm_send(
          0,
          32'hD000_0002,
          4'b0101,
          1'b0,
          1'b1
      );

      bfm_send(
          0,
          32'hD000_0003,
          4'b1000,
          1'b1,
          1'b0
      );

      bfm_idle(
          0
      );


      // ----------------------------------------------------------------------
      // Single-beat frame on input 2 -- explicitly exercises S2
      // ----------------------------------------------------------------------

      bfm_send(
          2,
          32'hD200_0001,
          4'b0011,
          1'b1,
          1'b1
      );

      bfm_idle(
          2
      );


      // ----------------------------------------------------------------------
      // Two-beat frame on input 3
      // ----------------------------------------------------------------------

      bfm_send(
          3,
          32'hD300_0001,
          4'b0000,
          1'b0,
          1'b1
      );

      bfm_send(
          3,
          32'hD300_0002,
          4'b1010,
          1'b1,
          1'b0
      );

      bfm_idle(
          3
      );


      wait_all_delivered(
          "S5"
      );
    end
  endtask


  // ==========================================================================
  // Frame atomicity with output backpressure and a competing input
  // ==========================================================================

  task automatic test_atomicity_backpressure;
    automatic integer base_output;
    automatic bit reached;

    begin
      clean_reset();

      bfm_ready(
          1'b1
      );

      atomic_stall_started =
          1'b0;

      base_output =
          output_beat_count;


      fork

        // --------------------------------------------------------------------
        // Source 0: long frame
        // --------------------------------------------------------------------

        begin : atomic_source_zero

          bfm_send(
              0,
              32'hE000_0001,
              4'b1111,
              1'b0,
              1'b0
          );

          bfm_send(
              0,
              32'hE000_0002,
              4'b1100,
              1'b0,
              1'b1
          );

          bfm_send(
              0,
              32'hE000_0003,
              4'b0011,
              1'b0,
              1'b0
          );

          bfm_send(
              0,
              32'hE000_0004,
              4'b1001,
              1'b1,
              1'b1
          );

          bfm_idle(
              0
          );

        end


        // --------------------------------------------------------------------
        // Competing complete frame from source 1, introduced only after the
        // first source-0 beat has begun the output frame.
        // --------------------------------------------------------------------

        begin : atomic_source_one

          while (!atomic_stall_started)
            @(posedge clk);

          bfm_send(
              1,
              32'hE100_0001,
              4'b0110,
              1'b1,
              1'b1
          );

          bfm_idle(
              1
          );

        end


        // --------------------------------------------------------------------
        // Sink controller: after the first output beat, stop mid-frame.
        // --------------------------------------------------------------------

        begin : atomic_sink_control

          wait_output_beats(
              base_output + 1,
              WAIT_LIMIT,
              reached
          );


          if (!reached) begin

            fail_req(
                "S5",
                "first beat of completed frame never reached the output"
            );

            atomic_stall_started =
                1'b1;

          end
          else begin

            bfm_ready(
                1'b0
            );

            atomic_stall_started =
                1'b1;


            /*
             * Long mid-frame backpressure interval.
             */
            repeat (12)
              @(posedge clk);


            bfm_ready(
                1'b1
            );

          end

        end

      join


      wait_all_delivered(
          "S5"
      );
    end
  endtask


  // ==========================================================================
  // S10 continuous-load fairness
  // ==========================================================================

  task automatic test_fairness;
    integer k;
    integer n;

    bit started;
    bit reached_target;
    bit stopped;

    begin
      clean_reset();

      bfm_ready(
          1'b1
      );


      for (k = 0; k < S_COUNT; k = k + 1) begin

        fair_seq[k] =
            0;

        fair_last_seen[k] =
            0;

      end


      fair_frame_no =
          0;

      fair_fail_reported =
          1'b0;

      fair_stop =
          1'b0;

      fair_check_active =
          1'b0;

      fair_active =
          1'b1;


      /*
       * Wait until all four continuous source offers are physically active.
       */
      started =
          1'b0;

      for (n = 0; n < 100; n = n + 1) begin

        @(negedge clk);

        if (s_tvalid == {S_COUNT{1'b1}}) begin
          started = 1'b1;
          break;
        end

      end


      if (!started)
        fail_req(
            "S10",
            "continuous fairness load could not be established"
        );


      /*
       * Start the 16-frame window measurement only after every input is
       * continuously offering.
       */
      fair_frame_no =
          0;

      for (k = 0; k < S_COUNT; k = k + 1)
        fair_last_seen[k] =
            0;

      fair_check_active =
          1'b1;


      /*
       * Observe many overlapping 16-frame windows.
       */
      reached_target =
          1'b0;

      for (n = 0; n < WAIT_LIMIT; n = n + 1) begin

        @(negedge clk);

        if (fair_frame_no >= 64) begin
          reached_target = 1'b1;
          break;
        end

      end


      if (!reached_target)
        fail_req(
            "S10",
            "continuous load did not complete enough output frames for fairness checking"
        );


      /*
       * Stop checking first, then gracefully stop the source streams.
       *
       * Every already-offered beat remains asserted until its own handshake,
       * preserving S7.
       */
      fair_check_active =
          1'b0;

      fair_stop =
          1'b1;


      stopped =
          1'b0;

      for (n = 0; n < WAIT_LIMIT; n = n + 1) begin

        @(negedge clk);

        if (s_tvalid == '0) begin
          stopped = 1'b1;
          break;
        end

      end


      if (!stopped)
        fail_req(
            "S10",
            "a continuously offered input could not be stopped through normal handshakes"
        );


      fair_active =
          1'b0;


      wait_all_delivered(
          "S5"
      );
    end
  endtask


  // ==========================================================================
  // Reset discard test
  //
  // A buffering implementation may accept the offered beat while the output is
  // blocked.  A pure cut-through implementation may refuse it.  Both are legal.
  // If the beat was accepted, reset must erase its delivery obligation.
  // ==========================================================================

  task automatic test_reset_discard;
    integer n;
    integer base_accepted;

    bit pre_reset_accepted;

    begin
      clean_reset();


      /*
       * Block the output.
       */
      bfm_ready(
          1'b0
      );


      base_accepted =
          accepted_beat_count;

      pre_reset_accepted =
          1'b0;


      /*
       * Present a complete frame and hold it stable.
       */
      @(negedge clk);

      s_tdata[2] =
          32'hF200_55AA;

      s_tkeep[2] =
          4'b1011;

      s_tlast[2] =
          1'b1;

      s_tuser[2] =
          1'b1;

      s_tvalid[2] =
          1'b1;


      /*
       * A buffered implementation may take it.  Acceptance is not required
       * while the output is blocked.
       */
      for (n = 0; n < 12; n = n + 1) begin

        @(posedge clk);

        if (
            accepted_beat_count >
            base_accepted
        ) begin

          pre_reset_accepted =
              1'b1;

          break;

        end

      end


      /*
       * Assert synchronous reset without illegally withdrawing a still-pending
       * source offer first.
       */
      @(negedge clk);
      rst = 1'b1;


      repeat (4)
        @(posedge clk);


      /*
       * Reset has been sampled.  The design must be idle.
       */
      @(negedge clk);

      if (m_tvalid)
        fail_req(
            "S12",
            "m_tvalid_o remained high after reset was sampled"
        );


      /*
       * Source offer can now be removed while reset is still asserted.
       */
      s_tvalid[2] =
          1'b0;


      /*
       * Give reset one additional sampled cycle after source removal.
       */
      @(posedge clk);

      @(negedge clk);

      rst =
          1'b0;

      m_tready =
          1'b1;


      /*
       * First post-reset cycle.
       */
      @(posedge clk);
      @(negedge clk);

      if (m_tvalid)
        fail_req(
            "S12",
            "m_tvalid_o was high on the first cycle after reset release"
        );


      /*
       * No old beat may reappear.  This is meaningful whether or not the
       * optional blocked-input buffering accepted the beat.
       */
      for (n = 0; n < 8; n = n + 1) begin

        @(posedge clk);
        @(negedge clk);

        if (m_tvalid)
          fail_req(
              "S12",
              "beat from before or during reset appeared after reset"
          );

      end


      /*
       * Fresh post-reset traffic must still behave normally.
       */
      bfm_send(
          3,
          32'hF300_1234,
          4'b1110,
          1'b1,
          1'b0
      );

      bfm_idle(
          3
      );


      wait_all_delivered(
          "S5"
      );


      /*
       * Prevent an unused-variable warning from obscuring intent.
       */
      if (pre_reset_accepted)
        pre_reset_accepted =
            1'b1;

    end
  endtask


  // ==========================================================================
  // Main test
  // ==========================================================================

  initial begin : main_test
    integer k;

    fail_count =
        0;

    accepted_beat_count =
        0;

    accepted_frame_count =
        0;

    output_beat_count =
        0;

    output_frame_count =
        0;

    frame_active =
        1'b0;

    frame_source =
        -1;

    stalled_offer =
        1'b0;

    fair_active =
        1'b0;

    fair_stop =
        1'b0;

    fair_check_active =
        1'b0;

    fair_accept_q =
        '0;

    fair_frame_no =
        0;

    fair_fail_reported =
        1'b0;

    atomic_stall_started =
        1'b0;


    for (k = 0; k < S_COUNT; k = k + 1) begin

      fair_seq[k] =
          0;

      fair_last_seen[k] =
          0;

    end


    // ------------------------------------------------------------------------
    // S1/S2/S4/S5: basic transfer, framing, payload and sideband integrity
    // ------------------------------------------------------------------------

    test_basic_integrity();


    // ------------------------------------------------------------------------
    // S3/S8: frame locking under competition and output backpressure
    // ------------------------------------------------------------------------

    test_atomicity_backpressure();


    // ------------------------------------------------------------------------
    // S10: all inputs continuously loaded, arbitrary starting selection
    // ------------------------------------------------------------------------

    test_fairness();


    // ------------------------------------------------------------------------
    // S12: synchronous reset and stale-beat discard
    // ------------------------------------------------------------------------

    test_reset_discard();


    // ------------------------------------------------------------------------
    // Final no-loss check
    // ------------------------------------------------------------------------

    wait_all_delivered(
        "S5"
    );


    if (fail_count == 0)
      $display("RESULT: PASS");
    else
      $display("RESULT: FAIL");

    $finish;
  end


  // ==========================================================================
  // Unconditional watchdog
  // ==========================================================================

  initial begin
    #20_000_000;

    $display(
        "FAIL S10: watchdog expired before the testbench reached a verdict"
    );

    $display("RESULT: FAIL");

    $finish;
  end

endmodule