// =============================================================================
// fp32_fma_ii1.sv -- IEEE-754 binary32 fused multiply-add, II = 1, latency 3
// -----------------------------------------------------------------------------
// Structure. The dataflow is cut into the four segments S1 names, with the
// three register boundaries falling between them:
//
//   stage 1  classify, normalise the operands, form the exact 48-bit product
//   -- reg --
//   stage 2  align the addend into the accumulator, one add
//   -- reg --
//   stage 3  leading-zero count of the sum, normalising shift
//   -- reg --
//   stage 4  round once, pack, flags                      (combinational out)
//
// A result therefore appears exactly 3 clocks after its operands are accepted
// (S1), and a new operation is accepted every cycle (C3): the pipeline has no
// feedback and nothing in it can stall except a stalled consumer.
//
// The arithmetic, and why it is shaped this way
// ---------------------------------------------
// Every operand is pre-normalised into a common form -- a 24-bit significand
// with its MSB set, and a signed exponent -- so a subnormal is just an operand
// with a smaller exponent. Nothing is flushed and there is no separate
// subnormal path to stall on (A3).
//
// The product is formed exactly (48 bits) and the addend is aligned into an
// 80-bit fixed-point accumulator with 4 guard positions below the product LSB.
// There is exactly ONE rounding, of the exact product-plus-addend (A1): the
// product is never rounded on its way into the accumulator, which is what makes
// a = b = 1 + 2^-12 against c = -(1 + 2^-11) return 2^-24 rather than zero.
//
// Alignment shifts saturate. Past saturation the smaller term can only reach
// the sticky region, which is what makes saturating safe -- but the left
// saturation must also carry its lost magnitude into the result exponent, which
// is what `esc` does. Dropping that compensation gives the right mantissa with
// the wrong exponent on roughly a quarter of random vectors.
//
// A9, the datapath bound. The widest significand signal in this module is the
// 80-bit alignment accumulator (ACC_W): the 48-bit exact product placed with 4
// guard positions below it, the addend aligned above it with saturation, and
// one carry bit -- 3*p + 8, which is the "3p plus guard, round and sticky"
// shape A9 sanctions and well inside its 4*p = 96 ceiling. Alignment shifts
// SATURATE rather than widening the accumulator: everything below the window
// collapses into the sticky bit, which is exactly what A9 permits. Nothing
// here scales with the operand exponents, so no input can widen the datapath.
//
// A6 is implemented as written, not as IEEE 7.5 states it: underflow is
// inexactness AND a delivered biased exponent field of zero. That is read off
// the packed result, after rounding and after the overflow substitution, so the
// round-up-to-smallest-normal band reports no underflow (delivered field is 1)
// and a tiny inexact result that rounds to zero does report it (field is 0).
// No second rounding with an unbounded exponent range is computed anywhere,
// because this contract does not ask for one.
// =============================================================================

