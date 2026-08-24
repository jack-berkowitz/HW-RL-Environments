# Task Catalog

**The single current task list.** Version history lives in this file, not in its
name — four differently-versioned catalogs is how the previous set drifted apart.

| | |
|---|---|
| **v1 / v2** | a two-tier layout, then a 21+23-task domain list. Both removed. |
| **v3** | this list, rebuilt on failure modes rather than line count. |
| **v3.1** | `ai_d01`, `ca_d08` and `nw_d01` removed as too easy; `DESIGN_CATALOG.md`, `DESIGN_TASKS_NO_GOLDEN_RTL.md` and `VERIFICATION_CATALOG.md` folded in here and deleted. |

**The v2 task set — 21 design and 23 verification tasks with their anchors and
per-task reasoning — is recoverable at git `c7609fa`**, the commit before the
tier layout was removed. Measured results from the three removed tasks are in
`RESULTS_ARCHIVE_V2_TASKS.md`. Methodology findings are in `FINDINGS.md`.

The v3 rebuild followed a frontier model appearing to beat the upstream
reference on area and power for `nw_d01`. **That triggering claim did not
survive re-derivation** — the reference had never passed the correctness gate at
all, and once it did, the result decomposed into a real capability gap (half
throughput at matched widths) with essentially no genuine optimisation. The
rebuild stands on the tasks' own merits; the claim does not. See
`RESULTS_ARCHIVE_V2_TASKS.md`.

---

# ORACLE CLASSES — what evidence each task can produce

Not every task has an external RTL oracle, and the ones that don't carry a
weaker guarantee. Stated up front, so that "the testbench passes correct RTL"
means something specific per task rather than something vague everywhere.

**Class A — external RTL oracle.** Vendored upstream RTL behind a port shim is
what the testbench is proven against. This is the strong case and the one the
methodology's claim to rigour actually rests on: *the testbench passed RTL
nobody on this project wrote.* The shim is combinational renaming and struct
pack/unpack only — if bridging needs behaviour, the shim has failed and the task
converts to a verification task rather than having its spec reshaped to fit.

**Class B — local model of record.** No outside RTL ever runs. The oracle is a
Python model written from the published algorithm or ISA, plus committed
vectors. The only RTL available to prove the testbench is RTL this project
wrote, so **"the testbench passes known-correct external RTL" is NOT AVAILABLE
for these tasks and must never be claimed.** The substitute guarantee is three
things, each recorded in the task's `NOTES.md`:

1. the model is derived from the documented algorithm, **not transcribed from a
   reference implementation**;
2. the model, its generator and the vectors are committed, so the oracle is
   reproducible and auditable by a reader who distrusts it;
3. mutation testing carries the sharpness argument *by itself* — there is no
   second signal, so the mutant set has to be better here, not worse.

**Class C — cross-check only.** Upstream is consulted once to confirm a
locally-generated artifact matches a known-good one, and is never vendored.

### Why model_of_record is valid for design tasks and never for verification

A **design** task ships a port-only `_iface.sv` and asks the model to write RTL.
The oracle's job is to decide whether that RTL is correct, and a Python model
derived from a published algorithm can do that: it is an independent statement
of the same specification, and the mutants test whether the checker built on it
is sharp.

A **verification** task ships the DUT and asks the model to write the testbench.
The oracle's job is now to decide whether a *testbench* is adequate — which
requires knowing that the testbench passes correct RTL and fails incorrect RTL.
A locally-written model cannot supply the first half: the RTL it would validate
against is RTL this project wrote against the same understanding, so a shared
misreading of the spec is invisible. **Verification tasks therefore require
Class A anchors.** A verification task with no external RTL is not a weaker
task; it is not a task.

---

## Two hard constraints this rebuild respects

**1. Egress is closed and `refs.lock` is frozen.** Every Class A task below
anchors on a module inside one of the 21 repos vendored in Phase 0. Nothing here
requires reopening the network.

**2. Design and verification anchors are disjoint at module level.** A
verification task ships a decontaminated copy of its golden RTL. If that same
module were a design task's hidden reference, a model working both would be
handed the answer. Shared *repo* is fine; shared *module* is not. The partition
below is built around this.

## What difficulty means here

The v2 tasks were sized by line count, which turned out to be the wrong proxy.
These are selected on failure modes frontier models actually hit:

- **Liveness under concurrency** — deadlock and starvation are not data
  properties, and no amount of output checking finds them by accident
- **Rare interleavings** — bugs that need a specific concurrent condition across
  large state
- **Multiple clock domains** — almost absent from v2
- **Bit-exact arithmetic across a full corner space** — subnormals, rounding
  modes, tininess
- **Allocation and scheduling** — allocators, multi-bank arbitration at width
- **Naive-correct far from PPA-competitive** — where the easy answer works and
  loses badly

---

# DESIGN TASKS (16)

## Comp Arch (5)

