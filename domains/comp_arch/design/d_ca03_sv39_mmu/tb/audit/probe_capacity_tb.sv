// probe_capacity_tb.sv -- how many entries does each TLB actually retain?
//
// P2 pins 16 + 16 and cites the harvested config. T4 checks it behaviourally.
// The instruction side of that check failed on the reference itself with every
// replay walking, while a single page installed and hit. So the question is
// what N distinct pages actually survive, per port, and the answer is measured
// here rather than argued from the configuration file.
`timescale 1ns/1ps
`include "sv39_mmu_seq.svh"

module probe_capacity_tb;
`include "sv39_mmu_harness.svh"

  task automatic one(input logic isf, input logic [63:0] va, output int acc);
    int a0, t;
    begin
      lsu_req = 0; fetch_req = 0; repeat (2) @(posedge clk);
      a0 = acc_count;
      if (isf) begin fetch_vaddr = va; fetch_req = 1; end
      else     begin lsu_vaddr  = va; lsu_req   = 1; end
      t = 0;
      while (t < 400 && !(isf ? fetch_valid : lsu_valid)) begin @(posedge clk); #1; t++; end
      acc = acc_count - a0;
      lsu_req = 0; fetch_req = 0; @(posedge clk);
    end
  endtask

  // fill n distinct pages, replay them, report how many replays took no read
  task automatic sweep(input logic isf, input int n, output int hits);
    int a;
    begin
      flush_tlb = 1; @(posedge clk); flush_tlb = 0; repeat (200) @(posedge clk);
      for (int i = 0; i < n; i++) one(isf, SEQ_BASE + i*4096, a);
      hits = 0;
      for (int i = 0; i < n; i++) begin
        one(isf, SEQ_BASE + i*4096, a);
        if (a == 0) hits++;
      end
    end
  endtask

  // fill n pages, but re-touch each page immediately after installing it, so the
  // install is followed by a HIT. The anchor's PLRU tree advances only on
  // lu_hit & lu_access (cva6_tlb.sv:436), so this is the pattern that should
  // spread the installs across entries where a cold fill does not.
  task automatic sweep_hitfill(input logic isf, input int n, output int hits);
    int a;
    begin
      flush_tlb = 1; @(posedge clk); flush_tlb = 0; repeat (200) @(posedge clk);
      for (int i = 0; i < n; i++) begin
        one(isf, SEQ_BASE + i*4096, a);   // install
        one(isf, SEQ_BASE + i*4096, a);   // hit -> advances the tree
      end
      hits = 0;
      for (int i = 0; i < n; i++) begin
        one(isf, SEQ_BASE + i*4096, a);
        if (a == 0) hits++;
      end
    end
  endtask

  int h;
  initial begin
    plant_table();
    repeat (4) @(posedge clk); rst_n = 1; repeat (4) @(posedge clk);

    $display("resident after filling n distinct pages, then replaying all n:");
    $display("   n   FETCH hits   LDST hits");
    for (int n = 1; n <= 20; n++) begin
      int hf, hl;
      sweep(1'b1, n, hf);
      sweep(1'b0, n, hl);
      $display("  %2d      %2d           %2d", n, hf, hl);
    end

    $display("");
    $display("HIT-INTERLEAVED fill (install, then re-touch), then replay all n:");
    $display("   n   FETCH hits   LDST hits");
    for (int n = 1; n <= 20; n++) begin
      int hf, hl;
      sweep_hitfill(1'b1, n, hf);
      sweep_hitfill(1'b0, n, hl);
      $display("  %2d      %2d           %2d", n, hf, hl);
    end
    $finish;
  end
endmodule
