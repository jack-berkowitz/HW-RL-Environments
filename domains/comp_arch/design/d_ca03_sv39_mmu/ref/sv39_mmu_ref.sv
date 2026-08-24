// =============================================================================
// sv39_mmu_ref.sv -- THIN PORT SHIM over vendored CVA6 RTL.
// Reference for d_ca03. NEVER SHIPPED.
//
// NO BEHAVIOUR: parameter binding, rename, struct flatten and reassembly only.
//
// ANCHOR: refs/cva6/core/cva6_mmu/cva6_mmu.sv (OpenHW Group CVA6, Solderpad 0.51)
// It instantiates two cva6_tlb, a cva6_shared_tlb, a cva6_ptw and a pmp -- the
// composition IS a module here, which is what makes this boundary shimmable.
//
// BINDINGS AND WHY:
//
//   CVA6Cfg = build_config(cv64a6_imafdc_sv39_config_pkg::cva6_cfg)
//                          A PREBUILT configuration, not one assembled here.
//                          `imafdc` has no `h`, so the hypervisor extension is
//                          off at source: CVA6ConfigHExtEn = 0, "always
//                          disabled". CONFIRMED BY RUNNING, not by reading the
//                          filename -- the elaboration assertions below print
//                          and check RVH, SV and PtLevels.
//
//   HYP_EXT = 0            and every G-stage port tied off. With RVH=0 the
//                          second-stage logic is not reachable; the ports remain
//                          on the anchor and are bound rather than left dangling.
//
// STRUCT REPRODUCTION -- THE PART MOST LIKELY TO GO SILENTLY WRONG.
// cva6_mmu takes its port types as `parameter type`. The concrete types are NOT
// in any package: cva6.sv declares them as ANONYMOUS `localparam type` structs
// inside its own parameter list. A shim therefore has to reproduce them field
// for field, and a wrong or reordered field misbinds silently -- exactly the
// shape of d_dsp01's FP4 mask, which elaborated fine and was wrong (F53).
//
// So each reproduced struct is checked by $bits() at elaboration against the
// width its field list must produce. The assertion is the part that survives a
// vendored-RTL bump; copying carefully is not.
//
// MODULE NAME. This declares `sv39_mmu_ref_inner`. The pass-through carrying the
// contract name is in sv39_mmu_top.sv. The split lets the controls in controls/
// wrap the reference and perturb one thing each without a name collision.
//
// BOUNDARY IS FLATTENED. The contract carries plain vectors, not CVA6 structs.
// Publishing `dcache_req_i_t` would put the anchor's internal request record
// into the contract and make the task a transcription exercise.
// =============================================================================
module sv39_mmu_ref_inner (
  input  logic        clk_i,
  input  logic        rst_ni,
  input  logic        flush_i,

  // translation enables
  input  logic        enable_translation_i,
  input  logic        en_ld_st_translation_i,

  // ---- load/store translation request ----
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

  // ---- instruction fetch translation request ----
  input  logic        fetch_req_i,
  input  logic [63:0] fetch_vaddr_i,
  output logic        fetch_valid_o,
  output logic [55:0] fetch_paddr_o,
  output logic        fetch_exc_valid_o,
  output logic [63:0] fetch_exc_cause_o,
  output logic [63:0] fetch_exc_tval_o,

  // ---- privilege and CSR state ----
  input  logic [1:0]  priv_lvl_i,
  input  logic [1:0]  ld_st_priv_lvl_i,
  input  logic        sum_i,
  input  logic        mxr_i,
  input  logic [43:0] satp_ppn_i,
  input  logic [15:0] asid_i,

  // ---- TLB maintenance ----
  input  logic        flush_tlb_i,
  input  logic [15:0] asid_to_be_flushed_i,
  input  logic [63:0] vaddr_to_be_flushed_i,
  output logic        itlb_miss_o,
  output logic        dtlb_miss_o,

  // ---- page-table memory port, driven by the walker ----
  output logic        mem_req_o,
  output logic [55:0] mem_addr_o,
  output logic        mem_tag_valid_o,
  output logic        mem_kill_o,
  input  logic        mem_gnt_i,
  input  logic        mem_rvalid_i,
  input  logic [63:0] mem_rdata_i,

  // ---- physical memory protection ----
  input  logic [7:0][7:0]  pmpcfg_i,
  input  logic [7:0][53:0] pmpaddr_i
);

  localparam config_pkg::cva6_cfg_t Cfg =
      build_config_pkg::build_config(cva6_config_pkg::cva6_cfg);

  // ---------------------------------------------------------------------------
  // Reproduced port types. Field lists copied from cva6.sv; the $bits() checks
  // below are what make the copy trustworthy.
  // ---------------------------------------------------------------------------
  typedef struct packed {
    logic [Cfg.XLEN-1:0]  cause;
    logic [Cfg.XLEN-1:0]  tval;
    logic [Cfg.GPLEN-1:0] tval2;
    logic [31:0]          tinst;
    logic                 gva;
    logic                 valid;
    logic                 timing;
  } exception_t;

  typedef struct packed {
    logic                fetch_valid;
    logic [Cfg.PLEN-1:0] fetch_paddr;
    exception_t          fetch_exception;
  } icache_areq_t;

  typedef struct packed {
    logic                fetch_req;
    logic [Cfg.VLEN-1:0] fetch_vaddr;
  } icache_arsp_t;

  typedef struct packed {
    logic [Cfg.DCACHE_INDEX_WIDTH-1:0] address_index;
    logic [Cfg.DCACHE_TAG_WIDTH-1:0]   address_tag;
    logic [Cfg.XLEN-1:0]               data_wdata;
    logic [Cfg.DCACHE_USER_WIDTH-1:0]  data_wuser;
    logic                              data_req;
    logic                              data_we;
    logic [(Cfg.XLEN/8)-1:0]           data_be;
    logic [1:0]                        data_size;
    logic [Cfg.DcacheIdWidth-1:0]      data_id;
    logic                              kill_req;
    logic                              tag_valid;
    logic [7:0]                        cbo_op;      // cbo_t is logic [7:0], cva6.sv:174
  } dcache_req_i_t;

  typedef struct packed {
    logic                             data_gnt;
    logic                             data_rvalid;
    logic [Cfg.DcacheIdWidth-1:0]     data_rid;
    logic [Cfg.XLEN-1:0]              data_rdata;
    logic [Cfg.DCACHE_USER_WIDTH-1:0] data_ruser;
  } dcache_req_o_t;

  // ---------------------------------------------------------------------------
  // ELABORATION CHECKS. A silently-misbound configuration is the failure mode
  // this task inherits from d_dsp01; these are what catch it.
  // ---------------------------------------------------------------------------
  initial begin
    if (Cfg.RVH  != 1'b0) $fatal(1, "d_ca03 shim: hypervisor enabled (RVH=%0b), expected 0", Cfg.RVH);
    if (Cfg.XLEN != 64)   $fatal(1, "d_ca03 shim: XLEN=%0d, expected 64", Cfg.XLEN);
    if (Cfg.SV   != 39)   $fatal(1, "d_ca03 shim: SV=%0d, expected 39", Cfg.SV);
    if (Cfg.PtLevels != 3)$fatal(1, "d_ca03 shim: PtLevels=%0d, expected 3", Cfg.PtLevels);
    if (Cfg.PLEN != 56)   $fatal(1, "d_ca03 shim: PLEN=%0d, expected 56", Cfg.PLEN);
    if (Cfg.VLEN != 64)   $fatal(1, "d_ca03 shim: VLEN=%0d, expected 64", Cfg.VLEN);
    if (Cfg.ASID_WIDTH != 16) $fatal(1, "d_ca03 shim: ASID_WIDTH=%0d, expected 16", Cfg.ASID_WIDTH);
    if (Cfg.NrPMPEntries != 8) $fatal(1, "d_ca03 shim: NrPMPEntries=%0d, expected 8", Cfg.NrPMPEntries);
    // the reproduced structs must be the widths their field lists imply
    if ($bits(exception_t) != 2*Cfg.XLEN + Cfg.GPLEN + 32 + 3)
      $fatal(1, "d_ca03 shim: exception_t is %0d bits", $bits(exception_t));
    if ($bits(icache_areq_t) != 1 + Cfg.PLEN + $bits(exception_t))
      $fatal(1, "d_ca03 shim: icache_areq_t is %0d bits", $bits(icache_areq_t));
    if ($bits(dcache_req_o_t) != 2 + Cfg.DcacheIdWidth + Cfg.XLEN + Cfg.DCACHE_USER_WIDTH)
      $fatal(1, "d_ca03 shim: dcache_req_o_t is %0d bits", $bits(dcache_req_o_t));
  end

  // ---------------------------------------------------------------------------
  // Flatten in, reassemble out. Nothing here computes.
  // ---------------------------------------------------------------------------
  icache_arsp_t  areq_i;
  icache_areq_t  areq_o;
  exception_t    misaligned_ex, lsu_exc;
  dcache_req_i_t req_o;
  dcache_req_o_t req_i;

  assign areq_i.fetch_req   = fetch_req_i;
  assign areq_i.fetch_vaddr = fetch_vaddr_i[Cfg.VLEN-1:0];
  assign misaligned_ex      = '0;

  assign fetch_valid_o     = areq_o.fetch_valid;
  assign fetch_paddr_o     = areq_o.fetch_paddr;
  assign fetch_exc_valid_o = areq_o.fetch_exception.valid;
  assign fetch_exc_cause_o = areq_o.fetch_exception.cause;
  assign fetch_exc_tval_o  = areq_o.fetch_exception.tval;

  assign lsu_exc_valid_o = lsu_exc.valid;
  assign lsu_exc_cause_o = lsu_exc.cause;
  assign lsu_exc_tval_o  = lsu_exc.tval;

  // The walker's address is one registered pointer split across two fields;
  // rejoining them is a rename, not a reconstruction.
  assign mem_req_o       = req_o.data_req;
  assign mem_addr_o      = {req_o.address_tag, req_o.address_index};
  assign mem_tag_valid_o = req_o.tag_valid;
  assign mem_kill_o      = req_o.kill_req;

  assign req_i.data_gnt    = mem_gnt_i;
  assign req_i.data_rvalid = mem_rvalid_i;
  assign req_i.data_rdata  = mem_rdata_i;
  assign req_i.data_rid    = '0;
  assign req_i.data_ruser  = '0;

  riscv::pmpcfg_t [7:0] pmpcfg;
  for (genvar i = 0; i < 8; i++) begin : gen_pmpcfg
    assign pmpcfg[i] = riscv::pmpcfg_t'(pmpcfg_i[i]);
  end

  cva6_mmu #(
     .CVA6Cfg        (Cfg)
    ,.icache_areq_t  (icache_areq_t)
    ,.icache_arsp_t  (icache_arsp_t)
    ,.dcache_req_i_t (dcache_req_i_t)
    ,.dcache_req_o_t (dcache_req_o_t)
    ,.exception_t    (exception_t)
    ,.HYP_EXT        (0)
  ) u_anchor (
     .clk_i(clk_i), .rst_ni(rst_ni), .flush_i(flush_i)
    ,.enable_translation_i(enable_translation_i)
    ,.enable_g_translation_i(1'b0)
    ,.en_ld_st_translation_i(en_ld_st_translation_i)
    ,.en_ld_st_g_translation_i(1'b0)
    ,.icache_areq_i(areq_i), .icache_areq_o(areq_o)
    ,.misaligned_ex_i(misaligned_ex)
    ,.lsu_req_i(lsu_req_i), .lsu_vaddr_i(lsu_vaddr_i[Cfg.VLEN-1:0])
    ,.lsu_tinst_i(32'd0), .lsu_is_store_i(lsu_is_store_i)
    ,.csr_hs_ld_st_inst_o()
    ,.lsu_dtlb_hit_o(lsu_dtlb_hit_o), .lsu_dtlb_ppn_o(lsu_dtlb_ppn_o)
    ,.lsu_valid_o(lsu_valid_o), .lsu_paddr_o(lsu_paddr_o)
    ,.lsu_exception_o(lsu_exc)
    ,.priv_lvl_i(riscv::priv_lvl_t'(priv_lvl_i)), .v_i(1'b0)
    ,.ld_st_priv_lvl_i(riscv::priv_lvl_t'(ld_st_priv_lvl_i)), .ld_st_v_i(1'b0)
    ,.sum_i(sum_i), .vs_sum_i(1'b0), .mxr_i(mxr_i), .vmxr_i(1'b0), .mbe_i(1'b0)
    ,.hlvx_inst_i(1'b0), .hs_ld_st_inst_i(1'b0)
    ,.satp_ppn_i(satp_ppn_i), .vsatp_ppn_i('0), .hgatp_ppn_i('0)
    ,.asid_i(asid_i), .vs_asid_i('0)
    ,.asid_to_be_flushed_i(asid_to_be_flushed_i)
    ,.vmid_i('0), .vmid_to_be_flushed_i('0)
    ,.vaddr_to_be_flushed_i(vaddr_to_be_flushed_i[Cfg.VLEN-1:0])
    ,.gpaddr_to_be_flushed_i('0)
    ,.flush_tlb_i(flush_tlb_i), .flush_tlb_vvma_i(1'b0), .flush_tlb_gvma_i(1'b0)
    ,.shared_tlb_flush_busy_o()
    ,.itlb_miss_o(itlb_miss_o), .dtlb_miss_o(dtlb_miss_o)
    ,.req_port_i(req_i), .req_port_o(req_o)
    ,.pmpcfg_i(pmpcfg), .pmpaddr_i(pmpaddr_i)
  );

endmodule
