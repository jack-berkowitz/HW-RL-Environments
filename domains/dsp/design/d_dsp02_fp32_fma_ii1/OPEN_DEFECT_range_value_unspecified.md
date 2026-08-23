# OPEN CONTRACT DEFECT — the delivered value outside the exponent range is unspecified

**Status: OPEN. Deliberately NOT fixed. Affects BOTH `d_dsp02` and `d_dsp03`.**

Deferred by decision, not oversight: a clause moves `task_text_hash` a third time
and invalidates three submissions solicited hours earlier. That is a scheduling
call and it is Jack's. Nothing here is a correctness risk to a landed result —
the vectors and the oracle already encode the right answers.

## What is missing

**No clause in either task states the delivered RESULT VALUE when the exact
product-sum falls outside the representable exponent range**, in either
direction.

* **Below the range.** Nothing says a nonzero value smaller than any
  representable increment rounds to `±0`, or to the smallest subnormal under the
  mode that rounds away from zero.
* **Above the range.** `d_dsp02`'s A4b says "OVERFLOW always raises `inexact`".
  `d_dsp03`'s A7 says "the rounded result exceeds the format's range". Both
  describe **when a flag is set**. Neither says whether the value delivered is
  `±inf` or `±maxfinite`, nor that the choice depends on the rounding mode.

It is inferable from A1's `RESULT = round(a*b + c)` plus the binary32 format
definition — round the exact value into the format, and both behaviours follow.
It is nowhere stated, and neither direction is named.

## Evidence it is a real gap and not pedantry

**Two independent artefacts failed in exactly this region**, and that is how it
was found — nobody found it by reading the spec.

    gemini (re-solicited)   2^-126 * 2^-30  ->  7f800000   expected 00000000
    second source           ~2^-298         ->  1d000000   expected 80000000

The first resolves an underflow as `+infinity`. The second lets the significand
survive while the exponent wraps. Neither design saw the other.

## Scope

| task | clause that gets closest | what it actually says |
|---|---|---|
| `d_dsp02` | A4b | overflow raises `inexact` — a flag condition |
| `d_dsp03` | A7 | "exceeds the format's range" — a flag condition |

Both would need the same addition, and both hashes move when it lands.

## What NOT to do when it is fixed

Do not write it as a citation. That is instance 1 of the same finding: A6 and A7
cited IEEE 754-2019 clause 7.5 for behaviour the oracle does not implement, and
the citation is what made it invisible. **State the rule longhand, name both
directions, and give the per-mode values explicitly** — the treatment A6 now has.

## Filed under

`FINDINGS.md` F57, *A requirement the oracle determines and the contract leaves
open*, instance 2.
