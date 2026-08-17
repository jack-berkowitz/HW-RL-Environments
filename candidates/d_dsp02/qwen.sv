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

    // Always ready to sustain II=1
    assign in_ready = 1'b1;

    function automatic [4:0] clz24;
        input [23:0] val;
        integer i;
        begin
            clz24 = 24;
            for (i = 23; i >= 0; i = i - 1) begin
                if (val[i]) begin
                    clz24 = 23 - i;
                    break;
                end
            end
        end
    endfunction

    function automatic [7:0] clz150;
        input [149:0] val;
        integer i;
        begin
            clz150 = 150;
            for (i = 149; i >= 0; i = i - 1) begin
                if (val[i]) begin
                    clz150 = 149 - i;
                    break;
                end
            end
        end
    endfunction

    // Pipeline valid bits
    logic v1, v2, v3;

    // Stage 1 Registers
    logic [31:0] a_r, b_r, c_r;
    logic [2:0]  rnd_mode_r;
    logic        sign_a_r, sign_b_r, sign_c_r;
    logic [7:0]  exp_a_r, exp_b_r, exp_c_r;
    logic [23:0] mant_a_r, mant_b_r, mant_c_r;
    logic [8:0]  true_exp_p_r, true_exp_c_r;
    logic        sign_p_r;
    logic [47:0] prod_r;
    logic        invalid_op_r, nan_result_r;

    // Stage 2 Registers
    logic [149:0] mag_sum_r;
    logic         res_sign_r;
    logic         is_zero_res_r;
    logic         zero_sign_r;
    logic         invalid_op_r2, nan_result_r2;
    logic [2:0]   rnd_mode_r2;
    logic [8:0]   true_exp_p_r2;

    // Stage 3 Registers
    logic [31:0] result_r;
    logic        flag_invalid_r, flag_overflow_r, flag_underflow_r, flag_inexact_r;

    // ========================================================================
    // Pipeline Control
    // ========================================================================
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            v1 <= 0; v2 <= 0; v3 <= 0;
        end else begin
            v1 <= in_valid;
            v2 <= v1;
            v3 <= v2;
        end
    end

    assign out_valid = v3;
    assign result = result_r;
    assign flag_invalid = flag_invalid_r;
    assign flag_overflow = flag_overflow_r;
    assign flag_underflow = flag_underflow_r;
    assign flag_inexact = flag_inexact_r;

    // ========================================================================
    // Stage 1: Classify and Multiply
    // ========================================================================
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_r <= 0; b_r <= 0; c_r <= 0;
            rnd_mode_r <= 0;
            sign_a_r <= 0; sign_b_r <= 0; sign_c_r <= 0;
            exp_a_r <= 0; exp_b_r <= 0; exp_c_r <= 0;
            mant_a_r <= 0; mant_b_r <= 0; mant_c_r <= 0;
            true_exp_p_r <= 0; true_exp_c_r <= 0;
            sign_p_r <= 0;
            prod_r <= 0;
            invalid_op_r <= 0; nan_result_r <= 0;
        end else if (in_valid) begin
            a_r <= a; b_r <= b; c_r <= c;
            rnd_mode_r <= rnd_mode;
            
            sign_a_r <= a[31]; sign_b_r <= b[31]; sign_c_r <= c[31];
            exp_a_r <= a[30:23]; exp_b_r <= b[30:23]; exp_c_r <= c[30:23];
            
            logic [4:0] lza, lzb, lzc;
            lza = clz24({1'b0, a[22:0]});
            lzb = clz24({1'b0, b[22:0]});
            lzc = clz24({1'b0, c[22:0]});
            
            mant_a_r <= (a[30:23] == 0) ? ({1'b0, a[22:0]} << lza) : {1'b1, a[22:0]};
            mant_b_r <= (b[30:23] == 0) ? ({1'b0, b[22:0]} << lzb) : {1'b1, b[22:0]};
            mant_c_r <= (c[30:23] == 0) ? ({1'b0, c[22:0]} << lzc) : {1'b1, c[22:0]};
            
            true_exp_p_r <= ((a[30:23] == 0) ? (-126 - lza) : (a[30:23] - 127)) + 
                            ((b[30:23] == 0) ? (-126 - lzb) : (b[30:23] - 127));
            true_exp_c_r <= (c[30:23] == 0) ? (-126 - lzc) : (c[30:23] - 127);
            
            sign_p_r <= sign_a_r ^ sign_b_r;
            prod_r <= mant_a_r * mant_b_r;
            
            logic is_nan_a, is_nan_b, is_nan_c;
            logic is_snan_a, is_snan_b, is_snan_c;
            logic is_inf_a, is_inf_b, is_inf_c;
            logic is_zero_a, is_zero_b, is_zero_c;
            
            is_nan_a   = (a[30:23] == 255) && (a[22:0] != 0);
            is_nan_b   = (b[30:23] == 255) && (b[22:0] != 0);
            is_nan_c   = (c[30:23] == 255) && (c[22:0] != 0);
            
            is_snan_a  = is_nan_a && !a[22];
            is_snan_b  = is_nan_b && !b[22];
            is_snan_c  = is_nan_c && !c[22];
            
            is_inf_a   = (a[30:23] == 255) && (a[22:0] == 0);
            is_inf_b   = (b[30:23] == 255) && (b[22:0] == 0);
            is_inf_c   = (c[30:23] == 255) && (c[22:0] == 0);
            
            is_zero_a  = (a[30:23] == 0) && (a[22:0] == 0);
            is_zero_b  = (b[30:23] == 0) && (b[22:0] == 0);
            is_zero_c  = (c[30:23] == 0) && (c[22:0] == 0);
            
            invalid_op_r <= is_snan_a || is_snan_b || is_snan_c ||
                            (is_inf_a && is_zero_b) || (is_zero_a && is_inf_b) ||
                            ((is_inf_a || is_inf_b) && is_inf_c && ((sign_a_r ^ sign_b_r) != sign_c_r));
                            
            nan_result_r <= is_nan_a || is_nan_b || is_nan_c || invalid_op_r;
        end
    end

    // ========================================================================
    // Stage 2: Align and Add (Combinational)
    // ========================================================================
    logic [149:0] V_P, V_C;
    logic         sticky_in;
    logic [8:0]   diff;
    logic [149:0] mag_sum;
    logic         res_sign;
    logic         is_sub;
    logic         is_zero_res;
    logic         zero_sign;

    always_comb begin
        diff = true_exp_p_r - true_exp_c_r - 23;
        
        if (diff > 80) begin
            V_P = {48'b0, prod_r, 78'b0};
            V_C = 150'b0;
            sticky_in = |mant_c_r;
        end else if (diff < -100) begin
            V_P = 150'b0;
            V_C = mant_c_r << ((-diff > 149) ? 149 : -diff);
            sticky_in = |prod_r;
        end else begin
            V_P = {48'b0, prod_r, 78'b0};
            if (diff >= 0) begin
                V_C = {126'b0, mant_c_r} >> diff;
            end else begin
                V_C = {mant_c_r, 126'b0} << -diff;
            end
            sticky_in = 1'b0;
        end
        
        is_sub = (sign_p_r ^ sign_c_r);
        
        if (is_sub) begin
            if (V_P >= V_C) begin
                mag_sum = V_P - V_C;
                res_sign = sign_p_r;
            end else begin
                mag_sum = V_C - V_P;
                res_sign = sign_c_r;
            end
        end else begin
            mag_sum = V_P + V_C;
            res_sign = sign_p_r;
        end
        
        is_zero_res = (mag_sum == 0);
        if (is_zero_res) begin
            if (sign_p_r == 1'b1 && sign_c_r == 1'b1) begin
                zero_sign = 1'b1;
            end else if (rnd_mode_r == 3'd2) begin
                zero_sign = 1'b1;
            end else begin
                zero_sign = 1'b0;
            end
        end else begin
            zero_sign = 1'b0;
        end
    end

    // Stage 2 Registers
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mag_sum_r <= 0;
            res_sign_r <= 0;
            is_zero_res_r <= 0;
            zero_sign_r <= 0;
            invalid_op_r2 <= 0;
            nan_result_r2 <= 0;
            rnd_mode_r2 <= 0;
            true_exp_p_r2 <= 0;
        end else if (v1) begin
            mag_sum_r <= mag_sum;
            res_sign_r <= res_sign;
            is_zero_res_r <= is_zero_res;
            zero_sign_r <= zero_sign;
            invalid_op_r2 <= invalid_op_r;
            nan_result_r2 <= nan_result_r;
            rnd_mode_r2 <= rnd_mode_r;
            true_exp_p_r2 <= true_exp_p_r;
        end else begin
            mag_sum_r <= 0;
            res_sign_r <= 0;
            is_zero_res_r <= 0;
            zero_sign_r <= 0;
            invalid_op_r2 <= 0;
            nan_result_r2 <= 0;
            rnd_mode_r2 <= 0;
            true_exp_p_r2 <= 0;
        end
    end

    // ========================================================================
    // Stage 3: Normalize and Round (Combinational)
    // ========================================================================
    logic [7:0]   lzc;
    logic [8:0]   msb_pos;
    logic [26:0]  mant_grs;
    logic         sticky_bit;
    logic [23:0]  val24;
    logic         G, R, S;
    logic         round_up;
    logic [23:0]  rounded_val;
    logic         carry_out;
    logic [8:0]   true_exp_final;
    logic         is_tiny, is_overflow, is_inexact, is_underflow;
    logic [31:0]  final_result;
    logic         f_invalid, f_overflow, f_underflow, f_inexact;

    always_comb begin
        lzc = clz150(mag_sum_r);
        msb_pos = 149 - lzc;
        
        if (is_zero_res_r) begin
            mant_grs = 0;
            sticky_bit = 0;
        end else if (msb_pos >= 26) begin
            mant_grs = mag_sum_r >> (msb_pos - 26);
            sticky_bit = mant_grs[0] | |mag_sum_r[msb_pos - 27 : 0];
        end else begin
            mant_grs = mag_sum_r[26:0];
            sticky_bit = mant_grs[0];
        end
        
        val24 = {mant_grs[26], mant_grs[25:3]};
        G = mant_grs[2];
        R = mant_grs[1];
        S = sticky_bit;
        
        case (rnd_mode_r2)
            3'd0: round_up = G & (R | S | val24[0]);
            3'd1: round_up = 1'b0;
            3'd2: round_up = res_sign_r & (G | R | S);
            3'd3: round_up = ~res_sign_r & (G | R | S);
            3'd4: round_up = G;
            default: round_up = 1'b0;
        endcase
        
        {carry_out, rounded_val} = val24 + {23'b0, round_up};
        
        if (carry_out) begin
            true_exp_final = true_exp_p_r2 - 121 + msb_pos + 1;
        end else begin
            true_exp_final = true_exp_p_r2 - 121 + msb_pos;
        end
        
        is_inexact = G | R | S;
        is_overflow = true_exp_final > 127;
        is_tiny = true_exp_final < -126;
        is_underflow = is_tiny & is_inexact;
        
        if (invalid_op_r2 || nan_result_r2) begin
            final_result = 32'h7FC00000;
            f_invalid = invalid_op_r2;
            f_overflow = 0;
            f_underflow = 0;
            f_inexact = 0;
        end else if (is_zero_res_r) begin
            final_result = {zero_sign_r, 31'b0};
            f_invalid = 0;
            f_overflow = 0;
            f_underflow = 0;
            f_inexact = 0;
        end else if (is_overflow) begin
            final_result = {res_sign_r, 8'hFF, 23'b0};
            f_invalid = 0;
            f_overflow = 1;
            f_underflow = 0;
            f_inexact = 1;
        end else if (is_tiny) begin
            int shift = -126 - true_exp_final;
            logic [23:0] sub_frac;
            sub_frac = rounded_val >> ((shift > 24) ? 24 : shift);
            final_result = {res_sign_r, 8'h00, sub_frac[22:0]};
            f_invalid = 0;
            f_overflow = 0;
            f_underflow = is_underflow;
            f_inexact = is_inexact;
        end else begin
            final_result = {res_sign_r, true_exp_final + 127, rounded_val[22:0]};
            f_invalid = 0;
            f_overflow = 0;
            f_underflow = 0;
            f_inexact = is_inexact;
        end
    end

    // Stage 3 Registers
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result_r <= 0;
            flag_invalid_r <= 0;
            flag_overflow_r <= 0;
            flag_underflow_r <= 0;
            flag_inexact_r <= 0;
        end else if (v2) begin
            result_r <= final_result;
            flag_invalid_r <= f_invalid;
            flag_overflow_r <= f_overflow;
            flag_underflow_r <= f_underflow;
            flag_inexact_r <= f_inexact;
        end else begin
            result_r <= 0;
            flag_invalid_r <= 0;
            flag_overflow_r <= 0;
            flag_underflow_r <= 0;
            flag_inexact_r <= 0;
        end
    end

endmodule