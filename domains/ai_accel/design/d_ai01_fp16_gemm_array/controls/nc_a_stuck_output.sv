// nc_a_stuck_output.sv -- d_ai01 NEGATIVE CONTROL. Never shipped, never scored as a submission.
//
// Ties z_o to a constant. The floor case: if this passes, the comparison is not wired up at all. Targets nothing specific and everything.
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
  logic [WIDTH-1:0][15:0] z_ref;
  fp16_gemm_array_ref_inner #(HEIGHT, WIDTH) u (.*, .z_o(z_ref));
  assign z_o = {WIDTH{16'h3C00}};
endmodule