`timescale 1ns/1ps

module fp32_fma_ii1 (
    input  logic        clk,
    input  logic        rst_n,

    // ---- operand input ------------------------------------------------------
    input  logic        in_valid,
    output logic        in_ready,
    input  logic [31:0] a,          // IEEE-754 binary32
    input  logic [31:0] b,
    input  logic [31:0] c,
    input  logic [2:0]  rnd_mode,   // 0 RNE, 1 RTZ, 2 RDN, 3 RUP, 4 RMM

    // ---- result output ------------------------------------------------------
    output logic        out_valid,
    input  logic        out_ready,
    output logic [31:0] result,
    output logic        flag_invalid,
    output logic        flag_overflow,
    output logic        flag_underflow,
    output logic        flag_inexact
);

  // ---------------------------------------------------------------------------
  // Geometry
  // ---------------------------------------------------------------------------
  localparam int PW    = 24;          // significand width
  localparam int PW2   = 48;          // exact product
  localparam int ACC_W = 80;          // alignment accumulator
  localparam int L_MAX = 55;          // left-align saturation
  localparam int BIAS  = 127;

  localparam logic [31:0] QNAN   = 32'h7FC00000;
  localparam logic [31:0] INF_P  = 32'h7F800000;
  localparam logic [31:0] SGN_B  = 32'h80000000;
  localparam logic [31:0] MAXN   = 32'h7F7FFFFF;

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------
  // Round-up decision, all five modes (A2).
  function automatic logic rup_f(input logic [2:0] rm, input logic sgn,
                                 input logic lsb, input logic gb, input logic sb);
    case (rm)
      3'd0:    rup_f = gb & (sb | lsb);        // RNE
      3'd1:    rup_f = 1'b0;                   // RTZ
      3'd2:    rup_f = sgn & (gb | sb);        // RDN
      3'd3:    rup_f = (~sgn) & (gb | sb);     // RUP
      3'd4:    rup_f = gb;                     // RMM
      default: rup_f = 1'b0;                   // 5..7 out of scope
    endcase
  endfunction

  // Leading-zero counts. The loop variables are deliberately not named `i`, and
  // no caller invokes these from a loop condition.
  function automatic int lzc24(input logic [PW-1:0] v);
    int li;
    begin
      lzc24 = PW;
      for (li = 0; li < PW; li = li + 1)
        if (v[li]) lzc24 = PW - 1 - li;
    end
  endfunction

  function automatic int lzc80(input logic [ACC_W-1:0] v);
    int lj;
    begin
      lzc80 = ACC_W;
      for (lj = 0; lj < ACC_W; lj = lj + 1)
        if (v[lj]) lzc80 = ACC_W - 1 - lj;
    end
  endfunction

  // ---------------------------------------------------------------------------
  // Handshake. in_ready is a function of out_valid and out_ready only, never of
  // in_valid (H1). A stalled consumer freezes the whole pipeline, so the held
  // result and flags are stable (H3), and order is structural (H4).
  // ---------------------------------------------------------------------------
  logic v1, v2, v3;
  logic en;

  assign out_valid = v3;
  assign en        = ~(v3 & ~out_ready);
  assign in_ready  = en;

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      v1 <= 1'b0;
      v2 <= 1'b0;
      v3 <= 1'b0;
    end else if (en) begin
      v1 <= in_valid;
      v2 <= v1;
      v3 <= v2;
    end
  end

  // ---------------------------------------------------------------------------
  // Stage 1 : classify, pre-normalise, multiply
  // ---------------------------------------------------------------------------
  logic [PW2-1:0]     n1_mp;
  logic [PW-1:0]      n1_sigcn;
  logic signed [15:0] n1_ep, n1_tsh;
  logic               n1_sp, n1_sc, n1_zc, n1_pz;
  logic [2:0]         n1_rnd;
  logic               n1_spv, n1_snv;
  logic [31:0]        n1_sres;

  logic [PW2-1:0]     r1_mp;
  logic [PW-1:0]      r1_sigcn;
  logic signed [15:0] r1_ep, r1_tsh;
  logic               r1_sp, r1_sc, r1_zc, r1_pz;
  logic [2:0]         r1_rnd;
  logic               r1_spv, r1_snv;
  logic [31:0]        r1_sres;

  always_comb begin
    logic               sa, sb_, sc_;
    logic [7:0]         fa, fb, fc;
    logic [22:0]        mua, mub, muc;
    logic               za, zb, zc, ina, inb, inc;
    logic               nna, nnb, nnc, sna, snb, snc;
    logic [PW-1:0]      siga, sigb, sigc, sigan, sigbn, sigcn;
    int                 lza, lzb, lzc_;
    int                 ea, eb, ec;
    logic               zsgn;

    sa  = a[31]; fa = a[30:23]; mua = a[22:0];
    sb_ = b[31]; fb = b[30:23]; mub = b[22:0];
    sc_ = c[31]; fc = c[30:23]; muc = c[22:0];

    za  = (fa == 8'h00) && (mua == 23'd0);
    zb  = (fb == 8'h00) && (mub == 23'd0);
    zc  = (fc == 8'h00) && (muc == 23'd0);
    ina = (fa == 8'hFF) && (mua == 23'd0);
    inb = (fb == 8'hFF) && (mub == 23'd0);
    inc = (fc == 8'hFF) && (muc == 23'd0);
    nna = (fa == 8'hFF) && (mua != 23'd0);
    nnb = (fb == 8'hFF) && (mub != 23'd0);
    nnc = (fc == 8'hFF) && (muc != 23'd0);
    sna = nna && !mua[22];
    snb = nnb && !mub[22];
    snc = nnc && !muc[22];

    // value = sig * 2^(exp-23); a subnormal is simply exp = 1-BIAS
    siga = {(fa != 8'h00), mua};
    sigb = {(fb != 8'h00), mub};
    sigc = {(fc != 8'h00), muc};
    ea   = (fa == 8'h00) ? (1 - BIAS) : ($signed({24'd0, fa}) - BIAS);
    eb   = (fb == 8'h00) ? (1 - BIAS) : ($signed({24'd0, fb}) - BIAS);
    ec   = (fc == 8'h00) ? (1 - BIAS) : ($signed({24'd0, fc}) - BIAS);

    // pre-normalise: this is what keeps subnormals at full precision (A3)
    lza   = lzc24(siga);
    lzb   = lzc24(sigb);
    lzc_  = lzc24(sigc);
    sigan = siga << lza;
    sigbn = sigb << lzb;
    sigcn = sigc << lzc_;
    ea    = ea - lza;
    eb    = eb - lzb;
    ec    = ec - lzc_;

    n1_mp    = {{PW{1'b0}}, sigan} * {{PW{1'b0}}, sigbn};   // exact, unrounded
    n1_sigcn = sigcn;
    n1_ep    = 16'(ea + eb - 2*(PW-1));    // weight of the product LSB
    n1_tsh   = 16'(ec - (PW-1) - (ea + eb - 2*(PW-1)) + 4);
    n1_sp    = sa ^ sb_;
    n1_sc    = sc_;
    n1_zc    = zc;
    n1_pz    = za | zb;
    n1_rnd   = rnd_mode;

    // ---- special values, resolved here and carried past the datapath -------
    zsgn    = 1'b0;
    n1_spv  = 1'b1;
    n1_snv  = 1'b0;
    n1_sres = QNAN;
    if (sna | snb | snc) begin                       // signalling NaN operand
      n1_sres = QNAN; n1_snv = 1'b1;
    end else if ((za & inb) | (ina & zb)) begin      // 0 * Inf
      n1_sres = QNAN; n1_snv = 1'b1;
    end else if (nna | nnb | nnc) begin              // quiet NaN operand
      n1_sres = QNAN; n1_snv = 1'b0;
    end else if (ina | inb) begin                    // infinite product
      if (inc && (sc_ != (sa ^ sb_))) begin
        n1_sres = QNAN; n1_snv = 1'b1;               // Inf - Inf
      end else begin
        n1_sres = INF_P | ((sa ^ sb_) ? SGN_B : 32'd0);
      end
    end else if (inc) begin                          // infinite addend
      n1_sres = INF_P | (sc_ ? SGN_B : 32'd0);
    end else if (za | zb) begin                      // 0*b + c is exactly c
      if (zc) begin
        zsgn    = ((sa ^ sb_) == sc_) ? sc_ : (rnd_mode == 3'd2);
        n1_sres = zsgn ? SGN_B : 32'd0;
      end else begin
        n1_sres = c;
      end
    end else begin
      n1_spv = 1'b0;
    end
  end

  always_ff @(posedge clk) begin
    if (en) begin
      r1_mp    <= n1_mp;
      r1_sigcn <= n1_sigcn;
      r1_ep    <= n1_ep;
      r1_tsh   <= n1_tsh;
      r1_sp    <= n1_sp;
      r1_sc    <= n1_sc;
      r1_zc    <= n1_zc;
      r1_pz    <= n1_pz;
      r1_rnd   <= n1_rnd;
      r1_spv   <= n1_spv;
      r1_snv   <= n1_snv;
      r1_sres  <= n1_sres;
    end
  end

  // ---------------------------------------------------------------------------
  // Stage 2 : align the addend, one add
  // ---------------------------------------------------------------------------
  logic [ACC_W-1:0]   n2_sum;
  logic               n2_stky, n2_sr;
  logic signed [15:0] n2_epx;

  logic [ACC_W-1:0]   r2_sum;
  logic               r2_stky, r2_sr;
  logic signed [15:0] r2_epx;
  logic [2:0]         r2_rnd;
  logic               r2_spv, r2_snv;
  logic [31:0]        r2_sres;

  always_comb begin
    logic [ACC_W-1:0] acc_p, acc_c;
    logic [PW2-1:0]   tmp2;
    int               tt, ss, esc;
    logic             stky_c, eff_sub;

    acc_p = r1_pz ? {ACC_W{1'b0}} : ({{(ACC_W-PW2){1'b0}}, r1_mp} << 4);
    esc   = 0;
    tt    = 0;
    ss    = 0;
    tmp2  = {PW2{1'b0}};

    if (r1_zc || r1_pz) begin
      acc_c  = {ACC_W{1'b0}};
      stky_c = 1'b0;
    end else if (r1_tsh >= 16'sd0) begin
      tt     = (r1_tsh > 16'sd55) ? L_MAX : int'(r1_tsh);
      esc    = int'(r1_tsh) - tt;        // saturated: rescale the accumulator
      acc_c  = {{(ACC_W-PW){1'b0}}, r1_sigcn} << tt;
      stky_c = 1'b0;
    end else begin
      ss     = ((0 - int'(r1_tsh)) > PW) ? PW : (0 - int'(r1_tsh));
      tmp2   = {r1_sigcn, {PW{1'b0}}} >> ss;
      acc_c  = {{(ACC_W-PW){1'b0}}, tmp2[PW2-1:PW]};
      stky_c = |tmp2[PW-1:0];
    end

    eff_sub = r1_sp ^ r1_sc;
    if (!eff_sub) begin
      n2_sum = acc_p + acc_c;    n2_stky = stky_c; n2_sr = r1_sp;
    end else if (stky_c) begin
      // acc_p strictly dominates here; the discarded tail is a borrow
      n2_sum = acc_p - acc_c - 1; n2_stky = 1'b1;  n2_sr = r1_sp;
    end else if (acc_p >= acc_c) begin
      n2_sum = acc_p - acc_c;    n2_stky = 1'b0;   n2_sr = r1_sp;
    end else begin
      n2_sum = acc_c - acc_p;    n2_stky = 1'b0;   n2_sr = r1_sc;
    end

    n2_epx = r1_ep + 16'(esc);
  end

  always_ff @(posedge clk) begin
    if (en) begin
      r2_sum  <= n2_sum;
      r2_stky <= n2_stky;
      r2_sr   <= n2_sr;
      r2_epx  <= n2_epx;
      r2_rnd  <= r1_rnd;
      r2_spv  <= r1_spv;
      r2_snv  <= r1_snv;
      r2_sres <= r1_sres;
    end
  end

  // ---------------------------------------------------------------------------
  // Stage 3 : leading-zero count and normalising shift
  // ---------------------------------------------------------------------------
  logic [ACC_W-1:0]   n3_norm;
  logic signed [15:0] n3_exp;
  logic               n3_szero;

  logic [ACC_W-1:0]   r3_norm;
  logic signed [15:0] r3_exp;
  logic               r3_szero, r3_stky, r3_sr;
  logic [2:0]         r3_rnd;
  logic               r3_spv, r3_snv;
  logic [31:0]        r3_sres;

  always_comb begin
    int lzs;
    lzs      = lzc80(r2_sum);
    n3_norm  = r2_sum << lzs;
    n3_exp   = r2_epx - 16'sd4 + 16'(ACC_W - 1 - lzs);
    n3_szero = (r2_sum == {ACC_W{1'b0}});   // exact cancellation
  end

  always_ff @(posedge clk) begin
    if (en) begin
      r3_norm  <= n3_norm;
      r3_exp   <= n3_exp;
      r3_szero <= n3_szero;
      r3_stky  <= r2_stky;
      r3_sr    <= r2_sr;
      r3_rnd   <= r2_rnd;
      r3_spv   <= r2_spv;
      r3_snv   <= r2_snv;
      r3_sres  <= r2_sres;
    end
  end

  // ---------------------------------------------------------------------------
  // Stage 4 : round once, pack, flags  (combinational from the stage-3 registers)
  // ---------------------------------------------------------------------------
  always_comb begin
    logic [ACC_W-1:0]   mask;
    logic [31:0]        sig_r, sigp, res_n;
    logic               gbit, stk, ru, carry, res_sub, want_inf;
    logic signed [15:0] shr_full, qexp, qf, bexp;
    int                 shr, ts;
    logic               ovf, nxf;

    shr_full = 16'sd1 - 16'sd127 - r3_exp;           // emin - exp

    if (shr_full <= 16'sd0)              shr = 0;
    else if (shr_full > 16'sd26)         shr = 26;   // beyond this all is sticky
    else                                 shr = int'(shr_full);
    qexp = (shr_full > 16'sd0) ? (16'sd1 - 16'sd127) : r3_exp;

    // ts runs 56..82 against an 80-bit accumulator. A shift past the top
    // yields zero on its own; only the round-bit select needs a guard, and
    // above the MSB that bit is zero because r3_norm is normalised.
    ts    = (ACC_W - PW) + shr;
    sig_r = 32'(r3_norm >> ts);
    gbit  = ((ts-1) < ACC_W) ? r3_norm[ts-1] : 1'b0;
    mask  = {ACC_W{1'b1}} << (ts-1);
    stk   = (|(r3_norm & ~mask)) | r3_stky;

    ru    = rup_f(r3_rnd, r3_sr, sig_r[0], gbit, stk);
    sigp  = sig_r + {31'b0, ru};
    carry = sigp[PW];
    res_sub = (!carry) && (!sigp[PW-1]);

    qf   = qexp + (carry ? 16'sd1 : 16'sd0);
    bexp = qf + 16'sd127;
    ovf  = (bexp >= 16'sd255);
    nxf  = gbit | stk | ovf;                          // A4b: overflow is inexact
    want_inf = (r3_rnd == 3'd0) || (r3_rnd == 3'd4) ||
               ((r3_rnd == 3'd3) && !r3_sr) || ((r3_rnd == 3'd2) && r3_sr);

    if (ovf)
      res_n = (want_inf ? INF_P : MAXN) | (r3_sr ? SGN_B : 32'd0);
    else
      res_n = {r3_sr, (res_sub ? 8'd0 : bexp[7:0]), sigp[22:0]};

    // ---- output mux -------------------------------------------------------
    if (r3_spv) begin
      result         = r3_sres;
      flag_invalid   = r3_snv;
      flag_overflow  = 1'b0;
      flag_underflow = 1'b0;
      flag_inexact   = 1'b0;
    end else if (r3_szero) begin                      // exact zero (A5)
      result         = (r3_rnd == 3'd2) ? SGN_B : 32'd0;
      flag_invalid   = 1'b0;
      flag_overflow  = 1'b0;
      flag_underflow = 1'b0;
      flag_inexact   = 1'b0;
    end else begin
      result         = res_n;
      flag_invalid   = 1'b0;
      flag_overflow  = ovf;
      // A6, exactly as pinned: inexact AND the DELIVERED exponent field is zero
      flag_underflow = nxf & (res_n[30:23] == 8'd0);
      flag_inexact   = nxf;
    end
  end

endmodule