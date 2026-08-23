// =============================================================================
// fp32_fma_ii1  --  IMPLEMENTATION
// =============================================================================

`timescale 1ns/1ps

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

    // -------------------------------------------------------------------------
    // Helper Functions
    // -------------------------------------------------------------------------
    function automatic logic [4:0] lzcnt24(input logic [23:0] val);
        for (int i = 23; i >= 0; i--) begin
            if (val[i]) return 5'(23 - i);
        end
        return 5'd24;
    endfunction

    function automatic logic [6:0] lzcnt77(input logic [76:0] val);
        for (int i = 76; i >= 0; i--) begin
            if (val[i]) return 7'(76 - i);
        end
        return 7'd77;
    endfunction

    // -------------------------------------------------------------------------
    // Pipeline Control (3 Stages, II=1)
    // -------------------------------------------------------------------------
    logic valid_r1, valid_r2, valid_r3;
    logic ready_r1, ready_r2;

    assign in_ready = !valid_r1 || ready_r1;
    assign ready_r1 = !valid_r2 || ready_r2;
    assign ready_r2 = !valid_r3 || out_ready;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_r1 <= 0;
            valid_r2 <= 0;
            valid_r3 <= 0;
        end else begin
            if (in_ready) valid_r1 <= in_valid;
            if (ready_r1) valid_r2 <= valid_r1;
            if (ready_r2) valid_r3 <= valid_r2;
        end
    end

    wire en_r1 = in_ready && in_valid;
    wire en_r2 = ready_r1 && valid_r1;
    wire en_r3 = ready_r2 && valid_r2;

    assign out_valid = valid_r3;

    // -------------------------------------------------------------------------
    // STAGE 1: Unpack, Multiply, Align
    // -------------------------------------------------------------------------
    logic [74:0] r1_P_shift, r1_C_shift;
    logic        r1_P_sticky, r1_C_sticky;
    logic signed [12:0] r1_E_max;
    logic        r1_S_P, r1_S_C;
    logic        r1_is_invalid, r1_is_nan_res, r1_is_inf_res, r1_inf_sign;
    logic [2:0]  r1_rnd_mode;
    logic        r1_P_is_zero, r1_C_is_zero;

    always_ff @(posedge clk) begin
        if (en_r1) begin
            logic A_sign, B_sign, C_sign;
            logic [7:0] A_exp_field, B_exp_field, C_exp_field;
            logic [22:0] A_mant_field, B_mant_field, C_mant_field;

            A_sign = a[31]; A_exp_field = a[30:23]; A_mant_field = a[22:0];
            B_sign = b[31]; B_exp_field = b[30:23]; B_mant_field = b[22:0];
            C_sign = c[31]; C_exp_field = c[30:23]; C_mant_field = c[22:0];

            logic A_is_zero, A_is_subnormal, A_is_inf, A_is_nan, A_is_snan;
            A_is_zero      = (A_exp_field == 0) && (A_mant_field == 0);
            A_is_subnormal = (A_exp_field == 0) && (A_mant_field != 0);
            A_is_inf       = (A_exp_field == 255) && (A_mant_field == 0);
            A_is_nan       = (A_exp_field == 255) && (A_mant_field != 0);
            A_is_snan      = A_is_nan && (A_mant_field[22] == 0);

            logic B_is_zero, B_is_subnormal, B_is_inf, B_is_nan, B_is_snan;
            B_is_zero      = (B_exp_field == 0) && (B_mant_field == 0);
            B_is_subnormal = (B_exp_field == 0) && (B_mant_field != 0);
            B_is_inf       = (B_exp_field == 255) && (B_mant_field == 0);
            B_is_nan       = (B_exp_field == 255) && (B_mant_field != 0);
            B_is_snan      = B_is_nan && (B_mant_field[22] == 0);

            logic C_is_zero, C_is_subnormal, C_is_inf, C_is_nan, C_is_snan;
            C_is_zero      = (C_exp_field == 0) && (C_mant_field == 0);
            C_is_subnormal = (C_exp_field == 0) && (C_mant_field != 0);
            C_is_inf       = (C_exp_field == 255) && (C_mant_field == 0);
            C_is_nan       = (C_exp_field == 255) && (C_mant_field != 0);
            C_is_snan      = C_is_nan && (C_mant_field[22] == 0);

            logic [4:0] A_lza = lzcnt24({A_mant_field, 1'b0});
            logic [4:0] B_lza = lzcnt24({B_mant_field, 1'b0});
            logic [4:0] C_lza = lzcnt24({C_mant_field, 1'b0});

            logic signed [12:0] A_exp_unb, B_exp_unb, C_exp_unb;
            logic [23:0] A_norm_mant, B_norm_mant, C_norm_mant;

            A_exp_unb   = A_is_zero ? -13'd1000 : (A_is_subnormal ? -13'd126 - {8'b0, A_lza} : {5'b0, A_exp_field} - 13'd127);
            A_norm_mant = A_is_zero ? 24'b0 : (A_is_subnormal ? {A_mant_field, 1'b0} << A_lza : {1'b1, A_mant_field});

            B_exp_unb   = B_is_zero ? -13'd1000 : (B_is_subnormal ? -13'd126 - {8'b0, B_lza} : {5'b0, B_exp_field} - 13'd127);
            B_norm_mant = B_is_zero ? 24'b0 : (B_is_subnormal ? {B_mant_field, 1'b0} << B_lza : {1'b1, B_mant_field});

            C_exp_unb   = C_is_zero ? -13'd1000 : (C_is_subnormal ? -13'd126 - {8'b0, C_lza} : {5'b0, C_exp_field} - 13'd127);
            C_norm_mant = C_is_zero ? 24'b0 : (C_is_subnormal ? {C_mant_field, 1'b0} << C_lza : {1'b1, C_mant_field});

            logic [47:0] M_P_full = A_norm_mant * B_norm_mant;
            logic signed [12:0] E_P_unb = A_exp_unb + B_exp_unb;

            logic [74:0] V_P = {2'b0, M_P_full, 25'b0};
            logic [74:0] V_C = {3'b0, C_norm_mant, 48'b0};

            logic signed [13:0] E_diff = E_P_unb - C_exp_unb;
            logic [13:0] shift_amt;
            logic [74:0] ones_75 = {75{1'b1}};

            if (E_diff >= 0) begin
                shift_amt = E_diff;
                r1_E_max  = E_P_unb;
                r1_P_shift = V_P;
                r1_P_sticky = 0;
                
                if (shift_amt >= 75) begin
                    r1_C_shift = 0;
                    r1_C_sticky = (V_C != 0);
                end else begin
                    r1_C_shift = V_C >> shift_amt;
                    r1_C_sticky = |(V_C & ~(ones_75 << shift_amt));
                end
            end else begin
                shift_amt = -E_diff;
                r1_E_max  = C_exp_unb;
                r1_C_shift = V_C;
                r1_C_sticky = 0;

                if (shift_amt >= 75) begin
                    r1_P_shift = 0;
                    r1_P_sticky = (V_P != 0);
                end else begin
                    r1_P_shift = V_P >> shift_amt;
                    r1_P_sticky = |(V_P & ~(ones_75 << shift_amt));
                end
            end

            logic P_is_zero = A_is_zero || B_is_zero;
            logic P_is_inf  = A_is_inf || B_is_inf;
            logic P_is_nan  = A_is_nan || B_is_nan;
            logic P_sign    = A_sign ^ B_sign;

            r1_S_P = P_sign;
            r1_S_C = C_sign;

            logic is_inv_mul = (A_is_zero && B_is_inf) || (A_is_inf && B_is_zero);
            logic is_inv_add = P_is_inf && C_is_inf && (P_sign != C_sign);

            r1_is_invalid = A_is_snan || B_is_snan || C_is_snan || is_inv_mul || is_inv_add;
            r1_is_nan_res = P_is_nan || C_is_nan || is_inv_mul || is_inv_add;
            r1_is_inf_res = (P_is_inf || C_is_inf) && !r1_is_nan_res;
            r1_inf_sign   = P_is_inf ? P_sign : C_sign;

            r1_P_is_zero  = P_is_zero;
            r1_C_is_zero  = C_is_zero;
            r1_rnd_mode   = rnd_mode;
        end
    end

    // -------------------------------------------------------------------------
    // STAGE 2: Add / Subtract, Sign & LZA
    // -------------------------------------------------------------------------
    logic [76:0]        r2_sum;
    logic [6:0]         r2_sum_lza;
    logic signed [12:0] r2_E_max;
    logic               r2_S_res;
    logic               r2_is_invalid, r2_is_nan_res, r2_is_inf_res, r2_inf_sign;
    logic               r2_exact_zero_sum;
    logic [2:0]         r2_rnd_mode;

    always_ff @(posedge clk) begin
        if (en_r2) begin
            logic [75:0] P_val = {r1_P_shift, r1_P_sticky};
            logic [75:0] C_val = {r1_C_shift, r1_C_sticky};
            logic same_sign = (r1_S_P == r1_S_C);
            logic [76:0] sum;
            logic S_res;
            logic exact_zero;

            if (same_sign) begin
                sum = P_val + C_val;
                S_res = r1_S_P;
                exact_zero = (sum == 0);
            end else begin
                if (P_val >= C_val) begin
                    sum = P_val - C_val;
                    S_res = r1_S_P;
                    exact_zero = (sum == 0);
                end else begin
                    sum = C_val - P_val;
                    S_res = r1_S_C;
                    exact_zero = (sum == 0);
                end
            end

            if (exact_zero) begin
                if (same_sign) r2_S_res = r1_S_P;
                else r2_S_res = (r1_rnd_mode == 3'd2) ? 1'b1 : 1'b0;
            end else begin
                r2_S_res = S_res;
            end

            r2_sum            = sum;
            r2_sum_lza        = lzcnt77(sum);
            r2_exact_zero_sum = exact_zero;
            r2_E_max          = r1_E_max;
            r2_is_invalid     = r1_is_invalid;
            r2_is_nan_res     = r1_is_nan_res;
            r2_is_inf_res     = r1_is_inf_res;
            r2_inf_sign       = r1_inf_sign;
            r2_rnd_mode       = r1_rnd_mode;
        end
    end

    // -------------------------------------------------------------------------
    // STAGE 3: Normalize, Round, Pack -> Output Registers
    // -------------------------------------------------------------------------
    logic [31:0] r3_result;
    logic        r3_invalid, r3_overflow, r3_underflow, r3_inexact;

    always_ff @(posedge clk) begin
        if (en_r3) begin
            logic [76:0] norm_sum = r2_sum << r2_sum_lza;
            logic signed [13:0] E_norm = r2_E_max + (76 - {7'b0, r2_sum_lza}) - 14'd71;
            logic signed [13:0] E_bias = E_norm + 14'd127;
            
            logic [76:0] shifted_sum;
            logic [7:0]  final_exp;
            logic        extra_sticky;
            logic [76:0] ones_77 = {77{1'b1}};

            if (r2_exact_zero_sum) begin
                shifted_sum = 0;
                final_exp = 0;
                extra_sticky = 0;
            end else if (E_bias <= 0) begin
                logic [13:0] shift_right_amt = 14'd1 - E_bias;
                if (shift_right_amt >= 77) begin
                    shifted_sum = 0;
                    extra_sticky = (norm_sum != 0);
                end else begin
                    shifted_sum = norm_sum >> shift_right_amt;
                    extra_sticky = |(norm_sum & ~(ones_77 << shift_right_amt));
                end
                final_exp = 0;
            end else begin
                shifted_sum = norm_sum;
                final_exp = E_bias[7:0];
                extra_sticky = 0;
            end

            logic [22:0] unrounded_frac = shifted_sum[75:53];
            logic guard_bit  = shifted_sum[52];
            logic round_bit  = shifted_sum[51];
            logic sticky_bit = (|shifted_sum[50:0]) | extra_sticky;
            logic LSB        = unrounded_frac[0];
            logic round_up;

            case (r2_rnd_mode)
                3'd0: round_up = guard_bit & (round_bit | sticky_bit | LSB);
                3'd1: round_up = 1'b0;
                3'd2: round_up = r2_S_res & (guard_bit | round_bit | sticky_bit);
                3'd3: round_up = (~r2_S_res) & (guard_bit | round_bit | sticky_bit);
                3'd4: round_up = guard_bit;
                default: round_up = 1'b0;
            endcase

            logic [23:0] pre_round_mant = {shifted_sum[76], unrounded_frac};
            logic [24:0] post_round_mant = {1'b0, pre_round_mant} + {24'b0, round_up};

            logic [22:0] final_mant;
            logic [7:0]  packed_exp;
            logic        overflow;
            logic        inexact;

            overflow   = 0;
            inexact    = (guard_bit | round_bit | sticky_bit) != 0;
            packed_exp = final_exp;
            final_mant = post_round_mant[22:0];

            if (post_round_mant[24]) begin
                packed_exp = final_exp + 1;
                final_mant = 0;
            end else if (final_exp == 0 && post_round_mant[23]) begin
                packed_exp = 1;
                final_mant = 0;
            end

            if (packed_exp >= 255) begin
                overflow = 1;
                inexact = 1;
                case (r2_rnd_mode)
                    3'd0: begin packed_exp = 255; final_mant = 0; end
                    3'd1: begin packed_exp = 254; final_mant = {23{1'b1}}; end
                    3'd2: begin 
                        if (r2_S_res) begin packed_exp = 255; final_mant = 0; end
                        else begin packed_exp = 254; final_mant = {23{1'b1}}; end
                    end
                    3'd3: begin 
                        if (!r2_S_res) begin packed_exp = 255; final_mant = 0; end
                        else begin packed_exp = 254; final_mant = {23{1'b1}}; end
                    end
                    3'd4: begin packed_exp = 255; final_mant = 0; end
                    default: begin packed_exp = 255; final_mant = 0; end
                endcase
            end

            logic underflow = inexact & (packed_exp == 0);

            if (r2_is_nan_res) begin
                r3_result    <= 32'h7FC00000;
                r3_invalid   <= r2_is_invalid;
                r3_overflow  <= 0;
                r3_underflow <= 0;
                r3_inexact   <= 0;
            end else if (r2_is_inf_res) begin
                r3_result    <= {r2_inf_sign, 8'hFF, 23'h0};
                r3_invalid   <= r2_is_invalid;
                r3_overflow  <= 0;
                r3_underflow <= 0;
                r3_inexact   <= 0;
            end else begin
                r3_result    <= {r2_S_res, packed_exp, final_mant};
                r3_invalid   <= r2_is_invalid;
                r3_overflow  <= overflow;
                r3_underflow <= underflow;
                r3_inexact   <= inexact;
            end
        end
    end

    assign result         = r3_result;
    assign flag_invalid   = r3_invalid;
    assign flag_overflow  = r3_overflow;
    assign flag_underflow = r3_underflow;
    assign flag_inexact   = r3_inexact;

endmodule