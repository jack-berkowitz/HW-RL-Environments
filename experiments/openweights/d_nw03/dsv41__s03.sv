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
  localparam int unsigned SLOTS = 2;
  localparam int unsigned MAX_BEATS = 8;
  localparam int unsigned SW = $clog2(S_COUNT);

  localparam [1:0] SLOT_FREE    = 2'd0;
  localparam [1:0] SLOT_WRITING = 2'd1;
  localparam [1:0] SLOT_FULL    = 2'd2;

  // Per-output storage: 2 slots, each up to 8 beats
  logic [DATA_W-1:0] slot_data [M_COUNT][SLOTS][MAX_BEATS];
  logic [KEEP_W-1:0] slot_keep [M_COUNT][SLOTS][MAX_BEATS];
  logic [2:0]        slot_last [M_COUNT][SLOTS];
  logic [1:0]        slot_state[M_COUNT][SLOTS];
  logic              slot_seq  [M_COUNT][SLOTS];

  // Per-output allocation sequence (toggles on each new frame allocation)
  logic alloc_seq [M_COUNT];

  // Per-input state
  logic              in_active [S_COUNT];
  logic [DEST_W-1:0] in_dest   [S_COUNT];
  logic              in_slot   [S_COUNT];
  logic [2:0]        in_beat   [S_COUNT];

  // Per-output read state
  logic              out_reading [M_COUNT];
  logic              out_slot    [M_COUNT];
  logic [2:0]        out_idx     [M_COUNT];

  // Write arbitration round-robin pointers
  logic [SW-1:0] wr_rr [M_COUNT];

  // Combinational signals
  logic [S_COUNT-1:0] wr_grant;
  logic [S_COUNT-1:0] s_ready_int;
  logic [M_COUNT-1:0] free_avail;
  logic [M_COUNT-1:0] full_avail;
  logic               free_slot_sel [M_COUNT];
  logic [M_COUNT-1:0] m_valid_int;
  logic [M_COUNT*DATA_W-1:0] m_data_int;
  logic [M_COUNT*KEEP_W-1:0] m_keep_int;
  logic [M_COUNT-1:0] m_last_int;

  assign s_ready_o = s_ready_int;
  assign m_valid_o = m_valid_int;
  assign m_data_o  = m_data_int;
  assign m_keep_o  = m_keep_int;
  assign m_last_o  = m_last_int;

  // Combinational logic
  always_comb begin
    integer m, s, off;
    logic found;
    logic [SW-1:0] start;
    logic [SW-1:0] s_idx;

    wr_grant = '0;
    s_ready_int = '0;
    free_avail = '0;
    full_avail = '0;
    m_valid_int = '0;
    m_data_int = '0;
    m_keep_int = '0;
    m_last_int = '0;

    // Compute availability and free slot selection
    for (m = 0; m < M_COUNT; m = m + 1) begin
      free_avail[m] = (slot_state[m][0] == SLOT_FREE) || (slot_state[m][1] == SLOT_FREE);
      full_avail[m] = (slot_state[m][0] == SLOT_FULL) || (slot_state[m][1] == SLOT_FULL);
      if (slot_state[m][0] == SLOT_FREE) begin
        free_slot_sel[m] = 1'b0;
      end else begin
        free_slot_sel[m] = 1'b1;
      end
    end

    // Write arbitration: round-robin per output
    for (m = 0; m < M_COUNT; m = m + 1) begin
      if (free_avail[m]) begin
        found = 1'b0;
        start = wr_rr[m];
        for (off = 0; off < S_COUNT; off = off + 1) begin
          s_idx = (start + off) % S_COUNT;
          if (!found && !in_active[s_idx] && s_valid_i[s_idx] &&
              (s_dest_i[s_idx*DEST_W +: DEST_W] == m)) begin
            wr_grant[s_idx] = 1'b1;
            found = 1'b1;
          end
        end
      end
    end

    // Input ready
    for (s = 0; s < S_COUNT; s = s + 1) begin
      if (in_active[s]) begin
        s_ready_int[s] = 1'b1;
      end else begin
        s_ready_int[s] = wr_grant[s];
      end
    end

    // Output mux
    for (m = 0; m < M_COUNT; m = m + 1) begin
      if (out_reading[m]) begin
        m_valid_int[m] = 1'b1;
        m_data_int[m*DATA_W +: DATA_W] = slot_data[m][out_slot[m]][out_idx[m]];
        m_keep_int[m*KEEP_W +: KEEP_W] = slot_keep[m][out_slot[m]][out_idx[m]];
        m_last_int[m] = (out_idx[m] == slot_last[m][out_slot[m]]);
      end else begin
        m_valid_int[m] = 1'b0;
        m_data_int[m*DATA_W +: DATA_W] = '0;
        m_keep_int[m*KEEP_W +: KEEP_W] = '0;
        m_last_int[m] = 1'b0;
      end
    end
  end

  // Sequential logic
  always_ff @(posedge clk_i) begin
    integer m, s;
    logic [DEST_W-1:0] dest;
    logic chosen_slot;
    logic [2:0] last_idx;

    if (!rst_ni) begin
      for (m = 0; m < M_COUNT; m = m + 1) begin
        slot_state[m][0] <= SLOT_FREE;
        slot_state[m][1] <= SLOT_FREE;
        slot_last[m][0] <= '0;
        slot_last[m][1] <= '0;
        slot_seq[m][0] <= 1'b0;
        slot_seq[m][1] <= 1'b0;
        alloc_seq[m] <= 1'b0;
        out_reading[m] <= 1'b0;
        out_slot[m] <= 1'b0;
        out_idx[m] <= '0;
        wr_rr[m] <= '0;
      end
      for (s = 0; s < S_COUNT; s = s + 1) begin
        in_active[s] <= 1'b0;
        in_dest[s] <= '0;
        in_slot[s] <= 1'b0;
        in_beat[s] <= '0;
      end
    end else begin
      // Write side
      for (s = 0; s < S_COUNT; s = s + 1) begin
        if (s_valid_i[s] && s_ready_int[s]) begin
          if (!in_active[s]) begin
            // Allocate new slot
            dest = s_dest_i[s*DEST_W +: DEST_W];
            chosen_slot = free_slot_sel[dest];
            slot_seq[dest][chosen_slot] <= alloc_seq[dest];
            alloc_seq[dest] <= ~alloc_seq[dest];
            slot_data[dest][chosen_slot][0] <= s_data_i[s*DATA_W +: DATA_W];
            slot_keep[dest][chosen_slot][0] <= s_keep_i[s*KEEP_W +: KEEP_W];
            if (s_last_i[s]) begin
              slot_last[dest][chosen_slot] <= 3'd0;
              slot_state[dest][chosen_slot] <= SLOT_FULL;
              in_active[s] <= 1'b0;
            end else begin
              slot_state[dest][chosen_slot] <= SLOT_WRITING;
              in_active[s] <= 1'b1;
              in_dest[s] <= dest;
              in_slot[s] <= chosen_slot;
              in_beat[s] <= 3'd1;
            end
          end else begin
            // Active, write next beat
            dest = in_dest[s];
            chosen_slot = in_slot[s];
            last_idx = in_beat[s];
            slot_data[dest][chosen_slot][last_idx] <= s_data_i[s*DATA_W +: DATA_W];
            slot_keep[dest][chosen_slot][last_idx] <= s_keep_i[s*KEEP_W +: KEEP_W];
            if (s_last_i[s]) begin
              slot_last[dest][chosen_slot] <= last_idx;
              slot_state[dest][chosen_slot] <= SLOT_FULL;
              in_active[s] <= 1'b0;
            end else begin
              in_beat[s] <= in_beat[s] + 3'd1;
            end
          end
        end
      end

      // Update write round-robin pointers
      for (m = 0; m < M_COUNT; m = m + 1) begin
        for (s = 0; s < S_COUNT; s = s + 1) begin
          if (wr_grant[s] && (s_dest_i[s*DEST_W +: DEST_W] == m)) begin
            wr_rr[m] <= (s + 1) % S_COUNT;
          end
        end
      end

      // Read side
      for (m = 0; m < M_COUNT; m = m + 1) begin
        if (out_reading[m]) begin
          if (m_ready_i[m]) begin
            if (out_idx[m] == slot_last[m][out_slot[m]]) begin
              out_reading[m] <= 1'b0;
              slot_state[m][out_slot[m]] <= SLOT_FREE;
            end else begin
              out_idx[m] <= out_idx[m] + 3'd1;
            end
          end
        end else begin
          if (full_avail[m]) begin
            // Choose oldest full slot
            if ((slot_state[m][0] == SLOT_FULL) && (slot_state[m][1] == SLOT_FULL)) begin
              if (slot_seq[m][0] == alloc_seq[m]) begin
                chosen_slot = 1'b0;
              end else begin
                chosen_slot = 1'b1;
              end
            end else if (slot_state[m][0] == SLOT_FULL) begin
              chosen_slot = 1'b0;
            end else begin
              chosen_slot = 1'b1;
            end
            out_slot[m] <= chosen_slot;
            out_idx[m] <= 3'd0;
            out_reading[m] <= 1'b1;
          end
        end
      end
    end
  end

endmodule
