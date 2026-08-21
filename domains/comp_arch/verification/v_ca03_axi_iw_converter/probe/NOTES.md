# v_ca03 — scoring notes (NOT shipped)

Everything the model receives is in `PASTE.md`, which is 100% paste-ready:
select all, copy, send. Nothing in it is addressed to us.

---

Scoring is the same three-way split as the other verification tasks:

  (a) driver bug          -- stimulus changed in the same timestep as the
                             sampling edge; a static-lifetime declaration; a
                             result matched by value rather than bookkeeping
  (b) unpromised reliance -- checks something section 8 leaves open. Compare
                             against conformant/README.md
  (c) genuine spec gap    -- the specification really does not say

Only (c) is a specification defect.

WHAT THIS TASK IS FOR. Nine of eleven clauses require a MODEL rather than a
comparison: the set of outstanding identifiers, a count per identifier, a FIFO
per identifier, the live slave-to-master mapping, and the exact retirement edge.
The three earlier verification tasks could be discharged with a scoreboard and
one expected value per transaction. This one cannot, and that is the headroom.

THE CLAUSES TO WATCH are A3 and A4. A3 is an exact boundary in both directions:
at MAX_UNIQ_IDS-1 distinct identifiers a new one MUST be accepted, at
MAX_UNIQ_IDS it must NOT -- and a request carrying an identifier already
outstanding is not blocked by fullness at all. A4 gives retirement a two-cycle
window. A submission that tests only "the table fills and then blocks" misses
three of the five faults.

CEILING: 5 of 5, and weaker than it looks. The mutants were written BEFORE the
reference testbench, so the model was developed against exactly these five
boundaries. It says the model is consistent with the cases it was built from,
not that it is complete. A submission is the first untainted test.
