# OPEN DEFECT — `tb/audit/fp32_fma_ii1_second_source.sv`, flush-to-zero region

**Status: OPEN. Filed by Agent 3, NOT OWNED BY Agent 3, NOT FIXED.**
Nothing in this file has been repaired. The second source has not been edited.
`d_dsp02` is **not** marked green on the strength of this filing.

Filed because repairing another owner's second source in passing is how
independence quietly disappears — the value of a second source is that nobody
tuned it to agree.

## What fails

10 of 4340 checks, all in one shape: **smallest subnormal squared**, both signs,
all five rounding modes. The 50 band vectors added to `vectors/inputs.hex` are
what reached it. `BAND`, `LOW`, `HIGH` and `EXACT` all pass — this is not the
underflow-flag clause.

## Reproducers, verbatim

```
vector 4322: a=00000001 b=00000001 c=00000000 rnd=2 -> result 80000000, reference says 00000000
vector 4323: a=00000001 b=00000001 c=00000000 rnd=3 -> result 00000000, reference says 00000001
vector 4325: a=80000001 b=00000001 c=00000000 rnd=0 -> result 1d000000, reference says 80000000
```

Two of the ten are flags-only; the rest are **wrong result bits**.

## Diagnosis

The exact product of two smallest-subnormals is 2^-298, far below anything the
format can represent. It must deliver a signed zero (or the smallest subnormal
under RUP for a positive operand).

`1d000000` is approximately 1.7e-21. That is the **significand product
surviving while the exponent wraps** — the mantissa arithmetic is carried out
and the exponent underflows out of range without being clamped to the subnormal
path. Vector 4322 shows the same defect in its sign handling: `-0` returned where
`+0` is required, on operands that are both positive.

## Evidence it is the second source, not the harness or the anchor

* the **reference shim** is correct on all ten;
* `d_dsp03`'s **anchor** is correct on the identical cases in all three formats;
* `d_dsp03`'s **second source**, independently written, is correct on them too;
* `d_dsp02`'s own **Python oracle** (`tb/audit/independent_fma_oracle.py`) is
  correct on them;
* the ten failures are confined to one operand shape, not spread.

The checker, the vectors and the anchor all agree with each other and disagree
with this one artefact.

## Scope — why it was never seen

The original 4290 vectors never produced a product that far below the subnormal
range. The region is not rare in principle; it simply was not generated. The
prior record of **4290/4290 is accurate over the set it was measured on** and
says nothing about this region — see F59.

## What is NOT affected

* `d_dsp02`'s landed correctness results and its scored configuration;
* the reference, the mutants, or any candidate score;
* the original 4290 vectors, which are **byte-identical** after the re-capture
  that added the band cases — verified by diff, not assumed.

## For the owning agent

Under Tier-B's rule this would be **logged, not debugged to green**. `d_dsp02`
is a full-rigor task and the call belongs to whoever owns it.

`task.yaml`'s `second_source: result: 4290/4290` needs rewording either way, to
name the set it was measured on and record that the extended set exposes these
10 failures. The prior number should not be deleted.
