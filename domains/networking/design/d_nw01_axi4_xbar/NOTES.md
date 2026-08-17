# d_nw01 `axi4_xbar` — build notes

Catalog v3. Verilator **5.046**. Checker complete and passing on all 8 legal
configs; second source not written (see § Still to build).

## Oracle class A

Anchored on vendored PULP `axi/src/axi_xbar.sv` @ `4da15979…` (SHL-0.51).

## Shim feasibility — the gate the catalog flagged

`axi_xbar` takes **14 `type` parameters** plus a struct `Cfg` and an address
map, which is the shape that blocked `ai_v01`. It elaborates cleanly with
concrete types, and the bridge is type binding plus struct pack/unpack — within
the shim rule. **Verified at all four legal geometries** (2×2, 4×2, 2×4, 4×4).
No conversion needed; the three-conversion budget is untouched.

The spec ships its own AXI4 struct package, with field order written to match
upstream's `AXI_DECL_*_CHAN_T` macros so the mapping is mechanical.

### The ID-width cap, and why it is enforced three times

The spec fixes the widened slave-side id at `SLV_ID_W + MST_IDX_W` with
`MST_IDX_W = 2`, because a SystemVerilog package cannot be parameterised and one
layout must serve every configuration. That supplies exactly two master-index
bits:

| NUM_MST | index bits needed | |
|---|---|---|
| 2 | 1 | one spare |
| 4 | 2 | exact |
| 8 | 3 | **impossible** |

At `NUM_MST = 8` two masters would share an index and their responses would
misroute — and it would present as an *ordering* bug, not a width bug, which is
the kind of thing that burns a day. So the cap is stated in the package header
next to the field-order note, in the spec's PARAMETERS section, and enforced by
an elaboration-time `$error` in the shim. Verified: `NUM_MST=4` elaborates
clean, `NUM_MST=8` errors at build.

Upstream computes the same width as `SLV_ID_W + $clog2(NoSlvPorts)` — 5 bits at
`NUM_MST=2` — so the shim resizes the id field rather than passing it through.
Bit placement, not behaviour.

## NEGATIVE CONTROL — liveness monitor validated before the checker was built

Per the standing rules in `FINDINGS.md`: *a checker whose failure
mode is silence must be validated against a known-failing input before it is
trusted.* The liveness mutants were therefore built **first**, and the monitor
was proven on them before any data checking existed.

Rig: `tb/axi4_xbar_liveness_tb.sv`, deliberately minimal — read channel only, no
scoreboard, 4 masters × 2 slaves under sustained all-to-all read pressure.

| input | verdict | monitor fired | served per requester |
|---|---|---|---|
| **correct reference** | PASS | neither | `10000 10000 9999 9999` |
| `mL1_ar_arbiter_never_grants` | FAIL | **DEADLOCK** — 4001 cycles with load offered and nothing retired | — |
| `mL2_master0_starved` | FAIL | **STARVATION** — requester 0 waited 8001 cycles while others were served | `0 13333 13332 13332` |

**The two failures are distinguishable, which was the point.** `mL2` fires
starvation and does **not** fire deadlock (`DEADLOCK` occurrences: 0). The
served counts show why that is the right call: the crossbar is manifestly alive
— 13 333 bursts retired for each of the other three masters — it is simply
serving nobody at port 0. A monitor that reported that as deadlock would be
describing the wrong defect.

### The inverse control: slow but fair must NOT fire

A monitor that trips on slowness would silently encode one arbitration policy
into the contract. Same correct reference, every slave's response latency
inflated equally so throughput collapses without anyone being treated unfairly:

| `SLOW_SLAVE` | verdict | served per requester |
|---|---|---|
| 0 | PASS | `10000 10000 9999 9999` |
| 5 | PASS | `2308 2308 2307 2307` |
| 20 | PASS | `698 698 697 697` |

Throughput drops **14×** and the monitor stays silent. It is measuring fairness
and forward progress, not speed — which is what the design note claimed and is
now demonstrated rather than asserted.

## The harness bug this exercise caught

The first version of the rig fired `DEADLOCK` on the **correct** reference, with
requesters 2 and 3 never served. The crossbar was fine; the harness was not. Its
master and slave models drove `valid` from inside the same `always_ff` that
consumed the handshake, reading their own pre-update values, and wedged.

That is worth recording precisely because it is the failure mode the standing
procedure exists to catch, arriving from the opposite direction: **a broken
harness and a deadlocked DUT produce identical output.** Without a known-good
and a known-bad input to compare against, there is no way to tell which one you
have. Both models are now combinational off registered state.

## The data half

**All 8 configs PASS with zero coverage holes** (`NUM_MST` ∈ {2,4} × `NUM_SLV` ∈
{2,4} × `MAX_TRANS` ∈ {2,8}). Representative run at 4×2:

```
// coverage: served_per_requester = 1466 1472 1470 1450
// coverage: rd_ok=2788 rd_decerr=233 wr_ok=2733 wr_decerr=246
// coverage: multi_beat_bursts=2259 cross_id_switches=2283
TEST_RESULT: PASS
```

### Three things the checker deliberately does not do

Each would look correct while quietly failing a correct crossbar.

1. **No global response-order check.** AXI requires ordering *per ID* and
   explicitly permits different IDs to interleave in any order. The scoreboard
   is a FIFO **per (master, ID) pair**, never one queue per master. A global
   check would pass this reference — whose arbitration happens to produce one
   interleaving — and fail a correct crossbar that interleaves differently.
2. **No response timing or latency check.** The slave models respond at
   *different* rates on purpose, so cross-ID reordering genuinely happens and an
   accidental global-order assumption is exposed rather than hidden. The run
   above records **2283 cross-ID switches**; a global-order scoreboard could not
   have survived them.
