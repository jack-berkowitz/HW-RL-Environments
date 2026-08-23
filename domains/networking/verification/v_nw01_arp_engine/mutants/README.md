# v_nw01 mutant set — these MUST BE CAUGHT

Every mutant is **generated**, by `gen_mutants.py`, as a mechanical edit of a
renamed copy of the anchor. Each edit is an exact `old -> new` pair asserted to
match **exactly once**, so a silent no-op cannot produce a mutant identical to
the golden that every testbench "kills" by doing nothing.

## Every defect in this set is GUARDED

    defect := wrong_behaviour AND rare_predicate over contract-level state

The guards name how many lookups have timed out, how many frames have been
learned since the last clear, which retry it is, and whether one of our own
lookups is outstanding when a frame arrives — all counted from the module's own
ports, so each can be restated against an independent implementation.

## The set

| id | clause | guard — fires only when… | defect |
|---|---|---|---|
| `ae_m1_three_requests_from_second_lookup` | **Q4** | the second unanswered lookup, and every one after it | only THREE request frames are transmitted instead of four |
| `ae_m2_last_request_wrong_target` | **Q3** | the LAST of the four requests | it asks for an address one off from the one looked up |
| `ae_m3_cached_mac_wrong_when_full` | **Q1** | four or more frames learned since the last clear -- the cache is full | the MAC answered from the cache has its low byte corrupted |
| `ae_m4_insert_dropped_when_full` | **C2** | four frames have already been learned since the last clear | the insert silently fails, so the address stays unknown |
| `ae_m5_requests_not_learned_after_two` | **C1** | two or more frames have already been learned since the last clear | a received ARP REQUEST does not insert its sender pair; replies still do |
| `ae_m6_reply_target_wrong_while_busy` | **A1** | one of our own lookups is outstanding when the request arrives | the reply names the wrong target hardware address |
| `ae_m7_answers_foreign_target_while_busy` | **A2** | one of our own lookups is outstanding when the request arrives | a request whose TPA is not local_ip_i is answered anyway |
| `ae_m8_ethtype_low_nibble_ignored` | **A3** | the eth_type differs from 0x0806 only in its low nibble, after two frames | a frame that is not ARP is processed as ARP |
| `ae_m9_clear_ignored_when_full` | **C3** | the cache holds four entries when the clear arrives | clear_cache_i does not reach the cache, so every entry survives it |
| `ae_m10_five_requests_on_third_lookup` | **Q4** | the third lookup since reset, and every one after it | FIVE request frames are transmitted instead of four |

## Witnesses — rule 21

`witness.sh` substitutes each mutant for the golden shim, runs the reference
against it, and reports the first clause failure.

| id | first clause failure |
|---|---|
| `ae_m1_three_requests_from_second_lookup` | FAIL Q4: the SECOND unanswered lookup transmitted 3 request(s); exactly 4 are required, on every lookup alike |
| `ae_m2_last_request_wrong_target` | FAIL Q3: retry 3: asked for c0a80108, expected c0a80109 |
| `ae_m3_cached_mac_wrong_when_full` | FAIL Q1: answered 010203040507, expected the cached 010203040506 |
| `ae_m4_insert_dropped_when_full` | FAIL Q1/X3: an address taught just before the clear: no response within 40 cycles |
| `ae_m5_requests_not_learned_after_two` | FAIL Q1/X3: the address of a station that asked us: no response within 40 cycles |
| `ae_m6_reply_target_wrong_while_busy` | FAIL A1: reply THA 000000000000 while a lookup was outstanding, expected the requester's SHA |
| `ae_m7_answers_foreign_target_while_busy` | FAIL A2: a request for another station's address produced 1 reply frame(s) while a lookup was outstanding |
| `ae_m8_ethtype_low_nibble_ignored` | FAIL A3: a frame with eth_type 0800 produced 1 frame(s); it must be ignored |
| `ae_m9_clear_ignored_when_full` | FAIL C3: after clear_cache a previously cached address was still answered from the cache |
| `ae_m10_five_requests_on_third_lookup` | FAIL Q4: an unanswered lookup transmitted 5 request(s); exactly 4 are required |

## The reference killed six of ten

Three of the four it missed came down to **one thing the run never did**: an
incoming ARP frame arriving while one of our own lookups was outstanding. Every
request in the testbench was fed to an idle engine, so A1 and A2 were only ever
checked in the quiet case. The fourth needed a **second** lookup to time out.

That second lookup then had to be moved *ahead* of the reset phase. Reset clears
the timed-out count, so a "second unanswered lookup" placed after a reset is the
first one again — the phase existed and measured nothing.

## A guard that defeated itself

`ae_m9` gates the cache's clear on the cache being full. The occupancy it read
was reset on the **first cycle of the clear pulse**, so the remaining three
cycles of a four-cycle pulse cleared the cache normally and the defect never
appeared. The gate now holds its decision across the whole pulse.
