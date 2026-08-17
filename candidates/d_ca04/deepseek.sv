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

    // =========================================================================
    // Internal signals
    // =========================================================================
    localparam int DEPTH = 2**LOG_DEPTH;
    localparam int PTR_W = LOG_DEPTH + 1;  // One extra bit for full/empty detection
    
    // Memory array
    logic [DATA_W-1:0] mem [DEPTH];
    
    // Write domain pointers
    logic [PTR_W-1:0] wr_ptr_bin;      // Binary write pointer
    logic [PTR_W-1:0] wr_ptr_gray;     // Gray-coded write pointer
    logic [PTR_W-1:0] rd_ptr_gray_sync_wr;  // Read pointer synchronized to write domain
    
    // Read domain pointers
    logic [PTR_W-1:0] rd_ptr_bin;      // Binary read pointer
    logic [PTR_W-1:0] rd_ptr_gray;     // Gray-coded read pointer
    logic [PTR_W-1:0] wr_ptr_gray_sync_rd;  // Write pointer synchronized to read domain
    
    // Synchronizer chains
    logic [PTR_W-1:0] wr_ptr_sync_stages [SYNC_STAGES];  // Write pointer sync to read domain
    logic [PTR_W-1:0] rd_ptr_sync_stages [SYNC_STAGES];  // Read pointer sync to write domain
    
    // =========================================================================
    // Binary to Gray conversion functions
    // =========================================================================
    function automatic [PTR_W-1:0] bin2gray(input [PTR_W-1:0] bin);
        return bin ^ (bin >> 1);
    endfunction
    
    function automatic [PTR_W-1:0] gray2bin(input [PTR_W-1:0] gray);
        logic [PTR_W-1:0] bin;
        bin[PTR_W-1] = gray[PTR_W-1];
        for (int i = PTR_W-2; i >= 0; i--) begin
            bin[i] = bin[i+1] ^ gray[i];
        end
        return bin;
    endfunction
    
    // =========================================================================
    // Write domain logic
    // =========================================================================
    always_ff @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) begin
            wr_ptr_bin <= '0;
            wr_ptr_gray <= '0;
        end else begin
            if (wr_valid && wr_ready) begin
                wr_ptr_bin <= wr_ptr_bin + 1'b1;
                wr_ptr_gray <= bin2gray(wr_ptr_bin + 1'b1);
            end
        end
    end
    
    // Write data to memory
    always_ff @(posedge wr_clk) begin
        if (wr_valid && wr_ready) begin
            mem[wr_ptr_bin[LOG_DEPTH-1:0]] <= wr_data;
        end
    end
    
    // Synchronize read pointer to write domain
    always_ff @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) begin
            for (int i = 0; i < SYNC_STAGES; i++) begin
                rd_ptr_sync_stages[i] <= '0;
            end
            rd_ptr_gray_sync_wr <= '0;
        end else begin
            rd_ptr_sync_stages[0] <= rd_ptr_gray;
            for (int i = 1; i < SYNC_STAGES; i++) begin
                rd_ptr_sync_stages[i] <= rd_ptr_sync_stages[i-1];
            end
            rd_ptr_gray_sync_wr <= rd_ptr_sync_stages[SYNC_STAGES-1];
        end
    end
    
    // Full detection (write domain)
    // Full when write pointer catches up to synchronized read pointer
    // In Gray code: full when top two bits are opposite and rest are same
    logic [PTR_W-1:0] rd_ptr_bin_sync_wr;
    assign rd_ptr_bin_sync_wr = gray2bin(rd_ptr_gray_sync_wr);
    
    wire full;
    assign full = (wr_ptr_gray[PTR_W-1] != rd_ptr_gray_sync_wr[PTR_W-1]) &&
                  (wr_ptr_gray[PTR_W-2] != rd_ptr_gray_sync_wr[PTR_W-2]) &&
                  (wr_ptr_gray[PTR_W-3:0] == rd_ptr_gray_sync_wr[PTR_W-3:0]);
    
    assign wr_ready = !full;
    
    // =========================================================================
    // Read domain logic
    // =========================================================================
    always_ff @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            rd_ptr_bin <= '0;
            rd_ptr_gray <= '0;
        end else begin
            if (rd_valid && rd_ready) begin
                rd_ptr_bin <= rd_ptr_bin + 1'b1;
                rd_ptr_gray <= bin2gray(rd_ptr_bin + 1'b1);
            end
        end
    end
    
    // Synchronize write pointer to read domain
    always_ff @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            for (int i = 0; i < SYNC_STAGES; i++) begin
                wr_ptr_sync_stages[i] <= '0;
            end
            wr_ptr_gray_sync_rd <= '0;
        end else begin
            wr_ptr_sync_stages[0] <= wr_ptr_gray;
            for (int i = 1; i < SYNC_STAGES; i++) begin
                wr_ptr_sync_stages[i] <= wr_ptr_sync_stages[i-1];
            end
            wr_ptr_gray_sync_rd <= wr_ptr_sync_stages[SYNC_STAGES-1];
        end
    end
    
    // Empty detection (read domain)
    // Empty when read pointer equals synchronized write pointer
    wire empty;
    assign empty = (rd_ptr_gray == wr_ptr_gray_sync_rd);
    
    assign rd_valid = !empty;
    
    // Read data from memory
    always_ff @(posedge rd_clk) begin
        if (rd_valid && rd_ready) begin
            rd_data <= mem[rd_ptr_bin[LOG_DEPTH-1:0]];
        end
    end
    
    // =========================================================================
    // Assertions for debugging (optional)
    // =========================================================================
    // synopsys translate_off
    // Ensure no read/write conflicts
    // synopsys translate_on

endmodule