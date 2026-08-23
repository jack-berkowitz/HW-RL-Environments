# `ptp_time_base` — specification

A free-running time base. It advances two timestamps every clock cycle by a
**fractional** amount, and it can be steered while it runs: the nominal period
can be replaced, a signed offset can be applied to a counted number of
increments, and a signed drift can be applied to one increment in every *N*.

The arithmetic is exact. There is no tolerance anywhere in this contract: a
testbench that compares the time base against a model to within "close enough"
will accept a design that is wrong.

Clauses marked **latitude** are choices the implementation is free to make;
your testbench must not require either answer.

---

## 0. Configuration — pinned

The module takes no parameters. These values are fixed inside it and you may
rely on them:

| quantity | value |
|---|---|
| fractional resolution | **1 fns = 2⁻¹⁶ ns** (16 fractional bits) |
| nominal period, from reset | `4'h6` ns + `16'h6666` fns = **6.4 ns** exactly |
| default drift, from reset | `4'h0` ns + `16'h0002` fns |
| default drift rate, from reset | **5** |
| nanoseconds per second | **1 000 000 000** |
| `rst_i` | **synchronous**, **active high** |

## F. Timestamp formats

- **F1.** `ts96_o` is `{seconds[47:0], 2'b00, ns[29:0], fns[15:0]}`.
- **F2.** `ts64_o` is `{ns[47:0], fns[15:0]}`.
- **F3.** A `fns` unit is 2⁻¹⁶ ns in both, so a whole nanosecond is 65536 fns.

## I. The increment

- **I1.** On every clock cycle each time base advances by an **increment**,
  which is the sum, as **signed** quantities, of
  1. the current period, plus
  2. the offset adjustment, on the cycles §A says it is applied, plus
  3. the drift, on the cycles §D says it is applied.

  **Do not begin measuring before cycle 9.** Clause X2b makes cycles 1 through
  8 after any reset unconstrained, for the increment value and the drift
  spacing alike. A count that starts at cycle 1, or an average taken over a
  window that includes those cycles, is measuring the warm-up.

  **Check each base on its own.** The two bases do not have to receive a given
  increment on the same cycle, and in general they will not; clause L2 leaves
  the phase between them free. Deriving one base's expected advance from the
  other's, on the same cycle, is a comparison this contract does not support.
- **I2.** The period is `4'h6`/`16'h6666` from reset, and is replaced by
  `{period_ns_i, period_fns_i}` when `period_valid_i` is asserted.

## A. The counted offset adjustment

- **A1.** Asserting `adj_valid_i` latches `{adj_ns_i, adj_fns_i}` and
  `adj_count_i`.
- **A2.** That adjustment is added to **exactly `adj_count_i` consecutive
  increments** — no more, and no fewer.
- **A3.** `adj_active_o` is asserted on **exactly `adj_count_i` cycles**, and
  those cycles are consecutive. It marks the adjustment in progress; the
  contract does not fix its alignment against the adjusted increments
  themselves (see L2).
- **A4.** `ts_step_o` is asserted on exactly those same cycles (and on the
  cycles §S names, and on no others).
- **A5.** `{adj_ns_i, adj_fns_i}` is a **signed** 20-bit quantity. A negative
  value retards the time base.

## D. The periodic drift adjustment

- **D1.** Asserting `drift_valid_i` latches `{drift_ns_i, drift_fns_i}` and
  `drift_rate_i`.
- **D2.** The drift is added to **exactly one increment out of every
  `drift_rate_i` consecutive increments**, counted **separately on each base**.
  The two bases are not in phase with one another (L2), so the drift lands on
  different cycles in each, and measuring the spacing on one base against the
  other's cycles will not give `drift_rate_i`. Begin counting at cycle 9 or
  later: clause X2b leaves the spacing unconstrained before then.
- **D3.** `{drift_ns_i, drift_fns_i}` is a **signed** 20-bit quantity.

## S. Setting the time base

