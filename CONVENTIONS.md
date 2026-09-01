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

## The four shared documents have one writer

`TASK_CATALOG.md`, `FINDINGS.md`, `RULES.md` and `CONVENTIONS.md` are written by
**one agent only**. No other agent writes to them. Everything else in the tree
stays owned by whoever is working on it; these four are the exception because
they are the documents every agent reads and none of them is derived from
anything — a lost concurrent edit here cannot be recovered by regenerating it.

### Peers stage; the owner lands

A peer with something to add does not edit the shared file. It appends a block
to a staging file:

    inbox/<shared-file>.agent<N>.md        e.g. inbox/FINDINGS.md.agent3.md

Every block opens with an explicit author line, so authorship survives the move:

    <!-- author: agent3 -->

The owner moves blocks into the shared file **verbatim**, preserving that author
line, and runs both checkers after each landing:

    python3 scripts/check_rule_linkage.py
    bash scripts/check_linkage_tree.sh

### Landing is not reviewing

The owner lands content. The owner does not edit it, rewrite it, tighten it, or
judge whether it is right. A block that fails linkage **goes back to its author**
with the checker's message; it does not get repaired in place.

This is the whole point of the separation. An owner who edits on the way in
becomes a second author of a document that is supposed to have one, and the
authorship line then names someone who did not write what is under it. An owner
who reviews on the way in becomes a gate on other agents' findings, which is a
role nobody granted and which silently drops what the gatekeeper disagrees with.
Landing verbatim keeps the owner's job mechanical: move the block, run the
checkers, and if they fail, hand it back.

The one thing an owner may fix without returning a block is a collision the
owner's **own** landing created — for example, adding a rule whose opening words
duplicate prose already in a finding, which trips the rule-13 restatement check.
That defect belongs to the landing, not to the block.

<!-- author: agent2 -->

## Go and find the case that would kill your own hypothesis

**A practice, not an observation. If a new agent is told one thing on day one,
this is it.**

Two mechanisms were proposed in one week to explain the same defect. Both were
plausible, both were held by people with evidence, and **both died within
hours**:

    setup role      died on d_ca04     a file its author owns and could have
                                       quietly not checked
    clause count    died on v_ca06     a task its author had already filed, and
                                       could have left filed

Neither hypothesis was careless. **Neither survived contact with the case its
author went to find.**

### The instruction is not "test your hypothesis"

It is **the file you own and could quietly skip**, and every clause is
load-bearing:

- **you own it** — nobody else will check it, and nobody will know you did not
- **you could skip it** — there is a live reason not to look, usually that it is
  the case most likely to be inconvenient
- **quietly** — skipping produces no artefact. There is no gap in the record
  where the unchecked case would have been

That is the shape of the defects worth catching: **not a wrong answer, an absent
question.** A hypothesis you did not try to kill and a hypothesis that survived
look identical in a report.

### The cost, measured rather than asserted

Two hours, twice. Against the alternative — a mechanism that survives because
nobody looked, is built into a checklist, and is found wrong by someone relying
on it after the checklist has been applied to eleven tasks.

**Both falsifications were cheaper than either mechanism would have been if it
had been kept.** The argument is cost, not honesty.

### The day-one form

> **Before you report a hypothesis, name the case that would kill it. If that
> case is in a file you own, go and look at it. If you cannot name such a case,
> you do not have a hypothesis — you have a description of what you already
> saw.**

The last clause generalises past any one week. Both dead mechanisms were good
*descriptions* of the instances that produced them. Neither made a prediction its
author could not already see, until somebody went looking for the row that would
break it.

## A probe that discriminates on WHEN needs both controls, not one

A probe answering "does X happen" needs one control: show it firing on a case
where X is known to happen, so that a silence means something. A probe answering
**"on which edge does X happen"** needs two, because it has two distinct ways to
produce a confident wrong answer and they are not each other's opposite:

  * an instrument BLIND to the event reports "never", which reads as a finding
    about the design rather than about the instrument;
  * an instrument that reports the event EVERYWHERE returns edge 1 for anything,
    which is the most plausible-looking answer it could give and the hardest to
    doubt.

One control catches one of these. The same control cannot catch both: a control
that must fire proves the instrument is not blind and says nothing about false
positives, and a control that must stay silent proves the reverse.

**The pattern, as run on d_ai01's `probe_flush_stall_edge_tb`:**

    ARM E   the effect MUST occur      -> a reported edge, or the instrument is blind
    ARM G   the effect MUST NOT occur  -> silence, or the instrument sees phantoms
    ARM S   the regime under test      -> read ONLY if E fired and G stayed silent
    ARM Q   the same regime entered a different way

The gate is printed before the result and the result is withheld when the gate
fails, rather than printed with a caveat. A reading that is only valid
conditionally should not be on the screen next to the condition.

**ARM Q is not a third control, it is a second experiment.** Where the regime is
entered by changing two inputs on one edge, a simultaneity artefact and a rule
are indistinguishable. Entering the same regime the other way round — establish
one input, then move the other — separates them. Cheap, and it is the difference
between "flush outranks the stall" and "flush outranks a stall that arrives at
the same instant".

**AND THE VACUITY GUARD, which is not optional and is not a control.** A probe
measuring when a value becomes 0 must assert that the value was NOT 0 before the
assertion, per arm. Otherwise "cleared on edge 1" is what the probe prints when
nothing was ever loaded — the exact defect recorded at d_ai01's own vector guard,
where an X test passed a run with no vectors. The controls test the instrument;
the vacuity guard tests the stimulus, and the two failures look identical in the
output.

**Rules:** 24


---

# Landed from agent deliveries, 2026-08-29

## A lesson carried across cases without re-deriving it is worse than no lesson

It arrives with evidence attached, so it is believed faster and questioned less
than a bare guess would be.

**The instance.** AGENT-VERIF-A2 lost two rows from a corpus sweep because their
scan anchored the field at column 0 and two declarations were indented. The
lesson looked like *tolerate indentation*. I took it, wrote an
indentation-tolerant parser, and put three cases in its self-test asserting that
an indented field is returned.

That parser then overwrote two historical records. `task.yaml` files carry
`task_text_hash:` in two different senses — a top-level one declaring the task's
own text, and nested ones inside `version_boundary.prior_result` and
`candidate_set` recording which text a past result ran against. **Tolerance was
never the requirement. Discrimination was.** Reading an indented field as the
task's declaration is precisely what made one file claim a historical
measurement had been produced against text that did not exist when it ran.

**Why it beat the usual defences.** The lesson was correct where it was learned,
it was recent, it was mine to apply, and it came with a measured failure behind
it. Every signal that normally marks a claim as safe was present. The one thing
missing was the only thing that mattered: nobody re-derived it for the new case,
where the two situations differ in the direction the fix points.

**The rule.** When you carry a lesson from one case to another, re-derive it
from the new case's own facts before applying it. If the derivation does not
reproduce the lesson, the lesson does not transfer — and the evidence attached
to it is evidence about the old case only.

**What to watch for.** The transfer is most dangerous when the two cases share a
mechanism and differ in intent. Both cases here were "a scan that must find a
field in a YAML file"; the intents were opposite. A shared mechanism is what
makes the transfer feel obvious, and it says nothing about whether the intents
agree.

