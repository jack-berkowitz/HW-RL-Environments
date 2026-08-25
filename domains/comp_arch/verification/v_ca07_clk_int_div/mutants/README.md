# v_ca07 — the mutant set

Ten defects, uniformly **guarded**: each is a wrong behaviour paired with a rare
predicate over contract-level state, read from the **ports**. A total defect —
one that fires on the first transaction of its class — measures whether a
submission exercised the design at all, not whether it checked anything.

Reading the guards from ports only is what makes step 5c possible: a guard that
reads an implementation-private register cannot be re-derived in a second
implementation that has no such register, and the check silently degrades into
one that cannot fail.

## Weighting

Seven of the ten are **ordinal or depth** conditions, on evidence from two
independent measurements rather than one. `v_nw01` (5 of 10) and the incognito
`v_ai02` (4 of 10) split the same way: conditions that are a property of a
single event get caught — a value, a last beat, a mode — and conditions on the
*n*th occurrence get missed.

## The set

| id | violates | guard | defect |
| --- | --- | --- | --- |
| `cd_m1_period_short_on_large_divisors` | P1 | the divisor is 8 or more -- every smaller divisor is exact | the period is one clk_i cycle shorter than the divisor asks for |
| `cd_m2_duty_stretched_on_odd` | P2 | the divisor is odd AND it is the third odd divisor used or later | the high phase is extended by half a clk_i cycle, so an odd divisor is no longer 50% -- this is the WRONG DUTY RULE this task's own specification carried until the reference caught it |
| `cd_m3_one_not_passthrough_after_large` | P3 | the divisor in force when 1 is requested was 8 or more | divisor 1 divides by two instead of passing through |
| `cd_m4_same_value_gates_from_second` | H3 | the second same-value request since reset, and every one after it | a same-value request gates the clock, where H3 says it must not |
| `cd_m5_second_request_refused` | H4 | the fourth reconfiguration since reset, and every one after it | a request offered during a transition is REFUSED rather than deferred: its ready never rises and the requester must offer again |
| `cd_m6_gate_over_bound_to_passthrough` | G1 | the change is TO pass-through, where the bound is exactly 3 and therefore tight -- every other transition has slack and hides it | the clock is gated one clk_i cycle longer than G1 permits |
| `cd_m7_idle_high_when_disabled_on_odd` | E3 | the divisor in force is odd -- an even divisor disables cleanly | while DISABLED the output idles HIGH instead of low |
| `cd_m8_disable_late_after_four_toggles` | E1 | the fourth en_i transition since reset, and every one after it | disabling takes two extra clk_i cycles, so edges appear after en_i falls |
| `cd_m9_counter_wraps_late_on_large` | C1 | the divisor in force is 6 or more | cycl_count_o reaches div_i instead of wrapping at div_i - 1 |
| `cd_m10_reset_keeps_divisor_from_second` | R2 | the second reset since power-up, and every one after it | reset leaves the last configured divisor in force instead of restoring the default |

Witness lines for all ten, with the rule-24 controls that license them, are in
[RULE24.md](RULE24.md). Regenerate with `./witness.sh`.

## Reference reachability — five survived the first run

None of the five was a submission-difficulty result. **A survivor is a question
about the apparatus, not evidence that the defect is hard.**

- `cd_m3` — the divisor ladder was ordered, so a defect conditioned on coming
  *down* from a large divisor never saw one.
- `cd_m5` — **not a defect at all.** It gated `div_valid_i` and `div_ready_o`
  together, which merely *defers* a request, and H4 permits deferral. The same
  discipline that keeps a conformant perturbation conformant also neuters a
  mutant, and there is no way to tell the two apart by inspection.
- `cd_m6` — the countdown was one negedge short, and it also raced the
  deassertion.
- `cd_m8` — a two-cycle delay is invisible inside a four-cycle period.
- `cd_m10` — the guard wanted a second reset and the reference issued one.

Three of the five were fixed in the reference (phase G2's second reset, the
descending ladder, a shorter period for the enable toggles); two were fixed in
the mutant.

## Step 5c

`in_source_rederivation`, the method that can fail — and did, in four cases on
the first run, all four apparatus faults. One of them, `cd_p3`, exposed a
**glitch in `dut2`**, a legal implementation, in a window the reference had never
measured. Full account in [RULE24.md](RULE24.md).

Regenerate the set with `python3 gen_mutants.py`, which writes both
`mutants.sv` and the ten in-source re-derivations under `policy/`.
