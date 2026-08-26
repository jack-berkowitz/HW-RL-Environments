// v_ca06 CONFORMANT PERTURBATIONS -- these MUST BE ACCEPTED.
//
// Each satisfies spec/dw_downsizer_spec.md and differs from the golden ONLY
// where the specification is silent -- on the named latitude clauses L1, L2, L5
// and the exclusion X2. A testbench that rejects any of them is relying on
// behaviour the contract does not promise, and is fitted to the anchor rather
// than to the contract.
//
// Every knob turned here is a ready the DESIGN drives, or a payload while its
// own valid is low, or a skid buffer. None of them gates a valid low once
// asserted, which would break AXI rather than exercise latitude.

// ----------------------------------------------------------------------------
// c1 -- EXTRA LATENCY, on every ready the design drives. Violates nothing:
// clause L1 leaves latency unconstrained and L2 says a ready may be low for
// reasons of internal arbitration. A testbench that requires a ready to be high
// because the unit looks idle fails this and is checking promptness the
// contract never promised.
// ----------------------------------------------------------------------------
module dwc_c1_extra_latency #(
    parameter int unsigned ADDR_W     = 32,
    parameter int unsigned ID_W       = 4,
    parameter int unsigned SLV_DATA_W = 64,   // upstream, wide
    parameter int unsigned MST_DATA_W = 16,   // downstream, narrow
    parameter int unsigned MAX_READS  = 4
) (
    input  logic clk_i,
    input  logic rst_ni,

    // ---- slave (upstream, WIDE) port ----
    input  logic [ID_W-1:0]          s_awid,
    input  logic [ADDR_W-1:0]        s_awaddr,
    input  logic [7:0]               s_awlen,
    input  logic [2:0]               s_awsize,
    input  logic [1:0]               s_awburst,
    input  logic                     s_awvalid,
    output logic                     s_awready,
    input  logic [SLV_DATA_W-1:0]    s_wdata,
    input  logic [SLV_DATA_W/8-1:0]  s_wstrb,
    input  logic                     s_wlast,
    input  logic                     s_wvalid,
    output logic                     s_wready,
    output logic [ID_W-1:0]          s_bid,
    output logic [1:0]               s_bresp,
    output logic                     s_bvalid,
    input  logic                     s_bready,
    input  logic [ID_W-1:0]          s_arid,
    input  logic [ADDR_W-1:0]        s_araddr,
    input  logic [7:0]               s_arlen,
    input  logic [2:0]               s_arsize,
    input  logic [1:0]               s_arburst,
    input  logic                     s_arvalid,
    output logic                     s_arready,
    output logic [ID_W-1:0]          s_rid,
    output logic [SLV_DATA_W-1:0]    s_rdata,
    output logic [1:0]               s_rresp,
    output logic                     s_rlast,
    output logic                     s_rvalid,
    input  logic                     s_rready,

    // ---- master (downstream, NARROW) port ----
    output logic [ID_W-1:0]          m_awid,
    output logic [ADDR_W-1:0]        m_awaddr,
    output logic [7:0]               m_awlen,
    output logic [2:0]               m_awsize,
    output logic [1:0]               m_awburst,
    output logic                     m_awvalid,
    input  logic                     m_awready,
    output logic [MST_DATA_W-1:0]    m_wdata,
    output logic [MST_DATA_W/8-1:0]  m_wstrb,
    output logic                     m_wlast,
    output logic                     m_wvalid,
    input  logic                     m_wready,
    input  logic [ID_W-1:0]          m_bid,
    input  logic [1:0]               m_bresp,
    input  logic                     m_bvalid,
    output logic                     m_bready,
    output logic [ID_W-1:0]          m_arid,
    output logic [ADDR_W-1:0]        m_araddr,
    output logic [7:0]               m_arlen,
    output logic [2:0]               m_arsize,
    output logic [1:0]               m_arburst,
    output logic                     m_arvalid,
    input  logic                     m_arready,
    input  logic [ID_W-1:0]          m_rid,
    input  logic [MST_DATA_W-1:0]    m_rdata,
    input  logic [1:0]               m_rresp,
    input  logic                     m_rlast,
    input  logic                     m_rvalid,
    output logic                     m_rready
);
  logic [3:0] tick;
  always_ff @(posedge clk_i or negedge rst_ni)
    if (!rst_ni) tick <= '0; else tick <= tick + 4'd1;
  // A MULTI-CYCLE WINDOW, not a single cycle. Gating valid and ready with a
  // one-cycle-in-N pulse can make acceptance impossible outright: if the
  // design's ready is registered rather than combinational on valid, the two
  // never coincide and nothing is ever accepted. That is not a slow design, it
  // is a broken one.
  wire slow = tick[2];                   // four cycles on, four off
  // GATED IN PAIRS. Masking only the ready is NOT a legal way to implement "this
  // design is slow": the golden asserts its ready and considers the transfer
  // done, while the master never sees it and re-offers -- so one upstream
  // request is accepted several times and A2 is violated by the PERTURBATION.
  // The valid presented to the golden and the ready presented outward carry the
  // same gate, so no cycle exists in which one side believes a transfer
  // happened and the other does not.
  //
  // AND HELD ONCE OPEN. A bare `valid & gate` is a WITHDRAWAL whenever the gate
  // falls on a cycle where the golden has an offer in hand and has not yet
  // taken it -- which is exactly what A5 forbids, and it is not a theoretical
  // worry: the anchor asserts the same property internally, and closing the
  // gate on `m_bvalid` mid-arbitration fires it --
  //     rr_arb_tree.sv:391  "it is disallowed to deassert unserved request
  //                          signals when LockIn is enabled".
  // So each gate may FALL only while nothing is pending. `hold_*` is a flop, so
  // the valid presented to the golden never depends combinationally on its
  // ready. Holding costs this perturbation none of the slowness it exists to
  // show -- it still refuses to BEGIN a transfer for the whole closed phase on
  // every intake channel. What it gives up is the right to take an offer back,
  // which no conforming design has.
  //
  // THE W CHANNEL IS NOT GATED AT ALL, and no hold could rescue it. Stalling
  // `s_wvalid` starves a downstream burst the golden has already committed to,
  // and the golden responds by withdrawing `m_wvalid` -- an A5 violation on the
  // wrapper's own master port whose author is the golden, not the wrapper.
  // Slow address intake and slow response intake demonstrate L1/L2 completely.
  //
  // THE R GATE IS THE DEEPEST STALL IN THE TASK, AND THAT IS ITS JOB.
  // Until the double drive below was repaired, `g_rready` was connected to
  // nothing and this wrapper's R channel was never throttled at all. Repairing
  // it stalled the downstream response path for the first time and immediately
  // failed the task's own D6 -- because D6 required a downstream read error to
  // PERSIST onto later upstream beats, and the reference only persists while
  // its pipeline stays full. Three idle cycles between narrow R beats is the
  // threshold: 0/1/2 persist, 3/4/8 do not, dut2 persists at every depth.
  // D6 is now ownership-only and persistence is L7, declared-open latitude.
  // This gate at four cycles is what keeps that honest -- it is the only
  // stimulus in the task that leaves the reference's fast path at all.
  logic g_awready, g_arready, g_bready, g_rready;
  logic hold_aw, hold_ar, hold_b, hold_r;
  wire  gate_aw = slow | hold_aw;
  wire  gate_ar = slow | hold_ar;
  wire  gate_b  = slow | hold_b;
  wire  gate_r  = slow | hold_r;
  always_ff @(posedge clk_i or negedge rst_ni)
    if (!rst_ni) begin
      hold_aw <= 1'b0; hold_ar <= 1'b0; hold_b <= 1'b0; hold_r <= 1'b0;
    end else begin
      hold_aw <= (s_awvalid & gate_aw) & ~g_awready;
      hold_ar <= (s_arvalid & gate_ar) & ~g_arready;
      hold_b  <= (m_bvalid  & gate_b ) & ~g_bready;
      hold_r  <= (m_rvalid  & gate_r ) & ~g_rready;
    end
  assign s_awready = g_awready & gate_aw;
  assign s_arready = g_arready & gate_ar;
  assign m_bready  = g_bready  & gate_b;
  assign m_rready  = g_rready  & gate_r;
  dw_downsizer i_g (
    .clk_i, .rst_ni,
    .s_awid, .s_awaddr, .s_awlen, .s_awsize, .s_awburst, .s_awvalid(s_awvalid & gate_aw), .s_awready(g_awready),
    .s_wdata, .s_wstrb, .s_wlast, .s_wvalid, .s_wready,
    .s_bid, .s_bresp, .s_bvalid, .s_bready,
    .s_arid, .s_araddr, .s_arlen, .s_arsize, .s_arburst, .s_arvalid(s_arvalid & gate_ar), .s_arready(g_arready),
    .s_rid, .s_rdata, .s_rresp, .s_rlast, .s_rvalid, .s_rready,
    .m_awid, .m_awaddr, .m_awlen, .m_awsize, .m_awburst, .m_awvalid, .m_awready,
    .m_wdata, .m_wstrb, .m_wlast, .m_wvalid, .m_wready,
    .m_bid, .m_bresp, .m_bvalid(m_bvalid & gate_b), .m_bready(g_bready),
    .m_arid, .m_araddr, .m_arlen, .m_arsize, .m_arburst, .m_arvalid, .m_arready,
    // `.m_rready` bare bound the GOLDEN'S OUTPUT to the wrapper's `m_rready`,
    // which the assign above already drives -- a DOUBLE DRIVE, with `g_rready`
    // connected to nothing. The R half of "extra latency" was never slow.
    .m_rid, .m_rdata, .m_rresp, .m_rlast, .m_rvalid(m_rvalid & gate_r), .m_rready(g_rready)
  );
