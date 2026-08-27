module fp_multifmt_fma #(
  parameter int unsigned WIDTH = 64
) (
  input  logic             clk_i,
  input  logic             rst_ni,

  input  logic             in_valid_i,
  output logic             in_ready_o,

  input  logic [1:0]       fmt_i,
  input  logic             vec_i,

  input  logic [WIDTH-1:0] a_i,
  input  logic [WIDTH-1:0] b_i,
  input  logic [WIDTH-1:0] c_i,

  input  logic [2:0]       rnd_i,

  output logic             out_valid_o,
  input  logic             out_ready_i,

  output logic [WIDTH-1:0] result_o,
  output logic [4:0]       flags_o
);

  /*
   * ==========================================================================
   * Small leading-one encoders
   * ==========================================================================
   */

  function automatic integer msb8(
    input logic [7:0] v
  );
    begin
      if      (v[7]) msb8 = 7;
      else if (v[6]) msb8 = 6;
      else if (v[5]) msb8 = 5;
      else if (v[4]) msb8 = 4;
      else if (v[3]) msb8 = 3;
      else if (v[2]) msb8 = 2;
      else if (v[1]) msb8 = 1;
      else           msb8 = 0;
    end
  endfunction


  function automatic integer msb16(
    input logic [15:0] v
  );
    begin
      if (|v[15:8])
        msb16 = 8 + msb8(v[15:8]);
      else
        msb16 = msb8(v[7:0]);
    end
  endfunction


  function automatic integer msb22(
    input logic [21:0] v
  );
    begin
      if (|v[21:16])
        msb22 = 16 + msb8({2'b00,v[21:16]});
      else
        msb22 = msb16(v[15:0]);
    end
  endfunction


  function automatic integer msb24(
    input logic [23:0] v
  );
    begin
      if (|v[23:16])
        msb24 = 16 + msb8(v[23:16]);
      else
        msb24 = msb16(v[15:0]);
    end
  endfunction


  function automatic integer msb32(
    input logic [31:0] v
  );
    begin
      if (|v[31:16])
        msb32 = 16 + msb16(v[31:16]);
      else
        msb32 = msb16(v[15:0]);
    end
  endfunction


  function automatic integer msb44(
    input logic [43:0] v
  );
    begin
      if (|v[43:32])
        msb44 = 32 + msb16({4'b0000,v[43:32]});
      else if (|v[31:16])
        msb44 = 16 + msb16(v[31:16]);
      else
        msb44 = msb16(v[15:0]);
    end
  endfunction


  function automatic integer msb48(
    input logic [47:0] v
  );
    begin
      if (|v[47:32])
        msb48 = 32 + msb16(v[47:32]);
      else if (|v[31:16])
        msb48 = 16 + msb16(v[31:16]);
      else
        msb48 = msb16(v[15:0]);
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
   * ==========================================================================
   * Sticky alignment helpers
   *
   * FP32 uses 80 bits <= 96-bit A8 ceiling.
   * FP16 uses 44 bits = its A8 ceiling.
   * BF16 uses 32 bits = its A8 ceiling.
   * ==========================================================================
   */

  function automatic logic [79:0] align80(
    input logic [47:0] mag,
    input integer      lsb_exp,
    input integer      base_exp
  );
    integer delta;
    integer rshift;
    logic [79:0] tmp;
    logic [79:0] shifted;
    logic [79:0] mask;
    logic sticky;

    begin
      tmp     = {{32{1'b0}},mag};
      shifted = 80'b0;
      mask    = 80'b0;
      sticky  = 1'b0;

      delta = lsb_exp - base_exp;

      if (mag == 48'b0) begin
        align80 = 80'b0;
      end
      else if (delta >= 0) begin
        align80 = tmp << delta;
      end
      else begin
        rshift = -delta;

        if (rshift >= 80) begin
          align80 = 80'd1;
        end
        else begin
          shifted = tmp >> rshift;
          mask = (80'd1 << rshift) - 80'd1;
          sticky = |(tmp & mask);
          shifted[0] = shifted[0] | sticky;
          align80 = shifted;
        end
      end
    end
  endfunction


  function automatic logic [43:0] align44(
    input logic [21:0] mag,
    input integer      lsb_exp,
    input integer      base_exp
  );
    integer delta;
    integer rshift;
    logic [43:0] tmp;
    logic [43:0] shifted;
    logic [43:0] mask;
    logic sticky;

    begin
      tmp     = {{22{1'b0}},mag};
      shifted = 44'b0;
      mask    = 44'b0;
      sticky  = 1'b0;

      delta = lsb_exp - base_exp;

      if (mag == 22'b0) begin
        align44 = 44'b0;
      end
      else if (delta >= 0) begin
        align44 = tmp << delta;
      end
      else begin
        rshift = -delta;

        if (rshift >= 44) begin
          align44 = 44'd1;
        end
        else begin
          shifted = tmp >> rshift;
          mask = (44'd1 << rshift) - 44'd1;
          sticky = |(tmp & mask);
          shifted[0] = shifted[0] | sticky;
          align44 = shifted;
        end
      end
    end
  endfunction


  function automatic logic [31:0] align32(
    input logic [15:0] mag,
    input integer      lsb_exp,
    input integer      base_exp
  );
    integer delta;
    integer rshift;
    logic [31:0] tmp;
    logic [31:0] shifted;
    logic [31:0] mask;
    logic sticky;

    begin
      tmp     = {{16{1'b0}},mag};
      shifted = 32'b0;
      mask    = 32'b0;
      sticky  = 1'b0;

      delta = lsb_exp - base_exp;

      if (mag == 16'b0) begin
        align32 = 32'b0;
      end
      else if (delta >= 0) begin
        align32 = tmp << delta;
      end
      else begin
        rshift = -delta;

        if (rshift >= 32) begin
          align32 = 32'd1;
        end
        else begin
          shifted = tmp >> rshift;
          mask = (32'd1 << rshift) - 32'd1;
          sticky = |(tmp & mask);
          shifted[0] = shifted[0] | sticky;
          align32 = shifted;
        end
      end
    end
  endfunction


  /*
   * ==========================================================================
   * Overflow result selection
   * ==========================================================================
   */

  function automatic logic [31:0] overflow32(
    input logic       sign,
    input logic [2:0] rnd
  );
    logic to_inf;

    begin
      to_inf = 1'b0;

      case (rnd)
        3'd0: to_inf = 1'b1;   // RNE
        3'd1: to_inf = 1'b0;   // RTZ
        3'd2: to_inf = sign;   // RDN
        3'd3: to_inf = !sign;  // RUP
        3'd4: to_inf = 1'b1;   // RMM
        default: to_inf = 1'b1;
      endcase

      if (to_inf)
        overflow32 = {sign,8'hff,23'b0};
      else
        overflow32 = {sign,8'hfe,23'h7fffff};
    end
  endfunction


  function automatic logic [15:0] overflow16(
    input logic       sign,
    input logic [2:0] rnd
  );
    logic to_inf;

    begin
      to_inf = 1'b0;

      case (rnd)
        3'd0: to_inf = 1'b1;
        3'd1: to_inf = 1'b0;
        3'd2: to_inf = sign;
        3'd3: to_inf = !sign;
        3'd4: to_inf = 1'b1;
        default: to_inf = 1'b1;
      endcase

      if (to_inf)
        overflow16 = {sign,5'h1f,10'b0};
      else
        overflow16 = {sign,5'h1e,10'h3ff};
    end
  endfunction


  function automatic logic [15:0] overflow_bf16(
    input logic       sign,
    input logic [2:0] rnd
  );
    logic to_inf;

    begin
      to_inf = 1'b0;

      case (rnd)
        3'd0: to_inf = 1'b1;
        3'd1: to_inf = 1'b0;
        3'd2: to_inf = sign;
        3'd3: to_inf = !sign;
        3'd4: to_inf = 1'b1;
        default: to_inf = 1'b1;
      endcase

      if (to_inf)
        overflow_bf16 = {sign,8'hff,7'b0};
      else
        overflow_bf16 = {sign,8'hfe,7'h7f};
    end
  endfunction


  /*
   * ==========================================================================
   * FP32 FMA
   *
   * return = {NV,DZ,OF,UF,NX,result[31:0]}
   * ==========================================================================
   */

  function automatic logic [36:0] fma_fp32(
    input logic [31:0] fa,
    input logic [31:0] fb,
    input logic [31:0] fc,
    input logic [2:0]  rnd
  );

    logic sign_a;
    logic sign_b;
    logic sign_c;
    logic sign_p;
    logic sign_r;

    logic [7:0] exp_a;
    logic [7:0] exp_b;
    logic [7:0] exp_c;

    logic [22:0] frac_a;
    logic [22:0] frac_b;
    logic [22:0] frac_c;

    logic a_nan;
    logic b_nan;
    logic c_nan;

    logic a_snan;
    logic b_snan;
    logic c_snan;

    logic a_inf;
    logic b_inf;
    logic c_inf;

    logic a_zero;
    logic b_zero;
    logic c_zero;

    logic invalid_op;

    logic [23:0] mant_a;
    logic [23:0] mant_b;
    logic [23:0] mant_c;

    logic [47:0] prod_mant;

    integer lsb_a;
    integer lsb_b;
    integer lsb_c;
    integer prod_lsb;

    integer prod_top;
    integer c_top;
    integer top_exp;
    integer base_exp;

    logic [79:0] prod_aligned;
    logic [79:0] c_aligned;

    logic signed [80:0] prod_term;
    logic signed [80:0] c_term;
    logic signed [80:0] exact_sum;

    logic [79:0] magnitude;
    logic [79:0] trunc_mag;
    logic [79:0] remainder;
    logic [79:0] mask;
    logic [79:0] half_ulp;

    integer leading_bit;
    integer exact_top_exp;
    integer shift_amt;
    integer unbiased_exp;

    logic [24:0] rounded_sig;
    logic [24:0] sub_sig;

    logic rem_nonzero;
    logic round_increment;

    logic [7:0] out_exp;
    logic [31:0] out_value;

    logic nv;
    logic of;
    logic uf;
    logic nx;

    begin

      sign_a = fa[31];
      sign_b = fb[31];
      sign_c = fc[31];
      sign_p = sign_a ^ sign_b;
      sign_r = 1'b0;

      exp_a = fa[30:23];
      exp_b = fb[30:23];
      exp_c = fc[30:23];

      frac_a = fa[22:0];
      frac_b = fb[22:0];
      frac_c = fc[22:0];

      a_nan = (exp_a == 8'hff) && (frac_a != 0);
      b_nan = (exp_b == 8'hff) && (frac_b != 0);
      c_nan = (exp_c == 8'hff) && (frac_c != 0);

      a_snan = a_nan && !frac_a[22];
      b_snan = b_nan && !frac_b[22];
      c_snan = c_nan && !frac_c[22];

      a_inf = (exp_a == 8'hff) && (frac_a == 0);
      b_inf = (exp_b == 8'hff) && (frac_b == 0);
      c_inf = (exp_c == 8'hff) && (frac_c == 0);

      a_zero = (exp_a == 0) && (frac_a == 0);
      b_zero = (exp_b == 0) && (frac_b == 0);
      c_zero = (exp_c == 0) && (frac_c == 0);

      mant_a = 0;
      mant_b = 0;
      mant_c = 0;

      prod_mant = 0;

      lsb_a = 0;
      lsb_b = 0;
      lsb_c = 0;
      prod_lsb = 0;

      prod_top = -10000;
      c_top    = -10000;
      top_exp  = -10000;
      base_exp = 0;

      prod_aligned = 0;
      c_aligned    = 0;

      prod_term = 0;
      c_term    = 0;
      exact_sum = 0;

      magnitude = 0;
      trunc_mag = 0;
      remainder = 0;
      mask      = 0;
      half_ulp  = 0;

      leading_bit  = 0;
      exact_top_exp = 0;
      shift_amt = 0;
      unbiased_exp = 0;

      rounded_sig = 0;
      sub_sig     = 0;

      rem_nonzero = 1'b0;
      round_increment = 1'b0;

      out_exp   = 0;
      out_value = 0;

      nv = 1'b0;
      of = 1'b0;
      uf = 1'b0;
      nx = 1'b0;

      invalid_op =
          a_snan ||
          b_snan ||
          c_snan ||
          (a_inf && b_zero) ||
          (b_inf && a_zero);

      if (
          (a_inf || b_inf) &&
          !a_nan &&
          !b_nan &&
          !a_zero &&
          !b_zero &&
          c_inf &&
          (sign_p != sign_c)
      )
        invalid_op = 1'b1;


      /*
       * Canonical NaN.
       *
       * A5's invalid operations take priority even if another operand is qNaN.
       */
      if (a_nan || b_nan || c_nan || invalid_op) begin

        out_value = 32'h7fc00000;
        nv = invalid_op;

      end
      else if (a_inf || b_inf) begin

        out_value = {sign_p,8'hff,23'b0};

      end
      else if (c_inf) begin

        out_value = {sign_c,8'hff,23'b0};

      end
      else begin

        if (exp_a == 0) begin
          mant_a = {1'b0,frac_a};
          lsb_a  = -149;
        end
        else begin
          mant_a = {1'b1,frac_a};
          lsb_a  = exp_a;
          lsb_a  = lsb_a - 150;
        end

        if (exp_b == 0) begin
          mant_b = {1'b0,frac_b};
          lsb_b  = -149;
        end
        else begin
          mant_b = {1'b1,frac_b};
          lsb_b  = exp_b;
          lsb_b  = lsb_b - 150;
        end

        if (exp_c == 0) begin
          mant_c = {1'b0,frac_c};
          lsb_c  = -149;
        end
        else begin
          mant_c = {1'b1,frac_c};
          lsb_c  = exp_c;
          lsb_c  = lsb_c - 150;
        end

        prod_mant =
            {24'b0,mant_a} *
            {24'b0,mant_b};

        prod_lsb = lsb_a + lsb_b;

        /*
         * Both terms are zero.
         */
        if ((prod_mant == 0) && (mant_c == 0)) begin

          if (sign_p == sign_c)
            sign_r = sign_p;
          else if (rnd == 3'd2)
            sign_r = 1'b1;
          else
            sign_r = 1'b0;

          out_value = {sign_r,31'b0};

        end
        else begin

          if (prod_mant != 0)
            prod_top = prod_lsb + msb48(prod_mant);

          if (mant_c != 0)
            c_top = lsb_c + msb24(mant_c);

          if (prod_top > c_top)
            top_exp = prod_top;
          else
            top_exp = c_top;

          /*
           * Keep the dominant bit near bit 76, leaving carry headroom.
           */
          base_exp = top_exp - 76;

          prod_aligned =
              align80(
                prod_mant,
                prod_lsb,
                base_exp
              );

          c_aligned =
              align80(
                {24'b0,mant_c},
                lsb_c,
                base_exp
              );

          prod_term = $signed({1'b0,prod_aligned});
          c_term    = $signed({1'b0,c_aligned});

          if (sign_p)
            prod_term = -prod_term;

          if (sign_c)
            c_term = -c_term;

          exact_sum = prod_term + c_term;

          if (exact_sum == 0) begin

            if (rnd == 3'd2)
              sign_r = 1'b1;
            else
              sign_r = 1'b0;

            out_value = {sign_r,31'b0};

          end
          else begin

            sign_r = exact_sum[80];

            if (sign_r)
              magnitude =
                  (~exact_sum[79:0]) +
                  80'd1;
            else
              magnitude =
                  exact_sum[79:0];

            leading_bit =
                msb80(magnitude);

            exact_top_exp =
                base_exp +
                leading_bit;


            /*
             * Normal result path.
             */
            if (exact_top_exp >= -126) begin

              if (exact_top_exp > 127) begin

                out_value = overflow32(sign_r,rnd);
                of = 1'b1;
                nx = 1'b1;

              end
              else begin

                unbiased_exp = exact_top_exp;

                shift_amt =
                    leading_bit -
                    23;

                trunc_mag = 0;
                remainder = 0;
                half_ulp = 0;
                mask = 0;
                rem_nonzero = 1'b0;

                if (shift_amt <= 0) begin

                  trunc_mag =
                      magnitude <<
                      (-shift_amt);

                end
                else if (shift_amt < 80) begin

                  trunc_mag =
                      magnitude >>
                      shift_amt;

                  mask =
                      (80'd1 << shift_amt) -
                      80'd1;

                  remainder =
                      magnitude &
                      mask;

                  half_ulp =
                      80'd1 <<
                      (shift_amt - 1);

                  rem_nonzero =
                      (remainder != 0);

                end
                else begin

                  trunc_mag = 0;
                  remainder = magnitude;
                  rem_nonzero = (magnitude != 0);

                end

                rounded_sig =
                    trunc_mag[24:0];

                round_increment = 1'b0;

                if (rem_nonzero) begin
                  case (rnd)

                    3'd0: begin
                      if (shift_amt >= 80)
                        round_increment = 1'b0;
                      else
                        round_increment =
                            (remainder > half_ulp) ||
                            (
                              (remainder == half_ulp) &&
                              rounded_sig[0]
                            );
                    end

                    3'd1:
                      round_increment = 1'b0;

                    3'd2:
                      round_increment = sign_r;

                    3'd3:
                      round_increment = !sign_r;

                    3'd4: begin
                      if (shift_amt >= 80)
                        round_increment = 1'b0;
                      else
                        round_increment =
                            remainder >= half_ulp;
                    end

                    default:
                      round_increment = 1'b0;

                  endcase
                end

                if (round_increment)
                  rounded_sig =
                      rounded_sig +
                      25'd1;

                if (rounded_sig[24]) begin

                  rounded_sig =
                      rounded_sig >> 1;

                  unbiased_exp =
                      unbiased_exp +
                      1;

                end

                if (unbiased_exp > 127) begin

                  out_value =
                      overflow32(
                        sign_r,
                        rnd
                      );

                  of = 1'b1;
                  nx = 1'b1;

                end
                else begin

                  out_exp =
                      unbiased_exp +
                      127;

                  out_value = {
                    sign_r,
                    out_exp,
                    rounded_sig[22:0]
                  };

                  nx = rem_nonzero;

                end

              end

            end
            else begin

              /*
               * Binary32 subnormal quantum is 2^-149.
               */
              shift_amt =
                  -149 -
                  base_exp;

              trunc_mag = 0;
              remainder = 0;
              mask = 0;
              half_ulp = 0;
              rem_nonzero = 1'b0;

              if (shift_amt <= 0) begin

                trunc_mag =
                    magnitude <<
                    (-shift_amt);

              end
              else if (shift_amt < 80) begin

                trunc_mag =
                    magnitude >>
                    shift_amt;

                mask =
                    (80'd1 << shift_amt) -
                    80'd1;

                remainder =
                    magnitude &
                    mask;

                half_ulp =
                    80'd1 <<
                    (shift_amt - 1);

                rem_nonzero =
                    (remainder != 0);

              end
              else begin

                trunc_mag = 0;
                remainder = magnitude;
                rem_nonzero = (magnitude != 0);

              end

              sub_sig =
                  trunc_mag[24:0];

              round_increment = 1'b0;

              if (rem_nonzero) begin
                case (rnd)

                  3'd0: begin
                    if (shift_amt >= 80)
                      round_increment = 1'b0;
                    else
                      round_increment =
                          (remainder > half_ulp) ||
                          (
                            (remainder == half_ulp) &&
                            sub_sig[0]
                          );
                  end

                  3'd1:
                    round_increment = 1'b0;

                  3'd2:
                    round_increment = sign_r;

                  3'd3:
                    round_increment = !sign_r;

                  3'd4: begin
                    if (shift_amt >= 80)
                      round_increment = 1'b0;
                    else
                      round_increment =
                          remainder >= half_ulp;
                  end

                  default:
                    round_increment = 1'b0;

                endcase
              end

              if (round_increment)
                sub_sig =
                    sub_sig +
                    25'd1;

              /*
               * Rounded upward to the smallest normal.
               */
              if (sub_sig >= 25'h0800000) begin

                out_value = {
                  sign_r,
                  8'h01,
                  23'b0
                };

                nx = rem_nonzero;
                uf = 1'b0;

              end
              else begin

                out_value = {
                  sign_r,
                  8'h00,
                  sub_sig[22:0]
                };

                nx = rem_nonzero;

                /*
                 * Task-pinned A7a rule.
                 */
                uf = rem_nonzero;

              end

            end

          end

        end

      end

      fma_fp32 = {
        nv,
        1'b0,
        of,
        uf,
        nx,
        out_value
      };

    end
  endfunction


  /*
   * ==========================================================================
   * FP16 FMA
   *
   * return = {NV,DZ,OF,UF,NX,result[15:0]}
   * ==========================================================================
   */

  function automatic logic [20:0] fma_fp16(
    input logic [15:0] fa,
    input logic [15:0] fb,
    input logic [15:0] fc,
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

    logic a_snan;
    logic b_snan;
    logic c_snan;

    logic a_inf;
    logic b_inf;
    logic c_inf;

    logic a_zero;
    logic b_zero;
    logic c_zero;

    logic invalid_op;

    logic [10:0] mant_a;
    logic [10:0] mant_b;
    logic [10:0] mant_c;

    logic [21:0] prod_mant;

    integer lsb_a;
    integer lsb_b;
    integer lsb_c;
    integer prod_lsb;

    integer prod_top;
    integer c_top;
    integer top_exp;
    integer base_exp;

    logic [43:0] prod_aligned;
    logic [43:0] c_aligned;

    logic signed [44:0] prod_term;
    logic signed [44:0] c_term;
    logic signed [44:0] exact_sum;

    logic [43:0] magnitude;
    logic [43:0] trunc_mag;
    logic [43:0] remainder;
    logic [43:0] mask;
    logic [43:0] half_ulp;

    integer leading_bit;
    integer exact_top_exp;
    integer shift_amt;
    integer unbiased_exp;

    logic [11:0] rounded_sig;
    logic [11:0] sub_sig;

    logic rem_nonzero;
    logic round_increment;

    logic [4:0] out_exp;
    logic [15:0] out_value;

    logic nv;
    logic of;
    logic uf;
    logic nx;

    begin

      sign_a = fa[15];
      sign_b = fb[15];
      sign_c = fc[15];
      sign_p = sign_a ^ sign_b;
      sign_r = 1'b0;

      exp_a = fa[14:10];
      exp_b = fb[14:10];
      exp_c = fc[14:10];

      frac_a = fa[9:0];
      frac_b = fb[9:0];
      frac_c = fc[9:0];

      a_nan = (exp_a == 5'h1f) && (frac_a != 0);
      b_nan = (exp_b == 5'h1f) && (frac_b != 0);
      c_nan = (exp_c == 5'h1f) && (frac_c != 0);

      a_snan = a_nan && !frac_a[9];
      b_snan = b_nan && !frac_b[9];
      c_snan = c_nan && !frac_c[9];

      a_inf = (exp_a == 5'h1f) && (frac_a == 0);
      b_inf = (exp_b == 5'h1f) && (frac_b == 0);
      c_inf = (exp_c == 5'h1f) && (frac_c == 0);

      a_zero = (exp_a == 0) && (frac_a == 0);
      b_zero = (exp_b == 0) && (frac_b == 0);
      c_zero = (exp_c == 0) && (frac_c == 0);

      mant_a = 0;
      mant_b = 0;
      mant_c = 0;

      prod_mant = 0;

      lsb_a = 0;
      lsb_b = 0;
      lsb_c = 0;
      prod_lsb = 0;

      prod_top = -10000;
      c_top = -10000;
      top_exp = -10000;
      base_exp = 0;

      prod_aligned = 0;
      c_aligned = 0;

      prod_term = 0;
      c_term = 0;
      exact_sum = 0;

      magnitude = 0;
      trunc_mag = 0;
      remainder = 0;
      mask = 0;
      half_ulp = 0;

      leading_bit = 0;
      exact_top_exp = 0;
      shift_amt = 0;
      unbiased_exp = 0;

      rounded_sig = 0;
      sub_sig = 0;

      rem_nonzero = 1'b0;
      round_increment = 1'b0;

      out_exp = 0;
      out_value = 0;

      nv = 1'b0;
      of = 1'b0;
      uf = 1'b0;
      nx = 1'b0;

      invalid_op =
          a_snan ||
          b_snan ||
          c_snan ||
          (a_inf && b_zero) ||
          (b_inf && a_zero);

      if (
          (a_inf || b_inf) &&
          !a_nan &&
          !b_nan &&
          !a_zero &&
          !b_zero &&
          c_inf &&
          (sign_p != sign_c)
      )
        invalid_op = 1'b1;


      if (a_nan || b_nan || c_nan || invalid_op) begin

        out_value = 16'h7e00;
        nv = invalid_op;

      end
      else if (a_inf || b_inf) begin

        out_value = {sign_p,5'h1f,10'b0};

      end
      else if (c_inf) begin

        out_value = {sign_c,5'h1f,10'b0};

      end
      else begin

        if (exp_a == 0) begin
          mant_a = {1'b0,frac_a};
          lsb_a = -24;
        end
        else begin
          mant_a = {1'b1,frac_a};
          lsb_a = exp_a;
          lsb_a = lsb_a - 25;
        end

        if (exp_b == 0) begin
          mant_b = {1'b0,frac_b};
          lsb_b = -24;
        end
        else begin
          mant_b = {1'b1,frac_b};
          lsb_b = exp_b;
          lsb_b = lsb_b - 25;
        end

        if (exp_c == 0) begin
          mant_c = {1'b0,frac_c};
          lsb_c = -24;
        end
        else begin
          mant_c = {1'b1,frac_c};
          lsb_c = exp_c;
          lsb_c = lsb_c - 25;
        end

        prod_mant =
            {11'b0,mant_a} *
            {11'b0,mant_b};

        prod_lsb = lsb_a + lsb_b;

        if ((prod_mant == 0) && (mant_c == 0)) begin

          if (sign_p == sign_c)
            sign_r = sign_p;
          else if (rnd == 3'd2)
            sign_r = 1'b1;
          else
            sign_r = 1'b0;

          out_value = {sign_r,15'b0};

        end
        else begin

          if (prod_mant != 0)
            prod_top =
                prod_lsb +
                msb22(prod_mant);

          if (mant_c != 0)
            c_top =
                lsb_c +
                msb16({5'b00000,mant_c});

          if (prod_top > c_top)
            top_exp = prod_top;
          else
            top_exp = c_top;

          base_exp =
              top_exp -
              40;

          prod_aligned =
              align44(
                prod_mant,
                prod_lsb,
                base_exp
              );

          c_aligned =
              align44(
                {11'b0,mant_c},
                lsb_c,
                base_exp
              );

          prod_term =
              $signed({1'b0,prod_aligned});

          c_term =
              $signed({1'b0,c_aligned});

          if (sign_p)
            prod_term = -prod_term;

          if (sign_c)
            c_term = -c_term;

          exact_sum =
              prod_term +
              c_term;

          if (exact_sum == 0) begin

            if (rnd == 3'd2)
              sign_r = 1'b1;
            else
              sign_r = 1'b0;

            out_value = {sign_r,15'b0};

          end
          else begin

            sign_r = exact_sum[44];

            if (sign_r)
              magnitude =
                  (~exact_sum[43:0]) +
                  44'd1;
            else
              magnitude =
                  exact_sum[43:0];

            leading_bit =
                msb44(magnitude);

            exact_top_exp =
                base_exp +
                leading_bit;


            if (exact_top_exp >= -14) begin

              if (exact_top_exp > 15) begin

                out_value =
                    overflow16(
                      sign_r,
                      rnd
                    );

                of = 1'b1;
                nx = 1'b1;

              end
              else begin

                unbiased_exp =
                    exact_top_exp;

                shift_amt =
                    leading_bit -
                    10;

                trunc_mag = 0;
                remainder = 0;
                mask = 0;
                half_ulp = 0;
                rem_nonzero = 1'b0;

                if (shift_amt <= 0) begin

                  trunc_mag =
                      magnitude <<
                      (-shift_amt);

                end
                else if (shift_amt < 44) begin

                  trunc_mag =
                      magnitude >>
                      shift_amt;

                  mask =
                      (44'd1 << shift_amt) -
                      44'd1;

                  remainder =
                      magnitude &
                      mask;

                  half_ulp =
                      44'd1 <<
                      (shift_amt - 1);

                  rem_nonzero =
                      (remainder != 0);

                end
                else begin

                  remainder = magnitude;
                  rem_nonzero = (magnitude != 0);

                end

                rounded_sig =
                    trunc_mag[11:0];

                round_increment = 1'b0;

                if (rem_nonzero) begin
                  case (rnd)

                    3'd0:
                      if (shift_amt < 44)
                        round_increment =
                            (remainder > half_ulp) ||
                            (
                              (remainder == half_ulp) &&
                              rounded_sig[0]
                            );

                    3'd1:
                      round_increment = 1'b0;

                    3'd2:
                      round_increment = sign_r;

                    3'd3:
                      round_increment = !sign_r;

                    3'd4:
                      if (shift_amt < 44)
                        round_increment =
                            remainder >= half_ulp;

                    default:
                      round_increment = 1'b0;

                  endcase
                end

                if (round_increment)
                  rounded_sig =
                      rounded_sig +
                      12'd1;

                if (rounded_sig[11]) begin

                  rounded_sig =
                      rounded_sig >> 1;

                  unbiased_exp =
                      unbiased_exp +
                      1;

                end

                if (unbiased_exp > 15) begin

                  out_value =
                      overflow16(
                        sign_r,
                        rnd
                      );

                  of = 1'b1;
                  nx = 1'b1;

                end
                else begin

                  out_exp =
                      unbiased_exp +
                      15;

                  out_value = {
                    sign_r,
                    out_exp,
                    rounded_sig[9:0]
                  };

                  nx = rem_nonzero;

                end

              end

            end
            else begin

              /*
               * FP16 subnormal quantum = 2^-24.
               */
              shift_amt =
                  -24 -
                  base_exp;

              trunc_mag = 0;
              remainder = 0;
              mask = 0;
              half_ulp = 0;
              rem_nonzero = 1'b0;

              if (shift_amt <= 0) begin

                trunc_mag =
                    magnitude <<
                    (-shift_amt);

              end
              else if (shift_amt < 44) begin

                trunc_mag =
                    magnitude >>
                    shift_amt;

                mask =
                    (44'd1 << shift_amt) -
                    44'd1;

                remainder =
                    magnitude &
                    mask;

                half_ulp =
                    44'd1 <<
                    (shift_amt - 1);

                rem_nonzero =
                    (remainder != 0);

              end
              else begin

                remainder = magnitude;
                rem_nonzero = (magnitude != 0);

              end

              sub_sig =
                  trunc_mag[11:0];

              round_increment = 1'b0;

              if (rem_nonzero) begin
                case (rnd)

                  3'd0:
                    if (shift_amt < 44)
                      round_increment =
                          (remainder > half_ulp) ||
                          (
                            (remainder == half_ulp) &&
                            sub_sig[0]
                          );

                  3'd1:
                    round_increment = 1'b0;

                  3'd2:
                    round_increment = sign_r;

                  3'd3:
                    round_increment = !sign_r;

                  3'd4:
                    if (shift_amt < 44)
                      round_increment =
                          remainder >= half_ulp;

                  default:
                    round_increment = 1'b0;

                endcase
              end

              if (round_increment)
                sub_sig =
                    sub_sig +
                    12'd1;

              if (sub_sig >= 12'd1024) begin

                out_value = {
                  sign_r,
                  5'h01,
                  10'b0
                };

                nx = rem_nonzero;
                uf = 1'b0;

              end
              else begin

                out_value = {
                  sign_r,
                  5'h00,
                  sub_sig[9:0]
                };

                nx = rem_nonzero;
                uf = rem_nonzero;

              end

            end

          end

        end

      end

      fma_fp16 = {
        nv,
        1'b0,
        of,
        uf,
        nx,
        out_value
      };

    end
  endfunction


  /*
   * ==========================================================================
   * BF16 FMA
   *
   * BF16:
   *   sign     1
   *   exponent 8
   *   fraction 7
   *   precision p = 8
   *
   * return = {NV,DZ,OF,UF,NX,result[15:0]}
   * ==========================================================================
   */

  function automatic logic [20:0] fma_bf16(
    input logic [15:0] fa,
    input logic [15:0] fb,
    input logic [15:0] fc,
    input logic [2:0]  rnd
  );

    logic sign_a;
    logic sign_b;
    logic sign_c;
    logic sign_p;
    logic sign_r;

    logic [7:0] exp_a;
    logic [7:0] exp_b;
    logic [7:0] exp_c;

    logic [6:0] frac_a;
    logic [6:0] frac_b;
    logic [6:0] frac_c;

    logic a_nan;
    logic b_nan;
    logic c_nan;

    logic a_snan;
    logic b_snan;
    logic c_snan;

    logic a_inf;
    logic b_inf;
    logic c_inf;

    logic a_zero;
    logic b_zero;
    logic c_zero;

    logic invalid_op;

    logic [7:0] mant_a;
    logic [7:0] mant_b;
    logic [7:0] mant_c;

    logic [15:0] prod_mant;

    integer lsb_a;
    integer lsb_b;
    integer lsb_c;
    integer prod_lsb;

    integer prod_top;
    integer c_top;
    integer top_exp;
    integer base_exp;

    logic [31:0] prod_aligned;
    logic [31:0] c_aligned;

    logic signed [32:0] prod_term;
    logic signed [32:0] c_term;
    logic signed [32:0] exact_sum;

    logic [31:0] magnitude;
    logic [31:0] trunc_mag;
    logic [31:0] remainder;
    logic [31:0] mask;
    logic [31:0] half_ulp;

    integer leading_bit;
    integer exact_top_exp;
    integer shift_amt;
    integer unbiased_exp;

    logic [8:0] rounded_sig;
    logic [8:0] sub_sig;

    logic rem_nonzero;
    logic round_increment;

    logic [7:0] out_exp;
    logic [15:0] out_value;

    logic nv;
    logic of;
    logic uf;
    logic nx;

    begin

      sign_a = fa[15];
      sign_b = fb[15];
      sign_c = fc[15];
      sign_p = sign_a ^ sign_b;
      sign_r = 1'b0;

      exp_a = fa[14:7];
      exp_b = fb[14:7];
      exp_c = fc[14:7];

      frac_a = fa[6:0];
      frac_b = fb[6:0];
      frac_c = fc[6:0];

      a_nan = (exp_a == 8'hff) && (frac_a != 0);
      b_nan = (exp_b == 8'hff) && (frac_b != 0);
      c_nan = (exp_c == 8'hff) && (frac_c != 0);

      a_snan = a_nan && !frac_a[6];
      b_snan = b_nan && !frac_b[6];
      c_snan = c_nan && !frac_c[6];

      a_inf = (exp_a == 8'hff) && (frac_a == 0);
      b_inf = (exp_b == 8'hff) && (frac_b == 0);
      c_inf = (exp_c == 8'hff) && (frac_c == 0);

      a_zero = (exp_a == 0) && (frac_a == 0);
      b_zero = (exp_b == 0) && (frac_b == 0);
      c_zero = (exp_c == 0) && (frac_c == 0);

      mant_a = 0;
      mant_b = 0;
      mant_c = 0;

      prod_mant = 0;

      lsb_a = 0;
      lsb_b = 0;
      lsb_c = 0;
      prod_lsb = 0;

      prod_top = -10000;
      c_top = -10000;
      top_exp = -10000;
      base_exp = 0;

      prod_aligned = 0;
      c_aligned = 0;

      prod_term = 0;
      c_term = 0;
      exact_sum = 0;

      magnitude = 0;
      trunc_mag = 0;
      remainder = 0;
      mask = 0;
      half_ulp = 0;

      leading_bit = 0;
      exact_top_exp = 0;
      shift_amt = 0;
      unbiased_exp = 0;

      rounded_sig = 0;
      sub_sig = 0;

      rem_nonzero = 1'b0;
      round_increment = 1'b0;

      out_exp = 0;
      out_value = 0;

      nv = 1'b0;
      of = 1'b0;
      uf = 1'b0;
      nx = 1'b0;

      invalid_op =
          a_snan ||
          b_snan ||
          c_snan ||
          (a_inf && b_zero) ||
          (b_inf && a_zero);

      if (
          (a_inf || b_inf) &&
          !a_nan &&
          !b_nan &&
          !a_zero &&
          !b_zero &&
          c_inf &&
          (sign_p != sign_c)
      )
        invalid_op = 1'b1;


      if (a_nan || b_nan || c_nan || invalid_op) begin

        out_value = 16'h7fc0;
        nv = invalid_op;

      end
      else if (a_inf || b_inf) begin

        out_value = {sign_p,8'hff,7'b0};

      end
      else if (c_inf) begin

        out_value = {sign_c,8'hff,7'b0};

      end
      else begin

        if (exp_a == 0) begin
          mant_a = {1'b0,frac_a};
          lsb_a = -133;
        end
        else begin
          mant_a = {1'b1,frac_a};
          lsb_a = exp_a;
          lsb_a = lsb_a - 134;
        end

        if (exp_b == 0) begin
          mant_b = {1'b0,frac_b};
          lsb_b = -133;
        end
        else begin
          mant_b = {1'b1,frac_b};
          lsb_b = exp_b;
          lsb_b = lsb_b - 134;
        end

        if (exp_c == 0) begin
          mant_c = {1'b0,frac_c};
          lsb_c = -133;
        end
        else begin
          mant_c = {1'b1,frac_c};
          lsb_c = exp_c;
          lsb_c = lsb_c - 134;
        end

        prod_mant =
            {8'b0,mant_a} *
            {8'b0,mant_b};

        prod_lsb = lsb_a + lsb_b;

        if ((prod_mant == 0) && (mant_c == 0)) begin

          if (sign_p == sign_c)
            sign_r = sign_p;
          else if (rnd == 3'd2)
            sign_r = 1'b1;
          else
            sign_r = 1'b0;

          out_value = {sign_r,15'b0};

        end
        else begin

          if (prod_mant != 0)
            prod_top =
                prod_lsb +
                msb16(prod_mant);

          if (mant_c != 0)
            c_top =
                lsb_c +
                msb8(mant_c);

          if (prod_top > c_top)
            top_exp = prod_top;
          else
            top_exp = c_top;

          base_exp =
              top_exp -
              28;

          prod_aligned =
              align32(
                prod_mant,
                prod_lsb,
                base_exp
              );

          c_aligned =
              align32(
                {8'b0,mant_c},
                lsb_c,
                base_exp
              );

          prod_term =
              $signed({1'b0,prod_aligned});

          c_term =
              $signed({1'b0,c_aligned});

          if (sign_p)
            prod_term = -prod_term;

          if (sign_c)
            c_term = -c_term;

          exact_sum =
              prod_term +
              c_term;

          if (exact_sum == 0) begin

            if (rnd == 3'd2)
              sign_r = 1'b1;
            else
              sign_r = 1'b0;

            out_value = {sign_r,15'b0};

          end
          else begin

            sign_r = exact_sum[32];

            if (sign_r)
              magnitude =
                  (~exact_sum[31:0]) +
                  32'd1;
            else
              magnitude =
                  exact_sum[31:0];

            leading_bit =
                msb32(magnitude);

            exact_top_exp =
                base_exp +
                leading_bit;


            if (exact_top_exp >= -126) begin

              if (exact_top_exp > 127) begin

                out_value =
                    overflow_bf16(
                      sign_r,
                      rnd
                    );

                of = 1'b1;
                nx = 1'b1;

              end
              else begin

                unbiased_exp =
                    exact_top_exp;

                shift_amt =
                    leading_bit -
                    7;

                trunc_mag = 0;
                remainder = 0;
                mask = 0;
                half_ulp = 0;
                rem_nonzero = 1'b0;

                if (shift_amt <= 0) begin

                  trunc_mag =
                      magnitude <<
                      (-shift_amt);

                end
                else if (shift_amt < 32) begin

                  trunc_mag =
                      magnitude >>
                      shift_amt;

                  mask =
                      (32'd1 << shift_amt) -
                      32'd1;

                  remainder =
                      magnitude &
                      mask;

                  half_ulp =
                      32'd1 <<
                      (shift_amt - 1);

                  rem_nonzero =
                      (remainder != 0);

                end
                else begin

                  remainder = magnitude;
                  rem_nonzero = (magnitude != 0);

                end

                rounded_sig =
                    trunc_mag[8:0];

                round_increment = 1'b0;

                if (rem_nonzero) begin
                  case (rnd)

                    3'd0:
                      if (shift_amt < 32)
                        round_increment =
                            (remainder > half_ulp) ||
                            (
                              (remainder == half_ulp) &&
                              rounded_sig[0]
                            );

                    3'd1:
                      round_increment = 1'b0;

                    3'd2:
                      round_increment = sign_r;

                    3'd3:
                      round_increment = !sign_r;

                    3'd4:
                      if (shift_amt < 32)
                        round_increment =
                            remainder >= half_ulp;

                    default:
                      round_increment = 1'b0;

                  endcase
                end

                if (round_increment)
                  rounded_sig =
                      rounded_sig +
                      9'd1;

                if (rounded_sig[8]) begin

                  rounded_sig =
                      rounded_sig >> 1;

                  unbiased_exp =
                      unbiased_exp +
                      1;

                end

                if (unbiased_exp > 127) begin

                  out_value =
                      overflow_bf16(
                        sign_r,
                        rnd
                      );

                  of = 1'b1;
                  nx = 1'b1;

                end
                else begin

                  out_exp =
                      unbiased_exp +
                      127;

                  out_value = {
                    sign_r,
                    out_exp,
                    rounded_sig[6:0]
                  };

                  nx = rem_nonzero;

                end

              end

            end
            else begin

              /*
               * BF16 subnormal quantum = 2^-133.
               */
              shift_amt =
                  -133 -
                  base_exp;

              trunc_mag = 0;
              remainder = 0;
              mask = 0;
              half_ulp = 0;
              rem_nonzero = 1'b0;

              if (shift_amt <= 0) begin

                trunc_mag =
                    magnitude <<
                    (-shift_amt);

              end
              else if (shift_amt < 32) begin

                trunc_mag =
                    magnitude >>
                    shift_amt;

                mask =
                    (32'd1 << shift_amt) -
                    32'd1;

                remainder =
                    magnitude &
                    mask;

                half_ulp =
                    32'd1 <<
                    (shift_amt - 1);

                rem_nonzero =
                    (remainder != 0);

              end
              else begin

                remainder = magnitude;
                rem_nonzero = (magnitude != 0);

              end

              sub_sig =
                  trunc_mag[8:0];

              round_increment = 1'b0;

              if (rem_nonzero) begin
                case (rnd)

                  3'd0:
                    if (shift_amt < 32)
                      round_increment =
                          (remainder > half_ulp) ||
                          (
                            (remainder == half_ulp) &&
                            sub_sig[0]
                          );

                  3'd1:
                    round_increment = 1'b0;

                  3'd2:
                    round_increment = sign_r;

                  3'd3:
                    round_increment = !sign_r;

                  3'd4:
                    if (shift_amt < 32)
                      round_increment =
                          remainder >= half_ulp;

                  default:
                    round_increment = 1'b0;

                endcase
              end

              if (round_increment)
                sub_sig =
                    sub_sig +
                    9'd1;

              if (sub_sig >= 9'd128) begin

                out_value = {
                  sign_r,
                  8'h01,
                  7'b0
                };

                nx = rem_nonzero;
                uf = 1'b0;

              end
              else begin

                out_value = {
                  sign_r,
                  8'h00,
                  sub_sig[6:0]
                };

                nx = rem_nonzero;
                uf = rem_nonzero;

              end

            end

          end

        end

      end

      fma_bf16 = {
        nv,
        1'b0,
        of,
        uf,
        nx,
        out_value
      };

    end
  endfunction


  /*
   * ==========================================================================
   * Physical lane FMA results
   *
   * Loop/generate bounds are compile-time constants as required by T5.
   * ==========================================================================
   */

  logic [36:0] fp32_lane [0:(WIDTH/32)-1];
  logic [20:0] fp16_lane [0:(WIDTH/16)-1];
  logic [20:0] bf16_lane [0:(WIDTH/16)-1];

  genvar g32;
  genvar g16;

  generate

    for (g32 = 0; g32 < WIDTH/32; g32 = g32 + 1) begin : GEN_FP32

      assign fp32_lane[g32] =
          fma_fp32(
            a_i[g32*32 +: 32],
            b_i[g32*32 +: 32],
            c_i[g32*32 +: 32],
            rnd_i
          );

    end


    for (g16 = 0; g16 < WIDTH/16; g16 = g16 + 1) begin : GEN_FP16_BF16

      assign fp16_lane[g16] =
          fma_fp16(
            a_i[g16*16 +: 16],
            b_i[g16*16 +: 16],
            c_i[g16*16 +: 16],
            rnd_i
          );

      assign bf16_lane[g16] =
          fma_bf16(
            a_i[g16*16 +: 16],
            b_i[g16*16 +: 16],
            c_i[g16*16 +: 16],
            rnd_i
          );

    end

  endgenerate


  /*
   * ==========================================================================
   * Lane packing
   * ==========================================================================
   */

  logic [WIDTH-1:0] result_calc;
  logic [4:0]       flags_calc;

  always_comb begin : lane_pack
    integer k;

    /*
     * V3: bits above active scalar lanes are ones.
     */
    result_calc = '1;
    flags_calc  = 5'b00000;

    case (fmt_i)

      /*
       * FP32
       */
      2'd0: begin

        for (k = 0; k < WIDTH/32; k = k + 1) begin

          if (vec_i || (k == 0)) begin

            result_calc[k*32 +: 32] =
                fp32_lane[k][31:0];

            flags_calc =
                flags_calc |
                fp32_lane[k][36:32];

          end

        end

      end


      /*
       * FP16
       */
      2'd1: begin

        for (k = 0; k < WIDTH/16; k = k + 1) begin

          if (vec_i || (k == 0)) begin

            result_calc[k*16 +: 16] =
                fp16_lane[k][15:0];

            flags_calc =
                flags_calc |
                fp16_lane[k][20:16];

          end

        end

      end


      /*
       * BF16
       */
      2'd2: begin

        for (k = 0; k < WIDTH/16; k = k + 1) begin

          if (vec_i || (k == 0)) begin

            result_calc[k*16 +: 16] =
                bf16_lane[k][15:0];

            flags_calc =
                flags_calc |
                bf16_lane[k][20:16];

          end

        end

      end


      default: begin

        result_calc = '1;
        flags_calc  = 5'b00000;

      end

    endcase

  end


  /*
   * ==========================================================================
   * One-entry elastic output stage
   *
   * Latency and throughput are deliberately left free by L2/L3, so this keeps
   * the implementation small while preserving all required handshake behavior.
   *
   * in_ready_o:
   *   depends on output occupancy / out_ready_i
   *   does NOT depend on in_valid_i.
   *
   * out_valid_o:
   *   is registered
   *   does NOT depend combinationally on out_ready_i.
   * ==========================================================================
   */

  logic             out_valid_q;
  logic [WIDTH-1:0] result_q;
  logic [4:0]       flags_q;

  logic accept_in;

  always_comb begin

    in_ready_o =
        rst_ni &&
        (
          !out_valid_q ||
          out_ready_i
        );

    accept_in =
        in_valid_i &&
        in_ready_o;

    out_valid_o =
        rst_ni &&
        out_valid_q;

    result_o =
        result_q;

    flags_o =
        flags_q;

  end


  always_ff @(posedge clk_i or negedge rst_ni) begin

    if (!rst_ni) begin

      out_valid_q <= 1'b0;
      result_q    <= '1;
      flags_q     <= 5'b00000;

    end
    else begin

      if (
          out_valid_q &&
          out_ready_i
      )
        out_valid_q <= 1'b0;


      /*
       * A new accepted operation may replace a result consumed on the same
       * edge, allowing one result per cycle when the sink stays ready.
       */
      if (accept_in) begin

        out_valid_q <= 1'b1;
        result_q    <= result_calc;
        flags_q     <= flags_calc;

      end

    end

  end

endmodule