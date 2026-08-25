# Rule 24 — reproduction record for v_ca07_clk_int_div

Rule 24 has two halves: the apparatus must reproduce a known-good answer, and
that reproduction must be **recorded alongside the numbers it licenses**. The
numbers are the `witness:` strings, the negative-control profiles and the
`policy_independence` figure in `../task.yaml`. This file is the second half.

Regenerate with `./witness.sh` and `./check_policy_independence.sh`. Both
**refuse** rather than warn: a failed control exits 2 without printing results.

## Counting basis

Every number here is read from a **result line the testbench emits**, never from
a text match in the log. Two reasons, both of them mistakes already made on this
task:

- An earlier runner grepped for the word `VIOLATION` and matched the harness's
  own explanatory prose, reporting one violation for every implementation
  **including the anchor**.
- The negative-control profile first counted printed `FAIL [` lines. The
  testbench stops printing at 40 and keeps counting, so two controls that differ
  by 22 failures both read as exactly 40. The totals below come from the
  `RESULT:` line; the clause set is noted as being drawn from the printed subset
  when it is.

## Witness runner

The **negative** control is the anchor through the same build-and-grep pipeline:
it must produce no clause failure. The **positive** control is that every mutant
must produce one. Neither alone catches both faults these runners have had — a
rename that silently matched nothing, and a grep that did not match the
testbench's failure format.

```
  RULE24 negative control : PASS (anchor produced no clause failure)
  cd_m1_period_short_on_large_divisors : FAIL [P1] A:the divisor ladder: div=8 period 7, expected 8 clk_i cycles (cyc=1593)
  cd_m2_duty_stretched_on_odd : FAIL [P2] A:the divisor ladder: div=11 high phase 60 time units, expected 55 (half of a 110-unit period) (cyc=2280)
  cd_m3_one_not_passthrough_after_large : FAIL [G1] H:LARGE divisor down to pass-through: 8 -> 1: gated 4 cycles from acceptance, bound is 3 (cyc=8309)
  cd_m4_same_value_gates_from_second : FAIL [H3] C:a SAME-VALUE request is a no-op: a same-value request elongated a period to 5; it must not gate (cyc=6156)
  cd_m5_second_request_refused : FAIL [H4] D:a second request during a transition is DEFERRED, not refused: a second request during a transition was never accepted in 600 cycles (cyc=6884)
  cd_m6_gate_over_bound_to_passthrough : FAIL [G1] B:reconfiguration, the gating bound from acceptance: 4 -> 0: gated 4 cycles from acceptance, bound is 3 (cyc=4808)
  cd_m7_idle_high_when_disabled_on_odd : FAIL [E3] E:enable: div 5: the output never came to rest LOW after en_i fell (cyc=7120)
  cd_m8_disable_late_after_four_toggles : FAIL [E1] J:REPEATED enable toggles: toggle 0: 1 rising edge(s) while en_i is low (cyc=10183)
  cd_m9_counter_wraps_late_on_large : FAIL [C1] F:the cycle counter: div=6: cycl_count_o reached 6, range is 0..5 (cyc=7951)
  cd_m10_reset_keeps_divisor_from_second : FAIL [R2] G2:a SECOND reset: after the SECOND reset the period is 7, expected 1 -- reset restores the DEFAULT divisor every time, not only the first (cyc=10817)
  RULE24 positive control : 10 of 10 mutants produced a clause failure

negative controls -- caught, on which clause, and how the profiles differ
  stuck_high_dut                       FAIL [P1] A:the divisor ladder: div=0 produced 0 rising edges where several were due (cyc=154)
                                         profile: 181 failures on {C1,E2,E3,G1,P1} (clauses among the first 40 printed of 181)
  reset_polarity_dut                   FAIL [P1] A:the divisor ladder: div=0 produced 0 rising edges where several were due (cyc=154)
                                         profile: 159 failures on {H1,P1} (clauses among the first 40 printed of 159)
  h3_nc1_throttle_hits_same_value      FAIL [H3] C:a SAME-VALUE request is a no-op: a same-value request was granted after 4 cycles, expected the same cycle (cyc=6328)
                                         profile: 1 failures on {H3}
  h3_nc2_extra_gating_hits_same_value  FAIL [H3] C:a SAME-VALUE request is a no-op: a same-value request elongated a period to 5; it must not gate (cyc=6156)
                                         profile: 2 failures on {H3}
```

### What the negative controls establish, and what they do not

`stuck_high_dut` and `reset_polarity_dut` fail **first on the same line** —
div=0 produced no rising edges — for two different reasons: an output stuck high
has no rising edges, and a design held in reset has no output. A first-failure
line alone would present them as one demonstration repeated. Their **profiles**
separate them, 181 failures across five clauses against 159 across two, and that
is the only reason both are worth keeping.

