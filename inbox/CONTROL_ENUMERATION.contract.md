# Control enumeration — a contract, for reconciliation across both territories

**Status: PROPOSAL. Nothing wired.** Written by AGENT-VERIF-A2 for
AGENT-DESIGN-43a92055 to reconcile against the design side, at Jack's direction,
because this is one problem across two territories and should be one fix.

## The problem, stated as counts

| | verification | design |
| --- | --- | --- |
| controls held | 21, across 6 tasks | 24 |
| exercised by a runner | 5, in 1 task | 0 |
| appearances of the control directory in `scripts/` | 1, and it is a comment | — |

Every one of those controls **works**. Run it by hand and it does what its record
says. What is missing is the path, and a path is invisible in every file you
would think to open. The verdicts sit in `task.yaml` — *"PASS — caught"*,
*"26 failures, every one A4"* — recorded as measurements, and nothing will notice
when they stop being true.

This is the shape of `v_ai02`'s `task.yaml` asserting 22 of 22 while its own
`RULE24.md` read *"(not yet run for this task)"*: a claim whose instrument was
never wired.

## What a control is, for this contract

A **control** is an implementation, testbench, or wrapper kept by a task whose
purpose is to establish that the apparatus *discriminates* — not to be scored.
Three kinds, and they need different assertions:

| kind | what it is | the runner asserts |
| --- | --- | --- |
| **negative** | violates something; must be caught | fails, **and on which clause** |
| **positive** | conforms; must survive | passes, no clause failure |
| **suppressing** | conforms *and* empties a clause's antecedent | passes, **and the antecedent count is zero** |

The third is new and is why an enumeration contract is worth agreeing rather than
each side inventing one: a suppressing control that passes proves nothing unless
the zero is also recorded. A control that passes without suppressing is a control
whose two arms produce the same observable.

## Discovery — declared, not globbed

A runner **must not** discover controls by globbing a directory. Two reasons,
both already paid for in this repo:

- A glob grades whatever it finds, including a file left behind by an earlier
  naming. On `v_ca07` that turned a reported 22 of 22 into a real 21 of 22.
- A glob cannot distinguish *"no controls"* from *"the directory moved"*, and
  those must not report the same. `sim_candidate.sh` refuses `controls/` today
  because its exemption is a literal directory list, which is the same defect
  from the other end.

So: **each task declares its controls in `task.yaml`**, and the runner reads the
declaration. The directory is where they live; the declaration is what they are.

    controls:
      - file: negctl/stuck_high_dut.sv
        kind: negative
        expect: fail
        clause: any                 # or a specific id, asserted by name
        note: every output tied to '1 -- the floor
      - file: negctl/h3_violating_perturbations.sv
        module: h3_nc1_throttle_hits_same_value
        kind: negative
        expect: fail
        clause: H3                  # and NOTHING else -- see below
        exclusive: true
      - file: negctl/g2h4_instant_resume_dut.sv
        kind: suppressing
        expect: pass
        antecedent_counter: cov_defer_condition
        expect_count: 0

`module:` is optional and names one module inside a multi-module file.

## What the runner asserts, per kind

1. **The control builds.** A build failure is a result and is recorded, never
   skipped. A control that stops building is exactly as informative as one that
   stops failing, and silence is the failure mode that has cost most here.
2. **The verdict matches `expect`.** A negative control that passes is a floor
   that has stopped holding.
3. **`clause:`, when given, is the clause actually reported** — not merely that
   *something* failed. This is the D6/D7 lesson: a check that fires on the right
   input for the wrong reason satisfies every other assertion in this list.
4. **`exclusive: true` asserts nothing else fired.** The two H3 controls on
   `v_ca07` fail on H3 and on nothing at all, one failure and two. That is what
   makes them a demonstration of *discrimination* rather than of a floor.
5. **`antecedent_counter` / `expect_count` for suppressing controls.** The
   counter must be one the testbench prints. Without it, "the control passed" is
   the unmeasured claim that F86 was itself built on.
6. **A declared control that is missing is `NO CONCLUSION` and exits non-zero.**
   Never "clean". *"Nothing failed"* and *"nothing was read"* must not print the
   same — the distinction `check_yaml_duplicate_keys.py` now makes, for the same
   reason.

## What it does NOT do

- It does not run controls as part of scoring a submission. These bound the
  **apparatus**, not the submission, and a submission's score must not move
  because a control regressed.
- It does not require a control per clause. A task with none declares none and
  that is a visible fact rather than an absence.

## Open, for the design side to settle

- **Where does it run?** A per-task runner (verification has `mutants/witness.sh`)
  or one repo-wide script in `scripts/`. Repo-wide is one place to fix and one
  place to break; per-task survives a task moving. I lean repo-wide reading the
  per-task declaration, but `scripts/` is AGENT-PPA's and the design side may
  have a constraint I cannot see.
- **Do design controls have the same three kinds?** I have inferred `suppressing`
  from F86's method. If the design side has a fourth, the schema should carry it
  from the start rather than gain it later.
- **`clause:` granularity.** Verification clause ids are `[A-Z][0-9]+`. If the
  design side names clauses differently the field needs a shape both can parse.

## Not landed

No runner has been wired on either side. One design, then land in parallel.
