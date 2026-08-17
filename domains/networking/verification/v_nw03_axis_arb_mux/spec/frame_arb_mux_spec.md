# `frame_arb_mux` — specification

An arbitrated multiplexer. `S_COUNT` independent input streams carry framed
data; one output stream carries the same frames, one whole frame at a time.

Ships with the port map (`frame_arb_mux_iface.sv`) and this document.
**No RTL is shipped.**

Every clause is numbered and individually citable. Every contract term names its
source of authority; where the authority is a standard that permits alternatives,
the alternatives this contract forecloses are named in §7.

---

## 0. Parameters

| name | meaning |
|---|---|
| `S_COUNT` | number of input streams |
| `DATA_WIDTH` | width of one beat of payload, in bits; a multiple of 8 |
| `USER_WIDTH` | width of the per-beat user sideband |

`s_tkeep_i` and `m_tkeep_o` are `DATA_WIDTH/8` bits wide.

*Authority: parameter names and widths are fixed by the shipped port map.*

---

## 1. Beats and frames

**S1 — beat.** A beat transfers on input `k` on a rising clock edge where
`s_tvalid_i[k] && s_tready_o[k]`. A beat transfers on the output on a rising
clock edge where `m_tvalid_o && m_tready_i`.
*Authority: AMBA AXI4-Stream — transfer occurs when VALID and READY are both
asserted at a rising clock edge.*

**S2 — frame.** A frame is a sequence of one or more beats on one input, ending
with the beat on which `s_tlast_i[k]` is high. **A frame may be a single beat**,
carrying `s_tlast_i[k]` high on its first and only beat.
*Authority: AMBA AXI4-Stream — TLAST marks the last transfer of a packet.*

---

## 2. What the output carries

**S3 — frame atomicity.** Once a beat of some frame from input `k` has
transferred on the output, every subsequent output beat shall carry the next
beat of **that same frame**, until and including the beat on which `m_tlast_o`
is high. No beat originating from any other input may transfer on the output
between the first and last beat of a frame.
*Authority: task intent — this is the property under test.*

**S4 — payload integrity and order.** Each output beat shall carry the
`tdata`, `tkeep` and `tuser` of exactly one input beat, **unmodified and
complete across the full width of each field**, and the beats of an input shall
appear on the output in the order in which they transferred on that input.
`m_tlast_o` shall be high on exactly those output beats carrying an input beat
that had `s_tlast_i[k]` high.
*Authority: AMBA AXI4-Stream — TDATA, TKEEP and TUSER are per-transfer payload
and sideband, and a multiplexer forwards a stream rather than transforming it.*

**S5 — no loss, no duplication.** Every beat that transfers on an input shall
transfer exactly once on the output.
*Authority: task intent.*

---

## 3. Handshake

**S6 — READY IS NOT A GRANT.** `s_tready_o[k]` may be high on an input that is
not selected and whose frame will not be forwarded next. A beat transferring on
input `k` does **not** imply that input `k` has been selected, nor that its data
will appear on the output in that cycle or the next. The port map exposes no
selection output, and none is inferable from `s_tready_o`.

A testbench that treats a beat accepted at an input as a beat forwarded to the
output will diverge from the design immediately, on correct hardware.
*Authority: task intent — stated as a contract term precisely because the
natural reading of a ready/valid input port is the opposite one.*

**S7 — source obligation (this constrains the TESTBENCH, not the design).**
Once `s_tvalid_i[k]` is asserted it shall remain asserted, with `s_tdata_i[k]`,
`s_tkeep_i[k]`, `s_tlast_i[k]` and `s_tuser_i[k]` held stable, until the beat
transfers. The design's behaviour if this is violated is unspecified.
*Authority: AMBA AXI4-Stream — a source must not wait for READY before asserting
VALID, and having asserted VALID must keep it asserted until the transfer
completes.*

**S8 — backpressure.** `m_tready_i` may be low on any cycle, including
mid-frame and on the cycle carrying `m_tlast_o`, for arbitrarily many
consecutive cycles. No beat shall be lost, duplicated or reordered as a result,
and no frame in progress shall be abandoned.
*Authority: AMBA AXI4-Stream — a sink may withhold READY arbitrarily.*

---

## 4. Selection

**S9 — selection order is unconstrained.** Which input is selected for the next
frame, and on what basis, is not specified. A testbench shall not require any
particular order, nor require that a given input be selected within any bound
tighter than S10.
*Authority: rule 12 — arbitration policy is deliberately unconstrained.*

