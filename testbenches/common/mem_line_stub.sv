// =============================================================================
// mem_line_stub.sv -- shared LINE-GRANULAR next-level memory stub
// =============================================================================
// The far side of the non-blocking cache (module 4) and of the shared bus in the
// coherence harness (module 5). `mem_stub.sv` stays as-is for the LSQ's scalar,
// sized interface; this is the line-wide sibling rather than a second mode
// bolted onto it, so neither harness can perturb the other.
//
// Storage is a nested golden_mem instance, so there is still exactly one
// implementation of the byte array in the tree.
//
// PROTOCOL: single outstanding transaction, no tag.
//   * accepted on a rising edge where req_valid && !busy
//   * resp_valid is a ONE-CYCLE pulse; reads return the whole line, writes
//     simply signal completion
//   * writes are applied at ACCEPT (indistinguishable from apply-at-response
//     with only one transaction in flight)
//   * latency is RANDOMIZED in [MIN_LAT, MAX_LAT] so fill-latency-dependent
//     bugs cannot hide behind a fixed timing assumption
//
// A request arriving while busy is a PROTOCOL VIOLATION by the DUT and is
// LATCHED (err_overlap / err_overlap_count) rather than swallowed.
//
// req_addr is a byte address; the LINE_BYTES-aligned line containing it is the
// unit of transfer. Unaligned bits are ignored, not an error.
// =============================================================================

`ifndef MEM_LINE_STUB_SV
`define MEM_LINE_STUB_SV

`include "golden_mem.sv"

module mem_line_stub #(
    parameter int ADDR_W     = 10,
    parameter int LINE_BYTES = 16,
    parameter int MIN_LAT    = 3,
    parameter int MAX_LAT    = 9
) (
    input  logic                       clk,
    input  logic                       rst_n,

    input  logic                       req_valid,
    input  logic [ADDR_W-1:0]          req_addr,
    input  logic                       req_we,
    input  logic [8*LINE_BYTES-1:0]    req_wdata,

    output logic                       resp_valid,
    output logic [8*LINE_BYTES-1:0]    resp_rdata,

    output logic                       busy,
    output logic                       err_overlap,
    output int                         err_overlap_count
);

    localparam int LINE_W = 8*LINE_BYTES;

    golden_mem #(.ADDR_W(ADDR_W), .LINE_BYTES(LINE_BYTES)) store ();

    int                cnt;
    logic [LINE_W-1:0] pending_rdata;

    function automatic int line_base(input logic [ADDR_W-1:0] a);
        return int'(a) & ~(LINE_BYTES - 1);
    endfunction

    task automatic init_pattern(input int seed);
        store.init_pattern(seed);
    endtask

    function automatic logic [7:0] peek_byte(input int a);
        return store.rd_byte(a);
    endfunction

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            busy              <= 1'b0;
            resp_valid        <= 1'b0;
            cnt               <= 0;
            err_overlap       <= 1'b0;
            err_overlap_count <= 0;
        end else begin
            resp_valid <= 1'b0;

            if (!busy) begin
                if (req_valid) begin
                    if (req_we) store.wr_line(line_base(req_addr), req_wdata);
                    else        pending_rdata <= store.rd_line(line_base(req_addr));
                    cnt  <= $urandom_range(MIN_LAT, MAX_LAT);
                    busy <= 1'b1;
                end
            end else begin
                if (req_valid) begin
                    err_overlap       <= 1'b1;
                    err_overlap_count <= err_overlap_count + 1;
                end
                if (cnt <= 1) begin
                    busy       <= 1'b0;
                    resp_valid <= 1'b1;
                end else begin
                    cnt <= cnt - 1;
                end
            end
        end
    end

    assign resp_rdata = pending_rdata;

endmodule

`endif
