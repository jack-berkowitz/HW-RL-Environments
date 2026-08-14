# Design Task Catalog — 21 tasks

Design-from-spec tasks. The model receives a port-only `_iface.sv` with the
contract in header comments, and nothing else. No testbench, no reference, no
mutants. It is scored on functional correctness (pass/fail) and PPA.

Directory layout:
```
domains/<domain>/design/<task_id>_<module>/
```
`<domain>` = `comp_arch` | `ai_accel` | `networking` | `dsp`

---

## Comp Arch — Design (8)

| id | module | ~lines | what it is | golden reference |
|---|---|---|---|---|
| `ca_d01` | `l1_dcache` | 350–500 | Write-back / write-allocate blocking L1 D-cache: tag+data arrays, victim selection, dirty writeback, single outstanding miss | basejump_stl `bsg_cache/bsg_cache.v` |
| `ca_d02` | `lsq` | 300–450 | Load/store queue: age-ordered entries, store-to-load forwarding, blocking on unresolved older stores, squash on flush | CVA6 `core/load_store_unit.sv` + `store_buffer.sv` |
| `ca_d03` | `mshr_file` | 250–400 | Miss-status holding registers: primary allocate, **secondary-miss merge** onto an in-flight line, per-word ready, fill broadcast, full/stall | basejump_stl `bsg_cache_non_blocking_mhu` + `_miss_fifo` |
| `ca_d04` | `frontend_bpu` | 200–350 | BHT (bimodal 2-bit) + BTB + RAS with speculative push/pop and mispredict repair | CVA6 `core/frontend/{bht,btb,ras}.sv` |
| `ca_d05` | `regfile_multiport_bypass` | 60–120 | 6R/3W register file, same-cycle write→read bypass, x0 hardwiring, write-port conflict rules | CVA6 `core/ariane_regfile_ff.sv`; basejump `bsg_mem_multiport` |
| `ca_d06` | `store_buffer_fwd` | 150–250 | Post-commit store buffer: byte-granular load forwarding, partial-overlap stall, drain ordering | CVA6 `core/store_buffer.sv` |
| `ca_d07` | `ecc_secded_wrapper` | 80–150 | SECDED (Hsiao) encode/decode over an SRAM: single-bit correct, double-bit detect, error counters, scrub port | OpenTitan `prim_secded_*` — **contamination-flagged**, see note |
| `ca_d08` | `tiny_core` | 250–350 | Single-issue in-order RV32I subset core — the reference simple example | See dedicated section below |

**`ca_d07` note.** OpenTitan is otherwise excluded on contamination grounds, and
this is the one exception. Mitigation: generate the Hsiao parity matrix from a
locally-written Python model, make that model the artifact of record, and use
`prim_secded` only as a cross-check that the matrix matches a known-good one.
Rename aggressively in the `_iface.sv`. If the cross-check can't be done
cleanly, drop this task rather than shipping a contaminated one. Nothing else
depends on `ca_d07`: if it is dropped the cut is 20 tasks and Comp Arch is 7.
Decide that in Phase 0, not after the spec is written.

### `ca_d08` `tiny_core` — scope and oracle

Deliberately the smallest real thing in the benchmark. Scope it hard:

- **Instructions:** `lui`, `auipc`, `addi`, `add`, `sub`, `and`, `or`, `xor`,
  `slt`, `sltu`, `sll`, `srl`, `sra`, `lw`, `sw`, `beq`, `bne`, `blt`, `bge`,
  `jal`, `jalr`
- **Excluded:** CSRs, interrupts, exceptions, misaligned access, `fence`,
  multiply/divide, byte/halfword memory ops
- Single memory port, separate instruction fetch port, no caches
- Pipeline depth is the model's choice — the spec must not constrain it

**Retire interface — the exception to "don't constrain the microarchitecture".**
A retire-trace oracle only works if the DUT exposes what it retired, so the
commit interface is part of the contract and the `_iface.sv` must pin it down:
port names and widths, at most one retire per cycle, what `rd == x0` and a store
retire report, and how the testbench knows the program has ended (retire count,
or an architecturally-defined halt). This is the one place the spec dictates
observability. Everything behind that interface — depth, forwarding, whether
branches are predicted — stays free.

The comparison is **order-based, never cycle-stamped**: the Nth retire must
match the Nth trace entry, at whatever cycle it arrives. A cycle-stamped compare
is the fastest way to fail a correct design with a different pipeline depth, and
it will show up as the second-source implementation failing in Step 5.

**Oracle.** Do *not* stand up ISS co-simulation for this. At this scope a
committed golden trace is sufficient and far cheaper:

