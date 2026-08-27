# HW-RL-Environments

A benchmark measuring whether language models can do two distinct jobs in RTL design:

1. **Design tasks**: write synthesisable SystemVerilog from a written specification, then be measured on correctness *and* on area, power and maximum frequency after a real place-and-route flow.
2. **Verification tasks**: write a self-checking testbench from a written specification, **never seeing the RTL**, then be measured on whether it accepts correct hardware and rejects faulty hardware.

The two are reported separately and never averaged. A testbench has no area; a design has no fault-detection rate. A single figure of merit would have to weight those against each other, and nothing here establishes those weights.

---

## Results at a glance

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/assets/funnel_dark.svg">
  <img alt="Cumulative stages, design and verification side by side. Design: submitted 24, compiled 15, correct 11, PPA measured 16. Verification: submitted 30, compiled 24, tells correct from broken 15, fault count 12." src="docs/assets/funnel_light.svg" width="100%">
</picture>

**Most submissions do not reach a score, and they fail early.** The design half
of that chart is currently a supersession artefact rather than a result: the
design specifications were revised to state their grading criteria, so every
design submission on record answers a prompt that no longer exists and renders
as unscoreable until the tasks are re-solicited. See *Design results* below.

Of 30 verification submissions, 2 do not compile; of the 28 that build,
16 tell a correct design from a deliberately broken one, and 13 end with a
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
  <img alt="Seeded faults detected by each verification submission, against the ceiling its task's reference testbench achieves, shown as a dashed line per task. v_ai02: ChatGPT 5.6 Sol 2 of 10; Claude Opus 5 4 of 10; Gemini 3.1 Pro 2 of 10. v_ca04: ChatGPT 5.6 Sol not scoreable (invalid); Claude Opus 5 6 of 10; Gemini 3.1 Pro 0 of 10. v_ca05: ChatGPT 5.6 Sol 6 of 10; Claude Opus 5 not scoreable (gate); Gemini 3.1 Pro not scoreable (gate). v_dsp02: ChatGPT 5.6 Sol 2 of 10; Claude Opus 5 10 of 10; Gemini 3.1 Pro not scoreable (invalid). v_nw01: ChatGPT 5.6 Sol not scoreable (invalid); Claude Opus 5 not scoreable (invalid); Gemini 3.1 Pro not scoreable (invalid). v_nw02: ChatGPT 5.6 Sol not scoreable (invalid); Claude Opus 5 10 of 10; Gemini 3.1 Pro not scoreable (invalid). v_nw03: ChatGPT 5.6 Sol 10 of 10; Claude Opus 5 10 of 10; Gemini 3.1 Pro not scoreable (invalid). v_nw04: ChatGPT 5.6 Sol not scoreable (gate); Claude Opus 5 8 of 10; Gemini 3.1 Pro not scoreable (invalid)." src="docs/assets/verification_faults_light.svg" width="100%">
</picture>

---

## Design results

**Seven tasks are complete at their pinned clock.** Every design specification was
revised to state its grading criteria — what correctness gates, which PPA axes
are compared, at what clock, and which levers the contract has already spent —
and every candidate was re-solicited against the revised prompt.

Each task is built at **one pinned period**, stated in the spec before
solicitation and derived as `ceil(1.5 × converged_period_ns / 0.25) × 0.25` from
the reference's own Fmax sweep. A single clock for every submission is what makes
area comparable at all: without it, area can be bought by relaxing timing.

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/assets/design_area_dark.svg">
  <img alt="Design area relative to each task's reference, at its pinned clock. async CDC FIFO at 4.25 ns, reference 19,837 um2: chat 0.75x, claude 0.75x, gemini 0.73x. Stream switch at 4.25 ns, reference 26,340 um2: all three missed timing. FP32 FMA at 19.25 ns, reference 60,031 um2: chat 1.80x, claude 1.05x, gemini fails correctness. Multi-format FMA at 70.5 ns, reference 177,557 um2: chat fails correctness, claude 1.42x, gemini fails correctness. AXI4 crossbar at 8.0 ns, reference 147,144 um2: chat 1.36x, claude missed timing, gemini fails correctness." src="docs/assets/design_area_light.svg" width="100%">
</picture>

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/assets/design_power_dark.svg">
  <img alt="Total power relative to each task's reference, at its pinned clock. async CDC FIFO: chat 0.61x, claude 0.60x, gemini 0.62x. Stream switch: all three missed timing. FP32 FMA: chat 0.30x, claude 0.89x, gemini fails correctness. Multi-format FMA: chat fails correctness, claude 0.88x, gemini did not build. AXI4 crossbar: chat 1.06x, claude missed timing, gemini did not build. Non-blocking D-cache: chat 1.68x, claude 1.24x, gemini fails correctness. Sv39 MMU: chat missed timing, claude fails correctness, gemini did not build." src="docs/assets/design_power_light.svg" width="100%">
