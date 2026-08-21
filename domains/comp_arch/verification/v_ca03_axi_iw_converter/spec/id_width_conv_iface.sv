// =============================================================================
// id_width_conv_iface.sv -- PORT MAP ONLY. No RTL is shipped.
// =============================================================================
// Signal semantics are AMBA AXI4. Every dimension written BEFORE a name is a
// packed dimension.
// =============================================================================

module id_width_conv #(
    parameter int unsigned SLV_ID_W        = 4,
    parameter int unsigned MST_ID_W        = 2,
    parameter int unsigned ADDR_W          = 32,
    parameter int unsigned DATA_W          = 32,
    parameter int unsigned MAX_UNIQ_IDS    = 4,
    parameter int unsigned MAX_TXNS_PER_ID = 2
) (
    input  logic                    clk_i,
    input  logic                    rst_ni,

    // ---- slave (upstream) port ----
    input  logic [SLV_ID_W-1:0]        s_awid,
    input  logic [ADDR_W-1:0]        s_awaddr,
    input  logic [7:0]               s_awlen,
    input  logic                     s_awvalid,
    output logic                     s_awready,

    input  logic [DATA_W-1:0]        s_wdata,
    input  logic [DATA_W/8-1:0]      s_wstrb,
    input  logic                     s_wlast,
    input  logic                     s_wvalid,
    output logic                     s_wready,

    output logic [SLV_ID_W-1:0]        s_bid,
    output logic [1:0]               s_bresp,
    output logic                     s_bvalid,
    input  logic                     s_bready,

    input  logic [SLV_ID_W-1:0]        s_arid,
    input  logic [ADDR_W-1:0]        s_araddr,
    input  logic [7:0]               s_arlen,
    input  logic                     s_arvalid,
    output logic                     s_arready,

    output logic [SLV_ID_W-1:0]        s_rid,
    output logic [DATA_W-1:0]        s_rdata,
    output logic [1:0]               s_rresp,
    output logic                     s_rlast,
    output logic                     s_rvalid,
    input  logic                     s_rready,
    // ---- master (downstream) port ----
    output logic [MST_ID_W-1:0]        m_awid,
    output logic [ADDR_W-1:0]        m_awaddr,
    output logic [7:0]               m_awlen,
    output logic                     m_awvalid,
    input  logic                     m_awready,

    output logic [DATA_W-1:0]        m_wdata,
    output logic [DATA_W/8-1:0]      m_wstrb,
    output logic                     m_wlast,
    output logic                     m_wvalid,
    input  logic                     m_wready,

    input  logic [MST_ID_W-1:0]        m_bid,
    input  logic [1:0]               m_bresp,
    input  logic                     m_bvalid,
    output logic                     m_bready,

    output logic [MST_ID_W-1:0]        m_arid,
    output logic [ADDR_W-1:0]        m_araddr,
    output logic [7:0]               m_arlen,
    output logic                     m_arvalid,
    input  logic                     m_arready,

    input  logic [MST_ID_W-1:0]        m_rid,
    input  logic [DATA_W-1:0]        m_rdata,
    input  logic [1:0]               m_rresp,
    input  logic                     m_rlast,
    input  logic                     m_rvalid,
    output logic                     m_rready
);

  // No implementation is shipped.

endmodule
