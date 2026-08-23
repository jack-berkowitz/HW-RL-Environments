// =============================================================================
// axis_switch_oq.sv
//
// Output-queued stream switch: S_COUNT inputs, M_COUNT outputs, routed by the
// destination field carried on each input.
//
// SHAPE
// -----
// One queue per OUTPUT, and one arbiter per output, and that is the whole of
// the concurrency story: output m decides for itself, every cycle, which input
// it pulls a beat from. Nothing is shared between outputs -- no common
// datapath, no common grant, no common queue -- so four inputs addressing four
// different outputs move four beats per cycle rather than taking turns (C1).
// An input can be selected by at most one output in a cycle because its `dest`
// names exactly one, so the per-output decisions never need reconciling.
//
// FRAME ATOMICITY (R4)
// --------------------
// The lock is on the ENQUEUE side, not the output side. When an output takes
// the first beat of a frame it latches which input that frame came from and
// keeps taking beats from that input until `last`, so beats of two frames can
// never be adjacent in one queue. The output then simply drains its queue in
// order, and atomicity at the port follows from atomicity in the queue rather
// than from anything the output side has to enforce. A frame may begin draining
// while it is still arriving -- cut-through is free (L3) and costs nothing here,
// because the lock already guarantees no other frame can slip in behind it.
//
// HEAD-OF-LINE (C2) AND FAIRNESS (C3)
// -----------------------------------
// `s_ready_o[s]` is asserted only by the one output that `dest` names, so an
// input backlogged to a full or stalled output holds nothing but itself: a
// different input reaching a different output is on entirely separate logic.
// Each output arbitrates round-robin at FRAME granularity, advancing past the
// input it just served when that frame ends, so no input is starved.
//
// BUFFERING (B1)
// --------------
// Per output: 16 beats of queue, and a new frame is only started when fewer
// than two complete frames are already queued. Both halves of the bound hold
// at once -- never more than 2 frames and never more than 16 beats resident
// for any output -- so a stream of one-beat frames cannot quietly turn the
// beat budget into a sixteen-frame buffer. The frame limit costs nothing at
// rate: a queue that drains every cycle sits at one complete frame.
// =============================================================================

