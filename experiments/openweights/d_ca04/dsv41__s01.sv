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

    localparam int DEPTH = 1 << LOG_DEPTH;
    localparam int PTR_W = LOG_DEPTH + 1;

    // ---- Storage ----
    logic [DATA_W-1:0] mem [DEPTH];

    // ---- Write domain ----
    logic [PTR_W-1:0] wr_bin;
    logic [PTR_W-1:0] wr_gray;
    logic [PTR_W-1:0] wr_bin_next;
    logic [PTR_W-1:0] wr_gray_next;
    logic [PTR_W-1:0] rd_gray_sync [SYNC_STAGES];
    logic [PTR_W-1:0] rd_bin_sync;
    logic             wr_full;

    // ---- Read domain ----
    logic [PTR_W-1:0] rd_bin;
    logic [PTR_W-1:0] rd_gray;
    logic [PTR_W-1:0] rd_bin_next;
    logic [PTR_W-1:0] rd_gray_next;
    logic [PTR_W-1:0] wr_gray_sync [SYNC_STAGES];
    logic [PTR_W-1:0] wr_bin_sync;
    logic             rd_empty;

    // ---- Code conversion helpers ----
    function automatic logic [PTR_W-1:0] bin2gray(input logic [PTR_W-1:0] b);
        return b ^ (b >> 1);
    endfunction

    function automatic logic [PTR_W-1:0] gray2bin(input logic [PTR_W-1:0] g);
        logic [PTR_W-1:0] b;
        int i;
        b = g;
        for (i = 1; i < PTR_W; i = i * 2) begin
            b = b ^ (b >> i);
        end
        return b;
    endfunction

    // =========================================================
    // Write domain
    // =========================================================
    assign wr_bin_next  = wr_bin + 1'b1;
    assign wr_gray_next = bin2gray(wr_bin_next);

    // Synchronize rd_gray into wr_clk domain
    genvar gi;
    generate
        for (gi = 0; gi < SYNC_STAGES; gi++) begin : gen_wr_sync
            always_ff @(posedge wr_clk or negedge wr_rst_n) begin
                if (!wr_rst_n) begin
                    rd_gray_sync[gi] <= '0;
                end else if (gi == 0) begin
                    rd_gray_sync[gi] <= rd_gray;
                end else begin
                    rd_gray_sync[gi] <= rd_gray_sync[gi-1];
                end
            end
        end
    endgenerate

    assign rd_bin_sync = gray2bin(rd_gray_sync[SYNC_STAGES-1]);

    // Full: wr_bin_next has wrapped one full depth past rd_bin_sync
    assign wr_full = (wr_bin_next[PTR_W-1] != rd_bin_sync[PTR_W-1]) &&
                     (wr_bin_next[PTR_W-2:0] == rd_bin_sync[PTR_W-2:0]);

    assign wr_ready = !wr_full;

    always_ff @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) begin
            wr_bin  <= '0;
            wr_gray <= '0;
        end else if (wr_valid && wr_ready) begin
            mem[wr_bin[LOG_DEPTH-1:0]] <= wr_data;
            wr_bin  <= wr_bin_next;
            wr_gray <= wr_gray_next;
        end
    end

    // =========================================================
    // Read domain
    // =========================================================
    assign rd_bin_next  = rd_bin + 1'b1;
    assign rd_gray_next = bin2gray(rd_bin_next);

    // Synchronize wr_gray into rd_clk domain
    genvar gj;
    generate
        for (gj = 0; gj < SYNC_STAGES; gj++) begin : gen_rd_sync
            always_ff @(posedge rd_clk or negedge rd_rst_n) begin
                if (!rd_rst_n) begin
                    wr_gray_sync[gj] <= '0;
                end else if (gj == 0) begin
                    wr_gray_sync[gj] <= wr_gray;
                end else begin
                    wr_gray_sync[gj] <= wr_gray_sync[gj-1];
                end
            end
        end
    endgenerate

    assign wr_bin_sync = gray2bin(wr_gray_sync[SYNC_STAGES-1]);

    // Empty: read pointer has caught up to synchronized write pointer
    assign rd_empty = (rd_bin == wr_bin_sync);

    assign rd_valid = !rd_empty;
    assign rd_data  = mem[rd_bin[LOG_DEPTH-1:0]];

    always_ff @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            rd_bin  <= '0;
            rd_gray <= '0;
        end else if (rd_valid && rd_ready) begin
            rd_bin  <= rd_bin_next;
            rd_gray <= rd_gray_next;
        end
    end

endmodule
