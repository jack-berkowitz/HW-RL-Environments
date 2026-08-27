// probe_refill_window_tb.sv -- d_ai01 DIAGNOSTIC for the UNSPECIFIED WINDOWS.
// Not a scoring rig. Report first; the spec and rig are only changed if this
// says they are wrong.
//
// THE QUESTION. Two spec sites and the rig's REFILL_W declare the first
// D*(HEIGHT-1)+3 enabled ticks after flush_i falls -- and after accumulate_i
// changes -- to be UNSPECIFIED and unscored. Under the OLD arithmetic that
// expression equalled dfb exactly. dfb has since been measured at D*(H-1)+4, so
// the window may have been sized to a full traversal and now be one tick short.
//
// IT MAY ALSO BE CORRECT AT +3 FOR ITS OWN REASONS, which is why this measures
// instead of assuming. A window is not obliged to equal any pipeline constant;
// it only has to cover the disturbance.
//
// METHOD. Hold a CONSTANT operand field so the steady-state output is a known
// value Z. Pulse flush_i. Count the enabled ticks after flush falls during which
// the output differs from Z. With the field constant the chain refills to the
// same value, so that count IS the disturbance -- no reference model needed and
// no assumption about where counting starts, only "how many ticks are wrong".

`timescale 1ns/1ps

module probe_refill_window_tb;

  localparam int unsigned H = `PH;
  localparam int unsigned W = 8;
  localparam int unsigned OLD_W = 4*(H-1) + 3;   // what spec and REFILL_W say
  localparam int unsigned DFB   = 4*(H-1) + 4;   // the measured feedback depth

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

  logic [15:0] steady;
  logic [15:0] trace_a [0:255], trace_b [0:255];
  int unsigned disturbed, last_bad, t;

  initial begin
    for (int rr = 0; rr < W; rr++) begin
      y[rr] = 16'h3C00;                                   // 1.0 bias
      for (int k = 0; k < H; k++) x[rr][k] = 16'h3C00;    // 1.0
    end
    for (int k = 0; k < H; k++) wt[k] = 16'h3C00;         // 1.0

    repeat (6) @(posedge clk); rst_n = 1'b1;
    repeat (4*(H-1) + 40) @(posedge clk); #1;
    steady = z[0];
    $display("MEASURE: steady-state output with a constant field = %04h", steady);
    if (steady === 16'h0000)
      $display("[WARN] steady state is zero -- the disturbance would be invisible");

    // ---- pulse flush and count the disturbance ----
    @(negedge clk); flush = 1'b1;
    @(posedge clk);
    @(negedge clk); flush = 1'b0;

    disturbed = 0; last_bad = 0;
    for (t = 1; t <= 4*(H-1) + 40; t++) begin
      @(posedge clk); #1;
      if (z[0] !== steady) begin disturbed++; last_bad = t; end
    end
    $display("MEASURE: after flush_i falls: %0d disturbed ticks, LAST disturbed tick = %0d",
             disturbed, last_bad);
    $display("MEASURE:   spec and REFILL_W declare %0d unspecified;  dfb = %0d", OLD_W, DFB);
    if (last_bad <= OLD_W)
      $display("MEASURE: VERDICT flush: the window at %0d COVERS the disturbance (last bad %0d). Correct as it stands.",
               OLD_W, last_bad);
    else
      $display("MEASURE: VERDICT flush: the window at %0d is SHORT -- tick %0d is disturbed and would be SCORED. Needs %0d.",
               OLD_W, last_bad, last_bad);

    // ---- THE CASE THE WINDOW ACTUALLY HAS TO COVER ----
    //
    // The measurement above used a CONSTANT operand field, which is the BEST
    // case: the chain refills with the same values it flushed, so the output
    // returns to the steady value almost immediately. The window exists to cover
    // a TIME-VARYING field, where a flush discards partial sums built from
    // operands that will never recur and the disturbance runs a full traversal.
    // Measuring only the constant case would report a comfortable margin that
    // the real case does not have.
    begin
      logic [15:0] pat;
      int unsigned lastbad2;
      // settle on a constant field first so there is a known starting point
      for (int rr = 0; rr < W; rr++) for (int k = 0; k < H; k++) x[rr][k] = 16'h3C00;
      repeat (4*(H-1) + 40) @(posedge clk);

      // flush WHILE the field changes every tick, then keep it changing
      @(negedge clk); flush = 1'b1;
      @(posedge clk);
      @(negedge clk); flush = 1'b0;

      lastbad2 = 0;
      pat = 16'h3C00;
      for (t = 1; t <= 4*(H-1) + 40; t++) begin
        // a new operand field every tick: 1.0, 2.0, 4.0, ... cycling
        pat = (pat == 16'h4400) ? 16'h3C00 : (pat + 16'h0400);
        @(negedge clk);
        for (int rr = 0; rr < W; rr++) for (int k = 0; k < H; k++) x[rr][k] = pat;
        @(posedge clk); #1;
        // the design is not compared against a model here; what is measured is
        // WHEN THE OUTPUT STOPS DEPENDING ON THE FLUSH. Run the same varying
        // sequence twice, once after a flush and once without, and the tick at
        // which the two agree from then on is the end of the disturbance.
        trace_a[t] = z[0];
      end

      // replay the identical sequence with NO flush
      for (int rr = 0; rr < W; rr++) for (int k = 0; k < H; k++) x[rr][k] = 16'h3C00;
      repeat (4*(H-1) + 40) @(posedge clk);
      pat = 16'h3C00;
      for (t = 1; t <= 4*(H-1) + 40; t++) begin
        pat = (pat == 16'h4400) ? 16'h3C00 : (pat + 16'h0400);
        @(negedge clk);
        for (int rr = 0; rr < W; rr++) for (int k = 0; k < H; k++) x[rr][k] = pat;
        @(posedge clk); #1;
        trace_b[t] = z[0];
      end

      lastbad2 = 0;
      for (t = 1; t <= 4*(H-1) + 40; t++)
        if (trace_a[t] !== trace_b[t]) lastbad2 = t;
      $display("MEASURE: TIME-VARYING field, flushed vs not: LAST differing tick = %0d", lastbad2);
      $display("MEASURE:   window declares %0d unspecified;  dfb = %0d", OLD_W, DFB);
      if (lastbad2 <= OLD_W)
        $display("MEASURE: VERDICT: the window at %0d COVERS the worst case (last differing %0d). CHANGE NOTHING.",
                 OLD_W, lastbad2);
      else if (lastbad2 <= DFB)
        $display("MEASURE: VERDICT: the window at %0d is SHORT by %0d -- tick %0d would be SCORED. dfb (%0d) covers it.",
                 OLD_W, lastbad2 - OLD_W, lastbad2, DFB);
      else
        $display("MEASURE: VERDICT: the window needs %0d -- MORE than dfb.", lastbad2);
    end

    // ---- and the accumulate transition, the second site ----
    repeat (4*(H-1) + 40) @(posedge clk); #1;
    steady = z[0];
    @(negedge clk); accumulate = 1'b1;
    disturbed = 0; last_bad = 0;
    for (t = 1; t <= 4*(H-1) + 40; t++) begin
      @(posedge clk); #1;
      if (z[0] !== steady) begin disturbed++; last_bad = t; end
    end
    $display("MEASURE: after accumulate_i rises: LAST disturbed tick = %0d (window %0d, dfb %0d)",
             last_bad, OLD_W, DFB);
    $display("MEASURE:   note: with accumulate asserted the output legitimately KEEPS changing,");
    $display("MEASURE:   so this row bounds the TRANSITION only if it settles; read it with that.");

    $display("TEST_RESULT: PROBE -- not a score");
    $finish;
  end

  initial begin #400000; $display("MEASURE: watchdog"); $display("TEST_RESULT: PROBE"); $finish; end
endmodule
