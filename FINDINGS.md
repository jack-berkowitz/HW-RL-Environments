# Findings

What went wrong while building this benchmark, how each defect was found, and
what it let a passing candidate hide.

This document exists because the defects are the most transferable thing the
project has produced. Every one of them was found *after* something passed, and
almost all of them are cases where **a check reported success while measuring
nothing**. Written for a reader who has seen none of this.

Two definitions used throughout:

- **Reference / anchor** — externally-authored RTL (PULP, basejump, Forencich,
  NVDLA, CVA6) wrapped in a thin port shim. The testbench is proven correct by
  passing RTL nobody here wrote.
- **Second source** — an independently written implementation whose only job is
  to *fail*. If it fails, the checker is over-constrained and the checker is
  wrong. It is a falsifier, never an oracle.

---

# THE PATTERN: work that looks like work and measures nothing

Five independent instances, in five different parts of the system, none of
which produced an error. This is the failure mode the project is organised
against, and it deserves naming before the individual findings.

### 1. The runner scored the wrong testbench for eight commits

`sim_candidate.sh` selected which testbench to score with:

```bash
TB="$(ls "$TASK_DIR"/tb/*_tb.sv 2>/dev/null | head -1)"
```

Alphabetical. `d_nw01` carries three testbenches, and
`axi4_xbar_liveness_tb.sv` sorts before `axi4_xbar_tb.sv`. The liveness rig is
deliberately minimal — read channel only, **no scoreboard, no data checking at
all**. So every run through the shared path scored the weak rig and reported
`8/8 PASS` for it.

Nothing errored. The output was indistinguishable from a full pass.

**Found by**: adding a third testbench and noticing it would sort first.
**Hid**: roughly the entire data contract — ordering, beat counts, decode errors.
**Rule**: the runner names its artifacts explicitly and refuses when they are
absent; it never discovers them by pattern.

### 2. A reference that had never run at all

`nw_d01`'s `ref/sim_flags_verilator.txt` was **empty**. The shim wraps a vendored
Forencich module and needs that directory on the search path, so the reference
failed all 16 configurations with `MODMISSING`.

It survived because of its asymmetry: **a self-contained candidate compiles fine
and only the reference fails**, which reads as a broken reference rather than a
broken configuration file. Every "the candidate beat the reference" statement
for that task had compared a gated candidate against a reference that was never
simulated.

**Found by**: re-running every task's reference through the shared path after an
unrelated change.
**Hid**: the entire comparison that triggered a catalog rebuild.
**Rule**: same as above — and every reference runs through the same gate as
every candidate, every time.

### 3. A measurement sweep that ran one iteration and died

An Fmax sweep was launched as `nohup … &` *inside* an already-backgrounded
call. The wrapper returned exit code 0 immediately, the real process was
orphaned after one iteration, and the result file was never written. Reading it
back produced the previous run's numbers — with the previous run's parameters
embedded, which is the only reason it was caught.

**Found by**: noticing the output JSON still recorded `seed_period_ns: 6.0` when
the run had been given `3.0`.
**Hid**: nothing yet — but it would have silently frozen a headline number.
**Rule**: a result file must record the parameters it was produced with, so a
stale read is detectable.

### 4. A results table reporting a live directory — the worst of the four

`collect_results.py` read the ORFS output directory directly. That directory is
shared and mutable: any concurrent build rewrites it. During an Fmax sweep the
`d_nw01` row read **`DID NOT COMPLETE`**.

`DID NOT COMPLETE` is *also the genuine finding about that task's candidate* — it
provisions 36 kbit of read buffering and fails detailed routing at 2003 DRC
violations.

**So the table displayed the right answer for the wrong reason, and nothing about
it looked wrong.** A stale entry that coincidentally matches a real result is the
most dangerous form of this defect: the other three announce themselves the
moment you look at the number, and this one does not. It would have gone into a
writeup unchallenged.

**Found by**: noticing the row while a sweep was knowingly running, and only
because the sweep had been started deliberately minutes earlier.
**Hid**: nothing — by luck. It was one concurrent build away from hiding anything.
**Fix, structural rather than a lock**: every run writes an immutable record
keyed by task, submission identity *and content hash*, timestamp and git SHA.
Collection reads only those records and **never the live directory**. A task
with no record is reported ABSENT rather than filled in from disk.
**Rule**: a missing row is honest; a stale row is not.

