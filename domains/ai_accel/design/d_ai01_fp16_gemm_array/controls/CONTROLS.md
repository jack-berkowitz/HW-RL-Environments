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


## nc_g -- the capacity-reduced control (HEIGHT discrimination)

Every control above is a correctness perturbation: wrong at every geometry.
`nc_g_height_blind_depth` answers a different question -- **is HEIGHT
load-bearing?** The reference passing at both geometries is not evidence that a
HEIGHT-blind design would fail at either, and without this control the
two-configuration argument in task.yaml was an assertion. It was recorded as
`measured: PARTIAL` until this ran.

It hands the reference the literal `4` as chain depth instead of the HEIGHT
parameter. Its ports stay HEIGHT-wide, so it accepts all eight operand pairs and
discards stages 4..7.

| geometry | result | z kills | first z kill | status kills | first status kill |
|---|---|---|---|---|---|
| HEIGHT=4 | **PASS** | 0 / 3400 | -- | 0 / 3400 | -- |
| HEIGHT=8 | **FAIL** | 3208 / 3400 | cycle 14 | 3189 / 3400 | cycle 13 |

### Witness

Not decoded from the random stream -- a directed settled field, so the arithmetic
is checkable by hand. HEIGHT=8, x=1.0 and w=2.0 on every stage, y=+0, held until
settled:

```
reference z[0] = 0x4C00   = 16.0 = 8 * (1.0*2.0)      <- contract
nc_g      z[0] = 0x4800   =  8.0 = 4 * (1.0*2.0)      <- pinned depth
```

A real non-equivalence, not a no-op perturbation. Both instances receive the same
eight operand pairs.

At HEIGHT=4 the pin equals the parameter, the port mapping is the identity, and
nc_g is bit-for-bit the reference -- which is exactly why it passes there. A
control that also failed at HEIGHT=4 would be a broken control rather than a
finding about the task.


## Re-measured against task text e43648a5afcacc53

The A10 pin and the C2 narrowing changed WHICH CYCLES ARE SCORED, not the vector
set -- `vectors_h4.hex` and `vectors_h8.hex` are byte-identical across the
boundary. C2 excludes the post-flush refill window: 236 of 3400 cycles at
HEIGHT=8, 113 at HEIGHT=4.

Everything above this heading was measured against the SUPERSEDED text
84950ba1d90be2d8 and is retained as historical. The two sets are not comparable.

| control | H=8 old | H=8 new | H=4 new | H=4 result |
|---|---|---|---|---|
| `nc_a_stuck_output` | 3399 | 3163 | 3286 | FAIL |
| `nc_b_extra_pipe_stage` | 2784 | 2583 | 2679 | FAIL |
| `nc_c_flush_subnormal` | 84 | **80** | **81** | FAIL |
| `nc_d_overflow_always_inf` | 230 | **215** | **205** | FAIL |
| `nc_e_positive_zero_only` | 132 | **132** | **148** | FAIL |
| `nc_f_reversed_chain` | 3203 | 2975 | 3034 | FAIL |
| `nc_g_height_blind_depth` | 3208 | 2980 | **0** | **PASS at 4, FAIL at 8** |

**Every movement is the C2 accounting and nothing else.** Scaling each control's
old kill RATE by the 236 removed cycles predicts the drop:

| control | predicted drop | actual |
|---|---|---|
| nc_a | 236.0 | 236 |
| nc_b | 193.2 | 201 |
| nc_c | 5.8 | 4 |
| nc_d | 16.0 | 15 |
| nc_e | 9.2 | **0** |
| nc_f | 222.3 | 228 |
| nc_g | 222.7 | 228 |

The residuals are small and follow from kills not being uniformly distributed
over the excluded window. `nc_e`'s zero drop is the one that looks anomalous and
is not: every one of its kills lands at cycle 3031 or later, and the capture rig
stops asserting flush at n < 3000, so no `nc_e` kill was ever inside a refill
window. That is a prediction confirmed rather than a movement to explain.

`nc_g` still discriminates: PASS at HEIGHT=4 with 0 kills, FAIL at HEIGHT=8 with
2980. The capacity argument survives the text change.


## Re-measured against task text 9a93e4502979efc9 (C3 and C4 narrowed)

Scored cycles fall again as C3's accumulate-transition window is excluded:
3164 -> 2937 at HEIGHT=8, 3287 -> 3157 at HEIGHT=4. C4's exclusion is per row and
removes no whole cycles. Vector sets unchanged, as at every boundary.

| control | H=8 prev | H=8 new | drop | predicted | residual | H=4 new |
|---|---|---|---|---|---|---|
| `nc_a_stuck_output` | 3163 | 2936 | 227 | 226.9 | +0.1 | 3156 |
| `nc_b_extra_pipe_stage` | 2583 | 2368 | 215 | 185.3 | +29.7 | 2570 |
| `nc_c_flush_subnormal` | 80 | 80 | 0 | 5.7 | -5.7 | 81 |
| `nc_d_overflow_always_inf` | 215 | 167 | 48 | 15.4 | **+32.6** | 185 |
| `nc_e_positive_zero_only` | 132 | 132 | 0 | 9.5 | -9.5 | 148 |
| `nc_f_reversed_chain` | 2975 | 2746 | 229 | 213.4 | +15.6 | 2902 |
| `nc_g_height_blind_depth` | 2980 | 2752 | 228 | 213.8 | +14.2 | **0, PASS** |

**`nc_d`'s +32.6 is the one deviation worth explaining, and it is
distributional.** Its kills were roughly three times over-represented in the
newly excluded windows: 48 of 215 kills (22%) sat in 227 cycles (7% of the
scored set). Measured after exclusion, only 20 of its 167 surviving kills fall
in the accumulate window, which is 17.6% of the run -- so the accumulate region
is now under-represented among its kills, exactly as removing a kill-dense
region predicts. The MECHANISM -- accumulate grows magnitudes, so overflow, which
is what nc_d perturbs, is likelier there -- is inferred and not separately
measured.

`nc_c` and `nc_e` dropping zero is the same effect with the sign reversed: their
kills lie outside every excluded window (subnormal results, and the directed tail
at cycle 3031+ where flush never fires).

`nc_g` still discriminates: PASS at HEIGHT=4 with 0 kills, FAIL at HEIGHT=8 with
2752.
