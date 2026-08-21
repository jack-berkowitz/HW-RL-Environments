# `atop_filter` — specification

A protection unit sitting between an AXI4 master and a subordinate that does
**not** implement atomic transactions. Writes carrying an atomic opcode must
never reach the subordinate. Because the master is still owed a reply, the unit
must **manufacture** the replies that the blocked transaction would have
produced — and must do so without disturbing the ordinary traffic flowing
around it.

Every clause below is a requirement on the module declared in
`spec/atop_filter_iface.sv`. Clauses marked **latitude** are choices the
implementation is free to make; your testbench must not require either answer.

---

## 0. Configuration — pinned

The module is scored at exactly one configuration:

| parameter | value |
|---|---|
| `ID_W` | 4 |
| `ADDR_W` | 32 |
| `DATA_W` | 32 |
| `USER_W` | 1 |

One further constant is **fixed inside the design and is not a parameter**:

| constant | value | meaning |
|---|---|---|
| `MAX_WRITE_TXNS` | **4** | the outstanding-write bound of §W |

All AXI signals follow AMBA AXI4. `rst_ni` is **active low**.

---

## C. Classification

- **C1.** An AW is **atomic** if and only if `s_awatop_i[5:4] != 2'b00`.
  Classification depends on bits `[5:4]` **only**; `s_awatop_i[3:0]` never
  affects whether a write is atomic.
- **C2.** An atomic AW **additionally owes a read response** if and only if
  `s_awatop_i[5] == 1'b1`.

So there are three kinds of write: non-atomic (`[5:4] == 00`), atomic without a
read response (`[5:4] == 01`), and atomic with a read response
(`[5:4] == 10` or `11`).

## P. Pass-through — what must be left alone

- **P1.** A non-atomic AW is forwarded to the master port with every field
  unmodified, except `m_awatop_o` (see F1).
- **P2.** The W beats of a forwarded write are forwarded unmodified and in
  order, with `m_wlast_o` marking the same beat that `s_wlast_i` marked.
- **P3.** The read address path is never altered: AR is forwarded unmodified,
  and R beats arriving on the master port are returned on the slave port
  unmodified. A read is never filtered, whatever its address.
- **P4.** A B response arriving on the master port is returned on the slave
  port unmodified — `id`, `resp` and `user` alike.

## F. Filtering — what must be blocked, and what must be manufactured

- **F1.** An atomic AW is **never** forwarded to the master port, and
  `m_awatop_o` is `6'b000000` whenever `m_awvalid_o` is asserted. (A channel's
  payload while its `valid` is low is not observable and carries no
  requirement — here or in any clause below.)
- **F2.** The W beats belonging to a filtered write are **consumed** on the
  slave port and **never** forwarded to the master port. Consumption runs
  through and includes the beat carrying `s_wlast_i`.
- **F3.** For each filtered write the unit returns **exactly one** B response,
  with `s_bresp_o == 2'b10` (SLVERR) and `s_bid_o` equal to the `s_awid_i` of
  **that** write.
- **F4.** For each filtered write for which C2 holds, the unit **additionally**
  returns **exactly `s_awlen_i + 1`** R beats, each with `s_rresp_o == 2'b10`
  (SLVERR) and `s_rid_o` equal to the `s_awid_i` of that write, with
  `s_rlast_o` asserted on the **final** beat and on no other.
- **F5.** For a filtered write for which C2 does **not** hold, the unit returns
  **no** R beats at all.

## W. The outstanding-write bound

- **W1 (definition).** The **downstream write debt** at any cycle is

  > (number of AW handshakes completed on the master port)
  > − (number of W handshakes completed on the master port carrying `m_wlast_o`)

- **W2.** The downstream write debt never exceeds `MAX_WRITE_TXNS` (**4**).
- **W3.** While the debt is strictly below `MAX_WRITE_TXNS`, this bound alone
  does not stall a non-atomic AW.
- **W4.** The debt is reduced by the **completion of a W burst on the master
  port**, and *not* by the arrival of a B response. A subordinate that accepts
  a full write burst but never answers it does not, by itself, exhaust the
  bound.
- **W5.** A filtered write never changes the debt: its AW is not forwarded and
  its W beats are not forwarded, so neither term of W1 moves.

## X. Reset, protocol and liveness

- **X1.** `rst_ni` is active low and may be asserted asynchronously. While it
  is low, no output `valid` on any channel is asserted.
- **X2.** After reset is released the unit owes no response and holds no
  transaction; its behaviour does not depend on anything presented while reset
  was low.
- **X3.** On every channel, once `valid` is asserted it remains asserted with a
  stable payload until the corresponding `ready` is seen.
- **X4 (liveness bound).** The unit makes forward progress in both directions,
  provided the receiving side holds its `ready` asserted:
  - every response it owes for a filtered write completes within **64 cycles**
    of the `s_wlast_i` handshake of that write; and
  - a W beat it is required to consume is accepted within **64 cycles** of being
    offered, and an AW is accepted within **64 cycles** of the §W bound
    permitting it.

---

## L. Latitude — named, and deliberately unconstrained

A correct implementation may make either choice on each of these. A testbench
that requires one of them is testing an implementation, not this contract.

- **L1.** For a filtered write that owes both a B and R beats, the **order** in
  which the two appear is unconstrained. An implementation may emit the B
  first, the R beats first, or interleave them. AXI orders the B and R channels
  independently and so does this contract.
- **L2.** On a **manufactured** response, `s_rdata_o`, `s_ruser_o` and
  `s_buser_o` carry no required value. The response is an error response; its
  data is meaningless by construction.
- **L3.** Whether any `ready` output is combinational in the corresponding
  downstream `ready` or registered.
- **L4.** Whether, and for how long, a subsequent AW is stalled while a filtered
  write is being processed — subject to X4.
- **L5.** The exact latency of any manufactured response, subject to X4.

---

## What this contract does not say

It says nothing about `s_awaddr_i` — no address is privileged, and no write is
filtered on the basis of where it points. It says nothing about the value of
`m_wstrb_o` beyond P2's "unmodified". It places no bound on read traffic: the
number of outstanding reads is not limited by §W, which concerns writes only.
