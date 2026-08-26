// =============================================================================
// conformant_perturbations.sv -- these MUST SURVIVE.
// =============================================================================
// Each wraps the unmodified golden and changes something spec section 8 leaves
// open. A submitted testbench must accept every one; a failure here means it
// checked something the specification never promised.
//
// RULE 16 APPLIES WITH FORCE ON THIS TASK. The latitude here is mostly about
// the ALLOCATION POLICY, and a perturbation that changes a policy in a way the
// table cannot express is a silent no-op: it survives and reports the
// reassuring answer. Every one below therefore carries a measured witness --
// see conformant/README.md -- and iw_c1 in particular exists only because a
// bijection on the master identifiers is a change the table CAN express.
// =============================================================================

// --------------------------------------------------------------------------
// iw_c1 -- a DIFFERENT ALLOCATION POLICY. Licence: D3 and latitude 8.1.
// The master identifiers the golden chooses are permuted through a fixed
// bijection (0<->2, 1<->3) on the way out, and the inverse is applied to the
// responses coming back. A bijection preserves D1 (distinct stays distinct) and
// D2 (a value is free exactly when its image is), so this is a legal allocator
// making different choices -- which is precisely what D3 leaves open.
//
// This is the perturbation rule 16 is aimed at: a policy change the table
// cannot express would be invisible. A permutation is expressible and is
// measured to differ. The second DUT independently shows the same latitude is
// real, by a different route.
// --------------------------------------------------------------------------
module iw_c1_permuted_allocation #(
    parameter int unsigned SLV_ID_W        = 4,
    parameter int unsigned MST_ID_W        = 2,
    parameter int unsigned ADDR_W          = 32,
    parameter int unsigned DATA_W          = 32,
    parameter int unsigned MAX_UNIQ_IDS    = 4,
    parameter int unsigned MAX_TXNS_PER_ID = 2
) (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic [SLV_ID_W-1:0]   s_awid,
    input  logic [ADDR_W-1:0]     s_awaddr,
    input  logic [7:0]            s_awlen,
    input  logic                  s_awvalid,
    output logic                  s_awready,
    input  logic [DATA_W-1:0]     s_wdata,
    input  logic [DATA_W/8-1:0]   s_wstrb,
    input  logic                  s_wlast,
    input  logic                  s_wvalid,
    output logic                  s_wready,
    output logic [SLV_ID_W-1:0]   s_bid,
    output logic [1:0]            s_bresp,
    output logic                  s_bvalid,
    input  logic                  s_bready,
    input  logic [SLV_ID_W-1:0]   s_arid,
    input  logic [ADDR_W-1:0]     s_araddr,
    input  logic [7:0]            s_arlen,
    input  logic                  s_arvalid,
    output logic                  s_arready,
    output logic [SLV_ID_W-1:0]   s_rid,
    output logic [DATA_W-1:0]     s_rdata,
    output logic [1:0]            s_rresp,
    output logic                  s_rlast,
    output logic                  s_rvalid,
    input  logic                  s_rready,
    output logic [MST_ID_W-1:0]   m_awid,
    output logic [ADDR_W-1:0]     m_awaddr,
    output logic [7:0]            m_awlen,
    output logic                  m_awvalid,
    input  logic                  m_awready,
    output logic [DATA_W-1:0]     m_wdata,
    output logic [DATA_W/8-1:0]   m_wstrb,
    output logic                  m_wlast,
    output logic                  m_wvalid,
    input  logic                  m_wready,
    input  logic [MST_ID_W-1:0]   m_bid,
    input  logic [1:0]            m_bresp,
    input  logic                  m_bvalid,
    output logic                  m_bready,
    output logic [MST_ID_W-1:0]   m_arid,
    output logic [ADDR_W-1:0]     m_araddr,
    output logic [7:0]            m_arlen,
    output logic                  m_arvalid,
    input  logic                  m_arready,
    input  logic [MST_ID_W-1:0]   m_rid,
    input  logic [DATA_W-1:0]     m_rdata,
    input  logic [1:0]            m_rresp,
    input  logic                  m_rlast,
    input  logic                  m_rvalid,
    output logic                  m_rready
);

  function automatic logic [MST_ID_W-1:0] perm(input logic [MST_ID_W-1:0] x);
    return x ^ MST_ID_W'(2);          // 0<->2, 1<->3 : an involution
  endfunction

  logic [MST_ID_W-1:0] g_arid, g_awid;
  assign m_arid = perm(g_arid);
  assign m_awid = perm(g_awid);
  id_width_conv #(
      .SLV_ID_W(SLV_ID_W), .MST_ID_W(MST_ID_W), .ADDR_W(ADDR_W), .DATA_W(DATA_W),
      .MAX_UNIQ_IDS(MAX_UNIQ_IDS), .MAX_TXNS_PER_ID(MAX_TXNS_PER_ID)
  ) i_g (
      .clk_i     (clk_i),
      .rst_ni    (rst_ni),
      .s_awid    (s_awid),
      .s_awaddr  (s_awaddr),
      .s_awlen   (s_awlen),
      .s_awvalid (s_awvalid),
      .s_awready (s_awready),
      .s_wdata   (s_wdata),
      .s_wstrb   (s_wstrb),
      .s_wlast   (s_wlast),
      .s_wvalid  (s_wvalid),
      .s_wready  (s_wready),
      .s_bid     (s_bid),
      .s_bresp   (s_bresp),
      .s_bvalid  (s_bvalid),
      .s_bready  (s_bready),
      .s_arid    (s_arid),
      .s_araddr  (s_araddr),
      .s_arlen   (s_arlen),
      .s_arvalid (s_arvalid),
      .s_arready (s_arready),
      .s_rid     (s_rid),
      .s_rdata   (s_rdata),
      .s_rresp   (s_rresp),
      .s_rlast   (s_rlast),
      .s_rvalid  (s_rvalid),
      .s_rready  (s_rready),
      .m_awid    (g_awid),
      .m_awaddr  (m_awaddr),
      .m_awlen   (m_awlen),
      .m_awvalid (m_awvalid),
      .m_awready (m_awready),
      .m_wdata   (m_wdata),
      .m_wstrb   (m_wstrb),
      .m_wlast   (m_wlast),
      .m_wvalid  (m_wvalid),
      .m_wready  (m_wready),
      .m_bid     (perm(m_bid)),
      .m_bresp   (m_bresp),
      .m_bvalid  (m_bvalid),
      .m_bready  (m_bready),
      .m_arid    (g_arid),
      .m_araddr  (m_araddr),
      .m_arlen   (m_arlen),
      .m_arvalid (m_arvalid),
      .m_arready (m_arready),
      .m_rid     (perm(m_rid)),
      .m_rdata   (m_rdata),
      .m_rresp   (m_rresp),
      .m_rlast   (m_rlast),
      .m_rvalid  (m_rvalid),
      .m_rready  (m_rready)
  );
