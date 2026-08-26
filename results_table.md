# Cross-model results

8 design tasks. Every design that was run appears, including the
reference implementation each task is anchored on.

**Per-axis only — there is deliberately no combined score.** A single
figure of merit would have to weight area against frequency against
capability, and nothing here establishes those weights.


## d_ai01 — FP16 weight-broadcast multiply-accumulate array

| design | correctness | area (µm²) | power (mW) | Fmax (MHz) | notes |
|---|---|---|---|---|---|
| **reference** | **2/2 pass** | — | — | — | scored configuration HEIGHT_4_WIDTH_8 not present in this run |
| `nc_g_height_blind_depth` — *negative control, expected to fail* | 1/2 FAIL | — | — | — | scored configuration HEIGHT_4_WIDTH_8 not present in this run |
| `ChatGPT 5.6 Sol` | *not scored against this prompt* | — | — | — | last run answered task text `2b7c36c5b08e7965`; the task text is now `2f2c4cd76f582ae1` |
| `Claude Opus 5` | *not scored against this prompt* | — | — | — | last run answered task text `2cf1ff4be7bf693a`; the task text is now `2f2c4cd76f582ae1` |
| `claude_nodefault` | *not scored against this prompt* | — | — | — | last run answered task text `2b7c36c5b08e7965`; the task text is now `2f2c4cd76f582ae1` |
| `Gemini 3.1 Pro` | *not scored against this prompt* | — | — | — | last run answered task text `2cf1ff4be7bf693a`; the task text is now `2f2c4cd76f582ae1` |
| `nc_a_stuck_output` | *not scored against this prompt* | — | — | — | last run answered task text `2b7c36c5b08e7965`; the task text is now `2f2c4cd76f582ae1` |
| `nc_b_extra_pipe_stage` | *not scored against this prompt* | — | — | — | last run answered task text `2b7c36c5b08e7965`; the task text is now `2f2c4cd76f582ae1` |
| `nc_c_flush_subnormal` | *not scored against this prompt* | — | — | — | last run answered task text `2b7c36c5b08e7965`; the task text is now `2f2c4cd76f582ae1` |
| `nc_d_overflow_always_inf` | *not scored against this prompt* | — | — | — | last run answered task text `2b7c36c5b08e7965`; the task text is now `2f2c4cd76f582ae1` |
| `nc_e_positive_zero_only` | *not scored against this prompt* | — | — | — | last run answered task text `2b7c36c5b08e7965`; the task text is now `2f2c4cd76f582ae1` |
| `nc_f_reversed_chain` | *not scored against this prompt* | — | — | — | last run answered task text `2b7c36c5b08e7965`; the task text is now `2f2c4cd76f582ae1` |

## d_ca01 — non-blocking data cache

| design | correctness | area (µm²) | power (mW) | Fmax (MHz) | lat.min | lat.max | outstd | fills | notes |
|---|---|---|---|---|---|---|---|---|---|
| `chat` | **16/16 pass** | 780,029 | 128.0 | not swept | 2 | 20057 | 10 | 486 | 78,003 um2 per unit of max_outstanding_n, 1.36x the reference per unit |
| `claude` | **16/16 pass** | 563,403 | 94.5 | not swept | 1 | 20057 | 9 | 482 | **different design point** (latency_min 1 vs reference 2): area is correct but not like-for-like; 62,600 um2 per unit of max_outstanding_n, 1.09x the reference per unit |
| `gemini` | 0/16 FAIL | — | — | — | 2 | 184 | 16 | 455 |  |
| `nc_r1_evades_antecedent` — *negative control, expected to fail* | 0/16 FAIL | — | — | — | 2 | 20113 | 10 | 481 |  |
| **reference** | **16/16 pass** | 573,055 | 76.0 | 100.0 | 2 | 20113 | 10 | 481 | 57,306 um2 per unit of max_outstanding_n |
| `nonblocking_dcache_alt_ref` | *not scored against this prompt* | — | — | — | — | — | — | — | last run answered task text `c9c3532f93fe4954`; the task text is now `51337b00b54b64c7` |

## d_ca03 — RISC-V Sv39 MMU -- page-table walker, TLBs, PMP

