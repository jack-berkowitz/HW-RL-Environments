// probe_corners_tb.sv -- d_ai01 STEP 0 MEASUREMENT #3. Not a scoring TB.
//
// Establishes, by observation, what the anchor DELIVERS at and beyond the ends
// of the binary16 range, in every rounding mode, together with the status flags
// it raises. The spec's range clauses are written FROM THIS TABLE. Writing them
// from IEEE 754 prose instead is the d_dsp02 mistake: the standard admits more
// than one delivered value at the boundaries, the anchor picks one, and a
// contract that only cites the standard leaves that pick to the oracle.
//
// INJECTION POINT: the LAST stage, k = H-1. Every upstream stage is driven
// x=+0, w=+0, y=+0 so it evaluates (+0 * +0) + addend and hands +0 down the
// chain. The corner case is then x[H-1] * w[H-1] + (+0), whose result reaches
// z_o after the measured tail latency of 2 cycles (see probe_skew_tb).
//
// Injecting at stage 0 instead would be wrong: the result would have to survive
// H-1 further pass-through adds, and (+0) + (-0) is +0 in every rounding mode
// except roundTowardNegative -- which would silently destroy exactly the
// signed-zero evidence this probe exists to collect.
module probe_corners_tb;

  localparam int unsigned H = 4;
  localparam int unsigned W = 1;

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

  string rname [0:4];

  task automatic shot(input string label, input logic [15:0] xv, wv);
    logic [15:0] got;
    logic [4:0]  fl;
    begin
      for (int m = 0; m < 5; m++) begin
        rnd = m[2:0];
        flush = 1'b1; repeat (2) @(posedge clk); flush = 1'b0;
        repeat (4*H + 6) @(posedge clk);
        // HOLD the operands stable across several edges rather than sampling
        // at the exact tail latency. The first cut of this probe waited exactly
        // 2 edges and read z=0 for EVERY case while the status flags varied
        // correctly -- a one-edge-early read, not an anchor that returns zero.
        // With the operands held, the last stage recomputes x*w+(+0) every
        // cycle and z settles and stays, so the reading cannot be off by one.
        x[0][H-1] = xv;
        wt[H-1]   = wv;
        repeat (6) @(posedge clk);
        #1;
        got = z[0];
        fl  = status[0][H-1];
        $display("  %-26s rnd=%-4s x=0x%04x w=0x%04x -> z=0x%04x  NV=%0d DZ=%0d OF=%0d UF=%0d NX=%0d",
                 label, rname[m], xv, wv, got, fl[4], fl[3], fl[2], fl[1], fl[0]);
        x[0][H-1] = 16'h0000;
        wt[H-1]   = 16'h0000;
      end
      $display("");
    end
  endtask

  initial begin
    rname[0]="RNE"; rname[1]="RTZ"; rname[2]="RDN"; rname[3]="RUP"; rname[4]="RMM";

    for (int r = 0; r < W; r++) begin
      y[r] = 16'h0000;
      for (int k = 0; k < H; k++) x[r][k] = 16'h0000;
    end
    for (int k = 0; k < H; k++) wt[k] = 16'h0000;
    rnd = 3'd0; accumulate = 1'b0; row_gate = '1;
    reg_enable = 1'b0; flush = 1'b0; 

    repeat (4) @(posedge clk);
    rst_n = 1'b1;
    @(posedge clk);
    reg_enable = 1'b1;

    $display("binary16 reference points: max finite 0x7BFF=65504, min normal 0x0400=2^-14,");
    $display("min subnormal 0x0001=2^-24, +inf 0x7C00, qNaN 0x7E00");
    $display("");

    // ---- ABOVE the representable range, both signs ----
    shot("overflow +",        16'h7BFF, 16'h4000);  //  65504 * 2
    shot("overflow -",        16'hFBFF, 16'h4000);  // -65504 * 2

    // ---- BELOW the representable range, both signs ----
    shot("underflow-to-zero +", 16'h0001, 16'h3800); //  2^-24 * 0.5 = 2^-25
    shot("underflow-to-zero -", 16'h8001, 16'h3800); // -2^-24 * 0.5
    shot("into subnormal +",    16'h0400, 16'h3800); //  2^-14 * 0.5 = 2^-15
    shot("into subnormal -",    16'h8400, 16'h3800); // -2^-14 * 0.5

    // ---- exact zero sign ----
    shot("pos * pos zero",    16'h0000, 16'h3C00);
    shot("neg * pos zero",    16'h8000, 16'h3C00);

    // ---- non-finite ----
    shot("inf * 2",           16'h7C00, 16'h4000);
    shot("inf * 0 (invalid)", 16'h7C00, 16'h0000);
    shot("qNaN * 2",          16'h7E00, 16'h4000);

    $finish;
  end

endmodule
