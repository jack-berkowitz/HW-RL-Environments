# `stream_realign` — specification

A realignment stage on a valid/ready byte stream. Data arrives in four-byte
beats, but the *line* the consumer wants may not start on a beat boundary. The
unit rotates the stream so that the consumer sees full beats starting at the
line's first byte, carrying bytes across beat boundaries to do it.

Clauses marked **latitude** are choices the implementation is free to make;
your testbench must not require either answer.

---

## 0. Configuration — pinned

| quantity | value |
|---|---|
| beat width | **32 bits = 4 bytes** |
| `strb_i` width | 4, one bit per byte |
| `rst_ni` | **asynchronous**, **active low** |
| `clear_i` | **synchronous**, active high; returns the unit to its starting condition |

Byte 0 of a beat is bits `[7:0]`, byte 1 is `[15:8]`, and so on.

## H. The handshake

- **H1.** A beat moves on the input in any cycle where `push_valid_i` and
  `push_ready_o` are both high at the rising edge; on the output, where
  `pop_valid_o` and `pop_ready_i` are both high.
- **H2.** This is an obligation on **you**, the source: once `push_valid_i` is
  asserted, it and `push_data_i` are held unchanged until that beat has moved.
- **H3.** `push_ready_o` may depend on `push_valid_i` and carries no meaning in
  a cycle where nothing is being offered.

## P. Pass-through, when `realign_i` is low

- **P1.** With `realign_i` low the unit is transparent: every input beat
  appears on the output with `pop_data_o` equal to `push_data_i` and
  `pop_strb_o` equal to `push_strb_i`, and the two handshakes are the same
  handshake — `pop_valid_o` follows `push_valid_i` and `push_ready_o` follows
  `pop_ready_i`.

## R. Realignment, when `realign_i` is high

Define the **rotation** *R* as the **number of set bits in `strb_i`**. It runs
from 0 to 4 and is *not* taken modulo the beat width — a fully set strobe gives
*R* = 4, not 0.

- **R1.** A beat presented with `first_i` high is the **first beat of a line**.
  It produces **no output beat**. It is consumed and retained.
- **R2.** A beat after the first produces an output beat **if and only if**
  `last_i` is high or `strb_i` is non-zero on that beat. `strb_i` therefore has
  two distinct roles: at a line's first beat it fixes the rotation (R4), and on
  every beat it gates whether an output is produced. When one is produced its
  value is the retained beat and the current beat joined at the rotation:

  > `pop_data_o = (push_data_i << 8R) | (retained >> 8(4-R))`

  where a shift of 32 or more yields zero. Both extremes follow from this and
  are worth stating plainly: at *R* = 0 the second term vanishes and the output
  is the **current** beat; at *R* = 4 the first term vanishes and the output is
  the **retained** one, so the stream is delayed by a whole beat.
- **R3.** `pop_strb_o` is **all ones** on every output beat produced while
  realigning, whatever `push_strb_i` carried.
- **R4.** The rotation *R* is fixed for a line: it is taken from `strb_i` at
  the line's first beat and does not change while the line runs.
- **R5.** The byte stream is **preserved** — for a line in which every beat
  after the first satisfies R2's condition, so that none is silently consumed.
  Number the bytes of such a line's input beats 0, 1, 2, … in order. Reading the output beats of that line in order
  gives exactly those bytes from index **4 − *R*** onward, with none lost,
  duplicated or reordered. A fully set strobe therefore starts at byte 0 and an
  empty one at byte 4 — that is, it skips the first beat entirely.
- **R6.** A beat presented with `last_i` high produces its output beat even if
  `strb_i` is entirely clear — that is the "or" in R2.

## X. Reset and liveness

- **X1.** `rst_ni` is asynchronous and active low. While it is low
  `pop_valid_o` is not asserted.
- **X2.** `clear_i` returns the unit to its starting condition: no beat is
  retained and no line is in progress.
- **X3 (liveness bound).** With `pop_ready_i` held high, a beat offered on the
  input is accepted within **16** cycles.

---

## L. Latitude — named, and deliberately unconstrained

- **L1.** Whether the **first beat of a line is accepted while the sink is not
  ready**. It produces no output, so an implementation may take it immediately;
  it may equally hold it until the sink is ready. Do not require either.
- **L2.** `pop_data_o` and `pop_strb_o` in any cycle where `pop_valid_o` is
  low. A payload nothing can observe carries no requirement.

These two are the whole of the latitude in this contract.

---

## What this contract does not say

It says nothing about what `push_strb_i` means while realigning — R3 fixes the
output strobe regardless. It places no requirement on the unit's behaviour if a
line's first beat never arrives, nor on `strb_i` in any cycle other than a
line's first beat, which R4 makes the only one that matters.
