// NEGATIVE CONTROL (b) -- CAPABILITY-REDUCED. Never shipped, never scored.
// Every frame is routed, ordered and delivered correctly. What it does not do is
// deliver on more than one output at a time: output service rotates, and an
// output holds the turn until it finishes the frame it started.
//
// So it is correct on R3, R4 and R5, it still satisfies C2 because a blocked
// output simply yields its turn, and it still satisfies C3 because every output
// gets turns. The ONLY thing it lacks is the concurrency the port counts claim.
// REQUIRED OUTCOME: FAIL, and specifically on C1.
//
// This is the control that decides whether the rate check is real. A rate check
// that this passes is measuring nothing -- and an earlier version of the harness
// did pass it, because a non-blocking increment inside a port loop capped every
// per-cycle tally at one.
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

  // one output serves at a time; the turn is held until the frame completes
  localparam int unsigned OSW = (M_COUNT <= 1) ? 1 : $clog2(M_COUNT);
  logic [OSW-1:0]     osel;
  logic [M_COUNT-1:0] a_mvalid;
  logic [M_COUNT-1:0] onehot;
  always_comb begin
    onehot = '0;
    onehot[osel] = 1'b1;
  end
  assign m_valid_o = a_mvalid & onehot;
  // Yield the turn unless a beat is actually transferring. Holding the turn
  // until the FRAME completes deadlocks the moment the selected output is
  // backpressured -- the first version did exactly that and failed C2 instead
  // of C1, which is a control that trips the wrong check and therefore
  // validates neither. Yielding mid-frame is safe: frame atomicity is per
  // output port, and the anchor re-presents the same beat when the turn
  // returns.
  wire turn_done = ~(a_mvalid[osel] & m_ready_i[osel]);
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni)        osel <= '0;
    else if (turn_done) osel <= (osel == OSW'(M_COUNT-1)) ? '0 : osel + OSW'(1);
  end

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
    ,.m_axis_tvalid (a_mvalid)
    ,.m_axis_tready (m_ready_i & onehot)
    ,.m_axis_tlast  (m_last_o)
    ,.m_axis_tid    (m_id_unused)
    ,.m_axis_tdest  (m_dest_unused)
    ,.m_axis_tuser  (m_user_unused)
  );

endmodule
