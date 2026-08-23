// =============================================================================
// async_fifo_cdc_iface.sv  --  IMPLEMENTATION
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

    // -------------------------------------------------------------------------
    // LOCAL PARAMETERS & STORAGE
    // -------------------------------------------------------------------------
    localparam int DEPTH = 1 << LOG_DEPTH;
    localparam int PTR_W = LOG_DEPTH + 1;

    // Dual-port memory (infers as distributed LUTRAM for these depths)
    logic [DATA_W-1:0] mem [DEPTH];

    // -------------------------------------------------------------------------
    // WRITE DOMAIN
    // -------------------------------------------------------------------------
    logic [PTR_W-1:0] wr_ptr_bin;
    logic [PTR_W-1:0] wr_ptr_gray;
    logic [PTR_W-1:0] rd_ptr_gray_sync [SYNC_STAGES];

    // Advance write pointer on successful handshake
    wire [PTR_W-1:0] wr_ptr_bin_next  = wr_ptr_bin + (wr_valid & wr_ready);
    
    // Binary to Gray conversion
    wire [PTR_W-1:0] wr_ptr_gray_next = wr_ptr_bin_next ^ (wr_ptr_bin_next >> 1);

    always_ff @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) begin
            wr_ptr_bin  <= '0;
            wr_ptr_gray <= '0;
            for (int i = 0; i < SYNC_STAGES; i++) begin
                rd_ptr_gray_sync[i] <= '0;
            end
        end else begin
            // Update pointers
            wr_ptr_bin  <= wr_ptr_bin_next;
            wr_ptr_gray <= wr_ptr_gray_next;
            
            // Synchronize read pointer into write domain
            rd_ptr_gray_sync[0] <= rd_ptr_gray;
            for (int i = 1; i < SYNC_STAGES; i++) begin
                rd_ptr_gray_sync[i] <= rd_ptr_gray_sync[i-1];
            end
        end
    end

    // Full condition: 
    // True when the write Gray pointer has caught up to the read Gray pointer from behind.
    // In Gray code, this means the top two bits are inverted, and the remaining bits match.
    wire [PTR_W-1:0] synced_rd_ptr_gray = rd_ptr_gray_sync[SYNC_STAGES-1];
    wire wr_full = (wr_ptr_gray == {~synced_rd_ptr_gray[PTR_W-1:PTR_W-2], 
                                     synced_rd_ptr_gray[PTR_W-3:0]});
    
    // Satisfies H1: wr_ready only combinationally depends on synced pointers
    assign wr_ready = ~wr_full;

    always_ff @(posedge wr_clk) begin
        if (wr_valid & wr_ready) begin
            mem[wr_ptr_bin[LOG_DEPTH-1:0]] <= wr_data;
        end
    end

    // -------------------------------------------------------------------------
    // READ DOMAIN
    // -------------------------------------------------------------------------
    logic [PTR_W-1:0] rd_ptr_bin;
    logic [PTR_W-1:0] rd_ptr_gray;
    logic [PTR_W-1:0] wr_ptr_gray_sync [SYNC_STAGES];

    // Advance read pointer on successful handshake
    wire [PTR_W-1:0] rd_ptr_bin_next  = rd_ptr_bin + (rd_valid & rd_ready);
    
    // Binary to Gray conversion
    wire [PTR_W-1:0] rd_ptr_gray_next = rd_ptr_bin_next ^ (rd_ptr_bin_next >> 1);

    always_ff @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            rd_ptr_bin  <= '0;
            rd_ptr_gray <= '0;
            for (int i = 0; i < SYNC_STAGES; i++) begin
                wr_ptr_gray_sync[i] <= '0;
            end
        end else begin
            // Update pointers
            rd_ptr_bin  <= rd_ptr_bin_next;
            rd_ptr_gray <= rd_ptr_gray_next;
            
            // Synchronize write pointer into read domain
            wr_ptr_gray_sync[0] <= wr_ptr_gray;
            for (int i = 1; i < SYNC_STAGES; i++) begin
                wr_ptr_gray_sync[i] <= wr_ptr_gray_sync[i-1];
            end
        end
    end

    // Empty condition:
    // True when the read Gray pointer exactly matches the synchronized write Gray pointer.
    wire [PTR_W-1:0] synced_wr_ptr_gray = wr_ptr_gray_sync[SYNC_STAGES-1];
    wire rd_empty = (rd_ptr_gray == synced_wr_ptr_gray);
    
    // Satisfies H1: rd_valid only combinationally depends on synced pointers
    assign rd_valid = ~rd_empty;

    // Asynchronous read assignment mapping out from dual-port memory.
    // Satisfies H3: rd_ptr_bin won't increment unless read is accepted (rd_valid & rd_ready),
    // therefore rd_data guarantees stability across cycles while waiting for rd_ready.
    assign rd_data = mem[rd_ptr_bin[LOG_DEPTH-1:0]];

endmodule