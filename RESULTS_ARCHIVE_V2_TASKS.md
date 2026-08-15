# Archived results — three superseded v2 design tasks

`ai_d01`, `ca_d08` and `nw_d01` were removed from `domains/` as too easy to carry
forward. Their measured results are preserved here because they are still
evidence about **where the difficulty floor sits**, which is the claim the v3
catalog rests on.

The task directories are recoverable from git history at commit `1e9c455`. What
survives outside them: `candidates/{ai_d01,ca_d08,nw_d01}/`,
`orfs_runs/nw_d01_cand_chatgpt/`, and the ORFS flow reports under
`$ORFS_FLOW_DIR/reports/sky130hd/{ai_d01_int8_requant,nw_d01_axis_width_adapter,nw_d01_cand_chatgpt}/`.

## PPA, sky130hd

| task | design area | synth area | WNS | power | notes |
|---|---|---|---|---|---|
| `ai_d01` `int8_requant` | 275 995 µm² | 193 269 µm² | **−6.41 ns** | 1.47 W | does NOT close; 100 % combinational |
| `nw_d01` `axis_width_adapter` | 3 115 µm² | 2 079 µm² | +14.30 ns | 245 µW | closes with room to spare |
| `ca_d08` `tiny_core` | — | — | — | — | ORFS deferred (Class B) |

## `nw_d01` reference vs candidate — the v3 trigger, re-derived

| metric | reference | candidate | |
|---|---|---|---|
| synth area | 2 079 µm² | 2 117 µm² | candidate **1.8 % larger** |
| design area | 3 115 µm² | 3 014 µm² | candidate 3.2 % smaller |
| power | 245 µW | 184 µW | candidate 25 % lower |
| WNS | +14.30 ns | +13.71 ns | candidate slightly worse |
| **throughput, matched widths** | full rate | **half rate** | candidate 0.50 |

Three-way decomposition: **no off-spec configuration**, a **real capability gap**
(half throughput at matched widths, `k/(k+1)` narrow-to-wide), and **essentially
no genuine optimisation** — the area figures disagree in sign, and normalised for
delivered throughput the candidate is 21 % worse on area and 6 % better on power.

**Both reference and candidate pass 16/16** on the corrected gate. The earlier
comparison was invalid because the reference had never passed at all: its
`sim_flags` file was empty, so it failed every config on `MODMISSING`.

## Why these three were retired

`nw_d01` and `ai_d01` are small dataflow and arithmetic blocks; `ca_d08` is a
scoped single-issue core. All three were solved by a frontier model on the first
attempt. They mark the **floor**, not the band worth measuring — which is the
finding, and is why they are archived rather than simply discarded.

Caveat on every number above: WNS is comfortably positive for `nw_d01` and
negative for `ai_d01`, so in neither case was the design pushed against a binding
constraint. These are not evidence about difficulty until rerun at a period that
actually binds.


---

# ARCHIVED — Tier-2 per-module build notes

The RTL these describe (`rob`, `lsq`, `bpred`, `ncache`, `mesi`) was removed with
the tier layout and is recoverable at git `c7609fa`. The notes are kept because
they record what each harness checked and which mutants killed it, which is
evidence about how the house style was arrived at. The live methodology from the
same document is in `CONVENTIONS.md`.

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

