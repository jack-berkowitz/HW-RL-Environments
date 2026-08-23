# Cross-model results

6 design tasks. Every design that was run appears, including the
reference implementation each task is anchored on.

**Per-axis only — there is deliberately no combined score.** A single
figure of merit would have to weight area against frequency against
capability, and nothing here establishes those weights.


## d_ca01 — non-blocking data cache

| design | correctness | area (µm²) | power (mW) | Fmax (MHz) | lat.min | lat.max | outstd | fills | notes |
|---|---|---|---|---|---|---|---|---|---|
| `chat` | **16/16 pass** | — | — | — | 1 | 20056 | 9 | 480 |  |
| `claude` | **16/16 pass** | — | — | — | 2 | 20064 | 10 | 481 |  |
| `gemini` | **16/16 pass** | — | — | — | 1 | 20058 | 9 | 461 |  |
| `nonblocking_dcache_alt_ref` | *not scored against this prompt* | — | — | — | — | — | — | — | last run answered task text `c9c3532f93fe4954`; the task text is now `77229cda1b6cd7c3` |
| `nonblocking_dcache_ref` | *not scored against this prompt* | — | — | — | — | — | — | — | last run answered task text `c9c3532f93fe4954`; the task text is now `77229cda1b6cd7c3` |

## d_ca04 — asynchronous CDC FIFO

| design | correctness | area (µm²) | power (mW) | Fmax (MHz) | FIFO capacity | min crossing lat | max crossing lat | write stalls | notes |
|---|---|---|---|---|---|---|---|---|---|
| **reference** | **18/18 pass** | 19,887 | 12.9 | 380.9 | 10 | 3 | 74 | 11046 | 1,989 um2 per unit of capacity_beats_accepted |
| `chat` | **18/18 pass** | 14,685 | 7.3 | 222.2 | 8 | 3 | 72 | 10914 | 1,836 um2 per unit of capacity_beats_accepted, 0.92x the reference per unit |
| `claude` | **18/18 pass** | — | — | — | 8 | 3 | 72 | 10914 |  |
| `deepseek` | **18/18 pass** | 14,589 | 7.5 | 273.5 | 8 | 2 | 72 | 10912 | **different design point** (crossing_latency_rdclk_min 2 vs reference 3): area is correct but not like-for-like; 1,824 um2 per unit of capacity_beats_accepted, 0.92x the reference per unit |
| `gemini` | **18/18 pass** | 14,515 | 7.1 | 273.5 | 8 | 2 | 72 | 10912 | **different design point** (crossing_latency_rdclk_min 2 vs reference 3): area is correct but not like-for-like; 1,814 um2 per unit of capacity_beats_accepted, 0.91x the reference per unit |
| `qwen` | **18/18 pass** | 14,176 | 7.8 | 273.5 | 8 | 2 | 72 | 10912 | **different design point** (crossing_latency_rdclk_min 2 vs reference 3): area is correct but not like-for-like; 1,772 um2 per unit of capacity_beats_accepted, 0.89x the reference per unit |
- **FIFO capacity** — beats accepted before backpressure
- **min crossing lat** — read-clock cycles, minimum. NOT a capability discriminator on its own: at the scored SYNC_STAGES=2 a design hardcoding two synchroniser flops reads identically to a correct one. The parameter is bound by the correctness sweep at SYNC_STAGES=3 (F49)
- **max crossing lat** — read-clock cycles, maximum
- **write stalls** — cycles the writer was blocked

## d_dsp02 — FP32 fused multiply-add

