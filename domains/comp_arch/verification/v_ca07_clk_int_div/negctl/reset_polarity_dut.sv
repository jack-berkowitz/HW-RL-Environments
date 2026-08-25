// ---------------------------------------------------------------------------
// NEGATIVE CONTROL -- rst_ni read as ACTIVE HIGH, so the design is held in reset
// exactly when it should run and runs exactly when it should be reset.
//
// The point of this one is WHICH clause catches it. A reference that only
// notices because its watchdog expired has not measured anything: it has timed
// out. The record in RULE24.md states the clause, not just the verdict.
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
  clk_ratio_div_golden i_g (
    .clk_i, .rst_ni (~rst_ni), .en_i, .test_mode_en_i,
    .div_i, .div_valid_i, .div_ready_o, .clk_o, .cycl_count_o
  );
endmodule