### 5. A self-consistent wrong answer — the worst of the five

An Fmax sweep aborted mid-bisection on a missing metrics file and wrote:

```json
"converged_period_ns": 6.0,
"achieved_fmax_mhz": 166.67,
"wns_at_converged_ns": 0.188814
```

Three fields, mutually consistent, all wrong. The true answer was at least
190.48 MHz — **understated by 14 %** — because the run the sweep gave up on had
in fact *completed*, leaving +0.04 ns slack and DRC 0 in its reports. The abort
reason was recorded, in a field below the headline numbers that nobody reads
before quoting them.

**The other four instances announce themselves the moment you look at the
number. This one does not.** There is nothing on the surface to notice: the JSON
is well-formed, the fields agree with each other, and the value is plausible for
the design.

**How it was caught, stated plainly: by a habit, not by a check.** The bracket
`[4.5, 6.0]` is 1.5 ns wide against a requested resolution of 0.5 ns — so the
search had not converged and the headline could not be a converged answer. That
comparison was only made because an earlier Fmax number on another task had been
sent back for exactly this reason, and checking bracket width against resolution
had become reflex. **A finding caught by a habit is a finding that was one
distraction away from being missed**, and it is reported that way rather than as
diligence.

**Fixes, both structural:**

1. Fall back to the reports when the metrics file is missing, rather than
   aborting — the flow had completed and the data was on disk.
2. **If the bracket is wider than the requested resolution, refuse to report an
   Fmax at all.** The trajectory is still written; it is simply not dressed up
   as a converged answer. This is the check that would have caught it with no
   human involved.

Applied to its own case, (2) also **rejects the corrected value**: the bracket
`[4.5, 5.25]` is 0.75 ns wide, so 190.48 MHz is a lower bound too. What is
established is that Fmax lies in **[190.48, 222.22) MHz** — and that is what the
record now says, instead of a number.

**What the five have in common:** exit code 0, plausible-looking output, and no
error anywhere. A test suite cannot catch these, because from the inside they
are indistinguishable from success. The only defence is to check that the thing
you think ran actually ran, against a known-failing input.

---

# UNBOUND PARAMETERS

A parameter the spec declares and no check enforces. The design is free to
ignore it, and every test still passes.

## 1. `MAX_TRANS` — declared once, never referenced

`d_nw01` (AXI4 crossbar) takes `MAX_TRANS`, the outstanding transactions each
master port must support. A candidate came back **67 % smaller** than the
reference while passing every configuration.

`MAX_TRANS` appeared **exactly once in its 732 lines — the parameter
declaration — and was never referenced again.** Its own comment said so: *"Only
one write from this master can be outstanding."*

Measured, by holding responses and counting what each master got in before the
crossbar stopped accepting:

| `MAX_TRANS` | reference | candidate |
|---|---|---|
| 2 | 3 | **1** |
| 8 | 9 | **1** |

The reference scales with the parameter. The candidate returns 1 at both.

**Why nothing caught it**: the testbench throttled its own offered load to
`MAX_TRANS`, so a one-deep design simply stalled `ar_ready` and the testbench
politely waited. Stalling is legal. No data was ever wrong.
**Hid**: seven-eighths of the required capacity, and half the aggregate
throughput.
**Rule**: every capability the design must support is a named parameter with a
binding check.

## 2. `DATA_W` — unbound above bit 31

`d_ca04` (async FIFO) takes `DATA_W ∈ {8, 32, 64}`. The payload generator was:

```systemverilog
wr_data <= DATA_W'(wr_idx + 32'h1000_0000);
```

A 32-bit value zero-extended. At `DATA_W = 64` **bits [63:32] were always zero**,
so a FIFO that carried only the low half passed every configuration.

**Found by**: building a probe that is a fully correct FIFO — loses nothing,
duplicates nothing, preserves order — and drops bits [63:32]. It **passed**.
**Hid**: half the datapath at the widest configuration.

## 3. `SYNC_STAGES` — unbound, and the first conclusion was wrong

