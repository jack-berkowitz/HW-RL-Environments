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

    localparam int ADDR_W = LOG_DEPTH;
    localparam int PTR_W  = LOG_DEPTH + 1;
    localparam int DEPTH  = 1 << LOG_DEPTH;

    logic [PTR_W-1:0] wr_bin;
    logic [PTR_W-1:0] wr_gray;
    logic [PTR_W-1:0] rd_bin;
    logic [PTR_W-1:0] rd_gray;

    logic wr_full;
    logic rd_empty;

    logic [PTR_W-1:0] wr_gray_sync [0:SYNC_STAGES-1];
    logic [PTR_W-1:0] rd_gray_sync [0:SYNC_STAGES-1];

    logic [DATA_W-1:0] mem [0:DEPTH-1];

    integer i_wr_sync;
    integer i_rd_sync;

    function automatic logic [PTR_W-1:0] bin2gray(input logic [PTR_W-1:0] b);
        bin2gray = b ^ (b >> 1);
    endfunction

    wire [PTR_W-1:0] wr_gray_sync_last = wr_gray_sync[SYNC_STAGES-1];
    wire [PTR_W-1:0] rd_gray_sync_last = rd_gray_sync[SYNC_STAGES-1];

    wire wr_en = wr_valid && wr_ready;
    wire rd_en = rd_valid && rd_ready;

    wire [PTR_W-1:0] wr_bin_next = wr_bin + {{(PTR_W-1){1'b0}}, wr_en};
    wire [PTR_W-1:0] wr_gray_next = bin2gray(wr_bin_next);
    wire wr_full_next = (wr_gray_next == {~rd_gray_sync_last[PTR_W-1:PTR_W-2],
                                           rd_gray_sync_last[PTR_W-3:0]});

    wire [PTR_W-1:0] rd_bin_next = rd_bin + {{(PTR_W-1){1'b0}}, rd_en};
    wire [PTR_W-1:0] rd_gray_next = bin2gray(rd_bin_next);
    wire rd_empty_next = (rd_gray_next == wr_gray_sync_last);

    assign wr_ready = wr_rst_n && !wr_full;
    assign rd_valid = rd_rst_n && !rd_empty;
    assign rd_data  = mem[rd_bin[ADDR_W-1:0]];

    always_ff @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) begin
            wr_bin  <= '0;
            wr_gray <= '0;
            wr_full <= 1'b0;
        end else begin
            if (wr_en) begin
                wr_bin  <= wr_bin_next;
                wr_gray <= wr_gray_next;
            end
            wr_full <= wr_full_next;
        end
    end

    always_ff @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            rd_bin   <= '0;
            rd_gray  <= '0;
            rd_empty <= 1'b1;
        end else begin
            if (rd_en) begin
                rd_bin  <= rd_bin_next;
                rd_gray <= rd_gray_next;
            end
            rd_empty <= rd_empty_next;
        end
    end

    always_ff @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            for (i_rd_sync = 0; i_rd_sync < SYNC_STAGES; i_rd_sync = i_rd_sync + 1) begin
                wr_gray_sync[i_rd_sync] <= '0;
            end
        end else begin
            wr_gray_sync[0] <= wr_gray;
            for (i_rd_sync = 1; i_rd_sync < SYNC_STAGES; i_rd_sync = i_rd_sync + 1) begin
                wr_gray_sync[i_rd_sync] <= wr_gray_sync[i_rd_sync-1];
            end
        end
    end

    always_ff @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) begin
            for (i_wr_sync = 0; i_wr_sync < SYNC_STAGES; i_wr_sync = i_wr_sync + 1) begin
                rd_gray_sync[i_wr_sync] <= '0;
            end
        end else begin
            rd_gray_sync[0] <= rd_gray;
            for (i_wr_sync = 1; i_wr_sync < SYNC_STAGES; i_wr_sync = i_wr_sync + 1) begin
                rd_gray_sync[i_wr_sync] <= rd_gray_sync[i_wr_sync-1];
            end
        end
    end

    always_ff @(posedge wr_clk) begin
        if (wr_en) begin
            mem[wr_bin[ADDR_W-1:0]] <= wr_data;
        end
    end

endmodule
