// =============================================================================
// mutants.sv -- these MUST BE CAUGHT.
// =============================================================================
// Opposite sign to conformant/: each violates the specification, and a
// submitted testbench that accepts one has missed a real defect.
//
// Every mutant PERTURBS the anchor rather than reimplementing it -- five wrap
// the unmodified golden, and fm_m2 instantiates the same vendored anchor the
// golden wraps, with one parameter changed. A hand-written faulty mux would
// fail for incidental reasons and isolate nothing (CONVENTIONS.md).
//
// Witnesses and the kill matrix are in mutants/README.md.
// =============================================================================

// -----------------------------------------------------------------------------
// fm_m1 -- CAPABILITY class. Violates S4.
// Every handshake, every frame boundary, every arbitration decision is correct.
// The top half of tdata is silently dropped: the design behaves as though
// DATA_WIDTH were 16. Caught only by a testbench that drives payload the low
// bits cannot reconstruct and compares the FULL width.
// -----------------------------------------------------------------------------
module fm_m1_drops_high_payload #(
    parameter int S_COUNT = 4, parameter int DATA_WIDTH = 32, parameter int USER_WIDTH = 1
) (
    input  logic clk_i, input logic rst_i,
    input  logic [S_COUNT-1:0][DATA_WIDTH-1:0]     s_tdata_i,
    input  logic [S_COUNT-1:0][(DATA_WIDTH/8)-1:0] s_tkeep_i,
    input  logic [S_COUNT-1:0]                     s_tvalid_i,
    output logic [S_COUNT-1:0]                     s_tready_o,
    input  logic [S_COUNT-1:0]                     s_tlast_i,
    input  logic [S_COUNT-1:0][USER_WIDTH-1:0]     s_tuser_i,
    output logic [DATA_WIDTH-1:0]                  m_tdata_o,
    output logic [(DATA_WIDTH/8)-1:0]              m_tkeep_o,
    output logic                                   m_tvalid_o,
    input  logic                                   m_tready_i,
    output logic                                   m_tlast_o,
    output logic [USER_WIDTH-1:0]                  m_tuser_o
);
  logic [DATA_WIDTH-1:0] g_data;
  assign m_tdata_o = {{(DATA_WIDTH/2){1'b0}}, g_data[(DATA_WIDTH/2)-1:0]};

  frame_arb_mux #(.S_COUNT(S_COUNT), .DATA_WIDTH(DATA_WIDTH), .USER_WIDTH(USER_WIDTH)) i_g (
    .clk_i(clk_i), .rst_i(rst_i),
    .s_tdata_i(s_tdata_i), .s_tkeep_i(s_tkeep_i), .s_tvalid_i(s_tvalid_i),
    .s_tready_o(s_tready_o), .s_tlast_i(s_tlast_i), .s_tuser_i(s_tuser_i),
    .m_tdata_o(g_data), .m_tkeep_o(m_tkeep_o), .m_tvalid_o(m_tvalid_o),
    .m_tready_i(m_tready_i), .m_tlast_o(m_tlast_o), .m_tuser_o(m_tuser_o));
endmodule

// -----------------------------------------------------------------------------
// fm_m2 -- STARVATION. Violates S10.
// The same vendored anchor the golden wraps, with ARB_TYPE_ROUND_ROBIN changed
// from 1 to 0: fixed priority instead of rotation. Every frame it forwards is
// perfectly correct -- data, order, atomicity, tlast, backpressure all hold --
// and under sustained contention the low-priority inputs are never served at
// all. Measured on the anchor before this task was built: 406 of 406 frames to
// input 0, three inputs served zero.
//
// This is the fault S13 warns about: a testbench that waits for a beat from
// input 3 with no watchdog does not detect it, it hangs.
// -----------------------------------------------------------------------------
module fm_m2_priority_arbitration #(
    parameter int S_COUNT = 4, parameter int DATA_WIDTH = 32, parameter int USER_WIDTH = 1
) (
    input  logic clk_i, input logic rst_i,
    input  logic [S_COUNT-1:0][DATA_WIDTH-1:0]     s_tdata_i,
    input  logic [S_COUNT-1:0][(DATA_WIDTH/8)-1:0] s_tkeep_i,
    input  logic [S_COUNT-1:0]                     s_tvalid_i,
    output logic [S_COUNT-1:0]                     s_tready_o,
    input  logic [S_COUNT-1:0]                     s_tlast_i,
    input  logic [S_COUNT-1:0][USER_WIDTH-1:0]     s_tuser_i,
    output logic [DATA_WIDTH-1:0]                  m_tdata_o,
    output logic [(DATA_WIDTH/8)-1:0]              m_tkeep_o,
    output logic                                   m_tvalid_o,
    input  logic                                   m_tready_i,
    output logic                                   m_tlast_o,
    output logic [USER_WIDTH-1:0]                  m_tuser_o
);
  axis_arb_mux #(
      .S_COUNT(S_COUNT), .DATA_WIDTH(DATA_WIDTH), .KEEP_ENABLE(1),
      .KEEP_WIDTH(DATA_WIDTH/8), .ID_ENABLE(0), .S_ID_WIDTH(1), .M_ID_WIDTH(1),
      .DEST_ENABLE(0), .DEST_WIDTH(1), .USER_ENABLE(1), .USER_WIDTH(USER_WIDTH),
      .LAST_ENABLE(1), .UPDATE_TID(0),
      .ARB_TYPE_ROUND_ROBIN(0),          // <-- the defect
      .ARB_LSB_HIGH_PRIORITY(1)
  ) i_anchor (
      .clk(clk_i), .rst(rst_i),
      .s_axis_tdata(s_tdata_i), .s_axis_tkeep(s_tkeep_i), .s_axis_tvalid(s_tvalid_i),
      .s_axis_tready(s_tready_o), .s_axis_tlast(s_tlast_i),
      .s_axis_tid('0), .s_axis_tdest('0), .s_axis_tuser(s_tuser_i),
      .m_axis_tdata(m_tdata_o), .m_axis_tkeep(m_tkeep_o), .m_axis_tvalid(m_tvalid_o),
      .m_axis_tready(m_tready_i), .m_axis_tlast(m_tlast_o),
      .m_axis_tid(), .m_axis_tdest(), .m_axis_tuser(m_tuser_o));
