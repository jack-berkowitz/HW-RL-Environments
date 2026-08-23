// fp16_gemm_array_top.sv -- contract-named pass-through over the reference shim.
// NEVER SHIPPED. NO BEHAVIOUR: a port-for-port instantiation and nothing else.
//
// Exists only so that `fp16_gemm_array_ref_inner` can be wrapped by the negative
// controls in controls/ without a module-name collision. Builds that want the
// unperturbed reference compile this file plus the inner one; builds that want a
// control compile the control plus the inner one, and leave this out.
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
  fp16_gemm_array_ref_inner #(.HEIGHT(HEIGHT), .WIDTH(WIDTH)) u_inner (
    .clk_i(clk_i), .rst_ni(rst_ni), .x_i(x_i), .w_i(w_i), .y_i(y_i), .z_o(z_o),
    .rnd_i(rnd_i), .accumulate_i(accumulate_i),
    .row_clk_gate_en_i(row_clk_gate_en_i), .reg_enable_i(reg_enable_i),
    .flush_i(flush_i), .status_o(status_o)
  );
endmodule
