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

  // The active significand window is 4*p bits, including the possible carry.
  // Bits shifted below the window are represented by sticky bits.
  function automatic logic [36:0] fma_lane (
    input logic [31:0] a,
    input logic [31:0] b,
    input logic [31:0] c,
    input logic [1:0]  fmt,
    input logic [2:0]  rnd
  );
    integer p;
    integer mantbits;
    integer bias;
    integer emin;
    integer emax;
    integer maxexp;
    integer exp_a;
    integer exp_b;
    integer exp_c;
    integer q_a;
    integer q_b;
    integer q_c;
    integer q_prod;
    integer lp;
    integer lc;
    integer top_p;
    integer top_c;
    integer top;
    integer g;
    integer window;
    integer rshift;
    integer h;
    integer e;
    integer qout;
    integer shift;
    integer hn;
    integer exp_out;
    integer j;

    logic sign_a;
    logic sign_b;
    logic sign_c;
    logic sign_p;
    logic sign_res;

    logic [22:0] mant_a;
    logic [22:0] mant_b;
    logic [22:0] mant_c;
    logic [22:0] qbit;

    logic [23:0] sig_a;
    logic [23:0] sig_b;
    logic [23:0] sig_c;
    logic [47:0] prod;

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
    logic zero_inf_invalid;

    logic [95:0] src_p;
    logic [95:0] src_c;
    logic [95:0] align_p;
    logic [95:0] align_c;
    logic [95:0] mag;
    logic [95:0] kept;
    logic [95:0] rounded;
    logic sticky_p;
    logic sticky_c;
    logic sticky;
    logic round_bit;
    logic tail;
    logic inexact;
    logic inc;
    logic to_inf;
    logic [7:0] exp_field;

    logic [31:0] res;
    logic [4:0]  flg;

    begin
      res = 32'b0;
      flg = 5'b0;

      // FP32 defaults.
      p        = 24;
      mantbits = 23;
      bias     = 127;
      emin     = -126;
      emax     = 127;
      maxexp   = 255;

      sign_a = a[31];
      sign_b = b[31];
      sign_c = c[31];
      exp_a  = a[30:23];
      exp_b  = b[30:23];
      exp_c  = c[30:23];
      mant_a = a[22:0];
      mant_b = b[22:0];
      mant_c = c[22:0];

      if (fmt == 2'd1) begin
        p        = 11;
        mantbits = 10;
        bias     = 15;
        emin     = -14;
        emax     = 15;
        maxexp   = 31;

        sign_a = a[15];
        sign_b = b[15];
        sign_c = c[15];
        exp_a  = a[14:10];
        exp_b  = b[14:10];
        exp_c  = c[14:10];
        mant_a = 23'b0;
        mant_b = 23'b0;
        mant_c = 23'b0;
        mant_a[9:0] = a[9:0];
        mant_b[9:0] = b[9:0];
        mant_c[9:0] = c[9:0];
      end else if (fmt == 2'd2) begin
        p        = 8;
        mantbits = 7;
        bias     = 127;
        emin     = -126;
        emax     = 127;
        maxexp   = 255;

        sign_a = a[15];
        sign_b = b[15];
        sign_c = c[15];
        exp_a  = a[14:8];
        exp_b  = b[14:8];
        exp_c  = c[14:8];
        mant_a = 23'b0;
        mant_b = 23'b0;
        mant_c = 23'b0;
        mant_a[6:0] = a[6:0];
        mant_b[6:0] = b[6:0];
        mant_c[6:0] = c[6:0];
      end

      a_zero = (exp_a == 0) && (mant_a == 0);
      b_zero = (exp_b == 0) && (mant_b == 0);

      a_inf = (exp_a == maxexp) && (mant_a == 0);
      b_inf = (exp_b == maxexp) && (mant_b == 0);
      c_inf = (exp_c == maxexp) && (mant_c == 0);

      a_nan = (exp_a == maxexp) && (mant_a != 0);
      b_nan = (exp_b == maxexp) && (mant_b != 0);
      c_nan = (exp_c == maxexp) && (mant_c != 0);

      qbit = 23'h1 << (mantbits-1);
      a_snan = a_nan && ((mant_a & qbit) == 0);
      b_snan = b_nan && ((mant_b & qbit) == 0);
      c_snan = c_nan && ((mant_c & qbit) == 0);

      zero_inf_invalid = (a_inf && b_zero) || (b_inf && a_zero);

      sig_a = {1'b0, mant_a};
      sig_b = {1'b0, mant_b};
      sig_c = {1'b0, mant_c};

      if (exp_a != 0)
        sig_a = (24'h1 << mantbits) | {1'b0, mant_a};
      if (exp_b != 0)
        sig_b = (24'h1 << mantbits) | {1'b0, mant_b};
      if (exp_c != 0)
        sig_c = (24'h1 << mantbits) | {1'b0, mant_c};

      if (exp_a == 0)
        q_a = emin - (p-1);
      else
        q_a = exp_a - bias - (p-1);

      if (exp_b == 0)
        q_b = emin - (p-1);
      else
        q_b = exp_b - bias - (p-1);

      if (exp_c == 0)
        q_c = emin - (p-1);
      else
        q_c = exp_c - bias - (p-1);

      q_prod = q_a + q_b;
      sign_p = sign_a ^ sign_b;
      prod   = sig_a * sig_b;

      if (zero_inf_invalid || a_snan || b_snan || c_snan) begin
        if (fmt == 2'd0)
          res = 32'h7fc00000;
        else if (fmt == 2'd1)
          res = {16'b0, 16'h7e00};
        else
          res = {16'b0, 16'h7fc0};
        flg = 5'b10000;
      end else if (a_nan || b_nan || c_nan) begin
        if (fmt == 2'd0)
          res = 32'h7fc00000;
        else if (fmt == 2'd1)
          res = {16'b0, 16'h7e00};
        else
          res = {16'b0, 16'h7fc0};
      end else if ((a_inf || b_inf) && c_inf && (sign_p != sign_c)) begin
        if (fmt == 2'd0)
          res = 32'h7fc00000;
        else if (fmt == 2'd1)
          res = {16'b0, 16'h7e00};
        else
          res = {16'b0, 16'h7fc0};
        flg = 5'b10000;
      end else if (a_inf || b_inf) begin
        if (fmt == 2'd0)
          res = {sign_p, 8'hff, 23'b0};
        else if (fmt == 2'd1)
          res = {16'b0, sign_p, 5'h1f, 10'b0};
        else
          res = {16'b0, sign_p, 8'hff, 7'b0};
      end else if (c_inf) begin
        if (fmt == 2'd0)
          res = {sign_c, 8'hff, 23'b0};
        else if (fmt == 2'd1)
          res = {16'b0, sign_c, 5'h1f, 10'b0};
        else
          res = {16'b0, sign_c, 8'hff, 7'b0};
      end else if ((prod == 0) && (sig_c == 0)) begin
        if (sign_p == sign_c)
          sign_res = sign_p;
        else
          sign_res = (rnd == 3'd2);

        if (fmt == 2'd0)
          res = {sign_res, 31'b0};
        else
          res = {16'b0, sign_res, 15'b0};
      end else if (prod == 0) begin
        // The exact sum is the already-representable addend.
        if (fmt == 2'd0)
          res = c;
        else
          res = {16'b0, c[15:0]};
      end else begin
        // Locate the exact product and addend above a common fixed-point
        // window.  The term with the greater top is always aligned exactly.
        lp = 0;
        for (j = 0; j < 48; j = j + 1)
          if (prod[j])
            lp = j;

        lc = 0;
        for (j = 0; j < 24; j = j + 1)
          if (sig_c[j])
            lc = j;

        top_p = q_prod + lp + 1;
        if (sig_c != 0)
          top_c = q_c + lc + 1;
        else
          top_c = top_p - 1;

        if (top_p >= top_c)
          top = top_p;
        else
          top = top_c;

        window = 4*p - 1;
        g = top - window;

        src_p = {48'b0, prod};
        src_c = {72'b0, sig_c};

        sticky_p = 1'b0;
        if (q_prod >= g) begin
          align_p = src_p << (q_prod-g);
        end else begin
          rshift = g - q_prod;
          align_p = src_p >> rshift;
          for (j = 0; j < 48; j = j + 1)
            if ((j < rshift) && prod[j])
              sticky_p = 1'b1;
        end

        sticky_c = 1'b0;
        if (q_c >= g) begin
          align_c = src_c << (q_c-g);
        end else begin
          rshift = g - q_c;
          align_c = src_c >> rshift;
          for (j = 0; j < 24; j = j + 1)
            if ((j < rshift) && sig_c[j])
              sticky_c = 1'b1;
        end

        mag      = 96'b0;
        sticky   = 1'b0;
        sign_res = sign_p;

        if (sign_p == sign_c) begin
          mag = align_p + align_c;
          sticky = sticky_p | sticky_c;
        end else if (top_p > top_c) begin
          sign_res = sign_p;
          if (sticky_c) begin
            // align_p - (align_c + fraction)
            mag = (align_p - align_c) - 96'd1;
            sticky = 1'b1;
          end else begin
            mag = align_p - align_c;
            sticky = sticky_p;
          end
        end else if (top_c > top_p) begin
          sign_res = sign_c;
          if (sticky_p) begin
            mag = (align_c - align_p) - 96'd1;
            sticky = 1'b1;
          end else begin
            mag = align_c - align_p;
            sticky = sticky_c;
          end
        end else begin
          // Equal tops imply that both alignments are exact.
          if (align_p > align_c) begin
            mag = align_p - align_c;
            sign_res = sign_p;
          end else if (align_c > align_p) begin
            mag = align_c - align_p;
            sign_res = sign_c;
          end else begin
            mag = 96'b0;
            sign_res = sign_p;
          end
          sticky = 1'b0;
        end

        if ((mag == 0) && !sticky) begin
          // Exact cancellation of nonzero terms.
          sign_res = (rnd == 3'd2);
          if (fmt == 2'd0)
            res = {sign_res, 31'b0};
          else
            res = {16'b0, sign_res, 15'b0};
          flg = 5'b0;
        end else begin
          h = 0;
          for (j = 0; j < 96; j = j + 1)
            if (mag[j])
              h = j;

          if (mag == 0)
            e = g - 1;
          else
            e = g + h;

          if (e > emin)
            qout = e - (p-1);
          else
            qout = emin - (p-1);

          shift = qout - g;
          round_bit = 1'b0;
          tail = sticky;

          if (shift <= 0) begin
            // This path is exact whenever sticky can be set.
            kept = mag << (-shift);
          end else begin
            kept = mag >> shift;
            for (j = 0; j < 96; j = j + 1) begin
              if (j == (shift-1))
                round_bit = mag[j];
              if (j < (shift-1))
                tail = tail | mag[j];
            end
          end

          inexact = round_bit | tail;
          inc = 1'b0;

          case (rnd)
            3'd0: inc = round_bit && (tail || kept[0]); // RNE
            3'd1: inc = 1'b0;                           // RTZ
            3'd2: inc = sign_res && inexact;            // RDN
            3'd3: inc = !sign_res && inexact;           // RUP
            3'd4: inc = round_bit;                      // RMM
            default: inc = 1'b0;
          endcase

          rounded = kept + {{95{1'b0}}, inc};

          hn = 0;
          for (j = 0; j < 96; j = j + 1)
            if (rounded[j])
              hn = j;

          if (rounded == 0) begin
            if (fmt == 2'd0)
              res = {sign_res, 31'b0};
            else
              res = {16'b0, sign_res, 15'b0};
            flg = {3'b000, inexact, inexact};
          end else if (rounded < (96'h1 << (p-1))) begin
            if (fmt == 2'd0)
              res = {sign_res, 8'b0, rounded[22:0]};
            else if (fmt == 2'd1)
              res = {16'b0, sign_res, 5'b0, rounded[9:0]};
            else
              res = {16'b0, sign_res, 8'b0, rounded[6:0]};
            flg = {3'b000, inexact, inexact};
          end else begin
            exp_out = qout + hn + bias;

            if ((qout + hn) > emax) begin
              to_inf = (rnd == 3'd0) || (rnd == 3'd4) ||
                       ((rnd == 3'd3) && !sign_res) ||
                       ((rnd == 3'd2) && sign_res);

              if (to_inf) begin
                if (fmt == 2'd0)
                  res = {sign_res, 8'hff, 23'b0};
                else if (fmt == 2'd1)
                  res = {16'b0, sign_res, 5'h1f, 10'b0};
                else
                  res = {16'b0, sign_res, 8'hff, 7'b0};
              end else begin
                if (fmt == 2'd0)
                  res = {sign_res, 8'hfe, 23'h7fffff};
                else if (fmt == 2'd1)
                  res = {16'b0, sign_res, 5'h1e, 10'h3ff};
                else
                  res = {16'b0, sign_res, 8'hfe, 7'h7f};
              end
              flg = 5'b00101;
            end else begin
              exp_field = exp_out;
              if (fmt == 2'd0)
                res = {sign_res, exp_field, rounded[22:0]};
              else if (fmt == 2'd1)
                res = {16'b0, sign_res, exp_field[4:0], rounded[9:0]};
              else
                res = {16'b0, sign_res, exp_field, rounded[6:0]};
              flg = {4'b0000, inexact};
            end
          end
        end
      end

      fma_lane = {res, flg};
    end
  endfunction

  integer k;
  logic [36:0] lane;

  // Fully combinational ready/valid implementation.  Neither forbidden
  // combinational handshake path is present.
  assign out_valid_o = in_valid_i;
  assign in_ready_o  = out_ready_i;

  always_comb begin
    result_o = {WIDTH{1'b1}};
    flags_o  = 5'b0;
    lane     = 37'b0;

    if (fmt_i == 2'd0) begin
      for (k = 0; k < WIDTH/32; k = k + 1) begin
        if (vec_i || (k == 0)) begin
          lane = fma_lane(a_i[k*32 +: 32],
                          b_i[k*32 +: 32],
                          c_i[k*32 +: 32],
                          fmt_i, rnd_i);
          result_o[k*32 +: 32] = lane[36:5];
          flags_o = flags_o | lane[4:0];
        end
      end
    end else if ((fmt_i == 2'd1) || (fmt_i == 2'd2)) begin
      for (k = 0; k < WIDTH/16; k = k + 1) begin
        if (vec_i || (k == 0)) begin
          lane = fma_lane({16'b0, a_i[k*16 +: 16]},
                          {16'b0, b_i[k*16 +: 16]},
                          {16'b0, c_i[k*16 +: 16]},
                          fmt_i, rnd_i);
          result_o[k*16 +: 16] = lane[20:5];
          flags_o = flags_o | lane[4:0];
        end
      end
    end
  end

endmodule
