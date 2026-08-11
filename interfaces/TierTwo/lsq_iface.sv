// =============================================================================
// lsq_iface.sv  --  PORT DEFINITION ONLY (no implementation)
// =============================================================================
// Task: implement a Load/Store Queue supporting OUT-OF-ORDER LOAD ISSUE with
//       conservative memory disambiguation and store-to-load forwarding.
//
// -----------------------------------------------------------------------------
// PARAMETERS
// -----------------------------------------------------------------------------
//   DEPTH   : number of LSQ entries (loads and stores share one slot space).
//             Legal: 8, 16, 32. Must be a power of 2.
//   ADDR_W  : byte-address width.
//   DATA_W  : data width. Fixed at 32 for the shipped harness.
//   AGE_W   : width of the monotonic age counter. Must be wide enough that it
//             does not wrap within a test (>= 16).
//   IDX_W   : DERIVED. Do not override. IDX_W = $clog2(DEPTH).
//
// -----------------------------------------------------------------------------
// SIZE ENCODING (shared with the rest of Tier 2)
// -----------------------------------------------------------------------------
//   2'b00 = 1 byte, 2'b01 = 2 bytes, 2'b10 = 4 bytes. 2'b11 is not generated.
//   Accesses are naturally aligned. Little-endian: byte 0 at the lowest address.
//   An access covers the byte range [addr, addr + nbytes).
//
//   OVERLAP      : two accesses overlap iff their byte ranges intersect.
//   EXACT MATCH  : same addr AND same size. Anything else that overlaps is a
//                  PARTIAL overlap, even if one range contains the other.
//
// -----------------------------------------------------------------------------
// AGE
// -----------------------------------------------------------------------------
//   Every allocation takes the next value of a free-running monotonic counter.
//   This age is the module's OWN ordering tag -- it is not borrowed from a ROB,
//   so the LSQ is testable standalone. Entry A is OLDER than entry B iff
//   age(A) < age(B). Ages are compared as plain unsigned integers; the counter
//   is assumed not to wrap within a run.
//
// -----------------------------------------------------------------------------
// TIMING CONTRACT
// -----------------------------------------------------------------------------
//   rst_n is ACTIVE-LOW and SYNCHRONOUS. After reset the queue is empty.
//
//   lsq_idx is COMBINATIONAL (it is the slot that an allocation this cycle would
//   take). Everything else the module drives is REGISTERED.
//
//   At most ONE allocation per cycle, presented in program order.
//   At most ONE load result per cycle.
//   At most ONE memory transaction in flight (see MEMORY INTERFACE).
//
// -----------------------------------------------------------------------------
// ALLOCATE
// -----------------------------------------------------------------------------
//   alloc_valid    : allocate one entry this cycle.
//   alloc_is_store : 1 = store, 0 = load.
//   lsq_idx        : OUTPUT, the slot being allocated this cycle.
//
//   alloc_addr_known : when 1, this entry's address is being supplied on the
//     addr_* channel IN THE SAME CYCLE as the allocation, with
//     addr_lsq_idx == lsq_idx. The entry must end that cycle both allocated and
//     address-resolved. When 0, the address arrives later on the addr_* channel.
//     This is a real case, not a hint: the testbench generates it.
//
//   THERE IS NO BACKPRESSURE OUTPUT, by design. Occupancy is externally
//   derivable (see ENTRY LIFETIME), and the testbench never allocates into a
//   full queue. Behaviour on overflow is unspecified.
//
// -----------------------------------------------------------------------------
// ADDRESS AND STORE-DATA RESOLUTION
// -----------------------------------------------------------------------------
//   addr_valid / addr_lsq_idx / addr_value / addr_size : the AGU resolving an
//     entry's address. Arrives in any order relative to program order, for loads
//     and stores alike. An entry's address resolves at most once.
//
//   store_data_valid / store_data_lsq_idx / store_data_value : the store's data
//     becoming available. Independent of, and unordered with respect to, address
//     resolution. Applies only to store entries.
//
// -----------------------------------------------------------------------------
// LOAD ISSUE LEGALITY  (conservative -- this is the heart of the module)
// -----------------------------------------------------------------------------
//   A load may produce its result ONLY WHEN EVERY OLDER STORE STILL IN THE QUEUE
//   HAS A KNOWN ADDRESS.
//
//   One older store with an unresolved address blocks the load, no matter what
//   the load's own address is and no matter what the other older stores say. No
//   memory-dependence prediction, no speculate-and-replay.
//
//   THIS IS A TIMING REQUIREMENT, NOT JUST A DATA REQUIREMENT. A load that fires
//   while an older store's address is still unknown is WRONG even if the value it
//   returns happens to be correct on that run. The testbench checks issue
//   legality separately from data correctness.
//
// -----------------------------------------------------------------------------
// FORWARDING  (exact match only)
// -----------------------------------------------------------------------------
//   Once a load is legal, consider the OLDER STORES STILL IN THE QUEUE whose
//   addresses are known and whose byte range OVERLAPS the load's. Let S be the
//   YOUNGEST of those -- the nearest older overlapping store. Then:
//
//     * no such S                      -> read memory. source = SRC_MEM.
//     * S is an EXACT match (addr+size)
//         and S's data is resolved     -> forward S's data. source = SRC_FWD.
//         and S's data is NOT resolved -> STALL until it is.
//     * S is a PARTIAL overlap         -> STALL until S leaves the queue, i.e.
//                                         until S has retired and its write has
//                                         reached memory. Then re-evaluate.
//
//   Only S matters. A load must never forward from an older store that is not
//   the nearest overlapping one, and must never merge bytes from two stores.
//
// -----------------------------------------------------------------------------
// LOAD RESULT
// -----------------------------------------------------------------------------
//   load_result_valid  : one-cycle pulse, at most one per cycle.
//   load_result_lsq_idx: the load being completed.
//   load_result_value  : the loaded value, ZERO-EXTENDED to DATA_W for sizes
//                        narrower than a word. Bytes above the access size are 0.
//   load_result_source : SRC_MEM (1'b0) or SRC_FWD (1'b1). Visibility only --
//                        it does not change the data contract, but it is checked,
//                        so it must be honest.
//
//   Every allocated load produces EXACTLY ONE result, unless it is squashed by a
//   flush first. The load's entry is freed in the cycle its result is delivered.
//
// -----------------------------------------------------------------------------
// STORE RETIRE
// -----------------------------------------------------------------------------
//   store_commit_valid / store_commit_lsq_idx : the core declaring this store
//     non-speculative. The testbench only commits stores whose address AND data
//     are already resolved, and only in program order among stores.
//
//   A committed store must then be written to memory. Its entry is freed when
//   that write COMPLETES (its mem_resp arrives) -- not when store_commit is
//   received. Until then it is still "in the queue" for forwarding and for the
//   partial-overlap stall rule above.
//
//   Committed stores must reach memory IN PROGRAM ORDER with respect to each
//   other.
//
// -----------------------------------------------------------------------------
// MEMORY INTERFACE  (single outstanding)
// -----------------------------------------------------------------------------
//   mem_req_valid / mem_req_addr / mem_req_we / mem_req_wdata / mem_req_size
//   mem_resp_valid / mem_resp_rdata
//
//   mem_req_size carries the access size using the encoding above; without it a
//   sub-word store could not be written to a byte-addressable memory.
//
//   A request is accepted by the memory on a rising edge where mem_req_valid is
//   high and no transaction is in flight. AT MOST ONE TRANSACTION MAY BE IN
//   FLIGHT: asserting mem_req_valid again before mem_resp_valid has pulsed is a
//   protocol violation and is detected by the harness.
//   mem_resp_valid is a one-cycle pulse. For reads it carries mem_resp_rdata,
//   already extracted and zero-extended for the requested size. For writes it
//   simply signals completion.
//   Memory latency is RANDOMIZED between runs and between transactions.
//
// -----------------------------------------------------------------------------
// FLUSH
// -----------------------------------------------------------------------------
//   On a rising edge with flush_valid==1, every entry whose age is STRICTLY
//   GREATER than flush_age_threshold is squashed. Entries at or below the
//   threshold survive.
//
//   A squashed load produces no result. A squashed store is discarded and must
//   NOT be written to memory -- unless its memory write was already accepted by
//   the memory before the flush, in which case that transaction completes
//   normally (it cannot be recalled) and the entry is then freed.
//   The testbench never flushes away a store that it has already committed.
//
//   A load result and a flush that squashes that same load in the same cycle:
//   the flush wins, and no result is emitted for it.
// =============================================================================

