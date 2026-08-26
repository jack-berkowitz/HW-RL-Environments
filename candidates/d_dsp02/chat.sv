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

    localparam int IW  = 96;
    localparam int TOP = 94;

    typedef struct packed {
        logic               special;
        logic [31:0]        special_result;
        logic               invalid;
        logic [2:0]         rm;
        logic               sp;
        logic               sc;
        logic [47:0]        prod_sig;
        logic [23:0]        c_sig;
        logic signed [11:0] exp_p;
        logic signed [11:0] exp_c;
        logic signed [11:0] top_p;
        logic signed [11:0] top_c;
        logic               prod_zero;
        logic               c_zero;
    } stage0_t;

    typedef struct packed {
        logic               special;
        logic [31:0]        special_result;
        logic               invalid;
        logic [2:0]         rm;
        logic               sr;
        logic               exact_zero;
        logic [95:0]        mag;
        logic               tail;
        logic signed [11:0] common_top;
    } stage1_t;

    typedef struct packed {
        logic               special;
        logic [31:0]        special_result;
        logic               invalid;
        logic [2:0]         rm;
        logic               sr;
        logic               exact_zero;
        logic               tail_only;
        logic               normal_path;
        logic signed [11:0] etop;
        logic [23:0]        q;
        logic               guard_bit;
        logic               lower_nonzero;
        logic               rem_nonzero;
    } stage2_t;

    typedef struct packed {
        logic [31:0] result;
        logic        invalid;
        logic        overflow;
        logic        underflow;
        logic        inexact;
    } stage3_t;

    stage0_t s0_q;
    stage1_t s1_q;
    stage2_t s2_q;
    stage3_t s3_q;

    logic s0_valid_q;
    logic s1_valid_q;
    logic s2_valid_q;
    logic s3_valid_q;

    logic s3_ready_c;
    logic s2_ready_c;
    logic s1_ready_c;
    logic s0_ready_c;

    function automatic integer msb24(input logic [23:0] v);
        integer i;
        begin
            msb24 = -1;
            for (i = 0; i < 24; i = i + 1) begin
                if (v[i]) begin
                    msb24 = i;
                end
            end
        end
    endfunction

    function automatic integer msb48(input logic [47:0] v);
        integer i;
        begin
            msb48 = -1;
            for (i = 0; i < 48; i = i + 1) begin
                if (v[i]) begin
                    msb48 = i;
                end
            end
        end
    endfunction

    function automatic integer msb96(input logic [95:0] v);
        integer i;
        begin
            msb96 = -1;
            for (i = 0; i < 96; i = i + 1) begin
                if (v[i]) begin
                    msb96 = i;
                end
            end
        end
    endfunction

    function automatic logic any_low48(
        input logic [47:0] v,
        input integer      count
    );
        integer i;
        begin
            any_low48 = 1'b0;
            for (i = 0; i < 48; i = i + 1) begin
                if ((i < count) && v[i]) begin
                    any_low48 = 1'b1;
                end
            end
        end
    endfunction

    function automatic logic any_low96(
        input logic [95:0] v,
        input integer      count
    );
        integer i;
        begin
            any_low96 = 1'b0;
            for (i = 0; i < 96; i = i + 1) begin
                if ((i < count) && v[i]) begin
                    any_low96 = 1'b1;
                end
            end
        end
    endfunction

    function automatic logic [95:0] align48_to96(
        input logic [47:0] sig,
        input integer      base_exp,
        input integer      common_top
    );
        integer sh;
        logic [95:0] ext;
        begin
            ext = {48'b0, sig};
            sh = TOP + base_exp - common_top;

            if (sh >= 0) begin
                if (sh >= 96) begin
                    align48_to96 = 96'b0;
                end
                else begin
                    align48_to96 = ext << sh;
                end
            end
            else begin
                sh = -sh;
                if (sh >= 96) begin
                    align48_to96 = 96'b0;
                end
                else begin
                    align48_to96 = ext >> sh;
                end
            end
        end
    endfunction

    function automatic logic align48_disc(
        input logic [47:0] sig,
        input integer      base_exp,
        input integer      common_top
    );
        integer sh;
        begin
            sh = TOP + base_exp - common_top;
            align48_disc = 1'b0;

            if (sh < 0) begin
                sh = -sh;
                if (sh >= 48) begin
                    align48_disc = |sig;
                end
                else begin
                    align48_disc = any_low48(sig, sh);
                end
            end
        end
    endfunction

    function automatic stage0_t make_stage0(
        input logic [31:0] aa,
        input logic [31:0] bb,
        input logic [31:0] cc,
        input logic [2:0]  rm
    );
        stage0_t t;

        logic sa;
        logic sb;
        logic sc;
        logic sp;
        logic [7:0] ea;
        logic [7:0] eb;
        logic [7:0] ec;
        logic [22:0] fa;
        logic [22:0] fb;
        logic [22:0] fc;
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
        logic invalid_mul;
        logic product_inf;
        logic invalid_add;
        logic [23:0] sig_a;
        logic [23:0] sig_b;
        logic [23:0] sig_c;
        logic [47:0] prod;
        integer exp_a_i;
        integer exp_b_i;
        integer exp_c_i;
        integer exp_p_i;
        integer mp;
        integer mc;

        begin
            t = '0;

            sa = aa[31];
            sb = bb[31];
            sc = cc[31];
            sp = sa ^ sb;

            ea = aa[30:23];
            eb = bb[30:23];
            ec = cc[30:23];
            fa = aa[22:0];
            fb = bb[22:0];
            fc = cc[22:0];

            a_nan = (ea == 8'hff) && (fa != 23'b0);
            b_nan = (eb == 8'hff) && (fb != 23'b0);
            c_nan = (ec == 8'hff) && (fc != 23'b0);

            a_snan = a_nan && !fa[22];
            b_snan = b_nan && !fb[22];
            c_snan = c_nan && !fc[22];

            a_inf = (ea == 8'hff) && (fa == 23'b0);
            b_inf = (eb == 8'hff) && (fb == 23'b0);
            c_inf = (ec == 8'hff) && (fc == 23'b0);

            a_zero = (ea == 8'b0) && (fa == 23'b0);
            b_zero = (eb == 8'b0) && (fb == 23'b0);

            invalid_mul = (a_inf && b_zero) || (b_inf && a_zero);
            product_inf = (a_inf || b_inf) && !invalid_mul && !a_nan && !b_nan;
            invalid_add = product_inf && c_inf && (sp != sc);

            t.invalid = a_snan || b_snan || c_snan || invalid_mul || invalid_add;
            t.rm = rm;
            t.sp = sp;
            t.sc = sc;

            if (a_nan || b_nan || c_nan || invalid_mul || invalid_add) begin
                t.special = 1'b1;
                t.special_result = 32'h7fc00000;
            end
            else if (product_inf) begin
                t.special = 1'b1;
                t.special_result = {sp, 8'hff, 23'b0};
            end
            else if (c_inf) begin
                t.special = 1'b1;
                t.special_result = {sc, 8'hff, 23'b0};
            end
            else begin
                t.special = 1'b0;

                if (ea == 8'b0) begin
                    sig_a = {1'b0, fa};
                    exp_a_i = -149;
                end
                else begin
                    sig_a = {1'b1, fa};
                    exp_a_i = ea - 150;
                end

                if (eb == 8'b0) begin
                    sig_b = {1'b0, fb};
                    exp_b_i = -149;
                end
                else begin
                    sig_b = {1'b1, fb};
                    exp_b_i = eb - 150;
                end

                if (ec == 8'b0) begin
                    sig_c = {1'b0, fc};
                    exp_c_i = -149;
                end
                else begin
                    sig_c = {1'b1, fc};
                    exp_c_i = ec - 150;
                end

                prod = sig_a * sig_b;
                exp_p_i = exp_a_i + exp_b_i;
                mp = msb48(prod);
                mc = msb24(sig_c);

                t.prod_sig = prod;
                t.c_sig = sig_c;
                t.exp_p = exp_p_i;
                t.exp_c = exp_c_i;
                t.prod_zero = (mp < 0);
                t.c_zero = (mc < 0);

                if (mp < 0) begin
                    t.top_p = -12'sd1024;
                end
                else begin
                    t.top_p = exp_p_i + mp;
                end

                if (mc < 0) begin
                    t.top_c = -12'sd1024;
                end
                else begin
                    t.top_c = exp_c_i + mc;
                end
            end

            make_stage0 = t;
        end
    endfunction

    function automatic stage1_t make_stage1(input stage0_t x);
        stage1_t t;
        logic [47:0] c_sig48;
        logic [95:0] p_al;
        logic [95:0] c_al;
        logic p_disc;
        logic c_disc;
        integer common_i;

        begin
            t = '0;
            t.special = x.special;
            t.special_result = x.special_result;
            t.invalid = x.invalid;
            t.rm = x.rm;

            if (x.special) begin
                t.sr = x.special_result[31];
            end
            else if (x.prod_zero && x.c_zero) begin
                t.exact_zero = 1'b1;
                if (x.sp == x.sc) begin
                    t.sr = x.sp;
                end
                else begin
                    t.sr = (x.rm == 3'd2);
                end
            end
            else begin
                if ($signed(x.top_p) >= $signed(x.top_c)) begin
                    common_i = $signed(x.top_p);
                end
                else begin
                    common_i = $signed(x.top_c);
                end

                t.common_top = common_i;
                c_sig48 = {24'b0, x.c_sig};

                p_al = align48_to96(x.prod_sig, $signed(x.exp_p), common_i);
                c_al = align48_to96(c_sig48, $signed(x.exp_c), common_i);
                p_disc = align48_disc(x.prod_sig, $signed(x.exp_p), common_i);
                c_disc = align48_disc(c_sig48, $signed(x.exp_c), common_i);

                if (x.prod_zero) begin
                    t.mag = c_al;
                    t.tail = c_disc;
                    t.sr = x.sc;
                end
                else if (x.c_zero) begin
                    t.mag = p_al;
                    t.tail = p_disc;
                    t.sr = x.sp;
                end
                else if (x.sp == x.sc) begin
                    t.mag = p_al + c_al;
                    t.tail = p_disc || c_disc;
                    t.sr = x.sp;
                end
                else if (p_al > c_al) begin
                    t.mag = p_al - c_al;
                    t.sr = x.sp;
                    if (c_disc && !p_disc) begin
                        t.mag = t.mag - 96'd1;
                        t.tail = 1'b1;
                    end
                    else begin
                        t.tail = p_disc || c_disc;
                    end
                end
                else if (c_al > p_al) begin
                    t.mag = c_al - p_al;
                    t.sr = x.sc;
                    if (p_disc && !c_disc) begin
                        t.mag = t.mag - 96'd1;
                        t.tail = 1'b1;
                    end
                    else begin
                        t.tail = p_disc || c_disc;
                    end
                end
                else begin
                    if (!p_disc && !c_disc) begin
                        t.exact_zero = 1'b1;
                        t.sr = (x.rm == 3'd2);
                    end
                    else if (p_disc && !c_disc) begin
                        t.mag = 96'b0;
                        t.tail = 1'b1;
                        t.sr = x.sp;
                    end
                    else if (c_disc && !p_disc) begin
                        t.mag = 96'b0;
                        t.tail = 1'b1;
                        t.sr = x.sc;
                    end
                    else begin
                        t.mag = 96'b0;
                        t.tail = 1'b1;
                        t.sr = (x.rm == 3'd2);
                    end
                end
            end

            make_stage1 = t;
        end
    endfunction

    function automatic stage2_t make_stage2(input stage1_t x);
        stage2_t t;
        logic [95:0] trunc96;
        integer m;
        integer base_i;
        integer etop_i;
        integer sh;

        begin
            t = '0;
            t.special = x.special;
            t.special_result = x.special_result;
            t.invalid = x.invalid;
            t.rm = x.rm;
            t.sr = x.sr;
            t.exact_zero = x.exact_zero;

            if (!x.special && !x.exact_zero) begin
                m = msb96(x.mag);

                if (m < 0) begin
                    t.tail_only = x.tail;
                end
                else begin
                    base_i = $signed(x.common_top) - TOP;
                    etop_i = base_i + m;
                    t.etop = etop_i;

                    if (etop_i >= -126) begin
                        t.normal_path = 1'b1;
                        sh = m - 23;

                        if (sh <= 0) begin
                            if (sh == 0) begin
                                t.q = x.mag[23:0];
                            end
                            else begin
                                t.q = x.mag << (-sh);
                            end
                            t.guard_bit = 1'b0;
                            t.lower_nonzero = x.tail;
                            t.rem_nonzero = x.tail;
                        end
                        else begin
                            trunc96 = x.mag >> sh;
                            t.q = trunc96[23:0];

                            if ((sh - 1) < 96) begin
                                t.guard_bit = x.mag[sh-1];
                            end

                            if (sh <= 1) begin
                                t.lower_nonzero = x.tail;
                            end
                            else if ((sh - 1) >= 96) begin
                                t.lower_nonzero = (|x.mag) || x.tail;
                            end
                            else begin
                                t.lower_nonzero = any_low96(x.mag, sh-1) || x.tail;
                            end

                            t.rem_nonzero = t.guard_bit || t.lower_nonzero;
                        end
                    end
                    else begin
                        t.normal_path = 1'b0;
                        sh = -149 - base_i;

                        if (sh <= 0) begin
                            t.q = x.mag << (-sh);
                            t.guard_bit = 1'b0;
                            t.lower_nonzero = x.tail;
                            t.rem_nonzero = x.tail;
                        end
                        else if (sh < 96) begin
                            trunc96 = x.mag >> sh;
                            t.q = trunc96[23:0];
                            t.guard_bit = x.mag[sh-1];

                            if (sh <= 1) begin
                                t.lower_nonzero = x.tail;
                            end
                            else begin
                                t.lower_nonzero = any_low96(x.mag, sh-1) || x.tail;
                            end

                            t.rem_nonzero = t.guard_bit || t.lower_nonzero;
                        end
                        else if (sh == 96) begin
                            t.q = 24'b0;
                            t.guard_bit = x.mag[95];
                            t.lower_nonzero = any_low96(x.mag, 95) || x.tail;
                            t.rem_nonzero = t.guard_bit || t.lower_nonzero;
                        end
                        else begin
                            t.q = 24'b0;
                            t.guard_bit = 1'b0;
                            t.lower_nonzero = (|x.mag) || x.tail;
                            t.rem_nonzero = t.lower_nonzero;
                        end
                    end
                end
            end

            make_stage2 = t;
        end
    endfunction

    function automatic stage3_t make_stage3(input stage2_t x);
        stage3_t t;
        logic round_inc;
        logic overflow_to_inf;
        logic [24:0] qext;
        logic [23:0] qround;
        integer etop_i;
        integer biased_i;

        begin
            t = '0;
            t.invalid = x.invalid;

            if (x.special) begin
                t.result = x.special_result;
            end
            else if (x.exact_zero) begin
                t.result = {x.sr, 31'b0};
            end
            else if (x.tail_only) begin
                t.result = {x.sr, 31'b0};
                t.inexact = 1'b1;
                t.underflow = 1'b1;
            end
            else begin
                round_inc = 1'b0;

                case (x.rm)
                    3'd0: round_inc = x.guard_bit &&
                                      (x.lower_nonzero || x.q[0]);
                    3'd1: round_inc = 1'b0;
                    3'd2: round_inc = x.sr && x.rem_nonzero;
                    3'd3: round_inc = (!x.sr) && x.rem_nonzero;
                    3'd4: round_inc = x.guard_bit;
                    default: round_inc = 1'b0;
                endcase

                qext = {1'b0, x.q} +
                       {{24{1'b0}}, round_inc};

                t.inexact = x.rem_nonzero;

                if (x.normal_path) begin
                    etop_i = $signed(x.etop);

                    if (qext[24]) begin
                        qround = qext[24:1];
                        etop_i = etop_i + 1;
                    end
                    else begin
                        qround = qext[23:0];
                    end

                    if (etop_i > 127) begin
                        t.overflow = 1'b1;
                        t.inexact = 1'b1;

                        overflow_to_inf = 1'b0;

                        case (x.rm)
                            3'd0: overflow_to_inf = 1'b1;
                            3'd1: overflow_to_inf = 1'b0;
                            3'd2: overflow_to_inf = x.sr;
                            3'd3: overflow_to_inf = !x.sr;
                            3'd4: overflow_to_inf = 1'b1;
                            default: overflow_to_inf = 1'b1;
                        endcase

                        if (overflow_to_inf) begin
                            t.result = {
                                x.sr,
                                8'hff,
                                23'b0
                            };
                        end
                        else begin
                            t.result = {
                                x.sr,
                                8'hfe,
                                23'h7fffff
                            };
                        end
                    end
                    else begin
                        biased_i = etop_i + 127;

                        t.result = {
                            x.sr,
                            biased_i[7:0],
                            qround[22:0]
                        };
                    end
                end
                else begin
                    qround = qext[23:0];

                    if (qext[23]) begin
                        t.result = {
                            x.sr,
                            8'h01,
                            23'b0
                        };
                    end
                    else begin
                        t.result = {
                            x.sr,
                            8'h00,
                            qround[22:0]
                        };
                    end

                    t.underflow =
                        t.inexact &&
                        (t.result[30:23] == 8'h00);
                end
            end

            make_stage3 = t;
        end
    endfunction

    always_comb begin
        s3_ready_c = (!s3_valid_q) || out_ready;
        s2_ready_c = (!s2_valid_q) || s3_ready_c;
        s1_ready_c = (!s1_valid_q) || s2_ready_c;
        s0_ready_c = (!s0_valid_q) || s1_ready_c;

        in_ready = rst_n && s0_ready_c;

        out_valid = rst_n && s3_valid_q;
        result = s3_q.result;

        flag_invalid = s3_q.invalid;
        flag_overflow = s3_q.overflow;
        flag_underflow = s3_q.underflow;
        flag_inexact = s3_q.inexact;
    end

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            s0_valid_q <= 1'b0;
            s1_valid_q <= 1'b0;
            s2_valid_q <= 1'b0;
            s3_valid_q <= 1'b0;

            s0_q <= '0;
            s1_q <= '0;
            s2_q <= '0;
            s3_q <= '0;
        end
        else begin
            if (s3_ready_c) begin
                s3_valid_q <= s2_valid_q;

                if (s2_valid_q) begin
                    s3_q <= make_stage3(s2_q);
                end
            end

            if (s2_ready_c) begin
                s2_valid_q <= s1_valid_q;

                if (s1_valid_q) begin
                    s2_q <= make_stage2(s1_q);
                end
            end

            if (s1_ready_c) begin
                s1_valid_q <= s0_valid_q;

                if (s0_valid_q) begin
                    s1_q <= make_stage1(s0_q);
                end
            end

            if (s0_ready_c) begin
                s0_valid_q <= in_valid;

                if (in_valid) begin
                    s0_q <= make_stage0(
                        a,
                        b,
                        c,
                        rnd_mode
                    );
                end
            end
        end
    end

endmodule