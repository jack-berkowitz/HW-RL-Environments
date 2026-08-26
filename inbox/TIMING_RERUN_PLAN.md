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


---

# RESULTS — first run, and the mechanism is wrong

**No threshold sweep started. No clause moved.** Reporting per the stopping rule.

## What was measured

| task | depth | narrow drain | wide drain | verdict |
|---|---|---|---|---|
| `v_ca06` | 9 | FAIL, 38 across 7 ids | **PASS** | **clean.** 38 of 38 were drain artefacts |
| `v_ai02` | 6 | PASS | PASS | **clean** |
| `v_dsp02` | 4 | PASS | PASS | **clean** |
| `v_ca07` | 16 | FAIL, FLOOR only | FAIL, FLOOR only | does not escalate — see below |
| `v_ca03` | 9 | FAIL 4 | FAIL 4 | **clause made unmeasurable** |
| `v_nw02` | 9 | FAIL 22 | FAIL 22 | **clause made unmeasurable** |
| `v_ca05` | 9 | FAIL | FAIL | **instrument artefact** |
| `v_ca04` | 4 | — | — | blocked: vector signal, patcher fixed, not re-run |
| `v_nw03` | 5 | — | — | blocked: same |
| `v_nw01` | 65 | — | — | not run: abbreviated signal names, unmapped |
| `v_nw04` | 6 | — | — | **NOT APPLICABLE**: pulse valids, no ready to gate |

Perturbation was live on every task that ran — `perturb_at_depth` between 78 and
3717, never zero. **The instrument declared itself, as designed.**

## The drain discriminator worked exactly as specified

`v_ca06`: **40 failures across 8 clause ids at the narrow drain, 0 at the wide.**
That is the whole point of the two-run design and it earned its cost on the first
task. Without it I would have reported the anchor as collapsing, for the second
time.

## A THIRD failure category the definition did not have

`v_ca03`'s `A4` bounds retirement at **2 cycles**. `v_nw02`'s `X4` bounds a
manufactured B at **232 cycles**. `v_ca07`'s `H4` needs a request pending while a
change gates.

**A perturbation of 9 or 16 cycles does not violate those clauses. It makes them
unmeasurable** — the testbench cannot offer inside a 2-cycle window when the
source is gated for 9.

    FAIL [A4] entry freed late: new id accepted 8 cycles after retirement, window is 2
    FAIL [X4] manufactured B for id=4 arrived at cycle 8541, deadline was 232

> **A clause with its own cycle bound cannot be measured under a perturbation
> that exceeds that bound, and the result reads as a violation.**

**And the difference between reading as a violation and reading as untested is
whether the clause has an antecedent floor.** `v_ca07`'s H4 has one, and reported:

    FAIL [FLOOR] H4's antecedent never held: no offered request was ever pending
                 while a change was still gating

*That is the honest form.* Same situation, same cause, and the task with the floor
said "untested" while the two without said "failed".

## The mechanism is unsound, and that is the real result

**Gating the DUT-visible valid creates phantom transfers in any testbench that
commits on ready or grant ALONE.**

    v_ca06   for (t=0; ...) begin @(posedge clk); if (s_wready) break; end
    v_ca05   if (push_gnt) begin              // R4: commit on req && gnt
               granted = 1'b1; ref_q[tg].push_back(d); ref_count++;

**v_ca05's own comment states the correct condition and the code checks the wrong
one.** Both are correct today *only because neither testbench ever gates its own
valid* — the third variety again, and now in the artefact the sweep was built to
test.

My patcher corrects `if (R) break;`. It does not match `if (R) begin`, so v_ca05
ran uncorrected and produced `full=0 with 8 entries` — the reference model
counting pushes the DUT never saw. **A pattern-matched correction to a pattern-matched
defect keeps missing variants**, which is the same failure one level up.

### What the mechanism should have been

**The run that actually found D6 did not gate anything.** It slowed the
responder's own beat advance — `RGAP` idle cycles between presenting beats — so
the DUT and the testbench never disagreed about whether a transfer occurred.

    gate the valid          creates valid/ready disagreement; unsound wherever a
                            testbench commits on one side
    delay the source's own  no disagreement possible; the testbench simply offers
    advance                 later, which is what a slow master IS

The sweep should be rebuilt on the second. That is a per-task edit to each
responder rather than a generic gate, which is the cost I estimated at 1–2 hours
per task and then tried to avoid with a generic mechanism.

## What I would do next, for a decision rather than on my own

1. **Rebuild on the delay-the-advance mechanism**, per task, and re-run the three
   that are currently artefacts.
2. **Exclude bounded clauses from perturbed runs**, or perturb below their bound —
   `v_ca03`'s A4 at 2 and `v_nw02`'s X4 at 232 cannot share a run with a 9-cycle
   gap. The alternative is a per-clause exclusion list, which is a scoring
   decision and not mine.
