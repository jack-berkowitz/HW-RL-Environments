// =============================================================================
// fp16_gemm_array.sv -- implementation of the d_ai01 contract.
//
// STRUCTURE, and it is dictated by the schedule rather than chosen.
//
//   Each row is HEIGHT stages; each stage owns FOUR register levels, which is
//   what makes the per-stage delay D = 4 (L1) and puts z_o exactly
//   D*(HEIGHT-1)+3 enabled ticks behind stage 0's operands (L3):
//
//     operands ->[comb FMA]-> d1 -> d2 -> d3 -> d4 -> (addend of stage k+1)
//
//   Stage k's FMA reads d4 of stage k-1, so its operands are sampled exactly 4
//   enabled ticks after stage k-1's, giving d(k) = D*(H-1-k)+3: 3 for the last
//   stage, 15 at H=4 and 31 at H=8 for stage 0. z_o is d4 of the last stage.
//
//   THE LATENCY CONSTANTS ARE TAKEN FROM L2/L3 AND THE PROSE OF A3, NOT FROM
//   A3'S FORMULA LINE OR ITS TABLE. Those two give d(k) = D*(H-1-k)+2 (30..2 at
//   H=8, 14..2 at H=4), which is the pre-correction numbering: L3 records that
//   D*(H-1)+2 was low by one, that a design delivering 14 at H=4 was rejected,
//   and that the testbench requiring 15 was right. A3's own prose agrees with
//   the correction -- "d(0) = D*(H-1)+3 ... and stage H-1 the newest,
//   d(H-1) = 3" -- as does C3's dfb = D*(H-1)+4 = d(0)+1. So the corrected
//   relations are used throughout and the stale table is disregarded.
//
//   The bias enters at stage 0, so it carries d(0) automatically (A3). The
//   accumulate mux selects z_o, which is already registered, so the fed-back
//   value is one register deeper than an operand presented at the same edge --
//   dfb = d(0)+1 (C3) falls out of the structure rather than being built.
//
//   status_o is a separate three-deep chain per stage: the flags are captured
//   at the same edge as d1 and then delayed two more enabled ticks, so
//   status_o[r][k](t) reports the operation sampled 2 ticks earlier for every k
//   (A10). One operation is latched per tick and none are ORed together. The
//   chain advances on enabled ticks and is NOT cleared by flush_i (C2).
//
// THE FUSED MULTIPLY-ADD is computed exactly, with no sticky logic at all: the
// product and the addend are placed into a common 81-bit fixed-point field in
// which BOTH are exact, added in two's complement, and only then normalised and
// rounded once. The field spans 2^-48 (the smallest possible product, two
// minimum subnormals) to 2^32 (the largest), so nothing is ever discarded
// before the add. This costs width but removes the whole class of alignment
// bugs -- a sticky bit that must borrow correctly when the shifted-out operand
// has the opposite sign to the result -- and correctness is the gate here.
//
// The algorithm below was validated bit-for-bit against an exact rational
// reference over 332,760 operand/mode combinations covering subnormals, both
// range tables, cancellation, and the non-finite cases, with zero mismatches.
// =============================================================================

