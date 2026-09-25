// Dual-clock FIFO. Only registered Gray pointers cross clock domains.
// Physical implementation must constrain Gray-bus skew and place each
// synchronizer chain together; RTL simulation cannot model metastability.
module async_fifo_cdc #(
    parameter int DATA_W = 32,
    parameter int LOG_DEPTH = 3,
    parameter int SYNC_STAGES = 2
) (
    input  logic wr_clk,
    input  logic wr_rst_n,
    input  logic wr_valid,
    output logic wr_ready,
    input  logic [DATA_W-1:0] wr_data,
    input  logic rd_clk,
    input  logic rd_rst_n,
    output logic rd_valid,
    input  logic rd_ready,
    output logic [DATA_W-1:0] rd_data
);
    localparam int DEPTH = 1 << LOG_DEPTH;
    localparam int PTR_W = LOG_DEPTH + 1;
    logic [DATA_W-1:0] memory [0:DEPTH-1];
    logic [PTR_W-1:0] wr_binary, wr_gray, rd_binary, rd_gray;
    logic [PTR_W-1:0] wr_binary_next, wr_gray_next;
    logic [PTR_W-1:0] rd_binary_next, rd_gray_next;
    logic full_q, empty_q;
    logic full_next, empty_next;
    (* ASYNC_REG = "TRUE" *) logic [PTR_W-1:0] rd_gray_sync [0:SYNC_STAGES-1];
    (* ASYNC_REG = "TRUE" *) logic [PTR_W-1:0] wr_gray_sync [0:SYNC_STAGES-1];

    assign wr_ready = wr_rst_n && !full_q;
    assign rd_valid = rd_rst_n && !empty_q;
    assign wr_binary_next = wr_binary + {{(PTR_W-1){1'b0}},(wr_valid && wr_ready)};
    assign rd_binary_next = rd_binary + {{(PTR_W-1){1'b0}},(rd_valid && rd_ready)};
    assign wr_gray_next = (wr_binary_next >> 1) ^ wr_binary_next;
    assign rd_gray_next = (rd_binary_next >> 1) ^ rd_binary_next;
    // A separation of DEPTH in binary flips the top TWO Gray bits.
    assign full_next = wr_gray_next ==
        {~rd_gray_sync[SYNC_STAGES-1][PTR_W-1:PTR_W-2],
          rd_gray_sync[SYNC_STAGES-1][PTR_W-3:0]};
    assign empty_next = rd_gray_next == wr_gray_sync[SYNC_STAGES-1];

    always_ff @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) begin
            wr_binary <= '0;
            wr_gray <= '0;
            full_q <= 1'b0;
            for (int s=0;s<SYNC_STAGES;s++) rd_gray_sync[s] <= '0;
        end else begin
            rd_gray_sync[0] <= rd_gray;
            for (int s=1;s<SYNC_STAGES;s++) rd_gray_sync[s] <= rd_gray_sync[s-1];
            wr_binary <= wr_binary_next;
            wr_gray <= wr_gray_next;
            full_q <= full_next;
        end
    end
    always_ff @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            rd_binary <= '0;
            rd_gray <= '0;
            empty_q <= 1'b1;
            for (int s=0;s<SYNC_STAGES;s++) wr_gray_sync[s] <= '0;
        end else begin
            wr_gray_sync[0] <= wr_gray;
            for (int s=1;s<SYNC_STAGES;s++) wr_gray_sync[s] <= wr_gray_sync[s-1];
            rd_binary <= rd_binary_next;
            rd_gray <= rd_gray_next;
            empty_q <= empty_next;
        end
    end
    // Payload storage is not reset. Validity comes exclusively from pointers.
    always_ff @(posedge wr_clk) begin
        if (wr_valid && wr_ready) memory[wr_binary[LOG_DEPTH-1:0]] <= wr_data;
    end
    // While stalled, rd_binary cannot change and this occupied location cannot
    // be overwritten: it is not released until the read pointer crosses back.
    assign rd_data = memory[rd_binary[LOG_DEPTH-1:0]];
endmodule
