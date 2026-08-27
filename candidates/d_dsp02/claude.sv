// =============================================================================
// fp32_fma_ii1.sv -- IEEE-754 binary32 fused multiply-add, II=1, latency 3.
//
// SINGLE ROUNDING (A1). The 48-bit product and the addend are placed into ONE
// 53-bit fixed-point alignment field in which BOTH are exact, added there, and
// rounded once. Nothing is rounded before the add.
//
// WHY 53 BITS IS ENOUGH, and this is the load-bearing argument:
//   Subnormal operands are pre-normalised, so every nonzero significand has bit
//   23 set and the product is always >= 2^46. The field holds the product at
//   [50:3] with 3 low guard bits and 25 bits of headroom above it. Bits are
//   discarded (into sticky) only when one term sits wholly below the other's
//   significant range, and in exactly those cases the terms differ by enough
//   magnitude that no cancellation can promote a discarded bit into the result.
//   Where cancellation IS possible the two terms are close in exponent, the
//   shift is small, and the sum is exact. Without pre-normalisation this fails:
//   a subnormal product can be smaller than a subnormal addend whose low bits
//   have already been shifted out, and those bits are then significant.
//
// The alignment is ONE shifter, not two: whichever term is the smaller is the
// one shifted, and the anchor moves with it.
//
// DATAPATH WIDTH (A9): the widest significand vector is the 78-bit rounding
// vector {mag, 24'b0}; the alignment field is 53 and the sum 55. All well
// inside the 96-bit ceiling. Nothing carries an unbounded intermediate.
//
// UNDERFLOW (A6): UF = inexact AND the DELIVERED exponent field is zero. That
// is read off the result actually driven, so the round-up-to-smallest-normal
// band delivers exponent field 1 and sets NX without UF, and a tiny inexact
// result that rounds to zero sets UF because its field is zero. This is the
// rule the task pins, NOT IEEE 754-2019 clause 7.5's.
//
// PIPELINE (S1): three register boundaries, so the result appears exactly 3
// clocks after acceptance, and one operation is accepted every cycle (C3).
//   stage A  classify, pre-normalise, multiply, align
//   stage B  add, absolute value, sticky borrow, leading-one search
//   stage C  place the rounding window, round, assemble, flags
//
// Every declaration precedes every statement in its block (T2), and every loop
// has a constant bound.
// =============================================================================

