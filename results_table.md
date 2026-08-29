# Cross-model results

10 design tasks. Every design that was run appears, including the
reference implementation each task is anchored on.

**Per-axis only — there is deliberately no combined score.** A single
figure of merit would have to weight area against frequency against
capability, and nothing here establishes those weights.


## d_ai01 — FP16 weight-broadcast multiply-accumulate array

| design | correctness | area (µm²) | power (mW) | Fmax (MHz) | notes |
|---|---|---|---|---|---|
| `ChatGPT 5.6 Sol` | *not scored against this prompt* | — | — | — | last run answered task text `b9ff647ed1ad2810`; the task text is now `b62c72cf684c1eff` |
| `Claude Opus 5` | *not scored against this prompt* | — | — | — | last run answered task text `b9ff647ed1ad2810`; the task text is now `b62c72cf684c1eff` |
| `claude_nodefault` | *not scored against this prompt* | — | — | — | last run answered task text `2b7c36c5b08e7965`; the task text is now `b62c72cf684c1eff` |
| `fp16_gemm_array_top` | *not scored against this prompt* | — | — | — | last run answered task text `8ec0b4fd8769d737`; the task text is now `b62c72cf684c1eff` |
| `Gemini 3.1 Pro` | *not scored against this prompt* | — | — | — | last run answered task text `b9ff647ed1ad2810`; the task text is now `b62c72cf684c1eff` |
| `nc_a_stuck_output` | *not scored against this prompt* | — | — | — | last run answered task text `8ec0b4fd8769d737`; the task text is now `b62c72cf684c1eff` |
| `nc_b_extra_pipe_stage` | *not scored against this prompt* | — | — | — | last run answered task text `2b7c36c5b08e7965`; the task text is now `b62c72cf684c1eff` |
| `nc_c_flush_subnormal` | *not scored against this prompt* | — | — | — | last run answered task text `2b7c36c5b08e7965`; the task text is now `b62c72cf684c1eff` |
| `nc_d_overflow_always_inf` | *not scored against this prompt* | — | — | — | last run answered task text `2b7c36c5b08e7965`; the task text is now `b62c72cf684c1eff` |
| `nc_e_positive_zero_only` | *not scored against this prompt* | — | — | — | last run answered task text `2b7c36c5b08e7965`; the task text is now `b62c72cf684c1eff` |
| `nc_f_reversed_chain` | *not scored against this prompt* | — | — | — | last run answered task text `2b7c36c5b08e7965`; the task text is now `b62c72cf684c1eff` |
| `nc_g_height_blind_depth` | *not scored against this prompt* | — | — | — | last run answered task text `8ec0b4fd8769d737`; the task text is now `b62c72cf684c1eff` |
| `nc_h_echo_band_only` | *not scored against this prompt* | — | — | — | last run answered task text `b9ff647ed1ad2810`; the task text is now `b62c72cf684c1eff` |

## d_ai04 — SDP requantise / convert unit

| design | correctness | area (µm²) | power (mW) | Fmax (MHz) | init interval | slots | latency | area | power | notes |
|---|---|---|---|---|---|---|---|---|---|---|
| `chat` | **1/1 pass** | 174,421 | 230.0 | not swept | — | — | — | — | — |  |
| `claude` | **1/1 pass** | 158,486 | 181.0 | not swept | — | — | — | — | — |  |
| `gemini` | **1/1 pass** | 179,212 | 257.0 | not swept | — | — | — | — | — |  |
| `nc_g_alias_modes` — *negative control, expected to fail* | 0/1 FAIL | — | — | — | — | — | — | — | — |  |
| **reference** | **1/1 pass** | 179,943 | 230.0 | 44.4 | — | — | — | — | — |  |
- **init interval** — clocks between accepts
- **latency** — clocks from accept to result

## d_ca01 — non-blocking data cache