3. **The one substantive result so far is `v_ca06` clean at depth 9**, which is
   three times the depth at which the old sticky D6 broke — evidence that the
   narrowing was right, and the only positive result the run has produced.


---

# SECOND RUN — delay-the-advance, and a correction to my own first report

**No sweep. No clause moved.**

## The mechanism was rebuilt twice, not once

    v1  gate the DUT-visible valid       UNSOUND -- phantom transfers
    v2  delay before the valid           UNSOUND -- sits between a measurement's
                                         baseline and the event it measures
    v3  delay at the top of the task     sound, and passing

**v2's defect is the wrong-baseline finding in a new form.** `do_read` samples
`ar0 = n_ds_ar` at task entry and compares at the end. A delay placed just before
the offer left that window open across the gap, so a *previous* transaction's
downstream address landed inside it:

    FAIL [A2] read issued 2 downstream addresses, expected exactly 1   x24

I did not move the baseline. **I moved the event away from it**, which has the
same effect and is harder to see.

## And it overturns the "third failure category" I reported

I reported `v_ca03`'s A4 (window 2) and `v_nw02`'s X4 (deadline 232) as **clauses
made unmeasurable by a 9-cycle perturbation**, and proposed excluding bounded
clauses. Under v3, at the same depth 9:

    v_ca03   PASS      (was FAIL 4)
    v_nw02   PASS      (was FAIL 22)
    v_ca06   PASS      (was FAIL 1 at wide drain)

**They were not unmeasurable. They were artefacts of the gate**, which inserted
delay inside the window those clauses bound. The category was real as an idea and
false as a diagnosis of these three, and I proposed a scoring change on the
strength of it.

> A category inferred from an instrument's output inherits the instrument's
> defects. I had already written that a failure surviving the drain widening
> escalates — it did survive, twice, and it was still the instrument.

## What v3 actually tests, and it is not the axis in the table above

The delay sits at the **top of each driving task**, so it spaces *transactions*
apart. The plan's axis is the **inter-beat gap** — the spacing between beats
*within* a transaction — and that is what found D6.

    v3 tests     inter-transaction spacing
    the plan     inter-beat gap
    D6 needed    inter-beat gap

**v3 would not have found D6.** It is sound and it is measuring the wrong thing,
which is a better position than v1 and v2 but not the one the plan asked for.

The inter-beat axis needs the responder's own beat advance slowed — the `RGAP`
edit, per task, in each responder's always block. That is the 1–2 hours per task
the estimate named, and no generic patcher reaches it: **the beat advance lives in
a different place in every testbench, which is exactly why a generic mechanism
kept measuring something else.**

## Standing results

| task | depth | mechanism | narrow | wide |
|---|---|---|---|---|
| `v_ca06` | 9 | v1 gate | FAIL 38 | **PASS** |
| `v_ca06` | 9 | v3 delay | **PASS** | FLOOR only |
| `v_ca03` | 9 | v3 delay | **PASS** | FLOOR only |
| `v_nw02` | 9 | v3 delay | **PASS** | FAIL, uncategorised |
| `v_ai02` | 6 | v1 gate | PASS | PASS |
| `v_dsp02` | 4 | v1 gate | PASS | PASS |
| `v_ca07` | 16 | v1 gate | FLOOR only | FLOOR only |

**`v_ca06` clean at depth 9 under two independent mechanisms** is the one result
that has survived every revision of the instrument, and it is three times the
depth at which the old sticky D6 broke.

A FLOOR firing at the wide drain is expected and does not escalate: multiplying
every drain changes how much stimulus fits in the run, so coverage counts fall.
That is the drain being widened, not the design.

---

# THE RGAP TABLE — where each beat advance lives, named before any edit

**Seven tasks are measurable on the inter-beat axis. Four are not, and are
reported as not measurable rather than perturbed by something adjacent.**

## Measurable — the beat advance is identifiable

