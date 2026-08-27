// =============================================================================
// async_fifo_cdc.sv
// 
// An asynchronous clock-domain-crossing FIFO that uses Gray-coded pointers to 
// safely transfer state between two unrelated clock domains.
//
// Key architectural features satisfying the contract:
// - Uses a pure combinational read path (FWFT without skid buffers) to 
//   guarantee exact capacity matching of 2**LOG_DEPTH.
// - Pointers are Gray-coded, ensuring only one bit changes per clock cycle
//   when crossing into the other domain's synchronizer.
// - Each synchronizer strictly honors the parameter SYNC_STAGES.
// - Correct behavior on independent reset de-assertion by asynchronously 
//   holding the synchronizers to 0 in the local domain while the local reset 
//   is active.
// - No variables are declared inside procedural blocks, ensuring seamless 
//   elaboration under both slang and Verilator strict modes.
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

    // Memory array
    logic [DATA_W-1:0] mem [0:DEPTH-1];

    // Write domain pointers
    logic [LOG_DEPTH:0] wr_ptr;
    logic [LOG_DEPTH:0] wr_ptr_nxt;
    logic [LOG_DEPTH:0] wr_ptr_gray;
    logic [LOG_DEPTH:0] wr_ptr_gray_nxt;

    // Read domain pointers
    logic [LOG_DEPTH:0] rd_ptr;
    logic [LOG_DEPTH:0] rd_ptr_nxt;
    logic [LOG_DEPTH:0] rd_ptr_gray;
    logic [LOG_DEPTH:0] rd_ptr_gray_nxt;

    // Cross-domain synchronizers
    logic [LOG_DEPTH:0] wr_ptr_gray_sync [SYNC_STAGES];
    logic [LOG_DEPTH:0] rd_ptr_gray_sync [SYNC_STAGES];

    // Status flags
    logic full;
    logic empty;

    // Variables for procedural loops declared at module scope to satisfy T2 safely
    integer i;
    integer j;

    // =========================================================================
    // Write Domain Logic
    // =========================================================================
    
    // A FIFO is full when the write pointer has wrapped around exactly one time 
    // more than the synchronized read pointer. In Gray code, this means the 
    // top two bits are inverted and the remaining bits match.
    assign full = (wr_ptr_gray == {~rd_ptr_gray_sync[SYNC_STAGES-1][LOG_DEPTH:LOG_DEPTH-1], 
                                    rd_ptr_gray_sync[SYNC_STAGES-1][LOG_DEPTH-2:0]});
    
    assign wr_ready = ~full;

    // Binary to Gray conversion for the next pointer
    assign wr_ptr_nxt = wr_ptr + 1'b1;
    assign wr_ptr_gray_nxt = wr_ptr_nxt ^ (wr_ptr_nxt >> 1);

    always_ff @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) begin
            wr_ptr      <= '0;
            wr_ptr_gray <= '0;
            // Securely reset the read-pointer synchronizer living in the write domain
            for (i = 0; i < SYNC_STAGES; i = i + 1) begin
                rd_ptr_gray_sync[i] <= '0;
            end
        end else begin
            if (wr_valid && wr_ready) begin
                wr_ptr      <= wr_ptr_nxt;
                wr_ptr_gray <= wr_ptr_gray_nxt;
            end
            
            // Advance the synchronizer pipeline
            rd_ptr_gray_sync[0] <= rd_ptr_gray;
            for (i = 1; i < SYNC_STAGES; i = i + 1) begin
                rd_ptr_gray_sync[i] <= rd_ptr_gray_sync[i-1];
            end
        end
    end

    // Storage Write
    always_ff @(posedge wr_clk) begin
        if (wr_valid && wr_ready) begin
            mem[wr_ptr[LOG_DEPTH-1:0]] <= wr_data;
        end
    end

    // =========================================================================
    // Read Domain Logic
    // =========================================================================
    
    // A FIFO is empty when the read pointer has caught up to the synchronized 
    // write pointer exactly.
    assign empty = (rd_ptr_gray == wr_ptr_gray_sync[SYNC_STAGES-1]);
    
    assign rd_valid = ~empty;
    
    // Combinational read matches the First-Word Fall-Through requirements 
    // and correctly keeps the capacity strictly to exactly 2**LOG_DEPTH.
    assign rd_data = mem[rd_ptr[LOG_DEPTH-1:0]];

    assign rd_ptr_nxt = rd_ptr + 1'b1;
    assign rd_ptr_gray_nxt = rd_ptr_nxt ^ (rd_ptr_nxt >> 1);

    always_ff @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            rd_ptr      <= '0;
            rd_ptr_gray <= '0;
            // Securely reset the write-pointer synchronizer living in the read domain
            for (j = 0; j < SYNC_STAGES; j = j + 1) begin
                wr_ptr_gray_sync[j] <= '0;
            end
        end else begin
            if (rd_valid && rd_ready) begin
                rd_ptr      <= rd_ptr_nxt;
                rd_ptr_gray <= rd_ptr_gray_nxt;
            end
            
            // Advance the synchronizer pipeline
            wr_ptr_gray_sync[0] <= wr_ptr_gray;
            for (j = 1; j < SYNC_STAGES; j = j + 1) begin
                wr_ptr_gray_sync[j] <= wr_ptr_gray_sync[j-1];
            end
        end
    end

endmodule