| design | correctness | area (µm²) | power (mW) | Fmax (MHz) | notes |
|---|---|---|---|---|---|
| `chat` | **1/1 pass** | withheld | withheld | not swept | **PPA withheld — the build did not meet timing** (slack -35.461 ns at 12.5 ns). Area and power from a design that does not close describe a circuit that cannot run at that clock (rule 22).; scored configuration SV_39_XLEN_64_VLEN_64_PLEN_56_ASID_WIDTH_16_NrPMPEntries_8_ITLB_ENTRIES_16_DTLB_ENTRIES_16 not present in this run |
| `claude` | 0/1 FAIL | — | — | — | scored configuration SV_39_XLEN_64_VLEN_64_PLEN_56_ASID_WIDTH_16_NrPMPEntries_8_ITLB_ENTRIES_16_DTLB_ENTRIES_16 not present in this run |
| `gemini` | **did not build** | **0** | **0** | **0** | **build failure** — 10 error(s); first: sanitised_gemini.sv:113:5: error: declaration must come before all statements in the block  |
| `sv39_mmu_ref` | — | 279,456 | 32.6 | 121.9 |  |
| **reference** | **1/1 pass** | 279,456 | 32.6 | not swept | scored configuration SV_39_XLEN_64_VLEN_64_PLEN_56_ASID_WIDTH_16_NrPMPEntries_8_ITLB_ENTRIES_16_DTLB_ENTRIES_16 not present in this run |

## d_ca04 — asynchronous CDC FIFO

| design | correctness | area (µm²) | power (mW) | Fmax (MHz) | FIFO capacity | min crossing lat | max crossing lat | write stalls | notes |
|---|---|---|---|---|---|---|---|---|---|
| **reference** | **18/18 pass** | 19,837 | 13.4 | 355.6 | 10 | 3 | 74 | 11046 | 1,984 um2 per unit of capacity_beats_accepted |
| `chat` | **18/18 pass** | 14,939 | 8.1 | not swept | 8 | 3 | 72 | 10914 | 1,867 um2 per unit of capacity_beats_accepted, 0.94x the reference per unit |
| `claude` | **18/18 pass** | 14,798 | 8.0 | not swept | 8 | 2 | 72 | 10912 | **different design point** (crossing_latency_rdclk_min 2 vs reference 3): area is correct but not like-for-like; 1,850 um2 per unit of capacity_beats_accepted, 0.93x the reference per unit |
| `gemini` | **18/18 pass** | 14,396 | 8.3 | not swept | 8 | 2 | 72 | 10912 | **different design point** (crossing_latency_rdclk_min 2 vs reference 3): area is correct but not like-for-like; 1,800 um2 per unit of capacity_beats_accepted, 0.91x the reference per unit |
| `DeepSeek V4 Pro` | *not scored against this prompt* | — | — | — | — | — | — | — | last run answered task text `8a5e5e0a9b2c93d3`; the task text is now `bb5804a42c980b6f` |
| `Qwen 3.7 Plus` | *not scored against this prompt* | — | — | — | — | — | — | — | last run answered task text `8a5e5e0a9b2c93d3`; the task text is now `bb5804a42c980b6f` |
- **FIFO capacity** — beats accepted before backpressure
- **min crossing lat** — read-clock cycles, minimum. NOT a capability discriminator on its own: at the scored SYNC_STAGES=2 a design hardcoding two synchroniser flops reads identically to a correct one. The parameter is bound by the correctness sweep at SYNC_STAGES=3 (F49)
- **max crossing lat** — read-clock cycles, maximum
- **write stalls** — cycles the writer was blocked

## d_dsp02 — FP32 fused multiply-add

| design | correctness | area (µm²) | power (mW) | Fmax (MHz) | latency | init interval | notes |
|---|---|---|---|---|---|---|---|
| `chat` | **1/1 pass** | 108,000 | 22.3 | not swept | 4 *(req. added later)* | 1 | **not scored against the current spec** — submitted 2026-08-15, before the 3-cycle latency requirement was added 2026-08-16; the spec it was given said "latency is not constrained" |
| `claude` | **1/1 pass** | 63,197 | 66.2 | not swept | 3 | 1 |  |
| **reference** | **1/1 pass** | 60,031 | 74.7 | 78.0 | 3 | 1 |  |
| `gemini` | **FAILS** | n/a | n/a | n/a | n/a | n/a | **fails correctness** — fails the contract at vector 4 (a=1.0, b=0); no PPA, a number for a design that fails its contract is not a result |
| `nc_h3_drops_valid` — *negative control, expected to fail* | 0/1 FAIL | — | — | — | 3 | 1 |  |
| `nc_h3_evades_antecedent` — *negative control, expected to fail* | 0/1 FAIL | — | — | — | 3 | 1 |  |
| `DeepSeek V4 Pro` | *not scored against this prompt* | — | — | — | — | — | last run answered task text `5ad30593403b4ae2`; the task text is now `1302fbe6c552abdc` |
| `Qwen 3.7 Plus` | *not scored against this prompt* | — | — | — | — | — | last run answered task text `5ad30593403b4ae2`; the task text is now `1302fbe6c552abdc` |
- **latency** — clocks from accept to result
- **init interval** — clocks between accepts

