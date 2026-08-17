// =============================================================================
// async_fifo_cdc -- asynchronous FIFO with gray-coded pointers and
// parameterizable synchronizer depth.
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

    localparam int ADDR_W = LOG_DEPTH;
    localparam int PTR_W  = ADDR_W + 1;
    localparam int DEPTH  = 1 << ADDR_W;

    // -------------------------------------------------------------------------
    // Memory
    // -------------------------------------------------------------------------
    logic [DATA_W-1:0] mem [0:DEPTH-1];

    // -------------------------------------------------------------------------
    // Pointers (binary + gray)
    // -------------------------------------------------------------------------
    logic [PTR_W-1:0] wr_ptr_bin;
    logic [PTR_W-1:0] wr_ptr_gray;
    logic [PTR_W-1:0] rd_ptr_bin;
    logic [PTR_W-1:0] rd_ptr_gray;

    // -------------------------------------------------------------------------
    // Synchronizers
    // -------------------------------------------------------------------------
    logic [PTR_W-1:0] rd_gray_sync_wr [0:SYNC_STAGES-1];
    logic [PTR_W-1:0] wr_gray_sync_rd [0:SYNC_STAGES-1];

    // -------------------------------------------------------------------------
    // Binary-to-gray converter
    // -------------------------------------------------------------------------
    function automatic [PTR_W-1:0] bin_to_gray(input [PTR_W-1:0] bin);
        bin_to_gray = bin ^ (bin >> 1);
    endfunction

    // -------------------------------------------------------------------------
    // Write domain
    // -------------------------------------------------------------------------
    logic [PTR_W-1:0] rd_gray_synced_wr;
    assign rd_gray_synced_wr = rd_gray_sync_wr[SYNC_STAGES-1];

    logic [PTR_W-1:0] full_gray;
    assign full_gray = {~rd_gray_synced_wr[PTR_W-1:PTR_W-2],
                        rd_gray_synced_wr[PTR_W-3:0]};

    logic wr_full;
    assign wr_full = (wr_ptr_gray == full_gray);

    assign wr_ready = !wr_full && wr_rst_n;

    always_ff @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) begin
            wr_ptr_bin  <= '0;
            wr_ptr_gray <= '0;
        end else if (wr_valid && wr_ready) begin
            wr_ptr_bin  <= wr_ptr_bin + 1'b1;
            wr_ptr_gray <= bin_to_gray(wr_ptr_bin + 1'b1);
        end
    end

    always_ff @(posedge wr_clk) begin
        if (wr_valid && wr_ready) begin
            mem[wr_ptr_bin[ADDR_W-1:0]] <= wr_data;
        end
    end

    // Synchronize read pointer gray into write domain
    always_ff @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) begin
            for (int i = 0; i < SYNC_STAGES; i++) rd_gray_sync_wr[i] <= '0;
        end else begin
            rd_gray_sync_wr[0] <= rd_ptr_gray;
            for (int i = 1; i < SYNC_STAGES; i++) begin
                rd_gray_sync_wr[i] <= rd_gray_sync_wr[i-1];
            end
        end
    end

    // -------------------------------------------------------------------------
    // Read domain
    // -------------------------------------------------------------------------
    logic [PTR_W-1:0] wr_gray_synced_rd;
    assign wr_gray_synced_rd = wr_gray_sync_rd[SYNC_STAGES-1];

    logic rd_empty;
    assign rd_empty = (rd_ptr_gray == wr_gray_synced_rd);

    assign rd_valid = !rd_empty && rd_rst_n;

    always_ff @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            rd_ptr_bin  <= '0;
            rd_ptr_gray <= '0;
        end else if (rd_valid && rd_ready) begin
            rd_ptr_bin  <= rd_ptr_bin + 1'b1;
            rd_ptr_gray <= bin_to_gray(rd_ptr_bin + 1'b1);
        end
    end

    // Synchronize write pointer gray into read domain
    always_ff @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            for (int i = 0; i < SYNC_STAGES; i++) wr_gray_sync_rd[i] <= '0;
        end else begin
            wr_gray_sync_rd[0] <= wr_ptr_gray;
            for (int i = 1; i < SYNC_STAGES; i++) begin
                wr_gray_sync_rd[i] <= wr_gray_sync_rd[i-1];
            end
        end
    end

    // -------------------------------------------------------------------------
    // Read data output
    // -------------------------------------------------------------------------
    assign rd_data = mem[rd_ptr_bin[ADDR_W-1:0]];

endmodule