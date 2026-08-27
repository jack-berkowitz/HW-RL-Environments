// probe_l4_combinational_tb.sv -- d_dsp03 DIAGNOSTIC for L4. Not a scoring rig.
// Report only; nothing is narrowed.
//
// THE QUESTION. L4 licenses `out_valid_o` to depend combinationally on
// `out_ready_i` and `in_ready_o` on `in_valid_i`, and says "a fully
// combinational unit is conformant". If bounding L4 would make the REFERENCE
// fail its own task, the question is decided without any further argument.
//
// The reference binds NumPipeRegs=0 and the scoring tb's own comment asserts
// "the reference, at zero pipeline depth, does" depend that way. That is a
// comment, and comments are the thing this repository keeps finding wrong. So
// it is measured: toggle each input WITHIN a cycle and see whether the paired
// output moves in the same instant.

`timescale 1ns/1ps

module probe_l4_combinational_tb;

  localparam int unsigned W = 64;

  logic clk = 1'b0, rst_n = 1'b0;
  always #5 clk = ~clk;

  logic          in_valid = 1'b0, in_ready;
  logic [1:0]    fmt = 2'd0;
  logic          vec = 1'b0;
  logic [W-1:0]  a = '0, b = '0, c = '0;
  logic [2:0]    rnd = 3'd0;
  logic          out_valid, out_ready = 1'b1;
  logic [W-1:0]  result;
  logic [4:0]    flags;

  fp_multifmt_fma #(.WIDTH(W)) dut (
    .clk_i(clk), .rst_ni(rst_n),
    .in_valid_i(in_valid), .in_ready_o(in_ready),
    .fmt_i(fmt), .vec_i(vec), .a_i(a), .b_i(b), .c_i(c), .rnd_i(rnd),
    .out_valid_o(out_valid), .out_ready_i(out_ready),
    .result_o(result), .flags_o(flags)
  );

  logic v0, v1, r0, r1;
  logic [W-1:0] res0, res1;

  initial begin
    // 1.0 * 1.0 + 1.0 in FP32
    a = 64'h0000_0000_3F80_0000;
    b = 64'h0000_0000_3F80_0000;
    c = 64'h0000_0000_3F80_0000;
    repeat (6) @(posedge clk); rst_n = 1'b1; repeat (4) @(posedge clk);

    // ---- Q1a: does out_valid_o move with out_ready_i, within one cycle? ----
    @(negedge clk);
    in_valid = 1'b1; out_ready = 1'b1;
    #1;
    v0 = out_valid; res0 = result;
    out_ready = 1'b0;                       // same cycle, no edge between
    #1;
    v1 = out_valid; res1 = result;
    $display("MEASURE: out_ready 1->0 within a cycle: out_valid %0b -> %0b   result %s",
             v0, v1, (res0 === res1) ? "unchanged" : "MOVED");
    if (v0 !== v1)
      $display("MEASURE: Q1 VERDICT: out_valid_o is COMBINATIONAL on out_ready_i");
    else
      $display("MEASURE: Q1 VERDICT: no same-cycle path from out_ready_i to out_valid_o");

    // ---- Q1b: and in_ready_o on in_valid_i ----
    @(negedge clk);
    out_ready = 1'b1; in_valid = 1'b0;
    #1; r0 = in_ready;
    in_valid = 1'b1;
    #1; r1 = in_ready;
    $display("MEASURE: in_valid 0->1 within a cycle: in_ready %0b -> %0b", r0, r1);
    if (r0 !== r1)
      $display("MEASURE: Q1 VERDICT: in_ready_o is COMBINATIONAL on in_valid_i");
    else
      $display("MEASURE: Q1 VERDICT: no same-cycle path from in_valid_i to in_ready_o");

    // ---- Q1c: the load-bearing one -- in_ready_o on out_ready_i ----
    // The scoring tb says a latched stall "deadlocks instantly against any design
    // whose in_ready_o depends on out_ready_i -- which the reference does".
    @(negedge clk);
    in_valid = 1'b1; out_ready = 1'b1;
    #1; r0 = in_ready;
    out_ready = 1'b0;
    #1; r1 = in_ready;
    $display("MEASURE: out_ready 1->0 within a cycle: in_ready %0b -> %0b", r0, r1);
    if (r0 !== r1)
      $display("MEASURE: Q1 VERDICT: in_ready_o is COMBINATIONAL on out_ready_i -- the tb's claim");
    else
      $display("MEASURE: Q1 VERDICT: no same-cycle path from out_ready_i to in_ready_o");

    // ---- and does a result appear with no clock edge at all? ----
    @(negedge clk);
    out_ready = 1'b1; in_valid = 1'b1;
    #1;
    $display("MEASURE: with in_valid high and NO intervening edge: out_valid=%0b result=%016h",
             out_valid, result);

    // ---- THE ONE THE QUESTION TURNS ON: out_valid_o vs in_valid_i ----
    // "Registered or combinational on the output valid" is not answered by the
    // out_ready path, which is quiet. With NumPipeRegs=0 the whole datapath is
    // one cone, so out_valid_o should track in_valid_i with no edge between.
    @(negedge clk);
    out_ready = 1'b1; in_valid = 1'b0;
    #1; v0 = out_valid; res0 = result;
    in_valid = 1'b1;
    #1; v1 = out_valid; res1 = result;
    $display("MEASURE: in_valid 0->1 within a cycle: out_valid %0b -> %0b   result %016h -> %016h",
             v0, v1, res0, res1);
    if (v0 !== v1)
      $display("MEASURE: Q1 ANSWER: out_valid_o is COMBINATIONAL on in_valid_i -- the reference is NOT registered on output valid");
    else
      $display("MEASURE: Q1 ANSWER: out_valid_o did not move with in_valid_i in-cycle");

    // and back down, so the answer is a transition rather than a level
    @(negedge clk);
    in_valid = 1'b1; #1; v0 = out_valid;
    in_valid = 1'b0; #1; v1 = out_valid;
    $display("MEASURE: in_valid 1->0 within a cycle: out_valid %0b -> %0b", v0, v1);

    $display("TEST_RESULT: PROBE -- not a score");
    $finish;
  end

  initial begin #200000; $display("MEASURE: watchdog"); $display("TEST_RESULT: PROBE"); $finish; end
endmodule
