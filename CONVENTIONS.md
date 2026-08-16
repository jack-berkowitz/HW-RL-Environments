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

## No metric may be quoted from a run that failed its own gate

A build that misses timing still produces an area number, a power number and a
cell count. They are real numbers from a real run, and they are **not results**:
they describe a configuration the design cannot be operated at.

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

## The oracle must be an artefact nobody on this project wrote

**Locally authored code generates INPUTS. It never generates expected values.**

The tempting arrangement is a local model that computes expected results,
cross-checked against the vendored anchor, with disagreements investigated. That
leaves a hole: **a shared misconception survives the cross-check**, because both
sides agree for the same wrong reason -- a corner of the standard misread the
same way twice.

Invert it:

1. local code generates **inputs only**
2. every input is run through the **anchor**
3. the **anchor's output** is the expected value

A local bug can then cost *coverage* -- a corner never generated -- and can never
produce a wrong expected value.

This is not hypothetical. Building `d_dsp02`, a hand-computed IEEE-754 case was
wrong on the first attempt and was caught **only because the anchor disagreed**.
Had that same misunderstanding been coded into a model producing expected values,
the cross-check would have agreed with it.

**The consequence is that coverage floors carry the whole weight.** Expected
values are safe by construction; input coverage is not. Every floor must be
stimulus-side, and adding a stimulus category without adding its floor is how
this gets quietly undermined.

## When a check and an implementation disagree, disambiguate

A second source failing a check does **not** by itself mean the check is
over-constrained. Establish which is wrong first:

1. run the failing input through the **anchor**
2. second source disagrees with the anchor -> **the second source is wrong**
3. second source agrees with the anchor and the check still fails -> **the check
   is over-constrained**

Taking the wrong branch loosens a check to accommodate a bug, and **a loosened
check is invisible afterwards.**

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

## Timing closure has ONE authoritative source

**Closure comes from `find_fmax.py`'s own classification, which reads the ORFS
metrics. Never from grepping an intermediate log.**

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

## Shared: toolchain — **migrated Icarus → Verilator**

Correctness simulation now runs on **Verilator 5.046** (`--binary --timing`).
PPA/synthesis was never on Icarus and is untouched. Icarus 13 is still installed
and the Tier-2 harnesses still run under it — see "portable subset" below.

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


