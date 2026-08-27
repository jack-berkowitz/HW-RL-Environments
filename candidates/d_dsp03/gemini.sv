// =============================================================================
// fp_multifmt_fma.sv
//
// A purely synthesizable multi-format, vectorized IEEE-754 FMA.
// Supports FP32, FP16, and BF16 in SIMD arrangements while respecting the
// bit-exact floating-point arithmetic rules, precise underflow logic, and NaN
// conventions established in the d_ai04 contract.
// =============================================================================

`timescale 1ns/1ps

module fma_lane (
    input  logic [31:0] a,
    input  logic [31:0] b,
    input  logic [31:0] c,
    input  logic [1:0]  fmt,
    input  logic [2:0]  rnd_mode,
    output logic [31:0] result,
    output logic [4:0]  flags
);
    localparam int L = 96;
    localparam int SHIFT_MAX = 28;

    logic a_sign, b_sign, c_sign;
    logic [7:0] a_exp, b_exp, c_exp;
    logic [22:0] a_sig, b_sig, c_sig;
    
    always_comb begin
        if (fmt == 0) begin
            a_sign = a[31]; a_exp = a[30:23]; a_sig = a[22:0];
            b_sign = b[31]; b_exp = b[30:23]; b_sig = b[22:0];
            c_sign = c[31]; c_exp = c[30:23]; c_sig = c[22:0];
        end else if (fmt == 1) begin
            a_sign = a[15]; a_exp = {3'b0, a[14:10]}; a_sig = {a[9:0], 13'b0};
            b_sign = b[15]; b_exp = {3'b0, b[14:10]}; b_sig = {b[9:0], 13'b0};
            c_sign = c[15]; c_exp = {3'b0, c[14:10]}; c_sig = {c[9:0], 13'b0};
        end else begin
            a_sign = a[15]; a_exp = a[14:7]; a_sig = {a[6:0], 16'b0};
            b_sign = b[15]; b_exp = b[14:7]; b_sig = {b[6:0], 16'b0};
            c_sign = c[15]; c_exp = c[14:7]; c_sig = {c[6:0], 16'b0};
        end
    end

    logic [7:0] MAX_EXP;
    always_comb begin
        if (fmt == 1) MAX_EXP = 31;
        else MAX_EXP = 255;
    end

    logic a_is_zero, b_is_zero, c_is_zero;
    assign a_is_zero = (a_exp == 0) && (a_sig == 0);
    assign b_is_zero = (b_exp == 0) && (b_sig == 0);
    assign c_is_zero = (c_exp == 0) && (c_sig == 0);

    logic a_is_inf, b_is_inf, c_is_inf;
    assign a_is_inf = (a_exp == MAX_EXP) && (a_sig == 0);
    assign b_is_inf = (b_exp == MAX_EXP) && (b_sig == 0);
    assign c_is_inf = (c_exp == MAX_EXP) && (c_sig == 0);

    logic a_is_nan, b_is_nan, c_is_nan;
    assign a_is_nan = (a_exp == MAX_EXP) && (a_sig != 0);
    assign b_is_nan = (b_exp == MAX_EXP) && (b_sig != 0);
    assign c_is_nan = (c_exp == MAX_EXP) && (c_sig != 0);

    logic a_is_snan, b_is_snan, c_is_snan;
    assign a_is_snan = a_is_nan && (a_sig[22] == 1'b0);
    assign b_is_snan = b_is_nan && (b_sig[22] == 1'b0);
    assign c_is_snan = c_is_nan && (c_sig[22] == 1'b0);

    logic [7:0] BIAS;
    always_comb begin
        if (fmt == 1) BIAS = 15;
        else BIAS = 127;
    end

    logic signed [15:0] a_e, b_e, c_e;
    assign a_e = (a_exp == 0) ? 1 - {8'b0, BIAS} : {8'b0, a_exp} - {8'b0, BIAS};
    assign b_e = (b_exp == 0) ? 1 - {8'b0, BIAS} : {8'b0, b_exp} - {8'b0, BIAS};
    assign c_e = (c_exp == 0) ? 1 - {8'b0, BIAS} : {8'b0, c_exp} - {8'b0, BIAS};

    logic [23:0] a_sig_ext, b_sig_ext, c_sig_ext;
    assign a_sig_ext = (a_exp == 0) ? {1'b0, a_sig} : {1'b1, a_sig};
    assign b_sig_ext = (b_exp == 0) ? {1'b0, b_sig} : {1'b1, b_sig};
    assign c_sig_ext = (c_exp == 0) ? {1'b0, c_sig} : {1'b1, c_sig};

    logic [47:0] p_val;
    logic p_sign;
    logic signed [15:0] p_e;
    assign p_val = (a_is_zero || b_is_zero) ? '0 : (a_sig_ext * b_sig_ext);
    assign p_sign = a_sign ^ b_sign;
    assign p_e = a_e + b_e;

    logic signed [15:0] E_P, E_C, E_max, E_align;
    assign E_P = p_e - 46;
    assign E_C = c_e - 23;

    logic p_val_zero, c_val_zero;
    assign p_val_zero = (p_val == 0);
    assign c_val_zero = (c_sig_ext == 0);

    logic signed [15:0] E_min_norm, E_min_limit, E_max_norm;
    always_comb begin
        if (fmt == 1) begin
            E_min_norm = -14;
            E_min_limit = -24;
            E_max_norm = 15;
        end else begin
            E_min_norm = -126;
            if (fmt == 0) E_min_limit = -149;
            else E_min_limit = -133;
            E_max_norm = 127;
        end
    end

    logic signed [15:0] max_PC;
    always_comb begin
        max_PC = (E_P > E_C) ? E_P : E_C;
        if (p_val_zero && c_val_zero) E_max = E_min_limit;
        else if (p_val_zero) E_max = (E_C > E_min_limit) ? E_C : E_min_limit;
        else if (c_val_zero) E_max = (E_P > E_min_limit) ? E_P : E_min_limit;
        else E_max = (max_PC > E_min_limit) ? max_PC : E_min_limit;
    end

    assign E_align = E_max - SHIFT_MAX;
    
    logic signed [15:0] P_shift, C_shift;
    assign P_shift = E_P - E_align;
    assign C_shift = E_C - E_align;

    logic [L-1:0] p_aligned;
    logic p_sticky;
    logic [127:0] p_mask;
    logic [15:0] R_P;
    
    always_comb begin
        p_mask = 0; R_P = 0;
        if (p_val_zero) begin
            p_aligned = 0;
            p_sticky = 0;
        end else if (P_shift >= 0) begin
            p_aligned = L'(p_val) << P_shift;
            p_sticky = 0;
        end else begin
            R_P = -P_shift;
            if (R_P >= 48) begin
                p_aligned = 0;
                p_sticky = 1;
            end else begin
                p_aligned = L'(p_val) >> R_P;
                p_mask = (128'b1 << R_P) - 1;
                p_sticky = (p_val & p_mask) != 0;
            end
        end
    end

    logic [L-1:0] c_aligned;
    logic c_sticky;
    logic [127:0] c_mask;
    logic [15:0] R_C;
    
    always_comb begin
        c_mask = 0; R_C = 0;
        if (c_val_zero) begin
            c_aligned = 0;
            c_sticky = 0;
        end else if (C_shift >= 0) begin
            c_aligned = L'(c_sig_ext) << C_shift;
            c_sticky = 0;
        end else begin
            R_C = -C_shift;
            if (R_C >= 24) begin
                c_aligned = 0;
                c_sticky = 1;
            end else begin
                c_aligned = L'(c_sig_ext) >> R_C;
                c_mask = (128'b1 << R_C) - 1;
                c_sticky = (c_sig_ext & c_mask) != 0;
            end
        end
    end

    logic [L+2:0] p_full, c_full;
    assign p_full = {1'b0, p_aligned, p_sticky};
    assign c_full = {1'b0, c_aligned, c_sticky};

    logic [L+2:0] p_tc_full, c_tc_full, sum_tc_full;
    assign p_tc_full = p_sign ? (~p_full + 1'b1) : p_full;
    assign c_tc_full = c_sign ? (~c_full + 1'b1) : c_full;

    assign sum_tc_full = p_tc_full + c_tc_full;

    logic sum_sign;
    logic [L+2:0] sum_mag_full;
    logic [L+1:0] sum_mag;
    logic sum_sticky;

    assign sum_sign = sum_tc_full[L+2];
    assign sum_mag_full = sum_sign ? (~sum_tc_full + 1'b1) : sum_tc_full;
    
    assign sum_mag = sum_mag_full[L+2:1];
    assign sum_sticky = sum_mag_full[0];

    logic [7:0] lz;
    integer i;
    always_comb begin
        lz = 0;
        for (i = L+1; i >= 0; i--) begin
            if (sum_mag[i]) break;
            lz++;
        end
    end

    logic is_exact_zero;
    assign is_exact_zero = (sum_mag == 0) && (sum_sticky == 0);

    logic signed [15:0] E_res;
    assign E_res = E_align + (L+1) - {8'b0, lz};

    logic signed [15:0] E_norm;
    logic [7:0] actual_shift;
    
    always_comb begin
        if (E_res < E_min_norm) begin
            E_norm = E_min_norm;
            actual_shift = ((L+1) - E_norm + E_align) & 8'hFF;
        end else begin
            E_norm = E_res;
            actual_shift = lz;
        end
    end

    logic [L+1:0] sum_shifted;
    assign sum_shifted = sum_mag << actual_shift;

    logic [22:0] frac_bits;
    logic G, R, S;
    logic [127:0] s_mask;
    always_comb begin
        s_mask = 0;
        if (fmt == 0) begin
            frac_bits = sum_shifted[L : L - 22];
            G = sum_shifted[L - 23];
            R = sum_shifted[L - 24];
            s_mask = (128'b1 << (L - 24)) - 1;
            S = ((sum_shifted & s_mask) != 0) | sum_sticky;
        end else if (fmt == 1) begin
            frac_bits = {sum_shifted[L : L - 9], 13'b0};
            G = sum_shifted[L - 10];
            R = sum_shifted[L - 11];
            s_mask = (128'b1 << (L - 11)) - 1;
            S = ((sum_shifted & s_mask) != 0) | sum_sticky;
        end else begin
            frac_bits = {sum_shifted[L : L - 6], 16'b0};
            G = sum_shifted[L - 7];
            R = sum_shifted[L - 8];
            s_mask = (128'b1 << (L - 8)) - 1;
            S = ((sum_shifted & s_mask) != 0) | sum_sticky;
        end
    end

    logic any_nan, any_snan, inf_times_zero, prod_is_inf, inf_minus_inf, is_invalid;
    assign any_nan = a_is_nan | b_is_nan | c_is_nan;
    assign any_snan = a_is_snan | b_is_snan | c_is_snan;
    assign inf_times_zero = (a_is_inf & b_is_zero) | (a_is_zero & b_is_inf);
    assign prod_is_inf = a_is_inf | b_is_inf;
    assign inf_minus_inf = prod_is_inf & c_is_inf & (p_sign != c_sign);
    assign is_invalid = any_snan | inf_times_zero | inf_minus_inf;

    logic sign_computed;
    always_comb begin
        if (is_exact_zero) begin
            if (p_sign == c_sign) sign_computed = p_sign;
            else if (rnd_mode == 2) sign_computed = 1'b1;
            else sign_computed = 1'b0;
        end else begin
            sign_computed = sum_sign;
        end
    end

    logic round_up;
    always_comb begin
        round_up = 1'b0;
        case (rnd_mode)
            3'd0: round_up = G & (R | S | frac_bits[0]);
            3'd1: round_up = 1'b0;
            3'd2: round_up = sign_computed & (G | R | S);
            3'd3: round_up = ~sign_computed & (G | R | S);
            3'd4: round_up = G;
            default: round_up = 1'b0;
        endcase
    end

    logic [24:0] round_add;
    always_comb begin
        if (round_up) begin
            if (fmt == 0) round_add = 25'd1;
            else if (fmt == 1) round_add = 25'd1 << 13;
            else round_add = 25'd1 << 16;
        end else begin
            round_add = 25'd0;
        end
    end

    logic [24:0] mant_rounded;
    assign mant_rounded = {1'b0, sum_shifted[L+1], frac_bits} + round_add;

    logic [22:0] final_frac;
    logic signed [15:0] final_exp;
    logic is_inexact;

    assign is_inexact = G | R | S;

    always_comb begin
        if (mant_rounded[24]) begin
            final_frac = mant_rounded[23:1];
            final_exp = E_norm + 1;
        end else begin
            final_frac = mant_rounded[22:0];
            final_exp = E_norm;
        end
    end

    logic is_overflow;
    assign is_overflow = (final_exp > E_max_norm);

    logic [22:0] max_frac;
    always_comb begin
        if (fmt == 0) max_frac = 23'h7FFFFF;
        else if (fmt == 1) max_frac = {10'h3FF, 13'h0};
        else max_frac = {7'h7F, 16'h0};
    end

    logic [7:0] out_exp;
    logic [22:0] out_frac;
    logic final_sign;

    always_comb begin
        if (is_invalid || any_nan) begin
            out_exp = MAX_EXP;
            if (fmt == 0) out_frac = 23'h400000;
            else if (fmt == 1) out_frac = {10'h200, 13'h0};
            else out_frac = {7'h40, 16'h0};
            final_sign = 1'b0; 
        end else if (prod_is_inf || c_is_inf) begin
            out_exp = MAX_EXP;
            out_frac = 0;
            final_sign = prod_is_inf ? p_sign : c_sign;
        end else if (is_exact_zero) begin
            out_exp = 0;
            out_frac = 0;
            final_sign = sign_computed;
        end else if (is_overflow) begin
            final_sign = sign_computed;
            case (rnd_mode)
                3'd0, 3'd4: begin
                    out_exp = MAX_EXP;
                    out_frac = 0;
                end
                3'd1: begin
                    out_exp = MAX_EXP - 1;
                    out_frac = max_frac;
                end
                3'd2: begin
                    if (final_sign) begin
                        out_exp = MAX_EXP;
                        out_frac = 0;
                    end else begin
                        out_exp = MAX_EXP - 1;
                        out_frac = max_frac;
                    end
                end
                3'd3: begin
                    if (!final_sign) begin
                        out_exp = MAX_EXP;
                        out_frac = 0;
                    end else begin
                        out_exp = MAX_EXP - 1;
                        out_frac = max_frac;
                    end
                end
                default: begin
                    out_exp = MAX_EXP;
                    out_frac = 0;
                end
            endcase
        end else begin
            final_sign = sign_computed;
            if (final_exp < E_min_norm) begin
                out_exp = 0;
                out_frac = final_frac;
            end else if (final_exp == E_min_norm && mant_rounded[23] == 1'b0) begin
                out_exp = 0;
                out_frac = final_frac;
            end else begin
                out_exp = final_exp + {8'b0, BIAS};
                out_frac = final_frac;
            end
        end
    end

    logic is_underflow;
    assign is_underflow = is_inexact && (out_exp == 0) && (!is_invalid) && (!any_nan) && (!is_exact_zero) && (!prod_is_inf) && (!c_is_inf);

    always_comb begin
        if (fmt == 0) begin
            result = {final_sign, out_exp[7:0], out_frac[22:0]};
        end else if (fmt == 1) begin
            result = {16'hFFFF, final_sign, out_exp[4:0], out_frac[22:13]};
        end else begin
            result = {16'hFFFF, final_sign, out_exp[7:0], out_frac[22:16]};
        end
    end

    assign flags[4] = is_invalid;
    assign flags[3] = 1'b0;
    assign flags[2] = is_overflow && (!is_invalid) && (!any_nan) && (!prod_is_inf) && (!c_is_inf);
    assign flags[1] = is_underflow;
    assign flags[0] = (is_inexact || flags[2]) && (!is_invalid) && (!any_nan) && (!prod_is_inf) && (!c_is_inf);

endmodule


module fp_multifmt_fma #(
  parameter int unsigned WIDTH = 64
) (
  input  logic             clk_i,
  input  logic             rst_ni,

  // ---- operation in ---------------------------------------------------------
  input  logic             in_valid_i,
  output logic             in_ready_o,
  input  logic [1:0]       fmt_i,          
  input  logic             vec_i,          
  input  logic [WIDTH-1:0] a_i,
  input  logic [WIDTH-1:0] b_i,
  input  logic [WIDTH-1:0] c_i,
  input  logic [2:0]       rnd_i,          

  // ---- result out -----------------------------------------------------------
  output logic             out_valid_o,
  input  logic             out_ready_i,
  output logic [WIDTH-1:0] result_o,
  output logic [4:0]       flags_o         
);

    logic stall;
    logic valid_q;
    
    assign stall = valid_q && !out_ready_i;
    assign in_ready_o = !stall;
    assign out_valid_o = valid_q;

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) valid_q <= 1'b0;
        else if (!stall) valid_q <= in_valid_i;
    end

    localparam int MAX_LANES = WIDTH / 16;
    
    logic [31:0] lane_a [MAX_LANES];
    logic [31:0] lane_b [MAX_LANES];
    logic [31:0] lane_c [MAX_LANES];
    logic [31:0] lane_res_comb [MAX_LANES];
    logic [4:0]  lane_flags_comb [MAX_LANES];
    logic [2:0]  num_lanes;
    
    integer i_idx;
    integer j_idx;

    always_comb begin
        for (i_idx = 0; i_idx < (WIDTH/16); i_idx++) begin
            lane_a[i_idx] = '0;
            lane_b[i_idx] = '0;
            lane_c[i_idx] = '0;
        end
        if (fmt_i == 0) begin
            lane_a[0] = a_i[31:0];
            lane_b[0] = b_i[31:0];
            lane_c[0] = c_i[31:0];
            if (WIDTH == 64) begin
                lane_a[1] = a_i[63:32];
                lane_b[1] = b_i[63:32];
                lane_c[1] = c_i[63:32];
            end
        end else begin
            lane_a[0] = {16'b0, a_i[15:0]};
            lane_b[0] = {16'b0, b_i[15:0]};
            lane_c[0] = {16'b0, c_i[15:0]};
            if (WIDTH >= 32) begin
                lane_a[1] = {16'b0, a_i[31:16]};
                lane_b[1] = {16'b0, b_i[31:16]};
                lane_c[1] = {16'b0, c_i[31:16]};
            end
            if (WIDTH == 64) begin
                lane_a[2] = {16'b0, a_i[47:32]};
                lane_b[2] = {16'b0, b_i[47:32]};
                lane_c[2] = {16'b0, c_i[47:32]};
                lane_a[3] = {16'b0, a_i[63:48]};
                lane_b[3] = {16'b0, b_i[63:48]};
                lane_c[3] = {16'b0, c_i[63:48]};
            end
        end
    end

    always_comb begin
        if (vec_i) begin
            if (fmt_i == 0) num_lanes = (WIDTH == 64) ? 3'd2 : 3'd1;
            else num_lanes = (WIDTH == 64) ? 3'd4 : 3'd2;
        end else begin
            num_lanes = 3'd1;
        end
    end

    for (genvar i = 0; i < MAX_LANES; i++) begin : gen_lanes
        fma_lane u_lane (
            .a(lane_a[i]),
            .b(lane_b[i]),
            .c(lane_c[i]),
            .fmt(fmt_i),
            .rnd_mode(rnd_i),
            .result(lane_res_comb[i]),
            .flags(lane_flags_comb[i])
        );
    end

    logic [WIDTH-1:0] result_comb;
    logic [4:0] flags_comb;

    always_comb begin
        result_comb = {WIDTH{1'b1}}; 
        flags_comb = 0;
        
        for (j_idx = 0; j_idx < (WIDTH/16); j_idx++) begin
            if (j_idx < num_lanes) begin
                if (fmt_i == 0) begin
                    if (WIDTH == 64) begin
                        if (j_idx == 0) result_comb[31:0] = lane_res_comb[j_idx];
                        else if (j_idx == 1) result_comb[63:32] = lane_res_comb[j_idx];
                    end else begin
                        if (j_idx == 0) result_comb[31:0] = lane_res_comb[j_idx];
                    end
                end else begin
                    if (j_idx == 0) result_comb[15:0] = lane_res_comb[j_idx][15:0];
                    else if (j_idx == 1) result_comb[31:16] = lane_res_comb[j_idx][15:0];
                    else if (WIDTH == 64 && j_idx == 2) result_comb[47:32] = lane_res_comb[j_idx][15:0];
                    else if (WIDTH == 64 && j_idx == 3) result_comb[63:48] = lane_res_comb[j_idx][15:0];
                end
                flags_comb |= lane_flags_comb[j_idx];
            end
        end
    end

    logic [WIDTH-1:0] result_q;
    logic [4:0] flags_q;

    always_ff @(posedge clk_i) begin
        if (!stall && in_valid_i) begin
            result_q <= result_comb;
            flags_q  <= flags_comb;
        end
    end

    assign result_o = result_q;
    assign flags_o = flags_q;

endmodule