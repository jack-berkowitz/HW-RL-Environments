# Catalog v3 — Hard Rebuild

32 tasks: 16 design, 16 verification. Replaces the v2 lists.

Rebuilt after a frontier model beat the upstream reference on area and power for
`nw_d01` (AXI-Stream width adapter) at slightly lower Fmax. Small combinational
and dataflow blocks are the wrong difficulty band — the headroom isn't there.

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

| id | module | why it's hard | anchor (vendored) |
|---|---|---|---|
| `d_ca01` | `nonblocking_dcache` | Full hit-under-miss and miss-under-miss: MSHR allocation, secondary merge, fill/replay ordering, store merging, forward progress under saturating traffic. Deadlock freedom is the real requirement. | basejump `bsg_cache_non_blocking` |
| `d_ca02` | `speculative_lsq` | Speculative load issue with memory-order-violation detection and replay. The violation detector only fails under specific store/load interleavings. | CVA6 `load_store_unit` subsystem |
| `d_ca03` | `mmu_sv39_full` | Integrated MMU: PTW, TLB, ASID handling, superpages, fault generation and prioritization, walk arbitration between I- and D-side. | CVA6 `cva6_mmu` (PTW + `cva6_tlb`) |
| `d_ca04` | `async_fifo_cdc` | **Two-clock.** Gray pointers, synchronizer depth, full/empty with no false assertion at any clock ratio, reset sequencing across domains. | PULP `common_cells/cdc_fifo_gray.sv` |
| `d_ca05` | `miss_handler_arb` | Multi-requester miss handler: arbitration among cache controllers, AMO handling, refill sequencing, no requester starvation. | CVA6 `miss_handler` / `std_nbdcache` |

## Networking (4)

| id | module | why it's hard | anchor (vendored) |
|---|---|---|---|
| `d_nw01` | `axi4_xbar` | Full AXI4 crossbar: outstanding-ID tracking, no per-ID response reordering, deadlock freedom under all-to-all traffic, QoS arbitration. Correctness is a liveness property. | PULP `axi/src/axi_xbar.sv` |
| `d_nw02` | `vc_router_alloc` | Separable VC allocation plus switch allocation. Allocator design is research-adjacent and the naive answer starves under load. | basejump `bsg_wormhole_router` + `bsg_router_crossbar_o_by_i` |
| `d_nw03` | `axis_switch_oq` | Output-queued stream switch: per-output scheduling, frame atomicity, no head-of-line blocking across inputs. | Forencich `verilog-axis/rtl/axis_switch.v` |
| `d_nw04` | `tcdm_log_interconnect` | Many-master/many-bank interconnect: single-cycle bank conflict resolution at width, fairness under hotspotting. | PULP `hci` |

## AI Acceleration (4)

| id | module | why it's hard | anchor (vendored) |
|---|---|---|---|
| `d_ai01` | `systolic_16x16_dbuf` | 16×16 array with weight double-buffering and accumulator drain overlapping compute. The scheduling is the task; the MAC is trivial. | PULP `redmule` datapath |
| `d_ai02` | `gemm_tiler` | Full GEMM tiling control: loop bounds, edge tiles, accumulator reuse, double-buffered operand fetch overlapping compute. | NVDLA CACC/CDMA control |
| `d_ai03` | `dma_2d_chained` | 2D/3D strided DMA: descriptor chaining, unaligned source and destination, mid-transfer reconfiguration, completion ordering. | PULP `idma` |
| `d_ai04` | `sdp_requant_pipeline` | Accumulate → bias → scale → requant → clamp at full rate: per-channel parameters, saturation boundaries, no bubble. | NVDLA SDP |

## DSP / Arithmetic (3)

| id | module | why it's hard | anchor (vendored) |
|---|---|---|---|
| `d_dsp01` | `fp_divsqrt_srt` | Radix-4 SRT divide/sqrt with on-the-fly quotient conversion, all IEEE rounding modes, subnormals, fixed initiation interval. Bit-exactness across the corner space is brutal. | PULP `fpu_div_sqrt_mvp` + `cvfpu` |
| `d_dsp02` | `fp32_fma_ii1` | fp32 FMA at II=1: five rounding modes, subnormals handled in-pipeline rather than via a slow path, correct tininess-after-rounding. | PULP `cvfpu/fpnew_fma.sv` |
| `d_dsp03` | `multifmt_slice` | Format-parametric datapath sharing hardware across fp32/fp16/bf16 with correct per-format rounding and exception flags. Resource sharing is the difficulty. | PULP `cvfpu/fpnew_opgroup_multifmt_slice.sv` |

