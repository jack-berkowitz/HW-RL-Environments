# d_ai04 — SDP requantise / convert unit

Implement `sdp_requant` in synthesisable SystemVerilog.

A four-lane unit on a valid/ready stream. Each 64-bit input word carries four
16-bit lanes; each 128-bit output word carries four 32-bit lanes. What happens to
a lane depends on `cfg_precision`, and the two behaviours it selects are not
variants of one operation — they share no arithmetic.

Five things about this contract are worth reading before choosing an
architecture:

* **The G clauses set out how you are graded**, in what order, and which
  optimisation levers are already closed. Read them first.
* **`cfg_offset` is SUBTRACTED, not added.** This is the zero-point convention of
  quantised inference. It is the single most likely way to fail this task, and
  the very first check catches it.
* **Two quantities must be DERIVED rather than assumed.** The product
  `(x - cfg_offset) * cfg_scale` does not fit in 32 bits and must be exact before
  the shift (F5); and every binary16 subnormal is a *normal* binary32 value, so
  the float path must normalise rather than copy fields across (F7). A design
  that guesses either width passes every ordinary vector and fails only at the
  edges — where the checks are.
* **Rounding is to nearest, ties AWAY FROM ZERO.** The natural
  `(v + (1 << (t-1))) >>> t` is round-half-*up* and is wrong on every negative
  tie. Both signs are checked.
* **`in_ready` must be registered, and throughput is one word per cycle.** Those
  two together force storage: a single output register sustains one word per
  cycle on open flow and loses a word when the consumer stalls in the cycle a
  word is accepted. That case is checked directly.

Everything asserted below about delivered lanes, rounding, saturation and
control behaviour was **measured** against a hardware anchor rather than assumed
from convention. Where IEEE-754 would permit something else, the contract states
the choice rather than leaving it to be inferred: infinity clamps to `FLT_MAX`
rather than propagating.

**Everything normative is in the interface below, and it is complete.** The
contract cites a few repository file names in passing — those are provenance
notes for maintainers, not documents you need; nothing normative lives in them.
You are not expected to have seen the anchor, and you do not need it: every
value the contract depends on is written out here.