| design | correctness | area (µm²) | power (mW) | Fmax (MHz) | lat.min | lat.max | outstd | fills | notes |
|---|---|---|---|---|---|---|---|---|---|
| `chat` | **16/16 pass** | withheld | withheld | not swept | 3 | 226 | 14 | 501 | **PPA withheld — the build did not meet timing** (slack -0.049 ns at 15.0 ns). Area and power from a design that does not close describe a circuit that cannot run at that clock (rule 22).; **different design point** (latency_min 3 vs reference 2): area is correct but not like-for-like; 70,342 um2 per unit of max_outstanding_n, 1.23x the reference per unit |
| `claude` | **16/16 pass** | 753,599 | 326.0 | not swept | 1 | 20057 | 9 | 493 | **different design point** (latency_min 1 vs reference 2): area is correct but not like-for-like; 83,733 um2 per unit of max_outstanding_n, 1.46x the reference per unit |
| `gemini` | **did not build** | **0** | **0** | **0** | n/a | n/a | n/a | n/a | **build failure** — 1 error(s); first: sanitised_gemini.sv:99:7: error: incrementing previous value 2'b11 would overflow enum base type 'logic[1:0]'  |
| `nc_r1_evades_antecedent` | *not scored against this prompt* | — | — | — | — | — | — | — | last run answered task text `51337b00b54b64c7`; the task text is now `63385929275747be` |
| `nonblocking_dcache_alt_ref` | *not scored against this prompt* | — | — | — | — | — | — | — | last run answered task text `c9c3532f93fe4954`; the task text is now `63385929275747be` |
| `nonblocking_dcache_ref` | *not scored against this prompt* | — | — | — | — | — | — | — | last run answered task text `f7a68c4dbec4a1b7`; the task text is now `63385929275747be` |

## d_ca03 — RISC-V Sv39 MMU -- page-table walker, TLBs, PMP

| design | correctness | area (µm²) | power (mW) | Fmax (MHz) | tlb.hits | hit% | pte.rd | cycles | notes |
|---|---|---|---|---|---|---|---|---|---|
| `chat` | **1/1 pass** | — | — | — | — | — | — | — | scored configuration SV_39_XLEN_64_VLEN_64_PLEN_56_ASID_WIDTH_16_NrPMPEntries_8_ITLB_ENTRIES_16_DTLB_ENTRIES_16 not present in this run |
| `claude` | **1/1 pass** | 212,774 | 33.4 | not swept | — | — | — | — | scored configuration SV_39_XLEN_64_VLEN_64_PLEN_56_ASID_WIDTH_16_NrPMPEntries_8_ITLB_ENTRIES_16_DTLB_ENTRIES_16 not present in this run |
| `gemini` | **did not build** | **0** | **0** | **0** | n/a | n/a | n/a | n/a | **build failure** — 4 error(s); first: sanitised_gemini.sv:430:23: error: use of undeclared identifier 'clk'  |
| `sv39_mmu_ref` | — | 279,456 | 32.6 | 121.9 | — | — | — | — |  |
| `sv39_mmu_top` | *not scored against this prompt* | — | — | — | — | — | — | — | last run answered task text `d79170d3b150c5e6`; the task text is now `5c30f59627bedc60` |

## d_ca04 — asynchronous CDC FIFO

| design | correctness | area (µm²) | power (mW) | Fmax (MHz) | FIFO capacity | min crossing lat | max crossing lat | write stalls | notes |
|---|---|---|---|---|---|---|---|---|---|
| **reference** | **18/18 pass** | 19,837 | 13.4 | 355.6 | 10 | 3 | 74 | 11046 | 1,984 um2 per unit of capacity_beats_accepted |
| `chat` | **18/18 pass** | 14,659 | 7.3 | not swept | 8 | 2 | 72 | 10912 | **different design point** (crossing_latency_rdclk_min 2 vs reference 3): area is correct but not like-for-like; 1,832 um2 per unit of capacity_beats_accepted, 0.92x the reference per unit |
| `claude` | **18/18 pass** | 14,520 | 8.2 | not swept | 8 | 3 | 72 | 10914 | 1,815 um2 per unit of capacity_beats_accepted, 0.91x the reference per unit |
| `gemini` | **18/18 pass** | 14,520 | 8.5 | not swept | 8 | 2 | 72 | 10912 | **different design point** (crossing_latency_rdclk_min 2 vs reference 3): area is correct but not like-for-like; 1,815 um2 per unit of capacity_beats_accepted, 0.91x the reference per unit |
| `nc_k_overbuffered_read` — *negative control, expected to fail* | 0/18 FAIL | — | — | — | 18 | 4 | 103 | 10844 |  |
| `DeepSeek V4 Pro` | *not scored against this prompt* | — | — | — | — | — | — | — | last run answered task text `8a5e5e0a9b2c93d3`; the task text is now `758f205c499c7fd1` |
| `Qwen 3.7 Plus` | *not scored against this prompt* | — | — | — | — | — | — | — | last run answered task text `8a5e5e0a9b2c93d3`; the task text is now `758f205c499c7fd1` |
- **FIFO capacity** — beats accepted before backpressure
- **min crossing lat** — read-clock cycles, minimum. NOT a capability discriminator on its own: at the scored SYNC_STAGES=2 a design hardcoding two synchroniser flops reads identically to a correct one. The parameter is bound by the correctness sweep at SYNC_STAGES=3 (F49)
- **max crossing lat** — read-clock cycles, maximum
- **write stalls** — cycles the writer was blocked

