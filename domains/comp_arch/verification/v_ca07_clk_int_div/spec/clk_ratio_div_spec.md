# `clk_ratio_div` — specification

A runtime-configurable integer clock divider. It takes an input clock and
produces an output clock at a programmable ratio, and it changes ratio without
emitting a malformed pulse.

**Correctness here is about INTERVALS BETWEEN EDGES, not sampled values.** A
testbench that samples `clk_o` as a signal will not see most of what follows.
Every clause below is stated in whole `clk_i` cycles so it can be decided by
counting edges.

Every number given was measured on a conforming implementation. Where a bound
was chosen rather than derived it is named as such.

---

## 0. Scored configuration — pinned

| | |
|---|---|
| `div_i` width | 4 bits, so divisors **0 to 15** |
| divisor after reset | **0** |
| `rst_ni` | **asynchronous**, **active low** |
| output while `rst_ni` is low | gated |

`test_mode_en_i` is pinned low and no clause depends on it.

---

## P. The output clock

- **P1 — period.** For `div_i` of 2 or more, one `clk_o` period is exactly
  `div_i` `clk_i` cycles.
- **P2 — the duty cycle is 50%, at EVERY divisor.** In each period `clk_o` is
  high for exactly half the period and low for exactly half.

  At an **even** divisor that is a whole number of `clk_i` cycles. At an **odd**
  divisor it is a **half-integer**: the transitions fall on `clk_i`'s falling
  edges as well as its rising ones, so divisor 3 is high for 1.5 cycles and low
  for 1.5, divisor 5 is 2.5 and 2.5, divisor 7 is 3.5 and 3.5.

  **Measure this in time, not in whole `clk_i` cycles.** Counting rising edges of
  `clk_i` between a rise and a fall of `clk_o` truncates the half and reports
  divisor 3 as high 1, low 2 — a 33% duty that the unit does not have. A
  testbench that measures that way will reject correct hardware at every odd
  divisor.
  *Measured in raw time at divisors 2 through 8: high equals low equals half the
  period in every case.*

- **P4 — an obligation on YOU, the measurer.** Measure the period and the duty
  **in time**, not in whole `clk_i` cycles.

  At every odd divisor the high and low phases are half-integer numbers of
  `clk_i` cycles. Any check that quantises to whole cycles — counting `clk_i`
  rising edges between a rise and a fall of `clk_o`, for instance — truncates the
  half and reports divisor 3 as 33% duty. Such a check **rejects conforming
  hardware at all seven odd divisors** in the range.

  This is stated as an obligation, in the same form as H2's obligation on the
  source, because it is not inferable from P2 and because getting it wrong does
  not look like a mistake: it produces a clean, self-consistent, wrong answer
  that agrees with itself across every odd divisor. If your stimulus happens to
  use only even divisors you will pass the golden and fail legal submissions.

- **P3 — 0 and 1 are a DEGENERATE PAIR, and the distinction is UNSCORED.** Both
  mean pass-through: `clk_o` has the same period as `clk_i`, one input cycle.
  *Measured for both.*

  **What this means for scoring, stated so it is not left to be inferred.**
  Pass-through itself IS scored — a unit that gives period 2 at `div_i = 1`
  violates this clause and will be caught. What is **not** scored is any
  difference **between** 0 and 1: they are observationally identical, so no
  testbench can distinguish them and no fault will ever be keyed on that
  distinction. You are not asked to tell them apart and you are not penalised for
  treating them as one value.

  Both remain in the scored configuration. Removing one would hide a real
  degenerate case that an implementation can get wrong in the same way for both.

---

## H. Reconfiguration, and its handshake

- **H1 — it is a real handshake.** A new divisor is offered with `div_valid_i`
  and taken with `div_ready_o`. `div_ready_o` is **not free-running**: it is low
  while `div_valid_i` is low.
  *Measured: held low across 20 cycles with `div_valid_i` deasserted. A testbench
  that treats it as always-ready is describing a different unit.*
- **H2 — an obligation on YOU, the source.** While `div_valid_i` is high, hold
  `div_i` stable until `div_ready_o` rises. The contract says nothing about what
  a unit does with a value that changes underneath an offer, and this document
  will not be extended to cover it.
- **H3 — a SAME-VALUE request is a no-op, and it is granted immediately.** If the
  offered `div_i` equals the divisor already in force, `div_ready_o` rises in the
  **same cycle** and the output is **not gated at all**.
  *Measured: 0 cycles to grant, and the output runs at full rate straight
  through. A real change takes longer and gates. One value changes the verdict.*
- **H4 — a request during a transition is DEFERRED, not refused.** A second
  change offered while a first is still gating is held off and then accepted; it
  is not rejected and it does not need re-offering.
  *Measured: granted 8 cycles later, where an uncontended change is granted in
  1 to 4.*

---

## G. Gating across a change

