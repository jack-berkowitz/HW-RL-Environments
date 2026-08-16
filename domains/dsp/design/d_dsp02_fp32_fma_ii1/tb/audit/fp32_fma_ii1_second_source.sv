// =============================================================================
// fp32_fma_ii1_second_source.sv -- SECOND SOURCE for d_dsp02. NEVER SHIPPED.
// =============================================================================
// A FALSIFIER, NOT AN ORACLE. Its job is to fail, and if it fails, rule 5's
// disambiguation decides what is wrong: run the failing vector through the
// ANCHOR first. If this file disagrees with the anchor, THIS FILE is wrong.
// Only if it agrees with the anchor and the checker still fails is the checker
// over-constrained. Writing a correct IEEE-754 FMA is not routine work, so the
// first branch is the expected one.
//
// THREE STRUCTURAL DIFFERENCES FROM THE ANCHOR, each an independent free choice
// and each the OPPOSITE of what cvfpu's fpnew_fma does:
//
//   1. ALIGNMENT IS BIDIRECTIONAL. The anchor frames on the PRODUCT and shifts
//      the ADDEND into it -- one shifter, one direction. This file frames on
//      max(product, addend) and shifts WHICHEVER IS SMALLER, so both operands
//      have a shift path and both have sticky collection.
//
//      An earlier version framed strictly on the addend and shifted the product.
//      That is NOT implementable at sane width: with a zero addend the effective
//      exponent is 1, so the product needs a ~485-bit accumulator to shift into.
//      It was corrected after the checker caught it at the overflow vectors, and
//      the difference is stated as what the file actually does. A bidirectional
//      aligner against a unidirectional one is still a real structural
//      difference -- different shifter count, different sticky logic, different
//      dominance conditions -- it is simply a smaller claim than the one that
//      did not work.
//
//   2. ROUNDING. The anchor decides first -- fpnew_rounding computes a
//      `round_up` bit from a case table over {round, sticky} and then
//      increments. This file computes BOTH candidates unconditionally, the
//      truncated and the incremented mantissa, and SELECTS between them.
//      Speculate-and-select rather than decide-and-increment.
//
//   3. NORMALIZATION. The anchor runs an `lzc` over the sum AFTER the add and
//      then applies a separate correction for subnormal results. This file does
//      a SINGLE barrel shift from one leading-one index over the full-width
//      accumulator, with the subnormal case folded into the same shift by
//      clamping the index rather than handled as a second stage.
//
// None of the three is a paraphrase: each changes what hardware exists, not just
// how it is written. Together they mean a bug in this file is very unlikely to
// coincide with a bug in the anchor -- which is the entire value of a second
// source.
//
// Correctness is not sacrificed for cleverness: a dual-path (far/close) FMA
// would be a more dramatic structural difference and was deliberately NOT
// chosen, because its failure mode is subtle cancellation behaviour and a buggy
// second source inverts the purpose of having one.
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

    localparam int ACC_W = 160;   // generous: exact product-sum plus guard room
    localparam int P_POS = 80;    // where the addend's LSB sits in the frame

    // ---- unpack -------------------------------------------------------------
    function automatic bit f_is_nan (input logic [31:0] x);
        return (x[30:23] == 8'hFF) && (x[22:0] != 0); endfunction
    function automatic bit f_is_snan(input logic [31:0] x);
        return f_is_nan(x) && !x[22]; endfunction
    function automatic bit f_is_inf (input logic [31:0] x);
        return (x[30:23] == 8'hFF) && (x[22:0] == 0); endfunction
    function automatic bit f_is_zero(input logic [31:0] x);
        return (x[30:0] == 0); endfunction
    function automatic bit f_is_sub (input logic [31:0] x);
        return (x[30:23] == 0) && (x[22:0] != 0); endfunction

    wire sa = a[31], sb = b[31], sc = c[31];
    wire [23:0] ma = {~f_is_sub(a) && (a[30:23] != 0), a[22:0]};
    wire [23:0] mb = {~f_is_sub(b) && (b[30:23] != 0), b[22:0]};
    wire [23:0] mc = {~f_is_sub(c) && (c[30:23] != 0), c[22:0]};
    // subnormals have an effective exponent of 1, not 0
    // Declared at the full working width so that NO concatenation is needed to
    // widen them later. Concatenation is UNSIGNED in SystemVerilog, so
    // {2'b0, ep} on a negative ep yields its raw bit pattern as a large
    // positive number -- which is exactly the bug this file shipped with:
    // shift_amt came out as 4139 instead of 43.
    wire signed [13:0] ea = (a[30:23] == 0) ? 14'sd1 : 14'sd0 + $signed({6'd0, a[30:23]});
    wire signed [13:0] eb = (b[30:23] == 0) ? 14'sd1 : 14'sd0 + $signed({6'd0, b[30:23]});
    wire signed [13:0] ec = (c[30:23] == 0) ? 14'sd1 : 14'sd0 + $signed({6'd0, c[30:23]});

    // ---- product ------------------------------------------------------------
    wire [47:0] prod = ma * mb;                       // exact, 48 bits
    wire        sp   = sa ^ sb;
    // unbiased-ish product exponent, in the same biased frame as ec.
    // ma*mb has its binary point after bit 46 when both are normal.
    wire signed [13:0] ep = ea + eb - 14'sd127;

    wire prod_zero = f_is_zero(a) || f_is_zero(b);
    wire any_nan   = f_is_nan(a) || f_is_nan(b) || f_is_nan(c);
    wire any_snan  = f_is_snan(a) || f_is_snan(b) || f_is_snan(c);
    wire inf_prod  = f_is_inf(a) || f_is_inf(b);
    wire inv_mul   = (f_is_inf(a) && f_is_zero(b)) || (f_is_zero(a) && f_is_inf(b));
    wire inv_add   = inf_prod && f_is_inf(c) && (sp != sc);

    // ---- DIFFERENCE 1: BIDIRECTIONAL alignment onto max(ep, ec) --------------
    // Both operands have a shift path; the larger sets the frame.
    wire signed [13:0] e_frame = (ep > ec) ? ep : ec;
    logic [ACC_W-1:0]  acc_c, acc_p;
    logic              p_sticky, c_sticky;

    always_comb begin
        automatic int shp, shc;
        acc_p = '0; acc_c = '0; p_sticky = 1'b0; c_sticky = 1'b0;

        // product LSB weight 2^(ep-127-46); frame bit B weight 2^(B-P_POS+e_frame-150)
        shp = P_POS + int'(ep - e_frame) - 23;
        if (shp >= 0) begin
            if (shp < ACC_W) acc_p = {{(ACC_W-48){1'b0}}, prod} << shp;
        end else begin
            automatic int rs = -shp;
            if (rs < 48) begin
                acc_p    = {{(ACC_W-48){1'b0}}, prod} >> rs;
                p_sticky = |(prod & ((48'd1 << rs) - 48'd1));
            end else p_sticky = |prod;
        end

        // addend LSB weight 2^(ec-127-23); frame bit B as above
        shc = P_POS + int'(ec - e_frame);
        if (shc >= 0) begin
            if (shc < ACC_W) acc_c = {{(ACC_W-24){1'b0}}, mc} << shc;
        end else begin
            automatic int rs = -shc;
            if (rs < 24) begin
                acc_c    = {{(ACC_W-24){1'b0}}, mc} >> rs;
                c_sticky = |(mc & ((24'd1 << rs) - 24'd1));
            end else c_sticky = |mc;
        end
    end

    // ---- signed add ---------------------------------------------------------
    wire eff_sub = sp ^ sc;
    logic signed [ACC_W+1:0] sum_s;
    logic                    res_sign;
    logic [ACC_W-1:0]        mag;
    logic                    sticky_in;

    always_comb begin
        automatic logic signed [ACC_W+1:0] pa, pc;
        pa = $signed({2'b0, acc_p});
        pc = $signed({2'b0, acc_c});
        sum_s = (sp ? -pa : pa) + (sc ? -pc : pc);
        // a borrow into the sticky region flips its sense on subtraction
        sticky_in = p_sticky | c_sticky;
        if (sum_s < 0) begin
            res_sign = 1'b1;
            mag = (-sum_s) - (eff_sub && (p_sticky | c_sticky) ? 1 : 0);
        end else begin
            res_sign = 1'b0;
            mag = sum_s[ACC_W-1:0] - (eff_sub && (p_sticky | c_sticky) ? 1 : 0);
        end
        if (eff_sub && (p_sticky | c_sticky)) sticky_in = 1'b1;
    end

    // ---- DIFFERENCE 3: ONE leading-one index, ONE barrel shift ---------------
    // No lzc-then-correct staging: the subnormal case is folded in by clamping
    // the index before the single shift.
    logic [8:0] lead;          // index of the highest set bit
    logic       any_bits;
    always_comb begin
        lead = '0; any_bits = 1'b0;
        for (int i = 0; i < ACC_W; i++)
            if (mag[i]) begin lead = i[8:0]; any_bits = 1'b1; end
    end

    // exponent if we normalise so the leading one becomes the hidden bit
    wire signed [13:0] e_norm = e_frame + $signed({5'd0, lead}) - 14'sd103;

    // clamp: a result below the smallest normal stays in the subnormal frame
    wire subn_res = (e_norm < 14'sd1);
    wire signed [13:0] e_eff   = subn_res ? 14'sd1 : e_norm;
    // bits below the 24-bit significand become guard/round/sticky
    wire signed [13:0] drop = $signed({5'd0, lead}) - 14'sd23
                              + (subn_res ? (14'sd1 - e_norm) : 14'sd0);

    logic [23:0] sig;
    logic        g_bit, r_bit, s_bit;
    always_comb begin
        automatic int d = drop;
        sig = '0; g_bit = 0; r_bit = 0; s_bit = sticky_in;
        if (d <= 0) begin
            sig = mag[23:0] << (-d);
        end else begin
            sig   = mag[d +: 24];
            g_bit = mag[d-1];
            if (d >= 2) r_bit = mag[d-2];
            if (d >= 3) s_bit = s_bit | (|(mag & ((({ACC_W{1'b0}} | 1) << (d-2)) - 1)));
        end
    end

    // ---- DIFFERENCE 2: compute BOTH candidates, then select -----------------
    wire [24:0] sig_trunc = {1'b0, sig};
    wire [24:0] sig_incr  = {1'b0, sig} + 25'd1;
    wire        lsb   = sig[0];
    wire        sticky_all = r_bit | s_bit;

    logic sel_incr;
    always_comb begin
        case (rnd_mode)
            3'd0: sel_incr = g_bit && (sticky_all || lsb);        // RNE
            3'd1: sel_incr = 1'b0;                                 // RTZ
            3'd2: sel_incr = res_sign && (g_bit || sticky_all);    // RDN
            3'd3: sel_incr = !res_sign && (g_bit || sticky_all);   // RUP
            3'd4: sel_incr = g_bit;                                // RMM
            default: sel_incr = 1'b0;
        endcase
    end

    wire [24:0] sig_r = sel_incr ? sig_incr : sig_trunc;
    wire        carry = sig_r[24];
    wire [23:0] sig_f = carry ? sig_r[24:1] : sig_r[23:0];
    wire signed [13:0] e_f = e_eff + (carry ? 14'sd1 : 14'sd0);

    wire inexact_pre = g_bit | r_bit | s_bit;

    // ---- assemble -----------------------------------------------------------
    logic [31:0] res_n;
    logic        ovf, unf;
    always_comb begin
        ovf = 1'b0; unf = 1'b0;
        if (!any_bits) begin
            // exact zero: sign is + except under RDN
            res_n = (rnd_mode == 3'd2) ? 32'h80000000 : 32'h00000000;
            if (eff_sub == 1'b0 && sp && sc) res_n = {1'b1, 31'd0};
        end else if (e_f >= 14'sd255) begin
            ovf = 1'b1;
            case (rnd_mode)
                3'd1:    res_n = {res_sign, 8'hFE, 23'h7FFFFF};
                3'd2:    res_n = res_sign ? {1'b1, 8'hFF, 23'd0} : {1'b0, 8'hFE, 23'h7FFFFF};
                3'd3:    res_n = res_sign ? {1'b1, 8'hFE, 23'h7FFFFF} : {1'b0, 8'hFF, 23'd0};
                default: res_n = {res_sign, 8'hFF, 23'd0};
            endcase
        end else if (sig_f[23] == 1'b0 && e_f <= 14'sd1) begin
            res_n = {res_sign, 8'd0, sig_f[22:0]};     // subnormal
            unf   = inexact_pre;
        end else begin
            res_n = {res_sign, e_f[7:0], sig_f[22:0]};
        end
    end

    // ---- special cases dominate --------------------------------------------
    logic [31:0] res_final;
    logic        f_nv, f_of, f_uf, f_nx;
    always_comb begin
        f_nv = 1'b0; f_of = 1'b0; f_uf = 1'b0; f_nx = 1'b0;
        if (any_nan || inv_mul || inv_add) begin
            res_final = 32'h7FC00000;                  // canonical qNaN, per spec A4
            f_nv      = any_snan || inv_mul || inv_add;
        end else if (inf_prod || f_is_inf(c)) begin
            res_final = inf_prod ? {sp, 8'hFF, 23'd0} : {sc, 8'hFF, 23'd0};
        end else if (prod_zero && f_is_zero(c)) begin
            res_final = (sp == sc) ? {sp, 31'd0}
                                   : ((rnd_mode == 3'd2) ? 32'h80000000 : 32'h00000000);
        end else if (prod_zero) begin
            res_final = c;
        end else begin
            res_final = res_n;
            f_of = ovf;
            f_uf = unf;
            f_nx = inexact_pre | ovf;
        end
    end

    assign result         = res_final;
    assign flag_invalid   = f_nv;
    assign flag_overflow  = f_of;
    assign flag_underflow = f_uf;
    assign flag_inexact   = f_nx;

    // combinational: II=1 by construction (C3)
    assign in_ready  = out_ready;
    assign out_valid = in_valid;

endmodule
