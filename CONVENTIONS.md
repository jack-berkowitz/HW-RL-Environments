# Conventions

> **The standing rules are in `RULES.md`, which is their only home.** This file
> covers house style, toolchain decisions and shared models. Where a convention
> here follows from a rule, it cites the number rather than restating it.

How testbenches are written in this project, and the toolchain decisions behind
it. Extracted from the Tier-2 build notes when the tier layout was removed; the
per-module sections that described deleted RTL were moved to
`RESULTS_ARCHIVE_V2_TASKS.md`, and this file is what remains live.

## The canonical exemplars

Two testbenches define house style. Read them before writing a new one:

| file | what it demonstrates |
|---|---|
| `testbenches/conventions/rob_tb.sv` | the full pattern at scale — constrained-random traffic, a reference model, per-transaction checking, coverage floors |
| `testbenches/conventions/fifo_tb.sv` | the same shape on a small module, readable end to end in one sitting |

Both are ~390 and ~850 lines, which is the working range: submitted testbenches
run 400–1200 lines, median around 600.

**A checker's last line is exactly one of** `TEST_RESULT: PASS` or
`TEST_RESULT: FAIL: <reason>`. Quality numbers print as `METRIC:` lines and
never gate the verdict.

## Shared models

`testbenches/common/` holds the models several harnesses include rather than
duplicate: `golden_mem.sv`, `mem_stub.sv`, `mem_line_stub.sv`,
`liveness_monitor.svh`, and `common_selftest.sv`. It is on the include path
unconditionally, so an `\`include` of any of them resolves without per-task
configuration.

`liveness_monitor.svh` is the newest and the one with the sharpest contract:
`LM_DECLARE(N)` / `LM_TICK(offered, served)` / `LM_CHECK(failtask)`, providing a
deadlock property and a starvation property measured **only while other
requesters are making progress** — so a uniformly slow design is not penalised,
only an unfair one.

## Failing runs sit in the same directory as passing ones

**Rule 6 governs.** The pothole is that nothing in a build directory distinguishes
a run that closed from one that did not — same files, same metrics, same shape.

This is easy to violate while assembling a sweep table, because the failing runs
sit in the same directory as the passing ones and look identical. An elasticity
table for `d_nw01` was first built from four periods, of which **two did not
close** — the headline "+17.6 % area" came from 3.0 ns, where the design misses
timing by 2.15 ns. The honest figure across the closing range was +5.0 %, a third
of what had been written down.

Before any number enters a table, check that its run passed its own gate:
timing closed, DRC clean, flow completed. If it did not, the row is excluded —
or marked as a failing point and never used in a ratio.

## Leave upstream assertions ENABLED while developing a harness

Vendored RTL usually ships its own assertions. **Leave them on.** They check the
one thing we are least able to check ourselves: whether *our own stimulus* is
legal.

This is not hypothetical. A differential harness drove AXI channels from a
free-running LFSR — mutating `valid` before `ready` — and the vendored
`rr_arb_tree`'s own assertion caught it immediately:

```
[ASSERT FAILED] req1: Req out implies req in.  (rr_arb_tree.sv:317)
```

Without it the run would have produced a confident diff-rate number derived
entirely from illegal stimulus, and nothing downstream would have questioned it.

**It is a control we get for nothing**, and it is the same shape as everything
else that has worked here: an independent check that fires on a condition we did
not think to test. Disable upstream assertions only with a stated reason, and
never merely because they are inconvenient.

## Recovered and pasted files carry U+00A0

Chat interfaces substitute non-breaking spaces for ordinary ones. **Two candidate
files have now been affected**, and a third instance appeared when a candidate
was recovered out of git history for reuse as a mutant — the NBSPs are committed,
so they come back with the file.

Verilator's lexer rejects them with a misleading `unexpected $end`, and slang
reports `UTF-8 sequence in source text`, so in both cases the answer looks broken
when only the transport was.

`sim_candidate.sh` and `ppa_candidate.sh` normalise a **copy** and never modify
the original, and the slang gate runs on the normalised copy for the same reason.
**Anything else that consumes a candidate file must normalise too** — including
one-off harnesses built during development, which is where the third instance
appeared.

## Under an inverted oracle, coverage floors carry the whole weight

**Rule 11 governs** — local code generates inputs, the anchor produces expected
values. The practical consequence is the part that gets forgotten.

Inversion makes expected values safe by construction, which removes the failure
mode people watch for and leaves the one they do not: **a corner never
generated**. Nothing goes wrong loudly. The run passes, the vectors are correct,
and the untested case is simply absent.

**The consequence is that coverage floors carry the whole weight.** Expected
values are safe by construction; input coverage is not. Every floor must be
stimulus-side, and adding a stimulus category without adding its floor is how
this gets quietly undermined.