Related, and the same failure one level out: a checker cited in an argument is
not a control until you know what it reads. Both are correct-sounding things
placed next to a question, settling it without being consulted.

<!-- author: agent3 -->

*Delivered by AGENT-DESIGN-43a92055.*

## Clause status is per task, traced, never pattern-matched

The same clause letter has opposite status in different tasks. `B1` is
**enforced** in d_nw03 — `nc_h_overbuffered` dies on it at 72 beats — and
**unchecked** in d_ca04, where it has zero mentions in the testbench. `R1b` is
grouped under `R1` in both d_ca01 and d_nw03, and the check that observes it
carries its id as a **prefix** in one and in **trailing parentheses** in the
other, so a grep tuned to one misses the other.

**So a clause's status cannot be inferred from its letter, from a sibling task,
or from what the same clause did last time.** It has to be traced to the check
that observes it, in that task's testbench, every time.

Three states, and two of them look identical from a grep of failure output:

    GROUPED     a check observes it and reports under another clause's id
    ANONYMOUS   a check observes it and its message names no clause at all
    UNCHECKED   nothing observes it

d_ai01, d_ca03 and d_dsp02 are largely ANONYMOUS — one comparison covers a whole
clause section and names none of it. d_nw01's C3, D3, H1 and H3 are UNCHECKED.
Reading the second as the first, or the first as the second, is the error this
convention exists to prevent, and only tracing separates them.

**The candidate list from `check_clause_emittable.py` is not the input to this.**
It is over-broad by roughly 45%, measured twice independently, and its false
positives are clauses addressed to the tester, clauses stating what the checker
guarantees, definitions, and clauses whose own text says they are never
exercised. It tells you where to look. It does not tell you what you will find.

---

*Delivered by AGENT-DESIGN-43a92055.*

## A relayed ruling is not the ruling

AGENT-VERIF-A2 declined to land two sentences on a user decision that reached
them through me, while landing the three that did not depend on it. I had
relayed accurately. That is the point.

> From the receiving end, the case where a relay is wrong looks identical to
> the case where it is right. **No property of the message distinguishes them.**

That is the in-range failure value, in the authorisation channel. We spent two
days establishing that an in-range failure value needs a SECOND CHANNEL rather
than more care -- a wrong number inside the range of legitimate outputs cannot
be caught by reading it harder. An authorisation that arrives correctly-formed
from a trusted peer has exactly that shape. The second channel is the user
saying it in the other session, and it costs one round trip.

The tempting counter-argument is a real one, which is what makes it worth
naming. Two of three tasks converted is the "same letter, different status
across tasks" state the annotation pass existed to remove, so consistency
genuinely argues for landing the third. A2's answer:

> **Consistency is a property of the corpus; authorisation is a property of who
> decided.** Trading the second for the first has no floor -- the next
> inconsistency will also be real, and will also be an argument for acting on
> the next relay.

*Delivered by AGENT-DESIGN-43a92055.*

## When a peer reports something is unmeasurable, ask the instrument, not the peer

AGENT-VERIF-A2's rule, from the retraction of my d_ai01 claim. It is worth more
than the retraction.

A claim of the form **"X is outside the reach of instrument Y"** is checkable
against Y's own output, and it is cheap precisely because these instruments
print a row per task. **A row refutes it on the spot; no row corroborates it;
neither outcome depends on trusting the report.**

Verified across the corpus after the fact: `check_clause_emittable` prints a row
for every live task. The only two NO CONCLUSION rows are `d_dsp01` and
`v_dsp01`, the pair that deliberately are not tasks — one WITHDRAWN, one
REJECTED, both recorded as terminal. **There is no task in this corpus outside
the reach of every instrument.**

*Delivered by AGENT-DESIGN-43a92055.*

## Disable the perturbation and require the control to PASS

AGENT-VERIF-A2 measured nine versions of three controls and found **six where
the verdict line alone would have misled**: four passed because nothing
perturbed, two failed on the wrong clause. Their remedy is a FIRED counter on
the perturbation rather than on the outcome.

The differential form is stronger and costs one more build:

> **Build the control with its perturbation REMOVED and require it to PASS.**
> Then the perturbation is necessary for the failure, not merely present during
> it.

A FIRED counter says the perturbing condition was true. It does not say the
failure came from it. A2's own `D5` case is exactly that gap: two of their
controls failed a clause their override never touched, because both were copied
from a file whose own perturbation came along -- every one of those failures was
the COPIED control doing its job, on a channel the new override never wrote.
A FIRED counter on the new perturbation would have read healthy throughout.

Applied to the seven controls written this session:

    nc_j  d_nw01 C3 W ceiling      liveness instrument (peak occupancy)
    nc_k  d_ca04 B1                liveness instrument (peak occupancy)
    nc_l  d_nw01 H1    FAIL/H1  -> PASS with perturbation removed
    nc_m  d_nw01 H3    FAIL/H3  -> PASS
    nc_n  d_nw01 D3    FAIL/D3  -> PASS
    nc_h1 d_dsp02 H1   FAIL/H1  -> PASS
    nc_f6 d_ca05 F6    FAIL/F6  -> PASS

Five differentials, two occupancy instruments. In every case the failure names
the clause the perturbation attacks AND disappears when the perturbation does.

**One of the five needed the test to reach that state.** `nc_f6` originally
failed F6 *and* T6, because gating all of `req_o` on an AMO window also blocked
the array traffic a miss needs to BECOME a refill. Discriminating by the flush
WRITE SIGNATURE instead of by the window separated them. **A control that fails
for two reasons is weaker evidence about either**, and the differential is what
makes that visible rather than a judgement call.

*Delivered by AGENT-DESIGN-43a92055.*

## A routing message for isolation work is inside the isolation boundary

I disqualified myself from re-deriving d_ai01's flush oracle, correctly, on
evidence: I had decoded the reference's `status_o` at flush cycles and read all
101 disagreement rows. Then I wrote the hand-off — and put all three readings in
it, **including the reference's**, under the label:

> Three readings exist, for context only — not as a hint.

AGENT-VERIF-A2 derived "advance" knowing the reference advances, and disqualified
their own work on the strength of it. **The label is the defect, not their
reading of it.**

### Why the label cannot work, stated mechanically

**A warning about content is processed after the content.** There is no ordering
in which a reader receives "do not use the following" before the following. By
the time "not a hint" has been parsed, the three readings are known. The
instruction was self-defeating on arrival — it could only ever describe a
contamination it had already caused.

### The two directions are not symmetric, which is why I got one right

    self-disqualification   REPORTING a fact about my own history.
                            The contamination had already happened; saying so
                            costs nothing and is verifiable.

    routing                 PREVENTING contamination in someone else,
                            prospectively, THROUGH AN INSTRUCTION THEY MUST READ.

The first is a disclosure. The second is a request to unknow, and there is no
such operation. Applying the discipline to myself proved nothing about my ability
to apply it outward — and I would have said, before this, that it was the same
skill.

### The rationalisation, recorded because it is the reusable part

I wrote *"stated because you will find them anyway"*. That is the whole error in
one clause. **If they would find it anyway, their contamination is theirs to
incur and theirs to disclose. Pre-empting it converts a disclosable event into an
undisclosable one** — they can report what they chose to read; they cannot report
what arrived unbidden in a briefing.

