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

    // FIFO storage
    logic [DATA_W-1:0] mem [0:DEPTH-1];

    // ---- Write domain ----
    logic [PTR_W-1:0] wr_bin, wr_gray;
    logic [PTR_W-1:0] wr_bin_next, wr_gray_next;
    logic             wr_full;
    logic [PTR_W-1:0] rd_gray_sync_wr;
    logic [PTR_W-1:0] rd_gray_sync_wr_chain [0:SYNC_STAGES-1];

    // ---- Read domain ----
    logic [PTR_W-1:0] rd_bin, rd_gray;
    logic [PTR_W-1:0] rd_bin_next, rd_gray_next;
    logic             rd_empty;
    logic [PTR_W-1:0] wr_gray_sync_rd;
    logic [PTR_W-1:0] wr_gray_sync_rd_chain [0:SYNC_STAGES-1];

    logic [DATA_W-1:0] rd_data_reg;
    logic              rd_valid_reg;

    genvar gs;

    // ------------------------------------------------------------------
    // Write domain: synchronize rd_gray into wr domain
    // ------------------------------------------------------------------
    always_ff @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) rd_gray_sync_wr_chain[0] <= '0;
        else           rd_gray_sync_wr_chain[0] <= rd_gray;
    end

    generate
        for (gs = 1; gs < SYNC_STAGES; gs = gs + 1) begin : gen_wr_sync
            always_ff @(posedge wr_clk or negedge wr_rst_n) begin
                if (!wr_rst_n) rd_gray_sync_wr_chain[gs] <= '0;
                else           rd_gray_sync_wr_chain[gs] <= rd_gray_sync_wr_chain[gs-1];
            end
        end
    endgenerate

    assign rd_gray_sync_wr = rd_gray_sync_wr_chain[SYNC_STAGES-1];

    // ------------------------------------------------------------------
    // Write domain: full detection (uses registered pointers only, so
    // wr_ready has no combinational dependency on wr_valid) and pointer
    // update.
    // ------------------------------------------------------------------
    assign wr_full  = (wr_gray == {~rd_gray_sync_wr[PTR_W-1:PTR_W-2],
                                    rd_gray_sync_wr[PTR_W-3:0]});
    assign wr_ready = !wr_full;

    assign wr_bin_next  = wr_bin + ((wr_valid && wr_ready) ? 1'b1 : 1'b0);
    assign wr_gray_next = (wr_bin_next >> 1) ^ wr_bin_next;

    always_ff @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) begin
            wr_bin  <= '0;
            wr_gray <= '0;
        end else begin
            wr_bin  <= wr_bin_next;
            wr_gray <= wr_gray_next;
        end
    end

    // Memory write
    always_ff @(posedge wr_clk) begin
        if (wr_valid && wr_ready) begin
            mem[wr_bin[LOG_DEPTH-1:0]] <= wr_data;
        end
    end

    // ------------------------------------------------------------------
    // Read domain: synchronize wr_gray into rd domain
    // ------------------------------------------------------------------
    always_ff @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) wr_gray_sync_rd_chain[0] <= '0;
        else           wr_gray_sync_rd_chain[0] <= wr_gray;
    end

    generate
        for (gs = 1; gs < SYNC_STAGES; gs = gs + 1) begin : gen_rd_sync
            always_ff @(posedge rd_clk or negedge rd_rst_n) begin
                if (!rd_rst_n) wr_gray_sync_rd_chain[gs] <= '0;
                else           wr_gray_sync_rd_chain[gs] <= wr_gray_sync_rd_chain[gs-1];
            end
        end
    endgenerate

    assign wr_gray_sync_rd = wr_gray_sync_rd_chain[SYNC_STAGES-1];

    // ------------------------------------------------------------------
    // Read domain: empty detection and pointer update
    // ------------------------------------------------------------------
    assign rd_empty = (rd_gray == wr_gray_sync_rd);

    assign rd_bin_next  = rd_bin + ((rd_valid_reg && rd_ready) ? 1'b1 : 1'b0);
    assign rd_gray_next = (rd_bin_next >> 1) ^ rd_bin_next;

    always_ff @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            rd_bin  <= '0;
            rd_gray <= '0;
        end else begin
            rd_bin  <= rd_bin_next;
            rd_gray <= rd_gray_next;
        end
    end

    // ------------------------------------------------------------------
    // Read data path: registered output.  Holds stable when rd_valid is
    // high and rd_ready is low (H3).  rd_valid is registered so it has
    // no combinational dependency on rd_ready (H1).
    // ------------------------------------------------------------------
    always_ff @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            rd_valid_reg <= 1'b0;
            rd_data_reg  <= '0;
        end else if (rd_valid_reg && rd_ready) begin
            // Beat consumed; advance and pre-load next beat if available.
            if (rd_gray_next != wr_gray_sync_rd) begin
                rd_valid_reg <= 1'b1;
                rd_data_reg  <= mem[rd_bin_next[LOG_DEPTH-1:0]];
            end else begin
                rd_valid_reg <= 1'b0;
            end
        end else if (!rd_valid_reg && !rd_empty) begin
            // Nothing currently presented; load the oldest unread beat.
            rd_valid_reg <= 1'b1;
            rd_data_reg  <= mem[rd_bin[LOG_DEPTH-1:0]];
        end
    end

    assign rd_valid = rd_valid_reg;
    assign rd_data  = rd_data_reg;

endmodule
