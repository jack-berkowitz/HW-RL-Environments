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

  // Each output has storage for exactly two maximum-length frames.  A new
  // frame is admitted only when all eight of its possible beats can be
  // accommodated, so an accepted frame cannot be stranded by a full queue.
  logic [S_COUNT-1:0] grant_matrix [0:M_COUNT-1];

  integer ready_s;
  integer ready_m;

  always_comb begin
    s_ready_o = '0;
    for (ready_m = 0; ready_m < M_COUNT; ready_m = ready_m + 1) begin
      for (ready_s = 0; ready_s < S_COUNT; ready_s = ready_s + 1) begin
        if (grant_matrix[ready_m][ready_s]) begin
          s_ready_o[ready_s] = 1'b1;
        end
      end
    end
  end

  for (genvar out_idx = 0; out_idx < M_COUNT; out_idx = out_idx + 1) begin : gen_output_queue
    logic [DATA_W-1:0] data_mem [0:15];
    logic [KEEP_W-1:0] keep_mem [0:15];
    logic              last_mem [0:15];

    logic [3:0] write_ptr;
    logic [3:0] read_ptr;
    logic [4:0] beat_count;
    logic [1:0] frame_count;

    logic             writer_active;
    logic [S_W-1:0]   writer_id;
    logic [S_W-1:0]   rr_ptr;

    logic             push;
    logic [S_W-1:0]   push_source;
    logic             pop;
    logic             start_frame;
    logic             write_last;
    logic             read_last;

    logic             found;
    integer           arb_offset;
    integer           arb_candidate;

    assign m_valid_o[out_idx] = (beat_count != 0);
    assign m_data_o[out_idx*DATA_W +: DATA_W] = data_mem[read_ptr];
    assign m_keep_o[out_idx*KEEP_W +: KEEP_W] = keep_mem[read_ptr];
    assign m_last_o[out_idx] = last_mem[read_ptr];

    assign pop         = m_valid_o[out_idx] && m_ready_i[out_idx];
    assign start_frame = push && !writer_active;
    assign write_last  = push && s_last_i[push_source];
    assign read_last   = pop && last_mem[read_ptr];

    // Independent per-output, per-frame round-robin arbitration.  The writer
    // lock remains in place across input-valid gaps until that frame's last
    // beat has been accepted.
    always_comb begin
      grant_matrix[out_idx] = '0;
      push                  = 1'b0;
      push_source           = rr_ptr;
      found                 = 1'b0;
      arb_candidate         = 0;

      if (writer_active) begin
        if (s_valid_i[writer_id] && (beat_count < 5'd16)) begin
          push        = 1'b1;
          push_source = writer_id;
        end
      end else if ((frame_count < 2'd2) && (beat_count <= 5'd8)) begin
        for (arb_offset = 0; arb_offset < S_COUNT; arb_offset = arb_offset + 1) begin
          arb_candidate = rr_ptr + arb_offset;
          if (arb_candidate >= S_COUNT) begin
            arb_candidate = arb_candidate - S_COUNT;
          end

          if (!found && s_valid_i[arb_candidate] &&
              (s_dest_i[arb_candidate*DEST_W +: DEST_W] == out_idx)) begin
            found       = 1'b1;
            push        = 1'b1;
            push_source = arb_candidate;
          end
        end
      end

      if (push) begin
        grant_matrix[out_idx][push_source] = 1'b1;
      end
    end

    always_ff @(posedge clk_i) begin
      if (!rst_ni) begin
        write_ptr     <= 4'd0;
        read_ptr      <= 4'd0;
        beat_count    <= 5'd0;
        frame_count   <= 2'd0;
        writer_active <= 1'b0;
        writer_id     <= '0;
        rr_ptr        <= '0;
      end else begin
        if (push) begin
          data_mem[write_ptr] <= s_data_i[push_source*DATA_W +: DATA_W];
          keep_mem[write_ptr] <= s_keep_i[push_source*KEEP_W +: KEEP_W];
          last_mem[write_ptr] <= s_last_i[push_source];
          write_ptr           <= write_ptr + 4'd1;
        end

        if (pop) begin
          read_ptr <= read_ptr + 4'd1;
        end

        case ({push, pop})
          2'b10:   beat_count <= beat_count + 5'd1;
          2'b01:   beat_count <= beat_count - 5'd1;
          default: beat_count <= beat_count;
        endcase

        case ({start_frame, read_last})
          2'b10:   frame_count <= frame_count + 2'd1;
          2'b01:   frame_count <= frame_count - 2'd1;
          default: frame_count <= frame_count;
        endcase

        if (write_last) begin
          writer_active <= 1'b0;
          if (push_source == S_COUNT-1) begin
            rr_ptr <= '0;
          end else begin
            rr_ptr <= push_source + 1'b1;
          end
        end else if (push) begin
          writer_active <= 1'b1;
          writer_id     <= push_source;
        end
      end
    end
  end

endmodule
