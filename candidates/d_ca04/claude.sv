// =============================================================================
// async_fifo_cdc.sv -- asynchronous FIFO across an unrelated-clock CDC boundary
// =============================================================================
// Structure:
//   * (LOG_DEPTH+1)-bit binary pointers, converted to Gray for the crossing.
//     The extra MSB distinguishes full from empty without sacrificing an entry,
//     so the FIFO holds a full 2**LOG_DEPTH beats (C4).
//   * Each Gray pointer crosses through SYNC_STAGES flops clocked by the
//     RECEIVING domain. Nothing bypasses the synchroniser chain, so minimum
//     observed crossing latency scales with SYNC_STAGES.
//   * full/empty are registered in their own domains, so wr_ready is not a
//     function of wr_valid and rd_valid is not a function of rd_ready (H1).
//   * Payload is unsynchronised, single-write / single-read dual-port memory.
//     The covering pointer crosses after the data is committed, so the entry is
//     stable by the time the far side can address it.
//
// Conservatism of the pointer comparisons is what makes this safe: a Gray value
// caught mid-transition resolves to either the old or the new count (one bit
// differs), never to a spurious third value. Stale-but-valid means the writer
// may briefly believe the FIFO is fuller than it is and the reader emptier --
// both directions are safe, and both self-correct on the next crossing.
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

    localparam int DEPTH = 1 << LOG_DEPTH;   // entries
    localparam int PW    = LOG_DEPTH + 1;    // pointer width (extra wrap bit)

    function automatic logic [PW-1:0] bin2gray(input logic [PW-1:0] b);
        return b ^ (b >> 1);
    endfunction

    // -------------------------------------------------------------------------
    // storage: written in wr_clk, read asynchronously by the rd_clk pointer
    // -------------------------------------------------------------------------
    logic [DATA_W-1:0] mem [DEPTH];

    // -------------------------------------------------------------------------
    // pointers / flags
    // -------------------------------------------------------------------------
    logic [PW-1:0] wr_bin_q,  wr_bin_d,  wr_gray_q,  wr_gray_d;
    logic [PW-1:0] rd_bin_q,  rd_bin_d,  rd_gray_q,  rd_gray_d;
    logic          full_q,    full_d;
    logic          empty_q,   empty_d;
    logic          wr_fire,   rd_fire;

    // Synchroniser chains. Index 0 is the metastability-catching flop; index
    // SYNC_STAGES-1 is the only stage any logic is allowed to look at.
    (* ASYNC_REG = "TRUE" *) logic [PW-1:0] wr_gray_sync [SYNC_STAGES];
    (* ASYNC_REG = "TRUE" *) logic [PW-1:0] rd_gray_sync [SYNC_STAGES];

    assign wr_ready = ~full_q;
    assign rd_valid = ~empty_q;
    assign wr_fire  = wr_valid & wr_ready;
    assign rd_fire  = rd_valid & rd_ready;

    // =========================================================================
    // WRITE DOMAIN
    // =========================================================================
    assign wr_bin_d  = wr_bin_q + PW'(wr_fire);
    assign wr_gray_d = bin2gray(wr_bin_d);

    // Full when the next write pointer would collide with the (synchronised)
    // read pointer one wrap ahead: in Gray, that is the read pointer with its
    // top two bits inverted.
    assign full_d = (wr_gray_d == {~rd_gray_sync[SYNC_STAGES-1][PW-1:PW-2],
                                    rd_gray_sync[SYNC_STAGES-1][PW-3:0]});

    always_ff @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) begin
            wr_bin_q  <= '0;
            wr_gray_q <= '0;
            full_q    <= 1'b0;   // R4: wr_ready is high the cycle after release
        end else begin
            wr_bin_q  <= wr_bin_d;
            wr_gray_q <= wr_gray_d;
            full_q    <= full_d;
        end
    end

    always_ff @(posedge wr_clk) begin
        if (wr_fire) mem[wr_bin_q[LOG_DEPTH-1:0]] <= wr_data;
    end

    // read pointer -> write domain
    always_ff @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) begin
            for (int i = 0; i < SYNC_STAGES; i++) rd_gray_sync[i] <= '0;
        end else begin
            rd_gray_sync[0] <= rd_gray_q;
            for (int i = 1; i < SYNC_STAGES; i++)
                rd_gray_sync[i] <= rd_gray_sync[i-1];
        end
    end

    // =========================================================================
    // READ DOMAIN
    // =========================================================================
    assign rd_bin_d  = rd_bin_q + PW'(rd_fire);
    assign rd_gray_d = bin2gray(rd_bin_d);

    assign empty_d = (rd_gray_d == wr_gray_sync[SYNC_STAGES-1]);

    always_ff @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            rd_bin_q  <= '0;
            rd_gray_q <= '0;
            empty_q   <= 1'b1;   // R5: rd_valid low out of / during reset
        end else begin
            rd_bin_q  <= rd_bin_d;
            rd_gray_q <= rd_gray_d;
            empty_q   <= empty_d;
        end
    end

    // write pointer -> read domain
    always_ff @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            for (int i = 0; i < SYNC_STAGES; i++) wr_gray_sync[i] <= '0;
        end else begin
            wr_gray_sync[0] <= wr_gray_q;
            for (int i = 1; i < SYNC_STAGES; i++)
                wr_gray_sync[i] <= wr_gray_sync[i-1];
        end
    end

    // Combinational read of the head entry. The entry cannot be overwritten
    // while it is unread (full logic forbids it) and rd_bin_q does not move
    // until the beat is accepted, so rd_data is stable across a stalled
    // handshake (H3).
    assign rd_data = mem[rd_bin_q[LOG_DEPTH-1:0]];

    // =========================================================================
    // Parameter legality
    // =========================================================================
`ifndef SYNTHESIS
    initial begin
        assert (DATA_W == 8 || DATA_W == 32 || DATA_W == 64)
            else $fatal(1, "async_fifo_cdc: illegal DATA_W=%0d", DATA_W);
        assert (LOG_DEPTH >= 2 && LOG_DEPTH <= 4)
            else $fatal(1, "async_fifo_cdc: illegal LOG_DEPTH=%0d", LOG_DEPTH);
        assert (SYNC_STAGES == 2 || SYNC_STAGES == 3)
            else $fatal(1, "async_fifo_cdc: illegal SYNC_STAGES=%0d", SYNC_STAGES);
    end
`endif

endmodule