endmodule

// --------------------------------------------------------------------------
// iw_c2 -- ONE EXTRA REGISTER STAGE on the master read-address path.
// Licence: latitude 8.2, latency is unconstrained. A register slice with a
// combinational upstream ready: one more cycle before the master request
// appears, no loss of throughput, and A4's window is untouched because the
// slave-side acceptance is not delayed by it.
// --------------------------------------------------------------------------
module iw_c2_extra_latency #(
    parameter int unsigned SLV_ID_W        = 4,
    parameter int unsigned MST_ID_W        = 2,
    parameter int unsigned ADDR_W          = 32,
    parameter int unsigned DATA_W          = 32,
    parameter int unsigned MAX_UNIQ_IDS    = 4,
    parameter int unsigned MAX_TXNS_PER_ID = 2
) (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic [SLV_ID_W-1:0]   s_awid,
    input  logic [ADDR_W-1:0]     s_awaddr,
    input  logic [7:0]            s_awlen,
    input  logic                  s_awvalid,
    output logic                  s_awready,
    input  logic [DATA_W-1:0]     s_wdata,
    input  logic [DATA_W/8-1:0]   s_wstrb,
    input  logic                  s_wlast,
    input  logic                  s_wvalid,
    output logic                  s_wready,
    output logic [SLV_ID_W-1:0]   s_bid,
    output logic [1:0]            s_bresp,
    output logic                  s_bvalid,
    input  logic                  s_bready,
    input  logic [SLV_ID_W-1:0]   s_arid,
    input  logic [ADDR_W-1:0]     s_araddr,
    input  logic [7:0]            s_arlen,
    input  logic                  s_arvalid,
    output logic                  s_arready,
    output logic [SLV_ID_W-1:0]   s_rid,
    output logic [DATA_W-1:0]     s_rdata,
    output logic [1:0]            s_rresp,
    output logic                  s_rlast,
    output logic                  s_rvalid,
    input  logic                  s_rready,
    output logic [MST_ID_W-1:0]   m_awid,
    output logic [ADDR_W-1:0]     m_awaddr,
    output logic [7:0]            m_awlen,
    output logic                  m_awvalid,
    input  logic                  m_awready,
    output logic [DATA_W-1:0]     m_wdata,
    output logic [DATA_W/8-1:0]   m_wstrb,
    output logic                  m_wlast,
    output logic                  m_wvalid,
    input  logic                  m_wready,
    input  logic [MST_ID_W-1:0]   m_bid,
    input  logic [1:0]            m_bresp,
    input  logic                  m_bvalid,
    output logic                  m_bready,
    output logic [MST_ID_W-1:0]   m_arid,
    output logic [ADDR_W-1:0]     m_araddr,
    output logic [7:0]            m_arlen,
    output logic                  m_arvalid,
    input  logic                  m_arready,
    input  logic [MST_ID_W-1:0]   m_rid,
    input  logic [DATA_W-1:0]     m_rdata,
    input  logic [1:0]            m_rresp,
    input  logic                  m_rlast,
    input  logic                  m_rvalid,
    output logic                  m_rready
);

  logic [MST_ID_W-1:0] g_arid; logic [ADDR_W-1:0] g_araddr; logic [7:0] g_arlen;
  logic g_arvalid, g_arready;
  logic [MST_ID_W-1:0] r_id; logic [ADDR_W-1:0] r_addr; logic [7:0] r_len; logic r_val;

  wire fire = r_val & m_arready;
  wire free = ~r_val | fire;
  assign g_arready = free;
  assign m_arvalid = r_val;
  assign m_arid    = r_id;
  assign m_araddr  = r_addr;
  assign m_arlen   = r_len;

  always_ff @(posedge clk_i) begin
    if (!rst_ni) r_val <= 1'b0;
    else begin
      if (fire) r_val <= 1'b0;
      if (free && g_arvalid) begin
        r_val <= 1'b1; r_id <= g_arid; r_addr <= g_araddr; r_len <= g_arlen;
      end
    end
  end
  id_width_conv #(
      .SLV_ID_W(SLV_ID_W), .MST_ID_W(MST_ID_W), .ADDR_W(ADDR_W), .DATA_W(DATA_W),
      .MAX_UNIQ_IDS(MAX_UNIQ_IDS), .MAX_TXNS_PER_ID(MAX_TXNS_PER_ID)
  ) i_g (
      .clk_i     (clk_i),
      .rst_ni    (rst_ni),
      .s_awid    (s_awid),
      .s_awaddr  (s_awaddr),
      .s_awlen   (s_awlen),
      .s_awvalid (s_awvalid),
      .s_awready (s_awready),
      .s_wdata   (s_wdata),
      .s_wstrb   (s_wstrb),
      .s_wlast   (s_wlast),
      .s_wvalid  (s_wvalid),
      .s_wready  (s_wready),
      .s_bid     (s_bid),
      .s_bresp   (s_bresp),
      .s_bvalid  (s_bvalid),
      .s_bready  (s_bready),
      .s_arid    (s_arid),
      .s_araddr  (s_araddr),
      .s_arlen   (s_arlen),
      .s_arvalid (s_arvalid),
      .s_arready (s_arready),
      .s_rid     (s_rid),
      .s_rdata   (s_rdata),
      .s_rresp   (s_rresp),
      .s_rlast   (s_rlast),
      .s_rvalid  (s_rvalid),
      .s_rready  (s_rready),
      .m_awid    (m_awid),
      .m_awaddr  (m_awaddr),
      .m_awlen   (m_awlen),
      .m_awvalid (m_awvalid),
      .m_awready (m_awready),
      .m_wdata   (m_wdata),
      .m_wstrb   (m_wstrb),
      .m_wlast   (m_wlast),
      .m_wvalid  (m_wvalid),
      .m_wready  (m_wready),
      .m_bid     (m_bid),
      .m_bresp   (m_bresp),
      .m_bvalid  (m_bvalid),
      .m_bready  (m_bready),
      .m_arid    (g_arid),
      .m_araddr  (g_araddr),
      .m_arlen   (g_arlen),
      .m_arvalid (g_arvalid),
      .m_arready (g_arready),
      .m_rid     (m_rid),
      .m_rdata   (m_rdata),
      .m_rresp   (m_rresp),
      .m_rlast   (m_rlast),
      .m_rvalid  (m_rvalid),
      .m_rready  (m_rready)
  );
