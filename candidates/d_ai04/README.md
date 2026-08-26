# candidates/d_ai04

Drop model answers here as `<model>.sv`, one file each. Score with:

    scripts/sim_candidate.sh d_ai04 candidates/d_ai04

The task text to paste is
`domains/ai_accel/design/d_ai04_sdp_requant/probe/PASTE.md`. It is the contract
and nothing else: no reference, no vectors, no testbench, no controls.

**The prompt is self-contained.** A submitter does not need the NVDLA anchor and
is not told which anchor it is. Every value the contract depends on is written
out in the text.

## Task text hash

    bcf0d0df4071c9ea

It supersedes one earlier text, `3140fecdb730cc07`, and **no result is affected
because nothing was ever solicited against it.** The change is not behavioural:
every clause in F, A, P, T and G is byte-identical. What moved was the framing
paragraph, which pointed a submitter at `MEASUREMENTS.md` — a repository file
they do not have. A prompt that cites a document its reader cannot open is a
defect in the prompt, and it was cheaper to fix before the first solicitation
than to explain afterwards.

**Recompute at the point of use** rather than quoting this line:
`scripts/task_text_hash.py domains/ai_accel/design/d_ai04_sdp_requant`. A hash in
a document is a snapshot and the document outlives the snapshot.

## Configuration

ONE configuration, and one by construction rather than omission. `sdp_requant`
declares **no parameters**: P1 pins four lanes and the 16b/32b lane widths, and
every other axis is a runtime input swept by the stimulus.

| | |
|---|---|
| lanes | 4 |
| input lane / output lane | 16b signed / 32b |
| `cfg_offset` / `cfg_scale` | 32b signed, **subtracted** / 16b signed |
| `cfg_truncate` | 0–63 |
| `cfg_precision` | `2'd2` = float; `0`, `1`, `3` = integer, indistinguishable |

## What is scored

**Correctness is a GATE.** Bit-exact on `out_data`, `out_valid` and `in_ready`
against the reference, over 44 anchor-measured words and 800 swept ones, plus
the flow-control, configuration-pipelining and reset checks. No partial credit.

**Area and power are the second axis and are NOT AVAILABLE YET.** Spec G1 pins
the measurement period at 1.5× the reference's own measured period, and that
reference Fmax sweep has not been run. `orfs/config.mk` and
`orfs/constraint.sdc` exist so it can be; the 40 ns in the SDC is a loose
starting constraint, explicitly **not** a derived figure, and any area recorded
at it is not comparable to a build at the eventual pin.

**Do not quote an area from this task** until that boundary lands with its own
record. Correctness scoring does not depend on it, so candidates can be
solicited and scored now.

There is no cycle axis: A4 pins throughput at one word per cycle, so every
conforming submission takes the same number of cycles and a count would
distinguish nothing. There is no capability axis either — P1, P2 and A4 leave no
dimension along which a submission may do *more*.

## Reference and second source

| | verdict | latency | slots | words accepted |
|---|---|---|---|---|
| reference, `ref/sdp_requant_ref.sv` | PASS | 1 | 2 | 945 |
| second source, `tb/sdp_requant_alt_ref.sv` | PASS | 2 | 3 | 951 |

The second source was **written from `spec/` alone** and is deliberately a
different design in all three places the contract leaves free (P3): two pipeline
stages instead of combinational compute, floor-then-correct rounding in the
signed domain instead of round-half-up on the magnitude, and a priority case over
the subnormal mantissa positions instead of a counting loop.

**Two conforming designs with different latency and different buffer depth both
passing is the evidence that the contract constrains behaviour without
constraining structure.** If the testbench had quietly assumed the reference's
latency of 1, the second source would have failed it — that was the point of
building one with a latency of 2.

Both agree with the vendored NVDLA anchor on **1728 words, 0 differing**
(`tb/audit/sdp_requant_xcheck_tb.sv`, an audit rig outside the scored path).

## Nine negative controls, all holding

Each is the reference with exactly one defect; all nine FAIL and the reference
PASSES. Full matrix in `CONTROLS.md`. The two worth knowing before reading a
submission:

* **`nc_d_single_register`** satisfies A2 and fails A3 — `in_ready` is constant,
  so there is trivially no combinational path from `out_ready`, and it loses a
  word when the consumer stalls in the cycle a second arrives. On open flow it is
  byte-identical to the reference. Expect submissions to land here.
* **`nc_b_round_half_up`** — the natural `(v + (1<<(t-1))) >>> t` — differs from
  the anchor on only **6 lanes out of nearly 7,000** in random stimulus. That is
  why the scoring rig carries five *directed* negative-tie vectors: random
  sweeping alone would miss it most of the time.

## Two things are rejected before simulation

A candidate that prints its own `TEST_RESULT` line (forged verdict), and one that
declares the wrong module name. The module is **`sdp_requant`** — the catalog
carried `sdp_requant_pipeline` until `55c40c5` and a submitter reading the old
row would have used it.
