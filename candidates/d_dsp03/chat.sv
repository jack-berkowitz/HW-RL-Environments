module fp_multifmt_fma #(
    parameter int unsigned WIDTH = 64
) (
    input  logic             clk_i,
    input  logic             rst_ni,

    // ---- operation in -------------------------------------------------------
    input  logic             in_valid_i,
    output logic             in_ready_o,
    input  logic [1:0]       fmt_i,
    input  logic             vec_i,
    input  logic [WIDTH-1:0] a_i,
    input  logic [WIDTH-1:0] b_i,
    input  logic [WIDTH-1:0] c_i,
    input  logic [2:0]       rnd_i,

    // ---- result out ---------------------------------------------------------
    output logic             out_valid_o,
    input  logic             out_ready_i,
    output logic [WIDTH-1:0] result_o,
    output logic [4:0]       flags_o
);

    // =========================================================================
    // Per-format fused arithmetic helper
    //
    // Parameters supplied to the macro:
    //
    //   TW      total floating-point width
    //   EW      exponent width
    //   FW      fraction width
    //   PW      significand precision including hidden bit
    //   PRODW   exact product significand width = 2*PW
    //   WORKW   bounded fused alignment/addition workspace = 4*PW
    //
    // Thus:
    //
    //   FP32 : p=24 -> 96-bit workspace
    //   FP16 : p=11 -> 44-bit workspace
    //   BF16 : p=8  -> 32-bit workspace
    //
    // Return value:
    //   {NV,DZ,OF,UF,NX,result}
    //
    // DZ is always zero.
    // =========================================================================

