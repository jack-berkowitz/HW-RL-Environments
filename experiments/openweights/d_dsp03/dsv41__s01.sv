// =============================================================================
// fp_multifmt_fma
// =============================================================================
module fp_multifmt_fma #(
  parameter int unsigned WIDTH = 64        // {32, 64}
) (
  input  logic             clk_i,
  input  logic             rst_ni,         // active low

  // ---- operation in ---------------------------------------------------------
  input  logic             in_valid_i,
  output logic             in_ready_o,
  input  logic [1:0]       fmt_i,          // 0 = FP32, 1 = FP16, 2 = BF16
  input  logic             vec_i,          // 1 = packed SIMD lanes
  input  logic [WIDTH-1:0] a_i,
  input  logic [WIDTH-1:0] b_i,
  input  logic [WIDTH-1:0] c_i,
  input  logic [2:0]       rnd_i,          // 0 RNE, 1 RTZ, 2 RDN, 3 RUP, 4 RMM

  // ---- result out -----------------------------------------------------------
  output logic             out_valid_o,
  input  logic             out_ready_i,
  output logic [WIDTH-1:0] result_o,
  output logic [4:0]       flags_o         // {NV, DZ, OF, UF, NX}
);

  // ---------------------------------------------------------------------------
  // Highest set bit of a 1024-bit vector, binary search (10 levels).
  // ---------------------------------------------------------------------------
  function automatic integer hb1024(input logic [1023:0] x);
    logic [1023:0] v;
    integer idx;
    begin
      v   = x;
      idx = 0;

      if (v[1023:512] != 0) begin v = v >> 512; idx = idx + 512; end
      if (v[511:256]  != 0) begin v = v >> 256; idx = idx + 256; end
      if (v[255:128]  != 0) begin v = v >> 128; idx = idx + 128; end
      if (v[127:64]   != 0) begin v = v >> 64;  idx = idx + 64;  end
      if (v[63:32]    != 0) begin v = v >> 32;  idx = idx + 32;  end
      if (v[31:16]    != 0) begin v = v >> 16;  idx = idx + 16;  end
      if (v[15:8]     != 0) begin v = v >> 8;   idx = idx + 8;   end
      if (v[7:4]      != 0) begin v = v >> 4;   idx = idx + 4;   end
      if (v[3:2]      != 0) begin v = v >> 2;   idx = idx + 2;   end
      if (v[1:1]      != 0) begin v = v >> 1;   idx = idx + 1;   end

      hb1024 = idx;
    end
  endfunction

  // ---------------------------------------------------------------------------
  // FP32 FMA
  // ---------------------------------------------------------------------------
  function automatic [36:0] fma_fp32(
    input logic [31:0] a,
    input logic [31:0] b,
    input logic [31:0] c,
    input logic [2:0]  rnd
  );
    localparam int M    = 23;
    localparam int BIAS = 127;
    localparam int BASE = -400;
    localparam int EMIN = 1 - BIAS;
    localparam int EMAX = BIAS;

    logic sa, sb, sc;
    logic [7:0]  ea, eb, ec;
    logic [22:0] fa, fb, fc;

    logic a_zero, b_zero, c_zero;
    logic a_inf,  b_inf,  c_inf;
    logic a_nan,  b_nan,  c_nan;
    logic a_snan, b_snan, c_snan;
    logic any_nan, any_snan;

    logic prod_inf;
    logic [23:0] siga, sigb, sigc;
    logic [47:0] prod;

    integer ea_i, eb_i, ec_i;
    integer scale_a, scale_b, scale_c, scale_p;
    integer shp, shc;

    logic signp, signc, sign, zero_sign;

    logic [1023:0] shifted_p, shifted_c, sum_mag, I, R, half;

    integer L, k, etop, e, expfield;
    logic inexact, round_up, ovf, uf, nx, nv;

    logic [31:0] res;
    logic [4:0]  flags;

    begin
      sa = a[31]; ea = a[30:23]; fa = a[22:0];
      sb = b[31]; eb = b[30:23]; fb = b[22:0];
      sc = c[31]; ec = c[30:23]; fc = c[22:0];

      ea_i = ea; eb_i = eb; ec_i = ec;

      a_zero = (ea == 8'h00) && (fa == 0);
      b_zero = (eb == 8'h00) && (fb == 0);
      c_zero = (ec == 8'h00) && (fc == 0);

      a_inf = (ea == 8'hFF) && (fa == 0);
      b_inf = (eb == 8'hFF) && (fb == 0);
      c_inf = (ec == 8'hFF) && (fc == 0);

      a_nan = (ea == 8'hFF) && (fa != 0);
      b_nan = (eb == 8'hFF) && (fb != 0);
      c_nan = (ec == 8'hFF) && (fc != 0);

      a_snan = a_nan && (fa[22] == 1'b0);
      b_snan = b_nan && (fb[22] == 1'b0);
      c_snan = c_nan && (fc[22] == 1'b0);

      any_nan  = a_nan | b_nan | c_nan;
      any_snan = a_snan | b_snan | c_snan;

      nv  = 1'b0;
      ovf = 1'b0;
      uf  = 1'b0;
      nx  = 1'b0;
      res = 32'h00000000;

      if (any_snan) begin
        res = 32'h7FC00000;
        nv  = 1'b1;
      end else if ((a_zero && b_inf) || (b_zero && a_inf)) begin
        res = 32'h7FC00000;
        nv  = 1'b1;
      end else if (any_nan) begin
        res = 32'h7FC00000;
      end else begin
        prod_inf = a_inf | b_inf;
        signp    = sa ^ sb;
        signc    = sc;

        if (prod_inf) begin
          if (c_inf && (signp != signc)) begin
            res = 32'h7FC00000;
            nv  = 1'b1;
          end else begin
            res = {signp, 8'hFF, 23'h000000};
          end
        end else if (c_inf) begin
          res = {signc, 8'hFF, 23'h000000};
        end else begin
          siga = (ea == 8'h00) ? {1'b0, fa} : {1'b1, fa};
          sigb = (eb == 8'h00) ? {1'b0, fb} : {1'b1, fb};
          sigc = (ec == 8'h00) ? {1'b0, fc} : {1'b1, fc};

          scale_a = (ea == 8'h00) ? (1 - BIAS - M) : (ea_i - BIAS - M);
          scale_b = (eb == 8'h00) ? (1 - BIAS - M) : (eb_i - BIAS - M);
          scale_c = (ec == 8'h00) ? (1 - BIAS - M) : (ec_i - BIAS - M);

          scale_p = scale_a + scale_b;
          prod    = siga * sigb;

          shp = scale_p - BASE;
          shc = scale_c - BASE;

          shifted_p = {{(1024-48){1'b0}}, prod} << shp;
          shifted_c = {{(1024-24){1'b0}}, sigc} << shc;

          if (signp == signc) begin
            sum_mag = shifted_p + shifted_c;
            sign    = signp;
          end else begin
            if (shifted_p >= shifted_c) begin
              sum_mag = shifted_p - shifted_c;
              sign    = signp;
            end else begin
              sum_mag = shifted_c - shifted_p;
              sign    = signc;
            end
          end

          if (sum_mag == 0) begin
            if (signp == signc) zero_sign = signp;
            else                zero_sign = (rnd == 3'd2);
            res = {zero_sign, 8'h00, 23'h000000};
          end else begin
            L    = hb1024(sum_mag);
            etop = L + BASE;

            if (etop >= EMIN) begin
              k = L - M;
              I = sum_mag >> k;
              R = sum_mag - (I << k);
              inexact = (R != 0);
              round_up = 1'b0;

              if (inexact) begin
                case (rnd)
                  3'd0: begin
                    half = (1024'd1 << (k-1));
                    if (R > half) round_up = 1'b1;
                    else if (R == half && I[0]) round_up = 1'b1;
                  end
                  3'd1: round_up = 1'b0;
                  3'd2: round_up = sign;
                  3'd3: round_up = ~sign;
                  3'd4: begin
                    half = (1024'd1 << (k-1));
                    if (R >= half) round_up = 1'b1;
                  end
                  default: round_up = 1'b0;
                endcase
              end

              if (round_up) I = I + 1'b1;

              if (I == (1024'd1 << (M+1))) begin
                I    = I >> 1;
                etop = etop + 1;
              end

              e = etop;

              if (e > EMAX) begin
                ovf = 1'b1;
                nx  = 1'b1;
                if ((rnd == 3'd0) || (rnd == 3'd4) ||
                    ((rnd == 3'd3) && !sign) ||
                    ((rnd == 3'd2) &&  sign)) begin
                  res = {sign, 8'hFF, 23'h000000};
                end else begin
                  res = {sign, 8'hFE, 23'h7FFFFF};
                end
              end else begin
                expfield = e + BIAS;
                res = {sign, expfield[7:0], I[22:0]};
                nx  = inexact;
                uf  = 1'b0;
              end
            end else begin
              k = (1 - BIAS - M) - BASE;
              I = sum_mag >> k;
              R = sum_mag - (I << k);
              inexact = (R != 0);
              round_up = 1'b0;

              if (inexact) begin
                case (rnd)
                  3'd0: begin
                    half = (1024'd1 << (k-1));
                    if (R > half) round_up = 1'b1;
                    else if (R == half && I[0]) round_up = 1'b1;
                  end
                  3'd1: round_up = 1'b0;
                  3'd2: round_up = sign;
                  3'd3: round_up = ~sign;
                  3'd4: begin
                    half = (1024'd1 << (k-1));
                    if (R >= half) round_up = 1'b1;
                  end
                  default: round_up = 1'b0;
                endcase
              end

              if (round_up) I = I + 1'b1;

              if (I >= (1024'd1 << M)) begin
                res = {sign, 8'h01, 23'h000000};
                nx  = inexact;
                uf  = 1'b0;
              end else begin
                res = {sign, 8'h00, I[22:0]};
                nx  = inexact;
                uf  = inexact;
              end
            end
          end
        end
      end

      flags = {nv, 1'b0, ovf, uf, nx};
      fma_fp32 = {flags, res};
    end
  endfunction

  // ---------------------------------------------------------------------------
  // FP16 FMA
  // ---------------------------------------------------------------------------
  function automatic [36:0] fma_fp16(
    input logic [15:0] a,
    input logic [15:0] b,
    input logic [15:0] c,
    input logic [2:0]  rnd
  );
    localparam int M    = 10;
    localparam int BIAS = 15;
    localparam int BASE = -400;
    localparam int EMIN = 1 - BIAS;
    localparam int EMAX = BIAS;

    logic sa, sb, sc;
    logic [4:0]  ea, eb, ec;
    logic [9:0]  fa, fb, fc;

    logic a_zero, b_zero, c_zero;
    logic a_inf,  b_inf,  c_inf;
    logic a_nan,  b_nan,  c_nan;
    logic a_snan, b_snan, c_snan;
    logic any_nan, any_snan;

    logic prod_inf;
    logic [23:0] siga, sigb, sigc;
    logic [47:0] prod;

    integer ea_i, eb_i, ec_i;
    integer scale_a, scale_b, scale_c, scale_p;
    integer shp, shc;

    logic signp, signc, sign, zero_sign;

    logic [1023:0] shifted_p, shifted_c, sum_mag, I, R, half;

    integer L, k, etop, e, expfield;
    logic inexact, round_up, ovf, uf, nx, nv;

    logic [31:0] res;
    logic [4:0]  flags;

    begin
      sa = a[15]; ea = a[14:10]; fa = a[9:0];
      sb = b[15]; eb = b[14:10]; fb = b[9:0];
      sc = c[15]; ec = c[14:10]; fc = c[9:0];

      ea_i = ea; eb_i = eb; ec_i = ec;

      a_zero = (ea == 5'h00) && (fa == 0);
      b_zero = (eb == 5'h00) && (fb == 0);
      c_zero = (ec == 5'h00) && (fc == 0);

      a_inf = (ea == 5'h1F) && (fa == 0);
      b_inf = (eb == 5'h1F) && (fb == 0);
      c_inf = (ec == 5'h1F) && (fc == 0);

      a_nan = (ea == 5'h1F) && (fa != 0);
      b_nan = (eb == 5'h1F) && (fb != 0);
      c_nan = (ec == 5'h1F) && (fc != 0);

      a_snan = a_nan && (fa[9] == 1'b0);
      b_snan = b_nan && (fb[9] == 1'b0);
      c_snan = c_nan && (fc[9] == 1'b0);

      any_nan  = a_nan | b_nan | c_nan;
      any_snan = a_snan | b_snan | c_snan;

      nv  = 1'b0;
      ovf = 1'b0;
      uf  = 1'b0;
      nx  = 1'b0;
      res = 32'h00000000;

      if (any_snan) begin
        res = 32'h00007E00;
        nv  = 1'b1;
      end else if ((a_zero && b_inf) || (b_zero && a_inf)) begin
        res = 32'h00007E00;
        nv  = 1'b1;
      end else if (any_nan) begin
        res = 32'h00007E00;
      end else begin
        prod_inf = a_inf | b_inf;
        signp    = sa ^ sb;
        signc    = sc;

        if (prod_inf) begin
          if (c_inf && (signp != signc)) begin
            res = 32'h00007E00;
            nv  = 1'b1;
          end else begin
            res = {signp, 5'h1F, 10'h000};
          end
        end else if (c_inf) begin
          res = {signc, 5'h1F, 10'h000};
        end else begin
          siga = (ea == 5'h00) ? {1'b0, fa} : {1'b1, fa};
          sigb = (eb == 5'h00) ? {1'b0, fb} : {1'b1, fb};
          sigc = (ec == 5'h00) ? {1'b0, fc} : {1'b1, fc};

          scale_a = (ea == 5'h00) ? (1 - BIAS - M) : (ea_i - BIAS - M);
          scale_b = (eb == 5'h00) ? (1 - BIAS - M) : (eb_i - BIAS - M);
          scale_c = (ec == 5'h00) ? (1 - BIAS - M) : (ec_i - BIAS - M);

          scale_p = scale_a + scale_b;
          prod    = siga * sigb;

          shp = scale_p - BASE;
          shc = scale_c - BASE;

          shifted_p = {{(1024-48){1'b0}}, prod} << shp;
          shifted_c = {{(1024-24){1'b0}}, sigc} << shc;

          if (signp == signc) begin
            sum_mag = shifted_p + shifted_c;
            sign    = signp;
          end else begin
            if (shifted_p >= shifted_c) begin
              sum_mag = shifted_p - shifted_c;
              sign    = signp;
            end else begin
              sum_mag = shifted_c - shifted_p;
              sign    = signc;
            end
          end

          if (sum_mag == 0) begin
            if (signp == signc) zero_sign = signp;
            else                zero_sign = (rnd == 3'd2);
            res = {zero_sign, 5'h00, 10'h000};
          end else begin
            L    = hb1024(sum_mag);
            etop = L + BASE;

            if (etop >= EMIN) begin
              k = L - M;
              I = sum_mag >> k;
              R = sum_mag - (I << k);
              inexact = (R != 0);
              round_up = 1'b0;

              if (inexact) begin
                case (rnd)
                  3'd0: begin
                    half = (1024'd1 << (k-1));
                    if (R > half) round_up = 1'b1;
                    else if (R == half && I[0]) round_up = 1'b1;
                  end
                  3'd1: round_up = 1'b0;
                  3'd2: round_up = sign;
                  3'd3: round_up = ~sign;
                  3'd4: begin
                    half = (1024'd1 << (k-1));
                    if (R >= half) round_up = 1'b1;
                  end
                  default: round_up = 1'b0;
                endcase
              end

              if (round_up) I = I + 1'b1;

              if (I == (1024'd1 << (M+1))) begin
                I    = I >> 1;
                etop = etop + 1;
              end

              e = etop;

              if (e > EMAX) begin
                ovf = 1'b1;
                nx  = 1'b1;
                if ((rnd == 3'd0) || (rnd == 3'd4) ||
                    ((rnd == 3'd3) && !sign) ||
                    ((rnd == 3'd2) &&  sign)) begin
                  res = {sign, 5'h1F, 10'h000};
                end else begin
                  res = {sign, 5'h1E, 10'h3FF};
                end
              end else begin
                expfield = e + BIAS;
                res = {sign, expfield[4:0], I[9:0]};
                nx  = inexact;
                uf  = 1'b0;
              end
            end else begin
              k = (1 - BIAS - M) - BASE;
              I = sum_mag >> k;
              R = sum_mag - (I << k);
              inexact = (R != 0);
              round_up = 1'b0;

              if (inexact) begin
                case (rnd)
                  3'd0: begin
                    half = (1024'd1 << (k-1));
                    if (R > half) round_up = 1'b1;
                    else if (R == half && I[0]) round_up = 1'b1;
                  end
                  3'd1: round_up = 1'b0;
                  3'd2: round_up = sign;
                  3'd3: round_up = ~sign;
                  3'd4: begin
                    half = (1024'd1 << (k-1));
                    if (R >= half) round_up = 1'b1;
                  end
                  default: round_up = 1'b0;
                endcase
              end

              if (round_up) I = I + 1'b1;

              if (I >= (1024'd1 << M)) begin
                res = {sign, 5'h01, 10'h000};
                nx  = inexact;
                uf  = 1'b0;
              end else begin
                res = {sign, 5'h00, I[9:0]};
                nx  = inexact;
                uf  = inexact;
              end
            end
          end
        end
      end

      flags = {nv, 1'b0, ovf, uf, nx};
      fma_fp16 = {flags, res};
    end
  endfunction

  // ---------------------------------------------------------------------------
  // BF16 FMA
  // ---------------------------------------------------------------------------
  function automatic [36:0] fma_bf16(
    input logic [15:0] a,
    input logic [15:0] b,
    input logic [15:0] c,
    input logic [2:0]  rnd
  );
    localparam int M    = 7;
    localparam int BIAS = 127;
    localparam int BASE = -400;
    localparam int EMIN = 1 - BIAS;
    localparam int EMAX = BIAS;

    logic sa, sb, sc;
    logic [7:0] ea, eb, ec;
    logic [6:0] fa, fb, fc;

    logic a_zero, b_zero, c_zero;
    logic a_inf,  b_inf,  c_inf;
    logic a_nan,  b_nan,  c_nan;
    logic a_snan, b_snan, c_snan;
    logic any_nan, any_snan;

    logic prod_inf;
    logic [23:0] siga, sigb, sigc;
    logic [47:0] prod;

    integer ea_i, eb_i, ec_i;
    integer scale_a, scale_b, scale_c, scale_p;
    integer shp, shc;

    logic signp, signc, sign, zero_sign;

    logic [1023:0] shifted_p, shifted_c, sum_mag, I, R, half;

    integer L, k, etop, e, expfield;
    logic inexact, round_up, ovf, uf, nx, nv;

    logic [31:0] res;
    logic [4:0]  flags;

    begin
      sa = a[15]; ea = a[14:7]; fa = a[6:0];
      sb = b[15]; eb = b[14:7]; fb = b[6:0];
      sc = c[15]; ec = c[14:7]; fc = c[6:0];

      ea_i = ea; eb_i = eb; ec_i = ec;

      a_zero = (ea == 8'h00) && (fa == 0);
      b_zero = (eb == 8'h00) && (fb == 0);
      c_zero = (ec == 8'h00) && (fc == 0);

      a_inf = (ea == 8'hFF) && (fa == 0);
      b_inf = (eb == 8'hFF) && (fb == 0);
      c_inf = (ec == 8'hFF) && (fc == 0);

      a_nan = (ea == 8'hFF) && (fa != 0);
      b_nan = (eb == 8'hFF) && (fb != 0);
      c_nan = (ec == 8'hFF) && (fc != 0);

      a_snan = a_nan && (fa[6] == 1'b0);
      b_snan = b_nan && (fb[6] == 1'b0);
      c_snan = c_nan && (fc[6] == 1'b0);

      any_nan  = a_nan | b_nan | c_nan;
      any_snan = a_snan | b_snan | c_snan;

      nv  = 1'b0;
      ovf = 1'b0;
      uf  = 1'b0;
      nx  = 1'b0;
      res = 32'h00000000;

      if (any_snan) begin
        res = 32'h00007FC0;
        nv  = 1'b1;
      end else if ((a_zero && b_inf) || (b_zero && a_inf)) begin
        res = 32'h00007FC0;
        nv  = 1'b1;
      end else if (any_nan) begin
        res = 32'h00007FC0;
      end else begin
        prod_inf = a_inf | b_inf;
        signp    = sa ^ sb;
        signc    = sc;

        if (prod_inf) begin
          if (c_inf && (signp != signc)) begin
            res = 32'h00007FC0;
            nv  = 1'b1;
          end else begin
            res = {signp, 8'hFF, 7'h00};
          end
        end else if (c_inf) begin
          res = {signc, 8'hFF, 7'h00};
        end else begin
          siga = (ea == 8'h00) ? {1'b0, fa} : {1'b1, fa};
          sigb = (eb == 8'h00) ? {1'b0, fb} : {1'b1, fb};
          sigc = (ec == 8'h00) ? {1'b0, fc} : {1'b1, fc};

          scale_a = (ea == 8'h00) ? (1 - BIAS - M) : (ea_i - BIAS - M);
          scale_b = (eb == 8'h00) ? (1 - BIAS - M) : (eb_i - BIAS - M);
          scale_c = (ec == 8'h00) ? (1 - BIAS - M) : (ec_i - BIAS - M);

          scale_p = scale_a + scale_b;
          prod    = siga * sigb;

          shp = scale_p - BASE;
          shc = scale_c - BASE;

          shifted_p = {{(1024-48){1'b0}}, prod} << shp;
          shifted_c = {{(1024-24){1'b0}}, sigc} << shc;

          if (signp == signc) begin
            sum_mag = shifted_p + shifted_c;
            sign    = signp;
          end else begin
            if (shifted_p >= shifted_c) begin
              sum_mag = shifted_p - shifted_c;
              sign    = signp;
            end else begin
              sum_mag = shifted_c - shifted_p;
              sign    = signc;
            end
          end

          if (sum_mag == 0) begin
            if (signp == signc) zero_sign = signp;
            else                zero_sign = (rnd == 3'd2);
            res = {zero_sign, 8'h00, 7'h00};
          end else begin
            L    = hb1024(sum_mag);
            etop = L + BASE;

            if (etop >= EMIN) begin
              k = L - M;
              I = sum_mag >> k;
              R = sum_mag - (I << k);
              inexact = (R != 0);
              round_up = 1'b0;

              if (inexact) begin
                case (rnd)
                  3'd0: begin
                    half = (1024'd1 << (k-1));
                    if (R > half) round_up = 1'b1;
                    else if (R == half && I[0]) round_up = 1'b1;
                  end
                  3'd1: round_up = 1'b0;
                  3'd2: round_up = sign;
                  3'd3: round_up = ~sign;
                  3'd4: begin
                    half = (1024'd1 << (k-1));
                    if (R >= half) round_up = 1'b1;
                  end
                  default: round_up = 1'b0;
                endcase
              end

              if (round_up) I = I + 1'b1;

              if (I == (1024'd1 << (M+1))) begin
                I    = I >> 1;
                etop = etop + 1;
              end

              e = etop;

              if (e > EMAX) begin
                ovf = 1'b1;
                nx  = 1'b1;
                if ((rnd == 3'd0) || (rnd == 3'd4) ||
                    ((rnd == 3'd3) && !sign) ||
                    ((rnd == 3'd2) &&  sign)) begin
                  res = {sign, 8'hFF, 7'h00};
                end else begin
                  res = {sign, 8'hFE, 7'h7F};
                end
              end else begin
                expfield = e + BIAS;
                res = {sign, expfield[7:0], I[6:0]};
                nx  = inexact;
                uf  = 1'b0;
              end
            end else begin
              k = (1 - BIAS - M) - BASE;
              I = sum_mag >> k;
              R = sum_mag - (I << k);
              inexact = (R != 0);
              round_up = 1'b0;

              if (inexact) begin
                case (rnd)
                  3'd0: begin
                    half = (1024'd1 << (k-1));
                    if (R > half) round_up = 1'b1;
                    else if (R == half && I[0]) round_up = 1'b1;
                  end
                  3'd1: round_up = 1'b0;
                  3'd2: round_up = sign;
                  3'd3: round_up = ~sign;
                  3'd4: begin
                    half = (1024'd1 << (k-1));
                    if (R >= half) round_up = 1'b1;
                  end
                  default: round_up = 1'b0;
                endcase
              end

              if (round_up) I = I + 1'b1;

              if (I >= (1024'd1 << M)) begin
                res = {sign, 8'h01, 7'h00};
                nx  = inexact;
                uf  = 1'b0;
              end else begin
                res = {sign, 8'h00, I[6:0]};
                nx  = inexact;
                uf  = inexact;
              end
            end
          end
        end
      end

      flags = {nv, 1'b0, ovf, uf, nx};
      fma_bf16 = {flags, res};
    end
  endfunction

  // ---------------------------------------------------------------------------
  // Lane processing
  // ---------------------------------------------------------------------------
  integer k;
  logic [15:0] a16, b16, c16, res16;
  logic [31:0] a32, b32, c32, res32;
  logic [36:0] out16, out32;
  logic [4:0]  fl16, fl32;
  logic [WIDTH-1:0] mask16, mask32, val16, val32;

  assign in_ready_o  = out_ready_i;
  assign out_valid_o = in_valid_i;

  always_comb begin
    result_o = {WIDTH{1'b1}};
    flags_o  = 5'b00000;

    for (k = 0; k < (WIDTH/16); k = k + 1) begin
      // ---- FP16 ----
      if (fmt_i == 2'd1) begin
        if (k < (vec_i ? (WIDTH/16) : 1)) begin
          a16 = (a_i >> (k*16)) & 16'hFFFF;
          b16 = (b_i >> (k*16)) & 16'hFFFF;
          c16 = (c_i >> (k*16)) & 16'hFFFF;

          out16 = fma_fp16(a16, b16, c16, rnd_i);
          res16 = out16[15:0];
          fl16  = out16[36:32];

          mask16 = '0;
          mask16[15:0] = 16'hFFFF;
          mask16 = mask16 << (k*16);

          val16 = '0;
          val16[15:0] = res16;
          val16 = val16 << (k*16);

          result_o = (result_o & ~mask16) | val16;
          flags_o  = flags_o | fl16;
        end
      end
      // ---- BF16 ----
      else if (fmt_i == 2'd2) begin
        if (k < (vec_i ? (WIDTH/16) : 1)) begin
          a16 = (a_i >> (k*16)) & 16'hFFFF;
          b16 = (b_i >> (k*16)) & 16'hFFFF;
          c16 = (c_i >> (k*16)) & 16'hFFFF;

          out16 = fma_bf16(a16, b16, c16, rnd_i);
          res16 = out16[15:0];
          fl16  = out16[36:32];

          mask16 = '0;
          mask16[15:0] = 16'hFFFF;
          mask16 = mask16 << (k*16);

          val16 = '0;
          val16[15:0] = res16;
          val16 = val16 << (k*16);

          result_o = (result_o & ~mask16) | val16;
          flags_o  = flags_o | fl16;
        end
      end
      // ---- FP32 ----
      else if (fmt_i == 2'd0) begin
        if (k < (vec_i ? (WIDTH/32) : 1)) begin
          a32 = (a_i >> (k*32)) & 32'hFFFFFFFF;
          b32 = (b_i >> (k*32)) & 32'hFFFFFFFF;
          c32 = (c_i >> (k*32)) & 32'hFFFFFFFF;

          out32 = fma_fp32(a32, b32, c32, rnd_i);
          res32 = out32[31:0];
          fl32  = out32[36:32];

          mask32 = '0;
          mask32[31:0] = 32'hFFFFFFFF;
          mask32 = mask32 << (k*32);

          val32 = '0;
          val32[31:0] = res32;
          val32 = val32 << (k*32);

          result_o = (result_o & ~mask32) | val32;
          flags_o  = flags_o | fl32;
        end
      end
    end
  end

endmodule
