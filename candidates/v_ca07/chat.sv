module clk_ratio_div_tb;

  localparam time CLK_HALF_T = 5;
  localparam time CLK_PER_T  = 10;

  localparam int EDGE_LOG    = 8192;
  localparam int WAIT_CYCLES = 4096;

  // ==========================================================================
  // DUT signals
  // ==========================================================================

  logic       clk;
  logic       rst_n;
  logic       en;
  logic       test_mode_en;
  logic [3:0] div;
  logic       div_valid;

  logic       div_ready;
  logic       clk_out;
  logic [3:0] cycl_count;


  clk_ratio_div dut (
      .clk_i           (clk),
      .rst_ni          (rst_n),
      .en_i            (en),
      .test_mode_en_i  (test_mode_en),
      .div_i           (div),
      .div_valid_i     (div_valid),
      .div_ready_o     (div_ready),
      .clk_o           (clk_out),
      .cycl_count_o    (cycl_count)
  );


  // ==========================================================================
  // Clock / reset
  // ==========================================================================

  initial begin
    clk = 1'b0;
    forever #CLK_HALF_T clk = ~clk;
  end


  task automatic bfm_reset(input integer cycles);
    begin
      @(negedge clk);
      rst_n = 1'b0;

      repeat (cycles)
        @(posedge clk);

      @(negedge clk);
      rst_n = 1'b1;
    end
  endtask


  // ==========================================================================
  // Edge log
  //
  // Stimulus is NEVER clocked from clk_out.  These blocks only timestamp its
  // edges.  All waits/timeouts used by stimulus remain driven from clk.
  // ==========================================================================

  time rise_time [0:EDGE_LOG-1];
  time fall_time [0:EDGE_LOG-1];

  integer rise_count;
  integer fall_count;


  always @(posedge clk_out) begin
    if (rst_n) begin
      if (rise_count < EDGE_LOG)
        rise_time[rise_count] = $time;

      rise_count = rise_count + 1;
    end
  end


  always @(negedge clk_out) begin
    if (rst_n) begin
      if (fall_count < EDGE_LOG)
        fall_time[fall_count] = $time;

      fall_count = fall_count + 1;
    end
  end


  // ==========================================================================
  // Common bookkeeping
  // ==========================================================================

  integer fail_count;

  logic [3:0] current_div;

  bit h1_reported;


  task automatic fail_req(
      input string req_name,
      input string text
  );
    begin
      fail_count = fail_count + 1;
      $display("FAIL %s: %s", req_name, text);
    end
  endtask


  /*
   * H1: READY is not free-running.
   */
  always @(posedge clk) begin
    if (
        rst_n &&
        !div_valid &&
        div_ready &&
        !h1_reported
    ) begin

      h1_reported = 1'b1;

      fail_req(
          "H1",
          "div_ready_o asserted while div_valid_i was low"
      );

    end
  end


  function automatic integer period_cycles(
      input logic [3:0] d
  );
    begin
      if (d <= 1)
        period_cycles = 1;
      else
        period_cycles = d;
    end
  endfunction


  function automatic time period_time(
      input logic [3:0] d
  );
    begin
      period_time =
          period_cycles(d) * CLK_PER_T;
    end
  endfunction


  function automatic time half_period_time(
      input logic [3:0] d
  );
    begin
      if (d <= 1)
        half_period_time = CLK_HALF_T;
      else
        half_period_time = d * CLK_HALF_T;
    end
  endfunction


  task automatic find_first_rise_after(
      input  time    after_t,
      output bit     found,
      output integer idx
  );
    integer i;

    begin
      found = 1'b0;
      idx   = -1;

      for (i = 0; i < rise_count; i = i + 1) begin

        if (
            !found &&
            (rise_time[i] > after_t)
        ) begin

          found = 1'b1;
          idx   = i;

        end

      end
    end
  endtask


  task automatic find_first_fall_after(
      input  time    after_t,
      output bit     found,
      output integer idx
  );
    integer i;

    begin
      found = 1'b0;
      idx   = -1;

      for (i = 0; i < fall_count; i = i + 1) begin

        if (
            !found &&
            (fall_time[i] > after_t)
        ) begin

          found = 1'b1;
          idx   = i;

        end

      end
    end
  endtask


  // ==========================================================================
  // Wait helpers -- all driven from clk_i
  // ==========================================================================

  task automatic wait_rise_target(
      input  integer target,
      input  integer budget,
      output bit     reached
  );
    integer n;

    begin
      reached = 1'b0;

      for (n = 0; n < budget; n = n + 1) begin

        @(posedge clk);

        if (rise_count >= target) begin
          reached = 1'b1;
          break;
        end

      end
    end
  endtask


  task automatic wait_fall_after(
      input  time    after_t,
      input  integer budget,
      output bit     found,
      output integer idx
  );
    integer n;

    begin
      found = 1'b0;
      idx   = -1;

      for (n = 0; n < budget; n = n + 1) begin

        @(posedge clk);

        find_first_fall_after(
            after_t,
            found,
            idx
        );

        if (found)
          break;

      end
    end
  endtask


  // ==========================================================================
  // Reconfiguration
  // ==========================================================================

  task automatic request_different_div(
      input logic [3:0] new_div
  );
    integer n;
    integer max_wait;
    integer first_idx;
    integer fall_idx;

    logic [3:0] old_div;

    bit granted;
    bit found;
    bit fall_found;

    time grant_t;
    time first_rise_t;
    time max_gap_t;
    time width_t;

    begin
      old_div = current_div;

      if (new_div == old_div) begin

        fail_req(
            "H1",
            "testbench called different-divisor request with the current value"
        );

      end
      else begin

        granted = 1'b0;
        grant_t = 0;

        @(negedge clk);

        div       = new_div;
        div_valid = 1'b1;


        /*
         * L3 leaves the grant phase free.  Use a generous timeout only so a
         * broken implementation cannot stop the entire testbench.
         */
        for (n = 0; n < WAIT_CYCLES; n = n + 1) begin

          @(posedge clk);

          if (div_ready) begin
            granted = 1'b1;
            grant_t = $time;
            break;
          end

        end


        if (!granted) begin

          fail_req(
              "H1",
              "a held divisor-change request never completed"
          );

          @(negedge clk);
          div_valid = 1'b0;

        end
        else begin

          current_div = new_div;

          @(negedge clk);
          div_valid = 1'b0;


          /*
           * G1 starts HERE: at the handshake/grant, not at VALID assertion.
           *
           * Ignore a rise exactly coincident with the handshake because it is
           * phase-ambiguous.  Taking the next rise is still within one new
           * period of a coincident first edge and therefore preserves G1's
           * upper-bound test.
           */
          found     = 1'b0;
          first_idx = -1;

          max_wait =
              (3 * period_cycles(new_div)) + 12;

          for (n = 0; n < max_wait; n = n + 1) begin

            @(posedge clk);

            find_first_rise_after(
                grant_t,
                found,
                first_idx
            );

            if (found)
              break;

          end


          if (!found) begin

            fail_req(
                "G1",
                "no rising edge appeared within the reconfiguration gating bound"
            );

            if (clk_out === 1'b1)
              fail_req(
                  "G2",
                  "clock remained high instead of being gated low"
              );

          end
          else begin

            first_rise_t =
                rise_time[first_idx];

            max_gap_t =
                3 * period_time(new_div);

            if (
                (first_rise_t - grant_t) >
                max_gap_t
            )
              fail_req(
                  "G1",
                  "gap from div_ready_o grant to the new clock exceeded 3x the new period"
              );


            /*
             * G2: the first visible new pulse may not be malformed.
             * Duty itself is excluded for pass-through divisors.
             */
            if (new_div >= 2) begin

              wait_fall_after(
                  first_rise_t,
                  period_cycles(new_div) + 8,
                  fall_found,
                  fall_idx
              );

              if (!fall_found) begin

                fail_req(
                    "G2",
                    "first pulse after reconfiguration never returned low"
                );

              end
              else begin

                width_t =
                    fall_time[fall_idx] -
                    first_rise_t;

                if (
                    width_t !=
                    half_period_time(new_div)
                )
                  fail_req(
                      "G2",
                      "first pulse after reconfiguration was truncated or malformed"
                  );

              end

            end

          end

        end

      end
    end
  endtask


  // ==========================================================================
  // Stable period / duty measurement
  // ==========================================================================

  task automatic check_stable_clock(
      input logic [3:0] d
  );
    integer base;
    integer first;
    integer last;
    integer i;
    integer j;
    integer falls_between;

    bit reached;

    time exp_period;
    time exp_half;
    time rise_a;
    time rise_b;
    time fall_v;

    begin
      base = rise_count;

      /*
       * Collect enough edges that any transition/gating phase is long past.
       */
      wait_rise_target(
          base + 7,
          WAIT_CYCLES,
          reached
      );

      if (!reached) begin

        if (d <= 1)
          fail_req(
              "P3",
              "pass-through clock produced too few rising edges"
          );
        else
          fail_req(
              "P1",
              "configured clock produced too few rising edges"
          );

      end
      else begin

        /*
         * Inspect only the last five complete periods.
         */
        last  = rise_count - 1;
        first = last - 4;

        exp_period =
            period_time(d);

        exp_half =
            half_period_time(d);


        for (i = first; i < last; i = i + 1) begin

          rise_a =
              rise_time[i];

          rise_b =
              rise_time[i + 1];


          if (
              (rise_b - rise_a) !=
              exp_period
          ) begin

            if (d <= 1)
              fail_req(
                  "P3",
                  "divisor 0/1 did not produce one clk_i cycle per clk_o period"
              );
            else
              fail_req(
                  "P1",
                  "clk_o period was not exactly div_i clk_i cycles"
              );

          end


          /*
           * X2 excludes pass-through duty measurement.
           */
          if (d >= 2) begin

            falls_between = 0;
            fall_v        = 0;

            for (j = 0; j < fall_count; j = j + 1) begin

              if (
                  (fall_time[j] > rise_a) &&
                  (fall_time[j] < rise_b)
              ) begin

                falls_between =
                    falls_between + 1;

                fall_v =
                    fall_time[j];

              end

            end


            if (falls_between != 1) begin

              fail_req(
                  "P2",
                  "a stable clk_o period did not contain exactly one falling edge"
              );

            end
            else begin

              /*
               * This is raw-time measurement.  For an odd divisor exp_half
               * is 15,25,35,... time units, i.e. 1.5,2.5,3.5,... clk_i
               * cycles.
               */
              if (
                  (fall_v - rise_a) !=
                  exp_half
              )
                fail_req(
                    "P2",
                    "clk_o high phase was not exactly half of its period"
                );

              if (
                  (rise_b - fall_v) !=
                  exp_half
              )
                fail_req(
                    "P2",
                    "clk_o low phase was not exactly half of its period"
                );

            end

          end

        end

      end
    end
  endtask


  // ==========================================================================
  // Cycle counter
  // ==========================================================================

  task automatic check_counter(
      input logic [3:0] d,
      input integer     samples
  );
    integer n;

    logic [3:0] prev_v;
    logic [3:0] now_v;
    logic [3:0] expected_v;

    bit have_prev;

    begin
      have_prev = 1'b0;
      prev_v    = '0;


      for (n = 0; n < samples; n = n + 1) begin

        /*
         * Sample midway between DUT rising-edge updates.
         */
        @(negedge clk);

        now_v =
            cycl_count;


        if (d <= 1) begin

          if (now_v != 0)
            fail_req(
                "C2",
                "cycl_count_o was not constantly zero in pass-through"
            );

        end
        else begin

          if (now_v >= d)
            fail_req(
                "C1",
                "cycl_count_o left the configured divisor range"
            );


          if (have_prev) begin

            if (prev_v == (d - 1))
              expected_v = 0;
            else
              expected_v = prev_v + 1'b1;

            if (now_v != expected_v)
              fail_req(
                  "C1",
                  "cycl_count_o did not advance once per clk_i cycle modulo the divisor"
              );

          end

        end


        prev_v =
            now_v;

        have_prev =
            1'b1;

      end
    end
  endtask


  // ==========================================================================
  // H3 same-value request
  // ==========================================================================

  task automatic test_same_value;
    integer n;
    integer start_idx;
    integer target;

    bit reached;

    time exp_period;

    begin
      /*
       * Put the unit at div 4 first.
       */
      if (current_div != 4)
        request_different_div(4);

      check_stable_clock(4);


      if (rise_count > 0)
        start_idx = rise_count - 1;
      else
        start_idx = 0;


      @(negedge clk);

      div       = 4;
      div_valid = 1'b1;


      /*
       * H3: same-value grant is immediate -- first eligible sampling cycle.
       */
      @(posedge clk);

      if (!div_ready)
        fail_req(
            "H3",
            "same-value divisor request was not granted immediately"
        );


      @(negedge clk);
      div_valid = 1'b0;


      /*
       * H3 also says there is NO gating.  Therefore rising-edge spacing across
       * the request must remain the normal div-4 period.
       */
      target =
          start_idx + 6;

      wait_rise_target(
          target,
          WAIT_CYCLES,
          reached
      );

      if (!reached) begin

        fail_req(
            "H3",
            "same-value request gated or stopped clk_o"
        );

      end
      else begin

        exp_period =
            period_time(4);

        for (n = start_idx; n < (start_idx + 5); n = n + 1) begin

          if (
              (n + 1 < rise_count) &&
              (
                (rise_time[n + 1] - rise_time[n]) !=
                exp_period
              )
          )
            fail_req(
                "H3",
                "same-value request disturbed the running output clock"
            );

        end

      end
    end
  endtask


  // ==========================================================================
  // H4: request while first transition is still gating
  // ==========================================================================

  task automatic test_deferred_request;
    integer n;
    integer i;

    bit first_granted;
    bit second_granted;
    bit rise_seen;
    bit offered_during_gate;

    time first_grant_t;

    begin
      if (current_div != 4)
        request_different_div(4);

      check_stable_clock(4);


      first_granted       = 1'b0;
      second_granted      = 1'b0;
      rise_seen           = 1'b0;
      offered_during_gate = 1'b0;
      first_grant_t       = 0;


      /*
       * First change.
       */
      @(negedge clk);

      div       = 4'd15;
      div_valid = 1'b1;


      for (n = 0; n < WAIT_CYCLES; n = n + 1) begin

        @(posedge clk);

        if (div_ready) begin

          first_granted =
              1'b1;

          first_grant_t =
              $time;

          break;

        end

      end


      if (!first_granted) begin

        fail_req(
            "H1",
            "first change in H4 test was never accepted"
        );

        @(negedge clk);
        div_valid = 1'b0;

      end
      else begin

        current_div = 4'd15;


        /*
         * At the next safe drive point, determine whether the first clock has
         * resumed yet.  If not, changing the VALID payload here creates the H4
         * situation while still respecting H2: the first request already
         * handshook.
         */
        @(negedge clk);

        rise_seen = 1'b0;

        for (i = 0; i < rise_count; i = i + 1) begin

          if (
              rise_time[i] >
              first_grant_t
          )
            rise_seen = 1'b1;

        end


        if (
            !rise_seen &&
            (clk_out === 1'b0)
        )
          offered_during_gate =
              1'b1;


        /*
         * Back-to-back second request.  VALID remains asserted and DIV changes
         * only after the first handshake, so H2 is obeyed.
         */
        div =
            4'd6;


        for (n = 0; n < WAIT_CYCLES; n = n + 1) begin

          @(posedge clk);

          if (div_ready) begin

            second_granted =
                1'b1;

            break;

          end

        end


        @(negedge clk);
        div_valid = 1'b0;


        if (offered_during_gate) begin

          if (!second_granted)
            fail_req(
                "H4",
                "request offered during an existing transition was refused instead of deferred"
            );

        end


        if (second_granted)
          current_div = 4'd6;

      end


      if (second_granted) begin

        check_stable_clock(6);
        check_counter(6, 12);

      end
    end
  endtask


  // ==========================================================================
  // Enable
  // ==========================================================================

  task automatic test_enable;
    integer n;
    integer rise_before;
    integer rise_at_disable;
    integer fall_idx;

    bit found;
    bit reached;

    time pulse_rise_t;
    time exp_half;

    begin
      if (current_div != 5)
        request_different_div(5);

      check_stable_clock(5);

      exp_half =
          half_period_time(5);


      /*
       * Disable while a high pulse is in progress.
       *
       * We only advance from clk_i edges; clk_out merely supplies timestamp
       * information.
       */
      found = 1'b0;

      for (n = 0; n < 100; n = n + 1) begin

        @(negedge clk);

        if (
            (clk_out === 1'b1) &&
            (rise_count > 0) &&
            (($time - rise_time[rise_count - 1]) < exp_half)
        ) begin

          pulse_rise_t =
              rise_time[rise_count - 1];

          en =
              1'b0;

          found =
              1'b1;

          break;

        end

      end


      if (!found) begin

        fail_req(
            "E3",
            "testbench could not reach a high phase for disable test"
        );

      end
      else begin

        rise_at_disable =
            rise_count;


        /*
         * Find the falling edge ending the high pulse that was already active.
         */
        wait_fall_after(
            pulse_rise_t,
            20,
            reached,
            fall_idx
        );


        if (!reached) begin

          fail_req(
              "E3",
              "output remained high after enable was removed"
          );

        end
        else begin

          if (
              (fall_time[fall_idx] - pulse_rise_t) !=
              exp_half
          )
            fail_req(
                "E3",
                "disabling the divider truncated the final high pulse"
            );

        end


        /*
         * E1: once disabled there must be no new rising edges.
         */
        rise_before =
            rise_count;

        repeat (100)
          @(posedge clk);

        if (rise_count != rise_before)
          fail_req(
              "E1",
              "clk_o produced a rising edge while en_i was low"
          );


        if (clk_out !== 1'b0)
          fail_req(
              "E3",
              "disabled clock did not settle and remain low"
          );


        /*
         * E2: re-enable without changing the configured divisor.
         */
        @(negedge clk);
        en = 1'b1;


        wait_rise_target(
            rise_count + 4,
            WAIT_CYCLES,
            reached
        );


        if (!reached) begin

          fail_req(
              "E2",
              "clk_o did not resume after en_i returned high"
          );

        end
        else begin

          check_stable_clock(5);

        end

      end
    end
  endtask


  // ==========================================================================
  // Reset restoring default divisor
  // ==========================================================================

  task automatic test_reset_default;
    integer base;
    integer last;
    integer i;

    bit reached;

    begin
      if (current_div != 4)
        request_different_div(4);

      check_stable_clock(4);


      @(negedge clk);

      div_valid = 1'b0;
      en        = 1'b1;

      bfm_reset(5);

      current_div = 4'd0;


      /*
       * X1 says not to inspect outputs while reset itself is low.
       * R2 is checked after release.
       */
      base = rise_count;

      wait_rise_target(
          base + 7,
          WAIT_CYCLES,
          reached
      );


      if (!reached) begin

        fail_req(
            "R2",
            "output did not resume after reset"
        );

      end
      else begin

        last = rise_count - 1;

        for (i = last - 4; i < last; i = i + 1) begin

          if (
              (rise_time[i + 1] - rise_time[i]) !=
              CLK_PER_T
          )
            fail_req(
                "R2",
                "reset did not restore the default pass-through divisor"
            );

        end

      end


      check_counter(
          0,
          8
      );
    end
  endtask


  // ==========================================================================
  // H1 idle-ready check
  // ==========================================================================

  task automatic test_ready_idle;
    integer n;

    begin
      @(negedge clk);

      div_valid = 1'b0;


      for (n = 0; n < 20; n = n + 1) begin

        @(posedge clk);

        if (div_ready)
          fail_req(
              "H1",
              "div_ready_o was high with no divisor request"
          );

      end
    end
  endtask


  // ==========================================================================
  // Main
  // ==========================================================================

  initial begin : main_test
    integer d;

    fail_count   = 0;
    rise_count   = 0;
    fall_count   = 0;
    h1_reported  = 1'b0;

    rst_n        = 1'b0;
    en           = 1'b1;
    test_mode_en = 1'b0;
    div           = 4'd0;
    div_valid     = 1'b0;

    current_div   = 4'd0;


    // ------------------------------------------------------------------------
    // Initial reset/default-divisor behavior
    // ------------------------------------------------------------------------

    bfm_reset(5);

    current_div = 4'd0;


    test_ready_idle();


    /*
     * P3/C2: reset divisor 0 is pass-through.
     */
    check_stable_clock(0);
    check_counter(0, 8);


    // ------------------------------------------------------------------------
    // Sweep every non-degenerate divisor.
    //
    // This explicitly includes every odd divisor so P2/P4 is exercised with
    // half-integer clk_i-cycle high/low intervals.
    // ------------------------------------------------------------------------

    request_different_div(1);

    check_stable_clock(1);
    check_counter(1, 8);


    for (d = 2; d <= 15; d = d + 1) begin

      request_different_div(
          d[3:0]
      );

      check_stable_clock(
          d[3:0]
      );

      check_counter(
          d[3:0],
          (2 * d) + 4
      );

    end


    // ------------------------------------------------------------------------
    // H3: exact same-value semantics.
    // ------------------------------------------------------------------------

    test_same_value();


    // ------------------------------------------------------------------------
    // C3: explicitly cross from a larger old counter range into a smaller new
    // range.  check_counter() may never observe an old-range value >=3 once
    // the new clock is running.
    // ------------------------------------------------------------------------

    if (current_div != 8)
      request_different_div(8);

    check_stable_clock(8);

    request_different_div(3);

    check_stable_clock(3);
    check_counter(3, 16);


    // ------------------------------------------------------------------------
    // H4: deferred second request during gating.
    // ------------------------------------------------------------------------

    test_deferred_request();


    // ------------------------------------------------------------------------
    // Enable behavior, including odd-divisor final pulse width.
    // ------------------------------------------------------------------------

    test_enable();


    // ------------------------------------------------------------------------
    // Reset must restore divisor 0 rather than retain the previous divisor.
    // ------------------------------------------------------------------------

    test_reset_default();


    // ------------------------------------------------------------------------
    // Final verdict
    // ------------------------------------------------------------------------

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
        "FAIL G1: watchdog expired before the testbench reached a verdict"
    );

    $display("RESULT: FAIL");

    $finish;
  end

endmodule