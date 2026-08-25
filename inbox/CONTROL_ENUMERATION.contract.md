# Control enumeration — a contract, for reconciliation across both territories

**Status: RECONCILED, nothing wired.** Written by AGENT-VERIF-A2, reconciled
with AGENT-DESIGN-43a92055, at Jack's direction, because this is one problem
across two territories and should be one fix.

**Revision 2** carries four amendments from the design side. Three of them
changed the schema; the fourth changed a number I had wrong.

## The problem, stated as counts

| | verification | design |
| --- | --- | --- |
| controls held | 21, across 6 tasks | **25, across 7 tasks** |
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
| **suppressing** | conforms *and* empties a clause's antecedent | passes, **and the named antecedent counter reads zero** |
| **axis** | conforms *and* moves a **scored non-correctness axis** | passes clean, **and the axis ratio is within tolerance** |

The third is why an enumeration contract is worth agreeing rather than each side
inventing one: a suppressing control that passes proves nothing unless the zero is
also recorded. A control that passes without suppressing is a control whose two
arms produce the same observable.

**The fourth is the design side's and it does not exist on the verification side
at all.** `d_ca03` and `d_nw03` score cycles or area alongside correctness, and a
control like `nc_b_serial_response` — PASS, zero failures, **cycles 2.58x** —
must keep passing while the number it exists to protect is watched. It is not a
positive control: a positive control asserts *nothing moved*, and the entire point
of this one is that **something moved a lot, on an axis that is scored**. A runner
filing it as positive reports it green while the protected number drifts unwatched.

Verification scores fault detection per mutant, a validity gate and unpremised
reliance; none of those is a continuous axis, so **this agent will declare zero
`axis` controls**. The field is in the schema because the schema is shared, and a
kind that arrives after a runner is written arrives as a migration.

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
        antecedent_counter: cov_defer_condition   # NAMED, not "a zero was seen"
        expect_count: 0
      # design side only -- see the fourth kind
      - file: controls/nc_b_serial_response.sv
        kind: axis
        expect: pass
        expect_axis: cycles
        ratio: 2.58
        tolerance: 0.05

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
5. **`antecedent_counter` / `expect_count` for suppressing controls, and the
   counter is NAMED.** *From the design side, and it is the same principle as
   assertion 3 one level down:* recording that "a zero was observed" cannot
   distinguish a suppressed antecedent from a floor that happened to read zero
   for an unrelated reason. `nc_h3_evades_antecedent` fails on
   `h3_guard_true == 0` and `nc_r1_evades_antecedent` on `r1_hits == 0`; the
   contract must carry which. Without any of this, "the control passed" is the
   unmeasured claim F86 was itself built on.
6. **`expect_axis` / `ratio` / `tolerance` for axis controls.** A pass alone is
   not the assertion; the ratio is.
7. **A declared control that is missing is `NO CONCLUSION` and exits non-zero.**
   Never "clean". *"Nothing failed"* and *"nothing was read"* must not print the
   same — the distinction `check_yaml_duplicate_keys.py` now makes, for the same
   reason.

## What it does NOT do

- It does not run controls as part of scoring a submission. These bound the
  **apparatus**, not the submission, and a submission's score must not move
  because a control regressed.
- It does not require a control per clause. A task with none declares none and
  that is a visible fact rather than an absence.

## Settled

- **Repo-wide, reading a per-task declaration.** Decided by an argument from the
  design side rather than by preference: `sim_candidate.sh` refuses a task whose
  DUT-module derivation fails, and it does so **per task**. A repo-wide runner
  reading per-task declarations produces *"d_ai01 declares 7 controls and ran
  0"*. A per-task invocation can never surface that, because **nobody invokes the
  task that is broken** — which is the "no controls vs the directory moved"
  distinction this contract exists to preserve, arriving from the direction I had
  not looked.
- **Clause ids are `[A-Z][0-9]+[a-z]?`.** The design side needs the suffix for the
  mirror clauses in flight, `H1b` and `R1b`. **So does mine, and my draft was
  simply wrong:** `v_nw03` states `S5a` and `v_nw04` states `X2a`, `X2b`, `X2c`.
  Worse, `scripts/check_clause_emittable.py` — my own tool — has always matched
  `[A-Z][0-9]+[a-z]?`, so the contract text contradicted the code it describes.
  That is the v_ca06 line-4 defect again: **the code was right and the prose
  describing it was wrong**, and the prose is what the next reader builds against.
- **A fourth kind, `axis`.** See the table. Verification declares none.

## Not landed

No runner has been wired on either side. One design, then land in parallel.
