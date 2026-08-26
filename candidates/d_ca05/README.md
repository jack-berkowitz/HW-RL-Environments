# candidates/d_ca05

Drop model answers here as `<model>.sv`, one file each. Score with:

    scripts/sim_candidate.sh d_ca05 candidates/d_ca05

The task text to paste is
`domains/comp_arch/design/d_ca05_miss_handler_arb/probe/PASTE.md`, together with
`spec/miss_handler_arb_pkg.sv`, which is named from inside the interface and is
part of the problem statement. No reference, no vectors, no testbench, no
controls.

## Task text hash

    7e4dbccc8ccabf44

It supersedes nothing — this is the task's first text. **Recompute at the point
of use** rather than quoting this line.

## Configuration

ONE configuration: `NR_PORTS = 4`. The geometry is fixed by the package as
concrete numbers — SET_ASSOC 8, INDEX 12, TAG 44, LINE 128, OFFSET 4,
NUM_WORDS 256, AXI id/addr/data 4/64/64 — so a submission never reconstructs it.

## What is scored

**Correctness is a GATE**, bit-exact on every output port against the reference.

**Cycles** are a second axis, and unlike `d_ai04` this task has one: the flush
walk's 512 array accesses are a real cost a design can trade against area.

**Area and power are NOT AVAILABLE YET** — G1 pins the measurement period at
1.5× the reference's own, and that sweep has not been run. Do not quote an area
from this task until that boundary lands.

## The three clauses submissions will land on

* **Arbitration is strict lowest-index priority and it starves.** A fair arbiter
  is a specification violation here, not an improvement. The catalog promised
  "no requester starvation" until `55c40c5`; it was refuted by measurement.
* **The two MSHR match outputs overlap** — an address match *implies* an index
  match, and the requester being served is *not* excluded. The anchor's own
  comments say otherwise on both counts, and the code is the contract.
* **A flush requested in the same cycle as an atomic is never acknowledged.** The
  walk runs in full; `flush_ack_o` never pulses. Invisible unless flush and
  atomic are exercised together.

## Four negative controls, all holding

The reference PASSES and all four FAIL. `nc_a_fair_arbiter` fails **T2 alone**,
`nc_b_exclusive_match` **T3(a) alone**, and `nc_d_ack_amo_flush` fails both AMO
acknowledgement cases while **passing the genuine flush** — so T5's three cases
are independently checked. Matrix and one instructive control bug in
`CONTROLS.md`.

**Not covered by any control:** T4, T6 and T8. Stated in `task.yaml` rather than
left to be inferred.

## Two things are rejected before simulation

A candidate that prints its own `TEST_RESULT` line (forged verdict), and one that
declares the wrong module name. The module is **`miss_handler_arb`**.
