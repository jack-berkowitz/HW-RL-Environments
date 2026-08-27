// probe_shift_tally_tb.sv -- d_ai01. AUDIT PROBE. Not a scoring TB. Never shipped.
//
// WHY IT EXISTS. The scoring tb caps its log at MAX_REPORT=12 per signal. A
// hypothesis read off twelve lines is a hypothesis about twelve lines, and this
// task has already been bitten once by MAX_REPORT hiding a population.
//
// THE HYPOTHESIS: a candidate whose every reported mismatch satisfies
// got[n] == expected[n+1] is running exactly ONE TICK AHEAD of the recorded
// stream, uniformly, rather than computing different values.
//
// WHAT IT MEASURES: agreement between the DUT's output at cycle n and the RECORD
// at cycle n+SH, for SH = 0, 1, 2, over EVERY cycle of the run, on z_o and
// status_o separately. A shift-invariant arithmetic difference stays low at
// every SH; a pure timing offset goes to ~100% at exactly one SH.
//
// CONTROL: SH=2 is the paired control. If the run scores high at 1 AND 2 the
// tally is not discriminating and no conclusion may be drawn from SH=1 alone.
// SH=0 is the scoring tb's own comparison and must reproduce its verdict.
//
// It compares against the RECORD, exactly as the scoring tb does -- there is no
// live reference instance in this task's harness.
//
// TWO TALLIES, AND THE SECOND IS WHY THE FIRST IS NOT ENOUGH. The RAW tally
// compares whole [W] vectors with NO exclusion windows. Its residual is
// uninterpretable: one row inside a C2/C3/C4 window fails the whole cycle, and
// the scoring tb removes thousands of ROW-SAMPLES per run. A raw residual is
// therefore consistent with perfect agreement on everything scored. The SCORED
// tally applies the same per-row windows the scoring tb applies, indexed at the
// SHIFTED cycle so the exclusion travels with the comparison, and it is the only
// one from which a residual may be read.
`ifndef HH
 `define HH 8
