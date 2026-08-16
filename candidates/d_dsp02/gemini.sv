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
    // PIPELINE FLOW CONTROL (II=1, Handshake H1-H4, Reset R1-R3)
    // =========================================================================
    logic stage1_valid;
    logic stage2_ready;
    logic stage1_ready;

    // H1: in_ready depends ONLY on internal pipeline register state
    assign stage2_ready = out_ready || !out_valid;
    assign stage1_ready = stage2_ready || !stage1_valid;
    assign in_ready     = stage1_ready;

    // =========================================================================
    // STAGE 0 -> STAGE 1: OPERAND UNPACKING & MULTIPLY
    // =========================================================================
    // Input Operands Breakdown
    wire        sign_a = a[31];
    wire [7:0]  exp_a  = a[30:23];
    wire [22:0] frac_a = a[22:0];

    wire        sign_b = b[31];
    wire [7:0]  exp_b  = b[30:23];
    wire [22:0] frac_b = b[22:0];

    wire        sign_c = c[31];
    wire [7:0]  exp_c  = c[30:23];
    wire [22:0] frac_c = c[22:0];

    // Classification
    wire is_zero_a = (exp_a == 8'd0) && (frac_a == 23'd0);
    wire is_sub_a  = (exp_a == 8'd0) && (frac_a != 23'd0);
    wire is_inf_a  = (exp_a == 8'd255) && (frac_a == 23'd0);
    wire is_nan_a  = (exp_a == 8'd255) && (frac_a != 23'd0);
    wire is_snan_a = is_nan_a && (frac_a[22] == 1'b0);

    wire is_zero_b = (exp_b == 8'd0) && (frac_b == 23'd0);
    wire is_sub_b  = (exp_b == 8'd0) && (frac_b != 23'd0);
    wire is_inf_b  = (exp_b == 8'd255) && (frac_b == 23'd0);
    wire is_nan_b  = (exp_b == 8'd255) && (frac_b != 23'd0);
    wire is_snan_b = is_nan_b && (frac_b[22] == 1'b0);

    wire is_zero_c = (exp_c == 8'd0) && (frac_c == 23'd0);
    wire is_sub_c  = (exp_c == 8'd0) && (frac_c != 23'd0);
    wire is_inf_c  = (exp_c == 8'd255) && (frac_c == 23'd0);
    wire is_nan_c  = (exp_c == 8'd255) && (frac_c != 23'd0);
    wire is_snan_c = is_nan_c && (frac_c[22] == 1'b0);

    // Explicit Mantissas (Implicit Bit 1 for Normals, 0 for Subnormals)
    wire [23:0] man_a = {(!is_sub_a && (exp_a != 8'd0)), frac_a};
    wire [23:0] man_b = {(!is_sub_b && (exp_b != 8'd0)), frac_b};
    wire [23:0] man_c = {(!is_sub_c && (exp_c != 8'd0)), frac_c};

    // Effective Biased Exponents (Subnormal exponent = 1)
    wire signed [12:0] exp_a_eff = is_sub_a ? 13'sd1 : $signed({5'b0, exp_a});
    wire signed [12:0] exp_b_eff = is_sub_b ? 13'sd1 : $signed({5'b0, exp_b});
    wire signed [12:0] exp_c_eff = is_sub_c ? 13'sd1 : $signed({5'b0, exp_c});

    // Exact Product Computation
    wire is_prod_zero = is_zero_a || is_zero_b;
    wire signed [12:0] exp_p = is_prod_zero ? 13'sd0 : (exp_a_eff + exp_b_eff - 13'sd127);
    wire [47:0] prod_mant   = is_prod_zero ? 48'd0 : (man_a * man_b);
    wire sign_p             = sign_a ^ sign_b;

    // Special Case Flags (Stage 1)
    wire invalid_snan    = is_snan_a || is_snan_b || is_snan_c;
    wire invalid_0xinf   = (is_zero_a && is_inf_b) || (is_inf_a && is_zero_b);
    wire is_inf_p        = (is_inf_a || is_inf_b) && !invalid_0xinf;
    wire eff_sub_s0      = sign_p ^ sign_c;
    wire invalid_inf_sub = is_inf_p && is_inf_c && eff_sub_s0;

    wire invalid_flag_s0 = invalid_snan || invalid_0xinf || invalid_inf_sub;
    wire is_nan_res_s0   = invalid_flag_s0 || is_nan_a || is_nan_b || is_nan_c;
    wire is_inf_res_s0   = (is_inf_p || is_inf_c) && !is_nan_res_s0;

    // -------------------------------------------------------------------------
    // STAGE 1 PIPELINE REGISTERS
    // -------------------------------------------------------------------------
    logic [47:0]        s1_prod_mant;
    logic signed [12:0] s1_exp_p;
    logic               s1_sign_p;
    logic [23:0]        s1_man_c;
    logic signed [12:0] s1_exp_c;
    logic               s1_sign_c;
    logic [2:0]         s1_rnd_mode;
    logic               s1_is_nan_res;
    logic               s1_invalid_flag;
    logic               s1_is_inf_res;
    logic               s1_is_inf_p;
    logic               s1_is_zero_p;
    logic               s1_is_zero_c;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            stage1_valid <= 1'b0;
        end else if (stage1_ready) begin
            stage1_valid <= in_valid;
        end
    end

    always_ff @(posedge clk) begin
        if (stage1_ready && in_valid) begin
            s1_prod_mant    <= prod_mant;
            s1_exp_p        <= exp_p;
            s1_sign_p       <= sign_p;
            s1_man_c        <= man_c;
            s1_exp_c        <= exp_c_eff;
            s1_sign_c       <= sign_c;
            s1_rnd_mode     <= rnd_mode;
            s1_is_nan_res   <= is_nan_res_s0;
            s1_invalid_flag <= invalid_flag_s0;
            s1_is_inf_res   <= is_inf_res_s0;
            s1_is_inf_p     <= is_inf_p;
            s1_is_zero_p    <= is_prod_zero;
            s1_is_zero_c    <= is_zero_c;
        end
    end

    // =========================================================================
    // STAGE 1 DATAPATH: ALIGNMENT, WIDE ADD, NORMALIZATION, ROUNDING
    // =========================================================================
    wire eff_sub_s1 = s1_sign_p ^ s1_sign_c;

    // Determine Base Exponent and Shift Differences
    wire signed [12:0] exp_base = (s1_exp_p > s1_exp_c) ? s1_exp_p : s1_exp_c;
    wire signed [12:0] diff_p   = exp_base - s1_exp_p;
    wire signed [12:0] diff_c   = exp_base - s1_exp_c;

    // Clamped Shift Amounts (Width window of 160 bits)
    wire [6:0] shift_p = (diff_p > 13'sd80) ? 7'd80 : diff_p[6:0];
    wire [6:0] shift_c = (diff_c > 13'sd80) ? 7'd80 : diff_c[6:0];

    // Wide Grid Alignment (Index 120 maps to weight 2^0 at exp_base)
    wire [159:0] P_full = {38'b0, s1_prod_mant, 74'b0};
    wire [159:0] C_full = {39'b0, s1_man_c, 97'b0};

    wire [159:0] P_shifted = P_full >> shift_p;
    wire [159:0] C_shifted = C_full >> shift_c;

    // Exact Sticky Bit Computation from Shift-Outs
    wire sticky_p = (diff_p > 13'sd80 && s1_prod_mant != 0) ||
                    (|(P_full & ((160'b1 << shift_p) - 160'b1)));
    wire sticky_c = (diff_c > 13'sd80 && s1_man_c != 0) ||
                    (|(C_full & ((160'b1 << shift_c) - 160'b1)));

    // Wide Addition / Subtraction
    wire [160:0] P_with_sticky = {P_shifted, sticky_p};
    wire [160:0] C_with_sticky = {C_shifted, sticky_c};

    logic [160:0] sum_raw;
    logic         sign_res_pre;

    always_comb begin
        if (!eff_sub_s1) begin
            sum_raw      = P_with_sticky + C_with_sticky;
            sign_res_pre = s1_sign_p;
        end else begin
            if (P_with_sticky >= C_with_sticky) begin
                sum_raw      = P_with_sticky - C_with_sticky;
                sign_res_pre = s1_sign_p;
            end else begin
                sum_raw      = C_with_sticky - P_with_sticky;
                sign_res_pre = s1_sign_c;
            end
        end
    end

    wire [159:0] sum_wide   = sum_raw[160:1];
    wire         sticky_sum = sum_raw[0];

    // Leading Zero Count / MSB Detection
    logic [7:0] msb_idx;
    logic       sum_is_zero;

    always_comb begin
        msb_idx     = 8'd0;
        sum_is_zero = 1'b1;
        for (integer i = 159; i >= 0; i--) begin
            if (sum_wide[i]) begin
                if (sum_is_zero) begin
                    msb_idx     = i[7:0];
                    sum_is_zero = 1 me;
                end
            end
        end
    end

    // Exponent and Normalization Shift Calculation
    wire signed [12:0] exp_sum_raw = exp_base + $signed({5'b0, msb_idx}) - 13'sd120;

    logic signed [12:0] norm_shift;
    logic signed [12:0] target_exp;

    always_comb begin
        if (exp_sum_raw >= 13'sd1) begin
            target_exp = exp_sum_raw;
            norm_shift = 13'sd120 - $signed({5'b0, msb_idx});
        end else begin
            target_exp = 13'sd0;
            norm_shift = exp_base - 13'sd1;
        end
    end

    // Apply Normalization Shift
    logic [159:0] aligned_mant;
    logic         sticky_norm;

    always_comb begin
        if (norm_shift >= 0) begin
            aligned_mant = sum_wide << norm_shift;
            sticky_norm  = 1'b0;
        end else begin
            wire [7:0] rshift = (-norm_shift > 13'sd159) ? 8'd159 : (-norm_shift[7:0]);
            aligned_mant = sum_wide >> rshift;
            sticky_norm  = |(sum_wide & ((160'b1 << rshift) - 160'b1));
        end
    end

    wire sticky_total = sticky_sum | sticky_norm;

    // Rounding Bit Extraction
    wire lsb      = aligned_mant[97];
    wire g        = aligned_mant[96];
    wire r        = aligned_mant[95];
    wire s        = (|aligned_mant[94:0]) | sticky_total;
    wire r_or_s   = r | s;
    wire inexact_raw = g | r_or_s;

    // Rounding Increments Across 5 Modes
    logic round_up;
    always_comb begin
        case (s1_rnd_mode)
            3'd0: round_up = g & (lsb | r_or_s);            // RNE
            3'd1: round_up = 1'b0;                          // RTZ
            3'd2: round_up = sign_res_pre & (g | r_or_s);   // RDN
            3'd3: round_up = !sign_res_pre & (g | r_or_s);  // RUP
            3'd4: round_up = g;                             // RMM
            default: round_up = 1'b0;
        endcase
    end

    wire [23:0] mant_pre  = aligned_mant[120:97];
    wire [24:0] mant_post = mant_pre + round_up;

    // Post-Rounding Exponent & Fraction Adjustment
    logic signed [12:0] final_exp;
    logic [22:0]        final_frac;

    always_comb begin
        if (mant_post[24]) begin
            final_exp  = target_exp + 13'sd1;
            final_frac = mant_post[23:1];
        end else if (target_exp == 13'sd0 && mant_post[23]) begin
            final_exp  = 13'sd1;
            final_frac = mant_post[22:0];
        end else begin
            final_exp  = target_exp;
            final_frac = mant_post[22:0];
        end
    end

    // Signed Zero Rules (A5)
    logic sign_res;
    always_comb begin
        if (sum_is_zero || (s1_is_zero_p && s1_is_zero_c)) begin
            if (eff_sub_s1) begin
                sign_res = (s1_rnd_mode == 3'd2) ? 1'b1 : 1'b0; // RDN = -0, others +0
            end else begin
                sign_res = s1_sign_p;
            end
        end else begin
            sign_res = sign_res_pre;
        end
    end

    // Exception Flags (A4b, A6)
    wire is_overflow  = (final_exp >= 13'sd255) && !sum_is_zero;
    wire is_underflow = (final_exp == 13'sd0) && inexact_raw && !sum_is_zero;

    // Normal / Overflow Formatter
    logic [31:0] normal_result;
    always_comb begin
        if (sum_is_zero) begin
            normal_result = {sign_res, 31'b0};
        end else if (is_overflow) begin
            case (s1_rnd_mode)
                3'd0, 3'd4: normal_result = {sign_res, 8'hFF, 23'b0};          // Inf
                3'd1:       normal_result = {sign_res, 8'hFE, 23'h7F_FFFF};  // MaxNorm
                3'd2:       normal_result = sign_res ? {1'b1, 8'hFF, 23'b0} : {1'b0, 8'hFE, 23'h7F_FFFF};
                3'd3:       normal_result = sign_res ? {1'b1, 8'hFE, 23'h7F_FFFF} : {1'b0, 8'hFF, 23'b0};
                default:    normal_result = {sign_res, 8'hFF, 23'b0};
            endcase
        end else begin
            normal_result = {sign_res, final_exp[7:0], final_frac};
        end
    end

    // Output Assembly
    logic [31:0] final_result;
    logic        res_invalid, res_overflow, res_underflow, res_inexact;

    always_comb begin
        if (s1_is_nan_res) begin
            final_result  = 32'h7FC00000; // Requirement A4: Canonical QNaN
            res_invalid   = s1_invalid_flag;
            res_overflow  = 1'b0;
            res_underflow = 1'b0;
            res_inexact   = 1'b0;
        end else if (s1_is_inf_res) begin
            wire inf_sign = s1_is_inf_p ? s1_sign_p : s1_sign_c;
            final_result  = {inf_sign, 8'hFF, 23'b0};
            res_invalid   = 1'b0;
            res_overflow  = 1'b0;
            res_underflow = 1'b0;
            res_inexact   = 1'b0;
        end else begin
            final_result  = normal_result;
            res_invalid   = 1'b0;
            res_overflow  = is_overflow;
            res_underflow = is_underflow;
            res_inexact   = inexact_raw | is_overflow;
        end
    end

    // -------------------------------------------------------------------------
    // STAGE 2 PIPELINE REGISTERS (OUTPUT REGISTER STAGE)
    // -------------------------------------------------------------------------
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            out_valid <= 1'b0;
        end else if (stage2_ready) begin
            out_valid <= stage1_valid;
        end
    end

    always_ff @(posedge clk) begin
        if (stage2_ready && stage1_valid) begin
            result         <= final_result;
            flag_invalid   <= res_invalid;
            flag_overflow  <= res_overflow;
            flag_underflow <= res_underflow;
            flag_inexact   <= res_inexact;
        end
    end

endmodule