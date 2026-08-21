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
