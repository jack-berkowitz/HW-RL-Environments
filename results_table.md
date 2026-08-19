# Cross-model results

Three design tasks. Every design that was run appears, including the
reference implementation each task is anchored on.

**Per-axis only — there is deliberately no combined score.** A single
figure of merit would have to weight area against frequency against
capability, and nothing here establishes those weights.


## d_ca04 — asynchronous CDC FIFO

| design | correctness | area (µm²) | power (mW) | Fmax (MHz) | FIFO capacity | min crossing lat | max crossing lat | write stalls | notes |
|---|---|---|---|---|---|---|---|---|---|
| **reference** | **18/18 pass** | 19,887 | 12.9 | 380.9 | 10 | 3 | 74 | 11046 |  |
| `chat` | **18/18 pass** | 14,685 | 7.3 | 222.2 | 8 | 3 | 72 | 10914 |  |
| `deepseek` | **18/18 pass** | 14,589 | 7.5 | 273.5 | 8 | 2 | 72 | 10912 |  |
| `gemini` | **18/18 pass** | 14,515 | 7.1 | 273.5 | 8 | 2 | 72 | 10912 |  |
| `qwen` | **18/18 pass** | 14,176 | 7.8 | 273.5 | 8 | 2 | 72 | 10912 |  |

- **FIFO capacity** — beats accepted before backpressure
- **min crossing lat** — read-clock cycles, minimum. NOT a capability discriminator on its own: at the scored SYNC_STAGES=2 a design hardcoding two synchroniser flops reads identically to a correct one. The parameter is bound by the correctness sweep at SYNC_STAGES=3 (F49)
- **max crossing lat** — read-clock cycles, maximum
- **write stalls** — cycles the writer was blocked

## d_dsp02 — FP32 fused multiply-add

| design | correctness | area (µm²) | power (mW) | Fmax (MHz) | latency | init interval | notes |
|---|---|---|---|---|---|---|---|
| `chat` | **1/1 pass** | 360,899 | 443.0 | 49.4 | 3 | 1 |  |
| **reference** | **1/1 pass** | 59,890 | 72.2 | 78.0 | 3 | 1 |  |
| `gemini` | **FAILS** | n/a | n/a | n/a | n/a | n/a | **fails correctness** — fails the contract at vector 4 (a=1.0, b=0); no PPA, a number for a design that fails its contract is not a result |
| `deepseek` | **did not build** | **0** | **0** | **0** | n/a | n/a | **build failure** — does not compile; rejected by slang, the synthesis frontend (17 errors, Verilator 3) |
| `qwen` | **did not build** | **0** | **0** | **0** | n/a | n/a | **build failure** — does not compile; rejected by slang, the synthesis frontend (2 errors) |

- **latency** — clocks from accept to result
- **init interval** — clocks between accepts

## d_nw01 — AXI4 crossbar

| design | correctness | area (µm²) | power (mW) | Fmax (MHz) | capacity (C1) | 1-pair thruput | 2-pair thruput | aggregate thruput | beat rate | notes |
|---|---|---|---|---|---|---|---|---|---|---|
| **reference** | **16/16 pass** | 146,932 | 48.6 | 190.5 | 27 | 2997 | 5994 | 1998 | 332 |  |
| `chat` | **16/16 pass** | 2,086,235 | 448.0 | 111.1 | 8 | 599 | 1198 | 399 | 359 |  |
| `gemini` | **did not build** | **0** | **0** | **0** | n/a | n/a | n/a | n/a | n/a | **build failure** — anonymous struct as parameter value; rejected by slang, the synthesis frontend (13 errors) |
| `deepseek` | **did not build** | **0** | **0** | **0** | n/a | n/a | n/a | n/a | n/a | **build failure** — does not compile; rejected by slang, the synthesis frontend (5 errors) |
| `qwen` | **did not build** | **0** | **0** | **0** | n/a | n/a | n/a | n/a | n/a | **build failure** — does not compile; rejected by slang, the synthesis frontend (20 errors) |

- **capacity (C1)** — checker's C1 capacity measure, master 0 — units unresolved, see note
- **1-pair thruput** — bursts/1k cyc, one master-slave pair alone
- **2-pair thruput** — bursts/1k cyc, two disjoint pairs concurrently
- **aggregate thruput** — bursts/1k cyc, all pairs
- **beat rate** — data beats/1k cyc

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


## v_ca05 — tag tracker (out-of-order queue)

Rows below answer task text `7e7f9d22bce28ef5` (spec + the prompt the
model is handed). A submission scored against a different
prompt is a different question and is not listed.

| testbench | accepts correct design | accepts 2nd implementation | accepts legal variants | catches faults | notes |
|---|---|---|---|---|---|
| `tag_tracker_ref` | *not scored against this prompt* | — | — | — | last run answered task text `f2926d08631309ca` |
| `chat` | *not scored against this prompt* | — | — | — | last run answered task text `f2926d08631309ca` |
| `deepseek` | *not scored against this prompt* | — | — | — | last run answered task text `f2926d08631309ca` |
| `gemini` | *not scored against this prompt* | — | — | — | last run answered task text `f2926d08631309ca` |
| `qwen` | *not scored against this prompt* | — | — | — | last run answered task text `f2926d08631309ca` |

## v_nw03 — frame-arbitrating stream mux

Rows below answer task text `fe8126ce163812aa` (spec + the prompt the
model is handed). A submission scored against a different
prompt is a different question and is not listed.

| testbench | accepts correct design | accepts 2nd implementation | accepts legal variants | catches faults | notes |
|---|---|---|---|---|---|
| **reference testbench** | yes | yes | 5/5 | **10/10** | establishes the ceiling |
| `ChatGPT 5.6 Sol` | yes | yes | 5/5 | **9/10** |  |
| `DeepSeek V4 Pro` | yes | yes | 5/5 | **6/10** |  |
| `Gemini 3.1 Pro` | yes | yes | 5/5 | **9/10** |  |
| `Qwen 3.7 Plus` | **no** | **no** | 0/5 | *withheld* | rejects the correct design, so it rejects correct and faulty hardware alike — a fault count from it carries no information |

## v_dsp02 — FP non-computational ops

Rows below answer task text `c2429e4f2fc3e2e1` (spec + the prompt the
model is handed). A submission scored against a different
prompt is a different question and is not listed.

| testbench | accepts correct design | accepts 2nd implementation | accepts legal variants | catches faults | notes |
|---|---|---|---|---|---|
| **reference testbench** | yes | yes | 5/5 | **10/10** | establishes the ceiling |
| `ChatGPT 5.6 Sol` | yes | yes | 5/5 | **9/10** |  |
| `DeepSeek V4 Pro` | yes | yes | 5/5 | **8/10** |  |
| `Gemini 3.1 Pro` | **no** | **no** | 1/5 | *withheld* | rejects the correct design, so it rejects correct and faulty hardware alike — a fault count from it carries no information |
| `Qwen 3.7 Plus` | **did not compile** | n/a | n/a | n/a | the testbench itself does not build |

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

