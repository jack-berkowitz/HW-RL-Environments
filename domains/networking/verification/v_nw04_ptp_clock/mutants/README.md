# v_nw04 mutant set — these MUST BE CAUGHT

The discriminating measure for a submitted testbench. Opposite sign to
`conformant/`: that one satisfies the spec and must survive; these violate it
and must be caught.

Every mutant is **generated**, by `gen_mutants.py`, as a mechanical edit of the
golden shim and — where the defect is internal — of a renamed copy of the
anchor. Each edit is an exact `old -> new` pair asserted to match **exactly
once**, so a silent no-op cannot produce a mutant identical to the golden that
every testbench "kills" by doing nothing.

## Every defect in this set is GUARDED

The set was rebuilt for difficulty. Each mutant is now a pair:

    defect := wrong_behaviour AND rare_predicate over contract-level state

A **total** defect — fixed priority, a dropped selector bit, an off-by-one that
holds always — fires on the first transaction of its class. Any testbench that
exercises the class at all catches it, whether or not it is checking the clause.
Such a mutant measures **coverage, not checking**, which is why a submission
that passed the validity gate used to collect most of the old set for free.

A **guarded** defect is caught only by a testbench that constructs the named
configuration and is still checking when it arrives. The guards here name
counts, run lengths, occupancies, repetitions and ordinal positions — how long an adjustment is, which adjustment it is, which wrap it is, which drift window it is, and whether two effects land on the same increment.

Two constraints bound how far this can go, and both are load-bearing:

- **Fairness.** Every guard names a condition the spec states as a checkable
  bound at a named boundary, so the catching act is derivable from the spec text
  alone. No mutant punishes an unstated expectation.
- **Reference reachability.** The reference testbench kills all ten. A mutant
  the reference cannot reach is not difficult, it is *unverified* — it would be
  scored against submissions on evidence the task itself cannot produce.

Guards are written over **contract-level** state only, never over a register
private to the anchor. That is what makes step 5c possible: each defect is
re-derived on the policy-divergent implementation in `policy/`, which has no
such registers to read.

## The set

| id | clause | guard — fires only when… | defect |
|---|---|---|---|
| `pt_m1_drift_skipped_one_in_eight` | **D2** | one drift window in every eight | that application is skipped |
| `pt_m2_adjust_short_when_long` | **A2** | the adjustment is eight increments or longer | it is applied one short |
| `pt_m3_adj_active_long_from_second` | **A3** | the second adjustment onward | adj_active_o runs one cycle past it |
| `pt_m4_wrap_early_when_fraction_carried` | **W1** | the boundary is crossed mid-nanosecond | the wrap happens one nanosecond early |
| `pt_m5_pps_two_cycles_on_later_wraps` | **W3** | the third wrap onward | pps_o lasts two cycles |
| `pt_m6_fns_truncated_on_drift_cycles` | **I1/F3** | the increments carrying the drift | the 96-bit base drops four fractional bits |
| `pt_m7_adjust_unsigned_for_small_magnitudes` | **A5** | a negative adjustment under one nanosecond | it is treated as unsigned |
| `pt_m8_reset_keeps_reprogrammed_period` | **R2** | a period has been programmed twice | reset stops restoring the default -- the first reset is correct |
| `pt_m9_fourth_window_after_rate_change` | **D2** | the fourth drift window after a rate change | that window is one cycle long |
| `pt_m10_drift_dropped_when_adjustment_active` | **I1** | an adjustment and a drift on the SAME increment | only the adjustment is applied |

## Non-equivalence witnesses — rule 16

`nonequiv_tb.sv` drives the golden and one mutant from a shared input sequence
and compares their observable outputs every cycle, each channel's payload masked
by its own `valid`. Run the whole set with `./witness.sh`.

| id | first observable difference |
|---|---|
| `pt_m1_drift_skipped_one_in_eight` | cycle 37 -- ts64: golden 17153238 / mutant 17153236 (-2 fns) |
| `pt_m2_adjust_short_when_long` | cycle 209 -- adj_active_o: golden 1 / mutant 0 |
| `pt_m3_adj_active_long_from_second` | cycle 63 -- adj_active_o: golden 0 / mutant 1 |
| `pt_m4_wrap_early_when_fraction_carried` | cycle 162 -- ts96 ns: golden 1 / mutant 2 |
| `pt_m5_pps_two_cycles_on_later_wraps` | cycle 255 -- pps_o: golden 0 / mutant 1 |
| `pt_m6_fns_truncated_on_drift_cycles` | cycle 2 -- ts96 fns: golden 26216 / mutant 26208 (-8 fns) |
| `pt_m7_adjust_unsigned_for_small_magnitudes` | cycle 66 -- ts64: golden 32478584 / mutant 33527160 |
| `pt_m8_reset_keeps_reprogrammed_period` | cycle 357 -- ts64: golden 419432 / mutant 598018 |
| `pt_m9_fourth_window_after_rate_change` | cycle 22 -- ts64: golden 9227472 / mutant 9227470 (-2 fns) |
| `pt_m10_drift_dropped_when_adjustment_active` | cycle 47 -- ts64: golden 22439182 / mutant 22439180 (-2 fns) |

## The witness harness had to be extended twice

Two mutants reported NO DIFFERENCE OBSERVED on the first run, and in both cases
the harness was at fault, not the mutant:

- `pt_m2_adjust_short_when_long` distinguishes adjustments at `adj_count_i >= 8`.
  Every adjustment in the harness was shorter than that, so a defect conditioned
  on length could not appear. A twelve-increment adjustment was added.
- `pt_m5_pps_two_cycles_on_later_wraps` fires from the **third** wrap. The
  harness reached exactly one. Two further wraps were added.

Both are the same mistake in different clothes: stimulus that exercises a
feature once, and a defect that only appears on the repetition. It is the
mistake the guarded set is built to punish, and the harness made it first.

## X2c, and why it exists

The spec's post-*reset* warm-up allowance (X2b) was referenced by I1 and D2 but
never defined — the clause had been lost. It is restored, and **X2c** now states
the matching allowance after a `set`: the increment following a set is
unconstrained for up to four cycles on the base that was set (measured: one).
This matters most at the wrap, which §W is only reached by setting close to one
second — so the wrap always lands a few cycles after a set, inside the window.