endmodule

// --------------------------------------------------------------------------
// iw_c3 -- READY WITHHELD one cycle in four. Licence: latitude 8.3.
// Ready may be low for internal arbitration where neither A3 nor A4 speaks.
// The mask is one cycle in four, so the worst delay it can add is a single
// cycle and A4's two-cycle window still holds. Valid into the golden and ready
// out are gated together, so no cycle exists in which one side believes a
// transaction was accepted and the other does not.
// --------------------------------------------------------------------------
module iw_c3_ready_withheld #(
    parameter int unsigned SLV_ID_W        = 4,
    parameter int unsigned MST_ID_W        = 2,
    parameter int unsigned ADDR_W          = 32,
    parameter int unsigned DATA_W          = 32,
    parameter int unsigned MAX_UNIQ_IDS    = 4,
    parameter int unsigned MAX_TXNS_PER_ID = 2
) (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic [SLV_ID_W-1:0]   s_awid,
    input  logic [ADDR_W-1:0]     s_awaddr,
    input  logic [7:0]            s_awlen,
    input  logic                  s_awvalid,
    output logic                  s_awready,
    input  logic [DATA_W-1:0]     s_wdata,
    input  logic [DATA_W/8-1:0]   s_wstrb,
    input  logic                  s_wlast,
    input  logic                  s_wvalid,
    output logic                  s_wready,
    output logic [SLV_ID_W-1:0]   s_bid,
    output logic [1:0]            s_bresp,
    output logic                  s_bvalid,
    input  logic                  s_bready,
    input  logic [SLV_ID_W-1:0]   s_arid,
    input  logic [ADDR_W-1:0]     s_araddr,
    input  logic [7:0]            s_arlen,
    input  logic                  s_arvalid,
    output logic                  s_arready,
    output logic [SLV_ID_W-1:0]   s_rid,
    output logic [DATA_W-1:0]     s_rdata,
    output logic [1:0]            s_rresp,
    output logic                  s_rlast,
    output logic                  s_rvalid,
    input  logic                  s_rready,
    output logic [MST_ID_W-1:0]   m_awid,
    output logic [ADDR_W-1:0]     m_awaddr,
    output logic [7:0]            m_awlen,
    output logic                  m_awvalid,
    input  logic                  m_awready,
    output logic [DATA_W-1:0]     m_wdata,
    output logic [DATA_W/8-1:0]   m_wstrb,
    output logic                  m_wlast,
    output logic                  m_wvalid,
    input  logic                  m_wready,
    input  logic [MST_ID_W-1:0]   m_bid,
    input  logic [1:0]            m_bresp,
    input  logic                  m_bvalid,
    output logic                  m_bready,
    output logic [MST_ID_W-1:0]   m_arid,
    output logic [ADDR_W-1:0]     m_araddr,
    output logic [7:0]            m_arlen,
    output logic                  m_arvalid,
    input  logic                  m_arready,
    input  logic [MST_ID_W-1:0]   m_rid,
    input  logic [DATA_W-1:0]     m_rdata,
    input  logic [1:0]            m_rresp,
    input  logic                  m_rlast,
    input  logic                  m_rvalid,
    output logic                  m_rready
);

  logic [1:0] cnt;
  always_ff @(posedge clk_i) if (!rst_ni) cnt <= '0; else cnt <= cnt + 1;
  wire block = (cnt == 2'd0);

  logic g_arvalid, g_arready, g_awvalid, g_awready;
  // A GATE ON A VALID GOING INTO THE DESIGN IS A WITHDRAWAL, and D5 forbids it.
  // The gate falls on a cycle where the design already holds an unaccepted
  // offer, and the anchor's own vendored arbiter says so on the same event:
  //     dut/rr_arb_tree.sv:391  "It is disallowed to deassert unserved request
  //                              signals when LockIn is enabled."
  // A gate may therefore FALL only while nothing is pending. `hold_*` is a flop,
  // so the valid presented to the design never depends combinationally on its
  // ready -- D5's second sentence, satisfied by construction. The perturbation
  // keeps every cycle of the behaviour it exists to demonstrate: it still
  // refuses to BEGIN a transfer for the whole closed phase. What it gives up is
  // the right to take an offer back, which no conforming design has.
  logic hold_ar, hold_aw;
  wire  en_ar = ~block | hold_ar;
  wire  en_aw = ~block | hold_aw;
  always_ff @(posedge clk_i)
    if (!rst_ni) begin
      hold_ar <= 1'b0; hold_aw <= 1'b0;
    end else begin
      hold_ar <= (s_arvalid & en_ar) & ~g_arready;
      hold_aw <= (s_awvalid & en_aw) & ~g_awready;
    end
  assign g_arvalid = s_arvalid & en_ar;
  assign s_arready = g_arready & en_ar;
  assign g_awvalid = s_awvalid & en_aw;
  assign s_awready = g_awready & en_aw;
  id_width_conv #(
      .SLV_ID_W(SLV_ID_W), .MST_ID_W(MST_ID_W), .ADDR_W(ADDR_W), .DATA_W(DATA_W),
      .MAX_UNIQ_IDS(MAX_UNIQ_IDS), .MAX_TXNS_PER_ID(MAX_TXNS_PER_ID)
  ) i_g (
      .clk_i     (clk_i),
      .rst_ni    (rst_ni),
      .s_awid    (s_awid),
      .s_awaddr  (s_awaddr),
      .s_awlen   (s_awlen),
      .s_awvalid (g_awvalid),
      .s_awready (g_awready),
      .s_wdata   (s_wdata),
      .s_wstrb   (s_wstrb),
      .s_wlast   (s_wlast),
      .s_wvalid  (s_wvalid),
      .s_wready  (s_wready),
      .s_bid     (s_bid),
      .s_bresp   (s_bresp),
      .s_bvalid  (s_bvalid),
      .s_bready  (s_bready),
      .s_arid    (s_arid),
      .s_araddr  (s_araddr),
      .s_arlen   (s_arlen),
      .s_arvalid (g_arvalid),
      .s_arready (g_arready),
      .s_rid     (s_rid),
      .s_rdata   (s_rdata),
      .s_rresp   (s_rresp),
      .s_rlast   (s_rlast),
      .s_rvalid  (s_rvalid),
      .s_rready  (s_rready),
      .m_awid    (m_awid),
      .m_awaddr  (m_awaddr),
      .m_awlen   (m_awlen),
      .m_awvalid (m_awvalid),
      .m_awready (m_awready),
      .m_wdata   (m_wdata),
      .m_wstrb   (m_wstrb),
      .m_wlast   (m_wlast),
      .m_wvalid  (m_wvalid),
      .m_wready  (m_wready),
      .m_bid     (m_bid),
      .m_bresp   (m_bresp),
      .m_bvalid  (m_bvalid),
      .m_bready  (m_bready),
      .m_arid    (m_arid),
      .m_araddr  (m_araddr),
      .m_arlen   (m_arlen),
      .m_arvalid (m_arvalid),
      .m_arready (m_arready),
      .m_rid     (m_rid),
      .m_rdata   (m_rdata),
      .m_rresp   (m_rresp),
      .m_rlast   (m_rlast),
      .m_rvalid  (m_rvalid),
      .m_rready  (m_rready)
  );
