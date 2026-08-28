# d_dsp03 `fp_multifmt_fma` -- build notes

Tier-B. Fused multiply-add shared across FP32, FP16 and BF16, with packed SIMD
lanes that scale with a declared `WIDTH`.

## Status

| artifact | WIDTH=32 | WIDTH=64 |
|---|---|---|
| `ref/fp_multifmt_fma_ref.sv` (shim over cvfpu) | PASS | PASS |
| `controls/nc_a_stuck_output.sv` | FAIL | FAIL |
| `controls/nc_b_two_lanes.sv` | **PASS** | **FAIL** |
| `controls/nc_c_flush_to_zero.sv` | FAIL | FAIL |
| `tb/fp_multifmt_fma_alt_ref.sv` (second source) | PASS | PASS |

13860 vectors, 6300 at WIDTH=32 and 7560 at WIDTH=64, every one compared on
result bits AND flags. PPA is Agent 1's.

## The step that mattered most: the anchor was checked before it was trusted

`tb/audit/ieee754_fma_model.py` verifies all 13860 captured vectors against
IEEE 754-2019 directly. It passes 13860/13860.

This is not ceremony. **d_dsp01 was withdrawn three hours earlier for exactly the
failure this step catches** (F54): its anchor satisfied rule 11 perfectly and was
correctly rounded in no mode but RTZ, and nothing downstream could have seen it,
because every expected value came from that anchor. Rule 11 makes fabrication
impossible and says nothing about provenance.

The model validates its own rounder first, against a property it does not
compute -- the bracketing representable pair found by binary search over bit
patterns, with the mode's rule asserted independently. 3000 trials x 2 signs x
5 modes at each format, 0 mismatches. A model that has not been validated is an
opinion.

**And the model was the one that was wrong.** 28 vectors disagreed on UF. In
every one the exact result is tiny and inexact and gradual underflow rounds it
to zero; the model said "no UF because the delivered value is zero", the anchor
said UF. Clause 7.5 defines tininess-after-rounding as rounding at the target
*precision* with an **unbounded exponent range** -- not as inspecting the value
actually delivered, which underflow has already flushed. The anchor was right.
Fixed in the model and in the second source, which had inherited the same
misreading.

## Why WIDTH, and why 64 is scored

The catalog's difficulty for this row is resource sharing, which PPA rewards and
a checker cannot gate. So the contract carries a capacity parameter that is
bound by **result bits** rather than by a rate: `lanes = WIDTH/format_width`.

At WIDTH=32 a vectorial 16-bit operation has two lanes -- and two is also what a
design gets from the narrowest shortcut. At WIDTH=64 it has four. `nc_b_two_lanes`
is that shortcut, built deliberately: it **passes at WIDTH=32 and fails at
WIDTH=64** on vector 1080, `fmt=FP16 vec=1 lanes=4`. That is the measurement S0
rests on, not an argument.

This is the F49 shape, and the failure recorded there is the reason the scored
configuration was chosen by where the check discriminates rather than by
engineering merit.

## Three harness defects, all in handshake observation, none visible to a control

All three are the same mistake in different clothes: **observing a handshake at
an edge where the testbench is also driving.**

1. **Capture rig.** The driver waited for its own input transfer and then looked
   for a result. A zero-latency design presents the result in the cycle the
   operation is accepted, and the `do/while` skipped the only negedge inside
   that one-cycle window. Zero vectors, watchdog, empty file.

   The diagnostic half is the sharper lesson: `$fwrite` is buffered and lost when
   the watchdog `$finish`es, **so a stall at vector 2000 and a stall at vector 0
   look identical from outside.** Reading the code produced two wrong theories; a
   `nvec` progress trace localised it in one run.

2. **Scoring TB, backpressure.** The stall decision was latched for the duration
   of one `issue()` call, so `out_ready_i` stayed low while the driver waited on
   `in_ready_o`. L4 permits `in_ready_o` to depend on `out_ready_i` and the
   reference does exactly that. Instant deadlock, 4200 of 6300 vectors lost, and
   it presented as a candidate wedging.

