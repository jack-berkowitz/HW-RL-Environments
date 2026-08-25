# HW-RL-Environments

A benchmark measuring whether language models can do two distinct jobs in RTL design:

1. **Design tasks**: write synthesisable SystemVerilog from a written specification, then be measured on correctness *and* on area, power and maximum frequency after a real place-and-route flow.
2. **Verification tasks**: write a self-checking testbench from a written specification, **never seeing the RTL**, then be measured on whether it accepts correct hardware and rejects faulty hardware.

The two are reported separately and never averaged. A testbench has no area; a design has no fault-detection rate. A single figure of merit would have to weight those against each other, and nothing here establishes those weights.

---

## Results at a glance

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/assets/funnel_dark.svg">
  <img alt="Cumulative stages, design and verification side by side. Design: submitted 28, compiled 1, correct 1, PPA measured 17. Verification: submitted 36, compiled 31, tells correct from broken 18, fault count 15." src="docs/assets/funnel_light.svg" width="100%">
</picture>

**Most submissions do not reach a score, and they fail early.** The design half
of that chart is currently a supersession artefact rather than a result: the
design specifications were revised to state their grading criteria, so every
design submission on record answers a prompt that no longer exists and renders
as unscoreable until the tasks are re-solicited. See *Design results* below.

Of 36 verification submissions, 5 do not compile; of the 31 that build,
18 tell a correct design from a deliberately broken one, and 15 end with a
fault count. **That gate is the binding constraint on this half.** A testbench that
fails it returns the same verdict on correct and broken hardware, and every one that does so here rejects
the correct design too, so it rejects everything and its fault count carries no
information.

Where a testbench does clear the gate it usually scores near the ceiling, so the
distribution is bimodal rather than centred on a middling value. Where PPA
exists, the gap to the reference is large and not uniform: on the CDC FIFO the
submissions are 26 to 29 % smaller at the same clock, trading frequency for area,
while on the AXI crossbar the one measured submission is 14.2× the reference's
area and slower.

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/assets/verification_faults_dark.svg">
  <img alt="Seeded faults detected by each verification submission, against the ceiling its task's reference testbench achieves, shown as a dashed line per task. v_ai02: ChatGPT 5.6 Sol 2 of 10; Claude Opus 5 4 of 10; Gemini 3.1 Pro 2 of 10. v_ca03: ChatGPT 5.6 Sol not scoreable (invalid); Claude Opus 5 not scoreable (invalid); Gemini 3.1 Pro 4 of 10. v_ca04: ChatGPT 5.6 Sol not scoreable (invalid); Claude Opus 5 6 of 10; Gemini 3.1 Pro 0 of 10. v_ca05: ChatGPT 5.6 Sol 6 of 10; Claude Opus 5 not scoreable (gate); DeepSeek V4 Pro not scoreable (nobuild); Gemini 3.1 Pro not scoreable (gate); Qwen 3.7 Plus not scoreable (nobuild). v_ca06: Claude Opus 5 not scoreable (invalid). v_dsp02: ChatGPT 5.6 Sol 2 of 10; Claude Opus 5 10 of 10; DeepSeek V4 Pro 0 of 10; Gemini 3.1 Pro not scoreable (invalid); Qwen 3.7 Plus not scoreable (nobuild). v_nw01: ChatGPT 5.6 Sol not scoreable (invalid); Claude Opus 5 not scoreable (invalid); Gemini 3.1 Pro not scoreable (invalid). v_nw02: _negctl_null 0 of 8; ChatGPT 5.6 Sol not scoreable (invalid); Claude Opus 5 10 of 10; Gemini 3.1 Pro not scoreable (invalid). v_nw03: ChatGPT 5.6 Sol 10 of 10; Claude Opus 5 10 of 10; DeepSeek V4 Pro 4 of 10; Gemini 3.1 Pro not scoreable (invalid); Qwen 3.7 Plus not scoreable (invalid). v_nw04: _negctl_null not scoreable (invalid); ChatGPT 5.6 Sol not scoreable (gate); Claude Opus 5 8 of 10; Gemini 3.1 Pro not scoreable (invalid)." src="docs/assets/verification_faults_light.svg" width="100%">
</picture>

---

## Design results

**Withheld pending re-solicitation.** Every design task's specification was
revised to state its grading criteria — what correctness gates, which PPA axes
are compared, at what clock, and which levers the contract has already spent.
That changed every design `task_text_hash`, so every candidate on record answers
a superseded prompt and no design number here is currently scoreable:

