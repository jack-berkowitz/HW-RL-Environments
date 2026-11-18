module axis_switch_oq #(
  parameter int unsigned S_COUNT = 4,   // {2, 4}
  parameter int unsigned M_COUNT = 4,   // {2, 4}
  parameter int unsigned DATA_W  = 32   // {8, 32}
) (
  input  logic                                clk_i,
  input  logic                                rst_ni,

  input  logic [S_COUNT-1:0]                  s_valid_i,
  output logic [S_COUNT-1:0]                  s_ready_o,
  input  logic [S_COUNT*DATA_W-1:0]           s_data_i,
  input  logic [S_COUNT*(DATA_W/8)-1:0]       s_keep_i,
  input  logic [S_COUNT-1:0]                  s_last_i,
  input  logic [S_COUNT*$clog2(M_COUNT)-1:0]  s_dest_i,

  output logic [M_COUNT-1:0]                  m_valid_o,
  input  logic [M_COUNT-1:0]                  m_ready_i,
  output logic [M_COUNT*DATA_W-1:0]           m_data_o,
  output logic [M_COUNT*(DATA_W/8)-1:0]       m_keep_o,
  output logic [M_COUNT-1:0]                  m_last_o
);

  // ------------------------------------------------------------------
  // Derived constants (NOT parameters, per contract)
  // ------------------------------------------------------------------
  localparam int unsigned KEEP_W = DATA_W/8;
  localparam int unsigned DEST_W = $clog2(M_COUNT);
  localparam int unsigned S_CW   = (S_COUNT <= 1) ? 1 : $clog2(S_COUNT);
  localparam int unsigned PW     = DATA_W + KEEP_W;   // {keep, data}

  // ------------------------------------------------------------------
  // Architecture (store-and-forward, output-queued):
  //   * Per output m: two frame slots, each 8 beats deep (B1: 2 frames).
  //   * At most ONE input writes to a given output at a time (frame grant),
  //     which guarantees frame atomicity on the write side.
  //   * Grants are issued per output with a round-robin pointer (C3).
  //     Grants on different outputs are independent (C1, C2).
  //   * A frame is drained only after it fully arrived; the second slot
  //     lets a new frame arrive while the previous one drains.
  //   * m_valid_o is purely registered (R1b), s_ready_o may be
  //     combinational on s_valid_i (L5).
  // ------------------------------------------------------------------

  // per-output state
  logic [M_COUNT-1:0][1:0]          busy_q;     // slot holds a completed frame
  logic [M_COUNT-1:0]              wr_act_q;   // an input holds the write side
  logic [M_COUNT-1:0][S_CW-1:0]     wr_inp_q;   // which input is writing
  logic [M_COUNT-1:0]              wr_slt_q;   // slot being written
  logic [M_COUNT-1:0][3:0]          wr_cnt_q;   // beat count of writing frame
  logic [M_COUNT-1:0]              rd_act_q;   // output is draining
  logic [M_COUNT-1:0]              rd_slt_q;   // slot being drained
  logic [M_COUNT-1:0][3:0]          rd_cnt_q;   // beat count of draining frame
  logic [M_COUNT-1:0]              rd_nxt_q;   // next slot to drain (FIFO order)
  logic [M_COUNT-1:0][1:0][3:0]    len_q;      // frame length per slot
  logic [M_COUNT-1:0][S_CW-1:0]    rr_q;       // round-robin pointer per output
  logic [M_COUNT-1:0][1:0][7:0][PW-1:0] mem;  // 2 frames x 8 beats per output

  // per-input state
  logic [S_COUNT-1:0]               act_q;      // input is inside a frame
  logic [S_COUNT-1:0][DEST_W-1:0]   dst_q;      // destination of that frame

  // combinational
  logic [S_COUNT-1:0][DEST_W-1:0]   dest;
  logic [S_COUNT-1:0]               req;
  logic [M_COUNT-1:0]              gnt_v;
  logic [M_COUNT-1:0][S_CW-1:0]     gnt_i;
  logic [M_COUNT-1:0]              gnt_s;
  logic [M_COUNT-1:0]              wr_v;
  logic [M_COUNT-1:0][S_CW-1:0]    wr_i;
  logic [M_COUNT-1:0]              wr_s;
  logic [M_COUNT-1:0][3:0]         wr_c;

  // ------------------------------------------------------------------
  // Grant / arbitration logic (combinational)
  // ------------------------------------------------------------------
  always_comb begin
    int si, mi, k, idx;
    for (si = 0; si < S_COUNT; si++) begin
      dest[si] = s_dest_i[si*DEST_W +: DEST_W];
      req[si]  = s_valid_i[si] && !act_q[si];
    end
    for (mi = 0; mi < M_COUNT; mi++) begin
      gnt_v[mi] = 1'b0;
      gnt_i[mi] = '0;
      gnt_s[mi] = 1'b0;
      // a new frame may start on this output only if no writer currently
      // holds it and at most one completed frame is waiting (2-slot bound)
      if (!wr_act_q[mi] && ((busy_q[mi][0] + busy_q[mi][1]) <= 1)) begin
        for (k = 0; k < S_COUNT; k++) begin
          idx = (int'(rr_q[mi]) + k) % S_COUNT;
          if (!gnt_v[mi] && req[idx] && (dest[idx] == DEST_W'(mi))) begin
            gnt_v[mi] = 1'b1;
            gnt_i[mi] = S_CW'(idx);
            gnt_s[mi] = busy_q[mi][0]; // first free slot
          end
        end
      end
      // effective writer (registered writer, or freshly granted input)
      wr_v[mi] = wr_act_q[mi] | gnt_v[mi];
      wr_i[mi] = wr_act_q[mi] ? wr_inp_q[mi] : gnt_i[mi];
      wr_s[mi] = wr_act_q[mi] ? wr_slt_q[mi] : gnt_s[mi];
      wr_c[mi] = wr_act_q[mi] ? wr_cnt_q[mi] : 4'd0;
    end
    // input ready: active writer always accepted; otherwise on grant
    for (si = 0; si < S_COUNT; si++) begin
      s_ready_o[si] = act_q[si] ||
                      (gnt_v[dest[si]] && (gnt_i[dest[si]] == S_CW'(si)));
    end
  end

  // ------------------------------------------------------------------
  // Sequential update
  // ------------------------------------------------------------------
  always_ff @(posedge clk_i) begin
    int s, m, wi;
    if (!rst_ni) begin
      busy_q   <= '0;
      wr_act_q <= '0;
      wr_inp_q <= '0;
      wr_slt_q <= '0;
      wr_cnt_q <= '0;
      rd_act_q <= '0;
      rd_slt_q <= '0;
      rd_cnt_q <= '0;
      rd_nxt_q <= '0;
      len_q    <= '0;
      rr_q     <= '0;
      act_q    <= '0;
      dst_q    <= '0;
    end else begin
      // ---- per-input frame tracking ----
      for (s = 0; s < S_COUNT; s++) begin
        if (s_valid_i[s] && s_ready_o[s]) begin
          if (act_q[s]) begin
            if (s_last_i[s])
              act_q[s] <= 1'b0;
          end else begin
            act_q[s] <= ~s_last_i[s];
            dst_q[s] <= dest[s];
          end
        end
      end

      // ---- per-output write side and drain side ----
      for (m = 0; m < M_COUNT; m++) begin
        wi = int'(wr_i[m]);
        // write side: the (single) writer of this output stores a beat
        if (wr_v[m] && s_valid_i[wi]) begin
          mem[m][wr_s[m]][wr_c[m]] <= {s_keep_i[wi*KEEP_W +: KEEP_W],
                                        s_data_i[wi*DATA_W +: DATA_W]};
          if (s_last_i[wi]) begin
            // frame complete: mark slot, release writer
            busy_q[m][wr_s[m]]   <= 1'b1;
            len_q[m][wr_s[m]]   <= wr_c[m] + 4'd1;
            wr_act_q[m]         <= 1'b0;
            // FIFO order: this frame is the next to drain only if the
            // reader is idle and no other completed frame is waiting
            if (!rd_act_q[m] && !busy_q[m][1 - wr_s[m]])
              rd_nxt_q[m] <= wr_s[m];
          end else begin
            wr_act_q[m] <= 1'b1;
            wr_inp_q[m] <= wr_i[m];
            wr_slt_q[m] <= wr_s[m];
            wr_cnt_q[m] <= wr_c[m] + 4'd1;
          end
        end

        // drain side
        if (!rd_act_q[m] && busy_q[m][rd_nxt_q[m]]) begin
          rd_act_q[m] <= 1'b1;
          rd_slt_q[m] <= rd_nxt_q[m];
          rd_cnt_q[m] <= 4'd0;
        end else if (rd_act_q[m] && m_ready_i[m]) begin
          if (rd_cnt_q[m] == (len_q[m][rd_slt_q[m]] - 4'd1)) begin
            rd_act_q[m]         <= 1'b0;
            busy_q[m][rd_slt_q[m]] <= 1'b0;
            rd_nxt_q[m]         <= ~rd_slt_q[m];
          end else begin
            rd_cnt_q[m] <= rd_cnt_q[m] + 4'd1;
          end
        end

        // round-robin pointer advance on grant (no starvation, C3)
        if (gnt_v[m])
          rr_q[m] <= S_CW'((int'(rr_q[m]) + 1) % S_COUNT);
      end
    end
  end

  // ------------------------------------------------------------------
  // Output ports (registered valid; no combinational path to m_ready_i)
  // ------------------------------------------------------------------
  always_comb begin
    int m;
    for (m = 0; m < M_COUNT; m++) begin
      m_valid_o[m] = rd_act_q[m];
      m_data_o[m*DATA_W +: DATA_W] =
          mem[m][rd_slt_q[m]][rd_cnt_q[m]][DATA_W-1:0];
      m_keep_o[m*KEEP_W +: KEEP_W] =
          mem[m][rd_slt_q[m]][rd_cnt_q[m]][PW-1:KEEP_W];
      m_last_o[m] = (rd_cnt_q[m] == (len_q[m][rd_slt_q[m]] - 4'd1));
    end
  end

endmodule
