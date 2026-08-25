// nc_r1_evades_antecedent -- d_ca01 NEGATIVE CONTROL for R1. Never shipped.
//
// The F86 method applied to d_ca01's R1, the second instance F86 names. R1 says:
// while a response is offered and not accepted, rsp_valid_o stays high and
// rsp_id_o/rsp_data_o do not change. This gates rsp_valid_o combinationally on
// rsp_ready_i. It does NOT violate R1's consequent -- it makes R1's ANTECEDENT
// unsatisfiable. L5 explicitly PERMITS req_ready_o to depend combinationally on
// req_valid_i and says nothing about the response side, so no clause objects.
//
// PREDICTION, before running: it does not fail R1. It fails the condition-side
// floor "R1 was never exercised", and only that. If it fails anything else, it
// perturbs more than R1 and is not the control it claims to be.

// =============================================================================
// nonblocking_dcache_ref.sv  --  THIN PORT SHIM over vendored basejump RTL
// =============================================================================
// Reference for d_ca01. Wraps `bsg_cache_non_blocking` from basejump_stl at
// refs.lock's pinned SHA. NEVER SHIPPED -- the task ships spec/ only.
//
// *** THIS FILE CONTAINS NO BEHAVIOUR. *** Everything below is one of:
//   - a parameter binding,
//   - a rename,
//   - a packed-struct pack or unpack,
//   - a reset-polarity inversion,
//   - a valid/ready to valid/yumi protocol adaptation.
// There is no state, no arithmetic, and no sequencing. If bridging had needed
// any of those the interface would have been wrong and the task would convert
// rather than have its spec reshaped to fit.
//
// WHAT IS NOT HERE, AND WHY IT MATTERS: no initialization sequencer. The
// anchor's tag memory is an SRAM with no reset, so an earlier reading of this
// task had the shim generating a TAGST sweep after reset -- which would have
// been behaviour, and would have failed the thin-shim test. Measured instead
// (NOTES.md, E3): with the tag array zeroed at power-up the anchor needs no
// initialization at all. Spec P1 makes that an environment precondition,
// ref/sim_flags_verilator.txt establishes it with --x-initial 0, and the
// testbench verifies it every run. That is what keeps this file a rename.
// =============================================================================