`timescale 1ns/1ps

module fp32_fma_ii1 (
    input  logic        clk,
    input  logic        rst_n,

    input  logic        in_valid,
    output logic        in_ready,
    input  logic [31:0] a,
    input  logic [31:0] b,
    input  logic [31:0] c,
    input  logic [2:0]  rnd_mode,

    output logic        out_valid,
    input  logic        out_ready,
    output logic [31:0] result,
    output logic        flag_invalid,
    output logic        flag_overflow,
    output logic        flag_underflow,
    output logic        flag_inexact
);

  localparam logic [2:0] RNE = 3'd0;
  localparam logic [2:0] RTZ = 3'd1;
  localparam logic [2:0] RDN = 3'd2;
  localparam logic [2:0] RUP = 3'd3;
  localparam logic [2:0] RMM = 3'd4;

  localparam logic [31:0] CANON_QNAN = 32'h7FC0_0000;

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

  // right shift collecting everything discarded into one sticky bit
  function automatic logic [53:0] shr53_sticky(input logic [52:0] v, input logic [5:0] sh);
    logic [52:0] t;
    logic        st;
    t  = v;
    st = 1'b0;
    if (sh[5]) begin st = st | (|t[31:0]); t = t >> 32; end
    if (sh[4]) begin st = st | (|t[15:0]); t = t >> 16; end
    if (sh[3]) begin st = st | (|t[7:0]);  t = t >> 8;  end
    if (sh[2]) begin st = st | (|t[3:0]);  t = t >> 4;  end
    if (sh[1]) begin st = st | (|t[1:0]);  t = t >> 2;  end
    if (sh[0]) begin st = st | t[0];       t = t >> 1;  end
    return {st, t};
  endfunction

  function automatic logic [78:0] shr78_sticky(input logic [77:0] v, input logic [6:0] sh);
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
    if (sh[0]) begin st = st | t[0];       t = t >> 1;  end
    return {st, t};
  endfunction

  // ---------------------------------------------------------------------------
  // flow control.  in_ready depends on out_ready and on our own output-stage
  // occupancy, NEVER on in_valid (H1); out_valid is a register, never a
  // function of out_ready (H1b).  With out_ready held high the enable is
  // permanently high, so one operation is accepted every cycle (C3) and the
  // result appears exactly three clocks later (S1).
  // ---------------------------------------------------------------------------
  logic v1_q, v2_q, v3_q;
  logic en;

  assign en        = out_ready | ~v3_q;
  assign in_ready  = en;
  assign out_valid = v3_q;

  // ===========================================================================
  // STAGE A -- classify, pre-normalise, multiply, align
  // ===========================================================================
  logic        sa, sb, scc, sp_a;
  logic [7:0]  ea, eb, ec;
  logic [22:0] ma, mb, mc;
  logic        a_nan, b_nan, c_nan, a_snan, b_snan, c_snan;
  logic        a_inf, b_inf, c_inf, a_zr, b_zr, c_zr;
  logic [23:0] siga_r, sigb_r, sigc_r;
  logic [4:0]  lz_a, lz_b, lz_c;
  logic [23:0] siga, sigb, sigc;

  logic signed [11:0] exp_a, exp_b, exp_c, exp_p;
  logic signed [11:0] diff_a, anchor_a;
  logic        [47:0] prod_a;
  logic        [52:0] shin_a, prod_f_a, add_f_a;
  logic        [53:0] shout_a;
  logic signed [11:0] shmag_a;
  logic        [5:0]  shamt_a;
  logic               lost_a, eps_sign_a;
  logic               spec_v_a, spec_nan_a, spec_sign_a, spec_nv_a;

  always_comb begin
    sa  = a[31]; ea = a[30:23]; ma = a[22:0];
    sb  = b[31]; eb = b[30:23]; mb = b[22:0];
    scc = c[31]; ec = c[30:23]; mc = c[22:0];
    sp_a = sa ^ sb;

    a_nan  = (ea == 8'hFF) && (ma != 23'd0);
    b_nan  = (eb == 8'hFF) && (mb != 23'd0);
    c_nan  = (ec == 8'hFF) && (mc != 23'd0);
    a_snan = a_nan && !ma[22];
    b_snan = b_nan && !mb[22];
    c_snan = c_nan && !mc[22];
    a_inf  = (ea == 8'hFF) && (ma == 23'd0);
    b_inf  = (eb == 8'hFF) && (mb == 23'd0);
    c_inf  = (ec == 8'hFF) && (mc == 23'd0);
    a_zr   = (ea == 8'd0)  && (ma == 23'd0);
    b_zr   = (eb == 8'd0)  && (mb == 23'd0);
    c_zr   = (ec == 8'd0)  && (mc == 23'd0);

    // Pre-normalise: every nonzero significand ends up with bit 23 set, which
    // is what makes the 53-bit alignment field sufficient (see header).
    siga_r = {(ea != 8'd0), ma};
    sigb_r = {(eb != 8'd0), mb};
    sigc_r = {(ec != 8'd0), mc};
    lz_a   = clz24(siga_r);
    lz_b   = clz24(sigb_r);
    lz_c   = clz24(sigc_r);
    siga   = (ea != 8'd0) ? siga_r : (siga_r << lz_a);
    sigb   = (eb != 8'd0) ? sigb_r : (sigb_r << lz_b);
    sigc   = (ec != 8'd0) ? sigc_r : (sigc_r << lz_c);
    exp_a  = (ea != 8'd0) ? ($signed({4'b0, ea}) - 12'sd150)
                          : (-12'sd149 - $signed({7'b0, lz_a}));
    exp_b  = (eb != 8'd0) ? ($signed({4'b0, eb}) - 12'sd150)
                          : (-12'sd149 - $signed({7'b0, lz_b}));
    exp_c  = (ec != 8'd0) ? ($signed({4'b0, ec}) - 12'sd150)
                          : (-12'sd149 - $signed({7'b0, lz_c}));

    prod_a = siga * sigb;                 // exact, never rounded (A1)
    exp_p  = exp_a + exp_b;

    // Which term is anchored.  A zero product forces the addend-anchored case
    // and a zero addend the product-anchored one, so a meaningless exponent
    // from a zero operand can never select the anchor.
    if (a_zr || b_zr)      diff_a = 12'sd200;
    else if (c_zr)         diff_a = -12'sd200;
    else                   diff_a = exp_c - exp_p - 12'sd26;

    anchor_a = (diff_a > 12'sd0) ? (exp_c - 12'sd29) : (exp_p - 12'sd3);

    // One shifter: the smaller term is shifted, its lost bits become sticky.
    if (diff_a > 12'sd0) begin
      shin_a  = {2'b0, prod_a, 3'b0};
      shmag_a = diff_a;
      shamt_a = (shmag_a > 12'sd51) ? 6'd51 : shmag_a[5:0];
    end else begin
      shin_a  = {sigc, 29'b0};
      shmag_a = -diff_a;
      shamt_a = (shmag_a > 12'sd53) ? 6'd53 : shmag_a[5:0];
    end

    shout_a = shr53_sticky(shin_a, shamt_a);
    lost_a  = shout_a[53];

    if (diff_a > 12'sd0) begin
      prod_f_a   = shout_a[52:0];
      add_f_a    = {sigc, 29'b0};
      eps_sign_a = sp_a;                  // the product supplied the lost bits
    end else begin
      prod_f_a   = {2'b0, prod_a, 3'b0};
      add_f_a    = shout_a[52:0];
      eps_sign_a = scc;                   // the addend supplied them
    end

    // Special values.  inf*0 is tested FIRST so it raises invalid even when an
    // operand is a NaN, and every NaN result is the canonical quiet NaN (A4).
    spec_v_a    = 1'b0;
    spec_nan_a  = 1'b0;
    spec_sign_a = 1'b0;
    spec_nv_a   = 1'b0;
    if ((a_inf && b_zr) || (a_zr && b_inf)) begin
      spec_v_a   = 1'b1;
      spec_nan_a = 1'b1;
      spec_nv_a  = 1'b1;
    end else if (a_nan || b_nan || c_nan) begin
      spec_v_a   = 1'b1;
      spec_nan_a = 1'b1;
      spec_nv_a  = a_snan | b_snan | c_snan;   // a quiet NaN alone does not
    end else if (a_inf || b_inf || c_inf) begin
      spec_v_a = 1'b1;
      if ((a_inf || b_inf) && c_inf && (scc != sp_a)) begin
        spec_nan_a = 1'b1;                     // inf - inf
        spec_nv_a  = 1'b1;
      end else if (a_inf || b_inf) begin
        spec_sign_a = sp_a;
      end else begin
        spec_sign_a = scc;
      end
    end
  end

  // ---- register boundary 1 ----
  logic [52:0]        prod_f_q, add_f_q;
  logic               sp_q, sc_q, eps_sign_q, lost_q;
  logic signed [11:0] anchor_q1;
  logic [2:0]         rnd_q1;
  logic               spec_v_q1, spec_nan_q1, spec_sign_q1, spec_nv_q1;

  // ===========================================================================
  // STAGE B -- add, magnitude, sticky borrow, leading-one search
  // ===========================================================================
  logic signed [54:0] sum_b;
  logic        [53:0] magp_b, mag_b;
  logic               rsign_b, sub1_b, zero_b, zsign_b, rsign_fin_b;
  logic        [5:0]  msb_b;

  always_comb begin
    sum_b = (sp_q ? -$signed({2'b0, prod_f_q}) : $signed({2'b0, prod_f_q}))
          + (sc_q ? -$signed({2'b0, add_f_q})  : $signed({2'b0, add_f_q}));

    rsign_b = sum_b[54];
    magp_b  = rsign_b ? (54'd0 - sum_b[53:0]) : sum_b[53:0];

    // The bits shifted out during alignment are a fraction of one field LSB
    // carrying the shifted term's sign.  When that sign opposes the result's,
    // the true magnitude is one ulp lower with a nonzero remainder, so the
    // field is decremented and the sticky is set.  Without this, a huge product
    // minus a far-below addend rounds as if the addend were absent.
    sub1_b = lost_q & (rsign_b ^ eps_sign_q);
    mag_b  = magp_b - {53'b0, sub1_b};

    // An exact zero can only arise with nothing lost below the field.
    zero_b      = (sum_b == 55'sd0) && !lost_q;
    zsign_b     = (sp_q == sc_q) ? sp_q : (rnd_q1 == RDN);
    rsign_fin_b = zero_b ? zsign_b : rsign_b;

    msb_b = msb54(mag_b);
  end

  // ---- register boundary 2 ----
  logic [53:0]        mag_q;
  logic [5:0]         msb_q;
  logic signed [11:0] anchor_q2;
  logic               rsign_q, sticky_q, zero_q;
  logic [2:0]         rnd_q2;
  logic               spec_v_q2, spec_nan_q2, spec_sign_q2, spec_nv_q2;

  // ===========================================================================
  // STAGE C -- place the rounding window, round once, assemble, flags
  // ===========================================================================
  logic signed [11:0] sub_lim_c, sh_sig_c, exp_pre_c, exp_f_c;
  logic        [6:0]  sh_c;
  logic               normal_c;
  logic        [77:0] em_c;
  logic        [78:0] so_c;
  logic        [24:0] r25_c, mr_c;
  logic        [23:0] mant_c;
  logic               g_c, sticky_c, inexact_c, inc_c, ovf_c, to_inf_c;
  logic        [31:0] res_c;
  logic        [3:0]  flg_c;

  always_comb begin
    // A normal result puts its LSB 23 below the leading one; a subnormal one
    // puts it at 2^-149 instead, which is the larger shift.  Taking the max
    // covers both, so there is no separate subnormal path.
    sub_lim_c = -12'sd126 - anchor_q2;
    normal_c  = ($signed({6'b0, msb_q}) >= sub_lim_c);
    sh_sig_c  = normal_c ? $signed({6'b0, msb_q}) : sub_lim_c;
    sh_c      = (sh_sig_c > 12'sd78) ? 7'd78
              : (sh_sig_c < 12'sd0)  ? 7'd0
                                     : sh_sig_c[6:0];

    em_c     = {mag_q, 24'b0};
    so_c     = shr78_sticky(em_c, sh_c);
    sticky_c = so_c[78] | sticky_q;
    r25_c    = so_c[24:0];
    mant_c   = r25_c[24:1];
    g_c      = r25_c[0];

    exp_pre_c = normal_c ? (anchor_q2 + $signed({6'b0, msb_q}) + 12'sd127) : 12'sd0;
    inexact_c = g_c | sticky_c;

    case (rnd_q2)
      RTZ:     inc_c = 1'b0;
      RDN:     inc_c = rsign_q     & (g_c | sticky_c);
      RUP:     inc_c = (~rsign_q)  & (g_c | sticky_c);
      RMM:     inc_c = g_c;
      default: inc_c = g_c & (sticky_c | mant_c[0]);   // RNE
    endcase

    mr_c = {1'b0, mant_c} + {24'b0, inc_c};

    // A carry out of the significand bumps the exponent; in the subnormal case
    // the same carry is what promotes the result to the smallest normal, which
    // is exactly the A6 band that must NOT report underflow.
    exp_f_c = normal_c ? (exp_pre_c + {11'b0, mr_c[24]}) : {11'b0, mr_c[23]};
    ovf_c   = normal_c && (exp_f_c >= 12'sd255);

    to_inf_c = (rnd_q2 == RNE) || (rnd_q2 == RMM)
            || ((rnd_q2 == RUP) && !rsign_q) || ((rnd_q2 == RDN) && rsign_q);

    if (spec_v_q2) begin
      res_c = spec_nan_q2 ? CANON_QNAN : {spec_sign_q2, 8'hFF, 23'h0};
      flg_c = {spec_nv_q2, 1'b0, 1'b0, 1'b0};
    end else if (zero_q) begin
      res_c = {rsign_q, 31'b0};
      flg_c = 4'b0000;
    end else if (ovf_c) begin
      res_c = to_inf_c ? {rsign_q, 8'hFF, 23'h0} : {rsign_q, 8'hFE, 23'h7FFFFF};
      flg_c = 4'b0101;                                    // overflow implies inexact
    end else begin
      res_c = {rsign_q, exp_f_c[7:0], mr_c[22:0]};
      // A6: underflow is read off the DELIVERED exponent field.
      flg_c = {1'b0, 1'b0, inexact_c & (exp_f_c[7:0] == 8'd0), inexact_c};
    end
  end

  // ===========================================================================
  // registers -- rst_n is active low and SYNCHRONOUS (R1); reset discards
  // everything in flight and holds out_valid low (R2, R3).
  // ===========================================================================
  always_ff @(posedge clk) begin
    if (!rst_n) begin
      v1_q           <= 1'b0;
      v2_q           <= 1'b0;
      v3_q           <= 1'b0;
      result         <= 32'd0;
      flag_invalid   <= 1'b0;
      flag_overflow  <= 1'b0;
      flag_underflow <= 1'b0;
      flag_inexact   <= 1'b0;
    end else if (en) begin
      v1_q <= in_valid;
      v2_q <= v1_q;
      v3_q <= v2_q;

      prod_f_q     <= prod_f_a;
      add_f_q      <= add_f_a;
      sp_q         <= sp_a;
      sc_q         <= scc;
      eps_sign_q   <= eps_sign_a;
      lost_q       <= lost_a;
      anchor_q1    <= anchor_a;
      rnd_q1       <= rnd_mode;
      spec_v_q1    <= spec_v_a;
      spec_nan_q1  <= spec_nan_a;
      spec_sign_q1 <= spec_sign_a;
      spec_nv_q1   <= spec_nv_a;

      mag_q        <= mag_b;
      msb_q        <= msb_b;
      anchor_q2    <= anchor_q1;
      rsign_q      <= rsign_fin_b;
      sticky_q     <= lost_q;
      zero_q       <= zero_b;
      rnd_q2       <= rnd_q1;
      spec_v_q2    <= spec_v_q1;
      spec_nan_q2  <= spec_nan_q1;
      spec_sign_q2 <= spec_sign_q1;
      spec_nv_q2   <= spec_nv_q1;

      result         <= res_c;
      flag_invalid   <= flg_c[3];
      flag_overflow  <= flg_c[2];
      flag_underflow <= flg_c[1];
      flag_inexact   <= flg_c[0];
    end
  end

endmodule