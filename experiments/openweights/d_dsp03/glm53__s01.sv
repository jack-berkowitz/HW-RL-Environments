// =============================================================================
// fp_multifmt_fma -- multi-format fused multiply-add (FP32 / FP16 / BF16)
//
// One FMA core per (format, lane), generated with per-format geometry, so the
// significand datapath of each format is 3p+3 bits (<= 4p per A8).  The unit
// is fully combinational (latency 0): out_valid_o = in_valid_i and
// in_ready_o = out_ready_i, which uses neither of the two forbidden
// combinational paths of L4.
//
// Algorithm (per lane): exact 2p-bit product; addend aligned into a (3p+3)-bit
// fixed-point window around it (frame chosen by the exponent difference, with
// saturation to a sticky bit when one operand is beyond half-ulp of the
// other); signed add; variable normalise; single rounding with guard/round/
// sticky in all five modes; subnormal results produced by fixed shift.
// =============================================================================

module fp_multifmt_fma #(
  parameter int unsigned WIDTH = 64        // {32, 64}
) (
  input  logic             clk_i,
  input  logic             rst_ni,         // active low

  input  logic             in_valid_i,
  output logic             in_ready_o,
  input  logic [1:0]       fmt_i,          // 0 = FP32, 1 = FP16, 2 = BF16
  input  logic             vec_i,          // 1 = packed SIMD lanes
  input  logic [WIDTH-1:0] a_i,
  input  logic [WIDTH-1:0] b_i,
  input  logic [WIDTH-1:0] c_i,
  input  logic [2:0]       rnd_i,          // 0 RNE, 1 RTZ, 2 RDN, 3 RUP, 4 RMM

  output logic             out_valid_o,
  input  logic             out_ready_i,
  output logic [WIDTH-1:0] result_o,
  output logic [4:0]       flags_o         // {NV, DZ, OF, UF, NX}
);

  localparam int unsigned N32 = WIDTH / 32;
  localparam int unsigned N16 = WIDTH / 16;

  logic [31:0] res32 [N32];
  logic [4:0]  fl32  [N32];
  logic [15:0] res16 [2][N16];
  logic [4:0]  fl16  [2][N16];

  int unsigned k;
  int unsigned fi;

  // fully combinational transfer, using only the two permitted paths (L4)
  assign in_ready_o  = out_ready_i;
  assign out_valid_o = in_valid_i;

  // ---------------------------------------------------------------------------
  // one FMA core per (format, lane); per-format widths are elaboration
  // constants inside each generate instance
  // ---------------------------------------------------------------------------
  for (genvar gf = 0; gf < 3; gf++) begin : g_fmt
    localparam int FW   = (gf == 0) ? 32 : 16;
    localparam int EW   = (gf == 0) ? 8  : ((gf == 1) ? 5 : 8);
    localparam int PW   = (gf == 0) ? 23 : ((gf == 1) ? 10 : 7);
    localparam int BIAS = (gf == 1) ? 15 : 127;
    localparam int PR   = PW + 1;          // precision incl. implicit bit
    localparam int WD   = 3*PR + 3;        // significand window (<= 4*PR)
    localparam int EMIN = 1 - BIAS;
    localparam int NL   = (gf == 0) ? N32 : N16;

    for (genvar gl = 0; gl < N16; gl++) begin : g_lane
      if (gl < NL) begin : g_core

        logic [FW-1:0] opa, opb, opc, res;
        logic [4:0]    fl;
        logic sa, sb, sc;
        logic [EW-1:0] ea, eb, ec;
        logic [PW-1:0] ma, mb, mcf;
        logic a_nan, a_inf, a_zero, a_snan;
        logic b_nan, b_inf, b_zero, b_snan;
        logic c_nan, c_inf, c_zero, c_snan;
        logic [PR-1:0] siga, sigb, sigc;
        int  e_a, e_b, e_c;
        logic sp;
        logic [2*PR-1:0] pm;
        int  ep, kk, gg, tt, lsh, ew, h, EE, DD, sh;
        logic [WD-1:0] prod_pl, add_pl;
        logic stk;
        logic signed [WD+1:0] Sp, Sc, Ssum;
        logic rs;
        logic [WD-1:0] Mm;
        logic [PR-1:0] sig;
        logic gd, rd, st, inc;
        logic [PR:0] sig_sum;
        logic [EW-1:0] expf;
        logic of, uf, nx, is_inf;
        logic invalid, any_nan, prod_inf;
        logic rz;
        int  li;

        assign opa = a_i[gl*FW +: FW];
        assign opb = b_i[gl*FW +: FW];
        assign opc = c_i[gl*FW +: FW];

        always_comb begin
          // ---------------- defaults ----------------
          res     = {1'b0, {EW{1'b1}}, 1'b1, {PW-1{1'b0}}};   // canonical qNaN
          fl      = 5'b0;
          stk     = 1'b0;
          expf    = '0;
          rs      = 1'b0;
          Mm      = '0;
          sig     = '0;
          gd      = 1'b0;
          rd      = 1'b0;
          st      = 1'b0;
          inc     = 1'b0;
          sig_sum = '0;
          prod_pl = '0;
          add_pl  = '0;
          Sp      = '0;
          Sc      = '0;
          Ssum    = '0;
          pm      = '0;
          h  = -1;  EE = 0;  DD = 0;  sh = 0;  ew = 0;  kk = 0;
          gg = 0;   tt = 0;  lsh = 0; ep = 0;
          e_a = 0;  e_b = 0;  e_c = 0;
          of = 1'b0; uf = 1'b0; nx = 1'b0; is_inf = 1'b0; rz = 1'b0;

          // ---------------- decode ----------------
          sa = opa[FW-1]; ea = opa[FW-2:PW]; ma = opa[PW-1:0];
          sb = opb[FW-1]; eb = opb[FW-2:PW]; mb = opb[PW-1:0];
          sc = opc[FW-1]; ec = opc[FW-2:PW]; mcf = opc[PW-1:0];

          a_nan  = (ea == {EW{1'b1}}) && (ma  != '0);
          a_inf  = (ea == {EW{1'b1}}) && (ma  == '0);
          a_snan = a_nan && !ma[PW-1];
          a_zero = (ea == '0) && (ma == '0);
          siga   = (ea == '0) ? {1'b0, ma} : {1'b1, ma};
          e_a    = (ea == '0) ? EMIN : (int'(ea) - BIAS);

          b_nan  = (eb == {EW{1'b1}}) && (mb  != '0);
          b_inf  = (eb == {EW{1'b1}}) && (mb  == '0);
          b_snan = b_nan && !mb[PW-1];
          b_zero = (eb == '0) && (mb == '0);
          sigb   = (eb == '0) ? {1'b0, mb} : {1'b1, mb};
          e_b    = (eb == '0) ? EMIN : (int'(eb) - BIAS);

          c_nan  = (ec == {EW{1'b1}}) && (mcf != '0);
          c_inf  = (ec == {EW{1'b1}}) && (mcf == '0);
          c_snan = c_nan && !mcf[PW-1];
          c_zero = (ec == '0) && (mcf == '0);
          sigc   = (ec == '0) ? {1'b0, mcf} : {1'b1, mcf};
          e_c    = (ec == '0) ? EMIN : (int'(ec) - BIAS);

          sp       = sa ^ sb;
          prod_inf = a_inf | b_inf;
          invalid  = a_snan | b_snan | c_snan
                   | ((a_inf & b_zero) | (a_zero & b_inf))
                   | (prod_inf & c_inf & (sp != sc));
          any_nan  = a_nan | b_nan | c_nan;

          // ---------------- special cases ----------------
          if (invalid) begin
            res = {1'b0, {EW{1'b1}}, 1'b1, {PW-1{1'b0}}};
            fl  = 5'b10000;                                   // NV
          end else if (any_nan) begin
            res = {1'b0, {EW{1'b1}}, 1'b1, {PW-1{1'b0}}};
          end else if (prod_inf) begin
            res = {sp, {EW{1'b1}}, {PW{1'b0}}};
          end else if (c_inf) begin
            res = {sc, {EW{1'b1}}, {PW{1'b0}}};
          end else if (a_zero | b_zero) begin
            // exact product is zero: result is c (with IEEE zero-sum sign rule)
            if (c_zero) begin
              rz  = (sp == sc) ? sp : (rnd_i == 3'd2);
              res = {rz, {EW{1'b0}}, {PW{1'b0}}};
            end else begin
              res = opc;
            end
          end else begin
            // ---------------- fused datapath ----------------
            pm = siga * sigb;                 // exact 2p-bit product
            ep = e_a + e_b;
            kk = e_c - ep;

            if (kk >= 2) begin
              // addend at least 4x the product: addend at window top,
              // product shifted down (or sticky-only when far below)
              ew     = e_c - 3*PR - 1;
              add_pl = sigc << (2*PR + 2);
              if (kk >= PR + 4) begin
                prod_pl = '0;
                stk     = (pm != '0);
              end else begin
                gg      = kk - 1;
                prod_pl = pm << (PR + 2 - gg);
              end
            end else begin
              // product at top of window, addend shifted into/ below it
              ew      = ep - 3*PR;
              prod_pl = pm << (PR + 2);
              lsh     = 2*PR + 1 + kk;
              if (lsh >= 0) begin
                add_pl = sigc << lsh;
              end else begin
                tt = -lsh;
                if (tt >= PR) begin
                  add_pl = '0;
                  stk    = (sigc != '0);
                end else begin
                  add_pl = sigc >> tt;
                  stk    = (sigc[tt-1:0] != '0);
                end
              end
            end

            Sp    = sp ? -$signed({2'b00, prod_pl}) : $signed({2'b00, prod_pl});
            Sc    = sc ? -$signed({2'b00, add_pl}) : $signed({2'b00, add_pl});
            Ssum  = Sp + Sc;
            rs    = Ssum[WD+1];
            if (Ssum < 0) begin
              Sp = -Ssum;
              Mm = Sp[WD-1:0];
            end else begin
              Mm = Ssum[WD-1:0];
            end

            if ((Mm == '0) && !stk) begin
              // exact zero of opposite-sign terms (A6)
              res = {(rnd_i == 3'd2), {EW{1'b0}}, {PW{1'b0}}};
            end else begin
              if (Mm == '0) rs = (kk >= 2) ? sp : sc;

              // leading-one search (constant bound)
              h = -1;
              for (li = WD-1; li >= 0; li--) begin
                if ((h < 0) && Mm[li]) h = li;
              end
              EE = ew + h;

              // extract p-bit significand plus guard/round/sticky
              if (EE >= EMIN) begin
                sh = h - (PR - 1);
                if (sh >= 0) begin
                  sig = Mm[sh +: PR];
                  if (sh >= 1) gd = Mm[sh-1];
                  if (sh >= 2) rd = Mm[sh-2];
                  if (sh >= 3) st = st | (|Mm[sh-3:0]);
                end else begin
                  sig = Mm << (-sh);
                end
              end else begin
                DD = EMIN - (PR - 1) - ew;
                if (DD <= 0) begin
                  sig = Mm << (-DD);
                end else if (DD >= WD) begin
                  st = st | (|Mm);
                end else begin
                  sig = Mm >> DD;
                  if (DD >= 1) gd = Mm[DD-1];
                  if (DD >= 2) rd = Mm[DD-2];
                  if (DD >= 3) st = st | (|Mm[DD-3:0]);
                end
              end
              st = st | stk;

              // single rounding, all five modes
              case (rnd_i)
                3'd0:    inc = gd & (rd | st | sig[0]);
                3'd1:    inc = 1'b0;
                3'd2:    inc = rs & (gd | rd | st);
                3'd3:    inc = (~rs) & (gd | rd | st);
                3'd4:    inc = gd;
                default: inc = 1'b0;
              endcase

              sig_sum = {1'b0, sig};
              if (inc) sig_sum = sig_sum + 1'b1;
              nx = gd | rd | st;

              if (EE >= EMIN) begin
                if (sig_sum[PR]) begin
                  sig_sum = sig_sum >> 1;
                  EE = EE + 1;
                end
                if (EE > BIAS) begin
                  of     = 1'b1;
                  nx     = 1'b1;
                  is_inf = (rnd_i == 3'd0) | (rnd_i == 3'd4) |
                           ((rnd_i == 3'd3) & ~rs) | ((rnd_i == 3'd2) & rs);
                  if (is_inf) res = {rs, {EW{1'b1}}, {PW{1'b0}}};
                  else        res = {rs, {EW-1{1'b1}}, 1'b0, {PW{1'b1}}};
                end else begin
                  expf = EE + BIAS;
                  res  = {rs, expf, sig_sum[PR-2:0]};
                end
              end else begin
                // subnormal delivery; carry into the smallest normal is natural
                if (sig_sum[PR-1]) expf = {{(EW-1){1'b0}}, 1'b1};
                uf = nx & (expf == '0);        // A7a: delivered exponent field
                res = {rs, expf, sig_sum[PR-2:0]};
              end
              fl = {1'b0, 1'b0, of, uf, nx};
            end
          end
        end

        if (gf == 0) begin : o32
          assign res32[gl] = res;
          assign fl32[gl]  = fl;
        end else begin : o16
          assign res16[gf-1][gl] = res;
          assign fl16[gf-1][gl]  = fl;
        end
      end
    end
  end

  // ---------------------------------------------------------------------------
  // lane mux / NaN-boxing / flag OR
  // ---------------------------------------------------------------------------
  always_comb begin
    result_o = '1;                       // V3: unused high bits are all ones
    flags_o  = 5'b0;
    fi       = (fmt_i == 2'd2) ? 1 : 0;
    if (fmt_i == 2'd0) begin
      for (k = 0; k < N32; k++) begin
        if (vec_i || (k == 0)) begin
          result_o[k*32 +: 32] = res32[k];
          flags_o = flags_o | fl32[k];
        end
      end
    end else begin
      for (k = 0; k < N16; k++) begin
        if (vec_i || (k == 0)) begin
          result_o[k*16 +: 16] = res16[fi][k];
          flags_o = flags_o | fl16[fi][k];
        end
      end
    end
  end

endmodule
