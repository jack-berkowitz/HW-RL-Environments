# ai_d01 `int8_requant` — build notes

Verilator **5.046** and Icarus **13.0** (both pinned in `refs.lock`) for every
result below.

## Oracle class B — what is and is not being claimed

There is **no external RTL oracle** for this task, so *"the checker passes
known-correct external RTL" is not available and is not claimed anywhere.* The
oracle is `ref/model/int8_requant_model.py` plus the committed vectors. The
three substitute guarantees required by `DESIGN_CATALOG.md` § Oracle classes:

1. **Derived from the documented algorithm.** The model implements the published
   gemmlowp/TFLite primitives from their arithmetic definition in plain Python
   integer arithmetic. Not transcribed from NVDLA RTL or gemmlowp C++.
2. **Model, generator and vectors are all committed** and regenerable
   (`--emit-vectors`), with a property self-test (`--selftest`).
3. **Mutation testing carries the sharpness argument alone.** No second signal
   exists. That raised the bar for the mutant set, not lowered it — see below.

## Spec ambiguity resolved: the two steps round differently

The catalog row says "round-half-away-from-zero". That is **imprecise in a way
that matters**, and it was caught by the model's own self-test rather than by
reading: I asserted end-to-end sign symmetry, and it failed.

| step | operation | tie rule | example |
|---|---|---|---|
| 1 | `DHIMUL` | toward **+∞** | `+3.5 → +4`, `−3.5 → −3` |
| 2 | `RSHIFT` | **away from zero** | `+1.5 → +2`, `−1.5 → −2` |

The asymmetry in step 1 comes from the negative nudge being `1 − 2^30` rather
than `−2^30`: the extra `+1`, combined with truncation toward zero, pulls a
negative exact tie back toward zero. This is real shipped behaviour, not a
transcription slip.

I kept the reference algorithm faithful and **pinned both rules normatively in
the spec header** rather than smoothing them into one uniform rule. Rationale:
the spec is what the checker is allowed to test, so an arbitrary choice left
implicit would be exactly the "TB encodes the reference's free choices" failure
the methodology exists to prevent. Pinned explicitly, it is a legitimate
requirement a competent engineer can meet without ever seeing gemmlowp.

## Interface decision changed during the build

`zero_point` started as a single shared int8 and became **per-lane**. The first
checker run failed on lane 1 of beat 0: the vectors carry a per-vector zero
point, but a shared port could only present lane 0's. Making every input
per-lane removes the aliasing entirely, works for all `LANES`, and matches the
catalog's "per-channel" framing. Caught by the checker on its first run against
a correct reference, which is the intended failure mode.

## Sizing decision

`LANES ∈ {1,2,4,8}`, default 4. Lanes are fully independent — no cross-lane
reduction — so this parameter is a pure replication knob and does **not** create
the DEPTH×DEPTH comparison sweep that forced the `lsq` and cache cuts. Chosen so
the PPA baseline has a scaling story without risking synthesis blowup.

**A PPA baseline at one `LANES` is not comparable to another.** The datapath
replicates per lane; the baseline below is `LANES=4` only.

## Step 4 — checker passes correct RTL, every legal config, both simulators

| LANES | Verilator | Icarus | coverage holes | checks |
|---|---|---|---|---|
| 1 | PASS | PASS | 0 | 4561 |
| 2 | PASS | PASS | 0 | 3531 |
| 4 | PASS | PASS | 0 | 3016 |
| 8 | PASS | PASS | 0 | 2759 |

Representative run (LANES=4):

```
METRIC: beats_checked=3016
METRIC: observed_latency_cycles_min=1 max=1
METRIC: backpressure_cycles=3528 input_stall_cycles=3277
// coverage: clamp_hi=3394 clamp_lo=3225 tie1=240 tie2=708 sh0=765 sh31=528
// coverage: bp=3528 in_stall=3277 reset_mid=1 idle_gap=1157 b2b=515
TEST_RESULT: PASS
```