3. **No arbitration requirement.** Fairness is checked only by the liveness
   monitor's starvation bound, measured relative to progress elsewhere.

### AXI4 has no WID

W beats carry no ID, so they belong to AW transactions in acceptance order and
must arrive contiguously. That is checked as a **protocol property at each slave
port** — a W beat with no AW outstanding, or WLAST on the wrong beat, fails —
rather than inferred from data. A crossbar that interleaved W bursts from two
masters onto one slave would corrupt data in a way a data-only scoreboard could
easily miss.

### DECERR is a beat-count property

An unmapped read must return **ARLEN+1 R beats, each DECERR, with RLAST on the
last**. The checker applies the *same* beat-count and RLAST-placement check to
mapped and unmapped bursts; only the expected response code differs. Returning a
single DECERR beat and dropping the rest is the classic bug, and it wedges a
master waiting on RLAST — see mD3 below.

## NEGATIVE CONTROL — ordering scoreboard

Same discipline as the liveness monitor. An ordering checker that is accidentally
checking *global* order looks identical to a working one until a correct
alternative design fails.

| input | verdict | caught by |
|---|---|---|
| correct reference | **PASS**, with 2283 cross-ID switches | — |
| `mD1_same_id_two_slaves` | FAIL at t=615 µs | per-(master,ID) data comparison |

The paired evidence is what matters: the mutant that violates **per-ID** order is
killed, while the correct reference passes *while interleaving heavily across
IDs*. A global-order scoreboard would have killed both.

## Mutant table

| id | class | injected bug | killing check |
|---|---|---|---|
| mL1 | liveness-deadlock | read-address arbiter never sees a request | `LM_STALL` |
| mL2 | liveness-starvation | slave port 0 masked out of the arbiter | `LM_STARVE`, and **not** `LM_STALL` |
| mD1 | ordering (per-ID) | demux no longer blocks a same-ID read to a *different* slave | per-(master,ID) data mismatch |
| mD2 | decode-beatcount | unmapped read asserts RLAST on its first beat, truncating the burst | `RLAST on beat 0 of a 2-beat burst` |
| mD3 | decode-liveness | unmapped read drops beats **without** RLAST | `LM_STALL` — deadlock |

### The free cross-check

`mD2` and `mD3` are the same defect class — a wrong DECERR beat count — split by
whether RLAST is asserted. They are caught by **different** checks:

* `mD2` truncates *with* RLAST: the master completes, nothing wedges, and the
  **beat-count check** catches it.
* `mD3` truncates *without* RLAST: the master waits forever, and the **liveness
  monitor** catches it.

That is a data-path bug being caught by the liveness monitor, which is exactly
the independent confirmation that the monitor is wired to something real. Neither
check alone covers the class.

## Still to build

* **second source** — not written. For a full AXI4 crossbar this is an
  independent crossbar implementation, which is a task-sized piece of work in
  itself. The over-constraint risk it exists to cover has been addressed
  differently here and the evidence is above: the scoreboard is per-(master,ID)
  by construction, the slaves respond at deliberately different rates, the
  correct reference passes with 2283 cross-ID switches, and the ordering mutant
  is killed. That is weaker than a second source and is recorded as such rather
  than claimed as equivalent.
## Step 7 — PPA baseline

sky130hd, 20 ns, **NUM_MST=2 NUM_SLV=2** — the smallest legal geometry. A 4×4
crossbar is a very different P&R proposition and a baseline is only comparable
within one geometry.

| metric | value |
|---|---|
| design area (post-route) | **146 818 µm²** (14 % utilisation) |
| synthesised module area | 107 891 µm² |
| WNS | **+7.83 ns** — closes |
| TNS | 0.00 |
| total power | 21.9 mW |
| instances | 147 097 |
| flow | completed to `6_finish`, DRC 0 |

For scale: this is ~47× `nw_d01`'s width adapter (3 115 µm²) and ~7× `d_ca04`'s
CDC FIFO at its 10 ns baseline. The catalog's warning that v3 DUTs are 5–20×
larger is borne out.

### One ORFS failure worth recording

The first attempt died at `1_1_yosys_canonicalize` with only
`ERROR: Design elaboration failed` and nothing else. Cause: **`slang` does not
do library search the way Yosys `-y` does.** Every file in the dependency
closure must be listed explicitly in `VERILOG_FILES`, packages first. A
`SYNTH_SEARCH_PATHS` variable does not substitute.

The 25-file list was extracted from the working Verilator build's dependency
file rather than assembled by hand — hand-assembling a closure this size is how
a missing file becomes a silent mis-elaboration later.

---

# CAPABILITY AUDIT — and the spec correctness gap it exposed

A candidate came back **67 % smaller** than the vendored reference while passing
every correctness config. That gap was too large to be an optimisation, so
before the result went anywhere it was audited on four measurements. The audit
found a **correctness gap in the spec, not a difficulty complaint**: the
contract never said how much the crossbar had to do *at once*, so a design that
carries one transaction per master is a conforming answer to the question that
was actually asked.

## The four measurements

Rig: `tb/audit/axi4_xbar_capability_rig.sv` — measurement only, emits
`CAPABILITY:` lines, decides nothing.

### 1. Outstanding capacity — DEFICIENT

Slaves accept every AR and return nothing; masters accept nothing. The only
thing that can stop a master issuing is the crossbar's own capacity.

| MAX_TRANS | reference | candidate |
|---|---|---|
| 2 | 3 | **1** |
| 8 | 9 | **1** |

