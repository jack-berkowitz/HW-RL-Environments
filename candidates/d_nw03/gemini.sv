// =============================================================================
// axis_switch_oq  --  IMPLEMENTATION
// =============================================================================

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

  // Depth of 16 beats precisely provides storage for up to 2 frames of 8 beats
  // per output, bounded as per B1 requirement.
  localparam int unsigned FIFO_DEPTH = 16;
  localparam int unsigned FIFO_ADDR_W = 4;

  typedef enum logic { IDLE, LOCKED } state_t;
  state_t state_q [M_COUNT];
  state_t state_d [M_COUNT];

  logic [$clog2(S_COUNT)-1:0] locked_sel_q [M_COUNT];
  logic [$clog2(S_COUNT)-1:0] locked_sel_d [M_COUNT];

  logic [$clog2(S_COUNT)-1:0] rr_ptr_q [M_COUNT];
  logic [$clog2(S_COUNT)-1:0] rr_ptr_d [M_COUNT];

  logic [M_COUNT-1:0] grant_valid;
  logic [$clog2(S_COUNT)-1:0] grant_sel [M_COUNT];

  // Output FIFO storage and pointers
  logic [DATA_W-1:0]   fifo_data [M_COUNT][FIFO_DEPTH];
  logic [KEEP_W-1:0]   fifo_keep [M_COUNT][FIFO_DEPTH];
  logic                fifo_last [M_COUNT][FIFO_DEPTH];

  logic [FIFO_ADDR_W:0] fifo_wr_ptr [M_COUNT];
  logic [FIFO_ADDR_W:0] fifo_rd_ptr [M_COUNT];

  logic [M_COUNT-1:0] fifo_full;
  logic [M_COUNT-1:0] fifo_empty;
  logic [M_COUNT-1:0] fifo_ready;
  logic [M_COUNT-1:0] fifo_wr;
  
  logic [DATA_W-1:0]  fifo_din_data [M_COUNT];
  logic [KEEP_W-1:0]  fifo_din_keep [M_COUNT];
  logic               fifo_din_last [M_COUNT];

  // 1. FIFO Status Logic
  always_comb begin
    int m;
    for (m = 0; m < M_COUNT; m++) begin
        fifo_full[m] = (fifo_wr_ptr[m][FIFO_ADDR_W] != fifo_rd_ptr[m][FIFO_ADDR_W]) &&
                       (fifo_wr_ptr[m][FIFO_ADDR_W-1:0] == fifo_rd_ptr[m][FIFO_ADDR_W-1:0]);
        fifo_empty[m] = (fifo_wr_ptr[m] == fifo_rd_ptr[m]);
        fifo_ready[m] = ~fifo_full[m];
    end
  end

  // 2. Round-Robin Output Arbiters
  always_comb begin
    int m;
    int i;
    int idx;
    logic any_req;
    logic [$clog2(S_COUNT)-1:0] first_req;
    
    for (m = 0; m < M_COUNT; m++) begin
        state_d[m] = state_q[m];
        locked_sel_d[m] = locked_sel_q[m];
        rr_ptr_d[m] = rr_ptr_q[m];
        
        grant_valid[m] = 1'b0;
        grant_sel[m] = '0;
        
        if (state_q[m] == IDLE) begin
            any_req = 1'b0;
            first_req = '0;
            
            // Search for highest-priority valid request directed to this output
            for (i = 0; i < S_COUNT; i++) begin
                idx = (rr_ptr_q[m] + i) % S_COUNT;
                if (s_valid_i[idx] && (s_dest_i[idx * DEST_W +: DEST_W] == m)) begin
                    any_req = 1'b1;
                    first_req = idx[$clog2(S_COUNT)-1:0];
                    break;
                end
            end
            
            if (any_req) begin
                grant_valid[m] = 1'b1;
                grant_sel[m] = first_req;
                
                // Advance pointer and stay IDLE if it's the last beat; else lock.
                if (fifo_ready[m] && s_valid_i[first_req] && s_last_i[first_req]) begin
                    state_d[m] = IDLE;
                    rr_ptr_d[m] = (first_req + 1) % S_COUNT;
                end else begin
                    state_d[m] = LOCKED;
                    locked_sel_d[m] = first_req;
                end
            end
        end else begin
            grant_valid[m] = 1'b1;
            grant_sel[m] = locked_sel_q[m];
            
            // Unlock only when the final beat of the frame is successfully transferred
            if (fifo_ready[m] && s_valid_i[locked_sel_q[m]] && s_last_i[locked_sel_q[m]]) begin
                state_d[m] = IDLE;
                rr_ptr_d[m] = (locked_sel_q[m] + 1) % S_COUNT;
            end
        end
    end
  end

  // 3. FIFO Write Generation & Routing
  always_comb begin
    int m;
    for (m = 0; m < M_COUNT; m++) begin
        fifo_wr[m] = 1'b0;
        fifo_din_data[m] = '0;
        fifo_din_keep[m] = '0;
        fifo_din_last[m] = 1'b0;
        
        if (grant_valid[m]) begin
            fifo_wr[m] = s_valid_i[grant_sel[m]] && fifo_ready[m];
            fifo_din_data[m] = s_data_i[grant_sel[m] * DATA_W +: DATA_W];
            fifo_din_keep[m] = s_keep_i[grant_sel[m] * KEEP_W +: KEEP_W];
            fifo_din_last[m] = s_last_i[grant_sel[m]];
        end
    end
  end

  // 4. Input Ready Backpressure
  always_comb begin
    int s;
    int m;
    for (s = 0; s < S_COUNT; s++) begin
        s_ready_o[s] = 1'b0;
        for (m = 0; m < M_COUNT; m++) begin
            if (grant_valid[m] && (grant_sel[m] == s) && (s_dest_i[s * DEST_W +: DEST_W] == m)) begin
                s_ready_o[s] = fifo_ready[m];
            end
        end
    end
  end

  // 5. FIFO Read Out
  always_comb begin
    int m;
    logic [FIFO_ADDR_W-1:0] rd_idx;
    for (m = 0; m < M_COUNT; m++) begin
        rd_idx = fifo_rd_ptr[m][FIFO_ADDR_W-1:0];
        m_valid_o[m] = ~fifo_empty[m];
        m_data_o[m * DATA_W +: DATA_W] = fifo_data[m][rd_idx];
        m_keep_o[m * KEEP_W +: KEEP_W] = fifo_keep[m][rd_idx];
        m_last_o[m] = fifo_last[m][rd_idx];
    end
  end

  // 6. Sequential State Updates
  always_ff @(posedge clk_i or negedge rst_ni) begin
    int m;
    if (!rst_ni) begin
        for (m = 0; m < M_COUNT; m++) begin
            state_q[m] <= IDLE;
            locked_sel_q[m] <= '0;
            rr_ptr_q[m] <= '0;
            fifo_wr_ptr[m] <= '0;
            fifo_rd_ptr[m] <= '0;
        end
    end else begin
        for (m = 0; m < M_COUNT; m++) begin
            state_q[m] <= state_d[m];
            locked_sel_q[m] <= locked_sel_d[m];
            rr_ptr_q[m] <= rr_ptr_d[m];
            
            if (fifo_wr[m]) begin
                fifo_data[m][fifo_wr_ptr[m][FIFO_ADDR_W-1:0]] <= fifo_din_data[m];
                fifo_keep[m][fifo_wr_ptr[m][FIFO_ADDR_W-1:0]] <= fifo_din_keep[m];
                fifo_last[m][fifo_wr_ptr[m][FIFO_ADDR_W-1:0]] <= fifo_din_last[m];
                fifo_wr_ptr[m] <= fifo_wr_ptr[m] + 1;
            end
            
            if (m_valid_o[m] && m_ready_i[m]) begin
                fifo_rd_ptr[m] <= fifo_rd_ptr[m] + 1;
            end
        end
    end
  end

endmodule