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

    // Pipeline registers
    logic v1, v2, v3;
    logic [31:0] r1, r2, r3;
    logic inv1, inv2, inv3;
    logic ovf1, ovf2, ovf3;
    logic uf1, uf2, uf3;
    logic nx1, nx2, nx3;

    // Combinational result
    logic [31:0] res_c;
    logic inv_c, ovf_c, uf_c, nx_c;

    // Intermediate signals
    logic sa, sb, sc;
    logic [7:0] ea, eb, ec;
    logic [22:0] fa, fb, fc;
    logic a_nan, b_nan, c_nan;
    logic a_inf, b_inf, c_inf;
    logic a_zero, b_zero, c_zero;
    logic a_snan, b_snan, c_snan;
    logic any_nan, any_snan;

    logic [23:0] Ma, Mb, Mc;
    integer ea_f, eb_f, ec_f;

    logic sign_p, sign_c;
    logic [47:0] Mp;
    integer ep;
    logic p_zero, p_inf;

    integer E;
    logic [95:0] Np, Nc;
    logic sp, sc_sticky;
    integer diff_p, diff_c, shift_r;
    logic [47:0] M_p48, M_c48;
    integer ec_eff;
    logic [95:0] N;
    logic sticky;
    logic sign_sum;

    integer L;
    integer i;
    logic found;
    integer exp_val;
    integer shift;
    logic [24:0] M;
    logic rbit, sbit;
    logic inc;
    logic [24:0] M_round;
    integer exp_final;
    logic [24:0] M_final;
    logic [7:0] exp_field;

    // Pipeline control
    wire stall = v3 && !out_ready;
    wire enable = !stall;
    assign in_ready = enable;

    always_comb begin
        // Defaults
        res_c = 32'h0;
        inv_c = 0;
        ovf_c = 0;
        uf_c = 0;
        nx_c = 0;

        // Field extraction
        sa = a[31]; ea = a[30:23]; fa = a[22:0];
        sb = b[31]; eb = b[30:23]; fb = b[22:0];
        sc = c[31]; ec = c[30:23]; fc = c[22:0];

        // Classification
        a_nan = (ea == 8'hFF) && (fa != 0);
        b_nan = (eb == 8'hFF) && (fb != 0);
        c_nan = (ec == 8'hFF) && (fc != 0);
        a_inf = (ea == 8'hFF) && (fa == 0);
        b_inf = (eb == 8'hFF) && (fb == 0);
        c_inf = (ec == 8'hFF) && (fc == 0);
        a_zero = (ea == 0) && (fa == 0);
        b_zero = (eb == 0) && (fb == 0);
        c_zero = (ec == 0) && (fc == 0);
        a_snan = a_nan && (fa[22] == 0);
        b_snan = b_nan && (fb[22] == 0);
        c_snan = c_nan && (fc[22] == 0);
        any_nan = a_nan || b_nan || c_nan;
        any_snan = a_snan || b_snan || c_snan;

        // Finite significands and exponents
        if (a_zero) begin
            Ma = 24'h0;
            ea_f = 0;
        end else if (ea == 0) begin
            Ma = {1'b0, fa};
            ea_f = -149;
        end else begin
            Ma = {1'b1, fa};
            ea_f = $signed({1'b0, ea}) - 150;
        end

        if (b_zero) begin
            Mb = 24'h0;
            eb_f = 0;
        end else if (eb == 0) begin
            Mb = {1'b0, fb};
            eb_f = -149;
        end else begin
            Mb = {1'b1, fb};
            eb_f = $signed({1'b0, eb}) - 150;
        end

        if (c_zero) begin
            Mc = 24'h0;
            ec_f = 0;
        end else if (ec == 0) begin
            Mc = {1'b0, fc};
            ec_f = -149;
        end else begin
            Mc = {1'b1, fc};
            ec_f = $signed({1'b0, ec}) - 150;
        end

        // Product
        sign_p = sa ^ sb;
        Mp = Ma * Mb;
        ep = ea_f + eb_f;
        p_zero = a_zero || b_zero;
        p_inf = (a_inf && !b_zero && !b_nan) || (b_inf && !a_zero && !a_nan) || (a_inf && b_inf);

        sign_c = sc;

        // Special cases
        if (any_nan) begin
            res_c = 32'h7FC00000;
            inv_c = any_snan;
            ovf_c = 0; uf_c = 0; nx_c = 0;
        end else if ((a_zero && b_inf) || (a_inf && b_zero)) begin
            res_c = 32'h7FC00000;
            inv_c = 1;
            ovf_c = 0; uf_c = 0; nx_c = 0;
        end else if (p_inf && c_inf && (sign_p != sc)) begin
            res_c = 32'h7FC00000;
            inv_c = 1;
            ovf_c = 0; uf_c = 0; nx_c = 0;
        end else if (p_inf) begin
            res_c = {sign_p, 8'hFF, 23'h0};
            inv_c = 0; ovf_c = 0; uf_c = 0; nx_c = 0;
        end else if (c_inf) begin
            res_c = {sc, 8'hFF, 23'h0};
            inv_c = 0; ovf_c = 0; uf_c = 0; nx_c = 0;
        end else if (Mp == 0) begin
            if (Mc == 0) begin
                if (sign_p == sc) begin
                    res_c = {sign_p, 31'h0};
                end else begin
                    res_c = {(rnd_mode == 3'd2), 31'h0};
                end
                inv_c = 0; ovf_c = 0; uf_c = 0; nx_c = 0;
            end else begin
                res_c = c;
                inv_c = 0; ovf_c = 0; uf_c = 0; nx_c = 0;
            end
        end else begin
            // General finite computation
            M_p48 = Mp;
            M_c48 = {24'h0, Mc};
            ec_eff = (Mc == 0) ? ep : ec_f;
            E = (ep > ec_eff) ? ep : ec_eff;

            // Align product
            diff_p = E - ep;
            if (diff_p <= 47) begin
                Np = {48'h0, M_p48} << (47 - diff_p);
                sp = 0;
            end else begin
                shift_r = diff_p - 47;
                if (shift_r >= 48) begin
                    Np = 96'h0;
                    sp = (M_p48 != 0);
                end else begin
                    Np = {48'h0, M_p48} >> shift_r;
                    sp = |(M_p48 & ((48'h1 << shift_r) - 1));
                end
            end

            // Align addend
            diff_c = E - ec_eff;
            if (diff_c <= 47) begin
                Nc = {48'h0, M_c48} << (47 - diff_c);
                sc_sticky = 0;
            end else begin
                shift_r = diff_c - 47;
                if (shift_r >= 48) begin
                    Nc = 96'h0;
                    sc_sticky = (M_c48 != 0);
                end else begin
                    Nc = {48'h0, M_c48} >> shift_r;
                    sc_sticky = |(M_c48 & ((48'h1 << shift_r) - 1));
                end
            end

            // Combine
            if (sign_p == sign_c) begin
                N = Np + Nc;
                sticky = sp | sc_sticky;
                sign_sum = sign_p;
            end else begin
                if (Np > Nc) begin
                    N = Np - Nc;
                    sign_sum = sign_p;
                    if (sc_sticky) begin
                        N = N - 1;
                        sticky = 1;
                    end else begin
                        sticky = sp;
                    end
                end else if (Np < Nc) begin
                    N = Nc - Np;
                    sign_sum = sign_c;
                    if (sp) begin
                        N = N - 1;
                        sticky = 1;
                    end else begin
                        sticky = sc_sticky;
                    end
                end else begin
                    N = 96'h0;
                    sticky = 0;
                    sign_sum = 0;
                end
            end

            if (N == 0 && sticky == 0) begin
                res_c = {(rnd_mode == 3'd2), 31'h0};
                inv_c = 0; ovf_c = 0; uf_c = 0; nx_c = 0;
            end else begin
                // Find MSB
                L = 0;
                found = 0;
                for (i = 95; i >= 0; i = i - 1) begin
                    if (N[i] && !found) begin
                        L = i;
                        found = 1;
                    end
                end

                exp_val = E - 47 + L;

                if (exp_val >= -126) begin
                    // Normal
                    shift = 23 - L;
                    if (shift >= 0) begin
                        M = N << shift;
                        rbit = 0;
                        sbit = sticky;
                    end else begin
                        shift_r = -shift;
                        if (shift_r >= 96) begin
                            M = 0;
                            rbit = 0;
                            sbit = (N != 0) | sticky;
                        end else begin
                            M = N >> shift_r;
                            if (shift_r == 0) begin
                                rbit = 0;
                                sbit = sticky;
                            end else begin
                                rbit = N[shift_r - 1];
                                if (shift_r > 1) begin
                                    sbit = |(N & ((96'h1 << (shift_r - 1)) - 1)) | sticky;
                                end else begin
                                    sbit = sticky;
                                end
                            end
                        end
                    end

                    inc = 0;
                    case (rnd_mode)
                        3'd0: if (rbit && (sbit || M[0])) inc = 1;
                        3'd1: inc = 0;
                        3'd2: if (sign_sum && (rbit || sbit)) inc = 1;
                        3'd3: if (!sign_sum && (rbit || sbit)) inc = 1;
                        3'd4: if (rbit) inc = 1;
                        default: inc = 0;
                    endcase
                    M_round = M + inc;

                    if (M_round[24]) begin
                        M_final = 25'h800000;
                        exp_final = exp_val + 1;
                    end else begin
                        M_final = M_round;
                        exp_final = exp_val;
                    end

                    if (exp_final > 127) begin
                        ovf_c = 1;
                        nx_c = 1;
                        uf_c = 0;
                        inv_c = 0;
                        if (rnd_mode == 3'd0 || rnd_mode == 3'd4) begin
                            res_c = {sign_sum, 8'hFF, 23'h0};
                        end else if (rnd_mode == 3'd1) begin
                            res_c = {sign_sum, 8'hFE, 23'h7FFFFF};
                        end else if (rnd_mode == 3'd2) begin
                            if (sign_sum) res_c = {1'b1, 8'hFF, 23'h0};
                            else res_c = {1'b0, 8'hFE, 23'h7FFFFF};
                        end else if (rnd_mode == 3'd3) begin
                            if (sign_sum) res_c = {1'b1, 8'hFE, 23'h7FFFFF};
                            else res_c = {1'b0, 8'hFF, 23'h0};
                        end else begin
                            res_c = {sign_sum, 8'hFF, 23'h0};
                        end
                    end else begin
                        exp_field = exp_final + 127;
                        res_c = {sign_sum, exp_field, M_final[22:0]};
                        nx_c = (rbit || sbit) ? 1 : 0;
                        uf_c = 0;
                        ovf_c = 0;
                        inv_c = 0;
                    end
                end else begin
                    // Subnormal
                    shift = E + 102;
                    if (shift >= 0) begin
                        M = N << shift;
                        rbit = 0;
                        sbit = sticky;
                    end else begin
                        shift_r = -shift;
                        if (shift_r >= 96) begin
                            M = 0;
                            rbit = 0;
                            sbit = (N != 0) | sticky;
                        end else begin
                            M = N >> shift_r;
                            if (shift_r == 0) begin
                                rbit = 0;
                                sbit = sticky;
                            end else begin
                                rbit = N[shift_r - 1];
                                if (shift_r > 1) begin
                                    sbit = |(N & ((96'h1 << (shift_r - 1)) - 1)) | sticky;
                                end else begin
                                    sbit = sticky;
                                end
                            end
                        end
                    end

                    inc = 0;
                    case (rnd_mode)
                        3'd0: if (rbit && (sbit || M[0])) inc = 1;
                        3'd1: inc = 0;
                        3'd2: if (sign_sum && (rbit || sbit)) inc = 1;
                        3'd3: if (!sign_sum && (rbit || sbit)) inc = 1;
                        3'd4: if (rbit) inc = 1;
                        default: inc = 0;
                    endcase
                    M_round = M + inc;

                    if (M_round >= 25'h800000) begin
                        res_c = {sign_sum, 8'd1, 23'h0};
                        nx_c = (rbit || sbit) ? 1 : 0;
                        uf_c = 0;
                        ovf_c = 0;
                        inv_c = 0;
                    end else begin
                        res_c = {sign_sum, 8'h0, M_round[22:0]};
                        nx_c = (rbit || sbit) ? 1 : 0;
                        uf_c = nx_c;
                        ovf_c = 0;
                        inv_c = 0;
                    end
                end
            end
        end
    end

    // Pipeline
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            v1 <= 1'b0;
            v2 <= 1'b0;
            v3 <= 1'b0;
            r1 <= 32'h0;
            r2 <= 32'h0;
            r3 <= 32'h0;
            inv1 <= 1'b0; inv2 <= 1'b0; inv3 <= 1'b0;
            ovf1 <= 1'b0; ovf2 <= 1'b0; ovf3 <= 1'b0;
            uf1 <= 1'b0; uf2 <= 1'b0; uf3 <= 1'b0;
            nx1 <= 1'b0; nx2 <= 1'b0; nx3 <= 1'b0;
        end else if (enable) begin
            v1 <= in_valid;
            if (in_valid) begin
                r1 <= res_c;
                inv1 <= inv_c;
                ovf1 <= ovf_c;
                uf1 <= uf_c;
                nx1 <= nx_c;
            end
            v2 <= v1;
            r2 <= r1;
            inv2 <= inv1;
            ovf2 <= ovf1;
            uf2 <= uf1;
            nx2 <= nx1;
            v3 <= v2;
            r3 <= r2;
            inv3 <= inv2;
            ovf3 <= ovf2;
            uf3 <= uf2;
            nx3 <= nx2;
        end
    end

    assign out_valid = v3 && rst_n;
    assign result = r3;
    assign flag_invalid = inv3;
    assign flag_overflow = ovf3;
    assign flag_underflow = uf3;
    assign flag_inexact = nx3;

endmodule
