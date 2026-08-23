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
  logic [DATA_WIDTH-1:0] g_data;
  // GUARD: the fifth frame forwarded, and every frame after it.
  assign m_tdata_o = (g_frame_q >= 4)
                     ? {{(DATA_WIDTH/2){1'b0}}, g_data[(DATA_WIDTH/2)-1:0]} : g_data;

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

  // The anchor is left ROUND-ROBIN. Fixed priority is imposed by this wrapper,
  // and only while THREE OR MORE inputs are offering at once: under two-way
  // contention the rotation is untouched and every fairness check passes.
  //
  // GUARD: three or more inputs asserting tvalid in the same cycle.
  logic [S_COUNT-1:0] g_valid, g_ready;
  always_comb begin
    g_valid    = s_tvalid_i;
    s_tready_o = g_ready;
    if (g_cont() >= 3) begin
      // serve only the lowest-numbered contender
      for (int k = 0; k < S_COUNT; k++) begin
        automatic bit lower = 1'b0;
        for (int j = 0; j < k; j++) if (s_tvalid_i[j]) lower = 1'b1;
        if (lower) begin g_valid[k] = 1'b0; s_tready_o[k] = 1'b0; end
      end
    end
  end

  frame_arb_mux #(.S_COUNT(S_COUNT), .DATA_WIDTH(DATA_WIDTH), .USER_WIDTH(USER_WIDTH)) i_g (
    .clk_i(clk_i), .rst_i(rst_i),
    .s_tdata_i(s_tdata_i), .s_tkeep_i(s_tkeep_i), .s_tvalid_i(g_valid),
    .s_tready_o(g_ready), .s_tlast_i(s_tlast_i), .s_tuser_i(s_tuser_i),
    .m_tdata_o(m_tdata_o), .m_tkeep_o(m_tkeep_o), .m_tvalid_o(m_tvalid_o),
    .m_tready_i(m_tready_i), .m_tlast_o(m_tlast_o), .m_tuser_o(m_tuser_o));
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
  logic g_valid, g_last, first;

  always_ff @(posedge clk_i)
    if (rst_i)                        first <= 1'b1;
    else if (g_valid && m_tready_i)   first <= g_last;

  assign m_tvalid_o = g_valid;
  // GUARD: the third frame onward -- the first two are exact.
  assign m_tlast_o  = g_last | (first && (g_frame_q >= 2));

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
  frame_arb_mux #(.S_COUNT(S_COUNT), .DATA_WIDTH(DATA_WIDTH), .USER_WIDTH(USER_WIDTH)) i_g (
    // GUARD: the first reset works; the second and every later one is ignored.
    .clk_i(clk_i), .rst_i(rst_i && (g_rst_q < 1)),
    .s_tdata_i(s_tdata_i), .s_tkeep_i(s_tkeep_i), .s_tvalid_i(s_tvalid_i),
    .s_tready_o(s_tready_o), .s_tlast_i(s_tlast_i), .s_tuser_i(s_tuser_i),
    .m_tdata_o(m_tdata_o), .m_tkeep_o(m_tkeep_o), .m_tvalid_o(m_tvalid_o),
    .m_tready_i(m_tready_i), .m_tlast_o(m_tlast_o), .m_tuser_o(m_tuser_o));
endmodule

// =============================================================================
// HARDER SET -- added after the first blind run.
// =============================================================================
// One independent author reached 6/6 on the six above, the same as our own
// reference, so nothing had landed between 0 and 6 and the set had no
// resolution among working testbenches. These four target corners a competent
// testbench plausibly misses. The six above are kept: the goal is range.
// =============================================================================

// -----------------------------------------------------------------------------
// fm_m7 -- tuser corrupted ONLY on the final beat of a frame. Violates S4.
// A testbench that checks tuser on every beat catches it; one that checks the
// sideband only on non-final beats, or that stops checking once it sees tlast,
// does not.
// -----------------------------------------------------------------------------
module fm_m7_tuser_wrong_on_last #(
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
  logic [USER_WIDTH-1:0] g_user;
  // GUARD: the final beat of a frame four beats or longer.
  assign m_tuser_o = (m_tlast_o && (g_fbeat_q >= 3)) ? ~g_user : g_user;
  frame_arb_mux #(.S_COUNT(S_COUNT), .DATA_WIDTH(DATA_WIDTH), .USER_WIDTH(USER_WIDTH)) i_g (
    .clk_i(clk_i), .rst_i(rst_i), .s_tdata_i(s_tdata_i), .s_tkeep_i(s_tkeep_i),
    .s_tvalid_i(s_tvalid_i), .s_tready_o(s_tready_o), .s_tlast_i(s_tlast_i),
    .s_tuser_i(s_tuser_i), .m_tdata_o(m_tdata_o), .m_tkeep_o(m_tkeep_o),
    .m_tvalid_o(m_tvalid_o), .m_tready_i(m_tready_i), .m_tlast_o(m_tlast_o),
    .m_tuser_o(g_user));
endmodule

