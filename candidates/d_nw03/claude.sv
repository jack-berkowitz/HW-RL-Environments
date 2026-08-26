// =============================================================================
// axis_switch_oq.sv -- output-queued stream switch
// =============================================================================
// Architecture: one independent frame-granular datapath per OUTPUT port.
//
//   * Each output owns a round-robin arbiter over the inputs that name it in
//     `dest`, plus a lock register that holds the winner for the duration of
//     one frame (R4 atomicity). Outputs never interact, so N disjoint pairs
//     move N beats per cycle (C1) and a blocked output cannot stall an input
//     headed elsewhere (C2). The round-robin pointer advances on every frame
//     completion, so no requester can be passed over twice (C3, L1).
//
//   * Cut-through: zero frames of storage, which is inside B1's ceiling of 2,
//     costs no beat-latency and no queue area (L2, L3). `s_ready_o` is
//     combinational on `s_valid_i`, which L5 permits explicitly.
//
//   * A grant taken while an output is idle is registered at the end of that
//     same cycle even if no beat transferred, so the selection an output
//     presents can never be stolen by a later-arriving requester while
//     `m_valid_o` is high and `m_ready_i` is low (R1 stability on the output
//     side). Because the grant itself is combinational, back-to-back frames
//     cost no arbitration bubble.
// =============================================================================

