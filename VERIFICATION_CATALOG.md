# Verification Task Catalog — 23 tasks

> **PATCHED POST-PHASE-0.** `refs.lock` is the source of truth for every path,
> SHA and anchor. Two corrections of record, both superseded by
> `CC_PROMPT_2_VERIFICATION.md` where they conflict:
>
> 1. **`dsp_v04` (`boxcar_filter`) is CUT** — `model_of_record` is never valid
>    for a verification task. See the rule at the end of the DSP section.
> 2. **SymbiYosys EC is NO LONGER MANDATED per mutant.** The bar is
>    **differential simulation**: proving non-equivalence needs exactly one
>    witness, and a diverging cycle under identical stimulus on a deterministic
>    design is a complete proof. Formal is opportunistic on `ca_v01` and
>    `ca_v06` only, via `eqy` in the ORFS container, and is abandoned when it
>    does not converge. No host formal install exists or is needed.
>
> **Three design tasks converted in here from Phase 0** — `ca_d02` (`lsq`),
> `ca_d04` (`frontend_bpu`), `ca_d06` (`store_buffer_fwd`) — each shipped as a
> fat multi-file DUT under one top-level spec, the `nw_v04` / `ai_v03` shape.
> They keep their original ids and live in `domains/comp_arch/verif/`.
> That is 20 − 1 + 3 = **23**, against 18 design tasks.

Verification tasks. The model receives a **correct** DUT (renamed golden RTL)
plus a natural-language spec, and must author a self-checking testbench. It is
scored on whether its testbench passes the correct DUT (hard gate) and then on
hidden mutant kill rate.

Directory layout:
```
domains/<domain>/verif/<task_id>_<module>/
```
`<domain>` = `comp_arch` | `ai_accel` | `networking` | `dsp`

---

## Why this task type exists

In a design task, if the model writes both the design and the testbench, the
testbench can be wrong and we cannot tell. Verification tasks resolve that by
holding the DUT fixed and known-correct: the only variable is the testbench, and
mutant-kill rate measures it directly.

That measurement is only as good as the mutants. **The mutants are the real
deliverable here, not the DUT.**

---

## Comp Arch — Verification (7)

| id | module | why it's hard to verify | golden reference |
|---|---|---|---|
| `ca_v01` | `rr_arb_tree` | Long-horizon fairness, `lock` semantics under changing requests, index/data consistency | PULP `common_cells/src/rr_arb_tree.sv` |
| `ca_v02` | `id_queue` | Out-of-order occupancy by ID, per-ID FIFO ordering, exists-lookup, full/empty edges | PULP `common_cells/src/id_queue.sv` |
| `ca_v03` | `cdc_fifo_gray` | CDC: gray pointer correctness, no loss or duplication at arbitrary clock ratios, reset skew | PULP `common_cells/src/cdc_fifo_gray.sv` |
| `ca_v04` | `tlb` | Fully-associative match with ASID + global bit + superpage masking; flush-all / by-ASID / by-VA | CVA6 `core/cva6_mmu/cva6_tlb.sv` |
| `ca_v05` | `scoreboard` | Issue/commit bookkeeping, WAW and RAW dependency tracking, flush, full-stall | CVA6 `core/scoreboard.sv` |
| `ca_v06` | `plru_way_select` | Tree-PLRU update ordering, way-locking, invalid-way-first override — tiny DUT, deep state-order bugs | basejump_stl `bsg_misc/bsg_lru_pseudo_tree_{decode,encode,backup}.sv` |
| `ca_v07` | `serdiv` | Variable latency, signed/unsigned, div-by-zero, INT_MIN/−1 overflow, early termination, back-to-back issue | CVA6 `core/serdiv.sv` — lints clean standalone |
| `ca_d02` | `lsq` | **Converted from design.** Age-ordered entries, store-to-load forwarding, blocking on unresolved older stores, squash on flush | CVA6 `core/load_store_unit.sv` + `store_buffer.sv` (ship whole) |
| `ca_d04` | `frontend_bpu` | **Converted from design.** BHT + BTB + RAS, speculative push/pop, mispredict repair | CVA6 `core/frontend/{bht,btb,ras}.sv` + `ariane_pkg` (ship whole) |
| `ca_d06` | `store_buffer_fwd` | **Converted from design.** Byte-granular load forwarding, partial-overlap stall, drain ordering | CVA6 `core/store_buffer.sv` (ship whole) |

**`ca_v03` is the only two-clock task.** State that explicitly in the task, and
confirm both simulator invocations handle two domains rather than assuming it —
if the harness cannot reach the same verdict under Icarus as under Verilator,
record which one the task is pinned to. Mutants should include a gray-code bug
that only manifests at a specific clock ratio.

---

