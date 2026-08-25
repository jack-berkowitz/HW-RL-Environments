# Rule 24 — reproduction record for v_ca03_axi_iw_converter

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
  iw_m1_blocks_one_early_on_long_bursts : FAIL [A3] a new id was refused at MAX_UNIQ-1 distinct outstanding, seven-beat burst (t=17090)
  iw_m2_depth_one_short_when_two_ids : FAIL [A3] an ALREADY-OUTSTANDING id was refused at a full table (t=800)
  iw_m3_entry_freed_late_after_busy_retire : FAIL [A4] entry freed late: new id accepted 5 cycles after retirement, window is 2 (t=2040)
  iw_m4_blocks_known_id_when_full_has_aged : FAIL [A3] an ALREADY-OUTSTANDING id was refused at a full table (t=800)
  iw_m5_reads_and_writes_share_when_deep : FAIL [A1] a READ was refused while only WRITES occupied the table (t=20340)
  iw_m6_rid_wrong_deep_in_burst : FAIL [E1] read beat 0 of slave id 1 carries 00001079, expected 00001177 -- the data a beat carries follows from the address its transaction was issued with, which E1 forwards unmodified (t=17055)
  iw_m7_rdata_corrupt_every_thirty_second : FAIL [E1] read beat 0 of slave id 1 carries 0000111e, expected 0000111f -- the data a beat carries follows from the address its transaction was issued with, which E1 forwards unmodified (t=6835)
  iw_m8_bresp_wrong_when_full : FAIL [E1] write response for slave id 0 carries resp 01, expected 00 -- a converter alters identifiers and nothing else (t=20235)
  iw_m9_rlast_early_on_long_bursts : FAIL [D4] slave id 0: rlast is 1 on beat 5 of a 7-beat burst -- one accepted transaction produces exactly one response, of exactly its own length (t=17075)
  iw_m10_extra_b_after_sixteen : FAIL [C2] write response for slave id 2 with none outstanding (t=27795)
  RULE24 positive control : 10 of 10 mutants produced a clause failure
   exit=0
```

## Step 5c — policy independence

Each `(clean)` line is a control: a conforming implementation must PASS, and a
failing control aborts the run rather than being counted alongside the defects.

```
v_ca03_axi_iw_converter
reference testbench vs the GOLDEN base and its ten defects
  golden (clean)                                 PASS as expected
  iw_m1_blocks_one_early_on_long_bursts          FAIL as expected
  iw_m2_depth_one_short_when_two_ids             FAIL as expected
  iw_m3_entry_freed_late_after_busy_retire       FAIL as expected
  iw_m4_blocks_known_id_when_full_has_aged       FAIL as expected
  iw_m5_reads_and_writes_share_when_deep         FAIL as expected
  iw_m6_rid_wrong_deep_in_burst                  FAIL as expected
  iw_m7_rdata_corrupt_every_thirty_second        FAIL as expected
  iw_m8_bresp_wrong_when_full                    FAIL as expected
  iw_m9_rlast_early_on_long_bursts               FAIL as expected
  iw_m10_extra_b_after_sixteen                   FAIL as expected

reference testbench vs the POLICY-DIVERGENT base and the same ten defects
  policy base (clean)                            PASS as expected
  iw_p10_extra_b_after_sixteen                   FAIL as expected
  iw_p1_blocks_one_early_on_long_bursts          FAIL as expected
  iw_p2_depth_one_short_when_two_ids             FAIL as expected
  iw_p3_entry_freed_late_after_busy_retire       FAIL as expected
  iw_p4_blocks_known_id_when_full_has_aged       FAIL as expected
  iw_p5_reads_and_writes_share_when_deep         FAIL as expected
  iw_p6_rid_wrong_deep_in_burst                  FAIL as expected
  iw_p7_rdata_corrupt_every_thirty_second        FAIL as expected
  iw_p8_bresp_wrong_when_full                    FAIL as expected
  iw_p9_rlast_early_on_long_bursts               FAIL as expected

OK: every defect is caught on BOTH bases, and both clean implementations
    pass. No mutant is killed by the latitude choice.
```
