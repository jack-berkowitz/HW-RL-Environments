// ---------------------------------------------------------------------------
// v_ca07 -- PORT MAP. This is the whole of the design that ships.
//
// A runtime-configurable integer clock divider. Your testbench drives clk_i,
// rst_ni, en_i, div_i and div_valid_i, and observes clk_o, div_ready_o and
// cycl_count_o.
//
// DRIVE AND TIME EVERYTHING FROM clk_i. clk_o is the thing under test: a
// testbench clocked by it stops when a faulty design stops it, and a testbench
// that SAMPLES it rather than measuring its edges will not see most of the
// contract.
//
// The body is empty ON PURPOSE. No implementation is shipped.
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
  // No implementation is shipped. See spec/clk_ratio_div_spec.md.
endmodule
