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
