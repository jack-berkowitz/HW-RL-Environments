// =============================================================================
// async_fifo_cdc.sv -- asynchronous FIFO clock-domain crossing
//
// Architecture: Clifford Cummings style.
//   - Dual-port storage written in the write domain, read in the read domain.
//   - Binary pointers are one bit wider than the address (wrap/phase bit).
//   - Pointers cross the boundary Gray-encoded (one bit changes per increment)
//     and are resynchronised through SYNC_STAGES flops in the receiving domain.
//   - full/empty are REGISTERED flags, so wr_ready / rd_valid are pure flop
//     outputs: no combinational dependence on wr_valid / rd_ready (H1).
//   - Capacity is exactly 2**LOG_DEPTH entries (C4).
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

    localparam int DEPTH = 2**LOG_DEPTH;
    localparam int PTR_W = LOG_DEPTH + 1;   // extra wrap/phase bit

    // -------------------------------------------------------------------------
    // Gray <-> binary helpers
    // -------------------------------------------------------------------------
    function automatic logic [PTR_W-1:0] bin2gray(input logic [PTR_W-1:0] b);
        return (b >> 1) ^ b;
    endfunction

    // (gray2bin is not needed: each domain keeps its own binary pointer and
    //  only the Gray form crosses; full/empty compares are done in Gray.)

    // -------------------------------------------------------------------------
    // Storage. Written only in the write domain; read combinationally in the
    // read domain. The payload never passes through a synchroniser: by the time
    // the read-side pointer that covers an entry has crossed, the data has been
    // stable for many wr_clk cycles, so it is safe to sample.
    // -------------------------------------------------------------------------
    logic [DATA_W-1:0] mem [0:DEPTH-1];

    // =========================================================================
    // Write domain
    // =========================================================================
    logic [PTR_W-1:0] wr_bin;                       // local binary write pointer
    logic [PTR_W-1:0] wr_gray;                      // Gray form (this crosses)
    logic [PTR_W-1:0] rd_gray_wsync [SYNC_STAGES];  // rd pointer synced into wr clk
    logic             wr_full;

    wire              wr_accept    = wr_valid & wr_ready;
    wire [PTR_W-1:0]  wr_bin_next  = wr_bin + (wr_accept ? PTR_W'(1) : PTR_W'(0));
    wire [PTR_W-1:0]  wr_gray_next = bin2gray(wr_bin_next);
    wire [PTR_W-1:0]  rd_gray_w    = rd_gray_wsync[SYNC_STAGES-1];

    assign wr_ready = ~wr_full;   // pure flop output (H1)

    always_ff @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) begin
            wr_bin  <= '0;
            wr_gray <= '0;
            wr_full <= 1'b0;      // empty out of reset -> wr_ready = 1 immediately (R4)
            for (int s = 0; s < SYNC_STAGES; s++)
                rd_gray_wsync[s] <= '0;
        end else begin
            // SYNC_STAGES-deep synchroniser for the read pointer (Gray)
            rd_gray_wsync[0] <= rd_gray;
            for (int s = 1; s < SYNC_STAGES; s++)
                rd_gray_wsync[s] <= rd_gray_wsync[s-1];

            // advance pointer and store payload on acceptance
            if (wr_accept) begin
                wr_bin                       <= wr_bin_next;
                wr_gray                      <= wr_gray_next;
                mem[wr_bin[LOG_DEPTH-1:0]]   <= wr_data;
            end

            // Registered full: next write pointer equals synced read pointer
            // with the two MSBs (wrap bit + phase) inverted.
            wr_full <= (wr_gray_next == {~rd_gray_w[PTR_W-1 -: 2],
                                          rd_gray_w[PTR_W-3:0]});
        end
    end

    // =========================================================================
    // Read domain
    // =========================================================================
    logic [PTR_W-1:0] rd_bin;                       // local binary read pointer
    logic [PTR_W-1:0] rd_gray;                      // Gray form (this crosses)
    logic [PTR_W-1:0] wr_gray_rsync [SYNC_STAGES];  // wr pointer synced into rd clk
    logic             rd_empty;

    wire              rd_accept    = rd_valid & rd_ready;
    wire [PTR_W-1:0]  rd_bin_next  = rd_bin + (rd_accept ? PTR_W'(1) : PTR_W'(0));
    wire [PTR_W-1:0]  rd_gray_next = bin2gray(rd_bin_next);
    wire [PTR_W-1:0]  wr_gray_r    = wr_gray_rsync[SYNC_STAGES-1];

    assign rd_valid = ~rd_empty;                     // pure flop output (H1/H3)
    assign rd_data  = mem[rd_bin[LOG_DEPTH-1:0]];    // stable while rd_bin holds

    always_ff @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            rd_bin   <= '0;
            rd_gray  <= '0;
            rd_empty <= 1'b1;     // empty out of reset -> rd_valid = 0 (R4/R5)
            for (int s = 0; s < SYNC_STAGES; s++)
                wr_gray_rsync[s] <= '0;
        end else begin
            // SYNC_STAGES-deep synchroniser for the write pointer (Gray)
            wr_gray_rsync[0] <= wr_gray;
            for (int s = 1; s < SYNC_STAGES; s++)
                wr_gray_rsync[s] <= wr_gray_rsync[s-1];

            // advance pointer on acceptance
            if (rd_accept) begin
                rd_bin  <= rd_bin_next;
                rd_gray <= rd_gray_next;
            end

            // Registered empty: next read pointer catches the synced write pointer.
            rd_empty <= (rd_gray_next == wr_gray_r);
        end
    end

endmodule