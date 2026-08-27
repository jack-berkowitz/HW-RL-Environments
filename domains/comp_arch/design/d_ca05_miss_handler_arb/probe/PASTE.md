# d_ca05 — multi-requester cache miss handler

Implement `miss_handler_arb` in synthesisable SystemVerilog.

The unit sits behind a data cache's controllers. Several requesters raise misses;
it arbitrates them, fetches cache lines over AXI, answers uncached accesses on a
separate bypass path, walks the array to flush it, and performs atomics. It also
answers, every cycle, whether a presented address collides with the refill
currently in flight.

Five things about this contract are worth reading before choosing an
architecture:

* **The G clauses set out how you are graded**, in what order, and which
  optimisation levers are already closed. Read them first.
* **Arbitration is strict lowest-index priority and it starves.** A
  continuously-requesting low port locks out every higher port indefinitely.
  This is the contract, not a defect to improve on — a round-robin arbiter fails.
  What is required is that every port be *servable*, not that service be fair.
* **The two MSHR match outputs overlap.** An address match *implies* an index
  match; they are not alternatives, and the requester whose own miss is in flight
  is *not* excluded from either. Both are easy to get wrong for reasons that look
  like care.
* **The flush's cost is part of the contract, not just its effect.** The walk is
  observable on the array port and the access count is pinned. A design that
  reaches the same final state in fewer accesses fails.
* **A flush requested in the same cycle as an atomic is never acknowledged.** The
  flush happens; `flush_ack_o` does not pulse. This is not reachable by writing
  the obvious thing, and it is invisible unless you exercise flush and atomic
  together.

Everything asserted below about arbitration, matching, flush behaviour and
acknowledgement was **measured** against a hardware anchor rather than assumed
from convention. Where the anchor's own comments disagree with what it does, the
contract follows what it does, and says so.

**One self-contained file** containing only `module miss_handler_arb`, with the
exact port list below. Import `miss_handler_arb_pkg` and declare nothing else
outside the module.

**The types are in `spec/miss_handler_arb_pkg.sv`, which ships with this file and
is part of the problem statement.** It holds the AXI channel structs, the cache
line and byte-enable types, the request and atomic structs, and every geometry
constant as a concrete number. Import it and you need nothing else — no vendor
packages, no AXI library, no knowledge of where the anchor came from.

The contract cites a few repository file names in passing; those are provenance
notes for maintainers, not documents you need.

First, the package the port list is written in. It is SUPPLIED and compiled for
you — read it, import it, do not reproduce it.