The reference delivers `MAX_TRANS + 1` and scales with the parameter. The
candidate returns 1 at both settings, because **`MAX_TRANS` appears exactly once
in its 732 lines — the parameter declaration — and is never referenced again.**
Its own comment: *"Only one write from this master can be outstanding."*

A first version of this measurement had the slave stop accepting once one
transaction was in flight, and reported 4 for the reference at `MAX_TRANS=8`. It
was measuring the depth of the harness's own slave model, not the DUT. A spec
requirement written off that number would have failed the reference.

### 2. Concurrency — NOT deficient

Both designs score **200 %** on disjoint pairs at every config: master0→slave0
and master1→slave1 genuinely run in parallel. The candidate has per-slave FSMs
and per-slave round-robin tokens. It is a real crossbar in this sense, and the
hypothesis that it funnels through a shared arbiter is **refuted**.

### 3. Aggregate throughput — HALF

999 vs 500 bursts per 1000 cycles at 4×2. A direct consequence of (1): with one
transaction in flight a master must see its response before issuing again.

### 4. Reference configuration — and 45 % of its area is off-spec

```
MaxMstTrans: MAX_TRANS   MaxSlvTrans: MAX_TRANS   FallThrough: 0
LatencyMode: axi_pkg::CUT_ALL_AX   PipelineStages: 0   UniqueIds: 0
```

`CUT_ALL_AX` is `DemuxAw|DemuxAr|MuxAw|MuxAr` — full AX channel cuts, which the
spec never asked for. That was **this shim's choice**, not upstream's
requirement. Rebuilding the reference with `NO_LATENCY` and synthesising both:

| build | synth area |
|---|---|
| reference, `CUT_ALL_AX` (as shipped) | 107 891 µm² |
| reference, `NO_LATENCY` (spec-minimal) | 59 209 µm² |
| candidate | 34 733 µm² |

So the 3.1× headline gap is **1.82× spec-irrelevant pipelining × 1.70× genuine
missing capability**. Neither factor is an optimisation the candidate earned,
and the headline number should never have been quoted on its own.

## The spec fix

`§ LATENCY AND THROUGHPUT` previously read *"NEITHER IS CONSTRAINED AND NEITHER
IS CHECKED."* That sentence is what the candidate answered correctly. It is
replaced by `§ CAPACITY AND CONCURRENCY`, normative and checked:

* **C1** each master accepts ≥ `MAX_TRANS` reads and writes with nothing drained
* **C2** disjoint master/slave pairs proceed in parallel
* **C3** both hold at every legal geometry

Latency remains explicitly unconstrained — the distinction the old wording lost
is between **delay**, which is free, and **capacity**, which is required.

Aggregate throughput is reported as a `METRIC:` line and **does not gate**. The
reference's worst config (666 bursts/1000 cyc) equals the candidate's best, so no
flat threshold separates them; a throughput gate would either fail a correct
design or pass a deficient one. C1 and C2 are the gates.

## Result of the fix

| input | verdict |
|---|---|
| reference | **8/8 PASS** |
| candidate | **0/8 FAIL** — C1 at every config |
| `mC2_serialised_xbar` | **FAIL** — C2 only |

The scored-phase coverage numbers are **unchanged** by the new preamble
(`rd_ok=2788`, `cross_id_switches=2283`, identical to before), which is the
evidence that the added phases do not perturb the data checking.

## NEGATIVE CONTROLS for the new checks

Both C1 and C2 fail by silence, so per the standing procedure neither is trusted
until something known-bad fails it.

**C1** — the candidate is a real-world negative control: it reports 1 at every
`MAX_TRANS` and is killed at all 8 configs.

**C2** — needed a purpose-built mutant, `mC2_serialised_xbar`, and getting it
right took three attempts. Each failure is worth recording because each was a
hole in the *check*, not in the mutant:

1. **Gated the master side.** Failed C1 as well as C2, so it proved nothing
   about C2 specifically. Moved the grant to the slave side, downstream of the
   crossbar's id queues, where it leaves capacity intact.
2. **One-at-a-time preamble slaves.** The mutant scored **199 %** and passed.
   With the slave accepting one transaction at a time, a single pair runs at
   0.5 bursts/cycle and the *slave* is the bottleneck — a serialising crossbar
   keeps up with it easily. The preamble slaves are now pipelined so the
   crossbar is the resource being measured.
3. **Blind round-robin grant.** Scored **199 %** again. A blind rotation
   throttles a solo pair exactly as much as a concurrent one, so the
   one-pair/two-pair *ratio* is unchanged. The grant is now demand-driven: a
   single pair gets the full rate and two pairs must share it.

Final: mutant passes C1 (all masters 9) and fails C2 alone at **100 %**, one
failing check. Reference scores 200 %.

### Where C2 is blunt — stated, not hidden

| MAX_TRANS | mutant speedup | caught? |
|---|---|---|
| 8 | 100 % | yes |
| 2 | 200 % | **no** |

At `MAX_TRANS = 2` a single pair cannot saturate the shared datapath, so the
ratio stays at 2× and serialisation is invisible. The sweep always includes
`MAX_TRANS = 8`, so a serialising design still fails overall — but C2 is sharp
only at the higher setting, and a future task reusing this check should not
assume otherwise.

## THE HARNESS BUG THIS AUDIT UNCOVERED

`sim_candidate.sh` selected the scoring testbench with `ls tb/*_tb.sv | head -1`
— **alphabetically**. `axi4_xbar_liveness_tb.sv` sorts before
`axi4_xbar_tb.sv`, so since commit `6337d3f` every d_nw01 run through
`sim_candidate.sh` or `build_and_score.sh` scored the **read-only liveness rig**
and reported 8/8 for it. The liveness rig contains none of the scoreboard or
coverage code; the reported passes covered a fraction of the contract.