endmodule

// ----------------------------------------------------------------------------
// c2 -- the UPSTREAM ADDRESS readys withheld to one cycle in eight, so at most
// one transaction is accepted per eight cycles. A4 makes MAX_READS an UPPER
// BOUND, not an obligation, so a design that is this slow to admit work is
// conforming. A testbench that measures throughput, or that assumes it can get
// four reads outstanding, fails this.
// ----------------------------------------------------------------------------
module dwc_c2_admission_throttled #(
    parameter int unsigned ADDR_W     = 32,
    parameter int unsigned ID_W       = 4,
    parameter int unsigned SLV_DATA_W = 64,   // upstream, wide
    parameter int unsigned MST_DATA_W = 16,   // downstream, narrow
    parameter int unsigned MAX_READS  = 4
) (
    input  logic clk_i,
    input  logic rst_ni,

    // ---- slave (upstream, WIDE) port ----
    input  logic [ID_W-1:0]          s_awid,
    input  logic [ADDR_W-1:0]        s_awaddr,
    input  logic [7:0]               s_awlen,
    input  logic [2:0]               s_awsize,
    input  logic [1:0]               s_awburst,
    input  logic                     s_awvalid,
    output logic                     s_awready,
    input  logic [SLV_DATA_W-1:0]    s_wdata,
    input  logic [SLV_DATA_W/8-1:0]  s_wstrb,
    input  logic                     s_wlast,
    input  logic                     s_wvalid,
    output logic                     s_wready,
    output logic [ID_W-1:0]          s_bid,
    output logic [1:0]               s_bresp,
    output logic                     s_bvalid,
    input  logic                     s_bready,
    input  logic [ID_W-1:0]          s_arid,
    input  logic [ADDR_W-1:0]        s_araddr,
    input  logic [7:0]               s_arlen,
    input  logic [2:0]               s_arsize,
    input  logic [1:0]               s_arburst,
    input  logic                     s_arvalid,
    output logic                     s_arready,
    output logic [ID_W-1:0]          s_rid,
    output logic [SLV_DATA_W-1:0]    s_rdata,
    output logic [1:0]               s_rresp,
    output logic                     s_rlast,
    output logic                     s_rvalid,
    input  logic                     s_rready,

    // ---- master (downstream, NARROW) port ----
    output logic [ID_W-1:0]          m_awid,
    output logic [ADDR_W-1:0]        m_awaddr,
    output logic [7:0]               m_awlen,
    output logic [2:0]               m_awsize,
    output logic [1:0]               m_awburst,
    output logic                     m_awvalid,
    input  logic                     m_awready,
    output logic [MST_DATA_W-1:0]    m_wdata,
    output logic [MST_DATA_W/8-1:0]  m_wstrb,
    output logic                     m_wlast,
    output logic                     m_wvalid,
    input  logic                     m_wready,
    input  logic [ID_W-1:0]          m_bid,
    input  logic [1:0]               m_bresp,
    input  logic                     m_bvalid,
    output logic                     m_bready,
    output logic [ID_W-1:0]          m_arid,
    output logic [ADDR_W-1:0]        m_araddr,
    output logic [7:0]               m_arlen,
    output logic [2:0]               m_arsize,
    output logic [1:0]               m_arburst,
    output logic                     m_arvalid,
    input  logic                     m_arready,
    input  logic [ID_W-1:0]          m_rid,
    input  logic [MST_DATA_W-1:0]    m_rdata,
    input  logic [1:0]               m_rresp,
    input  logic                     m_rlast,
    input  logic                     m_rvalid,
    output logic                     m_rready
);
  logic [3:0] tick;
  always_ff @(posedge clk_i or negedge rst_ni)
    if (!rst_ni) tick <= '0; else tick <= tick + 4'd1;
  // A MULTI-CYCLE WINDOW, not a single cycle. Gating valid and ready with a
  // one-cycle-in-N pulse can make acceptance impossible outright: if the
  // design's ready is registered rather than combinational on valid, the two
  // never coincide and nothing is ever accepted. That is not a slow design, it
  // is a broken one.
  wire adm = tick[3];                    // eight on, eight off
  // GATED IN PAIRS. Masking only the ready is NOT a legal way to implement "this
  // design is slow": the golden asserts its ready and considers the transfer
  // done, while the master never sees it and re-offers -- so one upstream
  // request is accepted several times and A2 is violated by the PERTURBATION.
  // The valid presented to the golden and the ready presented outward carry the
  // same gate, so no cycle exists in which one side believes a transfer
  // happened and the other does not.
  logic g_awready, g_arready;
  assign s_awready = g_awready & adm;
  assign s_arready = g_arready & adm;
  dw_downsizer i_g (
    .clk_i, .rst_ni,
    .s_awid, .s_awaddr, .s_awlen, .s_awsize, .s_awburst, .s_awvalid(s_awvalid & adm), .s_awready(g_awready),
    .s_wdata, .s_wstrb, .s_wlast, .s_wvalid, .s_wready,
    .s_bid, .s_bresp, .s_bvalid, .s_bready,
    .s_arid, .s_araddr, .s_arlen, .s_arsize, .s_arburst, .s_arvalid(s_arvalid & adm), .s_arready(g_arready),
    .s_rid, .s_rdata, .s_rresp, .s_rlast, .s_rvalid, .s_rready,
    .m_awid, .m_awaddr, .m_awlen, .m_awsize, .m_awburst, .m_awvalid, .m_awready,
    .m_wdata, .m_wstrb, .m_wlast, .m_wvalid, .m_wready,
    .m_bid, .m_bresp, .m_bvalid, .m_bready,
    .m_arid, .m_araddr, .m_arlen, .m_arsize, .m_arburst, .m_arvalid, .m_arready,
    .m_rid, .m_rdata, .m_rresp, .m_rlast, .m_rvalid, .m_rready
  );