```systemverilog
// =============================================================================
// miss_handler_arb_pkg.sv -- the types d_ca05's contract is written in.
//
// SHIPS WITH THE TASK and is part of its text. A submission imports this package
// and needs nothing else: no CVA6 configuration package, no AXI library, no
// knowledge of where the anchor came from. Every width below is a CONCRETE
// NUMBER measured from the reference configuration rather than a parameter to
// be resolved -- if it were a parameter, a submission would have to reconstruct
// the same configuration to get the same widths, and would be graded partly on
// having done that.
// =============================================================================

package miss_handler_arb_pkg;

  // ---- cache geometry, fixed by P1 -----------------------------------------
  localparam int unsigned SET_ASSOC    = 8;
  localparam int unsigned INDEX_WIDTH  = 12;
  localparam int unsigned TAG_WIDTH    = 44;
  localparam int unsigned LINE_WIDTH   = 128;
  localparam int unsigned OFFSET_WIDTH = 4;
  localparam int unsigned NUM_WORDS    = 256;   // 2^(INDEX_WIDTH-OFFSET_WIDTH)

  // ---- AXI geometry, fixed by P1 -------------------------------------------
  localparam int unsigned AXI_ID_W   = 4;
  localparam int unsigned AXI_ADDR_W = 64;
  localparam int unsigned AXI_DATA_W = 64;
  localparam int unsigned AXI_USER_W = 1;

  typedef logic [AXI_ID_W-1:0]     axi_id_t;
  typedef logic [AXI_ADDR_W-1:0]   axi_addr_t;
  typedef logic [AXI_DATA_W-1:0]   axi_data_t;
  typedef logic [AXI_DATA_W/8-1:0] axi_strb_t;
  typedef logic [AXI_USER_W-1:0]   axi_user_t;

  // ---- AXI channels --------------------------------------------------------
  // Field-for-field the AXI4 channels, including `atop`: an atomic memory
  // operation leaves this unit as an AXI ATOP write, and the memory performs
  // it. See A7.
  typedef struct packed {
    axi_id_t     id;
    axi_addr_t   addr;
    logic [7:0]  len;
    logic [2:0]  size;
    logic [1:0]  burst;
    logic        lock;
    logic [3:0]  cache;
    logic [2:0]  prot;
    logic [3:0]  qos;
    logic [3:0]  region;
    logic [5:0]  atop;
    axi_user_t   user;
  } axi_aw_t;

  typedef struct packed {
    axi_id_t     id;
    axi_addr_t   addr;
    logic [7:0]  len;
    logic [2:0]  size;
    logic [1:0]  burst;
    logic        lock;
    logic [3:0]  cache;
    logic [2:0]  prot;
    logic [3:0]  qos;
    logic [3:0]  region;
    axi_user_t   user;
  } axi_ar_t;

  typedef struct packed {
    axi_data_t data; axi_strb_t strb; logic last; axi_user_t user;
  } axi_w_t;

  typedef struct packed {
    axi_id_t id; logic [1:0] resp; axi_user_t user;
  } axi_b_t;

  typedef struct packed {
    axi_id_t id; axi_data_t data; logic [1:0] resp; logic last; axi_user_t user;
  } axi_r_t;

  typedef struct packed {
    axi_aw_t aw; logic aw_valid;
    axi_w_t  w;  logic w_valid;
    logic    b_ready;
    axi_ar_t ar; logic ar_valid;
    logic    r_ready;
  } axi_req_t;

  typedef struct packed {
    logic    aw_ready; logic ar_ready; logic w_ready;
    logic    b_valid;  axi_b_t b;
    logic    r_valid;  axi_r_t r;
  } axi_rsp_t;

  // ---- the cache array ------------------------------------------------------
  typedef struct packed {
    logic [TAG_WIDTH-1:0]  tag;
    logic [LINE_WIDTH-1:0] data;
    logic                  valid;
    logic                  dirty;
  } cache_line_t;

  typedef struct packed {
    logic [(TAG_WIDTH+7)/8-1:0]  tag;
    logic [(LINE_WIDTH+7)/8-1:0] data;
    logic [SET_ASSOC-1:0]        vldrty;
  } cl_be_t;

  // ---- a requester's miss request -------------------------------------------
  // 141 bits. `bypass` selects the bypass path over a cacheline refill; the two
  // are arbitrated separately (A2, A3).
  typedef struct packed {
    logic        valid;
    logic [63:0] addr;
    logic [7:0]  be;
    logic [1:0]  size;
    logic        we;
    logic [63:0] wdata;
    logic        bypass;
  } miss_req_t;

  // ---- atomics ---------------------------------------------------------------
  typedef enum logic [3:0] {
    AMO_NONE = 4'b0000, AMO_LR   = 4'b0001, AMO_SC   = 4'b0010, AMO_SWAP = 4'b0011,
    AMO_ADD  = 4'b0100, AMO_AND  = 4'b0101, AMO_OR   = 4'b0110, AMO_XOR  = 4'b0111,
    AMO_MAX  = 4'b1000, AMO_MAXU = 4'b1001, AMO_MIN  = 4'b1010, AMO_MINU = 4'b1011,
    AMO_CAS1 = 4'b1100, AMO_CAS2 = 4'b1101
  } amo_t;

  typedef struct packed {
    logic        req;
    amo_t        amo_op;
    logic [1:0]  size;
    logic [63:0] operand_a;   // address
    logic [63:0] operand_b;   // data
  } amo_req_t;

  typedef struct packed {
    logic        ack;
    logic [63:0] result;
  } amo_resp_t;

endpackage
```

