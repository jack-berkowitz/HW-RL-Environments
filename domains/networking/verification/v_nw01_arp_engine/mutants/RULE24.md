# Rule 24 — reproduction record for v_nw01_arp_engine

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
  ae_m1_three_requests_from_second_lookup : FAIL Q4: the SECOND unanswered lookup transmitted 3 request(s); exactly 4 are required, on every lookup alike
  ae_m2_last_request_wrong_target : FAIL Q3: retry 3: asked for c0a80108, expected c0a80109 -- an address inside the subnet is asked for directly, one outside it via the gateway
  ae_m3_cached_mac_wrong_when_full : FAIL Q1: an address taught just before the clear: answered 010203040507, expected the cached 010203040506
  ae_m4_insert_dropped_when_full : FAIL Q1/X3: an address taught just before the clear: no response within 40 cycles
  ae_m5_requests_not_learned_after_two : FAIL Q1/X3: the address of a station that asked us: no response within 40 cycles
  ae_m6_reply_target_wrong_while_busy : FAIL A1: reply THA 000000000000 while a lookup was outstanding, expected the requester's SHA
  ae_m7_answers_foreign_target_while_busy : FAIL A2: a request for another station's address produced 1 reply frame(s) while a lookup was outstanding
  ae_m8_ethtype_low_nibble_ignored : FAIL A3: a frame with eth_type 0800 produced 1 frame(s); it must be ignored
  ae_m9_clear_ignored_when_full : FAIL C3: after clear_cache a previously cached address was still answered from the cache
  ae_m10_five_requests_on_third_lookup : FAIL Q4: an unanswered lookup transmitted 5 request(s); exactly 4 are required
  RULE24 positive control : 10 of 10 mutants produced a clause failure
   exit=0
```

## Step 5c — policy independence

Each `(clean)` line is a control: a conforming implementation must PASS, and a
failing control aborts the run rather than being counted alongside the defects.

```
RULE 24: each "(clean)" line below is a CONTROL -- a conforming
         implementation must PASS. Each defect line is the positive half.

reference testbench vs the GOLDEN base and its ten defects
  golden (clean)                   PASS as expected
  ae_m1_three_requests_from_second_lookup FAIL as expected
  ae_m2_last_request_wrong_target  FAIL as expected
  ae_m3_cached_mac_wrong_when_full FAIL as expected
  ae_m4_insert_dropped_when_full   FAIL as expected
  ae_m5_requests_not_learned_after_two FAIL as expected
  ae_m6_reply_target_wrong_while_busy FAIL as expected
  ae_m7_answers_foreign_target_while_busy FAIL as expected
  ae_m8_ethtype_low_nibble_ignored FAIL as expected
  ae_m9_clear_ignored_when_full    FAIL as expected
  ae_m10_five_requests_on_third_lookup FAIL as expected

reference testbench vs the POLICY-DIVERGENT base and the same ten defects
  policy base (clean)              PASS as expected
  ae_p10_five_requests_on_third_lookup FAIL as expected
  ae_p1_three_requests_from_second_lookup FAIL as expected
  ae_p2_last_request_wrong_target  FAIL as expected
  ae_p3_cached_mac_wrong_when_full FAIL as expected
  ae_p4_insert_dropped_when_full   FAIL as expected
  ae_p5_requests_not_learned_after_two FAIL as expected
  ae_p6_reply_target_wrong_while_busy FAIL as expected
  ae_p7_answers_foreign_target_while_busy FAIL as expected
  ae_p8_ethtype_low_nibble_ignored FAIL as expected
  ae_p9_clear_ignored_when_full    FAIL as expected

OK: every defect is caught on BOTH bases, and both clean implementations
    pass. No mutant is killed by the latitude choice.
```