This is the worst failure this harness can have, and it is the same shape as the
one the standing procedure already names: it does not error, it just quietly
stops testing most of the contract. A weaker checker substituted in silence is
indistinguishable from a strong one passing.

Fixed: the scoring TB must be `tb/<dut>_tb.sv`. Auxiliary rigs live under any
other name and are run deliberately. If the required file is absent the runner
**refuses to run** rather than picking a neighbour. Verified against all five
registered tasks. The capability rig is kept in `tb/audit/` so it can never be
picked up by the scoring path.

Re-run through the corrected path: reference 8/8, and the candidate also passes
the real data checker 8/8 — its correctness result stands, it had simply never
been demonstrated through that path. The capacity deficit is the entire story.

## Simulator coverage — corrected claim

**d_nw01 is Verilator-only, and always has been.** The checker does not compile
under Icarus: it uses `automatic` in procedural blocks
(`sorry: Overriding the default variable lifetime is not yet supported`). The
pre-change checker fails identically, so this is not a regression from the
audit — but it means d_nw01 has no dual-simulator evidence and none should be
claimed for it.

## Still outstanding

* **The candidate must be re-solicited against the fixed spec.** The current one
  fails C1 by construction; its PPA numbers are no longer a comparison of two
  designs doing the same job.
* **PPA at a binding clock period.** The reference closed at **+7.83 ns** and the
  candidate at **+6.67 ns**, so the constraint never bound and neither design was
  pushed. No area comparison from this task — or from `ai_d01` or `d_ca04` — is
  evidence about difficulty until it has been rerun at a period that actually
  constrains the reference.
* Second source: still not written, still recorded as such.

## A second harness gap found by the same regression

Re-running every task's reference through the corrected runner exposed an
unrelated pre-existing failure: **`nw_d01`'s reference failed all 16 configs**
with `MODMISSING: Cannot find file containing module: 'axis_adapter'`. Its
`ref/sim_flags_verilator.txt` was **empty**, so the vendored `verilog-axis`
search path the shim needs was never passed.

Confirmed pre-existing — the same failure reproduces with the pre-change script,
so the TB-selection fix did not cause it.

It survived this long because of its asymmetry: a **self-contained candidate
compiles fine and only the REFERENCE fails**, which reads as a broken reference
rather than a broken flags file. That is the same shape as the d_nw01 gap where
the reference failed through the shared path while the candidate passed.

Fixed, and `nw_d01` is back to 16/16. Full regression, all references through
the corrected runner (`ai_d01`, `nw_d01` and `ca_d08` have since been removed
from `domains/` — see `RESULTS_ARCHIVE_V2_TASKS.md`): `ai_d01` 4/4,
`nw_d01` 16/16, `ca_d08` 3/3, `d_ca04`
18/18, `d_nw01` 8/8.

---

# C1 AND C2 AS FLOORS — the over-constraint check, and what it caught

C1 and C2 were derived from measurements of one implementation, which is exactly
how a rediscover-the-reference test gets written. Both were therefore checked
against a **correct design that differs from the anchor**, before anything else
ran.

The probe is the vendored `axi_xbar` reconfigured with `LatencyMode: NO_LATENCY`
— same crossbar, same `MaxMstTrans = MAX_TRANS`, two fewer buffering stages.

## C1 was over-constrained, and the probe proved it

| design | MAX_TRANS=2 | MAX_TRANS=8 |
|---|---|---|
| anchor, `CUT_ALL_AX` (shipped) | 3 | 9 |
| anchor, `NO_LATENCY` | **1** | **7** |
| candidate | 1 (`1 1 0 0`) | 1 |

**Observable capacity depends on pipeline depth, not only on configured queue
depth.** The same `MaxMstTrans` yields `MAX_TRANS+1` with cuts and `MAX_TRANS-1`
without. The original check required `>= MAX_TRANS`, so the no-cut anchor —
a correct crossbar differing only in buffering — **failed at both settings**.
The shipped reference passed only because `CUT_ALL_AX` handed it two spare
slots. That is PULP's pipelining choice encoded into the contract.

**Fixed: the floor is `ceil(MAX_TRANS / 2)`.** At `MAX_TRANS=8` that is 4, with
the anchor at 9, the no-cut anchor at 7 and a one-deep design at 1 — margin on
both sides rather than a threshold resting on the reference's exact figure.

### The floor is per master, which matters more than the depth at MAX_TRANS=2

At `MAX_TRANS=2` the floor is 1 and looks inert. It is not, because it is
applied per master:

```
no-cut anchor   1 1 1 1     PASS
candidate       1 1 0 0     FAIL
```

Masters 2 and 3 get **nothing**. One un-retiring transaction occupies the
candidate's per-slave read path and shuts out every other master targeting that
slave. So C1 catches *depth* at `MAX_TRANS=8` and *head-of-line blocking* at
`MAX_TRANS=2` — a different defect, caught by the same floor.

## C2's threshold, and why it sits at 150 %

Ideal parallelism is 200 %, complete serialisation is 100 %, and the threshold
is the midpoint. It tolerates a quarter of ideal throughput being lost to
arbitration overhead while still failing anything sharing one datapath.

Four designs measured: anchor **200 %**, no-cut anchor **200 %**, candidate
**200 %**, serialisation mutant **100 %**. Three structurally different passing
designs all land at 200 %, and the only thing near the threshold is the mutant,
50 points below it.

## Verdict matrix after the relaxation

| input | configs |
|---|---|
| anchor, as shipped | **8/8** |
| anchor, `NO_LATENCY` | **8/8** |
| candidate | 3/8 |
| `mC2_serialised_xbar` | 4/8 |