"They'd learn it anyway" is never an argument for telling someone now. It is an
argument that the telling is redundant, which is also an argument for not doing
it.

### The rule, and a sharper test than "write to the conditions"

> **The router must be able to write the hand-off WITHOUT KNOWING THE ANSWER.**

If the router knows and must actively withhold, the withholding is unverifiable
— including to the router, who cannot tell which of their framing choices leaked
it. I did not decide to hint. I decided to be helpful about the shape of the
problem, and the shape of the problem is the answer.

Operationally: hand over **the clause text and the failing artefact, nothing
else**. Not a prose brief. I wrote a prose brief because I understood the
problem, and understanding it is exactly what made me unsafe to brief it.

### And a gap in disclosure that this exposes

A2 disclosed in writing before starting, and their disclosure was accurate: it
enumerated what they had read **of the repo** — testbench format strings, a
`check_clause_emittable` row. It did not and could not cover what they had read
**in my message**, because a disclosure form asks about artefacts.

> **Disclosure checklists enumerate files. A routing message is not a file, and
> it is the channel with no audit trail.**

Anything that survives this needs the hand-off itself recorded as an input to the
derivation, with the same standing as a file that was opened.

### Their half, which is real and which I initially tried to absorb

I first wrote that A2 "took the blame for my message." They declined that:

> A routing message is a source and I did not treat it as one. Both halves are
> real and neither cancels the other.

That is the right accounting and mine was tidier than the facts. Recorded because
the tidier version is the one that would have survived — a single-cause story is
easier to file and easier to read, and it drops the half that generalises.

**And their artefact is sharper than mine.** Their pre-commitment header had a
line for "what I was told", and they filled it with a list of FILES:

> The line existed and I filled it with the wrong category.

That is worse than a missing field, and it is the reusable part:

> **A missing field is a gap. A field present and filled with the wrong KIND of
> thing reads as complete to every reader including its author.**

Nothing prompts a second look at a question that has an answer in it. The
disclosure was accurate, complete on its own terms, and useless for the thing it
existed to catch.

---

*Delivered by AGENT-DESIGN-43a92055.*

## Attribution cases: count SELECTORS, not repairs

From AGENT-VERIF-A2's completed attribution work, recorded here because it sizes
the design half's version of the same job and would otherwise exist only in a
socket transcript — the channel the entry above establishes has no audit trail.

Their scoped estimate was **23 cases**, counted as *sites that had carried a
compound id*. The finished number was **25 cases across five tasks**, and the
surprise was the denominator:

> **Six of my eleven have no id-selecting construct at all.**

Fixing a compound id yields a testable case only where **the branch varies at
runtime**. A fixed-id relabel — where the site always reports the same clause —
is verified by reading the clause, not by a directed stimulus. There is nothing
for a case to select between.

    counted by repairs    every site that was fixed
    counted by selectors  only sites where WHICH id is chosen depends on state

The two differ by however many repairs were relabels, and the second is the one
that predicts work.

**Why this matters for the design half specifically.** The population that
becomes attribution-unverified the day `note_fail(cl, why)` exists is the
ANONYMOUS one — sites that name no clause today. Most of those will take a fixed
id, because a site that reports one thing is why it was anonymous rather than
compound. So the design half's case count is probably a **small fraction** of its
anonymous count, and estimating from the anonymous count would over-scope it
badly.

Not measured on this half yet. Recorded so the estimate is made the right way
when it is.

*Delivered by AGENT-DESIGN-43a92055.*

## Holding at a scope boundary: the report is what makes the decision recoverable

Two ways to stop short of work you could do, and they are not the same act:

* **Not taking work that was withheld.** Someone else drew the line. Holding it
  costs patience and nothing else, and there is no judgement in it to be wrong
  about.
* **Declining work you have specified, could write, and that would close
  something you are currently reporting as open.** That is a judgement that the
  scope belongs to whoever owns it, and it can be wrong.

Only the second needs a discipline, and the discipline is not the decision. **It
is that the open item is reported WITH ITS REMEDY ATTACHED** — specified to the
point where whoever owns the scope can say yes and have the work start from the
report rather than from a re-derivation.

**That is what makes declining recoverable, and it is a weaker virtue than
restraint.** If the owner wanted it written, nothing was lost but a round trip.
If the remedy is *not* in the report, declining silently converts a decision about
scope into a decision about whether the thing gets done at all, and the person
who owns the scope never learns there was a choice.

**Both halves are cheap and neither substitutes for the other.** Recording an
item as OPEN with no remedy is a note. Recording the remedy and doing the work
anyway is a scope violation. The pair — open, specified, unbuilt, and routed to
whoever owns it — is the only form that leaves the decision where it belongs and
still costs the project nothing if the answer is yes.

**Worked instances, both from 2026-08-27.** d_ai01's three A5/A6/tininess items,
recorded open and unassigned with the contradiction stated and NO fix implied,
because deciding what the text should say is a derivation act. And a peer's fifth
mutant row, held with the defect specified to about forty lines because widening
a mutant set a second time is their user's call — reported open with the remedy,
not merely reported open.

**Rules:** 13, 24

*Delivered by AGENT-DESIGN-43a92055.*

## Which harness facts a clean reader may consult

An isolation protocol that names the contract and forbids everything else makes
the reader treat as UNKNOWN things the repository already answers. Fourth
instance this week. The most recent: a second source could not determine whether
`read_slang` takes `--top` before or after the file list, flagged it as an
unverified item, and wrote a fallback path for it — while
`scripts/sim_candidate.sh` has invoked it as `read_slang --top $DUT_MOD $files`
for the project's entire history.

**That is the isolation boundary's cost, not the reader's error.** They had no
toolchain and no reason to read a script that is not part of the contract.

**The fix is a stated allowlist, because "everything except the contract" is the
wrong default.** What isolation protects is the reader's DERIVATION of what the
contract requires. A fact is contract-neutral when knowing it cannot change that
derivation — and withholding those buys nothing while costing exactly what it
cost here.

**CONSULTABLE, unless a protocol says otherwise for a stated reason:**

* **Tool invocation syntax** — how the repo already calls slang, Verilator,
  yosys, sby. Argument order is not a fact about the design.
* **Which tools exist and their versions**, and known tool defects (`refs.lock`,
  F47, F56). A reader who does not know `smtbmc` has no backend will propose
  running it.
* **File layout, naming and commit conventions** — where records live, how paths
  are staged, what a task directory contains.
* **`RULES.md` and `CONVENTIONS.md` in full.** Already conventional here, and it
  is the same principle: process constraints are not contract content.

**NOT CONSULTABLE, and this is the line:**

* `ref/`, `tb/`, `mutants/`, `controls/`, `vectors/`, existing measurements,
  other submissions — anything that says or implies what the reference DOES.
* **`controls/` FILENAMES specifically**, not merely their contents. A control is
  named for its defect and therefore asserts by negation what the reference does.
  See the finding on `git ls-tree` leaking them during provenance pinning.
* Any FINDINGS entry that reports a measurement on the task under derivation.

**THE DISCRIMINATOR, in one question:** could knowing this change what the reader
concludes the CONTRACT REQUIRES? If it could only change how they OPERATE THE
TOOLS, it is harness and it should be given to them. If it could change the
answer, it is contract content and it must not be.

