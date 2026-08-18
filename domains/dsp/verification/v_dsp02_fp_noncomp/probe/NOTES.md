# v_dsp02 — scoring notes (NOT shipped)

Everything the model receives is in `PASTE.md`, which is 100% paste-ready:
select all, copy, send. Nothing in it is addressed to us.

---
===================================================================

     Self-contained task file for v_dsp02. Everything below the marker is
     paste-ready: port map, specification, output requirements. No RTL, no
     repo paths, no reference to this project.

     Scoring, once the reply comes back, is the SAME THREE-WAY split as
     v_ca05 and v_nw03:
       (a) driver bug          -- e.g. withdrawing in_valid_i before the
                                  operation is accepted, or sampling the
                                  outputs without qualifying on out_valid_o
       (b) unpromised reliance -- checks something section 10 leaves open;
                                  compare against conformant/README.md
       (c) genuine spec gap    -- the specification really does not say
     Only (c) is a specification defect.

     THE CLAUSE TO WATCH is S4 with section 10. cvfpu, RISC-V and IEEE
     754-2008 return the non-NaN operand from min(NaN, x); IEEE 754-2019
     withdrew that and its replacement PROPAGATES the NaN. A model that
     knows the 2019 standard and not the RISC-V lineage will write the
     other answer. If it does so having read section 10, that is (b) and
     the citation is decorative. If section 10 stops it, the citation is
     load-bearing. That is the measurement this task exists for.

     Note before sending: port map and prose only, no RTL. Same standing
     caveat -- fine internally, licence review before external release.
     ===================================================================
