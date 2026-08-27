// =============================================================================
// axis_switch_oq.sv -- output-queued stream switch, S_COUNT x M_COUNT.
//
// THE SHAPE OF THE DESIGN IS SET BY C1, NOT BY ROUTING.
//   Every output owns a complete, independent datapath: its own arbiter, its
//   own mux over the inputs, and its own output register.  Nothing is shared
//   between outputs, so four inputs addressing four different outputs all move
//   a beat in the same cycle -- 4.0 beats/cycle against C1's floor of 2.0.  A
//   design that muxes everything through one shared datapath routes every frame
//   correctly and delivers 1.0, which is why C1 is a rate and not a comparison.
//
// FRAME ATOMICITY (R4) is a LOCK, not a per-beat arbitration.  An output picks
// a source only when it is between frames; the grant is then held until the
// beat carrying `last` transfers.  A per-beat arbiter is the thing that breaks
// R4, and it breaks it only under contention, which is why it survives casual
// testing.
//
// NO HEAD-OF-LINE BLOCKING (C2) falls out of the independence: an input stalled
// against a busy output holds only that output's grant, and every other output
// is arbitrating on its own.  NO STARVATION (C3): each arbiter is round-robin
// with the pointer advanced past the winner AT FRAME COMPLETION, so service
// rotates per frame rather than per beat.
//
// BUFFERING (B1 ceiling: 2 frames = 16 beats per output).  This design stores
// TWO BEATS per output -- one two-entry register on each output and nothing
// anywhere else.  It is cut-through: a beat is taken from an input only when
// that output's register has room, so backpressure propagates to the source
// instead of being absorbed.
//
// R1b: `m_valid_o` is the occupancy of that output register.  It is a function
// of state alone and never of `m_ready_i`, so a sink may hold ready low
// indefinitely without the switch withdrawing the beat.  R1 stability follows:
// the read pointer only advances on an accepted beat, so valid and payload are
// held until the transfer completes.
//
// L5 is used: `s_ready_o` does depend combinationally on `s_valid_i`, through
// the arbiter.  The contract permits this explicitly.
//
// Declarations precede statements in every procedural block (T2); every loop
// bound is a constant and the module is self-contained (T4).
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

  // Index width for a source port, and the width of one buffered beat.
  localparam int unsigned SIDX_W = (S_COUNT > 1) ? $clog2(S_COUNT) : 1;
  localparam int unsigned BEAT_W = DATA_W + KEEP_W + 1;   // {last, keep, data}

  // ---------------------------------------------------------------------------
  // unpacked views of the input side
  // ---------------------------------------------------------------------------
  logic [S_COUNT-1:0][DATA_W-1:0] s_data;
  logic [S_COUNT-1:0][KEEP_W-1:0] s_keep;
  logic [S_COUNT-1:0][DEST_W-1:0] s_dest;

  // ---------------------------------------------------------------------------
  // per-output state.  Two beats of storage per output is the whole of this
  // design's buffering (B1 allows 16).
  // ---------------------------------------------------------------------------
  logic [M_COUNT-1:0]                 lk_v;    // grant locked mid-frame (R4)
  logic [M_COUNT-1:0][SIDX_W-1:0]     lk_s;    // locked source
  logic [M_COUNT-1:0][SIDX_W-1:0]     rr_p;    // round-robin pointer (C3)
  logic [M_COUNT-1:0][1:0][BEAT_W-1:0] fifo_d;
  logic [M_COUNT-1:0][1:0]            fifo_n;  // occupancy 0..2
  logic [M_COUNT-1:0]                 fifo_rp, fifo_wp;

  // ---------------------------------------------------------------------------
  // per-output combinational
  // ---------------------------------------------------------------------------
  logic [M_COUNT-1:0][S_COUNT-1:0] req;
  logic [M_COUNT-1:0][SIDX_W-1:0]  sel;
  logic [M_COUNT-1:0]              sel_v, buf_rdy, xfer, pop;
  logic [M_COUNT-1:0][BEAT_W-1:0]  beat;

  // ---------------------------------------------------------------------------
  // input unpacking
  // ---------------------------------------------------------------------------
  always_comb begin
    int unsigned i;
    for (i = 0; i < S_COUNT; i++) begin
      s_data[i] = s_data_i[i*DATA_W +: DATA_W];
      s_keep[i] = s_keep_i[i*KEEP_W +: KEEP_W];
      s_dest[i] = s_dest_i[i*DEST_W +: DEST_W];
    end
  end

  // ---------------------------------------------------------------------------
  // Arbitration, one INDEPENDENT arbiter per output -- this is what C1 measures.
  //
  // While locked the output re-selects the same source every cycle and does not
  // arbitrate at all, which is frame atomicity (R4).  While unlocked it takes
  // the first requester at or after the round-robin pointer.
  // ---------------------------------------------------------------------------
  always_comb begin
    int unsigned i, m, k;
    logic [SIDX_W-1:0] c;

    for (m = 0; m < M_COUNT; m++) begin
      for (i = 0; i < S_COUNT; i++) begin
        req[m][i] = s_valid_i[i] && (s_dest[i] == DEST_W'(m));
      end
    end

    for (m = 0; m < M_COUNT; m++) begin
      sel[m]   = '0;
      sel_v[m] = 1'b0;
      if (lk_v[m]) begin
        sel[m]   = lk_s[m];
        sel_v[m] = req[m][lk_s[m]];
      end else begin
        // S_COUNT is a power of two, so the rotate is a natural wrap.
        for (k = 0; k < S_COUNT; k++) begin
          c = SIDX_W'(rr_p[m] + SIDX_W'(k));
          if (!sel_v[m] && req[m][c]) begin
            sel_v[m] = 1'b1;
            sel[m]   = c;
          end
        end
      end

      // Cut-through: take a beat only when this output has room for it, so
      // backpressure reaches the source rather than being buffered (B1).
      buf_rdy[m] = (fifo_n[m] < 2'd2);
      xfer[m]    = sel_v[m] && buf_rdy[m];
      beat[m]    = {s_last_i[sel[m]], s_keep[sel[m]], s_data[sel[m]]};
    end
  end

  // ---------------------------------------------------------------------------
  // Input-side ready.  An input is ready exactly when the output it names is
  // taking its beat this cycle; L5 permits this to follow s_valid_i.
  // ---------------------------------------------------------------------------
  always_comb begin
    int unsigned m;
    s_ready_o = '0;
    for (m = 0; m < M_COUNT; m++) begin
      if (xfer[m]) s_ready_o[sel[m]] = 1'b1;
    end
  end

  // ---------------------------------------------------------------------------
  // Output side.  m_valid_o is register occupancy -- never a function of
  // m_ready_i (R1b) -- and the payload is held until the beat is taken (R1).
  // ---------------------------------------------------------------------------
  always_comb begin
    int unsigned m;
    m_valid_o = '0;
    m_last_o  = '0;
    m_data_o  = '0;
    m_keep_o  = '0;
    pop       = '0;
    for (m = 0; m < M_COUNT; m++) begin
      m_valid_o[m]                 = (fifo_n[m] != 2'd0);
      m_data_o[m*DATA_W +: DATA_W] = fifo_d[m][fifo_rp[m]][DATA_W-1:0];
      m_keep_o[m*KEEP_W +: KEEP_W] = fifo_d[m][fifo_rp[m]][DATA_W +: KEEP_W];
      m_last_o[m]                  = fifo_d[m][fifo_rp[m]][BEAT_W-1];
      pop[m]                       = m_valid_o[m] && m_ready_i[m];
    end
  end

  // ---------------------------------------------------------------------------
  // state.  rst_ni is active low and synchronous.
  // ---------------------------------------------------------------------------
  always_ff @(posedge clk_i) begin
    int unsigned m;
    if (!rst_ni) begin
      lk_v    <= '0;
      lk_s    <= '0;
      rr_p    <= '0;
      fifo_n  <= '0;
      fifo_rp <= '0;
      fifo_wp <= '0;
    end else begin
      for (m = 0; m < M_COUNT; m++) begin
        if (xfer[m]) begin
          fifo_d[m][fifo_wp[m]] <= beat[m];
          fifo_wp[m]            <= ~fifo_wp[m];
          // Release the grant on the frame's last beat and rotate past the
          // winner, so the next frame on this output goes to someone else (C3).
          if (s_last_i[sel[m]]) begin
            lk_v[m] <= 1'b0;
            rr_p[m] <= SIDX_W'(sel[m] + SIDX_W'(1));
          end else begin
            lk_v[m] <= 1'b1;
            lk_s[m] <= sel[m];
          end
        end
        if (pop[m]) fifo_rp[m] <= ~fifo_rp[m];

        if (xfer[m] && !pop[m])      fifo_n[m] <= fifo_n[m] + 2'd1;
        else if (!xfer[m] && pop[m]) fifo_n[m] <= fifo_n[m] - 2'd1;
      end
    end
  end

endmodule