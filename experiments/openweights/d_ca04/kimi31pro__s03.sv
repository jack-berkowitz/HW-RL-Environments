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

    localparam int DEPTH = 1 << LOG_DEPTH;
    localparam int PTR_W = LOG_DEPTH + 1;

    logic [DATA_W-1:0] mem [0:DEPTH-1];

    logic [PTR_W-1:0] wr_bin;
    logic [PTR_W-1:0] wr_gray;
    logic [PTR_W-1:0] wr_bin_next;
    logic [PTR_W-1:0] wr_gray_next;

    logic [PTR_W-1:0] rd_bin;
    logic [PTR_W-1:0] rd_gray;
    logic [PTR_W-1:0] rd_bin_next;
    logic [PTR_W-1:0] rd_gray_next;

    logic [PTR_W-1:0] rd_gray_wr_sync [0:SYNC_STAGES-1];
    logic [PTR_W-1:0] wr_gray_rd_sync [0:SYNC_STAGES-1];

    logic wr_full;
    logic wr_full_next;
    logic rd_empty;
    logic rd_empty_next;
    logic wr_transfer;
    logic rd_transfer;

    integer wr_sync_idx;
    integer rd_sync_idx;

    assign wr_ready    = wr_rst_n && !wr_full;
    assign wr_transfer = wr_valid && wr_ready;

    assign wr_bin_next =
        wr_bin + {{(PTR_W-1){1'b0}}, wr_transfer};
    assign wr_gray_next = (wr_bin_next >> 1) ^ wr_bin_next;

    // Full when the next write Gray pointer equals the synchronized read
    // pointer with its two most-significant bits inverted.
    assign wr_full_next =
        (wr_gray_next ==
         {~rd_gray_wr_sync[SYNC_STAGES-1][PTR_W-1:PTR_W-2],
           rd_gray_wr_sync[SYNC_STAGES-1][PTR_W-3:0]});

    assign rd_valid    = rd_rst_n && !rd_empty;
    assign rd_transfer = rd_valid && rd_ready;

    assign rd_bin_next =
        rd_bin + {{(PTR_W-1){1'b0}}, rd_transfer};
    assign rd_gray_next = (rd_bin_next >> 1) ^ rd_bin_next;
    assign rd_empty_next =
        (rd_gray_next == wr_gray_rd_sync[SYNC_STAGES-1]);

    // The addressed entry is stable whenever rd_valid is asserted. A full
    // FIFO cannot overwrite it before the corresponding read transfer.
    assign rd_data = mem[rd_bin[LOG_DEPTH-1:0]];

    always_ff @(posedge wr_clk) begin
        if (wr_transfer)
            mem[wr_bin[LOG_DEPTH-1:0]] <= wr_data;
    end

    always_ff @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) begin
            wr_bin  <= '0;
            wr_gray <= '0;
            wr_full <= 1'b0;
        end else begin
            wr_bin  <= wr_bin_next;
            wr_gray <= wr_gray_next;
            wr_full <= wr_full_next;
        end
    end

    always_ff @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            rd_bin   <= '0;
            rd_gray  <= '0;
            rd_empty <= 1'b1;
        end else begin
            rd_bin   <= rd_bin_next;
            rd_gray  <= rd_gray_next;
            rd_empty <= rd_empty_next;
        end
    end

    // Read Gray pointer crossing into the write clock domain.
    always_ff @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) begin
            for (wr_sync_idx = 0;
                 wr_sync_idx < SYNC_STAGES;
                 wr_sync_idx = wr_sync_idx + 1)
                rd_gray_wr_sync[wr_sync_idx] <= '0;
        end else begin
            rd_gray_wr_sync[0] <= rd_gray;
            for (wr_sync_idx = 1;
                 wr_sync_idx < SYNC_STAGES;
                 wr_sync_idx = wr_sync_idx + 1)
                rd_gray_wr_sync[wr_sync_idx]
                    <= rd_gray_wr_sync[wr_sync_idx-1];
        end
    end

    // Write Gray pointer crossing into the read clock domain.
    always_ff @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            for (rd_sync_idx = 0;
                 rd_sync_idx < SYNC_STAGES;
                 rd_sync_idx = rd_sync_idx + 1)
                wr_gray_rd_sync[rd_sync_idx] <= '0;
        end else begin
            wr_gray_rd_sync[0] <= wr_gray;
            for (rd_sync_idx = 1;
                 rd_sync_idx < SYNC_STAGES;
                 rd_sync_idx = rd_sync_idx + 1)
                wr_gray_rd_sync[rd_sync_idx]
                    <= wr_gray_rd_sync[rd_sync_idx-1];
        end
    end

endmodule
