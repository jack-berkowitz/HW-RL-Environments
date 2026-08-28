# Rule 24 — reproduction record for v_nw02_axi_atop_filter

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
  af_m1_admits_fifth_once_full_has_aged: first difference at cycle 154 -- s_awready (the write-admission bound)
  af_m2_debt_frees_on_b_when_deep: first difference at cycle 152 -- s_awready (the write-admission bound)
  af_m3_rresp_class_on_bit4_multibeat: first difference at cycle 57 -- slave R: golden valid=1 id=4 resp=10 last=0 / mutant valid=0 id=0 resp=00 last=0
  af_m4_rbeats_short_on_long_bursts: first difference at cycle 59 -- slave R: golden valid=1 id=4 resp=10 last=0 / mutant valid=1 id=4 resp=10 last=1
  af_m5_rlast_early_from_second_atomic: first difference at cycle 57 -- slave R: golden valid=1 id=4 resp=10 last=0 / mutant valid=1 id=4 resp=10 last=1
  af_m6_rresp_okay_on_final_beat: first difference at cycle 34 -- slave R: golden valid=1 id=3 resp=10 last=1 / mutant valid=1 id=3 resp=00 last=1
  af_m7_last_absorbed_w_leaks: first difference at cycle 11 -- master W: golden valid=0 data=d0000000 last=1 / mutant valid=1 data=d0000000 last=1
  af_m8_stale_id_when_atomics_close: first difference at cycle 12 -- slave B: golden valid=1 id=2 resp=10 / mutant valid=1 id=0 resp=10
  af_m9_b_okay_on_first_atomic: first difference at cycle 12 -- slave B: golden valid=1 id=2 resp=10 / mutant valid=1 id=2 resp=00
  af_m10_extra_rbeat_on_two_beat_burst: first difference at cycle 92 -- slave R: golden valid=1 id=9 resp=10 last=1 / mutant valid=1 id=9 resp=10 last=0
  RULE24 positive control : 10 of 10 mutants reported a difference

  # RE-RUN 2026-08-27, after af_m11_stalls_aw_below_bound was added to give W3 a
  # witness. The transcript above is left as recorded -- it was true of a
  # ten-mutant set and rewriting it would erase that the set changed.
  af_m11_stalls_aw_below_bound: first difference at cycle 145 -- s_awready (the write-admission bound)
  RULE24 negative control : PASS (golden vs golden: no difference)
  RULE24 positive control : 11 of 11 mutants reported a difference
   exit=0
```

## Step 5c — policy independence

Each `(clean)` line is a control: a conforming implementation must PASS, and a
failing control aborts the run rather than being counted alongside the defects.

```
v_nw02_axi_atop_filter
reference testbench vs the POLICY-DIVERGENT base and its ten defects
  policy base (clean)          PASS as expected
  af_p10_extra_rbeat_on_two_beat_burst FAIL as expected
  af_p1_admits_fifth_once_full_has_aged FAIL as expected
  af_p2_debt_frees_on_b_when_deep FAIL as expected
  af_p3_rresp_class_on_bit4_multibeat FAIL as expected
  af_p4_rbeats_short_on_long_bursts FAIL as expected
  af_p5_rlast_early_from_second_atomic FAIL as expected
  af_p6_rresp_okay_on_final_beat FAIL as expected
  af_p7_last_absorbed_w_leaks  FAIL as expected
  af_p8_stale_id_when_atomics_close FAIL as expected
  af_p9_b_okay_on_first_atomic FAIL as expected

OK: every defect is caught on BOTH bases, so none of them is killed by
    the latitude choice. The clean policy implementation still passes.
```

  # RE-RUN 2026-08-27, after af_m12_stalls_aw_with_no_debt was added because
  # af_m11 reaches only ONE of W3's two reporting sites. Transcripts above are
  # left as recorded -- each was true of the set it described.
  af_m12_stalls_aw_with_no_debt: first difference at cycle 139 -- s_awready (the write-admission bound)

  # Reference-testbench side, read by SITE rather than by id, because both sites
  # print "W3" and the id alone cannot separate them:
  #   af_m11   W3 from gov_admitted 1, from gov_aw_timeout 0   ids P2 W3 W4 X4
  #   af_m12   W3 from gov_admitted 1, from gov_aw_timeout 1   ids P2 W3 W4 X3 X4
  # Ordinal sweep for af_m12 (clean-run supply is TWO presentations):
  #   0 FAIL16 aw_timeout=1 unguarded | 1 FAIL17 aw_timeout=1 CHOSEN
  #   2 FAIL11 aw_timeout=0           | 3 PASS   out of reach
  # Differential control: with the ordinal neutralised the reference PASSES, so
  # the perturbation is entirely guard-gated.

  # 5c RE-RUN 2026-08-27, after af_m11/af_m12 were folded into gen_mutants.py
  # and p11/p12 generated. THIS IS THE FIRST TIME THIS SCRIPT HAS RUN since
  # af_m11 landed -- before this it exited on its count guard, before its first
  # build, producing no verification while task.yaml cited it as passing.
  reference testbench vs the POLICY-DIVERGENT base and the same 12 defects
    policy base (clean)          PASS as expected
    af_p1..af_p12                FAIL as expected  (12 of 12)
  OK: all 13 checks here pass.
   exit=0

  # Regeneration probe, identical script run BEFORE and AFTER -- output was
  # byte-identical, so no recorded witness moved:
  #   ten pre-existing dut files    byte-identical
  #   af_m11 / af_m12 dut files      +21 lines, -0: exactly the shared HELPERS
  #                                  block, declaring nothing either guard reads
  #   af_m11 witness  cycle 145 (unchanged)   af_m12 witness  cycle 139 (unchanged)
  #   af_m11 ref tb   10 viol, P2 W3 W4 X4,    W3@aw_timeout 0, W3@admitted 1
  #   af_m12 ref tb   17 viol, P2 W3 W4 X3 X4, W3@aw_timeout 1, W3@admitted 1
  #   af_m12 ordinal still 1; differential (ordinal neutralised) -> ref PASSES
  #   all twelve non-equivalence witnesses: 12 of 12, negative control clean
