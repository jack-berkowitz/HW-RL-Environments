// probe_flush_stall_edge_tb.sv -- d_ai01. AUDIT PROBE. Not a scoring TB. Never shipped.
//
// THE SPEC IT EXECUTES, written 2026-08-27, stated here because it is short and
// because a probe whose spec lives only in a chat log cannot be audited.
//
// THE QUESTION. C2 p3 says flush_i outranks reg_enable_i: with reg_enable_i low
// and flush_i high, every clocked row clears. MEASUREMENTS Sec 7 confirms the
// RESULT -- 0x0000 in both rows -- and records no EDGE. A1 defines an enabled
// tick as requiring reg_enable_i high, so in this regime NO enabled tick passes
// and A10's timebase does not advance, yet z_o clears anyway. On WHICH edge,
// relative to the assertion, has never been measured.
//
//   z_o ONLY. status_o is deliberately out of scope: under the C2 landed
//   2026-08-27 status_o holds through an assertion, and it also holds when no
//   enabled tick passes, so this regime does not discriminate for status_o. It
//   does for z_o, which clears in one case and would hold in the other.
//
// WHAT IT CANNOT SETTLE, stated so silence is not read as completeness. It
// measures the reference. It does not establish what the contract should say,
// and no clause is written from it.
//
// THE ARMS. Four, of which two are controls per Rule 24 -- this probe
// discriminates on WHEN a value appears, so an instrument that never sees a
// clear and an instrument that reports one everywhere both read as answers.
//
//   S  reg_enable 0, flush 1, all gates on   THE REGIME UNDER TEST
//   E  reg_enable 1, flush 1, all gates on   CONTROL, MUST clear (C2 p1, Sec 7)
//   G  reg_enable 1, flush 1, all gates OFF  CONTROL, MUST NOT clear (C4)
//   Q  stall established first, THEN flush   the same regime entered the other
//                                            way round, since S changes two
//                                            inputs on one edge and cannot tell
//                                            a simultaneity effect from a rule
//
// VACUITY GUARD. "Cleared" is only observable from a nonzero start. Each arm
// reports its settled value and FAILS if it is already 0x0000 -- the defect
// recorded at this task's own vector guard, where a test passed a run with
// nothing loaded.
`timescale 1ns/1ps
`ifndef HH
  `define HH 4
`endif

