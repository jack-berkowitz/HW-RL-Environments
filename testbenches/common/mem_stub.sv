// =============================================================================
// mem_stub.sv -- shared "next level" memory stub with randomizable latency
// =============================================================================
// The far side of the LSQ (module 2) and, once extended for line fills, of the
// non-blocking cache (module 4). Verification model only.
//
// Storage is a nested golden_mem instance rather than a second byte array, so
// there is exactly one implementation of sized little-endian access in the tree.
//
// LATENCY IS RANDOMIZED BY DEFAULT (MIN_LAT..MAX_LAT). That is deliberate and
// called out in the Tier-2 conventions: a fixed latency lets latency-dependent
// bugs hide behind a timing assumption the candidate happened to match. Set
// MIN_LAT == MAX_LAT for a deterministic directed test.
//
// PROTOCOL: single outstanding transaction.
//   * A request is accepted on a rising edge where req_valid && !busy.
//   * busy stays high until the response cycle.
//   * resp_valid is a ONE-CYCLE pulse. Reads return resp_rdata; writes also
//     pulse (rdata undefined) so the requester learns the store reached memory.
//   * The write is applied to storage at ACCEPT. With only one transaction in
//     flight this is indistinguishable from applying it at response, and it
//     keeps the model simple.
//
// A request arriving while busy is a PROTOCOL VIOLATION by the DUT. The stub
// does not swallow it: err_overlap latches high and err_overlap_count counts,
// so the harness can fail the candidate instead of silently mis-scoring it.
// =============================================================================

`ifndef MEM_STUB_SV
`define MEM_STUB_SV

`include "golden_mem.sv"

module mem_stub #(
    parameter int ADDR_W  = 12,
    parameter int DATA_W  = 32,
    parameter int MIN_LAT = 2,
    parameter int MAX_LAT = 6
) (
    input  logic              clk,
    input  logic              rst_n,

    input  logic              req_valid,
    input  logic [ADDR_W-1:0] req_addr,
    input  logic              req_we,
    input  logic [DATA_W-1:0] req_wdata,
    input  logic [1:0]        req_size,

    output logic              resp_valid,
    output logic [DATA_W-1:0] resp_rdata,

    output logic              busy,
    output logic              err_overlap,
    output int                err_overlap_count
);

    golden_mem #(.ADDR_W(ADDR_W), .DATA_W(DATA_W)) store ();

    int                cnt;
    logic [DATA_W-1:0] pending_rdata;

    // ---------------------------------------------------------------------
    // seed storage so an unfetched load cannot look correct by returning 0
    // ---------------------------------------------------------------------
    task automatic init_pattern(input int seed);
        store.init_pattern(seed);
    endtask

    task automatic init_zero();
        store.init_zero();
    endtask

    // read-back for end-of-test image comparison against the harness's golden
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
                    // apply writes at accept; capture reads at accept so a later
                    // write cannot retroactively change an in-flight read
                    if (req_we)
                        store.wr_sized(int'(req_addr), int'(req_size), req_wdata);
                    else
                        pending_rdata <= store.rd_sized(int'(req_addr), int'(req_size));
                    cnt  <= $urandom_range(MIN_LAT, MAX_LAT);
                    busy <= 1'b1;
                end
            end else begin
                // a second request while one is in flight breaks the contract
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
