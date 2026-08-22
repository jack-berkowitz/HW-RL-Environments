# Findings

What went wrong while building this benchmark, how each defect was found, and
what it let a passing candidate hide.

This document exists because the defects are the most transferable thing the
project has produced. Every one of them was found *after* something passed, and
almost all of them are cases where **a check reported success while measuring
nothing**. Written for a reader who has seen none of this.

**One line to carry away, if only one:**

> **An automated proxy for a property you cannot yet observe is a guess with a
> number attached.**

It is stated here because a reader should hit it early. It was learned from
mutant quality — a plausible, cheap metric that survived weeks of being quoted
before it turned out to rank the most valuable mutant in the project as
unremarkable — but it generalises to every derived score in this document, and to
most of them outside it.

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

### P1. The runner scored the wrong testbench for eight commits

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
**Rule produced**: rule 10.

**Rules:** 10
### P2. A reference that had never run at all

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
**Rule produced**: rule 10, and the corollary that every reference runs
through the same gate as every candidate, every time.

**Rules:** 10
### P3. A measurement sweep that ran one iteration and died

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

**Rules:** 7, 8
### P4. A results table reporting a live directory — the worst of the four

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

**Rules:** 8
### P5. A self-consistent wrong answer — the worst of the five

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

**Rules:** 7

---

# UNBOUND PARAMETERS

A parameter the spec declares and no check enforces. The design is free to
ignore it, and every test still passes.

## F1. `MAX_TRANS` — declared once, never referenced

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

**Rules:** 1
## F2. `DATA_W` — unbound above bit 31

`d_ca04` (async FIFO) takes `DATA_W ∈ {8, 32, 64}`. The payload generator was:

```systemverilog
wr_data <= DATA_W'(wr_idx + 32'h1000_0000);
```

A 32-bit value zero-extended. At `DATA_W = 64` **bits [63:32] were always zero**,
so a FIFO that carried only the low half passed every configuration.

**Found by**: building a probe that is a fully correct FIFO — loses nothing,
duplicates nothing, preserves order — and drops bits [63:32]. It **passed**.
**Hid**: half the datapath at the widest configuration.

**Rules:** 1
## F3. `SYNC_STAGES` — unbound, and the first conclusion was wrong

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

**Rules:** 1
## F4. `LOG_DEPTH` — bound only through a quantity known to be unmeasurable

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

**Rules:** 1, 4
## F5. Burst length — never a parameter at all

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

**Rules:** 1

---

# STATED REQUIREMENTS WITH NO CONDITION TO TRIGGER THEM

A requirement written in the spec that no test ever creates the situation for.
Strictly worse than an unbound parameter, because the document looks complete.

## F6. `L3` — liveness under backpressure, never given the backpressure

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

**Rules:** 2
## F7. `H1` — never checked at all

`d_ca04`'s spec: `wr_ready` must not depend combinationally on `wr_valid`. There
was no check. Not a weak check — none.

**Fixed**: toggle `wr_valid` between clock edges and require `wr_ready` not to
move. See finding 12 for what happened next.

**Rules:** 2

---

# OFF-SPEC CONFIGURATION IN THE HARNESS

The reference is not neutral. It is a vendored module configured by a shim
*this project wrote*, and those choices are not part of the contract.

## F8. `CUT_ALL_AX` — 45 % of the reference's area, never requested

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

**Rules:** 9

---

# CONTROLS THAT DID NOT CONTROL

A check whose failure mode is silence must be validated against a known-failing
input. These are the cases where the validation itself was wrong.

## F9. The wedging harness — a broken rig and a deadlocked DUT are identical

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

**Rules:** 3
## F10. A control that failed two checks validated neither

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

**Rules:** 3
## F11. The C2 control took three attempts, each a hole in the check

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

**Rules:** 3, 5
## F12. A new check that was vacuous on arrival

The H1 check from finding 7 **passed** its own control. Cause: a capacity phase
added in the same change set `rd_weight = 0` to stop the reader, and the drain
that followed restored `rd_en` but **not** `rd_weight`. The reader never
resumed, the FIFO stayed full, and `wr_ready` was 0 regardless of `wr_valid`.

The check passed because its precondition was never met — a silent no-op inside
a change written specifically to eliminate silent no-ops.

It now fails explicitly if it finds itself in that state, rather than passing on
a condition it never created.

**Rules:** 3
## F13. A coverage floor that was measuring the harness

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

**Rules:** 4

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
| 5.25 ns | *154 245 µm² (PROVISIONAL, unverifiable -- F20)* | *+5.0 % (provisional)* | closes, fastest measured |

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

# WE MEASURED CONTAMINATION INSTEAD OF ASSUMING IT AWAY — AND IT WAS TOTAL

Every verification task in this benchmark ships its DUT. The whole half rests on
an assumption carried since the corpus was vendored: that a module renamed and
stripped of commentary is not recognisable as the upstream file it derives from.

**That assumption had never been tested. It is false, at least for the first
anchor we tested it on.**

## The constraint that shapes the experiment

Decontamination cannot be total, because it is bounded by licence. SHL-0.51 §4 —
and the equivalent clauses in Apache-2.0, MIT, BSD and ISC — require attribution
notices to be **retained** in redistributed derivatives. Shipping a DUT to a
model provider is distribution.

The mitigation was a **corpus-level notice**: one block listing all 16 vendored
projects, attached to every shipped DUT, rather than the file's own upstream
header. Retention is satisfied, the statement is truthful, and it says "derives
from one of these sixteen" rather than naming the project.

Everything else was stripped: module renamed, every port and internal signal
renamed, all comments removed, includes removed, assertion macros inlined. The
result was verified **functionally identical to the original** — 160 000
cycle-by-cycle comparisons, zero differences — because a rename that changed
behaviour would have invalidated the task.

## The experiment

Two prompts, identical wording, one variable:

- **A** — the shipped, decontaminated DUT.
- **B** — the untouched original, as a positive control. Without B, a low score
  on A is ambiguous: it could mean renaming worked, or that the model never knew
  the module. Only the gap says what decontamination bought.

Four questions: what does it do, what project is it from, what is it originally
called, and — the important one — **how confident are you and what specifically
in the code led you there.** Without the reasoning, "it's `id_queue`" and "the
notice lists common_cells" are indistinguishable in the output.

## The result

| | A (shipped) | B (original) |
|---|---|---|
| project + file | **correct** | correct |
| **original module name** | **correct** | correct |
| stated confidence | **>99 %** | ~100 % |

**Delta: approximately zero.** Decontamination bought nothing.

And the reasoning shows it was recall rather than reading the notice. The model
**reconstructed the upstream identifier set from structure alone** — every one of
these appears *zero* times in the shipped file:

`HtCapacity`, `head_tail_t`, `linked_data_t`, `ID_WIDTH`, `CAPACITY`, `inp_*`,
`oup_*`, `exists_*`, and `id_queue` itself.

It gave the full rename mapping in the correct direction, and singled out the
simultaneous pop/push reuse path as "nearly dispositive". **The structure is the
fingerprint, and the structure is the thing the task requires us to ship.**

## What follows

**One unresolved question first:** whether the model had web search enabled. The
answer cites specific upstream commit dates, which is either deep pretraining
knowledge or a live lookup. Pretraining recall can be mitigated by choosing
less-reproduced anchors; **live retrieval cannot be mitigated by obscurity at
all**, and would affect the design half too, where a model could look up the
reference rather than solve the spec.

Sample is **one model, unlabelled** — a single observation, not a rate. It does
not establish that every anchor behaves this way; `id_queue` is small,
distinctive and widely vendored. It does establish that licence-bounded
decontamination is not, by itself, protection.

**The methodological point stands independently of the number.** Running the
probe cost two prompts and converted an assumption the project had carried since
Phase 0 into a measured result — before fifteen more tasks were built on it,
rather than after. A benchmark that measures and reports its own contamination
rate is more credible than one that claims none; after this, claiming none is not
available to us.

---

# RETRACTED: DIFF RATE AS A MUTANT-QUALITY BAND

**This was a proposed heuristic, it was tested, and it is wrong. Recording it as
a failed idea rather than quietly dropping it.**

The proposal — made by the project lead, falsified by the measurement — was that
diff rate, the fraction of cycles on which a mutant and the reference diverge
under identical stimulus, could band mutant quality: **too high means the mutant
is filler** (a change so coarse any testbench catches it), **too low means it is
effectively unkillable**. Flag anything above roughly 25 %, flag anything near
zero, keep the middle.

Both ends are wrong, and the counter-examples came from the same task.

| mutant | diff rate | what it actually is |
|---|---|---|
| `mCAP1` one-outstanding-per-master | **100 %** | **the most valuable mutant in the project** |
| `mC2` serialised datapath | **0 %** | not unkillable at all — the checker kills it |

**`mCAP1` is a real model submission**, recovered from git, that passed *every*
correctness configuration of the checker as it then stood: right data, right
order, right beat counts, no deadlock, no starvation — while carrying one eighth
of the required capacity. It is the reason the CAPABILITY class exists. The band
would have flagged it as filler.

**`mC2` scores zero because the differential harness holds slave responses at
zero** to keep its stimulus protocol-legal, so nothing completes and a
slave-side serialisation defect never manifests. The mutant is comfortably
killable — the concurrency check fails it at exactly 100 % speedup. The band
would have flagged it as unkillable.

**The metric measures pervasiveness under one particular stimulus, and that turns
out to be uncorrelated with the property it was meant to proxy for.** A defect
that perturbs a handshake every cycle scores 100 % whether it is profound or
trivial; a defect invisible to the chosen stimulus scores 0 % whether it is
subtle or merely unexercised.

## What diff rate is demoted to

**A witness that non-equivalence was demonstrated under a given stimulus.**
Nothing more. In particular:

> **A zero does not mean equivalent. It means this stimulus did not distinguish
> them.**

That distinction now lives in the field name rather than only in prose — the
harness reports `non_equivalence_demonstrated` and, when it is false, says so
explicitly instead of printing a number that reads like a score.

## And mutant quality is left with no prior — deliberately

There is no replacement heuristic and **none should be built.** Mutant quality
is a *posterior*, not a prior: a mutant every submission kills is filler, a
mutant nobody kills is too hard, and **neither is knowable before submissions
exist.** It is deferred to the cross-model run, where the kill matrix answers it
directly.

The general lesson, which is the reason this is written up at all: **an
automated proxy for a property you cannot yet observe is a guess with a number
attached.** This one survived several weeks of being quoted because it was
plausible and cheap, and it took building the highest-value mutant in the project
to notice it ranked that mutant as unremarkable.

---

# A SECOND DEFECT CLASS: CONTRACT DEFECTS

The first thirteen findings are one class: **measurement apparatus reporting
success while measuring nothing.** A testbench selected by sort order, a
reference that never ran, an orphaned sweep, a results table reading a live
directory, a self-consistent wrong Fmax. All of them exited zero and looked fine.

The two findings from `d_dsp02` are **not that class**, and the distinction
matters because it means the list is not closed.

## F14. A requirement inherited rather than chosen

Expected values for `d_dsp02` are captured from the vendored anchor, which makes
them correct. It does not make them *uniquely* correct.

IEEE-754 only **recommends** NaN payload propagation. RISC-V mandates a canonical
quiet NaN, cvfpu follows RISC-V, and so the captured vectors silently required
it. **An FMA propagating an operand payload is equally conformant and would have
failed** — against a requirement nobody had written down.

Auditing the vectors rather than the prose found **four** such inherited choices,
not one:

| | IEEE | anchor |
|---|---|---|
| NaN payload | recommends propagation | canonical `0x7FC00000`, all 188 results |
| NaN result sign | unspecified | always positive |
| **underflow tininess** | **before *or* after rounding permitted** | after, and only when inexact |
| overflow → inexact | mandated | consistent |

**The underflow case is the instructive one.** The spec *already said* "tininess
after rounding". Reading it would not have caught anything — the defect was that
the standard permits the other reading and the spec never said so. It surfaced
only by counting flag combinations across 4290 captured vectors.

**Rule 12**: standards latitude must be named, and audit the artefact, not the
prose.

**Rules:** 12, 15
## F15. Guidance that decayed

Diff rate was retracted as a mutant-quality band and recorded as such in this
document — **and left live in `BUILD_PROMPT_VERIFICATION.md`**, where it read as
current instruction. The next verification task would have inherited a withdrawn
heuristic. In the same edit the rule count was found at 7 in one prompt against
10 in the working set.

The cause is duplication: the rules lived in three documents at once.

**Rule 13**: the rules live in `RULES.md` and nowhere else; every other document
references it.

And the consolidation edit itself **dropped a rule** — "the runner names its
artifacts explicitly", the one produced by the alphabetical-testbench defect,
survived only in this file and in neither prompt. That is the same failure
occurring during the fix for it, which is the strongest available argument that
the structural fix was the right response rather than more careful editing.

**Rules:** 13
## F16. A rule dropped by the edit that was fixing rule duplication

`RULES.md` was created because the rules had been duplicated across three
documents and the copies drifted (F15). The consolidation edit that produced it
**silently dropped one of the rules it was consolidating**: *"the runner names
its artifacts explicitly and refuses when they are absent"* — the rule produced
by P1 and P2 — survived only in this file, and in **neither build prompt**.

**Found by diffing the unified list against the originals rather than trusting
the edit.** No test would have caught it: every document was well-formed, the
list was plausibly complete, and the missing rule is one whose absence shows up
only when someone writes a runner months later.

**The failure occurred during the remedy for it.** That is the strongest argument
available that the structural fix — one file, referenced everywhere — was the
right response, and that "edit more carefully" was not: careful editing is
exactly what was being attempted.

**Rules:** 13 (single source of truth), and the mechanical linkage check that
now guards it.

**Class:** contract defect, like F14 and F15. The apparatus was fine.


## Why the distinction is worth recording

The first thirteen are **apparatus defects**: something measured nothing and
said it was fine. They are caught by controls, by known-failing inputs, and by
checking that the thing you think ran actually ran.