**S10 — bounded fairness.** Under **continuous offered load** — defined as every
input holding `s_tvalid_i[k]` continuously with further complete frames
available, and `m_tready_i` held high throughout — **every input shall begin at
least one frame within any window of 16 consecutive completed output frames.**

The bound is stated as a finite window, not as "eventually", for two reasons: an
unbounded liveness claim cannot be falsified by any finite run, and the submitted
testbench must terminate on its own (S13). 16 is four times the smallest window
in which a design serving its inputs in strict rotation must reach all four at
`S_COUNT = 4`, so any evenly-serving policy passes with margin while an input
that is never selected fails on the first full window.
*Authority: task intent, with the window as a recorded design decision of this
task; the number is stated here rather than left to a reader to infer.*

---

## 5. Reset

**S11 — latency is unconstrained.** The number of cycles between a beat
transferring on an input and its appearance on the output is not specified, and
may vary between beats.
*Authority: rule 12.*

**S12 — reset.** `rst_i` is **synchronous and active high**. While `rst_i` is
high the design shall be returned to an idle state. On the first cycle after
`rst_i` is released, `m_tvalid_o` shall be low, and **no beat that transferred
on an input before or during reset shall appear on the output afterwards.**
*Authority: polarity and synchronicity are fixed by the port map's `rst_i`;
the discard requirement is task intent, stated because AXI4-Stream does not
settle whether data in flight survives a reset.*

---

## 6. Termination — a requirement on the submitted testbench

**S13.** The submitted testbench shall terminate on its own, unconditionally,
under every implementation it is run against. It shall include a watchdog: an
independent process that reports failure and finishes after a generous time
limit regardless of what the design does.

This is not a style preference. The testbench will be run against deliberately
faulty implementations, **one of which never selects an input that a correct
design would select.** A testbench that waits for that output with no timeout
runs forever. It has not detected the fault — it has stopped — and it blocks the
grading run for everything queued behind it.
*Authority: stated task requirement.*

---

## 7. Named latitude (rule 12)

The following are **explicitly out of scope and shall not be checked.** Each is
a point where the contract above admits more than one correct design, and a
testbench that pins one of them will reject correct hardware.

1. **Selection order** — which input goes next, and any policy behind it (S9),
   subject only to S10's window.
2. **Latency** between an input beat and its output beat (S11).
3. **Promptness of `s_tready_o[k]`** — an input's ready may be low on any cycle,
   for reasons including but not limited to fullness or another input being
   served. A testbench shall not require ready to be high merely because the
   design is idle (S6).
4. **`m_tdata_o`, `m_tkeep_o` and `m_tuser_o` while `m_tvalid_o` is low** — the
   values on those signals are unconstrained. They may hold their previous
   value, be zero, or be arbitrary. They shall not be checked.
5. **Whether a new frame may begin on the output in the same cycle the previous
   frame's `m_tlast_o` beat transfers**, or whether idle cycles separate frames.
   Both are legal, and the number of idle cycles is unbounded.
6. **Internal structure** — arbiter type, buffering, register stages, whether
   inputs are buffered at all.
7. **Behaviour of `m_tkeep_o` on non-final beats.** This contract requires only
   that whatever arrived on `s_tkeep_i[k]` with a beat leaves with it (S4); it
   does not require any particular pattern, and does not give `tkeep` a meaning
   beyond a forwarded sideband.

---

## 8. Scored configuration (rule 18)

The graded run uses exactly one parameter binding:

| parameter | value |
|---|---|
| `S_COUNT` | **4** |
| `DATA_WIDTH` | **32** |
| `USER_WIDTH` | **1** |

**Rationale.** `S_COUNT = 4` is the smallest count at which an evenly-serving
policy is distinguishable from a fixed order, and at which one starved input is
a minority of the machine rather than half of it; at `S_COUNT = 2` a starvation
fault and a legal alternating policy are hard to separate. `DATA_WIDTH = 32`
makes `tkeep` a four-bit sideband rather than the single bit it degenerates to
at `DATA_WIDTH = 8`, so S4's "complete across the full width of each field" has
something to bind on. `USER_WIDTH = 1` keeps the per-beat sideband present at
minimum width.

*Authority: rule 18 — one scored configuration, named in the spec, with its
rationale recorded beside it.*

Three further axes are **not parameters of the shipped port map at all** and
cannot be varied: the design is fixed to serve its inputs in rotation rather
than by fixed priority, to treat `tlast` as the frame boundary its arbitration
respects, and to start its rotation from input 0. They are bound inside the
implementation because S10 and S3 are properties of those choices, and a
specification that demanded them while leaving the axes free would be
demanding behaviour a legal configuration could not deliver.
