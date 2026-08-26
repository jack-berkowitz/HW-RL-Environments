# The next design task — proposal

**AGENT-DESIGN-43a92055.** Polled from the run records and `TASK_CATALOG.md`.
Nothing here is built; this is a scope for a decision.

---

## 1. What the results say about what discriminates

Every design task with candidate verdicts, latest run per model:

| task | chat | claude | gemini | others | discriminates |
|---|---|---|---|---|---|
| `d_ca04` async_fifo_cdc | 18/18 | 18/18 | 18/18 | deepseek 18/18, qwen 18/18 | **no — 5 of 5 pass** |
| `d_nw03` axis_switch_oq | 8/8 | 8/8 | 8/8 | | **no — 3 of 3 pass** |
| `d_nw01` axi4_xbar | 16/16 | 16/16 | — | | **no — 2 of 2 pass** |
| `d_dsp02` fp32_fma_ii1 | 1/1 | 1/1 | 0/1 | | weak — 1 of 3 |
| `d_ca01` nonblocking_dcache | 16/16 | 16/16 | 0/16 | | weak — 1 of 3 |
| `d_ca03` sv39_mmu | 1/1 | **0/1** | slang | | **yes** |
| `d_dsp03` fp_multifmt_fma | **0/2** | 2/2 | — | | **yes** |
| `d_ai01` fp16_gemm_array | **0/2** | **0/2** | fails | | **yes — 0 of 3 pass** |

**Three tasks discriminate, three do not discriminate at all, two are weak.**

The three that discriminate nothing are all **structural routing and buffering**
— a CDC FIFO, a stream switch, an AXI crossbar. Their contracts reduce to *move
the data to the right place without losing or reordering it*, and every model
does that. They are not bad tasks; they are **saturated**.

The failures we do have fall into exactly three mechanisms, and they are the
design brief for the next task:

**A. A quantity that must be DERIVED and gets hardcoded.**
`d_ai01`/chat: output leads the reference by exactly one cycle, 11 of 11 testable
pairs at both geometries — L3's pinned `D*(H-1)+2` off by one.
`d_dsp03`/chat: computes two lanes and copies them, passing at `WIDTH=32` and
failing at `WIDTH=64`. In both cases the design is **correct at one
configuration** and the wrongness is only visible at another.

**B. Tagged state that must be SELECTIVELY invalidated.**
`d_ca03`/claude reuses a non-global TLB entry across an ASID change. It returns
the *right address*; the defect is invisible on the delivered surface and shows
only in whether a page-table read happened.

**C. Ordinary data-path arithmetic.** `d_ca01`/gemini returns the wrong word;
`d_dsp02`/gemini gets a subnormal wrong. Caught by any competent scoreboard —
the control case that keeps the suite honest, per `docs/cases/d_ca01_R3R5_load_data.md`.

**A task that challenges models needs A and B, and B is the rarer one.**

---

## 2. Two catalog rows cannot be built at all

Reported rather than edited — `TASK_CATALOG.md` is not mine.

    d_ai02  gemm_tiler            reference: NVDLA CACC/CDMA control
    d_ai04  sdp_requant_pipeline  reference: NVDLA SDP

**`refs/nvdla` contains zero `.sv` or `.v` files.** No anchor is obtainable, so
neither row is buildable as written. This is `d_dsp01`'s disqualification exactly
— F54, where the only vendored FP divider implemented none of the five IEEE
rounding modes correctly and the task was withdrawn rather than faked. Both rows
should be marked before anyone starts one.

Anchors verified present for the other five: `d_ca02` (CVA6
`load_store_unit.sv` + `store_buffer.sv`), `d_ca05` (CVA6 `miss_handler.sv`),
`d_nw02` (basejump wormhole router), `d_nw04` (PULP `hci`), `d_ai03` (PULP
`idma`).

---

## 3. The proposal — `d_ai03`, retargeted

### The catalog's premise is not reachable, and this is the `d_ai01` shape again

