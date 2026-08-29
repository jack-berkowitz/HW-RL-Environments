
<!-- author: agent3 -->
## Capacity FLOORS get controls; capacity CEILINGS get written and forgotten

**Four instances, three found by sweeping for them once the pattern was named.**

| task | clause | the ceiling | checked |
|---|---|---|---|
| `d_nw01` | C3 | at most 4 R and 4 W beats per master port | **no** — 0 mentions in tb |
| `d_ca01` | C4 | at most 2 cache lines outside the arrays, 1 word per miss | **no** — 0 mentions |
| `d_ca04` | B1 | at most 4 further beats of storage across both domains | **no** — 0 mentions |
| `d_nw03` | B1 | over-buffering bound | **yes** — `nc_h_overbuffered` dies at 72 beats |

Against that, the **floors** in the same corpus are all enforced: d_ca03's P2
pins 16+16 TLB entries and `nc_g_itlb_one_entry` fails at one entry; d_nw01's C1
requires a minimum outstanding count and fails below it; d_ca04's C4 requires a
minimum accepted-with-reader-stopped.

**Why the asymmetry is structural, not accidental.** A floor is violated by a
design that does LESS, and doing less shows up as a behaviour the harness
already drives — fewer outstanding misses, a shallower queue, a slower rate. The
check falls out of the stimulus. A ceiling is violated by a design that does
MORE, and doing more is invisible from the delivered surface: a crossbar holding
sixteen beats per port answers every request correctly. Catching it needs a
measurement of internal state or a control built for it, and neither arrives for
free.

**So a ceiling is normative text that grades nothing.** All three unchecked ones
say so in strong terms — *"Storage beyond that is NON-CONFORMING, not a design
choice"* — and a submission that violates them passes with a clean sheet.

### d_ca04's B1 is the instructive one

Its testbench tracks occupancy and marks it **COVERAGE ONLY, never an
assertion**, giving the reason: sampled on `wr_clk` it sees a stale `rd_idx` and
OVERSTATES occupancy, so a bound asserted on it would fail conforming designs.
Someone hit the measurement problem, correctly declined to assert on a bad
measurement, and wrote down why.

That is the right call and it is still a hole. **A clause left unenforced for a
stated good reason is indistinguishable, from the results, from one left
unenforced by oversight** — both produce a passing submission that violates the
spec, and the results carry no trace of which. The honesty lives in the
testbench comment; it does not reach anything that reads the scores.

**These need controls, not annotations.** An annotation records where a clause is
reported; there is nothing to record when nothing reports it. The spec text now
says so in each of the three, which is disclosure, not enforcement.

<!-- author: agent3 -->
## ANONYMOUS and UNCHECKED are indistinguishable from failure output and mean opposite things

A clause can be in one of three states, not two:

    GROUPED     a check observes it and reports under another clause's id
    ANONYMOUS   a check observes it and its message names NO clause at all
    UNCHECKED   nothing observes it

**GROUPED is visible.** The failure names some other clause, and following the
arrow finds the check.

**ANONYMOUS and UNCHECKED are not distinguishable by any inspection of what a
run prints.** In both, the clause id never appears in failure output; in both, a
grep for it returns nothing. They mean opposite things:

    ANONYMOUS   the clause IS enforced. A violating design fails. What is
                missing is attribution -- a GRADING defect.
    UNCHECKED   the clause is NOT enforced. A violating design passes. What is
                missing is the check -- a COVERAGE hole.

Reading the first as the second wastes work writing a check that exists. Reading
the second as the first ships a specification clause that grades nothing.

### The populations, measured

    design half         d_ai01 A1-A10, C1, F2, F3   ANONYMOUS -- one comparison,
                                                    "%0d z mismatches, %0d status
                                                    mismatches", names no clause
                        d_ca03 A1-A11, C1, C3, C4, F1-F3   ANONYMOUS -- one
                                                    per-step message
                        d_dsp02 A1-A9               ANONYMOUS -- two vector
                                                    comparisons
                        d_nw01 C3, D3, H1, H3       UNCHECKED -- nothing observes
                                                    them

    verification half   251 clause-named call sites, 3 anonymous, of 254
                        -> 1.2% anonymous

### The cause is the helper's signature, and it is the actionable part

    verification    task automatic fail(input string cl, input string msg);
    design          task automatic note_fail(input string why);

Where the clause id is a **required argument**, omitting it takes deliberate
effort and 98.8% of sites carry one. Where the message is free text, omitting it
is the default and whole clause sections carry none.

**This is not a discipline problem and it will not be fixed by asking people to
write better messages.** The two halves were written to the same standards by the
same authors; the halves differ in one function signature. Attribution is a
property of the reporting API, not of the care taken at each call site.

### What was done about it, short of changing the API

d_ai01's and d_ca03's annotations state ANONYMOUS explicitly **and name d_nw01**:
*"this reading is WRONG here and RIGHT on d_nw01, where C3, D3, H1 and H3 have no
check at all."* The distinction has to survive being read in isolation, because
the two states look identical from a grep and the annotation is the only place
the difference is written down.

---

## A documented reason for not doing something is not evidence the reason applies

d_ca04's B1 carried its own non-enforcement in the prompt: *"NOT CHECKED BY THE
TESTBENCH, and it cannot be from where the checker stands. `B1` appears ZERO
times in tb/."* It gave a reason, and the reason was **correct about a different
number**.

The objection: occupancy sampled on `wr_clk` sees a stale `rd_idx` and
OVERSTATES, so a bound asserted on it would fail conforming designs. True — of
`peak_occupancy_estimate`, which is sampled while both sides are running. The
testbench carries a **second** occupancy number, `cap_accepted`, measured with
the reader stopped and the writer refused for 64 consecutive cycles. At rest the
synchroniser has converged and the read pointer has not moved. That number is
exact.

**The consequence is the part to state.** C4's *floor* already gated on
`cap_accepted`. So B1's ceiling was **one comparison away for as long as the
floor has existed** — no new measurement, no new phase, no CDC reasoning. The
clause was not hard to check. Nobody checked it, and nothing in the results
distinguished *"cannot be checked"* from *"nobody checked"*, because the text
asserted the first.

That is the general shape:

> **A stated reason for not doing something reads as settled and closes the
> question. It is the reason nobody re-derives it.** An unenforced clause with
> no explanation invites someone to ask why; an unenforced clause with a
> plausible explanation does not. The explanation is what makes it durable.

Test to apply: **name the quantity the objection is about, then check whether
the harness measures a different one.** A testbench with two numbers for the
same concept — one live, one at rest; one sampled, one settled — is where this
hides, because the objection is written about whichever one the author had in
mind and inherits the other silently.

### The settle guard belongs to the same finding

`cap_accepted` is only a capacity **if the writer stayed refused**. The phase
exits either on 64 quiet cycles or on a 4000-cycle guard, and it took the count
either way — so on the guard path the number is whatever had been accepted when
the clock ran out. That unguarded reading **was already gating C4's floor**, and
would now also have gated B1's ceiling. Fixed in `7710c1f`.

Same lesson one level down: the number was trusted because it was already
trusted, not because anyone had checked what made it trustworthy.

### Swept the other design specs for the pattern

Sixteen sites across five tasks state some form of "not checked" / "not
enforced" / "coverage only". Of them:

| clause | verdict |
|---|---|
| d_nw01 C3 | **was the same defect** — enforced at `f63f09a`, text still said ZERO times in tb/ |
| d_nw01 H1, H3, D3 | genuinely unchecked; being built now |
| d_ca01 C4 | **objection is sound, but the clause is mostly redundant** — see below |
| d_ca03 T4 (§538, §586) | "priced, not enforced" — deliberate, and the text says the earlier reading was wrong |
| d_nw03 R5 | GROUPED under R3, not unenforced |

### d_ca01 C4 — the hold is right, and the clause is weaker than it reads

C4 bounds block-data buffering to two lines "outside the tag and data arrays".
Applying the test above: the objection is about the right quantity. There is no
second number. "Outside the arrays" is a **structural** predicate, and a
retained line is indistinguishable from an array entry on the delivered surface.

But C4's own rationale gives the answer to most of it: *"M3 already permits only
ONE memory transaction outstanding, so at most one fill and one writeback can
ever be in flight."* **M3 is enforced** — `m3_overlap_err == 0`, with a firing
counter and a never-exercised guard. So the in-flight half of C4 is **already
enforced transitively**. What remains is retention after a transaction
completes, which is a cache, which is what the arrays are.

One residual that may be measurable and is **not** ready to build: C4 also
allows "per pending miss, at most ONE WORD of merged store data and its byte
mask". A design holding more could absorb more stores to distinct words of the
same missing line before backpressuring, and that is observable at rest. It
needs the clause to settle what happens on multiple stores to distinct words of
one missing line first. **That is a clause question, not a check question.**

---

## A hash computed before a peer's edit and reported after it

`75d3fb2`'s commit message states d_ai01's new `task_text_hash` as
`5b43da0c79a9f813`. **The committed tree hashes to `5da3b5fc43c5f4c6`.** The
message is wrong and this is the correction; the commit is pushed, so it is not
being amended.

**Cause, and it is not carelessness about the number.** I computed the hash
immediately after my own edit, then committed some minutes later. In between,
AGENT-PPA-2381f2fe applied their revert of `7b27f3d` to the working tree —
including `d_ai01/probe/PASTE.md`, a file my commit was about to take. Both
changes were in the file, correctly, and the commit carries both. The hash I had
in hand simply described a state that no longer existed when I wrote it down.

**The general shape.** A hash is a measurement of a tree at an instant. Reporting
one taken before an unrelated edit is the same error as reading a stale index —
the number was true, and it stopped being true without anything announcing it.
Everything else in this repo that goes stale silently has needed a channel; this
needs a rule instead:

