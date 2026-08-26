// =============================================================================
// fp_multifmt_fma.sv
//
// Multi-format fused multiply-add: FP32 / FP16 / BF16 through one shared
// significand datapath, SIMD across WIDTH/format_width lanes.
//
// STRUCTURE
//   * One lane engine per 16-bit slot (WIDTH/16 of them).  Slots below
//     WIDTH/32 are built wide enough for FP32; the remaining slots can only
//     ever be asked for a 16-bit format, so their significands are masked to
//     11 bits at elaboration and their multiplier and datapath shrink by
//     constant propagation.
//   * ONE rounding.  The exact product-plus-addend is formed in a fixed-point
//     field and rounded once; the product is never rounded on its own.
//   * SIGNIFICAND DATAPATH: 77 bits (A8 allows 4*p = 96 at FP32).  The field
//     is 3*p+4 = 76 bits for p = 24 plus one carry bit.  Everything below the
//     field collapses into a sticky bit, which is what "as if unbounded"
//     requires of the RESULT rather than of the hardware.
//   * Subnormal operands and subnormal results are handled at full precision
//     in all three formats; there is no flush to zero anywhere.
//
// THE FIELD, since the alignment is the part that has to be right.
//   sigp = siga*sigb is 2p bits; sigc is p bits (p = 24 throughout, narrower
//   formats simply carry leading zeros).  Both are notionally top-aligned:
//   bit 2p-1 of the product has exponent (ela+elb)+2p-1, bit p-1 of the addend
//   has exponent elc+p-1.  The frame's top is the larger of the two, so
//   whichever term is smaller is the one shifted right, and only one barrel
//   shifter is needed.  76 bits is enough because the addend can only matter
//   down to p+1 bits below the product's LSB -- further down it cannot reach
//   the round bit -- and the product can only matter down to p+4 below the
//   addend's LSB.  Anything past that is sticky, which is exactly what the
//   saturating shift produces.
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

  // ---- geometry -------------------------------------------------------------
  localparam int unsigned NU = WIDTH/16;   // 16-bit slots  (4 at WIDTH=64)
  localparam int unsigned NW = WIDTH/32;   // 32-bit slots  (2 at WIDTH=64)

  localparam int P  = 24;                  // widest significand precision
  localparam int F  = 3*P + 4;             // 76 -- alignment field
  localparam int SW = F + 1;               // 77 -- sum, one carry bit

  // ===========================================================================
  // ONE LANE.  Returns {flags[4:0], result[31:0]}; for a 16-bit format only
  // bits [15:0] of the result are meaningful.
  // ===========================================================================
  function automatic logic [36:0] fma_lane(
      input logic [31:0] a,
      input logic [31:0] b,
      input logic [31:0] c,
      input logic [1:0]  fmt,
      input logic [2:0]  rnd,
      input bit          wide);

    // ---- declarations (all before the first statement) ----------------------
    int            ew, bias, emaxf, minlsb, mw;
    logic          sa, sb, sc, sp;
    logic [7:0]    ea, eb, ec;
    logic [22:0]   ma, mb, mc;
    logic          qa, qb, qc;
    logic          nana, nanb, nanc, sna, snb, snc;
    logic          infa, infb, infc, zra, zrb;
    logic          nrma, nrmb, nrmc;
    logic [23:0]   siga, sigb, sigc, sigae, sigbe;
    logic [47:0]   sigp;
    int            ela, elb, elc, elp;
    int            pmsb, cmsb, pkey, ckey, topexp, origin;
    logic          ptop, pz, cz;
    logic [F-1:0]  pext, cext, topv, shin, shv, lostv;
    int            shraw, shamt;
    logic          stl, samesg, tsign, rsign;
    logic [SW-1:0] ssum, dext, lost2;
    /* verilator lint_off UNUSEDSIGNAL */
    logic [SW-1:0] mv;      // only [23:0] is ever a significand
    /* verilator lint_on UNUSEDSIGNAL */
    int            lead, sh2;
    logic          rb, st2, lsb, inc;
    logic [24:0]   mr;
    logic [22:0]   manfull;
    logic          bmsb, bcar;
    int            expi, bpre;
    logic          isnorm, ovf, nx, uf, nv, toinf, zs, done;
    logic [31:0]   res, canon;
    logic [4:0]    flg;

    // ---- per-format geometry -----------------------------------------------
    case (fmt)
      2'd0:    begin ew = 8; mw = 23; bias = 127; end
      2'd1:    begin ew = 5; mw = 10; bias = 15;  end
      default: begin ew = 8; mw = 7;  bias = 127; end
    endcase
    emaxf  = (1 << ew) - 1;
    minlsb = 1 - bias - mw;

    // ---- unpack -------------------------------------------------------------
    case (fmt)
      2'd0: begin
        sa = a[31]; ea = a[30:23]; ma = a[22:0]; qa = a[22];
        sb = b[31]; eb = b[30:23]; mb = b[22:0]; qb = b[22];
        sc = c[31]; ec = c[30:23]; mc = c[22:0]; qc = c[22];
      end
      2'd1: begin
        sa = a[15]; ea = {3'b0, a[14:10]}; ma = {13'b0, a[9:0]}; qa = a[9];
        sb = b[15]; eb = {3'b0, b[14:10]}; mb = {13'b0, b[9:0]}; qb = b[9];
        sc = c[15]; ec = {3'b0, c[14:10]}; mc = {13'b0, c[9:0]}; qc = c[9];
      end
      default: begin
        sa = a[15]; ea = a[14:7]; ma = {16'b0, a[6:0]}; qa = a[6];
        sb = b[15]; eb = b[14:7]; mb = {16'b0, b[6:0]}; qb = b[6];
        sc = c[15]; ec = c[14:7]; mc = {16'b0, c[6:0]}; qc = c[6];
      end
    endcase

    nana = (int'(ea) == emaxf) && (ma != 23'd0);
    nanb = (int'(eb) == emaxf) && (mb != 23'd0);
    nanc = (int'(ec) == emaxf) && (mc != 23'd0);
    sna  = nana && !qa;
    snb  = nanb && !qb;
    snc  = nanc && !qc;
    infa = (int'(ea) == emaxf) && (ma == 23'd0);
    infb = (int'(eb) == emaxf) && (mb == 23'd0);
    infc = (int'(ec) == emaxf) && (mc == 23'd0);
    zra  = (ea == 8'd0) && (ma == 23'd0);
    zrb  = (eb == 8'd0) && (mb == 23'd0);
    nrma = (ea != 8'd0);
    nrmb = (eb != 8'd0);
    nrmc = (ec != 8'd0);

    case (fmt)
      2'd0: begin
        siga = {nrma, ma[22:0]};
        sigb = {nrmb, mb[22:0]};
        sigc = {nrmc, mc[22:0]};
      end
      2'd1: begin
        siga = {13'b0, nrma, ma[9:0]};
        sigb = {13'b0, nrmb, mb[9:0]};
        sigc = {13'b0, nrmc, mc[9:0]};
      end
      default: begin
        siga = {16'b0, nrma, ma[6:0]};
        sigb = {16'b0, nrmb, mb[6:0]};
        sigc = {16'b0, nrmc, mc[6:0]};
      end
    endcase

    // A slot that can never be asked for FP32 needs only an 11-bit
    // significand; the mask is a constant there and prunes the multiplier.
    sigae = wide ? siga : {13'b0, siga[10:0]};
    sigbe = wide ? sigb : {13'b0, sigb[10:0]};

    // exponent of each significand's LSB
    ela = ((ea == 8'd0) ? 1 : int'(ea)) - bias - mw;
    elb = ((eb == 8'd0) ? 1 : int'(eb)) - bias - mw;
    elc = ((ec == 8'd0) ? 1 : int'(ec)) - bias - mw;
    elp = ela + elb;

    sigp = sigae * sigbe;                   // exact 2p-bit product
    sp   = sa ^ sb;

    canon = (fmt == 2'd0) ? 32'h7FC0_0000 :
            (fmt == 2'd1) ? 32'h0000_7E00 : 32'h0000_7FC0;

    res  = 32'd0;
    flg  = 5'd0;
    done = 1'b0;
    nv   = 1'b0;
    nx   = 1'b0;
    uf   = 1'b0;
    ovf  = 1'b0;
    rsign = 1'b0;

    // ---- special cases, in the priority A5 fixes ---------------------------
    if (sna || snb || snc) begin
      res = canon; nv = 1'b1; done = 1'b1;
    end else if ((infa && zrb) || (zra && infb)) begin
      // 0 * inf, whatever c is -- ahead of a quiet-NaN addend
      res = canon; nv = 1'b1; done = 1'b1;
    end else if (nana || nanb || nanc) begin
      res = canon; done = 1'b1;
    end else if ((infa || infb) && infc && (sp != sc)) begin
      res = canon; nv = 1'b1; done = 1'b1;
    end else if (infa || infb) begin
      case (fmt)
        2'd0:    res = {sp, 8'hFF, 23'd0};
        2'd1:    res = {16'd0, sp, 5'h1F, 10'd0};
        default: res = {16'd0, sp, 8'hFF, 7'd0};
      endcase
      done = 1'b1;
    end else if (infc) begin
      case (fmt)
        2'd0:    res = {sc, 8'hFF, 23'd0};
        2'd1:    res = {16'd0, sc, 5'h1F, 10'd0};
        default: res = {16'd0, sc, 8'hFF, 7'd0};
      endcase
      done = 1'b1;
    end

    pz = (sigp == 48'd0);
    cz = (sigc == 24'd0);

    if (!done && pz && cz) begin
      // exact zero out of two zero terms (A6)
      zs = (sp == sc) ? sp : (rnd == 3'd2);
      case (fmt)
        2'd0:    res = {zs, 31'd0};
        default: res = {16'd0, zs, 15'd0};
      endcase
      done = 1'b1;
    end

    if (!done) begin
      // ---- align ------------------------------------------------------------
      pmsb = elp + (2*P - 1);
      cmsb = elc + (P - 1);
      pkey = pz ? -32000 : pmsb;
      ckey = cz ? -32000 : cmsb;
      ptop = (pkey >= ckey);
      topexp = ptop ? pkey : ckey;
      origin = topexp - (F - 1);

      pext = {sigp, {(F-48){1'b0}}};
      cext = {sigc, {(F-24){1'b0}}};

      if (ptop) begin
        topv = pext; shin = cext; shraw = pmsb - cmsb; tsign = sp;
      end else begin
        topv = cext; shin = pext; shraw = cmsb - pmsb; tsign = sc;
      end
      shamt = (shraw < 0) ? 0 : ((shraw > F) ? F : shraw);

      shv   = shin >> shamt;
      lostv = shin << (F - shamt);          // shamt=0 -> shift by F -> zero
      stl   = |lostv;

      // ---- add or subtract, carrying the sticky as a borrow -----------------
      samesg = (sp == sc);
      if (samesg) begin
        ssum  = {1'b0, topv} + {1'b0, shv};
        rsign = tsign;
        dext  = '0;
      end else begin
        dext = {1'b0, topv} - {1'b0, shv} - {{(SW-1){1'b0}}, stl};
        if (!dext[SW-1]) begin
          ssum  = dext;
          rsign = tsign;
        end else begin
          // magnitude of a negative difference: with a sticky residual the
          // field value is -(d)-1 = ~d, without one it is -d
          ssum  = stl ? ~dext : (~dext + {{(SW-1){1'b0}}, 1'b1});
          rsign = ~tsign;
        end
      end

      // ---- normalise --------------------------------------------------------
      lead = -1;
      for (int i = 0; i < SW; i++) if (ssum[i]) lead = i;

      if (lead < 0) begin
        // exact cancellation (a residual here is unreachable, but is not
        // allowed to produce a wrong answer if it ever were)
        if (stl) begin
          zs = rsign;
          case (fmt)
            2'd0:    res = ((rnd == 3'd3 && !zs) || (rnd == 3'd2 && zs)) ? {zs, 31'd1} : {zs, 31'd0};
            default: res = ((rnd == 3'd3 && !zs) || (rnd == 3'd2 && zs)) ? {16'd0, zs, 15'd1} : {16'd0, zs, 15'd0};
          endcase
          nx = 1'b1;
          uf = 1'b1;
        end else begin
          zs = (rnd == 3'd2);               // A6: +0 except toward -inf
          case (fmt)
            2'd0:    res = {zs, 31'd0};
            default: res = {16'd0, zs, 15'd0};
          endcase
        end
      end else begin
        isnorm = ((origin + lead) >= (1 - bias));
        sh2    = (lead - mw);
        if ((minlsb - origin) > sh2) sh2 = minlsb - origin;

        if (sh2 < 0) begin
          mv  = ssum << (-sh2);
          rb  = 1'b0;
          st2 = stl;
        end else if (sh2 > SW) begin
          mv  = '0;
          rb  = 1'b0;
          st2 = (|ssum) | stl;
        end else begin
          mv    = ssum >> sh2;
          lost2 = ssum << (SW - sh2);
          rb    = lost2[SW-1];
          st2   = (|lost2[SW-2:0]) | stl;
        end

        lsb = mv[0];
        case (rnd)
          3'd0:    inc = rb & (st2 | lsb);          // RNE
          3'd1:    inc = 1'b0;                      // RTZ
          3'd2:    inc = rsign & (rb | st2);        // RDN
          3'd3:    inc = (~rsign) & (rb | st2);     // RUP
          default: inc = rb;                        // RMM
        endcase

        mr = {1'b0, mv[23:0]} + {24'd0, inc};

        case (fmt)
          2'd0:    begin manfull = mr[22:0];             bmsb = mr[23]; bcar = mr[24]; end
          2'd1:    begin manfull = {13'b0, mr[9:0]};     bmsb = mr[10]; bcar = mr[11]; end
          default: begin manfull = {16'b0, mr[6:0]};     bmsb = mr[7];  bcar = mr[8];  end
        endcase

        bpre = origin + lead + bias;
        if (isnorm) begin
          expi = bcar ? (bpre + 1) : bpre;
          if (bcar) manfull = 23'd0;
        end else begin
          expi = bmsb ? 1 : 0;
        end

        nx  = rb | st2;
        ovf = (expi >= emaxf);

        if (ovf) begin
          toinf = (rnd == 3'd0) || (rnd == 3'd4) ||
                  ((rnd == 3'd3) && !rsign) || ((rnd == 3'd2) && rsign);
          case (fmt)
            2'd0:    res = toinf ? {rsign, 8'hFF, 23'd0} : {rsign, 8'hFE, 23'h7FFFFF};
            2'd1:    res = toinf ? {16'd0, rsign, 5'h1F, 10'd0} : {16'd0, rsign, 5'h1E, 10'h3FF};
            default: res = toinf ? {16'd0, rsign, 8'hFF, 7'd0}  : {16'd0, rsign, 8'hFE, 7'h7F};
          endcase
          nx = 1'b1;
          uf = 1'b0;
        end else begin
          case (fmt)
            2'd0:    res = {rsign, expi[7:0], manfull[22:0]};
            2'd1:    res = {16'd0, rsign, expi[4:0], manfull[9:0]};
            default: res = {16'd0, rsign, expi[7:0], manfull[6:0]};
          endcase
          // A7a: inexact AND the DELIVERED exponent field is zero
          uf = nx & (expi == 0);
        end
      end
    end

    flg = {nv, 1'b0, ovf, uf, nx};
    return {flg, res};
  endfunction

  // ===========================================================================
  // LANE SLOTS
  // ===========================================================================
  logic [31:0] ua [NU];
  logic [31:0] ub [NU];
  logic [31:0] uc [NU];
  logic [36:0] uo [NU];

  for (genvar j = 0; j < int'(NU); j++) begin : g_slot
    if (j < int'(NW)) begin : g_wide
      // this slot can be asked for FP32
      always_comb begin
        if (fmt_i == 2'd0) begin
          ua[j] = a_i[j*32 +: 32];
          ub[j] = b_i[j*32 +: 32];
          uc[j] = c_i[j*32 +: 32];
        end else begin
          ua[j] = {16'd0, a_i[j*16 +: 16]};
          ub[j] = {16'd0, b_i[j*16 +: 16]};
          uc[j] = {16'd0, c_i[j*16 +: 16]};
        end
      end
      always_comb uo[j] = fma_lane(ua[j], ub[j], uc[j], fmt_i, rnd_i, 1'b1);
    end else begin : g_narrow
      // never FP32: an 11-bit significand is enough here
      always_comb begin
        ua[j] = {16'd0, a_i[j*16 +: 16]};
        ub[j] = {16'd0, b_i[j*16 +: 16]};
        uc[j] = {16'd0, c_i[j*16 +: 16]};
      end
      always_comb uo[j] = fma_lane(ua[j], ub[j], uc[j], fmt_i, rnd_i, 1'b0);
    end
  end

  // ---- lane count and assembly ----------------------------------------------
  logic [3:0]       nlanes;
  logic [WIDTH-1:0] result_c;
  logic [4:0]       flags_c;

  always_comb begin
    if (!vec_i)               nlanes = 4'd1;
    else if (fmt_i == 2'd0)   nlanes = 4'(NW);
    else                      nlanes = 4'(NU);
  end

  always_comb begin
    result_c = {WIDTH{1'b1}};               // V3: unused high bits are ones
    flags_c  = 5'd0;
    for (int s = 0; s < int'(NU); s++) begin
      if (fmt_i == 2'd0) begin
        if ((s/2) < int'(nlanes))
          result_c[s*16 +: 16] = (s % 2 == 0) ? uo[s/2][15:0] : uo[s/2][31:16];
      end else begin
        if (s < int'(nlanes))
          result_c[s*16 +: 16] = uo[s][15:0];
      end
    end
    for (int k = 0; k < int'(NU); k++)
      if (k < int'(nlanes)) flags_c = flags_c | uo[k][36:32];
  end

  // ===========================================================================
  // HANDSHAKE -- one result register; accepts one operation per cycle when the
  // output is being taken, and holds the result stable until it is (H1, H2).
  // ===========================================================================
  logic [WIDTH-1:0] res_q;
  logic [4:0]       flg_q;
  logic             val_q;

  assign in_ready_o  = !val_q | out_ready_i;
  assign out_valid_o = val_q;
  assign result_o    = res_q;
  assign flags_o     = flg_q;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      val_q <= 1'b0;
      res_q <= '0;
      flg_q <= '0;
    end else begin
      if (in_valid_i && in_ready_o) begin
        val_q <= 1'b1;
        res_q <= result_c;
        flg_q <= flags_c;
      end else if (val_q && out_ready_i) begin
        val_q <= 1'b0;
      end
    end
  end

endmodule