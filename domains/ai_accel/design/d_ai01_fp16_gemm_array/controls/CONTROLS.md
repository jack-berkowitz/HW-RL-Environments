# d_ai01 negative controls -- measured discrimination

Every control is a wrapper around `fp16_gemm_array_ref_inner` that perturbs one
behaviour. All six FAIL, which is the point; the useful number is HOW MANY
vectors each one kills, because a control that kills everything proves the
harness runs rather than that it discriminates.

Measured over the full H=8 set, 3400 cycles, `vectors/vectors_h8.hex`:

| control | clause targeted | z kills | status kills | first kill |
|---|---|---|---|---|
| `nc_a_stuck_output` | none -- floor case | 3399 / 3400 | 0 | cycle 0 |
| `nc_b_extra_pipe_stage` | A3, L1 operand skew | 2784 / 3400 | 0 | cycle 13 |
| `nc_c_flush_subnormal` | F1, A6 middle clause | **84** / 3400 | 0 | cycle 443 |
| `nc_d_overflow_always_inf` | A5 mode-dependence | **230** / 3400 | 0 | cycle 18 |
| `nc_e_positive_zero_only` | A6 sign, A8 | **132** / 3400 | 0 | cycle 3031 |
| `nc_f_reversed_chain` | A2 ordering | 3203 / 3400 | 3057 | cycle 13 |

Re-measured after the vector set gained a flush-during-stall window for C2; the
counts moved by at most one vector, and `nc_e`'s first kill did not move at all.

## What the narrow ones establish

`nc_c` at 84 and `nc_e` at 132 out of 3400 are the useful controls: they fire
only on the specific behaviour their clause describes, so a pass against them is
evidence about that clause rather than about the harness.

`nc_d` at 230 is the one a plausible submission actually writes. Delivering
infinity on every overflow is what falls out of reading a general rounding
clause and the format definition without A5's table. It is caught in the random
body of the set -- first kill at cycle 18 -- so it needs no special vector:

```
cycle 18: expected ...b9d6 c32c... got ...b9d6 fc00...
```

The reference delivers a finite -3.6-ish value where the control delivers -inf,
which is the roundTowardZero / roundTowardNegative row of A5.

## nc_e is why the -0 floor exists

**The first vector set could not have killed `nc_e`.** It reported coverage
`negzero=0` -- no -0 was ever delivered on z_o -- while still showing 10/10 on
both the A5 and A6 combination floors, because those are tallied from per-stage
FLAGS and the sign of a delivered zero is a different property.

`nc_e` changes nothing except 0x8000 -> 0x0000, so against that set it would
have produced zero mismatches and PASSED.

Measured, not argued: every one of `nc_e`'s 132 kills lands at cycle 3031 or
later, entirely inside the directed zero-sign phases added at cycle 3000. The
random body of the set contributes none of them.

That is the evidence for the two directed tail phases in
`tb/audit/capture_vectors_tb.sv` and for the separate `-0 never delivered` floor
in the scoring TB. Without both, A6's sign-preservation sentence and A8's
roundTowardNegative case are unscored.

## nc_f is correct in exact arithmetic

Reversing the chain order computes the same mathematical sum. It is wrong only
because floating-point addition is not associative, which is precisely what A2's
ordering sentence asserts. It kills 3203 vectors and, unlike every other
control, also moves `status_o` (3057) -- the per-stage flags shift when the
partial sums do.
