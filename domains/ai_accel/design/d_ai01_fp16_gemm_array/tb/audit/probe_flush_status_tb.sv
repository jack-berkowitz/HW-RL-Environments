// probe_flush_status_tb.sv -- d_ai01. EXECUTES an externally written spec.
// Not a scoring TB. Never shipped.
//
// PROVENANCE. The spec is d_ai01_probe_spec.md, written by an agent WITHOUT tb/
// access specifically so the derivation and the measurement are separated. This
// file executes it UNMODIFIED. Where the spec was ambiguous the ambiguity is
// REPORTED, not resolved -- resolving is a derivation act and the executor is
// disqualified from those.
//
// WHAT IT SETTLES: whether status_o ADVANCES or HOLDS while flush_i is asserted.
//   probe (i)  does the disagreement recur past the window, under a stimulus
//              that actually varies. A CONSTANT field cannot discriminate.
//   probe (ii) is stage 0 touched at all -- identical stimulus, flush vs no-flush.
// Controls C1/C2/C3 per the spec, because both probes discriminate on an ABSENCE.
`timescale 1ns/1ps
`ifndef HH
  `define HH 4
`endif

module probe_flush_status_tb;
  localparam int unsigned H = `HH;
  localparam int unsigned W = 8;
  localparam int unsigned D = 4;
  localparam int unsigned D0 = D*(H-1) + 3;      // d(0), enabled ticks
  localparam int unsigned PRE  = D0 + 2;         // steady state before flush
  localparam int unsigned FLEN = 12;             // flush-high enabled ticks
  localparam int unsigned POST = D0;             // ticks sampled after flush
  localparam int unsigned NT   = PRE + FLEN + POST + 4;

  logic clk = 1'b0, rst_n = 1'b0;
  always #5 clk = ~clk;

  logic [W-1:0][H-1:0][15:0] x;
  logic         [H-1:0][15:0] w;
  logic [W-1:0]        [15:0] y;
  logic [W-1:0]        [15:0] z;
  logic [2:0]  rnd;  logic accumulate, reg_enable, flush;
  logic [W-1:0] row_gate;
  logic [W-1:0][H-1:0][4:0] status;

  fp16_gemm_array #(.HEIGHT(H), .WIDTH(W)) dut (
    .clk_i(clk), .rst_ni(rst_n), .x_i(x), .w_i(w), .y_i(y), .z_o(z),
    .rnd_i(rnd), .accumulate_i(accumulate), .row_clk_gate_en_i(row_gate),
    .reg_enable_i(reg_enable), .flush_i(flush), .status_o(status)
  );

  // ---- the alternating stimulus, spec "THE ALTERNATING STIMULUS" -----------
  //   A: x=w=0x7BFF, product overflows        B: x=0x3800, w=0x0400, tiny exact
  task automatic drive_phase(input bit phaseA);
    for (int r = 0; r < W; r++)
      for (int k = 0; k < H; k++)
        x[r][k] = phaseA ? 16'h7BFF : 16'h3800;
    for (int k = 0; k < H; k++)
      w[k] = phaseA ? 16'h7BFF : 16'h0400;
  endtask

  // captured per run: [tick][row][stage]
  logic [4:0] capF [0:NT-1][0:W-1][0:H-1];
  logic [4:0] capN [0:NT-1][0:W-1][0:H-1];
  int unsigned samples;

  task automatic run_once(input bit with_flush, input bit isF);
    bit phase;
    samples = 0;
    rst_n = 1'b0; flush = 1'b0; accumulate = 1'b0; reg_enable = 1'b1;
    row_gate = {W{1'b1}}; rnd = 3'd0;
    for (int r = 0; r < W; r++) y[r] = 16'h0000;
    phase = 1'b1; drive_phase(phase);
    repeat (10) @(posedge clk);
    @(negedge clk); rst_n = 1'b1;
    for (int t = 0; t < NT; t++) begin
      // stimulus changes on the NEGEDGE, never on the sampling edge
      @(negedge clk);
      phase = ~phase; drive_phase(phase);
      flush = with_flush && (t >= PRE) && (t < PRE + FLEN);
      @(posedge clk); #1;
      for (int r = 0; r < W; r++)
        for (int k = 0; k < H; k++)
          if (isF) capF[t][r][k] = status[r][k]; else capN[t][r][k] = status[r][k];
      samples++;
    end
  endtask

  int unsigned c1_diff, c2_tog, rec_cnt, s0_diff;
  initial begin
    $display("=== probe_flush_status  H=%0d W=%0d  d(0)=%0d  PRE=%0d FLEN=%0d ===", H, W, D0, PRE, FLEN);

    run_once(1'b1, 1'b1);   // run F -- with flush
    run_once(1'b0, 1'b0);   // run N -- flush low throughout

    // ---- C3: the run produced samples at all -----------------------------
    $display("C3 vector/sample guard: samples=%0d expected=%0d  %s",
             samples, NT, (samples == NT) ? "OK" : "*** FAIL ***");

    // ---- C1: comparator fires on a known-different pair -------------------
    // F's stage 0 vs F's stage 1: different operations under the staggered field.
    c1_diff = 0;
    for (int t = 0; t < NT; t++)
      for (int r = 0; r < W; r++)
        if (capF[t][r][0] !== capF[t][r][1]) c1_diff++;
    $display("C1 comparator control: stage0 vs stage1 differing samples=%0d  %s",
             c1_diff, (c1_diff > 0) ? "FIRES" : "*** INERT -- silence means nothing ***");

    // ---- C2: sampler toggles with flush LOW -------------------------------
    c2_tog = 0;
    for (int t = 1; t < NT; t++)
      for (int r = 0; r < W; r++)
        for (int k = 0; k < H; k++)
          if (capN[t][r][k] !== capN[t-1][r][k]) c2_tog++;
    $display("C2 sampler control: transitions with flush low=%0d  %s",
             c2_tog, (c2_tog > 0) ? "FIRES" : "*** INERT -- stimulus not varying flags ***");
    // C2 PER STAGE. The spec's C2 is a GLOBAL toggle count, and probe (i) reads
    // only k>=1. A global fire does not establish that the sampler fires WHERE
    // THE PROBE LOOKS. Reported, not resolved: this is an observation about the
    // control's scope, and narrowing the control is the spec author's call.
    for (int k = 0; k < H; k++) begin
      int unsigned tk; tk = 0;
      for (int t = 1; t < NT; t++)
        for (int r = 0; r < W; r++)
          if (capN[t][r][k] !== capN[t-1][r][k]) tk++;
      $display("   C2 per-stage k=%0d transitions with flush low = %0d   %s",
               k, tk, (tk > 0) ? "fires" : "*** INERT AT THIS STAGE ***");
    end

    // ---- PROBE (i): recurrence past the window, k>=1, flush ticks t>=4 -----
    // flush-high enabled ticks numbered 1..FLEN
    rec_cnt = 0;
    for (int n = 4; n <= FLEN; n++)
      for (int r = 0; r < W; r++)
        for (int k = 1; k < H; k++) begin
          int ti = PRE + n - 1;
          if (capF[ti][r][k] !== capF[ti-1][r][k]) rec_cnt++;
        end
    $display("PROBE(i) recurrence: transitions at flush ticks 4..%0d, k>=1 = %0d", FLEN, rec_cnt);
    $display("PROBE(i) VERDICT: %s",
             (rec_cnt > 0) ? "ADVANCE -- status toggles inside the assertion"
                           : "HOLD -- constant across t=4..12 (R-C live)");

    // ---- PROBE (ii): is stage 0 touched at all ----------------------------
    s0_diff = 0;
    for (int t = PRE; t < PRE + FLEN + POST && t < NT; t++)
      for (int r = 0; r < W; r++)
        if (capF[t][r][0] !== capN[t][r][0]) s0_diff++;
    $display("PROBE(ii) stage0 F-vs-N differing samples=%0d", s0_diff);
    $display("PROBE(ii) VERDICT: %s",
             (s0_diff == 0) ? "IDENTICAL -- stage 0 unaffected, locus is k>=1"
                            : "DIFFERS -- not the addend axis; k>=1 scoping is WRONG");

    // a trace of the first flush ticks, so the numbers can be read not just the verdict
    $display("--- run F, row 0, flush ticks 1..%0d ---", (FLEN<8)?FLEN:8);
    for (int n = 1; n <= ((FLEN<8)?FLEN:8); n++) begin
      $write("  tick %0d:", n);
      for (int k = 0; k < H; k++) $write(" k%0d=%05b", k, capF[PRE+n-1][0][k]);
      $write("\n");
    end
    $display("--- run N, row 0, same ticks ---");
    for (int n = 1; n <= ((FLEN<8)?FLEN:8); n++) begin
      $write("  tick %0d:", n);
      for (int k = 0; k < H; k++) $write(" k%0d=%05b", k, capN[PRE+n-1][0][k]);
      $write("\n");
    end
    $finish;
  end
endmodule
