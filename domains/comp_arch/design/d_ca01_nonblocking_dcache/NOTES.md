# d_ca01 `nonblocking_dcache` — build notes

**Status: STEPS 1 AND 2 COMPLETE.** Interface, `task.yaml`, the `CFGS` arm and
the scored-path smoke proof are landed. The testbench is a **skeleton** and is
labelled as one; mutants, conformant set and second source are step 3.

**Oracle class: A.** The reference will be a thin port shim over vendored
`bsg_cache_non_blocking`. What that buys: the checker, once built, will have been
passed by RTL nobody here wrote. What it does **not** buy: any assurance the
checker's *requirements* are the right ones. That is rule 15's job and it is
done clause by clause in the interface.

---

## Anchor

| | |
|---|---|
| module | `bsg_cache_non_blocking` |
| file | `refs/basejump_stl/bsg_cache/bsg_cache_non_blocking.sv` (613 lines) |
| repo / SHA | `bespoke-silicon-group/basejump_stl` @ `b48037e28544425839dbd617d45b1a82631bc1a9` |
| licence | SHL-0.51, `licence_verified: true` |
| closure | **50 files, 6 350 lines**, entirely within `refs/basejump_stl/` |

---

## Result A — elaboration

| frontend | result |
|---|---|
| Verilator `--lint-only -Wall` | **0 errors**, 16 warnings (vendored-source style classes) |
| Verilator `--cc` | **exit 0, 0 errors** |
| yosys `read_slang`, no `-DYOSYS` | **fails**, exit 133, 1 error |
| yosys `read_slang`, `-DYOSYS` | **exit 0, 0 errors**, 1.71 s |

The shipped interface was checked separately and standalone, under the same
flags the scored path uses: **Verilator 0 errors, slang 0 errors.** (A `-Wall`
run exits non-zero on it, but that is warnings-as-fatal on a deliberately empty
port stub, not a defect.) This check exists because four independent submissions
once failed against one interface and the interface had to be cleared before the
result could be reported as a model result.

### NOTE FOR PPA — the `-DYOSYS` poison branch

`bsg_defines.sv:95-108` expands `BSG_VIVADO_SYNTH_FAILS` to the bare identifier
`this_module_is_not_synthesizeable_in_vivado` when `SYNTHESIS` is defined and no
recognised tool macro is. `read_slang` sets the former, not the latter, and dies
at `refs/basejump_stl/bsg_mem/bsg_mem_1rw_sync_mask_write_bit_synth.sv:108`.
That module is genuinely in the closure — `tag_mem` and `stat_mem` both reach it
— so it cannot be configured away. **`-DYOSYS` is the vendored-supported branch
and clears it.** Whoever writes this task's `config.mk` needs it; without it the
failure reads as a syntax error in basejump.

---

## Result B — semantic confirmation, driven not inherited

Rig: `tb/audit/anchor_semantic_probe.sv`, reproduced by `tb/audit/run_probe.sh`.
Never scored, never shipped. `sets=8 ways=2 block=4 id_width=4 miss_fifo_els=8`
unless stated; lines placed on distinct indices so nothing is explained by an
unintended conflict.

| | claim | witness | control | control result |
|---|---|---|---|---|
| **S1** | hit returned while a miss is outstanding | `hit_under_miss_events=1`, `resp_while_dma_outstanding=1` | non-resident second line | **0** — no spurious fire |
| **S2** | secondary miss merges | **1** fill for two requests to one line, both answered | different second line | **2** — counter distinguishes |
| **S3** | id tagging under out-of-order completion | `reorderings=1`, 0 data errors, looked up by the reported id | one expectation falsified | **exactly 1** error |
| **S4** | a STORE into a line with an outstanding fill survives the fill | 1 fill, stored word reads back | store to an already-resident line | **0 errors** — the store path itself is sound |
| **S5** | req `ready` independent of req `valid` for LOAD/STORE | LOAD=0, STORE=0 | the same measurement on a management op | **1** — the measurement can detect a dependency |
| **S6** | outstanding distinct-line miss capacity | see below | — | four points, not one |

