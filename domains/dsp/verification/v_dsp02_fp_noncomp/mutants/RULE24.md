# Rule 24 — reproduction record for v_dsp02_fp_noncomp

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
  fn_m1_classify_subnormal_as_zero : FAIL [S12] classify a=807fffff : mask expected 0000000100 got 0000001000
  fn_m2_ieee2019_minmax : FAIL [S4] op=1 mode=1 a=00000000 b=7fa00000 : result expected 00000000 got 7fc00000
  fn_m3_minmax_ignores_zero_sign : FAIL [S3] op=1 mode=0 a=80000000 b=00000000 : result expected 80000000 got 00000000
  fn_m4_feq_is_signalling : FAIL [S9] op=2 mode=2 a=80000000 b=7fc00000 : NV expected 0 got 1
  fn_m5_sgnjx_becomes_sgnj : FAIL [S1] op=0 mode=2 a=80000000 b=00000000 : result expected 80000000 got 00000000
  fn_m6_sgnj_canonicalises_nan : FAIL [S1] op=0 mode=0 a=ffd5a5a5 b=00000000 : result expected 7fd5a5a5 got 7fc00000
  fn_m7_sgnj_quiets_snan : FAIL [S1] op=0 mode=2 a=7fa00000 b=80000000 : result expected ffa00000 got ffe00000
  fn_m8_max_subnormal_is_normal : FAIL [S12] classify a=807fffff : mask expected 0000000100 got 0000000010
  fn_m9_feq_distinguishes_zeros : FAIL [S7] op=2 mode=2 a=80000000 b=00000000 : result expected 00000001 got 00000000
  fn_m10_minmax_snan_not_invalid : FAIL [S6] op=1 mode=1 a=80000000 b=ff812345 : NV expected 1 got 0
  RULE24 positive control : 10 of 10 mutants produced a clause failure
   exit=0
```

## Step 5c — policy independence

Each `(clean)` line is a control: a conforming implementation must PASS, and a
failing control aborts the run rather than being counted alongside the defects.

```
v_dsp02_fp_noncomp
reference testbench vs the GOLDEN base and its ten defects
  golden (clean)                                 PASS as expected
  fn_m1_classify_subnormal_as_zero               FAIL as expected
  fn_m2_ieee2019_minmax                          FAIL as expected
  fn_m3_minmax_ignores_zero_sign                 FAIL as expected
  fn_m4_feq_is_signalling                        FAIL as expected
  fn_m5_sgnjx_becomes_sgnj                       FAIL as expected
  fn_m6_sgnj_canonicalises_nan                   FAIL as expected
  fn_m7_sgnj_quiets_snan                         FAIL as expected
  fn_m8_max_subnormal_is_normal                  FAIL as expected
  fn_m9_feq_distinguishes_zeros                  FAIL as expected
  fn_m10_minmax_snan_not_invalid                 FAIL as expected

reference testbench vs the POLICY-DIVERGENT base and the same ten defects
  policy base (clean)                            PASS as expected
  fn_p10_minmax_snan_not_invalid                 FAIL as expected
  fn_p1_classify_subnormal_as_zero               FAIL as expected
  fn_p2_ieee2019_minmax                          FAIL as expected
  fn_p3_minmax_ignores_zero_sign                 FAIL as expected
  fn_p4_feq_is_signalling                        FAIL as expected
  fn_p5_sgnjx_becomes_sgnj                       FAIL as expected
  fn_p6_sgnj_canonicalises_nan                   FAIL as expected
  fn_p7_sgnj_quiets_snan                         FAIL as expected
  fn_p8_max_subnormal_is_normal                  FAIL as expected
  fn_p9_feq_distinguishes_zeros                  FAIL as expected

OK: every defect is caught on BOTH bases, and both clean implementations
    pass. No mutant is killed by the latitude choice.
```
