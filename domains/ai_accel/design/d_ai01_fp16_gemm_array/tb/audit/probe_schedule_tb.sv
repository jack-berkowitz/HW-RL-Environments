// probe_schedule_tb.sv -- d_ai01 STEP 0 MEASUREMENT. Not a scoring TB.
//
// Purpose: establish, by observation rather than inference, three facts about
// the anchor at the shim boundary:
//   (1) the arithmetic format really is FP16;
//   (2) what function z_o settles to for a known constant operand field;
//   (3) how many cycles the serial chain takes to produce it.
//
// Method: hold x[k]=X and w[k]=W constant on every lane with y=+0. Each row is
// H computing elements chained through a register, so the settled value should
// be H*(X*W) + Y and it should appear H*(NumPipeRegs+1) cycles after the first
// enabled edge. Both numbers are PREDICTIONS -- the TB prints the whole trace
// so a wrong prediction is visible as a trace, not hidden behind a pass/fail.
module probe_schedule_tb;

  localparam int unsigned H = `HH;
  localparam int unsigned W = `WW;

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
    .clk_i(clk), .rst_ni(rst_n),
    .x_i(x), .w_i(wt), .y_i(y), .z_o(z),
    .rnd_i(rnd), .accumulate_i(accumulate), .row_clk_gate_en_i(row_gate),
    .reg_enable_i(reg_enable), .flush_i(flush),
    .status_o(status)
  );

  localparam logic [15:0] FP16_1P0 = 16'h3C00;
  localparam logic [15:0] FP16_2P0 = 16'h4000;
  localparam logic [15:0] FP16_P0  = 16'h0000;

  int settle_cycle = -1;
  logic [15:0] settled;
  int c;

  initial begin
    // Static operand field: every lane sees 1.0 * 2.0, bias +0.
    for (int r = 0; r < W; r++) begin
      y[r] = FP16_P0;
      for (int k = 0; k < H; k++) x[r][k] = FP16_1P0;
    end
    for (int k = 0; k < H; k++) wt[k] = FP16_2P0;

    rnd        = 3'd0;      // RNE
    accumulate = 1'b0;      // take y_i, not the feedback path
    row_gate   = '1;        // every row clock ENABLED -- gated rows never tick
    reg_enable = 1'b0;
    flush      = 1'b0;

    repeat (4) @(posedge clk);
    rst_n = 1'b1;
    @(posedge clk);
    flush = 1'b1; @(posedge clk); flush = 1'b0;

    reg_enable = 1'b1;

    $display("cycle  z[0]    z[W-1]");
    for (c = 0; c < 4*H + 12; c++) begin
      @(posedge clk);
      #1;
      $display("%5d  0x%04x  0x%04x", c, z[0], z[W-1]);
      if (settle_cycle < 0 && z[0] == 16'h0000 && c > 0) begin
        // still zero, keep going
      end
    end

    // Report the final value and when it first reached it.
    settled = z[0];
    $display("");
    $display("H=%0d W=%0d  final z[0]=0x%04x  z[W-1]=0x%04x", H, W, z[0], z[W-1]);
    $display("PREDICTED settled value  = H*(1.0*2.0) + 0 = %0d.0", 2*H);
    $display("PREDICTED settle cycle   = H*(NumPipeRegs+1) = %0d", 4*H);
    $display("status[0][H-1] = 0b%05b  {NV,DZ,OF,UF,NX}", status[0][H-1]);
    $finish;
  end

endmodule
