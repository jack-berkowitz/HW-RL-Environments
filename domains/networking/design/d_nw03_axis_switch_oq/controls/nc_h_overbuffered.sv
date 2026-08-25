// ============================================================================
// nc_h_overbuffered -- d_nw03 CAPABILITY-EXCEEDED CONTROL. Never shipped.
// ============================================================================
// THE MIRROR OF A CAPACITY CONTROL. Every other control of this shape provides
// LESS than a declared budget and must fail. This one provides MORE than a
// declared CEILING, and must also fail -- B1 says "a design may hold at most 2
// frames per output, that is 16 beats given R6's 8-beat frame cap. Storage
// beyond that is NON-CONFORMING."
//
// WHY THE CEILING EXISTS. B1's own text: buffering is free under L2 and
// throughput is reported, so "deeper queues absorb more burstiness and read as
// better throughput, with the area charged to nothing -- a benefit with no
// stated cost." That is F62's language, and B1 was written in response to
// d_nw01, where a submission buffered a full 256-beat burst per master --
// 20,480 bits of flip-flops -- was entirely conforming, and came out at 14.2x
// the reference's area. The PPA comparison there measured the gap in the
// specification rather than the design.
//
// THE PERTURBATION, ONE EDIT. Derived from tb/axis_switch_oq_alt_ref.sv by
// changing NB from 2 to 8: eight frame buffers per input instead of two. Ports
// stay full width and nothing else differs. It is a correct switch -- it routes,
// orders and delivers every frame exactly once, keeps frames atomic, and its
// concurrency is if anything BETTER than the source it came from, because
// deeper queues absorb more burstiness. THE ONLY THING WRONG WITH IT IS THAT IT
// HOLDS FOUR TIMES THE STORAGE B1 PERMITS.
//
// PREDICTION, stated before running.
//   Both configurations -- 4x4 and 2x2 -- SHOULD PASS. I can find no check in
//   tb/axis_switch_oq_tb.sv that measures frames in flight per output or
//   asserts B1 at all: there is no occupancy counter, no beat-in-flight tally,
//   nothing keyed to the number 2 or 16. If that reading is right, B1 is a
//   clause the contract states and the harness does not enforce, and this
//   control passing is THE FINDING rather than a failure of the control.
//
//   IF IT FAILS at either configuration, my reading of the harness is wrong and
//   B1 is enforced by something I did not recognise -- most likely indirectly,
//   through a throughput or ordering consequence of the deeper queues. That
//   would be the better outcome and I would rather be wrong this way.
//
// POLARITY, AND IT IS NOT THE USUAL ONE. A capacity control passes at the small
// configuration, where its literal equals the parameter, and fails at the large
// one. THIS CONTROL HAS NO SUCH CROSSOVER: B1's ceiling is a constant, not a
// parameter, so 8 buffers exceeds it at every configuration and the expected
// verdict is the SAME at both. The two configurations are run to show that the
// absence of a check is not a configuration artefact, not to find a crossover.
//
// NEVER SCORED AS A SUBMISSION.
// ============================================================================
`timescale 1ns/1ps

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
  localparam int unsigned NB      = 8;    // buffers per input -- B1 allows 2

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