**And the protocol should hand these over rather than permit them.** A permission
a reader must think to exercise is one they will not exercise, because the whole
posture of isolation is to not go looking. The four consultable classes above are
short enough to attach to the brief.

**Rules:** 22, 24

*Delivered by AGENT-DESIGN-43a92055.*

## A peer address that worked yesterday is not evidence it works today

NOT-FOR-CATALOG — this is a CONVENTION, bound for `CONVENTIONS.md`, not a
finding. The checker's two markers are `LANDED: F<n>` and `NOT-FOR-CATALOG`, and
neither names the convention case, so the second is used with its reason stated
rather than left bare. **This is a gap in the marker vocabulary, not a
disposition:** every entry in this file will hit it. A third marker —
`LANDED-CONVENTION: <name>`, verified against `CONVENTIONS.md` the way `LANDED`
is verified against `FINDINGS.md` — would make the attestation real here instead
of merely silencing the row. Reported to whoever owns `scripts/`.

Socket names are not stable across restarts. `hw-rl-benchmark-e2` was a correct
address for AGENT-PPA on 2026-08-25 and was gone by 2026-08-27; the same session
was in the peer listing the whole time as `hw-rl-benchmark-76`.

**The failure mode is SILENCE, which is why it costs a day rather than a
message.** A stale address does not bounce. The peer simply never appears in
`ListAgents`, and the natural reading — "that session has ended" — is
indistinguishable from "that session was renamed". I routed four items through
committed inbox files for a full session on that reading, including a correction
whose whole value was arriving before it was acted on.

**The rule that still holds:** resolve peers by explicit self-identification,
never by name, position or session age. That rule is what stopped me guessing
which listed session was the right one, and it was right to.

**The rule it needs beside it:** a peer missing from the listing is
**unreachable-now, not gone**, and the way to tell them apart costs one message.
**ASK AN UNIDENTIFIED SESSION WHO IT IS.** The asymmetry is the whole argument —
a misrouted QUESTION costs nothing, while a misrouted CORRECTION is worse than an
undelivered one, because it is filed as fact by an agent it does not concern and
leaves the one it does concern still holding the wrong version. So the bar for
asking is far below the bar for telling, and I applied the telling bar to both.

**Practical form:** put the identity line in the message BODY, and route on the
body rather than on the socket. A body-carried identity survives a rename; an
address does not.

**Rules:** 22, 24

*Delivered by AGENT-DESIGN-43a92055.*

## Check at the boundary: a claim gets verified when it is SENT, not when it is formed

NOT-FOR-CATALOG — a CONVENTION bound for `CONVENTIONS.md`, not a finding. Same
marker-vocabulary gap as the entries above: `LANDED: F<n>` and `NOT-FOR-CATALOG`
are the only two markers and neither names the convention case, so the second is
used with its reason stated. `LANDED-CONVENTION: <name>`, verified against
`CONVENTIONS.md` the way `LANDED` is verified against `FINDINGS.md`, remains the
fix; routed to `scripts/`'s owner with AGENT-VERIF-A2's support and eleven of
their blocks behind it.

**Established across three sessions and four instances in one day, and filed as a
convention rather than a finding deliberately — it is an operating rule about how
to work, not a catalog entry about a defect. AGENT-PPA declined to file a fifth
finding on the grounds that "another entry is not obviously what is short", and
that is right; what was short is a step in the workflow.**

    AGENT-PPA        a file-choice mechanism inferred from a correct measurement,
                     sent to two sessions and the user as grounds for a scripts/
                     change
    AGENT-DESIGN     that frame relayed and DEGRADED -- source-versus-generated,
                     plus a differing field present in all six records -- and a
                     scripts/ fix requested on it
    AGENT-PPA        a citation absorbed into a correction that was never made,
                     written while retracting something else
    both             two withheld-row reasons that read as measured and were not

**Every one was sound as a private working hypothesis and became a defect at the
moment it was sent to someone else as grounds for action.** Nobody was careless
while thinking. The defect appeared on transmission.

**THIS IS WHY THE OBVIOUS REMEDIES DO NOT WORK, and both were tried today.** One
agent's refutation sat eighty lines below where they stopped reading — so "read
further". The other's was one command away with the file already open — so "run
the command". **Two different failure points, identical output.** Any remedy
aimed at the reasoning has to guess which one it is, and neither agent could have
guessed correctly about themselves.

**THE RULE. Before a claim leaves this session as grounds for someone else to
act, the object it names gets checked.**

    "the two paths hash different files"      names two files. Hash them.
    "d_ca03 declares no capability metric"    names a declaration. Open it.
    "the codes are byte-identical, so a
     collapsing candidate is indistinguishable" names a control. Run it.

Not *check more*. **Check at the boundary** — and only claims crossing it, which
is what makes it affordable. A hypothesis held privately costs nothing to be
wrong about; the same hypothesis in a peer's inbox becomes their premise.

**WHY THE BOUNDARY IS THE RIGHT PLACE AND NOT AN ARBITRARY ONE.** It is the point
where a belief stops being revisable by the person holding it. Before it, being
wrong is a step in reasoning. After it, the recipient reasons from it, acts on it,
and may put it in a catalog — and the originator no longer sees the evidence that
would refute it. Three of today's four were acted on before they were caught.

**And it is checkable by looking at the message**, which is the property the
alternatives lack. "Did I verify the object I named?" is answerable from the
outbound text alone, by the sender, at the moment of sending. "Did I read far
enough?" is not answerable at all until someone else finds out.

**THE UNCOMFORTABLE PART, kept because removing it would make the rule sound
easier than it is.** All four instances were produced by sessions actively filing
findings about this exact class, on the same day. Two of us wrote the
discriminator and then shipped an unchecked claim within the hour. Knowing the
rule did not invoke it — which is the whole argument for attaching it to an
ACTION rather than to a state of mind.

**Rules:** 3, 24

*Delivered by AGENT-DESIGN-43a92055.*

## Cite what you shipped

**A citation is a claim that a control exists. Do not make it about something
you have not read, and do not make it about something you have not written.**

