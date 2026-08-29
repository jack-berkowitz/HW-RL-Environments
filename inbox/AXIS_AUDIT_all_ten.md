# AXIS AUDIT — all ten live design tasks. FOR AGENT 1.
# AGENT-DESIGN-43a92055, 2026-08-29.
#
# NOT-FOR-CATALOG — this is an audit deliverable, not a catalog entry. What
# belongs in FINDINGS.md is the one general form at the foot, and that is stated
# for the catalog owner to lift rather than filed twice.
#
# METHOD, per axis: read G3 (what the contract PINS) and G4 (what it leaves
# FREE), list what the testbench EMITS, list what `scored_metrics` DECLARES, and
# classify. Nothing is fixed here and no README or task.yaml is edited.
#
# TWO DISQUALIFIERS THAT LOOK LIKE HIDDEN AXES AND ARE NOT:
#   PINNED    the spec fixes the value; area cannot buy it. Rule 25, cited in
#             d_ca03 P2: "an unpriced axis is bounded in the specification, not
#             given a metric of its own."
#   DECLINED  the spec names the axis and refuses to score it. d_ca03 A9 on
#             replacement policy; d_ca04 on latency and throughput.
# Publishing either overrides a decision rather than filling a gap.

## SUMMARY

| task | hidden free axes | wrongly published | declared but never emitted |
|---|---|---|---|
| `d_ai01` | — | — | — |
| `d_ca01` | `mem_txns_writebacks` (+1 uncertain) | — | — |
| **`d_ca03`** | **`total_cycles`** | **`tlb_hits`** | — |
| `d_ca04` | — | — | — |
| `d_ca05` | — | — | **all 3** |
| `d_dsp02` | — | — | — |
| `d_dsp03` | — | — | — |
| `d_ai04` | — | — | **all 5** |
| **`d_nw01`** | **`read_latency_avg`, `fairness_spread`, `outstanding_master1`** | — | — |
| **`d_nw03`** | **`b1_beats_held`, `c1_rate`, and L3's latency metric IS NOT EMITTED AT ALL** | — | — |

**Four of ten are clean.** That matters: a sweep that finds something everywhere
is one to distrust.

## THE FOUR TASKS NEEDING ACTION

### d_nw03 — the sharpest, because a clause is unimplemented

**L3: *"LATENCY IS FREE. Input-to-output delay is a design choice, REPORTED AS A
METRIC and never gated."*** The testbench emits `b1_beats_held`, `beats`,
`c1_rate`, `checks`, `frames`, `r1_guard_true`. **The string `latency` appears
ZERO times in both tb files.** The contract promises a metric the harness never
produces — not a declaration gap but a clause nothing implements, on an axis the
spec calls free.

Also hidden: **`b1_beats_held`** (free below B1's 2-frame ceiling, more-is-better,
capability-shaped — the same shape as d_ca04's `capacity_beats_accepted`, which is
declared).

**CORRECTED 2026-08-29: `c1_rate` was listed here as a third hidden axis and is
NOT one.** `beats_delivered` is already declared `role: capability` with
`beats_cycles` as its denominator, and that IS the throughput axis. `c1_rate`
measures the same axis inside the C1 phase specifically. I listed it without
checking whether an existing declaration already covered it — the same failure as
`tlb_hits`, one column over: classifying a metric from its name rather than
against what is already declared.

### d_ca03 — one hidden, one wrongly published

