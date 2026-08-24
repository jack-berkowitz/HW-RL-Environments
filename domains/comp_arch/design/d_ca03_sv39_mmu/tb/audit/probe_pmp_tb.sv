// probe_pmp_tb.sv -- WHICH permission bit does each PMP check require?
//
// A8 says every address the walker reads is checked "and so is the final
// translated address", and never says which bit each check needs. The second
// source recorded that as gap G-3 before it was ever run and took the
// architectural reading: walker reads need R, the final address needs R for a
// load, W for a store, X for a fetch. Sequence F reached it, and the reference
// disagreed on one case -- a fetch through a region granting R+W but not X
// TRANSLATED. This measures the rest of the matrix instead of inferring it.
`timescale 1ns/1ps
`include "sv39_mmu_seq.svh"

module probe_pmp_tb;
`include "sv39_mmu_harness.svh"

  task automatic try(input string what, input logic isf, input logic st,
                     input logic [7:0] cfg, input logic [63:0] va);
    int t;
    begin
      flush_tlb = 1; @(posedge clk); flush_tlb = 0; repeat (200) @(posedge clk);
      pmpcfg = '0; pmpaddr = '0; pmpcfg[0] = cfg; pmpaddr[0] = '1;
      lsu_req = 0; fetch_req = 0; repeat (2) @(posedge clk);
      if (isf) begin fetch_vaddr = va; fetch_req = 1; end
      else     begin lsu_vaddr = va; lsu_is_store = st; lsu_req = 1; end
      t = 0;
      while (t < 400 && !(isf ? fetch_valid : lsu_valid)) begin @(posedge clk); #1; t++; end
      $display("  %-34s cfg=%08b -> valid=%0b exc=%0b cause=%0d pa=%014x", what, cfg,
               isf ? fetch_valid : lsu_valid,
               isf ? fetch_exc_valid : lsu_exc_valid,
               isf ? fetch_exc_cause : lsu_exc_cause,
               isf ? fetch_paddr : lsu_paddr);
      lsu_req = 0; fetch_req = 0; lsu_is_store = 0; @(posedge clk);
    end
  endtask

  initial begin
    plant_table();
    repeat (4) @(posedge clk); rst_n = 1; repeat (4) @(posedge clk);
    $display("cfg bits are {locked, resv[1:0], mode[1:0], X, W, R}; mode 11 = NAPOT over all");
    try("load,  R+W+X  (all granted)",  1'b0, 1'b0, 8'b0_00_11_111, SEQ_BASE);
    try("load,  W+X only, R DENIED",    1'b0, 1'b0, 8'b0_00_11_110, SEQ_BASE);
    try("store, R+X only, W DENIED",    1'b0, 1'b1, 8'b0_00_11_101, SEQ_BASE);
    try("fetch, R+W only, X DENIED",    1'b1, 1'b0, 8'b0_00_11_011, SEQ_BASE);
    try("fetch, R+W+X  (all granted)",  1'b1, 1'b0, 8'b0_00_11_111, SEQ_BASE);
    try("load,  no region at all",      1'b0, 1'b0, 8'b0_00_00_000, SEQ_BASE);

    // Every case above WALKS, and a walk's own read needs R -- so none of them
    // can separate "the walker's reads are checked" from "the final address is
    // checked too". This one does: warm the TLB with R granted, then deny R and
    // re-request. A TLB hit issues no read, so a fault here can only come from a
    // check on the FINAL ADDRESS.
    $display("");
    $display("TLB-warm isolation -- no walk, so any fault is the final address:");
    flush_tlb = 1; @(posedge clk); flush_tlb = 0; repeat (200) @(posedge clk);
    pmpcfg = '0; pmpaddr = '0; pmpcfg[0] = 8'b0_00_11_111; pmpaddr[0] = '1;
    lsu_vaddr = SEQ_BASE; lsu_req = 1;
    while (!lsu_valid) begin @(posedge clk); #1; end
    lsu_req = 0; @(posedge clk);
    begin
      int a0, t;
      pmpcfg[0] = 8'b0_00_11_110;            // R DENIED, entry still resident
      repeat (2) @(posedge clk);
      a0 = acc_count;
      lsu_vaddr = SEQ_BASE; lsu_req = 1; t = 0;
      while (t < 400 && !lsu_valid) begin @(posedge clk); #1; t++; end
      $display("  warm load, R DENIED                 reads=%0d -> valid=%0b exc=%0b cause=%0d pa=%014x",
               acc_count - a0, lsu_valid, lsu_exc_valid, lsu_exc_cause, lsu_paddr);
      lsu_req = 0; @(posedge clk);
    end
    $finish;
  end
endmodule
