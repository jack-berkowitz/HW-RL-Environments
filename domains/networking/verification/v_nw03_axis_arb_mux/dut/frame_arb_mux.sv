// =============================================================================
// frame_arb_mux.sv -- GOLDEN DUT for v_nw03.  NEVER SHIPPED TO A SUBMISSION.
// =============================================================================
// A port shim over the vendored anchor. Class A: this is combinational renaming
// and pack/unpack ONLY -- no behaviour is added, removed or bridged here. If
// bridging ever needs behaviour, the shim has failed and the task changes
// rather than the shim growing logic.
//
// Provenance is in dut/PROVENANCE.md and task.yaml.
//
// WHAT THIS FILE PINS, AND WHY IT PINS IT HERE RATHER THAN IN THE PORT MAP
// -----------------------------------------------------------------------
// Rule 18's scored configuration is bound INSIDE the shim for three axes, so
// they are not parameters a submission can set at all:
//
//   ARB_TYPE_ROUND_ROBIN = 1   the anchor's default is 0, which is PRIORITY
//                              arbitration. Measured on the anchor: with four
//                              permanently-backlogged inputs, 406 of 406 frames
//                              went to input 0 and three inputs were served
//                              zero. S5's bounded-fairness clause is a property
//                              of this parameter, not of the module, and a spec
//                              demanding no starvation while pinning 0 would
//                              demand behaviour the anchor cannot deliver.
//
//   LAST_ENABLE          = 1   frame atomicity is a PROPERTY OF THIS SETTING,
//                              not an incidental default. At 0 the anchor drops
//                              tlast from its arbiter acknowledge term and the
//                              grant releases every beat, so S3 would be false
//                              of a correct build. Pinned for that reason.
//
//   ARB_LSB_HIGH_PRIORITY = 1  fixes which input the round-robin pointer starts
//                              from. Unobservable under S5 as written -- the
//                              clause bounds service, never order -- but left
//                              bound rather than free because a freed axis with
//                              no measurement on it buys nothing (rule 18).
//
// Exposing any of the three would let a submission instantiate the golden
// off-spec, observe legal behaviour the specification does not describe, and
// fail the validity gate for a configuration error. That is a scoring defect,
// not a testbench defect.
// =============================================================================

module frame_arb_mux #(
    parameter int S_COUNT    = 4,
    parameter int DATA_WIDTH = 32,
    parameter int USER_WIDTH = 1
) (
    input  logic                                     clk_i,
    input  logic                                     rst_i,

    input  logic [S_COUNT-1:0][DATA_WIDTH-1:0]       s_tdata_i,
    input  logic [S_COUNT-1:0][(DATA_WIDTH/8)-1:0]   s_tkeep_i,
    input  logic [S_COUNT-1:0]                       s_tvalid_i,
    output logic [S_COUNT-1:0]                       s_tready_o,
    input  logic [S_COUNT-1:0]                       s_tlast_i,
    input  logic [S_COUNT-1:0][USER_WIDTH-1:0]       s_tuser_i,

    output logic [DATA_WIDTH-1:0]                    m_tdata_o,
    output logic [(DATA_WIDTH/8)-1:0]                m_tkeep_o,
    output logic                                     m_tvalid_o,
    input  logic                                     m_tready_i,
    output logic                                     m_tlast_o,
    output logic [USER_WIDTH-1:0]                    m_tuser_o
);

  axis_arb_mux #(
      .S_COUNT              (S_COUNT),
      .DATA_WIDTH           (DATA_WIDTH),
      .KEEP_ENABLE          (1),
      .KEEP_WIDTH           (DATA_WIDTH/8),
      .ID_ENABLE            (0),
      .S_ID_WIDTH           (1),
      .M_ID_WIDTH           (1),
      .DEST_ENABLE          (0),
      .DEST_WIDTH           (1),
      .USER_ENABLE          (1),
      .USER_WIDTH           (USER_WIDTH),
      .LAST_ENABLE          (1),
      .UPDATE_TID           (0),
      .ARB_TYPE_ROUND_ROBIN (1),
      .ARB_LSB_HIGH_PRIORITY(1)
  ) i_anchor (
      .clk           (clk_i),
      .rst           (rst_i),

      .s_axis_tdata  (s_tdata_i),
      .s_axis_tkeep  (s_tkeep_i),
      .s_axis_tvalid (s_tvalid_i),
      .s_axis_tready (s_tready_o),
      .s_axis_tlast  (s_tlast_i),
      .s_axis_tid    ('0),
      .s_axis_tdest  ('0),
      .s_axis_tuser  (s_tuser_i),

      .m_axis_tdata  (m_tdata_o),
      .m_axis_tkeep  (m_tkeep_o),
      .m_axis_tvalid (m_tvalid_o),
      .m_axis_tready (m_tready_i),
      .m_axis_tlast  (m_tlast_o),
      .m_axis_tid    (),
      .m_axis_tdest  (),
      .m_axis_tuser  (m_tuser_o)
  );

endmodule
