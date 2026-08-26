# What design tasks are left — the landscape after auditing every unbuilt row

**AGENT-DESIGN-43a92055.** Every remaining catalog row audited against its
artefact rather than its description. Nothing built.

---

## The headline: the catalog is wrong more often than it is right

Seven unbuilt design rows. **Four cannot be built at all**, two need retargeting,
one survives as written.

| row | anchor | verdict |
|---|---|---|
| **`d_ca05`** miss_handler_arb | CVA6 `miss_handler.sv`, 855 lines | **VIABLE AS WRITTEN** |
| **`d_ca02`** speculative_lsq | CVA6 `store_buffer.sv`, 320 lines | premise refuted — **salvage viable, elaboration PROVEN** |
| `d_nw02` vc_router_alloc | basejump `bsg_wormhole_router.sv`, 268 | premise refuted — salvage possible |
| `d_nw04` tcdm_log_interconnect | PULP `hci` | **DEAD** |
| `d_ai03` dma_2d_chained | PULP `idma` | **DEAD** |
| `d_ai02` gemm_tiler | NVDLA | **DEAD** |
| `d_ai04` sdp_requant_pipeline | NVDLA | **DEAD** |

Counting the two built rows whose premises also had to be corrected — `d_ai01`
(RedMulE is two-level; the row's composition is exposed at no boundary) and
`d_ca03` (the row omits PMP, which is in the walk path, and claims walk
arbitration the contract does not score) — **the audit has contradicted the
catalog on six rows out of the nine it has examined.**

That is not a complaint about the catalog. It is a statement about what a row is:
**a row is a hypothesis about an artefact, and the artefact has to be read before
a spec is written against it.** Every refutation below cost a lint. The two that
were not caught early — `d_ai01` and `d_ca03` — cost a retarget and a near-miss
respectively.

---

## The four that are dead, and why

**`d_ai02`, `d_ai04` — no anchor exists.** `refs/nvdla` contains **zero** `.sv` or
`.v` files. Nothing to shim.

**`d_ai03` — the anchor's children are code generators, not code.**
`idma_backend_rw_axi.sv` is vendored and does not elaborate:
`idma_legalizer_rw_axi` and `idma_transport_layer_rw_axi` are `MODMISSING`. Both
exist only as Mako templates — 96 and 120 template constructs — requiring the
`mario` generator. **Those two modules are the task**: legalization is the
alignment and page-splitting arithmetic, the transport layer is the AXI datapath.
Separately, the ND midend is absent, so the row's "2D/3D strided" premise was
already unreachable.

**`d_nw04` — the same shape, two wrappers deep.** `hci_interconnect.sv` (402) is a
selector over several implementations. One level down, `hci_log_interconnect.sv`
(201) instantiates **`tcdm_interconnect`** and `hci_new_log_interconnect.sv` (198)
instantiates **`new_XBAR_TCDM`** — and **neither is vendored anywhere in
`refs/`.** The bank-conflict resolution the row is about lives in the missing
modules. Its family is also the saturated one: fairness and starvation, which is
what the three non-discriminating tasks already measure.

---

## The two worth building

### 1. `d_ca05` — CVA6 `miss_handler`. Viable as written, and the strongest of the set.

**The mechanism is there**, which is the thing the catalog gets wrong most often:
79 AMO references, and explicit sections for *"Bypass or miss"*, *"Miss handling
(~> cacheline refill)"* and *"AMO"*. It instantiates three submodules —
`axi_adapter`, `axi_adapter_arbiter`, `lfsr_8bit` — which is the `d_ca03` shape,
already proven shimmable.

**Elaboration: `MODMISSING = 0`.** Every module in its closure resolves. The
remaining errors are in `axi_adapter.sv` and are the *unbound parameter type*
class — the same 20 errors `store_buffer` showed and the same 39 `idma_axi_write`
showed, both of which a shim resolves. **I have not yet built the probe that
proves it with types bound**, which is the one step outstanding; on the evidence
it is very likely clean, and that is a prediction rather than a result.

**Why it should discriminate**, against the failure mechanisms the results
actually show:

    parameter int unsigned NR_PORTS = 4
    input  [NR_PORTS-1:0][$bits(miss_req_t)-1:0]  miss_req_i
    output [NR_PORTS-1:0]                         bypass_gnt_o
    input  logic flush_i / output logic flush_ack_o

* **`NR_PORTS` is a real capability axis, and ignoring it is a plausible
  mistake** — a design that services one requester at a time is something a model
  writes. That is the distinction `d_ai01` failed on: its mirror control was
  *constructible but not plausible*, and this one is both. `d_nw01`'s lesson
  applies directly — a pass at the low setting is not capability evidence — so
  the scored configuration must be the high one.
* **AMO atomicity is mechanism B**, the rare one. An AMO that is not atomic
  returns *the correct value* in the uncontended case and is wrong only under a
  race — invisible on the delivered surface, exactly `d_ca03`'s T10 shape.
* **`flush_i` / `flush_ack_o` is a flush with an acknowledgement** — a second
  clause that forces the operation to be exercised rather than merely performed.
  On tonight's evidence that is the shape that *gets instrumented* rather than
  the shape that goes untested.

**The risk to check first:** overlap with `d_ca01`. Both involve refill
sequencing. They are different anchors — basejump's cache versus CVA6's miss
handler — and the distinct content here is **multi-requester arbitration and
AMO**, neither of which `d_ca01` scores. Worth confirming the scored surfaces do
not intersect before writing clauses.

### 2. `d_ca02`'s `store_buffer` — smaller, and the only one whose elaboration is proven

**The row's premise is refuted**: there is no memory-order-violation detector and
no replay anywhere in `refs/`, and CVA6 stalls conservatively rather than
detecting. The `load_store_unit` boundary is separately disqualified — it
instantiates `cva6_mmu`, which is `d_ca03`'s entire anchor, so a task there would
subsume an existing one.

**But `store_buffer.sv` alone elaborates clean and I proved it**: with `CVA6Cfg`
bound as `d_ca03` already does and the two `dcache_req_*_t` structs transcribed
from `cva6.sv:205`/`:220`, a probe module gives **0 errors, 5 warnings, 0
UNOPTFLAT, 0 MODMISSING.** It is the only remaining candidate with a measured
clean elaboration rather than a predicted one.

The task: a two-level speculative/committed queue, promotion on `commit_i`,
**`flush_i` discarding speculative while preserving committed**, and the
deliberately approximate 9-bit hazard match — where **a design comparing full
physical addresses is strictly more precise, stalls less, and is still correct**,
so the contract has to decide whether beating the reference is conforming.

Smaller than `d_ca05`, one capability axis rather than several. Its flush clause
and testbench shape are already written in `docs/NEXT_TASK_PROPOSAL.md`.

---

## The third option, if a third is wanted

**`d_nw02` retargeted.** `bsg_wormhole_router.sv` contains **zero** references to
virtual channels — the row's "separable VC allocation plus switch allocation" is
not in the artefact, and building it as written would mean writing the allocator
into the shim. What *is* there is dimension-ordered wormhole routing:
`routing_matrix_p` as `StrictXY`/`StrictX`, head/body/tail flit sequencing with
`len_width_p`, and `hold_on_valid_p`.

That is a real task and it is in the **saturated family** — routing and flow
control, which every model already passes on `d_nw01`, `d_nw03` and `d_ca04`. I
would build it third or not at all.

---

## Recommendation

**`d_ca05` first, `store_buffer` second.** That is two tasks, both with the
mechanism verified present in the artefact, one with elaboration proven and one
with `MODMISSING = 0` and a probe outstanding.

**One step before either:** build the `d_ca05` probe module, the way
`store_buffer`'s was built. It is a lint and it is the difference between *"the
closure resolves"* and *"it elaborates"* — which is precisely the gap that made
`d_ai03` look viable for a day.