3. **Scoring TB, the monitor.** It fired on the negedge -- the same edge on which
   `issue()` clears `in_valid_i` with a blocking assignment. Double-counted
   transfers, slid the expected-value queue by one, **6116 mismatches against a
   bit-exact reference.** Moved to the posedge: the edge the DUT itself samples,
   and the one no testbench assignment races.

**Not one of the three controls could see any of them.** Controls feed the
checker bad inputs; these were defects in what the checker assumed about a
*correct* design. That is F52's argument, and it is why the second source is
targeted at latitude clauses rather than written to be merely different.

## What the second source bought

**A spec defect, and the kind only a second source finds.**

It passed every simulation config and was then rejected by the synthesis
frontend: `unroll limit of 4000 exhausted`. Its leading-one search is a
132-iteration loop nested inside a lane loop whose bound is the runtime lane
count, and slang cannot bound that at elaboration. Verilator accepts both
without a word.

T1 said "must elaborate under both slang and Verilator" and said nothing about
the one construct that most commonly breaks it here. **A conformant, bit-exact
design would have scored full correctness and produced no PPA number at all**,
with the cause surfacing much later as an unexplained mid-pipeline failure. Now
**T5**, with the constant-bound idiom written out. Re-verified after: reference
2/2, all three controls unchanged, second source 2/2, spec lints at both widths.
Nothing moved.

The negative controls could not have found this. All three are wrapped around
the anchor and inherit its structure; none of them contains a loop at all.

## And one positive result

Every one of the three harness defects above lived in handshake observation against a
zero-latency, one-per-cycle, always-ready design, because that is what the
reference is. The second source is the opposite legal choice on every clause the
checker observes: a registered three-cycle pipeline, `in_ready_o` that does not
look at `in_valid_i`, one operation at a time. Measured: latency 4-14 against 0,
187 ops/1000cyc against 427, 33511/40350 cycles against 14758/17680.

It retired 13860/13860 with no queue desync and no liveness failure. **That is
the first positive evidence that the handshake observation is correct rather
than merely not-yet-wrong** -- the previous two defects would have survived into
exactly this design.

Both adjudication rounds used, of two. Round 1 was the second source's own
defect: `sh` and `shu`, the rounding shift amounts, were declared `int unsigned`
and wrapped whenever `k < M`, which is every cancellation case. Adjudicated,
fixed, passed on the next run with nothing else changed. Round 2 was T5 above.
Neither was debugged to green.

## A fourth harness defect, found only by the real path

`ref/sim_flags_verilator.txt` put `-y` and its path on one line. The loader
appends one array element **per line**, so the pair arrived as a single argument
and Verilator rejected it -- every config `COMPILE_ERROR`. Building by hand had
worked all along, because there the tokens were separate. Found by running
`scripts/sim_candidate.sh` instead of `verilator`, which is the only reason to
run the gated path on your own artifacts before shipping them.

It also demonstrates the contract is **solvable** without the anchor.

## Stimulus: two directed bands

The uniform draw was not reaching the cases that break an FMA. Added:

* **Near-cancellation** -- `c` set to the negation of the product's leading M+1
  significand bits, so `a*b + c` is the product's own tail. This is the case a
  design that rounds the product before adding gets wrong wholesale, and it is
  the reason the contract can say "fused" and mean it.
* **Underflow band** -- exponents arranged so the product lands within a few
  ulps of the smallest normal, with mantissa bits guaranteeing inexactness.

Both are input generation, not oracle generation (rule 11). UF coverage went
from 27 to 451 at WIDTH=32, and the cancellation band is what surfaced the
model's tininess defect.

## A standard negative control that is inert here

**Wrong reset polarity was built first and passed at both widths.** The
reference binds `NumPipeRegs = 0` and is purely combinational: there is no state
for a reset to hold, so inverting `rst_ni` changes nothing observable. The
control was vacuous, not the checker blind.

Recorded because that control is standard equipment in this project and is inert
against every combinational DUT in it. Replaced with a stuck output, which is the
other form step 6a allows.

## Catalog corrections owed (I do not own `TASK_CATALOG.md`)