The row reads *"2D/3D strided DMA: descriptor chaining, unaligned source and
destination, mid-transfer reconfiguration, completion ordering"* against PULP
`idma`.

**The ND midend is not vendored.** `idma_pkg.sv` names `ND_MIDEND` as an error
source, and there is no `idma_nd_midend.sv` in the tree. Exactly one backend is
generated and concrete: `refs/idma/generated/idma_backend_rw_axi.sv`, 705 lines.
So 2D/3D striding, descriptor chaining and mid-transfer reconfiguration are **not
exposed at any vendored boundary** — the same refutation that retargeted `d_ai01`
from `systolic_16x16_dbuf` to the `redmule_engine` boundary.

**What is reachable is still a strong task**, and it keeps the two halves of the
row that matter: **unaligned source and destination**, and **completion
ordering**.

### The boundary

    refs/idma/generated/idma_backend_rw_axi.sv     705 lines, SHL-0.51

Single-level, parameterised, struct types passed as parameters — the same shim
shape already used for `d_nw01` (`axi_xbar`) and `d_ca03` (`cva6_mmu`). Not a
composition that has to be assembled, which is what disqualified the original
`d_ai01` premise.

Real parameters to sweep: `DataWidth`, `AddrWidth`, `NumAxInFlight`,
`BufferDepth`, `TFLenWidth`, and the capability bits `MaskInvalidData`,
`HardwareLegalizer`, `RejectZeroTransfers`.

### Why it should discriminate — mechanism by mechanism

**Unaligned source AND destination is mechanism A, twice.** The first and last
beats need byte masks derived from `addr % (DataWidth/8)`, and because the source
and destination offsets **differ**, the data must be realigned by a shift of
`(dst_offset - src_offset) mod bytes`. Three derived quantities, none of them a
constant. **A design that assumes alignment, or assumes the two offsets are
equal, passes every aligned transfer** — and aligned transfers are what anyone
writes first. This is `d_dsp03`/chat's two-lane failure with a much larger space
to be wrong in.

**Page-boundary legalization is mechanism A again, and invisible.** AXI forbids a
burst crossing a 4 KB boundary, so a transfer must split at the boundary — and
the split point depends on the **address**, not the length. A design that splits
purely by length is correct on every transfer that does not cross, which is most
of them. `idma_legalizer_page_splitter.sv` is 61 lines and its own author wrote
*"this is written very confusing due to system verilog not allowing variable
length ranges"* — the arithmetic is genuinely hard and the reference proves a
correct answer exists.

**Read/write coupling is mechanism B — the rare one.** With `RAWCouplingAvail`,
reads and writes of one transfer are coupled. A design that decouples them can
deliver **the correct final memory contents** while violating the ordering
contract. The defect is invisible in the data and visible only on the AXI ports —
**structurally the same as `d_ca03`'s T10**, where the wrong MMU returns the right
address and only the memory port shows it. This is the mechanism that caught the
one frontier-model functional failure worth writing a case study about, and this
task has its own instance of it.

**And the capability control is plausible, not merely constructible.**
`NumAxInFlight` is a real capability: a design that ignores it and keeps one
transaction outstanding is a mistake a model actually makes — unlike `d_ai01`'s
rejected mirror control, which constructed only because SystemVerilog resolves an
out-of-range index to X. `d_nw01` already recorded that *a pass at the low setting
is not capability evidence*, so the scored configuration must be the high one.

### The hard clauses, named in advance

1. First-beat and last-beat byte masks derived from the address, both ends.
2. Realignment shift `(dst_offset - src_offset) mod (DataWidth/8)`.
3. Burst split at the 4 KB page boundary, split point address-dependent.
4. Read/write coupling and completion ordering, **scored on the AXI ports, not on
   memory contents** — a stated exception in the `d_ca03` T10 shape.
5. `NumAxInFlight` as a capability, scored at the high setting.
6. Zero-length transfer rejection (`RejectZeroTransfers`) — a small, sharp
   boundary case of the kind `nc_c`/`nc_e` catch narrowly on `d_ai01`.

### Risks, and what would refute the proposal

