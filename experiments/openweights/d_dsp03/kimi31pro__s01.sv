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

  // The extra bit returned by the shifter is the OR of all discarded bits.
  function automatic logic [96:0] shr_sticky96(
    input logic [95:0] x,
    input integer      sh
  );
    logic [95:0] y;
    logic        st;
    integer      i;
    begin
      y  = 96'b0;
      st = 1'b0;
      if (sh <= 0)
        y = x;
      else if (sh < 96)
        y = x >> sh;
      for (i = 0; i < 96; i = i + 1)
        if (i < sh)
          st = st | x[i];
      shr_sticky96 = {st, y};
    end
  endfunction

  // Bits [31:0] are the lane result and bits [36:32] are its flags.
  function automatic logic [36:0] do_fma(
    input logic [31:0] a,
    input logic [31:0] b,
    input logic [31:0] c,
    input logic [1:0]  fmt,
    input logic [2:0]  rnd
  );
    integer p;
    integer exp_bits;
    integer bias;
    integer emin;
    integer emax;
    integer exp_all_ones;
    integer ae_raw;
    integer be_raw;
    integer ce_raw;
    integer ea;
    integer eb;
    integer ec;
    integer tp;
    integer tc;
    integer bp;
    integer bc;
    integer base;
    integer delta;
    integer ep;
    integer ec_lead;
    integer msb_prod;
    integer msb_c;
    integer msb;
    integer sh;
    integer e_res;
    integer i;

    logic [22:0] af;
    logic [22:0] bf;
    logic [22:0] cf;
    logic        sa;
    logic        sb;
    logic        sc;
    logic        sp;
    logic        sum_sign;
    logic        zero_sign;

    logic a_zero;
    logic b_zero;
    logic a_inf;
    logic b_inf;
    logic c_inf;
    logic a_nan;
    logic b_nan;
    logic c_nan;
    logic a_snan;
    logic b_snan;
    logic c_snan;

    logic [95:0] siga;
    logic [95:0] sigb;
    logic [95:0] sigc;
    logic [47:0] prod_short;
    logic [95:0] prod;
    logic [95:0] ap;
    logic [95:0] ac;
    logic [95:0] sum;
    logic [95:0] kept;
    logic [95:0] rounded;
    logic [96:0] shifted;

    logic align_sticky;
    logic guard_bit;
    logic sticky_bit;
    logic increment;
    logic inexact;
    logic normal_path;

    logic [31:0] rr;
    logic [31:0] nan_res;
    logic [4:0]  fl;

    begin
      p            = 24;
      exp_bits     = 8;
      bias         = 127;
      emin         = -126;
      emax         = 127;
      exp_all_ones = 255;
      nan_res      = 32'h7fc00000;

      case (fmt)
        2'd1: begin
          p            = 11;
          exp_bits     = 5;
          bias         = 15;
          emin         = -14;
          emax         = 15;
          exp_all_ones = 31;
          nan_res      = 32'h00007e00;
        end
        2'd2: begin
          p            = 8;
          exp_bits     = 8;
          bias         = 127;
          emin         = -126;
          emax         = 127;
          exp_all_ones = 255;
          nan_res      = 32'h00007fc0;
        end
        default: begin
        end
      endcase

      sa = 1'b0;
      sb = 1'b0;
      sc = 1'b0;
      ae_raw = 0;
      be_raw = 0;
      ce_raw = 0;
      af = 23'b0;
      bf = 23'b0;
      cf = 23'b0;

      case (fmt)
        2'd0: begin
          sa = a[31];
          sb = b[31];
          sc = c[31];
          ae_raw = a[30:23];
          be_raw = b[30:23];
          ce_raw = c[30:23];
          af = a[22:0];
          bf = b[22:0];
          cf = c[22:0];
        end
        2'd1: begin
          sa = a[15];
          sb = b[15];
          sc = c[15];
          ae_raw = a[14:10];
          be_raw = b[14:10];
          ce_raw = c[14:10];
          af = {13'b0, a[9:0]};
          bf = {13'b0, b[9:0]};
          cf = {13'b0, c[9:0]};
        end
        default: begin
          sa = a[15];
          sb = b[15];
          sc = c[15];
          ae_raw = a[14:7];
          be_raw = b[14:7];
          ce_raw = c[14:7];
          af = {16'b0, a[6:0]};
          bf = {16'b0, b[6:0]};
          cf = {16'b0, c[6:0]};
        end
      endcase

      a_zero = (ae_raw == 0) && (af == 0);
      b_zero = (be_raw == 0) && (bf == 0);
      a_inf  = (ae_raw == exp_all_ones) && (af == 0);
      b_inf  = (be_raw == exp_all_ones) && (bf == 0);
      c_inf  = (ce_raw == exp_all_ones) && (cf == 0);
      a_nan  = (ae_raw == exp_all_ones) && (af != 0);
      b_nan  = (be_raw == exp_all_ones) && (bf != 0);
      c_nan  = (ce_raw == exp_all_ones) && (cf != 0);
      a_snan = a_nan && !af[p-2];
      b_snan = b_nan && !bf[p-2];
      c_snan = c_nan && !cf[p-2];

      rr = 32'b0;
      fl = 5'b0;
      sp = sa ^ sb;
      sum_sign = 1'b0;

      // Invalid multiplication has priority over a quiet-NaN addend.
      if (((a_inf || b_inf) && (a_zero || b_zero)) ||
          a_snan || b_snan || c_snan) begin
        rr = nan_res;
        fl[4] = 1'b1;
      end else if (a_nan || b_nan || c_nan) begin
        rr = nan_res;
      end else if (a_inf || b_inf) begin
        if (c_inf && (sc != sp)) begin
          rr = nan_res;
          fl[4] = 1'b1;
        end else begin
          case (fmt)
            2'd0: rr = sp ? 32'hff800000 : 32'h7f800000;
            2'd1: rr = sp ? 32'h0000fc00 : 32'h00007c00;
            default: rr = sp ? 32'h0000ff80 : 32'h00007f80;
          endcase
        end
      end else if (c_inf) begin
        case (fmt)
          2'd0: rr = sc ? 32'hff800000 : 32'h7f800000;
          2'd1: rr = sc ? 32'h0000fc00 : 32'h00007c00;
          default: rr = sc ? 32'h0000ff80 : 32'h00007f80;
        endcase
      end else begin
        // Finite operands: value = significand * 2^(e-(p-1)).
        ea = (ae_raw == 0) ? (1 - bias) : (ae_raw - bias);
        eb = (be_raw == 0) ? (1 - bias) : (be_raw - bias);
        ec = (ce_raw == 0) ? (1 - bias) : (ce_raw - bias);

        siga = 96'b0;
        sigb = 96'b0;
        sigc = 96'b0;
        siga[22:0] = af;
        sigb[22:0] = bf;
        sigc[22:0] = cf;
        if (ae_raw != 0)
          siga[p-1] = 1'b1;
        if (be_raw != 0)
          sigb[p-1] = 1'b1;
        if (ce_raw != 0)
          sigc[p-1] = 1'b1;

        prod_short = siga[23:0] * sigb[23:0];
        prod = {48'b0, prod_short};

        if (prod == 0) begin
          if (sigc == 0) begin
            zero_sign = (sp == sc) ? sp : (rnd == 3'd2);
            case (fmt)
              2'd0: rr = zero_sign ? 32'h80000000 : 32'h00000000;
              2'd1: rr = zero_sign ? 32'h00008000 : 32'h00000000;
              default: rr = zero_sign ? 32'h00008000 : 32'h00000000;
            endcase
          end else begin
            // Adding a zero product to an already representable value is exact.
            rr = c;
          end
        end else begin
          tp = ea + eb - 2*(p-1);
          tc = ec - (p-1);

          // Normalize both nonzero terms to bit 94. Bit 95 is carry headroom.
          msb_prod = 0;
          for (i = 0; i < 96; i = i + 1)
            if (prod[i])
              msb_prod = i;

          ap = prod << (94 - msb_prod);
          bp = tp - (94 - msb_prod);
          ep = tp + msb_prod;

          ac = 96'b0;
          bc = 0;
          ec_lead = 0;
          if (sigc != 0) begin
            msb_c = 0;
            for (i = 0; i < 96; i = i + 1)
              if (sigc[i])
                msb_c = i;
            ac = sigc << (94 - msb_c);
            bc = tc - (94 - msb_c);
            ec_lead = tc + msb_c;
          end

          align_sticky = 1'b0;
          base = bp;
          if (sigc != 0) begin
            if (ep >= ec_lead) begin
              base = bp;
              delta = bp - bc;
              shifted = shr_sticky96(ac, delta);
              ac = shifted[95:0];
              align_sticky = shifted[96];
            end else begin
              base = bc;
              delta = bc - bp;
              shifted = shr_sticky96(ap, delta);
              ap = shifted[95:0];
              align_sticky = shifted[96];
            end
          end

          if (sp == sc) begin
            sum = ap + ac;
            sum_sign = sp;
          end else if (ap > ac) begin
            sum = ap - ac;
            sum_sign = sp;
            if (align_sticky)
              sum = sum - 1'b1;
          end else begin
            sum = ac - ap;
            sum_sign = sc;
            if (align_sticky)
              sum = sum - 1'b1;
          end

          if ((sum == 0) && !align_sticky) begin
            zero_sign = (sp == sc) ? sp : (rnd == 3'd2);
            case (fmt)
              2'd0: rr = zero_sign ? 32'h80000000 : 32'h00000000;
              2'd1: rr = zero_sign ? 32'h00008000 : 32'h00000000;
              default: rr = zero_sign ? 32'h00008000 : 32'h00000000;
            endcase
          end else begin
            msb = 0;
            for (i = 0; i < 96; i = i + 1)
              if (sum[i])
                msb = i;

            e_res = base + msb;
            normal_path = (e_res >= emin);

            if (normal_path)
              sh = msb - p + 1;
            else
              sh = emin - (p-1) - base;

            kept = 96'b0;
            guard_bit = 1'b0;
            sticky_bit = align_sticky;

            if (sh > 0) begin
              if (sh < 96)
                kept = sum >> sh;
              else
                kept = 96'b0;

              if (sh <= 96)
                guard_bit = sum[sh-1];

              for (i = 0; i < 96; i = i + 1)
                if (i < (sh-1))
                  sticky_bit = sticky_bit | sum[i];
            end else begin
              kept = sum << (-sh);
            end

            case (rnd)
              3'd0: increment = guard_bit && (sticky_bit || kept[0]);
              3'd1: increment = 1'b0;
              3'd2: increment = sum_sign && (guard_bit || sticky_bit);
              3'd3: increment = !sum_sign && (guard_bit || sticky_bit);
              default: increment = guard_bit;
            endcase

            inexact = guard_bit || sticky_bit;
            rounded = kept;
            if (increment)
              rounded = kept + 1'b1;

            if (normal_path) begin
              if (rounded[p]) begin
                rounded = rounded >> 1;
                e_res = e_res + 1;
              end

              if (e_res > emax) begin
                fl[2] = 1'b1;
                fl[0] = 1'b1;
                if ((rnd == 3'd0) || (rnd == 3'd4) ||
                    ((rnd == 3'd3) && !sum_sign) ||
                    ((rnd == 3'd2) && sum_sign)) begin
                  case (fmt)
                    2'd0: rr = sum_sign ? 32'hff800000 : 32'h7f800000;
                    2'd1: rr = sum_sign ? 32'h0000fc00 : 32'h00007c00;
                    default: rr = sum_sign ? 32'h0000ff80 : 32'h00007f80;
                  endcase
                end else begin
                  case (fmt)
                    2'd0: rr = sum_sign ? 32'hff7fffff : 32'h7f7fffff;
                    2'd1: rr = sum_sign ? 32'h0000fbff : 32'h00007bff;
                    default: rr = sum_sign ? 32'h0000ff7f : 32'h00007f7f;
                  endcase
                end
              end else begin
                case (fmt)
                  2'd0: begin
                    rr = 32'b0;
                    rr[31] = sum_sign;
                    rr[30:23] = e_res + bias;
                    rr[22:0] = rounded[22:0];
                  end
                  2'd1: begin
                    rr = 32'b0;
                    rr[15] = sum_sign;
                    rr[14:10] = e_res + bias;
                    rr[9:0] = rounded[9:0];
                  end
                  default: begin
                    rr = 32'b0;
                    rr[15] = sum_sign;
                    rr[14:7] = e_res + bias;
                    rr[6:0] = rounded[6:0];
                  end
                endcase
                fl[0] = inexact;
              end
            end else begin
              case (fmt)
                2'd0: begin
                  rr = 32'b0;
                  rr[31] = sum_sign;
                  if (rounded[p-1])
                    rr[30:23] = 8'd1;
                  else
                    rr[22:0] = rounded[22:0];
                end
                2'd1: begin
                  rr = 32'b0;
                  rr[15] = sum_sign;
                  if (rounded[p-1])
                    rr[14:10] = 5'd1;
                  else
                    rr[9:0] = rounded[9:0];
                end
                default: begin
                  rr = 32'b0;
                  rr[15] = sum_sign;
                  if (rounded[p-1])
                    rr[14:7] = 8'd1;
                  else
                    rr[6:0] = rounded[6:0];
                end
              endcase
              fl[0] = inexact;
              if (inexact && !rounded[p-1])
                fl[1] = 1'b1;
            end
          end
        end
      end

      do_fma = {fl, rr};
    end
  endfunction

  integer k;
  logic [36:0] lane;
  logic [31:0] aa;
  logic [31:0] bb;
  logic [31:0] cc;

  always_comb begin
    result_o = {WIDTH{1'b1}};
    flags_o  = 5'b0;
    lane     = 37'b0;
    aa       = 32'b0;
    bb       = 32'b0;
    cc       = 32'b0;

    for (k = 0; k < WIDTH/32; k = k + 1) begin
      if ((fmt_i == 2'd0) && (vec_i || (k == 0))) begin
        lane = do_fma(a_i[k*32 +: 32],
                      b_i[k*32 +: 32],
                      c_i[k*32 +: 32],
                      fmt_i, rnd_i);
        result_o[k*32 +: 32] = lane[31:0];
        flags_o = flags_o | lane[36:32];
      end
    end

    for (k = 0; k < WIDTH/16; k = k + 1) begin
      if ((fmt_i != 2'd0) && (vec_i || (k == 0))) begin
        aa = {16'b0, a_i[k*16 +: 16]};
        bb = {16'b0, b_i[k*16 +: 16]};
        cc = {16'b0, c_i[k*16 +: 16]};
        lane = do_fma(aa, bb, cc, fmt_i, rnd_i);
        result_o[k*16 +: 16] = lane[15:0];
        flags_o = flags_o | lane[36:32];
      end
    end
  end

  assign out_valid_o = in_valid_i;
  assign in_ready_o  = out_ready_i;

endmodule
