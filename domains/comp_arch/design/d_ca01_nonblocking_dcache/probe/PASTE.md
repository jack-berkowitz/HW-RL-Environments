# Task: implement a non-blocking data cache in SystemVerilog

You are given a **port map and a complete specification**. Write the RTL that
implements it. You will not be shown any reference implementation.

Your answer is run against a checker across **16 parameter combinations** and
must pass every one. It is also synthesised, so it must be legal SystemVerilog
for two different frontends.

**The difficulty is allocation and scheduling, not the datapath.** A cache that
stalls on every miss is straightforward and fails. What this task measures is
what happens while misses are outstanding: hits answered underneath them,
several distinct line misses in flight at once, and forward progress under
continuous load. Two of those are not data properties -- no amount of comparing
one output against one expected value finds them.

## What to submit

**One self-contained file** containing only `module nonblocking_dcache`, with
the exact port list below. No package, no include, no reference to anything
outside the file.

Two things that account for most failures here, both cheap to avoid:

- **It must elaborate under BOTH slang and Verilator.** Simulation uses one and
  synthesis reads the same file with the other; they disagree about what is
  legal, and a file only one accepts cannot be built.
- **Declare every variable before the first statement in its procedural block.**
  SystemVerilog forbids a declaration after a statement inside a block. This is
  by a wide margin the most common way a submission here fails to compile, and
  the error message names neither declarations nor placement.

---

## The specification

Everything below is the contract. Clauses marked `L`n name choices the contract
deliberately leaves **open** -- you may make them however you like, and nothing
checks them. Everything else is normative.

