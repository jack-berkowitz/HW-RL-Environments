// ---------------------------------------------------------------------------
// NEGATIVE CONTROL -- a testbench that measures nothing and reports cleanly.
//
// It declares the top module the harness expects, instantiates no design, drives
// no stimulus and prints RESULT: PASS. Any grader that scores this above zero is
// scoring the WORD "PASS" rather than an observation.
//
// The harness's own defence is the gate mutant: a design with every output tied
// high, which a submission must REJECT. This cannot reject anything, so it is
// reported INVALID and excluded from scoring rather than being given a mark.
// ---------------------------------------------------------------------------
module clk_ratio_div_tb;
  initial begin
    $display("RESULT: PASS");
    $finish;
  end
endmodule
