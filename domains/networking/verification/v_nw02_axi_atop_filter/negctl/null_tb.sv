// NEGATIVE CONTROL (a) -- this MUST BE REJECTED by the scoring harness.
//
// It declares the module the task asks for, drives nothing, observes nothing,
// and announces success. A harness that accepts this is not measuring anything:
// it would report the same verdict for a submission that does no work as for
// one that checks the whole contract.
module atop_filter_tb;
  initial begin
    $display("RESULT: PASS");
    $finish;
  end
endmodule
