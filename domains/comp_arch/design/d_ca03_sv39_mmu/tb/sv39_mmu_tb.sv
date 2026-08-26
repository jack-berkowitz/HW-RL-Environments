// sv39_mmu_tb.sv -- d_ca03 SCORING testbench.
//
// Replays sequence C against the submitted `sv39_mmu` and compares the
// delivered translation and fault against what the reference produced for the
// same stimulus and the same page-table contents.
//
// TWO SCORED AXES, REPORTED SEPARATELY (spec L1, G2):
//   correctness  -- lsu_valid_o, lsu_paddr_o, lsu_exc_valid_o, lsu_exc_cause_o,
//                   bit-exact on every request. A gate: fail it and no PPA
//                   number is produced.
//   cycles       -- the total to retire all 118 requests. Emitted as a METRIC
//                   for the run record; NOT folded into a scalar with area,
//                   because that needs a cycle-per-square-micron exchange rate
//                   nobody can defend (rule 22).
//
// The cycle axis is what stops serialisation being free. Without it a swept
// comparator across the 16 TLB entries, a single PMP comparator, and a
// per-entry flush clear are all dominant strategies -- smaller area, no
// measured cost. Sequence C is 51% TLB hits so those choices show up here.
//
// PER-REQUEST MEMORY VISIBILITY serves both the cycle axis and T4's capacity
// check, which is why it is one capability rather than two.
`include "sv39_mmu_seq.svh"

module sv39_mmu_tb;
`include "sv39_mmu_harness.svh"

  step_t            seq  [0:NSTEP-1];
  logic [REC_W-1:0] recs [0:NSTEP-1];
  int unsigned      n_rec;
  rec_t             r;
  string            vfile;

  int unsigned errs = 0, checked = 0, reported = 0;
  bit          selftest = 1'b0;
  int unsigned tot_cyc = 0, tot_acc = 0, n_hit = 0, n_walk = 0;
  int unsigned t4_resident_reads = 0, t4_thrash_reads = 0;
  int unsigned i4_resident_reads = 0, i4_thrash_reads = 0;
  int unsigned a10_glob_reads = 0, a10_nonglob_reads = 0;
  bit          cov_hit, cov_walk, cov_super, cov_fault_page, cov_fault_store;
  bit          cov_bare, cov_flush_tlb, cov_flush_mid, cov_a_fault, cov_d_fault;
  bit          cov_fetch, cov_fetch_fault, cov_fetch_bare;
  bit          cov_acc_load, cov_acc_store, cov_acc_fetch;   // A6 causes 5, 7, 1
  bit          cov_smode, cov_sum, cov_mxr, cov_global;
  int unsigned cov_tallied = 0;
  localparam int unsigned MAX_REPORT = 12;

  // plusarg-guarded, so a normal run is unaffected
  initial if ($test$plusargs("vcd")) begin
    $dumpfile("dump.vcd");
    $dumpvars(1, sv39_mmu_tb.dut);
  end

  initial begin
    if (!$value$plusargs("vec=%s", vfile)) vfile = "vectors/vectors_sv39.hex";
    // NO LOAD CHECK EXISTED HERE AT ALL. A missing or mistyped vector file left
    // the array at zero under Verilator and the run proceeded against zeros --
    // silently testing nothing rather than failing. d_ai01 had a guard for this
    // and it could not fire; this had none. Same outcome, different route.
    //
    // d_dsp02's pattern: pre-zero, load, count non-zero, refuse on zero.
    for (int i = 0; i < NSTEP; i++) recs[i] = '0;
    $readmemh(vfile, recs);
    n_rec = 0;
    for (int i = 0; i < NSTEP; i++) if (recs[i] !== '0) n_rec = i + 1;
    if (n_rec == 0) begin
      $display("TEST_RESULT: FAIL: no vectors loaded from %s", vfile);
      $finish;
    end
    plant_table();
    snapshot_table();
    build_sequence(seq);
    cov_hit=0; cov_walk=0; cov_super=0; cov_fault_page=0; cov_fault_store=0;
    cov_bare=0; cov_flush_tlb=0; cov_flush_mid=0; cov_a_fault=0; cov_d_fault=0;
    cov_fetch=0; cov_fetch_fault=0; cov_fetch_bare=0;
    cov_acc_load=0; cov_acc_store=0; cov_acc_fetch=0;
    cov_smode=0; cov_sum=0; cov_mxr=0; cov_global=0;

    repeat (4) @(posedge clk); rst_n = 1; repeat (4) @(posedge clk);

    for (int i = 0; i < NSTEP; i++) begin
      r = rec_t'(recs[i]);
      if (r.va !== seq[i].va) begin
        $display("[FAIL] vector %0d is for va=%016x, sequence says %016x -- wrong vector file",
                 i, r.va, seq[i].va);
        errs++;
        break;
      end

      // NEGATIVE CONTROL for the A5 table check: mutate one entry mid-run and
      // the comparison must fire. Without this the check is absence-shaped and
      // unvalidated, which is how its predecessor sat dead for the whole task.
      if (i == 50 && $test$plusargs("mutate_pte")) begin
        selftest = 1'b1;
        mem[64'h3000 + 0*8] = mem[64'h3000 + 0*8] ^ 64'h1000;
        $display("SELFTEST: mutated one page table entry at step 50");
      end

      do_step(seq[i]);
      checked++;
      tot_cyc += last_cyc;
      tot_acc += last_acc;
      if (last_acc == 0) n_hit++; else n_walk++;

      // T2 as amended: paddr_o is NOT compared when exc_valid_o is asserted.
      // Its value on a fault reports WHERE the failing check was made -- the
      // walker (no address yet) or the hit path (address computed) -- and A5
      // permits either, so scoring it scored an implementation choice. valid,
      // exc_valid and cause remain compared on every request, faulting or not.
      if (saw_v !== r.valid     || saw_e !== r.exc_valid ||
          saw_cause !== r.exc_cause ||
          (!r.exc_valid && saw_paddr !== r.paddr)) begin
        errs++;
        if (reported < MAX_REPORT) begin
          reported++;
          $display("[FAIL] step %0d %s va=%016x: expected valid=%0b pa=%014x%s exc=%0b cause=%0d",
                   i, seq[i].is_fetch ? "FETCH" : "LDST ", seq[i].va,
                   r.valid, r.paddr, r.exc_valid ? " (unscored)" : "",
                   r.exc_valid, r.exc_cause);
          $display("                          got      valid=%0b pa=%014x%s exc=%0b cause=%0d",
                   saw_v, saw_paddr, r.exc_valid ? " (unscored)" : "",
                   saw_e, saw_cause);
        end
      end

      if ($test$plusargs("trace")) begin
        $display("TRACE step=%0d %s va=%016x acc=%0d cyc=%0d v=%0b e=%0b pa=%014x c=%0d",
                 i, seq[i].is_fetch ? "F" : "L", seq[i].va, last_acc, last_cyc,
                 saw_v, saw_e, saw_paddr, saw_cause);
      end

      // ---- T4: the pinned entry counts, checked behaviourally ----
      if (i >= T4_REPLAY_LO && i <= T4_REPLAY_HI) t4_resident_reads += last_acc;
      if (i >= T4_R17_LO    && i <= T4_R17_HI)    t4_thrash_reads   += last_acc;
      if (i >= I4_REPLAY_LO && i <= I4_REPLAY_HI) i4_resident_reads += last_acc;
      if (i >= I4_R17_LO    && i <= I4_R17_HI)    i4_thrash_reads   += last_acc;
      if (i == A10_GLOB_HIT)                     a10_glob_reads    += last_acc;
      if (i == A10_NONGLOB_MISS)                 a10_nonglob_reads += last_acc;

      // ---- coverage, tallied from the RECORDED reference so a broken
      // ---- submission can neither inflate nor suppress it ----
      cov_tallied++;
      if (last_acc == 0) cov_hit  = 1'b1;
      else               cov_walk = 1'b1;
      if (seq[i].va == SEQ_SUPER && r.valid)                cov_super       = 1'b1;
      if (seq[i].va == SEQ_INVAL && r.exc_valid)            cov_fault_page  = 1'b1;
      if (seq[i].va == SEQ_DNOD  && r.exc_valid)            cov_fault_store = 1'b1;
      if (seq[i].va == SEQ_ANOA  && r.exc_valid)            cov_a_fault     = 1'b1;
      if (seq[i].is_store && r.exc_valid)                   cov_d_fault     = 1'b1;
      // OUTCOME-DERIVED, not schedule-derived. These four were previously set
      // from seq[i].ev -- the array this testbench had just built -- so they
      // asserted that the rig contains what the rig put in it and could not be
      // false. See F75. Each now derives from what the reference actually did.
      //   bare      : delivered pa == va[55:0] with NO page-table read
      //   flush_tlb : a page that was resident had to be walked again
      //   flush_mid : the aborted request still retired, and re-walked to do it
      if (!seq[i].is_fetch && r.valid && !r.exc_valid && last_acc == 0 &&
          r.paddr === seq[i].va[55:0])                      cov_bare        = 1'b1;
      if (seq[i].ev == EV_FLUSH_TLB && last_acc > 0)        cov_flush_tlb   = 1'b1;
      if (seq[i].ev == EV_FLUSH_MID && r.valid && last_acc > 0) cov_flush_mid = 1'b1;
      if (seq[i].is_fetch && r.valid)                       cov_fetch       = 1'b1;
      if (seq[i].is_fetch && r.exc_valid)                   cov_fetch_fault = 1'b1;
      if (r.exc_valid && r.exc_cause == 64'd5)              cov_acc_load    = 1'b1;
      if (r.exc_valid && r.exc_cause == 64'd7)              cov_acc_store   = 1'b1;
      if (r.exc_valid && r.exc_cause == 64'd1)              cov_acc_fetch   = 1'b1;
      if (seq[i].priv == 2'b01 && r.valid)                  cov_smode       = 1'b1;
      if (seq[i].priv == 2'b01 && seq[i].sum && !r.exc_valid) cov_sum       = 1'b1;
      if (seq[i].mxr && !r.exc_valid)                       cov_mxr         = 1'b1;
      if (i == A10_GLOB_HIT && r.valid && !r.exc_valid)     cov_global      = 1'b1;
      if (seq[i].is_fetch && r.valid && !r.exc_valid && last_acc == 0 &&
          r.paddr === seq[i].va[55:0])                      cov_fetch_bare  = 1'b1;
    end

    // ---------------------------------------------------------------------
    // V2 -- RESET EMPTIES BOTH TLBs. A CLAUSE THAT WAS NEVER EXERCISED.
    //
    // V2 says "rst_ni asserted low empties both TLBs and returns the walker to
    // idle". Before this phase, RESET WAS ASSERTED EXACTLY ONCE, AT
    // INITIALISATION -- rst_n starts low in the harness declaration and rises at
    // the top of this task, never to fall again. So "empties both TLBs" was
    // unreachable: reset only ever happened when the TLBs were already empty,
    // and a design that ignored reset entirely was INDISTINGUISHABLE from a
    // conforming one.
    //
    // Found by answering AGENT-VERIF-A2's question, who had the identical gap on
    // v_ca03's F1 and v_ca06's phase L. Three tasks, independently written. The
    // cause looks structural rather than careless: RESET GETS WRITTEN AS
    // INITIALISATION, because that is what a testbench needs it for, and the
    // clause saying what reset does TO STATE is a different requirement that the
    // initialisation path can never reach. The two uses share a signal and
    // nothing else.
    //
    // WORSE, AND THE REASON THIS WAS INVISIBLE: the harness tracks rst_n in the
    // stimulus-variation instrument (V_RST). It varies exactly once, at time
    // zero, so the variation checker records it VARIED and the row reads clean.
    // An input that changes only during initialisation is not a varied input and
    // the tool cannot tell.
    //
    // APPENDED AFTER THE SCORED LOOP, deliberately: it drives no recorded vector
    // and changes no comparison, so vectors_sv39.hex stays valid and this is NOT
    // a stimulus boundary.
    //
    // THE ANTECEDENT IS MEASURED, NOT ASSUMED. Step 1 establishes the page is
    // TLB-RESIDENT by requiring zero page-table reads. If that fails the phase
    // measured nothing, and it says so rather than passing -- the same gate rule
    // 36 puts on every other conditional check here.
    begin : v2_reset_phase
      step_t v2_step;
      int unsigned v2_hit_reads, v2_post_reset_reads;

      v2_step = seq[A10_GLOB_HIT];        // a page the sequence already resolved

      do_step(v2_step);                   // 1. prove it is resident
      v2_hit_reads = last_acc;

      rst_n = 1'b0;                       // 2. the event V2 is about
      repeat (4) @(posedge clk);
      rst_n = 1'b1;
      repeat (4) @(posedge clk);

      do_step(v2_step);                   // 3. the same page again
      v2_post_reset_reads = last_acc;

      $display("MEASURE: V2 resident-hit reads=%0d (want 0), post-reset reads=%0d (want >0)",
               v2_hit_reads, v2_post_reset_reads);

      if (v2_hit_reads != 0) begin
        $display("[FAIL] V2 was never exercised -- the page was not TLB-resident before");
        $display("            reset (%0d reads), so emptying the TLB could not be observed.",
                 v2_hit_reads);
        errs++;
      end else if (v2_post_reset_reads == 0) begin
        $display("[FAIL] V2: the same page was answered with no page-table read AFTER");
        $display("            reset; rst_ni must empty both TLBs.");
        errs++;
      end
    end

    // ---------------------------------------------------------------- verdict
    $display("");
    // A5, behavioural half. The structural half is guaranteed by V1's port list
    // -- there is no write data and no write enable -- and is stated in the spec
    // rather than counted here. This compares the table against the snapshot
    // taken after plant_table(); +mutate_pte is its negative control.
    verify_table_unchanged();
    if (pte_mutations != 0) begin
      $display("[FAIL] A5: %0d page table entr%s changed during the run; the unit",
               pte_mutations, (pte_mutations == 1) ? "y" : "ies");
      $display("            must never write one.");
      errs++;
    end

    // T4, validated against the reference before it was allowed to gate:
    // steps 27..42 all returned 0 reads, steps 44..60 all returned 6.
    if (t4_resident_reads != 0) begin
      $display("[FAIL] T4: the 16-page replay issued %0d page-table reads; 16 entries",
               t4_resident_reads);
      $display("            must be simultaneously resident, so it must issue none.");
      errs++;
    end
    if (t4_thrash_reads == 0) begin
      $display("[FAIL] T4: the 17-page replay issued no page-table read; 17 pages");
      $display("            cannot be resident in 16 entries.");
      errs++;
    end
    // T9: the same two checks on the INSTRUCTION TLB, made possible by the
    // hit-interleaved fill in phase 9. Under a COLD fill the reference itself
    // issues 96 reads here and no assertion is possible; with the re-touch it
    // issues 0. Validated against the reference before being allowed to gate.
    if (i4_resident_reads != 0) begin
      $display("[FAIL] T9: the 16-page instruction replay issued %0d page-table",
               i4_resident_reads);
      $display("            reads; the instruction TLB's 16 entries must be resident.");
      errs++;
    end
    if (i4_thrash_reads == 0) begin
      $display("[FAIL] T9: the 17-page instruction replay issued no page-table read;");
      $display("            17 pages cannot be resident in 16 entries.");
      errs++;
    end
    // T10: ASID and global pages. mem_* activity, as a stated exception to T2,
    // because one page table serves every ASID -- a stale non-global entry
    // returns the same address, so nothing on the T1 surface can separate them.
    if (a10_glob_reads != 0) begin
      $display("[FAIL] T10: the GLOBAL page issued %0d page-table reads under a new",
               a10_glob_reads);
      $display("            ASID; a leaf with G=1 is valid for every ASID (A10).");
      errs++;
    end
    if (a10_nonglob_reads == 0) begin
      $display("[FAIL] T10: the NON-GLOBAL page issued no page-table read under a new");
      $display("            ASID; a leaf with G=0 is valid only for its own (A10).");
      errs++;
    end
    $display("MEASURE: data replay reads=%0d thrash=%0d | instr replay reads=%0d thrash=%0d",
             t4_resident_reads, t4_thrash_reads, i4_resident_reads, i4_thrash_reads);
    $display("MEASURE: A10 global-page reads=%0d (want 0) non-global reads=%0d (want >0)",
             a10_glob_reads, a10_nonglob_reads);

    if (cov_tallied == 0) begin
      $display("COVERAGE: NOT MEASURED -- no request was ever tallied.");
      $display("TEST_RESULT: FAIL: coverage never measured");
      $finish;
    end

    $display("COVERAGE over %0d requests: hit=%0b walk=%0b superpage=%0b",
             cov_tallied, cov_hit, cov_walk, cov_super);
    $display("  faults: page=%0b store=%0b A-bit=%0b D-bit=%0b",
             cov_fault_page, cov_fault_store, cov_a_fault, cov_d_fault);
    $display("  controls: bare=%0b flush_tlb=%0b flush_mid=%0b",
             cov_bare, cov_flush_tlb, cov_flush_mid);
    $display("  fetch:    translate=%0b fault=%0b bare=%0b",
             cov_fetch, cov_fetch_fault, cov_fetch_bare);
    $display("  access:   load=%0b store=%0b fetch=%0b   (A6 causes 5, 7, 1)",
             cov_acc_load, cov_acc_store, cov_acc_fetch);
    $display("  privilege: s_mode=%0b sum=%0b mxr=%0b   global_page=%0b",
             cov_smode, cov_sum, cov_mxr, cov_global);

    if (!(cov_hit && cov_walk && cov_super && cov_fault_page && cov_a_fault &&
          cov_d_fault && cov_bare && cov_flush_tlb && cov_flush_mid &&
          cov_fetch && cov_fetch_fault && cov_fetch_bare &&
          cov_acc_load && cov_acc_store && cov_acc_fetch &&
          cov_smode && cov_sum && cov_mxr && cov_global)) begin
      $display("  FLOOR FAIL: the sequence did not reach every required condition");
      errs++;
    end else
      $display("  FLOORS: OK");


    // ---------------------------------------------- stimulus variation (T10)
    // Every input the contract gives meaning to must take MORE THAN ONE value
    // during the run. An input allowed to stay constant must be named here WITH
    // ITS REASON -- silence is the failure mode this check exists to refuse, so
    // a constant that nobody declared is a failure and not a warning.
    begin
      bit vw_ok [NVAR];
      string vw_why [NVAR];
      int nfail = 0;
      for (int i = 0; i < NVAR; i++) begin vw_ok[i] = 1'b0; vw_why[i] = ""; end

      // C5 puts a satp change without an intervening flush out of scope, and the
      // task pins one root page table, so one value is the whole scored regime.
      vw_ok[V_SATP]  = 1'b1; vw_why[V_SATP]  = "C5: one root, changing it is out of scope";
      // C2 says a design may treat any flush as a full flush, which makes the two
      // narrowing inputs explicitly non-load-bearing. Constant is correct here.
      vw_ok[V_ASIDF] = 1'b1; vw_why[V_ASIDF] = "C2: narrowing inputs are not load-bearing";
      vw_ok[V_VAF]   = 1'b1; vw_why[V_VAF]   = "C2: narrowing inputs are not load-bearing";

      // NEGATIVE CONTROL FOR THIS CHECK ITSELF: declaring every input constant
      // must make it pass, or the check is stuck-fail and proves nothing. The run
      // is marked SELFTEST rather than PASS so it can never be read as a score.
      if ($test$plusargs("declare_all")) begin
        selftest = 1'b1;
        vw_ok[V_PRIV]=1; vw_ok[V_LDPRIV]=1; vw_ok[V_SUM]=1; vw_ok[V_MXR]=1;
        vw_ok[V_ASID]=1; vw_ok[V_PMPCFG]=1; vw_ok[V_PMPADDR]=1;
        vw_why[V_PRIV]="SELF-TEST ONLY"; vw_why[V_LDPRIV]="SELF-TEST ONLY";
        vw_why[V_SUM]="SELF-TEST ONLY";  vw_why[V_MXR]="SELF-TEST ONLY";
        vw_why[V_ASID]="SELF-TEST ONLY"; vw_why[V_PMPCFG]="SELF-TEST ONLY";
        vw_why[V_PMPADDR]="SELF-TEST ONLY";
      end
      $display("");
      $display("STIMULUS VARIATION over %0d contract inputs:", NVAR);
      for (int i = 0; i < NVAR; i++) begin
        if (!vw_varied[i] && !vw_ok[i]) begin
          $display("  [FAIL] %-24s held ONE value for the whole run", vw_name[i]);
          nfail++;
        end else if (!vw_varied[i]) begin
          $display("  const  %-24s declared: %s", vw_name[i], vw_why[i]);
        end
      end
      if (nfail == 0) $display("  every undeclared input varied");
      else begin
        $display("  %0d input(s) never varied and were not declared constant.", nfail);
        $display("  An input assigned every cycle at a fixed value is NOT exercised.");
        errs += nfail;
      end
    end

    $display("");
    $display("METRIC: total_cycles=%0d pte_reads=%0d tlb_hits=%0d hit_pct=%0d",
             tot_cyc, tot_acc, n_hit, (100*n_hit)/(cov_tallied==0?1:cov_tallied));
    $display("d_ca03 sv39_mmu : %0d requests checked, %0d failures", checked, errs);
    // NOT a ternary between two string literals: SystemVerilog pads the shorter
    // one with NULs to the longer one's width and the line prints as nothing.
    if (selftest)       $display("TEST_RESULT: SELFTEST -- not a score");
    else if (errs == 0) $display("TEST_RESULT: PASS");
    else                $display("TEST_RESULT: FAIL: %0d failing checks", errs);
    $finish;
  end
endmodule