Synchroniser depth for a clock-domain crossing. A probe hard-coding two flops
**passed at `SYNC_STAGES = 3`**.

An earlier investigation had concluded synchroniser depth is *not
simulation-observable* — a metastability-hardening parameter with no functional
consequence in a zero-delay simulation. **That conclusion was too strong**, and
it survived because it sounded principled.

It is observable, through a consequence that is not a latency budget: a beat
cannot reach the read side until the write pointer has crossed `SYNC_STAGES`
flops clocked by the destination clock, so **minimum crossing latency ≥
`SYNC_STAGES` destination cycles**. Measured before the bound was written:

| design | `SS=2` | `SS=3` |
|---|---|---|
| vendored reference | 3 | 3 |
| second source | 2 | 3 |
| probe (always 2 stages) | 2 | **2** |

The floor passes both correct designs at both settings and fails the probe
exactly where it is wrong. It is a *lower* bound implied by the CDC requirement
— backpressure can only make a crossing slower — so it does not conflict with
the spec's refusal to constrain latency, which is about upper bounds.

**Rule**: "not observable" is a claim that needs a measurement, not an argument.

## 4. `LOG_DEPTH` — bound only through a quantity known to be unmeasurable

FIFO depth. Violations *were* caught, but only by a coverage counter computed
from `occ = wr_idx - rd_idx` — a cross-domain difference **the same testbench
documents in a comment as unmeasurable and overstating**, having previously
caused a false failure on a correct design.

Worse, it misattributed the defect. The failure read:

> `COVERAGE HOLE: FIFO never approached full occupancy`
> `1 coverage holes -- run did not exercise the target hazards`

which says *the test didn't try hard enough* when the truth was *the design is
too small*. A reader debugging that goes to the testbench and finds nothing
wrong with it.

**Fixed** by a direct check observed entirely in one clock domain: stop the
reader, offer writes, count what is accepted. Below `2**LOG_DEPTH` fails with a
message naming the design.

## 5. Burst length — never a parameter at all

`d_nw01`'s spec permitted AXI4's full `ARLEN` range (up to 256 beats) and the
checker drove `$urandom_range(0, 3)` — never more than 4.

A re-solicited candidate read the spec correctly and provisioned a **256-entry
read buffer per master** — 36 864 bits — to absorb a maximum-length burst under
backpressure. It was being *more* compliant than the reference, which buffers no
read data at all.

**The fix was not to narrow the spec.** Narrowing would have punished the
candidate for being right and rewarded the anchor for being incomplete. Instead
burst length became a swept parameter, `MAX_BURST_LEN ∈ {3, 255}`, with the
spec stating it is also a **ceiling** — so provisioning beyond it is wasted area
rather than insurance, and the candidate can legitimately drop the buffer.

The anchor was measured *first*, to check the requirement was satisfiable before
it was written: the reference passes at `MAX_BURST_LEN = 255` under backpressure
while buffering nothing.

---

# STATED REQUIREMENTS WITH NO CONDITION TO TRIGGER THEM

A requirement written in the spec that no test ever creates the situation for.
Strictly worse than an unbound parameter, because the document looks complete.

## 6. `L3` — liveness under backpressure, never given the backpressure

`d_nw01`'s spec required deadlock and starvation freedom to hold *"with
backpressure applied on any subset of response channels"*.

The checker hardwired `r_ready = 1'b1` and `b_ready = 1'b1`. **Backpressure was
never applied.** The requirement had been decorative since the day it was
written, and the 256-entry buffer above was provisioned for a condition nothing
tested.

**Fixed**: a free-running LFSR stalls each master's response channels ~25 % of
the time, independently. It never reads `*_valid`, so it cannot create the
combinational dependency the spec forbids, nor wedge the way a handshake-derived
stall would. **A coverage floor fails the run if backpressure never actually
stalled a response** — so the requirement cannot go back to passing by never
being exercised.

## 7. `H1` — never checked at all

`d_ca04`'s spec: `wr_ready` must not depend combinationally on `wr_valid`. There
was no check. Not a weak check — none.

**Fixed**: toggle `wr_valid` between clock edges and require `wr_ready` not to
move. See finding 12 for what happened next.

---

# OFF-SPEC CONFIGURATION IN THE HARNESS