* **The anchor must be conformance-audited before use.** F54 is why: `d_dsp01`'s
  anchor satisfied rule 11 and was correctly rounded in no mode but RTZ. A DMA
  backend's masking and alignment behaviour must be **measured** on directed
  probes before any clause cites it. If the anchor mishandles unaligned
  destinations, the task dies the way `d_dsp01` did, and that should be found in
  step 0 rather than in step 3.
* **The generated file may not elaborate standalone.** It is one file but its
  closure spans `idma_pkg`, the backend leaf modules and `common_cells`. This is
  the `d_ca03` cost — and `d_ca03` also taught that the closure must be declared
  in **both** `orfs/config.mk` and `ref/sim_flags_verilator.txt`, or the task is
  synthesisable and unsimulable (F88).
* **PPA is unproven at this size.** The largest DRC-clean design recorded here is
  **710,752 µm²**. A DMA backend with buffers is plausibly in that range, but it is
  not known, and `d_ai01` spent a night discovering that its scored geometry did
  not route. The h4 lesson applies: **decide the geometry with a route, not an
  area estimate.**

### The alternative, CHECKED: `d_ca02` is not buildable as written

I said this was a step-0 question worth an hour. It was, and the answer is no.
**Three independent findings, any one of which is disqualifying.**

**1. The mechanism the row describes does not exist in the anchor.** The row reads
*"speculative load issue with memory-order-violation detection and replay. The
violation detector only fails under specific store/load interleavings."* That
describes an **out-of-order LSQ**. Grepping every `.sv` and `.v` in `refs/` for
`memory.order.violation`, `mem_order`, `load.store.violation`, `st_ld_viol`,
`lsq` returns **nothing**. There is no violation detector and no replay path
anywhere in the vendored tree.

**2. What CVA6 actually implements is conservative stalling, and it is
deliberately approximate.** `store_buffer.sv` says so in its own comment:

> you can interlock and wait for the store buffer to drain if the load VA matches
> any store VA **modulo the page size (i.e. bits 11:0)**

and the code compares `page_offset_i[11:3]` — nine bits. A load whose page offset
collides with any pending store's page offset **stalls the pipeline**, whether or
not the addresses are actually the same. The hazard is never allowed to occur, so
**there is nothing to detect and nothing to replay.**

**3. `is_speculative_load` is BRANCH speculation, not memory-order speculation.**
Gated by `CVA6Cfg.SpeculativeSb`, and the handling is *stall and wait for the
branch result* for non-idempotent addresses. `store_buffer.sv`'s header — *"pushes
them to memory if they are no longer speculative"* — is about commit, not about
load-store ordering.

**And the boundary is separately disqualified.** `load_store_unit.sv` (909 lines)
instantiates **`cva6_mmu`** — `d_ca03`'s entire anchor — plus `pmp_data_if`,
`load_unit`, `store_unit` and `shift_reg`. A task at that boundary would
**subsume `d_ca03`**, so a submission's failure could be an MMU defect rather
than an LSQ one, and the two tasks would not be independent.

Building `d_ca02` as written would mean **writing the violation detector into the
shim** — behaviour in the reference, which is exactly what disqualified `d_dsp01`.
Reported for the catalog owner alongside `d_ai02` and `d_ai04`.

### But there IS a real task at `store_buffer`, and it should be kept on the list

`store_buffer.sv` is **320 lines, single-level, cleanly shimmable**, and does not
overlap `d_ca01` (it sits upstream of the cache) or `d_ca03`. The contract in it
is genuinely subtle and carries both mechanisms:

* **Store-to-load forwarding with byte-granular masks** is mechanism A — the
  forwarded value is assembled from overlapping stores of different widths.
* **The 9-bit approximate match is a latitude question with teeth.** A design
  comparing *full physical addresses* is strictly **more precise** than the
  reference, stalls less, and is **still correct**. So the contract must decide
  whether precision is conforming — and if it is, the reference's own stall
  pattern cannot be scored, which is `d_ca03`'s A9 problem in a new place.
