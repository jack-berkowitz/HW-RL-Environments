# Rule 24 — reproduction record for v_nw04_ptp_clock

Rule 24 has two halves: the apparatus must reproduce a known-good answer, and
that reproduction must be **recorded alongside the numbers it licenses**. The
numbers are the `witness:` strings and the `policy_independence` figure in
`../task.yaml`. This file is the second half.

Regenerate with `./witness.sh` and `./check_policy_independence.sh`.

## Witness runner

The **negative** control is the golden through the same build-and-grep pipeline:
it must produce no clause failure, which catches a runner that reports one
unconditionally. The **positive** control is that every mutant must produce one,
which catches the two bugs these runners actually had — a rename that silently
matched nothing, and a grep that did not match the testbench's failure format.
Both turned a real failure into silence, and both would have passed a
positive-only or negative-only check.

```
  RULE24 negative control : PASS (golden vs golden: no difference)
  pt_m1_drift_skipped_one_in_eight: first difference at cycle 37 -- ts64: golden 17153238 / mutant 17153236 (delta -2 fns)
  pt_m2_adjust_short_when_long: first difference at cycle 209 -- adj_active_o: golden 1 / mutant 0
  pt_m3_adj_active_long_from_second: first difference at cycle 63 -- adj_active_o: golden 0 / mutant 1
  pt_m4_wrap_early_when_fraction_carried: first difference at cycle 162 -- ts96 ns: golden 1 / mutant 2 (delta 1)
  pt_m5_pps_two_cycles_on_later_wraps: first difference at cycle 255 -- pps_o: golden 0 / mutant 1
  pt_m6_fns_truncated_on_drift_cycles: first difference at cycle 2 -- ts96 fns: golden 26216 / mutant 26208 (delta -8 fns)
  pt_m7_adjust_unsigned_for_small_magnitudes: first difference at cycle 66 -- ts64: golden 32478584 / mutant 33527160 (delta 1048576 fns)
  pt_m8_reset_keeps_reprogrammed_period: first difference at cycle 357 -- ts64: golden 419432 / mutant 598018 (delta 178586 fns)
  pt_m9_fourth_window_after_rate_change: first difference at cycle 22 -- ts64: golden 9227472 / mutant 9227470 (delta -2 fns)
  pt_m10_drift_dropped_when_adjustment_active: first difference at cycle 47 -- ts64: golden 22439182 / mutant 22439180 (delta -2 fns)
  RULE24 positive control : 10 of 10 mutants reported a difference
   exit=0
```

## Step 5c — policy independence

Each `(clean)` line is a control: a conforming implementation must PASS, and a
failing control aborts the run rather than being counted alongside the defects.

```
v_nw04_ptp_clock
reference testbench vs the GOLDEN base and its ten defects
  golden (clean)                     PASS as expected
  pt_m1_drift_skipped_one_in_eight   FAIL as expected
  pt_m2_adjust_short_when_long       FAIL as expected
  pt_m3_adj_active_long_from_second  FAIL as expected
  pt_m4_wrap_early_when_fraction_carried FAIL as expected
  pt_m5_pps_two_cycles_on_later_wraps FAIL as expected
  pt_m6_fns_truncated_on_drift_cycles FAIL as expected
  pt_m7_adjust_unsigned_for_small_magnitudes FAIL as expected
  pt_m8_reset_keeps_reprogrammed_period FAIL as expected
  pt_m9_fourth_window_after_rate_change FAIL as expected
  pt_m10_drift_dropped_when_adjustment_active FAIL as expected

reference testbench vs the POLICY-DIVERGENT base and the same eight defects
  policy base (clean)                PASS as expected
  pt_p10_drift_dropped_when_adjustment_active FAIL as expected
  pt_p1_drift_skipped_one_in_eight   FAIL as expected
  pt_p2_adjust_short_when_long       FAIL as expected
  pt_p3_adj_active_long_from_second  FAIL as expected
  pt_p4_wrap_early_when_fraction_carried FAIL as expected
  pt_p5_pps_two_cycles_on_later_wraps FAIL as expected
  pt_p6_fns_truncated_on_drift_cycles FAIL as expected
  pt_p7_adjust_unsigned_for_small_magnitudes FAIL as expected
  pt_p8_reset_keeps_reprogrammed_period FAIL as expected
  pt_p9_fourth_window_after_rate_change FAIL as expected

OK: every defect is caught on BOTH bases, and both clean implementations
    pass. No mutant is killed by the latitude choice.
```