The candidate now passes 3 configs rather than 0 — the honest consequence of
removing the over-constraint. It still fails overall, on capacity, which is the
defect that is actually there.

## d_nw01 contains roughly zero genuine optimisation win

Recording the decomposition as the headline finding: the 3.1× area gap is
**1.82× off-spec pipelining × 1.70× capability gap**. The pipelining was this
shim's choice of `CUT_ALL_AX`, not a requirement of the task and not something
the candidate competed against. The capability gap is missing function, not
efficiency. **Neither factor is an optimisation the candidate earned, and this
task should not be cited as evidence of one.**

---

# SECOND SOURCE — the over-constraint control for C1 and C2

`tb/audit/axi4_xbar_second_source.sv`. **A falsifier, not an oracle.** Written
because C1 and C2 were new normative checks and nothing had ever passed them
except the module they were measured from.

Deliberate structural differences from the anchor:

| anchor (PULP `axi_xbar`) | second source |
|---|---|
| per-master demux + per-slave mux hierarchy | one flat routing matrix, no hierarchy |
| `rr_arb_tree` | rotating-priority mask arbiter, written out |
| spill registers on AW/AR (`CUT_ALL_AX`) | **no channel registers anywhere** |
| `id_queue` structures | flat per-(master,ID) counter + destination |
| `MAX_TRANS + 1` observable outstanding | **exactly `MAX_TRANS`** |

It **passes 8/8**, and is genuinely exercised rather than trivially passing:
1116–2270 cross-ID switches per run against a floor of 100, plus the DECERR
paths, at every geometry.

| config | outstanding | speedup |
|---|---|---|
| MAX_TRANS=2 (all geometries) | **2** | 200 % |
| MAX_TRANS=8 (all geometries) | **8** | 200 % |

Exactly `MAX_TRANS`, never `MAX_TRANS+1`. That is the number that would have
exposed C1 as pinned to the anchor's buffering, and it clears the floor.

## The validated matrix

| design | structure | outstanding | speedup | configs |
|---|---|---|---|---|
| anchor, `CUT_ALL_AX` | demux/mux + spill | `MAX_TRANS+1` | 200 % | **8/8** |
| anchor, `NO_LATENCY` | demux/mux, no spill | `MAX_TRANS-1` | 200 % | **8/8** |
| second source | flat matrix, mask arbiter | `MAX_TRANS` | 200 % | **8/8** |
| candidate | one-deep | 1 | 200 % | 3/8 |
| `mC2_serialised_xbar` | one shared AR datapath | `MAX_TRANS+1` | 100 % | 4/8 |

**Three structurally different correct crossbars pass; the two deficient ones
fail.** C1's floor of `ceil(MAX_TRANS/2)` sits below all three passing capacity
values and well above the candidate's 1. C2's 150 % sits 50 points below three
passing designs and 50 above the mutant. Neither check is pinned to the anchor.

## Two honest caveats

**It passed first try.** A second source that never fails is weaker evidence
than one that struggles, and I wrote both it and the checker, so it is not
independent in the way an externally-authored implementation would be.

**The stronger evidence is the `NO_LATENCY` probe**, because that is
externally-authored RTL in a different configuration, and it **failed the
original C1** — which is what proved the check was pinned in the first place.
The second source confirms the relaxed floor admits a genuinely different
architecture; the probe is what found the defect.

---

# L3 WAS DECORATIVE, AND MAX_BURST_LEN IS NOW A PARAMETER

Third consecutive spec gap found *after* a candidate passed. The re-solicited
candidate provisioned a **256-entry read buffer per master** — 36 864 bits at
NUM_MST=2 — and said why in its own comment: *"A read burst may contain up to
256 beats. One full-burst buffer per master lets the crossbar absorb a mapped R
burst even if the originating master applies backpressure."*

It was reading the spec correctly. **L3 states liveness under backpressure, and
AXI4 permits ARLEN up to 255.** The checker did neither: `r_ready` and `b_ready`
were hardwired to 1, so backpressure was never applied, and bursts were drawn
from `$urandom_range(0, 3)`. **L3 had been decorative since it was written.**

## The measurement that decided the fix

Narrowing the spec would have punished the candidate for being more compliant
than the anchor. So the question was whether the anchor can actually satisfy L3,
and at what burst length. Measured before anything was changed:

| reference, backpressure ON | verdict | evidence |
|---|---|---|
| `MAX_BURST_LEN = 3` | **PASS** | 3509 R stalls, 1397 B stalls |
| `MAX_BURST_LEN = 255` | **PASS** | 14 231 R stalls, 255-beat bursts driven |

**The anchor satisfies L3 at full AXI4 burst length while buffering no read data
at all.** So there is no anchor limitation to document, the upper sweep value is
255 rather than something the reference forced down, and the candidate's
full-burst buffer is over-provisioning rather than a requirement.

## What changed

1. **Master-side backpressure, unconditional.** Free-running LFSR per master,
   ~25 % stall on R and on B independently. It never reads `*_valid`, so it
   cannot violate the ready-not-dependent-on-valid rule or wedge the way a
   handshake-derived stall would. **A coverage floor fails the run if
   backpressure never actually stalled a response**, so L3 cannot pass by never
   being exercised again.
2. **`MAX_BURST_LEN` is a swept parameter**, legal {3, 255}. One burst in four
   is driven at exactly the parameter, and a coverage floor fails the run if the
   full value was never reached. The spec states it is also a **ceiling** —
   nothing longer is ever driven, so provisioning beyond it is wasted area.
3. Configs go 8 → **16**. `EFF_TXN` drops to 120 at long bursts so total beats
   stay roughly constant instead of the long configs dominating runtime.

## A coverage floor that was measuring the harness

