// capture_vectors_tb.sv -- d_ca03 vector capture. Drives the REFERENCE over
// sequence C and records what it delivered. Never scored, never shipped.
//
// Rule 11: the expected values come from the vendored anchor, not from anything
// written here. The testbench owns the page table, so it COULD compute the
// translations itself -- and must not, because a locally written oracle is
// exactly what rule 11 excludes.
`include "sv39_mmu_seq.svh"

module capture_vectors_tb;
`include "sv39_mmu_harness.svh"

  step_t            seq  [0:NSTEP-1];
  rec_t             rec;
  logic [REC_W-1:0] recs [0:NSTEP-1];
  string            fname;
  int               fd;
  int unsigned      tot_cyc = 0, tot_acc = 0, n_hit = 0;

  initial begin
    if (!$value$plusargs("out=%s", fname)) fname = "vectors.hex";
    plant_table();
    build_sequence(seq);

    repeat (4) @(posedge clk); rst_n = 1; repeat (4) @(posedge clk);

    for (int i = 0; i < NSTEP; i++) begin
      do_step(seq[i]);
      rec.va        = seq[i].va;
      rec.is_store  = seq[i].is_store;
      rec.ev        = seq[i].ev;
      rec.valid     = saw_v;
      rec.paddr     = saw_paddr;
      rec.exc_valid = saw_e;
      rec.exc_cause = saw_cause;
      recs[i]       = rec;
      tot_cyc += last_cyc;
      tot_acc += last_acc;
      if (last_acc == 0) n_hit++;
    end

    fd = $fopen(fname, "w");
    if (fd == 0) $fatal(1, "capture: cannot open %s", fname);
    for (int i = 0; i < NSTEP; i++) $fwrite(fd, "%h\n", recs[i]);
    $fclose(fd);
    $display("capture: %0d records of %0d bits -> %s", NSTEP, REC_W, fname);
    $display("capture: reference cycles=%0d PTE reads=%0d hits=%0d (%0d%%)",
             tot_cyc, tot_acc, n_hit, (100*n_hit)/NSTEP);
    if (wr_attempts != 0) $fatal(1, "capture: the unit attempted a memory WRITE (A5)");
    $finish;
  end
endmodule
