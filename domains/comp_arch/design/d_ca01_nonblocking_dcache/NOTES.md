# d_ca01 `nonblocking_dcache` — build notes

**Status: STEP 1 COMPLETE. Nothing else started.** No `spec/`, no `ref/`, no
`task.yaml`, no scored-path wiring. The interface is step 2 and is deliberately
not written yet.

**Oracle class: A** — external RTL oracle. The reference will be a thin port shim
over vendored `bsg_cache_non_blocking`. What that buys and what it does not: the
checker, once built, will have been passed by RTL nobody on this project wrote.
It does **not** establish that the checker's *requirements* are the right ones —
that is rule 15's job and it is step 2's work.

---

## Anchor

| | |
|---|---|
| module | `bsg_cache_non_blocking` |
| file | `refs/basejump_stl/bsg_cache/bsg_cache_non_blocking.sv` (613 lines) |
| repo | `https://github.com/bespoke-silicon-group/basejump_stl` |
| SHA | `b48037e28544425839dbd617d45b1a82631bc1a9` |
| licence | SHL-0.51, `licence_verified: true` in `refs.lock` |
| closure | **50 files, 6 350 lines**, entirely within `refs/basejump_stl/` |

Closure spans four directories and nothing outside the repo:
`bsg_cache` (11 files incl. `bsg_cache_non_blocking.svh`), `bsg_dataflow` (5),
`bsg_mem` (10), `bsg_misc` (24). No cross-repo dependency — the smallest closure
risk of any anchor in the catalog. Search paths needed are four `-y` and two
`+incdir+`; `bsg_async` and `bsg_noc` are **not** required.

---

## Result A — elaboration (measured, three frontends)

Probe shim with widths taken from the `.svh` macros rather than guessed
(a first attempt guessed 74 bits where the real packet is 77, and Verilator
reports that as a width *warning*, not an error — so a guessed-width probe
elaborates clean and proves less than it appears to).

| frontend | invocation | result |
|---|---|---|
| Verilator 5.046 | `--lint-only -Wall` | **0 errors**, 16 warnings, all vendored-source style classes (`GENUNNAMED` 34, `WIDTHEXPAND` 12, `UNUSEDPARAM` 12, `PINCONNECTEMPTY` 6, `UNUSEDSIGNAL` 5, `WIDTHCONCAT` 2, `EOFNEWLINE` 1) |
| Verilator 5.046 | `--cc` (full verilation) | **exit 0, 0 errors**, C++ model generated |
| yosys 0.67 `read_slang` (in `openroad/orfs`) | without `-DYOSYS` | **FAILS**, exit 133, 1 error |
| yosys 0.67 `read_slang` | **with `-DYOSYS`** | **exit 0, 0 errors**, 1.71 s |

### NOTE FOR PPA — the `-DYOSYS` poison branch. Agent 1 will need this.

`refs/basejump_stl/bsg_misc/bsg_defines.sv:95-108` defines
`BSG_VIVADO_SYNTH_FAILS`. When `SYNTHESIS` is defined and none of the recognised
tool macros is, it expands to the bare identifier
`this_module_is_not_synthesizeable_in_vivado` — a deliberate poison pill.
`read_slang` defines `SYNTHESIS` but not `YOSYS`, so it takes that branch and
dies at:

```
refs/basejump_stl/bsg_mem/bsg_mem_1rw_sync_mask_write_bit_synth.sv:108:4:
    error: expected a declaration name
```

That module is genuinely in the closure (`tag_mem` and `stat_mem` both
instantiate `bsg_mem_1rw_sync_mask_write_bit`), so it cannot be avoided by
configuration. **`-DYOSYS` is the vendored-supported branch** and clears it
completely — measured, not assumed. Whoever writes this task's `config.mk` needs
it, and the failure without it looks like a syntax error in basejump rather than
a missing define.

Recorded here rather than left in conversation because it is needed at PPA time
and will be gone from anyone's head by then.

---

## Result B — semantic confirmation (directed probe, NOT inherited)

**This is a separate result from Result A and was established separately.**
`refs.lock`'s `is_secondary` evidence is filed under the Phase 0 task id
`ca_d03`, whose artifact was `bsg_cache_non_blocking_mhu` + `_miss_fifo` — a
narrower thing than the v3 anchor. It is not inherited here. Everything below
was produced by driving `bsg_cache_non_blocking` and its full closure.

Rig: [`tb/audit/anchor_semantic_probe.sv`](tb/audit/anchor_semantic_probe.sv),
reproduced by [`tb/audit/run_probe.sh`](tb/audit/run_probe.sh). Never scored,
never shipped. Configuration `sets=8 ways=2 block=4 words id_width=4
miss_fifo_els=8`, four lines placed on four different indices so no result can
be explained by a conflict the probe did not intend.

