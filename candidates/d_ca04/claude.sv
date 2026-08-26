// =============================================================================
// async_fifo_cdc.sv
// -----------------------------------------------------------------------------
// Asynchronous FIFO across two unrelated clock domains.
//
// THE CROSSING. Exactly two multi-bit values cross the boundary: the write
// pointer (into the read domain) and the read pointer (into the write domain).
// Both are GRAY CODED, so a single increment changes exactly one bit and a
// receiver that samples mid-transition latches either the old or the new value
// -- never a third value that was never architecturally present. Each is then
// resynchronised through SYNC_STAGES flops CLOCKED BY THE RECEIVING DOMAIN and
// RESET BY THE RECEIVING DOMAIN'S RESET. The payload does not cross: it is
// written in the write domain and only read once the pointer covering it has
// arrived, so it is stable by construction.
//
// WHY THE STALE POINTER IS SAFE IN BOTH DIRECTIONS. A synchronised pointer is
// always the true pointer or an older one, never a newer one. On the write side
// an older read pointer under-states how much has been drained, so `full`
// asserts early -- conservative, never an overflow. On the read side an older
// write pointer under-states how much has been written, so `empty` de-asserts
// late -- conservative, never a phantom beat. Both errors are in the safe
// direction, which is what makes the design correct at every clock ratio.
//
// STORAGE (B1). Zero beats are held outside the FIFO proper: no skid buffer, no
// prefetch stage, no output register. `rd_data` is a combinational read of the
// entry the read pointer selects. That is stable while the beat is unaccepted
// (H3) because the read pointer does not move and the full check prevents the
// writer from ever wrapping onto an unread entry.
//
// DEPTH (C4). The pointers carry one extra bit above LOG_DEPTH, so full and
// empty are distinguishable and the array holds exactly 2**LOG_DEPTH entries.
//
// HANDSHAKE (H1). `wr_ready` is a comparison of two registered pointers and
// does not involve `wr_valid`; `rd_valid` likewise does not involve `rd_ready`.
// =============================================================================

/* verilator lint_off DECLFILENAME */

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
    // Geometry
    // -------------------------------------------------------------------------
    localparam int DEPTH = 1 << LOG_DEPTH;
    localparam int PTR_W = LOG_DEPTH + 1;   // one guard bit above the index

    // -------------------------------------------------------------------------
    // Storage. No reset: entries are only read once the pointer covering them
    // has crossed, so their power-up value is never observable.
    // -------------------------------------------------------------------------
    logic [DATA_W-1:0] mem [DEPTH];

    // -------------------------------------------------------------------------
    // Pointers. Binary form is kept for indexing and incrementing; Gray form is
    // what crosses.
    // -------------------------------------------------------------------------
    logic [PTR_W-1:0] wbin_q,  wgray_q;
    logic [PTR_W-1:0] rbin_q,  rgray_q;
    logic [PTR_W-1:0] wbin_d,  wgray_d;
    logic [PTR_W-1:0] rbin_d,  rgray_d;

    // synchroniser chains, each clocked and reset by the RECEIVING domain
    logic [PTR_W-1:0] rgray_sync [SYNC_STAGES];   // read ptr, seen by writer
    logic [PTR_W-1:0] wgray_sync [SYNC_STAGES];   // write ptr, seen by reader
    logic [PTR_W-1:0] rgray_w, wgray_r;

    logic full_c, empty_c, wr_fire, rd_fire;

    function automatic logic [PTR_W-1:0] bin2gray(input logic [PTR_W-1:0] b);
        return b ^ (b >> 1);
    endfunction

    assign rgray_w = rgray_sync[SYNC_STAGES-1];
    assign wgray_r = wgray_sync[SYNC_STAGES-1];

    // -------------------------------------------------------------------------
    // FULL / EMPTY
    //
    // Empty is plain Gray equality: the reader has caught up with every write it
    // can see.
    //
    // Full is equality against the read pointer with its TOP TWO Gray bits
    // inverted. In binary that is exactly wbin == rbin + DEPTH: the two pointers
    // agree on the index but differ in the guard bit, which is what distinguishes
    // full from empty. Doing the comparison in Gray avoids converting a
    // just-crossed value back to binary.
    // -------------------------------------------------------------------------
    assign full_c  = (wgray_q == {~rgray_w[PTR_W-1], ~rgray_w[PTR_W-2],
                                   rgray_w[PTR_W-3:0]});
    assign empty_c = (rgray_q == wgray_r);

    // The reset terms are belt-and-braces for R4/R5: both comparisons already
    // read 'empty'/'not full' out of reset because every input register is reset
    // to zero, but gating also keeps the outputs driven at 0 before the first
    // edge rather than leaving them to the initial value of the flops.
    assign wr_ready = wr_rst_n & ~full_c;
    assign rd_valid = rd_rst_n & ~empty_c;

    assign wr_fire = wr_valid & wr_ready;
    assign rd_fire = rd_valid & rd_ready;

    // -------------------------------------------------------------------------
    // Write domain
    // -------------------------------------------------------------------------
    assign wbin_d  = wbin_q + {{(PTR_W-1){1'b0}}, wr_fire};
    assign wgray_d = bin2gray(wbin_d);

    always_ff @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) begin
            wbin_q  <= '0;
            wgray_q <= '0;
        end else begin
            wbin_q  <= wbin_d;
            wgray_q <= wgray_d;
        end
    end

    always_ff @(posedge wr_clk) begin
        if (wr_fire) mem[wbin_q[LOG_DEPTH-1:0]] <= wr_data;
    end

    // read pointer arriving in the write domain
    always_ff @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) begin
            for (int i = 0; i < SYNC_STAGES; i++) rgray_sync[i] <= '0;
        end else begin
            rgray_sync[0] <= rgray_q;
            for (int i = 1; i < SYNC_STAGES; i++) rgray_sync[i] <= rgray_sync[i-1];
        end
    end

    // -------------------------------------------------------------------------
    // Read domain
    // -------------------------------------------------------------------------
    assign rbin_d  = rbin_q + {{(PTR_W-1){1'b0}}, rd_fire};
    assign rgray_d = bin2gray(rbin_d);

    always_ff @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            rbin_q  <= '0;
            rgray_q <= '0;
        end else begin
            rbin_q  <= rbin_d;
            rgray_q <= rgray_d;
        end
    end

    // write pointer arriving in the read domain
    always_ff @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            for (int i = 0; i < SYNC_STAGES; i++) wgray_sync[i] <= '0;
        end else begin
            wgray_sync[0] <= wgray_q;
            for (int i = 1; i < SYNC_STAGES; i++) wgray_sync[i] <= wgray_sync[i-1];
        end
    end

    // B1: zero extra storage -- the output is the array entry itself.
    assign rd_data = mem[rbin_q[LOG_DEPTH-1:0]];

endmodule

/* verilator lint_on DECLFILENAME */