## Expect the second source to be the wrong one

**Rule 5 governs the procedure.** The convention is a prior to hold while
following it: on the evidence so far, a second source failing a check means the
second source is broken.

`d_dsp02` went three for three — a frame offset, a signedness bug, and a design
choice that cannot be built (F17, F18). None was a check defect. The second
source is newly written, unreviewed, and has had far less exercise than a checker
that has already passed the anchor and six mutants, so this is what the base
rates predict.

**Budget for it.** Three debug iterations on a second source is normal cost, not
a signal that the difference was too ambitious. The temptation at iteration three
is to conclude the checker is fussy, and that is exactly the point at which rule
5 is load-bearing.

## Name the differences before building — and record the ones that failed

Rule 5 requires three named differences from the anchor. **Name them before
writing, and keep the list even when a difference does not survive.**

The hazard is quiet: differences named *after* the fact become a description of
whatever got built, which satisfies the requirement in form while removing all of
its content. Nothing looks wrong afterwards — the file has three differences,
they are genuinely different, and the requirement did no work at any point.

`d_dsp02` shows both halves. Difference 1 was declared as strict addend framing,
turned out to need a ~485-bit accumulator, and was restated to bidirectional
alignment. The header records **the attempt, the reason it failed, and that the
shipped claim is smaller than the one declared** — so a reader can see the
requirement constrained the design rather than being back-fitted to it.

That record is also where the design-space result lives: the failed difference is
what proved the anchor's framing is a constraint rather than a preference (F18).
**Discard the failures and you discard the only evidence the exercise generated
about which choices are actually free.**

## Mutants perturb the anchor; they do not reimplement it

**Build a mutant as a wrapper around the vendored anchor with one thing changed,
not as an independent implementation of the defective behaviour.**

Two reasons, and the second is the one that matters:

1. A hand-written mutant can fail for **incidental** reasons — an unrelated bug
   introduced while writing it — and then it is not isolated: it trips checks
   other than the one it was built to trip, and by rule 3 it validates none of
   them.
2. Isolation is the whole point. A wrapper is correct everywhere except the
   injected defect *by construction*, so when it fails exactly one check, that
   is evidence about the check rather than about the author's care.

`d_dsp02` is the worked example. All six mutants wrap `fpnew_fma`; every one
fails on its own defect with zero coverage holes. The unfused mutant is the
sharpest case: it is **two anchor instances**, a `MUL` feeding an `ADD`, so every
arithmetic step is externally-authored correct and the only defect is the extra
rounding between them. Hand-writing an unfused FMA would have risked a dozen
unrelated corner-case bugs and isolated nothing.

Where a defect cannot be expressed as a wrapper, mutating one line of a vendored
file is the next best thing — but note that a mutant of a *shared* module cannot
be placed beside the reference in a differential harness, and its non-equivalence
witness has to come through the checker instead.

## The ORFS logs contain several numbers that look like closure

**Rule 7 governs.** This section is the specific trap, because the tempting grep
is always available and always returns something plausible.

Logs contain several things that look like the answer and are not. The most
misleading is `[INFO GPL-0106] Timing-driven: worst slack ...`, emitted during
global placement — it is **negative at periods that ultimately close**, because
placement has not yet been optimised. A log-grep heuristic built on it reports
failure for every design at every period, including designs that close
comfortably.

That was caught here only because a design known to close at 20 ns appeared to
fail at 12 ns. Had the numbers been less obviously wrong it would have stood.

Same family as the defects in `FINDINGS.md`: **a measurement that looks
authoritative and is not.** If a number is going to decide something, take it
from the tool that owns the decision, not from text that happens to contain a
similar word.

---

## Signed intermediates are declared at full working width — never widened by concatenation

**Concatenation is unsigned in SystemVerilog.** `{2'b0, ep}` does not widen a
signed `ep`; it produces an unsigned value from the raw bits, and wrapping
`$signed()` around the result cannot recover the sign because the information is
already gone.

This is the **second** signedness defect on this project. The first demoted `>>>`
to a logical shift inside a ternary whose other branch was unsigned. Both cost a
debug cycle, both produced plausible-looking wrong numbers rather than errors,
and both were invisible in the source at a glance — nothing about `{2'b0, ep}`
reads as a bug.

In the `d_dsp02` second source, `ep = −13` became `0xFF3 = 4083`, giving an
alignment `shift_amt` of **4139 where the correct value was 43**.

**The general fix, applied throughout:** declare exponents and other signed
intermediates at the **full working width they will ever need**, so no widening
step exists anywhere in the datapath.

```systemverilog
// full width at declaration, so nothing downstream needs to widen it
wire signed [13:0] ea = (a[30:23] == 0) ? 14'sd1 : 14'sd0 + $signed({6'd0, a[30:23]});
wire signed [13:0] ep = ea + eb - 14'sd127;
```

