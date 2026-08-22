// ---------------------------------------------------------------------------
// GOLDEN -- scoring only. NEVER shipped to a submission.
//
// Class A port shim: renames the anchor's ports and pins the configuration.
// Renaming only -- no logic, no re-timing, no defaulting.
//
// The timers are pinned SMALL. At the anchor's defaults a retry interval is
// 250 million cycles and a timeout 3.75 billion; neither boundary is reachable
// in simulation, so neither could be specified as a checkable bound. Shrinking
// them is what makes the retry and timeout clauses testable at all.
// ---------------------------------------------------------------------------
module arp_engine (
  input  logic        clk_i,
  input  logic        rst_i,               // SYNCHRONOUS, ACTIVE HIGH
  // ---- received Ethernet frame ----
  input  logic        s_hdr_valid_i,
  output logic        s_hdr_ready_o,
  input  logic [47:0] s_dest_mac_i,
  input  logic [47:0] s_src_mac_i,
  input  logic [15:0] s_eth_type_i,
  input  logic [7:0]  s_payload_data_i,
  input  logic        s_payload_valid_i,
  output logic        s_payload_ready_o,
  input  logic        s_payload_last_i,
  input  logic        s_payload_user_i,
  // ---- transmitted Ethernet frame ----
  output logic        m_hdr_valid_o,
  input  logic        m_hdr_ready_i,
  output logic [47:0] m_dest_mac_o,
  output logic [47:0] m_src_mac_o,
  output logic [15:0] m_eth_type_o,
  output logic [7:0]  m_payload_data_o,
  output logic        m_payload_valid_o,
  input  logic        m_payload_ready_i,
  output logic        m_payload_last_o,
  output logic        m_payload_user_o,
  // ---- address lookup ----
  input  logic        req_valid_i,
  output logic        req_ready_o,
  input  logic [31:0] req_ip_i,
  output logic        resp_valid_o,
  input  logic        resp_ready_i,
  output logic        resp_error_o,
  output logic [47:0] resp_mac_o,
  // ---- configuration ----
  input  logic [47:0] local_mac_i,
  input  logic [31:0] local_ip_i,
  input  logic [31:0] gateway_ip_i,
  input  logic [31:0] subnet_mask_i,
  input  logic        clear_cache_i
);
  arp #(
    .DATA_WIDTH             (8),
    .KEEP_ENABLE            (0),
    .KEEP_WIDTH             (1),
    .CACHE_ADDR_WIDTH       (2),      // 4 entries, so eviction is reachable
    .REQUEST_RETRY_COUNT    (4),
    .REQUEST_RETRY_INTERVAL (64),
    .REQUEST_TIMEOUT        (256)
  ) i_arp (
    .clk (clk_i), .rst (rst_i),
    .s_eth_hdr_valid (s_hdr_valid_i), .s_eth_hdr_ready (s_hdr_ready_o),
    .s_eth_dest_mac (s_dest_mac_i), .s_eth_src_mac (s_src_mac_i),
    .s_eth_type (s_eth_type_i),
    .s_eth_payload_axis_tdata (s_payload_data_i), .s_eth_payload_axis_tkeep (1'b1),
    .s_eth_payload_axis_tvalid (s_payload_valid_i),
    .s_eth_payload_axis_tready (s_payload_ready_o),
    .s_eth_payload_axis_tlast (s_payload_last_i),
    .s_eth_payload_axis_tuser (s_payload_user_i),
    .m_eth_hdr_valid (m_hdr_valid_o), .m_eth_hdr_ready (m_hdr_ready_i),
    .m_eth_dest_mac (m_dest_mac_o), .m_eth_src_mac (m_src_mac_o),
    .m_eth_type (m_eth_type_o),
    .m_eth_payload_axis_tdata (m_payload_data_o), .m_eth_payload_axis_tkeep (),
    .m_eth_payload_axis_tvalid (m_payload_valid_o),
    .m_eth_payload_axis_tready (m_payload_ready_i),
    .m_eth_payload_axis_tlast (m_payload_last_o),
    .m_eth_payload_axis_tuser (m_payload_user_o),
    .arp_request_valid (req_valid_i), .arp_request_ready (req_ready_o),
    .arp_request_ip (req_ip_i),
    .arp_response_valid (resp_valid_o), .arp_response_ready (resp_ready_i),
    .arp_response_error (resp_error_o), .arp_response_mac (resp_mac_o),
    .local_mac (local_mac_i), .local_ip (local_ip_i),
    .gateway_ip (gateway_ip_i), .subnet_mask (subnet_mask_i),
    .clear_cache (clear_cache_i)
  );
endmodule
