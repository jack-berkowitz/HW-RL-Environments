module axis_switch_oq #(
  parameter int unsigned S_COUNT = 4,   // {2, 4}
  parameter int unsigned M_COUNT = 4,   // {2, 4}
  parameter int unsigned DATA_W  = 32   // {8, 32}
) (
  input  logic                               clk_i,
  input  logic                               rst_ni,

  // ---- input streams, concatenated port-major ------------------------------
  input  logic [S_COUNT-1:0]                 s_valid_i,
  output logic [S_COUNT-1:0]                 s_ready_o,
  input  logic [S_COUNT*DATA_W-1:0]          s_data_i,
  input  logic [S_COUNT*(DATA_W/8)-1:0]      s_keep_i,
  input  logic [S_COUNT-1:0]                 s_last_i,
  input  logic [S_COUNT*$clog2(M_COUNT)-1:0] s_dest_i,

  // ---- output streams, concatenated port-major -----------------------------
  output logic [M_COUNT-1:0]                 m_valid_o,
  input  logic [M_COUNT-1:0]                 m_ready_i,
  output logic [M_COUNT*DATA_W-1:0]          m_data_o,
  output logic [M_COUNT*(DATA_W/8)-1:0]      m_keep_o,
  output logic [M_COUNT-1:0]                 m_last_o
);

  localparam int unsigned KEEP_W  = DATA_W/8;
  localparam int unsigned DEST_W  = $clog2(M_COUNT);
  localparam int unsigned OWNER_W = $clog2(S_COUNT);

  // --------------------------------------------------------------------------
  // Two complete-frame storage slots per output.
  // Each slot holds at most 8 beats, giving exactly the permitted maximum
  // buffering of 16 beats / two frames per output.
  // --------------------------------------------------------------------------

  logic [DATA_W-1:0] data_mem
      [0:M_COUNT-1][0:1][0:7];

  logic [KEEP_W-1:0] keep_mem
      [0:M_COUNT-1][0:1][0:7];

  logic [3:0] frame_len
      [0:M_COUNT-1][0:1];

  logic frame_complete
      [0:M_COUNT-1][0:1];

  // FIFO pointers and number of reserved frames.  A frame is counted as soon
  // as its first beat is accepted, so partially filled frames consume one of
  // the two permitted frame slots.
  logic       wr_ptr      [0:M_COUNT-1];
  logic       rd_ptr      [0:M_COUNT-1];
  logic [1:0] frame_count [0:M_COUNT-1];

  // Current output beat position.
  logic [2:0] out_index [0:M_COUNT-1];

  // --------------------------------------------------------------------------
  // Input-side state.
  //
  // Only one input at a time writes a particular output queue.  Once a frame
  // begins, rx_active locks that output's ingress side to the same input until
  // LAST, preserving the frame as one atomic queue entry.
  // --------------------------------------------------------------------------

  logic                 rx_active [0:M_COUNT-1];
  logic [OWNER_W-1:0]   rx_owner  [0:M_COUNT-1];
  logic                 rx_slot   [0:M_COUNT-1];
  logic [2:0]           rx_index  [0:M_COUNT-1];

  // Round-robin starting point for the next new frame targeting each output.
  logic [OWNER_W-1:0] rr_ptr [0:M_COUNT-1];

  // Combinational grant for a new frame.
  logic [M_COUNT-1:0]       grant_valid;
  logic [OWNER_W-1:0]       grant_idx [0:M_COUNT-1];


  // ==========================================================================
  // INPUT ARBITRATION
  // ==========================================================================
  //
  // Arbitration is completely independent for every output.  Consequently,
  // inputs targeting different outputs may all transfer on the same cycle.
  //
  // While an output is receiving a multi-beat frame, its owner receives ready
  // unconditionally; no other input can enter that output until LAST.
  // ==========================================================================

  always_comb begin : input_arb
    integer m;
    integer k;
    integer idx;
    logic   found;

    s_ready_o   = '0;
    grant_valid = '0;

    for (m = 0; m < M_COUNT; m = m + 1) begin
      grant_idx[m] = '0;
    end

    if (rst_ni) begin
      for (m = 0; m < M_COUNT; m = m + 1) begin

        if (rx_active[m]) begin
          // Once a frame has started, continue accepting only that input.
          s_ready_o[rx_owner[m]] = 1'b1;

        end else if (frame_count[m] < 2'd2) begin

          // Select a new frame using round-robin arbitration.
          found = 1'b0;

          for (k = 0; k < S_COUNT; k = k + 1) begin
            idx = (rr_ptr[m] + k) % S_COUNT;

            if (!found &&
                s_valid_i[idx] &&
                (s_dest_i[idx*DEST_W +: DEST_W] == m)) begin

              found          = 1'b1;
              grant_valid[m] = 1'b1;
              grant_idx[m]   = idx[OWNER_W-1:0];
              s_ready_o[idx] = 1'b1;
            end
          end
        end
      end
    end
  end


  // ==========================================================================
  // OUTPUT DATAPATH
  // ==========================================================================
  //
  // Only completed frames are exposed to the output.  Once their first beat
  // begins, rd_ptr remains fixed until the final beat transfers.
  // ==========================================================================

  always_comb begin : output_mux
    integer m;

    m_valid_o = '0;
    m_data_o  = '0;
    m_keep_o  = '0;
    m_last_o  = '0;

    if (rst_ni) begin
      for (m = 0; m < M_COUNT; m = m + 1) begin

        if ((frame_count[m] != 2'd0) &&
            frame_complete[m][rd_ptr[m]]) begin

          m_valid_o[m] = 1'b1;

          m_data_o[m*DATA_W +: DATA_W] =
              data_mem[m][rd_ptr[m]][out_index[m]];

          m_keep_o[m*KEEP_W +: KEEP_W] =
              keep_mem[m][rd_ptr[m]][out_index[m]];

          m_last_o[m] =
              (({1'b0, out_index[m]} + 4'd1) ==
               frame_len[m][rd_ptr[m]]);
        end
      end
    end
  end


  // ==========================================================================
  // SEQUENTIAL STATE
  // ==========================================================================

  always_ff @(posedge clk_i or negedge rst_ni) begin : state_update
    integer m;

    if (!rst_ni) begin

      for (m = 0; m < M_COUNT; m = m + 1) begin
        wr_ptr[m]      <= 1'b0;
        rd_ptr[m]      <= 1'b0;
        frame_count[m] <= 2'd0;

        out_index[m] <= 3'd0;

        rx_active[m] <= 1'b0;
        rx_owner[m]  <= '0;
        rx_slot[m]   <= 1'b0;
        rx_index[m]  <= 3'd0;

        rr_ptr[m] <= '0;

        frame_complete[m][0] <= 1'b0;
        frame_complete[m][1] <= 1'b0;

        frame_len[m][0] <= 4'd0;
        frame_len[m][1] <= 4'd0;
      end

    end else begin

      for (m = 0; m < M_COUNT; m = m + 1) begin

        // --------------------------------------------------------------------
        // Queue occupancy.
        //
        // New-frame acceptance reserves a slot immediately.
        // Last-beat output transfer releases the head slot.
        // Simultaneous reserve/release leaves the count unchanged.
        // --------------------------------------------------------------------

        case ({
          ((!rx_active[m]) && grant_valid[m]),
          (m_valid_o[m] && m_ready_i[m] && m_last_o[m])
        })

          2'b10: begin
            frame_count[m] <= frame_count[m] + 2'd1;
          end

          2'b01: begin
            frame_count[m] <= frame_count[m] - 2'd1;
          end

          default: begin
            frame_count[m] <= frame_count[m];
          end
        endcase


        // --------------------------------------------------------------------
        // OUTPUT CONSUMPTION
        // --------------------------------------------------------------------

        if (m_valid_o[m] && m_ready_i[m]) begin

          if (m_last_o[m]) begin
            // Finished the current frame.
            frame_complete[m][rd_ptr[m]] <= 1'b0;
            rd_ptr[m]                    <= ~rd_ptr[m];
            out_index[m]                 <= 3'd0;

          end else begin
            out_index[m] <= out_index[m] + 3'd1;
          end
        end


        // --------------------------------------------------------------------
        // INPUT FRAME ALREADY IN PROGRESS
        // --------------------------------------------------------------------

        if (rx_active[m]) begin

          if (s_valid_i[rx_owner[m]]) begin

            data_mem[m][rx_slot[m]][rx_index[m]]
              <= s_data_i[rx_owner[m]*DATA_W +: DATA_W];

            keep_mem[m][rx_slot[m]][rx_index[m]]
              <= s_keep_i[rx_owner[m]*KEEP_W +: KEEP_W];

            if (s_last_i[rx_owner[m]]) begin
              // The whole frame is now available to the output side.
              frame_len[m][rx_slot[m]]
                <= {1'b0, rx_index[m]} + 4'd1;

              frame_complete[m][rx_slot[m]] <= 1'b1;

              rx_active[m] <= 1'b0;
              rx_index[m]  <= 3'd0;

            end else begin
              rx_index[m] <= rx_index[m] + 3'd1;
            end
          end


        // --------------------------------------------------------------------
        // START OF A NEW FRAME
        // --------------------------------------------------------------------

        end else if (grant_valid[m]) begin

          data_mem[m][wr_ptr[m]][0]
            <= s_data_i[grant_idx[m]*DATA_W +: DATA_W];

          keep_mem[m][wr_ptr[m]][0]
            <= s_keep_i[grant_idx[m]*KEEP_W +: KEEP_W];

          // Reserve the slot immediately.  Because S_COUNT is always 2 or 4,
          // truncation implements modulo-S_COUNT round-robin advancement.
          wr_ptr[m] <= ~wr_ptr[m];
          rr_ptr[m] <= grant_idx[m] + 1'b1;

          if (s_last_i[grant_idx[m]]) begin

            // Single-beat frame.
            frame_len[m][wr_ptr[m]]      <= 4'd1;
            frame_complete[m][wr_ptr[m]] <= 1'b1;

            rx_active[m] <= 1'b0;
            rx_index[m]  <= 3'd0;

          end else begin

            // Multi-beat frame: remember its input and reserved slot.
            frame_complete[m][wr_ptr[m]] <= 1'b0;

            rx_active[m] <= 1'b1;
            rx_owner[m]  <= grant_idx[m];
            rx_slot[m]   <= wr_ptr[m];
            rx_index[m]  <= 3'd1;
          end
        end
      end
    end
  end

endmodule