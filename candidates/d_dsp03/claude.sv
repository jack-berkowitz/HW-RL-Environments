// =============================================================================
// fp_multifmt_fma.sv -- fused multiply-add, three formats, SIMD lanes
// =============================================================================
// One lane datapath, written once and instantiated per format by a generate
// loop whose localparams carry that format's geometry.  Each instance is
// therefore sized for the format it serves: the significand field is
// WF = 3*p+5 bits, which is 77 at FP32 (p=24), 38 at FP16 (p=11) and 29 at
// BF16 (p=8) -- inside A8's 4*p bound of 96 / 44 / 32 in every case.  The
// widest thing in the lane is the WF+1 bit sum, still inside the bound.
//
// The addition is fused: the exact 2p-bit product is placed in that field, the
// addend is aligned into it with everything below collapsed to one sticky bit,
// and the sum is rounded exactly once.
//
// Alignment, worked once so the constants below are checkable.  Bit i of the
// field has weight 2**(e_p + i - 3), so the product's LSB sits at bit 3 and its
// MSB at bit 2p+2, leaving p+2 bits above it for the addend and a carry, and
// three bits below it: two guard bits and, at bit 0, the sticky.  The addend's
// LSB lands at bit WF-p-s, so s = 2p+2-d with d = e_c-e_p.  s<0 means the
// addend sits so far above the product that the whole product is at least four
// bits below the addend's LSB and can only ever be sticky, so the product
// collapses to one bit and s clamps to zero.
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

  localparam int NL16 = WIDTH / 16;        // 2 or 4
  localparam int NL32 = WIDTH / 32;        // 1 or 2

  // ---------------------------------------------------------------------------
  // input register: one operation in flight, results in order (H1, H2, C1)
  // ---------------------------------------------------------------------------
  logic             valid_q;
  logic [1:0]       fmt_q;
  logic             vec_q;
  logic [2:0]       rnd_q;
  logic [WIDTH-1:0] a_q, b_q, c_q;

  assign in_ready_o  = !valid_q || out_ready_i;
  assign out_valid_o = valid_q;

  always_ff @(posedge clk_i) begin
    if (!rst_ni) begin
      valid_q <= 1'b0;
      fmt_q   <= 2'd0;
      vec_q   <= 1'b0;
      rnd_q   <= 3'd0;
      a_q     <= '0;
      b_q     <= '0;
      c_q     <= '0;
    end else begin
      if (in_valid_i && in_ready_o) begin
        valid_q <= 1'b1;
        fmt_q   <= fmt_i;
        vec_q   <= vec_i;
        rnd_q   <= rnd_i;
        a_q     <= a_i;
        b_q     <= b_i;
        c_q     <= c_i;
      end else if (out_ready_i) begin
        valid_q <= 1'b0;
      end
    end
  end

  // ---------------------------------------------------------------------------
  // per-format, per-lane results
  // ---------------------------------------------------------------------------
  logic [31:0] lane_res [3][NL16];
  logic [4:0]  lane_flg [3][NL16];

  for (genvar f = 0; f < 3; f++) begin : g_fmt
    localparam int EW    = (f == 1) ? 5 : 8;
    localparam int MW    = (f == 0) ? 23 : (f == 1) ? 10 : 7;
    localparam int FW    = 1 + EW + MW;                 // 32 / 16 / 16
    localparam int PP    = MW + 1;                      // significand precision
    localparam int BIAS  = (1 << (EW - 1)) - 1;
    localparam int EMIN  = 1 - BIAS;                    // unbiased subnormal exponent
    localparam int WF    = 3 * PP + 5;                  // significand field, <= 4*PP
    localparam int NLANE = int'(WIDTH) / FW;

    for (genvar l = 0; l < NL16; l++) begin : g_lane
      if (l < NLANE) begin : g_live
        always_comb begin
          // ---- declarations first (T2) --------------------------------------
          logic [FW-1:0]   av, bv, cv;
          logic            sa, sb, sc;
          logic [EW-1:0]   ea, eb, ec;
          logic [MW-1:0]   ma, mb, mc;
          logic            a_z, b_z, c_z;
          logic            a_i2, b_i2, c_i2;
          logic            a_n, b_n, c_n;
          logic            a_sn, b_sn, c_sn;
          logic [PP-1:0]   siga, sigb, sigc;
          logic signed [15:0] expa, expb, expc;
          logic signed [15:0] e_p, e_c, dd, s_raw, sh, ex, rsh, ebo, ebias, e_base;
          logic            sgn_p, eff_sub, rsgn;
          logic            prod_inf, invalid, nan_out, inf_out;
          logic [2*PP-1:0] prod;
          logic [WF-2:0]   c_pad, c_shr;
          logic            c_stk, far_above;
          logic [WF-1:0]   c_fld, p_fld;
          logic [WF:0]     msum, mnrm, mshf;
          logic            r_stk;
          integer          lz, shi, rshi;
          logic            fnd;
          logic [PP-1:0]   mant;
          logic            rbit, stky, incr;
          logic [PP:0]     qrnd;
          logic [EW-1:0]   eout;
          logic [MW-1:0]   mout;
          logic            nx, of, uf;
          logic            to_inf;

          to_inf = 1'b0;
          uf     = 1'b0;
          lane_res[f][l] = 32'd0;
          lane_flg[f][l] = 5'd0;

          av = a_q[l*FW +: FW];
          bv = b_q[l*FW +: FW];
          cv = c_q[l*FW +: FW];

          // ---- decode -------------------------------------------------------
          sa = av[FW-1];  ea = av[FW-2 -: EW];  ma = av[MW-1:0];
          sb = bv[FW-1];  eb = bv[FW-2 -: EW];  mb = bv[MW-1:0];
          sc = cv[FW-1];  ec = cv[FW-2 -: EW];  mc = cv[MW-1:0];

          a_z  = (ea == '0) && (ma == '0);
          b_z  = (eb == '0) && (mb == '0);
          c_z  = (ec == '0) && (mc == '0);
          a_i2 = (&ea) && (ma == '0);
          b_i2 = (&eb) && (mb == '0);
          c_i2 = (&ec) && (mc == '0);
          a_n  = (&ea) && (ma != '0);
          b_n  = (&eb) && (mb != '0);
          c_n  = (&ec) && (mc != '0);
          a_sn = a_n && !ma[MW-1];
          b_sn = b_n && !mb[MW-1];
          c_sn = c_n && !mc[MW-1];

          siga = {(ea != '0), ma};
          sigb = {(eb != '0), mb};
          sigc = {(ec != '0), mc};
          expa = (ea == '0) ? (16'sd1 - $signed(16'(BIAS))) : ($signed(16'(ea)) - $signed(16'(BIAS)));
          expb = (eb == '0) ? (16'sd1 - $signed(16'(BIAS))) : ($signed(16'(eb)) - $signed(16'(BIAS)));
          expc = (ec == '0) ? (16'sd1 - $signed(16'(BIAS))) : ($signed(16'(ec)) - $signed(16'(BIAS)));

          sgn_p    = sa ^ sb;
          prod_inf = a_i2 || b_i2;

          // ---- A5: the invalid cases ----------------------------------------
          invalid = a_sn || b_sn || c_sn
                 || (a_z && b_i2) || (a_i2 && b_z)
                 || (prod_inf && c_i2 && (sgn_p != sc));
          nan_out = invalid || a_n || b_n || c_n;
          inf_out = !nan_out && (prod_inf || c_i2);

          // defaults
          prod  = siga * sigb;
          e_p   = expa + expb - $signed(16'(2*MW));
          e_c   = expc - $signed(16'(MW));
          dd    = e_c - e_p;
          s_raw = $signed(16'(2*PP + 2)) - dd;
          far_above = (s_raw < 16'sd0);
          sh    = far_above ? 16'sd0 : ((s_raw > $signed(16'(WF))) ? $signed(16'(WF)) : s_raw);

          c_pad = {sigc, {(WF-1-PP){1'b0}}};
          shi   = int'(sh);
          if (shi >= (WF-1)) begin
            c_shr = '0;
            c_stk = |c_pad;
          end else begin
            c_shr = c_pad >> shi;
            c_stk = |(c_pad << ((WF-1) - shi));
          end
          c_fld = {c_shr, c_stk};
          p_fld = far_above ? {{(WF-1){1'b0}}, |prod}
                            : {{(PP+2){1'b0}}, prod, 3'b000};
          // Clamping the shift to zero re-anchors the field on the addend, so
          // the weight of bit 3 is no longer e_p: it is whatever e_p would have
          // put the addend at shift zero.
          e_base = far_above ? (e_c - $signed(16'(2*PP + 2))) : e_p;

          eff_sub = sgn_p ^ sc;
          if (!eff_sub) begin
            msum = {1'b0, p_fld} + {1'b0, c_fld};
            rsgn = sgn_p;
          end else if (p_fld >= c_fld) begin
            msum = {1'b0, p_fld - c_fld};
            rsgn = sgn_p;
          end else begin
            msum = {1'b0, c_fld - p_fld};
            rsgn = sc;
          end

          // ---- normalise ----------------------------------------------------
          lz  = 0;
          fnd = 1'b0;
          for (int i = WF; i >= 0; i--)
            if (!fnd && msum[i]) begin
              lz  = i;
              fnd = 1'b1;
            end
          mnrm = msum << (WF - lz);
          ex   = $signed(16'(lz)) + e_base - 16'sd3;
          if (ex < $signed(16'(EMIN))) begin
            rsh = $signed(16'(EMIN)) - ex;
            ebo = $signed(16'(EMIN));
          end else begin
            rsh = 16'sd0;
            ebo = ex;
          end

          rshi = int'(rsh);
          if (rshi >= (WF+1)) begin
            mshf  = '0;
            r_stk = |mnrm;
          end else if (rshi == 0) begin
            mshf  = mnrm;
            r_stk = 1'b0;
          end else begin
            mshf  = mnrm >> rshi;
            r_stk = |(mnrm << ((WF+1) - rshi));
          end

          mant = mshf[WF -: PP];
          rbit = mshf[WF-PP];
          stky = (|mshf[WF-PP-1:0]) | r_stk;

          // ---- round (A2) ---------------------------------------------------
          incr = 1'b0;
          case (rnd_q)
            3'd0: incr = rbit && (stky || mant[0]);   // RNE
            3'd1: incr = 1'b0;                        // RTZ
            3'd2: incr = rsgn && (rbit || stky);      // RDN
            3'd3: incr = !rsgn && (rbit || stky);     // RUP
            3'd4: incr = rbit;                        // RMM
            default: incr = 1'b0;
          endcase
          qrnd = {1'b0, mant} + {{PP{1'b0}}, incr};

          nx = rbit || stky;
          if (qrnd[PP]) ebo = ebo + 16'sd1;
          ebias = ebo + $signed(16'(BIAS));
          if (qrnd[PP]) begin
            eout = ebias[EW-1:0];
            mout = '0;
          end else if (qrnd[PP-1]) begin
            eout = ebias[EW-1:0];
            mout = qrnd[MW-1:0];
          end else begin
            eout = '0;
            mout = qrnd[MW-1:0];
          end

          // ---- overflow (A7) ------------------------------------------------
          of = 1'b0;
          if ((qrnd[PP] || qrnd[PP-1]) &&
              (ebias >= $signed(16'((1 << EW) - 1)))) begin
            of = 1'b1;
            nx = 1'b1;
            to_inf = (rnd_q == 3'd0) || (rnd_q == 3'd4)
                  || (rnd_q == 3'd3 && !rsgn) || (rnd_q == 3'd2 && rsgn);
            if (to_inf) begin
              eout = {EW{1'b1}};
              mout = '0;
            end else begin
              eout = {{(EW-1){1'b1}}, 1'b0};
              mout = {MW{1'b1}};
            end
          end

          // ---- assemble -----------------------------------------------------
          if (nan_out) begin
            lane_res[f][l] = 32'({1'b0, {EW{1'b1}}, 1'b1, {(MW-1){1'b0}}});
            lane_flg[f][l] = {invalid, 4'b0000};
          end else if (inf_out) begin
            lane_res[f][l] = 32'({prod_inf ? sgn_p : sc, {EW{1'b1}}, {MW{1'b0}}});
            lane_flg[f][l] = 5'b00000;
          end else if (a_z || b_z) begin
            // the product is an exact zero: the result is the addend, except
            // that two zeros of opposite sign give +0 (-0 under RDN) -- A6
            if (c_z) begin
              lane_res[f][l] = 32'({(sgn_p == sc) ? sc : (rnd_q == 3'd2),
                                    {EW{1'b0}}, {MW{1'b0}}});
            end else begin
              lane_res[f][l] = 32'(cv);
            end
            lane_flg[f][l] = 5'b00000;
          end else if (msum == '0) begin
            // exact cancellation -- A6
            lane_res[f][l] = 32'({eff_sub ? (rnd_q == 3'd2) : sgn_p,
                                  {EW{1'b0}}, {MW{1'b0}}});
            lane_flg[f][l] = 5'b00000;
          end else begin
            uf = nx && (eout == '0);
            lane_res[f][l] = 32'({rsgn, eout, mout});
            lane_flg[f][l] = {1'b0, 1'b0, of, uf, nx};
          end
        end
      end else begin : g_dead
        assign lane_res[f][l] = 32'd0;
        assign lane_flg[f][l] = 5'd0;
      end
    end
  end

  // ---------------------------------------------------------------------------
  // lane assembly: V1 lane count, V3 high bits all ones, V4 flags OR'd
  // ---------------------------------------------------------------------------
  always_comb begin
    int unsigned nlane;
    result_o = {WIDTH{1'b1}};
    flags_o  = 5'b00000;
    if (fmt_q == 2'd0) begin
      nlane = vec_q ? NL32 : 1;
      for (int k = 0; k < NL32; k++)
        if (k < nlane) begin
          result_o[k*32 +: 32] = lane_res[0][k];
          flags_o              = flags_o | lane_flg[0][k];
        end
    end else begin
      nlane = vec_q ? NL16 : 1;
      for (int k = 0; k < NL16; k++)
        if (k < nlane) begin
          result_o[k*16 +: 16] = (fmt_q == 2'd1) ? lane_res[1][k][15:0]
                                                 : lane_res[2][k][15:0];
          flags_o              = flags_o | ((fmt_q == 2'd1) ? lane_flg[1][k]
                                                            : lane_flg[2][k]);
        end
    end
  end

endmodule