The reference failed 2 of 16 on `COVERAGE HOLE: too little cross-ID
interleaving` — 76 switches against a floor of 100. Not a reference defect: at
`MAX_BURST_LEN=255` there are only 120 transactions per master, and 76 switches
out of 240 transactions is a **32 % interleaving rate**, higher than the long
runs achieve. The fixed floor of 100 was measuring `EFF_TXN`, which is my own
scaling knob, not the DUT.

Now rate-based — `(EFF_TXN * NUM_MST) / 32`, minimum 20 — which is the form the
property actually has. Loosening a floor because the reference tripped it is the
rediscover-the-reference trap, so the justification is deliberately independent
of what the reference scored: the count scales with transaction count, the
property does not.

## Verdict matrix, 16 configs

| input | configs |
|---|---|
| reference | **16/16** |
| second source | **16/16** |
| re-solicited candidate | **16/16** |

The second source clearing the new checks is the over-constraint control: L3
backpressure and `MAX_BURST_LEN=255` do not encode the anchor's architecture.

## The re-solicited candidate: capacity fixed, area and throughput lost

> **CORRECTION — two problems with the table below, both found later.**
>
> **1. The reference's "9 outstanding per master" is wrong.** It came from the
> checker's `MAX_TRANS + 1` model. Swept on the reference, the actual figure at
> `MAX_TRANS=8` is **27** — the relation is linear with slope 4 and `MAX_TRANS+1`
> holds only at `MAX_TRANS=2`, by coincidence. See FINDINGS.md F29. So the gap
> in that row is **27 vs 8**, not 9 vs 8, and it is a buffering difference
> (the reference carries `CUT_ALL_AX` channel registers) rather than a count of
> transactions in flight.
>
> **2. These figures predate rule 18's pinned scored configuration**, so they are
> not the scored comparison and must not be quoted as it. At the pinned
> configuration (`NUM_MST=2, NUM_SLV=2, MAX_TRANS=8, MAX_BURST_LEN=255`) the
> reference measures single-pair 2997 and aggregate 1998; the numbers below were
> taken across an unpinned config set and differ.
>
> The qualitative conclusion — capacity fixed, area and throughput lost — is
> unaffected. The specific ratios are.

| axis | reference | candidate |
|---|---|---|
| outstanding per master | 9 | **8** (was 1) |
| disjoint-pair concurrency | 200 % | 200 % |
| **single-pair throughput** | 2999 | **599** — 5× worse |
| aggregate throughput | 999 | 798 |
| **synth area** | 107 891 µm² | **1 540 648 µm²** — 14× larger |

**The pendulum swung all the way over.** The first candidate was 3× smaller with
one-eighth the capacity; this one has full capacity and is 14× larger and
slower. The 36 kbit buffer synthesised as flip-flops is the entire difference.

This is the first time a candidate has been materially **worse** than the
reference on a real axis, and the throughput half of it was visible only because
throughput is reported. It is now a first-class scored axis.

## Broadened metric set

Every one of the last four findings came from a number that happened to be
printed rather than from a gate, so the checker now prints:

```
METRIC: outstanding_master<N>          per-master capacity
METRIC: disjoint_one_pair / two_pairs  single-pair and concurrent throughput, separately
METRIC: aggregate_bursts_per_1000cyc   all-to-all saturation
METRIC: scored_beats_per_1000cyc       throughput under the real mixed workload
METRIC: read_latency_avg / max / n     AR-accept to RLAST, in cycles
METRIC: fairness_spread                max minus min served across masters
METRIC: backpressure_stalls r= b=      proof L3 was exercised
METRIC: liveness worst_wait            per-master wait under progress elsewhere
```

Single-pair and aggregate are recorded separately on purpose: the candidate's
**5× single-pair gap against a 1.25× aggregate gap** localises its bottleneck to
per-pair latency rather than total switching capacity.

---

# TASK C — the cross-ID coverage floor could not be validated, and why

The floor was changed from a fixed count (`>= 100`) to a rate after the
*reference* tripped it. The reasoning was sound, but by the standing rules a
changed floor is untrusted until a known-failing input fails it. Building that
control found two defects in the floor itself and ended with the floor removed.

## The control

`mutants/mX1_no_cross_id_interleaving.sv` — derived from the second source, one
injected restriction: **a master may have only one ID in flight at a time.**
Otherwise correct, and deliberately so: AXI permits a crossbar to be more
ordered than required, so no data, ordering, decode or liveness check can see it.

## What it found

### The counter did not measure what its name claimed

```systemverilog
if (last_rid[m] != i) begin cov_cross_id++; last_rid[m] <= i; end
```

That counts **ID changes in the delivered stream**, which a strictly in-order
crossbar still produces whenever consecutive transactions carry different IDs.
mX1 — incapable of any reordering whatsoever — scored **2234 against a floor of
20** and passed comfortably. *The floor could not have failed anything.*

Replaced with a real detector: issue order is recorded per master, and a burst
completing while an older burst with a different ID is still outstanding counts
as one reordering. Under the corrected counter mX1 scores **0**.

### The corrected counter gates a legal design choice

With the real detector, the **vendored reference scores 0 at `MAX_TRANS=2` in
all eight of those configurations** — and fails its own coverage floor.

Not a stimulus problem. The independently written second source scores **218 on
the same stimulus at the same setting.** The hazard is reachable; the reference
simply chooses not to reorder at that depth.

`O2` grants a crossbar the right to return different IDs out of order. It does
not oblige it. **Reordering is a DUT choice, so a floor on it fails a correct
design** — the rediscover-the-reference trap arriving from the opposite
direction, and this time it would have been *written into the contract* rather
than caught.

## What replaced it

