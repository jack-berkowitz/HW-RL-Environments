# d_ca01 `nonblocking_dcache` — build notes

**Status: STEPS 1-3 IN PROGRESS.** Shim and scoring testbench are landed and the
testbench passes the anchor 16/16. Mutants, conformant set and second source are
not started.

**Superseded status line (steps 1 and 2):** Interface, `task.yaml`, the `CFGS` arm and
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
| 4 | `force`/`release` on the memory model's own gap counter. `release` leaves the variable holding the forced value until the next procedural assignment, so the model counted a forced 100 000 back down before accepting anything | every phase after the forced one timed out: *"9 accepted, 8 answered"* |

**Four instances now, and that changes what this finding is about.** It is not a
list of testbench slips. Every one of the four produced *the same observable* — a
design that stops responding — from four unrelated causes: a combinational read
ordering, a stale level flag, an evaluation-order dependency, and a simulator
construct whose scope outlives the statement that used it. A harness that can
manufacture a dead DUT four different ways needs its silence treated as
uninformative by default, which is what the structural remedies below are for.

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

## Step 3 so far — shim and testbench

### Shim: `ref/nonblocking_dcache_ref.sv`, and it is a rename

Parameter binding, packed-struct pack/unpack, one reset-polarity inversion, one
width-dependent opcode constant (`LW` at DATA_W=32, `LD` at 64; stores use `SM`
at both because `data_mem` takes the mask straight from the packet when
`mask_op` is set). No state, no arithmetic, no sequencing, and — the part that
was in doubt — **no initialization sequencer**, because E3 established the
anchor needs none from a zeroed tag array.

Three valid/ready-to-valid/yumi adaptations, and the asymmetry is deliberate:

| channel | form | why |
|---|---|---|
| response | ungated, `yumi_i = rsp_ready_i` | read only through `stall = v_o & ~yumi_i` |
| memory request | ungated, `dma_pkt_yumi_i = mem_req_ready_i` | read only in FSM arms that also drive valid high |
| writeback data | **gated**, `dma_data_v_lo & mem_wr_ready_i` | goes to a `bsg_two_fifo` that ASSERTS on dequeue-while-empty (`bsg_two_fifo.sv:113`) |

Ungated wherever legal, because a gate is a combinational path from a DUT output
back to a DUT input — the shape that made two step-1 builds disagree. The one
place the anchor's own assertion forces a gate, it is used. The upstream
assertion earned its keep a second time here: without it the ungated form would
have silently corrupted a FIFO pointer.

**Reference passes 16/16 through the scored path.**

### Testbench: three defects, all mine, all found by running it against the anchor

The testbench failed the anchor on its first run. **When the anchor fails a
check, the check is what is wrong** — the anchor is the oracle, it is externally
authored, and its behaviour was already confirmed by directed probe in step 1.
All three turned out to be harness defects.

1. **`force`/`release` on the memory FSM's own gap counter.** `release` leaves a
   variable holding the forced value until the next procedural assignment, so
   after releasing a forced 100 000 the FSM counted it down before accepting
   anything and every later phase timed out. Replaced by a plain `mem_stall`
   register the stimulus writes. **The symptom was "9 accepted, 8 answered" —
   a design that stops responding.** Third time in this task that a harness
   defect has presented as a dead DUT.

2. **An over-constrained M2 check, and this one is a genuine contract mistake
   rather than a slip.** The harness compared every writeback beat against
   architectural state at the instant of eviction. A store may be ACCEPTED and
   not yet applied to its line when an unrelated eviction carries that block
   away; R5 orders requests by acceptance and says nothing about a store having
   reached the block before some other eviction. The check encoded an ordering
   the contract does not state, and the anchor failed it.

   Replaced with a **readback sweep** (phase 8): every line the soak touched is
   read back and checked against architectural state. That validates writeback
   *data* through the mechanism that actually matters — a block written back
   wrongly comes back wrongly on the next refill — without inventing an
   ordering requirement.

3. **The liveness monitor ticked during the harness's own deliberate memory
   stall**, and duly reported `DEADLOCK: 4001 cycles ... nothing retired
   anywhere`. C3's premise is *"with memory always eventually responding"*, and
   during the C1 and C2 phases it deliberately is not. `LM_TICK` is now gated on
   the stall register — the premise stated in the same place it is broken.

### The harness discriminates

| DUT | result |
|---|---|
| reference shim | **16/16 PASS** |
| `stub_inert` | FAIL, phase 1, first request never accepted |
| `stub_minimal` | FAIL, **phase 3, C2** — it passed the step-2 skeleton |

