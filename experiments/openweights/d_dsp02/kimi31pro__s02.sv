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

    // -------------------------------------------------------------------------
    // Pipeline control
    // -------------------------------------------------------------------------
    logic valid1, valid2, valid3;
    logic ready1, ready2, ready3;

    // -------------------------------------------------------------------------
    // Stage 1: classification and multiplication
    // -------------------------------------------------------------------------
    logic [23:0] ma_c, mb_c, mc_c;
    logic [47:0] product_c;
    logic signed [9:0] ep_c, ec_c;
    logic sp_c, sc_c;

    logic a_nan, b_nan, c_nan;
    logic a_snan, b_snan, c_snan;
    logic a_inf, b_inf, c_inf;
    logic a_zero, b_zero;
    logic any_nan, any_snan;
    logic zero_times_inf, product_inf, inf_cancellation;

    logic special_c;
    logic special_invalid_c;
    logic [31:0] special_result_c;

    integer ea_i, eb_i, ec_i;

    logic s1_special;
    logic s1_special_invalid;
    logic [31:0] s1_special_result;
    logic [47:0] s1_product;
    logic [23:0] s1_mc;
    logic signed [9:0] s1_ep, s1_ec;
    logic s1_sp, s1_sc;
    logic [31:0] s1_c;
    logic [2:0] s1_rnd;

    // -------------------------------------------------------------------------
    // Stage 2: alignment and exact magnitude addition/subtraction
    //
    // The larger-exponent operand is held with 47 fractional bits.  Thus the
    // complete product and all alignment information relevant to rounding fit
    // in 96 bits.  Bits shifted beyond that window become sticky.
    // -------------------------------------------------------------------------
    logic c2_direct;
    logic c2_direct_invalid;
    logic [31:0] c2_direct_result;
    logic [95:0] c2_w;
    logic c2_sticky;
    logic c2_sign;
    logic signed [9:0] c2_q;
    logic [2:0] c2_rnd;

    logic [47:0] x48, y48;
    logic [95:0] a_mag, b_mag, w_mag;
    logic [47:0] lost_mask;
    logic sign_x, sign_y, w_sign;
    logic b_sticky, result_sticky;
    integer align_e_i, align_d_i, align_sh_i;

    logic s2_direct;
    logic s2_direct_invalid;
    logic [31:0] s2_direct_result;
    logic [95:0] s2_w;
    logic s2_sticky;
    logic s2_sign;
    logic signed [9:0] s2_q;
    logic [2:0] s2_rnd;

    // -------------------------------------------------------------------------
    // Stage 3: normalization, rounding, and flag generation
    // -------------------------------------------------------------------------
    logic [31:0] c3_result;
    logic c3_invalid, c3_overflow, c3_underflow, c3_inexact;

    logic [95:0] n_mag, rounded_mag, mant_mag, mask96;
    logic guard_bit, lower_bits, inexact_tmp, increment;
    logic normal_path, to_inf, found_one;
    logic [7:0] exp_field;
    integer lz_i, k_i, q3_i, e3_i, r3_i, eout_i;

    logic [31:0] result3;
    logic invalid3, overflow3, underflow3, inexact3;

    assign ready3 = ~valid3 | out_ready;
    assign ready2 = ~valid2 | ready3;
    assign ready1 = ~valid1 | ready2;

    // No combinational dependence on in_valid.
    assign in_ready = rst_n & ready1;

    // No combinational dependence on out_ready.
    assign out_valid = valid3 & rst_n;

    assign result         = result3;
    assign flag_invalid   = invalid3;
    assign flag_overflow  = overflow3;
    assign flag_underflow = underflow3;
    assign flag_inexact   = inexact3;

    // -------------------------------------------------------------------------
    // Classification and 24-by-24 multiplication
    // -------------------------------------------------------------------------
    always_comb begin
        a_nan  = (&a[30:23]) && (|a[22:0]);
        b_nan  = (&b[30:23]) && (|b[22:0]);
        c_nan  = (&c[30:23]) && (|c[22:0]);

        a_snan = a_nan && !a[22];
        b_snan = b_nan && !b[22];
        c_snan = c_nan && !c[22];

        a_inf  = (&a[30:23]) && !(|a[22:0]);
        b_inf  = (&b[30:23]) && !(|b[22:0]);
        c_inf  = (&c[30:23]) && !(|c[22:0]);

        a_zero = !(|a[30:0]);
        b_zero = !(|b[30:0]);

        ma_c = (a[30:23] == 8'd0) ? {1'b0, a[22:0]}
                                  : {1'b1, a[22:0]};
        mb_c = (b[30:23] == 8'd0) ? {1'b0, b[22:0]}
                                  : {1'b1, b[22:0]};
        mc_c = (c[30:23] == 8'd0) ? {1'b0, c[22:0]}
                                  : {1'b1, c[22:0]};

        // value = significand * 2^exponent
        ea_i = (a[30:23] == 8'd0) ? -149 : (a[30:23] - 150);
        eb_i = (b[30:23] == 8'd0) ? -149 : (b[30:23] - 150);
        ec_i = (c[30:23] == 8'd0) ? -149 : (c[30:23] - 150);

        ep_c = ea_i + eb_i;
        ec_c = ec_i;

        // The 48-bit left operand ensures a full 48-bit product expression.
        product_c = {24'b0, ma_c} * mb_c;

        sp_c = a[31] ^ b[31];
        sc_c = c[31];

        any_nan  = a_nan | b_nan | c_nan;
        any_snan = a_snan | b_snan | c_snan;

        zero_times_inf = (a_zero & b_inf) | (b_zero & a_inf);

        product_inf = (a_inf && !b_zero && !b_nan) ||
                      (b_inf && !a_zero && !a_nan);

        inf_cancellation = product_inf && c_inf && (sp_c != sc_c);

        special_invalid_c = any_snan | zero_times_inf | inf_cancellation;
        special_result_c  = 32'd0;
        special_c         = 1'b1;

        if (any_nan || zero_times_inf || inf_cancellation) begin
            special_result_c = 32'h7fc00000;
        end else if (product_inf) begin
            special_result_c = {sp_c, 8'hff, 23'b0};
        end else if (c_inf) begin
            special_result_c = {sc_c, 8'hff, 23'b0};
        end else begin
            special_c = 1'b0;
        end
    end

    // -------------------------------------------------------------------------
    // Alignment and magnitude addition/subtraction
    // -------------------------------------------------------------------------
    always_comb begin
        c2_direct         = s1_special;
        c2_direct_invalid = s1_special_invalid;
        c2_direct_result  = s1_special_result;
        c2_w              = 96'd0;
        c2_sticky         = 1'b0;
        c2_sign           = 1'b0;
        c2_q              = 10'sd0;
        c2_rnd            = s1_rnd;

        x48           = 48'd0;
        y48           = 48'd0;
        a_mag         = 96'd0;
        b_mag         = 96'd0;
        w_mag         = 96'd0;
        lost_mask     = 48'd0;
        sign_x        = 1'b0;
        sign_y        = 1'b0;
        w_sign        = 1'b0;
        b_sticky      = 1'b0;
        result_sticky = 1'b0;
        align_e_i     = 0;
        align_d_i     = 0;
        align_sh_i    = 0;

        if (!s1_special) begin
            c2_direct_invalid = 1'b0;

            if (s1_product == 48'd0) begin
                // A zero product plus a nonzero binary32 addend is exactly that
                // addend.  Two zeros require the IEEE signed-zero rules.
                c2_direct = 1'b1;
                if (s1_mc == 24'd0) begin
                    if (s1_sp == s1_sc)
                        c2_direct_result = {s1_sp, 31'b0};
                    else
                        c2_direct_result = {(s1_rnd == 3'd2), 31'b0};
                end else begin
                    c2_direct_result = s1_c;
                end
            end else begin
                // With a zero addend, select the product unconditionally.  This
                // also prevents the zero addend's nominal exponent from causing
                // the nonzero product to be shifted entirely into sticky.
                if (s1_mc == 24'd0) begin
                    align_e_i = $signed(s1_ep);
                    align_d_i = 0;
                    x48       = s1_product;
                    y48       = 48'd0;
                    sign_x    = s1_sp;
                    sign_y    = s1_sp;
                end else if ($signed(s1_ep) >= $signed(s1_ec)) begin
                    align_e_i = $signed(s1_ep);
                    align_d_i = $signed(s1_ep) - $signed(s1_ec);
                    x48       = s1_product;
                    y48       = {24'b0, s1_mc};
                    sign_x    = s1_sp;
                    sign_y    = s1_sc;
                end else begin
                    align_e_i = $signed(s1_ec);
                    align_d_i = $signed(s1_ec) - $signed(s1_ep);
                    x48       = {24'b0, s1_mc};
                    y48       = s1_product;
                    sign_x    = s1_sc;
                    sign_y    = s1_sp;
                end

                a_mag = {1'b0, x48, 47'b0};

                if (align_d_i <= 47) begin
                    b_mag    = {48'b0, y48} << (47 - align_d_i);
                    b_sticky = 1'b0;
                end else begin
                    align_sh_i = align_d_i - 47;
                    if (align_sh_i >= 48) begin
                        b_mag    = 96'd0;
                        b_sticky = |y48;
                    end else begin
                        b_mag     = {48'b0, y48} >> align_sh_i;
                        lost_mask = (48'h1 << align_sh_i) - 48'h1;
                        b_sticky  = |(y48 & lost_mask);
                    end
                end

                result_sticky = b_sticky;

                if (sign_x == sign_y) begin
                    w_mag  = a_mag + b_mag;
                    w_sign = sign_x;
                end else if (!b_sticky) begin
                    if (a_mag >= b_mag) begin
                        w_mag  = a_mag - b_mag;
                        w_sign = sign_x;
                    end else begin
                        w_mag  = b_mag - a_mag;
                        w_sign = sign_y;
                    end
                end else begin
                    // If the discarded fraction belongs to the subtrahend,
                    // subtract one at the window LSB.  The remaining positive
                    // fraction is then represented by sticky, just as for add.
                    if (a_mag > b_mag) begin
                        w_mag  = a_mag - b_mag - 96'd1;
                        w_sign = sign_x;
                    end else begin
                        w_mag  = b_mag - a_mag;
                        w_sign = sign_y;
                    end
                end

                c2_w      = w_mag;
                c2_sticky = result_sticky;
                c2_sign   = w_sign;
                c2_q      = align_e_i - 47;

                if ((w_mag == 96'd0) && !result_sticky) begin
                    // Exact cancellation of nonzero operands.
                    c2_direct        = 1'b1;
                    c2_direct_result = {(s1_rnd == 3'd2), 31'b0};
                end
            end
        end
    end

    // -------------------------------------------------------------------------
    // Normalize and round exactly once
    // -------------------------------------------------------------------------
    always_comb begin
        c3_result    = 32'd0;
        c3_invalid   = 1'b0;
        c3_overflow  = 1'b0;
        c3_underflow = 1'b0;
        c3_inexact   = 1'b0;

        n_mag        = 96'd0;
        rounded_mag  = 96'd0;
        mant_mag     = 96'd0;
        mask96       = 96'd0;
        guard_bit    = 1'b0;
        lower_bits   = 1'b0;
        inexact_tmp  = 1'b0;
        increment    = 1'b0;
        normal_path  = 1'b0;
        to_inf       = 1'b0;
        found_one    = 1'b0;
        exp_field    = 8'd0;
        k_i          = 0;
        q3_i         = 0;
        e3_i         = 0;
        r3_i         = 0;
        eout_i       = 0;

        if (s2_direct) begin
            c3_result  = s2_direct_result;
            c3_invalid = s2_direct_invalid;
        end else begin
            // Leading-one detection over the bounded 96-bit datapath.
            for (lz_i = 95; lz_i >= 0; lz_i = lz_i - 1) begin
                if (!found_one && s2_w[lz_i]) begin
                    k_i       = lz_i;
                    found_one = 1'b1;
                end
            end

            q3_i = $signed(s2_q);
            e3_i = q3_i + k_i;

            normal_path = (e3_i >= -126);
            if (normal_path)
                r3_i = k_i - 23;
            else
                r3_i = -149 - q3_i;

            // Form the truncated significand at the destination quantum and
            // classify the discarded remainder relative to one half ulp.
            if (r3_i > 0) begin
                if (r3_i < 96) begin
                    n_mag   = s2_w >> r3_i;
                    mask96  = (96'h1 << r3_i) - 96'h1;
                    inexact_tmp = s2_sticky | (|(s2_w & mask96));

                    guard_bit = s2_w[r3_i-1];
                    mask96    = (96'h1 << (r3_i-1)) - 96'h1;
                    lower_bits = s2_sticky | (|(s2_w & mask96));
                end else if (r3_i == 96) begin
                    n_mag       = 96'd0;
                    inexact_tmp = s2_sticky | (|s2_w);
                    guard_bit   = s2_w[95];
                    lower_bits  = s2_sticky | (|s2_w[94:0]);
                end else begin
                    n_mag       = 96'd0;
                    inexact_tmp = s2_sticky | (|s2_w);
                    guard_bit   = 1'b0;
                    lower_bits  = s2_sticky | (|s2_w);
                end
            end else begin
                // Whenever sticky is set, normalization guarantees r3_i > 0.
                // Thus this path is the exact left-shift path.
                n_mag       = s2_w << (-r3_i);
                inexact_tmp = s2_sticky;
                guard_bit   = 1'b0;
                lower_bits  = s2_sticky;
            end

            case (s2_rnd)
                3'd0: increment = guard_bit && (lower_bits || n_mag[0]); // RNE
                3'd1: increment = 1'b0;                                // RTZ
                3'd2: increment = s2_sign && inexact_tmp;              // RDN
                3'd3: increment = !s2_sign && inexact_tmp;             // RUP
                3'd4: increment = guard_bit;                           // RMM
                default: increment = 1'b0;
            endcase

            rounded_mag = n_mag + increment;

            if (normal_path) begin
                eout_i   = e3_i;
                mant_mag = rounded_mag;

                // Rounding 1.111...1 up to 10.000...0.
                if (rounded_mag[24]) begin
                    eout_i   = e3_i + 1;
                    mant_mag = rounded_mag >> 1;
                end

                if (eout_i > 127) begin
                    c3_overflow = 1'b1;
                    c3_inexact  = 1'b1;

                    to_inf = (s2_rnd == 3'd0) || (s2_rnd == 3'd4) ||
                             ((s2_rnd == 3'd3) && !s2_sign) ||
                             ((s2_rnd == 3'd2) && s2_sign);

                    if (to_inf)
                        c3_result = {s2_sign, 8'hff, 23'b0};
                    else
                        c3_result = {s2_sign, 8'hfe, 23'h7fffff};
                end else begin
                    exp_field  = eout_i + 127;
                    c3_result  = {s2_sign, exp_field, mant_mag[22:0]};
                    c3_inexact = inexact_tmp;
                end
            end else begin
                // The only upward crossing possible here is to the smallest
                // normal.  UF deliberately examines the delivered exponent.
                if (rounded_mag[23])
                    c3_result = {s2_sign, 8'h01, 23'b0};
                else
                    c3_result = {s2_sign, 8'h00, rounded_mag[22:0]};

                c3_inexact   = inexact_tmp;
                c3_underflow = inexact_tmp && !rounded_mag[23];
            end
        end
    end

    // -------------------------------------------------------------------------
    // Three elastic register boundaries.  With an always-ready consumer, one
    // operation is accepted and one result is produced every cycle.
    // -------------------------------------------------------------------------
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            valid1 <= 1'b0;
            valid2 <= 1'b0;
            valid3 <= 1'b0;
        end else begin
            if (ready1) begin
                valid1 <= in_valid;
                if (in_valid) begin
                    s1_special         <= special_c;
                    s1_special_invalid <= special_invalid_c;
                    s1_special_result  <= special_result_c;
                    s1_product         <= product_c;
                    s1_mc              <= mc_c;
                    s1_ep              <= ep_c;
                    s1_ec              <= ec_c;
                    s1_sp              <= sp_c;
                    s1_sc              <= sc_c;
                    s1_c               <= c;
                    s1_rnd             <= rnd_mode;
                end
            end

            if (ready2) begin
                valid2 <= valid1;
                if (valid1) begin
                    s2_direct         <= c2_direct;
                    s2_direct_invalid <= c2_direct_invalid;
                    s2_direct_result  <= c2_direct_result;
                    s2_w              <= c2_w;
                    s2_sticky         <= c2_sticky;
                    s2_sign           <= c2_sign;
                    s2_q              <= c2_q;
                    s2_rnd            <= c2_rnd;
                end
            end

            if (ready3) begin
                valid3 <= valid2;
                if (valid2) begin
                    result3    <= c3_result;
                    invalid3   <= c3_invalid;
                    overflow3  <= c3_overflow;
                    underflow3 <= c3_underflow;
                    inexact3   <= c3_inexact;
                end
            end
        end
    end

endmodule
