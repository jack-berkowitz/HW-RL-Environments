// =============================================================================
// fp_multifmt_fma -- multi-format (FP32 / FP16 / BF16) fused multiply-add
//                    with SIMD lanes filling WIDTH.
//
//  * one rounding of the exact product-plus-addend (true FMA)
//  * subnormal operands and results at full precision, all three formats
//  * all five rounding modes, canonical qNaN, RISC-V style NaN-boxing of the
//    unused high result bits
//  * bounded significand datapath:
//       FP32 lane : 76-bit accumulator (3p+4, p=24)  <= 4p = 96
//       16b  lane : 37-bit accumulator (3p+4, p=11)  <= 4p = 44
//    everything below the window collapses into a sticky bit.
//  * fully combinational (conformant per L4: in_ready_o <- out_ready_i and
//    out_valid_o <- in_valid_i are the permitted paths).
// =============================================================================
/* verilator lint_off UNUSEDSIGNAL */
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

  // number of hardware lanes
  localparam int unsigned NW = (WIDTH >= 32) ? (WIDTH / 32) : 1;   // FP32 lanes
  localparam int unsigned NN = WIDTH / 16;                         // 16-bit lanes

  // ===========================================================================
  // FP32 fused multiply-add lane.  p = 24, W = 3p+4 = 76.
  // returns { flags[4:0], result[31:0] }
  // ===========================================================================
  function automatic logic [36:0] fma32_f(input logic [31:0] a,
                                          input logic [31:0] b,
                                          input logic [31:0] c,
                                          input logic [2:0]  rnd);
    logic        sa, sbg, scg, sp, sres;
    logic [7:0]  eaf, ebf, ecf;
    logic [22:0] maf, mbf, mcf;
    logic        anan, bnan, cnan, asn, bsn, csn;
    logic        ainf, binf, cinf, azer, bzer, czer;
    logic [23:0] ma, mb, mc, mkeep, mfin;
    logic [24:0] mr;
    int          ea, eb, ec, pe, ce, dd, shs, ae, eres, bexp, mxsh, lz, sh, i, klost;
    logic [6:0]  shamt, shu;
    logic [47:0] mp;
    logic [75:0] pshift, afull, ash, aop, mag, norm;
    logic [76:0] sraw;
    logic        stkb, esub, cry, rb, st, inc, nx, ovf, unf;
    logic [31:0] res;
    logic [4:0]  fl;
    begin
      // ---- decompose ---------------------------------------------------------
      sa  = a[31];  eaf = a[30:23];  maf = a[22:0];
      sbg = b[31];  ebf = b[30:23];  mbf = b[22:0];
      scg = c[31];  ecf = c[30:23];  mcf = c[22:0];

      ainf = (eaf == 8'hFF) && (maf == 23'd0);
      binf = (ebf == 8'hFF) && (mbf == 23'd0);
      cinf = (ecf == 8'hFF) && (mcf == 23'd0);
      anan = (eaf == 8'hFF) && (maf != 23'd0);
      bnan = (ebf == 8'hFF) && (mbf != 23'd0);
      cnan = (ecf == 8'hFF) && (mcf != 23'd0);
      asn  = anan && !maf[22];
      bsn  = bnan && !mbf[22];
      csn  = cnan && !mcf[22];
      azer = (eaf == 8'h00) && (maf == 23'd0);
      bzer = (ebf == 8'h00) && (mbf == 23'd0);
      czer = (ecf == 8'h00) && (mcf == 23'd0);

      ma = {(eaf != 8'h00), maf};
      mb = {(ebf != 8'h00), mbf};
      mc = {(ecf != 8'h00), mcf};
      ea = ((eaf == 8'h00) ? 32'sd1 : int'(eaf)) - 32'sd127;
      eb = ((ebf == 8'h00) ? 32'sd1 : int'(ebf)) - 32'sd127;
      ec = ((ecf == 8'h00) ? 32'sd1 : int'(ecf)) - 32'sd127;

      sp = sa ^ sbg;

      // defaults
      res = 32'd0;  fl = 5'd0;
      // unused-value defaults (keep tools happy about latch-free coding)
      pe = 0; ce = 0; dd = 0; shs = 0; ae = 0; eres = 0; bexp = 0; mxsh = 0;
      lz = 0; sh = 0; klost = 0; shamt = 7'd0; shu = 7'd0;
      mp = 48'd0; pshift = 76'd0; afull = 76'd0; ash = 76'd0; aop = 76'd0;
      mag = 76'd0; norm = 76'd0; sraw = 77'd0; mkeep = 24'd0; mfin = 24'd0;
      mr = 25'd0; stkb = 1'b0; esub = 1'b0; cry = 1'b0; rb = 1'b0; st = 1'b0;
      inc = 1'b0; nx = 1'b0; ovf = 1'b0; unf = 1'b0; sres = 1'b0;

      if (asn || bsn || csn) begin
        res = 32'h7FC00000;  fl = 5'b10000;
      end else if ((ainf && bzer) || (azer && binf)) begin
        res = 32'h7FC00000;  fl = 5'b10000;
      end else if (anan || bnan || cnan) begin
        res = 32'h7FC00000;  fl = 5'b00000;
      end else if (ainf || binf) begin
        if (cinf && (scg != sp)) begin
          res = 32'h7FC00000;  fl = 5'b10000;
        end else begin
          res = {sp, 8'hFF, 23'd0};
        end
      end else if (cinf) begin
        res = {scg, 8'hFF, 23'd0};
      end else begin
        // ---- alignment -------------------------------------------------------
        pe  = (azer || bzer) ? -32'sd252 : (ea + eb);
        ce  = ec;
        dd  = ce - pe;
        shs = 32'sd27 - dd;
        if (shs <= 0)       shamt = 7'd0;
        else if (shs >= 76) shamt = 7'd76;
        else                shamt = shs[6:0];

        afull = {mc, 52'd0};
        ash   = afull >> shamt;
        klost = (shamt > 7'd52) ? (int'(shamt) - 32'sd52) : 32'sd0;
        stkb  = 1'b0;
        for (i = 0; i < 24; i = i + 1)
          if (i < klost) stkb = stkb | mc[i];

        ae = (shs <= 0) ? (ce - 32'sd75) : (pe - 32'sd48);

        mp     = (azer || bzer) ? 48'd0 : (ma * mb);
        pshift = {26'd0, mp, 2'd0};

        // ---- add -------------------------------------------------------------
        esub = sp ^ scg;
        aop  = esub ? ~ash : ash;
        sraw = {1'b0, pshift} + {1'b0, aop} +
               {76'd0, (esub && !stkb)};
        cry  = sraw[76];

        if (esub && !cry) begin
          mag  = (~sraw[75:0]) + 76'd1;
          sres = ~sp;
        end else begin
          mag  = sraw[75:0];
          sres = sp;
        end

        if ((mag == 76'd0) && !stkb) begin
          // exact zero result
          if (esub) sres = (rnd == 3'd2) ? 1'b1 : 1'b0;
          res = {sres, 31'd0};
          fl  = 5'd0;
        end else begin
          // ---- normalise -----------------------------------------------------
          lz = 76;
          for (i = 0; i < 76; i = i + 1)
            if (mag[i]) lz = 75 - i;
          mxsh = ae + 32'sd201;
          sh   = (lz < mxsh) ? lz : mxsh;
          if (sh < 0)  sh = 0;
          if (sh > 75) sh = 75;
          shu  = sh[6:0];
          norm = mag << shu;
          eres = ae - sh + 32'sd75;

          mkeep = norm[75:52];
          rb    = norm[51];
          st    = (|norm[50:0]) | stkb;

          // ---- round ---------------------------------------------------------
          case (rnd)
            3'd0:    inc = rb && (st || mkeep[0]);
            3'd1:    inc = 1'b0;
            3'd2:    inc = sres && (rb || st);
            3'd3:    inc = (!sres) && (rb || st);
            3'd4:    inc = rb;
            default: inc = 1'b0;
          endcase
          mr = {1'b0, mkeep} + {24'd0, inc};
          if (mr[24]) begin
            mfin = 24'h800000;
            bexp = eres + 32'sd1 + 32'sd127;
          end else begin
            mfin = mr[23:0];
            bexp = eres + 32'sd127;
          end
          nx = rb | st;

          if (bexp >= 32'sd255) begin
            ovf = 1'b1;
            nx  = 1'b1;
            if ((rnd == 3'd1) || (rnd == 3'd2 && !sres) || (rnd == 3'd3 && sres))
              res = {sres, 8'hFE, 23'h7FFFFF};
            else
              res = {sres, 8'hFF, 23'd0};
          end else begin
            ovf = 1'b0;
            res = {sres, (mfin[23] ? bexp[7:0] : 8'h00), mfin[22:0]};
          end
          unf = nx && (res[30:23] == 8'h00);
          fl  = {1'b0, 1'b0, ovf, unf, nx};
        end
      end
      fma32_f = {fl, res};
    end
  endfunction

  // ===========================================================================
  // 16-bit operand decode.  Internally the significand is LEFT ALIGNED into an
  // 11-bit field, so FP16 and BF16 share one datapath geometry (p_int = 11).
  // returns { sign, nan, snan, inf, zero, exp[15:0] (signed), sig[10:0] }
  // ===========================================================================
  function automatic logic [31:0] dec16_f(input logic [15:0] x, input logic isbf);
    logic [7:0]  ef;
    logic        fnz, hid, emx, ezr, qb;
    logic [10:0] sig;
    int          e;
    begin
      ef  = isbf ? x[14:7] : {3'd0, x[14:10]};
      fnz = isbf ? (x[6:0] != 7'd0) : (x[9:0] != 10'd0);
      qb  = isbf ? x[6] : x[9];
      emx = isbf ? (x[14:7] == 8'hFF) : (x[14:10] == 5'h1F);
      ezr = (ef == 8'h00);
      hid = ~ezr;
      sig = isbf ? {hid, x[6:0], 3'd0} : {hid, x[9:0]};
      e   = (ezr ? 32'sd1 : int'(ef)) - (isbf ? 32'sd127 : 32'sd15);
      dec16_f = {x[15], (emx && fnz), (emx && fnz && !qb), (emx && !fnz),
                 (ezr && !fnz), e[15:0], sig};
    end
  endfunction

  // ===========================================================================
  // FP16 / BF16 fused multiply-add lane.  p_int = 11, W = 3p+4 = 37.
  // returns { flags[4:0], result[15:0] }
  // ===========================================================================
  function automatic logic [20:0] fma16_f(input logic [15:0] a,
                                          input logic [15:0] b,
                                          input logic [15:0] c,
                                          input logic [2:0]  rnd,
                                          input logic        isbf);
    logic [31:0] da, db, dc;
    logic        sa, sbg, scg, sp, sres;
    logic        anan, bnan, cnan, asn, bsn, csn;
    logic        ainf, binf, cinf, azer, bzer, czer;
    logic [10:0] ma, mb, mc, mkeep, mfin;
    logic [11:0] mr;
    int          ea, eb, ec, pe, ce, dd, shs, ae, eres, bexp, mxsh, lz, sh, i;
    int          klost, bias, elim;
    logic [5:0]  shamt, shu;
    logic [21:0] mp;
    logic [36:0] pshift, afull, ash, aop, mag, norm;
    logic [37:0] sraw;
    logic        stkb, esub, cry, rb, st, inc, nx, ovf, unf, hidb;
    logic [15:0] res, qnan;
    logic [7:0]  expf;
    logic [4:0]  fl;
    begin
      da = dec16_f(a, isbf);
      db = dec16_f(b, isbf);
      dc = dec16_f(c, isbf);

      sa   = da[31]; anan = da[30]; asn = da[29]; ainf = da[28]; azer = da[27];
      sbg  = db[31]; bnan = db[30]; bsn = db[29]; binf = db[28]; bzer = db[27];
      scg  = dc[31]; cnan = dc[30]; csn = dc[29]; cinf = dc[28]; czer = dc[27];
      ea   = int'($signed(da[26:11]));
      eb   = int'($signed(db[26:11]));
      ec   = int'($signed(dc[26:11]));
      ma   = da[10:0];
      mb   = db[10:0];
      mc   = dc[10:0];

      bias = isbf ? 32'sd127 : 32'sd15;
      elim = isbf ? 32'sd255 : 32'sd31;    // exponent field value meaning inf
      qnan = isbf ? 16'h7FC0 : 16'h7E00;
      sp   = sa ^ sbg;

      res = 16'd0;  fl = 5'd0;
      pe = 0; ce = 0; dd = 0; shs = 0; ae = 0; eres = 0; bexp = 0; mxsh = 0;
      lz = 0; sh = 0; klost = 0; shamt = 6'd0; shu = 6'd0; expf = 8'd0;
      mp = 22'd0; pshift = 37'd0; afull = 37'd0; ash = 37'd0; aop = 37'd0;
      mag = 37'd0; norm = 37'd0; sraw = 38'd0; mkeep = 11'd0; mfin = 11'd0;
      mr = 12'd0; stkb = 1'b0; esub = 1'b0; cry = 1'b0; rb = 1'b0; st = 1'b0;
      inc = 1'b0; nx = 1'b0; ovf = 1'b0; unf = 1'b0; sres = 1'b0; hidb = 1'b0;

      if (asn || bsn || csn) begin
        res = qnan;  fl = 5'b10000;
      end else if ((ainf && bzer) || (azer && binf)) begin
        res = qnan;  fl = 5'b10000;
      end else if (anan || bnan || cnan) begin
        res = qnan;  fl = 5'b00000;
      end else if (ainf || binf) begin
        if (cinf && (scg != sp)) begin
          res = qnan;  fl = 5'b10000;
        end else begin
          res = isbf ? {sp, 8'hFF, 7'd0} : {sp, 5'h1F, 10'd0};
        end
      end else if (cinf) begin
        res = isbf ? {scg, 8'hFF, 7'd0} : {scg, 5'h1F, 10'd0};
      end else begin
        pe  = (azer || bzer) ? (32'sd2 - 32'sd2 * bias) : (ea + eb);
        ce  = ec;
        dd  = ce - pe;
        shs = 32'sd14 - dd;
        if (shs <= 0)       shamt = 6'd0;
        else if (shs >= 37) shamt = 6'd37;
        else                shamt = shs[5:0];

        afull = {mc, 26'd0};
        ash   = afull >> shamt;
        klost = (shamt > 6'd26) ? (int'(shamt) - 32'sd26) : 32'sd0;
        stkb  = 1'b0;
        for (i = 0; i < 11; i = i + 1)
          if (i < klost) stkb = stkb | mc[i];

        ae = (shs <= 0) ? (ce - 32'sd36) : (pe - 32'sd22);

        mp     = (azer || bzer) ? 22'd0 : (ma * mb);
        pshift = {13'd0, mp, 2'd0};

        esub = sp ^ scg;
        aop  = esub ? ~ash : ash;
        sraw = {1'b0, pshift} + {1'b0, aop} + {37'd0, (esub && !stkb)};
        cry  = sraw[37];

        if (esub && !cry) begin
          mag  = (~sraw[36:0]) + 37'd1;
          sres = ~sp;
        end else begin
          mag  = sraw[36:0];
          sres = sp;
        end

        if ((mag == 37'd0) && !stkb) begin
          if (esub) sres = (rnd == 3'd2) ? 1'b1 : 1'b0;
          res = isbf ? {sres, 15'd0} : {sres, 15'd0};
          fl  = 5'd0;
        end else begin
          lz = 37;
          for (i = 0; i < 37; i = i + 1)
            if (mag[i]) lz = 36 - i;
          mxsh = ae + 32'sd35 + bias;
          sh   = (lz < mxsh) ? lz : mxsh;
          if (sh < 0)  sh = 0;
          if (sh > 36) sh = 36;
          shu  = sh[5:0];
          norm = mag << shu;
          eres = ae - sh + 32'sd36;

          mkeep = isbf ? {3'd0, norm[36:29]} : norm[36:26];
          rb    = isbf ? norm[28] : norm[25];
          st    = (isbf ? (|norm[27:0]) : (|norm[24:0])) | stkb;

          case (rnd)
            3'd0:    inc = rb && (st || mkeep[0]);
            3'd1:    inc = 1'b0;
            3'd2:    inc = sres && (rb || st);
            3'd3:    inc = (!sres) && (rb || st);
            3'd4:    inc = rb;
            default: inc = 1'b0;
          endcase
          mr  = {1'b0, mkeep} + {11'd0, inc};
          cry = isbf ? mr[8] : mr[11];
          if (cry) begin
            mfin = isbf ? 11'h080 : 11'h400;
            bexp = eres + 32'sd1 + bias;
          end else begin
            mfin = mr[10:0];
            bexp = eres + bias;
          end
          hidb = isbf ? mfin[7] : mfin[10];
          nx   = rb | st;

          if (bexp >= elim) begin
            ovf = 1'b1;
            nx  = 1'b1;
            if ((rnd == 3'd1) || (rnd == 3'd2 && !sres) || (rnd == 3'd3 && sres))
              res = isbf ? {sres, 8'hFE, 7'h7F} : {sres, 5'h1E, 10'h3FF};
            else
              res = isbf ? {sres, 8'hFF, 7'd0} : {sres, 5'h1F, 10'd0};
          end else begin
            ovf  = 1'b0;
            expf = hidb ? bexp[7:0] : 8'h00;
            res  = isbf ? {sres, expf, mfin[6:0]} : {sres, expf[4:0], mfin[9:0]};
          end
          unf = nx && (isbf ? (res[14:7] == 8'd0) : (res[14:10] == 5'd0));
          fl  = {1'b0, 1'b0, ovf, unf, nx};
        end
      end
      fma16_f = {fl, res};
    end
  endfunction

  // ===========================================================================
  // lanes
  // ===========================================================================
  logic [NW-1:0][36:0] wlane;
  logic [NN-1:0][20:0] nlane;

  genvar g;
  generate
    for (g = 0; g < int'(NW); g = g + 1) begin : gen_w
      always_comb begin
        wlane[g] = fma32_f(a_i[32*g +: 32], b_i[32*g +: 32], c_i[32*g +: 32], rnd_i);
      end
    end

    for (g = 0; g < int'(NN); g = g + 1) begin : gen_n
      always_comb begin
        nlane[g] = fma16_f(a_i[16*g +: 16], b_i[16*g +: 16], c_i[16*g +: 16],
                           rnd_i, fmt_i[1]);
      end
    end
  endgenerate

  // ===========================================================================
  // result assembly: active lanes packed low, unused high bits all ones (V3),
  // flags are the bitwise OR over the active lanes (V4).
  // ===========================================================================
  always_comb begin
    int nact;
    int k;
    nact     = 1;
    k        = 0;
    result_o = {WIDTH{1'b1}};
    flags_o  = 5'd0;
    if (fmt_i == 2'd0) begin
      nact = vec_i ? int'(NW) : 1;
      for (k = 0; k < int'(NW); k = k + 1) begin
        if (k < nact) begin
          result_o[32*k +: 32] = wlane[k][31:0];
          flags_o              = flags_o | wlane[k][36:32];
        end
      end
    end else begin
      nact = vec_i ? int'(NN) : 1;
      for (k = 0; k < int'(NN); k = k + 1) begin
        if (k < nact) begin
          result_o[16*k +: 16] = nlane[k][15:0];
          flags_o              = flags_o | nlane[k][20:16];
        end
      end
    end
  end

  // ===========================================================================
  // handshake: fully combinational unit (L4 permitted paths only)
  // ===========================================================================
  assign in_ready_o  = out_ready_i;
  assign out_valid_o = in_valid_i;

endmodule
/* verilator lint_on UNUSEDSIGNAL */
