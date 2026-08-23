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

    // -------------------------------------------------------------------------
    // Combinational fused arithmetic.
    //
    // Return packing:
    //   [31:0] result
    //   [32]   invalid
    //   [33]   overflow
    //   [34]   underflow
    //   [35]   inexact
    //
    // Finite operands are represented as
    //
    //     significand_integer * 2^unit_exponent
    //
    // where a normal FP32 operand has a 24-bit significand and a subnormal
    // carries its fraction directly.
    //
    // The exact 48-bit product and the addend are aligned into a 96-bit
    // sign-magnitude window.  Bits falling below that window are represented
    // by a sticky indication.  The 96-bit window is deliberately much wider
    // than the 24-bit destination precision, while remaining within the
    // specification's 96-bit significand-datapath limit.
    // -------------------------------------------------------------------------

    function automatic logic [35:0] fma_compute (
        input logic [31:0] aa,
        input logic [31:0] bb,
        input logic [31:0] cc,
        input logic [2:0]  rm
    );

        logic        sign_a;
        logic        sign_b;
        logic        sign_c;
        logic        prod_sign;
        logic        sum_sign;
        logic        zero_sign;

        logic [7:0]  exp_a;
        logic [7:0]  exp_b;
        logic [7:0]  exp_c;

        logic [22:0] frac_a;
        logic [22:0] frac_b;
        logic [22:0] frac_c;

        logic        nan_a;
        logic        nan_b;
        logic        nan_c;

        logic        snan_a;
        logic        snan_b;
        logic        snan_c;

        logic        inf_a;
        logic        inf_b;
        logic        inf_c;

        logic        zero_a;
        logic        zero_b;
        logic        zero_c;

        logic        mul_invalid;
        logic        prod_inf;
        logic        prod_zero;
        logic        inf_sub_invalid;

        logic [23:0] sig_a;
        logic [23:0] sig_b;
        logic [23:0] sig_c;

        logic [47:0] prod_sig;

        integer      ea_u;
        integer      eb_u;
        integer      ec_u;
        integer      ep_u;

        integer      lead_p;
        integer      lead_c;
        integer      lead_sum;

        integer      top_p;
        integer      top_c;
        integer      top_max;
        integer      top_res;

        integer      base_exp;
        integer      shift_p;
        integer      shift_c;
        integer      rshift;
        integer      cut;

        logic [95:0] wide_tmp;
        logic [95:0] mag_p;
        logic [95:0] mag_c;
        logic [95:0] sum_mag;

        logic        lost_p;
        logic        lost_c;
        logic        tail_nonzero;

        logic        found;

        logic [24:0] q_val;
        logic [24:0] q_round;
        logic [23:0] q24;

        logic        guard_bit;
        logic        sticky_bit;
        logic        rem_nonzero;
        logic        round_inc;
        logic        to_inf;

        logic [7:0]  out_exp;

        logic [31:0] res;

        logic        inv;
        logic        ov;
        logic        uf;
        logic        nx;

        integer      i;

        begin

            // -----------------------------------------------------------------
            // Defaults
            // -----------------------------------------------------------------

            res = 32'h00000000;

            inv = 1'b0;
            ov  = 1'b0;
            uf  = 1'b0;
            nx  = 1'b0;

            sign_a = aa[31];
            sign_b = bb[31];
            sign_c = cc[31];

            exp_a  = aa[30:23];
            exp_b  = bb[30:23];
            exp_c  = cc[30:23];

            frac_a = aa[22:0];
            frac_b = bb[22:0];
            frac_c = cc[22:0];

            prod_sign = sign_a ^ sign_b;

            // -----------------------------------------------------------------
            // Classification
            // -----------------------------------------------------------------

            nan_a =
                (exp_a == 8'hff) &&
                (frac_a != 23'h000000);

            nan_b =
                (exp_b == 8'hff) &&
                (frac_b != 23'h000000);

            nan_c =
                (exp_c == 8'hff) &&
                (frac_c != 23'h000000);

            snan_a = nan_a && !frac_a[22];
            snan_b = nan_b && !frac_b[22];
            snan_c = nan_c && !frac_c[22];

            inf_a =
                (exp_a == 8'hff) &&
                (frac_a == 23'h000000);

            inf_b =
                (exp_b == 8'hff) &&
                (frac_b == 23'h000000);

            inf_c =
                (exp_c == 8'hff) &&
                (frac_c == 23'h000000);

            zero_a =
                (exp_a == 8'h00) &&
                (frac_a == 23'h000000);

            zero_b =
                (exp_b == 8'h00) &&
                (frac_b == 23'h000000);

            zero_c =
                (exp_c == 8'h00) &&
                (frac_c == 23'h000000);

            prod_zero = zero_a || zero_b;

            // 0 * infinity is invalid.
            mul_invalid =
                (inf_a  && zero_b) ||
                (zero_a && inf_b);

            // A valid infinite product.
            prod_inf =
                (inf_a || inf_b) &&
                !mul_invalid &&
                !nan_a &&
                !nan_b;

            // Infinite product plus an infinity of the opposite sign.
            inf_sub_invalid =
                prod_inf &&
                inf_c &&
                (prod_sign != sign_c);

            inv =
                snan_a ||
                snan_b ||
                snan_c ||
                mul_invalid ||
                inf_sub_invalid;

            // -----------------------------------------------------------------
            // NaNs / invalid operations.
            //
            // All NaN results are exactly 7fc00000.
            // -----------------------------------------------------------------

            if (nan_a || nan_b || nan_c || inv) begin

                res = 32'h7fc00000;

                ov = 1'b0;
                uf = 1'b0;
                nx = 1'b0;

            end

            // -----------------------------------------------------------------
            // Infinite product.
            // -----------------------------------------------------------------

            else if (prod_inf) begin

                res = {
                    prod_sign,
                    8'hff,
                    23'h000000
                };

            end

            // -----------------------------------------------------------------
            // Infinite addend.
            // -----------------------------------------------------------------

            else if (inf_c) begin

                res = {
                    sign_c,
                    8'hff,
                    23'h000000
                };

            end

            // -----------------------------------------------------------------
            // Both terms are exact zeros.
            //
            // Equal signs preserve that sign.
            // Opposite signed zeros produce -0 only under RDN.
            // -----------------------------------------------------------------

            else if (prod_zero && zero_c) begin

                if (prod_sign == sign_c)
                    zero_sign = prod_sign;
                else
                    zero_sign = (rm == 3'd2);

                res = {
                    zero_sign,
                    31'h00000000
                };

            end

            // -----------------------------------------------------------------
            // Zero product + finite nonzero c is exactly c.
            // -----------------------------------------------------------------

            else if (prod_zero) begin

                res = cc;

            end

            // -----------------------------------------------------------------
            // General finite fused path.
            // -----------------------------------------------------------------

            else begin

                // -------------------------------------------------------------
                // Decode finite significands.
                //
                // normal:
                //     (1.frac) * 2^(exp-127)
                //
                // represented here as:
                //     {1,frac} * 2^(exp-150)
                //
                // subnormal:
                //     frac * 2^-149
                // -------------------------------------------------------------

                if (exp_a == 8'h00) begin
                    sig_a = {1'b0, frac_a};
                    ea_u  = -149;
                end
                else begin
                    sig_a = {1'b1, frac_a};
                    ea_u  = exp_a;
                    ea_u  = ea_u - 150;
                end

                if (exp_b == 8'h00) begin
                    sig_b = {1'b0, frac_b};
                    eb_u  = -149;
                end
                else begin
                    sig_b = {1'b1, frac_b};
                    eb_u  = exp_b;
                    eb_u  = eb_u - 150;
                end

                if (exp_c == 8'h00) begin
                    sig_c = {1'b0, frac_c};
                    ec_u  = -149;
                end
                else begin
                    sig_c = {1'b1, frac_c};
                    ec_u  = exp_c;
                    ec_u  = ec_u - 150;
                end

                // Exact 24 x 24 -> 48-bit product.
                prod_sig = sig_a * sig_b;
                ep_u     = ea_u + eb_u;

                // -------------------------------------------------------------
                // Find the highest set bit of the exact product.
                // -------------------------------------------------------------

                lead_p = 0;
                found  = 1'b0;

                for (i = 47; i >= 0; i = i - 1) begin
                    if (!found && prod_sig[i]) begin
                        lead_p = i;
                        found  = 1'b1;
                    end
                end

                top_p = ep_u + lead_p;

                // -------------------------------------------------------------
                // Find the highest set bit of c.
                //
                // A zero c is given a deliberately very small top exponent so
                // that the product determines the alignment window.
                // -------------------------------------------------------------

                if (sig_c != 24'h000000) begin

                    lead_c = 0;
                    found  = 1'b0;

                    for (i = 23; i >= 0; i = i - 1) begin
                        if (!found && sig_c[i]) begin
                            lead_c = i;
                            found  = 1'b1;
                        end
                    end

                    top_c = ec_u + lead_c;

                end
                else begin

                    lead_c = 0;
                    top_c  = -1000000;

                end

                // -------------------------------------------------------------
                // Put the larger term's leading bit at bit 94.
                //
                // Bit 95 is left free for a same-sign addition carry.
                // -------------------------------------------------------------

                if (top_p >= top_c)
                    top_max = top_p;
                else
                    top_max = top_c;

                base_exp = top_max - 94;

                // -------------------------------------------------------------
                // Align exact product into the 96-bit window.
                // -------------------------------------------------------------

                wide_tmp       = 96'h0;
                wide_tmp[47:0] = prod_sig;

                shift_p = ep_u - base_exp;

                mag_p  = 96'h0;
                lost_p = 1'b0;

                if (shift_p >= 0) begin

                    mag_p = wide_tmp << shift_p;

                end
                else begin

                    rshift = -shift_p;

                    if (rshift >= 96)
                        mag_p = 96'h0;
                    else
                        mag_p = wide_tmp >> rshift;

                    for (i = 0; i < 48; i = i + 1) begin
                        if ((i < rshift) && prod_sig[i])
                            lost_p = 1'b1;
                    end

                end

                // -------------------------------------------------------------
                // Align c into the same 96-bit window.
                // -------------------------------------------------------------

                wide_tmp       = 96'h0;
                wide_tmp[23:0] = sig_c;

                shift_c = ec_u - base_exp;

                mag_c  = 96'h0;
                lost_c = 1'b0;

                if (sig_c == 24'h000000) begin

                    mag_c  = 96'h0;
                    lost_c = 1'b0;

                end
                else if (shift_c >= 0) begin

                    mag_c = wide_tmp << shift_c;

                end
                else begin

                    rshift = -shift_c;

                    if (rshift >= 96)
                        mag_c = 96'h0;
                    else
                        mag_c = wide_tmp >> rshift;

                    for (i = 0; i < 24; i = i + 1) begin
                        if ((i < rshift) && sig_c[i])
                            lost_c = 1'b1;
                    end

                end

                // -------------------------------------------------------------
                // Exact-sign addition/subtraction.
                //
                // At most the smaller widely-separated term can lose bits
                // below bit zero of the 96-bit window.
                //
                // For subtraction of a discarded positive tail:
                //
                //      D - epsilon
                //
                // is represented as
                //
                //      (D - 1) + (1 - epsilon)
                //
                // so decrementing the integer window and setting a tail/sticky
                // bit preserves every later rounding decision.
                // -------------------------------------------------------------

                sum_mag      = 96'h0;
                tail_nonzero = 1'b0;
                sum_sign     = prod_sign;

                if (prod_sign == sign_c) begin

                    sum_mag      = mag_p + mag_c;
                    sum_sign     = prod_sign;
                    tail_nonzero = lost_p || lost_c;

                end
                else begin

                    if (mag_p > mag_c) begin

                        sum_mag  = mag_p - mag_c;
                        sum_sign = prod_sign;

                        if (lost_p && !lost_c) begin

                            tail_nonzero = 1'b1;

                        end
                        else if (lost_c && !lost_p) begin

                            if (sum_mag != 96'h0)
                                sum_mag = sum_mag - 96'd1;

                            tail_nonzero = 1'b1;

                        end

                    end
                    else if (mag_c > mag_p) begin

                        sum_mag  = mag_c - mag_p;
                        sum_sign = sign_c;

                        if (lost_c && !lost_p) begin

                            tail_nonzero = 1'b1;

                        end
                        else if (lost_p && !lost_c) begin

                            if (sum_mag != 96'h0)
                                sum_mag = sum_mag - 96'd1;

                            tail_nonzero = 1'b1;

                        end

                    end
                    else begin

                        // With the chosen 96-bit alignment, equality when one
                        // operand has discarded tail bits cannot occur: a term
                        // that loses bits is necessarily far smaller than the
                        // term defining bit 94.
                        //
                        // Therefore equal aligned magnitudes are an exact
                        // cancellation.

                        sum_mag      = 96'h0;
                        tail_nonzero = 1'b0;
                        sum_sign     = (rm == 3'd2);

                    end

                end

                // -------------------------------------------------------------
                // Exact cancellation.
                //
                // IEEE exact cancellation gives +0 except round-down, which
                // gives -0.
                // -------------------------------------------------------------

                if ((sum_mag == 96'h0) && !tail_nonzero) begin

                    zero_sign = (rm == 3'd2);

                    res = {
                        zero_sign,
                        31'h00000000
                    };

                end
                else begin

                    // ---------------------------------------------------------
                    // Locate the result's leading one.
                    // ---------------------------------------------------------

                    lead_sum = 0;
                    found    = 1'b0;

                    for (i = 95; i >= 0; i = i - 1) begin
                        if (!found && sum_mag[i]) begin
                            lead_sum = i;
                            found    = 1'b1;
                        end
                    end

                    top_res = base_exp + lead_sum;

                    // ---------------------------------------------------------
                    // Normal result path.
                    // ---------------------------------------------------------

                    if (top_res >= -126) begin

                        // A finite exact value whose unbounded rounded exponent
                        // is already above +127 necessarily overflows.

                        if (top_res > 127) begin

                            ov = 1'b1;
                            nx = 1'b1;
                            uf = 1'b0;

                            case (rm)

                                3'd0:
                                    to_inf = 1'b1; // RNE

                                3'd1:
                                    to_inf = 1'b0; // RTZ

                                3'd2:
                                    to_inf = sum_sign; // RDN

                                3'd3:
                                    to_inf = !sum_sign; // RUP

                                3'd4:
                                    to_inf = 1'b1; // RMM

                                default:
                                    to_inf = 1'b1;

                            endcase

                            if (to_inf) begin
                                res = {
                                    sum_sign,
                                    8'hff,
                                    23'h000000
                                };
                            end
                            else begin
                                res = {
                                    sum_sign,
                                    8'hfe,
                                    23'h7fffff
                                };
                            end

                        end
                        else begin

                            // Keep 24 significant bits.
                            cut = lead_sum - 23;

                            q_val       = 25'h0;
                            guard_bit   = 1'b0;
                            sticky_bit  = tail_nonzero;
                            rem_nonzero = 1'b0;
                            round_inc   = 1'b0;

                            if (cut >= 96)
                                q_val = 25'h0;
                            else if (cut >= 0)
                                q_val = sum_mag >> cut;
                            else
                                q_val = sum_mag << (-cut);

                            if (cut > 0) begin

                                if ((cut - 1) < 96)
                                    guard_bit = sum_mag[cut-1];

                                for (i = 0; i < 96; i = i + 1) begin
                                    if ((i < (cut - 1)) && sum_mag[i])
                                        sticky_bit = 1'b1;
                                end

                            end

                            rem_nonzero =
                                guard_bit ||
                                sticky_bit;

                            // -------------------------------------------------
                            // Runtime rounding mode.
                            // -------------------------------------------------

                            case (rm)

                                // RNE: nearest, ties to even
                                3'd0:
                                    round_inc =
                                        guard_bit &&
                                        (sticky_bit || q_val[0]);

                                // RTZ
                                3'd1:
                                    round_inc = 1'b0;

                                // RDN
                                3'd2:
                                    round_inc =
                                        sum_sign &&
                                        rem_nonzero;

                                // RUP
                                3'd3:
                                    round_inc =
                                        !sum_sign &&
                                        rem_nonzero;

                                // RMM: nearest, ties away from zero
                                3'd4:
                                    round_inc = guard_bit;

                                default:
                                    round_inc =
                                        guard_bit &&
                                        (sticky_bit || q_val[0]);

                            endcase

                            if (round_inc)
                                q_round = q_val + 25'd1;
                            else
                                q_round = q_val;

                            // A rounding carry renormalizes the significand.
                            if (q_round[24]) begin

                                q24    = q_round[24:1];
                                top_res = top_res + 1;

                            end
                            else begin

                                q24 = q_round[23:0];

                            end

                            // ---------------------------------------------
                            // Overflow after rounding.
                            //
                            // Overflow also raises inexact.
                            // ---------------------------------------------

                            if (top_res > 127) begin

                                ov = 1'b1;
                                nx = 1'b1;
                                uf = 1'b0;

                                case (rm)

                                    3'd0:
                                        to_inf = 1'b1;

                                    3'd1:
                                        to_inf = 1'b0;

                                    3'd2:
                                        to_inf = sum_sign;

                                    3'd3:
                                        to_inf = !sum_sign;

                                    3'd4:
                                        to_inf = 1'b1;

                                    default:
                                        to_inf = 1'b1;

                                endcase

                                if (to_inf) begin
                                    res = {
                                        sum_sign,
                                        8'hff,
                                        23'h000000
                                    };
                                end
                                else begin
                                    res = {
                                        sum_sign,
                                        8'hfe,
                                        23'h7fffff
                                    };
                                end

                            end
                            else begin

                                out_exp = top_res + 127;

                                res = {
                                    sum_sign,
                                    out_exp,
                                    q24[22:0]
                                };

                                ov = 1'b0;
                                uf = 1'b0;
                                nx = rem_nonzero;

                            end

                        end

                    end

                    // ---------------------------------------------------------
                    // Subnormal / zero result path.
                    //
                    // The fixed binary32 subnormal quantum is 2^-149.
                    // ---------------------------------------------------------

                    else begin

                        cut = -149 - base_exp;

                        q_val       = 25'h0;
                        guard_bit   = 1'b0;
                        sticky_bit  = tail_nonzero;
                        rem_nonzero = 1'b0;
                        round_inc   = 1'b0;

                        if (cut >= 96)
                            q_val = 25'h0;
                        else if (cut >= 0)
                            q_val = sum_mag >> cut;
                        else
                            q_val = sum_mag << (-cut);

                        if (cut > 0) begin

                            if ((cut - 1) < 96)
                                guard_bit = sum_mag[cut-1];

                            for (i = 0; i < 96; i = i + 1) begin
                                if ((i < (cut - 1)) && sum_mag[i])
                                    sticky_bit = 1'b1;
                            end

                        end

                        rem_nonzero =
                            guard_bit ||
                            sticky_bit;

                        case (rm)

                            // RNE
                            3'd0:
                                round_inc =
                                    guard_bit &&
                                    (sticky_bit || q_val[0]);

                            // RTZ
                            3'd1:
                                round_inc = 1'b0;

                            // RDN
                            3'd2:
                                round_inc =
                                    sum_sign &&
                                    rem_nonzero;

                            // RUP
                            3'd3:
                                round_inc =
                                    !sum_sign &&
                                    rem_nonzero;

                            // RMM
                            3'd4:
                                round_inc = guard_bit;

                            default:
                                round_inc =
                                    guard_bit &&
                                    (sticky_bit || q_val[0]);

                        endcase

                        if (round_inc)
                            q_round = q_val + 25'd1;
                        else
                            q_round = q_val;

                        nx = rem_nonzero;
                        ov = 1'b0;

                        // -----------------------------------------------------
                        // Rounding can promote the largest subnormal to exactly
                        // the smallest normal.
                        //
                        // Under the task's explicit UF rule this is NOT
                        // underflow, because the delivered exponent field is 1.
                        // -----------------------------------------------------

                        if (q_round[23]) begin

                            res = {
                                sum_sign,
                                8'h01,
                                23'h000000
                            };

                            uf = 1'b0;

                        end
                        else begin

                            res = {
                                sum_sign,
                                8'h00,
                                q_round[22:0]
                            };

                            // Task-pinned underflow rule:
                            //
                            //     inexact &&
                            //     delivered exponent field == 0
                            uf = rem_nonzero;

                        end

                    end

                end

            end

            fma_compute = {
                nx,
                uf,
                ov,
                inv,
                res
            };

        end

    endfunction


    // =========================================================================
    // Three-cycle, initiation-interval-one pipeline
    // =========================================================================
    //
    // Arithmetic is calculated at acceptance and the completed result/flags are
    // carried through three valid stages.
    //
    // With out_ready asserted continuously:
    //
    //     one new request can be accepted every clock
    //     and one result can retire every clock.
    //
    // When the output is blocked, the pipeline freezes as a unit.  This keeps
    // the visible output stable and applies backpressure at the input.
    // =========================================================================

    logic [35:0] pipe_data_0;
    logic [35:0] pipe_data_1;
    logic [35:0] pipe_data_2;

    logic        pipe_valid_0;
    logic        pipe_valid_1;
    logic        pipe_valid_2;

    logic        pipe_advance;

    // Output stage.
    always_comb begin

        out_valid      = pipe_valid_2;

        result         = pipe_data_2[31:0];
        flag_invalid   = pipe_data_2[32];
        flag_overflow  = pipe_data_2[33];
        flag_underflow = pipe_data_2[34];
        flag_inexact   = pipe_data_2[35];

        // Freeze all three stages while an unconsumed result occupies the
        // output stage.
        pipe_advance = !pipe_valid_2 || out_ready;

        // No combinational dependence on in_valid.
        in_ready = rst_n && pipe_advance;

    end


    // Synchronous active-low reset.
    always_ff @(posedge clk) begin

        if (!rst_n) begin

            pipe_valid_0 <= 1'b0;
            pipe_valid_1 <= 1'b0;
            pipe_valid_2 <= 1'b0;

            pipe_data_0 <= 36'h0;
            pipe_data_1 <= 36'h0;
            pipe_data_2 <= 36'h0;

        end
        else if (pipe_advance) begin

            // Stage 2
            pipe_valid_2 <= pipe_valid_1;

            if (pipe_valid_1)
                pipe_data_2 <= pipe_data_1;

            // Stage 1
            pipe_valid_1 <= pipe_valid_0;

            if (pipe_valid_0)
                pipe_data_1 <= pipe_data_0;

            // Stage 0
            pipe_valid_0 <= in_valid && in_ready;

            if (in_valid && in_ready) begin
                pipe_data_0 <= fma_compute(
                    a,
                    b,
                    c,
                    rnd_mode
                );
            end

        end

    end

endmodule