## d_dsp03 — multi-format FMA

| design | correctness | area (µm²) | power (mW) | Fmax (MHz) | lat.min | lat.max | ops/1k | notes |
|---|---|---|---|---|---|---|---|---|
| `chat` | 0/2 FAIL | — | — | — | 2 | 16 | 223 |  |
| `claude` | **2/2 pass** | 251,769 | 80.1 | not swept | 1 | 14 | 460 | **different design point** (latency_min 1 vs reference 0): area is correct but not like-for-like; 547 um2 per unit of throughput_ops_per_1000cyc, 1.32x the reference per unit |
| **reference** | **2/2 pass** | 177,557 | 91.1 | 21.3 | 0 | 0 | 427 | 416 um2 per unit of throughput_ops_per_1000cyc |
| `gemini` | **did not build** | **0** | **0** | **0** | n/a | n/a | n/a | **build failure** — 2 error(s); first: sanitised_gemini.sv:261:70: error: expected 'endfunction'  |
| `nc_d_band_unbounded_tininess` — *negative control, expected to fail* | 0/2 FAIL | — | — | — | 0 | 0 | 427 |  |

## d_nw01 — AXI4 crossbar

| design | correctness | area (µm²) | power (mW) | Fmax (MHz) | capacity (C1) | 1-pair thruput | 2-pair thruput | aggregate thruput | beat rate | notes |
|---|---|---|---|---|---|---|---|---|---|---|
| **reference** | **16/16 pass** | 147,144 | 54.7 | 190.5 | — | — | — | — | — | scored configuration MAX_TRANS_8_MAX_BURST_LEN_255 not present in this run |
| `chat` | **16/16 pass** | 199,852 | 58.1 | not swept | — | — | — | — | — | scored configuration MAX_TRANS_8_MAX_BURST_LEN_255 not present in this run |
| `claude` | **16/16 pass** | withheld | withheld | not swept | — | — | — | — | — | **PPA withheld — the build did not meet timing** (slack -0.023 ns at 8.0 ns). Area and power from a design that does not close describe a circuit that cannot run at that clock (rule 22).; scored configuration MAX_TRANS_8_MAX_BURST_LEN_255 not present in this run |
| `gemini` | **did not build** | **0** | **0** | **0** | n/a | n/a | n/a | n/a | n/a | **build failure** — 1 error(s); first: sanitised_gemini.sv:391:139: error: no member named 'w_ready' in 'mst_req_t'  |
| `nc_i_overbuffered_r` — *negative control, expected to fail* | **16/16 pass** | — | — | — | — | — | — | — | — | scored configuration MAX_TRANS_8_MAX_BURST_LEN_255 not present in this run |
| `DeepSeek V4 Pro` | *not scored against this prompt* | — | — | — | — | — | — | — | — | last run answered task text `4e277da1edfe8af7`; the task text is now `29910fdec8a8e5d9` |
| `Qwen 3.7 Plus` | *not scored against this prompt* | — | — | — | — | — | — | — | — | last run answered task text `4e277da1edfe8af7`; the task text is now `29910fdec8a8e5d9` |
- **capacity (C1)** — checker's C1 capacity measure, master 0 — units unresolved, see note
- **1-pair thruput** — bursts/1k cyc, one master-slave pair alone
- **2-pair thruput** — bursts/1k cyc, two disjoint pairs concurrently
- **aggregate thruput** — bursts/1k cyc, all pairs
- **beat rate** — data beats/1k cyc

## d_nw03 — output-queued AXI-Stream switch

