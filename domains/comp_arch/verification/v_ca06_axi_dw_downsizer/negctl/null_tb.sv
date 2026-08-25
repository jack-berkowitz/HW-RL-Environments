// NEGATIVE CONTROL (a) -- this MUST BE REJECTED by the scoring harness.
// Declares the module the task asks for, drives nothing, observes nothing,
// never instantiates the design, and announces success. If it is scored, the
// validity gate is being satisfied vacuously: the harness runs a gate-mutant
// with every output tied high and requires a submission to REJECT it, which
// this cannot do because it never looks at anything.
module dw_downsizer_tb;
  initial begin
    $display("RESULT: PASS");
    $finish;
  end
endmodule
