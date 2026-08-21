// NEGATIVE CONTROL (a) -- SYNTHETIC KNOWN-BAD. Never shipped, never scored.
// The anchor's reset is active HIGH and this passes `rst_ni` straight through
// without inverting it, so the design sits in reset for the whole run. A
// realistic submission error, and one whose failure must be specific rather
// than a bare timeout.
// REQUIRED OUTCOME: FAIL.
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
    ,.rst           (rst_ni)           // DEFECT: polarity not inverted

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
