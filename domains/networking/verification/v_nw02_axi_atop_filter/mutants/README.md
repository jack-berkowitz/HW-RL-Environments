# v_nw02 mutant set — these MUST BE CAUGHT

The discriminating measure for a submitted testbench. Opposite sign to
`conformant/`: that one satisfies the spec and must survive; these violate it
and must be caught.

Every mutant is **generated**, by `gen_mutants.py`, as a mechanical edit of the
golden shim and — where the defect is internal — of a renamed copy of the
anchor. Each edit is an exact `old -> new` pair asserted to match **exactly
once**, so a silent no-op cannot produce a mutant identical to the golden that
every testbench "kills" by doing nothing.

## Every defect in this set is GUARDED

The set was rebuilt for difficulty. Each mutant is now a pair:

    defect := wrong_behaviour AND rare_predicate over contract-level state

A **total** defect — fixed priority, a dropped selector bit, an off-by-one that
holds always — fires on the first transaction of its class. Any testbench that
exercises the class at all catches it, whether or not it is checking the clause.
Such a mutant measures **coverage, not checking**, which is why a submission
that passed the validity gate used to collect most of the old set for free.

A **guarded** defect is caught only by a testbench that constructs the named
configuration and is still checking when it arrives. The guards here name
counts, run lengths, occupancies, repetitions and ordinal positions — burst length, how many writes are outstanding, how long the debt has sat at its bound, how close together two filtered writes fall, and which filtered write it is.

Two constraints bound how far this can go, and both are load-bearing:

- **Fairness.** Every guard names a condition the spec states as a checkable
  bound at a named boundary, so the catching act is derivable from the spec text
  alone. No mutant punishes an unstated expectation.
- **Reference reachability.** The reference testbench kills all ten. A mutant
  the reference cannot reach is not difficult, it is *unverified* — it would be
  scored against submissions on evidence the task itself cannot produce.

Guards are written over **contract-level** state only, never over a register
private to the anchor. That is what makes step 5c possible: each defect is
re-derived on the policy-divergent implementation in `policy/`, which has no
such registers to read.

## The set

| id | clause | guard — fires only when… | defect |
|---|---|---|---|
| `af_m1_admits_fifth_once_full_has_aged` | **W2** | the debt has sat at its bound for eight cycles | a fifth outstanding write is admitted |
| `af_m2_debt_frees_on_b_when_deep` | **W4** | three or more writes outstanding | the debt falls on a B arriving, not on a W burst completing |
| `af_m3_rresp_class_on_bit4_multibeat` | **C2/F5** | the filtered write is multi-beat | the obligation is read from atop[4] instead of atop[5] |
| `af_m4_rbeats_short_on_long_bursts` | **F4** | the burst is four beats or longer | it receives one beat too few |
| `af_m5_rlast_early_from_second_atomic` | **F4** | the second filtered write onward | rlast is also asserted on the first injected beat |
| `af_m6_rresp_okay_on_final_beat` | **F4** | the final beat of an injected burst | it carries OKAY; earlier beats are correct |
| `af_m7_last_absorbed_w_leaks` | **F2** | the final W beat of a filtered write | it reaches the master port; the rest are absorbed |
| `af_m8_stale_id_when_atomics_close` | **F3/F4** | a filtered write follows the previous within twelve cycles | the id is not captured, so the response is stale |
| `af_m9_b_okay_on_first_atomic` | **F3** | the first filtered write after reset | the manufactured B carries OKAY |
| `af_m10_extra_rbeat_on_two_beat_burst` | **F4** | the burst is exactly two beats | it receives three beats |

## Non-equivalence witnesses — rule 16

`nonequiv_tb.sv` drives the golden and one mutant from a shared input sequence
and compares their observable outputs every cycle, each channel's payload masked
by its own `valid`. Run the whole set with `./witness.sh`.

| id | first observable difference |
|---|---|
| `af_m1_admits_fifth_once_full_has_aged` | cycle 154 -- s_awready (the write-admission bound) |
| `af_m2_debt_frees_on_b_when_deep` | cycle 152 -- s_awready (the write-admission bound) |
| `af_m3_rresp_class_on_bit4_multibeat` | cycle 57 -- slave R: golden valid=1 id=4 resp=10 / mutant valid=0 |
| `af_m4_rbeats_short_on_long_bursts` | cycle 59 -- slave R: golden last=0 / mutant last=1 |
| `af_m5_rlast_early_from_second_atomic` | cycle 57 -- slave R: golden last=0 / mutant last=1 |
| `af_m6_rresp_okay_on_final_beat` | cycle 34 -- slave R: golden resp=10 / mutant resp=00 |
| `af_m7_last_absorbed_w_leaks` | cycle 11 -- master W: golden valid=0 / mutant valid=1 |
| `af_m8_stale_id_when_atomics_close` | cycle 12 -- slave B: golden id=2 / mutant id=0 |
| `af_m9_b_okay_on_first_atomic` | cycle 12 -- slave B: golden resp=10 / mutant resp=00 |
| `af_m10_extra_rbeat_on_two_beat_burst` | cycle 92 -- slave R: golden last=1 / mutant last=0 |

## What these need that a single atomic does not

The old set fell to one atomic through an idle filter. This one does not. The
guards require burst lengths driven to particular values rather than left at
one; a second and a third filtered write, both close together and far apart;
the outstanding-write debt driven to its bound *and held there*; and the
injected R burst checked beat by beat rather than only at its last beat.

Attribution matters here. Clause F4 lets an injected R beat precede both the
manufactured B and the write's own W burst, so beats must be attributed by
`s_rid_o`, never by arrival order. A monitor that pairs responses positionally
reports failures on the golden.
