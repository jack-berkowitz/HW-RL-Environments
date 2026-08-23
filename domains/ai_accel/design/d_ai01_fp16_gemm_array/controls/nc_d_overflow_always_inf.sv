// nc_d_overflow_always_inf.sv -- d_ai01 NEGATIVE CONTROL. Never shipped, never scored as a submission.
//
// Delivers a correctly signed infinity whenever the final stage overflows, in EVERY rounding mode. Targets spec A5 specifically: the delivered value on overflow is mode-dependent, and roundTowardZero must give +/-65504 rather than infinity. A design that reads only the general rounding clause writes exactly this bug.
//
// A negative control earns its place only if it FAILS, and fails for its own
// reason. The kill counts measured over the full vector set are recorded in
// CONTROLS.md -- a control that kills everything proves the harness runs, not
// that it discriminates.
module fp16_gemm_array #(parameter int unsigned HEIGHT = 8, parameter int unsigned WIDTH = 8) (
  input logic clk_i, input logic rst_ni,
  input logic [WIDTH-1:0][HEIGHT-1:0][15:0] x_i,
  input logic [HEIGHT-1:0][15:0] w_i,
  input logic [WIDTH-1:0][15:0] y_i,
  output logic [WIDTH-1:0][15:0] z_o,
  input logic [2:0] rnd_i, input logic accumulate_i,
  input logic [WIDTH-1:0] row_clk_gate_en_i,
  input logic reg_enable_i, input logic flush_i,
  output logic [WIDTH-1:0][HEIGHT-1:0][4:0] status_o
);
  logic [WIDTH-1:0][15:0] z_int;
  logic [WIDTH-1:0][HEIGHT-1:0][4:0] st_int;
  fp16_gemm_array_ref_inner #(HEIGHT, WIDTH) u (.*, .z_o(z_int), .status_o(st_int));
  assign status_o = st_int;
  for (genvar r = 0; r < WIDTH; r++)
    assign z_o[r] = st_int[r][HEIGHT-1][2] ? {z_int[r][15], 5'h1F, 10'd0} : z_int[r];
endmodule
