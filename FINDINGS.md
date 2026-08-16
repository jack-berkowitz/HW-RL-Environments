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
**Rule**: the runner names its artifacts explicitly and refuses when they are
absent; it never discovers them by pattern.

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
**Rule**: same as above — and every reference runs through the same gate as
every candidate, every time.

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

---

# A STATED LIMITATION OF THE RULE SET

**Every one of the fifteen rules exists because something broke.** That is the
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
