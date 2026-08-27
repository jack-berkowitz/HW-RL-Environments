# PROPOSED — a mechanical check for record drift. NOT BUILT. `scripts/` is Agent 1's.

Shape only, as asked. Written after running two of the four parts by hand on
d_ca01, so the coverage claims below are measured on one task rather than
estimated.

**The premise, measured on three tasks:** a working record decays toward
UNDERSTATING what exists (F98-F106 family; d_ai01 ×2, d_ca01 ×10). Twenty-plus
instances, not one overstating. That is an argument for a check, not for writing
more carefully — the author who makes a claim stale is the author who finished
the thing, and they are the least likely person to return to where it was last
called unfinished.

---

## The question this has to answer

A `PROPOSED` heading is checkable against `FINDINGS.md` by identifier. A sentence
reading *"there is no formal non-equivalence result for these mutants"* is not —
**unless something links the claim to the artefact that would refute it.**

That is the whole answer, and it splits the problem correctly. The useful axis is
not *status* versus *content*. It is **BOUND versus UNBOUND**. A claim is
mechanically checkable exactly when it names the thing that would refute it.
Everything below is either a way of finding claims that are already bound, or a
way of making the residue bind itself.

---

## PART 1 — EXISTENCE. Run on d_ca01; cheap.

Every path cited in a record, tested for existence.

    37 cited, 2 absent — one a deleted script still described in the present
    tense by filename, one a genuine manifest defect (F43)

Catches: an artefact removed and still described. One of ten on d_ca01.

## PART 2 — STATUS TOKEN vs AUTHORITY. Run on d_ca01; cheap.

Every `PROPOSED`, `NOT LANDED`, `NOT STARTED`, `not built`, `not started` within
N lines of an identifier, resolved against that identifier's authority:

    heading slug   -> FINDINGS.md by title
    rule number    -> RULES.md
    task name      -> runs/<task>/ non-empty
    artefact path  -> the file

Catches: landed-but-still-proposed. **Six of ten on d_ca01** — five PROPOSED
headings that had landed as F43/F44/F45/F47/F48, and a NOT-LANDED heading over a
rule that is in `RULES.md`. Also the PPA row, which is a status token against a
directory.

## PART 3 — THE IDENTIFIER DISPOSITION INDEX. Not built. This is the new part.

**No new authoring syntax, and it reaches the content cases.** Build an index of
every identifier the project already uses — `D3`, `L4`, `C2`, `m06`, `c03`,
`F45`, `Rule 21`, `mCAP1` — across *all* files, with every line mentioning it and
every disposition word near that line: REFUTED, DEAD, WITHDRAWN, RETIRED,
SUPERSEDED, LANDED, NOT CONFORMANT, PROMOTED, NARROWED, CLOSED.

Report an identifier when its dispositions disagree, or when a live-sounding
mention sits in a file where the disposition is absent and another file has one.

**This is what would have caught the two hardest of the ten:**

  * `D3′` was proposed as a live second-source difference. Its disposition —
    *"Second-source difference D3' is dead with it"* — is in `task.yaml`, a
    different file. Cross-file index catches it; reading one file does not.
  * *"there is no formal non-equivalence result for these mutants"* sits under a
    heading about `eqy`, seventy lines below the section that obtained one. It
    does not name an identifier — **but the sentence it caveats does**: the
    mutant names, each of which carries `evidence: bmc_cex` in `task.yaml`. The
    index binds through the neighbours.

**Why this is the right shape rather than a natural-language check.** It uses
identifiers the project already maintains for other reasons, it needs no author
to annotate anything, and its false-positive mode is a list of identifiers to
look at rather than a verdict. It is an INDEX, and the reading is still a human's.

## PART 4 — BOUND NEGATIVES. Needs authoring discipline, and only for the residue.

Part 3 reaches claims that mention an identifier. It does not reach a bare
negative about the tree — *"nothing has ever"*, *"no task has"*, *"none of them
is in X"*. Those are the ones that read as strongest and age worst.

**The proposal: a negative claim about the tree is admissible only with its
binding inline.**

    <!-- claim: none | grep -lc 'evidence: bmc_cex' domains/*/design/*/task.yaml
         | expect 0 | measured 2026-08-19 -->

One comment, next to the sentence. The checker re-runs every binding and reports
those whose value moved, with the measurement date.

**The reason this is affordable is a timing argument and it is the crux.** The
expensive part is not running the check, it is AUTHORING the binding — and the
one moment the binding is free is the moment the claim is first made, because the
author has just run that command to justify it. Asked for at any later time it
costs a full re-derivation, which is why "add citations afterwards" never happens.

**I have a live instance of exactly this, from today, and it is why I am proposing
Part 4 rather than stopping at Part 3.** I reported *"Still none of the twelve is
in FINDINGS.md"* at 15:47. My measurement was taken before 15:37, when Agent 1
landed nine of them as F98-F106. The claim was stale by ten minutes, I restated
it without re-measuring, **and I did so one minute after committing the finding
about restating stale measurements as live.** Direction: understated, like all
the others. Part 3 would not have caught it — the sentence names no identifier.
A binding would have, because re-running `grep` was a second's work and the whole
defect was that I did not.

---

## DIRECTION IS PART OF THE REPORT, not a footnote

Every drift is reported with its direction. If the finding holds, nearly all
drift understates — so an OVERSTATEMENT hit is rare and should be read as a much
stronger signal: likely a real error rather than decay. A checker that reports
direction separates *the record is behind* from *the record is wrong*, and those
deserve different responses.

---

## WHAT NONE OF THE FOUR CATCHES, stated so the coverage claim is not read as total

A claim that is stale in its content, mentions no identifier, is not a negative,
carries no binding, and is contradicted only by prose elsewhere. Nothing
mechanical reaches that; it comes out by reading, and reading is scoped to
whatever question brought the reader.

**And the count above is itself a containment claim.** Ten sites on d_ca01, four
of which came out by reading along four named items, in a 1300-line file. Parts 1
and 2 were run; Parts 3 and 4 are assessed against those ten and not measured.
The honest figure is: **of the ten, Parts 1+2 caught seven, Part 3 would reach
two more, Part 4 reaches the residue and my own instance above.** One task.
