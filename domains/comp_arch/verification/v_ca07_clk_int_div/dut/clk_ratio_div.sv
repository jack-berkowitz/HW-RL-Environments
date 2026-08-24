// ---------------------------------------------------------------------------
// GOLDEN -- scoring only. NEVER shipped to a submission.
//
// Class A port shim: pins the configuration and renames. The anchor's ports are
// already plain signals, so there is no struct to flatten -- this exists to fix
// the parameters and to keep the anchor's identity out of the port map.
//
// PINNED. DIV_VALUE_WIDTH=4 gives divisors 0..15, which covers the degenerate
// pair (0 and 1 both mean pass-through), the smallest real division (2), the
// odd cases where a 50% duty cycle is a strong claim, and a range wide enough
// that a reconfiguration has somewhere to go. DEFAULT_DIV_VALUE=0 and
// ENABLE_CLOCK_IN_RESET=0 are pinned because neither is contract-interesting:
// one is the reset value the contract already fixes, the other is a build-time
// choice about behaviour while reset is asserted, which no clause depends on.
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
  clk_int_div #(
    .DIV_VALUE_WIDTH       (4),
    .DEFAULT_DIV_VALUE     (0),
    .ENABLE_CLOCK_IN_RESET (1'b0)
  ) i_div (
    .clk_i, .rst_ni, .en_i, .test_mode_en_i,
    .div_i, .div_valid_i, .div_ready_o, .clk_o, .cycl_count_o
  );
endmodule