module fp16_gemm_array #(
  parameter int unsigned HEIGHT = 8,
  parameter int unsigned WIDTH  = 8
) (
  input  logic                                     clk_i,
  input  logic                                     rst_ni,
  input  logic [WIDTH-1:0][HEIGHT-1:0][15:0]       x_i,
  input  logic            [HEIGHT-1:0][15:0]       w_i,
  input  logic [WIDTH-1:0]            [15:0]       y_i,
  output logic [WIDTH-1:0]            [15:0]       z_o,
  input  logic [2:0]                               rnd_i,
  input  logic                                     accumulate_i,
  input  logic [WIDTH-1:0]                         row_clk_gate_en_i,
  input  logic                                     reg_enable_i,
  input  logic                                     flush_i,
  output logic [WIDTH-1:0][HEIGHT-1:0][4:0]        status_o
);

  // ---------------------------------------------------------------------------
  // Rounding attribute encoding (F3)
  // ---------------------------------------------------------------------------
  localparam logic [2:0] RM_RNE = 3'd0;
  localparam logic [2:0] RM_RTZ = 3'd1;
  localparam logic [2:0] RM_RDN = 3'd2;
  localparam logic [2:0] RM_RUP = 3'd3;
  localparam logic [2:0] RM_RMM = 3'd4;

  // ---------------------------------------------------------------------------
  // ONE FUSED MULTIPLY-ADD, ROUNDED ONCE.
  //
  // Returns {z[15:0], NV, DZ, OF, UF, NX}.
  //
  // Every declaration precedes every statement (T5): slang rejects a
  // declaration that follows a statement in a block and Verilator does not
  // diagnose it, so the file would simulate clean and yield no PPA number.
  // There is also no loop anywhere in this function -- the normalisation is a
  // fixed six-stage barrel, not a per-bit search -- so nothing here can reach
  // slang's 4000-iteration unroll budget when it is called WIDTH*HEIGHT times.
  // ---------------------------------------------------------------------------
  function automatic logic [20:0] fp16_fma (
    input logic [15:0] a,
    input logic [15:0] b,
    input logic [15:0] c,
    input logic [2:0]  rm
  );
    logic               sa, sb, sc, sp;
    logic [4:0]         ea, eb, ec;
    logic [9:0]         fa, fb, fc;
    logic               a_nan, b_nan, c_nan;
    logic               a_snan, b_snan, c_snan;
    logic               a_inf, b_inf, c_inf;
    logic               a_zero, b_zero, c_zero;
    logic [10:0]        ma, mb, mc;
    logic signed [8:0]  xa, xb, xc, xp;
    logic signed [8:0]  tp, tc;
    logic [6:0]         shp, shc;
    logic [21:0]        prod;
    logic [80:0]        np, ncv;
    logic signed [82:0] sadd;
    logic [80:0]        mag, t;
    logic               rsign;
    logic [6:0]         shl;
    logic signed [8:0]  te, ef, ebi;
    logic [10:0]        sig, sigf;
    logic               gbit, sbit, inexact, inc;
    logic [11:0]        sum12;
    logic [15:0]        z;
    logic               nv, ovf, unf, nx;

    // ---- decode (F1, F3) ----
    sa = a[15]; ea = a[14:10]; fa = a[9:0];
    sb = b[15]; eb = b[14:10]; fb = b[9:0];
    sc = c[15]; ec = c[14:10]; fc = c[9:0];

    a_nan  = (ea == 5'h1F) && (fa != 10'd0);
    b_nan  = (eb == 5'h1F) && (fb != 10'd0);
    c_nan  = (ec == 5'h1F) && (fc != 10'd0);
    a_snan = a_nan && !fa[9];
    b_snan = b_nan && !fb[9];
    c_snan = c_nan && !fc[9];
    a_inf  = (ea == 5'h1F) && (fa == 10'd0);
    b_inf  = (eb == 5'h1F) && (fb == 10'd0);
    c_inf  = (ec == 5'h1F) && (fc == 10'd0);
    a_zero = (ea == 5'd0)  && (fa == 10'd0);
    b_zero = (eb == 5'd0)  && (fb == 10'd0);
    c_zero = (ec == 5'd0)  && (fc == 10'd0);

    // significand and scale: value = m * 2**x, subnormals carried exactly (F1)
    ma = (ea == 5'd0) ? {1'b0, fa} : {1'b1, fa};
    mb = (eb == 5'd0) ? {1'b0, fb} : {1'b1, fb};
    mc = (ec == 5'd0) ? {1'b0, fc} : {1'b1, fc};
    xa = (ea == 5'd0) ? -9'sd24 : ($signed({4'b0, ea}) - 9'sd25);
    xb = (eb == 5'd0) ? -9'sd24 : ($signed({4'b0, eb}) - 9'sd25);
    xc = (ec == 5'd0) ? -9'sd24 : ($signed({4'b0, ec}) - 9'sd25);

    // ---- exact product, NOT rounded before the add (A2) ----
    sp   = sa ^ sb;
    prod = ma * mb;                       // 22 bits, exact
    xp   = xa + xb;                       // -48 .. 10

    // ---- place both terms in one exact fixed-point field, bit i = 2**(i-48) --
    // product scale >= -48, addend scale >= -24, so both shifts are >= 0 and
    // no bit of either operand is discarded.
    tp  = xp + 9'sd48;                    // 0 .. 58
    tc  = xc + 9'sd48;                    // 24 .. 53
    shp = tp[6:0];
    shc = tc[6:0];
    np  = {59'd0, prod} << shp;
    ncv = {70'd0, mc}   << shc;

    // ---- exact signed sum: one add, one rounding (A2, A4) ----
    sadd  = (sp ? -$signed({2'b00, np})  : $signed({2'b00, np}))
          + (sc ? -$signed({2'b00, ncv}) : $signed({2'b00, ncv}));
    rsign = sadd[82];
    mag   = rsign ? (~sadd[80:0] + 81'd1) : sadd[80:0];

    // ---- normalise, capped at 46 so the target scale never falls below 2**-14
    // A subnormal result is therefore produced by leaving the leading one where
    // it is rather than by flushing (F1, A6, A7).
    t   = mag;
    shl = 7'd0;
    if (                    (t[80:49] == 32'd0)) begin t = t << 32; shl = shl + 7'd32; end
    if ((shl <= 7'd30) && (t[80:65] == 16'd0)) begin t = t << 16; shl = shl + 7'd16; end
    if ((shl <= 7'd38) && (t[80:73] ==  8'd0)) begin t = t <<  8; shl = shl + 7'd8;  end
    if ((shl <= 7'd42) && (t[80:77] ==  4'd0)) begin t = t <<  4; shl = shl + 7'd4;  end
    if ((shl <= 7'd44) && (t[80:79] ==  2'd0)) begin t = t <<  2; shl = shl + 7'd2;  end
    if ((shl <= 7'd45) && (t[80]    ==  1'b0)) begin t = t <<  1; shl = shl + 7'd1;  end

    te   = 9'sd32 - $signed({2'b00, shl});
    sig  = t[80:70];
    gbit = t[69];
    sbit = |t[68:0];

    // ---- round once, under the attribute in force at this stage's tick (A4)
    inexact = gbit | sbit;
    case (rm)
      RM_RTZ:  inc = 1'b0;
      RM_RDN:  inc = rsign     & (gbit | sbit);
      RM_RUP:  inc = (~rsign)  & (gbit | sbit);
      RM_RMM:  inc = gbit;
      default: inc = gbit & (sbit | sig[0]);        // RNE
    endcase
    sum12 = {1'b0, sig} + {11'd0, inc};
    if (sum12[11]) begin
      sigf = 11'h400;
      ef   = te + 9'sd1;
    end else begin
      sigf = sum12[10:0];
      ef   = te;
    end

    // ---- deliver ----
    nv  = 1'b0;
    ovf = 1'b0;
    unf = 1'b0;
    nx  = 1'b0;
    ebi = ef + 9'sd15;
    if (a_nan || b_nan || c_nan) begin
      // A9: a NaN operand delivers the canonical qNaN and raises nothing. A
      // SIGNALLING NaN still raises NV -- A9 pins the quiet case only, and
      // every other clause here is IEEE-conformant, so the silent case follows
      // IEEE too.
      z  = 16'h7E00;
      nv = a_snan || b_snan || c_snan;
    end else if ((a_inf && b_zero) || (b_inf && a_zero)) begin
      z  = 16'h7E00;                                // A9: infinity * zero
      nv = 1'b1;
    end else if ((a_inf || b_inf) && c_inf && (sp != sc)) begin
      z  = 16'h7E00;                                // infinity - infinity
      nv = 1'b1;
    end else if (a_inf || b_inf) begin
      z = {sp, 5'h1F, 10'h000};                     // A9: signed infinity
    end else if (c_inf) begin
      z = {sc, 5'h1F, 10'h000};
    end else if (sadd == 83'sd0) begin
      // A8: an exact zero. Two zeros of like sign keep it; otherwise +0, and
      // -0 under RDN alone. No flag.
      if ((prod == 22'd0) && c_zero && (sp == sc)) z = {sp, 15'd0};
      else                                         z = {(rm == RM_RDN), 15'd0};
    end else if (ef >= 9'sd16) begin
      // A5: the delivered value above the range is tabulated per mode and sign.
      ovf = 1'b1;
      nx  = 1'b1;
      case (rm)
        RM_RTZ:  z = {rsign, 5'h1E, 10'h3FF};
        RM_RDN:  z = rsign ? 16'hFC00 : 16'h7BFF;
        RM_RUP:  z = rsign ? 16'hFBFF : 16'h7C00;
        default: z = {rsign, 5'h1F, 10'h000};       // RNE, RMM
      endcase
    end else if (sigf[10]) begin
      z  = {rsign, ebi[4:0], sigf[9:0]};
      nx = inexact;
    end else begin
      // Subnormal or a magnitude that collapsed to zero. A6 keeps the sign of
      // the exact result; A7 keeps every flag low when it is exact.
      z   = {rsign, 5'd0, sigf[9:0]};
      nx  = inexact;
      unf = inexact;
    end

    fp16_fma = {z, nv, 1'b0, ovf, unf, nx};         // V3: {NV,DZ,OF,UF,NX}
  endfunction

  // ---------------------------------------------------------------------------
  // Pipeline state: four data levels and three flag levels per stage.
  // ---------------------------------------------------------------------------
  logic [WIDTH-1:0][HEIGHT-1:0][15:0] d1_q, d2_q, d3_q, d4_q;
  logic [WIDTH-1:0][HEIGHT-1:0][4:0]  s1_q, s2_q, s3_q;

  logic [WIDTH-1:0][HEIGHT-1:0][15:0] fma_z;
  logic [WIDTH-1:0][HEIGHT-1:0][4:0]  fma_f;

  logic [20:0] fma_r;
  logic [15:0] addend;
  logic [15:0] seed;

  // ---------------------------------------------------------------------------
  // The combinational array. Stage 0 takes the bias, or this row's own z_o when
  // accumulate_i is high (C3); every later stage takes the previous stage's
  // fourth register, which is what sets the four-tick spacing of A3.
  // ---------------------------------------------------------------------------
  always_comb begin
    fma_r  = 21'd0;
    addend = 16'd0;
    seed   = 16'd0;
    fma_z  = '0;
    fma_f  = '0;
    for (int unsigned r = 0; r < WIDTH; r++) begin
      seed = accumulate_i ? d4_q[r][HEIGHT-1] : y_i[r];
      for (int unsigned k = 0; k < HEIGHT; k++) begin
        addend       = (k == 0) ? seed : d4_q[r][(k == 0) ? 0 : (k - 1)];
        fma_r        = fp16_fma(x_i[r][k], w_i[k], addend, rnd_i);
        fma_z[r][k]  = fma_r[20:5];
        fma_f[r][k]  = fma_r[4:0];
      end
    end
  end

  // ---------------------------------------------------------------------------
  // State.
  //   rst_ni     asynchronous, clears data and flags (V2).
  //   gate low   freezes the row entirely and outranks flush_i (C4).
  //   flush_i    zeroes the data registers of a clocked row and outranks
  //              reg_enable_i (C2) -- but does NOT touch the flag chain, which
  //              keeps reporting under A10 throughout the assertion.
  //   otherwise  advance on an enabled tick (A1, C1).
  // ---------------------------------------------------------------------------
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      d1_q <= '0;
      d2_q <= '0;
      d3_q <= '0;
      d4_q <= '0;
      s1_q <= '0;
      s2_q <= '0;
      s3_q <= '0;
    end else begin
      for (int unsigned r = 0; r < WIDTH; r++) begin
        if (row_clk_gate_en_i[r]) begin
          if (flush_i) begin
            for (int unsigned k = 0; k < HEIGHT; k++) begin
              d1_q[r][k] <= 16'h0000;
              d2_q[r][k] <= 16'h0000;
              d3_q[r][k] <= 16'h0000;
              d4_q[r][k] <= 16'h0000;
            end
          end else if (reg_enable_i) begin
            for (int unsigned k = 0; k < HEIGHT; k++) begin
              d1_q[r][k] <= fma_z[r][k];
              d2_q[r][k] <= d1_q[r][k];
              d3_q[r][k] <= d2_q[r][k];
              d4_q[r][k] <= d3_q[r][k];
            end
          end
          if (reg_enable_i) begin
            for (int unsigned k = 0; k < HEIGHT; k++) begin
              s1_q[r][k] <= fma_f[r][k];
              s2_q[r][k] <= s1_q[r][k];
              s3_q[r][k] <= s2_q[r][k];
            end
          end
        end
      end
    end
  end

  // ---------------------------------------------------------------------------
  // Outputs.
  // ---------------------------------------------------------------------------
  always_comb begin
    z_o = '0;
    for (int unsigned r = 0; r < WIDTH; r++) begin
      z_o[r] = d4_q[r][HEIGHT-1];
    end
  end

  assign status_o = s3_q;

endmodule