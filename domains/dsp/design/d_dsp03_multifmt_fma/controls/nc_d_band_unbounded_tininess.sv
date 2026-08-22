// =============================================================================
// nc_d_band_unbounded_tininess.sv -- NEGATIVE CONTROL D. Never shipped.
// =============================================================================
// CONTRACT-CLAUSE control for A7a, the underflow predicate.
//
// NAMING. d_dsp02 carries this as a MUTANT (mA8); Tier-B skips mutant sets, so
// in this task the same artefact is a negative control. Identical job either
// way: it must FAIL on the band vectors, in all three formats.
//
// WHY IT EXISTS. A7a pins the delivered-result rule and departs from IEEE
// 754-2019 clause 7.5 in one band. The second source and the Python model were
// both changed to track that decision (2026-08-21), so NEITHER can disagree
// with the anchor there any more -- independence on this clause is now absent
// by construction. This control is the replacement discrimination. If it stops
// being killed, nothing is watching A7a.
//
// EXPECTED: FAIL at both WIDTH settings, on the BAND rows under RNE, RUP and
// RMM, in FP32, FP16 and BF16. Correct on every other vector -- results are
// untouched and only the UF bit moves.
// =============================================================================
module fp_multifmt_fma #(
  parameter int unsigned WIDTH = 64            // {32, 64}
) (
  input  logic        clk_i,
  input  logic        rst_ni,
  input  logic        in_valid_i,
  output logic        in_ready_o,
  input  logic [1:0]  fmt_i,        // 0 = FP32, 1 = FP16, 2 = BF16
  input  logic        vec_i,        // 1 = two 16-bit lanes; illegal with FP32
  input  logic [WIDTH-1:0] a_i,
  input  logic [WIDTH-1:0] b_i,
  input  logic [WIDTH-1:0] c_i,
  input  logic [2:0]  rnd_i,
  output logic        out_valid_o,
  input  logic        out_ready_i,
  output logic [WIDTH-1:0] result_o,
  output logic [4:0]  flags_o       // {NV, DZ, OF, UF, NX}
);

  logic [WIDTH-1:0] raw_result;
  logic [4:0]       raw_flags;
  // ---------------------------------------------------------------------------
  // FORMAT MASK. `fmt_logic_t` is `logic [0:NUM_FP_FORMATS-1]` -- ASCENDING --
  // so a literal's rightmost bit lands on the LAST format, not the first. That
  // mistake cost d_dsp01 a day: the mask selected FP4, the unit elaborated four
  // bits wide, returned zero, and asserted done in the same cycle as the start.
  // See F53. Build by index, then assert the WIDTH it produces -- indexing
  // alone still breaks silently if the vendored package renumbers its formats,
  // which is exactly what happened between cvfpu revisions.
  // ---------------------------------------------------------------------------
  function automatic fpnew_pkg::fmt_logic_t fmt_cfg();
    fmt_cfg = '0;
    fmt_cfg[fpnew_pkg::FP32]    = 1'b1;
    fmt_cfg[fpnew_pkg::FP16]    = 1'b1;
    fmt_cfg[fpnew_pkg::FP16ALT] = 1'b1;
  endfunction

  localparam fpnew_pkg::fmt_logic_t FMT_CFG = fmt_cfg();
  localparam int unsigned LANES = fpnew_pkg::max_num_lanes(WIDTH, FMT_CFG, 1'b1);

  initial begin
    if (fpnew_pkg::max_fp_width(FMT_CFG) != 32)
      $fatal(1, "d_dsp03 shim: widest selected format is %0d bits, expected 32",
             fpnew_pkg::max_fp_width(FMT_CFG));
    if (fpnew_pkg::min_fp_width(FMT_CFG) != 16)
      $fatal(1, "d_dsp03 shim: narrowest selected format is %0d bits, expected 16",
             fpnew_pkg::min_fp_width(FMT_CFG));
    if (LANES != WIDTH/16)
      $fatal(1, "d_dsp03 shim: %0d SIMD lanes at WIDTH=%0d, expected %0d",
             LANES, WIDTH, WIDTH/16);
  end

  fpnew_pkg::fp_format_e fmt;
  always_comb begin
    unique case (fmt_i)
      2'd0:    fmt = fpnew_pkg::FP32;
      2'd1:    fmt = fpnew_pkg::FP16;
      default: fmt = fpnew_pkg::FP16ALT;   // BF16
    endcase
  end

  assign result_o = raw_result;

  // THE INJECTED PREDICATE. A7a pins UF to "inexact AND the delivered result's
  // exponent field is zero". IEEE 754-2019 clause 7.5 instead rounds with an
  // UNBOUNDED EXPONENT and tests that against the smallest normal, which sets
  // UF in the band as well -- an exact result below the smallest normal that
  // rounds UP onto it. This control implements the clause 7.5 answer.
  //
  // CONSTRUCTION, and the FIRST VERSION OF IT WAS WRONG. A wrapper cannot see
  // the exact value, so it cannot evaluate clause 7.5 in general. The first
  // version approximated it as "the delivered result is exactly the smallest
  // normal and inexact" -- which is a SUPERSET. A result that rounded DOWN onto
  // the smallest normal from above satisfies it and is not in the band at all,
  // and because the test ORed across lanes, any vectorial vector with an
  // unrelated min-normal lane fired it too.
  //
  // MEASURED: that version killed 20 vectors at WIDTH=32 and 30 at WIDTH=64 on
  // a vector set containing ZERO band cases. A control that fails for reasons
  // other than the capability it targets validates nothing (rule 16) -- and it
  // was REPORTED AS ISOLATED because its kills had only ever been counted over
  // the band vectors, the one region where the claim held.
  //
  // This version is exact and deliberately CONSERVATIVE, matching the checker's
  // own band detector predicate for predicate: restricted to c == +0, where the
  // exact value is just a*b and the comparison is integer arithmetic on
  // significands and exponents. It under-counts (misses band cases reached with
  // a non-zero addend) and never over-counts. On the pre-band set it kills 0.
  // On the extended set it kills 30 (WIDTH=32) and 48 (WIDTH=64) -- exactly the
  // checker's per-format band counts, 6/12/12 and 12/18/18.
  always_comb begin
    int unsigned E, M, FW, N, k;
    logic [63:0] lane, lmask;
    logic        at_min_normal;
    E = (fmt_i == 2'd0) ? 8 : (fmt_i == 2'd1) ? 5 : 8;
    M = (fmt_i == 2'd0) ? 23 : (fmt_i == 2'd1) ? 10 : 7;
    FW = 1 + E + M;
    N  = vec_i ? (WIDTH / FW) : 1;
    lmask = (64'd1 << FW) - 64'd1;
    at_min_normal = 1'b0;
    for (k = 0; k < WIDTH/16; k++) if (k < N) begin
      logic [63:0] la, lb, lc, sa_, sb_, ea_, eb_, ma_, mb_;
      logic [127:0] prod;
      int unsigned bias, i, msb;
      int signed Xa, Xb;
      lane = (64'(raw_result) >> (k*FW)) & lmask;
      la   = (64'(a_i) >> (k*FW)) & lmask;
      lb   = (64'(b_i) >> (k*FW)) & lmask;
      lc   = (64'(c_i) >> (k*FW)) & lmask;
      bias = (1 << (E-1)) - 1;
      ea_  = (la >> M) & ((64'd1 << E) - 64'd1);
      eb_  = (lb >> M) & ((64'd1 << E) - 64'd1);
      ma_  = la & ((64'd1 << M) - 64'd1);
      mb_  = lb & ((64'd1 << M) - 64'd1);
      if ((lc == 0) &&
          (ea_ != (64'd1 << E) - 64'd1) && (eb_ != (64'd1 << E) - 64'd1) &&
          !((ea_ == 0) && (ma_ == 0)) && !((eb_ == 0) && (mb_ == 0)) &&
          (((lane >> M) & ((64'd1 << E) - 64'd1)) == 64'd1) &&
          ((lane & ((64'd1 << M) - 64'd1)) == 0)) begin
        sa_  = (ea_ == 0) ? ma_ : (ma_ | (64'd1 << M));
        sb_  = (eb_ == 0) ? mb_ : (mb_ | (64'd1 << M));
        Xa   = int'((ea_ == 0) ? 1 : int'(ea_)) - int'(bias) - int'(M);
        Xb   = int'((eb_ == 0) ? 1 : int'(eb_)) - int'(bias) - int'(M);
        prod = 128'(sa_) * 128'(sb_);
        msb  = 0;
        for (i = 0; i < 128; i++) if (prod[i]) msb = i;
        if ((int'(msb) + Xa + Xb) < (1 - int'(bias))) at_min_normal = 1'b1;
      end
    end
    flags_o    = raw_flags;
    flags_o[1] = raw_flags[1] | (raw_flags[0] & at_min_normal);   // UF |= band
  end

  fpnew_pkg::status_t st;
  assign raw_flags = {st.NV, st.DZ, st.OF, st.UF, st.NX};

  logic [2:0][WIDTH-1:0] ops;
  assign ops[0] = a_i;
  assign ops[1] = b_i;
  assign ops[2] = c_i;

  fpnew_opgroup_multifmt_slice #(
     .OpGroup       (fpnew_pkg::ADDMUL)
    ,.Width         (WIDTH)
    ,.FpFmtConfig   (FMT_CFG)
    ,.IntFmtConfig  ('0)
    ,.MxFpFmtConfig ('0)
    ,.MxIntFmtConfig('0)
    ,.EnableVectors (1'b1)
    ,.DivSqrtSel    (fpnew_pkg::PULP)   // unused at ADDMUL; never names TH RTL
    ,.NumPipeRegs   (0)
    ,.PipeConfig    (fpnew_pkg::BEFORE)
    ,.PaceFeatures  ('{default: 0})
    ,.TagType       (logic)
    ,.StochasticRndImplementation (fpnew_pkg::DEFAULT_NO_RSR)
  ) u_anchor (
     .clk_i          (clk_i)
    ,.rst_ni         (rst_ni)
    ,.hart_id_i      (32'd0)
    ,.operands_i     (ops)
    ,.is_boxed_i     ('1)
    ,.rnd_mode_i     (fpnew_pkg::roundmode_e'(rnd_i))
    ,.op_i           (fpnew_pkg::FMADD)
    ,.op_mod_i       (1'b0)
    ,.src_fmt_i      (fmt)
    ,.dst_fmt_i      (fmt)
    ,.int_fmt_i      (fpnew_pkg::int_format_e'(0))
    ,.vectorial_op_i (vec_i)
    ,.tag_i          (1'b0)
    ,.simd_mask_i    ('1)
    ,.pace_param_i   ('0)
    ,.pace_mode_i    ('0)
    ,.in_valid_i     (in_valid_i)
    ,.in_ready_o     (in_ready_o)
    ,.flush_i        (1'b0)
    ,.result_o       (raw_result)
    ,.status_o       (st)
    ,.extension_bit_o()
    ,.tag_o          ()
    ,.out_valid_o    (out_valid_o)
    ,.out_ready_i    (out_ready_i)
    ,.busy_o         ()
  );
endmodule