The minimal stub is the useful row: it satisfied the skeleton and fails the real
contract at exactly the clause its own header predicted it would (C2, no line is
ever resident so there is no hit to answer under a miss). That is the difference
between the skeleton and the checker, measured rather than asserted.

### Determinism check — BUILT, RUNS, AND IS NOT VALIDATED

`tb/audit/determinism_check.sh`. Two builds, same seed; build B enables an inert
observer process that reads signals and drives nothing.

**Positive case passes:** the two binaries genuinely differ and the two outputs
are byte-identical, `TEST_RESULT: PASS` both times.

**The first version of this check was worthless and it is worth saying why.**
Building the identical source twice produces *byte-identical binaries*, so the
comparison had nothing to detect and could only ever pass. The observer define
exists to reproduce the condition that actually discriminated in step 1 — two
builds differing by a debug process.

**Both negative controls FAIL TO FIRE.** The defect was reintroduced twice, in
the exact class the check exists for, and the check reported IDENTICAL each time:

| reintroduced defect | check result |
|---|---|
| `assign rsp_ready = rsp_valid` — DUT output driving a DUT input | **IDENTICAL, not caught** |
| `mem_req_ready = mreq_ready_r & mem_req_valid`, and the same on the writeback channel | **IDENTICAL, not caught** (and the run still reported PASS) |

**So the check is not validated and must not be quoted as evidence that this
harness is free of the hazard.** What it establishes is narrower and should be
stated that way: *on this harness, at this configuration, two differing builds
agree.*

**A hypothesis for why it does not fire, offered as a hypothesis.** The step-1
divergence involved a settle-order interaction inside the anchor's
**management-op** path — `mgmt_data_yumi_li` gated by `stall`, reached only by
TAGST. Management ops are out of this task's scope, so the scoring testbench may
never drive the anchor into the state where the hazard manifests. If that is
right, the harness is protected by the contract rather than by the check, which
is luck rather than design. Testing it properly means reproducing the hazard in a
path this testbench does reach, and I have not done that.

What actually protects the harness is the three structural remedies, applied by
construction. The determinism check was meant to be the detector, and it is not
yet a working detector.

## Determinism check — WITHDRAWN

Retired, not carried. It could not be made to fail:

| perturbation on build B | clean harness | harness with the defect reintroduced |
|---|---|---|
| inert observer process | IDENTICAL | IDENTICAL |
| `--public-flat-rw` | IDENTICAL | IDENTICAL |
| `-O0` | IDENTICAL | IDENTICAL |

Two reintroductions were tried, both in the exact class the check exists for:
`assign rsp_ready = rsp_valid`, and combinational gating on both memory ports.
The second still reported `TEST_RESULT: PASS`.

A check whose control never fires validates nothing, and one left in the harness
is worse than none — the next reader sees a determinism check and assumes
coverage. **What protects this harness is the three structural remedies applied
by construction. There is no detector behind them, and that is now stated in the
testbench header rather than implied.**

Why it could not fire, still a hypothesis: the step-1 divergence was in the
anchor's management-op path, which this contract puts out of scope, so the
harness may be protected by the contract rather than by anything I built.

---

## FINDING (PROPOSED — slug `latitude-the-interface-cannot-express`)

**Rules: 12**

**A spec can advertise latitude its own port map cannot carry, and reading the
clause will never reveal it.** Rule 12 is about alternatives silently
*foreclosed*; this is the inverse — alternatives silently *offered*.

Two instances in this task, both found the same way, by trying to **use** the
clause rather than read it:

| clause | what it offered | why the interface could not carry it |
|---|---|---|
| **L4** | write-through / no-write-allocate as a free choice | M1 and M2 make every memory transaction block-granular; there is no single-word or byte-masked write anywhere on the port. A no-write-allocate design has no legal way to send one modified word to memory. |
| **L6** | latency unconstrained, so a combinational hit response is legal | the scoreboard read `id_open` pre-edge, so a design answering in the same cycle it accepts was charged with *"a response arrived for an id with nothing outstanding"*. The harness could not express the latitude the spec granted. |

L4 was found while choosing the second source's differences — a candidate
difference was rejected because the port could not express it. L6 was found by
the audit L4 prompted.

**The detector, and it is the transferable part.** Enumerate every latitude
clause and try to realise each one against the port map and the harness. It is a
bounded pass and it is the only known way to catch this class: the clause reads
correctly, the artefact it describes is absent, and no control fires because
nothing is wrong with what was built — only with what was promised.

### The audit, run on every remaining clause