1. Write a Python ISS for exactly this instruction subset, from the ISA spec.
2. Generate a fixed program set: one directed program per instruction, plus
   hazard-targeted programs (load-use, back-to-back dependent ALU ops, taken and
   not-taken branches, `jalr` to a computed target), plus randomly generated
   programs from a constrained generator.
3. Emit, per retire: PC, destination register and value, and store address/data.
4. The testbench replays each program from `$readmemh` and compares the DUT's
   retire stream against the committed trace.

This keeps the TB in the portable subset (see § Testbench subset), keeps the
whole task offline and deterministic, and avoids the state-space explosion that
makes ISS co-sim necessary on a full core. Commit the ISS and the program generator alongside the
traces so the vectors are reproducible.

For cross-validation of the ISS itself, `SERV` or `darkriscv` are the acceptable
low-contamination references. `picorv32` is excluded — too well known. Neither
is a good structural template (SERV is bit-serial), so use them to confirm the
traces, not as a design reference.

---

## AI Acceleration — Design (4)

| id | module | ~lines | what it is | golden reference |
|---|---|---|---|---|
| `ai_d01` | `int8_requant` | 80–150 | INT32 → INT8 requantization: per-channel fixed-point multiplier + right shift, round-half-away-from-zero, clamp to [-128,127], zero-point handling | Locally-written Python model of the TFLite `MultiplyByQuantizedMultiplier` algorithm; cross-check NVDLA SDP |
| `ai_d02` | `pe_array_os` | 150–250 | 4×4 output-stationary INT8 MAC tile: weight load phase, streaming activations, per-PE accumulator, drain sequence | PULP `ne16` MAC array; NVDLA `nv_small` CMAC |
| `ai_d03` | `online_softmax` | 150–250 | Streaming softmax with running max and rescaled denominator (flash-attention style), fixed-point, single pass per row | Locally-written bit-exact Python model |
| `ai_d04` | `tile_double_buffer` | 150–250 | Ping-pong activation/weight tile buffer: credit-based producer/consumer handoff, descriptor-driven tile sizes, no tearing across swap | PULP `hwpe-stream` buffer / `hwpe_stream_fifo.sv` |

`ai_d01` is the most-written block in quantized inference hardware and small
enough to iterate on cheaply — **build it first** to validate the category.
`ai_d03` is the most current: it is the inner loop of every attention kernel.

For `ai_d01` and `ai_d03` the Python model is the artifact of record. Write it
from the documented algorithm, commit the generator, and use the RTL references
only to sanity-check the vectors.

---

## Networking — Design (5)

| id | module | ~lines | what it is | golden reference |
|---|---|---|---|---|
| `nw_d01` | `axis_width_adapter` | 150–250 | AXI-Stream up/down width conversion, `tkeep`/`tlast`/`tuser`, no bubble under sustained backpressure | Forencich `verilog-axis/rtl/axis_adapter.v` |
| `nw_d02` | `axi_burst_splitter` | 200–300 | Splits AXI4 bursts at 4 KiB boundaries, preserves ID ordering, W/B channel bookkeeping | PULP `axi/src/axi_burst_splitter.sv` |
| `nw_d03` | `crc32_eth` | 80–150 | Parallel Ethernet FCS-32, parameterisable datapath width, partial (byte-enabled) final beat, RX residue check | Forencich `verilog-ethernet/rtl/lfsr.v` (CRC config) |
| `nw_d04` | `mac_pause_ctrl` | 200–350 | 802.3x PAUSE / 802.1Qbb PFC: quanta timers, per-priority state, refresh threshold, tx gating | Forencich `mac_ctrl_{tx,rx}.v` + `mac_pause_ctrl_tx.v` |
| `nw_d05` | `wormhole_flow_ctrl` | 150–250 | Credit-based input-port flow control: per-VC credit counters, head/body/tail flit tracking, no credit overrun, no grant to a creditless VC | basejump_stl `bsg_noc/bsg_wormhole_router*` |

**`nw_d02` semantic risk.** PULP's `axi_burst_splitter` is believed to split
bursts into **single beats**, not at 4 KiB boundaries — that is what makes it
useful in front of a Lite-ish slave. If that is what Phase 0 finds, it is not a
reference for the task as described here and there is no behaviour-free shim.
Resolve it in Phase 0 while the network is still up: either restate `nw_d02` as
beat-splitting and keep the reference, or keep the 4 KiB spec and downgrade the
task to a local model of record. Do not discover this in Phase 1.

---

## DSP — Design (4)

