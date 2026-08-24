# v_ca07 — glitch-free integer clock divider

Anchor: `refs/common_cells/src/clk_int_div.sv` (PULP `common_cells`, SHL-0.51),
plus `tc_clk_gating` from `refs/tech_cells_generic`.
Scored configuration: `DIV_VALUE_WIDTH=4`, `DEFAULT_DIV_VALUE=0`,
`ENABLE_CLOCK_IN_RESET=0`. Ships as `clk_ratio_div`.

## Why this task exists

Every other verification task in this corpus is checked by SAMPLING VALUES. Here
correctness is about **intervals between edges** — the output period, the duty
split, and how long the output is gated across a reconfiguration. A testbench
that samples signals cannot see the property at all.

## Step 1 — semantic confirmation, MEASURED not read

`probe/measure_ratio.sv`. Units are `clk_i` cycles.

### The divisor ladder

| div | period | high | low | duty |
|---|---|---|---|---|
| 0 | 1 | — | — | pass-through |
| 1 | 1 | — | — | pass-through |
| 2 | 2 | 1 | 1 | 50% |
| 3 | 3 | **1** | **2** | **33%** |
| 4 | 4 | 2 | 2 | 50% |
| 5 | 5 | **2** | **3** | **40%** |
| 6 | 6 | 3 | 3 | 50% |
| 7 | 7 | **3** | **4** | **42%** |
| 8 | 8 | 4 | 4 | 50% |

### The handshake and the gating

| action | `div_ready_o` after | output |
|---|---|---|
| 2 → 4, a real change | 2 cycles | briefly gated; 39 edges where 40 were due |
| 4 → 4, the SAME value | **0 cycles** | **not gated at all**; 40 edges, full rate |
| 4 → 3, a real change | 2 cycles | briefly gated; 51 edges where 53 were due |
| 3 → 3, the SAME value | **0 cycles** | **not gated**; 53 edges |

### Enable and reset

`en_i=0` stops the output entirely (0 edges in 100 cycles); `en_i=1` resumes.
The output is gated throughout reset. After release the divisor returns to
`DEFAULT_DIV_VALUE`, which is 0 — pass-through.

## What the measurements settle, and where the anchor's own header is WRONG

1. **`div_i` 0 and 1 are a DEGENERATE PAIR.** Both mean pass-through, period 1.
   Two distinct input values with one behaviour, and no way to tell them apart
   from the output.
2. **The 50% duty cycle claim is FALSE for odd divisors.** The header says the
   unit "always generates clean 50% duty cycle output clock". Measured, the rule
   is `high = floor(div/2)`, `low = ceil(div/2)`: exact at even divisors, and at
   odd ones the LOW phase is the longer one — 33%, 40%, 42% at 3, 5 and 7. The
   specification will state the measured rule, not the header's.
3. **A same-value reconfiguration is a no-op**, granted in zero cycles with no
   gating, where a real change costs two cycles and a brief gate. One value
   changes the verdict — the shape that has separated submissions elsewhere.
4. Reset restores the DEFAULT divisor, so the post-reset state is pass-through
   rather than whatever was last configured.

## Step 1, continued — the gating bound and the remaining outputs

`probe/measure_gating.sv`, across **every ordered pair of divisors in 0..8**, 72
transitions.

### The gating bound: the header is RIGHT, and my first measurement was wrong

The header claims `clk_o` "remains gated for at most 3x<new clk period> clk_i
cycles". Measured **from the acceptance edge** — the cycle `div_ready_o` rises —
that holds on all 72 pairs, zero violations, worst gap 17 against a limit of 24.

It is **exactly tight** on 14 of them: every transition to `div_i` 0 or 1 gives a
gap of exactly 3, against a limit of exactly 3.

**My first attempt reported it as violated on four transitions, and that was my
error.** I measured the gap from the cycle I asserted `div_valid_i`, which folds
in the handshake wait — 1 to 4 cycles depending on phase — and the handshake wait
is not gating. "Remains gated" starts when the change is ACCEPTED. Measuring a
bound from the wrong origin makes a correct bound look broken, and I had already
written it down as a finding before rechecking.

The clause is worth having precisely because it is tight: a design that gates one
cycle longer on a transition to pass-through is outside the bound, and only a
testbench that measures the interval from acceptance can tell.

### The other outputs

- **`cycl_count_o` is a modulo-`div` counter.** At div=4 it runs `1 2 3 0 1 2 3
  0`; at div=3, `2 0 1 2 0 1`. It counts 0..div-1.
- **`div_ready_o` is a genuine handshake, not a constant.** Held low while
  `div_valid_i` is low — measured 0 across 20 cycles with valid deasserted. A
  spec must not describe it as always-ready.

### Where the header IS wrong, and this one survives rechecking

