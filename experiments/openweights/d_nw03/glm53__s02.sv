// =============================================================================
// axis_switch_oq -- output-queued stream switch
//
// Architecture: per-output store-and-forward double-frame buffer (2 slots x 8
// beats, exactly the B1 bound). Each output has its own independent datapath,
// so disjoint input/output pairs proceed fully in parallel (C1) and a blocked
// output never affects another (C2). A frame is emitted only once fully
// received, and only when no other frame is being emitted on that output,
// which gives frame atomicity (R4) by construction. Input arbitration per
// output: the input currently filling a slot has priority (bounded by R6's
// 8-beat cap), otherwise round-robin among requesting inputs (C3, no
// starvation). m_valid_o depends only on registered state, never on
// m_ready_i (R1b).
// =============================================================================
module axis_switch_oq #(
  parameter int unsigned S_COUNT = 4,   // {2, 4}
  parameter int unsigned M_COUNT = 4,   // {2, 4}
  parameter int unsigned DATA_W  = 32   // {8, 32}
) (
  input  logic                              clk_i,
  input  logic                              rst_ni,

  input  logic [S_COUNT-1:0]                s_valid_i,
  output logic [S_COUNT-1:0]                s_ready_o,
  input  logic [S_COUNT*DATA_W-1:0]         s_data_i,
  input  logic [S_COUNT*(DATA_W/8)-1:0]     s_keep_i,
  input  logic [S_COUNT-1:0]                 s_last_i,
  input  logic [S_COUNT*$clog2(M_COUNT)-1:0] s_dest_i,

  output logic [M_COUNT-1:0]                m_valid_o,
  input  logic [M_COUNT-1:0]                m_ready_i,
  output logic [M_COUNT*DATA_W-1:0]         m_data_o,
  output logic [M_COUNT*(DATA_W/8)-1:0]     m_keep_o,
  output logic [M_COUNT-1:0]                m_last_o
);

  localparam int unsigned KEEP_W = DATA_W/8;
  localparam int unsigned DEST_W = $clog2(M_COUNT);
  localparam int unsigned BEAT_W = DATA_W + KEEP_W + 1;
  localparam int unsigned OW     = $clog2(S_COUNT);

  // slot states
  localparam logic [1:0] S_EMPTY    = 2'd0;
  localparam logic [1:0] S_FILLING  = 2'd1;
  localparam logic [1:0] S_READY    = 2'd2;
  localparam logic [1:0] S_DRAINING = 2'd3;

  // per-output state
  logic [1:0]       st   [M_COUNT][2];   // slot state
  logic [3:0]       fcnt [M_COUNT][2];   // fill count per slot
  logic [3:0]       dcnt [M_COUNT];      // drain pointer
  logic             fill [M_COUNT];      // a slot is being filled
  logic [OW-1:0]    own  [M_COUNT];      // input currently filling
  logic [OW-1:0]    rr   [M_COUNT];      // round-robin pointer

  // frame memory: 2 slots x 8 beats per output
  logic [BEAT_W-1:0] mem [M_COUNT][2][8];

  // combinational helpers
  logic              isfill [M_COUNT];
  logic              hasfree[M_COUNT];
  logic              fs     [M_COUNT];   // filling slot
  logic              wslot  [M_COUNT];   // free slot for a new frame
  logic [S_COUNT-1:0] cand  [M_COUNT];
  logic [S_COUNT-1:0] gnt   [M_COUNT];
  logic              oact   [M_COUNT];
  logic              odrn   [M_COUNT];
  logic [1:0]        oslot  [M_COUNT];
  logic [3:0]        ocnt   [M_COUNT];

  int m, i, k, idx, gi;

  // ------------------------------------------------------------------
  // input arbitration and output selection (combinational)
  // ------------------------------------------------------------------
  always_comb begin
    s_ready_o = '0;
    for (m = 0; m < M_COUNT; m++) begin
      isfill[m]  = (st[m][0] == S_FILLING) || (st[m][1] == S_FILLING);
      fs[m]      = (st[m][0] == S_FILLING) ? 1'b0 : 1'b1;
      hasfree[m] = (st[m][0] == S_EMPTY)   || (st[m][1] == S_EMPTY);
      wslot[m]   = (st[m][0] == S_EMPTY)   ? 1'b0 : 1'b1;

      for (i = 0; i < S_COUNT; i++) begin
        cand[m][i] = s_valid_i[i] &&
                     (s_dest_i[i*DEST_W +: DEST_W] == m) &&
                     (isfill[m] ? (i == own[m]) : hasfree[m]);
      end

      // grant: filling input has priority; else round-robin
      gnt[m] = '0;
      if (isfill[m]) begin
        if (cand[m][own[m]]) gnt[m][own[m]] = 1'b1;
      end else begin
        for (k = 0; k < S_COUNT; k++) begin
          idx = (rr[m] + k) % S_COUNT;
          if (gnt[m] == '0 && cand[m][idx]) gnt[m][idx] = 1'b1;
        end
      end

      for (i = 0; i < S_COUNT; i++) begin
        if (gnt[m][i]) s_ready_o[i] = 1'b1;
      end

      // output stream selection: finish draining first, else a ready frame
      oact[m]  = 1'b0;
      odrn[m]  = 1'b0;
      oslot[m] = 2'd0;
      ocnt[m]  = 4'd0;
      if (st[m][0] == S_DRAINING) begin
        oact[m] = 1'b1; odrn[m] = 1'b1; oslot[m] = 2'd0; ocnt[m] = dcnt[m];
      end else if (st[m][1] == S_DRAINING) begin
        oact[m] = 1'b1; odrn[m] = 1'b1; oslot[m] = 2'd1; ocnt[m] = dcnt[m];
      end else if (st[m][0] == S_READY) begin
        oact[m] = 1'b1; oslot[m] = 2'd0; ocnt[m] = 4'd0;
      end else if (st[m][1] == S_READY) begin
        oact[m] = 1'b1; oslot[m] = 2'd1; ocnt[m] = 4'd0;
      end

      m_valid_o[m] = oact[m];
      m_data_o[m*DATA_W +: DATA_W] = mem[m][oslot[m]][ocnt[m]][0 +: DATA_W];
      m_keep_o[m*KEEP_W +: KEEP_W] = mem[m][oslot[m]][ocnt[m]][DATA_W +: KEEP_W];
      m_last_o[m]                  = mem[m][oslot[m]][ocnt[m]][DATA_W+KEEP_W];
    end
  end

  // ------------------------------------------------------------------
  // sequential update
  // ------------------------------------------------------------------
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      for (int r = 0; r < M_COUNT; r++) begin
        st[r][0]   <= S_EMPTY;
        st[r][1]   <= S_EMPTY;
        fcnt[r][0] <= 4'd0;
        fcnt[r][1] <= 4'd0;
        dcnt[r]    <= 4'd0;
        fill[r]    <= 1'b0;
        own[r]     <= '0;
        rr[r]      <= '0;
      end
    end else begin
      // ---- output side: advance / finish the frame being emitted ----
      for (int r = 0; r < M_COUNT; r++) begin
        if (oact[r] && m_ready_i[r]) begin
          if (mem[r][oslot[r]][ocnt[r]][DATA_W+KEEP_W]) begin
            // last beat of the frame accepted
            st[r][oslot[r]] <= S_EMPTY;
            dcnt[r]         <= 4'd0;
          end else begin
            if (!odrn[r]) st[r][oslot[r]] <= S_DRAINING;
            dcnt[r] <= ocnt[r] + 4'd1;
          end
        end
      end
      // ---- input side: write granted beats into the output's buffer ----
      for (int r = 0; r < M_COUNT; r++) begin
        if (gnt[r] != '0) begin
          for (int q = 0; q < S_COUNT; q++) begin
            if (gnt[r][q]) begin
              if (isfill[r]) begin
                // continue the frame being filled
                mem[r][fs[r]][fcnt[r][fs[r]]] <= {s_last_i[q],
                                                  s_keep_i[q*KEEP_W +: KEEP_W],
                                                  s_data_i[q*DATA_W +: DATA_W]};
                if (s_last_i[q]) begin
                  st[r][fs[r]] <= S_READY;
                  fill[r]      <= 1'b0;
                end else begin
                  fcnt[r][fs[r]] <= fcnt[r][fs[r]] + 4'd1;
                end
              end else begin
                // start a new frame in a free slot
                mem[r][wslot[r]][0] <= {s_last_i[q],
                                        s_keep_i[q*KEEP_W +: KEEP_W],
                                        s_data_i[q*DATA_W +: DATA_W]};
                if (s_last_i[q]) begin
                  st[r][wslot[r]] <= S_READY;
                end else begin
                  st[r][wslot[r]]   <= S_FILLING;
                  fcnt[r][wslot[r]] <= 4'd1;
                  fill[r]           <= 1'b1;
                  own[r]            <= q[OW-1:0];
                end
                rr[r] <= ((q + 1) % S_COUNT);
              end
            end
          end
        end
      end
    end
  end

endmodule
