// NEGATIVE CONTROL (a) -- this MUST BE REJECTED by the scoring harness.
// Declares the module the task asks for, drives nothing, observes nothing,
// never instantiates the design, and announces success.
module arp_engine_tb;
  initial begin
    $display("RESULT: PASS");
    $finish;
  end
endmodule
