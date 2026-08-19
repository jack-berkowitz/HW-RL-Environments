# HW-RL-Environments

A benchmark measuring whether language models can do two distinct jobs in RTL design:

1. **Design tasks** — write synthesisable SystemVerilog from a written specification, then be measured on correctness *and* on area, power and maximum frequency after a real place-and-route flow.
2. **Verification tasks** — write a self-checking testbench from a written specification, **never seeing the RTL**, then be measured on whether it accepts correct hardware and rejects faulty hardware.

The two are reported separately and never averaged. A testbench has no area; a design has no fault-detection rate. A single figure of merit would have to weight those against each other, and nothing here establishes those weights.

---

## Results at a glance

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/assets/funnel_dark.svg">
  <img alt="Cumulative stages, design and verification side by side. Design: 12 submitted, 7 compiled, 6 correct, 6 produced a PPA number. Verification: 12 submitted, 11 compiled, 6 accepted all correct hardware, 6 produced a fault count." src="docs/assets/funnel_light.svg" width="100%">
</picture>

**Most submissions do not reach a score, and they fail early.** Of 12 design submissions, **5 never compiled at all** and a sixth compiled but failed its contract — so half never reached a PPA number. The verification half is healthier on compilation, 11 of 12, but only 6 clear the validity gate: the rest reject some of the correct hardware they were supposed to accept.

Where numbers do exist, the picture is mixed rather than uniformly poor. On the CDC FIFO all four models are functionally correct across every legal configuration and land within 1.2 % of each other on area. On the FP32 multiply-add and the AXI crossbar the gap to the reference is large — 6.4× and 13.9× the area respectively — and on the crossbar the submission also runs at 111 MHz against the reference's 190.

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/assets/verification_faults_dark.svg">
  <img alt="Seeded faults detected by each of the 12 verification submissions, against a ceiling of 10 shown as a dashed line per task. v_ca05: ChatGPT 5.6 Sol 10 of 10; Gemini 3.1 Pro and Qwen 3.7 Plus not scoreable for rejecting a legal variant; DeepSeek V4 Pro not scoreable for rejecting the golden DUT. v_nw03: ChatGPT 5.6 Sol 9, Gemini 3.1 Pro 9, DeepSeek V4 Pro 6; Qwen 3.7 Plus not scoreable. v_dsp02: ChatGPT 5.6 Sol 9, DeepSeek V4 Pro 8; Gemini 3.1 Pro not scoreable; Qwen 3.7 Plus did not compile." src="docs/assets/verification_faults_light.svg" width="100%">
</picture>

---

## Design results

