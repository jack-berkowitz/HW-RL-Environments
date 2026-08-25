# Cross-model results

8 design tasks. Every design that was run appears, including the
reference implementation each task is anchored on.

**Per-axis only — there is deliberately no combined score.** A single
figure of merit would have to weight area against frequency against
capability, and nothing here establishes those weights.


## d_ca01 — non-blocking data cache

| design | correctness | area (µm²) | power (mW) | Fmax (MHz) | lat.min | lat.max | outstd | fills | notes |
|---|---|---|---|---|---|---|---|---|---|
| `ChatGPT 5.6 Sol` | *not scored against this prompt* | — | — | — | — | — | — | — | last run answered task text `77229cda1b6cd7c3`; the task text is now `aab70a4bfcf132e7` |
| `Claude Opus 5` | *not scored against this prompt* | — | — | — | — | — | — | — | last run answered task text `77229cda1b6cd7c3`; the task text is now `aab70a4bfcf132e7` |
| `Gemini 3.1 Pro` | *not scored against this prompt* | — | — | — | — | — | — | — | last run answered task text `77229cda1b6cd7c3`; the task text is now `aab70a4bfcf132e7` |
| `nonblocking_dcache_alt_ref` | *not scored against this prompt* | — | — | — | — | — | — | — | last run answered task text `c9c3532f93fe4954`; the task text is now `aab70a4bfcf132e7` |
| `nonblocking_dcache_ref` | *not scored against this prompt* | — | — | — | — | — | — | — | last run answered task text `c9c3532f93fe4954`; the task text is now `aab70a4bfcf132e7` |

## d_ca04 — asynchronous CDC FIFO

| design | correctness | area (µm²) | power (mW) | Fmax (MHz) | FIFO capacity | min crossing lat | max crossing lat | write stalls | notes |
|---|---|---|---|---|---|---|---|---|---|
| `async_fifo_cdc_ref` | *not scored against this prompt* | — | — | — | — | — | — | — | last run answered task text `5c9a12842b8b0c7d`; the task text is now `bb5804a42c980b6f` |
| `ChatGPT 5.6 Sol` | *not scored against this prompt* | — | — | — | — | — | — | — | last run answered task text `5c9a12842b8b0c7d`; the task text is now `bb5804a42c980b6f` |
| `Claude Opus 5` | *not scored against this prompt* | — | — | — | — | — | — | — | last run answered task text `5c9a12842b8b0c7d`; the task text is now `bb5804a42c980b6f` |
| `DeepSeek V4 Pro` | *not scored against this prompt* | — | — | — | — | — | — | — | last run answered task text `8a5e5e0a9b2c93d3`; the task text is now `bb5804a42c980b6f` |
| `Gemini 3.1 Pro` | *not scored against this prompt* | — | — | — | — | — | — | — | last run answered task text `5c9a12842b8b0c7d`; the task text is now `bb5804a42c980b6f` |
| `Qwen 3.7 Plus` | *not scored against this prompt* | — | — | — | — | — | — | — | last run answered task text `8a5e5e0a9b2c93d3`; the task text is now `bb5804a42c980b6f` |
- **FIFO capacity** — beats accepted before backpressure
- **min crossing lat** — read-clock cycles, minimum. NOT a capability discriminator on its own: at the scored SYNC_STAGES=2 a design hardcoding two synchroniser flops reads identically to a correct one. The parameter is bound by the correctness sweep at SYNC_STAGES=3 (F49)
- **max crossing lat** — read-clock cycles, maximum
- **write stalls** — cycles the writer was blocked

## d_dsp02 — FP32 fused multiply-add

| design | correctness | area (µm²) | power (mW) | Fmax (MHz) | latency | init interval | notes |
|---|---|---|---|---|---|---|---|
| `ChatGPT 5.6 Sol` | *not scored against this prompt* | — | — | — | — | — | last run answered task text `617eb4240908e773`; the task text is now `8420f4393a0a930d` |
| `Claude Opus 5` | *not scored against this prompt* | — | — | — | — | — | last run answered task text `617eb4240908e773`; the task text is now `8420f4393a0a930d` |
| `DeepSeek V4 Pro` | *not scored against this prompt* | — | — | — | — | — | last run answered task text `5ad30593403b4ae2`; the task text is now `8420f4393a0a930d` |
| `fp32_fma_ii1_ref` | *not scored against this prompt* | — | — | — | — | — | last run answered task text `617eb4240908e773`; the task text is now `8420f4393a0a930d` |
| `Gemini 3.1 Pro` | *not scored against this prompt* | — | — | — | — | — | last run answered task text `617eb4240908e773`; the task text is now `8420f4393a0a930d` |
| `Qwen 3.7 Plus` | *not scored against this prompt* | — | — | — | — | — | last run answered task text `5ad30593403b4ae2`; the task text is now `8420f4393a0a930d` |
- **latency** — clocks from accept to result
- **init interval** — clocks between accepts

## d_dsp03 — multi-format FMA