Row `d_dsp03`:

1. **Class A, not B.** cvfpu and its `common_cells` closure are vendored and
   elaborate clean at both WIDTH settings. The only build wrinkle is that
   Verilator's `-y` search pulls in `fpnew_mxdotp_multi_wrapper.sv`, so
   `refs/cvfpu/src/mxdotp` and `.../pace` must be on the search path;
   `ref/sim_flags_verilator.txt` carries this.
2. **The task is named `fp_multifmt_fma`, not `multifmt_slice`.** The contract is
   narrower than the anchor module: ADDMUL/FMADD only, three formats, packed
   SIMD. Naming it after the anchor would name the artifact rather than the
   contract.

## Independence on the underflow clause is now absent BY CONSTRUCTION

**2026-08-21.** A7a pins the underflow predicate to the delivered result's
exponent field, longhand, citing no standard. Until then the second source and
the Python model both implemented IEEE 754-2019 clause 7.5's unbounded-exponent
rule — a correct reading of the standard, and a genuinely independent one. Both
were changed to track the pinned decision.

**Neither was wrong, and neither change is a bug fix.** The second source and
the reference were answering different questions; the task has since decided
which question it is asking. Both files record it in those terms rather than as
a correction.

The consequence, stated rather than left implicit: **on this one clause the
second source can no longer disagree with the anchor, so it can no longer
falsify it.** Independence survives everywhere else — the arithmetic, the
rounding, the special cases, the handshake, the lane packing — but inside the
underflow band the three artefacts now agree by construction rather than by
convergence, and agreement that was engineered is not evidence.

**Discrimination on that band therefore rests on the mutant set.** `mBAND`
implements clause 7.5's predicate, which differs from the pinned rule under
RNE/RUP/RMM, and must be killed by the band vectors in all three formats;
`mA6` drops the inexactness condition. If either stops being killed, nothing
else is watching this clause.

The second source's other differences from the reference are untouched by the
change and were re-measured after it, byte-identical to the run before it:

| | reference | second source |
|---|---|---|
| latency min/max | 0 / 0 | 4 / 14 |
| throughput ops/1000cyc | 427 | 187 |
| cycles, W32 / W64 | 14758 / 17680 | 33511 / 40350 |
| `in_ready_o` | high every cycle | `= (state == IDLE)` |
| algorithm | cvfpu datapath | exact integer significands, bounded window, explicit sticky |

## Version boundary, 2026-08-21

The task text changed: `c4b5edc12f407731` -> `35619b11aa94307d`. A7a now pins
underflow longhand and the vector set reaches the band it turns on.

**WHAT MADE THE BUMP MATERIAL WAS NOT THE BAND.** This matters to anyone reading
the boundary later, because the clause that opened the whole thread is not the
clause that changed the requirement.

On `d_dsp02` the two halves came apart cleanly. Its A6 prose had always stated
the band correctly -- "a result that is tiny before rounding but rounds up to
the smallest normal is NOT underflow" -- so for the band the bump there is
GENUINELY DOCUMENTATION-ONLY: same requirement, better attribution. What was
never determined was the ZERO case. A4b said underflow is raised "only when the
result is tiny AFTER rounding AND inexact" and directed the reader to the
delivered result; a delivered zero is not tiny, so the natural reading yields no
underflow where the anchor sets it. 14 of d_dsp02's original 4290 sit there.

On THIS task neither half was determined -- the spec named clause 7.5 and
nothing else -- and the vector set reached neither. But the asymmetry is worth
carrying: **the band is what was argued about, and the zero case is what
actually moved.**

**The prior 13860/13860 is retained and is not comparable to anything after this
line.** It is accurate over the region its set reached, and that region did not
include the band -- zero cases in 13860. It is instance 1 in F59. No candidate
has ever been scored against this task, so nothing needs re-scoring; the boundary
is recorded so that a later reader does not compare across it.

---

## F53's blast radius, MEASURED. 2026-08-27

Flagged as a build gate before further work on d_dsp03 and v_dsp01 and never
confirmed. Confirmed now. **F53 reaches nothing live.**

