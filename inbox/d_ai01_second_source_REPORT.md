# d_ai01 second source — derivation report

**Artifact:** `inbox/d_ai01_second_source_fp16_gemm_array.sv`
**Derived against:** `9da6e62bfecb8d5a94dcf366c67ea5da07729d74`
**Status:** delivered, with two clause regions **VOID** — see §0.

This is an oracle, not a submission. It was written from the contract text
alone to be a second opinion on what that text requires. It was never run
against `ref/` or `tb/`, and nothing in it was tuned toward any other
implementation.

---

## 0. THE TEXT MOVED UNDER THE DERIVATION — read this first

`HEAD` advanced from `9da6e62` to `e312ee3` while this work was in progress.
Commit **`1bbc5bd` "The simultaneity premise is measured, the maintenance grep
is narrowed, and the narrowing costs the grep"** edited the contract:

| file | old blob | new blob |
|---|---|---|
| `spec/fp16_gemm_array_iface.sv` | `9d0b0444` | `158fd959` |
| `probe/PASTE.md` | `fe2f78bd` | `413d47e5` |

804 → 818 lines. Two hunks, located by line number only — **the new prose was
not read**, because the protocol says a moved text voids the work rather than
amending it:

* a **10-line pure insertion** at old line 266 → inside **C2** (247–344)
* a **3-line → 7-line replacement** at old line 453 → inside **C5** (431–497)

### What that voids

| | |
|---|---|
| **VOID** | **C2**, **C5**. With them: decision **D5**, **D6**, **D7** and finding **CF‑1**. |
| **STANDS** | All arithmetic, all latency, both range tables, the clock gate, the port map. |

**A second edit landed later.** Commit **`77ac97f` "CF‑4 closed by
recomputation, three items recorded open, and a gate defect I was asked to file
that I have measured to be false"** moved **C3** — one line at old 361 plus an
8-line insertion after old 365, located by line number only. That is *this
derivation's own finding* being landed. Final tally at HEAD `2e1d63d`:

| | |
|---|---|
| **MOVED** | **C2**, **C3**, **C5** |
| **INTACT** | the other **28 of 31**: `F1 F2 F3 V1 V2 V3 Aanon A1 A2 A3 A4 A5 A6 A7 A8 A9 A10 C1 C4 L1 L2 L3 P1 P2 T3 T4 T5 MODDECL` |

**C3 is a weaker void than C2 and C5.** The edit closed a defect I reported, *by
recomputation* rather than by altering the relation — and the relation is what
this implementation was built on (`dfb = d(0)+1`, measured here as 16 / 32). A
recomputation of stale numbers from a correct relation lands on 16 / 32. That
makes agreement likely, and likely is not verified: I have not read the new C3
and will not. Whoever runs the comparison should confirm it directly.

The insertion landed **inside the very paragraph CF‑1 is about**. CF‑1 was a
conflict between C2 ¶1 ("z_o reads +0 for as long as it is asserted") and C2's
own simultaneity argument. A commit subject reading "the simultaneity premise
is measured" is more likely than not addressing the same thing.

### Who should redo C2 — not me

Deriving C2 once has contaminated me for C2. I know what I concluded and why,
so a second pass by me would be a re-reading, not a derivation, and it would
carry the old reading's shape into the new text. **The C2/C5 redo needs a fresh
clean reader.** I have not read the new text and will not, so that reader's
independence is still available if it is spent on someone else.

The RTL is left exactly as derived. D5's behaviour (the combinational `z_o`
force) is *flagged*, not corrected — correcting it would be adjusting to a text
I am not entitled to have read.

---

## 1. Pinning

All reads went through `git show <SHA>:<path>`, never the working tree.

```
spec/fp16_gemm_array_iface.sv  804 lines  sha256 7c0b815de4ac8ea0a2a99f17f434e402b224d176ca49c1d95087fd567e376583
probe/PASTE.md                 843 lines  sha256 7a05fe8803cdb8c9547778382e8395f6a1331047c4a48e1226f6e3a423df51f8
RULES.md                      1021 lines  sha256 7cd223f6c64b033932df9159f53da1c12d943738f0b1686f21ff7bdec5182863
CONVENTIONS.md                 935 lines  sha256 108b4ee8093422df6165e0be254e7fcdb914830b43030b6764a1598e3478ffa5
```