| id | module | why it's hard | anchor (vendored) | Class | status |
|---|---|---|---|---|---|
| `d_ca01` | `nonblocking_dcache` | Full hit-under-miss and miss-under-miss: MSHR allocation, secondary merge, fill/replay ordering, store merging, forward progress under saturating traffic. Deadlock freedom is the real requirement. | basejump `bsg_cache_non_blocking` | A | not started |
| `d_ca02` | `speculative_lsq` | Speculative load issue with memory-order-violation detection and replay. The violation detector only fails under specific store/load interleavings. | CVA6 `load_store_unit` subsystem | A | not started |
| `d_ca03` | `sv39_mmu` | Sv39 MMU: three-level page-table walk, 16-entry instruction and data TLBs, ASID and global pages, superpages with misalignment faults, permission and A/D checks, fault-cause generation and priority — **and physical memory protection, which is in the walk path rather than alongside it**: `cva6_ptw.sv:250` instantiates `pmp` directly, so with no PMP region configured a U-mode walk is denied and reports cause 5 instead of translating. A spec omitting it describes a different module. | CVA6 `cva6_mmu` (`cva6_ptw` + `cva6_tlb` + `pmp`) | A | **BUILT + SCOREABLE.** Ships `sv39_mmu`. Reference PASS 175/175; second source PASS 175/175, written against the spec alone and 1.68x faster (899 cycles against 1,513); 6 negative controls hold their verdicts. Two scored axes reported separately, correctness and total cycles. task_text_hash `360afdc7295d5fd8`. PPA not yet run. |
| `d_ca04` | `async_fifo_cdc` | **Two-clock.** Gray pointers, synchronizer depth, full/empty with no false assertion at any clock ratio, reset sequencing across domains. | PULP `common_cells/cdc_fifo_gray.sv` | A | **BUILT + AUDITED** |
| `d_ca05` | `miss_handler_arb` | Multi-requester miss handler: arbitration among cache controllers, AMO handling, refill sequencing, no requester starvation. | CVA6 `miss_handler` / `std_nbdcache` | A | not started |

## Networking (4)

| id | module | why it's hard | anchor (vendored) | Class | status |
|---|---|---|---|---|---|
| `d_nw01` | `axi4_xbar` | Full AXI4 crossbar: outstanding-ID tracking, no per-ID response reordering, deadlock freedom under all-to-all traffic, QoS arbitration. Correctness is a liveness property. | PULP `axi/src/axi_xbar.sv` | A | **BUILT + AUDITED** |
| `d_nw02` | `vc_router_alloc` | Separable VC allocation plus switch allocation. Allocator design is research-adjacent and the naive answer starves under load. | basejump `bsg_wormhole_router` + `bsg_router_crossbar_o_by_i` | A | not started |
| `d_nw03` | `axis_switch_oq` | Output-queued stream switch: per-output scheduling, frame atomicity, no head-of-line blocking across inputs. | Forencich `verilog-axis/rtl/axis_switch.v` | A | not started |
| `d_nw04` | `tcdm_log_interconnect` | Many-master/many-bank interconnect: single-cycle bank conflict resolution at width, fairness under hotspotting. | PULP `hci` | A | not started |

## AI Acceleration (4)

| id | module | why it's hard | anchor (vendored) | Class | status |
|---|---|---|---|---|---|
| `d_ai01` | `fp16_gemm_array` | **8×8** chain of binary16 fused multiply-adds with a contractual operand skew, five IEEE rounding modes, subnormals at both ends, and mode-dependent delivered values at the range boundaries. | PULP `redmule` (`redmule_engine`) | A | **BUILT.** Ships `fp16_gemm_array` at HEIGHT=WIDTH=8. Reference PASS at both H=4 and H=8, 3400/3400 cycles each; 7 negative controls; second source PRESENT with one open residual. task_text_hash `86b7d95729381055`. PPA absent. |
| `d_ai02` | `gemm_tiler` | Full GEMM tiling control: loop bounds, edge tiles, accumulator reuse, double-buffered operand fetch overlapping compute. | NVDLA CACC/CDMA control | A | not started |
| `d_ai03` | `dma_2d_chained` | 2D/3D strided DMA: descriptor chaining, unaligned source and destination, mid-transfer reconfiguration, completion ordering. | PULP `idma` | A | not started |
| `d_ai04` | `sdp_requant_pipeline` | Accumulate → bias → scale → requant → clamp at full rate: per-channel parameters, saturation boundaries, no bubble. | NVDLA SDP | A | not started |

## DSP / Arithmetic (3)

