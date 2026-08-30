module fp_noncomp_tb;

  // ==========================================================================
  // DUT signals
  // ==========================================================================

  logic        clk;
  logic        rst_n;

  logic [31:0] operand_a_i;
  logic [31:0] operand_b_i;
  logic [1:0]  op_i;
  logic [2:0]  op_mode_i;
  logic        in_valid_i;
  logic        in_ready_o;

  logic [31:0] result_o;
  logic [9:0]  class_mask_o;
  logic [4:0]  status_o;
  logic        out_valid_o;
  logic        out_ready_i;


  fp_noncomp dut (
      .clk_i         (clk),
      .rst_ni        (rst_n),

      .operand_a_i   (operand_a_i),
      .operand_b_i   (operand_b_i),
      .op_i          (op_i),
      .op_mode_i     (op_mode_i),

      .in_valid_i    (in_valid_i),
      .in_ready_o    (in_ready_o),

      .result_o      (result_o),
      .class_mask_o  (class_mask_o),
      .status_o      (status_o),

      .out_valid_o   (out_valid_o),
      .out_ready_i   (out_ready_i)
  );


  // ==========================================================================
  // Constants
  // ==========================================================================

  localparam logic [1:0] OP_SGNJ     = 2'd0;
  localparam logic [1:0] OP_MINMAX   = 2'd1;
  localparam logic [1:0] OP_CMP      = 2'd2;
  localparam logic [1:0] OP_CLASSIFY = 2'd3;

  localparam logic [31:0] CANON_QNAN = 32'h7FC0_0000;

  localparam integer WAIT_LIMIT = 50000;


  // ==========================================================================
  // Clock / reset / provided-style BFM
  // ==========================================================================

  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end


  initial begin
    rst_n = 1'b0;
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


  task automatic bfm_issue(
      input logic [31:0] a,
      input logic [31:0] b,
      input logic [1:0]  op,
      input logic [2:0]  mode
  );
    begin
      @(negedge clk);

      operand_a_i = a;
      operand_b_i = b;
      op_i        = op;
      op_mode_i   = mode;
      in_valid_i  = 1'b1;

      forever begin
        @(posedge clk);

        if (in_ready_o)
          break;
      end
    end
  endtask


  task automatic bfm_idle;
    begin
      @(negedge clk);
      in_valid_i = 1'b0;
    end
  endtask


  task automatic bfm_out_ready(
      input logic value
  );
    begin
      @(negedge clk);
      out_ready_i = value;
    end
  endtask


  // ==========================================================================
  // Reference-model record
  // ==========================================================================

  typedef struct packed {
    logic [31:0] result;
    logic [9:0]  class_mask;
    logic [4:0]  status;
    logic        check_result;
    logic        check_class;
  } exp_rec_t;

  exp_rec_t exp_q[$];

  integer fail_count;
  integer accepted_count;
  integer delivered_count;
  integer stall_cycle_count;

  integer reset_low_edges;


  // ==========================================================================
  // Floating-point bit helpers
  // ==========================================================================

  function automatic logic fp_is_nan(
      input logic [31:0] x
  );
    begin
      fp_is_nan =
          (x[30:23] == 8'hFF) &&
          (x[22:0]  != 23'h0);
    end
  endfunction


  function automatic logic fp_is_snan(
      input logic [31:0] x
  );
    begin
      fp_is_snan =
          (x[30:23] == 8'hFF) &&
          (x[22:0]  != 23'h0) &&
          (x[22]    == 1'b0);
    end
  endfunction


  function automatic logic fp_is_zero(
      input logic [31:0] x
  );
    begin
      fp_is_zero =
          (x[30:0] == 31'h0);
    end
  endfunction


  /*
   * IEEE comparison less-than for NON-NaN inputs.
   *
   * +0 and -0 compare equal here, as required by CMP.
   */
  function automatic logic fp_lt(
      input logic [31:0] a,
      input logic [31:0] b
  );
    logic [30:0] amag;
    logic [30:0] bmag;

    begin
      amag = a[30:0];
      bmag = b[30:0];

      if (
          fp_is_zero(a) &&
          fp_is_zero(b)
      ) begin

        fp_lt = 1'b0;

      end
      else if (a[31] != b[31]) begin

        fp_lt = a[31];

      end
      else if (a[31] == 1'b0) begin

        fp_lt =
            (amag < bmag);

      end
      else begin

        fp_lt =
            (amag > bmag);

      end
    end
  endfunction


  function automatic logic fp_eq(
      input logic [31:0] a,
      input logic [31:0] b
  );
    begin
      if (
          fp_is_zero(a) &&
          fp_is_zero(b)
      )
        fp_eq = 1'b1;
      else
        fp_eq = (a == b);
    end
  endfunction


  // ==========================================================================
  // CLASSIFY model
  // ==========================================================================

  function automatic logic [9:0] fp_classify(
      input logic [31:0] x
  );
    logic [9:0] m;

    begin
      m = 10'b0;

      if (x[30:23] == 8'hFF) begin

        if (x[22:0] == 23'h0) begin

          if (x[31])
            m[0] = 1'b1;
          else
            m[7] = 1'b1;

        end
        else if (x[22] == 1'b0) begin

          m[8] = 1'b1;

        end
        else begin

          m[9] = 1'b1;

        end

      end
      else if (x[30:23] == 8'h00) begin

        if (x[22:0] == 23'h0) begin

          if (x[31])
            m[3] = 1'b1;
          else
            m[4] = 1'b1;

        end
        else begin

          if (x[31])
            m[2] = 1'b1;
          else
            m[5] = 1'b1;

        end

      end
      else begin

        if (x[31])
          m[1] = 1'b1;
        else
          m[6] = 1'b1;

      end

      fp_classify = m;
    end
  endfunction


  // ==========================================================================
  // Expected-result model
  // ==========================================================================

  function automatic exp_rec_t make_expected(
      input logic [31:0] a,
      input logic [31:0] b,
      input logic [1:0]  op,
      input logic [2:0]  mode
  );
    exp_rec_t e;

    logic nan_a;
    logic nan_b;
    logic snan_a;
    logic snan_b;
    logic nv;

    logic comparison;
    logic [31:0] chosen;

    begin
      e = '0;

      e.check_result = 1'b1;
      e.check_class  = 1'b0;

      nan_a  = fp_is_nan(a);
      nan_b  = fp_is_nan(b);
      snan_a = fp_is_snan(a);
      snan_b = fp_is_snan(b);

      nv         = 1'b0;
      comparison = 1'b0;
      chosen     = 32'h0;


      case (op)

        // --------------------------------------------------------------------
        // SGNJ
        // --------------------------------------------------------------------

        OP_SGNJ: begin

          e.result[30:0] = a[30:0];

          case (mode)

            3'd0:
              e.result[31] = b[31];

            3'd1:
              e.result[31] = ~b[31];

            3'd2:
              e.result[31] = a[31] ^ b[31];

            default:
              e.result[31] = 1'b0;

          endcase

          /*
           * S2: even an sNaN operand causes no exception.
           */
          nv = 1'b0;

        end


        // --------------------------------------------------------------------
        // MINMAX
        // --------------------------------------------------------------------

        OP_MINMAX: begin

          nv =
              snan_a ||
              snan_b;


          if (nan_a && nan_b) begin

            e.result =
                CANON_QNAN;

          end
          else if (nan_a) begin

            e.result =
                b;

          end
          else if (nan_b) begin

            e.result =
                a;

          end
          else if (
              fp_is_zero(a) &&
              fp_is_zero(b)
          ) begin

            /*
             * MINMAX gives -0 an ordering below +0.
             */
            if (mode == 3'd0) begin

              if (a[31] || b[31])
                e.result = 32'h8000_0000;
              else
                e.result = 32'h0000_0000;

            end
            else begin

              if (!a[31] || !b[31])
                e.result = 32'h0000_0000;
              else
                e.result = 32'h8000_0000;

            end

          end
          else begin

            if (mode == 3'd0) begin

              if (fp_lt(a, b))
                chosen = a;
              else
                chosen = b;

            end
            else begin

              if (fp_lt(a, b))
                chosen = b;
              else
                chosen = a;

            end

            e.result = chosen;

          end

        end


        // --------------------------------------------------------------------
        // CMP
        // --------------------------------------------------------------------

        OP_CMP: begin

          if (mode == 3'd0) begin

            /*
             * FLE is signalling.
             */
            if (nan_a || nan_b) begin

              comparison = 1'b0;
              nv         = 1'b1;

            end
            else begin

              comparison =
                  fp_lt(a, b) ||
                  fp_eq(a, b);

            end

          end
          else if (mode == 3'd1) begin

            /*
             * FLT is signalling.
             */
            if (nan_a || nan_b) begin

              comparison = 1'b0;
              nv         = 1'b1;

            end
            else begin

              comparison =
                  fp_lt(a, b);

            end

          end
          else begin

            /*
             * FEQ is quiet.
             */
            if (nan_a || nan_b) begin

              comparison = 1'b0;
              nv         =
                  snan_a ||
                  snan_b;

            end
            else begin

              comparison =
                  fp_eq(a, b);

            end

          end


          if (comparison)
            e.result = 32'h0000_0001;
          else
            e.result = 32'h0000_0000;

        end


        // --------------------------------------------------------------------
        // CLASSIFY
        // --------------------------------------------------------------------

        OP_CLASSIFY: begin

          /*
           * result_o is explicitly unconstrained for CLASSIFY.
           */
          e.check_result = 1'b0;
          e.check_class  = 1'b1;

          e.class_mask =
              fp_classify(a);

          nv =
              1'b0;

        end


        default: begin

          /*
           * Invalid op encodings are never driven.
           */
          e.check_result = 1'b0;
          e.check_class  = 1'b0;
          nv             = 1'b0;

        end

      endcase


      /*
       * {NV,DZ,OF,UF,NX}
       */
      e.status =
          {nv, 4'b0000};

      make_expected =
          e;
    end
  endfunction


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
  // Acceptance / output scoreboard
  // ==========================================================================

  always @(posedge clk) begin : scoreboard
    automatic exp_rec_t exp_item;

    if (!rst_n) begin

      /*
       * S15: all pre-reset accepted work is discarded.
       */
      exp_q.delete();

    end
    else begin

      /*
       * H1: create an expected result only on the actual input handshake.
       */
      if (
          in_valid_i &&
          in_ready_o
      ) begin

        exp_item =
            make_expected(
                operand_a_i,
                operand_b_i,
                op_i,
                op_mode_i
            );

        exp_q.push_back(
            exp_item
        );

        accepted_count =
            accepted_count + 1;

      end


      /*
       * H2: outputs must correspond one-for-one and in acceptance order.
       *
       * Input enqueue is deliberately processed first, so a legal zero-cycle
       * implementation can accept and deliver the same operation on one edge.
       */
      if (
          out_valid_o &&
          out_ready_i
      ) begin

        if (exp_q.size() == 0) begin

          fail_req(
              "H2",
              "result delivered with no accepted operation awaiting a result"
          );

        end
        else begin

          exp_item =
              exp_q.pop_front();

          if (
              exp_item.check_result &&
              (result_o !== exp_item.result)
          )
            fail_req(
                "H2",
                "result_o did not match the next accepted operation"
            );


          if (
              exp_item.check_class &&
              (class_mask_o !== exp_item.class_mask)
          )
            fail_req(
                "S12",
                "CLASSIFY one-hot mask was incorrect"
            );


          if (
              status_o !==
              exp_item.status
          )
            fail_req(
                "S14",
                "status_o did not match the per-operation exception flags"
            );


          delivered_count =
              delivered_count + 1;

        end

      end

    end
  end


  /*
   * Count actual backpressure stimulus.  The contract requires at least
   * twenty cycles with out_ready_i low.
   */
  always @(posedge clk) begin
    if (
        rst_n &&
        !out_ready_i
    )
      stall_cycle_count =
          stall_cycle_count + 1;
  end


  /*
   * Track sampled reset edges so reset-time checks are never made before the
   * synchronous reset has actually been clocked.
   */
  always @(posedge clk) begin
    if (!rst_n)
      reset_low_edges =
          reset_low_edges + 1;
    else
      reset_low_edges =
          0;
  end


  // ==========================================================================
  // Drain helper
  // ==========================================================================

  task automatic wait_for_all_results;
    integer n;
    bit done;

    begin
      done = 1'b0;

      for (n = 0; n < WAIT_LIMIT; n = n + 1) begin

        @(negedge clk);

        if (
            (exp_q.size() == 0) &&
            (accepted_count == delivered_count)
        ) begin

          done = 1'b1;
          break;

        end

      end


      if (!done)
        fail_req(
            "H2",
            "accepted operations did not all produce results"
        );


      /*
       * Leave several extra ready cycles to expose duplicated responses.
       */
      repeat (5)
        @(posedge clk);

    end
  endtask


  // ==========================================================================
  // Reset helper
  // ==========================================================================

  task automatic reset_and_check;
    integer n;

    begin
      /*
       * No source request is active while reset is entered.
       */
      @(negedge clk);

      in_valid_i  = 1'b0;
      out_ready_i = 1'b0;
      rst_n       = 1'b0;


      repeat (4)
        @(posedge clk);


      /*
       * Synchronous reset has now been sampled repeatedly.
       */
      @(negedge clk);

      if (out_valid_o)
        fail_req(
            "S15",
            "out_valid_o remained asserted after synchronous reset had been sampled"
        );


      rst_n =
          1'b1;


      /*
       * S15 explicitly requires out_valid_o low on the first cycle after
       * release.  Sample it after that clock edge, away from the edge race.
       */
      @(posedge clk);
      @(negedge clk);

      if (out_valid_o)
        fail_req(
            "S15",
            "out_valid_o was high on the first cycle after reset release"
        );


      out_ready_i =
          1'b1;


      /*
       * With no new operation offered, no stale pre-reset result may appear.
       */
      for (n = 0; n < 4; n = n + 1) begin

        @(posedge clk);
        @(negedge clk);

        if (out_valid_o)
          fail_req(
              "S15",
              "operation from before reset produced a result after reset"
          );

      end

    end
  endtask


  // ==========================================================================
  // Directed functional tests
  // ==========================================================================

  task automatic test_sgnj;
    begin

      // FSGNJ-style sign copy
      bfm_issue(
          32'h3F81_2345,
          32'hBF00_0000,
          OP_SGNJ,
          3'd0
      );

      // sign inversion
      bfm_issue(
          32'hBF81_2345,
          32'hBF00_0000,
          OP_SGNJ,
          3'd1
      );

      // sign XOR
      bfm_issue(
          32'hBF81_2345,
          32'hBF00_0000,
          OP_SGNJ,
          3'd2
      );

      /*
       * S1/S2: signalling-NaN payload must pass through unchanged except sign,
       * and NV must remain clear.
       */
      bfm_issue(
          32'h7F81_2345,
          32'h8000_0000,
          OP_SGNJ,
          3'd0
      );

      bfm_idle();
      wait_for_all_results();

    end
  endtask


  task automatic test_minmax;
    begin

      // ordinary min/max
      bfm_issue(
          32'hC000_0000,      // -2.0
          32'h3F80_0000,      // +1.0
          OP_MINMAX,
          3'd0
      );

      bfm_issue(
          32'hC000_0000,
          32'h3F80_0000,
          OP_MINMAX,
          3'd1
      );


      // S3: signed zero ordering
      bfm_issue(
          32'h0000_0000,
          32'h8000_0000,
          OP_MINMAX,
          3'd0
      );

      bfm_issue(
          32'h8000_0000,
          32'h0000_0000,
          OP_MINMAX,
          3'd1
      );


      // S4: one qNaN -> other operand, no NV
      bfm_issue(
          32'h7FC1_2345,
          32'h3F80_0000,
          OP_MINMAX,
          3'd0
      );


      // S4/S6: one sNaN -> other operand, NV
      bfm_issue(
          32'h7F81_2345,
          32'hC000_0000,
          OP_MINMAX,
          3'd1
      );


      // S5: both qNaNs -> exact canonical qNaN, no NV
      bfm_issue(
          32'h7FC1_1111,
          32'hFFC2_2222,
          OP_MINMAX,
          3'd0
      );


      // S5/S6: qNaN + sNaN -> canonical qNaN and NV
      bfm_issue(
          32'h7FC1_1111,
          32'h7F81_3333,
          OP_MINMAX,
          3'd1
      );


      // infinities
      bfm_issue(
          32'hFF80_0000,
          32'h7F80_0000,
          OP_MINMAX,
          3'd0
      );

      bfm_issue(
          32'hFF80_0000,
          32'h7F80_0000,
          OP_MINMAX,
          3'd1
      );


      bfm_idle();
      wait_for_all_results();

    end
  endtask


  task automatic test_cmp;
    begin

      // -2 <= +1 -> true
      bfm_issue(
          32'hC000_0000,
          32'h3F80_0000,
          OP_CMP,
          3'd0
      );


      // +1 < -2 -> false
      bfm_issue(
          32'h3F80_0000,
          32'hC000_0000,
          OP_CMP,
          3'd1
      );


      // equality
      bfm_issue(
          32'h3F80_0000,
          32'h3F80_0000,
          OP_CMP,
          3'd2
      );


      // S10: +0 == -0
      bfm_issue(
          32'h0000_0000,
          32'h8000_0000,
          OP_CMP,
          3'd2
      );


      // S10: neither zero is less
      bfm_issue(
          32'h8000_0000,
          32'h0000_0000,
          OP_CMP,
          3'd1
      );

      bfm_issue(
          32'h0000_0000,
          32'h8000_0000,
          OP_CMP,
          3'd1
      );


      // S8: FLE with qNaN -> false + NV
      bfm_issue(
          32'h7FC1_2345,
          32'h3F80_0000,
          OP_CMP,
          3'd0
      );


      // S8: FLT with qNaN -> false + NV
      bfm_issue(
          32'h7FC1_2345,
          32'h3F80_0000,
          OP_CMP,
          3'd1
      );


      // S9: FEQ with qNaN -> false, no NV
      bfm_issue(
          32'h7FC1_2345,
          32'h3F80_0000,
          OP_CMP,
          3'd2
      );


      // S9: FEQ with sNaN -> false + NV
      bfm_issue(
          32'h7F81_2345,
          32'h3F80_0000,
          OP_CMP,
          3'd2
      );


      // -infinity < finite
      bfm_issue(
          32'hFF80_0000,
          32'h0000_0000,
          OP_CMP,
          3'd1
      );


      // +infinity <= finite -> false
      bfm_issue(
          32'h7F80_0000,
          32'h3F80_0000,
          OP_CMP,
          3'd0
      );


      bfm_idle();
      wait_for_all_results();

    end
  endtask


  task automatic test_classify;
    begin

      // bit 0: -infinity
      bfm_issue(
          32'hFF80_0000,
          32'hDEAD_BEEF,
          OP_CLASSIFY,
          3'd0
      );

      // bit 1: -normal
      bfm_issue(
          32'hBF80_0000,
          32'h1234_5678,
          OP_CLASSIFY,
          3'd1
      );

      // bit 2: -subnormal
      bfm_issue(
          32'h8000_0001,
          32'hCAFE_BABE,
          OP_CLASSIFY,
          3'd2
      );

      // bit 3: -zero
      bfm_issue(
          32'h8000_0000,
          32'hFFFF_FFFF,
          OP_CLASSIFY,
          3'd3
      );

      // bit 4: +zero
      bfm_issue(
          32'h0000_0000,
          32'h0000_0001,
          OP_CLASSIFY,
          3'd4
      );

      // bit 5: +subnormal
      bfm_issue(
          32'h0000_0001,
          32'h8765_4321,
          OP_CLASSIFY,
          3'd5
      );

      // bit 6: +normal
      bfm_issue(
          32'h3F80_0000,
          32'h0000_0000,
          OP_CLASSIFY,
          3'd6
      );

      // bit 7: +infinity
      bfm_issue(
          32'h7F80_0000,
          32'h8000_0000,
          OP_CLASSIFY,
          3'd7
      );

      // bit 8: signalling NaN
      bfm_issue(
          32'h7F81_2345,
          32'h1111_1111,
          OP_CLASSIFY,
          3'd0
      );

      // bit 9: quiet NaN
      bfm_issue(
          32'hFFC1_2345,
          32'h2222_2222,
          OP_CLASSIFY,
          3'd7
      );


      bfm_idle();
      wait_for_all_results();

    end
  endtask


  // ==========================================================================
  // Backpressure stress
  // ==========================================================================

  task automatic test_backpressure;
    begin

      fork

        begin : issue_thread

          /*
           * Repeated and mixed results make value-based matching unsafe;
           * the FIFO acceptance scoreboard is what identifies each response.
           */
          bfm_issue(
              32'h3F80_0000,
              32'h4000_0000,
              OP_CMP,
              3'd1
          );

          bfm_issue(
              32'hBF80_0000,
              32'h0000_0000,
              OP_MINMAX,
              3'd0
          );

          bfm_issue(
              32'h7FC1_2345,
              32'h3F80_0000,
              OP_MINMAX,
              3'd1
          );

          bfm_issue(
              32'h7F81_2345,
              32'h0000_0000,
              OP_CLASSIFY,
              3'd4
          );

          bfm_issue(
              32'h3F12_3456,
              32'h8000_0000,
              OP_SGNJ,
              3'd0
          );

          bfm_issue(
              32'h0000_0000,
              32'h8000_0000,
              OP_CMP,
              3'd2
          );

          bfm_issue(
              32'hC000_0000,
              32'h3F80_0000,
              OP_MINMAX,
              3'd1
          );

          bfm_issue(
              32'h7FC0_0001,
              32'h0000_0000,
              OP_CMP,
              3'd2
          );

          bfm_issue(
              32'h0000_0001,
              32'hABCD_EF01,
              OP_CLASSIFY,
              3'd2
          );

          bfm_issue(
              32'hBF12_3456,
              32'h0000_0000,
              OP_SGNJ,
              3'd2
          );

          bfm_issue(
              32'hFF80_0000,
              32'h7F80_0000,
              OP_CMP,
              3'd1
          );

          bfm_issue(
              32'h7F81_0001,
              32'h3F80_0000,
              OP_MINMAX,
              3'd0
          );

          bfm_idle();

        end


        begin : stall_thread

          bfm_out_ready(
              1'b0
          );

          /*
           * H3's testbench floor requires at least 20 stalled cycles.
           */
          repeat (30)
            @(posedge clk);

          bfm_out_ready(
              1'b1
          );

        end

      join


      wait_for_all_results();


      if (stall_cycle_count < 20)
        fail_req(
            "H3",
            "testbench failed to apply the required minimum backpressure interval"
        );

    end
  endtask


  // ==========================================================================
  // Reset-discard test
  // ==========================================================================

  task automatic test_reset_discard;
    integer old_delivered;
    integer n;
    bit pending_before_reset;

    begin
      /*
       * Accept one operation normally.
       */
      out_ready_i =
          1'b1;

      old_delivered =
          delivered_count;

      bfm_issue(
          32'hC000_0000,
          32'h3F80_0000,
          OP_MINMAX,
          3'd0
      );


      /*
       * The input handshake has completed.  At the next safe edge stop new
       * source traffic and apply result backpressure.  If the result was not
       * zero-latency, it is now guaranteed to remain outstanding until reset.
       */
      @(negedge clk);

      in_valid_i =
          1'b0;

      out_ready_i =
          1'b0;

      if (exp_q.size() != 0)
        pending_before_reset = 1'b1;
      else
        pending_before_reset = 1'b0;


      /*
       * Assert synchronous reset before another result-side handshake.
       */
      rst_n =
          1'b0;


      repeat (4)
        @(posedge clk);


      @(negedge clk);

      if (out_valid_o)
        fail_req(
            "S15",
            "design did not return to idle while synchronous reset was active"
        );


      rst_n =
          1'b1;


      /*
       * First cycle after release must have out_valid low.
       */
      @(posedge clk);
      @(negedge clk);

      if (out_valid_o)
        fail_req(
            "S15",
            "out_valid_o was not low on the first cycle after reset release"
        );


      out_ready_i =
          1'b1;


      /*
       * No stale result may emerge after reset.  A zero-latency design may
       * already have completed the operation before reset; that is legal.
       */
      for (n = 0; n < 8; n = n + 1) begin

        @(posedge clk);
        @(negedge clk);

        if (
            pending_before_reset &&
            out_valid_o
        )
          fail_req(
              "S15",
              "pre-reset outstanding operation produced a result after reset"
          );

      end


      /*
       * Fresh post-reset work must still operate normally.
       */
      bfm_issue(
          32'h3F80_0000,
          32'h3F80_0000,
          OP_CMP,
          3'd2
      );

      bfm_idle();

      wait_for_all_results();

    end
  endtask


  // ==========================================================================
  // Main
  // ==========================================================================

  initial begin : main_test

    fail_count         = 0;
    accepted_count     = 0;
    delivered_count    = 0;
    stall_cycle_count  = 0;
    reset_low_edges    = 0;

    operand_a_i =
        32'h0;

    operand_b_i =
        32'h0;

    op_i =
        OP_SGNJ;

    op_mode_i =
        3'd0;

    in_valid_i =
        1'b0;

    out_ready_i =
        1'b1;


    // ------------------------------------------------------------------------
    // Initial synchronous reset
    // ------------------------------------------------------------------------

    reset_and_check();


    // ------------------------------------------------------------------------
    // S1/S2
    // ------------------------------------------------------------------------

    test_sgnj();


    // ------------------------------------------------------------------------
    // S3-S6
    // ------------------------------------------------------------------------

    test_minmax();


    // ------------------------------------------------------------------------
    // S7-S11
    // ------------------------------------------------------------------------

    test_cmp();


    // ------------------------------------------------------------------------
    // S12/S13
    // ------------------------------------------------------------------------

    test_classify();


    // ------------------------------------------------------------------------
    // H2/H3 under substantial result backpressure
    // ------------------------------------------------------------------------

    test_backpressure();


    // ------------------------------------------------------------------------
    // S15 reset/discard semantics
    // ------------------------------------------------------------------------

    test_reset_discard();


    /*
     * Every accepted non-reset operation must have exactly one response.
     */
    if (exp_q.size() != 0)
      fail_req(
          "H2",
          "expected-result queue was non-empty at end of test"
      );


    if (fail_count == 0)
      $display("RESULT: PASS");
    else
      $display("RESULT: FAIL");

    $finish;
  end


  // ==========================================================================
  // S16 unconditional watchdog
  // ==========================================================================

  initial begin
    #200_000_000;

    $display(
        "FAIL S16: watchdog expired before the testbench reached a verdict"
    );

    $display("RESULT: FAIL");

    $finish;
  end

endmodule