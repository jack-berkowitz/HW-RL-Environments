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
