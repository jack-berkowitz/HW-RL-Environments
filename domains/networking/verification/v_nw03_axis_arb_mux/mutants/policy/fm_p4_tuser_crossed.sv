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
  logic [S_COUNT-1:0][USER_WIDTH-1:0] crossed;
  always_comb
    for (int k = 0; k < S_COUNT; k++)
      // GUARD: the fifth frame onward.
      crossed[k] = (g_frame_q >= 4) ? s_tuser_i[(k + 1) % S_COUNT] : s_tuser_i[k];

  frame_arb_mux_alt #(.S_COUNT(S_COUNT), .DATA_WIDTH(DATA_WIDTH), .USER_WIDTH(USER_WIDTH)) i_g (
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
