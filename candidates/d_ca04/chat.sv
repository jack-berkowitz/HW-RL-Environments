// =============================================================================
// async_fifo_cdc.sv
// =============================================================================
// Asynchronous FIFO with Gray-coded CDC pointers.
//
// - FIFO depth is exactly 2**LOG_DEPTH.
// - Write and read clocks are completely unrelated.
// - Binary pointers are used locally for RAM addressing.
// - Gray-coded pointers cross clock domains.
// - Crossing pointers pass through exactly SYNC_STAGES synchronizer flops.
// - Payload RAM itself is not synchronized; the synchronized pointer guarantees
//   that a location is stable before the read side considers it available.
// - No additional beat storage is used beyond the FIFO memory.
// =============================================================================

module async_fifo_cdc #(
    parameter int DATA_W      = 32,
    parameter int LOG_DEPTH   = 3,
    parameter int SYNC_STAGES = 2
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
    // Geometry
    // -------------------------------------------------------------------------

    localparam int DEPTH = (1 << LOG_DEPTH);

    // One extra pointer bit is required to distinguish full from empty after
    // the address portion wraps.
    localparam int PTR_W = LOG_DEPTH + 1;

    // -------------------------------------------------------------------------
    // Storage
    // -------------------------------------------------------------------------

    logic [DATA_W-1:0] mem [0:DEPTH-1];

    // -------------------------------------------------------------------------
    // Local binary and Gray pointers
    // -------------------------------------------------------------------------

    logic [PTR_W-1:0] wr_bin_q;
    logic [PTR_W-1:0] wr_gray_q;

    logic [PTR_W-1:0] rd_bin_q;
    logic [PTR_W-1:0] rd_gray_q;

    // -------------------------------------------------------------------------
    // Pointer synchronizers
    //
    // Only Gray-coded pointers cross clock domains.
    // -------------------------------------------------------------------------

    logic [PTR_W-1:0] rd_gray_sync_q [0:SYNC_STAGES-1];
    logic [PTR_W-1:0] wr_gray_sync_q [0:SYNC_STAGES-1];

    // -------------------------------------------------------------------------
    // Miscellaneous signals
    // -------------------------------------------------------------------------

    logic [PTR_W-1:0] rd_gray_full_cmp;

    logic wr_full;
    logic rd_empty;

    logic wr_fire;
    logic rd_fire;

    integer i;

    // -------------------------------------------------------------------------
    // Binary -> Gray conversion
    // -------------------------------------------------------------------------

    function automatic logic [PTR_W-1:0] bin_to_gray(
        input logic [PTR_W-1:0] bin
    );
        bin_to_gray = (bin >> 1) ^ bin;
    endfunction

    // -------------------------------------------------------------------------
    // Synchronize read pointer into write clock domain
    // -------------------------------------------------------------------------

    always_ff @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) begin
            for (i = 0; i < SYNC_STAGES; i = i + 1) begin
                rd_gray_sync_q[i] <= '0;
            end
        end else begin
            rd_gray_sync_q[0] <= rd_gray_q;

            for (i = 1; i < SYNC_STAGES; i = i + 1) begin
                rd_gray_sync_q[i] <= rd_gray_sync_q[i-1];
            end
        end
    end

    // -------------------------------------------------------------------------
    // Synchronize write pointer into read clock domain
    // -------------------------------------------------------------------------

    always_ff @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            for (i = 0; i < SYNC_STAGES; i = i + 1) begin
                wr_gray_sync_q[i] <= '0;
            end
        end else begin
            wr_gray_sync_q[0] <= wr_gray_q;

            for (i = 1; i < SYNC_STAGES; i = i + 1) begin
                wr_gray_sync_q[i] <= wr_gray_sync_q[i-1];
            end
        end
    end

    // -------------------------------------------------------------------------
    // Full detection
    //
    // For an asynchronous FIFO with an extra wrap bit, the write pointer is
    // exactly one FIFO-length ahead of the read pointer when the FIFO is full.
    //
    // In Gray code this condition is detected by complementing the upper two
    // bits of the synchronized read pointer and comparing all remaining bits
    // directly.
    // -------------------------------------------------------------------------

    always_comb begin
        rd_gray_full_cmp = rd_gray_sync_q[SYNC_STAGES-1];

        rd_gray_full_cmp[PTR_W-1] = ~rd_gray_sync_q[SYNC_STAGES-1][PTR_W-1];
        rd_gray_full_cmp[PTR_W-2] = ~rd_gray_sync_q[SYNC_STAGES-1][PTR_W-2];

        wr_full = (wr_gray_q == rd_gray_full_cmp);
    end

    // -------------------------------------------------------------------------
    // Empty detection
    //
    // Once the synchronized write pointer equals the local read pointer there
    // are no architecturally visible entries remaining.
    // -------------------------------------------------------------------------

    always_comb begin
        rd_empty = (rd_gray_q == wr_gray_sync_q[SYNC_STAGES-1]);
    end

    // -------------------------------------------------------------------------
    // Handshake outputs
    //
    // wr_ready depends only on FIFO state, never combinationally on wr_valid.
    // rd_valid depends only on FIFO state, never combinationally on rd_ready.
    // -------------------------------------------------------------------------

    always_comb begin
        wr_ready = wr_rst_n && !wr_full;
        rd_valid = rd_rst_n && !rd_empty;

        wr_fire = wr_valid && wr_ready;
        rd_fire = rd_valid && rd_ready;
    end

    // -------------------------------------------------------------------------
    // Write-side pointer and RAM write
    // -------------------------------------------------------------------------

    always_ff @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) begin
            wr_bin_q  <= '0;
            wr_gray_q <= '0;
        end else begin
            if (wr_fire) begin
                mem[wr_bin_q[LOG_DEPTH-1:0]] <= wr_data;

                wr_bin_q  <= wr_bin_q + {{(PTR_W-1){1'b0}}, 1'b1};
                wr_gray_q <= bin_to_gray(
                    wr_bin_q + {{(PTR_W-1){1'b0}}, 1'b1}
                );
            end
        end
    end

    // -------------------------------------------------------------------------
    // Read-side pointer
    // -------------------------------------------------------------------------

    always_ff @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            rd_bin_q  <= '0;
            rd_gray_q <= '0;
        end else begin
            if (rd_fire) begin
                rd_bin_q  <= rd_bin_q + {{(PTR_W-1){1'b0}}, 1'b1};
                rd_gray_q <= bin_to_gray(
                    rd_bin_q + {{(PTR_W-1){1'b0}}, 1'b1}
                );
            end
        end
    end

    // -------------------------------------------------------------------------
    // Read data
    //
    // The payload is intentionally not passed through synchronizer flops.
    //
    // A memory location is written before its corresponding Gray pointer can
    // propagate through SYNC_STAGES rd_clk synchronizer stages. By the time
    // rd_valid can assert for that entry, the payload is already stable.
    //
    // While rd_valid && !rd_ready, rd_bin_q cannot advance. The location being
    // presented therefore remains unchanged. Full detection on the write side
    // prevents that unread location from being overwritten.
    // -------------------------------------------------------------------------

    always_comb begin
        rd_data = mem[rd_bin_q[LOG_DEPTH-1:0]];
    end

endmodule