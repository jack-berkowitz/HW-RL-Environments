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

    // A finite binary32 value is represented internally as
    //     significand * 2^exponent,
    // where a normal significand is 24 bits (including the hidden one).
    // The smallest product quantum is 2^-298, so using that as a fixed
    // binary point lets the product and addend be combined with no loss.
    localparam int W = 556;

    function automatic logic [35:0] fma_exact (
        input logic [31:0] aa,
        input logic [31:0] bb,
        input logic [31:0] cc,
        input logic [2:0]  rm
    );
        logic        sa, sb, sc, sp, sr;
        logic [7:0]  xa, xb, xc;
        logic [22:0] fa, fb, fc;

        logic nan_a, nan_b, nan_c;
        logic snan_a, snan_b, snan_c;
        logic inf_a, inf_b, inf_c;
        logic zero_a, zero_b, zero_c;

        logic [23:0] sig_a, sig_b, sig_c;
        logic [47:0] sig_p;
        integer ea_i, eb_i, ec_i;
        integer p_shift_i, c_shift_i;

        logic [W-1:0] p_mag;
        logic [W-1:0] c_mag;
        logic [W-1:0] sum_mag;

        integer i;
        integer h_i;
        integer shift_i;
        integer biased_i;
        logic found;
        logic rem_nonzero;
        logic guard_bit;
        logic sticky_bit;
        logic round_inc;
        logic [24:0] trunc_sig;
        logic [24:0] rounded_sig;

        logic [31:0] res;
        logic inv, ofl, ufl, inx;
        logic inf_out;

        begin
            sa = aa[31];
            sb = bb[31];
            sc = cc[31];
            sp = sa ^ sb;

            xa = aa[30:23];
            xb = bb[30:23];
            xc = cc[30:23];
            fa = aa[22:0];
            fb = bb[22:0];
            fc = cc[22:0];

            nan_a  = (xa == 8'hff) && (fa != 23'd0);
            nan_b  = (xb == 8'hff) && (fb != 23'd0);
            nan_c  = (xc == 8'hff) && (fc != 23'd0);

            snan_a = nan_a && !fa[22];
            snan_b = nan_b && !fb[22];
            snan_c = nan_c && !fc[22];

            inf_a  = (xa == 8'hff) && (fa == 23'd0);
            inf_b  = (xb == 8'hff) && (fb == 23'd0);
            inf_c  = (xc == 8'hff) && (fc == 23'd0);

            zero_a = (xa == 8'd0) && (fa == 23'd0);
            zero_b = (xb == 8'd0) && (fb == 23'd0);
            zero_c = (xc == 8'd0) && (fc == 23'd0);

            res = 32'd0;
            inv = 1'b0;
            ofl = 1'b0;
            ufl = 1'b0;
            inx = 1'b0;

            // 0 * Inf is invalid, even if C is a quiet NaN.
            if ((inf_a && zero_b) || (zero_a && inf_b)) begin
                res = 32'h7fc00000;
                inv = 1'b1;

            end else if (nan_a || nan_b || nan_c) begin
                // All NaN results are the canonical positive quiet NaN.
                res = 32'h7fc00000;
                inv = snan_a || snan_b || snan_c;

            end else if (inf_a || inf_b || inf_c) begin
                // Product infinity plus opposite-signed addend infinity.
                if ((inf_a || inf_b) && inf_c && (sp != sc)) begin
                    res = 32'h7fc00000;
                    inv = 1'b1;
                end else if (inf_a || inf_b) begin
                    res = {sp, 8'hff, 23'd0};
                end else begin
                    res = {sc, 8'hff, 23'd0};
                end

            end else begin
                // -------------------------------------------------------------
                // All operands finite.
                // -------------------------------------------------------------

                sig_a = (xa == 8'd0) ? {1'b0, fa} : {1'b1, fa};
                sig_b = (xb == 8'd0) ? {1'b0, fb} : {1'b1, fb};
                sig_c = (xc == 8'd0) ? {1'b0, fc} : {1'b1, fc};

                // Exact 24 x 24 product.  It is not rounded here.
                sig_p = sig_a * sig_b;

                // value = sig * 2^e
                //
                // normal:    e = encoded_exp - 127 - 23
                //                 = encoded_exp - 150
                // subnormal: e = -149
                if (xa == 8'd0) begin
                    ea_i = -149;
                end else begin
                    ea_i = xa;
                    ea_i = ea_i - 150;
                end

                if (xb == 8'd0) begin
                    eb_i = -149;
                end else begin
                    eb_i = xb;
                    eb_i = eb_i - 150;
                end

                if (xc == 8'd0) begin
                    ec_i = -149;
                end else begin
                    ec_i = xc;
                    ec_i = ec_i - 150;
                end

                // Use 2^-298 as the common fixed-point quantum.
                //
                // Product exponent range:
                //     -298 .. +208
                //
                // Addend exponent range:
                //     -149 .. +104
                p_shift_i = ea_i + eb_i + 298;
                c_shift_i = ec_i + 298;

                p_mag = {W{1'b0}};
                c_mag = {W{1'b0}};

                p_mag[47:0] = sig_p;
                c_mag[23:0] = sig_c;

                p_mag = p_mag << p_shift_i;
                c_mag = c_mag << c_shift_i;

                // Exact signed addition/subtraction in sign-magnitude form.
                if (sp == sc) begin
                    sum_mag = p_mag + c_mag;
                    sr = sp;

                end else if (p_mag > c_mag) begin
                    sum_mag = p_mag - c_mag;
                    sr = sp;

                end else if (c_mag > p_mag) begin
                    sum_mag = c_mag - p_mag;
                    sr = sc;

                end else begin
                    // Exact cancellation.
                    sum_mag = {W{1'b0}};

                    // Opposite-signed exact cancellation is +0 except for RDN.
                    if (sp == sc)
                        sr = sp;
                    else
                        sr = (rm == 3'd2);
                end

                // -------------------------------------------------------------
                // Exact zero.
                // -------------------------------------------------------------
                if (sum_mag == {W{1'b0}}) begin
                    if (sp == sc)
                        sr = sp;
                    else
                        sr = (rm == 3'd2);

                    res = {sr, 31'd0};

                end else begin
                    // ---------------------------------------------------------
                    // Find exact leading one.
                    //
                    // Fixed-point bit h has value 2^(h-298).
                    // ---------------------------------------------------------
                    h_i = 0;
                    found = 1'b0;

                    for (i = W-1; i >= 0; i = i-1) begin
                        if (!found && sum_mag[i]) begin
                            h_i = i;
                            found = 1'b1;
                        end
                    end

                    // h=425 => unbiased exponent +127.
                    // Anything above this overflows before rounding.
                    if (h_i > 425) begin
                        ofl = 1'b1;
                        inx = 1'b1;

                        case (rm)
                            3'd0: inf_out = 1'b1; // RNE
                            3'd1: inf_out = 1'b0; // RTZ

                            // RDN: negative overflow -> -Inf,
                            //      positive overflow -> +maxfinite
                            3'd2: inf_out = sr;

                            // RUP: positive overflow -> +Inf,
                            //      negative overflow -> -maxfinite
                            3'd3: inf_out = !sr;

                            3'd4: inf_out = 1'b1; // RMM
                            default: inf_out = 1'b0;
                        endcase

                        if (inf_out)
                            res = {sr, 8'hff, 23'd0};
                        else
                            res = {sr, 8'hfe, 23'h7fffff};

                    end else begin
                        // -----------------------------------------------------
                        // Select destination precision.
                        //
                        // For a normal result, retain 24 significant bits.
                        //
                        // For a subnormal result, rounding occurs directly at
                        // the binary32 subnormal quantum 2^-149, which is
                        // fixed-point bit 149.
                        // -----------------------------------------------------
                        if (h_i >= 172)
                            shift_i = h_i - 23;
                        else
                            shift_i = 149;

                        trunc_sig = sum_mag >> shift_i;

                        // Determine whether discarded information exists and
                        // derive guard/sticky for nearest rounding modes.
                        rem_nonzero = 1'b0;
                        sticky_bit  = 1'b0;

                        for (i = 0; i < W; i = i+1) begin
                            if (i < shift_i)
                                rem_nonzero =
                                    rem_nonzero | sum_mag[i];

                            if (i < (shift_i - 1))
                                sticky_bit =
                                    sticky_bit | sum_mag[i];
                        end

                        guard_bit = sum_mag[shift_i-1];
                        inx = rem_nonzero;

                        // -----------------------------------------------------
                        // Runtime rounding mode.
                        // -----------------------------------------------------
                        case (rm)
                            // Round to nearest, ties to even.
                            3'd0:
                                round_inc =
                                    guard_bit &&
                                    (sticky_bit || trunc_sig[0]);

                            // Round toward zero.
                            3'd1:
                                round_inc = 1'b0;

                            // Round toward -infinity.
                            3'd2:
                                round_inc = rem_nonzero && sr;

                            // Round toward +infinity.
                            3'd3:
                                round_inc = rem_nonzero && !sr;

                            // Round to nearest, ties away from zero.
                            3'd4:
                                round_inc = guard_bit;

                            default:
                                round_inc = 1'b0;
                        endcase

                        rounded_sig =
                            trunc_sig +
                            {{24{1'b0}}, round_inc};

                        // -----------------------------------------------------
                        // Subnormal / tiny result.
                        // -----------------------------------------------------
                        if (h_i < 172) begin
                            // Rounding the largest subnormal can produce the
                            // smallest normal.
                            if (rounded_sig[23])
                                res = {sr, 8'h01, 23'd0};
                            else
                                res = {
                                    sr,
                                    8'h00,
                                    rounded_sig[22:0]
                                };

                            // Contract A6:
                            //
                            // UF iff:
                            //   1. result is inexact, and
                            //   2. DELIVERED exponent field is zero.
                            ufl =
                                inx &&
                                (res[30:23] == 8'd0);

                        end else begin
                            // -------------------------------------------------
                            // Normal result.
                            //
                            // h=172 => unbiased exponent -126
                            //       => biased exponent 1
                            //
                            // therefore biased exponent = h - 171.
                            // -------------------------------------------------
                            biased_i = h_i - 171;

                            // Rounding carry renormalizes the significand.
                            if (rounded_sig[24])
                                biased_i = biased_i + 1;

                            // Rounding can turn max-finite-range input into
                            // infinity.
                            if (biased_i >= 255) begin
                                ofl = 1'b1;

                                // Overflow always raises inexact.
                                inx = 1'b1;

                                case (rm)
                                    3'd0: inf_out = 1'b1;
                                    3'd1: inf_out = 1'b0;
                                    3'd2: inf_out = sr;
                                    3'd3: inf_out = !sr;
                                    3'd4: inf_out = 1'b1;
                                    default: inf_out = 1'b0;
                                endcase

                                if (inf_out)
                                    res =
                                        {sr, 8'hff, 23'd0};
                                else
                                    res =
                                        {sr, 8'hfe, 23'h7fffff};

                            end else begin
                                res = {
                                    sr,
                                    biased_i[7:0],
                                    rounded_sig[22:0]
                                };
                            end
                        end
                    end
                end
            end

            // [35] invalid
            // [34] overflow
            // [33] underflow
            // [32] inexact
            // [31:0] result
            fma_exact = {inv, ofl, ufl, inx, res};
        end
    endfunction


    // =========================================================================
    // Three-cycle elastic pipeline
    // =========================================================================

    logic [35:0] computed;

    logic [35:0] pipe0;
    logic [35:0] pipe1;
    logic [35:0] pipe2;

    logic v0;
    logic v1;
    logic v2;

    logic r0;
    logic r1;
    logic r2;


    always_comb begin
        computed = fma_exact(a, b, c, rnd_mode);

        // Ready propagates backward through the elastic pipeline.
        //
        // It does not depend combinationally on in_valid.
        r2 = (~v2) | out_ready;
        r1 = (~v1) | r2;
        r0 = (~v0) | r1;

        in_ready = r0;

        out_valid      = v2;

        result         = pipe2[31:0];
        flag_inexact   = pipe2[32];
        flag_underflow = pipe2[33];
        flag_overflow  = pipe2[34];
        flag_invalid   = pipe2[35];
    end


    always_ff @(posedge clk) begin
        if (!rst_n) begin
            // Synchronous active-low reset.
            v0 <= 1'b0;
            v1 <= 1'b0;
            v2 <= 1'b0;

            pipe0 <= 36'd0;
            pipe1 <= 36'd0;
            pipe2 <= 36'd0;

        end else begin
            // Output stage.
            //
            // When v2=1 and out_ready=0, r2=0, so both valid and
            // payload remain stable.
            if (r2) begin
                v2 <= v1;

                if (v1)
                    pipe2 <= pipe1;
            end

            // Middle stage.
            if (r1) begin
                v1 <= v0;

                if (v0)
                    pipe1 <= pipe0;
            end

            // Input stage.
            if (r0) begin
                v0 <= in_valid;

                if (in_valid)
                    pipe0 <= computed;
            end
        end
    end

endmodule