# d_nw03 `axis_switch_oq` — build notes (TIER-B)

**Status: COMPLETE except PPA.** Reference 8/8, both negative controls fail as
required, second source probe complete. PPA is Agent 1's.

| artifact | state |
|---|---|
| `spec/axis_switch_oq_iface.sv` | complete; 6 latitude clauses named, both frontends clean |
| `ref/axis_switch_oq_ref.sv` | thin shim over `axis_switch`, **8/8** |
| `tb/axis_switch_oq_tb.sv` | checker; C1 is a rate, C2 HOL, C3 liveness |
| `controls/nc_a_reset_polarity.sv` | **0/8**, specific reason |
| `controls/nc_b_outputs_serialised.sv` | **6/8**, fails only where C1 is enforced, on C1 |
| `tb/axis_switch_oq_alt_ref.sv` | second source probe, 8/8, 0 adjudication rounds used |
| PPA | **Agent 1** |

## The scored configuration was chosen by discrimination, and it is measured

`S_COUNT=4, M_COUNT=4, DATA_W=32`. Not a judgement call — the numbers:

| | C1 rate at 4x4 |
|---|---|
| reference | **2.40** beats/cycle |
| capability-reduced control | **0.81** beats/cycle |
| floor | 2.0 |

At 2x2 the ceiling *is* the floor, so nothing can be told apart there and a
correct design cannot even clear it. C1 is therefore enforced only at 4x4 and
reported elsewhere with an explicit note that it is not capability evidence.

## Three harness defects, and the second one is the interesting one

**1. Found by the reference.** The routing check keyed on frames *fully
accepted*. That forbids cut-through, which L2 permits and the anchor does — its
first beat reaches an output before the frame has been fully accepted. Re-keyed
onto frames *started*.

**2. Found by instrumenting a number that looked wrong.** Every per-cycle tally
was `x <= x + 1` inside a port loop. A non-blocking assignment evaluated N times
against the same old value: **the last iteration wins and the counter caps at one
per cycle**, however many ports transferred. A switch delivering four beats a
cycle measured **0.93** — which is precisely the number a fully serialised design
produces.

That is the whole failure mode this project keeps recording, in a new place: the
rate was plausible, ordered correctly against expectation, and wrong. **The C1
check would have passed its own capability-reduced control**, and the control was
built afterwards, so nothing would have contradicted it. It was caught only
because 0.93 was too close to 1.00 to be a coincidence and the debug print showed
`mv=1111 mr=1111` — four beats transferring in the cycle the counter recorded one.

**3. Found by sweeping all 8 configurations.** C1's floor failed the *reference*
at 2x2. A floor that fails correct hardware is the recorded trap; now gated.

## What the second source bought, and what it did not

It **passed 8/8 on the first run**, so zero of the two adjudication rounds were
used. Stated plainly: that is the weaker outcome. A probe that fails and
adjudicates to "the harness is wrong" yields a fix; one that passes yields only
the absence of evidence.

**It was verified to have genuinely taken the other path** rather than matching
the anchor incidentally — which is the failure mode the procedure warns about.
At the scored configuration the two measure 2.40 and 2.57 beats/cycle over the
same window, across different cycle counts (7940 vs 8183) and different frame
mixes, because oldest-first arbitration starts a different set of frames than
round-robin does. Opposite choice on three clauses: store-and-forward (L2),
oldest-first (L1), ready gated on valid (L5).

**It did yield one spec defect, before a line of it was written.** L2 permits a
store-and-forward design, and such a design cannot be built without a bound on
frame length — which the spec did not state. That is latitude the interface
could not express, found by trying to USE the clause rather than by reading it.
**R6** now bounds a frame at 8 beats, and the harness drives the bound with a
coverage floor rather than merely stating it.

## For Agent 1 — PPA

- Scored configuration `S_COUNT=4 M_COUNT=4 DATA_W=32`.
- The reference's closure is flat in `refs/verilog-axis/rtl`; no include paths
  needed. It is Verilog-2001 with `default_nettype none`.
- Tier-B pins a fixed clock period rather than sweeping. Period, resolved-config
  hash and task-text hash are yours to record.
