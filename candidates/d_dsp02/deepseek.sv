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
    // Constant: exact fixed-point scale exponent.
    // All finite FP32 values can be represented exactly at scale 2^-298.
    // Subnormal product of two minimum subnormals is 2^-298.
    // =========================================================================
    localparam int SCALE_EXP = -298;
    localparam int W         = 1024;

    // -------------------------------------------------------------------------
    // Stage 1: unpack, multiply, special detection
    // -------------------------------------------------------------------------
    logic valid_s1;

    logic [2:0]  rnd_mode_s1;
    logic        sign_p_s1;
    logic        sign_c_s1;
    logic [47:0] Pm_s1;
    int          shift_prod_s1;
    logic [23:0] Cm_s1;
    int          shift_c_s1;

    logic invalid_s1;
    logic nan_s1;
    logic inf_s1;
    logic inf_sign_s1;

    // unpack temp
    int          Ea, Eb, Ec;
    logic [23:0] sig_a, sig_b, sig_c;
    logic        sign_a, sign_b, sign_c_in;
    logic        is_nan_a, is_nan_b, is_nan_c;
    logic        is_inf_a, is_inf_b, is_inf_c;
    logic        is_zero_a, is_zero_b;
    logic        snan_a, snan_b, snan_c;

    // -------------------------------------------------------------------------
    // Stage 2: exact fixed-point sum
    // -------------------------------------------------------------------------
    logic valid_s2;

    logic [2:0]  rnd_mode_s2;
    logic        invalid_s2;
    logic        nan_s2;
    logic        inf_s2;
    logic        inf_sign_s2;
    logic signed [W-1:0] exactN_s2;

    // -------------------------------------------------------------------------
    // Stage 3: rounding and output register
    // -------------------------------------------------------------------------
    logic valid_s3;

    logic [2:0]  rnd_mode_s3;
    logic        invalid_s3;
    logic        nan_s3;
    logic        inf_s3;
    logic        inf_sign_s3;
    logic signed [W-1:0] exactN_s3;

    // -------------------------------------------------------------------------
    // in_ready is independent of in_valid
    // -------------------------------------------------------------------------
    assign in_ready = 1'b1;

    // =========================================================================
    // STAGE 1
    // =========================================================================
    always_comb begin
        // ---- unpack a ----
        is_nan_a = (a[30:23] == 8'hFF) && (|a[22:0]);
        is_inf_a = (a[30:23] == 8'hFF) && !(|a[22:0]);
        is_zero_a = (a[30:23] == 8'h00) && !(|a[22:0]);
        snan_a   = is_nan_a && !a[22];
        sign_a   = a[31];

        if (a[30:23] == 8'hFF) begin
            Ea   = 0;
            sig_a = '0;
        end else if (a[30:23] == 8'h00) begin
            Ea   = -126;
            sig_a = {1'b0, a[22:0]};
        end else begin
            Ea   = a[30:23] - 127;
            sig_a = {1'b1, a[22:0]};
        end

        // ---- unpack b ----
        is_nan_b = (b[30:23] == 8'hFF) && (|b[22:0]);
        is_inf_b = (b[30:23] == 8'hFF) && !(|b[22:0]);
        is_zero_b = (b[30:23] == 8'h00) && !(|b[22:0]);
        snan_b   = is_nan_b && !b[22];
        sign_b   = b[31];

        if (b[30:23] == 8'hFF) begin
            Eb   = 0;
            sig_b = '0;
        end else if (b[30:23] == 8'h00) begin
            Eb   = -126;
            sig_b = {1'b0, b[22:0]};
        end else begin
            Eb   = b[30:23] - 127;
            sig_b = {1'b1, b[22:0]};
        end

        // ---- unpack c ----
        is_nan_c = (c[30:23] == 8'hFF) && (|c[22:0]);
        is_inf_c = (c[30:23] == 8'hFF) && !(|c[22:0]);
        sign_c_in = c[31];

        if (c[30:23] == 8'hFF) begin
            Ec   = 0;
            sig_c = '0;
        end else if (c[30:23] == 8'h00) begin
            Ec   = -126;
            sig_c = {1'b0, c[22:0]};
        end else begin
            Ec   = c[30:23] - 127;
            sig_c = {1'b1, c[22:0]};
        end

        // ---- signs ----
        sign_p_s1 = sign_a ^ sign_b;
        sign_c_s1 = sign_c_in;

        // ---- product significand and exponent ----
        // Pm = sig_a * sig_b, shifted by (Ea+Eb+252) to scale -298.
        Pm_s1 = {24'b0, sig_a} * sig_b;
        shift_prod_s1 = Ea + Eb + 252;

        // c contribution: Cm shifted by (Ec+275) to scale -298.
        Cm_s1 = sig_c;
        shift_c_s1 = Ec + 275;

        // ---- specials ----
        snan_any = snan_a | snan_b | snan_c;
        zero_inf_invalid = (is_zero_a && is_inf_b) ||
                           (is_inf_a && is_zero_b);

        product_inf_valid = (is_inf_a && !is_zero_b) ||
                            (is_inf_b && !is_zero_a);

        c_inf = is_inf_c;

        inf_inf_invalid = product_inf_valid && c_inf &&
                          (sign_c_in != (sign_a ^ sign_b));

        invalid_s1 = snan_any || zero_inf_invalid || inf_inf_invalid;
        nan_s1     = is_nan_a || is_nan_b || is_nan_c;
        inf_s1     = !nan_s1 && !invalid_s1 && (product_inf_valid || c_inf);
        inf_sign_s1 = product_inf_valid ? (sign_a ^ sign_b) : sign_c_in;
        rnd_mode_s1 = rnd_mode;
    end

    // -------------------------------------------------------------------------
    // Stage 1 -> Stage 2 registers
    // -------------------------------------------------------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_s1       <= 1'b0;
            rnd_mode_s2    <= '0;
            sign_p_s1      <= 1'b0;
            sign_c_s1      <= 1'b0;
            Pm_s1          <= '0;
            shift_prod_s1  <= 0;
            Cm_s1          <= '0;
            shift_c_s1     <= 0;
            invalid_s2     <= 1'b0;
            nan_s2         <= 1'b0;
            inf_s2         <= 1'b0;
            inf_sign_s2    <= 1'b0;
        end else begin
            valid_s1       <= in_valid;
            rnd_mode_s2    <= rnd_mode_s1;
            sign_p_s1      <= sign_p_s1;
            sign_c_s1      <= sign_c_s1;
            Pm_s1          <= Pm_s1;
            shift_prod_s1  <= shift_prod_s1;
            Cm_s1          <= Cm_s1;
            shift_c_s1     <= shift_c_s1;
            invalid_s2     <= invalid_s1;
            nan_s2         <= nan_s1;
            inf_s2         <= inf_s1;
            inf_sign_s2    <= inf_sign_s1;
        end
    end

    // =========================================================================
    // STAGE 2: exact fixed-point sum at scale -298
    // =========================================================================
    function automatic logic signed [W-1:0] shift_left_48(input logic [47:0] x,
                                                           input int sh);
        logic [W-1:0] tmp;
        tmp = {{W-48{1'b0}}, x};
        shift_left_48 = $signed(tmp << sh);
    endfunction

    function automatic logic signed [W-1:0] shift_left_24(input logic [23:0] x,
                                                           input int sh);
        logic [W-1:0] tmp;
        tmp = {{W-24{1'b0}}, x};
        shift_left_24 = $signed(tmp << sh);
    endfunction

    logic signed [W-1:0] prod_signed;
    logic signed [W-1:0] c_signed;

    always_comb begin
        prod_signed = sign_p_s1 ? -shift_left_48(Pm_s1, shift_prod_s1)
                                :  shift_left_48(Pm_s1, shift_prod_s1);
        c_signed    = sign_c_s1 ? -shift_left_24(Cm_s1, shift_c_s1)
                                :  shift_left_24(Cm_s1, shift_c_s1);
        exactN_s2   = prod_signed + c_signed;
    end

    // -------------------------------------------------------------------------
    // Stage 2 -> Stage 3 registers
    // -------------------------------------------------------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_s2       <= 1'b0;
            rnd_mode_s3    <= '0;
            invalid_s3     <= 1'b0;
            nan_s3         <= 1'b0;
            inf_s3         <= 1'b0;
            inf_sign_s3    <= 1'b0;
            exactN_s3      <= '0;
        end else begin
            valid_s2       <= valid_s1;
            rnd_mode_s3    <= rnd_mode_s2;
            invalid_s3     <= invalid_s2;
            nan_s3         <= nan_s2;
            inf_s3         <= inf_s2;
            inf_sign_s3    <= inf_sign_s2;
            exactN_s3      <= exactN_s2;
        end
    end

    // =========================================================================
    // STAGE 3: round exact fixed-point to FP32
    // =========================================================================
    function automatic int leading_one(input logic [W-1:0] x);
        for (int i = W-1; i >= 0; i--) begin
            if (x[i]) return i;
        end
        return -1;
    endfunction

    function automatic logic compute_inc(input logic [2:0] mode,
                                         input logic sign,
                                         input logic lsb,
                                         input logic guard,
                                         input logic round,
                                         input logic sticky);
        logic any_disc;
        any_disc = guard | round | sticky;
        case (mode)
            3'd0: compute_inc = guard && (round || sticky || lsb); // RNE
            3'd1: compute_inc = 1'b0;                              // RTZ
            3'd2: compute_inc = sign && any_disc;                  // RDN
            3'd3: compute_inc = !sign && any_disc;                 // RUP
            3'd4: compute_inc = guard;                             // RMM
            default: compute_inc = 1'b0;
        endcase
    endfunction

    logic        sign_exact;
    logic [W-1:0] absN;
    int          L;
    int          E_t;
    int          shift_n;
    logic [23:0] S_base_n;
    logic        guard_n, round_n, sticky_n, discarded_n;
    logic        inc_n;
    logic [24:0] S_final_n;
    logic [23:0] S_final_sub;
    logic [7:0]  biased_exp;
    logic [22:0] fraction;
    logic        overflow_case;
    logic        underflow_case;
    logic        inexact_case;
    logic        zero_sign;

    logic [31:0] result_c;
    logic        flag_invalid_c;
    logic        flag_overflow_c;
    logic        flag_underflow_c;
    logic        flag_inexact_c;

    always_comb begin
        // defaults
        result_c          = '0;
        flag_invalid_c    = 1'b0;
        flag_overflow_c   = 1'b0;
        flag_underflow_c  = 1'b0;
        flag_inexact_c    = 1'b0;
        overflow_case     = 1'b0;
        underflow_case    = 1'b0;
        inexact_case      = 1'b0;
        zero_sign         = (rnd_mode_s3 == 3'd2) ? 1'b1 : 1'b0; // RDN -> -0
        sign_exact        = exactN_s3[W-1];
        absN              = sign_exact ? -exactN_s3 : exactN_s3;
        L                 = leading_one(absN);
        E_t               = L - 298;

        if (invalid_s3) begin
            result_c        = 32'h7FC00000;
            flag_invalid_c  = 1'b1;
        end
        else if (nan_s3) begin
            result_c        = 32'h7FC00000;
        end
        else if (inf_s3) begin
            result_c        = {inf_sign_s3, 8'hFF, 23'b0};
        end
        else if (absN == '0) begin
            result_c = {zero_sign, 31'b0};
        end
        else begin
            if (E_t > 127) begin
                overflow_case = 1'b1;
            end
            else if (E_t >= -126) begin
                // ---- normal result ----
                shift_n = L - 23;
                S_base_n = (absN >> shift_n)[23:0];
                guard_n  = absN[shift_n-1];
                round_n  = absN[shift_n-2];
                sticky_n = |absN[shift_n-3:0];
                discarded_n = |absN[shift_n-1:0];

                inc_n = compute_inc(rnd_mode_s3, sign_exact,
                                    S_base_n[0], guard_n, round_n, sticky_n);

                S_final_n = {1'b0, S_base_n} + {{24{1'b0}}, inc_n};

                if (S_final_n[24]) begin
                    S_final_n = S_final_n >> 1;
                    E_t = E_t + 1;
                end

                if (E_t > 127) begin
                    overflow_case = 1'b1;
                end
                else begin
                    biased_exp = E_t + 127;
                    fraction   = S_final_n[22:0];
                    result_c   = {sign_exact, biased_exp, fraction};
                    inexact_case = discarded_n;
                end
            end
            else begin
                // ---- subnormal result ----
                shift_n = 149;
                S_base_n = (absN >> shift_n)[22:0];
                guard_n  = absN[148];
                round_n  = absN[147];
                sticky_n = |absN[146:0];
                discarded_n = |absN[148:0];

                inc_n = compute_inc(rnd_mode_s3, sign_exact,
                                    S_base_n[0], guard_n, round_n, sticky_n);

                S_final_sub = {1'b0, S_base_n} + {{23{1'b0}}, inc_n};

                if (S_final_sub[23]) begin
                    // rounds up to normal minimum
                    biased_exp = 8'd1;
                    fraction   = 23'b0;
                end
                else begin
                    biased_exp = 8'd0;
                    fraction   = S_final_sub[22:0];
                end

                result_c = {sign_exact, biased_exp, fraction};
                inexact_case = discarded_n;
                underflow_case = (biased_exp == 8'd0) && inexact_case;
            end

            // ---- overflow result ----
            if (overflow_case) begin
                flag_overflow_c = 1'b1;
                flag_inexact_c  = 1'b1;
                case (rnd_mode_s3)
                    3'd0, 3'd4: begin // RNE / RMM -> infinity
                        result_c = {sign_exact, 8'hFF, 23'b0};
                    end
                    3'd1: begin // RTZ -> max finite
                        result_c = sign_exact ? 32'hFF7FFFFF : 32'h7F7FFFFF;
                    end
                    3'd2: begin // RDN
                        result_c = sign_exact ? 32'hFF800000 : 32'h7F7FFFFF;
                    end
                    3'd3: begin // RUP
                        result_c = sign_exact ? 32'hFF7FFFFF : 32'h7F800000;
                    end
                    default: begin
                        result_c = sign_exact ? 32'hFF800000 : 32'h7F800000;
                    end
                endcase
            end
            else begin
                flag_inexact_c  = inexact_case;
                flag_underflow_c = underflow_case;
            end
        end
    end

    // -------------------------------------------------------------------------
    // Output register (latency 3)
    // -------------------------------------------------------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_valid      <= 1'b0;
            result         <= '0;
            flag_invalid   <= 1'b0;
            flag_overflow  <= 1'b0;
            flag_underflow <= 1'b0;
            flag_inexact   <= 1'b0;
            valid_s3       <= 1'b0;
        end else begin
            out_valid      <= valid_s2;
            result         <= result_c;
            flag_invalid   <= flag_invalid_c;
            flag_overflow  <= flag_overflow_c;
            flag_underflow <= flag_underflow_c;
            flag_inexact   <= flag_inexact_c;
            valid_s3       <= valid_s2;
        end
    end

endmodule