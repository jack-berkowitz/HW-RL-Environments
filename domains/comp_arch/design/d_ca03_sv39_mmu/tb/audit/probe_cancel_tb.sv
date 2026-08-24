// Does a flush_i-cancelled request retire if lsu_req_i STAYS asserted, or must
// the requester re-issue it? C3 has to say which, and so does the scoring TB.
`include "sv39_mmu_seq.svh"
module probe_cancel_tb;
`include "sv39_mmu_harness.svh"
  int t;
  initial begin
    plant_table();
    repeat (4) @(posedge clk); rst_n = 1; repeat (4) @(posedge clk);

    // warm the entry so a re-issue would hit, making the two cases separable
    lsu_vaddr = SEQ_BASE; lsu_req = 1;
    while (!lsu_valid && !lsu_exc_valid) @(posedge clk);
    lsu_req = 0; repeat (4) @(posedge clk);
    flush_tlb = 1; @(posedge clk); flush_tlb = 0; repeat (200) @(posedge clk);

    $display("");
    $display("  d_ca03 CANCELLED-REQUEST OBLIGATION");

    // ---- case 1: hold lsu_req_i asserted across and after the flush ----
    lsu_vaddr = SEQ_BASE; lsu_req = 1;
    repeat (3) @(posedge clk);
    flush = 1; @(posedge clk); flush = 0;
    t = 0;
    while (t < 400 && !lsu_valid && !lsu_exc_valid) begin @(posedge clk); #1; t++; end
    $display("    req HELD after flush_i : retired=%0b after %0d cyc  pa=%014x",
             (lsu_valid || lsu_exc_valid), t, lsu_paddr);
    $display("      -> %s", (lsu_valid || lsu_exc_valid)
             ? "the unit re-walks on its own; holding req is sufficient"
             : "the request is DROPPED; the requester must re-issue");
    lsu_req = 0; repeat (6) @(posedge clk);

    // ---- case 2: deassert, then re-issue ----
    lsu_vaddr = SEQ_BASE; lsu_req = 1;
    t = 0;
    while (t < 400 && !lsu_valid && !lsu_exc_valid) begin @(posedge clk); #1; t++; end
    $display("    re-issued after drop   : retired=%0b after %0d cyc  pa=%014x",
             (lsu_valid || lsu_exc_valid), t, lsu_paddr);
    lsu_req = 0;
    $finish;
  end
endmodule
