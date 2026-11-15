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

    localparam int PTR_W = LOG_DEPTH;
    localparam int DEPTH = 1 << LOG_DEPTH;

    // Inverting the two most-significant Gray bits detects a pointer
    // difference of exactly DEPTH.
    localparam logic [PTR_W:0] FULL_MASK =
        {2'b11, {(PTR_W-1){1'b0}}};

    logic [DATA_W-1:0] mem [0:DEPTH-1];

    logic [PTR_W:0] wr_bin;
    logic [PTR_W:0] wr_gray;
    logic [PTR_W:0] rd_bin;
    logic [PTR_W:0] rd_gray;

    logic [PTR_W:0] wr_bin_next;
    logic [PTR_W:0] wr_gray_next;
    logic [PTR_W:0] rd_bin_next;
    logic [PTR_W:0] rd_gray_next;

    // Only Gray-coded pointers cross clock domains.
    logic [SYNC_STAGES-1:0][PTR_W:0] wr_gray_rd_sync;
    logic [SYNC_STAGES-1:0][PTR_W:0] rd_gray_wr_sync;

    logic wr_full;
    logic wr_full_next;
    logic rd_empty;
    logic rd_empty_next;
    logic wr_fire;
    logic rd_fire;

    assign wr_ready = wr_rst_n & ~wr_full;
    assign rd_valid = rd_rst_n & ~rd_empty;

    assign wr_fire = wr_valid & wr_ready;
    assign rd_fire = rd_valid & rd_ready;

    // The read address changes only after an accepted read, so rd_data
    // remains stable throughout a valid/ready stall.
    assign rd_data = mem[rd_bin[PTR_W-1:0]];

    always_comb begin
        wr_bin_next = wr_bin;
        if (wr_fire) begin
            wr_bin_next = wr_bin + {{PTR_W{1'b0}}, 1'b1};
        end
        wr_gray_next = (wr_bin_next >> 1) ^ wr_bin_next;
        wr_full_next =
            (wr_gray_next ==
             (rd_gray_wr_sync[SYNC_STAGES-1] ^ FULL_MASK));
    end

    always_comb begin
        rd_bin_next = rd_bin;
        if (rd_fire) begin
            rd_bin_next = rd_bin + {{PTR_W{1'b0}}, 1'b1};
        end
        rd_gray_next = (rd_bin_next >> 1) ^ rd_bin_next;
        rd_empty_next =
            (rd_gray_next == wr_gray_rd_sync[SYNC_STAGES-1]);
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

    always_ff @(posedge wr_clk) begin
        if (wr_fire) begin
            mem[wr_bin[PTR_W-1:0]] <= wr_data;
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

    always_ff @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            wr_gray_rd_sync <= '0;
        end else begin
            wr_gray_rd_sync <=
                {wr_gray_rd_sync[SYNC_STAGES-2:0], wr_gray};
        end
    end

    always_ff @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) begin
            rd_gray_wr_sync <= '0;
        end else begin
            rd_gray_wr_sync <=
                {rd_gray_wr_sync[SYNC_STAGES-2:0], rd_gray};
        end
    end

endmodule
