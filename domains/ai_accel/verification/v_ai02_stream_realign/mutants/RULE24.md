# Rule 24 — reproduction record for v_ai02_stream_realign

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
  sr_m1_rotation_four_when_three: first difference at cycle 33 -- output beat: golden data=24232221 strb=1111 / mutant data=00000000 strb=1111
  sr_m2_first_beat_emitted_from_third_line: first difference at cycle 142 -- pop_valid_o: golden 0 / mutant 1
  sr_m3_rotation_recaptured_deep_in_line: first difference at cycle 177 -- output beat: golden data=f1f0efee strb=1111 / mutant data=f0efeeed strb=1111
  sr_m4_retain_skipped_after_stall: first difference at cycle 206 -- output beat: golden data=0c0b0a09 strb=1111 / mutant data=0cfbfaf9 strb=1111
  sr_m5_last_dropped_on_long_line: first difference at cycle 231 -- pop_valid_o: golden 1 / mutant 0
  sr_m9_extra_beat_on_late_empty_strobe: first difference at cycle 248 -- pop_valid_o: golden 0 / mutant 1
  sr_m6_strb_from_input_on_last_beat: first difference at cycle 84 -- output beat: golden data=7d7c7b7a strb=1111 / mutant data=7d7c7b7a strb=0011
  sr_m7_drop_every_thirty_second: first difference at cycle 156 -- pop_valid_o: golden 1 / mutant 0
  sr_m8_passthrough_rotates_after_realign: first difference at cycle 262 -- output beat: golden data=55545352 strb=1111 / mutant data=54535255 strb=1111
  sr_m10_admission_withheld_after_long_stall: first difference at cycle 204 -- push_ready_o while offering: golden 1 / mutant 0
  RULE24 positive control : 10 of 10 mutants reported a difference
   exit=0
```

## Step 5c — policy independence

Each `(clean)` line is a control: a conforming implementation must PASS, and a
failing control aborts the run rather than being counted alongside the defects.

```
RULE 24: each "(clean)" line below is a CONTROL -- a conforming
         implementation must PASS. Each defect line is the positive half.

reference testbench vs the GOLDEN base and its ten defects
  golden (clean)                     PASS as expected
  sr_m1_rotation_four_when_three     FAIL as expected
  sr_m2_first_beat_emitted_from_third_line FAIL as expected
  sr_m3_rotation_recaptured_deep_in_line FAIL as expected
  sr_m4_retain_skipped_after_stall   FAIL as expected
  sr_m5_last_dropped_on_long_line    FAIL as expected
  sr_m9_extra_beat_on_late_empty_strobe FAIL as expected
  sr_m6_strb_from_input_on_last_beat FAIL as expected
  sr_m7_drop_every_thirty_second     FAIL as expected
  sr_m8_passthrough_rotates_after_realign FAIL as expected
  sr_m10_admission_withheld_after_long_stall FAIL as expected

reference testbench vs the POLICY-DIVERGENT base and the same ten defects
  policy base (clean)                PASS as expected
  sr_p10_admission_withheld_after_long_stall FAIL as expected
  sr_p1_rotation_four_when_three     FAIL as expected
  sr_p2_first_beat_emitted_from_third_line FAIL as expected
  sr_p3_rotation_recaptured_deep_in_line FAIL as expected
  sr_p4_retain_skipped_after_stall   FAIL as expected
  sr_p5_last_dropped_on_long_line    FAIL as expected
  sr_p6_strb_from_input_on_last_beat FAIL as expected
  sr_p7_drop_every_thirty_second     FAIL as expected
  sr_p8_passthrough_rotates_after_realign FAIL as expected
  sr_p9_extra_beat_on_late_empty_strobe FAIL as expected

OK: every defect is caught on BOTH bases, and both clean implementations
    pass. No mutant is killed by the latitude choice.
```

**Counted from the output above, not from memory:** 11 checks on the golden
base (1 clean PASS + 10 defects FAIL) and 11 on the policy-divergent base
(1 clean PASS + 10 defects FAIL). **22 of 22, all as expected, exit 0.** This
matches the `policy_independence` figure in `../task.yaml`, which had been
asserted while this block read `(not yet run for this task)` -- the number was
right and the reproduction licensing it was missing, which is the half of rule
24 this file exists to carry.

Note for whoever reads the runner's summary: it prints "every defect is caught
on BOTH bases" and **prints no count**. The 22 is arrived at by counting its
lines. A summary that names a scope without stating the number it covered is
the F67 shape, and it is what let a figure sit in task.yaml for as long as it
did with nothing behind it. Count the lines; do not take the sentence.

Run: 2026-08-24 20:55 local, tree 1964dc6-dirty.