`define DEFINE_FMA_FUNC(NAME,TW,EW,FW,PW,PRODW,WORKW) \
function automatic logic [TW+4:0] NAME ( \
    input logic [TW-1:0] aa, \
    input logic [TW-1:0] bb, \
    input logic [TW-1:0] cc, \
    input logic [2:0] rm \
); \
    logic sign_a, sign_b, sign_c; \
    logic prod_sign, sum_sign, zero_sign; \
    logic [EW-1:0] exp_a, exp_b, exp_c; \
    logic [FW-1:0] frac_a, frac_b, frac_c; \
    logic nan_a, nan_b, nan_c; \
    logic snan_a, snan_b, snan_c; \
    logic inf_a, inf_b, inf_c; \
    logic zero_a, zero_b, zero_c; \
    logic mul_invalid; \
    logic prod_inf; \
    logic prod_zero; \
    logic inf_sub_invalid; \
    logic [PW-1:0] sig_a, sig_b, sig_c; \
    logic [PRODW-1:0] prod_sig; \
    integer bias_i, emin_i, emax_i; \
    integer ea_u, eb_u, ec_u, ep_u; \
    integer lead_p, lead_c, lead_sum; \
    integer top_p, top_c, top_max, top_res; \
    integer base_exp; \
    integer shift_p, shift_c, rshift, cut; \
    logic [WORKW-1:0] wide_tmp; \
    logic [WORKW-1:0] mag_p; \
    logic [WORKW-1:0] mag_c; \
    logic [WORKW-1:0] sum_mag; \
    logic lost_p, lost_c; \
    logic tail_nonzero; \
    logic found; \
    logic [PW:0] q_val, q_round; \
    logic [PW-1:0] q_sig; \
    logic guard_bit; \
    logic sticky_bit; \
    logic rem_nonzero; \
    logic round_inc; \
    logic to_inf; \
    logic [EW-1:0] out_exp; \
    logic [TW-1:0] res; \
    logic inv, ov, uf, nx; \
    integer i; \
    begin \
        bias_i = (1 << (EW-1)) - 1; \
        emin_i = 1 - bias_i; \
        emax_i = bias_i; \
        res = '0; \
        inv = 1'b0; \
        ov  = 1'b0; \
        uf  = 1'b0; \
        nx  = 1'b0; \
        sign_a = aa[TW-1]; \
        sign_b = bb[TW-1]; \
        sign_c = cc[TW-1]; \
        exp_a  = aa[FW +: EW]; \
        exp_b  = bb[FW +: EW]; \
        exp_c  = cc[FW +: EW]; \
        frac_a = aa[FW-1:0]; \
        frac_b = bb[FW-1:0]; \
        frac_c = cc[FW-1:0]; \
        prod_sign = sign_a ^ sign_b; \
        nan_a = (&exp_a) && (frac_a != '0); \
        nan_b = (&exp_b) && (frac_b != '0); \
        nan_c = (&exp_c) && (frac_c != '0); \
        snan_a = nan_a && !frac_a[FW-1]; \
        snan_b = nan_b && !frac_b[FW-1]; \
        snan_c = nan_c && !frac_c[FW-1]; \
        inf_a = (&exp_a) && (frac_a == '0); \
        inf_b = (&exp_b) && (frac_b == '0); \
        inf_c = (&exp_c) && (frac_c == '0); \
        zero_a = (exp_a == '0) && (frac_a == '0); \
        zero_b = (exp_b == '0) && (frac_b == '0); \
        zero_c = (exp_c == '0) && (frac_c == '0); \
        prod_zero = zero_a || zero_b; \
        mul_invalid = \
            (inf_a && zero_b) || \
            (zero_a && inf_b); \
        prod_inf = \
            (inf_a || inf_b) && \
            !mul_invalid && \
            !nan_a && \
            !nan_b; \
        inf_sub_invalid = \
            prod_inf && \
            inf_c && \
            (prod_sign != sign_c); \
        inv = \
            snan_a || \
            snan_b || \
            snan_c || \
            mul_invalid || \
            inf_sub_invalid; \
        if (nan_a || nan_b || nan_c || inv) begin \
            res = { \
                1'b0, \
                {EW{1'b1}}, \
                1'b1, \
                {(FW-1){1'b0}} \
            }; \
        end \
        else if (prod_inf) begin \
            res = { \
                prod_sign, \
                {EW{1'b1}}, \
                {FW{1'b0}} \
            }; \
        end \
        else if (inf_c) begin \
            res = cc; \
        end \
        else if (prod_zero && zero_c) begin \
            if (prod_sign == sign_c) \
                zero_sign = prod_sign; \
            else \
                zero_sign = (rm == 3'd2); \
            res = { \
                zero_sign, \
                {(TW-1){1'b0}} \
            }; \
        end \
        else if (prod_zero) begin \
            res = cc; \
        end \
        else begin \
            if (exp_a == '0) begin \
                sig_a = {1'b0, frac_a}; \
                ea_u = emin_i - FW; \
            end \
            else begin \
                sig_a = {1'b1, frac_a}; \
                ea_u = exp_a; \
                ea_u = ea_u - bias_i - FW; \
            end \
            if (exp_b == '0) begin \
                sig_b = {1'b0, frac_b}; \
                eb_u = emin_i - FW; \
            end \
            else begin \
                sig_b = {1'b1, frac_b}; \
                eb_u = exp_b; \
                eb_u = eb_u - bias_i - FW; \
            end \
            if (exp_c == '0) begin \
                sig_c = {1'b0, frac_c}; \
                ec_u = emin_i - FW; \
            end \
            else begin \
                sig_c = {1'b1, frac_c}; \
                ec_u = exp_c; \
                ec_u = ec_u - bias_i - FW; \
            end \
            prod_sig = sig_a * sig_b; \
            ep_u = ea_u + eb_u; \
            lead_p = 0; \
            found = 1'b0; \
            for (i = PRODW-1; i >= 0; i = i - 1) begin \
                if (!found && prod_sig[i]) begin \
                    lead_p = i; \
                    found = 1'b1; \
                end \
            end \
            top_p = ep_u + lead_p; \
            if (sig_c != '0) begin \
                lead_c = 0; \
                found = 1'b0; \
                for (i = PW-1; i >= 0; i = i - 1) begin \
                    if (!found && sig_c[i]) begin \
                        lead_c = i; \
                        found = 1'b1; \
                    end \
                end \
                top_c = ec_u + lead_c; \
            end \
            else begin \
                lead_c = 0; \
                top_c = -1000000; \
            end \
            if (top_p >= top_c) \
                top_max = top_p; \
            else \
                top_max = top_c; \
            base_exp = top_max - (WORKW-2); \
            wide_tmp = '0; \
            wide_tmp[PRODW-1:0] = prod_sig; \
            shift_p = ep_u - base_exp; \
            mag_p = '0; \
            lost_p = 1'b0; \
            if (shift_p >= 0) begin \
                mag_p = wide_tmp << shift_p; \
            end \
            else begin \
                rshift = -shift_p; \
                if (rshift >= WORKW) \
                    mag_p = '0; \
                else \
                    mag_p = wide_tmp >> rshift; \
                for (i = 0; i < PRODW; i = i + 1) begin \
                    if ((i < rshift) && prod_sig[i]) \
                        lost_p = 1'b1; \
                end \
            end \
            wide_tmp = '0; \
            wide_tmp[PW-1:0] = sig_c; \
            shift_c = ec_u - base_exp; \
            mag_c = '0; \
            lost_c = 1'b0; \
            if (sig_c == '0) begin \
                mag_c = '0; \
                lost_c = 1'b0; \
            end \
            else if (shift_c >= 0) begin \
                mag_c = wide_tmp << shift_c; \
            end \
            else begin \
                rshift = -shift_c; \
                if (rshift >= WORKW) \
                    mag_c = '0; \
                else \
                    mag_c = wide_tmp >> rshift; \
                for (i = 0; i < PW; i = i + 1) begin \
                    if ((i < rshift) && sig_c[i]) \
                        lost_c = 1'b1; \
                end \
            end \
            sum_mag = '0; \
            tail_nonzero = 1'b0; \
            sum_sign = prod_sign; \
            if (prod_sign == sign_c) begin \
                sum_mag = mag_p + mag_c; \
                sum_sign = prod_sign; \
                tail_nonzero = lost_p || lost_c; \
            end \
            else if (mag_p > mag_c) begin \
                sum_mag = mag_p - mag_c; \
                sum_sign = prod_sign; \
                if (lost_p && !lost_c) begin \
                    tail_nonzero = 1'b1; \
                end \
                else if (lost_c && !lost_p) begin \
                    if (sum_mag != '0) \
                        sum_mag = sum_mag - \
                            {{(WORKW-1){1'b0}},1'b1}; \
                    tail_nonzero = 1'b1; \
                end \
            end \
            else if (mag_c > mag_p) begin \
                sum_mag = mag_c - mag_p; \
                sum_sign = sign_c; \
                if (lost_c && !lost_p) begin \
                    tail_nonzero = 1'b1; \
                end \
                else if (lost_p && !lost_c) begin \
                    if (sum_mag != '0) \
                        sum_mag = sum_mag - \
                            {{(WORKW-1){1'b0}},1'b1}; \
                    tail_nonzero = 1'b1; \
                end \
            end \
            else begin \
                sum_mag = '0; \
                tail_nonzero = 1'b0; \
                sum_sign = (rm == 3'd2); \
            end \
            if ((sum_mag == '0) && !tail_nonzero) begin \
                zero_sign = (rm == 3'd2); \
                res = { \
                    zero_sign, \
                    {(TW-1){1'b0}} \
                }; \
            end \
            else begin \
                lead_sum = 0; \
                found = 1'b0; \
                for (i = WORKW-1; i >= 0; i = i - 1) begin \
                    if (!found && sum_mag[i]) begin \
                        lead_sum = i; \
                        found = 1'b1; \
                    end \
                end \
                top_res = base_exp + lead_sum; \
                if (top_res >= emin_i) begin \
                    if (top_res > emax_i) begin \
                        ov = 1'b1; \
                        nx = 1'b1; \
                        case (rm) \
                            3'd0: to_inf = 1'b1; \
                            3'd1: to_inf = 1'b0; \
                            3'd2: to_inf = sum_sign; \
                            3'd3: to_inf = !sum_sign; \
                            3'd4: to_inf = 1'b1; \
                            default: to_inf = 1'b1; \
                        endcase \
                        if (to_inf) begin \
                            res = { \
                                sum_sign, \
                                {EW{1'b1}}, \
                                {FW{1'b0}} \
                            }; \
                        end \
                        else begin \
                            res = { \
                                sum_sign, \
                                {{(EW-1){1'b1}},1'b0}, \
                                {FW{1'b1}} \
                            }; \
                        end \
                    end \
                    else begin \
                        cut = lead_sum - FW; \
                        q_val = '0; \
                        guard_bit = 1'b0; \
                        sticky_bit = tail_nonzero; \
                        rem_nonzero = 1'b0; \
                        round_inc = 1'b0; \
                        if (cut >= WORKW) \
                            q_val = '0; \
                        else if (cut >= 0) \
                            q_val = sum_mag >> cut; \
                        else \
                            q_val = sum_mag << (-cut); \
                        if (cut > 0) begin \
                            if ((cut - 1) < WORKW) \
                                guard_bit = sum_mag[cut-1]; \
                            for (i = 0; i < WORKW; i = i + 1) begin \
                                if ((i < (cut - 1)) && sum_mag[i]) \
                                    sticky_bit = 1'b1; \
                            end \
                        end \
                        rem_nonzero = \
                            guard_bit || sticky_bit; \
                        case (rm) \
                            3'd0: round_inc = \
                                guard_bit && \
                                (sticky_bit || q_val[0]); \
                            3'd1: round_inc = 1'b0; \
                            3'd2: round_inc = \
                                sum_sign && rem_nonzero; \
                            3'd3: round_inc = \
                                !sum_sign && rem_nonzero; \
                            3'd4: round_inc = guard_bit; \
                            default: round_inc = \
                                guard_bit && \
                                (sticky_bit || q_val[0]); \
                        endcase \
                        if (round_inc) \
                            q_round = q_val + \
                                {{PW{1'b0}},1'b1}; \
                        else \
                            q_round = q_val; \
                        if (q_round[PW]) begin \
                            q_sig = q_round[PW:1]; \
                            top_res = top_res + 1; \
                        end \
                        else begin \
                            q_sig = q_round[PW-1:0]; \
                        end \
                        if (top_res > emax_i) begin \
                            ov = 1'b1; \
                            nx = 1'b1; \
                            case (rm) \
                                3'd0: to_inf = 1'b1; \
                                3'd1: to_inf = 1'b0; \
                                3'd2: to_inf = sum_sign; \
                                3'd3: to_inf = !sum_sign; \
                                3'd4: to_inf = 1'b1; \
                                default: to_inf = 1'b1; \
                            endcase \
                            if (to_inf) begin \
                                res = { \
                                    sum_sign, \
                                    {EW{1'b1}}, \
                                    {FW{1'b0}} \
                                }; \
                            end \
                            else begin \
                                res = { \
                                    sum_sign, \
                                    {{(EW-1){1'b1}},1'b0}, \
                                    {FW{1'b1}} \
                                }; \
                            end \
                        end \
                        else begin \
                            out_exp = top_res + bias_i; \
                            res = { \
                                sum_sign, \
                                out_exp, \
                                q_sig[FW-1:0] \
                            }; \
                            nx = rem_nonzero; \
                        end \
                    end \
                end \
                else begin \
                    cut = (emin_i - FW) - base_exp; \
                    q_val = '0; \
                    guard_bit = 1'b0; \
                    sticky_bit = tail_nonzero; \
                    rem_nonzero = 1'b0; \
                    round_inc = 1'b0; \
                    if (cut >= WORKW) \
                        q_val = '0; \
                    else if (cut >= 0) \
                        q_val = sum_mag >> cut; \
                    else \
                        q_val = sum_mag << (-cut); \
                    if (cut > 0) begin \
                        if ((cut - 1) < WORKW) \
                            guard_bit = sum_mag[cut-1]; \
                        for (i = 0; i < WORKW; i = i + 1) begin \
                            if ((i < (cut - 1)) && sum_mag[i]) \
                                sticky_bit = 1'b1; \
                        end \
                    end \
                    rem_nonzero = \
                        guard_bit || sticky_bit; \
                    case (rm) \
                        3'd0: round_inc = \
                            guard_bit && \
                            (sticky_bit || q_val[0]); \
                        3'd1: round_inc = 1'b0; \
                        3'd2: round_inc = \
                            sum_sign && rem_nonzero; \
                        3'd3: round_inc = \
                            !sum_sign && rem_nonzero; \
                        3'd4: round_inc = guard_bit; \
                        default: round_inc = \
                            guard_bit && \
                            (sticky_bit || q_val[0]); \
                    endcase \
                    if (round_inc) \
                        q_round = q_val + \
                            {{PW{1'b0}},1'b1}; \
                    else \
                        q_round = q_val; \
                    nx = rem_nonzero; \
                    if (q_round[FW]) begin \
                        res = { \
                            sum_sign, \
                            {{(EW-1){1'b0}},1'b1}, \
                            {FW{1'b0}} \
                        }; \
                        uf = 1'b0; \
                    end \
                    else begin \
                        res = { \
                            sum_sign, \
                            {EW{1'b0}}, \
                            q_round[FW-1:0] \
                        }; \
                        uf = rem_nonzero; \
                    end \
                end \
            end \
        end \
        NAME = { \
            inv, \
            1'b0, \
            ov, \
            uf, \
            nx, \
            res \
        }; \
    end \
endfunction


    // -------------------------------------------------------------------------
    // Three bounded format implementations.
    //
    // No format uses a significand workspace wider than 4*p.
    // -------------------------------------------------------------------------

    `DEFINE_FMA_FUNC(fma32,    32, 8, 23, 24, 48, 96)
    `DEFINE_FMA_FUNC(fma16,    16, 5, 10, 11, 22, 44)
    `DEFINE_FMA_FUNC(fma_bf16, 16, 8,  7,  8, 16, 32)

