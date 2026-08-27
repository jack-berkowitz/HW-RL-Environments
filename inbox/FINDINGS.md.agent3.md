
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