module probe_flush_stall_edge_tb;
  localparam int unsigned H  = `HH;
  localparam int unsigned W  = 8;
  localparam int unsigned D  = 4;
  localparam int unsigned D0 = D*(H-1) + 3;
  localparam int unsigned PRE   = D0 + 6;   // settle, enabled ticks
  localparam int unsigned STALL = 6;        // arm Q: stall depth before flush
  localparam int unsigned NOBS  = 8;        // observation edges after assertion

  logic clk = 1'b0, rst_n = 1'b0;
  always #5 clk = ~clk;

  logic [W-1:0][H-1:0][15:0] x;
  logic         [H-1:0][15:0] w;
  logic [W-1:0]        [15:0] y, z;
  logic [2:0]  rnd;  logic accumulate, reg_enable, flush;
  logic [W-1:0] row_gate;
  logic [W-1:0][H-1:0][4:0] status;

  fp16_gemm_array #(.HEIGHT(H), .WIDTH(W)) dut (
    .clk_i(clk), .rst_ni(rst_n), .x_i(x), .w_i(w), .y_i(y), .z_o(z),
    .rnd_i(rnd), .accumulate_i(accumulate), .row_clk_gate_en_i(row_gate),
    .reg_enable_i(reg_enable), .flush_i(flush), .status_o(status)
  );

  // per-arm results
  logic [15:0] settled [0:W-1];
  logic [15:0] obs     [0:NOBS][0:W-1];     // index 0 = the pre-assertion sample
  int          first_zero [0:W-1];          // -1 = never; SIGNED, see F64 family

  // arm: en_during = reg_enable while flush is high
  //      gates_on  = row_clk_gate_en_i during the assertion
  //      prestall  = drop reg_enable STALL cycles BEFORE raising flush
  task automatic run_arm(input bit en_during, input bit gates_on, input bit prestall);
    rst_n = 1'b0; flush = 1'b0; accumulate = 1'b0; reg_enable = 1'b1;
    row_gate = {W{1'b1}}; rnd = 3'd0;
    for (int r = 0; r < W; r++) begin
      y[r] = 16'h0000;
      for (int k = 0; k < H; k++) x[r][k] = 16'h3C00;   // 1.0
    end
    for (int k = 0; k < H; k++) w[k] = 16'h3C00;        // 1.0  -> z settles to H
    repeat (10) @(posedge clk);
    @(negedge clk); rst_n = 1'b1;
    repeat (PRE) @(posedge clk);
    #1;
    for (int r = 0; r < W; r++) begin
      settled[r] = z[r]; obs[0][r] = z[r]; first_zero[r] = -1;
    end

    if (prestall) begin
      @(negedge clk); reg_enable = 1'b0;
      repeat (STALL) @(posedge clk);
    end

    // THE ASSERTION EDGE. Inputs move on the negedge, never on the sampling edge.
    @(negedge clk);
    flush      = 1'b1;
    reg_enable = en_during;
    row_gate   = gates_on ? {W{1'b1}} : {W{1'b0}};

    for (int e = 1; e <= NOBS; e++) begin
      @(posedge clk); #1;
      for (int r = 0; r < W; r++) begin
        obs[e][r] = z[r];
        if (z[r] === 16'h0000 && first_zero[r] < 0) first_zero[r] = e;
      end
    end
  endtask

  // returns 1 if every row cleared on the SAME edge, and reports it
  function automatic bit report_arm(input string tag, input string what);
    bit vac, uni;
    int e0;
    vac = 1'b0;
    for (int r = 0; r < W; r++) if (settled[r] === 16'h0000) vac = 1'b1;
    $display("ARM %s -- %s", tag, what);
    $display("   settled z = %h (all rows)   vacuity guard: %s",
             settled[0], vac ? "*** FAIL -- already zero, a clear is unobservable ***" : "OK");
    e0  = first_zero[0];
    uni = 1'b1;
    for (int r = 0; r < W; r++) if (first_zero[r] != e0) uni = 1'b0;
    if (e0 < 0) $display("   z_o did NOT clear within %0d edges of the assertion", NOBS);
    else        $display("   z_o first read 0x0000 on assertion edge %0d", e0);
    $display("   uniform across the %0d rows: %s", W, uni ? "yes" : "*** NO ***");
    $write  ("   row 0 trace, edge 0(pre)..%0d:", NOBS);
    for (int e = 0; e <= NOBS; e++) $write(" %h", obs[e][0]);
    $write("\n");
    return (e0 >= 0);
  endfunction

  bit cleared_S, cleared_E, cleared_G, cleared_Q;
  int edge_S, edge_E, edge_Q;
  initial begin
    $display("=== probe_flush_stall_edge  H=%0d W=%0d  d(0)=%0d  PRE=%0d STALL=%0d ===",
             H, W, D0, PRE, STALL);

    run_arm(1'b1, 1'b1, 1'b0); cleared_E = report_arm("E", "CONTROL  reg_enable=1 flush=1 gates on -- MUST clear");
    edge_E = first_zero[0];
    run_arm(1'b1, 1'b0, 1'b0); cleared_G = report_arm("G", "CONTROL  reg_enable=1 flush=1 gates OFF -- MUST NOT clear");
    run_arm(1'b0, 1'b1, 1'b0); cleared_S = report_arm("S", "REGIME   reg_enable=0 flush=1 gates on");
    edge_S = first_zero[0];
    run_arm(1'b0, 1'b1, 1'b1); cleared_Q = report_arm("Q", "REGIME   stall established, THEN flush raised");
    edge_Q = first_zero[0];

    $display("--- RULE 24 GATE ---");
    $display("   E fired (clear seen where one must be): %s",
             cleared_E ? "yes" : "*** NO -- instrument blind to clearing; S means nothing ***");
    $display("   G silent (no clear where none exists) : %s",
             cleared_G ? "*** NO -- instrument reports clears that are not there ***" : "yes");

    $display("--- RESULT ---");
    if (!cleared_E || cleared_G)
      $display("   INSTRUMENT INVALID -- no reading reported.");
    else begin
      $display("   z_o with reg_enable LOW and flush HIGH: %s",
               cleared_S ? "CLEARS" : "DOES NOT CLEAR");
      if (cleared_S)
        $display("   edge, from the flush assertion:  S=%0d   E=%0d   %s",
                 edge_S, edge_E,
                 (edge_S == edge_E) ? "SAME EDGE as the enabled case"
                                    : "*** DIFFERENT EDGE from the enabled case ***");
      $display("   entered as an established stall (Q): %s, edge %0d",
               cleared_Q ? "CLEARS" : "DOES NOT CLEAR", edge_Q);
      if (cleared_S && cleared_Q && edge_S != edge_Q)
        $display("   *** S and Q disagree -- the simultaneous change is not the same as the stall ***");
    end
    $finish;
  end
endmodule