module axis_switch_oq #(
  parameter int unsigned S_COUNT = 4,   // {2, 4}
  parameter int unsigned M_COUNT = 4,   // {2, 4}
  parameter int unsigned DATA_W  = 32   // {8, 32}
) (
  input  logic                              clk_i,
  input  logic                              rst_ni,      // active low, synchronous deassert

  // ---- input streams, concatenated port-major ------------------------------
  input  logic [S_COUNT-1:0]                s_valid_i,
  output logic [S_COUNT-1:0]                s_ready_o,
  input  logic [S_COUNT*DATA_W-1:0]         s_data_i,
  input  logic [S_COUNT*(DATA_W/8)-1:0]     s_keep_i,
  input  logic [S_COUNT-1:0]                s_last_i,
  input  logic [S_COUNT*$clog2(M_COUNT)-1:0] s_dest_i,

  // ---- output streams, concatenated port-major -----------------------------
  output logic [M_COUNT-1:0]                m_valid_o,
  input  logic [M_COUNT-1:0]                m_ready_i,
  output logic [M_COUNT*DATA_W-1:0]         m_data_o,
  output logic [M_COUNT*(DATA_W/8)-1:0]     m_keep_o,
  output logic [M_COUNT-1:0]                m_last_o
);

  // Derived by this contract, not parameters.
  localparam int unsigned KEEP_W = DATA_W/8;
  localparam int unsigned DEST_W = $clog2(M_COUNT);

  localparam int unsigned SRC_W  = (S_COUNT == 2) ? 1 : 2;
  localparam int unsigned MAX_FRAME = 8;                  // R6
  localparam int unsigned QD     = 2 * MAX_FRAME;         // 16 beats per output
  localparam int unsigned QAW    = 4;                     // $clog2(QD)
  localparam int unsigned BW     = DATA_W + KEEP_W + 1;   // {data, keep, last}

  localparam logic [QAW-1:0] QD_LAST = QAW'(QD - 1);
  localparam logic [QAW:0]   QD_FULL = (QAW+1)'(QD);
  localparam logic [QAW:0]   Q_ONE   = (QAW+1)'(1);
  localparam logic [QAW-1:0] P_ONE   = QAW'(1);
  localparam logic [SRC_W-1:0] S_ONE = {{(SRC_W-1){1'b0}}, 1'b1};
  localparam logic [1:0]     F_ONE   = 2'd1;
  localparam logic [1:0]     F_MAX   = 2'd2;

  // ---------------------------------------------------------------- inputs --
  logic [DATA_W-1:0] sd   [S_COUNT];
  logic [KEEP_W-1:0] sk   [S_COUNT];
  logic [DEST_W-1:0] sdst [S_COUNT];

  always_comb begin
    int unsigned s;
    for (s = 0; s < S_COUNT; s++) begin
      sd[s]   = s_data_i[s*DATA_W +: DATA_W];
      sk[s]   = s_keep_i[s*KEEP_W +: KEEP_W];
      sdst[s] = s_dest_i[s*DEST_W +: DEST_W];
    end
  end

  // ---------------------------------------------------------- output state --
  logic [BW-1:0]     q     [M_COUNT][QD];
  logic [QAW-1:0]    q_wp  [M_COUNT], q_rp [M_COUNT];
  logic [QAW:0]      q_cnt [M_COUNT];
  logic [1:0]        f_cnt [M_COUNT];   // complete frames resident
  logic              lk_v  [M_COUNT];   // mid-frame, locked to one input
  logic [SRC_W-1:0]  lk_s  [M_COUNT];
  logic [SRC_W-1:0]  rr    [M_COUNT];   // round-robin pointer (L1, C3)

  logic              gv   [M_COUNT];    // this output wants a beat
  logic [SRC_W-1:0]  gs   [M_COUNT];    // from this input
  logic              acc  [M_COUNT];    // and can take it
  logic              deq  [M_COUNT];
  logic              h_last [M_COUNT];

  // --------------------------------------------------------- arbitration ----
  always_comb begin
    int m, k, i, ls;
    i  = 0;
    ls = 0;
    for (m = 0; m < int'(M_COUNT); m++) begin
      gv[m] = 1'b0;
      gs[m] = '0;
      if (lk_v[m]) begin
        // committed to this frame until its last beat (R4)
        ls = int'(lk_s[m]);
        if (s_valid_i[ls]) begin
          gv[m] = 1'b1;
          gs[m] = lk_s[m];
        end
      end else if (f_cnt[m] != F_MAX) begin
        // frame-granular round robin, starting past whoever was served last
        for (k = int'(S_COUNT) - 1; k >= 0; k--) begin
          i = (int'(rr[m]) + k) % int'(S_COUNT);
          if (s_valid_i[i] && (sdst[i] == DEST_W'(unsigned'(m)))) begin
            gv[m] = 1'b1;
            gs[m] = SRC_W'(unsigned'(i));
          end
        end
      end
      acc[m] = gv[m] && (q_cnt[m] != QD_FULL);
    end
  end

  // An input is only ever selected by the single output its dest names, so
  // these assignments can never collide.
  always_comb begin
    int m;
    s_ready_o = '0;
    for (m = 0; m < int'(M_COUNT); m++) begin
      if (acc[m]) s_ready_o[gs[m]] = 1'b1;
    end
  end

  // ------------------------------------------------------------- outputs ----
  always_comb begin
    int unsigned m;
    logic [BW-1:0] h;
    m_valid_o = '0;
    m_data_o  = '0;
    m_keep_o  = '0;
    m_last_o  = '0;
    for (m = 0; m < M_COUNT; m++) begin
      h = q[m][q_rp[m]];
      m_valid_o[m]                 = (q_cnt[m] != '0);
      m_data_o[m*DATA_W +: DATA_W] = h[KEEP_W+1 +: DATA_W];
      m_keep_o[m*KEEP_W +: KEEP_W] = h[1 +: KEEP_W];
      m_last_o[m]                  = h[0];
      h_last[m]                    = h[0];
      deq[m]                       = (q_cnt[m] != '0) && m_ready_i[m];
    end
  end

  // ----------------------------------------------------------- sequential ---
  always_ff @(posedge clk_i) begin
    int m, g;
    if (!rst_ni) begin
      for (m = 0; m < int'(M_COUNT); m++) begin
        q_wp[m]  <= '0;
        q_rp[m]  <= '0;
        q_cnt[m] <= '0;
        f_cnt[m] <= '0;
        lk_v[m]  <= 1'b0;
        lk_s[m]  <= '0;
        rr[m]    <= '0;
      end
    end else begin
      for (m = 0; m < int'(M_COUNT); m++) begin
        g = int'(gs[m]);
        if (acc[m]) begin
          q[m][q_wp[m]] <= {sd[g], sk[g], s_last_i[g]};
          q_wp[m]       <= (q_wp[m] == QD_LAST) ? '0 : q_wp[m] + P_ONE;
          if (s_last_i[g]) begin
            lk_v[m] <= 1'b0;
            // hand the next frame to the following input (C3)
            rr[m]   <= (int'(gs[m]) == int'(S_COUNT) - 1) ? '0 : gs[m] + S_ONE;
          end else begin
            lk_v[m] <= 1'b1;
            lk_s[m] <= gs[m];
          end
        end
        if (deq[m]) q_rp[m] <= (q_rp[m] == QD_LAST) ? '0 : q_rp[m] + P_ONE;

        q_cnt[m] <= q_cnt[m] + (acc[m] ? Q_ONE : '0) - (deq[m] ? Q_ONE : '0);
        f_cnt[m] <= f_cnt[m] + ((acc[m] && s_last_i[g]) ? F_ONE : 2'd0)
                             - ((deq[m] && h_last[m])   ? F_ONE : 2'd0);
      end
    end
  end

endmodule