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

  localparam logic [2:0] RNE = 3'd0;
  localparam logic [2:0] RTZ = 3'd1;
  localparam logic [2:0] RDN = 3'd2;
  localparam logic [2:0] RUP = 3'd3;
  localparam logic [2:0] RMM = 3'd4;

  /*
   * Four registers per stage:
   *
   * sampled at t -> q[0]
   * q[1] at t+1
   * q[2] at t+2
   * q[3] at t+3
   *
   * The following FMA stage consumes q[3] at t+4.
   */
  logic [WIDTH-1:0][HEIGHT-1:0][3:0][15:0] data_q;

  /*
   * Three registers give a two-enabled-tick delay from sampling
   * to status_o.
   */
  logic [WIDTH-1:0][HEIGHT-1:0][2:0][4:0] flag_q;

  logic [WIDTH-1:0] flush_seen_q;

  /*
   * {NV,DZ,OF,UF,NX,result}
   */
  logic [WIDTH-1:0][HEIGHT-1:0][20:0] fma_now;


  function automatic integer msb_index80(
    input logic [79:0] v
  );
    logic [127:0] t;
    integer idx;

    begin
      t   = {48'b0, v};
      idx = 0;

      if (|t[127:64]) begin
        t   = t >> 64;
        idx = idx + 64;
      end

      if (|t[63:32]) begin
        t   = t >> 32;
        idx = idx + 32;
      end

      if (|t[31:16]) begin
        t   = t >> 16;
        idx = idx + 16;
      end

      if (|t[15:8]) begin
        t   = t >> 8;
        idx = idx + 8;
      end

      if (|t[7:4]) begin
        t   = t >> 4;
        idx = idx + 4;
      end

      if (|t[3:2]) begin
        t   = t >> 2;
        idx = idx + 2;
      end

      if (t[1])
        idx = idx + 1;

      msb_index80 = idx;
    end
  endfunction


  function automatic logic [15:0] overflow_value(
    input logic       sign,
    input logic [2:0] rnd
  );
    logic [15:0] inf_v;
    logic [15:0] max_v;

    begin
      inf_v = {sign, 5'h1f, 10'h000};
      max_v = {sign, 5'h1e, 10'h3ff};

      case (rnd)
        RNE: overflow_value = inf_v;
        RTZ: overflow_value = max_v;
        RDN: overflow_value = sign ? inf_v : max_v;
        RUP: overflow_value = sign ? max_v : inf_v;
        RMM: overflow_value = inf_v;
        default: overflow_value = inf_v;
      endcase
    end
  endfunction


  /*
   * Exact binary16 fused multiply-add.
   *
   * Finite values use an exact fixed-point representation whose
   * least-significant unit is 2^-48.
   *
   * This permits a*b+c to be formed exactly before a single FP16
   * rounding step.
   *
   * Return:
   *
   *   [20:16] {NV,DZ,OF,UF,NX}
   *   [15:0]  result
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
    logic prod_sign;
    logic sum_sign;
    logic zero_sign;

    logic [4:0] exp_a;
    logic [4:0] exp_b;
    logic [4:0] exp_c;

    logic [9:0] frac_a;
    logic [9:0] frac_b;
    logic [9:0] frac_c;

    logic a_nan;
    logic b_nan;
    logic c_nan;

    logic a_qnan;
    logic b_qnan;
    logic c_qnan;

    logic a_snan;
    logic b_snan;
    logic c_snan;

    logic a_inf;
    logic b_inf;
    logic c_inf;

    logic a_zero;
    logic b_zero;
    logic c_zero;

    logic [10:0] sig_a;
    logic [10:0] sig_b;
    logic [10:0] sig_c;

    logic [21:0] prod_sig;

    integer scale_a;
    integer scale_b;
    integer scale_c;
    integer prod_shift;
    integer c_shift;

    integer msb;
    integer rshift;
    integer exp_field;

    logic [79:0] prod_mag;
    logic [79:0] c_mag;
    logic [79:0] sum_mag;

    logic [79:0] retained_wide;
    logic [79:0] rem;
    logic [79:0] half;

    logic [79:0] ovf_threshold;
    logic [79:0] minsub_threshold;
    logic [79:0] minnorm_threshold;

    logic [11:0] retained;

    logic round_inc;
    logic inexact;

    logic nv;
    logic of;
    logic uf;
    logic nx;

    logic [15:0] result;

    begin

      sign_a = a[15];
      sign_b = b[15];
      sign_c = c[15];

      exp_a  = a[14:10];
      exp_b  = b[14:10];
      exp_c  = c[14:10];

      frac_a = a[9:0];
      frac_b = b[9:0];
      frac_c = c[9:0];

      a_nan =
        (exp_a == 5'h1f) &&
        (frac_a != 10'h000);

      b_nan =
        (exp_b == 5'h1f) &&
        (frac_b != 10'h000);

      c_nan =
        (exp_c == 5'h1f) &&
        (frac_c != 10'h000);

      a_qnan = a_nan && frac_a[9];
      b_qnan = b_nan && frac_b[9];
      c_qnan = c_nan && frac_c[9];

      a_snan = a_nan && !frac_a[9];
      b_snan = b_nan && !frac_b[9];
      c_snan = c_nan && !frac_c[9];

      a_inf =
        (exp_a == 5'h1f) &&
        (frac_a == 10'h000);

      b_inf =
        (exp_b == 5'h1f) &&
        (frac_b == 10'h000);

      c_inf =
        (exp_c == 5'h1f) &&
        (frac_c == 10'h000);

      a_zero =
        (exp_a == 5'h00) &&
        (frac_a == 10'h000);

      b_zero =
        (exp_b == 5'h00) &&
        (frac_b == 10'h000);

      c_zero =
        (exp_c == 5'h00) &&
        (frac_c == 10'h000);

      nv = 1'b0;
      of = 1'b0;
      uf = 1'b0;
      nx = 1'b0;

      result = 16'h0000;

      sig_a = 11'h000;
      sig_b = 11'h000;
      sig_c = 11'h000;

      scale_a = -24;
      scale_b = -24;
      scale_c = -24;

      prod_sig = 22'h000000;

      prod_shift = 0;
      c_shift    = 0;

      prod_mag = 80'h0;
      c_mag    = 80'h0;
      sum_mag  = 80'h0;

      prod_sign = 1'b0;
      sum_sign  = 1'b0;
      zero_sign = 1'b0;

      retained_wide = 80'h0;
      rem           = 80'h0;
      half          = 80'h0;

      retained = 12'h000;

      round_inc = 1'b0;
      inexact   = 1'b0;

      msb       = 0;
      rshift    = 0;
      exp_field = 0;

      /*
       * Internal unit = 2^-48.
       *
       * 65520 * 2^48
       * 2^-24 * 2^48 = 2^24
       * 2^-14 * 2^48 = 2^34
       */
      ovf_threshold     = (80'd65520 << 48);
      minsub_threshold  = (80'd1 << 24);
      minnorm_threshold = (80'd1 << 34);


      /*
       * Quiet NaN has contractual no-NV behavior.
       */
      if (a_qnan || b_qnan || c_qnan) begin

        result = 16'h7e00;

      end else if (a_snan || b_snan || c_snan) begin

        result = 16'h7e00;
        nv     = 1'b1;

      end else if (
        (a_inf && b_zero) ||
        (b_inf && a_zero)
      ) begin

        result = 16'h7e00;
        nv     = 1'b1;

      end else if (a_inf || b_inf) begin

        prod_sign = sign_a ^ sign_b;

        if (c_inf && (sign_c != prod_sign)) begin
          result = 16'h7e00;
          nv     = 1'b1;
        end else begin
          result = {
            prod_sign,
            5'h1f,
            10'h000
          };
        end

      end else if (c_inf) begin

        result = {
          sign_c,
          5'h1f,
          10'h000
        };

      end else begin

        /*
         * finite value = significand * 2^scale
         */
        if (exp_a == 5'h00) begin
          sig_a   = {1'b0, frac_a};
          scale_a = -24;
        end else begin
          sig_a   = {1'b1, frac_a};
          scale_a = $signed({1'b0, exp_a}) - 25;
        end

        if (exp_b == 5'h00) begin
          sig_b   = {1'b0, frac_b};
          scale_b = -24;
        end else begin
          sig_b   = {1'b1, frac_b};
          scale_b = $signed({1'b0, exp_b}) - 25;
        end

        if (exp_c == 5'h00) begin
          sig_c   = {1'b0, frac_c};
          scale_c = -24;
        end else begin
          sig_c   = {1'b1, frac_c};
          scale_c = $signed({1'b0, exp_c}) - 25;
        end

        prod_sign = sign_a ^ sign_b;

        prod_sig =
          {11'b0, sig_a} * sig_b;

        prod_shift =
          scale_a + scale_b + 48;

        c_shift =
          scale_c + 48;

        if (prod_sig != 22'h000000)
          prod_mag =
            {{58{1'b0}}, prod_sig}
            << prod_shift;

        if (sig_c != 11'h000)
          c_mag =
            {{69{1'b0}}, sig_c}
            << c_shift;

        /*
         * Exact signed magnitude addition.
         */
        if (prod_sign == sign_c) begin

          sum_mag  = prod_mag + c_mag;
          sum_sign = prod_sign;

        end else if (prod_mag > c_mag) begin

          sum_mag  = prod_mag - c_mag;
          sum_sign = prod_sign;

        end else if (c_mag > prod_mag) begin

          sum_mag  = c_mag - prod_mag;
          sum_sign = sign_c;

        end else begin

          sum_mag = 80'h0;

          /*
           * Same-sign zero + zero retains that sign.
           *
           * Exact cancellation of opposite signs yields -0 only
           * for roundTowardNegative.
           */
          if (
            (prod_mag == 80'h0) &&
            (c_mag == 80'h0) &&
            (prod_sign == sign_c)
          )
            zero_sign = prod_sign;
          else
            zero_sign = (rnd == RDN);

          sum_sign = zero_sign;

        end


        /*
         * Exact zero.
         */
        if (sum_mag == 80'h0) begin

          result = {
            sum_sign,
            15'h0000
          };


        /*
         * Exact magnitude at or above FP16 overflow threshold.
         */
        end else if (sum_mag >= ovf_threshold) begin

          result =
            overflow_value(
              sum_sign,
              rnd
            );

          of = 1'b1;
          nx = 1'b1;


        /*
         * Below the smallest positive subnormal.
         */
        end else if (sum_mag < minsub_threshold) begin

          rem  = sum_mag;
          half = (80'd1 << 23);

          round_inc = 1'b0;

          case (rnd)

            RNE:
              round_inc =
                (rem > half);

            RTZ:
              round_inc =
                1'b0;

            RDN:
              round_inc =
                sum_sign;

            RUP:
              round_inc =
                !sum_sign;

            RMM:
              round_inc =
                (rem >= half);

            default:
              round_inc =
                (rem > half);

          endcase

          if (round_inc)
            result = {
              sum_sign,
              5'h00,
              10'h001
            };
          else
            result = {
              sum_sign,
              15'h0000
            };

          uf = 1'b1;
          nx = 1'b1;


        /*
         * Subnormal result.
         *
         * FP16 subnormal ULP = 2^-24, therefore 2^24 units
         * of the internal 2^-48 representation.
         */
        end else if (sum_mag < minnorm_threshold) begin

          retained_wide =
            sum_mag >> 24;

          retained =
            retained_wide[11:0];

          rem =
            sum_mag -
            (retained_wide << 24);

          half =
            (80'd1 << 23);

          inexact =
            (rem != 80'h0);

          round_inc = 1'b0;

          if (inexact) begin

            case (rnd)

              RNE:
                round_inc =
                  (rem > half) ||
                  (
                    (rem == half) &&
                    retained[0]
                  );

              RTZ:
                round_inc =
                  1'b0;

              RDN:
                round_inc =
                  sum_sign;

              RUP:
                round_inc =
                  !sum_sign;

              RMM:
                round_inc =
                  (rem >= half);

              default:
                round_inc =
                  (rem > half) ||
                  (
                    (rem == half) &&
                    retained[0]
                  );

            endcase

          end

          retained =
            retained + round_inc;

          nx = inexact;
          uf = inexact;

          /*
           * Largest subnormal can round into minimum normal.
           */
          if (retained >= 12'd1024)
            result = {
              sum_sign,
              5'h01,
              10'h000
            };
          else
            result = {
              sum_sign,
              5'h00,
              retained[9:0]
            };


        /*
         * Normal FP16 result.
         */
        end else begin

          msb =
            msb_index80(sum_mag);

          rshift =
            msb - 10;

          retained_wide =
            sum_mag >> rshift;

          retained =
            retained_wide[11:0];

          rem =
            sum_mag -
            (retained_wide << rshift);

          half =
            (80'd1 << (rshift - 1));

          inexact =
            (rem != 80'h0);

          round_inc =
            1'b0;

          if (inexact) begin

            case (rnd)

              RNE:
                round_inc =
                  (rem > half) ||
                  (
                    (rem == half) &&
                    retained[0]
                  );

              RTZ:
                round_inc =
                  1'b0;

              RDN:
                round_inc =
                  sum_sign;

              RUP:
                round_inc =
                  !sum_sign;

              RMM:
                round_inc =
                  (rem >= half);

              default:
                round_inc =
                  (rem > half) ||
                  (
                    (rem == half) &&
                    retained[0]
                  );

            endcase

          end

          retained =
            retained + round_inc;

          /*
           * Internal scaling is 2^-48.
           *
           * biased FP16 exponent:
           *
           *   msb - 48 + 15
           * = msb - 33
           */
          exp_field =
            msb - 33;

          /*
           * Carry from significand rounding.
           */
          if (retained >= 12'd2048) begin

            retained =
              12'd1024;

            exp_field =
              exp_field + 1;

          end

          if (exp_field >= 31) begin

            result =
              overflow_value(
                sum_sign,
                rnd
              );

            of = 1'b1;
            nx = 1'b1;

          end else begin

            result = {
              sum_sign,
              exp_field[4:0],
              retained[9:0]
            };

            nx = inexact;

          end

        end
      end

      fp16_fma = {
        nv,
        1'b0,
        of,
        uf,
        nx,
        result
      };

    end
  endfunction


  /*
   * Combinational FMA input for each row/stage.
   */
  genvar gr;
  genvar gk;

  generate
    for (
      gr = 0;
      gr < WIDTH;
      gr = gr + 1
    ) begin : g_row

      for (
        gk = 0;
        gk < HEIGHT;
        gk = gk + 1
      ) begin : g_stage

        if (gk == 0) begin : g_first

          assign fma_now[gr][gk] =
            accumulate_i
              ? fp16_fma(
                  x_i[gr][gk],
                  w_i[gk],
                  data_q[gr][HEIGHT-1][3],
                  rnd_i
                )
              : fp16_fma(
                  x_i[gr][gk],
                  w_i[gk],
                  y_i[gr],
                  rnd_i
                );

        end else begin : g_rest

          assign fma_now[gr][gk] =
            fp16_fma(
              x_i[gr][gk],
              w_i[gk],
              data_q[gr][gk-1][3],
              rnd_i
            );

        end
      end
    end
  endgenerate


  integer r;
  integer k;
  integer j;

  always_ff @(posedge clk_i or negedge rst_ni) begin

    if (!rst_ni) begin

      data_q       <= '0;
      flag_q       <= '0;
      flush_seen_q <= '0;

    end else begin

      for (
        r = 0;
        r < WIDTH;
        r = r + 1
      ) begin

        /*
         * A gated row holds all state. It therefore also ignores flush.
         */
        if (row_clk_gate_en_i[r]) begin

          if (flush_i) begin

            /*
             * Flush clears the arithmetic pipeline even if
             * reg_enable_i is low.
             */
            data_q[r] <= '0;

            /*
             * status advances on the first enabled flush tick.
             * Enabled tick requires reg_enable_i.
             *
             * Later enabled flush ticks hold status.
             */
            if (
              reg_enable_i &&
              !flush_seen_q[r]
            ) begin

              for (
                k = 0;
                k < HEIGHT;
                k = k + 1
              ) begin

                flag_q[r][k][0] <=
                  fma_now[r][k][20:16];

                flag_q[r][k][1] <=
                  flag_q[r][k][0];

                flag_q[r][k][2] <=
                  flag_q[r][k][1];

              end

              flush_seen_q[r] <= 1'b1;

            end

          end else begin

            flush_seen_q[r] <= 1'b0;

            /*
             * Ordinary enabled-tick advancement.
             */
            if (reg_enable_i) begin

              for (
                k = 0;
                k < HEIGHT;
                k = k + 1
              ) begin

                data_q[r][k][0] <=
                  fma_now[r][k][15:0];

                for (
                  j = 1;
                  j < 4;
                  j = j + 1
                ) begin

                  data_q[r][k][j] <=
                    data_q[r][k][j-1];

                end

                flag_q[r][k][0] <=
                  fma_now[r][k][20:16];

                flag_q[r][k][1] <=
                  flag_q[r][k][0];

                flag_q[r][k][2] <=
                  flag_q[r][k][1];

              end

            end
          end
        end
      end
    end
  end


  genvar orow;
  genvar ostage;

  generate

    for (
      orow = 0;
      orow < WIDTH;
      orow = orow + 1
    ) begin : g_out_row

      assign z_o[orow] =
        data_q[orow][HEIGHT-1][3];

      for (
        ostage = 0;
        ostage < HEIGHT;
        ostage = ostage + 1
      ) begin : g_out_stage

        assign status_o[orow][ostage] =
          flag_q[orow][ostage][2];

      end
    end
  endgenerate

endmodule