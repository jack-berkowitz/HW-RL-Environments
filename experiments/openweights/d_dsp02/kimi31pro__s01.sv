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

    // Return the position of the most-significant set bit.  The caller only
    // uses this for nonzero operands.
    function automatic integer msb96(input logic [95:0] x);
        integer i;
        begin
            msb96 = 0;
            for (i = 0; i < 96; i = i + 1) begin
                if (x[i])
                    msb96 = i;
            end
        end
    endfunction

    // The product is supplied by the first pipeline stage.  The finite
    // datapath uses a 96-bit fixed-point significand with 47 bits below the
    // unaligned product/addend.  Bits shifted below that window are collapsed
    // into a sticky bit.
    function automatic logic [35:0] fma_calc(
        input logic [31:0] fa,
        input logic [31:0] fb,
        input logic [31:0] fc,
        input logic [2:0]  mode,
        input logic [47:0] mp
    );
        logic a_nan, b_nan, c_nan;
        logic a_snan, b_snan, c_snan;
        logic a_inf, b_inf, c_inf;
        logic a_zero, b_zero;
        logic sp, sc;
        logic prod_inf, zero_inf;

        logic [23:0] mc;
        integer qa, qb, qc, qp, qmax;
        integer d, n, elow, elead, r, ebi;

        logic [95:0] p_ext, c_ext;
        logic [95:0] p_al, c_al, mag;
        logic pst, cst, sticky;
        logic p_big, sign;

        logic [24:0] q, qr;
        logic guard, st, inc, nx;
        logic [95:0] mask, shifted;
        logic to_inf;

        logic [31:0] res;
        logic inv, ovf, uf;

        begin
            res = 32'd0;
            inv = 1'b0;
            ovf = 1'b0;
            uf  = 1'b0;
            nx  = 1'b0;

            sp = fa[31] ^ fb[31];
            sc = fc[31];

            a_nan = (fa[30:23] == 8'hff) && (fa[22:0] != 0);
            b_nan = (fb[30:23] == 8'hff) && (fb[22:0] != 0);
            c_nan = (fc[30:23] == 8'hff) && (fc[22:0] != 0);

            a_snan = a_nan && !fa[22];
            b_snan = b_nan && !fb[22];
            c_snan = c_nan && !fc[22];

            a_inf = (fa[30:23] == 8'hff) && (fa[22:0] == 0);
            b_inf = (fb[30:23] == 8'hff) && (fb[22:0] == 0);
            c_inf = (fc[30:23] == 8'hff) && (fc[22:0] == 0);

            a_zero = (fa[30:23] == 0) && (fa[22:0] == 0);
            b_zero = (fb[30:23] == 0) && (fb[22:0] == 0);

            zero_inf = (a_inf && b_zero) || (b_inf && a_zero);
            prod_inf = (a_inf && !b_zero && !b_nan) ||
                       (b_inf && !a_zero && !a_nan);

            inv = a_snan || b_snan || c_snan || zero_inf ||
                  (prod_inf && c_inf && (sp != sc));

            if (a_nan || b_nan || c_nan || inv) begin
                res = 32'h7fc00000;
            end else if (prod_inf || c_inf) begin
                res = {prod_inf ? sp : sc, 8'hff, 23'd0};
            end else begin
                mc = (fc[30:23] == 0) ?
                     {1'b0, fc[22:0]} : {1'b1, fc[22:0]};

                if (mp == 0) begin
                    // A zero product plus a nonzero finite addend is exact.
                    if (mc != 0) begin
                        res = fc;
                    end else if (sp == sc) begin
                        res = {sp, 31'd0};
                    end else begin
                        res = {(mode == 3'd2), 31'd0};
                    end
                end else begin
                    // A finite value is significand * 2^q.  For normals,
                    // q = biased_exponent - 150; for subnormals q = -149.
                    qa = fa[30:23];
                    if (fa[30:23] == 0)
                        qa = -149;
                    else
                        qa = qa - 150;

                    qb = fb[30:23];
                    if (fb[30:23] == 0)
                        qb = -149;
                    else
                        qb = qb - 150;

                    qc = fc[30:23];
                    if (fc[30:23] == 0)
                        qc = -149;
                    else
                        qc = qc - 150;

                    qp = qa + qb;

                    p_ext = {48'd0, mp} << 47;
                    c_ext = {72'd0, mc} << 47;

                    p_al = p_ext;
                    c_al = c_ext;
                    pst  = 1'b0;
                    cst  = 1'b0;

                    if (mc == 0) begin
                        qmax = qp;
                    end else if (qp >= qc) begin
                        qmax = qp;
                        d = qp - qc;
                        if (d != 0) begin
                            if (d < 96) begin
                                c_al = c_ext >> d;
                                cst  = |(c_ext << (96 - d));
                            end else begin
                                c_al = 96'd0;
                                cst  = |c_ext;
                            end
                        end
                    end else begin
                        qmax = qc;
                        d = qc - qp;
                        if (d < 96) begin
                            p_al = p_ext >> d;
                            pst  = |(p_ext << (96 - d));
                        end else begin
                            p_al = 96'd0;
                            pst  = |p_ext;
                        end
                    end

                    if ((sp != sc) && (p_al == c_al) && !pst && !cst) begin
                        // Exact cancellation of nonzero opposite-sign terms.
                        res = {(mode == 3'd2), 31'd0};
                    end else begin
                        sticky = pst || cst;

                        if (sp == sc) begin
                            sign = sp;
                            mag  = p_al + c_al;
                        end else begin
                            if (p_al > c_al)
                                p_big = 1'b1;
                            else if (p_al < c_al)
                                p_big = 1'b0;
                            else
                                p_big = pst;

                            if (p_big) begin
                                sign = sp;
                                // If the subtrahend had discarded bits, subtract
                                // one at bit zero and retain a nonzero fractional
                                // tail: A-(B+f) = (A-B-1)+(1-f).
                                if (cst)
                                    mag = p_al - c_al - 96'd1;
                                else
                                    mag = p_al - c_al;
                            end else begin
                                sign = sc;
                                if (pst)
                                    mag = c_al - p_al - 96'd1;
                                else
                                    mag = c_al - p_al;
                            end
                        end

                        n     = msb96(mag);
                        elow  = qmax - 47;
                        elead = elow + n;

                        if (elead >= -126)
                            r = n - 23;
                        else
                            r = -149 - elow;

                        q       = 25'd0;
                        guard   = 1'b0;
                        st      = sticky;
                        mask    = 96'd0;
                        shifted = 96'd0;

                        if (r <= 0) begin
                            shifted = mag << (-r);
                            q = shifted[24:0];
                        end else if (r < 96) begin
                            shifted = mag >> r;
                            q = shifted[24:0];
                            guard = mag[r-1];
                            if (r > 1) begin
                                mask = (96'h1 << (r-1)) - 96'h1;
                                st = sticky || (|(mag & mask));
                            end
                        end else if (r == 96) begin
                            q = 25'd0;
                            guard = mag[95];
                            st = sticky || (|mag[94:0]);
                        end else begin
                            q = 25'd0;
                            guard = 1'b0;
                            st = sticky || (|mag);
                        end

                        nx = guard || st;
                        inc = 1'b0;

                        case (mode)
                            3'd0: inc = guard && (st || q[0]); // RNE
                            3'd1: inc = 1'b0;                  // RTZ
                            3'd2: inc = sign && nx;            // RDN
                            3'd3: inc = !sign && nx;           // RUP
                            3'd4: inc = guard;                 // RMM
                            default: inc = 1'b0;
                        endcase

                        qr = q + {24'd0, inc};

                        if (elead >= -126) begin
                            ebi = elead + 127;
                            if (qr[24])
                                ebi = ebi + 1;

                            if (ebi >= 255) begin
                                to_inf = (mode == 3'd0) || (mode == 3'd4) ||
                                         ((mode == 3'd3) && !sign) ||
                                         ((mode == 3'd2) && sign);
                                if (to_inf)
                                    res = {sign, 8'hff, 23'd0};
                                else
                                    res = {sign, 8'hfe, 23'h7fffff};
                                ovf = 1'b1;
                                nx  = 1'b1;
                            end else begin
                                res = {sign, ebi[7:0], qr[22:0]};
                            end
                        end else begin
                            // Rounding a tiny value to the smallest normal
                            // delivers exponent field one and therefore does
                            // not raise underflow under the specified rule.
                            if (qr[23]) begin
                                res = {sign, 8'd1, 23'd0};
                                uf  = 1'b0;
                            end else begin
                                res = {sign, 8'd0, qr[22:0]};
                                uf  = nx;
                            end
                        end
                    end
                end
            end

            fma_calc = {inv, ovf, uf, nx, res};
        end
    endfunction

    logic [23:0] mul_ma, mul_mb;
    logic [47:0] mul_mp;

    assign mul_ma = (a[30:23] == 0) ?
                    {1'b0, a[22:0]} : {1'b1, a[22:0]};
    assign mul_mb = (b[30:23] == 0) ?
                    {1'b0, b[22:0]} : {1'b1, b[22:0]};
    assign mul_mp = {24'd0, mul_ma} * {24'd0, mul_mb};

    logic [31:0] a_q, b_q, c_q;
    logic [2:0]  mode_q;
    logic [47:0] mp_q;
    logic [35:0] eval_s2;
    logic [35:0] data_s2, data_s3;
    logic        valid_s1, valid_s2, valid_s3;
    logic        advance;

    assign eval_s2 = fma_calc(a_q, b_q, c_q, mode_q, mp_q);

    // A full output register stops the whole three-entry pipeline.  Thus an
    // offered result can never be withdrawn or altered under backpressure.
    assign advance  = !valid_s3 || out_ready;
    assign in_ready = rst_n && advance;
    assign out_valid = rst_n && valid_s3;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            valid_s1 <= 1'b0;
            valid_s2 <= 1'b0;
            valid_s3 <= 1'b0;
            a_q      <= 32'd0;
            b_q      <= 32'd0;
            c_q      <= 32'd0;
            mode_q   <= 3'd0;
            mp_q     <= 48'd0;
            data_s2  <= 36'd0;
            data_s3  <= 36'd0;
        end else if (advance) begin
            valid_s1 <= in_valid;
            valid_s2 <= valid_s1;
            valid_s3 <= valid_s2;

            a_q    <= a;
            b_q    <= b;
            c_q    <= c;
            mode_q <= rnd_mode;
            mp_q   <= mul_mp;

            data_s2 <= eval_s2;
            data_s3 <= data_s2;
        end
    end

    assign result         = data_s3[31:0];
    assign flag_inexact   = data_s3[32];
    assign flag_underflow = data_s3[33];
    assign flag_overflow  = data_s3[34];
    assign flag_invalid   = data_s3[35];

endmodule
