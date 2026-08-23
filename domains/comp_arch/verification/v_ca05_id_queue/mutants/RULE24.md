# Rule 24 — reproduction record for v_ca05_id_queue

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
  RULE24 negative control : PASS (golden produced no clause failure)
  tt_m1_capacity_off_by_one : [FAIL] R14 : after push 8: full=0 with 8 entries   (t=130000)
  tt_m2_lifo_within_tag : [FAIL] R8 : tag 5: pop_data=a0000007 expected a0000000   (t=215000)
  tt_m3_half_capacity : [FAIL] R14 : after push 8: full=0 with 8 entries   (t=130000)
  tt_m4_tag0_starved : [FAIL] R1 : entry 4 on tag 0 refused with 4 of 8 slots free -- entries are shared between tags, not reserved   (t=5090000)
  tt_m5_match_ignores_high_byte : [FAIL] R12 : data=71b2c3d4 mask=ff000000 hit=1 expected 0   (t=4755000)
  tt_m6_empty_wrong_at_one : [FAIL] R14 : after pop 7: empty=1 with 1 entries   (t=300000)
  tt_m7_per_tag_cap : [FAIL] R1 : entry 5 on tag 0 refused with 3 of 8 slots free -- entries are shared between tags, not reserved   (t=5100000)
  tt_m8_peek_removes_last : [FAIL] R8 : tag 7: pop_data_valid=0 expected 1   (t=4635000)
  tt_m9_zero_mask_no_hit : [FAIL] R12 : data=00000000 mask=00000000 hit=0 expected 1   (t=185000)
  tt_m10_full_asserts_late : [FAIL] R14 : full for the SECOND time: full=0 with 8 entries   (t=4650000)
  RULE24 positive control : 10 of 10 mutants produced a clause failure
   exit=0
```

## Step 5c — policy independence

Each `(clean)` line is a control: a conforming implementation must PASS, and a
failing control aborts the run rather than being counted alongside the defects.

```
v_ca05_id_queue
reference testbench vs the GOLDEN base and its ten defects
  golden (clean)                                 PASS as expected
  tt_m1_capacity_off_by_one                      FAIL as expected
  tt_m2_lifo_within_tag                          FAIL as expected
  tt_m3_half_capacity                            FAIL as expected
  tt_m4_tag0_starved                             FAIL as expected
  tt_m5_match_ignores_high_byte                  FAIL as expected
  tt_m6_empty_wrong_at_one                       FAIL as expected
  tt_m7_per_tag_cap                              FAIL as expected
  tt_m8_peek_removes_last                        FAIL as expected
  tt_m9_zero_mask_no_hit                         FAIL as expected
  tt_m10_full_asserts_late                       FAIL as expected

reference testbench vs the POLICY-DIVERGENT base and the same ten defects
  policy base (clean)                            PASS as expected
  tt_p10_full_asserts_late                       FAIL as expected
  tt_p1_capacity_off_by_one                      FAIL as expected
  tt_p2_lifo_within_tag                          FAIL as expected
  tt_p3_half_capacity                            FAIL as expected
  tt_p4_tag0_starved                             FAIL as expected
  tt_p5_match_ignores_high_byte                  FAIL as expected
  tt_p6_empty_wrong_at_one                       FAIL as expected
  tt_p7_per_tag_cap                              FAIL as expected
  tt_p8_peek_removes_last                        FAIL as expected
  tt_p9_zero_mask_no_hit                         FAIL as expected

OK: every defect is caught on BOTH bases, and both clean implementations
    pass. No mutant is killed by the latitude choice.
```
