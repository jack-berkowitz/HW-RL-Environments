# Two instruments blind for structural reasons, not oversight

## The gap

AGENT-VERIF-A2's line, which is the finding:

> **An instrument that detects sharing cannot detect total displacement,
> because total displacement leaves nothing behind to share.**

`--shared` looks for several clause ids in one failure message. That finds a
clause whose check it SHARES with another clause. It cannot find a clause with
**no site at all**, absorbed entirely into a check that names something else or
names nothing — because there is no message to carry two ids.

    the enumerator finds ...... two clauses, one verdict
    this finds ................ one clause, zero verdicts, absorbed entirely

And the second half, which completes it:

> **The disclaimer convention cannot reach it either, because no disclaimer was
> written and nothing went stale.**

The convention polices sentences that CLAIM something about enforcement. A
totally displaced clause makes no claim — it says what the design must do and
stops. There is no text to be stale, so a staleness check has nothing to bite
on.

**Two instruments, blind to the same clause, for structurally different reasons
in each case.** Neither is a bug. `--shared` measures exactly what it says;
the convention polices exactly what it says. The gap is that between them they
were read as covering the question *"which clauses are unenforced"*, and they
cover *"which clauses share a site"* and *"which enforcement claims are false"*.

The route in is neither: cross-reference **unreportable** against **obligation
vs latitude**, then ask of each obligation whether something else covers it.

## What it found on the design half

    d_dsp02 H1   UNENFORCED. Probe built and controlled, 8cea3ba
    d_dsp03 H2   enforced, no site, undeclared. Declared, 8cea3ba
    d_ca05 F4-F7 enforced, reported under T5/T7, undeclared grouping. NOT landed

## The population, swept across all eleven

178 stated clauses have zero mention in their checker. By family:

    G  48   GRADING (G1-G5). How a submission is judged. Never a DUT obligation
    A  36   DEFINITIONS. "an enabled tick is...", "a FRAME is...". Not obligations
    T  35   TRANSPORT. Obligations on the submitted FILE, policed by
            check_transport.py, not by any testbench
    L  18   LATITUDE, rule 12
    P  12   PPA axes, measured by the synthesis flow

149 of 178 are structurally unreportable by family. Of the remaining 29:

    declared groupings ....... R1b, R2, R3, H1b -- already carry REPORTED UNDER
    harness guarantees ....... 5, see below
    conditions ............... d_ca04 C6, "the condition the others run under"
    out of scope ............. d_ca04 R3 warm reset, d_ca01 C4 held
    definitions/scoring ...... S0, V1, V3, F2, F3, C4(d_ca03)
    resolved this pass ....... d_dsp02 H1, d_dsp03 H2
    UNDECLARED GROUPING ...... d_ca05 F4-F7

## THE SWEEP'S ERROR DIRECTION IS UNDER-REPORTING, and it took four attempts

Stated plainly because a population number invites being trusted:

    1  scanned lines, not sentences .......... AGENT-VERIF-A2 found it; wrapped
                                               disclaimers were invisible
    2  read one testbench per task ........... d_nw01 has TWO; H2 lives in the
                                               second, in a comment
    3  read only tb/*_tb.sv .................. d_ca03 splits its harness across
                                               .svh includes. Its zero-count
                                               fell from 25 to 17 when included
    4  assumed a helper signature ............ grepped `note_fail|chk(`. d_ca05
                                               uses `fail(string)` and
                                               `expect_eq(tag,...)`, so it read
                                               as ZERO check sites when it has 60

**The fourth is the one I had warned a peer about.** The signature finding --
that clause attribution depends on whether the id is a required argument -- was
mine, sent to AGENT-PPA-2381f2fe, and I then wrote a scan that assumed one
signature. Documenting a defect does not confer immunity to it; this is the
fifth instance this week across three agents.

And the residual limitation, which no attempt fixed: **occurrence is not a
check.** The scan counts an id appearing anywhere, including in a comment. So a
clause whose only mention is a comment does NOT appear in this population and
may still be unenforced. d_nw01 H2 is exactly that shape.

**The population is a lower bound on unenforced clauses, not a measurement of
them.** d_dsp02 H1 surfaced because it had zero mentions; a clause mentioned
once in a comment would not have.

## RETRACTED: "a task no instrument here can assess"

**This section claimed d_ai01 was outside the reach of every instrument. It is
false and it is retracted.** Kept rather than deleted because how it was
produced is the point.

    claimed   43 $display sites, no fail helper, therefore unassessable
    actual    5 TEST_RESULT: FAIL sites. 43 was every $display in the file,
              most of them METRIC and coverage output, not failure reports.

    claimed   check_clause_emittable cannot assess it
    actual    it does, and had already: 35 stated, 11 emittable, printed in
              the same table I was reading when I wrote the claim

Two of d_ai01's five failure sites name their clause -- `TEST_RESULT: FAIL: L3
latency floor` and `TEST_RESULT: FAIL: V2 -- reset did not clear the array` --
which is exactly what d_ai01's own spec already says about itself: *"TWO CLAUSES
IN THIS TASK DO NAME THEMSELVES."*

**HOW IT HAPPENED.** I grepped for a fail-helper DEFINITION, found none, and
concluded the instruments could not read the task. The instrument does not need
a helper; it reads failure message strings however they are emitted. I had the
tool's own output for d_ai01 on screen and drew the conclusion from a cruder
observation instead.

That is the defect this file is about, committed inside this file: **a count of
a vocabulary is a measurement of the vocabulary, not of the thing the vocabulary
is usually used for.** `$display` count is not failure-site count is not
attribution.

**WHAT SURVIVES.** d_ai01 has no fail helper, so of five failure sites two name
a clause and three do not. That is the ANONYMOUS state, already annotated on
this task, and it is a much smaller claim than the one retracted.

**WHAT DOES NOT.** There is no task outside the reach of every instrument. That
was the headline AGENT-VERIF-A2 was told to elevate above the H1 fix, and it was
wrong when I wrote it.
