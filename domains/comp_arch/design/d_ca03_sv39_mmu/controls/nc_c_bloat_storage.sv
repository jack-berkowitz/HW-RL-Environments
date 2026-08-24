// nc_c_bloat_storage -- d_ca03 NEGATIVE CONTROL. Never shipped, never scored as a submission.
//
// Adds 4096 flip-flops that are written and read but affect nothing observable,
//
// which is what over-provisioning looks like. Delivered values and cycles are
// UNCHANGED.
// VALIDATES THE AREA AXIS: correctness must PASS, total_cycles must be
// IDENTICAL to the reference, and synthesised area must rise. If area does not
// move, the area measurement is broken and would pass a bloated design silently.
module sv39_mmu (
  input  logic        clk_i,
  input  logic        rst_ni,
  input  logic        flush_i,

  input  logic        enable_translation_i,
  input  logic        en_ld_st_translation_i,

  input  logic        lsu_req_i,
  input  logic [63:0] lsu_vaddr_i,
  input  logic        lsu_is_store_i,
  output logic        lsu_valid_o,
  output logic [55:0] lsu_paddr_o,
  output logic        lsu_dtlb_hit_o,
  output logic [43:0] lsu_dtlb_ppn_o,
  output logic        lsu_exc_valid_o,
  output logic [63:0] lsu_exc_cause_o,
  output logic [63:0] lsu_exc_tval_o,

  input  logic        fetch_req_i,
  input  logic [63:0] fetch_vaddr_i,
  output logic        fetch_valid_o,
  output logic [55:0] fetch_paddr_o,
  output logic        fetch_exc_valid_o,
  output logic [63:0] fetch_exc_cause_o,
  output logic [63:0] fetch_exc_tval_o,

  input  logic [1:0]  priv_lvl_i,
  input  logic [1:0]  ld_st_priv_lvl_i,
  input  logic        sum_i,
  input  logic        mxr_i,
  input  logic [43:0] satp_ppn_i,
  input  logic [15:0] asid_i,

  input  logic        flush_tlb_i,
  input  logic [15:0] asid_to_be_flushed_i,
  input  logic [63:0] vaddr_to_be_flushed_i,
  output logic        itlb_miss_o,
  output logic        dtlb_miss_o,

  output logic        mem_req_o,
  output logic [55:0] mem_addr_o,
  output logic        mem_tag_valid_o,
  output logic        mem_kill_o,
  input  logic        mem_gnt_i,
  input  logic        mem_rvalid_i,
  input  logic [63:0] mem_rdata_i,

  input  logic [7:0][7:0]  pmpcfg_i,
  input  logic [7:0][53:0] pmpaddr_i
);

  // THE STORAGE MUST REACH AN OUTPUT OR SYNTHESIS DELETES IT. The first cut of
  // this control terminated the chain in a local wire, and yosys removed all
  // 4096 flip-flops: the "bloated" build measured 190,469 um^2 against the
  // reference's 190,561 -- SMALLER. An area-axis control that gets optimised
  // away validates nothing and would let a broken area measurement pass
  // silently, which is the whole reason this control exists.
  //
  // So the chain drives lsu_dtlb_ppn_o, which spec T2 does NOT score. The
  // storage is therefore load-bearing for a real output and survives
  // synthesis, while correctness -- valid, paddr, exc_valid, exc_cause -- is
  // untouched.
  logic [4095:0] bloat_q;
  always_ff @(posedge clk_i or negedge rst_ni)
    if (!rst_ni) bloat_q <= '0;
    else         bloat_q <= {bloat_q[4094:0], ^{lsu_vaddr_i, mem_rdata_i}};
  logic [43:0] ppn_int;
  assign lsu_dtlb_ppn_o = ppn_int ^ {44{^bloat_q}};

  sv39_mmu_ref_inner u_inner (
    .clk_i(clk_i),
    .rst_ni(rst_ni),
    .flush_i(flush_i),
    .enable_translation_i(enable_translation_i),
    .en_ld_st_translation_i(en_ld_st_translation_i),
    .lsu_req_i(lsu_req_i),
    .lsu_vaddr_i(lsu_vaddr_i),
    .lsu_is_store_i(lsu_is_store_i),
    .lsu_valid_o(lsu_valid_o),
    .lsu_paddr_o(lsu_paddr_o),
    .lsu_dtlb_hit_o(lsu_dtlb_hit_o),
    .lsu_dtlb_ppn_o(ppn_int),
    .lsu_exc_valid_o(lsu_exc_valid_o),
    .lsu_exc_cause_o(lsu_exc_cause_o),
    .lsu_exc_tval_o(lsu_exc_tval_o),
    .fetch_req_i(fetch_req_i),
    .fetch_vaddr_i(fetch_vaddr_i),
    .fetch_valid_o(fetch_valid_o),
    .fetch_paddr_o(fetch_paddr_o),
    .fetch_exc_valid_o(fetch_exc_valid_o),
    .fetch_exc_cause_o(fetch_exc_cause_o),
    .fetch_exc_tval_o(fetch_exc_tval_o),
    .priv_lvl_i(priv_lvl_i),
    .ld_st_priv_lvl_i(ld_st_priv_lvl_i),
    .sum_i(sum_i),
    .mxr_i(mxr_i),
    .satp_ppn_i(satp_ppn_i),
    .asid_i(asid_i),
    .flush_tlb_i(flush_tlb_i),
    .asid_to_be_flushed_i(asid_to_be_flushed_i),
    .vaddr_to_be_flushed_i(vaddr_to_be_flushed_i),
    .itlb_miss_o(itlb_miss_o),
    .dtlb_miss_o(dtlb_miss_o),
    .mem_req_o(mem_req_o),
    .mem_addr_o(mem_addr_o),
    .mem_tag_valid_o(mem_tag_valid_o),
    .mem_kill_o(mem_kill_o),
    .mem_gnt_i(mem_gnt_i),
    .mem_rvalid_i(mem_rvalid_i),
    .mem_rdata_i(mem_rdata_i),
    .pmpcfg_i(pmpcfg_i),
    .pmpaddr_i(pmpaddr_i)
  );
endmodule
