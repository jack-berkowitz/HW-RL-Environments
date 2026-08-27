# Task: write a SystemVerilog testbench from a specification

You are given the **port map** and a **complete specification** for a hardware
module. **You will not be shown the RTL.** Write a self-checking testbench that
verifies the module against the specification.

Your testbench will be run against a known-correct implementation. It must
**pass**. It will also be run against faulty implementations, and a good
testbench catches those — but passing the correct one comes first: a testbench
that rejects correct hardware is worthless regardless of what else it catches.

It will additionally be run against implementations that are **correct but
different** — they make different choices wherever the specification is silent.
Those must pass too.

**Most of this contract cannot be checked by comparing one output against one
expected value.** The design holds a bounded table of identifier conversions,
and the clauses below are about how many entries it has, when a request must
wait for one, and when an entry becomes reusable. Expect to maintain a model of
that table.

---

## Port map

```systemverilog
module id_width_conv #(
    parameter int unsigned SLV_ID_W        = 4,
    parameter int unsigned MST_ID_W        = 2,
    parameter int unsigned ADDR_W          = 32,
    parameter int unsigned DATA_W          = 32,
    parameter int unsigned MAX_UNIQ_IDS    = 4,
    parameter int unsigned MAX_TXNS_PER_ID = 2
) (
    input  logic                    clk_i,
    input  logic                    rst_ni,

    // ---- slave (upstream) port ----
    input  logic [SLV_ID_W-1:0]        s_awid,
    input  logic [ADDR_W-1:0]        s_awaddr,
    input  logic [7:0]               s_awlen,
    input  logic                     s_awvalid,
    output logic                     s_awready,

    input  logic [DATA_W-1:0]        s_wdata,
    input  logic [DATA_W/8-1:0]      s_wstrb,
    input  logic                     s_wlast,
    input  logic                     s_wvalid,
    output logic                     s_wready,

    output logic [SLV_ID_W-1:0]        s_bid,
    output logic [1:0]               s_bresp,
    output logic                     s_bvalid,
    input  logic                     s_bready,

    input  logic [SLV_ID_W-1:0]        s_arid,
    input  logic [ADDR_W-1:0]        s_araddr,
    input  logic [7:0]               s_arlen,
    input  logic                     s_arvalid,
    output logic                     s_arready,

    output logic [SLV_ID_W-1:0]        s_rid,
    output logic [DATA_W-1:0]        s_rdata,
    output logic [1:0]               s_rresp,
    output logic                     s_rlast,
    output logic                     s_rvalid,
    input  logic                     s_rready,
    // ---- master (downstream) port ----
    output logic [MST_ID_W-1:0]        m_awid,
    output logic [ADDR_W-1:0]        m_awaddr,
    output logic [7:0]               m_awlen,
    output logic                     m_awvalid,
    input  logic                     m_awready,

    output logic [DATA_W-1:0]        m_wdata,
    output logic [DATA_W/8-1:0]      m_wstrb,
    output logic                     m_wlast,
    output logic                     m_wvalid,
    input  logic                     m_wready,

    input  logic [MST_ID_W-1:0]        m_bid,
    input  logic [1:0]               m_bresp,
    input  logic                     m_bvalid,
    output logic                     m_bready,

    output logic [MST_ID_W-1:0]        m_arid,
    output logic [ADDR_W-1:0]        m_araddr,
    output logic [7:0]               m_arlen,
    output logic                     m_arvalid,
    input  logic                     m_arready,

    input  logic [MST_ID_W-1:0]        m_rid,
    input  logic [DATA_W-1:0]        m_rdata,
    input  logic [1:0]               m_rresp,
    input  logic                     m_rlast,
    input  logic                     m_rvalid,
    output logic                     m_rready
);
```

---

## Specification

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