</picture>

**Power does not track area.** d_dsp02's `chat` is the clearest case: 1.80× the
reference's area and **0.30× its power**. d_ca01's `chat` is the opposite — worse
on both, 1.36× area and 1.68× power. A single figure of merit would have to
weight these against each other, and nothing here establishes that weighting,
which is why there is no combined score.

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/assets/design_capability_dark.svg">
  <img alt="Area per unit of capability, relative to each task's reference. Where a task declares several capability metrics the bar spans best to worst. async CDC FIFO per capacity_beats_accepted: chat 0.91x, claude 0.91x, gemini 0.88x. Multi-format FMA per throughput_ops_per_1000cyc: claude 1.32x. AXI4 crossbar, range over 4 declared metrics: chat 2.59x to 3.40x. Non-blocking D-cache per max_outstanding_n: chat 1.36x, claude 1.15x." src="docs/assets/design_capability_light.svg" width="100%">
</picture>

**Raw area credits a design for being small when it was merely doing less**, and
this chart is where that shows. Two conclusions from the area chart invert:

- d_ca01's `claude` is **0.98×** on raw area — the only submission to come in
  under a reference on a large design — and **1.15×** per unit of outstanding
  capacity. The area win does not survive normalisation.
- d_nw01's `chat` is 1.36× on area and **2.59×–3.40×** per unit delivered. It is
  much further behind than the raw figure suggests, and *how much* further
  depends on which unit — 2.59× per burst, 2.72× per disjoint pair, 3.40× per
  outstanding transaction.
- d_ca04's three narrow from 0.73–0.75× to 0.88–0.91×. Most of that headline gap
  is two spill registers the reference has and they do not.

**Where a task declares several capability metrics, the bar spans best to worst
rather than picking one.** d_nw01 declares four, and they disagree by 31% about
how much `chat` paid per unit. Picking one and labelling it made the choice
visible but still made it silently: a reader had no way to know a different
declared metric moves the number by a third. The three other tasks declare one
metric each and render as points.

The alternatives were worse. A geometric mean is a synthetic quantity no contract
defines, and would smuggle in the combined score this project refuses. Worst-case
only penalises a task for declaring *more* metrics, which is backwards —
declaring more is better spec hygiene. One row per metric lets a four-metric task
visually outweigh a one-metric task.

Only tasks that **declare** a capability metric appear. d_dsp02 and d_ca03
declare none, so they are absent rather than shown against an invented axis —
"more is better and area buys it" is a claim about the contract, not something to
infer from a metric's name.

**Nine of twenty-one submissions produce a comparable area number.** Five missed
timing, four fail correctness, and three were rejected by the synthesis frontend
without ever running. That is the result, not a gap in the data.

### d_ca04 — asynchronous CDC FIFO, pinned at 4.25 ns

| | area µm² | power mW | slack ns | vs reference |
|---|---|---|---|---|
| reference | 19,837 | 13.4 | +0.606 | — |
| `chat` | 14,939 | 8.1 | +0.507 | **0.75×** |
| `claude` | 14,798 | 8.0 | +0.461 | **0.75×** |
| `gemini` | 14,396 | 8.3 | +0.456 | **0.73×** |

The only task where every submission closed timing, and all three are 25–27%
smaller than the reference. Two of them reach that partly by a design choice
rather than better implementation — see the like-for-like note below.

### d_nw03 — output-queued stream switch, pinned at 4.25 ns

| | area µm² | power mW | slack ns | vs reference |
|---|---|---|---|---|
| reference | 26,340 | 10.2 | +0.337 | — |
| `chat` | *withheld* | *withheld* | **−0.623** | missed timing |
| `claude` | *withheld* | *withheld* | **−0.078** | missed timing |
| `gemini` | *withheld* | *withheld* | **−0.116** | missed timing |

All three missed at the pin. `claude` missed by 78 ps, which is close — and close
is still missed: the number it would have reported describes a circuit that
cannot run at 4.25 ns.

### d_dsp02 — FP32 fused multiply-add, pinned at 19.25 ns

| | area µm² | power mW | slack ns | vs reference |
|---|---|---|---|---|
| reference | 60,031 | 74.7 | +2.710 | — |
| `chat` | 108,000 | 22.3 | +1.703 | 1.80× |
| `claude` | 63,197 | 66.2 | +0.992 | 1.05× |
| `gemini` | **0** | **0** | — | fails correctness |