| id | module | why it's hard | anchor (vendored) | Class | status |
|---|---|---|---|---|---|
| `d_dsp01` | `fp_divsqrt_srt` | Radix-4 SRT divide/sqrt with on-the-fly quotient conversion, all IEEE rounding modes, subnormals, fixed initiation interval. Bit-exactness across the corner space is brutal. | PULP `fpu_div_sqrt_mvp` + `cvfpu` | B | not started |
| `d_dsp02` | `fp32_fma_ii1` | fp32 FMA at II=1: five rounding modes, subnormals handled in-pipeline rather than via a slow path, correct tininess-after-rounding. | PULP `cvfpu/fpnew_fma.sv` | **A** | **SCOREABLE**: sim_flags, configs registered, 6 mutants killed through the scored path, second source 4290/4290; PPA in progress |
| `d_dsp03` | `multifmt_slice` | Format-parametric datapath sharing hardware across fp32/fp16/bf16 with correct per-format rounding and exception flags. Resource sharing is the difficulty. | PULP `cvfpu/fpnew_opgroup_multifmt_slice.sv` | B | not started |

---

# VERIFICATION TASKS (17)

> **Status column audited 2026-08-24, VERIFICATION ROWS ONLY.** Every `v_*` row
> below was checked against what is committed. Nine said "not started" while
> being built, scoreable and carrying a reference ceiling; `v_dsp01` said "not
> started" while being rejected; `v_ca06` was missing from the table entirely.
> All corrected, each built row now naming the module it actually ships and its
> `task_text_hash`.
>
> The **design rows above were NOT audited by this pass** and at least two are
> known stale — `d_ca03` and `d_ai01` are both built and committed while their
> rows say "not started", and `d_ai01`'s stated premise is refuted rather than
> renamed. Both record the detail in their own `task.yaml` under
> `catalog_divergence`. Corrections to design rows belong to whoever owns them,
> not to this pass.

Anchors disjoint from every design task above.

## Comp Arch (6)

| id | module | why it's hard to verify | anchor (vendored) | Class | status |
|---|---|---|---|---|---|
| `v_ca01` | `issue_stage` | Full issue: scoreboard, operand read, WAW/RAW tracking, flush and precise recovery. Deep state, rare interleavings. | CVA6 `issue_stage` + `scoreboard` | A | not started |
| `v_ca02` | `cache_ctrl` | Per-port cache controller: miss sequencing, AMO, replay, interaction with the shared miss handler. | CVA6 `cache_ctrl` | A | not started |
| `v_ca03` | `axi_iw_converter` | ID-width conversion: table pressure, stall when no free ID, per-ID ordering preserved across the conversion. | PULP `axi/src/axi_iw_converter.sv` | A | **BUILT + SCOREABLE.** Ships `id_width_conv` (port map + spec only, no RTL). 10 guarded mutants, reference ceiling 10/10, step 5c 22/22, rule-24 reproduction in `mutants/RULE24.md`. task_text_hash `a04f965ad7552b22`. |
| `v_ca04` | `stream_xbar` | Stream crossbar: fairness, no data loss, deadlock freedom under all-to-all. | PULP `common_cells/stream_xbar.sv` | A | **BUILT + SCOREABLE.** Ships `route_xbar` (port map + spec only, no RTL). 10 guarded mutants, reference ceiling 10/10, step 5c 22/22, rule-24 reproduction in `mutants/RULE24.md`. task_text_hash `f4ed051311687cf7`. |
| `v_ca05` | `id_queue` | Out-of-order occupancy by ID, per-ID FIFO ordering, exists-lookup, full/empty edges. | PULP `common_cells/id_queue.sv` | A | **BUILT + SCOREABLE.** Ships `tag_tracker` (port map + spec only, no RTL). 10 guarded mutants, reference ceiling 10/10, step 5c 22/22, rule-24 reproduction in `mutants/RULE24.md`. task_text_hash `fd2ae1ad9bf3719d`. |
| `v_ca06` | `axi_dw_downsizer` | Data-width downsizing: one wide beat becomes several narrow ones, so the observable is a DERIVED quantity -- the byte stream preserved across a re-segmentation -- rather than a port value. Length follows bytes covered, not beat count, and differs from the naive formula only when unaligned or when the range does not fill one downstream block. Two burst types are refused and the refusal emits NOTHING downstream. | PULP `axi/src/axi_dw_downsizer.sv` | A | **BUILT, docs pending.** Ships `dw_downsizer` (port map + spec only). 10 guarded mutants, reference ceiling 10/10, step 5c 22/22. task.yaml, witness runner and mutants/README.md outstanding; not yet scoreable. |

## Networking (4)