The remaining concatenation is safe precisely because it widens an
**unsigned** field. Where a signed value must be widened, use `$signed`'s
context-determined extension or an explicit cast — never a concatenation.

## When your reasoning and the artefact disagree, the artefact is the evidence

Hand-tracing the `d_dsp02` alignment logic said it was correct. The simulation
said otherwise. **The right move at that point was to instrument rather than
trace it again**, and it found the cause in one run — a shift amount of 4139
against an expected 43, which no amount of re-reading was going to produce
because the bug was in a language rule, not in the intended arithmetic.

The reason this is a convention and not a preference: on this same task **a
hand-computed IEEE-754 case had already been wrong once**, and the anchor was
what caught it. Two data points on one task, both in the same direction. When the
artefact and the reasoning conflict, the artefact has the better record here.

Re-deriving is attractive because it is fast and needs no setup. It is also how a
wrong model of the code gets confirmed twice. **Print the intermediate.**

## Never change stimulus in the same timestep as the sampling edge

`@(posedge clk); req = 0;` races the DUT's sampling of `req` on that very edge.
**Leave the edge first** — `@(posedge clk); ... @(negedge clk); req = 0;` — or
drive from a clocking block.

The symptom is not subtle and is very easy to misattribute: in the `v_ca05`
pilot a one-cycle request pulse committed **nothing at all**, so the store looked
completely inert — `empty_o` stuck high, `full_o` never asserting, every pop
returning no data. That reads as a dead DUT or a badly wrong specification, and
both were suspected before the driver was.

**The tell is that a held request works and a pulsed one does not.** That
comparison takes one probe and settles it immediately; re-reading the driver code
does not, because the code looks correct — the defect is in when the assignment
executes, not in what it assigns.

Two consequences worth carrying:

- a model writing a testbench against a hidden DUT will hit this, and the natural
  conclusions available to it are *"the DUT is broken"* or *"the spec is wrong"* —
  neither being true. Any spec-only verification task inherits this as a
  false-failure mode independent of spec quality.
- it is another instance of the artefact-over-reasoning convention above: the
  driver was read three times and looked right every time.

## Neutralise a wrapper before believing what it tells you about the DUT

**Every wrapper you build — conformant perturbation, mutant, shim — gets one
extra run with its perturbation removed, before its result is interpreted.**

The failure this prevents: a miswired wrapper fails the checker, and the natural
reading is *"the checker has a defect."* You then go looking in exactly the right
place for entirely the wrong reason, and if you find anything at all you will
attribute it wrongly.

Worked example. `d_dsp02`'s `cRESBUS` perturbation failed the checker on its
first run. The obvious inference was that the checker samples `result` while
`out_valid` is low — a genuine defect of the kind the conformant set exists to
find. The neutralised copy, identical but with the perturbation removed, **failed
identically**. The wrapper was broken: `inner_result` had been left implicitly
declared and became a **1-bit wire**, silently truncating a 32-bit result. The
design elaborated, ran, and returned garbage.

**The control costs one run and answers a question nothing else answers:** is the
artifact broken, or the thing under test? No amount of reading the wrapper
settles it — the file looked correct, and the defect was a language rule about
implicit declaration rather than anything visible in the logic.

It is the same shape as the liveness check on the conformant set, one level up:
that one asks *"does this perturbation do anything?"*, this one asks *"does this
perturbation do only what it claims?"* Both are needed, and neither substitutes
for the other.

## A metric with a known-answer case must be calibrated against it

**Before a metric is reported, run it against a design whose value you already
know.** Most metrics have such a case available, and it is usually cheap:

| metric | known-answer case |
|---|---|
| latency | a purely combinational design — must read 0 |
| initiation interval | a design that stalls every other cycle — must read 2 |
| throughput | a driver offering a known fixed rate |
| capacity | a design bounded at a parameter you set |

This is rule 3 applied to a *metric* rather than to a checker, and the reason it
matters is the failure signature.

`d_dsp02`'s latency metric first read **2 for a three-stage design and 1 for a
purely combinational one.** That is monotonic, correctly ordered, plausible for
both, and **off by one everywhere.** Every sanity check you would think to apply
passes: the pipelined design reads higher than the combinational one, both are
small positive integers, and the ratio looks about right. It fell out only
because two designs with known answers were run through it, and it took *both* —
the first correction fixed the depth-3 case and left the combinational case
wrong, because a combinational design has its result valid on the acceptance
edge and the counter never looked there.

**A metric that is wrong by a constant is the worst case**, because it preserves
ordering and therefore survives every comparison-based check. Ranking two
submissions by it still works. Only an absolute known answer catches it.

## A spec assertion beyond what step 1 confirmed gets checked against the golden

