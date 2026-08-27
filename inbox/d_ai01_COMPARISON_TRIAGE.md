# d_ai01 second source — triage note. Read this BEFORE you look at a diff.

**For:** whoever runs the comparison of
`inbox/d_ai01_second_source_fp16_gemm_array.sv` against the reference.

The author of that RTL predicted, before any comparison, *where* it would
disagree and *what shape* each disagreement would take. Those predictions are
frozen in the RTL header. This note is the part you cannot reconstruct from a
diff: **what each shape implies, in the order to test it.** The single most
useful fact is at §2 — most of the predicted divergences move `status_o` only
and leave `z_o` bit-identical, so the first question is not *which cycles* but
*which output*.

---

## 0. Three checks before you run anything

**0a — confirm the file.** The predictions are only evidence if they predate the
result:

```bash
shasum -a 256 inbox/d_ai01_second_source_fp16_gemm_array.sv
```

If it does not match the hash recorded in the commit that landed these files,
stop: the header may not hold the predictions that were frozen.

**0b — smoke-test the build.** Three probes ship alongside; they drive this file
only and touch nothing in `tb/` or `ref/`. Expect `59 checks, 0 failures` from
the clause probe and `0 failures` from the timing and control probes at both
HEIGHT=4 and HEIGHT=8. If these do not pass, the problem is your build and not
the design.

**0c — the C3 lookup, one line, do it first.** C3 was edited after this
derivation (commit `77ac97f`, landing this reader's own CF‑4). The question is
whether the *relation* survived the recomputation:

> Does the current C3 still state `dfb = D*(HEIGHT-1) + 4`, equivalently
> `d(0) + 1`?

* **Yes** → C3 is **not void** for this work. The implementation encodes that
  relation and measures 16 enabled ticks at H=4, 32 at H=8. Any `dfb`
  disagreement is a real finding.
* **No** → C3 is void exactly as C2 and C5 are. The accumulate behaviour here
  was derived against superseded text and needs a fresh clean reader. Do not
  report a `dfb` disagreement as a finding in that case.

---

## 1. Apply the exclusion windows before classifying anything

Nothing below means anything until the unscored intervals are removed. In
enabled ticks, per C5's enumeration:

| interval | length | at H=4 | at H=8 |
|---|---|---|---|
| C2 refill, after `flush_i` falls | `D*(H-1)+3` | 15 | 31 |
| C3 transition, after **any** change of `accumulate_i`, either direction | `2*D*(H-1)+7` | 31 | 63 |
| C4 post-release, after any change of `row_clk_gate_en_i[r]`, **per row** | `D*(H-1)+3` | 15 | 31 |

Counted in **enabled ticks** (A1: `reg_enable_i && row_clk_gate_en_i[r]`), not
raw clock edges. If the harness counts edges, everything downstream is wrong in
a way that will look like an arithmetic disagreement.

---

## 2. Triage by the SHAPE of the disagreement, in this order

### Shape A — `z_o` bit-identical everywhere, `status_o` differs on a minority of cycles

**This is the predicted case, and it means the arithmetic core is sound.**
Identify which decision by the bit that moved:

| bit | accompanying `z_o` | decision | witness |
|---|---|---|---|
| **UF** | `0x0400` / smallest normal; exact result was tiny and rounded up | **D8**, tininess before vs after rounding | `W10` |
| **OF** | `0x7BFF` / `0xFBFF`, the largest finite | **D12**, overflow trigger | `W4`–`W7` |
| **NV** | operands include a NaN | **D9**, sNaN and NaN-vs-invalid ordering | — |
| **NV** | operands include an infinity, addend also infinite | **D10**, `inf − inf` | — |
| anything else | — | **unpredicted** — the most valuable outcome here; report it | — |

For D12 specifically: if the `W8`/`W9`-shaped cycles (same magnitude, modes
where both readings overflow) **agree** while `W4`–`W7`-shaped ones disagree,
you have isolated the *trigger* and not the table. Say so — it settles defect 2
in `d_ai01_TEXT_DEFECTS.md`.

All of Shape A is a finding **about the text**. The RTL stays unchanged.

### Shape B — `z_o` disagrees broadly, on ordinary finite inputs, at both heights

**Structural, not arithmetic. Do not start by looking at the FMA.**

**First test, costs one re-run:** shift the reference stream by **one enabled
tick** and re-compare. If mismatches collapse to zero, it is **D1**, the
sampling convention — every delay is right and the two sides disagree about what
"the value at enabled tick *t*" names. That is a finding about the convention,
not a bug, and it is a *uniform* shift: every row, every stage, both heights.

If it does **not** collapse under a uniform shift, compare the measured `d(k)`
against A3: **15, 11, 7, 3** at H=4 and **31, 27, 23, 19, 15, 11, 7, 3** at H=8.
The timing probe already measures these and they match. If the probe agrees with
A3 and the comparison does not, the disagreement is in the harness's tick
accounting, not the design — see §1.

### Shape C — disagreement confined to a window after `flush_i` falls, `accumulate_i` changes, or a gate changes

Exclusion windows, §1. **Not a design result.** Check the lengths and the
per-row scoping of C4 before anything else.

### Shape D — disagreement at the *first* enabled tick of a flush assertion, and nowhere else

**D5, and the region is VOID** — C2 moved after this derivation. Disregard it
entirely. Do not file it as a finding and do not correct the RTL for it; it
belongs to whoever re-derives C2.

### Shape E — disagreement everywhere, including immediately after reset

Wiring, parameters, or geometry. V2 requires `z_o` = `0x0000` and `status_o` =
0 under reset, and the design does that in both probes. Check port order,
`HEIGHT`/`WIDTH`, and packed-dimension orientation before concluding anything.

### Shape F — `z_o` **and** `status_o` both disagree broadly

Matches no prediction. Treat as Shape E until ruled out; a real simultaneous
failure of both surfaces is far less likely than a harness or geometry problem.

---

## 3. What not to do

* **Do not change the RTL.** The author pre-committed: a disagreement is a datum
  about the contract text, reported rather than adjusted.
* **Do not resolve a flag mismatch by matching the reference.** That is exactly
  the tuning this oracle exists to avoid, and it would destroy the only evidence
  the exercise generates about which choices are actually free.
* **Do not conclude anything about the RTL from a tool-invocation error.** See
  `d_ai01_T5_CHECK.md` §3a: if the message names an option or an argument it is
  the harness; if it names a construct, a line, or a file in the design it is a
  result.

## 4. How to rank what you find

Most valuable first: an **unpredicted** disagreement; then a **predicted
flag-only** one (Shape A); then the **uniform one-tick shift** (D1); then clean
agreement. Clean agreement on a clause marked FORCED in §4 of the report is
weak evidence that the clause is unambiguous — a contaminated reader reaches the
same answer. The rows that carry weight are the ones marked FREE or INFERRED.
