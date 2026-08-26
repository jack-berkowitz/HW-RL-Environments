// =============================================================================
// async_fifo_cdc
// =============================================================================

module async_fifo_cdc #(
    parameter int DATA_W      = 32,   // 8 / 32 / 64
    parameter int LOG_DEPTH   = 3,    // 2 / 3 / 4  -> depth 4 / 8 / 16
    parameter int SYNC_STAGES = 2     // 2 / 3
) (
    // ---- write domain ----
    input  logic              wr_clk,
    input  logic              wr_rst_n,
    input  logic              wr_valid,
    output logic              wr_ready,
    input  logic [DATA_W-1:0] wr_data,

    // ---- read domain ----
    input  logic              rd_clk,
    input  logic              rd_rst_n,
    output logic              rd_valid,
    input  logic              rd_ready,
    output logic [DATA_W-1:0] rd_data
);

    localparam int PTR_W = LOG_DEPTH + 1;
    localparam int FIFO_DEPTH = 1 << LOG_DEPTH;

    // -------------------------------------------------------------------------
    // Memory Array
    // -------------------------------------------------------------------------
    // Synthesizes cleanly to distributed RAM or flip-flop array
    logic [DATA_W-1:0] mem [0 : FIFO_DEPTH-1];

    // -------------------------------------------------------------------------
    // Write Domain Signals
    // -------------------------------------------------------------------------
    logic [PTR_W-1:0] wr_bin;
    logic [PTR_W-1:0] wr_gray;
    logic [PTR_W-1:0] next_wr_bin;
    logic [PTR_W-1:0] next_wr_gray;

    logic [(SYNC_STAGES * PTR_W)-1 : 0] sync_rd_ptr;
    logic [PTR_W-1:0] wr_rd_gray_sync;

    logic wr_full;

    // -------------------------------------------------------------------------
    // Read Domain Signals
    // -------------------------------------------------------------------------
    logic [PTR_W-1:0] rd_bin;
    logic [PTR_W-1:0] rd_gray;
    logic [PTR_W-1:0] next_rd_bin;
    logic [PTR_W-1:0] next_rd_gray;

    logic [(SYNC_STAGES * PTR_W)-1 : 0] sync_wr_ptr;
    logic [PTR_W-1:0] rd_wr_gray_sync;

    logic rd_empty;

    // -------------------------------------------------------------------------
    // Write Domain Logic
    // -------------------------------------------------------------------------
    assign next_wr_bin  = wr_bin + 1'b1;
    assign next_wr_gray = next_wr_bin ^ (next_wr_bin >> 1);

    // Extract fully synchronized read pointer from the top of the shift register
    assign wr_rd_gray_sync = sync_rd_ptr[(SYNC_STAGES * PTR_W) - 1 -: PTR_W];

    // Full condition: Gray code pointer matches except for the top two bits inverted
    assign wr_full  = (wr_gray == {~wr_rd_gray_sync[PTR_W-1:PTR_W-2], wr_rd_gray_sync[PTR_W-3:0]});
    assign wr_ready = ~wr_full;

    always_ff @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) begin
            wr_bin      <= '0;
            wr_gray     <= '0;
            sync_rd_ptr <= '0;
        end else begin
            if (wr_valid && wr_ready) begin
                wr_bin  <= next_wr_bin;
                wr_gray <= next_wr_gray;
            end
            // Shift in the read pointer for synchronization
            sync_rd_ptr <= {sync_rd_ptr[(SYNC_STAGES - 1) * PTR_W - 1 : 0], rd_gray};
        end
    end

    // Memory write
    always_ff @(posedge wr_clk) begin
        if (wr_valid && wr_ready) begin
            mem[wr_bin[LOG_DEPTH-1:0]] <= wr_data;
        end
    end

    // -------------------------------------------------------------------------
    // Read Domain Logic
    // -------------------------------------------------------------------------
    assign next_rd_bin  = rd_bin + 1'b1;
    assign next_rd_gray = next_rd_bin ^ (next_rd_bin >> 1);

    // Extract fully synchronized write pointer from the top of the shift register
    assign rd_wr_gray_sync = sync_wr_ptr[(SYNC_STAGES * PTR_W) - 1 -: PTR_W];

    // Empty condition: Synchronized write pointer perfectly matches local read pointer
    assign rd_empty = (rd_gray == rd_wr_gray_sync);
    assign rd_valid = ~rd_empty;

    // FWFT asynchronous memory read 
    // Stable while valid is high and ready is low, because rd_bin will not increment.
    assign rd_data = mem[rd_bin[LOG_DEPTH-1:0]];

    always_ff @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            rd_bin      <= '0;
            rd_gray     <= '0;
            sync_wr_ptr <= '0;
        end else begin
            if (rd_valid && rd_ready) begin
                rd_bin  <= next_rd_bin;
                rd_gray <= next_rd_gray;
            end
            // Shift in the write pointer for synchronization
            sync_wr_ptr <= {sync_wr_ptr[(SYNC_STAGES - 1) * PTR_W - 1 : 0], wr_gray};
        end
    end

endmodule