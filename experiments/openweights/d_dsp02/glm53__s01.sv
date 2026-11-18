`timescale 1ns/1ps
// =============================================================================
// fp32_fma_ii1 -- IEEE-754 binary32 fused multiply-add, (a*b)+c, single rounding
// 3-cycle pipeline, II=1. Subnormals full precision, 5 rounding modes,
// canonical NaN, underflow = inexact AND delivered exponent field == 0.
// Internal significand datapath: 53 bits (< 96-bit bound).
// =============================================================================
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

  // ---------------- priority encoders ----------------
  function automatic [4:0] msb23(input logic [22:0] v);
    int i;
    begin
      msb23 = 5'd0;
      for (i = 0; i < 23; i = i + 1)
        if (v[i]) msb23 = i[4:0];
    end
  endfunction

  function automatic [5:0] msb53(input logic [52:0] v);
    int i;
    begin
      msb53 = 6'd0;
      for (i = 0; i < 53; i = i + 1)
        if (v[i]) msb53 = i[5:0];
    end
  endfunction

  // ---------------- stage 1: classify / normalise / multiply ----------------
  wire        sa   = a[31];
  wire [7:0]  expa = a[30:23];
  wire [22:0] ma   = a[22:0];
  wire        sb   = b[31];
  wire [7:0]  expb = b[30:23];
  wire [22:0] mb   = b[22:0];
  wire        sc   = c[31];
  wire [7:0]  expc = c[30:23];
  wire [22:0] mc   = c[22:0];

  wire a_nan  = (expa == 8'd255) & (ma != 23'd0);
  wire a_inf  = (expa == 8'd255) & (ma == 23'd0);
  wire a_zero = (expa == 8'd0)   & (ma == 23'd0);
  wire a_sub  = (expa == 8'd0)   & (ma != 23'd0);
  wire b_nan  = (expb == 8'd255) & (mb != 23'd0);
  wire b_inf  = (expb == 8'd255) & (mb == 23'd0);
  wire b_zero = (expb == 8'd0)   & (mb == 23'd0);
  wire b_sub  = (expb == 8'd0)   & (mb != 23'd0);
  wire c_nan  = (expc == 8'd255) & (mc != 23'd0);
  wire c_inf  = (expc == 8'd255) & (mc == 23'd0);
  wire c_zero = (expc == 8'd0)   & (mc == 23'd0);
  wire c_sub  = (expc == 8'd0)   & (mc != 23'd0);

  wire any_nan  = a_nan | b_nan | c_nan;
  wire any_snan = (a_nan & ~a[22]) | (b_nan & ~b[22]) | (c_nan & ~c[22]);
  wire ps        = sa ^ sb;
  wire prod_inf  = (a_inf | b_inf) & ~(a_zero | b_zero);
  wire inv_sp = any_snan
              | ((a_inf | b_inf) & (a_zero | b_zero))
              | (prod_inf & c_inf & (sc != ps));
  wire zsign = (ps == sc) ? ps : (rnd_mode == 3'd2);
  wire sp = any_nan | a_inf | b_inf | c_inf | a_zero | b_zero;
  wire [31:0] sp_res = any_nan         ? 32'h7FC00000 :
                       inv_sp          ? 32'h7FC00000 :
                       (a_inf | b_inf) ? {ps, 8'hFF, 23'd0} :
                       c_inf           ? {sc, 8'hFF, 23'd0} :
                       c_zero          ? {zsign, 31'd0} : c;

  wire [4:0]  lza = msb23(ma);
  wire [4:0]  lzb = msb23(mb);
  wire [4:0]  lzc = msb23(mc);
  wire [23:0] A24 = a_sub ? (ma << (5'd23 - lza)) : {1'b1, ma};
  wire [23:0] B24 = b_sub ? (mb << (5'd23 - lzb)) : {1'b1, mb};
  wire [23:0] C24 = c_sub ? (mc << (5'd23 - lzc)) :
                    (c_zero ? 24'd0 : {1'b1, mc});

  wire [47:0] P48    = A24 * B24;
  wire        eff_sub = ps ^ sc;

  logic signed [8:0]  Ea, Eb, Ec;
  logic signed [10:0] diff;
  logic               regB_v;
  logic signed [12:0] E0;

  always_comb begin
    Ea = a_sub ? ($signed({1'b0, lza}) - 9'sd149)
               : ($signed({1'b0, expa}) - 9'sd127);
    Eb = b_sub ? ($signed({1'b0, lzb}) - 9'sd149)
               : ($signed({1'b0, expb}) - 9'sd127);
    Ec = c_sub ? ($signed({1'b0, lzc}) - 9'sd149)
               : ($signed({1'b0, expc}) - 9'sd127);
    diff = c_zero ? 11'sd100 : (Ea + Eb - Ec - 11'sd23);
    regB_v = (diff <= -26);
    E0 = regB_v ? (Ec - 13'sd28) : (Ea + Eb - 13'sd49);
  end

  // ---------------- pipeline registers: stage1 -> stage2 ----------------
  logic        v1, v2, v3;
  logic [47:0] P_r;
  logic [23:0] C_r;
  logic        ps_r, sc_r, eff_r, regB_r, sp_r, spinv_r;
  logic signed [10:0] diff_r;
  logic signed [12:0] E0_r;
  logic [31:0] spres_r;
  logic [2:0]  rnd_r;

  // ---------------- stage 2: align + add ----------------
  wire [26:0] add_base  = {C_r, 3'd0};
  wire [50:0] prod_base = {P_r, 3'd0};

  logic signed [10:0] nmA;
  logic signed [10:0] sP_s;
  logic [4:0]  sA, lA;
  logic [5:0]  sPc;
  logic [51:0] add_vecA, prod_vecB;
  logic        stkA, stkP;
  logic [51:0] add_vec, prod_vec;
  logic        stk2;
  logic signed [52:0] S53;
  logic        neg2;
  logic [52:0] S_mag2;
  logic        res_sign2;

  always_comb begin
    sA       = 5'd0;
    lA       = 5'd0;
    add_vecA = 52'd0;
    stkA     = 1'b0;
    nmA      = 11'sd0;
    sP_s     = 11'sd0;
    sPc      = 6'd0;
    prod_vecB = 52'd0;
    stkP     = 1'b0;
    // regime A: addend aligned against fixed product (bits [50:3])
    if (diff_r >= 0) begin
      if (diff_r > 27) sA = 5'd27; else sA = diff_r[4:0];
      add_vecA = {25'd0, add_base} >> sA;
      stkA = |(add_base & (27'h7FFFFFF >> (5'd27 - sA)));
    end else begin
      nmA = -diff_r;
      if (nmA > 25) lA = 5'd25; else lA = nmA[4:0];
      add_vecA = {25'd0, add_base} << lA;
    end
    // regime B: product shifted below fixed addend (bits [28:5])
    sP_s = -diff_r - 11'sd2;
    if (sP_s > 51) sPc = 6'd51; else sPc = sP_s[5:0];
    prod_vecB = {1'd0, prod_base} >> sPc;
    stkP = |(prod_base & (51'h7FFFFFFFFFFFF >> (6'd51 - sPc)));
    // regime select + 53-bit two's-complement add
    add_vec  = regB_r ? ({23'd0, C_r} << 5) : add_vecA;
    prod_vec = regB_r ? prod_vecB : {1'd0, prod_base};
    stk2     = regB_r ? stkP : stkA;
    S53 = eff_r ? ($signed({1'd0, prod_vec}) - $signed({1'd0, add_vec}))
                : ($signed({1'd0, prod_vec}) + $signed({1'd0, add_vec}));
    neg2 = S53[52];
    S_mag2 = neg2 ? (~S53 + 53'sd1) : S53;
    res_sign2 = neg2 ? sc_r : ps_r;
  end

  // ---------------- pipeline registers: stage2 -> stage3 ----------------
  logic [52:0] S_mag;
  logic        stk;
  logic signed [12:0] E0q;
  logic        rsign;
  logic        sp_q, spinv_q;
  logic [31:0] spres_q;
  logic [2:0]  rnd_q;

  // ---------------- stage 3: normalise + round + flags ----------------
  logic [5:0]         L;
  logic signed [12:0] Eres, e_s, fin_e, rr;
  logic [52:0]        T;
  logic [23:0]        upper;
  logic               g, r, st;
  logic               inc_n;
  logic [24:0]        mant25;
  logic               carry;
  logic [7:0]         biased;
  logic               of_inf;
  logic [31:0]        res_n;
  logic               nx_n, of_n;
  logic [23:0]        M;
  logic               mg, mr, mst;
  logic               inc_s;
  logic [24:0]        Mi25;
  logic [31:0]        res_s;
  logic               nx_s;
  logic [55:0]        Spad;
  logic [5:0]         rc, gi, ri;
  logic [31:0]        res_f;
  logic               inv_f, of_f, uf_f, nx_f;

  always_comb begin
    L      = msb53(S_mag);
    Eres   = E0q + $signed({7'd0, L});
    // ---- normal-result path (Eres >= -126) ----
    T      = S_mag << (6'd52 - L);
    upper  = T[52:29];
    g      = T[28];
    r      = T[27];
    st     = (|T[26:0]) | stk;
    inc_n  = 1'b0;
    case (rnd_q)
      3'd0:    inc_n = g & (r | st | upper[0]);
      3'd1:    inc_n = 1'b0;
      3'd2:    inc_n = rsign & (g | r | st);
      3'd3:    inc_n = (~rsign) & (g | r | st);
      default: inc_n = g; // 4 = RMM
    endcase
    mant25 = {1'd0, upper} + {24'd0, inc_n};
    carry  = mant25[24];
    fin_e  = Eres + (carry ? 13'sd1 : 13'sd0);
    nx_n   = g | r | st;
    of_inf = (rnd_q == 3'd0) | (rnd_q == 3'd4) |
             ((rnd_q == 3'd2) & rsign) | ((rnd_q == 3'd3) & ~rsign);
    of_n   = 1'b0;
    biased = 8'd0;
    res_n  = 32'd0;
    if (fin_e >= 128) begin
      of_n = 1'b1;
      nx_n = 1'b1;
      res_n = of_inf ? {rsign, 8'hFF, 23'd0} : {rsign, 8'hFE, 23'h7FFFFF};
    end else begin
      biased = fin_e[7:0] + 8'd127;
      res_n  = {rsign, biased, mant25[23:0]};
    end
    // ---- subnormal / zero-result path (Eres <= -127) ----
    e_s = E0q + 13'sd149;
    M   = 24'd0;
    mg  = 1'b0;
    mr  = 1'b0;
    mst = 1'b0;
    rr  = 13'sd0;
    rc  = 6'd0;
    gi  = 6'd0;
    ri  = 6'd0;
    Spad = 56'd0;
    if (e_s >= 0) begin
      M = S_mag << e_s[4:0];      // exact, sticky is provably 0 here
    end else begin
      rr = -e_s;
      if (rr > 55) rc = 6'd55; else rc = rr[5:0];
      Spad = {3'd0, S_mag};
      M = Spad >> ({1'd0, rc} + 7'd3);
      if (rc > 53) gi = 6'd55; else gi = rc + 6'd2;
      if (rc > 54) ri = 6'd55; else ri = rc + 6'd1;
      mg  = (rc <= 53) ? Spad[gi] : 1'b0;
      mr  = (rc <= 54) ? Spad[ri] : 1'b0;
      mst = (|(Spad & (56'hFFFFFFFFFFFFFF >> (6'd55 - rc)))) | stk;
    end
    inc_s = 1'b0;
    case (rnd_q)
      3'd0:    inc_s = mg & (mr | mst | M[0]);
      3'd1:    inc_s = 1'b0;
      3'd2:    inc_s = rsign & (mg | mr | mst);
      3'd3:    inc_s = (~rsign) & (mg | mr | mst);
      default: inc_s = mg;
    endcase
    Mi25 = {1'd0, M} + {24'd0, inc_s};
    res_s = {rsign, (Mi25[24] ? 8'd1 : 8'd0), (Mi25[24] ? 24'd0 : Mi25[23:0])};
    nx_s  = mg | mr | mst;
    // ---- final select ----
    if (sp_q) begin
      res_f = spres_q; inv_f = spinv_q; of_f = 1'b0; nx_f = 1'b0;
    end else if (S_mag == 53'd0) begin
      res_f = {(rnd_q == 3'd2), 31'd0};
      inv_f = 1'b0; of_f = 1'b0; nx_f = 1'b0;
    end else if (Eres >= -126) begin
      res_f = res_n; inv_f = 1'b0; of_f = of_n; nx_f = nx_n;
    end else begin
      res_f = res_s; inv_f = 1'b0; of_f = 1'b0; nx_f = nx_s;
    end
    uf_f = nx_f & (~sp_q) & (res_f[30:23] == 8'd0);
  end

  // ---------------- handshake / pipeline control ----------------
  logic stall;
  assign stall    = v3 & ~out_ready;
  assign in_ready = rst_n & ~stall;
  assign out_valid = v3;

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      v1 <= 1'b0;
      v2 <= 1'b0;
      v3 <= 1'b0;
    end else if (!stall) begin
      v1 <= in_valid;
      v2 <= v1;
      v3 <= v2;
      P_r     <= P48;
      C_r     <= C24;
      ps_r    <= ps;
      sc_r    <= sc;
      eff_r   <= eff_sub;
      regB_r  <= regB_v;
      diff_r  <= diff;
      E0_r    <= E0;
      sp_r    <= sp;
      spres_r <= sp_res;
      spinv_r <= inv_sp;
      rnd_r   <= rnd_mode;
      S_mag   <= S_mag2;
      stk     <= stk2;
      E0q     <= E0_r;
      rsign   <= res_sign2;
      sp_q    <= sp_r;
      spres_q <= spres_r;
      spinv_q <= spinv_r;
      rnd_q   <= rnd_r;
      result        <= res_f;
      flag_invalid  <= inv_f;
      flag_overflow <= of_f;
      flag_underflow<= uf_f;
      flag_inexact  <= nx_f;
    end
  end

endmodule
