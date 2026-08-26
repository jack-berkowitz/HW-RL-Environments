// =============================================================================
// fp_multifmt_fma
// =============================================================================

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

    // =========================================================================
    // Generic FMA Function
    // =========================================================================
    function automatic logic [36:0] compute_fma(
        input logic [31:0] a,
        input logic [31:0] b,
        input logic [31:0] c,
        input logic [2:0]  rnd,
        input int          exp_w,
        input int          sig_w
    );
        int bias, p;
        logic a_sign, b_sign, c_sign;
        logic [7:0] a_exp, b_exp, c_exp;
        logic [23:0] a_sig, b_sig, c_sig;
        logic a_is_zero, a_is_sub, a_is_inf, a_is_nan, a_is_snan;
        logic b_is_zero, b_is_sub, b_is_inf, b_is_nan, b_is_snan;
        logic c_is_zero, c_is_sub, c_is_inf, c_is_nan, c_is_snan;
        logic p_is_zero, p_is_inf, p_sign;
        logic is_invalid, is_nan;
        logic [24:0] a_man, b_man, c_man;
        int a_exp_true, b_exp_true, c_exp_true;
        int E_p, E_c, eff_E_p, eff_E_c, max_E;
        int shift_P, shift_C;
        logic [49:0] p_man_mult;
        logic [95:0] P_wide, C_wide;
        logic [191:0] P_shifted_full, C_shifted_full;
        logic [95:0] P_aligned, C_aligned;
        logic P_sticky, C_sticky;
        logic [96:0] P_ext, C_ext, larger_ext, smaller_ext, sum_ext;
        logic p_larger, final_sign, eff_sub;
        logic [95:0] sum;
        logic sum_sticky;
        int L, E_res, target_E, idx_target, shift_amt;
        logic is_exact_zero, out_sign;
        logic [95:0] norm_sum, mantissa_aligned, lower_bits;
        logic [24:0] mantissa;
        logic guard, round_bit, sticky, round_up;
        logic [25:0] mantissa_ext;
        int final_exp;
        logic [24:0] final_man;
        logic flag_nv, flag_dz, flag_of, flag_uf, flag_nx;
        logic [31:0] result, temp_res;
        logic [7:0] final_exp_bits;
        logic [22:0] final_man_bits;
        logic max_normal;
        logic [23:0] max_man;

        bias = (1 << (exp_w - 1)) - 1;
        p = sig_w + 1;

        a_sign = (a >> (exp_w + sig_w)) & 1'b1;
        a_exp  = (a >> sig_w) & ((1 << exp_w) - 1);
        a_sig  = a & ((1 << sig_w) - 1);

        b_sign = (b >> (exp_w + sig_w)) & 1'b1;
        b_exp  = (b >> sig_w) & ((1 << exp_w) - 1);
        b_sig  = b & ((1 << sig_w) - 1);

        c_sign = (c >> (exp_w + sig_w)) & 1'b1;
        c_exp  = (c >> sig_w) & ((1 << exp_w) - 1);
        c_sig  = c & ((1 << sig_w) - 1);

        a_is_zero = (a_exp == 0) && (a_sig == 0);
        a_is_sub  = (a_exp == 0) && (a_sig != 0);
        a_is_inf  = (a_exp == ((1 << exp_w) - 1)) && (a_sig == 0);
        a_is_nan  = (a_exp == ((1 << exp_w) - 1)) && (a_sig != 0);
        a_is_snan = a_is_nan && ((a_sig & (1 << (sig_w - 1))) == 0);

        b_is_zero = (b_exp == 0) && (b_sig == 0);
        b_is_sub  = (b_exp == 0) && (b_sig != 0);
        b_is_inf  = (b_exp == ((1 << exp_w) - 1)) && (b_sig == 0);
        b_is_nan  = (b_exp == ((1 << exp_w) - 1)) && (b_sig != 0);
        b_is_snan = b_is_nan && ((b_sig & (1 << (sig_w - 1))) == 0);

        c_is_zero = (c_exp == 0) && (c_sig == 0);
        c_is_sub  = (c_exp == 0) && (c_sig != 0);
        c_is_inf  = (c_exp == ((1 << exp_w) - 1)) && (c_sig == 0);
        c_is_nan  = (c_exp == ((1 << exp_w) - 1)) && (c_sig != 0);
        c_is_snan = c_is_nan && ((c_sig & (1 << (sig_w - 1))) == 0);

        p_is_zero = a_is_zero || b_is_zero;
        p_is_inf  = (a_is_inf && !b_is_zero) || (b_is_inf && !a_is_zero);
        p_sign    = a_sign ^ b_sign;

        is_invalid = a_is_snan || b_is_snan || c_is_snan ||
                     (a_is_inf && b_is_zero) || (a_is_zero && b_is_inf) ||
                     (p_is_inf && c_is_inf && (p_sign != c_sign));

        is_nan = a_is_nan || b_is_nan || c_is_nan || is_invalid;

        a_man = a_is_zero ? 25'd0 : (a_is_sub ? {1'b0, a_sig} : {1'b1, a_sig});
        b_man = b_is_zero ? 25'd0 : (b_is_sub ? {1'b0, b_sig} : {1'b1, b_sig});
        c_man = c_is_zero ? 25'd0 : (c_is_sub ? {1'b0, c_sig} : {1'b1, c_sig});

        a_exp_true = (a_is_zero || a_is_sub) ? 1 - bias : a_exp - bias;
        b_exp_true = (b_is_zero || b_is_sub) ? 1 - bias : b_exp - bias;
        c_exp_true = (c_is_zero || c_is_sub) ? 1 - bias : c_exp - bias;

        E_p = a_exp_true + b_exp_true;
        E_c = c_exp_true;

        eff_E_p = p_is_zero ? -9999 : E_p;
        eff_E_c = c_is_zero ? -9999 : E_c;
        max_E = (eff_E_p > eff_E_c) ? eff_E_p : eff_E_c;

        shift_P = (p_is_zero) ? 96 : (max_E - eff_E_p);
        shift_C = (c_is_zero) ? 96 : (max_E - eff_E_c);
        shift_P = (shift_P > 96) ? 96 : shift_P;
        shift_C = (shift_C > 96) ? 96 : shift_C;

        p_man_mult = a_man * b_man;
        P_wide = {46'b0, p_man_mult} << (96 - 2 * p - 2);
        C_wide = {71'b0, c_man} << (96 - p - 3);

        P_shifted_full = {P_wide, 96'b0} >> shift_P;
        C_shifted_full = {C_wide, 96'b0} >> shift_C;

        P_aligned = P_shifted_full[191:96];
        P_sticky  = |P_shifted_full[95:0];

        C_aligned = C_shifted_full[191:96];
        C_sticky  = |C_shifted_full[95:0];

        P_ext = {P_aligned, P_sticky};
        C_ext = {C_aligned, C_sticky};

        p_larger    = (P_ext > C_ext);
        larger_ext  = p_larger ? P_ext : C_ext;
        smaller_ext = p_larger ? C_ext : P_ext;
        final_sign  = p_larger ? p_sign : c_sign;
        eff_sub     = (p_sign != c_sign);

        sum_ext = eff_sub ? (larger_ext - smaller_ext) : (larger_ext + smaller_ext);
        sum = sum_ext[96:1];
        sum_sticky = sum_ext[0];

        L = -1;
        for (int i = 95; i >= 0; i--) begin
            if (sum[i]) begin
                L = i;
                break;
            end
        end

        is_exact_zero = (L == -1) && !sum_sticky;
        out_sign = final_sign;
        if (is_exact_zero) begin
            out_sign = (eff_sub && rnd == 2) ? 1'b1 : ((p_sign == c_sign) ? p_sign : (rnd == 2));
        end

        E_res = (L == -1) ? 0 : max_E - (96 - 4) + L;
        target_E = (E_res > 1 - bias) ? E_res : 1 - bias;
        
        idx_target = 96 - 4 - max_E + target_E;
        shift_amt = 95 - idx_target;
        if (is_exact_zero || shift_amt < 0) shift_amt = 0;

        norm_sum = sum << shift_amt;

        mantissa_aligned = norm_sum >> (96 - p);
        mantissa = mantissa_aligned[24:0];

        guard     = norm_sum[95 - p];
        round_bit = norm_sum[95 - p - 1];
        lower_bits = norm_sum << (p + 2);
        sticky = (|lower_bits) | sum_sticky;

        round_up = 0;
        if (rnd == 0)      round_up = guard & (round_bit | sticky | mantissa[0]);
        else if (rnd == 1) round_up = 0;
        else if (rnd == 2) round_up = out_sign & (guard | round_bit | sticky);
        else if (rnd == 3) round_up = ~out_sign & (guard | round_bit | sticky);
        else if (rnd == 4) round_up = guard;

        mantissa_ext = {1'b0, mantissa} + round_up;

        if (mantissa_ext[p] == 1) begin
            final_exp = target_E + bias + 1;
            final_man = (mantissa_ext >> 1);
        end else begin
            final_exp = (target_E == 1 - bias && mantissa_ext[p-1] == 0) ? 0 : target_E + bias;
            final_man = mantissa_ext[24:0];
        end

        flag_nv = 0; flag_dz = 0; flag_of = 0; flag_uf = 0; flag_nx = 0;
        result = 0; temp_res = 0;

        final_exp_bits = final_exp[7:0];
        final_man_bits = final_man[22:0];
        max_man = (1 << sig_w) - 1;

        if (is_invalid || is_nan) begin
            if (exp_w == 8 && sig_w == 23) result = 32'h7FC00000;
            else if (exp_w == 5 && sig_w == 10) result = 32'h00007E00;
            else if (exp_w == 8 && sig_w == 7) result = 32'h00007FC0;
            flag_nv = is_invalid;
        end else if (p_is_inf || c_is_inf) begin
            if (exp_w == 8 && sig_w == 23) result = {out_sign, 8'hFF, 23'd0};
            else if (exp_w == 5 && sig_w == 10) result = {16'hFFFF, out_sign, 5'h1F, 10'd0};
            else if (exp_w == 8 && sig_w == 7) result = {16'hFFFF, out_sign, 8'hFF, 7'd0};
        end else if (is_exact_zero) begin
            if (exp_w == 8 && sig_w == 23) result = {out_sign, 31'd0};
            else if (exp_w == 5 && sig_w == 10) result = {16'hFFFF, out_sign, 15'd0};
            else if (exp_w == 8 && sig_w == 7) result = {16'hFFFF, out_sign, 15'd0};
        end else if (final_exp >= (1 << exp_w) - 1) begin
            max_normal = (rnd == 1) || (rnd == 2 && !out_sign) || (rnd == 3 && out_sign);
            if (max_normal) begin
                if (exp_w == 8 && sig_w == 23) result = {out_sign, 8'hFE, max_man[22:0]};
                else if (exp_w == 5 && sig_w == 10) result = {16'hFFFF, out_sign, 5'h1E, max_man[9:0]};
                else if (exp_w == 8 && sig_w == 7) result = {16'hFFFF, out_sign, 8'hFE, max_man[6:0]};
            end else begin
                if (exp_w == 8 && sig_w == 23) result = {out_sign, 8'hFF, 23'd0};
                else if (exp_w == 5 && sig_w == 10) result = {16'hFFFF, out_sign, 5'h1F, 10'd0};
                else if (exp_w == 8 && sig_w == 7) result = {16'hFFFF, out_sign, 8'hFF, 7'd0};
            end
            flag_of = 1;
            flag_nx = 1;
        end else if (final_exp <= 0) begin
            if (exp_w == 8 && sig_w == 23) result = {out_sign, 8'h00, final_man_bits[22:0]};
            else if (exp_w == 5 && sig_w == 10) result = {16'hFFFF, out_sign, 5'h00, final_man_bits[9:0]};
            else if (exp_w == 8 && sig_w == 7) result = {16'hFFFF, out_sign, 8'h00, final_man_bits[6:0]};
            
            flag_nx = guard | round_bit | sticky;
            if (flag_nx) flag_uf = 1;
        end else begin
            if (exp_w == 8 && sig_w == 23) result = {out_sign, final_exp_bits[7:0], final_man_bits[22:0]};
            else if (exp_w == 5 && sig_w == 10) result = {16'hFFFF, out_sign, final_exp_bits[4:0], final_man_bits[9:0]};
            else if (exp_w == 8 && sig_w == 7) result = {16'hFFFF, out_sign, final_exp_bits[7:0], final_man_bits[6:0]};
            
            flag_nx = guard | round_bit | sticky;
        end

        return {flag_nv, flag_dz, flag_of, flag_uf, flag_nx, result};
    end

    // =========================================================================
    // Combinational Datapath
    // =========================================================================
    logic [WIDTH-1:0] next_result;
    logic [4:0]       next_flags;

    always_comb begin
        int N_32;
        int N_16;
        logic [36:0] res;

        next_result = '1;
        next_flags  = '0;

        N_32 = vec_i ? (WIDTH / 32) : 1;
        N_16 = vec_i ? (WIDTH / 16) : 1;

        if (fmt_i == 2'b00) begin
            for (int k = 0; k < 2; k++) begin
                if (k < (WIDTH / 32)) begin
                    if (k < N_32) begin
                        res = compute_fma(a_i[k*32 +: 32], b_i[k*32 +: 32], c_i[k*32 +: 32], rnd_i, 8, 23);
                        next_result[k*32 +: 32] = res[31:0];
                        next_flags |= res[36:32];
                    end
                end
            end
        end else if (fmt_i == 2'b01) begin
            for (int k = 0; k < 4; k++) begin
                if (k < (WIDTH / 16)) begin
                    if (k < N_16) begin
                        res = compute_fma({16'd0, a_i[k*16 +: 16]}, {16'd0, b_i[k*16 +: 16]}, {16'd0, c_i[k*16 +: 16]}, rnd_i, 5, 10);
                        next_result[k*16 +: 16] = res[15:0];
                        next_flags |= res[36:32];
                    end
                end
            end
        end else if (fmt_i == 2'b10) begin
            for (int k = 0; k < 4; k++) begin
                if (k < (WIDTH / 16)) begin
                    if (k < N_16) begin
                        res = compute_fma({16'd0, a_i[k*16 +: 16]}, {16'd0, b_i[k*16 +: 16]}, {16'd0, c_i[k*16 +: 16]}, rnd_i, 8, 7);
                        next_result[k*16 +: 16] = res[15:0];
                        next_flags |= res[36:32];
                    end
                end
            end
        end
    end

    // =========================================================================
    // Pipeline Registers & Handshake
    // =========================================================================
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            out_valid_o <= 1'b0;
            result_o    <= '1;
            flags_o     <= '0;
        end else begin
            if (in_valid_i && in_ready_o) begin
                out_valid_o <= 1'b1;
                result_o    <= next_result;
                flags_o     <= next_flags;
            end else if (out_ready_i) begin
                out_valid_o <= 1'b0;
            end
        end
    end

    assign in_ready_o = out_ready_i || !out_valid_o;

endmodule