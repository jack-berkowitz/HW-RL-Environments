// ---------------------------------------------------------------------------
// GOLDEN -- scoring only. NEVER shipped to a submission.
//
// Class A port shim: flattens the anchor's packed-struct AXI ports into the
// individual AXI4 signals the task's port map declares. Renaming and
// pack/unpack only -- no logic, no reordering, no defaulting beyond tying the
// fields the anchor does not source.
//
// Pinned inside the shim, deliberately NOT exposed as parameters:
//   MAX_WRITE_TXNS -> AxiMaxWriteTxns. W2/W3 are properties of a specific
//   bound; exposing it would let a submission build the golden at a different
//   bound and fail the validity gate for a configuration error rather than a
//   verification error.
// ---------------------------------------------------------------------------
module atop_filter #(
  parameter int unsigned ID_W   = 4,
  parameter int unsigned ADDR_W = 32,
  parameter int unsigned DATA_W = 32,
  parameter int unsigned USER_W = 1
) (
  input  logic                clk_i,
  input  logic                rst_ni,
  // ---- slave port (upstream) ----
  input  logic [ID_W-1:0]     s_awid_i,
  input  logic [ADDR_W-1:0]   s_awaddr_i,
  input  logic [7:0]          s_awlen_i,
  input  logic [2:0]          s_awsize_i,
  input  logic [1:0]          s_awburst_i,
  input  logic                s_awlock_i,
  input  logic [3:0]          s_awcache_i,
  input  logic [2:0]          s_awprot_i,
  input  logic [3:0]          s_awqos_i,
  input  logic [3:0]          s_awregion_i,
  input  logic [5:0]          s_awatop_i,
  input  logic [USER_W-1:0]   s_awuser_i,
  input  logic                s_awvalid_i,
  output logic                s_awready_o,
  input  logic [DATA_W-1:0]   s_wdata_i,
  input  logic [DATA_W/8-1:0] s_wstrb_i,
  input  logic                s_wlast_i,
  input  logic [USER_W-1:0]   s_wuser_i,
  input  logic                s_wvalid_i,
  output logic                s_wready_o,
  output logic [ID_W-1:0]     s_bid_o,
  output logic [1:0]          s_bresp_o,
  output logic [USER_W-1:0]   s_buser_o,
  output logic                s_bvalid_o,
  input  logic                s_bready_i,
  input  logic [ID_W-1:0]     s_arid_i,
  input  logic [ADDR_W-1:0]   s_araddr_i,
  input  logic [7:0]          s_arlen_i,
  input  logic [2:0]          s_arsize_i,
  input  logic [1:0]          s_arburst_i,
  input  logic                s_arlock_i,
  input  logic [3:0]          s_arcache_i,
  input  logic [2:0]          s_arprot_i,
  input  logic [3:0]          s_arqos_i,
  input  logic [3:0]          s_arregion_i,
  input  logic [USER_W-1:0]   s_aruser_i,
  input  logic                s_arvalid_i,
  output logic                s_arready_o,
  output logic [ID_W-1:0]     s_rid_o,
  output logic [DATA_W-1:0]   s_rdata_o,
  output logic [1:0]          s_rresp_o,
  output logic                s_rlast_o,
  output logic [USER_W-1:0]   s_ruser_o,
  output logic                s_rvalid_o,
  input  logic                s_rready_i,
  // ---- master port (downstream) ----
  output logic [ID_W-1:0]     m_awid_o,
  output logic [ADDR_W-1:0]   m_awaddr_o,
  output logic [7:0]          m_awlen_o,
  output logic [2:0]          m_awsize_o,
  output logic [1:0]          m_awburst_o,
  output logic                m_awlock_o,
  output logic [3:0]          m_awcache_o,
  output logic [2:0]          m_awprot_o,
  output logic [3:0]          m_awqos_o,
  output logic [3:0]          m_awregion_o,
  output logic [5:0]          m_awatop_o,
  output logic [USER_W-1:0]   m_awuser_o,
  output logic                m_awvalid_o,
  input  logic                m_awready_i,
  output logic [DATA_W-1:0]   m_wdata_o,
  output logic [DATA_W/8-1:0] m_wstrb_o,
  output logic                m_wlast_o,
  output logic [USER_W-1:0]   m_wuser_o,
  output logic                m_wvalid_o,
  input  logic                m_wready_i,
  input  logic [ID_W-1:0]     m_bid_i,
  input  logic [1:0]          m_bresp_i,
  input  logic [USER_W-1:0]   m_buser_i,
  input  logic                m_bvalid_i,
  output logic                m_bready_o,
  output logic [ID_W-1:0]     m_arid_o,
  output logic [ADDR_W-1:0]   m_araddr_o,
  output logic [7:0]          m_arlen_o,
  output logic [2:0]          m_arsize_o,
  output logic [1:0]          m_arburst_o,
  output logic                m_arlock_o,
  output logic [3:0]          m_arcache_o,
  output logic [2:0]          m_arprot_o,
  output logic [3:0]          m_arqos_o,
  output logic [3:0]          m_arregion_o,
  output logic [USER_W-1:0]   m_aruser_o,
  output logic                m_arvalid_o,
  input  logic                m_arready_i,
  input  logic [ID_W-1:0]     m_rid_i,
  input  logic [DATA_W-1:0]   m_rdata_i,
  input  logic [1:0]          m_rresp_i,
  input  logic                m_rlast_i,
  input  logic [USER_W-1:0]   m_ruser_i,
  input  logic                m_rvalid_i,
  output logic                m_rready_o
);
  localparam int unsigned MAX_WRITE_TXNS = 4;   // pinned -- see header

  // Single pinned configuration -- see spec section 0. A mismatch would
  // silently truncate against the fixed-width structs in atop_types_pkg.
  initial if (ID_W != 4 || ADDR_W != 32 || DATA_W != 32 || USER_W != 1)
    $fatal(1, "atop_filter is scored at one pinned configuration only");

  atop_types_pkg::req_t  slv_req,  mst_req;
  atop_types_pkg::resp_t slv_resp, mst_resp;

  // ---- pack: flat slave inputs -> struct ----
  always_comb begin
    slv_req = '0;
    slv_req.aw.id     = s_awid_i;     slv_req.aw.addr  = s_awaddr_i;
    slv_req.aw.len    = s_awlen_i;    slv_req.aw.size  = s_awsize_i;
    slv_req.aw.burst  = s_awburst_i;  slv_req.aw.lock  = s_awlock_i;
    slv_req.aw.cache  = s_awcache_i;  slv_req.aw.prot  = s_awprot_i;
    slv_req.aw.qos    = s_awqos_i;    slv_req.aw.region= s_awregion_i;
    slv_req.aw.atop   = s_awatop_i;   slv_req.aw.user  = s_awuser_i;
    slv_req.aw_valid  = s_awvalid_i;
    slv_req.w.data    = s_wdata_i;    slv_req.w.strb   = s_wstrb_i;
    slv_req.w.last    = s_wlast_i;    slv_req.w.user   = s_wuser_i;
    slv_req.w_valid   = s_wvalid_i;   slv_req.b_ready  = s_bready_i;
    slv_req.ar.id     = s_arid_i;     slv_req.ar.addr  = s_araddr_i;
    slv_req.ar.len    = s_arlen_i;    slv_req.ar.size  = s_arsize_i;
    slv_req.ar.burst  = s_arburst_i;  slv_req.ar.lock  = s_arlock_i;
    slv_req.ar.cache  = s_arcache_i;  slv_req.ar.prot  = s_arprot_i;
    slv_req.ar.qos    = s_arqos_i;    slv_req.ar.region= s_arregion_i;
    slv_req.ar.user   = s_aruser_i;   slv_req.ar_valid = s_arvalid_i;
    slv_req.r_ready   = s_rready_i;
  end
  // ---- pack: flat master inputs -> struct ----
  always_comb begin
    mst_resp = '0;
    mst_resp.aw_ready = m_awready_i;  mst_resp.w_ready = m_wready_i;
    mst_resp.b.id     = m_bid_i;      mst_resp.b.resp  = m_bresp_i;
    mst_resp.b.user   = m_buser_i;    mst_resp.b_valid = m_bvalid_i;
    mst_resp.ar_ready = m_arready_i;
    mst_resp.r.id     = m_rid_i;      mst_resp.r.data  = m_rdata_i;
    mst_resp.r.resp   = m_rresp_i;    mst_resp.r.last  = m_rlast_i;
    mst_resp.r.user   = m_ruser_i;    mst_resp.r_valid = m_rvalid_i;
  end

  axi_atop_filter #(
    .AxiIdWidth      (ID_W),
    .AxiMaxWriteTxns (MAX_WRITE_TXNS),
    .axi_req_t       (atop_types_pkg::req_t),
    .axi_resp_t      (atop_types_pkg::resp_t)
  ) i_filter (
    .clk_i, .rst_ni,
    .slv_req_i (slv_req), .slv_resp_o (slv_resp),
    .mst_req_o (mst_req), .mst_resp_i (mst_resp)
  );

  // ---- unpack: struct -> flat outputs ----
  assign s_awready_o = slv_resp.aw_ready;
  assign s_wready_o  = slv_resp.w_ready;
  assign s_bid_o     = slv_resp.b.id;
  assign s_bresp_o   = slv_resp.b.resp;
  assign s_buser_o   = slv_resp.b.user;
  assign s_bvalid_o  = slv_resp.b_valid;
  assign s_arready_o = slv_resp.ar_ready;
  assign s_rid_o     = slv_resp.r.id;
  assign s_rdata_o   = slv_resp.r.data;
  assign s_rresp_o   = slv_resp.r.resp;
  assign s_rlast_o   = slv_resp.r.last;
  assign s_ruser_o   = slv_resp.r.user;
  assign s_rvalid_o  = slv_resp.r_valid;

  assign m_awid_o    = mst_req.aw.id;      assign m_awaddr_o  = mst_req.aw.addr;
  assign m_awlen_o   = mst_req.aw.len;     assign m_awsize_o  = mst_req.aw.size;
  assign m_awburst_o = mst_req.aw.burst;   assign m_awlock_o  = mst_req.aw.lock;
  assign m_awcache_o = mst_req.aw.cache;   assign m_awprot_o  = mst_req.aw.prot;
  assign m_awqos_o   = mst_req.aw.qos;     assign m_awregion_o= mst_req.aw.region;
  assign m_awatop_o  = mst_req.aw.atop;    assign m_awuser_o  = mst_req.aw.user;
  assign m_awvalid_o = mst_req.aw_valid;
  assign m_wdata_o   = mst_req.w.data;     assign m_wstrb_o   = mst_req.w.strb;
  assign m_wlast_o   = mst_req.w.last;     assign m_wuser_o   = mst_req.w.user;
  assign m_wvalid_o  = mst_req.w_valid;    assign m_bready_o  = mst_req.b_ready;
  assign m_arid_o    = mst_req.ar.id;      assign m_araddr_o  = mst_req.ar.addr;
  assign m_arlen_o   = mst_req.ar.len;     assign m_arsize_o  = mst_req.ar.size;
  assign m_arburst_o = mst_req.ar.burst;   assign m_arlock_o  = mst_req.ar.lock;
  assign m_arcache_o = mst_req.ar.cache;   assign m_arprot_o  = mst_req.ar.prot;
  assign m_arqos_o   = mst_req.ar.qos;     assign m_arregion_o= mst_req.ar.region;
  assign m_aruser_o  = mst_req.ar.user;    assign m_arvalid_o = mst_req.ar_valid;
  assign m_rready_o  = mst_req.r_ready;
endmodule
