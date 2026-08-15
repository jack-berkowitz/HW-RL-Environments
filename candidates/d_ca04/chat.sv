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

    localparam int DEPTH = (1 << LOG_DEPTH);

    // One extra pointer bit is required to distinguish full from empty.
    localparam int PTR_W = LOG_DEPTH + 1;


    // -------------------------------------------------------------------------
    // Payload storage
    //
    // Written only in wr_clk domain.
    // Read using the current read pointer in rd_clk domain.
    //
    // The data itself does not pass through synchronizers. The synchronized
    // write pointer guarantees that an entry has been stable before rd_valid
    // can assert for it.
    // -------------------------------------------------------------------------

    logic [DATA_W-1:0] mem [0:DEPTH-1];


    // -------------------------------------------------------------------------
    // Write-domain pointers
    // -------------------------------------------------------------------------

    logic [PTR_W-1:0] wr_bin;
    logic [PTR_W-1:0] wr_bin_next;

    logic [PTR_W-1:0] wr_gray;
    logic [PTR_W-1:0] wr_gray_next;

    logic             wr_full;
    logic             wr_full_next;

    logic             wr_fire;


    // -------------------------------------------------------------------------
    // Read-domain pointers
    // -------------------------------------------------------------------------

    logic [PTR_W-1:0] rd_bin;
    logic [PTR_W-1:0] rd_bin_next;

    logic [PTR_W-1:0] rd_gray;
    logic [PTR_W-1:0] rd_gray_next;

    logic             rd_empty;
    logic             rd_empty_next;

    logic             rd_fire;


    // -------------------------------------------------------------------------
    // CDC synchronizers
    //
    // wr_gray crosses into rd_clk domain.
    // rd_gray crosses into wr_clk domain.
    //
    // Only the final synchronizer stage is used by FIFO control logic.
    // -------------------------------------------------------------------------

    (* ASYNC_REG = "TRUE" *)
    logic [PTR_W-1:0] wr_gray_sync [0:SYNC_STAGES-1];

    (* ASYNC_REG = "TRUE" *)
    logic [PTR_W-1:0] rd_gray_sync [0:SYNC_STAGES-1];

    integer k;


    // -------------------------------------------------------------------------
    // Write pointer -> read domain synchronizer
    // -------------------------------------------------------------------------

    always_ff @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            for (k = 0; k < SYNC_STAGES; k = k + 1)
                wr_gray_sync[k] <= '0;
        end
        else begin
            wr_gray_sync[0] <= wr_gray;

            for (k = 1; k < SYNC_STAGES; k = k + 1)
                wr_gray_sync[k] <= wr_gray_sync[k-1];
        end
    end


    // -------------------------------------------------------------------------
    // Read pointer -> write domain synchronizer
    // -------------------------------------------------------------------------

    always_ff @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) begin
            for (k = 0; k < SYNC_STAGES; k = k + 1)
                rd_gray_sync[k] <= '0;
        end
        else begin
            rd_gray_sync[0] <= rd_gray;

            for (k = 1; k < SYNC_STAGES; k = k + 1)
                rd_gray_sync[k] <= rd_gray_sync[k-1];
        end
    end


    // -------------------------------------------------------------------------
    // Handshake outputs
    //
    // wr_ready depends only on registered write-domain state.
    // rd_valid depends only on registered read-domain state.
    //
    // Therefore:
    //   wr_ready does not depend combinationally on wr_valid
    //   rd_valid does not depend combinationally on rd_ready
    // -------------------------------------------------------------------------

    assign wr_ready = wr_rst_n && !wr_full;
    assign rd_valid = rd_rst_n && !rd_empty;

    assign wr_fire = wr_valid && wr_ready;
    assign rd_fire = rd_valid && rd_ready;


    // -------------------------------------------------------------------------
    // Write-domain next pointer
    // -------------------------------------------------------------------------

    always_comb begin
        wr_bin_next = wr_bin;

        if (wr_fire)
            wr_bin_next = wr_bin + {{(PTR_W-1){1'b0}}, 1'b1};

        // Binary -> reflected Gray:
        //
        //     gray = binary ^ (binary >> 1)
        //
        wr_gray_next = (wr_bin_next >> 1) ^ wr_bin_next;
    end


    // -------------------------------------------------------------------------
    // Full detection
    //
    // For a power-of-two asynchronous FIFO, the FIFO is full when the NEXT
    // write Gray pointer equals the synchronized read Gray pointer with its
    // upper two bits inverted.
    //
    // Example for PTR_W == 4:
    //
    //     wr_gray_next ==
    //         { ~rd_gray_sync[3:2],
    //            rd_gray_sync[1:0] }
    //
    // This is the standard Gray-pointer full test.
    // -------------------------------------------------------------------------

    always_comb begin
        wr_full_next =
            (wr_gray_next ==
                {
                    ~rd_gray_sync[SYNC_STAGES-1][PTR_W-1:PTR_W-2],
                     rd_gray_sync[SYNC_STAGES-1][PTR_W-3:0]
                });
    end


    // -------------------------------------------------------------------------
    // Write-domain state and memory write
    // -------------------------------------------------------------------------

    always_ff @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) begin
            wr_bin  <= '0;
            wr_gray <= '0;
            wr_full <= 1'b0;
        end
        else begin
            wr_bin  <= wr_bin_next;
            wr_gray <= wr_gray_next;
            wr_full <= wr_full_next;

            if (wr_fire)
                mem[wr_bin[LOG_DEPTH-1:0]] <= wr_data;
        end
    end


    // -------------------------------------------------------------------------
    // Read-domain next pointer
    // -------------------------------------------------------------------------

    always_comb begin
        rd_bin_next = rd_bin;

        if (rd_fire)
            rd_bin_next = rd_bin + {{(PTR_W-1){1'b0}}, 1'b1};

        rd_gray_next = (rd_bin_next >> 1) ^ rd_bin_next;
    end


    // -------------------------------------------------------------------------
    // Empty detection
    //
    // Empty when the NEXT read pointer equals the synchronized write pointer.
    //
    // Notice that only wr_gray_sync[SYNC_STAGES-1] is used here. An
    // unsynchronized or partially synchronized write pointer is never used to
    // assert availability.
    // -------------------------------------------------------------------------

    always_comb begin
        rd_empty_next =
            (rd_gray_next == wr_gray_sync[SYNC_STAGES-1]);
    end


    // -------------------------------------------------------------------------
    // Read-domain pointer / empty state
    // -------------------------------------------------------------------------

    always_ff @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            rd_bin   <= '0;
            rd_gray  <= '0;
            rd_empty <= 1'b1;
        end
        else begin
            rd_bin   <= rd_bin_next;
            rd_gray  <= rd_gray_next;
            rd_empty <= rd_empty_next;
        end
    end


    // -------------------------------------------------------------------------
    // Payload read
    //
    // rd_bin does not advance while rd_valid && !rd_ready, so the addressed
    // memory location remains unchanged.
    //
    // The write side cannot overwrite this unread location because wr_full is
    // calculated using the safely synchronized read pointer. Consequently
    // rd_data is stable for the entire duration of read-side backpressure.
    // -------------------------------------------------------------------------

    assign rd_data = mem[rd_bin[LOG_DEPTH-1:0]];

endmodule