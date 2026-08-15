// =============================================================================
// axi4_xbar_iface.sv  --  PORT DEFINITION ONLY (no implementation)
// =============================================================================
// Task: implement a full AXI4 crossbar connecting NUM_MST masters to NUM_SLV
// slaves, with address-based routing, ID widening so responses find their way
// home, and per-ID ordering preserved end to end.
//
// The channel and address-map types are in spec/axi4_xbar_pkg.sv, which ships
// with this file and is part of the problem statement.
//
// ***  THE HARD REQUIREMENT IN THIS TASK IS NOT A DATA PROPERTY.  ***
// A crossbar that returns wrong data is easy to catch. A crossbar that WEDGES
// under all-to-all traffic returns nothing at all, and a checker that only
// compares outputs reports a clean pass on a dead design. Deadlock freedom and
// starvation freedom are the requirements here, and they are checked
// explicitly. Read § LIVENESS before designing the arbitration.
//
// The second hard requirement is CAPACITY. A design that carries exactly one
// transaction per master is correct on every transaction it performs and still
// fails this task: it has a fraction of the aggregate throughput of a real
// crossbar, and MAX_TRANS exists to say so. Read § CAPACITY AND CONCURRENCY.
//
// -----------------------------------------------------------------------------
// PARAMETERS
// -----------------------------------------------------------------------------
//   NUM_MST : number of MASTERS attached (crossbar slave ports). Legal: 2, 4.
//             *** HARD CAP AT 4. *** The widened slave-side id field is fixed
//             at SLV_ID_W + 2 bits (see spec/axi4_xbar_pkg.sv), which supplies
//             exactly 2 master-index bits. NUM_MST = 8 would need 3, two
//             masters would share an index, and their responses would misroute.
//             The checker rejects NUM_MST > 4 rather than let that happen.
//   NUM_SLV : number of SLAVES attached  (crossbar master ports). Legal: 2, 4.
//   MAX_BURST_LEN : the largest ARLEN/AWLEN the design must support, in the
//             AXI encoding (beats - 1). Legal: 3, 255. This is a REQUIRED
//             capability, checked: the checker drives bursts at exactly this
//             value and fails if the design cannot carry them. It is also a
//             CEILING -- nothing above it is ever driven, so provisioning for
//             longer bursts is wasted area, not insurance.
//   MAX_TRANS : REQUIRED outstanding transactions per master port. Legal: 2, 8.
//             This is a MINIMUM CAPACITY the design must provide, not a limit
//             it may ignore -- see C1. Exceeding it is fine; a design that
//             accepts the parameter and never uses it fails.
//   Any other value is ILLEGAL and need not be handled.
//
// -----------------------------------------------------------------------------
// ID WIDENING -- normative
// -----------------------------------------------------------------------------
//   A master presents SLV_ID_W-bit IDs. Two different masters may legitimately
//   use the SAME ID value, so the crossbar must be able to tell their responses
//   apart. On the slave side the ID is therefore widened to
//
//       MST_ID_W = SLV_ID_W + $clog2(NUM_MST)
//
//   with the originating master port index in the UPPER bits and the master's
//   own ID in the lower SLV_ID_W bits. The struct field is fixed at
//   MST_ID_W = SLV_ID_W + 2 so one layout serves every legal NUM_MST; with
//   NUM_MST == 2 the upper index bit is always 0. A response arriving on
//   a slave port is routed back to the master named by those upper bits, and
//   the ID presented to that master is the lower bits — the master must see
//   exactly the ID it issued.
//
// -----------------------------------------------------------------------------
// ADDRESS DECODE
// -----------------------------------------------------------------------------
//   D1. `addr_map` supplies one rule per slave port: a request whose address
//       falls in [start_addr, end_addr) is routed to `mst_port`. Ranges never
//       overlap; you need not resolve conflicts.
//   D2. An address matching NO rule is a DECODE ERROR. The crossbar must
//       itself return a response — RESP_DECERR — to the originating master,
//       without forwarding anything to any slave. The transaction must be
//       completed, not dropped: a write returns a single B beat, a read returns
//       len+1 R beats with the last carrying `last`.
//       *** A dropped unmapped transaction is a deadlock, because the master
//       waits forever for a response that is never coming. ***
//   D3. Decode is on the address only. QoS, cache, prot and region are carried
//       through unmodified and never affect routing.
//
// -----------------------------------------------------------------------------
// ORDERING -- normative, and the subtlest data requirement
// -----------------------------------------------------------------------------
//   O1. PER-ID ORDERING. For one master, responses carrying the same ID must be
//       returned in the order the requests were issued. This holds even when
//       those requests went to DIFFERENT slaves that respond at different rates
//       — which is precisely the case that forces either ordering hardware or a
//       restriction on issuing same-ID requests to multiple slaves.
//   O2. Responses with DIFFERENT IDs may be returned in any order. AXI permits
//       it and the checker does not require any particular interleaving.
//       *** THIS IS A PERMISSION, NOT AN OBLIGATION. *** A crossbar that is
//       strictly in-order across IDs is conforming, and nothing scores it down
//       for that: reordering is reported as a METRIC and gates nothing. What
//       you may NOT do is refuse to ACCEPT a second ID -- see C1.
//   O3. WRITE DATA ORDER. W beats are not tagged with an ID; they belong to the
//       AW transactions in the order those were accepted on that port. A
//       crossbar that reorders W beats relative to their AW corrupts data.
//   O4. A read burst's R beats are contiguous per ID: once a burst starts
//       returning on an ID, no other response with that same ID interleaves
//       into it. `last` marks the final beat.
//
// -----------------------------------------------------------------------------
// LIVENESS -- the point of the task
// -----------------------------------------------------------------------------
//   L1. NO DEADLOCK. Under sustained all-to-all traffic — every master
//       targeting every slave, including several masters targeting one slave —
//       the crossbar must keep retiring transactions indefinitely. The checker
//       fails the design if, with load offered, NOTHING is retired anywhere for
//       a sustained window.
//   L2. NO STARVATION. No master may wait indefinitely while other masters are
//       being served. The checker tracks per-master wait time measured only
//       while OTHER masters are making progress, so a uniformly slow crossbar
//       is not penalised — only an unfair one.
//   L3. Both hold under RESPONSE BACKPRESSURE -- masters deassert r_ready and
//       b_ready at arbitrary times, independently of each other -- and with
//       masters offering load at different rates. The checker applies pseudo-
//       random backpressure on both response channels of every master and
//       fails if it never actually stalls a response, so this requirement
//       cannot pass by never being exercised.
//
//       Backpressure is bounded in TIME, never in total: a master always
//       resumes. You do not need to absorb a whole burst to satisfy L3 -- the
//       vendored reference satisfies it at MAX_BURST_LEN=255 while buffering
//       NO read data at all. Stalling your input is a legitimate response to a
//       stalled output.
//
//   The classic way to fail L1 is a shared resource claimed in a different
//   order by different paths — for example accepting an AW without reserving
//   the response capacity to retire its B. The classic way to fail L2 is a
//   fixed-priority arbiter.
//
//   QoS is carried but is NOT a scheduling requirement: you may use it, and a
//   design that ignores it entirely still passes. Nothing here rewards
//   prioritising by QoS, and nothing punishes it, provided L2 still holds.
//
// -----------------------------------------------------------------------------
// HANDSHAKE
// -----------------------------------------------------------------------------
//   Standard AXI4 valid/ready on all five channels of all ports.
//   H1. No *_ready may depend combinationally on the corresponding *_valid.
//   H2. Once a master asserts a valid it holds the channel payload stable until
//       ready. The checker honours this.
//   H3. A crossbar output holding valid with ready low must keep valid high and
//       the payload stable.
//
// -----------------------------------------------------------------------------
// CAPACITY AND CONCURRENCY -- normative, and checked
// -----------------------------------------------------------------------------
//   A crossbar that moves one transaction at a time is not a crossbar. These
//   requirements say what the design must be able to do AT ONCE, which is
//   independent of doing each transaction correctly.
//
//   C1. OUTSTANDING CAPACITY. Each master port must be able to carry MAX_TRANS
//       transactions at once. MAX_TRANS is a capacity requirement, not a
//       decorative parameter and not an upper bound you may ignore: a design
//       that hard-codes one in-flight transaction per master fails this.
//
//       The checker holds r_ready and b_ready low while the slave side accepts
//       every request, then counts what each master got in before the crossbar
//       stopped accepting. IT REQUIRES AT LEAST ceil(MAX_TRANS / 2) PER MASTER,
//       not MAX_TRANS. That gap is deliberate tolerance, not slack: observable
//       capacity depends on pipeline depth as well as queue depth, so a design
//       with fewer buffering stages legitimately reports a smaller number from
//       the same configured depth. Requiring the full MAX_TRANS would fail a
//       correct crossbar for being less pipelined, which is not a requirement
//       this spec makes. Honour the parameter and you will clear the floor
//       comfortably.
//
//       The floor applies PER MASTER, so it also catches head-of-line blocking:
//       a design where one master's un-retiring transaction shuts other masters
//       out of a shared slave fails even where the depth requirement is weak.
//
//       CAPACITY IS CAPACITY WHATEVER THE ID MIX. The checker issues DISTINCT
//       IDs while filling, so a design that holds MAX_TRANS of a single ID but
//       refuses a second ID fails here. O2 grants you the right to RETURN
//       different IDs out of order; it does not grant the right to REFUSE them.
//
//   C2. CONCURRENT DISJOINT PAIRS. Traffic between disjoint master/slave pairs
//       must proceed in parallel. With master i addressing only slave i and
//       master j only slave j (i != j, no shared endpoint), the two pairs share
//       no resource and both must make progress in the same window. A design
//       that funnels all traffic through a single shared arbiter is correct on
//       every individual transaction and fails here.
//
//       The checker requires two disjoint pairs to retain AT LEAST 150 % of the
//       throughput of one pair alone. Ideal parallelism is 200 % and complete
//       serialisation is 100 %, so the threshold sits at the midpoint: it
//       tolerates up to a quarter of the ideal being lost to arbitration
//       overhead, while still failing anything sharing one datapath. No
//       particular arbitration is required and none is rewarded.
//
//   C3. Both hold at every legal NUM_MST / NUM_SLV / MAX_TRANS combination.
//
//   Aggregate throughput under all-to-all saturation is MEASURED AND REPORTED as
//   a METRIC line. It does not gate: the achievable rate depends on the geometry
//   and on the slave models, so no single threshold separates a good design from
//   a bad one across all configurations. C1 and C2 are the gates.
//
// -----------------------------------------------------------------------------
// LATENCY
// -----------------------------------------------------------------------------
//   NOT CONSTRAINED AND NOT CHECKED. Pipeline as deeply as you like; added
//   latency is never penalised. Note that this is a statement about DELAY, not
//   about CAPACITY -- C1 and C2 above are requirements and are checked.
//
// -----------------------------------------------------------------------------
// RESET
// -----------------------------------------------------------------------------
//   rst_n is ACTIVE-LOW and SYNCHRONOUS.
//   R1. While rst_n is low every output valid is 0.
//   R2. Reset discards all in-flight transactions. After release the crossbar
//       starts clean; no response from before reset may be emitted.
//
// =============================================================================