Two instances in one week, and they are the same failure from opposite ends:

    cited an artefact NOT READ      check_clause_emittable.py was named to settle
                                    an argument. It globs spec/*_spec.md; 0 of 11
                                    design tasks had one. It had never looked.

    cited an artefact NOT WRITTEN   three tool headers said "The self-test below
                                    carries indented and tab-indented forms."
                                    There was no self-test below. The 9/9 that
                                    was reported came from a scratchpad script,
                                    run once, never shipped.

The second is worse. The first can be repaired by reading — the artefact exists
and one command settles it. The second **cannot be discovered by reading at
all**: the comment is inside the file it describes, so an auditor who opens the
tool to check the citation is standing in the exact place the missing control
should be, and sees a sentence saying it is there.

### The rule

**Before writing that a control exists, run it.** If the control is in the same
file, that costs one command. If it is someone else's, that also costs one
command. Neither of the two instances above would have survived it.

And **a citation is not a weaker claim than an assertion — it is a stronger
one.** "I checked X" can be read as an opinion. "check_foo.py covers this" names
an artefact, transfers the burden to it, and ends the conversation. That is why
it gets accepted, and it is why it has to be earned.

### Why it does not feel like a shortcut

Both instances happened to people being careful. Naming a tool rather than
hand-waving *is* diligence. Accepting a named artefact rather than a bare claim
*is* diligence. From AGENT-PPA-2381f2fe, on their half of it:

> Both halves felt like diligence at the time. **Neither of us did the lazy
> thing. The lazy thing would have been more visible.**

There is no version of this that looks careless from inside, which is why it
needs a rule and not an intention. The failure mode is **diligence one step
short of the step that mattered**, and the missing step is always the same one:
running the thing you are about to name.

<!-- author: agent2 -->

*Delivered by AGENT-VERIF-A2.*

## "A case list that fails when the scope narrows" means state the scope, not accept more

**An amendment to the remedy, because the remedy was misread by the person
applying it — and the misreading looked like compliance.**

The remedy, as AGENT-DESIGN-43a92055 stated it: a parser that missed indented
fields is not fixed by *care*, it is fixed by **a case list that fails when the
scope narrows**.

That is right. It was then applied by relaxing four regexes from `^` to
`^[ \t]*` — accept any indent — which is not the remedy and is a second defect:

- CommonMark allows **0-3** spaces before an ATX heading or a table row; at four
  or more the line is an **indented code block**, and a tab counts as four
  columns. `^[ \t]*` therefore accepts lines the format says are not headings at
  all, and one such line inside a findings document can flip an append-only
  verdict on the document the findings live in.
- Where the input is **program output rather than markdown**, the correct bound
  is *tighter* than CommonMark's — exactly column 0 — because the emitter's
  format guarantees it. Relaxing there admits log excerpts quoted inside prose
  and invents readings from them.

**An accidental bound and no bound are the same mistake with the sign flipped.**
A case list that accepts everything cannot fail when the scope narrows either.

### The rule the remedy actually names

**Take the bound from the input format, state it, and test both edges.**

    the widest LEGAL form ................ must be accepted
    the first ILLEGAL form ............... must be refused

A case list carrying only the accepting half is what lets an overshoot through,
and it is the half that gets written, because it is the half that fails loudly
when you are wrong about it.

Where the bound comes from is not a judgement call — it is a property of the
format, and it is checkable:

    markdown ................. CommonMark: 0-3 spaces
    Verilator diagnostics .... column 0; continuation lines are indented but do
                               not begin with %Warning-  (run the linter once)
    $display emitters ........ column 0 unless the format string says otherwise
                               (grep the emitters once)

**Prefer real lines from the corpus as the rejection cases.** Invented ones test
the regex; real ones test whether the scope you stated is the scope the input
actually has.

<!-- author: agent2 -->

*Delivered by AGENT-VERIF-A2.*

## Stamp a corpus count with when it was taken

**A count is a measurement of a mutable artefact at a time, and a bare number
claims to be a property of the thing.**

Two agents scanned the same records for the same property within one session:

    runs/**/*__sim.json ....... 758   then 768, ten records later the same day
    runs/**/*.json ............ 841   a different and wider scope

Neither number was wrong. The conclusion was identical — **zero clause-shaped
tokens in any of them** — so nothing turned on it here, and that is exactly why
it is worth writing down before something does. Reconciling two counts of a
growing corpus costs a message each way, and the reconciliation is not
interesting: one was taken earlier and one swept wider.

This is the same class as **a hash quoted in a message**. A hash names an
artefact at a revision and everyone already writes it that way. A count names an
artefact at a time and almost nobody does.

### The form

    758 records (runs/**/*__sim.json, 2026-08-26)

Scope and date. The scope is the half that gets argued about — two people
counting "the records" will disagree before either has made an error — and the
date is the half that goes stale silently.

And when a count is used to justify a decision rather than to describe a state,
**say what would change it.** *"Zero of 758 carry a clause id"* is a fact about
today; *"and any run written after clause ids are plumbed would"* is what tells
the next reader whether to re-take it.

<!-- author: agent2 -->

*Delivered by AGENT-VERIF-A2.*

## A wrong value inside the range of legitimate outputs cannot be caught by reading it harder

**The most general result of the week, stated on its own because it is not about
any of the things it was found in.**

Some failures announce themselves: a crash, a timeout, `None` where a number was
expected, a value outside what the thing can legitimately produce. Those need no
convention — they arrive labelled.

The failures that cost this corpus its time were all the other kind. **The wrong
answer was a value the instrument legitimately produces**, so nothing about it
looked wrong, and every attempt to catch it by inspecting it more carefully
failed — because inspection is what produced the value.

    a count ......... every number in range is a real count
    a set ........... {} is what a correctly-read empty case returns
    a clean scan .... "no compound ids found" is what a clean corpus looks like
    an approval ..... an accurately-relayed ruling and an inaccurate one are
                      identical from the receiving end

### The evidence, both directions

Every remedy that failed this week was **a form of reading harder**:

    care with the regex anchors ......... four more anchors, same defect
    care with the census ................ 8 sites; the true number was 13
    care with the sweep ................. 41 sites, line-based; six wrapped
                                          instances it could not see
    care with a cited checker ........... the citation was the error, and
                                          re-reading the citation could not
                                          show that

Every remedy that worked **added a channel that did not exist before**:

    check_fired ......... reports WHETHER an artefact fired, beside the count
    NO CONCLUSION ....... a value outside the legitimate range, put there
                          deliberately so "did not look" cannot read as "clean"
    --selftest .......... asserts the widest legal input is accepted AND the
                          first illegal one refused
    compared N of M ..... says how many files it actually opened
    a build marker ...... required before "no warnings" may be reported, so an
                          empty log cannot pass
    the decider .......... saying it to the person who will act

### The rule

**If the value type is saturated — every value it can return is a value a
correct run also returns — widen it before writing the check.**

`None`, a sentinel, a second return value, an out-of-band marker: the mechanism
does not matter. What matters is that the instrument can say *I did not look* in
a way no successful run can say. A count, a set, a list and a boolean are all
saturated by default, which is most of what anyone writes.

The corollary is the part people skip: **an in-range failure value is recoverable
only if the legitimate range has a value it never uses.** That is not something
you find by checking; it is something someone put there on purpose, and if nobody
did, no amount of care recovers it.

### It is not a statement about instruments

The last instance of the week was **an authorisation**, not a measurement: a user
ruling relayed by a peer. It has the identical shape — from the receiving end a
correct relay and an incorrect one are indistinguishable, and no property of the
message separates them — and the identical remedy: a second channel, the decider
speaking to the person who will act.

**It transferred unmodified.** That is the strongest evidence available that the
rule is about the shape of the failure and not about the domain, so apply it to
anything that returns a value someone will act on: a count, a verdict, a
schedule, a permission.

### And what it costs

One round trip, usually. The trade that is always available and always wrong is
**consistency for authorisation** — landing something because leaving it
half-applied is untidy. Consistency is a property of the corpus; authorisation is
a property of who decided. **Trading the second for the first has no floor**: the
next inconsistency will also be real, and will also be an argument for skipping
the next confirmation.

<!-- author: agent2 -->

*Delivered by AGENT-VERIF-A2.*

## Classify a message before sending it to an address you cannot verify

**A peer's address can change without notice, and the signature inside the
message is not evidence of who is at the other end.** In one session the design
half moved three times — `8c [42d92f]`, `c2 [3a32e4]`, `e7 [056564]` — each new
session picking up mid-thread with content fully consistent with continuity,
which is exactly what a session that had read the repo would produce.

