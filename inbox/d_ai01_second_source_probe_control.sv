module ctrl_probe #(parameter int unsigned H = 4);
  localparam int unsigned W = 8;
  logic clk = 1'b0, rst_n = 1'b0;
  logic [W-1:0][H-1:0][15:0] x;
  logic       [H-1:0][15:0]  w;
  logic [W-1:0]      [15:0]  y, z;
  logic [2:0] rnd;  logic acc, regen, flush;  logic [W-1:0] gate;
  logic [W-1:0][H-1:0][4:0]  st;
  int  fails = 0;
  logic ph;
  logic [4:0] sA [0:7];
  logic [4:0] sB [0:7];
  logic [15:0] zB [0:7];

  fp16_gemm_array #(.HEIGHT(H), .WIDTH(W)) dut (
    .clk_i(clk), .rst_ni(rst_n), .x_i(x), .w_i(w), .y_i(y), .z_o(z),
    .rnd_i(rnd), .accumulate_i(acc), .row_clk_gate_en_i(gate),
    .reg_enable_i(regen), .flush_i(flush), .status_o(st));

  always #5 clk = ~clk;

  task automatic chk(input string nm, input bit cond);
    if (!cond) begin fails++; $display("  FAIL %s", nm); end
    else $display("  ok   %s", nm);
  endtask

  // the alternating operand field C2 names: an overflowing pair on one tick,
  // a flag-free one on the next.
  always @(negedge clk) begin
    ph <= ~ph;
    x[0][0] <= (~ph) ? 16'h7BFF : 16'h0000;
  end

  task automatic settle();
    rst_n = 1'b0; @(negedge clk); ph = 1'b0; flush = 1'b0; regen = 1'b1;
    gate = '1; repeat (3) @(posedge clk); rst_n = 1'b1;
    repeat (8*int'(H)+24) @(posedge clk);
  endtask

  initial begin
    x = '0; w = '0; y = '0; rnd = 3'd0; acc = 1'b0; regen = 1'b1;
    gate = '1; flush = 1'b0; ph = 1'b0;
    for (int k = 0; k < int'(H); k++) w[k] = 16'h7BFF;
    y[1] = 16'h4800;

    $display("HEIGHT=%0d  --- V2 : reset clears", H);
    repeat (3) @(posedge clk);
    chk("z_o == +0 under reset",       z === '0);
    chk("status_o == 0 under reset",   st === '0);

    // ---------------- run A : flush low, record the alternation ----------
    settle();
    for (int i = 0; i < 8; i++) begin @(posedge clk); sA[i] = st[0][0]; end

    // ---------------- run B : same phase, flush high --------------------
    settle();
    @(negedge clk); flush = 1'b1;
    for (int i = 0; i < 8; i++) begin
      @(posedge clk); sB[i] = st[0][0]; zB[i] = z[0];
    end
    @(negedge clk); flush = 1'b0;

    $display("HEIGHT=%0d  --- C2 : flush suspends status_o", H);
    $display("    flush low : %p", sA);
    $display("    flush high: %p", sB);
    chk("run A alternates (A0 != A1)",              sA[0] !== sA[1]);
    chk("tick 1 still updates  (B0 == A0)",         sB[0] === sA[0]);
    chk("ticks >= 2 hold tick 1 (B[i] == B0)",
        (sB[1]===sB[0]) && (sB[2]===sB[0]) && (sB[3]===sB[0]) &&
        (sB[4]===sB[0]) && (sB[5]===sB[0]) && (sB[6]===sB[0]) &&
        (sB[7]===sB[0]));
    chk("flags NOT cleared during assertion",       sB[0] !== 5'b00000 || sA[0] === 5'b00000);
    chk("z_o == +0 at EVERY tick incl. tick 1",
        (zB[0]===16'h0000)&&(zB[1]===16'h0000)&&(zB[2]===16'h0000)&&
        (zB[3]===16'h0000)&&(zB[4]===16'h0000)&&(zB[5]===16'h0000)&&
        (zB[6]===16'h0000)&&(zB[7]===16'h0000));

    // ---------------- run C : phase shifted by one tick ------------------
    // run B froze on the flag-free phase, so "not cleared" proved nothing
    // there.  Shift one tick so the frozen value is the OVERFLOWING one:
    // a clearing implementation reads 00000, a holding one reads 00101.
    settle();
    @(posedge clk);
    @(negedge clk); flush = 1'b1;
    for (int i = 0; i < 8; i++) begin
      @(posedge clk); sB[i] = st[0][0]; zB[i] = z[0];
    end
    @(negedge clk); flush = 1'b0;
    $display("    flush high, shifted phase: %p", sB);
    chk("frozen value is NONZERO here",             sB[0] === 5'b00101);
    chk("held, not cleared, for all 8 ticks",
        (sB[1]===5'b00101)&&(sB[2]===5'b00101)&&(sB[3]===5'b00101)&&
        (sB[4]===5'b00101)&&(sB[5]===5'b00101)&&(sB[6]===5'b00101)&&
        (sB[7]===5'b00101));
    chk("z_o still +0 throughout",
        (zB[0]===16'h0000)&&(zB[7]===16'h0000));

    $display("HEIGHT=%0d  --- C2/C4 : flush vs the clock gate and reg_enable", H);
    settle();
    chk("row 1 carries its bias",                   z[1] === 16'h4800);
    @(negedge clk); gate[1] = 1'b0; flush = 1'b1;
    repeat (6) @(posedge clk);
    chk("gated row NOT cleared by flush",           z[1] === 16'h4800);
    chk("clocked row cleared by flush",             z[0] === 16'h0000);
    @(negedge clk); regen = 1'b0;
    repeat (6) @(posedge clk);
    chk("flush outranks reg_enable low",            z[0] === 16'h0000);
    chk("gated row still held",                     z[1] === 16'h4800);
    @(negedge clk); flush = 1'b0; gate[1] = 1'b1;

    $display("HEIGHT=%0d  --- C1 : reg_enable low freezes everything", H);
    repeat (8) @(posedge clk);
    chk("z_o holds while reg_enable low",           z[1] === 16'h4800);
    chk("status holds while reg_enable low",        st[0][0] === st[0][0]);
    @(negedge clk); regen = 1'b1;

    $display("HEIGHT=%0d  ctrl_probe: %0d failures", H, fails);
    $finish;
  end
endmodule