### d_dsp03 — multi-format FMA, pinned at 70.5 ns

| | area µm² | power mW | slack ns | vs reference |
|---|---|---|---|---|
| reference | 177,557 | 91.1 | +1.995 | — |
| `chat` | **0** | **0** | — | fails correctness |
| `claude` | 251,769 | 80.1 | +8.179 | 1.42× |
| `gemini` | **0** | **0** | — | did not build |

### d_nw01 — AXI4 crossbar, pinned at 8.0 ns

| | area µm² | power mW | slack ns | vs reference |
|---|---|---|---|---|
| reference | 147,144 | 54.7 | +1.148 | — |
| `chat` | 199,852 | 58.1 | +0.802 | 1.36× |
| `claude` | *withheld* | *withheld* | **−0.023** | missed timing |
| `gemini` | **0** | **0** | — | did not build |

### d_ca01 — non-blocking data cache, pinned at 15.0 ns

| | area µm² | power mW | slack ns | vs reference |
|---|---|---|---|---|
| reference | 573,055 | 76.0 | +2.200 | — |
| `chat` | 780,029 | 128.0 | +1.121 | 1.36× |
| `claude` | 563,403 | 94.5 | +2.648 | **0.98×** |
| `gemini` | **0** | **0** | — | fails correctness |

`claude` is the only submission across all seven tasks to come in under a
reference on a large design, and it did so with the most slack in the row. It
reaches a different design point to do it — one cycle of minimum latency against
the reference's two — so the area is correct but not like-for-like.

### d_ca03 — RISC-V Sv39 MMU, pinned at 12.5 ns

| | area µm² | power mW | slack ns | vs reference |
|---|---|---|---|---|
| reference | 279,456 | 32.6 | +0.989 | — |
| `chat` | *withheld* | *withheld* | **−35.461** | missed timing |
| `claude` | **0** | **0** | — | fails correctness |
| `gemini` | **0** | **0** | — | rejected by the synthesis frontend |

`chat` is correct — it passes the scored configuration — and needs roughly 48 ns
to do it, against a 12.5 ns pin. That is not a near miss like d_nw03's 78 ps; it
is a design that works and is nearly four times too slow.

`gemini` is a distinct outcome from a correctness failure: slang rejects it with
ten diagnostics, none of them internal errors, and Verilator rejects the same
construct at the same line. Two independent frontends agreeing makes it a
genuine build failure rather than a host problem.

### Why some cells are withheld and others are zero

**Timing closure is a gate, not a scored axis.** Slack is bought with area, so a
design that misses timing and one that closes it are not describing the same
circuit — quoting the area of the first beside the second compares two different
questions. PPA from a build that missed its pin is withheld, not reported (rule
22).

**A correctness failure scores zero on every PPA axis, and is shown as zero**
rather than omitted (rule 19). Omitting it would make the surviving rows look
like the whole population, which is how an 8-of-18 result reads as 8 of 10.

**"Did not build" is a separate outcome from "fails correctness"**, and they are
not interchangeable: one wrote hardware the synthesis frontend rejects, the other
wrote hardware that compiles and computes the wrong answer. Both score zero;
they say different things about the model. Three submissions never ran at all.

### Not measured yet

| task | state |
|---|---|
| d_ai01 | no pin yet — HEIGHT=8 never routed on sky130hd (76k–83k violations across three floorplans). The scored geometry moved to HEIGHT=4, which routes clean at 0 violations, so its reference Fmax sweep is possible for the first time and is queued |
| d_dsp01 | no scoring testbench; withdrawn |

`results_table.md` carries the full per-task detail — capability metrics,
per-unit normalisations, and every superseded row rendered as *not scored against
this prompt* with the hash it answered. It is generated from the run records
under `runs/`, never hand-edited, and fails loudly rather than emitting a table
with rows missing.

Two numbers from the superseded round are worth naming, because they are why the
revision happened rather than an accident of it. d_nw01's largest submission
measured 2,086,235 µm² against a 146,932 µm² reference, and d_ca01's measured
753,209 µm². Both were buffering storage the contract never asked for. The
specifications now bound that storage by clause, and separately now say what the
submission is being compared on — neither of which they did when those designs
were solicited.

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

### v_nw03: frame-arbitrating stream mux (ceiling 10/10)

| Submission | Passes golden, fails broken HW | Accepts other correct designs | Faults caught |
|---|---|---|---|
| ChatGPT 5.6 Sol | yes | yes (5/5) | **10/10** |
| Claude Opus 5 | yes | yes (5/5) | **10/10** |
| Gemini 3.1 Pro | **no** | **no** (0/5) | *withheld* |