| id | module | ~lines | what it is | golden reference |
|---|---|---|---|---|
| `dsp_d01` | `cordic_rot` | 100–180 | Pipelined CORDIC rotation mode, quadrant pre-rotation, documented gain handling, TB-enforced error bound | ZipCPU `cordic` — **GPL, model-of-record** |
| `dsp_d02` | `fir_polyphase_decim` | 100–180 | Symmetric-coefficient polyphase decimating FIR, one MAC per phase, rounding + saturation on output | ZipCPU `dspfilters/rtl/subfildown.v` — **GPL, model-of-record** |
| `dsp_d03` | `cic_decimator` | 80–150 | 3-stage CIC decimator, runtime rate change, correct integrator/comb register widths (no silent overflow) | Locally-written bit-exact Python integer model |
| `dsp_d04` | `bf16_fma` | 200–350 | bf16 × bf16 + fp32 accumulate, RNE rounding, subnormal and NaN/Inf propagation per IEEE-754 | PULP `cvfpu/src/fpnew_fma.sv` |

**GPL / model-of-record** means: the upstream RTL is **not** vendored into the
repo. It may be consulted in a scratch directory outside the repo to validate a
locally-written Python golden model, and only that model is committed. See
Phase 0 in the build prompt.

---

## Oracle classes

Not every task has an external RTL oracle, and the ones that don't carry a
weaker guarantee. Which is which, stated up front, so "prove the TB passes
correct RTL" means something specific per task.

**Class A — external RTL oracle (14).** `ca_d01`–`ca_d06`, `ai_d02`, `ai_d04`,
`nw_d01`–`nw_d05`, `dsp_d04`. Vendored upstream RTL behind a port shim is what
the testbench is proven against. This is the strong case, and the one the
methodology's claim to rigor actually rests on: the TB passed RTL nobody on this
project wrote.

**Class B — local model of record (6).** `ca_d08`, `ai_d01`, `ai_d03`,
`dsp_d01`, `dsp_d02`, `dsp_d03`. No outside RTL ever runs. The oracle is a
Python model written from the published algorithm or ISA, plus committed
vectors. The only RTL available to prove the TB is RTL this project wrote, so
*"the testbench passes known-correct external RTL" is not available for these
tasks* and must not be claimed. The substitute guarantee is three things, and
each must be recorded in `NOTES.md`:

1. the model is derived from the documented algorithm, not transcribed from the
   reference implementation;
2. the model, its generator, and the vectors are committed, so the oracle is
   reproducible and auditable by a reader who distrusts it;
3. mutation testing carries the sharpness argument by itself — there is no
   second signal, so the mutant set has to be better here, not worse.

`dsp_d02` is the sharpest case: model of record *and* on the mandatory
second-source list, so both implementations exercising the TB are locally
authored. Keep the task; do not describe it as externally validated.

**Class C — cross-check only (1).** `ca_d07`. Upstream is consulted to confirm a
locally-generated artifact matches a known-good one, and is never vendored.

## Shim feasibility

Step 2 of the build prompt restricts `ref/<module>_ref.sv` to combinational
renaming and struct pack/unpack. That holds for a leaf module. It is not
obviously true for the CVA6 core internals (`ca_d02`, `ca_d04`, `ca_d06`) or for
`bsg_cache` (`ca_d01`): those speak project-specific packages and structs and
expect neighbouring blocks — MMU, dcache, miss handler — on the far side of
their ports.

The escape hatch in Step 2 — "if you cannot bridge the two without adding logic,
the interface is wrong: revise the interface" — is correct for a leaf and wrong
here. Reshaping our `_iface.sv` to fit CVA6's internal boundary bakes CVA6's
free choices into the spec, which is exactly what § Second-source requirement
exists to prevent.

**Shim feasibility is therefore a Phase 0 determination**, made per task while
the network is still up. A thin shim is combinational renaming and struct
pack/unpack; needing behaviour to bridge means the shim has failed. Outcomes:

- **thin shim exists** → Class A, proceed as written;
- **shim fails, licence permits shipping the RTL** → **convert the task to a
  verification task.** This is the preferred fallback. Verification ships a fat
  multi-file DUT whole under one top-level spec — `nw_v04` and `ai_v03` already
  work that way — so the module that was too coupled to shim is exactly the shape
  verification wants, and the external-authorship guarantee survives intact. The
  task moves to the verification agent's queue;
- **shim fails, licence forbids shipping** (GPL / model-of-record) → keep it as a
  design task at Class B. After the `dsp_v04` cut this is the only remaining path
  to Class B by downgrade.

`ca_d02` and `ca_d04` are expected to convert. `ca_d06` is genuinely uncertain.
`ca_v07` (`serdiv`) is self-contained and should need none of this.

