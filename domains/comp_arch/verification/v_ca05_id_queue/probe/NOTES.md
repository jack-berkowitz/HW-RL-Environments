# v_ca05 — scoring notes (NOT shipped)

Everything the model receives is in `PASTE.md`, which is 100% paste-ready:
select all, copy, send. Nothing in it is addressed to us.

---
===================================================================

     Purpose: the clean version of the spec-completeness pilot. Every author
     here has read the RTL, so no local author can write a testbench blind.
     A model can. Paste everything BELOW the marker into a fresh chat.

     Note before sending: this ships a port map derived from SHL-0.51
     licensed code plus a prose specification. No RTL. Lighter exposure
     than the recognition probe, same standing caveat -- fine internally,
     needs a licence review before any external release.

     Scoring, once the reply comes back, is a THREE-WAY split per failure:
       (a) driver bug        -- e.g. stimulus changed in the same timestep
                                as the sampling edge, which makes a correct
                                DUT look completely inert
       (b) unpromised reliance -- checks something the spec leaves open
                                (compare against conformant/README.md)
       (c) genuine spec gap  -- the spec really does not say
     Only (c) is a specification defect. Do not collapse these into a
     pass/fail number; the split is the entire result.
     ===================================================================
