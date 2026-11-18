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

  localparam logic [1:0] EMPTY   = 2'd0;
  localparam logic [1:0] WRITING = 2'd1;
  localparam logic [1:0] READY   = 2'd2;

  // Per-output frame buffers (2 frames, each up to 8 beats)
  logic [1:0]          buffer_state [M_COUNT][2];
  logic [DATA_W-1:0]   buffer_data  [M_COUNT][2][8];
  logic [KEEP_W-1:0]   buffer_keep  [M_COUNT][2][8];
  logic                buffer_last  [M_COUNT][2][8];
  logic [2:0]          buffer_write_ptr [M_COUNT][2];
  logic [2:0]          buffer_read_ptr  [M_COUNT];

  // Output FIFO state
  logic [1:0] head [M_COUNT];
  logic [1:0] tail [M_COUNT];
  logic [1:0] frame_count [M_COUNT];
  logic       out_draining [M_COUNT];

  // Input state
  logic       input_active [S_COUNT];
  logic [1:0] input_out    [S_COUNT];
  logic       input_buf    [S_COUNT];

  // Round-robin pointers
  integer rr [M_COUNT];

  // Combinational signals
  logic [S_COUNT-1:0] req [M_COUNT];
  logic [1:0]         selected_s [M_COUNT];
  logic               grant_valid [M_COUNT];
  logic [1:0]         grant_src [M_COUNT];
  logic [S_COUNT-1:0] grant;

  // ---------------------------------------------------------------------------
  // Grant arbitration (per output, round-robin)
  // ---------------------------------------------------------------------------
  always_comb begin
    integer m, s, i, idx;
    logic found;
    logic can_accept;
    logic [DEST_W-1:0] dest_m;

    for (m = 0; m < M_COUNT; m = m + 1) begin
      req[m] = '0;
      selected_s[m] = 0;
      grant_valid[m] = 0;
      grant_src[m] = 0;
    end
    grant = '0;

    for (m = 0; m < M_COUNT; m = m + 1) begin
      dest_m = m;
      for (s = 0; s < S_COUNT; s = s + 1) begin
        req[m][s] = (!input_active[s]) && s_valid_i[s] &&
                    (s_dest_i[s*DEST_W +: DEST_W] == dest_m);
      end

      can_accept = (frame_count[m] < 2) &&
                   (buffer_state[m][tail[m]] == EMPTY);

      if (can_accept) begin
        found = 0;
        for (i = 0; i < S_COUNT; i = i + 1) begin
          idx = rr[m] + i;
          if (idx >= S_COUNT) idx = idx - S_COUNT;
          if (!found && req[m][idx]) begin
            selected_s[m] = idx;
            found = 1;
          end
        end
        if (found) begin
          grant_valid[m] = 1;
          grant_src[m] = selected_s[m];
          grant[selected_s[m]] = 1;
        end
      end
    end
  end

  // ---------------------------------------------------------------------------
  // Input ready generation
  // ---------------------------------------------------------------------------
  always_comb begin
    integer s;
    for (s = 0; s < S_COUNT; s = s + 1) begin
      if (input_active[s]) begin
        s_ready_o[s] = (buffer_write_ptr[input_out[s]][input_buf[s]] < 3'd7) ||
                       s_last_i[s];
      end else begin
        s_ready_o[s] = grant[s];
      end
    end
  end

  // ---------------------------------------------------------------------------
  // Output data generation
  // ---------------------------------------------------------------------------
  always_comb begin
    integer m;
    for (m = 0; m < M_COUNT; m = m + 1) begin
      m_valid_o[m] = out_draining[m];
      if (out_draining[m]) begin
        m_data_o[m*DATA_W +: DATA_W] = buffer_data[m][head[m]][buffer_read_ptr[m]];
        m_keep_o[m*KEEP_W +: KEEP_W] = buffer_keep[m][head[m]][buffer_read_ptr[m]];
        m_last_o[m] = buffer_last[m][head[m]][buffer_read_ptr[m]];
      end else begin
        m_data_o[m*DATA_W +: DATA_W] = '0;
        m_keep_o[m*KEEP_W +: KEEP_W] = '0;
        m_last_o[m] = 0;
      end
    end
  end

  // ---------------------------------------------------------------------------
  // Sequential logic
  // ---------------------------------------------------------------------------
  always_ff @(posedge clk_i) begin
    integer m, s, gs, gb, mo, bo, b;
    integer fc_next, head_next, tail_next, out_draining_next, read_ptr_next;

    if (!rst_ni) begin
      for (m = 0; m < M_COUNT; m = m + 1) begin
        buffer_state[m][0] <= EMPTY;
        buffer_state[m][1] <= EMPTY;
        buffer_write_ptr[m][0] <= 0;
        buffer_write_ptr[m][1] <= 0;
        buffer_read_ptr[m] <= 0;
        head[m] <= 0;
        tail[m] <= 0;
        frame_count[m] <= 0;
        out_draining[m] <= 0;
        rr[m] <= 0;
      end
      for (s = 0; s < S_COUNT; s = s + 1) begin
        input_active[s] <= 0;
        input_out[s] <= 0;
        input_buf[s] <= 0;
      end
    end else begin
      // Output drain and grant
      for (m = 0; m < M_COUNT; m = m + 1) begin
        fc_next = frame_count[m];
        head_next = head[m];
        tail_next = tail[m];
        out_draining_next = out_draining[m];
        read_ptr_next = buffer_read_ptr[m];

        // Drain logic
        if (out_draining[m]) begin
          if (m_ready_i[m]) begin
            if (buffer_last[m][head[m]][buffer_read_ptr[m]]) begin
              // Finish current frame
              buffer_state[m][head[m]] <= EMPTY;
              read_ptr_next = 0;
              head_next = (head[m] == 0) ? 1 : 0;
              fc_next = fc_next - 1;

              if (frame_count[m] > 1 && buffer_state[m][head_next] == READY) begin
                out_draining_next = 1;
                read_ptr_next = 0;
              end else begin
                out_draining_next = 0;
              end
            end else begin
              read_ptr_next = buffer_read_ptr[m] + 1;
            end
          end
        end else begin
          if (frame_count[m] > 0 && buffer_state[m][head[m]] == READY) begin
            out_draining_next = 1;
            read_ptr_next = 0;
          end else begin
            out_draining_next = 0;
          end
        end

        // Grant logic
        if (grant_valid[m]) begin
          gs = grant_src[m];
          gb = tail[m];

          buffer_data[m][gb][0] <= s_data_i[gs*DATA_W +: DATA_W];
          buffer_keep[m][gb][0] <= s_keep_i[gs*KEEP_W +: KEEP_W];
          buffer_last[m][gb][0] <= s_last_i[gs];

          if (s_last_i[gs]) begin
            buffer_state[m][gb] <= READY;
            buffer_write_ptr[m][gb] <= 0;
            input_active[gs] <= 0;
          end else begin
            buffer_state[m][gb] <= WRITING;
            buffer_write_ptr[m][gb] <= 1;
            input_active[gs] <= 1;
          end

          input_out[gs] <= m;
          input_buf[gs] <= gb;
          tail_next = (tail[m] == 0) ? 1 : 0;
          fc_next = fc_next + 1;

          if (gs == S_COUNT-1) rr[m] <= 0;
          else rr[m] <= gs + 1;
        end

        frame_count[m] <= fc_next;
        head[m] <= head_next;
        tail[m] <= tail_next;
        out_draining[m] <= out_draining_next;
        buffer_read_ptr[m] <= read_ptr_next;
      end

      // Active input beats (subsequent beats of a frame)
      for (s = 0; s < S_COUNT; s = s + 1) begin
        if (input_active[s] && s_valid_i[s] && s_ready_o[s]) begin
          mo = input_out[s];
          bo = input_buf[s];
          b = buffer_write_ptr[mo][bo];

          buffer_data[mo][bo][b] <= s_data_i[s*DATA_W +: DATA_W];
          buffer_keep[mo][bo][b] <= s_keep_i[s*KEEP_W +: KEEP_W];
          buffer_last[mo][bo][b] <= s_last_i[s];

          if (s_last_i[s]) begin
            buffer_state[mo][bo] <= READY;
            buffer_write_ptr[mo][bo] <= 0;
            input_active[s] <= 0;
          end else begin
            buffer_write_ptr[mo][bo] <= buffer_write_ptr[mo][bo] + 1;
          end
        end
      end
    end
  end

endmodule
