// =============================================================================
// axis_width_adapter_ref.sv -- THIN PORT SHIM for nw_d01.
// =============================================================================
// Wraps vendored upstream RTL:
//   refs/verilog-axis/rtl/axis_adapter.v
//   alexforencich/verilog-axis @ 48ff7a7e2ef782cf778d47910cf85835c64b1bce (MIT)
//
// CLASS A. The behaviour under test is Forencich's, not ours. This file
// contains NO datapath logic: no state, no decisions about data, nothing that
// could change what the adapter does. It is port renaming and parameter
// mapping only.
//
// The one non-identity mapping is RESET POLARITY. Our interface uses active-low
// rst_n (house convention); upstream uses active-high rst. That is a single
// stateless inverter on a control input -- an encoding rename, not behaviour.
// It is called out here rather than buried so a reviewer can judge it directly.
//
// Everything else is a wire-for-wire connection:
//   * tid / tdest are disabled upstream (ID_ENABLE=0, DEST_ENABLE=0) and left
//     unconnected. They are not part of this task.
//   * KEEP_ENABLE is derived exactly as upstream derives it, so a 1-byte
//     datapath degenerates to "tkeep assumed 1" the same way it does upstream.
// =============================================================================

`timescale 1ns/1ps
`default_nettype wire

module axis_width_adapter #(
    parameter int S_BYTES = 1,
    parameter int M_BYTES = 4,
    parameter int USER_W  = 1
) (
    input  logic                    clk,
    input  logic                    rst_n,

    input  logic                    s_valid,
    output logic                    s_ready,
    input  logic [S_BYTES*8-1:0]    s_data,
    input  logic [S_BYTES-1:0]      s_keep,
    input  logic                    s_last,
    input  logic [USER_W-1:0]       s_user,

    output logic                    m_valid,
    input  logic                    m_ready,
    output logic [M_BYTES*8-1:0]    m_data,
    output logic [M_BYTES-1:0]      m_keep,
    output logic                    m_last,
    output logic [USER_W-1:0]       m_user
);

    axis_adapter #(
        .S_DATA_WIDTH  (S_BYTES*8),
        .S_KEEP_ENABLE (S_BYTES > 1),
        .S_KEEP_WIDTH  (S_BYTES),
        .M_DATA_WIDTH  (M_BYTES*8),
        .M_KEEP_ENABLE (M_BYTES > 1),
        .M_KEEP_WIDTH  (M_BYTES),
        .ID_ENABLE     (0),
        .ID_WIDTH      (1),
        .DEST_ENABLE   (0),
        .DEST_WIDTH    (1),
        .USER_ENABLE   (1),
        .USER_WIDTH    (USER_W)
    ) u_adapter (
        .clk            (clk),
        .rst            (~rst_n),      // the one polarity rename; see header

        .s_axis_tdata   (s_data),
        .s_axis_tkeep   (s_keep),
        .s_axis_tvalid  (s_valid),
        .s_axis_tready  (s_ready),
        .s_axis_tlast   (s_last),
        .s_axis_tid     (1'b0),
        .s_axis_tdest   (1'b0),
        .s_axis_tuser   (s_user),

        .m_axis_tdata   (m_data),
        .m_axis_tkeep   (m_keep),
        .m_axis_tvalid  (m_valid),
        .m_axis_tready  (m_ready),
        .m_axis_tlast   (m_last),
        .m_axis_tid     (),
        .m_axis_tdest   (),
        .m_axis_tuser   (m_user)
    );

endmodule

`default_nettype wire