Every coverage class is populated at every `LANES`. Latency prints as a `METRIC`
and does not gate the verdict — the spec leaves latency free, so the checker
never asserts a cycle count.

### Two-simulator portability cost something real

Icarus initially reached a *different verdict* from Verilator — the exact "runs
under only one simulator" failure the catalog warns about. Two causes, both
mine:

* the driver changed `in_valid` **at** the clock edge, racing the monitor that
  samples it. Fixed by driving every stimulus change at edge+1ns.
* the reference used a part-select on a 64-bit intermediate inside a function
  (`biased[7:0]`), which Icarus refuses in an `always_*` process. Replaced with
  a size cast.

### Scoreboard restructured to remove a desync class

The driver originally recorded each beat's expectation itself, which meant
guessing which edge would transfer. It guessed wrong under backpressure and
desynced the whole comparison by one beat. **The monitor now records
expectations by observing the real `in_valid && in_ready` handshake**, so driver
and scoreboard cannot disagree. `sync_check()` at every phase boundary asserts
`beats_sent == beats_recv`, so a desync is reported where it happens instead of
silently shifting every later comparison.

This is the same family as the `rob_tb` bug the prompt warns about: do not let
the scoreboard grade itself against its own prediction of what the DUT did.

## Step 5 — second source

**Not required.** `ai_d01` is not on the mandatory second-source list
(`ca_d01`, `ca_d02`, `ca_d03`, `ca_d08`, `nw_d01`, `dsp_d02`, `ai_d02`).
Recorded explicitly so its absence is not read as a skipped step.

## Step 6 — mutation testing

Seven mutants, one bug each, seven distinct failure classes. All elaborate, all
simulate, all are killed, and **all die in a directed phase** — none survives to
be caught by random luck.

| id | class | injected bug | killing check | first fail | diff rate |
|---|---|---|---|---|---|
| m01 | arithmetic-rounding | step-1 negative nudge loses its `+1` (ties away from zero, not toward +∞) | D3 beat 10 result mismatch | cyc 19 | 5 671 ppm |
| m02 | arithmetic-rounding | step-2 threshold loses the negative `+1` (ties toward zero) | D3 beat 5 result mismatch | cyc 14 | 19 509 ppm |
| m03 | arithmetic-sign | step-1 floors instead of truncating toward zero | D2 beat 0 result mismatch | cyc 8 | 24 727 ppm |
| m04 | boundary | upper clamp compares `> 128` instead of `> 127` | D3 beat 2 result mismatch | cyc 11 | 5 444 ppm |
| m05 | saturation-vs-wrap | lower clamp removed — wraps instead of saturating | D3 beat 2 result mismatch | cyc 11 | 560 571 ppm |
| m06 | reset | reset clears data but not `out_valid` | D6 `out_valid survived reset (R3)` | cyc 3108 | 1 814 ppm |
| m07 | protocol-concurrency | `in_ready` ignores backpressure, overwriting an unaccepted result | D4 `result changed under backpressure (H3)` | cyc 527 | 247 731 ppm |

### What diff rate does and does not measure

Diff rate is the fraction of observed cycles on which reference and mutant
outputs diverge **under the diff harness's stimulus**
(`tb/int8_requant_diff.sv`). It is **not** the same thing as difficulty for a
checker that has to detect the divergence. A mutant can diverge rarely and still
be trivial to catch if the divergence lands on an obvious directed vector
(`m04`: 0.54%, killed at cycle 11), and a mutant could diverge often and still be
missed by a checker that never looks at the right signal. Read it as *how much
signal is available*, not *how hard this is*.

Two measurement bugs found and fixed while producing the table, both worth
recording because they produce plausible-looking wrong numbers:

* the ppm arithmetic overflowed 32-bit and reported **−416 279 ppm** for m05;
* m06 scored **0 ppm** until the diff harness was given a mid-stream reset —
  a reset-scoped bug has no opportunity to diverge in a stimulus that never
  resets, so the stimulus, not the mutant, was the reason nothing appeared.