endmodule

// --------------------------------------------------------------------------
// iw_c4 -- NOISE ON EVERY OUTPUT WHILE ITS VALID IS LOW. Licence: latitude 8.5.
// The values on an output are unconstrained whenever its valid is deasserted,
// so this drives an LFSR there. A testbench that samples an address or a
// response without qualifying on valid fails here and only here.
// --------------------------------------------------------------------------
module iw_c4_garbage_when_invalid #(
    parameter int unsigned SLV_ID_W        = 4,
    parameter int unsigned MST_ID_W        = 2,
    parameter int unsigned ADDR_W          = 32,
    parameter int unsigned DATA_W          = 32,
    parameter int unsigned MAX_UNIQ_IDS    = 4,
    parameter int unsigned MAX_TXNS_PER_ID = 2
) (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic [SLV_ID_W-1:0]   s_awid,
    input  logic [ADDR_W-1:0]     s_awaddr,
    input  logic [7:0]            s_awlen,
    input  logic                  s_awvalid,
    output logic                  s_awready,
    input  logic [DATA_W-1:0]     s_wdata,
    input  logic [DATA_W/8-1:0]   s_wstrb,
    input  logic                  s_wlast,
    input  logic                  s_wvalid,
    output logic                  s_wready,
    output logic [SLV_ID_W-1:0]   s_bid,
    output logic [1:0]            s_bresp,
    output logic                  s_bvalid,
    input  logic                  s_bready,
    input  logic [SLV_ID_W-1:0]   s_arid,
    input  logic [ADDR_W-1:0]     s_araddr,
    input  logic [7:0]            s_arlen,
    input  logic                  s_arvalid,
    output logic                  s_arready,
    output logic [SLV_ID_W-1:0]   s_rid,
    output logic [DATA_W-1:0]     s_rdata,
    output logic [1:0]            s_rresp,
    output logic                  s_rlast,
    output logic                  s_rvalid,
    input  logic                  s_rready,
    output logic [MST_ID_W-1:0]   m_awid,
    output logic [ADDR_W-1:0]     m_awaddr,
    output logic [7:0]            m_awlen,
    output logic                  m_awvalid,
    input  logic                  m_awready,
    output logic [DATA_W-1:0]     m_wdata,
    output logic [DATA_W/8-1:0]   m_wstrb,
    output logic                  m_wlast,
    output logic                  m_wvalid,
    input  logic                  m_wready,
    input  logic [MST_ID_W-1:0]   m_bid,
    input  logic [1:0]            m_bresp,
    input  logic                  m_bvalid,
    output logic                  m_bready,
    output logic [MST_ID_W-1:0]   m_arid,
    output logic [ADDR_W-1:0]     m_araddr,
    output logic [7:0]            m_arlen,
    output logic                  m_arvalid,
    input  logic                  m_arready,
    input  logic [MST_ID_W-1:0]   m_rid,
    input  logic [DATA_W-1:0]     m_rdata,
    input  logic [1:0]            m_rresp,
    input  logic                  m_rlast,
    input  logic                  m_rvalid,
    output logic                  m_rready
);

  logic [31:0] lfsr;
  always_ff @(posedge clk_i)
    if (!rst_ni) lfsr <= 32'h1234_5678;
    else         lfsr <= {lfsr[30:0], lfsr[31]^lfsr[21]^lfsr[1]^lfsr[0]};

  logic [MST_ID_W-1:0] g_arid; logic [ADDR_W-1:0] g_araddr; logic [7:0] g_arlen;
  logic g_arvalid;
  logic [SLV_ID_W-1:0] g_rid; logic [DATA_W-1:0] g_rdata; logic [1:0] g_rresp;
  logic g_rlast, g_rvalid;

  assign m_arvalid = g_arvalid;
  assign m_arid    = g_arvalid ? g_arid   : lfsr[MST_ID_W-1:0];
  assign m_araddr  = g_arvalid ? g_araddr : lfsr;
  assign m_arlen   = g_arvalid ? g_arlen  : lfsr[7:0];
  assign s_rvalid  = g_rvalid;
  assign s_rid     = g_rvalid ? g_rid   : lfsr[SLV_ID_W-1:0];
  assign s_rdata   = g_rvalid ? g_rdata : lfsr;
  assign s_rresp   = g_rvalid ? g_rresp : lfsr[1:0];
  assign s_rlast   = g_rvalid ? g_rlast : lfsr[7];
  id_width_conv #(
      .SLV_ID_W(SLV_ID_W), .MST_ID_W(MST_ID_W), .ADDR_W(ADDR_W), .DATA_W(DATA_W),
      .MAX_UNIQ_IDS(MAX_UNIQ_IDS), .MAX_TXNS_PER_ID(MAX_TXNS_PER_ID)
  ) i_g (
      .clk_i     (clk_i),
      .rst_ni    (rst_ni),
      .s_awid    (s_awid),
      .s_awaddr  (s_awaddr),
      .s_awlen   (s_awlen),
      .s_awvalid (s_awvalid),
      .s_awready (s_awready),
      .s_wdata   (s_wdata),
      .s_wstrb   (s_wstrb),
      .s_wlast   (s_wlast),
      .s_wvalid  (s_wvalid),
      .s_wready  (s_wready),
      .s_bid     (s_bid),
      .s_bresp   (s_bresp),
      .s_bvalid  (s_bvalid),
      .s_bready  (s_bready),
      .s_arid    (s_arid),
      .s_araddr  (s_araddr),
      .s_arlen   (s_arlen),
      .s_arvalid (s_arvalid),
      .s_arready (s_arready),
      .s_rid     (g_rid),
      .s_rdata   (g_rdata),
      .s_rresp   (g_rresp),
      .s_rlast   (g_rlast),
      .s_rvalid  (g_rvalid),
      .s_rready  (s_rready),
      .m_awid    (m_awid),
      .m_awaddr  (m_awaddr),
      .m_awlen   (m_awlen),
      .m_awvalid (m_awvalid),
      .m_awready (m_awready),
      .m_wdata   (m_wdata),
      .m_wstrb   (m_wstrb),
      .m_wlast   (m_wlast),
      .m_wvalid  (m_wvalid),
      .m_wready  (m_wready),
      .m_bid     (m_bid),
      .m_bresp   (m_bresp),
      .m_bvalid  (m_bvalid),
      .m_bready  (m_bready),
      .m_arid    (g_arid),
      .m_araddr  (g_araddr),
      .m_arlen   (g_arlen),
      .m_arvalid (g_arvalid),
      .m_arready (m_arready),
      .m_rid     (m_rid),
      .m_rdata   (m_rdata),
      .m_rresp   (m_rresp),
      .m_rlast   (m_rlast),
      .m_rvalid  (m_rvalid),
      .m_rready  (m_rready)
  );
