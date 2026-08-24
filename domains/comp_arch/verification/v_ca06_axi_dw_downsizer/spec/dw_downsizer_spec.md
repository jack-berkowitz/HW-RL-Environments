# `dw_downsizer` — specification

An AXI4 **data-width downsizer**. It accepts transactions on a wide upstream
port and re-issues them on a narrow downstream port, re-segmenting the data so
the byte stream is unchanged. It alters widths and nothing else.

Every clause below is stated so that a testbench can decide it. Where a bound
was chosen rather than derived, it is named as such and the measured value is
given, so you are never asked to guess a number.

---

## 0. Scored configuration — pinned

| | |
|---|---|
| upstream (slave) data width | **64 bits**, 8 byte lanes |
| downstream (master) data width | **16 bits**, 2 byte lanes |
| ratio | **4** |
| `ADDR_W` | 32 |
| `ID_W` | 4 |
| `MAX_READS` | 4 outstanding reads |
| `rst_ni` | **asynchronous**, **active low** |

Not parameters you may vary. One configuration is scored.

Throughout: **`beat_bytes(size)` = 2^`size`**, and

> **`aligned(addr, size)` = `addr` with its low `size` bits cleared.**

---

## 1. Transaction correspondence

- **A1.** An upstream address handshake (`s_awvalid && s_awready`, respectively
  `s_arvalid && s_arready`) **accepts** one upstream transaction.
- **A2.** Every accepted upstream transaction that §3 does not reject produces
  **exactly one** downstream transaction, on the matching channel, carrying the
  **same `id`** and the **same `addr`**.
  *Authority: task intent — this is a converter, not a splitter or a router.*
- **A3.** Every accepted upstream transaction produces **exactly one** upstream
  response: a `B` for a write, and an `R` burst whose final beat carries
  `s_rlast` for a read. Neither more nor fewer.
- **A4.** A transaction is **outstanding** from its address handshake until its
  final upstream response beat transfers. At most `MAX_READS` reads may be
  outstanding at once; a further read address need not be accepted until one
  retires.

---

## 2. The address transform

Let `size` and `len` be the upstream request's, and let

> `total_bytes = (len + 1) * beat_bytes(size) - (addr - aligned(addr, size))`

- **B1 — size.** The downstream `size` is **`min(size, 1)`** — the upstream size
  or the downstream width, whichever is smaller. It is **not** a constant: an
  upstream `size` of 0 stays **0**, and only sizes above the downstream width are
  reduced.
  *Measured: size 3 → 1, size 1 → 1, size 0 → **0**.*
- **B2 — length.** Let `first = addr` and `last = addr + total_bytes - 1`. The
  downstream burst covers every aligned downstream block from the one holding
  `first` to the one holding `last`, so

  > `downstream len = (aligned(last, dsize) - aligned(first, dsize)) / beat_bytes(dsize)`

  where `dsize = min(size, 1)`.

  **It is a count of BLOCKS SPANNED, not a division of the byte count.** Both
  readings agree on an aligned request at `size` 3, where it comes to
  `(len+1)*4 - 1`. They disagree twice:
  *at an unaligned address, because the first upstream beat contributes only the
  bytes from `addr` to the end of its aligned block* — `len=1 size=3 @0x1000`
  gives 7, and the same request `@0x1004` gives **5**;
  *and when the byte range does not fill one downstream block* — `len=0 size=1
  @0x1001` covers a single byte, and dividing gives **minus one** where the
  answer is **0**, one beat.
  *Measured for all four cases.*

- **B3 — address.** The downstream `addr` **equals** the upstream `addr`,
  unaligned or not. It is not realigned.
- **B4 — burst.** When the downstream burst has **more than one beat** the
  downstream `burst` is **`INCR`**.
  *Measured: upstream `FIXED len=0 size=3` becomes a four-beat downstream burst
  and its type is INCR.*

  When the downstream burst has **exactly one beat** the downstream burst type
  is **not specified** — see L6. A single-beat burst transfers one block and its
  type carries no meaning.
  *Measured: the anchor forwards `FIXED` unchanged there; an implementation that
  drives `INCR` instead is equally correct.*

