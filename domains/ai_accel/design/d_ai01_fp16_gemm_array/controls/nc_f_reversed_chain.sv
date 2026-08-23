// nc_f_reversed_chain.sv -- d_ai01 NEGATIVE CONTROL. Never shipped, never scored as a submission.
//
// Feeds the activation and weight vectors to the chain in reversed stage order. The dot product is mathematically the same sum, so this is CORRECT IN EXACT ARITHMETIC and wrong only in floating point. Targets spec A2's ordering sentence -- if the vectors cannot tell these apart, the ordering clause is unscored.
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
  logic [WIDTH-1:0][HEIGHT-1:0][15:0] x_rev;
  logic [HEIGHT-1:0][15:0] w_rev;
  for (genvar r = 0; r < WIDTH; r++)
    for (genvar k = 0; k < HEIGHT; k++)
      assign x_rev[r][k] = x_i[r][HEIGHT-1-k];
  for (genvar k = 0; k < HEIGHT; k++) assign w_rev[k] = w_i[HEIGHT-1-k];
  fp16_gemm_array_ref_inner #(HEIGHT, WIDTH) u (
    .clk_i(clk_i), .rst_ni(rst_ni), .x_i(x_rev), .w_i(w_rev), .y_i(y_i), .z_o(z_o),
    .rnd_i(rnd_i), .accumulate_i(accumulate_i), .row_clk_gate_en_i(row_clk_gate_en_i),
    .reg_enable_i(reg_enable_i), .flush_i(flush_i), .status_o(status_o));
endmodule