The reference is not neutral. It is a vendored module configured by a shim
*this project wrote*, and those choices are not part of the contract.

## 8. `CUT_ALL_AX` — 45 % of the reference's area, never requested

`d_nw01`'s shim bound `LatencyMode: axi_pkg::CUT_ALL_AX` — full channel cuts on
both address channels. The spec never asked for pipelining.

Rebuilding the reference with `NO_LATENCY` and synthesising both:

| build | synth area |
|---|---|
| reference, `CUT_ALL_AX` (as shipped) | 107 891 µm² |
| reference, `NO_LATENCY` (spec-minimal) | **59 209 µm²** |
| candidate | 34 733 µm² |

So a headline "candidate is 3.1× smaller" decomposes into **1.82× off-spec
pipelining × 1.70× missing capability**. Neither factor is an optimisation the
candidate earned, and quoting the headline alone would have been wrong in both
directions at once.

**Rule**: area comparisons are reported as a three-way split — off-spec
configuration, capability gap, genuine optimisation. A headline ratio without
that split is not a result.

This also produced the sharpest over-constraint of the project. A first attempt
at the capacity check required *at least* `MAX_TRANS` observable outstanding —
and the **same vendored crossbar**, correctly configured but without the channel
cuts, delivers `MAX_TRANS − 1` and **failed**. Observable capacity depends on
pipeline depth, not only on configured queue depth. The check had encoded one
implementation's buffering into the contract. The floor is now half of
`MAX_TRANS`, which passes the anchor at both settings, passes a no-cut anchor,
passes an independently written second source that provides *exactly*
`MAX_TRANS`, and still fails a one-deep design by a wide margin.

---

# CONTROLS THAT DID NOT CONTROL

A check whose failure mode is silence must be validated against a known-failing
input. These are the cases where the validation itself was wrong.

## 9. The wedging harness — a broken rig and a deadlocked DUT are identical

The first liveness rig for `d_nw01` reported `DEADLOCK` on the **correct**
reference. The crossbar was fine; the harness had wedged. Its master and slave
models drove `valid` from inside the same clocked block that consumed the
handshake, reading their own pre-update values.

**A wedged testbench and a deadlocked design emit exactly the same thing:
nothing.** Without both a known-good and a known-bad input, there is no way to
tell which side is broken.

This is why liveness mutants are now built *before* the checker they validate.
The pairing is the evidence: an arbiter that never grants must fire DEADLOCK, a
starved master must fire STARVATION **and not** DEADLOCK, and a correct-but-slow
design — every slave's latency inflated 14× — must fire **neither**. That last
one is the inverse control, and without it the monitor would silently encode one
arbitration policy into the contract.

## 10. A control that failed two checks validated neither

The textbook `H1` violation is `wr_ready = wr_valid && !full`. Used as a control
for finding 7, it **failed `R4` instead** — the requirement that `wr_ready`
assert within 16 cycles of reset — because ready is low whenever the producer is
idle, and `R4` is checked with the producer idle.

It failed. The suite went red. And it proved **nothing about H1**, because the
H1 check never ran.

Replaced with a probe that arms the dependency only after the first beat, so
`R4` still passes and H1 fires alone — one failing check, the right one.

**Rule**: a control validates a check only if it fails **that** check and
nothing else.

## 11. The C2 control took three attempts, each a hole in the check

`d_nw01`'s concurrency requirement: disjoint master/slave pairs must proceed in
parallel. A crossbar that serialises everything through one datapath is correct
on every individual transaction and is not a crossbar.

1. **Gated the master side.** Failed the capacity check too — see finding 10.
   Moved downstream of the queues.
2. **Passed at 199 %.** The harness's slave models accepted one transaction at a
   time, so a single pair ran at 0.5 bursts/cycle and *the slave*, not the
   crossbar, was the bottleneck. A fully serialising design kept up with it
   easily. **A throughput-shaped check is only as sharp as the load the harness
   can offer; if the harness is the limiting resource, the check measures the
   harness.**
3. **Passed at 199 % again.** A blind round-robin grant throttled the
   single-pair baseline exactly as much as the concurrent case, leaving the
   *ratio* unchanged. **A check expressed as a ratio is blind to any defect that
   scales both of its terms.**