The two `h3_*` controls are the strongest evidence here and **neither was built
to be caught**. They are the first drafts of conformant perturbations c1 and c3,
preserved verbatim in `../negctl/h3_violating_perturbations.sv`. Both were
written as legal variants turning latitude L3 and L2 genuinely leave free, and
both broke H3 by failing to distinguish a real change from a request for the
value already in force. The reference refused them **on H3 and on nothing else**
— one failure and two failures respectively, no collateral. A gate mutant with
every output tied high demonstrates a floor. This demonstrates discrimination,
and it cost nothing, because the two mistakes were already made.

## Step 5c — in-source re-derivation

Each `(clean)` line is a control. A failing control **aborts**.

This task's 5c is `in_source_rederivation`, not `wrapper_pointed`: each of the
ten defects is written into `dut2/clk_ratio_div_alt.sv`'s **own source**, in its
own terms — a counter and a half-cycle-delayed phase, where the anchor is a state
machine with a clock-gate cell. This is the method that **can fail**, and on the
first run it did, in four cases. All four were faults in this task's apparatus,
not in the mutants — and one of the four took three passes to diagnose, because
the first two readings blamed the guard when the stimulus was at fault:

| mutant | what the mismatch actually was |
| --- | --- |
| `cd_p3` | **A hole in the reference.** `check_change` measured the gating *gap* and never the *period the change settled at*, so a defect that alters which divisor lands was invisible on a base whose gap does not move. Closing it exposed a real glitch in `dut2` — see below. |
| `cd_p5` | **A second hole in the reference, and it took three attempts to find.** The guard first counted *deferrals*, whose frequency is an L2/L4 consequence; re-keyed to the fourth reconfiguration it was armed four times and the reference still passed, which said the guard was fine and the STIMULUS was not. Phase D dropped `div_valid_i` for one cycle between the two requests, and that cycle is the whole of a fast implementation's transition — so the phase stopped exercising H4 on exactly the implementations that make it hardest. The second request now lands in the cycle after acceptance, with valid held high. |
| `cd_p7` | Same class: idling high *while gated* is only observable for as long as the gate lasts, which is L2. Re-keyed to the **disabled** state, whose length the testbench controls. |
| `cd_p10` | An off-by-one in the re-derivation itself. |

**`cd_p3` found a defect in a legal implementation.** With the period check
added, `dut2` failed: across a reconfiguration it emitted a half-cycle runt and
then a short pulse before settling, because its output gate opened onto a phase
that was already high. A glitch-free divider producing a glitch, in the one
window the reference had never looked at. `dut2`'s gate now moves only while the
signal it gates is low.

```
RULE 24: each "(clean)" line is a CONTROL and must PASS.

reference testbench vs the ANCHOR and its ten defects
  anchor (clean)                                 PASS as expected
  cd_m1_period_short_on_large_divisors           FAIL as expected
  cd_m2_duty_stretched_on_odd                    FAIL as expected
  cd_m3_one_not_passthrough_after_large          FAIL as expected
  cd_m4_same_value_gates_from_second             FAIL as expected
  cd_m5_second_request_refused                   FAIL as expected
  cd_m6_gate_over_bound_to_passthrough           FAIL as expected
  cd_m7_idle_high_when_disabled_on_odd           FAIL as expected
  cd_m8_disable_late_after_four_toggles          FAIL as expected
  cd_m9_counter_wraps_late_on_large              FAIL as expected
  cd_m10_reset_keeps_divisor_from_second         FAIL as expected

reference testbench vs the POLICY-DIVERGENT base and the same ten defects
  policy base (clean)                            PASS as expected
  cd_p10_reset_keeps_divisor_from_second         FAIL as expected
  cd_p1_period_short_on_large_divisors           FAIL as expected
  cd_p2_duty_stretched_on_odd                    FAIL as expected
  cd_p3_one_not_passthrough_after_large          FAIL as expected
  cd_p4_same_value_gates_from_second             FAIL as expected
  cd_p5_second_request_refused                   FAIL as expected
  cd_p6_gate_over_bound_to_passthrough           FAIL as expected
  cd_p7_idle_high_when_disabled_on_odd           FAIL as expected
  cd_p8_disable_late_after_four_toggles          FAIL as expected
  cd_p9_counter_wraps_late_on_large              FAIL as expected

OK: every defect is caught on BOTH bases, and both clean implementations
    pass. No mutant is killed by the latitude choice.
```

## What the 5c number does license

22 of 22 by `in_source_rederivation`. The guards survive being expressed in the
terms of a second, independently written implementation, which is a stronger
claim than `wrapper_pointed` — where the guard logic is literally the same code
on both bases and the property therefore holds by construction. **A 22/22 from
the two methods is not the same number.** See `../task.yaml` under
`policy_derivation`.