- **S1.** Asserting `set_ts96_valid_i` sets the 96-bit base to `set_ts96_i`.
- **S2.** Asserting `set_ts64_valid_i` sets the 64-bit base to `set_ts64_i`.
- **S3.** Each such assertion raises `ts_step_o` for **exactly one cycle**.
- **S4.** The two bases are **independent accumulators driven by the same
  sequence of increments**. Setting one does not disturb the other, and neither
  the count of adjusted increments nor the drift spacing differs between them.

## W. The one-second wrap

- **W1.** The `ns` field of `ts96_o` never reaches 1 000 000 000. On the
  increment that would carry it to or past that value, exactly 1 000 000 000 is
  subtracted from it and the `seconds` field increases by one.
- **W2.** `ts64_o` has no seconds field and does **not** wrap at one second.
- **W3.** `pps_o` is asserted for **exactly one cycle** on each wrap described
  in W1, and is **not** asserted at any other time.

At 6.4 ns per cycle a wrap is over 150 million cycles away. §S is the only
practical way to reach one.

## R. Reset

- **R1.** `rst_i` is **synchronous** and **active high**.
- **R2.** Reset returns the module to its starting condition: both bases read
  zero, the period returns to `4'h6`/`16'h6666`, the drift and drift rate
  return to `4'h0`/`16'h0002` and 5, and any offset adjustment still owed is
  cancelled.

---

## X. What is excluded from measurement

- **X1.** While `rst_i` is asserted this contract requires nothing of any
  output. It governs what the module *originates* once reset is released, and
  what reset leaves behind.
- **X2a.** Number the cycles after reset so that **cycle 1 is the first rising
  edge at which `rst_i` is low**.
- **X2b (warm-up after reset).** **Cycles 1 through 8 after any reset are
  unconstrained, for the increment value and the drift spacing alike.** The
  pipeline is refilling; neither §I nor §D applies to those cycles, and this
  holds after *every* reset, not only the first. Measurement resumes at cycle
  9.
- **X2c (warm-up after a set).** A set is a discontinuity, and it carries the
  same allowance: for up to **4 cycles** after `set_ts96_valid_i` or
  `set_ts64_valid_i` is accepted, **that base's** advance need not follow §I or
  §D. The value written by S1 or S2 is visible immediately — it is the
  *increment following it* that is unconstrained, and only on the base that was
  set. Measurement of that base resumes from the fifth cycle.

  This matters most at a wrap. §W is reached in practice only by setting the
  base close to one second (§W's own note says so), which puts the wrap a few
  cycles after a set. Sample the wrap **after** this window has elapsed: a
  `ts96_o` compared one or two cycles early will show the pre-wrap value and
  read as a missing wrap, and `pps_o` will not yet have fired.

## L. Latitude — named, and deliberately unconstrained

- **L1.** The number of cycles between a control input's `valid` and the first
  increment that reflects it is **unconstrained**, up to a bound of **8
  cycles**, **measured separately on each base**. The two bases do not adopt a
  control change on the same cycle, so a change visible on one may be two or
  more cycles later on the other; the bound is per base, not shared. An implementation may act on it immediately or register it first.
  This applies to `period_valid_i`, `adj_valid_i` and `drift_valid_i`.
  It does **not** relax A2, A3 or D2: whenever the adjustment begins, it is
  applied exactly the stated number of times, and `adj_active_o` marks exactly
  those cycles.
- **L2.** The **relative phase between `ts96_o` and `ts64_o` is
  unconstrained**, and so is the phase of the increment sequence each of them
  sees. An implementation may hand the same increment to both on the same
  cycle, or to one of them a fixed number of cycles after the other. The
  alignment of `adj_active_o` against the adjusted increments is free in the
  same way. What is fixed is that each base, taken on its own, advances by a
  legal increment every cycle, receives the drift exactly every `drift_rate_i`
  cycles, and receives the offset adjustment on exactly `adj_count_i`
  increments. Do not require any particular difference between the two.

These two are the whole of the latitude in this contract. Everything else above
is exact.

---

## What this contract does not say

It says nothing about what happens to `ts64_o` when its `ns` field overflows 48
bits — that is over three days away and out of scope. It places no requirement
on the outputs while `rst_i` is asserted, only on what reset leaves behind. It
does not say whether a control input asserted in the same cycle as `rst_i` is
honoured.
