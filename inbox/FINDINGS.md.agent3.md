
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
