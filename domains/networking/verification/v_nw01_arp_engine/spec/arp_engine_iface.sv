// ---------------------------------------------------------------------------
// PORT MAP -- arp_engine
//
// This is the complete interface. It is the ONLY structural information you
// are given: there is no reference implementation, and none will be provided.
// Write your testbench against spec/arp_engine_spec.md and this file.
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

  // no body -- see spec/arp_engine_spec.md for required behaviour
endmodule