---

# VERIFICATION TASKS (16)

Anchors disjoint from every design task above.

## Comp Arch (5)

| id | module | why it's hard to verify | anchor (vendored) |
|---|---|---|---|
| `v_ca01` | `issue_stage` | Full issue: scoreboard, operand read, WAW/RAW tracking, flush and precise recovery. Deep state, rare interleavings. | CVA6 `issue_stage` + `scoreboard` |
| `v_ca02` | `cache_ctrl` | Per-port cache controller: miss sequencing, AMO, replay, interaction with the shared miss handler. | CVA6 `cache_ctrl` |
| `v_ca03` | `axi_iw_converter` | ID-width conversion: table pressure, stall when no free ID, per-ID ordering preserved across the conversion. | PULP `axi/src/axi_iw_converter.sv` |
| `v_ca04` | `stream_xbar` | Stream crossbar: fairness, no data loss, deadlock freedom under all-to-all. | PULP `common_cells/stream_xbar.sv` |
| `v_ca05` | `id_queue` | Out-of-order occupancy by ID, per-ID FIFO ordering, exists-lookup, full/empty edges. | PULP `common_cells/id_queue.sv` |

## Networking (4)

| id | module | why it's hard to verify | anchor (vendored) |
|---|---|---|---|
| `v_nw01` | `eth_stack` | ARP plus the surrounding RX/TX path shipped whole: request/reply, cache insert and evict, timeout and retry, gratuitous ARP, broadcast. | Forencich `arp*` + `axis_gmii_rx` |
| `v_nw02` | `axi_atop_filter` | Atomic-op filtering: synthesised B/R responses, no protocol violation on filtered ATOPs. | PULP `axi/src/axi_atop_filter.sv` |
| `v_nw03` | `axis_arb_mux` | Frame atomicity, arbitration fairness over long horizons, `tlast` under backpressure. | Forencich `verilog-axis/rtl/axis_arb_mux.v` |
| `v_nw04` | `ptp_clock` | Time-base correctness: fractional-ns accumulation, drift, adjustment without discontinuity. | Forencich `verilog-ethernet/rtl/ptp_clock.v` |

## AI Acceleration (4)

| id | module | why it's hard to verify | anchor (vendored) |
|---|---|---|---|
| `v_ai01` | `idma_backend` | Descriptor-driven DMA: unaligned src/dst, 2D strides, mid-transfer backpressure, completion ordering. **Blocked on the concrete-type wrapper** — see open items. | PULP `idma` (generated backend) |
| `v_ai02` | `hwpe_stream_fabric` | Streamer split/merge/fifo: no data loss across width changes, valid/ready never deadlocks. | PULP `hwpe-stream` |
| `v_ai03` | `redmule_ctrl` | GEMM control: loop bounds, edge tiles, accumulator reuse across tiles. Disjoint from `d_ai01`, which uses the datapath. | PULP `redmule` control |
| `v_ai04` | `binconv_array` | Mixed/binary-precision convolution array: precision-mode switching, accumulation correctness per mode. | PULP `ne16` |

## DSP / Arithmetic (3)

| id | module | why it's hard to verify | anchor (vendored) |
|---|---|---|---|
| `v_dsp01` | `fp_cast_multi` | Saturation vs wraparound, RTZ vs RNE, out-of-range, NaN→int, every format pair. | PULP `cvfpu/fpnew_cast_multi.sv` |
| `v_dsp02` | `fp_noncomp` | Comparisons, min/max, classification, sign injection: NaN payloads, signed zero, quiet vs signalling. Enormous corner space, trivial-looking module. | PULP `cvfpu/fpnew_noncomp.sv` |
| `v_dsp03` | `cdc_fifo_gray` | **Two-clock.** Gray pointer correctness, no loss or duplication at arbitrary clock ratios, reset skew. Verification counterpart to `d_ca04`, and permitted because a design task's reference is never shipped. | PULP `common_cells/cdc_fifo_gray.sv` |

> `v_dsp03` is the one deliberate near-collision with `d_ca04`. It is acceptable
> because the design task ships only an `_iface.sv` and never exposes its
> reference. If you would rather have zero overlap at all, drop `v_dsp03` and run
> 15 verification tasks.

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

Keep the completed work. `ai_d01`, `nw_d01`, and `ca_d08` are built and passing —
they are useful as **calibration tasks**: a floor that confirms the harness works
and that a submission which fails them is broken rather than merely unoptimized.
Just don't count them as benchmark signal.

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
