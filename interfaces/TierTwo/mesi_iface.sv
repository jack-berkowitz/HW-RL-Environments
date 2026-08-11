// =============================================================================
// mesi_iface.sv  --  PORT DEFINITION ONLY (no implementation)
// =============================================================================
// Task: implement a TWO-CORE MESI-lite snooping coherence system: two private
//       blocking L1s, one shared bus, one shared memory.
//
// Scope is deliberately tight. Each L1 is SIMPLE, SINGLE-PORT and BLOCKING --
// do NOT reuse the non-blocking machinery from module 4. The difficulty here is
// the protocol, not the pipeline.
//
// -----------------------------------------------------------------------------
// STRUCTURE
// -----------------------------------------------------------------------------
//   ONE module contains both caches, the arbiter, the bus and the memory port.
//   The bus signals are exposed as OUTPUTS purely so the harness can observe
//   traffic (they are what the informational traffic score is measured from).
//
// -----------------------------------------------------------------------------
// PARAMETERS
// -----------------------------------------------------------------------------
//   ADDR_W     : byte-address width. Default 10 (small on purpose: the address
//                pool must be tiny so both cores collide constantly).
//   DATA_W     : scalar access width. Fixed at 32, naturally aligned, and an
//                access never crosses a line.
//   LINE_BYTES : line size. Default 16.
//   SETS       : per-core sets. Default 4.
//   WAYS       : per-core associativity. Default 2.
//   LINE_W     : DERIVED, 8*LINE_BYTES.
//
//   Address split: offset = addr[$clog2(LINE_BYTES)-1:0]
//                  set    = addr[$clog2(LINE_BYTES) +: $clog2(SETS)]
//                  tag    = the bits above.
//
// -----------------------------------------------------------------------------
// STATES
// -----------------------------------------------------------------------------
//   2'd0 = I (invalid)   2'd1 = S (shared)   2'd2 = E (exclusive)   2'd3 = M
//
// -----------------------------------------------------------------------------
// CPU SIDE  (per core, single-outstanding, BLOCKING)
// -----------------------------------------------------------------------------
//   The core asserts cpu_req_valid with stable addr/we/wdata and HOLDS it until
//   cpu_resp_valid pulses. The cache latches the request on the first cycle it
//   is idle. cpu_resp_valid is a ONE-CYCLE pulse; cpu_resp_rdata is the loaded
//   value for a read and DON'T CARE for a write.
//
//   THE CORE DEASSERTS cpu_req_valid IN THE SAME CYCLE IT OBSERVES
//   cpu_resp_valid. cpu_resp_valid is registered, so it is stable for the whole
//   of that cycle and the core has time to drop valid combinationally before the
//   next edge. Without this rule a cache that latches on "idle && valid" would
//   re-latch the request it has just answered and respond to it twice; with it,
//   such a design is correct. The core then leaves valid low for at least one
//   cycle before the next request.
//
//   A core has at most one request outstanding. It may not issue a second
//   request before the first has responded.
//
// -----------------------------------------------------------------------------
// PROTOCOL  (MESI-lite)
// -----------------------------------------------------------------------------
//   Served with NO bus transaction:
//     * read hit in S, E or M
//     * write hit in M
//     * write hit in E  -> SILENTLY upgrade E to M (this is the point of E)
//
//   Requiring a bus transaction:
//     * read miss (I)        -> BusRd
//     * write hit in S       -> BusUpgr   (no data needed, just ownership)
//     * write miss (I)       -> BusRdX
//
//   Bus transaction types: 2'd0 = BusRd, 2'd1 = BusRdX, 2'd2 = BusUpgr.
//
//   SNOOP RESPONSE by the peer, for the addressed line:
//     BusRd   : peer in M -> FLUSH the line and downgrade to S. The peer must
//                            NOT go to I -- both caches end in S. Going to I is
//                            a correctness-preserving PERFORMANCE bug and shows
//                            up in the traffic score, not as a data failure.
//               peer in E or S -> downgrade to S.
//               peer in I -> nothing. The requester, finding no sharer, installs
//                            the line in E (not S) -- that is what makes the
//                            silent E->M upgrade legal later.
//     BusRdX  : every peer invalidates. A peer in M FLUSHES FIRST -- its dirty
//     BusUpgr   data must not be lost. The requester ends in M.
//
//   bus_snoop_hit  : the peer had the line in any of S, E or M.
//   bus_snoop_hitm : the peer had it in M and is flushing it.
//   bus_data / bus_data_valid : the flushed line, when hitm.
//
//   A FLUSH ALSO WRITES THE LINE BACK TO MEMORY, so memory is a valid backing
//   store for every line that is not currently held in M.
//
// -----------------------------------------------------------------------------
// BUS AND ARBITRATION
// -----------------------------------------------------------------------------
//   ONE transaction in flight at a time. Both caches snoop every transaction.
//   Arbitration between the two cores is ROUND-ROBIN, which is anti-starving by
//   construction. bus_grant pulses for one cycle when a transaction is granted;
//   bus_req_valid is high for the duration of the transaction, with
//   bus_req_type / bus_req_addr / bus_req_core_id describing it.
//
// -----------------------------------------------------------------------------
// MEMORY  (shared, single outstanding, line granular, no tag)
// -----------------------------------------------------------------------------
//   mem_req_valid / mem_req_addr / mem_req_we / mem_req_wdata (a full line) /
//   mem_resp_valid / mem_resp_rdata. At most ONE transaction in flight;
//   asserting mem_req_valid again before mem_resp_valid has pulsed is a
//   protocol violation and is detected. Latency is randomised.
//
// -----------------------------------------------------------------------------
// EVICTION
// -----------------------------------------------------------------------------
//   Installing a line may require evicting one from the set. A victim in M MUST
//   be written back before it is discarded; a victim in S or E may be dropped
//   silently. Replacement choice is IMPLEMENTATION DEFINED and NOT graded.
//
// -----------------------------------------------------------------------------
// VERIFICATION HOOK
// -----------------------------------------------------------------------------
//   debug_state is a FLATTENED, packed vector carrying, for every way,
//   {tag, state}:
//
//       ENT_W = LTAG_W + 2
//       entry(core, set, way) = debug_state[((core*SETS+set)*WAYS+way)*ENT_W +: ENT_W]
//       state = entry[1:0]                 tag = entry[ENT_W-1:2]
//
//   RESOLVED AMBIGUITY -- the original port list carried only the 2-bit state.
//   That is not sufficient: the coherence invariant is a statement about a LINE
//   (an address), and once more than one line maps to a set, the state of a way
//   says nothing about which address it belongs to. The TAG is therefore
//   included so the invariant is checkable at all. Flattened rather than a 3-D
//   unpacked port purely for tool portability.
//
//   A way whose state is I has a DON'T CARE tag.
//
//   This exists ONLY so the harness can check the coherence invariants every
//   cycle; it must not feed anything functional.
//
// -----------------------------------------------------------------------------
// RESET
// -----------------------------------------------------------------------------
//   rst_n is ACTIVE-LOW and SYNCHRONOUS. After reset every line in both caches
//   is I, the bus is idle, and no memory transaction is in flight.
//
// -----------------------------------------------------------------------------
// GRADING
// -----------------------------------------------------------------------------
//   TIER 1, PASS/FAIL:
//     * STATE INVARIANT, checked every cycle over debug_state:
//         - a line is never M or E in BOTH caches
//         - a line is never M or E in one cache while S in the other
//         - a line is never M in one cache while valid in the other at all
//     * DATA: every read returns the value of the most recent write to that
//       address by either core, under a single global order per address
//     * no dirty data lost: the final memory image must match the golden model
//     * memory protocol legality
//   TIER 2, INFORMATIONAL: bus transaction counts by type, and memory traffic.
//     A protocol-correct implementation that generates more bus traffic than
//     necessary still PASSES; the traffic score is where that shows up.
// =============================================================================

