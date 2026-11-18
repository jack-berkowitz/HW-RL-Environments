module async_fifo_cdc #(
    parameter int DATA_W      = 32,
    parameter int LOG_DEPTH   = 3,
    parameter int SYNC_STAGES = 2
) (
    input  logic              wr_clk,
    input  logic              wr_rst_n,
    input  logic              wr_valid,
    output logic              wr_ready,
    input  logic [DATA_W-1:0] wr_data,

    input  logic              rd_clk,
    input  logic              rd_rst_n,
    output logic              rd_valid,
    input  logic              rd_ready,
    output logic [DATA_W-1:0] rd_data
);

    localparam int DEPTH = (1 << LOG_DEPTH);
    localparam int PTR_W = LOG_DEPTH + 1;

    logic [DATA_W-1:0] mem [0:DEPTH-1];

    logic [PTR_W-1:0] wr_bin;
    logic [PTR_W-1:0] wr_gray;
    logic [PTR_W-1:0] rd_bin;
    logic [PTR_W-1:0] rd_gray;

    logic [PTR_W-1:0] wr_bin_inc;
    logic [PTR_W-1:0] wr_gray_inc;
    logic [PTR_W-1:0] rd_bin_inc;
    logic [PTR_W-1:0] rd_gray_inc;

    logic [PTR_W-1:0] rd_gray_wr_sync [0:SYNC_STAGES-1];
    logic [PTR_W-1:0] wr_gray_rd_sync [0:SYNC_STAGES-1];

    logic full;
    logic empty;
    logic wr_fire;
    logic rd_fire;

    assign wr_bin_inc  = wr_bin + 1'b1;
    assign wr_gray_inc = (wr_bin_inc >> 1) ^ wr_bin_inc;
    assign rd_bin_inc  = rd_bin + 1'b1;
    assign rd_gray_inc = (rd_bin_inc >> 1) ^ rd_bin_inc;

    // The extra pointer bit distinguishes full from empty. Inverting the
    // upper two Gray bits detects a write pointer exactly DEPTH ahead.
    assign full =
        (wr_gray ==
         {~rd_gray_wr_sync[SYNC_STAGES-1][PTR_W-1:PTR_W-2],
           rd_gray_wr_sync[SYNC_STAGES-1][PTR_W-3:0]});

    assign empty = (rd_gray == wr_gray_rd_sync[SYNC_STAGES-1]);

    assign wr_ready = wr_rst_n && !full;
    assign rd_valid = rd_rst_n && !empty;

    assign wr_fire = wr_valid && wr_ready;
    assign rd_fire = rd_valid && rd_ready;

    // The addressed entry is stable whenever rd_valid is asserted. The read
    // address changes only when a beat is accepted, preserving H3.
    assign rd_data = mem[rd_bin[LOG_DEPTH-1:0]];

    always_ff @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) begin
            wr_bin  <= '0;
            wr_gray <= '0;
        end else if (wr_fire) begin
            wr_bin  <= wr_bin_inc;
            wr_gray <= wr_gray_inc;
        end
    end

    always_ff @(posedge wr_clk) begin
        if (wr_fire) begin
            mem[wr_bin[LOG_DEPTH-1:0]] <= wr_data;
        end
    end

    always_ff @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            rd_bin  <= '0;
            rd_gray <= '0;
        end else if (rd_fire) begin
            rd_bin  <= rd_bin_inc;
            rd_gray <= rd_gray_inc;
        end
    end

    // Read-pointer Gray code crossing into the write domain.
    always_ff @(posedge wr_clk or negedge wr_rst_n) begin
        integer idx;
        if (!wr_rst_n) begin
            for (idx = 0; idx < SYNC_STAGES; idx = idx + 1) begin
                rd_gray_wr_sync[idx] <= '0;
            end
        end else begin
            rd_gray_wr_sync[0] <= rd_gray;
            for (idx = 1; idx < SYNC_STAGES; idx = idx + 1) begin
                rd_gray_wr_sync[idx] <= rd_gray_wr_sync[idx-1];
            end
        end
    end

    // Write-pointer Gray code crossing into the read domain.
    always_ff @(posedge rd_clk or negedge rd_rst_n) begin
        integer idx;
        if (!rd_rst_n) begin
            for (idx = 0; idx < SYNC_STAGES; idx = idx + 1) begin
                wr_gray_rd_sync[idx] <= '0;
            end
        end else begin
            wr_gray_rd_sync[0] <= wr_gray;
            for (idx = 1; idx < SYNC_STAGES; idx = idx + 1) begin
                wr_gray_rd_sync[idx] <= wr_gray_rd_sync[idx-1];
            end
        end
    end

endmodule
