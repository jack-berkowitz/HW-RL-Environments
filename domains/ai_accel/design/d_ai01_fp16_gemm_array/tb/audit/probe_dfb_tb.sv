// probe_dfb_tb.sv -- d_ai01 DIAGNOSTIC for the FEEDBACK delay. Not a scoring rig.
// Commissioned by AGENT-PPA; report only, nothing written into the spec.
//
// THE SPEC STATES dfb TWICE AND THE TWO NO LONGER AGREE:
//
//     dfb = D*(H-1) + 3        -> 15 at HEIGHT=4
//     dfb = d(0) + 1           -> 16, now that d(0) is MEASURED at 15
//
// Before the stage sweep those were the same number, because d(0) was believed
// to be 14. The sweep measured d(k) = D*(H-1-k)+3 for every k, which moved d(0)
// to 15 and split the two statements apart. Only one can be the contract.
//
// HOW THIS MEASURES IT WITHOUT COUNTING PIPELINE STAGES. With every weight zero
// the forward path is a pure delay of the accumulator input:
//
//     p[0] = fma(x, 0, acc_in) = acc_in ,  p[k] = fma(x, 0, p[k-1]) = p[k-1]
//
// and with accumulate asserted, acc_in is the fed-back z_o(t - dfb). So
//
//     z_o(t) = z_o(t - dfb)
//
// and a single injected value RECIRCULATES WITH PERIOD EXACTLY dfb. The answer
// is a gap between two observations of the same value at the output, which needs
// no assumption about where counting starts -- the defect that made the forward
// measurement ambiguous in the first place.
//
// The value is injected by a ONE-TICK weight impulse at stage 0, which adds
// x*w once and nothing thereafter.

`timescale 1ns/1ps

module probe_dfb_tb;

  localparam int unsigned H = `PH;
  localparam int unsigned W = 8;

  logic clk = 1'b0, rst_n = 1'b0;
  always #5 clk = ~clk;

  logic [W-1:0][H-1:0][15:0] x;
  logic       [H-1:0][15:0]  wt;
  logic [W-1:0]      [15:0]  y, z;
  logic [2:0] rnd = 3'b000;
  logic accumulate = 1'b0, reg_enable = 1'b1, flush = 1'b0;
  logic [W-1:0] row_gate = '1;
  logic [W-1:0][4:0] status;

  fp16_gemm_array_ref_inner #(.HEIGHT(H), .WIDTH(W)) dut (
    .clk_i(clk), .rst_ni(rst_n),
    .x_i(x), .w_i(wt), .y_i(y), .z_o(z), .rnd_i(rnd),
    .accumulate_i(accumulate), .row_clk_gate_en_i(row_gate),
    .reg_enable_i(reg_enable), .flush_i(flush), .status_o(status)
  );

  int unsigned hit[$];
  int unsigned tick;

  initial begin
    for (int rr = 0; rr < W; rr++) begin
      y[rr] = 16'h0000;
      for (int k = 0; k < H; k++) x[rr][k] = 16'h3C00;   // 1.0
    end
    for (int k = 0; k < H; k++) wt[k] = 16'h0000;        // pure delay line

    repeat (6) @(posedge clk); rst_n = 1'b1;

    // clear the chain with accumulate OFF so nothing is circulating
    flush = 1'b1; accumulate = 1'b0;
    repeat (6) @(posedge clk);
    flush = 1'b0;
    repeat (4*(H-1) + 24) @(posedge clk);
    if (z[0] !== 16'h0000) $display("[WARN] chain not clear before injection: %04h", z[0]);

    // close the loop, then inject ONE tick of weight at stage 0
    @(negedge clk); accumulate = 1'b1;
    repeat (4) @(negedge clk);
    @(negedge clk); wt[0] = 16'h3C00;
    @(posedge clk);
    @(negedge clk); wt[0] = 16'h0000;

    // record every tick at which the output is non-zero
    tick = 0;
    for (int i = 0; i < (4*(H-1) + 3)*5 + 60; i++) begin
      @(posedge clk); #1;
      tick++;
      if (z[0] !== 16'h0000) hit.push_back(tick);
    end

    $display("MEASURE: HEIGHT=%0d   D*(H-1)+3 = %0d   d(0)+1 = %0d   (d(0) measured at %0d)",
             H, 4*(H-1)+3, (4*(H-1)+3)+1, 4*(H-1)+3);
    if (hit.size() < 2) begin
      $display("MEASURE: only %0d output hit(s) -- the value did not recirculate, NOT A MEASUREMENT",
               hit.size());
    end else begin
      automatic int unsigned g0 = hit[1] - hit[0];
      $display("MEASURE: output non-zero at ticks: %p", hit);
      for (int i = 1; i < hit.size(); i++)
        $display("MEASURE:   gap %0d -> %0d = %0d", i-1, i, hit[i] - hit[i-1]);
      $display("MEASURE: RECIRCULATION PERIOD dfb = %0d", g0);
      if (g0 == 4*(H-1)+3)
        $display("MEASURE: VERDICT: dfb is the LITERAL D*(H-1)+3. The d(0)+1 relation is WRONG.");
      else if (g0 == 4*(H-1)+4)
        $display("MEASURE: VERDICT: dfb is d(0)+1 = %0d. The literal D*(H-1)+3 is WRONG.", g0);
      else
        $display("MEASURE: VERDICT: dfb is %0d -- NEITHER of the spec's two statements.", g0);
    end
    $display("TEST_RESULT: PROBE -- not a score");
    $finish;
  end

  initial begin #400000; $display("MEASURE: watchdog"); $display("TEST_RESULT: PROBE"); $finish; end
endmodule
