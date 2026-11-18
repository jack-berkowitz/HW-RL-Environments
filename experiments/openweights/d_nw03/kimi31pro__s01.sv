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

  localparam logic [1:0] SLOT_FREE    = 2'd0;
  localparam logic [1:0] SLOT_WRITING = 2'd1;
  localparam logic [1:0] SLOT_READY   = 2'd2;

  localparam logic [S_W-1:0] LAST_INPUT = S_COUNT-1;

  // Two eight-beat frame slots per output. A slot is not visible at the
  // output until its complete frame has been accepted.
  logic [1:0]        slot_state [M_COUNT-1:0][1:0];
  logic [DATA_W-1:0] data_mem   [M_COUNT-1:0][1:0][7:0];
  logic [KEEP_W-1:0] keep_mem   [M_COUNT-1:0][1:0][7:0];
  logic              last_mem   [M_COUNT-1:0][1:0][7:0];

  logic [M_COUNT-1:0] wr_active;
  logic [S_W-1:0]     wr_input  [M_COUNT-1:0];
  logic [2:0]         wr_beat   [M_COUNT-1:0];
  logic               wr_ptr    [M_COUNT-1:0];

  logic               rd_ptr    [M_COUNT-1:0];
  logic [2:0]         rd_beat   [M_COUNT-1:0];

  logic [S_W-1:0]     rr_ptr    [M_COUNT-1:0];

  logic [M_COUNT-1:0] arb_valid;
  logic [S_W-1:0]     arb_input [M_COUNT-1:0];

  // Independent per-output arbitration and write paths. An active writer
  // retains its output until the final beat, while round-robin selection at
  // frame boundaries prevents starvation.
  always_comb begin : p_arbitration
    integer o;
    integer k;
    integer idx;

    s_ready_o = '0;
    arb_valid = '0;

    for (o = 0; o < M_COUNT; o = o + 1) begin
      arb_input[o] = '0;
      idx = 0;

      if (wr_active[o]) begin
        s_ready_o[wr_input[o]] = 1'b1;
      end else if (slot_state[o][wr_ptr[o]] == SLOT_FREE) begin
        for (k = 0; k < S_COUNT; k = k + 1) begin
          idx = rr_ptr[o] + k;
          if (idx >= S_COUNT)
            idx = idx - S_COUNT;

          if (!arb_valid[o] && s_valid_i[idx] &&
              (s_dest_i[idx*DEST_W +: DEST_W] == o[DEST_W-1:0])) begin
            arb_valid[o]  = 1'b1;
            arb_input[o]  = idx[S_W-1:0];
            s_ready_o[idx] = 1'b1;
          end
        end
      end
    end
  end

  always_ff @(posedge clk_i) begin : p_state
    integer o;

    if (!rst_ni) begin
      wr_active <= '0;

      for (o = 0; o < M_COUNT; o = o + 1) begin
        slot_state[o][0] <= SLOT_FREE;
        slot_state[o][1] <= SLOT_FREE;
        wr_input[o]      <= '0;
        wr_beat[o]       <= '0;
        wr_ptr[o]        <= 1'b0;
        rd_ptr[o]        <= 1'b0;
        rd_beat[o]       <= '0;
        rr_ptr[o]        <= '0;
      end
    end else begin
      for (o = 0; o < M_COUNT; o = o + 1) begin
        // Drain the oldest complete frame. The read pointer cannot advance
        // while stalled, so all output signals remain stable.
        if (m_valid_o[o] && m_ready_i[o]) begin
          if (last_mem[o][rd_ptr[o]][rd_beat[o]]) begin
            slot_state[o][rd_ptr[o]] <= SLOT_FREE;
            rd_ptr[o]  <= ~rd_ptr[o];
            rd_beat[o] <= '0;
          end else begin
            rd_beat[o] <= rd_beat[o] + 3'd1;
          end
        end

        if (wr_active[o]) begin
          if (s_valid_i[wr_input[o]]) begin
            data_mem[o][wr_ptr[o]][wr_beat[o]] <=
              s_data_i[wr_input[o]*DATA_W +: DATA_W];
            keep_mem[o][wr_ptr[o]][wr_beat[o]] <=
              s_keep_i[wr_input[o]*KEEP_W +: KEEP_W];
            last_mem[o][wr_ptr[o]][wr_beat[o]] <=
              s_last_i[wr_input[o]];

            if (s_last_i[wr_input[o]]) begin
              slot_state[o][wr_ptr[o]] <= SLOT_READY;
              wr_active[o] <= 1'b0;
              wr_ptr[o]    <= ~wr_ptr[o];
              wr_beat[o]   <= '0;

              if (wr_input[o] == LAST_INPUT)
                rr_ptr[o] <= '0;
              else
                rr_ptr[o] <= wr_input[o] + 1'b1;
            end else begin
              wr_beat[o] <= wr_beat[o] + 3'd1;
            end
          end
        end else if (arb_valid[o]) begin
          data_mem[o][wr_ptr[o]][0] <=
            s_data_i[arb_input[o]*DATA_W +: DATA_W];
          keep_mem[o][wr_ptr[o]][0] <=
            s_keep_i[arb_input[o]*KEEP_W +: KEEP_W];
          last_mem[o][wr_ptr[o]][0] <=
            s_last_i[arb_input[o]];

          if (s_last_i[arb_input[o]]) begin
            slot_state[o][wr_ptr[o]] <= SLOT_READY;
            wr_ptr[o]  <= ~wr_ptr[o];
            wr_beat[o] <= '0;

            if (arb_input[o] == LAST_INPUT)
              rr_ptr[o] <= '0;
            else
              rr_ptr[o] <= arb_input[o] + 1'b1;
          end else begin
            slot_state[o][wr_ptr[o]] <= SLOT_WRITING;
            wr_active[o] <= 1'b1;
            wr_input[o]  <= arb_input[o];
            wr_beat[o]   <= 3'd1;
          end
        end
      end
    end
  end

  generate
    for (genvar g = 0; g < M_COUNT; g = g + 1) begin : g_output
      assign m_valid_o[g] =
        (slot_state[g][rd_ptr[g]] == SLOT_READY);
      assign m_data_o[g*DATA_W +: DATA_W] =
        data_mem[g][rd_ptr[g]][rd_beat[g]];
      assign m_keep_o[g*KEEP_W +: KEEP_W] =
        keep_mem[g][rd_ptr[g]][rd_beat[g]];
      assign m_last_o[g] =
        last_mem[g][rd_ptr[g]][rd_beat[g]];
    end
  endgenerate

endmodule
