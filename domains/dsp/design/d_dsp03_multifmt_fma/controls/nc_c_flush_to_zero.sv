// =============================================================================
// nc_c_flush_to_zero.sv -- NEGATIVE CONTROL C. Never shipped, never scored.
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

  // THE REDUCTION. Per lane: exponent field zero with a non-zero mantissa is a
  // subnormal, and this design keeps only the sign.
  always_comb begin
    int unsigned E, M, FW, N, k;
    logic [63:0] tmp, lane, lmask;
    E = (fmt_i == 2'd0) ? 8 : (fmt_i == 2'd1) ? 5 : 8;
    M = (fmt_i == 2'd0) ? 23 : (fmt_i == 2'd1) ? 10 : 7;
    FW = 1 + E + M;
    N  = vec_i ? (WIDTH / FW) : 1;
    lmask = (64'd1 << FW) - 64'd1;
    tmp = 64'(raw_result);
    for (k = 0; k < N; k++) begin
      lane = (tmp >> (k*FW)) & lmask;
      if ((((lane >> M) & ((64'd1 << E) - 64'd1)) == 0) &&
          ((lane & ((64'd1 << M) - 64'd1)) != 0)) begin
        tmp = tmp & ~(lmask << (k*FW));
        tmp = tmp | ((lane & (64'd1 << (E+M))) << (k*FW));
      end
    end
    result_o = tmp[WIDTH-1:0];
  end

  fpnew_pkg::status_t st;
  assign flags_o = {st.NV, st.DZ, st.OF, st.UF, st.NX};

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
