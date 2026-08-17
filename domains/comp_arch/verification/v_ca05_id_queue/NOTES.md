# v_ca05 `tag_tracker` — build notes

Oracle class **A**: the golden DUT derives from vendored PULP `id_queue`, so the
scoring rests on RTL nobody here wrote.

## What this task ships

**A port map and a pinned specification. No RTL.** Under the decision in
`TASK_CATALOG.md`, that removes decontamination, licence retention in a shipped
derivative, and recognition exposure together rather than mitigating them.

`dut/` holds a decontaminated copy because it predates that decision and is what
the scoring harness runs. It is never given to a submission.

## The measured result that made the decision

A model wrote a testbench from the port map and prose alone and **passed the
golden DUT and all four conformant perturbations**. Two of the three failure
buckets came back empty: no driver defect, no reliance on unspecified behaviour.

Only a model could produce that evidence. Every author here had read the RTL
while decontaminating it, so a locally written testbench pre-empts exactly the
gaps the exercise counts — see `FINDINGS.md`.

## Three artefact sets, and their signs differ

| set | relation to spec | required outcome | a failure means |
|---|---|---|---|
| `dut/` golden | satisfies it | **accepted** | the testbench rejects correct hardware |
| `conformant/` ×4 | satisfies it | **accepted** | the **spec** is incomplete |
| `mutants/` ×6 | violates it | **caught** | the **testbench** is weak |

Confusing the middle row with the last inverts the result, which is why they sit
in separate directories with the sign stated in each README.

## Scoring notes that are easy to get wrong

- **A hang is not a catch.** A submission with no watchdog runs forever against
  the starvation mutant. It did not detect the fault; it stopped, and a
  correct-but-slow design hangs it identically. Reported as its own verdict.
- **A catch from a submission that failed the golden carries no information** —
  a testbench rejecting everything appears to catch everything (rule 16).
- **Per mutant, never a rate.** One submission scored 2 caught, 3 hung, 1 missed:
  four different problems that a single percentage hides.

## The mutant set caught us first

On first use it found **two holes in our own reference testbench** — it never
pushed to tag 0 in a way that exposes starvation, and never searched with a mask
covering the top byte. Both fixed; it now catches 6/6, and the corrected version
still accepts all four conformant perturbations. That second check is not a
formality: adding checks is exactly when a testbench starts depending on things
the spec never promised.

## What is missing, stated rather than left to be discovered

**There is no second DUT, and nothing in the harness gates on its absence.**

A verification task's second DUT is the analogue of a design task's second
source: an independent correct implementation the submission must *also* accept.
Without it, "passes the golden" cannot separate a testbench that checks the
contract from one fitted to this implementation's incidental behaviour.

The conformant perturbations cover part of that ground — they vary what the spec
leaves open — but they are perturbations **of** the golden, not an independent
design, so a shared misconception between the golden and the checks is invisible
to them. Recorded in `task.yaml` under `second_dut: status: ABSENT`.

## Open measurement question

The reference's minimum crossing latency is flat across `SYNC_STAGES` while two
submissions scale with it. That may mean the reference's fastest path does not
traverse the full synchroniser chain, in which case the three numbers are not
like-for-like. Unresolved, and flagged in the results table rather than quietly
compared.