`undef DEFINE_FMA_FUNC


    // =========================================================================
    // SIMD operation construction
    // =========================================================================

    logic [WIDTH-1:0] calc_result;
    logic [4:0]       calc_flags;

    logic [36:0] lane32_value;
    logic [20:0] lane16_value;

    integer k;

    always_comb begin

        // V3: bits above the active lanes are ones.
        calc_result = '1;

        // V4: flags are ORed only across active lanes.
        calc_flags = 5'b00000;

        lane32_value = '0;
        lane16_value = '0;

        case (fmt_i)

            // -----------------------------------------------------------------
            // FP32
            // -----------------------------------------------------------------

            2'd0: begin

                // Constant loop bound.  WIDTH/32 is 1 or 2.
                for (k = 0; k < WIDTH/32; k = k + 1) begin

                    if (vec_i || (k == 0)) begin

                        lane32_value = fma32(
                            a_i[k*32 +: 32],
                            b_i[k*32 +: 32],
                            c_i[k*32 +: 32],
                            rnd_i
                        );

                        calc_result[k*32 +: 32] =
                            lane32_value[31:0];

                        calc_flags =
                            calc_flags |
                            lane32_value[36:32];

                    end

                end

            end


            // -----------------------------------------------------------------
            // FP16
            // -----------------------------------------------------------------

            2'd1: begin

                // Constant loop bound.  WIDTH/16 is 2 or 4.
                for (k = 0; k < WIDTH/16; k = k + 1) begin

                    if (vec_i || (k == 0)) begin

                        lane16_value = fma16(
                            a_i[k*16 +: 16],
                            b_i[k*16 +: 16],
                            c_i[k*16 +: 16],
                            rnd_i
                        );

                        calc_result[k*16 +: 16] =
                            lane16_value[15:0];

                        calc_flags =
                            calc_flags |
                            lane16_value[20:16];

                    end

                end

            end


            // -----------------------------------------------------------------
            // BF16
            // -----------------------------------------------------------------

            2'd2: begin

                // Constant loop bound.  WIDTH/16 is 2 or 4.
                for (k = 0; k < WIDTH/16; k = k + 1) begin

                    if (vec_i || (k == 0)) begin

                        lane16_value = fma_bf16(
                            a_i[k*16 +: 16],
                            b_i[k*16 +: 16],
                            c_i[k*16 +: 16],
                            rnd_i
                        );

                        calc_result[k*16 +: 16] =
                            lane16_value[15:0];

                        calc_flags =
                            calc_flags |
                            lane16_value[20:16];

                    end

                end

            end


            // fmt_i == 3 is outside the contract.
            default: begin
                calc_result = '1;
                calc_flags  = 5'b00000;
            end

        endcase

    end


    // =========================================================================
    // One-entry elastic output register
    //
    // Latency and throughput are unconstrained by this task.  This structure
    // gives:
    //
    //   - one-cycle result latency when accepted into an empty buffer
    //   - stable output/result/flags during backpressure
    //   - one operation per cycle when out_ready_i remains asserted
    //   - in-order results
    // =========================================================================

    logic             valid_q;
    logic [WIDTH-1:0] result_q;
    logic [4:0]       flags_q;


    always_comb begin

        out_valid_o = valid_q;
        result_o    = result_q;
        flags_o     = flags_q;

        // Buffer can accept when empty or when the current result is being
        // consumed on this edge.
        in_ready_o = !valid_q || out_ready_i;

    end


    // Active-low reset.
    always_ff @(posedge clk_i or negedge rst_ni) begin

        if (!rst_ni) begin

            valid_q  <= 1'b0;
            result_q <= '1;
            flags_q  <= 5'b00000;

        end
        else if (in_ready_o) begin

            valid_q <= in_valid_i;

            if (in_valid_i) begin
                result_q <= calc_result;
                flags_q  <= calc_flags;
            end

        end

    end

endmodule