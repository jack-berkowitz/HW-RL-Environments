// =============================================================================
// fp_multifmt_fma.sv
//
// Multi-format (FP32 / FP16 / BF16) SIMD fused multiply-add.
//
// ORGANISATION
//   One lane core, instantiated WIDTH/16 times.  Lanes [0 .. WIDTH/32-1] are
//   format-agnostic (they serve the FP32 lanes as well as 16-bit lanes); the
//   remaining lanes are only ever handed FP16/BF16 operands, so their format
//   selector is constrained to {1,2} and their upper operand bits are tied to
//   zero, which lets the FP32 geometry constant-propagate out of them.
//
//   The lane core is split across one pipeline register:
//     fma_pre  : unpack, 24x24 product, addend alignment, signed add, |sum|
//     fma_post : normalise, subnormal clamp, round, encode, flags
//
// SIGNIFICAND DATAPATH (A8)
//   W = 3*p + 6 = 78 bits at p = 24 (FP32), i.e. below the 4*p = 96 bit
//   ceiling.  The window holds the 2p-bit product with two bits of headroom
//   below it and room for an addend up to p+3 binades above; everything that
//   falls outside is collapsed into a sticky bit, including the borrow that an
//   effective subtraction takes out of the bottom of the window.  The three
//   formats share these bits; nothing is carried at "unbounded" width.
//
// HANDSHAKE (H1, H2, L4, C1)
//   One elastic register stage:
//     in_ready_o  = !v_q || out_ready_i     (may depend on out_ready_i)
//     out_valid_o = v_q                     (never depends on out_ready_i)
//   Neither forbidden combinational path is used.  Results leave in the order
//   they were accepted, one per cycle when the sink is ready.
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

  localparam int W   = 78;            // 3*24 + 6 aligned significand window
  localparam int MW  = 99;            // width of the mid-pipeline lane word
  localparam int NL  = (WIDTH/16);    // 16-bit lane slots  (2 or 4)
  localparam int N32 = (WIDTH/32);    // 32-bit lane slots  (1 or 2)

  // ===========================================================================
  // Stage A : unpack, multiply, align, add.
  // Returns { mag[77:0], AB[11:0], rsign, exzero, stal, zeq, zs,
  //           nanout, inv, infout, infsign }
  //   mag    magnitude of the aligned exact sum, window bit 0 has weight ANC
  //   AB     ANC + bias, the exponent anchor of window bit 0
  //   stal   addend bits that fell below the window were non-zero
  // ===========================================================================
  function automatic logic [MW-1:0] fma_pre
  (
    input logic [1:0]  fmt,
    input logic [31:0] ain,
    input logic [31:0] bin,
    input logic [31:0] cin
  );
    // ---- declarations (all before any statement -- T2) ----------------------
    int P, BS;
    int Ea, Eb, Ec, TEP, TEC, EDv, EDu, ANC;
    int SHA, LST;
    logic [23:0] MMASK, IMPL, QBIT;
    logic [7:0]  EMASK;
    logic sa, sb, sc, sp, effsub;
    logic [7:0]  ea, eb, ec;
    logic [23:0] fa, fb, fc, siga, sigb, sigc;
    logic za, zb, ia, ib, ic, na, nb, nc, sna, snb, snc, inv, nanout;
    logic [47:0] prod48;
    logic [W-1:0] prodr, addnd, tsh, mag;
    logic signed [W+1:0] sums, sabs;
    logic signed [11:0] AB;
    logic neg, rsign, exzero, stal, infout, infsign;

    // ---- per-format geometry ------------------------------------------------
    case (fmt)
      2'd0: begin
        P = 24; BS = 127;
        MMASK = 24'h7FFFFF; IMPL = 24'h800000; QBIT = 24'h400000; EMASK = 8'hFF;
      end
      2'd1: begin
        P = 11; BS = 15;
        MMASK = 24'h0003FF; IMPL = 24'h000400; QBIT = 24'h000200; EMASK = 8'h1F;
      end
      default: begin
        P = 8; BS = 127;
        MMASK = 24'h00007F; IMPL = 24'h000080; QBIT = 24'h000040; EMASK = 8'hFF;
      end
    endcase

    // ---- unpack -------------------------------------------------------------
    if (fmt == 2'd0) begin
      sa = ain[31];      sb = bin[31];      sc = cin[31];
      ea = ain[30:23];   eb = bin[30:23];   ec = cin[30:23];
    end else if (fmt == 2'd1) begin
      sa = ain[15];      sb = bin[15];      sc = cin[15];
      ea = {3'b0, ain[14:10]};
      eb = {3'b0, bin[14:10]};
      ec = {3'b0, cin[14:10]};
    end else begin
      sa = ain[15];      sb = bin[15];      sc = cin[15];
      ea = ain[14:7];    eb = bin[14:7];    ec = cin[14:7];
    end

    fa = ain[23:0] & MMASK;
    fb = bin[23:0] & MMASK;
    fc = cin[23:0] & MMASK;

    za  = (ea == 8'd0)  && (fa == 24'd0);
    zb  = (eb == 8'd0)  && (fb == 24'd0);
    ia  = (ea == EMASK) && (fa == 24'd0);
    ib  = (eb == EMASK) && (fb == 24'd0);
    ic  = (ec == EMASK) && (fc == 24'd0);
    na  = (ea == EMASK) && (fa != 24'd0);
    nb  = (eb == EMASK) && (fb != 24'd0);
    nc  = (ec == EMASK) && (fc != 24'd0);
    sna = na && ((fa & QBIT) == 24'd0);
    snb = nb && ((fb & QBIT) == 24'd0);
    snc = nc && ((fc & QBIT) == 24'd0);

    siga = fa | ((ea != 8'd0) ? IMPL : 24'd0);
    sigb = fb | ((eb != 8'd0) ? IMPL : 24'd0);
    sigc = fc | ((ec != 8'd0) ? IMPL : 24'd0);

    Ea = (ea == 8'd0) ? 1 : int'(ea);
    Eb = (eb == 8'd0) ? 1 : int'(eb);
    Ec = (ec == 8'd0) ? 1 : int'(ec);

    sp     = sa ^ sb;
    effsub = sp ^ sc;

    // ---- exponents ----------------------------------------------------------
    // value(a) = siga * 2^(Ea-BS-(P-1));  TEP = true exponent of the product
    TEP = Ea + Eb - 2*BS;
    TEC = Ec - BS;
    EDv = TEC - TEP;

    prod48 = siga * sigb;

    // A zero product must let the addend anchor the window; a zero addend must
    // let the product anchor it.  Both are forced, not inferred.
    if (prod48 == 48'd0)     EDu = P + 8;
    else if (sigc == 24'd0)  EDu = -(3 * P);
    else                     EDu = EDv;

    // ---- alignment ----------------------------------------------------------
    // Window bit 0 has weight ANC.  The product sits at bits [2P+1:2] and the
    // addend LSB at bit (2P+4-SHA).  Both clamps place the smaller term far
    // enough below the other that only its sticky contribution can matter.
    if (EDu >= P + 3) begin
      SHA = 0;
      ANC = TEC - 3*P - 3;
    end else if (EDu <= -(2*P + 1)) begin
      SHA = 3*P + 4;
      ANC = TEP - 2*P;
    end else begin
      SHA = P + 3 - EDu;
      ANC = TEP - 2*P;
    end

    LST = SHA - (2*P + 4);
    if (LST < 0)  LST = 0;
    if (LST > 24) LST = 24;
    stal = |(sigc & ~({24{1'b1}} << LST));

    prodr = {{(W-50){1'b0}}, prod48, 2'b00};
    // Only three addend placements exist: a mux, not a barrel shifter.
    case (fmt)
      2'd0:    tsh = { 2'b0, sigc, 52'b0};
      2'd1:    tsh = {28'b0, sigc, 26'b0};
      default: tsh = {34'b0, sigc, 20'b0};
    endcase
    addnd = tsh >> SHA;

    // Effective subtraction with addend bits below the window: the discarded
    // part makes the true subtrahend larger than what the window holds, so one
    // unit is borrowed out of the bottom and the residual (1 - eps) keeps the
    // sticky bit set.  Without this the borrow never propagates and a result
    // just below a power of two comes out one ulp high.
    sums = $signed({2'b00, prodr})
         + (effsub ? -$signed({2'b00, addnd} + {{(W+1){1'b0}}, stal})
                   :  $signed({2'b00, addnd}));
    neg  = sums[W+1];
    sabs = neg ? -sums : sums;
    mag  = sabs[W-1:0];

    rsign  = neg ? ~sp : sp;
    exzero = (mag == {W{1'b0}}) && !stal;
    AB     = 12'(ANC + BS);

    inv    = sna | snb | snc
           | (ia & zb) | (za & ib)
           | ((ia | ib) & ic & (sp ^ sc) & ~(na | nb | nc));
    nanout  = inv | na | nb | nc;
    infout  = ~nanout & (ia | ib | ic);
    infsign = (ia | ib) ? sp : sc;

    fma_pre = {mag, AB, rsign, exzero, stal, (sp == sc), sp,
               nanout, inv, infout, infsign};
  endfunction

  // ===========================================================================
  // Stage B : normalise, subnormal clamp, round, encode.
  // Returns { result[31:0], flags[4:0] }.
  // ===========================================================================
  function automatic logic [36:0] fma_post
  (
    input logic [1:0]      fmt,
    input logic [2:0]      rnd,
    input logic [MW-1:0]   d
  );
    // ---- declarations (all before any statement -- T2) ----------------------
    int P;
    int SLS, EF, LZ, RST;
    logic [23:0] MMASK;
    logic [7:0]  EMASK;
    logic [31:0] QNANC, INFC, MAXC, SGNC;
    logic [W-1:0] mag, nz, ZZ, rmask;
    logic signed [11:0] AB;
    logic rsign, exzero, stal, zeq, zs, nanout, inv, infout, infsign;
    logic subres, zsign;
    logic [23:0] mantp, mantb;
    logic [24:0] mantr;
    logic guard, stick, strs, nxo, ufo, ofo, infres, rup, mcar;
    logic [15:0] efv;
    logic [31:0] res;
    logic [4:0]  fl;

    // ---- per-format geometry ------------------------------------------------
    case (fmt)
      2'd0: begin
        P = 24; MMASK = 24'h7FFFFF; EMASK = 8'hFF;
        QNANC = 32'h7FC00000; INFC = 32'h7F800000;
        MAXC  = 32'h7F7FFFFF; SGNC = 32'h80000000;
      end
      2'd1: begin
        P = 11; MMASK = 24'h0003FF; EMASK = 8'h1F;
        QNANC = 32'h00007E00; INFC = 32'h00007C00;
        MAXC  = 32'h00007BFF; SGNC = 32'h00008000;
      end
      default: begin
        P = 8;  MMASK = 24'h00007F; EMASK = 8'hFF;
        QNANC = 32'h00007FC0; INFC = 32'h00007F80;
        MAXC  = 32'h00007F7F; SGNC = 32'h00008000;
      end
    endcase

    mag     = d[MW-1 -: W];
    AB      = $signed(d[20:9]);
    rsign   = d[8];
    exzero  = d[7];
    stal    = d[6];
    zeq     = d[5];
    zs      = d[4];
    nanout  = d[3];
    inv     = d[2];
    infout  = d[1];
    infsign = d[0];

    // ---- normalise (binary search leading one; no runtime loop bound) -------
    nz = mag; LZ = 0;
    if (nz[W-1 -: 64] == 64'd0) begin nz = nz << 64; LZ = LZ + 64; end
    if (nz[W-1 -: 32] == 32'd0) begin nz = nz << 32; LZ = LZ + 32; end
    if (nz[W-1 -: 16] == 16'd0) begin nz = nz << 16; LZ = LZ + 16; end
    if (nz[W-1 -:  8] ==  8'd0) begin nz = nz <<  8; LZ = LZ +  8; end
    if (nz[W-1 -:  4] ==  4'd0) begin nz = nz <<  4; LZ = LZ +  4; end
    if (nz[W-1 -:  2] ==  2'd0) begin nz = nz <<  2; LZ = LZ +  2; end
    if (nz[W-1]       ==  1'b0) begin nz = nz <<  1; LZ = LZ +  1; end

    // Left shift that places the significand LSB at window bit W-P when the
    // result is a subnormal of the destination format.  It does not depend on
    // the leading one, so LZ <= SLS is exactly "the result is normal".
    SLS = int'(AB) + W - 2;

    if (LZ <= SLS) begin
      subres = 1'b0;
      RST    = 0;
      EF     = int'(AB) + W - 1 - LZ;
    end else begin
      subres = 1'b1;
      EF     = 0;
      if (SLS >= 0) RST = LZ - SLS;
      else          RST = LZ + ((-SLS > P + 1) ? (P + 1) : -SLS);
    end

    rmask = ~({W{1'b1}} << RST);
    strs  = |(nz & rmask);
    ZZ    = nz >> RST;

    case (fmt)
      2'd0: begin
        mantp = ZZ[W-1 -: 24];
        guard = ZZ[W-25];
        stick = (|ZZ[W-26:0]) | stal | strs;
      end
      2'd1: begin
        mantp = {13'b0, ZZ[W-1 -: 11]};
        guard = ZZ[W-12];
        stick = (|ZZ[W-13:0]) | stal | strs;
      end
      default: begin
        mantp = {16'b0, ZZ[W-1 -: 8]};
        guard = ZZ[W-9];
        stick = (|ZZ[W-10:0]) | stal | strs;
      end
    endcase

    // ---- round --------------------------------------------------------------
    case (rnd)
      3'd0:    rup = guard & (stick | mantp[0]);   // RNE
      3'd1:    rup = 1'b0;                         // RTZ
      3'd2:    rup = rsign  & (guard | stick);     // RDN
      3'd3:    rup = ~rsign & (guard | stick);     // RUP
      default: rup = guard;                        // RMM
    endcase

    mantr = {1'b0, mantp} + {24'b0, rup};
    mantb = mantr[23:0] & MMASK;

    // Carry out of the significand: bit P for a normal result, bit P-1 for a
    // subnormal one (where it promotes the result to the smallest normal).
    case (fmt)
      2'd0:    mcar = subres ? mantr[23] : mantr[24];
      2'd1:    mcar = subres ? mantr[10] : mantr[11];
      default: mcar = subres ? mantr[7]  : mantr[8];
    endcase
    if (subres) EF = mcar ? 1 : 0;
    else        EF = EF + (mcar ? 1 : 0);

    nxo = guard | stick;
    ofo = (EF >= int'(EMASK));
    ufo = nxo && (EF == 0);          // A7a: inexact and delivered exponent 0

    infres = (rnd == 3'd0) || (rnd == 3'd4)
          || ((rnd == 3'd3) && !rsign) || ((rnd == 3'd2) && rsign);

    zsign = zeq ? zs : ((rnd == 3'd2) ? 1'b1 : 1'b0);   // A6
    efv   = 16'(EF);

    // ---- assemble -----------------------------------------------------------
    if (nanout) begin
      res = QNANC;
      fl  = {inv, 4'b0000};
    end else if (infout) begin
      res = INFC | (infsign ? SGNC : 32'd0);
      fl  = 5'b00000;
    end else if (exzero) begin
      res = zsign ? SGNC : 32'd0;
      fl  = 5'b00000;
    end else if (ofo) begin
      res = (infres ? INFC : MAXC) | (rsign ? SGNC : 32'd0);
      fl  = 5'b00101;                                     // OF | NX
    end else begin
      case (fmt)
        2'd0:    res = {rsign, efv[7:0], mantb[22:0]};
        2'd1:    res = {16'h0000, rsign, efv[4:0], mantb[9:0]};
        default: res = {16'h0000, rsign, efv[7:0], mantb[6:0]};
      endcase
      fl = {3'b000, ufo, nxo};
    end

    fma_post = {res, fl};
  endfunction

  // ===========================================================================
  // Lane operand selection
  // ===========================================================================
  logic [31:0]   la   [0:NL-1];
  logic [31:0]   lb   [0:NL-1];
  logic [31:0]   lc   [0:NL-1];
  logic [1:0]    lfmt [0:NL-1];
  logic [MW-1:0] lpre [0:NL-1];
  logic [MW-1:0] lpre_q [0:NL-1];
  logic [36:0]   lres [0:NL-1];

  logic         v_q, ena;
  logic [1:0]   fmt_q;
  logic         vec_q;
  logic [2:0]   rnd_q;

  genvar g;
  generate
    for (g = 0; g < NL; g++) begin : g_lane
      if (g < N32) begin : g_wide
        assign lfmt[g] = fmt_i;
        assign la[g] = (fmt_i == 2'd0) ? a_i[32*g +: 32] : {16'b0, a_i[16*g +: 16]};
        assign lb[g] = (fmt_i == 2'd0) ? b_i[32*g +: 32] : {16'b0, b_i[16*g +: 16]};
        assign lc[g] = (fmt_i == 2'd0) ? c_i[32*g +: 32] : {16'b0, c_i[16*g +: 16]};
      end else begin : g_narrow
        // never handed an FP32 operation: keeps the FP32 geometry out of here
        assign lfmt[g] = (fmt_i == 2'd1) ? 2'd1 : 2'd2;
        assign la[g] = {16'b0, a_i[16*g +: 16]};
        assign lb[g] = {16'b0, b_i[16*g +: 16]};
        assign lc[g] = {16'b0, c_i[16*g +: 16]};
      end
      assign lpre[g] = fma_pre(lfmt[g], la[g], lb[g], lc[g]);
      // the format selector of stage B is re-derived from the registered fmt,
      // so the narrow lanes stay narrow on both sides of the register
      if (g < N32) begin : g_post_wide
        assign lres[g] = fma_post(fmt_q, rnd_q, lpre_q[g]);
      end else begin : g_post_narrow
        assign lres[g] = fma_post((fmt_q == 2'd1) ? 2'd1 : 2'd2, rnd_q, lpre_q[g]);
      end
    end
  endgenerate

  // ===========================================================================
  // Pipeline register (one stage) and elastic handshake
  // ===========================================================================
  assign ena = !v_q || out_ready_i;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      v_q <= 1'b0;
    end else if (ena) begin
      v_q <= in_valid_i;
    end
  end

  always_ff @(posedge clk_i) begin
    int k;
    if (ena) begin
      fmt_q <= fmt_i;
      vec_q <= vec_i;
      rnd_q <= rnd_i;
      for (k = 0; k < NL; k++) begin
        lpre_q[k] <= lpre[k];
      end
    end
  end

  assign in_ready_o  = ena;          // may depend on out_ready_i (L4 permits)
  assign out_valid_o = v_q;          // never depends on out_ready_i

  // ===========================================================================
  // Result packing (V3: bits above the lanes in use are all ones)
  // ===========================================================================
  always_comb begin
    int i;
    logic [4:0] fl;
    result_o = {WIDTH{1'b1}};
    fl       = 5'b00000;
    if (fmt_q == 2'd0) begin
      for (i = 0; i < N32; i++) begin
        if (vec_q || (i == 0)) begin
          result_o[32*i +: 32] = lres[i][36:5];
          fl = fl | lres[i][4:0];
        end
      end
    end else begin
      for (i = 0; i < NL; i++) begin
        if (vec_q || (i == 0)) begin
          result_o[16*i +: 16] = lres[i][20:5];
          fl = fl | lres[i][4:0];
        end
      end
    end
    flags_o = fl;
  end

endmodule
