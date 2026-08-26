module axis_switch_oq #(
  parameter int unsigned S_COUNT = 4,
  parameter int unsigned M_COUNT = 4,
  parameter int unsigned DATA_W  = 32
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

  localparam int unsigned KEEP_W    = DATA_W / 8;
  localparam int unsigned DEST_W    = $clog2(M_COUNT);
  localparam int unsigned MAX_BEATS = 8;
  localparam int unsigned SLOTS     = 2;

  // --------------------------------------------------------------------------
  // Input-field views.
  // --------------------------------------------------------------------------
  logic [DATA_W-1:0] s_data [0:S_COUNT-1];
  logic [KEEP_W-1:0] s_keep [0:S_COUNT-1];
  logic [DEST_W-1:0] s_dest [0:S_COUNT-1];

  genvar gv;
  generate
    for (gv = 0; gv < S_COUNT; gv = gv + 1) begin : g_input_views
      assign s_data[gv] = s_data_i[gv*DATA_W +: DATA_W];
      assign s_keep[gv] = s_keep_i[gv*KEEP_W +: KEEP_W];
      assign s_dest[gv] = s_dest_i[gv*DEST_W +: DEST_W];
    end
  endgenerate

  // --------------------------------------------------------------------------
  // Two frame slots per output, eight beats per slot.
  //
  // A slot is reserved on the first accepted beat of a frame.  The frame may
  // then fill independently of the output.  Output transmission begins only
  // after the slot is complete, which makes frame atomicity automatic.
  // --------------------------------------------------------------------------
  logic [DATA_W-1:0] frame_data_q [0:M_COUNT-1][0:SLOTS-1][0:MAX_BEATS-1];
  logic [KEEP_W-1:0] frame_keep_q [0:M_COUNT-1][0:SLOTS-1][0:MAX_BEATS-1];
  logic              frame_last_q [0:M_COUNT-1][0:SLOTS-1][0:MAX_BEATS-1];
  logic              frame_complete_q [0:M_COUNT-1][0:SLOTS-1];

  logic              alloc_ptr_q [0:M_COUNT-1];
  logic              drain_ptr_q [0:M_COUNT-1];
  logic [1:0]        frame_count_q [0:M_COUNT-1];
  logic [2:0]        out_beat_q [0:M_COUNT-1];

  // Round-robin first-beat arbitration is independent for every output.
  logic [1:0]        alloc_rr_q [0:M_COUNT-1];
  logic              alloc_grant_valid_c [0:M_COUNT-1];
  logic [1:0]        alloc_grant_input_c [0:M_COUNT-1];
  logic              alloc_fire_c [0:M_COUNT-1];
  logic              drain_last_fire_c [0:M_COUNT-1];

  // Once an input owns a frame slot, all remaining beats of that frame go to
  // that slot without any further arbitration.
  logic              in_frame_q [0:S_COUNT-1];
  logic [DEST_W-1:0] in_dest_q  [0:S_COUNT-1];
  logic              in_slot_q  [0:S_COUNT-1];
  logic [2:0]        in_beat_q  [0:S_COUNT-1];
  logic              active_fire_c [0:S_COUNT-1];

  // --------------------------------------------------------------------------
  // Fair per-output arbitration for the first beat of a new frame.
  // Only one new frame is reserved per output in one cycle, while different
  // outputs arbitrate completely independently and therefore proceed in
  // parallel.
  // --------------------------------------------------------------------------
  always_comb begin : p_allocate
    integer o;
    integer k;
    integer idx;

    for (o = 0; o < M_COUNT; o = o + 1) begin
      alloc_grant_valid_c[o] = 1'b0;
      alloc_grant_input_c[o] = 2'b00;

      if (rst_ni && (frame_count_q[o] < SLOTS)) begin
        for (k = 0; k < S_COUNT; k = k + 1) begin
          idx = alloc_rr_q[o] + k;
          if (idx >= S_COUNT) begin
            idx = idx - S_COUNT;
          end

          if ((!alloc_grant_valid_c[o]) &&
              (!in_frame_q[idx]) &&
              s_valid_i[idx] &&
              (s_dest[idx] == o[DEST_W-1:0])) begin
            alloc_grant_valid_c[o] = 1'b1;
            alloc_grant_input_c[o] = idx[1:0];
          end
        end
      end
    end
  end

  // --------------------------------------------------------------------------
  // Input ready generation.
  //
  // A frame that already owns a slot can always continue: its storage has been
  // reserved through the last beat.  A new frame is ready exactly when its
  // destination's independent allocator grants it a free frame slot.
  // --------------------------------------------------------------------------
  always_comb begin : p_input_ready
    integer i;
    integer o;

    s_ready_o = '0;

    for (i = 0; i < S_COUNT; i = i + 1) begin
      active_fire_c[i] = 1'b0;

      if (rst_ni && in_frame_q[i]) begin
        s_ready_o[i] = 1'b1;
      end
    end

    for (o = 0; o < M_COUNT; o = o + 1) begin
      alloc_fire_c[o] = 1'b0;

      if (rst_ni && alloc_grant_valid_c[o]) begin
        s_ready_o[alloc_grant_input_c[o]] = 1'b1;
        alloc_fire_c[o] = s_valid_i[alloc_grant_input_c[o]];
      end
    end

    for (i = 0; i < S_COUNT; i = i + 1) begin
      active_fire_c[i] = rst_ni && in_frame_q[i] &&
                         s_valid_i[i] && s_ready_o[i];
    end
  end

  // --------------------------------------------------------------------------
  // Output datapaths.  The head frame of each output is independent, so up to
  // M_COUNT beats can transfer in the same cycle.  Storage is not modified once
  // frame_complete_q is set, so a stalled VALID/payload remains stable.
  // --------------------------------------------------------------------------
  always_comb begin : p_outputs
    integer o;

    m_valid_o = '0;
    m_data_o  = '0;
    m_keep_o  = '0;
    m_last_o  = '0;

    for (o = 0; o < M_COUNT; o = o + 1) begin
      drain_last_fire_c[o] = 1'b0;

      if (rst_ni &&
          (frame_count_q[o] != 0) &&
          frame_complete_q[o][drain_ptr_q[o]]) begin
        m_valid_o[o] = 1'b1;
        m_data_o[o*DATA_W +: DATA_W] =
          frame_data_q[o][drain_ptr_q[o]][out_beat_q[o]];
        m_keep_o[o*KEEP_W +: KEEP_W] =
          frame_keep_q[o][drain_ptr_q[o]][out_beat_q[o]];
        m_last_o[o] = frame_last_q[o][drain_ptr_q[o]][out_beat_q[o]];

        drain_last_fire_c[o] = m_ready_i[o] && m_last_o[o];
      end
    end
  end

  // --------------------------------------------------------------------------
  // State and frame memories.
  // --------------------------------------------------------------------------
  always_ff @(posedge clk_i or negedge rst_ni) begin : p_state
    integer i;
    integer o;
    integer sl;
    integer b;
    integer gi;

    if (!rst_ni) begin
      for (i = 0; i < S_COUNT; i = i + 1) begin
        in_frame_q[i] <= 1'b0;
        in_dest_q[i]  <= '0;
        in_slot_q[i]  <= 1'b0;
        in_beat_q[i]  <= 3'b000;
      end

      for (o = 0; o < M_COUNT; o = o + 1) begin
        alloc_ptr_q[o]   <= 1'b0;
        drain_ptr_q[o]   <= 1'b0;
        frame_count_q[o] <= 2'b00;
        out_beat_q[o]    <= 3'b000;
        alloc_rr_q[o]    <= 2'b00;

        for (sl = 0; sl < SLOTS; sl = sl + 1) begin
          frame_complete_q[o][sl] <= 1'b0;
          for (b = 0; b < MAX_BEATS; b = b + 1) begin
            frame_data_q[o][sl][b] <= '0;
            frame_keep_q[o][sl][b] <= '0;
            frame_last_q[o][sl][b] <= 1'b0;
          end
        end
      end
    end
    else begin
      // Continue frames whose slots were reserved on an earlier cycle.
      for (i = 0; i < S_COUNT; i = i + 1) begin
        if (active_fire_c[i]) begin
          frame_data_q[in_dest_q[i]][in_slot_q[i]][in_beat_q[i]] <= s_data[i];
          frame_keep_q[in_dest_q[i]][in_slot_q[i]][in_beat_q[i]] <= s_keep[i];
          frame_last_q[in_dest_q[i]][in_slot_q[i]][in_beat_q[i]] <= s_last_i[i];

          if (s_last_i[i]) begin
            frame_complete_q[in_dest_q[i]][in_slot_q[i]] <= 1'b1;
            in_frame_q[i] <= 1'b0;
            in_beat_q[i] <= 3'b000;
          end
          else begin
            in_beat_q[i] <= in_beat_q[i] + 1'b1;
          end
        end
      end

      // Reserve slots and store first beats of newly accepted frames.
      for (o = 0; o < M_COUNT; o = o + 1) begin
        if (alloc_fire_c[o]) begin
          gi = alloc_grant_input_c[o];

          frame_data_q[o][alloc_ptr_q[o]][0] <= s_data[gi];
          frame_keep_q[o][alloc_ptr_q[o]][0] <= s_keep[gi];
          frame_last_q[o][alloc_ptr_q[o]][0] <= s_last_i[gi];
          frame_complete_q[o][alloc_ptr_q[o]] <= s_last_i[gi];

          if (!s_last_i[gi]) begin
            in_frame_q[gi] <= 1'b1;
            in_dest_q[gi] <= o[DEST_W-1:0];
            in_slot_q[gi] <= alloc_ptr_q[o];
            in_beat_q[gi] <= 3'd1;
          end
          else begin
            in_frame_q[gi] <= 1'b0;
            in_beat_q[gi] <= 3'b000;
          end

          alloc_ptr_q[o] <= ~alloc_ptr_q[o];

          if (gi == (S_COUNT-1)) begin
            alloc_rr_q[o] <= 2'b00;
          end
          else begin
            alloc_rr_q[o] <= gi[1:0] + 1'b1;
          end
        end

        // Advance within a completed head frame, or retire it on LAST.
        if (m_valid_o[o] && m_ready_i[o]) begin
          if (m_last_o[o]) begin
            frame_complete_q[o][drain_ptr_q[o]] <= 1'b0;
            drain_ptr_q[o] <= ~drain_ptr_q[o];
            out_beat_q[o] <= 3'b000;
          end
          else begin
            out_beat_q[o] <= out_beat_q[o] + 1'b1;
          end
        end

        // Allocated-frame occupancy includes frames still being filled.  This
        // is what makes the physical storage ceiling exactly two frames/output.
        case ({alloc_fire_c[o], drain_last_fire_c[o]})
          2'b10: frame_count_q[o] <= frame_count_q[o] + 1'b1;
          2'b01: frame_count_q[o] <= frame_count_q[o] - 1'b1;
          default: frame_count_q[o] <= frame_count_q[o];
        endcase
      end
    end
  end

endmodule