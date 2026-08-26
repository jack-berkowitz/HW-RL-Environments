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

    localparam int DEPTH = (1 << LOG_DEPTH);
    localparam int PTR_W = LOG_DEPTH + 1;

    logic [DATA_W-1:0] mem [0:DEPTH-1];

    logic [PTR_W-1:0] wr_bin_q;
    logic [PTR_W-1:0] wr_gray_q;
    logic [PTR_W-1:0] wr_bin_next;
    logic [PTR_W-1:0] wr_gray_next;
    logic             wr_full_q;
    logic             wr_full_next;
    logic             wr_fire;

    logic [PTR_W-1:0] rd_bin_q;
    logic [PTR_W-1:0] rd_gray_q;
    logic [PTR_W-1:0] rd_bin_next;
    logic [PTR_W-1:0] rd_gray_next;
    logic             rd_empty_q;
    logic             rd_empty_next;
    logic             rd_fire;

    (* async_reg = "true" *)
    logic [PTR_W-1:0] rd_gray_sync_q [0:SYNC_STAGES-1];

    (* async_reg = "true" *)
    logic [PTR_W-1:0] wr_gray_sync_q [0:SYNC_STAGES-1];

    function automatic logic [PTR_W-1:0] bin_to_gray(
        input logic [PTR_W-1:0] value
    );
        begin
            bin_to_gray = (value >> 1) ^ value;
        end
    endfunction

    // ------------------------------------------------------------------------
    // Write domain
    // ------------------------------------------------------------------------
    always_comb begin
        wr_ready = wr_rst_n && !wr_full_q;
        wr_fire  = wr_valid && wr_ready;

        wr_bin_next = wr_bin_q;

        if (wr_fire) begin
            wr_bin_next =
                wr_bin_q + {{(PTR_W-1){1'b0}}, 1'b1};
        end

        wr_gray_next = bin_to_gray(wr_bin_next);

        // Full when the next write pointer is one complete FIFO depth
        // ahead of the synchronized read pointer.
        wr_full_next =
            (wr_gray_next ==
             {~rd_gray_sync_q[SYNC_STAGES-1][PTR_W-1:PTR_W-2],
               rd_gray_sync_q[SYNC_STAGES-1][PTR_W-3:0]});
    end

    // ------------------------------------------------------------------------
    // Read domain
    // ------------------------------------------------------------------------
    always_comb begin
        rd_valid = rd_rst_n && !rd_empty_q;
        rd_fire  = rd_valid && rd_ready;

        rd_bin_next = rd_bin_q;

        if (rd_fire) begin
            rd_bin_next =
                rd_bin_q + {{(PTR_W-1){1'b0}}, 1'b1};
        end

        rd_gray_next = bin_to_gray(rd_bin_next);

        rd_empty_next =
            (rd_gray_next ==
             wr_gray_sync_q[SYNC_STAGES-1]);

        // Payload does not cross through synchronizers.  It is safe because
        // rd_valid cannot assert until the covering write pointer has crossed
        // the complete synchronization chain.
        rd_data = mem[rd_bin_q[LOG_DEPTH-1:0]];
    end

    // ------------------------------------------------------------------------
    // Write pointer and FIFO storage
    // ------------------------------------------------------------------------
    always_ff @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) begin
            wr_bin_q  <= '0;
            wr_gray_q <= '0;
            wr_full_q <= 1'b0;
        end
        else begin
            wr_bin_q  <= wr_bin_next;
            wr_gray_q <= wr_gray_next;
            wr_full_q <= wr_full_next;

            if (wr_fire) begin
                mem[wr_bin_q[LOG_DEPTH-1:0]] <= wr_data;
            end
        end
    end

    // ------------------------------------------------------------------------
    // Read pointer
    // ------------------------------------------------------------------------
    always_ff @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            rd_bin_q   <= '0;
            rd_gray_q  <= '0;
            rd_empty_q <= 1'b1;
        end
        else begin
            rd_bin_q   <= rd_bin_next;
            rd_gray_q  <= rd_gray_next;
            rd_empty_q <= rd_empty_next;
        end
    end

    // ------------------------------------------------------------------------
    // Read pointer -> write domain synchronizer
    // ------------------------------------------------------------------------
    always_ff @(posedge wr_clk or negedge wr_rst_n) begin : sync_rd_to_wr
        integer i;

        if (!wr_rst_n) begin
            for (i = 0; i < SYNC_STAGES; i = i + 1) begin
                rd_gray_sync_q[i] <= '0;
            end
        end
        else begin
            rd_gray_sync_q[0] <= rd_gray_q;

            for (i = 1; i < SYNC_STAGES; i = i + 1) begin
                rd_gray_sync_q[i] <= rd_gray_sync_q[i-1];
            end
        end
    end

    // ------------------------------------------------------------------------
    // Write pointer -> read domain synchronizer
    // ------------------------------------------------------------------------
    always_ff @(posedge rd_clk or negedge rd_rst_n) begin : sync_wr_to_rd
        integer i;

        if (!rd_rst_n) begin
            for (i = 0; i < SYNC_STAGES; i = i + 1) begin
                wr_gray_sync_q[i] <= '0;
            end
        end
        else begin
            wr_gray_sync_q[0] <= wr_gray_q;

            for (i = 1; i < SYNC_STAGES; i = i + 1) begin
                wr_gray_sync_q[i] <= wr_gray_sync_q[i-1];
            end
        end
    end

endmodule