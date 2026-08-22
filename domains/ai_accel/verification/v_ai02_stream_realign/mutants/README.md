# v_ai02 mutant set — these MUST BE CAUGHT

The discriminating measure for a submitted testbench. Opposite sign to
`conformant/`: that one satisfies the spec and must survive; these violate it
and must be caught.

Every mutant is **generated**, by `gen_mutants.py`, as a mechanical edit of the
golden shim and — where the defect is internal — of a renamed copy of the
anchor. Each edit is an exact `old -> new` pair asserted to match **exactly
once**, so a silent no-op cannot produce a mutant identical to the golden that
every testbench "kills" by doing nothing.

## The set

| id | clause | defect | why one beat through the unit misses it |
|---|---|---|---|
| `sr_m1_rotation_off_by_one` | **R2/R5** | the rotation is one byte more than the strobe calls for | needs the rotation exercised at a value where one byte matters, and the output compared byte-exactly |
| `sr_m2_first_beat_emitted` | **R1** | a line's first beat produces an output instead of being retained | needs the first beat of a line distinguished from the rest |
| `sr_m3_first_beat_not_retained` | **R2/R5** | the first beat is not retained, so the next beat joins stale data | the *count* of output beats is right; only their contents are wrong |
| `sr_m4_rotation_reversed` | **R2** | the two halves are joined the wrong way round | at rotation 0 and rotation 4 this is invisible — only the intermediate rotations expose it |
| `sr_m5_strobe_passed_through` | **R3** | the output strobe carries the input strobe | invisible until the source drives something other than a full strobe |
| `sr_m6_rotation_recaptured` | **R4** | the rotation is recaptured every cycle, not just at a line's first beat | needs `strb_i` to *change* mid-line, which a testbench holding it constant never does |
| `sr_m7_always_realigns` | **P1** | the unit realigns even when `realign_i` is low | needs pass-through exercised at all |
| `sr_m8_last_ignored` | **R6** | a final beat with an empty strobe produces no output | needs a line deliberately ended on an empty strobe |

## Non-equivalence witnesses — rule 16

`nonequiv_tb.sv` drives the golden and one mutant from a shared input sequence
and compares their observable outputs every cycle, with the payload masked by
`pop_valid_o` and `push_ready_o` by `push_valid_i` — clause L2 leaves the
payload free while valid is low, and H3 says a ready bit means nothing while
nothing is offered.

| id | first observable difference |
|---|---|
| `sr_m1_rotation_off_by_one` | cycle 19 — output `00000000` against `13121110` |
| `sr_m2_first_beat_emitted` | cycle 17 — `pop_valid_o` 0 against 1 |
| `sr_m3_first_beat_not_retained` | cycle 19 — output `0f0e0d0c` against `13121110` |
| `sr_m4_rotation_reversed` | cycle 33 — output `22212027` against `24232221` |
| `sr_m5_strobe_passed_through` | cycle 80 — output strobe `0011` against `1111` |
| `sr_m6_rotation_recaptured` | cycle 98 — output `5b5a5958` against `59585756` |
| `sr_m7_always_realigns` | cycle 4 — `pop_valid_o` 1 against 0 |
| `sr_m8_last_ignored` | cycle 98 — `pop_valid_o` 1 against 0 |

**`sr_m5` reported NO DIFFERENCE OBSERVED on the first run.** The harness drove
a full `push_strb_i` on every beat, and a design that forwards the input strobe
is indistinguishable from one that forces all ones until the source drives
something else. A phase with a partial input strobe was added. *"No difference
observed" is a claim about the harness until the harness has been shown able to
see the difference.*

## Reference testbench ceiling

**8 of 8**, checked against a second, independent base: all eight defects
re-derived on the policy-divergent implementation and re-run, 18 of 18 verdicts
matching, both clean implementations passing. See
`check_policy_independence.sh` and NOTES.md.
