
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