| clause | offered | expressible? | evidence |
|---|---|---|---|
| L1 replacement policy free | LRU / tree-PLRU / RR / random | **yes** | victim choice is visible only on `mem_req_addr_o`; nothing constrains it |
| L2 miss tracking free | any structure | **yes** | internal; no port-map consequence, and no check inspects it |
| L3 critical-word-first out of scope | — | **n/a, foreclosure verified** | M1 pins ascending and the memory model serves ascending; the foreclosure is real and stated |
| L5 `ready` may depend on `valid` | either | **yes**, but **unexercised** | harness drives `req_valid` from a negedge register, never derived from ready. No artifact in the task takes the dependent side — a conformant-set candidate |
| L6 latency unconstrained | any, including 0 | **was NOT** → fixed | see above |
| R4 response order free | in-order or reordered | **yes**, both exercised | anchor reorders (probe `reorderings=1`); a strictly in-order design is D3' below |

**L6's fix is controlled.** A scratch zero-latency DUT (one line, combinational
hit response) now runs with `METRIC: latency min=0` — previously min=2 — and
raises no unknown-id error. It fails C1 and C2 by construction, which is what it
should fail. The reference's numbers are unchanged by the fix.

---

## D3 is REFUTED — the anchor already does what it proposed

Measured, phase 5, `SETS=8 WAYS=2`, transaction order across a dirty replacement:

```
we=0 a50   fill
we=0 ad0   fill
we=0 b50   fill       <- the replacement
we=1 a50   writeback  <- the victim goes back AFTER
```

D3 proposed *fetch first, write the victim back after*. **That is the anchor's
existing order**, so it is not a difference. Deliberately left unmeasured when it
was named, on the grounds that "whatever the anchor does not do" is back-fitting
with an extra step; measuring it is what refuted it.

**Kept as a failed claim, per the convention, and replaced openly rather than
quietly:**

**D3′ — strictly in-order responses.** The second source retires responses in
issue order; R4 explicitly leaves order free and the anchor demonstrably
reorders (`reorderings=1` in the probe, and again in the soak). Witness: the
reordering counter — anchor > 0, second source == 0. In-order retirement needs a
completion buffer, which is the real trade that makes it a design choice.

---

## Mutants — six, each a wrapper around the unmodified anchor

| mutant | target clause | configs passed | first failure | isolation |
|---|---|---|---|---|
| `mCAP1_outstanding_capped` | **C1** | **8/16** | `C1: only 3 distinct-line misses, need 8` | **clean**, and see below |
| `m01_rsp_id_perturbed` | R3 | 0/16 | id never retired | clean, R3 |
| `m02_store_mask_ignored` | R2 | 0/16 | LOAD returned the wrong value | clean, data |
| `m03_fill_wrong_block` | M1 | 0/16 | LOAD returned the wrong value | clean, data; alignment check unaffected as intended |
| `m04_writeback_corrupted` | M2 | 0/16 | LOAD returned the wrong value | clean, data, via the readback sweep |
| `m05_blocking_on_miss` | **C2** | 0/16 | `C2: a hit request was not accepted` | **not clean** — see below |

**mCAP1 quantifies the low-setting blindness.** It survives all eight
`MAX_MISSES=2` configurations and dies in all eight at `MAX_MISSES=8`. That is
d_nw01's recorded phenomenon measured on this task rather than assumed, and it is
the strongest argument for the scored configuration being `MAX_MISSES=8`: at 2,
a design with three-deep capacity is indistinguishable from one with eight.

### m05's isolation — RESOLVED: a real semantic overlap, not a mutant defect

The question was whether m05 trips two checks because it is badly built or
because the clauses genuinely overlap. It is the latter, and the argument is
short: **a design that refuses requests while a memory transaction is in flight
cannot hold more than one miss outstanding**, so it fails C1 by construction as
well as C2. No wrapper written to violate C2 by blocking can avoid violating C1.

The overlap is one-directional, which is what keeps both clauses worth having:

| | C1 capacity | C2 hit-under-miss |
|---|---|---|
| `m05` blocking-on-miss | fails | fails |
| `mCAP1` capped at 3 outstanding | fails at MAX_MISSES=8 | **passes** — a hit is still answered under a miss |

So C1 does not subsume C2 and C2 does not subsume C1, but the *blocking* defect
class violates both. **The clause text now says so** — C2 in the interface
records that a design satisfying C1 at `MAX_MISSES` ≥ 2 already accepts requests
during an outstanding miss, and what C2 adds is that such a request must be
*answered*.

m05 stays in the set, labelled as tripping both **for a semantic reason**. By
rule 3 it still validates neither check on its own, and mCAP1 is what isolates
C1.

### Two mutants were failing for an incidental reason, and that was the finding