Final control: passes the capacity check, fails concurrency alone at 100 %.

## 12. A new check that was vacuous on arrival

The H1 check from finding 7 **passed** its own control. Cause: a capacity phase
added in the same change set `rd_weight = 0` to stop the reader, and the drain
that followed restored `rd_en` but **not** `rd_weight`. The reader never
resumed, the FIFO stayed full, and `wr_ready` was 0 regardless of `wr_valid`.

The check passed because its precondition was never met — a silent no-op inside
a change written specifically to eliminate silent no-ops.

It now fails explicitly if it finds itself in that state, rather than passing on
a condition it never created.

## 13. A coverage floor that was measuring the harness

`d_nw01`'s cross-ID interleaving floor required ≥ 100 observed reorderings.
After burst length became a swept parameter, transaction counts were scaled down
at long bursts to hold total beats constant — and the **reference** tripped the
floor with 76.

Not a reference defect: 76 reorderings in 240 transactions is a **32 % rate**,
higher than the long runs achieve. The fixed floor was measuring the harness's
own scaling knob.

Made rate-based. The justification is deliberately independent of what the
reference scored, because **loosening a floor because the reference tripped it
is the purest form of the rediscover-the-reference trap.** The count scales with
transaction count; the property does not.

**Validated, and it did not survive.** The control — a crossbar restricted to
one ID in flight per master, and therefore incapable of any reordering — scored
**2234 against a floor of 20** and passed. The counter was measuring ID
*changes* in the delivered stream, which a strictly in-order design still
produces whenever consecutive transactions carry different IDs. *The floor could
not have failed anything.*

Replacing it with a real out-of-order-completion detector made it worse: the
**vendored reference then scored 0** at `MAX_TRANS=2` in eight configurations
and failed its own floor, while an independently written second source scored
218 on identical stimulus. The hazard was reachable; the reference simply
declines to reorder at that depth, which `O2` permits.

**So the floor was removed.** Reordering is a DUT choice, and gating it fails a
correct design — the rediscover-the-reference trap arriving from the opposite
direction, and this time it would have been written *into the contract*. The
requirement underneath was capacity with **mixed IDs**, which now lives in the
capacity check where the defect actually is: the capacity phase previously drove
one ID per master, so a design holding `MAX_TRANS` of a single ID while refusing
any second ID passed it.

### Neither control alone would have found it

This is the clearest argument for the second-source rule the project has, so it
is worth stating rather than leaving implicit.

**With only the reference**, the sequence is: the corrected counter makes the
reference score 0, the reference is known-good, so the floor must be too tight —
loosen it, move on. The conclusion is wrong in a way that looks responsible, and
*the counter is never suspected at all.*

**With only the mutant**, the sequence is: mX1 scores 0 and fails, the floor
caught a known-bad input, the floor works. Also wrong, and this one closes the
investigation with a green tick.

It took **both**, plus an independently written second source scoring 218 on
identical stimulus, to establish the actual fact: **the hazard was reachable and
the reference declined to take it.** The second source is what converts "the
reference scores 0" from evidence about the floor into evidence about the
reference. Without it, 0 is uninterpretable — you cannot tell a stimulus that
never created the opportunity from a design that never took one.

A known-good input tells you a check is not too tight. A known-bad input tells
you it is not too loose. **Neither tells you the check is measuring the right
quantity** — for that you need two correct designs that disagree.



---

# A COVERAGE FLOOR MUST MEASURE WHAT THE HARNESS CONTROLS — THE STIMULUS — NOT WHAT THE DESIGN CHOSE TO DO WITH IT

This is the most transferable thing in this document and it is not specific to
hardware. It is the general reason coverage metrics decay into implementation
constraints.

A coverage floor exists to answer one question: **did this run actually exercise
the situation the checker was built to survive?** It guards against a passing
result that passed only because the interesting case never arose — a random draw
that happened to miss it, a stimulus generator with a correlated bug, a
transaction count scaled down for runtime.

That question is about the **stimulus**, which the harness controls.

The failure mode is to measure the **outcome** instead, because the outcome is
easier to instrument. "Did reordering occur?" is one line; "did the harness
create conditions under which reordering was possible?" needs bookkeeping. So
the outcome gets measured, and for a while it correlates well enough that nobody
notices.