### The three claims and their controls

| | claim | witness | control | control result |
|---|---|---|---|---|
| **S1** | a hit is returned while a miss is outstanding | `hit_under_miss_events=1`; `resp_while_dma_outstanding=1` | NC1: second request targets a **non-resident** line, so nothing can return | **0** — detector does not fire spuriously |
| **S2** | a secondary miss merges against the in-flight line | **1** DMA read packet for two requests to one line, **both** answered | NC2: second request targets a **different** line | **2** — the counter can distinguish one line from two |
| **S3** | responses tagged by id, correct under out-of-order completion | `reorderings=1`, 0 data errors, expectations looked up **by the id the DUT reported** | NC3: one expectation deliberately falsified | **exactly 1** new error — the checker can fail |

### The run

```
---- S1/S3: warm LINE_A, then miss LINE_B held, then hit LINE_A
     id3 done_seq=2  id2 done_seq=0  dma_rd_pkts=1  resp_while_dma_outstanding=1
     after release: id2 done_seq=3  id3 done_seq=2
     S1 hit_under_miss_events=1 (want >=1)
     S3 reorderings=1 (want >=1)  data errors so far=0
---- NC1 (control for S1): second request targets a NON-resident line
     NC1 hit_under_miss_events=0 (want 0)
---- S2: two requests to the SAME non-resident line while the fill is held
     dma READ packets issued for the pair = 1 (want 1)
     id6 done_seq=1  id7 done_seq=2  data errors so far=0
---- NC2 (control for S2): second request targets a DIFFERENT line
     dma READ packets issued for the pair = 2 (want 2)
---- NC3 (control for S3): one expectation deliberately falsified
[FAIL] id=10 data=5a1a0041 expected=deadbeef
     new errors from one falsified expectation = 1 (want exactly 1)
================ probe summary ================
checks=10  errors=0
PROBE_RESULT: CONFIRMED
```

Read the S1/S3 line directly: request order was id2 (miss) then id3 (hit);
completion order was id3 (`done_seq=2`) then id2 (`done_seq=3`). id3 completed
while id2 was still open **and** while the anchor had an unserved fill request
asserted. That is hit-under-miss, out-of-order completion, and id tagging in one
transaction pair.

Determinism confirmed across **three independent rebuilds** — identical
`checks=10 errors=0 CONFIRMED`.

### Initialization is a contract question, and the anchor's own assertion says so

The tag and stat memories have **no reset**. Sweeping power-up state:

| mode | result |
|---|---|
| `+verilator+rand+reset+0` (zeroed) | **CONFIRMED** |
| `+verilator+rand+reset+1` (ones) | anchor's own assertion fires |
| random, seeds 1–12 | **9/12** assertion, **3/12** CONFIRMED, **0/12** ran to completion and disagreed |

The assertion is the anchor's:

```
bsg_cache_non_blocking_tl_stage.sv:468: [BSG_ERROR] There needs to be at least
2 unlocked ways.
```

Random power-up sets `lock` bits in the tag array, and the anchor refuses to
operate before a `TAGST` pass can clear them — the pass itself needs the
invariant it is establishing. This is exactly the value `CONVENTIONS.md` claims
for leaving upstream assertions enabled: it caught illegal stimulus we could not
have checked ourselves, and it cost nothing.

**No seed produced a run that completed and contradicted S1, S2 or S3.** Every
failure is the anchor declining to operate from an undefined tag state.

**Carry into step 2:** the reset/initialization contract must be pinned in the
spec, with its authority. This is a real design-space question, not a probe
artifact — a submission is entitled to know whether it may assume tags come up
invalid or must provide an initialization mechanism, and the anchor's answer
("neither; the tag array is externally initialized via `TAGST`") is a *choice*,
not the only conformant one.

---

## FINDING (proposed — Jack lands the number; F42 may collide with Agent 2)

### The drift control for this task cannot see drift on 6 350 lines

`refs.lock`'s per-file SHA-256 block was added on 2026-08-17 so that a file
edited, truncated or replaced after that date changes its hash and the check
fires. For this anchor it is structurally incapable of doing so.

Of the **50 files** in the anchor's dependency closure:

| | count | detail |
|---|---|---|
| carry a SHA-256 in `refs.lock` | **1 / 50** | only `bsg_misc/bsg_defines.sv` |
| named in `refs.manifest.yaml` | **5 / 50** | `bsg_cache_non_blocking_mhu`, `_miss_fifo`, and the three `bsg_lru_pseudo_tree_*` — every one listed with a `.v` extension for a file that is `.sv` on disk |
| **the anchor top itself** | **0** | `bsg_cache_non_blocking.sv` is neither named nor hashed |

