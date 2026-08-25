// probe_status_tb.sv -- d_ai01 MEASUREMENT. Not a scoring TB.
//
// WHY. Clause A10 said status_o[r][k] reports that stage's fused multiply-add
// "alone" and said nothing about WHEN, so the reference and the second source
// took different legal readings and disagreed on ~2900 of 3400 cycles. Pinning
// A10 to "whatever the reference does" would re-create exactly the gap it is
// meant to close, so the reference's status latency is MEASURED here and the
// number is written into the clause.
//
// METHOD. Hold a flag-free field: x[k]=1.0 and w[k]=+0 on every stage, so each
// element evaluates (1.0 * +0) + addend = addend exactly and raises nothing.
// Then raise stage K's operands to 65504 * 2.0 for exactly one enabled tick,
// which overflows and must raise OF and NX at that stage and nowhere else.
// Record the delay from the applying edge to OF appearing on status_o[0][K].
module probe_status_tb;

  localparam int unsigned H = `HH;
  localparam int unsigned W = 1;
  localparam int unsigned D = 4;

  logic clk = 1'b0, rst_n = 1'b0;
  always #5 clk = ~clk;

  logic [W-1:0][H-1:0][15:0] x;
  logic        [H-1:0][15:0] wt;
  logic [W-1:0]       [15:0] y, z;
  logic [2:0]                rnd;
  logic                      accumulate, reg_enable, flush;
  logic [W-1:0]              row_gate;
  logic [W-1:0][H-1:0][4:0]  status;

  fp16_gemm_array #(.HEIGHT(H), .WIDTH(W)) dut (
    .clk_i(clk), .rst_ni(rst_n), .x_i(x), .w_i(wt), .y_i(y), .z_o(z),
    .rnd_i(rnd), .accumulate_i(accumulate), .row_clk_gate_en_i(row_gate),
    .reg_enable_i(reg_enable), .flush_i(flush), .status_o(status));

  int unsigned cyc = 0;
  always @(posedge clk) cyc <= cyc + 1;

  task automatic trial(input int K);
    int t_apply, t_of, t_gone;
    begin
      for (int k = 0; k < H; k++) begin x[0][k] = 16'h3C00; wt[k] = 16'h0000; end
      y[0] = 16'h0000;
      repeat (4*H + 12) @(posedge clk);
      x[0][K] = 16'h7BFF; wt[K] = 16'h4000;          // 65504 * 2 -> overflow
      @(posedge clk); #1;
      t_apply = cyc - 1;
      x[0][K] = 16'h3C00; wt[K] = 16'h0000;
      t_of = -1; t_gone = -1;
      while ((cyc - t_apply) < 4*H + 12) begin
        @(posedge clk); #1;
        if (t_of < 0 && status[0][K][2]) t_of = cyc - 1;
        else if (t_of >= 0 && t_gone < 0 && !status[0][K][2]) t_gone = cyc - 1;
      end
      $display("  K=%0d  apply@%0d  OF seen@%0d  delay=%0d  held for %0d tick(s)",
               K, t_apply, t_of, (t_of < 0) ? -1 : t_of - t_apply,
               (t_gone < 0 || t_of < 0) ? -1 : t_gone - t_of);
    end
  endtask

  initial begin
    x = '0; wt = '0; y = '0; rnd = 3'd0; accumulate = 1'b0; row_gate = '1;
    reg_enable = 1'b0; flush = 1'b0;
    repeat (4) @(posedge clk); rst_n = 1'b1; @(posedge clk); reg_enable = 1'b1;
    $display("status latency probe: H=%0d", H);
    for (int K = 0; K < H; K++) trial(K);
    $finish;
  end
endmodule