| task | prompt then | prompt now |
|---|---|---|
| d_ca01 | `77229cda1b6cd7c3` | `7e0c51b2fd28d3c5` |
| d_ca04 | `5c9a12842b8b0c7d` | `353f11388a6d579d` |
| d_dsp01 | *(no prompt)* | `18c2e731034e5c5e` |
| d_dsp02 | `617eb4240908e773` | `aff15b9eeb69e6cd` |
| d_dsp03 | `8eb2ae18667fe22a` | `51a7fa04a20938a3` |
| d_nw01 | `96c1a3ad5854776a` | `05379ddae2650498` |
| d_nw03 | `b02da2223907630b` | `27a4c81ec39cddf7` |

The tables that stood here are not archived in this file because they would read
as results. They are in git history, and every run record behind them is still on
disk under `runs/`, stamped with the prompt it answered — which is what makes
this supersession visible rather than silent.

Two of those numbers are worth naming, because they are why the revision
happened rather than an accident of it. d_nw01's largest submission measured
2,086,235 µm² against a 146,932 µm² reference, and d_ca01's measured 753,209 µm².
Both were buffering storage the contract never asked for. The specifications now
bound that storage by clause, and separately now say what the submission is being
compared on — neither of which they did when those designs were solicited.

`results_table.md` is generated from the run records and renders each superseded
row as *not scored against this prompt*, naming the hash it answered. The
verification side below is unaffected: those tasks were not changed.


### How design choices are separated from implementation quality

Area is only comparable at a shared clock, and only between designs that made the
same free choices. Each design task declares its metrics with a role:

- **fixed** the specification requires a value; deviating is a spec violation.
- **choice** the specification leaves it free and it moves PPA. Where a
  submission chose differently from the reference, the report marks the area
  ratio **not like-for-like** rather than presenting it as a quality gap.
- **capability** more is better and area buys it. Reported raw and per unit,
  because raw area credits a design for being small when it was doing less.

There is deliberately no combined score. Nothing here establishes what a beat of
FIFO capacity is worth in µm².

---

## Verification results

One table per task, three columns, in the order a testbench has to earn them.

**Passes golden, fails broken HW** is the gate: every testbench runs against the
correct DUT and against one with every output tied high, and must pass the first
and fail the second. Returning the same verdict on both means
it is not observing the design, so its fault count is withheld rather than
printed. A file that drives nothing and prints `PASS` scores 0 here.

The ceiling is what each task's own reference testbench achieves, which proves
every seeded fault is findable.

### v_dsp02: FP non-computational ops (ceiling 10/10)

| Submission | Passes golden, fails broken HW | Accepts other correct designs | Faults caught |
|---|---|---|---|
| ChatGPT 5.6 Sol | yes | yes (5/5) | 2/10 |
| Claude Opus 5 | yes | yes (5/5) | **10/10** |
| Gemini 3.1 Pro | **no** | **no** (1/5) | *withheld* |
| DeepSeek V4 Pro | yes | yes (5/5) | 0/10 |
| Qwen 3.7 Plus | did not compile | did not compile | |

### v_nw03: frame-arbitrating stream mux (ceiling 10/10)

| Submission | Passes golden, fails broken HW | Accepts other correct designs | Faults caught |
|---|---|---|---|
| ChatGPT 5.6 Sol | yes | yes (5/5) | **10/10** |
| Claude Opus 5 | yes | yes (5/5) | **10/10** |
| Gemini 3.1 Pro | **no** | **no** (0/5) | *withheld* |
| DeepSeek V4 Pro | yes | yes (5/5) | 4/10 |
| Qwen 3.7 Plus | **no** | **no** (0/5) | *withheld* |

### v_ca05: tag tracker (ceiling 10/10)

| Submission | Passes golden, fails broken HW | Accepts other correct designs | Faults caught |
|---|---|---|---|
| ChatGPT 5.6 Sol | yes | yes (4/4) | 6/10 |
| Claude Opus 5 | yes | **partial** (3/4) | *withheld* |
| Gemini 3.1 Pro | yes | **partial** (3/4) | *withheld* |
| DeepSeek V4 Pro | did not compile | did not compile | |
| Qwen 3.7 Plus | did not compile | did not compile | |

### v_nw01: ARP engine (ceiling 10/10)

