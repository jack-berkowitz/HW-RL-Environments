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

    localparam int PTR_W = LOG_DEPTH + 1;
    localparam int DEPTH = 1 << LOG_DEPTH;

    logic [DATA_W-1:0] mem [0:DEPTH-1];

    logic [PTR_W-1:0] wr_bin;
    logic [PTR_W-1:0] wr_gray;
    logic [PTR_W-1:0] rd_bin;
    logic [PTR_W-1:0] rd_gray;

    logic [PTR_W-1:0] rd_gray_sync [0:SYNC_STAGES-1];
    logic [PTR_W-1:0] wr_gray_sync [0:SYNC_STAGES-1];

    logic [PTR_W-1:0] rd_bin_sync;
    logic [PTR_W-1:0] wr_bin_sync;

    logic full;
    logic empty;
    logic wr_en;
    logic rd_en;

    function automatic [PTR_W-1:0] bin2gray(input logic [PTR_W-1:0] b);
        begin
            bin2gray = (b >> 1) ^ b;
        end
    endfunction

    function automatic [PTR_W-1:0] gray2bin(input logic [PTR_W-1:0] g);
        begin
            integer i;
            gray2bin[PTR_W-1] = g[PTR_W-1];
            for (i = PTR_W-2; i >= 0; i = i - 1) begin
                gray2bin[i] = gray2bin[i+1] ^ g[i];
            end
        end
    endfunction

    assign rd_bin_sync = gray2bin(rd_gray_sync[SYNC_STAGES-1]);
    assign wr_bin_sync = gray2bin(wr_gray_sync[SYNC_STAGES-1]);

    assign full = (wr_bin[LOG_DEPTH] != rd_bin_sync[LOG_DEPTH]) &&
                  (wr_bin[LOG_DEPTH-1:0] == rd_bin_sync[LOG_DEPTH-1:0]);
    assign empty = (rd_bin == wr_bin_sync);

    assign wr_ready = wr_rst_n && !full;
    assign rd_valid = rd_rst_n && !empty;

    assign wr_en = wr_valid && wr_ready;
    assign rd_en = rd_valid && rd_ready;

    assign rd_data = mem[rd_bin[LOG_DEPTH-1:0]];

    always_ff @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) begin
            wr_bin  <= '0;
            wr_gray <= '0;
        end else begin
            if (wr_en) begin
                wr_bin  <= wr_bin + 1'b1;
                wr_gray <= bin2gray(wr_bin + 1'b1);
            end
        end
    end

    always_ff @(posedge wr_clk) begin
        if (wr_en) begin
            mem[wr_bin[LOG_DEPTH-1:0]] <= wr_data;
        end
    end

    always_ff @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            rd_bin  <= '0;
            rd_gray <= '0;
        end else begin
            if (rd_en) begin
                rd_bin  <= rd_bin + 1'b1;
                rd_gray <= bin2gray(rd_bin + 1'b1);
            end
        end
    end

    always_ff @(posedge wr_clk or negedge wr_rst_n) begin
        integer i;
        if (!wr_rst_n) begin
            for (i = 0; i < SYNC_STAGES; i = i + 1) begin
                rd_gray_sync[i] <= '0;
            end
        end else begin
            rd_gray_sync[0] <= rd_gray;
            for (i = 1; i < SYNC_STAGES; i = i + 1) begin
                rd_gray_sync[i] <= rd_gray_sync[i-1];
            end
        end
    end

    always_ff @(posedge rd_clk or negedge rd_rst_n) begin
        integer i;
        if (!rd_rst_n) begin
            for (i = 0; i < SYNC_STAGES; i = i + 1) begin
                wr_gray_sync[i] <= '0;
            end
        end else begin
            wr_gray_sync[0] <= wr_gray;
            for (i = 1; i < SYNC_STAGES; i = i + 1) begin
                wr_gray_sync[i] <= wr_gray_sync[i-1];
            end
        end
    end

endmodule