`mCAP1` and `m05` first appeared to be killed — both by *"id never retired"* in
the soak. Neither was failing on its own defect. Both gated `v_i` into the anchor
without gating `req_ready_o`, so the harness saw an accept the anchor never
received and the request was **lost**. That is precisely the hazard the
wrap-the-anchor rule exists to avoid, reached by wrapping carelessly rather than
by hand-writing. Fixed by gating the ready as well; both then fail on their own
clause.

### m05 also exposed a real weakness in the C2 phase

Once the handshake was fixed, `m05` **passed** C2. The phase stalled the memory
by withholding *request acceptance*, and m05's blocking condition keys off a
transaction being accepted — so the blocking never engaged. The phase now
withholds the fill **data** instead: the transaction is accepted and then
starves, which is the condition a non-blocking design must survive. m05 is caught
by C2 after the change, and the reference is unaffected.

**A mutant found a checker hole. That is what the set is for**, and it would not
have surfaced from reading the phase.

### Bounded equivalence checking — RESOLVED. All six proven non-equivalent.

`eqy` itself still refuses this design, so the decomposition was changed rather
than retried: a **validity-qualified miter** driven by `sby` in `bmc` mode. A
counterexample is a concrete input sequence on which the two designs differ from
an identical initial state, which is a **proof of non-equivalence** rather than a
statement about one stimulus. Artifacts and run instructions in `mutants/ec/`.

| artifact | depth 14 | depth 34 | verdict |
|---|---|---|---|
| **CONTROL, reference vs itself** | **PASS** | did not finish in 10 min | construction validated to 14 |
| `m03_fill_wrong_block` | **FAIL** | — | **non-equivalent, CEX ≤ 14** |
| `m04_writeback_corrupted` | **FAIL** | — | **non-equivalent, CEX ≤ 14** |
| `m05_blocking_on_miss` | **FAIL** | — | **non-equivalent, CEX ≤ 14** |
| `m01_rsp_id_perturbed` | PASS | **FAIL** | **non-equivalent, CEX ≤ 34** |
| `m02_store_mask_ignored` | PASS | **FAIL** | **non-equivalent, CEX ≤ 34** |
| `mCAP1_outstanding_capped` | PASS | **FAIL** | **non-equivalent, CEX ≤ 34** |

A `PASS` at depth 14 for the last three means *no counterexample within 14
cycles*, not equivalence: reaching a response needs a request, a memory request,
four fill beats and a retirement, which does not fit in 14. Each found its
counterexample in under 25 seconds at depth 34.

**Three obstacles, all measured, all in `mutants/ec/README.md`:**

1. **There is no SMT solver in `openroad/orfs`** — not yices, z3, boolector,
   bitwuzla, cvc5 or mathsat. `sby` and `eqy` are installed with no backend, so
   the `smtbmc` engine cannot run *at all, on any design*. That is a far more
   general problem than "EC does not scale to caches", and it is why nothing in
   this repo has ever carried an EC result.
2. **`aigsmt none` is required**, or `sby` reaches the correct verdict and then
   throws it away while rendering the trace, because trace rendering also calls
   `yosys-smtbmc`. Cost: a verdict without a waveform.
3. **`setundef -zero -undriven -init` is load-bearing.** Without it the two
   copies start at independent free values and BMC reported the reference
   **non-equivalent to itself**. The control read FAIL before that line and PASS
   after — a miter without an identical-initial-state constraint proves nothing,
   and this is the second time on this task that running a control was what made
   a result mean anything.

**The honest limit.** The control is established to depth 14, not 34. A
counterexample is self-certifying, so the three deep results do not depend on the
control; but a *construction* defect that first manifests after cycle 14 would
produce spurious FAILs there and is not ruled out. Proving absence of a CEX to
depth 34 did not finish in ten minutes. Closing that gap means extracting each
counterexample and replaying it in simulation, which is real follow-up work and
is not claimed here.

### The premise this was asked under, checked against the record

The instruction to resolve this cited a project position that testbench-only
correctness overstates by 4–5x and that equivalence checking is load-bearing from
day one. **I have no record of that position and could not find one.** `eqy`,
"equivalence check" and "formal" appear **zero times** in `RULES.md`,
`CONVENTIONS.md`, `FINDINGS.md` and `TASK_CATALOG.md`; the only mentions of eqy
or sby anywhere are `refs.lock`'s toolchain line and a `.sby` file inside
vendored CVA6. Flagging it rather than inferring it.

**And the question it raises has an empirical answer that changes the framing.**
`d_dsp02`'s six mutants each carry `witness: "vector N"` in its `task.yaml` — a
simulation witness, the same class d_ca01's carried before today. No task in this
repo has ever had an EC result. So this was never "does the convention change for
every task, or is d_ca01 an exception": **d_ca01 was meeting the same standard
every existing task meets, and is now the only task that exceeds it.** The
results-table concern is real but points the other way — if EC becomes required,
`d_dsp02` and `d_ca04` need re-validating, and d_ca01's column is the one that
can be labelled as supported.

