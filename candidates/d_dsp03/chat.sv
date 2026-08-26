module fp_multifmt_fma #(
  parameter int unsigned WIDTH = 64
) (
  input  logic             clk_i,
  input  logic             rst_ni,

  input  logic             in_valid_i,
  output logic             in_ready_o,
  input  logic [1:0]       fmt_i,
  input  logic             vec_i,
  input  logic [WIDTH-1:0] a_i,
  input  logic [WIDTH-1:0] b_i,
  input  logic [WIDTH-1:0] c_i,
  input  logic [2:0]       rnd_i,

  output logic             out_valid_o,
  input  logic             out_ready_i,
  output logic [WIDTH-1:0] result_o,
  output logic [4:0]       flags_o
);


function automatic logic [36:0] fp32_calc(
    input logic [31:0] aa,
    input logic [31:0] bb,
    input logic [31:0] cc,
    input logic [2:0]       rm
);
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
    logic c_zero;
    logic invalid_mul;
    logic product_inf;
    logic invalid_add;
    logic nan_result;
    logic [23:0] sig_a;
    logic [23:0] sig_b;
    logic [23:0] sig_c;
    logic [47:0] prod_sig;
    logic [95:0] p_ext;
    logic [95:0] c_ext;
    logic [95:0] p_al;
    logic [95:0] c_al;
    logic [95:0] mag;
    logic p_disc;
    logic c_disc;
    logic tail;
    logic sr;
    logic exact_zero;
    logic [23:0] q;
    logic [24:0] qext;
    logic [23:0] qround;
    logic guard_bit;
    logic lower_nonzero;
    logic rem_nonzero;
    logic round_inc;
    logic overflow_to_inf;
    logic [31:0] res;
    logic [4:0] flags;
    integer exp_a;
    integer exp_b;
    integer exp_c;
    integer exp_p;
    integer mp;
    integer mc;
    integer common_top;
    integer base_exp;
    integer m;
    integer etop;
    integer biased;
    integer sh;
    integer rsh;
    integer i;

    begin
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

        a_nan = (ea == {8{1'b1}}) && (fa != '0);
        b_nan = (eb == {8{1'b1}}) && (fb != '0);
        c_nan = (ec == {8{1'b1}}) && (fc != '0);

        a_snan = a_nan && !fa[22];
        b_snan = b_nan && !fb[22];
        c_snan = c_nan && !fc[22];

        a_inf = (ea == {8{1'b1}}) && (fa == '0);
        b_inf = (eb == {8{1'b1}}) && (fb == '0);
        c_inf = (ec == {8{1'b1}}) && (fc == '0);

        a_zero = (ea == '0) && (fa == '0);
        b_zero = (eb == '0) && (fb == '0);
        c_zero = (ec == '0) && (fc == '0);

        invalid_mul = (a_inf && b_zero) || (b_inf && a_zero);
        product_inf = (a_inf || b_inf) &&
                      !a_nan && !b_nan &&
                      !invalid_mul;
        invalid_add = product_inf && c_inf && (sp != sc);

        nan_result = a_nan || b_nan || c_nan ||
                     invalid_mul || invalid_add;

        flags = 5'b0;
        flags[4] = a_snan || b_snan || c_snan ||
                   invalid_mul || invalid_add;
        res = '0;

        if (nan_result) begin
            res = 32'h7fc00000;
        end
        else if (product_inf) begin
            res = {sp, {8{1'b1}}, {23{1'b0}}};
        end
        else if (c_inf) begin
            res = {sc, {8{1'b1}}, {23{1'b0}}};
        end
        else begin
            if (ea == '0) begin
                sig_a = {1'b0, fa};
                exp_a = -149;
            end
            else begin
                sig_a = {1'b1, fa};
                exp_a = $unsigned(ea) - 127 - 23;
            end

            if (eb == '0) begin
                sig_b = {1'b0, fb};
                exp_b = -149;
            end
            else begin
                sig_b = {1'b1, fb};
                exp_b = $unsigned(eb) - 127 - 23;
            end

            if (ec == '0) begin
                sig_c = {1'b0, fc};
                exp_c = -149;
            end
            else begin
                sig_c = {1'b1, fc};
                exp_c = $unsigned(ec) - 127 - 23;
            end

            prod_sig = sig_a * sig_b;
            exp_p = exp_a + exp_b;

            mp = -1;
            for (i = 0; i < 48; i = i + 1) begin
                if (prod_sig[i]) begin
                    mp = i;
                end
            end

            mc = -1;
            for (i = 0; i < 24; i = i + 1) begin
                if (sig_c[i]) begin
                    mc = i;
                end
            end

            exact_zero = 1'b0;
            tail = 1'b0;
            sr = 1'b0;
            mag = '0;

            if ((mp < 0) && (mc < 0)) begin
                exact_zero = 1'b1;
                if (sp == sc) begin
                    sr = sp;
                end
                else begin
                    sr = (rm == 3'd2);
                end
            end
            else begin
                if (mp < 0) begin
                    common_top = exp_c + mc;
                end
                else if (mc < 0) begin
                    common_top = exp_p + mp;
                end
                else if ((exp_p + mp) >= (exp_c + mc)) begin
                    common_top = exp_p + mp;
                end
                else begin
                    common_top = exp_c + mc;
                end

                p_ext = '0;
                c_ext = '0;
                p_ext[47:0] = prod_sig;
                c_ext[23:0] = sig_c;

                p_al = '0;
                c_al = '0;
                p_disc = 1'b0;
                c_disc = 1'b0;

                sh = 94 + exp_p - common_top;
                if (mp >= 0) begin
                    if (sh >= 0) begin
                        if (sh < 96) begin
                            p_al = p_ext << sh;
                        end
                    end
                    else begin
                        rsh = -sh;
                        if (rsh >= 96) begin
                            p_al = '0;
                            p_disc = |p_ext;
                        end
                        else begin
                            p_al = p_ext >> rsh;
                            for (i = 0; i < 96; i = i + 1) begin
                                if ((i < rsh) && p_ext[i]) begin
                                    p_disc = 1'b1;
                                end
                            end
                        end
                    end
                end

                sh = 94 + exp_c - common_top;
                if (mc >= 0) begin
                    if (sh >= 0) begin
                        if (sh < 96) begin
                            c_al = c_ext << sh;
                        end
                    end
                    else begin
                        rsh = -sh;
                        if (rsh >= 96) begin
                            c_al = '0;
                            c_disc = |c_ext;
                        end
                        else begin
                            c_al = c_ext >> rsh;
                            for (i = 0; i < 96; i = i + 1) begin
                                if ((i < rsh) && c_ext[i]) begin
                                    c_disc = 1'b1;
                                end
                            end
                        end
                    end
                end

                if (sp == sc) begin
                    mag = p_al + c_al;
                    tail = p_disc || c_disc;
                    sr = sp;
                end
                else if (p_al > c_al) begin
                    sr = sp;
                    if (c_disc && !p_disc) begin
                        mag = (p_al - c_al) -
                              {{(96-1){1'b0}}, 1'b1};
                        tail = 1'b1;
                    end
                    else begin
                        mag = p_al - c_al;
                        tail = p_disc || c_disc;
                    end
                end
                else if (c_al > p_al) begin
                    sr = sc;
                    if (p_disc && !c_disc) begin
                        mag = (c_al - p_al) -
                              {{(96-1){1'b0}}, 1'b1};
                        tail = 1'b1;
                    end
                    else begin
                        mag = c_al - p_al;
                        tail = p_disc || c_disc;
                    end
                end
                else if (!p_disc && !c_disc) begin
                    mag = '0;
                    tail = 1'b0;
                    exact_zero = 1'b1;
                    sr = (rm == 3'd2);
                end
                else if (p_disc && !c_disc) begin
                    mag = '0;
                    tail = 1'b1;
                    sr = sp;
                end
                else if (c_disc && !p_disc) begin
                    mag = '0;
                    tail = 1'b1;
                    sr = sc;
                end
                else begin
                    mag = '0;
                    tail = 1'b1;
                    sr = (rm == 3'd2);
                end

                if (!exact_zero) begin
                    base_exp = common_top - 94;

                    m = -1;
                    for (i = 0; i < 96; i = i + 1) begin
                        if (mag[i]) begin
                            m = i;
                        end
                    end

                    if (m < 0) begin
                        rem_nonzero = tail;
                        round_inc = 1'b0;
                        case (rm)
                            3'd2: round_inc = sr && rem_nonzero;
                            3'd3: round_inc = (!sr) && rem_nonzero;
                            default: round_inc = 1'b0;
                        endcase

                        if (round_inc) begin
                            res = {sr, {8{1'b0}},
                                   {(23-1){1'b0}}, 1'b1};
                        end
                        else begin
                            res = {sr, {(32-1){1'b0}}};
                        end

                        flags[0] = rem_nonzero;
                        flags[1] = rem_nonzero;
                    end
                    else begin
                        etop = base_exp + m;
                        q = '0;
                        guard_bit = 1'b0;
                        lower_nonzero = 1'b0;
                        rem_nonzero = 1'b0;

                        if (etop >= -126) begin
                            sh = m - 23;

                            if (sh <= 0) begin
                                q = mag << (-sh);
                                rem_nonzero = tail;
                            end
                            else begin
                                q = mag >> sh;
                                guard_bit = mag[sh-1];
                                lower_nonzero = tail;

                                if (sh > 1) begin
                                    for (i = 0; i < 96; i = i + 1) begin
                                        if ((i < (sh-1)) && mag[i]) begin
                                            lower_nonzero = 1'b1;
                                        end
                                    end
                                end

                                rem_nonzero =
                                    guard_bit || lower_nonzero;
                            end

                            round_inc = 1'b0;
                            case (rm)
                                3'd0: round_inc =
                                    guard_bit &&
                                    (lower_nonzero || q[0]);
                                3'd1: round_inc = 1'b0;
                                3'd2: round_inc = sr && rem_nonzero;
                                3'd3: round_inc = (!sr) && rem_nonzero;
                                3'd4: round_inc = guard_bit;
                                default: round_inc = 1'b0;
                            endcase

                            qext = {1'b0, q} +
                                   {{24{1'b0}}, round_inc};

                            if (qext[24]) begin
                                qround = qext[24:1];
                                etop = etop + 1;
                            end
                            else begin
                                qround = qext[23:0];
                            end

                            if (etop > 127) begin
                                flags[0] = 1'b1;
                                flags[2] = 1'b1;

                                overflow_to_inf = 1'b0;
                                case (rm)
                                    3'd0: overflow_to_inf = 1'b1;
                                    3'd1: overflow_to_inf = 1'b0;
                                    3'd2: overflow_to_inf = sr;
                                    3'd3: overflow_to_inf = !sr;
                                    3'd4: overflow_to_inf = 1'b1;
                                    default: overflow_to_inf = 1'b1;
                                endcase

                                if (overflow_to_inf) begin
                                    res = {sr, {8{1'b1}},
                                           {23{1'b0}}};
                                end
                                else begin
                                    res = {sr,
                                           {(8-1){1'b1}}, 1'b0,
                                           {23{1'b1}}};
                                end
                            end
                            else begin
                                biased = etop + 127;
                                res = {sr,
                                       biased[7:0],
                                       qround[22:0]};
                                flags[0] = rem_nonzero;
                            end
                        end
                        else begin
                            sh = -149 - base_exp;

                            if (sh <= 0) begin
                                q = mag << (-sh);
                                rem_nonzero = tail;
                            end
                            else if (sh < 96) begin
                                q = mag >> sh;
                                guard_bit = mag[sh-1];
                                lower_nonzero = tail;

                                if (sh > 1) begin
                                    for (i = 0; i < 96; i = i + 1) begin
                                        if ((i < (sh-1)) && mag[i]) begin
                                            lower_nonzero = 1'b1;
                                        end
                                    end
                                end

                                rem_nonzero =
                                    guard_bit || lower_nonzero;
                            end
                            else if (sh == 96) begin
                                q = '0;
                                guard_bit = mag[95];
                                lower_nonzero = tail;

                                for (i = 0; i < 95; i = i + 1) begin
                                    if (mag[i]) begin
                                        lower_nonzero = 1'b1;
                                    end
                                end

                                rem_nonzero =
                                    guard_bit || lower_nonzero;
                            end
                            else begin
                                q = '0;
                                guard_bit = 1'b0;
                                lower_nonzero = (|mag) || tail;
                                rem_nonzero = lower_nonzero;
                            end

                            round_inc = 1'b0;
                            case (rm)
                                3'd0: round_inc =
                                    guard_bit &&
                                    (lower_nonzero || q[0]);
                                3'd1: round_inc = 1'b0;
                                3'd2: round_inc = sr && rem_nonzero;
                                3'd3: round_inc = (!sr) && rem_nonzero;
                                3'd4: round_inc = guard_bit;
                                default: round_inc = 1'b0;
                            endcase

                            qext = {1'b0, q} +
                                   {{24{1'b0}}, round_inc};

                            if (qext[23]) begin
                                res = {sr,
                                       {(8-1){1'b0}}, 1'b1,
                                       {23{1'b0}}};
                            end
                            else begin
                                res = {sr,
                                       {8{1'b0}},
                                       qext[22:0]};
                            end

                            flags[0] = rem_nonzero;
                            flags[1] =
                                rem_nonzero &&
                                (res[30:23] == '0);
                        end
                    end
                end

                if (exact_zero) begin
                    res = {sr, {(32-1){1'b0}}};
                end
            end
        end

        fp32_calc = {flags, res};
    end
endfunction


function automatic logic [20:0] fp16_calc(
    input logic [15:0] aa,
    input logic [15:0] bb,
    input logic [15:0] cc,
    input logic [2:0]       rm
);
    logic sa;
    logic sb;
    logic sc;
    logic sp;
    logic [4:0] ea;
    logic [4:0] eb;
    logic [4:0] ec;
    logic [9:0] fa;
    logic [9:0] fb;
    logic [9:0] fc;
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
    logic invalid_mul;
    logic product_inf;
    logic invalid_add;
    logic nan_result;
    logic [10:0] sig_a;
    logic [10:0] sig_b;
    logic [10:0] sig_c;
    logic [21:0] prod_sig;
    logic [43:0] p_ext;
    logic [43:0] c_ext;
    logic [43:0] p_al;
    logic [43:0] c_al;
    logic [43:0] mag;
    logic p_disc;
    logic c_disc;
    logic tail;
    logic sr;
    logic exact_zero;
    logic [10:0] q;
    logic [11:0] qext;
    logic [10:0] qround;
    logic guard_bit;
    logic lower_nonzero;
    logic rem_nonzero;
    logic round_inc;
    logic overflow_to_inf;
    logic [15:0] res;
    logic [4:0] flags;
    integer exp_a;
    integer exp_b;
    integer exp_c;
    integer exp_p;
    integer mp;
    integer mc;
    integer common_top;
    integer base_exp;
    integer m;
    integer etop;
    integer biased;
    integer sh;
    integer rsh;
    integer i;

    begin
        sa = aa[15];
        sb = bb[15];
        sc = cc[15];
        sp = sa ^ sb;

        ea = aa[14:10];
        eb = bb[14:10];
        ec = cc[14:10];

        fa = aa[9:0];
        fb = bb[9:0];
        fc = cc[9:0];

        a_nan = (ea == {5{1'b1}}) && (fa != '0);
        b_nan = (eb == {5{1'b1}}) && (fb != '0);
        c_nan = (ec == {5{1'b1}}) && (fc != '0);

        a_snan = a_nan && !fa[9];
        b_snan = b_nan && !fb[9];
        c_snan = c_nan && !fc[9];

        a_inf = (ea == {5{1'b1}}) && (fa == '0);
        b_inf = (eb == {5{1'b1}}) && (fb == '0);
        c_inf = (ec == {5{1'b1}}) && (fc == '0);

        a_zero = (ea == '0) && (fa == '0);
        b_zero = (eb == '0) && (fb == '0);
        c_zero = (ec == '0) && (fc == '0);

        invalid_mul = (a_inf && b_zero) || (b_inf && a_zero);
        product_inf = (a_inf || b_inf) &&
                      !a_nan && !b_nan &&
                      !invalid_mul;
        invalid_add = product_inf && c_inf && (sp != sc);

        nan_result = a_nan || b_nan || c_nan ||
                     invalid_mul || invalid_add;

        flags = 5'b0;
        flags[4] = a_snan || b_snan || c_snan ||
                   invalid_mul || invalid_add;
        res = '0;

        if (nan_result) begin
            res = 16'h7e00;
        end
        else if (product_inf) begin
            res = {sp, {5{1'b1}}, {10{1'b0}}};
        end
        else if (c_inf) begin
            res = {sc, {5{1'b1}}, {10{1'b0}}};
        end
        else begin
            if (ea == '0) begin
                sig_a = {1'b0, fa};
                exp_a = -24;
            end
            else begin
                sig_a = {1'b1, fa};
                exp_a = $unsigned(ea) - 15 - 10;
            end

            if (eb == '0) begin
                sig_b = {1'b0, fb};
                exp_b = -24;
            end
            else begin
                sig_b = {1'b1, fb};
                exp_b = $unsigned(eb) - 15 - 10;
            end

            if (ec == '0) begin
                sig_c = {1'b0, fc};
                exp_c = -24;
            end
            else begin
                sig_c = {1'b1, fc};
                exp_c = $unsigned(ec) - 15 - 10;
            end

            prod_sig = sig_a * sig_b;
            exp_p = exp_a + exp_b;

            mp = -1;
            for (i = 0; i < 22; i = i + 1) begin
                if (prod_sig[i]) begin
                    mp = i;
                end
            end

            mc = -1;
            for (i = 0; i < 11; i = i + 1) begin
                if (sig_c[i]) begin
                    mc = i;
                end
            end

            exact_zero = 1'b0;
            tail = 1'b0;
            sr = 1'b0;
            mag = '0;

            if ((mp < 0) && (mc < 0)) begin
                exact_zero = 1'b1;
                if (sp == sc) begin
                    sr = sp;
                end
                else begin
                    sr = (rm == 3'd2);
                end
            end
            else begin
                if (mp < 0) begin
                    common_top = exp_c + mc;
                end
                else if (mc < 0) begin
                    common_top = exp_p + mp;
                end
                else if ((exp_p + mp) >= (exp_c + mc)) begin
                    common_top = exp_p + mp;
                end
                else begin
                    common_top = exp_c + mc;
                end

                p_ext = '0;
                c_ext = '0;
                p_ext[21:0] = prod_sig;
                c_ext[10:0] = sig_c;

                p_al = '0;
                c_al = '0;
                p_disc = 1'b0;
                c_disc = 1'b0;

                sh = 42 + exp_p - common_top;
                if (mp >= 0) begin
                    if (sh >= 0) begin
                        if (sh < 44) begin
                            p_al = p_ext << sh;
                        end
                    end
                    else begin
                        rsh = -sh;
                        if (rsh >= 44) begin
                            p_al = '0;
                            p_disc = |p_ext;
                        end
                        else begin
                            p_al = p_ext >> rsh;
                            for (i = 0; i < 44; i = i + 1) begin
                                if ((i < rsh) && p_ext[i]) begin
                                    p_disc = 1'b1;
                                end
                            end
                        end
                    end
                end

                sh = 42 + exp_c - common_top;
                if (mc >= 0) begin
                    if (sh >= 0) begin
                        if (sh < 44) begin
                            c_al = c_ext << sh;
                        end
                    end
                    else begin
                        rsh = -sh;
                        if (rsh >= 44) begin
                            c_al = '0;
                            c_disc = |c_ext;
                        end
                        else begin
                            c_al = c_ext >> rsh;
                            for (i = 0; i < 44; i = i + 1) begin
                                if ((i < rsh) && c_ext[i]) begin
                                    c_disc = 1'b1;
                                end
                            end
                        end
                    end
                end

                if (sp == sc) begin
                    mag = p_al + c_al;
                    tail = p_disc || c_disc;
                    sr = sp;
                end
                else if (p_al > c_al) begin
                    sr = sp;
                    if (c_disc && !p_disc) begin
                        mag = (p_al - c_al) -
                              {{(44-1){1'b0}}, 1'b1};
                        tail = 1'b1;
                    end
                    else begin
                        mag = p_al - c_al;
                        tail = p_disc || c_disc;
                    end
                end
                else if (c_al > p_al) begin
                    sr = sc;
                    if (p_disc && !c_disc) begin
                        mag = (c_al - p_al) -
                              {{(44-1){1'b0}}, 1'b1};
                        tail = 1'b1;
                    end
                    else begin
                        mag = c_al - p_al;
                        tail = p_disc || c_disc;
                    end
                end
                else if (!p_disc && !c_disc) begin
                    mag = '0;
                    tail = 1'b0;
                    exact_zero = 1'b1;
                    sr = (rm == 3'd2);
                end
                else if (p_disc && !c_disc) begin
                    mag = '0;
                    tail = 1'b1;
                    sr = sp;
                end
                else if (c_disc && !p_disc) begin
                    mag = '0;
                    tail = 1'b1;
                    sr = sc;
                end
                else begin
                    mag = '0;
                    tail = 1'b1;
                    sr = (rm == 3'd2);
                end

                if (!exact_zero) begin
                    base_exp = common_top - 42;

                    m = -1;
                    for (i = 0; i < 44; i = i + 1) begin
                        if (mag[i]) begin
                            m = i;
                        end
                    end

                    if (m < 0) begin
                        rem_nonzero = tail;
                        round_inc = 1'b0;
                        case (rm)
                            3'd2: round_inc = sr && rem_nonzero;
                            3'd3: round_inc = (!sr) && rem_nonzero;
                            default: round_inc = 1'b0;
                        endcase

                        if (round_inc) begin
                            res = {sr, {5{1'b0}},
                                   {(10-1){1'b0}}, 1'b1};
                        end
                        else begin
                            res = {sr, {(16-1){1'b0}}};
                        end

                        flags[0] = rem_nonzero;
                        flags[1] = rem_nonzero;
                    end
                    else begin
                        etop = base_exp + m;
                        q = '0;
                        guard_bit = 1'b0;
                        lower_nonzero = 1'b0;
                        rem_nonzero = 1'b0;

                        if (etop >= -14) begin
                            sh = m - 10;

                            if (sh <= 0) begin
                                q = mag << (-sh);
                                rem_nonzero = tail;
                            end
                            else begin
                                q = mag >> sh;
                                guard_bit = mag[sh-1];
                                lower_nonzero = tail;

                                if (sh > 1) begin
                                    for (i = 0; i < 44; i = i + 1) begin
                                        if ((i < (sh-1)) && mag[i]) begin
                                            lower_nonzero = 1'b1;
                                        end
                                    end
                                end

                                rem_nonzero =
                                    guard_bit || lower_nonzero;
                            end

                            round_inc = 1'b0;
                            case (rm)
                                3'd0: round_inc =
                                    guard_bit &&
                                    (lower_nonzero || q[0]);
                                3'd1: round_inc = 1'b0;
                                3'd2: round_inc = sr && rem_nonzero;
                                3'd3: round_inc = (!sr) && rem_nonzero;
                                3'd4: round_inc = guard_bit;
                                default: round_inc = 1'b0;
                            endcase

                            qext = {1'b0, q} +
                                   {{11{1'b0}}, round_inc};

                            if (qext[11]) begin
                                qround = qext[11:1];
                                etop = etop + 1;
                            end
                            else begin
                                qround = qext[10:0];
                            end

                            if (etop > 15) begin
                                flags[0] = 1'b1;
                                flags[2] = 1'b1;

                                overflow_to_inf = 1'b0;
                                case (rm)
                                    3'd0: overflow_to_inf = 1'b1;
                                    3'd1: overflow_to_inf = 1'b0;
                                    3'd2: overflow_to_inf = sr;
                                    3'd3: overflow_to_inf = !sr;
                                    3'd4: overflow_to_inf = 1'b1;
                                    default: overflow_to_inf = 1'b1;
                                endcase

                                if (overflow_to_inf) begin
                                    res = {sr, {5{1'b1}},
                                           {10{1'b0}}};
                                end
                                else begin
                                    res = {sr,
                                           {(5-1){1'b1}}, 1'b0,
                                           {10{1'b1}}};
                                end
                            end
                            else begin
                                biased = etop + 15;
                                res = {sr,
                                       biased[4:0],
                                       qround[9:0]};
                                flags[0] = rem_nonzero;
                            end
                        end
                        else begin
                            sh = -24 - base_exp;

                            if (sh <= 0) begin
                                q = mag << (-sh);
                                rem_nonzero = tail;
                            end
                            else if (sh < 44) begin
                                q = mag >> sh;
                                guard_bit = mag[sh-1];
                                lower_nonzero = tail;

                                if (sh > 1) begin
                                    for (i = 0; i < 44; i = i + 1) begin
                                        if ((i < (sh-1)) && mag[i]) begin
                                            lower_nonzero = 1'b1;
                                        end
                                    end
                                end

                                rem_nonzero =
                                    guard_bit || lower_nonzero;
                            end
                            else if (sh == 44) begin
                                q = '0;
                                guard_bit = mag[43];
                                lower_nonzero = tail;

                                for (i = 0; i < 43; i = i + 1) begin
                                    if (mag[i]) begin
                                        lower_nonzero = 1'b1;
                                    end
                                end

                                rem_nonzero =
                                    guard_bit || lower_nonzero;
                            end
                            else begin
                                q = '0;
                                guard_bit = 1'b0;
                                lower_nonzero = (|mag) || tail;
                                rem_nonzero = lower_nonzero;
                            end

                            round_inc = 1'b0;
                            case (rm)
                                3'd0: round_inc =
                                    guard_bit &&
                                    (lower_nonzero || q[0]);
                                3'd1: round_inc = 1'b0;
                                3'd2: round_inc = sr && rem_nonzero;
                                3'd3: round_inc = (!sr) && rem_nonzero;
                                3'd4: round_inc = guard_bit;
                                default: round_inc = 1'b0;
                            endcase

                            qext = {1'b0, q} +
                                   {{11{1'b0}}, round_inc};

                            if (qext[10]) begin
                                res = {sr,
                                       {(5-1){1'b0}}, 1'b1,
                                       {10{1'b0}}};
                            end
                            else begin
                                res = {sr,
                                       {5{1'b0}},
                                       qext[9:0]};
                            end

                            flags[0] = rem_nonzero;
                            flags[1] =
                                rem_nonzero &&
                                (res[14:10] == '0);
                        end
                    end
                end

                if (exact_zero) begin
                    res = {sr, {(16-1){1'b0}}};
                end
            end
        end

        fp16_calc = {flags, res};
    end
endfunction


function automatic logic [20:0] bf16_calc(
    input logic [15:0] aa,
    input logic [15:0] bb,
    input logic [15:0] cc,
    input logic [2:0]       rm
);
    logic sa;
    logic sb;
    logic sc;
    logic sp;
    logic [7:0] ea;
    logic [7:0] eb;
    logic [7:0] ec;
    logic [6:0] fa;
    logic [6:0] fb;
    logic [6:0] fc;
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
    logic invalid_mul;
    logic product_inf;
    logic invalid_add;
    logic nan_result;
    logic [7:0] sig_a;
    logic [7:0] sig_b;
    logic [7:0] sig_c;
    logic [15:0] prod_sig;
    logic [31:0] p_ext;
    logic [31:0] c_ext;
    logic [31:0] p_al;
    logic [31:0] c_al;
    logic [31:0] mag;
    logic p_disc;
    logic c_disc;
    logic tail;
    logic sr;
    logic exact_zero;
    logic [7:0] q;
    logic [8:0] qext;
    logic [7:0] qround;
    logic guard_bit;
    logic lower_nonzero;
    logic rem_nonzero;
    logic round_inc;
    logic overflow_to_inf;
    logic [15:0] res;
    logic [4:0] flags;
    integer exp_a;
    integer exp_b;
    integer exp_c;
    integer exp_p;
    integer mp;
    integer mc;
    integer common_top;
    integer base_exp;
    integer m;
    integer etop;
    integer biased;
    integer sh;
    integer rsh;
    integer i;

    begin
        sa = aa[15];
        sb = bb[15];
        sc = cc[15];
        sp = sa ^ sb;

        ea = aa[14:7];
        eb = bb[14:7];
        ec = cc[14:7];

        fa = aa[6:0];
        fb = bb[6:0];
        fc = cc[6:0];

        a_nan = (ea == {8{1'b1}}) && (fa != '0);
        b_nan = (eb == {8{1'b1}}) && (fb != '0);
        c_nan = (ec == {8{1'b1}}) && (fc != '0);

        a_snan = a_nan && !fa[6];
        b_snan = b_nan && !fb[6];
        c_snan = c_nan && !fc[6];

        a_inf = (ea == {8{1'b1}}) && (fa == '0);
        b_inf = (eb == {8{1'b1}}) && (fb == '0);
        c_inf = (ec == {8{1'b1}}) && (fc == '0);

        a_zero = (ea == '0) && (fa == '0);
        b_zero = (eb == '0) && (fb == '0);
        c_zero = (ec == '0) && (fc == '0);

        invalid_mul = (a_inf && b_zero) || (b_inf && a_zero);
        product_inf = (a_inf || b_inf) &&
                      !a_nan && !b_nan &&
                      !invalid_mul;
        invalid_add = product_inf && c_inf && (sp != sc);

        nan_result = a_nan || b_nan || c_nan ||
                     invalid_mul || invalid_add;

        flags = 5'b0;
        flags[4] = a_snan || b_snan || c_snan ||
                   invalid_mul || invalid_add;
        res = '0;

        if (nan_result) begin
            res = 16'h7fc0;
        end
        else if (product_inf) begin
            res = {sp, {8{1'b1}}, {7{1'b0}}};
        end
        else if (c_inf) begin
            res = {sc, {8{1'b1}}, {7{1'b0}}};
        end
        else begin
            if (ea == '0) begin
                sig_a = {1'b0, fa};
                exp_a = -133;
            end
            else begin
                sig_a = {1'b1, fa};
                exp_a = $unsigned(ea) - 127 - 7;
            end

            if (eb == '0) begin
                sig_b = {1'b0, fb};
                exp_b = -133;
            end
            else begin
                sig_b = {1'b1, fb};
                exp_b = $unsigned(eb) - 127 - 7;
            end

            if (ec == '0) begin
                sig_c = {1'b0, fc};
                exp_c = -133;
            end
            else begin
                sig_c = {1'b1, fc};
                exp_c = $unsigned(ec) - 127 - 7;
            end

            prod_sig = sig_a * sig_b;
            exp_p = exp_a + exp_b;

            mp = -1;
            for (i = 0; i < 16; i = i + 1) begin
                if (prod_sig[i]) begin
                    mp = i;
                end
            end

            mc = -1;
            for (i = 0; i < 8; i = i + 1) begin
                if (sig_c[i]) begin
                    mc = i;
                end
            end

            exact_zero = 1'b0;
            tail = 1'b0;
            sr = 1'b0;
            mag = '0;

            if ((mp < 0) && (mc < 0)) begin
                exact_zero = 1'b1;
                if (sp == sc) begin
                    sr = sp;
                end
                else begin
                    sr = (rm == 3'd2);
                end
            end
            else begin
                if (mp < 0) begin
                    common_top = exp_c + mc;
                end
                else if (mc < 0) begin
                    common_top = exp_p + mp;
                end
                else if ((exp_p + mp) >= (exp_c + mc)) begin
                    common_top = exp_p + mp;
                end
                else begin
                    common_top = exp_c + mc;
                end

                p_ext = '0;
                c_ext = '0;
                p_ext[15:0] = prod_sig;
                c_ext[7:0] = sig_c;

                p_al = '0;
                c_al = '0;
                p_disc = 1'b0;
                c_disc = 1'b0;

                sh = 30 + exp_p - common_top;
                if (mp >= 0) begin
                    if (sh >= 0) begin
                        if (sh < 32) begin
                            p_al = p_ext << sh;
                        end
                    end
                    else begin
                        rsh = -sh;
                        if (rsh >= 32) begin
                            p_al = '0;
                            p_disc = |p_ext;
                        end
                        else begin
                            p_al = p_ext >> rsh;
                            for (i = 0; i < 32; i = i + 1) begin
                                if ((i < rsh) && p_ext[i]) begin
                                    p_disc = 1'b1;
                                end
                            end
                        end
                    end
                end

                sh = 30 + exp_c - common_top;
                if (mc >= 0) begin
                    if (sh >= 0) begin
                        if (sh < 32) begin
                            c_al = c_ext << sh;
                        end
                    end
                    else begin
                        rsh = -sh;
                        if (rsh >= 32) begin
                            c_al = '0;
                            c_disc = |c_ext;
                        end
                        else begin
                            c_al = c_ext >> rsh;
                            for (i = 0; i < 32; i = i + 1) begin
                                if ((i < rsh) && c_ext[i]) begin
                                    c_disc = 1'b1;
                                end
                            end
                        end
                    end
                end

                if (sp == sc) begin
                    mag = p_al + c_al;
                    tail = p_disc || c_disc;
                    sr = sp;
                end
                else if (p_al > c_al) begin
                    sr = sp;
                    if (c_disc && !p_disc) begin
                        mag = (p_al - c_al) -
                              {{(32-1){1'b0}}, 1'b1};
                        tail = 1'b1;
                    end
                    else begin
                        mag = p_al - c_al;
                        tail = p_disc || c_disc;
                    end
                end
                else if (c_al > p_al) begin
                    sr = sc;
                    if (p_disc && !c_disc) begin
                        mag = (c_al - p_al) -
                              {{(32-1){1'b0}}, 1'b1};
                        tail = 1'b1;
                    end
                    else begin
                        mag = c_al - p_al;
                        tail = p_disc || c_disc;
                    end
                end
                else if (!p_disc && !c_disc) begin
                    mag = '0;
                    tail = 1'b0;
                    exact_zero = 1'b1;
                    sr = (rm == 3'd2);
                end
                else if (p_disc && !c_disc) begin
                    mag = '0;
                    tail = 1'b1;
                    sr = sp;
                end
                else if (c_disc && !p_disc) begin
                    mag = '0;
                    tail = 1'b1;
                    sr = sc;
                end
                else begin
                    mag = '0;
                    tail = 1'b1;
                    sr = (rm == 3'd2);
                end

                if (!exact_zero) begin
                    base_exp = common_top - 30;

                    m = -1;
                    for (i = 0; i < 32; i = i + 1) begin
                        if (mag[i]) begin
                            m = i;
                        end
                    end

                    if (m < 0) begin
                        rem_nonzero = tail;
                        round_inc = 1'b0;
                        case (rm)
                            3'd2: round_inc = sr && rem_nonzero;
                            3'd3: round_inc = (!sr) && rem_nonzero;
                            default: round_inc = 1'b0;
                        endcase

                        if (round_inc) begin
                            res = {sr, {8{1'b0}},
                                   {(7-1){1'b0}}, 1'b1};
                        end
                        else begin
                            res = {sr, {(16-1){1'b0}}};
                        end

                        flags[0] = rem_nonzero;
                        flags[1] = rem_nonzero;
                    end
                    else begin
                        etop = base_exp + m;
                        q = '0;
                        guard_bit = 1'b0;
                        lower_nonzero = 1'b0;
                        rem_nonzero = 1'b0;

                        if (etop >= -126) begin
                            sh = m - 7;

                            if (sh <= 0) begin
                                q = mag << (-sh);
                                rem_nonzero = tail;
                            end
                            else begin
                                q = mag >> sh;
                                guard_bit = mag[sh-1];
                                lower_nonzero = tail;

                                if (sh > 1) begin
                                    for (i = 0; i < 32; i = i + 1) begin
                                        if ((i < (sh-1)) && mag[i]) begin
                                            lower_nonzero = 1'b1;
                                        end
                                    end
                                end

                                rem_nonzero =
                                    guard_bit || lower_nonzero;
                            end

                            round_inc = 1'b0;
                            case (rm)
                                3'd0: round_inc =
                                    guard_bit &&
                                    (lower_nonzero || q[0]);
                                3'd1: round_inc = 1'b0;
                                3'd2: round_inc = sr && rem_nonzero;
                                3'd3: round_inc = (!sr) && rem_nonzero;
                                3'd4: round_inc = guard_bit;
                                default: round_inc = 1'b0;
                            endcase

                            qext = {1'b0, q} +
                                   {{8{1'b0}}, round_inc};

                            if (qext[8]) begin
                                qround = qext[8:1];
                                etop = etop + 1;
                            end
                            else begin
                                qround = qext[7:0];
                            end

                            if (etop > 127) begin
                                flags[0] = 1'b1;
                                flags[2] = 1'b1;

                                overflow_to_inf = 1'b0;
                                case (rm)
                                    3'd0: overflow_to_inf = 1'b1;
                                    3'd1: overflow_to_inf = 1'b0;
                                    3'd2: overflow_to_inf = sr;
                                    3'd3: overflow_to_inf = !sr;
                                    3'd4: overflow_to_inf = 1'b1;
                                    default: overflow_to_inf = 1'b1;
                                endcase

                                if (overflow_to_inf) begin
                                    res = {sr, {8{1'b1}},
                                           {7{1'b0}}};
                                end
                                else begin
                                    res = {sr,
                                           {(8-1){1'b1}}, 1'b0,
                                           {7{1'b1}}};
                                end
                            end
                            else begin
                                biased = etop + 127;
                                res = {sr,
                                       biased[7:0],
                                       qround[6:0]};
                                flags[0] = rem_nonzero;
                            end
                        end
                        else begin
                            sh = -133 - base_exp;

                            if (sh <= 0) begin
                                q = mag << (-sh);
                                rem_nonzero = tail;
                            end
                            else if (sh < 32) begin
                                q = mag >> sh;
                                guard_bit = mag[sh-1];
                                lower_nonzero = tail;

                                if (sh > 1) begin
                                    for (i = 0; i < 32; i = i + 1) begin
                                        if ((i < (sh-1)) && mag[i]) begin
                                            lower_nonzero = 1'b1;
                                        end
                                    end
                                end

                                rem_nonzero =
                                    guard_bit || lower_nonzero;
                            end
                            else if (sh == 32) begin
                                q = '0;
                                guard_bit = mag[31];
                                lower_nonzero = tail;

                                for (i = 0; i < 31; i = i + 1) begin
                                    if (mag[i]) begin
                                        lower_nonzero = 1'b1;
                                    end
                                end

                                rem_nonzero =
                                    guard_bit || lower_nonzero;
                            end
                            else begin
                                q = '0;
                                guard_bit = 1'b0;
                                lower_nonzero = (|mag) || tail;
                                rem_nonzero = lower_nonzero;
                            end

                            round_inc = 1'b0;
                            case (rm)
                                3'd0: round_inc =
                                    guard_bit &&
                                    (lower_nonzero || q[0]);
                                3'd1: round_inc = 1'b0;
                                3'd2: round_inc = sr && rem_nonzero;
                                3'd3: round_inc = (!sr) && rem_nonzero;
                                3'd4: round_inc = guard_bit;
                                default: round_inc = 1'b0;
                            endcase

                            qext = {1'b0, q} +
                                   {{8{1'b0}}, round_inc};

                            if (qext[7]) begin
                                res = {sr,
                                       {(8-1){1'b0}}, 1'b1,
                                       {7{1'b0}}};
                            end
                            else begin
                                res = {sr,
                                       {8{1'b0}},
                                       qext[6:0]};
                            end

                            flags[0] = rem_nonzero;
                            flags[1] =
                                rem_nonzero &&
                                (res[14:7] == '0);
                        end
                    end
                end

                if (exact_zero) begin
                    res = {sr, {(16-1){1'b0}}};
                end
            end
        end

        bf16_calc = {flags, res};
    end
endfunction

    logic             busy_q;
    logic [1:0]       fmt_q;
    logic             vec_q;
    logic [2:0]       rnd_q;
    logic [WIDTH-1:0] a_q;
    logic [WIDTH-1:0] b_q;
    logic [WIDTH-1:0] c_q;
    logic [2:0]       lane_q;
    logic [2:0]       lane_count_q;
    logic [WIDTH-1:0] accum_result_q;
    logic [4:0]       accum_flags_q;

    logic             out_valid_q;
    logic [WIDTH-1:0] out_result_q;
    logic [4:0]       out_flags_q;

    logic [31:0] lane_a32_c;
    logic [31:0] lane_b32_c;
    logic [31:0] lane_c32_c;
    logic [15:0] lane_a16_c;
    logic [15:0] lane_b16_c;
    logic [15:0] lane_c16_c;

    logic [36:0] calc32_c;
    logic [20:0] calc16_c;
    logic [20:0] calcb16_c;

    logic [WIDTH-1:0] accum_next_c;
    logic [4:0]       flags_next_c;
    logic [31:0]      selected_result32_c;
    logic [15:0]      selected_result16_c;
    logic [4:0]       selected_flags_c;

    always_comb begin
        lane_a32_c = a_q >> (lane_q * 32);
        lane_b32_c = b_q >> (lane_q * 32);
        lane_c32_c = c_q >> (lane_q * 32);

        lane_a16_c = a_q >> (lane_q * 16);
        lane_b16_c = b_q >> (lane_q * 16);
        lane_c16_c = c_q >> (lane_q * 16);

        calc32_c = fp32_calc(
            lane_a32_c,
            lane_b32_c,
            lane_c32_c,
            rnd_q
        );

        calc16_c = fp16_calc(
            lane_a16_c,
            lane_b16_c,
            lane_c16_c,
            rnd_q
        );

        calcb16_c = bf16_calc(
            lane_a16_c,
            lane_b16_c,
            lane_c16_c,
            rnd_q
        );

        selected_result32_c = calc32_c[31:0];
        selected_result16_c = calc16_c[15:0];
        selected_flags_c = calc32_c[36:32];

        if (fmt_q == 2'd1) begin
            selected_result16_c = calc16_c[15:0];
            selected_flags_c = calc16_c[20:16];
        end
        else if (fmt_q == 2'd2) begin
            selected_result16_c = calcb16_c[15:0];
            selected_flags_c = calcb16_c[20:16];
        end

        accum_next_c = accum_result_q;
        flags_next_c = accum_flags_q | selected_flags_c;

        if (fmt_q == 2'd0) begin
            accum_next_c[(lane_q * 32) +: 32] =
                selected_result32_c;
        end
        else begin
            accum_next_c[(lane_q * 16) +: 16] =
                selected_result16_c;
        end
    end

    always_comb begin
        in_ready_o = rst_ni && !busy_q && !out_valid_q;

        out_valid_o = rst_ni && out_valid_q;
        result_o = out_result_q;
        flags_o = out_flags_q;
    end

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            busy_q <= 1'b0;
            fmt_q <= 2'b0;
            vec_q <= 1'b0;
            rnd_q <= 3'b0;
            a_q <= '0;
            b_q <= '0;
            c_q <= '0;
            lane_q <= 3'b0;
            lane_count_q <= 3'd1;
            accum_result_q <= '1;
            accum_flags_q <= 5'b0;

            out_valid_q <= 1'b0;
            out_result_q <= '0;
            out_flags_q <= 5'b0;
        end
        else begin
            if (out_valid_q && out_ready_i) begin
                out_valid_q <= 1'b0;
            end

            if (!busy_q && !out_valid_q) begin
                if (in_valid_i) begin
                    busy_q <= 1'b1;
                    fmt_q <= fmt_i;
                    vec_q <= vec_i;
                    rnd_q <= rnd_i;
                    a_q <= a_i;
                    b_q <= b_i;
                    c_q <= c_i;
                    lane_q <= 3'd0;
                    accum_result_q <= '1;
                    accum_flags_q <= 5'b0;

                    if (!vec_i) begin
                        lane_count_q <= 3'd1;
                    end
                    else if (fmt_i == 2'd0) begin
                        lane_count_q <= WIDTH / 32;
                    end
                    else begin
                        lane_count_q <= WIDTH / 16;
                    end
                end
            end
            else if (busy_q) begin
                accum_result_q <= accum_next_c;
                accum_flags_q <= flags_next_c;

                if ((lane_q + 3'd1) >= lane_count_q) begin
                    busy_q <= 1'b0;
                    out_valid_q <= 1'b1;
                    out_result_q <= accum_next_c;
                    out_flags_q <= flags_next_c;
                end
                else begin
                    lane_q <= lane_q + 3'd1;
                end
            end
        end
    end

endmodule