endmodule

// --------------------------------------------------------------------------
// iw_c5 -- READ AND WRITE ADDRESS CHANNELS ARBITRATED. Licence: latitude 8.3,
// and A1's separate counting does not require both to be accepted at once.
// When both channels offer in the same cycle only one is admitted, alternating.
// A single channel offering alone is never delayed, so the worst case is one
// cycle and A4's window holds.
// --------------------------------------------------------------------------
module iw_c5_channel_arbitration #(
    parameter int unsigned SLV_ID_W        = 4,
    parameter int unsigned MST_ID_W        = 2,
    parameter int unsigned ADDR_W          = 32,
    parameter int unsigned DATA_W          = 32,
    parameter int unsigned MAX_UNIQ_IDS    = 4,
    parameter int unsigned MAX_TXNS_PER_ID = 2
) (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic [SLV_ID_W-1:0]   s_awid,
    input  logic [ADDR_W-1:0]     s_awaddr,
    input  logic [7:0]            s_awlen,
    input  logic                  s_awvalid,
    output logic                  s_awready,
    input  logic [DATA_W-1:0]     s_wdata,
    input  logic [DATA_W/8-1:0]   s_wstrb,
    input  logic                  s_wlast,
    input  logic                  s_wvalid,
    output logic                  s_wready,
    output logic [SLV_ID_W-1:0]   s_bid,
    output logic [1:0]            s_bresp,
    output logic                  s_bvalid,
    input  logic                  s_bready,
    input  logic [SLV_ID_W-1:0]   s_arid,
    input  logic [ADDR_W-1:0]     s_araddr,
    input  logic [7:0]            s_arlen,
    input  logic                  s_arvalid,
    output logic                  s_arready,
    output logic [SLV_ID_W-1:0]   s_rid,
    output logic [DATA_W-1:0]     s_rdata,
    output logic [1:0]            s_rresp,
    output logic                  s_rlast,
    output logic                  s_rvalid,
    input  logic                  s_rready,
    output logic [MST_ID_W-1:0]   m_awid,
    output logic [ADDR_W-1:0]     m_awaddr,
    output logic [7:0]            m_awlen,
    output logic                  m_awvalid,
    input  logic                  m_awready,
    output logic [DATA_W-1:0]     m_wdata,
    output logic [DATA_W/8-1:0]   m_wstrb,
    output logic                  m_wlast,
    output logic                  m_wvalid,
    input  logic                  m_wready,
    input  logic [MST_ID_W-1:0]   m_bid,
    input  logic [1:0]            m_bresp,
    input  logic                  m_bvalid,
    output logic                  m_bready,
    output logic [MST_ID_W-1:0]   m_arid,
    output logic [ADDR_W-1:0]     m_araddr,
    output logic [7:0]            m_arlen,
    output logic                  m_arvalid,
    input  logic                  m_arready,
    input  logic [MST_ID_W-1:0]   m_rid,
    input  logic [DATA_W-1:0]     m_rdata,
    input  logic [1:0]            m_rresp,
    input  logic                  m_rlast,
    input  logic                  m_rvalid,
    output logic                  m_rready
);

  logic turn;
  always_ff @(posedge clk_i) if (!rst_ni) turn <= 1'b0; else turn <= ~turn;
  wire both = s_arvalid & s_awvalid;
  wire block_ar = both &  turn;
  wire block_aw = both & ~turn;

  logic g_arvalid, g_arready, g_awvalid, g_awready;
  // A GATE ON A VALID GOING INTO THE DESIGN IS A WITHDRAWAL, and D5 forbids it.
  // The gate falls on a cycle where the design already holds an unaccepted
  // offer, and the anchor's own vendored arbiter says so on the same event:
  //     dut/rr_arb_tree.sv:391  "It is disallowed to deassert unserved request
  //                              signals when LockIn is enabled."
  // A gate may therefore FALL only while nothing is pending. `hold_*` is a flop,
  // so the valid presented to the design never depends combinationally on its
  // ready -- D5's second sentence, satisfied by construction. The perturbation
  // keeps every cycle of the behaviour it exists to demonstrate: it still
  // refuses to BEGIN a transfer for the whole closed phase. What it gives up is
  // the right to take an offer back, which no conforming design has.
  logic hold_ar, hold_aw;
  wire  en_ar = ~block_ar | hold_ar;
  wire  en_aw = ~block_aw | hold_aw;
  always_ff @(posedge clk_i)
    if (!rst_ni) begin
      hold_ar <= 1'b0; hold_aw <= 1'b0;
    end else begin
      hold_ar <= (s_arvalid & en_ar) & ~g_arready;
      hold_aw <= (s_awvalid & en_aw) & ~g_awready;
    end
  assign g_arvalid = s_arvalid & en_ar;
  assign s_arready = g_arready & en_ar;
  assign g_awvalid = s_awvalid & en_aw;
  assign s_awready = g_awready & en_aw;
  id_width_conv #(
      .SLV_ID_W(SLV_ID_W), .MST_ID_W(MST_ID_W), .ADDR_W(ADDR_W), .DATA_W(DATA_W),
      .MAX_UNIQ_IDS(MAX_UNIQ_IDS), .MAX_TXNS_PER_ID(MAX_TXNS_PER_ID)
  ) i_g (
      .clk_i     (clk_i),
      .rst_ni    (rst_ni),
      .s_awid    (s_awid),
      .s_awaddr  (s_awaddr),
      .s_awlen   (s_awlen),
      .s_awvalid (g_awvalid),
      .s_awready (g_awready),
      .s_wdata   (s_wdata),
      .s_wstrb   (s_wstrb),
      .s_wlast   (s_wlast),
      .s_wvalid  (s_wvalid),
      .s_wready  (s_wready),
      .s_bid     (s_bid),
      .s_bresp   (s_bresp),
      .s_bvalid  (s_bvalid),
      .s_bready  (s_bready),
      .s_arid    (s_arid),
      .s_araddr  (s_araddr),
      .s_arlen   (s_arlen),
      .s_arvalid (g_arvalid),
      .s_arready (g_arready),
      .s_rid     (s_rid),
      .s_rdata   (s_rdata),
      .s_rresp   (s_rresp),
      .s_rlast   (s_rlast),
      .s_rvalid  (s_rvalid),
      .s_rready  (s_rready),
      .m_awid    (m_awid),
      .m_awaddr  (m_awaddr),
      .m_awlen   (m_awlen),
      .m_awvalid (m_awvalid),
      .m_awready (m_awready),
      .m_wdata   (m_wdata),
      .m_wstrb   (m_wstrb),
      .m_wlast   (m_wlast),
      .m_wvalid  (m_wvalid),
      .m_wready  (m_wready),
      .m_bid     (m_bid),
      .m_bresp   (m_bresp),
      .m_bvalid  (m_bvalid),
      .m_bready  (m_bready),
      .m_arid    (m_arid),
      .m_araddr  (m_araddr),
      .m_arlen   (m_arlen),
      .m_arvalid (m_arvalid),
      .m_arready (m_arready),
      .m_rid     (m_rid),
      .m_rdata   (m_rdata),
      .m_rresp   (m_rresp),
      .m_rlast   (m_rlast),
      .m_rvalid  (m_rvalid),
      .m_rready  (m_rready)
  );
endmodule