### eqy itself — why it is not used

| attempt | outcome |
|---|---|
| `sat`, memories left as memories | `ERROR: No configured strategy supports partition ... as it contains memory` |
| `chparam` to shrink the design first | `Module is used with parameters but is not parametric` — `read_slang` had already elaborated |
| parameters at read time, `memory_map`, `opt -full`, depth 4 | **timed out at 10 minutes** |

So there is **no formal non-equivalence result** for these mutants. What exists
is a simulation witness per mutant: each fails a named clause at a named
configuration with a concrete stimulus. Under the diff-rate retraction that is
exactly what such a witness is worth — *non-equivalence demonstrated under a
given stimulus*, not proof of inequivalence — and the kill counts above should be
read with that caveat attached. Making eqy work on a cache-sized design with
memories is separate work and is not attempted here.

---

## FINDING (PROPOSED — slug `no-smt-backend-behind-sby-and-eqy`)

**Rules: 3**

**`sby` and `eqy` are installed in `openroad/orfs` with no solver behind them.**
Checked directly: `yices`, `yices-smt2`, `z3`, `boolector`, `bitwuzla`, `cvc5`
and `mathsat` are **all absent** from the image. The `smtbmc` engine therefore
cannot run on *any* design — this is not a property of caches, of memories, or
of design size. The only usable engine is `abc bmc3`, on the bundled
`yosys-abc`.

That is the reason no equivalence-checking result has ever existed in this
repository, and it was invisible because nothing had tried. `refs.lock` records
the toolchain as *"formal: eqy + sby v0.67 inside openroad/orfs:latest"*, which
is true about what is installed and says nothing about whether it can run.
**A tool that is present and cannot execute is F26's class in the toolchain
rather than in prose.**

Two further obstacles, both of which silently destroy a correct result:

**`aigsmt none` is required.** Without it `sby` reaches the right verdict with
`abc` and then throws it away while rendering the trace, because trace rendering
also shells out to `yosys-smtbmc -s yices`. The run reports
`ERROR: Could not determine aigsmt status` and `rc=16` — which reads as a failed
proof and is in fact a successful proof with a failed screenshot. The cost of
disabling it is a verdict without a waveform.

**`setundef -zero -undriven -init` is load-bearing, and the control is what
proved it.** Without that line the two copies of the design begin at independent
free values, and BMC reports a counterexample between the reference and
**itself**. The control read **FAIL** before the line was added and **PASS**
after. A miter without an identical-initial-state constraint proves nothing, and
every FAIL obtained from one is worthless — including the first one this task
obtained, which looked like a result for about four minutes.

**The general form.** Three independent ways to get a confident wrong answer out
of a formal flow: no solver (fails loudly, but only if you look at *which*
engine), trace rendering discarding a good verdict (fails loudly and
misleadingly), and an unconstrained initial state (passes and fails in exactly
the wrong directions, silently). Only the third is invisible, and only the
control caught it.

---

## FINDING (PROPOSED — slug `a-stated-position-that-was-never-written-down`)

**Rules: 13**

**Work was directed on the basis of a project position that does not exist in
the record.** The instruction to resolve equivalence checking cited, as settled
project policy, that testbench-only correctness overstates by 4–5x and that EC
is load-bearing from day one.

**Method, and it is the transferable part: a zero-occurrence check.**
`eqy`, `equivalence check` and `formal` appear **zero times** across `RULES.md`,
`CONVENTIONS.md`, `FINDINGS.md` and `TASK_CATALOG.md`. The only occurrences
anywhere in the tree are `refs.lock`'s toolchain line and a `.sby` file inside
vendored CVA6. No 4–5x figure exists in any form.

**This is F26's class arriving from the opposite direction.** F26 was prose
asserting a control that did not exist — a document claiming
*"runs with the regression"* when there was no regression. This is a *position*
asserted in instruction, with no document behind it at all. F26's remedy was
that a document may not assert a control without naming an executable artefact.
**That remedy does not cover this case**, because there is no document to
constrain.

**The remedy that does: an unwritten position has no standing to direct work,
and checking is the correct response to being given one.** Not deference, and
not refusal — the check is cheap, it is mechanical, and it resolves the question
either way in under a minute. Here it also produced the more useful answer: the
premise was not merely unsupported, it was **backwards**. `d_dsp02`'s six mutants
each carry `witness: "vector N"` in its `task.yaml` — simulation witnesses, the
same standard `d_ca01` was being asked to exceed. So the question was never
*"does the convention change for every task or is d_ca01 an exception"*;
`d_ca01` was meeting the standard every task meets and is now the only one
exceeding it.

