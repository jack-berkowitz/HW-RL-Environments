// capture_vectors_tb.sv -- d_ai01 vector capture. Drives the REFERENCE shim and
// records what it delivers. Never scored; never shipped to a candidate.
//
// Each record is one cycle: the operand field and control state stable across
// rising edge n, followed by z_o and status_o sampled immediately after that
// same edge. The scoring TB replays the identical stimulus and compares at the
// same cycle indices, so neither rig has to model the operand skew of spec A3 --
// the skew is already baked into the recorded outputs.
//
// SAMPLING CONVENTION, and it is the one the spec names: z_o is read
// immediately after a rising edge. probe_corners_tb's first cut read one edge
// early and returned z=0 for every corner case while the flags varied
// correctly; that is what a half-cycle error looks like here.

`ifndef HH
 `define HH 8
`endif
`define VH `HH
`define VW 8

`include "fp16_gemm_array_vec.svh"

module capture_vectors_tb;

  localparam int unsigned H = `VH;
  localparam int unsigned W = `VW;
  localparam int unsigned NCYC = 3400;

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

  fp16_gemm_array #(.HEIGHT(H), .WIDTH(W)) u_ref (
    .clk_i(clk), .rst_ni(rst_n), .x_i(x), .w_i(wt), .y_i(y), .z_o(z),
    .rnd_i(rnd), .accumulate_i(accumulate), .row_clk_gate_en_i(row_gate),
    .reg_enable_i(reg_enable), .flush_i(flush), .status_o(status)
  );

  // Corner values the range clauses (A5-A9) are written about. Injected by
  // schedule rather than left to chance: uniform draws essentially never
  // produce inf*0, and a vector set that never exercises A9 cannot discriminate
  // a DUT that gets it wrong.
  localparam int unsigned NCORNER = 10;
  logic [15:0] corner [0:NCORNER-1];
  initial begin
    corner[0] = 16'h7BFF; // +max finite
    corner[1] = 16'hFBFF; // -max finite
    corner[2] = 16'h0001; // +min subnormal
    corner[3] = 16'h8001; // -min subnormal
    corner[4] = 16'h0400; // +min normal
    corner[5] = 16'h0000; // +0
    corner[6] = 16'h8000; // -0
    corner[7] = 16'h7C00; // +inf
    corner[8] = 16'hFC00; // -inf
    corner[9] = 16'h7E00; // qNaN
  end

  rec_t                  rec;
  logic [REC_W-1:0]      recs [0:NCYC-1];
  int unsigned           s;
  int                    fd, n;
  string                 fname;

  function automatic int unsigned band_for(input int unsigned c);
    // Most of the run sits in band 0 so chains accumulate without saturating;
    // the tails drive the underflow, overflow and subnormal clauses.
    if (c % 17 == 0) return 1;
    if (c % 23 == 0) return 2;
    if (c % 41 == 0) return 3;
    return 0;
  endfunction

  initial begin
    if (!$value$plusargs("out=%s", fname)) fname = "vectors.hex";

    s = 32'h1234_5678;
    rnd = 3'd0; accumulate = 1'b0; flush = 1'b0; reg_enable = 1'b1; row_gate = '1;
    for (int r = 0; r < W; r++) begin
      y[r] = 16'h3C00;
      for (int k = 0; k < H; k++) x[r][k] = 16'h3C00;
    end
    for (int k = 0; k < H; k++) wt[k] = 16'h3C00;

    repeat (4) @(posedge clk);
    rst_n = 1'b1;
    @(posedge clk);

    for (n = 0; n < NCYC; n++) begin
      // ---- stimulus for cycle n ----
      for (int r = 0; r < W; r++) begin
        for (int k = 0; k < H; k++) begin
          s = xs32(s);
          x[r][k] = fp16_draw(s, band_for(n + r + k));
        end
        s = xs32(s);
        y[r] = fp16_draw(s, band_for(n + r));
      end
      for (int k = 0; k < H; k++) begin
        s = xs32(s);
        wt[k] = fp16_draw(s, band_for(n + k));
      end

      // Directed corner injection: from cycle 400 on, every 7th cycle plants a
      // corner pair at a walking (row, stage) position so every stage index and
      // every corner value is reached.
      if (n >= 400 && n < 3000 && (n % 7 == 0)) begin
        automatic int ci = (n / 7) % NCORNER;
        automatic int cr = (n / 7) % W;
        automatic int ck = (n / 7) % H;
        x[cr][ck] = corner[ci];
        wt[ck]    = corner[(ci + 3) % NCORNER];
      end

      // ---- directed zero-sign phases ----
      // Random band-0 operands essentially never drive z_o to a signed zero, so
      // the first vector set delivered NO -0 at all (coverage negzero=0) while
      // still reporting 10/10 on the A5/A6 flag floors. Those floors are tallied
      // from per-stage FLAGS; the sign of a DELIVERED zero is a different
      // property and needs its own stimulus, or A6's sign-preservation rule and
      // A8's roundTowardNegative rule are unscored.
      //
      // Both phases hold the field constant for long enough that the operand
      // skew of A3 has fully settled, so what reaches z_o is unambiguous.
      if (n >= 3000) begin
        for (int r = 0; r < W; r++) begin
          y[r] = 16'h0000;                        // +0 seed
          for (int k = 0; k < H-1; k++) x[r][k] = 16'h0000;
        end
        for (int k = 0; k < H-1; k++) wt[k] = 16'h0000;   // upstream: +0*+0+addend

        if (n < 3200) begin
          // A6: last stage yields -2^-25, below the smallest subnormal, so the
          // magnitude collapses and only the SIGN of the exact result survives.
          for (int r = 0; r < W; r++) x[r][H-1] = 16'h8001;   // -2^-24
          wt[H-1] = 16'h3800;                                 // 0.5
        end else begin
          // A8: (-0)*(+1.0) + (+0) -- +0 in every mode except RDN, which gives -0.
          for (int r = 0; r < W; r++) x[r][H-1] = 16'h8000;   // -0
          wt[H-1] = 16'h3C00;                                 // +1.0
        end
      end

      // ---- control schedule ----
      // Rounding mode sweeps slowly so each mode covers a long run of operands.
      // In the directed tail each rounding mode must get a settled window of its
      // own, so the sweep is faster there and slow elsewhere.
      rnd = (n >= 3000) ? ((n / 40) % 5) : ((n / 97) % 5);

      // Stall windows: reg_enable low for a few cycles at a time.
      reg_enable = (n >= 3000) ? 1'b1 : !(((n / 11) % 13) == 0);

      // Flush pulses, kept away from the stall windows so the two are
      // separable in the record.
      // Two flush schedules, deliberately. The first is kept clear of the stall
      // windows so flush and stall are separable in the record. The second
      // fires INSIDE a stall window on purpose: C2 asserts flush outranks
      // reg_enable_i, and without this the assertion is unscored -- the first
      // schedule alone left coverage flush+stalled at 0 while every other
      // control floor read as met.
      //   reg_enable is low when (n/11)%13 == 0, so n = 430,431 (n/11 = 39) sits
      //   inside a stall window, with every row clock still enabled.
      flush = (n < 3000) && ( (((n % 401) inside {200, 201}) && reg_enable)
                              || (n inside {430, 431}) );

      // Accumulate windows exercise C3 (the partial-product feedback).
      accumulate = (n >= 1200) && (n < 1800) && (((n / 53) % 3) == 0);

      // Row gating: from cycle 2000 a walking pattern freezes a subset of rows.
      row_gate = (n < 2000 || n >= 3000) ? {W{1'b1}}
                                        : ~({{(W-1){1'b0}}, 1'b1} << ((n / 19) % W));

      @(posedge clk);
      #1;

      rec.x          = x;
      rec.w          = wt;
      rec.y          = y;
      rec.rnd        = rnd;
      rec.accumulate = accumulate;
      rec.flush      = flush;
      rec.reg_enable = reg_enable;
      rec.row_gate   = row_gate;
      rec.z          = z;
      rec.status     = status;
      recs[n]        = rec;
    end

    fd = $fopen(fname, "w");
    if (fd == 0) $fatal(1, "capture: cannot open %s", fname);
    for (n = 0; n < NCYC; n++) $fwrite(fd, "%h\n", recs[n]);
    $fclose(fd);
    $display("capture: wrote %0d records of %0d bits to %s (H=%0d W=%0d)",
             NCYC, REC_W, fname, H, W);
    $finish;
  end

endmodule
