module fp16_gemm_array #(
  parameter int unsigned HEIGHT = 8,
  parameter int unsigned WIDTH  = 8
) (
  input  logic                                     clk_i,
  input  logic                                     rst_ni,
  input  logic [WIDTH-1:0][HEIGHT-1:0][15:0]       x_i,
  input  logic            [HEIGHT-1:0][15:0]       w_i,
  input  logic [WIDTH-1:0]            [15:0]       y_i,
  output logic [WIDTH-1:0]            [15:0]       z_o,
  input  logic [2:0]                               rnd_i,
  input  logic                                     accumulate_i,
  input  logic [WIDTH-1:0]                         row_clk_gate_en_i,
  input  logic                                     reg_enable_i,
  input  logic                                     flush_i,
  output logic [WIDTH-1:0][HEIGHT-1:0][4:0]        status_o
);

  /*
   * Four registered ticks separate adjacent FMA stages.
   *
   * The final stage also owns four registers.  With cycle indexing:
   *
   *   pipe[0] at tick t = operation sampled at t
   *   pipe[1]           = operation sampled at t-1
   *   pipe[2]           = operation sampled at t-2
   *   pipe[3]           = operation sampled at t-3
   *
   * Thus z_o observes the final-stage operation three enabled ticks
   * after that operation samples its operands.
   *
   * A following FMA samples pipe[3] on the NEXT edge, giving the
   * required four-enabled-tick stage-to-stage spacing.
   */
  localparam int unsigned STAGE_DELAY  = 4;
  localparam int unsigned STATUS_DELAY = 3;

  localparam logic [15:0] FP16_QNAN = 16'h7e00;


  /*
   * stage_pipe_q[row][stage][delay]
   */
  logic [15:0] stage_pipe_q
      [0:WIDTH-1][0:HEIGHT-1][0:STAGE_DELAY-1];

  /*
   * Three registers give:
   *
   *   status(t) = raw_status(t-2)
   */
  logic [4:0] status_pipe_q
      [0:WIDTH-1][0:HEIGHT-1][0:STATUS_DELAY-1];

  /*
   * { status[4:0], result[15:0] }
   */
  logic [20:0] fma_comb
      [0:WIDTH-1][0:HEIGHT-1];

  integer r_idx;
  integer k_idx;
  integer d_idx;


  /*
   * --------------------------------------------------------------------------
   * Small priority encoder.
   * --------------------------------------------------------------------------
   *
   * Explicit logic is used instead of a wide loop so slang does not have to
   * unroll a leading-one search once for every row/stage FMA.
   */
  function automatic integer msb16(
    input logic [15:0] v
  );
    begin
      if      (v[15]) msb16 = 15;
      else if (v[14]) msb16 = 14;
      else if (v[13]) msb16 = 13;
      else if (v[12]) msb16 = 12;
      else if (v[11]) msb16 = 11;
      else if (v[10]) msb16 = 10;
      else if (v[9])  msb16 = 9;
      else if (v[8])  msb16 = 8;
      else if (v[7])  msb16 = 7;
      else if (v[6])  msb16 = 6;
      else if (v[5])  msb16 = 5;
      else if (v[4])  msb16 = 4;
      else if (v[3])  msb16 = 3;
      else if (v[2])  msb16 = 2;
      else if (v[1])  msb16 = 1;
      else             msb16 = 0;
    end
  endfunction


  function automatic integer msb80(
    input logic [79:0] v
  );
    begin
      if (|v[79:64])
        msb80 = 64 + msb16(v[79:64]);
      else if (|v[63:48])
        msb80 = 48 + msb16(v[63:48]);
      else if (|v[47:32])
        msb80 = 32 + msb16(v[47:32]);
      else if (|v[31:16])
        msb80 = 16 + msb16(v[31:16]);
      else
        msb80 = msb16(v[15:0]);
    end
  endfunction


  /*
   * --------------------------------------------------------------------------
   * Overflow result table from A5.
   * --------------------------------------------------------------------------
   */
  function automatic logic [15:0] fp16_overflow_value(
    input logic       sign,
    input logic [2:0] rnd
  );
    logic to_inf;

    begin
      to_inf = 1'b0;

      case (rnd)

        /*
         * RNE
         */
        3'd0:
          to_inf = 1'b1;

        /*
         * RTZ
         */
        3'd1:
          to_inf = 1'b0;

        /*
         * RDN
         *
         * + overflow -> +65504
         * - overflow -> -inf
         */
        3'd2:
          to_inf = sign;

        /*
         * RUP
         *
         * + overflow -> +inf
         * - overflow -> -65504
         */
        3'd3:
          to_inf = !sign;

        /*
         * RMM
         */
        3'd4:
          to_inf = 1'b1;

        default:
          to_inf = 1'b1;

      endcase

      if (to_inf)
        fp16_overflow_value = {
          sign,
          5'h1f,
          10'h000
        };
      else
        fp16_overflow_value = {
          sign,
          5'h1e,
          10'h3ff
        };
    end
  endfunction


  /*
   * --------------------------------------------------------------------------
   * One exact FP16 fused multiply-add.
   * --------------------------------------------------------------------------
   *
   * Finite binary16 is represented as:
   *
   *     sign * mantissa_integer * 2^pow
   *
   * normal:
   *     mantissa = 1024 + fraction
   *     pow      = exponent_field - 25
   *
   * subnormal:
   *     mantissa = fraction
   *     pow      = -24
   *
   * Every finite FP16 product can therefore be represented exactly on a
   * common 2^-48 integer grid:
   *
   *     product = integer * 2^-48
   *
   * The addend also lands exactly on that same grid.  We add those exact
   * integers first and perform only ONE FP16 rounding afterwards.
   *
   * Return:
   *
   *     [20:16] = {NV,DZ,OF,UF,NX}
   *     [15:0]  = binary16 result
   */
  function automatic logic [20:0] fp16_fma(
    input logic [15:0] a,
    input logic [15:0] b,
    input logic [15:0] c,
    input logic [2:0]  rnd
  );

    logic sign_a;
    logic sign_b;
    logic sign_c;
    logic sign_p;
    logic sign_r;

    logic [4:0] exp_a;
    logic [4:0] exp_b;
    logic [4:0] exp_c;

    logic [9:0] frac_a;
    logic [9:0] frac_b;
    logic [9:0] frac_c;

    logic a_nan;
    logic b_nan;
    logic c_nan;

    logic a_inf;
    logic b_inf;
    logic c_inf;

    logic a_zero;
    logic b_zero;
    logic c_zero;

    logic [10:0] mant_a;
    logic [10:0] mant_b;
    logic [10:0] mant_c;

    integer pow_a;
    integer pow_b;
    integer pow_c;

    integer prod_shift;
    integer c_shift;

    logic [21:0] prod_mant;

    logic [79:0] prod_mag;
    logic [79:0] c_mag;
    logic [79:0] magnitude;

    logic signed [80:0] prod_term;
    logic signed [80:0] c_term;
    logic signed [80:0] exact_sum;

    logic [79:0] trunc_mag;
    logic [79:0] remainder;
    logic [79:0] half_ulp;

    /*
     * 65520 * 2^48.
     *
     * 65520 is the binary16 RNE overflow boundary immediately above
     * the largest finite value 65504.
     */
    logic [79:0] overflow_threshold;

    logic [11:0] rounded_sig;

    logic rem_nonzero;
    logic round_increment;

    integer leading_bit;
    integer shift_amt;
    integer unbiased_exp;

    logic [4:0] out_exp;

    logic [15:0] result;
    logic [4:0]  flags;

    begin

      /*
       * Defaults.
       */
      result = 16'h0000;
      flags  = 5'b00000;

      sign_a = a[15];
      sign_b = b[15];
      sign_c = c[15];

      sign_p = sign_a ^ sign_b;
      sign_r = 1'b0;

      exp_a = a[14:10];
      exp_b = b[14:10];
      exp_c = c[14:10];

      frac_a = a[9:0];
      frac_b = b[9:0];
      frac_c = c[9:0];

      a_nan = (exp_a == 5'h1f) && (frac_a != 10'b0);
      b_nan = (exp_b == 5'h1f) && (frac_b != 10'b0);
      c_nan = (exp_c == 5'h1f) && (frac_c != 10'b0);

      a_inf = (exp_a == 5'h1f) && (frac_a == 10'b0);
      b_inf = (exp_b == 5'h1f) && (frac_b == 10'b0);
      c_inf = (exp_c == 5'h1f) && (frac_c == 10'b0);

      a_zero = (exp_a == 5'b0) && (frac_a == 10'b0);
      b_zero = (exp_b == 5'b0) && (frac_b == 10'b0);
      c_zero = (exp_c == 5'b0) && (frac_c == 10'b0);

      /*
       * Decode finite significands and powers.
       */
      if (exp_a == 5'b0) begin
        mant_a = {1'b0, frac_a};
        pow_a  = -24;
      end
      else begin
        mant_a = {1'b1, frac_a};
        pow_a  = exp_a;
        pow_a  = pow_a - 25;
      end

      if (exp_b == 5'b0) begin
        mant_b = {1'b0, frac_b};
        pow_b  = -24;
      end
      else begin
        mant_b = {1'b1, frac_b};
        pow_b  = exp_b;
        pow_b  = pow_b - 25;
      end

      if (exp_c == 5'b0) begin
        mant_c = {1'b0, frac_c};
        pow_c  = -24;
      end
      else begin
        mant_c = {1'b1, frac_c};
        pow_c  = exp_c;
        pow_c  = pow_c - 25;
      end

      prod_shift = pow_a + pow_b + 48;
      c_shift    = pow_c + 48;

      prod_mant =
          {{11{1'b0}}, mant_a} *
          {{11{1'b0}}, mant_b};

      prod_mag = {{58{1'b0}}, prod_mant};
      c_mag    = {{69{1'b0}}, mant_c};

      prod_mag = prod_mag << prod_shift;
      c_mag    = c_mag << c_shift;

      prod_term = $signed({1'b0, prod_mag});
      c_term    = $signed({1'b0, c_mag});

      if (sign_p)
        prod_term = -prod_term;

      if (sign_c)
        c_term = -c_term;

      exact_sum = prod_term + c_term;

      overflow_threshold = 80'b0;
      overflow_threshold[63:48] = 16'hfff0;

      trunc_mag       = 80'b0;
      remainder       = 80'b0;
      half_ulp        = 80'b0;
      rounded_sig     = 12'b0;
      rem_nonzero     = 1'b0;
      round_increment = 1'b0;
      leading_bit     = 0;
      shift_amt       = 0;
      unbiased_exp    = 0;
      out_exp         = 5'b0;


      /*
       * ----------------------------------------------------------------------
       * NaN propagation.
       * ----------------------------------------------------------------------
       *
       * The contract's quiet-NaN case delivers the canonical qNaN and raises
       * no exception.
       */
      if (a_nan || b_nan || c_nan) begin

        result = FP16_QNAN;

      end


      /*
       * ----------------------------------------------------------------------
       * infinity * zero
       * ----------------------------------------------------------------------
       */
      else if (
          (a_inf && b_zero) ||
          (b_inf && a_zero)
      ) begin

        result   = FP16_QNAN;
        flags[4] = 1'b1;

      end


      /*
       * ----------------------------------------------------------------------
       * Infinite product.
       * ----------------------------------------------------------------------
       */
      else if (a_inf || b_inf) begin

        /*
         * +inf + -inf is invalid.
         */
        if (c_inf && (sign_c != sign_p)) begin

          result   = FP16_QNAN;
          flags[4] = 1'b1;

        end
        else begin

          result = {
            sign_p,
            5'h1f,
            10'h000
          };

        end

      end


      /*
       * ----------------------------------------------------------------------
       * Finite product plus infinite c.
       * ----------------------------------------------------------------------
       */
      else if (c_inf) begin

        result = {
          sign_c,
          5'h1f,
          10'h000
        };

      end


      /*
       * ----------------------------------------------------------------------
       * Exact finite zero.
       * ----------------------------------------------------------------------
       */
      else if (exact_sum == 81'sd0) begin

        /*
         * Same-sign zeros preserve their sign.
         *
         * Opposite-sign zeros and exact cancellation are +0 except under
         * roundTowardNegative, where they are -0.
         */
        if (
            (prod_mag == 80'b0) &&
            (c_mag == 80'b0) &&
            (sign_p == sign_c)
        )
          sign_r = sign_p;
        else if (rnd == 3'd2)
          sign_r = 1'b1;
        else
          sign_r = 1'b0;

        result = {
          sign_r,
          15'b0
        };

      end


      /*
       * ----------------------------------------------------------------------
       * Finite nonzero exact result.
       * ----------------------------------------------------------------------
       */
      else begin

        sign_r = exact_sum[80];

        if (sign_r)
          magnitude =
              (~exact_sum[79:0]) +
              80'd1;
        else
          magnitude =
              exact_sum[79:0];


        /*
         * --------------------------------------------------------------------
         * Explicit A5 range boundary.
         * --------------------------------------------------------------------
         */
        if (magnitude >= overflow_threshold) begin

          result = fp16_overflow_value(
            sign_r,
            rnd
          );

          flags[2] = 1'b1;  // OF
          flags[0] = 1'b1;  // NX

        end
        else begin

          leading_bit = msb80(magnitude);


          /*
           * ------------------------------------------------------------------
           * Subnormal range.
           * ------------------------------------------------------------------
           *
           * Since the exact integer grid is 2^-48 and a binary16 subnormal
           * quantum is 2^-24, rounding to the subnormal grid means dropping
           * exactly 24 low bits.
           */
          if (leading_bit < 34) begin

            shift_amt = 24;

            trunc_mag =
                magnitude >>
                shift_amt;

            remainder =
                magnitude -
                (trunc_mag << shift_amt);

            half_ulp = 80'd1 << (shift_amt - 1);

            rounded_sig =
                trunc_mag[11:0];

            rem_nonzero =
                (remainder != 80'b0);

            round_increment = 1'b0;

            if (rem_nonzero) begin

              case (rnd)

                /*
                 * RNE
                 */
                3'd0:
                  round_increment =
                      (remainder > half_ulp) ||
                      (
                        (remainder == half_ulp) &&
                        rounded_sig[0]
                      );

                /*
                 * RTZ
                 */
                3'd1:
                  round_increment = 1'b0;

                /*
                 * RDN
                 */
                3'd2:
                  round_increment = sign_r;

                /*
                 * RUP
                 */
                3'd3:
                  round_increment = !sign_r;

                /*
                 * RMM
                 */
                3'd4:
                  round_increment =
                      (remainder >= half_ulp);

                default:
                  round_increment =
                      (remainder > half_ulp) ||
                      (
                        (remainder == half_ulp) &&
                        rounded_sig[0]
                      );

              endcase

            end

            if (round_increment)
              rounded_sig =
                  rounded_sig +
                  12'd1;


            /*
             * Rounding the largest subnormal can create the minimum normal.
             */
            if (rounded_sig >= 12'd1024) begin

              result = {
                sign_r,
                5'd1,
                10'h000
              };

            end
            else begin

              result = {
                sign_r,
                5'd0,
                rounded_sig[9:0]
              };

            end


            /*
             * A7:
             *
             * exact subnormal => no UF and no NX.
             *
             * tiny + inexact => both UF and NX.
             */
            if (rem_nonzero) begin
              flags[1] = 1'b1;
              flags[0] = 1'b1;
            end

          end


          /*
           * ------------------------------------------------------------------
           * Normal range.
           * ------------------------------------------------------------------
           */
          else begin

            unbiased_exp =
                leading_bit - 48;

            /*
             * Retain hidden bit + ten fraction bits.
             */
            shift_amt =
                leading_bit - 10;

            trunc_mag =
                magnitude >>
                shift_amt;

            remainder =
                magnitude -
                (trunc_mag << shift_amt);

            half_ulp =
                80'd1 <<
                (shift_amt - 1);

            rounded_sig =
                trunc_mag[11:0];

            rem_nonzero =
                (remainder != 80'b0);

            round_increment = 1'b0;

            if (rem_nonzero) begin

              case (rnd)

                /*
                 * RNE
                 */
                3'd0:
                  round_increment =
                      (remainder > half_ulp) ||
                      (
                        (remainder == half_ulp) &&
                        rounded_sig[0]
                      );

                /*
                 * RTZ
                 */
                3'd1:
                  round_increment = 1'b0;

                /*
                 * RDN
                 */
                3'd2:
                  round_increment = sign_r;

                /*
                 * RUP
                 */
                3'd3:
                  round_increment = !sign_r;

                /*
                 * RMM
                 */
                3'd4:
                  round_increment =
                      (remainder >= half_ulp);

                default:
                  round_increment =
                      (remainder > half_ulp) ||
                      (
                        (remainder == half_ulp) &&
                        rounded_sig[0]
                      );

              endcase

            end


            if (round_increment)
              rounded_sig =
                  rounded_sig +
                  12'd1;


            /*
             * Significand rounding carried into the next exponent.
             */
            if (rounded_sig >= 12'd2048) begin

              rounded_sig =
                  rounded_sig >> 1;

              unbiased_exp =
                  unbiased_exp + 1;

            end


            /*
             * Directed rounding can cross into overflow below the fixed
             * RNE threshold.
             */
            if (unbiased_exp > 15) begin

              result =
                  fp16_overflow_value(
                    sign_r,
                    rnd
                  );

              flags[2] = 1'b1;
              flags[0] = 1'b1;

            end
            else begin

              out_exp =
                  unbiased_exp + 15;

              result = {
                sign_r,
                out_exp,
                rounded_sig[9:0]
              };

              if (rem_nonzero)
                flags[0] = 1'b1;

            end

          end

        end

      end


      /*
       * DZ is always zero.
       */
      flags[3] = 1'b0;

      fp16_fma = {
        flags,
        result
      };

    end
  endfunction


  /*
   * --------------------------------------------------------------------------
   * Combinational FMA network.
   * --------------------------------------------------------------------------
   *
   * Stage zero is seeded from either:
   *
   *   y_i[row]
   *
   * or the row's current registered z value.
   *
   * Because stage-zero samples the PRE-EDGE value of the output register,
   * accumulated feedback is one enabled tick older than stage-zero's current
   * operands. Combined with d(0), this gives:
   *
   *   dfb = d(0) + 1
   *
   * exactly as required.
   */
  genvar gr;
  genvar gk;

  generate

    for (gr = 0; gr < WIDTH; gr = gr + 1) begin : GEN_ROW

      assign z_o[gr] =
          stage_pipe_q[gr][HEIGHT-1][STAGE_DELAY-1];

      for (
          gk = 0;
          gk < HEIGHT;
          gk = gk + 1
      ) begin : GEN_STAGE

        assign status_o[gr][gk] =
            status_pipe_q[gr][gk][STATUS_DELAY-1];

        if (gk == 0) begin : GEN_FIRST_STAGE

          assign fma_comb[gr][gk] =
              fp16_fma(
                x_i[gr][gk],
                w_i[gk],
                accumulate_i
                  ? stage_pipe_q
                      [gr]
                      [HEIGHT-1]
                      [STAGE_DELAY-1]
                  : y_i[gr],
                rnd_i
              );

        end
        else begin : GEN_LATER_STAGE

          assign fma_comb[gr][gk] =
              fp16_fma(
                x_i[gr][gk],
                w_i[gk],
                stage_pipe_q
                    [gr]
                    [gk-1]
                    [STAGE_DELAY-1],
                rnd_i
              );

        end

      end

    end

  endgenerate


  /*
   * --------------------------------------------------------------------------
   * Pipeline/register state.
   * --------------------------------------------------------------------------
   *
   * Reset:
   *   asynchronous and active-low, clearing z and status.
   *
   * Row gate:
   *   if low, EVERYTHING belonging to that row holds.
   *
   * flush:
   *   acts only when the row clock gate is enabled;
   *   clears the data/partial-sum pipeline;
   *   outranks reg_enable_i;
   *   DOES NOT clear or otherwise alter the status pipeline.
   *
   * reg_enable:
   *   advances both arithmetic and status pipelines when high.
   */
  always_ff @(posedge clk_i or negedge rst_ni) begin

    if (!rst_ni) begin

      for (
          r_idx = 0;
          r_idx < WIDTH;
          r_idx = r_idx + 1
      ) begin

        for (
            k_idx = 0;
            k_idx < HEIGHT;
            k_idx = k_idx + 1
        ) begin

          for (
              d_idx = 0;
              d_idx < STAGE_DELAY;
              d_idx = d_idx + 1
          ) begin

            stage_pipe_q
                [r_idx]
                [k_idx]
                [d_idx]
                <= 16'h0000;

          end

          for (
              d_idx = 0;
              d_idx < STATUS_DELAY;
              d_idx = d_idx + 1
          ) begin

            status_pipe_q
                [r_idx]
                [k_idx]
                [d_idx]
                <= 5'b00000;

          end

        end

      end

    end
    else begin

      for (
          r_idx = 0;
          r_idx < WIDTH;
          r_idx = r_idx + 1
      ) begin

        /*
         * Entire row freezes when its clock gate is disabled.
         */
        if (row_clk_gate_en_i[r_idx]) begin

          /*
           * --------------------------------------------------------------
           * Arithmetic state.
           * --------------------------------------------------------------
           *
           * flush has priority over reg_enable.
           */
          if (flush_i) begin

            for (
                k_idx = 0;
                k_idx < HEIGHT;
                k_idx = k_idx + 1
            ) begin

              for (
                  d_idx = 0;
                  d_idx < STAGE_DELAY;
                  d_idx = d_idx + 1
              ) begin

                stage_pipe_q
                    [r_idx]
                    [k_idx]
                    [d_idx]
                    <= 16'h0000;

              end

            end

          end
          else if (reg_enable_i) begin

            for (
                k_idx = 0;
                k_idx < HEIGHT;
                k_idx = k_idx + 1
            ) begin

              stage_pipe_q
                  [r_idx]
                  [k_idx]
                  [0]
                  <= fma_comb
                      [r_idx]
                      [k_idx]
                      [15:0];

              for (
                  d_idx = 1;
                  d_idx < STAGE_DELAY;
                  d_idx = d_idx + 1
              ) begin

                stage_pipe_q
                    [r_idx]
                    [k_idx]
                    [d_idx]
                    <=
                stage_pipe_q
                    [r_idx]
                    [k_idx]
                    [d_idx-1];

              end

            end

          end


          /*
           * --------------------------------------------------------------
           * Status state.
           * --------------------------------------------------------------
           *
           * flush deliberately does not enter this condition.
           *
           * An "enabled tick" for status still requires reg_enable_i.
           */
          if (reg_enable_i) begin

            for (
                k_idx = 0;
                k_idx < HEIGHT;
                k_idx = k_idx + 1
            ) begin

              status_pipe_q
                  [r_idx]
                  [k_idx]
                  [0]
                  <= fma_comb
                      [r_idx]
                      [k_idx]
                      [20:16];

              for (
                  d_idx = 1;
                  d_idx < STATUS_DELAY;
                  d_idx = d_idx + 1
              ) begin

                status_pipe_q
                    [r_idx]
                    [k_idx]
                    [d_idx]
                    <=
                status_pipe_q
                    [r_idx]
                    [k_idx]
                    [d_idx-1];

              end

            end

          end

        end

      end

    end

  end

endmodule