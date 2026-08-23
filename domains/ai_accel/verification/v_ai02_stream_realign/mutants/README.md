# v_ai02 mutant set — these MUST BE CAUGHT

The discriminating measure for a submitted testbench. Opposite sign to
`conformant/`: that one satisfies the spec and must survive; these violate it
and must be caught.

Every mutant is **generated**, by `gen_mutants.py`, as a mechanical edit of the
golden shim and — where the defect is internal — of a renamed copy of the
anchor. Each edit is an exact `old -> new` pair asserted to match **exactly
once**, so a silent no-op cannot produce a mutant identical to the golden that
every testbench "kills" by doing nothing.

## Every defect in this set is GUARDED

    defect := wrong_behaviour AND rare_predicate over contract-level state

A **total** defect fires on the first transaction of its class, so any testbench
that exercises the class catches it whether or not it is checking the clause —
it measures coverage, not checking. A **guarded** defect is caught only by a
testbench that constructs the named configuration and is still checking when it
arrives. The guards here name a rotation value, a beat's index within its line,
how many lines have run without a clear, how long the sink has held off, an
ordinal delivery, and whether the unit has ever realigned.

Two constraints bound them:

- **Fairness.** Every guard names a condition the spec states as a checkable
  bound at a named boundary. No mutant punishes an unstated expectation.
- **Reference reachability.** The reference kills all ten. It reached **three**
  when this set was first generated; seven phases were added to it rather than
  loosening the guards. A mutant the reference cannot reach is unverified, not
  difficult.

Guards read contract-level state only. The policy base in `policy/` has no
barrel shifter, no strobe FIFO and no `int_first`; a guard written over any of
those could not be restated there.

## The set

| id | clause | guard — fires only when… | defect |
|---|---|---|---|
| `sr_m1_rotation_four_when_three` | **R2/R4/R5** | the line's rotation is exactly 3 | realigned at rotation 4 instead |
| `sr_m2_first_beat_emitted_from_third_line` | **R1** | the third line of a run, and every line after | a line's first beat produces an output instead of being retained |
| `sr_m3_rotation_recaptured_deep_in_line` | **R4** | the fifth beat of a line onward | the rotation is recaptured from the current beat's strobe |
| `sr_m4_retain_skipped_after_stall` | **R5** | a beat accepted just after the sink held off four or more cycles | it is not retained, so the next output joins stale data |
| `sr_m5_last_dropped_on_long_line` | **R6** | the line is five beats or longer | a final beat with a clear strobe produces no output |
| `sr_m6_strb_from_input_on_last_beat` | **R3** | the output beat of a line's LAST beat | pop_strb_o carries push_strb_i instead of all ones |
| `sr_m7_drop_every_thirty_second` | **R2/R5** | the thirty-second output beat, and every thirty-second after | consumed internally, never shown to the sink |
| `sr_m8_passthrough_rotates_after_realign` | **P1** | realign_i has been high at least once since reset | pass-through is not transparent -- rotated one byte |
| `sr_m9_extra_beat_on_late_empty_strobe` | **R2** | the empty-strobe beat is the fourth or later in its line | it produces an output beat anyway |
| `sr_m10_admission_withheld_after_long_stall` | **X3** | the sink has just held off eight or more cycles | admission withheld twenty cycles although pop_ready_i is high |

## Non-equivalence witnesses — rule 16

`nonequiv_tb.sv` drives the golden and one mutant from a shared input sequence
and compares their observable outputs every cycle, payload masked by its own
valid and `push_ready_o` by `push_valid_i`. Run the set with `./witness.sh`.

| id | first observable difference |
|---|---|
| `sr_m1_rotation_four_when_three` | cycle 33 -- output: golden data=24232221 / mutant data=00000000 |
| `sr_m2_first_beat_emitted_from_third_line` | cycle 142 -- pop_valid_o: golden 0 / mutant 1 |
| `sr_m3_rotation_recaptured_deep_in_line` | cycle 177 -- output: golden data=f1f0efee / mutant data=f0efeeed |
| `sr_m4_retain_skipped_after_stall` | cycle 206 -- output: golden data=0c0b0a09 / mutant data=0cfbfaf9 |
| `sr_m5_last_dropped_on_long_line` | cycle 231 -- pop_valid_o: golden 1 / mutant 0 |
| `sr_m6_strb_from_input_on_last_beat` | cycle 84 -- output strb: golden 1111 / mutant 0011 |
| `sr_m7_drop_every_thirty_second` | cycle 156 -- pop_valid_o: golden 1 / mutant 0 |
| `sr_m8_passthrough_rotates_after_realign` | cycle 262 -- output: golden data=55545352 / mutant data=54535255 |
| `sr_m9_extra_beat_on_late_empty_strobe` | cycle 248 -- pop_valid_o: golden 0 / mutant 1 |
| `sr_m10_admission_withheld_after_long_stall` | cycle 204 -- push_ready_o while offering: golden 1 / mutant 0 |

## Three things this rebuild found

**An equivalent mutant.** The first draft included a defect that ignored
`clear_i` from the second clear onward. At this configuration that is
*unobservable*: the only clear-sensitive state is the rotation and the retained
beat, and R1 makes the next line's first beat overwrite both. It was replaced by
`sr_m9`, a live R2 violation. A mutant nothing can detect is not a hard mutant.

**An under-specified clause.** Driving an empty strobe deep inside a line made
the reference fail the *golden*. The anchor retains a silently consumed beat;
the reference assumed it does not. R5 already withheld its byte-preservation
claim from such lines, but nothing said what the retained beat becomes — so the
spec now carries **L4**, and the reference checks the count of output beats
there while leaving their content free.

**A guard that the policy base could not reach.** `sr_m4` fires on a beat
accepted just after a long stall, and step 5c had it PASS on the divergent base.
That base makes every beat wait for the sink (its opposite choice on L1), so
stalling *before* the line produced anything left `pop_valid_o` low — nothing
was being offered, so nothing was being held off, and the stall did not exist
from the unit's point of view. The reference now waits for output beats before
stalling, which makes the stall real on either reading of L1.