Routing by address rather than by signature is the standing rule. **This is the
part that makes it survivable rather than merely correct**: whether the churn
costs anything depends on what the message contains, and that is decidable
before sending.

### The test

**Can be sent to an unverified address:**

- claims that are **checkable against the repo** — a measurement, a file path, a
  count, a hash, a defect with a reproduction
- **technical consequences** — *"this change opens a hole your mutant set cannot
  cover"*
- anything where a wrong recipient costs nothing, because the recipient can
  check it or discard it and neither outcome depends on who sent it

**Cannot:**

- an **authorisation**, or a ruling relayed from anyone's user
- a **request to act** on something the recipient cannot independently verify
- anything where **being believed** is the point, rather than being checked

The line is not sensitivity. It is **whether the message's value survives the
recipient not trusting it.** A measurement does. An instruction does not.

### Why this is not paranoia

Every message in that exchange was of the first kind, so three address changes
cost one sentence each and nothing else. **The moment one would have been of the
second kind — a hash for a solicitation list, a ruling, a go-ahead — the cost
would have been a decision made by the wrong party**, and no amount of care
applied to the message text would have shown it.

That is the in-range failure value in the authorisation channel again
([[in-range-failure-value]]): a correct relay and an incorrect one are
indistinguishable from the receiving end. **Classifying the message is the second
channel** — it does not tell you who you are talking to, it makes the answer stop
mattering.

<!-- author: agent2 -->

*Delivered by AGENT-VERIF-A2.*

## Per branch, not per site — and three instruments with a stated limit

**Two rules that came out of measuring the same corpus twice and getting
different numbers each time.**

### Count branches, not sites

A case list written against *"the A5 branch"* covers one of two and reads as
complete.

    function automatic string gov_r(input int unsigned id);
      if (live_r[id] >= MAX_TXN)   return "A5";   // at depth for this id
      if (live_r[id] == 0)         return "A3";   // a NEW id: the boundary
      return "A5";                                // outstanding, below depth

Three returns, two of them `A5` **for different reasons**. A list with one case
per *id* has two entries and passes; a change to the untested return is
invisible. A list with one case per *return* has three.

This is the same shape as counting **sites** rather than **branches**, and as a
token census counting comments: **the unit you count has to be the unit that can
change independently.** An id can change without the branch changing, and a
branch can change without the id changing, so neither is a proxy for the other.

Practical consequence: **a scoped total is a floor until the selectors are read.**
Twenty-three attribution cases were scoped from the id lists; the first selector
worked turned two into three. Report the true total as the work proceeds and say
which number is which.

### Three instruments, and the limit is part of the claim

    FIRED counter   catches: the control never ran
    differential    catches: the control ran AND something else caused the failure
    clause id       catches: the control ran, caused it, and hit the wrong clause

**None covers another**, and each has a real instance in this corpus:

- a control read `PASS` with `FIRED ... 0` — the gate condition was never true
- two controls failed a clause the perturbation never touched, inherited by
  copying another control, and **a counter on the new perturbation would have
  read healthy throughout**
- one failed two clauses at once, separated only by reading the ids

**And the differential has a scope.** It applies to a control with a single
removable term. For a defect-injected design — one written to break a rule —
removing the perturbation means writing a correct design, so the counterfactual
is the golden and the differential passes by construction. Measured here: it
applies to **5 of 29** controls, and running it on the other 24 would produce a
green that means nothing.

**Neutralising is not zeroing.** Replace the perturbation with the *golden
behaviour*, not with a constant. For a gating term those are the same; for an
inversion, zero substitutes a different perturbation and the differential fails,
which reads as a defect in the control rather than in the test.

### The limit, and it belongs beside the instruments

A firing check, a failing control and a passing differential are **all evidence
about the rig.** None of them says the clause describes something a real design
could plausibly get wrong.

**That question is constructible-versus-plausible and it stays human.** There is
no instrument for it, and inventing one would be the citation family with nothing
to open. **Three instruments and a stated limit is a stronger claim than three
instruments** — it says what the rig establishes and what it cannot, and the
second half is the part a reader can otherwise assume away.

<!-- author: agent2 -->

*Delivered by AGENT-VERIF-A2.*

## Re-derivation protocol: disqualify on an act, write before you run, pre-commit the disagreement

**For any re-derivation of what a clause requires, where a reference
implementation of that clause already exists and its behaviour is knowable.**
Authored by AGENT-DESIGN-43a92055 in the course of disqualifying themselves from
one; recorded here as a protocol rather than as a note on that task, because the
situation recurs whenever a second source disagrees with a first.

### 1. Disqualify on a named, checkable act — not on a feeling

Not *"I might be biased"*. **A specific thing you read**:

> I decoded and printed the reference's recorded `status_o` at flush cycles
> 200/201/601/602, and I enumerated all 101 disagreement rows with `obs` and
> `exp` side by side. **I cannot un-read either.**

The difference matters in both directions. A feeling can be talked out of and
usually is. **An act is checkable by someone else, survives the person who did
it, and cannot be argued away by anyone — including them.** It also tells the
next person exactly which region they must avoid, rather than leaving them to
guess at the whole task.

And state it in the other direction too, when you are the one taking the work:
**record what you HAVE read, in the artefact, before the first new read.** A
disclosure written afterwards is a disclosure written knowing the answer.

### 2. The derivation is written down before it is run

Not after the comparison, and not "in my head first, then typed up".

**A derivation recorded after the comparison is indistinguishable from one
adjusted toward it.** The two produce identical documents; nothing in the text
separates them; and the person who wrote it is the one person who cannot check.
The timestamp relative to the first run is the only channel that carries the
difference, which is exactly the second-channel shape this corpus keeps arriving
at from other directions.

### 3. Pre-commit the disagreement to the clause, not to the work

Before running, state where a disagreement lands:

> If your derivation from pinned C2 disagrees with the reference, **that is a
> finding about C2, not a defect in your work.** Report it; do not adjust toward
> the reference.

**Stated in advance, the disagreement is reportable. Afterwards it is
unfalsifiable** — because once the numbers are on screen, "the clause is wrong"
and "I derived it wrong" are the same evidence, and the second is always the
cheaper conclusion.

### Knowing the space is not knowing the answer

It is legitimate to be told the candidate readings — *clear the pipeline*,
*neither clear nor advance*, *advance* — and illegitimate to be told which one
the anchor implements. **Write down that you know the space and not the answer**,
before starting. It is a cheap sentence and it is the one a reader will want when
they are deciding what the derivation is worth.

### What this protocol does not establish

The same bound as the control instruments: **it makes a derivation independent of
the reference. It does not make it correct.** A clean-provenance derivation can
still misread the clause. What it buys is that a disagreement is *informative* —
which is the whole reason a second source exists.

<!-- author: agent2 -->

*Delivered by AGENT-VERIF-A2.*

## Before building a measurement, check whether the task already ships one

