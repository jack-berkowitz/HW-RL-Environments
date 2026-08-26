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
//             accepts the parameter and never uses it fails. Note that
//             TRACKING more transactions is cheap and permitted, while BUFFERING
//             their data is bounded by C3 -- the two are different resources.
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
//   C3. RESPONSE BUFFERING IS BOUNDED. A design may hold at most **4 R beats
//       and 4 W beats per master port** in flight inside the crossbar. Storage
//       beyond that is NON-CONFORMING, not a design choice.
//
//       WHY A CEILING AND NOT A FLOOR. C1 says how much the design must be able
//       to do at once; this says how much it may SPEND doing it. Without a
//       ceiling, buffering is an unpriced axis: a submission may absorb a whole
//       maximum-length burst per master and report better throughput for it,
//       and the area that bought is charged to nothing. One did exactly that --
//       a 256-entry per-master read buffer, 2 x 256 x ~40 bits of flip-flops,
//       which is 14x the reference's total area on a design that is otherwise
//       correct on every axis. It was not a bad answer to this specification.
//       It was an answer this specification failed to constrain.
//
//       4 beats is the smallest depth that lets a design register both the
//       request and the response path without stalling, which is what the
//       reference does with a pair of two-entry spill registers. A crossbar
//       ROUTES; it is not a reorder buffer and it is not a cache. Anything that
//       needs deeper storage belongs on the other side of the master port.
//
//       This bound is on STORAGE, not on outstanding transactions. C1's
//       MAX_TRANS capacity is tracked with counters and IDs, which cost almost
//       nothing; holding the DATA is what costs area. A conforming design
//       tracks many transactions and buffers few beats.
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
// -----------------------------------------------------------------------------
// TOOL REQUIREMENTS
// -----------------------------------------------------------------------------
//   T1. THE SUBMISSION MUST ELABORATE UNDER BOTH slang AND Verilator.
//       Simulation uses Verilator; physical synthesis reads the same file with
//       slang. A file one accepts and the other rejects cannot be built, and a
//       submission that cannot be built produces no PPA number at all -- see G1.
//   T2. DECLARE EVERY VARIABLE BEFORE THE FIRST STATEMENT IN ITS PROCEDURAL
//       BLOCK. slang enforces the LRM rule that every declaration in a block
//       precedes every statement in that block, and VERILATOR DOES NOT DIAGNOSE
//       THE VIOLATION. The file therefore simulates clean and then yields NO PPA
//       NUMBER AT ALL -- it reads as a missing measurement rather than as a
//       rejected submission, which is the worst shape a failure can take here.
//       Declare every variable at the top of the block that uses it, or at module
//       scope, before any assignment, loop or $display in that block.
//   
//       MEASURED HISTORY, NOT CAUTION. Ten run records across four tasks in this
//       repository were killed by exactly
//           error: declaration must come before all statements in the block
//       nine of them from one model. An earlier version of this clause called it
//       "the most common compile failure here", which reads as though the failure
//       is VISIBLE. Under Verilator it is not.
//   T3. THE MODULE MUST BE NAMED `axi4_xbar` with the exact port list below,
//       including port names.
//   T4. ONE SELF-CONTAINED FILE. No package, no include, no reference to
//       anything outside itself.
// -----------------------------------------------------------------------------
// G. GRADING -- how a submission is judged, and against what
// -----------------------------------------------------------------------------
//   G1. THE ORDER. Correctness is a GATE, not a weighting.
//
//       1. CORRECTNESS, at every legal NUM_MST / NUM_SLV / MAX_TRANS
//          combination. Checked against D1-D3, O1-O4, H1-H3, C1-C3, L1-L3 and
//          R1-R2. There is no partial credit: a crossbar that deadlocks is not
//          a small design, it is a broken one.
//
//       2. THE GATE. A submission that fails correctness at ANY legal
//          combination, or that fails to build, produces NO PPA NUMBER AT ALL.
//          It is recorded as a failure and scores zero on every PPA axis --
//          not as a missing measurement.
//
//       3. PPA, measured only for submissions that already passed, ONCE AT A
//          PINNED CLOCK PERIOD, at the scored configuration and nowhere else.
//          The pinned period is 8.0 ns on sky130hd. It is derived as 1.5x the
//          reference implementation's own measured period (5.25 ns), rounded
//          up to the next 0.25 ns, and it is STATED HERE BEFORE ANY SUBMISSION IS
//          SOLICITED. It does not move in response to what is submitted -- an
//          earlier scheme pinned the row at the slowest submission's own Fmax,
//          which rewards a slow design by moving the measurement toward the period
//          where its own area looks best. The period is THE SAME for every
//          submission, so all designs are compared at one frequency rather than at
//          each design's own best.
//
//   G2. WHAT IS COMPARED. Measured from one build, at the pinned period:
//         * AREA, post-synthesis and post-place-and-route.
//         * POWER, at the pinned period.
//         * CONCURRENCY, as outstanding transactions carried and as bursts
//           completed between disjoint pairs. These are CAPABILITIES: more is
//           better, they cost area, and they are reported both raw and per unit
//           of area so a design is not rewarded merely for carrying less.
//
//       TIMING CLOSURE IS A GATE, NOT AN AXIS, AND SLACK IS NOT SCORED. A build
//       that misses the pinned period yields no comparable area or power figure --
//       an area number from a build that did not close is not a smaller design, it
//       is an unfinished one -- so its PPA is withheld rather than reported.
//
//       Slack ABOVE zero earns nothing either, and the reason is that it is not a
//       separate quantity from area. Meeting timing with margin is bought WITH
//       area: the tools upsize cells, insert buffers and duplicate logic to close
//       faster. A design sitting at +2 ns on the pinned period spent silicon
//       getting there that a design at +0.05 ns did not. Area already charges for
//       that, so scoring slack as well would count one tradeoff twice and in
//       opposite directions -- rewarding a design for the very spending the area
//       axis penalises. Closure is therefore pass or fail, and everything above
//       the line is the same result.