Discovering any of it in Phase 1 is the expensive failure, because fixing it
needs the network back.

## Testbench subset

"Synthesizable subset" is house shorthand and is not literally what is meant —
the existing testbenches use `string`, `$sformatf` and `$display`, none of which
synthesize. The real rule is a **portable two-simulator subset**: no classes, no
constrained randomization, no UVM, no `forever` loops, and the harness must
compile and reach the same verdict under both Verilator and Icarus. Anything
that runs under only one of the two is a harness that will silently stop being
run.

---

## Totals and sizing

| domain | tasks |
|---|---|
| Comp Arch | 8 |
| AI Accel | 4 |
| Networking | 5 |
| DSP | 4 |
| **Total** | **21** |

20 if `ca_d07` is dropped in Phase 0 on contamination grounds.

Solution size: median ~200 lines of synthesizable SV, mean ~215, range 60–500.

Line count is a weak difficulty proxy — `ca_d03` is ~300 lines and the hardest
task here; `nw_d04` is ~300 lines and mostly bookkeeping. Use it for context and
iteration budgeting, not for difficulty tiers.

**These numbers describe the solution, not the work.** The testbench is the
deliverable that takes the time: the existing house harnesses run 379–1039 lines
each, and every task here also needs a shim, 5–7 mutants, an ORFS baseline, and
for seven of them a second-source implementation. Budget against the testbench
column, not the solution column, and re-scope after the first three tasks rather
than committing to 21 up front.

## Build order

1. `ai_d01` `int8_requant` — smallest, validates the new category end to end
2. `ca_d08` `tiny_core` — the demo module; get it working early

**Checkpoint. Stop here.** Two working tasks are enough to build the spec loader
and run one frontier model end to end. That answers the two questions that get
expensive to answer later: does PPA plateau on simple blocks with real data, and
do models sail straight through `int8_requant`? Both bear on difficulty
calibration for the remaining nineteen, and both are cheap to act on now and
costly after the catalog is built out.

3. `ca_d03` `mshr_file` — isolates the live `ncache` secondary-miss bug
4. Remaining Comp Arch, then AI Accel, then Networking, then DSP

## Reference-source policy

Preference order, chosen to limit pretraining contamination:
basejump_stl → PULP → Forencich → NVDLA → ZipCPU → CVA6 → local Python model.
Ibex and OpenTitan are excluded, with the single flagged `ca_d07` exception.

Reference paths above are best identification and are **not verified**. Phase 0
confirms four things per reference — it exists, it elaborates with its
dependencies listed, it carries the licence claimed here, and **it does what the
"what it is" column says** — and stops rather than substituting. The fourth is
the one that gets skipped: a file that exists and elaborates can still implement
different behaviour from the task it is supposed to anchor (see `nw_d02`), and
that only becomes cheap to fix while the network is up.

## Second-source requirement

Writing a testbench against one specific implementation bakes in that
implementation's free choices (latency, replacement order, arbitration, last-ULP
rounding). A correct alternative design then fails, and the benchmark measures
"did you rediscover CVA6" rather than "is your design correct."

Mandatory second-source check — an independently written, structurally different
correct implementation must also pass — on: `ca_d01`, `ca_d02`, `ca_d03`,
`ca_d08`, `nw_d01`, `dsp_d02`, `ai_d02`.

**The second source is a falsifier, not an oracle.** `tb/<module>_alt_ref.sv` is
written by us, on purpose, to try to break the testbench by making different
legal choices. It never grades a submission and it is never the thing a spec is
validated against, so it does not contradict "never write the golden reference
yourself." Its only job is to fail, and if it does, the testbench is
over-constrained.

## Sizing for synthesis time

Every task is built from scratch here; nothing is retargeted from the existing
TierTwo harnesses. That makes parameter sizing a spec-time decision, and it has
already cost real time twice on this project.

Order-sensitive structures are the trap. A rule phrased "every older store" or
"the youngest older overlapping entry" implies a DEPTH × DEPTH comparison sweep,
each cell carrying a magnitude compare; Yosys's SAT-based `share` pass costs
roughly the square of the arithmetic-operator count and stops finishing. The
shipped `lsq` had to be cut from DEPTH 16 to 8 for exactly this reason, and the
cache from a wider line for a related one.

So, for `ca_d01`, `ca_d02`, `ca_d03` and `ca_d06` in particular: pick the
smallest depth/associativity at which every ordering, forwarding and stall case
in the spec still occurs, prove it builds through ORFS before writing the
testbench against it, and record the sizing decision *and its reason* in the
`_iface.sv` header. A parameter cut after PPA numbers exist invalidates them —
note in the header that baselines from a different size are not comparable.