It stops correlating the moment a **conforming design declines to produce the
outcome.** Then the floor fails a correct design, and the floor has silently
become a requirement — one that was never written in the specification, never
agreed, and is now enforced. In this project that requirement would have been
*"a crossbar must reorder across IDs"*, in a contract whose ordering clause
explicitly grants the right **not** to.

The test for whether a floor is on the right side of the line:

> **Could a correct implementation score zero here?**
>
> If yes, it is measuring a design choice and must be a `METRIC`, not a gate.
> If no — because the harness itself creates the condition — it is coverage.

Applied to the floors in this project:

| floor | measures | verdict |
|---|---|---|
| unmapped-address requests were issued | stimulus — the generator chose the address | **coverage**, correctly gating |
| both a read and a write reached each slave | stimulus | **coverage** |
| backpressure actually stalled a response | stimulus — the harness drives ready | **coverage** |
| a burst of the full `MAX_BURST_LEN` was driven | stimulus | **coverage** |
| **cross-ID reordering occurred** | **the DUT's arbitration** | **removed — became a METRIC** |

The same test disposes of the near-miss cases. "Did the FIFO reach full
occupancy?" is a design choice if the design may legally be deeper than asked;
it is coverage only because the depth is *required*, and even then it was
measuring an unmeasurable cross-domain quantity and had to be replaced by a
direct capacity check.

**The general form:** a coverage metric measures the *input distribution*. The
instant it starts measuring the *output distribution*, it has become a
specification clause that nobody wrote down.

---

# AREA × DELAY IS NOT AN INDEPENDENT AXIS UNLESS AREA IS ELASTIC

A composite metric is only worth quoting when its terms move independently. For
`d_ca04` they do not, and the arithmetic shows exactly why:

| quantity | value |
|---|---|
| speed ratio (reference faster) | **1.714** |
| area ratio (reference bigger) | **1.362** |
| area × delay ratio | 1.714 / 1.362 = **1.258** |

Area barely moves under constraint — 1.5 % from a relaxed 6.0 ns to the design's
2.625 ns limit — because the design is **storage-dominated**: its cell count is
set by `DATA_W × 2**LOG_DEPTH`, and only a small amount of pointer logic sits on
the critical path. With area effectively constant, area × delay is proportional
to delay, and **the AD ranking is the Fmax ranking wearing a different unit.**

Two consequences:

1. **AD must not become a scoring axis.** PPA axes are kept separate so that it
   is visible which one moved; a composite hides precisely the information the
   separation exists to preserve. AD is legitimate as engineering interpretation
   in prose — it answers "which would I take for a fixed silicon budget?" — but
   it is not evidence, and it must never be reported as a third result standing
   beside area and Fmax.
2. **The precondition for quoting it is that area is elastic under constraint**,
   and that is a property of the individual design, not an assumption. Test it
   by sweeping area across periods, as was done here. A logic-dominated design
   would behave completely differently, and there AD may carry real information.

## The two sweeps, side by side

Elasticity is a property of the individual design, and the two tasks built so
far sit at opposite ends of it:

**Only runs that closed are in this table.** A first version included 3.0 ns and
4.5 ns for the crossbar and reported "+17.6 %" — both are periods the design
misses timing at, by 2.15 ns and 0.64 ns. See `CONVENTIONS.md`, *no metric may be
quoted from a run that failed its own gate.*

| period | area | vs relaxed | |
|---|---|---|---|
| **`d_ca04` FIFO** | | | |
| 6.000 ns | 19 809 µm² | — | closes |
| 3.000 ns | 19 955 µm² | +0.7 % | closes |
| 2.625 ns | 20 101 µm² | **+1.5 %** | closes, its limit |
| **`d_nw01` crossbar** | | | |
| 12.00 ns | 146 951 µm² | — | closes |
| 6.00 ns | 150 399 µm² | +2.3 % | closes |
| 5.25 ns | 154 245 µm² | **+5.0 %** | closes, fastest measured |

**+1.5 % against +5.0 %** — the crossbar is more elastic, but not by the margin a
first pass suggested. The honest conclusion is weaker than the one originally
drawn from it:

