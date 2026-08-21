// =============================================================================
// axis_switch_oq_alt_ref.sv  --  SECOND SOURCE. Never shipped, never scored.
// =============================================================================
// Independently written. Shares no code with the shim and does not instantiate
// the anchor.
//
// *** IT IS A PROBE, NOT A DELIVERABLE. *** Its job is to catch assumptions the
// negative controls structurally cannot see: the controls only feed the checker
// BAD inputs, so an over-strict checker passes both of them. Only a design that
// is RIGHT in an unfamiliar way can expose a precondition the harness never
// established.
//
// TARGETED: for each named latitude clause, this takes the OPPOSITE legal
// choice from the anchor.
//
//   L2  buffering    STORE-AND-FORWARD. A frame is buffered in full before any
//                    of it appears at an output. The anchor cuts through -- its
//                    first beat reaches the output before the frame has been
//                    fully accepted, which is what forced the harness's routing
//                    check off "frames fully accepted" and onto "frames
//                    started".
//   L1  arbitration  OLDEST-FIRST by arrival order, against the anchor's
//                    round-robin.
//   L5  ready        s_ready_o IS GATED ON s_valid_i, which L5 explicitly
//                    permits and the anchor does not do.
//
// Two buffers per input, so filling one frame overlaps draining the previous --
// a single buffer would halve throughput and make a C1 result impossible to
// adjudicate between "the floor is too tight" and "this design is just slow".
// =============================================================================

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

  localparam int unsigned KEEP_W  = DATA_W/8;
  localparam int unsigned DEST_W  = $clog2(M_COUNT);
  localparam int unsigned MAXF    = 8;    // spec R6
  localparam int unsigned NB      = 2;    // buffers per input

  logic              b_full [S_COUNT][NB];
  logic [DEST_W-1:0] b_dest [S_COUNT][NB];
  int unsigned       b_len  [S_COUNT][NB];
  int unsigned       b_seq  [S_COUNT][NB];
  logic [DATA_W-1:0] b_data [S_COUNT][NB][MAXF];
  logic [KEEP_W-1:0] b_keep [S_COUNT][NB][MAXF];

  int unsigned wr_sel [S_COUNT];
  int unsigned wr_cnt [S_COUNT];
  int unsigned seq_ctr;

  logic        o_act [M_COUNT];
  int unsigned o_in  [M_COUNT];
  int unsigned o_bf  [M_COUNT];
  int unsigned o_bt  [M_COUNT];

  // ---- input side: L5, ready gated on valid --------------------------------
  always_comb begin
    for (int i = 0; i < int'(S_COUNT); i++)
      s_ready_o[i] = s_valid_i[i] & ~b_full[i][wr_sel[i]];
  end

  // ---- output side ---------------------------------------------------------
  always_comb begin
    m_valid_o = '0; m_data_o = '0; m_keep_o = '0; m_last_o = '0;
    for (int m = 0; m < int'(M_COUNT); m++) begin
      m_valid_o[m] = o_act[m];
      m_data_o[m*DATA_W +: DATA_W] = b_data[o_in[m]][o_bf[m]][o_bt[m]];
      m_keep_o[m*KEEP_W +: KEEP_W] = b_keep[o_in[m]][o_bf[m]][o_bt[m]];
      m_last_o[m] = o_act[m] && (o_bt[m] == b_len[o_in[m]][o_bf[m]] - 1);
    end
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      seq_ctr <= 0;
      for (int i = 0; i < int'(S_COUNT); i++) begin
        wr_sel[i] <= 0; wr_cnt[i] <= 0;
        for (int b = 0; b < int'(NB); b++) begin
          b_full[i][b] <= 1'b0; b_len[i][b] <= 0; b_seq[i][b] <= 0; b_dest[i][b] <= '0;
        end
      end
      for (int m = 0; m < int'(M_COUNT); m++) begin
        o_act[m] <= 1'b0; o_in[m] <= 0; o_bf[m] <= 0; o_bt[m] <= 0;
      end
    end
    else begin
      // ---- accept beats into the filling buffer -----------------------------
      for (int i = 0; i < int'(S_COUNT); i++) begin
        if (s_valid_i[i] && s_ready_o[i]) begin
          automatic int unsigned wb = wr_sel[i];
          b_data[i][wb][wr_cnt[i]] <= s_data_i[i*DATA_W +: DATA_W];
          b_keep[i][wb][wr_cnt[i]] <= s_keep_i[i*KEEP_W +: KEEP_W];
          if (s_last_i[i]) begin
            // L2: the frame becomes visible to the output side only now
            b_full[i][wb] <= 1'b1;
            b_len [i][wb] <= wr_cnt[i] + 1;
            b_dest[i][wb] <= s_dest_i[i*DEST_W +: DEST_W];
            b_seq [i][wb] <= seq_ctr;
            seq_ctr       <= seq_ctr + 1;
            wr_cnt[i]     <= 0;
            wr_sel[i]     <= (wb == NB-1) ? 0 : wb + 1;
          end
          else wr_cnt[i] <= wr_cnt[i] + 1;
        end
      end

      // ---- output side: stream, then pick the oldest waiting frame ----------
      for (int m = 0; m < int'(M_COUNT); m++) begin
        if (o_act[m]) begin
          if (m_ready_i[m]) begin
            if (o_bt[m] == b_len[o_in[m]][o_bf[m]] - 1) begin
              b_full[o_in[m]][o_bf[m]] <= 1'b0;
              o_act[m] <= 1'b0;
              o_bt[m]  <= 0;
            end
            else o_bt[m] <= o_bt[m] + 1;
          end
        end
        else begin
          // L1: oldest arrival first, not round robin
          automatic logic        found = 1'b0;
          automatic int unsigned best  = 0;
          automatic int unsigned bi_   = 0;
          automatic int unsigned bb_   = 0;
          for (int i = 0; i < int'(S_COUNT); i++)
            for (int b = 0; b < int'(NB); b++)
              if (b_full[i][b] && (int'(b_dest[i][b]) == m))
                if (!found || (b_seq[i][b] < best)) begin
                  found = 1'b1; best = b_seq[i][b]; bi_ = i; bb_ = b;
                end
          if (found) begin
            o_act[m] <= 1'b1; o_in[m] <= bi_; o_bf[m] <= bb_; o_bt[m] <= 0;
          end
        end
      end
    end
  end

endmodule
