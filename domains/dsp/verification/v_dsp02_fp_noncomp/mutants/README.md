# v_dsp02 mutant set — these MUST BE CAUGHT

Opposite sign to `conformant/`: those satisfy the spec and must survive; these
violate it and must be caught.

**Every mutant perturbs the golden's INPUTS.** On a pipelined unit an
output-side mutation needs the operation tracked through the handshake to land
on the right result, and a wrapper carrying that much state can fail for reasons
unrelated to its defect. An input-side mutation is combinational, has no
alignment to get wrong, and is correct everywhere except the case it rewrites —
by construction.

## The set

| id | class | defect | violates |
|---|---|---|---|
| `fn_m1` | **capability** | subnormals classified as zero — the design never implemented subnormal detection | S12 |
| `fn_m2` | standards | IEEE 754-**2019** `minimum`/`maximum`: a single NaN operand propagates | S4 |
| `fn_m3` | signed zero | MINMAX treats −0.0 and +0.0 as interchangeable | S3 |
| `fn_m4` | flags | equality made a signalling comparison; a quiet NaN now raises `NV` | S9 |
| `fn_m5` | variant | the XOR sign-injection implemented as the plain one | S1 |
| `fn_m6` | payload | SGNJ canonicalises a NaN instead of preserving its payload | S1 |

`fn_m1` is the CAPABILITY member: every other operand class, every operation,
every flag and the whole handshake are correct.

**`fn_m2` is the one that earns the spec its citation.** It is not a bug — it is
a faithful implementation of the *current* IEEE standard, which withdrew
`minNum`/`maxNum` in favour of operations that propagate NaN. §10 names that
alternative out of scope. If a submission accepts `fn_m2`, the citation in S4 is
decorative; if it catches it, the citation is load-bearing. That is the same
question `mA4` and `mA6` asked on `d_dsp02`.

## Reachability — the constraint this set was built under

`v_nw03`'s risk was an unfalsifiable liveness claim. Here there is no liveness
property and an enormous corner space, so the opposite risk applies: **a mutant
nobody kills because the corner is unreachable from a spec-only reading.**

Every mutant above targets a corner the specification NAMES:

| id | the clause that makes it reachable |
|---|---|
| `fn_m1` | S12 enumerates all ten classes, subnormals among them |
| `fn_m2` | S4 states the single-NaN case and §10 names the alternative explicitly |
| `fn_m3` | S3 states `min(−0.0, +0.0) = −0.0` in words |
| `fn_m4` | S9 states equality is quiet and contrasts it with S8 |
| `fn_m5` | §0 tabulates all three sign-injection variants |
| `fn_m6` | S1 says the payload is copied through "and is not canonicalised" |

A mutant whose corner is not named by a clause would have to be retired. None
was, but the check is the point, not the outcome.

## Non-equivalence witnesses

| id | witness (first differing operation) |
|---|---|
| `fn_m1` | classify `00000001`: golden `+subnormal`, mutant `+zero` — 24 ops differ |
| `fn_m2` | `min(qNaN, +0)`: golden `00000000`, mutant `7fc00000` — 108 ops differ |
| `fn_m3` | `min(−0, +0)`: golden `80000000`, mutant `00000000` — 5 ops differ |
| `fn_m4` | `feq(qNaN, +0)`: result identical, **status `00000` vs `10000`** — 40 ops |
| `fn_m5` | `sgnjx(−0, +0)`: golden `80000000`, mutant `00000000` — 60 ops differ |
| `fn_m6` | `sgnj(ffd5a5a5, +0)`: golden `7fd5a5a5`, mutant `7fc00000` — 48 ops |

## Isolation — which clause each mutant trips

Reference testbench against each mutant, no print cap.

| id | first failure | all clauses tripped | count |
|---|---|---|---|
| `fn_m1` | S12 | **S12 only** | 12 |
| `fn_m2` | S4 | **S4 only** | 264 |
| `fn_m3` | S3 | **S3 only** | 4 |
| `fn_m4` | S9 | **S9 only** | 71 |
| `fn_m5` | S1 | **S1 only** | 220 |
| `fn_m6` | S1 | **S1 only** | 180 |

All six trip exactly one clause, and it is the clause each was built to violate.
`fn_m4` reports S9 rather than S8 only because the checker's NV attribution was
made mode-dependent — S8 and S9 differ solely in whether the comparison is
signalling, so attributing by operation alone named the wrong clause.

## Reference testbench ceiling

**6 of 6.** Report a submission's catches against that, never as a bare fraction.

**Same caveat as `v_nw03`, and it has not been discharged.** One author wrote the
spec, the checker and the mutants, so the set has only been challenged by what
that author anticipated. What the controls *did* find were four defects in our
own apparatus, three of them in the witness harness — see `NOTES.md`.

---

## The harder set

Four added after the first blind run; the six originals kept.

| id | violates | why a competent testbench misses it |
|---|---|---|
| `fn_m7_sgnj_quiets_snan` | S1 | needs an sNaN driven through SGNJ, which looks arithmetic-free and raises no flags |
| `fn_m8_max_subnormal_is_normal` | S12 | only the LARGEST subnormal is misclassified — the boundary between adjacent classes |
| `fn_m9_feq_distinguishes_zeros` | S10 | the one case where S3 and S10 disagree on purpose |
| `fn_m10_minmax_snan_not_invalid` | S6 | result exactly right, only the invalid flag missing |

Every one targets a corner a clause names — the reachability check that governs
this set. The reference catches **10 of 10**. No independent submission has yet
reached the mutants on this task, so unlike the sibling task the ceiling here is
still an author's self-assessment.
