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

    // =========================================================================
    // PIPELINE & HANDSHAKE CONTROL
    // =========================================================================
    logic stall;
    assign stall = out_valid && !out_ready;
    assign in_ready = !stall;

    logic v1, v2, v3;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            v1 <= 1'b0;
            v2 <= 1'b0;
            v3 <= 1'b0;
        end else if (!stall) begin
            v1 <= in_valid;
            v2 <= v1;
            v3 <= v2;
        end
    end

    assign out_valid = v3;

    // Helper functions
    function automatic [6:0] count_lz_128(input logic [127:0] val);
        integer i;
        logic [6:0] lz;
        lz = 7'd128;
        for (i = 127; i >= 0; i = i - 1) begin
            if (val[i]) begin
                lz = 7'd127 - i[6:0];
                break;
            end
        end
        return lz;
    endfunction

    // =========================================================================
    // STAGE 1: UNPACK, CLASSIFY, MULTIPLY & PRE-ALIGN
    // =========================================================================
    // Operand Unpack
    logic sa, sb, sc;
    logic [7:0] ea, eb, ec;
    logic [22:0] ma, mb, mc;

    assign {sa, ea, ma} = a;
    assign {sb, eb, mb} = b;
    assign {sc, ec, mc} = c;

    // Classification
    logic is_zero_a, is_zero_b, is_zero_c;
    logic is_inf_a,  is_inf_b,  is_inf_c;
    logic is_nan_a,  is_nan_b,  is_nan_c;
    logic is_snan_a, is_snan_b, is_snan_c;

    assign is_zero_a = (ea == 8'd0)   && (ma == 23'd0);
    assign is_zero_b = (eb == 8'd0)   && (mb == 23'd0);
    assign is_zero_c = (ec == 8'd0)   && (mc == 23'd0);

    assign is_inf_a  = (ea == 8'd255) && (ma == 23'd0);
    assign is_inf_b  = (eb == 8'd255) && (mb == 23'd0);
    assign is_inf_c  = (ec == 8'd255) && (mc == 23'd0);

    assign is_nan_a  = (ea == 8'd255) && (ma != 23'd0);
    assign is_nan_b  = (eb == 8'd255) && (mb != 23'd0);
    assign is_nan_c  = (ec == 8'd255) && (mc != 23'd0);

    assign is_snan_a = is_nan_a && !ma[22];
    assign is_snan_b = is_nan_b && !mb[22];
    assign is_snan_c = is_nan_c && !mc[22];

    // Mantissas with hidden bit
    logic [23:0] MA, MB, MC;
    assign MA = (ea == 8'd0) ? {1'b0, ma} : {1'b1, ma};
    assign MB = (eb == 8'd0) ? {1'b0, mb} : {1'b1, mb};
    assign MC = (ec == 8'd0) ? {1'b0, mc} : {1'b1, mc};

    // Unbiased Exponents (13-bit signed integer)
    logic signed [12:0] Exp_a, Exp_b, Exp_c, Exp_prod, Exp_base;
    assign Exp_a = (ea == 8'd0) ? 13'sd1 - 13'sd127 : $signed({5'b0, ea}) - 13'sd127;
    assign Exp_b = (eb == 8'd0) ? 13'sd1 - 13'sd127 : $signed({5'b0, eb}) - 13'sd127;
    assign Exp_c = (ec == 8'd0) ? 13'sd1 - 13'sd127 : $signed({5'b0, ec}) - 13'sd127;

    // Multiplication
    logic sp;
    logic [47:0] P;
    assign sp = sa ^ sb;
    assign P  = MA * MB;
    assign Exp_prod = Exp_a + Exp_b;

    // Invalid & NaN Checks
    logic is_invalid_s1;
    logic is_nan_res_s1;
    logic is_inf_res_s1;
    logic is_zero_prod, is_inf_prod;

    assign is_zero_prod = is_zero_a || is_zero_b;
    assign is_inf_prod  = is_inf_a  || is_inf_b;

    assign is_invalid_s1 = is_snan_a || is_snan_b || is_snan_c ||
                           (is_inf_prod && is_zero_prod) ||
                           (is_inf_prod && is_inf_c && (sp != sc));

    assign is_nan_res_s1 = is_nan_a || is_nan_b || is_nan_c || is_invalid_s1;
    assign is_inf_res_s1 = (is_inf_prod || is_inf_c) && !is_nan_res_s1;

    // Alignment logic
    assign Exp_base = (Exp_prod > Exp_c) ? Exp_prod : Exp_c;

    logic signed [12:0] shift_p_raw, shift_c_raw;
    logic [7:0] shift_p, shift_c;

    assign shift_p_raw = Exp_base - Exp_prod;
    assign shift_c_raw = Exp_base - Exp_c;

    assign shift_p = (shift_p_raw > 13'sd128) ? 8'd128 : shift_p_raw[7:0];
    assign shift_c = (shift_c_raw > 13'sd128) ? 8'd128 : shift_c_raw[7:0];

    // Wide alignment canvas (128 bits)
    logic [127:0] P_wide, C_wide;
    logic stk_p, stk_c;

    always_comb begin
        logic [255:0] P_ext, C_ext;
        P_ext = {P, 208'b0} >> shift_p;
        C_ext = {MC, 232'b0} >> shift_c;

        P_wide = P_ext[255:128];
        stk_p  = |P_ext[127:0];

        C_wide = C_ext[255:128];
        stk_c  = |C_ext[127:0];
    end

    // Pipeline Register 1 (S1 -> S2)
    logic signed [12:0] s2_exp_base;
    logic [127:0] s2_p_wide, s2_c_wide;
    logic s2_sp, s2_sc, s2_stk_p, s2_stk_c;
    logic s2_is_nan, s2_is_inf, s2_invalid;
    logic s2_is_zero_prod, s2_is_zero_c;
    logic [2:0] s2_rnd_mode;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s2_exp_base     <= '0;
            s2_p_wide       <= '0;
            s2_c_wide       <= '0;
            s2_sp           <= '0;
            s2_sc           <= '0;
            s2_stk_p        <= '0;
            s2_stk_c        <= '0;
            s2_is_nan       <= '0;
            s2_is_inf       <= '0;
            s2_invalid      <= '0;
            s2_is_zero_prod <= '0;
            s2_is_zero_c    <= '0;
            s2_rnd_mode     <= '0;
        end else if (!stall) begin
            s2_exp_base     <= Exp_base;
            s2_p_wide       <= P_wide;
            s2_c_wide       <= C_wide;
            s2_sp           <= sp;
            s2_sc           <= sc;
            s2_stk_p        <= stk_p;
            s2_stk_c        <= stk_c;
            s2_is_nan       <= is_nan_res_s1;
            s2_is_inf       <= is_inf_res_s1;
            s2_invalid      <= is_invalid_s1;
            s2_is_zero_prod <= is_zero_prod;
            s2_is_zero_c    <= is_zero_c;
            s2_rnd_mode     <= rnd_mode;
        end
    end

    // =========================================================================
    // STAGE 2: ADDITION / SUBTRACTION & LEADING ZERO DETECT
    // =========================================================================
    logic eff_sub;
    assign eff_sub = s2_sp ^ s2_sc;

    logic [127:0] sum_raw;
    logic res_sign;
    logic stk_eff;

    always_comb begin
        stk_eff = s2_stk_p | s2_stk_c;
        if (!eff_sub) begin
            sum_raw  = s2_p_wide + s2_c_wide;
            res_sign = s2_sp;
        end else begin
            if (s2_p_wide >= s2_c_wide) begin
                sum_raw  = s2_p_wide - s2_c_wide - (s2_stk_c && !s2_stk_p ? 128'd1 : 128'd0);
                res_sign = s2_sp;
            end else begin
                sum_raw  = s2_c_wide - s2_p_wide - (s2_stk_p && !s2_stk_c ? 128'd1 : 128'd0);
                res_sign = s2_sc;
            end
        end

        // Exact zero sign handling
        if ((sum_raw == '0) && !stk_eff && (s2_is_zero_prod || s2_is_zero_c || eff_sub)) begin
            res_sign = (s2_rnd_mode == 3'd2) ? 1'b1 : 1'b0; // RDN yields -0
        end
    end

    logic [6:0] lz;
    assign lz = count_lz_128(sum_raw);

    // Pipeline Register 2 (S2 -> S3)
    logic signed [12:0] s3_exp_base;
    logic [127:0] s3_sum_raw;
    logic [6:0] s3_lz;
    logic s3_res_sign, s3_stk_eff;
    logic s3_is_nan, s3_is_inf, s3_invalid;
    logic [2:0] s3_rnd_mode;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s3_exp_base  <= '0;
            s3_sum_raw   <= '0;
            s3_lz        <= '0;
            s3_res_sign  <= '0;
            s3_stk_eff   <= '0;
            s3_is_nan    <= '0;
            s3_is_inf    <= '0;
            s3_invalid   <= '0;
            s3_rnd_mode  <= '0;
        end else if (!stall) begin
            s3_exp_base  <= s2_exp_base;
            s3_sum_raw   <= sum_raw;
            s3_lz        <= lz;
            s3_res_sign  <= res_sign;
            s3_stk_eff   <= stk_eff;
            s3_is_nan    <= s2_is_nan;
            s3_is_inf    <= s2_is_inf;
            s3_invalid   <= s2_invalid;
            s3_rnd_mode  <= s2_rnd_mode;
        end
    end

    // =========================================================================
    // STAGE 3: NORMALIZE, ROUND, TININESS DETECT & FINAL RESULT
    // =========================================================================
    logic [127:0] norm_sum;
    logic signed [12:0] exp_norm;

    assign norm_sum = s3_sum_raw << s3_lz;
    assign exp_norm = s3_exp_base + 13'sd1 - $signed({6'b0, s3_lz});

    // Subnormal shift calculation
    logic signed [12:0] exp_biased;
    assign exp_biased = exp_norm + 13'sd127;

    logic [7:0] sub_shift;
    logic [127:0] sub_norm_sum;
    logic sub_stk;

    always_comb begin
        if (exp_biased <= 0) begin
            logic signed [12:0] shift_amt;
            logic [255:0] ext_norm;
            shift_amt = 13'sd1 - exp_biased;
            sub_shift = (shift_amt > 13'sd128) ? 8'd128 : shift_amt[7:0];

            ext_norm     = {norm_sum, 128'b0} >> sub_shift;
            sub_norm_sum = ext_norm[255:128];
            sub_stk      = |ext_norm[127:0];
        end else begin
            sub_shift    = 8'd0;
            sub_norm_sum = norm_sum;
            sub_stk      = 1'b0;
        end
    end

    // Rounding Extraction
    logic [22:0] mant_pre;
    logic g_bit, r_bit, s_bit, l_bit;

    assign mant_pre = sub_norm_sum[126:104];
    assign l_bit    = mant_pre[0];
    assign g_bit    = sub_norm_sum[103];
    assign r_bit    = sub_norm_sum[102];
    assign s_bit    = (|sub_norm_sum[101:0]) | s3_stk_eff | sub_stk;

    logic rnd_inc;
    always_comb begin
        case (s3_rnd_mode)
            3'd0: rnd_inc = g_bit && (r_bit || s_bit || l_bit);           // RNE
            3'd1: rnd_inc = 1'b0;                                          // RTZ
            3'd2: rnd_inc = s3_res_sign  && (g_bit || r_bit || s_bit);     // RDN
            3'd3: rnd_inc = !s3_res_sign && (g_bit || r_bit || s_bit);     // RUP
            3'd4: rnd_inc = g_bit;                                         // RMM
            default: rnd_inc = 1'b0;
        endcase
    end

    logic [24:0] mant_rounded;
    assign mant_rounded = {1'b0, sub_norm_sum[127], mant_pre} + rnd_inc;

    // Exponent and Mantissa Post-Rounding Adjustment
    logic signed [12:0] final_exp;
    logic [22:0] final_mant;

    always_comb begin
        if (exp_biased <= 0) begin
            if (mant_rounded[24]) begin // Normalization overflow from subnormal rounding
                final_exp  = 13'sd1;
                final_mant = 23'd0;
            end else begin
                final_exp  = 13'sd0;
                final_mant = mant_rounded[22:0];
            end
        end else begin
            if (mant_rounded[24]) begin
                final_exp  = exp_biased + 13'sd1;
                final_mant = mant_rounded[23:1];
            end else begin
                final_exp  = exp_biased;
                final_mant = mant_rounded[22:0];
            end
        end
    end

    // Exception Flags & Special Output Formatting
    logic is_inexact, is_overflow, is_underflow;

    assign is_inexact = g_bit || r_bit || s_bit;

    // Overflow check
    assign is_overflow = (final_exp >= 13'sd255) && !s3_is_nan && !s3_is_inf;

    // Tininess AFTER rounding check (Requirement A6)
    assign is_underflow = (exp_biased <= 0) && (final_exp == 13'sd0) && is_inexact && !s3_is_nan;

    always_comb begin
        if (s3_is_nan || s3_invalid) begin
            result        = 32'h7FC00000; // Canonical Quiet NaN
            flag_invalid   = s3_invalid || s3_is_nan;
            flag_overflow  = 1'b0;
            flag_underflow = 1'b0;
            flag_inexact   = 1'b0;
        end else if (s3_is_inf || is_overflow) begin
            flag_invalid   = 1'b0;
            flag_overflow  = is_overflow;
            flag_underflow = 1'b0;
            flag_inexact   = is_inexact || is_overflow;

            if (s3_is_inf) begin
                result = {s3_res_sign, 8'hFF, 23'd0};
            end else begin
                // Overflow rounding selection
                case (s3_rnd_mode)
                    3'd1: result = {s3_res_sign, 8'hFE, 23'h7FFFFF}; // RTZ
                    3'd2: result = s3_res_sign  ? {s3_res_sign, 8'hFF, 23'd0} : {s3_res_sign, 8'hFE, 23'h7FFFFF}; // RDN
                    3'd3: result = !s3_res_sign ? {s3_res_sign, 8'hFF, 23'd0} : {s3_res_sign, 8'hFE, 23'h7FFFFF}; // RUP
                    default: result = {s3_res_sign, 8'hFF, 23'd0};  // RNE, RMM
                endcase
            end
        end else if (s3_sum_raw == '0 && !s3_stk_eff) begin
            result        = {s3_res_sign, 31'd0};
            flag_invalid   = 1'b0;
            flag_overflow  = 1'b0;
            flag_underflow = 1'b0;
            flag_inexact   = 1'b0; // False
            flag_inexact   = 1'b0;
        end else begin
            result        = {s3_res_sign, final_exp[7:0], final_mant};
            flag_invalid   = 1'b0;
            flag_overflow  = 1'b0;
            flag_underflow = is_underflow;
            flag_inexact   = is_inexact;
        end
    end

endmodule