These two are **contract defects**: the apparatus worked perfectly. The vectors
were captured correctly, the prompts rendered correctly, every number was real.
What was wrong was *what we had agreed to require* — a requirement absorbed from
an implementation, and guidance that aged out of correctness while still being
served.

**No control catches those.** A negative control confirms a check fires on a
known-bad input; it cannot tell you the check encodes a choice the standard left
open. What catches them is auditing the artefact against the source of authority
— the standard, not the reference; the single rule file, not the copy in front of
you.

`d_dsp02` was sequenced as the first task built under the rules from the start,
to find out whether they were sufficient. **They were not, and the two gaps were
of a class the previous thirteen would not have predicted.**

## F17. Rule 5's disambiguation, tested three times in the turn it was written

The `d_dsp02` second source failed the checker three times. **Every one
adjudicated to "the second source is wrong." No check was loosened at any point.**

| # | symptom | actual cause | verdict |
|---|---|---|---|
| 1 | 3632/4290 fail; `1.0×2⁻¹⁴⁹ + 0` → `0` | addend placed at `P_POS`, product shifted from bit 0 — an 80-bit frame offset | second source |
| 2 | `2⁻¹⁰⁰ × 2⁻⁴⁰` nonsense | `{2'b0, ep}` is unsigned, so `ep = −13` read as `4083` | second source |
| 3 | wide-exponent cases fail | stated difference not implementable at sane width (F18) | second source |

**The counterfactual is the finding.** The wording rule 5 replaced treated a
second-source failure as evidence about the check. Under it, this task would have
loosened the checker three times: once to tolerate a frame-offset bug, once to
tolerate a signedness bug, and once to accommodate a design choice that cannot be
built. The anchor would have kept passing, the second source would have kept
passing, the coverage floors would have stayed green, and **all three loosenings
would have been invisible afterwards** — a checker with three holes in it,
reporting success, with nothing in the artefact recording that the holes were put
there deliberately.

That is the same shape as every apparatus defect in this document, arrived at
from the opposite direction: not a check that never fired, but a check
deliberately weakened until it stopped firing, one accommodation at a time.

**The disambiguation is what makes the second source a falsifier rather than a
negotiation.** Without it, "independent implementation disagrees" is an argument
for whichever artefact its author is less willing to rewrite.

**Rules:** 5

## F18. A free choice that was not free — strict addend framing needs ~485 bits

Difference 1 was first written as *frame the accumulator on the addend and shift
the product*, the exact inverse of the anchor. **It is not implementable at a
sane width**, and the reason is a real property of the design space rather than a
fact about this attempt.

With the frame pinned to the addend, a zero or subnormal addend sits at effective
exponent −149 while the product ranges up to 2¹²⁸ — and a subnormal×subnormal
product reaches 2⁻²⁹⁸. The accumulator must span that whole range *relative to a
frame it does not control*: roughly 426 binades plus 48 bits of product mantissa
plus round and sticky, so **on the order of 485 bits**. The anchor sizes its
alignment shifter for `3·PRECISION_BITS + 5 = 77` positions
(`fpnew_fma.sv:72`), which is about a sixth of that.

**This explains why the anchor frames on the product, and nothing in the anchor's
source says so.** `SHIFT_AMOUNT_WIDTH` is a bound with no rationale attached; the
comments describe what the code does, not which alternatives were rejected or
why. The constraint is recoverable only by trying the alternative and watching
the width explode.

**That is the second source doing something beyond being a control.** Its
declared job is to fail differently from the anchor. Its side effect here was to
*map which of the anchor's choices are actually free* — framing is not, and any
spec language implying a designer may frame either way is wrong. Two of the three
differences survived; this one turned out to be a constraint wearing the costume
of a choice.

The shipped difference is the smaller, true claim: **bidirectional** alignment
onto `max(ep, ec)`, which needs no more width than the anchor and is still the
opposite of a unidirectional addend shift.

**Convention:** Name the differences before building — and record the ones that failed

## F19. The single-source fix was applied to the prompts and not to everything else

Rule 13 consolidated the rules into `RULES.md` after they had drifted across
three documents (F15). **Two live duplications survived the consolidation**, both
found while adding F17 and F18:

1. **A seven-row rule table inside `FINDINGS.md` itself** — with its own
   numbering, contradicting `RULES.md` on what rules 3 through 7 are. A reader
   following a cross-reference to "rule 5" landed on the runner rule or on the
   second-source rule depending on which file they were in.
2. **Four rules restated in full in `CONVENTIONS.md`** — 5, 6, 7 and 11, as
   normative section headings rather than as pointers.

**The linkage checker passed throughout**, because it reads `**From:**` lines in
`RULES.md` and `**Rules:**` lines in `FINDINGS.md`. A rule copied into a markdown
table or a section heading is not in either grammar, so the one automated control
for rule duplication was structurally incapable of seeing the duplication.

The duplication in `FINDINGS.md` is the sharper instance: **the stale copy was
sitting in the document that records F15 and F16**, the two findings about rules
decaying when duplicated. Recording a failure mode in a document does not
inoculate that document against it.

Fixed by deleting both copies and leaving pointers, and by extending the checker
to reject any rule-list table outside `RULES.md` — which is a genuine structural
check, unlike detecting a *restatement*, which is a content question no cheap
proxy answers honestly.

**Rules:** 13

## F20. Every PPA number we have quoted is provisional

Prompted by a near-miss: `d_nw01`'s reference area was about to be set against
the second source's to yield *"the second source is 85 % larger"*. The
reference's surviving build has **`wns = −0.216 ns`** — it failed its own gate,
and rule 6 forbids the number. It was caught only by checking the live directory
rather than trusting it.

That is the **second** time the live flow directory has held output from a
different experiment than the one being reported (after P4). The first was a
table cell. This would have been a headline.

So every previously quoted PPA number was audited. **The result is worse than
expected and simpler than expected.**

### There is exactly one run record in the repository

`runs/` holds a single `sim` record, carrying no PPA fields at all. The immutable
record landed after the measurements. **Therefore no PPA number in this project
is traceable to a run record — not one.** Every figure ever quoted was read from
`~/tools/OpenROAD-flow-scripts/flow`, a directory that holds whatever ran last.

`collect_results.py` is already honest about this: it prints `--` for every PPA
column and lists `d_nw01_axi4_xbar` as ABSENT. **The stale numbers survive only
in prose** — this file, the catalog, and the per-task notes.

### The audit

Corroboration = does the surviving flow directory still show that number, from a
run that passed its own gate?

| number | quoted in | record? | corroboration |
|---|---|---|---|
| d_ca04 cand **14 644** | `NOTES.md` | no | **matches**, wns +1.219 |
| d_ca04 ref **19 887** @4.5 ns | `NOTES.md` | no | **matches**, wns +0.790 |
| d_nw01_nolat **100 277** | `TASK_CATALOG.md`, `NOTES.md` | no | **matches**, wns +0.052 |
| d_ca04 ref **19 942** | `NOTES.md` | no | **conflicts** — dir shows 19 887 |
| d_ca04 cand **14 754** @4.5 ns | `NOTES.md`, `FINDINGS.md` | no | **conflicts** — dir shows 14 644 at 4.5 ns |
| d_ca04 ref **20 101** @2.625 ns | `NOTES.md`, `FINDINGS.md` | **YES, rebuilt** | **REBUILT: 20 101 exactly**, wns +0.032, DRC 0 |
| d_nw01 ref **154 245** @5.25 ns | `FINDINGS.md`, `TASK_CATALOG.md`, `NOTES.md`, `task.yaml` | **YES, rebuilt** | **REBUILT: 154 245 exactly**, wns +0.037, DRC 0 |
| d_nw01_ss **294 555** @9.0 ns | this session | no | was +0.0037; dir since wiped |

Three corroborate exactly. Two **conflict** with the only surviving evidence.
Three are unverifiable because the directory was overwritten.

**Update — the first rebuild vindicates the number and not the process.**
`d_nw01`'s reference was rebuilt at 5.25 ns and returned **154 245 µm²
exactly**, wns +0.037, DRC 0, now carrying a run record. The withdrawn
figure was never wrong; it was undefendable. Both things are worth saying at
once: the audit was not alarmism about fabricated numbers, and the
withdrawal was still correct, because *"it later turned out to be right"* is
not a property you can rely on before doing the work.

**CORRECTION TO THIS AUDIT — the "conflict" verdicts were partly my error.**

The d_ca04 reference was rebuilt at 2.625 ns and returned **20 101 µm² exactly**.
The row above had it as unverifiable, and the two rows marked *conflicts* were
reached by comparing a quoted number against whatever the flow directory held —
**without establishing which clock period that directory's run was at.** For
`d_ca04_async_fifo_cdc` the surviving run was at 4.5 ns, so "19 887 vs 20 101"
was never a conflict: it is the same design at two different periods, exactly as
the notes said.

That is the same mistake the audit was written about, committed inside the audit:
**two numbers compared without checking they are the same measurement.** The
audit's conclusion survives — no PPA number was traceable to a run record, and
that was worth fixing — but its per-row verdicts were sharper than the evidence
supported, and "conflicts" should have read "not comparable as read".

The lesson is narrower and more useful than the original framing: a flow
directory does not tell you what it is a run *of*. It has no period, no
configuration and no provenance in it. Reading a number out of it is not just
unrepeatable, it is **unlabelled** — which is why a run record has to carry
`clk_period_ns`, and why comparing across records without matching that field
would reproduce this error with full provenance in place.

**The remaining conflict to settle**, because both feed the d_ca04
area-versus-Fmax conclusion, and `20 101 / 14 754 = 1.362` is the ratio that
conclusion is stated as.

### What is and is not affected

**Fmax is unaffected.** Every Fmax comes from a `fmax_results/*.json` written by
the sweep itself, with its own classification and validity check. Those are
records, and they were checked: all six report `fmax_invalid_reason: null`.

**Every area, power and elasticity figure is provisional** until rebuilt. That
includes the elasticity comparison (+1.5 %, +5.0 %) in full, since both derive
from areas in the conflicting or unverifiable rows.

### Why the apparatus did not catch this

Rule 8 was written and the tooling built, but **the tooling was never made the
only path.** `collect_results.py` reads records correctly and reports ABSENT
correctly — and it was simply bypassed, because reading the flow directory
directly still worked and produced a number that looked identical.

**A rule enforced by a tool nobody is obliged to use is a convention, not a
control.** The fix is not another rule: it is that `ppa_candidate.sh` must be the
only way a PPA number is obtained, and that anything else refuses. The
`provisional_` refusal added to `collect_results.py` is the first half of that.

**Rules:** 6, 8

## F21. The fix for F20 was itself recording the wrong numbers

F20 concluded that `ppa_candidate.sh` must become the only way a PPA number is
obtained. **Its record writer had two parsing defects**, found on the first
record ever written through it:

| field | parsed | actual | cause |
|---|---|---|---|
| `wns_ns` | `0.00` | `0.46` | matched `wns max`, the negative-slack summary, which reads `0.00` for **every passing run** |
| `power_w` | `9.35e-08` | `3.04e-02` | took column `$4` of the power table — **Leakage**, not Total. Understated by five orders of magnitude |

The WNS defect is the worse of the two, and not because of the lost margin.
`find_fmax.py` reads `worst slack max`; the record writer read `wns max`. **The
two authoritative paths disagreed about what WNS means**, so a sweep and a run
record could report different slack for the same build and both be "the tool's
own classification" under rule 7.

Neither is detectable from the record. `wns_ns: 0.00` is exactly what a design
closing with no margin looks like, and a power figure is only obviously wrong if
you already know the right order of magnitude.

**Found by** cross-checking the record against `6_report.json` immediately after
writing it — not by any check, and only because F20 had just made provenance the
active concern.

**The general shape is the one to carry:** the remedy for an untrustworthy number
was a tool that produced an *authoritative* wrong number, which is strictly
worse. A provisional number invites checking; a record does not. **Promoting a
path to authoritative raises the cost of its bugs**, so the promotion has to
include validating it against a second reading of the same run — which is what
`6_report.json` provided here, and which nothing required.

**Rules:** 7, 8

## F22. A task whose every result was produced outside the scored path

`d_dsp02` has **no `ref/sim_flags_verilator.txt`** — the file absent entirely,
not empty. It is the only design task without one, and it is not referenced by
`sim_candidate.sh` or `ppa_candidate.sh`. **It cannot be scored.**

Every result reported for it — 4290/4290 vectors, six mutants each failing on its
own defect, the second source passing after three adjudications — was produced by
**ad-hoc Verilator invocations assembled by hand for each run**. The simulations
are real and the numbers are correct as far as they go. What is missing is that
none of them came from the path that scores a submission.

That path is not a wrapper. `sim_candidate.sh` applies the six-token leak check,
the slang synthesis gate, NBSP normalisation on a copy, and refuses unregistered
config lists. **None of it ran.** So the task's results carry the properties I
verified and none of the properties the harness exists to enforce.

Same family as P2, where `nw_d01`'s empty `sim_flags` meant its reference had
never simulated at all — and different in the way that made it survive longer.
P2 announced itself as a failure. This announces itself as nothing: the ad-hoc
runs pass, the output looks like the harness's output, and the task reads as
finished. It was found only when the absent file blocked the ORFS config, which
needs the same dependency closure.

**The task is not finished and should not be described as built.** The build
prompt's step order puts the harness wiring before the measurement, and it was
taken out of order — the interesting work (oracle inversion, mutants, second
source) was done first and the plumbing deferred, which is exactly the order that
leaves a task looking complete while being unscoreable.

**Rules:** 10

## F23. Area-delay elasticity retired — a mechanism that never changed an answer

**The area-delay precondition is withdrawn as an objective.** Rule 9 already
excluded area × delay as a scoring axis and required elasticity to be tested per
design rather than assumed. The elasticity programme existed to answer one
question behind that: *does area × delay carry information beyond area and Fmax?*

**It does not, on the evidence available.** Two designs came back inelastic, and
the axis they would have justified was already excluded. The measurements were
sound and the conclusion they support is that the mechanism is inert.

