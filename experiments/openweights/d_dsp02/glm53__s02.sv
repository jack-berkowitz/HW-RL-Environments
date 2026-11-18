// =============================================================================
// fp32_fma_ii1 -- IEEE-754 binary32 FUSED multiply-add (a*b)+c, II=1, latency 3
//
// Structure (3 register boundaries):
//   S1: decode / classify / 24x24 multiply / special-case resolve
//   S2: align both operands in a 96-bit fixed-point window (A9), add, sticky
//   S3: leading-zero count, normalise, single rounding, flags
//
// The exact product-sum is represented in a 96-bit window whose bit b has
// weight 2^(Eref-92+b), where Eref = max(product exponent, addend exponent).
// The product sits at bits [93:46], the addend enters at bit 69-d (d = ep-ec).
// Bits shifted below the window collapse into a sticky bit.  A zero addend is
// forced to d=0 so it can never set the window scale.  The one boundary case
// where a truncated (sticky-only) operand sits *below* an exact window tie is
// corrected: for the nearest modes the tie then rounds down (the true value is
// below the tie), which naive sticky logic would get wrong.
//
// Underflow follows A6 longhand: UF = inexact AND delivered exponent field 0.
// Every NaN result is the canonical 32'h7FC00000.
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
    input  logic [2:0]  rnd_mode,   // 0 RNE, 1 RTZ, 2 RDN, 3 RUP, 4 RMM

    output logic        out_valid,
    input  logic        out_ready,
    output logic [31:0] result,
    output logic        flag_invalid,
    output logic        flag_overflow,
    output logic        flag_underflow,
    output logic        flag_inexact
);

  // ===========================================================================
  // Stage 1 : decode / classify / multiply
  // ===========================================================================
  logic [7:0]  ea, eb, ec;
  logic [22:0] fa, fb, fc;
  logic        sa, sb, sc;
  logic        a_nan, b_nan, c_nan;
  logic        a_snan, b_snan, c_snan;
  logic        a_inf, b_inf, c_inf;
  logic        a_zero, b_zero, c_zero;
  logic [23:0] a_int, b_int, c_int;
  logic signed [9:0] ea_u, eb_u, ec_u;
  logic signed [9:0] ep, exp_diff, eref, psh, csh;
  logic [47:0] prod;
  logic        sp, prod_inf, prod_zero, any_nan, inv_s1, is_spec;
  logic [31:0] spec_res;

  assign ea = a[30:23];
  assign eb = b[30:23];
  assign ec = c[30:23];
  assign fa = a[22:0];
  assign fb = b[22:0];
  assign fc = c[22:0];
  assign sa = a[31];
  assign sb = b[31];
  assign sc = c[31];

  assign a_nan  = (ea == 8'd255) && (fa != 22'd0);
  assign b_nan  = (eb == 8'd255) && (fb != 22'd0);
  assign c_nan  = (ec == 8'd255) && (fc != 22'd0);
  assign a_snan = a_nan && !a[22];
  assign b_snan = b_nan && !b[22];
  assign c_snan = c_nan && !c[22];
  assign a_inf  = (ea == 8'd255) && (fa == 22'd0);
  assign b_inf  = (eb == 8'd255) && (fb == 22'd0);
  assign c_inf  = (ec == 8'd255) && (fc == 22'd0);
  assign a_zero = (ea == 8'd0)   && (fa == 22'd0);
  assign b_zero = (eb == 8'd0)   && (fb == 22'd0);
  assign c_zero = (ec == 8'd0)   && (fc == 22'd0);

  // significand as 24-bit integer, value = int * 2^(E-23)
  assign a_int = (ea == 8'd0) ? {1'b0, fa} : {1'b1, fa};
  assign b_int = (eb == 8'd0) ? {1'b0, fb} : {1'b1, fb};
  assign c_int = (ec == 8'd0) ? {1'b0, fc} : {1'b1, fc};

  assign ea_u = (ea == 8'd0) ? -10'sd126 : ($signed({2'b00, ea}) - 10'sd127);
  assign eb_u = (eb == 8'd0) ? -10'sd126 : ($signed({2'b00, eb}) - 10'sd127);
  assign ec_u = (ec == 8'd0) ? -10'sd126 : ($signed({2'b00, ec}) - 10'sd127);

  assign prod = a_int * b_int;               // exact 48-bit product
  assign ep   = ea_u + eb_u;

  // a zero addend must not set the alignment scale: force d = 0
  assign exp_diff = c_zero ? 10'sd0 : (ep - ec_u);

  assign eref = exp_diff[9] ? ec_u : ep;     // window reference exponent
  assign psh  = 10'sd46 + (exp_diff[9] ? exp_diff : 10'sd0);
  assign csh  = 10'sd69 - (((!exp_diff[9]) && (exp_diff != 10'sd0)) ? exp_diff : 10'sd0);

  assign sp        = sa ^ sb;
  assign prod_inf  = (a_inf || b_inf) && !(a_zero || b_zero);
  assign prod_zero = a_zero || b_zero;
  assign any_nan   = a_nan || b_nan || c_nan;
  assign inv_s1    = a_snan || b_snan || c_snan
                   || (a_inf && b_zero) || (a_zero && b_inf)
                   || (prod_inf && c_inf && (sp != sc));
  assign is_spec   = any_nan || inv_s1 || prod_inf || c_inf || prod_zero;

  always_comb begin
    if (any_nan || inv_s1) begin
      spec_res = 32'h7FC00000;               // canonical quiet NaN (A4)
    end else if (prod_inf) begin
      spec_res = {sp, 8'hFF, 23'd0};
    end else if (c_inf) begin
      spec_res = {sc, 8'hFF, 23'd0};
    end else if (c_zero) begin
      // (+-0)*b + (+-0) : sign per IEEE (A5), -0 only in RDN
      spec_res = {((sp == sc) ? sp : (rnd_mode == 3'd2)), 31'd0};
    end else begin
      spec_res = c;                          // 0*b + c = c, exact
    end
  end

  // ===========================================================================
  // Pipeline registers
  // ===========================================================================
  logic               v1, v2, v3;
  logic [47:0]        r1_prod;
  logic [23:0]        r1_cint;
  logic               r1_sp, r1_sc;
  logic signed [9:0]  r1_eref, r1_psh, r1_csh;
  logic               r1_spec, r1_inv;
  logic [31:0]        r1_specres;
  logic [2:0]         r1_rnd;

  logic [95:0]        r2_m;
  logic               r2_s, r2_st, r2_sub, r2_spec, r2_inv, r2_sp, r2_sc;
  logic signed [9:0]  r2_eref;
  logic [31:0]        r2_specres;
  logic [2:0]         r2_rnd;

  logic [31:0]        r3_res;
  logic               r3_inv, r3_ovf, r3_uf, r3_nx;

  // ===========================================================================
  // Stage 2 : align / add  (96-bit window, bit b has weight 2^(eref-92+b))
  // ===========================================================================
  logic [95:0] pterm, cterm, m2;
  logic        pst2, cst2, st2, s2, sub2;
  logic [9:0]  pamt, camt;

  always_comb begin
    pterm = 96'd0;
    cterm = 96'd0;
    pst2  = 1'b0;
    cst2  = 1'b0;
    pamt  = 10'd0;
    camt  = 10'd0;
    if (r1_psh[9]) begin
      pamt = -r1_psh;
      if (pamt >= 10'd48) begin
        pterm = 96'd0;
        pst2  = (r1_prod != 48'd0);
      end else begin
        pterm = {48'd0, r1_prod} >> pamt;
        pst2  = |(r1_prod & ((48'd1 << pamt) - 48'd1));
      end
    end else begin
      pterm = {48'd0, r1_prod} << r1_psh[5:0];
    end
    if (r1_csh[9]) begin
      camt = -r1_csh;
      if (camt >= 10'd24) begin
        cterm = 96'd0;
        cst2  = (r1_cint != 24'd0);
      end else begin
        cterm = {72'd0, r1_cint} >> camt;
        cst2  = |(r1_cint & ((24'd1 << camt) - 24'd1));
      end
    end else begin
      cterm = {72'd0, r1_cint} << r1_csh[6:0];
    end
    st2 = pst2 | cst2;
    if (r1_sp == r1_sc) begin
      m2 = pterm + cterm;
      s2 = r1_sp;
    end else if (pterm >= cterm) begin
      m2 = pterm - cterm;
      s2 = r1_sp;
    end else begin
      m2 = cterm - pterm;
      s2 = r1_sc;
    end
    // truncated operand's lost bits subtract from the magnitude when its sign
    // opposes the result sign (used only to fix the exact-tie case)
    sub2 = st2 && ((r1_csh[9]) ? (r1_sc != s2) : (r1_sp != s2));
  end

  // ===========================================================================
  // Stage 3 : normalise / round / flags
  // ===========================================================================
  logic [31:0] res3;
  logic        inv3, ovf3, uf3, nx3;
  logic        is_norm;
  int          li;
  logic [6:0]  lzc, msb;
  logic signed [9:0] er, er2, sh;
  logic [9:0]  samt;
  logic [95:0] sh2, sh3;
  logic [23:0] sig24, fval, ffinal;
  logic [24:0] sigf;
  logic [9:0]  field;
  logic        g, wlow, rem_nz, inc, carry1, rnd_lsb;

  always_comb begin
    res3   = 32'd0;
    inv3   = 1'b0;
    ovf3   = 1'b0;
    uf3    = 1'b0;
    nx3    = 1'b0;
    is_norm = 1'b0;
    lzc    = 7'd96;
    msb    = 7'd0;
    er     = 10'sd0;
    er2    = 10'sd0;
    sh     = 10'sd0;
    samt   = 10'd0;
    sh2    = 96'd0;
    sh3    = 96'd0;
    sig24  = 24'd0;
    fval   = 24'd0;
    ffinal = 24'd0;
    sigf   = 25'd0;
    field  = 10'd0;
    g      = 1'b0;
    wlow   = 1'b0;
    rem_nz = 1'b0;
    inc    = 1'b0;
    carry1 = 1'b0;
    rnd_lsb = 1'b0;

    if (r2_spec) begin
      res3 = r2_specres;
      inv3 = r2_inv;
    end else begin
      lzc = 7'd96;
      for (li = 0; li < 96; li = li + 1) begin
        if (r2_m[li]) begin
          lzc = 7'd95 - li[6:0];
        end
      end
      if (lzc == 7'd96) begin
        // exact zero (M==0 implies no truncation): sign per IEEE
        res3 = {((r2_sp == r2_sc) ? r2_sp : (r2_rnd == 3'd2)), 31'd0};
      end else begin
        msb = 7'd95 - lzc;
        er  = r2_eref - 10'sd92 + $signed({3'b000, msb});
        is_norm = (er >= -10'sd126);
        if (is_norm) begin
          // ---------------- normal result: 24-bit significand -------------
          if (msb >= 7'd24) begin
            sh2   = r2_m >> (msb - 7'd24);
            sig24 = sh2[24:1];
            g     = sh2[0];
            wlow  = |(r2_m & ((96'd1 << (msb - 7'd24)) - 96'd1));
          end else if (msb == 7'd23) begin
            sig24 = r2_m[23:0];               // exact, nothing below
          end else begin
            sig24 = r2_m << (7'd23 - msb);    // exact, needs left shift
          end
          rnd_lsb = sig24[0];
        end else begin
          // ------------- subnormal / tiny result: grid 2^-149 --------------
          sh = r2_eref + 10'sd57;
          if (!sh[9]) begin
            sh3  = r2_m << sh[5:0];           // exact (unreachable in practice)
            fval = sh3[23:0];
          end else begin
            samt = -sh;
            if (samt >= 10'd97) begin
              fval = 24'd0;                   // everything below the grid
              wlow = |r2_m;
            end else begin
              sh3  = r2_m >> samt;
              fval = sh3[23:0];
              g    = r2_m[samt - 10'd1];
              wlow = |(r2_m & ((96'd1 << (samt - 10'd1)) - 96'd1));
            end
          end
          rnd_lsb = fval[0];
        end

        // ------------------- single rounding of the exact sum ------------
        rem_nz = g | wlow | r2_st;
        case (r2_rnd)
          3'd0: inc = g & (wlow | (r2_st ? ~r2_sub : rnd_lsb));      // RNE
          3'd1: inc = 1'b0;                                          // RTZ
          3'd2: inc = r2_s ? rem_nz : 1'b0;                          // RDN
          3'd3: inc = r2_s ? 1'b0 : rem_nz;                          // RUP
          default: inc = g & (wlow | (r2_st ? ~r2_sub : 1'b1));      // RMM
        endcase

        if (is_norm) begin
          sigf   = {1'b0, sig24} + {24'd0, inc};
          carry1 = sigf[24];
          er2    = er + (carry1 ? 10'sd1 : 10'sd0);
          field  = er2 + 10'sd127;
          nx3    = g | wlow | r2_st;
          if (field >= 10'd255) begin
            ovf3 = 1'b1;
            nx3  = 1'b1;                     // overflow always inexact (A4b)
            if ((r2_rnd == 3'd0) || (r2_rnd == 3'd4) ||
                ((r2_rnd == 3'd3) && !r2_s) ||
                ((r2_rnd == 3'd2) &&  r2_s)) begin
              res3 = {r2_s, 8'hFF, 23'd0};
            end else begin
              res3 = {r2_s, 8'hFE, 23'h7FFFFF};
            end
          end else begin
            res3 = {r2_s, field[7:0], sigf[22:0]};
          end
        end else begin
          ffinal = fval + {23'd0, inc};
          nx3    = g | wlow | r2_st;
          if (ffinal[23]) begin
            res3 = {r2_s, 8'd1, 23'd0};      // carried to smallest normal
          end else begin
            res3 = {r2_s, 8'd0, ffinal[22:0]};
            uf3  = nx3;                      // A6: inexact AND field == 0
          end
        end
      end
    end
  end

  // ===========================================================================
  // Handshake / pipeline control  (II=1; in_ready never sees in_valid)
  // ===========================================================================
  logic r3_accept, r2_accept, r1_accept;

  assign r3_accept = (!v3) || out_ready;
  assign r2_accept = (!v2) || r3_accept;
  assign r1_accept = (!v1) || r2_accept;
  assign in_ready  = r1_accept;

  assign out_valid      = v3;
  assign result         = r3_res;
  assign flag_invalid   = r3_inv;
  assign flag_overflow  = r3_ovf;
  assign flag_underflow = r3_uf;
  assign flag_inexact   = r3_nx;

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      v1 <= 1'b0;
      v2 <= 1'b0;
      v3 <= 1'b0;
    end else begin
      if (r1_accept) begin
        v1         <= in_valid;
        r1_prod    <= prod;
        r1_cint    <= c_int;
        r1_sp      <= sp;
        r1_sc      <= sc;
        r1_eref    <= eref;
        r1_psh     <= psh;
        r1_csh     <= csh;
        r1_spec    <= is_spec;
        r1_inv     <= inv_s1;
        r1_specres <= spec_res;
        r1_rnd     <= rnd_mode;
      end
      if (r2_accept) begin
        v2         <= v1;
        r2_m       <= m2;
        r2_s       <= s2;
        r2_st      <= st2;
        r2_sub     <= sub2;
        r2_eref    <= r1_eref;
        r2_spec    <= r1_spec;
        r2_inv     <= r1_inv;
        r2_specres <= r1_specres;
        r2_rnd     <= r1_rnd;
        r2_sp      <= r1_sp;
        r2_sc      <= r1_sc;
      end
      if (r3_accept) begin
        v3     <= v2;
        r3_res <= res3;
        r3_inv <= inv3;
        r3_ovf <= ovf3;
        r3_uf  <= uf3;
        r3_nx  <= nx3;
      end
    end
  end

endmodule
