# v_dsp01 `fp_cast_multi` — REJECTED at step 1, on semantics

Anchor: PULP `cvfpu/src/fpnew_cast_multi.sv`. Elaborates clean with a six-file
closure; the Class A shim in `dut/fp_convert.sv` builds and runs. **The task was
not built.** The anchor has two flag defects on named boundaries, and a
specification it satisfies would pin them.

## What was measured

`probe/semantic_probe.sv` runs 22 conversions whose expected results were
computed by hand from IEEE 754 and the RISC-V F extension. **All 22 match**,
once two things about the interface are accounted for:

- a narrow result is **NaN-boxed** into the 32-bit port (`0xFFFF3C00`, not
  `0x3C00`), which is the RISC-V convention; and
- 4 000 000 000 is exactly representable in binary32, so `NX` correctly stays
  clear on that conversion. My first expectation was wrong, not the design.

`probe/corner_probe.sv` then confirms the anchor gets the genuinely hard,
rounding-mode-dependent corners exactly right:

| corner | result |
|---|---|
| binary32→binary16 overflow, positive | RNE/RUP/RMM → `+inf`; **RTZ/RDN → `+max`** — IEEE exactly |
| the same, negative | RNE/RDN/RMM → `-inf`; **RTZ/RUP → `-max`** — IEEE exactly |
| binary32→binary16 subnormal | 16.78 ulps rounds to 17/16/16/17/17 by mode, `UF`+`NX` |
| binary16 subnormal → binary32 | exact, no flags |
| F2I of −0.5, signed | `0`/`0`/`-1`/`0`/`-1` by mode, `NX` |
| F2I of −0.5, **unsigned** | `0` throughout, but **`NV` only under RDN and RMM** — the two modes that round it to −1, out of unsigned range |

That last one is subtle and the anchor gets it right. The arithmetic here is
sound in a way `fpnew_divsqrt_multi`'s was not.

## The two defects

`probe/defect_probe.sv`, with the expected values from the RISC-V spec:

| case | anchor | RISC-V / IEEE |
|---|---|---|
| **F2I signed, operand exactly −2³¹** (`0xCF000000`) | `0x80000000`, **`NV` set** | `0x80000000`, **no flags** — the value *is* representable as INT32_MIN |
| **I2F overflowing the destination float** (e.g. INT32 100000 → binary16) | `+inf`, **`NV`**+`NX` | `+inf`, **`OF`**+`NX` |

Both are flag misattribution; every result *value* is correct.

The first is the classic asymmetric two's-complement boundary bug: the range
check compares magnitudes, and |−2³¹| = 2³¹ reads as out of range. One ulp
further out (`0xCF000001`) correctly sets `NV`, and `−(2³¹−128)` is correctly
clean, so the defect sits exactly on the boundary and nowhere else.

The second is not a missing capability — the **control case proves `OF` works**:
the same overflow reached through F2F (`100000.0` → binary16) sets `OF`+`NX`
correctly. Only the I2F path substitutes `NV`.

## Why the task was dropped rather than scoped around it

A specification the golden satisfies would have to say that converting exactly
−2³¹ to a 32-bit signed integer raises Invalid, and that an integer-to-float
overflow raises Invalid rather than Overflow. Both statements are wrong.

Excluding the two cases from the contract does not rescue it. **A thorough
submission would check them, get the RISC-V-correct answer, reject the golden,
and fail the validity gate** — the task would penalise exactly the rigour it
exists to measure. These are not obscure inputs; they are the named boundaries
a cast unit is *about*.

Restricting the configuration dodges only the second: pinning the I2F
destination to binary32 makes overflow unreachable, because every INT32 fits.
The first cannot be dodged while the task converts to integers at all.

This is the same decision, on the same grounds, as
`fpnew_divsqrt_multi`: **a spec it satisfies would pin its defects.**

## What would make it usable

Either an anchor whose flag semantics match RISC-V on both boundaries, or an
explicit decision that this benchmark's oracle may be a corrected derivative
rather than the vendored anchor — which changes the oracle class and is not this
agent's call to make.
