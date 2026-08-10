# Tier-2 harness notes

One file rather than five near-identical ones: the toolchain findings below are
identical for every Tier-2 module, and duplicating them per module would mean
five copies to keep in sync. Per-module sections follow the shared section.
**Flagging this as a deviation** from the "a short `NOTES.md` per module"
wording — say the word and I'll split it.

---

## Shared: Icarus Verilog SV subset (measured, not assumed)

Installed: **Icarus Verilog 13.0 (stable)**. Every construct below was smoke-tested
before any testbench was written.

| Construct | Status | Consequence |
|---|---|---|
| `class` | parses | **but see below — effectively unusable** |
| Queues inside classes | ✗ `sorry: not yet supported` | kills class-based scoreboards |
| Class handle arrays (`C list[4]`) | ✗ type error | kills object pools |
| `static` class members | ✗ syntax error | kills class-level counters |
| **Associative arrays** (any index type: `int`, `integer`, `logic[31:0]`, `string`, `[*]`) | ✗ **entirely unsupported** | golden memory cannot be sparse |
| Unpacked structs | ✗ `sorry: not supported` | records must be packed |
| Queues of structs | ✗ `sorry: Queue of type ... not supported` | records must be cast to vectors |
| Queues of integral types (incl. wide, e.g. `logic [95:0]`) | ✓ | the scoreboard container |
| `push_back` / `pop_front` / `size()` / `delete(i)` / indexing | ✓ | enough for a scoreboard |
| Array `find_first_index ... with` | ✗ syntax error | use explicit loops |
| Packed structs (incl. through module ports) | ✓ | the record type |
| `enum` + `.name()` | ✓ | readable state dumps |
| Multi-dimensional unpacked arrays (2D, 3D) | ✓ | per-entry / per-set state |
| Packed 2-D ports (`logic [1:0][W-1:0]`) | ✓ | multi-lane buses stay readable |
| `ref` task arguments | ✗ `sorry: not supported` | operate on module-level state |
| Subroutine ports with unpacked dimensions | ✗ `sorry: not supported` | ditto |
| Functions calling tasks | ✗ (LRM-correct) | any routine that reports must be a `task` |
| Hierarchical reference into a DUT instance | ✓ | available if a debug hook is ever needed |

**Decision: no classes anywhere in Tier 2.** Classes technically parse, but with
no queues inside them, no handle arrays and no statics, nothing resembling a
class-based scoreboard is expressible. Per the prompt's instruction this is a
fallback to **procedural, module-level scoreboards**, and the simulator is
unchanged (still `iverilog -g2012`) — no project-wide simulator switch.

**The standard record pattern for all Tier-2 harnesses:**

```systemverilog
typedef struct packed { logic [7:0] addr; logic [1:0] sz; logic we; } rec_t;
logic [$bits(rec_t)-1:0] q [$];   // queue of vectors
rec_t r;
q.push_back(r);                   // implicit pack
r = q.pop_front();                // implicit unpack
```

Verified working. Linear scan + `delete(i)` covers every lookup the scoreboards
need. Since associative arrays don't exist, the golden memory for modules 2/4/5
must be a **bounded dense array over a small address space** — which the prompt's
"small, explicitly skewed address pool" convention wanted anyway, so the tool
limitation and the methodology point the same direction.

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

Files: `interfaces/TierTwo/rob_iface.sv`, `testbenches/TierTwo/rob_tb.sv`,
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
fast and deterministically rather than relying on random luck.

### Robustness

- Golden passes at `DEPTH` = 8, 16, 32, 64 with zero coverage holes.
- **Every drain loop is iteration-capped** and the global timeout scales with
  `RANDOM_CYCLES`. A buggy candidate produces a `TEST_RESULT: FAIL` with state
  dumped (phase, cycle, head, occupancy) — it can never hang the grader. Mutant 1
  originally *did* hang an unbounded drain; that's why the caps exist.

---

## Shared verification models — **COMPLETE and self-tested**

`testbenches/common/golden_mem.sv` — byte-addressable golden memory (sized
little-endian scalar access, line access for modules 4/5, deterministic
non-zero `init_pattern` so a load that never actually fetched cannot look
correct by returning 0, and address wrapping so a stray address folds in rather
than killing the sim). Dense rather than sparse because Icarus has no
associative arrays; the small skewed address pool convention makes that a
non-issue.

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
iverilog -g2012 -I testbenches/common -o sim testbenches/common/common_selftest.sv && ./sim
```

Known cosmetic warning: `golden_mem.sv:90` "for statement must compare against a
constant to be synthesized in an always_ff" — raised because `mem_stub`'s
always_ff calls `wr_sized`. These are verification models and are never
synthesised; harmless.

Open item for module 4: the stub is currently scalar/sized. The cache needs
**line-granular** fills and writebacks — extend `mem_stub` with a line mode (or
add a thin line wrapper) during that session rather than guessing now.

## Modules 2–5 — NOT STARTED

Interfaces, testbenches, goldens and mutants for LSQ, branch predictor, cache
and coherence are still to do. Recommended order stands:
LSQ → Branch Predictor → Cache → Coherence.

**Known spec issue to resolve at the start of the LSQ session:** the module-2
port list has `mem_req_valid/addr/we/wdata` but no size or byte-enable field.
Sub-word stores therefore cannot be written to a byte-addressable memory, and
sub-word accesses are exactly what the partial-overlap hazard needs. Either add
`mem_req_size` (one port, what `mem_stub` already expects) or make the LSQ do
read-modify-write internally. **Needs a decision before that harness is written.**