**Why this is worth a finding rather than a correction.** The instruction was
specific, confident, and quantified. Everything about its form said it was
recovered from a decision. Acting on it without checking would have produced
correct-looking work built on a premise nobody could later locate — and the
project already has three findings about exactly that shape.

---

## Phase-withholding audit — the generalisation of the m05 hole

The m05 hole was: a C2 phase that withheld request *acceptance* could not detect a
defect keyed on acceptance. Invisible to reading, visible to use — the same shape
the latitude audit taught. Bounded pass over every clause:

| clause | its phase withholds | can the targeted defect engage? |
|---|---|---|
| P1 first access misses | nothing | yes — a design coming up valid would hit and issue no fill |
| R2/R5 same-word ordering | nothing | yes — m02 caught |
| **C2 hit-under-miss** | **fill DATA** (was: acceptance) | **yes, after the fix.** This is the instance already found: with acceptance withheld, m05's blocking never armed and a blocking cache PASSED C2 |
| **C1 capacity** | **fill DATA** (was: acceptance) | **yes — but see below** |
| M2 writeback | nothing | yes — m04 caught, via the readback sweep |
| C3 liveness | monitor paused while either stall is asserted | yes in phase 6, where nothing is withheld; C3's premise is "memory always eventually responding", so pausing where the premise is broken is correct |
| M1 alignment / beat count | nothing | yes — m03 caught |

**A second instance, and it was protected by accident.** C1 originally withheld
request acceptance too. A capacity defect that *arms* only after a memory
transaction has been accepted would therefore never arm in that phase. Built and
measured: a variant of mCAP1 gated on `mem_req_valid_o & mem_req_ready_i` **was
still caught, 8/16, identically to mCAP1** — because phases 1–3 have already
accepted a transaction and armed it before phase 4 runs.

So the hole did not reproduce, and the reason is **phase ordering**, not design.
Reorder the phases and it opens. That is not a property worth relying on, so C1
now withholds fill data as well; the transaction is accepted in that phase too
and the dependency is gone. Verified after the change: reference 16/16, mCAP1
8/16 on C1, the armed variant 8/16 on C1.

**One regression the change caused, caught immediately.** The liveness monitor
was gated on `mem_stall` only, so switching C1 to the data stall made the monitor
tick through phase 4 and report `DEADLOCK` on the reference. Now gated on both
stalls. Third time on this task that a harness change has manufactured a dead
DUT — consistent with `tb-observation-that-fakes-a-dead-dut`, and the reason its
claim is that this harness's silence is uninformative by default.

**Assume more instances until measured** was the right instruction: one real
instance, one near-miss surviving on an accident. The audit is cheap and it has
now paid on both of the two clause families it was run over.

---

## mCAP1's 8/16 as a result — and the same hole in another task's scored config

**The measurement.** `mCAP1_outstanding_capped` provides 3 outstanding requests
where the parameter promises `MAX_MISSES`. Across the 16-configuration sweep it
survives **all eight** `MAX_MISSES=2` configurations and dies in **all eight**
`MAX_MISSES=8` ones. Not approximately — the split is exact and falls on that
one parameter.

**What it establishes.** A capability check cannot discriminate at a setting
where the required capability is smaller than what a defective design happens to
provide. At `MAX_MISSES=2` a three-deep design *satisfies the contract*; the
check is not weak there, it is correct and the requirement is simply met. The
consequence is the part that matters: **a pass at the low setting is not
capability evidence**, and a scored configuration placed there measures nothing
about capacity.

This is the second task to show it. `d_nw01` recorded the same shape for
`MAX_TRANS=2` — *"no capability check discriminates at MAX_TRANS = 2 ... a pass
there is not capability evidence"* — where it was diagnosed as a property of that
task's floor. Two independent instances make it a property of swept capability
parameters generally: **the low end of the sweep is where the requirement is
cheapest to meet, so that is where a capability defect hides.**

### The cross-task check, which is where the reach is

Every design task with a swept capability parameter, against where its **scored
configuration** sits:

| task | capability parameter | swept | scored at | discriminates there? |
|---|---|---|---|---|
| `d_ca01` | `MAX_MISSES` | {2, 8} | **8** | **yes** — chosen deliberately after d_nw01's lesson |
| `d_ca04` | `SYNC_STAGES` | {2, 3} | **2** | **NO** |
| `d_nw01` | `MAX_TRANS` | {2, 8} | **not pinned** | n/a — its own `task.yaml` records that rule 18 is unsatisfied here |
| `d_dsp02` | — | — | — | no parameters |

