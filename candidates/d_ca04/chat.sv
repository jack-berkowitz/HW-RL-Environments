module async_fifo_cdc #(
    parameter int DATA_W      = 32,   // 8 / 32 / 64
    parameter int LOG_DEPTH   = 3,    // 2 / 3 / 4
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

    localparam int DEPTH = (1 << LOG_DEPTH);
    localparam int PTR_W = LOG_DEPTH + 1;

    /*
     * FIFO storage.
     *
     * The payload itself does not pass through synchronizer flops.
     * The write pointer crosses safely before the read domain is
     * allowed to access the corresponding entry.
     */
    logic [DATA_W-1:0] mem [0:DEPTH-1];

    /*
     * Local binary pointers.
     *
     * The low LOG_DEPTH bits select the memory entry.
     * The extra MSB distinguishes different wraps around the FIFO.
     */
    logic [PTR_W-1:0] wr_bin_q;
    logic [PTR_W-1:0] rd_bin_q;

    /*
     * Gray-coded versions of the pointers are the ONLY pointer
     * representations allowed to cross the clock-domain boundary.
     */
    logic [PTR_W-1:0] wr_gray_q;
    logic [PTR_W-1:0] rd_gray_q;

    /*
     * Synchronizer pipelines.
     *
     * Their dimensions deliberately depend directly on SYNC_STAGES.
     * Therefore SYNC_STAGES=3 really gives three receiving-domain
     * flip-flops rather than a hard-coded two-stage synchronizer.
     */
    logic [PTR_W-1:0] rd_gray_sync_q [0:SYNC_STAGES-1];
    logic [PTR_W-1:0] wr_gray_sync_q [0:SYNC_STAGES-1];

    logic [PTR_W-1:0] wr_bin_next;
    logic [PTR_W-1:0] wr_gray_next;

    logic [PTR_W-1:0] rd_bin_next;
    logic [PTR_W-1:0] rd_gray_next;

    logic wr_full;
    logic rd_empty;

    logic wr_fire;
    logic rd_fire;

    integer wr_sync_i;
    integer rd_sync_i;


    /*
     * ------------------------------------------------------------------------
     * Binary -> Gray conversion
     * ------------------------------------------------------------------------
     */
    function automatic logic [PTR_W-1:0] bin_to_gray(
        input logic [PTR_W-1:0] bin
    );
        begin
            bin_to_gray = (bin >> 1) ^ bin;
        end
    endfunction


    /*
     * ------------------------------------------------------------------------
     * Gray value corresponding to "one complete FIFO depth ahead"
     * ------------------------------------------------------------------------
     *
     * For an asynchronous FIFO with an extra wrap bit, the full condition
     * is obtained by comparing the current write Gray pointer against the
     * synchronized read pointer with its two most-significant Gray bits
     * inverted.
     *
     * Example for depth 8:
     *
     *     read binary  = 0000 -> Gray 0000
     *     write binary = 1000 -> Gray 1100
     *
     * so inversion of the top two bits gives the full-point value.
     */
    function automatic logic [PTR_W-1:0] full_compare_gray(
        input logic [PTR_W-1:0] gray
    );
        logic [PTR_W-1:0] tmp;

        begin
            tmp = gray;

            tmp[PTR_W-1] = ~gray[PTR_W-1];
            tmp[PTR_W-2] = ~gray[PTR_W-2];

            full_compare_gray = tmp;
        end
    endfunction


    /*
     * ========================================================================
     * WRITE DOMAIN COMBINATIONAL LOGIC
     * ========================================================================
     *
     * wr_ready depends only on:
     *
     *   - the local write pointer
     *   - the safely synchronized read pointer
     *   - reset
     *
     * It does NOT depend on wr_valid, satisfying H1.
     */
    always_comb begin

        wr_full =
            (
                wr_gray_q ==
                full_compare_gray(
                    rd_gray_sync_q[SYNC_STAGES-1]
                )
            );

        wr_ready =
            wr_rst_n &&
            !wr_full;

        wr_fire =
            wr_valid &&
            wr_ready;

        wr_bin_next =
            wr_bin_q +
            {{(PTR_W-1){1'b0}}, wr_fire};

        wr_gray_next =
            bin_to_gray(wr_bin_next);

    end


    /*
     * ========================================================================
     * READ DOMAIN COMBINATIONAL LOGIC
     * ========================================================================
     *
     * rd_valid depends only on:
     *
     *   - the local read pointer
     *   - the safely synchronized write pointer
     *   - reset
     *
     * It does NOT depend on rd_ready.
     */
    always_comb begin

        rd_empty =
            (
                rd_gray_q ==
                wr_gray_sync_q[SYNC_STAGES-1]
            );

        rd_valid =
            rd_rst_n &&
            !rd_empty;

        rd_fire =
            rd_valid &&
            rd_ready;

        rd_bin_next =
            rd_bin_q +
            {{(PTR_W-1){1'b0}}, rd_fire};

        rd_gray_next =
            bin_to_gray(rd_bin_next);

        /*
         * rd_bin_q does not advance while rd_ready is low.
         *
         * Therefore when rd_valid=1 and rd_ready=0, this address is
         * unchanged and rd_data remains stable.
         */
        if (rd_rst_n)
            rd_data = mem[rd_bin_q[LOG_DEPTH-1:0]];
        else
            rd_data = '0;

    end


    /*
     * ========================================================================
     * WRITE POINTER AND STORAGE
     * ========================================================================
     */
    always_ff @(posedge wr_clk or negedge wr_rst_n) begin

        if (!wr_rst_n) begin

            wr_bin_q  <= '0;
            wr_gray_q <= '0;

        end
        else begin

            wr_bin_q  <= wr_bin_next;
            wr_gray_q <= wr_gray_next;

            /*
             * Memory changes only when a write beat is actually accepted.
             */
            if (wr_fire)
                mem[wr_bin_q[LOG_DEPTH-1:0]] <= wr_data;

        end

    end


    /*
     * ========================================================================
     * READ POINTER
     * ========================================================================
     */
    always_ff @(posedge rd_clk or negedge rd_rst_n) begin

        if (!rd_rst_n) begin

            rd_bin_q  <= '0;
            rd_gray_q <= '0;

        end
        else begin

            rd_bin_q  <= rd_bin_next;
            rd_gray_q <= rd_gray_next;

        end

    end


    /*
     * ========================================================================
     * READ POINTER -> WRITE CLOCK DOMAIN
     * ========================================================================
     *
     * Exactly SYNC_STAGES write-clocked synchronization registers.
     */
    always_ff @(posedge wr_clk or negedge wr_rst_n) begin

        if (!wr_rst_n) begin

            for (
                wr_sync_i = 0;
                wr_sync_i < SYNC_STAGES;
                wr_sync_i = wr_sync_i + 1
            ) begin

                rd_gray_sync_q[wr_sync_i] <= '0;

            end

        end
        else begin

            /*
             * First synchronizer stage samples the remote Gray pointer.
             */
            rd_gray_sync_q[0] <= rd_gray_q;

            /*
             * Remaining stages propagate entirely within wr_clk.
             */
            for (
                wr_sync_i = 1;
                wr_sync_i < SYNC_STAGES;
                wr_sync_i = wr_sync_i + 1
            ) begin

                rd_gray_sync_q[wr_sync_i] <=
                    rd_gray_sync_q[wr_sync_i-1];

            end

        end

    end


    /*
     * ========================================================================
     * WRITE POINTER -> READ CLOCK DOMAIN
     * ========================================================================
     *
     * Exactly SYNC_STAGES read-clocked synchronization registers.
     */
    always_ff @(posedge rd_clk or negedge rd_rst_n) begin

        if (!rd_rst_n) begin

            for (
                rd_sync_i = 0;
                rd_sync_i < SYNC_STAGES;
                rd_sync_i = rd_sync_i + 1
            ) begin

                wr_gray_sync_q[rd_sync_i] <= '0;

            end

        end
        else begin

            /*
             * First synchronizer stage samples the remote Gray pointer.
             */
            wr_gray_sync_q[0] <= wr_gray_q;

            /*
             * Remaining stages propagate entirely within rd_clk.
             */
            for (
                rd_sync_i = 1;
                rd_sync_i < SYNC_STAGES;
                rd_sync_i = rd_sync_i + 1
            ) begin

                wr_gray_sync_q[rd_sync_i] <=
                    wr_gray_sync_q[rd_sync_i-1];

            end

        end

    end

endmodule