### v_ca05: tag tracker (ceiling 10/10)

| Submission | Passes golden, fails broken HW | Accepts other correct designs | Faults caught |
|---|---|---|---|
| ChatGPT 5.6 Sol | yes | yes (4/4) | 6/10 |
| Claude Opus 5 | yes | **partial** (3/4) | *withheld* |
| Gemini 3.1 Pro | yes | **partial** (3/4) | *withheld* |

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

### Automated model submissions

`runner.domain_sweep` replaces the manual prompt/chat/copy loop for every task
that has a canonical `probe/PASTE.md`. It sends that prompt to a selected model,
extracts the submitted module, and dispatches to the existing design or
verification grader. The two older design tasks without packaged prompts
(`d_ca04` and `d_nw01`) are deliberately absent.

To use included ChatGPT, Claude, or Gemini subscription quota instead of paying
for API tokens, authenticate the provider CLIs and select the subscription
transport:

```bash
codex login
claude auth login
python3 -m runner.domain_sweep --transport subscription \
  --tasks d_nw03 --models gpt-5.6-luna --smoke
```

Each subscription request runs as a fresh, non-persistent process in an empty
temporary directory, and the prompt is passed through stdin. Subscription
artifacts include `subscription` in their filenames and manifests. Codex and
Claude project/account customizations are disabled. Gemini runs headlessly in
the empty workspace; use the dedicated CLI home below so unrelated Gemini
extensions and user instructions are not loaded. The runner strips API-key and
Vertex environment variables and requires Google-account OAuth for Gemini.
Included quota is limited, so a sweep can stop until the provider's usage
window resets.

#### Gemini account setup for a collaborator

Gemini support uses the official Gemini CLI's `pro` model alias. On the
collaborator's computer, install the CLI, create a dedicated Gemini CLI home
outside this repository, and sign in interactively with the Google account that
owns the Gemini subscription:

```bash
npm install -g @google/gemini-cli@latest
export GEMINI_CLI_HOME="$HOME/.hwrl-gemini"
gemini
```

Choose **Sign in with Google** in the browser flow. Keep
`GEMINI_CLI_HOME` set to the same path when running the sweep. Gemini's
official documentation describes both [Google-account
authentication](https://github.com/google-gemini/gemini-cli/blob/main/docs/get-started/authentication.mdx)
and [`--prompt`/JSON headless
execution](https://github.com/google-gemini/gemini-cli/blob/main/docs/cli/cli-reference.md).
If the login is a company, school, or Workspace account, follow Google's guide
to set the required `GOOGLE_CLOUD_PROJECT`; the runner preserves that project
identifier while still enforcing Google-account OAuth.

After Codex, Claude, and Gemini are authenticated on that computer, all three
can participate in one resumable sweep. Five workers means at most five
task/model requests are in flight at once:

```bash
export GEMINI_CLI_HOME="$HOME/.hwrl-gemini"
python3 -m runner.domain_sweep --transport subscription \
  --tasks all --models gpt-5.6-sol,opus-5,gemini-pro \
  --api-workers 5 --smoke
```

Pushing this repository shares the Gemini integration, model roster, tests,
and instructions; it does **not** share login sessions. Codex, Claude, and
Gemini OAuth credentials remain in machine-local CLI storage and must never be
committed. On a separate computer, each account owner must complete the
corresponding CLI login there. If a collaborator is meant to use somebody
else's Codex or Claude subscription, use an account/team arrangement authorized
by that provider's terms and your organization rather than copying token or
credential files. On a shared computer and OS account, the runner uses whichever
authorized CLI sessions are already logged in locally.

For strict direct-API runs, enter keys with `read -s` to keep them out of shell
history:

```bash
read -s -p "OpenAI API key: " OPENAI_API_KEY; export OPENAI_API_KEY; echo
read -s -p "Anthropic API key: " ANTHROPIC_API_KEY; export ANTHROPIC_API_KEY; echo
```

List the checked-in provider model roster and preview a sweep without spending:

```bash
python3 -m runner.domain_sweep --list-models
python3 -m runner.domain_sweep --tasks all --models gpt-5.6-sol,opus-5 --dry-run
```

One low-cost live smoke run, with an explicit local spend stop:

```bash
python3 -m runner.domain_sweep --tasks d_nw03 --models gpt-5.6-luna \
  --smoke --max-spend 0.25
```

Every attempt gets a unique file under `candidates/<task>/`. Sanitized original
responses and a resumable manifest live under the gitignored
`results/generations/<run-id>/`; the existing graders continue to write their
immutable records under `runs/`. Add `--ppa` only when place-and-route is wanted.

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
