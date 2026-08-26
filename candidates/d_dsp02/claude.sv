// =============================================================================
// fp32_fma_ii1.sv -- IEEE-754 binary32 fused multiply-add, II = 1, latency 3
// -----------------------------------------------------------------------------
// STRUCTURE. Three register boundaries (S1), one operation accepted per cycle
// (C3). The whole pipeline advances or freezes together, so `in_ready` depends
// on `out_ready` but never on `in_valid` (H1), and a held result stays stable
// (H3). Results are in order by construction (H4).
//
//   stage 1 comb : classify, 24x24 multiply, align the addend, add/subtract
//   stage 2 comb : leading-zero count, normalise, extract significand + G/R/S
//   stage 3 comb : round, assemble, derive flags
//
// THE ALIGNMENT, which is what makes the rounding single (A1).
// A 77-bit window holds the exact product-sum to the precision that can affect
// one rounding. Window bit k has weight 2^(anchor-75+k):
//
//   * the addend's 24-bit significand is placed with its MSB at window bit 75
//     and shifted RIGHT by `shamt`; bits pushed below bit 0 are collapsed into
//     a sticky bit,
//   * the 48-bit product is placed, shifted left by 2, at bits [49:0].
//
// `shamt = 27 - d` where d is the addend-minus-product exponent difference, so
// the two operands land in their true relative positions. Outside the range
// -49 <= d <= 26 the shift saturates:
//
//   d >= 27  the addend dominates; the product lands wholly at or below the
//            sticky region, so its exact placement cannot change the rounded
//            result -- only whether it is non-zero -- and the anchor becomes
//            the addend's exponent;
//   d <= -49 the addend is below the window entirely and is pure sticky.
//
// This is what bounds the datapath at 76/77 bits rather than the ~400 an
// unbounded intermediate would need (A9's ceiling is 96).
//
// SUBNORMALS (A3) fall out of this without a separate path: operands keep their
// biased-exponent-1 interpretation rather than being pre-normalised, which
// keeps the anchor high enough that a subnormal result is reached by a
// left shift of `anchor + 127` instead of a right shift.
//
// ROUNDING uses the contiguous {exponent, mantissa} encoding, so a mantissa
// carry-out and the subnormal-to-normal transition are both just `+1`.
// =============================================================================