> **Compute the hash from the COMMITTED tree, after committing, never from the
> working tree before.** `git archive HEAD <task> | tar -x` and hash that. It
> cannot be stale by construction, because the thing it measures is the thing
> that was recorded.

That is how the correct value above was obtained, and it is what the working-tree
computation could not have given me at any point in the sequence.

**Concurrency made it visible and is not the cause.** A single agent editing two
files and computing between them produces the identical defect. The peer's edit
only shortened the window from minutes to seconds.

---

## An unspecified value on a feedback path is unspecified again, one lap later

d_ai01's C3 excluded `d(0) = D*(HEIGHT-1)+3` enabled ticks after any change of
`accumulate_i`. The accumulate output is `z_o(t) = dot(t) + z_o(t - dfb)` with
`dfb = D*(HEIGHT-1)+4`. The first term settles at `d(0)`. **The second does
not:** for the next `dfb` ticks, `z_o(t - dfb)` still reaches back into the
transient the window just excluded, so the excluded values come back out.

The window ended at tick `d(0)`. The echo began at tick `dfb`. **It escaped by
exactly one tick, and `dfb - d(0) = 1` independently of HEIGHT** — so the defect
was geometry-independent even though the observed counts were not.

    transient (unscored)   tick  1  2 [3=0] 4  5  6   then clean
    echo      (scored)     tick 33 34 [35=0] 36 37 38   then clean
                           35 - 3 = 32 = dfb

Per-row: at every scored tick the diverging row-set was a SUBSET of the
row-set at `tick - dfb`, with two exact matches including the silence.

**Three independent implementations produced identical values at all six scored
samples and all differed from the reference** — two solicited submissions and
this task's own second source, which was written from the spec with `ref/` never
opened.

**WHAT THAT LICENSES, STATED NARROWLY.** An earlier version of this entry said
two independent designs cannot agree bit-for-bit on a wrong value and three
cannot at all. That is wrong, and it is the v_ca07 lesson inverted. **Three
readers of the same underspecified clause agree BECAUSE they share the clause.**
Convergence is what a shared upstream cause produces; it is not evidence against
the one thing they all differ from. The agreement is a signal to look upstream,
which is how it was used here, and nothing more.

The licensed claim is **"the text does not specify z_o through the transient."**
It is NOT "the reference was the outlier." The strong version would license
treating reference-versus-field disagreement as evidence against the reference
elsewhere, and that precedent does not belong in this record — a field that
agrees with itself against the anchor is equally consistent with the field
sharing a misreading the anchor does not.

### Why the observed counts looked geometry-dependent and were not

Scored z mismatches were 0 at HEIGHT=4 and 34 at HEIGHT=8, which reads as a
height-scaled effect. It is not. At HEIGHT=4 the echo escaped C3 exactly as at
HEIGHT=8 and then landed inside an overlapping **C2 flush window** — a flush
pulsed at cycles 1804-1805, and its 15-tick exclusion covered 1806-1820, which
is where the echo arrived. **The defect was fully present at both heights and
invisible at one of them by stimulus coincidence.** A count of failures is not a
measurement of exposure.

### The fix is derived, not fitted

`z_o(t)` is specified only once `t - dfb` is past the transient, so the window
is `d(0) + dfb = 2*D*(HEIGHT-1) + 7`. Stated as that formula rather than as the
two magic numbers the clause used to carry, because a reader could not check
"31 at HEIGHT=8, 15 at HEIGHT=4" and could not extend them to a geometry not
listed.

**Widening an exclusion until failures disappear is how a rig stops
discriminating**, so the window was derived first and the failures checked
after. Every negative control still fails at both heights with margins of 80 to
3033 z mismatches.

### PINNING WAS PREFERRED AND WAS INFEASIBLE, and the reason is C3's own

Pinning `z_o` through the transient means stating what the chain delivers while
partial sums seeded with the pre-transition `y_i` are still travelling, which is
a function of how many registers sit between stages. C3 already refuses that and
the refusal is right: *"Modelling it instead would put a pipeline structure into
the contract and hand every submission a required microarchitecture, which is
the freedom this task exists to measure."* The other form of pinning -- mandating
a defined transient, such as discarding in-flight partial sums on the toggle --
replaces the behaviour rather than describing it, and would make the reference
itself non-conforming.

### THE SECOND HALF IS NOT FIXED AND IS NOT THE SAME DEFECT

After the C3 fix, `z_o` agrees everywhere scored for all three implementations.
The second source still disagrees with the reference on `status_o`: 46 rows at
HEIGHT=4, 55 at HEIGHT=8, and **every single one of them is a `flush_i` HIGH
cycle -- 46 of 46 and 55 of 55.**

That is the question C2 was pinned for in the same session, and the pin resolves
it in the reference's favour via A10. The second source was written before the
pin, from text that permitted more than one reading, and implements a third
reading distinct from both the reference's and the two submissions'. **Its
disagreement is therefore expected and is not evidence that the scored region is
still unspecified -- but it also cannot be used as evidence that it is not.**

Re-deriving the second source's flush behaviour FROM THE PINNED CLAUSE is
outstanding, and it has to be a re-derivation rather than an adjustment until it
agrees. An oracle edited until it matches the reference has stopped being one.

---

## Two tick bases in one harness, and the window enforced in the wrong one

**Instance of Rule 26** — *"name the window in whatever tick the contract
already counts in"*. Counting basis is a harness property; here the harness
holds two of them and the clause holds one.

    A1          an enabled tick FOR ROW r requires reg_enable_i AND
                row_clk_gate_en_i[r], and "all timing below is counted in
                enabled ticks of the row in question"
    rig, C4     decrements on  r.reg_enable && r.row_gate[gi]      per-row
    rig, C2/C3  decrements on  r.reg_enable                        array-wide

`ACC_W = 2*D*(HEIGHT-1)+7` was **derived in A1's per-row basis** — `d(0)` and
`dfb` are both row latencies — and is **enforced in the array-wide basis**. For
a row gated for `G` enabled ticks inside an accumulate window, the window closes
after `ACC_W` array ticks while that row has advanced only `ACC_W - G` of its
own. Its echo needs `ACC_W` of its own, so **the escape re-opens by exactly `G`
ticks, per row.**

### Measured under current stimulus: it is latent, not active

Across every accumulate transition at both heights, **no row has `row_gate` low
inside any ACC_W window.** Zero rows, zero ticks. The defect is real and is not
currently reachable, which is the most easily-lost state to record — it will
become reachable the moment stimulus puts a gate transition near an accumulate
transition, and nothing in the rig would announce that.

### Recommendation, not implemented

**Make the C2/C3 windows per-row, as C4 already is.** Two reasons, and the
second is the load-bearing one:

1. It is what A1 says, and C3 states its window in "ENABLED TICKS" — a term A1
   defines per-row. The rig is not implementing the clause as written.
2. **It needs no clause change and no hash move.** C3 already says enabled
   ticks; only the rig is in the wrong basis. That makes it strictly cheaper
   than the alternative, which would be to restate C3's window in array ticks
   and thereby put a harness convenience into the contract.

The whole-array basis is defensible ONLY as an approximation valid while no row
is gated during a window, which is today's stimulus and is not a property
anything enforces. Stated so it is not mistaken for a design decision.

---

## An exclusion window can be masked by an overlapping window from a different clause

d_ai01's C3 window ended at `d(0)` and the accumulate echo began at `dfb`.
**`dfb - d(0) = 1` at every HEIGHT** — the escape is one tick wide and is
geometry-independent, since both terms carry the same `D*(HEIGHT-1)`.

Observed scored z mismatches were **0 at HEIGHT=4 and 34 at HEIGHT=8**, which
reads as a height-scaled effect and is not one. At HEIGHT=4 the echo escaped C3
exactly as at HEIGHT=8, and then landed inside an overlapping **C2 flush
window**: a flush pulsed at cycles 1804-1805 and its 15-tick exclusion covered
1806-1820, which is precisely where the echo arrived.

**The defect was fully present at both heights and invisible at one of them by
stimulus coincidence.**

### The general form

An exclusion window declared by clause X can be **masked by an exclusion window
declared by clause Y**, so a defect in X's window produces no failures at all.
The masking is a property of the STIMULUS, not of either clause — move the flush
a few cycles and the same rig, the same design and the same defect start
failing. Nothing in the rig or in either clause records that one window is
sitting inside another.

The consequence for how exposure is read:

> **A count of failures is not a measurement of exposure.**

Zero failures is consistent with "the window is correct", with "the window is
wrong and the stimulus does not reach it", and with "the window is wrong and a
different clause's window is covering for it". Those are three different states
and the failure count is identical in all three — the same shape as ANONYMOUS
versus UNCHECKED, arriving in the exclusion machinery.

### The rule this attaches

> **Overlapping exclusion windows are REPORTED AS A COVERAGE MAP, never
> inferred from failure counts.** A rig that excludes on more than one clause
> emits, per exclusion, how many samples it removed and how many of those were
> already removed by another exclusion. An exclusion whose removals are entirely
> redundant with another's is not doing any work, and cannot be distinguished
> from one that is, by any verdict.

d_ai01 today prints a single aggregate — *"243 cycles unscored: C2 flush / C3
accumulate transition windows"* — which sums two clauses into one number and is
exactly the shape that hid this. It is not split by clause and does not report
overlap.

---

## Rule 24 for a WIDENED window needs a control inside the new band

`nc_a..nc_g` fail by 80 to 3033 z mismatches spread across the whole run.
**Every one of them would be caught by a window of any width**, so their firing
says nothing about what C3's new band covers. Rule 24 was not satisfied for the
widening by the set already shipped, and re-running that set after the change
would have looked like evidence.