The duty-cycle claim. "Always generates clean 50% duty cycle output clock" is
false for odd divisors: `high = floor(div/2)`, `low = ceil(div/2)`. That was
measured by direct edge timestamps rather than by sampling, so it is not a phase
artifact — and it is arithmetically necessary, since an odd number of input
cycles cannot be split evenly. 33%, 40% and 42% at divisors 3, 5 and 7.

## What this cost, and the rule it produces

Two of my three "the header is wrong" claims were mine, not the header's. The
pass-through one came from sampling a clock at a phase that aliases it; the
gating one came from measuring an interval from the wrong origin. Only the duty
cycle survived.

**A measurement of an interval is only as good as its two endpoints, and a
measurement of a clock is only as good as its observer's phase.** Both faults
produced confident, plausible, wrong numbers, and in both cases what caught them
was rechecking an implausible result rather than anything in the apparatus.

## A probe fault, found before it became a specification

The first version sampled `clk_o` at the `negedge` of `clk_i`. That **aliases
the entire pass-through case**: when `clk_o` IS `clk_i` it is low at every
negedge of `clk_i`, so the probe saw no rising edges and reported "NO OUTPUT
CLOCK" for `div=0` and `div=1` — the two values the header says are
pass-through. It also skewed the odd-divisor duty measurements, reporting div=3
as 66% where it is 33%: the sampled version had the high and low phases
BACKWARDS.

Had that been written down, the spec would have said a clock divider produces no
clock at its two most common settings, and inverted the duty rule. A sampled
measurement of a clock measures the sampling phase. Edges are now recorded
directly with `always @(posedge clk_o)` and timestamps.

## dut2 and the perturbations, written BEFORE any mutant

Same ordering as v_ca06, for the same reason: what stops the strongest
submissions is rejecting a legal variant, not missing a defect. Seven legal
implementations exist before a single mutant does.

### dut2 — independent, opposite on all five latitude clauses

| clause | anchor | `clk_ratio_div_alt` |
|---|---|---|
| L1 phase | its own | period begins after the transition ends |
| L2 gating duration | **at** G1's bound, tight on all 14 transitions to pass-through | worst gap 2 of a permitted 3, tight nowhere |
| L3 `div_ready_o` on a real change | 1 to 4 cycles | same cycle |
| L4 deferral of a second request | 8 cycles | about 2 |
| L5 `cycl_count_o` while gated | counts the new divisor at once | held at 0 |

Verified against the probes: identical period, high, low and duty at every
divisor. The only differences are edge counts inside fixed windows, which are
phase and gating-duration artefacts — exactly the latitude.

**dut2's first version violated G1**, gap 4 against a bound of 3 on every
transition to pass-through. It gated for two cycles and the negedge enable
register added a third. *Being slower is not automatically safer when the clause
is an upper bound* — the reflex that a conservative implementation is a safe one
is wrong in that direction, and it produced a non-conforming second source.

### The five perturbations

| id | clause | what it does |
|---|---|---|
| `cdc_c1_accept_window_4` | L3, L4 | acceptance gated, 4 on / 4 off |
| `cdc_c2_accept_window_8` | L3, L4 | the same knob at 8 on / 8 off |
| `cdc_c3_extra_gating` | L2 | one extra gated cycle, still inside G1 |
| `cdc_c4_count_zero_when_disabled` | L5 | counter forced to 0 while disabled |
| `cdc_c5_count_frozen_when_disabled` | L5 | counter frozen at its last value |

Two on L5 deliberately: they are opposite legal readings of the same clause, so
a testbench fitted to either fails the other. Two on L3/L4 for the same reason at
different settings.

**L1 is not perturbed here and cannot be.** A wrapper cannot shift the phase of a
clock it did not generate. dut2 covers L1 by being independent, which is the only
way to reach that clause — worth recording, because a reader counting five
latitude clauses against five perturbations would otherwise assume L1 was among
them.

Confirmed: all seven implementations show **zero G1 violations** across all 72
ordered divisor pairs, and all five perturbations are identical to the anchor on
the divisor ladder — same period, same duty, every divisor.

### One more instrument fault, small

The first sweep reported "G1 violations = 1" for every implementation including
the anchor, which I know has none. The grep was matching the word VIOLATION in
the harness's own explanatory line. Counting the result lines rather than the
word gives zero everywhere. Same class as the `fail()`-label map and the
degenerate control: what was counted was not what was claimed.

## Declared unscoreable, to be carried into task.yaml verbatim