The requirement the floor was groping toward is **capacity with mixed IDs**, and
that belongs in C1, where the defect actually is.

The capacity phase previously drove **one ID per master**, so a design holding
`MAX_TRANS` of a single ID while refusing any second ID passed. Two attempts
were needed:

1. a free-running ID counter — **not enough.** Its pattern repeats every `NID`
   cycles, so mX1 simply waited for its own ID to come round again and still
   reached 8.
2. an ID keyed to how many that master has already had **accepted**, so the
   outstanding set holds distinct IDs. mX1 now stalls at **1**.

| input | outstanding @ `MAX_TRANS=8` | reorderings | verdict |
|---|---|---|---|
| reference (`CUT_ALL_AX`) | 27 | 914 | **PASS** |
| reference (`NO_LATENCY`) | 25 | — | **PASS** |
| second source | 8 | 234 | **PASS** |
| `mX1` | **1** | 0 | **FAIL — C1 only, 4 failing checks** |

Reordering is now a `METRIC:` line and gates nothing.

## Sweep, and the blind spot

| input | configs |
|---|---|
| reference | **16/16** |
| second source | **16/16** |
| candidate | **16/16** |
| `mX1` | **8/16** — fails every `MAX_TRANS=8` config |

**mX1 survives all eight `MAX_TRANS=2` configurations**, and this is structural,
not an oversight. The C1 floor is `ceil(MAX_TRANS/2)`, which is 1 there, and the
floor cannot be raised: the `NO_LATENCY` anchor — a correct crossbar — still
delivers exactly **1** at that setting even with mixed IDs. Any floor that
catches mX1 at `MAX_TRANS=2` also fails a correct design.

The same blind spot as C2's at `MAX_TRANS=2`, from the same cause: at two
outstanding there is too little room for capacity defects to show. Both checks
bite at `MAX_TRANS=8`, which every sweep includes.

---

# d_nw01 candidate — PPA: DID NOT COMPLETE

The re-solicited candidate fixed its capacity gap by provisioning a 256-entry
per-master read buffer (36 864 bits). The ORFS build reached detailed routing
and **failed with 2003 DRC violations**, after passing synthesis, floorplan,
placement, CTS and global route.

| stage | reference | candidate |
|---|---|---|
| synth area | 107 891 µm² | **1 540 648 µm²** — 14× |
| post-placement area | 146 818 µm² | **1 835 465 µm²** — 12.5× |
| timing at global route | +7.83 ns final | +5.22 ns worst slack, TNS 0 |
| detailed route | completed, DRC 0 | **FAILED, 2003 violations** |

**Timing was never the problem — congestion was.** 36 kbit of read buffering as
flip-flops creates routing demand the flow cannot satisfy.

**Not retried, and not to be retried.** Failing to close is the result, and it
is consistent with the other two measurements on this candidate: over-building
cost it 14× area, 5× single-pair throughput, and now physical closure.

*Caveat, stated rather than buried:* a 12 % utilisation floorplan on a
1.8 M µm² design is an unusual corner, so the DRC count is not a precise measure
of anything. The robust finding is the **12–14× area**, which two independent
stages agree on. Raising `SYNTH_MEMORY_MAX_BITS` to let the build proceed was
the right call — aborting at synthesis would have hidden a real physical
consequence behind a tool guard — but it does mean this is not a routine
configuration.

---

# CANONICAL REFERENCE CONFIG — reported as a Pareto envelope, not a winner

Both configurations pass all 16 configs. Both are legitimate implementations of
a spec that **explicitly does not constrain latency**. Measured at each one's own
Fmax, with only closing runs counted:

| | `CUT_ALL_AX` (shipped) | `NO_LATENCY` |
|---|---|---|
| Fmax | **≥ 190.48 MHz** (5.25 ns) | **126.98 MHz** (7.875 ns) |
| converged? | **no** — bracket [4.5, 5.25] is 0.75 ns wide | yes — [7.5, 7.875], 0.375 ns |
| area at own Fmax | **ABSENT** (was 154 245 µm²; F20) | *100 277 µm² (provisional, corroborated)* |
| area at 12 ns | 146 951 µm² | 86 133 µm² |
| synth area | 107 891 µm² | 59 209 µm² |
| elasticity, closing range | +5.0 % | **+16.4 %** |

**`CUT_ALL_AX` is at least 1.50× faster and 54 % larger at its own Fmax.**
Neither dominates. Which is "better" depends entirely on a frequency target the
specification never states — the same shape as the `d_ca04` result, on a
different axis.

## Therefore the baseline is the envelope, not a point

The reference exists to be the thing candidates are compared against, and the
choice of configuration silently picks a side:

- with `NO_LATENCY` canonical, a candidate that pipelines looks **bad on area**
  and good on Fmax;
- with `CUT_ALL_AX` canonical, a candidate that does not pipeline looks **good on
  area** and bad on Fmax.

Since the spec permits either strategy, **picking one configuration as "the"
reference builds an arbitrary preference into every comparison.** Both are
therefore recorded as the baseline, and a candidate is reported against the
envelope: does it land inside, on, or outside the line joining these two points.

`CUT_ALL_AX` remains the **build default**, purely because the ORFS harness and
every historical number use it — not because it is the better design. Any figure
quoted against it must say so.

## Consequence for previously quoted numbers

The 3.1× decomposition — *1.82× off-spec pipelining × 1.70× capability gap* —
was computed against synthesis area. It stands, and the envelope now makes the
first factor concrete: `CUT_ALL_AX` really does cost 54 % more area at own Fmax,
and buys at least 1.5× the speed for it. It is off-spec, not free.

## Elasticity — the first design where area moves materially