| design | correctness | area (µm²) | power (mW) | Fmax (MHz) | latency | init interval | notes |
|---|---|---|---|---|---|---|---|
| `chat` | **1/1 pass** | — | — | 49.4 | 3 | 1 |  |
| `claude` | **1/1 pass** | — | — | — | 3 | 1 |  |
| **reference** | **1/1 pass** | 59,890 | 72.2 | 78.0 | 3 | 1 |  |
| `gemini` | **FAILS** | n/a | n/a | n/a | n/a | n/a | **fails correctness** — fails the contract at vector 4 (a=1.0, b=0); no PPA, a number for a design that fails its contract is not a result |
| `DeepSeek V4 Pro` | *not scored against this prompt* | — | — | — | — | — | last run answered task text `5ad30593403b4ae2`; the task text is now `530f3e4189421457` |
| `Qwen 3.7 Plus` | *not scored against this prompt* | — | — | — | — | — | last run answered task text `5ad30593403b4ae2`; the task text is now `530f3e4189421457` |
- **latency** — clocks from accept to result
- **init interval** — clocks between accepts

## d_dsp03 — multi-format FMA

| design | correctness | area (µm²) | power (mW) | Fmax (MHz) | lat.min | lat.max | ops/1k | notes |
|---|---|---|---|---|---|---|---|---|
| `chat` | **2/2 pass** | — | — | — | 0 | 0 | 427 |  |
| `claude` | 0/2 FAIL | — | — | — | 1 | 14 | 460 |  |
| `gemini` | **did not build** | **0** | **0** | **0** | n/a | n/a | n/a | **build failure** — 2 error(s); first: sanitised_gemini.sv:123:9: error: declaration must come before all statements in the block  |

## d_nw01 — AXI4 crossbar

| design | correctness | area (µm²) | power (mW) | Fmax (MHz) | capacity (C1) | 1-pair thruput | 2-pair thruput | aggregate thruput | beat rate | notes |
|---|---|---|---|---|---|---|---|---|---|---|
| `chat` | **16/16 pass** | n/a | n/a | 111.1 | — | — | — | — | — | **area, power and Fmax unavailable** — place-and-route exceeded the 5.8 GB container memory limit during detailed routing (peak 5.70 GB) — a limit of this test setup, not a property of the design, which was at 75 DRC violations and improving; scored configuration MAX_TRANS_8_MAX_BURST_LEN_255 not present in this run |
| `claude` | **16/16 pass** | — | — | — | — | — | — | — | — | scored configuration MAX_TRANS_8_MAX_BURST_LEN_255 not present in this run |
| `gemini` | 0/16 FAIL | — | — | — | — | — | — | — | — |  |
| `axi4_xbar_ref` | *not scored against this prompt* | — | — | — | — | — | — | — | — | last run answered task text `04ddf4d2c9e06b3d`; the task text is now `96c1a3ad5854776a` |
| `DeepSeek V4 Pro` | *not scored against this prompt* | — | — | — | — | — | — | — | — | last run answered task text `4e277da1edfe8af7`; the task text is now `96c1a3ad5854776a` |
| `Qwen 3.7 Plus` | *not scored against this prompt* | — | — | — | — | — | — | — | — | last run answered task text `4e277da1edfe8af7`; the task text is now `96c1a3ad5854776a` |
- **capacity (C1)** — checker's C1 capacity measure, master 0 — units unresolved, see note
- **1-pair thruput** — bursts/1k cyc, one master-slave pair alone
- **2-pair thruput** — bursts/1k cyc, two disjoint pairs concurrently
- **aggregate thruput** — bursts/1k cyc, all pairs
- **beat rate** — data beats/1k cyc

## d_nw03 — output-queued AXI-Stream switch

| design | correctness | area (µm²) | power (mW) | Fmax (MHz) | beats | cycles | wait.max | notes |
|---|---|---|---|---|---|---|---|---|
| **reference** | **8/8 pass** | — | — | — | 14633 | 8183 | 41 |  |
| **reference** | **8/8 pass** | — | — | — | 14856 | 7940 | 0 |  |
| `chat` | **8/8 pass** | — | — | — | 18240 | 7937 | 0 |  |
| `claude` | **8/8 pass** | — | — | — | 18240 | 7945 | 54 |  |
| `gemini` | **8/8 pass** | — | — | — | 21404 | 8271 | 54 |  |
| `nc_a_reset_polarity` | 0/8 FAIL | — | — | — | 0 | 7834 | 0 |  |
| `nc_b_outputs_serialised` | 6/8 FAIL | — | — | — | 7079 | 7983 | 9 |  |

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

