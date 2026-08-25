module frame_arb_mux_tb;

  localparam int S_COUNT    = 4;
  localparam int DATA_WIDTH = 32;
  localparam int USER_WIDTH = 1;

  localparam int PHASE_FUNC = 0;
  localparam int PHASE_FAIR = 1;

  localparam logic [5:0] FUNC_MARK = 6'h2A;
  localparam logic [5:0] FAIR_MARK = 6'h15;

  // ---------------------------------------------------------------------------
  // Clock / reset / DUT wiring
  // ---------------------------------------------------------------------------
  logic clk;
  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end

  logic rst;
  initial rst = 1'b1;

  logic [S_COUNT-1:0][DATA_WIDTH-1:0]       s_tdata = '0;
  logic [S_COUNT-1:0][(DATA_WIDTH/8)-1:0]   s_tkeep = '0;
  logic [S_COUNT-1:0]                       s_tvalid = '0;
  logic [S_COUNT-1:0]                       s_tready;
  logic [S_COUNT-1:0]                       s_tlast = '0;
  logic [S_COUNT-1:0][USER_WIDTH-1:0]       s_tuser = '0;

  logic [DATA_WIDTH-1:0]                    m_tdata;
  logic [(DATA_WIDTH/8)-1:0]                m_tkeep;
  logic                                     m_tvalid;
  logic                                     m_tready = 1'b1;
  logic                                     m_tlast;
  logic [USER_WIDTH-1:0]                    m_tuser;

  frame_arb_mux #(
    .S_COUNT(S_COUNT),
    .DATA_WIDTH(DATA_WIDTH),
    .USER_WIDTH(USER_WIDTH)
  ) dut (
    .clk_i(clk),
    .rst_i(rst),
    .s_tdata_i(s_tdata),
    .s_tkeep_i(s_tkeep),
    .s_tvalid_i(s_tvalid),
    .s_tready_o(s_tready),
    .s_tlast_i(s_tlast),
    .s_tuser_i(s_tuser),
    .m_tdata_o(m_tdata),
    .m_tkeep_o(m_tkeep),
    .m_tvalid_o(m_tvalid),
    .m_tready_i(m_tready),
    .m_tlast_o(m_tlast),
    .m_tuser_o(m_tuser)
  );

  // ---------------------------------------------------------------------------
  // Common helpers
  // ---------------------------------------------------------------------------
  bit verdict_printed = 1'b0;

  task automatic fail_now(input string req_name, input string msg);
    begin
      if (!verdict_printed) begin
        verdict_printed = 1'b1;
        $display("FAIL %s: %s", req_name, msg);
        $display("RESULT: FAIL");
        $finish;
      end
    end
  endtask

  task automatic pass_now();
    begin
      if (!verdict_printed) begin
        verdict_printed = 1'b1;
        $display("RESULT: PASS");
        $finish;
      end
    end
  endtask

  task automatic bfm_ready(input logic value);
    begin
      @(negedge clk);
      m_tready = value;
    end
  endtask

  // ---------------------------------------------------------------------------
  // Deterministic source stream.
  //
  // Every data beat carries an unambiguous source code in [31:30] and a phase
  // marker in [29:24]. This lets the checker identify the source without ever
  // inferring selection from READY. Sequence order is then checked from
  // bookkeeping counters, not by searching for a repeated payload value.
  // ---------------------------------------------------------------------------
  typedef struct packed {
    logic [31:0] data;
    logic [3:0]  keep;
    logic        last;
    logic        user;
  } beat_t;

  function automatic int func_script_count(input int k);
    begin
      case (k)
        0: func_script_count = 6;
        1: func_script_count = 7;
        2: func_script_count = 6;
        3: func_script_count = 7;
        default: func_script_count = 0;
      endcase
    end
  endfunction

  function automatic logic func_last(input int k, input int idx);
    begin
      func_last = 1'b1;
      case (k)
        0: begin
          case (idx)
            0, 1, 4: func_last = 1'b0;
            default: func_last = 1'b1;
          endcase
        end
        1: begin
          case (idx)
            0, 2, 3, 4: func_last = 1'b0;
            default: func_last = 1'b1;
          endcase
        end
        2: begin
          case (idx)
            1, 2, 4: func_last = 1'b0;
            default: func_last = 1'b1;
          endcase
        end
        3: begin
          case (idx)
            0, 1, 2, 5: func_last = 1'b0;
            default: func_last = 1'b1;
          endcase
        end
        default: func_last = 1'b1;
      endcase
    end
  endfunction

  function automatic beat_t make_beat(
    input int phase_v,
    input int k,
    input int idx
  );
    beat_t b;
    begin
      b = '0;
      b.data[31:30] = k;
      b.data[23:0] = idx;

      if (phase_v == PHASE_FUNC)
        b.data[29:24] = FUNC_MARK;
      else
        b.data[29:24] = FAIR_MARK;

      case (idx % 4)
        0: b.keep = 4'b0001;
        1: b.keep = 4'b0101;
        2: b.keep = 4'b1110;
        default: b.keep = 4'b1011;
      endcase

      b.user = idx[0] ^ k[0];

      if (phase_v == PHASE_FUNC) begin
        if (idx < func_script_count(k))
          b.last = func_last(k, idx);
        else
          b.last = 1'b1;
      end else begin
        // Fairness phase is an endless stream of complete one-beat frames.
        b.last = 1'b1;
      end

      make_beat = b;
    end
  endfunction

  // ---------------------------------------------------------------------------
  // Continuous-load source driver.
  //
  // Once enabled, all four inputs keep VALID asserted continuously and replace
  // a beat only after its actual handshake. That satisfies S7 and establishes
  // the S10 continuous-load precondition whenever m_tready is high.
  // ---------------------------------------------------------------------------
  logic [S_COUNT-1:0] src_hs = '0;
  int src_offer_idx [0:S_COUNT-1];
  bit source_enable = 1'b0;
  int phase_mode = PHASE_FUNC;

  integer drv_k;
  beat_t drv_beat;

  always @(posedge clk) begin
    if (rst)
      src_hs <= '0;
    else
      src_hs <= s_tvalid & s_tready;
  end

  always @(negedge clk) begin
    if (rst) begin
      s_tvalid = '0;
      s_tdata  = '0;
      s_tkeep  = '0;
      s_tlast  = '0;
      s_tuser  = '0;

      for (drv_k = 0; drv_k < S_COUNT; drv_k = drv_k + 1)
        src_offer_idx[drv_k] = 0;

    end else if (!source_enable) begin
      s_tvalid = '0;

    end else begin
      for (drv_k = 0; drv_k < S_COUNT; drv_k = drv_k + 1) begin
        if (src_hs[drv_k])
          src_offer_idx[drv_k] = src_offer_idx[drv_k] + 1;

        drv_beat = make_beat(
          phase_mode,
          drv_k,
          src_offer_idx[drv_k]
        );

        s_tdata[drv_k]  = drv_beat.data;
        s_tkeep[drv_k]  = drv_beat.keep;
        s_tlast[drv_k]  = drv_beat.last;
        s_tuser[drv_k]  = drv_beat.user;
        s_tvalid[drv_k] = 1'b1;
      end
    end
  end

  // ---------------------------------------------------------------------------
  // Scoreboard / frame checker
  // ---------------------------------------------------------------------------
  int in_accepted [0:S_COUNT-1];
  int out_seen    [0:S_COUNT-1];

  bit out_in_frame = 1'b0;
  int locked_src = 0;

  // Backpressure trigger. A known two-beat frame is chosen, so the beat after
  // the trigger is TLAST.
  bit bp_candidate = 1'b0;
  bit bp_done = 1'b0;

  // Fairness sliding window.
  int fair_hist [0:15];
  int fair_hist_len = 0;
  int fair_windows_checked = 0;
  logic [3:0] fair_mask_tmp;

  integer mon_k;
  integer fair_i;
  int mon_src;
  beat_t mon_exp;
  beat_t mon_next;

  always @(posedge clk) begin
    if (rst) begin

      for (mon_k = 0; mon_k < S_COUNT; mon_k = mon_k + 1) begin
        in_accepted[mon_k] = 0;
        out_seen[mon_k] = 0;
      end

      out_in_frame = 1'b0;
      locked_src = 0;
      bp_candidate = 1'b0;
      fair_hist_len = 0;
      fair_windows_checked = 0;

    end else begin

      // S1/S6: record only actual input handshakes. READY alone is never
      // interpreted as selection.
      for (mon_k = 0; mon_k < S_COUNT; mon_k = mon_k + 1) begin
        if (s_tvalid[mon_k] && s_tready[mon_k])
          in_accepted[mon_k] = in_accepted[mon_k] + 1;
      end

      // An S10 window is valid only while its entire continuous-load
      // precondition holds.
      if (phase_mode == PHASE_FAIR) begin
        if (!(source_enable && m_tready && (&s_tvalid)))
          fair_hist_len = 0;
      end else begin
        fair_hist_len = 0;
      end

      if (m_tvalid && m_tready) begin

        // Any functional-phase beat appearing after the reset between phases
        // is forbidden by S12.
        if ((phase_mode == PHASE_FAIR) &&
            (m_tdata[29:24] == FUNC_MARK)) begin
          fail_now(
            "S12",
            "a pre-reset functional-phase beat appeared after reset"
          );
        end

        mon_src = int'(m_tdata[31:30]);

        if ((mon_src < 0) || (mon_src >= S_COUNT)) begin
          fail_now(
            "S4",
            "output beat carried an invalid source signature"
          );
        end

        if (out_seen[mon_src] >= in_accepted[mon_src]) begin
          fail_now(
            "S4/S5",
            $sformatf(
              "output source %0d produced beat %0d before that beat transferred on its input",
              mon_src,
              out_seen[mon_src]
            )
          );
        end

        mon_exp = make_beat(
          phase_mode,
          mon_src,
          out_seen[mon_src]
        );

        if (m_tdata !== mon_exp.data) begin
          fail_now(
            "S4",
            $sformatf(
              "tdata mismatch for source %0d beat %0d: got %08h expected %08h",
              mon_src,
              out_seen[mon_src],
              m_tdata,
              mon_exp.data
            )
          );
        end

        if (m_tkeep !== mon_exp.keep) begin
          fail_now(
            "S4",
            $sformatf(
              "tkeep mismatch for source %0d beat %0d: got %h expected %h",
              mon_src,
              out_seen[mon_src],
              m_tkeep,
              mon_exp.keep
            )
          );
        end

        if (m_tuser !== mon_exp.user) begin
          fail_now(
            "S4",
            $sformatf(
              "tuser mismatch for source %0d beat %0d: got %0b expected %0b",
              mon_src,
              out_seen[mon_src],
              m_tuser,
              mon_exp.user
            )
          );
        end

        if (m_tlast !== mon_exp.last) begin
          fail_now(
            "S2/S4",
            $sformatf(
              "tlast mismatch for source %0d beat %0d: got %0b expected %0b",
              mon_src,
              out_seen[mon_src],
              m_tlast,
              mon_exp.last
            )
          );
        end

        // S3: no source switch is permitted inside a frame.
        if (out_in_frame) begin

          if (mon_src != locked_src) begin
            fail_now(
              "S3",
              $sformatf(
                "frame interleaving: source %0d appeared while source %0d frame was active",
                mon_src,
                locked_src
              )
            );
          end

        end else begin

          locked_src = mon_src;

          // Find the beginning of any known two-beat scripted frame.
          if ((phase_mode == PHASE_FUNC) &&
              !bp_candidate &&
              !bp_done &&
              !mon_exp.last) begin

            mon_next = make_beat(
              phase_mode,
              mon_src,
              out_seen[mon_src] + 1
            );

            if (mon_next.last)
              bp_candidate = 1'b1;
          end
        end

        if (mon_exp.last)
          out_in_frame = 1'b0;
        else
          out_in_frame = 1'b1;

        out_seen[mon_src] = out_seen[mon_src] + 1;

        // S10: every frame in this phase is one beat, so every completed frame
        // is also its frame-begin event. Check every overlapping 16-frame
        // window while continuous load holds.
        if ((phase_mode == PHASE_FAIR) &&
            source_enable &&
            m_tready &&
            (&s_tvalid)) begin

          if (fair_hist_len < 16) begin

            fair_hist[fair_hist_len] = mon_src;
            fair_hist_len = fair_hist_len + 1;

          end else begin

            for (fair_i = 0; fair_i < 15; fair_i = fair_i + 1)
              fair_hist[fair_i] = fair_hist[fair_i + 1];

            fair_hist[15] = mon_src;
          end

          if (fair_hist_len >= 16) begin

            fair_mask_tmp = 4'b0000;

            for (fair_i = 0; fair_i < 16; fair_i = fair_i + 1)
              fair_mask_tmp[fair_hist[fair_i]] = 1'b1;

            if (fair_mask_tmp != 4'b1111) begin
              fail_now(
                "S10",
                $sformatf(
                  "a 16-frame continuous-load window omitted an input; seen mask=%b",
                  fair_mask_tmp
                )
              );
            end

            fair_windows_checked = fair_windows_checked + 1;
          end
        end
      end
    end
  end

  // ---------------------------------------------------------------------------
  // Reset helper.
  //
  // Inputs are made idle before reset. Reset is then sampled high on several
  // rising edges. The source remains idle through the first released cycle,
  // where S12 explicitly requires m_tvalid_o low.
  // ---------------------------------------------------------------------------
  task automatic reset_to_phase(input int new_phase);
    begin

      source_enable = 1'b0;

      @(negedge clk);
      rst = 1'b1;

      repeat (4) @(posedge clk);

      @(negedge clk);

      if (m_tvalid !== 1'b0) begin
        fail_now(
          "S12",
          "m_tvalid_o was not low after synchronous reset had taken effect"
        );
      end

      phase_mode = new_phase;
      rst = 1'b0;

      @(posedge clk);
      @(negedge clk);

      if (m_tvalid !== 1'b0) begin
        fail_now(
          "S12",
          "m_tvalid_o was not low on the first cycle after reset release"
        );
      end
    end
  endtask

  // ---------------------------------------------------------------------------
  // Stimulus
  // ---------------------------------------------------------------------------
  initial begin

    // Initial reset.
    m_tready = 1'b1;
    bp_done = 1'b0;

    reset_to_phase(PHASE_FUNC);

    // All four sources now remain continuously offered. Each scripted prefix
    // contains varied one-, two-, three-, and four-beat frames followed by
    // endless one-beat frames.
    source_enable = 1'b1;

    // S8: after the first beat of a known two-beat frame transfers, deassert
    // READY before the next rising edge. The next beat is TLAST, so this
    // exercises backpressure while a frame is active and across its end.
    wait (bp_candidate);

    bfm_ready(1'b0);

    repeat (6) @(posedge clk);

    bfm_ready(1'b1);

    bp_done = 1'b1;

    // All scripted beats must eventually leave exactly once and in per-input
    // order. No arbitration order or cycle latency is assumed.
    wait (
      (out_seen[0] >= 6) &&
      (out_seen[1] >= 7) &&
      (out_seen[2] >= 6) &&
      (out_seen[3] >= 7)
    );

    // Flush continuing filler traffic and explicitly test reset behavior.
    reset_to_phase(PHASE_FAIR);

    // Dedicated S10 phase: all four sources offer an endless sequence of
    // complete single-beat frames while output READY remains continuously high.
    m_tready = 1'b1;
    source_enable = 1'b1;

    // This corresponds to many overlapping 16-completed-frame windows.
    wait (fair_windows_checked >= 32);

    // Finish through reset so outstanding endless-load traffic is discarded by
    // the contract rather than becoming an unfinished test obligation.
    reset_to_phase(PHASE_FAIR);

    pass_now();
  end

  // ---------------------------------------------------------------------------
  // Independent watchdog.
  // ---------------------------------------------------------------------------
  initial begin
    #20_000_000;

    if (!verdict_printed) begin
      verdict_printed = 1'b1;
      $display("FAIL S5/S10: watchdog: no forward progress");
      $display("RESULT: FAIL");
      $finish;
    end
  end

endmodule