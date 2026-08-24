// =============================================================================
// fp16_gemm_array_alt_ref.sv -- d_ai01 SECOND SOURCE. Never shipped, never
// scored as a submission.
//
// ORACLE CLASS: B -- A LOCAL MODEL OF RECORD, NOT AN EXTERNAL ONE.
// This is written by the same author as the task. RedMulE exposes no shimmable
// boundary for this contract beyond redmule_engine itself, so there is no second
// external RTL to anchor on. NOTHING HERE CARRIES A "PASSES KNOWN-CORRECT
// EXTERNAL RTL" CLAIM. Its evidential value is limited to: an independent
// implementation of the pinned text agrees, or does not, with the reference --
// and where it does not, one of the two is wrong or the text is ambiguous.
//
// SOURCES, STATED HONESTLY RATHER THAN CLAIMED CLEAN.
//   * Written from spec/fp16_gemm_array_iface.sv only. ref/ was NOT opened,
//     read, or consulted at any point while writing this file.
//   * THAT IS NOT A CLEAN ROOM AND IT WOULD BE FALSE TO CALL IT ONE. During the
//     step-0 audit I read redmule_engine.sv in full, redmule_row.sv's body,
//     redmule_ce.sv's output selection, and redmule_fma.sv's pipeline
//     parameters, and I wrote the shim that binds them. The anchor's STRUCTURE
//     -- W rows of H chained computing elements, a registered partial sum
//     between stages, NumPipeRegs=3 DISTRIBUTED inside each element, physically
//     gated row clocks -- is in my working memory and cannot be unlearned.
//   * What follows from that: the structural differences below are DELIBERATE
//     OPPOSITES of a structure I know, not the independent convergence of an
//     ignorant author. That is weaker evidence than a true clean room, and it is
//     stated so the evidence is not over-read. Where it still bites is the
//     ARITHMETIC and the TIMING READINGS, which I derived from the clause text.
//
// STRUCTURAL DIFFERENCES -- claimed here, MEASURED in ALT_REF.md.
//   1. PIPELINE ORGANISATION. One partial-sum shift register per row, of length
//      L = D*(HEIGHT-1)+2, with a fused multiply-add TAPPED IN at position D*k
//      for stage k. The anchor instantiates HEIGHT separate arithmetic units per
//      row, each with its own internal pipeline. Here there is exactly one
//      adder-chain position per register stage and no instantiated unit at all.
//   2. CLOCKING DISCIPLINE. Ordinary flip-flops with a CLOCK ENABLE. The anchor
//      gates the row clock physically. This file instantiates no clock-gating
//      cell of any kind.
//   3. ARITHMETIC ALGORITHM. Every product and sum is formed EXACTLY, as a
//      fixed-point integer at a common scale of 2^EMIN, and rounded once at the
//      end. There is no alignment shifter, no sticky bit, no leading-zero count
//      and no normalisation loop -- the operations that a hardware fused
//      multiply-add is mostly built from.
//   These are independent: (1) is how state is laid out, (2) is how state is
//   held, (3) is how the value is computed. Any one could be changed without
//   the others.
//
// OBSERVED-LATITUDE CLAUSES -- opposite legal choice taken. See ALT_REF.md for
// the table of anchor choice versus this one.
//
// A10 WAS UNPINNED WHEN THIS FILE WAS FIRST WRITTEN, and this file took the
// reading coherent with A3 -- flags arriving alongside the z_o they contributed
// to, i.e. delayed by d(k). The reference took the other legal reading, the two
// disagreed on ~2900 of 3400 cycles, and the clause was found to permit both.
// A10 is now PINNED to a uniform 2-enabled-tick delay, independent of k, and
// this file follows the pinned text: each stage reports its OWN in-flight
// operation, two enabled ticks after that operation's operands.
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

  localparam int unsigned D    = 4;                    // spec L1
  localparam int          EMIN = -80;                  // common fixed-point scale
  localparam int unsigned AW   = 176;                  // exact accumulator width
  localparam int unsigned L    = D*(HEIGHT-1) + 2;     // spec L3
  // ONE MORE REGISTER THAN THE TAP POSITIONS NEED. Measured, not derived: with
  // the output taken at position L the probe returned d(k) = D*(HEIGHT-1-k)+1
  // for every stage and for the bias path -- the right spacing, the constant one
  // short. LZ adds the missing stage. It is never a tap: (L+1) mod D = 3 for
  // both legal HEIGHTs.
  localparam int unsigned LZ   = L + 1;

  // ---------------------------------------------------------------------------
  // Decode a binary16 into an exact integer significand M and exponent E, with
  // value = (-1)^s * M * 2^E. Subnormals need no special case downstream: they
  // simply have a smaller M at the fixed exponent -24.
  // ---------------------------------------------------------------------------
  // UNPACKED, with the exponent as a plain `int`. This started as a packed
  // struct with `logic signed [7:0] e` and was changed on a SUSPICION that a
  // signed member of a packed struct would not carry its signedness through a
  // member select. THAT WAS NOT THE BUG -- the change was made, the unit test
  // re-run, and all 12 failures reproduced identically. The real cause is at the
  // product line below. The unpacked form is kept because it is clearer, not
  // because it fixed anything, and the false lead is recorded so it is not
  // re-tried.
  typedef struct {
    logic        s;
    logic [11:0] m;
    int          e;
    logic        is_zero, is_inf, is_nan, is_snan;
  } dec_t;

  function automatic dec_t decode(input logic [15:0] v);
    logic [4:0] ex; logic [9:0] mn;
    dec_t d;
    begin
      ex = v[14:10]; mn = v[9:0];
      d.s = v[15];
      d.is_zero = (ex == 5'd0)  && (mn == 10'd0);
      d.is_inf  = (ex == 5'h1F) && (mn == 10'd0);
      d.is_nan  = (ex == 5'h1F) && (mn != 10'd0);
      d.is_snan = d.is_nan && (mn[9] == 1'b0);
      if (ex == 5'd0) begin
        d.m = {2'b00, mn};                    // subnormal: no hidden bit
        d.e = -24;
      end else begin
        d.m = {2'b01, mn};                    // normal: hidden bit at position 10
        d.e = int'(ex) - 25;
      end
      return d;
    end
  endfunction

  function automatic int unsigned msb_idx(input logic [AW-1:0] u);
    int unsigned i;
    begin
      msb_idx = 0;
      for (i = 0; i < AW; i++) if (u[i]) msb_idx = i;
      return msb_idx;
    end
  endfunction

  // ---------------------------------------------------------------------------
  // The fused multiply-add. Returns {value, flags} with flags {NV,DZ,OF,UF,NX}.
  // ---------------------------------------------------------------------------
  typedef struct packed { logic [15:0] v; logic [4:0] f; } res_t;

  localparam logic [15:0] QNAN = 16'h7E00;

  function automatic res_t fma16(input logic [15:0] a, b, c, input logic [2:0] rm);
    dec_t da, db, dc;
    res_t r;
    logic sp;
    logic signed [AW-1:0] sc_p, sc_c, sum, u;
    logic [23:0]          prod;
    logic [AW-1:0] uu;
    int unsigned n, nq, sh;
    int e, ulp_e, e_fin;
    logic [AW-1:0] q, rem, halfv;
    logic sgn, inexact, up;
    int ef;
    begin
      da = decode(a); db = decode(b); dc = decode(c);
      r.f = 5'd0;

      // ---- A9 non-finite, and the invalid cases -----------------------------
      if (da.is_snan || db.is_snan || dc.is_snan) begin
        r.v = QNAN; r.f[4] = 1'b1; return r;                       // NV
      end
      if ((da.is_inf && db.is_zero) || (db.is_inf && da.is_zero)) begin
        r.v = QNAN; r.f[4] = 1'b1; return r;                       // inf * 0
      end
      if (da.is_nan || db.is_nan || dc.is_nan) begin
        r.v = QNAN; return r;                                      // quiet, no flag
      end
      sp = da.s ^ db.s;
      if (da.is_inf || db.is_inf) begin
        if (dc.is_inf && (dc.s != sp)) begin
          r.v = QNAN; r.f[4] = 1'b1; return r;                     // inf - inf
        end
        r.v = {sp, 5'h1F, 10'd0}; return r;
      end
      if (dc.is_inf) begin r.v = {dc.s, 5'h1F, 10'd0}; return r; end

      // ---- exact fixed-point product and sum, no alignment, no sticky -------
      // int'() SIGN-EXTENDS. A zero-extending concatenation here turns every
      // negative exponent into a huge positive shift and the model silently
      // returns zero for every subnormal -- the sign extension is the whole
      // correctness of this line.
      // THE PRODUCT IS FORMED IN AN EXPLICITLY WIDE VARIABLE, and that is the
      // whole correctness of this line. Written inline as
      //     {{(AW-24){1'b0}}, da.m * db.m}
      // the multiply sits inside a concatenation, which makes it
      // SELF-DETERMINED: a 12-bit by 12-bit multiply then yields 12 BITS and the
      // top of every product is discarded. 1*1024 survives, 1024*1024 becomes 0,
      // 2047*1024 becomes 3072. That is exactly what the unit test showed --
      // every normal-by-normal case wrong, every subnormal and non-finite case
      // right, because those never form a wide product.
      prod = {12'd0, da.m} * {12'd0, db.m};
      sc_p = $signed({{(AW-24){1'b0}}, prod}) <<< ((da.e + db.e) - EMIN);
      sc_c = $signed({{(AW-12){1'b0}}, dc.m})        <<< (dc.e - EMIN);
      if (sp)   sc_p = -sc_p;
      if (dc.s) sc_c = -sc_c;
      sum = sc_p + sc_c;

      // ---- A8 / exact zero --------------------------------------------------
      if (sum == 0) begin
        if ((da.is_zero || db.is_zero) && dc.is_zero) sgn = (sp == dc.s) ? sp : (rm == 3'd2);
        else                                          sgn = (rm == 3'd2);
        r.v = {sgn, 15'd0};
        return r;
      end

      sgn = (sum < 0);
      u   = sgn ? -sum : sum;
      uu  = u;
      n   = msb_idx(uu);
      e   = int'(n) + EMIN;

      ulp_e = (e >= -14) ? (e - 10) : -24;
      sh    = ulp_e - EMIN;
      q     = uu >> sh;
      rem   = uu - (q << sh);
      halfv = (sh == 0) ? '0 : (({{(AW-1){1'b0}}, 1'b1}) << (sh - 1));
      inexact = (rem != 0);

      up = 1'b0;
      case (rm)
        3'd0: up = (rem > halfv) || ((rem == halfv) && (rem != 0) && q[0]);   // RNE
        3'd1: up = 1'b0;                                                       // RTZ
        3'd2: up = inexact &&  sgn;                                            // RDN
        3'd3: up = inexact && !sgn;                                            // RUP
        3'd4: up = (rem >= halfv) && (rem != 0);                               // RMM
        default: up = 1'b0;
      endcase
      if (up) q = q + 1;

      if (inexact) r.f[0] = 1'b1;                                              // NX

      if (q == 0) begin                     // rounded away to nothing
        r.v = {sgn, 15'd0};
        if (inexact) r.f[1] = 1'b1;                                            // UF
        return r;
      end

      nq    = msb_idx(q);
      e_fin = int'(nq) + ulp_e;

      if (e_fin > 15) begin                 // ---- A5, longhand ---------------
        r.f[2] = 1'b1; r.f[0] = 1'b1;                                          // OF, NX
        case (rm)
          3'd1:    r.v = {sgn, 5'd30, 10'h3FF};                                // RTZ
          3'd2:    r.v = sgn ? {1'b1, 5'h1F, 10'd0} : {1'b0, 5'd30, 10'h3FF};  // RDN
          3'd3:    r.v = sgn ? {1'b1, 5'd30, 10'h3FF} : {1'b0, 5'h1F, 10'd0};  // RUP
          default: r.v = {sgn, 5'h1F, 10'd0};                                  // RNE, RMM
        endcase
        return r;
      end

      if (e_fin < -14) begin                // subnormal delivered
        r.v = {sgn, 5'd0, q[9:0]};
        if (inexact) r.f[1] = 1'b1;                                            // A7: UF only if inexact
        return r;
      end

      ef  = e_fin + 15;
      r.v = {sgn, ef[4:0], (nq >= 10) ? q[nq-1 -: 10] : 10'd0};
      if (ef == 0 && inexact) r.f[1] = 1'b1;
      return r;
    end
  endfunction

  // ---------------------------------------------------------------------------
  // Per-row partial-sum shift register. The fused multiply-add for stage k is
  // tapped in at position D*k; every other position is a plain delay. One
  // register file per row, no instantiated arithmetic units, no gated clocks.
  // ---------------------------------------------------------------------------
  logic [WIDTH-1:0][LZ:0][15:0] psum_q;
  logic [WIDTH-1:0]     [15:0] zprev_q;                 // one extra tick for C3
  // A10 as pinned: a flat 2-deep delay per stage, the SAME for every k. The
  // flags do not ride the partial-sum pipeline -- they are not aligned to the
  // z_o their operation contributes to.
  // THREE deep, read at [2]. The flags for an operation are latched into [0] on
  // the SAME tick its operands are sampled, so [1] is t+1 and [2] is t+2 -- the
  // delay A10 pins. A two-deep array reads t+1: measured against the reference
  // with a four-tick overflow burst, the flags landed one tick early at every
  // stage (mine 0-4/9-12/17-20, reference 1-5/10-13/18-21).
  logic [WIDTH-1:0][HEIGHT-1:0][2:0][4:0] stg_q;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      psum_q  <= '0;
      zprev_q <= '0;
      stg_q   <= '0;
    end else begin
      for (int r = 0; r < WIDTH; r++) begin
        // CLOCK ENABLE, not a gated clock. flush outranks the stall (C2) but a
        // row whose gate is low is frozen even against flush (C2, C4).
        if (row_clk_gate_en_i[r]) begin
          if (flush_i) begin
            for (int p = 0; p <= LZ; p++) psum_q[r][p] <= 16'h0000;
            // stg_q is deliberately NOT cleared here. C2 zeroes the INTER-STAGE
            // registers of the chain; the status pipeline is not one of them, and
            // A10 -- which is what governs status_o -- says nothing about flush.
            // Clearing it was an invented behaviour and produced the only
            // surviving status divergence, at exactly the flush cycles.
            zprev_q[r] <= 16'h0000;
          end else if (reg_enable_i) begin
            automatic logic [15:0] seed;
            automatic logic [15:0] vin;
            automatic res_t        rr;
            // FEED BACK z(t), NOT z(t-1). The pipeline is LZ deep, so seeding
            // with the current output gives dfb = LZ = D*(HEIGHT-1)+3, which is
            // what C3 pins. Seeding with zprev_q gave LZ+1 and was INVISIBLE to
            // both the first-change latency probe and the constant-operand
            // probe -- with a static field z(t) == z(t-1), so neither could see
            // the tap. It shows only under a time-varying field, where it
            // disagrees on 100% of steady-state accumulate ticks.
            seed = accumulate_i ? psum_q[r][LZ] : y_i[r];
            for (int k = 0; k < HEIGHT; k++) begin
              stg_q[r][k][2] <= stg_q[r][k][1];
              stg_q[r][k][1] <= stg_q[r][k][0];
            end
            for (int p = 0; p <= LZ; p++) begin
              vin = (p == 0) ? seed : psum_q[r][p-1];
              if ((p % D) == 0 && (p / D) < HEIGHT) begin
                rr = fma16(x_i[r][p/D], w_i[p/D], vin, rnd_i);
                psum_q[r][p] <= rr.v;
                for (int kk = 0; kk < HEIGHT; kk++)
                  if (kk == (p / D)) stg_q[r][kk][0] <= rr.f;
              end else begin
                psum_q[r][p] <= vin;
              end
            end
            zprev_q[r] <= psum_q[r][LZ];
          end
        end
      end
    end
  end

  for (genvar r = 0; r < WIDTH; r++) begin : gen_out
    assign z_o[r] = psum_q[r][LZ];
    for (genvar k = 0; k < HEIGHT; k++) begin : gen_st
      assign status_o[r][k] = stg_q[r][k][2];
    end
  end

endmodule
