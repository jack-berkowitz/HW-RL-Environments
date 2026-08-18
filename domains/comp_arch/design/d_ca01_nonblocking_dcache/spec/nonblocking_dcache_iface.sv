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
//   R4. RESPONSE ORDER IS FREE. Responses may be returned in any order with
//       respect to request order. Returning them strictly in order is
//       conformant and is neither rewarded nor penalised.
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
//       AUTHORITY: stated task intent -- this is the definition of
//       non-blocking, and without it the parameter in C1 is the only thing
//       separating this from a blocking cache with a queue in front.
//
//   C3. FORWARD PROGRESS. With requests continuously offered and memory always
//       eventually responding, every accepted request is eventually answered,
//       and no id is starved while others are being served.
//       AUTHORITY: stated task intent.
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
//   L4. WHETHER A STORE MISS ALLOCATES IS FREE -- as far as the memory port is
//       concerned. Write-allocate and write-through both satisfy R5, and the
//       checker does not inspect memory traffic for stores. (The task title
//       says write-allocate; that describes the intended design, and R5 is what
//       is actually enforced.)
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