`nc_h_echo_band_only` corrupts `z_o` **only** inside the newly excluded band —
enabled ticks `d(0)+1` through `d(0)+dfb` after a change of `accumulate_i` —
and is bit-for-bit the reference outside it:

    window            H=4                H=8
    pre-widening      FAIL, 123 z        FAIL, 196 z     DETECTED
    post-widening     PASS               PASS            NOT DETECTED

**Its PASS is the measurement**, which inverts the reading every other control
in that directory takes, and the file says so in its header before anything
else.

### What the widening bought and what it cost

    window length     H=4  15 -> 31      H=8  31 -> 63       doubled
    scored cycles     H=4  3157 -> 3034  H=8  2937 -> 2741
    lost              123 cycles (3.6% of 3400)  196 cycles (5.8% of 3400)

Two numbers already in the record gestured at this and neither was called out
at the time: `nc_g` moved 2752 -> 2557 z rows and the control ceiling moved
3156 -> 3033. Both are the same 123/196 cycles leaving the scored region.

**Bought:** the echo is specified-or-excluded rather than scored, and three
independent implementations that disagreed with the reference on six samples now
agree everywhere `z_o` is scored.

**Cost:** a band of `dfb` enabled ticks after every accumulate transition is now
blind, and `nc_h_echo_band_only` is the proof that it is blind rather than an
assurance that it is empty. Anything a submission does only in that band is
undetectable, and the band grows linearly with HEIGHT — which is d_ai01's
scored axis, so the hole is larger exactly where the task is hardest.

That cost is the argument for pinning the transient rather than excluding it.
Pinning was refused for a stated reason (it requires a microarchitecture in the
contract), so the cost stands as the price of that refusal and is recorded here
rather than left implicit in a scored-cycle count nobody diffs.

### And the control needed the same discipline it exists to enforce

Its first version was detected AFTER the widening too — 16 residual mismatches
at HEIGHT=4 and 32 at HEIGHT=8. Cause: the tick counter free-ran from reset, so
it entered the band during initial startup, where C3's window had never been
armed by a transition. **The control was being detected for a reason that had
nothing to do with the band it was built to measure**, which is the "failed on
the wrong clause" case one level in. Fixed by arming on the first real
transition; the residual went to zero and the pairing became exact.

---

## A clause pinned beside the anchor is not a clause derived from the contract

d_ai01's C2 was pinned this session to say `flush_i` does not affect `status_o`,
with A10 governing throughout. The outcome is defensible: A10 fixes the delay at
2 enabled ticks unconditionally, C2 speaks only of `z_o`, so A10 governs. That
argument does not depend on the reference.

**The provenance does not support it.** The actual order was:

    1. enumerated status mismatches; the output printed
       "cycle 200: expected 0842308421... got 0000000000..."
       -- that is the reference's flush behaviour, and I saw it first
    2. read A10 and C2 -- in a tool call that ALSO decoded and printed the
       reference's recorded status at flush cycles 200/201/601/602
    3. wrote the pin

So the A10 derivation was constructed **after** I knew what the anchor does, and
in the same breath as re-confirming it. I cannot claim the clause was written
from A10's delay rather than from the anchor's behaviour.

### Why this is worth more than the pin

**A clause pinned to match the anchor is the same defect as an oracle edited to
match it, one level up — and it is invisible from below.** Every subsequent
check agrees with a clause that was written to agree with the reference, and the
agreement is not evidence, because the reference is what the clause was fitted
to. There is no experiment inside the task that distinguishes the two cases.

AGENT-VERIF-A2's statement of it is the one to keep:

> A derivation that is sound and whose provenance is contaminated is not the
> same artefact as one that is sound. The first cannot be used to adjudicate the
> thing it was derived beside.

### The general rule

> **A clause that resolves an ambiguity must be derived before the anchor's
> behaviour in that region is read, and the derivation recorded before it is
> compared.** Otherwise it is a transcription with a citation attached, and the
> citation is the part that makes it hard to see.

This applies to every clause pinned the same way, not only C2. The three pinned
this session — C2's flush question, C3's window, and d_ca04's B1 — differ in
this respect and the difference is not visible from the text:

    C3's window     DERIVED. d(0) + dfb follows from the clause's own algebra;
                    the arithmetic was written before the failures were counted
                    and predicted them.
    d_ca04 B1       DERIVED. The ceiling is stated in the clause; only the
                    measurement point moved.
    C2's flush      NOT CLEAN. Argument sound, provenance contaminated.

Recorded per clause because "which of these was fitted" is exactly what a reader
cannot recover later.

---

## A correction that reaches the prose and not the relation

d_ai01's L3 recorded on 2026-08-26 that the chain latency constant was
`D*(H-1)+2` and **"WAS LOW BY ONE"** — a design delivering the 14 the old
constant implied was rejected by a testbench requiring 15, and the testbench was
right. L2 was updated to `d(k) = D*(H-1-k)+3`. The testbench was updated.

**A3's formula and both its tables still said `+2`, for a further day.**

    A3 formula   d(k) = D * (H - 1 - k) + 2
    A3 tables    H=8: 30, 26, 22, 18, 14, 10, 6, 2      H=4: 14, 10, 6, 2
    A3 prose     "Stage 0 consumes the OLDEST operands, d(0) = D*(H-1)+3,
                  and stage H-1 the newest, d(H-1) = 3."

The prose and the formula are **four lines apart in the same clause** and
disagree at both endpoints.

### What that cost, and it is not cosmetic

**A submitter implementing A3 as written builds the design L3 says the checker
already rejects.** The clause that defines the operand schedule told them to
build the thing another clause records as having been failed, correctly, by the
rig they were about to be scored by.

### And it falsifies the correction's own summary

L3 says:

> ONE CONSTANT WAS WRONG AND EVERY RELATION WAS RIGHT.

That was false while A3's formula said `+2` — **the relation carried the old
constant**. The sentence asserting that the damage was contained was itself the
thing that made the surviving instance hard to see: a reader who believed it had
no reason to check the relations.

### The class, which is why this is not a typo

A correction is applied where the argument for it was made. The argument was made
about a LATENCY, so it reached L3, L2, and the latency floor in the testbench. It
did not reach the SCHEDULE clause, which states the same quantity as a formula
for a different purpose. Nothing links them, and nothing was going to.

    reached      L2, L3, the testbench floor, and L3's own narrative
    not reached  A3's formula, A3's two tables,
                 task.yaml's HEIGHT-axis rationale,
                 task.yaml's proposed capacity floor,
                 tb/audit/probe_skew_tb.sv's asserted `expected`

**Five surviving sites, in four files, one of which was a live assertion** —
`probe_skew_tb` would have reported MISMATCH against a conforming design.

> **A constant that appears in more than one clause has as many copies as it has
> purposes, and a correction argued from one purpose reaches one copy.** The
> sweep after a constant changes is not optional and is not "grep for the number"
> — it is grep for the RELATION, in every file, including records that merely
> describe the rig.

Fixed 2026-08-27: the formula, both tables, the two live task.yaml claims, and
the probe's assertion. Historical records of the old value are left as written
and the two dated records that described it as current are marked SUPERSEDED
rather than rewritten — an artefact that only shows its corrected state cannot be
audited for how it got there.

---
---
## FOR THE CATALOG — eighteen entries; twelve landed as F98-F109, six are not yet in the catalog

---

### An audit probe that pinned its model and was never re-pinned

**RETRACTED IN PART, AND THE RETRACTION IS THE FINDING.** This entry first said
`tb/audit/probe_skew_tb.sv` carried a stale constant that would fail a conforming
design. **It carried a correct constant for a different quantity.**

    spec A3 / L2 / L3   d(k) = D*(H-1-k)+3, in ENABLED TICKS (A1)
    probe_skew_tb       D*(H-1-k)+2, in RAW CLOCK CYCLES, t_emerge = cyc - 1

I "corrected" +2 to +3 and **the probe then reported `*** MISMATCH ***` against
the REFERENCE at every stage, uniformly one short, at both geometries.** I
created the apparatus defect I was filing, in the opposite direction, in the act
of filing it. Reverted; the probe agrees with the reference again, and the offset
is now recorded in its header as an **unresolved apparatus question** rather than
closed by choosing whichever constant turns the output green.

**Why the reflex was wrong.** A stale constant in prose is fixed by writing the
current value. An apparatus is not prose: its constant is only meaningful
alongside its measurement convention, and changing one without the other
converts a working instrument into one that fails correct work. **The
documentation-decay repair applied to an apparatus IS the apparatus defect.**

**The question it left open is now CLOSED, 2026-08-27, and the closing is its own
entry below — "A measurement applied in one unit and recorded in another".** L3
records +3 from "an impulse at every stage"; this probe is also an impulse at
every stage and reads +2. They are not two measurements disagreeing by one. They
are ONE quantity counted on two clocks: MEASUREMENTS Sec 3 states, at the point
of measurement, that the impulse is applied for one ENABLED TICK and the
emergence is recorded against a FREE-RUNNING ABSOLUTE CYCLE COUNTER, while Sec 12
and A3/L2/L3 state the delay in enabled ticks. Both constants are correct in
their own unit. `+2` stays; 14 is still not the contract's number.

**The audit, run.** 52 audit probes across 10 design tasks. Scanned for the
signature — an `expected` model pinned to contract constants **and** a fail path,
since a probe that only displays cannot fail correct work:

    probes with a fail path AND a pinned expected model .... 2
    both in probe_skew_tb.sv -- and NEITHER was stale; both are correct
    for that probe's raw-cycle convention and are restored

**So the audit's result is that no design-half audit probe carries a stale
model.** The one that looked like it does not, and finding that out required
breaking it. That is a cleaner result than the one I first filed and it is worth
more: 52 probes, one apparatus/contract offset recorded, zero stale constants.

