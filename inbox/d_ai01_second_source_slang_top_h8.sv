// =============================================================================
// T5 elaboration wrapper -- HEIGHT=8, WIDTH=8.
//
// Exists so the slang check needs NO parameter-override flag and therefore no
// judgement call about override syntax. Elaborate THIS module as the top; the
// parameters are fixed in the instantiation below.
//
// Not a testbench. Not scored. Combinational pass-through of every port.
// =============================================================================
module d_ai01_ss_slang_top_h8 (
  input  logic                         clk_i,
  input  logic                         rst_ni,
  input  logic [7:0][8-1:0][15:0]      x_i,
  input  logic     [8-1:0][15:0]       w_i,
  input  logic [7:0]       [15:0]      y_i,
  output logic [7:0]       [15:0]      z_o,
  input  logic [2:0]                   rnd_i,
  input  logic                         accumulate_i,
  input  logic [7:0]                   row_clk_gate_en_i,
  input  logic                         reg_enable_i,
  input  logic                         flush_i,
  output logic [7:0][8-1:0][4:0]       status_o
);
  fp16_gemm_array #(.HEIGHT(8), .WIDTH(8)) u_dut (
    .clk_i, .rst_ni, .x_i, .w_i, .y_i, .z_o, .rnd_i, .accumulate_i,
    .row_clk_gate_en_i, .reg_enable_i, .flush_i, .status_o
  );
endmodule
