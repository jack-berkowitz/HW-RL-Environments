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

Per the standing procedure in `CATALOG_V3_HARD.md`: *a checker whose failure
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
the corrected runner: `ai_d01` 4/4, `nw_d01` 16/16, `ca_d08` 3/3, `d_ca04`
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