`PASTE.md`'s fenced `systemverilog` block and `spec/fp16_gemm_array_iface.sv`
are **byte-identical** at the pinned commit (`diff`, 0 differences, both 804
lines). There is one contract text, not two that can drift.

The 31 per-clause region hashes are in the RTL header. They were recomputed at
report time and every one still matches **at the pinned SHA** — which is a
tautology for immutable git objects, and is exactly why the check that mattered
was the one in §0: comparing the pinned blob against *current* `HEAD`. A
protocol that only re-hashes the pinned object cannot see the text move.
Staleness is quiet; that is the whole point.

---

## 2. Decision list

Every point where the text did not determine the answer. "Rejected" is the
alternative that is equally legal against the pinned text.

### The load-bearing one

**D1 — the sampling convention.** *(inference, not explicit text)*
"Signal at enabled tick `t`" = its value at the sampling instant of edge `t`
(pre-edge). Under D1, `d(k)` is exactly the **count of enabled-tick registers**
between an input and `z_o`.

Forced by C2's own tick numbering: `status_o(1)` is "the value A10 gives", i.e.
still the pre-flush value, while `status_o(t≥2)` is frozen — so a write at edge
1 is visible at tick 2, not tick 1. Corroborated by CONVENTIONS' "never change
stimulus in the same timestep as the sampling edge".

*Rejected:* the post-edge convention, under which every path would need `d(k)+1`
registers and `L3`'s 15 would be 16 registers of latency.

**Nothing else in this build is as load-bearing as D1.** If D1 is wrong every
delay is off by exactly one, uniformly, and the whole comparison is a
one-tick shift rather than an arithmetic disagreement. That signature is worth
checking for first if this oracle disagrees broadly.

### Structure — free under G4

| # | Choice | Rejected alternative |
|---|---|---|
| **D2** | Budget spent as **1 operand-input register per stage + 3 partial-sum registers** (2 on the last stage): `1+3 = 4 = D`, `1+2 = 3 = d(H-1)`. | 0 input registers and 4 (resp. 3) partial-sum registers — identical `d(k)` and `dfb`. **Deliberately the less obvious split**, so a structural disagreement shows up as one. |
| **D3** | **Exact wide fixed-point FMA**: exact product and exact addend on a common 2⁻⁴⁸ grid, 84-bit exact signed sum, then **one** rounding. No alignment shift, no normalisation loop. | A conventional align/normalise datapath. Chosen for auditability; area is not what an oracle is for. |
| **D4** | Leading-one search **chunked 7×12 = 19 iterations**. | An 84-iteration scan. Rejected on T5: 84 × HEIGHT × WIDTH would approach slang's 4000 unroll budget at HEIGHT=8. Rows and stages are `generate`, never procedural loops, for the same reason. |
| **D16** | A uniform 3-deep pipe declared at every stage; the last stage taps `[1]` and `pz[H-1][2]` is driven but unused. | Per-stage pipe depths. Wellformedness (C5) over minimality — nothing is left undriven. |
| **D15** | `accumulate_i` sampled at stage 0's own tick. | Any other sampling point; C3 leaves all transitions unscored. |

### Arithmetic — where the text stops short

