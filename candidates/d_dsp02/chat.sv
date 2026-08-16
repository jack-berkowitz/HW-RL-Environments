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

    // Every finite binary32 value is an integer multiple of 2^-149.
    // Therefore a finite product is an integer multiple of 2^-298.
    // The largest finite product has its top bit at 2^255, so indices
    // 0..553 are sufficient when bit 0 represents 2^-298. 576 leaves margin.
    localparam int EXACT_W = 576;

    localparam logic [31:0] CANON_QNAN = 32'h7fc0_0000;
    localparam logic [31:0] POS_INF    = 32'h7f80_0000;
    localparam logic [31:0] MAX_FINITE = 32'h7f7f_ffff;

    localparam logic [2:0] RM_RNE = 3'd0;
    localparam logic [2:0] RM_RTZ = 3'd1;
    localparam logic [2:0] RM_RDN = 3'd2;
    localparam logic [2:0] RM_RUP = 3'd3;
    localparam logic [2:0] RM_RMM = 3'd4;

    function automatic logic fp_is_nan(input logic [31:0] x);
        fp_is_nan = (&x[30:23]) && (|x[22:0]);
    endfunction

    function automatic logic fp_is_snan(input logic [31:0] x);
        fp_is_snan = (&x[30:23]) && (|x[22:0]) && !x[22];
    endfunction

    function automatic logic fp_is_inf(input logic [31:0] x);
        fp_is_inf = (&x[30:23]) && !(|x[22:0]);
    endfunction

    function automatic logic fp_is_zero(input logic [31:0] x);
        fp_is_zero = !(|x[30:0]);
    endfunction

    // Return the index of the most-significant 1. x is guaranteed nonzero
    // by callers that use the returned value.
    function automatic integer msb_index(input logic [EXACT_W-1:0] x);
        integer i;
        begin
            msb_index = -1;
            for (i = 0; i < EXACT_W; i = i + 1)
                if (x[i])
                    msb_index = i;
        end
    endfunction

    // Finite-result rounding/packing.
    // Return layout: {overflow, underflow, inexact, result[31:0]}.
    function automatic logic [34:0] round_finite(
        input logic [EXACT_W-1:0] mag,
        input logic               sign,
        input logic [2:0]         rm
    );
        integer k;
        integer e_unbiased;
        integer cut;

        logic [EXACT_W-1:0] shifted;
        logic [EXACT_W-1:0] discarded;
        logic [23:0]         kept24;
        logic [24:0]         rounded25;
        logic                guard;
        logic                sticky;
        logic                discarded_nonzero;
        logic                increment;
        logic                ovf;
        logic                udf;
        logic                inex;
        logic [31:0]         r;

        begin
            shifted           = '0;
            discarded         = '0;
            kept24            = '0;
            rounded25         = '0;
            guard             = 1'b0;
            sticky            = 1'b0;
            discarded_nonzero = 1'b0;
            increment         = 1'b0;
            ovf               = 1'b0;
            udf               = 1'b0;
            inex              = 1'b0;
            r                 = {sign, 31'b0};
            k                 = -1;
            e_unbiased        = 0;
            cut               = 0;

            if (mag != '0) begin
                k          = msb_index(mag);
                e_unbiased = k - 298;

                if (e_unbiased >= -126) begin
                    // Normal path.
                    // Keep the top 24 bits: hidden bit + 23 fraction bits.
                    cut     = k - 23;
                    shifted = mag >> cut;
                    kept24  = shifted[23:0];

                    // Move discarded bits so the first discarded bit becomes
                    // guard and all remaining bits reduce into sticky.
                    discarded         = mag << (EXACT_W - cut);
                    guard             = discarded[EXACT_W-1];
                    sticky            = |discarded[EXACT_W-2:0];
                    discarded_nonzero = guard | sticky;

                    case (rm)
                        RM_RNE:
                            increment = guard && (sticky || kept24[0]);

                        RM_RTZ:
                            increment = 1'b0;

                        RM_RDN:
                            increment = sign && discarded_nonzero;

                        RM_RUP:
                            increment = !sign && discarded_nonzero;

                        RM_RMM:
                            increment = guard;

                        default:
                            increment = 1'b0;
                    endcase

                    rounded25 = {1'b0, kept24}
                              + {{24{1'b0}}, increment};

                    inex = discarded_nonzero;

                    // Carry out of significand renormalizes by one bit.
                    if (rounded25[24]) begin
                        kept24     = rounded25[24:1];
                        e_unbiased = e_unbiased + 1;
                    end
                    else begin
                        kept24 = rounded25[23:0];
                    end

                    if (e_unbiased > 127) begin
                        ovf  = 1'b1;
                        inex = 1'b1;

                        case (rm)
                            RM_RTZ:
                                r = {sign, MAX_FINITE[30:0]};

                            RM_RDN:
                                r = sign
                                    ? {1'b1, POS_INF[30:0]}
                                    : {1'b0, MAX_FINITE[30:0]};

                            RM_RUP:
                                r = sign
                                    ? {1'b1, MAX_FINITE[30:0]}
                                    : {1'b0, POS_INF[30:0]};

                            default:
                                // RNE and RMM
                                r = {sign, POS_INF[30:0]};
                        endcase
                    end
                    else begin
                        r[31]    = sign;
                        r[30:23] = e_unbiased + 127;
                        r[22:0]  = kept24[22:0];
                    end
                end
                else begin
                    // Subnormal path.
                    // Binary32's subnormal quantum is 2^-149.
                    // Since accumulator bit 0 represents 2^-298,
                    // accumulator bit 149 corresponds to 2^-149.
                    cut     = 149;
                    shifted = mag >> cut;
                    kept24  = shifted[23:0];

                    discarded         = mag << (EXACT_W - cut);
                    guard             = discarded[EXACT_W-1];
                    sticky            = |discarded[EXACT_W-2:0];
                    discarded_nonzero = guard | sticky;

                    case (rm)
                        RM_RNE:
                            increment = guard && (sticky || kept24[0]);

                        RM_RTZ:
                            increment = 1'b0;

                        RM_RDN:
                            increment = sign && discarded_nonzero;

                        RM_RUP:
                            increment = !sign && discarded_nonzero;

                        RM_RMM:
                            increment = guard;

                        default:
                            increment = 1'b0;
                    endcase

                    rounded25 = {1'b0, kept24}
                              + {{24{1'b0}}, increment};

                    inex = discarded_nonzero;

                    if (rounded25[23]) begin
                        // Rounded from the subnormal region to the smallest
                        // normal. Tininess is detected AFTER rounding, so
                        // underflow is not raised.
                        r   = {sign, 8'h01, 23'b0};
                        udf = 1'b0;
                    end
                    else begin
                        r = {
                            sign,
                            8'h00,
                            rounded25[22:0]
                        };

                        // Tiny after rounding AND inexact.
                        udf = discarded_nonzero;
                    end
                end
            end

            round_finite = {
                ovf,
                udf,
                inex,
                r
            };
        end
    endfunction

    logic [31:0] comb_result;
    logic        comb_invalid;
    logic        comb_overflow;
    logic        comb_underflow;
    logic        comb_inexact;

    always_comb begin : fma_comb
        logic a_nan;
        logic b_nan;
        logic c_nan;

        logic a_snan;
        logic b_snan;
        logic c_snan;

        logic a_inf;
        logic b_inf;
        logic c_inf;

        logic a_zero;
        logic b_zero;
        logic c_zero;

        logic prod_sign;
        logic prod_inf;
        logic mul_invalid;
        logic add_invalid;

        logic [23:0] sig_a;
        logic [23:0] sig_b;
        logic [23:0] sig_c;

        logic [47:0] prod_sig;

        integer scale_a;
        integer scale_b;
        integer scale_c;

        integer prod_shift;
        integer c_shift;

        logic [EXACT_W-1:0] prod_mag;
        logic [EXACT_W-1:0] c_mag;
        logic [EXACT_W-1:0] exact_mag;

        logic exact_sign;
        logic prod_zero_finite;

        logic [34:0] rounded;

        comb_result    = 32'b0;
        comb_invalid   = 1'b0;
        comb_overflow  = 1'b0;
        comb_underflow = 1'b0;
        comb_inexact   = 1'b0;

        a_nan  = fp_is_nan(a);
        b_nan  = fp_is_nan(b);
        c_nan  = fp_is_nan(c);

        a_snan = fp_is_snan(a);
        b_snan = fp_is_snan(b);
        c_snan = fp_is_snan(c);

        a_inf  = fp_is_inf(a);
        b_inf  = fp_is_inf(b);
        c_inf  = fp_is_inf(c);

        a_zero = fp_is_zero(a);
        b_zero = fp_is_zero(b);
        c_zero = fp_is_zero(c);

        prod_sign = a[31] ^ b[31];

        mul_invalid =
            (a_inf && b_zero) ||
            (b_inf && a_zero);

        prod_inf =
            (a_inf || b_inf) &&
            !mul_invalid &&
            !a_nan &&
            !b_nan;

        add_invalid =
            prod_inf &&
            c_inf &&
            (prod_sign != c[31]);

        comb_invalid =
            a_snan ||
            b_snan ||
            c_snan ||
            mul_invalid ||
            add_invalid;

        // Any NaN operand or invalid arithmetic produces the pinned
        // canonical quiet NaN.
        if (
            a_nan ||
            b_nan ||
            c_nan ||
            mul_invalid ||
            add_invalid
        ) begin
            comb_result = CANON_QNAN;
        end
        else if (prod_inf) begin
            comb_result = {
                prod_sign,
                POS_INF[30:0]
            };
        end
        else if (c_inf) begin
            comb_result = {
                c[31],
                POS_INF[30:0]
            };
        end
        else begin
            // -------------------------------------------------------------
            // Decode finite A
            //
            // The value is represented as:
            //
            //     sig_a * 2^scale_a
            //
            // For a normal:
            //     sig = {1, fraction}
            //     scale = exponent_field - 150
            //
            // For a subnormal:
            //     sig = fraction
            //     scale = -149
            // -------------------------------------------------------------
            if (a[30:23] == 8'h00) begin
                sig_a   = {1'b0, a[22:0]};
                scale_a = -149;
            end
            else begin
                sig_a   = {1'b1, a[22:0]};
                scale_a = a[30:23];
                scale_a = scale_a - 150;
            end

            // Decode finite B
            if (b[30:23] == 8'h00) begin
                sig_b   = {1'b0, b[22:0]};
                scale_b = -149;
            end
            else begin
                sig_b   = {1'b1, b[22:0]};
                scale_b = b[30:23];
                scale_b = scale_b - 150;
            end

            // Decode finite C
            if (c[30:23] == 8'h00) begin
                sig_c   = {1'b0, c[22:0]};
                scale_c = -149;
            end
            else begin
                sig_c   = {1'b1, c[22:0]};
                scale_c = c[30:23];
                scale_c = scale_c - 150;
            end

            // Full 24 x 24 = 48-bit product.
            // No rounding occurs here.
            prod_sig =
                {24'b0, sig_a} *
                {24'b0, sig_b};

            // Exact accumulator bit 0 represents 2^-298.
            prod_shift =
                scale_a +
                scale_b +
                298;

            c_shift =
                scale_c +
                298;

            prod_mag =
                {{(EXACT_W-48){1'b0}}, prod_sig}
                << prod_shift;

            c_mag =
                {{(EXACT_W-24){1'b0}}, sig_c}
                << c_shift;

            prod_zero_finite =
                (sig_a == 24'b0) ||
                (sig_b == 24'b0);

            // Exact signed addition/subtraction.
            if (prod_sign == c[31]) begin
                exact_mag  = prod_mag + c_mag;
                exact_sign = prod_sign;
            end
            else if (prod_mag > c_mag) begin
                exact_mag  = prod_mag - c_mag;
                exact_sign = prod_sign;
            end
            else if (c_mag > prod_mag) begin
                exact_mag  = c_mag - prod_mag;
                exact_sign = c[31];
            end
            else begin
                // Exact cancellation.
                exact_mag = '0;

                // Exact-zero sign rules:
                //
                // Same-signed zero + zero keeps that sign.
                //
                // Opposite-signed zero or exact cancellation produces
                // -0 only under round-toward-negative-infinity.
                if (
                    prod_zero_finite &&
                    c_zero &&
                    (prod_sign == c[31])
                ) begin
                    exact_sign = prod_sign;
                end
                else begin
                    exact_sign = (rnd_mode == RM_RDN);
                end
            end

            // Exactly one rounding operation occurs here.
            rounded = round_finite(
                exact_mag,
                exact_sign,
                rnd_mode
            );

            comb_overflow  = rounded[34];
            comb_underflow = rounded[33];
            comb_inexact   = rounded[32];
            comb_result    = rounded[31:0];
        end
    end

    // ---------------------------------------------------------------------
    // One-entry elastic output stage.
    //
    // With out_ready asserted continuously:
    //
    //     in_ready = 1 every non-reset cycle
    //
    // so a new transaction can be accepted every cycle (II = 1).
    //
    // If the consumer stalls, the current result and all flags remain stable.
    // ---------------------------------------------------------------------

    logic        out_valid_q;
    logic [31:0] result_q;

    logic invalid_q;
    logic overflow_q;
    logic underflow_q;
    logic inexact_q;

    always_comb begin
        in_ready =
            rst_n &&
            (!out_valid_q || out_ready);

        out_valid      = out_valid_q;
        result         = result_q;
        flag_invalid   = invalid_q;
        flag_overflow  = overflow_q;
        flag_underflow = underflow_q;
        flag_inexact   = inexact_q;
    end

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            out_valid_q <= 1'b0;

            result_q    <= 32'b0;

            invalid_q   <= 1'b0;
            overflow_q  <= 1'b0;
            underflow_q <= 1'b0;
            inexact_q   <= 1'b0;
        end
        else if (!out_valid_q || out_ready) begin
            out_valid_q <= in_valid;

            if (in_valid) begin
                result_q    <= comb_result;
                invalid_q   <= comb_invalid;
                overflow_q  <= comb_overflow;
                underflow_q <= comb_underflow;
                inexact_q   <= comb_inexact;
            end
        end
    end

endmodule