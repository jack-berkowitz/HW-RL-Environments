// Hit/walk mix of the candidate scoring sequence. A request that issues no
// page-table read was served from a TLB; one that issues reads was walked.
// mem_gnt pulses are counted, so each PTE read is one access.
module probe_mix_tb;
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
  logic [15:0] asid = 0, asid_flush = 0;
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

  logic [63:0] mem [bit [55:0]];
  int acc_count = 0;
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin mem_gnt <= 0; mem_rvalid <= 0; mem_rdata <= '0; end
    else begin
      mem_gnt    <= mem_req;
      mem_rvalid <= mem_gnt;
      if (mem_gnt) begin
        acc_count <= acc_count + 1;
        mem_rdata <= mem.exists({mem_addr[55:3],3'd0}) ? mem[{mem_addr[55:3],3'd0}] : 64'd0;
      end
    end
  end

  function automatic logic [63:0] pte(input logic [43:0] ppn,
                                      input bit v,r,w,x,u,a,d);
    return {10'd0, ppn, 2'd0, d, a, 1'b0, u, x, w, r, v};
  endfunction

  int n_req, n_hit, n_walk, n_acc, n_cyc;

  task automatic req(input logic [63:0] va);
    int t, a0;
    begin
      lsu_req = 0; repeat (2) @(posedge clk);
      a0 = acc_count; lsu_vaddr = va; lsu_req = 1; t = 0;
      while (t < 400 && !lsu_valid && !lsu_exc_valid) begin @(posedge clk); #1; t++; end
      n_req++; n_cyc += t; n_acc += (acc_count - a0);
      if (acc_count == a0) n_hit++; else n_walk++;
      lsu_req = 0; @(posedge clk);
    end
  endtask

  task automatic reset_counts(); begin n_req=0; n_hit=0; n_walk=0; n_acc=0; n_cyc=0; end endtask
  task automatic report_mix(input string tag);
    begin
      $display("  %-34s requests=%0d  hits=%0d (%0d%%)  walks=%0d  PTE reads=%0d  cycles=%0d",
               tag, n_req, n_hit, (100*n_hit)/(n_req==0?1:n_req), n_walk, n_acc, n_cyc);
    end
  endtask

  // 4 KiB pages at va = BASE + i*4096, all via one level-1 table
  localparam logic [63:0] BASE = 64'h0000_0000_8000_0000;
  initial begin
    pmpcfg = '0; pmpaddr = '0; pmpcfg[0] = 8'b0_00_11_111; pmpaddr[0] = '1;
    // root: VPN2=2 -> L1 table @0x2000 ; L1: VPN1=0 -> L0 table @0x3000
    mem[64'h1000 + 2*8] = pte(44'h2, 1,0,0,0,0,1,0);
    mem[64'h2000 + 0*8] = pte(44'h3, 1,0,0,0,0,1,0);
    for (int i = 0; i < 20; i++)                       // 20 distinct 4 KiB leaves
      mem[64'h3000 + i*8] = pte(44'h100 + i[43:0], 1,1,1,1,1,1,1);
    mem[64'h1000 + 3*8] = pte(44'h0, 0,0,0,0,0,0,0);   // invalid, VPN2=3
    mem[64'h1000 + 1*8] = pte(44'h40000, 1,1,1,1,1,1,1); // 1GiB superpage, VPN2=1
    mem[64'h1000 + 0*8] = pte(44'h80000, 1,1,1,1,0,1,1); // no U, VPN2=0

    repeat (4) @(posedge clk); rst_n = 1; repeat (4) @(posedge clk);
    $display("");
    $display("  d_ca03 HIT/WALK MIX OF THE CANDIDATE SCORING SEQUENCE");

    // ---- SEQUENCE A: the functional probes as they stand today ----
    reset_counts();
    req(BASE);                        // cold walk
    req(BASE);                        // same page
    req(64'h0000_0000_4000_0001);     // superpage
    req(64'h0000_0000_C000_0000);     // invalid PTE
    req(64'h0000_0000_0000_0000);     // leaf without U
    report_mix("A: functional probes only");

    // ---- SEQUENCE B: A, plus the T4 capacity replays ----
    flush_tlb = 1; @(posedge clk); flush_tlb = 0; repeat (150) @(posedge clk);
    reset_counts();
    req(BASE); req(BASE);
    req(64'h0000_0000_4000_0001);
    req(64'h0000_0000_C000_0000);
    req(64'h0000_0000_0000_0000);
    for (int i = 0; i < 16; i++) req(BASE + i*4096);   // fill 16 entries
    for (int i = 0; i < 16; i++) req(BASE + i*4096);   // replay: all must hit
    req(BASE + 16*4096);                               // 17th
    for (int i = 0; i < 17; i++) req(BASE + i*4096);   // replay 17
    report_mix("B: A + T4 capacity replays");

    // ---- SEQUENCE C: B, plus a reuse-heavy tail ----
    flush_tlb = 1; @(posedge clk); flush_tlb = 0; repeat (150) @(posedge clk);
    reset_counts();
    req(BASE); req(BASE);
    req(64'h0000_0000_4000_0001);
    req(64'h0000_0000_C000_0000);
    req(64'h0000_0000_0000_0000);
    for (int i = 0; i < 16; i++) req(BASE + i*4096);
    for (int i = 0; i < 16; i++) req(BASE + i*4096);
    req(BASE + 16*4096);
    for (int i = 0; i < 17; i++) req(BASE + i*4096);
    for (int p = 0; p < 4; p++)                        // four more passes over
      for (int i = 0; i < 16; i++) req(BASE + i*4096); // the 16 resident pages
    report_mix("C: B + 4 reuse passes");
    $finish;
  end
endmodule
