# Design tasks with no golden / open-source RTL model

Which design-from-spec tasks are **not** anchored on externally-authored RTL,
why, and what stands in for it. Derived from `refs.lock` (authoritative) and
`DESIGN_CATALOG.md` § Oracle classes, both post-Phase-0.

**Why this file exists.** For these tasks the sentence *"the testbench was
proven correct against known-correct external RTL"* is **not available and must
never be written**. That is the benchmark's central evidence claim, and it does
not hold here. Anyone reading a result from one of these tasks needs to know
that up front rather than discovering it in a per-task `NOTES.md`.

**PPA / ORFS status.** Full ORFS builds are **deferred** for every task in this
file. Clock period, area and power baselines are determined later, once the
reference implementations are settled. `ai_d01` already carries a real ORFS
baseline (it was built before this policy) — see its `NOTES.md`; treat it as
early data, not as a precedent that the others must match.

---

## Summary

| oracle class | design tasks | external RTL runs? |
|---|---|---|
| **A** — external RTL oracle | 10 | yes, vendored + shimmed |
| **B** — local model of record | **7** | **no** |
| **C** — cross-check only | **1** | no (consulted once, never vendored) |
| total | 18 | |

**8 of 18 design tasks have no external RTL oracle.**

---

## Class B — local model of record (7)

No outside RTL ever runs. The oracle is a locally-written model plus committed
vectors. The only RTL available to exercise the checker is RTL this project
wrote, so mutation testing carries the sharpness argument **alone** — the mutant
set has to be better here, not worse.

| task | module | oracle | why there is no external RTL |
|---|---|---|---|
| `ca_d08` | `tiny_core` | Python RV32I ISS + committed retire traces | Scoped subset core; SERV / darkriscv are trace cross-checks only, and are structurally unusable as a design reference (SERV is bit-serial) |
| `ai_d01` | `int8_requant` | Python model of the documented TFLite/gemmlowp requantisation | **DONE.** NVDLA SDP is a structural cross-check only; its rounding is configurable and not guaranteed to match the specified rule |
| `ai_d02` | `pe_array_os` | Python model of the 4×4 output-stationary INT8 tile | **Re-anchored in Phase 0.** Both catalog anchors rejected: PULP `ne16` is binary-conv (`ne16_binconv_*`), not INT8 output-stationary, and fails to elaborate; NVDLA CMAC carries 297 fp16/Winograd references and needs NVDLA's build flow. Neither admits a thin shim |
| `ai_d03` | `online_softmax` | Python bit-exact fixed-point model | No open-source flash-attention-style streaming softmax at this scope |
| `dsp_d01` | `cordic_rot` | Python CORDIC model | ZipCPU `cordic` is **GPL-3.0** — consulted in scratch, never vendored |
| `dsp_d02` | `fir_polyphase_decim` | Python polyphase FIR model | ZipCPU `dspfilters` is **LGPL** — consulted in scratch, never vendored |
| `dsp_d03` | `cic_decimator` | Python bit-exact integer CIC model | No suitable permissively-licensed reference |

### `dsp_d02` is the sharpest case

It is model-of-record **and** on the mandatory second-source list, so *both*
implementations exercising its checker are locally authored. The task stays, but
it must never be described as externally validated.

### Licence-driven vs. semantics-driven

Worth keeping distinct, because only the first could be fixed by a licence change:

* **licence** forced `dsp_d01`, `dsp_d02` out of the tree (GPL / LGPL).
* **semantics** forced `ai_d02` out — the references exist and are permissively
  licensed, they simply do not implement the module the task describes.
* **no candidate exists** for `ca_d08`, `ai_d01`, `ai_d03`, `dsp_d03`.

---

## Class C — cross-check only (1)

| task | module | oracle | why |
|---|---|---|---|
| `ca_d07` | `ecc_secded_wrapper` | Python Hsiao parity-matrix generator | OpenTitan is excluded project-wide on contamination grounds; `prim_secded` is consulted **once** to confirm the generated matrix matches a known-good one, and is never vendored |

Per `DESIGN_CATALOG.md`: if that cross-check cannot be done cleanly, **drop
`ca_d07`** rather than ship a contaminated task. Nothing depends on it — the cut
would leave 17 design tasks and 4 in Comp Arch.

---

## Class A for contrast — these 10 DO have external RTL (10)

Listed so the boundary is unambiguous.

| task | module | vendored anchor |
|---|---|---|
| `ca_d01` | `l1_dcache` | basejump_stl `bsg_cache/bsg_cache.sv` |
| `ca_d03` | `mshr_file` | basejump_stl `bsg_cache_non_blocking_mhu.sv` + `_miss_fifo.sv` |
| `ca_d05` | `regfile_multiport_bypass` | CVA6 `ariane_regfile_ff.sv` (module `ariane_regfile`) |
| `ai_d04` | `tile_double_buffer` | hwpe-stream `rtl/fifo/hwpe_stream_fifo.sv` |
| `nw_d01` | `axis_width_adapter` | verilog-axis `rtl/axis_adapter.v` |
| `nw_d02` | `axi_burst_splitter` | pulp axi `src/axi_burst_splitter.sv` (spec restated to beat-splitting) |
| `nw_d03` | `crc32_eth` | verilog-ethernet `rtl/lfsr.v` (CRC32 FCS parameterisation) |
| `nw_d04` | `mac_pause_ctrl` | verilog-ethernet `mac_ctrl_{tx,rx}.v` + `mac_pause_ctrl_tx.v` |
| `nw_d05` | `wormhole_flow_ctrl` | basejump_stl `bsg_wormhole_router*.sv` (spec restated to ready/valid/yumi) |
| `dsp_d04` | `bf16_fma` | cvfpu `src/fpnew_fma.sv` |

Note `nw_d02` and `nw_d05` are Class A but their **specs were restated in Phase
0** to match what the reference actually does. They keep the full external-RTL
guarantee; only the task description moved.

---

## Rule of record

`model_of_record` is valid for a **design** task and never for a **verification**
task. A verification task ships the DUT, so no vendored RTL means we would
author the shipped DUT — the precise trust problem verification exists to
eliminate. `dsp_v04` was cut on exactly these grounds. See
`VERIFICATION_CATALOG.md`.
