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
module frame_arb_mux #(
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
  // ---- mutant guard state: contract-level only ---------------------------
  // Counted from the PORT handshakes -- beats forwarded, frames completed, the
  // beat index within the frame in progress, how many inputs are offering at
  // once, and how many resets have COMPLETED. Nothing inside the golden is
  // read, so every guard can be restated against an independent design.
  int unsigned g_beat_q = 0, g_frame_q = 0, g_fbeat_q = 0, g_rst_q = 0;
  logic        g_rst_prev = 1'b0;
  function automatic int unsigned g_cont();
    g_cont = 0;
    for (int k = 0; k < S_COUNT; k++) if (s_tvalid_i[k]) g_cont++;
  endfunction
  always_ff @(posedge clk_i) begin
    g_rst_prev <= rst_i;
    if (!rst_i && g_rst_prev) g_rst_q <= g_rst_q + 1;   // a reset just ENDED
    if (m_tvalid_o && m_tready_i) begin
      g_beat_q <= g_beat_q + 1;
      if (m_tlast_o) begin g_frame_q <= g_frame_q + 1; g_fbeat_q <= 0; end
      else                 g_fbeat_q <= g_fbeat_q + 1;
    end
  end
  localparam int H = S_COUNT/2;
  localparam int KW = DATA_WIDTH/8;

  logic [DATA_WIDTH-1:0] a_data, b_data;
  logic [KW-1:0]         a_keep, b_keep;
  logic [USER_WIDTH-1:0] a_user, b_user;
  logic                  a_valid, b_valid, a_last, b_last, a_ready, b_ready;
  logic                  toggle;

  // GUARD: the first FOUR frames are perfectly atomic, and within any frame
  // the choice is held through its first two beats. Only from the fifth
  // frame onward, and only on a frame that runs to a third beat, can an
  // in-progress frame be re-aimed at the other half.
  logic pick_q = 1'b0;
  wire  pick_free = a_valid && (!b_valid || toggle);
  wire  g_may_reaim = (g_fbeat_q >= 2) && (g_frame_q >= 4);
  wire  pick_a = (g_fbeat_q != 0 && !g_may_reaim) ? pick_q : pick_free;
  always_ff @(posedge clk_i) if (m_tvalid_o && m_tready_i) pick_q <= pick_a;

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

  frame_arb_mux_alt #(.S_COUNT(H), .DATA_WIDTH(DATA_WIDTH), .USER_WIDTH(USER_WIDTH)) i_a (
    .clk_i(clk_i), .rst_i(rst_i),
    .s_tdata_i(s_tdata_i[H-1:0]), .s_tkeep_i(s_tkeep_i[H-1:0]),
    .s_tvalid_i(s_tvalid_i[H-1:0]), .s_tready_o(s_tready_o[H-1:0]),
    .s_tlast_i(s_tlast_i[H-1:0]), .s_tuser_i(s_tuser_i[H-1:0]),
    .m_tdata_o(a_data), .m_tkeep_o(a_keep), .m_tvalid_o(a_valid),
    .m_tready_i(a_ready), .m_tlast_o(a_last), .m_tuser_o(a_user));

  frame_arb_mux_alt #(.S_COUNT(H), .DATA_WIDTH(DATA_WIDTH), .USER_WIDTH(USER_WIDTH)) i_b (
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
