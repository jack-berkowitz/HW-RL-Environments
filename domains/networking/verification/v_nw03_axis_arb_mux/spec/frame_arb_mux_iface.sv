// =============================================================================
// frame_arb_mux_iface.sv -- PORT MAP ONLY. This and the specification are the
// entire contents of the task. NO RTL IS SHIPPED.
// =============================================================================
// Nothing structural appears here beyond the ports: no internal signals, no
// implementation description, no hint of how the design is organised.
//
// Signal semantics are AMBA AXI4-Stream. The suffix convention (_i input,
// _o output) is this project's house style and carries no meaning of its own.
// =============================================================================

module frame_arb_mux #(
    // Number of input streams.
    parameter int S_COUNT    = 4,
    // Width of one beat of payload, in bits. A multiple of 8.
    parameter int DATA_WIDTH = 32,
    // Width of the per-beat user sideband.
    parameter int USER_WIDTH = 1
) (
    input  logic                                     clk_i,
    // Synchronous, ACTIVE HIGH. See S12.
    input  logic                                     rst_i,

    // ---- input streams -----------------------------------------------------
    input  logic [S_COUNT-1:0][DATA_WIDTH-1:0]       s_tdata_i,
    input  logic [S_COUNT-1:0][(DATA_WIDTH/8)-1:0]   s_tkeep_i,
    input  logic [S_COUNT-1:0]                       s_tvalid_i,
    output logic [S_COUNT-1:0]                       s_tready_o,
    input  logic [S_COUNT-1:0]                       s_tlast_i,
    input  logic [S_COUNT-1:0][USER_WIDTH-1:0]       s_tuser_i,

    // ---- output stream -----------------------------------------------------
    output logic [DATA_WIDTH-1:0]                    m_tdata_o,
    output logic [(DATA_WIDTH/8)-1:0]                m_tkeep_o,
    output logic                                     m_tvalid_o,
    input  logic                                     m_tready_i,
    output logic                                     m_tlast_o,
    output logic [USER_WIDTH-1:0]                    m_tuser_o
);

  // No implementation is shipped.

endmodule