module axis_switch_oq #(
  parameter int unsigned S_COUNT = 4,   // {2, 4}
  parameter int unsigned M_COUNT = 4,   // {2, 4}
  parameter int unsigned DATA_W  = 32   // {8, 32}
) (
  input  logic                               clk_i,
  input  logic                               rst_ni,      // active low, synchronous deassert

  // ---- input streams, concatenated port-major ------------------------------
  input  logic [S_COUNT-1:0]                 s_valid_i,
  output logic [S_COUNT-1:0]                 s_ready_o,
  input  logic [S_COUNT*DATA_W-1:0]          s_data_i,
  input  logic [S_COUNT*(DATA_W/8)-1:0]      s_keep_i,
  input  logic [S_COUNT-1:0]                 s_last_i,
  input  logic [S_COUNT*$clog2(M_COUNT)-1:0] s_dest_i,

  // ---- output streams, concatenated port-major -----------------------------
  output logic [M_COUNT-1:0]                 m_valid_o,
  input  logic [M_COUNT-1:0]                 m_ready_i,
  output logic [M_COUNT*DATA_W-1:0]          m_data_o,
  output logic [M_COUNT*(DATA_W/8)-1:0]      m_keep_o,
  output logic [M_COUNT-1:0]                 m_last_o
);

  // Derived by this contract, not parameters.
  localparam int unsigned KEEP_W = DATA_W/8;
  localparam int unsigned DEST_W = $clog2(M_COUNT);
  localparam int unsigned SIDX_W = (S_COUNT > 1) ? $clog2(S_COUNT) : 1;

  localparam logic [SIDX_W-1:0] SIDX_ONE = {{(SIDX_W-1){1'b0}}, 1'b1};
  localparam logic [SIDX_W-1:0] SIDX_MAX = SIDX_W'(S_COUNT-1);

  // gnt_rdy[m*S_COUNT + s] : output m is selecting input s and is taking a beat
  // this cycle. At most one output can select a given input at a time, because
  // an input is requestable only at the output its (frame-constant) dest names.
  logic [M_COUNT*S_COUNT-1:0] gnt_rdy;

  genvar gm, gs;

  generate
  for (gm = 0; gm < int'(M_COUNT); gm = gm + 1) begin : g_out

    localparam logic [DEST_W-1:0] MY_DEST = DEST_W'(gm);

    logic [S_COUNT-1:0] req;      // inputs asking for this output right now
    logic [SIDX_W-1:0]  rr_q;     // round-robin pointer (fairness, C3)
    logic [SIDX_W-1:0]  sel_q;    // locked source, valid while busy_q
    logic               busy_q;   // a frame is in flight on this output
    logic [SIDX_W-1:0]  win;      // arbiter winner this cycle
    logic               found;    // arbiter has a winner
    logic [SIDX_W-1:0]  sel;      // source actually driving the output
    logic               active;   // this output is driving from `sel`
    logic               sv;       // selected input's valid
    logic               sl;       // selected input's last
    logic [DATA_W-1:0]  sd;       // selected input's data
    logic [KEEP_W-1:0]  sk;       // selected input's keep
    logic               beat;     // a beat transfers on this output
    logic               done;     // that beat was the frame's last

    // ---- request vector ----------------------------------------------------
    for (gs = 0; gs < int'(S_COUNT); gs = gs + 1) begin : g_req
      assign req[gs] = s_valid_i[gs] & (s_dest_i[gs*DEST_W +: DEST_W] == MY_DEST);
    end

    // ---- round-robin arbiter: first requester at or after rr_q -------------
    always_comb begin
      int unsigned idx;
      found = 1'b0;
      win   = {SIDX_W{1'b0}};
      idx   = 0;
      for (int unsigned k = 0; k < S_COUNT; k = k + 1) begin
        idx = (32'(rr_q) + k) % S_COUNT;
        if (!found && req[idx]) begin
          found = 1'b1;
          win   = SIDX_W'(idx);
        end
      end
    end

    // A locked output re-arbitrates for nothing: the lock wins until `last`.
    assign sel    = busy_q ? sel_q : win;
    assign active = busy_q | found;

    // ---- source multiplex --------------------------------------------------
    always_comb begin
      sv = 1'b0;
      sl = 1'b0;
      sd = {DATA_W{1'b0}};
      sk = {KEEP_W{1'b0}};
      for (int unsigned s = 0; s < S_COUNT; s = s + 1) begin
        if (sel == SIDX_W'(s)) begin
          sv = s_valid_i[s];
          sl = s_last_i[s];
          sd = s_data_i[s*DATA_W +: DATA_W];
          sk = s_keep_i[s*KEEP_W +: KEEP_W];
        end
      end
    end

    assign m_valid_o[gm]                 = active & sv;
    assign m_data_o[gm*DATA_W +: DATA_W] = sd;
    assign m_keep_o[gm*KEEP_W +: KEEP_W] = sk;
    assign m_last_o[gm]                  = sl;

    assign beat = active & sv & m_ready_i[gm];
    assign done = beat & sl;

    // ---- back-pressure contribution to the selected input ------------------
    for (gs = 0; gs < int'(S_COUNT); gs = gs + 1) begin : g_rdy
      localparam logic [SIDX_W-1:0] THIS_SRC = SIDX_W'(gs);
      assign gnt_rdy[gm*S_COUNT + gs] = active & m_ready_i[gm] & (sel == THIS_SRC);
    end

    // ---- lock / fairness state --------------------------------------------
    always_ff @(posedge clk_i) begin
      if (!rst_ni) begin
        busy_q <= 1'b0;
        sel_q  <= {SIDX_W{1'b0}};
        rr_q   <= {SIDX_W{1'b0}};
      end else if (done) begin
        // Frame finished: release, and give the next turn to somebody else.
        busy_q <= 1'b0;
        rr_q   <= (sel == SIDX_MAX) ? {SIDX_W{1'b0}} : (sel + SIDX_ONE);
      end else if (active) begin
        // Hold the selection even if no beat moved this cycle.
        busy_q <= 1'b1;
        sel_q  <= sel;
      end
    end

  end
  endgenerate

  // An input is ready when the one output currently selecting it is ready.
  always_comb begin
    s_ready_o = {S_COUNT{1'b0}};
    for (int unsigned s = 0; s < S_COUNT; s = s + 1) begin
      for (int unsigned m = 0; m < M_COUNT; m = m + 1) begin
        if (gnt_rdy[m*S_COUNT + s]) s_ready_o[s] = 1'b1;
      end
    end
  end

endmodule