Step 1 of a task build confirms the anchor exists, elaborates, and carries the
licence claimed. **Everything the spec asserts BEYOND that is a claim about
behaviour, and it gets run against the golden before anything is built on it.**

The failure this prevents is delayed and misattributed. A spec that has drifted
from its anchor — a requirement that was true of an earlier revision, or was
inferred rather than measured — does not announce itself. It surfaces much later
as **the reference testbench failing the validity gate**, and the natural reading
at that point is a checker defect. You then debug the checker, which is correct,
against a spec that is wrong.

Cheap because the golden is already there: for each asserted behaviour, write
the stimulus that would exhibit it and confirm the golden does. Anything the
golden does not do is either a spec error or a genuine anchor limitation, and
both need finding before mutants and coverage floors are built on top.

It caught nothing on `v_dsp02`, which is the expected outcome and not a reason to
skip it — the check is cheap and the failure it prevents is expensive and
misdirected.

## Any long-running job must emit progress to a readable stream

**This is the highest-leverage convention in this file, because it is the cause
behind a whole class of violations rather than an instance of one.**

An unobservable job does not go unobserved. Someone needs to know whether it is
alive, and they will find some other way to tell — and **that other way is
reliably the untrustworthy one**, because the trustworthy source is precisely the
one that is unreadable.

The worked example is exact. A `find_fmax` sweep ran two and a half hours with a
**zero-byte stdout file**, working normally the whole time: Python block-buffers
stdout when it is a file rather than a TTY. With the driver's own classification
unreadable, the only remaining evidence was the flow logs — so the check on
liveness became a log grep, which is the one thing rule 7 forbids, landing
straight on the `GPL-0106` trap documented two sections above. **Documented, and
walked into anyway.**

That is the part worth internalising. The trap was already written down. Knowing
about it did not help, because the pressure was structural: the only available
measurement was the wrong one. **Discipline does not survive a missing
instrument.**

So the fix is not "be more careful about rule 7". It is to remove the pressure:

- `python3 -u`, or `PYTHONUNBUFFERED=1`, on anything backgrounded
- flush after each iteration in any loop that runs longer than a few minutes
- emit a line per iteration carrying **the tool's own verdict**, so the readable
  stream and the authoritative source are the same stream
- if a job cannot emit progress, it must at least write a state file the
  supervisor can read

**Expect every future rule-7 violation to have this cause.** A grep of an
intermediate log is nearly always a symptom of an unobservable job upstream, and
fixing the grep leaves the cause in place.

## CRITICAL PROCESS FINDING — single-seed validation is not validation

Every "3/3 mutants caught, golden PASSES" claim in the module sections below was
originally established from **one run per configuration, i.e. one random seed**.
That was not enough, and it let a real bug ship.

`$urandom` in these testbenches explores ONE trajectory per run. Verilator picks
a seed per binary, so a different machine (or a different Verilator build) walks
a different trajectory. Sweeping seeds afterwards found:

| module | seeds passed (of 6) |
|---|---|
| rob | 6/6 |
| lsq | **4/6** |
| bpred | 6/6 |
| ncache | **2/6** |
| mesi | 6/6 |

Two genuine bugs had been sitting behind the default seed:

1. **`ncache` golden — a real RTL bug** (and it had already propagated into the corresponding candidate). `B_req_ready` budgeted the PQ slot that port
   A would consume, but **not the MSHR**. With one MSHR free and both ports
   missing to *different* lines, both ports were told ready; A took the last
   MSHR and B was accepted with nothing to allocate. Symptoms: a request that is
   never answered (`C3 LIVENESS`) and a read whose data was never written
   (`C2`). Fixed by budgeting MSHRs in `B_req_ready` exactly as PQ slots already
   were, plus a guard so a reference model can never index with `-1`.
   *This is the bug that failed on the Windows machine and passed on the Mac.*

2. **`lsq` testbench — a false failure.** The D2 relaxation that permits a
   forward to become a memory read once the source store retires asked "is that
   slot still live?" using the slot number alone. Slots get reused, so a younger
   store in the same slot made it look live again and a legitimate result was
   failed. Fixed by tagging the frozen expectation with the store's **age** as
   well as its slot. (Note the shape: this is the *third* slot-reuse-without-a-
   generation-tag bug in this tier — see also the LSQ golden's in-flight memory
   transaction and the ncache response path. It is the characteristic bug of
   this whole design space; check for it first.)

After both fixes all five goldens pass **10/10 seeds**, and the ncache mutants
still fail.

### Use `scripts/seed_sweep.sh`

```
./scripts/seed_sweep.sh ncache 20              # golden
./scripts/seed_sweep.sh ncache 20 candidate    # a submission
```