The manifest's basejump file list names `bsg_cache/bsg_cache.v` — the **blocking**
cache, a different module — plus the two non-blocking submodules. The v3 anchor
top is present only because `mode: vendor` copied whole directories. So the file
this task's entire oracle rests on **arrived by directory-granular side effect,
was never declared, and is not under drift detection.**

**What this is and is not.** It is not evidence that anything is wrong with the
bytes on disk; the anchor elaborates on three frontends and behaves as the
catalog claims. It is that *nothing mechanically asserts* the bytes are what the
pinned SHA contains, and — with egress closed — nothing can. Same shape as the
`refs.lock` hashes' own stated limitation ("they attest LOCAL STATE ... THEY ARE
NOT PROVENANCE"), one level worse: for this task the local-state guarantee does
not apply either, because 49 of 50 files were never hashed.

**Why this is the class that survives.** The manifest looks complete. The lock
file looks complete. `check_refs_hashes.py` passes. Every artefact is
well-formed and the control reports success — while covering 1 file in 50. That
is the pattern `FINDINGS.md` opens with: work that looks like work and measures
nothing. It was found only by asking which files the anchor actually pulls in and
diffing that list against the two documents that claim to track it.

**Not fixed here.** `refs.lock` is frozen and shared; this is reported, not
edited. The cheap remedy, if wanted, is to extend the hash block to a closure
rather than a hand-listed set — computed from the elaborator's own file list, so
it cannot drift from what is really compiled.

---

## Corrections owed to `TASK_CATALOG.md` (step 2, per instruction — correct the row, do not silently omit)

1. **"store merging" is unevidenced at the anchor.** `grep -i merge` across all
   ten `bsg_cache_non_blocking*.sv` files returns **zero** hits. The row claims
   it. Handle it the way the `axis_arb_mux` fairness claim was handled — correct
   the row, so the next reader does not inherit it — after a directed probe
   settles whether the behaviour is present under another name (a secondary
   store replaying into a refilled block is plausibly the same thing and would
   need measuring, not assuming).
2. **The row says "MSHR allocation"; the anchor has no MSHRs.** It uses a miss
   FIFO plus tag-and-index matching against the in-flight miss
   (`bsg_cache_non_blocking_mhu.sv:193`). The spec will state the contract —
   N misses in flight, forward progress under saturating offered load, responses
   tagged by id — and will **not** name MSHRs, because naming them would ship a
   structure the anchor does not use as a requirement.

---

## My own errors in step 1

Three, all in the probe, all costing debug cycles. Recorded because the pattern
is more useful than the fixes.

1. **Polled a `ready` that depends combinationally on the `valid` I was
   driving.** `ready_o = mgmt_op_v ? mhu_idle_i : 1'b1` with
   `mgmt_op_v = v_i & decode_i.mgmt_op` (`tl_stage.sv:437`). Assigning `v_i` and
   reading `ready_o` in the same timestep returns the pre-drive value. Fixed by
   observing the transfer with a flop clocked on the edge the DUT uses.
2. **Waited on a stale level flag.** `req_taken_r` is high for one cycle *after*
   the transfer it describes, so a waiter that tests it before advancing the
   clock reads the *previous* transaction's success and returns immediately —
   dropping the request without ever presenting it. Fixed by counting transfers
   and waiting for the count to change; a monotonic counter cannot be stale.
3. **Created a testbench→DUT combinational dependency and got build-dependent
   behaviour.** `assign yumi_i = v_o` is read by the anchor only in
   `wire stall = v_o & ~yumi_i` (`bsg_cache_non_blocking.sv:78`), so it is
   equivalent to a constant 1 — but it makes `stall` depend on evaluation order
   within a settle pass. It is not a loop, so **nothing warned**: no `UNOPTFLAT`,
   no error. Builds differing only by an added debug process disagreed about
   whether the anchor jammed after one operation. Fixed by driving `yumi_i`
   constant.

**The shape worth carrying:** all three produced *an anchor that looked broken*.
The first two made a working cache appear to accept exactly one request and then
wedge; the third made that symptom appear and disappear across rebuilds. At no
point did anything error. This is the false-failure mode `CONVENTIONS.md` warns
about for spec-only verification tasks, hit from the design side — and it is a
direct argument for the eventual reference testbench shipping its handshake
discipline rather than leaving each author to rediscover it.

Two of the three were found only by instrumenting. Re-reading the driver — which
I did, repeatedly — confirmed it looked correct every time.

---

## Next (step 2, not started)

Interface + `task.yaml` parameter set, then the `CFGS` arm in
`scripts/sim_candidate.sh` (authorized, single arm, `*)` refusal untouched), then
the F22 smoke-proof on a trivial stub, then testbench / mutants / second source.
