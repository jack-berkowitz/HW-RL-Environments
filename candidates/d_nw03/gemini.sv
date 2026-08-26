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

  // Derived by this contract, not parameters.
  localparam int unsigned KEEP_W = DATA_W/8;
  localparam int unsigned DEST_W = $clog2(M_COUNT);
  localparam int unsigned S_W    = $clog2(S_COUNT);

  // Cross-module signal to aggregate the `ready` outputs from each destination arbiter.
  logic [M_COUNT-1:0][S_COUNT-1:0] out_granted_and_ready;

  genvar m;
  generate
    for (m = 0; m < M_COUNT; m++) begin : gen_out
      localparam logic [DEST_W-1:0] M_IDX = m[DEST_W-1:0];

      // -----------------------------------------------------------------------
      // Output-queued FIFO (depth 16 max, ensuring 2 frames bound B1)
      // -----------------------------------------------------------------------
      localparam int FIFO_DEPTH = 16;
      localparam int FIFO_AW    = 4;

      logic [DATA_W+KEEP_W:0] fifo_mem [FIFO_DEPTH];
      logic [FIFO_AW:0]       fifo_wr_ptr;
      logic [FIFO_AW:0]       fifo_rd_ptr;

      logic fifo_full;
      logic fifo_empty;
      logic fifo_ready;
      logic fifo_push;
      logic fifo_pop;

      assign fifo_full  = (fifo_wr_ptr[FIFO_AW] != fifo_rd_ptr[FIFO_AW]) && 
                          (fifo_wr_ptr[FIFO_AW-1:0] == fifo_rd_ptr[FIFO_AW-1:0]);
      assign fifo_empty = (fifo_wr_ptr == fifo_rd_ptr);
      assign fifo_ready = !fifo_full;

      // -----------------------------------------------------------------------
      // Per-Output Arbiter and Multiplexer State
      // -----------------------------------------------------------------------
      logic locked_q;
      logic [S_COUNT-1:0] grant_oh_q;
      logic [S_W-1:0]     rr_ptr;

      logic [S_COUNT-1:0] current_req;
      logic [S_COUNT-1:0] mask;
      logic [S_COUNT-1:0] req_masked;
      logic [S_COUNT-1:0] pe_masked;
      logic [S_COUNT-1:0] pe_raw;
      logic [S_COUNT-1:0] grant_oh;
      
      logic [S_COUNT-1:0] active_grant_oh;
      logic               active_valid;
      logic               transfer_beat;
      logic               is_last;
      logic               transfer_last;

      logic [DATA_W-1:0]  wdata;
      logic [KEEP_W-1:0]  wkeep;
      logic               wlast;
      logic [S_W-1:0]     next_rr;

      // Ensure variable declarations precede the first statement inside procedural blocks.
      always_comb begin
        int s;
        logic prev_masked_or;
        logic prev_raw_or;
        logic [31:0] s_plus_1;

        current_req    = '0;
        mask           = '0;
        req_masked     = '0;
        pe_masked      = '0;
        pe_raw         = '0;
        grant_oh       = '0;
        prev_masked_or = 1'b0;
        prev_raw_or    = 1'b0;
        s_plus_1       = '0;
        next_rr        = '0;
        wdata          = '0;
        wkeep          = '0;
        wlast          = 1'b0;

        // 1. Identify which inputs are valid and targeted at this specific output.
        for (s = 0; s < S_COUNT; s++) begin
          if (s_valid_i[s] && (s_dest_i[s*DEST_W +: DEST_W] == M_IDX)) begin
            current_req[s] = 1'b1;
          end
          if (s >= rr_ptr) begin
            mask[s] = 1'b1;
          end
        end

        // 2. Round-Robin Arbitration Priority Encoders
        req_masked = current_req & mask;
        
        for (s = 0; s < S_COUNT; s++) begin
          pe_masked[s] = req_masked[s] & ~prev_masked_or;
          prev_masked_or |= req_masked[s];
        end
        for (s = 0; s < S_COUNT; s++) begin
          pe_raw[s] = current_req[s] & ~prev_raw_or;
          prev_raw_or |= current_req[s];
        end
        
        if (|req_masked) begin
          grant_oh = pe_masked;
        end else begin
          grant_oh = pe_raw;
        end

        // 3. Atomicity Lock (hold ongoing frame uninterrupted)
        if (locked_q) begin
          active_grant_oh = grant_oh_q;
        end else begin
          active_grant_oh = grant_oh;
        end

        active_valid  = |(current_req & active_grant_oh);
        transfer_beat = active_valid & fifo_ready;
        
        is_last       = |(s_last_i & active_grant_oh);
        transfer_last = transfer_beat & is_last;

        // 4. Multiplexing granted data
        for (s = 0; s < S_COUNT; s++) begin
          if (active_grant_oh[s]) begin
            wdata |= s_data_i[s*DATA_W +: DATA_W];
            wkeep |= s_keep_i[s*KEEP_W +: KEEP_W];
            wlast |= s_last_i[s];
            
            s_plus_1 = s + 1;
            if (s == S_COUNT - 1) begin
              next_rr = '0;
            end else begin
              next_rr = s_plus_1[S_W-1:0];
            end
          end
        end
      end

      // State transitions for round-robin pointer and frame lock
      always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
          locked_q   <= 1'b0;
          grant_oh_q <= '0;
          rr_ptr     <= '0;
        end else begin
          if (!locked_q) begin
            if (active_valid) begin
              if (!transfer_last) begin
                locked_q   <= 1'b1;
                grant_oh_q <= active_grant_oh;
              end else begin
                rr_ptr <= next_rr;
              end
            end
          end else begin
            if (transfer_last) begin
              locked_q <= 1'b0;
              rr_ptr   <= next_rr;
            end
          end
        end
      end

      // Feed granted ready assignments upward
      assign out_granted_and_ready[m] = active_grant_oh & {S_COUNT{fifo_ready}};

      // -----------------------------------------------------------------------
      // Synchronous FIFO Memory & Pointers
      // -----------------------------------------------------------------------
      assign fifo_push = transfer_beat;
      assign fifo_pop  = m_valid_o[m] & m_ready_i[m];
      
      assign m_valid_o[m] = !fifo_empty;

      always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
          fifo_wr_ptr <= '0;
          fifo_rd_ptr <= '0;
        end else begin
          if (fifo_push) fifo_wr_ptr <= fifo_wr_ptr + 1'b1;
          if (fifo_pop)  fifo_rd_ptr <= fifo_rd_ptr + 1'b1;
        end
      end

      // Unpacked array maps perfectly to FWFT LUTRAM semantics
      always_ff @(posedge clk_i) begin
        if (fifo_push) begin
          fifo_mem[fifo_wr_ptr[FIFO_AW-1:0]] <= {wdata, wkeep, wlast};
        end
      end
      
      logic [DATA_W+KEEP_W:0] fifo_rdata;
      assign fifo_rdata = fifo_mem[fifo_rd_ptr[FIFO_AW-1:0]];
      
      assign m_data_o[m*DATA_W +: DATA_W] = fifo_rdata[DATA_W+KEEP_W : KEEP_W+1];
      assign m_keep_o[m*KEEP_W +: KEEP_W] = fifo_rdata[KEEP_W : 1];
      assign m_last_o[m]                  = fifo_rdata[0];
    end
  endgenerate

  // ---------------------------------------------------------------------------
  // Global Ready aggregation - An input sees ready if its chosen output grants it
  // ---------------------------------------------------------------------------
  always_comb begin
    int s;
    int m_idx;
    s_ready_o = '0;
    for (s = 0; s < S_COUNT; s++) begin
      for (m_idx = 0; m_idx < M_COUNT; m_idx++) begin
        s_ready_o[s] |= out_granted_and_ready[m_idx][s];
      end
    end
  end

endmodule