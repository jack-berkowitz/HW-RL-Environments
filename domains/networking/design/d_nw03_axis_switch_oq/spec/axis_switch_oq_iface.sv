// =============================================================================
// axis_switch_oq_iface.sv  --  PORT DEFINITION ONLY (no implementation)
// =============================================================================
// Task: implement an OUTPUT-QUEUED stream switch. S_COUNT input streams, M_COUNT
// output streams, frames routed by a destination field carried on the input.
//
// *** THE DIFFICULTY IS CONCURRENCY, NOT ROUTING. ***
//
//   1. DISJOINT PAIRS MUST PROCEED IN PARALLEL. Four inputs sending to four
//      different outputs must all make progress at once. A switch that routes
//      every frame correctly through one shared datapath is correct on every
//      individual frame and is not a switch -- it fails C1, and C1 is a RATE
//      measurement, not an output comparison.
//
//   2. NO HEAD-OF-LINE BLOCKING ACROSS INPUTS. An input whose destination is
//      busy must not stop a different input reaching a free output.
//
//   3. FRAME ATOMICITY. Once an output starts a frame it finishes that frame.
//      Beats from two inputs may never interleave on one output.
//
//   4. FORWARD PROGRESS. Every accepted frame is eventually delivered and no
//      input is starved while others are served. Not a data property; no amount
//      of output comparison finds it.
//
// NO INTERNAL STRUCTURE IS REQUIRED OR IMPLIED. Nothing here names a queue, a
// crossbar, an arbiter or a buffer. Only observable behaviour is contractual.
//
// -----------------------------------------------------------------------------
// PARAMETERS -- all three swept; each is bound by a check
// -----------------------------------------------------------------------------
//   S_COUNT   number of input streams    legal {2, 4}
//   M_COUNT   number of output streams   legal {2, 4}
//   DATA_W    stream width in bits       legal {8, 32}
//
//   Derived, and NOT parameters: KEEP_W = DATA_W/8, DEST_W = $clog2(M_COUNT).
//   A quantity that is never swept is a constant; declaring it a parameter
//   would claim a flexibility nothing binds.
//
// -----------------------------------------------------------------------------
// S0. SCORED CONFIGURATION -- rule 18
// -----------------------------------------------------------------------------
//   *** S_COUNT = 4, M_COUNT = 4, DATA_W = 32. ***
//
//   PPA, latency and throughput are measured HERE AND NOWHERE ELSE. Correctness
//   is checked across all 8 legal combinations.
//
//   CHOSEN SO THE CAPABILITY CHECK CAN DISCRIMINATE, which is a separate
//   question from engineering merit and is the one that decides it here. At
//   2x2, a design that serialises all traffic through one datapath produces
//   nearly the same observable behaviour as a correct one: two disjoint pairs
//   at a 2x aggregate gap is inside the noise of any plausible buffering
//   choice. At 4x4 the gap is 4x and C1's floor sits cleanly between them.
//   A scored configuration where a correct design and a capability-reduced
//   design produce the same checker output measures nothing.
//
//   DATA_W = 32 rather than 8: at 8 bits KEEP_W is 1 and the partial-final-beat
//   case in R2 degenerates, so the narrow setting cannot exercise it.
//
// -----------------------------------------------------------------------------
// FRAMES AND ROUTING -- normative
// -----------------------------------------------------------------------------
//   R1. HANDSHAKE. A beat transfers on a rising clock edge where the stream's
//       valid and ready are both high. Once valid is asserted it stays asserted,
//       with data, keep, last and dest held stable, until the transfer
//       completes.
//       AUTHORITY: stated task intent -- the ordinary stream contract, stated so
//       stability is a contract term rather than an assumption.
//
//   R2. A FRAME is a run of beats on one input ending with `s_last_i` set.
//       `s_dest_i` is HELD CONSTANT for every beat of a frame and names the
//       output port index. `s_keep_i` marks which bytes of the beat carry data;
//       it is all-ones on every beat except possibly the last.
//       AUTHORITY: stated task intent.
//
//   R3. EVERY ACCEPTED FRAME IS DELIVERED EXACTLY ONCE, to the output named by
//       its `dest`, with its beats in order and its data and keep unmodified.
//       No loss, no duplication, no reordering within a frame.
//       AUTHORITY: stated task intent.
//
//   R4. FRAME ATOMICITY. Once an output emits the first beat of a frame it
//       emits the remaining beats of THAT frame before any beat of any other
//       frame. Beats from two inputs never interleave on one output.
//       AUTHORITY: stated task intent -- this is what makes the output a stream
//       rather than a multiplexed jumble, and it is the property a naive
//       per-beat arbiter breaks.
//
//   R6. A FRAME IS AT MOST 8 BEATS. The harness never offers a longer one.
//       AUTHORITY: this task's decision, recorded as such, and it is NOT
//       cosmetic. L2 leaves buffering free and explicitly permits a
//       store-and-forward design that buffers a whole frame before emitting
//       any of it -- and such a design cannot be built at all without a bound
//       on frame length. Without R6 the contract advertises a choice the
//       interface does not make buildable. Found by trying to construct the
//       store-and-forward design, not by reading L2.
//
//   R5. ORDER BETWEEN FRAMES FROM ONE INPUT TO ONE OUTPUT IS PRESERVED. Two
//       frames from the same input to the same output are delivered in the
//       order they were accepted. No ordering is promised between different
//       inputs, or between different outputs -- see L4.
//       AUTHORITY: stated task intent.
//
// -----------------------------------------------------------------------------
// CAPABILITY AND LIVENESS -- what this task measures
// -----------------------------------------------------------------------------
//   C1. DISJOINT PAIRS PROCEED IN PARALLEL. With every input backlogged to a
//       DIFFERENT output and every output continuously ready, the switch
//       sustains an aggregate delivery rate of at least 2 beats per cycle.
//       AUTHORITY: stated task intent -- this is the capability the port counts
//       claim, and a design that provides one shared datapath delivers one beat
//       per cycle however correct each frame is.
//
//       C1 IS ENFORCED ONLY WHERE IT CAN DISCRIMINATE -- at S_COUNT and M_COUNT
//       both 4, which is the scored configuration. At 2x2 the ceiling is 2.0
//       beats per cycle, so the floor would fail correct hardware; the rate is
//       reported there and is NOT capability evidence. A pass at the small
//       configuration says nothing about concurrency, exactly as a pass at the
//       low setting of an outstanding-transaction parameter says nothing about
//       capacity.
//
//       WHY AN ABSOLUTE RATE AND NOT A RATIO. A ratio between the concurrent
//       case and a single-pair baseline is blind to any defect that scales both
//       terms -- a blind round-robin grant throttles the baseline by exactly as
//       much as the concurrent case and the ratio never moves. That failure is
//       recorded on d_nw01, where a serialising design passed a ratio-shaped
//       concurrency check twice at 199%.
//
//   C2. NO HEAD-OF-LINE BLOCKING ACROSS INPUTS. With one output held not-ready
//       and an input backlogged to it, a different input must still deliver
//       frames to a ready output.
//       AUTHORITY: stated task intent.
//
//   C3. FORWARD PROGRESS. With frames continuously offered on every input and
//       every output eventually ready, every accepted frame is eventually
//       delivered, and no input goes unserved while others are being served.
//       AUTHORITY: stated task intent.
//
//   DELIVERY RATE AND LATENCY ARE REPORTED, NOT GATED, except for C1's floor
//   which is a capability threshold rather than a performance score. Per-frame
//   latency and per-port rates are emitted as METRIC: lines.
//
// -----------------------------------------------------------------------------
// L. WHAT IS NOT CONSTRAINED -- rule 12, named so it is not inferred
// -----------------------------------------------------------------------------
//   L1. ARBITRATION POLICY IS FREE. When two inputs target one output, which
//       goes first is a design choice. Round-robin, fixed priority, oldest-first
//       and random are all conformant -- SUBJECT TO C3, which forbids starving
//       an input indefinitely. Fixed priority that never serves a lower-priority
//       input under sustained load fails C3, not L1.
//
//   L2. BUFFERING IS FREE. Where frames are stored, how deep, and whether an
//       input is accepted before its output is available are all unconstrained.
//       A design may buffer whole frames, buffer nothing, or anything between.
//
//   L3. LATENCY IS FREE. Input-to-output delay is a design choice, reported as
//       a METRIC and never gated. A combinational path from input to output is
//       permitted; so is deep pipelining.
//
//   L4. ORDER ACROSS DIFFERENT OUTPUTS, AND BETWEEN DIFFERENT INPUTS, IS FREE.
//       R5 constrains one input to one output and nothing else. A frame accepted
//       later may be delivered earlier if it goes somewhere else.
//
//   L5. `s_ready_o` MAY DEPEND COMBINATIONALLY ON `s_valid_i`. The harness never
//       derives valid from ready, so a design that gates ready on valid cannot
//       deadlock against it. Named because the opposite rule is a common house
//       style and a submission should not have to guess.
//
//   L6. ACCEPTING A FRAME BEFORE ITS OUTPUT IS FREE IS PERMITTED, and so is
//       refusing to. Both are conformant; C2 constrains only that one blocked
//       input must not block a different input's progress to a free output.
//
// -----------------------------------------------------------------------------
// TOOL REQUIREMENTS
// -----------------------------------------------------------------------------
//   T1. THE SUBMISSION MUST ELABORATE UNDER BOTH slang AND Verilator.
//       Simulation uses Verilator; physical synthesis reads the same file with
//       slang. A file one accepts and the other rejects cannot be built.
//   T2. DECLARE EVERY VARIABLE BEFORE THE FIRST STATEMENT IN ITS PROCEDURAL
//       BLOCK. SystemVerilog forbids a declaration after a statement inside a
//       block; this is the most common compile failure here and the error text
//       names neither declarations nor placement.
//   T3. THE MODULE MUST BE NAMED `axis_switch_oq` with the exact port list
//       below, including port names.
//   T4. ONE SELF-CONTAINED FILE. No package, no include, no reference to
//       anything outside itself.
// =============================================================================