```systemverilog
// =============================================================================
// d_ca05 -- miss_handler_arb : multi-requester cache miss handler
// =============================================================================
//
// EVERY CLAUSE BELOW WAS MEASURED. The anchor is CVA6's miss_handler, and the
// probes are in tb/audit/ with the evidence tables in MEASUREMENTS.md. Three
// clauses contradict what the anchor's own COMMENTS say, and in each case the
// measurement is the contract:
//
//   * bypass arbitration is STRICT LOWEST-INDEX PRIORITY and starves higher
//     ports indefinitely. The task catalog promised "no requester starvation"
//     until 55c40c5; a no-starvation clause would be failed by the anchor.
//   * an address match and an index match assert TOGETHER, not as alternatives,
//     although the anchor's comment reads "same as previous, but checking only
//     the index".
//   * the requester being served is NOT excluded from the match outputs,
//     although the anchor's comment says "exclude the unit currently being
//     served". Comment and code disagree; the code is what the anchor does.
//
// -----------------------------------------------------------------------------
// THE INTERFACE
// -----------------------------------------------------------------------------
// Types come from spec/miss_handler_arb_pkg.sv, which ships with this task.
// Import it and you need nothing else -- no vendor packages, no AXI library.
module miss_handler_arb
  import miss_handler_arb_pkg::*;
#(
    parameter int unsigned NR_PORTS = 4     // scored at 4; see P2
) (
    input  logic clk,
    input  logic rst_n,                     // active low, asynchronous assert

    // ---- flush ---------------------------------------------------------------
    input  logic flush_i,                   // flush request
    output logic flush_ack_o,               // one-cycle acknowledgement -- F5-F8
    output logic miss_o,                    // performance counter output
    input  logic busy_i,                    // a requester is mid-operation

    // ---- requesters ----------------------------------------------------------
    input  logic [NR_PORTS-1:0][$bits(miss_req_t)-1:0] miss_req_i,
    output logic [NR_PORTS-1:0]       bypass_gnt_o,
    output logic [NR_PORTS-1:0]       bypass_valid_o,
    output logic [NR_PORTS-1:0][63:0] bypass_data_o,
    output logic [NR_PORTS-1:0]       miss_gnt_o,
    output logic [NR_PORTS-1:0]       active_serving_o,
    output logic [63:0]               critical_word_o,
    output logic                      critical_word_valid_o,

    // ---- MSHR interrogation -- F3 --------------------------------------------
    input  logic [NR_PORTS-1:0][55:0] mshr_addr_i,
    output logic [NR_PORTS-1:0]       mshr_addr_matches_o,
    output logic [NR_PORTS-1:0]       mshr_index_matches_o,

    // ---- atomics -------------------------------------------------------------
    input  amo_req_t  amo_req_i,
    output amo_resp_t amo_resp_o,

    // ---- AXI: bypass path (single accesses and atomics) ----------------------
    output axi_req_t axi_bypass_req_o,
    input  axi_rsp_t axi_bypass_rsp_i,

    // ---- AXI: refill path (cacheline reads and evictions) --------------------
    output axi_req_t axi_data_req_o,
    input  axi_rsp_t axi_data_rsp_i,

    // ---- the cache array -----------------------------------------------------
    output logic [SET_ASSOC-1:0]        req_o,
    output logic [INDEX_WIDTH-1:0]      addr_o,
    output cache_line_t                 data_o,
    output cl_be_t                      be_o,
    input  cache_line_t [SET_ASSOC-1:0] data_i,
    output logic                        we_o
);
endmodule
//
// -----------------------------------------------------------------------------
// F -- THE FUNCTIONAL CONTRACT
// -----------------------------------------------------------------------------
// F1. TWO REQUEST PATHS, SEPARATELY ARBITRATED. Each requester presents a
//     miss_req_t. `bypass` selects the path:
//       bypass = 1 -> a single uncached access on axi_bypass_*, answered on
//                     bypass_gnt_o / bypass_valid_o / bypass_data_o;
//       bypass = 0 -> a cacheline refill on axi_data_*, answered on miss_gnt_o,
//                     with the line written into the array.
//
// F2. BYPASS ARBITRATION IS STRICT LOWEST-INDEX PRIORITY, AND IT STARVES.
//
//     With all four requesters asserting continuously, port 0 took 20 of 20
//     grants over 60 cycles. With port 0 idle, port 1 took 20 of 20 and ports 2
//     and 3 took NONE. A continuously-requesting low port starves every higher
//     port indefinitely.
//
//     THIS IS THE CONTRACT, NOT A DEFECT TO IMPROVE ON. A round-robin or
//     least-recently-granted arbiter is WRONG here and fails T2. The requirement
//     is that every port be SERVABLE -- port 1 is granted the moment port 0 goes
//     idle -- not that service be fair.
//
// F3. THE MSHR MATCH OUTPUTS, AND THEY OVERLAP.
//
//     While a cacheline refill is in flight, the unit holds that miss's address.
//     For each requester i, against the address presented on mshr_addr_i[i]:
//
//       mshr_addr_matches_o[i]  = in_flight && mshr_addr_i[i][55:4] == miss[55:4]
//       mshr_index_matches_o[i] = in_flight && mshr_addr_i[i][11:4] == miss[11:4]
//
//     TWO CONSEQUENCES, BOTH MEASURED, BOTH EASY TO GET WRONG:
//
//     (a) THE INDEX FIELD IS A SUBSET OF THE ADDRESS FIELD, so an address match
//         IMPLIES an index match. They are NOT alternatives. A requester
//         presenting the identical address gets BOTH outputs high. An
//         implementation that treats "matches the index only" as a separate
//         case, and clears the index output when the full address matches,
//         fails T3.
//
//     (b) THE REQUESTER WHOSE MISS IS IN FLIGHT IS NOT EXCLUDED. If port 0's
//         miss is being served and port 0 presents that same address, port 0's
//         match outputs are BOTH high. Excluding it is a plausible reading and
//         is wrong.
//
//     Both outputs are ZERO for every port when no refill is in flight, and
//     return to zero once the refill retires.
//
// F4. THE FLUSH WALK IS OBSERVABLE ON THE ARRAY PORT, AND ITS COST IS PART OF
//     THE CONTRACT. A flush visits every one of the NUM_WORDS = 256 sets exactly
//     once, in ascending order, addresses 0x000 to 0xff0 stepping by
//     2^OFFSET_WIDTH = 16, asserting be_o.vldrty for ALL SET_ASSOC = 8 ways.
//
//     Measured: 512 array requests of which 256 are writes -- one read and one
//     write per set -- and 513 cycles from flush_i to idle.
//
//     A design that reaches the same final cache state in a different number of
//     array accesses is DISTINGUISHABLE on the array port and fails T4. This is
//     deliberate: the array port is how a cache's flush cost is paid, and a task
//     that scored only the end state would let a submission invent a broadcast
//     invalidate the hardware does not have.
//
// F5. A GENUINE FLUSH ACKNOWLEDGES. flush_i asserted while the unit is idle
//     starts the walk of F4, and flush_ack_o pulses for exactly one cycle when
//     the walk completes.
//
// F6. AN ATOMIC FORCES A FULL FLUSH BEFORE IT IS SERVED. amo_req_i.req asserted
//     with busy_i low sends the unit into the flush walk of F4 FIRST; only when
//     the cache is clean is the atomic issued. The atomic leaves on the bypass
//     AXI port as a write with `aw.atop` set, and the memory performs the
//     operation -- see A7. amo_resp_o.ack pulses with the result.
//
// F7. THE AMO-INDUCED FLUSH DOES NOT ACKNOWLEDGE. That walk is a side effect of
//     the atomic and nobody requested it, so flush_ack_o stays low for its whole
//     duration. Measured: zero pulses across a complete AMO sequence, against
//     exactly one for the genuine flush of F5.
//
// F8. THE CORNER, AND IT IS THE CLAUSE THIS TASK EXISTS FOR.
//
//     flush_i AND amo_req_i.req asserted IN THE SAME CYCLE produce NO
//     ACKNOWLEDGEMENT AT ALL. The flush happens -- the walk of F4 runs in full
//     and the cache is left clean -- and flush_ack_o never pulses. A requester
//     that waits on flush_ack_o waits forever.
//
//     Measured: zero pulses, with the unit returning to idle after 495 cycles,
//     so the walk demonstrably occurred.
//
//     Implement this deliberately. It is not reachable by writing the obvious
//     thing, and it is invisible unless flush and atomic are exercised TOGETHER.
//
// F9. AN INCOMING MISS DEFERS A PENDING ATOMIC. If a requester raises a
//     non-bypass miss in the same cycle the atomic is taken, the miss wins: the
//     unit serves the refill and the atomic's pending state is cleared, so the
//     atomic is re-evaluated afresh rather than resumed. Atomics are the lowest
//     priority work this unit does.
//
// -----------------------------------------------------------------------------
// A -- PROTOCOL AND TIMING
// -----------------------------------------------------------------------------
// A1. AXI4 on both ports, as master. Standard valid/ready on all five channels;
//     no channel may withdraw a valid before its ready.
// A2. THE BYPASS PORT issues single-beat accesses. The REFILL PORT issues
//     cacheline reads whose length follows LINE_WIDTH / AXI_DATA_W, and
//     evictions of dirty lines.
// A3. critical_word_o / critical_word_valid_o forward the requested word of a
//     refill as it arrives, ahead of the line being written to the array.
// A4. busy_i GATES BOTH FLUSH AND ATOMIC. Neither F5's walk nor F6's is entered
//     while busy_i is high. It does not gate miss handling.
// A5. RESET is asynchronous-assert, synchronous-release. After release the unit
//     is idle, no MSHR is in flight, both match outputs are low, and flush_ack_o
//     and amo_resp_o.ack are low. A reset mid-operation discards; it does not
//     drain.
// A6. THE ARRAY PORT is a synchronous read/write port: req_o selects ways,
//     addr_o the set, we_o the direction, be_o the byte enables including the
//     per-way vldrty bits, and data_i returns all SET_ASSOC lines of the set.
// A7. AN ATOMIC IS AN AXI ATOP AND THE MEMORY PERFORMS IT. The unit issues the
//     operation encoded in aw.atop and consumes BOTH a B beat and an R beat --
//     the R carries the pre-operation value, which becomes amo_resp_o.result. A
//     design that waits only for B hangs, and this is checked (T7).
//
// -----------------------------------------------------------------------------
// P -- PINNED, AND WHAT IS FREE
// -----------------------------------------------------------------------------
// P1. FIXED BY THE PACKAGE, not by a submission: SET_ASSOC 8, INDEX_WIDTH 12,
//     TAG_WIDTH 44, LINE_WIDTH 128, OFFSET_WIDTH 4, NUM_WORDS 256, and AXI
//     id/addr/data widths 4/64/64. These are concrete numbers so that a
//     submission does not have to reconstruct a configuration to get them right.
// P2. NR_PORTS IS SCORED AT 4. It is a parameter because the arbitration must be
//     written against a count rather than unrolled, but only 4 is measured and
//     only 4 is scored -- d_nw01's lesson is that a pass at a low setting is not
//     capability evidence, and the corollary is that an unmeasured setting is
//     not a scored one.
// P3. FREE, AND IT MOVES PPA. How the flush walk's two array accesses per set
//     are sequenced; whether the two AXI paths share a datapath; how the MSHR
//     comparators are built, given that F3(a) means the index comparison is a
//     sub-range of the address comparison and can share silicon; and the depth of
//     any pipelining inside the FSM.
//
// -----------------------------------------------------------------------------
// T -- WHAT IS CHECKED
// -----------------------------------------------------------------------------
// T1. THE SCORED SURFACE is every output port, sampled each cycle, compared
//     against the reference. Internal state is not read.
// T2. ARBITRATION (F2): all four ports requesting, then port 0 idle. The grant
//     counts must match, including the zeros -- a fair arbiter fails here.
// T3. MSHR MATCHING (F3): the four-row matrix, with a miss in flight, without
//     one, and after it retires. Both (a) and (b) are separate checks.
// T4. THE FLUSH WALK (F4): array request and write counts, the address sequence,
//     and the vldrty pattern.
// T5. FLUSH ACKNOWLEDGEMENT (F5, F7, F8) AND THE AMO-INDUCED WALK (F6): the
//     genuine flush, the AMO-induced flush, and the two asserted together. The
//     third is the discriminating one for acknowledgement.
//
//     F6 IS CHECKED ON THE ARRAY PORT, NOT ON THE ACKNOWLEDGEMENT, and it has
//     to be. "The AMO-induced flush acknowledges zero times" is what F7
//     requires AND what a design that never flushed at all produces -- the same
//     value for conformance and for the violation. So the walk is counted where
//     F4 says a flush's cost is paid: at least one full walk of 512 array
//     requests and 256 writes, with vldrty asserted for all ways, during the
//     AMO sequence.
//
//     A FLOOR RATHER THAN AN EQUALITY. The reference performs TWO full walks
//     here (1024 requests, 512 writes) and nothing in this contract explains
//     the second, so requiring it would pin an unexplained implementation
//     detail. F6 asks that the atomic flush first; one complete walk is that.
//     The measured count is reported as a METRIC.
// T6. ATOMIC ORDERING (F9): a miss raised in the same cycle as the atomic.
// T7. THE ATOP HANDSHAKE (A7): the testbench's memory returns B and R for an
//     atomic write. A design that waits only for B does not complete and is
//     detected as a hang rather than as a wrong value.
// T8. RESET MID-OPERATION (A5), with the antecedent gated -- the check asserts
//     that work was actually in flight before the reset, so it cannot pass
//     vacuously on a unit that happened to be idle.
// T9. NO CHECK MAY PASS UNEXERCISED. Every clause above carries an exercise
//     counter and the run FAILS if any counter is zero.
//
// T10. THE SUBMISSION MUST ELABORATE UNDER BOTH slang AND Verilator, and passing
//     simulation is not sufficient. The synthesis frontend is slang, so a
//     construct Verilator accepts silently can be a hard error there -- in which
//     case a correct submission produces NO PPA NUMBER AT ALL. That is the worst
//     shape a failure can take here: it reads as a missing measurement rather
//     than as a rejected submission.
//
//     THE REJECTION THIS MOST OFTEN PRODUCES is a variable declared after a
//     statement inside a begin/end block:
//
//         error: declaration must come before all statements in the block
//
//     slang enforces the LRM rule that every declaration in a block precedes
//     every statement in that block. VERILATOR DOES NOT DIAGNOSE THE VIOLATION,
//     so the file simulates clean and then yields nothing. Declare every
//     variable at the top of the block that uses it, or at module scope, before
//     any assignment, loop or $display in that block.
//
//     This is measured history, not caution: ten run records across four tasks
//     in this repository were killed by exactly that error, nine of them from
//     one model.
//
// -----------------------------------------------------------------------------
// G -- GRADING
// -----------------------------------------------------------------------------
// G1. THE ORDER, and correctness is a GATE rather than a weighting.
//     1. CORRECTNESS. Bit-exact on the T1 surface against the reference. There
//        is no partial credit and no tolerance.
//     2. THE GATE. A submission that fails correctness, OR THAT FAILS TO BUILD,
//        produces NO PPA NUMBER AT ALL, recorded as a failure rather than as a
//        missing measurement, and scoring zero on every PPA axis. A design the
//        simulator accepts and the synthesis frontend rejects scores full
//        correctness and no PPA.
//     3. PPA, measured only for submissions that passed, ONCE AT A PINNED CLOCK
//        PERIOD rather than by sweeping for a maximum frequency, so every
//        submission is compared at one frequency.
//
//        THE PINNED PERIOD IS NOT YET SET. It is derived as 1.5x the reference
//        implementation's own measured period, rounded up to the next 0.25 ns,
//        from a single reference Fmax sweep -- AND THAT SWEEP HAS NOT BEEN RUN.
//        No PPA number may be reported for d_ca05 until it is. Recorded as
//        missing rather than filled with a plausible value.
//
//        The period does not move in response to what is submitted. Pinning the
//        row at the slowest submission's own Fmax rewards a slow design by
//        moving the measurement toward the period where its own area looks best.
//
// G2. WHAT IS COMPARED: area post-synthesis and post-place-and-route, and power
//     at the pinned period.
//
//     TIMING CLOSURE IS A GATE, NOT AN AXIS, AND SLACK IS NOT SCORED. A build
//     that misses the pinned period yields no comparable area or power figure --
//     an area number from a build that did not close is not a smaller design, it
//     is an unfinished one -- so its PPA is withheld rather than reported. Slack
//     above zero earns nothing either: meeting timing with margin is bought WITH
//     area, and area already charges for that.
//
//     THERE IS A CYCLE AXIS ON THIS TASK, unlike d_ai04, and F4 is why. The
//     flush walk's 512 array accesses are a real cost that a design can trade
//     against area -- a narrower array port, or a walk that reads and writes in
//     one access, changes both. Total cycles over the scored sequence is
//     reported alongside area, and the two are never combined.
//
// G3. WHAT IS NOT AVAILABLE TO OPTIMISE.
//       * THE ARBITRATION ORDER. F2 pins strict lowest-index priority. Fairness
//         is not an improvement here, it is a specification violation.
//       * THE MATCH SEMANTICS. F3 pins both comparisons and their overlap.
//       * THE FLUSH'S OBSERVABLE COST. F4 pins the access count and pattern, not
//         merely the final state.
//       * THE ACKNOWLEDGEMENT RULE. F5, F7 and F8 pin exactly when flush_ack_o
//         may pulse, including the case where it must not.
//
// G4. WHAT IS ACTUALLY LEFT. The FSM's sequencing and the comparator structure:
//       * THE MSHR COMPARATORS. F3(a) makes the index comparison a sub-range of
//         the address comparison. Sharing that silicon, or building two
//         independent comparators, are both conforming and are not the same area.
//       * THE TWO AXI PATHS. Separate adapters, or one shared with an arbiter,
//         differ in area and in whether a bypass access can proceed during a
//         refill.
//       * THE FLUSH SEQUENCER. Two array accesses per set is pinned; how the
//         address counter and the way-enable are generated is not.
//       * FSM PIPELINING, which trades cycles for period.
//
//     A submission that meets the pinned period with less area and less power
//     scores better. There is no credit for slack beyond zero.
//
// G5. THERE IS NO SINGLE COMBINED SCORE, and that is deliberate rather than
//     unfinished. Nothing in this project establishes what a unit of capability
//     is worth in square micrometres, so no weighted sum is computed, and none
//     should be inferred from the phrase "scores better" above. Each axis is
//     reported separately, and a submission that wins on one and loses on
//     another is reported as exactly that.
//
//     WHAT A SUBMISSION IS COMPARED AGAINST. The reference implementation, built
//     from the same contract at the same pinned period and the same scored
//     configuration, and the other submissions to this task on the same axes.
//     The reference is an ANCHOR, not a target: beating it is not required and
//     losing to it is not disqualifying.
//
//     EVERY REPORTED METRIC CARRIES A ROLE:
//       * FIXED -- the contract requires a value. Deviating is a specification
//         violation and fails correctness.
//       * CHOICE -- the contract leaves it free and it moves PPA. Where a
//         submission chose differently from the reference, the area ratio is
//         marked NOT LIKE-FOR-LIKE rather than presented as a quality gap.
//       * CAPABILITY -- more is better and area buys it. Reported both raw and
//         per unit of area.
//
//     ON THIS TASK THERE IS NO CAPABILITY COLUMN. P1 pins the geometry and P2
//     pins the port count, so there is no dimension along which a submission may
//     do MORE. It is not reported rather than reported as zero.
// =============================================================================
```