## d_ca05 — Multi-requester cache miss handler

| design | correctness | area (µm²) | power (mW) | Fmax (MHz) | cycles | area | power | notes |
|---|---|---|---|---|---|---|---|---|
| `chat` | **1/1 pass** | — | — | — | — | — | — |  |
| `claude` | 0/1 FAIL | — | — | — | — | — | — | 1 configuration(s) carried a combinational-loop warning; Verilator iterated to a fixed point and every configuration converged, so the verdict stands |
| `gemini` | 0/1 FAIL | — | — | — | — | — | — |  |
| **reference** | **1/1 pass** | — | — | — | — | — | — | 1 configuration(s) carried a combinational-loop warning; Verilator iterated to a fixed point and every configuration converged, so the verdict stands |

## d_dsp02 — FP32 fused multiply-add

| design | correctness | area (µm²) | power (mW) | Fmax (MHz) | latency | init interval | notes |
|---|---|---|---|---|---|---|---|
| `chat` | **1/1 pass** | withheld | withheld | not swept | 4 *(req. added later)* | 1 | **PPA withheld — the build did not meet timing** (slack -22.923 ns at 19.25 ns). Area and power from a design that does not close describe a circuit that cannot run at that clock (rule 22).; **not scored against the current spec** — submitted 2026-08-15, before the 3-cycle latency requirement was added 2026-08-16; the spec it was given said "latency is not constrained" |
| `claude` | **1/1 pass** | 61,305 | 21.5 | not swept | 3 | 1 |  |
| `gemini` | **FAILS** | n/a | n/a | n/a | n/a | n/a | **fails correctness** — fails the contract at vector 4 (a=1.0, b=0); no PPA, a number for a design that fails its contract is not a result |
| `nc_h1_comb_ready` — *negative control, expected to fail* | 0/1 FAIL | — | — | — | 3 | 1 |  |
| `nc_h1_inert` — *negative control, expected to fail* | **did not build** | **0** | **0** | **0** | n/a | n/a | **build failure** — 12 error(s); first: nc_h1_inert.sv:74:5: error: unknown class or package 'fpnew_pkg'  |
| `DeepSeek V4 Pro` | *not scored against this prompt* | — | — | — | — | — | last run answered task text `5ad30593403b4ae2`; the task text is now `fd4d334195354cfa` |
| `fp32_fma_ii1_ref` | *not scored against this prompt* | — | — | — | — | — | last run answered task text `a3dfc6d107b61503`; the task text is now `fd4d334195354cfa` |
| `nc_h3_drops_valid` | *not scored against this prompt* | — | — | — | — | — | last run answered task text `a3dfc6d107b61503`; the task text is now `fd4d334195354cfa` |
| `nc_h3_evades_antecedent` | *not scored against this prompt* | — | — | — | — | — | last run answered task text `a3dfc6d107b61503`; the task text is now `fd4d334195354cfa` |
| `Qwen 3.7 Plus` | *not scored against this prompt* | — | — | — | — | — | last run answered task text `5ad30593403b4ae2`; the task text is now `fd4d334195354cfa` |
- **latency** — clocks from accept to result
- **init interval** — clocks between accepts

## d_dsp03 — multi-format FMA

| design | correctness | area (µm²) | power (mW) | Fmax (MHz) | lat.min | lat.max | ops/1k | notes |
|---|---|---|---|---|---|---|---|---|
| `chat` | **2/2 pass** | 582,093 | 167.0 | not swept | 1 | 14 | 460 | **different design point** (latency_min 1 vs reference 0): area is correct but not like-for-like; 1,265 um2 per unit of throughput_ops_per_1000cyc, 3.04x the reference per unit |
| `claude` | **2/2 pass** | 226,664 | 134.0 | not swept | 0 | 0 | 427 | 531 um2 per unit of throughput_ops_per_1000cyc, 1.28x the reference per unit |
| **reference** | **2/2 pass** | 177,557 | 91.1 | 21.3 | 0 | 0 | 427 | 416 um2 per unit of throughput_ops_per_1000cyc |
| `gemini` | 0/2 FAIL | — | — | — | 1 | 14 | 460 |  |
| `m_a2_rmm_aliases_rne` | 0/2 FAIL | — | — | — | 0 | 0 | 427 |  |
| `m_a5_no_nv_on_invalid` | 0/2 FAIL | — | — | — | 0 | 0 | 427 |  |
| `m_a6_negative_zero_lost` | 0/2 FAIL | — | — | — | 0 | 0 | 427 |  |
| `m_f1_bf16_decoded_as_fp16` | 0/2 FAIL | — | — | — | 0 | 0 | 427 |  |
| `m_v3_upper_bits_zero` | 1/2 FAIL | — | — | — | 0 | 0 | 427 |  |
| `nc_d_band_unbounded_tininess` | *not scored against this prompt* | — | — | — | — | — | — | last run answered task text `62ca0ac68332c76d`; the task text is now `ec21554692b610a5` |