## AI Acceleration — Verification (4)

| id | module | why it's hard to verify | golden reference |
|---|---|---|---|
| `ai_v01` | `idma_backend` | Descriptor-driven DMA: unaligned src/dst, 2D strides, mid-transfer backpressure, completion ordering | PULP idma — **generated**, see note. Module is `idma_backend_rw_axi` |
| `ai_v02` | `hwpe_stream_fabric` | Streamer split/merge/fifo handshake: no data loss across width changes, valid/ready never deadlock | PULP `hwpe-stream/rtl/*` |
| `ai_v03` | `redmule_gemm_ctrl` | FP16 GEMM tiling control: loop bounds, edge tiles, accumulator reuse across tiles | PULP `redmule` (`redmule_ctrl.sv` + scheduler) |
| `ai_v04` | `nvdla_sdp_requant` | Accumulate → bias → scale → requant → clamp pipeline; per-channel parameters, saturation boundaries | NVDLA `nv_small` SDP |

`ai_v03` and `ai_v04` are multi-file assemblies. Ship each as one DUT with one
top-level spec rather than splitting into sub-module tasks — a spec for a
fragment of a GEMM controller is not a task anyone would recognise as real work.

**`ai_v01` generation note (Phase 0).** idma has **no checked-in
`idma_backend.sv`** — the backend is mako-templated. Generation was verified to
run **fully offline** and was performed during the network window with
`mako==1.4.1`, `pyyaml==6.0.3`, Python 3.14.4, in a venv outside the repo.
Regeneration from the vendored generator reproduces the file **byte-identically**
(sha256 confirmed), so generation is deterministic and the generator — not just
the output — is the artifact of record. Generator, templates and `src/db/*.yml`
inputs are all vendored. The top-level module is **`idma_backend_rw_axi`**, not
`idma_backend`. It does **not** elaborate standalone: its req/rsp are `type`
parameters, so a concrete-type wrapper is required before the DUT can be shipped.
That wrapper is Part 2 work and is a known open item.

---

## Networking — Verification (6)

| id | module | why it's hard to verify | golden reference |
|---|---|---|---|
| `nw_v01` | `axi_lite_xbar` | Address decode, default slave / decode error, concurrent masters, no response interleaving | PULP `axi/src/axi_lite_xbar.sv` |
| `nw_v02` | `axi_id_remap` | ID table pressure, stall when no free remapped ID, per-ID ordering guarantees | PULP `axi/src/axi_id_remap.sv` |
| `nw_v03` | `axi_atop_filter` | Atomic-op filtering: correctly synthesised B/R responses, no protocol violation on filtered ATOPs | PULP `axi/src/axi_atop_filter.sv` |
| `nw_v04` | `arp` | Request/reply, cache insert and evict, timeout and retry, gratuitous ARP, broadcast handling | Forencich `arp{,_cache,_eth_rx,_eth_tx}.v` |
| `nw_v05` | `axis_arb_mux` | Frame atomicity (no mid-frame interleaving), arbitration fairness, `tlast` under backpressure | Forencich `verilog-axis/rtl/axis_arb_mux.v` |
| `nw_v06` | `eth_mac_1g_rx` | Preamble/SFD alignment, FCS check, runt and oversize frames, inter-packet gap, error propagation | **Re-anchored:** Forencich `verilog-ethernet/rtl/axis_gmii_rx.v` (+ `lfsr.v`). `eth_mac_1g_rx.v` does not exist |

`nw_v04` has multiple sub-modules — ship the whole ARP assembly as one DUT.

---

## DSP — Verification (3)

| id | module | why it's hard to verify | golden reference |
|---|---|---|---|
| `dsp_v01` | `fpnew_fma` | All five IEEE rounding modes, subnormals, NaN payload propagation, Inf−Inf, signed zero, tininess-after-rounding | PULP `cvfpu/src/fpnew_fma.sv` |
| `dsp_v02` | `fpnew_divsqrt` | Variable latency, sqrt of negative, div-by-zero, exact-result cases, back-to-back issue | PULP `cvfpu/src/fpnew_divsqrt_multi.sv` |
| `dsp_v03` | `fp_int_cast` | Saturation vs wraparound, RTZ vs RNE, out-of-range, NaN→int | PULP `cvfpu/src/fpnew_cast_multi.sv` |

**`dsp_v01`–`dsp_v03`** need a bit-exact software reference for expected results.
Write it locally (Python `struct` / integer bit-manipulation, or a locally-built
SoftFloat), generate vectors offline, commit them, and have the TB read them via
`$readmemh` so the TB stays in the portable two-simulator subset. Include
subnormal, NaN-payload, and signed-zero vectors — most submitted testbenches
will not.

