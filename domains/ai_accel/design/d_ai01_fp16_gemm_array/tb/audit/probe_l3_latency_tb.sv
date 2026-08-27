// probe_l3_latency_tb.sv -- d_ai01 DIAGNOSTIC for the L3 counting convention.
// Not a scoring rig. Commissioned by AGENT-PPA to decide a results question.
//
// THE DISPUTE. spec L3 states "D*(H-1)+2 enabled ticks: ... 14 at HEIGHT=4".
// tb:354 computes that 14 and calls it "the contract's number"; tb:355 adds
//   EXP_LAT = L3_LAT + 1   // +1 for the sampling edge
// and requires 15. "sampling edge" appears 0 times in spec/ and 0 times in
// PASTE.md. A candidate that delivered exactly 14 was failed.
//
// THE SUSPICION THIS RIG TESTS. The scoring tb applies the impulse like this:
//
//     repeat (EXP_LAT + 8) @(posedge clk);   // resumes AT a posedge
//     wt[0] = 16'h3C00;                      // ... and assigns AT that posedge
//
// so the operand changes at the same simulation instant the DUT's flops sample.
// Every other stimulus site in that testbench drives at @(negedge clk) precisely
// to avoid this. If the +1 is compensating for that race rather than describing
// the design, then applying the impulse at a negedge -- where the value is
// unambiguously settled before the sampling edge -- will yield 14.
//
// SO THE RIG MEASURES BOTH AND REPORTS BOTH. It does not assume the reference is
// right because it passes a testbench written to match it.

`timescale 1ns/1ps

module probe_l3_latency_tb;

  localparam int unsigned H = `PH;   // set on the command line
  localparam int unsigned W = 8;
  localparam int unsigned L3_LAT = 4*(H-1) + 2;   // 14, the spec's number

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

  // Bring the chain to a settled, known-zero z with a zero weight vector.
  task automatic quiesce();
    begin
      flush = 1'b1; accumulate = 1'b0; reg_enable = 1'b1; row_gate = '1;
      for (int rr = 0; rr < W; rr++) begin
        y[rr] = 16'h0000;
        for (int k = 0; k < H; k++) x[rr][k] = 16'h3C00;   // 1.0
      end
      for (int k = 0; k < H; k++) wt[k] = 16'h0000;        // 0.0 -> pure delay line
      repeat (4) @(posedge clk);
      flush = 1'b0;
      repeat (L3_LAT + 12) @(posedge clk);
      if (z[0] !== 16'h0000)
        $display("[WARN] chain not settled to zero before the impulse: z0=%04h", z[0]);
    end
  endtask

  // Apply the impulse AT A POSEDGE -- the scoring testbench's convention, and a
  // race: the operand changes in the same instant the flops sample it.
  task automatic measure_at_posedge(output int unsigned n);
    int unsigned t;
    begin
      quiesce();
      n = 0;
      @(posedge clk);            // resume exactly at an edge
      wt[0] = 16'h3C00;          // ... and assign there
      for (t = 1; t <= L3_LAT + 20; t++) begin
        @(posedge clk); #1;
        if (z[0] !== 16'h0000) begin n = t; break; end
      end
      wt[0] = 16'h0000;
    end
  endtask

  // Apply the impulse AT A NEGEDGE -- settled well before the sampling edge, so
  // the first posedge that can act on it is unambiguous.
  task automatic measure_at_negedge(output int unsigned n);
    int unsigned t;
    begin
      quiesce();
      n = 0;
      @(negedge clk);            // half a cycle of setup
      wt[0] = 16'h3C00;
      for (t = 1; t <= L3_LAT + 20; t++) begin
        @(posedge clk); #1;
        if (z[0] !== 16'h0000) begin n = t; break; end
      end
      wt[0] = 16'h0000;
    end
  endtask

  // Impulse at stage k, negedge-applied. L2 claims d(k) = D*(H-1-k)+2 and L3 is
  // its k=0 case; if L3 is off by one, the question is whether the WHOLE FAMILY
  // shifts or only the k=0 member. Correcting L3 alone would leave the spec
  // internally inconsistent with L2, so this is measured before anything is
  // written.
  task automatic measure_stage(input int k, output int unsigned n);
    int unsigned t;
    begin
      quiesce();
      n = 0;
      @(negedge clk);
      wt[k] = 16'h3C00;
      for (t = 1; t <= L3_LAT + 24; t++) begin
        @(posedge clk); #1;
        if (z[0] !== 16'h0000) begin n = t; break; end
      end
      wt[k] = 16'h0000;
    end
  endtask

  int unsigned n_pos, n_neg;

  initial begin
    x = '0; wt = '0; y = '0;
    repeat (6) @(posedge clk); rst_n = 1'b1; repeat (6) @(posedge clk);

    measure_at_posedge(n_pos);
    measure_at_negedge(n_neg);

    $display("MEASURE: spec L3 at HEIGHT=%0d              = %0d", H, L3_LAT);
    $display("MEASURE: tb requires (L3_LAT + 1)           = %0d", L3_LAT + 1);
    $display("MEASURE: impulse applied AT POSEDGE  -> lat = %0d   (the scoring tb's convention)", n_pos);
    $display("MEASURE: impulse applied AT NEGEDGE  -> lat = %0d   (settled before the edge)", n_neg);
    if (n_pos == 0 || n_neg == 0)
      $display("MEASURE: VERDICT: at least one measurement never saw the impulse -- NOT A MEASUREMENT");
    else if (n_pos == n_neg)
      $display("MEASURE: VERDICT: both conventions agree at %0d -- the +1 is NOT a stimulus race", n_pos);
    else begin
      // signed, because the first version printed 4294967295 for a difference
      // of -1: unsigned subtraction underflowed and the display read as data.
      $display("MEASURE: VERDICT: the two differ by %0d edges -- the posedge assignment is a RACE",
               $signed(n_pos) - $signed(n_neg));
      $display("MEASURE: SAMPLING-EDGE-TO-OUTPUT depth is the same either way:");
      $display("MEASURE:   posedge-applied: sampled at edge N,   out at N+%0d  -> %0d edges", n_pos, n_pos);
      $display("MEASURE:   negedge-applied: sampled at edge N+1, out at N+%0d  -> %0d edges", n_neg, n_neg - 1);
    end
    $display("MEASURE: --- per-stage: is it the k=0 member or the whole family? ---");
    begin
      int unsigned nk;
      for (int k = 0; k < H; k++) begin
        measure_stage(k, nk);
        // negedge-applied counts one edge before the sampling edge, so the
        // delivered depth is nk-1.
        $display("MEASURE:   stage %0d: lat=%0d -> depth %0d   L2 says d(%0d)=%0d, L2+1 says %0d",
                 k, nk, nk - 1, k, 4*(H-1-k)+2, 4*(H-1-k)+3);
      end
    end
    $display("TEST_RESULT: PROBE -- not a score");
    $finish;
  end

  initial begin #200000; $display("MEASURE: watchdog"); $display("TEST_RESULT: PROBE"); $finish; end
endmodule
