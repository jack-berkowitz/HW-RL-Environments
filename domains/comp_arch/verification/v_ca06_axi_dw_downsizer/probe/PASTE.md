# Write a testbench for `dw_downsizer`

You are given a port map and a specification. **No implementation is shipped.**
Write a SystemVerilog testbench that decides whether an implementation of this
port map obeys the specification.

Your testbench will be run against several implementations. Some are correct.
Some are correct but differ from one another wherever the specification is
**silent** — those must PASS. Some carry a single planted defect that violates a
stated clause — those must FAIL. A testbench that rejects a correct
implementation is not scored, however many defects it catches.

The unit is an AXI4 **data-width downsizer**: a wide upstream port, a narrow
downstream port, and a re-segmentation between them. Your testbench drives the
upstream port as a master and answers the downstream port as a slave. Both sides
are yours to drive.

## Port map

```systemverilog
// ---------------------------------------------------------------------------
// v_ca06 -- PORT MAP. This is the whole of the design that ships.
//
// An AXI4 data-width downsizer: a WIDE upstream (slave) port and a NARROW
// downstream (master) port. Your testbench instantiates this module, drives the
// upstream port as a master, and answers the downstream port as a slave.
//
// The body is empty ON PURPOSE. No implementation is shipped, and the
// specification is the only description of behaviour you are given.
//
// FIELDS THAT ARE NOT PORTS. lock, cache, prot, qos, region, atop and user are
// pinned inside the design and are not exposed. Nothing in the contract reads
// them. size and burst ARE exposed on both address channels, and the contract
// turns on both.
// ---------------------------------------------------------------------------
module dw_downsizer #(
    parameter int unsigned ADDR_W     = 32,
    parameter int unsigned ID_W       = 4,
    parameter int unsigned SLV_DATA_W = 64,   // upstream, wide
    parameter int unsigned MST_DATA_W = 16,   // downstream, narrow
    parameter int unsigned MAX_READS  = 4
) (
    input  logic clk_i,
    input  logic rst_ni,

    // ---- slave (upstream, WIDE) port ----
    input  logic [ID_W-1:0]          s_awid,
    input  logic [ADDR_W-1:0]        s_awaddr,
    input  logic [7:0]               s_awlen,
    input  logic [2:0]               s_awsize,
    input  logic [1:0]               s_awburst,
    input  logic                     s_awvalid,
    output logic                     s_awready,
    input  logic [SLV_DATA_W-1:0]    s_wdata,
    input  logic [SLV_DATA_W/8-1:0]  s_wstrb,
    input  logic                     s_wlast,
    input  logic                     s_wvalid,
    output logic                     s_wready,
    output logic [ID_W-1:0]          s_bid,
    output logic [1:0]               s_bresp,
    output logic                     s_bvalid,
    input  logic                     s_bready,
    input  logic [ID_W-1:0]          s_arid,
    input  logic [ADDR_W-1:0]        s_araddr,
    input  logic [7:0]               s_arlen,
    input  logic [2:0]               s_arsize,
    input  logic [1:0]               s_arburst,
    input  logic                     s_arvalid,
    output logic                     s_arready,
    output logic [ID_W-1:0]          s_rid,
    output logic [SLV_DATA_W-1:0]    s_rdata,
    output logic [1:0]               s_rresp,
    output logic                     s_rlast,
    output logic                     s_rvalid,
    input  logic                     s_rready,

    // ---- master (downstream, NARROW) port ----
    output logic [ID_W-1:0]          m_awid,
    output logic [ADDR_W-1:0]        m_awaddr,
    output logic [7:0]               m_awlen,
    output logic [2:0]               m_awsize,
    output logic [1:0]               m_awburst,
    output logic                     m_awvalid,
    input  logic                     m_awready,
    output logic [MST_DATA_W-1:0]    m_wdata,
    output logic [MST_DATA_W/8-1:0]  m_wstrb,
    output logic                     m_wlast,
    output logic                     m_wvalid,
    input  logic                     m_wready,
    input  logic [ID_W-1:0]          m_bid,
    input  logic [1:0]               m_bresp,
    input  logic                     m_bvalid,
    output logic                     m_bready,
    output logic [ID_W-1:0]          m_arid,
    output logic [ADDR_W-1:0]        m_araddr,
    output logic [7:0]               m_arlen,
    output logic [2:0]               m_arsize,
    output logic [1:0]               m_arburst,
    output logic                     m_arvalid,
    input  logic                     m_arready,
    input  logic [ID_W-1:0]          m_rid,
    input  logic [MST_DATA_W-1:0]    m_rdata,
    input  logic [1:0]               m_rresp,
    input  logic                     m_rlast,
    input  logic                     m_rvalid,
    output logic                     m_rready
);
  // No implementation is shipped. See spec/dw_downsizer_spec.md.
endmodule
```

## Specification

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
- **D6 — downstream error precedence.** If any downstream `R` beat of a
  transaction carries an error response, the upstream response for that
  transaction carries an error too. A transaction whose downstream beats are all
  `OKAY` is answered `OKAY`.

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
- **E6 — error precedence.** If the downstream `B` carries an error, the upstream
  `B` carries an error. Otherwise it carries `OKAY`.

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