| design | correctness | area (µm²) | power (mW) | Fmax (MHz) | lat.min | lat.max | ops/1k | notes |
|---|---|---|---|---|---|---|---|---|
| `ChatGPT 5.6 Sol` | *not scored against this prompt* | — | — | — | — | — | — | last run answered task text `8eb2ae18667fe22a`; the task text is now `62ca0ac68332c76d` |
| `Claude Opus 5` | *not scored against this prompt* | — | — | — | — | — | — | last run answered task text `8eb2ae18667fe22a`; the task text is now `62ca0ac68332c76d` |
| `fp_multifmt_fma_ref` | *not scored against this prompt* | — | — | — | — | — | — | last run answered task text `8eb2ae18667fe22a`; the task text is now `62ca0ac68332c76d` |
| `Gemini 3.1 Pro` | *not scored against this prompt* | — | — | — | — | — | — | last run answered task text `8eb2ae18667fe22a`; the task text is now `62ca0ac68332c76d` |

## d_nw01 — AXI4 crossbar

| design | correctness | area (µm²) | power (mW) | Fmax (MHz) | capacity (C1) | 1-pair thruput | 2-pair thruput | aggregate thruput | beat rate | notes |
|---|---|---|---|---|---|---|---|---|---|---|
| `axi4_xbar_ref` | *not scored against this prompt* | — | — | — | — | — | — | — | — | last run answered task text `96c1a3ad5854776a`; the task text is now `29910fdec8a8e5d9` |
| `ChatGPT 5.6 Sol` | *not scored against this prompt* | — | — | — | — | — | — | — | — | last run answered task text `96c1a3ad5854776a`; the task text is now `29910fdec8a8e5d9` |
| `Claude Opus 5` | *not scored against this prompt* | — | — | — | — | — | — | — | — | last run answered task text `96c1a3ad5854776a`; the task text is now `29910fdec8a8e5d9` |
| `DeepSeek V4 Pro` | *not scored against this prompt* | — | — | — | — | — | — | — | — | last run answered task text `4e277da1edfe8af7`; the task text is now `29910fdec8a8e5d9` |
| `Gemini 3.1 Pro` | *not scored against this prompt* | — | — | — | — | — | — | — | — | last run answered task text `96c1a3ad5854776a`; the task text is now `29910fdec8a8e5d9` |
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
| `nc_a_reset_polarity` | 0/8 FAIL | — | — | — | 0 | 7834 | 0 |  |
| `nc_b_outputs_serialised` | 6/8 FAIL | — | — | — | 7079 | 7983 | 9 |  |
| `axis_switch_oq_ref` | *not scored against this prompt* | — | — | — | — | — | — | last run answered task text `b02da2223907630b`; the task text is now `514a316a4889dd72` |
| `ChatGPT 5.6 Sol` | *not scored against this prompt* | — | — | — | — | — | — | last run answered task text `b02da2223907630b`; the task text is now `514a316a4889dd72` |
| `Claude Opus 5` | *not scored against this prompt* | — | — | — | — | — | — | last run answered task text `b02da2223907630b`; the task text is now `514a316a4889dd72` |
| `Gemini 3.1 Pro` | *not scored against this prompt* | — | — | — | — | — | — | last run answered task text `b02da2223907630b`; the task text is now `514a316a4889dd72` |

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

Rows below answer task text `a04f965ad7552b22` (spec + the prompt the
model is handed). A submission scored against a different
prompt is a different question and is not listed.

| testbench | tells correct from broken | accepts correct design | accepts 2nd implementation | accepts legal variants | catches faults | notes |
|---|---|---|---|---|---|---|
| **reference testbench** | yes | yes | yes | 5/5 | **10/10** | establishes the ceiling |
| `ChatGPT 5.6 Sol` | **no** | **no** | **no** | 1/5 | *withheld* | **INVALID** — same verdict on the golden DUT and on a deliberately broken one (golden=FAIL, broken=FAIL), so it is not measuring the design under test. Excluded from scoring (rule 23) |
| `Claude Opus 5` | **no** | **no** | **no** | 1/5 | *withheld* | **INVALID** — same verdict on the golden DUT and on a deliberately broken one (golden=FAIL, broken=FAIL), so it is not measuring the design under test. Excluded from scoring (rule 23) |
| `Gemini 3.1 Pro` | yes | yes | yes | 5/5 | **4/10** |  |

## v_ca04 — stream crossbar

Rows below answer task text `f4ed051311687cf7` (spec + the prompt the
model is handed). A submission scored against a different
prompt is a different question and is not listed.

| testbench | tells correct from broken | accepts correct design | accepts 2nd implementation | accepts legal variants | catches faults | notes |
|---|---|---|---|---|---|---|
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

Rows below answer task text `ca63302d6b23df46` (spec + the prompt the
model is handed). A submission scored against a different
prompt is a different question and is not listed.

| testbench | tells correct from broken | accepts correct design | accepts 2nd implementation | accepts legal variants | catches faults | notes |
|---|---|---|---|---|---|---|
| **reference testbench** | yes | yes | yes | 5/5 | **10/10** | establishes the ceiling |
| `Claude Opus 5` | **no** | **no** | yes | 0/5 | *withheld* | **INVALID** — same verdict on the golden DUT and on a deliberately broken one (golden=FAIL, broken=FAIL), so it is not measuring the design under test. Excluded from scoring (rule 23) |

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