Every design that ran appears, including the reference implementation each task is anchored on. What each block does, and where that hardware is used in real silicon, is described in [The tasks, and where this hardware is used](#the-tasks-and-where-this-hardware-is-used) below.

**Read the clock period before comparing areas.** Area is meaningless without the frequency it was achieved at — a design synthesised at a slower clock is smaller for that reason alone.

### d_dsp02 — FP32 fused multiply-add

| Design | Correctness | Built at | Area (µm²) | Power (mW) | Own Fmax (MHz) | Latency (cycles) | Throughput |
|---|---|---|---|---|---|---|---|
| reference | 1/1 | **20.25 ns** | **59,890** | 72.2 | 78.0 | 3 | 1 result/cycle |
| ChatGPT 5.6 Sol | 1/1 | **20.25 ns** | **360,899** | 443.0 | 49.4 | 3 | 1 result/cycle |
| Gemini 3.1 Pro | **fails at vector 4** (a=1.0, b=0) | — | — | — | — | — | — |
| DeepSeek V4 Pro | **did not build** | — | 0 | 0 | 0 | — | — |
| Qwen 3.7 Plus | **did not build** | — | 0 | 0 | 0 | — | — |

**Latency** is clocks from accepting an operation to its result; **throughput** is how often a new operation can be accepted — 1 result/cycle means fully pipelined, so a result emerges every cycle after the first. The specification fixes throughput at 1 and deliberately leaves latency free, so a design may pipeline as deeply as it likes.

**20.25 ns is ChatGPT's own maximum frequency and the slower of the two**, so it is the clock both designs close at — the reference with 3.27 ns of slack, the submission with 0.12 ns. At that point the submitted FMA is **6.0× the area and 6.1× the power** of the reference.

The gap decomposes not to the multiplier — 485 versus 486 full adders, essentially identical — but to unshared shifters: 7.9× the muxes and 8× the half-adders. The arithmetic core is right; the structure around it duplicates hardware the reference reuses.

> An earlier published figure of 440,336 µm² (a 6.4× ratio) came from a build at the reference's 12.8125 ns that **missed timing by 0.697 ns**, and has been withdrawn. It described the design at a clock it cannot run at.

### d_nw01 — AXI4 crossbar

| Design | Correctness | Built at | Area (µm²) | Power (mW) | Own Fmax (MHz) |
|---|---|---|---|---|---|
| reference | 16/16 configs | **9.0 ns** | **146,932** | 48.6 | 190.5 |
| ChatGPT 5.6 Sol | 16/16 configs | **9.0 ns** | **2,086,235** | 448.0 | 111.1 |
| Gemini 3.1 Pro | **did not build** | — | 0 | 0 | — |
| DeepSeek V4 Pro | **did not build** | — | 0 | 0 | — |
| Qwen 3.7 Plus | **did not build** | — | 0 | 0 | — |

**9.0 ns is the clock both designs can close** — ChatGPT's crossbar reaches 111.1 MHz, the reference 190.5 MHz, so the slower of the two sets the comparison point. Both close timing there, so these two numbers are directly comparable.

**The submitted crossbar is 14.2× the area and 9.2× the power of the reference.** That is the largest gap on any task here, and unlike the CDC FIFO it is not a specialisation trade — the reference is the general, parameterisable design and it is still the far smaller one.

Three of the four models did not produce a crossbar that builds at all, which is itself the headline: an AXI4 crossbar has to hold ordering rules across several masters and slaves simultaneously, and it is the task in this set where submissions most often fail before reaching measurement.

An earlier figure of 2,141,894 µm² has been **withdrawn**: it came from a build at the reference's 5.25 ns that missed timing by 3.03 ns, describing a design at a clock it cannot run at. Area, power and period are reported here at one clock every design closes.

#### Outstanding-transaction capacity

An AXI master can have several read requests in flight at once. **Outstanding capacity** is how many the crossbar will accept before it stops granting — it is a buffering choice, not a quality score. More outstanding transactions hide more memory latency, and cost area and power to store. Neither end of the range is "better"; the number is only meaningful next to the area it cost.

Capacity is measured by offering **K distinct AXI IDs** and counting accepted requests. **A design's real capacity is the value at which that count stops rising with K.** While it is still rising, the number is describing the test, not the hardware.

| What was measured | K=1 | 2 | 4 | 8 | 16 | Stops rising? |
|---|---|---|---|---|---|---|
| **Reference** — PULP `axi_xbar`, as configured in the table above (`CUT_ALL_AX`) | 9 | 15 | 27 | 51 | 99 | **no** |
| Same reference, pipelining turned off (`NO_LATENCY`) | 7 | 13 | 25 | 49 | 97 | **no** |
| Second source — an independently written crossbar | 8 | 8 | 8 | 8 | 8 | **yes — 8** |
| ChatGPT 5.6 Sol | 8 | 8 | 8 | 8 | 8 | **yes — 8** |
| `mX1` — deliberately broken crossbar | 8 | 8 | 8 | 8 | 8 | **yes — 8** |
| `mCAP1` — deliberately broken crossbar | 1 | 1 | 1 | 1 | 1 | **yes — 1** |

**The two reference rows are one design, not two.** Both are the same vendored PULP `axi_xbar`; they differ only in a configuration switch for how much pipelining it inserts. The first row is the configuration used everywhere else in this README. The gap between them is exactly **2 at every K**, so that switch is worth a constant 2 outstanding requests regardless of the test.

**The "second source" is a second correct implementation of the same specification**, written independently so that a checker cannot be quietly fitted to one design's habits. It is not a competitor and it is not scored; it exists to catch a checker that only works on the reference.

**`mX1` and `mCAP1` are deliberately broken designs** — seeded faults used to prove the checker can detect a problem at all. `mCAP1` accepts only one request at a time, which is the failure the capacity check exists to catch, and the check does catch it. A test that nothing fails is not evidence that anything passed.

**The reference has no capacity figure here, and its 99 is not a win.** It never stops rising, because the test runs out of distinct AXI IDs before the hardware runs out of buffering — the ID field is 4 bits, so 16 IDs is the ceiling of the *stimulus*, not of the design. 99 is a lower bound at 16 IDs. It is deliberately not placed in the same column as the four figures that did stop rising, because those are properties of the hardware and this one is not.

### d_ca04 — asynchronous CDC FIFO

**Every design below is built at the same 4.5 ns and closes timing there**, so area and power are directly comparable. 4.5 ns is ChatGPT's maximum frequency and the slowest of the four — all four sweeps are now measured, so this is the one clock every model demonstrably meets, not an assumption.

| Design | Correctness | Area (µm²) | Power (mW) | Own Fmax (MHz) |
|---|---|---|---|---|
| reference | 18/18 configs | 19,887 | 12.9 | **380.9** |
| ChatGPT 5.6 Sol | 18/18 configs | 14,685 | 7.30 | 222.2 |
| DeepSeek V4 Pro | 18/18 configs | 14,589 | 7.45 | 273.5 |
| Gemini 3.1 Pro | 18/18 configs | 14,515 | 7.12 | 273.5 |
| Qwen 3.7 Plus | 18/18 configs | **14,176** | 7.85 | 273.5 |

**All four models pass every one of the 18 legal parameter combinations, and all four are 26–29 % smaller and roughly 40 % lower power than the reference at the same clock.** They cluster tightly — 14,176 to 14,685 µm², a 3.6 % spread — which suggests they are converging on a similar structure rather than one model finding something the others missed.

The reference wins the axis they lose: it closes at **380.9 MHz**, where three of the four models reach 273.5 MHz and ChatGPT 222.2 MHz. That is the trade, and it is a reasonable one — the vendored design buys speed with area, the models buy area with speed. Neither is "better" without a target frequency to judge against.

*Own Fmax is each design's own maximum, from its own sweep. It is reported for context and is not a like-for-like column — each figure comes from a different clock.*

#### Why the reference is larger, and why that is not a defect

The gap is **structural, not timing pressure**. Relaxing the reference's clock from 2.625 ns to 4.5 ns — a 71 % longer period, far more slack for the synthesiser to trade area against — shrank it by **1.1 %**, from 20,101 to 19,887 µm². It is not big because it is being pushed hard; it is big because of what it contains.

The post-route cell counts say where it goes:

| | reference | Qwen 3.7 Plus | ChatGPT 5.6 Sol |
|---|---|---|---|
| sequential cells (flip-flops) | 346 | 280 | 288 |
| combinational cells | **666** | 142 | 158 |
| total standard cells | 3,212 | 1,958 | 2,072 |

**Storage is nearly the same — combinational logic is 4.2–4.7× larger.** The models did not omit the buffering; they omitted the surrounding structure. Three things account for it, all visible in the source:

- **A generic payload type.** `cdc_fifo_gray` is declared `parameter type T`, so it must work for arbitrary structs, not just a 32-bit word. Generic width costs muxing that a fixed-width design never pays.
- **Six separate Gray↔binary conversion blocks**, three per clock domain, instantiated as standalone modules. A hand-written FIFO for one width typically folds these into the pointer logic.
- **Two spill registers** on the output path. These are why the reference accepts **10** beats before backpressure where the candidates accept 8 — an extra pipeline stage that buys the frequency headroom showing up in its 380.9 MHz.

So the reference is a **library component**: parameterisable over payload type and depth, pipelined for a high clock, and reusable across a whole SoC. The models wrote a **point solution** — one width, one depth, one clock target — and a point solution is legitimately smaller. Reading the 26–29 % as "the models beat the reference" would be reading a specialised design against a general one and calling the specialisation a win.

What the comparison does show is that all four models produce correct, synthesisable, competitively-sized hardware for a fixed specification. That is a real result. It is just not the same claim as being better than the library.

---

## How a verification submission is judged

The order matters. Fault detection is only meaningful *after* the testbench is shown to be valid.

| Stage | Question | Why it gates the next |
|---|---|---|
| 1. **Validity gate — golden DUT** | Does it accept a known-correct implementation? | A testbench that rejects correct hardware is unusable no matter what else it catches. |
| 2. **Validity gate — second DUT** | Does it accept an *independent* correct implementation with different internals? | Passing the reference alone cannot distinguish a testbench that checks the *specification* from one fitted to how one implementation happens to work. |
| 3. **Validity gate — conformant perturbations** | Does it accept variants that differ only where the spec is deliberately silent? | Rejecting one means it checked something the spec never promised. |
| 4. **Fault detection** | How many seeded faults does it catch, out of the ceiling? | Reported per fault, never as a rate. |

**A fault count from a testbench that failed the gate is withheld, not printed.** A testbench that rejects everything appears to catch everything. Publishing "5 of 10 caught" next to a genuine 5 of 10 would be a number that looks like a measurement and is not.

**A hang is not a catch.** If the simulation times out, the testbench did not detect the fault — it stopped.

### Verification results

Ceiling = what the task's own reference testbench achieves, shown as the dashed line on the chart above. Every seeded fault is proven catchable. The reference is not a submission and is not counted among the twelve.

| Task | Testbench | Accepts correct DUT | Accepts 2nd impl. | Accepts legal variants | Faults caught |
|---|---|---|---|---|---|
| **v_ca05** tag tracker | *reference (ceiling)* | yes | yes | 4/4 | **10/10** |
| | ChatGPT 5.6 Sol | yes | yes | 4/4 | **10/10** — matches the ceiling |
| | Gemini 3.1 Pro | yes | yes | **3/4** | *withheld* |
| | Qwen 3.7 Plus | yes | yes | **3/4** | *withheld* |
| | DeepSeek V4 Pro | **no** | no | 0/4 | *withheld* |
| **v_nw03** stream mux | *reference (ceiling)* | yes | yes | 5/5 | **10/10** |
| | ChatGPT 5.6 Sol | yes | yes | 5/5 | **9/10** |
| | Gemini 3.1 Pro | yes | yes | 5/5 | **9/10** |
| | DeepSeek V4 Pro | yes | yes | 5/5 | 6/10 |
| | Qwen 3.7 Plus | **no** | no | 0/5 | *withheld* |
| **v_dsp02** FP non-computational | *reference (ceiling)* | yes | yes | 5/5 | **10/10** |
| | ChatGPT 5.6 Sol | yes | yes | 5/5 | **9/10** |
| | DeepSeek V4 Pro | yes | yes | 5/5 | 8/10 |
| | Gemini 3.1 Pro | **no** | no | 1/5 | *withheld* |
| | Qwen 3.7 Plus | *did not compile* | — | — | *withheld* |

**Six of twelve submissions now clear the validity gate**, and five produce a fault count at or near the ceiling: ChatGPT 5.6 Sol reaches **10/10 on v_ca05**, and ChatGPT 5.6 Sol and Gemini 3.1 Pro both reach **9/10 on v_nw03**, with ChatGPT 5.6 Sol at **9/10 on v_dsp02**. Each of those accepted the golden DUT, an independent second implementation, and every legal variant before any fault count was reported.

Two failure modes remain visible and are worth separating. **DeepSeek V4 Pro** on v_ca05 and **Qwen 3.7 Plus** on v_nw03 **reject the golden DUT outright** — they would reject correct hardware. **Gemini 3.1 Pro** and **Qwen 3.7 Plus** on v_ca05 do something subtler: they accept the golden DUT and the second implementation, then reject one legal variant (`tt_c4_pop_gnt_delayed`), meaning they check something the specification never promised. Both cases have their fault counts withheld, for the same reason — a testbench that rejects some correct hardware rejects faulty hardware for the wrong reasons too.

---

## The tasks, and where this hardware is used

Reference for the results above. Six tasks across three domains, every one anchored on a real, widely deployed open-source IP block rather than a toy — the reference implementation is vendored from upstream at a pinned commit, so "correct" means agreeing with hardware that people actually tape out.

### Computer architecture — the plumbing inside a CPU or SoC

| Task | Block | What it does | Where you find it | Upstream anchor |
|---|---|---|---|---|
| **d_ca04** *design* | Asynchronous CDC FIFO | Moves data between two unrelated clocks without corrupting it | Any chip with more than one clock — which is nearly all of them. The classic source of bugs that appear only in silicon | `pulp-platform/common_cells` |
| **v_ca05** *verification* | Tag tracker / ID queue | Tracks outstanding transactions so out-of-order responses can be matched to requests | Cache controllers, memory controllers, any out-of-order interconnect | `pulp-platform/common_cells` |

### DSP — floating-point arithmetic

| Task | Block | What it does | Where you find it | Upstream anchor |
|---|---|---|---|---|
| **d_dsp02** *design* | FP32 fused multiply-add | Computes `a×b+c` in one rounding step, one result per cycle | The core operation of every ML accelerator and GPU shader; the bulk of the silicon in a matrix engine | `pulp-platform/cvfpu` |
| **v_dsp02** *verification* | FP non-computational ops | Sign manipulation, comparison, min/max, classification — the IEEE-754 operations that move bits rather than compute | Every FPU. Individually simple, collectively full of edge cases: NaN, signed zero, subnormals | `pulp-platform/cvfpu` |

### Networking — on-chip interconnect

| Task | Block | What it does | Where you find it | Upstream anchor |
|---|---|---|---|---|
| **d_nw01** *design* | AXI4 crossbar | Routes transactions between several masters and several slaves, keeping AXI's ordering rules | The backbone of essentially every ARM-based SoC | `pulp-platform/axi` |
| **v_nw03** *verification* | Frame-arbitrating stream mux | Merges several AXI-Stream inputs into one without interleaving packets | NIC datapaths, video pipelines, anything moving framed data | `alexforencich/verilog-axis` |

These are deliberately not textbook exercises. They are blocks with real specifications, real edge cases, and a known-correct implementation to measure against — which is what makes a wrong answer detectable rather than a matter of taste.

---

## Repository layout

```
domains/<domain>/design/<task>/        design tasks: spec, ref, tb, mutants, orfs
domains/<domain>/verification/<task>/  verification tasks: spec, dut, dut2,
                                       conformant, mutants, probe (the prompt)
candidates/<task>/<model>.sv           submissions as received
runs/<task>/<timestamp>__<label>.json  immutable run records
refs/                                  vendored external RTL (pinned in refs.lock)
scripts/                               harness — simulation, PPA, reporting
RULES.md  FINDINGS.md  CONVENTIONS.md  methodology
results_table.md / .txt                generated report
```

## Reproducing

Requires **Verilator 5.046** and Docker for the OpenROAD flow.

Verilator is the simulator of record for every scored result. Synthesis uses **slang** inside the OpenROAD container, so a design slang rejects can never produce a PPA number — that is why some submissions are recorded as not building even though a simulator would accept them. Icarus Verilog is kept on the side as a debugging aid for awkward candidate submissions; nothing scored depends on it.

> **On formal methods:** the `openroad/orfs` image ships `sby` and `eqy` but **no SMT solver** — not yices, z3, boolector, bitwuzla, cvc5 or mathsat. The `smtbmc` engine has therefore never been runnable here. The only working engine is `abc bmc3` on the bundled `yosys-abc`, so every equivalence result in this project is **bounded**, never an unbounded proof. `refs.lock`'s toolchain line overstates this; it is frozen, and the correction is recorded in [`CONVENTIONS.md`](CONVENTIONS.md).

```bash
python3 scripts/report_table.py > results_table.md
```

```bash
bash scripts/regression.sh
```

```bash
bash scripts/sim_verification.sh domains/comp_arch/verification/v_ca05_id_queue candidates/v_ca05/chat.sv chat
```

> **On an Apple Silicon host, the OpenROAD flow runs amd64 under Rosetta and dies at clock-tree synthesis with "child killed: illegal instruction" unless you pass `LEC_CHECK=0`.**

## Status and limits

This is active work, and several numbers are deliberately marked *unattested* rather than published as clean:

- **Cross-design area ratios are not established.** d_ca04's reference and candidates were built at different clock periods; d_dsp02 and d_nw01 match periods but have task-text-hash gaps that block a mechanical comparability assertion.
- **Outstanding-capacity is bounded by the harness, not the design, for any design that does not saturate.** `SLV_ID_W = 4` caps the stimulus at 16 distinct AXI IDs; a design still rising in K at that point has only a lower bound, and measuring it would need a wider ID field — a change to the interface, not to the stimulus.
- **The correctness checkers verify the functional half of CDC correctness only.** Synchroniser depth and whether crossings are constrained at all need static CDC analysis or formal methods, which are not in this harness.
- **Sample sizes are small** — four to six submissions per task, one attempt each, no temperature sweep. Treat individual model rankings as anecdotes; the *distribution of failure modes* is the durable result.

## Licence and third-party code

`refs/` vendors external RTL under its own licences — SHL-0.51, Apache-2.0, MIT, BSD and ISC — pinned by SHA in [`refs.lock`](refs.lock). Those licences and their attribution requirements govern that code.

> ⚠️ **Redistribution of this repository, including sending its contents to third-party model providers, has not been legally reviewed.** Get that review before any external distribution.
