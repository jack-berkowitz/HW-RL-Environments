// =============================================================================
// fifo.sv -- synchronous single-clock FIFO, first-word fall-through.
// Implements the interface and semantics of interfaces/fifo_iface.sv exactly.
// =============================================================================
//
// Structure: a DEPTH x DATA_WIDTH register-file storage array with independent
// write/read pointers and a separate occupancy counter. The counter (rather
// than an extra pointer MSB) is what generates full/empty, which also gives the
// almost_* thresholds a direct magnitude comparison to sit on.
//
// Commit rules (each side qualified independently by the PRE-EDGE flags):
//   write commits iff rst_n && wr_en && !full
//   read  commits iff rst_n && rd_en && !empty
// so at full a simultaneous r/w drops the write, and at empty it drops the read.
// No full-slot-freeing bypass and no write-to-read passthrough.
// =============================================================================

module fifo #(
    parameter int DEPTH               = 16,
    parameter int DATA_WIDTH          = 32,
    parameter int ALMOST_FULL_THRESH  = 12,
    parameter int ALMOST_EMPTY_THRESH = 4,
    // derived -- do not override
    parameter int CNT_W               = $clog2(DEPTH) + 1
) (
    input  logic                  clk,
    input  logic                  rst_n,

    // write port
    input  logic                  wr_en,
    input  logic [DATA_WIDTH-1:0] wr_data,

    // read port (first-word fall-through)
    input  logic                  rd_en,
    output logic [DATA_WIDTH-1:0] rd_data,

    // status
    output logic                  full,
    output logic                  empty,
    output logic                  almost_full,
    output logic                  almost_empty,
    output logic [CNT_W-1:0]      count
);

    localparam int PTR_W = $clog2(DEPTH);

    // ---------------------------------------------------------------------
    // state
    // ---------------------------------------------------------------------
    logic [DATA_WIDTH-1:0] mem [DEPTH];
    logic [PTR_W-1:0]      wr_ptr;
    logic [PTR_W-1:0]      rd_ptr;
    logic [CNT_W-1:0]      cnt;

    // ---------------------------------------------------------------------
    // combinational flags -- functions of the current (pre-edge) occupancy
    // ---------------------------------------------------------------------
    assign count        = cnt;
    assign empty        = (cnt == '0);
    assign full         = (cnt == CNT_W'(DEPTH));
    assign almost_empty = (cnt <= CNT_W'(ALMOST_EMPTY_THRESH));
    assign almost_full  = (cnt >= CNT_W'(ALMOST_FULL_THRESH));

    // commit qualifiers
    logic do_wr, do_rd;
    assign do_wr = wr_en && !full;
    assign do_rd = rd_en && !empty;

    // ---------------------------------------------------------------------
    // FWFT read data: the head entry is presented combinationally. Undefined
    // (don't care) when empty, so no empty-qualification is needed here.
    // ---------------------------------------------------------------------
    assign rd_data = mem[rd_ptr];

    // ---------------------------------------------------------------------
    // pointers and occupancy -- synchronous active-low reset
    // ---------------------------------------------------------------------
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            wr_ptr <= '0;
            rd_ptr <= '0;
            cnt    <= '0;
        end else begin
            if (do_wr)
                wr_ptr <= (wr_ptr == PTR_W'(DEPTH-1)) ? '0 : wr_ptr + PTR_W'(1);
            if (do_rd)
                rd_ptr <= (rd_ptr == PTR_W'(DEPTH-1)) ? '0 : rd_ptr + PTR_W'(1);

            // net occupancy change: +1 write-only, -1 read-only, 0 for both
            case ({do_wr, do_rd})
                2'b10:   cnt <= cnt + CNT_W'(1);
                2'b01:   cnt <= cnt - CNT_W'(1);
                default: cnt <= cnt;
            endcase
        end
    end

    // ---------------------------------------------------------------------
    // storage write port -- not reset, contents are don't-care while empty
    // ---------------------------------------------------------------------
    always_ff @(posedge clk) begin
        if (rst_n && do_wr)
            mem[wr_ptr] <= wr_data;
    end

endmodule
