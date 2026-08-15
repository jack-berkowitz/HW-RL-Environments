// =============================================================================
// async_fifo_cdc.sv  --  Asynchronous CDC FIFO Implementation
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
    // Memory Storage
    // -------------------------------------------------------------------------
    logic [DATA_W-1:0] mem [0:(1<<LOG_DEPTH)-1];

    // -------------------------------------------------------------------------
    // Internal Signals
    // -------------------------------------------------------------------------
    // Write domain
    logic [LOG_DEPTH:0] wr_ptr_bin;
    logic [LOG_DEPTH:0] wr_ptr_gray;
    logic [LOG_DEPTH:0] wr_ptr_bin_next;
    logic [LOG_DEPTH:0] wr_ptr_gray_next;
    logic               wr_en;
    logic               wr_full;

    // Read domain
    logic [LOG_DEPTH:0] rd_ptr_bin;
    logic [LOG_DEPTH:0] rd_ptr_gray;
    logic [LOG_DEPTH:0] rd_ptr_bin_next;
    logic [LOG_DEPTH:0] rd_ptr_gray_next;
    logic               rd_en;
    logic               rd_empty;

    // Synchronizer chains (configurable depth SYNC_STAGES)
    logic [LOG_DEPTH:0] rd_ptr_gray_sync [0:SYNC_STAGES-1];
    logic [LOG_DEPTH:0] wr_ptr_gray_sync [0:SYNC_STAGES-1];

    // -------------------------------------------------------------------------
    // Write Domain Logic
    // -------------------------------------------------------------------------
    assign wr_en = wr_valid && wr_ready;

    assign wr_ptr_bin_next  = wr_ptr_bin + (wr_en ? 1'b1 : 1'b0);
    assign wr_ptr_gray_next = (wr_ptr_bin_next >> 1) ^ wr_ptr_bin_next;

    always_ff @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) begin
            wr_ptr_bin  <= '0;
            wr_ptr_gray <= '0;
        end else begin
            wr_ptr_bin  <= wr_ptr_bin_next;
            wr_ptr_gray <= wr_ptr_gray_next;
        end
    end

    // Memory write
    always_ff @(posedge wr_clk) begin
        if (wr_en) begin
            mem[wr_ptr_bin[LOG_DEPTH-1:0]] <= wr_data;
        end
    end

    // Synchronize read pointer (Gray code) into write clock domain
    always_ff @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) begin
            for (int i = 0; i < SYNC_STAGES; i++) begin
                rd_ptr_gray_sync[i] <= '0;
            end
        end else begin
            rd_ptr_gray_sync[0] <= rd_ptr_gray;
            for (int i = 1; i < SYNC_STAGES; i++) begin
                rd_ptr_gray_sync[i] <= rd_ptr_gray_sync[i-1];
            end
        end
    end

    // Full condition: Top 2 MSBs inverted, remaining bits identical
    assign wr_full  = (wr_ptr_gray == {~rd_ptr_gray_sync[SYNC_STAGES-1][LOG_DEPTH:LOG_DEPTH-1],
                                        rd_ptr_gray_sync[SYNC_STAGES-1][LOG_DEPTH-2:0]});
    
    // H1: wr_ready has no combinational dependency on wr_valid
    assign wr_ready = !wr_full && wr_rst_n;

    // -------------------------------------------------------------------------
    // Read Domain Logic
    // -------------------------------------------------------------------------
    assign rd_en = rd_valid && rd_ready;

    assign rd_ptr_bin_next  = rd_ptr_bin + (rd_en ? 1'b1 : 1'b0);
    assign rd_ptr_gray_next = (rd_ptr_bin_next >> 1) ^ rd_ptr_bin_next;

    always_ff @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            rd_ptr_bin  <= '0;
            rd_ptr_gray <= '0;
        end else begin
            rd_ptr_bin  <= rd_ptr_bin_next;
            rd_ptr_gray <= rd_ptr_gray_next;
        end
    end

    // Synchronize write pointer (Gray code) into read clock domain
    always_ff @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            for (int i = 0; i < SYNC_STAGES; i++) begin
                wr_ptr_gray_sync[i] <= '0;
            end
        end else begin
            wr_ptr_gray_sync[0] <= wr_ptr_gray;
            for (int i = 1; i < SYNC_STAGES; i++) begin
                wr_ptr_gray_sync[i] <= wr_ptr_gray_sync[i-1];
            end
        end
    end

    assign rd_empty = (rd_ptr_gray == wr_ptr_gray_sync[SYNC_STAGES-1]);

    // H1 & R5: rd_valid has no combinational dependency on rd_ready and forces 0 during reset
    assign rd_valid = !rd_empty && rd_rst_n;

    // Direct asynchronous read output (H3: remains stable while backpressured since rd_ptr_bin holds)
    assign rd_data  = mem[rd_ptr_bin[LOG_DEPTH-1:0]];

endmodule