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

    localparam int DEPTH = 1 << LOG_DEPTH;
    localparam int PTR_W = LOG_DEPTH + 1;

    // Gray-code helper
    function automatic logic [PTR_W-1:0] bin2gray(
        input logic [PTR_W-1:0] b
    );
        bin2gray = b ^ (b >> 1);
    endfunction

    // --------------------------------------------------------------------------
    // Storage
    // --------------------------------------------------------------------------
    logic [DATA_W-1:0] mem [0:DEPTH-1];

    // --------------------------------------------------------------------------
    // Write domain
    // --------------------------------------------------------------------------
    logic [PTR_W-1:0] wbin, wgray;
    logic [PTR_W-1:0] rgray_sync [0:SYNC_STAGES-1];
    logic             full_r;

    logic             wr_accept;
    logic [PTR_W-1:0] wbin_next;
    logic [PTR_W-1:0] wgray_next;
    logic [PTR_W-1:0] rgray_c;

    assign wr_accept  = wr_valid && wr_ready;
    assign wbin_next  = wbin + (wr_accept ? 1 : 0);
    assign wgray_next = bin2gray(wbin_next);
    assign rgray_c    = rgray_sync[SYNC_STAGES-1];

    assign wr_ready   = ~full_r;

    always_ff @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) begin
            wbin    <= '0;
            wgray   <= '0;
            full_r  <= 1'b0;
            for (int i = 0; i < SYNC_STAGES; i++)
                rgray_sync[i] <= '0;
        end else begin
            // synchronise read Gray pointer into write domain
            rgray_sync[0] <= rgray;
            for (int i = 1; i < SYNC_STAGES; i++)
                rgray_sync[i] <= rgray_sync[i-1];

            wbin  <= wbin_next;
            wgray <= wgray_next;

            // full when the next write Gray pointer equals the synchronised
            // read Gray pointer with its top two bits inverted
            full_r <= (wgray_next ==
                       {~rgray_c[PTR_W-1:PTR_W-2], rgray_c[PTR_W-2:0]});

            if (wr_accept)
                mem[wbin[LOG_DEPTH-1:0]] <= wr_data;
        end
    end

    // --------------------------------------------------------------------------
    // Read domain
    // --------------------------------------------------------------------------
    logic [PTR_W-1:0] rbin, rgray;
    logic [PTR_W-1:0] wgray_sync [0:SYNC_STAGES-1];
    logic             empty_r;

    logic             rd_accept;
    logic [PTR_W-1:0] rbin_next;
    logic [PTR_W-1:0] rgray_next;
    logic [PTR_W-1:0] wgray_c;

    assign rd_accept  = rd_valid && rd_ready;
    assign rbin_next  = rbin + (rd_accept ? 1 : 0);
    assign rgray_next = bin2gray(rbin_next);
    assign wgray_c    = wgray_sync[SYNC_STAGES-1];

    assign rd_valid   = ~empty_r;
    assign rd_data    = mem[rbin[LOG_DEPTH-1:0]];

    always_ff @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            rbin    <= '0;
            rgray   <= '0;
            empty_r <= 1'b1;
            for (int i = 0; i < SYNC_STAGES; i++)
                wgray_sync[i] <= '0;
        end else begin
            // synchronise write Gray pointer into read domain
            wgray_sync[0] <= wgray;
            for (int i = 1; i < SYNC_STAGES; i++)
                wgray_sync[i] <= wgray_sync[i-1];

            rbin  <= rbin_next;
            rgray <= rgray_next;

            // empty when the next read Gray pointer equals the synchronised
            // write Gray pointer
            empty_r <= (rgray_next == wgray_c);
        end
    end

endmodule
