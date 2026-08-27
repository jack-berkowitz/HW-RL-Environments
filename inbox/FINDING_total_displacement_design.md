# Two clauses found by a method neither `--shared` nor the disclaimer convention can reach

**Not landed. d_dsp02 H1 is control work; d_dsp03 H2 is a declaration. Both
move hashes about to be solicited against.**

Method is AGENT-VERIF-A2's, from `b69c2b0`: cross-reference **unreportable**
clauses against **obligation vs latitude**, then ask of each obligation whether
it is covered somewhere else.

## Why the existing instruments cannot find these

    --shared finds ......... two clause ids in one message  -> a SHARED site
    this finds ............. a clause with NO site at all   -> TOTAL displacement

**An instrument that detects sharing cannot detect total displacement, because
total displacement leaves nothing behind to share.** And the disclaimer
convention cannot reach either, because neither clause carries a disclaimer —
there is nothing written to be stale.

## 1. d_dsp02 H1 — UNENFORCED. A violating submission passes.

    H1. `in_ready` MUST NOT depend combinationally on `in_valid`.

    H1 occurrences in d_dsp02's checker ......... 0
    sub-cycle delays in the whole testbench ..... 1, the #500_000_000 timeout

There is no in-cycle probe, so nothing can observe the combinational path. And
nothing else catches it either: a design with `in_ready = f(in_valid)` still
transfers exactly when both are high, so every data, latency and II=1 check
passes unchanged. **It is invisible to every check that looks at what was
delivered rather than when.**

This is the same clause, and the same gap, as d_nw01's H1 — closed at `9d80ae8`
with a mid-cycle probe on AW/AR/W plus a vacuity guard, and validated by
`nc_l_comb_ready`, which fails 0/16 naming H1. **The remedy already exists and
has a working control; it has not been carried across.**

d_dsp02's H1b is declared as reported under H3, which is correct and is about
STABILITY. The combinational-dependence half of H1 has no owner at all.

## 2. d_dsp03 H2 — COVERED COMPLETELY, DECLARED NOWHERE.

    H2. RESULTS COME OUT IN THE ORDER THE OPERATIONS WENT IN.

    H2 occurrences in d_dsp03's checker ......... 0

It is enforced. The result comparison walks the vector set in order against an
expected-value queue, so a reordered result is compared against the wrong
vector and fails as `vec %0d ... result %h expected %h`. A design that reorders
cannot pass. **The clause is fully absorbed into the data comparison and has no
site of its own.**

The spec says nothing about this, so from the outside H2 is indistinguishable
from an unenforced clause — which is the exact state the annotation pass
existed to remove, arriving in the one form the pass could not see: it looked
for clauses reported under ANOTHER ID, and H2 is reported under a message that
carries no id at all.

d_dsp02's H4 is the same mechanism and IS declared — *"CHECKED, BUT ITS FAILURE
NAMES NO CLAUSE... a message carrying no clause id at all"*. So the vocabulary
exists; H2 simply never got it.

## The design half's fifth state: A HARNESS GUARANTEE

Running the cross-reference turned up a category A2 predicted could not arise
on this half. Their six were obligations on the SUBMITTED TESTBENCH — *owed by
the other party*, unreportable by construction because the reference has no
verdict to render on someone else's harness.

The design half has the mirror image. Clauses that are **promises from the
harness to the submission**:

    d_ca04 R1  "THE TWO RESETS ARE ASSERTED SIMULTANEOUSLY ... You may rely
                on that."
    d_nw03 R6  "A FRAME IS AT MOST 8 BEATS. The harness never offers a
                longer one."
    d_nw03 R2  "`s_dest_i` is HELD CONSTANT for every beat of a frame"
    d_ca04 H2  "the producer holds it ... The checker honours this."
    d_nw01 H2  "a master ... holds the channel payload stable. The checker
                honours this."

Equally unreportable by construction — **the harness cannot fail its own
promise** — and equally neither confession nor latitude. Same structural
position as A2's six, opposite direction: on the verification half the
obligation flows outward to the submitted testbench, on the design half the
guarantee flows inward from the harness to the DUT.

A2's rule was *"on your half this state cannot arise, because the submission is
a DUT and every obligation is on it."* Correct about obligations, and it missed
that a contract also contains things the harness owes.

## Everything else resolved

    transport (T1..T4)     obligations on the submitted FILE, not behaviour
    definitions (A1, R2)   not obligations
    declared groupings     already carry REPORTED UNDER
    d_ca04 C6              "NOT A SEPARATE CHECK -- IT IS THE CONDITION THE
                           OTHERS RUN UNDER ... Stated so C6 is not read as
                           unchecked." Declared, and a sixth state
    d_ca04 R3              warm reset, out of scope
    d_ca01 C4              known, held for a clause decision
