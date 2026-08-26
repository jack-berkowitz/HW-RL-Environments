// =============================================================================
// fp32_fma_ii1
// =============================================================================

`timescale 1ns/1ps

module fp32_fma_ii1 (
    input  logic        clk,
    input  logic        rst_n,

    // ---- operand input ------------------------------------------------------
    input  logic        in_valid,
    output logic        in_ready,
    input  logic [31:0] a,
    input  logic [31:0] b,
    input  logic [31:0] c,
    input  logic [2:0]  rnd_mode,

    // ---- result output ------------------------------------------------------
    output logic        out_valid,
    input  logic        out_ready,
    output logic [31:0] result,
    output logic        flag_invalid,
    output logic        flag_overflow,
    output logic        flag_underflow,
    output logic        flag_inexact
);

    // =========================================================================
    // Pipeline Control
    // =========================================================================
    logic v1, v2, v3;
    logic advance_1, advance_2, advance_3;

    assign advance_3 = out_ready || !v3;
    assign advance_2 = advance_3 || !v2;
    assign advance_1 = advance_2 || !v1;

    assign in_ready  = advance_1;
    assign out_valid = v3;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            v1 <= 1'b0;
            v2 <= 1'b0;
            v3 <= 1'b0;
        end else begin
            if (advance_1) v1 <= in_valid;
            if (advance_2) v2 <= v1;
            if (advance_3) v3 <= v2;
        end
    end

    // =========================================================================
    // Stage 1: Decode, Multiply, Align
    // =========================================================================
    logic a_sign, b_sign, c_sign;
    logic [7:0] a_exp_raw, b_exp_raw, c_exp_raw;
    logic [22:0] a_frac, b_frac, c_frac;

    assign {a_sign, a_exp_raw, a_frac} = a;
    assign {b_sign, b_exp_raw, b_frac} = b;
    assign {c_sign, c_exp_raw, c_frac} = c;

    logic a_is_zero, a_is_sub, a_is_inf, a_is_nan, a_is_snan;
    assign a_is_zero = (a_exp_raw == 8'd0) && (a_frac == 23'd0);
    assign a_is_sub  = (a_exp_raw == 8'd0) && (a_frac != 23'd0);
    assign a_is_inf  = (a_exp_raw == 8'd255) && (a_frac == 23'd0);
    assign a_is_nan  = (a_exp_raw == 8'd255) && (a_frac != 23'd0);
    assign a_is_snan = a_is_nan && (a_frac[22] == 1'b0);

    logic b_is_zero, b_is_sub, b_is_inf, b_is_nan, b_is_snan;
    assign b_is_zero = (b_exp_raw == 8'd0) && (b_frac == 23'd0);
    assign b_is_sub  = (b_exp_raw == 8'd0) && (b_frac != 23'd0);
    assign b_is_inf  = (b_exp_raw == 8'd255) && (b_frac == 23'd0);
    assign b_is_nan  = (b_exp_raw == 8'd255) && (b_frac != 23'd0);
    assign b_is_snan = b_is_nan && (b_frac[22] == 1'b0);

    logic c_is_zero, c_is_sub, c_is_inf, c_is_nan, c_is_snan;
    assign c_is_zero = (c_exp_raw == 8'd0) && (c_frac == 23'd0);
    assign c_is_sub  = (c_exp_raw == 8'd0) && (c_frac != 23'd0);
    assign c_is_inf  = (c_exp_raw == 8'd255) && (c_frac == 23'd0);
    assign c_is_nan  = (c_exp_raw == 8'd255) && (c_frac != 23'd0);
    assign c_is_snan = c_is_nan && (c_frac[22] == 1'b0);

    logic p_sign;
    assign p_sign = a_sign ^ b_sign;

    logic [23:0] a_man, b_man, c_man;
    assign a_man = a_is_zero ? 24'd0 : (a_is_sub ? {1'b0, a_frac} : {1'b1, a_frac});
    assign b_man = b_is_zero ? 24'd0 : (b_is_sub ? {1'b0, b_frac} : {1'b1, b_frac});
    assign c_man = c_is_zero ? 24'd0 : (c_is_sub ? {1'b0, c_frac} : {1'b1, c_frac});

    logic signed [9:0] a_exp, b_exp, c_exp;
    assign a_exp = (a_is_zero || a_is_sub) ? -10'sd126 : ($signed({2'b0, a_exp_raw}) - 10'sd127);
    assign b_exp = (b_is_zero || b_is_sub) ? -10'sd126 : ($signed({2'b0, b_exp_raw}) - 10'sd127);
    assign c_exp = (c_is_zero || c_is_sub) ? -10'sd126 : ($signed({2'b0, c_exp_raw}) - 10'sd127);

    logic signed [9:0] E_p, E_c;
    assign E_p = a_exp + b_exp - 10'sd46;
    assign E_c = c_exp - 10'sd23;

    logic p_is_zero, p_is_inf;
    assign p_is_zero = a_is_zero || b_is_zero;
    assign p_is_inf  = (a_is_inf && !b_is_zero) || (b_is_inf && !a_is_zero);

    logic is_invalid_d1, is_nan_d1, is_inf_d1, inf_sign_d1;
    assign is_invalid_d1 = a_is_snan || b_is_snan || c_is_snan ||
                           (a_is_inf && b_is_zero) || (a_is_zero && b_is_inf) ||
                           (p_is_inf && c_is_inf && (p_sign != c_sign));
    assign is_nan_d1 = a_is_nan || b_is_nan || c_is_nan || is_invalid_d1;
    assign is_inf_d1 = p_is_inf || c_is_inf;
    assign inf_sign_d1 = p_is_inf ? p_sign : c_sign;

    logic signed [9:0] eff_weight_p, eff_weight_c, W_max_d1;
    assign eff_weight_p = p_is_zero ? -10'sd300 : (E_p + 10'sd47);
    assign eff_weight_c = c_is_zero ? -10'sd300 : (E_c + 10'sd23);
    assign W_max_d1 = (eff_weight_p > eff_weight_c) ? eff_weight_p : eff_weight_c;

    logic signed [10:0] W_max_11, eff_weight_p_11, eff_weight_c_11;
    assign W_max_11 = W_max_d1;
    assign eff_weight_p_11 = eff_weight_p;
    assign eff_weight_c_11 = eff_weight_c;

    logic signed [10:0] shift_p_raw, shift_c_raw;
    assign shift_p_raw = W_max_11 - eff_weight_p_11;
    assign shift_c_raw = W_max_11 - eff_weight_c_11;

    logic [7:0] shift_p_capped, shift_c_capped;
    assign shift_p_capped = (shift_p_raw > 11'sd81) ? 8'd81 : shift_p_raw[7:0];
    assign shift_c_capped = (shift_c_raw > 11'sd81) ? 8'd81 : shift_c_raw[7:0];

    logic [47:0] p_man_mult;
    assign p_man_mult = a_man * b_man;

    logic [79:0] p_val_wide, c_val_wide;
    assign p_val_wide = {2'b0, p_man_mult, 30'b0};
    assign c_val_wide = {2'b0, c_man, 54'b0};

    logic [160:0] p_shifted_full, c_shifted_full;
    assign p_shifted_full = {p_val_wide, 81'b0} >> shift_p_capped;
    assign c_shifted_full = {c_val_wide, 81'b0} >> shift_c_capped;

    logic [79:0] p_aligned, c_aligned;
    logic p_sticky, c_sticky;
    assign p_aligned = p_shifted_full[160:81];
    assign p_sticky  = (p_shifted_full[80:0] != 161'd0);
    assign c_aligned = c_shifted_full[160:81];
    assign c_sticky  = (c_shifted_full[80:0] != 161'd0);

    logic p_larger;
    assign p_larger = (p_aligned > c_aligned) || ((p_aligned == c_aligned) && (p_sticky >= c_sticky));

    logic [79:0] larger_val_d1, smaller_val_d1;
    logic smaller_sticky_d1, final_sign_d1, eff_sub_d1;
    assign larger_val_d1 = p_larger ? p_aligned : c_aligned;
    assign smaller_val_d1 = p_larger ? c_aligned : p_aligned;
    assign smaller_sticky_d1 = p_larger ? c_sticky : p_sticky;
    assign final_sign_d1 = p_larger ? p_sign : c_sign;
    assign eff_sub_d1 = (p_sign != c_sign);

    // Stage 1 Registers
    logic [79:0] larger_val_q1, smaller_val_q1;
    logic smaller_sticky_q1, final_sign_q1, eff_sub_q1;
    logic signed [9:0] W_max_q1;
    logic is_nan_q1, is_inf_q1, is_invalid_q1, inf_sign_q1;
    logic [2:0] rnd_mode_q1;

    always_ff @(posedge clk) begin
        if (advance_1 && in_valid) begin
            larger_val_q1     <= larger_val_d1;
            smaller_val_q1    <= smaller_val_d1;
            smaller_sticky_q1 <= smaller_sticky_d1;
            final_sign_q1     <= final_sign_d1;
            eff_sub_q1        <= eff_sub_d1;
            W_max_q1          <= W_max_d1;
            is_nan_q1         <= is_nan_d1;
            is_inf_q1         <= is_inf_d1;
            is_invalid_q1     <= is_invalid_d1;
            inf_sign_q1       <= inf_sign_d1;
            rnd_mode_q1       <= rnd_mode;
        end
    end

    // =========================================================================
    // Stage 2: Add & Leading Zero Count
    // =========================================================================
    logic [79:0] sum_val_d2;
    logic sum_sticky_d2;
    assign sum_val_d2 = eff_sub_q1 ? (larger_val_q1 - smaller_val_q1 - {79'd0, smaller_sticky_q1}) : (larger_val_q1 + smaller_val_q1);
    assign sum_sticky_d2 = smaller_sticky_q1;

    logic [6:0] lzc_d2;
    always_comb begin
        lzc_d2 = 7'd80;
        for (int i = 79; i >= 0; i--) begin
            if (sum_val_d2[i]) begin
                lzc_d2 = 7'd79 - 7'(i);
                break;
            end
        end
    end

    // Stage 2 Registers
    logic [79:0] sum_val_q2;
    logic sum_sticky_q2;
    logic [6:0] lzc_q2;
    logic final_sign_q2, eff_sub_q2;
    logic signed [9:0] W_max_q2;
    logic is_nan_q2, is_inf_q2, is_invalid_q2, inf_sign_q2;
    logic [2:0] rnd_mode_q2;

    always_ff @(posedge clk) begin
        if (advance_2 && v1) begin
            sum_val_q2     <= sum_val_d2;
            sum_sticky_q2  <= sum_sticky_d2;
            lzc_q2         <= lzc_d2;
            final_sign_q2  <= final_sign_q1;
            eff_sub_q2     <= eff_sub_q1;
            W_max_q2       <= W_max_q1;
            is_nan_q2      <= is_nan_q1;
            is_inf_q2      <= is_inf_q1;
            is_invalid_q2  <= is_invalid_q1;
            inf_sign_q2    <= inf_sign_q1;
            rnd_mode_q2    <= rnd_mode_q1;
        end
    end

    // =========================================================================
    // Stage 3: Normalize, Round, Pack
    // =========================================================================
    logic signed [11:0] W_max_ext;
    assign W_max_ext = W_max_q2;

    logic signed [11:0] lzc_signed;
    assign lzc_signed = {5'd0, lzc_q2};

    logic signed [11:0] norm_weight, target_weight, shift_left_amt;
    assign norm_weight = W_max_ext + 12'sd2 - lzc_signed;
    assign target_weight = (norm_weight > -12'sd126) ? norm_weight : -12'sd126;
    assign shift_left_amt = (W_max_ext + 12'sd2) - target_weight;

    logic [7:0] L_sh, R_sh;
    assign L_sh = (shift_left_amt > 12'sd0) ? shift_left_amt[7:0] : 8'd0;
    assign R_sh = (shift_left_amt < 12'sd0) ? (-shift_left_amt[7:0]) : 8'd0;

    logic [159:0] sum_val_r_full;
    assign sum_val_r_full = {sum_val_q2, 80'd0} >> R_sh;
    
    logic [79:0] sum_val_r;
    assign sum_val_r = sum_val_r_full[159:80];

    logic sum_sticky_r;
    assign sum_sticky_r = sum_sticky_q2 | (sum_val_r_full[79:0] != 160'd0);

    logic [79:0] sum_val_l;
    assign sum_val_l = sum_val_r << L_sh;

    logic [23:0] mantissa;
    logic guard, round, sticky;
    assign mantissa = sum_val_l[79:56];
    assign guard = sum_val_l[55];
    assign round = sum_val_l[54];
    assign sticky = (|sum_val_l[53:0]) | sum_sticky_r;

    logic is_exact_zero, sign_zero, out_sign;
    assign is_exact_zero = (sum_val_q2 == 80'd0) && !sum_sticky_q2;
    assign sign_zero = (rnd_mode_q2 == 3'b010) ? 1'b1 : 1'b0;
    assign out_sign = is_exact_zero ? (eff_sub_q2 ? sign_zero : final_sign_q2) : final_sign_q2;

    logic round_up;
    always_comb begin
        case (rnd_mode_q2)
            3'b000: round_up = guard & (round | sticky | mantissa[0]);
            3'b001: round_up = 1'b0;
            3'b010: round_up = out_sign & (guard | round | sticky);
            3'b011: round_up = ~out_sign & (guard | round | sticky);
            3'b100: round_up = guard;
            default: round_up = 1'b0;
        endcase
    end

    logic [24:0] mantissa_rounded;
    logic mantissa_overflow;
    logic [23:0] final_mantissa;
    logic signed [11:0] final_exp_adj, biased_exp;

    assign mantissa_rounded = {1'b0, mantissa} + {24'd0, round_up};
    assign mantissa_overflow = mantissa_rounded[24];
    assign final_mantissa = mantissa_overflow ? mantissa_rounded[24:1] : mantissa_rounded[23:0];
    
    assign final_exp_adj = target_weight + {11'd0, mantissa_overflow};
    assign biased_exp = final_exp_adj + 12'sd127;

    logic [31:0] result_d3;
    logic flag_overflow_d3, flag_inexact_d3, flag_underflow_d3;
    logic is_special;
    
    assign is_special = is_invalid_q2 || is_nan_q2 || is_inf_q2;

    always_comb begin
        if (is_special) begin
            if (is_invalid_q2 || is_nan_q2) result_d3 = 32'h7FC00000;
            else result_d3 = {inf_sign_q2, 8'hFF, 23'd0};
            flag_overflow_d3 = 1'b0;
            flag_inexact_d3 = 1'b0;
        end else if (is_exact_zero) begin
            result_d3 = {out_sign, 31'd0};
            flag_overflow_d3 = 1'b0;
            flag_inexact_d3 = 1'b0;
        end else if (biased_exp >= 12'sd255) begin
            logic max_normal;
            max_normal = (rnd_mode_q2 == 3'b001) ||
                         (rnd_mode_q2 == 3'b010 && !out_sign) ||
                         (rnd_mode_q2 == 3'b011 && out_sign);
            result_d3 = max_normal ? {out_sign, 8'hFE, 23'h7FFFFF} : {out_sign, 8'hFF, 23'd0};
            flag_overflow_d3 = 1'b1;
            flag_inexact_d3 = 1'b1;
        end else if (biased_exp <= 12'sd0) begin
            result_d3 = {out_sign, 8'h00, final_mantissa[22:0]};
            flag_overflow_d3 = 1'b0;
            flag_inexact_d3 = guard | round | sticky;
        end else begin
            result_d3 = {out_sign, biased_exp[7:0], final_mantissa[22:0]};
            flag_overflow_d3 = 1'b0;
            flag_inexact_d3 = guard | round | sticky;
        end
    end

    assign flag_underflow_d3 = !is_special && flag_inexact_d3 && (result_d3[30:23] == 8'd0) && !flag_overflow_d3;

    // Stage 3 Registers (Final Output)
    logic [31:0] result_q3;
    logic flag_invalid_q3, flag_overflow_q3, flag_underflow_q3, flag_inexact_q3;

    always_ff @(posedge clk) begin
        if (advance_3 && v2) begin
            result_q3         <= result_d3;
            flag_invalid_q3   <= is_invalid_q2;
            flag_overflow_q3  <= flag_overflow_d3;
            flag_underflow_q3 <= flag_underflow_d3;
            flag_inexact_q3   <= flag_inexact_d3;
        end
    end

    assign result         = result_q3;
    assign flag_invalid   = flag_invalid_q3;
    assign flag_overflow  = flag_overflow_q3;
    assign flag_underflow = flag_underflow_q3;
    assign flag_inexact   = flag_inexact_q3;

endmodule