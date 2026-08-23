// =============================================================================
// fp16_gemm_array_ref.sv -- THIN PORT SHIM over vendored PULP RedMulE RTL.
// Reference for d_ai01. NEVER SHIPPED.
//
// NO BEHAVIOUR: parameter binding, rename, struct flatten, and enum decode only.
//
// MODULE NAME. This declares `fp16_gemm_array_ref_inner`, not the contract name.
// The pass-through top that carries the contract name lives in
// fp16_gemm_array_top.sv. The split exists so the negative controls in
// controls/ can wrap the reference and perturb one behaviour each: a control
// declares `fp16_gemm_array` itself and instantiates this inner module, and the
// two never collide in one elaboration.
// Every output below is an anchor output; nothing is combined, reduced, or
// recomputed here.
//
// ANCHOR: refs/redmule/rtl/redmule_engine.sv  (ETH Zurich / U. Bologna, SHL-0.51)
//
// BINDINGS AND WHY -- a shim's configuration is not part of the contract, and an
// off-spec binding inflates or deflates the reference:
//
//   FpFormat = FP16        the contract is binary16. RedMulE's own default.
//                          BOUND BY ENUM, then WIDTH-CHECKED below -- d_dsp01
//                          burned a week on a format mask that silently
//                          selected FP4, so the width assertion is the part
//                          that matters, not the enum name.
//
//   Height in {4,8}        HEIGHT is the length of the serial FMA chain in a
//   Width  = 8             row; WIDTH is the number of independent rows. Both
//                          are within redmule_pkg::MaxDim (32).
//
//                          SCORED AT HEIGHT=8 -- the default below. The
//                          geometry is capped by SYNTHESIS FEASIBILITY, not by
//                          the anchor: one redmule_ce measures 23,034 um^2 on
//                          sky130hd, so 16x16 would be ~5.9 mm^2, about 2.8x
//                          the largest design this repo has ever built
//                          (d_nw01_axi4_xbar, 2.09 mm^2). 8x8 lands near
//                          1.5 mm^2, inside the proven envelope.
//
//                          HEIGHT is the parameterised axis rather than WIDTH
//                          because HEIGHT changes the OBSERVABLE SCHEDULE --
//                          chain depth sets both latency and the operand skew
//                          -- whereas WIDTH is pure replication.
//
//   NumPipeRegs = 3        CONTRACTUAL, not free. Unlike d_dsp01, latency here
//                          is observable: each row stage is separated by a
//                          register, so per-stage delay sets the operand
//                          presentation schedule. 3 is RedMulE's engine
//                          default. PipeConfig DISTRIBUTED likewise.
//
//   op1 = FMADD            fixes the datapath to z = x*w + y. With op1 == FMADD
//                          redmule_ce disables AND clock-gates its stage-2
//                          noncomp unit (redmule_ce.sv:66, :455), so z_output_o
//                          is the stage-1 FMA result and nothing else. Any
//                          other op1 would build min/max/compare datapath the
//                          contract does not ask for.
//
//   op2 = SGNJ             don't-care: the stage-2 unit it selects is gated off
//                          by the FMADD binding above. Bound to a legal enum
//                          rather than left dangling so elaboration is clean.
//
//   op_mod = 1'b0          FMADD, not FMSUB -- addend sign unmodified.
//
//   stage2_rnd = RNE       don't-care for the same reason as op2.
//
//   *_is_boxed = '1        every operand is a true FP16 value, not a narrower
//                          format NaN-boxed into 16 bits.
//
//   TagType/AuxType=logic  the contract carries neither; tied low, outputs left
//                          unconnected.
//
//   class_mask/is_class/extension_bit  left unconnected: they are noncomp
//                          outputs, inert under the FMADD binding.
//
//   in_valid = out_ready = 1'b1   NOT a shortcut -- a SCOPE DECISION with a
//                          reason. Every measurement in MEASUREMENTS.md was
//                          taken with both of these high, so binding them high
//                          reproduces exactly the conditions the contract was
//                          written from. They do have real effect (dropping
//                          in_valid clears out_valid and busy; dropping
//                          out_ready deasserts in_ready), but the interaction
//                          between backpressure and chain advance was not
//                          separated from reg_enable_i, so the protocol is
//                          characterised only to first order. in_ready_o,
//                          out_valid_o and busy_o are therefore NOT surfaced:
//                          a port whose protocol is not fully characterised
//                          would be scored by the anchor while the contract
//                          only appeared to specify it. Widening this is a
//                          deliberate later step, not an oversight.
//
// STRUCT FLATTEN: cntrl_engine_t has 12 fields but redmule_engine reads exactly
// two of them (accumulate, row_clk_gate_en -- see redmule_engine.sv:77,121).
// The other ten are shadowed by dedicated top-level ports on the same module.
// The two live fields are surfaced as scalars; the dead ten are driven to their
// bound values above so no field is left X.
// =============================================================================
module fp16_gemm_array_ref_inner #(
  parameter int unsigned HEIGHT = 8,
  parameter int unsigned WIDTH  = 8
) (
  input  logic                                     clk_i,
  input  logic                                     rst_ni,

  // Operands
  input  logic [WIDTH-1:0][HEIGHT-1:0][15:0]       x_i,
  input  logic            [HEIGHT-1:0][15:0]       w_i,
  input  logic [WIDTH-1:0]            [15:0]       y_i,
  output logic [WIDTH-1:0]            [15:0]       z_o,

  // Rounding for the FMA stage
  input  logic [2:0]                               rnd_i,

  // Datapath control
  input  logic                                     accumulate_i,
  input  logic [WIDTH-1:0]                         row_clk_gate_en_i,
  input  logic                                     reg_enable_i,
  input  logic                                     flush_i,

  // Per-FMA IEEE status, {NV,DZ,OF,UF,NX}
  output logic [WIDTH-1:0][HEIGHT-1:0][4:0]        status_o
);

  // ---------------------------------------------------------------------------
  // FORMAT WIDTH CHECK. fp_width() is the only thing that proves the enum we
  // bound is the format we meant. d_dsp01's FP4 elaboration produced a working,
  // silent, wrong unit; the only symptom was one WIDTHTRUNC among 124.
  // ---------------------------------------------------------------------------
  initial begin
    if (fpnew_pkg::fp_width(fpnew_pkg::FP16) != 16)
      $fatal(1, "d_ai01 shim: FP16 is %0d bits, expected 16",
             fpnew_pkg::fp_width(fpnew_pkg::FP16));
    if (HEIGHT > redmule_pkg::MaxDim || WIDTH > redmule_pkg::MaxDim)
      $fatal(1, "d_ai01 shim: %0dx%0d exceeds redmule_pkg::MaxDim=%0d",
             WIDTH, HEIGHT, redmule_pkg::MaxDim);
  end

  redmule_pkg::cntrl_engine_t ctrl;
  always_comb begin
    ctrl                    = '0;
    ctrl.accumulate         = accumulate_i;
    ctrl.row_clk_gate_en    = '0;
    ctrl.row_clk_gate_en[WIDTH-1:0] = row_clk_gate_en_i;
    // Dead fields, shadowed by dedicated ports on the anchor. Bound, not X.
    ctrl.fma_is_boxed       = '1;
    ctrl.noncomp_is_boxed   = '1;
    ctrl.stage1_rnd         = fpnew_pkg::roundmode_e'(rnd_i);
    ctrl.stage2_rnd         = fpnew_pkg::RNE;
    ctrl.op1                = fpnew_pkg::FMADD;
    ctrl.op2                = fpnew_pkg::SGNJ;
    ctrl.op_mod             = 1'b0;
    ctrl.in_valid           = 1'b1;
    ctrl.flush              = flush_i;
    ctrl.out_ready          = 1'b1;
  end

  fpnew_pkg::status_t [WIDTH-1:0][HEIGHT-1:0] st;
  for (genvar r = 0; r < WIDTH; r++) begin : gen_status_rename
    for (genvar c = 0; c < HEIGHT; c++) begin : gen_status_bit
      assign status_o[r][c] = {st[r][c].NV, st[r][c].DZ, st[r][c].OF,
                               st[r][c].UF, st[r][c].NX};
    end
  end

  redmule_engine #(
     .FpFormat    (fpnew_pkg::FP16)
    ,.Height      (HEIGHT)
    ,.Width       (WIDTH)
    ,.NumPipeRegs (3)
    ,.PipeConfig  (fpnew_pkg::DISTRIBUTED)
    ,.TagType     (logic)
    ,.AuxType     (logic)
  ) u_anchor (
     .clk_i              (clk_i)
    ,.rst_ni             (rst_ni)
    ,.x_input_i          (x_i)
    ,.w_input_i          (w_i)
    ,.y_bias_i           (y_i)
    ,.z_output_o         (z_o)
    ,.fma_is_boxed_i     ('1)
    ,.noncomp_is_boxed_i ('1)
    ,.stage1_rnd_i       (fpnew_pkg::roundmode_e'(rnd_i))
    ,.stage2_rnd_i       (fpnew_pkg::RNE)
    ,.op1_i              (fpnew_pkg::FMADD)
    ,.op2_i              (fpnew_pkg::SGNJ)
    ,.op_mod_i           (1'b0)
    ,.tag_i              (1'b0)
    ,.aux_i              (1'b0)
    ,.in_valid_i         (1'b1)
    ,.in_ready_o         ()
    ,.reg_enable_i       (reg_enable_i)
    ,.flush_i            (flush_i)
    ,.status_o           (st)
    ,.extension_bit_o    ()
    ,.class_mask_o       ()
    ,.is_class_o         ()
    ,.tag_o              ()
    ,.aux_o              ()
    ,.out_valid_o        ()
    ,.out_ready_i        (1'b1)
    ,.busy_o             ()
    ,.ctrl_engine_i      (ctrl)
  );

endmodule