```systemverilog
// =============================================================================
// nonblocking_dcache_iface.sv  --  PORT DEFINITION ONLY (no implementation)
// =============================================================================
// Task: implement a set-associative, write-back, write-allocate data cache that
// KEEPS ACCEPTING REQUESTS WHILE MISSES ARE OUTSTANDING.
//
// *** THE DIFFICULTY IS ALLOCATION AND SCHEDULING, NOT THE DATAPATH. ***
//
//   1. HIT UNDER MISS, AND MISS UNDER MISS. A request that hits must be
//      answered while earlier misses are still waiting on memory. Several
//      distinct line misses must be in flight at once -- see C1, which is the
//      capability this task exists to measure.
//
//   2. FORWARD PROGRESS IS THE REAL REQUIREMENT. Under continuously offered
//      load, with memory always eventually responding, every accepted request
//      must eventually be answered. A design that is correct on every
//      individual transaction and wedges under pressure fails C3, and C3 is
//      not a data property -- no amount of output comparison finds it.
//
//   3. RESPONSES CARRY AN ID AND MAY COME BACK IN ANY ORDER. Out-of-order
//      completion is the point, not an allowance.
//
// NO INTERNAL STRUCTURE IS REQUIRED OR IMPLIED. This contract never names a
// miss-status register, a miss queue, or any other mechanism. How outstanding
// misses are tracked is a design choice; only the externally observable
// behaviour below is contractual.
//
// -----------------------------------------------------------------------------
// PARAMETERS  --  all four are swept, and each is bound by a check
// -----------------------------------------------------------------------------
//   DATA_W      word width in bits          legal {32, 64}
//   SETS        number of sets              legal {8, 16}
//   WAYS        associativity               legal {2, 4}
//   MAX_MISSES  outstanding distinct-line misses that must be supported
//                                           legal {2, 8}
//
//   Fixed by this contract and NOT parameters: ADDR_W = 32 (byte address),
//   ID_W = 4, BLOCK_WORDS = 4. They are localparams below. A quantity that is
//   never swept is a constant, not a capability, and declaring it as a
//   parameter would claim a flexibility nothing checks.
//
//   AUTHORITY for the legal sets (rule 15): stated task intent. Two values on
//   each axis is the minimum that can bind the parameter -- a single value is
//   indistinguishable from a hardcoded constant, which is the defect the
//   capability checks exist to catch.
//
// -----------------------------------------------------------------------------
// S0. SCORED CONFIGURATION -- rule 18
// -----------------------------------------------------------------------------
//   *** DATA_W = 32, SETS = 16, WAYS = 4, MAX_MISSES = 8. ***
//
//   PPA, latency and throughput are measured HERE AND NOWHERE ELSE. Correctness
//   is checked across all 16 legal combinations; a submission must work at every
//   one of them. Building only for the scored configuration fails the sweep.
//
//   Rationale, in rule 18's order, and NOT the anchor's default (the reference
//   module has no default -- every parameter is mandatory):
//
//   REPRESENTATIVE OF REAL USE. A 32-bit word with 4-way associativity is the
//   ordinary L1 data cache arrangement for the core class this task belongs to.
//   16 sets x 4 ways x 4 words x 32 bits is 8 kbit of data array: a real cache
//   rather than a toy, and small enough that place-and-route completes.
//
//   EXERCISES THE INTERESTING PART OF THE DESIGN SPACE. MAX_MISSES = 8 is the
//   load-bearing choice. At MAX_MISSES = 2 a capacity check can barely
//   discriminate -- d_nw01 recorded exactly this: no capability check
//   discriminates at MAX_TRANS = 2, and a pass there is not capability
//   evidence. Choosing 2 here would knowingly repeat that. WAYS = 4 likewise:
//   at 2 ways, replacement is nearly degenerate.
//
//   DATA_W = 32 rather than 64: 64 doubles the data array without exercising
//   anything new on the allocation-and-scheduling axis this task measures, and
//   pushes the physical build toward the container memory ceiling that has
//   already killed one route here.
//
// -----------------------------------------------------------------------------
// P1. POWER-UP STATE -- a PRECONDITION on the environment, not a requirement
// -----------------------------------------------------------------------------
//   *** EVERY LINE IS INVALID AT THE FIRST REQUEST AFTER RESET DEASSERTS. ***
//
//   The design MAY assume this. It is NOT required to implement an
//   invalidate-on-reset sequence, and it is NOT required to accept any
//   initialization or management operation -- there is no such operation in
//   this interface. The harness guarantees the condition and the testbench
//   verifies it on every run: the first access to each line must be observed to
//   fetch from memory rather than hit.
//
//   A design that DOES clear its own tags on reset is equally conformant. The
//   precondition permits that; it does not require it.
//
//   AUTHORITY (rule 15): THIS TASK'S DECISION, recorded as such. It must not be
//   cited as a standard, and it is not what the reference happens to do -- the
//   reference's tag memory is externally initialized, which is a third
//   conformant arrangement this contract simply does not use.
//
//   WHY IT IS A PRECONDITION RATHER THAN A REQUIREMENT. This task's difficulty
//   axes are hit-under-miss, outstanding-miss capacity and forward progress.
//   Power-up tag state is on none of them. Making initialization a design
//   requirement would add a barrier off every measured axis, which is how a
//   submission loses its whole result for a reason the benchmark is not trying
//   to measure. Stating it as a precondition AND checking it every run is what
//   keeps a self-initializing design and an assuming design from passing for
//   two different reasons.
//
// -----------------------------------------------------------------------------
// REQUEST AND RESPONSE -- normative
// -----------------------------------------------------------------------------
//   R1. HANDSHAKE. A request transfers on a rising clock edge where
//       `req_valid_i` and `req_ready_o` are both high. Once `req_valid_i` is
//       asserted it remains asserted, with the payload held stable, until the
//       transfer completes. Responses use the same discipline on
//       `rsp_valid_o` / `rsp_ready_i`.
//       AUTHORITY: stated task intent. This is the ordinary ready/valid
//       contract and is stated so that stability is a contract term rather than
//       an assumption.
//
//   R2. OPERATIONS. `req_op_i` is 1'b0 for LOAD, 1'b1 for STORE.
//       LOAD returns the addressed word. STORE writes the bytes of
//       `req_data_i` selected by `req_mask_i`; bytes whose mask bit is 0 are
//       left unchanged.
//       `req_addr_i` is a BYTE address and is word-aligned for both operations;
//       its low $clog2(DATA_W/8) bits are always zero and their handling is
//       unconstrained.
//       AUTHORITY: stated task intent.
//
//   R3. EVERY ACCEPTED REQUEST PRODUCES EXACTLY ONE RESPONSE, tagged with that
//       request's `req_id_i` on `rsp_id_o`. For a LOAD, `rsp_data_o` is the
//       addressed word. For a STORE, `rsp_data_o` IS NOT CONSTRAINED and is
//       not checked -- a design may return anything, including zero.
//       AUTHORITY: stated task intent. The id is what makes an out-of-order
//       response stream decodable; constraining store response data would
//       encode a choice nothing needs.
//
//   R4. RESPONSE ORDER IS FREE, WITH ONE EXCEPTION THAT FOLLOWS FROM C2.
//       Responses may be returned in any order with respect to request order.
//       Nothing rewards or penalises reordering, and no check counts it.
//
//       THE EXCEPTION: a response that is ready must not be held behind one
//       that is not. STRICTLY IN-ORDER RETIREMENT IS THEREFORE NOT CONFORMANT
//       -- a hit accepted after an outstanding miss would be blocked behind it,
//       and C2 requires that hit to be ANSWERED, not merely accepted.
//
//       This is a CONSEQUENCE of C2 rather than an independent requirement, and
//       it is stated because an earlier revision of this clause said flatly that
//       strict in-order retirement was conformant. It is not, and the two
//       clauses could not both be satisfied. Found by building the in-order
//       design and running it: it fails C2 and nothing else.
//
//       WHY THIS IS NOT THE d_nw01 TRAP. There, a coverage floor REQUIRING
//       cross-ID reordering failed the vendored reference and was removed --
//       reordering was an optimisation on an axis the contract never named, so
//       gating it invented a requirement. Here the axis IS named: hit under
//       miss is what this task exists to measure, and C2 states it. The
//       distinction is between requiring reordering in general (wrong) and
//       requiring that one specific ready response not be blocked (what C2
//       already says).
//       AUTHORITY: stated task intent -- out-of-order completion is what
//       hit-under-miss produces, and REQUIRING reordering would fail a correct
//       design that declines to reorder. That failure mode is recorded: a
//       reordering floor on d_nw01 failed the vendored reference and was
//       removed.
//
//   R5. SAME-ADDRESS ORDERING. Requests to the same word are ordered by the
//       order in which they were ACCEPTED. A LOAD accepted after a STORE to the
//       same word returns that stored value. Requests to different words carry
//       no ordering guarantee whatsoever.
//       AUTHORITY: stated task intent. This is the memory contract the task
//       needs; without it a store followed by a load is unspecified and no
//       scoreboard is possible.
//
//   R6. ID UNIQUENESS IS A PRECONDITION ON THE HARNESS. Two requests with the
//       same `req_id_i` are never in flight at once. The design may rely on it.
//       AUTHORITY: this task's decision. Duplicate ids would make R3
//       undecidable.
//
// -----------------------------------------------------------------------------
// MEMORY PORT -- normative
// -----------------------------------------------------------------------------
//   M1. FILL. On a miss the design issues a memory request with
//       `mem_req_we_o` low and `mem_req_addr_o` equal to the BLOCK-ALIGNED
//       address of the line being fetched, then accepts exactly BLOCK_WORDS
//       beats on `mem_rd_*` in ASCENDING word order, lowest word first.
//       AUTHORITY: stated task intent. Ascending order is pinned because
//       a block transfer has to have an order and both endpoints must agree;
//       the alternative -- critical-word-first -- is named as out of scope in
//       L3 below rather than left to be inferred.
//
//   M2. WRITEBACK. A dirty victim is written back with `mem_req_we_o` high and
//       the victim's block-aligned address, followed by exactly BLOCK_WORDS
//       beats on `mem_wr_*` in ascending word order. A clean victim is not
//       written back.
//       AUTHORITY: stated task intent -- write-back is stated in the task
//       title; writing back a clean line is permitted but wasteful and is not
//       checked either way.
//
//   M3. AT MOST ONE MEMORY TRANSACTION IS OUTSTANDING. A new
//       `mem_req_valid_o` is not asserted until the previous transaction's
//       final data beat has transferred.
//       AUTHORITY: this task's decision, recorded as such. It fixes the
//       next-level model to a single-transaction subordinate, which is the
//       common L1 arrangement and keeps the memory port off the measured axes.
//       A design that pipelines memory transactions is a different and
//       legitimate design; it is out of scope here.
//
// -----------------------------------------------------------------------------
// CAPABILITY AND LIVENESS -- normative, and this is what the task measures
// -----------------------------------------------------------------------------
//   C1. AT LEAST `MAX_MISSES` DISTINCT LINE MISSES MUST BE OUTSTANDING AT ONCE.
//       With memory held so that nothing completes, the design must accept
//       requests to MAX_MISSES distinct lines before it may stop accepting.
//       AUTHORITY: stated task intent -- this is the capability the parameter
//       names, and a parameter no check enforces will be ignored.
//
//       MEASURED AT THE REFERENCE BEFORE BEING WRITTEN, at four settings:
//       the reference accepts exactly MAX_MISSES + 1, at 2, 4, 8 and 16. The
//       floor is MAX_MISSES, so the reference clears it by one and a design
//       providing exactly MAX_MISSES also passes. The floor is NOT set from the
//       reference's number: a floor fitted to the reference's buffering is how
//       an implementation detail becomes a requirement.
//
//   C2. A HIT IS ANSWERED WHILE A MISS IS OUTSTANDING. With a fill unserved,
//       a request that hits a resident line must still be accepted and
//       answered.
//
//       C1 AND C2 OVERLAP, AND THE OVERLAP IS STATED RATHER THAN LEFT TO BE
//       DISCOVERED. Satisfying C1 at MAX_MISSES >= 2 already requires accepting
//       a further request while a miss is outstanding; what C2 adds is that
//       such a request must be ANSWERED. So a design that blocks on a miss
//       fails both, necessarily -- it cannot hold more than one miss
//       outstanding. The converse does not hold: a design with reduced but
//       non-trivial capacity fails C1 and satisfies C2.
//       AUTHORITY: stated task intent -- this is the definition of
//       non-blocking, and without it the parameter in C1 is the only thing
//       separating this from a blocking cache with a queue in front.
//
//   C3. FORWARD PROGRESS. With requests continuously offered and memory always
//       eventually responding, every accepted request is eventually answered,
//       and no id is starved while others are being served.
//       AUTHORITY: stated task intent.
//
//   C4. BLOCK-DATA BUFFERING IS BOUNDED. Outside the tag and data arrays, a
//       design may hold at most TWO cache lines of block data at any time --
//       one for the fill in flight and one for the writeback in flight -- plus,
//       per pending miss, at most ONE WORD of merged store data and its byte
//       mask. Deeper block-data buffering is NON-CONFORMING, not a design
//       choice.
//
//       WHY TWO IS ENOUGH, AND WHY THIS IS NOT FITTED TO THE REFERENCE. M3
//       already permits only ONE memory transaction outstanding, so at most one
//       fill and one writeback can ever be in flight. There is no state in
//       which a third line of block data is in motion. The bound follows from
//       M3 rather than from what any implementation happens to do, which is the
//       trap C1's own note warns about: a floor fitted to the reference's
//       buffering is how an implementation detail becomes a requirement, and a
//       ceiling fitted that way would be the same error pointing down.
//
//       BUFFERING IS NOT TRACKING. MAX_MISSES is a count of misses whose data
//       has NOT yet arrived; their addresses, ids, word indices and masks cost
//       registers and are not bounded here. Holding the block DATA is what
//       costs area. A conforming design tracks many misses and buffers few
//       lines.
//
//       WHY THIS CLAUSE EXISTS. A specification that names a capability and
//       says nothing about the resources delivering it leaves an axis with a
//       benefit and no stated cost, and a submission that spends without limit
//       is conforming while the area comparison measures the specification
//       rather than the design. That is not hypothetical: on the AXI crossbar
//       task a submission buffered a full 256-beat burst per master, about
//       20,480 bits of flip-flops, and measured 14.2x the reference's area
//       while being correct on every axis that task checked.
//
//   ACCEPTANCE RATE IS REPORTED, NOT GATED. Requests accepted per cycle and
//   response latency are emitted as METRIC: lines at the scored configuration.
//   They do not gate the verdict. A slower correct design is not a failing
//   design.
//
// -----------------------------------------------------------------------------
// L. WHAT IS NOT CONSTRAINED -- rule 12, named so it is not inferred
// -----------------------------------------------------------------------------
//   L1. REPLACEMENT POLICY IS FREE. LRU, tree-pseudo-LRU, round-robin and
//       random are all conformant. Nothing checks which line is evicted.
//
//   L2. HOW OUTSTANDING MISSES ARE TRACKED IS FREE. A queue, a register file
//       of miss records, per-line state, or anything else. This contract names
//       no structure, and no check can distinguish them.
//
//   L3. CRITICAL-WORD-FIRST IS OUT OF SCOPE. M1 pins ascending word order, so
//       returning the requested word first is NOT permitted here even though it
//       is a normal cache optimisation. Named because a design that does it
//       would fail M1 against a requirement it was never told.
//
//   L4. A STORE MISS ALLOCATES. This is NOT free, and the reason is worth
//       stating because it is a consequence rather than an independent
//       requirement: M1 and M2 make every memory transaction BLOCK-GRANULAR,
//       BLOCK_WORDS beats, and this port carries no single-word and no
//       byte-masked write. A no-write-allocate design therefore has no legal
//       way to send one modified word to memory -- write-through is not
//       forbidden here so much as INEXPRESSIBLE at this interface.
//
//       Named explicitly because an earlier revision of this clause advertised
//       write-through as a free choice. It was not, and a submission that took
//       the offer would have found the port could not carry it. What IS free is
//       everything about how the allocation is performed: when the fill is
//       requested, whether the store is merged into the arriving block or
//       applied after it lands, and in what order the fill and any writeback of
//       the victim are issued.
//
//   L5. `req_ready_o` MAY DEPEND COMBINATIONALLY ON `req_valid_i`. The harness
//       never derives `req_valid_i` from `req_ready_o`, so a design that gates
//       ready on valid cannot deadlock against it. Named because the opposite
//       rule is a common house style and a submission should not have to guess
//       whether it is being enforced here. It is not.
//
//   L6. LATENCY IS NOT CONSTRAINED. Hit latency, fill latency and the pipeline
//       depth behind them are design choices, reported as METRIC lines at the
//       scored configuration and never gated.
//
//   L7. SIZED AND SIGN-EXTENDED ACCESSES ARE OUT OF SCOPE. Only full-word LOAD
//       and masked STORE exist in this interface. Byte and halfword operations,
//       and any tag-management or flush operation, are not part of this
//       contract and are never driven.
//
// -----------------------------------------------------------------------------
// TOOL REQUIREMENTS -- stated, because a submission cannot pass what it is not told
// -----------------------------------------------------------------------------
//   T1. THE SUBMISSION MUST ELABORATE UNDER BOTH slang AND Verilator.
//       Simulation runs on Verilator; physical synthesis reads the same file
//       with slang. They disagree about what is legal, so a file one accepts
//       and the other rejects cannot be built and scores zero. Agreement
//       between the two is sufficient evidence of validity, not necessary --
//       one frontend accepting a file does not make it legal.
//
//   T2. DECLARE EVERY VARIABLE BEFORE THE FIRST STATEMENT IN ITS PROCEDURAL
//       BLOCK. SystemVerilog forbids a declaration after a statement inside a
//       block. This is stated explicitly because it is by a wide margin the
//       most common way a submission here fails to compile, and the error text
//       names neither declarations nor placement.
//
//   T3. THE MODULE MUST BE NAMED `nonblocking_dcache` and must match the port
//       list below exactly, including port names.
//
//   T4. THE SUBMISSION IS A SINGLE SELF-CONTAINED FILE. It may not reference
//       the testbench hierarchy, any shared model, or any file outside itself.
//
// -----------------------------------------------------------------------------
// G. GRADING -- how a submission is judged, and against what
// -----------------------------------------------------------------------------
//   G1. THE ORDER. Correctness is a GATE, not a weighting.
//
//       1. CORRECTNESS, at every legal parameter combination. Checked against
//          R1-R6, M1-M3, C1-C4 and the reset rules. There is no partial credit:
//          a cache that answers a load wrongly is not a small design, it is a
//          broken one.
//
//       2. THE GATE. A submission that fails correctness at ANY legal
//          combination, or that fails to build, produces NO PPA NUMBER AT ALL.
//          It is recorded as a failure and scores zero on every PPA axis --
//          not as a missing measurement.
//
//       3. PPA, measured only for submissions that already passed, ONCE AT A
//          PINNED CLOCK PERIOD, at the scored configuration and nowhere else.
//          The pinned period is 15.0 ns on sky130hd. It is derived as 1.5x the
//          reference implementation's own measured period (10.0 ns), rounded
//          up to the next 0.25 ns, and it is STATED HERE BEFORE ANY SUBMISSION IS
//          SOLICITED. It does not move in response to what is submitted -- an
//          earlier scheme pinned the row at the slowest submission's own Fmax,
//          which rewards a slow design by moving the measurement toward the
//          period where its area looks best. The period is THE SAME for every
//          submission, so all designs are compared at one frequency rather than
//          at each design's own best.
//
//   G2. WHAT IS COMPARED. Measured from one build, at the pinned period:
//         * AREA, post-synthesis and post-place-and-route.
//         * POWER, at the pinned period.
//         * TIMING SLACK against the pinned period. A build that misses timing
//           yields no comparable area or power figure -- an area number from a
//           build that did not close is not a smaller design, it is an
//           unfinished one, and it is withheld rather than reported.
//         * OUTSTANDING MISSES CARRIED. This is a CAPABILITY: more is better,
//           it costs area, and it is reported both raw and per unit of area so
//           a design is not rewarded merely for tracking fewer misses.
//         * HIT LATENCY, reported as a CHOICE. A design that answers hits in one
//           cycle and one that takes two are both conformant and are NOT ranked
//           against each other on latency; the number is reported so that an
//           area difference between them is read as the trade it is.
//
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
//         * MISS PARALLELISM HAS A FLOOR. C1 requires at least MAX_MISSES
//           distinct line misses outstanding at once, and C2 requires a hit to
//           be answered while a miss is outstanding. A blocking cache is much
//           smaller and it FAILS, so that area is not bought.
//         * BLOCK-DATA BUFFERING HAS A CEILING. C4 bounds a design, outside the
//           tag and data arrays, to 2 cache lines of block data and one merged
//           store word per pending miss. Miss parallelism bought by buffering
//           whole lines per miss is not available: it is wrong, not expensive.
//         * MEMORY-SIDE CONCURRENCY IS PINNED. M3 permits at most one
//           outstanding memory transaction. Widening the memory interface is
//           not a design choice here.
//         * A STORE MISS ALLOCATES. L4 says so explicitly -- write-around is
//           not a permitted cheaper policy.
//         * FILL ORDER IS PINNED. M1 fixes ascending word order, so
//           critical-word-first is out of scope (L3).
//
//   G4. WHAT IS ACTUALLY LEFT, and it is where the whole PPA difference comes
//       from. The contract fixes WHAT is answered and IN WHAT ORDER; it says
//       nothing about HOW:
//
//         * replacement policy, which is free (L1) and differs in cost;
//         * how outstanding misses are tracked -- a queue, a register file, a
//           CAM, anything -- subject to C1's floor and C4's ceiling (L2);
//         * how the tag and data arrays are organised and banked;
//         * pipeline depth and hit latency, which are unconstrained (L6);
//         * whether `req_ready_o` is combinational on `req_valid_i` (L5).
//
//       A submission that meets the pinned period with less area and less power
//       scores better. Meeting it comfortably buys nothing extra: there is no
//       credit for slack beyond zero, because the period is fixed for everyone.
//
// =============================================================================

module nonblocking_dcache #(
  parameter int unsigned DATA_W     = 32,   // {32, 64}
  parameter int unsigned SETS       = 16,   // {8, 16}
  parameter int unsigned WAYS       = 4,    // {2, 4}
  parameter int unsigned MAX_MISSES = 8     // {2, 8}
) (
  input  logic                     clk_i,
  input  logic                     rst_ni,        // active low, asynchronous assert

  // ---- request ------------------------------------------------------------
  input  logic                     req_valid_i,
  output logic                     req_ready_o,
  input  logic [3:0]               req_id_i,      // ID_W = 4
  input  logic                     req_op_i,      // 0 = LOAD, 1 = STORE
  input  logic [31:0]              req_addr_i,    // ADDR_W = 32, byte address, word aligned
  input  logic [DATA_W-1:0]        req_data_i,    // STORE data
  input  logic [(DATA_W/8)-1:0]    req_mask_i,    // STORE byte enables

  // ---- response -----------------------------------------------------------
  output logic                     rsp_valid_o,
  input  logic                     rsp_ready_i,
  output logic [3:0]               rsp_id_o,
  output logic [DATA_W-1:0]        rsp_data_o,

  // ---- memory: request ----------------------------------------------------
  output logic                     mem_req_valid_o,
  input  logic                     mem_req_ready_i,
  output logic                     mem_req_we_o,  // 0 = fill, 1 = writeback
  output logic [31:0]              mem_req_addr_o,// block aligned

  // ---- memory: fill data in ----------------------------------------------
  input  logic                     mem_rd_valid_i,
  output logic                     mem_rd_ready_o,
  input  logic [DATA_W-1:0]        mem_rd_data_i,

  // ---- memory: writeback data out ----------------------------------------
  output logic                     mem_wr_valid_o,
  input  logic                     mem_wr_ready_i,
  output logic [DATA_W-1:0]        mem_wr_data_o
);

  // BLOCK_WORDS is fixed at 4 by this contract. It is a localparam rather than
  // a parameter because it is never swept, and an unswept parameter claims a
  // flexibility no check enforces.
  localparam int unsigned BLOCK_WORDS = 4;

  // Implementation goes here.

endmodule
```
