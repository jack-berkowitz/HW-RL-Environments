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

## THE TOKENS MEAN OPPOSITE THINGS ACROSS THE TWO HALVES

Found by AGENT-VERIF-A2 while applying this convention, and it is a gap in the
convention rather than in their specs.

    design half        "NOT CHECKED"          our checker is silent here
                                              -> a CONFESSION about the harness

    verification half  "shall not be checked" your testbench must not check it
                                              -> a REQUIREMENT on the submission

On a verification task **the submission IS a testbench**, so the sentence is an
instruction and obeying it is scored: checking a rule-12 latitude is precisely
how a testbench rejects correct hardware, which is what rule 24 exists for.

Verified independently: 5 instruction-form uses across v_ca03, v_ca05 and
v_nw03, and **0** in any design spec. So a gate keyed on the token list reads
five requirements as five confessions -- true sentences, wrong category, and
the error direction is over-reporting on the half that has none of the thing
being counted. That is the failure the convention exists to remove, arriving
from the other side.

**The sharp case is v_ca05 R3, and it is why this is not cosmetic.** R3 is
*genuinely* emittable-zero: `fail("R3")` appears 0 times and
`check_clause_emittable` lists it unreportable. A gate flagging it would be
RIGHT BY ACCIDENT. The reason R3 is unchecked is not that the reference fell
short -- it is that checking it is FORBIDDEN. **A count cannot tell a
confession from a prohibition**, and the count is exactly what this convention
makes exact. Separating the vocabulary is what makes the number mean one thing.

## The three forms

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

**LATITUDE / INSTRUCTION.** The contract does not constrain this at all. The
leading vocabulary differs by half, because the consequence differs:

    design        (submission is a DUT)        PIPELINE DEPTH IS FREE.
    verification  (submission is a testbench)  NOT SPECIFIED -- A TESTBENCH THAT
                                               CHECKS THIS REJECTS CORRECT HARDWARE.

AGENT-VERIF-A2's wording, adopted as proposed. It states the consequence, which
the old phrasing left the submitter to infer, and it leaves the reserved tokens
to confessions alone in BOTH halves rather than exact-on-one-half.

**GROUPING is none of the three.** "R5. REPORTED UNDER R3." is complete as
written; adding "not checked by a counter of its own" imports the vocabulary for
no gain.

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
    v_ca05 R10   partial in whole-clause vocabulary             LANDED, 5d98536
    6 design     partials in whole-clause vocabulary            proposed text filed
    5 verif      latitude in confession vocabulary              proposed, not landed
                 v_ca03 B2, v_ca05 R3 + latitude, v_nw03 x2

The design partials and the five instruction-form sentences are not landed.
v_ca03 and v_ca05 are already on the re-solicitation list; v_nw03 is not and
would be added -- one task's hash for two sentences, which is the whole cost of
closing the half-exactness gap.

## A note on why both halves wrapped

AGENT-DESIGN-43a92055's design sweep missed six wrapped instances behind `//`
continuations; AGENT-VERIF-A2's R10 wrapped behind a markdown line break. Same
cause: **prose wraps wherever the column runs out, which is unrelated to where
the meaning breaks.** A line is not a unit of meaning in either format, and a
scanner that treats it as one under-reports in both.
