// MUTANT -- NEVER SHIPPED, NEVER SCORED.
//
// *** BUILT AS A CONFORMANT PERTURBATION, AND IT IS NOT ONE. ***
// Written against R4's original text, which said strictly in-order retirement
// was conformant. It failed C2; the neutralised copy passed; the conflict turned
// out to be real. A hit accepted after an outstanding miss is blocked behind
// that miss under in-order retirement, and C2 requires it to be ANSWERED, not
// merely accepted. R4 has been narrowed and this artifact is a MUTANT.
//
// TARGET CLAUSE: C2 -- and it is the CLEANLY ISOLATED one. It fails C2 and
// nothing else, where m05 (blocking on miss) also trips C1. Both are kept: m05
// is the likely wrong answer a submission produces, this is the sharp
// instrument that validates C2 on its own.
//
// ORIGINAL LICENCE CLAIM, kept because the failure IS the finding: R4. "Responses may be returned in any order with respect to request
// order. Returning them strictly in order is conformant and is neither rewarded
// nor penalised." The anchor reorders -- measured, `reorderings=1` in the probe
// and again in the soak -- so nothing in the task took the in-order side. This
// does: responses are buffered and released in ACCEPTANCE order.
//
// NON-EQUIVALENCE WITNESS: the reordering counter reads > 0 for the reference
// and 0 for this, plus a bounded counterexample from the miter.
//
// This is also second-source difference D3', and it is the SAME artifact serving
// both purposes -- declared in task.yaml rather than left to be worked out.
// The packed-struct WIDTH macros are preprocessor definitions, not package
// members, so importing the package is not enough to reach them.
`include "bsg_cache_non_blocking.svh"

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

  // ---- in-order completion buffer -------------------------------------------
  // R6 guarantees at most one request per id in flight, so 16 slots and a
  // 16-deep issue-order queue can never overflow: a response can only arrive
  // for an id that is currently queued.
  localparam int unsigned NIDS = 16;

  logic                a_req_ready, a_rsp_v;
  logic [3:0]          a_rsp_id;
  logic [DATA_W-1:0]   a_rsp_data;

  logic [3:0]          order_q [NIDS];      // ids in acceptance order
  logic [4:0]          ord_head, ord_tail;
  logic [DATA_W-1:0]   slot_data [NIDS];
  logic                slot_done [NIDS];

  wire        ord_empty = (ord_head == ord_tail);
  wire [3:0]  head_id   = order_q[ord_head[3:0]];

  assign req_ready_o = a_req_ready;
  assign rsp_valid_o = ~ord_empty & slot_done[head_id];
  assign rsp_id_o    = head_id;
  assign rsp_data_o  = slot_data[head_id];

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      ord_head <= '0; ord_tail <= '0;
      for (int i = 0; i < NIDS; i++) slot_done[i] <= 1'b0;
    end
    else begin
      // accept: record acceptance order
      if (req_valid_i & req_ready_o) begin
        order_q[ord_tail[3:0]] <= req_id_i;
        ord_tail               <= ord_tail + 5'd1;
        slot_done[req_id_i]    <= 1'b0;
      end
      // anchor answered: park it, whatever order it came back in
      if (a_rsp_v) begin
        slot_data[a_rsp_id] <= a_rsp_data;
        slot_done[a_rsp_id] <= 1'b1;
      end
      // release strictly from the head
      if (rsp_valid_o & rsp_ready_i) begin
        ord_head             <= ord_head + 5'd1;
        if (!(a_rsp_v && (a_rsp_id == head_id))) slot_done[head_id] <= 1'b0;
      end
    end
  end

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
    ,.ready_o             (a_req_ready)

    ,.v_o                 (a_rsp_v)
    ,.id_o                (a_rsp_id)
    ,.data_o              (a_rsp_data)
    ,.yumi_i              (1'b1)   // always absorbed into the reorder buffer

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