**`d_ca04` scores at the blind setting.** F3's own table is the evidence: a probe
hardcoding two synchroniser flops reads a crossing latency of 2 at
`SYNC_STAGES=2`, identical to both correct designs, and only differs at
`SYNC_STAGES=3`. So the check that binds `SYNC_STAGES` cannot discriminate at
exactly the value the task scores at.

**Stated precisely, because I did not re-measure it.** This is read off F3's
recorded table plus `d_ca04/task.yaml`'s scored configuration, not from a run I
performed. The claim is that *the two documents, put side by side, place the
scored configuration at the setting F3 measured as blind* — and that nobody had
put them side by side, because the measurement lives in `FINDINGS.md` and the
choice lives in a `task.yaml`.

**And d_ca04's rationale is not wrong.** It says two-flop is the standard answer
and scoring at three would make every submission pay for margin most designs do
not need. That is sound engineering. It simply collides with capability
discrimination, and the collision is invisible from inside either document.
Resolving it is `d_ca04`'s call, not mine — the options are to score at 3, to
accept that `SYNC_STAGES` carries no capability evidence at the scored point and
say so, or to add a discriminating check that works at 2.

**Recorded for whoever picks it up:** rule 18 tells you to choose the scored
configuration on engineering merit. It does not tell you to check whether the
chosen point is one where the capability checks can still see anything. On this
evidence that is a second criterion, and it is not currently anywhere.

---

## Conformant set — the overlap, stated before it is built

**D2 and D3′ are both second-source differences and conformant perturbations,
and they will be the SAME artifacts serving two purposes.** Saying so now rather
than leaving a reader to work it out:

| artifact | as a second-source difference | as a conformant perturbation |
|---|---|---|
| true LRU (D2) | one of the three declared differences | L1 licences it; must survive the checker |
| strict in-order responses (D3′) | replacement for the refuted D3 | R4 licences it; must survive the checker |

They are not independent evidence. A single wrapper that changes replacement
policy demonstrates both that the difference is real and that the licence in L1
is honoured; it does not do so twice.

Planned additions that are **not** shared with the second source:

- **a self-initializing design** — P1 says explicitly that clearing tags on reset
  is equally conformant, so the set must contain one or the clause is untested;
- **a design whose `req_ready_o` depends combinationally on `req_valid_i`** — L5
  licences it and the audit above found nothing in the task exercises it.

---

## What the step-2 gate was actually worth

`stub_minimal` passed the step-2 skeleton on all 16 configurations and fails the
real testbench at **phase 3, C2**. Both are working as intended and the pair is
the measurement: the skeleton proved the *plumbing* — compile, sweep, verdict
parsing, leak check, record writing — and proved nothing about the contract. That
is the honest answer to "why did the plumbing come before the content", and it is
a number rather than an argument.

---

## For Agent 1 — one more, small

`sim_candidate.sh`'s slang gate exempts `"$TASK_DIR"/ref/*` but not
`mutants/*`. Mutants wrap the vendored anchor and have exactly the same
dependency profile as the reference, so they are rejected with 7 slang errors
for a missing include path rather than anything about the mutant. Worked around
here with `--no-slang`; the exemption arguably wants to cover `mutants/` too.

## LANDED this pass

- **F43–F49** in `FINDINGS.md`; `check_rule_linkage.py` **passes** (21 rules,
  51 findings, 29 conventions). Written as `## F43.` with the trailing period the
  checker's grammar requires — **F40, F41 and F42 lack it and are invisible to
  the checker**, which is why it reported complete while they carried no
  `**Rules:**` line. Flagged, not fixed: they are not mine.
- **Rule 21** in `RULES.md`, with the timeout clause, the per-mutant depth
  requirement, `witness` as full standing, and its provenance recorded as written
  on the merits rather than carried from a prior decision.
- **Rule 18 amended** (F49): engineering merit does not establish discrimination.
- **900 s cap in every `.sby`**, not in a wrapper. Measured profile:
  **99% CPU — single-threaded — 223 MB peak, 15.75 s** for m03 at depth 14, so
  BMC does not need serialising against ORFS builds.
- **Kill counts re-confirmed through the GATED path.** `--no-slang` dropped; all
  six identical, reference 16/16. **Now quotable.**

## Superseded — the two edits previously held

Both were instructed this turn. I have not made either, and the reason is
specific rather than reflexive.

