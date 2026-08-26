module fp16_gemm_array #(
    parameter int WIDTH  = 8,
    parameter int HEIGHT = 8
) (
    input  logic                                      clk_i,
    input  logic                                      rst_ni,
    input  logic [WIDTH-1:0][HEIGHT-1:0][15:0]       x_i,
    input  logic [HEIGHT-1:0][15:0]                  w_i,
    input  logic [WIDTH-1:0][15:0]                   y_i,
    output logic [WIDTH-1:0][15:0]                   z_o,
    input  logic [2:0]                                rnd_i,
    input  logic                                      accumulate_i,
    input  logic [WIDTH-1:0]                         row_clk_gate_en_i,
    input  logic                                      reg_enable_i,
    input  logic                                      flush_i,
    output logic [WIDTH-1:0][HEIGHT-1:0][4:0]        status_o
);

    function automatic int msb8(input logic [7:0] v);
        begin
            casez (v)
                8'b1???????: msb8 = 7;
                8'b01??????: msb8 = 6;
                8'b001?????: msb8 = 5;
                8'b0001????: msb8 = 4;
                8'b00001???: msb8 = 3;
                8'b000001??: msb8 = 2;
                8'b0000001?: msb8 = 1;
                default:     msb8 = 0;
            endcase
        end
    endfunction

    // Small fixed-bound priority encoder. No wide iterative leading-one scan:
    // that matters for the slang unroll-limit requirement in T5.
    function automatic int msb_index65(input logic [64:0] v);
        begin
            if      (v[64])      msb_index65 = 64;
            else if (|v[63:56])  msb_index65 = 56 + msb8(v[63:56]);
            else if (|v[55:48])  msb_index65 = 48 + msb8(v[55:48]);
            else if (|v[47:40])  msb_index65 = 40 + msb8(v[47:40]);
            else if (|v[39:32])  msb_index65 = 32 + msb8(v[39:32]);
            else if (|v[31:24])  msb_index65 = 24 + msb8(v[31:24]);
            else if (|v[23:16])  msb_index65 = 16 + msb8(v[23:16]);
            else if (|v[15:8])   msb_index65 =  8 + msb8(v[15:8]);
            else if (|v[7:0])    msb_index65 =      msb8(v[7:0]);
            else                 msb_index65 = -1;
        end
    endfunction

    function automatic logic round_increment(
        input logic [2:0]  rnd,
        input logic        sign,
        input logic [64:0] rem,
        input logic [64:0] half,
        input logic        retained_lsb
    );
        begin
            if (rem == 65'd0) begin
                round_increment = 1'b0;
            end else begin
                case (rnd)
                    3'd0: round_increment =
                        (rem > half) ||
                        ((rem == half) && retained_lsb); // RNE

                    3'd1: round_increment = 1'b0;        // RTZ
                    3'd2: round_increment = sign;        // RDN
                    3'd3: round_increment = !sign;       // RUP
                    3'd4: round_increment = (rem >= half); // RMM

                    default: round_increment =
                        (rem > half) ||
                        ((rem == half) && retained_lsb);
                endcase
            end
        end
    endfunction

    function automatic logic [15:0] overflow_value(
        input logic       sign,
        input logic [2:0] rnd
    );
        begin
            case (rnd)
                3'd0: overflow_value =
                    sign ? 16'hFC00 : 16'h7C00; // RNE

                3'd1: overflow_value =
                    sign ? 16'hFBFF : 16'h7BFF; // RTZ

                3'd2: overflow_value =
                    sign ? 16'hFC00 : 16'h7BFF; // RDN

                3'd3: overflow_value =
                    sign ? 16'hFBFF : 16'h7C00; // RUP

                3'd4: overflow_value =
                    sign ? 16'hFC00 : 16'h7C00; // RMM

                default: overflow_value =
                    sign ? 16'hFC00 : 16'h7C00;
            endcase
        end
    endfunction

    // Return value: {flags[4:0], result[15:0]}
    // flags are {NV, DZ, OF, UF, NX}.
    function automatic logic [20:0] fp16_fma(
        input logic [15:0] a,
        input logic [15:0] b,
        input logic [15:0] c,
        input logic [2:0]  rnd
    );
        logic a_nan, b_nan, c_nan;
        logic a_qnan, b_qnan, c_qnan;
        logic a_snan, b_snan, c_snan;

        logic a_inf, b_inf, c_inf;
        logic a_zero, b_zero;

        logic prod_sign;
        logic c_sign;
        logic result_sign;

        logic [10:0] ma, mb, mc;
        logic [21:0] prod_mant;

        logic [64:0] prod_mag;
        logic [64:0] c_mag;
        logic [64:0] sum_mag;

        logic [64:0] trunc_mag;
        logic [64:0] rem_mag;
        logic [64:0] half_mag;

        logic [12:0] q_work;

        logic [15:0] result;
        logic [4:0]  flags;

        logic inc;

        integer ea, eb, ec;
        integer ep;
        integer ebase;
        integer prod_shift;
        integer c_shift;
        integer msb_pos;
        integer top_exp;
        integer rshift;
        integer sub_scale;
        integer sub_shift;
        integer exp_field;

        begin
            result = 16'h0000;
            flags  = 5'b00000;

            a_nan  = (&a[14:10]) && (|a[9:0]);
            b_nan  = (&b[14:10]) && (|b[9:0]);
            c_nan  = (&c[14:10]) && (|c[9:0]);

            a_qnan = a_nan && a[9];
            b_qnan = b_nan && b[9];
            c_qnan = c_nan && c[9];

            a_snan = a_nan && !a[9];
            b_snan = b_nan && !b[9];
            c_snan = c_nan && !c[9];

            a_inf = (&a[14:10]) && !(|a[9:0]);
            b_inf = (&b[14:10]) && !(|b[9:0]);
            c_inf = (&c[14:10]) && !(|c[9:0]);

            a_zero = !(|a[14:0]);
            b_zero = !(|b[14:0]);

            prod_sign = a[15] ^ b[15];
            c_sign    = c[15];

            // Any quiet NaN operand returns the canonical qNaN with no flag.
            if (a_qnan || b_qnan || c_qnan) begin
                result = 16'h7E00;
            end

            // Signaling NaNs are outside the scored contract. Quiet them and
            // treat them as invalid.
            else if (a_snan || b_snan || c_snan) begin
                result   = 16'h7E00;
                flags[4] = 1'b1;
            end

            // infinity * zero is invalid.
            else if ((a_inf && b_zero) ||
                     (b_inf && a_zero)) begin
                result   = 16'h7E00;
                flags[4] = 1'b1;
            end

            // Infinite product.
            else if (a_inf || b_inf) begin
                // +inf + -inf or -inf + +inf.
                if (c_inf && (c_sign != prod_sign)) begin
                    result   = 16'h7E00;
                    flags[4] = 1'b1;
                end else begin
                    result =
                        prod_sign ? 16'hFC00 : 16'h7C00;
                end
            end

            // Finite product plus infinity.
            else if (c_inf) begin
                result =
                    c_sign ? 16'hFC00 : 16'h7C00;
            end

            else begin
                // ---------------------------------------------------------
                // Exact finite operand decoding.
                //
                // Normal:
                //   value = {1,frac} * 2^(exp_field - 25)
                //
                // Subnormal:
                //   value = {0,frac} * 2^-24
                // ---------------------------------------------------------

                if (a[14:10] == 5'd0) begin
                    ma = {1'b0, a[9:0]};
                    ea = -24;
                end else begin
                    ma = {1'b1, a[9:0]};
                    ea = $unsigned(a[14:10]);
                    ea = ea - 25;
                end

                if (b[14:10] == 5'd0) begin
                    mb = {1'b0, b[9:0]};
                    eb = -24;
                end else begin
                    mb = {1'b1, b[9:0]};
                    eb = $unsigned(b[14:10]);
                    eb = eb - 25;
                end

                if (c[14:10] == 5'd0) begin
                    mc = {1'b0, c[9:0]};
                    ec = -24;
                end else begin
                    mc = {1'b1, c[9:0]};
                    ec = $unsigned(c[14:10]);
                    ec = ec - 25;
                end

                // ---------------------------------------------------------
                // Exact fused arithmetic.
                //
                // The binary16 product significand is at most 22 bits.
                // Align product and addend to min(ep,ec).
                //
                // Maximum required alignment:
                //   product shift <= 34
                //   c shift       <= 53
                //
                // 65 bits are sufficient for the exact magnitude.
                // ---------------------------------------------------------

                prod_mant = ma * mb;
                ep        = ea + eb;

                ebase = (ep < ec) ? ep : ec;

                prod_shift = ep - ebase;
                c_shift    = ec - ebase;

                prod_mag =
                    ({43'b0, prod_mant} << prod_shift);

                c_mag =
                    ({54'b0, mc} << c_shift);

                if (prod_sign == c_sign) begin
                    sum_mag     = prod_mag + c_mag;
                    result_sign = prod_sign;
                end
                else if (prod_mag > c_mag) begin
                    sum_mag     = prod_mag - c_mag;
                    result_sign = prod_sign;
                end
                else if (c_mag > prod_mag) begin
                    sum_mag     = c_mag - prod_mag;
                    result_sign = c_sign;
                end
                else begin
                    sum_mag = 65'd0;

                    // Exact cancellation is -0 only in RDN.
                    result_sign = (rnd == 3'd2);
                end

                // ---------------------------------------------------------
                // Exact zero.
                // ---------------------------------------------------------

                if (sum_mag == 65'd0) begin
                    // Same-sign zero plus zero preserves the common sign.
                    if ((prod_mag == 65'd0) &&
                        (c_mag    == 65'd0) &&
                        (prod_sign == c_sign)) begin
                        result_sign = prod_sign;
                    end

                    result =
                        {result_sign, 15'h0000};
                end

                else begin
                    msb_pos = msb_index65(sum_mag);
                    top_exp = ebase + msb_pos;

                    // =====================================================
                    // SUBNORMAL / BELOW-MIN-SUBNORMAL PATH
                    // =====================================================
                    if (top_exp < -14) begin
                        // Express the exact magnitude in units of 2^-24.
                        //
                        // q_exact =
                        //    sum_mag * 2^(ebase + 24)
                        //
                        // Positive scale => exact left shift.
                        // Negative scale => right shift with discarded bits.

                        sub_scale = ebase + 24;

                        rem_mag  = 65'd0;
                        half_mag = 65'd0;

                        if (sub_scale >= 0) begin
                            q_work =
                                (sum_mag << sub_scale);

                            inc = 1'b0;
                        end
                        else begin
                            sub_shift = -sub_scale;

                            q_work =
                                (sum_mag >> sub_shift);

                            trunc_mag =
                                ({52'b0, q_work}
                                 << sub_shift);

                            rem_mag =
                                sum_mag - trunc_mag;

                            half_mag =
                                (65'd1 << (sub_shift - 1));

                            inc =
                                round_increment(
                                    rnd,
                                    result_sign,
                                    rem_mag,
                                    half_mag,
                                    q_work[0]
                                );

                            if (inc)
                                q_work =
                                    q_work + 13'd1;
                        end

                        // Rounding can promote the largest subnormal to the
                        // minimum normal.
                        if (q_work >= 13'd1024) begin
                            result =
                                {result_sign,
                                 5'd1,
                                 10'd0};

                            if (rem_mag != 65'd0)
                                flags[0] = 1'b1;
                        end
                        else begin
                            result =
                                {result_sign,
                                 5'd0,
                                 q_work[9:0]};

                            if (rem_mag != 65'd0) begin
                                // Tiny and inexact.
                                flags[1] = 1'b1; // UF
                                flags[0] = 1'b1; // NX
                            end
                        end
                    end

                    // =====================================================
                    // NORMAL PATH
                    // =====================================================
                    else begin
                        rem_mag  = 65'd0;
                        half_mag = 65'd0;

                        // Normalize to an 11-bit significand.
                        if (msb_pos > 10) begin
                            rshift =
                                msb_pos - 10;

                            q_work =
                                (sum_mag >> rshift);

                            trunc_mag =
                                ({52'b0, q_work}
                                 << rshift);

                            rem_mag =
                                sum_mag - trunc_mag;

                            half_mag =
                                (65'd1 << (rshift - 1));
                        end
                        else begin
                            rshift = 0;

                            q_work =
                                (sum_mag << (10 - msb_pos));
                        end

                        // -------------------------------------------------
                        // A5 overflow threshold.
                        //
                        // 65520 is halfway between:
                        //   65504 = max finite
                        // and the next unbounded 11-bit value 65536.
                        //
                        // At or above this threshold the contractual
                        // endpoint table is used for all rounding modes.
                        // -------------------------------------------------

                        if ((top_exp > 15) ||
                            ((top_exp == 15) &&
                             (q_work == 13'd2047) &&
                             (rem_mag >= half_mag) &&
                             (rem_mag != 65'd0))) begin

                            result =
                                overflow_value(
                                    result_sign,
                                    rnd
                                );

                            flags[2] = 1'b1; // OF
                            flags[0] = 1'b1; // NX
                        end

                        else begin
                            inc =
                                round_increment(
                                    rnd,
                                    result_sign,
                                    rem_mag,
                                    half_mag,
                                    q_work[0]
                                );

                            if (inc)
                                q_work =
                                    q_work + 13'd1;

                            // Significand rounding carry.
                            if (q_work == 13'd2048) begin
                                q_work =
                                    13'd1024;

                                top_exp =
                                    top_exp + 1;
                            end

                            // A directed rounding mode can cross the range
                            // endpoint from just below the common A5
                            // threshold.
                            if (top_exp > 15) begin
                                result =
                                    overflow_value(
                                        result_sign,
                                        rnd
                                    );

                                flags[2] = 1'b1; // OF
                                flags[0] = 1'b1; // NX
                            end

                            else begin
                                exp_field =
                                    top_exp + 15;

                                result = {
                                    result_sign,
                                    exp_field[4:0],
                                    q_work[9:0]
                                };

                                if (rem_mag != 65'd0)
                                    flags[0] = 1'b1;
                            end
                        end
                    end
                end
            end

            fp16_fma =
                {flags, result};
        end
    endfunction


    // -------------------------------------------------------------------------
    // Datapath state
    // -------------------------------------------------------------------------

    // A result from stage k is consumed by stage k+1 exactly four enabled
    // ticks later. Only stages 0 .. HEIGHT-2 need these delay registers.
    logic [WIDTH-1:0]
          [HEIGHT-2:0]
          [3:0]
          [15:0] partial_pipe;

    // Final value delay.
    logic [WIDTH-1:0][15:0]
        z_delay0,
        z_delay1;

    // Per-stage flag delay.
    logic [WIDTH-1:0]
          [HEIGHT-1:0]
          [4:0]
          status_delay0,
          status_delay1;

    // {flags,result} for the operation presented to each FMA stage in the
    // current enabled tick.
    wire [WIDTH-1:0]
         [HEIGHT-1:0]
         [20:0] fma_calc;


    // -------------------------------------------------------------------------
    // Combinational FMA stages
    // -------------------------------------------------------------------------

    genvar gr;
    genvar gk;

    generate
        for (gr = 0;
             gr < WIDTH;
             gr = gr + 1) begin : g_calc_row

            for (gk = 0;
                 gk < HEIGHT;
                 gk = gk + 1) begin : g_calc_stage

                if (gk == 0) begin : g_first
                    assign fma_calc[gr][gk] =
                        fp16_fma(
                            x_i[gr][gk],
                            w_i[gk],

                            accumulate_i
                                ? z_o[gr]
                                : y_i[gr],

                            rnd_i
                        );
                end
                else begin : g_later
                    assign fma_calc[gr][gk] =
                        fp16_fma(
                            x_i[gr][gk],
                            w_i[gk],

                            partial_pipe
                                [gr]
                                [gk-1]
                                [3],

                            rnd_i
                        );
                end

            end
        end
    endgenerate


    // -------------------------------------------------------------------------
    // Sequential state
    // -------------------------------------------------------------------------

    integer r;
    integer k;

    always_ff @(posedge clk_i or negedge rst_ni) begin

        if (!rst_ni) begin
            z_o           <= '0;
            status_o      <= '0;

            z_delay0      <= '0;
            z_delay1      <= '0;

            status_delay0 <= '0;
            status_delay1 <= '0;

            partial_pipe  <= '0;
        end

        else begin

            for (r = 0;
                 r < WIDTH;
                 r = r + 1) begin

                // C4:
                // A gated row holds absolutely everything. Flush does not
                // override the row clock gate.
                if (row_clk_gate_en_i[r]) begin

                    // C2:
                    // Flush takes precedence over reg_enable_i.
                    if (flush_i) begin

                        z_o[r]      <= 16'h0000;
                        z_delay0[r] <= 16'h0000;
                        z_delay1[r] <= 16'h0000;

                        for (k = 0;
                             k < HEIGHT-1;
                             k = k + 1) begin

                            partial_pipe[r][k][0]
                                <= 16'h0000;

                            partial_pipe[r][k][1]
                                <= 16'h0000;

                            partial_pipe[r][k][2]
                                <= 16'h0000;

                            partial_pipe[r][k][3]
                                <= 16'h0000;
                        end

                        for (k = 0;
                             k < HEIGHT;
                             k = k + 1) begin

                            status_delay0[r][k]
                                <= 5'b00000;

                            status_delay1[r][k]
                                <= 5'b00000;

                            status_o[r][k]
                                <= 5'b00000;
                        end
                    end

                    // A1/C1:
                    // Ordinary state advances only on an enabled tick.
                    else if (reg_enable_i) begin

                        // -------------------------------------------------
                        // Four-enabled-tick stage-to-stage result spacing.
                        // -------------------------------------------------

                        for (k = 0;
                             k < HEIGHT-1;
                             k = k + 1) begin

                            partial_pipe[r][k][0]
                                <= fma_calc[r][k][15:0];

                            partial_pipe[r][k][1]
                                <= partial_pipe[r][k][0];

                            partial_pipe[r][k][2]
                                <= partial_pipe[r][k][1];

                            partial_pipe[r][k][3]
                                <= partial_pipe[r][k][2];
                        end

                        // -------------------------------------------------
                        // A10:
                        // status_o[r][k](t) reports the operation whose
                        // operands were sampled two enabled ticks earlier.
                        // -------------------------------------------------

                        for (k = 0;
                             k < HEIGHT;
                             k = k + 1) begin

                            status_delay0[r][k]
                                <= fma_calc[r][k][20:16];

                            status_delay1[r][k]
                                <= status_delay0[r][k];

                            status_o[r][k]
                                <= status_delay1[r][k];
                        end

                        // -------------------------------------------------
                        // Final-stage result delay.
                        //
                        // After edge t:
                        //   z_delay0 = final FMA(t)
                        //   z_delay1 = final FMA(t-1)
                        //   z_o      = final FMA(t-2)
                        //
                        // Therefore the final stage has d(H-1)=2.
                        // Combined with the four-tick stage spacing:
                        //
                        //   d(k) = 4*(HEIGHT-1-k) + 2.
                        // -------------------------------------------------

                        z_delay0[r]
                            <= fma_calc
                                [r]
                                [HEIGHT-1]
                                [15:0];

                        z_delay1[r]
                            <= z_delay0[r];

                        z_o[r]
                            <= z_delay1[r];
                    end

                    // reg_enable_i == 0:
                    // hold all state in this row.
                end

                // row_clk_gate_en_i[r] == 0:
                // hold all state in this row.
            end
        end
    end

endmodule