endmodule

// ----------------------------------------------------------------------------
// c3 -- a SKID BUFFER on the downstream write data channel. The burst arrives a
// cycle later and, under backpressure, with gaps between its beats. Clause L5
// leaves the number of beats in flight and whether the burst is contiguous
// free. A testbench that requires the downstream beats of one burst to be
// consecutive cycles fails this.
// ----------------------------------------------------------------------------
module dwc_c3_downstream_w_spilled #(
    parameter int unsigned ADDR_W     = 32,
    parameter int unsigned ID_W       = 4,
    parameter int unsigned SLV_DATA_W = 64,   // upstream, wide
    parameter int unsigned MST_DATA_W = 16,   // downstream, narrow
    parameter int unsigned MAX_READS  = 4
) (
    input  logic clk_i,
    input  logic rst_ni,

    // ---- slave (upstream, WIDE) port ----
    input  logic [ID_W-1:0]          s_awid,
    input  logic [ADDR_W-1:0]        s_awaddr,
    input  logic [7:0]               s_awlen,
    input  logic [2:0]               s_awsize,
    input  logic [1:0]               s_awburst,
    input  logic                     s_awvalid,
    output logic                     s_awready,
    input  logic [SLV_DATA_W-1:0]    s_wdata,
    input  logic [SLV_DATA_W/8-1:0]  s_wstrb,
    input  logic                     s_wlast,
    input  logic                     s_wvalid,
    output logic                     s_wready,
    output logic [ID_W-1:0]          s_bid,
    output logic [1:0]               s_bresp,
    output logic                     s_bvalid,
    input  logic                     s_bready,
    input  logic [ID_W-1:0]          s_arid,
    input  logic [ADDR_W-1:0]        s_araddr,
    input  logic [7:0]               s_arlen,
    input  logic [2:0]               s_arsize,
    input  logic [1:0]               s_arburst,
    input  logic                     s_arvalid,
    output logic                     s_arready,
    output logic [ID_W-1:0]          s_rid,
    output logic [SLV_DATA_W-1:0]    s_rdata,
    output logic [1:0]               s_rresp,
    output logic                     s_rlast,
    output logic                     s_rvalid,
    input  logic                     s_rready,

    // ---- master (downstream, NARROW) port ----
    output logic [ID_W-1:0]          m_awid,
    output logic [ADDR_W-1:0]        m_awaddr,
    output logic [7:0]               m_awlen,
    output logic [2:0]               m_awsize,
    output logic [1:0]               m_awburst,
    output logic                     m_awvalid,
    input  logic                     m_awready,
    output logic [MST_DATA_W-1:0]    m_wdata,
    output logic [MST_DATA_W/8-1:0]  m_wstrb,
    output logic                     m_wlast,
    output logic                     m_wvalid,
    input  logic                     m_wready,
    input  logic [ID_W-1:0]          m_bid,
    input  logic [1:0]               m_bresp,
    input  logic                     m_bvalid,
    output logic                     m_bready,
    output logic [ID_W-1:0]          m_arid,
    output logic [ADDR_W-1:0]        m_araddr,
    output logic [7:0]               m_arlen,
    output logic [2:0]               m_arsize,
    output logic [1:0]               m_arburst,
    output logic                     m_arvalid,
    input  logic                     m_arready,
    input  logic [ID_W-1:0]          m_rid,
    input  logic [MST_DATA_W-1:0]    m_rdata,
    input  logic [1:0]               m_rresp,
    input  logic                     m_rlast,
    input  logic                     m_rvalid,
    output logic                     m_rready
);
  typedef struct packed {
    logic [MST_DATA_W-1:0]   data;
    logic [MST_DATA_W/8-1:0] strb;
    logic                    last;
  } wbeat_t;
  wbeat_t g_w, o_w;
  logic   g_wvalid, g_wready;
  logic [MST_DATA_W-1:0]   g_wdata;
  logic [MST_DATA_W/8-1:0] g_wstrb;
  logic                    g_wlast;
  assign g_w = '{data: g_wdata, strb: g_wstrb, last: g_wlast};
  spill_register #(.T(wbeat_t)) i_spill (
    .clk_i, .rst_ni,
    .valid_i(g_wvalid), .ready_o(g_wready), .data_i(g_w),
    .valid_o(m_wvalid), .ready_i(m_wready), .data_o(o_w));
  assign m_wdata = o_w.data;
  assign m_wstrb = o_w.strb;
  assign m_wlast = o_w.last;
  dw_downsizer i_g (
    .clk_i, .rst_ni,
    .s_awid, .s_awaddr, .s_awlen, .s_awsize, .s_awburst, .s_awvalid, .s_awready,
    .s_wdata, .s_wstrb, .s_wlast, .s_wvalid, .s_wready,
    .s_bid, .s_bresp, .s_bvalid, .s_bready,
    .s_arid, .s_araddr, .s_arlen, .s_arsize, .s_arburst, .s_arvalid, .s_arready,
    .s_rid, .s_rdata, .s_rresp, .s_rlast, .s_rvalid, .s_rready,
    .m_awid, .m_awaddr, .m_awlen, .m_awsize, .m_awburst, .m_awvalid, .m_awready,
    .m_wdata(g_wdata), .m_wstrb(g_wstrb), .m_wlast(g_wlast), .m_wvalid(g_wvalid), .m_wready(g_wready),
    .m_bid, .m_bresp, .m_bvalid, .m_bready,
    .m_arid, .m_araddr, .m_arlen, .m_arsize, .m_arburst, .m_arvalid, .m_arready,
    .m_rid, .m_rdata, .m_rresp, .m_rlast, .m_rvalid, .m_rready
  );
