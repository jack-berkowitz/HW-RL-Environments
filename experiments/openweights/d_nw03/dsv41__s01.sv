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

  localparam int unsigned KEEP_W = DATA_W/8;
  localparam int unsigned DEST_W = $clog2(M_COUNT);
  localparam int unsigned S_W    = $clog2(S_COUNT);

  // Two frame slots per output, each holding up to 8 beats.
  logic [DATA_W-1:0] slot_data [0:M_COUNT-1][0:1][0:7];
  logic [KEEP_W-1:0] slot_keep [0:M_COUNT-1][0:1][0:7];
  logic              slot_last [0:M_COUNT-1][0:1][0:7];

  logic              slot_full [0:M_COUNT-1][0:1];
  logic              wr_active [0:M_COUNT-1];
  logic              wr_slot   [0:M_COUNT-1];
  logic [S_W-1:0]    wr_src    [0:M_COUNT-1];
  logic [2:0]        wr_beat   [0:M_COUNT-1];

  logic              head    [0:M_COUNT-1];
  logic [1:0]        count   [0:M_COUNT-1];
  logic [2:0]        rd_beat [0:M_COUNT-1];
  logic [S_W-1:0]    rr      [0:M_COUNT-1];

  logic [M_COUNT-1:0] grant_valid;
  logic [S_W-1:0]     grant_src [0:M_COUNT-1];

  always_comb begin
    integer m, off, idx;
    logic found;

    s_ready_o   = '0;
    m_valid_o   = '0;
    m_data_o    = '0;
    m_keep_o    = '0;
    m_last_o    = '0;
    grant_valid = '0;

    for (m = 0; m < M_COUNT; m = m + 1) begin
      grant_src[m] = '0;
    end

    // Output side: present the oldest full frame.
    for (m = 0; m < M_COUNT; m = m + 1) begin
      if ((count[m] > 0) && slot_full[m][head[m]]) begin
        m_valid_o[m] = 1'b1;
        m_data_o[m*DATA_W +: DATA_W] = slot_data[m][head[m]][rd_beat[m]];
        m_keep_o[m*KEEP_W +: KEEP_W] = slot_keep[m][head[m]][rd_beat[m]];
        m_last_o[m] = slot_last[m][head[m]][rd_beat[m]];
      end
    end

    // Pick one input per output for a new frame, round-robin.
    for (m = 0; m < M_COUNT; m = m + 1) begin
      grant_valid[m] = 1'b0;
      grant_src[m]   = '0;

      if (!wr_active[m] && (count[m] < 2)) begin
        found = 1'b0;
        for (off = 0; off < S_COUNT; off = off + 1) begin
          idx = rr[m] + off;
          if (idx >= S_COUNT) idx = idx - S_COUNT;

          if (!found && s_valid_i[idx] &&
              (s_dest_i[idx*DEST_W +: DEST_W] == m)) begin
            grant_valid[m] = 1'b1;
            grant_src[m]   = idx[S_W-1:0];
            found          = 1'b1;
          end
        end
      end
    end

    // Ready for active frame beats, or for the first beat of a new frame.
    for (m = 0; m < M_COUNT; m = m + 1) begin
      if (wr_active[m]) begin
        s_ready_o[wr_src[m]] = 1'b1;
      end else if ((count[m] < 2) && grant_valid[m]) begin
        s_ready_o[grant_src[m]] = 1'b1;
      end
    end
  end

  always_ff @(posedge clk_i) begin
    integer m;
    logic slot_idx;
    logic read_done;
    logic start_transfer;
    logic [2:0] count_next;
    logic [S_W-1:0] src_idx;

    if (!rst_ni) begin
      for (m = 0; m < M_COUNT; m = m + 1) begin
        slot_full[m][0] <= 1'b0;
        slot_full[m][1] <= 1'b0;
        wr_active[m]    <= 1'b0;
        wr_slot[m]      <= 1'b0;
        wr_src[m]       <= '0;
        wr_beat[m]      <= 3'd0;
        head[m]         <= 1'b0;
        count[m]        <= 2'd0;
        rd_beat[m]      <= 3'd0;
        rr[m]           <= '0;
      end
    end else begin
      for (m = 0; m < M_COUNT; m = m + 1) begin
        read_done = 1'b0;
        if (m_valid_o[m] && m_ready_i[m] && m_last_o[m]) begin
          read_done = 1'b1;
        end

        start_transfer = 1'b0;
        if (!wr_active[m] && (count[m] < 2) &&
            grant_valid[m] && s_valid_i[grant_src[m]]) begin
          start_transfer = 1'b1;
        end

        count_next = {1'b0, count[m]} +
                     (start_transfer ? 3'd1 : 3'd0) -
                     (read_done      ? 3'd1 : 3'd0);
        count[m] <= count_next[1:0];

        // Read side
        if (m_valid_o[m] && m_ready_i[m]) begin
          if (m_last_o[m]) begin
            slot_full[m][head[m]] <= 1'b0;
            head[m]               <= ~head[m];
            rd_beat[m]            <= 3'd0;
          end else begin
            rd_beat[m] <= rd_beat[m] + 3'd1;
          end
        end

        // Write side
        if (wr_active[m]) begin
          src_idx = wr_src[m];
          if (s_valid_i[src_idx]) begin
            slot_data[m][wr_slot[m]][wr_beat[m]] <=
              s_data_i[src_idx*DATA_W +: DATA_W];
            slot_keep[m][wr_slot[m]][wr_beat[m]] <=
              s_keep_i[src_idx*KEEP_W +: KEEP_W];
            slot_last[m][wr_slot[m]][wr_beat[m]] <= s_last_i[src_idx];

            if (s_last_i[src_idx]) begin
              slot_full[m][wr_slot[m]] <= 1'b1;
              wr_active[m]             <= 1'b0;
              wr_beat[m]               <= 3'd0;
            end else begin
              wr_beat[m] <= wr_beat[m] + 3'd1;
            end
          end
        end else if (start_transfer) begin
          src_idx  = grant_src[m];
          slot_idx = head[m] ^ count[m][0];

          wr_active[m] <= 1'b1;
          wr_slot[m]   <= slot_idx;
          wr_src[m]    <= src_idx;
          wr_beat[m]   <= 3'd0;

          slot_full[m][slot_idx] <= 1'b0;
          slot_data[m][slot_idx][0] <= s_data_i[src_idx*DATA_W +: DATA_W];
          slot_keep[m][slot_idx][0] <= s_keep_i[src_idx*KEEP_W +: KEEP_W];
          slot_last[m][slot_idx][0] <= s_last_i[src_idx];

          if (s_last_i[src_idx]) begin
            slot_full[m][slot_idx] <= 1'b1;
            wr_active[m]           <= 1'b0;
            wr_beat[m]             <= 3'd0;
          end else begin
            wr_beat[m] <= 3'd1;
          end

          if (src_idx == S_COUNT-1) begin
            rr[m] <= '0;
          end else begin
            rr[m] <= src_idx + 1'b1;
          end
        end
      end
    end
  end

endmodule