module lsq #(
    parameter int DEPTH  = 16,   // 8 / 16 / 32, power of 2
    parameter int ADDR_W = 10,
    parameter int DATA_W = 32,
    parameter int AGE_W  = 16,
    // derived -- do not override
    parameter int IDX_W  = $clog2(DEPTH)
) (
    input  logic                clk,
    input  logic                rst_n,

    // ---- allocate (one per cycle, program order) ----
    input  logic                alloc_valid,
    input  logic                alloc_is_store,
    input  logic                alloc_addr_known,
    output logic [IDX_W-1:0]    lsq_idx,

    // ---- address resolution (from AGU / execute) ----
    input  logic                addr_valid,
    input  logic [IDX_W-1:0]    addr_lsq_idx,
    input  logic [ADDR_W-1:0]   addr_value,
    input  logic [1:0]          addr_size,

    // ---- store data resolution ----
    input  logic                store_data_valid,
    input  logic [IDX_W-1:0]    store_data_lsq_idx,
    input  logic [DATA_W-1:0]   store_data_value,

    // ---- load result (LSQ-internally triggered once legal) ----
    output logic                load_result_valid,
    output logic [IDX_W-1:0]    load_result_lsq_idx,
    output logic [DATA_W-1:0]   load_result_value,
    output logic                load_result_source,   // 0 = memory, 1 = forwarded

    // ---- memory interface (single outstanding) ----
    output logic                mem_req_valid,
    output logic [ADDR_W-1:0]   mem_req_addr,
    output logic                mem_req_we,
    output logic [DATA_W-1:0]   mem_req_wdata,
    output logic [1:0]          mem_req_size,
    input  logic                mem_resp_valid,
    input  logic [DATA_W-1:0]   mem_resp_rdata,

    // ---- store retire ----
    input  logic                store_commit_valid,
    input  logic [IDX_W-1:0]    store_commit_lsq_idx,

    // ---- flush ----
    input  logic                flush_valid,
    input  logic [AGE_W-1:0]    flush_age_threshold
);

    // IMPLEMENTATION INTENTIONALLY OMITTED.

endmodule
