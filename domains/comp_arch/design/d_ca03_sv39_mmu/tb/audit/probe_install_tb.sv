// probe_install_tb.sv -- when may a requester deassert after retirement?
//
// The 16-page instruction replay issued 96 page-table reads, i.e. every replay
// missed, while probe_fetch_tb -- which held fetch_req for twelve cycles past
// retirement -- hit immediately on its second request. So whether the TLB
// install completes depends on how long the request is held AFTER valid_o.
// This measures the boundary instead of guessing it, on both ports.
`timescale 1ns/1ps
`include "sv39_mmu_seq.svh"

module probe_install_tb;
`include "sv39_mmu_harness.svh"

  // one request, dropping the request line `hold` cycles after valid_o;
  // returns the number of memory accesses the request itself took
  task automatic one(input logic isf, input logic [63:0] va, input int hold,
                     output int acc);
    int a0, t;
    begin
      lsu_req = 0; fetch_req = 0; repeat (2) @(posedge clk);
      a0 = acc_count;
      if (isf) begin fetch_vaddr = va; fetch_req = 1; end
      else     begin lsu_vaddr  = va; lsu_req   = 1; end
      t = 0;
      while (t < 400 && !(isf ? fetch_valid : lsu_valid)) begin
        @(posedge clk); #1; t++;
      end
      repeat (hold) @(posedge clk);
      acc = acc_count - a0;
      lsu_req = 0; fetch_req = 0; @(posedge clk);
    end
  endtask

  int a1, a2;
  initial begin
    plant_table();
    repeat (4) @(posedge clk); rst_n = 1; repeat (4) @(posedge clk);

    for (int h = 0; h <= 3; h++) begin
      // clear both TLBs, walk the page, then ask for it again holding 2 cycles
      flush_tlb = 1; @(posedge clk); flush_tlb = 0; repeat (200) @(posedge clk);
      one(1'b1, SEQ_BASE, h,  a1);
      one(1'b1, SEQ_BASE, 2,  a2);
      $display("FETCH hold=%0d after valid_o: first=%0d reads, refetch=%0d reads  -> %s",
               h, a1, a2, (a2 == 0) ? "INSTALLED" : "NOT installed");
    end
    $display("");
    for (int h = 0; h <= 3; h++) begin
      flush_tlb = 1; @(posedge clk); flush_tlb = 0; repeat (200) @(posedge clk);
      one(1'b0, SEQ_BASE, h,  a1);
      one(1'b0, SEQ_BASE, 2,  a2);
      $display("LDST  hold=%0d after valid_o: first=%0d reads, reload =%0d reads  -> %s",
               h, a1, a2, (a2 == 0) ? "INSTALLED" : "NOT installed");
    end
    $finish;
  end
endmodule