* **Forward-versus-drain is invisible in the delivered data** — both produce the
  right value, and the difference shows only in memory traffic. Mechanism B, the
  T10 shape.

It is smaller than `d_ai03` and has one capability axis (`DEPTH_COMMIT`) against
`d_ai03`'s several, which is why it is second and not first: `d_dsp02` is the
comparable size in this suite and it discriminates weakly. **Recommendation
unchanged — `d_ai03` first, `store_buffer` as the next after it.**

`d_ca05`, `d_nw02` and `d_nw04` all rest on **fairness and starvation**, which are
liveness properties. The three tasks that discriminate nothing today are exactly
the ones whose contracts are throughput and routing, and `d_nw01`'s fairness floor
passes every submission. I would not build a fourth until one of the three
existing ones is shown to discriminate.


---

# STEP 0 — ANCHOR AUDIT, RUN BEFORE ANY SPEC TEXT. `d_ai03` IS REFUTED.

**The audit did the thing it exists for.** `d_ai03` is not buildable from
`refs/idma` as vendored, and the reason is fatal at the boundary the proposal
above named. Recorded rather than quietly re-scoped, because the proposal was
committed and a reader should see what changed it.

## The backend does not elaborate

    verilator --lint-only --top-module idma_backend_rw_axi
      MODMISSING: 'idma_legalizer_rw_axi'
      MODMISSING: 'idma_transport_layer_rw_axi'

**Neither module is vendored.** They exist only as Mako templates —
`idma_legalizer.sv.tpl` with **96** template constructs and
`idma_transport_layer.sv.tpl` with **120** — which require the `mario` generator
to instantiate. `refs/idma/generated/` contains exactly one file, the backend
top, and its two generated children were not vendored with it.

**Those two modules are the task.** Legalization *is* the alignment and
page-splitting arithmetic; the transport layer *is* the AXI datapath. Every
mechanism the proposal argued for lives in the two files that are absent.

## Why generating them is not a repair

`mario` would produce them, and `refs/idma/generated/idma_backend_rw_axi.sv`
shows generation is an accepted step for this vendor. But a module generated
**by me** is not a vendored anchor — it is a reference I produced, which is a
different oracle class and a different provenance claim. `refs.lock` is frozen
and `refs.manifest.yaml` is not mine. That is a decision, not a step.

## Second refutation at the same anchor

The proposal already recorded the first: the **ND midend is absent**, so 2D/3D
striding is unreachable. This is the second, and it removes the 1D fallback the
retarget rested on. **Two refutations at one anchor is enough** — `d_ai03` is not
buildable from `refs/idma` as vendored, at any boundary that constitutes a DMA.

What remains vendored is a set of protocol-adapter leaves. `idma_axi_write.sv`
(294 lines) does carry mechanism A —

    assign w_first_mask = '1 << w_dp_req_i.offset;
    assign w_last_mask  = '1 >> (StrbWidth - w_dp_req_i.tailer);

— so a much smaller task exists there. But an adapter leaf is not the DMA the row
describes, and the compositions that would make it one are the missing files.

## The replacement was audited before being recommended

Not repeating the mistake one paragraph later:

    verilator --lint-only --top-module store_buffer
      MODMISSING: 0        <- every module resolves
      20 x %Error-UNSUPPORTED, all of the form
         "'1 << w_dp_req_i.offset"  -- unbound parameter TYPES at standalone lint

**The distinction is the whole point.** `idma` is missing entire modules, which no
shim can supply. `store_buffer` is missing **parameter bindings**, which is
exactly what a shim provides — the same condition `d_nw01` and `d_ca03` were in
before their shims were written. `idma_axi_write` shows the identical error class,
which is why its 39 errors are not evidence against it either.

**Recommendation: `d_ca02`'s `store_buffer` boundary becomes the proposal, on the
scope already written above.** Its premise refutation stands — there is no
violation detector and no replay — so the task is store-to-load forwarding and
conservative hazard stalling, with the 9-bit approximate match as the latitude
question.
