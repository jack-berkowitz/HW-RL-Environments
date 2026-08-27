# d_ai01 — three undecided points in the contract, written for a fresh reader

**Pinned to:** `9da6e62bfecb8d5a94dcf366c67ea5da07729d74`
**Clause regions this rests on, all verified byte-identical read-to-report:**
`A4 e671740c…` · `A5 c80fdfe6…` · `A6 94db18ce…` · `A7 9f06a378…` ·
`A8 54dc4142…` · `F1 486a96d6…` · `F3 9f11b990…`
None of these regions has been touched by any edit since. `1bbc5bd` moved C2
and C5; `77ac97f` moved C3 (CF‑4, below, being landed). **Every clause region
this document reasons about is still byte-identical to the pinned text.**

**Who wrote this and why that matters.** I derived an independent implementation
of `fp16_gemm_array` from this contract alone, having never seen `ref/`, `tb/`,
`MEASUREMENTS.md`, any submission, or any result. Each item below is a place
where the text ran out and I had to choose. **I do not know which way the
reference goes on any of them**, and that is the point: what follows is what the
text does and does not determine, uncontaminated by what the hardware happens to
do.

I am contaminated for d_ai01 now and cannot take the repair. Everything needed
to act without me is below.

**Standing caution for whoever fixes these.** In all three cases, the fix is
*not* "measure the reference and write that down". A10 and C2 both carry their
own histories of exactly that going wrong — a clause that permits two readings
gets closed by copying the anchor, and the clause is then a description of the
reference rather than a contract the reference could be checked against. Each
item below says what a decision needs to determine on its own terms.

---

## 0. First, a note on the class — CF‑4 strengthens it