| # | Choice | Rejected alternative | Basis |
|---|---|---|---|
| **D8** | **Tininess detected BEFORE rounding.** | After rounding. | **Nothing in the contract names this.** See GAP‑1. Deliberately the opposite of the project's other spec. |
| **D9** | **Any** NaN operand — quiet *or* signalling — delivers `0x7E00` with **no flag**, checked **before** `inf×0`. So `fma(inf, 0, qNaN)` raises nothing. | sNaN raises NV; or `inf×0` checked first so that case raises NV. IEEE 754‑2019 makes the ordering explicitly implementation-defined. | A9 ¶3 is unconditional: "any quiet NaN operand … raises NO flag". Extended to sNaN because A9 does not mention it. |
| **D10** | `inf − inf` (infinite product, infinite addend, opposite signs) → `0x7E00` + **NV**. | Deliver an infinity, or raise nothing. | **Inference.** A9 ¶1 says "+ finite" and never covers an infinite addend — which is reachable, since A5 makes RNE overflow deliver `+inf` into the next stage. |
| **D11** | A8's zero-sign rule generalised to **any** exact zero, including cancellation of non-zeros; same-signed zeros keep their sign in every mode. | A8 applied literally to opposite-signed zeros only, leaving cancellation unspecified. | **Inference** from IEEE §6.3. |
| **D12** | Overflow condition is **IEEE's, mode- and sign-dependent**: the rounded-with-unbounded-exponent magnitude exceeds 65504. | A single fixed "overflow threshold" constant. | A5's five-row table **is exactly** IEEE's overflow-result table, so its condition should be IEEE's too. See CF‑3. |
| **D13** | A6's table read as the **worked example at 2⁻²⁵** under correct rounding, not as an override of A4 across the whole sub-2⁻²⁴ range. | The table applied literally to every magnitude below 2⁻²⁴. | Correct rounding **reproduces A6's table exactly** at 2⁻²⁵, all ten cells. See CF‑2. |
| **D14** | `rnd_i` 5–7 behave as RNE. | Anything. F3: "not exercised and carry no requirement". |

### Void — derived against a C2 that no longer exists

| # | Choice | Rejected alternative |
|---|---|---|
| **D5** | `z_o` forced to `+0` **combinationally** while `flush_i & row_clk_gate_en_i[r]`, so it reads `+0` at **tick 1** of the assertion, not from tick 2. | Registered-only forcing, `z_o = +0` from tick 2. Both readings were legal against the pinned C2 — this is CF‑1. |
| **D6** | Flush zeroes the operand input registers too, not only the partial sums. | Zero only the partial sums. Unobservable either way: `z_o` is `+0` during the assertion and the refill window is unscored. |
| **D7** | The whole flag path freezes during an assertion. | Freeze only the output register. With one flag register per stage the two coincide here — recorded as a structural consequence, not a choice that was available. |

---

## 3. Findings about the text

Ordered by what I would act on first.

### CF‑4 — C3 states the feedback depth twice and the two disagree *(clause region intact; hash `9142f9c8`)*

C3 gives the rule as

> `dfb = D*(H-1) + 4 = d(0) + 1`, "so at HEIGHT=8 the feedback carries 32
> enabled ticks and at HEIGHT=4 it carries 16"

and then, four lines later:

> "Measured at both geometries — **15 at H=4 and 31 at H=8** — after an earlier
> draft of this clause asserted d(0) and was wrong by exactly one tick in both."

15 and 31 **are** `d(0)`. The sentence says the earlier draft asserted `d(0)`
and was wrong by one, while quoting the measurement as the value it says was
wrong. One of the two is stale.

**The formula is right and the numbers are stale.** Not a preference — C3's own
transition window closes it. That window is `d(0) + dfb = 2*D*(HEIGHT-1)+7`,
"31 at HEIGHT=4". At H=4, `d(0)=15`, so `15 + dfb = 31` forces **`dfb = 16`**.
L3 independently says the recirculation period settles `dfb` at `d(0)+1`.

This is the **same failure mode A3 documents about itself** — a `+2` constant
that survived the correction to `+3` in the surrounding prose. The correction
reached the sentence and not the numbers beside it, one clause over.

*This oracle implements `dfb = d(0)+1` and measures 16 at H=4 and 32 at H=8.*

### CF‑2 — A6's table is "in full" and is also a single worked example *(intact; `94db18ce`)*

A6 says the delivered value is "set out here in full, in both directions, for
every rounding mode … stated, not left to inference", then immediately: "Taking
the representative case of an exact result of magnitude 2⁻²⁵".

Applied literally to the whole range it declares (magnitude below 2⁻²⁴), the
table says RNE delivers ±0 for **every** such value. For an exact magnitude of
0.9 × 2⁻²⁴ correct rounding gives 2⁻²⁴, so the literal table **contradicts A4**.

Read as the worked example, the table is reproduced exactly — all ten cells —
by plain correct rounding. That is strong evidence for the narrow reading, and
it is why D13 went that way. **The clause should say which it is**, because
both readings are currently available and they differ on real inputs.

