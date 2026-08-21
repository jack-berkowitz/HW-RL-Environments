// =============================================================================
// fp_divsqrt_srt_ref.sv -- THIN PORT SHIM over vendored cvfpu RTL.
// Reference for d_dsp01. NEVER SHIPPED.
//
// NO BEHAVIOUR: parameter binding, rename, and enum decode only.
//
// BINDINGS AND WHY -- a shim's configuration is not part of the contract, and
// an off-spec binding inflates the reference:
//   FpFmtConfig = FP32 only   the contract is binary32; enabling other formats
//                             would build datapath nobody asked for. BUILT BY
//                             INDEX AND THEN WIDTH-CHECKED -- see below; the
//                             obvious literal selects the wrong format and
//                             says nothing.
//   NumPipeRegs = 0           spec-minimal. L2 leaves latency free, so this
//                             affects area and Fmax and nothing contractual.
//   TagType/AuxType = logic   the interface carries neither.
//   simd_synch_* tied LOW     and the polarity matters. The anchor computes
//                             `simd_synch_done = simd_synch_done_i || ~vec_op`
//                             internally, so with vectorial_op_i low it already
//                             supplies the 1. Driving simd_synch_done_i HIGH
//                             additionally satisfies a separate FSM branch
//                             (fpnew_divsqrt_multi.sv:237) before the unit has
//                             finished, and the unit then never produces a
//                             result at all -- capture wrote zero vectors and
//                             hit its watchdog. simd_synch_rdy_i is only read
//                             when vec_op is high, so it is don't-care here.
// =============================================================================
module fp_divsqrt_srt (
  input  logic        clk_i,
  input  logic        rst_ni,
  input  logic        in_valid_i,
  output logic        in_ready_o,
  input  logic        op_i,
  input  logic [31:0] a_i,
  input  logic [31:0] b_i,
  input  logic [2:0]  rnd_i,
  output logic        out_valid_o,
  input  logic        out_ready_i,
  output logic [31:0] result_o,
  output logic [4:0]  flags_o
);
  // ---------------------------------------------------------------------------
  // FORMAT MASK. `fmt_logic_t` is `logic [0:NUM_FP_FORMATS-1]` -- ASCENDING --
  // and NUM_FP_FORMATS is 9 in this vendored cvfpu. A literal of the shape
  // {{(N-1){1'b0}}, 1'b1} therefore sets index 8, which is FP4 (4 bits), not
  // FP32 at index 0. Nothing rejects it: the divider elaborates as a 4-bit
  // unit, `operands_i` narrows to 8 bits total, every operand is truncated,
  // the result is 0 and Done_SO asserts in the same cycle as the start. The
  // only evidence was a WIDTHTRUNC warning among 124 others.
  //
  // So build the mask BY INDEX, then CHECK THE WIDTH IT PRODUCES. The check is
  // the part that matters -- indexing alone would still break silently if the
  // vendored package renumbered its formats.
  // ---------------------------------------------------------------------------
  function automatic fpnew_pkg::fmt_logic_t fmt_fp32_only();
    fmt_fp32_only = '0;
    fmt_fp32_only[fpnew_pkg::FP32] = 1'b1;
  endfunction

  localparam fpnew_pkg::fmt_logic_t FP32_ONLY = fmt_fp32_only();

  initial if (fpnew_pkg::max_fp_width(FP32_ONLY) != 32)
    $fatal(1, "d_dsp01 shim: FP32_ONLY selects a %0d-bit format, expected 32",
           fpnew_pkg::max_fp_width(FP32_ONLY));

  fpnew_pkg::status_t st;
  assign flags_o = {st.NV, st.DZ, st.OF, st.UF, st.NX};

  logic [1:0][31:0] ops;
  assign ops[0] = a_i;
  assign ops[1] = b_i;

  fpnew_divsqrt_multi #(
     .FpFmtConfig (FP32_ONLY)
    ,.NumPipeRegs (0)
    ,.PipeConfig  (fpnew_pkg::AFTER)
    ,.TagType     (logic)
    ,.AuxType     (logic)
  ) u_anchor (
     .clk_i            (clk_i)
    ,.rst_ni           (rst_ni)
    ,.operands_i       (ops)
    ,.is_boxed_i       ('1)
    ,.rnd_mode_i       (fpnew_pkg::roundmode_e'(rnd_i))
    ,.op_i             (op_i ? fpnew_pkg::SQRT : fpnew_pkg::DIV)
    ,.dst_fmt_i        (fpnew_pkg::FP32)
    ,.tag_i            (1'b0)
    ,.mask_i           (1'b1)
    ,.aux_i            (1'b0)
    ,.vectorial_op_i   (1'b0)
    ,.in_valid_i       (in_valid_i)
    ,.in_ready_o       (in_ready_o)
    ,.divsqrt_done_o   ()
    ,.simd_synch_done_i(1'b0)
    ,.divsqrt_ready_o  ()
    ,.simd_synch_rdy_i (1'b0)
    ,.flush_i          (1'b0)
    ,.result_o         (result_o)
    ,.status_o         (st)
    ,.extension_bit_o  ()
    ,.tag_o            ()
    ,.mask_o           ()
    ,.aux_o            ()
    ,.out_valid_o      (out_valid_o)
    ,.out_ready_i      (out_ready_i)
    ,.busy_o           ()
  );
endmodule