| Submission | Passes golden, fails broken HW | Accepts other correct designs | Faults caught |
|---|---|---|---|
| ChatGPT 5.6 Sol | **no** | yes (1/1) | *withheld* |
| Claude Opus 5 | **no** | yes (1/1) | *withheld* |
| Gemini 3.1 Pro | **no** | **no** (0/1) | *withheld* |

### v_nw04: PTP time base (ceiling 10/10)

| Submission | Passes golden, fails broken HW | Accepts other correct designs | Faults caught |
|---|---|---|---|
| ChatGPT 5.6 Sol | yes | **no** (0/1) | *withheld* |
| Claude Opus 5 | yes | yes (1/1) | 8/10 |
| Gemini 3.1 Pro | **no** | **no** (0/1) | *withheld* |

### v_ca04: stream crossbar (ceiling 8/8)

| Submission | Passes golden, fails broken HW | Accepts other correct designs | Faults caught |
|---|---|---|---|
| ChatGPT 5.6 Sol | **no** | yes (1/1) | *withheld* |
| Claude Opus 5 | yes | yes (1/1) | 6/10 |
| Gemini 3.1 Pro | yes | yes (1/1) | 0/10 |

*The reference run behind this ceiling exercised 8 of the 10 mutants now declared; it predates the rest.*

### v_ca03: AXI ID-width converter (ceiling 10/10)

| Submission | Passes golden, fails broken HW | Accepts other correct designs | Faults caught |
|---|---|---|---|
| ChatGPT 5.6 Sol | **no** | **no** (1/5) | *withheld* |
| Claude Opus 5 | **no** | **no** (1/5) | *withheld* |
| Gemini 3.1 Pro | yes | yes (5/5) | 4/10 |

### v_nw02: AXI atomic-op filter (ceiling 10/10)

| Submission | Passes golden, fails broken HW | Accepts other correct designs | Faults caught |
|---|---|---|---|
| ChatGPT 5.6 Sol | **no** | **no** (0/1) | *withheld* |
| Claude Opus 5 | yes | yes (1/1) | **10/10** |
| Gemini 3.1 Pro | **no** | **no** (0/1) | *withheld* |

### v_ai02: byte-stream realignment (ceiling 10/10)

| Submission | Passes golden, fails broken HW | Accepts other correct designs | Faults caught |
|---|---|---|---|
| ChatGPT 5.6 Sol | yes | yes (1/1) | 2/10 |
| Claude Opus 5 | yes | yes (1/1) | 4/10 |
| Gemini 3.1 Pro | yes | yes (1/1) | 2/10 |

## The tasks, and where this hardware is used

Reference for the results above. Thirteen tasks across three domains, every one anchored on a real, widely deployed open-source IP block rather than a toy. The reference implementation is vendored from upstream at a pinned commit, so "correct" means agreeing with hardware that people actually tape out.

### Computer architecture: the plumbing inside a CPU or SoC

| Task | Block | What it does | Where you find it | Upstream anchor |
|---|---|---|---|---|
| **d_ca04** *design* | Asynchronous CDC FIFO | Moves data between two unrelated clocks without corrupting it | Any chip with more than one clock, which is nearly all of them. The classic source of bugs that appear only in silicon | `pulp-platform/common_cells` |
| **v_ca05** *verification* | Tag tracker / ID queue | Tracks outstanding transactions so out-of-order responses can be matched to requests | Cache controllers, memory controllers, any out-of-order interconnect | `pulp-platform/common_cells` |
| **d_ca01** *design* | Non-blocking data cache | Serves hits while misses are still outstanding, instead of stalling until each fill returns | Every performance CPU. The difference between a core that stalls on every miss and one that keeps working | `bespoke-silicon-group/basejump_stl` |
| **v_ca03** *verification* | AXI ID-width converter | Remaps wide master IDs onto a narrower slave ID space without breaking ordering | Any SoC joining subsystems whose ID widths disagree, which is most of them | `pulp-platform/axi` |
| **v_ca04** *verification* | Stream crossbar | Routes N stream inputs to M outputs with per-output arbitration | On-chip switch fabric, DMA engines, any many-to-many datapath | `pulp-platform/common_cells` |

### DSP: floating-point arithmetic