## d_nw01 — AXI4 crossbar

| design | correctness | area (µm²) | power (mW) | Fmax (MHz) | capacity (C1) | 1-pair thruput | 2-pair thruput | aggregate thruput | beat rate | notes |
|---|---|---|---|---|---|---|---|---|---|---|
| `chat` | **16/16 pass** | 172,662 | 49.0 | not swept | — | — | — | — | — | scored configuration MAX_TRANS_8_MAX_BURST_LEN_255 not present in this run |
| `claude` | **16/16 pass** | 181,174 | 49.3 | not swept | — | — | — | — | — | scored configuration MAX_TRANS_8_MAX_BURST_LEN_255 not present in this run |
| `gemini` | 0/16 FAIL | — | — | — | — | — | — | — | — |  |
| `nc_l_inert` — *negative control, expected to fail* | **did not build** | **0** | **0** | **0** | n/a | n/a | n/a | n/a | n/a | **build failure** — 20 error(s); first: typedef.svh': No such file or directory  |
| `nc_m_inert` — *negative control, expected to fail* | **did not build** | **0** | **0** | **0** | n/a | n/a | n/a | n/a | n/a | **build failure** — 20 error(s); first: typedef.svh': No such file or directory  |
| `nc_n_inert` — *negative control, expected to fail* | **did not build** | **0** | **0** | **0** | n/a | n/a | n/a | n/a | n/a | **build failure** — 20 error(s); first: typedef.svh': No such file or directory  |
| `axi4_xbar_ref` | *not scored against this prompt* | — | — | — | — | — | — | — | — | last run answered task text `ad1f7eec79eba35f`; the task text is now `0d484a57107f3502` |
| `DeepSeek V4 Pro` | *not scored against this prompt* | — | — | — | — | — | — | — | — | last run answered task text `4e277da1edfe8af7`; the task text is now `0d484a57107f3502` |
| `nc_i_overbuffered_r` | *not scored against this prompt* | — | — | — | — | — | — | — | — | last run answered task text `ad1f7eec79eba35f`; the task text is now `0d484a57107f3502` |
| `nc_j_overbuffered_w` | *not scored against this prompt* | — | — | — | — | — | — | — | — | last run answered task text `ad1f7eec79eba35f`; the task text is now `0d484a57107f3502` |
| `nc_l_comb_ready` | *not scored against this prompt* | — | — | — | — | — | — | — | — | last run answered task text `ad79bb69c9a09efb`; the task text is now `0d484a57107f3502` |
| `nc_m_withdraws_r_valid` | *not scored against this prompt* | — | — | — | — | — | — | — | — | last run answered task text `ad79bb69c9a09efb`; the task text is now `0d484a57107f3502` |
| `nc_n_drops_sideband` | *not scored against this prompt* | — | — | — | — | — | — | — | — | last run answered task text `ad79bb69c9a09efb`; the task text is now `0d484a57107f3502` |
| `Qwen 3.7 Plus` | *not scored against this prompt* | — | — | — | — | — | — | — | — | last run answered task text `4e277da1edfe8af7`; the task text is now `0d484a57107f3502` |
- **capacity (C1)** — checker's C1 capacity measure, master 0 — units unresolved, see note
- **1-pair thruput** — bursts/1k cyc, one master-slave pair alone
- **2-pair thruput** — bursts/1k cyc, two disjoint pairs concurrently
- **aggregate thruput** — bursts/1k cyc, all pairs
- **beat rate** — data beats/1k cyc

## d_nw03 — output-queued AXI-Stream switch

