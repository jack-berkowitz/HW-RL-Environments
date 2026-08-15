# Harness conventions and Tier-2 build notes

> **RELOCATED from `testbenches/TierTwo/NOTES.md`.** The tier task directories
> were removed; this file survives because it is the companion to the canonical
> style exemplars `testbenches/conventions/rob_tb.sv` and `fifo_tb.sv`, and
> because the shared sections below are methodology that still applies. The
> per-module sections are a historical record — those RTL files no longer exist
> and are recoverable from git history.


One file rather than five near-identical ones: the toolchain findings below are
identical for every Tier-2 module, and duplicating them per module would mean
five copies to keep in sync. Per-module sections follow the shared section.
**Flagging this as a deviation** from the "a short `NOTES.md` per module"
wording — say the word and I'll split it.

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

1. **`ncache` golden — a real RTL bug** (and it had already propagated into
   `candidates/TierTwo/ncache.sv`). `B_req_ready` budgeted the PQ slot that port
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
   and fixed** — 5 in `rob_tb.sv`, 3 in `TierTwo/softmax_tb.sv` (Tier-1 at the
   time; softmax has since been reclassified to Tier 2), 2 in
   `TierOne/uart_tb.sv` (the pre-existing ones were equally broken, just never
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

* `testbenches/TierOne/uart_tb.sv` is **byte-identical** to the committed
  baseline apart from the two format-string merges made in this migration. The
  `rx_valid` monitor and `rxv_clear()` bookkeeping were never touched.
* `candidates/TierOne/uart.sv` is **wholly replaced** vs. the committed baseline
  (469 lines changed, a different implementation).

Controlled experiment — same unchanged testbench, only the DUT swapped:

| DUT | Verilator | Icarus |
|---|---|---|
| milestone-1 `uart.sv` (`git show HEAD:candidates/TierOne/uart.sv`) | FAIL, 9 failures, all in R7 | FAIL, 14 failures |
| current `candidates/TierOne/uart.sv` | PASS | PASS |

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

## Shared: layout decisions

- `interfaces/` and `testbenches/` were still flat. Created empty `TierOne/` and
  `TierTwo/` subfolders in each; **existing Tier-1 files were left untouched in
  place**, as instructed.
- Goldens go to `reference_solutions/TierTwo/<module>.sv`. The prompt's
  deliverables checklist also mentions `harness_validation/<module>_golden.sv`;
  these two conflict, and I used `reference_solutions/` because it is the one
  given an explicit rationale and a "create this folder" instruction.
  **Needs confirmation.**
- Throwaway mutants live in `sandbox/mutation_tests/TierTwo/<module>/`.

---

## Module 1 — Reorder Buffer (ROB) — **COMPLETE**

Files: `interfaces/TierTwo/rob_iface.sv` (removed), `testbenches/conventions/rob_tb.sv`,
`reference_solutions/TierTwo/rob.sv`,
`sandbox/mutation_tests/TierTwo/rob/{rob_mut1_ooo_commit,rob_mut2_double_commit,rob_mut3_flush_offbyone}.sv`

### Scope decisions — confirmed

- 2-wide dispatch / 2-wide commit, `DEPTH` parameterizable, default 16.
- Atomic dispatch-group allocation, rejected whole via `dispatch_ready`.
- Flush squashes strictly younger than `flush_rob_idx`; the entry *at*
  `flush_rob_idx` still commits.
- A completion landing on an entry being flushed the same cycle is **dropped**.

### Scope decisions — resolved because the prompt was ambiguous (**confirm or override**)

1. **`dispatch_ready` is `free_entries >= 2`, independent of `dispatch_valid`.**
   Taken literally from the prompt. The alternative (`free >= popcount(valid)`)
   would let a 1-wide group in with one entry free, but creates a combinational
   valid→ready path. Cost of the literal reading: up to one entry can sit unused,
   and `rob_full` is *not* the inverse of `dispatch_ready`. Documented in the iface.
2. **Compacted lane allocation.** `dispatch_rob_idx[1] = tail + (valid[0] ? 1 : 0)`,
   so `valid == 2'b10` allocates at `tail`, not `tail+1`. The prompt didn't say.
3. **All outputs combinational**; state updates only at the edge. An entry
   completing at edge N commits at N+1, never at N. Without this the commit
   protocol isn't checkable cycle-by-cycle.
4. **Exceptions terminate the commit group.** An entry committing with
   `commit_exception=1` is the last to commit that cycle. The ROB never
   self-flushes — it reports, the core reacts. The prompt gave the ROB no
   exception output other than `commit_exception`, so this had to be pinned down.
5. **Commit/flush overlap — a genuine hole in the spec as written.** If
   `flush_rob_idx == head`, then `head+1` is simultaneously *squashed* (strictly
   younger than the flush point) and *eligible to commit* (allocated + complete).
   Resolved: **an entry may never both commit and be squashed**, so
   `commit_valid[1]` is forced to 0 in exactly that case. This is a nasty corner
   and good benchmark material — directed test **D6** targets it specifically, and
   it was hit 30 times in the random run.
6. **Dispatch is ignored in any cycle where `flush_valid` is asserted** (the front
   end is being redirected). Also unstated in the prompt.

### Why this testbench should be trusted

The model alone is not the grader. Every dispatched instruction carries a
monotonic **sequence number**, and the commit stream is graded against that
sequence *using the index the DUT itself reports* — not the index the model
expected. That distinction matters: an earlier draft looked up the seq via the
model's expected index, which quietly degenerated into the model checking
itself. Caught during mutation testing and fixed; it is the reason mutant 2 now
trips the order/payload checks rather than only occupancy drift.

Layered checks: commit contiguity · commit-from-head · commit-only-when-complete ·
program-order/no-duplicate via seq · per-seq payload shadow (tag/value/exception) ·
exception terminates group · exact `free_entries` after flush.

### Coverage gating

A run that never reaches the hard states is **failed**, not passed. Nine
coverage holes are hard-checked: dispatch stall, ROB full, 2-wide commit,
out-of-order completion, partial flush, flush-at-head, completion/flush race,
index wrap, exception commit. Representative run (DEPTH=16, 12 000 random cycles):

```
dispatch stalled 33 · rob_full 36 cycles · commit w2 5694 · out-of-order completions 11683
flushes: none 54 / partial 199 / all-but-head 55 · completion-squashed race 188
flush+commit same cycle 217 · head-flush suppressing lane 1 30
exceptions 447 · mispredicts 1750 · wraps 905 · 13527 instructions committed
```

### Mutation testing — 3/3 caught

| Mutant | Injected bug | Caught by | First failure |
|---|---|---|---|
| 1 | lane 1 commits without lane 0 → out-of-order commit | contiguity check, then seq order | `commit lane 1 valid without lane 0 (commit must be contiguous)` @ cyc 26 |
| 2 | lane-1 entry reported committed but neither freed nor stepped over → commits twice | commit-from-head + per-seq payload + occupancy | `commit lane 0 idx=1 expected head-relative 2` @ cyc 28 |
| 3 | flush boundary `>=` instead of `>` → squashes the branch itself | commit_valid mismatch + exact `free_entries` after flush | `commit_valid=1 expected 11` @ cyc 66 (D3) |

All three fail inside the **directed** suite (cycles 26–66), so they're caught
fast and deterministically rather than relying on random luck. Mutant 3's
message was garbage under Verilator until the brace-concatenated format string
defect (gotcha 1 above) was fixed — a good illustration of why the mutants are
worth keeping around across toolchain changes.

### Robustness

- Golden passes at `DEPTH` = 8, 16, 32, 64 with zero coverage holes, under
  **both** Verilator 5.046 and Icarus 13. All three mutants fail with identical
  first-failure messages under both — which is the cross-check that the
  2-state/4-state difference is not changing the verdicts for this module.
- **Every drain loop is iteration-capped** and the global timeout scales with
  `RANDOM_CYCLES`. A buggy candidate produces a `TEST_RESULT: FAIL` with state
  dumped (phase, cycle, head, occupancy) — it can never hang the grader. Mutant 1
  originally *did* hang an unbounded drain; that's why the caps exist.

---

## Module 2 — Load/Store Queue (LSQ) — **COMPLETE**

Files: `interfaces/TierTwo/lsq_iface.sv`, `testbenches/TierTwo/lsq_tb.sv`,
`reference_solutions/TierTwo/lsq.sv`,
`sandbox/mutation_tests/TierTwo/lsq/{lsq_mut1_early_issue,lsq_mut2_wrong_store,lsq_mut3_partial_as_exact}.sv`

### Scope decisions — confirmed

- Own monotonic age tag (not borrowed from the ROB), so the module is testable standalone.
- Forwarding on **exact addr+size match only**; partial overlap stalls until the
  overlapping older store has retired to memory. No byte merging.
- Conservative issue: a load waits until **every** older in-queue store has a
  known address. No memory-dependence prediction, no speculate-and-replay.
- Single-outstanding far-side memory.
- **`mem_req_size` added** as instructed. Without it a sub-word store cannot be
  written to a byte-addressable memory, and sub-word access is precisely what
  manufactures the partial-overlap hazard.

### Scope decisions — resolved because the prompt was ambiguous (**confirm or override**)

1. **`alloc_addr_known` means the address arrives on the addr channel in the SAME
   cycle as the allocation** (`addr_lsq_idx == lsq_idx`). The port list has no
   address field at allocate, so this is the only reading that gives it teeth.
   It is a genuine hazard and is generated by the testbench (456 occurrences in a
   24 000-cycle run).
2. **No backpressure output.** The port list has none, and occupancy is externally
   derivable, so the testbench simply never allocates into a full queue.
3. **Entry lifetime**: a load's slot frees when its result is delivered; a store's
   frees when its write *completes*, not when `store_commit` is received. Until
   then the store is still "in the queue" for forwarding and for the
   partial-overlap stall rule.
4. **Stores retire in program order, and only after every older load has been
   answered.** This is what an in-order retire gives you for free, and it is what
   makes the golden memory a well-defined reference — without it a younger store
   could reach memory ahead of an older load's read and no fixed expected value
   would exist.
5. **Flush wins over a same-cycle result**; a store whose write was already
   accepted by the memory keeps its slot until the response lands, because the
   transaction cannot be recalled.

### Why this testbench should be trusted

The scoreboard is a **shadow, not a predictor** — it never guesses which cycle
the DUT will answer a load, since scheduling is implementation-defined. It grades
observed events against state it maintains from testbench-driven inputs.

**Issue legality is graded separately from data**, which is the whole point of the
module: a load that fires while an older store's address is unknown is wrong even
when the value it returns is right, and a data-only check would pass that bug on
most seeds. Three timing checks (L1/L2/L3) sit alongside four data checks
(D1–D4).

The subtle part, and the thing that took the longest to get right: **a load's
expectation is frozen the first cycle it becomes legally answerable**, not
recomputed when the result arrives. The DUT decides from cycle C-1 state and
reports in cycle C; grading against cycle-C state mis-flags a perfectly legal
forward whose source store retired in between. Freezing is sound because once a
load is legal its correct value cannot change — no older store can appear, and
the retire rule stops any younger store reaching memory first.

### Bugs this cost me (all found by the harness, all real)

| Where | Bug |
|---|---|
| golden | A returning memory read and a ready forward both claimed the single result port in one cycle: **two entries retired, one result emitted** — a silently dropped load. Caught by the slot-occupancy check. |
| golden | `mem_ld_deliver` was a continuous `assign` calling a function that indexes arrays by a variable. Icarus's sensitivity inference left it **stale across a flush**, delivering a result for a squashed load. Verilator passed; **only the Icarus cross-check caught it.** Now evaluated at the edge in the process that consumes it. |
| testbench | The same-cycle-address path drove a **stale** per-slot address, because the shadow lags the DUT by one cycle on load frees and a just-freed slot still looked occupied. Produced phantom forwarding mismatches. |
| testbench | A same-cycle-address request could **clobber an address resolution already marked delivered**, so that store's address never arrived and every younger load blocked forever. |

The last two would have produced **false failures against real candidates** — the
most damaging failure mode a grader can have.

### Coverage gating

Eight holes hard-checked. Representative run (DEPTH=16, 24 000 random cycles):

```
loads answered: forwarded=867 from-memory=2358
load-cycles blocked by: unknown older store=10973 partial overlap=25360 awaiting store data=68
same-cycle alloc+addr=456 · flush squashed=1020 (130 while blocked)
stores written=1287 · loads completed=3225 · 6878 graded events
```

### Mutation testing — 3/3 caught, each in its own targeted directed test

| Mutant | Injected bug | Caught by | Where |
|---|---|---|---|
| 1 | conservative gate removed — load issues before older store addresses resolve | **L2 ILLEGAL READ** | C3-unknown-older-store |
| 2 | forwards from the oldest overlapping store instead of the nearest | **D1** value mismatch | C4-nearest-older-store |
| 3 | partial overlap treated as an exact match | **L1/L3 ILLEGAL ISSUE** | C2-partial-overlap-stall |

Mutant 1 is the important one: it frequently returns the *correct value* and is
caught purely on issue timing, which is exactly what a data-only harness would
miss.

### Robustness

- Golden PASSES under **both** Verilator 5.046 and Icarus 13; all three mutants
  fail under both.
- Every drain and wait loop is iteration-capped; the liveness check names the
  blocking entry and the reason, so a stalled candidate produces a diagnosis
  rather than a hang.

---

## Module 3 — Branch Predictor (gshare + BTB + RAS) — **COMPLETE**

Files: `interfaces/TierTwo/bpred_iface.sv`, `testbenches/TierTwo/bpred_tb.sv`,
`reference_solutions/TierTwo/bpred.sv`,
`sandbox/mutation_tests/TierTwo/bpred/{bpred_mut1_bad_ghr_restore,bpred_mut2_spurious_ras_pop,bpred_mut3_no_btb_alloc}.sv`

### Scope decisions — confirmed

- gshare: `pc[2 +: GHR_W] ^ ghr` into a 2-bit saturating PHT; 8-bit GHR, 256 entries.
- Tagged BTB (16 sets x 2 ways), entries carry a 2-bit type written at update.
- RAS (depth 8) for call/return.
- Single-cycle combinational prediction.
- Externally-supplied snapshot/restore — no internal checkpoint table.

### Scope decisions — resolved because the prompt was ambiguous (**confirm or override**)

1. **`ghr_snapshot` carries the WHOLE speculative checkpoint, packed
   `{ras_sp, ghr}`** (width `GHR_W + RAS_PTR_W`). The prompt requires the RAS
   depth to be restored on a squash but gives no RAS restore port; its own
   wording is "a GHR/RAS snapshot", so one combined checkpoint word is the
   intended reading. **No port was added.** The name is inherited from the
   original port list — read it as "speculative state snapshot".
2. **The RAS is a wrapping circular array with no full/empty tracking**, so the
   pointer alone is a complete checkpoint and restore is exact. This is what
   makes "RAS depth restored on squash" precisely testable rather than
   implementation-defined.
3. **Calls and returns do not shift the GHR**; only conditional branches do.
4. **`restore` is the channel by which the core hands a branch's checkpoint back
   when it RESOLVES, not only when it mispredicts** — see below. On a restore
   cycle carrying a same-cycle conditional-branch update, the true outcome is
   folded in: `ghr <= {restore.ghr[GHR_W-2:0], update_taken}`.
5. **Reset clears the RAS contents as well as the pointer**, so a return
   predicted before anything is pushed has a defined result instead of leaking
   stale state. (Added after the testbench caught itself grading undefined state.)
6. A BTB miss is **inert**: no GHR shift, no RAS push/pop.

### The spec bug the accuracy tier caught

First working version passed all of tier 1 but scored **12.5% on the 15T/1N loop
(worse than always-taken) and 66% on a learnable period-6 pattern (worse than
random)**. Cause: prediction indexed the PHT with pre-branch history while
training indexed it with post-branch history, so the predictor learned a
one-position-lagged correlation. Tier 1 could never have caught this — it is a
pure quality bug — which is exactly the argument for having tier 2 at all, even
though tier 2 is never pass/fail.

Fixed by defining `restore` as the resolve-time history channel. Now: loop
**6.62%**, unpredictable **48.5%** (correctly ~50%), correlated period-6
**0.12%** — gshare learning the pattern essentially perfectly.

### What is and is not graded

**Not graded:** BTB replacement choice and conflict misses. A finite BTB may
miss whenever it likes. The model therefore **follows the DUT's hit/miss
decisions** and grades the data returned, rather than predicting hits. Index/tag
aliasing between two different PCs cannot produce a wrong hit here, because set
and tag together cover the whole PC — so a stale hit is a genuine bug.

**Graded (tier 1, pass/fail):** P1 hit only for a previously-updated PC · P2 type
· P3 replayed target · P4 return target from the modelled RAS top · P5
`predict_taken` against the modelled counter · P6 `ghr_snapshot == {ras_sp, ghr}`
**every cycle** (this is what continuously grades the speculative shift, the RAS
push/pop and the exact restore) · P7 allocate-on-first-encounter.

P7 is what stops a DUT gaming the "misses are always allowed" rule by never
allocating — and that is precisely mutant 3.

### Coverage gating

Ten holes hard-checked. Representative run:

```
BTB hits=23208 misses=16886 · RAS push=2232 pop=2153 · return predictions=2211
GHR shifts=18518 · restores=12444 (12258 with a same-cycle update)
PHT saturated hi=6521 lo=3323 · BTB type rewrites=5370 · 40094 graded cycles
```

### Mutation testing — 3/3 caught

| Mutant | Injected bug | Caught by | Where |
|---|---|---|---|
| 1 | GHR restore lands one position shifted | **D3** exact-restore | D3-ghr-shift-and-restore |
| 2 | conditional branch also pops the RAS (pop with no push) | **P6** snapshot mismatch | D1 |
| 3 | never allocates on a first-encounter miss | **P7** | D1-btb-allocate-first-encounter |

**A vacuous-test hole found and closed:** mutant 1 initially slipped past D3
because that test checkpointed a *zero* GHR, and a shifted zero is still zero.
D3 and D5 now shift real history in first and **assert the checkpoint is
non-zero**, so the test cannot silently go vacuous. Worth remembering as a
pattern: a restore test whose checkpoint is zero proves nothing.

### Robustness

Golden PASSES under **both** Verilator 5.046 and Icarus 13; all three mutants
fail under both.

---

## Module 4 — Non-blocking dual-port cache with victim buffer — **COMPLETE**

Files: `interfaces/TierTwo/ncache_iface.sv`, `testbenches/TierTwo/ncache_tb.sv`,
`reference_solutions/TierTwo/ncache.sv`,
`sandbox/mutation_tests/TierTwo/ncache/{ncache_mut1_dup_fill,ncache_mut2_lost_writeback,ncache_mut3_wrong_tag}.sv`
plus the new shared `testbenches/common/mem_line_stub.sv`.

### Scope decisions — confirmed

- 2 symmetric ports, 4-way / 8 sets, 4 MSHRs, 4-entry fully-associative victim
  buffer, write-allocate write-back, randomised fill latency.
- Replacement policy and hit rate are **not** graded; data correctness and
  protocol legality are.

### Scope decisions — resolved (**confirm or override**)

1. **Port-A-before-Port-B is stated as an ORDERING rule, not just conflict
   resolution.** If both ports are accepted in one cycle and their ranges
   overlap, B sees A's write. Stated this way it is checkable; as a "priority
   hint" it would not be.
2. **Visibility is anchored at the ACCEPT edge**: an accepted write is
   architecturally visible immediately, and an accepted read returns the value as
   of its own accept edge no matter how late its response arrives. This is what
   makes out-of-order responses gradeable at all.
3. **Memory is single-outstanding and untagged** (the port list has no memory
   tag), so fills are serialised. Multiple MSHRs still make the CPU side
   non-blocking, which is the property being tested.
4. **A cache reset discards dirty lines**, so the testbench resynchronises the
   golden memory from the memory image after every reset. Without this the
   harness would blame the DUT for a write the spec says reset legitimately
   throws away.

### Why merging is graded by directed tests

With single-outstanding memory a duplicate fill is necessarily *sequential*, and
from outside the cache a second fill for a line is indistinguishable from a
legitimate refill after eviction — unless the scenario is controlled. So C4 is
graded by directed tests that start from reset, hit one line from both ports
before any fill can complete, and assert **exactly one** memory read for that
line. Two variants: read+read, and a three-deep read/write/read merge.

### Bugs this cost me (all found by the harness)

| Where | Bug |
|---|---|
| testbench | The request driver held `req_valid` while stepping and could be accepted *inside* the wait loop, then accepted **again** by the trailing step — duplicate accepts on one tag. Fixed by settling, sampling `req_ready`, then completing the cycle. |
| testbench | Requests were dropped whenever `req_ready` happened to be low, so the flush sweep evicted almost nothing and C6 was near-vacuous (2 writebacks in a whole run). |
| testbench | Mid-test resets were blamed on the DUT for losing dirty data that reset is entitled to discard. |
| coverage | The first address pool fitted inside the cache: 99.75% hit rate, 53 fills, 11 writebacks. The victim/writeback paths were barely touched. Pool rebuilt so set 0 has **eight** competing lines against 4 ways + 4 victim entries. |

That last one matters for this benchmark specifically: the harness *passed* in
both cases, but only the second one actually tests anything.

### Coverage gating

Eight holes hard-checked. Representative run (20 000 random cycles):

```
accepted A=14198 B=13838 · dual-accept cycles=9642 (same line=3349, r/w overlap=1668)
backpressure cycles A=1345 B=124 · fills=1079 writebacks=874
HIT_RATE=92.91% (informational) · 28038 graded events
```

### Mutation testing — 3/3 caught

| Mutant | Injected bug | Caught by | Where |
|---|---|---|---|
| 1 | secondary miss allocates its own MSHR → duplicate fill | **C4** exactly-one-fill | D1-mshr-merge (directed) |
| 2 | dirty line displaced from the victim buffer is dropped | **C2** stale read data (20 hits), and **C6** image compare | R1-random |
| 3 | response tags crossed when both ports answer in one cycle | **C1** port/tag mismatch | R1-random |

### Robustness

Golden PASSES under **both** Verilator 5.046 and Icarus 13.

---

## Module 5 — Two-core MESI-lite coherence — **COMPLETE**

Files: `interfaces/TierTwo/mesi_iface.sv`, `testbenches/TierTwo/mesi_tb.sv`,
`reference_solutions/TierTwo/mesi_top.sv`,
`sandbox/mutation_tests/TierTwo/mesi/{mesi_mut1_dual_m,mesi_mut2_no_flush,mesi_mut3_busrd_to_i}.sv`

### Scope decisions — confirmed

- Two private, single-port, **blocking** L1s (4 sets x 2 ways). None of module
  4's non-blocking machinery is reused, as instructed.
- Single shared bus, one transaction in flight, **round-robin** arbitration
  (anti-starving by construction).
- M / E / S / I. BusRd leaves an M peer in **S** (not I) after flushing;
  BusRdX / BusUpgr invalidate, with an M peer flushing first.
- `debug_state` is a verification hook only.

### Scope decisions — resolved (**confirm or override**)

1. **`debug_state` carries the TAG as well as the 2-bit state.** The original
   port list had state only, which makes the invariant *uncheckable*: the
   invariant is about a LINE, and once more than one line maps to a set, a way's
   state says nothing about which address it belongs to. Same class of addition
   as the LSQ's `mem_req_size`.
2. **The core deasserts `cpu_req_valid` in the same cycle it observes
   `cpu_resp_valid`.** Without this rule a cache that latches on "idle && valid"
   re-latches the request it just answered and responds twice — which is exactly
   what happened on the first run.
3. **A flush also writes the line back to memory**, so memory is a valid backing
   store for every line not currently held in M. This is what makes the
   end-of-run image comparison meaningful.
4. Both caches, the arbiter and the bus live in **one module and one FSM**. The
   protocol is a sequence of globally ordered steps
   (SNOOP → FLUSHWB → EVICT → FETCH → INSTALL) and expressing it as one explicit
   sequence is far easier to argue correct than two machines racing on a wire.
   The spec constrains observable behaviour plus `debug_state`, so this is a
   legitimate implementation of it.

### The two checkers

**I. State invariant, every cycle**, per line, from `debug_state`:
I1 never M/E in both caches · I2 never M/E in one while S in the other ·
I3 never M in one while valid at all in the other · I4 no line twice in a set.

**II. Data / ordering.** Each core is blocking and single-outstanding, so at most
two operations overlap. A read is legal iff it returns either the value as of the
moment it was **issued**, or the value of a write on the **other** core that
overlapped it. Every write carries a unique value, so a returned value names
exactly which write was observed. Anything else is unreachable under any global
order. This is a deliberately simple linearizability argument that only holds
*because* the caches are blocking — worth remembering if the scope is ever
widened.

### Bugs this cost me

| Where | Bug |
|---|---|
| golden | `mem_req_valid` was held high for the whole transaction. The memory then **re-accepted the same request** the cycle its response landed — duplicate reads and writes, plus 20 599 protocol violations. Now a one-cycle pulse. |
| testbench | The driver held `cpu_req_valid` through the response cycle, so the cache latched the same request twice. |
| testbench | Concurrent-write values were collected *after* responses were graded, so a read completing on its first cycle never saw the overlapping write as legal. |
| testbench | The random suite exited with operations still in flight; their writes landed in the cache but never in the golden model. Now drained. |
| testbench | Memory traffic was counted from `req_valid && !busy`, which depends on how the DUT shapes `req_valid` — not something the spec pins down. Now counted on the memory's **busy rising edge**, one count per accepted transaction. |

### Coverage gating

Nine holes hard-checked. Representative run (12 000 CPU ops):

```
ops core0=6097 (rd 3043/wr 3054) core1=6004 (rd 3011/wr 2993)
both outstanding=35978 cycles (same line=2260) · concurrent-write windows=300
snoop HITM=32781 hit-shared=2176 · states M=255951 E=121 both-S=131997
BUS_TOTAL=6203 (BusRd 2079 / BusRdX 2092 / BusUpgr 2032) · 65584 graded events
```

### Mutation testing — 3/3 caught

| Mutant | Injected bug | Caught by | Where |
|---|---|---|---|
| 1 | peer never invalidated on BusRdX/BusUpgr → two caches own the line | **I2** invariant | D2-busupgr-invalidate |
| 2 | no flush before invalidate → peer's dirty data lost | **COHERENCE** data check (stale read) | D1-busrd-hitm |
| 3 | BusRd sends the peer to I instead of S | directed state check **and** the **traffic score** | D1-busrd-hitm |

**Mutant 3 is the interesting one.** It is correctness-preserving, so the prompt
expected it to be visible only in a traffic score. It is — clearly:

| | golden | mutant 3 |
|---|---|---|
| BUS_TOTAL | 6203 | **7375 (+19%)** |
| bus per op | 0.513 | **0.609** |
| BusRd on an M line → peer to S / to I | 2040 / 0 | **0 / 2085** |

So the informational scoring does notice, which is what that mutant was for. It
*also* fails a pass/fail check here, because the interface states outright that
the peer must not go to I — a deliberate choice: the behaviour is specified, so
it is graded, and the traffic score independently quantifies the cost.

### Robustness

Golden PASSES under **both** Verilator 5.046 and Icarus 13.

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