`probe_l3_latency_tb` is the instructive contrast, and now doubly so: it names
both constants and **asserts neither**, displaying them side by side. A probe
that reports rather than adjudicates cannot rot into a false negative — **and it
cannot be broken by someone correcting it, either.**

**THE TEXT-SWEEP FAILURE STILL STANDS, and it is what surfaced all of this.**
The first pass corrected the total-latency site and missed `D*(H-1-K)+2` at the
per-stage site **in the same file**, because the sweep matched `H - 1 - k) + 2`
and the survivor spells the stage index `K`. **A text sweep on a relation fails
on a capitalisation.** Recomputing the derived value would have found it — and
would then have shown that neither site needed changing, because the recomputed
value under the probe's own convention is +2.

The class rule below reproduced itself one step later, in the file being fixed,
by the person who had just written it down. Then the fix it prompted was itself
wrong. Both are the same underlying error: **treating a number as text.**

**Cross-cites:** "A measurement applied in one unit and recorded in another"
below — same family, and it is what closed this entry's open question.

**Rules:** 24

---

### A correction reaches the copy whose purpose it was argued from

> **A constant that appears in more than one clause has as many copies as it has
> purposes, and a correction argued from one purpose reaches one copy.**

d_ai01's chain-latency constant was corrected from `D*(H-1)+2` to `+3` on
2026-08-26, with the measurement recorded and a rejected-but-compliant submission
as the motivating case. The argument was about a **latency**. It reached every
site whose purpose is latency and no site whose purpose is anything else:

    reached      L2, L3, the testbench latency floor, L3's own narrative
    not reached  A3's formula          d(k) = D*(H-1-k)+2
                 A3's H=8 table        30, 26, 22, 18, 14, 10, 6, 2
                 A3's H=4 table        14, 10, 6, 2
                 task.yaml's HEIGHT-axis rationale
                 task.yaml's proposed capacity floor
    NOT A SITE   probe_skew_tb's two `expected` models -- they were listed here
                 in the first version of this finding and they do not belong.
                 They are correct for that probe's raw-cycle convention, which
                 is one tick off the contract's enabled-tick convention. A
                 recompute-based sweep distinguishes them from the five real
                 sites; a text sweep does not, and neither does a reader who
                 already believes the constant is wrong everywhere it appears.

A3's formula and its prose disagreed **four lines apart in the same clause** for
a day, and A3 is the clause that defines the operand schedule: **a submitter
implementing it as written builds the design L3 records the checker as having
already rejected.**

**FIVE SITES, NOT SIX.** The sixth candidate was an apparatus whose constant was
right for its own convention, and adding it to this list — which I did, before
running it — is the mirror of the defect this finding is about. A correction
under-propagates to copies with a different purpose, **and over-propagates to
things that merely look like copies.** Both are the same failure to ask what the
number means where it sits.

**A THIRD VARIANT, 2026-08-27, and it is the same defect once more.** Sweeping
for F53's ascending-mask defect, I grepped for a mask literal appearing inline at
the port connection and got zero hits — which I nearly reported as "no literal
binding anywhere". Both real sites bind a `localparam` and pass its NAME to the
port, so the pattern is split across two lines and no single-line match can see
it. **A pattern sweep on a BINDING fails on an indirection, as a numeric sweep on
a RELATION fails on a capitalisation.**

> **Both are one defect: a sweep matching SURFACE FORM where the thing swept for
> is a STRUCTURE.** A relation can be respelled, a binding can be indirected, and
> in both cases the structure survives the edit that defeats the grep.

**THE GENERAL REMEDY, and it is what worked here: sweep for the TYPE, not the
form.** The two literal sites were found immediately by grepping for
`fmt_logic_t` / `ifmt_logic_t` — because a declaration MUST NAME ITS TYPE, and
the type is the one token no indirection can remove. The numeric case has the
same shape with recomputation standing in for the type: the derived value must
equal its formula however it is spelled.

**THE EXECUTABLE HALF, and it is the part that makes the rule usable.** A numeric
correction is swept by **recomputing every derived table and expression**, not by
matching the constant's text. On this instance a text sweep for `D*(H-1)+2`
catches L3's citation, **misses `D * (H - 1 - k) + 2`** because the spacing
differs, and **misses both tables entirely**, where the constant survives only as
a trailing `2` in `..., 6, 2`. Three of the six sites are invisible to the sweep
that finds the first.

**THIRD INSTANCE, 2026-08-27, and three is a rate rather than a pair.** A
SECOND correction on the same task under-propagated the same way: C3's feedback
delay was corrected from `d(0)` to `dfb = d(0)+1`, the fix reached the formula
AND the prose restating it, and left the two cited numbers four lines below
reading 15 and 31 -- which are `d(0)`, the values the same sentence says the
earlier draft was wrong to assert. So the current prompt text carried three
instances of this class at once: A3's `+2` residue, C3's `dfb` citation, and L3's
containment claim, which asserted every relation was right and is what kept
anyone from looking for the first two. **A clean reader flagged the C3 one at low
confidence and it was not chased for most of a session** -- a low-confidence flag
on a class with a measured rate deserves a recompute, which costs seconds.

Closed by recomputation with nothing external consulted: C3 closes on itself,
since its transition window is `d(0) + dfb` and is stated as `2*D*(HEIGHT-1)+7`.
**The executable half of this finding is what closed it, on its third instance.**

**Rules:** 24

---

### A containment claim in a finding summary is a measurement

L3's correction record says:

> ONE CONSTANT WAS WRONG AND EVERY RELATION WAS RIGHT.

**That was false when written.** A3's relation carried the old constant at the
moment the sentence was committed, and went on carrying it for a day.

The sentence is not merely wrong — **it is what made the survivor hard to see.**
A reader who believes every relation is right has no reason to check the
relations. A summary that overstates the blast radius of a fix is worse than no
summary, because it converts an open question into a closed one at no cost and
with no record of what was actually examined.

> **A containment claim in a finding is a measurement, and needs its sweep
> stated, or it is not made.** "One constant was wrong and every relation was
> right" is admissible only beside the enumeration that establishes it: which
> relations were checked, by what method, and what the method cannot see. Absent
> that, the finding says what was fixed and stops.

This generalises past the task. Every finding in this catalog that scopes its own
damage — *"this affected only X"*, *"no other instance exists"*, *"the rest were
already correct"* — is asserting a sweep. Where the sweep is not stated, the
claim is an intuition wearing a measurement's grammar, and it is load-bearing for
every reader who then does not look.

**A SECOND FAILURE MODE OF THE SAME CLAUSE, contributed by AGENT-VERIF-A2 and
filed with their name on it.** The case above is a sweep that was never stated.
Theirs is a sweep that EXISTS and whose discriminator is INCIDENTAL RATHER THAN
DESIGNED: a containment claim — "one defect closes both branches" — held only
because two selector sites happened to write different sentences. Measured, it
was false; four of five rows closed, not five.

**And the incidental case is the more dangerous of the two.** A missing sweep
fails loudly, by being unmeasurable — you cannot quote a number you never took.
An incidental discriminator starts measurable and can stop being so between one
commit and the next **with the table still printing a number.** Nothing fails,
nothing warns, and the claim silently changes from measured to assumed.

**The remedy is where it gets sharp, and it is one wording edit from gone.**
Anyone tidying the two messages toward a common phrasing, or factoring them
through a shared helper, destroys the discriminator without touching the mutant,
the selector, or the clause. The fix is distinct ids on the two returns — the
compound-id split this corpus already performs, arriving as the case where the
split was made at the CLAUSE level and not at the SITE level. Two sites, one id,
and the id is what the instrument reads.

**So: state the sweep, and state what the sweep DEPENDS ON.** A discriminator
that is a property of the artefact's incidental wording is a dependency on a file
anyone can innocently break, and it belongs in the claim beside the sweep itself.

**Rules:** 24, 36

---

### An unsigned comparison inverted a probe's verdict while its own numbers said the opposite

**APPARATUS. Same family as F64, and it belongs beside it in the catalog.**

d_ai01's refill-duration probe printed `*** OUTSIDE the named window ***` while
the numbers on the same line — 13 at HEIGHT=4, 29 at HEIGHT=8 — are **inside**
the window (15, 31). `WIN` was declared `int unsigned`, so comparing the
never-diverged sentinel `-1` against it promoted to unsigned, and a result
meaning "no divergence found" read as a violation.

**Caught only because the numbers were read rather than the verdict.** The
verdict line and the data it summarised were on the same line and disagreed, and
the verdict was the more prominent of the two.

    printed   *** OUTSIDE the named window ***
    printed   13 (H=4), 29 (H=8)
    window    15, 31
    truth     inside, i.e. never diverged, i.e. the clean result

**Why this is apparatus and not a typo.** The bug is in the instrument's
*verdict computation*, not in its measurement — every number it produced was
correct. An instrument whose numbers are right and whose conclusion is inverted
is worse than one that is simply wrong, because its output survives a numeric
sanity check: a reader spot-checking the values finds them consistent with the
run and is reassured by exactly the part that was never in question.

**The general form, and it is why the F64 family keeps recurring:**

> **A verdict is a derived value and inherits every type rule of its
> operands.** `int unsigned` is not a documentation choice; a sentinel compared
> against it is a different expression than the same sentinel compared against
> `int`. Sentinels and width/signedness are the two halves of the same defect —
> a sentinel only works if the comparison that reads it preserves its sign.

**Sentinel-specific corollary:** `-1` as "not found" requires the comparison to
be signed, and nothing in the declaration of the *other* operand announces that
it will not be. Prefer a separate `found` bit to a sentinel wherever the
comparison crosses a type boundary — a boolean has no promotion rule to get
wrong.

**Rules:** 24

---

### A measurement applied in one unit and recorded in another

> **A measurement applied in one unit and recorded in another produces a constant
> correct in neither. Stating the mixing where the measurement is taken does not
> propagate it to the sites that consume the number.**

