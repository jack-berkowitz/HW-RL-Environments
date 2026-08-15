// ============================================================================
// p2_ignores_log_depth -- AUDIT PROBE for d_ca04. NEVER SHIPPED.
// ============================================================================
// Ignores LOG_DEPTH: always 4 entries, whatever depth was requested.
// Derived from tb/async_fifo_cdc_alt_ref.sv by one edit. It is otherwise a
// correct FIFO: it loses nothing, duplicates nothing and preserves order.
// The ONLY thing wrong with it is that it ignores the parameter named above.
// If the checker passes it, that parameter is UNBOUND.
// ============================================================================
`timescale 1ps/1ps

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

    // PROBE: fixed 4-entry FIFO regardless of LOG_DEPTH
    localparam int EFF_LD = 2;
    localparam int DEPTH = 1 << EFF_LD;
    localparam int PW    = EFF_LD + 1;      // one extra bit distinguishes full from empty

    // Unpacked, memory-style storage.
    logic [DATA_W-1:0] mem [0:DEPTH-1];

    logic [PW-1:0] wbin, wgray, wbin_n, wgray_n;
    logic [PW-1:0] rbin, rgray, rbin_n, rgray_n;

    // Synchroniser chains. Gray-coded pointers only: exactly one bit changes
    // per increment, so a value latched mid-transition is always either the old
    // or the new pointer, never a third value that never existed.
    logic [PW-1:0] wgray_sync [0:SYNC_STAGES-1];   // wgray seen in the READ domain
    logic [PW-1:0] rgray_sync [0:SYNC_STAGES-1];   // rgray seen in the WRITE domain

    function automatic logic [PW-1:0] bin2gray(input logic [PW-1:0] b);
        return b ^ (b >> 1);
    endfunction

    // ---- write domain ------------------------------------------------------
    assign wbin_n  = wbin + (wr_valid && wr_ready ? PW'(1) : PW'(0));
    assign wgray_n = bin2gray(wbin_n);

    // Full when the next write pointer would equal the synchronised read
    // pointer with the top TWO bits inverted -- the standard Gray full test.
    wire full = (wgray_n == {~rgray_sync[SYNC_STAGES-1][PW-1:PW-2],
                              rgray_sync[SYNC_STAGES-1][PW-3:0]});

    // wr_ready depends on occupancy only, never on wr_valid (spec H1).
    assign wr_ready = wr_rst_n && !(wgray == {~rgray_sync[SYNC_STAGES-1][PW-1:PW-2],
                                               rgray_sync[SYNC_STAGES-1][PW-3:0]});

    always_ff @(posedge wr_clk) begin
        if (!wr_rst_n) begin
            wbin  <= '0;
            wgray <= '0;
            for (int i = 0; i < SYNC_STAGES; i++) rgray_sync[i] <= '0;
        end else begin
            if (wr_valid && wr_ready) begin
                mem[wbin[EFF_LD-1:0]] <= wr_data;
                wbin  <= wbin_n;
                wgray <= wgray_n;
            end
            rgray_sync[0] <= rgray;
            for (int i = 1; i < SYNC_STAGES; i++) rgray_sync[i] <= rgray_sync[i-1];
        end
    end

    // ---- read domain -------------------------------------------------------
    assign rbin_n  = rbin + (rd_valid && rd_ready ? PW'(1) : PW'(0));
    assign rgray_n = bin2gray(rbin_n);

    // Empty when the local read pointer has caught the synchronised write
    // pointer exactly.
    assign rd_valid = rd_rst_n && (rgray != wgray_sync[SYNC_STAGES-1]);
    assign rd_data  = mem[rbin[EFF_LD-1:0]];

    always_ff @(posedge rd_clk) begin
        if (!rd_rst_n) begin
            rbin  <= '0;
            rgray <= '0;
            for (int i = 0; i < SYNC_STAGES; i++) wgray_sync[i] <= '0;
        end else begin
            if (rd_valid && rd_ready) begin
                rbin  <= rbin_n;
                rgray <= rgray_n;
            end
            wgray_sync[0] <= wgray;
            for (int i = 1; i < SYNC_STAGES; i++) wgray_sync[i] <= wgray_sync[i-1];
        end
    end

endmodule
