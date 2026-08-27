# `id_width_conv` — specification

An AXI4 identifier-width converter. It forwards read and write transactions from
a **slave port** carrying `SLV_ID_W`-bit identifiers to a **master port**
carrying narrower `MST_ID_W`-bit identifiers, and restores the original
identifier on every response.

Because the master port has fewer identifiers than the slave port, the design
holds a bounded table of the conversions currently in use. **Most of this
contract is about that table**: how many entries it has, when a request must
wait for one, and when an entry becomes reusable.

Ships with the port map (`id_width_conv_iface.sv`) and this document.
**No RTL is shipped.**

Every clause is numbered and individually citable. Every contract term names its
source of authority; §8 names what is deliberately left open.

---

## 0. Parameters

| name | meaning |
|---|---|
| `SLV_ID_W` | identifier width on the slave port |
| `MST_ID_W` | identifier width on the master port; smaller than `SLV_ID_W` |
| `ADDR_W`, `DATA_W` | address and data widths, shared by both ports |
| `MAX_UNIQ_IDS` | the number of table entries — see A2 |
| `MAX_TXNS_PER_ID` | see A5 |

*Authority: names and widths are fixed by the shipped port map.*

---

## 1. Transactions and the table

**A1 — outstanding.** A read transaction is **outstanding** from the rising edge
on which `s_arvalid && s_arready` until the rising edge on which its final read
response beat transfers (`s_rvalid && s_rready && s_rlast`). A write transaction
is outstanding from `s_awvalid && s_awready` until `s_bvalid && s_bready` for
that transaction. Reads and writes are counted **separately**.
*Authority: AMBA AXI4 — a transaction begins at its address handshake and ends
at its last response transfer. The separate counting is task intent, stated
because the contract below is otherwise ambiguous for a design serving both.*

**A2 — table size.** At most **`MAX_UNIQ_IDS` distinct slave identifiers** may
be outstanding on the read side at any time, and at most `MAX_UNIQ_IDS` on the
write side.
*Authority: task intent — this bound is the property under test.*

  *Exceeding the bound forces a master-identifier collision, so a violation is **reported under D1**. A submission that checks
  D1 is credited with this clause; recorded here so the grouping is visible
  rather than discovered from a failure message.*
**A3 — the boundary, and it is the point of this design.** When
`MAX_UNIQ_IDS` distinct slave identifiers are already outstanding, an address
request carrying an identifier **not among them** shall **not** be accepted —
`s_arready` (respectively `s_awready`) shall stay low for that request — until
one of the outstanding identifiers retires completely.

A request carrying an identifier **already outstanding** is not blocked by this
clause.
*Authority: task intent. Stated as an exact boundary rather than as "the design
may stall" so that a testbench can check it: at `MAX_UNIQ_IDS - 1` distinct
identifiers a new one must be accepted, at `MAX_UNIQ_IDS` it must not.*

**A4 — retirement frees an entry, and frees it within a bounded time.** An
identifier ceases to occupy a table entry on the rising edge at which its last
outstanding transaction completes, as A1 defines completion. A request carrying
a new identifier, offered continuously from that edge and blocked by no other
clause, shall be accepted **within 2 cycles of it**.

*Authority: task intent, with the 2-cycle window a recorded design decision of
this task. Measured on a correct implementation: acceptance happens on the
retiring edge itself — zero cycles — so the window leaves room for a design that
needs a cycle of internal arbitration while remaining a bound a testbench can
check. It is stated as a bound rather than as "promptly" because an unbounded
promise cannot be falsified in a finite run, and because the cycle of retirement
is exactly where a design can be wrong while being right everywhere else.*

**A5 — depth per identifier.** At most **`MAX_TXNS_PER_ID`** transactions with
the same slave identifier may be outstanding at once, per direction. A further
request with that identifier shall not be accepted until one of them completes.
*Authority: task intent.*

---

## 2. Ordering

**B1 — per-identifier ordering.** For a given slave identifier, responses shall
return in the order in which their address requests were accepted.
*Authority: AMBA AXI4 — transactions with the same ID must complete in order.*

  *An out-of-order response carries the data of another transaction, so a violation is **reported under E1**. A submission that checks
  E1 is credited with this clause; recorded here so the grouping is visible
  rather than discovered from a failure message.*
**B2 — no ordering between identifiers.** **NOT SPECIFIED — A TESTBENCH THAT CHECKS THIS REJECTS CORRECT HARDWARE.**
The relative order of responses carrying **different** slave identifiers is
free.
*Authority: AMBA AXI4 — the protocol permits completion out of order between
different IDs, and this design forwards that freedom.*

**B3 — write data ordering.** Write data beats shall be forwarded on the master
port in the order their address requests were accepted on the slave port, and
the beats of one write shall not be interleaved with another's.
*Authority: AMBA AXI4 — write data interleaving was removed in AXI4, so beats
follow address order.*

  *Misordered or interleaved write beats carry the wrong payload, so a violation is **reported under E1**. A submission that checks
  E1 is credited with this clause; recorded here so the grouping is visible
  rather than discovered from a failure message.*
---

## 3. Identifier restoration

**C1.** Every response beat presented on the slave port shall carry the slave
identifier of the transaction that produced it.
*Authority: AMBA AXI4 — a response carries the identifier of its transaction.*

  *A wrongly restored identifier appears as a beat for an id with none outstanding, so a violation is **reported under C2**. A submission that checks
  C2 is credited with this clause; recorded here so the grouping is visible
  rather than discovered from a failure message.*
