// probe_walk_tb.sv -- d_ca03 STEP 0 MEASUREMENT. Not a scoring TB.
//
// Drives the FLATTENED boundary and hosts the page table here, in the
// testbench, reached through mem_*. That is the property that makes this
// contract testable: the walker's memory accesses are ports, so a directed
// Sv39 table can be planted and the delivered translation checked.
//
// PMP IS IN THE WALK PATH. With all eight entries zero no region matches and
// U-mode access is denied, which surfaces as cause 5 (load ACCESS fault) rather
// than cause 13 (load PAGE fault). That is easy to misread as a translation
// defect: the first run of this probe returned pa=0 with cause=5 and looked like
// a broken walker. Entry 0 is set NAPOT-over-everything with RWX so translation
// is measured on its own; the cause moving 5 -> 13 once it was opened is the
// evidence that both mechanisms are live and distinguishable.
module probe_walk_tb;

  logic clk = 1'b0, rst_n = 1'b0;
  always #5 clk = ~clk;

  logic        flush = 0, en_tr = 1, en_ldst = 1;
  logic        lsu_req = 0, lsu_is_store = 0, lsu_valid, lsu_dtlb_hit;
  logic [63:0] lsu_vaddr = 0;
  logic [55:0] lsu_paddr;
  logic [43:0] lsu_dtlb_ppn;
  logic        lsu_exc_valid;
  logic [63:0] lsu_exc_cause, lsu_exc_tval;
  logic        fetch_req = 0, fetch_valid, fetch_exc_valid;
  logic [63:0] fetch_vaddr = 0, fetch_exc_cause, fetch_exc_tval;
  logic [55:0] fetch_paddr;
  logic [1:0]  priv = 2'b00, ld_st_priv = 2'b00;
  logic        sum = 0, mxr = 0;
  logic [43:0] satp_ppn = 44'd1;
  logic [15:0] asid = 16'd0, asid_flush = 16'd0;
  logic        flush_tlb = 0;
  logic [63:0] vaddr_flush = 0;
  logic        itlb_miss, dtlb_miss;
  logic        mem_req, mem_tag_valid, mem_kill;
  logic [55:0] mem_addr;
  logic        mem_gnt = 0, mem_rvalid = 0;
  logic [63:0] mem_rdata = 0;
  logic [7:0][7:0]  pmpcfg;
  logic [7:0][53:0] pmpaddr;

  sv39_mmu dut (
    .clk_i(clk), .rst_ni(rst_n), .flush_i(flush),
    .enable_translation_i(en_tr), .en_ld_st_translation_i(en_ldst),
    .lsu_req_i(lsu_req), .lsu_vaddr_i(lsu_vaddr), .lsu_is_store_i(lsu_is_store),
    .lsu_valid_o(lsu_valid), .lsu_paddr_o(lsu_paddr),
    .lsu_dtlb_hit_o(lsu_dtlb_hit), .lsu_dtlb_ppn_o(lsu_dtlb_ppn),
    .lsu_exc_valid_o(lsu_exc_valid), .lsu_exc_cause_o(lsu_exc_cause),
    .lsu_exc_tval_o(lsu_exc_tval),
    .fetch_req_i(fetch_req), .fetch_vaddr_i(fetch_vaddr),
    .fetch_valid_o(fetch_valid), .fetch_paddr_o(fetch_paddr),
    .fetch_exc_valid_o(fetch_exc_valid), .fetch_exc_cause_o(fetch_exc_cause),
    .fetch_exc_tval_o(fetch_exc_tval),
    .priv_lvl_i(priv), .ld_st_priv_lvl_i(ld_st_priv), .sum_i(sum), .mxr_i(mxr),
    .satp_ppn_i(satp_ppn), .asid_i(asid),
    .flush_tlb_i(flush_tlb), .asid_to_be_flushed_i(asid_flush),
    .vaddr_to_be_flushed_i(vaddr_flush),
    .itlb_miss_o(itlb_miss), .dtlb_miss_o(dtlb_miss),
    .mem_req_o(mem_req), .mem_addr_o(mem_addr),
    .mem_tag_valid_o(mem_tag_valid), .mem_kill_o(mem_kill),
    .mem_gnt_i(mem_gnt), .mem_rvalid_i(mem_rvalid), .mem_rdata_i(mem_rdata),
    .pmpcfg_i(pmpcfg), .pmpaddr_i(pmpaddr)
  );

  // testbench-hosted physical memory, 8-byte words
  logic [63:0] mem [bit [55:0]];
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      mem_gnt <= 1'b0; mem_rvalid <= 1'b0; mem_rdata <= '0;
    end else begin
      mem_gnt    <= mem_req;
      mem_rvalid <= mem_gnt;
      if (mem_gnt)
        mem_rdata <= mem.exists({mem_addr[55:3], 3'd0}) ? mem[{mem_addr[55:3], 3'd0}] : 64'd0;
    end
  end

  function automatic logic [63:0] pte(input logic [43:0] ppn,
                                      input bit v, r, w, x, u, a, d);
    return {10'd0, ppn, 2'd0, d, a, 1'b0, u, x, w, r, v};
  endfunction

  int fails = 0;

  task automatic walk(input string tag, input logic [63:0] va,
                      input logic [55:0] want_pa, input int want_cause);
    int t;
    begin
      lsu_vaddr = va; lsu_req = 1'b1; t = 0;
      while (t < 300 && !lsu_valid && !lsu_exc_valid) begin @(posedge clk); #1; t++; end
      if (want_cause >= 0) begin
        if (!lsu_exc_valid || lsu_exc_cause != want_cause) fails++;
        $display("  %-26s va=%016x -> exc=%0b cause=%0d (want %0d)  %s",
                 tag, va, lsu_exc_valid, lsu_exc_cause, want_cause,
                 (lsu_exc_valid && lsu_exc_cause == want_cause) ? "MATCH" : "*** MISMATCH ***");
      end else begin
        if (!lsu_valid || lsu_paddr != want_pa) fails++;
        $display("  %-26s va=%016x -> pa=%014x hit=%0b in %0d cyc  %s",
                 tag, va, lsu_paddr, lsu_dtlb_hit, t,
                 (lsu_valid && lsu_paddr == want_pa) ? "MATCH" : "*** MISMATCH ***");
      end
      lsu_req = 1'b0; repeat (4) @(posedge clk);
    end
  endtask

  initial begin
    pmpcfg = '0; pmpaddr = '0;
    pmpcfg[0] = 8'b0_00_11_111;   // {locked,resv[1:0],mode=NAPOT,x,w,r}
    pmpaddr[0] = '1;

    // Sv39, satp_ppn=1 -> root table at 0x1000.
    // va 0x8000_0000: VPN2=2, VPN1=0, VPN0=0
    mem[64'h1000 + 2*8] = pte(44'h2, 1,0,0,0,0,1,0);  // -> table @0x2000
    mem[64'h2000 + 0*8] = pte(44'h3, 1,0,0,0,0,1,0);  // -> table @0x3000
    mem[64'h3000 + 0*8] = pte(44'h5, 1,1,1,1,1,1,1);  // leaf, PPN 5, U rwx
    // va 0xC000_0000: VPN2=3, PTE invalid
    mem[64'h1000 + 3*8] = pte(44'h0, 0,0,0,0,0,0,0);
    // va 0x4000_0000: VPN2=1 -> 1 GiB SUPERPAGE leaf, PPN 0x40000 (1GiB aligned)
    mem[64'h1000 + 1*8] = pte(44'h40000, 1,1,1,1,1,1,1);
    // va 0x0000_0000: VPN2=0 -> leaf WITHOUT U bit, U-mode must fault
    mem[64'h1000 + 0*8] = pte(44'h80000, 1,1,1,1,0,1,1);

    repeat (4) @(posedge clk); rst_n = 1'b1; repeat (4) @(posedge clk);
    $display("");
    $display("  d_ca03 WALK PROBE -- page table hosted in the testbench");
    walk("3-level walk, U leaf",   64'h0000_0000_8000_0000, 56'h5000,      -1);
    walk("same page, TLB hit",     64'h0000_0000_8000_0000, 56'h5000,      -1);
    walk("1 GiB superpage",        64'h0000_0000_4000_0001, 56'h40000001,  -1);
    walk("invalid PTE (V=0)",      64'h0000_0000_C000_0000, 56'h0,         13);
    walk("leaf without U, in U",   64'h0000_0000_0000_0000, 56'h0,         13);
    $display("");
    $display("  walk probe: %0d failures of 5", fails);
    $finish;
  end
endmodule
