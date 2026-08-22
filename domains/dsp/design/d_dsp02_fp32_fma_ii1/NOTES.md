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

---

# IMPLEMENTATION-DEFINED BEHAVIOUR — audited and pinned before the mutants

Capturing expected values from the anchor makes them *correct*. It does not make
them *the only correct answer*. **Wherever IEEE-754 says "should" rather than
"shall", the vector set silently adopted cvfpu's choice** — and a conformant
alternative implementation would fail on it.

That is a live over-constraint risk, and it would have surfaced at the worst
possible moment: when the second source failed and there was no way to tell
whether the design was wrong or the check was.

Audited across all 4290 vectors, not assumed:

| area | what IEEE says | what the anchor does | now |
|---|---|---|---|
| **NaN payload** | *recommends* propagation; does not mandate | **only ever `0x7FC00000`** across all 188 NaN results — canonical, never propagated | **pinned in A4** |
| NaN result sign | unspecified | always `+` | pinned in A4 |
| **underflow flag** | permits tininess before *or* after rounding | after rounding, and only when also inexact — 103 cases with `NX`, **0 without** | **pinned in A4b / A6** |
| overflow → inexact | mandated | 0 overflow cases without `NX` | stated in A4b |
| invalid → NaN result | mandated | 0 invalid cases with a non-NaN result | stated in A4b |

**The NaN one is the live risk.** RISC-V mandates a canonical quiet NaN and cvfpu
follows RISC-V, so our vectors encode that. An FMA propagating an operand payload
is *equally IEEE-conformant* and would have failed. It is now a **contract term**,
so such a design fails a stated requirement rather than failing to guess what the
reference happened to do.

The generator's `qnan_payload` category is really testing **canonicalisation**,
not propagation, and the coverage-floor message says so. Both operand orders are
still required: a design that canonicalises only one operand position would
otherwise be indistinguishable.


---

# MUTANT SET — six classes, all killed, each on its own defect

Every mutant is a **wrapper around the vendored anchor** with one thing
perturbed, so the arithmetic is externally-authored correct everywhere except the
injected defect. A hand-written FMA mutant would risk failing for incidental
reasons and would not isolate the property.

| mutant | class | fails | witness |
|---|---|---|---|
| `mCAP1_flush_to_zero` | **CAPABILITY** | 907 | `1.0 × 2⁻¹⁴⁹ + 0` → `0`, reference `0x00000001` |
| `mA1_unfused_multiply_add` | fused-vs-unfused (A1) | 1182 | `(1+2⁻¹²)² − (1+2⁻¹¹)` → `0`, reference `2⁻²⁴` |
| `mA4_nan_payload_propagate` | contract-NaN (A4) | 62 | sNaN operand → `0x7FC00001`, reference `0x7FC00000` |
| `mA5_signed_zero_always_positive` | special values (A5) | 14 | `(−0)+(+0)` under RDN → `+0`, reference `−0` |
| `mA6_underflow_ignores_inexact` | contract-underflow (A6.1) | 57 | exact subnormal → `UF` set, reference clear |
| `mA8_band_unbounded_tininess` | contract-underflow (A6.2) | 6 | rounds up onto smallest normal → `UF` set, reference clear |
| `mA7_inexact_dropped_on_subnormal` | flags (A7) | 89 | subnormal result → `NX` clear, reference set |

**Reference passes with 0 failures. Every mutant shows 0 coverage holes and 0
dead cycles**, so each is killed by its own defect and not by something
incidental — the isolation rule 3 requires.

## The two that mattered most

**`mCAP1` is the CAPABILITY mutant, and deliberately not the RNE-only probe.**
Reusing that probe would have made the validation set and the mutant set the same
artefact. Flush-to-zero is the better axis: it is a **completely correct FMA on
every normal operand** — right results, right flags, all five rounding modes, at
full rate — and FTZ is the most common real shortcut in FP hardware and
*area-favourable*, exactly the trade a model would make silently while scoring
better on PPA. It is caught only by the subnormal vectors. **Its first witness is
vector 0**, and it fails 907 of 4290.