**`dsp_v04` (`boxcar_filter`) was cut**, and the rule behind the cut applies to
every task here.

`model_of_record` means no vendored upstream RTL. A verification task ships the
DUT, so no vendored RTL means *we* would author the shipped DUT — which is the
precise trust problem this whole task type exists to eliminate. There is no
version of `dsp_v04` that is worth having.

**So: `model_of_record` is valid for a design task and never for a verification
task.** Design tasks are unaffected by an unvendorable source because their
oracle is a Python model plus committed vectors and nothing is shipped —
`dsp_d02` still uses ZipCPU `dspfilters` exactly this way, and it stays in the
manifest for that reason. If the Phase 0 licence gate downgrades any other
verification task to `model_of_record`, that task is cut too; Phase 0 reports the
cut and continues rather than stopping.

---

## Totals and sizing

**POST-PHASE-0 (authoritative).**

| domain | tasks | change |
|---|---|---|
| Comp Arch | 10 | was 7 — `ca_d02`, `ca_d04`, `ca_d06` converted in |
| AI Accel | 4 | unchanged |
| Networking | 6 | unchanged (`nw_v06` re-anchored to `axis_gmii_rx.v`) |
| DSP | 3 | unchanged — **`dsp_v02` SURVIVES the licence gate** |
| **Total** | **23** | was 20 (21 − `dsp_v04` + 3 conversions) |

`dsp_v02` was at risk of being cut with `dsp_v04`: `fpnew_divsqrt_multi`
instantiates `div_sqrt_top_mvp`, which is not in cvfpu. It resolves to
`pulp-platform/fpu_div_sqrt_mvp` (SHL-0.51), now vendored, and cvfpu's
`vendor/opene906` subtree is **Apache-2.0**, not GPL-family. No verification
task is cut by licence.

This count moves in both directions during Phase 0. Design tasks whose upstream
reference cannot be bridged by a thin port shim **convert to verification tasks**
rather than being downgraded — `ca_d02` and `ca_d04` are expected to, `ca_d06`
may. A converted task arrives here as a fat multi-file DUT shipped whole under
one top-level spec, which is the `nw_v04` / `ai_v03` shape and needs no special
handling. See `DESIGN_CATALOG.md` § Shim feasibility.

Submitted testbenches run **400–1200 lines**, median ~600, in house style.

## Build order

1. `ca_v01` `rr_arb_tree` — smallest DUT; validates the decontamination → EC →
   mutant → scoring pipeline end to end before anything expensive
2. `ca_v06` `plru_way_select` — second-smallest, confirms EC converges on a
   sequential design
3. `nw_v05` `axis_arb_mux` — first protocol-level task
4. Then the rest: Comp Arch, Networking, AI Accel, DSP

Do the two smallest first on purpose. Standing up EC on a simple module is far
cheaper than retrofitting it onto `idma_backend`.

## Mutant diversity requirement

Each task carries 5–7 mutants, one bug each, distinct failure classes:

| class | example |
|---|---|
| boundary | off-by-one on wrap, full/empty, 4 KiB split, last beat |
| concurrency | simultaneous events on the same entry/set/ID mishandled |
| control flow | inverted condition, missing FSM transition, wrong priority |
| staleness | forwards old data, one-cycle-late update |
| reset/flush | one piece of state not cleared |
| protocol | handshake violation, `tlast`/`tkeep` wrong under backpressure |
| arithmetic | wrong rounding mode, saturation vs wrap, sign handling |
| liveness | rare starvation or deadlock rather than a wrong value |

At least one **hard** mutant per task, manifesting only under a specific
concurrent condition. That is the mutant separating a good testbench from a
superficial one.

~~Every mutant must be **EC-confirmed non-equivalent** to the golden DUT via
SymbiYosys.~~ **SUPERSEDED.** Every mutant must be confirmed non-equivalent by
**differential simulation**: run reference and mutant under identical stimulus
and record a diverging cycle. On a deterministic design one witness is a complete
proof of non-equivalence, which is all that is needed here. Formal via `eqy` is
opportunistic on `ca_v01` and `ca_v06` only — cheap there — and is abandoned when
it does not converge. It runs in the ORFS container (`sby`/`eqy` v0.67,
`yosys-abc`, `read_slang`); there is no host formal install and none is needed.

A mutant that is functionally equivalent is still not a bug and still silently
caps the achievable kill rate — that part stands.

## Reference-source policy

Preference order, to limit pretraining contamination: basejump_stl → PULP →
Forencich → NVDLA → ZipCPU → CVA6. Ibex and OpenTitan excluded.

Reference paths above are best identification and are **not verified**. Phase 0
(owned by the design agent) confirms each exists, elaborates, and carries the
licence claimed, and stops rather than substituting.
