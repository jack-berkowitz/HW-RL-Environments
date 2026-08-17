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

    // ------------------------------------------------------------------------
    // Exact representation
    //
    // Every binary32 value is an integer multiple of 2^-149.
    // Therefore every binary32 product is an integer multiple of 2^-298.
    //
    // Accumulator bit 0 represents 2^-298.
    //
    // Largest finite product is below 2^256, giving a highest possible
    // accumulator bit near 553. 576 bits therefore provides sufficient range.
    // ------------------------------------------------------------------------
    localparam integer EXACT_W = 576;

    localparam logic [31:0] CANON_QNAN = 32'h7FC0_0000;
    localparam logic [31:0] POS_INF    = 32'h7F80_0000;
    localparam logic [31:0] MAX_FINITE = 32'h7F7F_FFFF;

    localparam logic [2:0] RM_RNE = 3'd0;
    localparam logic [2:0] RM_RTZ = 3'd1;
    localparam logic [2:0] RM_RDN = 3'd2;
    localparam logic [2:0] RM_RUP = 3'd3;
    localparam logic [2:0] RM_RMM = 3'd4;


    // ========================================================================
    // Classification helpers
    // ========================================================================

    function automatic logic fp_is_nan(input logic [31:0] x);
        fp_is_nan =
            (x[30:23] == 8'hFF) &&
            (x[22:0]  != 23'b0);
    endfunction

    function automatic logic fp_is_snan(input logic [31:0] x);
        fp_is_snan =
            (x[30:23] == 8'hFF) &&
            (x[22:0]  != 23'b0) &&
            (x[22]    == 1'b0);
    endfunction

    function automatic logic fp_is_inf(input logic [31:0] x);
        fp_is_inf =
            (x[30:23] == 8'hFF) &&
            (x[22:0]  == 23'b0);
    endfunction

    function automatic logic fp_is_zero(input logic [31:0] x);
        fp_is_zero = (x[30:0] == 31'b0);
    endfunction


    // ========================================================================
    // MSB position
    // ========================================================================

    function automatic integer msb_index(
        input logic [EXACT_W-1:0] x
    );
        integer i;
        begin
            msb_index = -1;

            for (i = 0; i < EXACT_W; i = i + 1) begin
                if (x[i])
                    msb_index = i;
            end
        end
    endfunction


    // ========================================================================
    // Final IEEE binary32 rounding
    //
    // Return:
    //   [34]    overflow
    //   [33]    underflow
    //   [32]    inexact
    //   [31:0]  result
    //
    // Input magnitude is exact and uses the fixed-point scale:
    //
    //                 bit 0 = 2^-298
    //
    // This is the ONLY rounding operation in the FMA.
    // ========================================================================

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

        logic [23:0] kept24;
        logic [24:0] rounded25;

        logic guard;
        logic sticky;
        logic discarded_nonzero;
        logic increment;

        logic ovf;
        logic udf;
        logic inex;

        logic [31:0] r;

        begin
            k                 = -1;
            e_unbiased        = 0;
            cut               = 0;

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


            // ----------------------------------------------------------------
            // Exact zero
            // ----------------------------------------------------------------
            if (mag == '0) begin
                r = {sign, 31'b0};
            end

            else begin
                k          = msb_index(mag);

                // bit k represents 2^(k-298)
                e_unbiased = k - 298;


                // ============================================================
                // NORMAL RESULT REGION
                // ============================================================
                if (e_unbiased >= -126) begin

                    // Retain 24 significant bits:
                    //
                    //   hidden 1 + 23 fraction bits
                    //
                    cut = k - 23;

                    shifted = mag >> cut;
                    kept24  = shifted[23:0];

                    // Lowest retained bit is mag[cut].
                    // Guard is mag[cut-1].
                    //
                    // Shift discarded portion so guard lands at MSB.
                    discarded = mag << (EXACT_W - cut);

                    guard  = discarded[EXACT_W-1];
                    sticky = |discarded[EXACT_W-2:0];

                    discarded_nonzero = guard | sticky;


                    // --------------------------------------------------------
                    // Runtime rounding mode
                    // --------------------------------------------------------
                    case (rm)

                        RM_RNE: begin
                            // nearest, ties-to-even
                            increment =
                                guard &&
                                (sticky || kept24[0]);
                        end

                        RM_RTZ: begin
                            increment = 1'b0;
                        end

                        RM_RDN: begin
                            increment =
                                sign &&
                                discarded_nonzero;
                        end

                        RM_RUP: begin
                            increment =
                                !sign &&
                                discarded_nonzero;
                        end

                        RM_RMM: begin
                            // nearest, ties-away
                            increment = guard;
                        end

                        default: begin
                            increment = 1'b0;
                        end
                    endcase


                    rounded25 =
                        {1'b0, kept24} +
                        {{24{1'b0}}, increment};

                    inex = discarded_nonzero;


                    // --------------------------------------------------------
                    // Rounding carry
                    //
                    // 1.111... -> 10.000...
                    // --------------------------------------------------------
                    if (rounded25[24]) begin
                        kept24     = rounded25[24:1];
                        e_unbiased = e_unbiased + 1;
                    end
                    else begin
                        kept24 = rounded25[23:0];
                    end


                    // --------------------------------------------------------
                    // Overflow
                    // --------------------------------------------------------
                    if (e_unbiased > 127) begin

                        ovf  = 1'b1;
                        inex = 1'b1;

                        case (rm)

                            RM_RTZ: begin
                                r = {
                                    sign,
                                    MAX_FINITE[30:0]
                                };
                            end

                            RM_RDN: begin
                                if (sign)
                                    r = 32'hFF80_0000;
                                else
                                    r = 32'h7F7F_FFFF;
                            end

                            RM_RUP: begin
                                if (sign)
                                    r = 32'hFF7F_FFFF;
                                else
                                    r = 32'h7F80_0000;
                            end

                            default: begin
                                // RNE / RMM
                                r = {
                                    sign,
                                    POS_INF[30:0]
                                };
                            end

                        endcase
                    end

                    else begin

                        r[31]    = sign;
                        r[30:23] = e_unbiased + 127;
                        r[22:0]  = kept24[22:0];

                    end
                end


                // ============================================================
                // SUBNORMAL RESULT REGION
                // ============================================================
                else begin

                    // A binary32 subnormal quantum is 2^-149.
                    //
                    // Accumulator bit 149 represents:
                    //
                    //       2^(149-298) = 2^-149
                    //
                    // Therefore bits [148:0] are discarded.
                    cut = 149;

                    shifted = mag >> cut;
                    kept24  = shifted[23:0];

                    discarded = mag << (EXACT_W - cut);

                    guard  = discarded[EXACT_W-1];
                    sticky = |discarded[EXACT_W-2:0];

                    discarded_nonzero = guard | sticky;


                    case (rm)

                        RM_RNE: begin
                            increment =
                                guard &&
                                (sticky || kept24[0]);
                        end

                        RM_RTZ: begin
                            increment = 1'b0;
                        end

                        RM_RDN: begin
                            increment =
                                sign &&
                                discarded_nonzero;
                        end

                        RM_RUP: begin
                            increment =
                                !sign &&
                                discarded_nonzero;
                        end

                        RM_RMM: begin
                            increment = guard;
                        end

                        default: begin
                            increment = 1'b0;
                        end

                    endcase


                    rounded25 =
                        {1'b0, kept24} +
                        {{24{1'b0}}, increment};

                    inex = discarded_nonzero;


                    // --------------------------------------------------------
                    // Rounded upward into smallest NORMAL number.
                    //
                    // Tininess is detected AFTER rounding, therefore this is
                    // NOT an underflow.
                    // --------------------------------------------------------
                    if (rounded25[23]) begin

                        r = {
                            sign,
                            8'h01,
                            23'b0
                        };

                        udf = 1'b0;

                    end

                    else begin

                        r = {
                            sign,
                            8'h00,
                            rounded25[22:0]
                        };

                        // AFTER-rounding tininess:
                        //
                        // underflow iff:
                        //     rounded result is tiny
                        // AND operation was inexact.
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


    // ========================================================================
    // STAGE 1
    //
    // Classify operands and compute the exact 24x24 product significand.
    //
    // A finite operand is represented as:
    //
    //     sig * 2^-149 * 2^shift
    //
    // subnormal:
    //     shift = 0
    //
    // normal:
    //     shift = exponent_field - 1
    //
    // This makes exact product placement particularly simple.
    // ========================================================================

    logic s1_valid;

    logic        s1_special;
    logic [31:0] s1_special_result;
    logic        s1_invalid;

    logic [2:0]  s1_rnd_mode;

    logic        s1_prod_sign;
    logic        s1_c_sign;

    logic        s1_prod_zero;
    logic        s1_c_zero;

    logic [47:0] s1_prod_sig;
    logic [23:0] s1_c_sig;

    logic [8:0]  s1_prod_shift;
    logic [8:0]  s1_c_shift;


    // Stage-1 combinational values

    logic        st1_special;
    logic [31:0] st1_special_result;
    logic        st1_invalid;

    logic        st1_prod_sign;
    logic        st1_prod_zero;
    logic        st1_c_zero;

    logic [23:0] st1_a_sig;
    logic [23:0] st1_b_sig;
    logic [23:0] st1_c_sig;

    logic [7:0]  st1_a_exp;
    logic [7:0]  st1_b_exp;
    logic [7:0]  st1_c_exp;

    logic [8:0]  st1_a_shift;
    logic [8:0]  st1_b_shift;
    logic [8:0]  st1_c_base_shift;

    logic [47:0] st1_prod_sig;
    logic [8:0]  st1_prod_shift;
    logic [8:0]  st1_c_shift;


    always_comb begin : stage1_comb

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

        logic mul_invalid;
        logic prod_inf;
        logic add_invalid;


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


        st1_prod_sign = a[31] ^ b[31];

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
            (st1_prod_sign != c[31]);


        st1_invalid =
            a_snan ||
            b_snan ||
            c_snan ||
            mul_invalid ||
            add_invalid;


        st1_special        = 1'b0;
        st1_special_result = 32'b0;


        // --------------------------------------------------------------------
        // NaN / invalid
        // --------------------------------------------------------------------
        if (
            a_nan ||
            b_nan ||
            c_nan ||
            mul_invalid ||
            add_invalid
        ) begin

            st1_special        = 1'b1;
            st1_special_result = CANON_QNAN;

        end

        // --------------------------------------------------------------------
        // Infinite product
        // --------------------------------------------------------------------
        else if (prod_inf) begin

            st1_special = 1'b1;

            st1_special_result = {
                st1_prod_sign,
                POS_INF[30:0]
            };

        end

        // --------------------------------------------------------------------
        // Infinite addend
        // --------------------------------------------------------------------
        else if (c_inf) begin

            st1_special = 1'b1;

            st1_special_result = {
                c[31],
                POS_INF[30:0]
            };

        end


        // --------------------------------------------------------------------
        // Finite significands
        // --------------------------------------------------------------------

        st1_a_exp = a[30:23];
        st1_b_exp = b[30:23];
        st1_c_exp = c[30:23];


        if (st1_a_exp == 8'h00) begin
            st1_a_sig   = {1'b0, a[22:0]};
            st1_a_shift = 9'd0;
        end
        else begin
            st1_a_sig   = {1'b1, a[22:0]};
            st1_a_shift = {1'b0, st1_a_exp} - 9'd1;
        end


        if (st1_b_exp == 8'h00) begin
            st1_b_sig   = {1'b0, b[22:0]};
            st1_b_shift = 9'd0;
        end
        else begin
            st1_b_sig   = {1'b1, b[22:0]};
            st1_b_shift = {1'b0, st1_b_exp} - 9'd1;
        end


        if (st1_c_exp == 8'h00) begin
            st1_c_sig        = {1'b0, c[22:0]};
            st1_c_base_shift = 9'd0;
        end
        else begin
            st1_c_sig        = {1'b1, c[22:0]};
            st1_c_base_shift =
                {1'b0, st1_c_exp} - 9'd1;
        end


        // Full exact significand product.
        st1_prod_sig =
            st1_a_sig *
            st1_b_sig;


        // Product's scale relative to accumulator bit zero = 2^-298.
        st1_prod_shift =
            st1_a_shift +
            st1_b_shift;


        // C is a multiple of 2^-149, while the accumulator quantum is
        // 2^-298, hence the additional 149-bit displacement.
        st1_c_shift =
            9'd149 +
            st1_c_base_shift;


        st1_prod_zero =
            a_zero ||
            b_zero;

        st1_c_zero = c_zero;

    end


    // ========================================================================
    // STAGE 2
    //
    // Align product and C into the exact 576-bit fixed-point domain and
    // perform the exact signed addition/subtraction.
    // ========================================================================

    logic s2_valid;

    logic        s2_special;
    logic [31:0] s2_special_result;
    logic        s2_invalid;

    logic [2:0]  s2_rnd_mode;

    logic [EXACT_W-1:0] s2_exact_mag;
    logic               s2_exact_sign;


    logic        st2_special;
    logic [31:0] st2_special_result;
    logic        st2_invalid;

    logic [EXACT_W-1:0] st2_prod_mag;
    logic [EXACT_W-1:0] st2_c_mag;

    logic [EXACT_W-1:0] st2_exact_mag;
    logic               st2_exact_sign;


    always_comb begin : stage2_comb

        st2_special        = s1_special;
        st2_special_result = s1_special_result;
        st2_invalid        = s1_invalid;

        st2_prod_mag = '0;
        st2_c_mag    = '0;

        st2_exact_mag  = '0;
        st2_exact_sign = 1'b0;


        if (!s1_special) begin

            // ---------------------------------------------------------------
            // Exact alignment
            // ---------------------------------------------------------------

            st2_prod_mag =
                {{(EXACT_W-48){1'b0}}, s1_prod_sig}
                << s1_prod_shift;

            st2_c_mag =
                {{(EXACT_W-24){1'b0}}, s1_c_sig}
                << s1_c_shift;


            // ---------------------------------------------------------------
            // Exact signed addition
            // ---------------------------------------------------------------

            if (s1_prod_sign == s1_c_sign) begin

                st2_exact_mag =
                    st2_prod_mag +
                    st2_c_mag;

                st2_exact_sign =
                    s1_prod_sign;

            end

            else if (st2_prod_mag > st2_c_mag) begin

                st2_exact_mag =
                    st2_prod_mag -
                    st2_c_mag;

                st2_exact_sign =
                    s1_prod_sign;

            end

            else if (st2_c_mag > st2_prod_mag) begin

                st2_exact_mag =
                    st2_c_mag -
                    st2_prod_mag;

                st2_exact_sign =
                    s1_c_sign;

            end

            else begin

                // -----------------------------------------------------------
                // Exact cancellation / exact zero
                // -----------------------------------------------------------

                st2_exact_mag = '0;

                // Same-sign zero + zero preserves that zero sign.
                //
                // Otherwise exact cancellation is +0 except under RDN,
                // where IEEE requires -0.
                if (
                    s1_prod_zero &&
                    s1_c_zero &&
                    (s1_prod_sign == s1_c_sign)
                ) begin

                    st2_exact_sign =
                        s1_prod_sign;

                end
                else begin

                    st2_exact_sign =
                        (s1_rnd_mode == RM_RDN);

                end

            end
        end
    end


    // ========================================================================
    // STAGE 3
    //
    // Normalize, round exactly once, pack binary32, generate flags.
    // ========================================================================

    logic s3_valid;

    logic [31:0] s3_result;
    logic        s3_invalid;
    logic        s3_overflow;
    logic        s3_underflow;
    logic        s3_inexact;


    logic [31:0] st3_result;
    logic        st3_invalid;
    logic        st3_overflow;
    logic        st3_underflow;
    logic        st3_inexact;

    logic [34:0] st3_rounded;


    always_comb begin : stage3_comb

        st3_result    = 32'b0;
        st3_invalid   = 1'b0;
        st3_overflow  = 1'b0;
        st3_underflow = 1'b0;
        st3_inexact   = 1'b0;

        st3_rounded   = '0;


        if (s2_special) begin

            st3_result  = s2_special_result;
            st3_invalid = s2_invalid;

        end

        else begin

            // ================================================================
            // Exactly one rounding of exact (a*b + c)
            // ================================================================

            st3_rounded =
                round_finite(
                    s2_exact_mag,
                    s2_exact_sign,
                    s2_rnd_mode
                );

            st3_overflow  = st3_rounded[34];
            st3_underflow = st3_rounded[33];
            st3_inexact   = st3_rounded[32];
            st3_result    = st3_rounded[31:0];

        end
    end


    // ========================================================================
    // ELASTIC PIPELINE READY CHAIN
    //
    // Each pipeline stage can advance if:
    //
    //   - it is empty, or
    //   - the following stage can advance.
    //
    // With out_ready continuously asserted:
    //
    //      s3_ready = 1
    //      s2_ready = 1
    //      s1_ready = 1
    //      in_ready = 1
    //
    // Therefore initiation interval = 1.
    // ========================================================================

    logic s3_ready;
    logic s2_ready;
    logic s1_ready;


    always_comb begin

        s3_ready =
            !s3_valid ||
            out_ready;

        s2_ready =
            !s2_valid ||
            s3_ready;

        s1_ready =
            !s1_valid ||
            s2_ready;


        // H1: does not depend combinationally on in_valid.
        in_ready =
            rst_n &&
            s1_ready;


        // R2: out_valid is forced low whenever reset is asserted.
        out_valid =
            rst_n &&
            s3_valid;


        result         = s3_result;
        flag_invalid   = s3_invalid;
        flag_overflow  = s3_overflow;
        flag_underflow = s3_underflow;
        flag_inexact   = s3_inexact;

    end


    // ========================================================================
    // PIPELINE REGISTERS
    //
    // Active-low SYNCHRONOUS reset.
    // ========================================================================

    always_ff @(posedge clk) begin

        if (!rst_n) begin

            s1_valid <= 1'b0;
            s2_valid <= 1'b0;
            s3_valid <= 1'b0;


            s1_special        <= 1'b0;
            s1_special_result <= 32'b0;
            s1_invalid        <= 1'b0;

            s1_rnd_mode       <= 3'b0;

            s1_prod_sign      <= 1'b0;
            s1_c_sign         <= 1'b0;

            s1_prod_zero      <= 1'b0;
            s1_c_zero         <= 1'b0;

            s1_prod_sig       <= 48'b0;
            s1_c_sig          <= 24'b0;

            s1_prod_shift     <= 9'b0;
            s1_c_shift        <= 9'b0;


            s2_special        <= 1'b0;
            s2_special_result <= 32'b0;
            s2_invalid        <= 1'b0;

            s2_rnd_mode       <= 3'b0;

            s2_exact_mag      <= '0;
            s2_exact_sign     <= 1'b0;


            s3_result         <= 32'b0;
            s3_invalid        <= 1'b0;
            s3_overflow       <= 1'b0;
            s3_underflow      <= 1'b0;
            s3_inexact        <= 1'b0;

        end

        else begin

            // ================================================================
            // Stage 3
            // ================================================================
            if (s3_ready) begin

                s3_valid <= s2_valid;

                if (s2_valid) begin

                    s3_result    <= st3_result;
                    s3_invalid   <= st3_invalid;
                    s3_overflow  <= st3_overflow;
                    s3_underflow <= st3_underflow;
                    s3_inexact   <= st3_inexact;

                end
            end


            // ================================================================
            // Stage 2
            // ================================================================
            if (s2_ready) begin

                s2_valid <= s1_valid;

                if (s1_valid) begin

                    s2_special        <= st2_special;
                    s2_special_result <= st2_special_result;
                    s2_invalid        <= st2_invalid;

                    s2_rnd_mode       <= s1_rnd_mode;

                    s2_exact_mag      <= st2_exact_mag;
                    s2_exact_sign     <= st2_exact_sign;

                end
            end


            // ================================================================
            // Stage 1
            // ================================================================
            if (s1_ready) begin

                s1_valid <= in_valid;

                if (in_valid) begin

                    s1_special        <= st1_special;
                    s1_special_result <= st1_special_result;
                    s1_invalid        <= st1_invalid;

                    s1_rnd_mode       <= rnd_mode;

                    s1_prod_sign      <= st1_prod_sign;
                    s1_c_sign         <= c[31];

                    s1_prod_zero      <= st1_prod_zero;
                    s1_c_zero         <= st1_c_zero;

                    s1_prod_sig       <= st1_prod_sig;
                    s1_c_sig          <= st1_c_sig;

                    s1_prod_shift     <= st1_prod_shift;
                    s1_c_shift        <= st1_c_shift;

                end
            end

        end
    end

endmodule