// =============================================================================
// fp32_fma_ii1.sv
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
    // Pipeline control
    // -------------------------------------------------------------------------
    logic stall_s1, stall_s2, stall_s3;
    logic valid_s1, valid_s2, valid_s3;
    
    assign in_ready = !stall_s1;
    assign out_valid = valid_s3;

    assign stall_s3 = valid_s3 && !out_ready;
    assign stall_s2 = valid_s2 && stall_s3;
    assign stall_s1 = valid_s1 && stall_s2;

    wire en_s1 = in_valid && !stall_s1;
    wire en_s2 = valid_s1 && !stall_s2;
    wire en_s3 = valid_s2 && !stall_s3;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            valid_s1 <= 1'b0;
            valid_s2 <= 1'b0;
            valid_s3 <= 1'b0;
        end else begin
            if (!stall_s1) valid_s1 <= in_valid;
            if (!stall_s2) valid_s2 <= valid_s1;
            if (!stall_s3) valid_s3 <= valid_s2;
        end
    end

    // -------------------------------------------------------------------------
    // Stage 0 -> Stage 1: Unpack, Multiply, Align
    // -------------------------------------------------------------------------
    logic sign_a, sign_b, sign_c;
    logic [7:0] exp_a, exp_b, exp_c;
    logic [23:0] sig_a, sig_b, sig_c;
    
    assign sign_a = a[31];
    assign exp_a  = a[30:23];
    assign sig_a  = (exp_a == 0) ? {1'b0, a[22:0]} : {1'b1, a[22:0]};
    
    assign sign_b = b[31];
    assign exp_b  = b[30:23];
    assign sig_b  = (exp_b == 0) ? {1'b0, b[22:0]} : {1'b1, b[22:0]};
    
    assign sign_c = c[31];
    assign exp_c  = c[30:23];
    assign sig_c  = (exp_c == 0) ? {1'b0, c[22:0]} : {1'b1, c[22:0]};

    logic a_is_nan, b_is_nan, c_is_nan;
    logic a_is_snan, b_is_snan, c_is_snan;
    logic a_is_inf, b_is_inf, c_is_inf;
    logic a_is_zero, b_is_zero, c_is_zero;

    assign a_is_nan  = (exp_a == 8'hFF) && (sig_a[22:0] != 0);
    assign a_is_snan = a_is_nan && !sig_a[22];
    assign a_is_inf  = (exp_a == 8'hFF) && (sig_a[22:0] == 0);
    assign a_is_zero = (exp_a == 0) && (sig_a[22:0] == 0);

    assign b_is_nan  = (exp_b == 8'hFF) && (sig_b[22:0] != 0);
    assign b_is_snan = b_is_nan && !sig_b[22];
    assign b_is_inf  = (exp_b == 8'hFF) && (sig_b[22:0] == 0);
    assign b_is_zero = (exp_b == 0) && (sig_b[22:0] == 0);

    assign c_is_nan  = (exp_c == 8'hFF) && (sig_c[22:0] != 0);
    assign c_is_snan = c_is_nan && !sig_c[22];
    assign c_is_inf  = (exp_c == 8'hFF) && (sig_c[22:0] == 0);
    assign c_is_zero = (exp_c == 0) && (sig_c[22:0] == 0);

    logic prod_sign;
    assign prod_sign = sign_a ^ sign_b;
    
    logic inf_mul_zero;
    assign inf_mul_zero = (a_is_inf && b_is_zero) || (a_is_zero && b_is_inf);
    
    logic invalid_op;
    assign invalid_op = a_is_snan || b_is_snan || c_is_snan || inf_mul_zero || 
                        ((a_is_inf || b_is_inf) && c_is_inf && (prod_sign != sign_c));
                        
    logic is_nan_res;
    assign is_nan_res = a_is_nan || b_is_nan || c_is_nan || invalid_op;

    // Adjusted exponents for subnormals
    logic signed [9:0] ext_exp_a, ext_exp_b, ext_exp_c;
    assign ext_exp_a = (exp_a == 0) ? ((sig_a == 0) ? 0 : 1) : exp_a;
    assign ext_exp_b = (exp_b == 0) ? ((sig_b == 0) ? 0 : 1) : exp_b;
    assign ext_exp_c = (exp_c == 0) ? ((sig_c == 0) ? 0 : 1) : exp_c;

    logic signed [10:0] exp_prod;
    assign exp_prod = ext_exp_a + ext_exp_b - 127;

    // 48-bit product
    logic [47:0] sig_prod;
    assign sig_prod = sig_a * sig_b;

    logic prod_is_zero;
    assign prod_is_zero = a_is_zero || b_is_zero;

    logic signed [11:0] exp_diff;
    assign exp_diff = exp_prod - ext_exp_c;

    // Align C with product
    // The product has 48 bits, 2 integer bits. Q2.46. 
    // C has 24 bits, 1 integer bit. Q1.23.
    // We pad C to match the product's format, then shift it.
    // Let's place the radix point at bit 46.
    logic signed [11:0] shift_c;
    logic signed [11:0] shift_p;
    logic signed [11:0] target_exp;
    
    // Choose the larger exponent as the temporary exponent
    assign target_exp = (prod_is_zero && c_is_zero) ? 0 :
                        (prod_is_zero) ? ext_exp_c :
                        (c_is_zero) ? exp_prod :
                        (exp_prod > ext_exp_c) ? exp_prod : ext_exp_c;

    assign shift_c = target_exp - ext_exp_c;
    assign shift_p = target_exp - exp_prod;

    // Expand to 75 bits to prevent precision loss.
    // Q3.72 format
    logic [74:0] aligned_c;
    logic [74:0] aligned_p;
    
    logic [74:0] unshifted_c;
    assign unshifted_c = {2'b0, sig_c, 49'b0};
    
    logic [74:0] unshifted_p;
    assign unshifted_p = {1'b0, sig_prod, 26'b0};
    
    logic c_sticky, p_sticky;
    
    always_comb begin
        if (shift_c >= 75) begin
            aligned_c = 0;
            c_sticky = (sig_c != 0);
        end else begin
            aligned_c = unshifted_c >> shift_c;
            c_sticky = ((unshifted_c << (75 - shift_c)) != 0);
        end
    end

    always_comb begin
        if (shift_p >= 75) begin
            aligned_p = 0;
            p_sticky = (sig_prod != 0);
        end else begin
            aligned_p = unshifted_p >> shift_p;
            p_sticky = ((unshifted_p << (75 - shift_p)) != 0);
        end
    end

    // Add sticky bit to LSB
    logic [74:0] aligned_c_st, aligned_p_st;
    assign aligned_c_st = {aligned_c[74:1], aligned_c[0] | c_sticky};
    assign aligned_p_st = {aligned_p[74:1], aligned_p[0] | p_sticky};

    // FF for S1
    logic s1_sign_p, s1_sign_c;
    logic [74:0] s1_aligned_p, s1_aligned_c;
    logic signed [11:0] s1_target_exp;
    logic s1_invalid, s1_is_nan_res;
    logic [2:0] s1_rnd_mode;
    logic s1_prod_is_zero, s1_c_is_zero;
    logic s1_is_inf;
    logic s1_inf_sign;
    
    always_ff @(posedge clk) begin
        if (en_s1) begin
            s1_sign_p <= prod_sign;
            s1_sign_c <= sign_c;
            s1_aligned_p <= aligned_p_st;
            s1_aligned_c <= aligned_c_st;
            s1_target_exp <= target_exp;
            s1_invalid <= invalid_op;
            s1_is_nan_res <= is_nan_res;
            s1_rnd_mode <= rnd_mode;
            s1_prod_is_zero <= prod_is_zero;
            s1_c_is_zero <= c_is_zero;
            s1_is_inf <= (a_is_inf || b_is_inf || c_is_inf);
            s1_inf_sign <= (a_is_inf || b_is_inf) ? prod_sign : sign_c;
        end
    end

    // -------------------------------------------------------------------------
    // Stage 1 -> Stage 2: Add/Sub, Leading Zero Count
    // -------------------------------------------------------------------------
    
    logic do_sub;
    assign do_sub = s1_sign_p ^ s1_sign_c;

    logic [75:0] sum;
    logic res_sign;
    logic is_exact_zero;

    always_comb begin
        if (s1_prod_is_zero && s1_c_is_zero) begin
            sum = 0;
            res_sign = (s1_sign_p & s1_sign_c);
            if (s1_sign_p != s1_sign_c && s1_rnd_mode == 2) // RDN
                res_sign = 1;
        end else if (!do_sub) begin
            sum = s1_aligned_p + s1_aligned_c;
            res_sign = s1_sign_p;
        end else begin
            if (s1_aligned_p > s1_aligned_c) begin
                sum = s1_aligned_p - s1_aligned_c;
                res_sign = s1_sign_p;
            end else if (s1_aligned_c > s1_aligned_p) begin
                sum = s1_aligned_c - s1_aligned_p;
                res_sign = s1_sign_c;
            end else begin
                sum = 0;
                res_sign = (s1_rnd_mode == 2) ? 1'b1 : 1'b0; // RDN yields -0
            end
        end
    end

    assign is_exact_zero = (sum == 0) && !s1_is_nan_res && !s1_is_inf;

    // Find leading zero
    logic [6:0] lzc;
    always_comb begin
        lzc = 7'd75;
        for (int i = 75; i >= 0; i--) begin
            if (sum[i]) begin
                lzc = 75 - i;
                break;
            end
        end
    end

    // Normalize
    logic [75:0] norm_sum;
    logic signed [12:0] norm_exp;
    assign norm_sum = sum << lzc;
    assign norm_exp = s1_target_exp + 1 - lzc; 

    // FF for S2
    logic s2_res_sign;
    logic signed [12:0] s2_norm_exp;
    logic [75:0] s2_norm_sum;
    logic s2_invalid, s2_is_nan_res;
    logic [2:0] s2_rnd_mode;
    logic s2_is_exact_zero;
    logic s2_is_inf;
    logic s2_inf_sign;
    logic [75:0] s2_raw_sum;

    always_ff @(posedge clk) begin
        if (en_s2) begin
            s2_res_sign <= res_sign;
            s2_norm_exp <= norm_exp;
            s2_norm_sum <= norm_sum;
            s2_invalid <= s1_invalid;
            s2_is_nan_res <= s1_is_nan_res;
            s2_rnd_mode <= s1_rnd_mode;
            s2_is_exact_zero <= is_exact_zero;
            s2_is_inf <= s1_is_inf;
            s2_inf_sign <= s1_inf_sign;
            s2_raw_sum <= sum;
        end
    end

    // -------------------------------------------------------------------------
    // Stage 2 -> Output: Rounding, Packing, Flags
    // -------------------------------------------------------------------------
    
    logic [23:0] sig_round;
    logic round_up;
    logic guard, round_bit, sticky;
    logic signed [12:0] final_exp;
    
    logic signed [12:0] shift_sub;
    logic [75:0] sub_shifted_sum;

    always_comb begin
        if (s2_norm_exp <= 0) begin
            // Subnormal result
            shift_sub = 1 - s2_norm_exp;
            if (shift_sub > 75) begin
                sub_shifted_sum = 0;
                sticky = (s2_norm_sum != 0);
            end else begin
                sub_shifted_sum = s2_norm_sum >> shift_sub;
                sticky = ((s2_norm_sum << (76 - shift_sub)) != 0);
            end
            sig_round = sub_shifted_sum[75:52];
            guard = sub_shifted_sum[51];
            round_bit = sub_shifted_sum[50];
            sticky = sticky | (sub_shifted_sum[49:0] != 0);
            final_exp = 0;
        end else begin
            // Normal result
            sig_round = s2_norm_sum[75:52];
            guard = s2_norm_sum[51];
            round_bit = s2_norm_sum[50];
            sticky = (s2_norm_sum[49:0] != 0);
            final_exp = s2_norm_exp;
        end
    end

    logic is_inexact;
    assign is_inexact = guard | round_bit | sticky;

    always_comb begin
        round_up = 1'b0;
        case (s2_rnd_mode)
            3'd0: round_up = guard && (round_bit || sticky || sig_round[0]); // RNE
            3'd1: round_up = 1'b0; // RTZ
            3'd2: round_up = s2_res_sign && is_inexact; // RDN
            3'd3: round_up = !s2_res_sign && is_inexact; // RUP
            3'd4: round_up = guard; // RMM
            default: round_up = 1'b0;
        endcase
    end

    logic [24:0] rounded_sig;
    assign rounded_sig = sig_round + round_up;

    logic signed [12:0] rounded_exp;
    logic [22:0] final_sig;

    always_comb begin
        if (rounded_sig[24]) begin // Overflow from rounding
            rounded_exp = final_exp + 1;
            final_sig = rounded_sig[23:1];
        end else begin
            rounded_exp = final_exp;
            final_sig = rounded_sig[22:0];
        end
    end

    // Flags & Special values
    logic is_ovf;
    logic is_udf;
    
    assign is_ovf = (rounded_exp >= 255);
    // Underflow: result is inexact AND delivered result's biased exponent field is ZERO.
    assign is_udf = is_inexact && (rounded_exp <= 0);

    logic [31:0] final_res;
    logic f_inv, f_ovf, f_udf, f_inx;

    always_comb begin
        f_inv = s2_invalid;
        f_ovf = 1'b0;
        f_udf = 1'b0;
        f_inx = 1'b0;

        if (s2_is_nan_res) begin
            final_res = 32'h7FC00000;
        end else if (s2_is_inf) begin
            final_res = {s2_inf_sign, 8'hFF, 23'b0};
        end else if (s2_is_exact_zero) begin
            final_res = {s2_res_sign, 31'b0};
        end else if (is_ovf) begin
            f_ovf = 1'b1;
            f_inx = 1'b1;
            // Overflow handling based on rounding mode
            if (s2_rnd_mode == 0 || s2_rnd_mode == 4 || 
               (s2_rnd_mode == 2 && s2_res_sign) || (s2_rnd_mode == 3 && !s2_res_sign)) begin
                final_res = {s2_res_sign, 8'hFF, 23'b0}; // Inf
            end else begin
                final_res = {s2_res_sign, 8'hFE, 23'h7FFFFF}; // Max normal
            end
        end else begin
            final_res = {s2_res_sign, rounded_exp[7:0], final_sig};
            if (is_udf) begin
                f_udf = 1'b1;
            end
            if (is_inexact) begin
                f_inx = 1'b1;
            end
        end
    end

    // Assign to Output registers
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            result <= 32'b0;
            flag_invalid <= 1'b0;
            flag_overflow <= 1'b0;
            flag_underflow <= 1'b0;
            flag_inexact <= 1'b0;
        end else if (en_s3) begin
            result <= final_res;
            flag_invalid <= f_inv;
            flag_overflow <= f_ovf;
            flag_underflow <= f_udf;
            flag_inexact <= f_inx;
        end
    end

endmodule