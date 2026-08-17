# Build prompt — DESIGN tasks

The instructions for building one design-from-spec task. Sequential, one agent,
one task at a time.

A design task ships a **port-only `_iface.sv`** to the model and asks it to write
the RTL. Everything else — testbench, reference, mutants, second source — stays
here and is never shipped.

Pick the task from `TASK_CATALOG.md`. Read `CONVENTIONS.md` before writing a
testbench and `FINDINGS.md` before deciding a check is good enough.

---

## WHAT EVERY DESIGN TASK PROMPT MUST STATE

**A submission must elaborate under BOTH slang and Verilator.** This belongs in
the task text given to the model, not only in the harness, and the reason is
F14's shape.

`d_ca04/kimi.sv` was rejected by slang for using an identifier before its
declaration and accepted by Verilator with zero errors. Verilator is the more
permissive frontend; the construct is not legal SystemVerilog either way. But
until this is written down, the submission fails **a requirement the task never
stated** — an inherited tool behaviour acting as a contract term, which is
exactly what F14 was about with the NaN payload.

The task text must say, in the prompt itself:

> Your design must elaborate under **both** Verilator 5.x and slang. These
> disagree: Verilator accepts some constructs slang rejects, and synthesis uses
> slang, so a design Verilator accepts may still be unbuildable. Declare every
> identifier before use, and do not rely on one tool's tolerance.

With that stated, a `kimi`-shaped failure is the submission failing something it
was told, which is the standard rule 18 draws between a spec requirement and a
hidden assumption.

## THE STANDING RULES

**The rules live in `RULES.md` and nowhere else. Read it before starting, and
re-read it before deciding a check is good enough.**

They are not restated here on purpose. They were previously duplicated across
this file, the verification prompt and `CONVENTIONS.md`, and the copies drifted:
a retraction recorded in `FINDINGS.md` stayed live here as current guidance, and
the count reached 7 in one document against 10 in another. Rule 13 exists because
of that, and restating them here would reintroduce exactly the defect it was
written to prevent.

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


### 2a. C3 — sustained acceptance rate, a standard contract term

Most blocks in this benchmark move transactions, and "how fast" is the axis a
model is most likely to trade away silently. Capacity alone does not catch that:
a design can accept `MAX_TRANS` outstanding and still idle between acceptances.

**Do not gate raw throughput.** Bursts per 1000 cycles is the *product* of
capacity, latency and arbitration policy, and gating it fails a correct design
that trades speed for area — the same defect as gating cross-ID reordering, in
new clothes. Throughput stays a scored `METRIC:` axis and never a gate.

Gate the **capability** instead, where C1 already draws the line:

| | | |
|---|---|---|
| capacity | how many the design must hold at once | **C1**, gated |
| **sustained acceptance rate** | **how often it must be able to take a new one** | **C3, gated** |
| bursts per 1000 cycles | what it achieved | METRIC, never gated |

**C3.** Under continuously offered load with every response accepted
immediately, the design must accept a new request **at least once every K
cycles**, with no dead cycle beyond that. The harness controls the offered load;
the requirement is what the design must be able to absorb.

Three conditions on how K is written. All three are mandatory.

**(i) K comes from the task's intent, stated in the spec — never from measuring
the reference.** Decide what the block is *for*, state the rate that purpose
implies, then check the anchor meets it. Deriving K from the anchor writes
"match this implementation's arbitration" into the contract by a longer route,
which is exactly the trap the ordering and reordering checks fell into. If you
find yourself running the reference to pick K, stop: you are about to encode it.

**(ii) If the reference or the second source fails K, the number is wrong, not
the design.** Same rule as every other check. **Verify both before the check
ships** — not after a candidate fails it, because by then there is pressure to
conclude the candidate is bad.

**(iii) It needs a negative control that fails C3 and nothing else:** a design
with full C1 capacity that stalls between acceptances — correct, full depth,
dead cycles. If you cannot build one that fails C3 alone, **C3 is entangled with
C1 and must be reworded** until you can. A control that trips both validates
neither.

**Pair C3 with a stimulus-side coverage floor** proving the offered load was
actually continuous across the measurement window — no cycle in which the
harness had nothing to offer. An acceptance-rate check that runs while the
harness is the bottleneck measures the harness. That mistake has already been
made once here: a concurrency control scored 199 % and passed because the
harness's slave models, not the design, were the limiting resource.

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
falsifier, not an oracle: its only job is to fail.**

**When it fails, do not assume the checker is over-constrained.** That inference
holds only where writing a correct second source is routine; for something like
an IEEE-754 FMA it is not. **Rule 5 in `RULES.md` gives the disambiguation
procedure — follow it before changing anything.**

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
