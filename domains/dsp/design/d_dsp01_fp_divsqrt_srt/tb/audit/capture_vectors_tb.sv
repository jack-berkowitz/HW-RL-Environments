// =============================================================================
// capture_vectors_tb.sv -- VECTOR CAPTURE. Never scored, never shipped.
// =============================================================================
// Rule 11's inversion. This file is LOCALLY AUTHORED and it generates INPUTS
// ONLY. Expected values are whatever the vendored anchor produces for those
// inputs, so a bug in this file costs COVERAGE and can never produce a wrong
// expected value.
//
// The consequence, which is the part that gets forgotten: with expected values
// safe by construction, the only remaining failure is a corner never generated.
// Nothing goes wrong loudly -- the run passes, the vectors are correct, and the
// untested case is simply absent. That is why the scoring testbench's floors
// are all stimulus-side and why the corner list below is directed rather than
// left to the random stream.
//
// Output: vectors/vectors.hex, one 112-bit word per line:
//   [111:105] pad   [104] op   [103:101] rnd
//   [100:69] a      [68:37] b  [36:5] result   [4:0] flags
// =============================================================================
module capture_vectors_tb;

  localparam int unsigned NCORNER = 22;
  localparam int unsigned NRAND   = 560;

  logic clk = 0, rst_n = 0;
  always #5 clk = ~clk;

  logic        iv, ir, op, ov, orr;
  logic [31:0] a, b, res;
  logic [2:0]  rnd;
  logic [4:0]  fl;

  fp_divsqrt_srt dut (
    .clk_i(clk), .rst_ni(rst_n),
    .in_valid_i(iv), .in_ready_o(ir), .op_i(op), .a_i(a), .b_i(b), .rnd_i(rnd),
    .out_valid_o(ov), .out_ready_i(orr), .result_o(res), .flags_o(fl));

  // Directed corners. Every one is here because it is a boundary the contract
  // names: subnormal edges, the normal/subnormal transition, the exact powers
  // where rounding ties land, and every operand class A4 and A5 mention.
  logic [31:0] corner [NCORNER];
  initial begin
    corner[0]  = 32'h0000_0000;  // +0
    corner[1]  = 32'h8000_0000;  // -0
    corner[2]  = 32'h0000_0001;  // smallest subnormal
    corner[3]  = 32'h007F_FFFF;  // largest subnormal
    corner[4]  = 32'h0080_0000;  // smallest normal
    corner[5]  = 32'h0080_0001;
    corner[6]  = 32'h3F80_0000;  // 1.0
    corner[7]  = 32'h3F80_0001;  // 1.0 + 1ulp
    corner[8]  = 32'h4000_0000;  // 2.0
    corner[9]  = 32'h3F00_0000;  // 0.5
    corner[10] = 32'h7F7F_FFFF;  // largest normal
    corner[11] = 32'h7F80_0000;  // +inf
    corner[12] = 32'hFF80_0000;  // -inf
    corner[13] = 32'h7FC0_0000;  // quiet NaN
    corner[14] = 32'h7F80_0001;  // signalling NaN
    corner[15] = 32'hBF80_0000;  // -1.0
    corner[16] = 32'h8080_0000;  // -smallest normal
    corner[17] = 32'h8000_0001;  // -smallest subnormal
    corner[18] = 32'h4170_0000;  // 15.0
    corner[19] = 32'h4000_0001;
    corner[20] = 32'h7EFF_FFFF;  // big, so a/big underflows
    corner[21] = 32'h0040_0000;  // mid subnormal
  end

  logic [31:0] lfsr = 32'hD5_F0_10_01;
  function automatic logic [31:0] nxt(input logic [31:0] s);
    nxt = {s[30:0], s[31]^s[21]^s[1]^s[0]};
  endfunction
  task automatic roll(); lfsr = nxt(lfsr); endtask

  // A random draw biased toward the interesting exponents rather than uniform
  // over 2^32, which would be almost entirely large normals and would never
  // produce a subnormal result.
  function automatic logic [31:0] rnd_fp(input logic [31:0] s);
    logic [7:0] e;
    case (s[30:29])
      2'b00: e = 8'(s[7:0] % 8'd12);              // subnormal / tiny
      2'b01: e = 8'd127 + 8'(s[3:0]) - 8'd8;      // around 1.0
      2'b10: e = 8'd240 + 8'(s[3:0] % 8'd15);     // near overflow
      default: e = 8'(s[15:8]);                   // anywhere
    endcase
    rnd_fp = {s[31], e, s[22:0]};
  endfunction

  int fd, nvec;
  logic [111:0] w;

  // HANDSHAKE. Everything is DRIVEN at negedge and SAMPLED at negedge, and the
  // waits test before they wait. Both halves of that matter and the first
  // version got both wrong:
  //
  //   * `do @(negedge clk); while (!ir);` waits a negedge BEFORE testing, so it
  //     cannot observe a ready that was already high when the operation was
  //     presented. It kept `in_valid_i` asserted for the whole operation and
  //     exited only at the completion cycle -- where the anchor's FSM re-asserts
  //     in_ready while presenting the result (fpnew_divsqrt_multi.sv BUSY, the
  //     `out_ready` branch) -- so it read the RESULT cycle's ready as its own
  //     acceptance, a cycle-late by ten.
  //
  //   * `out_ready_i` is held high, so `out_valid_o` is high for EXACTLY ONE
  //     CYCLE. The second do/while then skipped the only negedge inside that
  //     window and waited forever. Zero vectors, watchdog, and an empty file --
  //     the buffered writes are lost on $finish, so a stall at vector 2000 and
  //     a stall at vector 0 look identical from outside. That is why the
  //     progress trace, not more reading, found it.
  //
  // The `#0` re-settles combinational logic after the drive: L4 permits
  // in_ready_o to depend combinationally on in_valid_i, and this rig is the
  // template the scoring testbench follows, where candidates will do exactly
  // that.
  task automatic issue(input logic o, input logic [31:0] av, input logic [31:0] bv,
                       input logic [2:0] r);
    @(negedge clk);
    op = o; a = av; b = bv; rnd = r; iv = 1'b1;
    #0;
    while (!ir) begin @(negedge clk); #0; end   // the next posedge takes it
    @(negedge clk);
    iv = 1'b0;
    #0;
    while (!ov) begin @(negedge clk); #0; end   // one-cycle window: test first
    w = {7'b0, o, r, av, bv, res, fl};
    $fwrite(fd, "%028h\n", w);
    nvec++;
  endtask

  int i, j, k;
  initial begin
    iv = 0; orr = 1'b1; op = 0; a = 0; b = 0; rnd = 0; nvec = 0;
    fd = $fopen("vectors/vectors.hex", "w");
    if (fd == 0) begin $display("CAPTURE: cannot open vectors/vectors.hex"); $finish; end
    repeat (8) @(negedge clk); rst_n = 1; repeat (4) @(negedge clk);

    // corner x corner, every rounding mode, both operations
    for (k = 0; k < 5; k++)
      for (i = 0; i < int'(NCORNER); i++)
        for (j = 0; j < int'(NCORNER); j = j + 3) begin
          issue(1'b0, corner[i], corner[j], 3'(k));           // DIV
          if (j == 0) issue(1'b1, corner[i], lfsr, 3'(k));    // SQRT, b is garbage on purpose (L6)
        end

    // randomized, biased toward the interesting exponent bands
    for (i = 0; i < int'(NRAND); i++) begin
      roll();
      issue(1'b0, rnd_fp(lfsr), rnd_fp(nxt(lfsr)), 3'(i % 5));
      roll();
      issue(1'b1, rnd_fp(lfsr), nxt(lfsr), 3'((i+2) % 5));
    end

    $fclose(fd);
    $display("CAPTURE: wrote %0d vectors", nvec);
    $finish;
  end

  initial begin
    #20_000_000;
    $display("CAPTURE: watchdog -- the anchor stopped producing results");
    $finish;
  end
endmodule
