# candidates/d_ai01

Drop model answers here as `<model>.sv`, one file each. Score with:

    scripts/sim_candidate.sh domains/ai_accel/design/d_ai01_fp16_gemm_array candidates/d_ai01

The task text to paste is
`domains/ai_accel/design/d_ai01_fp16_gemm_array/probe/PASTE.md`. It is the
contract and nothing else: no reference, no vectors, no testbench.

## Task text hash

    86b7d95729381055

It **supersedes three earlier texts**: `84950ba1d90be2d8`, `e43648a5afcacc53` and
`9a93e4502979efc9`.

The first two boundaries were BEHAVIOURAL -- clauses were pinned or narrowed, the
set of scored cycles changed, and no result measured against them is comparable.

The third, to this text, is NOT: it added the grading clauses G1-G4 and changed no
behavioural requirement. Every clause in F, V, A, C, L, P and T is byte-identical
across it, and re-running reproduces every number exactly. A design conformant
against `9a93e4502979efc9` is still conformant here. The hash changed because the
shipped text changed, which is what the hash is for.

**A submission cannot infer comparability from the vector files.** The vector
sets are BYTE-IDENTICAL across both boundaries — same stimulus, same recorded
reference behaviour. What changed each time is the SET OF SCORED CYCLES, because
clauses that asserted determinism the contract could not deliver were narrowed
rather than modelled. Matching vector hashes therefore say nothing about whether
two numbers can be compared; only the task text hash does.

## Configurations

Two geometries, both of which a submission must pass:

| HEIGHT | WIDTH | |
|---|---|---|
| 4 | 8 | |
| 8 | 8 | **scored** |

**HEIGHT=8 is the scored configuration, and the reason is measured.** HEIGHT sets
both the chain latency and the per-stage operand skew of clause A3, so a design
that hardcodes a depth cannot pass both. The capacity control
`nc_g_height_blind_depth` pins the chain depth to a literal 4 instead of deriving
it from HEIGHT and keeps HEIGHT-wide ports:

    HEIGHT=4   PASS   0 kills of 3157 scored cycles
    HEIGHT=8   FAIL   2752 kills of 2937 scored cycles

HEIGHT=4 cannot tell a HEIGHT-blind design from a conformant one; HEIGHT=8 can.
See `controls/CONTROLS.md` in the task directory.

## How a submission is graded

The contract's **G clauses** are normative and should be read before choosing an
architecture. In short:

* **Correctness is a gate, not a weighting.** Bit-exact on `z_o` and `status_o`
  at BOTH geometries, over the scored cycles. Fail either and there is no PPA
  number at all — recorded as a failure, not a missing measurement.
* **PPA is measured once at a pinned clock period**, not swept for a maximum
  frequency, so every submission is compared at one frequency. Axes: area
  (post-synthesis and post-route), power, and worst negative slack.
* **The usual lever is gone.** Latency, throughput and the arithmetic are all
  pinned — by L1, A3 and A1–A10. A submission cannot buy frequency by adding
  pipeline stages, because that changes the delivered values and fails
  correctness.
* **What is left** is how the fused multiply-add is built, how the WIDTH rows
  share logic given that `w_i` is broadcast identically to all of them, where
  state sits inside the fixed per-stage delay budget, and clock gating. That is
  where the whole PPA difference comes from.

## Gates

**Correctness before PPA.** A submission is scored for correctness first, at both
geometries. No PPA number is produced for a design that does not pass — a build
that fails scores zero on every PPA axis and is labelled a build failure, not a
missing measurement.

**T5 — elaboration under BOTH slang and Verilator.** Passing simulation is not
sufficient. The synthesis frontend is slang, and a construct Verilator accepts
silently can be a hard error there:

    error: unroll limit of 4000 exhausted [--unroll-limit=]

A per-bit search over a wide value — a leading-one scan, a priority encode, a
normalisation loop — nested inside a per-row and a per-stage loop exceeds that
budget. Give every loop a small constant bound, or express the search as indexed
logic. A bit-exact submission that trips this scores full correctness and
produces **no PPA number at all**, with the cause surfacing much later.

---

## GRADING NOTE — the scored geometry moved, and one control stopped covering it

**As of `34f1d43` the scored configuration is `HEIGHT=4, WIDTH=8`.** It was
`HEIGHT=8`. The move is physical, measured, and not a contract change: at
`HEIGHT=8` detailed routing does not close on sky130hd — 76,253 to 83,445
violations across three separate floorplans — and at `HEIGHT=4` it closes clean
at 0 violations, 710,752 µm². Both routed at the same 50 ns constraint.

**`HEIGHT=8` is still legal (P1) and T3 still requires a submission to hold at
BOTH.** What moved is which geometry carries the PPA comparison, not which
geometries a design must implement. `sim_candidate.sh` sweeps both.

### The part a reader will get wrong

**At the scored geometry, `nc_g_height_blind_depth` cannot discriminate. If you
assume it still covers HEIGHT at the scored config, you are wrong.**

`nc_g` pins the chain depth to the literal 4. That is *correct behaviour* at
`HEIGHT=4`, so it **PASSES** there, and it **FAILS** only at `HEIGHT=8`:

    nc_g_height_blind_depth    1/2    passes at +HH=4, fails at +HH=8

Two consequences, and the second is the one to act on:

* **T3 now carries a discrimination it was previously redundant with.** When
  `HEIGHT=8` was scored, the scored run alone caught a HEIGHT-blind design. It no
  longer does. The pair does; the scored geometry alone does not.
* **A PPA-only run at the scored configuration produces NO HEIGHT EVIDENCE.**
  Any flow that elaborates only `HEIGHT=4` — which is what a synthesis or
  place-and-route run does — is blind to whether the design uses HEIGHT at all.
  A PPA number from such a run is a number about *a* design, not evidence that
  the design is HEIGHT-parameterised.

### Grading rule that follows

**Correctness must be read across both configurations, never from the scored one
alone.** `1/2` and `2/2` are different verdicts and only the second is a pass.
The runner already enforces this — a candidate reported `1/2` has failed — but
the failing geometry is worth reading, because **failing only at `+HH=8` is the
`nc_g` signature**: a design that hardcoded the scored depth.

### Known gap, scoped and not yet closed

There is currently **no capacity-class control that fails at the scored
geometry.** The six controls that fail at both heights are arithmetic and
ordering controls; `nc_g` is the only capacity one and its polarity now points
away from the scored config. This is `d_nw01`'s `MAX_TRANS=2` lesson in a new
place — *a pass at the low setting is not capability evidence* — and the scored
setting is now the low one. Scoped in `task.yaml` under
`second_capacity_control_owed`; not built.
