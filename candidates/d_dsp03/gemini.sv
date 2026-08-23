// =============================================================================
// fp_multifmt_fma  --  IMPLEMENTATION
// =============================================================================

`timescale 1ns/1ps

module fp_multifmt_fma #(
  parameter int unsigned WIDTH = 64        // {32, 64}
) (
  input  logic             clk_i,
  input  logic             rst_ni,         // active low

  // ---- operation in ---------------------------------------------------------
  input  logic             in_valid_i,
  output logic             in_ready_o,
  input  logic [1:0]       fmt_i,          // 0 = FP32, 1 = FP16, 2 = BF16
  input  logic             vec_i,          // 1 = packed SIMD lanes
  input  logic [WIDTH-1:0] a_i,
  input  logic [WIDTH-1:0] b_i,
  input  logic [WIDTH-1:0] c_i,
  input  logic [2:0]       rnd_i,          // 0 RNE, 1 RTZ, 2 RDN, 3 RUP, 4 RMM

  // ---- result out -----------------------------------------------------------
  output logic             out_valid_o,
  input  logic             out_ready_i,
  output logic [WIDTH-1:0] result_o,
  output logic [4:0]       flags_o         // {NV, DZ, OF, UF, NX}
);

    // -------------------------------------------------------------------------
    // Helper Functions
    // -------------------------------------------------------------------------
    function automatic logic [4:0] lzcnt24(input logic [23:0] val);
        int i;
        logic [4:0] res;
        res = 5'd24;
        for (i = 23; i >= 0; i--) begin
            if (val[i]) begin
                res = 5'(23 - i);
                break;
            end
        end
        return res;
    endfunction

    function automatic logic [6:0] lzcnt77(input logic [76:0] val);
        int i;
        logic [6:0] res;
        res = 7'd77;
        for (i = 76; i >= 0; i--) begin
            if (val[i]) begin
                res = 7'(76 - i);
                break;
            end
        end
        return res;
    endfunction

    // -------------------------------------------------------------------------
    // Shared FMA Core Logic per Lane
    // -------------------------------------------------------------------------
    function automatic logic [36:0] do_fma(
        input logic [1:0] fmt,
        input logic [2:0] rnd,
        input logic [31:0] a,
        input logic [31:0] b,
        input logic [31:0] c
    );
        // Ensure all variables are declared at the top of the block
        logic sign_a, sign_b, sign_c;
        logic is_zero_a, is_sub_a, is_inf_a, is_nan_a, is_snan_a;
        logic is_zero_b, is_sub_b, is_inf_b, is_nan_b, is_snan_b;
        logic is_zero_c, is_sub_c, is_inf_c, is_nan_c, is_snan_c;
        logic [4:0] lz_a, lz_b, lz_c;
        logic [23:0] mant_norm_a, mant_norm_b, mant_norm_c;
        logic signed [12:0] exp_unb_a, exp_unb_b, exp_unb_c;
        logic [47:0] p_mant_full;
        logic signed [12:0] p_exp;
        logic p_sign;
        logic p_is_zero;
        logic [74:0] v_p, v_c;
        logic signed [13:0] e_diff;
        logic [13:0] shift_amt;
        logic [74:0] ones_75;
        logic [74:0] v_p_shift, v_c_shift;
        logic v_p_sticky, v_c_sticky;
        logic signed [12:0] e_max;
        logic [75:0] p_val, c_val;
        logic [76:0] sum;
        logic sum_sign;
        logic exact_zero;
        logic [6:0] sum_lza;
        logic [76:0] sum_norm;
        logic signed [13:0] e_target;
        logic signed [13:0] e_bias;
        logic [76:0] sum_shifted;
        logic [7:0] final_exp;
        logic extra_sticky;
        logic [76:0] ones_77;
        logic [13:0] shift_right;
        logic [22:0] unrounded_frac;
        logic guard_bit, round_bit, sticky_bit, LSB;
        logic round_up;
        logic [23:0] pre_round_mant;
        logic [24:0] post_round_mant;
        logic [22:0] final_mant;
        logic mant_ovf, mant_became_normal;
        logic [7:0] packed_exp;
        logic overflow, inexact, underflow;
        logic [7:0] max_exp_val;
        logic [22:0] max_mant;
        logic p_is_nan, is_inv_mul, is_inv_add, is_invalid, is_nan_res, is_inf_res, inf_sign;
        logic [31:0] final_res;
        logic [4:0] final_flags;

        ones_75 = {75{1'b1}};
        ones_77 = {77{1'b1}};

        // Decode operands based on format
        if (fmt == 0) begin
            sign_a = a[31]; is_zero_a = (a[30:23] == 0) && (a[22:0] == 0); is_sub_a = (a[30:23] == 0) && (a[22:0] != 0); is_inf_a = (a[30:23] == 255) && (a[22:0] == 0); is_nan_a = (a[30:23] == 255) && (a[22:0] != 0); is_snan_a = is_nan_a && (a[22] == 0);
            sign_b = b[31]; is_zero_b = (b[30:23] == 0) && (b[22:0] == 0); is_sub_b = (b[30:23] == 0) && (b[22:0] != 0); is_inf_b = (b[30:23] == 255) && (b[22:0] == 0); is_nan_b = (b[30:23] == 255) && (b[22:0] != 0); is_snan_b = is_nan_b && (b[22] == 0);
            sign_c = c[31]; is_zero_c = (c[30:23] == 0) && (c[22:0] == 0); is_sub_c = (c[30:23] == 0) && (c[22:0] != 0); is_inf_c = (c[30:23] == 255) && (c[22:0] == 0); is_nan_c = (c[30:23] == 255) && (c[22:0] != 0); is_snan_c = is_nan_c && (c[22] == 0);
            lz_a = lzcnt24({a[22:0], 1'b0}); exp_unb_a = is_zero_a ? -13'd1000 : (is_sub_a ? -13'd126 - {8'b0, lz_a} : {5'b0, a[30:23]} - 13'd127); mant_norm_a = is_zero_a ? 24'b0 : (is_sub_a ? {a[22:0], 1'b0} << lz_a : {1'b1, a[22:0]});
            lz_b = lzcnt24({b[22:0], 1'b0}); exp_unb_b = is_zero_b ? -13'd1000 : (is_sub_b ? -13'd126 - {8'b0, lz_b} : {5'b0, b[30:23]} - 13'd127); mant_norm_b = is_zero_b ? 24'b0 : (is_sub_b ? {b[22:0], 1'b0} << lz_b : {1'b1, b[22:0]});
            lz_c = lzcnt24({c[22:0], 1'b0}); exp_unb_c = is_zero_c ? -13'd1000 : (is_sub_c ? -13'd126 - {8'b0, lz_c} : {5'b0, c[30:23]} - 13'd127); mant_norm_c = is_zero_c ? 24'b0 : (is_sub_c ? {c[22:0], 1'b0} << lz_c : {1'b1, c[22:0]});
        end else if (fmt == 1) begin
            sign_a = a[15]; is_zero_a = (a[14:10] == 0) && (a[9:0] == 0); is_sub_a = (a[14:10] == 0) && (a[9:0] != 0); is_inf_a = (a[14:10] == 31) && (a[9:0] == 0); is_nan_a = (a[14:10] == 31) && (a[9:0] != 0); is_snan_a = is_nan_a && (a[9] == 0);
            sign_b = b[15]; is_zero_b = (b[14:10] == 0) && (b[9:0] == 0); is_sub_b = (b[14:10] == 0) && (b[9:0] != 0); is_inf_b = (b[14:10] == 31) && (b[9:0] == 0); is_nan_b = (b[14:10] == 31) && (b[9:0] != 0); is_snan_b = is_nan_b && (b[9] == 0);
            sign_c = c[15]; is_zero_c = (c[14:10] == 0) && (c[9:0] == 0); is_sub_c = (c[14:10] == 0) && (c[9:0] != 0); is_inf_c = (c[14:10] == 31) && (c[9:0] == 0); is_nan_c = (c[14:10] == 31) && (c[9:0] != 0); is_snan_c = is_nan_c && (c[9] == 0);
            lz_a = lzcnt24({a[9:0], 14'b0}); exp_unb_a = is_zero_a ? -13'd1000 : (is_sub_a ? -13'd14 - {8'b0, lz_a} : {8'b0, a[14:10]} - 13'd15); mant_norm_a = is_zero_a ? 24'b0 : (is_sub_a ? {a[9:0], 14'b0} << lz_a : {1'b1, a[9:0], 13'b0});
            lz_b = lzcnt24({b[9:0], 14'b0}); exp_unb_b = is_zero_b ? -13'd1000 : (is_sub_b ? -13'd14 - {8'b0, lz_b} : {8'b0, b[14:10]} - 13'd15); mant_norm_b = is_zero_b ? 24'b0 : (is_sub_b ? {b[9:0], 14'b0} << lz_b : {1'b1, b[9:0], 13'b0});
            lz_c = lzcnt24({c[9:0], 14'b0}); exp_unb_c = is_zero_c ? -13'd1000 : (is_sub_c ? -13'd14 - {8'b0, lz_c} : {8'b0, c[14:10]} - 13'd15); mant_norm_c = is_zero_c ? 24'b0 : (is_sub_c ? {c[9:0], 14'b0} << lz_c : {1'b1, c[9:0], 13'b0});
        end else begin
            sign_a = a[15]; is_zero_a = (a[14:7] == 0) && (a[6:0] == 0); is_sub_a = (a[14:7] == 0) && (a[6:0] != 0); is_inf_a = (a[14:7] == 255) && (a[6:0] == 0); is_nan_a = (a[14:7] == 255) && (a[6:0] != 0); is_snan_a = is_nan_a && (a[6] == 0);
            sign_b = b[15]; is_zero_b = (b[14:7] == 0) && (b[6:0] == 0); is_sub_b = (b[14:7] == 0) && (b[6:0] != 0); is_inf_b = (b[14:7] == 255) && (b[6:0] == 0); is_nan_b = (b[14:7] == 255) && (b[6:0] != 0); is_snan_b = is_nan_b && (b[6] == 0);
            sign_c = c[15]; is_zero_c = (c[14:7] == 0) && (c[6:0] == 0); is_sub_c = (c[14:7] == 0) && (c[6:0] != 0); is_inf_c = (c[14:7] == 255) && (c[6:0] == 0); is_nan_c = (c[14:7] == 255) && (c[6:0] != 0); is_snan_c = is_nan_c && (c[6] == 0);
            lz_a = lzcnt24({a[6:0], 17'b0}); exp_unb_a = is_zero_a ? -13'd1000 : (is_sub_a ? -13'd126 - {8'b0, lz_a} : {5'b0, a[14:7]} - 13'd127); mant_norm_a = is_zero_a ? 24'b0 : (is_sub_a ? {a[6:0], 17'b0} << lz_a : {1'b1, a[6:0], 16'b0});
            lz_b = lzcnt24({b[6:0], 17'b0}); exp_unb_b = is_zero_b ? -13'd1000 : (is_sub_b ? -13'd126 - {8'b0, lz_b} : {5'b0, b[14:7]} - 13'd127); mant_norm_b = is_zero_b ? 24'b0 : (is_sub_b ? {b[6:0], 17'b0} << lz_b : {1'b1, b[6:0], 16'b0});
            lz_c = lzcnt24({c[6:0], 17'b0}); exp_unb_c = is_zero_c ? -13'd1000 : (is_sub_c ? -13'd126 - {8'b0, lz_c} : {5'b0, c[14:7]} - 13'd127); mant_norm_c = is_zero_c ? 24'b0 : (is_sub_c ? {c[6:0], 17'b0} << lz_c : {1'b1, c[6:0], 16'b0});
        end

        // Exact Product
        p_mant_full = mant_norm_a * mant_norm_b;
        p_exp = exp_unb_a + exp_unb_b;
        p_sign = sign_a ^ sign_b;
        p_is_zero = is_zero_a | is_zero_b;

        // Alignment
        v_p = {2'b0, p_mant_full, 25'b0};
        v_c = {3'b0, mant_norm_c, 48'b0};
        e_diff = p_exp - exp_unb_c;

        if (e_diff >= 0) begin
            shift_amt = e_diff;
            e_max = p_exp;
            v_p_shift = v_p;
            v_p_sticky = 0;
            if (shift_amt >= 75) begin
                v_c_shift = 0;
                v_c_sticky = (v_c != 0);
            end else begin
                v_c_shift = v_c >> shift_amt;
                v_c_sticky = |(v_c & ~(ones_75 << shift_amt));
            end
        end else begin
            shift_amt = -e_diff;
            e_max = exp_unb_c;
            v_c_shift = v_c;
            v_c_sticky = 0;
            if (shift_amt >= 75) begin
                v_p_shift = 0;
                v_p_sticky = (v_p != 0);
            end else begin
                v_p_shift = v_p >> shift_amt;
                v_p_sticky = |(v_p & ~(ones_75 << shift_amt));
            end
        end

        // Exact Addition
        p_val = {v_p_shift, v_p_sticky};
        c_val = {v_c_shift, v_c_sticky};

        if (p_sign == sign_c) begin
            sum = p_val + c_val;
            sum_sign = p_sign;
            exact_zero = (sum == 0);
        end else begin
            if (p_val >= c_val) begin
                sum = p_val - c_val;
                sum_sign = p_sign;
                exact_zero = (sum == 0);
            end else begin
                sum = c_val - p_val;
                sum_sign = sign_c;
                exact_zero = (sum == 0);
            end
        end

        if (exact_zero) begin
            if (p_sign == sign_c) sum_sign = p_sign;
            else sum_sign = (rnd == 3'd2) ? 1'b1 : 1'b0;
        end

        // Normalization
        sum_lza = lzcnt77(sum);
        sum_norm = sum << sum_lza;
        e_target = e_max + 14'd3 - {7'b0, sum_lza};

        if (fmt == 0 || fmt == 2) e_bias = e_target + 14'd127;
        else e_bias = e_target + 14'd15;

        if (exact_zero) begin
            sum_shifted = 0;
            final_exp = 0;
            extra_sticky = 0;
        end else if (e_bias <= 0) begin
            shift_right = 14'd1 - e_bias;
            if (shift_right >= 77) begin
                sum_shifted = 0;
                extra_sticky = (sum_norm != 0);
            end else begin
                sum_shifted = sum_norm >> shift_right;
                extra_sticky = |(sum_norm & ~(ones_77 << shift_right));
            end
            final_exp = 0;
        end else begin
            sum_shifted = sum_norm;
            final_exp = e_bias[7:0];
            extra_sticky = 0;
        end

        // Rounding
        if (fmt == 0) begin
            unrounded_frac = sum_shifted[75:53]; guard_bit = sum_shifted[52]; round_bit = sum_shifted[51]; sticky_bit = (|sum_shifted[50:0]) | extra_sticky; LSB = sum_shifted[53];
        end else if (fmt == 1) begin
            unrounded_frac = {sum_shifted[75:66], 13'b0}; guard_bit = sum_shifted[65]; round_bit = sum_shifted[64]; sticky_bit = (|sum_shifted[63:0]) | extra_sticky; LSB = sum_shifted[66];
        end else begin
            unrounded_frac = {sum_shifted[75:69], 16'b0}; guard_bit = sum_shifted[68]; round_bit = sum_shifted[67]; sticky_bit = (|sum_shifted[66:0]) | extra_sticky; LSB = sum_shifted[69];
        end

        case (rnd)
            3'd0: round_up = guard_bit & (round_bit | sticky_bit | LSB);
            3'd1: round_up = 1'b0;
            3'd2: round_up = sum_sign & (guard_bit | round_bit | sticky_bit);
            3'd3: round_up = (~sum_sign) & (guard_bit | round_bit | sticky_bit);
            3'd4: round_up = guard_bit;
            default: round_up = 1'b0;
        endcase

        if (fmt == 0) begin
            pre_round_mant = {sum_shifted[76], unrounded_frac[22:0]};
            post_round_mant = {1'b0, pre_round_mant} + {24'b0, round_up};
        end else if (fmt == 1) begin
            pre_round_mant = {13'b0, sum_shifted[76], unrounded_frac[22:13]};
            post_round_mant = {1'b0, pre_round_mant} + {24'b0, round_up};
        end else begin
            pre_round_mant = {16'b0, sum_shifted[76], unrounded_frac[22:16]};
            post_round_mant = {1'b0, pre_round_mant} + {24'b0, round_up};
        end

        if (fmt == 0) begin final_mant = post_round_mant[22:0]; mant_ovf = post_round_mant[24]; mant_became_normal = (final_exp == 0) && post_round_mant[23]; end
        else if (fmt == 1) begin final_mant = {post_round_mant[9:0], 13'b0}; mant_ovf = post_round_mant[11]; mant_became_normal = (final_exp == 0) && post_round_mant[10]; end
        else begin final_mant = {post_round_mant[6:0], 16'b0}; mant_ovf = post_round_mant[8]; mant_became_normal = (final_exp == 0) && post_round_mant[7]; end

        packed_exp = final_exp;
        if (mant_ovf) packed_exp = packed_exp + 1;
        else if (mant_became_normal) packed_exp = 1;

        overflow = 0;
        inexact = (guard_bit | round_bit | sticky_bit) != 0;

        if (fmt == 0 || fmt == 2) max_exp_val = 255;
        else max_exp_val = 31;

        if (fmt == 0) max_mant = 23'h7FFFFF;
        else if (fmt == 1) max_mant = {10'h3FF, 13'b0};
        else max_mant = {7'h7F, 16'b0};

        if (packed_exp >= max_exp_val) begin
            overflow = 1;
            inexact = 1;
            case (rnd)
                3'd0, 3'd4: begin packed_exp = max_exp_val; final_mant = 0; end
                3'd1: begin packed_exp = max_exp_val - 1; final_mant = max_mant; end
                3'd2: begin if (sum_sign) begin packed_exp = max_exp_val; final_mant = 0; end else begin packed_exp = max_exp_val - 1; final_mant = max_mant; end end
                3'd3: begin if (!sum_sign) begin packed_exp = max_exp_val; final_mant = 0; end else begin packed_exp = max_exp_val - 1; final_mant = max_mant; end end
                default: begin packed_exp = max_exp_val; final_mant = 0; end
            endcase
        end

        underflow = inexact && (packed_exp == 0);

        // Special Case Exceptions
        p_is_nan = is_nan_a || is_nan_b;
        is_inv_mul = (is_zero_a && is_inf_b) || (is_inf_a && is_zero_b);
        is_inv_add = (is_inf_a || is_inf_b) && is_inf_c && (p_sign != sign_c);
        is_invalid = is_snan_a || is_snan_b || is_snan_c || is_inv_mul || is_inv_add;
        is_nan_res = p_is_nan || is_nan_c || is_inv_mul || is_inv_add;
        is_inf_res = (is_inf_a || is_inf_b || is_inf_c) && !is_nan_res;
        inf_sign = (is_inf_a || is_inf_b) ? p_sign : sign_c;

        if (is_nan_res) begin
            if (fmt == 0) final_res = 32'h7FC00000;
            else if (fmt == 1) final_res = {16'b0, 16'h7E00};
            else final_res = {16'b0, 16'h7FC0};
            final_flags = {is_invalid, 1'b0, 1'b0, 1'b0, 1'b0};
        end else if (is_inf_res) begin
            if (fmt == 0) final_res = {inf_sign, 8'hFF, 23'h0};
            else if (fmt == 1) final_res = {16'b0, inf_sign, 5'h1F, 10'h0};
            else final_res = {16'b0, inf_sign, 8'hFF, 7'h0};
            final_flags = {is_invalid, 1'b0, 1'b0, 1'b0, 1'b0};
        end else begin
            if (fmt == 0) final_res = {sum_sign, packed_exp[7:0], final_mant[22:0]};
            else if (fmt == 1) final_res = {16'b0, sum_sign, packed_exp[4:0], final_mant[22:13]};
            else final_res = {16'b0, sum_sign, packed_exp[7:0], final_mant[22:16]};
            final_flags = {is_invalid, 1'b0, overflow, underflow, inexact};
        end

        return {final_flags, final_res};
    endfunction

    // -------------------------------------------------------------------------
    // Datapath & Vector Lane Instantiation
    // -------------------------------------------------------------------------
    logic [WIDTH-1:0] result_comb;
    logic [4:0]       flags_comb;

    always_comb begin
        int k;
        logic active;
        logic [31:0] op_a, op_b, op_c;
        logic [36:0] res;

        // Default: Box unused lanes with 1s and zero flags
        result_comb = {WIDTH{1'b1}};
        flags_comb  = 5'b0;

        for (k = 0; k < WIDTH/16; k++) begin
            active = 1'b0;
            op_a = 0; op_b = 0; op_c = 0;
            res = 0;

            if (fmt_i == 0) active = vec_i ? (k < WIDTH/32) : (k == 0);
            else active = vec_i ? (k < WIDTH/16) : (k == 0);

            if (active) begin
                if (fmt_i == 0) begin
                    if (WIDTH == 64) begin
                        op_a = (k == 0) ? a_i[31:0] : ((k == 1) ? a_i[63:32] : 32'b0);
                        op_b = (k == 0) ? b_i[31:0] : ((k == 1) ? b_i[63:32] : 32'b0);
                        op_c = (k == 0) ? c_i[31:0] : ((k == 1) ? c_i[63:32] : 32'b0);
                    end else begin
                        op_a = a_i[31:0]; op_b = b_i[31:0]; op_c = c_i[31:0];
                    end
                end else begin
                    if (WIDTH == 64) begin
                        op_a = (k == 0) ? {16'b0, a_i[15:0]} : ((k == 1) ? {16'b0, a_i[31:16]} : ((k == 2) ? {16'b0, a_i[47:32]} : {16'b0, a_i[63:48]}));
                        op_b = (k == 0) ? {16'b0, b_i[15:0]} : ((k == 1) ? {16'b0, b_i[31:16]} : ((k == 2) ? {16'b0, b_i[47:32]} : {16'b0, b_i[63:48]}));
                        op_c = (k == 0) ? {16'b0, c_i[15:0]} : ((k == 1) ? {16'b0, c_i[31:16]} : ((k == 2) ? {16'b0, c_i[47:32]} : {16'b0, c_i[63:48]}));
                    end else begin
                        op_a = (k == 0) ? {16'b0, a_i[15:0]} : ((k == 1) ? {16'b0, a_i[31:16]} : 32'b0);
                        op_b = (k == 0) ? {16'b0, b_i[15:0]} : ((k == 1) ? {16'b0, b_i[31:16]} : 32'b0);
                        op_c = (k == 0) ? {16'b0, c_i[15:0]} : ((k == 1) ? {16'b0, c_i[31:16]} : 32'b0);
                    end
                end

                res = do_fma(fmt_i, rnd_i, op_a, op_b, op_c);
                flags_comb |= res[36:32];

                if (fmt_i == 0) begin
                    if (WIDTH == 64) begin
                        if (k == 0) result_comb[31:0]  = res[31:0];
                        if (k == 1) result_comb[63:32] = res[31:0];
                    end else begin
                        if (k == 0) result_comb[31:0]  = res[31:0];
                    end
                end else begin
                    if (WIDTH == 64) begin
                        if (k == 0) result_comb[15:0]  = res[15:0];
                        if (k == 1) result_comb[31:16] = res[15:0];
                        if (k == 2) result_comb[47:32] = res[15:0];
                        if (k == 3) result_comb[63:48] = res[15:0];
                    end else begin
                        if (k == 0) result_comb[15:0]  = res[15:0];
                        if (k == 1) result_comb[31:16] = res[15:0];
                    end
                end
            end
        end
    end

    // -------------------------------------------------------------------------
    // Handshake and Reset logic
    // -------------------------------------------------------------------------
    assign result_o    = result_comb;
    assign flags_o     = flags_comb;

    // 0-cycle pass-through logic with safety interlock for reset. 
    assign in_ready_o  = out_ready_i;
    assign out_valid_o = in_valid_i & rst_ni;

endmodule