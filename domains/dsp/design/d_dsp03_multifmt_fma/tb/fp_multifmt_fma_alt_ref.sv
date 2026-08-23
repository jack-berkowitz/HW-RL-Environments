// =============================================================================
// fp_multifmt_fma_alt_ref.sv -- SECOND SOURCE. Never shipped, never scored.
// =============================================================================
// Independently written. Shares no code with the shim and does not instantiate
// the anchor: the arithmetic below is exact integer significand arithmetic with
// an explicit alignment window and sticky, which is not how cvfpu does it.
//
// *** IT IS A PROBE, NOT A DELIVERABLE. *** Its job is to catch assumptions the
// negative controls structurally cannot see. The controls only feed the checker
// BAD inputs, so an over-strict checker passes all three of them. Only a design
// that is RIGHT in an unfamiliar way can expose a precondition the harness
// never established (F52).
//
// TARGETED: for every latitude clause the checker observes, this takes the
// OPPOSITE legal choice from the reference.
//
//   L4  handshake   REGISTERED. The reference is purely combinational --
//                   NumPipeRegs = 0, measured latency 0, in_ready_o high every
//                   cycle. This one has a real state machine, in_ready_o does
//                   NOT depend on in_valid_i, and out_valid_o is a flop.
//   L2  latency     THREE CYCLES, not zero.
//   L3  throughput  ONE OPERATION AT A TIME. The reference retires one per
//                   cycle; this one refuses new work while busy, so the
//                   checker's throughput metric moves by ~4x and its liveness
//                   check has to survive that.
//   L1  algorithm   Exact integer significands with a bounded alignment window
//                   and an explicit sticky, against the anchor's structure.
//
// The registered handshake is the point. The checker has already been wrong
// twice about handshake observation on a zero-latency design -- once racing its
// own driver at the negedge, once deadlocking on latched backpressure -- and
// both were invisible to every control.
// =============================================================================

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

  localparam int unsigned AW = 192;   // accumulator width, ample for M = 23

  // ---------------------------------------------------------------------------
  // One lane, combinational, exact.
  // ---------------------------------------------------------------------------
  function automatic logic [68:0] fma_lane(input logic [63:0] xa, input logic [63:0] xb,
                                           input logic [63:0] xc,
                                           input int unsigned E, input int unsigned M,
                                           input logic [2:0] rm);
    int unsigned bias, LIM, k, i;
    // sh is SIGNED. Declared unsigned it wraps when k < M -- which is every
    // cancellation case -- and `mag >> sh` then returns zero.
    int signed   sh;
    int signed   Xa, Xb, Xc, Xp, Xr, Xmax, Xmin, dp, dc, bexp;
    logic [63:0] ea, ebv, ec, ma, mb, mc, qn, canon, top;
    logic        sa, sb, sc, sp, sres, za, zb, zc, ia, ib, ic, na, nb, nc, sna, snb, snc;
    logic [AW-1:0] Sa, Sb, Sc, Sp, accp, accc, mag, magu;
    logic signed [AW-1:0] acc;
    logic [AW-1:0] q, lowmask;
    logic        rbit, sticky, stky_pre, inexact, up, tiny, ovf;
    logic [4:0]  fg;
    logic [63:0] rbits;

    bias = (1 << (E-1)) - 1;
    LIM  = 3*M + 8;
    canon = (((64'd1 << E) - 64'd1) << M) | (64'd1 << (M-1));

    sa = xa[E+M]; sb = xb[E+M]; sc = xc[E+M];
    ea = (xa >> M) & ((64'd1 << E) - 64'd1);
    ebv= (xb >> M) & ((64'd1 << E) - 64'd1);
    ec = (xc >> M) & ((64'd1 << E) - 64'd1);
    ma = xa & ((64'd1 << M) - 64'd1);
    mb = xb & ((64'd1 << M) - 64'd1);
    mc = xc & ((64'd1 << M) - 64'd1);
    top = (64'd1 << E) - 64'd1;

    za = (ea == 0) && (ma == 0);   ia = (ea == top) && (ma == 0);
    zb = (ebv== 0) && (mb == 0);   ib = (ebv== top) && (mb == 0);
    zc = (ec == 0) && (mc == 0);   ic = (ec == top) && (mc == 0);
    na = (ea == top) && (ma != 0); sna = na && !ma[M-1];
    nb = (ebv== top) && (mb != 0); snb = nb && !mb[M-1];
    nc = (ec == top) && (mc != 0); snc = nc && !mc[M-1];
    sp = sa ^ sb;

    // ---- special cases, A4 and A5 -------------------------------------------
    if (sna || snb || snc)                    return {5'b10000, canon};
    if ((ia && zb) || (za && ib))             return {5'b10000, canon};
    if (na || nb || nc)                       return {5'b00000, canon};
    if (ia || ib) begin
      if (ic && (sc != sp))                   return {5'b10000, canon};
      return {5'b00000, (64'(sp) << (E+M)) | (top << M)};
    end
    if (ic)                                   return {5'b00000, xc & ((64'd1 << (E+M+1)) - 64'd1)};

    // ---- exact significands: value = S * 2**X --------------------------------
    Sa = za ? '0 : AW'((ea == 0) ? ma : (ma | (64'd1 << M)));
    Sb = zb ? '0 : AW'((ebv== 0) ? mb : (mb | (64'd1 << M)));
    Sc = zc ? '0 : AW'((ec == 0) ? mc : (mc | (64'd1 << M)));
    Xa = ((ea == 0) ? 1 : int'(ea)) - int'(bias) - int'(M);
    Xb = ((ebv== 0) ? 1 : int'(ebv))- int'(bias) - int'(M);
    Xc = ((ec == 0) ? 1 : int'(ec)) - int'(bias) - int'(M);
    Sp = Sa * Sb;                       // 2M+2 bits
    Xp = Xa + Xb;

    // both zero: A6's sign rule
    if (Sp == 0 && Sc == 0) begin
      if (sp == sc) return {5'b00000, 64'(sp) << (E+M)};
      return {5'b00000, 64'((rm == 3'd2) ? 1'b1 : 1'b0) << (E+M)};
    end
    if (Sp == 0) Xp = Xc;
    if (Sc == 0) Xc = Xp;

    // ---- bounded alignment window -------------------------------------------
    Xmax = (Xp > Xc) ? Xp : Xc;
    Xmin = (Xp < Xc) ? Xp : Xc;
    Xr   = ((Xmax - Xmin) > int'(LIM)) ? (Xmax - int'(LIM)) : Xmin;
    stky_pre = 1'b0;
    dp = Xp - Xr; dc = Xc - Xr;
    accp = '0; accc = '0;
    if (dp < 0) begin stky_pre = stky_pre | (Sp != 0); end else accp = Sp << dp;
    if (dc < 0) begin stky_pre = stky_pre | (Sc != 0); end else accc = Sc << dc;

    acc = (sp ? -$signed({1'b0, accp[AW-2:0]}) : $signed({1'b0, accp[AW-2:0]}))
        + (sc ? -$signed({1'b0, accc[AW-2:0]}) : $signed({1'b0, accc[AW-2:0]}));

    if (acc == 0 && !stky_pre) begin       // exact cancellation, A6
      if (sp == sc) return {5'b00000, 64'(sp) << (E+M)};
      return {5'b00000, 64'((rm == 3'd2) ? 1'b1 : 1'b0) << (E+M)};
    end
    sres = (acc < 0);
    mag  = sres ? AW'(-acc) : AW'(acc);
    // the discarded tail sits below the window: it nudges the magnitude up if it
    // shares the result's sign and down otherwise, and either way it is only
    // ever a sticky.
    //
    // THE CASE THIS DOES NOT GUARD, and why that is a choice rather than luck.
    // If `acc` were ZERO while `stky_pre` were set, the true value would be the
    // discarded tail alone -- nonzero, carrying the DROPPED term's sign, and
    // smaller than any representable increment. `mag - 1` would then wrap. It
    // cannot arise HERE: Xr is `max(Xp,Xc) - LIM`, so the larger term is always
    // retained and `acc` is non-zero whenever anything was dropped.
    //
    // That reasoning is about THIS WINDOW and does not transfer. d_dsp02's
    // second source frames differently, its accumulator CAN empty while a
    // sticky is set, and it wrapped exactly this way -- `0 - 1` across 160 bits,
    // delivering 1d000000 for a product near 2^-298. Same guard, same argument
    // for omitting it, right in one design and wrong in the other.
    //
    // A guard whose necessity depends on a framing choice is a guard whose
    // ABSENCE must be justified against that choice every time it is reused. Do
    // not carry this omission into another design without re-deriving it.
    if (stky_pre) begin
      if (((dp < 0) ? sp : sc) != sres) mag = mag - 1;
    end

    // ---- normalise -----------------------------------------------------------
    // Bounded by a CONSTANT, not by AW. mag < 2**(LIM + 2M + 3) = 2**(5M+11),
    // which is 126 bits at M=23, so 132 covers every format with room. Searching
    // all 192 bits blew the synthesis frontend's unroll budget -- see T5.
    k = 0;
    for (i = 0; i < 132; i++) if (mag[i]) k = i;

    // rounding position, with gradual underflow
    sh  = (int'(k) - int'(M) > (1 - int'(bias) - int'(M)) - Xr)
        ? (k - M) : ((1 - int'(bias) - int'(M)) - Xr);

    // helper: round `mag` at shift `s`, returns q and whether it rounded up
    q = (sh <= 0) ? (mag << (-sh)) : (mag >> sh);
    if (sh <= 0) begin rbit = 1'b0; sticky = stky_pre; end
    else begin
      rbit    = mag[sh-1];
      lowmask = (AW'(1) << (sh-1)) - AW'(1);
      sticky  = ((mag & lowmask) != 0) | stky_pre;
    end
    inexact = rbit | sticky;
    case (rm)
      3'd0: up = rbit & (sticky | q[0]);
      3'd1: up = 1'b0;
      3'd2: up = inexact & sres;
      3'd3: up = inexact & ~sres;
      default: up = rbit;
    endcase
    if (up) q = q + 1;
    if (q[M+1]) begin q = q >> 1; sh = sh + 1; end

    // UNDERFLOW predicate -- TRACKS A PINNED TASK DECISION, 2026-08-21.
    //
    // This is NOT a bug fix and this file was NOT wrong before. It previously
    // implemented IEEE 754-2019 clause 7.5's tininess-after-rounding rule:
    // round at the target precision with an UNBOUNDED EXPONENT, then test
    // against the smallest normal. That is a correct reading of the standard.
    //
    // The CONTRACT changed under it. A7a now pins the delivered-result rule
    // longhand and cites no standard: UF iff inexact AND the delivered result's
    // biased exponent field is zero. The second source and the reference were
    // answering different questions; the task has since decided which question
    // it is asking.
    //
    // The delivered exponent field is zero exactly when the significand did not
    // normalise -- see the assembly below, where !q[M] takes the subnormal/zero
    // branch and leaves the exponent field at 0.
    tiny = ~q[M];

    // ---- assemble ------------------------------------------------------------
    bexp = sh + Xr + int'(M) + int'(bias);
    fg   = 5'b00000;
    ovf  = 1'b0;
    if (q[M]) begin
      if (bexp >= int'(top)) ovf = 1'b1;
    end
    if (ovf) begin
      // clause 7.4: infinity, except the modes that round away from it
      if ((rm == 3'd1) || ((rm == 3'd2) && !sres) || ((rm == 3'd3) && sres))
        rbits = (64'(sres) << (E+M)) | ((top - 64'd1) << M) | ((64'd1 << M) - 64'd1);
      else
        rbits = (64'(sres) << (E+M)) | (top << M);
      return {5'b00101, rbits};
    end
    if (!q[M]) rbits = (64'(sres) << (E+M)) | (q[63:0] & ((64'd1 << M) - 64'd1));
    else       rbits = (64'(sres) << (E+M)) | (64'(bexp) << M) | (q[63:0] & ((64'd1 << M) - 64'd1));
    fg[0] = inexact;
    fg[1] = inexact & tiny;
    return {fg, rbits};
  endfunction

  // ---------------------------------------------------------------------------
  // combinational whole-word evaluation
  // ---------------------------------------------------------------------------
  function automatic int unsigned fw_of(input logic [1:0] f); fw_of = (f == 2'd0) ? 32 : 16; endfunction
  function automatic int unsigned eb_of(input logic [1:0] f); eb_of = (f == 2'd0) ? 8 : (f == 2'd1) ? 5 : 8; endfunction
  function automatic int unsigned mb_of(input logic [1:0] f); mb_of = (f == 2'd0) ? 23 : (f == 2'd1) ? 10 : 7; endfunction

  logic [WIDTH-1:0] comb_res;
  logic [4:0]       comb_flg;

  always_comb begin
    int unsigned FW, N, k, E, M;
    logic [63:0] la, lb, lc, lmask;
    logic [68:0] r;
    logic [WIDTH-1:0] acc;
    E = eb_of(fmt_i); M = mb_of(fmt_i); FW = fw_of(fmt_i);
    N = vec_i ? (WIDTH / FW) : 1;
    lmask = (64'd1 << FW) - 64'd1;
    acc = '1;                      // V3: NaN-boxing above the lanes in use
    comb_flg = 5'b0;
    // CONSTANT bound with a runtime guard inside. `k < N` as the loop condition
    // cannot be bounded at elaboration, and the frontend then multiplies its
    // unroll tally by the leading-one search above and gives up. T5.
    for (k = 0; k < WIDTH/16; k++) if (k < N) begin
      la = (64'(a_i) >> (k*FW)) & lmask;
      lb = (64'(b_i) >> (k*FW)) & lmask;
      lc = (64'(c_i) >> (k*FW)) & lmask;
      r  = fma_lane(la, lb, lc, E, M, rnd_i);
      acc[k*FW +: 16] = r[15:0];
      if (FW == 32) acc[k*FW+16 +: 16] = r[31:16];
      comb_flg = comb_flg | r[68:64];
    end
    comb_res = acc;
  end

  // ---------------------------------------------------------------------------
  // L2/L3/L4: a REGISTERED three-cycle pipeline, one operation at a time, and
  // in_ready_o that does not look at in_valid_i.
  // ---------------------------------------------------------------------------
  typedef enum logic [1:0] { IDLE, RUN, DONE } st_e;
  st_e st_q;
  logic [1:0]       cnt_q;
  logic [WIDTH-1:0] res_q;
  logic [4:0]       flg_q;

  assign in_ready_o  = (st_q == IDLE);
  assign out_valid_o = (st_q == DONE);
  assign result_o    = res_q;
  assign flags_o     = flg_q;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      st_q <= IDLE; cnt_q <= '0; res_q <= '0; flg_q <= '0;
    end else begin
      unique case (st_q)
        IDLE: if (in_valid_i) begin
                res_q <= comb_res; flg_q <= comb_flg; cnt_q <= 2'd2; st_q <= RUN;
              end
        RUN:  if (cnt_q == 0) st_q <= DONE; else cnt_q <= cnt_q - 1;
        DONE: if (out_ready_i) st_q <= IDLE;
        default: st_q <= IDLE;
      endcase
    end
  end

endmodule
