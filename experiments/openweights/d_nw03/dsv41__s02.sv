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
  localparam int unsigned LOG_S = $clog2(S_COUNT);
  localparam int unsigned FIFO_DEPTH = 16;
  localparam int unsigned PTR_W = $clog2(FIFO_DEPTH);

  // State registers
  logic [PTR_W-1:0] wr_ptr [M_COUNT];
  logic [PTR_W-1:0] rd_ptr [M_COUNT];
  logic [PTR_W:0] count [M_COUNT];
  logic [1:0] frame_count [M_COUNT];
  logic locked [M_COUNT];
  logic [LOG_S-1:0] locked_idx [M_COUNT];
  logic [LOG_S-1:0] rr_ptr [M_COUNT];

  // FIFO memory
  logic [DATA_W-1:0] fifo_data [M_COUNT][FIFO_DEPTH];
  logic [KEEP_W-1:0] fifo_keep [M_COUNT][FIFO_DEPTH];
  logic fifo_last [M_COUNT][FIFO_DEPTH];

  // Combinational signals
  logic grant_valid [M_COUNT];
  logic [LOG_S-1:0] grant_idx [M_COUNT];
  logic wr_en [M_COUNT];
  logic [LOG_S-1:0] wr_idx [M_COUNT];
  logic [DATA_W-1:0] wr_data [M_COUNT];
  logic [KEEP_W-1:0] wr_keep [M_COUNT];
  logic wr_last [M_COUNT];
  logic wr_is_new [M_COUNT];
  logic rd_en [M_COUNT];

  // Grant and s_ready logic
  always_comb begin
    integer j, k;
    logic [LOG_S-1:0] idx;
    logic found;
    logic [DEST_W-1:0] dest;

    for (j = 0; j < M_COUNT; j++) begin
      grant_valid[j] = 0;
      grant_idx[j] = '0;
    end

    for (j = 0; j < M_COUNT; j++) begin
      if (!locked[j] && (frame_count[j] < 2)) begin
        found = 0;
        for (k = 0; k < S_COUNT; k++) begin
          idx = (rr_ptr[j] + k) & (S_COUNT - 1);
          dest = s_dest_i[idx*DEST_W +: DEST_W];
          if (!found && s_valid_i[idx] && (dest == j)) begin
            grant_valid[j] = 1;
            grant_idx[j] = idx;
            found = 1;
          end
        end
      end
    end

    for (integer i = 0; i < S_COUNT; i++) begin
      s_ready_o[i] = 0;
      for (j = 0; j < M_COUNT; j++) begin
        if (locked[j] && (locked_idx[j] == i)) begin
          s_ready_o[i] = 1;
        end else if (!locked[j] && grant_valid[j] && (grant_idx[j] == i)) begin
          s_ready_o[i] = 1;
        end
      end
    end
  end

  // Write enable and data logic
  always_comb begin
    integer j;
    logic [LOG_S-1:0] idx;
    for (j = 0; j < M_COUNT; j++) begin
      if (locked[j]) begin
        idx = locked_idx[j];
        wr_en[j] = s_valid_i[idx];
        wr_is_new[j] = 0;
      end else begin
        idx = grant_idx[j];
        wr_en[j] = grant_valid[j];
        wr_is_new[j] = grant_valid[j];
      end
      wr_idx[j] = idx;
      wr_data[j] = s_data_i[idx*DATA_W +: DATA_W];
      wr_keep[j] = s_keep_i[idx*KEEP_W +: KEEP_W];
      wr_last[j] = s_last_i[idx];
    end
  end

  // Read enable logic
  always_comb begin
    integer j;
    for (j = 0; j < M_COUNT; j++) begin
      rd_en[j] = (count[j] > 0) && m_ready_i[j];
    end
  end

  // Output assignments
  always_comb begin
    integer j;
    for (j = 0; j < M_COUNT; j++) begin
      m_valid_o[j] = (count[j] > 0);
      m_data_o[j*DATA_W +: DATA_W] = fifo_data[j][rd_ptr[j]];
      m_keep_o[j*KEEP_W +: KEEP_W] = fifo_keep[j][rd_ptr[j]];
      m_last_o[j] = fifo_last[j][rd_ptr[j]];
    end
  end

  // Sequential state update
  always_ff @(posedge clk_i) begin
    integer j;
    logic [PTR_W-1:0] next_wr_ptr;
    logic [PTR_W-1:0] next_rd_ptr;
    logic [PTR_W:0] next_count;
    logic [1:0] next_frame_count;
    logic next_locked;
    logic [LOG_S-1:0] next_locked_idx;
    logic [LOG_S-1:0] next_rr_ptr;
    logic wen, ren;
    logic wlast;
    logic [LOG_S-1:0] widx;

    if (!rst_ni) begin
      for (j = 0; j < M_COUNT; j++) begin
        wr_ptr[j] <= 0;
        rd_ptr[j] <= 0;
        count[j] <= 0;
        frame_count[j] <= 0;
        locked[j] <= 0;
        locked_idx[j] <= 0;
        rr_ptr[j] <= 0;
      end
    end else begin
      for (j = 0; j < M_COUNT; j++) begin
        next_wr_ptr = wr_ptr[j];
        next_rd_ptr = rd_ptr[j];
        next_count = count[j];
        next_frame_count = frame_count[j];
        next_locked = locked[j];
        next_locked_idx = locked_idx[j];
        next_rr_ptr = rr_ptr[j];

        wen = wr_en[j];
        ren = rd_en[j];
        widx = wr_idx[j];
        wlast = wr_last[j];

        if (wen) begin
          fifo_data[j][wr_ptr[j]] <= wr_data[j];
          fifo_keep[j][wr_ptr[j]] <= wr_keep[j];
          fifo_last[j][wr_ptr[j]] <= wlast;
          next_wr_ptr = wr_ptr[j] + 1;
          if (wr_is_new[j]) begin
            next_frame_count = next_frame_count + 1;
            next_rr_ptr = (widx + 1) & (S_COUNT - 1);
          end
          if (!locked[j]) begin
            if (!wlast) begin
              next_locked = 1;
              next_locked_idx = widx;
            end else begin
              next_locked = 0;
            end
          end else begin
            if (wlast) begin
              next_locked = 0;
            end
          end
        end

        if (ren) begin
          if (fifo_last[j][rd_ptr[j]]) begin
            next_frame_count = next_frame_count - 1;
          end
          next_rd_ptr = rd_ptr[j] + 1;
        end

        next_count = count[j] + (wen ? 1 : 0) - (ren ? 1 : 0);

        wr_ptr[j] <= next_wr_ptr;
        rd_ptr[j] <= next_rd_ptr;
        count[j] <= next_count;
        frame_count[j] <= next_frame_count;
        locked[j] <= next_locked;
        locked_idx[j] <= next_locked_idx;
        rr_ptr[j] <= next_rr_ptr;
      end
    end
  end

endmodule