**`mA4` and `mA6` confirm the newly-pinned contract terms are enforced rather than
decorative.** Both encode behaviour that is **IEEE-conformant** — payload
propagation and before-rounding tininess are both permitted by the standard — and
both are now failures because A4 and A4b/A6 pin the alternative. Had either
passed, the pins would have been words with no check behind them, and a
conformant design would have been failing an unwritten rule instead of a stated
one. **That is rule 12 verified end to end, one turn after being written.** The rule
was added because the vectors had silently encoded cvfpu's choices; the spec was
then pinned; and `mA4` and `mA6` now demonstrate that the pins are enforced by a
check that actually fires. **A rule demonstrated by a check that fires is worth
more than a rule asserted** — until one of these mutants failed, "A4 is pinned"
was a claim about a comment.

## Non-equivalence, and how it is witnessed here

The witness is the **failing input vector**, not a cycle number: this is a
combinational unit at `NumPipeRegs=0`, so the input tuple fully determines the
divergence and is more useful than a timestamp.

Witnessing **through the checker** — it passes the reference and fails the mutant
under identical stimulus — is the same proof as a direct differential comparison,
observed through the checker. No separate differential harness was built for this
task because it would add nothing: the checker already replays a fixed vector
file, so both designs see byte-identical stimulus by construction.

**No diff rate is reported.** It was retracted as a quality signal
(`FINDINGS.md`), and mutant quality is a posterior deferred to the cross-model
run.

---

# SECOND SOURCE — passes 4290/4290, and rule 5 adjudicated every failure

`tb/audit/fp32_fma_ii1_second_source.sv`. An independent FMA sharing no
arithmetic with the anchor. **4290/4290, zero coverage holes, C3 with 0 dead
cycles.**

## The three structural differences

| | anchor (`fpnew_fma`) | second source |
|---|---|---|
| **1. alignment** | frames on the **product**, shifts the **addend** — one shifter, one direction | frames on **max(product, addend)** and shifts whichever is smaller — **both** operands have a shift path and sticky collection |
| **2. rounding** | **decide then increment**: `fpnew_rounding` computes `round_up` from a case table over {round, sticky}, then adds | **speculate and select**: truncated and incremented significands are computed unconditionally and one is selected |
| **3. normalisation** | `lzc` over the sum **after** the add, then a separate correction stage for subnormal results | a **single** barrel shift from one leading-one index, with the subnormal case folded in by clamping that index — no second stage |

Each changes what hardware exists, not how it is written. None is a paraphrase.

**A dual-path (far/close) FMA would have been a more dramatic difference and was
deliberately not chosen.** Its failure mode is subtle cancellation behaviour, and
a buggy second source inverts the entire purpose of having one.

## Rule 5 in practice: three failures, all adjudicated to the second source

Every failing vector went through the anchor before anything was changed. **No
check was loosened at any point.**

**1 — frame misalignment (3632 of 4290 failing).** First vector:
`1.0 × 2⁻¹⁴⁹ + 0` gave `0`, anchor gave `0x00000001`. The anchor is right — that
is the exact product. The addend was placed at `P_POS` while the product was
shifted from bit 0, an 80-bit misalignment.

**2 — sign destroyed by concatenation.** `2⁻¹⁰⁰ × 2⁻⁴⁰` gave `0x1c800000`,
anchor gave `0x00000200` (= 512 × 2⁻¹⁴⁹, correct). Hand-tracing said the logic
was right, so it was instrumented instead — and `shift_amt` was **4139 instead of
43**.

> **Concatenation is unsigned in SystemVerilog.** `{2'b0, ep}` takes `ep`'s raw
> bit pattern, so `ep = −13` became `0xFF3 = 4083`, and the `$signed()` wrapped
> around the *already-widened* value could never recover it.