- **G1 — the bound, and where it is measured FROM.** On a change to a different
  divisor, `clk_o` is gated and then resumes. Counting from the cycle
  `div_ready_o` rises — **not** from the cycle you asserted `div_valid_i` — the
  gap to the first rising edge of the new clock is at most

  > **3 × (the new period in `clk_i` cycles)**

  where the period of divisor 0 or 1 is 1.

  **The origin is load-bearing.** Measured from the assertion of `div_valid_i`
  the bound does not hold, because the handshake wait — 1 to 4 cycles depending
  on phase — is not gating.
  *Verified across all 72 ordered pairs of divisors in 0..8: zero violations, and
  the bound is **exactly attained** on all 14 transitions to divisor 0 or 1,
  where the gap is 3 and the limit is 3. A unit that gates one cycle longer on
  those is outside the contract.*
- **G2 — gated means idle low.** While gated, `clk_o` stays low. It does not stop
  high and it does not emit a partial pulse.

---

## E. Enable

- **E1.** With `en_i` low the output is stopped: no rising edge occurs.
  *Measured: zero rising edges in 100 cycles.*
- **E2.** With `en_i` returned high the output resumes at the configured divisor.
- **E3 — disabling does not truncate a pulse, and does not leave the output
  high.** Two obligations, and neither is E1. When `en_i` falls, the high phase
  in progress completes at its full width; the output then stays low.

  **Do not write this as a deadline.** "Low on every input edge after `en_i`
  falls" is the wrong shape, because at an **odd** divisor the high phase is a
  half-integer and its tail runs past any whole-cycle grace you pick. The
  quantity the clause is about is the **width of the final high pulse**, which is
  half the period whatever the divisor. A number of cycles generalised from an
  even divisor will fail a conforming unit.
  *Measured: the final high pulse is a full half-period at divisors 4 and 5, and
  `clk_o` is low on all 40 input edges once at rest.*

  Note that **E1 cannot see the second half of this.** E1 counts rising edges,
  and an output stuck high has none.

---

## C. The cycle counter

- **C1.** `cycl_count_o` advances once per `clk_i` cycle and wraps at the
  configured divisor, taking the values `0` to `div_i - 1`.
  *Measured: `1 2 3 0 1 2 3 0` at div 4; `2 0 1 2 0 1` at div 3.*
- **C2.** In pass-through — `div_i` of 0 or 1 — `cycl_count_o` is constantly `0`.
  *Measured.*
- **C3.** After a change is accepted, `cycl_count_o` counts over the **new**
  divisor's range immediately, without a partial cycle of the old one.
  *Measured across a 4 to 8 change: `0 1 2 3 4 5 6 7 0 1 …`.*

---

## R. Reset

- **R1.** `rst_ni` is **asynchronous** and **active low**. While it is low no
  rising edge appears on `clk_o`.
- **R2 — reset restores the DEFAULT divisor, not the last configured one.** After
  release the unit is in pass-through, whatever it was set to before.
  *Measured: configured to 4, reset, and the output returned at period 1.*

---

## X. What is excluded from measurement

- **X1.** Nothing is required of any output while `rst_ni` is low. This applies
  from the first rising clock edge onward; before any edge the registers hold no
  defined value.
- **X2.** The **sub-cycle** duty of `clk_o` in pass-through. There `clk_o`
  follows `clk_i`, so its high and low phases are the input clock's own and are
  not a property of this unit. Measure pass-through by period, not by duty.
- **X3.** Anything following a violation of H2 — a `div_i` that changes while
  `div_valid_i` is high and before `div_ready_o` rises.
- **X4.** `test_mode_en_i`, which is pinned low.

---

## L. Latitude — named, and deliberately unconstrained

- **L1 — the phase of `clk_o` relative to `clk_i`.** Which input edge a period
  begins on is free. Only the period and the split within it are fixed.
- **L2 — how long gating actually lasts**, below G1's bound. A unit that resumes
  sooner is conforming. Do not require a particular duration.
- **L3 — when `div_ready_o` rises** for a change to a different value. H3 fixes
  it only for the same-value case.
- **L4 — how long H4's deferral lasts.** That a second request is eventually
  accepted is fixed; when is not.
- **L5 — `cycl_count_o` while the output is gated or disabled.** C1 fixes its
  behaviour while the clock is running.

These five are the whole of the latitude in this contract. Everything else above
is exact.

---

## Termination — a requirement on your testbench

Your testbench shall terminate on its own, unconditionally, under every
implementation it is run against, and shall include a watchdog that reports
failure and finishes after a generous time limit regardless of what the design
does.

**A faulty implementation here can stop the output clock entirely.** A testbench
that waits for an edge on `clk_o` with no timeout runs forever — and a testbench
clocked BY `clk_o` stops with it. Drive and time everything from `clk_i`.

---

## What this contract does not say

It says nothing about divisors above 15, which the port cannot express. It says
nothing about changing `en_i` and `div_i` in the same cycle. It does not say
whether the unit is glitch-free by construction or by gating, only what the
output does.
