# d_ai01 — D1: what "signal at enabled tick t" means. FOR A FRESH READER.
# Unassigned. NOT a defect in anyone's RTL. Written 2026-08-27 by the agent who
# ran the comparison, who is disqualified from deriving on this task.

## Why you are reading this rather than fixing something

A second source derived this design from the contract text alone and delivered a
bit-exact-in-shape implementation that disagrees with the reference by **exactly
one tick, uniformly, at both legal HEIGHTs.** Their pre-commitment is that a
disagreement is a datum about the text and not a defect in their RTL, and the
RTL is unchanged. That commitment is being honoured: nothing here asks anyone to
alter an implementation.

**What is needed is a reading of the clause.** The author is contaminated for it
— they have already derived it once. So is the agent who ran the comparison, for
this task generally. You are the fresh reader.

## What the text says

`A1` defines the enabled tick: a `posedge clk_i` with `reg_enable_i` and
`row_clk_gate_en_i[r]` both high. All timing in the contract is counted in
enabled ticks of the row in question.

`A3` gives the per-stage operand-to-output delay `d(k) = D*(H-1-k) + 3`.
`L3` gives total latency from stage 0's operands to `z_o` as `D*(H-1) + 3` —
15 at HEIGHT=4, 31 at HEIGHT=8.

Every one of these is phrased as *the value of a signal at enabled tick t*.

## What it fails to determine

**Whether "the signal at enabled tick t" means its value at the SAMPLING INSTANT
of edge t, or its value AFTER edge t has been taken.**

Nothing in A1, A3 or L3 chooses. The phrase is used consistently and is
consistently ambiguous, and the two readings differ by exactly one register on
every path in the design.

## The full divergence pair

| | reading A — sampling instant | reading B — post-edge |
|---|---|---|
| `d(k)` counts | enabled-tick registers between an input and `z_o` | the same, plus one |
| L3 total latency at HEIGHT=4 | **15 registers** | **16 registers** |
| L3 at HEIGHT=8 | **31 registers** | **32 registers** |
| the reference implements | | **B** |
| the second source implemented | **A** | |

Both readings satisfy every stated number in the contract. They differ only in
what the number is a count OF.

## What the measurement settles, and what it does not

Measured with `tb/audit/probe_shift_tally_tb.sv`, all 3400 record cycles, scored
row-samples, per-row windows from the full record stream, at shifts 0, 1 and 2
with shift 2 as a paired control:

| shift | H=4 z agree | H=8 z agree |
|---|---|---|
| 0 | 14.48% | 16.36% |
| **1** | **93.67%** | **93.60%** |
| 2 (control) | 15.19% | 17.02% |

**IT SETTLES THAT TWO READINGS EXIST AND WHICH ONE EACH IMPLEMENTATION TOOK.**
A one-tick realignment takes agreement from 14% to 94% while the control stays
flat, so the difference is a uniform timing offset and not arithmetic. The
reference is reading B; the second source is reading A.

**IT DOES NOT SETTLE WHICH READING THE TEXT REQUIRES.** The measurement says what
the reference does. The reference is not the contract, and this task's own record
contains a clause that was rewritten because the reference's behaviour had been
mistaken for the requirement.

## What a fixer must not assume

* **Do not assume the reference is right because it is the reference.** The
  question is what A1's phrase means, and A1 does not cite the reference.
* **Do not close it by measurement.** Measuring the reference again produces
  reading B again and adds nothing; it is the step that would look like progress
  and is not.
* **Do not treat the 94% as near-agreement.** It is 100% agreement on a
  different clock. The residual is separately accounted for (MEASUREMENTS §22)
  and none of it bears on this question.
* **Do not pin the convention in L3 alone.** The phrase is used in A1, A3 and
  L3, and a correction that reaches one is this task's recorded failure class
  (F99). If the convention is stated, it belongs where the tick is DEFINED.
* **Do not narrow it to a latency clause.** `dfb`, both `d(k)` tables and every
  exclusion window are counted in the same unit, so the reading moves all of
  them together or the contract becomes internally inconsistent.