//       Fmax is NOT a scored axis. It is measured once per task, on the
//       REFERENCE ONLY, and its sole job is to set the pinned period above.
//       Submissions are not swept. A design that could run faster than the
//       pinned period earns nothing for it, exactly as a design handed a
//       frequency target in practice earns nothing for exceeding it; and a
//       per-design Fmax could not be combined with the area and power above
//       in any case, because those come from a build at the pinned period and
//       an Fmax comes from a different build at a different one.
//
//   G3. WHAT IS NOT AVAILABLE TO OPTIMISE. The levers most designs reach for
//       first are already spent by the contract above.
//
//         * OUTSTANDING CAPACITY HAS A FLOOR. C1 requires each master port to
//           carry MAX_TRANS transactions. A design that accepts one at a time
//           is smaller and it FAILS, so the area is not bought.
//         * RESPONSE BUFFERING HAS A CEILING. C3 bounds a design to at most
//           4 R beats and 4 W beats per master port. Concurrency bought by
//           buffering whole bursts is not available: a 256-entry response
//           buffer is wrong, not merely expensive. This clause is why an
//           earlier submission measured 2,086,235 um2 against a reference of
//           77,852 -- it was storing what the contract never asked it to store.
//         * FORWARD PROGRESS IS NOT NEGOTIABLE. L1 and L2 forbid deadlock and
//           starvation under sustained all-to-all traffic, and L3 requires both
//           to hold under response backpressure.
//         * ORDERING IS PINNED WHERE AXI PINS IT. O1 and O4 are not choices.
//
//   G4. WHAT IS ACTUALLY LEFT, and it is where the whole PPA difference comes
//       from. The contract fixes WHAT is delivered and WHEN; it says nothing
//       about HOW:
//
//         * how the switch fabric is built -- full crossbar, shared bus, or
//           anything between, subject to C2's disjoint-pair concurrency;
//         * how outstanding transactions are tracked, given C1's floor and C3's
//           ceiling -- the tracking structure is a real choice with real cost;
//         * how arbitration is done, subject only to L2;
//         * where registers sit relative to the LATENCY_MODE cuts;
//         * how much logic is shared across master and slave ports.
//
//       A submission that meets the pinned period with less area and less power
//       scores better. Meeting it comfortably buys nothing extra: there is no
//       credit for slack beyond zero, because the period is fixed for everyone.
//
//   G5. THERE IS NO SINGLE COMBINED SCORE, and that is deliberate rather than
//       unfinished. Nothing in this project establishes what a unit of
//       capability is worth in square micrometres, so no weighted sum of area,
//       power and capability is computed, and none should be inferred from the
//       phrase "scores better" above. Each axis is reported separately, and a
//       submission that wins on one and loses on another is reported as exactly
//       that.
//
//       WHAT A SUBMISSION IS COMPARED AGAINST. The reference implementation,
//       built from the same contract at the same pinned period and the same
//       scored configuration, and the other submissions to this task on the
//       same axes. The reference is an ANCHOR, not a target: beating it is not
//       required and losing to it is not disqualifying. It exists so that a
//       number has something to be a ratio of.
//
//       EVERY REPORTED METRIC CARRIES A ROLE, and the role decides how a
//       difference from the reference is read:
//
//         * FIXED -- the contract requires a value. Deviating is a specification
//         violation, not a design choice, and it fails correctness.
//         * CHOICE -- the contract leaves it free and it moves PPA. Where a
//         submission chose differently from the reference, the area ratio is
//         marked NOT LIKE-FOR-LIKE rather than presented as a quality gap.
//         Choosing differently from the reference is not penalised; it is
//         disclosed.
//         * CAPABILITY -- more is better and area buys it. Reported both raw and
//         per unit of area, because raw area credits a design for being small
//         when it was actually doing less.
//
//       So the honest summary of the whole scheme: correctness gates, timing
//       closure gates, and what survives both is described on several axes at one
//       operating point, with the free choices named so that a difference in area
//       can be read as the trade it is rather than as a verdict.
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