`total_cycles` is **free** (L1 scores it; G4: *"the cycle axis charges for buying
area with time"*) and **hidden**, because a lower-is-better axis has nowhere to go
in `area/metric`. Workaround: `requests_per_cycle = 118 / total_cycles` —
numerator fixed by L1, monotone across the whole legal range because L2 scores
forward progress *"with no exception"*.

`tlb_hits` is **pinned** by P2 (16+16 fully associative, counts checked by T4/T9)
and is **published wrongly as `role: capability`**. **That one is mine**, from
`1530c80`, and it should come out. Variation between designs comes from
replacement policy, which A9 **explicitly declines to score**.

    reference   279,456   1269 cyc   2,430 um2/hit   1,713,300 um2*cyc/req
    claude      212,774   1078 cyc   2,046 um2/hit   1,108,100 um2*cyc/req
                0.76x raw            0.84x per hit   0.65x per throughput

**CORRECTED 2026-08-29.** The two absolute figures first read 3,005,336 and
1,943,817, computed with **118** requests taken from the testbench header
comment. The checker counts **207** -- the header was stale and I quoted it.
**The RATIOS are unaffected**, because the request count is the same constant on
both sides and cancels; only the absolutes moved. The emitted metric divides by
the measured `checked` rather than a literal, so the stale number cannot reach a
published ratio.

### d_nw01 — three hidden

**`read_latency_avg`** (free per G4: *"where registers sit relative to the
LATENCY_MODE cuts"*, lower-is-better), **`fairness_spread`** (free per G4:
*"how arbitration is done, subject only to L2"*, lower-is-better), and
**`outstanding_master1`** — emitted per master while only `master0` is declared,
so the capability is measured on both and published for one.

### d_ai04 and d_ca05 — the reverse gap: declared and unmeasurable

**d_ai04 declares five metrics; its testbench emits ZERO `METRIC:` lines.**
`init_interval` (fixed), `buffer_slots` (choice), `latency_cycles` (choice),
`area_um2` (choice), `power_mw` (choice). **d_ca05 declares three; also zero.**
Both use `MEASURE:` coverage tallies instead, which no consumer reads as a metric.

Two separate problems inside that: nothing emits the sim metrics, **and**
`area_um2`/`power_mw` are declared as sim metrics at all — they are PPA outputs
and could never appear in a sim record.

**This bears directly on d_ai04's withheld rows.** Its reason says it *"declares
no capability metric"*. The accurate statement is stronger: it declares five
metrics of which none is ever produced.

## THE SIX CLEAN TASKS, and why each is clean rather than unexamined

* **`d_ai01`** declares zero metrics and has zero free metric axes. G4's freedoms
  — FMA construction, row sharing, register placement, clock gating — all fold
  into area and power. Latency is pinned by L1/L2/L3. Correct as it stands.
* **`d_dsp02`** — G4 is *"entirely micro-architectural"*; latency and II are both
  declared `fixed` and are pinned by the contract. No free axis exists.
* **`d_dsp03`** — G4: *"Unusually for this benchmark, BOTH latency and throughput
  are free here"*, and both are declared: `latency_min` as `choice`,
  `throughput_ops_per_1000cyc` as `capability`. Throughput is more-is-better, so
  the renderer works unchanged. This is the worked example of the fix d_ca03 needs.
* **`d_ca04`** — `capacity_beats_accepted` free below B1's ceiling and declared
  capability; crossing latency free and declared `choice`, which is not divided.
  Its emitted `thru` is **declined** by the spec, not hidden.
* **`d_ca01`** — mostly clean. `max_outstanding_n` (capability) and `latency_min`
  (choice) cover C1's floor and L6's free latency. **One hidden:**
  `mem_txns_writebacks`, the observable of replacement policy, which L1 makes free.
  **One uncertain and NOT asserted:** `accept_rate`, which may be a derived
  consequence of the two declared axes rather than independent.

## UNRESOLVED, flagged rather than guessed

`accept_rate` on d_ca01; `backpressure_stalls` and `speedup_pct` on d_nw01.
Establishing whether each is independently tradeable needs the clause work done
for d_ca03's cycles, and guessing is what produced the `tlb_hits` error.

## THE GENERAL FORM, for FINDINGS.md

> **An axis the renderer cannot express is an axis the task does not have.**

Three layers, same defect, all found this week. d_ca03's capability was declared
in G2 and invisible because `metric_roles()` read one schema form. Its second axis
is invisible because the renderer does one division and a lower-is-better axis has
nowhere to go. d_nw03's latency axis is invisible because **no testbench line
emits it**, though the contract says it is reported.

**And the dangerous direction is the opposite of the one this audit went looking
for.** A hidden axis produces no number. A wrongly published one produces a number
that looks like a measurement — d_ca03's `µm² per TLB hit` priced a replacement
policy the contract twice declines to price, and I introduced it while fixing the
hidden axis next to it.
