// fp16_gemm_array_tb.sv -- d_ai01 SCORING testbench.
//
// Replays the captured stimulus against the submitted `fp16_gemm_array` and
// compares z_o and status_o cycle by cycle against what the reference
// delivered. The operand skew of spec A3 is not modelled here: it is already
// present in the recorded outputs, so a DUT with the wrong skew mismatches on
// ordinary vectors rather than needing a special test.
//
// COVERAGE FLOORS. Passing every vector is not by itself evidence that the
// vectors reached the behaviour the contract turns on. The floors below are
// derived from the spec's own tables -- A5 and A6 are MODE-DEPENDENT AND
// SIGN-DEPENDENT, ten distinct delivered values each, so the floor is the
// product (mode x sign), not a count of overflow events.
//
// ABSENCE GUARD. `cov_tallied` separates "this condition was measured and never
// occurred" from "this condition was never measured". Reporting the first as
// the second is how a broken detector reads as a clean run.

`ifndef HH
 `define HH 8
`endif
`define VH `HH
`define VW 8

`include "fp16_gemm_array_vec.svh"

module fp16_gemm_array_tb;

  localparam int unsigned H = `VH;
  localparam int unsigned W = `VW;
  localparam int unsigned NCYC = 3400;
  localparam int unsigned MAX_REPORT = 12;

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
    .reg_enable_i(reg_enable), .flush_i(flush), .status_o(status)
  );

  logic [REC_W-1:0] recs [0:NCYC-1];
  rec_t             r;
  string            vfile;

  int unsigned errs_z, errs_st, reported, n, checked;

  // ---- coverage ----
  logic        cov_of   [0:4][0:1];   // A5: rounding mode x sign of product
  logic        cov_uf   [0:4][0:1];   // A6: rounding mode x sign of product
  logic        cov_rnd  [0:4];
  logic        cov_nv, cov_nx, cov_dz;
  logic        cov_acc, cov_flush, cov_stall, cov_gate;
  logic        cov_flush_gated, cov_flush_stalled;
  logic        cov_sub_delivered, cov_inf_delivered, cov_nan_delivered;
  logic        cov_negzero_delivered;
  int unsigned cov_tallied;

  function automatic bit is_sub(input logic [15:0] v);
    return (v[14:10] == 5'd0) && (v[9:0] != 10'd0);
  endfunction
  function automatic bit is_inf(input logic [15:0] v);
    return (v[14:10] == 5'h1F) && (v[9:0] == 10'd0);
  endfunction
  function automatic bit is_nan(input logic [15:0] v);
    return (v[14:10] == 5'h1F) && (v[9:0] != 10'd0);
  endfunction

  initial begin
    for (int m = 0; m < 5; m++) begin
      cov_rnd[m] = 1'b0;
      for (int sg = 0; sg < 2; sg++) begin
        cov_of[m][sg] = 1'b0;
        cov_uf[m][sg] = 1'b0;
      end
    end
    cov_nv = 0; cov_nx = 0; cov_dz = 0;
    cov_acc = 0; cov_flush = 0; cov_stall = 0; cov_gate = 0;
    cov_flush_gated = 0; cov_flush_stalled = 0;
    cov_sub_delivered = 0; cov_inf_delivered = 0; cov_nan_delivered = 0;
    cov_negzero_delivered = 0;
    cov_tallied = 0;
    errs_z = 0; errs_st = 0; reported = 0; checked = 0;

    if (!$value$plusargs("vec=%s", vfile)) vfile = "vectors.hex";
    $readmemh(vfile, recs);

    rst_n = 1'b0;
    rnd = 3'd0; accumulate = 1'b0; flush = 1'b0; reg_enable = 1'b1; row_gate = '1;
    for (int rr = 0; rr < W; rr++) begin
      y[rr] = 16'h3C00;
      for (int k = 0; k < H; k++) x[rr][k] = 16'h3C00;
    end
    for (int k = 0; k < H; k++) wt[k] = 16'h3C00;

    repeat (4) @(posedge clk);
    rst_n = 1'b1;
    @(posedge clk);

    for (n = 0; n < NCYC; n++) begin
      r = rec_t'(recs[n]);

      x          = r.x;
      wt         = r.w;
      y          = r.y;
      rnd        = r.rnd;
      accumulate = r.accumulate;
      flush      = r.flush;
      reg_enable = r.reg_enable;
      row_gate   = r.row_gate;

      @(posedge clk);
      #1;

      checked++;

      if (z !== r.z) begin
        errs_z++;
        if (reported < MAX_REPORT) begin
          reported++;
          $display("MISMATCH z   cycle %0d: expected %h got %h", n, r.z, z);
        end
      end
      if (status !== r.status) begin
        errs_st++;
        if (reported < MAX_REPORT) begin
          reported++;
          $display("MISMATCH st  cycle %0d: expected %h got %h", n, r.status, status);
        end
      end

      // ---- coverage, tallied from the REFERENCE record so a broken DUT
      // ---- cannot inflate or suppress it ----
      cov_tallied++;
      if (r.rnd < 5) cov_rnd[r.rnd] = 1'b1;
      cov_acc   |= r.accumulate;
      cov_flush |= r.flush;
      cov_stall |= ~r.reg_enable;
      cov_gate  |= (r.row_gate != {W{1'b1}});
      // C2's two precedence questions, each needing its own stimulus: flush
      // against a GATED row (which flush does not clear) and flush against a
      // stalled one (which it does).
      cov_flush_gated   |= (r.flush && (r.row_gate != {W{1'b1}}));
      cov_flush_stalled |= (r.flush && !r.reg_enable);

      for (int rr = 0; rr < W; rr++) begin
        for (int k = 0; k < H; k++) begin
          automatic logic [4:0] st = r.status[rr][k];
          automatic bit sgn = r.x[rr][k][15] ^ r.w[k][15];
          if (r.rnd < 5) begin
            if (st[2]) cov_of[r.rnd][sgn] = 1'b1;   // OF
            if (st[1]) cov_uf[r.rnd][sgn] = 1'b1;   // UF
          end
          cov_nv |= st[4];
          cov_dz |= st[3];
          cov_nx |= st[0];
        end
        cov_sub_delivered     |= is_sub(r.z[rr]);
        cov_inf_delivered     |= is_inf(r.z[rr]);
        cov_nan_delivered     |= is_nan(r.z[rr]);
        cov_negzero_delivered |= (r.z[rr] == 16'h8000);
      end
    end

    // ------------------------------------------------------------------
    report_coverage();

    $display("");
    $display("d_ai01 H=%0d W=%0d : %0d cycles checked, %0d z mismatches, %0d status mismatches",
             H, W, checked, errs_z, errs_st);
    if (errs_z == 0 && errs_st == 0) $display("RESULT: PASS");
    else                             $display("RESULT: FAIL");
    $finish;
  end

  task automatic report_coverage();
    int unsigned of_hits, uf_hits, rnd_hits;
    bit floors_ok;
    begin
      floors_ok = 1'b1;

      if (cov_tallied == 0) begin
        // An unfilled record is worse than no record: say so plainly rather
        // than printing zeros that read like measured absence.
        $display("COVERAGE: NOT MEASURED -- no cycle was ever tallied.");
        $display("RESULT: FAIL");
        $finish;
      end

      of_hits = 0; uf_hits = 0; rnd_hits = 0;
      for (int m = 0; m < 5; m++) begin
        if (cov_rnd[m]) rnd_hits++;
        for (int sg = 0; sg < 2; sg++) begin
          if (cov_of[m][sg]) of_hits++;
          if (cov_uf[m][sg]) uf_hits++;
        end
      end

      $display("");
      $display("COVERAGE (tallied over %0d cycles)", cov_tallied);
      $display("  rounding modes reached      : %0d/5", rnd_hits);
      $display("  A5 overflow  mode x sign    : %0d/10", of_hits);
      $display("  A6 underflow mode x sign    : %0d/10", uf_hits);
      $display("  flags seen                  : NV=%0d NX=%0d DZ=%0d", cov_nv, cov_nx, cov_dz);
      $display("  controls                    : accumulate=%0d flush=%0d stall=%0d rowgate=%0d",
               cov_acc, cov_flush, cov_stall, cov_gate);
      $display("  C2 precedence               : flush+gated=%0d flush+stalled=%0d",
               cov_flush_gated, cov_flush_stalled);
      $display("  delivered classes           : subnormal=%0d inf=%0d nan=%0d negzero=%0d",
               cov_sub_delivered, cov_inf_delivered, cov_nan_delivered,
               cov_negzero_delivered);

      // ---- floors ----
      if (rnd_hits != 5)  begin floors_ok = 0; $display("  FLOOR FAIL: not all 5 rounding modes reached"); end
      if (of_hits  < 10)  begin floors_ok = 0; $display("  FLOOR FAIL: A5 combination floor %0d/10", of_hits); end
      if (uf_hits  < 10)  begin floors_ok = 0; $display("  FLOOR FAIL: A6 combination floor %0d/10", uf_hits); end
      if (!cov_acc)       begin floors_ok = 0; $display("  FLOOR FAIL: accumulate never exercised"); end
      if (!cov_flush)     begin floors_ok = 0; $display("  FLOOR FAIL: flush never exercised"); end
      if (!cov_stall)     begin floors_ok = 0; $display("  FLOOR FAIL: stall never exercised"); end
      if (!cov_gate)      begin floors_ok = 0; $display("  FLOOR FAIL: row gating never exercised"); end
      if (!cov_flush_gated)
        begin floors_ok = 0; $display("  FLOOR FAIL: flush never coincided with a gated row (C2)"); end
      if (!cov_flush_stalled)
        begin floors_ok = 0; $display("  FLOOR FAIL: flush never coincided with a stall (C2 precedence)"); end
      if (!cov_sub_delivered) begin floors_ok = 0; $display("  FLOOR FAIL: no subnormal ever delivered (F1)"); end
      if (!cov_nv)        begin floors_ok = 0; $display("  FLOOR FAIL: NV never raised (A9)"); end
      // A6 sign preservation and A8's roundTowardNegative case are both about
      // the sign of a DELIVERED zero, which the per-stage flag floors above do
      // not reach. Floored separately and driven by the directed tail phases.
      if (!cov_negzero_delivered)
        begin floors_ok = 0; $display("  FLOOR FAIL: -0 never delivered on z_o (A6 sign preservation, A8)"); end

      // DZ is expected to be absent -- there is no division in this unit. This
      // is MEASURED ABSENCE, not an unmeasured hole, which is why it is
      // asserted rather than floored.
      if (cov_dz) $display("  UNEXPECTED: DZ raised, but this unit has no division (V3)");

      $display("  FLOORS: %s", floors_ok ? "OK" : "FAILED");
    end
  endtask

endmodule