`endif
`define VH `HH
`define VW 8
`include "fp16_gemm_array_vec.svh"

module probe_shift_tally_tb;
  localparam int unsigned H = `VH;
  localparam int unsigned W = `VW;
  localparam int unsigned NCYC = 3400;
  localparam int unsigned MAXSH = 2;

  logic clk = 1'b0, rst_n = 1'b0;
  always #5 clk = ~clk;

  logic [W-1:0][H-1:0][15:0] x;
  logic        [H-1:0][15:0] wt;
  logic [W-1:0]       [15:0] y, z;
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
  string vfile;
  int unsigned n_rec;
  logic [W-1:0]      [15:0] dz  [0:NCYC-1];
  logic [W-1:0][H-1:0][4:0] dst [0:NCYC-1];
  rec_t r;
  int n;
  int unsigned zhit [0:MAXSH];
  int unsigned shit [0:MAXSH];
  int unsigned pairs[0:MAXSH];
  int unsigned szpair[0:MAXSH], szhit[0:MAXSH], sshit[0:MAXSH], sskip[0:MAXSH];
  bit smask [0:NCYC-1][0:`VW-1];
  localparam int unsigned REFILL_W = 4*(H-1) + 3;
  localparam int unsigned ACC_W    = 2*4*(H-1) + 7;

  initial begin
    $display("=== probe_shift_tally  H=%0d W=%0d  NCYC=%0d ===", H, W, NCYC);
    // VECTOR GUARD, in the form this task learned the hard way: Verilator is
    // 2-state, so testing recs[0] === 'x passes a run with NOTHING LOADED.
    // Zero the array, read, then COUNT NON-ZERO RECORDS.
    vfile = (H == 4) ? "vectors/vectors_h4.hex" : "vectors/vectors_h8.hex";
    for (int i = 0; i < NCYC; i++) recs[i] = '0;
    $readmemh(vfile, recs);
    n_rec = 0;
    for (int i = 0; i < NCYC; i++) if (recs[i] !== '0) n_rec = i + 1;
    $display("  vectors: %0d records from %s", n_rec, vfile);
    if (n_rec < NCYC) begin
      $display("*** FAIL: %0d of %0d records -- a tally over an empty run reports 100%% ***",
               n_rec, NCYC);
      $finish;
    end
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
      x = r.x; wt = r.w; y = r.y; rnd = r.rnd;
      accumulate = r.accumulate; flush = r.flush;
      reg_enable = r.reg_enable; row_gate = r.row_gate;
      @(posedge clk); #1;
      dz[n]  = z;
      dst[n] = status;
    end

    for (int sh = 0; sh <= MAXSH; sh++) begin
      zhit[sh] = 0; shit[sh] = 0; pairs[sh] = 0;
      for (int c = 0; c + sh < NCYC; c++) begin
        rec_t rr2;
        rr2 = rec_t'(recs[c + sh]);
        pairs[sh]++;
        if (dz[c]  === rr2.z)      zhit[sh]++;
        if (dst[c] === rr2.status) shit[sh]++;
      end
    end

    // ---- SCORED tally: per ROW-SAMPLE, windows from the record, at c+sh -----
    for (int sh = 0; sh <= MAXSH; sh++) begin
      int unsigned rl [0:`VW-1];
      int unsigned al [0:`VW-1];
      int unsigned gl [0:`VW-1];
      bit prev_acc;
      logic [W-1:0] prev_gate;
      bit c2o, c3o;
      rec_t q;
      szpair[sh] = 0; szhit[sh] = 0; sshit[sh] = 0; sskip[sh] = 0;
      for (int gi = 0; gi < W; gi++) begin rl[gi]=0; al[gi]=0; gl[gi]=0; end
      prev_acc = 1'b0; prev_gate = '1;
      for (int c = 0; c + sh < NCYC; c++) begin
        q = rec_t'(recs[c + sh]);
        for (int gi = 0; gi < W; gi++) begin
          c2o = 1'b0; c3o = 1'b0;
          if (q.flush) rl[gi] = REFILL_W;
          else if (rl[gi] != 0) begin
            c2o = 1'b1;
            if (q.reg_enable && q.row_gate[gi]) rl[gi] = rl[gi] - 1;
          end
          if (q.accumulate !== prev_acc) al[gi] = ACC_W;
          else if (al[gi] != 0) begin
            c3o = 1'b1;
            if (q.reg_enable && q.row_gate[gi]) al[gi] = al[gi] - 1;
          end
          if (q.row_gate[gi] !== prev_gate[gi]) gl[gi] = REFILL_W;
          else if (gl[gi] != 0) begin
            if (q.reg_enable && q.row_gate[gi]) gl[gi] = gl[gi] - 1;
          end
          if (c2o || c3o || gl[gi] != 0 || q.flush) sskip[sh]++;
          else begin
            szpair[sh]++;
            if (dz[c][gi]  === q.z[gi])      szhit[sh]++;
            if (dst[c][gi] === q.status[gi]) sshit[sh]++;
          end
        end
        prev_acc  = q.accumulate;
        prev_gate = q.row_gate;
      end
    end
    // ---- SCORED MASK, precomputed from the FULL record stream ---------------
    // THE LIMIT THIS CLOSES. A first version ran the window state machine over
    // recs[c+sh], so the machine's history was truncated by sh records and the
    // scored condition carried an extra `|| flush` the scoring tb does not have.
    // Both were over-conservative, so the residual could not have been an
    // under-skipping artefact -- but a window evaluated on a truncated stream can
    // misclassify at a window edge, and that was unmeasured. The mask is now
    // computed ONCE per record index from record 0 forward, using the scoring
    // tb's exact per-row condition, and then INDEXED at c+sh.
    begin
      int unsigned rl [0:`VW-1]; int unsigned al [0:`VW-1]; int unsigned gl [0:`VW-1];
      bit pa; logic [W-1:0] pg; rec_t q;
      for (int gi = 0; gi < W; gi++) begin rl[gi]=0; al[gi]=0; gl[gi]=0; end
      pa = 1'b0; pg = '1;
      for (int nn = 0; nn < NCYC; nn++) begin
        q = rec_t'(recs[nn]);
        for (int gi = 0; gi < W; gi++) begin
          bit c2o, c3o;
          c2o = 1'b0; c3o = 1'b0;
          if (q.flush) rl[gi] = REFILL_W;
          else if (rl[gi] != 0) begin
            c2o = 1'b1;
            if (q.reg_enable && q.row_gate[gi]) rl[gi] = rl[gi] - 1;
          end
          if (q.accumulate !== pa) al[gi] = ACC_W;
          else if (al[gi] != 0) begin
            c3o = 1'b1;
            if (q.reg_enable && q.row_gate[gi]) al[gi] = al[gi] - 1;
          end
          if (q.row_gate[gi] !== pg[gi]) gl[gi] = REFILL_W;
          else if (gl[gi] != 0 && q.reg_enable && q.row_gate[gi]) gl[gi] = gl[gi] - 1;
          // the scoring tb's condition, verbatim: no flush term
          smask[nn][gi] = (gl[gi] == 0) && !c2o && !c3o;
        end
        pa = q.accumulate; pg = q.row_gate;
      end
    end

    for (int sh = 0; sh <= MAXSH; sh++) begin
      rec_t q3;
      szpair[sh]=0; szhit[sh]=0; sshit[sh]=0; sskip[sh]=0;
      for (int c = 0; c + sh < NCYC; c++) begin
        q3 = rec_t'(recs[c + sh]);
        for (int gi = 0; gi < W; gi++) begin
          if (!smask[c + sh][gi]) sskip[sh]++;
          else begin
            szpair[sh]++;
            if (dz[c][gi]  === q3.z[gi])      szhit[sh]++;
            if (dst[c][gi] === q3.status[gi]) sshit[sh]++;
          end
        end
      end
    end

    // ---- CLASSIFY the SH=1 residual by the REFERENCE value's class ---------
    begin
      rec_t q2, qprev; logic [15:0] rv;
      int unsigned cls_inf, cls_sub, cls_norm, zonly, stonly, both_, shown, en0, en1;
      cls_inf=0; cls_sub=0; cls_norm=0; zonly=0; stonly=0; both_=0; shown=0; en0=0; en1=0;
      for (int c = 0; c + 1 < NCYC; c++) begin
        q2    = rec_t'(recs[c + 1]);
        qprev = rec_t'(recs[c]);
        for (int gi = 0; gi < W; gi++) begin
          if (smask[c + 1][gi]) begin
            automatic bit zbad = (dz[c][gi]  !== q2.z[gi]);
            automatic bit sbad = (dst[c][gi] !== q2.status[gi]);
            if (zbad && sbad) both_++; else if (zbad) zonly++; else if (sbad) stonly++;
            if (zbad) begin
              rv = q2.z[gi];
              if (q2.reg_enable) en1++; else en0++;
              if (rv[14:10] == 5'h1F)      cls_inf++;
              else if (rv[14:10] == 5'h00) cls_sub++;
              else                         cls_norm++;
              // Dump ONLY the free-running ones: the stall population is
              // explained and would bury the ~35 that are not.
              if (q2.reg_enable && shown < 40) begin
                $display("      FR cyc=%0d row=%0d ref=%h dut=%h  acc=%b flush=%b gate=%b  prev_en=%b",
                         c+1, gi, q2.z[gi], dz[c][gi], q2.accumulate, q2.flush,
                         q2.row_gate[gi], qprev.reg_enable);
                shown++;
              end
            end
          end
        end
      end
      $display("  --- SH=1 residual, windows from the FULL stream, tb condition verbatim ---");
      $display("      z wrong on inf/NaN (exp=1F) : %0d", cls_inf);
      $display("      z wrong on zero/subnormal   : %0d", cls_sub);
      $display("      z wrong on a NORMAL value   : %0d", cls_norm);
      $display("      z-only %0d   status-only %0d   both %0d", zonly, stonly, both_);
      $display("  --- THE SAME RESIDUAL SPLIT BY reg_enable_i AT THE COMPARED CYCLE ---");
      $display("      z wrong with reg_enable HIGH (free-running) : %0d", en1);
      $display("      z wrong with reg_enable LOW  (C1 stall)     : %0d", en0);
      $display("      %s",
        (en1 == 0) ? "ENTIRE z RESIDUAL IS INSIDE A STALL. Nothing disagrees while running."
                   : "residual is NOT confined to the stall -- a free-running difference exists");
    end
    $display("  --- SCORED row-samples only (mask from full stream, indexed at c+sh) ---");
    $display("  SH  scored   skipped     z agree            status agree");
    for (int sh = 0; sh <= MAXSH; sh++)
      $display("  %0d  %6d  %6d   %6d (%6.2f%%)   %6d (%6.2f%%)",
               sh, szpair[sh], sskip[sh],
               szhit[sh], 100.0*szhit[sh]/(szpair[sh]==0?1:szpair[sh]),
               sshit[sh], 100.0*sshit[sh]/(szpair[sh]==0?1:szpair[sh]));
    // ---- IS THE FLUSH RESPONSE SHIFTED AT ALL? -----------------------------
    // The free-running residual is entirely at flush cycles, ref=0000. flush
    // acts on the output register DIRECTLY; it does not travel the pipeline. So
    // a GLOBAL one-tick shift may be the wrong comparison at exactly that edge.
    // Test it: at every flush-high record cycle, compare the DUT UNSHIFTED.
    begin
      int unsigned fl_n, fl_sh1_ok, fl_sh0_ok;
      rec_t qf;
      fl_n=0; fl_sh1_ok=0; fl_sh0_ok=0;
      for (int c = 1; c + 1 < NCYC; c++) begin
        qf = rec_t'(recs[c]);
        if (qf.flush) begin
          for (int gi = 0; gi < W; gi++) begin
            fl_n++;
            if (dz[c][gi]     === qf.z[gi]) fl_sh0_ok++;   // unshifted
            if (dz[c-1][gi]   === qf.z[gi]) fl_sh1_ok++;   // shifted by one
          end
        end
      end
      $display("  --- FLUSH-CYCLE ALIGNMENT (all flush-high record cycles) ---");
      $display("      flush row-samples            : %0d", fl_n);
      $display("      DUT UNSHIFTED matches ref    : %0d (%6.2f%%)", fl_sh0_ok, 100.0*fl_sh0_ok/fl_n);
      $display("      DUT shifted-by-one matches   : %0d (%6.2f%%)", fl_sh1_ok, 100.0*fl_sh1_ok/fl_n);
      $display("      %s", (fl_sh0_ok > fl_sh1_ok)
        ? "FLUSH RESPONSE IS NOT SHIFTED. The global shift mismeasures this edge."
        : "flush response carries the same shift as the pipeline");
    end
    $display("--- CONTROL: SH=2 must NOT also score high, or the tally is inert ---");
    $display("    SH=1 z %.2f%%   SH=2 z %.2f%%   %s",
             100.0*zhit[1]/pairs[1], 100.0*zhit[2]/pairs[2],
             (100.0*zhit[1]/pairs[1] - 100.0*zhit[2]/pairs[2] > 50.0)
               ? "DISCRIMINATES" : "*** INERT -- no conclusion from SH=1 ***");
    $display("--- VERDICT ---");
    if (100.0*zhit[0]/pairs[0] > 99.0)
      $display("    aligned already: this candidate has no timing offset");
    else begin
      $display("    RAW SH=1 is the best alignment; the RAW residual is not readable.");
      $display("    ON SCORED ROW-SAMPLES AT SH=1:  z %.4f%%   status %.4f%%",
               100.0*szhit[1]/(szpair[1]==0?1:szpair[1]),
               100.0*sshit[1]/(szpair[1]==0?1:szpair[1]));
      if (szhit[1] == szpair[1] && sshit[1] == szpair[1])
        $display("    PURE ONE-TICK OFFSET. Nothing scored disagrees once realigned.");
      else
        $display("    RESIDUAL SURVIVES REALIGNMENT: z %0d / status %0d scored row-samples",
                 szpair[1]-szhit[1], szpair[1]-sshit[1]);
    end
    $finish;
  end
endmodule
