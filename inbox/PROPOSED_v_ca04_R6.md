PROPOSED CLAUSE for v_ca04_stream_xbar — NOT LANDED. Written for the task owner
to take, reword or reject; it moves the task_text_hash and should ride with the
annotation pass rather than arrive on its own.

Placement: section 1 (Routing), after R5, as the last of the delivery clauses.
Spec file: spec/route_xbar_spec.md, and the same paragraph into probe/PASTE.md.

----------------------------------------------------------------------
- **R6 — every delivered beat was accepted.** A beat appearing on an output
  shall be one that was accepted on some input. The unit delivers beats; it does
  not originate them.

  *This is not implied by R1 or R4. R1 governs WHICH output an accepted beat
  reaches, and R4 governs HOW MANY TIMES it is delivered; both presuppose the
  beat was accepted. A beat that entered the unit at no input satisfies both
  vacuously — there is no binding to be wrong about and no first delivery to
  count a second against.*

  *Authority: task intent. The interface has no source of payload other than the
  input side, so a beat with no acceptance is not an under-specified case but an
  impossible one, and a design that produces it is wrong for a reason the other
  clauses cannot name.*
----------------------------------------------------------------------

WHY IT IS NEEDED, and the evidence, since "add a clause" is the expensive answer:

  The testbench site that fires here reported `fail("R1/R4", ...)` — a compound
  that is not a clause id, so the verdict named a token nothing matches. Split,
  the branch resolves into R1 (found outstanding for another output) and a state
  where the payload is outstanding for NO output and was never accepted.

  That state is NOT hypothetical. It is produced by a mutant in the shipped set:

    xb_m8_duplicate_on_stall_release
      FAIL UNCLAIMED: cycle 141: output 0 delivered payload 0000002e naming
                      input 0, which was never accepted on any input for any output
      FAIL R4:        cycle 142: output 0 delivered payload 0000002e a second time

  The mutant emits the beat BEFORE anything accepted it, then again. The second
  emission is a genuine R4. The first has no clause.

  The duplicate case cannot reach this branch at all — `seen.exists(d)` catches
  it eight lines earlier under R4's own id — so the site was never "R1 or R4".
  It was R1 plus this.

WHY NOT "DELIBERATELY UNCLAIMED":

  That is the right answer for a state no stimulus reaches, and this one has a
  witness in the set a submission is scored against. Leaving it unclaimed means a
  submission that never checks for fabricated beats scores as though nothing
  happened, while the mutant that produces them is counted as caught — by R4,
  for the second emission, one cycle later.

INTERACTION WITH THE MUTANT SET, which the owner should check before landing:

  Adding R6 does not change any kill count — m8 is already caught by R4 — but it
  changes what m8 is EVIDENCE OF. If the set is meant to have one clause per
  mutant, m8 now touches two, and that is a set-design question I am not placed
  to answer.

  The testbench currently emits this state under the marker `fail("UNCLAIMED", ...)`
  with a comment saying the state awaits a decision. If R6 lands, that marker
  becomes `fail("R6", ...)` and the comment comes out.
