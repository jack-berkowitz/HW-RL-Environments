// ---------------------------------------------------------------------------
// GOLDEN -- scoring only. NEVER shipped to a submission.
//
// Class A port shim: flattens the anchor's package-enum ports into plain logic
// and pins the configuration. Renaming and re-encoding only -- no arithmetic,
// no rounding, no flag logic of its own.
//
// THE ENCODINGS BELOW ARE THIS TASK'S DECISION, NOT A STANDARD, except the
// rounding modes, which are the RISC-V F extension's own encoding. They are
// stated in the specification so a submission never has to guess.
// ---------------------------------------------------------------------------
module fp_convert (
  input  logic        clk_i,
  input  logic        rst_ni,
  // ---- request ----
  input  logic [31:0] operand_i,
  input  logic [1:0]  op_i,        // 0 = FP->FP, 1 = FP->int, 2 = int->FP
  input  logic [2:0]  rnd_i,       // RISC-V: 0 RNE, 1 RTZ, 2 RDN, 3 RUP, 4 RMM
  input  logic        signed_i,    // 1 = signed integer, 0 = unsigned
  input  logic        src_fmt_i,   // 0 = binary32, 1 = binary16   (FP source)
  input  logic        dst_fmt_i,   // 0 = binary32, 1 = binary16   (FP destination)
  input  logic        in_valid_i,
  output logic        in_ready_o,
  // ---- response ----
  output logic [31:0] result_o,
  output logic [4:0]  flags_o,     // {NV, DZ, OF, UF, NX}
  output logic        out_valid_o,
  input  logic        out_ready_i
);
  // FP32 (index 0) and FP16 (index 2). The config vector is ASCENDING --
  // fmt_logic_t is logic [0:NUM_FP_FORMATS-1] -- so the LEFTMOST bit is FP32.
  // Written descending it silently selects the wrong formats and every request
  // comes back invalid.
  localparam fpnew_pkg::fmt_logic_t  FP_CFG  = 9'b101_000_000;
  localparam fpnew_pkg::ifmt_logic_t INT_CFG = 4'b0010;          // INT32 only

  fpnew_pkg::operation_e  op;
  fpnew_pkg::fp_format_e  sfmt, dfmt;
  fpnew_pkg::status_t     status;

  always_comb begin
    unique case (op_i)
      2'd0:    op = fpnew_pkg::F2F;
      2'd1:    op = fpnew_pkg::F2I;
      default: op = fpnew_pkg::I2F;
    endcase
    sfmt = src_fmt_i ? fpnew_pkg::FP16 : fpnew_pkg::FP32;
    dfmt = dst_fmt_i ? fpnew_pkg::FP16 : fpnew_pkg::FP32;
  end

  fpnew_cast_multi #(
    .FpFmtConfig  (FP_CFG),
    .IntFmtConfig (INT_CFG),
    .NumPipeRegs  (0),
    .PipeConfig   (fpnew_pkg::BEFORE),
    .TagType      (logic),
    .AuxType      (logic)
  ) i_cast (
    .clk_i, .rst_ni,
    .operands_i      (operand_i),
    .is_boxed_i      (9'h1FF),
    .rnd_mode_i      (fpnew_pkg::roundmode_e'(rnd_i)),
    .op_i            (op),
    .op_mod_i        (~signed_i),        // the anchor's op_mod means UNSIGNED
    .src_fmt_i       (sfmt),
    .dst_fmt_i       (dfmt),
    .int_fmt_i       (fpnew_pkg::INT32),
    .tag_i           (1'b0),
    .mask_i          (1'b1),
    .aux_i           (1'b0),
    .in_valid_i      (in_valid_i),
    .in_ready_o      (in_ready_o),
    .flush_i         (1'b0),
    .result_o        (result_o),
    .status_o        (status),
    .extension_bit_o (),
    .tag_o           (),
    .mask_o          (),
    .aux_o           (),
    .out_valid_o     (out_valid_o),
    .out_ready_i     (out_ready_i),
    .busy_o          ()
  );

  assign flags_o = {status.NV, status.DZ, status.OF, status.UF, status.NX};
endmodule
