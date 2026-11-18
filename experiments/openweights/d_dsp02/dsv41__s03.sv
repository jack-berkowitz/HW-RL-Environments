// =============================================================================
// fp32_fma_ii1.sv
// IEEE-754 binary32 fused multiply-add, (a*b)+c, single rounding.
// Latency 3, II=1, all five rounding modes, subnormals, canonical NaN.
// =============================================================================

`timescale 1ns/1ps

module fp32_fma_ii1 (
    input  logic        clk,
    input  logic        rst_n,

    input  logic        in_valid,
    output logic        in_ready,
    input  logic [31:0] a,
    input  logic [31:0] b,
    input  logic [31:0] c,
    input  logic [2:0]  rnd_mode,

    output logic        out_valid,
    input  logic        out_ready,
    output logic [31:0] result,
    output logic        flag_invalid,
    output logic        flag_overflow,
    output logic        flag_underflow,
    output logic        flag_inexact
);

    // -------------------------------------------------------------------------
    // Functions
    // -------------------------------------------------------------------------
    function automatic logic [6:0] find_msb(input logic [95:0] x);
        integer i;
        begin
            find_msb = 7'd0;
            for (i = 0; i < 96; i = i + 1) begin
                if (x[i]) find_msb = i[6:0];
            end
        end
    endfunction

    function automatic logic round_up_func(
        input logic [24:0] kept,
        input logic guard,
        input logic sticky,
        input logic sign,
        input logic [2:0] mode
    );
        begin
            case (mode)
                3'd0: round_up_func = guard && (sticky || kept[0]); // RNE
                3'd1: round_up_func = 1'b0;                         // RTZ
                3'd2: round_up_func = sign && (guard || sticky);    // RDN
                3'd3: round_up_func = !sign && (guard || sticky);   // RUP
                3'd4: round_up_func = guard;                        // RMM
                default: round_up_func = 1'b0;
            endcase
        end
    endfunction

    function automatic void align_term(
        input logic [47:0] M,
        input logic signed [10:0] shift,
        output logic [95:0] aligned,
        output logic guard,
        output logic sticky
    );
        integer rshift;
        begin
            if (shift >= 0) begin
                aligned = {48'b0, M} << shift;
                guard = 1'b0;
                sticky = 1'b0;
            end else begin
                rshift = -shift;
                if (rshift >= 48) begin
                    aligned = 96'd0;
                    if (rshift == 48) begin
                        guard = M[47];
                        sticky = |M[46:0];
                    end else begin
                        guard = 1'b0;
                        sticky = |M;
                    end
                end else begin
                    aligned = {48'b0, M} >> rshift;
                    guard = M[rshift-1];
                    sticky = |(M & ((48'd1 << (rshift-1)) - 1));
                end
            end
        end
    endfunction

    // -------------------------------------------------------------------------
    // Pipeline control
    // -------------------------------------------------------------------------
    logic stall;
    assign stall = out_valid && !out_ready;
    assign in_ready = !stall;

    // -------------------------------------------------------------------------
    // Stage 1 registers
    // -------------------------------------------------------------------------
    logic        reg1_valid;
    logic        reg1_nan;
    logic        reg1_inf;
    logic        reg1_inf_sign;
    logic        reg1_invalid;
    logic        reg1_sign_p;
    logic [47:0] reg1_M_p;
    logic signed [10:0] reg1_exp_p;
    logic        reg1_product_zero;
    logic        reg1_sign_c;
    logic [23:0] reg1_M_c;
    logic signed [10:0] reg1_exp_c;
    logic        reg1_c_zero;
    logic [2:0]  reg1_rnd_mode;

    // Stage 1 next
    logic        reg1_valid_next;
    logic        reg1_nan_next;
    logic        reg1_inf_next;
    logic        reg1_inf_sign_next;
    logic        reg1_invalid_next;
    logic        reg1_sign_p_next;
    logic [47:0] reg1_M_p_next;
    logic signed [10:0] reg1_exp_p_next;
    logic        reg1_product_zero_next;
    logic        reg1_sign_c_next;
    logic [23:0] reg1_M_c_next;
    logic signed [10:0] reg1_exp_c_next;
    logic        reg1_c_zero_next;
    logic [2:0]  reg1_rnd_mode_next;

    // -------------------------------------------------------------------------
    // Stage 2 registers
    // -------------------------------------------------------------------------
    logic        reg2_valid;
    logic        reg2_nan;
    logic        reg2_inf;
    logic        reg2_inf_sign;
    logic        reg2_invalid;
    logic        reg2_sign_sum;
    logic [95:0] reg2_sum_mag;
    logic        reg2_sum_guard;
    logic        reg2_sum_sticky;
    logic signed [10:0] reg2_E_scale;
    logic        reg2_exact_zero;
    logic        reg2_sign_zero;
    logic [2:0]  reg2_rnd_mode;

    // Stage 2 next
    logic        reg2_valid_next;
    logic        reg2_nan_next;
    logic        reg2_inf_next;
    logic        reg2_inf_sign_next;
    logic        reg2_invalid_next;
    logic        reg2_sign_sum_next;
    logic [95:0] reg2_sum_mag_next;
    logic        reg2_sum_guard_next;
    logic        reg2_sum_sticky_next;
    logic signed [10:0] reg2_E_scale_next;
    logic        reg2_exact_zero_next;
    logic        reg2_sign_zero_next;
    logic [2:0]  reg2_rnd_mode_next;

    // -------------------------------------------------------------------------
    // Stage 3 next (output)
    // -------------------------------------------------------------------------
    logic        out_valid_next;
    logic [31:0] result_next;
    logic        flag_invalid_next;
    logic        flag_overflow_next;
    logic        flag_underflow_next;
    logic        flag_inexact_next;

    // -------------------------------------------------------------------------
    // Stage 1 combinational
    // -------------------------------------------------------------------------
    always_comb begin
        logic sa, sb, sc;
        logic [7:0] ea, eb, ec;
        logic [22:0] fa, fb, fc;
        logic a_nan, a_inf, a_zero, a_sub, a_snan;
        logic b_nan, b_inf, b_zero, b_sub, b_snan;
        logic c_nan, c_inf, c_zero, c_sub, c_snan;
        logic [23:0] M_a, M_b, M_c;
        logic signed [10:0] exp_a, exp_b, exp_c;
        logic [47:0] M_p;
        logic signed [10:0] exp_p;
        logic sign_p;
        logic product_zero;
        logic any_nan, any_snan, invalid, result_nan, result_inf;
        logic inf_sign;
        logic zero_times_inf;
        logic product_inf;
        logic inf_minus_inf;

        // defaults
        reg1_valid_next = in_valid;
        reg1_nan_next = 1'b0;
        reg1_inf_next = 1'b0;
        reg1_inf_sign_next = 1'b0;
        reg1_invalid_next = 1'b0;
        reg1_sign_p_next = 1'b0;
        reg1_M_p_next = 48'd0;
        reg1_exp_p_next = 11'sd0;
        reg1_product_zero_next = 1'b0;
        reg1_sign_c_next = 1'b0;
        reg1_M_c_next = 24'd0;
        reg1_exp_c_next = 11'sd0;
        reg1_c_zero_next = 1'b0;
        reg1_rnd_mode_next = rnd_mode;

        // extract
        sa = a[31]; ea = a[30:23]; fa = a[22:0];
        sb = b[31]; eb = b[30:23]; fb = b[22:0];
        sc = c[31]; ec = c[30:23]; fc = c[22:0];

        // classify
        a_nan = (ea == 8'hFF) && (fa != 0);
        a_inf = (ea == 8'hFF) && (fa == 0);
        a_zero = (ea == 0) && (fa == 0);
        a_sub = (ea == 0) && (fa != 0);
        a_snan = a_nan && !fa[22];

        b_nan = (eb == 8'hFF) && (fb != 0);
        b_inf = (eb == 8'hFF) && (fb == 0);
        b_zero = (eb == 0) && (fb == 0);
        b_sub = (eb == 0) && (fb != 0);
        b_snan = b_nan && !fb[22];

        c_nan = (ec == 8'hFF) && (fc != 0);
        c_inf = (ec == 8'hFF) && (fc == 0);
        c_zero = (ec == 0) && (fc == 0);
        c_sub = (ec == 0) && (fc != 0);
        c_snan = c_nan && !fc[22];

        // significands and exponents
        M_a = (ea == 0) ? {1'b0, fa} : {1'b1, fa};
        exp_a = (ea == 0) ? -11'sd149 : (signed'(ea) - 11'sd150);
        M_b = (eb == 0) ? {1'b0, fb} : {1'b1, fb};
        exp_b = (eb == 0) ? -11'sd149 : (signed'(eb) - 11'sd150);
        M_c = (ec == 0) ? {1'b0, fc} : {1'b1, fc};
        exp_c = (ec == 0) ? -11'sd149 : (signed'(ec) - 11'sd150);

        // product
        M_p = M_a * M_b;
        exp_p = exp_a + exp_b;
        sign_p = sa ^ sb;
        product_zero = a_zero || b_zero;

        // special
        any_nan = a_nan || b_nan || c_nan;
        any_snan = a_snan || b_snan || c_snan;
        zero_times_inf = (a_inf && b_zero) || (a_zero && b_inf);
        product_inf = a_inf || b_inf;
        inf_minus_inf = product_inf && c_inf && (sign_p != sc);
        invalid = any_snan || zero_times_inf || inf_minus_inf;
        result_nan = any_nan || invalid;
        result_inf = !result_nan && (product_inf || c_inf);
        inf_sign = product_inf ? sign_p : sc;

        // assign next
        reg1_nan_next = result_nan;
        reg1_inf_next = result_inf;
        reg1_inf_sign_next = inf_sign;
        reg1_invalid_next = invalid;
        reg1_sign_p_next = sign_p;
        reg1_M_p_next = M_p;
        reg1_exp_p_next = exp_p;
        reg1_product_zero_next = product_zero;
        reg1_sign_c_next = sc;
        reg1_M_c_next = M_c;
        reg1_exp_c_next = exp_c;
        reg1_c_zero_next = c_zero;
        reg1_rnd_mode_next = rnd_mode;
    end

    // -------------------------------------------------------------------------
    // Stage 2 combinational
    // -------------------------------------------------------------------------
    always_comb begin
        logic signed [10:0] max_exp, E_scale;
        logic [95:0] aligned_p, aligned_c;
        logic guard_p, sticky_p, guard_c, sticky_c;
        logic [95:0] sum_mag;
        logic sum_guard, sum_sticky;
        logic sum_sign;
        logic exact_zero;
        logic sign_zero;
        logic signed [10:0] shift_p, shift_c;
        logic [47:0] M_c_ext;
        logic [1:0] frac_sum;

        // defaults
        reg2_valid_next = reg1_valid;
        reg2_nan_next = reg1_nan;
        reg2_inf_next = reg1_inf;
        reg2_inf_sign_next = reg1_inf_sign;
        reg2_invalid_next = reg1_invalid;
        reg2_sign_sum_next = 1'b0;
        reg2_sum_mag_next = 96'd0;
        reg2_sum_guard_next = 1'b0;
        reg2_sum_sticky_next = 1'b0;
        reg2_E_scale_next = 11'sd0;
        reg2_exact_zero_next = 1'b0;
        reg2_sign_zero_next = 1'b0;
        reg2_rnd_mode_next = reg1_rnd_mode;

        if (!reg1_nan && !reg1_inf) begin
            // max exponent
            max_exp = -11'sd1024;
            if (!reg1_product_zero && (reg1_exp_p > max_exp)) max_exp = reg1_exp_p;
            if (!reg1_c_zero && (reg1_exp_c > max_exp)) max_exp = reg1_exp_c;
            E_scale = (max_exp == -11'sd1024) ? 11'sd0 : (max_exp - 11'sd47);

            // align product
            shift_p = reg1_exp_p - max_exp + 11'sd47;
            align_term(reg1_M_p, shift_p, aligned_p, guard_p, sticky_p);
            if (reg1_product_zero) begin
                aligned_p = 96'd0; guard_p = 1'b0; sticky_p = 1'b0;
            end

            // align c
            shift_c = reg1_exp_c - max_exp + 11'sd47;
            M_c_ext = {24'b0, reg1_M_c};
            align_term(M_c_ext, shift_c, aligned_c, guard_c, sticky_c);
            if (reg1_c_zero) begin
                aligned_c = 96'd0; guard_c = 1'b0; sticky_c = 1'b0;
            end

            // add or subtract
            if (reg1_sign_p == reg1_sign_c) begin
                sum_mag = aligned_p + aligned_c;
                frac_sum = {1'b0, guard_p} + {1'b0, guard_c};
                if (frac_sum == 2) begin
                    sum_mag = sum_mag + 1;
                    sum_guard = 1'b0;
                    sum_sticky = sticky_p | sticky_c;
                end else if (frac_sum == 1) begin
                    sum_guard = 1'b1;
                    sum_sticky = sticky_p | sticky_c;
                end else begin
                    sum_guard = 1'b0;
                    sum_sticky = sticky_p | sticky_c;
                end
                sum_sign = reg1_sign_p;
            end else begin
                if (aligned_p > aligned_c) begin
                    sum_mag = aligned_p - aligned_c;
                    if (guard_c || sticky_c) begin
                        sum_mag = sum_mag - 1;
                        if (guard_c && !sticky_c) begin
                            sum_guard = 1'b1; sum_sticky = 1'b0;
                        end else if (guard_c && sticky_c) begin
                            sum_guard = 1'b0; sum_sticky = 1'b1;
                        end else begin
                            sum_guard = 1'b1; sum_sticky = 1'b1;
                        end
                    end else begin
                        sum_guard = 1'b0; sum_sticky = 1'b0;
                    end
                    sum_sign = reg1_sign_p;
                end else if (aligned_c > aligned_p) begin
                    sum_mag = aligned_c - aligned_p;
                    if (guard_p || sticky_p) begin
                        sum_mag = sum_mag - 1;
                        if (guard_p && !sticky_p) begin
                            sum_guard = 1'b1; sum_sticky = 1'b0;
                        end else if (guard_p && sticky_p) begin
                            sum_guard = 1'b0; sum_sticky = 1'b1;
                        end else begin
                            sum_guard = 1'b1; sum_sticky = 1'b1;
                        end
                    end else begin
                        sum_guard = 1'b0; sum_sticky = 1'b0;
                    end
                    sum_sign = reg1_sign_c;
                end else begin
                    if (guard_p || sticky_p) begin
                        sum_mag = 96'd0;
                        sum_guard = guard_p;
                        sum_sticky = sticky_p;
                        sum_sign = reg1_sign_p;
                    end else if (guard_c || sticky_c) begin
                        sum_mag = 96'd0;
                        sum_guard = guard_c;
                        sum_sticky = sticky_c;
                        sum_sign = reg1_sign_c;
                    end else begin
                        sum_mag = 96'd0;
                        sum_guard = 1'b0;
                        sum_sticky = 1'b0;
                        sum_sign = 1'b0;
                    end
                end
            end

            exact_zero = (sum_mag == 0) && (sum_guard == 0) && (sum_sticky == 0);
            if (exact_zero) begin
                if (reg1_product_zero && reg1_c_zero) begin
                    if (reg1_sign_p == reg1_sign_c)
                        sign_zero = reg1_sign_p;
                    else
                        sign_zero = (reg1_rnd_mode == 3'd2) ? 1'b1 : 1'b0;
                end else begin
                    sign_zero = (reg1_rnd_mode == 3'd2) ? 1'b1 : 1'b0;
                end
            end else begin
                sign_zero = 1'b0;
            end

            reg2_sign_sum_next = sum_sign;
            reg2_sum_mag_next = sum_mag;
            reg2_sum_guard_next = sum_guard;
            reg2_sum_sticky_next = sum_sticky;
            reg2_E_scale_next = E_scale;
            reg2_exact_zero_next = exact_zero;
            reg2_sign_zero_next = sign_zero;
        end
    end

    // -------------------------------------------------------------------------
    // Stage 3 combinational
    // -------------------------------------------------------------------------
    always_comb begin
        logic [6:0] L;
        logic signed [10:0] E_val;
        logic [24:0] kept;
        logic guard, sticky;
        logic round_up;
        logic [24:0] rounded;
        logic [7:0] exp_field;
        logic [22:0] frac;
        logic overflow_flag;
        logic underflow_flag;
        logic inexact_flag;
        logic [31:0] res;
        logic inv, ovf, unf, inx;
        integer drop;
        logic [95:0] shifted;
        logic signed [10:0] shift;
        logic [23:0] frac_result;
        logic sub_inexact;
        logic is_smallest_normal;
        logic [47:0] scaled_int;
        logic scaled_guard, scaled_sticky;
        logic [24:0] kept_ext;
        logic [24:0] rounded_sub;

        // defaults
        out_valid_next = reg2_valid;
        result_next = 32'd0;
        flag_invalid_next = 1'b0;
        flag_overflow_next = 1'b0;
        flag_underflow_next = 1'b0;
        flag_inexact_next = 1'b0;

        if (reg2_nan) begin
            result_next = 32'h7FC00000;
            flag_invalid_next = reg2_invalid;
        end else if (reg2_inf) begin
            result_next = {reg2_inf_sign, 8'hFF, 23'b0};
        end else if (reg2_exact_zero) begin
            result_next = {reg2_sign_zero, 31'b0};
        end else begin
            L = find_msb(reg2_sum_mag);
            E_val = signed'(L) + reg2_E_scale;

            if (E_val >= -11'sd126) begin
                // normal path
                drop = L - 7'd23;
                if (drop > 0) begin
                    shifted = reg2_sum_mag >> drop;
                    kept = {1'b0, shifted[23:0]};
                    guard = reg2_sum_mag[drop-1];
                    sticky = |(reg2_sum_mag & ((96'd1 << (drop-1)) - 1)) | reg2_sum_guard | reg2_sum_sticky;
                end else if (drop == 0) begin
                    kept = {1'b0, reg2_sum_mag[23:0]};
                    guard = reg2_sum_guard;
                    sticky = reg2_sum_sticky;
                end else begin
                    kept = {1'b0, (reg2_sum_mag[23:0] << (-drop))};
                    guard = 1'b0;
                    sticky = 1'b0;
                end

                round_up = round_up_func(kept, guard, sticky, reg2_sign_sum, reg2_rnd_mode);
                rounded = kept + round_up;
                if (rounded[24]) begin
                    rounded = rounded >> 1;
                    E_val = E_val + 1;
                end
                exp_field = E_val + 11'sd127;
                frac = rounded[22:0];
                inexact_flag = guard || sticky;

                if (exp_field >= 8'd255) begin
                    overflow_flag = 1;
                    inexact_flag = 1;
                    case (reg2_rnd_mode)
                        3'd0: res = {reg2_sign_sum, 8'hFF, 23'b0};
                        3'd1: res = {reg2_sign_sum, 8'hFE, 23'h7FFFFF};
                        3'd2: begin
                            if (reg2_sign_sum) res = {1'b1, 8'hFF, 23'b0};
                            else res = {1'b0, 8'hFE, 23'h7FFFFF};
                        end
                        3'd3: begin
                            if (reg2_sign_sum) res = {1'b1, 8'hFE, 23'h7FFFFF};
                            else res = {1'b0, 8'hFF, 23'b0};
                        end
                        3'd4: res = {reg2_sign_sum, 8'hFF, 23'b0};
                        default: res = {reg2_sign_sum, 8'hFF, 23'b0};
                    endcase
                    ovf = 1;
                    unf = 0;
                    inx = 1;
                end else begin
                    overflow_flag = 0;
                    res = {reg2_sign_sum, exp_field[7:0], frac};
                    ovf = 0;
                    unf = 0;
                    inx = inexact_flag;
                end
            end else begin
                // subnormal path
                shift = reg2_E_scale + 11'sd149;
                is_smallest_normal = 1'b0;

                if (shift >= 0) begin
                    scaled_int = {24'b0, reg2_sum_mag[23:0]} << shift;
                    if (shift > 0) begin
                        scaled_int = scaled_int + ({24'b0, reg2_sum_guard} << (shift-1));
                        scaled_guard = 1'b0;
                        scaled_sticky = reg2_sum_sticky;
                    end else begin
                        scaled_guard = reg2_sum_guard;
                        scaled_sticky = reg2_sum_sticky;
                    end
                    kept_ext = {1'b0, scaled_int[23:0]};
                    round_up = round_up_func(kept_ext, scaled_guard, scaled_sticky, reg2_sign_sum, reg2_rnd_mode);
                    rounded_sub = kept_ext + round_up;
                    frac_result = rounded_sub[23:0];
                    sub_inexact = scaled_guard || scaled_sticky;
                    if (rounded_sub[24]) is_smallest_normal = 1'b1;
                end else begin
                    drop = -shift;
                    if (drop >= 96) begin
                        frac_result = 24'd0;
                        if (drop == 96) begin
                            guard = reg2_sum_mag[95];
                            sticky = |reg2_sum_mag[94:0] | reg2_sum_guard | reg2_sum_sticky;
                        end else begin
                            guard = 1'b0;
                            sticky = |reg2_sum_mag | reg2_sum_guard | reg2_sum_sticky;
                        end
                    end else begin
                        shifted = reg2_sum_mag >> drop;
                        frac_result = shifted[23:0];
                        if (drop == 0) begin
                            guard = reg2_sum_guard;
                            sticky = reg2_sum_sticky;
                        end else begin
                            guard = reg2_sum_mag[drop-1];
                            sticky = |(reg2_sum_mag & ((96'd1 << (drop-1)) - 1)) | reg2_sum_guard | reg2_sum_sticky;
                        end
                    end
                    kept_ext = {1'b0, frac_result};
                    round_up = round_up_func(kept_ext, guard, sticky, reg2_sign_sum, reg2_rnd_mode);
                    rounded_sub = kept_ext + round_up;
                    frac_result = rounded_sub[23:0];
                    sub_inexact = guard || sticky;
                    if (rounded_sub[24]) is_smallest_normal = 1'b1;
                end

                if (is_smallest_normal) begin
                    res = {reg2_sign_sum, 8'd1, 23'd0};
                    ovf = 0;
                    unf = 0;
                    inx = sub_inexact;
                end else begin
                    res = {reg2_sign_sum, 8'd0, frac_result[22:0]};
                    ovf = 0;
                    unf = sub_inexact;
                    inx = sub_inexact;
                end
            end

            result_next = res;
            flag_invalid_next = inv;
            flag_overflow_next = ovf;
            flag_underflow_next = unf;
            flag_inexact_next = inx;
        end
    end

    // -------------------------------------------------------------------------
    // Pipeline registers
    // -------------------------------------------------------------------------
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            reg1_valid <= 1'b0;
            reg1_nan <= 1'b0;
            reg1_inf <= 1'b0;
            reg1_inf_sign <= 1'b0;
            reg1_invalid <= 1'b0;
            reg1_sign_p <= 1'b0;
            reg1_M_p <= 48'd0;
            reg1_exp_p <= 11'sd0;
            reg1_product_zero <= 1'b0;
            reg1_sign_c <= 1'b0;
            reg1_M_c <= 24'd0;
            reg1_exp_c <= 11'sd0;
            reg1_c_zero <= 1'b0;
            reg1_rnd_mode <= 3'd0;

            reg2_valid <= 1'b0;
            reg2_nan <= 1'b0;
            reg2_inf <= 1'b0;
            reg2_inf_sign <= 1'b0;
            reg2_invalid <= 1'b0;
            reg2_sign_sum <= 1'b0;
            reg2_sum_mag <= 96'd0;
            reg2_sum_guard <= 1'b0;
            reg2_sum_sticky <= 1'b0;
            reg2_E_scale <= 11'sd0;
            reg2_exact_zero <= 1'b0;
            reg2_sign_zero <= 1'b0;
            reg2_rnd_mode <= 3'd0;

            out_valid <= 1'b0;
            result <= 32'd0;
            flag_invalid <= 1'b0;
            flag_overflow <= 1'b0;
            flag_underflow <= 1'b0;
            flag_inexact <= 1'b0;
        end else if (!stall) begin
            reg1_valid <= reg1_valid_next;
            reg1_nan <= reg1_nan_next;
            reg1_inf <= reg1_inf_next;
            reg1_inf_sign <= reg1_inf_sign_next;
            reg1_invalid <= reg1_invalid_next;
            reg1_sign_p <= reg1_sign_p_next;
            reg1_M_p <= reg1_M_p_next;
            reg1_exp_p <= reg1_exp_p_next;
            reg1_product_zero <= reg1_product_zero_next;
            reg1_sign_c <= reg1_sign_c_next;
            reg1_M_c <= reg1_M_c_next;
            reg1_exp_c <= reg1_exp_c_next;
            reg1_c_zero <= reg1_c_zero_next;
            reg1_rnd_mode <= reg1_rnd_mode_next;

            reg2_valid <= reg2_valid_next;
            reg2_nan <= reg2_nan_next;
            reg2_inf <= reg2_inf_next;
            reg2_inf_sign <= reg2_inf_sign_next;
            reg2_invalid <= reg2_invalid_next;
            reg2_sign_sum <= reg2_sign_sum_next;
            reg2_sum_mag <= reg2_sum_mag_next;
            reg2_sum_guard <= reg2_sum_guard_next;
            reg2_sum_sticky <= reg2_sum_sticky_next;
            reg2_E_scale <= reg2_E_scale_next;
            reg2_exact_zero <= reg2_exact_zero_next;
            reg2_sign_zero <= reg2_sign_zero_next;
            reg2_rnd_mode <= reg2_rnd_mode_next;

            out_valid <= out_valid_next;
            result <= result_next;
            flag_invalid <= flag_invalid_next;
            flag_overflow <= flag_overflow_next;
            flag_underflow <= flag_underflow_next;
            flag_inexact <= flag_inexact_next;
        end
    end

endmodule