---

## 3. Burst types that are refused

- **C1.** A **`WRAP`** burst is refused.
- **C2.** A **`FIXED`** burst of **more than one beat** (`len != 0`) is refused.
- **C3.** A `FIXED` burst of **exactly one beat** (`len == 0`) is **accepted** and
  converted under §2 like any other.
  *The verdict turns on a single beat: `FIXED len=0` is served, `FIXED len=1` is
  refused.*
- **C4 — what "refused" means, exactly.** A refused transaction:
  1. is still **accepted** on its upstream address channel — `s_arready` /
     `s_awready` rises for it;
  2. produces **NO downstream transaction at all**. Not an address, not a data
     beat. A monitor watching only the downstream port sees nothing;
  3. for a write, has its **entire `W` burst absorbed** upstream, every beat
     accepted and none forwarded;
  4. is answered with **`SLVERR`** — on the `B` beat for a write, and on **every
     one** of the `len + 1` upstream `R` beats for a read, not only the last;
  5. still receives exactly `len + 1` upstream `R` beats, with `s_rlast` on the
     last.

  *Authority: task intent for the refusal itself, which the anchor documents;
  measured for each of the five parts.*

---

## 4. The read data path

- **D1 — byte stream.** Number the bytes the transaction covers 0, 1, 2, … from
  `addr`. Reading the downstream `R` beats in order yields those bytes; reading
  the upstream `R` beats in order yields **exactly the same bytes, in the same
  order**, packed into the wide lanes.
- **D2 — lane placement.** An upstream beat's bytes sit in the lanes its address
  selects: byte at address `A` occupies lane `A mod 8`.
- **D3 — identifier.** Every upstream `R` beat carries the `id` of the
  transaction that produced it.
- **D4 — last.** `s_rlast` is high on the final upstream beat of a transaction
  and low on every other.
- **D5 — response.** Absent a refusal (§3) and absent a downstream error, every
  upstream `R` beat carries `OKAY`.
- **D6 — downstream error precedence, and it is STICKY.** Number the upstream
  beats 0, 1, 2, … Each is built from a group of downstream beats. An upstream
  beat carries an error response if any downstream beat in **its own group, or in
  any earlier group**, carried one. Equivalently: once an error occurs it
  persists to the end of the transaction, and beats before it are unaffected.

  *Measured, on a two-beat upstream read of eight downstream beats: an error on
  downstream beat 0 or 3 gives `SLVERR SLVERR`; an error on the LAST downstream
  beat gives `OKAY SLVERR`. It is not "all beats error", and a testbench that
  requires that rejects correct hardware.*
- **D7 — the error code is preserved.** `SLVERR` upstream for a downstream
  `SLVERR`, `DECERR` for a `DECERR`. Neither is normalised to the other.
  *Measured: `DECERR` on a downstream beat produces `DECERR` upstream.*

---

## 5. The write data path

- **E1 — byte stream.** The bytes an upstream `W` burst presents, taken in beat
  order and lane order, appear on the downstream `W` burst in the same order.
- **E2 — strobes split per byte lane.** Each downstream beat's `strb` carries the
  bits of the upstream `strb` for the byte lanes that beat covers, and nothing
  else.
  *Measured: upstream `strb = 0x81` at `size` 3 → downstream `01 00 00 10` across
  the four beats. The two live lanes land four beats apart.*
- **E3 — an unstrobed beat is still a beat.** A downstream beat all of whose
  lanes are unstrobed is **emitted**, with `strb = 0`. It is not suppressed and
  it is not skipped: the downstream burst always has exactly the `len + 1` beats
  §2 computed.
  *Measured: upstream `strb = 0x0F` at `size` 3 → four downstream beats, the last
  two with `strb = 00`.*
