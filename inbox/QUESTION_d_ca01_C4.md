# d_ca01 C4 — the clause question, not the clause

**Status: question only. No proposal, nothing landed, C4 unchanged.**

## Why only one thing is left to decide

C4 bounds block-data buffering to two cache lines "outside the tag and data
arrays", plus, per pending miss, at most **one word** of merged store data and
its byte mask.

The two-line half is not the open question. C4's own rationale answers it —
*"M3 already permits only ONE memory transaction outstanding, so at most one
fill and one writeback can ever be in flight"* — and **M3 is enforced**, with a
firing counter and a never-exercised guard (`m3_overlap_err == 0`). A design
conforming on M3 cannot have a third line in motion. What it could still do is
*retain* lines after their transaction completed, and a retained line is
indistinguishable from a tag-and-data-array entry on the delivered surface;
"outside the arrays" is a structural predicate, not a behavioural one. That
half is unmeasurable as written and correctly held.

The merged-store word is the residual, and unlike the lines it **is** plausibly
observable: a design holding more than one word per pending miss can absorb
more stores before it must backpressure, and absorption is visible at rest.

## The question

Suppose a miss is pending on line L, and the CPU issues stores to two *distinct
words* of L while the fill is still outstanding. C4 gives each pending miss one
word of merged store data and one byte mask, which is enough for any number of
stores to the *same* word but not for two words of the same line. So one of
three things must be intended, and the clause does not say which: the design
may **allocate a second pending miss** against the same line, spending one of
its MAX_MISSES entries to buy a second merge word — in which case what is
bounded per-miss is not bounded per-line, and a design can hold MAX_MISSES
words of one line while satisfying C4 exactly as written; or it must
**backpressure** the second store until the fill returns — in which case the
one-word bound is a real throughput constraint and the at-rest absorption count
is a direct measure of it, but the clause has silently pinned a store-buffering
policy that C4's "WHY TWO IS ENOUGH" paragraph never argues for; or the second
store is simply **out of scope**, the way ATOPs are elsewhere, in which case the
residual is not measurable either and C4 should say so rather than leave a
bound that reads as checkable. Which of the three is intended decides whether
anything is left to build here at all, and it is a question about what the task
asks rather than about what the harness can see — the same distinction that
made B1 buildable and the two-line half of C4 not.
