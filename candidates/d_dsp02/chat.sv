`timescale 1ns/1ps

module fp32_fma_ii1_tb;

  logic        clk;
  logic        rst_n;

  logic        in_valid;
  logic        in_ready;
  logic [31:0] a;
  logic [31:0] b;
  logic [31:0] c;
  logic [2:0]  rnd_mode;

  logic        out_valid;
  logic        out_ready;
  logic [31:0] result;
  logic        flag_invalid;
  logic        flag_overflow;
  logic        flag_underflow;
  logic        flag_inexact;

  int errors;

  typedef struct packed {
    logic [31:0] a;
    logic [31:0] b;
    logic [31:0] c;
    logic [2:0]  rm;

    logic [31:0] result;
    logic        invalid;
    logic        overflow;
    logic        underflow;
    logic        inexact;

    // Identifies the principal arithmetic requirement exercised.
    logic [3:0]  req;
  } vec_t;

  vec_t vectors[$];
  vec_t expected_q[$];

  localparam logic [3:0] REQ_A1 = 4'd1;
  localparam logic [3:0] REQ_A2 = 4'd2;
  localparam logic [3:0] REQ_A3 = 4'd3;
  localparam logic [3:0] REQ_A4 = 4'd4;
  localparam logic [3:0] REQ_A5 = 4'd5;
  localparam logic [3:0] REQ_A6 = 4'd6;

  fp32_fma_ii1 dut (
    .clk            (clk),
    .rst_n          (rst_n),

    .in_valid       (in_valid),
    .in_ready       (in_ready),
    .a              (a),
    .b              (b),
    .c              (c),
    .rnd_mode       (rnd_mode),

    .out_valid      (out_valid),
    .out_ready      (out_ready),
    .result         (result),
    .flag_invalid   (flag_invalid),
    .flag_overflow  (flag_overflow),
    .flag_underflow (flag_underflow),
    .flag_inexact   (flag_inexact)
  );

  // Only permitted # delay: clock generation.
  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end


  // --------------------------------------------------------------------------
  // Diagnostics
  // --------------------------------------------------------------------------

  task automatic fail_check(
    input string requirement,
    input string message
  );
    begin
      errors++;
      $display("FAIL %s: %s", requirement, message);
    end
  endtask


  function automatic string arithmetic_req(input logic [3:0] req);
    begin
      case (req)
        REQ_A1: arithmetic_req = "A1";
        REQ_A2: arithmetic_req = "A2";
        REQ_A3: arithmetic_req = "A3";
        REQ_A4: arithmetic_req = "A4";
        REQ_A5: arithmetic_req = "A5";
        REQ_A6: arithmetic_req = "A6";
        default: arithmetic_req = "A1";
      endcase
    end
  endfunction


  // --------------------------------------------------------------------------
  // Directed vector construction
  // --------------------------------------------------------------------------

  task automatic add_vec(
    input logic [31:0] va,
    input logic [31:0] vb,
    input logic [31:0] vc,
    input logic [2:0]  vrm,

    input logic [31:0] vresult,
    input logic        vinvalid,
    input logic        voverflow,
    input logic        vunderflow,
    input logic        vinexact,

    input logic [3:0]  vreq
  );
    vec_t v;
    begin
      v.a         = va;
      v.b         = vb;
      v.c         = vc;
      v.rm        = vrm;
      v.result    = vresult;
      v.invalid   = vinvalid;
      v.overflow  = voverflow;
      v.underflow = vunderflow;
      v.inexact   = vinexact;
      v.req       = vreq;

      vectors.push_back(v);
    end
  endtask


  task automatic build_vectors;
    begin
      vectors.delete();

      // ----------------------------------------------------------------------
      // A1: ordinary exact arithmetic.
      // ----------------------------------------------------------------------
      add_vec(
        32'h3f800000, 32'h3f800000, 32'h00000000, 3'd0,
        32'h3f800000, 0,0,0,0, REQ_A1
      );

      // 1.5 * 2.0 - 1.0 = 2.0 exactly.
      add_vec(
        32'h3fc00000, 32'h40000000, 32'hbf800000, 3'd0,
        32'h40000000, 0,0,0,0, REQ_A1
      );

      // ----------------------------------------------------------------------
      // A1: discriminating fused case from the specification.
      //
      // (1 + 2^-12)^2 - (1 + 2^-11) = exactly 2^-24.
      //
      // A multiply-then-add implementation which rounds the product first
      // produces zero instead.
      // ----------------------------------------------------------------------
      add_vec(
        32'h3f800800, 32'h3f800800, 32'hbf801000, 3'd0,
        32'h33800000, 0,0,0,0, REQ_A1
      );

      // ----------------------------------------------------------------------
      // A4: NaN canonicalization.
      // Quiet NaN alone does not raise invalid.
      // ----------------------------------------------------------------------
      add_vec(
        32'h7fc12345, 32'h3f800000, 32'h00000000, 3'd0,
        32'h7fc00000, 0,0,0,0, REQ_A4
      );

      // Signalling NaN raises invalid and canonicalizes.
      add_vec(
        32'h3f800000, 32'h7fa12345, 32'h00000000, 3'd0,
        32'h7fc00000, 1,0,0,0, REQ_A4
      );

      // ----------------------------------------------------------------------
      // A4/A5: invalid arithmetic operations.
      // ----------------------------------------------------------------------

      // 0 * Inf.
      add_vec(
        32'h00000000, 32'h7f800000, 32'h3f800000, 3'd0,
        32'h7fc00000, 1,0,0,0, REQ_A5
      );

      // +Inf + -Inf.
      add_vec(
        32'h7f800000, 32'h3f800000, 32'hff800000, 3'd0,
        32'h7fc00000, 1,0,0,0, REQ_A5
      );

      // Valid infinity results.
      add_vec(
        32'h7f800000, 32'h40000000, 32'h3f800000, 3'd0,
        32'h7f800000, 0,0,0,0, REQ_A5
      );

      add_vec(
        32'h3f800000, 32'h3f800000, 32'hff800000, 3'd0,
        32'hff800000, 0,0,0,0, REQ_A5
      );

      // ----------------------------------------------------------------------
      // A5: signed zero.
      //
      // (-0 * +1) + (+0)
      // is +0 except under RDN, where it is -0.
      // ----------------------------------------------------------------------
      add_vec(
        32'h80000000, 32'h3f800000, 32'h00000000, 3'd0,
        32'h00000000, 0,0,0,0, REQ_A5
      );
      add_vec(
        32'h80000000, 32'h3f800000, 32'h00000000, 3'd1,
        32'h00000000, 0,0,0,0, REQ_A5
      );
      add_vec(
        32'h80000000, 32'h3f800000, 32'h00000000, 3'd2,
        32'h80000000, 0,0,0,0, REQ_A5
      );
      add_vec(
        32'h80000000, 32'h3f800000, 32'h00000000, 3'd3,
        32'h00000000, 0,0,0,0, REQ_A5
      );
      add_vec(
        32'h80000000, 32'h3f800000, 32'h00000000, 3'd4,
        32'h00000000, 0,0,0,0, REQ_A5
      );

      // Same-sign negative zeros remain negative zero.
      add_vec(
        32'h80000000, 32'h3f800000, 32'h80000000, 3'd0,
        32'h80000000, 0,0,0,0, REQ_A5
      );

      // ----------------------------------------------------------------------
      // A3: exact subnormal operands/results.
      //
      // Smallest subnormal * 1.
      // Exact tiny results must NOT assert underflow.
      // ----------------------------------------------------------------------
      add_vec(
        32'h00000001, 32'h3f800000, 32'h00000000, 3'd0,
        32'h00000001, 0,0,0,0, REQ_A3
      );

      // min_sub + min_sub = 2*min_sub exactly.
      add_vec(
        32'h3f800000, 32'h00000001, 32'h00000001, 3'd0,
        32'h00000002, 0,0,0,0, REQ_A3
      );

      // ----------------------------------------------------------------------
      // A2/A3/A6/A7:
      // min_sub * 0.5 = 2^-150, exactly halfway between zero and min_sub.
      //
      // Result remains tiny after rounding, so underflow and inexact are set.
      // ----------------------------------------------------------------------

      // Positive halfway-to-minsub.
      add_vec(
        32'h00000001, 32'h3f000000, 32'h00000000, 3'd0,
        32'h00000000, 0,0,1,1, REQ_A3
      );
      add_vec(
        32'h00000001, 32'h3f000000, 32'h00000000, 3'd1,
        32'h00000000, 0,0,1,1, REQ_A3
      );
      add_vec(
        32'h00000001, 32'h3f000000, 32'h00000000, 3'd2,
        32'h00000000, 0,0,1,1, REQ_A3
      );
      add_vec(
        32'h00000001, 32'h3f000000, 32'h00000000, 3'd3,
        32'h00000001, 0,0,1,1, REQ_A3
      );
      add_vec(
        32'h00000001, 32'h3f000000, 32'h00000000, 3'd4,
        32'h00000001, 0,0,1,1, REQ_A3
      );

      // Negative halfway-to-minsub.
      add_vec(
        32'h80000001, 32'h3f000000, 32'h00000000, 3'd0,
        32'h80000000, 0,0,1,1, REQ_A3
      );
      add_vec(
        32'h80000001, 32'h3f000000, 32'h00000000, 3'd1,
        32'h80000000, 0,0,1,1, REQ_A3
      );
      add_vec(
        32'h80000001, 32'h3f000000, 32'h00000000, 3'd2,
        32'h80000001, 0,0,1,1, REQ_A3
      );
      add_vec(
        32'h80000001, 32'h3f000000, 32'h00000000, 3'd3,
        32'h80000000, 0,0,1,1, REQ_A3
      );
      add_vec(
        32'h80000001, 32'h3f000000, 32'h00000000, 3'd4,
        32'h80000001, 0,0,1,1, REQ_A3
      );

      // ----------------------------------------------------------------------
      // A6: after-rounding tininess detection.
      //
      // min_normal * largest float below 1.0
      //   = min_normal - 2^-150
      //
      // This is exactly halfway between largest subnormal and min normal.
      //
      // RNE/RUP/RMM round to min normal: inexact but NO underflow.
      // RTZ/RDN round to largest subnormal: underflow + inexact.
      // ----------------------------------------------------------------------
      add_vec(
        32'h00800000, 32'h3f7fffff, 32'h00000000, 3'd0,
        32'h00800000, 0,0,0,1, REQ_A6
      );
      add_vec(
        32'h00800000, 32'h3f7fffff, 32'h00000000, 3'd1,
        32'h007fffff, 0,0,1,1, REQ_A6
      );
      add_vec(
        32'h00800000, 32'h3f7fffff, 32'h00000000, 3'd2,
        32'h007fffff, 0,0,1,1, REQ_A6
      );
      add_vec(
        32'h00800000, 32'h3f7fffff, 32'h00000000, 3'd3,
        32'h00800000, 0,0,0,1, REQ_A6
      );
      add_vec(
        32'h00800000, 32'h3f7fffff, 32'h00000000, 3'd4,
        32'h00800000, 0,0,0,1, REQ_A6
      );

      // ----------------------------------------------------------------------
      // A2: rounding-mode discriminator.
      //
      // 1 + 2^-24 is exactly halfway between 1.0 and the next binary32.
      // ----------------------------------------------------------------------
      add_vec(
        32'h3f800000, 32'h3f800000, 32'h33800000, 3'd0,
        32'h3f800000, 0,0,0,1, REQ_A2
      );
      add_vec(
        32'h3f800000, 32'h3f800000, 32'h33800000, 3'd1,
        32'h3f800000, 0,0,0,1, REQ_A2
      );
      add_vec(
        32'h3f800000, 32'h3f800000, 32'h33800000, 3'd2,
        32'h3f800000, 0,0,0,1, REQ_A2
      );
      add_vec(
        32'h3f800000, 32'h3f800000, 32'h33800000, 3'd3,
        32'h3f800001, 0,0,0,1, REQ_A2
      );
      add_vec(
        32'h3f800000, 32'h3f800000, 32'h33800000, 3'd4,
        32'h3f800001, 0,0,0,1, REQ_A2
      );

      // Negative halfway case.
      add_vec(
        32'hbf800000, 32'h3f800000, 32'hb3800000, 3'd0,
        32'hbf800000, 0,0,0,1, REQ_A2
      );
      add_vec(
        32'hbf800000, 32'h3f800000, 32'hb3800000, 3'd1,
        32'hbf800000, 0,0,0,1, REQ_A2
      );
      add_vec(
        32'hbf800000, 32'h3f800000, 32'hb3800000, 3'd2,
        32'hbf800001, 0,0,0,1, REQ_A2
      );
      add_vec(
        32'hbf800000, 32'h3f800000, 32'hb3800000, 3'd3,
        32'hbf800000, 0,0,0,1, REQ_A2
      );
      add_vec(
        32'hbf800000, 32'h3f800000, 32'hb3800000, 3'd4,
        32'hbf800001, 0,0,0,1, REQ_A2
      );

      // ----------------------------------------------------------------------
      // A2/A4b/A7: positive overflow.
      //
      // Overflow MUST also set inexact.
      // ----------------------------------------------------------------------
      add_vec(
        32'h7f7fffff, 32'h40000000, 32'h00000000, 3'd0,
        32'h7f800000, 0,1,0,1, REQ_A2
      );
      add_vec(
        32'h7f7fffff, 32'h40000000, 32'h00000000, 3'd1,
        32'h7f7fffff, 0,1,0,1, REQ_A2
      );
      add_vec(
        32'h7f7fffff, 32'h40000000, 32'h00000000, 3'd2,
        32'h7f7fffff, 0,1,0,1, REQ_A2
      );
      add_vec(
        32'h7f7fffff, 32'h40000000, 32'h00000000, 3'd3,
        32'h7f800000, 0,1,0,1, REQ_A2
      );
      add_vec(
        32'h7f7fffff, 32'h40000000, 32'h00000000, 3'd4,
        32'h7f800000, 0,1,0,1, REQ_A2
      );

      // Negative overflow.
      add_vec(
        32'hff7fffff, 32'h40000000, 32'h00000000, 3'd0,
        32'hff800000, 0,1,0,1, REQ_A2
      );
      add_vec(
        32'hff7fffff, 32'h40000000, 32'h00000000, 3'd1,
        32'hff7fffff, 0,1,0,1, REQ_A2
      );
      add_vec(
        32'hff7fffff, 32'h40000000, 32'h00000000, 3'd2,
        32'hff800000, 0,1,0,1, REQ_A2
      );
      add_vec(
        32'hff7fffff, 32'h40000000, 32'h00000000, 3'd3,
        32'hff7fffff, 0,1,0,1, REQ_A2
      );
      add_vec(
        32'hff7fffff, 32'h40000000, 32'h00000000, 3'd4,
        32'hff800000, 0,1,0,1, REQ_A2
      );
    end
  endtask


  // --------------------------------------------------------------------------
  // Output comparison
  // --------------------------------------------------------------------------

  task automatic check_output(
    input vec_t exp,
    input int vector_number
  );
    string req_name;
    begin
      req_name = arithmetic_req(exp.req);

      if (result !== exp.result) begin
        fail_check(
          req_name,
          $sformatf(
            "vector %0d rm=%0d a=%08x b=%08x c=%08x: result=%08x expected=%08x",
            vector_number, exp.rm, exp.a, exp.b, exp.c,
            result, exp.result
          )
        );
      end

      // A7: all four flags are bit-exact on every completed result.
      if ({flag_invalid,
           flag_overflow,
           flag_underflow,
           flag_inexact}
          !==
          {exp.invalid,
           exp.overflow,
           exp.underflow,
           exp.inexact}) begin

        fail_check(
          "A7",
          $sformatf(
            "vector %0d rm=%0d a=%08x b=%08x c=%08x: flags=%0b%0b%0b%0b expected=%0b%0b%0b%0b",
            vector_number, exp.rm, exp.a, exp.b, exp.c,
            flag_invalid,
            flag_overflow,
            flag_underflow,
            flag_inexact,
            exp.invalid,
            exp.overflow,
            exp.underflow,
            exp.inexact
          )
        );
      end
    end
  endtask


  // --------------------------------------------------------------------------
  // Synchronous active-low reset.
  // --------------------------------------------------------------------------

  task automatic apply_reset;
    begin
      @(negedge clk);

      in_valid = 1'b0;
      out_ready = 1'b1;
      rst_n = 1'b0;

      expected_q.delete();

      // R1/R2: reset is synchronous; check only following active edges.
      @(posedge clk);
      if (out_valid !== 1'b0) begin
        fail_check(
          "R2",
          "out_valid was not zero on a clock edge while rst_n was low"
        );
      end

      @(posedge clk);
      if (out_valid !== 1'b0) begin
        fail_check(
          "R2",
          "out_valid was not zero while synchronous reset remained asserted"
        );
      end

      @(negedge clk);
      rst_n = 1'b1;
    end
  endtask


  // --------------------------------------------------------------------------
  // H3: output backpressure stability.
  //
  // Acceptance while out_ready=0 is not required by the specification.
  // Therefore this test only performs the H3 check if the DUT voluntarily
  // accepts the operation during the short opportunity window.
  // --------------------------------------------------------------------------

  task automatic test_backpressure;
    vec_t v;
    logic accepted;

    logic [31:0] held_result;
    logic held_invalid;
    logic held_overflow;
    logic held_underflow;
    logic held_inexact;

    begin
      v.a         = 32'h3fc00000;
      v.b         = 32'h40000000;
      v.c         = 32'hbf800000;
      v.rm        = 3'd0;
      v.result    = 32'h40000000;
      v.invalid   = 1'b0;
      v.overflow  = 1'b0;
      v.underflow = 1'b0;
      v.inexact   = 1'b0;
      v.req       = REQ_A1;

      accepted = 1'b0;

      @(negedge clk);
      out_ready = 1'b0;
      in_valid  = 1'b1;
      a         = v.a;
      b         = v.b;
      c         = v.c;
      rnd_mode  = v.rm;

      // There is no contractual requirement that input remain ready while
      // the output is blocked, so lack of acceptance here is not a failure.
      for (int n = 0; n < 4; n++) begin
        @(posedge clk);
        if (in_ready === 1'b1) begin
          accepted = 1'b1;
          break;
        end
      end

      @(negedge clk);
      in_valid = 1'b0;

      if (accepted) begin
        // Latency is completely unconstrained.
        while (out_valid !== 1'b1)
          @(posedge clk);

        held_result    = result;
        held_invalid   = flag_invalid;
        held_overflow  = flag_overflow;
        held_underflow = flag_underflow;
        held_inexact   = flag_inexact;

        check_output(v, -1);

        // H3: with ready low, valid and all payload bits must remain stable.
        repeat (3) begin
          @(posedge clk);

          if (out_valid !== 1'b1) begin
            fail_check(
              "H3",
              "out_valid dropped while out_ready was low"
            );
          end

          if ({result,
               flag_invalid,
               flag_overflow,
               flag_underflow,
               flag_inexact}
              !==
              {held_result,
               held_invalid,
               held_overflow,
               held_underflow,
               held_inexact}) begin

            fail_check(
              "H3",
              "result or exception flags changed while output was stalled"
            );
          end
        end

        @(negedge clk);
        out_ready = 1'b1;

        // The held item is consumed at the next active edge.
        @(posedge clk);
      end
      else begin
        @(negedge clk);
        out_ready = 1'b1;
      end
    end
  endtask


  // --------------------------------------------------------------------------
  // C3 + H2 + H4 + arithmetic:
  //
  // Feed the complete directed vector list continuously.
  //
  // With out_ready=1 and an operation continuously offered, C3 requires
  // in_ready on EVERY cycle. If a faulty DUT lowers ready, the producer still
  // honours H2 by holding the same operands until they are accepted.
  //
  // The expected queue is populated ONLY on actual input handshakes.
  // Results are checked ONLY on actual output handshakes.
  //
  // No input-to-output latency is assumed.
  // --------------------------------------------------------------------------

  task automatic run_vector_stream;
    int input_index;
    int output_index;

    logic input_fire;
    logic output_fire;
    logic same_cycle_consumed;

    vec_t current;
    vec_t exp;

    begin
      expected_q.delete();

      input_index  = 0;
      output_index = 0;

      @(negedge clk);
      out_ready = 1'b1;

      while (input_index < vectors.size()) begin
        current = vectors[input_index];

        in_valid = 1'b1;
        a         = current.a;
        b         = current.b;
        c         = current.c;
        rnd_mode  = current.rm;

        @(posedge clk);

        input_fire  = (in_valid  === 1'b1) &&
                      (in_ready  === 1'b1);

        output_fire = (out_valid === 1'b1) &&
                      (out_ready === 1'b1);

        same_cycle_consumed = 1'b0;

        // C3:
        // During this phase operands are offered continuously and results are
        // always accepted. Therefore EVERY cycle must accept the input.
        if (in_ready !== 1'b1) begin
          fail_check(
            "C3",
            $sformatf(
              "in_ready=%0b while continuous input was offered and out_ready=1 at vector %0d",
              in_ready, input_index
            )
          );
        end

        // Process a result returning on this edge.
        if (output_fire) begin
          if (expected_q.size() != 0) begin
            exp = expected_q.pop_front();
            check_output(exp, output_index);
            output_index++;
          end
          else if (input_fire) begin
            // Zero-cycle latency is not prohibited. If the expected queue is
            // empty and this edge both accepts an input and returns a result,
            // that result can correspond to the just-accepted operation.
            check_output(current, output_index);
            output_index++;
            same_cycle_consumed = 1'b1;
          end
          else begin
            // With no accepted operation outstanding, a result is impossible.
            // Immediately after reset this would also violate R3.
            fail_check(
              "H4",
              "output completed with no accepted operation outstanding"
            );
          end
        end

        if (input_fire) begin
          if (!same_cycle_consumed)
            expected_q.push_back(current);

          input_index++;
        end

        // If a faulty implementation stalls, H2 requires the producer to keep
        // this same vector asserted. Hence only advance after a real handshake.
        @(negedge clk);
      end

      in_valid = 1'b0;

      // Drain all accepted work. Latency is intentionally unconstrained:
      // there is no cycle timeout here.
      while (expected_q.size() != 0) begin
        @(posedge clk);

        if ((out_valid === 1'b1) &&
            (out_ready === 1'b1)) begin

          exp = expected_q.pop_front();
          check_output(exp, output_index);
          output_index++;
        end
      end

      // A few observation cycles can catch duplicate/spurious results without
      // imposing any latency requirement on a legitimate outstanding result:
      // the queue is empty only because all accepted work has already returned.
      repeat (3) begin
        @(posedge clk);

        if (out_valid === 1'b1) begin
          fail_check(
            "H4",
            "extra output appeared after all accepted operations had completed"
          );
        end
      end
    end
  endtask


  // --------------------------------------------------------------------------
  // R3: reset discards work in flight.
  //
  // We create an operation and then reset. The operation may already have
  // completed in a zero/short-latency implementation; that is legal. What is
  // checked is that no pre-reset result is observed after the reset edge.
  // --------------------------------------------------------------------------

  task automatic test_reset_discard;
    begin
      @(negedge clk);

      out_ready = 1'b1;
      in_valid  = 1'b1;
      a         = 32'h41200000; // 10.0
      b         = 32'h40000000; // 2.0
      c         = 32'h3f800000; // 1.0
      rnd_mode  = 3'd0;

      // Under C3 conditions this must be accepted on this edge.
      @(posedge clk);

      if (in_ready !== 1'b1) begin
        fail_check(
          "C3",
          "input was not accepted during reset-discard setup with out_ready=1"
        );
      end

      @(negedge clk);
      in_valid = 1'b0;
      rst_n    = 1'b0;

      // R1/R2: synchronous reset takes effect at this edge.
      @(posedge clk);

      if (out_valid !== 1'b0) begin
        fail_check(
          "R2",
          "out_valid was asserted on active synchronous reset edge"
        );
      end

      @(negedge clk);
      rst_n = 1'b1;

      // R3 says work from before reset can never appear afterwards.
      // Observe an idle interval before introducing new work.
      repeat (4) begin
        @(posedge clk);

        if (out_valid === 1'b1) begin
          fail_check(
            "R3",
            "a pre-reset operation produced an output after reset"
          );
        end
      end
    end
  endtask


  // --------------------------------------------------------------------------
  // Main
  // --------------------------------------------------------------------------

  initial begin
    errors = 0;

    rst_n     = 1'b0;

    in_valid  = 1'b0;
    a         = 32'h00000000;
    b         = 32'h00000000;
    c         = 32'h00000000;
    rnd_mode  = 3'd0;

    out_ready = 1'b1;

    build_vectors();

    // Initial synchronous reset.
    @(posedge clk);

    if (out_valid !== 1'b0) begin
      fail_check(
        "R2",
        "out_valid was not zero during initial reset"
      );
    end

    @(posedge clk);

    if (out_valid !== 1'b0) begin
      fail_check(
        "R2",
        "out_valid was not zero while initial reset remained asserted"
      );
    end

    @(negedge clk);
    rst_n = 1'b1;

    // Exercise stable-output behavior independently of the main arithmetic
    // stream. If the design does not accept while backpressured, no acceptance
    // behavior is assumed or checked.
    test_backpressure();

    // Cleanly remove any state from the optional backpressure experiment.
    apply_reset();

    // Explicitly test cancellation of in-flight work.
    test_reset_discard();

    // Reset again so the arithmetic/C3 stream begins from a known state.
    apply_reset();

    // Continuous, II=1 arithmetic stream.
    run_vector_stream();

    if (errors == 0)
      $display("RESULT: PASS");
    else
      $display("RESULT: FAIL");

    $finish;
  end

endmodule