# d_dsp02 `fp32_fma_ii1` — build notes

**The first task built under the full rule set from the start.** Every earlier
finding came from a task built before the rules existed, so the interesting
outcome here is a defect class the ten rules do not catch.

## Step 1 — anchor: elaboration and semantics, reported separately

**Elaboration: PASS.** `refs/cvfpu/src/fpnew_fma.sv`, cvfpu `6e5267e`, SHL-0.51
verified. Clean at `FpFormat=FP32, NumPipeRegs=0`.

**Semantics: PASS, 15/15 directed known-answer cases.** Measured, not read:

| claim | how it was confirmed |
|---|---|
| it is an FMA | `1×1+1=2`, `2×3+4=10`, `(−2)×3+4=−2` |
| **single** rounding | the discriminator below |
| five rounding modes | RNE/RTZ/RDN/RUP/RMM on an exact tie, all distinct |
| subnormals in-pipeline | smallest subnormal survives; no flush-to-zero |
| tininess after rounding | `uf_after_round`, with upstream's own note that RISC-V mandates it |
| specials | `0×Inf`, `Inf−Inf`, signed zero under RNE vs RDN |

**The single-rounding discriminator.** `a=b=1+2⁻¹²` gives an exact product of
`1 + 2⁻¹¹ + 2⁻²⁴`. The `2⁻²⁴` term is past the 23-bit mantissa, so an *unfused*
unit rounds the product to `1+2⁻¹¹` and a subsequent `c = −(1+2⁻¹¹)` cancels to
exactly **zero**. A *fused* unit returns **2⁻²⁴**. Different answers, so it
separates the two designs rather than merely testing arithmetic.

### A worked example of why the oracle cannot be locally authored

The first version of that discriminator **failed, and the anchor was right.** I
hand-computed `(1+2⁻²³)² − 2⁻²⁴` and expected `0x34000000`. The true result is
`1 + 1.5×2⁻²³` plus a `2⁻⁴⁶` term — just above halfway — so RNE correctly rounds
up to `0x3F800002`, which is what the anchor returned.

**An IEEE-754 corner case computed by hand was wrong on the first attempt, on the
very task whose oracle was to be locally authored.** It was caught only because
the anchor disagreed. That is the whole argument for the inversion below.

## The oracle is the anchor. Python generates INPUTS ONLY.

| | |
|---|---|
| `gen/generate_inputs.py` | produces `(a, b, c, rnd)` tuples. **Computes no expected value.** |
| `tb/audit/capture_vectors_tb.sv` | runs every tuple through the vendored anchor |
| `vectors/vectors.hex` | `{a, b, c, rnd, result, flags}` — **expected values authored by nobody on this project** |

The rejected alternative was a local model producing expected values,
cross-checked against the anchor. That leaves a hole: **a shared misconception
survives the cross-check, because both sides agree for the same wrong reason.**
The hand-computation error above is the proof of concept.

Under the inversion, **a Python bug can cost coverage and can never produce a
wrong expected value.** This makes the task fully Class A rather than Class A
with a local oracle bolted on.

**So the risk moves entirely to input coverage**, and every coverage floor in the
checker is stimulus-side: it counts what the vector set *drove*, tallied from the
file before a cycle runs, never what the design did. An unreached floor fails the
run.

Nine independent IEEE spot-checks against the captured vectors all matched,
including `(−0)+(+0)` under RNE vs RDN, the fused-cancellation case, ties under
all five modes, and overflow under RNE vs RTZ.

## Vector set — 4290 tuples

| category | count | floor |
|---|---|---|
| subnormal operands | 1223 | yes |
| subnormal results | 146 | yes |
| signalling NaN | 31 | yes |
| quiet NaN payload, operand a / b | 46 / 42 | yes, both orders |
| zero results | 40 | yes |
| overflow / underflow | 486 / 103 | yes |
| tininess boundary | 195 | yes |
| exact results | 640 | yes |
| **inputs where modes disagree** | **80** | **yes** |
| each rounding mode driven | 837–884 each | yes, all five |

Reproducible: fixed seed `0xD5F02`.

## Reference result

**4290/4290, zero coverage holes.**
**C3: 4290 offered, 4290 accepted, 0 dead cycles** — the anchor meets II=1 at
`NumPipeRegs=0`. K=1 came from the task's intent (inner cell of a MAC array,
where a stalling FMA is unusable) and was *verified* against the anchor, never
derived from it.

## Rounding-mode probe — run BEFORE the mutants

Per rule 1, audit by probe rather than by reading. `tb/audit/
p1_ignores_rounding_mode.sv` is the vendored anchor with `rnd_mode` tied off to
RNE — **a completely correct FMA in every other respect**, bit-exact on normals,
subnormals, NaNs and flags, at full rate. The only defect is that a runtime
capability the spec requires is not implemented. It is the `MAX_TRANS` question
in a different domain.

**Result: FAIL, 1136 failing checks of 4290.**

| rounding mode | failures |
|---|---|
| **RNE (0)** | **none** — the probe implements it correctly |
| RTZ, RDN, RUP, RMM | all failures |

And **isolated**: C3 still shows 0 dead cycles, and there are no coverage holes.
It fails on rounding and nothing else.

**So the rounding mode is BOUND and the vector set has real discriminating
power.** Had it passed, the requirement the task is largely about would have been
decorative — a second `MAX_TRANS` — and the mutants would have been built on a
vector set that could not tell the difference.

## Shim configuration, recorded because it is not part of the contract

`NumPipeRegs = 0` — the **spec-minimal** choice. The anchor is parameterised for
pipelining and the spec does not constrain latency, so zero adds nothing the
contract does not ask for. Compare `d_nw01`, where a shim bound `CUT_ALL_AX` and
handed the reference 45 % of its area in pipelining nobody required.
