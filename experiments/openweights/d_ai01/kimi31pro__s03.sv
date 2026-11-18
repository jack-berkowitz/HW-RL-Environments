module fp16_gemm_array #(
  parameter int unsigned HEIGHT = 8,
  parameter int unsigned WIDTH  = 8
) (
  input  logic                               clk_i,
  input  logic                               rst_ni,
  input  logic [WIDTH-1:0][HEIGHT-1:0][15:0] x_i,
  input  logic            [HEIGHT-1:0][15:0] w_i,
  input  logic [WIDTH-1:0]            [15:0] y_i,
  output logic [WIDTH-1:0]            [15:0] z_o,
  input  logic [2:0]                         rnd_i,
  input  logic                               accumulate_i,
  input  logic [WIDTH-1:0]                   row_clk_gate_en_i,
  input  logic                               reg_enable_i,
  input  logic                               flush_i,
  output logic [WIDTH-1:0][HEIGHT-1:0][4:0]  status_o
);

  // Return the index of the most-significant set bit in a nonzero 12-bit
  // value. A case priority encoder avoids per-bit normalization loops.
  function automatic [3:0] msb12(input logic [11:0] v);
    begin
      casez (v)
        12'b1???????????: msb12 = 4'd11;
        12'b01??????????: msb12 = 4'd10;
        12'b001?????????: msb12 = 4'd9;
        12'b0001????????: msb12 = 4'd8;
        12'b00001???????: msb12 = 4'd7;
        12'b000001??????: msb12 = 4'd6;
        12'b0000001?????: msb12 = 4'd5;
        12'b00000001????: msb12 = 4'd4;
        12'b000000001???: msb12 = 4'd3;
        12'b0000000001??: msb12 = 4'd2;
        12'b00000000001?: msb12 = 4'd1;
        12'b000000000001: msb12 = 4'd0;
        default:          msb12 = 4'd0;
      endcase
    end
  endfunction

  // Exact binary16 FMA.
  //
  // Finite exact results are represented as an unsigned magnitude multiplied
  // by 2^-48. Every binary16 product and every binary16 addend is exact in
  // this representation. The wide integer sum therefore performs no product
  // rounding and no alignment rounding.
  //
  // Return value: {NV, DZ, OF, UF, NX, result[15:0]}.
  function automatic [20:0] fma16(
    input logic [15:0] a,
    input logic [15:0] b,
    input logic [15:0] c,
    input logic [2:0]  rnd
  );
    logic a_nan, b_nan, c_nan;
    logic a_snan, b_snan, c_snan;
    logic a_inf, b_inf, c_inf;
    logic a_zero, b_zero;

    logic [10:0] ma, mb, mc;
    logic [21:0] prod;
    integer ea, eb, ec;

    logic p_sign, c_sign, sign;
    logic [83:0] p_mag, c_mag, mag;

    logic [15:0] res;
    logic nv, of, uf, nx;

    integer h;
    integer shift_amt;
    integer exp_field;
    logic tiny;
    logic [83:0] q, base, rem, half, rounded;
    logic inexact, increment;

    begin
      a_nan  = (&a[14:10]) && (|a[9:0]);
      b_nan  = (&b[14:10]) && (|b[9:0]);
      c_nan  = (&c[14:10]) && (|c[9:0]);
      a_snan = a_nan && !a[9];
      b_snan = b_nan && !b[9];
      c_snan = c_nan && !c[9];

      a_inf  = (&a[14:10]) && !(|a[9:0]);
      b_inf  = (&b[14:10]) && !(|b[9:0]);
      c_inf  = (&c[14:10]) && !(|c[9:0]);
      a_zero = (a[14:0] == 15'd0);
      b_zero = (b[14:0] == 15'd0);

      res = 16'd0;
      nv  = 1'b0;
      of  = 1'b0;
      uf  = 1'b0;
      nx  = 1'b0;

      p_sign = a[15] ^ b[15];
      c_sign = c[15];
      sign   = 1'b0;

      ma = 11'd0;
      mb = 11'd0;
      mc = 11'd0;
      prod = 22'd0;
      ea = 1;
      eb = 1;
      ec = 1;

      p_mag = 84'd0;
      c_mag = 84'd0;
      mag   = 84'd0;

      h         = 0;
      shift_amt = 0;
      exp_field = 0;
      tiny      = 1'b0;
      q         = 84'd0;
      base      = 84'd0;
      rem       = 84'd0;
      half      = 84'd0;
      rounded   = 84'd0;
      inexact   = 1'b0;
      increment = 1'b0;

      if (a_nan || b_nan || c_nan) begin
        res = 16'h7E00;
        nv  = a_snan || b_snan || c_snan;
      end else if ((a_inf && b_zero) || (b_inf && a_zero)) begin
        res = 16'h7E00;
        nv  = 1'b1;
      end else if (a_inf || b_inf) begin
        if (c_inf && (c[15] != p_sign)) begin
          res = 16'h7E00;
          nv  = 1'b1;
        end else begin
          res = {p_sign, 5'h1F, 10'd0};
        end
      end else if (c_inf) begin
        res = {c[15], 5'h1F, 10'd0};
      end else begin
        // Effective exponent is one for both zero and subnormal encodings.
        ea = (a[14:10] == 5'd0) ? 1 : a[14:10];
        eb = (b[14:10] == 5'd0) ? 1 : b[14:10];
        ec = (c[14:10] == 5'd0) ? 1 : c[14:10];

        ma = {(a[14:10] != 5'd0), a[9:0]};
        mb = {(b[14:10] != 5'd0), b[9:0]};
        mc = {(c[14:10] != 5'd0), c[9:0]};

        prod = ma * mb;

        // a*b = prod * 2^(ea+eb-50)
        // c   = mc   * 2^(ec-25)
        // Both right-hand sides below are scaled by 2^48.
        p_mag = {{62{1'b0}}, prod} << (ea + eb - 2);
        c_mag = {{73{1'b0}}, mc}   << (ec + 23);

        if (p_sign == c_sign) begin
          mag  = p_mag + c_mag;
          sign = p_sign;
        end else if (p_mag > c_mag) begin
          mag  = p_mag - c_mag;
          sign = p_sign;
        end else if (c_mag > p_mag) begin
          mag  = c_mag - p_mag;
          sign = c_sign;
        end else begin
          mag  = 84'd0;
          sign = 1'b0;
        end

        if (mag == 84'd0) begin
          // Zeros of the same sign retain that sign. Cancellation and zeros
          // of opposite signs produce -0 only under RDN.
          if ((p_mag == 84'd0) && (c_mag == 84'd0) &&
              (p_sign == c_sign)) begin
            sign = p_sign;
          end else begin
            sign = (rnd == 3'd2);
          end
          res = {sign, 15'd0};
        end else begin
          if (|mag[83:72]) begin
            h = 72 + msb12(mag[83:72]);
          end else if (|mag[71:60]) begin
            h = 60 + msb12(mag[71:60]);
          end else if (|mag[59:48]) begin
            h = 48 + msb12(mag[59:48]);
          end else if (|mag[47:36]) begin
            h = 36 + msb12(mag[47:36]);
          end else if (|mag[35:24]) begin
            h = 24 + msb12(mag[35:24]);
          end else if (|mag[23:12]) begin
            h = 12 + msb12(mag[23:12]);
          end else begin
            h = msb12(mag[11:0]);
          end

          // mag's highest bit h represents 2^(h-48). The smallest normal
          // has h=34. Subnormals are rounded in units of 2^-24, hence shift 24.
          tiny = (h < 34);
          shift_amt = tiny ? 24 : (h - 10);

          q       = mag >> shift_amt;
          base    = q << shift_amt;
          rem     = mag - base;
          half    = 84'd1 << (shift_amt - 1);
          inexact = (rem != 84'd0);

          case (rnd)
            3'd0: begin // RNE
              increment = (rem > half) ||
                          ((rem == half) && q[0]);
            end
            3'd1: begin // RTZ
              increment = 1'b0;
            end
            3'd2: begin // RDN
              increment = sign && inexact;
            end
            3'd3: begin // RUP
              increment = !sign && inexact;
            end
            3'd4: begin // RMM
              increment = (rem >= half);
            end
            default: begin
              increment = (rem > half) ||
                          ((rem == half) && q[0]);
            end
          endcase

          rounded = q + increment;
          nx = inexact;
          uf = tiny && inexact;

          if (tiny) begin
            if (rounded == 84'd0) begin
              res = {sign, 15'd0};
            end else if (rounded >= 84'd1024) begin
              // Rounding a tiny value can produce the smallest normal.
              res = {sign, 5'd1, 10'd0};
            end else begin
              res = {sign, 5'd0, rounded[9:0]};
            end
          end else begin
            if (rounded >= 84'd2048) begin
              rounded = 84'd1024;
              h = h + 1;
            end

            exp_field = h - 33;

            if (exp_field >= 31) begin
              of = 1'b1;
              uf = 1'b0;
              nx = 1'b1;

              case (rnd)
                3'd1: begin // RTZ: maximum finite in both directions
                  res = {sign, 5'd30, 10'h3FF};
                end
                3'd2: begin // RDN
                  if (sign) begin
                    res = {1'b1, 5'h1F, 10'd0};
                  end else begin
                    res = {1'b0, 5'd30, 10'h3FF};
                  end
                end
                3'd3: begin // RUP
                  if (sign) begin
                    res = {1'b1, 5'd30, 10'h3FF};
                  end else begin
                    res = {1'b0, 5'h1F, 10'd0};
                  end
                end
                default: begin // RNE and RMM
                  res = {sign, 5'h1F, 10'd0};
                end
              endcase
            end else begin
              // rounded is in [1024,2047], so its low ten bits are the
              // trailing significand without another subtraction.
              res = {sign, exp_field[4:0], rounded[9:0]};
            end
          end
        end
      end

      fma16 = {nv, 1'b0, of, uf, nx, res};
    end
  endfunction

  logic [WIDTH-1:0][HEIGHT-1:0][15:0] stage_p;

  generate
    for (genvar r = 0; r < WIDTH; r = r + 1) begin : g_rows
      // Counts enabled flush ticks separately for each row. A gated row does
      // not observe flush at all.
      logic flush_seen;

      always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
          flush_seen <= 1'b0;
        end else if (row_clk_gate_en_i[r]) begin
          if (!flush_i) begin
            flush_seen <= 1'b0;
          end else if (reg_enable_i) begin
            flush_seen <= 1'b1;
          end
        end
      end

      for (genvar k = 0; k < HEIGHT; k = k + 1) begin : g_stages
        logic [15:0] addend;
        logic [20:0] fma_comb;

        // A result is delivered three enabled ticks after its stage samples
        // operands. The following stage samples one tick later, giving the
        // required four-tick stage spacing.
        logic [15:0] result_d0;
        logic [15:0] result_d1;
        logic [15:0] result_d2;
        logic [15:0] result_d3;

        // flag_d2 is the externally visible status and has a two-tick delay.
        logic [4:0] flag_d0;
        logic [4:0] flag_d1;
        logic [4:0] flag_d2;

        if (k == 0) begin : g_bias
          // Reading registered z_o before this edge supplies z_o(s-1), which
          // is exactly dfb = d(0)+1 relative to the eventual output.
          assign addend = accumulate_i ? z_o[r] : y_i[r];
        end else begin : g_chain
          assign addend = stage_p[r][k-1];
        end

        assign fma_comb = fma16(x_i[r][k], w_i[k], addend, rnd_i);
        assign stage_p[r][k] = result_d3;
        assign status_o[r][k] = flag_d2;

        if (k == HEIGHT-1) begin : g_output
          assign z_o[r] = result_d3;
        end

        always_ff @(posedge clk_i or negedge rst_ni) begin
          if (!rst_ni) begin
            result_d0 <= 16'd0;
            result_d1 <= 16'd0;
            result_d2 <= 16'd0;
            result_d3 <= 16'd0;
            flag_d0   <= 5'd0;
            flag_d1   <= 5'd0;
            flag_d2   <= 5'd0;
          end else if (row_clk_gate_en_i[r]) begin
            if (flush_i) begin
              // Simultaneous chain clear, independent of reg_enable_i.
              result_d0 <= 16'd0;
              result_d1 <= 16'd0;
              result_d2 <= 16'd0;
              result_d3 <= 16'd0;

              if (reg_enable_i) begin
                flag_d0 <= 5'd0;
                flag_d1 <= 5'd0;

                // First enabled flush tick performs the normal A10 update;
                // subsequent enabled flush ticks hold flag_d2.
                if (!flush_seen) begin
                  flag_d2 <= flag_d1;
                end
              end
            end else if (reg_enable_i) begin
              result_d0 <= fma_comb[15:0];
              result_d1 <= result_d0;
              result_d2 <= result_d1;
              result_d3 <= result_d2;

              flag_d0 <= fma_comb[20:16];
              flag_d1 <= flag_d0;
              flag_d2 <= flag_d1;
            end
          end
        end
      end
    end
  endgenerate

endmodule