### CF‑3 — "the binary16 overflow threshold" is named as one number and is not one number *(intact; `c80fdfe6`)*

A5 triggers on the **exact** result being "at or above the binary16 overflow
threshold" — a single quantity. But IEEE's overflow condition is mode- and
sign-dependent, and A5's table *is* IEEE's overflow-result table, cell for cell.

The two readings differ on real inputs. For an exact result of **65530** under
RTZ:

* IEEE / D12 → deliver `0x7BFF`, **NX only, no OF**
* a fixed threshold at or below 65530 → deliver `0x7BFF`, **OF and NX**

Same value, different flag, on an input that is neither exotic nor unreachable.
A reader who takes "threshold" to mean 2¹⁶ gets a third answer, and for RNE that
reading is incoherent: exact 65530 would fall to A4, which would have to round
it to 65536 — not representable, and A5 would be the clause that was supposed
to say so.

### GAP‑1 — tininess detection is never named *(rule 12)*

RULES rule 12: "Where a task is anchored on a standard that permits
alternatives, every alternative the anchor forecloses is named in the spec as
out of scope." IEEE permits tininess before or after rounding. **The contract
never says which**, and A7 does not settle it — A7's example is exact, so both
conventions agree there.

Reachable, and the flags differ. Exact `2047 × 2⁻²⁵` rounds under RNE to
exactly 2⁻¹⁴, the smallest normal:

* before rounding (D8, this oracle) → **UF and NX**
* after rounding → **NX only**

CONVENTIONS records this exact class of defect being found on `d_dsp02` by
counting flag combinations across captured vectors, and notes that a spec saying
"tininess after rounding" still would not have caught it. Here the spec does not
say even that much.

### GAP‑2 / GAP‑3 / GAP‑4 — A9 and A8 are narrower than the inputs they will see

* **GAP‑2.** A9 covers "infinity × finite-nonzero + **finite**". An **infinite
  addend** is not covered, and it is reachable in one hop: A5 makes an
  overflowing stage deliver `+inf` under RNE, which is the next stage's addend.
  `inf − inf` currently has no clause.
* **GAP‑3.** A9 says "any **quiet** NaN operand". Signalling NaN is unmentioned;
  IEEE would raise NV, A9's shape suggests not.
* **GAP‑4.** A8 covers a zero "that arises as the sum of two zeros of opposite
  sign". Exact zero by **cancellation of non-zeros** is not covered, nor are two
  zeros of the *same* sign.

Each is small. Together they are the corners a differential run will hit.

### CF‑1 — **VOID**, and reported as history only

Derived against C2 region hash `f4d272fa…`, which no longer exists. The
insertion from `1bbc5bd` landed inside this paragraph, so **this finding may
already be answered by text I am not entitled to have read.**

For the record, against the pinned C2: ¶1 says `z_o` reads `+0` "for as long as
it is asserted", and the status paragraph establishes that flush's effect on the
registers is visible only from tick 2. A purely registered flush therefore
cannot make `z_o` read `+0` at tick 1 — while "NOTHING IS EXCLUDED FROM SCORING
DURING AN ASSERTION" and the deletion of the 3-tick rising-edge window remove
the escape. Satisfying both required flush to land on **opposite sides of the
register** for `z_o` and for `status_o`. Meanwhile C2's own simultaneity
argument only rules out a `HEIGHT-1`-tick march, tacitly accepting a one-tick
delay that ¶1's literal words forbid.

**Do not treat this as a live finding.** Check it against the new C2 first.

---

## 4. Strength statement — stated before any comparison happens

**The bound first.** An obvious reading is weak evidence that a clause is
unambiguous, because a contaminated reader reaches it too. Agreement between
this oracle and the reference on any FORCED row below is worth close to nothing
as evidence about the text; agreement on an INFERRED or FREE row is worth
something, and disagreement there is worth the most.

