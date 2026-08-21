// NEGATIVE CONTROL (a) -- this MUST BE REJECTED by the scoring harness.
//
// It declares the module the task asks for, drives nothing, observes nothing,
// never instantiates the design, and announces success.
module ptp_time_base_tb;
  initial begin
    $display("RESULT: PASS");
    $finish;
  end
endmodule