module axis_switch_oq #(
  parameter int unsigned S_COUNT = 4,   // {2, 4}
  parameter int unsigned M_COUNT = 4,   // {2, 4}
  parameter int unsigned DATA_W  = 32   // {8, 32}
) (
  input  logic                              clk_i,
  input  logic                              rst_ni,      // active low, synchronous deassert

  // ---- input streams, concatenated port-major ------------------------------
  input  logic [S_COUNT-1:0]                s_valid_i,
  output logic [S_COUNT-1:0]                s_ready_o,
  input  logic [S_COUNT*DATA_W-1:0]         s_data_i,
  input  logic [S_COUNT*(DATA_W/8)-1:0]     s_keep_i,
  input  logic [S_COUNT-1:0]                s_last_i,
  input  logic [S_COUNT*$clog2(M_COUNT)-1:0] s_dest_i,

  // ---- output streams, concatenated port-major -----------------------------
  output logic [M_COUNT-1:0]                m_valid_o,
  input  logic [M_COUNT-1:0]                m_ready_i,
  output logic [M_COUNT*DATA_W-1:0]         m_data_o,
  output logic [M_COUNT*(DATA_W/8)-1:0]     m_keep_o,
  output logic [M_COUNT-1:0]                m_last_o
);

  // Derived by this contract, not parameters.
  localparam int unsigned KEEP_W = DATA_W/8;
  localparam int unsigned DEST_W = $clog2(M_COUNT);

  // Implementation goes here.

endmodule
