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
  rec_t             r;
  string            vfile;

  int unsigned errs = 0, checked = 0, reported = 0;
  int unsigned tot_cyc = 0, tot_acc = 0, n_hit = 0, n_walk = 0;
  int unsigned t4_resident_reads = 0, t4_thrash_reads = 0;
  int unsigned i4_resident_reads = 0, i4_thrash_reads = 0;
  bit          cov_hit, cov_walk, cov_super, cov_fault_page, cov_fault_store;
  bit          cov_bare, cov_flush_tlb, cov_flush_mid, cov_a_fault, cov_d_fault;
  bit          cov_fetch, cov_fetch_fault, cov_fetch_bare;
  int unsigned cov_tallied = 0;
  localparam int unsigned MAX_REPORT = 12;

  initial begin
    if (!$value$plusargs("vec=%s", vfile)) vfile = "vectors/vectors_sv39.hex";
    $readmemh(vfile, recs);
    plant_table();
    build_sequence(seq);
    cov_hit=0; cov_walk=0; cov_super=0; cov_fault_page=0; cov_fault_store=0;
    cov_bare=0; cov_flush_tlb=0; cov_flush_mid=0; cov_a_fault=0; cov_d_fault=0;
    cov_fetch=0; cov_fetch_fault=0; cov_fetch_bare=0;

    repeat (4) @(posedge clk); rst_n = 1; repeat (4) @(posedge clk);

    for (int i = 0; i < NSTEP; i++) begin
      r = rec_t'(recs[i]);
      if (r.va !== seq[i].va) begin
        $display("[FAIL] vector %0d is for va=%016x, sequence says %016x -- wrong vector file",
                 i, r.va, seq[i].va);
        errs++;
        break;
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
      if (seq[i].ev == EV_BARE_ON)                          cov_bare        = 1'b1;
      if (seq[i].ev == EV_FLUSH_TLB)                        cov_flush_tlb   = 1'b1;
      if (seq[i].ev == EV_FLUSH_MID)                        cov_flush_mid   = 1'b1;
      if (seq[i].is_fetch && r.valid)                       cov_fetch       = 1'b1;
      if (seq[i].is_fetch && r.exc_valid)                   cov_fetch_fault = 1'b1;
      if (seq[i].is_fetch && seq[i].ev == EV_BARE_ON)        cov_fetch_bare  = 1'b1;
    end

    // ---------------------------------------------------------------- verdict
    $display("");
    if (wr_attempts != 0) begin
      $display("[FAIL] the unit attempted a page-table WRITE; A5 forbids it");
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
    // NOT an assertion on the instruction side, and T9 says why. The same
    // 16-page replay that issues zero reads on the data TLB issues 96 on the
    // instruction TLB of the reference itself -- every replay walks -- because
    // the anchor's replacement tree advances only on a lookup HIT
    // (cva6_tlb.sv:436), so a cold fill with no intervening hit installs all
    // sixteen pages into one entry. A9 leaves the replacement policy free, so
    // that policy is conforming, and a residency assertion would therefore be
    // testing the policy rather than the capacity. It is REPORTED so the
    // difference between the two ports stays visible.
    $display("MEASURE: t4 data replay reads=%0d thrash=%0d | instr replay reads=%0d thrash=%0d",
             t4_resident_reads, t4_thrash_reads, i4_resident_reads, i4_thrash_reads);

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

    if (!(cov_hit && cov_walk && cov_super && cov_fault_page && cov_a_fault &&
          cov_d_fault && cov_bare && cov_flush_tlb && cov_flush_mid &&
          cov_fetch && cov_fetch_fault && cov_fetch_bare)) begin
      $display("  FLOOR FAIL: the sequence did not reach every required condition");
      errs++;
    end else
      $display("  FLOORS: OK");

    $display("");
    $display("METRIC: total_cycles=%0d pte_reads=%0d tlb_hits=%0d hit_pct=%0d",
             tot_cyc, tot_acc, n_hit, (100*n_hit)/(cov_tallied==0?1:cov_tallied));
    $display("d_ca03 sv39_mmu : %0d requests checked, %0d failures", checked, errs);
    if (errs == 0) $display("TEST_RESULT: PASS");
    else           $display("TEST_RESULT: FAIL: %0d failing checks", errs);
    $finish;
  end
endmodule