| design | correctness | area (µm²) | power (mW) | Fmax (MHz) | beats | cycles | wait.max | notes |
|---|---|---|---|---|---|---|---|---|
| **second source** | **8/8 pass** | — | — | — | 14633 | 8183 | 41 |  |
| `chat` | **8/8 pass** | withheld | withheld | not swept | 18254 | 8010 | 0 | **PPA withheld — the build did not meet timing** (slack -0.184 ns at 4.25 ns). Area and power from a design that does not close describe a circuit that cannot run at that clock (rule 22).; 1 um2 per unit of beats_delivered, 0.60x the reference per unit |
| `claude` | **8/8 pass** | 26,164 | 16.9 | not swept | 18267 | 8025 | 1 | 1 um2 per unit of beats_delivered, 0.81x the reference per unit |
| `gemini` | **8/8 pass** | withheld | withheld | not swept | 18376 | 8066 | 54 | **PPA withheld — the build did not meet timing** (slack -0.266 ns at 4.25 ns). Area and power from a design that does not close describe a circuit that cannot run at that clock (rule 22).; 8 um2 per unit of beats_delivered, 4.26x the reference per unit |
| `axis_switch_oq_ref` | *not scored against this prompt* | — | — | — | — | — | — | last run answered task text `62e627b4957c0e2c`; the task text is now `f621889159c58a9d` |
| `nc_a_reset_polarity` | *not scored against this prompt* | — | — | — | — | — | — | last run answered task text `62e627b4957c0e2c`; the task text is now `f621889159c58a9d` |
| `nc_b_outputs_serialised` | *not scored against this prompt* | — | — | — | — | — | — | last run answered task text `62e627b4957c0e2c`; the task text is now `f621889159c58a9d` |
| `nc_h_overbuffered` | *not scored against this prompt* | — | — | — | — | — | — | last run answered task text `62e627b4957c0e2c`; the task text is now `f621889159c58a9d` |
| `nc_r1_evades_antecedent` | *not scored against this prompt* | — | — | — | — | — | — | last run answered task text `62e627b4957c0e2c`; the task text is now `f621889159c58a9d` |

---

## Two measurement questions still open

Both affect how a number should be read, not whether it was measured.

**1. What the d_nw01 capacity figure counts.** The checker's own
comment predicts the reference reaching `MAX_TRANS + 1` = 9 at
`MAX_TRANS = 8`. It measures 27, consistently, across every geometry —
while at `MAX_TRANS = 2` it measures exactly 3, which *is* `MAX_TRANS + 1`.
The relation holds at one depth and not the other. The figures remain
comparable between designs, since every design is measured by the same
harness at the same configuration, but the units are not established
and nothing here should be read as "27 concurrent transactions".

**2. Whether the d_ca04 crossing latencies are comparable at all.**
Minimum crossing latency scales differently on each design: the
`gemini` submission tracks the synchroniser depth exactly (2 stages →
2 cycles, 3 → 3), `chat` tracks depth plus one, and **the reference is
flat at 3 regardless of depth**. Two of those are a plausible design
tradeoff. The third suggests the reference's fastest path may not
traverse the full synchroniser chain — in which case the metric is
sampling something different on that design and the three numbers are
not a like-for-like comparison. This also decides whether `gemini`'s
2-cycle crossing is a genuine result or an artefact. Unresolved.


---

# Verification tasks

**A different measurement, on its own table on purpose.** A verification
submission is a *testbench*: it is judged by which implementations it
accepts and rejects, and there is no area or frequency to report.
Averaging it with the design results would combine things that do not
share units.

The model is given a port map and a written specification. **It never
sees the RTL.**


## v_ai02 — byte-stream realignment

Rows below answer task text `0453b447cb8b1a5c` (spec + the prompt the
model is handed). A submission scored against a different
prompt is a different question and is not listed.

*Clause grouping is recorded in the specifications, not scored here.* Several clauses share one observation and one reported id; the columns below count mutants killed and gate outcomes, and read no clause id. A fault count is not a per-clause score.

| testbench | tells correct from broken | accepts correct design | accepts 2nd implementation | accepts legal variants | catches faults | notes |
|---|---|---|---|---|---|---|
| `ChatGPT 5.6 Sol` | yes | yes | yes | 1/1 | **2/10** |  |
| `Claude Opus 5` | yes | yes | yes | 1/1 | **4/10** |  |
| `Gemini 3.1 Pro` | yes | yes | yes | 1/1 | **2/10** |  |
| `stream_realign_tb` | — | *not scored against this prompt* | — | — | — | last run answered task text `f8d230ec11bd0372` |

## v_ca03 — AXI ID-width converter

Rows below answer task text `5e1adba7cce23c3a` (spec + the prompt the
model is handed). A submission scored against a different
prompt is a different question and is not listed.

*Clause grouping is recorded in the specifications, not scored here.* Several clauses share one observation and one reported id; the columns below count mutants killed and gate outcomes, and read no clause id. A fault count is not a per-clause score.

