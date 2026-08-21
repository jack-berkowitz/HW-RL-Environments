// ---------------------------------------------------------------------------
// PORT MAP -- route_xbar
//
// This is the complete interface. It is the ONLY structural information you
// are given: there is no reference implementation, and none will be provided.
// Write your testbench against spec/route_xbar_spec.md and this file.
//
// Every port is a plain packed vector. Per-port fields are packed low-index
// first: input k's data occupies in_data_i[k*DATA_W +: DATA_W], and output j's
// index occupies out_idx_o[j*IDX_W +: IDX_W].
// ---------------------------------------------------------------------------
module route_xbar #(
  parameter int unsigned N_IN    = 4,
  parameter int unsigned N_OUT   = 4,
  parameter int unsigned DATA_W  = 32,
  parameter int unsigned SEL_W   = 2,
  parameter int unsigned IDX_W   = 2
) (
  input  logic                       clk_i,
  input  logic                       rst_ni,
  // ---- input side ----
  input  logic [N_IN*DATA_W-1:0]     in_data_i,
  input  logic [N_IN*SEL_W-1:0]      in_sel_i,
  input  logic [N_IN-1:0]            in_valid_i,
  output logic [N_IN-1:0]            in_ready_o,
  // ---- output side ----
  output logic [N_OUT*DATA_W-1:0]    out_data_o,
  output logic [N_OUT*IDX_W-1:0]     out_idx_o,
  output logic [N_OUT-1:0]           out_valid_o,
  input  logic [N_OUT-1:0]           out_ready_i
);

  // no body -- see spec/route_xbar_spec.md for required behaviour
endmodule
