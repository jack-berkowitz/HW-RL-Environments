// probe_fetch_tb.sv -- what does the instruction port actually do?
//
// Sequence D's phase 8 retired every fetch with cause 1 (instruction access
// fault) EXCEPT the two that followed an enable_translation_i transition, which
// translated correctly from the same page table. That is not a capacity story
// and not a PMP story -- pmpcfg[0] is NAPOT-over-everything with X=1, and the
// load/store port translates through it 118 times. So the protocol is being
// driven wrong, and this prints it cycle by cycle instead of inferring it.
`timescale 1ns/1ps
`include "sv39_mmu_seq.svh"

module probe_fetch_tb;
`include "sv39_mmu_harness.svh"

  initial begin
    plant_table();
    repeat (4) @(posedge clk); rst_n = 1; repeat (4) @(posedge clk);

    $display("en_tr=%0b priv=%0d  -- holding fetch_req at %014x", en_tr, priv, SEQ_BASE);
    fetch_vaddr = SEQ_BASE; fetch_req = 1;
    for (int c = 0; c < 24; c++) begin
      @(posedge clk); #1;
      $display("  c=%2d ivalid=%0b iexc=%0b icause=%0d ipaddr=%014x imiss=%0b mreq=%0b maddr=%014x gnt=%0b rv=%0b",
               c, fetch_valid, fetch_exc_valid, fetch_exc_cause,
               fetch_paddr, itlb_miss, mem_req, mem_addr, mem_gnt, mem_rvalid);
    end
    fetch_req = 0; repeat (4) @(posedge clk);

    $display("");
    $display("second request, same page, ITLB should now be warm");
    fetch_vaddr = SEQ_BASE; fetch_req = 1;
    for (int c = 0; c < 6; c++) begin
      @(posedge clk); #1;
      $display("  c=%2d ivalid=%0b iexc=%0b icause=%0d ipaddr=%014x imiss=%0b",
               c, fetch_valid, fetch_exc_valid, fetch_exc_cause, fetch_paddr, itlb_miss);
    end
    fetch_req = 0;
    $finish;
  end
endmodule
