# Build prompt — VERIFICATION tasks

The instructions for building one verification task. Sequential, one agent, one
task at a time.

A verification task is the inverse of a design task: **the DUT is shipped and the
model writes the testbench.** What we build here is the grading apparatus — a
golden DUT, a mutant set, and the scoring rules that decide whether a submitted
testbench is any good.

Pick the task from `TASK_CATALOG.md`. Read `CONVENTIONS.md` and `FINDINGS.md`
first.

---

## THE STANDING RULES

Identical to the design side, and they apply to the *grading apparatus* here
rather than to a DUT.

1. **Every capability the design must support is a named parameter with a
   binding check.** Audit by probe, not by reading: write a correct
   implementation that ignores exactly one parameter and confirm the checker
   fails it.
2. **Every stated requirement has a coverage floor proving it was exercised.**
3. **Every check gets a negative control that fails THAT check and nothing
   else**, and only counts if the harness can saturate what the check measures.
4. **Coverage floors measure STIMULUS, not design behaviour.** If a correct
   implementation could score zero on a floor, the floor is gating a design
   choice and must become a METRIC.
5. **Second source is mandatory** -- an independent implementation making
   different free choices. Name three specific differences or it is a paraphrase.
   **When it fails, disambiguate before changing anything** -- see below.
6. **No metric may be quoted from a run that failed its own gate.**
7. **Closure status comes from `find_fmax`'s classification**, never a log grep.
8. **Every run writes an immutable record; collection reads only those records**,
   never a live tool directory.
9. **Area and power are reported at own Fmax and at a common binding period**,
   and area comparisons split three ways: off-spec configuration, capability
   gap, genuine optimisation.
10. **When blocked, the deliverable is the report.** Stop and say so.
11. **The oracle must be an artefact nobody on this project wrote. Locally
    authored code generates INPUTS, never expected values.** A local model
    producing expected values and merely cross-checked against the anchor leaves
    a shared misconception surviving the cross-check -- both sides agreeing for
    the same wrong reason. Invert it: generate inputs locally, run them through
    the anchor, take the ANCHOR'S output as expected. A local bug then costs
    coverage and can never produce a wrong expected value.

**Nothing you write is trusted until it has been run.**

---

## Why verification tasks require a Class A anchor

A design task's oracle decides whether *RTL* is correct, and a Python model
derived from a published algorithm can do that.

A verification task's oracle must decide whether a *testbench* is adequate,
which requires knowing that the testbench passes correct RTL and fails incorrect
RTL. **A locally-written model cannot supply the first half** — the RTL it would
validate against is RTL this project wrote against the same understanding, so a
shared misreading of the specification is invisible.

**A verification task with no external RTL anchor is not a weaker task; it is
not a task.** If the anchor falls through, cut it.

---

## Order of work

Stop and report after each numbered step.

### 1. Anchor, licence, decontamination

Confirm the anchor exists at its pinned SHA, elaborates, carries the licence
claimed, and does what the catalog says.

Verification ships the DUT, so it ships **decontaminated**: strip comments that
name the upstream project or explain the algorithm, rename aggressively, remove
anything that would let a model recognise the source and recall its testbench
rather than write one.

**Design and verification anchors are disjoint at module level.** If the module
you are about to ship is some design task's hidden reference, a model working
both is handed the answer. Shared repository is fine; shared module is not.
Check before writing anything.

### 2. The DUT bundle and its specification

Ship the DUT whole — a fat multi-file DUT under one top-level spec is normal
here and is the preferred fallback when a design task's shim fails.

The specification must state the contract completely enough that a testbench
author can decide what to check without reading the RTL. Every requirement needs
a condition a test can create (rule 2).

### 3. The mutant set — the core deliverable

This is what actually grades a submitted testbench: **a good testbench kills
mutants, a bad one does not.**

5–7 mutants, one defect each, spanning the classes:

- **liveness** — deadlock, and starvation that does not also read as deadlock
- **ordering** — violates local order while global order still looks right
- **boundary** — off-by-one at full, empty, wrap
- **capability** — correct on every transaction, carries a fraction of the
  required capacity

**Non-equivalence bar.** Every mutant must be confirmed to actually differ from
the golden DUT — a mutant equivalent to the golden is unkillable, and a
submission is penalised for not killing something that cannot be killed.

**The bar is a simulation counterexample: a concrete input sequence on which
golden and mutant differ.** That is a direct proof of non-equivalence and it is
all that is needed. Formal equivalence checking is **not** mandated per mutant —
it was tried, it does not converge on the larger DUTs, and requiring it stalls
the task for no extra confidence. If a mutant resists a counterexample after
honest effort, **withdraw it and write a different one**; do not ship a mutant
you cannot demonstrate is killable.

*A mutant that survives correctly is a real outcome.* One forcing a synchroniser
depth was withdrawn because the change is not simulation-observable at all —
that is a fact about the property, not a failure of effort. Record it and
replace the mutant.

### 4. The golden testbench

Written here, never shipped, and used to establish that the mutants are killable
and the golden DUT is clean.

Same constraints as the design side: no global-order checks where the spec wants
local order, no cross-domain assertions, no requiring one particular arbitration.

### 5. Scoring

A submitted testbench is scored on:

- **passes the golden DUT** — a testbench that fails correct RTL is worthless
- **kills the mutants** — the discriminating measure, reported per mutant
- **coverage floors reached** — hazards actually exercised rather than nominally
  present

Report per-mutant results, not just a total. *Which* mutant survived is the
informative part.

**Diff rate is NOT a quality signal, in either direction.** It was proposed as a
band -- high means filler, low means unkillable -- and that was **tested and
retracted**: the most valuable mutant in the project scored 100 %, and a
comfortably killable one scored 0 % because the harness stimulus could not reach
it. See `FINDINGS.md`.

What it is: **a witness that non-equivalence was demonstrated under a given
stimulus.** A zero means *this stimulus did not distinguish them*, never that the
designs are equivalent. Report it as `non_equivalence_demonstrated` with a
witness case, not as a rate that reads like a score.

**Mutant quality has no prior and no proxy should be built for it.** It is a
posterior: a mutant every submission kills is filler, one nobody kills is too
hard, and neither is knowable before submissions exist. Defer it to the
cross-model run.

### 6. NOTES.md

Oracle class, decontamination performed, every mutant with its defect class and
its counterexample, every mutant withdrawn and why, and the golden testbench's
own coverage.

**Record what you did not do.** Do not describe a weaker guarantee in language
that implies a stronger one.