module mesi_top #(
    parameter int ADDR_W     = 10,
    parameter int DATA_W     = 32,
    parameter int LINE_BYTES = 16,
    parameter int SETS       = 4,
    parameter int WAYS       = 2,
    // derived -- do not override
    parameter int LINE_W     = 8*LINE_BYTES,
    parameter int LTAG_W     = ADDR_W - $clog2(LINE_BYTES) - $clog2(SETS),
    parameter int ENT_W      = LTAG_W + 2,
    parameter int NSTATE     = 2*SETS*WAYS
) (
    input  logic                clk,
    input  logic                rst_n,

    // ---- core 0 CPU side ----
    input  logic                c0_req_valid,
    input  logic [ADDR_W-1:0]   c0_req_addr,
    input  logic                c0_req_we,
    input  logic [DATA_W-1:0]   c0_req_wdata,
    output logic                c0_resp_valid,
    output logic [DATA_W-1:0]   c0_resp_rdata,

    // ---- core 1 CPU side ----
    input  logic                c1_req_valid,
    input  logic [ADDR_W-1:0]   c1_req_addr,
    input  logic                c1_req_we,
    input  logic [DATA_W-1:0]   c1_req_wdata,
    output logic                c1_resp_valid,
    output logic [DATA_W-1:0]   c1_resp_rdata,

    // ---- shared bus (observation) ----
    output logic                bus_req_valid,
    output logic [1:0]          bus_req_type,
    output logic [ADDR_W-1:0]   bus_req_addr,
    output logic                bus_req_core_id,
    output logic                bus_grant,
    output logic                bus_snoop_hit,
    output logic                bus_snoop_hitm,
    output logic [LINE_W-1:0]   bus_data,
    output logic                bus_data_valid,

    // ---- shared memory ----
    output logic                mem_req_valid,
    output logic [ADDR_W-1:0]   mem_req_addr,
    output logic                mem_req_we,
    output logic [LINE_W-1:0]   mem_req_wdata,
    input  logic                mem_resp_valid,
    input  logic [LINE_W-1:0]   mem_resp_rdata,

    // ---- verification only ----
    output logic [NSTATE*ENT_W-1:0] debug_state
);

    // IMPLEMENTATION INTENTIONALLY OMITTED.

endmodule