### Testbench strengthened twice, driven by mutant results

Both changes were made because a mutant was killed in the *wrong place*, then
the reference was re-run on all configs and all mutants re-run:

* **m07** originally died only in the random soak. `D4` now offers a *different*
  beat while the output is stalled — a correct design may refuse it or buffer
  it, but neither may disturb the pending result. m07 now dies at D4 cycle 527.
* **m04** originally survived to beat 506. The model now emits directed
  clamp-boundary vectors landing on exactly ±127/±128/−129, so an off-by-one in
  the comparison dies at beat 2.

### Proposed diff-rate band — deferred, as instructed

Not fixing a threshold on one module's numbers. From this task alone the spread
is 0.18 % – 56 %, and the shape suggests a band somewhere around **0.1 % – 25 %**
with everything above it treated as filler. **m05 at 56 % is the one I would
flag as approaching filler**: removing the low clamp entirely is caught by
almost any submission. I kept it because "saturation vs wrap" is a required
mutant class in `VERIFICATION_CATALOG.md` § Mutant diversity, and a subtler
version collapses into m04's boundary class. Recommend revisiting after
`nw_d01` and `ca_d08` give two more modules' worth of numbers.

## Step 7 — PPA baseline

See `orfs/config.mk` and `orfs/constraint.sdc`. sky130hd, 20 ns period matching
the house Tier-One designs so the number is comparable with them.
`ABC_CLOCK_PERIOD_IN_PS` is derived from this design's own SDC (`$3*1000`), so it
cannot drift and cannot hand ABC a 20 ps target.

### Result — sky130hd, LANES=4, 20 ns target

| metric | value |
|---|---|
| design area (post-route) | **275 995 µm²** (14 % utilisation) |
| synthesised module area | 193 269 µm² |
| WNS | **−6.41 ns** |
| TNS | −193.07 ns |
| total power | 1.47 W (100 % combinational) |
| sequential cells | 33 |
| reg→reg min period | 1.95 ns |
| flow | completed to `6_finish`, exit 0 |

### It does not close timing, and I am not relaxing the period to hide that

The reference **misses the 20 ns target by 6.41 ns.** The worst path is
diagnostic:

```
Startpoint: mult[111] (input port clocked by vclk_core_clock)
Endpoint:   result[25]$_SDFFE_PN0P_ (flop clocked by core_clock)
            4.00 ns input external delay, then the whole datapath
```

It is an **input-port → output-register** path, not register-to-register:
reg→reg min period is 1.95 ns, and there are only 33 sequential cells in the
entire design. The reference has exactly one pipeline stage, so all four lanes'
32×32 signed multiply, 64-bit rounding, variable 0–31 shift and clamp sit in a
single combinational block, ~22 ns of logic against a 16 ns budget
(20 ns period − 4 ns input delay).

**This is a property of the reference, not of the task.** The spec deliberately
leaves latency free ("Pipeline it, or don't"), and `ref/int8_requant_ref.sv`
deliberately picks the most obvious un-pipelined structure so that mutants stay
localised and readable. A submission that pipelines the multiply will close
timing comfortably and beat this baseline outright.

**That is a calibration finding worth acting on**: it means `ai_d01` has real
PPA headroom rather than plateauing. Timing closure is a genuine axis of
difficulty here, not a formality — a correct-but-naive design and a correct-and-
pipelined design are far apart on PPA, which is exactly what the scoring needs
in order to discriminate.

**Open decision for the project owner** (I have not made it unilaterally): a PPA
baseline that fails timing is awkward to score against. Three options —
(a) keep it, and score submissions against a deliberately naive baseline;
(b) pipeline the reference, which costs mutant readability;
(c) raise the period until the reference closes, which the build prompt
explicitly forbids doing quietly and which I have therefore not done.


## Open items

* Nothing blocking.
* The diff-rate band above is a proposal on one module's data and should not be
  adopted until `nw_d01` and `ca_d08` are measured.