endmodule

// ----------------------------------------------------------------------------
// c4 -- a fixed recognisable pattern on every payload output while its own
// valid is low, where the golden drives the computed value. Clause X2 says a
// payload nothing can observe carries no requirement. A testbench that samples
// a payload without gating on valid fails this, and it is checking a value the
// contract does not define.
// ----------------------------------------------------------------------------
module dwc_c4_garbage_when_invalid #(
    parameter int unsigned ADDR_W     = 32,
    parameter int unsigned ID_W       = 4,
    parameter int unsigned SLV_DATA_W = 64,   // upstream, wide
    parameter int unsigned MST_DATA_W = 16,   // downstream, narrow
    parameter int unsigned MAX_READS  = 4
) (
    input  logic clk_i,
    input  logic rst_ni,

    // ---- slave (upstream, WIDE) port ----
    input  logic [ID_W-1:0]          s_awid,
    input  logic [ADDR_W-1:0]        s_awaddr,
    input  logic [7:0]               s_awlen,
    input  logic [2:0]               s_awsize,
    input  logic [1:0]               s_awburst,
    input  logic                     s_awvalid,
    output logic                     s_awready,
    input  logic [SLV_DATA_W-1:0]    s_wdata,
    input  logic [SLV_DATA_W/8-1:0]  s_wstrb,
    input  logic                     s_wlast,
    input  logic                     s_wvalid,
    output logic                     s_wready,
    output logic [ID_W-1:0]          s_bid,
    output logic [1:0]               s_bresp,
    output logic                     s_bvalid,
    input  logic                     s_bready,
    input  logic [ID_W-1:0]          s_arid,
    input  logic [ADDR_W-1:0]        s_araddr,
    input  logic [7:0]               s_arlen,
    input  logic [2:0]               s_arsize,
    input  logic [1:0]               s_arburst,
    input  logic                     s_arvalid,
    output logic                     s_arready,
    output logic [ID_W-1:0]          s_rid,
    output logic [SLV_DATA_W-1:0]    s_rdata,
    output logic [1:0]               s_rresp,
    output logic                     s_rlast,
    output logic                     s_rvalid,
    input  logic                     s_rready,

    // ---- master (downstream, NARROW) port ----
    output logic [ID_W-1:0]          m_awid,
    output logic [ADDR_W-1:0]        m_awaddr,
    output logic [7:0]               m_awlen,
    output logic [2:0]               m_awsize,
    output logic [1:0]               m_awburst,
    output logic                     m_awvalid,
    input  logic                     m_awready,
    output logic [MST_DATA_W-1:0]    m_wdata,
    output logic [MST_DATA_W/8-1:0]  m_wstrb,
    output logic                     m_wlast,
    output logic                     m_wvalid,
    input  logic                     m_wready,
    input  logic [ID_W-1:0]          m_bid,
    input  logic [1:0]               m_bresp,
    input  logic                     m_bvalid,
    output logic                     m_bready,
    output logic [ID_W-1:0]          m_arid,
    output logic [ADDR_W-1:0]        m_araddr,
    output logic [7:0]               m_arlen,
    output logic [2:0]               m_arsize,
    output logic [1:0]               m_arburst,
    output logic                     m_arvalid,
    input  logic                     m_arready,
    input  logic [ID_W-1:0]          m_rid,
    input  logic [MST_DATA_W-1:0]    m_rdata,
    input  logic [1:0]               m_rresp,
    input  logic                     m_rlast,
    input  logic                     m_rvalid,
    output logic                     m_rready
);
  logic [ID_W-1:0]         g_rid, g_bid, g_awid, g_arid;
  logic [SLV_DATA_W-1:0]   g_rdata;
  logic [1:0]              g_rresp, g_bresp;
  logic                    g_rlast;
  logic [MST_DATA_W-1:0]   g_wdata;
  logic [MST_DATA_W/8-1:0] g_wstrb;
  logic                    g_wlast;
  logic [31:0]             g_awaddr, g_araddr;
  logic [7:0]              g_awlen, g_arlen;
  logic [2:0]              g_awsize, g_arsize;
  logic [1:0]              g_awburst, g_arburst;
  assign s_rid    = s_rvalid ? g_rid    : 4'hA;
  assign s_rdata  = s_rvalid ? g_rdata  : 64'hDEAD_BEEF_DEAD_BEEF;
  assign s_rresp  = s_rvalid ? g_rresp  : 2'b11;
  assign s_rlast  = s_rvalid ? g_rlast  : 1'b1;
  assign s_bid    = s_bvalid ? g_bid    : 4'hB;
  assign s_bresp  = s_bvalid ? g_bresp  : 2'b11;
  assign m_wdata  = m_wvalid ? g_wdata  : 16'hC0DE;
  assign m_wstrb  = m_wvalid ? g_wstrb  : '1;
  assign m_wlast  = m_wvalid ? g_wlast  : 1'b1;
  assign m_awid   = m_awvalid ? g_awid   : 4'hC;
  assign m_awaddr = m_awvalid ? g_awaddr : 32'hFEED_FACE;
  assign m_awlen  = m_awvalid ? g_awlen  : 8'hFF;
  assign m_awsize = m_awvalid ? g_awsize : 3'h7;
  assign m_awburst= m_awvalid ? g_awburst: 2'b11;
  assign m_arid   = m_arvalid ? g_arid   : 4'hD;
  assign m_araddr = m_arvalid ? g_araddr : 32'hFEED_FACE;
  assign m_arlen  = m_arvalid ? g_arlen  : 8'hFF;
  assign m_arsize = m_arvalid ? g_arsize : 3'h7;
  assign m_arburst= m_arvalid ? g_arburst: 2'b11;
  dw_downsizer i_g (
    .clk_i, .rst_ni,
    .s_awid, .s_awaddr, .s_awlen, .s_awsize, .s_awburst, .s_awvalid, .s_awready,
    .s_wdata, .s_wstrb, .s_wlast, .s_wvalid, .s_wready,
    .s_bid(g_bid), .s_bresp(g_bresp), .s_bvalid, .s_bready,
    .s_arid, .s_araddr, .s_arlen, .s_arsize, .s_arburst, .s_arvalid, .s_arready,
    .s_rid(g_rid), .s_rdata(g_rdata), .s_rresp(g_rresp), .s_rlast(g_rlast), .s_rvalid, .s_rready,
    .m_awid(g_awid), .m_awaddr(g_awaddr), .m_awlen(g_awlen), .m_awsize(g_awsize), .m_awburst(g_awburst), .m_awvalid, .m_awready,
    .m_wdata(g_wdata), .m_wstrb(g_wstrb), .m_wlast(g_wlast), .m_wvalid, .m_wready,
    .m_bid, .m_bresp, .m_bvalid, .m_bready,
    .m_arid(g_arid), .m_araddr(g_araddr), .m_arlen(g_arlen), .m_arsize(g_arsize), .m_arburst(g_arburst), .m_arvalid, .m_arready,
    .m_rid, .m_rdata, .m_rresp, .m_rlast, .m_rvalid, .m_rready
  );