d_ai01's per-stage operand-to-output delay was recorded twice and the two records
differ by exactly one:

    spec A3 / L2 / L3, MEASUREMENTS Sec 12   D*(H-1-k)+3, ENABLED TICKS (A1)
    tb/audit/probe_skew_tb.sv                D*(H-1-k)+2, RAW CLOCK CYCLES

That looked for a day like two impulse measurements disagreeing, and it was
carried as an open discrepancy in the entry above. It is not a disagreement.
MEASUREMENTS Sec 3 says, in the two sentences that describe the method, that the
impulse is **applied for one enabled tick** and the emergence cycle is **recorded
against a free-running absolute cycle counter**. One quantity, two clocks, offset
by the probe's own `t_emerge = cyc - 1`. Both constants are right in their own
unit and neither is stale.

**The defect is not the mixing — it is that the mixing was documented only where
it happened.** Sec 3 states both units plainly and does not flag them as
different; every later site that consumed the number took it as a bare integer.
A convention stated at the point of measurement and not attached to the value
travels nowhere, because the value travels and the sentence does not.

**Why this is the same family as the apparatus-constant entry above.** There the
lesson was that an apparatus constant is meaningful only alongside its
measurement convention, and that "correcting" one without the other breaks a
working instrument. Here is the other end of the same rope: the convention *was*
recorded, and the number still arrived at four consuming sites without it. The
pair is the finding — **a constant and its convention are one object, and every
mechanism that moves the constant must move the convention or refuse to move.**

**Executable form.** A measured constant is written with its unit at the value,
not in the surrounding prose: `d(k) = D*(H-1-k)+3 enabled ticks`. Where two units
are in play in one document, a site stating one of them names the other and its
offset. Both are one-line obligations and both would have prevented this.

**Cross-cites:** "An audit probe that pinned its model and was never re-pinned"
above.

**Rules:** 24

---

### A clause stating a global effect where the mechanism is per-instance gated

> **A clause that describes an effect on "every X" is asserting a quantifier over
> the mechanism, not over the outcome. Where the mechanism is gated per instance,
> the quantifier is false and the clause reads as true because the usual
> configuration has every gate on.**

d_ai01's C2 said flush "forces every inter-stage register of every row to zero".
The row registers are clocked by the gated `row_clk`; a row with its clock gate
off receives no edge and is untouched. Measured (MEASUREMENTS Sec 7): with one
row gated off and flush asserted, the clocked row went to `0x0000` and the gated
row held `0x4800`. **The clause was corrected before this catalog entry existed**
and C2 p1 now carries the qualifier explicitly, together with the statement that
flush is not an exception to C4.

**The instructive part is where the universal SURVIVED.** The clause was fixed;
the *measurement narrative that fixed it* was not. MEASUREMENTS Sec 6, written
before Sec 7 existed, still read "while `flush_i` is asserted every inter-stage
register reads zero" — an unqualified universal, two sections above the
measurement that refutes it, never amended when the clause was. A correction
propagated to the normative text and not to the record it was derived from.

**The general form, and it is a cheap check.** For every clause quantifying over
instances of a resource, ask what CLOCKS or ENABLES that resource. If the answer
is a per-instance gate, the quantifier is over ungated instances and the clause
must say so. The default configuration — all gates on — makes the false universal
indistinguishable from the true restricted one in every ordinary run.

**Cross-cites:** "A correction reaches the copy whose purpose it was argued from"
above — this is the same under-propagation with the direction reversed: there the
fix reached the clause's copies with one purpose and not the others; here it
reached the clause and not the measurement it came from.

**Rules:** 24, 26

---

### Marking a block SUPERSEDED does not mark the claims inside it

> **A supersession header is navigation. A reader who arrives by grep, by line
> number, or by a link into the middle of a document never sees it, and reads
> every sentence in the block as live.**

d_ai01's MEASUREMENTS Sec 15 was marked `SUPERSEDED` at its header, with the
reasons stated, including that one of its factual claims had been **measured
false**. The claim itself — "the reference ... evidently keeps ADVANCING its
status pipeline through the flush" — sat 43 lines further down, unmarked, in
ordinary declarative prose. A search of the file for `advanc` lands on that
sentence and not on the header.

**This is not hypothetical in this document.** The search spec written for this
same file records that a clean reader was contaminated by a **table-of-contents
heading** carrying a verdict on the question they were deriving, before any body
text was read. Headings are read as content when they should be navigation; block
headers are read as navigation when they should be content. Both failures are the
same mistake about where a reader's attention actually enters a document.

**The rule.** When a block is superseded, mark the **specific sentences whose
truth changed**, at those sentences, dated, with what falsifies them — and leave
the text otherwise as written, because an artefact that only shows its corrected
state cannot be audited for how it got there. The header stays; it is not
sufficient on its own.

**The check is mechanical.** In a block marked SUPERSEDED / RETRACTED / CLOSED,
every sentence stating a fact about the world in the present tense is a candidate
for its own marker. If there are none, the header was doing nothing and the block
was reasoning rather than assertion.

**Rules:** 24, 26

---

### An isolation protocol silent about VERSION is half-specified

> **Naming which files a clean reader may read pins the SCOPE of an isolation.
> It does not pin the ARTEFACT. In a shared tree written concurrently, the same
> protocol executed twice reads different text and produces derivations that
> cannot be compared.**

d_ai01's C2 derivations were run under a protocol specifying exactly what a clean
reader could read — `spec/`, `probe/PASTE.md`, greps of RULES/CONVENTIONS — and
explicitly what they could not. The protocol was complete about the file set and
silent about the version. **A prior reader watched the contract file change under
them mid-session.** The tree is shared with two peer agents who commit to it
while a derivation is in progress.

**Two things break, and they are different.** The derivation may straddle a write
and rest on text that never existed as a whole. And a second derivation run for
independent confirmation is not a replication if the artefact moved between them
— it is a different experiment reported as the same one, which is worse than no
replication because it is counted.

**The fix is three lines and belongs in the protocol, not in the reader's
judgement:** record `git rev-parse HEAD`, `git status --porcelain -- <path>` and
`shasum <file>` before reading; re-run the shasum at the end; report both. If
they differ, the read straddled a write — redo it, do not reconcile it.

**The general form.** Any isolation, quarantine or blind-review protocol that
names sources must also name the version of each source and require the reader to
verify it did not move. "Read only X" and "read only X as of SHA" are different
instructions, and only the second is reproducible.

**Rules:** 22, 24

---

### An open question stated in one section and not carried into the reasoning of another

> **A document that enumerates its open questions in one place and reasons in
> another can contradict itself without any single sentence being wrong. The
> enumeration stays true; the reasoning quietly assumes it away.**

d_ai01's C2 derivation listed, under "Q1 — unique?", **three** surviving readings
of what `status_o` does during a flush: two marching readings and R-C, holding.
Four paragraphs earlier, D6 concluded "STAGE 0 IS FULLY DETERMINED throughout the
assertion", reasoning entirely about which operand stage 0 reads — an argument
that only discriminates between the two marching readings. Under R-C, stage 0
holds like every other stage and the exemption does not exist.

The document never denied R-C. It listed it, and then reasoned as though the
question were which of R-A and R-B held.

**What it cost.** D6's stage-0 exemption became the `k >= 1` scoping of a
proposed C5 enumeration and of a 3-enabled-tick exclusion window. A probe
(`probe_flush_status_tb`) later returned R-C, and both the scoping and the window
were deleted rather than rewritten. **The defect was visible in the document
before any measurement was taken** — the enumeration and the reasoning were four
paragraphs apart and disagreed.

**Mechanically checkable, which is why it is worth a catalog entry.** For every
question a document lists as OPEN with N surviving answers, every later
conclusion in that document must either hold under all N or name the ones it
excludes and why. A conclusion that holds under a strict subset, stated
unconditionally, is the defect — and finding it needs no domain knowledge, only
the enumeration and the conclusions in the same file.

**Not a duplicate of "a containment claim needs its sweep stated".** That one is
about a claim whose scope is unmeasured. This one is about a claim whose scope is
measured, written down in the same document, and then not consulted.

**Rules:** 24, 36

---

### A correction reaches the normative text and not the record it was derived from

> **A correction reaches the normative text and not the record the text was
> derived from. The record then reads as a live claim to anyone arriving by
> search, and quoting it propagates the dead version forward.**

Two instances in one file, found within an hour of each other, pointing the same
way.

**One.** d_ai01's C2 was corrected in commit `0477595` to say flush clears every
row *whose clock is enabled*, and MEASUREMENTS Sec 7 was written in the same
commit to record why — quoting the dead draft in the past tense: *"C2 said flush
forces every inter-stage register of every row to zero"*. A later reader
searching the file for that string landed on the quotation and reported it as a
live defect in current clause text. **The string appears zero times in the spec.**
The correction was complete; the record of it was indistinguishable from the
thing it corrected, to a reader who arrived at the line rather than at the
paragraph.

**Two.** The same file's Sec 6, written *before* the measurement that produced
Sec 7, still said "while `flush_i` is asserted every inter-stage register reads
zero" — the unqualified universal, two sections above its own refutation, never
amended when the clause was. That one was live and had been for as long as the
clause was wrong plus everything since.

**The two failure modes are opposite and the cause is one.** A quotation of a
dead claim reads as live; a superseded claim in a narrative reads as live. Both
happen because the correction is applied where the *rule* lives and the *record*
is left as an append-only history that nobody re-reads as a whole.

**Handling, and it is not "delete the record".** Records are append-only for good
reason — an artefact that only shows its corrected state cannot be audited for
how it got there. The obligation is to MARK, at the sentence: a quotation of
superseded text is marked as a quotation, and a superseded assertion is marked
with the date and what falsifies it. Both cost one line and both are invisible to
a reader who does not need them.

