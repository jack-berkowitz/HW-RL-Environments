# Non-enforcement disclaimers: the checkable form

Settled between AGENT-DESIGN-43a92055, AGENT-PPA-2381f2fe and AGENT-VERIF-A2.
**Proposed. Not landed anywhere — every instance moves a hash.**

## Why a convention rather than a checker

A gate that flags "clause disclaimed but emittable" was measured twice:

    AGENT-PPA-2381f2fe, verification+design   7 flagged, 7 consistent
    AGENT-DESIGN-43a92055, 11 design tasks    41 sites, 2 stale

Roughly half the flags are wrong, and always the same way: **a disclaimer about
one PART of a clause, written in whole-clause vocabulary.** d_ca01's R3 says
"`rsp_data_o` ... is not checked" about STORE responses only. d_nw01's pipeline
note says "NOT CONSTRAINED AND NOT CHECKED" about DELAY, not capacity. v_ca05's
R10 says "shall not be checked" about one output field of a checked clause.
All three are true; all three flag.

A gate at that rate trains people to skip it, and the first real stale claim
arrives looking like the six before it. So the fix is upstream: **make the
whole-clause form countable, and keep partials out of its vocabulary.**

## The two forms

**WHOLE-CLAUSE.** The clause is observed by nothing. First sentence states the
id and the count and nothing else:

    `C4` appears ZERO times in tb/.

Every qualification goes in following sentences that claim nothing countable —
why it cannot be checked, what would be needed, what a violating design looks
like. A checker verifies the first sentence arithmetically. It never parses the
rest, and should not try.

**PARTIAL.** Some named sub-property of a checked clause is unobserved. It must
NOT use whole-clause vocabulary. Lead with the scope, as a positive statement
of what is free:

    STORE RESPONSE DATA IS FREE.        not  "`rsp_data_o` ... is not checked"
    REPLACEMENT CHOICE IS FREE.         not  "which of the 17 is not checked"
    PIPELINE DEPTH IS FREE.             not  "NOT CONSTRAINED AND NOT CHECKED"
    REORDERING IS A DUT CHOICE.         not  "gates nothing"

The reserved tokens — NOT CHECKED, appears ZERO times, shall not be checked,
no enforcement — then appear only in whole-clause disclaimers, which is what
makes the gate exact rather than heuristic.

Grouping is neither form. "R5. REPORTED UNDER R3." is complete as written;
adding "not checked by a counter of its own" imports the vocabulary for no gain.

## The scanner must see SENTENCES, not lines

AGENT-VERIF-A2 measured the same corpus three ways:

    line-based scan .......  4 hits    missed sentences that WRAP
    paragraph-based scan ..  1 hit     missed lists split from their intro
    normalised per block ... 12 hits   11 whole-scope, 1 partial

**Disclaimer sentences wrap**, and in a comment block every wrap is a `//`
boundary. AGENT-DESIGN-43a92055's design-half sweep was line-based and missed
six wrapped instances, two of them genuine disclaimer vocabulary:

    d_ca01:235  "...is permitted but wasteful and is not\n//  checked either way"
    d_ca04:290  "...reported as a metric and never\n//  gated"

Both verified TRUE, so the verdict did not change — **but that was luck, not
method.** Any checker built on this convention must join comment runs, strip
markers, and split on sentence boundaries before matching. A line-based
implementation will silently under-report, which is the failure direction that
looks like success.

## Do not make claims about another task's checker

Two design specs cited a third task's clauses as the example of "no check at
all". Checks were written for all four, and both sentences went false in files
nobody was editing.

This is the citation family with an **ownership** axis rather than a tense one
(AGENT-VERIF-A2's framing): not "a checker I did not read", not "a checker that
does not exist yet", but **a checker somebody else can change without telling
me.** The remedy is different from the others — not run it, not defer it, but
DO NOT MAKE THE CLAIM. State the general point self-containedly; it almost
never needed the other task's name.

Same-task disclaimers are safe in a way cross-task ones are not: a same-task
disclaimer is written by whoever touches the checker, and a cross-task one is
falsified by someone who will never open the file.

Historical references are fine — recorded traps, superseded drafts, measured
numbers, all attributed as observations. **A record of what happened does not
stop being true when something changes.**

## Instances

    d_ca01 C4    whole-clause, verified TRUE at 0 occurrences   already conforms
    v_ca05 R10   partial in whole-clause vocabulary             one reworded sentence
    6 design     partials in whole-clause vocabulary            proposed text filed

None landed. v_ca05 and the design partials bundle into hash moves already on
the re-solicitation list.
