// =============================================================================
// async_fifo_cdc.sv
//
// Asynchronous FIFO across two unrelated clocks.
//
// Structure:
//   * one 2**LOG_DEPTH entry array, written in the wr_clk domain and read
//     asynchronously in the rd_clk domain -- no output register, no skid, so
//     ZERO beats of storage outside the FIFO proper (B1 ceiling is 4);
//   * pointers are LOG_DEPTH+1 bits so that full and empty are distinguishable,
//     held in binary locally and converted to GRAY for the crossing, so exactly
//     one bit changes per increment;
//   * each crossing passes through SYNC_STAGES flops clocked by the receiving
//     domain -- the depth comes from the parameter, it is not hard-coded;
//   * full and empty are REGISTERED, computed from the pointer value that will
//     exist after this cycle's transfer, so wr_ready cannot depend
//     combinationally on wr_valid and rd_valid cannot depend on rd_ready (H1).
//
// The pessimism of the crossing is what makes it safe: a stale synchronised
// read pointer can only make the write side look fuller than it is, and a stale
// synchronised write pointer can only make the read side look emptier. Neither
// direction can invent a beat (C5) or overwrite a live one (C4).
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
    // geometry
    // -------------------------------------------------------------------------
    localparam int AW    = LOG_DEPTH;        // address bits
    localparam int PW    = LOG_DEPTH + 1;    // pointer bits: one extra to tell
                                             // full from empty
    localparam int DEPTH = 1 << LOG_DEPTH;

    // -------------------------------------------------------------------------
    // storage
    // -------------------------------------------------------------------------
    logic [DATA_W-1:0] mem [0:DEPTH-1];

    // -------------------------------------------------------------------------
    // write domain state
    // -------------------------------------------------------------------------
    logic [PW-1:0] wbin_q;
    logic [PW-1:0] wgray_q;
    logic [PW-1:0] wbin_nxt;
    logic [PW-1:0] wgray_nxt;
    logic          wr_en;
    logic          full_q;
    logic          full_nxt;

    // read pointer, gray coded, resynchronised into the write domain
    logic [SYNC_STAGES-1:0][PW-1:0] rgray_sync_q;
    logic [PW-1:0]                  rgray_wsync;

    // -------------------------------------------------------------------------
    // read domain state
    // -------------------------------------------------------------------------
    logic [PW-1:0] rbin_q;
    logic [PW-1:0] rgray_q;
    logic [PW-1:0] rbin_nxt;
    logic [PW-1:0] rgray_nxt;
    logic          rd_en;
    logic          empty_q;
    logic          empty_nxt;

    // write pointer, gray coded, resynchronised into the read domain
    logic [SYNC_STAGES-1:0][PW-1:0] wgray_sync_q;
    logic [PW-1:0]                  wgray_rsync;

    // =========================================================================
    // WRITE DOMAIN
    // =========================================================================

    // H1: wr_ready is a register output. full_nxt below is a function of
    // wr_valid, but wr_ready itself is not, so toggling wr_valid between edges
    // cannot move it.
    assign wr_ready = ~full_q;
    assign wr_en    = wr_valid & ~full_q;

    assign wbin_nxt  = wr_en ? (wbin_q + {{(PW-1){1'b0}}, 1'b1}) : wbin_q;
    assign wgray_nxt = wbin_nxt ^ (wbin_nxt >> 1);

    assign rgray_wsync = rgray_sync_q[SYNC_STAGES-1];

    // Full when the write pointer is one wrap ahead of the read pointer: the
    // same address with the top bit inverted. In gray code that is the top TWO
    // bits inverted and the rest equal.
    assign full_nxt = (wgray_nxt == {~rgray_wsync[PW-1],
                                     ~rgray_wsync[PW-2],
                                      rgray_wsync[PW-3:0]});

    always_ff @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) begin
            wbin_q  <= '0;
            wgray_q <= '0;
            full_q  <= 1'b0;          // R4: wr_ready is high the cycle after
                                      // release, well inside 16 cycles
        end else begin
            wbin_q  <= wbin_nxt;
            wgray_q <= wgray_nxt;
            full_q  <= full_nxt;
        end
    end

    // Payload is not synchronised and does not need to be: it is only read once
    // the write pointer covering it has crossed, by which time it is stable.
    always_ff @(posedge wr_clk) begin
        if (wr_en) begin
            mem[wbin_q[AW-1:0]] <= wr_data;
        end
    end

    // Read pointer into the write domain, SYNC_STAGES deep.
    always_ff @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) begin
            rgray_sync_q <= '0;
        end else begin
            rgray_sync_q[0] <= rgray_q;
            for (int i = 1; i < SYNC_STAGES; i++) begin
                rgray_sync_q[i] <= rgray_sync_q[i-1];
            end
        end
    end

    // =========================================================================
    // READ DOMAIN
    // =========================================================================

    // H1/H3: rd_valid is a register output, so it does not move with rd_ready,
    // and while it is high with rd_ready low the read pointer does not advance,
    // so rd_data holds.
    assign rd_valid = ~empty_q;
    assign rd_en    = ~empty_q & rd_ready;

    assign rbin_nxt  = rd_en ? (rbin_q + {{(PW-1){1'b0}}, 1'b1}) : rbin_q;
    assign rgray_nxt = rbin_nxt ^ (rbin_nxt >> 1);

    assign wgray_rsync = wgray_sync_q[SYNC_STAGES-1];

    // Empty when the read pointer has caught the synchronised write pointer.
    // A stale value here only delays the assertion of rd_valid; it can never
    // assert it early, which is what C5 forbids.
    assign empty_nxt = (rgray_nxt == wgray_rsync);

    always_ff @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            rbin_q  <= '0;
            rgray_q <= '0;
            empty_q <= 1'b1;          // R5: rd_valid is low throughout reset
        end else begin
            rbin_q  <= rbin_nxt;
            rgray_q <= rgray_nxt;
            empty_q <= empty_nxt;
        end
    end

    // Write pointer into the read domain, SYNC_STAGES deep. This is the chain
    // the minimum crossing latency is measured through.
    always_ff @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            wgray_sync_q <= '0;
        end else begin
            wgray_sync_q[0] <= wgray_q;
            for (int i = 1; i < SYNC_STAGES; i++) begin
                wgray_sync_q[i] <= wgray_sync_q[i-1];
            end
        end
    end

    // Asynchronous read of the array: no output register, so no beat of storage
    // is held outside the FIFO.
    assign rd_data = mem[rbin_q[AW-1:0]];

endmodule