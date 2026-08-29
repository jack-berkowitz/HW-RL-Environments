# AXIS AUDIT — first three tasks, for shape approval before the remaining seven
# AGENT-DESIGN-43a92055, 2026-08-29. Nothing fixed; nothing routed to Agent 1 yet.
#
# NOT-FOR-CATALOG — every section of this file. It is an AUDIT DELIVERABLE awaiting
# shape approval, not a catalog entry: its rows are per-task findings about
# declarations, and what belongs in FINDINGS.md is the one general form at the
# foot, once the remaining seven tasks either confirm or refute it. Marked at the
# top because the checker reads a file's first ten lines.

**The question per axis:** does the design have freedom on it, is it published,
and if not what is the workaround. **The judgement is per-axis and it is where
the errors live** — d_ca03 cost me a wrong `role: capability` because I read a
metric's name instead of its pinning clause.

**Two disqualifiers that look like hidden axes and are not**, both learned on
d_ca03 and applied throughout:

* **PINNED** — the spec fixes the value, so area cannot buy it. Rule 25 as cited
  in d_ca03 P2: *"an unpriced axis is bounded in the specification, not given a
  metric of its own."* Giving it a metric prices something the contract removed.
* **EXPLICITLY DECLINED** — the spec names the axis and refuses to score it.
  d_ca03 A9 on replacement policy; d_ca04 on latency and throughput. Publishing
  it overrides a stated decision rather than filling a gap.

---

## d_ca03 sv39_mmu — ONE HIDDEN AXIS, and one metric published that should not be

| axis | free? | published? | note |
|---|---|---|---|
| **total_cycles** | **FREE** — L1 scores it, G4: *"THE CYCLE AXIS CHARGES FOR BUYING AREA WITH TIME"* | **HIDDEN** — declared with no role, so no per-unit column | **the one-division problem**: lower-is-better has nowhere to go in `area/metric` |
| tlb_hits | **PINNED** — P2 fixes 16+16 fully associative; T4/T9 check the counts | published **wrongly**, as `role: capability` (mine, 1530c80) | area cannot buy entries; variation comes from replacement policy, which A9 **explicitly declines to score** |
| hit_pct, pte_reads | consequences of the above | declared, no role | correct — derived, not independent |
| per-entry layout, tag-compare structure, PMP structure, walker sequencing (G4) | FREE | via **area** | correct — implementation choices with no separate observable |

**Workaround: invert the metric, not the formula.** `requests_per_cycle =
118 / total_cycles`. 118 is fixed by L1 (sequence, page tables and memory timing
identical for every submission), so the numerator is constant. Monotone
more-is-better over the whole legal range: L2 scores forward progress *"WITH NO
EXCEPTION"*, so cycles is finite and positive for every conforming design and the
metric never reverses. `area/throughput = area × cycles / 118`, an area-delay
product.

    reference   area 279,456   cycles 1269   2,430 um2/hit   3,005,336 um2*cyc/req
    claude      area 212,774   cycles 1078   2,046 um2/hit   1,943,817 um2*cyc/req
    ratios      0.76x raw      ---           0.84x per hit   0.65x per throughput

**claude's advantage strengthens rather than reverses** — smaller *and* faster.
And the per-hit axis was the only one making it look worse, which is the axis
that should not be scored at all.

---

## d_ca04 async_fifo_cdc — NO HIDDEN AXIS FOUND

| axis | free? | published? | note |
|---|---|---|---|
| capacity_beats_accepted | **FREE below B1's ceiling of 4** | **yes**, `role: capability`, per-unit computed | ceiling ≠ pinned: freedom exists below it, and area buys it |
| crossing_latency min/max | FREE — G4: *"a CHOICE reported as a metric and never gated"* | **yes**, `role: choice` | `choice` is not divided, so the one-division problem does not bite |
| wr_stall_cycles | consequence | yes, no role | correct |
| `thru` (emitted by `async_fifo_cdc_thru.sv`) | **EXPLICITLY DECLINED** | not declared | spec: *"NEITHER IS CONSTRAINED AND NEITHER IS CHECKED… Throughput likewise"*, and G3: *"Throughput bought with extra skid buffering is not available"* — the lever is spent by B1 |
| depth, handshake, SYNC_STAGES | **PINNED** (G3) | n/a | correctly unpriced |
| pointer encoding, storage construction (G4) | FREE | via **area** | correct |

**This one is clean.** Worth recording as the negative result: the audit is not
guaranteed to find something, and d_ca04's declaration matches its clauses.

---

## d_nw01 axi4_xbar — TWO HIDDEN FREE AXES, plus a declaration gap

**20 metrics emitted per configuration, 5 declared.** Not all 15 are axes.

| axis | free? | published? | workaround |
|---|---|---|---|
| **read_latency_avg** | **FREE** — G4: *"where registers sit relative to the LATENCY_MODE cuts"* | **HIDDEN** | lower-is-better → invert. `bursts_per_latency` or publish as a `choice` column, which needs no division |
| **fairness_spread** | **FREE** — G4: *"how arbitration is done, subject only to L2"* | **HIDDEN** | lower-is-better and bounded below by 0 → publish as `choice`; a per-unit form is not meaningful |
| **outstanding_master1** | FREE — same axis as master0 | **HIDDEN**: only `outstanding_master0` is declared | declare per master, or declare the min across masters, which is what C1's floor actually requires |
| disjoint_one_pair / two_pairs | FREE — C2 concurrency | **yes**, `role: capability` | correct, and this is the area-for-concurrency trade |
| aggregate_bursts, scored_beats | FREE | yes | correct |
| cross_id_reorderings | **PINNED** — O1/O4 | not declared | correct — correctness observable |
| liveness, liveness_worst_wait, liveness_global_idle_max_seen | **PINNED** — L1/L2/L3 *"not negotiable"* | not declared | correct |
| backpressure_stalls (+_b, +_r) | **uncertain** — likely a consequence of C3's ceiling | not declared | **flagged, not resolved**: I have not established whether a design can trade area against it independently |
| speedup_pct | **uncertain** | not declared | **flagged, not resolved** |
| `max`, `min`, `n` | not axes | present as bare keys | the unnamed-metric artefact — the record writer dropping a METRIC line's name, already a known defect on d_ca04 |
| fabric structure, tracking structure, register placement, logic sharing (G4) | FREE | via **area** | correct |

---

## What this says about the shape, before the remaining seven

**The one-division renderer is real but it is not the main finding.** It hides
exactly one axis here (d_ca03's cycles) and one candidate (d_nw01's latency). The
larger effect is simpler: **metrics are emitted and never declared.** d_nw01 emits
20 and declares 5.

**And the dangerous direction is the opposite of the one we were looking for.**
The instruction anticipated hidden axes. d_ca03 also had a *published* axis that
should not exist — and a wrongly published axis is worse than a hidden one,
because a hidden axis produces no number while a wrong one produces a number that
looks like a measurement. My own bridge introduced it.

**Two things I did NOT resolve and am not going to assert:** `backpressure_stalls`
and `speedup_pct` on d_nw01. Establishing whether either is independently
tradeable needs the clause work I did for cycles, and guessing is what produced
the tlb_hits error.

**Cost for the remaining seven:** the three above took roughly two hours, and
d_ca04 was fast because it is clean. d_ai01, d_ca01, d_dsp02, d_dsp03, d_nw03
should be comparable; d_ai04 and d_ca05 are slower because I know their clauses
least. **Estimate 4–5 hours**, and the two flagged-uncertain rows above are the
rate at which unresolved rows will appear — roughly one or two per task.