`NO_LATENCY` grows **+16.4 %** across its closing range, against `CUT_ALL_AX`'s
+5.0 % and `d_ca04`'s +1.5 %. Removing the pipeline registers forces the tool to
buy timing out of logic instead, which is exactly where area is elastic.

This is the first configuration measured where area × delay could carry
information independent of area and Fmax. It is still only 16 %, so the
conclusion in `FINDINGS.md` stands — no design yet found where AD changes an
answer — but it is the closest case so far and worth re-testing if a candidate
lands near the envelope.

---

# MUTANT TABLE

| mutant | class | killing check | non-equivalence witness |
|---|---|---|---|
| `mCAP1_one_outstanding_per_master` | **CAPABILITY** | **C1** capacity, 4 checks, nothing else | differential, cycle 0 |
| `mX1_no_cross_id_interleaving` | capacity / mixed-ID | **C1** capacity, `MAX_TRANS=8` only | differential, cycle 0 |
| `mC2_serialised_xbar` | concurrency | **C2**, at exactly 100 % speedup | **checker** — see below |
| `mL1_ar_arbiter_never_grants` | liveness / deadlock | `LM_STALL` | **checker** |
| `mL2_master0_starved` | liveness / starvation | `LM_STARVE` in the liveness rig; `LM_STALL` in the full checker | **checker** |
| `mD1_same_id_two_slaves` | ordering, per-ID | per-(master,ID) data mismatch | **checker** |
| `mD2_decerr_truncates_burst` | decode / beat count | RLAST-on-wrong-beat | **checker** |
| `mD3_decerr_drops_beats` | decode / liveness | `LM_STALL` — a data defect caught by the liveness monitor | **checker** |

## Two ways of witnessing non-equivalence, and neither is weaker

**Differential** — reference and mutant instantiated together, identical
stimulus, outputs compared, witness cycle recorded.

**Through the checker** — the checker passes the reference and fails the mutant
under identical stimulus. **That is a witness of behavioural difference by the
same logic as a direct diff**, observed through the checker rather than through a
comparator. It is not a weaker standard, and the column records the named killing
check rather than being left blank.

**The differential harness cannot cover mutants of a shared module.** `mL1`,
`mL2`, `mD1`, `mD2` and `mD3` mutate a *vendored* module, and both instances in
the harness would resolve to the same mutated file, so there is nothing to
compare. Building renamed duplicate copies of the vendored closure to force them
through would buy nothing — the checker already provides the witness, and diff
rate is demoted (see below).

## Diff rate is demoted — do not read the numbers as quality

`mCAP1` diverges on **100 %** of cycles and is the most valuable mutant here.
`mC2` diverges on **0 %** and is comfortably killable — the harness holds slave
responses at zero to keep its stimulus protocol-legal, so nothing completes and a
slave-side defect cannot manifest. The metric measures pervasiveness under one
stimulus and is uncorrelated with value. See `FINDINGS.md § RETRACTED`.

The harness now reports `non_equivalence_demonstrated` and a `witness_cycle`
rather than a rate, because **a zero means this stimulus did not distinguish
them, never that the designs are equivalent.**

**Mutant quality is deferred to the cross-model run.** It is a posterior — a
mutant everything kills is filler, a mutant nothing kills is too hard — and
neither is knowable before submissions exist.

---

# CUT_ALL_AX Fmax — CONVERGED, closed by one targeted build

The sweep aborted at 5.25 ns on a missing metrics file and reported 6.0 ns /
166.67 MHz. The flow had in fact completed (+0.04 ns, DRC 0), so the report
fallback moved the lower bound to 5.25 ns — but the bracket [4.5, 5.25] was
0.75 ns wide against a 0.5 ns resolution, so `find_fmax` correctly refused to
call it an Fmax.

**Closed by one build at 4.875 ns, which FAILS**: worst slack −0.22 ns,
TNS −5.84, DRC 0.

| | |
|---|---|
| final bracket | **[4.875, 5.25] ns — 0.375 wide, inside the 0.5 resolution** |
| **Fmax** | **190.48 MHz at 5.25 ns, CONVERGED** |
| area at own Fmax | **ABSENT** (was 154 245 µm²; F20) |

One build, ~15 minutes, rather than a 2.5-hour re-sweep — the bisection only
needed its last point. **Nothing in this task now ships an unconverged Fmax.**

## The envelope, both points converged

| | `CUT_ALL_AX` | `NO_LATENCY` |
|---|---|---|
| Fmax | **190.48 MHz** (converged) | **126.98 MHz** (converged) |
| area at own Fmax | **ABSENT** (was 154 245 µm²; F20) | 100 277 µm² |
| elasticity, closing range | +5.0 % | +16.4 % |

**1.50× faster for 54 % more area.** Neither dominates.

## The second source is NOT an envelope point

The envelope contains **only the anchor's legitimate configurations** —
externally authored, production RTL — and that is the entire reason a comparison
against it means anything.

**The second source is ours.** It exists as an over-constraint control and it is
only as good as our engineering. Folding it into the baseline would judge
candidates partly against our own implementation quality, which is precisely the
criticism we would level at anyone using a self-authored oracle. It cuts both
ways: a weak second source flatters every candidate, a strong one penalises them,
and in neither case is the number about the candidate.

So it is plotted as a **distinctly labelled third point — internally authored,
control, not baseline** — and candidate claims are stated against the envelope
only. If it lands inside the envelope, that is worth saying: confirmation the
contract is achievable by more than one design. If it lands outside on some axis,
that is recorded as interesting and **does not move the bar**.

`task.yaml` keeps it under a separate `ppa_internal_control` key rather than as a
third row of `ppa_reference_envelope.points`, for the same reason the run records
are immutable: **if two things can be confused, eventually they will be.**
