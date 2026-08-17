// =============================================================================
// async_fifo_cdc.sv  --  Asynchronous FIFO with Gray Code Pointers
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

    localparam int DEPTH = 1 << LOG_DEPTH;

    logic [LOG_DEPTH:0] w_ptr;
    logic [LOG_DEPTH:0] r_ptr;
    logic [LOG_DEPTH:0] w_ptr_gray;
    logic [LOG_DEPTH:0] r_ptr_gray;

    logic [LOG_DEPTH:0] w_ptr_gray_sync [0:SYNC_STAGES-1];
    logic [LOG_DEPTH:0] r_ptr_gray_sync [0:SYNC_STAGES-1];

    // Binary to Gray code conversion
    assign w_ptr_gray = (w_ptr >> 1) ^ w_ptr;
    assign r_ptr_gray = (r_ptr >> 1) ^ r_ptr;

    // =========================================================================
    // Write Domain
    // =========================================================================
    always_ff @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) begin
            w_ptr <= '0;
            for (int i = 0; i < SYNC_STAGES; i++) r_ptr_gray_sync[i] <= '0;
        end else begin
            if (wr_valid && wr_ready) begin
                w_ptr <= w_ptr + 1;
            end
            // Synchronize read pointer into write domain
            r_ptr_gray_sync[0] <= r_ptr_gray;
            for (int i = 1; i < SYNC_STAGES; i++) begin
                r_ptr_gray_sync[i] <= r_ptr_gray_sync[i-1];
            end
        end
    end

    // Full condition: pointers differ only in the top two bits
    logic wr_full;
    always @(*) begin
        if (LOG_DEPTH == 2) begin
            wr_full = (w_ptr_gray[2] == ~r_ptr_gray_sync[SYNC_STAGES-1][2]) &&
                      (w_ptr_gray[1] == ~r_ptr_gray_sync[SYNC_STAGES-1][1]) &&
                      (w_ptr_gray[0] == r_ptr_gray_sync[SYNC_STAGES-1][0]);
        end else if (LOG_DEPTH == 3) begin
            wr_full = (w_ptr_gray[3] == ~r_ptr_gray_sync[SYNC_STAGES-1][3]) &&
                      (w_ptr_gray[2] == ~r_ptr_gray_sync[SYNC_STAGES-1][2]) &&
                      (w_ptr_gray[1:0] == r_ptr_gray_sync[SYNC_STAGES-1][1:0]);
        end else begin // LOG_DEPTH == 4
            wr_full = (w_ptr_gray[4] == ~r_ptr_gray_sync[SYNC_STAGES-1][4]) &&
                      (w_ptr_gray[3] == ~r_ptr_gray_sync[SYNC_STAGES-1][3]) &&
                      (w_ptr_gray[2:0] == r_ptr_gray_sync[SYNC_STAGES-1][2:0]);
        end
    end
    
    // H1: wr_ready does not depend combinationally on wr_valid
    assign wr_ready = ~wr_full;

    // =========================================================================
    // Read Domain
    // =========================================================================
    always_ff @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            r_ptr <= '0;
            for (int i = 0; i < SYNC_STAGES; i++) w_ptr_gray_sync[i] <= '0;
        end else begin
            if (rd_valid && rd_ready) begin
                r_ptr <= r_ptr + 1;
            end
            // Synchronize write pointer into read domain
            w_ptr_gray_sync[0] <= w_ptr_gray;
            for (int i = 1; i < SYNC_STAGES; i++) begin
                w_ptr_gray_sync[i] <= w_ptr_gray_sync[i-1];
            end
        end
    end

    // Empty condition: pointers are exactly equal
    logic rd_empty;
    assign rd_empty = (r_ptr_gray == w_ptr_gray_sync[SYNC_STAGES-1]);
    
    // H1 & R5: rd_valid does not depend on rd_ready, and is strictly 0 when rd_rst_n is low
    assign rd_valid = (rd_rst_n === 1'b1) ? ~rd_empty : 1'b0;

    // =========================================================================
    // Data Memory
    // =========================================================================
    logic [DATA_W-1:0] fifo_mem [0:DEPTH-1];
    logic [LOG_DEPTH-1:0] w_addr;
    logic [LOG_DEPTH-1:0] r_addr;

    assign w_addr = w_ptr[LOG_DEPTH-1:0];
    assign r_addr = r_ptr[LOG_DEPTH-1:0];

    // Synchronous write
    always_ff @(posedge wr_clk) begin
        if (wr_valid && wr_ready) begin
            fifo_mem[w_addr] <= wr_data;
        end
    end

    // Combinational read (safe because r_addr only changes when data is valid and stable)
    assign rd_data = fifo_mem[r_addr];

endmodule