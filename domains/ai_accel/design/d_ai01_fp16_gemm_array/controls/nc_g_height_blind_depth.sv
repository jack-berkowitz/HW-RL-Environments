// nc_g_height_blind_depth.sv -- d_ai01 CAPACITY-REDUCED CONTROL.
// Never shipped, never scored as a submission.
//
// PURPOSE. Every other control in this directory is a correctness perturbation:
// it is wrong at every geometry. This one exists to answer a different question
// -- is HEIGHT LOAD-BEARING? task.yaml recorded `measured: PARTIAL` because the
// reference passing at both HEIGHT=4 and HEIGHT=8 is not evidence that a design
// which ignores HEIGHT would fail at either. Without a control that passes at
// one geometry and fails at the other, the two-configuration argument is an
// assertion.
//
// THE PERTURBATION. The chain depth handed to the reference is the LITERAL 4,
// not the HEIGHT parameter. `HP` below is a constant; nothing derives it from
// HEIGHT, and no generate branch recovers the difference. The wrapper's ports
// are still HEIGHT-wide -- it accepts an 8-deep operand field and quietly
// computes a 4-deep dot product from the first four stages, discarding
// x_i[r][4..HEIGHT-1] and w_i[4..HEIGHT-1] entirely.
//
// PREDICTION, stated before running:
//   HEIGHT=4  -- HP == HEIGHT, the port mapping is the identity, and this is
//                bit-for-bit the reference. Should PASS.
//   HEIGHT=8  -- z_o is the sum of four products where the contract requires
//                eight, the operand skew d(k) is the 4-deep schedule rather
//                than the 8-deep one, and status_o[r][4..7] report nothing.
//                Should FAIL.
//
// If it fails at HEIGHT=4 the control is wrong, not the task -- a 4-deep
// reference driven by a 4-deep wrapper has nothing to differ about.
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

  // PINNED. This is the defect: a capacity the designer baked in as a constant.
  localparam int unsigned HP = 4;

  logic [WIDTH-1:0][HP-1:0][15:0] x_p;
  logic           [HP-1:0][15:0] w_p;
  logic [WIDTH-1:0][HP-1:0][4:0] st_p;

  for (genvar r = 0; r < WIDTH; r++) begin : gen_x_pin
    for (genvar k = 0; k < HP; k++) begin : gen_x_stage
      assign x_p[r][k] = x_i[r][k];
    end
  end
  for (genvar k = 0; k < HP; k++) begin : gen_w_pin
    assign w_p[k] = w_i[k];
  end

  fp16_gemm_array_ref_inner #(.HEIGHT(HP), .WIDTH(WIDTH)) u_pinned (
    .clk_i(clk_i), .rst_ni(rst_ni),
    .x_i(x_p), .w_i(w_p), .y_i(y_i), .z_o(z_o),
    .rnd_i(rnd_i), .accumulate_i(accumulate_i),
    .row_clk_gate_en_i(row_clk_gate_en_i), .reg_enable_i(reg_enable_i),
    .flush_i(flush_i), .status_o(st_p)
  );

  // Stages the pinned instance does not have report nothing. At HEIGHT=4 this
  // loop is empty and status_o is exactly st_p.
  for (genvar r = 0; r < WIDTH; r++) begin : gen_st
    for (genvar k = 0; k < HEIGHT; k++) begin : gen_st_stage
      if (k < HP) assign status_o[r][k] = st_p[r][k];
      else        assign status_o[r][k] = 5'd0;
    end
  end

endmodule
