# Task: write a SystemVerilog testbench from a specification

You are given a **specification** and a **port map**. You are not given the
design, and you will not be. Write a testbench that decides whether a design
presented to it obeys the specification.

Your testbench will be compiled against several different designs. One of them
is correct. Others are correct in every respect but one, each breaking a single
clause below. Some of those differ from a correct design only under traffic
that has to be built up deliberately -- a bound that is only reached by holding
data back, a burst longer than one beat, a second transaction that has to
follow a first. A testbench that exercises only the straightforward case will
accept them all.

Your testbench must **accept** every design that obeys the specification and
**reject** every design that does not. Both halves matter: one that rejects
everything is worth nothing, and neither is one that accepts everything.

A design that obeys the specification may still differ from another that also
obeys it. The clauses marked **latitude** name exactly where. Requiring one of
those choices is a defect in your testbench, and one of the designs you will be
run against deliberately takes the opposite choice on every one of them.

---

## Port map

```systemverilog
module atop_filter #(
  parameter int unsigned ID_W   = 4,
  parameter int unsigned ADDR_W = 32,
  parameter int unsigned DATA_W = 32,
  parameter int unsigned USER_W = 1
) (
  input  logic                clk_i,
  input  logic                rst_ni,
  // ---- slave port (upstream) ----
  input  logic [ID_W-1:0]     s_awid_i,
  input  logic [ADDR_W-1:0]   s_awaddr_i,
  input  logic [7:0]          s_awlen_i,
  input  logic [2:0]          s_awsize_i,
  input  logic [1:0]          s_awburst_i,
  input  logic                s_awlock_i,
  input  logic [3:0]          s_awcache_i,
  input  logic [2:0]          s_awprot_i,
  input  logic [3:0]          s_awqos_i,
  input  logic [3:0]          s_awregion_i,
  input  logic [5:0]          s_awatop_i,
  input  logic [USER_W-1:0]   s_awuser_i,
  input  logic                s_awvalid_i,
  output logic                s_awready_o,
  input  logic [DATA_W-1:0]   s_wdata_i,
  input  logic [DATA_W/8-1:0] s_wstrb_i,
  input  logic                s_wlast_i,
  input  logic [USER_W-1:0]   s_wuser_i,
  input  logic                s_wvalid_i,
  output logic                s_wready_o,
  output logic [ID_W-1:0]     s_bid_o,
  output logic [1:0]          s_bresp_o,
  output logic [USER_W-1:0]   s_buser_o,
  output logic                s_bvalid_o,
  input  logic                s_bready_i,
  input  logic [ID_W-1:0]     s_arid_i,
  input  logic [ADDR_W-1:0]   s_araddr_i,
  input  logic [7:0]          s_arlen_i,
  input  logic [2:0]          s_arsize_i,
  input  logic [1:0]          s_arburst_i,
  input  logic                s_arlock_i,
  input  logic [3:0]          s_arcache_i,
  input  logic [2:0]          s_arprot_i,
  input  logic [3:0]          s_arqos_i,
  input  logic [3:0]          s_arregion_i,
  input  logic [USER_W-1:0]   s_aruser_i,
  input  logic                s_arvalid_i,
  output logic                s_arready_o,
  output logic [ID_W-1:0]     s_rid_o,
  output logic [DATA_W-1:0]   s_rdata_o,
  output logic [1:0]          s_rresp_o,
  output logic                s_rlast_o,
  output logic [USER_W-1:0]   s_ruser_o,
  output logic                s_rvalid_o,
  input  logic                s_rready_i,
  // ---- master port (downstream) ----
  output logic [ID_W-1:0]     m_awid_o,
  output logic [ADDR_W-1:0]   m_awaddr_o,
  output logic [7:0]          m_awlen_o,
  output logic [2:0]          m_awsize_o,
  output logic [1:0]          m_awburst_o,
  output logic                m_awlock_o,
  output logic [3:0]          m_awcache_o,
  output logic [2:0]          m_awprot_o,
  output logic [3:0]          m_awqos_o,
  output logic [3:0]          m_awregion_o,
  output logic [5:0]          m_awatop_o,
  output logic [USER_W-1:0]   m_awuser_o,
  output logic                m_awvalid_o,
  input  logic                m_awready_i,
  output logic [DATA_W-1:0]   m_wdata_o,
  output logic [DATA_W/8-1:0] m_wstrb_o,
  output logic                m_wlast_o,
  output logic [USER_W-1:0]   m_wuser_o,
  output logic                m_wvalid_o,
  input  logic                m_wready_i,
  input  logic [ID_W-1:0]     m_bid_i,
  input  logic [1:0]          m_bresp_i,
  input  logic [USER_W-1:0]   m_buser_i,
  input  logic                m_bvalid_i,
  output logic                m_bready_o,
  output logic [ID_W-1:0]     m_arid_o,
  output logic [ADDR_W-1:0]   m_araddr_o,
  output logic [7:0]          m_arlen_o,
  output logic [2:0]          m_arsize_o,
  output logic [1:0]          m_arburst_o,
  output logic                m_arlock_o,
  output logic [3:0]          m_arcache_o,
  output logic [2:0]          m_arprot_o,
  output logic [3:0]          m_arqos_o,
  output logic [3:0]          m_arregion_o,
  output logic [USER_W-1:0]   m_aruser_o,
  output logic                m_arvalid_o,
  input  logic                m_arready_i,
  input  logic [ID_W-1:0]     m_rid_i,
  input  logic [DATA_W-1:0]   m_rdata_i,
  input  logic [1:0]          m_rresp_i,
  input  logic                m_rlast_i,
  input  logic [USER_W-1:0]   m_ruser_i,
  input  logic                m_rvalid_i,
  output logic                m_rready_o
);

  // no body -- see spec/atop_filter_spec.md for required behaviour
endmodule
```