// The packed-struct WIDTH macros are preprocessor definitions, not package
// members, so importing the package is not enough to reach them.
`include "bsg_cache_non_blocking.svh"

module nonblocking_dcache_inner
  import bsg_cache_non_blocking_pkg::*;
#(
  parameter int unsigned DATA_W     = 32,
  parameter int unsigned SETS       = 16,
  parameter int unsigned WAYS       = 4,
  parameter int unsigned MAX_MISSES = 8
) (
  input  logic                     clk_i,
  input  logic                     rst_ni,

  input  logic                     req_valid_i,
  output logic                     req_ready_o,
  input  logic [3:0]               req_id_i,
  input  logic                     req_op_i,
  input  logic [31:0]              req_addr_i,
  input  logic [DATA_W-1:0]        req_data_i,
  input  logic [(DATA_W/8)-1:0]    req_mask_i,

  output logic                     rsp_valid_o,
  input  logic                     rsp_ready_i,
  output logic [3:0]               rsp_id_o,
  output logic [DATA_W-1:0]        rsp_data_o,

  output logic                     mem_req_valid_o,
  input  logic                     mem_req_ready_i,
  output logic                     mem_req_we_o,
  output logic [31:0]              mem_req_addr_o,

  input  logic                     mem_rd_valid_i,
  output logic                     mem_rd_ready_o,
  input  logic [DATA_W-1:0]        mem_rd_data_i,

  output logic                     mem_wr_valid_o,
  input  logic                     mem_wr_ready_i,
  output logic [DATA_W-1:0]        mem_wr_data_o
);

  localparam int unsigned ADDR_W      = 32;
  localparam int unsigned ID_W        = 4;
  localparam int unsigned BLOCK_WORDS = 4;

  // ---- parameter binding ---------------------------------------------------
  // MAX_MISSES binds the anchor's miss FIFO depth directly. Measured
  // (NOTES.md, S6): the anchor then accepts exactly MAX_MISSES+1 outstanding
  // distinct-line misses, at 2/4/8/16, so C1's floor of MAX_MISSES is cleared
  // by one. The floor is NOT set from that number.
  //
  // BLOCK_WORDS is bound here rather than exposed. Exposing it would let a
  // submission build the anchor at a block size the spec does not use and fail
  // the gate for a configuration error -- a scoring defect wearing a design
  // defect's clothes.

  // ---- opcode selection ----------------------------------------------------
  // A width-dependent constant, not a decision made at run time. The anchor's
  // LW is a 32-bit load; at DATA_W=64 the full-word load is LD. Stores use SM
  // (store-with-mask) at both widths: data_mem takes the mask straight from the
  // packet when mask_op is set (data_mem.sv:144), so size_op is not consulted.
  localparam bsg_cache_non_blocking_opcode_e LD_OP = (DATA_W == 64) ? LD : LW;

  bsg_cache_non_blocking_opcode_e op_sel;
  assign op_sel = req_op_i ? SM : LD_OP;

  // ---- request: pack the flat ports into the anchor's packed struct --------
  // Field order is the anchor's declaration order: {id, opcode, addr, data, mask}.
  localparam int unsigned PKT_W =
    `bsg_cache_non_blocking_pkt_width(ID_W, ADDR_W, DATA_W);

  logic [PKT_W-1:0] cache_pkt;
  assign cache_pkt = {req_id_i, op_sel, req_addr_i, req_data_i, req_mask_i};

  // ---- memory port: unpack the anchor's dma packet -------------------------
  localparam int unsigned DMA_PKT_W = `bsg_cache_non_blocking_dma_pkt_width(ADDR_W);
  logic [DMA_PKT_W-1:0] dma_pkt;
  assign mem_req_we_o   = dma_pkt[ADDR_W];        // {write_not_read, addr}
  assign mem_req_addr_o = dma_pkt[ADDR_W-1:0];

  // ---- valid/ready to valid/yumi -------------------------------------------
  // The anchor consumes `yumi`, which by convention may only assert when the
  // corresponding valid is high. Two of the three need no gate and one does,
  // and the difference is not stylistic:
  //
  //   rsp:     yumi_i is read ONLY through `stall = v_o & ~yumi_i`
  //            (bsg_cache_non_blocking.sv:78), so a bare ready is equivalent.
  //   mem_req: dma_pkt_yumi_i is read only in the FSM arms that also drive
  //            dma_pkt_v_o high (dma.sv:260-284), so a bare ready is equivalent.
  //   mem_wr:  dma_data_yumi_i goes straight to a bsg_two_fifo's yumi_i, and
  //            that FIFO ASSERTS on a dequeue-while-empty
  //            (bsg_two_fifo.sv:113). This one MUST be gated.
  //
  // The two ungated forms are preferred wherever they are legal because they
  // avoid a combinational path from a DUT output back to a DUT input. That
  // path is not a loop and produces no warning, and it is the shape that made
  // two builds of this task's probe disagree about whether the anchor had
  // jammed. Where the anchor's own assertion forces the gate, the gate is used
  // and the determinism check is what confirms it is harmless.
  logic dma_data_v_lo;
  assign mem_wr_valid_o = dma_data_v_lo;

  bsg_cache_non_blocking #(
     .id_width_p(ID_W)
    ,.addr_width_p(ADDR_W)
    ,.data_width_p(DATA_W)
    ,.sets_p(SETS)
    ,.ways_p(WAYS)
    ,.block_size_in_words_p(BLOCK_WORDS)
    ,.miss_fifo_els_p(MAX_MISSES)
  ) u_anchor (
     .clk_i               (clk_i)
    ,.reset_i             (~rst_ni)                    // polarity rename

    ,.v_i                 (req_valid_i)
    ,.cache_pkt_i         (cache_pkt)
    ,.ready_o             (req_ready_o)

    ,.v_o                 (rsp_valid_o)
    ,.id_o                (rsp_id_o)
    ,.data_o              (rsp_data_o)
    ,.yumi_i              (rsp_ready_i)                // ungated: see above

    ,.dma_pkt_o           (dma_pkt)
    ,.dma_pkt_v_o         (mem_req_valid_o)
    ,.dma_pkt_yumi_i      (mem_req_ready_i)            // ungated: see above

    ,.dma_data_i          (mem_rd_data_i)
    ,.dma_data_v_i        (mem_rd_valid_i)
    ,.dma_data_ready_and_o(mem_rd_ready_o)

    ,.dma_data_o          (mem_wr_data_o)
    ,.dma_data_v_o        (dma_data_v_lo)
    ,.dma_data_yumi_i     (dma_data_v_lo & mem_wr_ready_i)   // gated: FIFO asserts otherwise
  );

endmodule

module nonblocking_dcache
  import bsg_cache_non_blocking_pkg::*;
#(
  parameter int unsigned DATA_W     = 32,
  parameter int unsigned SETS       = 16,
  parameter int unsigned WAYS       = 4,
  parameter int unsigned MAX_MISSES = 8
) (
  input  logic                     clk_i,
  input  logic                     rst_ni,

  input  logic                     req_valid_i,
  output logic                     req_ready_o,
  input  logic [3:0]               req_id_i,
  input  logic                     req_op_i,
  input  logic [31:0]              req_addr_i,
  input  logic [DATA_W-1:0]        req_data_i,
  input  logic [(DATA_W/8)-1:0]    req_mask_i,

  output logic                     rsp_valid_o,
  input  logic                     rsp_ready_i,
  output logic [3:0]               rsp_id_o,
  output logic [DATA_W-1:0]        rsp_data_o,

  output logic                     mem_req_valid_o,
  input  logic                     mem_req_ready_i,
  output logic                     mem_req_we_o,
  output logic [31:0]              mem_req_addr_o,

  input  logic                     mem_rd_valid_i,
  output logic                     mem_rd_ready_o,
  input  logic [DATA_W-1:0]        mem_rd_data_i,

  output logic                     mem_wr_valid_o,
  input  logic                     mem_wr_ready_i,
  output logic [DATA_W-1:0]        mem_wr_data_o
);
  logic inner_rsp_valid;
  assign rsp_valid_o = inner_rsp_valid & rsp_ready_i;   // <-- the evasion

  nonblocking_dcache_inner #(.DATA_W(DATA_W), .SETS(SETS), .WAYS(WAYS), .MAX_MISSES(MAX_MISSES)) u_inner (
    .clk_i(clk_i),
    .rst_ni(rst_ni),
    .req_valid_i(req_valid_i),
    .req_ready_o(req_ready_o),
    .req_id_i(req_id_i),
    .req_op_i(req_op_i),
    .req_addr_i(req_addr_i),
    .req_data_i(req_data_i),
    .req_mask_i(req_mask_i),
    .rsp_valid_o(inner_rsp_valid),
    .rsp_ready_i(rsp_ready_i),
    .rsp_id_o(rsp_id_o),
    .rsp_data_o(rsp_data_o),
    .mem_req_valid_o(mem_req_valid_o),
    .mem_req_ready_i(mem_req_ready_i),
    .mem_req_we_o(mem_req_we_o),
    .mem_req_addr_o(mem_req_addr_o),
    .mem_rd_valid_i(mem_rd_valid_i),
    .mem_rd_ready_o(mem_rd_ready_o),
    .mem_rd_data_i(mem_rd_data_i),
    .mem_wr_valid_o(mem_wr_valid_o),
    .mem_wr_ready_i(mem_wr_ready_i),
    .mem_wr_data_o(mem_wr_data_o)
  );
endmodule
