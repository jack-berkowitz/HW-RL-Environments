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

  logic [36:0] lane_tmp;
  integer k;

  function automatic logic [96:0] shift_jam96(
    input logic [95:0] x,
    input integer      d
  );
    logic [95:0] y;
    logic        lost;
    logic [95:0] mask;
    begin
      y    = 96'd0;
      lost = 1'b0;
      mask = 96'd0;

      if (d <= 0) begin
        y = x;
      end else if (d < 96) begin
        y    = x >> d;
        mask = (96'd1 << d) - 96'd1;
        lost = |(x & mask);
        if (lost)
          y[0] = 1'b1;
      end else begin
        lost = |x;
        y    = 96'd0;
        y[0] = lost;
      end

      shift_jam96 = {lost, y};
    end
  endfunction

  function automatic logic [36:0] fma_lane(
    input logic [31:0] a,
    input logic [31:0] b,
    input logic [31:0] c,
    input logic [1:0]  fmt,
    input logic [2:0]  rnd
  );
    integer p;
    integer mantbits;
    integer expbits;
    integer bias;
    integer emin;
    integer emax;
    integer signpos;

    integer a_exp;
    integer b_exp;
    integer c_exp;
    logic [22:0] a_mant;
    logic [22:0] b_mant;
    logic [22:0] c_mant;
    logic [23:0] a_sig;
    logic [23:0] b_sig;
    logic [23:0] c_sig;
    integer a_esig;
    integer b_esig;
    integer c_esig;

    logic sa;
    logic sb;
    logic sc;
    logic sp;
    logic signr;

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
    logic product_inf;
    logic invalid;

    logic [47:0] product;
    logic [95:0] x;
    logic [95:0] y;
    logic [95:0] s;
    logic [95:0] q;
    logic [95:0] rounded;
    logic [96:0] shifted;

    integer ep;
    integer ec;
    integer ebase;
    integer diff;
    integer eb;
    integer h;
    integer un;
    integer sh;
    integer i;

    logic alignment_lost;
    logic guard_bit;
    logic sticky_bit;
    logic inexact;
    logic increment;
    logic overflow;
    logic to_infinity;

    logic [31:0] res;
    logic [31:0] tmp32;
    logic [4:0]  fl;

    begin
      res = 32'd0;
      fl  = 5'd0;

      if (fmt == 2'd0) begin
        p        = 24;
        mantbits = 23;
        expbits  = 8;
        bias     = 127;
        emin     = -126;
        emax     = 127;
        signpos  = 31;

        sa     = a[31];
        sb     = b[31];
        sc     = c[31];
        a_exp  = a[30:23];
        b_exp  = b[30:23];
        c_exp  = c[30:23];
        a_mant = a[22:0];
        b_mant = b[22:0];
        c_mant = c[22:0];

        a_sig = {(a_exp != 0), a_mant};
        b_sig = {(b_exp != 0), b_mant};
        c_sig = {(c_exp != 0), c_mant};

        a_esig = (a_exp == 0) ? -149 : a_exp - 150;
        b_esig = (b_exp == 0) ? -149 : b_exp - 150;
        c_esig = (c_exp == 0) ? -149 : c_exp - 150;

        a_inf  = (a_exp == 255) && (a_mant == 0);
        b_inf  = (b_exp == 255) && (b_mant == 0);
        c_inf  = (c_exp == 255) && (c_mant == 0);
        a_nan  = (a_exp == 255) && (a_mant != 0);
        b_nan  = (b_exp == 255) && (b_mant != 0);
        c_nan  = (c_exp == 255) && (c_mant != 0);
        a_snan = a_nan && !a_mant[22];
        b_snan = b_nan && !b_mant[22];
        c_snan = c_nan && !c_mant[22];
      end else if (fmt == 2'd1) begin
        p        = 11;
        mantbits = 10;
        expbits  = 5;
        bias     = 15;
        emin     = -14;
        emax     = 15;
        signpos  = 15;

        sa     = a[15];
        sb     = b[15];
        sc     = c[15];
        a_exp  = a[14:10];
        b_exp  = b[14:10];
        c_exp  = c[14:10];
        a_mant = {13'd0, a[9:0]};
        b_mant = {13'd0, b[9:0]};
        c_mant = {13'd0, c[9:0]};

        a_sig = {13'd0, (a_exp != 0), a[9:0]};
        b_sig = {13'd0, (b_exp != 0), b[9:0]};
        c_sig = {13'd0, (c_exp != 0), c[9:0]};

        a_esig = (a_exp == 0) ? -24 : a_exp - 25;
        b_esig = (b_exp == 0) ? -24 : b_exp - 25;
        c_esig = (c_exp == 0) ? -24 : c_exp - 25;

        a_inf  = (a_exp == 31) && (a[9:0] == 0);
        b_inf  = (b_exp == 31) && (b[9:0] == 0);
        c_inf  = (c_exp == 31) && (c[9:0] == 0);
        a_nan  = (a_exp == 31) && (a[9:0] != 0);
        b_nan  = (b_exp == 31) && (b[9:0] != 0);
        c_nan  = (c_exp == 31) && (c[9:0] != 0);
        a_snan = a_nan && !a[9];
        b_snan = b_nan && !b[9];
        c_snan = c_nan && !c[9];
      end else begin
        p        = 8;
        mantbits = 7;
        expbits  = 8;
        bias     = 127;
        emin     = -126;
        emax     = 127;
        signpos  = 15;

        sa     = a[15];
        sb     = b[15];
        sc     = c[15];
        a_exp  = a[14:7];
        b_exp  = b[14:7];
        c_exp  = c[14:7];
        a_mant = {16'd0, a[6:0]};
        b_mant = {16'd0, b[6:0]};
        c_mant = {16'd0, c[6:0]};

        a_sig = {16'd0, (a_exp != 0), a[6:0]};
        b_sig = {16'd0, (b_exp != 0), b[6:0]};
        c_sig = {16'd0, (c_exp != 0), c[6:0]};

        a_esig = (a_exp == 0) ? -133 : a_exp - 134;
        b_esig = (b_exp == 0) ? -133 : b_exp - 134;
        c_esig = (c_exp == 0) ? -133 : c_exp - 134;

        a_inf  = (a_exp == 255) && (a[6:0] == 0);
        b_inf  = (b_exp == 255) && (b[6:0] == 0);
        c_inf  = (c_exp == 255) && (c[6:0] == 0);
        a_nan  = (a_exp == 255) && (a[6:0] != 0);
        b_nan  = (b_exp == 255) && (b[6:0] != 0);
        c_nan  = (c_exp == 255) && (c[6:0] != 0);
        a_snan = a_nan && !a[6];
        b_snan = b_nan && !b[6];
        c_snan = c_nan && !c[6];
      end

      a_zero      = (a_exp == 0) && (a_mant == 0);
      b_zero      = (b_exp == 0) && (b_mant == 0);
      sp          = sa ^ sb;
      product_inf = a_inf || b_inf;

      invalid = a_snan || b_snan || c_snan ||
                (a_inf && b_zero) || (b_inf && a_zero) ||
                (product_inf && c_inf && (sp != sc));

      if (invalid) begin
        case (fmt)
          2'd0:    res = 32'h7fc00000;
          2'd1:    res = 32'h00007e00;
          default: res = 32'h00007fc0;
        endcase
        fl = 5'b10000;
      end else if (a_nan || b_nan || c_nan) begin
        case (fmt)
          2'd0:    res = 32'h7fc00000;
          2'd1:    res = 32'h00007e00;
          default: res = 32'h00007fc0;
        endcase
      end else if (product_inf || c_inf) begin
        signr = product_inf ? sp : sc;
        res   = 32'd0;
        res[signpos] = signr;
        tmp32 = (32'd1 << expbits) - 32'd1;
        res   = res | (tmp32 << mantbits);
      end else begin
        product = a_sig * b_sig;

        x = {product, 48'd0};
        y = {24'd0, c_sig, 48'd0};

        ep = a_esig + b_esig;
        ec = c_esig;

        alignment_lost = 1'b0;
        shifted        = 97'd0;

        if (ep >= ec) begin
          ebase   = ep;
          diff    = ep - ec;
          shifted = shift_jam96(y, diff);
          y       = shifted[95:0];
          alignment_lost = shifted[96];
        end else begin
          ebase   = ec;
          diff    = ec - ep;
          shifted = shift_jam96(x, diff);
          x       = shifted[95:0];
          alignment_lost = shifted[96];
        end

        if (sp == sc) begin
          s     = x + y;
          signr = sp;
        end else if (x >= y) begin
          s     = x - y;
          signr = sp;
          if (alignment_lost)
            s[0] = 1'b1;
        end else begin
          s     = y - x;
          signr = sc;
          if (alignment_lost)
            s[0] = 1'b1;
        end

        if (s == 0) begin
          res = 32'd0;
          if (sp == sc)
            res[signpos] = sp;
          else
            res[signpos] = (rnd == 3'd2);
        end else begin
          h = 0;
          for (i = 0; i < 96; i = i + 1) begin
            if (s[i])
              h = i;
          end

          eb = ebase - 48;
          un = eb + h;

          if (un >= emin)
            sh = h - p + 1;
          else
            sh = (emin - p + 1) - eb;

          q          = 96'd0;
          guard_bit  = 1'b0;
          sticky_bit = 1'b0;

          if (sh <= 0)
            q = s << (-sh);
          else if (sh < 96)
            q = s >> sh;

          for (i = 0; i < 96; i = i + 1) begin
            if ((sh > 0) && (i == sh - 1))
              guard_bit = s[i];
            if (i < sh - 1)
              sticky_bit = sticky_bit | s[i];
          end

          inexact  = guard_bit | sticky_bit;
          increment = 1'b0;

          case (rnd)
            3'd0: increment = guard_bit && (sticky_bit || q[0]);
            3'd1: increment = 1'b0;
            3'd2: increment = signr && inexact;
            3'd3: increment = !signr && inexact;
            3'd4: increment = guard_bit;
            default: increment = 1'b0;
          endcase

          rounded = q;
          if (increment)
            rounded = q + 96'd1;

          if (un >= emin) begin
            overflow = 1'b0;

            if (un > emax) begin
              overflow = 1'b1;
            end else if (rounded[p]) begin
              un = un + 1;
              if (un > emax)
                overflow = 1'b1;
            end

            if (overflow) begin
              to_infinity = (rnd == 3'd0) || (rnd == 3'd4) ||
                            ((rnd == 3'd3) && !signr) ||
                            ((rnd == 3'd2) && signr);

              res = 32'd0;
              res[signpos] = signr;

              if (to_infinity) begin
                tmp32 = (32'd1 << expbits) - 32'd1;
                res   = res | (tmp32 << mantbits);
              end else begin
                tmp32 = (32'd1 << expbits) - 32'd2;
                res   = res | (tmp32 << mantbits);
                tmp32 = (32'd1 << mantbits) - 32'd1;
                res   = res | tmp32;
              end

              fl = 5'b00101;
            end else begin
              res = 32'd0;
              res[signpos] = signr;
              tmp32 = un + bias;
              res   = res | (tmp32 << mantbits);
              tmp32 = (32'd1 << mantbits) - 32'd1;
              res   = res | (rounded[31:0] & tmp32);
              fl[0] = inexact;
            end
          end else begin
            res = 32'd0;
            res[signpos] = signr;

            if (rounded[p-1]) begin
              tmp32 = 32'd1;
              res   = res | (tmp32 << mantbits);
            end else begin
              tmp32 = (32'd1 << mantbits) - 32'd1;
              res   = res | (rounded[31:0] & tmp32);
            end

            fl[0] = inexact;
            fl[1] = inexact && !rounded[p-1];
          end
        end
      end

      fma_lane = {fl, res};
    end
  endfunction

  assign out_valid_o = in_valid_i;
  assign in_ready_o  = out_ready_i;

  always_comb begin
    result_o = {WIDTH{1'b1}};
    flags_o  = 5'd0;
    lane_tmp = 37'd0;

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
    end else begin
      for (k = 0; k < WIDTH/16; k = k + 1) begin
        if (k < (vec_i ? WIDTH/16 : 1)) begin
          lane_tmp = fma_lane({16'd0, a_i[k*16 +: 16]},
                              {16'd0, b_i[k*16 +: 16]},
                              {16'd0, c_i[k*16 +: 16]},
                              fmt_i, rnd_i);
          result_o[k*16 +: 16] = lane_tmp[15:0];
          flags_o = flags_o | lane_tmp[36:32];
        end
      end
    end
  end

endmodule
