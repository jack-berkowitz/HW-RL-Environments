# v_ca05 mutant set — these MUST BE CAUGHT

Each mutant wraps the unmodified golden and injects exactly one defect. The
occupancy tracker in every wrapper watches the **port handshakes only** — it
never reads anything inside the golden, so a mutant cannot inherit the golden's
own blind spots.

## Every defect in this set is GUARDED

    defect := wrong_behaviour AND rare_predicate over contract-level state

The previous set was boundary-shaped, which was right, but every defect was
**total**: it held on every transaction of its class and so fired on the first
one any testbench drove. Catching it required exercising the class, not checking
the clause.

The guards here name occupancy, per-tag occupancy, how many distinct tags are
present, an ordinal search, and how many times the store has filled — every one
counted from the port handshakes, so each can be restated against an
independent implementation.

## The set

| id | clause | guard — fires only when… | defect |
|---|---|---|---|
| `tt_m1_capacity_off_by_one` | **R1/R5** | the store has already been filled and drained once | accepts only SLOTS-1 entries; full_o rises one entry early |
| `tt_m2_lifo_within_tag` | **R2** | the tag being popped holds three or more entries | the NEWEST entry of that tag is returned instead of the oldest |
| `tt_m3_half_capacity` | **R1** | three or more distinct tags are present | the store holds SLOTS/2 — every transaction is still correct |
| `tt_m4_tag0_starved` | **R1/R6** | the store is at least half full | tag 0 is never granted — starvation, not deadlock |
| `tt_m5_match_ignores_high_byte` | **R12** | the eighth completed search onward | the masked compare silently drops bits 31:24 of the mask |
| `tt_m6_empty_wrong_at_one` | **R14** | the store has been full at some point since reset | empty_o is high at exactly one stored entry |
| `tt_m7_per_tag_cap` | **R1** | two or more distinct tags are present | a per-tag cap of SLOTS/2, while total capacity is correct |
| `tt_m8_peek_removes_last` | **R9** | the store holds four or more entries | a peek REMOVES the entry when its tag holds exactly one |
| `tt_m9_zero_mask_no_hit` | **R13** | the store holds four or more entries | a mask of all zeros reports no hit |
| `tt_m10_full_asserts_late` | **R14** | the SECOND time the store becomes full, and every one after | full_o rises one cycle late |

## Witnesses — rule 21

`witness.sh` substitutes each mutant for the golden — the same rename the
harness performs — runs the reference against it, and reports the first clause
failure.

| id | first clause failure |
|---|---|
| `tt_m1_capacity_off_by_one` | [FAIL] R14 : after push 8: full=0 with 8 entries (t=130000) |
| `tt_m2_lifo_within_tag` | [FAIL] R8 : tag 5: pop_data=a0000007 expected a0000000 (t=215000) |
| `tt_m3_half_capacity` | [FAIL] R14 : after push 8: full=0 with 8 entries (t=130000) |
| `tt_m4_tag0_starved` | [FAIL] R1 : entry 4 on tag 0 refused with 4 of 8 slots free (t=5090000) |
| `tt_m5_match_ignores_high_byte` | [FAIL] R12 : data=71b2c3d4 mask=ff000000 hit=1 expected 0 (t=4755000) |
| `tt_m6_empty_wrong_at_one` | [FAIL] R14 : after pop 7: empty=1 with 1 entries (t=300000) |
| `tt_m7_per_tag_cap` | [FAIL] R1 : entry 5 on tag 0 refused with 3 of 8 slots free (t=5100000) |
| `tt_m8_peek_removes_last` | [FAIL] R8 : tag 7: pop_data_valid=0 expected 1 (t=4635000) |
| `tt_m9_zero_mask_no_hit` | [FAIL] R12 : data=00000000 mask=00000000 hit=0 expected 1 (t=185000) |
| `tt_m10_full_asserts_late` | [FAIL] R14 : full for the SECOND time: full=0 with 8 entries (t=4650000) |

## The reference killed five of ten

It exercised each clause **once, in the easiest configuration available**: an
empty store, a single tag, a first fill, a handful of searches. That is enough
for a total defect and nothing like enough for a guarded one.

It now drives a half-full store, more than `SLOTS/2` entries on one tag with
another tag present, a peek of a single-entry tag while the store is busy, a
**second** fill to capacity, and the discriminating high-byte search after ten
other searches. Every one of those duplicates a clause already checked — what
differs is the configuration it is checked in.

One instrument fault surfaced here too: the witness runner matched `^FAIL`,
while this testbench prints `[FAIL] R14 : …`. Ten real failures were reported as
"no failure observed". A runner that finds nothing looks exactly like a set with
nothing to find.