**Treat a single-seed PASS as unvalidated** — for goldens, for mutants, and
above all for candidate submissions, where a seed-lucky pass is a scoring error.

---


---

## Shared: toolchain — **Verilator is the simulator of record**

**One simulator decides every scored result: Verilator 5.046** (`--binary --timing`).
Synthesis is a separate frontend — **slang**, inside the OpenROAD container — and
a design slang rejects can never produce a PPA number, so that gate stays.

**Do not report a result as confirmed on two simulators.** Dual-frontend
agreement was useful while the harness was being built and is no longer part of
how anything is scored; describing a result that way implies a check the
pipeline does not perform. Icarus 13 remains installed as a **debugging aid for
awkward candidate submissions** — a second opinion when a failure is hard to
read — and nothing scored depends on it. The notes below on the portable subset
and on Icarus behaviour are kept for that debugging use, not as a scoring
requirement.

### What the migration changed for harness authoring

The Icarus-era constraint table that used to live here is **obsolete**. Verified
under Verilator 5.046, all of the following now work and were previously blocked:

| Construct | Icarus 13 | Verilator 5.046 |
|---|---|---|
| Associative arrays (any index type) | ✗ unsupported | ✓ |
| Unpacked structs | ✗ `sorry:` | ✓ |
| Queues of structs | ✗ `sorry:` | ✓ |
| **`entries[idx].field`** (array-of-struct access) | ✗ **elaborator crash** | ✓ |
| Queues inside classes | ✗ `sorry:` | ✓ |
| Class handle arrays | ✗ type error | ✓ |
| `static` class members | ✗ syntax error | ✓ |
| `ref` task arguments | ✗ `sorry:` | ✓ |

So class-based scoreboards, sparse golden memories and natural per-entry struct
arrays are all available for modules 2–5.

### The existing harnesses stay in the portable subset — on purpose

`rob_tb.sv`, `golden_mem.sv`, `mem_stub.sv` and `common_selftest.sv` were written
against the Icarus subset (procedural scoreboards, dense golden memory, packed
records in vector queues). They have **not** been rewritten, because they now run
unmodified under *both* simulators. That is worth keeping: Verilator is 2-state,
so being able to re-run the same harness under Icarus's 4-state engine is a free
cross-check on exactly the class of bug 2-state simulation under-reports (the
UART R7 finding is the standing example). Confirmed identical verdicts on the
golden and all three mutants under both.

New Tier-2 harnesses may use the richer constructs; if a harness does, note in
its section that it is Verilator-only.

### Verilator gotchas found the hard way (all cost a debug cycle here)

1. **`$sformatf({"part1 ", "part2"}, args)` silently produces garbage.** Icarus
   renders the brace-concatenated format string correctly; Verilator treats the
   concatenation as a bit vector and prints it as a huge decimal, then appends
   the arguments. This is a *latent grading defect*: it only shows up on failure
   paths, which is exactly when the message matters. **10 occurrences were found
   and fixed** — 5 in `rob_tb.sv`, 3 in the softmax testbench and 2 in the UART testbench
   (both since removed; the pre-existing ones were equally broken, just never
   exercised because those modules pass). Rule: **format strings must be a
   single literal.**
2. **A comment line whose first word is `verilator`/`Verilator` (any case) is
   parsed as a metacomment pragma** and hard-errors with `BADVLTPRAGMA`. Writing
   an example command line in a header comment is enough to break the build.
   Prefix with `$ ` or reword.
3. **`-I` must be attached**: `-Itestbenches/common`, not `-I testbenches/common`
   (the latter is read as a source file). `build_and_score.sh` already does this
   correctly; the migration note's example has the space.
4. **Parameter override is `-GDEPTH=32`, bare name.** `-Grob_tb.DEPTH=32` and
   `-pvalue+rob_tb.DEPTH=32` both fail with "Parameters from the command line
   were not found in the design". Note this differs from Icarus's
   `-P rob_tb.DEPTH=32`, which *is* scoped.
5. `-Mdir` must already exist, or Verilator fails with `Can't write file`.

### Follow-up: the UART R7 root cause — **attribution appears to be wrong**