| testbench | tells correct from broken | accepts correct design | accepts 2nd implementation | accepts legal variants | catches faults | notes |
|---|---|---|---|---|---|---|
| `ChatGPT 5.6 Sol` | **no** | **no** | **no** | 0/5 | *withheld* | **INVALID** — same verdict on the golden DUT and on a deliberately broken one (golden=FAIL, broken=FAIL), so it is not measuring the design under test. Excluded from scoring (rule 23) |
| `Claude Opus 5` | **no** | **no** | **no** | 1/5 | *withheld* | **INVALID** — same verdict on the golden DUT and on a deliberately broken one (golden=FAIL, broken=FAIL), so it is not measuring the design under test. Excluded from scoring (rule 23) |
| `id_width_conv_spec_tb` | — | *not scored against this prompt* | — | — | — | last run answered task text `fa23813e5874ef92` |
| `gemini` | — | *not scored against this prompt* | — | — | — | last run answered task text `18b1288587d371a8` |

## v_ca04 — stream crossbar

Rows below answer task text `dce75b0677d07f7f` (spec + the prompt the
model is handed). A submission scored against a different
prompt is a different question and is not listed.

*Clause grouping is recorded in the specifications, not scored here.* Several clauses share one observation and one reported id; the columns below count mutants killed and gate outcomes, and read no clause id. A fault count is not a per-clause score.

| testbench | tells correct from broken | accepts correct design | accepts 2nd implementation | accepts legal variants | catches faults | notes |
|---|---|---|---|---|---|---|
| **reference testbench** | yes | yes | yes | 1/1 | **10/10** | establishes the ceiling |
| `ChatGPT 5.6 Sol` | yes | yes | yes | 1/1 | **6/10** |  |
| `Claude Opus 5` | yes | yes | yes | 1/1 | **8/10** |  |
| `Gemini 3.1 Pro` | **no** | **no** | **no** | 0/1 | *withheld* | **INVALID** — same verdict on the golden DUT and on a deliberately broken one (golden=FAIL, broken=FAIL), so it is not measuring the design under test. Excluded from scoring (rule 23) |

## v_ca05 — tag tracker (out-of-order queue)

Rows below answer task text `d260529e781b3208` (spec + the prompt the
model is handed). A submission scored against a different
prompt is a different question and is not listed.

*Clause grouping is recorded in the specifications, not scored here.* Several clauses share one observation and one reported id; the columns below count mutants killed and gate outcomes, and read no clause id. A fault count is not a per-clause score.

| testbench | tells correct from broken | accepts correct design | accepts 2nd implementation | accepts legal variants | catches faults | notes |
|---|---|---|---|---|---|---|
| `ChatGPT 5.6 Sol` | yes | yes | yes | 4/4 | **6/10** |  |
| `Claude Opus 5` | yes | yes | yes | 4/4 | **6/10** |  |
| `Gemini 3.1 Pro` | yes | yes | yes | 3/4 | *withheld* | accepts the golden DUT but rejects a legal variant or the second DUT, so it rejects some correct hardware — its fault count carries no information |
| `tag_tracker_spec_tb` | — | *not scored against this prompt* | — | — | — | last run answered task text `fd2ae1ad9bf3719d` |

## v_ca06 — AXI data-width downsizer

Rows below answer task text `2f63b738ee5baf99` (spec + the prompt the
model is handed). A submission scored against a different
prompt is a different question and is not listed.

*Clause grouping is recorded in the specifications, not scored here.* Several clauses share one observation and one reported id; the columns below count mutants killed and gate outcomes, and read no clause id. A fault count is not a per-clause score.

| testbench | tells correct from broken | accepts correct design | accepts 2nd implementation | accepts legal variants | catches faults | notes |
|---|---|---|---|---|---|---|
| `ChatGPT 5.6 Sol` | **no** | **no** | **no** | 0/5 | *withheld* | **INVALID** — same verdict on the golden DUT and on a deliberately broken one (golden=CRASH, broken=FAIL), so it is not measuring the design under test. Excluded from scoring (rule 23) |
| `Claude Opus 5` | **no** | **no** | **no** | 0/5 | *withheld* | **INVALID** — same verdict on the golden DUT and on a deliberately broken one (golden=FAIL, broken=FAIL), so it is not measuring the design under test. Excluded from scoring (rule 23) |
| `Gemini 3.1 Pro` | **no** | **did not compile** | n/a | n/a | n/a | the testbench itself does not build |
| `dw_downsizer_spec_tb` | — | *not scored against this prompt* | — | — | — | last run answered task text `ae29e2161468aeff` |