**The sweep this implies.** When a clause is corrected, the sweep is not only
over other copies of the clause — it is over every document that *quotes,
restates or reasons from* the old text. Those sites do not match a search for the
new wording, only for the old, which is exactly the search nobody runs after a
fix.

**Cross-cites:** "Marking a block SUPERSEDED does not mark the claims inside it"
above — both are about a reader arriving at a LINE rather than at a document, and
the fix in both is a marker at the sentence rather than at the container. Also
"A correction reaches the copy whose purpose it was argued from", which is the
same under-propagation confined to the normative text.

**Rules:** 24, 26

---

### A maintenance obligation stated as a grep is only as good as the grep

> **A clause that makes itself checkable by naming a string has delegated its
> correctness to a text match, and a neighbouring clause can break it by using
> the same words to say the opposite thing.**

d_ai01's C5 enumerates every interval this contract excludes from scoring, and
states the obligation as a test: *"every site in this file matching 'excluded
from scoring' appears above"*. That was true when written. It **began failing in
the same commit that landed it**, because the C2 rewrite beside it contains the
sentence `NOTHING IS EXCLUDED FROM SCORING DURING AN ASSERTION` — a negation,
matching the string exactly, asserting the reverse. C5's own self-reference
matched too. Three of five matches were not exclusion sites.

**The failure is not the wording, it is the delegation.** A grep tests
CONTAINMENT of words. A maintenance obligation is about what a sentence DOES.
Those coincide only while no neighbouring text discusses the same subject, which
is the one condition a clause cannot rely on: the neighbours of a clause about
exclusions are clauses about exclusions.

**Narrowed 2026-08-27** to test what a sentence does rather than the words it
contains, with the negation and the self-reference named as non-sites. **And the
narrowing has a cost that should be stated rather than discovered:** the test is
no longer executable by a grep. It now needs a reader who can tell an exclusion
from a statement about exclusions. "Checkable" moved from *mechanical* to
*checkable by someone who reads it*, which is weaker and is what the honest
version of the clause claims.

**The general form.** When a document makes itself self-checking, state whether
the check is MECHANICAL or requires judgement, and never let a mechanical check
be phrased over a string that ordinary discussion of the subject would also
produce. A mechanical check on vocabulary is a check on the absence of neighbours.

**Cross-cites:** "A containment claim in a finding summary is a measurement"
above — that entry requires a sweep to be stated; this one is what happens when
the sweep IS stated and the sweep is the wrong instrument. Also the text-sweep
half of "A correction reaches the copy whose purpose it was argued from": a text
sweep on a relation fails on a capitalisation, and a text sweep on an obligation
fails on a synonym or a negation.

**Rules:** 24, 36

---

### The working record understates what exists, and it does so by default

> **MEASURED, not asserted: on a task where every deliverable was complete and
> correct in the authoritative artefacts, NINE separate claims in the working
> record contradicted them — and all nine erred in the same direction, saying
> less exists than does.**

d_ca01 was revisited for four items: a determinism check, a clause defect
write-up, a design-difference refutation, and mutant non-equivalence evidence.
**All four were already finished.** The spec, `task.yaml`, `RULES.md`,
`FINDINGS.md` and `scripts/sim_candidate.sh` were each correct. `NOTES.md` and
`PROPOSED_RULE.md` said otherwise in nine places:

    a section describing a deleted script by filename, in the present tense
    five headings reading FINDING (PROPOSED) for findings landed as F43-F48
    a heading reading "PROPOSED for RULES.md -- NOT LANDED" for a landed rule
    "Mutants -- six" for a set of seven
    an equivalence table of six for nine artifacts carrying the evidence
    "there is no formal non-equivalence result for these mutants" -- 70 lines
      BELOW the section that obtained one for every mutant
    a design difference proposed as live, refuted 460 lines further down
    a top-of-file status row reading PPA NOT STARTED against 13 run records
    a handoff item reading "still not landed ... not quotable" for a landed
      exemption whose results are now quotable

**RATE, as of 2026-08-28: three tasks, FOUR SURFACES, ~two dozen sites,
direction unvaried.**
d_ai01 twice, d_ca01 twelve, d_ai04 three. **d_ai04 is the instance that removes
the obvious explanation.** The other two were tasks under active edit, where
"the author forgot to update the record" is available. d_ai04's author had not
touched it since writing those records: they were ACCURATE WHEN WRITTEN and the
tree moved past them. Nobody failed to update anything — the record was right and
then stopped being right without being touched.

**AND TWO OF d_ai04'S THREE ARE ACTIONABLE-FALSE, WHICH IS A DIFFERENT THING FROM
INCOMPLETE.** A stale record that understates does not merely fail to mention
work; it **withholds permission for work already done and licenses work already
finished.**

    ppa_status          "no PPA may be reported yet"     while a PPA record
                                                         sits in runs/
    submissions_status  "no submission exists"           while three passing
                                                         ones sit in candidates/

The first tells a PPA owner not to record a number that exists. The second tells
anyone reading it to solicit, and acting on it produces a fourth submission for
nothing.

**BOTH COSTS WERE CONFIRMED INDEPENDENTLY BY THE AGENT THEY POINT AT, the same
day.** AGENT-PPA reports that they had already found d_ai04's three candidates
passing and queued them for a PPA build — *"Had I read that field and believed
it, I would have solicited a fourth submission for a task that already has three
passing ones"* — and that the reference PPA record `ppa_status` denies is the one
they built the README row from. This is not a projected consequence. It is a
near-miss recorded by the party the false record was pointed at.

**AND A FOURTH SURFACE, theirs, same class and a different mechanism entirely.**
d_ai04 appeared NOWHERE on the README — no chart, no table, not even "not
measured yet" — because the design-task list was a **hardcoded seven-task
tuple**. A pin, a reference that closes timing and three passing candidates, and
the surface that publishes the project simply had no slot for it. So the count is
now: two `task.yaml` fields, one catalog row, and one report generator, **four
independent records, none of which was wrong when written, all understating the
same task.** Neither is a gap in a narrative — each is an instruction, and each is
the wrong one. **That is the reason this class is worth a mechanical check rather
than a habit of tidying:** the cost is not an out-of-date document, it is work
not done and work done twice.

**The direction is the result.** Not one of the twenty-plus overstated. A working record
decays toward *understating* what exists, because the act that makes a claim
stale — finishing the thing — is the act whose author has the least reason to
return to where it was last described as unfinished. Overstatement requires
someone to write a claim that was never true; understatement requires only that
someone succeed and move on.

**Consequences, and they are not cosmetic.** A reader deciding what to work on
next reads the record, not the authority: they will rebuild what exists, or
report as blocked what is landed. And the record is what gets *quoted* — the
sentence saying no formal non-equivalence result exists was still sitting under a
heading about the tool a later instruction named, which is exactly where the next
reader looking for that tool would arrive.

**The top status block is the sharpest instance.** Its neighbouring rows —
mutant count, conformant count — were current. The PPA row was not. **A
maintained table goes stale one row at a time**, and being maintained is what
makes the stale row credible.

**The sweep that is mechanical, and it is worth running before the reading.**
Every filename cited in a working record, tested for existence: 37 cited on this
task, 2 absent, one of them a genuine defect. Every status word — NOT STARTED,
NOT LANDED, PROPOSED, not built — enumerated and checked against its authority.
Both are one-pass and both paid here. **What neither covers** is a claim stale in
its content rather than in a filename, a count or a status word — those come out
only by reading, and the reading was scoped to four items in a 1300-line file.

**The remedy is a direction of travel, not a document.** When work lands in an
authority, the sweep is over the record that *proposed* it — and the search term
is the OLD status word, which is the only string that still matches.

**Cross-cites:** "A correction reaches the normative text and not the record it
was derived from" above — this is that finding measured on a third task, with a
rate and a direction attached. "Marking a block SUPERSEDED does not mark the
claims inside it" — the handling for all nine was a dated marker at the site,
leaving the text as written. "A containment claim in a finding summary is a
measurement" — the sweep above is stated because this entry's count is one.

**Rules:** 13, 24, 26

---

### A stale measurement restated as live, in the report that filed the finding about it

**MY OWN, and it is the cleanest instance of the class because the interval is
ten minutes and the author had just written the rule.**

At 15:47 on 2026-08-27 I reported *"Still none of the twelve is in
`FINDINGS.md`"*. The grep behind that sentence was run before 15:37, which is
when Agent 1 landed nine of them as **F98-F106**. I restated a measurement
without re-taking it — **one minute after committing "The working record
understates what exists", which is the finding about doing exactly that.**

    measured   ~15:00   grep -ic <title> FINDINGS.md  ->  0 for all twelve
    changed     15:37   c64b714 lands nine as F98-F106
    restated    15:47   "Still none of them in FINDINGS.md"
    direction            UNDERSTATED, like every other instance

**Two things this adds that the parent finding did not have.**

**One: the decay is not a property of documents.** The parent finding measured it
in `NOTES.md` and in a spec's measurement record — artefacts that sit still and
rot. This instance is a *report*, composed in one pass, where the stale claim and
the finding about stale claims were adjacent paragraphs. The carrier does not
matter. What matters is that a measurement was taken once and its result was
carried forward as a fact.

**Two: writing the rule does not protect you from the rule.** I had just
articulated why the decay happens — the author who makes a claim stale is the one
who finished the thing and has least reason to revisit where it was called
unfinished. Here the author who made my claim stale was *someone else*, which is
the same structure one degree worse: I could not have noticed without
re-measuring, and nothing prompted me to.

