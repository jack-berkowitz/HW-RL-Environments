// =============================================================================
// async_fifo_cdc -- Gray-pointer asynchronous FIFO
//
//   * Storage: exactly 2**LOG_DEPTH entries of flops, written in wr_clk, read
//     combinationally in rd_clk. No storage outside the FIFO (0 of the 4 beats
//     B1 allows), so capacity at rest is exactly 2**LOG_DEPTH.
//   * Pointers: (LOG_DEPTH+1)-bit Gray counters, held ONLY in Gray form. The
//     binary value needed for addressing and incrementing is decoded from the
//     Gray register, so each side carries LOG_DEPTH+1 pointer flops instead of
//     2*(LOG_DEPTH+1). The Gray register is the crossing source, so exactly one
//     bit changes per increment and every crossing bit leaves a flop.
//   * Each pointer crosses through exactly SYNC_STAGES flops in the receiving
//     domain, reset by that domain's reset.
//   * full / empty are compared combinationally from registers only, so
//     wr_ready never depends on wr_valid and rd_valid never on rd_ready (H1).
//     rd_data is the entry at the read pointer; it is stable while rd_valid is
//     high and unaccepted because the writer cannot reach that entry (H3, C4).
//   * Reset: both sides reset their own pointers and synchronisers. Whichever
//     side releases first sees the other's pointer at zero, which is the true
//     value while that side is held (R1/R2). wr_ready is gated by wr_rst_n so no
//     beat is accepted while the write side is held in reset.
// =============================================================================
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

    localparam int PW    = LOG_DEPTH + 1;       // pointer width (wrap bit + index)
    localparam int DEPTH = 1 << LOG_DEPTH;

    // ---------------------------------------------------------------------------
    // Declarations
    // ---------------------------------------------------------------------------
    logic [DATA_W-1:0] mem [DEPTH];

    logic [PW-1:0] wgray_q, wbin, wgray_nx;
    logic [PW-1:0] rgray_q, rbin, rgray_nx;
    logic [PW-1:0] wsync_q [SYNC_STAGES];    // rd_clk domain: write pointer
    logic [PW-1:0] rsync_q [SYNC_STAGES];    // wr_clk domain: read pointer
    logic [PW-1:0] w_in_rd, r_in_wr;

    logic full, empty, wr_fire, rd_fire;

    // ---------------------------------------------------------------------------
    // Gray <-> binary
    // ---------------------------------------------------------------------------
    function automatic logic [PW-1:0] g2b(input logic [PW-1:0] g);
        logic [PW-1:0] b;
        b[PW-1] = g[PW-1];
        for (int i = PW - 2; i >= 0; i--) b[i] = b[i+1] ^ g[i];
        return b;
    endfunction

    function automatic logic [PW-1:0] b2g(input logic [PW-1:0] b);
        return b ^ (b >> 1);
    endfunction

    // ---------------------------------------------------------------------------
    // Write domain
    // ---------------------------------------------------------------------------
    assign r_in_wr  = rsync_q[SYNC_STAGES-1];
    assign wbin     = g2b(wgray_q);
    assign wgray_nx = b2g(wbin + 1'b1);

    // full: write pointer is exactly one lap ahead of the read pointer
    assign full     = (wgray_q == {~r_in_wr[PW-1:PW-2], r_in_wr[PW-3:0]});
    assign wr_ready = wr_rst_n && !full;
    assign wr_fire  = wr_valid && wr_ready;

    always_ff @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) wgray_q <= '0;
        else if (wr_fire) wgray_q <= wgray_nx;
    end

    always_ff @(posedge wr_clk) begin
        if (wr_fire) mem[wbin[LOG_DEPTH-1:0]] <= wr_data;
    end

    always_ff @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) begin
            for (int s = 0; s < SYNC_STAGES; s++) rsync_q[s] <= '0;
        end else begin
            rsync_q[0] <= rgray_q;
            for (int s = 1; s < SYNC_STAGES; s++) rsync_q[s] <= rsync_q[s-1];
        end
    end

    // ---------------------------------------------------------------------------
    // Read domain
    // ---------------------------------------------------------------------------
    assign w_in_rd  = wsync_q[SYNC_STAGES-1];
    assign rbin     = g2b(rgray_q);
    assign rgray_nx = b2g(rbin + 1'b1);

    assign empty    = (rgray_q == w_in_rd);
    assign rd_valid = !empty;
    assign rd_fire  = rd_valid && rd_ready;
    assign rd_data  = mem[rbin[LOG_DEPTH-1:0]];

    always_ff @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) rgray_q <= '0;
        else if (rd_fire) rgray_q <= rgray_nx;
    end

    always_ff @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            for (int s = 0; s < SYNC_STAGES; s++) wsync_q[s] <= '0;
        end else begin
            wsync_q[0] <= wgray_q;
            for (int s = 1; s < SYNC_STAGES; s++) wsync_q[s] <= wsync_q[s-1];
        end
    end

endmodule