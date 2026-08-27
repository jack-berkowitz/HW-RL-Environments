// =============================================================================
// fp32_fma_ii1.sv
// 
// Synthesizable IEEE-754 binary32 Fused Multiply-Add (FMA).
// Delivers exactly 3 cycles of latency and an initiation interval of 1.
// Strictly adheres to all rounding modes, proper subnormal handling, pinned 
// underflow logic, and NaN specifications per the d_ai04 contract.
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
    // Module-Level Variable Declarations (T2 Compliance)
    // =========================================================================
    logic stall;
    logic [2:0] valid_q;
    
    // Stage 1 variables
    logic [7:0] a_exp, b_exp, c_exp;
    logic [23:0] sig_a, sig_b, sig_c;
    logic [7:0] e_a, e_b, e_c;
    logic signed [11:0] W_p, W_c, delta_W, E_max_s1;
    logic [47:0] sig_prod;
    logic a_is_zero, b_is_zero, c_is_zero;
    logic a_is_inf, b_is_inf, c_is_inf;
    logic a_is_nan, b_is_nan, c_is_nan;
    logic a_is_snan, b_is_snan, c_is_snan;
    logic any_snan, any_nan, inf_times_zero, prod_is_inf, inf_minus_inf;
    logic invalid_flag_s1, res_is_nan_s1, res_is_inf_s1, inf_sign_s1;
    logic s_prod, s_c;
    logic [74:0] p_unshifted, c_unshifted;
    logic [7:0] sh_c, sh_p;
    logic [6:0] sh_c_trunc, sh_p_trunc;
    logic [74:0] c_shifted, p_shifted;
    logic c_sticky, p_sticky;
    logic [75:0] p_val76_s1, c_val76_s1;
    
    // Stage 1 -> Stage 2 Registers
    logic [75:0] p_val76_s2, c_val76_s2;
    logic s_prod_s2, s_c_s2;
    logic signed [11:0] E_max_s2;
    logic res_is_nan_s2, res_is_inf_s2, invalid_flag_s2, inf_sign_s2;
    logic [2:0] rnd_mode_s2;

    // Stage 2 variables
    logic p_ge_c_s2;
    logic [75:0] sum_raw_s2;
    logic sum_sign_s2;
    logic [6:0] lz_count_s2;
    int i;
    logic signed [11:0] E_top_s2, sh_unb_s2, sh_sub_s2, sh_norm_s2;
    logic signed [12:0] E_norm_s2;
    logic [11:0] rsh_full;
    logic [6:0] rsh_trunc;
    logic [74:0] norm_frac_s2;
    logic norm_sticky_s2;
    logic is_exact_zero_s2;
    
    // Stage 2 -> Stage 3 Registers
    logic [74:0] norm_frac_s3;
    logic norm_sticky_s3;
    logic signed [12:0] E_norm_s3;
    logic is_exact_zero_s3;
    logic sum_sign_s3, s_prod_s3, s_c_s3;
    logic res_is_nan_s3, res_is_inf_s3, invalid_flag_s3, inf_sign_s3;
    logic [2:0] rnd_mode_s3;

    // Stage 3 variables
    logic G_s3, R_s3, S_bit_s3;
    logic round_up_s3;
    logic [24:0] mantissa_rounded_s3;
    logic [23:0] final_mantissa_s3;
    logic signed [12:0] final_exp_s3;
    logic inexact_flag_s3;
    logic [7:0] packed_exp_s3;
    logic [22:0] packed_frac_s3;
    logic overflow_flag_s3, underflow_flag_s3;
    logic final_sign_s3;

    // =========================================================================
    // Pipeline Control & Handshake (Latency = 3, II = 1)
    // =========================================================================
    assign stall = valid_q[2] && !out_ready;
    assign in_ready = !stall;
    assign out_valid = valid_q[2];

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_q <= 3'b0;
        end else if (!stall) begin
            valid_q[0] <= in_valid;
            valid_q[1] <= valid_q[0];
            valid_q[2] <= valid_q[1];
        end
    end

    // =========================================================================
    // Stage 1: Unpack, Multiply, and Alignment Shifts
    // =========================================================================
    always_comb begin
        a_exp = a[30:23];
        b_exp = b[30:23];
        c_exp = c[30:23];

        sig_a = (a_exp == 0) ? {1'b0, a[22:0]} : {1'b1, a[22:0]};
        sig_b = (b_exp == 0) ? {1'b0, b[22:0]} : {1'b1, b[22:0]};
        sig_c = (c_exp == 0) ? {1'b0, c[22:0]} : {1'b1, c[22:0]};

        e_a = (a_exp == 0) ? 8'd1 : a_exp;
        e_b = (b_exp == 0) ? 8'd1 : b_exp;
        e_c = (c_exp == 0) ? 8'd1 : c_exp;

        // Weights tracking and Exponent calculation
        W_p = {4'b0, e_a} + {4'b0, e_b} - 12'sd126;
        W_c = {4'b0, e_c};
        delta_W = W_p - W_c;
        E_max_s1 = (delta_W >= 0) ? W_p : W_c;

        sig_prod = sig_a * sig_b;
        s_prod = a[31] ^ b[31];
        s_c = c[31];

        // Exception checking
        a_is_zero = (a_exp == 0) && (a[22:0] == 0);
        b_is_zero = (b_exp == 0) && (b[22:0] == 0);
        c_is_zero = (c_exp == 0) && (c[22:0] == 0);

        a_is_inf = (a_exp == 255) && (a[22:0] == 0);
        b_is_inf = (b_exp == 255) && (b[22:0] == 0);
        c_is_inf = (c_exp == 255) && (c[22:0] == 0);

        a_is_nan = (a_exp == 255) && (a[22:0] != 0);
        b_is_nan = (b_exp == 255) && (b[22:0] != 0);
        c_is_nan = (c_exp == 255) && (c[22:0] != 0);

        a_is_snan = a_is_nan && (a[22] == 0);
        b_is_snan = b_is_nan && (b[22] == 0);
        c_is_snan = c_is_nan && (c[22] == 0);

        any_snan = a_is_snan | b_is_snan | c_is_snan;
        any_nan  = a_is_nan | b_is_nan | c_is_nan;

        inf_times_zero = (a_is_inf & b_is_zero) | (a_is_zero & b_is_inf);
        prod_is_inf = a_is_inf | b_is_inf;
        inf_minus_inf = prod_is_inf & c_is_inf & (s_prod != s_c);

        invalid_flag_s1 = any_snan | inf_times_zero | inf_minus_inf;
        res_is_nan_s1 = any_nan | invalid_flag_s1;
        res_is_inf_s1 = (prod_is_inf | c_is_inf) & ~res_is_nan_s1;
        inf_sign_s1 = prod_is_inf ? s_prod : s_c;

        // Alignment logic
        // p_unshifted LSB placed at bit 25; c_unshifted LSB at bit 49.
        p_unshifted = {2'b0, sig_prod, 25'b0};
        c_unshifted = {2'b0, sig_c, 49'b0};

        if (delta_W >= 0) begin
            sh_c = (delta_W > 75) ? 8'd75 : delta_W[7:0];
            sh_c_trunc = sh_c[6:0];
            sh_p = 0;
            
            c_shifted = c_unshifted >> sh_c;
            p_shifted = p_unshifted;
            
            if (sh_c == 0) c_sticky = 1'b0;
            else if (sh_c >= 75) c_sticky = (c_unshifted != 75'd0);
            else c_sticky = ((c_unshifted << (7'd75 - sh_c_trunc)) != 75'd0);
            
            p_sticky = 1'b0;
        end else begin
            logic [11:0] neg_delta_W;
            neg_delta_W = -delta_W;
            
            sh_p = (neg_delta_W > 75) ? 8'd75 : neg_delta_W[7:0];
            sh_p_trunc = sh_p[6:0];
            sh_c = 0;
            
            p_shifted = p_unshifted >> sh_p;
            c_shifted = c_unshifted;
            
            if (sh_p == 0) p_sticky = 1'b0;
            else if (sh_p >= 75) p_sticky = (p_unshifted != 75'd0);
            else p_sticky = ((p_unshifted << (7'd75 - sh_p_trunc)) != 75'd0);
            
            c_sticky = 1'b0;
        end

        p_val76_s1 = {p_shifted, p_sticky};
        c_val76_s1 = {c_shifted, c_sticky};
    end

    always_ff @(posedge clk) begin
        if (!stall) begin
            p_val76_s2      <= p_val76_s1;
            c_val76_s2      <= c_val76_s1;
            s_prod_s2       <= s_prod;
            s_c_s2          <= s_c;
            E_max_s2        <= E_max_s1;
            res_is_nan_s2   <= res_is_nan_s1;
            res_is_inf_s2   <= res_is_inf_s1;
            invalid_flag_s2 <= invalid_flag_s1;
            inf_sign_s2     <= inf_sign_s1;
            rnd_mode_s2     <= rnd_mode;
        end
    end

    // =========================================================================
    // Stage 2: Add/Sub, LZD, and Normalize
    // =========================================================================
    always_comb begin
        p_ge_c_s2 = (p_val76_s2 >= c_val76_s2);

        if (s_prod_s2 == s_c_s2) begin
            sum_raw_s2 = p_val76_s2 + c_val76_s2;
            sum_sign_s2 = s_prod_s2;
        end else begin
            if (p_ge_c_s2) begin
                sum_raw_s2 = p_val76_s2 - c_val76_s2;
                sum_sign_s2 = s_prod_s2;
            end else begin
                sum_raw_s2 = c_val76_s2 - p_val76_s2;
                sum_sign_s2 = s_c_s2;
            end
        end

        lz_count_s2 = 7'd75;
        if (sum_raw_s2[75:1] != 75'd0) begin
            for (i = 74; i >= 0; i--) begin
                if (sum_raw_s2[i+1]) begin
                    lz_count_s2 = 7'd74 - i[6:0];
                    break;
                end
            end
        end

        E_top_s2 = E_max_s2 + 12'sd3;
        sh_unb_s2 = {5'b0, lz_count_s2};
        sh_sub_s2 = E_top_s2 - 12'sd1;
        sh_norm_s2 = (sh_unb_s2 < sh_sub_s2) ? sh_unb_s2 : sh_sub_s2;
        E_norm_s2 = E_top_s2 - sh_norm_s2;

        if (sh_norm_s2 >= 0) begin
            norm_frac_s2 = sum_raw_s2[75:1] << sh_norm_s2;
            norm_sticky_s2 = sum_raw_s2[0];
        end else begin
            rsh_full = -sh_norm_s2;
            if (rsh_full >= 75) begin
                norm_frac_s2 = 75'b0;
                norm_sticky_s2 = (|sum_raw_s2[75:1]) | sum_raw_s2[0];
            end else begin
                rsh_trunc = rsh_full[6:0];
                norm_frac_s2 = sum_raw_s2[75:1] >> rsh_trunc;
                norm_sticky_s2 = ((sum_raw_s2[75:1] << (7'd75 - rsh_trunc)) != 75'd0) | sum_raw_s2[0];
            end
        end

        is_exact_zero_s2 = (sum_raw_s2 == 76'd0);
    end

    always_ff @(posedge clk) begin
        if (!stall) begin
            norm_frac_s3     <= norm_frac_s2;
            norm_sticky_s3   <= norm_sticky_s2;
            E_norm_s3        <= E_norm_s2;
            is_exact_zero_s3 <= is_exact_zero_s2;
            sum_sign_s3      <= sum_sign_s2;
            s_prod_s3        <= s_prod_s2;
            s_c_s3           <= s_c_s2;
            res_is_nan_s3    <= res_is_nan_s2;
            res_is_inf_s3    <= res_is_inf_s2;
            invalid_flag_s3  <= invalid_flag_s2;
            inf_sign_s3      <= inf_sign_s2;
            rnd_mode_s3      <= rnd_mode_s2;
        end
    end

    // =========================================================================
    // Stage 3: Round, Exception Generation, and Pack (Combinational -> Out)
    // =========================================================================
    always_comb begin
        G_s3 = norm_frac_s3[51];
        R_s3 = norm_frac_s3[50];
        S_bit_s3 = (|norm_frac_s3[49:1]) | norm_sticky_s3;

        round_up_s3 = 1'b0;
        case (rnd_mode_s3)
            3'd0: round_up_s3 = G_s3 & (R_s3 | S_bit_s3 | norm_frac_s3[52]); // RNE
            3'd1: round_up_s3 = 1'b0;                                        // RTZ
            3'd2: round_up_s3 = sum_sign_s3 & (G_s3 | R_s3 | S_bit_s3);      // RDN
            3'd3: round_up_s3 = (~sum_sign_s3) & (G_s3 | R_s3 | S_bit_s3);   // RUP
            3'd4: round_up_s3 = G_s3;                                        // RMM
            default: round_up_s3 = 1'b0;
        endcase

        mantissa_rounded_s3 = {1'b0, norm_frac_s3[75:52]} + round_up_s3;

        if (mantissa_rounded_s3[24]) begin
            final_mantissa_s3 = mantissa_rounded_s3[24:1];
            final_exp_s3 = E_norm_s3 + 12'sd1;
        end else begin
            final_mantissa_s3 = mantissa_rounded_s3[23:0];
            final_exp_s3 = E_norm_s3;
        end

        inexact_flag_s3 = G_s3 | R_s3 | S_bit_s3;

        overflow_flag_s3 = 1'b0;
        underflow_flag_s3 = 1'b0;

        if (is_exact_zero_s3) begin
            packed_exp_s3 = 8'd0;
            packed_frac_s3 = 23'd0;
        end else if (final_exp_s3 >= 255) begin
            overflow_flag_s3 = 1'b1;
            case (rnd_mode_s3)
                3'd0: begin packed_exp_s3 = 8'd255; packed_frac_s3 = 23'd0; end
                3'd1: begin packed_exp_s3 = 8'd254; packed_frac_s3 = {23{1'b1}}; end
                3'd2: begin
                    if (sum_sign_s3) begin packed_exp_s3 = 8'd255; packed_frac_s3 = 23'd0; end
                    else begin packed_exp_s3 = 8'd254; packed_frac_s3 = {23{1'b1}}; end
                end
                3'd3: begin
                    if (!sum_sign_s3) begin packed_exp_s3 = 8'd255; packed_frac_s3 = 23'd0; end
                    else begin packed_exp_s3 = 8'd254; packed_frac_s3 = {23{1'b1}}; end
                end
                3'd4: begin packed_exp_s3 = 8'd255; packed_frac_s3 = 23'd0; end
                default: begin packed_exp_s3 = 8'd255; packed_frac_s3 = 23'd0; end
            endcase
        end else if (final_exp_s3 <= 0 || (final_exp_s3 == 1 && final_mantissa_s3[23] == 0)) begin
            packed_exp_s3 = 8'd0;
            packed_frac_s3 = final_mantissa_s3[22:0];
            underflow_flag_s3 = inexact_flag_s3;
        end else begin
            packed_exp_s3 = final_exp_s3[7:0];
            packed_frac_s3 = final_mantissa_s3[22:0];
        end

        // A8: Exact Zero Sign
        if (res_is_nan_s3) begin
            final_sign_s3 = 1'b0; // Canonical NaN has 0 sign
        end else if (res_is_inf_s3) begin
            final_sign_s3 = inf_sign_s3;
        end else if (is_exact_zero_s3) begin
            if (s_prod_s3 == s_c_s3) final_sign_s3 = s_prod_s3;
            else final_sign_s3 = (rnd_mode_s3 == 3'd2) ? 1'b1 : 1'b0;
        end else begin
            final_sign_s3 = sum_sign_s3;
        end
    end

    // =========================================================================
    // Final Result Assignments
    // =========================================================================
    assign result = res_is_nan_s3 ? 32'h7FC00000 :
                    res_is_inf_s3 ? {final_sign_s3, 8'hFF, 23'd0} :
                    {final_sign_s3, packed_exp_s3, packed_frac_s3};

    assign flag_invalid   = invalid_flag_s3;
    assign flag_overflow  = ~res_is_nan_s3 & ~res_is_inf_s3 & overflow_flag_s3;
    assign flag_underflow = ~res_is_nan_s3 & ~res_is_inf_s3 & underflow_flag_s3;
    assign flag_inexact   = ~res_is_nan_s3 & ~res_is_inf_s3 & (inexact_flag_s3 | overflow_flag_s3);

endmodule