Same family as the `sra` defect found earlier in this project, where `>>>` was
demoted to a logical shift inside a ternary with an unsigned branch. **Fixed
generally rather than locally**: the exponents are now declared at full working
width so no widening concatenation appears anywhere.

**3 — a stated difference that was not implementable.** Overflow vectors failed
because framing strictly on the addend means a zero addend gives an effective
exponent of 1, and the product then needs a **~485-bit accumulator** to shift
into. Difference 1 was restated to what the file actually does — bidirectional
alignment onto `max(ep, ec)` — which is still a real structural difference
against a unidirectional aligner, but **a smaller claim than the one that did not
work.** The header says so rather than quietly describing the working version as
though it had been the plan.

## What this run demonstrates

**Rule 5's disambiguation was the correct default every single time.** Three
failures, three times the second source was wrong, zero times the checker was.
Had the old wording been followed — *"if the second source fails, fix the
check"* — the checker would have been loosened three times to accommodate a
frame-offset bug, a signedness bug, and an unimplementable design choice. Each
loosening would have been invisible afterwards.

**And the checker earned its keep in the other direction**: it localised all
three bugs to specific input vectors, which is why the second source is now
correct rather than merely plausible.

## The anchor's rounding, checked against an independent computation

**Motivation.** Agent 2 rejected `fpnew_divsqrt_multi` — a sibling module in the
same repository as this task's anchor — for three measured defects: truncation
where RNE requires round-to-nearest, RDN and RUP inverted, and RMM with no
counterpart in its two-bit field. That is close enough to home to matter.

**Why the existing confirmation did not settle it.** This task's vector set is
generated under rule 11's inversion: local code produces the INPUTS, the anchor
produces the EXPECTED VALUES. That makes the expected values unfalsifiable from
inside the task. If the anchor rounded wrongly, every vector would inherit the
defect, the reference would pass, every mutant would behave as designed, and the
task would pin the defect as its contract with nothing in the apparatus able to
notice. Fifteen directed known-answer cases do not reach this: they confirm the
cases whoever wrote them thought to test.

**Method.** An independent fp32 FMA oracle in exact integer arithmetic
(`tb/audit/independent_fma_oracle.py`). **No Python float appears anywhere in
the reference computation.** Every fp32 value is a dyadic rational, exactly
`(-1)^s * N * 2^E` with N and E integers; products and sums of dyadic rationals
are dyadic, so `a*b+c` is computed EXACTLY with arbitrary-precision integers and
rounded ONCE -- which is the definition of a fused multiply-add. The five
rounding modes are implemented from the IEEE-754 rules directly, not by calling
a library that might share an implementation, and therefore a bug, with the DUT.

The harness (`tb/audit/anchor_rounding_audit_tb.sv`) drives the anchor and
prints what it produces. **It does not know the expected values** -- comparison
happens in Python. A harness carrying the expected values would be the same
inversion this audit exists to break.

**The oracle was validated before it was trusted.** Hand-computable cases:
exact results, an exact halfway at an even mantissa (ties-to-even must stay), an
exact halfway at an odd mantissa (ties-to-even must round up), a negative
operand (RDN and RUP must swap roles), and exact cancellation (+0 in every mode
except RDN). An oracle I wrote could be wrong, and then it would accuse the
anchor falsely.

**Result: 10,150 vectors, ZERO mismatches on results and on flags.**

| set | vectors | result mismatches | flag mismatches |
|---|---|---|---|
| directed boundary cases | 150 | 0 | 0 |
| randomized | 10,000 | 0 | 0 |

Coverage: 610 subnormal results, 610 underflow, exact ties at eight mantissa
patterns and five binades, near-ties either side, cancellation, and the overflow
edge (RTZ and RDN correctly produce max-finite rather than infinity).

