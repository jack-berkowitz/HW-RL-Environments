// =============================================================================
// ncache_iface.sv  --  PORT DEFINITION ONLY (no implementation)
// =============================================================================
// Task: implement a dual-port, NON-BLOCKING, set-associative write-back L1 with
//       MSHR miss merging and a fully-associative victim cache.
//
// Graded in TWO TIERS, like the branch predictor: data correctness and protocol
// legality are PASS/FAIL; hit rate is an informational score. Replacement policy
// is NOT graded.
//
// -----------------------------------------------------------------------------
// PARAMETERS
// -----------------------------------------------------------------------------
//   ADDR_W     : byte-address width. Default 10 (a deliberately tiny space, so
//                conflicts, evictions and victim hits happen constantly).
//   DATA_W     : scalar access width. Fixed at 32.
//   LINE_BYTES : line size. Default 4. (Was 8 -- see SIZING NOTE.)
//   SETS       : sets in the main array. Default 4.
//   WAYS       : associativity. Default 2.
//   MSHRS      : outstanding misses tracked. Default 2.
//   VICTIM_ENT : victim cache entries, fully associative. Default 2.
//   TAG_W      : width of the opaque request tag. Default 4.
//   LINE_W     : DERIVED. 8*LINE_BYTES.
//
//   Address split: offset = addr[$clog2(LINE_BYTES)-1:0]
//                  set    = addr[$clog2(LINE_BYTES) +: $clog2(SETS)]
//                  tag    = the bits above that
//
//   SIZE ENCODING (shared with the rest of Tier 2):
//     2'b00 = 1 byte, 2'b01 = 2 bytes, 2'b10 = 4 bytes. Naturally aligned,
//     little-endian. An access never crosses a line boundary.
//
// -----------------------------------------------------------------------------
// REQUEST / RESPONSE  (two symmetric ports, A and B)
// -----------------------------------------------------------------------------
//   A request is ACCEPTED on a rising edge where req_valid && req_ready.
//   req_ready may be withdrawn (MSHRs full and no merge target, etc.).
//
//   req_tag is OPAQUE and is returned unmodified in the response. It exists
//   because RESPONSES MAY RETURN OUT OF ORDER relative to requests -- a hit
//   behind an outstanding miss may answer first, and misses to different lines
//   complete in fill order. The testbench guarantees that all tags outstanding
//   at any moment are distinct, across BOTH ports.
//
//   EXACTLY ONE response per accepted request, on the SAME port, carrying that
//   request's tag. resp_rdata is the loaded value for a read, ZERO-EXTENDED to
//   DATA_W; it is DON'T CARE for a write. resp_hit is INFORMATIONAL only -- it
//   feeds the hit-rate score and is never a pass/fail condition.
//
//   ORDERING AND VISIBILITY (this is the part that must be exact):
//     * An accepted write becomes architecturally visible AT ITS ACCEPT EDGE.
//     * An accepted read returns the value as of ITS OWN ACCEPT EDGE, however
//       long its response takes. A write accepted later must NOT be visible to
//       an earlier-accepted read.
//     * Within one cycle, PORT A IS ORDERED BEFORE PORT B. So if both ports are
//       accepted in the same cycle and their byte ranges overlap, B sees A's
//       write. This is the fixed Port-A > Port-B priority, stated as an
//       ordering rule so it is checkable rather than only a conflict-resolution
//       hint.
//
// -----------------------------------------------------------------------------
// NON-BLOCKING BEHAVIOUR AND MSHRs
// -----------------------------------------------------------------------------
//   A miss allocates an MSHR and the cache CONTINUES ACCEPTING requests.
//
//   SECONDARY MISS MERGING (graded): a miss to a line that an in-flight MSHR
//   already covers MUST merge into that MSHR. It must NOT issue a second fill
//   for the same line. Both requesters are satisfied when the single fill
//   returns. Issuing a duplicate fill for a line already in flight is a
//   protocol violation and is detected.
//
//   When no MSHR is free and the miss cannot merge, the port must deassert
//   req_ready rather than drop or reorder the request.
//
// -----------------------------------------------------------------------------
// VICTIM CACHE
// -----------------------------------------------------------------------------
//   A line evicted from the main array is placed in the fully-associative
//   victim buffer. A subsequent miss that HITS in the victim buffer must swap
//   that line back into the main array WITHOUT a memory fill.
//
//   Whether a given access hits in the victim buffer is a consequence of the
//   replacement policy and is therefore NOT graded directly. What is graded:
//   the data must be right, and a victim hit must not fabricate a memory read.
//
// -----------------------------------------------------------------------------
// WRITE POLICY
// -----------------------------------------------------------------------------
//   WRITE-ALLOCATE, WRITE-BACK. A store miss fills the line, then merges the
//   store into it. A line is dirty once written.
//
//   A DIRTY LINE MAY NEVER BE DISCARDED WITHOUT A WRITEBACK. When a dirty line
//   leaves the cache hierarchy (evicted from the main array and then displaced
//   from the victim buffer), its data must reach memory. Silently dropping it
//   loses a write, and the harness compares the final memory image against a
//   golden model byte for byte.
//
// -----------------------------------------------------------------------------
// NEXT-LEVEL MEMORY  (single outstanding, line granular, no tag)
// -----------------------------------------------------------------------------
//   mem_req_valid / mem_req_addr / mem_req_we / mem_req_wdata (a full LINE_W
//   line, used for both fills and writebacks) / mem_resp_valid / mem_resp_rdata.
//
//   AT MOST ONE MEMORY TRANSACTION IN FLIGHT. There is no tag on this
//   interface, so responses are necessarily in order; asserting mem_req_valid
//   again before mem_resp_valid has pulsed is a protocol violation and is
//   detected by the harness. Multiple MSHRs therefore track multiple misses,
//   but their FILLS are serialised -- the non-blocking behaviour that matters
//   is on the CPU side.
//
//   Fill latency is randomised per transaction.
//
// -----------------------------------------------------------------------------
// RESET
// -----------------------------------------------------------------------------
//   rst_n is ACTIVE-LOW and SYNCHRONOUS. After reset every main-array line and
//   every victim entry is invalid, no MSHR is allocated, both ports are ready,
//   and there is no memory transaction in flight.
//
// -----------------------------------------------------------------------------
// GRADING
// -----------------------------------------------------------------------------
//   TIER 1, PASS/FAIL: response data, tag correctness, exactly-one-response,
//     no duplicate fill for an in-flight line, no lost dirty data, memory
//     protocol legality.
//   TIER 2, INFORMATIONAL: hit rate, victim-cache hit rate, fill count.
//     Replacement choice is not graded and a low hit rate never fails.
// =============================================================================
//
// SIZING NOTE (why these defaults are small)
//   The geometry below is chosen so the design still contains every hazard the
//   module exists to test -- MSHR merging, backpressure when none is free,
//   eviction, a dirty writeback, a victim hit, dual-port same-line conflict --
//   while staying small enough to synthesise and place-and-route in a sane time.
//   The earlier 16-byte / 8-set / 4-way / PQ-8 version unrolled the merged-drain
//   logic MSHRS x (PQ+1) = 36 times over a 128-bit line and pushed Yosys past
//   4 GB. Halving the line and cutting the queues gives ~7x less of that logic.
//   Note 2 MSHRs and 2 victim entries exercise the "none free" paths MORE often
//   than 4 did, so this is not a weaker test -- just a cheaper one.
//
//   SECOND DOWNSIZING: LINE_BYTES 8 -> 4. A correct, congestion-free
//   implementation still took ~19.5 h in detailed routing at 8 bytes, and
//   LINE_W dominates this design -- the line arrays (main + victim + MSHR +
//   writeback) hold most of its flops, and every byte-merge / byte-extract
//   datapath is LINE_W wide and replicated per port and per drain path.
//
//   IMPORTANT, IF YOU CHANGE LINE_BYTES AGAIN: the testbench stimulus must move
//   with it. ncache_tb.sv used to hardcode a 32-byte set stride and 4-byte
//   intra-line offsets, both of which silently assumed LINE_BYTES==8. Flipping
//   the parameter alone made "base" and "base+4" different lines, which turned
//   the two MSHR-merge directed tests into ordinary misses and doubled the
//   working set: hit rate fell 87.9% -> 42.4% and the run failed the coverage
//   gate below with 3945 graded events. That was the STIMULUS breaking, not the
//   geometry. The stride and offsets are now derived (SETSTRIDE / HALF_OFF /
//   HALF_SZ), and with them matched the 4-byte line costs 2.5 points of hit rate
//   and nothing else: 13592 graded events vs 13208, identical dual-accept,
//   same-line and read/write-overlap counts, both merge and victim scenarios
//   still covered.
//
//   PPA numbers taken at LINE_BYTES=8 are NOT comparable to numbers taken here.
// =============================================================================

