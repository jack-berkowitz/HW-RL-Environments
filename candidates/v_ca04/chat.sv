module route_xbar_tb;

  // ---------------------------------------------------------------------------
  // PROVIDED PLUMBING
  // ---------------------------------------------------------------------------

  localparam int N_IN = 4, N_OUT = 4, DW = 32, SW = 2, IW = 2;

  // ---- clock ----------------------------------------------------------------

  logic clk = 1'b0;

  always #5 clk = ~clk;

  int bfm_cycle = 0;

  always @(posedge clk)
    if (rst_n)
      bfm_cycle <= bfm_cycle + 1;

  // ---- reset ----------------------------------------------------------------

  logic rst_n = 1'b0;

  task automatic bfm_reset(input int cycles = 5);
    @(negedge clk);
    rst_n = 1'b0;
    repeat (cycles) @(posedge clk);
    @(negedge clk);
    rst_n = 1'b1;
  endtask

  // ---- signals and DUT -------------------------------------------------------

  logic [N_IN*DW-1:0]  in_data;
  logic [N_IN*SW-1:0]  in_sel;
  logic [N_IN-1:0]     in_valid;
  logic [N_IN-1:0]     in_ready;

  logic [N_OUT*DW-1:0] out_data;
  logic [N_OUT*IW-1:0] out_idx;
  logic [N_OUT-1:0]    out_valid;
  logic [N_OUT-1:0]    out_ready;

  route_xbar #(
      .N_IN   (N_IN),
      .N_OUT  (N_OUT),
      .DATA_W (DW),
      .SEL_W  (SW),
      .IDX_W  (IW)
  ) dut (
      .clk_i         (clk),
      .rst_ni        (rst_n),

      .in_data_i     (in_data),
      .in_sel_i      (in_sel),
      .in_valid_i    (in_valid),
      .in_ready_o    (in_ready),

      .out_data_o    (out_data),
      .out_idx_o     (out_idx),
      .out_valid_o   (out_valid),
      .out_ready_i   (out_ready)
  );

  function automatic logic [DW-1:0] bfm_odata(input int j);
    bfm_odata = out_data[j*DW +: DW];
  endfunction

  function automatic logic [IW-1:0] bfm_oidx(input int j);
    bfm_oidx = out_idx[j*IW +: IW];
  endfunction

  // ---- source driver ---------------------------------------------------------

  logic [N_IN-1:0] bfm_offer;

  logic [DW-1:0] bfm_next_data [N_IN];
  logic [SW-1:0] bfm_next_sel  [N_IN];

  logic [N_IN-1:0] bfm_accepted;

  always @(posedge clk)
    bfm_accepted <=
        (rst_n ? (in_valid & in_ready) : '0);

  always @(negedge clk) begin : bfm_driver
    integer k;

    if (!rst_n) begin

      in_valid = '0;

    end
    else begin

      for (k = 0; k < N_IN; k = k + 1) begin

        if (bfm_accepted[k])
          in_valid[k] = 1'b0;

        if (!in_valid[k] && bfm_offer[k]) begin

          in_data[k*DW +: DW] =
              bfm_next_data[k];

          in_sel[k*SW +: SW] =
              bfm_next_sel[k];

          in_valid[k] =
              1'b1;

        end

      end

    end

  end

  task automatic bfm_ready(
      input logic [N_OUT-1:0] v
  );
    out_ready = v;
  endtask

  initial begin : bfm_init
    integer k;

    in_data   = '0;
    in_sel    = '0;
    in_valid  = '0;
    out_ready = '1;
    bfm_offer = '0;

    for (k = 0; k < N_IN; k = k + 1) begin
      bfm_next_data[k] = '0;
      bfm_next_sel[k]  = '0;
    end
  end


  // ---------------------------------------------------------------------------
  // TESTBENCH MODEL
  // ---------------------------------------------------------------------------

  localparam int MAX_BEATS    = 4096;
  localparam int DRAIN_BUDGET = 12000;
  localparam int FAIR_BUDGET  = 20000;

  typedef struct {
    logic          live;
    integer        src;
    integer        dst;
    logic [DW-1:0] data;
    integer        accept_cycle;
  } beat_rec_t;

  beat_rec_t beat_rec [0:MAX_BEATS-1];

  integer beat_rec_count;
  integer live_count;

  integer tb_cycle;
  integer fail_count;

  integer input_accept_total [0:N_IN-1];
  integer output_xfer_total  [0:N_OUT-1];

  logic [N_IN-1:0] stream_gen;
  logic [N_IN-1:0] one_shot_mode;

  integer stream_seq [0:N_IN-1];

  /*
   * X3 tracking is enabled only when the stimulus promises that the bound
   * output is continuously ready.
   */
  logic [N_IN-1:0] x3_watch;
  logic [N_IN-1:0] x3_failed;

  integer x3_age [0:N_IN-1];

  /*
   * A3 snapshots.
   */
  logic stall_active [0:N_OUT-1];

  logic [DW-1:0] stall_data [0:N_OUT-1];
  logic [IW-1:0] stall_idx  [0:N_OUT-1];

  /*
   * A few cycles after reset release are explicitly checked for X2.
   */
  integer reset_quiet_left;

  integer clock_seen;


  function automatic logic [DW-1:0] stream_word(
      input integer src,
      input integer seq_no
  );
    logic [31:0] v;

    begin
      v =
          32'h8000_0000 ^
          (src << 24) ^
          seq_no;

      stream_word = v[DW-1:0];
    end
  endfunction


  task automatic report_fail(
      input string req_name,
      input string detail
  );
    begin
      fail_count = fail_count + 1;
      $display("FAIL %s: %s", req_name, detail);
    end
  endtask


  function automatic integer count_live;
    integer i;
    integer n;

    begin
      n = 0;

      for (i = 0; i < beat_rec_count; i = i + 1)
        if (beat_rec[i].live)
          n = n + 1;

      count_live = n;
    end
  endfunction


  // ---------------------------------------------------------------------------
  // PASSIVE CHECKER
  // ---------------------------------------------------------------------------

  always @(posedge clk) begin : monitor
    automatic integer k;
    automatic integer j;
    automatic integer i;
    automatic integer src;
    automatic integer dst;
    automatic integer found;

    automatic logic [DW-1:0] got_data;

    clock_seen = clock_seen + 1;

    if (!rst_n) begin

      /*
       * X1 is observed only after a clock has occurred and with the source
       * driver quiet, matching the specification's reset qualification.
       */
      if (
          (clock_seen > 1) &&
          (|out_valid)
      )
        report_fail(
            "X1",
            "output valid asserted while reset was active and inputs were quiet"
        );

      beat_rec_count = 0;
      live_count     = 0;

      for (j = 0; j < N_OUT; j = j + 1)
        stall_active[j] = 1'b0;

      for (k = 0; k < N_IN; k = k + 1)
        x3_age[k] = 0;

    end
    else begin

      tb_cycle = tb_cycle + 1;


      /*
       * ------------------------------------------------------------
       * X2 -- after reset, no stale beat is held.
       * ------------------------------------------------------------
       */
      if (reset_quiet_left > 0) begin

        if (|out_valid)
          report_fail(
              "X2",
              "output beat survived reset or appeared with no post-reset input"
          );

        reset_quiet_left =
            reset_quiet_left - 1;

      end


      /*
       * ------------------------------------------------------------
       * Input acceptances.
       *
       * Process these BEFORE output transfers.  This permits a legal
       * zero-latency crossbar whose input and output handshake occur
       * on the same rising edge.
       * ------------------------------------------------------------
       */
      for (k = 0; k < N_IN; k = k + 1) begin

        if (
            in_valid[k] &&
            in_ready[k]
        ) begin

          dst =
              in_sel[k*SW +: SW];

          input_accept_total[k] =
              input_accept_total[k] + 1;

          if (beat_rec_count >= MAX_BEATS) begin

            report_fail(
                "R4",
                "testbench bookkeeping capacity exhausted"
            );

          end
          else begin

            beat_rec[beat_rec_count].live =
                1'b1;

            beat_rec[beat_rec_count].src =
                k;

            beat_rec[beat_rec_count].dst =
                dst;

            beat_rec[beat_rec_count].data =
                in_data[k*DW +: DW];

            beat_rec[beat_rec_count].accept_cycle =
                tb_cycle;

            beat_rec_count =
                beat_rec_count + 1;

            live_count =
                live_count + 1;

          end


          /*
           * One-shot offers stop after precisely one accepted beat.
           * Setting bfm_offer here is safe: the BFM samples it at the
           * following falling edge.
           */
          if (one_shot_mode[k]) begin

            bfm_offer[k] =
                1'b0;

            one_shot_mode[k] =
                1'b0;

          end


          /*
           * Continuous stress source: prepare the next payload before
           * the BFM reaches its following falling-edge load point.
           */
          if (stream_gen[k]) begin

            stream_seq[k] =
                stream_seq[k] + 1;

            bfm_next_data[k] =
                stream_word(
                    k,
                    stream_seq[k]
                );

          end

        end

      end


      /*
       * ------------------------------------------------------------
       * X3 -- acceptance within 32 cycles while the destination stays
       * ready.
       * ------------------------------------------------------------
       */
      for (k = 0; k < N_IN; k = k + 1) begin

        if (
            x3_watch[k] &&
            in_valid[k] &&
            out_ready[
                in_sel[k*SW +: SW]
            ]
        ) begin

          if (in_ready[k]) begin

            x3_age[k] =
                0;

          end
          else begin

            x3_age[k] =
                x3_age[k] + 1;

            if (
                (x3_age[k] >= 32) &&
                !x3_failed[k]
            ) begin

              x3_failed[k] =
                  1'b1;

              report_fail(
                  "X3",
                  "continuously offered beat to a continuously ready output waited more than 32 cycles"
              );

            end

          end

        end
        else begin

          x3_age[k] =
              0;

        end

      end


      /*
       * ------------------------------------------------------------
       * A3 -- once an output offers a beat while stalled, VALID,
       * payload and source index must remain unchanged.
       * ------------------------------------------------------------
       */
      for (j = 0; j < N_OUT; j = j + 1) begin

        if (stall_active[j]) begin

          if (!out_valid[j]) begin

            report_fail(
                "A3",
                "output withdrew valid while its offered beat was stalled"
            );

            stall_active[j] =
                1'b0;

          end
          else begin

            if (
                (bfm_odata(j) != stall_data[j]) ||
                (bfm_oidx(j)  != stall_idx[j])
            )
              report_fail(
                  "A3",
                  "output changed payload or source index while stalled"
              );

            if (out_ready[j])
              stall_active[j] =
                  1'b0;

          end

        end
        else if (
            out_valid[j] &&
            !out_ready[j]
        ) begin

          stall_active[j] =
              1'b1;

          stall_data[j] =
              bfm_odata(j);

          stall_idx[j] =
              bfm_oidx(j);

        end

      end


      /*
       * ------------------------------------------------------------
       * Output deliveries.
       * ------------------------------------------------------------
       */
      for (j = 0; j < N_OUT; j = j + 1) begin

        if (
            out_valid[j] &&
            out_ready[j]
        ) begin

          output_xfer_total[j] =
              output_xfer_total[j] + 1;

          src =
              bfm_oidx(j);

          got_data =
              bfm_odata(j);

          found = -1;

          /*
           * Earliest still-live beat from this source to this output.
           *
           * This checks R5 without imposing any ordering between
           * different inputs or between different outputs.
           */
          for (i = 0; i < beat_rec_count; i = i + 1) begin

            if (
                (found < 0) &&
                beat_rec[i].live &&
                (beat_rec[i].src == src) &&
                (beat_rec[i].dst == j)
            )
              found = i;

          end

          if (found < 0) begin

            report_fail(
                "R6",
                "output delivered a beat for which no matching input acceptance exists"
            );

          end
          else begin

            /*
             * Wrong output/source association generally reaches this
             * comparison because each generated payload is unique.
             */
            if (
                got_data !=
                beat_rec[found].data
            ) begin

              report_fail(
                  "R2",
                  "delivered payload differs from the accepted payload"
              );

              report_fail(
                  "R3",
                  "output source index does not identify the accepted beat"
              );

              report_fail(
                  "R5",
                  "same-input/same-output beat order was not preserved"
              );

            end

            beat_rec[found].live =
                1'b0;

            live_count =
                live_count - 1;

          end

        end

      end

    end
  end


  // ---------------------------------------------------------------------------
  // STIMULUS HELPERS
  // ---------------------------------------------------------------------------

  task automatic quiet_sources;
    integer k;

    begin
      @(posedge clk);

      bfm_offer    = '0;
      stream_gen  = '0;
      one_shot_mode = '0;
      x3_watch    = '0;

      for (k = 0; k < N_IN; k = k + 1)
        x3_age[k] = 0;
    end
  endtask


  task automatic set_all_ready;
    begin
      @(negedge clk);
      bfm_ready('1);
    end
  endtask


  task automatic tb_reset;
    integer k;

    begin
      quiet_sources();

      @(negedge clk);
      bfm_ready('1);

      bfm_reset(5);

      reset_quiet_left = 3;

      for (k = 0; k < N_IN; k = k + 1) begin
        x3_age[k]    = 0;
        x3_failed[k] = 1'b0;
      end

      repeat (4)
        @(posedge clk);
    end
  endtask


  task automatic wait_quiet(
      input integer budget,
      input string  req_name
  );
    automatic integer n;
    automatic bit done;

    begin
      done = 1'b0;

      for (n = 0; n < budget; n = n + 1) begin

        @(posedge clk);

        if (
            (in_valid == '0) &&
            (live_count == 0) &&
            (out_valid == '0)
        ) begin

          done = 1'b1;
          break;

        end

      end

      if (!done) begin

        if (live_count != 0)
          report_fail(
              "R4",
              "accepted beats did not all reach an output"
          );

        report_fail(
            req_name,
            "crossbar failed to return to quiescence within the generous test budget"
        );

      end
    end
  endtask


  task automatic start_streams_same_output(
      input integer set_size,
      input integer dst
  );
    integer k;

    begin
      @(posedge clk);

      for (k = 0; k < N_IN; k = k + 1) begin

        if (k < set_size) begin

          stream_seq[k] =
              0;

          bfm_next_data[k] =
              stream_word(k, 0);

          bfm_next_sel[k] =
              dst[SW-1:0];

          stream_gen[k] =
              1'b1;

          bfm_offer[k] =
              1'b1;

          x3_watch[k] =
              1'b1;

          x3_age[k] =
              0;

          x3_failed[k] =
              1'b0;

        end
        else begin

          bfm_offer[k] =
              1'b0;

          stream_gen[k] =
              1'b0;

          x3_watch[k] =
              1'b0;

        end

      end
    end
  endtask


  task automatic stop_streams;
    integer k;

    begin
      @(posedge clk);

      for (k = 0; k < N_IN; k = k + 1) begin

        bfm_offer[k] =
            1'b0;

        stream_gen[k] =
            1'b0;

        x3_watch[k] =
            1'b0;

        x3_age[k] =
            0;

      end
    end
  endtask


  /*
   * --------------------------------------------------------------------------
   * A2 exact fairness-window test.
   * --------------------------------------------------------------------------
   */
  task automatic run_fairness(
      input integer set_size,
      input integer dst
  );
    automatic integer hist [0:63];

    automatic integer n;
    automatic integer k;
    automatic integer p;
    automatic integer transfers;
    automatic integer target;
    automatic integer active_wait;

    automatic logic [N_IN-1:0] seen;
    automatic bit all_active;
    automatic bit fair_failed;

    begin

      tb_reset();

      @(negedge clk);
      bfm_ready('1);

      start_streams_same_output(
          set_size,
          dst
      );

      /*
       * Wait until all set members are visibly continuously offering.
       */
      all_active =
          1'b0;

      for (
          active_wait = 0;
          active_wait < 40;
          active_wait = active_wait + 1
      ) begin

        @(posedge clk);

        all_active =
            1'b1;

        for (k = 0; k < set_size; k = k + 1) begin

          if (
              !in_valid[k] ||
              (
                in_sel[k*SW +: SW] !=
                dst[SW-1:0]
              )
          )
            all_active =
                1'b0;

        end

        if (all_active)
          break;

      end

      if (!all_active)
        report_fail(
            "X3",
            "not all continuously driven contenders became active within the 32-cycle liveness region"
        );


      transfers   = 0;
      target      = set_size * 6;
      fair_failed = 1'b0;

      for (n = 0; n < FAIR_BUDGET; n = n + 1) begin

        @(posedge clk);

        if (
            out_valid[dst] &&
            out_ready[dst]
        ) begin

          if (transfers < 64)
            hist[transfers] =
                bfm_oidx(dst);

          transfers =
              transfers + 1;

          if (
              transfers >= set_size
          ) begin

            seen = '0;

            for (
                p = transfers - set_size;
                p < transfers;
                p = p + 1
            ) begin

              if (
                  (p >= 0) &&
                  (p < 64) &&
                  (hist[p] >= 0) &&
                  (hist[p] < N_IN)
              )
                seen[hist[p]] =
                    1'b1;

            end

            for (k = 0; k < set_size; k = k + 1) begin

              if (
                  !seen[k] &&
                  !fair_failed
              ) begin

                fair_failed =
                    1'b1;

                report_fail(
                    "A2",
                    "a continuously requesting contender was absent from a fairness window"
                );

              end

            end

          end


          if (transfers >= target)
            break;

        end

      end


      if (transfers < target)
        report_fail(
            "A2",
            "insufficient output transfers under sustained contention"
        );


      stop_streams();

      @(negedge clk);
      bfm_ready('1);

      wait_quiet(
          DRAIN_BUDGET,
          "R4"
      );

    end
  endtask


  /*
   * --------------------------------------------------------------------------
   * Backpressure / A3.
   * --------------------------------------------------------------------------
   */
  task automatic run_stability;
    automatic integer n;
    automatic integer start_xfers;

    automatic logic pre_valid;
    automatic logic [DW-1:0] pre_data;
    automatic logic [IW-1:0] pre_idx;

    begin

      tb_reset();

      @(negedge clk);
      bfm_ready('1);

      start_streams_same_output(
          2,
          0
      );

      start_xfers =
          output_xfer_total[0];

      /*
       * Reach a steady stream first.
       */
      for (n = 0; n < 2000; n = n + 1) begin

        @(posedge clk);

        if (
            output_xfer_total[0] >=
            start_xfers + 4
        )
          break;

      end

      if (
          output_xfer_total[0] <
          start_xfers + 4
      )
        report_fail(
            "R4",
            "could not establish traffic before the backpressure test"
        );


      /*
       * Snapshot an already asserted output immediately before applying
       * backpressure.  If no beat is currently offered, A3 imposes no
       * obligation until one is.
       */
      @(negedge clk);

      pre_valid =
          out_valid[0];

      pre_data =
          bfm_odata(0);

      pre_idx =
          bfm_oidx(0);

      out_ready[0] =
          1'b0;


      /*
       * If VALID was already asserted before READY fell, the same offered
       * beat must remain.
       */
      @(posedge clk);

      if (pre_valid) begin

        if (!out_valid[0])
          report_fail(
              "A3",
              "output withdrew a beat when backpressure was applied"
          );
        else if (
            (bfm_odata(0) != pre_data) ||
            (bfm_oidx(0)  != pre_idx)
        )
          report_fail(
              "A3",
              "output re-aimed or changed an already offered beat when backpressure was applied"
          );

      end


      /*
       * Hold the output stopped for several cycles.  The passive checker
       * verifies every cycle in which VALID remains asserted.
       */
      repeat (6)
        @(posedge clk);


      @(negedge clk);
      out_ready[0] =
          1'b1;


      repeat (6)
        @(posedge clk);


      stop_streams();

      @(negedge clk);
      bfm_ready('1);

      wait_quiet(
          DRAIN_BUDGET,
          "R4"
      );

    end
  endtask


  /*
   * --------------------------------------------------------------------------
   * Independence / HOL blocking.
   *
   * Output 0 is blocked.  Inputs 1,2,3 target free outputs and must still
   * be accepted and delivered.
   * --------------------------------------------------------------------------
   */
  task automatic run_independence;
    automatic integer n;
    automatic integer k;

    automatic integer accept_start [0:N_IN-1];
    automatic integer xfer_start   [0:N_OUT-1];

    automatic bit accepted_others;
    automatic bit delivered_others;

    begin

      tb_reset();

      for (k = 0; k < N_IN; k = k + 1) begin
        accept_start[k] =
            input_accept_total[k];

        xfer_start[k] =
            output_xfer_total[k];
      end


      @(negedge clk);

      out_ready =
          4'b1110;


      /*
       * Four one-shot beats:
       *
       * input 0 -> blocked output 0
       * input 1 -> output 1
       * input 2 -> output 2
       * input 3 -> output 3
       */
      @(posedge clk);

      for (k = 0; k < N_IN; k = k + 1) begin

        bfm_next_data[k] =
            32'h4000_0000 +
            (k << 16) +
            k;

        bfm_next_sel[k] =
            k[SW-1:0];

        one_shot_mode[k] =
            1'b1;

        bfm_offer[k] =
            1'b1;

        x3_age[k] =
            0;

        x3_failed[k] =
            1'b0;

        /*
         * Input 0 has a non-ready destination, so X3 does not apply.
         */
        if (k == 0)
          x3_watch[k] =
              1'b0;
        else
          x3_watch[k] =
              1'b1;

      end


      accepted_others =
          1'b0;

      for (n = 0; n < 32; n = n + 1) begin

        @(posedge clk);

        if (
            (input_accept_total[1] > accept_start[1]) &&
            (input_accept_total[2] > accept_start[2]) &&
            (input_accept_total[3] > accept_start[3])
        ) begin

          accepted_others =
              1'b1;

          break;

        end

      end


      if (!accepted_others) begin

        report_fail(
            "I2",
            "an input targeting a blocked output prevented an unrelated input from being accepted"
        );

        report_fail(
            "X3",
            "a beat targeting a continuously ready output was not accepted within 32 cycles"
        );

      end


      /*
       * The three unrelated outputs must continue to make progress even
       * while output 0 remains stalled.
       */
      delivered_others =
          1'b0;

      for (n = 0; n < 3000; n = n + 1) begin

        @(posedge clk);

        if (
            (output_xfer_total[1] > xfer_start[1]) &&
            (output_xfer_total[2] > xfer_start[2]) &&
            (output_xfer_total[3] > xfer_start[3])
        ) begin

          delivered_others =
              1'b1;

          break;

        end

      end


      if (!delivered_others)
        report_fail(
            "I1",
            "a blocked output prevented independent ready outputs from making progress"
        );


      /*
       * Release output 0 so its held source can finish too.
       */
      @(negedge clk);
      out_ready =
          '1;

      @(posedge clk);
      x3_watch =
          '0;

      wait_quiet(
          DRAIN_BUDGET,
          "R4"
      );

    end
  endtask


  /*
   * --------------------------------------------------------------------------
   * Reset with possible internal work.
   *
   * A no-buffer implementation may refuse the beat while the destination is
   * stalled; a buffered implementation may accept it.  Both are legal.
   * If it WAS accepted, reset must discard it.
   * --------------------------------------------------------------------------
   */
  task automatic run_reset_discard;
    automatic integer k;
    automatic integer start_accept;

    begin

      tb_reset();

      start_accept =
          input_accept_total[0];


      @(negedge clk);
      out_ready =
          4'b1110;


      @(posedge clk);

      bfm_next_data[0] =
          32'h55AA_1234;

      bfm_next_sel[0] =
          2'd0;

      one_shot_mode[0] =
          1'b1;

      bfm_offer[0] =
          1'b1;


      /*
       * Give implementations that buffer blocked traffic a chance to accept.
       * No acceptance is REQUIRED here.
       */
      repeat (8)
        @(posedge clk);


      /*
       * Stop asking for new work.  If the currently visible beat was never
       * accepted, reset itself is allowed to discard the source-side offer.
       */
      @(posedge clk);

      bfm_offer       = '0;
      stream_gen     = '0;
      one_shot_mode  = '0;
      x3_watch       = '0;


      /*
       * Keep output 0 blocked while reset is asserted so an implementation
       * cannot retire a buffered beat immediately before reset.
       */
      bfm_reset(5);

      reset_quiet_left =
          4;


      @(negedge clk);
      out_ready =
          '1;


      /*
       * With no post-reset input traffic there may be no output traffic.
       */
      repeat (6)
        @(posedge clk);


      /*
       * The fact that some conforming designs did not accept the pre-reset
       * blocked beat is deliberately NOT considered an error.
       */
      for (k = 0; k < N_IN; k = k + 1) begin
        bfm_offer[k] =
            1'b0;
      end

    end
  endtask


  /*
   * --------------------------------------------------------------------------
   * A simple all-disjoint routing phase.
   * --------------------------------------------------------------------------
   */
  task automatic run_disjoint_routing;
    automatic integer k;
    automatic integer n;

    automatic integer accept_start [0:N_IN-1];

    begin

      tb_reset();

      @(negedge clk);
      out_ready =
          '1;


      for (k = 0; k < N_IN; k = k + 1)
        accept_start[k] =
            input_accept_total[k];


      @(posedge clk);

      for (k = 0; k < N_IN; k = k + 1) begin

        bfm_next_data[k] =
            32'h1000_0000 +
            (k << 20) +
            (k << 4);

        bfm_next_sel[k] =
            k[SW-1:0];

        one_shot_mode[k] =
            1'b1;

        bfm_offer[k] =
            1'b1;

        x3_watch[k] =
            1'b1;

        x3_age[k] =
            0;

        x3_failed[k] =
            1'b0;

      end


      /*
       * All four destinations are continuously ready, so every input must
       * accept within the X3 bound.
       */
      for (n = 0; n < 33; n = n + 1) begin

        @(posedge clk);

        if (
            (input_accept_total[0] > accept_start[0]) &&
            (input_accept_total[1] > accept_start[1]) &&
            (input_accept_total[2] > accept_start[2]) &&
            (input_accept_total[3] > accept_start[3])
        )
          break;

      end


      for (k = 0; k < N_IN; k = k + 1) begin

        if (
            input_accept_total[k] ==
            accept_start[k]
        )
          report_fail(
              "X3",
              "disjoint ready-path beat was not accepted within 32 cycles"
          );

      end


      @(posedge clk);
      x3_watch =
          '0;


      wait_quiet(
          DRAIN_BUDGET,
          "R4"
      );

    end
  endtask


  // ---------------------------------------------------------------------------
  // MAIN TEST
  // ---------------------------------------------------------------------------

  initial begin : main_test
    integer k;
    integer j;

    fail_count        = 0;
    tb_cycle          = 0;
    clock_seen        = 0;
    beat_rec_count    = 0;
    live_count        = 0;
    reset_quiet_left  = 0;

    stream_gen        = '0;
    one_shot_mode     = '0;
    x3_watch          = '0;
    x3_failed         = '0;

    for (k = 0; k < N_IN; k = k + 1) begin

      stream_seq[k] =
          0;

      x3_age[k] =
          0;

      input_accept_total[k] =
          0;

    end

    for (j = 0; j < N_OUT; j = j + 1) begin

      output_xfer_total[j] =
          0;

      stall_active[j] =
          1'b0;

      stall_data[j] =
          '0;

      stall_idx[j] =
          '0;

    end


    /*
     * Basic reset and four independent routes.
     */
    run_disjoint_routing();


    /*
     * Exact A2 fairness windows for every interesting contention-set size.
     *
     * Starting arbiter rotation is never assumed.
     */
    run_fairness(2, 2);
    run_fairness(3, 1);
    run_fairness(4, 0);


    /*
     * Output backpressure and held-offer stability.
     */
    run_stability();


    /*
     * Cross-output and cross-input independence.
     */
    run_independence();


    /*
     * Reset must erase whatever state a buffering implementation happened
     * to accumulate.  Refusing the blocked input before reset is legal too.
     */
    run_reset_discard();


    /*
     * Final reset also verifies that no old bookkeeping affects new traffic.
     */
    tb_reset();

    run_disjoint_routing();


    /*
     * Final exactly-once check.
     */
    if (count_live() != 0)
      report_fail(
          "R4",
          "accepted beats remained undelivered at end of test"
      );


    if (fail_count == 0)
      $display("RESULT: PASS");
    else
      $display("RESULT: FAIL");

    $finish;
  end


  // ---------------------------------------------------------------------------
  // WATCHDOG
  // ---------------------------------------------------------------------------

  initial begin
    #2_000_000;
    $display("FAIL X3: watchdog expired before the testbench reached a verdict");
    $display("RESULT: FAIL");
    $finish;
  end

endmodule