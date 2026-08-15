# d_nw01 `axi4_xbar` — build notes

Catalog v3. Verilator **5.046**. **In progress** — the negative control and the
liveness mutants are complete; the full data/ordering checker is not yet built.

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

## Mutant table (liveness classes only so far)

| id | class | injected bug | killing check |
|---|---|---|---|
| mL1 | liveness-deadlock | read-address arbiter never sees a request | `LM_STALL` |
| mL2 | liveness-starvation | slave port 0 masked out of the arbiter | `LM_STARVE`, and not `LM_STALL` |

Data, ordering, decode-error and reset mutants are still to come with the full
checker.

## Still to build

* full checker: per-ID ordering scoreboard, write channel, `DECERR` on unmapped
  addresses, response routing back to the originating master
* the remaining mutant classes
* second source
* ORFS
