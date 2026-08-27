// =============================================================================
// fp_multifmt_fma.sv -- shared-datapath fused multiply-add over FP32/FP16/BF16
//                       with WIDTH/format_width SIMD lanes.
//
// THE IDEA THAT MAKES ONE DATAPATH SERVE THREE FORMATS.
//   A floating-point value is sig * 2^e, and that value is unchanged by
//   (sig << k, e - k).  So every operand is decoded with its OWN geometry and
//   then LEFT-ALIGNED to a common 24-bit significand: FP32 shifts by 0, FP16 by
//   13, BF16 by 16.  After that single step the alignment, addition,
//   normalisation and rounding hardware is literally identical for all three
//   formats -- one fixed field geometry, no per-format widths -- and the format
//   survives only in five constants used at the very end:
//
//     fmt   EXP MAN BIAS  D=23-MAN  E_min=1-BIAS
//     FP32   8   23  127     0        -126
//     FP16   5   10   15    13         -14
//     BF16   8    7  127    16        -126
//
//   BF16 IS NOT FP16.  They share only their width; here they share only the
//   16-bit slot they are unpacked from, and differ in every constant above.
//
// SINGLE ROUNDING (A1).  The 48-bit product and the addend are placed into ONE
// 53-bit fixed-point field in which BOTH are exact, summed there, and rounded
// once.  Nothing is rounded before the add.
//
// WHY 53 BITS SUFFICES, and this is the load-bearing argument.  Subnormal
// operands are pre-normalised, so after left-alignment every nonzero
// significand has bit 23 set and the product is always >= 2^46.  The field
// holds the product at [50:3] with three guard bits below and 25 bits of
// headroom above.  Bits are discarded (into sticky) only when one term lies
// wholly below the other's significant range, and in exactly those cases the
// two differ by enough magnitude that no cancellation can promote a discarded
// bit into the result.  Where cancellation IS possible the exponents are close,
// the shift is small, and the sum is exact.
//
// DATAPATH WIDTH (A8).  The widest significand vector is the 78-bit rounding
// vector; the alignment field is 53 and the sum 55.  The ceiling is 4*p = 96 at
// FP32, and this datapath is the FP32 one shared downward -- which is what "one
// datapath, three formats" means.  Nothing carries an unbounded intermediate.
//
// UNDERFLOW (A7a).  UF = inexact AND the DELIVERED exponent field is zero, read
// off the result actually driven.  So the round-up-to-smallest-normal band
// delivers exponent field 1 and sets NX without UF, and a tiny inexact result
// that rounds to zero sets UF because its field is zero.  This is the rule the
// task pins, NOT IEEE 754-2019 clause 7.5's, and it is applied per lane before
// V4's OR.
//
// LANES.  WIDTH/16 cores.  Core k always owns 16-bit slot k; cores below
// WIDTH/32 additionally own 32-bit slot k for FP32.  Cores that can never see
// FP32 have their format input forced narrow, so their multiplier operands
// carry >= 13 constant-zero low bits and synthesis prunes them.  No lane reads
// another lane's operands (V2).
//
// Every declaration precedes every statement in its block (T2); every loop has
// a constant bound and the whole unroll is ~130 iterations per core (T5).
// =============================================================================