| Reading | Basis | Weight of agreement |
|---|---|---|
| Chain order, seeded by bias (A2) | **Forced.** Written as equations. | none |
| `d(k) = 4(H-1-k)+3`, `D = 4` (A3/L1/L2/L3) | **Forced.** Formula plus both tables plus L3, mutually consistent at this SHA. | none |
| `dfb = d(0)+1` | **Forced by arithmetic, not by prose** — the formula and the window agree, one quoted measurement does not (CF‑4). | some |
| A5 / A6 tables, cell for cell | **Forced.** Tabulated. Reproduced exactly, 20/20 cells. | none |
| A7 tiny-but-exact | **Forced.** Worked example given; reproduced. | none |
| A8 opposite-signed zeros | **Forced** for the case named; **inferred** beyond it (GAP‑4). | mixed |
| A10 status = 2 ticks, uniform in k | **Forced.** Stated flatly and measured here at every k, both heights. | none |
| `status_o` holds from tick 2 (C2) | **Forced** — but against a **VOID** region. | disregard |
| Overflow *condition* (D12) | **Inferred** from the table matching IEEE. CF‑3. | **high** |
| A6 table scope (D13) | **Inferred**; two readings live. CF‑2. | **high** |
| Tininess before rounding (D8) | **Free.** Nothing in the text. GAP‑1. | **highest** |
| sNaN, NaN-vs-`inf×0` priority (D9) | **Free.** Unmentioned. | **highest** |
| `inf − inf` (D10) | **Inferred.** Unmentioned. GAP‑2. | **highest** |
| Sampling convention (D1) | **Inferred**, and everything timing-related rests on it. | **high** |
| Register split, pipe depths (D2/D16) | **Free** under G4. Deliberately non-obvious. | n/a — invisible if right |
| `z_o` at flush tick 1 (D5) | **VOID.** | disregard |

**Where I expect to disagree, ranked.** Recorded now so it cannot be
back-fitted later: D8 (tininess) → D9 (sNaN / NaN priority) → D12 (overflow
flag between 65504 and 65536) → D10 (`inf − inf`) → D1 (a *uniform one-tick
shift on everything* — check for this signature before assuming an arithmetic
bug) → D5 (void; C2 tick 1 only).

**Rule 5 — three independent differences from the anchor**, named before
writing, not after: **D3** exact 84-bit fixed-point FMA with no alignment or
normalisation step; **D2** the operand-register-first split of the delay budget;
**D4** chunked 7×12 leading-one instead of a per-bit scan. None is a consequence
of another. All three are inspection-verifiable in
`inbox/d_ai01_second_source_fp16_gemm_array.sv` at the constructs named. None is
measured — area and timing were not run, and by rule 5's own terms an honest
two-or-fewer measured beats a decorative three, so this is recorded as **0
measured / 3 inspection-verifiable**, upgradeable if a synthesis slot frees up.

---

## 5. What was run — and what was not

Everything below drives **this file only**. Nothing from `tb/` or `ref/` was
read, executed, or linked. Harnesses live in the session scratchpad, not the
repo, so they cannot be mistaken for a scoring rig.

| Check | Result |
|---|---|
| `verilator --lint-only -Wall`, HEIGHT=4 and 8 | **clean, no warnings** |
| Contract-table check (A5–A9, free-choice probes, divergence witnesses) | **59 / 59** |
| `d(k)` by impulse, every k, HEIGHT=4 | **15, 11, 7, 3** — matches A3 |
| `d(k)` by impulse, every k, HEIGHT=8 | **31, 27, 23, 19, 15, 11, 7, 3** — matches A3 |
| `dfb` by recirculation period, two periods each | **16** at H=4, **32** at H=8 — matches C3's formula, contradicts C3's quoted numbers (CF‑4) |
| `status_o` delay, every k, both heights | **2** everywhere — matches A10 |
| V2 reset, C1 freeze, C4 gate-vs-flush, flush-over-`reg_enable` | pass, both heights |
| C2 status suspension, on the alternating field C2 names | pass — `00101` **held** across 8 ticks while `z_o` reads `+0`; a clearing design would read `00000`, an advancing one would alternate |

The C2 row above was re-run after a first attempt froze on the flag-free phase,
where holding and clearing predict the same constant — the trap C2 itself warns
about ("A CONSTANT OPERAND FIELD SHOWS NOTHING HERE"). The phase was shifted by
one tick so the frozen value is non-zero. The first run is not quoted as
evidence.

