# Rule 24 — reproduction record for v_nw03_axis_arb_mux

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
  fm_m1_drops_high_payload : FAIL [S4] input 0 tdata: expected ab750060 got 00000060 (t=225000)
  fm_m2_priority_arbitration : FAIL [S10] input 1 has started no frame in 109 completed output frames (window 16) (t=2835000)
  fm_m3_frame_interleaved : FAIL [S3] mid-frame switch: frame from input 3 interrupted by input 1 (t=395000)
  fm_m4_tuser_crossed : FAIL [S4] input 1 tuser: expected 1 got 0 (t=265000)
  fm_m5_early_tlast : FAIL [S4] input 2 tlast: expected 0 got 1 (t=135000)
  fm_m6_reset_ignored : FAIL [S12] m_tvalid_o high on the first cycle after reset release (t=20175000)
  fm_m7_tuser_wrong_on_last : FAIL [S4] input 0 tuser: expected 0 got 1 (t=105000)
  fm_m8_tkeep_full_on_last : FAIL [S4] input 2 tkeep: expected c got f (t=165000)
  fm_m9_marginal_starvation : FAIL [S10] input 3 has started no frame in 113 completed output frames (window 16) (t=2695000)
  fm_m10_deep_beat_corruption : FAIL [S4] input 0 tdata: expected d5ca0090 got e9ba0060 (t=285000)
  RULE24 positive control : 10 of 10 mutants produced a clause failure
   exit=0
```

## Step 5c — policy independence

Each `(clean)` line is a control: a conforming implementation must PASS, and a
failing control aborts the run rather than being counted alongside the defects.

```
v_nw03_axis_arb_mux
reference testbench vs the GOLDEN base and its ten defects
  golden (clean)                                 PASS as expected
  fm_m1_drops_high_payload                       FAIL as expected
  fm_m2_priority_arbitration                     FAIL as expected
  fm_m3_frame_interleaved                        FAIL as expected
  fm_m4_tuser_crossed                            FAIL as expected
  fm_m5_early_tlast                              FAIL as expected
  fm_m6_reset_ignored                            FAIL as expected
  fm_m7_tuser_wrong_on_last                      FAIL as expected
  fm_m8_tkeep_full_on_last                       FAIL as expected
  fm_m9_marginal_starvation                      FAIL as expected
  fm_m10_deep_beat_corruption                    FAIL as expected

reference testbench vs the POLICY-DIVERGENT base and the same ten defects
  policy base (clean)                            PASS as expected
  fm_p10_deep_beat_corruption                    FAIL as expected
  fm_p1_drops_high_payload                       FAIL as expected
  fm_p2_priority_arbitration                     FAIL as expected
  fm_p3_frame_interleaved                        FAIL as expected
  fm_p4_tuser_crossed                            FAIL as expected
  fm_p5_early_tlast                              FAIL as expected
  fm_p6_reset_ignored                            FAIL as expected
  fm_p7_tuser_wrong_on_last                      FAIL as expected
  fm_p8_tkeep_full_on_last                       FAIL as expected
  fm_p9_marginal_starvation                      FAIL as expected

OK: every defect is caught on BOTH bases, and both clean implementations
    pass. No mutant is killed by the latitude choice.
```