| design | correctness | area (µm²) | power (mW) | Fmax (MHz) | beats | cycles | wait.max | notes |
|---|---|---|---|---|---|---|---|---|
| **second source** | **8/8 pass** | — | — | — | 14633 | 8183 | 41 |  |
| **reference** | **8/8 pass** | 26,340 | 10.2 | 363.6 | 14882 | 8021 | 0 | 2 um2 per unit of beats_delivered |
| `chat` | **8/8 pass** | withheld | withheld | not swept | 15926 | 8129 | 46 | **PPA withheld — the build did not meet timing** (slack -0.623 ns at 4.25 ns). Area and power from a design that does not close describe a circuit that cannot run at that clock (rule 22).; 16 um2 per unit of beats_delivered, 9.04x the reference per unit |
| `claude` | **8/8 pass** | withheld | withheld | not swept | 18254 | 8010 | 0 | **PPA withheld — the build did not meet timing** (slack -0.078 ns at 4.25 ns). Area and power from a design that does not close describe a circuit that cannot run at that clock (rule 22).; 1 um2 per unit of beats_delivered, 0.57x the reference per unit |
| `gemini` | **8/8 pass** | withheld | withheld | not swept | 18376 | 8066 | 54 | **PPA withheld — the build did not meet timing** (slack -0.116 ns at 4.25 ns). Area and power from a design that does not close describe a circuit that cannot run at that clock (rule 22).; 7 um2 per unit of beats_delivered, 4.06x the reference per unit |
| `nc_a_reset_polarity` — *negative control, expected to fail* | 0/8 FAIL | — | — | — | 0 | 7834 | 0 |  |
| `nc_b_outputs_serialised` — *negative control, expected to fail* | 6/8 FAIL | — | — | — | 7079 | 7983 | 9 |  |
| `nc_r1_evades_antecedent` — *negative control, expected to fail* | 0/8 FAIL | — | — | — | 14882 | 8021 | 0 |  |

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

| testbench | tells correct from broken | accepts correct design | accepts 2nd implementation | accepts legal variants | catches faults | notes |
|---|---|---|---|---|---|---|
| `ChatGPT 5.6 Sol` | yes | yes | yes | 1/1 | **2/10** |  |
| `Claude Opus 5` | yes | yes | yes | 1/1 | **4/10** |  |
| `Gemini 3.1 Pro` | yes | yes | yes | 1/1 | **2/10** |  |
| `stream_realign_tb` | — | *not scored against this prompt* | — | — | — | last run answered task text `f8d230ec11bd0372` |

## v_ca03 — AXI ID-width converter

Rows below answer task text `fc1baef44b90f91c` (spec + the prompt the
model is handed). A submission scored against a different
prompt is a different question and is not listed.

| testbench | tells correct from broken | accepts correct design | accepts 2nd implementation | accepts legal variants | catches faults | notes |
|---|---|---|---|---|---|---|
| **reference testbench** | yes | yes | yes | 5/5 | **11/11** | establishes the ceiling |
| `chat` | — | *not scored against this prompt* | — | — | — | last run answered task text `a04f965ad7552b22` |
| `claude` | — | *not scored against this prompt* | — | — | — | last run answered task text `a04f965ad7552b22` |
| `gemini` | — | *not scored against this prompt* | — | — | — | last run answered task text `a04f965ad7552b22` |

## v_ca04 — stream crossbar

Rows below answer task text `f4ed051311687cf7` (spec + the prompt the
model is handed). A submission scored against a different
prompt is a different question and is not listed.

| testbench | tells correct from broken | accepts correct design | accepts 2nd implementation | accepts legal variants | catches faults | notes |
|---|---|---|---|---|---|---|
| **reference testbench** | yes | yes | yes | 1/1 | **10/10** | establishes the ceiling |
| `ChatGPT 5.6 Sol` | **no** | **no** | yes | 1/1 | *withheld* | **INVALID** — same verdict on the golden DUT and on a deliberately broken one (golden=FAIL, broken=FAIL), so it is not measuring the design under test. Excluded from scoring (rule 23) |
| `Claude Opus 5` | yes | yes | yes | 1/1 | **6/10** |  |
| `Gemini 3.1 Pro` | yes | yes | yes | 1/1 | **0/10** |  |

## v_ca05 — tag tracker (out-of-order queue)

Rows below answer task text `fd2ae1ad9bf3719d` (spec + the prompt the
model is handed). A submission scored against a different
prompt is a different question and is not listed.

| testbench | tells correct from broken | accepts correct design | accepts 2nd implementation | accepts legal variants | catches faults | notes |
|---|---|---|---|---|---|---|
| **reference testbench** | yes | yes | yes | 4/4 | **10/10** | establishes the ceiling |
| `ChatGPT 5.6 Sol` | yes | yes | yes | 4/4 | **6/10** |  |
| `Claude Opus 5` | yes | yes | yes | 3/4 | *withheld* | accepts the golden DUT but rejects a legal variant or the second DUT, so it rejects some correct hardware — its fault count carries no information |
| `Gemini 3.1 Pro` | yes | yes | yes | 3/4 | *withheld* | accepts the golden DUT but rejects a legal variant or the second DUT, so it rejects some correct hardware — its fault count carries no information |