| id | module | why it's hard to verify | anchor (vendored) | Class | status |
|---|---|---|---|---|---|
| `v_nw01` | `eth_stack` | ARP plus the surrounding RX/TX path shipped whole: request/reply, cache insert and evict, timeout and retry, gratuitous ARP, broadcast. | Forencich `arp*` + `axis_gmii_rx` | A | **BUILT + SCOREABLE.** Ships `arp_engine` (port map + spec only, no RTL). 10 guarded mutants, reference ceiling 10/10, step 5c 22/22, rule-24 reproduction in `mutants/RULE24.md`. task_text_hash `63dbe82fceded681`. |
| `v_nw02` | `axi_atop_filter` | Atomic-op filtering: synthesised B/R responses, no protocol violation on filtered ATOPs. | PULP `axi/src/axi_atop_filter.sv` | A | **BUILT + SCOREABLE.** Ships `atop_filter` (port map + spec only, no RTL). 10 guarded mutants, reference ceiling 10/10, step 5c 22/22, rule-24 reproduction in `mutants/RULE24.md`. task_text_hash `90f7b34382e396f4`. |
| `v_nw03` | `axis_arb_mux` | Frame atomicity, arbitration behaviour under backlog — **see the correction below**, `tlast` under backpressure. | Forencich `verilog-axis/rtl/axis_arb_mux.v` | A | **BUILT + SCOREABLE.** Ships `frame_arb_mux` (port map + spec only, no RTL). 10 guarded mutants, reference ceiling 10/10, step 5c 22/22, rule-24 reproduction in `mutants/RULE24.md`. task_text_hash `839999302366fa24`. |

> **CORRECTION — the fairness claim was measured false.** This row read
> *"arbitration fairness over long horizons"*. At the anchor's DEFAULT
> arbitration, **three of four backlogged inputs were served zero frames
> across 406** — that is starvation, not unfairness, and a fairness metric
> measured there reports on a design that never gets a turn at all.
> The claim holds only at `ARB_TYPE_ROUND_ROBIN=1`, so the task must pin
> that in its scored configuration (rule 18) or the property it exists to
> test is absent from the configuration it is tested in.

| `v_nw04` | `ptp_clock` | Time-base correctness: fractional-ns accumulation, drift, adjustment without discontinuity. | Forencich `verilog-ethernet/rtl/ptp_clock.v` | A | **BUILT + SCOREABLE.** Ships `ptp_time_base` (port map + spec only, no RTL). 10 guarded mutants, reference ceiling 10/10, step 5c 22/22, rule-24 reproduction in `mutants/RULE24.md`. task_text_hash `b963a88053bae3da`. |

## AI Acceleration (4)

| id | module | why it's hard to verify | anchor (vendored) | Class | status |
|---|---|---|---|---|---|
| `v_ai01` | `idma_backend` | Descriptor-driven DMA: unaligned src/dst, 2D strides, mid-transfer backpressure, completion ordering. **Blocked on the concrete-type wrapper** — see open items. | PULP `idma` (generated backend) | A | not started |
| `v_ai02` | `hwpe_stream_fabric` | Streamer split/merge/fifo: no data loss across width changes, valid/ready never deadlocks. | PULP `hwpe-stream` | A | **BUILT + SCOREABLE.** Ships `stream_realign` (port map + spec only, no RTL). 10 guarded mutants, reference ceiling 10/10, step 5c 22/22, rule-24 reproduction in `mutants/RULE24.md`. task_text_hash `0453b447cb8b1a5c`. |
| `v_ai03` | `redmule_ctrl` | GEMM control: loop bounds, edge tiles, accumulator reuse across tiles. Disjoint from `d_ai01`, which uses the datapath. | PULP `redmule` control | A | not started |
| `v_ai04` | `binconv_array` | Mixed/binary-precision convolution array: precision-mode switching, accumulation correctness per mode. | PULP `ne16` | A | not started |

## DSP / Arithmetic (3)

| id | module | why it's hard to verify | anchor (vendored) | Class | status |
|---|---|---|---|---|---|
| `v_dsp01` | `fp_cast_multi` | Saturation vs wraparound, RTZ vs RNE, out-of-range, NaN→int, every format pair. | PULP `cvfpu/fpnew_cast_multi.sv` | A | **REJECTED**, see `v_dsp01_fp_cast_multi/REJECTED.md`: the anchor carries two flag defects, so a conformant testbench cannot pass it and a passing one is wrong. Not scoreable. |
| `v_dsp02` | `fp_noncomp` | Comparisons, min/max, classification, sign injection: NaN payloads, signed zero, quiet vs signalling. Enormous corner space, trivial-looking module. | PULP `cvfpu/fpnew_noncomp.sv` | A | **BUILT + SCOREABLE.** Ships `fp_noncomp` (port map + spec only, no RTL). 10 guarded mutants, reference ceiling 10/10, step 5c 22/22, rule-24 reproduction in `mutants/RULE24.md`. task_text_hash `eacc3c043e2a5767`. |
| `v_dsp03` | `cdc_fifo_gray` | **Two-clock.** Gray pointer correctness, no loss or duplication at arbitrary clock ratios, reset skew. Verification counterpart to `d_ca04`, and permitted because a design task's reference is never shipped. | PULP `common_cells/cdc_fifo_gray.sv` | A | not started |

> `v_dsp03` is the one deliberate near-collision with `d_ca04`. It is acceptable
> because the design task ships only an `_iface.sv` and never exposes its
> reference. If you would rather have zero overlap at all, drop `v_dsp03` and run
> 15 verification tasks.

---

# A LIMITATION OF THE VERIFICATION HALF — state it, do not let a reviewer find it

**Class A verification tasks carry irreducible recognition risk.**