The migration note records R7-rx-back-to-back as a *testbench* bug ("pointed at
the testbench's own pulse-monitoring infrastructure ... Resolved") and leaves the
root cause undocumented. Reconstructing it from the repo contradicts that:

* the UART testbench was **byte-identical** to the committed
  baseline apart from the two format-string merges made in this migration. The
  `rx_valid` monitor and `rxv_clear()` bookkeeping were never touched.
* its candidate was **wholly replaced** vs. the committed baseline
  (469 lines changed, a different implementation).

Controlled experiment — same unchanged testbench, only the DUT swapped:

| DUT | Verilator | Icarus |
|---|---|---|
| milestone-1 `uart.sv` | FAIL, 9 failures, all in R7 | FAIL, 14 failures |
| current `uart.sv` | PASS | PASS |

So the testbench correctly failed a buggy receiver and correctly passes a good
one. **The R7 bug was in the DUT, not in the monitor**, and the resolution was
replacing `uart.sv`. This matters: believing the grader was at fault invites
either distrusting a testbench that is in fact sound, or applying a phantom fix
to it. Every failure is confined to the R7 phase, which is what a genuine
back-to-back receive bug looks like.

Caveat on the exhaustive 65 536-combination check cited in the note: it appears
to have validated the RX state machine in isolation, which would not model the
**inter-frame boundary** — a receiver that returns to idle at the last stop bit's
midpoint and then mishandles a start bit arriving in the very next bit period
fails only when frames are adjacent, not for any single data value.

**This incidentally reproduces the 2-state under-reporting cost exactly**: the
same DUT and testbench yield **14** failures under Icarus and **9** under
Verilator. That is precisely the "5 additional spurious frame error failures"
the migration note observed, and it is a concrete measurement of what 2-state
simulation hides — Verilator under-reported by 36% on a real bug.

### 2-state caveat (carried forward)

`--x-assign unique --x-initial unique` makes uninitialized reads pseudo-random
per run rather than fixed, but it is not 4-state X-tracking. Verilator alone may
under-report bugs that depend on genuinely undefined state at a race window.
Mitigation available at zero cost: the Tier-2 harnesses are portable, so any
suspicious result can be re-run under Icarus for a second opinion.

**The standard record pattern used by the existing harnesses:**

```systemverilog
typedef struct packed { logic [7:0] addr; logic [1:0] sz; logic we; } rec_t;
logic [$bits(rec_t)-1:0] q [$];   // queue of vectors
rec_t r;
q.push_back(r);                   // implicit pack
r = q.pop_front();                // implicit unpack
```


---

## Layout

Every task is a self-contained directory:

```
domains/<domain>/design/<task_id>_<module>/
  spec/<module>_iface.sv     port-only contract -- THE ONLY FILE SHIPPED
  spec/<module>_pkg.sv       shipped too, when the task needs shared types
  ref/<module>_ref.sv        thin shim over vendored RTL (Class A)
  ref/sim_flags_*.txt        extra simulator args the REFERENCE needs
  tb/<module>_tb.sv          the scoring testbench -- name must match the DUT
  tb/audit/                  probes and second sources; never scored
  mutants/                   known-bad inputs, one defect each
  orfs/config.mk             PPA harness
  NOTES.md                   the evidence trail
  task.yaml                  legal configs, verified simulators, caps
```

**`tb/<module>_tb.sv` is required and is the only file the runner will score.**
Auxiliary rigs — liveness probes, capability audits, second sources — live under
any other name, and `tb/audit/` by convention. This is not cosmetic: the runner
once selected the scoring testbench with `ls tb/*_tb.sv | head -1` and scored a
read-only liveness rig for eight commits. See `FINDINGS.md`.

`ref/sim_flags_<simulator>.txt` carries the search paths and include directories
a *reference* needs and a self-contained candidate does not. One token per line;
`%REPO%` expands to the repository root. An empty file here once meant a
reference had never been simulated at all.

---

## Shared verification models — **COMPLETE and self-tested**

`testbenches/common/golden_mem.sv` — byte-addressable golden memory (sized
little-endian scalar access, line access for modules 4/5, deterministic
non-zero `init_pattern` so a load that never actually fetched cannot look
correct by returning 0, and address wrapping so a stray address folds in rather
than killing the sim). Dense rather than sparse — originally forced by Icarus,
now a kept choice: the small skewed address pool makes a few KB of flat array
sufficient, and it keeps the model runnable under both simulators.

`testbenches/common/mem_line_stub.sv` — the LINE-GRANULAR sibling added for
module 4 (and reused by module 5's bus): same single-outstanding contract, same
violation latching, line-wide transfers.

`testbenches/common/mem_stub.sv` — next-level memory with **randomized**
latency (`MIN_LAT..MAX_LAT`, default 2..6) so latency-dependent bugs cannot hide
behind a fixed timing assumption. Storage is a nested `golden_mem` instance, so
there is exactly one implementation of sized access in the tree. Single
outstanding transaction; **a request arriving while busy is latched as a
protocol violation** (`err_overlap` / `err_overlap_count`) rather than silently
swallowed, so a candidate that breaks the single-outstanding contract gets
failed instead of mis-scored.

`testbenches/common/common_selftest.sv` — these two are depended on by three
separate harnesses, so they get their own self-test rather than being trusted
implicitly. **134 checks, PASS**: little-endian byte ordering, sub-word writes
leaving neighbours intact, address wrap, line/scalar view agreement, pattern
fill non-degeneracy, read/write round-trips at all three sizes against the
golden model, whole-image agreement, and positive confirmation that the
single-outstanding violation detector actually fires.

```
verilator --binary --timing -j 0 -Wno-fatal --top-module common_selftest \
  -Mdir obj_dir -o sim -Itestbenches/common testbenches/common/common_selftest.sv
obj_dir/sim
```

Confirmed PASS under **both** Verilator 5.046 and Icarus 13 (`iverilog -g2012
-Itestbenches/common`). Icarus emits a cosmetic "for statement must compare
against a constant to be synthesized in an always_ff" warning at
`golden_mem.sv` because `mem_stub`'s always_ff calls `wr_sized`; these are
verification models, never synthesised, so it is harmless.

Open item for module 4: the stub is currently scalar/sized. The cache needs
**line-granular** fills and writebacks — extend `mem_stub` with a line mode (or
add a thin line wrapper) during that session rather than guessing now.



## Controls: existence is not participation

A gate that proves a control EXISTS proves nothing about whether it RAN. The
second-DUT gate checked `[ -d "$TASK_DIR/dut2" ]` and passed; the second DUT
was never compiled against, for three tasks, while the status field said
`BUILT_UNWIRED` in plain text (F40).

Rule 8's test — *can this control be skipped by calling something one level
down?* — does not catch this shape. The control was not skipped. It was never
invoked, so there was nothing to skip.

**The test that does catch it: does anything READ the control's output?** Trace
from the control to a number that appears in a report. If no path exists, the
control is decoration however carefully it was built.

Two cheap habits that make the failure visible:

- **Print the count of things the harness will run, before it runs them.**
  `duts=12` becoming `duts=13` is how the fix was confirmed to be live. A
  harness that does not say how much work it is about to do cannot be observed
  to be doing less than you think.
- **Validate a control before trusting a failure it produces.** The second DUT
  is an oracle, so a wrong one manufactures submission failures out of nothing.
  Every reference testbench was run against its own dut2 first; all three
  accepted, which is what makes the submission rows interpretable.

Related: the `sorry:` prefix in Icarus means *valid input, unimplemented
feature* — not a defect in the file. Never quote a `sorry:` as a submission
error, and check which frontend the harness actually invokes before attributing
anything to the submission: the verification harness runs **Verilator**, so an
Icarus limitation observed at a terminal has no bearing on a score.

## Correction against `refs.lock`'s toolchain line — no SMT backend exists

`refs.lock:15` reads:

```
formal: "eqy + sby v0.67 inside openroad/orfs:latest (read_slang frontend); no host install"
```

**That line overstates what the container can do, and `refs.lock` is frozen, so
this is the correction of record rather than an edit to the lock file.**

`openroad/orfs` ships **no SMT solver at all**. Verified directly in the image:

```
yices  yices-smt2  z3  boolector  bitwuzla  cvc5  cvc4  mathsat  msat
   -- every one NOT PRESENT
sby /usr/local/bin/sby     eqy /usr/local/bin/eqy
yosys-smtbmc /usr/local/bin/yosys-smtbmc     yosys-abc /usr/local/bin/yosys-abc
```

`sby`, `eqy` and `yosys-smtbmc` are all installed, which is why the line reads
plausibly. **`yosys-smtbmc` is a driver, not a solver** — with no backend behind
it the `smtbmc` engine cannot run on any design, and never could. It has never
run in this project.

**What actually works: `abc bmc3` on the bundled `yosys-abc`, and nothing else.**
Two consequences that follow from that and not from any design's difficulty:

- `aigsmt none` is required, or `sby` reaches the correct verdict and then fails
  post-processing when it tries to build a waveform through `yosys-smtbmc`. The
  cost is a verdict without a counterexample trace.
- Any equivalence result in this project is a **bounded** result from `bmc3`.
  Nothing here is an unbounded proof, and no statement should be written as
  though it were.

**Reading discipline.** "eqy + sby are installed" and "this container can run
formal equivalence" are different claims, and the toolchain line collapses them.
Presence of a tool is not presence of the capability it fronts -- the same
distinction as a control that exists versus a control that runs.

Where formal capability is described anywhere else, it must be described as
bounded `abc bmc3` only. `refs.lock` itself stays as it is: it is frozen, and a
frozen manifest with a correction recorded against it is more honest than a
manifest quietly edited to match what was later discovered.

**From:** Agent 3's toolchain audit; the d_ca01 EC work that hit it

## Committing in a tree another agent is working in

**From:** F61. The mechanics of the invariant are rule 13's; this is how to
avoid the pothole.

Several agents share one working tree and one `.git/index`. Git's granularity is
per-file and the index is per-repository, so **the unit that collides is the
file, not the edit** — two agents editing disjoint regions of `FINDINGS.md` have
no conflict to resolve and every opportunity to publish each other's work under
the wrong name.

### Committing a shared file you did not write all of

`FINDINGS.md`, `RULES.md` and `CONVENTIONS.md` are append-only and unowned.
Interactive staging is unavailable here, so whoever commits carries whatever else
is in the file. Carrying it is correct — holding the file back leaves findings
unlanded, and a finding absent from `FINDINGS.md` cannot be cited by a rule, so
the graph cannot validate it. Carrying it *silently* is what makes the history
unreadable later.

1. **Name the other agent's content in the commit message.**
2. **Prove nothing pre-existing was altered — measured, not asserted:**
   `git diff HEAD -- FINDINGS.md | grep '^-' | grep -v '^---'`
   Every removed line must be one you wrote. A removal anywhere else is a
   stop-and-report, not a conflict to resolve in passing.
3. **Establish attribution; do not infer it from subject matter.** A finding
   about someone's task was not necessarily written by them. Ask — a teammate is
   one message away, and the cost of guessing is a permanent record crediting
   the wrong person for work and the wrong person for a mistake. Record
   provenance and authorship as separate fields when you carry either.

### Committing while the shared index holds someone else's staging

`git add` + `git commit` carries their staging into your commit;
`git restore --staged` destroys it; `git commit -- <paths>` cannot add untracked
files. Build through a private index instead:

1. `export GIT_INDEX_FILE=/tmp/myidx`
2. `git read-tree HEAD`
3. `git add -A -- <explicit paths>` — never a bare `-A`
4. **`scripts/check_linkage_tree.sh --staged`**
5. `TREE=$(git write-tree)`; `unset GIT_INDEX_FILE`;
   `git commit-tree $TREE -p HEAD -F msg` ; `git update-ref HEAD <new>`
6. `git read-tree HEAD` — **refresh the real index against the NEW HEAD**
7. `git add -A -- <the other agent's paths>` — re-stage what was there

Then `cmp .git/index /tmp/real_index.bak` to confirm you left it as you found it.

**Steps 4, 6 and 7 are not optional and each exists because it was skipped
once.** Omitting 6 leaves the real index carrying stale blobs: measured, a plain
commit from it would have reverted a rule landed seconds earlier. And
`git update-index --force-remove` is **not** the way to re-stage a deletion — it
fails silently and leaves it unstaged. `git add -A --` with explicit paths works.

**The failure is silent in both directions and neither agent saw their own.** One
index carried staged deletions of seven of the other agent's files; the other
carried blobs that would have reverted a just-landed rule. `git status` showed
something entirely ordinary in both cases, and each was found by the other agent.

### The gate is a convenience; the audit is the check

**Before pushing, whoever pushes runs:**

    scripts/check_linkage_tree.sh --audit origin/main..HEAD

In practice that is Jack. It is his step, not an agent's.

`--staged` can be wired to a pre-commit hook (`scripts/install_hooks.sh`), and
that covers ordinary `git commit`. **It would have missed the only instance we
have.** `d6d3423` was made with `commit-tree` + `update-ref`, which runs no hooks
at all — and that is the procedure recommended above. `--no-verify` bypasses it,
and `.git/hooks` is not versioned so it does not reach another clone. Trust the
audit, not the hook.

Both test the **resulting tree**, never whether a file is dirty. An uncommitted
change that does not break linkage is not a reason to block, and a check that
fires on file state gets routed around within a week.

The override (`LINKAGE_OVERRIDE="reason"`) prints a `LINKAGE-OVERRIDE:` trailer
to paste into the message. It buys a labelled exception, not silence: `--audit`
reports a failing tree without the trailer as unexplained.

### This binds whoever commits, not only agents

A broad `git add <dir>` from the repository owner reintroduces exactly what the
private-index procedure prevents. `d103a3f` and `7e97cb6` carried an agent's
in-progress work, another agent's staged deletions, and an uncommitted edit to a
finding, under messages naming none of them. Nothing broke and nothing needs
undoing — but the hazard is the same one under a different hand, and the owner is
the one person whose commits nobody else reviews.

### Candidate artefacts are committed ON ARRIVAL

Not when the surrounding work is ready, not when the batch completes, not when
scoring finishes. A file arriving from outside the project — a model submission,
a vendored drop, a hand-collected log — is committed **before any work is done on
it, including before it is scored.** A commit whose message is only
`land <model>.sv as received` is complete and correct.

Losing a derived file costs a rebuild. **Losing a solicited answer costs the
answer** — the model is not deterministic and its version may no longer be
reachable. `candidates/d_dsp02/claude.sv` was lost exactly this way, and unlike
every other collision here there was no diff to catch it: the file had never
been in git, so nothing registered a change.
