// =============================================================================
// axis_switch_oq.sv
// 
// Synthesizable Output-Queued AXI-Stream Switch.
// Supports generic S_COUNT and M_COUNT by instantiating individual output 
// queues and arbitrating inputs at the entrance to each output FIFO.
// Strict compliance with frame-atomicity (locking per-output arbiters until 
// s_last_i) and disjoint concurrent throughput.
// =============================================================================

module axis_switch_oq #(
  parameter int unsigned S_COUNT = 4,   // {2, 4}
  parameter int unsigned M_COUNT = 4,   // {2, 4}
  parameter int unsigned DATA_W  = 32   // {8, 32}
) (
  input  logic                              clk_i,
  input  logic                              rst_ni,

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

  localparam int unsigned KEEP_W = DATA_W/8;
  localparam int unsigned DEST_W = (M_COUNT == 1) ? 1 : $clog2(M_COUNT);
  localparam int unsigned S_IDX_W = (S_COUNT == 1) ? 1 : $clog2(S_COUNT);

  // =========================================================================
  // State elements
  // =========================================================================
  logic arb_locked [M_COUNT];
  logic [S_IDX_W-1:0] arb_sel [M_COUNT];
  logic [S_IDX_W-1:0] rr_ptr [M_COUNT];
  
  logic [4:0] fifo_count [M_COUNT];
  logic [3:0] fifo_wptr [M_COUNT];
  logic [3:0] fifo_rptr [M_COUNT];
  
  logic [DATA_W-1:0] fifo_data [M_COUNT][16];
  logic [KEEP_W-1:0] fifo_keep [M_COUNT][16];
  logic              fifo_last [M_COUNT][16];

  // =========================================================================
  // Combinational signals
  // =========================================================================
  logic [S_COUNT-1:0] req [M_COUNT];
  logic [S_COUNT-1:0] gnt [M_COUNT];
  logic fifo_full [M_COUNT];
  logic push [M_COUNT];
  logic pop [M_COUNT];

  // =========================================================================
  // Variables for loops (Declared at module scope to satisfy T2 safely)
  // =========================================================================
  int m, s, i, out, in_s;
  logic [S_IDX_W-1:0] idx;
  logic [DEST_W-1:0] dest;
  logic [S_IDX_W-1:0] current_sel;

  // =========================================================================
  // Input Routing & Arbitration Logic
  // =========================================================================
  always_comb begin
      // Default assignments
      for (m = 0; m < M_COUNT; m++) begin
          req[m] = '0;
          gnt[m] = '0;
          push[m] = 1'b0;
          fifo_full[m] = (fifo_count[m] == 16);
      end
      
      for (s = 0; s < S_COUNT; s++) begin
          s_ready_o[s] = 1'b0;
      end

      // 1. Request Generation
      for (s = 0; s < S_COUNT; s++) begin
          if (s_valid_i[s]) begin
              dest = s_dest_i[s*DEST_W +: DEST_W];
              if (dest < M_COUNT) begin
                  req[dest][s] = 1'b1;
              end
          end
      end
      
      // 2. Output-Side Arbitration
      for (m = 0; m < M_COUNT; m++) begin
          if (arb_locked[m]) begin
              // Frame Atomicity: Stick to the previously granted input until s_last_i
              if (req[m][arb_sel[m]]) begin
                  gnt[m][arb_sel[m]] = 1'b1;
              end
          end else begin
              // Round-Robin Arbitration to avoid Starvation
              for (i = 0; i < S_COUNT; i++) begin
                  if (rr_ptr[m] + i < S_COUNT) begin
                      idx = S_IDX_W'(rr_ptr[m] + i);
                  end else begin
                      idx = S_IDX_W'(rr_ptr[m] + i - S_COUNT);
                  end
                  
                  if (req[m][idx]) begin
                      gnt[m][idx] = 1'b1;
                      break;
                  end
              end
          end
      end
      
      // 3. FIFO Push Check and Input Ready Formulation
      for (m = 0; m < M_COUNT; m++) begin
          push[m] = (|gnt[m]) && !fifo_full[m];
      end
      
      for (s = 0; s < S_COUNT; s++) begin
          for (m = 0; m < M_COUNT; m++) begin
              if (gnt[m][s] && !fifo_full[m]) begin
                  s_ready_o[s] = 1'b1;
              end
          end
      end
  end

  // =========================================================================
  // Output Queue Output Assignments
  // =========================================================================
  always_comb begin
      for (m = 0; m < M_COUNT; m++) begin
          m_valid_o[m] = (fifo_count[m] > 0);
          pop[m] = m_valid_o[m] && m_ready_i[m];
          m_data_o[m*DATA_W +: DATA_W] = fifo_data[m][fifo_rptr[m]];
          m_keep_o[m*KEEP_W +: KEEP_W] = fifo_keep[m][fifo_rptr[m]];
          m_last_o[m] = fifo_last[m][fifo_rptr[m]];
      end
  end

  // =========================================================================
  // Sequential Updates
  // =========================================================================
  always_ff @(posedge clk_i or negedge rst_ni) begin
      if (!rst_ni) begin
          for (out = 0; out < M_COUNT; out++) begin
              arb_locked[out] <= 1'b0;
              arb_sel[out]    <= '0;
              rr_ptr[out]     <= '0;
              fifo_count[out] <= '0;
              fifo_wptr[out]  <= '0;
              fifo_rptr[out]  <= '0;
          end
      end else begin
          for (out = 0; out < M_COUNT; out++) begin
              
              // Arbiter Update & FIFO Write
              if (push[out]) begin
                  current_sel = '0;
                  for (in_s = 0; in_s < S_COUNT; in_s++) begin
                      if (gnt[out][in_s]) current_sel = S_IDX_W'(in_s);
                  end
                  
                  if (s_last_i[current_sel]) begin
                      arb_locked[out] <= 1'b0;
                      if (current_sel == S_COUNT - 1) begin
                          rr_ptr[out] <= '0;
                      end else begin
                          rr_ptr[out] <= current_sel + 1;
                      end
                  end else begin
                      arb_locked[out] <= 1'b1;
                      arb_sel[out]    <= current_sel;
                  end
                  
                  fifo_data[out][fifo_wptr[out]] <= s_data_i[current_sel*DATA_W +: DATA_W];
                  fifo_keep[out][fifo_wptr[out]] <= s_keep_i[current_sel*KEEP_W +: KEEP_W];
                  fifo_last[out][fifo_wptr[out]] <= s_last_i[current_sel];
                  fifo_wptr[out] <= fifo_wptr[out] + 1;
              end
              
              // FIFO Read
              if (pop[out]) begin
                  fifo_rptr[out] <= fifo_rptr[out] + 1;
              end
              
              // FIFO Depth Tracking
              if (push[out] && !pop[out]) begin
                  fifo_count[out] <= fifo_count[out] + 1;
              end else if (!push[out] && pop[out]) begin
                  fifo_count[out] <= fifo_count[out] - 1;
              end
              
          end
      end
  end

endmodule