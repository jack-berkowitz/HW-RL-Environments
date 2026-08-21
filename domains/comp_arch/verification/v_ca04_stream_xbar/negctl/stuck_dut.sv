// NEGATIVE CONTROL (b1) -- a KNOWN-BAD DUT. The reference testbench MUST catch it.
// Every output tied low: nothing is ever accepted or delivered. Generated from
// the port map so no output can be left out by hand.
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
  assign in_ready_o = '0;
  assign out_data_o = '0;
  assign out_idx_o = '0;
  assign out_valid_o = '0;
endmodule