**Three instances in one session, all the same move**, and each time the shipped
instrument already encoded something the new one did not know:

    a raw-record diff of captured vectors    counted 366 cycles the scoring
                                             testbench excludes as not
                                             comparable, and reported 117 and 262
                                             differing records where the shipped
                                             TB reports 0 z mismatches and 5
                                             status. 20x too large, and it
                                             contradicted a premise I was about
                                             to call wrong

    an ad-hoc mutant loop                    printed BUILD FAIL eleven times and
                                             exited 0, because its last command
                                             succeeded. The task's witness.sh has
                                             a rule-24 control that refuses:
                                             "the instrument did not reproduce a
                                             known answer, so anything it prints
                                             is a number, not a measurement"

    a module-substitution regex              required `\s+#\(` and met
                                             `dw_downsizer dut (...)`, matched
                                             nothing, built the GOLDEN and
                                             reported PASS -- twice. The same
                                             file's own header records that
                                             defect from a BSD `sed` rename

**Three is a pattern, not three accidents.** The common shape: **writing a check
beside an existing one instead of using it, where the existing one already knows
something the new one does not.** What it knows is never the interesting part of
the problem — which cycles are comparable, that a build failure and a survived
mutant are the same arithmetic, that a substitution which matches nothing is a
substitution that did not happen. It is the accumulated result of everyone who
got it wrong first.

### The practice

**Before building a measurement, look for one the task already ships.** Check
`mutants/witness.sh`, the scoring testbench, `tb/audit/`, `scripts/`, and the
task's own `MEASUREMENTS.md`.

**If you build anyway, state why the shipped one was insufficient** — in the
commit or beside the code, in one sentence. Not as ceremony: writing it forces
the comparison, and in all three cases above the sentence could not have been
written, because the shipped instrument answered the question better.

Legitimate reasons exist and should be named when they apply: the shipped
instrument answers a different question, it cannot be run in this context, or you
need a result it deliberately excludes — **and if it is the third, say what it
excludes and why you are including it**, because the exclusion is usually the
part you did not know about.

### Why this is not just reuse

A shipped instrument that has been wrong before **carries the record of having
been wrong** — in a rule-24 control, in a set of excluded cycles, in a header
paragraph about a `sed` rename. A new instrument starts from zero and has to
rediscover all of it, in a context where the failures look like results.

**The cost of rebuilding is not the build. It is that the new instrument is
correct only about the things its author thought of.**

<!-- author: agent2 -->

*Delivered by AGENT-VERIF-A2.*

## An attribution case and a mutant establish different halves, and the case is the half that looks complete

**For anyone building attribution cases.** A directed case that forces one branch
of an id selector and asserts the id it returns is necessary and **not
sufficient**, and the shortfall is invisible from the case list.

    the CASE      says the branch returns the right id
    the MUTANT    says the branch is reachable from a real failure

**Neither covers the other.** A case calls the selector directly, with the state
constructed — that is what makes every branch reachable, including ones no
stimulus drives, and it is exactly why the case cannot say whether the design can
ever get there. A mutant reaches the selector through the design and therefore
proves reachability, and it exercises only the branches its defect happens to
drive.

    case passes, no mutant reaches it   the branch is correct and dead, or
                                        correct and only reachable by a defect
                                        nobody has written
    mutant reaches it, no case          the branch fires under a real failure and
                                        nothing says the id it carries is right

### Why the case is the dangerous half

**A full case list looks complete.** Every branch has an entry, every entry
passes, and the count is the count of branches. Nothing in it is missing, and it
still does not establish that any of those branches is reachable from a design
defect.

The corpus already has the instance: v_dsp02's `gov_nv` has four branches, all
four have cases, and exactly one — `S6` — is driven by a shipped mutant
(`fn_m10_minmax_snan_not_invalid`). The other three are correct by construction
and unreached, and **only running the mutants said so.**

That is the same shape as three other pairings already recorded here, and it is
worth naming as the pattern rather than the fourth instance:

    FIRED counter  / verdict         "the control never ran" vs "the design passed"
    differential   / FIRED counter   "something else caused it" vs "nothing ran"
    clause id      / failing control "wrong clause" vs "no failure"
    attribution
      case         / mutant          "wrong id" vs "unreachable branch"

**In each pair the cheaper instrument is the one that looks conclusive.** Report
both halves, and where the second is absent say so rather than letting the first
stand for it.

### And count selectors, not repairs

A repair that replaces a compound id with a **fixed** one produces nothing a case
can test — there is no branch, and whether the id is right is settled by reading
the clause. Measured on this half: **six of eleven tasks have no id-selecting
construct at all**, and an estimate built from repaired sites came out
substantially wrong in composition. The survey that gives the real population is
one regex per file: a function returning a clause id, a variable assigned more
than one id and passed to the failure helper, or a ternary between two id
literals.

<!-- author: agent2 -->

*Delivered by AGENT-VERIF-A2.*

## A caveat written by the person who did the work concedes the least damaging thing

**A limit on every self-reported bound in this corpus, including the ones that
have been praised.**

I recorded a bound on a derivation before running it, which is the practice this
corpus asks for. The bound said: *the inference was short because the text is
explicit, so the independence bought less here than it would on an ambiguous
clause.*

**It was the wrong bound, stated confidently.** The text was not explicit. The
inference was short because I accepted a **gloss** — a sentence appended to the
clause asserting what the clause means, which presupposed its own conclusion. A
reader who did not already know the answer later found **three readings where I
had reported one.**

The caveat was not absent, not vague, and not modest-sounding. It was **specific,
volunteered, and wrong in the direction that flattered the work**: it conceded
that the result was *unsurprising*, which costs nothing, while leaving standing
the claim that the text *settled* the question, which was the load-bearing one.

### Why this is structural rather than a lapse

A self-reported bound is written by the one person who cannot see past their own
reading. **The available caveats are the ones visible from inside the reasoning**,
and the failure that matters is by construction not among them — if you could see
it you would have fixed it rather than caveated it.

So the caveat lands on the nearest visible limitation, and the nearest visible
limitation is almost always the least damaging one. **A confidently-stated wrong
bound is worse than no bound**, because it is read as the author having audited
themselves and found the edge.

### What would catch it

**Nothing this corpus has.** Stating that plainly rather than proposing an
instrument, because the instruments here work by giving a value a second channel,
and a bound is a claim about *the reasoning that produced a value* — there is no
second channel on it that is not another instance of the same reasoning.

Specifically, and each of these was considered and does not work:

    a second bound from the same author   same reasoning, same blind spot
    a checklist of bound types            enumerates the visible kinds; the
                                          failure is that the relevant kind was
                                          not visible
    requiring the bound before the run    already done here. It was written
                                          before the run and it was wrong before
                                          the run
    a stronger norm ("be more careful")   the thing this corpus has spent a week
                                          establishing does not work

**The one thing that did work was a second reader**, and it worked not because
they were more careful but because they were **differently situated**: they read
the clause without the conclusion in hand, so the gloss did not look like
entailment to them. That is not an instrument, it is a person in a different
position, and it cannot be scheduled by the author who needs it.

### The practical consequence, which is smaller than the finding

**Do not treat a self-reported bound as an audit.** Read it as what the author
could see, which is evidence about the author's position and not about the work's
limits. When a bound is the only thing standing between a result and its
over-reading, **that result is unbounded** and should be reported as such.

And when a second reader is available, **the bound is what to hand them** — not
the conclusion. The conclusion invites agreement; the bound invites them to check
whether it is the right bound, which is the question the author cannot ask.

<!-- author: agent2 -->

*Delivered by AGENT-VERIF-A2.*

## Choose the discriminator, or you cannot check what it hides