Retiring it costs nothing that was being used, and the three-way comparison it
was heading toward is **cancelled rather than completed** — no rebuild will be
done to finish it.

**Why this is recorded as a finding rather than deleted.** A plausible mechanism
that never changed an answer is a result, and an unusually easy one to lose:
there is no failure to point at, so the natural outcome is that it quietly stops
being mentioned and gets reinvented later. The same reasoning retired diff rate,
and both belong in the same drawer — **ideas that survived on plausibility until
someone measured whether they moved anything.**

The distinction worth keeping: diff rate was retracted because it was
*actively misleading* — it rated the most valuable mutant in the project as
unremarkable. Elasticity is retired because it is **inert**, which is a weaker
verdict and a different one. An inert metric is not wrong; it is overhead.

**What survives as data.** `d_nw01_ss` measured **+8.1 %** across its closing
range, both endpoints carrying run records and both passing their gate — the
first elasticity figure in the project computed entirely from records. It stands
as a properly recorded measurement of a real property. **It is simply not in
service of anything now**, and it should not be cited as evidence for an
area-delay axis that no longer exists.

Provisional elasticity figures elsewhere (+1.5 %, +5.0 %, the retracted +17.6 %)
stay marked as provisional. **They are not being rebuilt**, because the objective
they served is retired — but the numbers that *feed* them are still being
rebuilt, for provenance rather than for elasticity. See F20.

**Rules:** 9

## F24. Candidates and references were not synthesised against the same target

**Every `d_ca04` candidate was built with ABC unconstrained while the reference
was built at 5000 ps.** The comparison was not like-for-like.

**Measured impact on this task: none.** The candidate was rebuilt with the ABC
target corrected to the reference's 5000 ps and returned **byte-identical**
results — area 14 685, wns 0.706029, power 7.30e-03, matching the broken build in
every digit. The design closes at 4.5 ns with +0.71 ns of slack, so ABC's mapping
target never binds, and downstream resizing dominates whatever ABC chose.

That is the honest headline and it is two claims, not one: **the defect is real
and would bite a timing-constrained design; on this design it changed nothing.**
I initially reported it as invalidating d_ca04's result. It does not. What it
invalidated was the *guarantee* — the comparison was sound by luck rather than by
construction, and nothing in the apparatus could have told the difference.

`ppa_candidate.sh` generates the candidate's config rather than copying one,
which is correct and was itself a fix for a real defect. But one generated line
was hardcoded:

```make
export ABC_CLOCK_PERIOD_IN_PS := $(shell awk '/^set clk_period/{...}' $(SDC_FILE))
```

`d_ca04` is a **two-clock** design. Its SDC declares `wr_period` and
`rd_period`; there is no `clk_period`. The awk matched nothing, the variable
came out **empty**, and ABC mapped the candidate with no timing target while the
reference's own config — which reads `wr_period` — mapped at 5000 ps.

**The script printed a claim of comparability in the same run:**

> *"A candidate is only comparable to that baseline if the clock period and
> parameters match — both come from the task's own SDC, so they do."*

That sentence is false for any task whose SDC does not use the literal name
`clk_period`, which is every multi-clock task. `d_nw01` is single-clock and
unaffected, which is why nothing looked wrong for two tasks running.

**Found by** chasing a 0.47 % discrepancy that turned out not to be the cause of
anything — the rebuilt candidate differed from the quoted figure, the RTL hash
was byte-identical, so the remaining variable was the build, and diffing the two
configs field by field exposed it. **The discrepancy was noise; looking into it
was not.**

**Fix:** the ABC line is now **copied verbatim from the task's own `config.mk`**
rather than re-derived, and the script **refuses to build** if that line is
absent. Re-deriving a value the task already states is the defect; there was
never a reason to compute it twice. Verified: the regenerated config carries
`wr_period` and resolves to 5000 ps.

**The 0.47 % that started this is unexplained, and the obvious alternative was
tested and falsified.** The rebuilt candidate is 14 685 against a quoted 14 754,
with a byte-identical RTL hash and a byte-identical build target.

The natural hypothesis was that 14 754 belonged to **the other d_ca04
candidate** — read from the unlabelled flow directory at a moment when
`gemini.sv` had last built there. That fits the evidence shape exactly, and it
would have made this the cleanest instance of F20 available: a number that was
accurate, recorded nowhere, and belonged to a different design entirely.

**It was built and it does not fit.** `gemini.sv` at 4.5 ns through the
validated path is **14 515 µm²** (wns +0.713) — 1.62 % from 14 754, further away
than `chat.sv` is. So 14 754 is neither candidate's area at this period.

Recorded as unexplained, with the alternative **tested rather than merely
unavailable**. What is established: 14 685 is reproduced twice, recorded and
validated; 14 515 is recorded and validated; 14 754 corresponds to no build
reproducible from this tree. The three candidate explanations that remain are a
different tool version, a different config predating the current one, or a
transcription error, and none is distinguishable now that the directory it came
from is gone.

**That is the residue F20 predicts.** An unlabelled number is not merely
unverifiable — once the directory turns over, it becomes *permanently*
undecidable. No amount of later rigour recovers it.

**The general form, and it is the sharpest instance in this document.** A
generated config is only equivalent to the one it stands in for if *every*
field is. This one differed in a single line, produced no error, and the
resulting number was plausible, gated, DRC-clean and comparable-looking. The
provenance audit (F20) would never have caught it: the numbers had records, the
records were accurate, the runs passed their gates. **Provenance tells you where
a number came from, not whether two numbers may be subtracted.**

**Rules:** 9

## F25. `\b` in sed is a silent no-op on macOS, and it hid a dead harness

The verification scoring path substitutes a conformant perturbation in place of
the golden DUT by renaming modules. The renames were written with `sed
"s/\btag_tracker\b/..."`.

**BSD sed does not support `\b`.** It matched nothing, substituted nothing, and
exited 0. So `variant.sv` was the unmodified golden, the perturbation modules
kept their own names, and the submitted testbench — which instantiates
`tag_tracker` by name — bound to the golden **on every row**.

Four of the five DUT rows were running the same design, and the table looked
like this:

```
  golden                     PASS
  tt_c1_match_gnt_freerun    PASS
  tt_c2_pop_data_garbage     PASS      <- actually the golden
  tt_c3_push_gnt_throttled   PASS      <- actually the golden
  tt_c4_pop_gnt_delayed      PASS      <- actually the golden
```

**Two negative controls were run, and only one had any power.** A crude control
— a testbench that reports FAIL unconditionally — was correctly rejected, and
made the harness look validated. The real control was a testbench relying on
*unpromised behaviour*: it asserts `pop_data_o == 0` when invalid, which the
golden satisfies and `c2` deliberately breaks. It was **accepted**, and that is
what exposed the dead substitution.

**A control that fails everything validates almost nothing.** It cannot
distinguish "the harness discriminates" from "the harness reports whatever the
submission says", because a submission that always fails produces the same table
either way. This is rule 3's *"a control that trips two checks validates
neither"* in a new shape: **a control that trips every check validates none of
them.** The useful control is the one that must pass some rows and fail exactly
one.

There is a second, independent instance of the same hazard in the same function.
The rewrite must retarget the inner instantiation **before** renaming the module
declaration; done in the other order, the declaration is renamed to `tag_tracker`
and then caught by the instantiation rewrite, producing a module called
`tag_tracker_golden` that collides with the real golden — a different mechanism
producing the identical symptom.

Renaming now happens in `scripts/_verif_variant.py`, where `\b` means what it
says, and the ordering constraint is stated in a comment next to the code that
depends on it.

**Rules:** 3

## F26. Three documents asserting a control that did not exist

`check_rule_linkage.py` and `check_ppa_record.py` both stated, in their own
headers, *"Runs with the regression."* **There was no regression.** No runner, no
target, no CI — the phrase was referenced in `RULES.md` and `TASK_CATALOG.md` as
though it named something, and both checks were in fact run by hand when someone
remembered.

This is the third instance of one pattern, and it is worth naming as a pattern
rather than filing each as an oversight:

| | the document said | reality |
|---|---|---|
| **F19** | `RULES.md` is the single source of truth | a stale seven-row rule table sat in `FINDINGS.md` with its own numbering |
| **F22** | `d_dsp02` is built and its results stand | no `sim_flags`, never once run through the scored path |
| **F26** | these checks run with the regression | there was no regression |

**The common shape: prose asserting a control, and the prose being the only
place the control existed.** Every one of them reads as true. Nothing fails.
The claim is load-bearing for a reader's trust and carries no weight at all.

**Why this class is hard to see from inside.** A missing artefact announces
itself the moment something tries to use it — but nothing *tries to use* a
sentence. The assertion is consumed by humans, who take it at face value
precisely because it is written down in a document that has been accurate about
everything else. The three instances were found by three unrelated accidents:
diffing an edit, an absent file blocking a build, and going to wire a check into
the regression and finding none.

**The remedy is not more careful writing.** It is that a document may not assert
a control exists without naming the artefact that implements it, and the
artefact must be executable. `scripts/regression.sh` now exists and runs all
three checks; the headers that referenced it are now true.

**What this does not fix:** nothing prevents the next such sentence. The honest
statement is that this class is currently caught by accident, and three
accidents is not a detection mechanism.

**Rules:** 13

## F27. F20's lesson did not generalise, and the same defect recurred

F20 concluded, in this document, that **"a rule enforced by a tool nobody is
obliged to use is a convention, not a control."** The next control built after
that sentence was written repeated the defect exactly.

`ppa_candidate.sh` had **no check that a passing correctness record existed**.
The rule *"PPA only for a submission that passed correctness"* lived in
`run_submissions.sh`, the driver. Calling the tool directly bypassed it in
silence — and I did exactly that while testing the 0.47 % hypothesis, producing
`d_ca04/gemini.sv` with area, power and WNS recorded and **no correctness
verdict at all**, sitting in the results table looking like a result.

**Why the lesson failed to transfer.** F20 recorded the conclusion *about rule 8
and `collect_results.py`* — a specific tool that had been bypassed. It did not
state the general form: **a control must be enforced at the tool boundary, not
in a wrapper that calls the tool.** So the next control was placed in a wrapper,
and nothing in the written record objected.

That is a finding about how findings fail. A lesson recorded at the level of its
instance does not fire on the next instance, because the next instance does not
look like the first — different tool, different rule, different failure mode,
identical structure.

**The test that would have caught it, now in rule 8:** *can this control be
skipped by calling something one level down?* If yes it is a convention,
whatever the document says.

**Fixed:** the gate now lives in `ppa_candidate.sh`, matched on the submission's
**content hash** so an edited file must re-pass. `--no-correctness-gate` exists
for deliberate exploration and stamps `correctness_gate=BYPASSED` into the
record; collection shows every record predating the gate as `!ungated` rather
than silently clean.

`d_ca04/gemini.sv` subsequently passed 18/18, so its numbers were legitimate.
**Nothing established that at the time**, which is the defect — the number was
right by luck, and luck is not a control.

**Rules:** 8, 19

## F28. The record writer dropped metric names, colliding every structured metric

`crossing_latency_rdclk` read **ABSENT** in the results table for `d_ca04`. It
was not a stale record: it read ABSENT on a **fresh run, 0 of 18 configurations**,
while the checker emitted it on every one.

The checker prints:

```
METRIC: crossing_latency_rdclk min=3 max=71 n=1184 (SYNC_STAGES=2)
```

a bare **name** followed by `key=value` fields. The record writer captured only
`key=value` pairs, so it **discarded the name** and filed the values under the
bare keys `min`, `max`, `n`.

**This is a collision, not a loss.** Those keys are generic. Any other metric in
any other task emitting `min=` or `n=` would overwrite them, and the surviving
value would be from whichever metric printed last — with no indication that a
substitution had happened. `crossing_latency_rdclk` is where it was noticed; the
defect is in the shared writer and applied to **every structured metric in every
task**.

**The class is the one this document keeps recording:** the quantity was
measured correctly, printed correctly, and destroyed in the reporting path. The
simulation was right the whole time. Nothing errored.

**Found by** asking which of two explanations applied — stale records or an
untaken path — and running one fresh scoring to distinguish them. Neither was
the answer, and that is what pointed at the writer.

**Fixed:** a leading bare identifier now prefixes its fields, so the metric
appears as `crossing_latency_rdclk_min` and cannot collide. The bare name is
also kept addressable. `d_ca04` reports `lat.min` and `lat.max`.

**Rules:** 8

## F29. The C1 capacity floor was derived from a model that is wrong

`d_nw01`'s checker documents the anchor reaching **`MAX_TRANS + 1`** outstanding
transactions, and sets the C1 floor at `ceil(MAX_TRANS/2)` to leave "margin on
both sides at MAX_TRANS=8: anchor 9, no-cut anchor 7, floor 4".

**The anchor delivers 27 at `MAX_TRANS=8`, not 9.** Swept on the reference:

| `MAX_TRANS` | measured | `MAX_TRANS+1` |
|---|---|---|
| 2 | **3** | 3 |
| 4 | **11** | 5 |
| 8 | **27** | 9 |

The measurement is **linear with slope 4** — `4·MAX_TRANS − 5` fits all three
exactly — and is **independent of geometry**: 27 at `NUM_SLV` 2 and 4, at
`NUM_MST` 2 and 4. `MAX_TRANS + 1` is right at `MAX_TRANS=2` **by coincidence**,
because `4·2 − 5 = 3 = 2 + 1`. One point of agreement, and the model was built
on it.

**What this costs.** The C1 floor at `MAX_TRANS=8` is 4, chosen to sit roughly
half way to an expected 9. Against an actual 27 it leaves **6.75× margin**, not
2×. A submission delivering a quarter of the reference's capacity passes C1
comfortably — which is close to what happened: `chat` measures 8, passes the
floor of 4, and sits 3.4× below the reference.

