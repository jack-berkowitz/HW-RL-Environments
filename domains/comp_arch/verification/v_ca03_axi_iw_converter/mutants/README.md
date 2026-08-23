# v_ca03 mutant set — these MUST BE CAUGHT

The discriminating measure for a submitted testbench. Opposite sign to
`conformant/`: those satisfy the contract and must survive; these violate it and
must be caught.

Every mutant is **generated**, by `gen_mutants.py`, as a wrapper around the
unmodified golden with two hooks: the slave-side **handshake**, gated so that
the valid going in and the ready coming out move together — no cycle exists in
which one side believes a transaction was accepted and the other does not — and
the slave-side **response channels**, intercepted on the way out.

## Every defect in this set is GUARDED

    defect := wrong_behaviour AND rare_predicate over contract-level state

The previous set of five was boundary-shaped but **total**: each defect held on
every transaction of its class, so it fired on the first one a testbench
happened to drive. Catching it required exercising the class, not checking the
clause.

The guards here name a burst length, how many distinct identifiers are
outstanding, how long the table has been full, an ordinal beat, an ordinal
response, and how busy the table was when an identifier retired.

The occupancy tracker reads the **slave port handshakes** and the golden's own
response stream — never anything inside its table. That is what keeps a mutant
from inheriting the golden's blind spots, and what lets every guard be restated
against a different implementation.

## The set

| id | clause | guard — fires only when… | defect |
|---|---|---|---|
| `iw_m1_blocks_one_early_on_long_bursts` | **A3** | the arriving request's burst is four beats or longer | a new identifier is refused one entry BELOW the boundary |
| `iw_m2_depth_one_short_when_two_ids` | **A5** | two or more distinct identifiers are outstanding on that side | the per-identifier depth stalls one transaction early |
| `iw_m3_entry_freed_late_after_busy_retire` | **A4** | the identifier retired out of a table holding three or more | the freed entry stays blocked four cycles, past A4's two-cycle window |
| `iw_m4_blocks_known_id_when_full_has_aged` | **A3** | the table has been full for four consecutive cycles | a request carrying an ALREADY-outstanding identifier is refused |
| `iw_m5_reads_and_writes_share_when_deep` | **A1** | two or more distinct write identifiers are outstanding | reads and writes are counted against ONE table instead of separately |
| `iw_m6_rid_wrong_deep_in_burst` | **C1** | the fourth beat of a burst and every beat after | a read response beat carries the wrong slave identifier |
| `iw_m7_rdata_corrupt_every_thirty_second` | **E1** | the thirty-second beat delivered, and every one after | a read data beat has its low bit flipped |
| `iw_m8_bresp_wrong_when_full` | **E1** | the write table is full when the response is presented | the write response carries an altered resp field |
| `iw_m9_rlast_early_on_long_bursts` | **D4** | the burst runs to a seventh beat | rlast lands on a beat that is not the burst's last |
| `iw_m10_extra_b_after_sixteen` | **C2** | sixteen write responses have already been delivered | an extra write response appears with nothing outstanding |

## Witnesses — rule 21

`witness.sh` substitutes each mutant for the golden — the same rename the
harness performs — runs the reference against it, and reports the first clause
failure. That message *is* the witness: the observable difference the contract
itself names.

| id | first clause failure |
|---|---|
| `iw_m1_blocks_one_early_on_long_bursts` | FAIL [A3] a new id was refused at MAX_UNIQ-1 distinct outstanding, seven-beat burst (t=17090) |
| `iw_m2_depth_one_short_when_two_ids` | FAIL [A3] an ALREADY-OUTSTANDING id was refused at a full table (t=800) |
| `iw_m3_entry_freed_late_after_busy_retire` | FAIL [A4] entry freed late: new id accepted 5 cycles after retirement, window is 2 (t=2040) |
| `iw_m4_blocks_known_id_when_full_has_aged` | FAIL [A3] an ALREADY-OUTSTANDING id was refused at a full table (t=800) |
| `iw_m5_reads_and_writes_share_when_deep` | FAIL [A1] a READ was refused while only WRITES occupied the table (t=20340) |
| `iw_m6_rid_wrong_deep_in_burst` | FAIL [E1] read beat 0 of slave id 1 carries 00001079, expected 00001177 (t=17055) |
| `iw_m7_rdata_corrupt_every_thirty_second` | FAIL [E1] read beat 0 of slave id 1 carries 0000111e, expected 0000111f (t=6835) |
| `iw_m8_bresp_wrong_when_full` | FAIL [E1] write response for slave id 0 carries resp 01, expected 00 (t=20235) |
| `iw_m9_rlast_early_on_long_bursts` | FAIL [D4] slave id 0: rlast is 1 on beat 5 of a 7-beat burst (t=17075) |
| `iw_m10_extra_b_after_sixteen` | FAIL [C2] write response for slave id 2 with none outstanding (t=27795) |

## The reference killed three of ten, and why

It was **read-only and single-beat**. Its master-side responder returned one
beat of constant data and asserted `rlast` on every beat, which cannot
distinguish a correct response from any other: C1, E1, D4 and the entire write
side went unobserved. It has been rebuilt to honour `arlen`, derive each beat's
data from the address its transaction was issued with, check **every** beat
rather than only the last, drive writes and their B responses, and run long
enough to pass a count in the dozens.

One latent flaw surfaced on the way. `BOUNDARY 5` accepted a write address and
never supplied its `W` burst, leaving that transaction outstanding for the rest
of the run and holding a table entry. Every later write boundary was then
measured one entry short — and reported against the design rather than against
the stimulus that caused it.

A second one was in the witness runner itself: BSD `sed` has no `\b`, so the
rename that substitutes a mutant for the golden silently matched nothing and
**every** witness ran the golden, reporting "no failure observed" for ten
mutants the harness kills. The rename is done in python now.
