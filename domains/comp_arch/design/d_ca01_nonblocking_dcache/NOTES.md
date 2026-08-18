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

**m05 is recorded as not isolated.** Refusing requests during a memory
transaction also caps outstanding requests, so it trips C1 as well as C2. It is
kept because a blocking cache is the single most likely wrong answer to this
task, but by rule 3 it validates neither check on its own.

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

### eqy — attempted, does not complete on this design

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

## Next — the second source, not started

Reference shim, then the real testbench (coverage floors, liveness monitor,
C1/C2/C3), 5–7 mutants wrapping the anchor including a CAPABILITY-class one,
the conformant set enumerated clause by clause, and the second source with its
three differences **named in writing before any of it is written**, failures kept.
