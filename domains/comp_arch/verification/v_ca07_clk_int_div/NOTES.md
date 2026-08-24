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