**Why the number is still comparable and the label still was not.** Every design
is measured by the same harness at the same configuration, so `27` against `8`
is a real difference. What was wrong was calling it "outstanding transactions":
under a slope-4 relation the figure is not a count of concurrent transactions,
and a reader given that label would have read a 3.4× capability gap as
3.4× fewer transactions in flight. It is a buffering difference — the reference
carries `CUT_ALL_AX` channel registers and the submission does not, which
`task.yaml` had already recorded for the second source as *"NO channel
registers, so exactly MAX_TRANS observable outstanding"*. **The project knew the
anchor exceeded `MAX_TRANS`; it was wrong about by how much, and the floor
inherited the error.**

**Found by** refusing to publish a label for a number whose own checker
predicted something else, and sweeping to settle it. `MAX_TRANS=4` is rejected by
the checker's parameter guard, so the sweep ran on a scratch copy with the guard
relaxed — a diagnostic, not a change to the scored artefact.

**Not yet fixed.** Raising the floor is a scoring change and needs deciding
separately; the sweep establishes the shape, not the new floor.

**Rules:** 1, 20

## F30. A spec change silently converts old submissions into failures

`d_dsp02/chat.sv` measures **latency 1** where spec clause S1 requires 3, and
the results table rendered that as *"does not implement the scored
configuration"* — which reads as a defect in the submission.

**It is not.** Git settles it:

| | date |
|---|---|
| `chat.sv` submitted | **2026-08-15** |
| S1 latency requirement added | **2026-08-16** |

And the spec at the moment of submission said, in capitals:

> *"LATENCY IS NOT CONSTRAINED AND NOT CHECKED. Pipeline as deeply as you like."*

**The submission complied completely with the specification it was given.**
Latency 1 was not merely permitted, it was explicitly invited. Scoring it
against S1 measures the spec change, not the model.

**The general form, and it applies to every task here:** a specification change
retroactively converts prior submissions into apparent failures, and nothing in
the apparatus notices — the checker is silent on S1 by design, the metric reads
correctly, and the comparison against `expect` fires exactly as built. Every
component behaves properly and the conclusion is still wrong about the model.

This is the third variety of the pattern this document keeps recording. The
first two were a measurement that measured nothing, and a report that invented a
value. This one is **a correct measurement compared against the wrong contract**.

**Consequences adopted:**

1. **A submission is scored against the spec it was given.** Where the spec has
   since changed, the row says so and names both dates; it does not render as
   non-compliance.
2. **A spec change requires re-soliciting**, not rescoring. `d_dsp02` needs
   re-prompting before it carries a scored latency result, because no submission
   in hand has ever seen S1.
3. Rule 18's pinning made this visible rather than causing it — before pinning,
   the mismatch had nothing to be measured against.

**Rules:** 18

**Class:** contract defect. The apparatus was correct throughout.

## F31. A resource limit that looks exactly like a design failure

`d_nw01/chat` place-and-route died in detailed routing after 1 h 40 m:

```
[INFO DRT-0195] Start 3rd guides tiles iteration.
    Completing 10% with 75 violations.
    elapsed time = 00:00:00, memory = 5476.98 (MB)
Peak memory: 5702896
make: *** [do-5_2_route] Error 247
```

No OpenROAD error, no assertion, no message. **Docker `MemTotal` is 5.8 GB and
the run peaked at 5.702 GB.** It was killed at the container ceiling. The host
has 16 GB; the limit is a Docker Desktop allocation.

**Why this is dangerous rather than merely annoying.** Every available signal
points at the design:

- it died in *detailed routing*, which is where a genuinely unroutable design
  dies;
- it had **75 DRC violations** outstanding, so "failed routing with violations"
  is a completely plausible reading;
- `d_nw01`'s history contains a real instance of exactly that — the re-solicited
  candidate failed detailed routing at 2003 violations;
- exit 247 is not a signal code, so nothing announces a kill.

The one thing that distinguishes them is the memory number against the container
limit, and it appears in the log as an unremarkable stage summary. **Read that
routing failure without checking it and you conclude the candidate cannot be
routed.** It was at 75 violations and still improving.

**What it is not:** it is not a build failure under rule 19, and it must not
score zero. Rule 19 is for failures *confirmed genuine* — `d_nw01/gemini`
qualifies because two independent frontends reject its syntax. A design killed by
a memory limit has not been shown to fail anything, and scoring it zero would
attribute an apparatus limit to a model.

**What it renders as:** absent, with the reason named — per rule 20, a value not
measured for that design renders absent, and here even the *reason* for absence
had to be established rather than assumed.

**The compounding cost, caught before it was paid.** An Fmax sweep runs the same
place-and-route at every period. Queued unattended it would have hit the same
ceiling nine times over — roughly fifteen hours to produce nothing, and a
`fmax_invalid_reason` at the end that says the sweep did not converge rather than
that the machine ran out of memory. It was withdrawn from the queue.

**Unresolved and outside the apparatus:** raising Docker's allocation is a host
setting. Until then `d_nw01`'s largest submission has no PPA, and that is a
limit of this bench rather than a property of the design.

**Rules:** 19, 20

## F32. The regression was red and I committed anyway

`scripts/regression.sh` exists, runs in about a second, and was invoked in the
same command as the commit. It printed **REGRESSION FAILED**. The commit went in
regardless, because the commit followed the check in one shell line and nobody
read the output between them.

The failure was real: `sim_verification.sh` had just started writing run records,
and a verification record has no `configs_passed`, so `collect_results.py`
crashed on every invocation. The whole results table was broken and the commit
message said the work was done.

**This is the same shape as three earlier findings and it deserves its own
entry rather than a note on the commit:**

| | the control | how it was bypassed |
|---|---|---|
| F20 | rule 8, collection reads records | reading the flow directory still worked |
| F27 | PPA needs a passing correctness gate | the gate lived in the driver, not the tool |
| F15 | diff rate was retracted | the retraction never reached the build prompt |
| **F32** | **the regression** | **it ran, printed FAILED, and was not read** |

The first three are a control that was absent, misplaced, or stale. **This one
was present, correct, in the path, and produced the right answer** — and the
answer was not consumed. That is a distinct failure mode and the hardest of the
four to engineer against, because every component worked.

**"We built the control", "the control is in the path", and "the control is
read" are three different claims.** This project has been careful about the
first two and had not distinguished the third.

**What actually fixes it** is not resolve. Chaining a check and a commit in one
command makes the check advisory: the shell runs both regardless of the first
one's exit status unless something enforces the dependency. The fix is
mechanical — `&&` rather than `;`, or a pre-commit hook — and it is the same
lesson as rule 8's tool boundary, one level up: **a control whose result nothing
consumes is decoration.**

Recorded rather than quietly fixed because the near-identical structure across
four findings is the signal. The failure keeps being about the *path* the check
sits in rather than the check itself.

**Rules:** 8

## F33. The 6.4x area gap is not the multiplier, and is not yet quotable

`d_dsp02/chat` placed at **440,336 um2** against the reference's **68,303** --
6.4x. Every large ratio in this project has so far decomposed into off-spec
configuration, capability gap and genuine difference, with the last share near
zero twice. This one was put through the same three checks before being
reported, and the third stops it.

**1. Off-spec configuration: NO.** `chat` measures `latency_cycles=3`,
`init_interval=1`. It implements S1. This is the first submission that does, and
it is why the comparison was worth attempting at all.

**2. Rule 17 comparability: FAILS -- and this is the blocker.** The reference's
PPA record predates the build-config hash, so `compare_ppa.py` returns
**UNCOMPARABLE** rather than a ratio. **The 6.4x is therefore not currently
quotable**, and the reference is being rebuilt to produce one. Rule 17 was
written after F24, where two builds differed in ABC target and every other
signal said they were comparable; this is its first live use on a headline
number and it refused it.

**3. Structural decomposition: the interesting part, and it is not what it
looks like.**

| | reference | `chat` | ratio |
|---|---|---|---|
| full adders | 485 | **486** | **1.0x** |
| half adders | 276 | 2,209 | 8.0x |
| muxes | 330 | 2,597 | 7.9x |
| flops | 263 | 724 | 2.8x |
| total cells | 5,928 | 41,093 | 6.9x |
| sequential share of area | 13.3 % | 5.5 % | — |

**The multiplier is not the difference.** 485 against 486 full adders is the
same 24x24 partial-product tree, almost cell for cell -- the obvious hypothesis
(a naive non-Booth multiplier) is wrong, and would have been an appealing thing
to write down.

The excess is in **shifting and small-adder logic**: eight times the half
adders, eight times the muxes. That is the signature of **unshared barrel
shifters** -- alignment and normalisation each built their own mux tree instead
of sharing one -- plus replicated increment logic, which is what a
speculate-and-select rounding scheme costs if both candidates are computed with
independent adders rather than one adder and a select.

Note the sequential share *falls*, 13.3 % to 5.5 %: `chat` has 2.8x the flops
but 6.9x the cells, so the design is not register-heavy. It is combinationally
wasteful, which is a different and more fixable problem.

**Why this is worth stating precisely.** "6.4x larger" invites the reading that
the model cannot build an FMA. It built the hard part -- the compressor tree --
at parity with a production implementation, and lost the area in structure
sharing around it. Those are very different statements about capability.

**Rules:** 9, 17

## F34. Four outcome types, and Block 4 must not collapse them

Submissions have produced four distinct outcomes. They mean different things
about the model and a single pass/fail column destroys the distinction.

| outcome | what happened | what it says about the model | PPA |
|---|---|---|---|
| **PASS** | compiles, meets the contract on every config | it solved the task | measured |
| **build failure, both frontends** | slang *and* Verilator reject it | it did not produce valid SystemVerilog | zero (rule 19) |
| **build failure, one frontend** | slang rejects, Verilator accepts | it produced something one tool tolerates and the other does not; **synthesis uses slang, so it cannot be built** | zero (rule 19) |
| **correctness failure** | compiles cleanly, wrong answer at a named vector | it produced valid hardware that does the wrong thing | none — a number for a design that fails its contract is not a result |

Instances: `d_ca04/deepseek` PASS; `d_dsp02/deepseek` and `d_nw01/gemini` reject
on both; `d_ca04/kimi` rejects on slang only; `d_dsp02/gemini` fails at vector 4.

**The two build-failure rows are worth separating** even though both score zero.
Rejection by both frontends is unambiguous. Rejection by one is a claim that
needs the reason attached — and until the two-frontend requirement was written
into the task text, it was a submission failing something it had never been
told, which is F14's shape.

**The correctness failure is the most informative of the three failures** and
the easiest to under-report. `d_dsp02/gemini` compiles, elaborates, and produces
a wrong result at a specific input. That is a design defect with a witness,
which is a far more interesting outcome than a syntax error, and collapsing it
into "failed" alongside a design that would not parse loses that entirely.

**Rules:** 19

## F35. d_nw01 is not defective, and two models share one misconception

Three of four `d_nw01` submissions fail to elaborate on both frontends, one with
20 slang errors. Four independent models failing against one interface is more
likely one interface problem than four model problems, so the interface was
checked before the result was reported.

**The interface is clean.** `axi4_xbar_pkg.sv` plus `axi4_xbar_iface.sv`
elaborate with **zero errors on both Verilator and slang**, standalone. Not a
task defect, and Block 4 will not report one as a capability result.

**But the errors partly cluster, and that is the finding.** Two of three hit the
same construct:

| submission | first errors |
|---|---|
| `gemini` | `missing '(' in parameter list` — unrelated syntax |
| `deepseek` | **`no member named 'b_ready' in 'slv_resp_t'`** + a redefinition with a different type |
| `qwen` | `cannot refer to automatic variable 'i' from static initializer` + **`no member named 'b_ready' in 'slv_resp_t'`** |

**`b_ready` is in `slv_req_t`, and that is correct AXI4** — `BREADY` is driven by
the master, so it belongs in the request struct; `slv_resp_t` holds only
slave-to-master signals. The shipped package defines it that way at line 116, and
both models had that definition in front of them.

So it is a model error, not a spec ambiguity — **and two independent models made
the identical one.** That is worth reporting as a shared failure mode rather than
as two separate defects: the request/response split in an AXI struct package puts
the handshake signals of one channel on opposite sides, and reaching for
`resp.b_ready` is the natural mistake if you think of B as "the response
channel" rather than tracking signal direction.

**What this does NOT license.** It is not evidence the packaging is wrong, and it
is not grounds for moving `b_ready`: the package matches the standard, and
changing it to match a common misreading would encode the misconception into the
contract. The task stays as it is, and the shared error is a result about the
models.

**Rules:** 19

## F36. A kill count from a testbench that fails the validity gate is not a number

`v_ca05/gemini` **rejects the golden DUT and all four conformant perturbations**,
then reported catching **6 of 6** mutants. Printed beside a genuine 5/6 that
reads as the better testbench.

It is not a measurement. A testbench that rejects everything rejects correct and
faulty hardware alike, so it appears to catch every fault by construction — rule
16 in the reporting layer rather than the control layer.

**This is F20's shape one level along.** F20 was a number read from the wrong
place; this is a number computed correctly from a run that cannot support it.
Both look exactly like results.

Now suppressed at the source, with the reason printed in place of the count, and
recorded as `faults_caught=SUPPRESSED-gate-failed` rather than as a ratio. Hangs
get the same treatment: a hang is not detection, and saying so in the row is
cheaper than hoping a reader remembers.

**Rules:** 16, 20

## F37. Verification outcome taxonomy — five types, non-collapsible

Distinct from the design taxonomy in F34, and for the same reason: a single
column destroys what the results mean.

| outcome | what happened | instance |
|---|---|---|
| **PASS** | accepts the golden and all conformant, catches faults | `chat`: 4/4 conformant, **5/6 caught**, 1 missed |
| **format failure** | does not declare the module the task names | earlier `deepseek`: declared `tb_tag_tracker` |
| **did not compile** | the testbench itself does not build | `deepseek`, `qwen` — both `expecting '{`, an array-literal syntax error |
| **validity-gate failure** | rejects correct hardware; kill count suppressed | `gemini`: golden FAIL, 0/4 conformant |
| **HUNG** | no watchdog; ran forever against the starvation mutant | earlier `chat` and `qwen` |

