module axis_switch_oq #(
  parameter int unsigned S_COUNT = 4,
  parameter int unsigned M_COUNT = 4,
  parameter int unsigned DATA_W  = 32
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

  localparam int unsigned KEEP_W  = DATA_W/8;
  localparam int unsigned DEST_W  = $clog2(M_COUNT);
  localparam int unsigned S_IDX_W = $clog2(S_COUNT);

  /*
   * Each output has an independent round-robin arbiter.
   *
   * Once an output selects a frame, grant_q is locked to that input
   * until the final beat of the frame transfers.  The lock is also
   * taken when an initially selected beat is stalled, so m_* remains
   * stable while m_valid_o is asserted and m_ready_i is low.
   */
  logic                       lock_q  [0:M_COUNT-1];
  logic [S_IDX_W-1:0]         grant_q [0:M_COUNT-1];
  logic [S_IDX_W-1:0]         rr_q    [0:M_COUNT-1];

  /*
   * Current arbitration result.  These are used both for driving the
   * datapath and for updating the registered grant state.
   */
  logic                       sel_valid [0:M_COUNT-1];
  logic [S_IDX_W-1:0]         sel_idx   [0:M_COUNT-1];

  /*
   * Combinational crossbar and arbitration.
   *
   * There is one arbitration operation per output, allowing disjoint
   * input/output pairs to transfer simultaneously.
   */
  always_comb begin : switch_comb
    integer m;
    integer off;
    integer idx;

    s_ready_o = '0;

    m_valid_o = '0;
    m_data_o  = '0;
    m_keep_o  = '0;
    m_last_o  = '0;

    for (m = 0; m < M_COUNT; m = m + 1) begin
      sel_valid[m] = 1'b0;
      sel_idx[m]   = '0;

      /*
       * A locked output remains attached to the same input until
       * that frame's last beat transfers.
       */
      if (lock_q[m]) begin
        sel_idx[m]   = grant_q[m];
        sel_valid[m] = s_valid_i[grant_q[m]];
      end
      else begin
        /*
         * Unlocked output: choose the first requesting input starting
         * from this output's round-robin pointer.
         */
        for (off = 0; off < S_COUNT; off = off + 1) begin
          idx = rr_q[m] + off;

          if (idx >= S_COUNT)
            idx = idx - S_COUNT;

          if (!sel_valid[m] &&
              s_valid_i[idx] &&
              (s_dest_i[idx*DEST_W +: DEST_W] == m)) begin
            sel_valid[m] = 1'b1;
            sel_idx[m]   = idx[S_IDX_W-1:0];
          end
        end
      end

      /*
       * Drive this output directly from its selected input.
       */
      if (sel_valid[m]) begin
        m_valid_o[m] = 1'b1;

        m_data_o[m*DATA_W +: DATA_W] =
          s_data_i[sel_idx[m]*DATA_W +: DATA_W];

        m_keep_o[m*KEEP_W +: KEEP_W] =
          s_keep_i[sel_idx[m]*KEEP_W +: KEEP_W];

        m_last_o[m] = s_last_i[sel_idx[m]];

        /*
         * An input can request only the output named by its dest.
         * Thus no input can be selected by two unlocked outputs.
         * While locked, dest is constant for the active frame.
         */
        s_ready_o[sel_idx[m]] = m_ready_i[m];
      end
    end
  end

  /*
   * Grant locking and round-robin state.
   */
  always_ff @(posedge clk_i or negedge rst_ni) begin : switch_state
    integer m;

    if (!rst_ni) begin
      for (m = 0; m < M_COUNT; m = m + 1) begin
        lock_q[m]  <= 1'b0;
        grant_q[m] <= '0;
        rr_q[m]    <= '0;
      end
    end
    else begin
      for (m = 0; m < M_COUNT; m = m + 1) begin

        if (lock_q[m]) begin
          /*
           * While locked, only completion of the final beat releases
           * the output.
           */
          if (m_valid_o[m] && m_ready_i[m] && m_last_o[m]) begin
            lock_q[m] <= 1'b0;

            if (grant_q[m] == S_COUNT-1)
              rr_q[m] <= '0;
            else
              rr_q[m] <= grant_q[m] + 1'b1;
          end
        end
        else begin
          if (sel_valid[m]) begin

            if (!m_ready_i[m]) begin
              /*
               * m_valid is visible but the beat has not transferred.
               * Hold this choice so output payload cannot change
               * while stalled.
               */
              lock_q[m]  <= 1'b1;
              grant_q[m] <= sel_idx[m];
            end
            else if (!s_last_i[sel_idx[m]]) begin
              /*
               * First/non-final beat transferred.  Lock the output to
               * this input for the remainder of the frame.
               */
              lock_q[m]  <= 1'b1;
              grant_q[m] <= sel_idx[m];
            end
            else begin
              /*
               * A one-beat frame transferred completely.  No lock is
               * needed; rotate priority immediately.
               */
              lock_q[m] <= 1'b0;

              if (sel_idx[m] == S_COUNT-1)
                rr_q[m] <= '0;
              else
                rr_q[m] <= sel_idx[m] + 1'b1;
            end
          end
        end
      end
    end
  end

endmodule