- **E4 — last.** `m_wlast` is high on the final downstream beat of a burst and
  low on every other.
- **E5 — one response.** The downstream burst's `B` produces exactly one upstream
  `B`, carrying the transaction's `id`.
- **E6 — error precedence, and the code is preserved.** If the downstream `B`
  carries an error, the upstream `B` carries **the same code**. Otherwise it
  carries `OKAY`. There is no stickiness question here: a write has exactly one
  response.
  *Measured: downstream `OKAY` gives upstream `OKAY`, downstream `SLVERR` gives
  upstream `SLVERR`.*

---

## 6. Reset

- **F1.** `rst_ni` is **asynchronous** and **active low**. While it is low the
  unit presents no valid on any channel it drives and completes nothing.
- **F2.** After release the unit is idle: no transaction is outstanding, and
  `MAX_READS` reads may be accepted again.
- **F3.** No transaction outstanding before reset produces a response after it.

---

## X. What is excluded from measurement

- **X1.** While `rst_ni` is low this contract requires nothing of any output. It
  governs what the unit **originates** once reset is released, and what reset
  leaves behind. **This applies from the first rising clock edge onward** — before
  any edge the registers hold no defined value, so sampling at time zero tests
  nothing promised here.
- **X2.** The value on any output while its `valid` is low. A payload nothing can
  observe carries no requirement.
- **X3.** Anything that follows an upstream `W` burst whose `strb` does not cover
  the byte lanes its address selects. Such a burst is not conforming AXI, and the
  contract says nothing about the response to it. **Drive lane-correct strobes**:
  at `size` 1 and address `0x1002` the live lanes are 2 and 3, not 0 and 1.

---

## L. Latitude — named, and deliberately unconstrained

- **L1 — latency.** The number of cycles between an upstream address handshake
  and the downstream one, and between a downstream response and the upstream
  one, is unconstrained and may vary between transactions.
- **L2 — readiness.** When `s_awready`, `s_arready`, `s_wready`, `m_bready` and
  `m_rready` rise is unconstrained, except that A4's bound is a bound on
  *blocking*, not on promptness. Ready may be low for reasons of internal
  arbitration. **Do not require a ready merely because the unit looks idle.**
- **L3 — interleaving between transactions.** With more than one transaction
  outstanding, the order in which their downstream requests are issued, and the
  order in which their upstream responses complete relative to each other, is
  unconstrained. Per transaction the beats are in order; **between** transactions
  nothing is promised.
- **L4 — the downstream `W` burst may start before the upstream one finishes**,
  or after it. Whether the unit forwards beats as they arrive or buffers a whole
  upstream beat first is free.
- **L5 — how many downstream beats are in flight**, and whether the downstream
  burst is issued as one contiguous run of beats or with gaps, is free.
- **L6 — the burst type of a SINGLE-BEAT downstream burst.** It transfers one
  aligned block; `FIXED` and `INCR` describe the same transfer, so neither is
  required. Do not check it. B4 binds only where the downstream burst has more
  than one beat.

These six are the whole of the latitude in this contract. Everything above is
exact.

---

## Termination — a requirement on your testbench

Your testbench shall terminate on its own, unconditionally, under every
implementation it is run against, and shall include a watchdog that reports
failure and finishes after a generous time limit regardless of what the design
does.

**One of the faulty implementations refuses a request it should accept.** A
testbench that waits for that acceptance with no timeout runs forever: it has not
detected the fault, it has stopped.

---

## What this contract does not say

It says nothing about `lock`, `cache`, `prot`, `qos`, `region`, `atop` or `user`
— they are not ports. It says nothing about upstream sizes larger than the
upstream width, or about `len` values that would carry a burst across a 4 KiB
boundary; neither is driven at this configuration. It does not say which
downstream beat of a refused transaction would have carried which byte, because a
refused transaction has no downstream beats at all.
