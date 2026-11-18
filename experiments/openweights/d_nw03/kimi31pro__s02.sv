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
  localparam int unsigned SRC_W  = $clog2(S_COUNT);

  logic [DATA_W-1:0] s_data [S_COUNT];
  logic [KEEP_W-1:0] s_keep [S_COUNT];
  logic [DEST_W-1:0] s_dest [S_COUNT];

  // Two frame slots per output, each holding at most eight beats.
  logic [DATA_W-1:0] data_mem [M_COUNT][2][8];
  logic [KEEP_W-1:0] keep_mem [M_COUNT][2][8];
  logic [3:0]        slot_len [M_COUNT][2];

  logic [1:0]        slot_valid [M_COUNT];
  logic              head_slot [M_COUNT];
  logic              tail_slot [M_COUNT];
  logic [2:0]        rd_pos [M_COUNT];

  logic              w_active [M_COUNT];
  logic              w_slot [M_COUNT];
  logic [SRC_W-1:0]  w_src [M_COUNT];
  logic [2:0]        w_pos [M_COUNT];
  logic [SRC_W-1:0]  rr_ptr [M_COUNT];

  logic [S_COUNT-1:0] sel_onehot [M_COUNT];
  logic [SRC_W-1:0]   sel_src [M_COUNT];
  logic               sel_write [M_COUNT];
  logic               sel_slot [M_COUNT];
  logic [2:0]         sel_pos [M_COUNT];

  genvar gi;
  genvar go;

  generate
    for (gi = 0; gi < S_COUNT; gi = gi + 1) begin : gen_input_unpack
      assign s_data[gi] = s_data_i[gi*DATA_W +: DATA_W];
      assign s_keep[gi] = s_keep_i[gi*KEEP_W +: KEEP_W];
      assign s_dest[gi] = s_dest_i[gi*DEST_W +: DEST_W];
    end

    for (go = 0; go < M_COUNT; go = go + 1) begin : gen_output_queue
      always_comb begin : arbitration
        int unsigned k;
        int unsigned idx;
        logic found;

        sel_onehot[go] = '0;
        sel_src[go]    = '0;
        sel_write[go]  = 1'b0;
        sel_slot[go]   = w_active[go] ? w_slot[go] : tail_slot[go];
        sel_pos[go]    = w_active[go] ? w_pos[go] : 3'd0;
        found          = 1'b0;
        idx            = 0;

        if (w_active[go]) begin
          sel_src[go] = w_src[go];
          sel_onehot[go][w_src[go]] = 1'b1;
          if (s_valid_i[w_src[go]]) begin
            sel_write[go] = 1'b1;
          end
        end else if (!slot_valid[go][tail_slot[go]]) begin
          // Round-robin selection at frame granularity.
          for (k = 0; k < S_COUNT; k = k + 1) begin
            idx = rr_ptr[go] + k;
            if (idx >= S_COUNT) begin
              idx = idx - S_COUNT;
            end

            if (!found && s_valid_i[idx] &&
                (s_dest[idx] == DEST_W'(go))) begin
              found = 1'b1;
              sel_src[go] = SRC_W'(idx);
              sel_onehot[go][idx] = 1'b1;
              sel_write[go] = 1'b1;
            end
          end
        end
      end

      assign m_valid_o[go] = slot_valid[go][head_slot[go]];
      assign m_data_o[go*DATA_W +: DATA_W] =
          data_mem[go][head_slot[go]][rd_pos[go]];
      assign m_keep_o[go*KEEP_W +: KEEP_W] =
          keep_mem[go][head_slot[go]][rd_pos[go]];
      assign m_last_o[go] = slot_valid[go][head_slot[go]] &&
          (({1'b0, rd_pos[go]} + 4'd1) ==
           slot_len[go][head_slot[go]]);

      always_ff @(posedge clk_i) begin
        if (!rst_ni) begin
          slot_valid[go] <= 2'b00;
          head_slot[go]  <= 1'b0;
          tail_slot[go]  <= 1'b0;
          rd_pos[go]     <= 3'd0;
          w_active[go]   <= 1'b0;
          w_slot[go]     <= 1'b0;
          w_src[go]      <= '0;
          w_pos[go]      <= 3'd0;
          rr_ptr[go]     <= '0;
          slot_len[go][0] <= 4'd0;
          slot_len[go][1] <= 4'd0;
        end else begin
          if (sel_write[go]) begin
            data_mem[go][sel_slot[go]][sel_pos[go]] <=
                s_data[sel_src[go]];
            keep_mem[go][sel_slot[go]][sel_pos[go]] <=
                s_keep[sel_src[go]];

            if (s_last_i[sel_src[go]]) begin
              slot_valid[go][sel_slot[go]] <= 1'b1;
              slot_len[go][sel_slot[go]] <=
                  {1'b0, sel_pos[go]} + 4'd1;
              w_active[go] <= 1'b0;
              w_pos[go] <= 3'd0;
              tail_slot[go] <= ~tail_slot[go];

              if (sel_src[go] == SRC_W'(S_COUNT-1)) begin
                rr_ptr[go] <= '0;
              end else begin
                rr_ptr[go] <= sel_src[go] + SRC_W'(1);
              end
            end else begin
              w_active[go] <= 1'b1;
              w_slot[go] <= sel_slot[go];
              w_src[go] <= sel_src[go];
              w_pos[go] <= sel_pos[go] + 3'd1;
            end
          end

          if (m_valid_o[go] && m_ready_i[go]) begin
            if (({1'b0, rd_pos[go]} + 4'd1) ==
                slot_len[go][head_slot[go]]) begin
              slot_valid[go][head_slot[go]] <= 1'b0;
              head_slot[go] <= ~head_slot[go];
              rd_pos[go] <= 3'd0;
            end else begin
              rd_pos[go] <= rd_pos[go] + 3'd1;
            end
          end
        end
      end
    end
  endgenerate

  always_comb begin : input_ready
    int unsigned si;
    int unsigned so;

    s_ready_o = '0;
    for (si = 0; si < S_COUNT; si = si + 1) begin
      for (so = 0; so < M_COUNT; so = so + 1) begin
        s_ready_o[si] = s_ready_o[si] | sel_onehot[so][si];
      end
    end
  end

endmodule
