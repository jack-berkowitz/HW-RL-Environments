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

// GEOMETRY IS A DEFINE HERE AND CANNOT BE A PARAMETER, which is why this task
// could not be swept by the scored runner and had ZERO SIM RECORDS (F88).
//
// `rec_t` in fp16_gemm_array_vec.svh is sized by `VH and `VW -- the recorded
// vector width IS the geometry -- so the record type must be fixed before
// elaboration. A parameter arrives too late: passing -GHEIGHT=4 leaves rec_t at
// the HEIGHT=8 width and the comparison fails on a width mismatch rather than on
// anything about the design. The two geometries are two ELABORATIONS, not two
// parameterisations, and the runner selects them with `+HH=<n>` config tokens.
//
// Tried and reverted rather than left unstated: parameterising this module and
// sweeping with -G. It compiles at HEIGHT=8 and fails at HEIGHT=4 with
// "Operator NEQCASE expects 40 bits on the LHS, but LHS's SEL generates 20" --
// status[rr] is H*5 bits and r.status[rr] is still 40. The failure is loud, but
// only because the widths happen to differ; the pairing it protects is not.
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
  // One pipeline depth, in enabled ticks: 31 at HEIGHT=8, 15 at HEIGHT=4. Three
  // clauses exclude a window of exactly this length --
  //   C2  after flush_i falls                     (whole array)
  //   C3  after accumulate_i changes either way   (whole array)
  //   C4  after row_clk_gate_en_i[r] changes      (THAT ROW ONLY)
  // All three are the same defect shape: the contract specifies steady states
  // and does not model the in-flight pipeline, so transitions are not scored.
  localparam int unsigned REFILL_W = 4*(H-1) + 3;

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
  int unsigned      n_rec;
  rec_t             r;
  string            vfile;

  // SEPARATE BUDGETS, one per failure class. They shared one, and status
  // mismatches consumed the whole of it: not a single z mismatch was printed in
  // the scored run, though four existed. A shared budget systematically hides
  // the rarer class behind the noisier one, and the rarer one is the
  // interesting one -- here it was the only real finding.
  int unsigned errs_z, errs_st, rep_z, rep_st, n, checked;
  int unsigned refill_left, acc_left, skipped;
  int unsigned gate_left [0:`VW-1];
  bit          prev_acc;
  logic [W-1:0] prev_gate;
  bit          scored, any_z, any_s;

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
    errs_z = 0; errs_st = 0; rep_z = 0; rep_st = 0; checked = 0;
    refill_left = 0; acc_left = 0; skipped = 0;
    prev_acc = 1'b0; prev_gate = {W{1'b1}};
    for (int gi = 0; gi < W; gi++) gate_left[gi] = 0;

    // THE VECTOR FILE IS DERIVED FROM THE GEOMETRY, not passed in beside it.
    // There are two sets, vectors_h4.hex and vectors_h8.hex, and they are not
    // interchangeable: each records what the reference delivered at THAT
    // HEIGHT. The default used to be a bare "vectors.hex" that does not exist,
    // with the real file supplied by hand on the command line -- so an ad-hoc
    // run could pair -DHH=8 with the h4 vectors and score the wrong comparison
    // without a word. Deriving it from HEIGHT makes that pairing unrepresentable.
    // The plusarg still overrides, for the capture rig and for deliberate
    // cross-geometry experiments.
    if (!$value$plusargs("vec=%s", vfile))
      vfile = $sformatf("vectors/vectors_h%0d.hex", H);
    // PRE-ZERO, THEN COUNT NON-ZERO. The premise of the previous guard was that
    // "$readmemh on a missing file leaves the array X", and it tested
    // recs[0] === 'x. THAT PREMISE IS FALSE UNDER VERILATOR, which is 2-state: a
    // failed load leaves ZEROS, the comparison is never true, and the guard
    // could not fire. A run with no vectors at all reported PASS -- observed,
    // with "$readmem file not found" and "TEST_RESULT: PASS" in the same output.
    //
    // The premise is what made it look correct to every reader. This is
    // d_dsp02's pattern, which is the one that is right for a 2-state simulator.
    for (int i = 0; i < NCYC; i++) recs[i] = '0;
    $readmemh(vfile, recs);
    n_rec = 0;
    for (int i = 0; i < NCYC; i++) if (recs[i] !== '0) n_rec = i + 1;
    if (n_rec == 0) begin
      $display("TEST_RESULT: FAIL: no vectors loaded from %s", vfile);
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

      // ---- C2 / C3 whole-array exclusion windows -----------------------------
      scored = 1'b1;
      if (r.flush)                 refill_left = REFILL_W;
      else if (refill_left != 0) begin
        scored = 1'b0;
        if (r.reg_enable) refill_left = refill_left - 1;
      end
      if (r.accumulate !== prev_acc) acc_left = REFILL_W;
      else if (acc_left != 0) begin
        scored = 1'b0;
        if (r.reg_enable) acc_left = acc_left - 1;
      end
      prev_acc = r.accumulate;

      // ---- C4 per-row exclusion: only the row whose gate moved -------------
      for (int gi = 0; gi < W; gi++) begin
        if (r.row_gate[gi] !== prev_gate[gi]) gate_left[gi] = REFILL_W;
        // A1: an enabled tick FOR ROW r needs reg_enable_i AND
        // row_clk_gate_en_i[r] high, and "all timing below is counted in
        // enabled ticks of the row in question, not in raw clock edges."
        // Decrementing on reg_enable alone counted this window in the WRONG
        // CLOCK: it ran down while the row was frozen, so the window expired
        // under a row still holding whatever it froze with. Measured: row 2's
        // gate fell at cycle 2622, INSIDE C2's post-flush unspecified window,
        // so it froze holding unspecified state and held it until 2641 -- and
        // cycles 2637-2640 were scored against it. Both solicited candidates
        // failed there, bit-identically, on a value this contract never pinned.
        else if (gate_left[gi] != 0 && r.reg_enable && r.row_gate[gi])
          gate_left[gi] = gate_left[gi] - 1;
      end
      prev_gate = r.row_gate;

      if (!scored) begin
        skipped++;
      end else begin
      checked++;
      any_z = 1'b0; any_s = 1'b0;
      for (int rr = 0; rr < W; rr++) begin
        if (gate_left[rr] == 0) begin          // this row is scored this cycle
          if (z[rr] !== r.z[rr]) any_z = 1'b1;
          // z_o IS specified while flush_i is high -- C2 pins it at +0 for
          // every clocked row and held for a gated one -- so it stays scored.
          // status_o is NOT: C2 pins only z_o during assertion, and its
          // unspecified window is the refill AFTER flush_i falls. Whether flush
          // clears the flags is a question this contract does not settle, and
          // two independently solicited designs both answered "yes" against a
          // reference that answers "no". Twelve of one candidate's twenty-three
          // status mismatches were flush-high cycles and nothing else.
          if (!r.flush && status[rr] !== r.status[rr]) any_s = 1'b1;
        end
      end
      if (any_z) begin
        errs_z++;
        if (rep_z < MAX_REPORT) begin
          rep_z++;
          $display("MISMATCH z   cycle %0d: expected %h got %h", n, r.z, z);
        end
      end
      if (any_s) begin
        errs_st++;
        if (rep_st < MAX_REPORT) begin
          rep_st++;
          $display("MISMATCH st  cycle %0d: expected %h got %h", n, r.status, status);
        end
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
    measure_latency();

    check_reset_clears();

    report_coverage();

    $display("");
    $display("d_ai01 H=%0d W=%0d : %0d cycles checked, %0d z mismatches, %0d status mismatches",
             H, W, checked, errs_z, errs_st);
    $display("  (%0d cycles unscored: C2 flush / C3 accumulate transition windows, %0d enabled ticks;",
             skipped, REFILL_W);
    $display("   C4 gate-transition exclusion is per row and does not remove whole cycles)");
    // TEST_RESULT, not RESULT. The runner and rule 24 both read the token
    // TEST_RESULT; this rig emitted a bare RESULT, so every scored-path run
    // returned NO_VERDICT while the run itself had passed and said so in a
    // word a human reads identically. Fourth of the four gaps that kept
    // d_ai01 off the scored path, and the one that survived the other three.
    // THE REASON IS PART OF THE VERDICT. Converting the old bare `RESULT: FAIL`
    // to TEST_RESULT left it with no reason string, so the runner reported
    // "FAIL:" with nothing after it -- a correct verdict that cannot be acted
    // on. A one-line failure with no reason is the same defect as a metric with
    // no gate: it is read, and it says nothing.
    if (errs_z == 0 && errs_st == 0 && lat_ok && floors_v2_ok) $display("TEST_RESULT: PASS");
    else if (!floors_v2_ok)
      $display("TEST_RESULT: FAIL: V2 -- reset did not clear the array, or was never exercised on a non-zero array");
    else if (!lat_ok)
      $display("TEST_RESULT: FAIL: L3 latency floor -- measured %0d ticks at HEIGHT=%0d, expected %0d (L3 D*(H-1)+3 = %0d plus one counting offset)",
               lat_meas, H, EXP_LAT, L3_LAT);
    else $display("TEST_RESULT: FAIL: %0d z mismatches, %0d status mismatches over %0d scored cycles (H=%0d)",
                  errs_z, errs_st, checked, H);
    $finish;
  end

  // ---------------------------------------------------------------------------
  // L3 LATENCY FLOOR -- the capacity evidence the scored geometry no longer has.
  //
  // WHY IT EXISTS. The scored geometry moved from HEIGHT=8 to HEIGHT=4 because
  // 8x8 does not route. That reopened a gap this task had already closed:
  // nc_g_height_blind_depth pins the chain depth to the literal 4, which is
  // CORRECT at HEIGHT=4, so it passes there and fails only at HEIGHT=8. The
  // scored geometry has no capacity-class control of its own. d_nw01 recorded
  // the same shape once already -- no capability check discriminates at
  // MAX_TRANS=2, and A PASS AT THE LOW SETTING IS NOT CAPABILITY EVIDENCE -- and
  // the scored setting here is now the low one.
  //
  // WHAT IT ASSERTS. Total latency is L3's D*(H-1)+3: 15 enabled ticks at
  // HEIGHT=4, 31 at HEIGHT=8. The value is DERIVED FROM H, so a design carrying a
  // CONSTANT latency satisfies at most one of the two legal geometries and the
  // pair catches it. The measurement is printed at both, so the derivation is
  // readable across the pair rather than asserted.
  //
  // WHAT IT DOES NOT CLOSE, stated because the honest limit matters more than the
  // floor. IT CANNOT DETECT nc_g AT HEIGHT=4 AND NOTHING CAN. At HEIGHT=4 nc_g is
  // not a wrong design -- it is a right one that happens to be inflexible, and it
  // is behaviourally identical to a conforming design at that geometry. The only
  // evidence of inflexibility is the other geometry. What this floor adds is that
  // a latency defect is now REPORTED AS A LATENCY DEFECT rather than inferred from
  // a mismatch count, which is rule 36's shape: the measurement is visible instead
  // of implied.
  //
  // VALIDATED BY FIRING IT, not by watching it pass. A floor that has only ever
  // agreed with the reference is a floor nobody has seen discriminate:
  //
  //   reference   H=4  15  expected 15  PASS      H=8  31  expected 31  PASS
  //   nc_g        H=4  15  expected 15  PASS      H=8  15  expected 31  FAIL
  //   nc_b        H=4  16  expected 15  FAIL
  //
  // nc_g's row IS the test. Its latency is 15 at BOTH heights -- the same number
  // for a geometry twice the size -- which is precisely what "constant rather
  // than derived" looks like when you measure it instead of arguing about it. And
  // it does NOT fire at H=4, where nc_g is a correct design, so the floor does not
  // manufacture a failure at the geometry it cannot speak about.
  //
  // nc_b's row is the part that is new at the scored geometry: a latency defect
  // now FIRES AT HEIGHT=4 and is reported as a latency defect rather than inferred
  // from a mismatch count. Before this floor, HEIGHT=4 carried no latency evidence
  // of its own at all.
  //
  // WHY NOT THE MIRROR CONTROL. The alternative was nc_g's mirror -- depth pinned
  // to the literal 8, failing at HEIGHT=4. It CONSTRUCTS: indexing stages 4..7 of
  // a [3:0] port resolves to X in SystemVerilog rather than erroring. That is
  // exactly the sign it is CONSTRUCTIBLE AND NOT PLAUSIBLE. No submission builds
  // for a height above the one it was given, and a control nobody would write
  // measures the checker rather than the contract.
  // THE +1 WAS OBSERVED, INVESTIGATED, EXPLAINED AND DOCUMENTED -- INCORRECTLY.
  // This comment used to read: "THE CONVENTION IS +1 AND IT IS THE RIG, NOT THE
  // DESIGN. First cut asserted L3's D*(H-1)+2 directly and the REFERENCE measured
  // one tick more at BOTH geometries -- 15 against 14 at H=4, 31 against 30 at
  // H=8. A UNIFORM offset across both is the signature of a counting convention,
  // not of a design defect."
  //
  // THE DATA WAS RIGHT AND THE INFERENCE WAS WRONG. A uniform offset across both
  // geometries is EQUALLY the signature of a spec constant that is low by one,
  // which is what it was. The discrepancy was not missed -- it was seen, probed,
  // and argued away, and the argument was written into the rig as a
  // justification. That is why it survived: a wrong reason attached to a right
  // number reads as diligence.
  //
  // Settled 2026-08-26 by measuring the impulse at EVERY stage rather than only
  // stage 0 -- d(k) = D*(H-1-k)+3 for all k, so the whole family was low by one,
  // not the rig -- and by a recirculation period fixing dfb at d(0)+1. Both
  // reproduced on a second host. spec/ now states +3 and this rig asserts it.
  //
  // THE SLOPE IS THE REAL ASSERTION and it is what "derived rather than constant"
  // means. One elaboration measures one geometry, so this floor asserts the
  // absolute value under the stated convention and the PAIR carries the slope. A
  // design with constant latency has slope 0 and fails at one of the two heights
  // necessarily.
  // L3_LAT is the CONTRACT'S NUMBER and the contract has been corrected: the
  // spec stated D*(H-1)+2 and the reference delivers D*(H-1)+3, measured two
  // ways on two hosts. The old constant failed a compliant submission that
  // delivered exactly the 14 the spec asked for.
  //
  // EXP_LAT's +1 IS NOW WHAT ITS COMMENT ALWAYS CLAIMED. The impulse is applied
  // at a NEGEDGE, so it is settled before the posedge that samples it, and the
  // counting loop begins at that same posedge -- which means the loop's origin
  // sits one edge before the sampling edge and the observed count is the depth
  // plus one. That is a counting offset, not a pipeline stage. It used to be a
  // pipeline stage wearing this label, which is why the discrepancy survived
  // review for as long as it did.
  localparam int unsigned L3_LAT  = 4*(H-1) + 3;   // the contract's number, corrected
  localparam int unsigned EXP_LAT = L3_LAT + 1;    // +1: the loop's origin precedes the sampling edge
  int unsigned lat_meas;
  bit          lat_ok;
  bit          floors_v2_ok = 1'b1;

  task automatic measure_latency();
    int unsigned t;
    begin
      lat_meas = 0;
      lat_ok   = 1'b0;
      // Quiesce: flush the chain, then hold a settled all-ones operand field so
      // z is a known constant before the impulse.
      flush = 1'b1; accumulate = 1'b0; reg_enable = 1'b1; row_gate = '1;
      for (int rr = 0; rr < W; rr++) begin
        y[rr] = 16'h0000;
        for (int k = 0; k < H; k++) x[rr][k] = 16'h3C00;   // 1.0
      end
      for (int k = 0; k < H; k++) wt[k] = 16'h0000;        // 0.0 -> chain is a delay line
      repeat (4) @(posedge clk);
      flush = 1'b0;
      repeat (EXP_LAT + 8) @(posedge clk);                  // let the flush drain

      // IMPULSE AT STAGE 0, whose delay IS the total latency D*(H-1)+3.
      //
      // APPLIED AT A NEGEDGE. The previous version assigned here immediately
      // after `repeat (...) @(posedge clk)`, i.e. AT the posedge -- the same
      // instant the DUT's flops sample -- while every other stimulus site in
      // this file drives at a negedge for exactly that reason. The race did not
      // change the measured depth, but it made which edge sampled the operand
      // ambiguous, and that ambiguity is what let a wrong explanation of the +1
      // stand.
      @(negedge clk);
      wt[0] = 16'h3C00;                                     // 1.0 at stage 0 only
      t = 0;
      for (t = 1; t <= EXP_LAT + 20; t++) begin
        @(posedge clk);
        #1;
        if (z[0] !== 16'h0000) begin
          lat_meas = t;
          break;
        end
      end
      lat_ok = (lat_meas == EXP_LAT);
      $display("METRIC: latency_ticks=%0d expected=%0d (L3 D*(H-1)+3=%0d, +1 counting offset) H=%0d ok=%s",
               lat_meas, EXP_LAT, L3_LAT, H, lat_ok ? "yes" : "NO");
      if (lat_meas == 0)
        $display("  L3 FLOOR: the impulse never emerged within %0d ticks -- not measured, not passed",
                 EXP_LAT + 20);
    end
  endtask

  // ---------------------------------------------------------------------------
  // V2 -- RESET CLEARS EVERY INTER-STAGE REGISTER. NOT INSTRUMENTED BEFORE THIS.
  //
  // V2 says "rst_ni asserted low clears every inter-stage register; z_o reads +0
  // (0x0000) and every status_o field reads 0". Reset was asserted TWICE and BOTH
  // ARE INITIALISATION -- rst_n low at the top of the run, high eight lines
  // later, never again. No check anywhere referenced reset. So a design that
  // ignored rst_ni entirely was indistinguishable from a conforming one, because
  // reset only ever happened when the array was already zero.
  //
  // THIS IS THE FOURTH INSTANCE OF THE CLASS and the SECOND CONTROLLED
  // COMPARISON. d_ca03 has flush instrumented and reset not, in one file; SO DOES
  // THIS TASK -- flush_i is driven three times inside the scored sequence with
  // cov_flush and the C2 refill window built around it, while reset had nothing.
  // Two files, same author, different domains, same split. The mechanism:
  //
  //   THE GAP APPEARS WHERE THE OPERATION DOUBLES AS THE TESTBENCH'S OWN
  //   INITIALISATION. Reset is what a testbench must do to get started, so it is
  //   written as setup and the clause about what it does to state never acquires
  //   a condition. Flush has no setup role, so its clause got one from the start.
  //
  // AND MY OWN SWEEP MISCOUNTED THIS TASK. It reported "tb reset-assertions=2"
  // and passed d_ai01 as instrumented. The two assignments are the initialisation
  // pair. The right measurement against the wrong population, which is the error
  // AGENT-VERIF-A2 had named an hour earlier and I then made.
  //
  // Appended after the scored loop: drives no recorded vector, so the vectors
  // stay valid and this is NOT a stimulus boundary.
  task automatic check_reset_clears();
    bit any_nonzero;
    begin
      // 1. ESTABLISH THE ANTECEDENT. Drive a settled non-zero field so the array
      //    holds something for reset to clear. Without this the check is vacuous
      //    in exactly the way V2 was for the life of the task.
      for (int rr = 0; rr < W; rr++) begin
        y[rr] = 16'h3C00;
        for (int k = 0; k < H; k++) x[rr][k] = 16'h3C00;
      end
      for (int k = 0; k < H; k++) wt[k] = 16'h3C00;
      rnd = 3'd0; accumulate = 1'b0; flush = 1'b0; reg_enable = 1'b1; row_gate = '1;
      repeat (EXP_LAT + 8) @(posedge clk);
      #1;
      any_nonzero = 1'b0;
      for (int rr = 0; rr < W; rr++) if (z[rr] !== 16'h0000) any_nonzero = 1'b1;

      // 2. THE EVENT V2 IS ABOUT.
      rst_n = 1'b0;
      repeat (4) @(posedge clk);
      #1;

      $display("METRIC: v2_array_nonzero_before_reset=%0b", any_nonzero);
      if (!any_nonzero) begin
        $display("  FLOOR FAIL: V2 was never exercised -- z_o was already all-zero");
        $display("              before reset, so clearing it could not be observed.");
        floors_v2_ok = 1'b0;
      end else begin
        for (int rr = 0; rr < W; rr++) begin
          if (z[rr] !== 16'h0000) begin
            $display("  FAIL V2: z_o[%0d]=%h after reset; rst_ni must clear every inter-stage register",
                     rr, z[rr]);
            floors_v2_ok = 1'b0;
          end
          for (int k = 0; k < H; k++)
            if (status[rr][k] !== 5'd0) begin
              $display("  FAIL V2: status_o[%0d][%0d]=%b after reset; every status field must read 0",
                       rr, k, status[rr][k]);
              floors_v2_ok = 1'b0;
            end
        end
      end
      rst_n = 1'b1;
      repeat (4) @(posedge clk);
    end
  endtask

  task automatic report_coverage();
    int unsigned of_hits, uf_hits, rnd_hits;
    bit floors_ok;
    begin
      floors_ok = 1'b1;

      if (cov_tallied == 0) begin
        // An unfilled record is worse than no record: say so plainly rather
        // than printing zeros that read like measured absence.
        $display("COVERAGE: NOT MEASURED -- no cycle was ever tallied.");
        $display("TEST_RESULT: FAIL: coverage floors not met -- see FLOOR FAIL lines above");
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