A verification task ships its DUT, and every DUT derives from a vendored project
whose licence requires attribution notices be **retained** in redistributed
derivatives — SHL-0.51 §4, and the equivalent clauses in Apache-2.0, MIT, BSD and
ISC. Decontamination is therefore bounded by law: the module can be renamed, its
ports and internals renamed, its commentary stripped, but it cannot be shipped
without a notice identifying the corpus it came from.

Mitigation, applied to every shipped DUT: **one corpus-level notice** listing all
18 vendored projects and their licences, rather than a per-file header. That
satisfies retention while saying "this derives from one of these" instead of
naming the project. Everything else is stripped.

**This bounds the risk; it does not remove it.** A distinctive structure may be
recognisable from the code alone, and no licence-compliant transformation
prevents that.

**MEASURED, AND THE RESULT IS BAD.** The probe was run on `id_queue`, the first
verification anchor. A model identified the project, the file **and the original
module name** from the shipped decontaminated DUT with >99 % stated confidence —
scoring identically to the untouched original. It reconstructed the upstream
identifier set (`head_tail_t`, `linked_data_t`, `ID_WIDTH`, `inp_*`/`oup_*`,
`id_queue`) from structure alone; none of those strings is in the shipped file.
**Decontamination bought nothing for this anchor.** See
`probe/RESULT.md`.

Consequences, pending a decision:
- **Verification-task scores are not pure capability measurements** while a model
  can recognise the DUT and recall its upstream testbench — which is the
  deliverable being scored.
- **Run the probe per anchor.** It costs two prompts and the outcome plausibly
  varies with how distinctive a module is; `id_queue` is small and widely
  vendored.
- **Resolve whether web search was enabled.** Pretraining recall can be mitigated
  by anchor choice; live retrieval cannot, and would affect the design half too.

**Not yet reviewed by a lawyer.** The corpus-notice approach is a reading of the
retention clauses, not a legal opinion. Fine for internal work; **a review is
required before anything is distributed to a model provider or released
publicly** — see the pre-release checklist below.

---

# DECISION — VERIFICATION TASKS SHIP NO RTL

**Decided. Verification tasks ship a port map and a fully pinned specification.
The DUT is not shipped.**

## What settled it

A model wrote a testbench for `v_ca05` from the port map and prose alone, having
never seen the RTL. It **passed the golden DUT and all four conformant
perturbations.** The two failure modes that would have sunk the approach both
came back empty:

| bucket | result |
|---|---|
| driver bug — the false-failure mode | **none** in the passing submission |
| reliance on unpromised behaviour | **none** — 4/4 conformant accepted |
| genuine spec gap | **none found** |

The local pilot could not establish this: its author had decontaminated the RTL
and so pre-empted exactly the gaps being counted. **Only a model could be the
untainted author**, which is why this question stayed open from the recognition
probe until now.

The second submission failed, and its failure is *also* evidence for the
decision rather than against it: it checked the DUT before resetting it, which
is a driver defect and not a spec ambiguity.

## What it buys

**Decontamination, licence retention and recognition exposure all disappear
together.** Not mitigated — removed. There is no decontaminated derivative to
ship, so there is nothing to recognise and no notice to retain. The measured
result that decontamination *bought nothing* for `id_queue` stops mattering.

## The consequence that changes the catalog's shape

**Anchor-disjointness dissolves.** The constraint existed because a verification
task shipped a decontaminated copy of its golden RTL, so a module that was also
a design task's hidden reference handed the answer to anyone working both. **With
no RTL shipped there is nothing to hand over.**

So a module may now be **both** a design task and a verification task, and **one
pinned spec can serve both**:

- the **design** task ships the spec and asks for RTL, graded by our checker;
- the **verification** task ships the same spec and asks for a testbench, graded
  by our golden and mutants.

Three consequences worth stating before anyone rebuilds the catalog on this:

1. **Spec cost is now amortised across two tasks**, and the spec is the
   expensive artefact — `d_dsp02`'s pinning work exceeded its RTL work.
2. **The pair is more informative than either half.** The same contract, probed
   from both directions, separates "the model cannot build this" from "the model
   cannot say what correct means."
3. **A shared spec is a shared single point of failure.** A contract defect now
   corrupts two tasks rather than one, which raises the value of rule 15 and of
   the conformant-perturbation control.

## Still required, and NOT settled by this

**The spec must be pinned to the standard of `spec/tag_tracker_spec.md`.** Three
clauses in it are load-bearing — R4 (grant is not an acknowledgement), R10 (a pop
of an absent tag is granted), R3 (no cross-tag ordering) — and each is an answer
to a question you only know to ask **after** seeing an implementation. That is a
real cost and it does not go away; it moves entirely into spec authoring.

**Termination is now a stated task requirement**, after a submission with no
watchdog ran forever against the starvation mutant.

## The BFM sub-decision — still open, and now better informed

