// =============================================================================
// fp_multifmt_fma.sv -- multi-format (FP32 / FP16 / BF16) SIMD fused multiply-add
// =============================================================================
//  * one rounding of the exact a*b + c   (true FMA)
//  * subnormal operands and subnormal results at full precision, all formats
//  * WIDTH/16 shared 16-bit-granular cores; FP32 lanes use the even cores
//  * one pipeline stage, 1 op/cycle, in-order, latency 1
// =============================================================================

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
  // constants
  // ---------------------------------------------------------------------------
  localparam int unsigned NC  = WIDTH/16;   // number of 16-bit-granular cores
  localparam int unsigned S1W = 134;        // stage-1 payload width per core

  // ---------------------------------------------------------------------------
  // pack a result word for the selected format
  // ---------------------------------------------------------------------------
  function automatic logic [31:0] pack_fp(input logic       s,
                                          input logic [7:0] e,
                                          input logic [22:0] m,
                                          input logic [1:0]  fmt);
    begin
      if (fmt == 2'd0)      pack_fp = {s, e, m};
      else if (fmt == 2'd1) pack_fp = {16'h0000, s, e[4:0], m[9:0]};
      else                  pack_fp = {16'h0000, s, e, m[6:0]};
    end
  endfunction

  // ---------------------------------------------------------------------------
  // unpack + normalise one operand
  //   [44]=sign [43]=nan [42]=snan [41]=inf [40]=zero
  //   [39:16]=24-bit normalised significand   [15:0]=signed exponent
  // ---------------------------------------------------------------------------
  function automatic logic [44:0] fp_unpack(input logic [31:0] x,
                                            input logic [1:0]  fmt);
    logic               sgn;
    logic [7:0]         ef;
    logic [22:0]        mf;
    logic [23:0]        sigr;
    logic [23:0]        signorm;
    logic               emax_f, ezero_f, mzero_f;
    logic               f_nan, f_snan, f_inf, f_zero;
    logic signed [15:0] ev;
    logic signed [15:0] biasv;
    logic signed [15:0] lz;
    int                 i;
    begin
      if (fmt == 2'd0) begin
        sgn = x[31]; ef = x[30:23];        mf = x[22:0];
      end else if (fmt == 2'd1) begin
        sgn = x[15]; ef = {3'b000, x[14:10]}; mf = {x[9:0], 13'b0};
      end else begin
        sgn = x[15]; ef = x[14:7];         mf = {x[6:0], 16'b0};
      end
      biasv   = (fmt == 2'd1) ? 16'sd15 : 16'sd127;
      emax_f  = (fmt == 2'd1) ? (ef == 8'd31) : (ef == 8'd255);
      ezero_f = (ef == 8'd0);
      mzero_f = (mf == 23'd0);
      f_zero  = ezero_f & mzero_f;
      f_inf   = emax_f  & mzero_f;
      f_nan   = emax_f  & ~mzero_f;
      f_snan  = f_nan   & ~mf[22];

      sigr = {~ezero_f, mf};
      lz   = 16'sd0;
      for (i = 0; i < 24; i = i + 1) if (sigr[i]) lz = 16'sd23 - i;
      signorm = sigr << lz;

      if (f_zero | f_inf | f_nan) begin
        signorm = 24'd0;
        ev      = 16'sd1 - biasv;
      end else if (ezero_f) begin
        ev      = 16'sd1 - biasv - lz;
      end else begin
        ev      = $signed({8'b0, ef}) - biasv;
      end
      fp_unpack = {sgn, f_nan, f_snan, f_inf, f_zero, signorm, ev};
    end
  endfunction

  // ---------------------------------------------------------------------------
  // stage 1 : classify, normalise, multiply, align, add
  //   payload  [77:0]=|sum|  [78]=sign  [94:79]=frame exponent
  //            [95]=special  [127:96]=special result  [132:128]=special flags
  //            [133]=addend bits shifted out of the bottom (sticky)
  //
  //   field unit weight = 2^(fexp-49); product at [50:3], addend at [76:0].
  //   The alignment shift is clamped at both ends: past either clamp the
  //   smaller term is provably below the rounding position of the result, so
  //   it only has to survive as a sticky bit (and as a borrow).
  // ---------------------------------------------------------------------------
  function automatic logic [S1W-1:0] fma_s1(input logic [31:0] a,
                                            input logic [31:0] b,
                                            input logic [31:0] c,
                                            input logic [1:0]  fmt,
                                            input logic [2:0]  rnd);
    logic [44:0]        ua, ub, uc;
    logic               sa, sb, sc, ps, subop;
    logic               na, nb, nc, sna, snb, snc, ia, ib, ic, za, zb, zc;
    logic [23:0]        siga, sigb, sigc;
    logic signed [15:0] ea, eb, ec, pexp, dexp, fexp;
    logic [47:0]        prod;
    logic [76:0]        addf, prodf;
    logic [77:0]        sum78, dif78, summag;
    logic               rsign;
    logic [31:0]        qn, spec_res;
    logic [4:0]         spec_fl;
    logic               spec_v;
    int                 shamt, shl;
    logic signed [15:0] shamt_t, eoff;
    logic [31:0]        lmask;
    logic               lost;
    begin
      ua = fp_unpack(a, fmt);
      ub = fp_unpack(b, fmt);
      uc = fp_unpack(c, fmt);
      sa = ua[44]; na = ua[43]; sna = ua[42]; ia = ua[41]; za = ua[40];
      sb = ub[44]; nb = ub[43]; snb = ub[42]; ib = ub[41]; zb = ub[40];
      sc = uc[44]; nc = uc[43]; snc = uc[42]; ic = uc[41]; zc = uc[40];
      siga = ua[39:16]; ea = ua[15:0];
      sigb = ub[39:16]; eb = ub[15:0];
      sigc = uc[39:16]; ec = uc[15:0];
      ps = sa ^ sb;
      qn = (fmt == 2'd0) ? 32'h7FC00000 :
           (fmt == 2'd1) ? 32'h00007E00 : 32'h00007FC0;

      // ---- special cases ----------------------------------------------------
      spec_v   = 1'b1;
      spec_res = qn;
      spec_fl  = 5'b00000;
      if (sna | snb | snc | (ia & zb) | (za & ib)) begin
        spec_res = qn;             spec_fl = 5'b10000;
      end else if (na | nb | nc) begin
        spec_res = qn;             spec_fl = 5'b00000;
      end else if (ia | ib) begin
        if (ic & (sc != ps)) begin spec_res = qn; spec_fl = 5'b10000; end
        else                       spec_res = pack_fp(ps, 8'hFF, 23'd0, fmt);
      end else if (ic) begin
        spec_res = pack_fp(sc, 8'hFF, 23'd0, fmt);
      end else if (za | zb) begin
        if (zc) spec_res = pack_fp((ps == sc) ? sc : (rnd == 3'd2),
                                   8'h00, 23'd0, fmt);
        else    spec_res = (fmt == 2'd0) ? c : {16'h0000, c[15:0]};
      end else begin
        spec_v = 1'b0;
      end

      // ---- exact product + aligned addend -----------------------------------
      prod  = siga * sigb;
      pexp  = ea + eb;
      dexp    = pexp - ec;
      shamt_t = dexp + 16'sd27;                  // exact alignment shift
      if      (zc)                shamt = 0;
      else if (shamt_t <= 16'sd0) shamt = 0;
      else if (shamt_t >= 16'sd77) shamt = 77;
      else                         shamt = shamt_t;
      // when the addend is clamped high the whole frame moves with it
      eoff = (zc | (shamt_t >= 16'sd0)) ? 16'sd0 : -shamt_t;
      fexp = pexp + eoff;
      addf  = zc ? 77'd0 : ({sigc, 53'd0} >> shamt);
      prodf = {26'd0, prod, 3'd0};
      subop = ps ^ sc;

      // addend bits pushed out of the bottom of the field: they are far below
      // the rounding position, so they only survive as a sticky -- but a
      // subtraction has to borrow for them
      shl   = (shamt_t > 16'sd53) ? ((shamt_t >= 16'sd77) ? 24 : (shamt_t - 16'sd53)) : 0;
      lmask = (32'd1 << shl) - 32'd1;
      lost  = (~zc) & (|(sigc & lmask[23:0]));

      sum78  = {1'b0, addf} + {1'b0, prodf};
      dif78  = {1'b0, addf} - {1'b0, prodf};
      if (!subop) begin
        summag = sum78;
        rsign  = ps;
      end else if (dif78[77]) begin
        // |P - A| - eps  ==  (|P - A| - 1) + (1 - eps)
        summag = (~dif78) + {77'd0, ~(lost)};
        rsign  = ps;
      end else begin
        summag = dif78;
        rsign  = sc;
      end

      fma_s1 = {lost, spec_fl, spec_res, spec_v, fexp, rsign, summag};
    end
  endfunction

  // ---------------------------------------------------------------------------
  // stage 2 : normalise, round once, pack, flags
  // ---------------------------------------------------------------------------
  function automatic logic [36:0] fma_s2(input logic [S1W-1:0] s1,
                                         input logic [1:0]     fmt,
                                         input logic [2:0]     rnd);
    logic [77:0]        summag;
    logic [79:0]        sum80, mask80, shifted;
    logic               rsign, spec_v, lostb;
    logic signed [15:0] pexp;
    logic [31:0]        spec_res, res, keepv, rounded;
    logic [4:0]         spec_fl, fl;
    logic [22:0]        mant;
    logic               g, st, rup, nx, unf, to_inf;
    int                 i, msb, shp, shn, precv, expwv, gidx;
    logic signed [31:0] npos, subpos, lsbp, e_lsb, bexp, biasv;
    begin
      summag   = s1[77:0];
      rsign    = s1[78];
      pexp     = s1[94:79];
      spec_v   = s1[95];
      spec_res = s1[127:96];
      spec_fl  = s1[132:128];
      lostb    = s1[133];

      precv = (fmt == 2'd0) ? 24 : (fmt == 2'd1) ? 11 : 8;
      expwv = (fmt == 2'd1) ?  5 : 8;
      biasv = (fmt == 2'd1) ? 32'sd15 : 32'sd127;

      sum80 = {2'b00, summag};
      msb   = 0;
      for (i = 0; i < 78; i = i + 1) if (summag[i]) msb = i;

      npos   = msb - precv + 1;                             // normal  lsb pos
      subpos = 32'sd1 - biasv - precv + 32'sd50 - pexp;     // subnormal lsb pos
      lsbp   = (npos > subpos) ? npos : subpos;
      shp    = (lsbp > 0) ? ((lsbp > 80) ? 80 : lsbp) : 0;
      shn    = (lsbp < 0) ? -lsbp : 0;

      mask80  = ~({80{1'b1}} << shp);
      shifted = (sum80 >> shp) << shn;
      keepv   = shifted[31:0];
      gidx    = (shp == 0) ? 0 : (shp - 1);
      g       = (shp != 0) & sum80[gidx];
      st      = lostb | (|(sum80 & (mask80 >> 1)));
      e_lsb   = lsbp + pexp - 32'sd49;

      rup = (rnd == 3'd0) ? (g & (st | keepv[0])) :
            (rnd == 3'd1) ? 1'b0                  :
            (rnd == 3'd2) ? (rsign & (g | st))    :
            (rnd == 3'd3) ? ((~rsign) & (g | st)) : g;
      rounded = keepv + {31'd0, rup};
      nx      = g | st;
      mant    = rounded[22:0];

      if      (rounded[precv])     bexp = e_lsb + precv + biasv;
      else if (rounded[precv-1])   bexp = e_lsb + precv - 32'sd1 + biasv;
      else                         bexp = 32'sd0;

      to_inf = (rnd == 3'd0) | (rnd == 3'd4) |
               ((rnd == 3'd2) & rsign) | ((rnd == 3'd3) & (~rsign));

      unf = 1'b0;
      if (summag == 78'd0) begin                         // exact cancellation
        res = pack_fp(rnd == 3'd2, 8'h00, 23'd0, fmt);
        fl  = 5'b00000;
      end else if (rounded == 32'd0) begin               // rounds to zero
        res = pack_fp(rsign, 8'h00, 23'd0, fmt);
        fl  = {3'b000, nx, nx};
      end else if (bexp >= ((32'sd1 << expwv) - 32'sd1)) begin
        res = to_inf ? pack_fp(rsign, 8'hFF, 23'd0,      fmt)
                     : pack_fp(rsign, 8'hFE, 23'h7FFFFF, fmt);
        fl  = 5'b00101;                                  // OF | NX
      end else begin
        res = pack_fp(rsign, bexp[7:0], mant, fmt);
        unf = nx & (bexp == 32'sd0);
        fl  = {3'b000, unf, nx};
      end

      if (spec_v) begin
        res = spec_res;
        fl  = spec_fl;
      end
      fma_s2 = {res, fl};
    end
  endfunction

  // ---------------------------------------------------------------------------
  // pipeline registers
  // ---------------------------------------------------------------------------
  logic                 v1, adv;
  logic [1:0]           fmt_q, fmt_q2;
  logic                 vec_q2;
  logic [2:0]           rnd_q, rnd_q2;
  logic [S1W-1:0]       s1_d [NC];
  logic [S1W-1:0]       s1_q [NC];
  logic [36:0]          s2_r [NC];
  logic [31:0]          a_ln [NC];
  logic [31:0]          b_ln [NC];
  logic [31:0]          c_ln [NC];
  logic [1:0]           fmt_ln [NC];
  logic [1:0]           fmt2_ln [NC];
  logic [15:0]          slots [NC];
  logic [WIDTH+31:0]    a_ext, b_ext, c_ext;

  assign adv         = (~v1) | out_ready_i;
  assign in_ready_o  = adv;
  assign out_valid_o = v1;

  assign fmt_q = fmt_i;
  assign rnd_q = rnd_i;
  assign a_ext = {32'h0, a_i};
  assign b_ext = {32'h0, b_i};
  assign c_ext = {32'h0, c_i};

  // ---- per-core operand selection -------------------------------------------
  always_comb begin
    int j;
    for (j = 0; j < int'(NC); j = j + 1) begin
      if ((fmt_q == 2'd0) && ((j % 2) == 0)) begin
        a_ln[j] = a_ext[j*16 +: 32];
        b_ln[j] = b_ext[j*16 +: 32];
        c_ln[j] = c_ext[j*16 +: 32];
      end else begin
        a_ln[j] = {16'h0000, a_ext[j*16 +: 16]};
        b_ln[j] = {16'h0000, b_ext[j*16 +: 16]};
        c_ln[j] = {16'h0000, c_ext[j*16 +: 16]};
      end
      // odd cores never see FP32: pinning the format there lets the tools drop
      // the wide significand path in half of the cores
      fmt_ln[j]  = ((j % 2) == 1) ? (fmt_q[1]  ? 2'd2 : 2'd1) : fmt_q;
      fmt2_ln[j] = ((j % 2) == 1) ? (fmt_q2[1] ? 2'd2 : 2'd1) : fmt_q2;
    end
  end

  // ---- stage 1 / stage 2 datapaths ------------------------------------------
  always_comb begin
    int j;
    for (j = 0; j < int'(NC); j = j + 1)
      s1_d[j] = fma_s1(a_ln[j], b_ln[j], c_ln[j], fmt_ln[j], rnd_q);
  end

  always_comb begin
    int j;
    for (j = 0; j < int'(NC); j = j + 1)
      s2_r[j] = fma_s2(s1_q[j], fmt2_ln[j], rnd_q2);
  end

  // ---- lane assembly ---------------------------------------------------------
  //  narrow format : 16-bit slot j comes from core j
  //  FP32          : lane j/2 lives in cores j and j+1's slots, both driven by
  //                  the even core.  Slots above the lanes in use read all ones.
  always_comb begin
    int j;
    int nlanes;
    logic act;
    flags_o = 5'b00000;
    if (fmt_q2 == 2'd0) nlanes = vec_q2 ? int'(WIDTH/32) : 1;
    else                nlanes = vec_q2 ? int'(WIDTH/16) : 1;
    for (j = 0; j < int'(NC); j = j + 1) begin
      slots[j] = 16'hFFFF;
      act      = 1'b0;
      if (fmt_q2 == 2'd0) begin
        if ((j/2) < nlanes) begin
          act = 1'b1;
          if ((j % 2) == 0) slots[j] = s2_r[j][20:5];
          else              slots[j] = s2_r[j-1][36:21];
        end
      end else begin
        if (j < nlanes) begin
          act      = 1'b1;
          slots[j] = s2_r[j][20:5];
        end
      end
      if (act && ((fmt_q2 != 2'd0) || ((j % 2) == 0)))
        flags_o = flags_o | s2_r[j][4:0];
    end
  end

  for (genvar gk = 0; gk < int'(NC); gk = gk + 1) begin : g_slot
    assign result_o[gk*16 +: 16] = slots[gk];
  end

  // ---- sequential ------------------------------------------------------------
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) v1 <= 1'b0;
    else if (adv) v1 <= in_valid_i;
  end

  always_ff @(posedge clk_i) begin
    if (adv) begin
      for (int k = 0; k < int'(NC); k = k + 1) s1_q[k] <= s1_d[k];
      fmt_q2 <= fmt_i;
      vec_q2 <= vec_i;
      rnd_q2 <= rnd_i;
    end
  end

endmodule
