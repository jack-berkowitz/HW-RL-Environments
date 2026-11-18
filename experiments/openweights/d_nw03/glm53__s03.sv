module axis_switch_oq #(
  parameter int unsigned S_COUNT = 4,   // {2, 4}
  parameter int unsigned M_COUNT = 4,   // {2, 4}
  parameter int unsigned DATA_W  = 32   // {8, 32}
) (
  input  logic                               clk_i,
  input  logic                               rst_ni,

  input  logic [S_COUNT-1:0]                 s_valid_i,
  output logic [S_COUNT-1:0]                 s_ready_o,
  input  logic [S_COUNT*DATA_W-1:0]          s_data_i,
  input  logic [S_COUNT*(DATA_W/8)-1:0]      s_keep_i,
  input  logic [S_COUNT-1:0]                 s_last_i,
  input  logic [S_COUNT*$clog2(M_COUNT)-1:0] s_dest_i,

  output logic [M_COUNT-1:0]                 m_valid_o,
  input  logic [M_COUNT-1:0]                 m_ready_i,
  output logic [M_COUNT*DATA_W-1:0]          m_data_o,
  output logic [M_COUNT*(DATA_W/8)-1:0]      m_keep_o,
  output logic [M_COUNT-1:0]                 m_last_o
);

  // Derived by this contract, not parameters.
  localparam int unsigned KEEP_W = DATA_W/8;
  localparam int unsigned DEST_W = $clog2(M_COUNT);
  localparam int unsigned SW     = (S_COUNT > 1) ? $clog2(S_COUNT) : 1;
  localparam int unsigned BW     = DATA_W + KEEP_W + 1;   // {last, keep, data}

  // ---------------------------------------------------------------------------
  // Architecture: one 16-beat circular buffer per output (B1's exact ceiling:
  // 2 frames x 8 beats).  Each output has a single "owner" input at a time; a
  // new owner is granted round-robin among requesting inputs when the output
  // is unowned and has space.  The owner holds the output until its last beat
  // is accepted, which guarantees frame atomicity (R4) by construction: only
  // one input can ever append to a given output's buffer.  Because every
  // output has its own buffer and its own owner logic, disjoint input/output
  // pairs proceed fully in parallel (C1) and a blocked pair cannot affect a
  // different pair (C2).  Round-robin grant renewal guarantees forward
  // progress (C3).  m_valid_o depends only on registered state (R1b).
  // ---------------------------------------------------------------------------

  logic [BW-1:0] mem [M_COUNT][16];
  logic [3:0]    wr_ptr [M_COUNT];
  logic [3:0]    rd_ptr [M_COUNT];
  logic [4:0]    cnt    [M_COUNT];
  logic          own_v  [M_COUNT];
  logic [SW-1:0] own    [M_COUNT];
  logic [SW-1:0] rr     [M_COUNT];

  logic           acc_m   [M_COUNT];   // a beat is accepted into output m
  logic [SW-1:0] acc_src [M_COUNT];    // which input supplies it
  logic           pop     [M_COUNT];    // output m delivers a beat

  int unsigned    m;
  int unsigned    s;
  int unsigned    k;
  logic [SW-1:0]  sidx;
  logic [SW-1:0]  pick;
  logic           found;
  logic [DEST_W-1:0] ds;

  // ---------------------------------------------------------------------------
  // Accept / arbitrate / output-drive (combinational)
  // ---------------------------------------------------------------------------
  always_comb begin
    for (m = 0; m < M_COUNT; m++) begin
      pop[m]     = (cnt[m] != 5'd0) && m_ready_i[m];
      acc_m[m]   = 1'b0;
      acc_src[m] = '0;

      if (own_v[m]) begin
        // Current owner: accept its beat if it is offering one and there is
        // space.  The owner is the only writer, so no interleaving is possible.
        acc_m[m]   = s_valid_i[own[m]] && (cnt[m] < 5'd16) &&
                     (s_dest_i[own[m]*DEST_W +: DEST_W] == m);
        acc_src[m] = own[m];
      end else if (cnt[m] < 5'd16) begin
        // Output free: round-robin grant among requesting inputs.
        found = 1'b0;
        pick  = '0;
        for (k = 0; k < S_COUNT; k++) begin
          sidx = rr[m] + SW'(k);
          if (!found && s_valid_i[sidx] &&
              (s_dest_i[sidx*DEST_W +: DEST_W] == m)) begin
            found = 1'b1;
            pick  = sidx;
          end
        end
        acc_m[m]   = found;
        acc_src[m] = pick;
      end

      // Output side: valid depends only on registered occupancy (R1b).
      m_valid_o[m]                = (cnt[m] != 5'd0);
      m_data_o[m*DATA_W +: DATA_W] = mem[m][rd_ptr[m]][DATA_W-1:0];
      m_keep_o[m*KEEP_W +: KEEP_W] = mem[m][rd_ptr[m]][DATA_W +: KEEP_W];
      m_last_o[m]                 = mem[m][rd_ptr[m]][DATA_W+KEEP_W];
    end

    // Input side: an input is ready exactly when its destination output
    // accepts a beat from it this cycle.
    for (s = 0; s < S_COUNT; s++) begin
      ds = s_dest_i[s*DEST_W +: DEST_W];
      s_ready_o[s] = acc_m[ds] && (acc_src[ds] == SW'(s));
    end
  end

  // ---------------------------------------------------------------------------
  // State update
  // ---------------------------------------------------------------------------
  always_ff @(posedge clk_i) begin
    if (!rst_ni) begin
      for (m = 0; m < M_COUNT; m++) begin
        wr_ptr[m] <= 4'd0;
        rd_ptr[m] <= 4'd0;
        cnt[m]    <= 5'd0;
        own_v[m]   <= 1'b0;
        own[m]     <= '0;
        rr[m]      <= '0;
      end
    end else begin
      for (m = 0; m < M_COUNT; m++) begin
        // Push accepted beat into this output's buffer.
        if (acc_m[m]) begin
          mem[m][wr_ptr[m]] <= {s_last_i[acc_src[m]],
                                 s_keep_i[acc_src[m]*KEEP_W +: KEEP_W],
                                 s_data_i[acc_src[m]*DATA_W +: DATA_W]};
          wr_ptr[m] <= wr_ptr[m] + 4'd1;
        end
        // Pop delivered beat.
        if (pop[m]) begin
          rd_ptr[m] <= rd_ptr[m] + 4'd1;
        end
        // Occupancy.
        cnt[m] <= cnt[m] + (acc_m[m] ? 5'd1 : 5'd0)
                        - (pop[m]   ? 5'd1 : 5'd0);
        // Ownership: take a new owner on grant (unless the granted frame is a
        // single beat, in which case it is already complete).
        if (!own_v[m] && acc_m[m] && !s_last_i[acc_src[m]]) begin
          own_v[m] <= 1'b1;
          own[m]   <= acc_src[m];
        end
        // Release the owner when the final beat of its frame is accepted,
        // and advance the round-robin pointer (wraps mod S_COUNT, which is a
        // power of two, so no input can be starved).
        if (acc_m[m] && s_last_i[acc_src[m]]) begin
          own_v[m] <= 1'b0;
          rr[m]    <= acc_src[m] + SW'(1);
        end
      end
    end
  end

endmodule