Whether the task ships a protocol BFM is **not** settled. The evidence moved:
the passing submission wrote a correct driver unaided, so the plumbing risk is
real but not prohibitive. Against a BFM: it encodes the handshake and so hands
over R4, the most load-bearing clause in the spec. Leave it open; revisit with
more submissions.

---

# PRE-RELEASE CHECKLIST

Before any external distribution — to a lab, a model provider, or a public repo:

- [ ] **Legal review of the third-party notice approach.** Derivatives of
      SHL-0.51, Apache-2.0, MIT, BSD and ISC code are being distributed to third
      parties. The corpus-level notice is our reading of the retention clauses
      and has not been reviewed.
- [x] **GPL/LGPL anchors excluded.** ~~Two vendored repos are copyleft.~~
      **CHECKED AND NOT AN ISSUE:** `ZipCPU/cordic` (GPL-3.0) and
      `ZipCPU/dspfilters` (LGPL) were **never vendored** — both carry
      `vendored_to: null` in `refs.lock`, as do `lowRISC/opentitan`,
      `olofk/serv` and `darklife/darkriscv`. No v3 task anchors any of them, so
      no shipped artifact can derive from them and none appears in the corpus
      notice. Re-check if a future task adds a copyleft anchor.
- [ ] Recognition probe run and its rate recorded.
- [ ] Every task's `NOTES.md` states its oracle class and what it does not claim.
- [ ] **Every spec term checked against its cited source of authority** (rule 15).
      A term citing nothing, or citing the anchor's behaviour, is an inherited
      implementation detail rather than a contract term.
- [ ] **Every rule checked against its originating finding**, and every finding
      against its rule — `python3 scripts/check_rule_linkage.py`.
- [ ] **Every build prompt checked against `RULES.md`** — that it references and
      does not restate.

> F14, F15 and F16 all came from this kind of pass and **none of them would have
> come from running the tests.** Contract defects leave the apparatus working
> perfectly; the only way to find them is to audit the artefact against the
> source of authority.

---

# BUILT TASKS — status detail

## `d_ca04` `async_fifo_cdc` — Class A, built and audited

Reference 18/18, second source 18/18, candidate 18/18 on the tightened spec.
Audited against the standing rules; `DATA_W` (above bit 31), `SYNC_STAGES` and
C4's minimum-depth half were all found unbound and are now bound, each with an
isolated negative control. **First task whose capability audit came back clean.**

Outstanding: none blocking. `find_fmax` on the second source would complete the
picture but is not required for a result.

## `d_nw01` `axi4_xbar` — Class A, built and audited

Reference 16/16, second source 16/16, candidate 16/16 across
`NUM_MST` × `NUM_SLV` × `MAX_TRANS` × `MAX_BURST_LEN`.

> **NO CAPABILITY CHECK DISCRIMINATES AT `MAX_TRANS = 2`.** Both C1 (capacity)
> and C2 (concurrency) are blind there, and the capability mutant
> `mX1_no_cross_id_interleaving` survives **all eight** of those configurations.
> The cause is structural rather than an oversight: the C1 floor is
> `ceil(MAX_TRANS/2)` = 1, and it cannot be raised because the `NO_LATENCY`
> anchor — a correct crossbar — also delivers exactly 1 at that setting. Any
> floor that catches the mutant there fails a correct design.
>
> The eight `MAX_TRANS = 2` configurations still bind something real: a design
> requiring depth ≥ 4 fails them, and the whole data contract, liveness and
> decode behaviour is checked as usual. **But a pass at `MAX_TRANS = 2` is not
> capability evidence and must not be reported as any.**
>
> If discrimination at low depth is wanted later, **add `MAX_TRANS = 4`** rather
> than trying to raise the `T = 2` floor — the anchor's own behaviour makes that
> floor unraisable.

**OUTSTANDING WORK — recorded here so it stops living only in conversation:**

1. ~~Task C negative control.~~ **DONE, and it removed the floor.** The control
   showed the counter measured ID *changes*, not reordering; the corrected
   counter then failed the *reference* at `MAX_TRANS=2`, because reordering is a
   DUT choice AXI permits a design to decline. The requirement underneath was
   capacity with mixed IDs, now enforced in C1. See `NOTES.md § TASK C`.
2. ~~Decide the canonical reference configuration.~~ **DONE — reported as a
   Pareto envelope rather than a winner.** `CUT_ALL_AX` reaches ≥190.48 MHz at
   154 245 µm² [AREA ABSENT -- see F20; unverifiable, the directory it came from was overwritten by a run that FAILED its gate]; `NO_LATENCY` reaches 126.98 MHz at 100 277 µm² [provisional, corroborated]. At least 1.50×
   faster for 54 % more area, neither dominating, and the spec does not
   constrain latency — so picking one would build an arbitrary preference into
   every candidate comparison. **Both are the baseline; candidates are reported
   against the envelope.** `CUT_ALL_AX` stays the build default only because the
   harness and historical numbers use it. See `NOTES.md § CANONICAL`.
