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
- **Reference reachability.** The reference testbench kills all twelve. A mutant
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
| `af_m11_stalls_aw_below_bound` | **W3** | the FIFTH non-atomic AW offered while the debt is below the bound | the AW is stalled although the bound does not license it |
| `af_m12_stalls_aw_with_no_debt` | **W3** | the SECOND non-atomic AW presented while the debt is EMPTY | the AW is stalled with nothing outstanding at all |

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


## W3 needed two mutants, not one, and the id column cannot show why

`af_m11` was written to give W3 a witness and does — at **one** of W3's two
reporting sites. Measured against the reference testbench:

    af_m11    W3 from gov_admitted 1, from gov_aw_timeout 0    ids P2 W3 W4 X4
    af_m12    W3 from gov_admitted 1, from gov_aw_timeout 1    ids P2 W3 W4 X3 X4

The reason is arithmetic. `AxiMaxWriteTxns` is 4, and af_m11 fires from the fifth
non-atomic AW offered below the bound — by which point four writes are
outstanding, so the debt is **at** the bound when the AW finally times out, and
`gov_aw_timeout`'s `(debt_now < bound_) ? "W3" : "X4"` takes the other branch.
The stall was below the bound; the timeout was at it. `af_m12` stalls with the
debt empty, so it is still 0 at the timeout.

**Both sites print the id `W3`.** They are separable only by the text of their
failure messages, and nothing asserts those strings differ — unifying the wording
would destroy the distinction with no test failing. The reachability claim for
this clause depends on that accident, and says so.

### af_m12's ordinal is 1, and 1 is the only value that works

    ordinal   result      ids                W3@aw_timeout  W3@admitted
    (none)    PASS        --                      0              0    <- supply probe
    0         FAIL 16     P2 W3 W4 X4             1              1
    1         FAIL 17     P2 W3 W4 X3 X4          1              1    <- chosen
    2         FAIL 11     P2 W3 W4 X3 X4          0              1
    3         PASS        --                      0              0

Clean-run supply is **two presentations**. Ordinal 0 is unguarded; ordinal 2
still fires but loses the branch the mutant exists for; ordinal 3 is out of
reach. This is shallower than the rest of the set (4th–10th) **because of supply,
not choice** — the reference offers exactly two non-atomic AWs with an empty
debt. The stated fix for a guard out of reach is to extend the reference rather
than dial the guard back; that is not done here because it would change the
supply the other eleven guards were calibrated against.

## Both gaps are closed, and what they cost while open

`af_m11` and `af_m12` are now generated by `gen_mutants.py` (entries in `MUT`),
with policy counterparts `af_p11` and `af_p12` in `POLICY`. Anchor and policy
sets are both twelve, so `check_policy_independence.sh` clears its count guard
and runs: **13 of 13, the clean policy base passing and all twelve defects
caught.**

**What it cost: from the moment af_m11 landed until this was fixed, 5c for this
task produced no verification at all.** The script exited on its count guard
before its first build, while task.yaml went on citing it as a passing check. A
check that refuses is indistinguishable from a check that passes if nobody reads
past the exit code — this one exited 2, and nothing was watching the exit code.

### Regeneration was verified not to move anything

The risk was that a generator-expressed guard is not the hand-written one — in
particular that af_m11 would stop producing the cycle-145 witness `task.yaml`
records.

**The probe was written BEFORE the change and re-run UNMODIFIED afterwards, and
that ordering is why its result is usable.** A check authored after a change is
written by someone who already knows which fields moved, and will tend to compare
the ones that did not; this one could not have been shaped that way. It lives at
`scratchpad/probe_nw02.sh` and prints the two reference-testbench runs read *by
W3 site* — both sites emit the id `W3`, so the id alone cannot separate them —
followed by all twelve non-equivalence witnesses.

**The regeneration was also applied to a `mktemp -d` copy before the real tree.**
That caught a `NameError` in the generator that wrote nothing at all, on a run
whose output still said "ten pre-existing dut files identical, m11/m12
IDENTICAL" — vacuous, since the files had been compared against themselves. The
reassuring lines and the failure that emptied them were three lines apart.

Probed before and after with the same script:

    ten pre-existing dut files      byte-identical
    af_m11 / af_m12 dut files       differ by exactly the shared HELPERS block,
                                    21 added lines, 0 removed, declaring nothing
                                    either guard reads
    af_m11 non-equiv witness        cycle 145, unchanged (task.yaml matches)
    af_m12 non-equiv witness        cycle 139, unchanged (task.yaml matches)
    af_m11 reference tb             10 violations, P2 W3 W4 X4,
                                    W3@aw_timeout 0, W3@admitted 1 -- unchanged
    af_m12 reference tb             17 violations, P2 W3 W4 X3 X4,
                                    W3@aw_timeout 1, W3@admitted 1 -- unchanged
    af_m12 ordinal                  still 1; target branch still fires
    all twelve witnesses            12 of 12, negative control clean
    af_m12 differential             ordinal neutralised -> reference PASSES

The before/after probe output is byte-identical. No witness moved.
