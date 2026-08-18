# v_nw03 — scoring notes (NOT shipped)

Everything the model receives is in `PASTE.md`, which is 100% paste-ready:
select all, copy, send. Nothing in it is addressed to us.

---
===================================================================

     Self-contained task file for v_nw03. Everything below the marker is
     paste-ready: port map, specification, output requirements. No RTL, no
     repo paths, no reference to this project.

     Note before sending: this ships a port map and prose only. The design
     it is derived from is MIT-licensed and nothing derived from it is
     included here, so the exposure is lighter than v_ca05's -- the same
     standing caveat applies, fine internally, licence review before any
     external release.

     Scoring, once the reply comes back, is a THREE-WAY split per failure:
       (a) driver bug         -- e.g. stimulus changed in the same timestep
                                 as the sampling edge, which makes a correct
                                 design look inert or deadlocked
       (b) unpromised reliance -- checks something §7 leaves open; compare
                                 against conformant/README.md
       (c) genuine spec gap   -- the specification really does not say
     Only (c) is a specification defect. Do not collapse these into a
     pass/fail number; the split is the entire result.

     Watch for one thing in particular. S6 ("ready is not a grant") is this
     task's load-bearing clause, the analogue of v_ca05's R4. A submission
     that treats a beat accepted at an input as a beat forwarded to the
     output will fail the golden, and that failure is (a) or (b), never (c).
     ===================================================================
