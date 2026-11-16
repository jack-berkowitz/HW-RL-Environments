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

    localparam logic [31:0] CANONICAL_NAN = 32'h7fc00000;

    logic advance;

    logic        s1_valid;
    logic        s1_special;
    logic [31:0] s1_special_result;
    logic        s1_special_invalid;
    logic        s1_p_sign;
    logic        s1_c_sign;
    logic [47:0] s1_p_sig;
    logic [23:0] s1_c_sig;
    logic signed [9:0] s1_p_scale;
    logic signed [9:0] s1_c_scale;
    logic [2:0]  s1_rnd;

    logic        s2_valid;
    logic        s2_special;
    logic [31:0] s2_special_result;
    logic        s2_special_invalid;
    logic        s2_sign;
    logic [95:0] s2_mag;
    logic        s2_sticky;
    logic signed [9:0] s2_w_scale;
    logic [2:0]  s2_rnd;

    logic        s3_valid;
    logic [31:0] s3_result;
    logic        s3_invalid;
    logic        s3_overflow;
    logic        s3_underflow;
    logic        s3_inexact;

    logic [23:0] sig_a_c;
    logic [23:0] sig_b_c;
    logic [23:0] sig_c_c;
    logic [47:0] prod_c;
    logic        sp_c;
    logic        sc_c;
    logic        a_zero_c;
    logic        b_zero_c;
    logic        a_inf_c;
    logic        b_inf_c;
    logic        c_inf_c;
    logic        a_nan_c;
    logic        b_nan_c;
    logic        c_nan_c;
    logic        a_snan_c;
    logic        b_snan_c;
    logic        c_snan_c;
    logic        any_nan_c;
    logic        product_inf_c;
    logic        invalid_c;
    logic        special_c;
    logic [31:0] special_result_c;
    logic        special_invalid_c;
    integer      ea_i;
    integer      eb_i;
    integer      ec_i;
    integer      p_scale_i;
    integer      c_scale_i;

    logic [95:0] l2;
    logic [95:0] q2;
    logic [95:0] mag2;
    logic        rem2;
    logic        sticky2;
    logic        sign_l2;
    logic        sign_s2;
    logic        sign2;
    integer      d2;
    integer      sh2;
    integer      w_scale2i;

    logic [31:0] result3_c;
    logic        invalid3_c;
    logic        overflow3_c;
    logic        underflow3_c;
    logic        inexact3_c;
    logic [95:0] q3;
    logic [95:0] qr3;
    logic [23:0] mant3;
    logic [7:0]  exp8_3;
    logic        mag_nz3;
    logic        normal3;
    logic        guard3;
    logic        rest3;
    logic        any3;
    logic        increment3;
    integer      msb3;
    integer      e3;
    integer      r3;
    integer      biased3;
    integer      idx3;

    assign advance  = (~s3_valid) | out_ready;
    assign in_ready = rst_n & advance;
    assign out_valid = s3_valid & rst_n;

    assign result         = s3_result;
    assign flag_invalid   = s3_invalid;
    assign flag_overflow  = s3_overflow;
    assign flag_underflow = s3_underflow;
    assign flag_inexact   = s3_inexact;

    /* Classification, exact 24 by 24 multiplication, and special values. */
    always_comb begin
        sig_a_c = {(a[30:23] != 8'h00), a[22:0]};
        sig_b_c = {(b[30:23] != 8'h00), b[22:0]};
        sig_c_c = {(c[30:23] != 8'h00), c[22:0]};

        ea_i = (a[30:23] == 8'h00) ? -126 : (a[30:23] - 127);
        eb_i = (b[30:23] == 8'h00) ? -126 : (b[30:23] - 127);
        ec_i = (c[30:23] == 8'h00) ? -126 : (c[30:23] - 127);

        prod_c = sig_a_c * sig_b_c;
        sp_c = a[31] ^ b[31];
        sc_c = c[31];

        p_scale_i = ea_i + eb_i - 46;
        c_scale_i = ec_i - 23;
        if (sig_c_c == 24'd0)
            c_scale_i = p_scale_i;

        a_zero_c = (a[30:0] == 31'd0);
        b_zero_c = (b[30:0] == 31'd0);

        a_inf_c = (a[30:23] == 8'hff) && (a[22:0] == 23'd0);
        b_inf_c = (b[30:23] == 8'hff) && (b[22:0] == 23'd0);
        c_inf_c = (c[30:23] == 8'hff) && (c[22:0] == 23'd0);

        a_nan_c = (a[30:23] == 8'hff) && (a[22:0] != 23'd0);
        b_nan_c = (b[30:23] == 8'hff) && (b[22:0] != 23'd0);
        c_nan_c = (c[30:23] == 8'hff) && (c[22:0] != 23'd0);

        a_snan_c = a_nan_c && !a[22];
        b_snan_c = b_nan_c && !b[22];
        c_snan_c = c_nan_c && !c[22];
        any_nan_c = a_nan_c | b_nan_c | c_nan_c;

        product_inf_c = (a_inf_c && !b_nan_c && !b_zero_c) ||
                        (b_inf_c && !a_nan_c && !a_zero_c);

        invalid_c = a_snan_c | b_snan_c | c_snan_c |
                    (a_inf_c && b_zero_c) |
                    (b_inf_c && a_zero_c) |
                    (product_inf_c && c_inf_c && (sp_c != sc_c));

        special_c = 1'b0;
        special_result_c = 32'd0;
        special_invalid_c = 1'b0;

        if (any_nan_c || invalid_c) begin
            special_c = 1'b1;
            special_result_c = CANONICAL_NAN;
            special_invalid_c = invalid_c;
        end else if (product_inf_c) begin
            special_c = 1'b1;
            special_result_c = {sp_c, 8'hff, 23'd0};
        end else if (c_inf_c) begin
            special_c = 1'b1;
            special_result_c = {sc_c, 8'hff, 23'd0};
        end else if (prod_c == 48'd0) begin
            special_c = 1'b1;
            if (sig_c_c != 24'd0) begin
                special_result_c = c;
            end else if (sp_c == sc_c) begin
                special_result_c = {sp_c, 31'd0};
            end else begin
                special_result_c = {(rnd_mode == 3'd2), 31'd0};
            end
        end
    end

    /*
     * Align on a 96-bit grid with 47 fractional bits.  Only the operand
     * having the smaller binary scale can be shifted right.  If bits are
     * discarded during a subtraction, converting X-r to (X-1)+(1-r)
     * leaves a magnitude plus a nonzero fractional sticky contribution.
     */
    always_comb begin
        l2 = 96'd0;
        q2 = 96'd0;
        rem2 = 1'b0;
        sign_l2 = s1_p_sign;
        sign_s2 = s1_c_sign;
        d2 = 0;
        sh2 = 0;
        w_scale2i = s1_p_scale - 47;

        if (s1_p_scale >= s1_c_scale) begin
            l2 = {48'd0, s1_p_sig} << 47;
            sign_l2 = s1_p_sign;
            sign_s2 = s1_c_sign;
            d2 = s1_p_scale - s1_c_scale;
            w_scale2i = s1_p_scale - 47;

            if (d2 <= 47) begin
                q2 = {72'd0, s1_c_sig} << (47 - d2);
            end else begin
                sh2 = d2 - 47;
                if (sh2 >= 24) begin
                    q2 = 96'd0;
                    rem2 = |s1_c_sig;
                end else begin
                    q2 = {72'd0, s1_c_sig} >> sh2;
                    rem2 = |(s1_c_sig << (24 - sh2));
                end
            end
        end else begin
            l2 = {72'd0, s1_c_sig} << 47;
            sign_l2 = s1_c_sign;
            sign_s2 = s1_p_sign;
            d2 = s1_c_scale - s1_p_scale;
            w_scale2i = s1_c_scale - 47;

            if (d2 <= 47) begin
                q2 = {48'd0, s1_p_sig} << (47 - d2);
            end else begin
                sh2 = d2 - 47;
                if (sh2 >= 48) begin
                    q2 = 96'd0;
                    rem2 = |s1_p_sig;
                end else begin
                    q2 = {48'd0, s1_p_sig} >> sh2;
                    rem2 = |(s1_p_sig << (48 - sh2));
                end
            end
        end

        mag2 = 96'd0;
        sticky2 = 1'b0;
        sign2 = 1'b0;

        if (sign_l2 == sign_s2) begin
            mag2 = l2 + q2;
            sticky2 = rem2;
            sign2 = sign_l2;
        end else if (l2 > q2) begin
            sign2 = sign_l2;
            if (rem2) begin
                mag2 = l2 - q2 - 96'd1;
                sticky2 = 1'b1;
            end else begin
                mag2 = l2 - q2;
            end
        end else if (q2 > l2) begin
            mag2 = q2 - l2;
            sticky2 = rem2;
            sign2 = sign_s2;
        end else begin
            mag2 = 96'd0;
            sticky2 = rem2;
            sign2 = rem2 ? sign_s2 : 1'b0;
        end
    end

    /* Normalization, single rounding, and exception generation. */
    always_comb begin
        result3_c = 32'd0;
        invalid3_c = 1'b0;
        overflow3_c = 1'b0;
        underflow3_c = 1'b0;
        inexact3_c = 1'b0;

        q3 = 96'd0;
        qr3 = 96'd0;
        mant3 = 24'd0;
        exp8_3 = 8'd0;
        mag_nz3 = |s2_mag;
        normal3 = 1'b0;
        guard3 = 1'b0;
        rest3 = 1'b0;
        any3 = 1'b0;
        increment3 = 1'b0;
        msb3 = 0;
        e3 = -1000;
        r3 = 0;
        biased3 = 0;

        if (s2_special) begin
            result3_c = s2_special_result;
            invalid3_c = s2_special_invalid;
        end else if (!mag_nz3 && !s2_sticky) begin
            result3_c = {(s2_rnd == 3'd2), 31'd0};
        end else begin
            for (idx3 = 0; idx3 < 96; idx3 = idx3 + 1) begin
                if (s2_mag[idx3])
                    msb3 = idx3;
            end

            if (mag_nz3)
                e3 = s2_w_scale + msb3;

            normal3 = mag_nz3 && (e3 >= -126);
            if (normal3)
                r3 = msb3 - 23;
            else
                r3 = -149 - s2_w_scale;

            if (r3 > 0) begin
                if (r3 > 96) begin
                    q3 = 96'd0;
                    guard3 = 1'b0;
                    rest3 = (|s2_mag) | s2_sticky;
                    any3 = rest3;
                end else begin
                    q3 = s2_mag >> r3;
                    guard3 = s2_mag[r3-1];
                    if (r3 == 1)
                        rest3 = s2_sticky;
                    else
                        rest3 = s2_sticky |
                                (|(s2_mag << (97 - r3)));
                    any3 = guard3 | rest3;
                end
            end else begin
                q3 = s2_mag << (-r3);
                guard3 = 1'b0;
                rest3 = s2_sticky;
                any3 = s2_sticky;
            end

            case (s2_rnd)
                3'd0: increment3 = guard3 && (rest3 || q3[0]);
                3'd1: increment3 = 1'b0;
                3'd2: increment3 = s2_sign && any3;
                3'd3: increment3 = !s2_sign && any3;
                3'd4: increment3 = guard3;
                default: increment3 = 1'b0;
            endcase

            qr3 = increment3 ? (q3 + 96'd1) : q3;
            inexact3_c = any3;

            if (normal3) begin
                biased3 = e3 + 127;
                if (qr3[24]) begin
                    biased3 = biased3 + 1;
                    mant3 = qr3[24:1];
                end else begin
                    mant3 = qr3[23:0];
                end

                if (biased3 >= 255) begin
                    overflow3_c = 1'b1;
                    inexact3_c = 1'b1;
                    if ((s2_rnd == 3'd0) || (s2_rnd == 3'd4) ||
                        ((s2_rnd == 3'd3) && !s2_sign) ||
                        ((s2_rnd == 3'd2) && s2_sign)) begin
                        result3_c = {s2_sign, 8'hff, 23'd0};
                    end else begin
                        result3_c = {s2_sign, 8'hfe, 23'h7fffff};
                    end
                end else begin
                    exp8_3 = biased3;
                    result3_c = {s2_sign, exp8_3, mant3[22:0]};
                end
            end else begin
                if (qr3[23]) begin
                    result3_c = {s2_sign, 8'h01, 23'd0};
                    underflow3_c = 1'b0;
                end else begin
                    result3_c = {s2_sign, 8'h00, qr3[22:0]};
                    underflow3_c = any3;
                end
            end
        end
    end

    /* Three elastic register boundaries; a stalled output freezes the pipe. */
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            s1_valid <= 1'b0;
            s2_valid <= 1'b0;
            s3_valid <= 1'b0;
        end else if (advance) begin
            s1_valid <= in_valid;
            s2_valid <= s1_valid;
            s3_valid <= s2_valid;

            if (in_valid) begin
                s1_special <= special_c;
                s1_special_result <= special_result_c;
                s1_special_invalid <= special_invalid_c;
                s1_p_sign <= sp_c;
                s1_c_sign <= sc_c;
                s1_p_sig <= prod_c;
                s1_c_sig <= sig_c_c;
                s1_p_scale <= p_scale_i;
                s1_c_scale <= c_scale_i;
                s1_rnd <= rnd_mode;
            end

            if (s1_valid) begin
                s2_special <= s1_special;
                s2_special_result <= s1_special_result;
                s2_special_invalid <= s1_special_invalid;
                s2_sign <= sign2;
                s2_mag <= mag2;
                s2_sticky <= sticky2;
                s2_w_scale <= w_scale2i;
                s2_rnd <= s1_rnd;
            end

            if (s2_valid) begin
                s3_result <= result3_c;
                s3_invalid <= invalid3_c;
                s3_overflow <= overflow3_c;
                s3_underflow <= underflow3_c;
                s3_inexact <= inexact3_c;
            end
        end
    end

endmodule