**Which is the argument for binding rather than for care.** "Be careful about
restating" is not actionable — the sentence read as true to me when I wrote it,
and re-reading it more carefully would not have changed that. What would have
changed it is one re-run of a command I had already written once. **A negative
claim about the tree should carry the command that produced it, at the sentence,
with the date it was measured.** See `inbox/PROPOSED_CHECK_record_drift.md`,
Part 4, where the timing argument is the whole case: the binding is free only at
the moment the claim is first made.

**Cross-cites:** "The working record understates what exists, and it does so by
default" above — this is that finding with the shortest interval yet measured and
with the author of the finding as the subject. "A containment claim in a finding
summary is a measurement" — a negative existence claim is a containment claim
with the scope set to zero, and it needs its sweep re-run, not merely stated.

**Rules:** 13, 24, 26

---

### Re-hashing a pinned blob is a tautology, and it was written as an isolation check

> **An immutable object always matches itself. A version-pinning instruction that
> says "re-hash the pinned blob and confirm it matches" specifies a check that
> cannot fail, and therefore cannot detect the thing it was written to detect.**

The isolation protocol for a clean-reader derivation on d_ai01 required pinning
the sources by hash and re-verifying at the end. **Re-hashing the pinned blob is
a tautology** — git objects are content-addressed, so the pinned blob's hash is
its identity and re-computing it confirms nothing about whether the FILE moved.

**What actually detected the mid-session move was a different comparison:** the
pinned blob against the file at CURRENT HEAD. That is the check that can fail,
and it is not the one the instruction specified.

**This is the silence-failure class arriving in an instruction written to enforce
discipline.** The author of the protocol had internalised that a check whose
control never fires validates nothing, wrote a protocol to protect a derivation
from a shared tree, and specified a check with no failing case. Knowing the rule
is not the same as applying it to the artefact you are writing at the time.

**The corrected form, and the difference is one operand:**

    WRONG   shasum the pinned blob at the end; confirm it matches the pin
    RIGHT   git rev-parse HEAD:<path> at the end; confirm it matches the pin
            -- and record HEAD at both ends, since the pin is a claim about
               WHICH HEAD the reading was taken against

**Generalises past isolation protocols.** Any verification step whose two
operands are the same object cannot fail. The test is: name the state of the
world that makes this check report a failure. If you cannot, the check is a
tautology however carefully it is worded.

**Rules:** 3, 22, 24

---

### Pinning the tree leaked the control names, and the control names describe the defects

> **An isolation protocol that requires a directory listing to establish
> provenance hands the isolated reader the names of the negative controls — and a
> control's name states its defect, which by negation asserts what the reference
> does.**

Pinning d_ai01's tree required `git ls-tree`, which printed `controls/`:

    nc_c_flush_subnormal        nc_d_overflow_always_inf
    nc_e_positive_zero_only     nc_f_reversed_chain
    nc_g_height_blind_depth

**Every one is a statement about the reference, delivered by negation.**
`nc_c_flush_subnormal` says the reference does NOT flush subnormals — which is
A6/A7's content. `nc_d_overflow_always_inf` says overflow does not always deliver
infinity — A5's content, and A5 is one of the three items currently open.
`nc_e_positive_zero_only` says zero signs are preserved. A reader deriving what
the contract requires, from text alone, now has five answers they did not derive.

**The provenance step and the isolation are in direct conflict, and neither is
optional.** Provenance exists because the tree is shared and written
concurrently; isolation exists because a derivation contaminated by the answer is
not a derivation. The protocol satisfied one by violating the other.

**Two fixes, either sufficient, both cheap:**

    A  path-scope the listing:  git ls-tree -r HEAD -- <task>/spec
       the reader pins exactly what they are allowed to read and nothing else
    B  the brief carries the SHA, computed by the router
       the reader verifies against a value handed to them and lists nothing

**B is stronger and it is the same rule as the routing-message finding.** The
router must be able to write the hand-off without knowing the answer; here the
router must be able to establish provenance without the reader seeing the tree.
Anything the reader must run to verify provenance is a channel, and a listing is
a wide one.

**And naming is the underlying exposure.** Controls are named for their defects
because that is what makes them readable to their own maintainer. That is right,
and it means the control directory is a compact statement of everything the
reference does. It should be treated as answer-bearing wherever isolation is in
force, not merely as apparatus.

**Rules:** 22, 24

---

### A stale git index and a dirty one are indistinguishable to every ordinary command

> **`git status`, `git diff --cached` and `git diff HEAD` all report a stale index
> as staged deletions. The discriminator is a one-line measurement and it is not
> one anybody runs.**

Three agents share one working tree here. Commits are made through a temp index
(`GIT_INDEX_FILE=$(mktemp); git read-tree HEAD; git add -- <paths>`) so that no
agent's staging can reach another's commit. **The side effect is that the REAL
index is never advanced** — it holds whatever tree it last held. HEAD moves on,
and everything the newer commits ADDED then reads as a staged DELETION.

Both directions were misread on the same day:

    read as "my files were deleted"            -- an agent whose new files
                                                  looked gone, and who therefore
                                                  read a peer's committed work as
                                                  uncommitted
    read as "my commit is staged for reversion" -- an agent seeing 752 deletions
                                                  of files present on disk and
                                                  byte-identical to HEAD, who
                                                  stopped work and warned a peer
                                                  off committing

**Neither was happening.** The measurement that settles it takes one line, is
read-only, and was decisive immediately:

    IDX=$(git write-tree)                      # does not alter staged content
    for c in $(git rev-list -12 HEAD); do
      [ "$(git rev-parse "$c^{tree}")" = "$IDX" ] && echo "STALE: index == $c"
    done

A match means the index is a stale snapshot of a real commit and holds no
staged intent. No match means look harder.

**Why the false reading is the dangerous one here.** "The index is staged to
revert 752 lines" is alarming and correct-sounding, and the natural response is
either to stop, or to reset shared state that might hold a third agent's work.
The measurement licenses the repair — `git read-tree HEAD` with `GIT_INDEX_FILE`
unset destroys nothing when the index is stale — and without it the safe-looking
move is to leave a confusing index in place for the next agent to rediscover.

**The general form:** where a working tree is shared, `git status` describes the
relationship between three objects — the working tree, the index, and HEAD — and
a claim about any one of them needs to say which pair it compared. Most confusion
between agents here has been two different pairs reported as though they were the
same comparison.

**CO-OWNED with AGENT-VERIF-A2**, who hit the same artefact from the opposite
side within the hour and confirmed the discriminator by running it rather than on
report. Their framing of why it is necessary is the one to keep: **the
discriminator is not a convenience, it is the only thing that separates the two
cases**, because all three ordinary commands report them identically. And the
sign of the error depends only on which side of the stale index your own commits
fell — a stale index makes you read a peer's committed work as uncommitted, or
your own committed work as staged for deletion, and it is the same artefact both
times.

**The contributing cause is an omitted step, not the temp-index procedure.**
Committing through a temp index is correct and is what keeps agents' staging out
of each other's trees. What produces the stale index is omitting the refresh
afterwards: `unset GIT_INDEX_FILE; git read-tree HEAD`. Any temp-index commit
helper that lacks that line leaves the shared index one commit further behind
every time it lands something.

**Cross-cites:** F95 (three agents, one git index) — this is that hazard's
benign twin, and telling them apart is the whole difficulty.

**Rules:** 24

---

### A correct measurement, a mechanism inferred from it, and no test of the mechanism

> **The measurement always feels like it contains the explanation. It does not,
> and the inferred mechanism is then shipped to someone as a reason to act.**

Three instances in one session, across two agents, each one a peer telling
another peer to stop or to go:

| measurement, correct | mechanism inferred, untested | consequence |
|---|---|---|
| the witness gate refused my commit; a direct run of the checker in the working tree showed 4 problems and a run over `git archive HEAD` showed 1 | *"the gate reads the working tree, so a peer's unsaved edits can block you"* | told a peer they were unblocked when they were not; they acted on it and told me to retry |
| the shared index would commit a tree with a peer's whole change reverted | *"so any commit, including yours, carries those deletions"* | told a peer to stop committing; their helper was immune |
| the index diff showed 752 staged deletions of files present on disk | *"the index holds someone's staged intent and resetting it could destroy work"* | left a confusing index in place and treated a safe repair as dangerous |

**Every one has the same shape: a real measurement, one inferential step past it
to a mechanism, no test of that step, and then delivery to a peer as grounds for
action.** In the first case the refutation was *inside the output I had already
quoted* — the gate's own failure line reads "on the tree the index would commit",
and I pasted that line into a report asserting the opposite.

**What makes it cheap to fall into.** The measurement is genuinely hard-won and
genuinely correct, so the confidence attaching to it is earned — and then it
transfers, unearned, to the explanation. The explanation is the part that gets
sent, because it is the part that is actionable.

**The discipline is one question, asked before the mechanism is transmitted
rather than before it is believed:** *what would I run to make this mechanism
fail?* All three were one command away. Reading the gate's own source settled the
first; comparing two tree hashes settled the second and third.

**And it is not learnable by watching someone else do it.** Both agents here
watched the other make this error and then made it again — one of them twice,
after writing up why it was wrong the first time. That is the argument for
attaching the question to the ACT of sending a mechanism to a peer, rather than
trusting recognition.

**THE FIFTH INSTANCE ARRIVED INSIDE A MESSAGE ABOUT THE FOURTH, and it is the one
that settles the placement.** A peer ran the commit gate once, saw one red row,
concluded a second row had never been there, and used that to suggest I had
routed a correction on a reading the gate did not support — **in a message whose
subject was correcting me for confusing two objects.** The two runs were three
minutes apart across a two-minute window in which the row existed and was fixed.

**What makes this instance decisive is not the error, it is what was already in
their hands.** My message to them contained a VERBATIM QUOTE of the gate output
naming the row they concluded had never appeared. The refuting evidence was not
merely available — it had been handed to them, in the message they were replying
to, and reconciling it was reading rather than measuring. Their own summary:
*"Recognition was not just insufficient — I was actively writing about the
failure mode while committing it."*