**Not run, and it matters (T5):** `slang` is **not installed on this host**
(`which slang` → not found). The design was built to T5's rules by construction
— every declaration precedes every statement in its block, every loop has a
small constant bound, rows and stages are `generate` rather than nested
procedural loops, both parameters carry defaults — but **this is unverified**.
T5 is exactly the gate that turns a bit-exact design into no PPA number at all,
and this oracle has not passed it.

**Also not run:** area, power, timing closure. No PPA claim is made.

---

## 6. Contamination status

Deriving this contaminates me for any future clause derivation on d_ai01 — and
specifically for **C2**, which now needs a redo I should not be the one to do
(§0). I have not read the post-`1bbc5bd` text and will not.

Incidental exposure is itemised in the RTL header. The one item worth a
decision: `git ls-tree`, run to pin the tree, printed the `controls/nc_*.sv`
filenames, whose names describe each mutant's defect and so assert things about
the reference by negation. No control file was opened. Every axis those names
touch — subnormal flushing, overflow-always-infinity, zero sign, chain order,
HEIGHT-dependence — is pinned explicitly by F1, A5, A6, A8, A2 and P1, and each
is marked **FORCED** in §4, i.e. already carrying zero evidential weight. The
free and inferred rows, which are the ones that carry weight, do not overlap any
control name. **Pinning a tree should not require listing the mutants.**

---

## 7. Freeze — the predictions predate any comparison

The ranked disagreement predictions and the full free-choice log are written
**into the artifact itself**, `inbox/d_ai01_second_source_fp16_gemm_array.sv`,
not only into this report. That is deliberate: a prediction that lives only in a
commentary file can be edited after a result lands and nothing would show it.

**Provenance chain.** Derived against `9da6e62`. Observed `HEAD` move to
`e312ee3` and then `2e1d63d` during the session, both recorded above with the
regions they touched. **No comparison against `ref/` or `tb/` has been run by
this author, none will be, and this author will not see the outcome.**

**Deliverable hashes at freeze:**

```
867742fdd417fad2ed6b849a717f3beec57a549324a70b4fbef15b344e18cd02  d_ai01_second_source_fp16_gemm_array.sv   [superseded, see below]
5d650b675e3a2d548525fec08adc55baa8753e8f05ee3f3c28dde5edf4cf099b  d_ai01_second_source_probe_clauses.sv
844f73ba85f7d83a766e4842ec5e249e42abcb0bdb240bcd0b380dc210c754eb  d_ai01_second_source_probe_timing.sv
fef6ab281a4876a4f5e149e33617760e4fe771cb7a3149673110b0fe0da80545  d_ai01_second_source_probe_control.sv
e57844c6e77f7dea819e0f4756a7a475494d4beed8968e08f8e932b5453c44d4  d_ai01_second_source_slang_top_h4.sv
bac0d1af27f853366fd1081cb260c42bce49fa33ca675c67647973b2e8af3ab7  d_ai01_second_source_slang_top_h8.sv
e5187a68ff689bd572031c76d7004b577f9f775471dc851c264eb37b9f9812bb  d_ai01_T5_CHECK.md
```

The RTL and `d_ai01_TEXT_DEFECTS.md` were edited **after** that listing, to
record the C3 move and to cross-reference the divergence witnesses. Neither edit
touched a line of RTL, the free-choice log, or the predictions — both are
comment and prose only. The authoritative hashes are the ones printed at the end
of this section by the command below; **whoever runs the comparison should
record the hash of the file they actually consume.** If it matches, the
predictions provably predate the result.

```bash
shasum -a 256 inbox/d_ai01_second_source_*.sv inbox/d_ai01_T*.md
```

This is content-addressed, not time-attested. If you want a git-backed
timestamp, say so and I will commit these files with explicit paths under the
repo's commit convention; I have not done so unasked.

**What is frozen, in one line:** predictions ranked D8 → D9 → D12 → D10 → D1 →
D5, with the diagnostic that D8/D9/D12/D10 are **flag-only** — they move
`status_o` and leave `z_o` identical — so a broad `z_o` disagreement means D1 or
D2, structural, and not the arithmetic.