**This task has no `task.yaml` yet** — creating a partial one would make
`check_witness_sync.py` report v_ca07 as missing its rule-24 record, which is
true but not useful noise. It is written here so it cannot be lost, and it goes
into `task.yaml` in the same form as v_ca06's D6/E6/D7 block when the task is
complete.

    unscored_clauses:
      P3_distinction:
        text: divisors 0 and 1 are observationally identical -- both pass-through
        scored:   pass-through ITSELF is scored. A unit giving period 2 at
                  div_i=1 violates P3 and is caught.
        unscored: any DIFFERENCE between 0 and 1. No testbench can distinguish
                  them and no fault will be keyed on the distinction.
        why_both_kept: >
          Dropping one would hide a degenerate case an implementation can get
          wrong in the same way for both. The distinction is declared
          unscoreable rather than removed.
      L1_not_perturbed:
        text: the phase of clk_o against clk_i
        note: >
          Covered by dut2, which is independent, and NOT by any conformant
          perturbation -- a wrapper cannot shift the phase of a clock it did not
          generate. Recorded because five latitude clauses against five
          perturbations invites the inference that each covers one.

The general rule both entries serve: **a count a reader can do is a claim you
have made**, whether or not you wrote it down. Five clauses beside five
perturbations asserts a pairing. Two divisor values with one behaviour asserts a
distinction is testable. Neither was true, and neither was stated until it was
checked.

## CORRECTION — the duty-cycle claim was mine too, so it is three of three

Recorded above, twice, is the claim that the anchor's header is wrong to say it
"always generates clean 50% duty cycle output clock", and that the real rule is
`high = floor(div/2)`, `low = ceil(div/2)`.

**That is wrong. The header is right.** Measured in RAW TIME rather than in whole
`clk_i` cycles, high equals low equals half the period at every divisor from 2
to 8. At odd divisors the split is a **half-integer** — divisor 3 is 1.5 and 1.5
— because the transitions use `clk_i`'s falling edges as well as its rising
ones. That is what a 50%-duty odd divider is.

**How it survived two measurements.** Both divided each endpoint by the clock
period *before* subtracting, so 1.5 truncated to 1 and the low phase appeared to
be 2. The step-1 probe did it, and then the reference testbench's own P2 check
did it again independently — and agreed, which is exactly the agreement that
made the number look solid.

**How it survived reasoning, which is the worse half.** I wrote that the odd case
was "arithmetically necessary, since an odd number of input cycles cannot be
split evenly". That is true only if the split must land on whole cycles. It does
not. A plausible argument was constructed on top of a truncation and made it look
settled rather than provisional — the reasoning did not check the measurement, it
ratified it.

So all three of the "the header is wrong" claims about this module were mine: a
sampling phase that aliased pass-through, an interval measured from the wrong
origin, and now a truncation dressed in an argument. **Zero defects found in the
anchor. Three in my own instruments.**

The consequence for the task is not small: P2 is a central clause, `dut2`
implemented the wrong rule and had to be rebuilt to use both edges, and a
submission measuring the way I did would reject correct hardware at every odd
divisor. The spec now says so explicitly, because it is the trap I fell into
twice.

## The reference testbench, against all seven

All seven legal implementations PASS: the anchor, `dut2`, and the five
conformant perturbations. Coverage: 16 divisors, 7 odd, both pass-through
values, 12 reconfigurations, the gating bound measured 12 times.

**The counting basis is a property of the harness, not a habit.** Every reported
number comes from a structured counter incremented where the event happens.
There is no text-matching surface, because four instrument faults on this task
were miscounts and two of them were grep-shaped.

**Agent 3's input-variation monitor is in**, with their allowlist discipline: an
input that never varies and is not declared constant is a FAILURE, and each
declared constant prints its reason. One declared here — `test_mode_en_i`, citing
X4. Its negative control (`+declare_all`) prints `RESULT: SELFTEST -- not a
score` and suppresses both the PASS and FAIL branches, so a self-test can never
be read as a result. Written as plain if/else, not a ternary between string
literals, which pads the shorter with NULs and prints nothing.

## What the reference caught while being built

**Two of my own perturbations violated H3.** `c1` throttled every request
including a same-value one, and `c3` gated on every acceptance. H3 says a
same-value request is granted in the same cycle and is not gated. Both now track
the divisor in force so they only turn the knob L3 and L4 actually leave free —
the timing of a *real* change. The reference discriminating against artefacts I
built to be legal is the outcome that argues it works.

**`dut2` had a 4-bit overflow at the top of the range.** `(div_q + 1)` at
`div_q = 15` wraps to zero, the high phase became zero, and the clock never
started — at divisor 15 only. Found because the ladder sweeps all 16 values
rather than a sample.

## The P2 correction, and what it cost

Recorded above in full. The duty is 50% at every divisor; at odd ones the split
is a half-integer, using both edges of `clk_i`. Two independent measurements
truncated it and agreed with each other, and a plausible arithmetic argument
ratified the wrong answer.

`dut2` had implemented the wrong rule — `floor(div/2)` whole cycles, giving 33%
at divisor 3 — and was rebuilt to AND the posedge phase with a half-cycle-delayed
copy. The testbench's own P2 check had the same defect and now compares in time
units. Both are in the spec as an explicit warning, because measuring in whole
`clk_i` cycles rejects correct hardware at every odd divisor and it is the trap I
fell into twice.
