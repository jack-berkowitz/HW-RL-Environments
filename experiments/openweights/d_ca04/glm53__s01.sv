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

    // ------------------------------------------------------------------
    // Local parameters
    // ------------------------------------------------------------------
    localparam int DEPTH = 1 << LOG_DEPTH;    // FIFO depth: exactly 2**LOG_DEPTH
    localparam int PW    = LOG_DEPTH + 1;     // pointer width (one wrap bit)
    localparam int SW    = SYNC_STAGES * PW;  // width of each synchronizer shift register

    // ------------------------------------------------------------------
    // Storage: the FIFO proper, and nothing else.
    // Written only in the wr_clk domain, read combinationally in the
    // rd_clk domain once the covering pointer has safely crossed.
    // ------------------------------------------------------------------
    logic [DATA_W-1:0] mem [0:DEPTH-1];

    // ------------------------------------------------------------------
    // Write-domain state
    // ------------------------------------------------------------------
    logic [PW-1:0] wbin;      // binary write pointer
    logic [SW-1:0] rq_sync;   // read Gray pointer, SYNC_STAGES flops in wr_clk

    // ------------------------------------------------------------------
    // Read-domain state
    // ------------------------------------------------------------------
    logic [PW-1:0] rbin;      // binary read pointer
    logic [SW-1:0] wq_sync;   // write Gray pointer, SYNC_STAGES flops in rd_clk

    // ------------------------------------------------------------------
    // Combinational nets (all sourced from registers -> H1/H3 safe)
    // ------------------------------------------------------------------
    logic [PW-1:0] wgray;     // Gray-coded write pointer
    logic [PW-1:0] rgray;     // Gray-coded read pointer
    logic [PW-1:0] rgray_w;   // read Gray pointer resynchronised into wr_clk
    logic [PW-1:0] wgray_r;   // write Gray pointer resynchronised into rd_clk
    logic          full;
    logic          empty;
    logic          wr_accept;
    logic          rd_accept;

    // Gray code: at most one bit changes per pointer increment.
    assign wgray   = wbin ^ (wbin >> 1);
    assign rgray   = rbin ^ (rbin >> 1);

    // Final stage of each synchronizer shift register.
    // Stage 0 (the sampling flop) lives in the low bits; the last stage
    // in the high bits is the value the receiving domain may use.
    assign rgray_w = rq_sync[SW-1 -: PW];
    assign wgray_r = wq_sync[SW-1 -: PW];

    // Full: write Gray pointer equals the synchronised read Gray pointer
    // with its top two bits inverted  <=>  wbin == rbin_w + DEPTH.
    // The synchronised read pointer is stale, so 'full' can only be
    // pessimistic -- never overflow.
    assign full = (wgray == {~rgray_w[PW-1:PW-2], rgray_w[PW-3:0]});

    // Empty: pointers equal in the read domain. Uses only the final
    // synchronizer stage, so rd_valid can never assert on a pointer
    // value still in flight (C5).
    assign empty = (rgray == wgray_r);

    // Handshake outputs. Pure functions of registered state (and the
    // local reset), so toggling wr_valid/rd_ready between edges cannot
    // move them (H1). Gated by the local reset so nothing is accepted
    // or offered while the own domain is held in reset (R4/R5).
    assign wr_ready  = wr_rst_n & ~full;
    assign rd_valid  = rd_rst_n & ~empty;
    assign wr_accept = wr_valid & wr_ready;
    assign rd_accept = rd_valid & rd_ready;

    // Payload comes straight out of the slot the read pointer names.
    // While a beat is offered, rbin is frozen and that slot cannot be
    // overwritten (the write side is throttled by a stale read pointer),
    // so rd_data is stable until the beat is accepted (H3).
    assign rd_data = mem[rbin[LOG_DEPTH-1:0]];

    // ------------------------------------------------------------------
    // Write domain
    // ------------------------------------------------------------------
    always_ff @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) begin
            wbin    <= '0;
            rq_sync <= '0;
        end else begin
            // shift the read Gray pointer through SYNC_STAGES flops
            rq_sync <= {rq_sync[SW-1:PW], rgray};
            if (wr_accept) begin
                mem[wbin[LOG_DEPTH-1:0]] <= wr_data;
                wbin <= wbin + 1'b1;
            end
        end
    end

    // ------------------------------------------------------------------
    // Read domain
    // ------------------------------------------------------------------
    always_ff @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            rbin    <= '0;
            wq_sync <= '0;
        end else begin
            // shift the write Gray pointer through SYNC_STAGES flops
            wq_sync <= {wq_sync[SW-1:PW], wgray};
            if (rd_accept)
                rbin <= rbin + 1'b1;
        end
    end

endmodule
