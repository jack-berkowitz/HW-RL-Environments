<!-- author: agent2 -->
# The single perturbed rerun — plan, for approval before anything runs

**Not started.** This document is the per-task perturbation table and the failure
definition, both required before the first build.

## The rule the magnitudes come from

A perturbation shorter than the deepest thing the design can be holding **cannot
drain it** — the design absorbs the stall in buffering and never has to expose
held state. So the magnitude is not a round number; it is derived per task:

> **stall depth = (deepest buffer the design can hold on that channel) + 1**

One cycle past the buffer is the first cycle on which the design must *hold*
rather than *absorb*. Where a task's deepest buffer is a whole transaction rather
than a channel FIFO, the relevant depth is still the **per-channel** one: D6 fired
at three idle cycles between narrow beats, not at a drained 64-beat burst,
because the mechanism was an accumulator cleared on a pipeline bubble. **The
bubble is what the stall has to produce, and a bubble needs only to outlast the
buffer.**

Floor of 4 where a design has no buffer on the axis, so the stall is longer than
any single-cycle handshake artefact.

## The table

| task | axis perturbed | deepest hold, from the design | stall | why sufficient |
|---|---|---|---|---|
| `v_ai02` | inter-beat gap, input line | `STRB_FIFO_DEPTH=4`, plus one held beat | **6** | 4-deep strobe FIFO + the held beat + 1. A line runs to 10 beats, so a 6-cycle gap lands inside a line rather than between lines |
| `v_ca03` | inter-beat gap, `m_r`/`m_b` intake | internal FIFO depth **8**; 4 ids × 2 txns = 8 outstanding | **9** | one past the 8-deep FIFO; the table cannot absorb a ninth cycle without holding |
| `v_ca04` | inter-beat gap, per output | `OutSpillReg=0` — **no output buffer**; one beat in flight | **4** | floor; with no spill register any stall > 1 forces the hold, and 4 outlasts arbitration round-robin over `N_OUT=4` |
| `v_ca05` | gap between pop/search requests | `SLOTS=8` entries, `NTAG=8` | **9** | one past capacity: the store must be full and still holding when the next request arrives |
| `v_ca06` | inter-beat gap, downstream `R` | internal FIFO depth **8**; ratio 4; `MAX_READS=4` | **9** | one past the 8-deep FIFO. **Known to be sufficient: D6 fires at 3** |
| `v_ca07` | gap between `div_valid_i` offers | divisor to `2^4-1 = 15`; one output period = up to 15 input cycles | **16** | one past the longest output period, so a change is offered while a full period is in flight |
| `v_dsp02` | gap between operand offers | `NumPipeRegs=1` — depth 1 | **4** | floor; depth 1 needs only 2, and 4 outlasts the `PipeConfig=BEFORE` register plus handshake |
| `v_nw01` | gap between frames | `REQUEST_RETRY_INTERVAL=64`, cache 4 entries | **65** | one past the retry interval — a stall shorter than 64 never lets a retry fire, so the retry path is unreachable |
| `v_nw02` | inter-beat gap, `W` intake | `MAX_WRITE_TXNS=4`; internal FIFO depth **8** | **9** | one past the FIFO; the debt bound of W1 is only observable with the queue held full |
| `v_nw03` | inter-beat gap, mid-frame | `S_COUNT=4` inputs, no output spill | **5** | one past the number of contending inputs, so a round-robin cannot hide the stall by serving another input |
| `v_nw04` | gap between `adj`/`drift` offers | `DRIFT_RATE=5` — a drift lands every 5 cycles | **6** | one past the drift period, so a stall always contains a whole drift event |

**Two magnitudes are load-bearing rather than conservative.** `v_nw01` at 65 and
`v_ca07` at 16 are large because those designs hold *timers*, not buffers, and a
stall shorter than the timer cannot reach the state the clause is about. Both
will need the drain widening described below.

## Showing the perturbation is live — `FIRED`, on the instrument itself

A rerun that passes because the perturbation never took effect is
indistinguishable from one that passes because the clauses hold. **That is the
class this week is about and the instrument is not exempt from it.**

Each perturbed run emits, at end of run:

    FIRED <task>.perturb_applied <n>      cycles the stall was asserted
    FIRED <task>.perturb_at_depth <n>     times the stall ran to its FULL depth

and `check_fired.py` refuses on zero for either. **The second is the one that
matters**: a stall interrupted at cycle 2 of 9 by the end of a phase has been
*applied* without ever being *deep*, and only the second counter separates them.
`perturb_at_depth == 0` with `perturb_applied > 0` is the exact shape of a
control that ran and never triggered.

## What a failure looks like, defined before any result

### Escalates — a candidate reference failure

The reference **FAILS on a contract clause id it passes at zero perturbation**,
and the failure **survives the drain-widened repeat** described below.

### Does not escalate — phase-structure artefact

Any of:

- failures on `FLOOR` or `COVERAGE` ids
- wrong-id, wrong-beat-count or out-of-order failures, which are the signature of
  one phase's traffic arriving inside the next
- **anything that disappears when the drains are widened**

These get the drain fixed and the rerun repeated. They are not results.

### Does not escalate — refuses instead

Hang, crash, or no `RESULT` line. **Absent is not failure (rule 20).** The task is
reported NOT MEASURABLE under perturbation and comes back to you.

### The separation, mechanically

**Every task is run twice**: once at its existing inter-phase drain, once with
every drain multiplied by `(1 + stall_depth)`.

    fails at both drains      -> candidate reference failure, ESCALATE
    fails only at the narrow  -> phase-structure artefact, fix the drain and repeat
    fails only at the wide    -> report; this should not happen and I do not have
                                 a story for it, so it goes to you unexplained

This costs one extra build per task and it is derived from the one case where I
got it wrong: v_ca06's first slow-slave run reported **43 failures across seven
clause ids** and read as the anchor collapsing. Widening the drain from 40 cycles
to 600 left **9 × D6 and nothing else**. Six of seven clause ids were the drain.

## Scope

**Reference, `dut2`, and the conformant set. Not mutants.** D6 was a clause false
about the reference and every mutant died either way, so the kill table is not the
instrument here.

The kill table is re-run **only on a task where a clause has to change**, because
narrowing can cost kills. D6 cost zero — **measured, not assumed**, and the same
measurement is owed by any narrowing this produces.

## Stopping rule

**A failing golden is the D6 shape. I report before sweeping for a threshold, and
before any clause moves.** The threshold sweep — bisection on stall depth for that
one task, roughly seven builds — runs only after that.