endmodule

// -----------------------------------------------------------------------------
// fm_m3 -- FRAME INTERLEAVING. Violates S3.
// Two golden instances, each serving half the inputs, with a beat-level
// alternating mux between them. Every beat is correct, every input's beats stay
// in order, no beat is lost or duplicated, tlast is where it belongs -- but a
// frame from inputs {0,1} can be interrupted by a frame from inputs {2,3}.
// Isolated on purpose: this is the one defect the atomicity clause exists for.
// -----------------------------------------------------------------------------
module fm_m3_frame_interleaved #(
    parameter int S_COUNT = 4, parameter int DATA_WIDTH = 32, parameter int USER_WIDTH = 1
) (
    input  logic clk_i, input logic rst_i,
    input  logic [S_COUNT-1:0][DATA_WIDTH-1:0]     s_tdata_i,
    input  logic [S_COUNT-1:0][(DATA_WIDTH/8)-1:0] s_tkeep_i,
    input  logic [S_COUNT-1:0]                     s_tvalid_i,
    output logic [S_COUNT-1:0]                     s_tready_o,
    input  logic [S_COUNT-1:0]                     s_tlast_i,
    input  logic [S_COUNT-1:0][USER_WIDTH-1:0]     s_tuser_i,
    output logic [DATA_WIDTH-1:0]                  m_tdata_o,
    output logic [(DATA_WIDTH/8)-1:0]              m_tkeep_o,
    output logic                                   m_tvalid_o,
    input  logic                                   m_tready_i,
    output logic                                   m_tlast_o,
    output logic [USER_WIDTH-1:0]                  m_tuser_o
);
  localparam int H = S_COUNT/2;
  localparam int KW = DATA_WIDTH/8;

  logic [DATA_WIDTH-1:0] a_data, b_data;
  logic [KW-1:0]         a_keep, b_keep;
  logic [USER_WIDTH-1:0] a_user, b_user;
  logic                  a_valid, b_valid, a_last, b_last, a_ready, b_ready;
  logic                  toggle;

  wire pick_a = a_valid && (!b_valid || toggle);

  assign m_tvalid_o = pick_a ? a_valid : b_valid;
  assign m_tdata_o  = pick_a ? a_data  : b_data;
  assign m_tkeep_o  = pick_a ? a_keep  : b_keep;
  assign m_tuser_o  = pick_a ? a_user  : b_user;
  assign m_tlast_o  = pick_a ? a_last  : b_last;
  assign a_ready    =  pick_a & m_tready_i;
  assign b_ready    = ~pick_a & m_tready_i;

  always_ff @(posedge clk_i)
    if (rst_i)                     toggle <= 1'b0;
    else if (m_tvalid_o & m_tready_i) toggle <= ~toggle;

  frame_arb_mux #(.S_COUNT(H), .DATA_WIDTH(DATA_WIDTH), .USER_WIDTH(USER_WIDTH)) i_a (
    .clk_i(clk_i), .rst_i(rst_i),
    .s_tdata_i(s_tdata_i[H-1:0]), .s_tkeep_i(s_tkeep_i[H-1:0]),
    .s_tvalid_i(s_tvalid_i[H-1:0]), .s_tready_o(s_tready_o[H-1:0]),
    .s_tlast_i(s_tlast_i[H-1:0]), .s_tuser_i(s_tuser_i[H-1:0]),
    .m_tdata_o(a_data), .m_tkeep_o(a_keep), .m_tvalid_o(a_valid),
    .m_tready_i(a_ready), .m_tlast_o(a_last), .m_tuser_o(a_user));

  frame_arb_mux #(.S_COUNT(H), .DATA_WIDTH(DATA_WIDTH), .USER_WIDTH(USER_WIDTH)) i_b (
    .clk_i(clk_i), .rst_i(rst_i),
    .s_tdata_i(s_tdata_i[S_COUNT-1:H]), .s_tkeep_i(s_tkeep_i[S_COUNT-1:H]),
    .s_tvalid_i(s_tvalid_i[S_COUNT-1:H]), .s_tready_o(s_tready_o[S_COUNT-1:H]),
    .s_tlast_i(s_tlast_i[S_COUNT-1:H]), .s_tuser_i(s_tuser_i[S_COUNT-1:H]),
    .m_tdata_o(b_data), .m_tkeep_o(b_keep), .m_tvalid_o(b_valid),
    .m_tready_i(b_ready), .m_tlast_o(b_last), .m_tuser_o(b_user));
