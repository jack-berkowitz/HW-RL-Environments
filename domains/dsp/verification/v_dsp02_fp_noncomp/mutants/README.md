# v_dsp02 mutant set — these MUST BE CAUGHT

Each mutant wraps the unmodified golden and rewrites its INPUTS for one named
case, so the wrapper is combinational, has no alignment to get wrong, and is
correct everywhere except the case it rewrites — by construction.

## Every defect in this set is GUARDED

    defect := wrong_behaviour AND rare_predicate over contract-level state

This unit is combinational at the contract level: no occupancy, no burst, no
queue to key a guard on. What it has is a **sequence of operations**, and
clauses that hold on every one of them. So each defect fires only from the
**Nth operation of its own class since reset** — the first several are exact.

That rewards a testbench that keeps checking over one that spot-checks each
operand class once, which is the distinction this set exists to draw.

## The set

| id | clause | guard — fires only from… | defect |
|---|---|---|---|
| `fn_m1_classify_subnormal_as_zero` | **S12** | the EIGHTH subnormal classify since reset | a subnormal is classified as zero |
| `fn_m2_ieee2019_minmax` | **S4** | the SIXTH minmax with exactly one NaN operand | IEEE 754-2019 minimum/maximum: the NaN propagates |
| `fn_m3_minmax_ignores_zero_sign` | **S3** | the FOURTH minmax of two zeros | −0.0 and +0.0 are treated as interchangeable |
| `fn_m4_feq_is_signalling` | **S9** | the FOURTH quiet comparison with a NaN operand | equality is made a SIGNALLING comparison |
| `fn_m5_sgnjx_becomes_sgnj` | **S1** | the TENTH sign-injection XOR since reset | sgnjx behaves as sgnj |
| `fn_m6_sgnj_canonicalises_nan` | **S1** | the SIXTH sign-injection on a NaN | the NaN payload is canonicalised instead of carried through |
| `fn_m7_sgnj_quiets_snan` | **S1** | the SIXTH sign-injection on a signalling NaN | the sNaN is quieted — sign injection is not arithmetic |
| `fn_m8_max_subnormal_is_normal` | **S12** | the FOURTH classify of the largest subnormal | it is classified as the smallest normal |
| `fn_m9_feq_distinguishes_zeros` | **S7** | the FOURTH equality comparison of +0 against −0 | they compare unequal |
| `fn_m10_minmax_snan_not_invalid` | **S6** | the EIGHTH minmax with a signalling NaN operand | no invalid flag is raised |

## Witnesses — rule 21

`witness.sh` substitutes each mutant for the golden — the same rename the harness
performs — runs the reference against it, and reports the first clause failure
with the exact operands.

| id | first clause failure |
|---|---|
| `fn_m1_classify_subnormal_as_zero` | FAIL [S12] classify a=807fffff : mask expected 0000000100 got 0000001000 |
| `fn_m2_ieee2019_minmax` | FAIL [S4] op=1 mode=1 a=00000000 b=7fa00000 : result expected 00000000 got 7fc00000 |
| `fn_m3_minmax_ignores_zero_sign` | FAIL [S3] op=1 mode=0 a=80000000 b=00000000 : result expected 80000000 got 00000000 |
| `fn_m4_feq_is_signalling` | FAIL [S9] op=2 mode=2 a=80000000 b=7fc00000 : NV expected 0 got 1 |
| `fn_m5_sgnjx_becomes_sgnj` | FAIL [S1] op=0 mode=2 a=80000000 b=00000000 : result expected 80000000 got 00000000 |
| `fn_m6_sgnj_canonicalises_nan` | FAIL [S1] op=0 mode=0 a=ffd5a5a5 b=00000000 : result expected 7fd5a5a5 got 7fc00000 |
| `fn_m7_sgnj_quiets_snan` | FAIL [S1] op=0 mode=2 a=7fa00000 b=80000000 : result expected ffa00000 got ffe00000 |
| `fn_m8_max_subnormal_is_normal` | FAIL [S12] classify a=807fffff : mask expected 0000000100 got 0000000010 |
| `fn_m9_feq_distinguishes_zeros` | FAIL [S7] op=2 mode=2 a=80000000 b=00000000 : result expected 00000001 got 00000000 |
| `fn_m10_minmax_snan_not_invalid` | FAIL [S6] op=1 mode=1 a=80000000 b=ff812345 : NV expected 1 got 0 |

## The thresholds were raised once

At ordinals of 2 to 5 the reference killed all ten **with no change to it at
all**. That is the signal that a guard is shallower than the reference's own
sweeps — it was not measuring anything the sweep did not already do.

Raised, one mutant went out of reach: `fn_m9`, the +0/−0 equality, because the
pool sweep compared that pair only once or twice in passing. The **reference was
extended** to drive it eight times rather than the guard dialled back. Loosening
the guard is the fallback, not the fix — it is right only when the reference
genuinely cannot be made to get there.
