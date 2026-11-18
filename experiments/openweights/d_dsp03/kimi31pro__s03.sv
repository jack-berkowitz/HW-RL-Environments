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

  // The arithmetic window is 4*p bits: 96, 44, or 32 bits depending on
  // the selected format.  The 96-bit objects merely provide the maximum
  // storage; bits above the active window are never used.
  function automatic logic [36:0] fma_lane (
    input logic [31:0] op_a,
    input logic [31:0] op_b,
    input logic [31:0] op_c,
    input logic [1:0]  fmt,
    input logic [2:0]  rnd
  );
    logic [31:0] res;
    logic nv, of, uf, nx;

    logic sa, sb, sc, sp;
    integer p, exp_bits, mant_bits, bias;
    integer emin, emax, qsub, window;
    integer expa, expb, expc;
    integer ea, eb, ec;
    logic [22:0] frac_a, frac_b, frac_c;

    logic exp_all_a, exp_all_b, exp_all_c;
    logic a_nan, b_nan, c_nan;
    logic a_snan, b_snan, c_snan;
    logic a_inf, b_inf, c_inf;
    logic a_zero, b_zero, c_zero;
    logic any_nan, any_snan, zero_inf, product_inf;

    logic [23:0] ma, mb, mc;
    logic [47:0] prod;
    integer hp, hc;
    integer e_prod, e_c, e_max, diff;

    logic [95:0] norm_prod, norm_c;
    logic [95:0] large_sig, small_full, small_sig;
    logic [95:0] r_sig, low_mask;
    logic sticky_bit;
    logic sign_large, sign_small;
    logic exact_zero, res_sign;

    integer scale, h, e_res, sh;
    integer exp_work, expfield;
    logic [95:0] kept_sig, rounded_sig;
    logic guard_bit, rest_bit, inexact_bit, round_inc;
    logic [22:0] frac_out;
    logic overflow_to_inf;

    integer i;

    begin
      res = 32'b0;
      nv  = 1'b0;
      of  = 1'b0;
      uf  = 1'b0;
      nx  = 1'b0;

      // FP32 defaults; the two 16-bit formats override all geometry.
      p         = 24;
      exp_bits  = 8;
      mant_bits = 23;
      bias      = 127;
      emin      = -126;
      emax      = 127;
      window    = 96;

      sa = op_a[31];
      sb = op_b[31];
      sc = op_c[31];
      expa = op_a[30:23];
      expb = op_b[30:23];
      expc = op_c[30:23];
      frac_a = op_a[22:0];
      frac_b = op_b[22:0];
      frac_c = op_c[22:0];

      case (fmt)
        2'd1: begin
          p         = 11;
          exp_bits  = 5;
          mant_bits = 10;
          bias      = 15;
          emin      = -14;
          emax      = 15;
          window    = 44;

          sa = op_a[15];
          sb = op_b[15];
          sc = op_c[15];
          expa = op_a[14:10];
          expb = op_b[14:10];
          expc = op_c[14:10];
          frac_a = {13'b0, op_a[9:0]};
          frac_b = {13'b0, op_b[9:0]};
          frac_c = {13'b0, op_c[9:0]};
        end

        2'd2: begin
          p         = 8;
          exp_bits  = 8;
          mant_bits = 7;
          bias      = 127;
          emin      = -126;
          emax      = 127;
          window    = 32;

          sa = op_a[15];
          sb = op_b[15];
          sc = op_c[15];
          expa = op_a[14:7];
          expb = op_b[14:7];
          expc = op_c[14:7];
          frac_a = {16'b0, op_a[6:0]};
          frac_b = {16'b0, op_b[6:0]};
          frac_c = {16'b0, op_c[6:0]};
        end

        default: begin
        end
      endcase

      qsub = emin - (p - 1);
      sp = sa ^ sb;

      exp_all_a = (expa == ((1 << exp_bits) - 1));
      exp_all_b = (expb == ((1 << exp_bits) - 1));
      exp_all_c = (expc == ((1 << exp_bits) - 1));

      a_nan  = exp_all_a && (frac_a != 0);
      b_nan  = exp_all_b && (frac_b != 0);
      c_nan  = exp_all_c && (frac_c != 0);
      a_snan = a_nan && !frac_a[mant_bits-1];
      b_snan = b_nan && !frac_b[mant_bits-1];
      c_snan = c_nan && !frac_c[mant_bits-1];

      a_inf  = exp_all_a && (frac_a == 0);
      b_inf  = exp_all_b && (frac_b == 0);
      c_inf  = exp_all_c && (frac_c == 0);
      a_zero = (expa == 0) && (frac_a == 0);
      b_zero = (expb == 0) && (frac_b == 0);
      c_zero = (expc == 0) && (frac_c == 0);

      any_nan  = a_nan || b_nan || c_nan;
      any_snan = a_snan || b_snan || c_snan;
      zero_inf = (a_zero && b_inf) || (a_inf && b_zero);
      product_inf = a_inf || b_inf;

      ma = 24'b0;
      mb = 24'b0;
      mc = 24'b0;
      ea = qsub;
      eb = qsub;
      ec = qsub;
      prod = 48'b0;

      norm_prod = 96'b0;
      norm_c = 96'b0;
      large_sig = 96'b0;
      small_full = 96'b0;
      small_sig = 96'b0;
      r_sig = 96'b0;
      low_mask = 96'b0;
      sticky_bit = 1'b0;
      sign_large = 1'b0;
      sign_small = 1'b0;
      exact_zero = 1'b0;
      res_sign = 1'b0;

      kept_sig = 96'b0;
      rounded_sig = 96'b0;
      guard_bit = 1'b0;
      rest_bit = 1'b0;
      inexact_bit = 1'b0;
      round_inc = 1'b0;
      frac_out = 23'b0;
      expfield = 0;
      overflow_to_inf = 1'b0;

      if (any_snan || zero_inf ||
          (!any_nan && product_inf && c_inf && (sp != sc))) begin
        nv = 1'b1;
        case (fmt)
          2'd0: res = 32'h7FC00000;
          2'd1: res = {16'b0, 16'h7E00};
          default: res = {16'b0, 16'h7FC0};
        endcase
      end
      else if (any_nan) begin
        case (fmt)
          2'd0: res = 32'h7FC00000;
          2'd1: res = {16'b0, 16'h7E00};
          default: res = {16'b0, 16'h7FC0};
        endcase
      end
      else if (product_inf || c_inf) begin
        res_sign = product_inf ? sp : sc;
        case (fmt)
          2'd0: res = {res_sign, 8'hFF, 23'b0};
          2'd1: res = {16'b0, res_sign, 5'h1F, 10'b0};
          default: res = {16'b0, res_sign, 8'hFF, 7'b0};
        endcase
      end
      else begin
        // Finite operands: value = significand * 2^exponent, including
        // subnormals, without any flushing.
        if (expa == 0) begin
          ma = {1'b0, frac_a};
          ea = qsub;
        end
        else begin
          ma = (24'd1 << (p-1)) | {1'b0, frac_a};
          ea = expa - bias - (p-1);
        end

        if (expb == 0) begin
          mb = {1'b0, frac_b};
          eb = qsub;
        end
        else begin
          mb = (24'd1 << (p-1)) | {1'b0, frac_b};
          eb = expb - bias - (p-1);
        end

        if (expc == 0) begin
          mc = {1'b0, frac_c};
          ec = qsub;
        end
        else begin
          mc = (24'd1 << (p-1)) | {1'b0, frac_c};
          ec = expc - bias - (p-1);
        end

        prod = {24'b0, ma} * mb;

        hp = 0;
        for (i = 0; i < 48; i = i + 1)
          if (prod[i])
            hp = i;

        hc = 0;
        for (i = 0; i < 24; i = i + 1)
          if (mc[i])
            hc = i;

        e_prod = ea + eb + hp;
        e_c = ec + hc;

        norm_prod = {48'b0, prod} << (window - 2 - hp);
        norm_c = {72'b0, mc} << (window - 2 - hc);

        if ((prod == 0) && (mc == 0)) begin
          // Both terms are zero.  Opposite-signed zeros differ from a
          // cancellation only in that a common sign is always retained.
          res_sign = (sp == sc) ? sp : (rnd == 3'd2);
          res = 32'b0;
          if (fmt == 2'd0)
            res[31] = res_sign;
          else
            res[15] = res_sign;
        end
        else begin
          if (prod == 0) begin
            r_sig = norm_c;
            e_max = e_c;
            res_sign = sc;
            sticky_bit = 1'b0;
          end
          else if (mc == 0) begin
            r_sig = norm_prod;
            e_max = e_prod;
            res_sign = sp;
            sticky_bit = 1'b0;
          end
          else begin
            // Align the smaller term against the larger term.  Bits below
            // the active 4*p-bit window are collapsed into sticky_bit.
            if (e_prod > e_c) begin
              e_max = e_prod;
              diff = e_prod - e_c;
              large_sig = norm_prod;
              small_full = norm_c;
              sign_large = sp;
              sign_small = sc;
            end
            else if (e_c > e_prod) begin
              e_max = e_c;
              diff = e_c - e_prod;
              large_sig = norm_c;
              small_full = norm_prod;
              sign_large = sc;
              sign_small = sp;
            end
            else begin
              e_max = e_prod;
              diff = 0;
              if (norm_c > norm_prod) begin
                large_sig = norm_c;
                small_full = norm_prod;
                sign_large = sc;
                sign_small = sp;
              end
              else begin
                large_sig = norm_prod;
                small_full = norm_c;
                sign_large = sp;
                sign_small = sc;
              end
            end

            sticky_bit = 1'b0;
            if (diff == 0) begin
              small_sig = small_full;
            end
            else if (diff >= window) begin
              small_sig = 96'b0;
              sticky_bit = (small_full != 0);
            end
            else begin
              small_sig = small_full >> diff;
              low_mask = (96'd1 << diff) - 96'd1;
              sticky_bit = ((small_full & low_mask) != 0);
            end

            res_sign = sign_large;
            if (sign_large == sign_small) begin
              r_sig = large_sig + small_sig;
            end
            else if ((large_sig == small_sig) && !sticky_bit) begin
              exact_zero = 1'b1;
            end
            else begin
              r_sig = large_sig - small_sig;

              // For subtraction, the truncated small term is L-(S+f).
              // Rewriting this as (L-S-1)+(1-f) leaves a magnitude with
              // an ordinary positive sticky fraction below bit zero.
              if (sticky_bit)
                r_sig = r_sig - 96'd1;
            end
          end

          if (exact_zero) begin
            res_sign = (rnd == 3'd2);
            res = 32'b0;
            if (fmt == 2'd0)
              res[31] = res_sign;
            else
              res[15] = res_sign;
          end
          else begin
            scale = e_max - (window - 2);

            h = 0;
            for (i = 0; i < 96; i = i + 1)
              if (r_sig[i])
                h = i;

            e_res = scale + h;

            if (e_res >= emin)
              sh = h - (p-1);
            else
              sh = qsub - scale;

            kept_sig = 96'b0;
            guard_bit = 1'b0;
            rest_bit = 1'b0;
            low_mask = 96'b0;

            if (sh <= 0) begin
              kept_sig = r_sig << (-sh);
              rest_bit = sticky_bit;
            end
            else if (sh < window) begin
              kept_sig = r_sig >> sh;
              guard_bit = r_sig[sh-1];
              low_mask = (96'd1 << (sh-1)) - 96'd1;
              rest_bit = sticky_bit | ((r_sig & low_mask) != 0);
            end
            else if (sh == window) begin
              kept_sig = 96'b0;
              guard_bit = r_sig[window-1];
              low_mask = (96'd1 << (window-1)) - 96'd1;
              rest_bit = sticky_bit | ((r_sig & low_mask) != 0);
            end
            else begin
              kept_sig = 96'b0;
              guard_bit = 1'b0;
              rest_bit = sticky_bit | (r_sig != 0);
            end

            inexact_bit = guard_bit | rest_bit;
            nx = inexact_bit;

            case (rnd)
              3'd0: round_inc = guard_bit &&
                                (rest_bit || kept_sig[0]);
              3'd1: round_inc = 1'b0;
              3'd2: round_inc = res_sign && inexact_bit;
              3'd3: round_inc = !res_sign && inexact_bit;
              3'd4: round_inc = guard_bit;
              default: round_inc = 1'b0;
            endcase

            rounded_sig = kept_sig + (round_inc ? 96'd1 : 96'd0);
            exp_work = e_res;
            expfield = 0;
            frac_out = 23'b0;

            if (e_res >= emin) begin
              if (rounded_sig >= (96'd1 << p)) begin
                rounded_sig = rounded_sig >> 1;
                exp_work = exp_work + 1;
              end

              if (exp_work > emax) begin
                of = 1'b1;
              end
              else begin
                expfield = exp_work + bias;
                frac_out = rounded_sig - (96'd1 << (p-1));
              end
            end
            else begin
              if (rounded_sig >= (96'd1 << (p-1))) begin
                expfield = 1;
                frac_out = rounded_sig - (96'd1 << (p-1));
              end
              else begin
                expfield = 0;
                frac_out = rounded_sig;
              end
            end

            if (of) begin
              nx = 1'b1;
              case (rnd)
                3'd0, 3'd4: overflow_to_inf = 1'b1;
                3'd1:       overflow_to_inf = 1'b0;
                3'd2:       overflow_to_inf = res_sign;
                3'd3:       overflow_to_inf = !res_sign;
                default:    overflow_to_inf = 1'b1;
              endcase

              if (overflow_to_inf) begin
                case (fmt)
                  2'd0: res = {res_sign, 8'hFF, 23'b0};
                  2'd1: res = {16'b0, res_sign, 5'h1F, 10'b0};
                  default: res = {16'b0, res_sign, 8'hFF, 7'b0};
                endcase
              end
              else begin
                case (fmt)
                  2'd0: res = {res_sign, 8'hFE, 23'h7FFFFF};
                  2'd1: res = {16'b0, res_sign, 5'h1E, 10'h3FF};
                  default: res = {16'b0, res_sign, 8'hFE, 7'h7F};
                endcase
              end
            end
            else begin
              res = 32'b0;
              case (fmt)
                2'd0: begin
                  res[31] = res_sign;
                  res[30:23] = expfield;
                  res[22:0] = frac_out;
                end
                2'd1: begin
                  res[15] = res_sign;
                  res[14:10] = expfield;
                  res[9:0] = frac_out[9:0];
                end
                default: begin
                  res[15] = res_sign;
                  res[14:7] = expfield;
                  res[6:0] = frac_out[6:0];
                end
              endcase

              // Tininess is tested on the delivered encoding.
              uf = nx && (expfield == 0);
            end
          end
        end
      end

      fma_lane = {nv, 1'b0, of, uf, nx, res};
    end
  endfunction

  logic [36:0] lane_tmp;
  integer k;

  always_comb begin
    result_o = {WIDTH{1'b1}};
    flags_o = 5'b0;
    lane_tmp = 37'b0;

    if (fmt_i == 2'd0) begin
      for (k = 0; k < WIDTH/32; k = k + 1) begin
        if (k < (vec_i ? WIDTH/32 : 1)) begin
          lane_tmp = fma_lane(a_i[k*32 +: 32],
                              b_i[k*32 +: 32],
                              c_i[k*32 +: 32],
                              fmt_i, rnd_i);
          result_o[k*32 +: 32] = lane_tmp[31:0];
          flags_o = flags_o | lane_tmp[36:32];
        end
      end
    end
    else if ((fmt_i == 2'd1) || (fmt_i == 2'd2)) begin
      for (k = 0; k < WIDTH/16; k = k + 1) begin
        if (k < (vec_i ? WIDTH/16 : 1)) begin
          lane_tmp = fma_lane({16'b0, a_i[k*16 +: 16]},
                              {16'b0, b_i[k*16 +: 16]},
                              {16'b0, c_i[k*16 +: 16]},
                              fmt_i, rnd_i);
          result_o[k*16 +: 16] = lane_tmp[15:0];
          flags_o = flags_o | lane_tmp[36:32];
        end
      end
    end
  end

  // A combinational implementation obeys the same stable-valid transfer
  // rules while permitting one operation per cycle.
  assign out_valid_o = in_valid_i;
  assign in_ready_o = out_ready_i;

endmodule
