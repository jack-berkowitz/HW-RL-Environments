// =============================================================================
// fp16_gemm_array -- d_ai01 implementation.
//
// Per row: chain of HEIGHT FMA stages, each a 2-phase pipelined fused
// multiply-add (exact product formed before the sample register; exact
// align/add/normalise/round after it), followed by two inter-stage delay
// registers. Stage k therefore consumes its operands 4 enabled ticks before
// stage k+1, and z_o lags the last stage's operands by 3 enabled ticks:
// the contractual skew d(k) = 4*(H-1-k)+3 and total latency 4*(H-1)+3.
// status_o[r][k] is the flag register one edge after the sample edge, i.e.
// it reports the operation sampled 2 enabled ticks earlier, for every k.
// =============================================================================
module fp16_gemm_array #(
  parameter int unsigned HEIGHT = 8,
  parameter int unsigned WIDTH  = 8
) (
  input  logic                                   clk_i,
  input  logic                                   rst_ni,
  input  logic [WIDTH-1:0][HEIGHT-1:0][15:0]      x_i,
  input  logic [HEIGHT-1:0][15:0]                w_i,
  input  logic [WIDTH-1:0][15:0]                 y_i,
  output logic [WIDTH-1:0][15:0]                 z_o,
  input  logic [2:0]                             rnd_i,
  input  logic                                   accumulate_i,
  input  logic [WIDTH-1:0]                       row_clk_gate_en_i,
  input  logic                                   reg_enable_i,
  input  logic                                   flush_i,
  output logic [WIDTH-1:0][HEIGHT-1:0][4:0]      status_o
);

  // --------------------------------------------------------------------------
  // functions
  // --------------------------------------------------------------------------
  function automatic logic [3:0] f_clz10(input logic [9:0] v);
    casez (v)
      10'b1????????? : f_clz10 = 4'd0;
      10'b01???????? : f_clz10 = 4'd1;
      10'b001??????? : f_clz10 = 4'd2;
      10'b0001?????? : f_clz10 = 4'd3;
      10'b00001????? : f_clz10 = 4'd4;
      10'b000001???? : f_clz10 = 4'd5;
      10'b0000001??? : f_clz10 = 4'd6;
      10'b00000001?? : f_clz10 = 4'd7;
      10'b000000001? : f_clz10 = 4'd8;
      10'b0000000001 : f_clz10 = 4'd9;
      default        : f_clz10 = 4'd0;
    endcase
  endfunction

  // decode finite fp16 into {normalised mantissa (0 if zero), exponent};
  // exponent is 6-bit two's complement, value = m * 2^(e-10).
  function automatic logic [16:0] f_decode(input logic [15:0] v);
    logic [10:0] m;
    logic [5:0]  e;
    logic [3:0]  clz;
    clz = f_clz10(v[9:0]);
    if (v[14:10] == 5'd0) begin
      m = {1'b0, v[9:0]} << (clz + 4'd1);
      e = 6'd49 - {2'b00, clz};          // -15 - clz  in [-24,-15]
    end else begin
      m = {1'b1, v[9:0]};
      e = {1'b0, v[14:10]} - 6'd15;      // in [-14,15]
    end
    f_decode = {m, e};
  endfunction

  function automatic logic [5:0] f_lod40(input logic [39:0] v);
    logic [5:0] p;
    p = 6'd0;
    for (int i = 0; i < 40; i++) begin
      if (v[i]) p = i[5:0];
    end
    f_lod40 = p;
  endfunction

  // rounding increment: g = guard, st = sticky(inexact below guard),
  // lsb = LSB of truncated magnitude, sgn = sign of exact result.
  function automatic logic f_inc(input logic g, input logic st, input logic lsb,
                                 input logic sgn, input logic [2:0] rnd);
    logic r;
    case (rnd)
      3'd0:    r = g & (st | lsb);        // RNE
      3'd1:    r = 1'b0;                  // RTZ
      3'd2:    r = sgn & (g | st);        // RDN
      3'd3:    r = (~sgn) & (g | st);     // RUP
      3'd4:    r = g;                     // RMM
      default: r = 1'b0;
    endcase
    f_inc = r;
  endfunction

  // --------------------------------------------------------------------------
  // shared state / broadcast weight decode
  // --------------------------------------------------------------------------
  logic [WIDTH-1:0][HEIGHT-1:0][15:0] sres;   // per-stage result register
  logic [WIDTH-1:0][HEIGHT-1:0][15:0] sd2;     // per-stage 2nd delay register
  logic [WIDTH-1:0][15:0]             fbq;    // z_o delayed one tick (feedback)
  logic [WIDTH-1:0]                   fprev;  // flush seen at previous enabled tick

  logic [HEIGHT-1:0][16:0] wdec;
  logic [HEIGHT-1:0]       w_isN, w_isI, w_isZ;

  always_comb begin
    for (int kk = 0; kk < HEIGHT; kk++) begin
      wdec[kk]  = f_decode(w_i[kk]);
      w_isN[kk] = (w_i[kk][14:10] == 5'd31) && (w_i[kk][9:0] != 10'd0);
      w_isI[kk] = (w_i[kk][14:10] == 5'd31) && (w_i[kk][9:0] == 10'd0);
      w_isZ[kk] = (w_i[kk][14:10] == 5'd0)  && (w_i[kk][9:0] == 10'd0);
    end
  end

  // --------------------------------------------------------------------------
  // rows / stages
  // --------------------------------------------------------------------------
  for (genvar r = 0; r < WIDTH; r++) begin : g_row
    wire row_gate = row_clk_gate_en_i[r];
    wire row_tick  = row_gate & reg_enable_i;
    wire row_fclr  = row_gate & flush_i;    // flush outranks reg_enable_i (C2)

    for (genvar k = 0; k < HEIGHT; k++) begin : g_stage

      // -------- pre-edge: operand decode + exact product -------------------
      logic [15:0] a_v, c_v;
      logic [16:0] ad, cd;
      logic [21:0] mp_c;
      logic [6:0]  epx_c;
      logic [9:0]  sfl_c;

      always_comb begin
        a_v = x_i[r][k];
        if (k == 0) begin
          c_v = accumulate_i ? fbq[r] : y_i[r];   // feedback depth d(0)+1 (C3)
        end else begin
          c_v = sd2[r][k-1];
        end
        ad     = f_decode(a_v);
        cd     = f_decode(c_v);
        mp_c   = ad[16:6] * wdec[k][16:6];
        epx_c = $signed({ad[5], ad[5:0]}) + $signed({wdec[k][5], wdec[k][5:0]});
        sfl_c = {(a_v[14:10] == 5'd31) && (a_v[9:0] != 10'd0),  // [9] aN
                 w_isN[k],                                       // [8] bN
                 (c_v[14:10] == 5'd31) && (c_v[9:0] != 10'd0),  // [7] cN
                 (a_v[14:10] == 5'd31) && (a_v[9:0] == 10'd0),  // [6] aI
                 w_isI[k],                                       // [5] bI
                 (c_v[14:10] == 5'd31) && (c_v[9:0] == 10'd0),  // [4] cI
                 (a_v[14:10] == 5'd0)  && (a_v[9:0] == 10'd0),  // [3] aZ
                 w_isZ[k],                                       // [2] bZ
                 (c_v[14:10] == 5'd0)  && (c_v[9:0] == 10'd0),  // [1] cZ
                 (c_v[14:10] == 5'd0)  && (c_v[9:0] != 10'd0)}; // [0] csub
      end

      // -------- sample registers -------------------------------------------
      logic [21:0] s_mp;
      logic [6:0]  s_epx;
      logic        s_sP;
      logic [10:0] s_mc;
      logic [5:0]  s_Ec;
      logic [15:0] s_c;
      logic [2:0]  s_rnd;
      logic [9:0]  s_fl;

      always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
          s_mp <= 22'd0;  s_epx <= 7'd0;  s_sP <= 1'b0;
          s_mc <= 11'd0;  s_Ec  <= 6'd0;  s_c  <= 16'd0;
          s_rnd <= 3'd0;  s_fl  <= 10'd0;
        end else if (row_fclr) begin
          s_mp <= 22'd0;  s_epx <= 7'd0;  s_sP <= 1'b0;
          s_mc <= 11'd0;  s_Ec  <= 6'd0;  s_c  <= 16'd0;
          s_rnd <= 3'd0;  s_fl  <= 10'd0;
        end else if (row_tick) begin
          s_mp  <= mp_c;
          s_epx <= epx_c;
          s_sP  <= a_v[15] ^ w_i[k][15];
          s_mc  <= cd[16:6];
          s_Ec  <= cd[5:0];
          s_c   <= c_v;
          s_rnd <= rnd_i;
          s_fl  <= sfl_c;
        end
      end

      // -------- post-edge: exact align + add + normalise + round ------------
      logic [15:0] zres;
      logic [4:0]  zfl;

      always_comb begin
        logic [39:0] A, B, M, tmp40;
        logic [47:0] Mx, tmp48;
        logic signed [7:0] d;
        logic [4:0]  shl;
        logic [7:0]  rsh8;
        logic [3:0]  rsh4;
        logic        sticky;
        logic        sgn;
        logic [5:0]  p;
        logic signed [7:0] E, sh2;
        logic [7:0]  rt;
        logic [4:0]  shl2;
        logic [5:0]  nsh;
        logic [3:0]  psh;
        logic [10:0] q0, q;
        logic        gd, st, inc;
        logic [9:0]  f0;
        logic [10:0] f;
        logic signed [7:0] E15;
        logic        done;

        zres = 16'h0000;
        zfl  = 5'b00000;
        done = 1'b0;

        if (s_fl[9] || s_fl[8] || s_fl[7]) begin
          // any NaN operand -> canonical qNaN, no flag
          zres = 16'h7E00;
        end else if (s_fl[6] || s_fl[5]) begin
          // infinite product
          if ((s_fl[3] && s_fl[5]) || (s_fl[6] && s_fl[2])) begin
            zres = 16'h7E00;                 // inf * 0
            zfl  = 5'b10000;                  // NV
          end else if (s_fl[4]) begin
            if (s_c[15] == s_sP) begin
              zres = s_sP ? 16'hFC00 : 16'h7C00;
            end else begin
              zres = 16'h7E00;               // inf - inf
              zfl  = 5'b10000;                // NV
            end
          end else begin
            zres = s_sP ? 16'hFC00 : 16'h7C00;
          end
        end else if (s_fl[4]) begin
          zres = s_c;                         // finite * finite + inf
        end else if (s_fl[3] || s_fl[2]) begin
          // zero product: result is the addend
          if (s_fl[1]) begin
            if (s_sP == s_c[15]) begin
              zres = s_sP ? 16'h8000 : 16'h0000;
            end else begin
              zres = (s_rnd == 3'd2) ? 16'h8000 : 16'h0000;  // A8
            end
          end else begin
            zres = s_c;
          end
        end else begin
          // -------- finite arithmetic, single rounding --------
          B      = 40'd0;
          sticky = 1'b0;
          if (!s_fl[1]) begin
            d = $signed({{2{s_Ec[5]}}, s_Ec}) - $signed({{1{s_epx[6]}}, s_epx});
            if (d >= 8'sd17) begin
              // addend dominates: exact sum rounds to the addend (guard = 0)
              zres = s_c;
              zfl  = {3'b000, s_fl[0], 1'b1};       // UF if addend subnormal, NX
              done = 1'b1;
            end else if (d <= -8'sd14) begin
              // product dominates: addend only reaches guard/sticky
              rsh8 = -(d + 8'sd13);
              if (rsh8 >= 8'd11) begin
                B      = 40'd0;
                sticky = (s_mc != 11'd0);
              end else begin
                rsh4   = rsh8[3:0];
                B      = {29'd0, (s_mc >> rsh4)};
                sticky = |(s_mc & ((11'd1 << rsh4) - 11'd1));
              end
            end else begin
              // exact overlap: addend inside the 40-bit field
              shl = (d + 8'sd13);
              B   = {29'd0, s_mc} << shl;
            end
          end
          if (!done) begin
            A = {18'd0, s_mp} << 3;
            if (s_sP == s_c[15]) begin
              M = A + B;  sgn = s_sP;
            end else if (A >= B) begin
              M = A - B;  sgn = s_sP;
            end else else begin
              M = B - A;  sgn = s_c[15];
            end
            if (M == 40'd0) begin
              // exact zero (cancellation): +0, -0 under RDN alone (A8)
              if (s_sP == s_c[15]) begin
                zres = s_sP ? 16'h8000 : 16'h0000;
              end else begin
                zres = (s_rnd == 3'd2) ? 16'h8000 : 16'h0000;
              end
            end else begin
              p = f_lod40(M);
              E = $signed({{1{s_epx[6]}}, s_epx}) + $signed({2'b00, p}) - 8'sd23;
              if (E >= -8'sd14) begin
                // -------- normal result --------
                if (p >= 6'd10) begin
                  nsh   = p - 6'd10;
                  tmp40 = M >> nsh;
                  q0    = tmp40[10:0];
                  if (nsh == 6'd0) begin
                    gd = 1'b0;
                    st = sticky;
                  end else begin
                    gd = M[nsh - 6'd1];
                    st = (|(M & ((40'd1 << (nsh - 6'd1)) - 40'd1))) | sticky;
                  end
                  inc = f_inc(gd, st, q0[0], sgn, s_rnd);
                  q   = q0 + {10'd0, inc};
                  if (q == 11'd2048) begin
                    q = 11'd1024;
                    E = E + 8'sd1;
                  end
                  if (E >= 8'sd16) begin
                    // overflow: A5 table
                    zfl = 5'b00101;                          // OF | NX
                    case (s_rnd)
                      3'd1:    zres = sgn ? 16'hFBFF : 16'h7BFF;  // RTZ
                      3'd2:    zres = sgn ? 16'hFC00 : 16'h7BFF;  // RDN
                      3'd3:    zres = sgn ? 16'hFBFF : 16'h7C00;  // RUP
                      default: zres = sgn ? 16'hFC00 : 16'h7C00;  // RNE/RMM
                    endcase
                  end else begin
                    E15  = E + 8'sd15;
                    zres = {sgn, E15[4:0], q[9:0]};
                    zfl[0] = gd | st;
                  end
                end else begin
                  // exact, no low bits can have been discarded here
                  psh   = 4'd10 - p[3:0];
                  tmp40 = M << psh;
                  q     = tmp40[10:0];
                  E15   = E + 8'sd15;
                  zres  = {sgn, E15[4:0], q[9:0]};
                end
              end else begin
                // -------- subnormal / zero result --------
                sh2 = $signed({{1{s_epx[6]}}, s_epx}) + 8'sd1;
                Mx  = {8'd0, M};
                if (sh2 >= 8'sd0) begin
                  shl2  = sh2[4:0];
                  tmp48 = Mx << shl2;
                  f0    = tmp48[9:0];
                  gd    = 1'b0;
                  st    = 1'b0;
                end else begin
                  rt    = 8'd0 - sh2;
                  tmp48 = Mx >> rt;
                  f0    = tmp48[9:0];
                  gd    = Mx[rt - 8'd1];
                  st    = |(Mx & ((48'd1 << (rt - 8'd1)) - 48'd1));
                end
                inc = f_inc(gd, st, f0[0], sgn, s_rnd);
                f   = {1'b0, f0} + {10'd0, inc};
                if (f == 11'd1024) begin
                  zres = {sgn, 15'h0400};                    // rounded to 2^-14
                  zfl  = {3'b000, (gd | st), (gd | st)};
                end else if (f == 11'd0) begin
                  zres = sgn ? 16'h8000 : 16'h0000;          // A6, sign kept
                  zfl  = 5'b00011;                           // UF | NX
                end else begin
                  zres = {sgn, 5'd0, f[9:0]};
                  zfl  = {3'b000, (gd | st), (gd | st)};     // A7: exact -> 0
                end
              end
            end
          end
        end
      end

      // -------- result / delay / status registers ---------------------------
      logic [15:0] sd1;

      always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
          sres[r][k] <= 16'd0;
          sd1        <= 16'd0;
          sd2[r][k]  <= 16'd0;
        end else if (row_fclr) begin
          sres[r][k] <= 16'd0;                     // simultaneous flush (C2)
          sd1        <= 16'd0;
          sd2[r][k]  <= 16'd0;
        end else if (row_tick) begin
          sres[r][k] <= zres;
          sd1        <= sres[r][k];
          sd2[r][k]  <= sd1;
        end
      end

      always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
          status_o[r][k] <= 5'd0;
        end else if (row_tick && (!flush_i || !fprev[r])) begin
          status_o[r][k] <= zfl;                   // A10 / C2 suspension
        end
      end
    end
  end

    // -------- row-level output, feedback and flush tracking -----------------
    always_ff @(posedge clk_i or negedge rst_ni) begin
      if (!rst_ni) begin
        z_o[r]   <= 16'd0;
        fbq[r]   <= 16'd0;
        fprev[r] <= 1'b0;
      end else begin
        if (row_fclr) begin
          z_o[r] <= 16'd0;                          // z_o = +0 while flushed
          fbq[r] <= 16'd0;
        end else if (row_tick) begin
          z_o[r] <= sres[r][HEIGHT-1];
          fbq[r] <= z_o[r];                         // z_o one tick deeper
        end
        if (row_tick) begin
          fprev[r] <= flush_i;
        end
      end
    end

  end
endmodule
