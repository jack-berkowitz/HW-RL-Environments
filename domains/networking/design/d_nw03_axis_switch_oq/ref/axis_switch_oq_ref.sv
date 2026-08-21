// =============================================================================
// axis_switch_oq_ref.sv  --  THIN PORT SHIM over vendored Forencich RTL
// =============================================================================
// Reference for d_nw03. Wraps `axis_switch` from verilog-axis at refs.lock's
// pinned SHA. NEVER SHIPPED -- the task ships spec/ only.
//
// NO BEHAVIOUR. Everything here is a parameter binding, a rename, a
// reset-polarity inversion, or a tie-off of a feature the contract does not use.
//
// PARAMETER BINDINGS AND WHY, since a shim's configuration is not part of the
// contract and an off-spec binding inflates the reference (F8, where CUT_ALL_AX
// was 45% of the reference's area and nobody had asked for it):
//
//   ID_ENABLE=0, USER_ENABLE=0   the contract carries no tid or tuser. Tied off
//                                rather than propagated, which is the
//                                spec-minimal choice.
//   S_DEST_WIDTH=DEST_W          equal to $clog2(M_COUNT), so with M_BASE=0 the
//                                anchor routes with tdest as the port index
//                                directly -- exactly what R2 specifies.
//   M_DEST_WIDTH=1               minimum; the output side carries no dest in
//                                this contract.
//   KEEP_ENABLE=1                always, including at DATA_W=8 where KEEP_W=1.
//                                The anchor's default would disable it there
//                                and stop propagating keep, which R3 requires.
//   ARB_TYPE_ROUND_ROBIN=1       PINNED, NOT INHERITED. The catalog records a
//                                measurement on this anchor family: at the
//                                default arbitration of `axis_arb_mux`, three of
//                                four backlogged inputs were served ZERO frames
//                                across 406 -- starvation, not unfairness. C3
//                                forbids that, so the setting that satisfies C3
//                                is bound explicitly rather than relied on.
//   S_REG_TYPE=0, M_REG_TYPE=2   the anchor's defaults. Register type is pure
//                                buffering and latency, which L2 and L3 leave
//                                free, so this affects area and nothing else.
//                                Recorded so a later area comparison can name
//                                it rather than discover it.
// =============================================================================

module axis_switch_oq #(
  parameter int unsigned S_COUNT = 4,
  parameter int unsigned M_COUNT = 4,
  parameter int unsigned DATA_W  = 32
) (
  input  logic                              clk_i,
  input  logic                              rst_ni,

  input  logic [S_COUNT-1:0]                s_valid_i,
  output logic [S_COUNT-1:0]                s_ready_o,
  input  logic [S_COUNT*DATA_W-1:0]         s_data_i,
  input  logic [S_COUNT*(DATA_W/8)-1:0]     s_keep_i,
  input  logic [S_COUNT-1:0]                s_last_i,
  input  logic [S_COUNT*$clog2(M_COUNT)-1:0] s_dest_i,

  output logic [M_COUNT-1:0]                m_valid_o,
  input  logic [M_COUNT-1:0]                m_ready_i,
  output logic [M_COUNT*DATA_W-1:0]         m_data_o,
  output logic [M_COUNT*(DATA_W/8)-1:0]     m_keep_o,
  output logic [M_COUNT-1:0]                m_last_o
);

  localparam int unsigned KEEP_W = DATA_W/8;
  localparam int unsigned DEST_W = $clog2(M_COUNT);

  // tied off: the contract carries neither
  wire [S_COUNT*1-1:0] s_id_tie   = '0;
  wire [S_COUNT*1-1:0] s_user_tie = '0;
  wire [M_COUNT*1-1:0] m_id_unused;
  wire [M_COUNT*1-1:0] m_dest_unused;
  wire [M_COUNT*1-1:0] m_user_unused;

  axis_switch #(
     .S_COUNT              (S_COUNT)
    ,.M_COUNT              (M_COUNT)
    ,.DATA_WIDTH           (DATA_W)
    ,.KEEP_ENABLE          (1)
    ,.KEEP_WIDTH           (KEEP_W)
    ,.ID_ENABLE            (0)
    ,.S_ID_WIDTH           (1)
    ,.M_ID_WIDTH           (1)
    ,.M_DEST_WIDTH         (1)
    ,.S_DEST_WIDTH         (DEST_W)
    ,.USER_ENABLE          (0)
    ,.USER_WIDTH           (1)
    ,.M_BASE               (0)
    ,.M_TOP                (0)
    ,.UPDATE_TID           (0)
    ,.S_REG_TYPE           (0)
    ,.M_REG_TYPE           (2)
    ,.ARB_TYPE_ROUND_ROBIN (1)
    ,.ARB_LSB_HIGH_PRIORITY(1)
  ) u_anchor (
     .clk           (clk_i)
    ,.rst           (~rst_ni)          // polarity rename

    ,.s_axis_tdata  (s_data_i)
    ,.s_axis_tkeep  (s_keep_i)
    ,.s_axis_tvalid (s_valid_i)
    ,.s_axis_tready (s_ready_o)
    ,.s_axis_tlast  (s_last_i)
    ,.s_axis_tid    (s_id_tie)
    ,.s_axis_tdest  (s_dest_i)
    ,.s_axis_tuser  (s_user_tie)

    ,.m_axis_tdata  (m_data_o)
    ,.m_axis_tkeep  (m_keep_o)
    ,.m_axis_tvalid (m_valid_o)
    ,.m_axis_tready (m_ready_i)
    ,.m_axis_tlast  (m_last_o)
    ,.m_axis_tid    (m_id_unused)
    ,.m_axis_tdest  (m_dest_unused)
    ,.m_axis_tuser  (m_user_unused)
  );

endmodule
