# v_ca04 mutant set — these MUST BE CAUGHT

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
counts, run lengths, occupancies, repetitions and ordinal positions — how many inputs contend, how long an output has stalled or idled, how many beats it has delivered.

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
| `xb_m1_fairness_freeze_at_three` | **A2** | exactly three inputs contend for one output | the rotation freezes |
| `xb_m2_rotation_skips_on_fourth_wrap` | **A2** | the fourth complete wrap of the rotation | it lands one place past input 0, skipping its turn |
| `xb_m3_lock_released_after_long_stall` | **A3** | the output has stalled eight consecutive cycles | an already-offered beat is re-aimed |
| `xb_m4_starves_input_two_every_eleventh_turn` | **A2** | one rotation in every eleven | input 2 loses its turn |
| `xb_m5_idx_stale_after_long_idle` | **R3** | the output has been idle eight cycles | out_idx_o names the previous source; the payload is right |
| `xb_m6_swap_pair_under_backpressure` | **R5** | two beats, one input to one output, separated by a stall | they arrive in the opposite order |
| `xb_m7_drop_every_sixty_fourth` | **R4** | the sixty-fourth beat delivered on an output | it is silently dropped |
| `xb_m8_duplicate_on_stall_release` | **R4** | the beat released after a stall of four or more cycles | it is delivered twice |
| `xb_m9_misroute_under_full_collision` | **R1** | all four inputs target one output at once | a beat lands on the next output along |
| `xb_m10_ready_glitch_when_all_stalled` | **I2** | every output stalled at once | input 0 is accepted although nothing can take its beat |

## Non-equivalence witnesses — rule 16

`nonequiv_tb.sv` drives the golden and one mutant from a shared input sequence
and compares their observable outputs every cycle, each channel's payload masked
by its own `valid`. Run the whole set with `./witness.sh`.

| id | first observable difference |
|---|---|
| `xb_m1_fairness_freeze_at_three` | cycle 186 -- output 0: golden data=5a10003d idx=1 / mutant data=5a00003d idx=0 |
| `xb_m2_rotation_skips_on_fourth_wrap` | cycle 5 -- output 0: golden data=5a000000 idx=0 / mutant data=5a100001 idx=1 |
| `xb_m3_lock_released_after_long_stall` | cycle 185 -- output 0: golden data=5a00003d idx=0 / mutant data=5a10003d idx=1 |
| `xb_m4_starves_input_two_every_eleventh_turn` | cycle 23 -- output 0: golden data=5a200005 idx=2 / mutant data=5a300005 idx=3 |
| `xb_m5_idx_stale_after_long_idle` | cycle 42 -- output 3: golden idx=3 / mutant idx=0, same data |
| `xb_m6_swap_pair_under_backpressure` | cycle 46 -- output 0: golden data=5a00000b / mutant data=5a00000a |
| `xb_m7_drop_every_sixty_fourth` | cycle 72 -- out_valid_o: golden 1111 / mutant 1110 |
| `xb_m8_duplicate_on_stall_release` | cycle 185 -- in_ready_o (masked): golden 0001 / mutant 0000 |
| `xb_m9_misroute_under_full_collision` | cycle 1 -- out_valid_o: golden 0001 / mutant 0010 |
| `xb_m10_ready_glitch_when_all_stalled` | cycle 492 -- in_ready_o (masked): golden 0000 / mutant 0001 |

## The witness harness had to be rewritten

Against the previous set, `nonequiv_tb.sv` ran three fixed forty-cycle phases.
That is enough to expose a total defect and **not** enough to expose any of
these: it never drove the contender count to exactly three, never held a stall
past eight cycles, never left an output idle, and never delivered sixty-four
beats on one output. A fifth phase now soaks the crossbar for 4000 cycles,
cycling through four request modes — random, four-way collision, three-way
collision, identity — against a backpressure pattern that periodically stalls
every output for twelve consecutive cycles.

The PRNG is a fixed xorshift, not `$urandom`, so the cycle numbers above are
reproducible.

`in_valid_i` is never withdrawn: an input that has made an offer holds it, with
the same payload, until both sides accept. Idles are entered from an accepted
beat. Clause H2 states that obligation on the source, and the harness is a
source.