### Every site outside `refs/` that binds a cvfpu ascending format mask

| site | how it builds the mask | live? |
|---|---|---|
| `d_dsp01/ref/fp_divsqrt_srt_ref.sv` | by index, `fmt_fp32_only()`, width-asserted | task **WITHDRAWN** |
| `d_dsp03/ref/fp_multifmt_fma_ref.sv` | by index + **three `$fatal` width assertions** | **yes** |
| `d_dsp03/controls/nc_a`, `nc_b`, `nc_c`, `nc_d` | by index, same construction | yes |
| `v_dsp01/probe/semantic_probe.sv` | **by literal** `9'b101_000_000` / `4'b0110` | task **REJECTED at step 1, never built** |
| `v_dsp01/dut/fp_convert.sv` | **by literal** `9'b101_000_000` / `4'b0010` | same |

Eleven files match the mask vocabulary outside `refs/`; nine build by index, two
by literal, both in `v_dsp01`.

### The four literals are arithmetically correct, checked against the enum

`fmt_logic_t` is `logic [0:8]`, so a 9-bit literal's leftmost bit lands on index
0. `NUM_FP_FORMATS = 9`, `FP32 = 0`, `FP16 = 2`; `NUM_INT_FORMATS = 4`,
`INT8/INT16/INT32/INT64 = 0/1/2/3`.

    9'b101_000_000 -> indices 0, 2  = FP32 + FP16     matches its comment
    4'b0110        -> indices 1, 2  = INT16 + INT32   matches its comment
    4'b0010        -> index 2       = INT32 only      matches its comment

Every one carries a comment stating the ascending convention, so both files were
written after F53 was learned.

### d_dsp03 is verified LIVE, not by inspection

The shim asserts `max_fp_width == 32`, `min_fp_width == 16` and
`LANES == WIDTH/16`, and **the reference passes 2/2 through the scored path** —
so none of the three fired. That is the executable difference between d_dsp03 and
d_dsp01: F53's only symptom was one `WIDTHTRUNC` among 133 warnings, and this
build emits **192 warnings including WIDTHTRUNC**. The noise is still there. The
assertions are what make it non-load-bearing.

### The residual risk: PRESENT AND UNFIXED, not absent

The two literal sites have **no width assertion**, which is the second half of
d_dsp03's fix. F53's own text says indexing alone breaks silently if the package
renumbers its formats — and a literal is strictly weaker than indexing, because
it hardcodes the position *and* the width. If `NUM_FP_FORMATS` ever moves off 9,
`9'b101_000_000` misaligns silently and only an assertion would catch it.
`v_dsp01` is REJECTED and unbuilt so nothing scored depends on it, and it is
verification's territory: **reported, not edited.**

**STATED AS UNFIXED RATHER THAN ABSENT, deliberately.** The sweep's conclusion is
that F53 reaches nothing LIVE — not that every site is safe. Two sites carry the
weaker construction today. If `v_dsp01` is ever resumed, or if either file is
copied as a starting point for something that IS built, the defect arrives with
it and the assertions that would catch it are not there. "Reaches nothing live"
is a statement about the current build set and expires the moment that set
changes.

### And d_dsp03 is unblocked ON F53's GROUNDS ONLY

F53 is closed for this task and is not what is holding it. **d_dsp03 still waits
on Agent 1's vendored-anchor sweep, for an unrelated reason:** 2 of its 3 named
files are recorded, with five search directories underneath whose coverage is
poor. That is a provenance question about which bytes the anchor actually
comprises, not a question about format masks. Do not read "F53 closed" as
"d_dsp03 unblocked".

### And my first sweep missed both literal sites

I grepped for a literal appearing inline at the port connection. Both real sites
bind a `localparam` and then pass its NAME to the port, so the pattern is split
across two lines and the grep returned empty — which I nearly reported as "no
literal binding anywhere". **A pattern sweep on a BINDING fails on an
indirection**, exactly as a numeric sweep on a relation fails on a capitalisation
(F99). What found them was sweeping for the TYPE, which cannot be indirected away
because the declaration must name it.