module axi4_xbar
  import axi4_xbar_pkg::*;
#(
    parameter int NUM_MST   = 2,   // masters attached   (2 / 4)
    parameter int NUM_SLV   = 2,   // slaves attached    (2 / 4)
    parameter int MAX_TRANS = 8,   // REQUIRED outstanding per master port (2 / 8) -- see C1
    parameter int MAX_BURST_LEN = 3 // largest ARLEN/AWLEN to support (3 / 255)
) (
    input  logic clk,
    input  logic rst_n,

    // ---- master side: NUM_MST masters drive these -------------------------
    input  slv_req_t  [NUM_MST-1:0] mst_req,
    output slv_resp_t [NUM_MST-1:0] mst_resp,

    // ---- slave side: NUM_SLV slaves are driven by these --------------------
    // These use the WIDE-ID channel types: the originating master travels in
    // the upper MST_IDX_W bits of the id field, which is how AXI carries it.
    // There is no sideband signal for it and there must not be one.
    output mst_req_t  [NUM_SLV-1:0] slv_req,
    input  mst_resp_t [NUM_SLV-1:0] slv_resp,

    // ---- address map ------------------------------------------------------
    input  xbar_rule_t [NUM_SLV-1:0] addr_map
);

    // IMPLEMENTATION INTENTIONALLY OMITTED.

endmodule