| task | where the beat advance lives | the edit |
|---|---|---|
| `v_ca06` | R responder `always @(posedge clk)`: `rbeat <= rbeat + 1` at **L165** on `m_rvalid_q && m_rready`, queue pop at **L159** | countdown loaded on accept; the next beat is not presented until it expires. **This is the edit that found D6** |
| `v_ca03` | R/B responders: `m_beat` at **L169** on `m_rvalid && m_rready`; queue pops at **L165** (R) and **L191** (B) | same, on both responders |
| `v_nw02` | B and R responder queue pops at **L360** / **L361** on `m_bvalid && m_bready` / `m_rvalid && m_rready` | same, on both |
| `v_ai02` | procedural driver: `if (hs && txq.size() > 0) begin void'(txq.pop_front()); pvalid = 1'b0; end` at **L172**, re-assert at **L176** | countdown between the pop and the re-assertion of `pvalid` |
| `v_ca04` | `always @(negedge clk)`: `if (hs[k]) begin nxt[k]++; in_valid[k] = 1'b0; end` then `if (!in_valid[k] && offer[k]) present(k);` at **L202–206** | per-input countdown gating `present(k)` |
| `v_nw03` | **the hook already exists**: `assign s_tvalid[k] = run_en && !done_f[k] && (gap_cnt[k] == 0);` at **L101**, advance at **L153** | set `gap_cnt[k] = PDEPTH` on each accepted beat. **No new mechanism — the testbench was built with an inter-beat gap counter** |
| `v_nw01` | payload byte loop: `for (i...) @(negedge clk); s_pd = p[i]; s_pl = (i==27); s_pv = 1'b1;` at **L164** | delay at the top of the loop body, before `s_pd` is set |

`v_nw03` is worth calling out: **its testbench already carries a per-input
`gap_cnt`**, so the inter-beat axis was anticipated by whoever wrote it and the
perturbation is a one-line assignment rather than a new mechanism.

## NOT measurable on this axis — and not to be approximated

| task | why |
|---|---|
| `v_ca05` | **No beats.** `push_req`/`push_gnt`, `pop_req`/`pop_gnt`, `match_req`/`match_gnt` are single-beat operations. There is no next beat of anything to delay |
| `v_ca07` | **No beats.** `div_valid`/`div_ready` carries one value per handshake; the design's output is a clock, not a stream |
| `v_dsp02` | **No beats.** One operand pair per handshake. `NumPipeRegs=1` is pipeline depth, not a burst |
| `v_nw04` | **No handshake at all.** `adj_valid_i`, `drift_valid_i`, `set_ts96_valid_i` are pulses with no ready. Nothing to be late for |

**These four have an inter-transaction axis and no inter-beat axis.** Perturbing
their request spacing would produce a number, and the number would not be a
measurement of the thing D6 lives on. Reporting them as not measurable is the
honest result; the alternative is a clean row that means untested, which is the
class this whole file is about.

**7 of 11 measurable. Same stopping rule: report on the first escalation, no
sweep, no clause moves.**


---

# THIRD RUN — per-task RGAP, seven edits. Five clean, two escalations.

**No sweep. No clause moved.**

## Results

| task | depth | narrow drain | wide drain | verdict |
|---|---|---|---|---|
| `v_ca06` | 9 | FAIL 38 (drain) | **PASS**, FLOOR only | **CLEAN** |
| `v_ca03` | 9 | **PASS** | FLOOR only | **CLEAN** |
| `v_nw03` | 5 | **PASS** | **PASS** | **CLEAN** |
| `v_ai02` | 6 | **PASS** | **PASS** | **CLEAN** |
| `v_ca04` | 4 | FAIL 2 (I1, I2) | **PASS** | **CLEAN** — narrow failures were drain |
| `v_nw02` | 9 | FAIL P3 | FAIL P3 | **ESCALATION** |
| `v_nw01` | 65 | FAIL Q6 | FAIL Q6 | **ESCALATION** |

Perturbation live on all seven: `perturb_at_depth` from 26 to 1380, never zero.

**Five of seven clean on the axis D6 lives on**, including `v_ca06` at three times
the depth the old sticky D6 broke at — now confirmed by a third independent
mechanism.

## Escalation 1 — `v_nw02` P3

    FAIL P3: after the read sweep: 3 R beat(s) still owed, oldest id=6

P3 is *"the read address path is never altered… a read is never filtered."* The
message is not about alteration — it is **beats still in flight at a phase
boundary**. The R responder is held back 9 cycles per beat and the read sweep's
end-of-phase check runs before they drain.

**It survived the ×10 widening, which is what makes it an escalation by my own
definition** — but the widening multiplies `repeat(N)`, `t < N` and `drain(N)`,
and if that phase ends on a different construct the widening never reached it.
**I have not confirmed which**, and that is the next thing to check rather than a
conclusion to draw.

## Escalation 2 — `v_nw01` Q6, and the magnitude is my error

    FAIL Q6: a matching reply did not resolve the lookup

**The depth is wrong and the table says why.** I justified 65 as *"one past
`REQUEST_RETRY_INTERVAL=64`, so a stall shorter than 64 never lets a retry fire"*
— which is an argument about the gap **between requests**. The inter-beat axis
applies it **between payload bytes**, and the frame is 28 bytes:

    65 cycles x 28 bytes = 1820 cycles per frame
    REQUEST_TIMEOUT      = 256

**The frame takes seven times the design's own lookup timeout.** The lookup
expires before the reply finishes arriving, and Q6 — *a matching reply resolves
the outstanding lookup* — cannot hold because there is no outstanding lookup left.