```systemverilog
// =============================================================================
// d_ai04 -- sdp_requant : 4-lane requantise / convert unit
// =============================================================================
//
// THE CONTRACT BELOW WAS MEASURED, NOT READ.
//
// The anchor is refs/nvdla_hw/vmod/nvdla/sdp/NV_NVDLA_SDP_CORE_Y_cvt.v -- 2,721
// lines of Catapult HLS output whose readable part is the Mentor library
// wrappers, not the arithmetic. Every F, A and P clause here comes from a probe
// under tb/audit/ and the evidence table in MEASUREMENTS.md. F54 is the
// precedent: d_dsp01 satisfied rule 11 exactly, its anchor turned out to be
// correctly rounded in no mode but RTZ, and the task was withdrawn rather than
// faked. Nothing here rests on a port name.
//
// Three clauses contradict what the port names suggest, and each was re-measured
// on an independently shaped vector before being written: cfg_offset SUBTRACTS,
// the rounding is ties-AWAY rather than half-up, and cfg_precision selects
// between two UNRELATED operations rather than four variants of one.
//
// -----------------------------------------------------------------------------
// THE INTERFACE
// -----------------------------------------------------------------------------
module sdp_requant (
    input  logic         clk,
    input  logic         rst_n,           // active-low, asynchronous assert

    // input stream -- one 64b word carrying four 16b lanes
    input  logic [63:0]  in_data,
    input  logic         in_valid,
    output logic         in_ready,

    // configuration. Sampled with the word it applies to (A5).
    input  logic [ 1:0]  cfg_precision,
    input  logic [31:0]  cfg_offset,      // SIGNED, and SUBTRACTED (F3)
    input  logic [15:0]  cfg_scale,       // SIGNED
    input  logic [ 5:0]  cfg_truncate,    // 0..63
    input  logic         cfg_bypass,
    input  logic         cfg_nan_to_zero,

    // output stream -- one 128b word carrying four 32b lanes
    output logic [127:0] out_data,
    output logic         out_valid,
    input  logic         out_ready
);
endmodule
//
// -----------------------------------------------------------------------------
// F -- THE FUNCTIONAL CONTRACT
// -----------------------------------------------------------------------------
// F1. LANES. in_data carries four 16-bit lanes, lane k at in_data[16k+15:16k].
//     out_data carries four 32-bit lanes, lane k at out_data[32k+31:32k]. Lane k
//     of the output is a function of lane k of the input ALONE. One output word
//     per input word, in order, never merged and never split.
//
// F2. cfg_precision SELECTS BETWEEN TWO UNRELATED OPERATIONS.
//
//       2'd2            -> FLOAT mode  (F7-F9)
//       2'd0, 1, 3      -> INTEGER mode (F3-F6)
//
//     The three integer codes are INDISTINGUISHABLE from one another. That is
//     measured, not assumed: a three-parameter vector chosen to separate them
//     returned the same word for all three. A submission may not use 2'd1 or
//     2'd3 to select any behaviour of its own.
//
//     THE MODES SHARE NO ARITHMETIC. Float mode is not integer mode with
//     different widths, and implementing one and aliasing the other is the
//     failure this axis exists to catch.
//
// F3. INTEGER MODE, and cfg_offset SUBTRACTS.
//
//       out_lane = sat32( round( (x - cfg_offset) * cfg_scale / 2^cfg_truncate ) )
//
//     with x the input lane read as a SIGNED 16-bit integer, cfg_offset signed
//     32-bit, cfg_scale signed 16-bit.
//
//     THE SUBTRACTION IS THE MEASURED DIRECTION. x=4 with cfg_offset=3 delivers
//     1, not 7; x=10 with cfg_offset=-5 delivers 15. Confirmed independently on
//     x=4660, offset=291, scale=37, truncate=3 -> 20207, where addition would
//     give 22898. This is the zero-point convention of quantised inference, and
//     writing `x + offset` is the single most likely way to fail this task.
//
// F4. ROUNDING IS TO NEAREST, TIES AWAY FROM ZERO.
//
//     Not truncation, not an arithmetic shift, and NOT round-half-up. The
//     natural implementation
//
//         (v + (1 << (cfg_truncate-1))) >>> cfg_truncate
//
//     is round-half-UP and is WRONG ON EVERY NEGATIVE TIE. Measured: +3 and -3
//     at truncate=1 deliver +2 and -2; +7 and -7 deliver +4 and -4; +1 and -1
//     deliver +1 and -1. An arithmetic shift is separately excluded: -9 at
//     truncate=2 delivers -2 where `>>>` gives -3, and x=-32768 with
//     scale=32767 at truncate=63 delivers 0 where `>>>` gives -1.
//
//     cfg_truncate=0 is a no-op, not a rounding step.
//
// F5. THE PRODUCT IS EXACT; SATURATION HAPPENS LAST.
//
//     (x - cfg_offset) * cfg_scale must be computed WITHOUT rounding,
//     truncation or saturation. Only after the shift and the rounding of F4 is
//     the result saturated to signed 32 bits, to 32'h7FFFFFFF above and
//     32'h80000000 below.
//
//     THIS IS A DERIVED QUANTITY, WHICH IS WHY IT IS STATED AS A BEHAVIOUR AND
//     NOT AS A WIDTH. x-cfg_offset does not fit in 32 bits and the product does
//     not fit in 47. A submission carrying 32-bit intermediates passes every
//     small vector and fails only out here. Measured: with cfg_offset = -2^31,
//     scale = 32767 and truncate = 46 the anchor delivers 1, where a 32-bit
//     intermediate saturates first and then shifts to 0; at truncate = 45 it
//     delivers 2. Separately, 0 - (-2^31) delivers 32'h7FFFFFFF rather than the
//     32'h80000000 a wrapping subtraction would give.
//
// F6. cfg_bypass IS INTEGER-MODE ONLY. With cfg_bypass=1 in integer mode,
//     out_lane = the input lane sign-extended to 32 bits, and cfg_offset,
//     cfg_scale and cfg_truncate are IGNORED. In float mode cfg_bypass has NO
//     EFFECT -- measured: 0x4100 with cfg_bypass=1 in float mode still delivers
//     0x40200000, not 0x00004100.
//
// F7. FLOAT MODE IS AN EXACT fp16 -> fp32 CONVERSION.
//
//     out_lane = the IEEE-754 binary32 value equal to the binary16 input.
//     cfg_offset, cfg_scale, cfg_truncate and cfg_bypass are ALL INERT -- each
//     confirmed separately, one vector per signal.
//
//     SUBNORMALS CONVERT EXACTLY AND ARE NOT FLUSHED TO ZERO. Every binary16
//     subnormal is a NORMAL binary32 value, so an implementation that copies the
//     exponent and mantissa fields across is wrong here: the mantissa must be
//     normalised and the exponent adjusted by the leading-zero count. Measured:
//     0x0001 -> 0x33800000 (2^-24 exactly), 0x0200 -> 0x38000000,
//     0x03FF -> 0x387FC000, 0x8001 -> 0xB3800000. This is a second derived
//     quantity, alongside F5.
//
//     Signed zero is preserved: 0x0000 -> 0x00000000, 0x8000 -> 0x80000000.
//
// F8. INFINITY IS CLAMPED TO FLT_MAX, NOT PROPAGATED.
//
//       0x7C00 -> 0x7F7FFFFF        0xFC00 -> 0xFF7FFFFF
//
//     No one writes that unless the contract says so, and it is the clause most
//     likely to be "corrected" by a submission that knows IEEE-754. It is the
//     anchor's measured behaviour and it is required.
//
// F9. NaN AND cfg_nan_to_zero.
//
//     A binary16 NaN maps to {sign, 8'hFF, 13'b0, mantissa[9:0]} -- the payload
//     lands in the LOW mantissa bits and the sign is preserved. Measured:
//     0x7E00 -> 0x7F800200, 0x7C01 -> 0x7F800001, 0xFE00 -> 0xFF800200.
//
//     cfg_nan_to_zero=1 delivers 32'h00000000 for a NaN input of EITHER sign.
//     It applies to NaN ONLY: infinity is unaffected (0x7C00 still delivers
//     0x7F7FFFFF with the bit set), and in INTEGER mode the signal has no effect
//     at all -- 0x7E00 delivers 32256, untouched.
//
// -----------------------------------------------------------------------------
// A -- FLOW CONTROL AND TIMING
// -----------------------------------------------------------------------------
// A1. THE HANDSHAKE. in_valid/in_ready and out_valid/out_ready are AXI-stream
//     style: a transfer occurs on a rising clk edge with both high. Neither
//     valid may be withdrawn once asserted before its transfer completes, and
//     data must be held stable across a stall.
//
// A2. in_ready IS REGISTERED. There must be NO combinational path from out_ready
//     to in_ready. Measured on the anchor: toggling out_ready within a cycle
//     leaves in_ready unchanged.
//
//     THIS IS THE CLAUSE THAT MAKES THE TASK MORE THAN ARITHMETIC. A2 together
//     with A3 forces storage: a single output register gives II=1 on open flow
//     and LOSES A WORD when the consumer stalls in the cycle a word is accepted.
//     The extra slot is invisible on the delivered surface and appears only at a
//     stall boundary.
//
// A3. LOSSLESS AND ORDER-PRESERVING. Every accepted word produces exactly one
//     output word, in acceptance order, with no loss and no duplication, across
//     any pattern of stalls on either side.
//
// A4. THROUGHPUT. With both sides open, one word per cycle, sustained. Latency
//     from acceptance to out_valid is not pinned and is a PPA choice (P3).
//
//     THE ANCHOR'S NUMBERS, FOR REFERENCE AND NOT AS A REQUIREMENT: latency 1,
//     II 1, and three words held behind a fully stalled consumer.
//
// A5. CONFIGURATION IS SAMPLED WITH ITS WORD. The cfg_* inputs that apply to a
//     word are those present when that word is ACCEPTED. A design that pipelines
//     data must pipeline the configuration with it; a design that applies the
//     currently-presented configuration to a word accepted three cycles earlier
//     is wrong. This is checked by changing configuration between back-to-back
//     accepted words.
//
// A6. RESET. rst_n asserts asynchronously and is released synchronously. After
//     release, in_ready must be high and out_valid low, with no stale word
//     retained from before the reset. Reset asserted mid-stream discards
//     everything in flight; it does not drain.
//
// -----------------------------------------------------------------------------
// P -- PINNED, AND WHAT IS FREE
// -----------------------------------------------------------------------------
// P1. FIXED. Four lanes; 16-bit input lanes and 32-bit output lanes; the port
//     list above, exactly. These are not design choices.
//
// P2. FIXED. The arithmetic of F3-F9, bit for bit. There is no accuracy trade
//     and no tolerance.
//
// P3. FREE, AND IT MOVES PPA. Pipeline depth, the number of buffer slots beyond
//     what A2 and A3 require, whether the two modes share a datapath or are
//     built separately, how the exact product of F5 is formed, and how the
//     normalisation of F7 is implemented. These are CHOICE metrics in G5's
//     sense: a submission choosing differently from the reference is disclosed,
//     not penalised.
//
// -----------------------------------------------------------------------------
// T -- WHAT IS CHECKED
// -----------------------------------------------------------------------------
// T1. THE SCORED SURFACE is out_data, out_valid and in_ready, sampled every
//     cycle, compared bit-exact against the reference. Internal state is not
//     read.
//
// T2. INTEGER ARITHMETIC across the F3-F5 space, including the negative ties of
//     F4 and the wide-intermediate vectors of F5. A submission that gets F3's
//     direction wrong fails on the first vector; one that gets F5 wrong fails
//     only on the wide ones, which is why they are present.
//
// T3. FLOAT CONVERSION across F7-F9, including every subnormal boundary, both
//     zeroes, both infinities and NaN of both signs with cfg_nan_to_zero clear
//     and set.
//
// T4. MODE DISJOINTNESS. cfg_bypass exercised in float mode and cfg_nan_to_zero
//     in integer mode, each of which must do NOTHING; and the full requant
//     configuration driven to non-trivial values in float mode, which must be
//     ignored. Four separate "has no effect here" checks.
//
// T5. THE STALL BOUNDARY. out_ready deasserted in the cycle a word is accepted,
//     and held; then released. This is the check A2 and A3 exist for, and it is
//     the one a single-register implementation fails while passing everything
//     else.
//
// T6. CONFIGURATION PIPELINING (A5): back-to-back words with different
//     configurations, checked against the reference lane by lane.
//
// T7. RESET MID-STREAM (A6), with the antecedent gated -- the check asserts that
//     words were actually in flight before the reset, so it cannot pass
//     vacuously on a design that was idle.
//
// T8. SUSTAINED THROUGHPUT (A4) over a long open-flow burst.
//
// T9. THE SUBMISSION MUST ELABORATE UNDER BOTH slang AND Verilator, and passing
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
//        from a single reference Fmax sweep -- and THAT SWEEP HAS NOT BEEN RUN
//        for this task. No PPA number may be reported for d_ai04 until it is.
//        This is recorded as missing rather than filled with a plausible value.
//
//        The period does not move in response to what is submitted. Pinning the
//        row at the slowest submission's own Fmax rewards a slow design by
//        moving the measurement toward the period where its own area looks best.
//        The period is THE SAME for every submission.
//
// G2. WHAT IS COMPARED: area post-synthesis and post-place-and-route, and power
//     at the pinned period.
//
//     TIMING CLOSURE IS A GATE, NOT AN AXIS, AND SLACK IS NOT SCORED. A build
//     that misses the pinned period yields no comparable area or power figure --
//     an area number from a build that did not close is not a smaller design, it
//     is an unfinished one -- so its PPA is withheld rather than reported.
//
//     Slack above zero earns nothing either, because it is not a separate
//     quantity from area: meeting timing with margin is bought WITH area, as the
//     tools upsize cells, insert buffers and duplicate logic. Area already
//     charges for that, so scoring slack as well would count one tradeoff twice
//     and in opposite directions. Closure is pass or fail.
//
//     THERE IS NO CYCLE AXIS ON THIS TASK, and that is a consequence of A4
//     rather than an omission. Throughput is pinned at one word per cycle, so
//     every conforming submission takes the same number of cycles over the
//     scored sequence and a cycle count would distinguish nothing. Latency is
//     free (P3) but is not scored: a deeper pipeline shows up in area and in
//     whether the design closes timing, which is where it belongs.
//
// G3. WHAT IS NOT AVAILABLE TO OPTIMISE.
//       * THE ARITHMETIC. Every delivered lane is pinned by F3-F9. There is no
//         accuracy trade, no fast path for common configurations, and no
//         permission to flush subnormals or propagate infinities.
//       * THE HANDSHAKE. A2 forbids the combinational ready path that would
//         otherwise be the cheapest way to build this, and A3 forbids dropping a
//         word at a stall boundary. Both are checked (T5).
//       * THE MODE SPACE. F2 forbids implementing one mode and aliasing the
//         other, and T4 checks the four inertness clauses separately.
//
// G4. WHAT IS ACTUALLY LEFT. The two derived quantities and the buffer, and
//     these are where the area difference comes from:
//
//       * THE EXACT PRODUCT (F5). A full-width multiplier, a shift-and-add
//         sequence, or a decomposition exploiting the 16-bit scale are all
//         conforming and do not cost the same. Getting the width by derivation
//         rather than by guessing is the whole of this clause.
//       * THE NORMALISER (F7). Leading-zero count plus barrel shift, a small
//         lookup, or a per-case decode across the ten subnormal exponents. Also
//         conforming, also not equally priced.
//       * DATAPATH SHARING between the two modes of F2, which share no
//         arithmetic but do share a pipeline and an output register.
//       * THE BUFFER. A2 and A3 force storage; the exact depth beyond that
//         minimum is free. The anchor holds three words. Two is achievable and
//         smaller. Both conform.
//       * ROUNDING (F4). Ties-away can be built as a magnitude-domain round, or
//         as a sign-corrected increment. These differ in area.
//
//     A submission that meets the pinned period with less area and less power
//     scores better. There is no credit for slack beyond zero.
//
// G5. THERE IS NO SINGLE COMBINED SCORE, and that is deliberate rather than
//     unfinished. Nothing in this project establishes what a unit of capability
//     is worth in square micrometres, so no weighted sum of area and power is
//     computed, and none should be inferred from the phrase "scores better"
//     above. Each axis is reported separately, and a submission that wins on one
//     and loses on another is reported as exactly that.
//
//     WHAT A SUBMISSION IS COMPARED AGAINST. The reference implementation, built
//     from the same contract at the same pinned period and the same scored
//     configuration, and the other submissions to this task on the same axes.
//     The reference is an ANCHOR, not a target: beating it is not required and
//     losing to it is not disqualifying. It exists so that a number has
//     something to be a ratio of.
//
//     EVERY REPORTED METRIC CARRIES A ROLE, and the role decides how a
//     difference from the reference is read:
//
//       * FIXED -- the contract requires a value. Deviating is a specification
//         violation, not a design choice, and it fails correctness.
//       * CHOICE -- the contract leaves it free and it moves PPA. Where a
//         submission chose differently from the reference, the area ratio is
//         marked NOT LIKE-FOR-LIKE rather than presented as a quality gap.
//         Choosing differently from the reference is not penalised; it is
//         disclosed.
//       * CAPABILITY -- more is better and area buys it. Reported both raw and
//         per unit of area, because raw area credits a design for being small
//         when it was actually doing less.
//
//     ON THIS TASK EVERY METRIC IS FIXED OR CHOICE. There is no capability axis,
//     because P1 and P2 pin the lane count and the arithmetic and A4 pins the
//     throughput -- there is no dimension along which a submission may do MORE.
//     A capability column is therefore not reported for d_ai04 rather than
//     reported as zero.
// =============================================================================
```