3. **A CAPABILITY-class mutant.** The class was discovered on this task and
   currently exists only as prose. The original one-deep candidate is a
   ready-made instance: correct on every transaction, one outstanding per
   master, caught only by C1.
4. ~~`find_fmax.py` on the reference and the second source.~~ **REFERENCE DONE
   AND CONVERGED**: `CUT_ALL_AX` 190.48 MHz at 5.25 ns, bracket [4.875, 5.25]
   (0.375 ns, inside resolution), area **ABSENT** at own Fmax -- 154 245 µm² is withdrawn pending rebuild (F20). `NO_LATENCY`
   126.98 MHz. **This task no longer ships an unconverged Fmax.** Second-source
   sweep running — it is the third envelope point.
5. **Second-source synthesis.** It has never been through ORFS, so its area is
   unknown and it cannot yet appear in a three-way comparison.
6. **`task.yaml` completion** — the Verilator-only flag (the checker uses
   `automatic` in procedural blocks, which Icarus rejects), the `NUM_MST <= 4`
   cap from the fixed `MST_IDX_W = 2` id layout, and the `MAX_BURST_LEN` sweep.

**Candidate PPA is `DID NOT COMPLETE`.** The re-solicited candidate fixed its
capacity gap by provisioning a 256-entry per-master read buffer (36 864 bits),
and that over-build cost it 14× area, 5× single-pair throughput, and physical
closure: the build reached detailed routing and failed with 2003 DRC violations.
Not retried. See `FINDINGS.md`.

---

# What was dropped and why

Everything below fell out of the difficulty band. Not bad tasks — wrong band.

`int8_requant`, `crc32_eth`, `regfile_multiport_bypass`, `plru_way_select`,
`store_buffer_fwd`, `ecc_secded_wrapper`, `cordic_rot`, `cic_decimator`,
`fir_polyphase_decim`, `fft_stage_r2`, `boxcar_filter`, `nco_sintable`,
`axis_width_adapter`, `axi_burst_splitter`, `mac_pause_ctrl`,
`wormhole_flow_ctrl`, `tiny_core`, `mshr_file` (subsumed by `d_ca01`),
`frontend_bpu`, `l1_dcache` (subsumed by `d_ca01`), `rr_arb_tree`,
`tlb` (subsumed by `d_ca03`), `serdiv`, `axi_lite_xbar`, `axi_id_remap`,
`eth_mac_1g_rx`, `fpnew_fma` and `fpnew_divsqrt` as verification tasks (both are
now design tasks).

**`ai_d01`, `nw_d01` and `ca_d08` have since been REMOVED from `domains/`.** All
three were solved by a frontier model on the first attempt, and carrying them as
calibration tasks was not worth the maintenance: every harness change had to keep
five tasks green instead of two. Their measured results are preserved in
`RESULTS_ARCHIVE_V2_TASKS.md` because they are still evidence about where the
difficulty floor sits, and the task directories are recoverable from git history
at `1e9c455`. The surviving design tasks are `d_ca04` and `d_nw01`.

---

# Costs of this rebuild — read before committing

**Build time per task roughly triples.** These DUTs are 5–20× larger. Testbenches
for `d_ca01` or `d_nw01` need traffic generators and liveness monitors, not
directed vectors plus a soak. Budget accordingly; 32 hard tasks is not 32 v2
tasks.

**Shim risk is much higher.** CVA6 already produced three conversions on smaller
modules. `d_ca02`, `d_ca03`, and `d_ca05` are all CVA6 subsystems with heavy
package coupling. Expect the shim check to fail on at least one. The
stop-and-report rule at a fourth conversion still applies, and here it is more
likely to fire — if it does, the fix is substituting a basejump or PULP anchor,
not draining the design side.

**Liveness needs testbench machinery you haven't built.** Deadlock and starvation
are not caught by output comparison. `d_ca01`, `d_nw01`, `d_nw02`, `d_nw04` all
need forward-progress monitors: per-requester watchdogs that fail if any request
goes unserviced for N cycles under continuous offered load. Build that harness
once, reuse it across all four. It lives in
`testbenches/common/liveness_monitor.svh`.

### STANDING PROCEDURE — negative control for silent-failure checkers

> **Any check whose failure mode is ABSENCE rather than MISMATCH must be
> validated against a known-failing input before it is trusted.**

This is general, not specific to liveness. A scoreboard that compares outputs
announces itself when it is broken: it stops matching. A check that fires on the
*absence* of something cannot. It looks exactly like coverage while providing
none, and there is no way to tell the two apart from a passing run.

The house conventions already contain one member of this family — the coverage
floor, which exists precisely because "the run passed" and "the run never
reached the interesting state" are indistinguishable without it. Liveness
monitors are the second. Any future check of the form "X should eventually
happen" is a third.