A format failure is a failed attempt, not a harness problem — the task text names
`tag_tracker_tb` explicitly, so declaring something else fails a stated
requirement. Same treatment a wrong module name gets on the design side.

**The most informative row is `chat`'s single miss.** It caught five of six and
missed `m5`, the masked compare that ignores bits [31:24] — the same mutant our
own reference testbench missed on first use, and the one that needed a mask
covering the top byte to catch. Two independent testbenches missing the same
fault says something about which corner is easy to overlook, and a rate would
have hidden it.

**Rules:** 16

## F38. Task text needs versioning, and the hash cannot see the whole problem

`v_ca05/chat` scored 2/6 and later 5/6. Those are **not two points on a
progression** — the submission was re-solicited against a corrected prompt, so
they answer different questions. Side by side in a results table they read as
improvement.

**This is rule 17 applied to specs instead of build configurations.** Rule 17
says two PPA numbers may be compared only when their build configurations match,
asserted mechanically. The same argument holds for the thing the model was
asked: a submission is an answer to a specific text, and comparing answers to
different texts measures the edit.

`scripts/task_text_hash.py` hashes the artefacts a submission actually sees —
the spec/interface files, plus the prompt document for a verification task. Not
`task.yaml`, not the checker, not the mutants: those change *scoring*, which is
rule 18's business, while this tracks what was *asked*. Every submission record
carries it, `compare_ppa.py` refuses across differing hashes, and 42 existing
records were retrofitted where the version is recoverable.

**Six records are marked `unknown`, and they stay that way.** Back-filling
today's hash onto a record written before the text last changed would assert the
submission answered a text nobody has checked it against. Unknown is honest;
`compare_ppa.py` refuses on it just as it does on a mismatch.

### The limitation, which is larger than the mechanism

**The hash attests the task text AS STORED, not AS DELIVERED.** Checking the
`v_ca05` case exposed this: our `BLIND_TB_TASK.md` has not changed since
2026-08-15, yet the two chat submissions answer different prompts, because the
prompt was corrected *outside the repository* when the submission was solicited.
The hash was identical across both and would not have flagged them.

So it catches a spec revised in-tree, and cannot catch a paraphrase, a stale
copy, or an edit made in the chat window. **Same shape as the `refs.lock`
hashes**, which attest local state rather than upstream provenance — a real
guarantee, narrower than it first appears, and worth stating so nobody reads a
matching hash as proof two submissions saw the same words.

Closing that would need the delivered text captured at solicitation time and
stored with the submission. Not built; recorded as the gap it is.

**Rules:** 17

## F39. A lookup barrier that costs the whole submission is noise, and was removed

Two independent submissions reached for `slv_resp_t.b_ready`, failed to
elaborate, and lost their entire result (F35). The package is right — BREADY is
master-driven, so it belongs to the request struct — and it is not changing.

**The decision taken: state the channel signal directions explicitly in the
shipped package**, as a normative table citing AMBA AXI4 §A3.1.

The argument for it is what the failure measures. `d_nw01`'s stated difficulty
axes are outstanding-ID tracking, per-ID response ordering, deadlock freedom and
arbitration. **Struct membership is on none of them.** A barrier that is not on
any measured axis and costs 100 % of the score is noise in the measurement, and
removing it makes none of those four axes easier — a submission still has to
track IDs, avoid reordering, and stay deadlock-free.

Under rule 15 the table is a citable contract term rather than a hint: AMBA AXI4
fixes the directions, and the grouping into request and response structs follows
from them rather than being a free choice.

**The counter-argument is real and is recorded rather than dismissed.** It does
lower difficulty — a model that would have failed here will now proceed. The
judgement is that the difficulty removed is recall about signal direction, which
this benchmark is not trying to measure, and the alternative is a task where two
of four submissions score zero for a reason unrelated to design ability.

**The finding stands independently of the decision.** Two independent models made
the identical error, which says something about how the B channel is naturally
misread — "the response channel" is a name that invites putting all of B's
signals in the response. That observation survives the fix and is the more
transferable half.

**Rules:** 15

---

# A STATED LIMITATION OF THE RULE SET

**Every one of the 20 rules exists because something broke.** That is the
set's strength — none is speculative, each cites the finding that produced it,
and the citation graph is checked mechanically.

**It is also a hard limitation, and it should be stated rather than left for a
reader to infer: the rules have no coverage guarantee.** They cover the failure
modes we have hit. They say nothing about the ones we have not.

`d_dsp02` demonstrated this directly. It was sequenced as the first task built
under the rules from the start, precisely to test whether they were sufficient.
They were not: it produced **contract defects** (F14, F15, F16) — requirements
inherited rather than chosen, and guidance that decayed — a class the first
thirteen findings would not have predicted, because all thirteen were apparatus
defects and the remedies for apparatus defects do not generalise to contracts.

Two consequences worth being explicit about:

**The linkage checker proves the graph is complete, not that the rules are.** It
asserts every rule cites a finding and every finding cites a rule. It cannot
assert that the rules span the space of ways this benchmark can be wrong, and a
green run must not be read as saying they do.

**Expect further classes.** The right posture is that the set is provisional and
grows on contact with new task types. The rate of discovery is the signal to
watch: the first two tasks produced thirteen findings, the third produced three
more of a genuinely new kind, and a task type that produces none is the first
real evidence of saturation. **We are not there.**

**Rules:** 13, 15


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

# THE STANDING RULES

**They live in `RULES.md` and nowhere else, each citing the finding that produced
it.** This document supplies the other direction: every finding names the rule or
convention it produced, and `scripts/check_rule_linkage.py` asserts both.

*A seven-row copy of the rules stood here until F19. It had drifted to a
numbering of its own — it called "the runner names its artifacts" rule 5, where
`RULES.md` has that as rule 10 and rule 5 as the second source — so a
cross-reference to "rule 5" resolved to two different rules depending on which
document you were holding.*

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

## F40. A second DUT declared, gated on, and never actually run

**The second DUT was declared, gated, and never run.** Three verification
tasks carried `second_dut: status: BUILT_UNWIRED` with a real, independent
implementation on disk. The gate in `sim_verification.sh` checked that
`dut2/` EXISTED and passed. Nothing ever compiled against it: the `DUTS`
array held golden + conformant + mutants, and no fourth kind.

So the harness refused tasks that had no second DUT, and quietly gave full
credit to tasks that had one it never used. The status literally said
`BUILT_UNWIRED` and the gate read it as satisfied.

**This is F32's shape a second time.** "We built the control" and "the
control is in the path and is read" are different claims, and the gate
asserted the first while appearing to assert the second. Rule 8's test --
*can this control be skipped by calling something one level down?* -- does
not catch it, because the control was not skipped, it was never invoked.
The stronger test is: **does anything READ the control's output?** A gate
that proves a file exists proves nothing about whether it was used.

Fixed: `dut2` is a member of `DUTS`, its verdict is recorded separately from
the conformant tally (a conformant failure means the testbench relies on
unpromised behaviour; a dut2 failure means it is fitted to the golden's
incidental choices -- different defects, so not one number), and the gate now
resolves the declared `file:` rather than the directory.

Validated before use, as the second DUT is itself an oracle: all three
reference testbenches ACCEPT their dut2 (v_ca05, v_nw03, v_dsp02). Had a
reference rejected one, every submission failure on that row would have been
an artefact of a wrong dut2 rather than a property of the submission.

**Rules:** 8, 10
**Convention:** Controls: existence is not participation

**From:** scoring v_nw03 and v_dsp02

## F41. Half the verification compile failures are one language rule

**Half the verification submissions failed to compile, and every one of the
nine errors is the same language rule.** Across v_ca05, v_nw03 and v_dsp02,
six submissions from two models did not build. Verilator -- the frontend the
harness actually uses -- reported nine errors in total, and all nine are a
**variable declaration placed after a statement** inside a procedural block,
which SystemVerilog forbids.

Confirmed as a mechanism rather than inferred from the message, whose text
(`syntax error, unexpected IDENTIFIER, expecting "'{"`) names neither
declarations nor placement:

    task automatic t();      task automatic t();
      if (1) begin end         int unsigned x = 0;   // moved up
      int unsigned x = 0;      if (1) begin end
    REJECTED, both frontends  ACCEPTED, both frontends

**The diagnostic is the finding.** Moving that ONE declaration in
`v_nw03/deepseek` -- a single line, no other edit -- produced a testbench
that passes the golden, passes all five conformant perturbations, passes the
independent second DUT, and kills 5 of 6 mutants. That is the joint best
score any submission has achieved on this benchmark. It was recorded as
DID NOT COMPILE.

**The score stands and the interpretation does not.** The submission does not
build, so `did not compile` is the honest verdict and it is not being revised;
the diagnostic ran on a copy and is labelled as one. But a headline of "0 of 8
passed" implies these models cannot write a testbench, and at least one of
them wrote a near-ceiling testbench with a misplaced `int`. Those are
different failures and the column was reporting them as one.

A first-token error also destroys all information after it: a file that dies
at parse yields no golden verdict, no conformant tally, no kill count. **The
one outcome type that admits no partial credit is the one a trivial defect
produces**, so triviality and severity are inversely related here, which is
the opposite of what a reader assumes.

Not yet established: whether the other five decompose the same way. Only
`v_nw03/deepseek` was run as a diagnostic.

**Rules:** 19, 20

**From:** scoring v_nw03 and v_dsp02

## F42. A reference testbench named so the scored path could never run it

**v_ca05's reference testbench declared a module name the scored path could
not run, so the ceiling every submission was compared against had never gone
through the harness.** `task.yaml` requires `tb_module: tag_tracker_tb`; the
reference testbench declared `tag_tracker_spec_tb`. The harness builds with
`--top-module` from task.yaml, so the file could not be the top and was never
run through the scored path. Every v_ca05 ceiling figure before this session --
including the 6/6 that submissions were reported against -- came from an ad-hoc
invocation outside the harness.

**The asymmetry is the finding.** The submissions were harness-measured. The
number they were scored against was not. Both were printed in the same table,
in the same units, with nothing marking that one had a different provenance
from the other. A ratio between them was never a like-for-like comparison, and
nothing in the output said so.

This is F22's shape -- a name that has to match in two places, with no check
that it does -- on the OLDEST task in the project, found only when a later task
exercised the same path. The renaming fixes v_ca05; it does not fix the class.
Nothing today asserts that `tb_module` in task.yaml names a module the
reference testbench actually declares, so the same defect can be reintroduced
by a rename, exactly as the prompt document was dropped from the task-text hash
by a rename.

The current 10/10 is harness-measured. Ceiling figures from before this session
should be treated as unattested rather than wrong: they may well have been
right, and nothing available now demonstrates it.

**Rules:** 8, 10

**From:** Agent 2's v_ca05 scoring run

## F50. Rule 11's inversion conceals a defective anchor from inside the task

**Rule 11's inversion buys unfalsifiable expected values, and the price is that
a defective anchor is undetectable from inside the task.** Locally authored code
generates inputs; the external anchor generates expected values. That removes
the failure where a testbench author encodes their own misreading as the
expected answer. It does not remove — and actively conceals — the failure where
the ANCHOR is wrong.

**The concealment is total, and self-consistent.** If the anchor rounds
incorrectly, every generated vector inherits the defect. The reference passes,
because it IS the anchor. Every mutant is killed exactly as designed, because
each is a perturbation of the anchor measured against the anchor. The task
publishes a contract that pins the defect, and nothing in the apparatus can
notice: every internal check is a check of consistency with the anchor, and the
anchor is consistent with itself.

**This is not hypothetical.** `fpnew_divsqrt_multi` was rejected as an anchor for
three measured defects — truncation where RNE requires round-to-nearest, RDN and
RUP inverted because the divider's internal encoding differs from `fpnew_pkg`'s
and `rnd_mode` is passed straight through, and RMM with no counterpart in its
two-bit field. A sibling module in the same repository as d_dsp02's anchor.

**Semantic confirmation does not reach it.** d_dsp02 already had fifteen directed
known-answer cases chosen by someone reading the module. Those confirm the cases
that person thought to test — a superset of their understanding, not of the
specification. The defects above sit in tie-breaking and in mode encoding, which
is precisely where a reader who believes the module is correct does not look.

**The only check that reaches an anchor is an independent computation of the
same quantity**, by a route that shares no implementation with it. For d_dsp02
that is exact integer arithmetic with the IEEE-754 rules applied directly: no
floating point anywhere in the reference computation, and no library that might
share a bug with the DUT. 10,150 vectors, zero mismatches — the anchor is
confirmed. See `domains/dsp/design/d_dsp02_fp32_fma_ii1/NOTES.md`.

**The general requirement: every Class A task whose oracle computes a value
should carry one.** Where the oracle's output is computable by an independent
route, the absence of that check is a gap in the strongest claim the project
makes — that the expected values came from something nobody here wrote.

**And the check must be shown to have power before "clean" means anything.** A
comparison that would pass whatever the anchor did is not evidence. Here: the
DUT produced differing results across rounding modes on 25 of 30 directed cases,
and each of the three divsqrt defects would have failed on 25, 16 and 5 cases
respectively. A clean result from a check that could not have failed is the same
non-measurement as a kill count from a testbench that rejects everything.

**Not every Class A oracle admits this.** d_nw01's crossbar and d_ca04's CDC FIFO
have no closed-form value to recompute — their contracts are protocol and
ordering properties, not arithmetic. For those the equivalent is the second
source, which is why that control exists. The requirement is: where an
independent computation is POSSIBLE, its absence is a gap; where it is not, say
so explicitly rather than leaving the difference unstated.

**Rules:** 11

**From:** Agent 2's rejection of fpnew_divsqrt_multi; the d_dsp02 anchor audit


## F43. The anchor a task rests on can be present without ever being declared