CF‑4 (C3 quoting `dfb` as 15/31 when those are the `d(0)` values, closed
internally by C3's own window at `15 + dfb = 31`) has since been landed by
commit `77ac97f`, "CF‑4 closed by recomputation".
It is the **third** instance of one failure mode, and naming the class is worth
more than the third fix:

> **A correction argued from one purpose reaches the prose carrying the
> argument, and not the formal site that consumes the number.**

The three instances, all in this one file:

1. **A3.** The `d(k)` formula and both worked tables carried `+2` while the
   sentence immediately above them said `+3`. A3 documents this against itself.
2. **L3.** The correction from `D*(H-1)+2` to `+3` landed in L3's prose and did
   not reach the relation in A3 that consumed it. A3 documents this too.
3. **C3.** The rule states `dfb = d(0)+1` → 16 at H=4, 32 at H=8; the "Measured
   at both geometries" sentence four lines later still quotes 15 and 31, which
   are `d(0)`, in a sentence that says the earlier draft asserted `d(0)` and was
   wrong by one.

In every case the *argument* was updated and the *number* was not, and in every
case the stale number sat within a few lines of the correct relation. Proximity
is not protection.

**A mechanical check that would have caught all three**, and does not require
knowing the answer: for every clause that states a relation *and* quotes
numbers, recompute the numbers from the relation and diff. Then cross-check
against any other clause consuming the same quantity — here C3's own transition
window `d(0) + dfb = 2*D*(HEIGHT-1)+7` pins `dfb` without reference to the
disputed sentence. Both checks are greppable and neither needs the reference.

---

## 1. A6 is both "in full" and "the representative case"

### What the text says

> **A6.** "When the exact result of a stage is nonzero and its magnitude is
> below the smallest positive subnormal, the delivered value is set out here in
> full, in both directions, for every rounding mode. **As with A5 this is
> stated, not left to inference.**"

then, immediately:

> "**Taking the representative case** of an exact result of magnitude 2⁻²⁵,
> exactly half the smallest subnormal:"

followed by the five-by-two table, and "In every one of these ten cases that
stage raises UF and NX."

A6's closing paragraph then defers to correct rounding for the band above:
magnitudes below the smallest normal but at or above the smallest subnormal are
"delivered as the correctly rounded SUBNORMAL under `rnd_i`".

### What it fails to determine

Whether the table is

* **(a) normative across the whole range it declares** — every exact magnitude
  in (0, 2⁻²⁴) — as "in full … for every rounding mode … not left to inference"
  says; or
* **(b) the worked values at the single point 2⁻²⁵**, as "the representative
  case" says.

The clause asserts both in consecutive sentences.

### Where the two readings diverge — the full pair

Under reading (b), A4's general rounding rule fills the rest of the range. The
readings agree on most of it. They diverge in exactly two places, symmetrically:

| exact magnitude | mode | reading (a), table literal | reading (b), A4 correct rounding |
|---|---|---|---|
| strictly between 2⁻²⁵ and 2⁻²⁴ | **RNE** | ±0 | **±2⁻²⁴** (`0x0001` / `0x8001`) |
| strictly between 0 and 2⁻²⁵ | **RMM** | ±2⁻²⁴ | **±0** (`0x0000` / `0x8000`) |

RTZ agrees everywhere. RUP and RDN agree everywhere (their answer does not
depend on where the value sits inside the interval, only on its sign). The
divergence is confined to the two round-to-nearest modes, on opposite halves of
the interval, and it is a **delivered-value** divergence, not a flag one.

Concrete: exact magnitude `0.75 × 2⁻²⁴` under RNE. Literal table → `+0`.
Correct rounding → `0x0001`, because the exact value is nearer 2⁻²⁴ than 0.

**Runnable witnesses** — `W1` (RNE half), `W2` (RMM half), `W3` (the tie, where
both readings agree) in `inbox/d_ai01_second_source_probe_clauses.sv`. All three
verified against the implementation; the flags are `00011` under either reading,
so only the delivered value moves.

### What decides it, on the text's own terms

Correct rounding reproduces **all ten cells** of A6's table at 2⁻²⁵. That is not
a coincidence available to both readings: 2⁻²⁵ is the **tie point**, the unique
magnitude in the interval at which RNE and RMM give *different* answers from
each other. A table that captures the tie is diagnostic of a worked example, not
of a range. Together with A6's own closing paragraph deferring to correct
rounding one band up, this is why my implementation took (b).

But that is an inference from the values, and the clause's words say (a). **The
clause should say which.**

### What I would NOT want a fixer to assume

* **Do not assume the ten cells are wrong.** They are correct under correct
  rounding at 2⁻²⁵, all ten. The defect is the **quantifier**, not the values.
  A repair that changes a cell has gone wrong.
* **Do not fix it by deleting "in full" and stopping.** That removes the
  contradiction and leaves the scope still unstated — a reader would still not
  know whether the table binds above and below the tie.
* **Do not narrow A6 to the tie point and leave the rest unsaid.** That converts
  a resolvable ambiguity into a genuine gap. If the table becomes an example,
  the clause must explicitly hand the interval to A4.
* **Do not assume A7 helps.** A7 is about the *exact* case; it says nothing
  about which value an inexact tiny result rounds to.
* **Do not settle it by measuring the reference.** Both readings are legal
  against this text. Measuring picks a winner without making the clause say why,
  which is the failure C2 documents about itself in exactly these words: "A
  WINNER HAS BEEN CHOSEN HERE RATHER THAN DERIVED."

---

## 2. A5 names "the binary16 overflow threshold" as one number; it is not one number

### What the text says

> **A5.** "When the exact result of an individual stage's fused multiply-add has
> magnitude **at or above the binary16 overflow threshold**, the value delivered
> by that stage is set out here in full … It is NOT to be inferred from A4 and
> F1."

then the table — RNE ±∞, RTZ ±65504, RDN +65504/−∞, RUP +∞/−65504, RMM ±∞ — and
"In every one of these ten cases that stage raises **OF and NX**."

### What it fails to determine

The value of "the binary16 overflow threshold". The phrase is definite and
singular, implying one constant applied to the **exact** result. But the table
is, cell for cell, IEEE 754's overflow-*result* table, and IEEE's overflow
*condition* is a property of the **rounded** result and is therefore mode- and
sign-dependent.

Largest finite is 65504; the next value representable with unbounded exponent is
65536; the midpoint is 65520. Under IEEE the exact-magnitude thresholds are:

| mode | positive exact | negative exact (magnitude) |
|---|---|---|
| RNE | ≥ 65520 | ≥ 65520 |
| RMM | ≥ 65520 | ≥ 65520 |
| RTZ | ≥ 65536 | ≥ 65536 |
| RDN | ≥ 65536 | > 65504 |
| RUP | > 65504 | ≥ 65536 |

Five different conditions. No single constant reproduces them.

### The two coherent readings, and the full divergence

**(A) IEEE.** Overflow iff the result rounded with unbounded exponent exceeds
65504 in magnitude. This is what my implementation does (decision D12).

**(B) A single threshold at "magnitude greater than the largest finite".** The
table applies to every exact magnitude above 65504.

Both are internally coherent. They agree on **every delivered value**. They
diverge on **the OF bit alone**, for exact magnitudes in the open interval
(65504, 65536), in the three mode/sign combinations where ordinary rounding
lands back on the largest finite:

| exact | mode | reading (A) IEEE | reading (B) single threshold |
|---|---|---|---|
| +65530 | RTZ | `0x7BFF`, flags `00001` — **NX only** | `0x7BFF`, flags `00101` — **OF and NX** |
| −65530 | RTZ | `0xFBFF`, `00001` | `0xFBFF`, `00101` |
| +65530 | RDN | `0x7BFF`, `00001` | `0x7BFF`, `00101` |
| −65530 | RUP | `0xFBFF`, `00001` | `0xFBFF`, `00101` |

Everywhere else — RNE, RMM, RUP positive, RDN negative — the two agree, because
there the rounded result really does leave the range.

**Only `status_o` can distinguish them.** `z_o` is identical on every input.

**Runnable witnesses** — `W4`–`W7` are the four divergent cases above; `W8` and
`W9` are the same exact magnitude in modes where both readings agree it
overflows, so a run that fails `W4`–`W7` while passing `W8`–`W9` has isolated
the trigger and not the table.

### Two candidate constants that are not merely wrong but incomplete

Worth stating explicitly, because they are the two a fixer is most likely to
reach for:

* **T = 65536 (2¹⁶).** Leaves a hole. Exact +65530 under **RNE** falls below T,
  so A5 does not apply and A4 must round it — and correct rounding gives 65536,
  which is not representable. A4 has no rule for that; A5 was the clause meant
  to supply one. The contract would say nothing.
* **T = 65520 (the RNE midpoint).** Leaves a hole for two modes. Exact +65510
  under **RUP** falls below T, so A4 must round it — RUP gives 65536, again not
  representable. Same for −65510 under RDN.

And a trap at the other end: reading "at or above the threshold" with **T =
65504** would make an exact result of exactly 65504 — a representable value that
requires no rounding at all — deliver ±∞ and raise OF. Any repair must exclude
65504 itself.

### What I would NOT want a fixer to assume

* **Do not assume the delivered values are in question.** All ten cells are
  IEEE-correct and both coherent readings agree on all ten. The defect is
  entirely in the **trigger**, and therefore visible only in OF.
* **Do not read "It is NOT to be inferred from A4 and F1" as asserting a
  departure from IEEE.** The table *is* IEEE's overflow-result table. That
  sentence is warning against naive "round it and see", which would give ±∞ in
  every mode — it is not a claim that the clause is non-standard.
* **Do not write a single number into the clause without checking it against
  all five modes and both signs.** Two of the three obvious candidates leave
  modes with no stated result at all.
* **Do not settle it by measuring the reference.** Same reason as §1. If the
  decision is (B), the clause must say that OF tracks the *exact* result rather
  than the rounded one, and say it deliberately — that is a real and defensible
  choice, but it is a departure from IEEE and rule 12 requires it to be named.

---

## 3. Tininess detection is never named, is reachable, and moves a flag

### What the text says

Nothing. That is the defect.

F1 requires subnormal support. A6 gives the below-range table. A7 says:

> "If a stage's result is subnormal and EXACTLY representable, no flag is raised
> at all — UF and NX both stay low. … Underflow is signalled only when the
> result is both **tiny** and inexact."

**"Tiny" is never defined.** IEEE 754‑2019 permits two detection methods —
tininess **before** rounding (evaluate the exact result against the smallest
normal) and **after** rounding (evaluate the unbounded-exponent rounded result)
— and requires an implementation to pick one. The contract picks neither.

RULES rule 12: "Where a task is anchored on a standard that permits
alternatives, every alternative the anchor forecloses is named in the spec as
out of scope. Otherwise the vectors silently encode the anchor's choice and a
conformant design fails a requirement nobody wrote down." This is that, exactly.

### The reachable case

Exact result **2047 × 2⁻²⁵** — which is 1023.5 × 2⁻²⁴, precisely halfway between
the largest subnormal (1023 × 2⁻²⁴) and the smallest normal (1024 × 2⁻²⁴ =
2⁻¹⁴). Under RNE this ties to even and delivers **`0x0400`**, the smallest
normal.

Constructible from ordinary binary16 operands, at any stage:

```
a = 0x0001   (2^-24)          x_i[r][k]
b = 0x3800   (0.5)            w_i[k]
c = 0x03FF   (1023 * 2^-24)   the addend: y_i[r] at stage 0,
                              or the previous partial sum at stage k > 0
exact = 1023*2^-24 + 2^-25 = 2047 * 2^-25
```

| rule | delivered | UF | NX | `status_o` |
|---|---|---|---|---|
| tininess **before** rounding | `0x0400` | **1** | 1 | `00011` |
| tininess **after** rounding | `0x0400` | **0** | 1 | `00001` |

Same delivered value. One status bit apart. My implementation takes **before**
(decision D8), chosen deliberately as the opposite of the project's other spec
so the choice would be visible rather than inherited.

**Runnable witness** — `W10`, and the same input appears as `D8.tiny`.

The class is wider than the one vector: any exact result that is tiny and rounds
up to exactly the smallest normal. Under RUP that is *every* positive exact
magnitude in (1023 × 2⁻²⁴, 2⁻¹⁴).

### What I would NOT want a fixer to assume

* **Do not assume A7 already settles it.** A7's worked example (2⁻¹⁴ × 0.5 →
  `0x0200`, all flags low) is **exact**, and both conventions agree whenever
  there is no rounding. A7 constrains the exact case and nothing else. It looks
  like the clause that settles flags near the subnormal boundary; it is not.
* **Do not assume A6 already settles it.** It does not — but note that A6 *does*
  rule out a third definition a fixer might reach for, and this is worth
  keeping: **"tiny" cannot mean "the delivered value is subnormal"**. A6's ten
  cases deliver ±0 or ±2⁻²⁴ and *all* raise UF, and ±0 is not subnormal. So that
  reading is already excluded by the text. Both genuine IEEE conventions survive
  A6 and A7; only the boundary case separates them.
* **Do not assume the choice is invisible because it never changes a value.** It
  is one bit of `status_o`, which T1 scores cycle by cycle, on an input a
  vector-writer would plausibly generate.
* **Do not write the reference's convention into the clause without naming the
  rejected one.** Rule 12's requirement is the *naming*, not the choosing.
  CONVENTIONS records that on `d_dsp02` the spec already said "tininess after
  rounding" and that still did not catch the inherited choice — it was found by
  counting flag combinations across 4290 captured vectors. Here the spec does
  not say even that much, so the vectors are currently the only place the answer
  exists.