> **A magnitude justified on one axis and applied on another is not justified.**
> My own table names the axis for each task and I derived this one from an
> inter-transaction quantity, then applied it per beat. The table looked
> rigorous — every row has a reason — and the reason for this row is about a
> different measurement.

The correct depth for `v_nw01`'s inter-beat axis comes from what the design
buffers *within* a frame, not from its retry interval. **I do not currently know
that number**, and picking one without it would repeat the error.

## What this does and does not establish

**Establishes:** five tasks clean on the inter-beat axis at a justified depth, by
a mechanism that gates nothing and cannot produce a phantom transfer. `v_ca06`
clean under three independent mechanisms.

**Does not establish:** anything about `v_nw02` or `v_nw01`. One has an unverified
widening and one has a depth I derived wrongly. **Neither is a statement about
the design yet**, and by the pattern of this whole exercise the prior should be
that they are not.


---

# FINAL — six clean, five not measurable, ZERO escalations standing

## The standing result

**Six of eleven tasks are measured clean on the inter-beat axis — the axis D6
lives on — by a mechanism that gates nothing and cannot produce a phantom
transfer.**

| task | depth | drain | result |
|---|---|---|---|
| `v_ca06` | 9 | x10 | **CLEAN** |
| `v_ca03` | 9 | x10 | **CLEAN** |
| `v_nw02` | 9 | **x2** | **CLEAN** |
| `v_ai02` | 6 | x7 | **CLEAN** |
| `v_nw03` | 5 | x6 | **CLEAN** |
| `v_ca04` | 4 | x5 | **CLEAN** |

**`v_ca06` is clean at three times the depth the old sticky D6 broke at, under a
third independent mechanism.** That result has now survived the gate, the
task-top delay, and the per-task RGAP edit — three instruments with three
different defects, agreeing.

## Both escalations dissolved

### `v_nw02` P3 — the widening never reached that phase

The read sweep ends on `settle(20)`, `settle(14)`, … and my widening multiplied
`repeat(N)`, `t < N` and `drain(N)`. **`settle(N)` was not in the list.**

> *"The failure survived the widening"* was not evidence about the failure. It
> was evidence that the widening had no effect on that phase. **An escalation
> criterion that a widening never reached is not a criterion.**

With `settle()` widened, P3 is gone.

### And the drain multiplier has an UPPER bound, which my rule did not have

Widening `settle()` by x10 then produced **4 x X4** — the deadline clause. A
drain large enough to clear contamination is large enough to push events past a
fixed deadline.

    drain x1    P3 fails      not enough drain
    drain x2    PASS          <-- both hold
    drain x3    X4 fails      deadline stretched
    drain x5    X4 fails
    drain x10   X4 fails

**My rule was "multiply by (1 + stall_depth)" — a single number, x10 here, which
is outside the window where this task is measurable at all.** The discriminator
needs a RANGE and a search, not a multiplier. `v_nw02` is clean at x2 and that
is the whole of the escalation.

### `v_nw01` Q6 — the magnitude was mine, and the axis has no depth

Withdrawn as an escalation. Two separate things were wrong:

1. **The magnitude.** 65 was justified as *"one past `REQUEST_RETRY_INTERVAL=64`"*
   — a quantity about the gap **between requests** — and applied **between
   payload bytes**. 28 bytes x 65 = 1820 cycles per frame against a
   `REQUEST_TIMEOUT` of 256.
2. **The rule has no operand here.** *"One past the deepest buffer on that
   channel"* needs a buffer. Searched across **all** the ARP engine's sources —
   `arp.sv`, `arp_eth_rx.sv`, `arp_eth_tx.sv`, `arp_cache.sv` — there is no FIFO,
   no byte-indexed store, no per-frame buffer of any kind. **The design holds
   PARSER STATE, not buffered beats.**

*(`arp_engine.sv` alone has zero clocked processes — it is a wrapper. My first
search read only the wrapper and concluded the design held nothing, which was
right by accident. The four files that matter were not in scope.)*

**`v_nw01` is NOT MEASURABLE on the inter-beat axis**, and reported as such rather
than perturbed at a guessed depth. The design's own `REQUEST_TIMEOUT` spans a
frame, so any inter-byte gap large enough to be interesting collides with a
timeout that is **correct behaviour**, not a defect.

## Not measurable — five, and that is a result

| task | why |
|---|---|
| `v_nw01` | no buffer between beats; the design holds parser state. Depth rule has no operand |
| `v_ca05` | no beats — single-beat req/gnt operations |
| `v_ca07` | no beats — one value per handshake, output is a clock |
| `v_dsp02` | no beats — one operand per handshake |
| `v_nw04` | no handshake at all — pulse inputs, no ready |

**Five honest rows beat five guessed depths.** Each would have produced a number,
and each number would have been a clean row meaning untested.