`checks=14 errors=0 PROBE_RESULT: CONFIRMED`, stable across three independent
rebuilds.

**S5 nearly shipped a false clean.** Measured with the MHU idle it read
LOAD=0 STORE=0 **TAGST=0** — and the TAGST zero is what said the apparatus was
blind, not that the anchor was clean: idle, the anchor's ready is `1'b1` for
every op and the dependency is unobservable. Re-measured with a miss in flight,
the control reads 1 and the load/store zeros mean something. **The clause this
was validating was then not written**: see L5 in the interface — the anchor's
behaviour is stated as latitude rather than turned into a requirement, because
requiring it would constrain submissions on an axis this task does not measure.

**S6 — capacity, measured before the spec clause was written.** F29 is the
finding about a floor built on an unmeasured model of the anchor, where the
documented `MAX_TRANS+1` was really `4·MAX_TRANS−5` and one coincidental point
of agreement carried it. Swept here at four points:

| `miss_fifo_els_p` | 2 | 4 | 8 | 16 |
|---|---|---|---|---|
| distinct-line misses accepted with memory held | **3** | **5** | **9** | **17** |

Exactly `els + 1` at every point. C1's floor is `MAX_MISSES`, so the reference
clears it by one and a design providing exactly `MAX_MISSES` also passes. **The
floor is not fitted to the reference's number** — that is how buffering becomes
a requirement (F8).

### How many seeds actually ran to completion

Stated plainly, because "no seed contradicted the claims" is an absence
statement over a filtered population and is worth exactly what the population
size makes it worth.

| power-up mode | outcome |
|---|---|
| `+verilator+rand+reset+0` (zeroed) | CONFIRMED |
| `+verilator+rand+reset+1` (ones) | refused by the anchor's own assertion |
| random, seeds 1–12 | **3 ran to completion, all CONFIRMED; 9 refused before any claim was reached** |

So the randomized-init evidence is **three seeds**, not twelve. The deterministic
zeroed-power-up run is the primary evidence and it is reproducible; the seed
sweep adds three more independent initial states and no contradiction. It does
not add twelve.

The refusals are the anchor's own assertion, `tl_stage.sv:468`,
*"There needs to be at least 2 unlocked ways"*, which fires on **any** operation
in the TL stage — including the one that would clear the condition. That is why
the anchor cannot be initialized through its own request port from a random
state, and it is the fact that decided P1 below.

### E3 — the experiment that kept the shim thin

With the tag array zeroed at power-up and **no initialization sequence at all**,
the probe returns CONFIRMED on every claim. So the reference needs no init
sequencer, the contract needs no management operation, and the shim stays a
rename. Had this gone the other way the interface would have needed an
initialization port and the shim would have needed behaviour, which is the point
at which the task converts rather than having its spec reshaped to fit.

---

## The initialization decision (spec P1)

**Decided: a PRECONDITION on the environment, not a design requirement.**
Every line is invalid at the first request after reset; the design may assume it
and is not required to implement invalidate-on-reset; a design that *does*
self-invalidate is equally conformant.

**Authority: this task's decision, recorded as such in the interface and marked
as not citable as a standard.** It is explicitly **not** the anchor's
arrangement — the anchor's tag memory is externally initialized, a third
conformant option this contract does not use. The anchor's assertion is evidence
that the anchor made a choice, not evidence that the choice is required, and it
is cited nowhere in the spec as authority.

**Why a precondition.** The measured difficulty axes are hit-under-miss,
outstanding-miss capacity and forward progress. Power-up tag state is on none of
them, and making it a requirement adds a barrier off every measured axis — the
argument that removed the `b_ready` lookup barrier from `d_nw01`.

**Both halves are built, because one without the other is the failure mode.**
The condition is established at build time by `--x-initial 0` declared in
`ref/sim_flags_verilator.txt`, **and** it is verified by the testbench on every
run (skeleton phase 2: the first access to a line must issue a memory fill
rather than hit). A stated precondition nothing checks is how a self-initializing
design and an assuming design pass for two different reasons.

The override was **verified, not assumed**: built with the scored path's
hardcoded `--x-initial unique` followed by the task's `--x-initial 0`, the probe
runs CONFIRMED with no runtime argument and stays CONFIRMED even when
`+verilator+rand+reset+2` is forced at run time — the zeroing is baked in at
compile time and cannot be undone afterwards.

**The cost is stated rather than hidden.** `--x-initial 0` makes uninitialised
reads deterministic zero, so it hides bugs that depend on genuinely undefined
state. That is the trade P1 makes, and it is why P1 is checked every run.

---

## Scored path — the F22 proof, and it discriminates

One arm added to `scripts/sim_candidate.sh`, nothing else in the file touched,
the `*)` refusal intact. 16 configs, the full cross of the four swept
parameters, kept in step with `task.yaml`.

```
task=d_ca01_nonblocking_dcache  dut=nonblocking_dcache  configs=16  extra_flags=14
stub_minimal.sv            16/16
stub_inert.sv               0/1     -> FAIL: phase 1: no request accepted within 500 cycles
```

Both stubs are in `tb/audit/` and are never scored. **Two of them on purpose**:
a path that only ever produced one verdict would prove nothing about whether it
discriminates, which is F25's shape one level up — there, a control that failed
everything made a dead harness look validated. The inert stub fails with a
specific, correct reason; the minimal stub passes all 16 configs; run records are
written for both.

The minimal stub is a cache in name only — it stores nothing, so every access
misses. It satisfies the **skeleton** and would fail C1, C2 and R5. That is the
honest measure of what the skeleton currently checks.

---

## FINDING (PROPOSED — slug `anchor-outside-drift-detection`)

**Rules: 10**

**The drift control for this task cannot see drift on 6 350 lines.**

Of the anchor's **50** closure files:

| | count | detail |
|---|---|---|
| carry a SHA-256 in `refs.lock` | **1 / 50** | only `bsg_misc/bsg_defines.sv` |
| named in `refs.manifest.yaml` | **5 / 50** | the two non-blocking submodules and three `bsg_lru_pseudo_tree_*`, every one listed with a `.v` extension for a file that is `.sv` on disk |
| **the anchor top itself** | **0** | `bsg_cache_non_blocking.sv` is neither named nor hashed |

The manifest's basejump list names `bsg_cache/bsg_cache.v` — the **blocking**
cache, a different module. The v3 anchor top is present only because
`mode: vendor` copied whole directories. The file this task's entire oracle rests
on arrived by directory-granular side effect, was never declared, and is not
under drift detection.

**What it is and is not.** Not evidence anything is wrong with the bytes; the
anchor elaborates on three frontends and behaves as claimed. It is that *nothing
mechanically asserts* they are what the pinned SHA contains, and with egress
closed nothing can. Same shape as the hash block's own stated limitation, one
level worse: for this task the local-state guarantee does not apply either.

**Why it survives.** The manifest looks complete, the lock file looks complete,
`check_refs_hashes.py` passes — while covering one file in fifty. Found only by
asking which files the anchor actually pulls in and diffing that list against the
two documents that claim to track it.

**On the rule-10 citation, since it was offered rather than assumed.** It fits,
and not as a stretch. Rule 10's content is *name your artifacts, do not discover
them by pattern*; `mode: vendor` copying directories is discovery by pattern, and
the anchor is used without ever being named. The one imperfection is that
rule 10 also says "refuses when they are absent" and nothing here refuses — but
nothing *can* refuse, because nothing names them, which is the rule's failure
mode rather than a mismatch. The secondary resonance is with the
*existence is not participation* convention: a control that runs, passes, and
covers 1 of 50 files. I do not think a different rule fits better.

**Not fixed here.** `refs.lock` is frozen; reported, not edited. The cheap
remedy is to hash a *closure* computed from the elaborator's own file list rather
than a hand-listed set, so the covered set cannot drift from what is compiled.

---

## FINDING (PROPOSED — slug `tb-observation-that-fakes-a-dead-dut`)

**Rules: 3**

**Three testbench defects, all of which made a working anchor look jammed, none
of which errored.** Written up as a finding rather than a self-assessment
because the third one is a general hazard and the scoring testbench, the shared
liveness monitor, and `d_nw02`/`d_nw04` reusing that monitor all live exactly
where it bites.

| # | defect | symptom |
|---|---|---|
| 1 | polled `req_ready_o`, which depends combinationally on the `req_valid_i` being driven in the same timestep (`tl_stage.sv:437`) | read the pre-drive value; request never presented |
| 2 | waited on a **level flag** describing a *completed* transfer — high for one cycle *after* the transfer — so the waiter read the previous transaction's success and returned immediately | request dropped without ever being presented at a posedge |
| 3 | drove a DUT input combinationally from a DUT output (`assign yumi_i = v_o`), semantically identical to a constant since the anchor reads it only in `stall = v_o & ~yumi_i` | **two builds differing only by an added debug process disagreed** about whether the anchor jammed after one operation |

**Defect 3 is the one to carry.** It produced no `UNOPTFLAT` and no warning of
any kind, because it is not a loop — it is an evaluation-order dependency inside
a settle pass. It is semantically a no-op and it changed behaviour. Nothing in
the toolchain objects, and the symptom is *a DUT that stops responding*, which
is indistinguishable from a deadlock.

**All three present as silence.** That is F9's shape — a wedged harness and a
deadlocked design emit exactly the same thing — arriving from a new direction:
not the harness's *drivers* wedging, but the harness's *observation of the
handshake* misreading a working one. Rule 3 is cited on that basis; the
determinism check below is the negative control this class needs and did not
have.

**Which way the evidence ran.** Two of the three fell out **only from
instrumenting**. The driver was re-read several times and looked correct every
time; defect 1 in particular is invisible in source — nothing about
`while (!ready_o) @(negedge clk);` reads as a bug.

### Structural remedies, to be built into step 3 rather than remembered

1. **Drivers sample and drive on a clock edge, and never assign a DUT input
   combinationally from a DUT output.** Constants where a mirror would do.
2. **Level flags describing a completed transfer are replaced by monotonic
   counters.** A counter cannot be stale: the waiter snapshots it and waits for
   it to change.
3. **A determinism check runs before any liveness verdict is trusted** — same
   seed, two independently produced builds, byte-identical result. There is
   already a case where nothing else would have caught the defect, and a
   liveness verdict is exactly the kind that cannot tell a broken observer from
   a broken design.

The skeleton testbench already applies (1) and (2).

---

## Correction owed to `TASK_CATALOG.md` — measured, and the row is wrong as written

The row claims *"store merging"*. `grep -i merge` across all ten
`bsg_cache_non_blocking*.sv` files returns **zero** hits, so the term appears
nowhere in the anchor.

**The behaviour is present under another name — measured (S4).** A STORE issued
to a line whose fill is still outstanding produces **one** fill, and the stored
word reads back afterwards rather than being overwritten by the returning fill
data. The control (NC4, a store to an already-resident line) is clean, so this is
not the store path merely working.

**Proposed correction, stating what is evidenced rather than keeping the term:**
replace *"store merging"* with *"a store to a line with a fill outstanding is
merged into the refilled block rather than lost or overwritten"*. Also in the
same row: *"MSHR allocation"* — the anchor has no MSHRs, it uses a miss FIFO plus
tag-and-index matching against the in-flight miss (`mhu.sv:193`). The interface
names no structure at all; L2 states explicitly that how misses are tracked is
free.

---

## For Agent 1 — LIVE: every design-task sim record has been losing its verdict

Found while checking why the smoke run showed FAIL in the results table for a
stub that had just passed 16/16. **Not caused by this task, and it affects every
design task.**

`scripts/sim_candidate.sh` calls the record writer with an argument that was
inserted at the `label` position in `607d97f`:

```
before 607d97f:  write_run_record.py <task> <cand> sim <basename> <RAW_DIR>
now:             write_run_record.py <task> <cand> sim "task_text_hash=..." <basename> <RAW_DIR>
```

`write_run_record.py:119` gates the whole verdict block on
`os.path.isdir(rest[0])`. `rest[0]` is now the **basename**, not the raw
directory — the raw dir moved to `rest[1]`. The test fails, and
`configs_total`, `configs_passed`, `all_passed`, `per_config`, `metrics` and
`coverage` are **all silently dropped**. The fallback loop stores `key=value`
pairs, and neither remaining argument contains `=`, so nothing lands.

Reproduced from the exact argument vector, without writing a record:

```
  label   = task_text_hash=9b45fb9445f1c796
  rest    = ['stub_minimal', '/tmp/raw_dir_example']
  rest[0] = stub_minimal -> isdir: False   <- the verdict block is gated on this