module fp_multifmt_fma #(
    parameter int unsigned WIDTH = 64        // {32, 64}
) (
    input  logic             clk_i,
    input  logic             rst_ni,         // active low

    // ---- operation in -------------------------------------------------------
    input  logic             in_valid_i,
    output logic             in_ready_o,
    input  logic [1:0]       fmt_i,          // 0 = FP32, 1 = FP16, 2 = BF16
    input  logic             vec_i,          // 1 = packed SIMD lanes
    input  logic [WIDTH-1:0] a_i,
    input  logic [WIDTH-1:0] b_i,
    input  logic [WIDTH-1:0] c_i,
    input  logic [2:0]       rnd_i,          // 0 RNE, 1 RTZ, 2 RDN, 3 RUP, 4 RMM

    // ---- result out ---------------------------------------------------------
    output logic             out_valid_o,
    input  logic             out_ready_i,
    output logic [WIDTH-1:0] result_o,
    output logic [4:0]       flags_o         // {NV, DZ, OF, UF, NX}
);

  localparam int unsigned N16 = WIDTH / 16;   // 16-bit lanes / cores: 2 or 4
  localparam int unsigned N32 = WIDTH / 32;   // 32-bit lanes:         1 or 2

  localparam logic [2:0] RNE = 3'd0;
  localparam logic [2:0] RTZ = 3'd1;
  localparam logic [2:0] RDN = 3'd2;
  localparam logic [2:0] RUP = 3'd3;
  localparam logic [2:0] RMM = 3'd4;

  // ---------------------------------------------------------------------------
  // helpers
  // ---------------------------------------------------------------------------
  function automatic logic [4:0] clz24(input logic [23:0] v);
    logic [4:0] n;
    logic       found;
    n     = 5'd24;
    found = 1'b0;
    for (int i = 0; i < 24; i++) begin
      if (!found && v[23-i]) begin
        n     = i[4:0];
        found = 1'b1;
      end
    end
    return n;
  endfunction

  // index of the highest set bit (0 when v is zero)
  function automatic logic [5:0] msb54(input logic [53:0] v);
    logic [5:0] p;
    p = 6'd0;
    for (int i = 0; i < 54; i++) begin
      if (v[i]) p = i[5:0];
    end
    return p;
  endfunction

  // right shift, collecting everything discarded into one sticky bit
  function automatic logic [53:0] shr53(input logic [52:0] v, input logic [5:0] sh);
    logic [52:0] t;
    logic        st;
    t  = v;
    st = 1'b0;
    if (sh[5]) begin st = st | (|t[31:0]); t = t >> 32; end
    if (sh[4]) begin st = st | (|t[15:0]); t = t >> 16; end
    if (sh[3]) begin st = st | (|t[7:0]);  t = t >> 8;  end
    if (sh[2]) begin st = st | (|t[3:0]);  t = t >> 4;  end
    if (sh[1]) begin st = st | (|t[1:0]);  t = t >> 2;  end
    if (sh[0]) begin st = st |   t[0];     t = t >> 1;  end
    return {st, t};
  endfunction

  function automatic logic [78:0] shr78(input logic [77:0] v, input logic [6:0] sh);
    logic [77:0] t;
    logic        st;
    t  = v;
    st = 1'b0;
    if (sh[6]) begin st = st | (|t[63:0]); t = t >> 64; end
    if (sh[5]) begin st = st | (|t[31:0]); t = t >> 32; end
    if (sh[4]) begin st = st | (|t[15:0]); t = t >> 16; end
    if (sh[3]) begin st = st | (|t[7:0]);  t = t >> 8;  end
    if (sh[2]) begin st = st | (|t[3:0]);  t = t >> 4;  end
    if (sh[1]) begin st = st | (|t[1:0]);  t = t >> 2;  end
    if (sh[0]) begin st = st |   t[0];     t = t >> 1;  end
    return {st, t};
  endfunction

  // ---------------------------------------------------------------------------
  // DECODE one operand of the selected format into the common representation.
  // Returns {sig24[23:0], e24[11:0], is_nan, is_snan, is_inf, is_zero, sign}.
  // sig24 is LEFT-ALIGNED to 24 bits and pre-normalised, so value = sig24*2^e24
  // and every nonzero significand has bit 23 set whatever the format was.
  // ---------------------------------------------------------------------------
  function automatic logic [40:0] fdec(input logic [31:0] x, input logic [1:0] fmt);
    logic               sgn, enz, mnz, mmsb;
    logic [7:0]         ef, maxe;
    logic signed [11:0] bias, ebase;
    logic [23:0]        raw, sig;
    logic [4:0]         lz;
    logic               f_nan, f_snan, f_inf, f_zero;

    case (fmt)
      2'd0: begin
        sgn  = x[31];
        ef   = x[30:23];
        mnz  = (x[22:0] != 23'd0);
        mmsb = x[22];
        maxe = 8'd255;
        bias = 12'sd127;
      end
      2'd1: begin
        sgn  = x[15];
        ef   = {3'b000, x[14:10]};
        mnz  = (x[9:0] != 10'd0);
        mmsb = x[9];
        maxe = 8'd31;
        bias = 12'sd15;
      end
      default: begin
        sgn  = x[15];
        ef   = x[14:7];
        mnz  = (x[6:0] != 7'd0);
        mmsb = x[6];
        maxe = 8'd255;
        bias = 12'sd127;
      end
    endcase

    enz = (ef != 8'd0);

    // left-align the significand: FP32 by 0, FP16 by 13, BF16 by 16
    case (fmt)
      2'd0:    raw = {enz, x[22:0]};
      2'd1:    raw = {enz, x[9:0], 13'b0};
      default: raw = {enz, x[6:0], 16'b0};
    endcase

    f_nan  = (ef == maxe) &&  mnz;
    f_snan = f_nan && !mmsb;
    f_inf  = (ef == maxe) && !mnz;
    f_zero = !enz && !mnz;

    // A subnormal has stored exponent 0 but real exponent 1; after left
    // alignment the mantissa scale is the same for every format, so this one
    // expression covers all three.
    ebase = (enz ? $signed({4'b0, ef}) : 12'sd1) - bias - 12'sd23;
    lz    = clz24(raw);
    sig   = raw << lz;

    return {sig, (ebase - $signed({7'b0, lz})), f_nan, f_snan, f_inf, f_zero, sgn};
  endfunction

  // ---------------------------------------------------------------------------
  // ONE LANE.  Returns {result[31:0], flags[4:0]}; a 16-bit format uses the low
  // 16 bits of the result.
  // ---------------------------------------------------------------------------
  function automatic logic [36:0] fma_core(input logic [31:0] a,
                                           input logic [31:0] b,
                                           input logic [31:0] c,
                                           input logic [1:0]  fmt,
                                           input logic [2:0]  rnd);
    logic [40:0]        da, db, dc;
    logic [23:0]        siga, sigb, sigc;
    logic signed [11:0] ea, eb, ec, ep;
    logic               sa, sb, sc, sp;
    logic               a_nan, b_nan, c_nan, a_snan, b_snan, c_snan;
    logic               a_inf, b_inf, c_inf, a_zr, b_zr, c_zr;

    logic signed [11:0] diff, anchor, shmag, sub_lim, exp_pre, exp_f, sh_sig;
    logic [47:0]        prod;
    logic [52:0]        shin, prod_f, add_f;
    logic [53:0]        shout;
    logic [5:0]         shamt;
    logic               lost, eps_sign;

    logic signed [54:0] sum;
    logic [53:0]        magp, mag;
    logic               rsign, sub1, zres, zsign;
    logic [5:0]         msb;

    logic [6:0]         sh;
    logic               normal;
    logic [77:0]        em;
    logic [78:0]        so;
    logic [24:0]        r25, mr;
    logic [23:0]        mant;
    logic               gbit, sticky, inexact, inc, ovf, to_inf, carry, subbit;

    logic [4:0]         dsh;
    logic signed [11:0] bias, emin;
    logic [7:0]         maxe;
    logic [31:0]        res, qnan_v, inf_v, ovf_v, num_v, zero_v;
    logic [4:0]         flg;
    logic               isign;

    // ---- per-format constants ----
    case (fmt)
      2'd0: begin
        dsh = 5'd0;  bias = 12'sd127; emin = -12'sd126; maxe = 8'd255;
      end
      2'd1: begin
        dsh = 5'd13; bias = 12'sd15;  emin = -12'sd14;  maxe = 8'd31;
      end
      default: begin
        dsh = 5'd16; bias = 12'sd127; emin = -12'sd126; maxe = 8'd255;
      end
    endcase

    da = fdec(a, fmt);
    db = fdec(b, fmt);
    dc = fdec(c, fmt);

    siga = da[40:17]; ea = $signed(da[16:5]);
    sigb = db[40:17]; eb = $signed(db[16:5]);
    sigc = dc[40:17]; ec = $signed(dc[16:5]);
    a_nan = da[4]; a_snan = da[3]; a_inf = da[2]; a_zr = da[1]; sa = da[0];
    b_nan = db[4]; b_snan = db[3]; b_inf = db[2]; b_zr = db[1]; sb = db[0];
    c_nan = dc[4]; c_snan = dc[3]; c_inf = dc[2]; c_zr = dc[1]; sc = dc[0];
    sp = sa ^ sb;

    prod = siga * sigb;                       // exact, never rounded (A1)
    ep   = ea + eb;

    // Which term is anchored.  A zero product forces the addend-anchored case
    // and a zero addend the product-anchored one, so a meaningless exponent
    // from a zero operand can never select the anchor.
    if (a_zr || b_zr)  diff = 12'sd200;
    else if (c_zr)     diff = -12'sd200;
    else               diff = ec - ep - 12'sd26;

    anchor = (diff > 12'sd0) ? (ec - 12'sd29) : (ep - 12'sd3);

    // One shifter: the smaller term is shifted, its lost bits become sticky.
    if (diff > 12'sd0) begin
      shin  = {2'b0, prod, 3'b0};
      shmag = diff;
      shamt = (shmag > 12'sd51) ? 6'd51 : shmag[5:0];
    end else begin
      shin  = {sigc, 29'b0};
      shmag = -diff;
      shamt = (shmag > 12'sd53) ? 6'd53 : shmag[5:0];
    end

    shout = shr53(shin, shamt);
    lost  = shout[53];

    if (diff > 12'sd0) begin
      prod_f   = shout[52:0];
      add_f    = {sigc, 29'b0};
      eps_sign = sp;                          // the product supplied lost bits
    end else begin
      prod_f   = {2'b0, prod, 3'b0};
      add_f    = shout[52:0];
      eps_sign = sc;                          // the addend supplied them
    end

    sum = (sp ? -$signed({2'b0, prod_f}) : $signed({2'b0, prod_f}))
        + (sc ? -$signed({2'b0, add_f})  : $signed({2'b0, add_f}));

    rsign = sum[54];
    magp  = rsign ? (54'd0 - sum[53:0]) : sum[53:0];

    // The bits shifted out during alignment are a fraction of one field LSB
    // carrying the shifted term's sign.  When that sign opposes the result's,
    // the true magnitude is one ulp lower with a nonzero remainder, so the
    // field is decremented and sticky is set.  Without this, a large product
    // minus a far-below addend rounds as if the addend were absent.
    sub1 = lost & (rsign ^ eps_sign);
    mag  = magp - {53'b0, sub1};

    // An exact zero can only arise with nothing lost below the field.
    zres  = (sum == 55'sd0) && !lost;
    zsign = (sp == sc) ? sp : (rnd == RDN);   // A6
    msb   = msb54(mag);

    // A normal result puts its LSB MAN below the leading one; a subnormal one
    // puts it at the format's minimum instead, which is the larger shift.  The
    // max covers both, so there is no separate subnormal path.  The +dsh is
    // what re-widens the narrow formats' rounding window.
    sub_lim = emin - anchor;
    normal  = (mag != 54'd0) && ($signed({6'b0, msb}) >= sub_lim);
    sh_sig  = $signed({7'b0, dsh})
            + (normal ? $signed({6'b0, msb}) : sub_lim);
    sh      = (sh_sig > 12'sd78) ? 7'd78
            : (sh_sig < 12'sd0)  ? 7'd0
                                 : sh_sig[6:0];

    em     = {mag, 24'b0};
    so     = shr78(em, sh);
    sticky = so[78] | lost;
    r25    = so[24:0];
    mant   = r25[24:1];
    gbit   = r25[0];

    exp_pre = normal ? (anchor + $signed({6'b0, msb}) + bias) : 12'sd0;
    inexact = gbit | sticky;

    case (rnd)
      RTZ:     inc = 1'b0;
      RDN:     inc = rsign     & (gbit | sticky);
      RUP:     inc = (~rsign)  & (gbit | sticky);
      RMM:     inc = gbit;
      default: inc = gbit & (sticky | mant[0]);      // RNE
    endcase

    mr = {1'b0, mant} + {24'b0, inc};

    // Carry out of this format's significand, and the bit that promotes a
    // subnormal to the smallest normal -- the A7a band that must NOT report UF.
    case (fmt)
      2'd0:    begin carry = mr[24]; subbit = mr[23]; end
      2'd1:    begin carry = mr[11]; subbit = mr[10]; end
      default: begin carry = mr[8];  subbit = mr[7];  end
    endcase

    exp_f = normal ? (exp_pre + {11'b0, carry}) : {11'b0, subbit};
    ovf   = normal && (exp_f >= $signed({4'b0, maxe}));

    to_inf = (rnd == RNE) || (rnd == RMM)
          || ((rnd == RUP) && !rsign) || ((rnd == RDN) && rsign);

    // ---- per-format encodings ----
    case (fmt)
      2'd0: begin
        qnan_v = 32'h7FC0_0000;
        ovf_v  = to_inf ? {rsign, 8'hFF, 23'h0} : {rsign, 8'hFE, 23'h7FFFFF};
        num_v  = {rsign, exp_f[7:0], mr[22:0]};
        zero_v = {zsign, 31'b0};
      end
      2'd1: begin
        qnan_v = {16'h0000, 16'h7E00};
        ovf_v  = to_inf ? {16'h0000, rsign, 5'h1F, 10'h0}
                        : {16'h0000, rsign, 5'h1E, 10'h3FF};
        num_v  = {16'h0000, rsign, exp_f[4:0], mr[9:0]};
        zero_v = {16'h0000, zsign, 15'b0};
      end
      default: begin
        qnan_v = {16'h0000, 16'h7FC0};
        ovf_v  = to_inf ? {16'h0000, rsign, 8'hFF, 7'h0}
                        : {16'h0000, rsign, 8'hFE, 7'h7F};
        num_v  = {16'h0000, rsign, exp_f[7:0], mr[6:0]};
        zero_v = {16'h0000, zsign, 15'b0};
      end
    endcase

    // ---- special values, in this order.  0*inf outranks a NaN operand (A5).
    // The sign of an infinite result comes from whichever term is infinite --
    // NOT from rsign, which is the sum's sign and means nothing on this path.
    isign = (a_inf || b_inf) ? sp : sc;
    case (fmt)
      2'd0:    inf_v = {isign, 8'hFF, 23'h0};
      2'd1:    inf_v = {16'h0000, isign, 5'h1F, 10'h0};
      default: inf_v = {16'h0000, isign, 8'hFF, 7'h0};
    endcase

    if ((a_inf && b_zr) || (a_zr && b_inf)) begin
      res = qnan_v;                           // 0 * inf, whatever c is
      flg = 5'b10000;
    end else if (a_nan || b_nan || c_nan) begin
      res = qnan_v;
      flg = {(a_snan | b_snan | c_snan), 4'b0000};
    end else if ((a_inf || b_inf) && c_inf && (sc != sp)) begin
      res = qnan_v;                           // inf - inf
      flg = 5'b10000;
    end else if (a_inf || b_inf || c_inf) begin
      res = inf_v;
      flg = 5'b00000;
    end else if (zres) begin
      res = zero_v;                           // A6 sign rule
      flg = 5'b00000;
    end else if (ovf) begin
      res = ovf_v;
      flg = 5'b00101;                         // OF always sets NX too (A7)
    end else begin
      res = num_v;
      // A7a: underflow is read off the DELIVERED exponent field.
      flg = {3'b000, inexact & (exp_f == 12'sd0), inexact};
    end
    return {res, flg};
  endfunction

  // ---------------------------------------------------------------------------
  // Lanes.  Core k owns 16-bit slot k always, and 32-bit slot k when k < N32.
  // ---------------------------------------------------------------------------
  logic [N16-1:0][36:0] core_o;
  logic [N16-1:0]       lane_act;

  genvar k;
  generate
    for (k = 0; k < N16; k++) begin : g_core
      logic [31:0] ca, cb, cc;
      logic [1:0]  cfmt;

      if (k < N32) begin : g_wide
        // this core can be handed a 32-bit FP32 lane
        assign ca   = (fmt_i == 2'd0) ? a_i[k*32 +: 32] : {16'b0, a_i[k*16 +: 16]};
        assign cb   = (fmt_i == 2'd0) ? b_i[k*32 +: 32] : {16'b0, b_i[k*16 +: 16]};
        assign cc   = (fmt_i == 2'd0) ? c_i[k*32 +: 32] : {16'b0, c_i[k*16 +: 16]};
        assign cfmt = fmt_i;
      end else begin : g_narrow
        // this core never sees FP32, so its format is forced narrow.  That
        // leaves >= 13 constant-zero low bits on the multiplier operands and
        // lets synthesis prune the wide part away.
        assign ca   = {16'b0, a_i[k*16 +: 16]};
        assign cb   = {16'b0, b_i[k*16 +: 16]};
        assign cc   = {16'b0, c_i[k*16 +: 16]};
        assign cfmt = (fmt_i == 2'd0) ? 2'd1 : fmt_i;
      end

      assign core_o[k] = fma_core(ca, cb, cc, cfmt, rnd_i);

      // V1: N = vec ? WIDTH/fmt_width : 1.  Both index tests are elaboration
      // constants, so only vec_i is a runtime term.
      assign lane_act[k] = (fmt_i == 2'd0) ? ((k < N32) && (vec_i || (k == 0)))
                                           : (vec_i || (k == 0));
    end
  endgenerate

  // ---------------------------------------------------------------------------
  // Result assembly.  V3: bits above the lanes in use read all ones.
  // V4: flags are the bitwise OR across the lanes in use only.
  // Loop bounds are the constants N16/N32 with a runtime guard inside (T5).
  // ---------------------------------------------------------------------------
  always_comb begin
    result_o = {WIDTH{1'b1}};
    flags_o  = 5'b00000;

    for (int kk = 0; kk < N16; kk++) begin
      if (lane_act[kk]) flags_o = flags_o | core_o[kk][4:0];
    end

    if (fmt_i == 2'd0) begin
      for (int jj = 0; jj < N32; jj++) begin
        if (lane_act[jj]) result_o[jj*32 +: 32] = core_o[jj][36:5];
      end
    end else begin
      for (int kk = 0; kk < N16; kk++) begin
        if (lane_act[kk]) result_o[kk*16 +: 16] = core_o[kk][20:5];
      end
    end
  end

  // ---------------------------------------------------------------------------
  // Handshake.  Combinational, which L4 states is conformant and is what the
  // reference is.  in_ready_o follows out_ready_i and out_valid_o follows
  // in_valid_i -- both PERMITTED paths; neither forbidden path exists, since
  // in_ready_o does not read in_valid_i and out_valid_o does not read
  // out_ready_i.  Order is trivially preserved (H2) and progress is
  // unconditional (C1).
  // ---------------------------------------------------------------------------
  assign in_ready_o  = out_ready_i;
  assign out_valid_o = in_valid_i;

  // clk_i / rst_ni are unused: this unit holds no state.
  logic unused_ok;
  assign unused_ok = clk_i | rst_ni;

endmodule