Rows below answer task text `621b30d2f397d8e9` (spec + the prompt the
model is handed). A submission scored against a different
prompt is a different question and is not listed.

| testbench | tells correct from broken | accepts correct design | accepts 2nd implementation | accepts legal variants | catches faults | notes |
|---|---|---|---|---|---|---|
| `stream_realign_tb` | — | *not scored against this prompt* | — | — | — | last run answered task text `df21476af2453246` |
| `chat` | — | *not scored against this prompt* | — | — | — | last run answered task text `c53e9bdba7ff4d52` |
| `claude` | — | *not scored against this prompt* | — | — | — | last run answered task text `c53e9bdba7ff4d52` |
| `gemini` | — | *not scored against this prompt* | — | — | — | last run answered task text `c53e9bdba7ff4d52` |

## v_ca03 — AXI ID-width converter

Rows below answer task text `a04f965ad7552b22` (spec + the prompt the
model is handed). A submission scored against a different
prompt is a different question and is not listed.

| testbench | tells correct from broken | accepts correct design | accepts 2nd implementation | accepts legal variants | catches faults | notes |
|---|---|---|---|---|---|---|
| `id_width_conv_spec_tb` | — | *not scored against this prompt* | — | — | — | last run answered task text `c328435ef50f48b2` |
| `chat` | — | *not scored against this prompt* | — | — | — | last run answered task text `c328435ef50f48b2` |
| `claude` | — | *not scored against this prompt* | — | — | — | last run answered task text `c328435ef50f48b2` |
| `gemini` | — | *not scored against this prompt* | — | — | — | last run answered task text `c328435ef50f48b2` |

## v_ca04 — stream crossbar

Rows below answer task text `95264ace42e3171a` (spec + the prompt the
model is handed). A submission scored against a different
prompt is a different question and is not listed.

| testbench | tells correct from broken | accepts correct design | accepts 2nd implementation | accepts legal variants | catches faults | notes |
|---|---|---|---|---|---|---|
| `chat` | — | *not scored against this prompt* | — | — | — | last run answered task text `d1875a47216e3205` |
| `claude` | — | *not scored against this prompt* | — | — | — | last run answered task text `d1875a47216e3205` |
| `gemini` | — | *not scored against this prompt* | — | — | — | last run answered task text `d1875a47216e3205` |

## v_ca05 — tag tracker (out-of-order queue)

Rows below answer task text `fd2ae1ad9bf3719d` (spec + the prompt the
model is handed). A submission scored against a different
prompt is a different question and is not listed.

| testbench | tells correct from broken | accepts correct design | accepts 2nd implementation | accepts legal variants | catches faults | notes |
|---|---|---|---|---|---|---|
| `chat` | — | *not scored against this prompt* | — | — | — | last run answered task text `7e7f9d22bce28ef5` |
| `claude` | — | *not scored against this prompt* | — | — | — | last run answered task text `7e7f9d22bce28ef5` |
| `deepseek` | — | *not scored against this prompt* | — | — | — | last run answered task text `7e7f9d22bce28ef5` |
| `gemini` | — | *not scored against this prompt* | — | — | — | last run answered task text `7e7f9d22bce28ef5` |
| `qwen` | — | *not scored against this prompt* | — | — | — | last run answered task text `7e7f9d22bce28ef5` |

## v_dsp02 — FP non-computational ops

Rows below answer task text `eacc3c043e2a5767` (spec + the prompt the
model is handed). A submission scored against a different
prompt is a different question and is not listed.

