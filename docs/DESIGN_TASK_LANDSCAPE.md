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
| **`d_ai04`** sdp_requant_pipeline | NVDLA `SDP_CORE_Y_cvt`, 2,721 lines | **VIABLE — cleanest anchor audited** |
| `d_ai02` gemm_tiler | NVDLA `cacc` 30k / `cdma` 103k lines | needs its own audit |

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

**`d_ai02`, `d_ai04` — RETRACTED. THE ANCHOR EXISTS AND I CHECKED THE WRONG PATH.**

I wrote that `refs/nvdla` contains zero RTL files. **The directory is
`refs/nvdla_hw`, and it contains 107 of them**, including all three modules the
two rows name: `NV_NVDLA_cacc.v`, `NV_NVDLA_cdma.v`, `NV_NVDLA_sdp.v`.

The mechanism of the error is worth more than the correction. I ran

    find refs/nvdla -name "*.sv" -o -name "*.v" | wc -l    2>/dev/null

`find` on a path that does not exist prints an error and no results. **I
suppressed the error and read the resulting zero as a measurement.** A missing
directory and an empty directory produced the same output, and I reported the one
as the other — then declared two catalog rows dead on it.

That is the seventh instance of this week's error class and the only one that
reached a conclusion someone else acted on. It is also the sharpest: the other
six were the wrong population, the wrong timing model or the wrong signal
identity, and **this one is a suppressed error read as data** — the same shape as
every "clean because nothing looked" finding in `FINDINGS.md`, committed by the
person cataloguing them. `2>/dev/null` on a discovery command is that shape
exactly.

See the re-audit below: `d_ai04` is now the strongest candidate in the set.

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


---

# RE-AUDIT: `d_ai04` IS THE STRONGEST CANDIDATE IN THE SET

## The boundary, and it is the cleanest anchor audited tonight

    refs/nvdla_hw/vmod/nvdla/sdp/NV_NVDLA_SDP_CORE_Y_cvt.v

    verilator --lint-only --top-module NV_NVDLA_SDP_CORE_Y_cvt
      errors 0    MODMISSING 0    warnings 3

**Zero external dependencies.** All eighteen modules it needs are in that one
file; the top is at line 2661. No package to import, no struct types to
transcribe, no shim probe required to find out. Compare: `store_buffer` needed a
probe with two structs copied out of `cva6.sv`, and `d_ca05` still needs one.

## The interface IS the task

    input  [63:0]  chn_in_rsc_z          input channel data
    input  [31:0]  cfg_offset_rsc_z      BIAS
    input  [15:0]  cfg_scale_rsc_z       SCALE
    input  [5:0]   cfg_truncate_rsc_z    SHIFT
    input  [1:0]   cfg_precision_rsc_z   PRECISION MODE
    input          cfg_nan_to_zero_rsc_z
    input          cfg_bypass_rsc_z
    output [127:0] chn_out_rsc_z

`(x + offset) * scale >> truncate`, saturated per precision mode — which is the
row's *"accumulate → bias → scale → requant → clamp"* almost word for word. **The
row is right about this artefact**, which makes it the first one that has been.

## Why it should discriminate, against the mechanisms the results show

* **Mechanism A, four times over.** Offset, scale, truncate and precision all
  interact, and the **saturation bound depends on the precision mode**. Order of
  operations, rounding on the truncate, and where saturation is applied are each
  a derived quantity that is invisible except at boundaries. That is `d_dsp02`
  and `d_dsp03`'s family, and both discriminate.
* **`cfg_precision_rsc_z` is a capability axis with a plausible mistake behind
  it** — implement one mode, alias the others, pass at that mode. Exactly
  `nc_b_two_lanes` on `d_dsp03`, which caught `chat` at 0/2.
* **`cfg_nan_to_zero` is a conditional clause with a design-controlled
  antecedent** — the F86 family, and a control for it is plausible rather than
  merely constructible.
* **64 in, 128 out** — the width change means per-element unpacking, and an
  off-by-one there is invisible on aligned, uniform data.

## The one real risk, stated plainly

**It is Catapult HLS output.** `mgc_in_wire_wait_v1`, `mgc_shift_r_v4` and the
rest are Mentor library modules, and the 2,721 lines are machine-generated.

**The source is not readable as a specification.** That is not disqualifying here
— this repository writes contracts from *measured* behaviour and audits the
anchor before trusting it (F54, and `d_ai01`'s four probes). But it makes the
step-0 conformance audit mandatory rather than advisable: **every clause must
come from a probe, and none from reading the RTL.** If the anchor's rounding or
saturation turns out not to match any stated convention, the task dies the way
`d_dsp01` did — and that must be found in step 0.

## Also never enumerated, and worth an audit before the next choice

    ne16               21 RTL files      PULP neural engine -- ai_accel domain
    hwpe-ctrl          11
    verilog-axis        8
    fpu_div_sqrt_mvp    8

I listed `refs/` for the first time in this session while finding the error
above. These four were never examined for any row.

## Revised recommendation

1. **`d_ai04`** — cleanest anchor, the row's premise is accurate, four
   discriminating mechanisms, and no shim scaffolding needed to start.
2. **`d_ca05`** — mechanism verified present, `MODMISSING 0`, probe outstanding.
3. `store_buffer` — smaller, elaboration proven, scope already written.

`d_ai02` needs its own audit: `cacc` is 30k lines over 13 files and `cdma` 103k
over 25, so the boundary question there is real and unanswered.