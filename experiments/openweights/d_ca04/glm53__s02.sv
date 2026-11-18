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

    localparam int PTR_W = LOG_DEPTH + 1;

    // ---------------- write domain ----------------
    logic [PTR_W-1:0] wbin_q, wbin_next;
    logic [PTR_W-1:0] wgray_q, wgray_next;
    logic             full_q;

    // read-pointer gray value resynchronised into write domain
    logic [PTR_W-1:0] rgray_wsync [SYNC_STAGES];

    // ---------------- read domain ----------------
    logic [PTR_W-1:0] rbin_q, rbin_next;
    logic [PTR_W-1:0] rgray_q, rgray_next;
    logic             empty_q;

    // write-pointer gray value resynchronised into read domain
    logic [PTR_W-1:0] wgray_rsync [SYNC_STAGES];

    // ---------------- storage ----------------
    logic [DATA_W-1:0] mem [0:(1<<LOG_DEPTH)-1];

    // gray encode helper
    function automatic logic [PTR_W-1:0] bin2gray(
        input logic [PTR_W-1:0] b
    );
        bin2gray = b ^ (b >> 1);
    endfunction

    // ================= write domain logic =================
    always_comb begin
        wbin_next  = wbin_q + PTR_W'(wr_valid && !full_q);
        wgray_next = bin2gray(wbin_next);
    end

    always_ff @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) begin
            wbin_q  <= '0;
            wgray_q <= '0;
            full_q  <= 1'b0;
            for (int i = 0; i < SYNC_STAGES; i++)
                rgray_wsync[i] <= '0;
        end else begin
            wbin_q  <= wbin_next;
            wgray_q <= wgray_next;
            full_q  <= (wgray_next[PTR_W-1:PTR_W-2] ==
                        ~rgray_wsync[SYNC_STAGES-1][PTR_W-1:PTR_W-2]) &&
                       (wgray_next[PTR_W-3:0] ==
                        rgray_wsync[SYNC_STAGES-1][PTR_W-3:0]);
            rgray_wsync[0] <= rgray_q;
            for (int i = 1; i < SYNC_STAGES; i++)
                rgray_wsync[i] <= rgray_wsync[i-1];
            if (wr_valid && !full_q)
                mem[wbin_q[LOG_DEPTH-1:0]] <= wr_data;
        end
    end

    assign wr_ready = ~full_q;   // registered, no comb dependence on wr_valid

    // ================= read domain logic =================
    always_comb begin
        rbin_next  = rbin_q + PTR_W'(rd_ready && !empty_q);
        rgray_next = bin2gray(rbin_next);
    end

    always_ff @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            rbin_q  <= '0;
            rgray_q <= '0;
            empty_q <= 1'b1;
            for (int i = 0; i < SYNC_STAGES; i++)
                wgray_rsync[i] <= '0;
        end else begin
            rbin_q  <= rbin_next;
            rgray_q <= rgray_next;
            empty_q <= (rgray_next == wgray_rsync[SYNC_STAGES-1]);
            wgray_rsync[0] <= wgray_q;
            for (int i = 1; i < SYNC_STAGES; i++)
                wgray_rsync[i] <= wgray_rsync[i-1];
        end
    end

    assign rd_valid = ~empty_q;
    assign rd_data  = mem[rbin_q[LOG_DEPTH-1:0]];

endmodule
