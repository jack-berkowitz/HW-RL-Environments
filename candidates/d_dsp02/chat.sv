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

    localparam logic [31:0] CANON_QNAN = 32'h7fc00000;

    /*
     * Internal significand window.
     *
     * 80 bits < the contractual 96-bit maximum.  Operands which lie below
     * the retained window are reduced to a sticky unit.  Whenever cancellation
     * is possible, both exact operands fit in the window because the product
     * has at most 48 significant bits and c has at most 24.
     */
    localparam integer ALIGN_W   = 80;
    localparam integer ALIGN_TOP = 76;


    /*
     * ------------------------------------------------------------------------
     * Leading-one helpers.
     * ------------------------------------------------------------------------
     */

    function automatic integer msb8(
        input logic [7:0] v
    );
        begin
            if      (v[7]) msb8 = 7;
            else if (v[6]) msb8 = 6;
            else if (v[5]) msb8 = 5;
            else if (v[4]) msb8 = 4;
            else if (v[3]) msb8 = 3;
            else if (v[2]) msb8 = 2;
            else if (v[1]) msb8 = 1;
            else           msb8 = 0;
        end
    endfunction


    function automatic integer msb16(
        input logic [15:0] v
    );
        begin
            if (|v[15:8])
                msb16 = 8 + msb8(v[15:8]);
            else
                msb16 = msb8(v[7:0]);
        end
    endfunction


    function automatic integer msb24(
        input logic [23:0] v
    );
        begin
            if (|v[23:16])
                msb24 = 16 + msb8(v[23:16]);
            else
                msb24 = msb16(v[15:0]);
        end
    endfunction


    function automatic integer msb48(
        input logic [47:0] v
    );
        begin
            if (|v[47:32])
                msb48 = 32 + msb16(v[47:32]);
            else if (|v[31:16])
                msb48 = 16 + msb16(v[31:16]);
            else
                msb48 = msb16(v[15:0]);
        end
    endfunction


    function automatic integer msb80(
        input logic [79:0] v
    );
        begin
            if (|v[79:64])
                msb80 = 64 + msb16(v[79:64]);
            else if (|v[63:48])
                msb80 = 48 + msb16(v[63:48]);
            else if (|v[47:32])
                msb80 = 32 + msb16(v[47:32]);
            else if (|v[31:16])
                msb80 = 16 + msb16(v[31:16]);
            else
                msb80 = msb16(v[15:0]);
        end
    endfunction


    /*
     * ------------------------------------------------------------------------
     * Align one exact integer significand into the bounded accumulator window.
     *
     * Exact value represented by the source is:
     *
     *      mag * 2^lsb_exp
     *
     * Returned integer is in units of 2^base_exp.
     *
     * If bits fall below the 80-bit window they are compressed into bit zero.
     * ------------------------------------------------------------------------
     */

    function automatic logic [79:0] align80(
        input logic [47:0] mag,
        input integer      lsb_exp,
        input integer      base_exp
    );
        integer delta;
        integer rshift;
        logic [79:0] tmp;
        logic [79:0] shifted;
        logic [79:0] mask;
        logic sticky;

        begin
            tmp     = {{32{1'b0}}, mag};
            shifted = 80'b0;
            mask    = 80'b0;
            sticky  = 1'b0;

            delta = lsb_exp - base_exp;

            if (mag == 48'b0) begin
                align80 = 80'b0;
            end
            else if (delta >= 0) begin
                align80 = tmp << delta;
            end
            else begin
                rshift = -delta;

                if (rshift >= 80) begin
                    /*
                     * Entire term lies below the retained window.
                     */
                    align80 = 80'd1;
                end
                else begin
                    shifted = tmp >> rshift;

                    mask =
                        (80'd1 << rshift) -
                        80'd1;

                    sticky =
                        |(tmp & mask);

                    shifted[0] =
                        shifted[0] |
                        sticky;

                    align80 = shifted;
                end
            end
        end
    endfunction


    /*
     * ------------------------------------------------------------------------
     * Result selected after overflow.
     * ------------------------------------------------------------------------
     */

    function automatic logic [31:0] overflow_value(
        input logic       sign,
        input logic [2:0] rnd
    );
        logic to_inf;

        begin
            to_inf = 1'b0;

            case (rnd)
                /*
                 * RNE
                 */
                3'd0:
                    to_inf = 1'b1;

                /*
                 * RTZ
                 */
                3'd1:
                    to_inf = 1'b0;

                /*
                 * RDN:
                 * positive -> max finite
                 * negative -> -infinity
                 */
                3'd2:
                    to_inf = sign;

                /*
                 * RUP:
                 * positive -> +infinity
                 * negative -> max finite magnitude
                 */
                3'd3:
                    to_inf = !sign;

                /*
                 * RMM
                 */
                3'd4:
                    to_inf = 1'b1;

                default:
                    to_inf = 1'b1;
            endcase

            if (to_inf)
                overflow_value = {
                    sign,
                    8'hff,
                    23'b0
                };
            else
                overflow_value = {
                    sign,
                    8'hfe,
                    23'h7fffff
                };
        end
    endfunction


    /*
     * ------------------------------------------------------------------------
     * Exact fused arithmetic + one binary32 rounding.
     *
     * Return layout:
     *
     *   [35]    invalid
     *   [34]    overflow
     *   [33]    underflow
     *   [32]    inexact
     *   [31:0]  result
     * ------------------------------------------------------------------------
     */

    function automatic logic [35:0] fma_core(
        input logic [31:0] fa,
        input logic [31:0] fb,
        input logic [31:0] fc,
        input logic [2:0]  rnd
    );

        logic sign_a;
        logic sign_b;
        logic sign_c;
        logic sign_p;
        logic sign_r;

        logic [7:0] exp_a;
        logic [7:0] exp_b;
        logic [7:0] exp_c;

        logic [22:0] frac_a;
        logic [22:0] frac_b;
        logic [22:0] frac_c;

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

        logic invalid_op;

        logic [23:0] mant_a;
        logic [23:0] mant_b;
        logic [23:0] mant_c;

        logic [47:0] prod_mant;

        integer lsb_a;
        integer lsb_b;
        integer lsb_c;
        integer prod_lsb;

        integer prod_top;
        integer c_top;
        integer top_exp;
        integer base_exp;

        logic [79:0] prod_aligned;
        logic [79:0] c_aligned;

        logic signed [80:0] prod_term;
        logic signed [80:0] c_term;
        logic signed [80:0] exact_sum;

        logic [79:0] magnitude;
        logic [79:0] trunc_mag;
        logic [79:0] remainder;
        logic [79:0] half_ulp;
        logic [79:0] rem_mask;

        integer leading_bit;
        integer exact_top_exp;
        integer shift_amt;
        integer unbiased_exp;

        logic [24:0] rounded_sig;
        logic [24:0] sub_sig;

        logic rem_nonzero;
        logic round_increment;

        logic [7:0] out_exp;

        logic [31:0] out_value;

        logic fl_invalid;
        logic fl_overflow;
        logic fl_underflow;
        logic fl_inexact;

        begin

            /*
             * --------------------------------------------------------------
             * Defaults / classification.
             * --------------------------------------------------------------
             */
            sign_a = fa[31];
            sign_b = fb[31];
            sign_c = fc[31];

            sign_p = sign_a ^ sign_b;
            sign_r = 1'b0;

            exp_a = fa[30:23];
            exp_b = fb[30:23];
            exp_c = fc[30:23];

            frac_a = fa[22:0];
            frac_b = fb[22:0];
            frac_c = fc[22:0];

            a_nan =
                (exp_a == 8'hff) &&
                (frac_a != 23'b0);

            b_nan =
                (exp_b == 8'hff) &&
                (frac_b != 23'b0);

            c_nan =
                (exp_c == 8'hff) &&
                (frac_c != 23'b0);

            a_snan =
                a_nan &&
                !frac_a[22];

            b_snan =
                b_nan &&
                !frac_b[22];

            c_snan =
                c_nan &&
                !frac_c[22];

            a_inf =
                (exp_a == 8'hff) &&
                (frac_a == 23'b0);

            b_inf =
                (exp_b == 8'hff) &&
                (frac_b == 23'b0);

            c_inf =
                (exp_c == 8'hff) &&
                (frac_c == 23'b0);

            a_zero =
                (exp_a == 8'b0) &&
                (frac_a == 23'b0);

            b_zero =
                (exp_b == 8'b0) &&
                (frac_b == 23'b0);

            c_zero =
                (exp_c == 8'b0) &&
                (frac_c == 23'b0);

            out_value   = 32'b0;
            fl_invalid  = 1'b0;
            fl_overflow = 1'b0;
            fl_underflow = 1'b0;
            fl_inexact  = 1'b0;

            mant_a = 24'b0;
            mant_b = 24'b0;
            mant_c = 24'b0;

            prod_mant = 48'b0;

            lsb_a   = 0;
            lsb_b   = 0;
            lsb_c   = 0;
            prod_lsb = 0;

            prod_top = -10000;
            c_top    = -10000;
            top_exp  = -10000;
            base_exp = 0;

            prod_aligned = 80'b0;
            c_aligned    = 80'b0;

            prod_term = 81'sd0;
            c_term    = 81'sd0;
            exact_sum = 81'sd0;

            magnitude = 80'b0;
            trunc_mag = 80'b0;
            remainder = 80'b0;
            half_ulp  = 80'b0;
            rem_mask  = 80'b0;

            leading_bit  = 0;
            exact_top_exp = 0;
            shift_amt    = 0;
            unbiased_exp = 0;

            rounded_sig = 25'b0;
            sub_sig     = 25'b0;

            rem_nonzero   = 1'b0;
            round_increment = 1'b0;

            out_exp = 8'b0;


            /*
             * --------------------------------------------------------------
             * Invalid-operation conditions.
             * --------------------------------------------------------------
             */
            invalid_op =
                a_snan ||
                b_snan ||
                c_snan ||
                (a_inf && b_zero) ||
                (b_inf && a_zero);

            /*
             * Infinite product plus opposite-signed infinity.
             */
            if (
                (a_inf || b_inf) &&
                !a_nan &&
                !b_nan &&
                !a_zero &&
                !b_zero &&
                c_inf &&
                (sign_p != sign_c)
            )
                invalid_op = 1'b1;


            /*
             * --------------------------------------------------------------
             * NaN / invalid.
             *
             * Every NaN result is exactly 7fc00000.
             * --------------------------------------------------------------
             */
            if (
                a_nan ||
                b_nan ||
                c_nan ||
                invalid_op
            ) begin

                out_value  = CANON_QNAN;
                fl_invalid = invalid_op;

            end


            /*
             * --------------------------------------------------------------
             * Infinite product.
             * --------------------------------------------------------------
             */
            else if (a_inf || b_inf) begin

                out_value = {
                    sign_p,
                    8'hff,
                    23'b0
                };

            end


            /*
             * --------------------------------------------------------------
             * Finite product + infinite c.
             * --------------------------------------------------------------
             */
            else if (c_inf) begin

                out_value = {
                    sign_c,
                    8'hff,
                    23'b0
                };

            end


            /*
             * --------------------------------------------------------------
             * Finite arithmetic.
             *
             * A finite binary32 number is represented exactly as
             *
             *   mantissa_integer * 2^lsb_exp
             *
             * normal:
             *   mantissa = {1,frac}
             *   lsb_exp  = exponent_field - 150
             *
             * subnormal:
             *   mantissa = frac
             *   lsb_exp  = -149
             * --------------------------------------------------------------
             */
            else begin

                if (exp_a == 8'b0) begin
                    mant_a = {1'b0, frac_a};
                    lsb_a  = -149;
                end
                else begin
                    mant_a = {1'b1, frac_a};
                    lsb_a  = exp_a;
                    lsb_a  = lsb_a - 150;
                end

                if (exp_b == 8'b0) begin
                    mant_b = {1'b0, frac_b};
                    lsb_b  = -149;
                end
                else begin
                    mant_b = {1'b1, frac_b};
                    lsb_b  = exp_b;
                    lsb_b  = lsb_b - 150;
                end

                if (exp_c == 8'b0) begin
                    mant_c = {1'b0, frac_c};
                    lsb_c  = -149;
                end
                else begin
                    mant_c = {1'b1, frac_c};
                    lsb_c  = exp_c;
                    lsb_c  = lsb_c - 150;
                end

                /*
                 * Force a 48-bit multiplication result.
                 */
                prod_mant =
                    {24'b0, mant_a} *
                    {24'b0, mant_b};

                prod_lsb =
                    lsb_a +
                    lsb_b;


                /*
                 * ----------------------------------------------------------
                 * Both exact terms are zero.
                 * ----------------------------------------------------------
                 */
                if (
                    (prod_mant == 48'b0) &&
                    (mant_c == 24'b0)
                ) begin

                    /*
                     * Same-sign zeros preserve their sign.
                     *
                     * Opposite-sign zero addition is -0 only under RDN.
                     */
                    if (sign_p == sign_c)
                        sign_r = sign_p;
                    else if (rnd == 3'd2)
                        sign_r = 1'b1;
                    else
                        sign_r = 1'b0;

                    out_value = {
                        sign_r,
                        31'b0
                    };

                end
                else begin

                    /*
                     * ------------------------------------------------------
                     * Choose a common 80-bit accumulator scale.
                     * ------------------------------------------------------
                     */
                    if (prod_mant != 48'b0)
                        prod_top =
                            prod_lsb +
                            msb48(prod_mant);

                    if (mant_c != 24'b0)
                        c_top =
                            lsb_c +
                            msb24(mant_c);

                    if (prod_top > c_top)
                        top_exp = prod_top;
                    else
                        top_exp = c_top;

                    base_exp =
                        top_exp -
                        ALIGN_TOP;

                    prod_aligned =
                        align80(
                            prod_mant,
                            prod_lsb,
                            base_exp
                        );

                    c_aligned =
                        align80(
                            {24'b0, mant_c},
                            lsb_c,
                            base_exp
                        );

                    prod_term =
                        $signed({
                            1'b0,
                            prod_aligned
                        });

                    c_term =
                        $signed({
                            1'b0,
                            c_aligned
                        });

                    if (sign_p)
                        prod_term =
                            -prod_term;

                    if (sign_c)
                        c_term =
                            -c_term;

                    exact_sum =
                        prod_term +
                        c_term;


                    /*
                     * ------------------------------------------------------
                     * Exact cancellation.
                     * ------------------------------------------------------
                     */
                    if (exact_sum == 81'sd0) begin

                        /*
                         * Exact cancellation of nonzero opposite-sign
                         * quantities produces -0 under RDN and +0 otherwise.
                         */
                        if (rnd == 3'd2)
                            sign_r = 1'b1;
                        else
                            sign_r = 1'b0;

                        out_value = {
                            sign_r,
                            31'b0
                        };

                    end
                    else begin

                        sign_r =
                            exact_sum[80];

                        if (sign_r)
                            magnitude =
                                (~exact_sum[79:0]) +
                                80'd1;
                        else
                            magnitude =
                                exact_sum[79:0];

                        leading_bit =
                            msb80(magnitude);

                        exact_top_exp =
                            base_exp +
                            leading_bit;


                        /*
                         * ==================================================
                         * NORMAL RANGE
                         * ==================================================
                         */
                        if (exact_top_exp >= -126) begin

                            /*
                             * If the exact leading exponent already exceeds
                             * binary32's emax, overflow is unconditional.
                             */
                            if (exact_top_exp > 127) begin

                                out_value =
                                    overflow_value(
                                        sign_r,
                                        rnd
                                    );

                                fl_overflow = 1'b1;
                                fl_inexact  = 1'b1;

                            end
                            else begin

                                unbiased_exp =
                                    exact_top_exp;

                                /*
                                 * Retain hidden bit + 23 fraction bits.
                                 */
                                shift_amt =
                                    leading_bit -
                                    23;

                                trunc_mag   = 80'b0;
                                remainder   = 80'b0;
                                half_ulp    = 80'b0;
                                rem_mask    = 80'b0;
                                rem_nonzero = 1'b0;

                                if (shift_amt <= 0) begin

                                    trunc_mag =
                                        magnitude <<
                                        (-shift_amt);

                                    remainder   = 80'b0;
                                    rem_nonzero = 1'b0;

                                end
                                else if (shift_amt < 80) begin

                                    trunc_mag =
                                        magnitude >>
                                        shift_amt;

                                    rem_mask =
                                        (80'd1 << shift_amt) -
                                        80'd1;

                                    remainder =
                                        magnitude &
                                        rem_mask;

                                    half_ulp =
                                        80'd1 <<
                                        (shift_amt - 1);

                                    rem_nonzero =
                                        (remainder != 80'b0);

                                end
                                else begin

                                    trunc_mag =
                                        80'b0;

                                    remainder =
                                        magnitude;

                                    rem_nonzero =
                                        (magnitude != 80'b0);

                                end

                                rounded_sig =
                                    trunc_mag[24:0];

                                round_increment = 1'b0;

                                if (rem_nonzero) begin

                                    case (rnd)

                                        /*
                                         * RNE
                                         */
                                        3'd0: begin

                                            if (shift_amt > 80)
                                                round_increment = 1'b0;
                                            else if (shift_amt == 80)
                                                round_increment =
                                                    (magnitude > (80'd1 << 79)) ||
                                                    (
                                                        (magnitude == (80'd1 << 79)) &&
                                                        rounded_sig[0]
                                                    );
                                            else
                                                round_increment =
                                                    (remainder > half_ulp) ||
                                                    (
                                                        (remainder == half_ulp) &&
                                                        rounded_sig[0]
                                                    );

                                        end


                                        /*
                                         * RTZ
                                         */
                                        3'd1:
                                            round_increment = 1'b0;


                                        /*
                                         * RDN
                                         */
                                        3'd2:
                                            round_increment = sign_r;


                                        /*
                                         * RUP
                                         */
                                        3'd3:
                                            round_increment = !sign_r;


                                        /*
                                         * RMM
                                         */
                                        3'd4: begin

                                            if (shift_amt > 80)
                                                round_increment = 1'b0;
                                            else if (shift_amt == 80)
                                                round_increment =
                                                    magnitude >=
                                                    (80'd1 << 79);
                                            else
                                                round_increment =
                                                    remainder >=
                                                    half_ulp;

                                        end

                                        default:
                                            round_increment = 1'b0;

                                    endcase

                                end

                                if (round_increment)
                                    rounded_sig =
                                        rounded_sig +
                                        25'd1;

                                /*
                                 * Carry from 1.111... to 10.000...
                                 */
                                if (rounded_sig[24]) begin

                                    rounded_sig =
                                        rounded_sig >>
                                        1;

                                    unbiased_exp =
                                        unbiased_exp +
                                        1;

                                end


                                /*
                                 * Rounding itself may cross into overflow.
                                 */
                                if (unbiased_exp > 127) begin

                                    out_value =
                                        overflow_value(
                                            sign_r,
                                            rnd
                                        );

                                    fl_overflow = 1'b1;
                                    fl_inexact  = 1'b1;

                                end
                                else begin

                                    out_exp =
                                        unbiased_exp +
                                        127;

                                    out_value = {
                                        sign_r,
                                        out_exp,
                                        rounded_sig[22:0]
                                    };

                                    fl_inexact =
                                        rem_nonzero;

                                end

                            end

                        end


                        /*
                         * ==================================================
                         * SUBNORMAL / ZERO RANGE
                         * ==================================================
                         *
                         * Binary32 subnormal quantum is exactly 2^-149.
                         * ==================================================
                         */
                        else begin

                            shift_amt =
                                -149 -
                                base_exp;

                            trunc_mag   = 80'b0;
                            remainder   = 80'b0;
                            half_ulp    = 80'b0;
                            rem_mask    = 80'b0;
                            rem_nonzero = 1'b0;

                            if (shift_amt <= 0) begin

                                trunc_mag =
                                    magnitude <<
                                    (-shift_amt);

                                remainder   = 80'b0;
                                rem_nonzero = 1'b0;

                            end
                            else if (shift_amt < 80) begin

                                trunc_mag =
                                    magnitude >>
                                    shift_amt;

                                rem_mask =
                                    (80'd1 << shift_amt) -
                                    80'd1;

                                remainder =
                                    magnitude &
                                    rem_mask;

                                half_ulp =
                                    80'd1 <<
                                    (shift_amt - 1);

                                rem_nonzero =
                                    (remainder != 80'b0);

                            end
                            else begin

                                trunc_mag =
                                    80'b0;

                                remainder =
                                    magnitude;

                                rem_nonzero =
                                    (magnitude != 80'b0);

                            end


                            sub_sig =
                                trunc_mag[24:0];

                            round_increment =
                                1'b0;

                            if (rem_nonzero) begin

                                case (rnd)

                                    /*
                                     * RNE
                                     */
                                    3'd0: begin

                                        if (shift_amt > 80)
                                            round_increment = 1'b0;
                                        else if (shift_amt == 80)
                                            round_increment =
                                                (magnitude > (80'd1 << 79)) ||
                                                (
                                                    (magnitude == (80'd1 << 79)) &&
                                                    sub_sig[0]
                                                );
                                        else
                                            round_increment =
                                                (remainder > half_ulp) ||
                                                (
                                                    (remainder == half_ulp) &&
                                                    sub_sig[0]
                                                );

                                    end


                                    /*
                                     * RTZ
                                     */
                                    3'd1:
                                        round_increment = 1'b0;


                                    /*
                                     * RDN
                                     */
                                    3'd2:
                                        round_increment =
                                            sign_r;


                                    /*
                                     * RUP
                                     */
                                    3'd3:
                                        round_increment =
                                            !sign_r;


                                    /*
                                     * RMM
                                     */
                                    3'd4: begin

                                        if (shift_amt > 80)
                                            round_increment = 1'b0;
                                        else if (shift_amt == 80)
                                            round_increment =
                                                magnitude >=
                                                (80'd1 << 79);
                                        else
                                            round_increment =
                                                remainder >=
                                                half_ulp;

                                    end

                                    default:
                                        round_increment = 1'b0;

                                endcase

                            end


                            if (round_increment)
                                sub_sig =
                                    sub_sig +
                                    25'd1;


                            /*
                             * Rounding a subnormal may produce exactly the
                             * smallest normal number.
                             *
                             * The task explicitly says this case has NX=1
                             * but UF=0 because the DELIVERED exponent field
                             * is nonzero.
                             */
                            if (sub_sig >= 25'h0800000) begin

                                out_value = {
                                    sign_r,
                                    8'h01,
                                    23'b0
                                };

                                fl_inexact   = rem_nonzero;
                                fl_underflow = 1'b0;

                            end
                            else begin

                                out_value = {
                                    sign_r,
                                    8'h00,
                                    sub_sig[22:0]
                                };

                                fl_inexact =
                                    rem_nonzero;

                                /*
                                 * Contract A6:
                                 *
                                 * UF iff:
                                 *   NX == 1
                                 *   AND delivered exponent field == 0
                                 */
                                fl_underflow =
                                    rem_nonzero;

                            end

                        end

                    end

                end

            end


            fma_core = {
                fl_invalid,
                fl_overflow,
                fl_underflow,
                fl_inexact,
                out_value
            };

        end
    endfunction


    /*
     * ========================================================================
     * Four elastic storage positions implement a three-clock delay:
     *
     * accepted at edge N  -> slot 0
     * edge N+1            -> slot 1
     * edge N+2            -> slot 2
     * edge N+3            -> slot 3 / output
     *
     * With out_ready continuously high this accepts one operation every cycle.
     *
     * Backpressure turns the same structure into an elastic pipeline, preserving
     * output validity/data until accepted.
     * ========================================================================
     */

    logic        v0_q;
    logic        v1_q;
    logic        v2_q;
    logic        v3_q;

    logic [35:0] d0_q;
    logic [35:0] d1_q;
    logic [35:0] d2_q;
    logic [35:0] d3_q;

    logic ready0;
    logic ready1;
    logic ready2;
    logic ready3;

    logic in_fire;


    /*
     * Ready propagation contains no combinational dependence on in_valid.
     */
    always_comb begin

        ready3 =
            !v3_q ||
            out_ready;

        ready2 =
            !v2_q ||
            ready3;

        ready1 =
            !v1_q ||
            ready2;

        ready0 =
            !v0_q ||
            ready1;

        in_ready =
            rst_n &&
            ready0;

        in_fire =
            in_valid &&
            in_ready;


        /*
         * out_valid does NOT depend on out_ready.
         */
        out_valid =
            rst_n &&
            v3_q;

        result =
            d3_q[31:0];

        flag_invalid =
            d3_q[35];

        flag_overflow =
            d3_q[34];

        flag_underflow =
            d3_q[33];

        flag_inexact =
            d3_q[32];

    end


    /*
     * Synchronous active-low reset, as required.
     */
    always_ff @(posedge clk) begin

        if (!rst_n) begin

            v0_q <= 1'b0;
            v1_q <= 1'b0;
            v2_q <= 1'b0;
            v3_q <= 1'b0;

            d0_q <= 36'b0;
            d1_q <= 36'b0;
            d2_q <= 36'b0;
            d3_q <= 36'b0;

        end
        else begin

            /*
             * Output position.
             *
             * If out_valid && !out_ready, ready3 is false and both v3_q
             * and d3_q hold exactly, satisfying H3.
             */
            if (ready3) begin

                v3_q <= v2_q;

                if (v2_q)
                    d3_q <= d2_q;

            end


            /*
             * Pipeline position 2.
             */
            if (ready2) begin

                v2_q <= v1_q;

                if (v1_q)
                    d2_q <= d1_q;

            end


            /*
             * Pipeline position 1.
             */
            if (ready1) begin

                v1_q <= v0_q;

                if (v0_q)
                    d1_q <= d0_q;

            end


            /*
             * Input position.
             */
            if (ready0) begin

                v0_q <= in_fire;

                if (in_fire)
                    d0_q <=
                        fma_core(
                            a,
                            b,
                            c,
                            rnd_mode
                        );

            end

        end

    end

endmodule