So the control cannot be "notice that you are inferring". Both parties have now
demonstrated that noticing runs concurrently with doing. It has to be a step
attached to sending: **before transmitting a mechanism, reconcile it against any
contrary evidence the recipient has already shown you.**

**WIDENED BY AGENT-VERIF-A2, and their framing supersedes the title.** The three
rows above are all mechanism-from-measurement, which is how I first filed it. That
is a special case. The family is **a source that underdetermines, and a reader who
resolves it silently and then acts on the resolution as though it were given:**

    a correct measurement    resolved into a mechanism
    a two-word phrase        resolved into an assignment
    a bare identifier        resolved into an address
    an ordinal / -m1 hit     resolved into a coverage set
    a staged-deletion count  resolved into another agent's intent

Five instances, one session, two agents. Nothing in any source was false. In every
case the reader supplied the missing determination, and the supplied half then
travelled as though it had been given.

**THE FOURTH ROW IS THE ONE THAT SETTLES THE CONTROL'S PLACEMENT.** "Second source
unrouted" was read as *not yet assigned, so it falls to you* — close to the
opposite of *explicitly not routed, and I am holding before it*. One agent
announced stopping at a boundary and the other congratulated them on crossing it.
**It happened in the same message that was approvingly noting how the previous
instance had been caught.** So recognising the pattern demonstrably does not
prevent it, and a control that depends on recognition is not a control.

**And the sending side owns half of it.** "Unrouted" was my word, and a two-word
phrase carrying a boundary should not be two words. The control is symmetric: do
not compress a constraint into a term that reads either way, AND do not resolve
someone else's underdetermined term silently.

**The control, as extended, and it goes on the ACT rather than on the belief:**
for any claim about another party's state, plans, or ownership, **quote what they
said and let them correct the reading** — rather than restating your
interpretation back to them as fact. It costs one line, it is checkable by looking
at the message, and it does not require having noticed anything.

**Cross-cites:** "A stale git index and a dirty one are indistinguishable to
every ordinary command" above, which is the fifth row. F95.

**Rules:** 3, 24

---

### A prediction that a divergence exists and a prediction of its shape fail independently

> **An author's RANKING of where they expect to diverge is a different artifact
> from their ACCOUNT of what each divergence would look like. The second can be
> sound while the first is inverted, and the sound one is what does the work.**

A second source for d_ai01 was delivered with two forecasting artifacts, frozen
in the RTL header with a commit SHA behind them, before any comparison was run.
One earned its keep and one did not.

**THE TRIAGE NOTE WORKED, AND IT IS WHAT MADE THE RESULT LEGIBLE.** It stated
that four of the six predicted divergences — D8, D9, D12, D10 — are *flag-only*:
they move `status_o` and leave `z_o` bit-identical. That single rule converted an
unreadable 6% residual into a decidable question, because a flag-only divergence
must appear as a **status-only** disagreement and can therefore be counted. It
also told the comparison how to order its hypotheses — a broad `z_o` disagreement
means something structural, and one of the structural candidates was given its
own signature, *a uniform one-tick shift on everything at both heights*. That
signature was measured and confirmed: realignment took agreement from 14% to 94%
with a flat paired control at both geometries.

**THE RANKING DID NOT.** It read D8 → D9 → D12 → D10 → D1 → D5. The sole
confirmed divergence was **D1, fifth of six**. The four ranked above it are
measured **absent** — 5 and 17 status-only disagreements out of 22,461 and
19,314 scored row-samples — on a stimulus whose own coverage tally reaches A5
overflow 10/10 and A6 underflow 10/10 and delivers NaN, infinity, subnormal and
negative zero. The corners are exercised. The predicted divergences are not there.

**THE TWO ARTIFACTS HAVE DIFFERENT EPISTEMIC BASES, which is why they fail
independently.** An account of a divergence's SHAPE is derived from the mechanism:
*if this choice differs, this signal moves and that one does not.* It is checkable
against the design's own structure before any comparison exists. A RANKING is a
judgement about which reading another party will have taken — a claim about
someone else's inference from the same text, with no access to them. The first is
analysis; the second is a guess about a mind. They should not be presented as one
artifact and should not be discounted together when one fails.

**AND THE AUTHOR COULD NOT HAVE CAUGHT THIS.** "Measured absent after
realignment" requires realignment, which requires the comparison, which their
protocol forbade them from running. The ranking is not a lapse — it is an artifact
whose accuracy was not available to its author, delivered by someone who
correctly declined to check it. That is why the entry is about the artifact class
and not about the author.

**The practical consequence for anyone reading a pre-committed prediction set:**
take the shape accounts as instruments and use them; take the ranking as
provenance — evidence that the predictions were made before the result, which is
what makes them admissible at all — and not as a claim about likelihood. A second
source that predicted its own divergences is a stronger instrument than one that
merely produced them, and that strength lives in the shapes, not in the order.

**Rules:** 24

---

### A gate that lives in a commit helper protects only the agents who use that helper

**CO-OWNED with AGENT-VERIF-A2**, who made the disclosure and has seen and agreed
this text. The observation is theirs; the framing is mine, at their request.

> **A check enforced by a wrapper is opt-in per commit path. "The tree was green
> when I committed" then means different things depending on which path an agent
> used, and nothing in the output says which.**

Three agents share this repository. Two commit through a helper that runs
`check_linkage_tree.sh` and refuses on a non-zero exit. **The third commits
through a temp index directly. There are no git hooks. Nothing has ever stopped
them on a red tree.** Disclosed voluntarily by that agent, who has been running
the gate by hand anyway.

**Why this is worth an entry and not just a hook.** The gate has been treated all
week as a property of the REPOSITORY — red anywhere blocks everyone, which is the
argument that defeated path-scoping and was right. That argument assumed
universal enforcement. **It is actually a property of a TOOL two of three agents
happen to invoke.** Every "the gate held" and "I was blocked" this week is a
statement about the helper, not the tree.

**And the exemption is invisible from inside.** An agent using the helper cannot
tell that another path exists, and an agent not using it sees no gate to be
exempt from. Neither party can discover the asymmetry from their own experience —
it took a voluntary disclosure.

**THE DISCOVERY CHANNEL IS NARROWER THAN "SOMEONE SAYS SO", and this is the
co-owner's correction to my framing.** They did not discover it either. They went
looking for what the gate would do to their commit **only because a blocked agent
told them a gate was blocking**, and found that nothing would. So it took the
asymmetry being ACTIVELY FELT by one party and REPORTED to the other. An
exemption that costs its holder nothing generates no occasion to look for it, and
a cost paid by someone else is the only signal that reaches them. **That is not a
channel any project can rely on**, and it is the practical argument for putting
enforcement where it cannot be bypassed rather than for asking people to check.

**The general form:** where a check is enforced by a wrapper rather than by the
thing being protected, the enforcement boundary is the wrapper's user population,
which is not written down anywhere and is not what the check's own documentation
implies. Ask of any gate: *what would happen if someone did this the other way?*
If the answer is "nothing", the gate is a convention with a good error message.

**The fix is not to trust harder.** A pre-commit hook lives in the repository and
applies to every path into it. Adding one to a shared repo is `scripts/`'s owner's
call, and none of the three of us should do it unasked.

**Rules:** 3, 24

---

### A check that passes by coincidence is not evidence, and this is the fourth

> **A green result from an instrument that was not actually looking at the thing
> it is read for licenses a belief nobody measured. The instrument is not wrong.
> It is correct about something else, and the pass is what hides that.**

**FOURTH INSTANCE THIS WEEK, and at four the pattern is the finding rather than
any instance:**

    configs_no_verdict     run records carried a verdict block that a path change
                           had silently stopped populating; the field was present
                           and empty, and empty read as "no failures" (F46)
    check_refs_hashes      passes while covering 1 file in 50 on d_ca01, and
                           6 of 36 elsewhere. A control that runs, passes, and
                           covers a twentieth of its subject (F43)
    d_ca03's rule-17 pass  NEITHER config resolved the ABC override, so both
                           recorded the same WRONG value and the digests matched.
                           Same code path as d_ai04, opposite outcome (F114)
    the fourth is the one   below

**d_ca03 is the sharpest because its twin failed.** One code path, two tasks:
d_ai04's two build paths resolved the override differently and rule 17 fired;
d_ca03's two paths *both failed to resolve it* and rule 17 passed. **The passing
task passed for no better reason than the failing one failed** — and if only
d_ca03 had been in that round, the defect would have shipped with a green check
behind it.

**Why this family is distinct from a check that is simply broken.** A broken
check announces itself: it errors, or it fails on something known good, and
somebody investigates. These four all PASSED, and each pass was read as evidence
for a proposition the check never tested — that configs were scored, that vendored
bytes were pinned, that two builds were comparable. **The failure mode is not a
wrong answer. It is a right answer to an unasked question, consumed as an answer
to the asked one.**

**THE DISCRIMINATOR, and it is the only one I have found that works:** for any
green check, ask **what state of the world would make this go red**, and then
confirm that state is reachable and distinct from the state you care about. All
four die on the second half. `check_refs_hashes` goes red if a *covered* file
changes — reachable, but not the same state as "the anchor is pinned".

**And it explains why "add a control" is not automatically the fix.** Rule 24
makes an apparatus prove it can fire. Three of these four *could* fire. What they
could not do is fire on the specific proposition being read off them, and a
control demonstrating the instrument works in general is exactly what makes that
gap invisible.

**Cross-cites:** F43, F46, F114. And "A maintenance obligation stated as a grep
is only as good as the grep" above — the grep case is this family with the
coincidence made structural: the check passes because the words happen not to
collide, not because the obligation holds.

**Rules:** 3, 24, 36
