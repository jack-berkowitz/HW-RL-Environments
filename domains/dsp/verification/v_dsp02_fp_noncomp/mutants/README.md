# v_dsp02 mutant set — these MUST BE CAUGHT

Each mutant wraps the unmodified golden and is correct everywhere except the one
named case it perturbs.

**Ten of the thirteen rewrite the golden's INPUTS**, so the wrapper is
combinational and has no alignment to get wrong — by construction.

**Three do not, and could not.** `fn_m11`, `fn_m12` and `fn_m13` perturb an
OUTPUT, because their clauses cannot be broken from the inputs at all: no input
makes SGNJ raise a flag (S2 *is* that), no input makes minmax return a
non-canonical NaN (S5 *is* that), and dropping NV on a signalling compare by
substituting the operand would also change the boolean and trip S7 instead of
S8. The golden is `NumPipeRegs=1, PipeConfig=BEFORE`, so an output belongs to an
operation accepted EARLIER — and under a stalling handshake not a fixed number of
cycles earlier. Those three therefore load the guard's verdict on acceptance and
carry it across the register on the port handshake alone; one flag, because one
stage holds one operation.

A misaligned guard of that kind does not produce a surviving mutant. It produces
one that fails on a NEIGHBOURING clause, with the kill count and the rule-24
positive control both unchanged. **The clause id in the witness table below is
therefore the alignment check for those three**, not decoration.

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
| `fn_m11_minmax_both_nan_keeps_payload` | **S5** | the EIGHTH minmax with BOTH operands NaN | a payload is forwarded instead of the canonical quiet NaN |
| `fn_m12_signalling_cmp_quiet_on_qnan` | **S8** | the EIGHTH less-than / less-than-or-equal with a QUIET NaN operand | NV is dropped for a quiet NaN — S9's rule on the wrong opcode |
| `fn_m13_sgnj_raises_nv_on_snan` | **S2** | the TENTH sign-injection with a signalling NaN operand | NV is raised — sign injection raises no flags, for any operand |

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
| `fn_m11_minmax_both_nan_keeps_payload` | FAIL [S5] op=1 mode=1 a=7fc00000 b=ff812345 : result expected 7fc00000 got 7fc00001 |
| `fn_m12_signalling_cmp_quiet_on_qnan` | FAIL [S8] op=2 mode=1 a=80000000 b=ffd5a5a5 : NV expected 1 got 0 |
| `fn_m13_sgnj_raises_nv_on_snan` | FAIL [S2] op=0 mode=0 a=80000000 b=ff812345 : NV expected 0 got 1 |

## The thresholds were raised once

At ordinals of 2 to 5 the reference killed all ten **with no change to it at
all**. That is the signal that a guard is shallower than the reference's own
sweeps — it was not measuring anything the sweep did not already do.

Raised, one mutant went out of reach: `fn_m9`, the +0/−0 equality, because the
pool sweep compared that pair only once or twice in passing. The **reference was
extended** to drive it eight times rather than the guard dialled back. Loosening
the guard is the fallback, not the fix — it is right only when the reference
genuinely cannot be made to get there.


## The three added guards were calibrated against measured supply

The thresholds first written for `fn_m11`/`fn_m12`/`fn_m13` were the 5th, 3rd and
2nd of their class — at or below the floor this set had already rejected. Supply
was then measured directly, by neutralising each threshold and counting accepted
operations of the class under the reference:

    fn_m11   minmax, both operands NaN            32 operations available
    fn_m12   FLT/FLE with a quiet NaN operand    152
    fn_m13   SGNJ with a signalling NaN operand  228

and the ordinals were raised to the 8th, 8th and 10th — inside the 4th-to-10th
band the rest of the set occupies, and far enough below supply that the reference
reaches each many times over.

**The first supply probe reported 0 for all three.** Its counter had an async
reset, and the reference pulses reset once, late; the probe read it after that
pulse. The numbers above come from a counter with no reset clause. The same
pulse clears `g_hit_q` in the mutants themselves, which is harmless only because
no operation of any of these three classes is issued after it — recorded here
because it would NOT be harmless for a class the reference exercises late.

## Policy independence covers all thirteen

`check_policy_independence.sh` re-derives every defect on the independent
implementation in `dut2/`: **28 of 28**, both clean bases passing. It was 22 of
22 over ten before these three.

That script asserts a mutant FAILS, never *which* clause it fails on — enough for
the ten input-side mutants, not enough for the three that carry a guard across
the pipeline, where a misaligned carry would still read "FAIL as expected". The
clause was therefore measured separately on the policy base and is the **same
clause and the same operands** as on the golden. The two bases register opposite
ends — inputs against outputs — but both hold one operation and load on
acceptance, and `dut2`'s header records `in_ready_o` and `out_valid_o` differing
on zero cycles over 3178. The carry reads only the handshake.

## Non-equivalence, for the record

`nonequiv_tb` enumerates VARIANTs 1–5 (the conformant wrappers) and 11–16
(`fn_m1`–`fn_m6`). **`fn_m7` onward are not in it**, these three included. For a
conformant variant the differential is the only available point of difference,
since it must PASS the reference by definition. For a mutant the rule-24 pair is
itself that point: the golden PASSes and the mutant FAILs on the same stimulus.
Noted so the gap is not later read as an oversight in one direction or a
licence in the other.