module ncache #(
    parameter int ADDR_W     = 10,
    parameter int DATA_W     = 32,
    parameter int LINE_BYTES = 4,
    parameter int SETS       = 4,
    parameter int WAYS       = 2,
    parameter int MSHRS      = 2,
    parameter int VICTIM_ENT = 2,
    parameter int TAG_W      = 4,
    // derived -- do not override
    parameter int LINE_W     = 8*LINE_BYTES
) (
    input  logic                clk,
    input  logic                rst_n,

    // ---- port A ----
    input  logic                A_req_valid,
    input  logic [ADDR_W-1:0]   A_req_addr,
    input  logic                A_req_we,
    input  logic [DATA_W-1:0]   A_req_wdata,
    input  logic [1:0]          A_req_size,
    input  logic [TAG_W-1:0]    A_req_tag,
    output logic                A_req_ready,
    output logic                A_resp_valid,
    output logic [TAG_W-1:0]    A_resp_tag,
    output logic [DATA_W-1:0]   A_resp_rdata,
    output logic                A_resp_hit,        // informational only

    // ---- port B ----
    input  logic                B_req_valid,
    input  logic [ADDR_W-1:0]   B_req_addr,
    input  logic                B_req_we,
    input  logic [DATA_W-1:0]   B_req_wdata,
    input  logic [1:0]          B_req_size,
    input  logic [TAG_W-1:0]    B_req_tag,
    output logic                B_req_ready,
    output logic                B_resp_valid,
    output logic [TAG_W-1:0]    B_resp_tag,
    output logic [DATA_W-1:0]   B_resp_rdata,
    output logic                B_resp_hit,        // informational only

    // ---- next-level memory (single outstanding, line granular) ----
    output logic                mem_req_valid,
    output logic [ADDR_W-1:0]   mem_req_addr,
    output logic                mem_req_we,
    output logic [LINE_W-1:0]   mem_req_wdata,
    input  logic                mem_resp_valid,
    input  logic [LINE_W-1:0]   mem_resp_rdata
);

    // IMPLEMENTATION INTENTIONALLY OMITTED.

endmodule