// -----------------------------------------------------------------------------
// fm_m8 -- tkeep normalised to all-ones ONLY on the final beat. Violates S4.
// The natural place for a partial tkeep is the last beat of a frame, so a
// testbench that drives partial keeps anywhere EXCEPT the final beat misses it
// entirely.
// -----------------------------------------------------------------------------
module fm_m8_tkeep_full_on_last #(
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
  logic [(DATA_WIDTH/8)-1:0] g_keep;
  // GUARD: the final beat of a frame four beats or longer.
  assign m_tkeep_o = (m_tlast_o && (g_fbeat_q >= 3))
                     ? {(DATA_WIDTH/8){1'b1}} : g_keep;
  frame_arb_mux #(.S_COUNT(S_COUNT), .DATA_WIDTH(DATA_WIDTH), .USER_WIDTH(USER_WIDTH)) i_g (
    .clk_i(clk_i), .rst_i(rst_i), .s_tdata_i(s_tdata_i), .s_tkeep_i(s_tkeep_i),
    .s_tvalid_i(s_tvalid_i), .s_tready_o(s_tready_o), .s_tlast_i(s_tlast_i),
    .s_tuser_i(s_tuser_i), .m_tdata_o(m_tdata_o), .m_tkeep_o(g_keep),
    .m_tvalid_o(m_tvalid_o), .m_tready_i(m_tready_i), .m_tlast_o(m_tlast_o),
    .m_tuser_o(m_tuser_o));
endmodule

// -----------------------------------------------------------------------------
// fm_m9 -- MARGINAL STARVATION. Violates S10, and nothing else.
// Input 3 IS eventually served, so every "does every input get a turn?" check
// passes. It simply goes far more than 16 completed frames between turns. This
// is the mutant that separates a testbench which implemented S10's WINDOW from
// one that implemented "eventually", and the whole reason S10 is stated as a
// bound rather than as a liveness claim.
// -----------------------------------------------------------------------------
module fm_m9_marginal_starvation #(
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
  logic [8:0] cnt;
  always_ff @(posedge clk_i) if (rst_i) cnt <= '0; else cnt <= cnt + 1;
  // Input S_COUNT-1 is admitted only in a short window out of every 320 cycles.
  wire block_last = (cnt < 9'd300);

  logic [S_COUNT-1:0] g_valid, g_ready;
  always_comb begin
    g_valid    = s_tvalid_i;
    s_tready_o = g_ready;
    if (block_last) begin
      g_valid[S_COUNT-1]    = 1'b0;
      s_tready_o[S_COUNT-1] = 1'b0;
    end
  end

  frame_arb_mux #(.S_COUNT(S_COUNT), .DATA_WIDTH(DATA_WIDTH), .USER_WIDTH(USER_WIDTH)) i_g (
    .clk_i(clk_i), .rst_i(rst_i), .s_tdata_i(s_tdata_i), .s_tkeep_i(s_tkeep_i),
    .s_tvalid_i(g_valid), .s_tready_o(g_ready), .s_tlast_i(s_tlast_i),
    .s_tuser_i(s_tuser_i), .m_tdata_o(m_tdata_o), .m_tkeep_o(m_tkeep_o),
    .m_tvalid_o(m_tvalid_o), .m_tready_i(m_tready_i), .m_tlast_o(m_tlast_o),
    .m_tuser_o(m_tuser_o));
endmodule

// -----------------------------------------------------------------------------
// fm_m10 -- payload corrupted only DEEP inside a frame. Violates S4.
// tdata bit 0 is flipped from the fourth beat of a frame onward. Frames of
// three beats or fewer are perfect, so a testbench using short frames -- which
// is the natural choice -- never reaches it.
// -----------------------------------------------------------------------------
module fm_m10_deep_beat_corruption #(
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
  logic [DATA_WIDTH-1:0] g_data;
  logic [3:0] beat_idx;
  always_ff @(posedge clk_i) begin
    if (rst_i) beat_idx <= '0;
    else if (m_tvalid_o && m_tready_i)
      beat_idx <= m_tlast_o ? 4'd0 : (beat_idx == 4'hF ? 4'hF : beat_idx + 1);
  end
  // GUARD: the fourth beat onward of a frame, and only from the fifth frame.
  assign m_tdata_o = ((beat_idx >= 4'd3) && (g_frame_q >= 4))
                     ? {g_data[DATA_WIDTH-1:1], ~g_data[0]} : g_data;

  frame_arb_mux #(.S_COUNT(S_COUNT), .DATA_WIDTH(DATA_WIDTH), .USER_WIDTH(USER_WIDTH)) i_g (
    .clk_i(clk_i), .rst_i(rst_i), .s_tdata_i(s_tdata_i), .s_tkeep_i(s_tkeep_i),
    .s_tvalid_i(s_tvalid_i), .s_tready_o(s_tready_o), .s_tlast_i(s_tlast_i),
    .s_tuser_i(s_tuser_i), .m_tdata_o(g_data), .m_tkeep_o(m_tkeep_o),
    .m_tvalid_o(m_tvalid_o), .m_tready_i(m_tready_i), .m_tlast_o(m_tlast_o),
    .m_tuser_o(m_tuser_o));
endmodule