endmodule

// ----------------------------------------------------------------------------
// c5 -- slow to accept the DOWNSTREAM responses it is waiting on: m_rready and
// m_bready are held low for three cycles out of every four. These are readys
// the DESIGN drives, so L2 covers them, and the effect is that every upstream
// response is late by an amount that varies with alignment. A testbench with a
// response-latency bound of its own invention fails this.
// ----------------------------------------------------------------------------
module dwc_c5_response_intake_slow #(
    parameter int unsigned ADDR_W     = 32,
    parameter int unsigned ID_W       = 4,
    parameter int unsigned SLV_DATA_W = 64,   // upstream, wide
    parameter int unsigned MST_DATA_W = 16,   // downstream, narrow
    parameter int unsigned MAX_READS  = 4
) (
    input  logic clk_i,
    input  logic rst_ni,

    // ---- slave (upstream, WIDE) port ----
    input  logic [ID_W-1:0]          s_awid,
    input  logic [ADDR_W-1:0]        s_awaddr,
    input  logic [7:0]               s_awlen,
    input  logic [2:0]               s_awsize,
    input  logic [1:0]               s_awburst,
    input  logic                     s_awvalid,
    output logic                     s_awready,
    input  logic [SLV_DATA_W-1:0]    s_wdata,
    input  logic [SLV_DATA_W/8-1:0]  s_wstrb,
    input  logic                     s_wlast,
    input  logic                     s_wvalid,
    output logic                     s_wready,
    output logic [ID_W-1:0]          s_bid,
    output logic [1:0]               s_bresp,
    output logic                     s_bvalid,
    input  logic                     s_bready,
    input  logic [ID_W-1:0]          s_arid,
    input  logic [ADDR_W-1:0]        s_araddr,
    input  logic [7:0]               s_arlen,
    input  logic [2:0]               s_arsize,
    input  logic [1:0]               s_arburst,
    input  logic                     s_arvalid,
    output logic                     s_arready,
    output logic [ID_W-1:0]          s_rid,
    output logic [SLV_DATA_W-1:0]    s_rdata,
    output logic [1:0]               s_rresp,
    output logic                     s_rlast,
    output logic                     s_rvalid,
    input  logic                     s_rready,

    // ---- master (downstream, NARROW) port ----
    output logic [ID_W-1:0]          m_awid,
    output logic [ADDR_W-1:0]        m_awaddr,
    output logic [7:0]               m_awlen,
    output logic [2:0]               m_awsize,
    output logic [1:0]               m_awburst,
    output logic                     m_awvalid,
    input  logic                     m_awready,
    output logic [MST_DATA_W-1:0]    m_wdata,
    output logic [MST_DATA_W/8-1:0]  m_wstrb,
    output logic                     m_wlast,
    output logic                     m_wvalid,
    input  logic                     m_wready,
    input  logic [ID_W-1:0]          m_bid,
    input  logic [1:0]               m_bresp,
    input  logic                     m_bvalid,
    output logic                     m_bready,
    output logic [ID_W-1:0]          m_arid,
    output logic [ADDR_W-1:0]        m_araddr,
    output logic [7:0]               m_arlen,
    output logic [2:0]               m_arsize,
    output logic [1:0]               m_arburst,
    output logic                     m_arvalid,
    input  logic                     m_arready,
    input  logic [ID_W-1:0]          m_rid,
    input  logic [MST_DATA_W-1:0]    m_rdata,
    input  logic [1:0]               m_rresp,
    input  logic                     m_rlast,
    input  logic                     m_rvalid,
    output logic                     m_rready
);
  logic [3:0] tick;
  always_ff @(posedge clk_i or negedge rst_ni)
    if (!rst_ni) tick <= '0; else tick <= tick + 4'd1;
  // A MULTI-CYCLE WINDOW, not a single cycle. Gating valid and ready with a
  // one-cycle-in-N pulse can make acceptance impossible outright: if the
  // design's ready is registered rather than combinational on valid, the two
  // never coincide and nothing is ever accepted. That is not a slow design, it
  // is a broken one.
  wire ok = tick[1];                     // two on, two off
  // GATED IN PAIRS. Masking only the ready is NOT a legal way to implement "this
  // design is slow": the golden asserts its ready and considers the transfer
  // done, while the master never sees it and re-offers -- so one upstream
  // request is accepted several times and A2 is violated by the PERTURBATION.
  // The valid presented to the golden and the ready presented outward carry the
  // same gate, so no cycle exists in which one side believes a transfer
  // happened and the other does not.
  //
  // AND HELD ONCE OPEN. A bare `valid & gate` is a WITHDRAWAL whenever the gate
  // falls on a cycle where the golden has an offer in hand and has not yet
  // taken it -- which is exactly what A5 forbids, and it is not a theoretical
  // worry: the anchor asserts the same property internally, and closing the
  // gate on `m_bvalid` mid-arbitration fires it --
  //     rr_arb_tree.sv:391  "it is disallowed to deassert unserved request
  //                          signals when LockIn is enabled".
  // So each gate may FALL only while nothing is pending. `hold_*` is a flop, so
  // the valid presented to the golden never depends combinationally on its
  // ready. Holding costs this perturbation none of the slowness it exists to
  // show -- it still refuses to BEGIN a transfer for the whole closed phase on
  // every intake channel. What it gives up is the right to take an offer back,
  // which no conforming design has.
  //
  // Depth two here, depth four in dwc_c1, on purpose: the two straddle the
  // reference's persistence threshold (three idle cycles between narrow R
  // beats), so the conformant set exercises L7 on both sides of it rather than
  // sampling one. Both were double-driven and inert until this repair -- see
  // the note on the instantiation below.
  logic g_bready, g_rready;
  logic hold_b, hold_r;
  wire  gate_b = ok | hold_b;
  wire  gate_r = ok | hold_r;
  always_ff @(posedge clk_i or negedge rst_ni)
    if (!rst_ni) begin
      hold_b <= 1'b0; hold_r <= 1'b0;
    end else begin
      hold_b <= (m_bvalid & gate_b) & ~g_bready;
      hold_r <= (m_rvalid & gate_r) & ~g_rready;
    end
  assign m_bready = g_bready & gate_b;
  assign m_rready = g_rready & gate_r;
  dw_downsizer i_g (
    .clk_i, .rst_ni,
    .s_awid, .s_awaddr, .s_awlen, .s_awsize, .s_awburst, .s_awvalid, .s_awready,
    .s_wdata, .s_wstrb, .s_wlast, .s_wvalid, .s_wready,
    .s_bid, .s_bresp, .s_bvalid, .s_bready,
    .s_arid, .s_araddr, .s_arlen, .s_arsize, .s_arburst, .s_arvalid, .s_arready,
    .s_rid, .s_rdata, .s_rresp, .s_rlast, .s_rvalid, .s_rready,
    .m_awid, .m_awaddr, .m_awlen, .m_awsize, .m_awburst, .m_awvalid, .m_awready,
    .m_wdata, .m_wstrb, .m_wlast, .m_wvalid, .m_wready,
    .m_bid, .m_bresp, .m_bvalid(m_bvalid & gate_b), .m_bready(g_bready),
    .m_arid, .m_araddr, .m_arlen, .m_arsize, .m_arburst, .m_arvalid, .m_arready,
    // `.m_rready` bare bound the GOLDEN'S OUTPUT to the wrapper's `m_rready`,
    // which the assign above already drives -- a DOUBLE DRIVE, with `g_rready`
    // connected to nothing. The R half of "response intake slow" was never slow.
    .m_rid, .m_rdata, .m_rresp, .m_rlast, .m_rvalid(m_rvalid & gate_r), .m_rready(g_rready)
  );
endmodule
