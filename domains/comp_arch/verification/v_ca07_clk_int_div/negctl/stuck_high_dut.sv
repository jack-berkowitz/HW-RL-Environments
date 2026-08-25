// ---------------------------------------------------------------------------
// NEGATIVE CONTROL -- every output tied high. This is the GATE MUTANT: a
// submission that does not reject it is not measuring the design at all, and the
// harness reports such a submission INVALID rather than scoring it.
//
// A reference that fails to reject this has no floor.
// ---------------------------------------------------------------------------
module clk_ratio_div (
  input  logic       clk_i,
  input  logic       rst_ni,
  input  logic       en_i,
  input  logic       test_mode_en_i,
  input  logic [3:0] div_i,
  input  logic       div_valid_i,
  output logic       div_ready_o,
  output logic       clk_o,
  output logic [3:0] cycl_count_o
);
  assign div_ready_o  = 1'b1;
  assign clk_o        = 1'b1;
  assign cycl_count_o = 4'hF;
endmodule