| testbench | tells correct from broken | accepts correct design | accepts 2nd implementation | accepts legal variants | catches faults | notes |
|---|---|---|---|---|---|---|
| `fp_noncomp_spec_tb` | — | *not scored against this prompt* | — | — | — | last run answered task text `f4632c28f77b5168` |
| `chat` | — | *not scored against this prompt* | — | — | — | last run answered task text `c2429e4f2fc3e2e1` |
| `claude` | — | *not scored against this prompt* | — | — | — | last run answered task text `c2429e4f2fc3e2e1` |
| `deepseek` | — | *not scored against this prompt* | — | — | — | last run answered task text `c2429e4f2fc3e2e1` |
| `gemini` | — | *not scored against this prompt* | — | — | — | last run answered task text `c2429e4f2fc3e2e1` |
| `qwen` | — | *not scored against this prompt* | — | — | — | last run answered task text `c2429e4f2fc3e2e1` |

## v_nw02 — AXI atomic-op filter

Rows below answer task text `03a3290cdd6034de` (spec + the prompt the
model is handed). A submission scored against a different
prompt is a different question and is not listed.

| testbench | tells correct from broken | accepts correct design | accepts 2nd implementation | accepts legal variants | catches faults | notes |
|---|---|---|---|---|---|---|
| `atop_filter_tb` | — | *not scored against this prompt* | — | — | — | last run answered task text `6dee1aa1ade3e882` |
| `chat` | — | *not scored against this prompt* | — | — | — | last run answered task text `6dee1aa1ade3e882` |
| `claude` | — | *not scored against this prompt* | — | — | — | last run answered task text `6dee1aa1ade3e882` |
| `gemini` | — | *not scored against this prompt* | — | — | — | last run answered task text `6dee1aa1ade3e882` |

## v_nw03 — frame-arbitrating stream mux

Rows below answer task text `839999302366fa24` (spec + the prompt the
model is handed). A submission scored against a different
prompt is a different question and is not listed.

| testbench | tells correct from broken | accepts correct design | accepts 2nd implementation | accepts legal variants | catches faults | notes |
|---|---|---|---|---|---|---|
| `frame_arb_mux_spec_tb` | — | *not scored against this prompt* | — | — | — | last run answered task text `cea417c3c55f160d` |
| `chat` | — | *not scored against this prompt* | — | — | — | last run answered task text `fe8126ce163812aa` |
| `claude` | — | *not scored against this prompt* | — | — | — | last run answered task text `fe8126ce163812aa` |
| `deepseek` | — | *not scored against this prompt* | — | — | — | last run answered task text `fe8126ce163812aa` |
| `gemini` | — | *not scored against this prompt* | — | — | — | last run answered task text `fe8126ce163812aa` |
| `qwen` | — | *not scored against this prompt* | — | — | — | last run answered task text `fe8126ce163812aa` |

## v_nw04 — PTP time base

Rows below answer task text `8f022b11a86a7769` (spec + the prompt the
model is handed). A submission scored against a different
prompt is a different question and is not listed.

| testbench | tells correct from broken | accepts correct design | accepts 2nd implementation | accepts legal variants | catches faults | notes |
|---|---|---|---|---|---|---|
| **reference testbench** | yes | yes | yes | 1/1 | **10/10** | establishes the ceiling |
| `ChatGPT 5.6 Sol` | **no** | **no** | **no** | 0/1 | *withheld* | **INVALID** — same verdict on the golden DUT and on a deliberately broken one (golden=FAIL, broken=FAIL), so it is not measuring the design under test. Excluded from scoring (rule 23) |
| `Claude Opus 5` | **no** | **no** | yes | 1/1 | *withheld* | **INVALID** — same verdict on the golden DUT and on a deliberately broken one (golden=FAIL, broken=FAIL), so it is not measuring the design under test. Excluded from scoring (rule 23) |
| `Gemini 3.1 Pro` | **no** | **did not compile** | n/a | n/a | n/a | the testbench itself does not build |

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