**Tininess after rounding is correct**, which is the corner the spec pins
explicitly. On `tiny_boundary_near` the same exact value gives `uf=0` under RNE,
RUP and RMM -- rounding lifted it to the smallest normal -- and `uf=1` under RTZ
and RDN, where it stayed subnormal. Underflow determined by the result after
rounding, not before.

**The check has power, which is the part that makes "clean" mean something.**
The DUT produced more than one distinct result across modes on 25 of 30 directed
cases, so rnd_mode demonstrably reaches the rounding logic. Against the three
divsqrt defects specifically: RDN/RUP inversion would fail on 25 cases,
truncation-where-RNE-is-required on 16, RMM aliased to RNE on 5.

**What this does NOT cover.** NaN and infinity propagation. The oracle returns
early on those paths; they are pinned by the spec and checked separately. This
audit is about rounding of finite operands.

**Standing.** d_dsp02's oracle is now CONFIRMED against an external truth rather
than assumed. Its numbers may go into a cross-model report.

## Candidate set after the prompt change, 2026-08-21

**The set is three models, and three is the whole set — not a run in progress.**

`chat`, `claude` and `gemini` were re-solicited against `probe/PASTE.md` and
carry task-text hash `530f3e4189421457`, which covers the spec **and** the
prompt together. Each has a solicitation record beside it in
`candidates/d_dsp02/<model>.solicitation.md` — the prior five had none, and a
pinned prompt with no solicitation record just moves the reproducibility gap up
a level.

**`deepseek` and `qwen` are WITHDRAWN, not pending.** They are not being
re-solicited and nothing is scheduled for them. Both were build failures at the
pre-bump spec — rejected by slang, the synthesis frontend — and they answer a
task text that no longer exists. Their rows and hashes are retained as
historical against `5ad30593403b4ae2`, not deleted and not re-scored.

### What that does to cross-model claims from this task

The two withdrawn models are **open-weight**. The three that remain are all
**closed frontier labs**. So the set is not just smaller by two, it is narrower
in kind: after this change d_dsp02 contains no open-weight design at all.

Any cross-model statement from this task is therefore a statement about three
closed frontier models. It is not directly comparable to tasks carrying five,
and its pass rate cannot be averaged with theirs without naming the axis
(rule 17) — *3 of 3* and *3 of 5* are different populations, not different
scores.

### The prior Claude submission was LOST TO OVERWRITE

Recorded because the distinction matters and would otherwise be invisible:
`deepseek` and `qwen` carry withdrawal rationales and `claude` does not, and the
reason is not that claude's was withdrawn without one.

**It is an artefact loss, not a decision.** The earlier `candidates/d_dsp02/claude.sv`
existed on disk and was never committed. Re-solicitation overwrote it. Git reads
today's `claude.sv` as an *addition* for that reason alone — **Claude was in the
prior five and is not a new model.**

Its identity survives in the run record — `submission_sha256_16 7b3240027cc7837c`,
1/1 PASS at task text `5ad30593403b4ae2` — so a future file can be proven to be
or not be that one. The content cannot be recovered.

**The asymmetry this creates is narrower than it first looks, and sharper.** No
pre-bump record for *any* model carries the per-shape floors (BAND, FTZ, EXACT,
zero case) — those were added on 2026-08-21 and did not exist. So a per-shape
before/after is unavailable from the records for everyone.

What is claude-specific: `chat` and `gemini`'s prior submissions are committed in
HEAD, so a per-shape "before" could be **reconstructed** for them by re-running
the committed artefact against the current checker. Claude's cannot be. Its
before/after is permanently coarser than the other two's, and re-running cannot
fix it.

**The general lesson, which is the third instance of it today:** uncommitted
work is work that can vanish without anyone noticing. Agent 1's findings and the
convention draft both came close; this one actually happened. Unlike the other
two there was no diff to catch it — the loss was silent and total.