`d_ca01`'s reference is `bsg_cache_non_blocking` and its dependency closure is
**50 files, 6 350 lines**. Of those, **one** carries a SHA-256 in `refs.lock`
(`bsg_defines.sv`) and **five** are named in `refs.manifest.yaml` -- each with a
`.v` extension for a file that is `.sv` on disk. **The anchor top is neither
named nor hashed.** The manifest's basejump list names `bsg_cache/bsg_cache.v`,
the *blocking* cache, a different module.

The file arrived because `mode: vendor` copied whole directories. So the artefact
the entire oracle rests on is present by directory-granular side effect, was
never declared, and is not under drift detection -- while `check_refs_hashes.py`
passes, because it checks the files it was given.

Found by listing what the elaborator actually pulls in and diffing that against
the two documents that claim to track it. The cheap remedy is to hash a
**closure** computed from the elaborator's own file list rather than a
hand-maintained set, so the covered set cannot drift from what is compiled.

**Rules:** 10

## F44. This harness's silence is uninformative by default

Four testbench defects on one task, each from an unrelated cause, each producing
**the identical observable: a working design that appears to stop responding.**

| | cause |
|---|---|
| 1 | polled a `ready` that depends combinationally on the `valid` being driven in the same timestep -- read the pre-drive value |
| 2 | waited on a **level flag** describing a completed transfer; it is stale for one cycle afterwards, so the waiter read the previous transaction's success and returned immediately, dropping the request |
| 3 | drove a DUT input combinationally from a DUT output. Semantically a no-op; **two builds differing only by an added debug process disagreed** about whether the anchor had jammed. No `UNOPTFLAT`, no warning |
| 4 | `force`/`release` on the memory model's gap counter -- `release` leaves the forced value in place, so the model counted 100 000 cycles down before accepting anything |

**The claim is not that four mistakes were made. It is that a harness able to
manufacture a dead-looking DUT four different ways cannot have its silence read
as evidence about the design.** This is F9's shape -- a wedged harness and a
deadlocked design emit the same thing -- generalised from the drivers to the
harness's *observation* of the handshake.

Two of the four fell out only from instrumenting; re-reading the driver looked
correct every time.

**Structural remedies, applied by construction rather than remembered:** drivers
sample and drive on a clock edge and never assign a DUT input combinationally
from a DUT output; level flags describing a completed transfer are replaced by
monotonic counters. A determinism check intended as the *detector* behind these
was built and **withdrawn** -- three perturbation axes against two reintroductions
of the defect and it never fired, and a check whose control cannot fire validates
nothing.

**Rules:** 3

## F45. A spec can advertise latitude its own interface cannot express

Rule 12 is about alternatives silently **foreclosed**. This is the inverse:
alternatives silently **offered** that the port map cannot carry.

| clause | offered | why it could not be carried |
|---|---|---|
| `d_ca01` L4 | write-through / no-write-allocate | M1/M2 make every memory transaction block-granular; the port has no single-word and no byte-masked write, so a no-write-allocate design has no legal way to send one modified word |
| `d_ca01` L6 | latency unconstrained, so a combinational hit response is legal | the scoreboard read `id_open` pre-edge, charging a same-cycle response as *"a response for an id with nothing outstanding"* |

**The detector, and it is the transferable part: enumerate every latitude clause
and try to REALISE each one against the port map and the harness.** Reading the
clause reveals nothing -- the clause is well-formed and the thing it describes is
simply absent. No control fires, because nothing is wrong with what was built,
only with what was promised. L4 was found while choosing second-source
differences; L6 was found by the audit L4 prompted, and its fix is controlled by
a zero-latency DUT that now runs with `latency min=0` and no unknown-id error.

**Rules:** 12

## F46. An argument inserted at a label position silently stripped every design task's verdict

`sim_candidate.sh` gained a `task_text_hash=` argument at the `label` position in
`607d97f`. `write_run_record.py` gates its entire verdict block on
`os.path.isdir(rest[0])`; `rest[0]` became the basename and the raw directory
moved to `rest[1]`. The test failed silently, and `configs_total`,
`configs_passed`, `all_passed`, `per_config`, `metrics` and `coverage` were **all
dropped** from every design-task sim record written afterwards.

Every design record before the change carries a verdict; every one after does
not. **And it stacked with a second defect: `collect_results.py` renders the
missing verdict as `FAIL`**, so a run that passed every configuration appeared in
the table as a failure. That is the more dangerous half -- a blank cell sends
someone to measure, `FAIL` reads as a result about the design.

F28's class in the same writer, reached by a different route: the simulation was
right, the verdict was printed, and the reporting path destroyed it. Found by
asking why a stub that had just passed 16/16 showed FAIL.

**Rules:** 8, 10

## F47. `sby` and `eqy` are installed here with no solver behind them

Checked directly in `openroad/orfs`: `yices`, `yices-smt2`, `z3`, `boolector`,
`bitwuzla`, `cvc5` and `mathsat` are **all absent**. The `smtbmc` engine
therefore cannot run **on any design** -- not a property of caches, memories or
size. The only usable engine is `abc bmc3`, on the bundled `yosys-abc`.

This is why no equivalence-checking result had ever existed in this repository,
and it was invisible because nothing had tried. `refs.lock` records the toolchain
as *"formal: eqy + sby v0.67 inside openroad/orfs:latest"* -- true about what is
installed, silent about whether it can execute. **A tool that is present and
cannot run is F26's class in the toolchain rather than in prose.**

Two further obstacles, each of which destroys a correct result:

**`aigsmt none` is required.** Otherwise `sby` reaches the right verdict with
`abc` and throws it away rendering the trace, which also shells out to the
missing solver. It reports `Could not determine aigsmt status`, `rc=16` -- a
successful proof with a failed screenshot.

**`setundef -zero -undriven -init` is load-bearing, and only the control proved
it.** Without it the two copies start at independent free values and BMC reports
the reference **non-equivalent to itself**. The control read FAIL before that
line and PASS after. Every FAIL from an unconstrained miter is worthless,
including the first one this task obtained.

Three ways to get a confident wrong answer out of a formal flow: no solver, a
good verdict discarded during rendering, and an unconstrained initial state. Only
the third is silent, and only a control catches it.

**Rules:** 3, 21

## F48. A stated position that was never written down

Work was directed on the basis of a project position asserted as settled policy
-- that testbench-only correctness overstates by 4-5x and that equivalence
checking is load-bearing from day one.

**Method: a zero-occurrence check.** `eqy`, `equivalence check` and `formal`
appear **zero times** across `RULES.md`, `CONVENTIONS.md`, `FINDINGS.md` and
`TASK_CATALOG.md`. The only occurrences in the tree are `refs.lock`'s toolchain
line and a `.sby` inside vendored CVA6. No 4-5x figure exists in any form.

**F26's class from the opposite direction.** F26 was prose asserting a control
that did not exist. This is a position asserted in *instruction*, with no
document behind it at all -- so F26's remedy, that a document may not assert a
control without naming an executable artefact, has nothing to constrain.

**The remedy that does apply: an unwritten position has no standing to direct
work, and checking is the correct response to being given one.** Not deference
and not refusal -- the check is mechanical and resolves it in under a minute.
Here it also produced the more useful answer: the premise was **backwards**.
`d_dsp02`'s six mutants each carry `witness: "vector N"` -- simulation witnesses,
the same standard the task in hand was being asked to exceed.

Worth recording because the instruction was specific, confident and quantified.
Everything about its form said it had been recovered from a decision.

**Rules:** 13

## F49. A scored configuration chosen on engineering merit can sit where the capability check is blind

`d_ca01`'s capability mutant provides 3 outstanding requests where the parameter
promises `MAX_MISSES`. Across the 16-configuration sweep it survives **all eight**
`MAX_MISSES=2` configurations and dies in **all eight** `MAX_MISSES=8` ones. The
split is exact and falls on that one parameter. At the low setting a three-deep
design *satisfies the contract* -- the check is not weak, the requirement is
simply cheap to meet. **So a pass at the low end is not capability evidence.**

Second instance after `d_nw01`'s `MAX_TRANS=2`. Two independent instances make it
a property of swept capability parameters generally: **the low end of a sweep is
where a capability defect hides.**

**The cross-task check is where the reach is:**

| task | capability parameter | scored at | discriminates there? |
|---|---|---|---|
| `d_ca01` | `MAX_MISSES` {2,8} | **8** | yes -- chosen deliberately after d_nw01's lesson |
| `d_ca04` | `SYNC_STAGES` {2,3} | **2** | **NO** |
| `d_nw01` | `MAX_TRANS` {2,8} | not pinned | n/a; its own `task.yaml` records rule 18 as unsatisfied |
| `d_dsp02` | -- | -- | no parameters |

**`d_ca04` scores at the blind setting.** F3's own table is the evidence: a probe
hardcoding two synchroniser flops reads a crossing latency of 2 at
`SYNC_STAGES=2`, identical to both correct designs, and differs only at 3.

**Read off two documents, not re-measured.** The claim is that F3's recorded
table and `d_ca04/task.yaml`'s scored configuration, placed side by side, put the
scored point where the capability check cannot discriminate. `d_ca04`'s owner
re-measures and decides. Its rationale -- two-flop is the standard answer, and
scoring at three makes every submission pay for margin most designs do not need
-- is sound engineering; it simply collides with discrimination.

**The structural point.** The measurement lives in `FINDINGS.md` and the choice
lives in a `task.yaml`, with nothing joining them. The collision is invisible
from inside either document, which is why it survived. Rule 18 tells you to
choose on engineering merit and says nothing about checking whether the chosen
point is one where the capability checks can still see anything -- amended.

**Rules:** 18

## F51. An accurate record of an invalid build passes every provenance check

Two PPA figures were published from builds that did not meet timing:
`d_nw01/chat` at 2,141,894 um2 with **-3.03 ns** of slack, and
`d_dsp02/chat` at 440,336 um2 with **-0.697 ns**. Both were quoted against a
reference that *did* close, and both ratios -- 13.9x and 6.4x -- went into the
report.

**Neither was a provenance failure, and that is the finding.** Every number
traced to a run record. Every record was accurate. Every build completed, was
DRC clean, and was correctly parsed. A pre-push audit checked all nine published
PPA figures against their records and found **zero discrepancies** -- because
there were none. The records were right about builds that were invalid.

**Provenance answers "where did this number come from". It does not answer "is
the thing it describes real".** A design that misses timing by 3 ns has an area
and a power, and they are correctly measured properties of a circuit that cannot
run at the clock it was built at. The operating point is imaginary; the
measurement of it is not.

**It was found by eye, and nearly not at all.** The d_dsp02 case surfaced only
because an audit script happened to print slack in the same row as area, and the
sign was visible. The d_nw01 case had been caught earlier and by hand. Neither
check in the harness looked at slack before rendering, so nothing would have
stopped either from being published a second time.

**Why the common-clock rule did not catch it.** Reporting area at one clock
every design can close is a separate requirement, and both figures satisfied a
weaker reading of it: they were built at the *reference's* clock, which is one
clock, applied uniformly. The defect is that "every design can close" was never
checked -- only "every design was built at". A shared period is not evidence of
a shared operating point.

**Fixed by gating on slack where the number is RENDERED**, in both renderers
independently, because a control applied by one of two readers is bypassed by
using the other. Absent or unparseable slack renders normally: treating missing
data as a negative verdict would invent a result, which is the same class of
error pointing the other way.

**Rules:** 22
**Convention:** Controls: existence is not participation

**From:** the d_dsp02 pre-push audit

## F52. Negative controls cannot see an assumption the reference and every mutant share

`d_ca01`'s checker had a latent precondition in two phases: **it treated a
response as evidence that the memory transaction had finished.** The C2 phase
warmed a line, waited for its response, then stalled the memory -- freezing its
own warming fill half-done, so the line was never installed and the "hit" the
phase depends on missed. The C1 phase asserted its stall before the previous
phase's fill had drained, leaking a miss record and leaving one fewer available.

Spec clause L6 leaves latency unconstrained, so **a design that forwards the
requested word off the fill stream answers while beats are still in flight.**
The anchor does not forward -- measured flat at 13 cycles across all four word
offsets, with a throttle control confirming the measurement responds. Neither did
any of the seven mutants, because every one of them wraps the anchor.

**So the checker was validated, thoroughly, against a population that shared the
assumption.** Reference 16/16. Seven mutants each failing their own clause, all
with bounded counterexamples. Two conformant perturbations surviving. Every
negative control fired exactly where it should. **None of it could see this**,
and the reason is structural rather than an oversight:

> **A negative control feeds the checker a BAD input. It establishes that a
> check fires when the design is wrong. It cannot establish that the check's
> PRECONDITION holds for a design that is right in an unfamiliar way** -- because
> a control that shares the assumption satisfies the precondition by accident,
> exactly as the reference does.

The independently written second source found both within two runs, by making a
legal choice on a clause the spec had explicitly left free.

**This is the argument for rule 5 that the project did not previously have.**
Before this, the second source's recorded value was as a falsifier of
over-constrained *checks* -- `d_dsp02` went three for three the other way, every
failure adjudicated "the second source is wrong", and the rule's worth was that
it prevented three loosenings. Here it did something the mutant set structurally
could not: it exposed a precondition that was never established, in a phase whose
own negative control passed.

**Neither fix loosened a check.** Both make the phase wait for the memory model
to go idle before stalling -- establishing the precondition the stimulus had
assumed. Verified afterwards, and this is the part that makes it reportable:
reference 16/16, capability mutant still 8/16 on C1, blocking mutant still 0/16
on C2, isolated C2 mutant 0/16, both conformant perturbations 16/16. Nothing
moved.

**The transferable form.** When a checker is validated only against artifacts
derived from one implementation -- a reference plus mutants that wrap it -- the
validation covers behaviour but not assumptions. Any property the reference has
incidentally is a property the whole validation population has. **Targeting the
second source at the opposite legal choice on each named latitude clause is what
converts that blind spot into a test**, and it is cheap: two runs found both
defects here.

**Rules:** 3, 5

## F53. An ascending packed mask accepts the obvious literal and selects the wrong element