## v_ca06 — AXI data-width downsizer

Rows below answer task text `6cb14e9d2e6381ac` (spec + the prompt the
model is handed). A submission scored against a different
prompt is a different question and is not listed.

| testbench | tells correct from broken | accepts correct design | accepts 2nd implementation | accepts legal variants | catches faults | notes |
|---|---|---|---|---|---|---|
| **reference testbench** | yes | yes | yes | 5/5 | **12/12** | establishes the ceiling |
| `claude` | — | *not scored against this prompt* | — | — | — | last run answered task text `ca63302d6b23df46` |

## v_ca07 — Glitch-free integer clock divider

Rows below answer task text `0d5cc8575568fdb1` (spec + the prompt the
model is handed). A submission scored against a different
prompt is a different question and is not listed.

| testbench | tells correct from broken | accepts correct design | accepts 2nd implementation | accepts legal variants | catches faults | notes |
|---|---|---|---|---|---|---|
| **reference testbench** | yes | yes | yes | 5/5 | **10/10** | establishes the ceiling |

## v_dsp02 — FP non-computational ops

Rows below answer task text `eacc3c043e2a5767` (spec + the prompt the
model is handed). A submission scored against a different
prompt is a different question and is not listed.

| testbench | tells correct from broken | accepts correct design | accepts 2nd implementation | accepts legal variants | catches faults | notes |
|---|---|---|---|---|---|---|
| **reference testbench** | yes | yes | yes | 5/5 | **10/10** | establishes the ceiling |
| `ChatGPT 5.6 Sol` | yes | yes | yes | 5/5 | **2/10** |  |
| `Claude Opus 5` | yes | yes | yes | 5/5 | **10/10** |  |
| `Gemini 3.1 Pro` | **no** | **no** | **no** | 1/5 | *withheld* | **INVALID** — same verdict on the golden DUT and on a deliberately broken one (golden=FAIL, broken=FAIL), so it is not measuring the design under test. Excluded from scoring (rule 23) |

## v_nw01 — arp engine

Rows below answer task text `63dbe82fceded681` (spec + the prompt the
model is handed). A submission scored against a different
prompt is a different question and is not listed.

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

| testbench | tells correct from broken | accepts correct design | accepts 2nd implementation | accepts legal variants | catches faults | notes |
|---|---|---|---|---|---|---|
| **reference testbench** | yes | yes | yes | 1/1 | **10/10** | establishes the ceiling |
| `ChatGPT 5.6 Sol` | **no** | **no** | **no** | 0/1 | *withheld* | **INVALID** — same verdict on the golden DUT and on a deliberately broken one (golden=FAIL, broken=FAIL), so it is not measuring the design under test. Excluded from scoring (rule 23) |
| `Claude Opus 5` | yes | yes | yes | 1/1 | **10/10** |  |
| `Gemini 3.1 Pro` | **no** | **no** | **no** | 0/1 | *withheld* | **INVALID** — same verdict on the golden DUT and on a deliberately broken one (golden=FAIL, broken=FAIL), so it is not measuring the design under test. Excluded from scoring (rule 23) |

## v_nw03 — frame-arbitrating stream mux

Rows below answer task text `839999302366fa24` (spec + the prompt the
model is handed). A submission scored against a different
prompt is a different question and is not listed.

| testbench | tells correct from broken | accepts correct design | accepts 2nd implementation | accepts legal variants | catches faults | notes |
|---|---|---|---|---|---|---|
| **reference testbench** | yes | yes | yes | 5/5 | **10/10** | establishes the ceiling |
| `ChatGPT 5.6 Sol` | yes | yes | yes | 5/5 | **10/10** |  |
| `Claude Opus 5` | yes | yes | yes | 5/5 | **10/10** |  |
| `Gemini 3.1 Pro` | **no** | **no** | **no** | 0/5 | *withheld* | **INVALID** — same verdict on the golden DUT and on a deliberately broken one (golden=FAIL, broken=FAIL), so it is not measuring the design under test. Excluded from scoring (rule 23) |

## v_nw04 — PTP time base

Rows below answer task text `b963a88053bae3da` (spec + the prompt the
model is handed). A submission scored against a different
prompt is a different question and is not listed.

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