```

Evidence in the records themselves. Every design-task sim record written before
this change carries a verdict; every one written after does not:

| timestamp | task | verdict | label |
|---|---|---|---|
| 2026-08-17T19:15 | d_ca04 | **YES** | `deepseek` |
| 2026-08-17T20:12 | d_ca04 | **YES** | `qwen` |
| 2026-08-18T02:41 | d_ca01 | **no** | `task_text_hash=…` |

**This is F28's class exactly** — the simulation was right, the verdict was
printed, and the reporting path destroyed it. And it stacks with a second
defect: `collect_results.py` renders the missing verdict as **`FAIL`**, so a run
that passed every configuration appears in the table as a failure. That is the
more dangerous half. Absence must render as absent (rule 20): a blank cell sends
someone to measure, `FAIL` reads as a result about the design.

Not fixed here — `scripts/` is Agent 1's and the authorization for this task was
one `CFGS` arm. The fix is one of: pass the raw dir where the writer expects it,
or have the writer locate it by scanning `rest` for a directory rather than
assuming a position.

**Also note:** three run records under `runs/d_ca01_nonblocking_dcache/` are
scaffolding, not submissions — `stub_inert.sv` and `stub_minimal.sv` from the
smoke proof. They are left in place because records are immutable, but the two
rows they produce in the results table are not model results. Once the writer is
fixed they will read 0/16 and 16/16 respectively, which is self-describing.

## For Agent 1 — the red regression, with both diagnoses

`scripts/regression.sh` fails on
`2026-08-17T175854Z__chat_scored__ppa.json` (`d_dsp02`):
`area 440336 vs 360899`, `wns −0.697486 vs +0.119133`, `power 0.669 vs 0.442941`.
Control run: parking this task's directory reproduces it byte-identically, so it
is not caused by anything here.

**Two diagnoses fit, and the evidence in hand does not separate them:**

1. **A parser defect in `ppa_candidate.sh`'s record writer** — the F21 class,
   which has happened before on exactly this path (`wns max` versus
   `worst slack max`, and Leakage read as Total power).
2. **The record and the flow directory are not readings of the same run.**
   `check_ppa_record.py` compares a record against `6_report.json` in the live
   flow directory for that nickname, and nothing asserts the two are the same
   measurement. A record from an earlier period against a directory since rebuilt
   at a different one produces exactly this signature: a large area delta with
   the sign of the slack flipped. That is F20's own correction — two numbers
   compared without establishing they are the same measurement — recurring
   inside the check written for F21, and the fix would be a `clk_period_ns` and
   resolved-config match before comparing, per rule 17.

Byte-identical reproduction is consistent with **either**, so neither is
asserted here. The flow directory settles it: if its run is at a different period
than the record's, it is (2).

---

## Next — step 3, not started

Reference shim, then the real testbench (coverage floors, liveness monitor,
C1/C2/C3), 5–7 mutants wrapping the anchor including a CAPABILITY-class one,
the conformant set enumerated clause by clause, and the second source with its
three differences **named in writing before any of it is written**, failures kept.