---

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
*Not constrained by this contract. ( — the mapping policy is deliberately free.*

**D4 — one transaction in, one transaction out.** Each accepted slave
transaction shall produce exactly one master transaction, carrying the same
`addr` and `len`, and each master response shall produce exactly one slave
response.
*Authority: task intent — this is a converter, not a splitter.*

---

## 5. Payload integrity

**E1.** `addr` and `len` on the address channels, `data`, `strb` and `last` on
the write data channel, and `data`, `resp` and `last` on the read data channel
shall be forwarded unmodified in both directions.
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

## 8. Named latitude 

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
---

## SystemVerilog constraints — read these first

Your file is compiled with **Verilator 5.x** (`--binary --timing`). These are
tool-enforced, not style advice. Every one has already caused a submitted
testbench to be rejected with none of its checking ever running:

- **Declarations come before statements.** Every variable declared in a
  `begin`/`end` block must appear before the first statement in that block.
  `int found = -1;` written after an assignment is a syntax error, not a warning.

- **Use `automatic` for anything declared inside a procedural block that you
  assign on each execution.** A declaration with an initialiser inside an
  `always` or `initial` block is **static**: `rec_t e = q.pop_front();` runs its
  initialiser once, at time zero, and never again — so `e` silently holds an
  all-zero value for the whole run and every comparison against it is
  meaningless. Write `automatic rec_t e = q.pop_front();`.

- **Do not use a reserved word as an identifier.** All of these are errors:
  `sequence`, `property`, `context`, `do`, `ref`, `expect`, `this`, `final`,
  `table`, `bind`, `cover`, `assert`, `event`, `local`, `type`, `class`,
  `virtual`, `program`, `interface`, `modport`, `extern`, `randomize`,
  `constraint`, `solve`, `before`, `alias`. If a name reads like a verification
  concept, rename it: `seq_no`, `ctx_id`, `is_final`.

- **Module instantiation belongs at module scope**, never inside an `initial` or
  `always` block.

- **Match a port's array form exactly.** Dimensions written BEFORE the name are
  *packed*; dimensions written AFTER the name are *unpacked*; they are different
  types and will not connect.

- **Never change a signal in the same timestep as the edge that samples it —
  including the falling edge.** Both of these race:

```systemverilog
  @(posedge clk); x = 1;   // races a design sampling x on the rising edge
  @(negedge clk); x = 1;   // races YOUR OWN checker if it runs on negedge
```

  The second is the one that gets missed. Drive from the edge OPPOSITE to the
  one that samples. The provided plumbing already does this.

- **Identify a result by bookkeeping, not by matching on its value.** Values
  repeat, so content matching is ambiguous and will mis-attribute.

- **`checker` / `endchecker` is not supported.** Nor are `bind`, `program`
  blocks, or SVA sequence/property declarations. Write your checks as
  ordinary `always` blocks and tasks.

- **`automatic` belongs on declarations inside a task, function or
  procedural block — never at module scope.** `automatic int x;` written
  among the module's signals is a syntax error, not a lifetime hint.

- Do not use `#` delays for anything except the clock generator and the watchdog.
- No UVM, no `randsequence`, no DPI. Queues and associative arrays are fine.

---

## Provided plumbing

It moves transactions and decides nothing. It never tracks what is outstanding,
never judges whether a request should have been accepted, and never chooses a
response order — those are the task. Paste it inside your module; it is correct
as given and has been run against a correct implementation.

```systemverilog
// ---------------------------------------------------------------------------
// PROVIDED PLUMBING -- moves transactions, checks nothing.
// ---------------------------------------------------------------------------
// This exists so you spend your effort on checking rather than on handshake
// mechanics. It has been compiled and run against a correct implementation.
//
// What it does: generates the clock, sequences reset, offers one address
// request at a time and REPORTS whether it was accepted and after how many
// cycles, and lets you present responses on the downstream port.
//
// What it does NOT do: it never decides whether a request SHOULD have been
// accepted, never tracks what is outstanding, and never chooses a response
// order. Those are the task.
// ---------------------------------------------------------------------------

  logic clk;
  initial begin clk = 1'b0; forever #5 clk = ~clk; end

  logic rst_n;
  initial rst_n = 1'b0;

  // Asserted and released away from the sampling edge.
  task automatic bfm_reset(input int cycles = 4);
    @(negedge clk);
    rst_n = 1'b0;
    repeat (cycles) @(posedge clk);
    @(negedge clk);
    rst_n = 1'b1;
  endtask

  // Offer a read address and hold it stable until accepted or the budget runs
  // out. Reports BOTH facts: whether it went, and how many cycles it waited.
  // Interpreting a refusal is yours.
  task automatic bfm_ar(input  logic [SLV_ID_W-1:0] id,
                        input  logic [ADDR_W-1:0]   addr,
                        input  logic [7:0]          len,
                        input  int                  budget,
                        output bit                  accepted,
                        output int                  waited);
    accepted = 1'b0; waited = 0;
    @(negedge clk);
    s_arid = id; s_araddr = addr; s_arlen = len; s_arvalid = 1'b1;
    while (waited < budget) begin
      @(posedge clk);
      if (s_arready) begin accepted = 1'b1; break; end
      waited++;
    end
    @(negedge clk) s_arvalid = 1'b0;
  endtask

  // The same for a write address.
  task automatic bfm_aw(input  logic [SLV_ID_W-1:0] id,
                        input  logic [ADDR_W-1:0]   addr,
                        input  logic [7:0]          len,
                        input  int                  budget,
                        output bit                  accepted,
                        output int                  waited);
    accepted = 1'b0; waited = 0;
    @(negedge clk);
    s_awid = id; s_awaddr = addr; s_awlen = len; s_awvalid = 1'b1;
    while (waited < budget) begin
      @(posedge clk);
      if (s_awready) begin accepted = 1'b1; break; end
      waited++;
    end
    @(negedge clk) s_awvalid = 1'b0;
  endtask

  // One write data beat.
  task automatic bfm_w(input logic [DATA_W-1:0]   data,
                       input logic [DATA_W/8-1:0] strb,
                       input logic                last);
    @(negedge clk);
    s_wdata = data; s_wstrb = strb; s_wlast = last; s_wvalid = 1'b1;
    forever begin @(posedge clk); if (s_wready) break; end
    @(negedge clk) s_wvalid = 1'b0;
  endtask

  // Present one downstream read response beat with the given master identifier.
  // WHICH identifier, and in what order, is yours to decide.
  task automatic bfm_rbeat(input logic [MST_ID_W-1:0] mid,
                           input logic [DATA_W-1:0]   data,
                           input logic                last);
    @(negedge clk);
    m_rid = mid; m_rdata = data; m_rlast = last; m_rresp = 2'b00; m_rvalid = 1'b1;
    forever begin @(posedge clk); if (m_rready) break; end
    @(negedge clk) m_rvalid = 1'b0;
  endtask

  // Present one downstream write response.
  task automatic bfm_bbeat(input logic [MST_ID_W-1:0] mid);
    @(negedge clk);
    m_bid = mid; m_bresp = 2'b00; m_bvalid = 1'b1;
    forever begin @(posedge clk); if (m_bready) break; end
    @(negedge clk) m_bvalid = 1'b0;
  endtask

  // Watchdog. Fires regardless of what the design does -- one of the faulty
  // implementations refuses a request it should accept.
  initial begin
    #4_000_000;
    $display("RESULT: FAIL (watchdog: no forward progress)");
    $finish;
  end
```

---

## What to produce

A single SystemVerilog file containing one module `id_width_conv_tb` that
instantiates `id_width_conv` and self-checks.

- Configure it with `SLV_ID_W = 4`, `MST_ID_W = 2`, `ADDR_W = 32`,
  `DATA_W = 32`, `MAX_UNIQ_IDS = 4`, `MAX_TXNS_PER_ID = 2`.
- Your testbench drives the slave port **and** acts as the downstream slave on
  the master port — you decide when and in what order to return responses.
- **It must terminate on its own, unconditionally.** A watchdog is provided;
  keep it. One of the faulty implementations refuses a request it should accept,
  and a testbench that waits for that acceptance with no timeout runs forever.
- Print exactly one final line: `RESULT: PASS` or `RESULT: FAIL`.
- Print a diagnostic line per failure naming the requirement (`A1`…`A5`,
  `B1`…`B3`, `C1`, `C2`, `D1`…`D4`, `E1`, `F1`).
- Compiled with Verilator 5.x. Queues and associative arrays are fine.

Ground every check in a numbered requirement. If a behaviour is not specified
above, do not check it — the implementation is free to choose, and a check on an
unspecified behaviour will reject correct hardware.