**The sharpest form of the problem: a broken harness and a broken DUT produce
identical output.** A wedged testbench and a deadlocked design both emit
nothing. Building `d_nw01`'s liveness rig hit exactly this — the first version
reported DEADLOCK on the *correct* reference because its own driver models had
wedged. Without both a known-good and a known-bad input to compare against,
there is no way to know which side is broken.

#### Corollary added after the `d_nw01` capability audit

> **A control validates a check only if it fails that check and nothing else,
> and only if the harness can saturate what the check measures.**

Building the C2 concurrency control took three attempts, and every failure was a
hole in the *check* rather than in the mutant:

1. The mutant failed C1 as well as C2, so it proved nothing about C2 in
   particular. **A control that fails several checks at once validates none of
   them.**
2. The harness's own slave models were the bottleneck, so a design that
   serialised all traffic still kept up and scored 199 % — passing. **A
   throughput-shaped check is only as sharp as the load the harness can offer;
   if the harness is the limiting resource, the check measures the harness.**
3. The mutant throttled the single-pair baseline as much as the concurrent case,
   leaving the *ratio* unchanged. **A check expressed as a ratio is blind to any
   defect that scales both of its terms.**

The same audit produced the most expensive instance of the general rule so far,
and it was in the runner rather than in any checker: `sim_candidate.sh` picked
the scoring testbench with `ls tb/*_tb.sv | head -1`, so a task carrying both a
liveness rig and a full checker silently scored **whichever name sorted first**
and reported passes for it. **A weaker checker substituted in silence is
indistinguishable from a strong one passing.** The scoring testbench is now
required to be `tb/<dut>_tb.sv`, and the runner refuses to run rather than
choose a neighbour. Any harness that *selects* among artefacts needs the same
scrutiny as any check that fires on absence.

### STANDING PROCEDURE — the runner never discovers its artifacts

> **THE RUNNER NAMES ITS ARTIFACTS EXPLICITLY AND REFUSES WHEN THEY ARE ABSENT;
> IT NEVER DISCOVERS THEM BY PATTERN.**

Same family as the wedging harness: the run looked clean while measuring the
wrong thing. `sim_candidate.sh` selected the scoring testbench with
`ls tb/*_tb.sv | head -1`, so a task carrying both a liveness rig and a full
checker scored whichever name sorted first — and reported passes for it.

Globbing, sorting, and silent defaults are all the same defect: they turn a
missing or ambiguous artifact into a *different* run rather than an error. A
selection that cannot fail is a selection that cannot be trusted. Any shared
path that picks among artifacts must name what it wants and stop when it is not
there.

Therefore, for every task using a liveness monitor, and **before** the full
testbench is built on top of it:

1. **Build the liveness mutants first.** Break the design so it genuinely
   deadlocks — a response-channel arbiter, an ID-tracking freelist — and confirm
   the deadlock check fires.
2. **Build a separate starvation mutant**: one requester permanently
   deprioritised while others continue to be served. Confirm the starvation
   check fires and the deadlock check does **not**. The two failures have
   different causes and must be distinguishable.
3. **Confirm the inverse.** Run the monitor against the correct reference with
   deliberately slow-but-fair arbitration and verify it does NOT fire. A monitor
   that penalises slowness silently encodes one arbitration policy into the
   contract, which is exactly what the second-source rule exists to prevent.

The negative-control result goes in `NOTES.md` **alongside the mutant table**,
not buried in prose. A liveness claim without it is unsupported.

**ORFS runtime grows a lot.** A 16×16 systolic array or a full AXI4 crossbar is a
different P&R proposition than a width adapter. `find_fmax.py`'s three-phase
search over designs this size may need its bracket widened and its per-run
timeout raised.

**Class B is nearly gone**, which is a real gain — only the two-clock tasks and
the arithmetic ones lean on locally-written vectors, and those are bit-exactly
specifiable. Every other task has external RTL as the oracle.

# Suggested build order

1. `d_ca04` `async_fifo_cdc` — smallest of the hard set, and the first two-clock
   design task; validates that flow before anything expensive
2. `d_nw01` `axi4_xbar` — builds the liveness-monitor harness the others reuse
3. `v_ca05` `id_queue` — smallest verification task; validates decontamination
   and mutant flow at the new scale
4. `d_ca01` `nonblocking_dcache` — the flagship, and the one closest to the
   `ncache` work already in flight

---

# STANDING RULES

**They live in `RULES.md`, which is their only home.** Read it before building a
task and again before deciding a check is good enough.

*A seven-rule restatement stood here, with its own numbering, contradicting
`RULES.md` on what rules 3 through 7 are — the same defect as F19's stale table
in a document the fix did not cover, and invisible to the linkage checker
because it was a numbered list rather than a table. The checker now rejects a
restatement in any form. See F32.*

## House-style exemplars

The canonical testbench style is `testbenches/conventions/rob_tb.sv` and
`testbenches/conventions/fifo_tb.sv`. Conventions, toolchain decisions and the
shared-model contract are in `CONVENTIONS.md`. Methodology findings — what went
wrong and the rule each defect produced — are in `FINDINGS.md`.