---

## Specification

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


---

## Termination — a requirement on your testbench

Your testbench must **always** reach a verdict and stop. Print exactly one of

```
RESULT: PASS
```

when the design obeys every clause, or

```
RESULT: FAIL
```

when it does not, then call `$finish`. You may print anything you like
alongside; only the `RESULT:` line is read.

A design that never makes progress must produce `RESULT: FAIL`, not a hang. A
hang is not a verdict. Keep the watchdog in the provided plumbing, or write
your own.

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

- Do not use `#` delays for anything except the clock generator and the watchdog.
- No UVM, no `randsequence`, no DPI. Queues and associative arrays are fine.

---

## Provided plumbing

It moves transactions and decides nothing. Paste it inside your module, above
your own code. It has been compiled and run against a correct design.

```systemverilog
// ---------------------------------------------------------------------------
// PROVIDED PLUMBING -- moves transactions, checks nothing.
// ---------------------------------------------------------------------------
// This exists so you spend your effort on checking rather than on AXI
// handshake mechanics. It has been compiled and run against a correct design.
//
// What it does: generates the clock, sequences reset, connects the design,
// offers one beat at a time on a chosen channel and returns once that beat has
// transferred, and plays the part of the subordinate on the master port --
// accepting requests and answering them.
//
// What it does NOT do: it has no notion of which writes are special, keeps no
// model of what the design owes anyone, counts nothing, and draws no conclusion
// from any signal. Every check is yours to write.
// ---------------------------------------------------------------------------

  // ---- clock ---------------------------------------------------------------
  logic clk = 1'b0;
  always #5 clk = ~clk;

  // A free-running cycle count, for your own bookkeeping and messages.
  int bfm_cycle = 0;
  always @(posedge clk) if (rst_n) bfm_cycle <= bfm_cycle + 1;

  // ---- reset ---------------------------------------------------------------
  logic rst_n = 1'b0;      // ACTIVE LOW

  // Asserts reset, holds it, and releases it OFF the sampling edge, so nothing
  // you or the design samples changes in the same timestep as the change.
  task automatic bfm_reset(input int cycles = 5);
    @(negedge clk);
    rst_n = 1'b0;
    repeat (cycles) @(posedge clk);
    @(negedge clk);
    rst_n = 1'b1;
  endtask

  // ---- the signals, and the design under test ------------------------------
  logic [3:0]     s_awid;
  logic [31:0]   s_awaddr;
  logic [7:0]          s_awlen;
  logic [2:0]          s_awsize;
  logic [1:0]          s_awburst;
  logic                s_awlock;
  logic [3:0]          s_awcache;
  logic [2:0]          s_awprot;
  logic [3:0]          s_awqos;
  logic [3:0]          s_awregion;
  logic [5:0]          s_awatop;
  logic    s_awuser;
  logic                s_awvalid;
  logic                s_awready;
  logic [31:0]   s_wdata;
  logic [3:0] s_wstrb;
  logic                s_wlast;
  logic    s_wuser;
  logic                s_wvalid;
  logic                s_wready;
  logic [3:0]     s_bid;
  logic [1:0]          s_bresp;
  logic    s_buser;
  logic                s_bvalid;
  logic                s_bready;
  logic [3:0]     s_arid;
  logic [31:0]   s_araddr;
  logic [7:0]          s_arlen;
  logic [2:0]          s_arsize;
  logic [1:0]          s_arburst;
  logic                s_arlock;
  logic [3:0]          s_arcache;
  logic [2:0]          s_arprot;
  logic [3:0]          s_arqos;
  logic [3:0]          s_arregion;
  logic    s_aruser;
  logic                s_arvalid;
  logic                s_arready;
  logic [3:0]     s_rid;
  logic [31:0]   s_rdata;
  logic [1:0]          s_rresp;
  logic                s_rlast;
  logic    s_ruser;
  logic                s_rvalid;
  logic                s_rready;
  logic [3:0]     m_awid;
  logic [31:0]   m_awaddr;
  logic [7:0]          m_awlen;
  logic [2:0]          m_awsize;
  logic [1:0]          m_awburst;
  logic                m_awlock;
  logic [3:0]          m_awcache;
  logic [2:0]          m_awprot;
  logic [3:0]          m_awqos;
  logic [3:0]          m_awregion;
  logic [5:0]          m_awatop;
  logic    m_awuser;
  logic                m_awvalid;
  logic                m_awready;
  logic [31:0]   m_wdata;
  logic [3:0] m_wstrb;
  logic                m_wlast;
  logic    m_wuser;
  logic                m_wvalid;
  logic                m_wready;
  logic [3:0]     m_bid;
  logic [1:0]          m_bresp;
  logic    m_buser;
  logic                m_bvalid;
  logic                m_bready;
  logic [3:0]     m_arid;
  logic [31:0]   m_araddr;
  logic [7:0]          m_arlen;
  logic [2:0]          m_arsize;
  logic [1:0]          m_arburst;
  logic                m_arlock;
  logic [3:0]          m_arcache;
  logic [2:0]          m_arprot;
  logic [3:0]          m_arqos;
  logic [3:0]          m_arregion;
  logic    m_aruser;
  logic                m_arvalid;
  logic                m_arready;
  logic [3:0]     m_rid;
  logic [31:0]   m_rdata;
  logic [1:0]          m_rresp;
  logic                m_rlast;
  logic    m_ruser;
  logic                m_rvalid;
  logic                m_rready;

  atop_filter #(.ID_W(4), .ADDR_W(32), .DATA_W(32), .USER_W(1)) dut (
    .clk_i(clk),
    .rst_ni(rst_n),
    .s_awid_i(s_awid),
    .s_awaddr_i(s_awaddr),
    .s_awlen_i(s_awlen),
    .s_awsize_i(s_awsize),
    .s_awburst_i(s_awburst),
    .s_awlock_i(s_awlock),
    .s_awcache_i(s_awcache),
    .s_awprot_i(s_awprot),
    .s_awqos_i(s_awqos),
    .s_awregion_i(s_awregion),
    .s_awatop_i(s_awatop),
    .s_awuser_i(s_awuser),
    .s_awvalid_i(s_awvalid),
    .s_awready_o(s_awready),
    .s_wdata_i(s_wdata),
    .s_wstrb_i(s_wstrb),
    .s_wlast_i(s_wlast),
    .s_wuser_i(s_wuser),
    .s_wvalid_i(s_wvalid),
    .s_wready_o(s_wready),
    .s_bid_o(s_bid),
    .s_bresp_o(s_bresp),
    .s_buser_o(s_buser),
    .s_bvalid_o(s_bvalid),
    .s_bready_i(s_bready),
    .s_arid_i(s_arid),
    .s_araddr_i(s_araddr),
    .s_arlen_i(s_arlen),
    .s_arsize_i(s_arsize),
    .s_arburst_i(s_arburst),
    .s_arlock_i(s_arlock),
    .s_arcache_i(s_arcache),
    .s_arprot_i(s_arprot),
    .s_arqos_i(s_arqos),
    .s_arregion_i(s_arregion),
    .s_aruser_i(s_aruser),
    .s_arvalid_i(s_arvalid),
    .s_arready_o(s_arready),
    .s_rid_o(s_rid),
    .s_rdata_o(s_rdata),
    .s_rresp_o(s_rresp),
    .s_rlast_o(s_rlast),
    .s_ruser_o(s_ruser),
    .s_rvalid_o(s_rvalid),
    .s_rready_i(s_rready),
    .m_awid_o(m_awid),
    .m_awaddr_o(m_awaddr),
    .m_awlen_o(m_awlen),
    .m_awsize_o(m_awsize),
    .m_awburst_o(m_awburst),
    .m_awlock_o(m_awlock),
    .m_awcache_o(m_awcache),
    .m_awprot_o(m_awprot),
    .m_awqos_o(m_awqos),
    .m_awregion_o(m_awregion),
    .m_awatop_o(m_awatop),
    .m_awuser_o(m_awuser),
    .m_awvalid_o(m_awvalid),
    .m_awready_i(m_awready),
    .m_wdata_o(m_wdata),
    .m_wstrb_o(m_wstrb),
    .m_wlast_o(m_wlast),
    .m_wuser_o(m_wuser),
    .m_wvalid_o(m_wvalid),
    .m_wready_i(m_wready),
    .m_bid_i(m_bid),
    .m_bresp_i(m_bresp),
    .m_buser_i(m_buser),
    .m_bvalid_i(m_bvalid),
    .m_bready_o(m_bready),
    .m_arid_o(m_arid),
    .m_araddr_o(m_araddr),
    .m_arlen_o(m_arlen),
    .m_arsize_o(m_arsize),
    .m_arburst_o(m_arburst),
    .m_arlock_o(m_arlock),
    .m_arcache_o(m_arcache),
    .m_arprot_o(m_arprot),
    .m_arqos_o(m_arqos),
    .m_arregion_o(m_arregion),
    .m_aruser_o(m_aruser),
    .m_arvalid_o(m_arvalid),
    .m_arready_i(m_arready),
    .m_rid_i(m_rid),
    .m_rdata_i(m_rdata),
    .m_rresp_i(m_rresp),
    .m_rlast_i(m_rlast),
    .m_ruser_i(m_ruser),
    .m_rvalid_i(m_rvalid),
    .m_rready_o(m_rready));

  // ---- upstream: offering requests to the design ---------------------------
  // Offers ONE write address and returns once it has transferred. Every field
  // is presented at the negative edge and held stable until the transfer, which
  // is what clause X3 requires of a source.
  //
  // `accepted` is returned low if `timeout` cycles pass without a transfer;
  // the offer is then withdrawn. Pass a large timeout when you simply want to
  // wait, and a small one when the point of the test is whether it is taken.
  task automatic bfm_aw(input logic [3:0] id, input logic [31:0] addr,
                        input logic [7:0] len, input logic [5:0] atop,
                        input int timeout, output bit accepted);
    int t;
    @(negedge clk);
    s_awid = id; s_awaddr = addr; s_awlen = len; s_awatop = atop;
    s_awsize = 3'd2; s_awburst = 2'd1; s_awlock = 1'b0; s_awcache = 4'd0;
    s_awprot = 3'd0; s_awqos = 4'd0; s_awregion = 4'd0; s_awuser = 1'b0;
    s_awvalid = 1'b1;
    accepted = 1'b0;
    for (t = 0; t < timeout; t++) begin
      @(posedge clk);
      if (s_awready) begin accepted = 1'b1; break; end
    end
    @(negedge clk) s_awvalid = 1'b0;
  endtask

  // Offers ONE write data beat and returns once it has transferred.
  task automatic bfm_w(input logic [31:0] data, input logic [3:0] strb,
                       input bit last, input int timeout, output bit accepted);
    int t;
    @(negedge clk);
    s_wdata = data; s_wstrb = strb; s_wlast = last; s_wuser = 1'b0;
    s_wvalid = 1'b1;
    accepted = 1'b0;
    for (t = 0; t < timeout; t++) begin
      @(posedge clk);
      if (s_wready) begin accepted = 1'b1; break; end
    end
    @(negedge clk) s_wvalid = 1'b0;
  endtask

  // Offers ONE read address and returns once it has transferred.
  task automatic bfm_ar(input logic [3:0] id, input logic [31:0] addr,
                        input logic [7:0] len, input int timeout, output bit accepted);
    int t;
    @(negedge clk);
    s_arid = id; s_araddr = addr; s_arlen = len;
    s_arsize = 3'd2; s_arburst = 2'd1; s_arlock = 1'b0; s_arcache = 4'd0;
    s_arprot = 3'd0; s_arqos = 4'd0; s_arregion = 4'd0; s_aruser = 1'b0;
    s_arvalid = 1'b1;
    accepted = 1'b0;
    for (t = 0; t < timeout; t++) begin
      @(posedge clk);
      if (s_arready) begin accepted = 1'b1; break; end
    end
    @(negedge clk) s_arvalid = 1'b0;
  endtask

  // Your readiness to take responses. Changed at the negative edge, never at
  // the edge the design samples them on.
  task automatic bfm_b_ready(input bit v); @(negedge clk); s_bready = v; endtask
  task automatic bfm_r_ready(input bit v); @(negedge clk); s_rready = v; endtask

  // ---- downstream: this plumbing is the SUBORDINATE ------------------------
  // It accepts every request the design forwards and answers it. It is a model
  // of the thing on the other side, not of the design: it does not know or care
  // which requests the design chose to forward, and it checks nothing.
  //
  // bfm_dn_b_lag sets how many cycles the subordinate waits, after taking a
  // write address, before it answers that write. Zero means it answers as
  // early as it can. Set it to whatever your test needs.
  int bfm_b_lag = 0;
  task automatic bfm_dn_b_lag(input int cycles); bfm_b_lag = cycles; endtask

  int bfm_bq_id [$], bfm_bq_t [$], bfm_rq_id [$], bfm_rq_n [$];
  assign m_awready = 1'b1;
  assign m_wready  = 1'b1;
  assign m_arready = 1'b1;
  always @(posedge clk) begin
    if (!rst_n) begin
      bfm_bq_id.delete(); bfm_bq_t.delete(); bfm_rq_id.delete(); bfm_rq_n.delete();
    end else begin
      if (m_awvalid && m_awready) begin
        bfm_bq_id.push_back(int'(m_awid)); bfm_bq_t.push_back(bfm_cycle + bfm_b_lag);
      end
      if (m_arvalid && m_arready) begin
        bfm_rq_id.push_back(int'(m_arid)); bfm_rq_n.push_back(int'(m_arlen) + 1);
      end
      if (m_bvalid && m_bready) begin
        void'(bfm_bq_id.pop_front()); void'(bfm_bq_t.pop_front());
      end
      if (m_rvalid && m_rready) begin
        if (bfm_rq_n[0] <= 1) begin void'(bfm_rq_id.pop_front()); void'(bfm_rq_n.pop_front()); end
        else bfm_rq_n[0] = bfm_rq_n[0] - 1;
      end
    end
  end
  always_comb begin
    m_bvalid = (bfm_bq_id.size() > 0) && (bfm_cycle >= bfm_bq_t[0]);
    m_bid    = 4'(bfm_bq_id.size() ? bfm_bq_id[0] : 0);
    m_bresp  = 2'b00;                 // the subordinate always succeeds
    m_buser  = 1'b0;
    m_rvalid = (bfm_rq_id.size() > 0);
    m_rid    = 4'(bfm_rq_id.size() ? bfm_rq_id[0] : 0);
    m_rdata  = 32'hFEED_0000 + 32'(bfm_rq_n.size() ? bfm_rq_n[0] : 0);
    m_rresp  = 2'b00;
    m_ruser  = 1'b0;
    m_rlast  = (bfm_rq_id.size() > 0) && (bfm_rq_n[0] <= 1);
  end

  // ---- idle the upstream request signals at time zero ----------------------
  initial begin
    s_awvalid = 1'b0; s_wvalid = 1'b0; s_arvalid = 1'b0;
    s_bready  = 1'b1; s_rready = 1'b1;
    s_awid = '0; s_awaddr = '0; s_awlen = '0; s_awsize = 3'd2; s_awburst = 2'd1;
    s_awlock = 1'b0; s_awcache = '0; s_awprot = '0; s_awqos = '0; s_awregion = '0;
    s_awatop = '0; s_awuser = 1'b0;
    s_wdata = '0; s_wstrb = 4'hF; s_wlast = 1'b0; s_wuser = 1'b0;
    s_arid = '0; s_araddr = '0; s_arlen = '0; s_arsize = 3'd2; s_arburst = 2'd1;
    s_arlock = 1'b0; s_arcache = '0; s_arprot = '0; s_arqos = '0; s_arregion = '0;
    s_aruser = 1'b0;
  end

  // ---- watchdog ------------------------------------------------------------
  // Yours to keep. It fires regardless of what the design does, which is what
  // the termination requirement demands: some faulty designs never make
  // progress at all, and without this your testbench hangs instead of
  // reporting a verdict. A hang is not a verdict.
  initial begin
    #4_000_000;
    $display("RESULT: FAIL (watchdog: no forward progress)");
    $finish;
  end
```

---

## What to produce

A single self-contained SystemVerilog file declaring

```systemverilog
module atop_filter_tb;
  // the provided plumbing, then your own stimulus and checking
endmodule
```

It must compile under Verilator 5.x with `--binary --timing`, instantiate the
design exactly once as `atop_filter` with the parameters shown in the plumbing,
and print exactly one `RESULT:` line before finishing.

Say which clause a failure violates when you report one. A message naming the
clause is worth far more than a bare mismatch, both to you and to anyone
reading the result.