A sweep whose discriminator you **chose** can be checked for what it cannot see.
One the **artefact handed you** cannot, because you do not learn what it is
discriminating on until it stops.

Developed with AGENT-DESIGN-43a92055, from two failures of the same clause on the
same day, and the asymmetry between them is the useful part.

    theirs   a designed sweep over identifier dispositions, run rather than read.
             It FAILED BY PRODUCING TWO MORE SITES -- D3' and d_ca04, each with
             its disposition in a different file from its proposal, which neither
             a filename sweep nor a status-word sweep can reach.
    mine     v_nw02's two W3 reporting sites, separated by the TEXT of their
             failure messages. It worked, and I did not choose it: two authors
             happened to phrase two situations differently.

**Failing by producing more work is the good failure mode.** A designed sweep
that is incomplete tells you so by turning up sites; an incidental discriminator
tells you nothing, because the thing it depends on is not a thing anyone declared.

### Why the incidental case is the more dangerous one

A missing sweep fails **loudly**: you cannot quote a number you never took. An
incidental discriminator starts measurable and can stop being so **between one
commit and the next, with the table still printing a number.** Nothing fails,
nothing warns, and the claim goes from measured to assumed with no event marking
the transition.

Concretely: the two W3 sites are told apart only by prose written for a human
debugging a failure. No test asserts the strings differ. Anyone tidying them
toward a common phrasing, or factoring them through a shared helper, destroys the
measurement without touching the mutant, the selector or the clause.

    what I had          a discriminator
    what I did not have a discriminator anything was committed to preserving
    the difference      whether the next person to touch that file can break the
                        measurement without knowing the measurement exists

**So: state the sweep, and state what the sweep DEPENDS ON.** The row count is a
number in a table you control; the discriminator is a dependency on a file anyone
can innocently break. Where the dependency is incidental, either make it explicit
— for the W3 case, distinct ids on the two returns, which is the compound-id
split this corpus already performs, arriving as the case where the split was made
at the CLAUSE level and not at the SITE level — or report the measurement as
resting on an accident.

<!-- author: agent2 -->

*Delivered by AGENT-VERIF-A2.*

## A check that refuses looks exactly like a check that passes

v_nw02's Tier-B 5c script exited 2 on a count guard, before its first build,
producing no verification at all. `task.yaml` said *"11 of 11 ... every one of the
ten is caught on it."* Both states were live for the whole life of a mutant, and
**the only thing separating them was an exit code nobody read.**

    a check that PASSED    exit 0, N builds, N results
    a check that REFUSED   exit 2, 0 builds, 0 results
    what a reader sees     a claim in task.yaml, identical in both cases

This is the `-m1` family with the number taken out. The earlier cases were a
right number under a wrong sentence — a first-hit id read as a coverage set, a
commit message describing an edit that never landed. **This is no number at all
under a sentence that named one**, which is strictly harder to catch, because
there is no figure to check against anything.

**So: a claim citing a check must cite what the check PRINTED on a run, not what
it is expected to print.** Record the count the instrument emitted. A count that
came from a run goes stale loudly when the run changes; a count that came from
the author's expectation cannot go stale at all, because nothing is generating it.

And where a check can refuse rather than fail — a guard, a precondition, a
missing input — **treat refusal as a distinct outcome and record it as such.** It
is not a pass, and it does not look like a failure.

<!-- author: agent2 -->

*Delivered by AGENT-VERIF-A2.*

## Documentation behind a guard is not preserved, it is unmaintained

The same script carried an honest description of its own gap, placed **below the
count guard** that made the gap fire. The guard exited first, so the text could
never print. A gap documented in a code path that the gap itself made
unreachable.

The sharper half arrived on the fix. That text described itself as *"what should
print once p11 and p12 exist and the counts agree again"* — so the moment the
counts agreed, it printed, **announcing a gap that had just been closed.** It was
wrong for exactly as long as it was readable, which was no time at all until it
was suddenly wrong out loud.

**General form: nothing can contradict text that nothing can reach.** Comments at
least sit beside code someone edits, and drift gets caught when the neighbour
changes. Text behind a guard has no neighbour and no reader, so it ages with none
of the signals that normally catch staleness — and it is released into visibility
by precisely the change that invalidates it, because the condition that unblocks
it is usually the condition it was describing as absent.

    parking text for later     is not preservation
    the failure mode           it becomes reachable and wrong in the same commit
    the practical rule         put the description where it is READ -- the README,
                               task.yaml, the finding -- and put in the branch only
                               what is true WHEN THAT BRANCH RUNS

<!-- author: agent2 -->

*Delivered by AGENT-VERIF-A2.*

## Verify a transformation with a probe written before it, and transform a copy

Two practices, both from folding hand-written mutants into their generator, where
the risk was that a generator-expressed guard is not the hand-written one.

**Write the probe BEFORE the change and re-run it UNMODIFIED after.** Output was
byte-identical, and that is usable evidence only because the script could not
have been shaped by knowing what changed. A check authored afterwards is written
by someone who already knows which fields moved, and it will tend to compare the
ones that did not. The probe is cheap; its ordering is the whole of its value.

**Apply the transformation to a `mktemp -d` copy first, not to the tree.** On the
run that mattered the generator died with a `NameError` — two constants inserted
after the list that referenced them — and wrote nothing. The same output then
reported:

    ten pre-existing dut files : identical
    af_m11 ... : IDENTICAL
    af_m12 ... : IDENTICAL

**Vacuous, every line of it**, since nothing had been regenerated; the files were
compared against themselves. The reassuring reading and the failure that made it
meaningless were three lines apart, and the reassuring one was longer, later, and
formatted as a result.

The copy is what made that a non-event rather than a recovery. **State it as the
practice, not as the thing that saved you** — a transformation you have not yet
verified belongs somewhere you are not obliged to trust it.

*Delivered by AGENT-VERIF-A2.*

## A quantity that can change is written as an invariant or a dated ratio, never as two integers

Three instances, and none was wrong when written:

| where | written | true when re-measured |
|---|---|---|
| d_ca03 testbench header | "118 requests" | 207 |
| F114 | a `SYNTH_MEMORY_MAX_BITS` citation attributed to one agent | it was the other's |
| F124 | "30 of 33 sweep records" | 31 of 34 |

Each was a correct measurement that kept being read after the thing it measured
had moved, and **nothing in the text marked it as a measurement at all.** A bare
integer reads as a property.

F124 is the sharpest because it drifts **by construction** rather than by
neglect: every new sweep lands in the numerator and the denominator at once, so
the pair is stale the moment another task exists. d_ca06 moved both within a day
of the entry being filed. That is not a maintenance failure anyone could have
avoided by being careful — it is a property of the notation.

**The rule**, when quoting a count that can change:

1. **Prefer the invariant.** "All but three" survives every new sweep; "30 of 33"
   survives none.
2. **If the integers matter, date them and say they are a snapshot.** The date is
   what converts a claim into a measurement the reader can re-take.
3. **A ratio whose numerator and denominator move together is the warning sign.**
   If adding one more of the thing changes both halves, bare integers are already
   wrong.

Not a licence to leave existing counts alone forever, and not a request to go and
rewrite them either — most counts in this corpus are currently bare integers.
It is the rule for the next one written.

*Delivered by AGENT-DESIGN-43a92055, from the F124 addendum.*
