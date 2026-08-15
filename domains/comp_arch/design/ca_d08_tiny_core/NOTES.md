# ca_d08 `tiny_core` — build notes

Verilator **5.046** and Icarus **13.0** (pinned in `refs.lock`) for every result
below.

## Oracle class B — what is and is not claimed

No external RTL oracle runs, so *"the checker passes known-correct external RTL"
is not available and is not claimed.* The oracle is `ref/model/rv32i_iss.py`
plus 20 committed programs and their retire traces. The three substitute
guarantees are recorded in `ref/PROVENANCE.md`; the third — that mutation
testing carries the sharpness argument alone — is the reason the mutant table
below is the most important section here.

## The checker caught a real bug in my own reference

The first full run failed 4 checks, all the same defect, and **the defect was in
`ref/tiny_core_ref.sv`, not in the checker**:

```
retire 19 (pc 0x0000004c): rd_val=0x40000000 expected 0xc0000000
```

`sra` was performing a *logical* shift. The cause is a SystemVerilog signedness
trap worth recording, because it is invisible on inspection:

```systemverilog
// WRONG -- the unsigned srl branch makes the whole conditional expression
// unsigned, which silently demotes a_s and turns >>> into a logical shift
alu_r = (f7 == 7'h20) ? (a_s >>> shamt) : (a >> shamt);
```

Fixed by computing each shift in an isolated wire so signedness stays
self-contained. This is exactly how a Class B task is supposed to behave: the
ISS is the oracle, the RTL is mine, and when they disagree the RTL is wrong.
Mutant `m02` now re-injects this bug deliberately.

## Spec decisions

**The retire interface is pinned; everything behind it is free.** A trace-based
checker cannot work unless the core reports what it committed, so port names,
widths, one-retire-per-cycle, and the `x0` reporting rule are all normative.
Pipeline depth, forwarding vs interlocking, branch prediction and per-instruction
cycle counts are explicitly *not* checked.

**The comparison is order-based, never cycle-stamped** — the Nth retire against
the Nth trace entry, at whatever cycle it arrives.

**`retire_rd_val` must be 0 when `retire_rd` is 0.** An instruction encoding
`rd == x0` still retires but writes nothing, so reporting the computed value is
a spec violation. Called out explicitly because it is the single most likely
place to differ silently; mutant `m01` targets it.

### Two spec bugs found by running, not by reading

* **R9 was over-constrained.** It originally required `retire_valid == 0` in the
  first cycle after reset release. A single-cycle core legitimately retires in
  its very first active cycle, and the reference failed its own spec. Since the
  delay before the first retire is a pipeline-depth artifact — and pipeline depth
  is explicitly free — R9 now constrains `retire_valid` only *while* reset is
  asserted.
* **Programs read registers they had never written.** R11 says reset need not
  clear `x1..x31` (zeroing 31 registers is real hardware for no architectural
  benefit), but the ISS starts them at zero while `--x-initial unique` randomises
  the RTL's. The randomised programs read unwritten registers and a branch went
  the wrong way. Fixed in the generator, not the spec: every program now begins
  with a `REG_INIT` preamble writing every register it later reads, so reset
  values are never observable. The alternative — mandating a register-file reset
  — would have been a spec change to accommodate a generator bug.

## Sizing

`IMEM_AW`, `DMEM_AW` ∈ {8, 10, 12} words. Memories are supplied by the
environment, so this parameter only sets address decode width; there is no
DEPTH×DEPTH structure and none of the synthesis blowup risk that forced the
`lsq` and cache cuts.

## Step 4 — checker passes correct RTL

| IMEM_AW=DMEM_AW | Verilator | Icarus | coverage holes |
|---|---|---|---|
| 8 | PASS | PASS | 0 |
| 10 | PASS | PASS | 0 |
| 12 | PASS | PASS | 0 |

```
METRIC: programs=20 retires_checked=831
// coverage: alu=582 shift=49 load=46 store=44 lui=26 auipc=13
// coverage: br_taken=21 br_ntaken=18 jal=26 jalr=6 x0_write=48 sra=17
// coverage: programs=20 longest=105 retires
TEST_RESULT: PASS
```

Icarus needed two changes, both in the harness: `automatic` variables inside
`always_ff` (unsupported — hoisted to module scope) and a conditional expression
between two enum values in the second source (needs an explicit cast — replaced
with `if`/`else`).