| Task | Block | What it does | Where you find it | Upstream anchor |
|---|---|---|---|---|
| **d_dsp02** *design* | FP32 fused multiply-add | Computes `a×b+c` in one rounding step, one result per cycle | The core operation of every ML accelerator and GPU shader; the bulk of the silicon in a matrix engine | `pulp-platform/cvfpu` |
| **v_dsp02** *verification* | FP non-computational ops | Sign manipulation, comparison, min/max, classification: the IEEE-754 operations that move bits rather than compute | Every FPU. Individually simple, collectively full of edge cases: NaN, signed zero, subnormals | `pulp-platform/cvfpu` |
| **d_dsp03** *design* | Multi-format FMA | One multiply-add datapath serving several floating-point widths | Mixed-precision ML accelerators, where fp32 and bf16 share hardware | `pulp-platform/cvfpu` |

### Networking: on-chip interconnect

| Task | Block | What it does | Where you find it | Upstream anchor |
|---|---|---|---|---|
| **d_nw01** *design* | AXI4 crossbar | Routes transactions between several masters and several slaves, keeping AXI's ordering rules | The backbone of essentially every ARM-based SoC | `pulp-platform/axi` |
| **v_nw03** *verification* | Frame-arbitrating stream mux | Merges several AXI-Stream inputs into one without interleaving packets | NIC datapaths, video pipelines, anything moving framed data | `alexforencich/verilog-axis` |
| **d_nw03** *design* | Output-queued stream switch | Switches AXI-Stream traffic with per-output queueing | Ethernet switch fabrics, NoC routers | `alexforencich/verilog-axis` |
| **v_nw02** *verification* | AXI atomic-op filter | Strips or absorbs AXI atomic operations a downstream slave cannot handle | SoCs mixing AXI5 masters with older slaves | `pulp-platform/axi` |
| **v_nw04** *verification* | PTP time base | Maintains a fractional-nanosecond clock that can be slewed and stepped | Time-synchronised Ethernet, IEEE 1588 endpoints | `alexforencich/verilog-ethernet` |

These are deliberately not textbook exercises. They are blocks with real specifications, real edge cases, and a known-correct implementation to measure against, which is what makes a wrong answer detectable rather than a matter of taste.

---

## Repository layout

```
domains/<domain>/design/<task>/        design tasks: spec, ref, tb, mutants, orfs
domains/<domain>/verification/<task>/  verification tasks: spec, dut, dut2,
                                       conformant, mutants, probe (the prompt)
candidates/<task>/<model>.sv           submissions as received
runs/<task>/<timestamp>__<label>.json  immutable run records
refs/                                  vendored external RTL (pinned in refs.lock)
scripts/                               harness: simulation, PPA, reporting
RULES.md  FINDINGS.md  CONVENTIONS.md  methodology
results_table.md / .txt                generated report
```

## Reproducing

Requires **Verilator 5.046** and Docker for the OpenROAD flow.

Verilator is the simulator of record for every scored result. Synthesis uses **slang** inside the OpenROAD container, so a design slang rejects can never produce a PPA number, which is why some submissions are recorded as not building even though a simulator would accept them. Icarus Verilog is kept on the side as a debugging aid for awkward candidate submissions; nothing scored depends on it.

> **On formal methods:** the `openroad/orfs` image ships `sby` and `eqy` but **no SMT solver**: not yices, z3, boolector, bitwuzla, cvc5 or mathsat. The `smtbmc` engine has therefore never been runnable here. The only working engine is `abc bmc3` on the bundled `yosys-abc`, so every equivalence result in this project is **bounded**, never an unbounded proof. `refs.lock`'s toolchain line overstates this; it is frozen, and the correction is recorded in [`CONVENTIONS.md`](CONVENTIONS.md).

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
- **Outstanding-capacity is bounded by the harness, not the design, for any design that does not saturate.** `SLV_ID_W = 4` caps the stimulus at 16 distinct AXI IDs; a design still rising in K at that point has only a lower bound, and measuring it would need a wider ID field: a change to the interface, not to the stimulus.
- **The correctness checkers verify the functional half of CDC correctness only.** Synchroniser depth and whether crossings are constrained at all need static CDC analysis or formal methods, which are not in this harness.
- **Sample sizes are small**: two to six submissions per task, one attempt each, no temperature sweep. Treat individual model rankings as anecdotes; the *distribution of failure modes* is the durable result.

## Licence and third-party code

`refs/` vendors external RTL under its own licences (SHL-0.51, Apache-2.0, MIT, BSD and ISC), pinned by SHA in [`refs.lock`](refs.lock). Those licences and their attribution requirements govern that code.

> ⚠️ **Redistribution of this repository, including sending its contents to third-party model providers, has not been legally reviewed.** Get that review before any external distribution.