**Both tasks built so far are largely inelastic, and no design has yet been found
where area × delay carries information independent of area and Fmax.** At 5 %
across the closing range, AD for the crossbar is still delay-dominated and still
close to redundant — just less so than for the FIFO. The precondition stands as a
thing to *test*, but it has not yet earned its place by finding a case where it
changes an answer. If a genuinely elastic design turns up later, that is when it
does.

The general form: **a composite of two measurements you already have is not a
third measurement.** It is worth computing only when you can show the terms are
not locked together.

---

# CHOOSING ANCHORS: contamination, and why the order matters

Every Class A task is anchored on vendored open-source RTL, which raises an
obvious objection: **if the reference is on GitHub, the model has seen it.**

The mitigation is a sourcing preference order, chosen to limit pretraining
contamination:

> **basejump_stl → PULP → Forencich → NVDLA → ZipCPU → CVA6 → local Python model**

The ordering runs from *least* to *most* likely to appear in a pretraining
corpus with its problem statement attached. `basejump_stl` and PULP's
`common_cells` are library modules whose names carry little context.
Forencich's `verilog-axis` and NVDLA sit in the middle. CVA6 is a well-known
core whose module names are strongly associated with published descriptions.

**Ibex and OpenTitan are excluded entirely.** Both are heavily documented,
heavily tutorialised, and heavily reproduced, which makes them the worst case:
a model may reproduce the reference implementation from memory rather than
solving the stated problem, and the benchmark would be measuring recall.

One sanctioned exception, and the shape of it is the point. A SECDED ECC task
wanted OpenTitan's `prim_secded`. The mitigation: generate the Hsiao parity
matrix from a locally-written Python model, make **that model** the artifact of
record, consult `prim_secded` exactly once as a cross-check that the generated
matrix matches a known-good one, rename aggressively in the interface, and
record the SHA. With the standing instruction that **if the cross-check cannot
be done cleanly, drop the task rather than ship a contaminated one.**

That is the general principle: contamination is managed by making the
locally-authored artifact the one of record and demoting upstream to a
cross-check — never by hoping the model has not seen the file.

A related constraint: **design and verification anchors are disjoint at module
level.** A verification task ships a decontaminated copy of its golden RTL; if
that same module were a design task's hidden reference, a model working both
would be handed the answer. Shared repository is fine, shared module is not.

---

# THE STANDING RULES, AND WHICH FINDING PRODUCED EACH

| # | rule | from |
|---|---|---|
| 1 | Every capability the design must support is a named parameter with a binding check | `MAX_TRANS`, `DATA_W`, `SYNC_STAGES`, burst length |
| 2 | Every stated requirement has a coverage floor proving it was exercised | `L3`, `H1` |
| 3 | A checker whose failure mode is silence must be validated against a known-failing input | the wedging harness |
| 4 | A control validates a check only if it fails **that** check and nothing else, and only if the harness can saturate what the check measures | the H1 control, the three C2 attempts |
| 5 | The runner names its artifacts explicitly and refuses when they are absent; it never discovers them by pattern | alphabetical testbench selection, empty `sim_flags` |
| 6 | Area comparisons are reported as a three-way split: off-spec configuration, capability gap, genuine optimisation | `CUT_ALL_AX` |
| 7 | When blocked, the deliverable is the report | — |

---

# WHAT THIS COST, AND WHAT IT BOUGHT

Three consecutive spec gaps were found **after a candidate had passed**. Each
one let a passing submission differ from the reference by a large factor on an
axis the harness could not see: 8× on outstanding capacity, 2× on throughput,
14× on area.

They were not independent defects. They are one defect — **a requirement stated
in prose with no binding check** — recurring in three places.

The practical consequence is a rule about scope: **a larger module reproduces
this exactly, at several times the cost.** Complexity should not increase until
the existing tasks are clean, because the failures found so far have been in the
harness rather than in the models, and a bigger module produces more harness.

The first measurement that was actually about model capability rather than about
a defect here came only after all of the above was fixed — and it produced a
tradeoff rather than a ranking: a candidate 27 % smaller and 44 % lower power at
a clock where neither design was constrained, and 33 % slower at the frequency
where they were. Two points on one Pareto frontier, with no way to rank them
without a frequency target the specification never stated.
