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
