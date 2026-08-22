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

  localparam int unsigned KEEP_W = DATA_W/8;
  localparam int unsigned DEST_W = $clog2(M_COUNT);
  localparam int unsigned PAYLOAD_W = 1 + KEEP_W + DATA_W;

  // Flattened input array extraction
  logic [DEST_W-1:0] s_dest_arr [S_COUNT];
  logic [KEEP_W-1:0] s_keep_arr [S_COUNT];
  logic [DATA_W-1:0] s_data_arr [S_COUNT];

  // Interconnect FIFOs mapping
  logic fifo_write [S_COUNT][M_COUNT];
  logic fifo_read  [S_COUNT][M_COUNT];
  logic fifo_empty [S_COUNT][M_COUNT];
  logic fifo_full  [S_COUNT][M_COUNT];
  logic [PAYLOAD_W-1:0] fifo_data_in [S_COUNT][M_COUNT];
  logic [PAYLOAD_W-1:0] fifo_data_out [S_COUNT][M_COUNT];

  // ===========================================================================
  // Input Routing Stage
  // ===========================================================================
  always_comb begin
    logic [DEST_W-1:0] dest;
    int i, j;

    for (i = 0; i < S_COUNT; i = i + 1) begin
      s_dest_arr[i] = s_dest_i[i * DEST_W +: DEST_W];
      s_keep_arr[i] = s_keep_i[i * KEEP_W +: KEEP_W];
      s_data_arr[i] = s_data_i[i * DATA_W +: DATA_W];
    end

    // Default driver assignments
    for (i = 0; i < S_COUNT; i = i + 1) begin
      s_ready_o[i] = 1'b0;
      for (j = 0; j < M_COUNT; j = j + 1) begin
        fifo_write[i][j] = 1'b0;
        fifo_data_in[i][j] = {s_last_i[i], s_keep_arr[i], s_data_arr[i]};
      end
    end

    // Route each input to its target FIFO
    for (i = 0; i < S_COUNT; i = i + 1) begin
      dest = s_dest_arr[i];
      s_ready_o[i] = ~fifo_full[i][dest];
      if (s_valid_i[i] && !fifo_full[i][dest]) begin
        fifo_write[i][dest] = 1'b1;
      end
    end
  end

  // ===========================================================================
  // S_COUNT * M_COUNT FIFOs
  // ===========================================================================
  genvar s, m;
  generate
    for (s = 0; s < S_COUNT; s = s + 1) begin : g_s
      for (m = 0; m < M_COUNT; m = m + 1) begin : g_m
        // Depth 16 easily accommodates frames up to 8 beats
        logic [PAYLOAD_W-1:0] mem [16];
        logic [4:0] wr_ptr;
        logic [4:0] rd_ptr;

        assign fifo_empty[s][m] = (wr_ptr == rd_ptr);
        assign fifo_full[s][m]  = (wr_ptr[4] != rd_ptr[4]) && (wr_ptr[3:0] == rd_ptr[3:0]);
        assign fifo_data_out[s][m] = mem[rd_ptr[3:0]];

        always_ff @(posedge clk_i) begin
          if (!rst_ni) begin
            wr_ptr <= 5'd0;
            rd_ptr <= 5'd0;
          end else begin
            if (fifo_write[s][m]) begin
              mem[wr_ptr[3:0]] <= fifo_data_in[s][m];
              wr_ptr <= wr_ptr + 1'b1;
            end
            if (fifo_read[s][m]) begin
              rd_ptr <= rd_ptr + 1'b1;
            end
          end
        end
      end
    end
  endgenerate

  // ===========================================================================
  // Output Arbitration Stage
  // ===========================================================================
  logic [M_COUNT-1:0]         out_locked;
  logic [$clog2(S_COUNT)-1:0] out_sel [M_COUNT];
  logic [$clog2(S_COUNT)-1:0] rr_ptr [M_COUNT];

  logic [M_COUNT-1:0]         out_valid;
  logic [$clog2(S_COUNT)-1:0] out_grant_idx [M_COUNT];

  always_comb begin
    logic [S_COUNT-1:0] req;
    logic granted;
    logic [$clog2(S_COUNT)-1:0] grant_idx;
    logic [$clog2(S_COUNT)-1:0] idx;
    logic [$clog2(S_COUNT)-1:0] i_cast;
    int i, j;

    for (j = 0; j < M_COUNT; j = j + 1) begin
      out_valid[j] = 1'b0;
      out_grant_idx[j] = '0;
      for (i = 0; i < S_COUNT; i = i + 1) begin
        fifo_read[i][j] = 1'b0;
      end
    end

    for (j = 0; j < M_COUNT; j = j + 1) begin
      req = '0;
      granted = 1'b0;
      grant_idx = '0;

      for (i = 0; i < S_COUNT; i = i + 1) begin
        req[i] = ~fifo_empty[i][j];
      end

      if (out_locked[j]) begin
        // Retain lock to finish the current frame
        granted = 1'b1;
        grant_idx = out_sel[j];
      end else begin
        // Round Robin when not locked
        for (i = 0; i < S_COUNT; i = i + 1) begin
          i_cast = i[$clog2(S_COUNT)-1:0];
          idx = rr_ptr[j] + i_cast;
          if (req[idx] && !granted) begin
            granted = 1'b1;
            grant_idx = idx;
          end
        end
      end

      if (granted && req[grant_idx]) begin
        out_valid[j] = 1'b1;
        out_grant_idx[j] = grant_idx;
        if (m_ready_i[j]) begin
          fifo_read[grant_idx][j] = 1'b1;
        end
      end
    end
  end

  always_ff @(posedge clk_i) begin
    int j;
    if (!rst_ni) begin
      out_locked <= '0;
      for (j = 0; j < M_COUNT; j = j + 1) begin
        out_sel[j] <= '0;
        rr_ptr[j] <= '0;
      end
    end else begin
      for (j = 0; j < M_COUNT; j = j + 1) begin
        if (out_valid[j] && m_ready_i[j]) begin
          if (fifo_data_out[out_grant_idx[j]][j][PAYLOAD_W-1]) begin // MSB is last
            out_locked[j] <= 1'b0;
            rr_ptr[j] <= out_grant_idx[j] + 1'b1; // Shift fairness
          end else begin
            out_locked[j] <= 1'b1;
            out_sel[j] <= out_grant_idx[j];
          end
        end
      end
    end
  end

  // ===========================================================================
  // Output Mapping
  // ===========================================================================
  always_comb begin
    logic [PAYLOAD_W-1:0] pld;
    int j;

    for (j = 0; j < M_COUNT; j = j + 1) begin
      m_valid_o[j] = out_valid[j];
      pld = fifo_data_out[out_grant_idx[j]][j];
      
      m_last_o[j] = pld[PAYLOAD_W-1];
      m_keep_o[j * KEEP_W +: KEEP_W] = pld[DATA_W + KEEP_W - 1 : DATA_W];
      m_data_o[j * DATA_W +: DATA_W] = pld[DATA_W - 1 : 0];
    end
  end

endmodule