## v_ca07 — Glitch-free integer clock divider

Rows below answer task text `0d5cc8575568fdb1` (spec + the prompt the
model is handed). A submission scored against a different
prompt is a different question and is not listed.

*Clause grouping is recorded in the specifications, not scored here.* Several clauses share one observation and one reported id; the columns below count mutants killed and gate outcomes, and read no clause id. A fault count is not a per-clause score.

| testbench | tells correct from broken | accepts correct design | accepts 2nd implementation | accepts legal variants | catches faults | notes |
|---|---|---|---|---|---|---|
| **reference testbench** | yes | yes | yes | 5/5 | **10/10** | establishes the ceiling |
| `ChatGPT 5.6 Sol` | yes | yes | yes | 5/5 | **6/10** |  |
| `Claude Opus 5` | **no** | **no** | **no** | 0/5 | *withheld* | **INVALID** — same verdict on the golden DUT and on a deliberately broken one (golden=FAIL, broken=FAIL), so it is not measuring the design under test. Excluded from scoring (rule 23) |
| `Gemini 3.1 Pro` | yes | yes | **no** | 3/5 | *withheld* | accepts the golden DUT but rejects a legal variant or the second DUT, so it rejects some correct hardware — its fault count carries no information |

## v_dsp02 — FP non-computational ops

Rows below answer task text `0d8119950359c940` (spec + the prompt the
model is handed). A submission scored against a different
prompt is a different question and is not listed.

*Clause grouping is recorded in the specifications, not scored here.* Several clauses share one observation and one reported id; the columns below count mutants killed and gate outcomes, and read no clause id. A fault count is not a per-clause score.

| testbench | tells correct from broken | accepts correct design | accepts 2nd implementation | accepts legal variants | catches faults | notes |
|---|---|---|---|---|---|---|
| `ChatGPT 5.6 Sol` | **no** | **no** | **no** | 0/5 | *withheld* | **INVALID** — same verdict on the golden DUT and on a deliberately broken one (golden=FAIL, broken=FAIL), so it is not measuring the design under test. Excluded from scoring (rule 23) |
| `Claude Opus 5` | yes | yes | yes | 5/5 | **12/13** |  |
| `Gemini 3.1 Pro` | **no** | **no** | **no** | 1/5 | *withheld* | **INVALID** — same verdict on the golden DUT and on a deliberately broken one (golden=FAIL, broken=FAIL), so it is not measuring the design under test. Excluded from scoring (rule 23) |
| `fp_noncomp_spec_tb` | — | *not scored against this prompt* | — | — | — | last run answered task text `eacc3c043e2a5767` |

## v_nw01 — arp engine

Rows below answer task text `63dbe82fceded681` (spec + the prompt the
model is handed). A submission scored against a different
prompt is a different question and is not listed.

*Clause grouping is recorded in the specifications, not scored here.* Several clauses share one observation and one reported id; the columns below count mutants killed and gate outcomes, and read no clause id. A fault count is not a per-clause score.

| testbench | tells correct from broken | accepts correct design | accepts 2nd implementation | accepts legal variants | catches faults | notes |
|---|---|---|---|---|---|---|
| **reference testbench** | yes | yes | yes | 1/1 | **10/10** | establishes the ceiling |
| `ChatGPT 5.6 Sol` | **no** | **no** | yes | 1/1 | *withheld* | **INVALID** — same verdict on the golden DUT and on a deliberately broken one (golden=FAIL, broken=FAIL), so it is not measuring the design under test. Excluded from scoring (rule 23) |
| `Claude Opus 5` | **no** | **no** | yes | 1/1 | *withheld* | **INVALID** — same verdict on the golden DUT and on a deliberately broken one (golden=FAIL, broken=FAIL), so it is not measuring the design under test. Excluded from scoring (rule 23) |
| `Gemini 3.1 Pro` | **no** | **no** | **no** | 0/1 | *withheld* | **INVALID** — same verdict on the golden DUT and on a deliberately broken one (golden=FAIL, broken=FAIL), so it is not measuring the design under test. Excluded from scoring (rule 23) |

## v_nw02 — AXI atomic-op filter

Rows below answer task text `90f7b34382e396f4` (spec + the prompt the
model is handed). A submission scored against a different
prompt is a different question and is not listed.

*Clause grouping is recorded in the specifications, not scored here.* Several clauses share one observation and one reported id; the columns below count mutants killed and gate outcomes, and read no clause id. A fault count is not a per-clause score.

