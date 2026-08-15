# Build prompt — DESIGN tasks

The instructions for building one design-from-spec task. Sequential, one agent,
one task at a time.

A design task ships a **port-only `_iface.sv`** to the model and asks it to write
the RTL. Everything else — testbench, reference, mutants, second source — stays
here and is never shipped.

Pick the task from `TASK_CATALOG.md`. Read `CONVENTIONS.md` before writing a
testbench and `FINDINGS.md` before deciding a check is good enough.

---

## THE STANDING RULES

In force for every task. Each exists because its absence produced a wrong result
that survived review. `FINDINGS.md` records which defect produced each.

1. **Every capability the design must support is a named parameter with a
   binding check.** A parameter no check enforces will be ignored, and the
   design that ignores it will pass.
2. **Every stated requirement has a coverage floor proving it was exercised.** A
   requirement written in prose that no test creates the condition for is
   decorative.
3. **A checker whose failure mode is silence must be validated against a
   known-failing input before it is trusted.** A wedged harness and a deadlocked
   design emit exactly the same thing.
4. **A control validates a check only if it fails THAT check and nothing else,
   and only if the harness can saturate what the check measures.** A control
   that trips two checks validates neither; a throughput check whose bottleneck
   is the harness is measuring the harness.
5. **The runner names its artifacts explicitly and refuses when they are absent;
   it never discovers them by pattern.** Globbing, sorting and silent defaults
   turn a missing artifact into a different run rather than an error.
6. **Area comparisons are reported as a three-way split:** off-spec
   configuration, capability gap, genuine optimisation. A headline ratio without
   that split is not a result.
7. **When blocked, the deliverable is the report.** Stop and say so.

**Nothing you write is trusted until it has been run.**

---

## Order of work

Stop and report after each numbered step.

### 1. Anchor and oracle class

Confirm the vendored anchor named in `TASK_CATALOG.md` exists at the pinned SHA,
elaborates, and does what the catalog claims. **The fourth check is the one that
gets skipped and the one that finds problems.**

Record the oracle class:

- **Class A** — external RTL behind a thin shim. The strong case.
- **Class B** — local Python model of record. *"The testbench passes
  known-correct external RTL" is not available and must never be claimed.*
- **Class C** — cross-check only.

### 2. The interface

Write `spec/<module>_iface.sv`: ports, parameters, and the contract in header
comments. This is the only file the model receives.

Every parameter must be something a check will enforce (rule 1). Every
requirement must be something a test will create the condition for (rule 2). If
you write a requirement you cannot check, either build the check or delete the
requirement — **do not ship both the claim and no test for it.**

State explicitly what is *not* constrained. Latency and throughput usually are
not; capacity and concurrency usually are. The distinction between *delay*
(free) and *capacity* (required) has been mistaken before.

### 3. The shim — Class A only

`ref/<module>_ref.sv` is **combinational renaming and struct pack/unpack only.**
No behaviour, no buffering, no arbitration.

If bridging needs behaviour, the shim has failed. Do not reshape the interface
to fit the anchor's internal boundary — that bakes the anchor's free choices
into the spec. **Convert the task to a verification task instead.**

**Hard limit: three conversions across the project.** A fourth is stop-and-report:
it means the anchor repository was the wrong choice for that domain, and the fix
is substituting a different anchor, not draining the design side.

The shim's configuration choices are **not part of the contract**. Binding a
vendored module with deeper pipelining than the spec requires makes the reference
larger for reasons the candidate never had to compete with (rule 6). Record every
configuration parameter the shim binds, and be prepared to re-derive numbers
against a different setting.

### 4. Liveness rig and its mutants — BEFORE the checker

If the task has any liveness requirement, build this first.

Build the deadlock and starvation mutants **before** the monitor that catches
them, and prove the monitor on them (rule 3). Then prove the **inverse**: a
correct-but-slow design must NOT fire, or the monitor has silently encoded one
arbitration policy into the contract.

### 5. The checker

`tb/<module>_tb.sv`. The name must match the DUT module — the runner requires it
and refuses otherwise (rule 5).

Last line is exactly `TEST_RESULT: PASS` or `TEST_RESULT: FAIL: <reason>`.
Quality numbers are `METRIC:` lines and never gate.

Three things a checker must not do, each of which looks correct while failing a
correct design:

- **Do not check a global order** where the spec requires only a local one.
- **Do not assert a cross-domain quantity.** A value advanced in two clock
  domains has no consistent reading at any single sampling point.
- **Do not require a particular arbitration, latency or interleaving** unless
  the spec states it.

Coverage floors for every hazard the task exists to test, printed as
`// COVERAGE HOLE: <what>` and failing the run.

### 6. Mutants

5–7, one defect each, each with the killing check named. Include the classes
this project has found the hard way:

- **liveness** — deadlock, and starvation that does *not* also read as deadlock
- **ordering** — violates local order while global order still looks right
- **boundary** — off-by-one at full, empty, wrap
- **capability** — correct on every transaction, but carries a fraction of the
  required capacity. *This class was discovered after a one-deep design passed
  everything.*

### 7. Second source

An independently written implementation, structurally unlike the anchor. **A
falsifier, not an oracle: its only job is to fail.** If it fails, the checker is
over-constrained and the checker is wrong.

Make the free choices differently on purpose — different arbitration, different
buffering depth, exactly the required capacity rather than the anchor's
comfortable margin. Those are the differences that expose a check pinned to one
implementation.

### 8. PPA

`orfs/config.mk`, then `scripts/build_and_score.sh <task>`.

**A comparison at a clock that does not bind is not a result.** If both designs
close with slack to spare, neither was pushed, and the area difference reflects
whatever each happened to synthesise to. Run `scripts/find_fmax.py` on both and
report the frequency at which each stops closing.

### 9. NOTES.md

The evidence trail: oracle class, what each check does and why, every negative
control with its result, every over-constraint found and how it was fixed, and
the PPA numbers with the three-way split.

**Record what you did not do.** "Second source not written" is a fact a reader
needs. Do not describe a weaker guarantee in language that implies a stronger
one.
