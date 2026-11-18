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

    // ------------------------------------------------------------------------
    // Pipeline registers
    // ------------------------------------------------------------------------
    logic valid1, valid2, valid3;

    // Stage 1 registers
    logic        s1_is_special;
    logic [31:0] s1_special_result;
    logic [3:0]  s1_special_flags;
    logic [2:0]  s1_rnd_mode;
    logic        s1_sign_p, s1_sign_c;
    logic [47:0] s1_Mp;
    logic signed [9:0] s1_Ep;
    logic [23:0] s1_Mc;
    logic signed [9:0] s1_Ec;

    // Stage 2 registers
    logic        s2_is_special;
    logic [31:0] s2_special_result;
    logic [3:0]  s2_special_flags;
    logic [2:0]  s2_rnd_mode;
    logic        s2_sign_res;
    logic signed [9:0] s2_E_lead;
    logic [24:0] s2_Q;
    logic        s2_round_bit;
    logic        s2_sticky;
    logic        s2_inexact;
    logic        s2_zero_exact;

    // Stage 3 registers (final outputs)
    logic [31:0] result3;
    logic        flag_invalid3, flag_overflow3, flag_underflow3, flag_inexact3;

    // ------------------------------------------------------------------------
    // Handshake
    // ------------------------------------------------------------------------
    wire advance = ~valid3 | out_ready;
    assign in_ready = advance;

    assign out_valid      = valid3;
    assign result         = result3;
    assign flag_invalid   = flag_invalid3;
    assign flag_overflow  = flag_overflow3;
    assign flag_underflow = flag_underflow3;
    assign flag_inexact   = flag_inexact3;

    // ------------------------------------------------------------------------
    // Stage 1 combinational: unpack, special cases, multiply
    // ------------------------------------------------------------------------
    logic        sa, sb, sc;
    logic [7:0]  ea, eb, ec;
    logic [22:0] fa, fb, fc;
    logic        is_nan_a, is_nan_b, is_nan_c;
    logic        is_snan_a, is_snan_b, is_snan_c;
    logic        is_inf_a, is_inf_b, is_inf_c;
    logic        is_zero_a, is_zero_b, is_zero_c;
    logic        invalid_op;
    logic        any_nan, any_snan;
    logic        product_inf;
    logic [31:0] special_result;
    logic [3:0]  special_flags;
    logic        is_special;
    logic        sign_p, sign_c;
    logic [23:0] M_a, M_b, M_c;
    logic signed [9:0] E_a, E_b, E_c;
    logic [47:0] Mp;
    logic signed [9:0] Ep;
    logic [23:0] Mc;
    logic signed [9:0] Ec;
    logic        sign_zero;

    always_comb begin
        // Unpack
        sa = a[31]; ea = a[30:23]; fa = a[22:0];
        sb = b[31]; eb = b[30:23]; fb = b[22:0];
        sc = c[31]; ec = c[30:23]; fc = c[22:0];

        is_nan_a = (ea == 8'hFF) && (fa != 0);
        is_nan_b = (eb == 8'hFF) && (fb != 0);
        is_nan_c = (ec == 8'hFF) && (fc != 0);
        is_snan_a = is_nan_a && !fa[22];
        is_snan_b = is_nan_b && !fb[22];
        is_snan_c = is_nan_c && !fc[22];
        is_inf_a = (ea == 8'hFF) && (fa == 0);
        is_inf_b = (eb == 8'hFF) && (fb == 0);
        is_inf_c = (ec == 8'hFF) && (fc == 0);
        is_zero_a = (ea == 0) && (fa == 0);
        is_zero_b = (eb == 0) && (fb == 0);
        is_zero_c = (ec == 0) && (fc == 0);

        any_nan = is_nan_a | is_nan_b | is_nan_c;
        any_snan = is_snan_a | is_snan_b | is_snan_c;

        product_inf = (is_inf_a & !is_zero_b & !is_nan_b) |
                      (is_inf_b & !is_zero_a & !is_nan_a);

        invalid_op = (is_inf_a & is_zero_b) | (is_zero_a & is_inf_b) |
                     (product_inf & is_inf_c & ((sa^sb) != sc));

        // Defaults
        is_special      = 1'b0;
        special_result  = 32'b0;
        special_flags   = 4'b0;
        sign_p          = sa ^ sb;
        sign_c          = sc;
        M_a             = 24'b0;
        M_b             = 24'b0;
        M_c             = 24'b0;
        E_a             = 10'sd0;
        E_b             = 10'sd0;
        E_c             = 10'sd0;
        Mp              = 48'b0;
        Ep              = 10'sd0;
        Mc              = 24'b0;
        Ec              = 10'sd0;

        if (any_nan || invalid_op) begin
            is_special     = 1'b1;
            special_result = 32'h7FC00000;
            special_flags  = {any_snan | invalid_op, 3'b0};
        end else if (product_inf) begin
            is_special     = 1'b1;
            special_result = {sa^sb, 8'hFF, 23'd0};
            special_flags  = 4'b0;
        end else if (is_inf_c) begin
            is_special     = 1'b1;
            special_result = c;
            special_flags  = 4'b0;
        end else if ((is_zero_a | is_zero_b) && is_zero_c) begin
            is_special     = 1'b1;
            sign_zero      = (sign_p == sign_c) ? sign_p : (rnd_mode == 3'd2);
            special_result = {sign_zero, 31'b0};
            special_flags  = 4'b0;
        end else begin
            // Non-special: unpack significands and exponents
            if (ea == 0) begin
                M_a = {1'b0, fa};
                E_a = -10'sd149;
            end else begin
                M_a = {1'b1, fa};
                E_a = $signed({2'b0, ea}) - 10'sd150;
            end

            if (eb == 0) begin
                M_b = {1'b0, fb};
                E_b = -10'sd149;
            end else begin
                M_b = {1'b1, fb};
                E_b = $signed({2'b0, eb}) - 10'sd150;
            end

            if (ec == 0) begin
                M_c = {1'b0, fc};
                E_c = -10'sd149;
            end else begin
                M_c = {1'b1, fc};
                E_c = $signed({2'b0, ec}) - 10'sd150;
            end

            Mp = M_a * M_b;
            Ep = E_a + E_b;
            Mc = M_c;
            Ec = E_c;

            if (Mp == 0) begin
                Ep = Ec;
                sign_p = 1'b0;
            end
            if (Mc == 0) begin
                Ec = Ep;
                sign_c = 1'b0;
            end
        end
    end

    // Stage 1 registers
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            valid1 <= 1'b0;
        end else if (advance) begin
            valid1 <= in_valid;
            if (in_valid) begin
                s1_is_special     <= is_special;
                s1_special_result <= special_result;
                s1_special_flags  <= special_flags;
                s1_rnd_mode       <= rnd_mode;
                s1_sign_p         <= sign_p;
                s1_sign_c         <= sign_c;
                s1_Mp             <= Mp;
                s1_Ep             <= Ep;
                s1_Mc             <= Mc;
                s1_Ec             <= Ec;
            end
        end
    end

    // ------------------------------------------------------------------------
    // Stage 2 combinational: align, add, normalize, compute Q and sticky
    // ------------------------------------------------------------------------
    logic signed [9:0] Emax, E;
    logic signed [9:0] shift_p, shift_c;
    logic [95:0] P_mag, C_mag;
    logic        st_p, st_c, sticky, small_sign;
    logic [95:0] sum_mag;
    logic [96:0] sum_97;
    logic        carry;
    logic        sign_S;
    logic [95:0] mag;
    logic        sticky_out;
    logic        sign_res;
    logic [6:0]  L;
    logic signed [9:0] E_lead;
    logic signed [9:0] E_round_lsb;
    logic [9:0]  shift;
    logic [95:0] Q_full;
    logic [24:0] Q;
    logic        round_bit;
    logic        sticky_bits;
    logic        inexact;
    logic        zero_exact;
    integer      i;
    logic signed [9:0] k_p, k_c;
    logic [95:0] larger, smaller, diff;
    logic        same_sign;

    always_comb begin
        // Defaults
        Emax        = 10'sd0;
        E           = 10'sd0;
        shift_p     = 10'sd0;
        shift_c     = 10'sd0;
        P_mag       = 96'b0;
        C_mag       = 96'b0;
        st_p        = 1'b0;
        st_c        = 1'b0;
        sticky      = 1'b0;
        small_sign  = 1'b0;
        sum_mag     = 96'b0;
        sum_97      = 97'b0;
        carry       = 1'b0;
        sign_S      = 1'b0;
        mag         = 96'b0;
        sticky_out  = 1'b0;
        sign_res    = 1'b0;
        L           = 7'd0;
        E_lead      = 10'sd0;
        E_round_lsb = 10'sd0;
        shift       = 10'd0;
        Q_full      = 96'b0;
        Q           = 25'd0;
        round_bit   = 1'b0;
        sticky_bits = 1'b0;
        inexact     = 1'b0;
        zero_exact  = 1'b0;
        larger      = 96'b0;
        smaller     = 96'b0;
        diff        = 96'b0;
        same_sign   = 1'b0;

        if (s1_is_special) begin
            // pass through, no arithmetic
        end else begin
            Emax    = (s1_Ep > s1_Ec) ? s1_Ep : s1_Ec;
            E       = Emax - 10'sd48;
            shift_p = s1_Ep - E;
            shift_c = s1_Ec - E;

            // Product alignment
            if (shift_p >= 0) begin
                P_mag = {48'b0, s1_Mp} << shift_p;
                st_p  = 1'b0;
            end else begin
                k_p = -shift_p;
                if (k_p >= 48) begin
                    P_mag = 96'b0;
                    st_p  = (s1_Mp != 0);
                end else begin
                    P_mag = {48'b0, s1_Mp} >> k_p;
                    st_p  = (s1_Mp & ((48'd1 << k_p) - 1)) != 0;
                end
            end

            // C alignment
            if (shift_c >= 0) begin
                C_mag = {72'b0, s1_Mc} << shift_c;
                st_c  = 1'b0;
            end else begin
                k_c = -shift_c;
                if (k_c >= 24) begin
                    C_mag = 96'b0;
                    st_c  = (s1_Mc != 0);
                end else begin
                    C_mag = {72'b0, s1_Mc} >> k_c;
                    st_c  = (s1_Mc & ((24'd1 << k_c) - 1)) != 0;
                end
            end

            sticky     = st_p | st_c;
            small_sign = st_p ? s1_sign_p : s1_sign_c;
            same_sign  = (s1_sign_p == s1_sign_c);

            if (same_sign) begin
                sum_97   = {1'b0, P_mag} + {1'b0, C_mag};
                carry    = sum_97[96];
                sum_mag  = sum_97[95:0];
                sign_S   = s1_sign_p;
                if (carry) begin
                    mag        = {carry, sum_97[95:1]};
                    sticky_out = sticky | sum_97[0];
                    E          = E + 10'sd1;
                end else begin
                    mag        = sum_mag;
                    sticky_out = sticky;
                end
                sign_res = sign_S;
            end else begin
                if (P_mag >= C_mag) begin
                    larger  = P_mag;
                    smaller = C_mag;
                    sign_S  = s1_sign_p;
                end else begin
                    larger  = C_mag;
                    smaller = P_mag;
                    sign_S  = s1_sign_c;
                end
                diff = larger - smaller;
                if (sticky) begin
                    if (diff == 0) begin
                        mag        = 96'b0;
                        sticky_out = 1'b1;
                        sign_res   = small_sign;
                    end else begin
                        mag        = diff - 1;
                        sticky_out = 1'b1;
                        sign_res   = sign_S;
                    end
                end else begin
                    mag        = diff;
                    sticky_out = 1'b0;
                    sign_res   = sign_S;
                end
            end

            if (mag == 0 && sticky_out == 0) begin
                zero_exact = 1'b1;
                sign_res   = (s1_rnd_mode == 3'd2) ? 1'b1 : 1'b0;
            end else begin
                zero_exact = 1'b0;
                // Leading bit position
                L = 7'd0;
                for (i = 0; i < 96; i = i + 1) begin
                    if (mag[i]) L = i[6:0];
                end
                E_lead = E + L;
                if (E_lead < -10'sd126) begin
                    E_round_lsb = -10'sd149;
                end else begin
                    E_round_lsb = E_lead - 10'sd23;
                end
                shift = E_round_lsb - E;

                // Compute Q, round_bit, sticky_bits
                Q_full      = 96'b0;
                round_bit   = 1'b0;
                sticky_bits = sticky_out;
                if (shift >= 10'd96) begin
                    Q_full      = 96'b0;
                    round_bit   = (shift == 10'd96) ? mag[95] : 1'b0;
                    sticky_bits = sticky_out | (mag != 0);
                end else if (shift > 0) begin
                    Q_full    = mag >> shift;
                    round_bit = mag[shift-1];
                    for (i = 0; i < 96; i = i + 1) begin
                        if (i < (shift - 1) && mag[i]) sticky_bits = 1'b1;
                    end
                end else begin
                    Q_full    = mag;
                    round_bit = 1'b0;
                end
                Q       = Q_full[24:0];
                inexact = round_bit | sticky_bits;
            end
        end
    end

    // Stage 2 registers
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            valid2 <= 1'b0;
        end else if (advance) begin
            valid2 <= valid1;
            if (valid1) begin
                s2_is_special     <= s1_is_special;
                s2_special_result <= s1_special_result;
                s2_special_flags  <= s1_special_flags;
                s2_rnd_mode       <= s1_rnd_mode;
                s2_sign_res       <= sign_res;
                s2_E_lead         <= E_lead;
                s2_Q              <= Q;
                s2_round_bit      <= round_bit;
                s2_sticky         <= sticky_bits;
                s2_inexact        <= inexact;
                s2_zero_exact     <= zero_exact;
            end
        end
    end

    // ------------------------------------------------------------------------
    // Stage 3 combinational: rounding, final result and flags
    // ------------------------------------------------------------------------
    logic [24:0] Q_final;
    logic        round_up;
    logic        lsb;
    logic [7:0]  exp_field;
    logic [22:0] frac;
    logic        overflow, underflow, inexact_final;
    logic [31:0] result_final;
    logic [3:0]  flags_final;
    logic signed [9:0] E_lead_final;

    always_comb begin
        Q_final       = 25'd0;
        round_up      = 1'b0;
        lsb           = 1'b0;
        exp_field     = 8'd0;
        frac          = 23'd0;
        overflow      = 1'b0;
        underflow     = 1'b0;
        inexact_final = 1'b0;
        result_final  = 32'b0;
        flags_final   = 4'b0;
        E_lead_final  = 10'sd0;

        if (s2_is_special) begin
            result_final = s2_special_result;
            flags_final  = s2_special_flags;
        end else if (s2_zero_exact) begin
            result_final = {s2_sign_res, 31'b0};
            flags_final  = 4'b0;
        end else begin
            lsb = s2_Q[0];
            case (s2_rnd_mode)
                3'd0: round_up = s2_round_bit && (s2_sticky || lsb);          // RNE
                3'd1: round_up = 1'b0;                                        // RTZ
                3'd2: round_up = s2_sign_res && (s2_round_bit || s2_sticky);  // RDN
                3'd3: round_up = !s2_sign_res && (s2_round_bit || s2_sticky); // RUP
                3'd4: round_up = s2_round_bit;                                // RMM
                default: round_up = 1'b0;
            endcase
            Q_final       = s2_Q + round_up;
            inexact_final = s2_inexact;

            if (s2_E_lead < -10'sd126) begin
                // Subnormal result
                if (Q_final >= (25'd1 << 23)) begin
                    exp_field = 8'd1;
                    frac      = 23'd0;
                    underflow = 1'b0;
                end else begin
                    exp_field = 8'd0;
                    frac      = Q_final[22:0];
                    underflow = inexact_final;
                end
                overflow     = 1'b0;
                result_final = {s2_sign_res, exp_field, frac};
            end else begin
                // Normal result
                E_lead_final = s2_E_lead;
                if (Q_final == (25'd1 << 24)) begin
                    Q_final      = 25'd1 << 23;
                    E_lead_final = E_lead_final + 1;
                end
                exp_field = E_lead_final + 127;
                if (exp_field >= 255) begin
                    overflow      = 1'b1;
                    inexact_final = 1'b1;
                    underflow     = 1'b0;
                    case (s2_rnd_mode)
                        3'd0: result_final = {s2_sign_res, 8'hFF, 23'd0};
                        3'd1: result_final = {s2_sign_res, 8'hFE, 23'h7FFFFF};
                        3'd2: result_final = s2_sign_res ? {1'b1, 8'hFF, 23'd0}
                                                         : {1'b0, 8'hFE, 23'h7FFFFF};
                        3'd3: result_final = s2_sign_res ? {1'b1, 8'hFE, 23'h7FFFFF}
                                                         : {1'b0, 8'hFF, 23'd0};
                        3'd4: result_final = {s2_sign_res, 8'hFF, 23'd0};
                        default: result_final = {s2_sign_res, 8'hFF, 23'd0};
                    endcase
                end else begin
                    overflow     = 1'b0;
                    underflow    = 1'b0;
                    frac         = Q_final[22:0];
                    result_final = {s2_sign_res, exp_field, frac};
                end
            end
            flags_final = {1'b0, overflow, underflow, inexact_final};
        end
    end

    // Stage 3 registers (final output)
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            valid3 <= 1'b0;
        end else if (advance) begin
            valid3 <= valid2;
            if (valid2) begin
                result3         <= result_final;
                flag_invalid3   <= flags_final[3];
                flag_overflow3  <= flags_final[2];
                flag_underflow3 <= flags_final[1];
                flag_inexact3   <= flags_final[0];
            end
        end
    end

endmodule
