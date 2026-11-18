module fp_multifmt_fma #(
  parameter int unsigned WIDTH = 64        // {32, 64}
) (
  input  logic             clk_i,
  input  logic             rst_ni,         // active low

  // ---- operation in ---------------------------------------------------------
  input  logic             in_valid_i,
  output logic             in_ready_o,
  input  logic [1:0]       fmt_i,          // 0 = FP32, 1 = FP16, 2 = BF16
  input  logic             vec_i,          // 1 = packed SIMD lanes
  input  logic [WIDTH-1:0] a_i,
  input  logic [WIDTH-1:0] b_i,
  input  logic [WIDTH-1:0] c_i,
  input  logic [2:0]       rnd_i,          // 0 RNE, 1 RTZ, 2 RDN, 3 RUP, 4 RMM

  // ---- result out -----------------------------------------------------------
  output logic             out_valid_o,
  input  logic             out_ready_i,
  output logic [WIDTH-1:0] result_o,
  output logic [4:0]       flags_o         // {NV, DZ, OF, UF, NX}
);

  // ---------------------------------------------------------------------------
  // FP32 lane
  // ---------------------------------------------------------------------------
  function automatic [31:0] fma32 (
      input logic [31:0] a,
      input logic [31:0] b,
      input logic [31:0] c,
      input logic [2:0]  rnd,
      output logic [4:0] flags
  );
    localparam int EW   = 8;
    localparam int MW   = 23;
    localparam int P    = 24;
    localparam int BIAS = 127;
    localparam int EMIN = 1 - BIAS;
    localparam int EMAX = BIAS;
    localparam int W    = 4 * P;      // 96
    localparam int SUMW = W + 2;      // 98
    localparam logic [31:0] CANON_NAN = 32'h7FC00000;

    logic sa, sb, sc;
    logic [EW-1:0] ea_f, eb_f, ec_f;
    logic [MW-1:0] fa, fb, fc;
    logic isNaN_A, isNaN_B, isNaN_C;
    logic isInf_A, isInf_B, isInf_C;
    logic isSNaN_A, isSNaN_B, isSNaN_C;
    logic isQNaN_A, isQNaN_B, isQNaN_C;
    logic isZero_A, isZero_B, isZero_C;
    logic [P-1:0] sigA, sigB, sigC;
    int eA, eB, eC;
    logic [2*P-1:0] prod;
    int eP_lsb, eC_lsb;
    int msbP, msbC, topP, topC, maxTop, B;
    int shiftP, shiftC, shP, shC;
    logic [SUMW-1:0] termP, termC, alignedP, alignedC;
    logic stickyP, stickyC;
    logic signed [SUMW-1:0] signedP, signedC, sum_signed, S_floor;
    logic st, sticky_neg;
    logic [SUMW-1:0] Msum;
    int msb_pos, E, target_LSB, sh;
    logic [SUMW-1:0] integer_part, rem, Q;
    logic guard, sticky_low;
    logic inc;
    int E_final;
    logic [EW-1:0] exp_field;
    logic [MW-1:0] frac;
    logic sign_out;
    logic inexact;
    logic [4:0] fl;
    integer i;
    logic sign_zero;
    logic prod_inf, c_inf;

    // decode
    sa = a[31];
    ea_f = a[30:23];
    fa = a[22:0];
    sb = b[31];
    eb_f = b[30:23];
    fb = b[22:0];
    sc = c[31];
    ec_f = c[30:23];
    fc = c[22:0];

    isNaN_A = (ea_f == 8'hFF) && (fa != 0);
    isNaN_B = (eb_f == 8'hFF) && (fb != 0);
    isNaN_C = (ec_f == 8'hFF) && (fc != 0);
    isInf_A = (ea_f == 8'hFF) && (fa == 0);
    isInf_B = (eb_f == 8'hFF) && (fb == 0);
    isInf_C = (ec_f == 8'hFF) && (fc == 0);
    isSNaN_A = isNaN_A && !fa[22];
    isSNaN_B = isNaN_B && !fb[22];
    isSNaN_C = isNaN_C && !fc[22];
    isQNaN_A = isNaN_A && fa[22];
    isQNaN_B = isNaN_B && fb[22];
    isQNaN_C = isNaN_C && fc[22];
    isZero_A = (ea_f == 0) && (fa == 0);
    isZero_B = (eb_f == 0) && (fb == 0);
    isZero_C = (ec_f == 0) && (fc == 0);

    // invalid: 0 * inf
    if ((isZero_A && isInf_B) || (isInf_A && isZero_B)) begin
        flags = 5'b10000;
        return CANON_NAN;
    end
    // signalling NaN
    if (isSNaN_A || isSNaN_B || isSNaN_C) begin
        flags = 5'b10000;
        return CANON_NAN;
    end
    // quiet NaN
    if (isNaN_A || isNaN_B || isNaN_C) begin
        flags = 5'b00000;
        return CANON_NAN;
    end

    prod_inf = isInf_A || isInf_B;
    c_inf    = isInf_C;

    if (prod_inf && c_inf) begin
        if ((sa ^ sb) != sc) begin
            flags = 5'b10000;
            return CANON_NAN;
        end else begin
            flags = 5'b00000;
            return {sa ^ sb, 8'hFF, 23'b0};
        end
    end
    if (prod_inf) begin
        flags = 5'b00000;
        return {sa ^ sb, 8'hFF, 23'b0};
    end
    if (c_inf) begin
        flags = 5'b00000;
        return {sc, 8'hFF, 23'b0};
    end

    // effective significands and exponents
    if (ea_f == 0) begin
        eA = 1 - BIAS;
        sigA = {1'b0, fa};
    end else begin
        eA = ea_f - BIAS;
        sigA = {1'b1, fa};
    end
    if (eb_f == 0) begin
        eB = 1 - BIAS;
        sigB = {1'b0, fb};
    end else begin
        eB = eb_f - BIAS;
        sigB = {1'b1, fb};
    end
    if (ec_f == 0) begin
        eC = 1 - BIAS;
        sigC = {1'b0, fc};
    end else begin
        eC = ec_f - BIAS;
        sigC = {1'b1, fc};
    end

    prod   = sigA * sigB;
    eP_lsb = eA + eB - 2*(P-1);
    eC_lsb = eC - (P-1);

    // top exponents
    if (prod == 0) begin
        topP = -1000000;
        msbP = 0;
    end else begin
        msbP = -1;
        for (i = 2*P-1; i >= 0; i = i - 1) begin
            if (prod[i]) begin
                msbP = i;
                break;
            end
        end
        topP = eP_lsb + msbP;
    end
    if (sigC == 0) begin
        topC = -1000000;
        msbC = 0;
    end else begin
        msbC = -1;
        for (i = P-1; i >= 0; i = i - 1) begin
            if (sigC[i]) begin
                msbC = i;
                break;
            end
        end
        topC = eC_lsb + msbC;
    end

    maxTop = (topP > topC) ? topP : topC;
    B = maxTop - (W - 1);

    // align product
    termP = {{(SUMW-(2*P)){1'b0}}, prod};
    if (prod == 0) begin
        alignedP = 0;
        stickyP  = 0;
    end else begin
        shiftP = eP_lsb - B;
        if (shiftP >= 0) begin
            alignedP = termP << shiftP;
            stickyP  = 0;
        end else begin
            shP = -shiftP;
            if (shP >= SUMW) begin
                alignedP = 0;
                stickyP  = (prod != 0);
            end else begin
                alignedP = termP >> shP;
                stickyP  = (termP != (alignedP << shP));
            end
        end
    end

    // align addend
    termC = {{(SUMW-P){1'b0}}, sigC};
    if (sigC == 0) begin
        alignedC = 0;
        stickyC  = 0;
    end else begin
        shiftC = eC_lsb - B;
        if (shiftC >= 0) begin
            alignedC = termC << shiftC;
            stickyC  = 0;
        end else begin
            shC = -shiftC;
            if (shC >= SUMW) begin
                alignedC = 0;
                stickyC  = (sigC != 0);
            end else begin
                alignedC = termC >> shC;
                stickyC  = (termC != (alignedC << shC));
            end
        end
    end

    // signed sum
    if (sa ^ sb) signedP = -$signed(alignedP);
    else         signedP =  $signed(alignedP);
    if (sc)      signedC = -$signed(alignedC);
    else         signedC =  $signed(alignedC);

    sum_signed = signedP + signedC;

    st         = stickyP | stickyC;
    sticky_neg = (stickyP & (sa ^ sb)) | (stickyC & sc);
    if (st && sticky_neg) S_floor = sum_signed - 1;
    else                  S_floor = sum_signed;

    if (S_floor == 0 && !st) begin
        // exact zero
        if (prod == 0 && sigC == 0) begin
            if ((sa ^ sb) == sc) sign_zero = (sa ^ sb);
            else                 sign_zero = (rnd == 2);
        end else begin
            sign_zero = (rnd == 2);
        end
        flags = 5'b00000;
        return {sign_zero, 8'h00, 23'h0};
    end

    if (S_floor[SUMW-1]) begin
        sign_out = 1'b1;
        Msum     = -S_floor;
    end else begin
        sign_out = 1'b0;
        Msum     = S_floor;
    end

    msb_pos = -1;
    for (i = SUMW-1; i >= 0; i = i - 1) begin
        if (Msum[i]) begin
            msb_pos = i;
            break;
        end
    end

    E = B + msb_pos;

    if (E < EMIN) target_LSB = EMIN - (P-1);
    else          target_LSB = E - (P-1);

    sh = target_LSB - B;
    if (sh <= 0) begin
        integer_part = Msum << (-sh);
        rem          = 0;
        inexact      = st;
        guard        = 0;
        sticky_low   = st;
    end else begin
        integer_part = Msum >> sh;
        rem          = Msum - (integer_part << sh);
        inexact      = (rem != 0) || st;
        guard        = (Msum >> (sh-1)) & 1'b1;
        if (rem == 0) begin
            sticky_low = st;
        end else if (guard == 0) begin
            sticky_low = 1'b1;
        end else begin
            sticky_low = ((rem & (rem - 1)) != 0) || st;
        end
    end

    inc = 0;
    case (rnd)
        0: begin // RNE
            if (guard && (sticky_low || integer_part[0])) inc = 1;
        end
        1: inc = 0; // RTZ
        2: begin // RDN
            if (sign_out && (guard || sticky_low)) inc = 1;
        end
        3: begin // RUP
            if (!sign_out && (guard || sticky_low)) inc = 1;
        end
        4: begin // RMM
            if (guard) inc = 1;
        end
        default: inc = 0;
    endcase

    Q = integer_part + inc;

    if (E < EMIN) begin
        // subnormal path
        if (Q < (1 << (P-1))) begin
            exp_field = 0;
            frac      = Q[MW-1:0];
        end else begin
            exp_field = 1;
            frac      = 0;
        end
        fl = 5'b00000;
        fl[0] = inexact;
        fl[1] = inexact && (exp_field == 0);
        flags = fl;
        return {sign_out, exp_field, frac};
    end else begin
        // normal path
        if (Q >= (1 << P)) begin
            E_final = E + 1;
            Q       = (1 << (P-1));
        end else begin
            E_final = E;
        end
        if (E_final > EMAX) begin
            flags = 5'b00101; // OF=1, NX=1
            return {sign_out, 8'hFF, 23'b0};
        end
        exp_field = E_final + BIAS;
        frac      = Q - (1 << (P-1));
        fl = 5'b00000;
        fl[0] = inexact;
        fl[1] = 1'b0;
        flags = fl;
        return {sign_out, exp_field, frac};
    end
  endfunction

  // ---------------------------------------------------------------------------
  // FP16 lane
  // ---------------------------------------------------------------------------
  function automatic [15:0] fma16 (
      input logic [15:0] a,
      input logic [15:0] b,
      input logic [15:0] c,
      input logic [2:0]  rnd,
      output logic [4:0] flags
  );
    localparam int EW   = 5;
    localparam int MW   = 10;
    localparam int P    = 11;
    localparam int BIAS = 15;
    localparam int EMIN = 1 - BIAS;
    localparam int EMAX = BIAS;
    localparam int W    = 4 * P;      // 44
    localparam int SUMW = W + 2;      // 46
    localparam logic [15:0] CANON_NAN = 16'h7E00;

    logic sa, sb, sc;
    logic [EW-1:0] ea_f, eb_f, ec_f;
    logic [MW-1:0] fa, fb, fc;
    logic isNaN_A, isNaN_B, isNaN_C;
    logic isInf_A, isInf_B, isInf_C;
    logic isSNaN_A, isSNaN_B, isSNaN_C;
    logic isQNaN_A, isQNaN_B, isQNaN_C;
    logic isZero_A, isZero_B, isZero_C;
    logic [P-1:0] sigA, sigB, sigC;
    int eA, eB, eC;
    logic [2*P-1:0] prod;
    int eP_lsb, eC_lsb;
    int msbP, msbC, topP, topC, maxTop, B;
    int shiftP, shiftC, shP, shC;
    logic [SUMW-1:0] termP, termC, alignedP, alignedC;
    logic stickyP, stickyC;
    logic signed [SUMW-1:0] signedP, signedC, sum_signed, S_floor;
    logic st, sticky_neg;
    logic [SUMW-1:0] Msum;
    int msb_pos, E, target_LSB, sh;
    logic [SUMW-1:0] integer_part, rem, Q;
    logic guard, sticky_low;
    logic inc;
    int E_final;
    logic [EW-1:0] exp_field;
    logic [MW-1:0] frac;
    logic sign_out;
    logic inexact;
    logic [4:0] fl;
    integer i;
    logic sign_zero;
    logic prod_inf, c_inf;

    sa = a[15];
    ea_f = a[14:10];
    fa = a[9:0];
    sb = b[15];
    eb_f = b[14:10];
    fb = b[9:0];
    sc = c[15];
    ec_f = c[14:10];
    fc = c[9:0];

    isNaN_A = (ea_f == 5'h1F) && (fa != 0);
    isNaN_B = (eb_f == 5'h1F) && (fb != 0);
    isNaN_C = (ec_f == 5'h1F) && (fc != 0);
    isInf_A = (ea_f == 5'h1F) && (fa == 0);
    isInf_B = (eb_f == 5'h1F) && (fb == 0);
    isInf_C = (ec_f == 5'h1F) && (fc == 0);
    isSNaN_A = isNaN_A && !fa[9];
    isSNaN_B = isNaN_B && !fb[9];
    isSNaN_C = isNaN_C && !fc[9];
    isQNaN_A = isNaN_A && fa[9];
    isQNaN_B = isNaN_B && fb[9];
    isQNaN_C = isNaN_C && fc[9];
    isZero_A = (ea_f == 0) && (fa == 0);
    isZero_B = (eb_f == 0) && (fb == 0);
    isZero_C = (ec_f == 0) && (fc == 0);

    if ((isZero_A && isInf_B) || (isInf_A && isZero_B)) begin
        flags = 5'b10000;
        return CANON_NAN;
    end
    if (isSNaN_A || isSNaN_B || isSNaN_C) begin
        flags = 5'b10000;
        return CANON_NAN;
    end
    if (isNaN_A || isNaN_B || isNaN_C) begin
        flags = 5'b00000;
        return CANON_NAN;
    end

    prod_inf = isInf_A || isInf_B;
    c_inf    = isInf_C;

    if (prod_inf && c_inf) begin
        if ((sa ^ sb) != sc) begin
            flags = 5'b10000;
            return CANON_NAN;
        end else begin
            flags = 5'b00000;
            return {sa ^ sb, 5'h1F, 10'b0};
        end
    end
    if (prod_inf) begin
        flags = 5'b00000;
        return {sa ^ sb, 5'h1F, 10'b0};
    end
    if (c_inf) begin
        flags = 5'b00000;
        return {sc, 5'h1F, 10'b0};
    end

    if (ea_f == 0) begin
        eA = 1 - BIAS;
        sigA = {1'b0, fa};
    end else begin
        eA = ea_f - BIAS;
        sigA = {1'b1, fa};
    end
    if (eb_f == 0) begin
        eB = 1 - BIAS;
        sigB = {1'b0, fb};
    end else begin
        eB = eb_f - BIAS;
        sigB = {1'b1, fb};
    end
    if (ec_f == 0) begin
        eC = 1 - BIAS;
        sigC = {1'b0, fc};
    end else begin
        eC = ec_f - BIAS;
        sigC = {1'b1, fc};
    end

    prod   = sigA * sigB;
    eP_lsb = eA + eB - 2*(P-1);
    eC_lsb = eC - (P-1);

    if (prod == 0) begin
        topP = -1000000;
        msbP = 0;
    end else begin
        msbP = -1;
        for (i = 2*P-1; i >= 0; i = i - 1) begin
            if (prod[i]) begin
                msbP = i;
                break;
            end
        end
        topP = eP_lsb + msbP;
    end
    if (sigC == 0) begin
        topC = -1000000;
        msbC = 0;
    end else begin
        msbC = -1;
        for (i = P-1; i >= 0; i = i - 1) begin
            if (sigC[i]) begin
                msbC = i;
                break;
            end
        end
        topC = eC_lsb + msbC;
    end

    maxTop = (topP > topC) ? topP : topC;
    B = maxTop - (W - 1);

    termP = {{(SUMW-(2*P)){1'b0}}, prod};
    if (prod == 0) begin
        alignedP = 0;
        stickyP  = 0;
    end else begin
        shiftP = eP_lsb - B;
        if (shiftP >= 0) begin
            alignedP = termP << shiftP;
            stickyP  = 0;
        end else begin
            shP = -shiftP;
            if (shP >= SUMW) begin
                alignedP = 0;
                stickyP  = (prod != 0);
            end else begin
                alignedP = termP >> shP;
                stickyP  = (termP != (alignedP << shP));
            end
        end
    end

    termC = {{(SUMW-P){1'b0}}, sigC};
    if (sigC == 0) begin
        alignedC = 0;
        stickyC  = 0;
    end else begin
        shiftC = eC_lsb - B;
        if (shiftC >= 0) begin
            alignedC = termC << shiftC;
            stickyC  = 0;
        end else begin
            shC = -shiftC;
            if (shC >= SUMW) begin
                alignedC = 0;
                stickyC  = (sigC != 0);
            end else begin
                alignedC = termC >> shC;
                stickyC  = (termC != (alignedC << shC));
            end
        end
    end

    if (sa ^ sb) signedP = -$signed(alignedP);
    else         signedP =  $signed(alignedP);
    if (sc)      signedC = -$signed(alignedC);
    else         signedC =  $signed(alignedC);

    sum_signed = signedP + signedC;

    st         = stickyP | stickyC;
    sticky_neg = (stickyP & (sa ^ sb)) | (stickyC & sc);
    if (st && sticky_neg) S_floor = sum_signed - 1;
    else                  S_floor = sum_signed;

    if (S_floor == 0 && !st) begin
        if (prod == 0 && sigC == 0) begin
            if ((sa ^ sb) == sc) sign_zero = (sa ^ sb);
            else                 sign_zero = (rnd == 2);
        end else begin
            sign_zero = (rnd == 2);
        end
        flags = 5'b00000;
        return {sign_zero, 5'h00, 10'h0};
    end

    if (S_floor[SUMW-1]) begin
        sign_out = 1'b1;
        Msum     = -S_floor;
    end else begin
        sign_out = 1'b0;
        Msum     = S_floor;
    end

    msb_pos = -1;
    for (i = SUMW-1; i >= 0; i = i - 1) begin
        if (Msum[i]) begin
            msb_pos = i;
            break;
        end
    end

    E = B + msb_pos;

    if (E < EMIN) target_LSB = EMIN - (P-1);
    else          target_LSB = E - (P-1);

    sh = target_LSB - B;
    if (sh <= 0) begin
        integer_part = Msum << (-sh);
        rem          = 0;
        inexact      = st;
        guard        = 0;
        sticky_low   = st;
    end else begin
        integer_part = Msum >> sh;
        rem          = Msum - (integer_part << sh);
        inexact      = (rem != 0) || st;
        guard        = (Msum >> (sh-1)) & 1'b1;
        if (rem == 0) begin
            sticky_low = st;
        end else if (guard == 0) begin
            sticky_low = 1'b1;
        end else begin
            sticky_low = ((rem & (rem - 1)) != 0) || st;
        end
    end

    inc = 0;
    case (rnd)
        0: begin
            if (guard && (sticky_low || integer_part[0])) inc = 1;
        end
        1: inc = 0;
        2: begin
            if (sign_out && (guard || sticky_low)) inc = 1;
        end
        3: begin
            if (!sign_out && (guard || sticky_low)) inc = 1;
        end
        4: begin
            if (guard) inc = 1;
        end
        default: inc = 0;
    endcase

    Q = integer_part + inc;

    if (E < EMIN) begin
        if (Q < (1 << (P-1))) begin
            exp_field = 0;
            frac      = Q[MW-1:0];
        end else begin
            exp_field = 1;
            frac      = 0;
        end
        fl = 5'b00000;
        fl[0] = inexact;
        fl[1] = inexact && (exp_field == 0);
        flags = fl;
        return {sign_out, exp_field, frac};
    end else begin
        if (Q >= (1 << P)) begin
            E_final = E + 1;
            Q       = (1 << (P-1));
        end else begin
            E_final = E;
        end
        if (E_final > EMAX) begin
            flags = 5'b00101;
            return {sign_out, 5'h1F, 10'b0};
        end
        exp_field = E_final + BIAS;
        frac      = Q - (1 << (P-1));
        fl = 5'b00000;
        fl[0] = inexact;
        fl[1] = 1'b0;
        flags = fl;
        return {sign_out, exp_field, frac};
    end
  endfunction

  // ---------------------------------------------------------------------------
  // BF16 lane
  // ---------------------------------------------------------------------------
  function automatic [15:0] fma_bf16 (
      input logic [15:0] a,
      input logic [15:0] b,
      input logic [15:0] c,
      input logic [2:0]  rnd,
      output logic [4:0] flags
  );
    localparam int EW   = 8;
    localparam int MW   = 7;
    localparam int P    = 8;
    localparam int BIAS = 127;
    localparam int EMIN = 1 - BIAS;
    localparam int EMAX = BIAS;
    localparam int W    = 4 * P;      // 32
    localparam int SUMW = W + 2;      // 34
    localparam logic [15:0] CANON_NAN = 16'h7FC0;

    logic sa, sb, sc;
    logic [EW-1:0] ea_f, eb_f, ec_f;
    logic [MW-1:0] fa, fb, fc;
    logic isNaN_A, isNaN_B, isNaN_C;
    logic isInf_A, isInf_B, isInf_C;
    logic isSNaN_A, isSNaN_B, isSNaN_C;
    logic isQNaN_A, isQNaN_B, isQNaN_C;
    logic isZero_A, isZero_B, isZero_C;
    logic [P-1:0] sigA, sigB, sigC;
    int eA, eB, eC;
    logic [2*P-1:0] prod;
    int eP_lsb, eC_lsb;
    int msbP, msbC, topP, topC, maxTop, B;
    int shiftP, shiftC, shP, shC;
    logic [SUMW-1:0] termP, termC, alignedP, alignedC;
    logic stickyP, stickyC;
    logic signed [SUMW-1:0] signedP, signedC, sum_signed, S_floor;
    logic st, sticky_neg;
    logic [SUMW-1:0] Msum;
    int msb_pos, E, target_LSB, sh;
    logic [SUMW-1:0] integer_part, rem, Q;
    logic guard, sticky_low;
    logic inc;
    int E_final;
    logic [EW-1:0] exp_field;
    logic [MW-1:0] frac;
    logic sign_out;
    logic inexact;
    logic [4:0] fl;
    integer i;
    logic sign_zero;
    logic prod_inf, c_inf;

    sa = a[15];
    ea_f = a[14:7];
    fa = a[6:0];
    sb = b[15];
    eb_f = b[14:7];
    fb = b[6:0];
    sc = c[15];
    ec_f = c[14:7];
    fc = c[6:0];

    isNaN_A = (ea_f == 8'hFF) && (fa != 0);
    isNaN_B = (eb_f == 8'hFF) && (fb != 0);
    isNaN_C = (ec_f == 8'hFF) && (fc != 0);
    isInf_A = (ea_f == 8'hFF) && (fa == 0);
    isInf_B = (eb_f == 8'hFF) && (fb == 0);
    isInf_C = (ec_f == 8'hFF) && (fc == 0);
    isSNaN_A = isNaN_A && !fa[6];
    isSNaN_B = isNaN_B && !fb[6];
    isSNaN_C = isNaN_C && !fc[6];
    isQNaN_A = isNaN_A && fa[6];
    isQNaN_B = isNaN_B && fb[6];
    isQNaN_C = isNaN_C && fc[6];
    isZero_A = (ea_f == 0) && (fa == 0);
    isZero_B = (eb_f == 0) && (fb == 0);
    isZero_C = (ec_f == 0) && (fc == 0);

    if ((isZero_A && isInf_B) || (isInf_A && isZero_B)) begin
        flags = 5'b10000;
        return CANON_NAN;
    end
    if (isSNaN_A || isSNaN_B || isSNaN_C) begin
        flags = 5'b10000;
        return CANON_NAN;
    end
    if (isNaN_A || isNaN_B || isNaN_C) begin
        flags = 5'b00000;
        return CANON_NAN;
    end

    prod_inf = isInf_A || isInf_B;
    c_inf    = isInf_C;

    if (prod_inf && c_inf) begin
        if ((sa ^ sb) != sc) begin
            flags = 5'b10000;
            return CANON_NAN;
        end else begin
            flags = 5'b00000;
            return {sa ^ sb, 8'hFF, 7'b0};
        end
    end
    if (prod_inf) begin
        flags = 5'b00000;
        return {sa ^ sb, 8'hFF, 7'b0};
    end
    if (c_inf) begin
        flags = 5'b00000;
        return {sc, 8'hFF, 7'b0};
    end

    if (ea_f == 0) begin
        eA = 1 - BIAS;
        sigA = {1'b0, fa};
    end else begin
        eA = ea_f - BIAS;
        sigA = {1'b1, fa};
    end
    if (eb_f == 0) begin
        eB = 1 - BIAS;
        sigB = {1'b0, fb};
    end else begin
        eB = eb_f - BIAS;
        sigB = {1'b1, fb};
    end
    if (ec_f == 0) begin
        eC = 1 - BIAS;
        sigC = {1'b0, fc};
    end else begin
        eC = ec_f - BIAS;
        sigC = {1'b1, fc};
    end

    prod   = sigA * sigB;
    eP_lsb = eA + eB - 2*(P-1);
    eC_lsb = eC - (P-1);

    if (prod == 0) begin
        topP = -1000000;
        msbP = 0;
    end else begin
        msbP = -1;
        for (i = 2*P-1; i >= 0; i = i - 1) begin
            if (prod[i]) begin
                msbP = i;
                break;
            end
        end
        topP = eP_lsb + msbP;
    end
    if (sigC == 0) begin
        topC = -1000000;
        msbC = 0;
    end else begin
        msbC = -1;
        for (i = P-1; i >= 0; i = i - 1) begin
            if (sigC[i]) begin
                msbC = i;
                break;
            end
        end
        topC = eC_lsb + msbC;
    end

    maxTop = (topP > topC) ? topP : topC;
    B = maxTop - (W - 1);

    termP = {{(SUMW-(2*P)){1'b0}}, prod};
    if (prod == 0) begin
        alignedP = 0;
        stickyP  = 0;
    end else begin
        shiftP = eP_lsb - B;
        if (shiftP >= 0) begin
            alignedP = termP << shiftP;
            stickyP  = 0;
        end else begin
            shP = -shiftP;
            if (shP >= SUMW) begin
                alignedP = 0;
                stickyP  = (prod != 0);
            end else begin
                alignedP = termP >> shP;
                stickyP  = (termP != (alignedP << shP));
            end
        end
    end

    termC = {{(SUMW-P){1'b0}}, sigC};
    if (sigC == 0) begin
        alignedC = 0;
        stickyC  = 0;
    end else begin
        shiftC = eC_lsb - B;
        if (shiftC >= 0) begin
            alignedC = termC << shiftC;
            stickyC  = 0;
        end else begin
            shC = -shiftC;
            if (shC >= SUMW) begin
                alignedC = 0;
                stickyC  = (sigC != 0);
            end else begin
                alignedC = termC >> shC;
                stickyC  = (termC != (alignedC << shC));
            end
        end
    end

    if (sa ^ sb) signedP = -$signed(alignedP);
    else         signedP =  $signed(alignedP);
    if (sc)      signedC = -$signed(alignedC);
    else         signedC =  $signed(alignedC);

    sum_signed = signedP + signedC;

    st         = stickyP | stickyC;
    sticky_neg = (stickyP & (sa ^ sb)) | (stickyC & sc);
    if (st && sticky_neg) S_floor = sum_signed - 1;
    else                  S_floor = sum_signed;

    if (S_floor == 0 && !st) begin
        if (prod == 0 && sigC == 0) begin
            if ((sa ^ sb) == sc) sign_zero = (sa ^ sb);
            else                 sign_zero = (rnd == 2);
        end else begin
            sign_zero = (rnd == 2);
        end
        flags = 5'b00000;
        return {sign_zero, 8'h00, 7'h0};
    end

    if (S_floor[SUMW-1]) begin
        sign_out = 1'b1;
        Msum     = -S_floor;
    end else begin
        sign_out = 1'b0;
        Msum     = S_floor;
    end

    msb_pos = -1;
    for (i = SUMW-1; i >= 0; i = i - 1) begin
        if (Msum[i]) begin
            msb_pos = i;
            break;
        end
    end

    E = B + msb_pos;

    if (E < EMIN) target_LSB = EMIN - (P-1);
    else          target_LSB = E - (P-1);

    sh = target_LSB - B;
    if (sh <= 0) begin
        integer_part = Msum << (-sh);
        rem          = 0;
        inexact      = st;
        guard        = 0;
        sticky_low   = st;
    end else begin
        integer_part = Msum >> sh;
        rem          = Msum - (integer_part << sh);
        inexact      = (rem != 0) || st;
        guard        = (Msum >> (sh-1)) & 1'b1;
        if (rem == 0) begin
            sticky_low = st;
        end else if (guard == 0) begin
            sticky_low = 1'b1;
        end else begin
            sticky_low = ((rem & (rem - 1)) != 0) || st;
        end
    end

    inc = 0;
    case (rnd)
        0: begin
            if (guard && (sticky_low || integer_part[0])) inc = 1;
        end
        1: inc = 0;
        2: begin
            if (sign_out && (guard || sticky_low)) inc = 1;
        end
        3: begin
            if (!sign_out && (guard || sticky_low)) inc = 1;
        end
        4: begin
            if (guard) inc = 1;
        end
        default: inc = 0;
    endcase

    Q = integer_part + inc;

    if (E < EMIN) begin
        if (Q < (1 << (P-1))) begin
            exp_field = 0;
            frac      = Q[MW-1:0];
        end else begin
            exp_field = 1;
            frac      = 0;
        end
        fl = 5'b00000;
        fl[0] = inexact;
        fl[1] = inexact && (exp_field == 0);
        flags = fl;
        return {sign_out, exp_field, frac};
    end else begin
        if (Q >= (1 << P)) begin
            E_final = E + 1;
            Q       = (1 << (P-1));
        end else begin
            E_final = E;
        end
        if (E_final > EMAX) begin
            flags = 5'b00101;
            return {sign_out, 8'hFF, 7'b0};
        end
        exp_field = E_final + BIAS;
        frac      = Q - (1 << (P-1));
        fl = 5'b00000;
        fl[0] = inexact;
        fl[1] = 1'b0;
        flags = fl;
        return {sign_out, exp_field, frac};
    end
  endfunction

  // ---------------------------------------------------------------------------
  // Vectorised lane processing
  // ---------------------------------------------------------------------------
  always_comb begin
    logic [WIDTH-1:0] res_tmp;
    logic [4:0]       flags_tmp;
    int               N, fw, offset;
    logic [31:0]      al32, bl32, cl32, r32;
    logic [15:0]      al16, bl16, cl16, r16;
    logic [4:0]       lf;
    int               k;

    res_tmp   = {WIDTH{1'b1}};
    flags_tmp = 5'b0;
    fw        = (fmt_i == 0) ? 32 : 16;
    N         = vec_i ? (WIDTH / fw) : 1;

    for (k = 0; k < WIDTH/16; k = k + 1) begin
        if (k < N) begin
            offset = k * fw;
            if (fmt_i == 0) begin
                al32 = a_i[offset +: 32];
                bl32 = b_i[offset +: 32];
                cl32 = c_i[offset +: 32];
                r32  = fma32(al32, bl32, cl32, rnd_i, lf);
                res_tmp[offset +: 32] = r32;
            end else if (fmt_i == 1) begin
                al16 = a_i[offset +: 16];
                bl16 = b_i[offset +: 16];
                cl16 = c_i[offset +: 16];
                r16  = fma16(al16, bl16, cl16, rnd_i, lf);
                res_tmp[offset +: 16] = r16;
            end else begin
                al16 = a_i[offset +: 16];
                bl16 = b_i[offset +: 16];
                cl16 = c_i[offset +: 16];
                r16  = fma_bf16(al16, bl16, cl16, rnd_i, lf);
                res_tmp[offset +: 16] = r16;
            end
            flags_tmp = flags_tmp | lf;
        end
    end

    result_o = res_tmp;
    flags_o  = flags_tmp;
  end

  // Fully combinational handshake (L4 conformant)
  assign in_ready_o  = out_ready_i;
  assign out_valid_o = in_valid_i;

endmodule
