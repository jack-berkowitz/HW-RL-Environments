// =============================================================================
// fp_multifmt_fma.sv
// -----------------------------------------------------------------------------
// Multi-format (FP32 / FP16 / BF16) vectorial FUSED multiply-add.
//
// Structure
//   * WIDTH/16 lane slots.  Slot k always covers result bits [16k +: 16].
//     - 16-bit formats: slot k is lane k.
//     - FP32:           slot k (k even) is lane k/2 and covers [16k +: 32];
//                       odd slots are unused, so their cores are built with
//                       en32 tied low and collapse to the 16-bit datapath.
//   * One shared core.  Every operand is widened to a common internal form
//         value = sig * 2^(exp - 23),  sig 24 bits, left-aligned mantissa,
//     so the three formats differ only in unpack, in the rounding precision
//     (24 / 11 / 8) and in the exponent bias.  BF16 is 8/7, FP16 is 5/10.
//   * The product is formed exactly (48b) and the addend is aligned into an
//     80-bit fixed-point accumulator with 4 guard positions below the product
//     LSB.  There is exactly ONE rounding, of the exact product-plus-addend.
//   * Alignment shifts saturate.  Past saturation the smaller term can only
//     reach the sticky region, which is why saturation is safe; the left
//     saturation additionally compensates the result exponent (esc).
//   * Subnormals are pre-normalised on the way in and re-materialised on the
//     way out.  Nothing is flushed.
//   * Tininess is detected AFTER rounding, by rounding a second time with an
//     unbounded exponent range and testing that result against 2^emin.
//
// All procedural loop bounds are compile-time constants (T5); the runtime lane
// count is applied as a guard inside the loop, never as a bound.
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
  // Geometry of the shared datapath
  // ---------------------------------------------------------------------------
  localparam int PW    = 24;               // internal significand width
  localparam int PW2   = 2*PW;             // exact product width
  localparam int ACC_W = 3*PW + 8;         // 80 : alignment accumulator
  localparam int L_MAX = 2*PW + 7;         // 55 : left-align saturation
  localparam int NORMW = ACC_W + 8;        // 88 : padded, for variable extracts
  localparam int NSLOT = WIDTH/16;         // lane slots (2 or 4)

  // ---------------------------------------------------------------------------
  // Round-up decision, all five modes
  // ---------------------------------------------------------------------------
  function automatic logic rup_f(input logic [2:0] rm,
                                 input logic       sgn,
                                 input logic       lsb,
                                 input logic       gb,
                                 input logic       sb);
    case (rm)
      3'd0:    rup_f = gb & (sb | lsb);      // RNE
      3'd1:    rup_f = 1'b0;                 // RTZ
      3'd2:    rup_f = sgn & (gb | sb);      // RDN
      3'd3:    rup_f = (~sgn) & (gb | sb);   // RUP
      3'd4:    rup_f = gb;                   // RMM
      default: rup_f = 1'b0;
    endcase
  endfunction

  // ---------------------------------------------------------------------------
  // One scalar fused multiply-add.  Returns {flags[4:0], result[31:0]}.
  // 16-bit formats are returned right-aligned with a zeroed upper half.
  // ---------------------------------------------------------------------------
  function automatic logic [36:0] fma_core(input logic       en32,
                                           input logic [1:0] fmt,
                                           input logic [31:0] a,
                                           input logic [31:0] b,
                                           input logic [31:0] c,
                                           input logic [2:0]  rm);
    // ---- declarations (all before the first statement, T2) ------------------
    integer            i;
    logic              sa, sb, sc;
    logic [7:0]        fa, fb, fc;
    logic [22:0]       mua, mub, muc;
    logic [7:0]        expall;
    int                expall_i, bias, prec, emin;
    logic [31:0]       qnan_v, infp_v, sgn_v, maxn_v;
    logic              za, zb, zc, ina, inb, inc;
    logic              nna, nnb, nnc, sna, snb, snc;
    logic [PW-1:0]     siga, sigb, sigc, sigan, sigbn, sigcn;
    int                ea, eb, ec, ep, ecl, tsh, esc;
    int                lza, lzb, lzc, lzs;
    logic [PW2-1:0]    mp, tmp2;
    logic [ACC_W-1:0]  acc_p, acc_c, accsum, norm;
    int                tt, ss;
    logic              stky_c, stky_lo, sp, sr, eff_sub, prod_zero;
    int                exp_n, shr_full, shr, qexp, qf, bexp, ts, ts_unb, q_unb;
    logic [NORMW-1:0]  normw, sh_r, sh_u;
    logic [31:0]       sig_r, sig_u, sigp, sigu;
    logic              gbit, stk, gbit_u, stk_u, ru, ru_u, carry, carry_u;
    logic              tiny, ovf, nxf, uff, res_sub, want_inf, zsign;
    logic [31:0]       res;
    logic [4:0]        fl;

    // ---- unpack: one 24-bit left-aligned form for all three formats ---------
    if (en32 && (fmt == 2'd0)) begin              // FP32  1 / 8 / 23
      sa = a[31]; fa = a[30:23]; mua = a[22:0];
      sb = b[31]; fb = b[30:23]; mub = b[22:0];
      sc = c[31]; fc = c[30:23]; muc = c[22:0];
      expall = 8'hFF; expall_i = 255; bias = 127; prec = 24;
      qnan_v = 32'h7FC00000; infp_v = 32'h7F800000;
      sgn_v  = 32'h80000000; maxn_v = 32'h7F7FFFFF;
    end else if (fmt == 2'd1) begin               // FP16  1 / 5 / 10
      sa = a[15]; fa = {3'b000, a[14:10]}; mua = {a[9:0], 13'b0};
      sb = b[15]; fb = {3'b000, b[14:10]}; mub = {b[9:0], 13'b0};
      sc = c[15]; fc = {3'b000, c[14:10]}; muc = {c[9:0], 13'b0};
      expall = 8'd31; expall_i = 31; bias = 15; prec = 11;
      qnan_v = 32'h00007E00; infp_v = 32'h00007C00;
      sgn_v  = 32'h00008000; maxn_v = 32'h00007BFF;
    end else begin                                // BF16  1 / 8 / 7
      sa = a[15]; fa = a[14:7]; mua = {a[6:0], 16'b0};
      sb = b[15]; fb = b[14:7]; mub = {b[6:0], 16'b0};
      sc = c[15]; fc = c[14:7]; muc = {c[6:0], 16'b0};
      expall = 8'hFF; expall_i = 255; bias = 127; prec = 8;
      qnan_v = 32'h00007FC0; infp_v = 32'h00007F80;
      sgn_v  = 32'h00008000; maxn_v = 32'h00007F7F;
    end
    emin = 1 - bias;

    // ---- classify -----------------------------------------------------------
    za  = (fa == 8'd0) && (mua == 23'd0);
    zb  = (fb == 8'd0) && (mub == 23'd0);
    zc  = (fc == 8'd0) && (muc == 23'd0);
    ina = (fa == expall) && (mua == 23'd0);
    inb = (fb == expall) && (mub == 23'd0);
    inc = (fc == expall) && (muc == 23'd0);
    nna = (fa == expall) && (mua != 23'd0);
    nnb = (fb == expall) && (mub != 23'd0);
    nnc = (fc == expall) && (muc != 23'd0);
    sna = nna && !mua[22];
    snb = nnb && !mub[22];
    snc = nnc && !muc[22];

    // ---- significands and unbiased exponents; subnormals get their true value
    siga = {(fa != 8'd0), mua};
    sigb = {(fb != 8'd0), mub};
    sigc = {(fc != 8'd0), muc};
    ea = (fa == 8'd0) ? (1 - bias) : ($signed({24'b0, fa}) - bias);
    eb = (fb == 8'd0) ? (1 - bias) : ($signed({24'b0, fb}) - bias);
    ec = (fc == 8'd0) ? (1 - bias) : ($signed({24'b0, fc}) - bias);

    // ---- pre-normalise (this is what keeps subnormals at full precision) ----
    lza = PW; lzb = PW; lzc = PW;
    for (i = 0; i < PW; i = i + 1) begin
      if (siga[i]) lza = PW - 1 - i;
      if (sigb[i]) lzb = PW - 1 - i;
      if (sigc[i]) lzc = PW - 1 - i;
    end
    sigan = siga << lza;
    sigbn = sigb << lzb;
    sigcn = sigc << lzc;
    ea = ea - lza;
    eb = eb - lzb;
    ec = ec - lzc;

    // ---- exact product, and the addend's alignment target -------------------
    mp  = {{PW{1'b0}}, sigan} * {{PW{1'b0}}, sigbn};
    ep  = ea + eb - 2*(PW-1);        // weight of mp's LSB
    ecl = ec - (PW-1);               // weight of sigcn's LSB
    tsh = ecl - ep + 4;              // addend LSB position in the accumulator
    sp  = sa ^ sb;
    prod_zero = za | zb;

    // ---- align -------------------------------------------------------------
    acc_p = prod_zero ? {ACC_W{1'b0}} : ({{(ACC_W-PW2){1'b0}}, mp} << 4);
    esc   = 0;
    tt    = 0;
    ss    = 0;
    tmp2  = {PW2{1'b0}};
    if (zc || prod_zero) begin
      acc_c  = {ACC_W{1'b0}};
      stky_c = 1'b0;
    end else if (tsh >= 0) begin
      tt     = (tsh > L_MAX) ? L_MAX : tsh;
      esc    = tsh - tt;             // saturated: rescale the whole accumulator
      acc_c  = {{(ACC_W-PW){1'b0}}, sigcn} << tt;
      stky_c = 1'b0;
    end else begin
      ss     = ((0 - tsh) > PW) ? PW : (0 - tsh);
      tmp2   = {sigcn, {PW{1'b0}}} >> ss;
      acc_c  = {{(ACC_W-PW){1'b0}}, tmp2[PW2-1:PW]};
      stky_c = |tmp2[PW-1:0];
    end

    // ---- the single add ----------------------------------------------------
    eff_sub = sp ^ sc;
    if (!eff_sub) begin
      accsum = acc_p + acc_c;   stky_lo = stky_c; sr = sp;
    end else if (stky_c) begin
      // acc_p strictly dominates here, and the discarded addend tail is a
      // borrow: subtract one ulp and leave a residual sticky.
      accsum = acc_p - acc_c - 1; stky_lo = 1'b1;  sr = sp;
    end else if (acc_p >= acc_c) begin
      accsum = acc_p - acc_c;   stky_lo = 1'b0;   sr = sp;
    end else begin
      accsum = acc_c - acc_p;   stky_lo = 1'b0;   sr = sc;
    end

    // ---- normalise ---------------------------------------------------------
    lzs = ACC_W;
    for (i = 0; i < ACC_W; i = i + 1) if (accsum[i]) lzs = ACC_W - 1 - i;
    norm  = accsum << lzs;
    exp_n = ep - 4 + esc + (ACC_W - 1 - lzs);

    // ---- rounding position: normal, or clamped to the subnormal grid -------
    shr_full = emin - exp_n;
    if (shr_full <= 0)                 shr = 0;
    else if (shr_full > (prec + 2))    shr = prec + 2;
    else                               shr = shr_full;
    qexp   = (shr_full > 0) ? emin : exp_n;
    ts_unb = ACC_W - prec;
    ts     = ts_unb + shr;
    normw  = {{(NORMW-ACC_W){1'b0}}, norm};

    sh_r  = normw >> ts;
    sig_r = sh_r[31:0];
    gbit  = normw[ts-1];
    stk   = (|(normw & ~({NORMW{1'b1}} << (ts-1)))) | stky_lo;

    // the same value rounded with an unbounded exponent range: this, and only
    // this, is what tininess-after-rounding is defined against
    sh_u   = normw >> ts_unb;
    sig_u  = sh_u[31:0];
    gbit_u = normw[ts_unb-1];
    stk_u  = (|(normw & ~({NORMW{1'b1}} << (ts_unb-1)))) | stky_lo;

    ru      = rup_f(rm, sr, sig_r[0], gbit, stk);
    sigp    = sig_r + {31'b0, ru};
    carry   = sigp[prec];
    ru_u    = rup_f(rm, sr, sig_u[0], gbit_u, stk_u);
    sigu    = sig_u + {31'b0, ru_u};
    carry_u = sigu[prec];
    q_unb   = exp_n + (carry_u ? 1 : 0);
    tiny    = (q_unb < emin);

    res_sub = (!carry) && (!sigp[prec-1]);
    qf      = qexp + (carry ? 1 : 0);
    bexp    = qf + bias;
    ovf     = (bexp >= expall_i);
    nxf     = gbit | stk | ovf;
    uff     = tiny & (gbit | stk);
    want_inf = (rm == 3'd0) || (rm == 3'd4) ||
               ((rm == 3'd3) && !sr) || ((rm == 3'd2) && sr);

    // ---- pack the numeric result -------------------------------------------
    if (ovf) begin
      res = (want_inf ? infp_v : maxn_v) | (sr ? sgn_v : 32'b0);
    end else if (en32 && (fmt == 2'd0)) begin
      res = {sr, (res_sub ? 8'd0 : bexp[7:0]),  sigp[22:0]};
    end else if (fmt == 2'd1) begin
      res = {16'b0, sr, (res_sub ? 5'd0 : bexp[4:0]), sigp[9:0]};
    end else begin
      res = {16'b0, sr, (res_sub ? 8'd0 : bexp[7:0]), sigp[6:0]};
    end
    fl = {1'b0, 1'b0, ovf, uff, nxf};

    // ---- special cases override, in IEEE / task priority order -------------
    zsign = 1'b0;
    if (sna | snb | snc) begin                       // signalling NaN operand
      res = qnan_v; fl = 5'b10000;
    end else if ((za & inb) | (ina & zb)) begin      // 0 * inf, beats a qNaN c
      res = qnan_v; fl = 5'b10000;
    end else if (nna | nnb | nnc) begin              // quiet NaN operand
      res = qnan_v; fl = 5'b00000;
    end else if (ina | inb) begin                    // infinite product
      if (inc && (sc != sp)) begin
        res = qnan_v; fl = 5'b10000;                 // inf - inf
      end else begin
        res = infp_v | (sp ? sgn_v : 32'b0); fl = 5'b00000;
      end
    end else if (inc) begin                          // infinite addend
      res = infp_v | (sc ? sgn_v : 32'b0); fl = 5'b00000;
    end else if (prod_zero) begin                    // 0 + c is exactly c
      if (zc) begin
        zsign = (sp == sc) ? sc : ((rm == 3'd2) ? 1'b1 : 1'b0);
        res = zsign ? sgn_v : 32'b0;
      end else begin
        res = c;
      end
      fl = 5'b00000;
    end else if (accsum == {ACC_W{1'b0}}) begin      // exact cancellation
      res = (rm == 3'd2) ? sgn_v : 32'b0;
      fl = 5'b00000;
    end

    fma_core = {fl, res};
  endfunction

  // ---------------------------------------------------------------------------
  // Lane slots
  // ---------------------------------------------------------------------------
  logic [36:0] lane_out [NSLOT];
  logic [15:0] chunk    [NSLOT];
  logic [WIDTH-1:0] res_c;
  logic [4:0]       fl_c;
  integer           kk;

  genvar g;
  generate
    for (g = 0; g < NSLOT; g = g + 1) begin : g_lane
      // even slots may carry an FP32 lane; for odd slots this base is legal but
      // unreachable, so the FP32 datapath constant-folds away there.
      localparam int B32 = ((g % 2) == 0) ? 16*g : 16*(g-1);
      logic [31:0] la, lb, lc;

      always_comb begin
        if (((g % 2) == 0) && (fmt_i == 2'd0)) begin
          la = a_i[B32 +: 32];
          lb = b_i[B32 +: 32];
          lc = c_i[B32 +: 32];
        end else begin
          // narrow formats: the slot's 16 bits only. Operand bits outside the
          // lanes in use never reach the datapath.
          la = {16'b0, a_i[16*g +: 16]};
          lb = {16'b0, b_i[16*g +: 16]};
          lc = {16'b0, c_i[16*g +: 16]};
        end
      end

      assign lane_out[g] = fma_core(((g % 2) == 0) ? 1'b1 : 1'b0,
                                    fmt_i, la, lb, lc, rnd_i);
    end

    // Result assembly. Slots not in use read back all ones (NaN-boxing).
    for (g = 0; g < NSLOT; g = g + 1) begin : g_asm
      always_comb begin
        chunk[g] = 16'hFFFF;
        if (fmt_i == 2'd0) begin
          // FP32 lane (g/2): lane 0 always live, higher lanes only when vector
          if ((g < 2) || vec_i)
            chunk[g] = ((g % 2) == 0) ? lane_out[(g/2)*2][15:0]
                                      : lane_out[(g/2)*2][31:16];
        end else begin
          if ((g == 0) || vec_i)
            chunk[g] = lane_out[g][15:0];
        end
      end
      assign res_c[16*g +: 16] = chunk[g];
    end
  endgenerate

  // flags are the bitwise OR across the lanes in use
  always_comb begin
    fl_c = 5'b00000;
    for (kk = 0; kk < NSLOT; kk = kk + 1) begin
      if (fmt_i == 2'd0) begin
        if (((kk % 2) == 0) && ((kk == 0) || vec_i)) fl_c = fl_c | lane_out[kk][36:32];
      end else begin
        if ((kk == 0) || vec_i)                      fl_c = fl_c | lane_out[kk][36:32];
      end
    end
  end

  // ---------------------------------------------------------------------------
  // Handshake: one output register. in_ready_o does not depend on in_valid_i
  // and out_valid_o does not depend on out_ready_i, so neither side can wedge.
  // Results leave in the order they arrived.
  // ---------------------------------------------------------------------------
  assign in_ready_o = (!out_valid_o) | out_ready_i;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      out_valid_o <= 1'b0;
      result_o    <= {WIDTH{1'b0}};
      flags_o     <= 5'b00000;
    end else if (in_valid_i && in_ready_o) begin
      out_valid_o <= 1'b1;
      result_o    <= res_c;
      flags_o     <= fl_c;
    end else if (out_ready_i) begin
      out_valid_o <= 1'b0;
    end
  end

endmodule