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

    // -------------------------------------------------------------------------
    // Classification
    // -------------------------------------------------------------------------
    logic a_nan, b_nan, c_nan;
    logic a_snan, b_snan, c_snan;
    logic a_inf, b_inf, c_inf;
    logic a_zero, b_zero, c_zero;
    logic product_zero;
    logic prod_sign;

    assign a_nan  = (a[30:23] == 8'hff) && (a[22:0] != 0);
    assign b_nan  = (b[30:23] == 8'hff) && (b[22:0] != 0);
    assign c_nan  = (c[30:23] == 8'hff) && (c[22:0] != 0);
    assign a_snan = a_nan && !a[22];
    assign b_snan = b_nan && !b[22];
    assign c_snan = c_nan && !c[22];

    assign a_inf  = (a[30:23] == 8'hff) && (a[22:0] == 0);
    assign b_inf  = (b[30:23] == 8'hff) && (b[22:0] == 0);
    assign c_inf  = (c[30:23] == 8'hff) && (c[22:0] == 0);

    assign a_zero = (a[30:23] == 0) && (a[22:0] == 0);
    assign b_zero = (b[30:23] == 0) && (b[22:0] == 0);
    assign c_zero = (c[30:23] == 0) && (c[22:0] == 0);

    assign product_zero = a_zero || b_zero;
    assign prod_sign    = a[31] ^ b[31];

    // Return the position of the highest set bit.  The input is nonzero on
    // every arithmetic path where the result is used.
    function automatic [6:0] msb_96(input logic [95:0] x);
        integer j;
        begin
            msb_96 = 7'd0;
            for (j = 0; j < 96; j = j + 1) begin
                if (x[j])
                    msb_96 = j[6:0];
            end
        end
    endfunction

    // True iff any bit below bit number sh is set.  sh may exceed 96.
    function automatic logic any_low_96(
        input logic [95:0] x,
        input integer      sh
    );
        integer j;
        begin
            any_low_96 = 1'b0;
            for (j = 0; j < 96; j = j + 1) begin
                if ((j < sh) && x[j])
                    any_low_96 = 1'b1;
            end
        end
    endfunction

    // -------------------------------------------------------------------------
    // Stage 1: classify, multiply, and align.
    //
    // A finite nonzero product is P*2^sp and the addend is Mc*2^sc.  The
    // larger scale is H.  The larger term is placed with its least significant
    // bit at bit 48, giving a 96-bit exact window.  If the other scale differs
    // by at most 48, both terms are exact.  Otherwise the smaller term is
    // truncated and its discarded portion is recorded as a sticky bit.
    // -------------------------------------------------------------------------
    logic [23:0] ma, mb, mc;
    logic [47:0] ma48, mb48, product;
    logic [95:0] product_ext, mc_ext;
    integer sa, sb, sc, sp;
    integer h_exp, d_exp, r_exp, sh_exp;

    logic        s1_direct_c;
    logic [31:0] s1_dresult_c;
    logic        s1_dinv_c, s1_dof_c, s1_duf_c, s1_dnx_c;
    logic [95:0] s1_a_c, s1_b_c;
    logic        s1_residual_c;
    logic signed [31:0] s1_q_c;
    logic        s1_same_c, s1_larger_product_c;
    logic        s1_ps_c, s1_cs_c;

    always_comb begin
        ma = {1'b0, a[22:0]};
        mb = {1'b0, b[22:0]};
        mc = {1'b0, c[22:0]};

        sa = a[30:23];
        sb = b[30:23];
        sc = c[30:23];

        if (a[30:23] == 0) begin
            sa = -149;
        end else begin
            ma[23] = 1'b1;
            sa = sa - 150;
        end
        if (b[30:23] == 0) begin
            sb = -149;
        end else begin
            mb[23] = 1'b1;
            sb = sb - 150;
        end
        if (c[30:23] == 0) begin
            sc = -149;
        end else begin
            mc[23] = 1'b1;
            sc = sc - 150;
        end

        sp = sa + sb;

        ma48 = {24'd0, ma};
        mb48 = {24'd0, mb};
        product = ma48 * mb48;
        product_ext = {48'd0, product};
        mc_ext = {72'd0, mc};

        h_exp = 0;
        d_exp = 0;
        r_exp = 0;
        sh_exp = 0;

        s1_direct_c = 1'b0;
        s1_dresult_c = 32'd0;
        s1_dinv_c = 1'b0;
        s1_dof_c = 1'b0;
        s1_duf_c = 1'b0;
        s1_dnx_c = 1'b0;

        s1_a_c = 96'd0;
        s1_b_c = 96'd0;
        s1_residual_c = 1'b0;
        s1_q_c = 32'sd0;
        s1_same_c = 1'b0;
        s1_larger_product_c = 1'b0;
        s1_ps_c = prod_sign;
        s1_cs_c = c[31];

        if (a_nan || b_nan || c_nan) begin
            s1_direct_c = 1'b1;
            s1_dresult_c = 32'h7fc00000;
            s1_dinv_c = a_snan || b_snan || c_snan;
        end else if ((a_inf && b_zero) || (b_inf && a_zero)) begin
            s1_direct_c = 1'b1;
            s1_dresult_c = 32'h7fc00000;
            s1_dinv_c = 1'b1;
        end else if ((a_inf || b_inf) && c_inf &&
                     (prod_sign != c[31])) begin
            s1_direct_c = 1'b1;
            s1_dresult_c = 32'h7fc00000;
            s1_dinv_c = 1'b1;
        end else if (a_inf || b_inf) begin
            s1_direct_c = 1'b1;
            s1_dresult_c = {prod_sign, 8'hff, 23'd0};
        end else if (c_inf) begin
            s1_direct_c = 1'b1;
            s1_dresult_c = {c[31], 8'hff, 23'd0};
        end else if (product_zero) begin
            s1_direct_c = 1'b1;
            if (c_zero) begin
                if (prod_sign == c[31])
                    s1_dresult_c = {prod_sign, 31'd0};
                else
                    s1_dresult_c = {(rnd_mode == 3'd2), 31'd0};
            end else begin
                // A signed zero addend cannot change a nonzero c.
                s1_dresult_c = c;
            end
        end else if (c_zero) begin
            // Product only; retaining it in the exact window avoids treating
            // the zero addend's sign or scale as an arithmetic contribution.
            s1_a_c = product_ext << 48;
            s1_b_c = 96'd0;
            s1_q_c = sp - 48;
            s1_same_c = 1'b1;
            s1_larger_product_c = 1'b1;
        end else begin
            s1_same_c = (prod_sign == c[31]);

            if (sp >= sc) begin
                s1_larger_product_c = 1'b1;
                h_exp = sp;
                d_exp = sp - sc;
            end else begin
                s1_larger_product_c = 1'b0;
                h_exp = sc;
                d_exp = sc - sp;
            end
            s1_q_c = h_exp - 48;

            if (d_exp <= 48) begin
                sh_exp = 48 - d_exp;
                if (sp >= sc) begin
                    s1_a_c = product_ext << 48;
                    s1_b_c = mc_ext << sh_exp;
                end else begin
                    s1_a_c = mc_ext << 48;
                    s1_b_c = product_ext << sh_exp;
                end
            end else begin
                r_exp = d_exp - 48;
                if (sp >= sc) begin
                    s1_a_c = product_ext << 48;
                    if (r_exp >= 24) begin
                        s1_b_c = 96'd0;
                        s1_residual_c = 1'b1;
                    end else begin
                        s1_b_c = mc_ext >> r_exp;
                        s1_residual_c =
                            ((s1_b_c << r_exp) != mc_ext);
                    end
                end else begin
                    s1_a_c = mc_ext << 48;
                    if (r_exp >= 48) begin
                        s1_b_c = 96'd0;
                        s1_residual_c = 1'b1;
                    end else begin
                        s1_b_c = product_ext >> r_exp;
                        s1_residual_c =
                            ((s1_b_c << r_exp) != product_ext);
                    end
                end
            end
        end
    end

    // -------------------------------------------------------------------------
    // Pipeline registers, stage 1
    // -------------------------------------------------------------------------
    logic        v1;
    logic        d1;
    logic [31:0] dr1;
    logic        di1, do1, du1, dn1;
    logic [95:0] aligned_a1, aligned_b1;
    logic        residual1;
    logic signed [31:0] q1;
    logic        same1, larger_product1, ps1, cs1;
    logic [2:0]  rnd1;

    // -------------------------------------------------------------------------
    // Stage 2: exact-window addition/subtraction and leading-one detection.
    //
    // With opposite signs and a discarded residual r (0<r<1), the exact
    // magnitude is A-B-r = (A-B-1) + (1-r).  Thus decrementing the integer
    // part and retaining sticky represents it correctly for every rounding
    // mode, including truncation and nearest rounding across a power of two.
    // -------------------------------------------------------------------------
    logic        d2_c;
    logic [31:0] dr2_c;
    logic        di2_c, do2_c, du2_c, dn2_c;
    logic [95:0] mag2_c;
    logic        sticky2_c, sign2_c, zero2_c;
    logic signed [31:0] q2_c;
    logic [6:0]  msb2_c;
    logic [2:0]  rnd2_c;

    always_comb begin
        d2_c = d1;
        dr2_c = dr1;
        di2_c = di1;
        do2_c = do1;
        du2_c = du1;
        dn2_c = dn1;

        mag2_c = 96'd0;
        sticky2_c = 1'b0;
        sign2_c = 1'b0;
        zero2_c = 1'b0;
        q2_c = q1;
        rnd2_c = rnd1;

        if (!d1) begin
            if (same1) begin
                mag2_c = aligned_a1 + aligned_b1;
                sticky2_c = residual1;
                sign2_c = ps1;
            end else if (residual1) begin
                // A residual can occur only when the scale separation is
                // large enough that aligned_a1 strictly dominates.
                mag2_c = aligned_a1 - aligned_b1 - 96'd1;
                sticky2_c = 1'b1;
                sign2_c = larger_product1 ? ps1 : cs1;
            end else if (aligned_a1 > aligned_b1) begin
                mag2_c = aligned_a1 - aligned_b1;
                sign2_c = larger_product1 ? ps1 : cs1;
            end else if (aligned_b1 > aligned_a1) begin
                mag2_c = aligned_b1 - aligned_a1;
                sign2_c = larger_product1 ? cs1 : ps1;
            end else begin
                mag2_c = 96'd0;
                sign2_c = 1'b0;
            end

            if ((mag2_c == 96'd0) && !sticky2_c) begin
                zero2_c = 1'b1;
                sign2_c = (rnd1 == 3'd2);
            end
        end

        msb2_c = msb_96(mag2_c);
    end

    // -------------------------------------------------------------------------
    // Pipeline registers, stage 2
    // -------------------------------------------------------------------------
    logic        v2;
    logic        d2;
    logic [31:0] dr2;
    logic        di2, do2, du2, dn2;
    logic [95:0] mag2;
    logic        sticky2, sign2, zero2;
    logic signed [31:0] q2;
    logic [6:0]  msb2;
    logic [2:0]  rnd2;

    // -------------------------------------------------------------------------
    // Stage 3: one rounding, result construction, and exception flags.
    // -------------------------------------------------------------------------
    logic [31:0] core_result;
    logic core_invalid, core_overflow, core_underflow, core_inexact;

    logic [95:0] keep96;
    logic [24:0] kept;
    logic guard_bit, lower_bits, discarded, round_up;
    logic normal_path, to_infinity;
    logic [7:0] result_exp;
    integer e_round, shift_round, k_round;

    always_comb begin
        core_result = 32'd0;
        core_invalid = 1'b0;
        core_overflow = 1'b0;
        core_underflow = 1'b0;
        core_inexact = 1'b0;

        keep96 = 96'd0;
        kept = 25'd0;
        guard_bit = 1'b0;
        lower_bits = 1'b0;
        discarded = 1'b0;
        round_up = 1'b0;
        normal_path = 1'b0;
        to_infinity = 1'b0;
        result_exp = 8'd0;
        e_round = 0;
        shift_round = 0;
        k_round = 0;

        case (rnd2)
            3'd0, 3'd4: to_infinity = 1'b1;
            3'd2:       to_infinity = sign2;
            3'd3:       to_infinity = !sign2;
            default:    to_infinity = 1'b0;
        endcase

        if (d2) begin
            core_result = dr2;
            core_invalid = di2;
            core_overflow = do2;
            core_underflow = du2;
            core_inexact = dn2;
        end else if (zero2) begin
            core_result = {sign2, 31'd0};
        end else begin
            k_round = msb2;
            e_round = q2;
            e_round = e_round + k_round;

            if (e_round >= -126) begin
                normal_path = 1'b1;
                if (k_round > 23) begin
                    shift_round = k_round - 23;
                    keep96 = mag2 >> shift_round;
                    guard_bit = mag2[shift_round-1];
                    lower_bits = sticky2 |
                                 any_low_96(mag2, shift_round-1);
                    discarded = sticky2 |
                                any_low_96(mag2, shift_round);
                end else begin
                    shift_round = 23 - k_round;
                    keep96 = mag2 << shift_round;
                    guard_bit = 1'b0;
                    lower_bits = sticky2;
                    discarded = sticky2;
                end
            end else begin
                normal_path = 1'b0;
                // Round directly in units of 2^-149.  This includes results
                // that round upward to the smallest normal number.
                shift_round = -q2;
                shift_round = shift_round - 149;

                if (shift_round > 0) begin
                    if (shift_round >= 96)
                        keep96 = 96'd0;
                    else
                        keep96 = mag2 >> shift_round;

                    discarded = sticky2 |
                                any_low_96(mag2, shift_round);
                    if (shift_round <= 96)
                        guard_bit = mag2[shift_round-1];
                    else
                        guard_bit = 1'b0;
                    lower_bits = sticky2 |
                                 any_low_96(mag2, shift_round-1);
                end else begin
                    keep96 = mag2 << (-shift_round);
                    guard_bit = 1'b0;
                    lower_bits = sticky2;
                    discarded = sticky2;
                end
            end

            kept = {1'b0, keep96[23:0]};

            case (rnd2)
                3'd0: round_up = guard_bit &&
                                 (lower_bits || kept[0]);
                3'd1: round_up = 1'b0;
                3'd2: round_up = sign2 && discarded;
                3'd3: round_up = !sign2 && discarded;
                3'd4: round_up = guard_bit;
                default: round_up = 1'b0;
            endcase

            if (round_up)
                kept = kept + 25'd1;

            if (normal_path) begin
                if (kept[24]) begin
                    kept = kept >> 1;
                    e_round = e_round + 1;
                end

                if (e_round > 127) begin
                    core_overflow = 1'b1;
                    core_inexact = 1'b1;
                    if (to_infinity)
                        core_result = {sign2, 8'hff, 23'd0};
                    else
                        core_result = {sign2, 8'hfe, 23'h7fffff};
                end else begin
                    result_exp = e_round + 127;
                    core_result = {sign2, result_exp, kept[22:0]};
                    core_inexact = discarded;
                end
            end else begin
                if (kept[23]) begin
                    // Rounded upward to 2^-126: delivered exponent field 1,
                    // hence no underflow under the specified delivered-result
                    // tininess rule.
                    core_result = {sign2, 8'h01, 23'd0};
                end else begin
                    core_result = {sign2, 8'h00, kept[22:0]};
                end
                core_inexact = discarded;
                core_underflow = discarded && !kept[23];
            end
        end
    end

    // -------------------------------------------------------------------------
    // Three-stage elastic pipeline.  A global advance is sufficient because
    // all stages advance together; a stalled output therefore freezes every
    // result and flag.  With an accepting consumer, advance is continuously 1.
    // -------------------------------------------------------------------------
    logic v3;
    logic [31:0] result3;
    logic invalid3, overflow3, underflow3, inexact3;
    logic advance;

    assign advance = !v3 || out_ready;
    assign in_ready = rst_n && advance;

    assign out_valid = rst_n && v3;
    assign result = result3;
    assign flag_invalid = invalid3;
    assign flag_overflow = overflow3;
    assign flag_underflow = underflow3;
    assign flag_inexact = inexact3;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            v1 <= 1'b0;
            v2 <= 1'b0;
            v3 <= 1'b0;
        end else if (advance) begin
            v1 <= in_valid;
            v2 <= v1;
            v3 <= v2;

            if (in_valid) begin
                d1 <= s1_direct_c;
                dr1 <= s1_dresult_c;
                di1 <= s1_dinv_c;
                do1 <= s1_dof_c;
                du1 <= s1_duf_c;
                dn1 <= s1_dnx_c;
                aligned_a1 <= s1_a_c;
                aligned_b1 <= s1_b_c;
                residual1 <= s1_residual_c;
                q1 <= s1_q_c;
                same1 <= s1_same_c;
                larger_product1 <= s1_larger_product_c;
                ps1 <= s1_ps_c;
                cs1 <= s1_cs_c;
                rnd1 <= rnd_mode;
            end

            if (v1) begin
                d2 <= d2_c;
                dr2 <= dr2_c;
                di2 <= di2_c;
                do2 <= do2_c;
                du2 <= du2_c;
                dn2 <= dn2_c;
                mag2 <= mag2_c;
                sticky2 <= sticky2_c;
                sign2 <= sign2_c;
                zero2 <= zero2_c;
                q2 <= q2_c;
                msb2 <= msb2_c;
                rnd2 <= rnd2_c;
            end

            if (v2) begin
                result3 <= core_result;
                invalid3 <= core_invalid;
                overflow3 <= core_overflow;
                underflow3 <= core_underflow;
                inexact3 <= core_inexact;
            end
        end
    end

endmodule
