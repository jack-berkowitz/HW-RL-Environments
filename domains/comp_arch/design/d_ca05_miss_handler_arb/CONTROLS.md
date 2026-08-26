# d_ca05 — the negative controls

Four controls. The vendored anchor is never edited — it cannot be — so each
control instantiates the same `miss_handler` the reference does and **perturbs
exactly one output on the way out**. The defect is isolated by construction.

| control | the one change | verdict | clauses tripped |
|---|---|---|---|
| *(reference)* | — | **PASS** | — |
| `nc_a_fair_arbiter` | bypass grants rotated round-robin over the requesters (F2) | FAIL | **T2 only** |
| `nc_b_exclusive_match` | index match cleared when the address matches (F3a) | FAIL | **T3(a) only** |
| `nc_c_exclude_served` | the served requester masked out of both match outputs (F3b) | FAIL | T3(a), T3(b) |
| `nc_d_ack_amo_flush` | `flush_ack_o` pulses whenever the walk completes (F7, F8) | FAIL | **T5 on both AMO cases, not the genuine flush** |

Each control is the *plausible* mistake for its clause, not a constructed one:

* `nc_a` is the "improvement" — a fair arbiter. F2 forbids it, and the catalog
  promised it until `55c40c5`.
* `nc_b` is the natural reading of the anchor's own comment, *"same as previous,
  but checking only the index"*.
* `nc_c` is what that comment **says** the anchor does — *"exclude the unit
  currently being served"* — and what it does not do.
* `nc_d` is the obvious implementation: acknowledge when the walk finishes. Right
  for a requested flush, wrong for the two walks nobody requested.

`nc_d`'s localisation is the sharpest evidence the ack clauses are separable: it
fails the AMO-induced flush and the flush+amo corner while **passing the genuine
flush**, so T5's three cases are independently checked rather than jointly.

## `nc_a` passed on its first run, and it was the control that was broken

Its first version rotated among the bits set in `bypass_gnt_raw`. **The anchor
grants one port at a time**, so exactly one bit was ever set and "rotate to the
first set bit from `rr_q`" always landed on the same port. The control perturbed
nothing and the testbench correctly reported no failure.

**A control that perturbs nothing and a clause that is unchecked look identical
from the verdict alone.** That is the trap in reading a control matrix: a PASS in
this table is only evidence about the testbench once you have shown the control
actually changes the delivered surface. Rewritten to arbitrate over the
*requesters* rather than over the granted ports, it fails T2 with 5/5/5/5 where
the anchor gives 20/0/0/0.

## What is not covered

No control exercises **T4** (the flush walk's access count) or **T6** (atomic
ordering) or **T8** (mid-stream reset). Those clauses are checked against the
anchor's measured values and the reference passes them, but no control
demonstrates that a design violating them would be caught. Stated rather than
left to be assumed from the table's shape.
