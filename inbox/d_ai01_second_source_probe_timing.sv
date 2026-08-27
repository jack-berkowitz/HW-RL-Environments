module timing_probe #(parameter int unsigned H = 4);
  localparam int unsigned W = 8;
  logic clk = 1'b0, rst_n = 1'b0;
  logic [W-1:0][H-1:0][15:0] x;
  logic       [H-1:0][15:0]  w;
  logic [W-1:0]      [15:0]  y, z;
  logic [2:0] rnd;  logic acc, regen, flush;  logic [W-1:0] gate;
  logic [W-1:0][H-1:0][4:0]  st;
  int fails = 0;

  fp16_gemm_array #(.HEIGHT(H), .WIDTH(W)) dut (
    .clk_i(clk), .rst_ni(rst_n), .x_i(x), .w_i(w), .y_i(y), .z_o(z),
    .rnd_i(rnd), .accumulate_i(acc), .row_clk_gate_en_i(gate),
    .reg_enable_i(regen), .flush_i(flush), .status_o(st));

  always #5 clk = ~clk;

  task automatic expect_int(input string nm, input int got, input int want);
    if (got !== want) begin
      fails++;  $display("  FAIL %-14s got %0d want %0d", nm, got, want);
    end else $display("  ok   %-14s %0d", nm, got);
  endtask

  int d_meas, gap1, gap2, first_nz;
  initial begin
    x = '0; w = '0; y = '0; rnd = 3'd0; acc = 1'b0; regen = 1'b1;
    gate = '1; flush = 1'b0;
    for (int k = 0; k < int'(H); k++) w[k] = 16'h3C00;   // all weights 1.0
    repeat (4) @(posedge clk);
    rst_n = 1'b1;
    repeat (8*int'(H)+20) @(posedge clk);

    $display("HEIGHT=%0d  --- A3 / L2 / L3 : operand-to-z_o delay d(k)", H);
    for (int k = 0; k < int'(H); k++) begin
      @(negedge clk);  x[0][k] = 16'h3C00;
      @(posedge clk);                                    // impulse tick == 0
      @(negedge clk);  x[0][k] = 16'h0000;
      d_meas = -1;
      for (int i = 1; i <= 4*int'(H)+12; i++) begin
        @(posedge clk);
        if (z[0] !== 16'h0000 && d_meas < 0) d_meas = i;
      end
      expect_int($sformatf("d(%0d)", k), d_meas, 4*(int'(H)-1-k)+3);
      repeat (4*int'(H)+12) @(posedge clk);
    end

    $display("HEIGHT=%0d  --- C3 : feedback depth dfb", H);
    acc = 1'b1;
    repeat (8*int'(H)+40) @(posedge clk);
    @(negedge clk);  x[0][0] = 16'h3C00;
    @(posedge clk);
    @(negedge clk);  x[0][0] = 16'h0000;
    first_nz = -1; gap1 = -1; gap2 = -1;
    for (int i = 1; i <= 6*int'(H)+90; i++) begin
      @(posedge clk);
      if (z[0] !== 16'h0000) begin
        if (first_nz < 0) first_nz = i;
        else if (gap1 < 0) gap1 = i - first_nz;
        else if (gap2 < 0) gap2 = i - first_nz - gap1;
      end
    end
    expect_int("d(0) via acc", first_nz, 4*(int'(H)-1)+3);
    expect_int("dfb", gap1, 4*(int'(H)-1)+4);
    expect_int("dfb again", gap2, 4*(int'(H)-1)+4);
    acc = 1'b0;
    x[0][0] = 16'h0000;
    rst_n = 1'b0; repeat (3) @(posedge clk); rst_n = 1'b1;
    repeat (8*int'(H)+20) @(posedge clk);

    $display("HEIGHT=%0d  --- A10 : status delay, same 2 ticks at every k", H);
    for (int k = 0; k < int'(H); k++) begin
      w[k] = 16'h7BFF;
      repeat (8*int'(H)+20) @(posedge clk);
      @(negedge clk);  x[0][k] = 16'h7BFF;
      @(posedge clk);
      @(negedge clk);  x[0][k] = 16'h0000;
      d_meas = -1;
      for (int i = 1; i <= 4*int'(H)+12; i++) begin
        @(posedge clk);
        if (st[0][k] === 5'b00101 && d_meas < 0) d_meas = i;
      end
      expect_int($sformatf("status d(%0d)", k), d_meas, 2);
      w[k] = 16'h3C00;
      repeat (4*int'(H)+12) @(posedge clk);
    end
    $display("HEIGHT=%0d  timing_probe: %0d failures", H, fails);
    $finish;
  end
endmodule
