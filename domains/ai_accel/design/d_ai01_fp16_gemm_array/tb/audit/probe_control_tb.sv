// probe_control_tb.sv -- d_ai01 STEP 0 MEASUREMENT #4. Not a scoring TB.
//
// probes 2-4 held accumulate_i=0, row_clk_gate_en_i=all-ones, in_valid_i=1 and
// out_ready_i=1 for their whole run. Those inputs are therefore NOT
// characterised by them, and a clause written about any of them would be a
// clause the anchor decides and the text only appears to. This probe measures
// them.
module probe_control_tb;

  localparam int unsigned H = 4;
  localparam int unsigned W = 2;
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

  localparam logic [15:0] ONE = 16'h3C00, TWO = 16'h4000;

  task automatic settle();
    begin
      flush = 1'b1; repeat (2) @(posedge clk); flush = 1'b0;
      repeat (D*H + 8) @(posedge clk); #1;
    end
  endtask

  initial begin
    for (int r = 0; r < W; r++) begin
      y[r] = 16'h0000;
      for (int k = 0; k < H; k++) x[r][k] = ONE;
    end
    for (int k = 0; k < H; k++) wt[k] = TWO;
    rnd = 3'd0; accumulate = 1'b0; row_gate = '1;
    reg_enable = 1'b0; flush = 1'b0;

    repeat (4) @(posedge clk); rst_n = 1'b1; @(posedge clk);
    reg_enable = 1'b1;

    // ---------------- flush ----------------
    settle();
    $display("[flush]      settled z0=0x%04x (expect 0x4800 = 8.0)", z[0]);
    flush = 1'b1; repeat (2) @(posedge clk); flush = 1'b0; #1;
    $display("[flush]      immediately after flush z0=0x%04x", z[0]);
    settle();

    // ---------------- accumulate ----------------
    $display("");
    $display("[accumulate] baseline settled z0=0x%04x", z[0]);
    accumulate = 1'b1;
    for (int i = 0; i < 6; i++) begin
      repeat (D*H) @(posedge clk); #1;
      $display("[accumulate] after %0d further chain-fills z0=0x%04x", i+1, z[0]);
    end
    accumulate = 1'b0;
    settle();

    // ---------------- row clock gating ----------------
    $display("");
    $display("[rowgate]    both rows settled: z0=0x%04x z1=0x%04x", z[0], z[1]);
    // Freeze row 1, then change the operand field and let row 0 respond.
    row_gate = 2'b01;              // row 0 clocked, row 1 frozen
    for (int r = 0; r < W; r++)
      for (int k = 0; k < H; k++) x[r][k] = TWO;   // 2.0*2.0 -> settles to 16.0
    repeat (D*H + 8) @(posedge clk); #1;
    $display("[rowgate]    after operand change, gate=01: z0=0x%04x z1=0x%04x", z[0], z[1]);
    $display("             (row0 should track the new field; row1 should hold)");
    row_gate = '1;
    repeat (D*H + 8) @(posedge clk); #1;
    $display("[rowgate]    after re-enabling row1: z0=0x%04x z1=0x%04x", z[0], z[1]);

    // ---------------- reg_enable as stall ----------------
    $display("");
    for (int r = 0; r < W; r++)
      for (int k = 0; k < H; k++) x[r][k] = ONE;
    settle();
    $display("[stall]      settled z0=0x%04x", z[0]);
    reg_enable = 1'b0;
    for (int r = 0; r < W; r++)
      for (int k = 0; k < H; k++) x[r][k] = TWO;
    repeat (D*H + 8) @(posedge clk); #1;
    $display("[stall]      reg_enable low, operands changed: z0=0x%04x (should hold)", z[0]);
    reg_enable = 1'b1;
    repeat (D*H + 8) @(posedge clk); #1;
    $display("[stall]      reg_enable restored: z0=0x%04x", z[0]);

    // ---------------- handshake outputs ----------------
    // MEASURED, then REMOVED FROM THIS PROBE. in_valid_i/out_ready_i are now
    // bound HIGH inside the shim and in_ready_o/out_valid_o/busy_o are not
    // surfaced, so this probe can no longer reach them. The numbers taken
    // against the wider pre-narrowing shim are recorded in MEASUREMENTS.md #6.

    $finish;
  end

endmodule
