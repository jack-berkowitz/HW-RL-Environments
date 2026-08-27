// =============================================================================
// async_fifo_cdc_iface.sv  --  PORT DEFINITION ONLY (no implementation)
// =============================================================================
// Task: implement an asynchronous FIFO that carries data across a clock domain
// crossing. The write port is clocked by `wr_clk`, the read port by `rd_clk`,
// and THE TWO CLOCKS ARE UNRELATED -- no fixed ratio, no phase relationship, no
// common source. Your design must be correct at every ratio, including ratios
// close to 1 where the two edges drift slowly past each other.
//
// This is the only two-clock task in the design set. Everything difficult about
// it follows from that: a multi-bit value sampled across the boundary while it
// is changing can be latched inconsistently, and no amount of data checking on
// one side alone will reveal it.
//
// -----------------------------------------------------------------------------
// PARAMETERS
// -----------------------------------------------------------------------------
//   DATA_W      : payload width in bits. Legal: 8, 32, 64. Every bit is
//                 carried and every bit is checked -- the payload varies across
//                 the full width, so dropping the upper half of a 64-bit word
//                 is caught.
//   LOG_DEPTH   : FIFO depth is 2**LOG_DEPTH entries. Legal: 2, 3, 4.
//                 Depth is a power of two by construction; do not support
//                 non-power-of-two depths.
//   SYNC_STAGES : number of synchroniser flops on each value crossing the
//                 boundary. Legal: 2, 3. THIS IS A REQUIRED DEPTH, NOT A HINT.
//                 It is checked through the one consequence that is visible in
//                 simulation: a beat cannot reach the read side until the write
//                 pointer has crossed SYNC_STAGES flops clocked by `rd_clk`, so
//                 the MINIMUM observed crossing latency must be at least
//                 SYNC_STAGES `rd_clk` cycles. A design that hard-codes two
//                 stages fails at SYNC_STAGES = 3.
//   Any other value of any parameter is ILLEGAL and need not be handled.
//
// -----------------------------------------------------------------------------
// PORTS AND HANDSHAKE
// -----------------------------------------------------------------------------
//   Standard valid/ready on each side, each in ITS OWN clock domain.
//   A beat transfers on a rising edge of that side's clock at which both valid
//   and ready are high.
//
//   H1. `wr_ready` MUST NOT depend combinationally on `wr_valid`, and
//       `rd_valid` MUST NOT depend combinationally on `rd_ready`. CHECKED: the
//       harness toggles `wr_valid` between clock edges and requires `wr_ready`
//       not to move.
//   H2. Once `wr_valid` is asserted the producer holds it, and holds `wr_data`
//       stable, until the beat is accepted. The checker honours this.
//   H3. When `rd_valid` is high and `rd_ready` is low, `rd_valid` must REMAIN
//       high and `rd_data` must remain STABLE until the beat is accepted.
//
// -----------------------------------------------------------------------------
// WHAT THE FIFO MUST DO
// -----------------------------------------------------------------------------
//   B1. CHECKED, AT REST. The capacity phase stops the reader, offers writes
//       until the design has refused for 64 consecutive cycles, and counts what
//       it accepted. With nothing draining, that count IS the design's total
//       storage, and it is compared against the ceiling below.
//
//       IT WAS NOT ALWAYS CHECKED, and the reason given is worth keeping
//       because the reason was correct -- about a different number. Occupancy
//       sampled on `wr_clk` while both sides run sees a stale `rd_idx` and
//       OVERSTATES, so a bound asserted on it would fail conforming designs.
//       That is true of the running occupancy estimate, which is COVERAGE ONLY
//       and must stay that way. It is NOT true of the at-rest count: with the
//       reader stopped and the writer refused, the synchroniser has converged
//       and the read pointer has not moved from where it started. The
//       testbench carries two occupancy numbers; the objection was written
//       about the live one and applied to both.
//
//       (d_nw03's B1 is also enforced; the same letter is still not the same
//       status across tasks.)
//
//       STORAGE BEYOND THE FIFO IS BOUNDED. The FIFO holds 2**LOG_DEPTH
//       entries. A design may add **at most 4 further beats of storage in
//       total** across both clock domains -- pipeline or output registers on
//       the read side, input registration on the write side. Storage beyond
//       that is NON-CONFORMING.
//
//       WHY THIS IS NOT A FLOOR. `capacity_beats_accepted` is REPORTED, and
//       more of it looks better: a design that adds prefetch stages accepts
//       more beats before backpressure and is credited for it, while the area
//       those stages cost is charged to nothing. Without a ceiling the metric
//       rewards spending rather than design.
//
//       WHY 4. Crossing a clock boundary needs registration on each side, and
//       an output register to break the read path; two stages per domain is
//       the architectural need, and 4 is that with room to spare. It is not
//       fitted to any implementation. Checked AFTER the number was chosen: the
//       vendored reference accepts 10 beats at depth 8, so it uses 2, and
//       every submission uses 0.
//
//       THE FIFO ITSELF IS NOT BOUNDED HERE -- LOG_DEPTH fixes it, and a
//       design must provide exactly that depth.
//
//   C1. NO LOSS. Every beat accepted on the write side is eventually delivered
//       on the read side.
//   C2. NO DUPLICATION. Delivered exactly once.
//   C3. ORDER PRESERVED. Beat N in is beat N out. This is a FIFO.
//   C4. NO OVERFLOW, AND THE DEPTH YOU WERE ASKED FOR. `wr_ready` must be low
//       whenever accepting another beat would overwrite an entry that has not
//       yet been read, and must never accept more than the FIFO can hold.
//       EQUALLY BINDING, AND CHECKED DIRECTLY: with the reader stopped
//       entirely, the FIFO must accept AT LEAST 2**LOG_DEPTH beats before it
//       backpressures. LOG_DEPTH is a required capacity, not a suggestion; a
//       design that builds a smaller FIFO than asked for fails even though it
//       loses no data. The count is observed entirely in the write domain, so
//       it is not the unmeasurable cross-domain occupancy.
//   C5. NO UNDERFLOW / NO PHANTOM DATA. `rd_valid` must be low unless a beat
//       written on the other side is genuinely available. It must NEVER assert
//       on the strength of a pointer value that is still in flight through the
//       synchronisers -- that is the classic false-empty/false-full bug and it
//       only appears at particular clock ratios.
//   C6. NOT A SEPARATE CHECK -- IT IS THE CONDITION THE OTHERS RUN UNDER. There
//       is no C6 message and there should not be one: the clock-ratio phases are
//       the axis along which every other check is repeated, so a design that is
//       correct only at one ratio fails whichever clause it actually breaks, at
//       the ratio that breaks it. Stated so C6 is not read as unchecked.
//
//       CORRECT AT ANY RATIO. All of the above hold for arbitrary, unrelated
//       `wr_clk` and `rd_clk` frequencies and phases. The checker exercises
//       fast-write/slow-read, slow-write/fast-read, near-equal-but-drifting,
//       and integer ratios in both directions.
//
// -----------------------------------------------------------------------------
// CDC REQUIREMENT -- normative, and the point of the task
// -----------------------------------------------------------------------------
//   Any multi-bit value that crosses between the domains must be encoded so
//   that AT MOST ONE BIT CHANGES per increment (a Gray code is the standard
//   choice), and must then be resynchronised through SYNC_STAGES flops in the
//   receiving domain before use.
//
//   Passing a plain binary counter through a synchroniser is INCORRECT even
//   though it will appear to work in a zero-delay simulation: several bits
//   change at once, and the receiving domain can latch a value that was never
//   architecturally present. Do not do it.
//
//   The payload itself does NOT need to be synchronised. It is written in the
//   source domain and only read once the pointer that covers it has safely
//   crossed, so it is already stable by construction.
//
// -----------------------------------------------------------------------------
// RESET -- read this carefully, it is the subtlest part of the contract
// -----------------------------------------------------------------------------
//   `wr_rst_n` and `rd_rst_n` are ACTIVE-LOW.
//
//   R1. THE TWO RESETS ARE ASSERTED SIMULTANEOUSLY. This is a power-on reset:
//       both domains go into reset together. You may rely on that.
//   R2. REPORTED UNDER R4/R5. A design that mishandles staggered release
//       surfaces as R4 -- wr_ready did not assert within 16 wr_clk cycles of
//       reset release -- or as R5, rd_valid asserted while rd_rst_n was still
//       low. R2 states the condition; R4/R5 is where failing to tolerate it is
//       reported.
//
//       DE-ASSERTION IS PER-DOMAIN AND NOT SIMULTANEOUS. `wr_rst_n` is released
//       synchronously to `wr_clk` and `rd_rst_n` synchronously to `rd_clk`, so
//       one side can leave reset several cycles before the other. Your design
//       must tolerate that: the side that comes out first must not emit or
//       accept anything that violates C1-C5 while the other is still held.
//   R3. WARM RESET IS OUT OF SCOPE. Resetting one domain while the other keeps
//       running is ILLEGAL, is never exercised, and its behaviour is
//       unconstrained. Do not spend hardware supporting it.
//   R4. Coming out of reset the FIFO is EMPTY: `rd_valid` == 0, and `wr_ready`
//       becomes 1 within 16 `wr_clk` cycles of `wr_rst_n` releasing.
//   R5. While `rd_rst_n` is low, `rd_valid` == 0.
//
// -----------------------------------------------------------------------------
// LATENCY AND THROUGHPUT
// -----------------------------------------------------------------------------
//   NEITHER IS CONSTRAINED AND NEITHER IS CHECKED. Crossing latency depends on
//   SYNC_STAGES and on the ratio between two unrelated clocks, so no fixed
//   number could be correct. Throughput likewise.
//
//   The only timing requirement is LIVENESS: with `wr_valid` held high and
//   `rd_ready` held high, the FIFO must not stall permanently. Concretely, a
//   beat accepted on the write side must become visible on the read side within
//   64 `rd_clk` cycles, and `wr_ready` must recover within 64 `wr_clk` cycles of
//   the read side draining.
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
//   T3. THE MODULE MUST BE NAMED `async_fifo_cdc` with the exact port list below,
//       including port names.
//   T4. ONE SELF-CONTAINED FILE. No package, no include, no reference to
//       anything outside itself.
// -----------------------------------------------------------------------------
// G. GRADING -- how a submission is judged, and against what
// -----------------------------------------------------------------------------
//   G1. THE ORDER. Correctness is a GATE, not a weighting.
//
//       1. CORRECTNESS, across every legal DATA_W / LOG_DEPTH / SYNC_STAGES
//          combination and at arbitrary, unrelated clock ratios per C6. Checked
//          against H1-H3, B1, C1-C6 and R1-R5. There is no partial credit: a
//          FIFO that drops a beat is not a small design, it is a broken one.
//
//       2. THE GATE. A submission that fails correctness at ANY legal
//          combination, or that fails to build, produces NO PPA NUMBER AT ALL.
//          It is recorded as a failure and scores zero on every PPA axis --
//          not as a missing measurement.
//
//       3. PPA, measured only for submissions that already passed, ONCE AT A
//          PINNED CLOCK PERIOD, at the scored configuration and nowhere else.
//          The pinned period is 4.25 ns on sky130hd. It is derived as 1.5x the
//          reference implementation's own measured period (2.8125 ns), rounded
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
//         * CAPACITY, as beats accepted before the write side stalls. This is a
//           CAPABILITY: more is better, it costs area, and it is reported both
//           raw and per unit of area so a shallower design is not rewarded
//           merely for holding less.
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
//         * DEPTH IS PINNED, NOT CHOSEN. C4 requires exactly the 2**LOG_DEPTH
//           beats you were asked for -- a shallower FIFO is wrong, and a deeper
//           one violates B1.
//         * STORAGE BEYOND THE FIFO HAS A CEILING. B1 bounds a design to at
//           most 4 beats held outside the FIFO proper. Throughput bought with
//           extra skid buffering is not available.
//         * THE HANDSHAKE IS PINNED. H1 forbids `wr_ready` depending
//           combinationally on `wr_valid`. The usual latency-for-area trade at
//           the interface is not on offer.
//         * SYNCHRONISER DEPTH IS A PARAMETER, NOT A CHOICE. SYNC_STAGES is
//           given. Removing a stage to shorten the crossing is not a smaller
//           design, it is a different and wrong one.
//
//   G4. WHAT IS ACTUALLY LEFT, and it is where the whole PPA difference comes
//       from. The contract fixes WHAT crosses and IN WHAT ORDER; it says
//       nothing about HOW:
//
//         * how the pointers are encoded and compared -- Gray, one-hot, or
//           otherwise -- and how full and empty are derived from them;
//         * how the storage array is built and whether it is registered or
//           inferred;
//         * how many beats of the permitted 4 are actually held outside the
//           FIFO, and where;
//         * crossing latency, which is a CHOICE reported as a metric and never
//           gated -- a design may cross faster or slower and pay for it in
//           area.
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

module async_fifo_cdc #(
    parameter int DATA_W      = 32,   // 8 / 32 / 64
    parameter int LOG_DEPTH   = 3,    // 2 / 3 / 4  -> depth 4 / 8 / 16
    parameter int SYNC_STAGES = 2     // 2 / 3
) (
    // ---- write domain ----
    input  logic              wr_clk,
    input  logic              wr_rst_n,
    input  logic              wr_valid,
    output logic              wr_ready,
    input  logic [DATA_W-1:0] wr_data,

    // ---- read domain ----
    input  logic              rd_clk,
    input  logic              rd_rst_n,
    output logic              rd_valid,
    input  logic              rd_ready,
    output logic [DATA_W-1:0] rd_data
);

    // IMPLEMENTATION INTENTIONALLY OMITTED.

endmodule
