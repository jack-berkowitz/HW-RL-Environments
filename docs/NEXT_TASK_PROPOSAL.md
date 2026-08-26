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

### The alternative I did not pick, and why

**`d_ca02` speculative_lsq** has the single most promising line in the catalog —
*"the violation detector only fails under specific store/load interleavings"* —
which is mechanism B stated outright. The anchor is present.

**The boundary is the problem.** CVA6's `load_store_unit` interfaces with the
scoreboard, the commit stage and the MMU; reaching memory-order-violation
detection means shimming most of a pipeline, and a shim that ends up containing
the sequencing **puts behaviour in the reference**, which is what disqualified
`d_dsp01`. It is the better task if the boundary turns out to be clean, and
checking that is a step-0 question worth an hour — but on present evidence
`d_ai03` is the one whose boundary is already verified single-level.

`d_ca05`, `d_nw02` and `d_nw04` all rest on **fairness and starvation**, which are
liveness properties. The three tasks that discriminate nothing today are exactly
the ones whose contracts are throughput and routing, and `d_nw01`'s fairness floor
passes every submission. I would not build a fourth until one of the three
existing ones is shown to discriminate.
