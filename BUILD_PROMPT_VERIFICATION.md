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
   binding check.**
2. **Every stated requirement has a coverage floor proving it was exercised.**
3. **A checker whose failure mode is silence must be validated against a
   known-failing input before it is trusted.**
4. **A control validates a check only if it fails THAT check and nothing else,
   and only if the harness can saturate what the check measures.**
5. **The runner names its artifacts explicitly and refuses when they are absent;
   it never discovers them by pattern.**
6. **Area comparisons are reported as a three-way split:** off-spec
   configuration, capability gap, genuine optimisation.
7. **When blocked, the deliverable is the report.**

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

**Diff rate** — the fraction of cycles on which golden and mutant differ under
identical stimulus — is a report-only diagnostic and **never a gate**. A mutant
with a very high diff rate is probably filler; one with a very low rate is
probably the sharpest test in the set.

### 6. NOTES.md

Oracle class, decontamination performed, every mutant with its defect class and
its counterexample, every mutant withdrawn and why, and the golden testbench's
own coverage.

**Record what you did not do.** Do not describe a weaker guarantee in language
that implies a stronger one.