`jalr` was initially the thinnest-covered instruction at **1 retire across the
whole suite**, despite the spec calling out two of its corners by name. Added a
dedicated `jalr_corners` program covering a plain indirect jump, `rd == rs1`, an
odd target whose LSB must be cleared, `rd == x0`, and a negative offset. My first
attempt at it miscomputed the targets so the jumps skipped three of the five
`jalr`s; corrected against the actual word layout, and all five now execute.
Coverage is now 6.

## Step 5 — second source

**Mandatory for `ca_d08`, and performed.** `tb/tiny_core_alt_ref.sv` is a
multi-cycle FSM (`FETCH → EXEC → [MEM] → WB`) against the reference's
single-cycle structure:

| reference | second source |
|---|---|
| single-cycle | multi-cycle FSM |
| retires every cycle | every 3 cycles (ALU/branch/jump), every 4 (load/store) |
| constant cadence | **variable**, instruction-dependent |
| combinational fetch→retire | retire driven from registers in `WB` |

It **passes all three configs on both simulators.** The evidence that this
actually exercised the order-based property: the same suite takes **9 µs** with
the single-cycle reference and **27 µs** with the multi-cycle second source. A
checker that assumed one retire per cycle, or a fixed cycle count per
instruction, would pass the reference and fail this.

Unlike `nw_d01`, the second source found no over-constraint here — the checker
was already order-based by construction.

## Step 6 — mutation testing

Seven mutants, one bug each, seven distinct classes. All elaborate, all
simulate, all killed, every one in a **directed** program.

| id | class | injected bug | killing check | diff rate |
|---|---|---|---|---|
| m01 | spec-violation-x0 | `retire_rd_val` reports the computed value for `rd == x0` | `rd_val=0x3e7 expected 0x0` | 906 611 ppm |
| m02 | arithmetic-sign | `sra` degraded to a logical shift | `rd_val=0x40000000 expected 0xc0000000` | 222 ppm |
| m03 | boundary | shift amount not masked to `rs2[4:0]` | `rd_val=0x0 expected 0xc80` | 944 ppm |
| m04 | boundary | `jalr` does not clear the target LSB | `pc=0x61 expected 0x60` | 111 ppm |
| m05 | control-flow | `blt`/`bge` compare unsigned | `pc=0x5c expected 0x60` | 6 833 ppm |
| m06 | reset | reset does not restore PC to 0 | `pc=0x6c expected 0x0` | 900 500 ppm |
| m07 | decode | store address uses the I-type immediate | `store addr=0x42 expected 0x40` | 2 277 ppm |

### Diff-rate band — third module, and the recommendation is now firm

Three modules of data:

| task | spread |
|---|---|
| `ai_d01` | 0.18 % – 56 % |
| `nw_d01` | 0.0011 % – 98.9 % |
| `ca_d08` | **0.011 % – 90.7 %** |

The pattern is consistent and it argues against using diff rate as a filter:

* **The two highest here are the two weakest mutants.** `m01` (90.7 %) and `m06`
  (90 %) are filler — writes to `x0` and resets are everywhere, so any submission
  that looks at the retire stream at all catches them.
* **The lowest is among the best.** `m04` at 111 ppm — roughly one cycle in nine
  thousand — is the `jalr` LSB corner the spec names explicitly, and it dies
  deterministically in a directed program written to find it.

**Recommendation, unchanged from `nw_d01` and now confirmed: use diff rate as a
report-only diagnostic, never as a gate.** Flag anything above ~25 % for review
as probable filler; flag nothing at the bottom. A low rate means "make sure a
directed test kills it", not "discard it". Adopting a lower bound would have
thrown away `m04` here and `m06` on `nw_d01`, which are the two sharpest mutants
in the whole set so far.

## Step 7 — PPA

**Deliberately not run.** `ca_d08` is Class B and the project owner directed
that ORFS builds are deferred for every task without an external RTL golden
model; clock and area baselines come later. See
`DESIGN_TASKS_NO_GOLDEN_RTL.md`. `orfs/` is intentionally absent from this task
rather than present and empty.

## Open items

* Nothing blocking.
* The darkriscv cross-check covers **encodings only**, not execution semantics —
  no co-simulation was run. Scope and reasoning in `ref/PROVENANCE.md`. If a
  stronger guarantee is wanted later, wrapping darkriscv's bus and diffing its
  writeback against these traces is the cheapest route; SERV is not, being
  bit-serial with no clean retire point.