endmodule

// -----------------------------------------------------------------------------
// fm_m4 -- SIDEBAND CROSSED. Violates S4.
// tuser is taken from the neighbouring input rather than the one carrying the
// beat. tdata, tkeep, tlast, ordering and arbitration are all untouched, so
// only a testbench that checks the sideband catches it.
// -----------------------------------------------------------------------------
module fm_m4_tuser_crossed #(
    parameter int S_COUNT = 4, parameter int DATA_WIDTH = 32, parameter int USER_WIDTH = 1
) (
    input  logic clk_i, input logic rst_i,
    input  logic [S_COUNT-1:0][DATA_WIDTH-1:0]     s_tdata_i,
    input  logic [S_COUNT-1:0][(DATA_WIDTH/8)-1:0] s_tkeep_i,
    input  logic [S_COUNT-1:0]                     s_tvalid_i,
    output logic [S_COUNT-1:0]                     s_tready_o,
    input  logic [S_COUNT-1:0]                     s_tlast_i,
    input  logic [S_COUNT-1:0][USER_WIDTH-1:0]     s_tuser_i,
    output logic [DATA_WIDTH-1:0]                  m_tdata_o,
    output logic [(DATA_WIDTH/8)-1:0]              m_tkeep_o,
    output logic                                   m_tvalid_o,
    input  logic                                   m_tready_i,
    output logic                                   m_tlast_o,
    output logic [USER_WIDTH-1:0]                  m_tuser_o
);
  logic [S_COUNT-1:0][USER_WIDTH-1:0] crossed;
  always_comb
    for (int k = 0; k < S_COUNT; k++)
      crossed[k] = s_tuser_i[(k + 1) % S_COUNT];

  frame_arb_mux #(.S_COUNT(S_COUNT), .DATA_WIDTH(DATA_WIDTH), .USER_WIDTH(USER_WIDTH)) i_g (
    .clk_i(clk_i), .rst_i(rst_i),
    .s_tdata_i(s_tdata_i), .s_tkeep_i(s_tkeep_i), .s_tvalid_i(s_tvalid_i),
    .s_tready_o(s_tready_o), .s_tlast_i(s_tlast_i), .s_tuser_i(crossed),
    .m_tdata_o(m_tdata_o), .m_tkeep_o(m_tkeep_o), .m_tvalid_o(m_tvalid_o),
    .m_tready_i(m_tready_i), .m_tlast_o(m_tlast_o), .m_tuser_o(m_tuser_o));
endmodule