| testbench | tells correct from broken | accepts correct design | accepts 2nd implementation | accepts legal variants | catches faults | notes |
|---|---|---|---|---|---|---|
| **reference testbench** | yes | yes | yes | 1/1 | **11/11** | establishes the ceiling |
| `ChatGPT 5.6 Sol` | **no** | **no** | **no** | 0/1 | *withheld* | **INVALID** — same verdict on the golden DUT and on a deliberately broken one (golden=FAIL, broken=FAIL), so it is not measuring the design under test. Excluded from scoring (rule 23) |
| `Claude Opus 5` | yes | yes | yes | 1/1 | **10/10** |  |
| `Gemini 3.1 Pro` | **no** | **no** | **no** | 0/1 | *withheld* | **INVALID** — same verdict on the golden DUT and on a deliberately broken one (golden=FAIL, broken=FAIL), so it is not measuring the design under test. Excluded from scoring (rule 23) |

## v_nw03 — frame-arbitrating stream mux

Rows below answer task text `f2bf87012c9a497f` (spec + the prompt the
model is handed). A submission scored against a different
prompt is a different question and is not listed.

*Clause grouping is recorded in the specifications, not scored here.* Several clauses share one observation and one reported id; the columns below count mutants killed and gate outcomes, and read no clause id. A fault count is not a per-clause score.

| testbench | tells correct from broken | accepts correct design | accepts 2nd implementation | accepts legal variants | catches faults | notes |
|---|---|---|---|---|---|---|
| `ChatGPT 5.6 Sol` | yes | yes | yes | 5/5 | **8/10** |  |
| `Claude Opus 5` | yes | yes | yes | 5/5 | **9/10** |  |
| `Gemini 3.1 Pro` | **no** | **no** | **no** | 0/5 | *withheld* | **INVALID** — same verdict on the golden DUT and on a deliberately broken one (golden=FAIL, broken=FAIL), so it is not measuring the design under test. Excluded from scoring (rule 23) |
| `frame_arb_mux_spec_tb` | — | *not scored against this prompt* | — | — | — | last run answered task text `839999302366fa24` |

## v_nw04 — PTP time base

Rows below answer task text `b963a88053bae3da` (spec + the prompt the
model is handed). A submission scored against a different
prompt is a different question and is not listed.

*Clause grouping is recorded in the specifications, not scored here.* Several clauses share one observation and one reported id; the columns below count mutants killed and gate outcomes, and read no clause id. A fault count is not a per-clause score.

| testbench | tells correct from broken | accepts correct design | accepts 2nd implementation | accepts legal variants | catches faults | notes |
|---|---|---|---|---|---|---|
| **reference testbench** | yes | yes | yes | 1/1 | **10/10** | establishes the ceiling |
| `ChatGPT 5.6 Sol` | yes | yes | **no** | 0/1 | *withheld* | accepts the golden DUT but rejects a legal variant or the second DUT, so it rejects some correct hardware — its fault count carries no information |
| `Claude Opus 5` | yes | yes | yes | 1/1 | **8/10** |  |
| `Gemini 3.1 Pro` | **no** | **no** | **no** | 0/1 | *withheld* | **INVALID** — same verdict on the golden DUT and on a deliberately broken one (golden=FAIL, broken=FAIL), so it is not measuring the design under test. Excluded from scoring (rule 23) |

- **tells correct from broken** — the gate. Every testbench is run twice:
  once against the correct DUT and once against one with every output tied
  high. It must PASS the first and FAIL the second. A testbench that
  returns the same verdict on both is not observing the design at all, and
  no number after this column means anything. A file that drives nothing
  and prints PASS scores 0 here; before this column existed it was reported
  as merely having gaps in fault detection. A dash means the run predates
  the gate and was never measured against it.
- **accepts correct design** — does it pass a known-good implementation?
  A testbench that rejects correct hardware is unusable whatever else it
  catches, so this gates everything after it.
- **accepts 2nd implementation** — an INDEPENDENT correct design, not a
  variation of the reference: different internal structure, same contract.
  Passing the reference design alone cannot distinguish a testbench that
  checks the specification from one fitted to how this particular
  implementation happens to work. A dash means the run predates this
  column and was never measured against it.
- **accepts legal variants** — implementations differing from the reference
  only where the specification is deliberately silent. A correct testbench
  must accept all of them; failing one means it checked something the
  specification never promised.
- **catches faults** — implementations each carrying one deliberate defect.
  Every one is proven catchable by the reference testbench.

**Reported per fault, never as a rate**, and *withheld* where the
testbench failed the first column. A hang is likewise not a catch: the
testbench did not detect the fault, it stopped.

