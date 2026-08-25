# Rule 24 — reproduction record for v_ca06_axi_dw_downsizer

Rule 24 has two halves: the apparatus must reproduce a known-good answer, and
that reproduction must be **recorded alongside the numbers it licenses**. The
numbers are the `witness:` strings and the `policy_independence` figure in
`../task.yaml`. This file is the second half.

Regenerate with `./witness.sh` and `./check_policy_independence.sh`.

**Both blocks below were re-measured on 2026-08-24**, under a generator that
wipes `policy/` and validates every substitution before writing, and a 5c runner
that refuses when the two halves are not the same size. The previous 5c block
dated from `f5f8e45` and `dut2` changed at `605974d` — so it was a measurement
whose base had moved underneath it. The re-run agrees with it, but it agrees now
for a reason that can be checked.

## Witness runner

The **negative** control is the golden through the same build-and-grep pipeline:
it must produce no clause failure, which catches a runner that reports a failure
unconditionally. The **positive** control is that every mutant must produce one,
which catches the two faults these runners have actually had — a rename that
silently matched nothing, and a grep that did not match the testbench's failure
format. Both turned a real failure into silence, and neither would be caught by
one control alone. The runner **refuses** rather than warns: a failed control
exits 2 without printing witnesses.

```
  RULE24 negative control : PASS (golden produced no clause failure)
  dw_m1_len_simple_formula_when_unaligned : FAIL [B2] B:reads, UNALIGNED -- B2 follows bytes covered: downstream arlen 7, expected 5 (bytes covered, not beat count) (t=1525)
  dw_m2_size_raised_when_narrow : FAIL [B1] A:reads, aligned: downstream arsize 1, expected min(size,1)=0 (t=85)
  dw_m3_len_short_from_eighth_read : FAIL [B2] A:reads, aligned: downstream arlen 2, expected 3 (bytes covered, not beat count) (t=525)
  dw_m4_fixed_single_refused_from_second : FAIL [D5] C2:FIXED of ONE beat is SERVED: R beat 0 carries resp 10, expected 0 (t=2355)
  dw_m5_refused_served_from_third : FAIL [C4] C:refused reads: refused read, R beat 0 carries resp 0, expected SLVERR on EVERY beat (t=2145)
  dw_m6_slverr_only_on_last_beat : FAIL [C4] C:refused reads: refused read, R beat 0 carries resp 0, expected SLVERR on EVERY beat (t=1985)
  dw_m7_zero_strobe_beat_dropped_midburst : FAIL [E3] F:writes, SPARSE strobes -- E2 and E3: downstream burst has 3 beats, expected exactly 4 -- an unstrobed beat is still a beat (t=4295)
  dw_m8_strb_wrong_every_thirty_second : FAIL [E2] E:writes, aligned: downstream beat 3 strb 0, expected 11 (t=4075)
  dw_m9_rdata_lanes_swapped_deep_in_burst : FAIL [D1] D:long reads: R beat 4 data 8283808186878584, expected 8283808186878485 on the lanes it covers (t=2585)
  dw_m10_rlast_withheld_from_sixteenth_read : FAIL [D4] A:reads, aligned: rlast is 0 on beat 2 of a 3-beat response (t=1295)
  dw_m11_downstream_error_dropped_from_second : FAIL [D6] M:DOWNSTREAM ERRORS -- D6 is sticky, D7 preserves the code: R beat 0 carries resp 0, expected 10 -- an error is STICKY from the beat it occurs on (t=13885)
  dw_m12_error_code_normalised_from_second : FAIL [D7] M:DOWNSTREAM ERRORS -- D6 is sticky, D7 preserves the code: R beat 1 carries resp 10 where the slave returned 11 -- an error, of the WRONG KIND; the code is preserved, not normalised (t=14685)
  RULE24 positive control : 12 of 12 mutants produced a clause failure
```

## Step 5c

Each `(clean)` line is a control — a conforming implementation must PASS — and a
failing control **aborts** rather than being counted with the defects, because a
run whose control failed licenses nothing.

```
RULE 24: each "(clean)" line below is a CONTROL -- a conforming
         implementation must PASS. Each defect line is the positive half.

reference testbench vs the GOLDEN base and its 12 defects
  golden (clean)                                 PASS as expected
  dw_m1_len_simple_formula_when_unaligned        FAIL as expected
  dw_m2_size_raised_when_narrow                  FAIL as expected
  dw_m3_len_short_from_eighth_read               FAIL as expected
  dw_m4_fixed_single_refused_from_second         FAIL as expected
  dw_m5_refused_served_from_third                FAIL as expected
  dw_m6_slverr_only_on_last_beat                 FAIL as expected
  dw_m7_zero_strobe_beat_dropped_midburst        FAIL as expected
  dw_m8_strb_wrong_every_thirty_second           FAIL as expected
  dw_m9_rdata_lanes_swapped_deep_in_burst        FAIL as expected
  dw_m10_rlast_withheld_from_sixteenth_read      FAIL as expected
  dw_m11_downstream_error_dropped_from_second    FAIL as expected
  dw_m12_error_code_normalised_from_second       FAIL as expected

reference testbench vs the POLICY-DIVERGENT base and the same defects
  policy base (clean)                            PASS as expected
  dw_p10_rlast_withheld_from_sixteenth_read      FAIL as expected
  dw_p11_downstream_error_dropped_from_second    FAIL as expected
  dw_p12_error_code_normalised_from_second       FAIL as expected
  dw_p1_len_simple_formula_when_unaligned        FAIL as expected
  dw_p2_size_raised_when_narrow                  FAIL as expected
  dw_p3_len_short_from_eighth_read               FAIL as expected
  dw_p4_fixed_single_refused_from_second         FAIL as expected
  dw_p5_refused_served_from_third                FAIL as expected
  dw_p6_slverr_only_on_last_beat                 FAIL as expected
  dw_p7_zero_strobe_beat_dropped_midburst        FAIL as expected
  dw_p8_strb_wrong_every_thirty_second           FAIL as expected
  dw_p9_rdata_lanes_swapped_deep_in_burst        FAIL as expected

OK: every defect is caught on BOTH bases, and both clean implementations
    pass. No mutant is killed by the latitude choice.
```

## What the 5c number does NOT license

This task's 5c is `wrapper_pointed`, not `in_source_rederivation` — see
`../task.yaml` under `policy_derivation`. The mutants are wrappers whose guard
logic is literally the same code on both bases, so there is nothing
anchor-specific for the check to catch and the property holds **by
construction**. It establishes that the defects survive an implementation with
different latency, structure and scheduling. It does **not** establish that the
guards were stress-tested against an independent reading of the contract, which
is what the in-source method tests and can fail.