`d_dsp01`'s shim bound cvfpu's format mask the way the type name invites:

```systemverilog
.FpFmtConfig ({{(fpnew_pkg::NUM_FP_FORMATS-1){1'b0}}, 1'b1})   // "FP32 only"
```

The comment is what the author meant. The code selects **FP4**.

`fmt_logic_t` is `logic [0:NUM_FP_FORMATS-1]` -- **ascending** -- and
`NUM_FP_FORMATS` is 9 in this vendored cvfpu, not the 5 the older published
version had. A literal's rightmost bit is its LSB, and in an ascending vector
the LSB is index `N-1`. So the mask set index 8, which `FP_ENCODINGS` gives as
2 exponent bits and 1 mantissa bit: a 4-bit float.

**What that produced is the part worth recording.** `max_fp_width` returned 4,
the divider elaborated as a 4-bit unit, `operands_i` narrowed to 8 bits total,
every operand was truncated to nothing, and the unit returned `0` with `Done_SO`
asserted in the same cycle as the start. It did not fail to elaborate. It did
not fail to simulate. It did not hang. **It ran, it handshook correctly, and it
answered every question with zero** -- and a capture rig reading it would have
written two thousand perfectly well-formed wrong vectors had a separate harness
bug not stalled it first.

The only evidence anywhere was one line:

```
%Warning-WIDTHTRUNC: Input port connection 'operands_i' expects 8 bits on the
pin connection, but pin connection's VARREF 'ops' generates 64 bits.
```

among **124 WIDTHEXPAND and 9 WIDTHTRUNC warnings** that the vendored tree emits
as a matter of course. Nothing distinguishes the fatal one from the noise, and
`-Wno-fatal` is required to build the tree at all.

**The transferable form, and it is not "read the typedef".** Reading the typedef
is what fixes this instance. What prevents the class is that **a parameter bound
by a literal whose meaning depends on a packing convention must be bound by
index and then CHECKED BY ITS CONSEQUENCE**:

```systemverilog
function automatic fpnew_pkg::fmt_logic_t fmt_fp32_only();
  fmt_fp32_only = '0;
  fmt_fp32_only[fpnew_pkg::FP32] = 1'b1;      // by index, not by literal
endfunction
localparam fpnew_pkg::fmt_logic_t FP32_ONLY = fmt_fp32_only();

initial if (fpnew_pkg::max_fp_width(FP32_ONLY) != 32)
  $fatal(1, "FP32_ONLY selects a %0d-bit format", fpnew_pkg::max_fp_width(FP32_ONLY));
```

Indexing alone still breaks silently if the vendored package renumbers its
formats -- which is exactly what happened between the cvfpu version this mask
was written against and the one in `refs/`. **The width assertion is the part
that survives the next version bump.**

Exposure checked across the project: `d_dsp02` binds `FpFormat` (the enum) rather
than a mask and is unaffected. `d_dsp03 multifmt_slice` and `v_dsp01
fp_cast_multi` both take `fmt_logic_t` masks and will meet this exactly.

**Rules:** 1, 20

## F54. A vendored dependency one version out of step makes a golden reference that is wrong in five of five rounding modes

`d_dsp01`'s contract was bit-exact IEEE-754 binary32 divide and square root
across all five rounding modes. Its anchor, `cvfpu/fpnew_divsqrt_multi` over
`fpu_div_sqrt_mvp/div_sqrt_top_mvp`, **implements none of them correctly.**

Measured, after F53 was fixed and against a `Fraction`-exact rounding model that
was itself first validated at 0 disagreements in 180 cases against binary64
division rounded to binary32 (safe: 53 >= 2*24+2, so no double rounding):

```
 driven |     RNE     RTZ     RDN     RUP     RMM      n     <- fraction of results
    RNE |   0.900   0.772   0.744   0.611   0.900    180        matching the model
    RTZ |   0.698   1.000   0.736   0.604   0.698    182        under each mode
    RDN |   0.737   0.715   0.419   0.914   0.737    186
    RUP |   0.738   0.786   0.909   0.428   0.738    187
    RMM |   0.701   1.000   0.679   0.652   0.701    187
```

Read down the diagonal for what was asked and across for what was delivered:

* **RDN and RUP are swapped.** `defs_div_sqrt_mvp.sv` defines
  `NEAREST=0, TRUNC=1, PLUSINF=2, MINUSINF=3`; `fpnew_pkg` defines
  `RNE=0, RTZ=1, RDN=2, RUP=3`. `fpnew_divsqrt_multi` wires `rnd_mode_q`
  straight to `RM_SI` with no remap, so 2 means "toward -inf" upstream and
  "toward +inf" downstream. Driven RDN matches the model's RUP at 0.914.
* **RMM does not exist downstream.** `C_RM` has four encodings; 4 falls through
  to `default` and truncates. Driven RMM matches RTZ at **1.000**.
* **RNE is still wrong on 10% of cases after the encodings line up.** `1.0/15.0`
  returns `3d888888` where correct rounding is `3d888889`. Not a subnormal
  effect -- 16 of the 18 RNE misses are normal/normal/normal.
* Flags are independently wrong: `x/1.0` for subnormal `x` is exact and returns
  UF and NX; a subnormal-operand division that IS inexact returns neither.
  200 of 922 in-range divisions disagree on flags.
* **Subnormal results are wrong too** -- 81 of 112 bit-exact, so the one
  capability the task was built to measure (A3) is 28% wrong in the reference.

The encoding swap is version skew: `refs/fpu_div_sqrt_mvp` is not the revision
`cvfpu` expects, and the interface between them is four untyped bits with no
overlap in meaning and no way to fail loudly.

**Why this is a finding and not a bug report.** The apparatus was working. The
spec cited IEEE 754-2019 clause by clause, the shim was thin, the capture rig
obeyed rule 11 and generated inputs only, and every expected value came from
externally-authored RTL exactly as the rule requires. **Rule 11 guarantees that
locally written code cannot invent a wrong answer. It does not guarantee that
the vendored RTL knows the right one** -- and with expected values taken from
the anchor by construction, a wrong anchor is invisible to every check that
compares a candidate against them. Mutants would have been killed, negative
controls would have failed, a second source would have been adjudicated wrong,
and the task would have shipped a scored contract whose golden answers are
wrong in four modes out of five.

**What actually caught it** was an independent model of the *contract* -- not of
the anchor -- run over the captured vectors before anything downstream was
built. That step is cheap and it is the only thing between "rule 11 was
followed" and "the answers are right".

> **Rule 11 moves the risk from fabrication to provenance. When a contract is
> pinned to an external standard rather than to the anchor's behaviour, the
> anchor is a CANDIDATE for the reference, not the reference, until its output
> has been checked against the standard the contract cites.**

`d_dsp01` is **withdrawn**, not deferred: no correctly-rounded FP divider exists
in `refs/`. `fpnew_divsqrt_th_32` is present but its `pa_fdsu_top`, `pa_fpu_dp`
and `pa_fpu_frbus` are not vendored, and there is no network. Narrowing the
contract to RTZ-only with flags out of scope is the one thing the anchor does
support -- and it is fitting the contract to the artifact, which is the
anti-pattern this finding is about.

Exposure: `d_dsp02` uses `fpnew_fma`, a different unit with vendored
dependencies, and is unaffected. The catalog's suggestion of `fpnew_divsqrt` as
a **verification** task should be read against this: the unit is a legitimate
target for a verification task precisely because it is non-conforming, but its
output must never be used as a golden reference.

**Rules:** 5, 8, 11, 15

---

## F55. A gate that anything can satisfy is not a gate

`domains/networking/verification/v_nw02_axi_atop_filter/negctl/null_tb.sv`
declares the module the task requires, drives nothing, observes nothing, never
instantiates the DUT, and prints `RESULT: PASS`. The harness scored it:

```
  golden                     PASS
  dut2                       PASS
  => VALID, with gaps in fault detection... Caught 0 of 8 faults
1 of 1 submission(s) passed the validity gate.
```

**"Passed the validity gate" was true and meant nothing.** The gate asked
whether the submission produced PASS on the golden DUT and PASS on a second
correct DUT. A file that prints `RESULT: PASS` unconditionally satisfies both
by construction. So does one that instantiates the DUT and asserts nothing. The
0-of-8 kill rate was reported as *gaps in fault detection*, framing a testbench
that tests nothing as a weak testbench rather than as not a testbench.

The gate's two conditions were both **PASS-shaped**. Nothing in it could ever
be failed by doing less work, and a condition that cannot be failed by doing
less work does not measure work.

### Why the obvious fix is the wrong one

The tempting repair is to require that the submission instantiate the DUT --
grep the source, or fail if the top module has no child instance. **This does
not work, and the reason generalises.**

Instantiation is a property of the SOURCE. Any source-level or lint-shaped
condition is satisfiable by writing the source that satisfies it, and here that
is one line:

```systemverilog
    atop_filter dut ();     // instantiated. Nothing connected, nothing checked.
```

That file passes an instantiation check and still tests nothing. The gate would
have moved from trivially satisfiable to trivially satisfiable-with-one-more-line.
This was confirmed, not assumed: the instantiate-and-ignore testbench was written
and run, and under the structural framing it would have been accepted.

> **A gate must require a property that has no source-level counterfeit. The
> only such properties are behavioural: to produce two different OUTCOMES on two
> different DUTs, a submission must actually observe something that differs
> between them.** There is no way to fake a distinction you did not make.

### The gate as built

Every submission now runs against a **gate mutant** in addition to the golden,
and must produce *different verdicts*: PASS on the golden, FAIL on the mutant.
Same verdict on both means the submission did not discriminate, and it is
**INVALID** -- a distinct state from a low kill rate, and it suppresses the
kill rate entirely rather than reporting it as a score.

The mutant is generated mechanically by `scripts/make_gate_mutant.py` from the
task's own golden DUT. It copies the module header **verbatim** and ties every
output port to `'1`.

**Verbatim, because a regenerated interface drifts.** If the mutant's port list
is reconstructed rather than copied, it can disagree with the golden's, the
mutant fails to bind, and every submission "fails" it for a reason that has
nothing to do with the submission.

**`'1`, because it must keep transactions flowing.** One rule does both jobs:
data outputs become all-ones, which is wrong under essentially any stimulus, so
a submission that checks a single data output catches it; and handshake outputs
(`valid`, `ready`, `last`, `grant`) become ASSERTED. Tying handshakes low would
make submissions HANG rather than report a mismatch, and a hang diagnoses
nothing -- Agent 2 hit exactly that at `v_nw02`, where two known-bad DUTs were
caught only by watchdog because `send_w`/`issue_ar` waited unbounded.

The port parser tracks the **last-seen direction** across commas, because
direction persists in SystemVerilog: `output logic a, b` declares both as
outputs. Matching the word `output` per item would silently miss `b`, leave it
undriven, elaborate cleanly, and produce a mutant that is only half wrong.

The mutant is identified by the explicit identifier `__gate_mutant__`, never by
position or path, and it **never enters a kill-rate numerator or denominator**.
It is not the Tier-B step 5b authoring control, which is a different artifact
serving a different purpose and may legitimately be subtle. This one is
deliberately maximally obvious: the gate is a floor, not a scoring axis, and a
subtle gate mutant produces false INVALIDs on legitimate-but-narrow testbenches,
which is the expensive direction to be wrong in.

### Validating the gate itself

This is a check whose failure mode is ABSENCE -- a broken one reports nothing
and looks identical to a clean run. It was therefore run against known-bad and
known-good input before landing:

| # | input | required | observed |
|---|---|---|---|
| 1 | `null_tb.sv` (drives nothing) | INVALID | INVALID, `golden=PASS gate=PASS` |
| 2 | instantiate-and-ignore | INVALID | INVALID -- the case a structural gate accepts |
| 3 | always-reports-FAIL | INVALID | INVALID, `golden=FAIL gate=FAIL` |
| 4 | `v_nw02` reference TB | VALID, 8/8 unchanged | VALID, 8/8 |
| 5 | `v_ca05` reference TB | VALID, 10/10 unchanged | VALID, 10/10 |
| 6 | syntactically broken DUT as the mutant | `null_tb` still not accepted | refusal, exit 2 |

Case 3 matters on its own: a testbench that always fails is caught by the SAME
condition as one that always passes. The gate requires a DIFFERENCE, so both
constant functions fail it. A gate phrased as "must fail the mutant" would have
accepted the always-FAIL file.

### What case 6 exposed

Case 6 asks whether the gate is secretly relying on elaboration failure. If the
mutant does not build, every submission fails it identically -- including
`null_tb.sv`, which would then show PASS-golden / FAIL-mutant and **satisfy the
very gate it was written to fail**.

It does not rely on that. But the first run surfaced a second defect: with a
broken mutant, `null_tb.sv` came back **`DID NOT COMPILE`** -- attributing a
harness setup failure to the submission, which compiled fine. The wrong party
was blamed, in the same units as a real verdict.

The mutant's elaboration is now checked BEFORE any submission is scored, and a
failure is a **refusal (exit 2) with nothing scored and no run record written**,
never a verdict about anyone's work. Confirmed: exit 2, zero run records.

### The shape

Three of this repository's findings are now the same shape: **a control whose
stated scope exceeds its reach, reported in the same units as a real result.**
F26 named the class. F51 was a provenance audit that could not see an accurate
record of an invalid build. This is a validity gate that could not see a
submission that verified nothing. In each case the check ran, returned cleanly,
and the clean return was read as evidence of the property it never tested.

The distinguishing question is not *does the check pass?* but *what input would
make it fail?* For the old gate the honest answer was **none** -- and that
answer was available before any submission was scored against it.

**Rules:** 8, 18, 23

---

## F56. A shell pipeline lost the verdict, and the loss read as failure

`v_nw02`'s reference testbench was scored twice from the same bytes:

```
standalone            golden=PASS   =>  VALID, catches 8/8
inside a batch        golden=FAIL   =>  INVALID, does not discriminate
```