**C2.** Every response beat presented on the slave port shall correspond to a
transaction that is outstanding at that moment. A response for which no
transaction is outstanding is a violation.
*Authority: follows from A1 and C1.*

---

## 4. The master port

**D1 — distinct while co-outstanding.** Two transactions with **different** slave
identifiers that are outstanding at the same time, in the same direction, shall
carry **different** master identifiers.
*Authority: task intent — it is what makes A2's bound necessary, and it is
observable at the master port.*

**D2 — reuse is permitted only after retirement.** A master identifier that has
been used for a transaction may be used again for a **different** slave
identifier only once the first has retired under A4.
*Authority: follows from D1. Called out separately because "reused one cycle too
early" is a defect a design can carry while being correct in every other
respect.*

**D3 — which master identifier is chosen is unconstrained.** Any assignment
satisfying D1 and D2 is correct. A testbench shall not require a particular
value, nor a particular allocation order.
*Authority: rule 12 — the mapping policy is deliberately free.*

**D4 — one transaction in, one transaction out.** Each accepted slave
transaction shall produce exactly one master transaction, carrying the same
`addr` and `len`, and each master response shall produce exactly one slave
response.
*Authority: task intent — this is a converter, not a splitter.*

**D5 — an offered beat is not withdrawn.** On every channel of **both** ports
that the design drives — `s_bvalid`, `s_rvalid`, `m_awvalid`, `m_wvalid`,
`m_arvalid` — once a `valid` is asserted it shall remain asserted, with its
payload unchanged, until the corresponding `ready` is seen.

`valid` **shall not depend combinationally on `ready`.** A design that asserts
`valid` only in cycles where `ready` happens to be high satisfies the letter of
the sentence above and defeats it: nothing is ever withdrawn because nothing is
ever offered into a stall.

This binds the **design's outputs only**. It says nothing about the offers a
testbench makes to the design: A3 and A4 permit a request not to be accepted,
so a testbench that gives up on an offer after a bounded wait is doing what
those clauses require of it, not violating this one.

*Authority: AMBA AXI4 — `VALID` must remain asserted until the handshake
completes, and the source may not wait for `READY` before asserting it. The
anchor asserts the same property internally, on the same event:
`dut/rr_arb_tree.sv:391` — "It is disallowed to deassert unserved request
signals when LockIn is enabled."*

---

## 5. Payload integrity

**E1.** `addr` and `len` on the address channels, `data`, `strb` and `last` on
the write data channel, `data`, `resp` and `last` on the read data channel, and
`resp` on the write response channel shall be forwarded unmodified in both
directions.
*Authority: AMBA AXI4 — a converter alters identifiers and nothing else.*

---

## 6. Reset

**F1.** `rst_ni` is **synchronous and active low**. While it is low the design
shall be returned to an idle state: no request is accepted and no response is
presented. After release the table is empty, so `MAX_UNIQ_IDS` distinct
identifiers may be accepted again, and **no transaction outstanding before reset
shall produce a response afterwards.**
*Authority: polarity and synchronicity fixed by the port map's `rst_ni`; the
discard requirement is task intent, stated because AXI4 does not settle whether
transactions survive a reset.*

---

## 7. Termination — a requirement on the submitted testbench

**G1.** The submitted testbench shall terminate on its own, unconditionally,
under every implementation it is run against, and shall include a watchdog that
reports failure and finishes after a generous time limit regardless of what the
design does.

**One of the faulty implementations refuses a request it should accept.** A
testbench that waits for that acceptance with no timeout runs forever: it has
not detected the fault, it has stopped, and it blocks everything queued behind
it.
*Authority: stated task requirement.*

---

## 8. Named latitude (rule 12)

Not constrained by this contract, and not to be checked:

1. **Which master identifier is used** for any transaction (D3), and the order
   in which free entries are allocated.
2. **Latency** — the number of cycles between a slave request being accepted and
   the corresponding master request appearing, and between a master response and
   the slave response, is unconstrained and may vary.
3. **Promptness of `s_awready` / `s_arready`** where neither A3 nor A4 speaks.
   Ready may be low for reasons of internal arbitration; a testbench shall not
   require it high merely because a table entry is free. A4's 2-cycle window is
   the one place this contract does bound it.
4. **Relative order of responses carrying different identifiers** (B2).
5. **The values on any output while its `valid` is low.** Unconstrained.
6. **Whether reads and writes share table entries or hold separate tables**,
   beyond A1's requirement that they are counted separately.
7. **Internal structure** — how the table is stored or searched.

---

## 9. Scored configuration (rule 18)

| parameter | value |
|---|---|
| `SLV_ID_W` | **4** |
| `MST_ID_W` | **2** |
| `ADDR_W`, `DATA_W` | **32**, **32** |
| `MAX_UNIQ_IDS` | **4** |
| `MAX_TXNS_PER_ID` | **2** |

**Rationale.** `SLV_ID_W = 4` against `MST_ID_W = 2` makes the conversion
genuinely lossy — sixteen slave identifiers onto four master ones — so the table
is the whole difficulty rather than an incidental detail. `MAX_UNIQ_IDS = 4`
puts A3's boundary within a handful of transactions of the start of any test, so
a testbench can reach it deliberately rather than by accident, and
`MAX_TXNS_PER_ID = 2` does the same for A5. Both bounds are small on purpose:
the interesting behaviour is at the boundary, and a large table hides it behind
traffic volume.

*Authority: rule 18 — one scored configuration, named in the spec, with its
rationale recorded beside it.*