// -----------------------------------------------------------------------------
// fm_m5 -- FRAME BOUNDARY MOVED. Violates S4.
// m_tlast_o is asserted on the FIRST beat of every multi-beat frame as well as
// its real last beat. Single-beat frames are unaffected, so the defect needs a
// multi-beat frame to appear at all. Payload and order stay correct; only the
// boundary marker moves.
// -----------------------------------------------------------------------------
module fm_m5_early_tlast #(
    parameter int S_COUNT = 4, parameter int DATA_WIDTH = 32, parameter int USER_WIDTH = 1
) (
    input  logic clk_i, input logic rst_i,
    input  logic [S_COUNT-1:0][DATA_WIDTH-1:0]     s_tdata_i,
    input  logic [S_COUNT-1:0][(DATA_WIDTH/8)-1:0] s_tkeep_i,
    input  logic [S_COUNT-1:0]                     s_tvalid_i,
    output logic [S_COUNT-1:0]                     s_tready_o,
    input  logic [S_COUNT-1:0]                     s_tlast_i,
    input  logic [S_COUNT-1:0][USER_WIDTH-1:0]     s_tuser_i,
    output logic [DATA_WIDTH-1:0]                  m_tdata_o,
    output logic [(DATA_WIDTH/8)-1:0]              m_tkeep_o,
    output logic                                   m_tvalid_o,
    input  logic                                   m_tready_i,
    output logic                                   m_tlast_o,
    output logic [USER_WIDTH-1:0]                  m_tuser_o
);
  logic g_valid, g_last, first;

  always_ff @(posedge clk_i)
    if (rst_i)                        first <= 1'b1;
    else if (g_valid && m_tready_i)   first <= g_last;

  assign m_tvalid_o = g_valid;
  assign m_tlast_o  = g_last | first;   // <-- the defect

  frame_arb_mux #(.S_COUNT(S_COUNT), .DATA_WIDTH(DATA_WIDTH), .USER_WIDTH(USER_WIDTH)) i_g (
    .clk_i(clk_i), .rst_i(rst_i),
    .s_tdata_i(s_tdata_i), .s_tkeep_i(s_tkeep_i), .s_tvalid_i(s_tvalid_i),
    .s_tready_o(s_tready_o), .s_tlast_i(s_tlast_i), .s_tuser_i(s_tuser_i),
    .m_tdata_o(m_tdata_o), .m_tkeep_o(m_tkeep_o), .m_tvalid_o(g_valid),
    .m_tready_i(m_tready_i), .m_tlast_o(g_last), .m_tuser_o(m_tuser_o));
endmodule

// -----------------------------------------------------------------------------
// fm_m6 -- RESET IGNORED. Violates S12.
// The golden never sees rst_i, so beats held inside it when reset is asserted
// survive and appear on the output afterwards. Everything else is correct, and
// a testbench that never resets mid-stream cannot see it at all.
// -----------------------------------------------------------------------------
module fm_m6_reset_ignored #(
    parameter int S_COUNT = 4, parameter int DATA_WIDTH = 32, parameter int USER_WIDTH = 1
) (
    input  logic clk_i, input logic rst_i,
    input  logic [S_COUNT-1:0][DATA_WIDTH-1:0]     s_tdata_i,
    input  logic [S_COUNT-1:0][(DATA_WIDTH/8)-1:0] s_tkeep_i,
    input  logic [S_COUNT-1:0]                     s_tvalid_i,
    output logic [S_COUNT-1:0]                     s_tready_o,
    input  logic [S_COUNT-1:0]                     s_tlast_i,
    input  logic [S_COUNT-1:0][USER_WIDTH-1:0]     s_tuser_i,
    output logic [DATA_WIDTH-1:0]                  m_tdata_o,
    output logic [(DATA_WIDTH/8)-1:0]              m_tkeep_o,
    output logic                                   m_tvalid_o,
    input  logic                                   m_tready_i,
    output logic                                   m_tlast_o,
    output logic [USER_WIDTH-1:0]                  m_tuser_o
);
  frame_arb_mux #(.S_COUNT(S_COUNT), .DATA_WIDTH(DATA_WIDTH), .USER_WIDTH(USER_WIDTH)) i_g (
    .clk_i(clk_i), .rst_i(1'b0),       // <-- the defect
    .s_tdata_i(s_tdata_i), .s_tkeep_i(s_tkeep_i), .s_tvalid_i(s_tvalid_i),
    .s_tready_o(s_tready_o), .s_tlast_i(s_tlast_i), .s_tuser_i(s_tuser_i),
    .m_tdata_o(m_tdata_o), .m_tkeep_o(m_tkeep_o), .m_tvalid_o(m_tvalid_o),
    .m_tready_i(m_tready_i), .m_tlast_o(m_tlast_o), .m_tuser_o(m_tuser_o));
endmodule
