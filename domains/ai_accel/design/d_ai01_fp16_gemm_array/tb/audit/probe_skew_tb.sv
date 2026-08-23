// probe_skew_tb.sv -- d_ai01 STEP 0 MEASUREMENT #2. Not a scoring TB.
//
// WHY THIS EXISTS. probe_schedule_tb held every operand constant, so it could
// measure the settled value and the per-stage spacing but could NOT distinguish
// WHICH cycle's operands a given result depends on. A contract that says
// "z = sum of x[k]*w[k] + y" without pinning the time index leaves the temporal
// question to the anchor -- F57's general form exactly. This probe pins it.
//
// METHOD -- impulse response. Hold x[k] = 1.0 on every lane and w[k] = +0 on
// every lane, so each computing element evaluates 1.0*0 + addend and the chain
// is a pure delay line for the addend. Then, for one chosen stage K, raise
// w[K] to 1.0 for EXACTLY ONE enabled tick. That injects a single 1.0 at stage
// K, which then propagates down the remaining stages.
//
// MEASURED MODEL, and the first one was WRONG. The initial guess was
// delay(K) = D*(H-K); the probe returned a uniform 2-cycle shortfall at every
// stage, which is a wrong formula rather than a wrong instrument -- the
// stage-to-stage SPACING came back as exactly D=4, which is origin-independent
// and agrees with probe_schedule_tb (first product on z at cycle 2, one more
// every 4 cycles thereafter). The corrected model is
//
//   delay(K) = D*(H-1-K) + 2
//
// i.e. the LAST stage costs 2 cycles to reach z, and every stage upstream of it
// adds a further D. Both probes agree on this independently.
//
// L0 = 2 is the tail latency of the final stage under the sampling convention
// used here: z_o read immediately after a rising edge.
//
// A wrong prediction shows up as a measured emergence cycle that does not match,
// printed next to the expected one -- not as a silent pass.
module probe_skew_tb;

  localparam int unsigned H = `HH;
  localparam int unsigned W = 1;
  localparam int unsigned D = 4;

  logic clk = 1'b0, rst_n = 1'b0;
  always #5 clk = ~clk;

  logic [W-1:0][H-1:0][15:0] x;
  logic        [H-1:0][15:0] wt;
  logic [W-1:0]       [15:0] y;
  logic [W-1:0]       [15:0] z;
  logic [2:0]                rnd;
  logic                      accumulate, reg_enable, flush;
  logic [W-1:0]              row_gate;
  logic [W-1:0][H-1:0][4:0]  status;

  fp16_gemm_array #(.HEIGHT(H), .WIDTH(W)) dut (
    .clk_i(clk), .rst_ni(rst_n), .x_i(x), .w_i(wt), .y_i(y), .z_o(z),
    .rnd_i(rnd), .accumulate_i(accumulate), .row_clk_gate_en_i(row_gate),
    .reg_enable_i(reg_enable), .flush_i(flush),
    .status_o(status)
  );

  localparam logic [15:0] FP16_1P0 = 16'h3C00;

  int tick, emerge, expected, fails;

  // Free-running absolute cycle counter. Every event below is timestamped
  // against THIS, so the measured delay is a difference of two observed edges
  // and carries no assumption about where a trial "starts".
  int unsigned cyc = 0;
  always @(posedge clk) cyc <= cyc + 1;

  task automatic run_trial(input int K, input bit trace);
    int t_apply, t_emerge;
    begin
      flush = 1'b1; repeat (2) @(posedge clk); flush = 1'b0;
      for (int k = 0; k < H; k++) wt[k] = 16'h0000;
      repeat (D*H + 6) @(posedge clk);

      t_apply  = -1;
      t_emerge = -1;

      // Drive the impulse so it is STABLE ACROSS EXACTLY ONE RISING EDGE, and
      // record which edge that was.
      wt[K] = FP16_1P0;
      @(posedge clk);
      #1;
      t_apply = cyc - 1;          // cyc already incremented on this edge
      wt[K]   = 16'h0000;

      while ((cyc - t_apply) < D*(H+2) && t_emerge < 0) begin
        @(posedge clk);
        #1;
        if (trace)
          $display("    cyc=%0d  (t-t_apply)=%0d  z=0x%04x", cyc-1, (cyc-1)-t_apply, z[0]);
        if (z[0] != 16'h0000) t_emerge = cyc - 1;
      end

      expected = D * (H - 1 - K) + 2;
      $display("  K=%0d  apply@%0d  emerge@%0d  delay=%0d  expected %0d   %s",
               K, t_apply, t_emerge, t_emerge - t_apply, expected,
               ((t_emerge - t_apply) == expected) ? "MATCH" : "*** MISMATCH ***");
      if ((t_emerge - t_apply) != expected) fails++;
    end
  endtask

  // The bias enters at stage 0's addend, so it should carry stage 0's delay.
  // ASSUMED is not MEASURED -- so measure it.
  task automatic run_y_trial();
    int t_apply, t_emerge;
    begin
      flush = 1'b1; repeat (2) @(posedge clk); flush = 1'b0;
      y[0] = 16'h0000;
      for (int k = 0; k < H; k++) wt[k] = 16'h0000;
      repeat (D*H + 6) @(posedge clk);

      t_emerge = -1;
      y[0] = FP16_1P0;
      @(posedge clk);
      #1;
      t_apply = cyc - 1;
      y[0]    = 16'h0000;

      while ((cyc - t_apply) < D*(H+2) && t_emerge < 0) begin
        @(posedge clk);
        #1;
        if (z[0] != 16'h0000) t_emerge = cyc - 1;
      end

      expected = D * (H - 1) + 2;
      $display("  y  apply@%0d  emerge@%0d  delay=%0d  expected %0d   %s",
               t_apply, t_emerge, t_emerge - t_apply, expected,
               ((t_emerge - t_apply) == expected) ? "MATCH" : "*** MISMATCH ***");
      if ((t_emerge - t_apply) != expected) fails++;
    end
  endtask

  initial begin
    for (int r = 0; r < W; r++) begin
      y[r] = 16'h0000;
      for (int k = 0; k < H; k++) x[r][k] = FP16_1P0;
    end
    for (int k = 0; k < H; k++) wt[k] = 16'h0000;
    rnd = 3'd0; accumulate = 1'b0; row_gate = '1;
    reg_enable = 1'b0; flush = 1'b0; 
    fails = 0;

    repeat (4) @(posedge clk);
    rst_n = 1'b1;
    @(posedge clk);
    reg_enable = 1'b1;

    $display("skew probe: H=%0d D=%0d   model delay(K) = D*(H-1-K) + 2", H, D);
    run_trial(H-1, 1'b1);   // trace one stage in full, so the delay is readable off the trace
    for (int K = 0; K < H; K++) run_trial(K, 1'b0);
    run_y_trial();

    $display("");
    $display("skew probe: %0d mismatches out of %0d trials", fails, H+2);
    $finish;
  end

endmodule