`timescale 1ns/1ps

/* verilator lint_off DECLFILENAME */
/* verilator lint_off UNUSED */

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

  localparam logic [2:0] RNE = 3'd0;
  localparam logic [2:0] RTZ = 3'd1;
  localparam logic [2:0] RDN = 3'd2;
  localparam logic [2:0] RUP = 3'd3;
  localparam logic [2:0] RMM = 3'd4;

  // ---------------------------------------------------------------------------
  // Pipeline control. One enable for the whole pipe: it either advances or it
  // freezes, which keeps results in order and held results stable.
  // ---------------------------------------------------------------------------
  logic en;
  logic v1_q, v2_q, v3_q;

  assign en       = ~(v3_q & ~out_ready);
  assign in_ready = en;                 // H1: no dependence on in_valid
  assign out_valid = v3_q;

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      v1_q <= 1'b0; v2_q <= 1'b0; v3_q <= 1'b0;   // R2/R3
    end else if (en) begin
      v1_q <= in_valid;
      v2_q <= v1_q;
      v3_q <= v2_q;
    end
  end

  // ===========================================================================
  // STAGE 1 -- classify, multiply, align, add
  // ===========================================================================
  logic        sa, sb, sc_s;
  logic [7:0]  ea_f, eb_f, ec_f;
  logic [22:0] ma_f, mb_f, mc_f;

  assign sa   = a[31];  assign ea_f = a[30:23];  assign ma_f = a[22:0];
  assign sb   = b[31];  assign eb_f = b[30:23];  assign mb_f = b[22:0];
  assign sc_s = c[31];  assign ec_f = c[30:23];  assign mc_f = c[22:0];

  logic a_zero, b_zero, c_zero, a_inf, b_inf, c_inf;
  logic a_nan, b_nan, c_nan, a_snan, b_snan, c_snan;

  assign a_zero = (ea_f == 8'd0)   && (ma_f == 23'd0);
  assign b_zero = (eb_f == 8'd0)   && (mb_f == 23'd0);
  assign c_zero = (ec_f == 8'd0)   && (mc_f == 23'd0);
  assign a_inf  = (ea_f == 8'hFF)  && (ma_f == 23'd0);
  assign b_inf  = (eb_f == 8'hFF)  && (mb_f == 23'd0);
  assign c_inf  = (ec_f == 8'hFF)  && (mc_f == 23'd0);
  assign a_nan  = (ea_f == 8'hFF)  && (ma_f != 23'd0);
  assign b_nan  = (eb_f == 8'hFF)  && (mb_f != 23'd0);
  assign c_nan  = (ec_f == 8'hFF)  && (mc_f != 23'd0);
  assign a_snan = a_nan && ~ma_f[22];
  assign b_snan = b_nan && ~mb_f[22];
  assign c_snan = c_nan && ~mc_f[22];

  // significands with the implicit bit; a subnormal keeps exponent field 1
  logic [23:0] sig_a, sig_b, sig_c;
  assign sig_a = {(ea_f != 8'd0), ma_f};
  assign sig_b = {(eb_f != 8'd0), mb_f};
  assign sig_c = {(ec_f != 8'd0), mc_f};

  logic signed [12:0] eff_ea, eff_eb, eff_ec;
  assign eff_ea = (ea_f == 8'd0) ? 13'sd1 : $signed({5'd0, ea_f});
  assign eff_eb = (eb_f == 8'd0) ? 13'sd1 : $signed({5'd0, eb_f});
  assign eff_ec = (ec_f == 8'd0) ? 13'sd1 : $signed({5'd0, ec_f});

  logic sign_p;
  assign sign_p = sa ^ sb;

  // Exponent of the product's leading position, and of the addend.
  // A zero product is forced far below the addend so the addend anchors and the
  // (zero) product contributes nothing.
  logic signed [12:0] exp_prod, exp_add, expdiff, anchor_c;
  assign exp_prod = (a_zero || b_zero) ? -13'sd300 : (eff_ea + eff_eb - 13'sd254);
  assign exp_add  = eff_ec - 13'sd127;
  assign expdiff  = exp_add - exp_prod;
  assign anchor_c = (expdiff >= 13'sd27) ? exp_add : (exp_prod + 13'sd27);

  logic [6:0] shamt;
  always_comb begin
    if (expdiff >= 13'sd27)       shamt = 7'd0;
    else if (expdiff <= -13'sd49) shamt = 7'd76;
    else                          shamt = 7'(13'sd27 - expdiff);
  end

  // addend placed with its MSB at window bit 75, then shifted right
  logic [75:0] addend_max, addend_sh;
  assign addend_max = {sig_c, 52'd0};
  assign addend_sh  = addend_max >> shamt;

  // bits pushed below window bit 0 become sticky
  logic [4:0]  n_out;
  logic [24:0] mask_full;
  logic        sticky_c;
  assign n_out     = (shamt > 7'd52) ? 5'(shamt - 7'd52) : 5'd0;
  assign mask_full = (25'd1 << n_out) - 25'd1;
  assign sticky_c  = |(sig_c & mask_full[23:0]);

  // product, shifted left by two so it sits below the addend's LSB
  logic [47:0] prod;
  assign prod = sig_a * sig_b;

  logic [76:0] a_win, p_win;
  assign a_win = {1'b0, addend_sh};
  assign p_win = {27'd0, prod, 2'd0};

  logic eff_sub;
  assign eff_sub = sa ^ sb ^ sc_s;

  logic [77:0] sum_add, sum_sub;
  logic        sub_neg, sub_zero;
  assign sum_add  = {1'b0, a_win} + {1'b0, p_win};
  assign sum_sub  = {1'b0, p_win} - {1'b0, a_win};
  assign sub_neg  = sum_sub[77];
  assign sub_zero = (sum_sub == 78'd0);

  logic [76:0] mag_c;
  logic        sign_c_res;
  always_comb begin
    if (!eff_sub) begin
      mag_c = sum_add[76:0];
    end else if (sub_zero) begin
      // magnitudes cancel in the window; anything below it is the whole result
      mag_c = 77'd0;
    end else if (!sub_neg) begin
      // true addend is (window value + eps), so one extra unit comes off
      mag_c = sum_sub[76:0] - {76'd0, sticky_c};
    end else begin
      mag_c = (~sum_sub[76:0]) + 77'd1;
    end
  end
  // when the addend wins, or the entire result is the sub-window remainder,
  // the sign follows the addend
  assign sign_c_res = (eff_sub && (sub_neg || (sub_zero && sticky_c))) ? sc_s : sign_p;

  logic exact_zero_c, zero_sign_c;
  assign exact_zero_c = (mag_c == 77'd0) && !sticky_c;
  assign zero_sign_c  = ((a_zero || b_zero) && c_zero && (sign_p == sc_s))
                        ? sign_p : (rnd_mode == RDN);

  // ---- special values (A4, A5) ----
  logic mul_inv, prod_inf, addsub_inv, any_nan, spec_v, spec_nan_c, spec_sign_c, inv_c;
  assign mul_inv     = (a_inf && b_zero) || (b_inf && a_zero);
  assign prod_inf    = ((a_inf && !b_zero) || (b_inf && !a_zero)) && !a_nan && !b_nan;
  assign addsub_inv  = prod_inf && c_inf && (sign_p != sc_s);
  assign any_nan     = a_nan || b_nan || c_nan;
  assign spec_nan_c  = any_nan || mul_inv || addsub_inv;
  assign inv_c       = a_snan || b_snan || c_snan || mul_inv || addsub_inv;
  assign spec_v      = spec_nan_c || prod_inf || c_inf;
  assign spec_sign_c = prod_inf ? sign_p : sc_s;

  // ---- stage 1 registers ----
  logic [76:0]        mag_q;
  logic               sticky_q, sign_q, exact_zero_q, zero_sign_q;
  logic signed [12:0] anchor_q;
  logic               spec_v_q, spec_nan_q, spec_sign_q, inv_q;
  logic [2:0]         rnd_q1;

  always_ff @(posedge clk) begin
    if (en) begin
      mag_q        <= mag_c;
      sticky_q     <= sticky_c;
      sign_q       <= sign_c_res;
      exact_zero_q <= exact_zero_c;
      zero_sign_q  <= zero_sign_c;
      anchor_q     <= anchor_c;
      spec_v_q     <= spec_v;
      spec_nan_q   <= spec_nan_c;
      spec_sign_q  <= spec_sign_c;
      inv_q        <= inv_c;
      rnd_q1       <= rnd_mode;
    end
  end

  // ===========================================================================
  // STAGE 2 -- leading-zero count, normalise, extract significand and G/R/S
  // ===========================================================================
  logic [6:0] lead_idx;
  always_comb begin
    lead_idx = 7'd0;
    for (int i = 0; i < 77; i++) begin
      if (mag_q[i]) lead_idx = 7'(i);
    end
  end

  logic mag_zero;
  assign mag_zero = (mag_q == 77'd0);

  // biased exponent implied by the leading one
  logic signed [12:0] exp_full;
  assign exp_full = anchor_q + $signed({6'd0, lead_idx}) + 13'sd52;

  logic is_norm;
  assign is_norm = (exp_full >= 13'sd1) && !mag_zero;

  // normal: put the leading one at bit 76.  subnormal: fixed shift so that the
  // significand LSB lands on 2^-149.  both are proven to lie in [0, 76].
  logic [6:0] nshift;
  always_comb begin
    if (mag_zero)     nshift = 7'd0;
    else if (is_norm) nshift = 7'd76 - lead_idx;
    else              nshift = 7'(anchor_q + 13'sd127);
  end

  logic [76:0] shifted;
  assign shifted = mag_q << nshift;

  logic [23:0] sig24_c;
  logic        gbit_c, rbit_c, sbit_c;
  logic [8:0]  expp_c;

  assign sig24_c = shifted[76:53];
  assign gbit_c  = shifted[52];
  assign rbit_c  = shifted[51];
  assign sbit_c  = (|shifted[50:0]) | sticky_q;
  assign expp_c  = is_norm ? 9'(exp_full) : 9'd0;

  logic [23:0]  sig24_q;
  logic         g_q, r_q, s_q;
  logic [8:0]   expp_q;
  logic         sign_q2, exact_zero_q2, zero_sign_q2;
  logic         spec_v_q2, spec_nan_q2, spec_sign_q2, inv_q2;
  logic [2:0]   rnd_q2;

  always_ff @(posedge clk) begin
    if (en) begin
      sig24_q       <= sig24_c;
      g_q           <= gbit_c;
      r_q           <= rbit_c;
      s_q           <= sbit_c;
      expp_q        <= expp_c;
      sign_q2       <= sign_q;
      exact_zero_q2 <= exact_zero_q;
      zero_sign_q2  <= zero_sign_q;
      spec_v_q2     <= spec_v_q;
      spec_nan_q2   <= spec_nan_q;
      spec_sign_q2  <= spec_sign_q;
      inv_q2        <= inv_q;
      rnd_q2        <= rnd_q1;
    end
  end

  // ===========================================================================
  // STAGE 3 -- round, assemble, flags
  // ===========================================================================
  logic rb, st, ru, fsign;
  assign rb    = g_q;
  assign st    = r_q | s_q;
  assign fsign = exact_zero_q2 ? zero_sign_q2 : sign_q2;

  always_comb begin
    case (rnd_q2)
      RNE:     ru = rb & (st | sig24_q[0]);
      RTZ:     ru = 1'b0;
      RDN:     ru = fsign & (rb | st);
      RUP:     ru = ~fsign & (rb | st);
      RMM:     ru = rb;
      default: ru = 1'b0;
    endcase
  end

  // contiguous encoding: one increment covers both mantissa carry-out and the
  // subnormal-to-normal step
  logic [31:0] enc, enc_r;
  logic [8:0]  expf;
  assign enc   = {expp_q, sig24_q[22:0]};
  assign enc_r = enc + {31'd0, ru};
  assign expf  = enc_r[31:23];

  logic ovf_c, nx_c, uf_c;
  assign ovf_c = (expf >= 9'd255);
  assign nx_c  = rb | st | ovf_c;                    // A4b
  assign uf_c  = (expf == 9'd0) && (rb | st);        // A6

  logic [31:0] ovf_val, norm_val, fin_val;
  always_comb begin
    if ((rnd_q2 == RNE) || (rnd_q2 == RMM) ||
        ((rnd_q2 == RDN) && fsign) || ((rnd_q2 == RUP) && !fsign))
      ovf_val = {fsign, 8'hFF, 23'd0};
    else
      ovf_val = {fsign, 8'hFE, 23'h7FFFFF};
  end
  assign norm_val = {fsign, enc_r[30:23], enc_r[22:0]};

  always_comb begin
    if (spec_v_q2)   fin_val = spec_nan_q2 ? 32'h7FC00000 : {spec_sign_q2, 8'hFF, 23'd0};
    else if (ovf_c)  fin_val = ovf_val;
    else             fin_val = norm_val;
  end

  logic [31:0] res_q;
  logic        finv_q, fovf_q, fuf_q, fnx_q;

  always_ff @(posedge clk) begin
    if (en) begin
      res_q  <= fin_val;
      finv_q <= spec_v_q2 ? inv_q2 : 1'b0;
      fovf_q <= spec_v_q2 ? 1'b0   : ovf_c;
      fuf_q  <= spec_v_q2 ? 1'b0   : uf_c;
      fnx_q  <= spec_v_q2 ? 1'b0   : nx_c;
    end
  end

  assign result         = res_q;
  assign flag_invalid   = finv_q;
  assign flag_overflow  = fovf_q;
  assign flag_underflow = fuf_q;
  assign flag_inexact   = fnx_q;

endmodule

/* verilator lint_on UNUSED */
/* verilator lint_on DECLFILENAME */