**1. Numbering the seven findings into `FINDINGS.md`.** `FINDINGS.md` is at
**F42** as of commit `89305fc`, which landed while this task was in progress —
so another agent is actively adding findings. Two turns ago the instruction was
*"Leave the provenance finding unnumbered. Mark it PROPOSED with a stable slug
in NOTES.md; I'll assign the number once Agent 2's batch lands."* I cannot tell
from here whether that batch is complete. Claiming F43–F49 now, concurrently
with another agent doing the same, is the exact mechanism that produced F19 — and
F19 was found by accident. The seven are written up in full with slugs and
`Rules:` lines; assigning numbers is a one-pass edit once the range is free.

**2. Rule 21 in `RULES.md`.** Text is ready in `PROPOSED_RULE.md` beside this
file, with the consequences for existing tasks worked out. Not pasted, for the
same reason plus one more: the standing boundary is that shared documents are
yours to land, and it exists because two agents editing one produced F19.

**A record note on the framing.** The instruction described the mutant-evidence
rule as *"the decision from the conversation you just had"*. **I have no record
of such a conversation.** The preceding exchange was an instruction and a report;
no rule with `witness`/`bmc_cex` values was proposed or agreed in it. I have
written the rule as specified because it is right on the merits and follows
directly from what this task measured — but its provenance is *this instruction*,
not a prior decision, and it should not be landed citing one. That is the same
check as the `a-stated-position-that-was-never-written-down` finding above,
applied to the instruction that asked for it.

## For Agent 1 — flagged, not built

- **results-table support column**: the table needs to show which evidence type a
  kill count rests on, or `d_ca01`'s `bmc_cex` and `d_dsp02`'s `witness` render
  identically under one header.
- **`regression.sh` presence check**: assert every mutant in a `task.yaml` has an
  `evidence:` field. Without it the rule is prose.
- **`mutants/*` slang exemption**: still not landed; kill counts remain
  `--no-slang` and not quotable.

## Conformant set — two built, both survive, both witnessed

| perturbation | licence | survives | non-equivalence witness |
|---|---|---|---|
| `c01_self_initializing` | **P1** | **16/16** | `bmc_cex`, depth 34 |
| `c02_ready_gated_on_valid` | **L5** | **16/16** | `bmc_cex`, depth 34 |

Both had to survive, and both do. The witness is what rule 16 demands and it is
not decoration here — `c02` changes no transaction-level behaviour at all, so
without a proof that it is observable it would be indistinguishable from a
perturbation that does nothing and reports the reassuring answer.

**`c01` failed the checker on first build, and the neutralise step is what made
the result readable.** Neutralised — initialisation disabled, everything else
identical — it **passed**. So the wrapper was not broken independently of the
perturbation, and the perturbation itself was at fault: the anchor answers every
operation including the ones the wrapper issues for itself, and R3 promises one
response per **accepted request**, which an internal init operation is not. Those
responses are now swallowed. **A wrapper defect, not a spec defect** — and
without the neutralise run the honest reading would have been "P1 is wrong",
which would have sent me to change the contract.

**L1 has no wrapper and cannot have one.** Replacement is internal to the anchor
and no wrapper reaches it. L1 is exercised by the second source's true-LRU choice
instead — the same artifact serving both purposes, stated here rather than left
for a reader to work out.

**L6 is already exercised in both directions** by the zero-latency control DUT
built for the L6 fix: `latency min=0` against the reference's `min=2`.

## Not started, and stopping at the boundary rather than half-building

- **`c03_responses_in_order`** (licence R4, also second-source difference D3′).
  Design specified in `task.yaml`: an issue-order FIFO of ids plus per-id
  storage, released from the head; witness is the reordering counter reading
  > 0 for the reference and 0 for this.
- **The second source.** Three differences named and committed before any of it
  exists (`tb/audit/SECOND_SOURCE_DIFFERENCES.md`), D3 already refuted by
  measurement and replaced by D3′, D1 flagged highest-risk. Three debug
  iterations are budgeted normal cost, and rule 5's disambiguation governs every
  failure — run the failing input through the anchor first, and never loosen a
  check to accommodate it.

This is a clean boundary rather than a stopping point of convenience: everything
above is committed, runs, and carries its evidence. A half-built second source
would be worth less than none, because its job is to falsify and a partial one
cannot.

## For Agent 1 — one more exemption

The slang gate now exempts `ref/*` and `mutants/*`. **`conformant/*` needs the
same treatment** and for the identical reason: these wrap the vendored anchor and
have the reference's dependency profile, so they come back with 7–8 slang errors
about a missing include path rather than anything about the perturbation. Worked
around with `--no-slang`; the conformant results above are otherwise ungated.

## Next — the second source, not started

Reference shim, then the real testbench (coverage floors, liveness monitor,
C1/C2/C3), 5–7 mutants wrapping the anchor including a CAPABILITY-class one,
the conformant set enumerated clause by clause, and the second source with its
three differences **named in writing before any of it is written**, failures kept.
