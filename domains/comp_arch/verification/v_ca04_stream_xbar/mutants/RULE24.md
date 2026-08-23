# Rule 24 — reproduction record for v_ca04_stream_xbar

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
  xb_m1_fairness_freeze_at_three: first difference at cycle 186 -- output 0: golden data=5a10003d idx=1 / mutant data=5a00003d idx=0
  xb_m2_rotation_skips_on_fourth_wrap: first difference at cycle 5 -- output 0: golden data=5a000000 idx=0 / mutant data=5a100001 idx=1
  xb_m3_lock_released_after_long_stall: first difference at cycle 185 -- output 0: golden data=5a00003d idx=0 / mutant data=5a10003d idx=1
  xb_m4_starves_input_two_every_eleventh_turn: first difference at cycle 23 -- output 0: golden data=5a200005 idx=2 / mutant data=5a300005 idx=3
  xb_m5_idx_stale_after_long_idle: first difference at cycle 42 -- output 3: golden data=5a30000a idx=3 / mutant data=5a30000a idx=0
  xb_m6_swap_pair_under_backpressure: first difference at cycle 46 -- output 0: golden data=5a00000b idx=0 / mutant data=5a00000a idx=0
  xb_m7_drop_every_sixty_fourth: first difference at cycle 72 -- out_valid_o: golden 1111 / mutant 1110
  xb_m8_duplicate_on_stall_release: first difference at cycle 185 -- in_ready_o (masked by in_valid_i): golden 0001 / mutant 0000
  xb_m9_misroute_under_full_collision: first difference at cycle 1 -- out_valid_o: golden 0001 / mutant 0010
  xb_m10_ready_glitch_when_all_stalled: first difference at cycle 492 -- in_ready_o (masked by in_valid_i): golden 0000 / mutant 0001
  RULE24 positive control : 10 of 10 mutants reported a difference
   exit=0
```

## Step 5c — policy independence

Each `(clean)` line is a control: a conforming implementation must PASS, and a
failing control aborts the run rather than being counted alongside the defects.

```
v_ca04_stream_xbar
reference testbench vs the GOLDEN base and its eight defects
  golden (clean)                     PASS as expected
  xb_m1_fairness_freeze_at_three     FAIL as expected
  xb_m2_rotation_skips_on_fourth_wrap FAIL as expected
  xb_m3_lock_released_after_long_stall FAIL as expected
  xb_m4_starves_input_two_every_eleventh_turn FAIL as expected
  xb_m5_idx_stale_after_long_idle    FAIL as expected
  xb_m6_swap_pair_under_backpressure FAIL as expected
  xb_m7_drop_every_sixty_fourth      FAIL as expected
  xb_m8_duplicate_on_stall_release   FAIL as expected
  xb_m9_misroute_under_full_collision FAIL as expected
  xb_m10_ready_glitch_when_all_stalled FAIL as expected

reference testbench vs the POLICY-DIVERGENT base and the same eight defects
  policy base (clean)                PASS as expected
  xb_p10_ready_glitch_when_all_stalled FAIL as expected
  xb_p1_fairness_freeze_at_three     FAIL as expected
  xb_p2_rotation_skips_on_fourth_wrap FAIL as expected
  xb_p3_lock_released_after_long_stall FAIL as expected
  xb_p4_starves_input_two_every_eleventh_turn FAIL as expected
  xb_p5_idx_stale_after_long_idle    FAIL as expected
  xb_p6_swap_pair_under_backpressure FAIL as expected
  xb_p7_drop_every_sixty_fourth      FAIL as expected
  xb_p8_duplicate_on_stall_release   FAIL as expected
  xb_p9_misroute_under_full_collision FAIL as expected

OK: every defect is caught on BOTH bases, and both clean implementations
    pass. No mutant is killed by the latitude choice.
```