`md5 2ebf74b2eaa295a80b29e98aa993bbfd` both times, no `$urandom` anywhere, so
the simulation is deterministic. The harness was not.

### First diagnosis, and why it was wrong

The obvious reading was that a simulation had been killed under load and so
printed no `RESULT` line. That was wrong, and it was wrong in the direction
that flatters the investigator: it blamed the environment for a defect in this
repository's own code. What actually happens is that the simulation completes
normally, writes its verdict, and **the harness misreads its own log**.

### The mechanism

```bash
set -uo pipefail                                   # line 42
...
if echo "$out" | grep -qE "^RESULT: *PASS"; then verdict=PASS; else verdict=FAIL; fi
```

`grep -q` exits the instant it matches. `echo` is still writing the rest of the
log into the pipe, takes **SIGPIPE**, and dies with 141. `pipefail` makes the
pipeline report the first non-zero status in it -- so **the pipeline returns
141 while grep matched**. Measured on the failing case:

```
DBGX v=__gate_mutant__   gp=1   gf=141   gfile=0
                                 ^^^^^^   ^^^^^^
                 pipeline: SIGPIPE        same grep, reading the FILE: match
```

The log is 97 KB and its `RESULT: FAIL` is on line 1709 of 1713. The golden's
log is 352 bytes.

**That size difference is the whole behaviour.** Under about 64 KB the log fits
entirely in the pipe buffer, `echo` finishes before `grep` can exit, no SIGPIPE
is possible, and the verdict is read correctly -- every time, for years. Above
it, whether `echo` is still writing when `grep` exits is a **scheduling race**,
which is why the same file gave different answers standalone and under load,
and why this looked like a load problem rather than a code defect.

### Two defects, and the second hid behind the first

The failed read then fell into `else`, and the `else` said `FAIL`:

- **The misread** -- a pipeline that discards its own success. The cause.
- **The default** -- `else verdict=FAIL`, which converts *any* failure to
  obtain a verdict into a verdict of failure. Not the cause, but the reason the
  misread was invisible: it produced a plausible, well-formed, entirely
  fabricated result instead of an error.

Either alone is survivable. A misread that produced no verdict would have been
noticed the first time. A default that fires only on genuinely absent verdicts
would rarely fire. Together they manufacture failures for submissions whose
testbenches print the most output, which is to say the ones doing the most
checking.

### The fix

Read the file, never a pipe:

```bash
if   grep -qE "^RESULT: *PASS" "$WORK/run.log"; then verdict=PASS
elif grep -qE "^RESULT: *FAIL" "$WORK/run.log"; then verdict=FAIL
else verdict=CRASH; CRASH_RC="$rc"
fi
```

No pipe, no SIGPIPE, no race, and no size dependence. `CRASH` is a third
outcome -- absence of a verdict, reported as `NO VERDICT`, excluded from
scoring and explicitly not counted against the submission.

Confirmed on the case that exposed it: `v_dsp02/chat` went from `INVALID -- does
not discriminate` to **VALID, 9/10**, which is what it scored before the gate
existed.

### Why nothing downstream could see it

The record was faithful. It recorded a `FAIL` that the harness had invented, so
every provenance check confirmed it, and re-reading the record only re-confirmed
it. This is F51's shape at the point of measurement rather than of reporting:
**an accurate record of a fabricated value**. It became visible only because the
new gate produced a verdict that could be checked against a known-good answer,
and that answer disagreed.

Rule 20 said of its four instances: *"all in the reporting path and none in
measurement."* That was a description of where the class had been looked for.

**Every result from the affected batches was discarded rather than filtered.**
Which rows the race hit is not recoverable, and reconstructing a corrupted
measurement is the same error one level up.

**Rules:** 8, 20, 23

## F57. A contract that cites a standard its own oracle does not implement

`d_dsp02`'s A6 and `d_dsp03`'s A7 both pinned the underflow flag as "tininess
detected AFTER rounding", citing IEEE 754-2019 clause 7.5. The vendored anchor
does not implement that rule, and neither does any other cvfpu FMA unit.

**The words are the trap.** "Tininess after rounding" names TWO INCOMPATIBLE
RULES:

* colloquially — inspect the result you DELIVERED; if it is not subnormal, no
  underflow;
* clause 7.5 — round the exact value at the destination precision with an
  **UNBOUNDED EXPONENT RANGE**, then test THAT against the smallest normal.

They agree everywhere except one band: an exact result strictly below the
smallest normal that rounds UP onto it. There the delivered result is normal
(no underflow) while the unbounded-exponent value is still tiny (underflow).
Measured on the anchor, FP32 `a=00ffffff b=3f000000 c=0`:

```
RNE 00800000 exp1 NX      RTZ 007fffff exp0 UF NX     RDN 007fffff exp0 UF NX
RUP 00800000 exp1 NX      RMM 00800000 exp1 NX
```

Identical in FP16 and BF16, and identical in `fpnew_fma` and
`fpnew_opgroup_multifmt_slice` — a house convention, not a single-file bug.

**Both specs were self-consistent and one was still wrong.** `d_dsp02`'s prose
had always said the right thing — "a result that is tiny before rounding but
rounds up to the smallest normal is NOT underflow" — and only the CITATION named
the other rule. No candidate was ever mis-scored by it. `d_dsp03` had the
citation and no such sentence, so it was ambiguous where it mattered, and its
own second source and Python model implemented the standard's reading rather
than the reference's.

> **A citation is a load-bearing contract term, not decoration. Naming a clause
> imports whatever that clause says — including the half the author did not
> mean — and where the clause and the oracle disagree, the contract has a
> requirement nobody chose.**

The fix is not a better citation. It is to state the rule LONGHAND and cite
nothing: UF iff inexact AND the delivered result's biased exponent field is
zero, with the divergence band worked per format and the departure from clause
7.5 stated as the task's deliberate choice. That is the treatment A4 already
gave canonical NaN, where IEEE permits either and the task picks one. The
difference is that A4 knew it was choosing.

Rule 15 already requires every contract term to cite an authority. This is the
case rule 15 does not cover: the authority was cited, existed, and said
something the oracle does not do. "PINNED BY THIS TASK" is a legitimate
authority and is the right one whenever the standard's answer and the
reference's answer differ.

**Rules:** 11, 12, 15

## F58. A mutant whose stated intent and actual edit diverge

`d_dsp02/mutants/mA6_underflow_before_rounding.sv` was described in its header,
in NOTES.md and in task.yaml as "detecting tininess before rounding — the OTHER
READING IEEE-754 PERMITS". Its actual edit is one line:

```systemverilog
assign flag_underflow = is_subn(raw_result) | raw_status.UF;
```

That is not before-rounding detection. It ORs "the result is subnormal" into the
anchor's own underflow, which drops the INEXACTNESS condition — it raises UF on
an EXACT subnormal result, where the reference correctly clears it. Measured
against the band vectors, all 10 of its kills land on the `EXACT` shape and none
on `BAND`.

**The kill count was never wrong.** 57 on the original vector set, reproduced
exactly. Every number in the record was accurate. What was wrong was the
COVERAGE MAP: the mutant set claimed a mutant sitting on the alternative reading
of tininess, and no such mutant existed. The clause the task believed was
guarded was unguarded, and the guard that did exist was pointed somewhere else
and scoring well.

> **A mutant's stated intent is a claim about WHAT THE SET COVERS. Its edit is
> the only thing that determines what it actually kills. When those diverge, the
> kill count stays honest and the coverage map silently becomes fiction — and
> the kill count is the thing everyone reads.**

Rule 21 requires every mutant to carry recorded evidence of non-equivalence and
pins the evidence TYPE. That evidence was present and correct here. What nothing
required was that the recorded INTENT match the edit, and no verdict changes
when it does not.

Found only because renaming the mutant required reading it. The check is cheap
and nothing was doing it: read the edit, then read the description, and confirm
they describe the same defect.

**Rules:** 3, 16, 21

## F59. A pass count is evidence only over the region the vector set reaches

Six instances this session, all the same defect wearing different hats. Every
number was arithmetically correct. Every one was read as saying more than it
said.

1. **`d_dsp03`'s anchor audit: 13860/13860 conforming.** The vector set never
   reached the underflow band — zero cases in 13860 — so the audit was SILENT
   about the one clause that turned out to be contested, not exonerating.
2. **`mA6`'s kill count: 57.** Accurate, and describing a different defect than
   the record claimed. See F58.
3. **`d_dsp02`'s second source: 4290/4290.** Agreement held over the region the
   set reached. Extending it by 50 directed vectors produced 10 failures, all in
   one shape, including wrong RESULT bits — a defect that had been there all
   along with nothing pointed at it.
4. **The first band-coverage detector.** Written to catch exactly this class, and
   it scored 10 hits per format on a set with ZERO band coverage, because
   "delivered result is the smallest normal and inexact" also matches results
   that rounded DOWN onto it. **A coverage floor whose own detector would have
   certified the absence it exists to detect.** The class is not confined to
   results; it reaches the instruments built to detect the class.
5. **`nc_d`'s isolation claim: "every kill is a BAND row, 0 result-bit
   differences".** True over the 370 band vectors, which is the only region it
   was ever measured over. Pointed at the base set, the same control killed 20
   vectors at WIDTH=32 and 30 at WIDTH=64 with zero band coverage present — a
   control failing for reasons unrelated to its target (rule 16), standing in
   for the independence that had just been removed by construction.
6. **A review acceptance issued on that claim.** Step 3 was accepted on a
   measurement scoped to the region where the claim held. This is the only
   instance where the defect reached a DECISION rather than an artefact, and it
   is the one most worth having in the record.

**The sharpest illustration is an asymmetry nobody would have predicted.**
`d_dsp02` — the task that looked exposed, whose 6 flag mismatches opened this
entire thread — HAD band coverage: those 6 mismatches ARE 6 band cases, sitting
in its original 4290 all along. `d_dsp03` — the task that audited clean at
13860/13860 — had NONE.

> **The task that looked exposed had the coverage. The task that audited clean
> had none. Clean and covered are INDEPENDENT PROPERTIES, and a pass count
> distinguishes neither.**

Rule 2 requires a coverage floor for every stated requirement and rule 4
requires floors to measure stimulus. Both were followed. Neither says what to do
about a requirement whose floor is *absent* — and absence produces a clean run,
which is indistinguishable from a covered one by the only number anyone reads.

The transferable form: **before quoting a pass count as evidence for a clause,
state the region the set reaches and show the clause is inside it.** Concretely,
that means a floor per contested clause whose failure mode is absence, validated
against a known-failing input — and for this clause it also meant checking the
floor's own detector, which is instance 4.

**Rules:** 2, 4, 5

## F60. Measurement apparatus that reports confidently while measuring something else

Distinct from F59, and worth separating: there the number was right and its
scope was misread; here the number was WRONG and nothing said so.

**Six instances this session, five of them the same shape** — the apparatus
drove and observed at edges that do not correspond to the transfer it claimed to
be watching:

1. The capture rig waited for its own input transfer, then looked for a result.
   A zero-latency design presents the result in the cycle the operation is
   accepted; the rig missed a one-cycle window and hung. Zero vectors, and
   because `$fwrite` is buffered and lost on the watchdog `$finish`, a stall at
   vector 2000 and a stall at vector 0 look identical from outside.
2. The scoring testbench latched a backpressure decision for the duration of one
   `issue()`, deadlocking against an `in_ready_o` that depends on `out_ready_i`.
   4200 of 6300 vectors lost, presenting as a candidate wedging.
3. The scoring testbench's monitor fired on the NEGEDGE, the same edge on which
   `issue()` clears `in_valid_i` with a blocking assignment. It double-counted
   transfers, slid the expected-value queue by one, and reported **6116
   mismatches against a bit-exact reference**.
4. The corner probe sampled at the input handshake — correct for the
   combinational reference, off-by-N for the 3-cycle second source. It reported
   **51 disagreements** that were entirely its own.
5. A measurement probe declared `logic iv = 1`, so it transacted during reset
   and offset every record. It reported both mutants killing **50 of 50 band
   vectors across every shape**.
6. **And one that is not a drive/observe defect at all.** A shell loop reused a
   single `--Mdir` across every artifact it measured. A failed build leaves the
   previous binary in place and `[ -x ]` still passes, so the loop silently
   re-ran the previous mutant. It reported `mCAP1_flush_to_zero` killing **6**
   vectors; the true number is **907**. It reported mA8's number under mCAP1's
   name.

**Instance 6 is the one that matters for scope.** It happened while executing an
audit whose entire purpose was catching this class, using a loop written that
same hour, in bash rather than in RTL. Any rule scoped to "probes" or to
"testbenches" would have missed it.

7. **And one caught by a CONTROL rather than by luck.** Validating this very
   finding's linkage, a test that injected a bogus rule citation to prove the
   checker sees the new findings SILENTLY FAILED TO MATCH -- the pattern did not
   occur in the file, nothing was modified, and the checker's "linkage complete"
   was vacuous. Caught by asserting the edit applied, then re-run: the checker
   correctly reported `finding F60 cites rule 99, which does not exist`. This is
   the FIRST instance this session found by a control instead of by a number
   looking implausible, and it was found by the rule this finding proposes,
   inside the step that drafted it.

**What caught the other six was luck of implausibility, not a control.** 50/50 across
every shape is obviously wrong; 6 is not. Had mCAP1's true count been 8 instead
of 907, the wrong number would have been reported, believed, and recorded — and
it would have understated a capability mutant's kill rate by two orders of
magnitude in a task's permanent record.

Every one of these was found by a number looking wrong, and a number only looks
wrong when the reader already knows roughly what to expect. That is not
available for a measurement whose whole purpose is to establish a value nobody
knows yet.

> **An apparatus that has not reproduced a known answer has not been shown to
> measure anything. Its output is a number, not a measurement.**

Rule 3 requires negative controls for checks and rule 16 requires them to be
isolated. Neither reaches the instrument doing the measuring. A rule is proposed
in `domains/dsp/design/d_dsp03_multifmt_fma/PROPOSED_RULE.md`.

**Rules:** 3, 16
