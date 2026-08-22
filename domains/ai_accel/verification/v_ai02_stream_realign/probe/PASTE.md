# Task: write a SystemVerilog testbench from a specification

You are given a **specification** and a **port map**. You are not given the
design, and you will not be. Write a testbench that decides whether a design
presented to it obeys the specification.

Your testbench will be compiled against several different designs. One of them
is correct. Others are correct in every respect but one, each breaking a single
clause below. None can be told apart from a correct design by pushing one beat
through it: the differences live in how bytes are carried across beat
boundaries, in which beat of a line is treated specially, and in what the
strobe is allowed to mean.

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
module stream_realign (
  input  logic        clk_i,
  input  logic        rst_ni,
  input  logic        clear_i,
  // ---- control ----
  input  logic        realign_i,
  input  logic        first_i,
  input  logic        last_i,
  input  logic [3:0]  strb_i,
  // ---- input stream ----
  input  logic [31:0] push_data_i,
  input  logic [3:0]  push_strb_i,
  input  logic        push_valid_i,
  output logic        push_ready_o,
  // ---- output stream ----
  output logic [31:0] pop_data_o,
  output logic [3:0]  pop_strb_o,
  output logic        pop_valid_o,
  input  logic        pop_ready_i
);

  // no body -- see spec/stream_realign_spec.md for required behaviour
endmodule
```

---

## Specification

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

- **P1.** With `realign_i` low the unit is transparent **on the data path**:
  every input beat appears on the output with `pop_data_o` equal to
  `push_data_i`, and the two handshakes are the same handshake — `pop_valid_o`
  follows `push_valid_i` and `push_ready_o` follows `pop_ready_i`.
- **P2.** `pop_strb_o` while `realign_i` is low is **not specified** — see L3.
  Transparency here covers the data path and the handshake only. Do **not**
  require the output strobe to equal `push_strb_i`, and do not require it to be
  all ones either.

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
- **L3.** `pop_strb_o` on an output beat produced while `realign_i` is **low**.
  Conforming implementations differ here and both readings are defensible: the
  unit this task is anchored on drives the output strobe to all ones in every
  mode, from a single unconditional assignment, while an independently written
  implementation of the same contract passes `push_strb_i` through. A testbench
  must accept **either**. R3 still binds while `realign_i` is high, where the
  behaviour is not in doubt.

These three are the whole of the latitude in this contract.

---

## What this contract does not say

It says nothing about what `push_strb_i` means while realigning — R3 fixes the
output strobe regardless. It places no requirement on the unit's behaviour if a
line's first beat never arrives, nor on `strb_i` in any cycle other than a
line's first beat, which R4 makes the only one that matters.


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

A design that never accepts a beat must produce `RESULT: FAIL`, not a hang. A
hang is not a verdict. Keep the watchdog in the provided plumbing, or write your
own.

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

It moves beats and decides nothing. Paste it inside your module, above your own
code. It has been compiled and run against a correct design.

```systemverilog
// ---------------------------------------------------------------------------
// PROVIDED PLUMBING -- moves beats, checks nothing.
// ---------------------------------------------------------------------------
// This exists so you spend your effort on checking rather than on handshake
// mechanics. It has been compiled and run against a correct design.
//
// What it does: generates the clock, sequences reset, connects the design, and
// presents queued beats one at a time -- holding each offer unchanged until it
// is taken, which is what clause H2 requires of a source.
//
// What it does NOT do: it computes no expected value, models no rotation, keeps
// no byte stream, and draws no conclusion from any signal.
//
// TWO THINGS WORTH KNOWING, both of which cost real time to find:
//
//   * The driver is an ALWAYS BLOCK, not a loop you pump from your stimulus.
//     A pumped loop only services the edges it happens to be waiting on, and
//     every edge you wait on elsewhere is one where a beat can be accepted
//     unnoticed -- after which you re-present a beat the design already took.
//
//   * Sample a handshake AT the rising edge. `push_ready_o` read at the falling
//     edge is not necessarily the value the design used.
// ---------------------------------------------------------------------------

  // ---- clock ---------------------------------------------------------------
  logic clk = 1'b0;
  always #5 clk = ~clk;

  int bfm_cycle = 0;
  always @(posedge clk) if (rst_n) bfm_cycle <= bfm_cycle + 1;

  // ---- reset ---------------------------------------------------------------
  logic rst_n = 1'b0;          // ASYNCHRONOUS, ACTIVE LOW
  logic clr   = 1'b0;          // synchronous, active high

  task automatic bfm_reset(input int cycles = 5);
    @(negedge clk);
    rst_n = 1'b0;
    repeat (cycles) @(posedge clk);
    @(negedge clk);
    rst_n = 1'b1;
  endtask

  task automatic bfm_clear();
    @(negedge clk) clr = 1'b1;
    @(negedge clk) clr = 1'b0;
    repeat (2) @(posedge clk);
  endtask

  // ---- signals and the design under test ------------------------------------
  logic        ra = 1'b0, fst = 1'b0, lst = 1'b0;
  logic [3:0]  strb = 4'hF;
  logic [31:0] pdata = '0;
  logic [3:0]  pstrb = 4'hF;
  logic        pvalid = 1'b0, pready;
  logic [31:0] qdata;
  logic [3:0]  qstrb;
  logic        qvalid;
  logic        qready = 1'b1;

  stream_realign dut (
    .clk_i(clk), .rst_ni(rst_n), .clear_i(clr), .realign_i(ra), .first_i(fst),
    .last_i(lst), .strb_i(strb), .push_data_i(pdata), .push_strb_i(pstrb),
    .push_valid_i(pvalid), .push_ready_o(pready), .pop_data_o(qdata),
    .pop_strb_o(qstrb), .pop_valid_o(qvalid), .pop_ready_i(qready));

  // ---- what you queue --------------------------------------------------------
  typedef struct packed {
    logic [31:0] data;   // push_data_i
    logic [3:0]  dstrb;  // push_strb_i
    logic        first;  // first_i
    logic        last;   // last_i
    logic        realign;// realign_i
    logic [3:0]  lstrb;  // strb_i presented with this beat
  } bfm_beat_t;

  bfm_beat_t bfm_q [$];

  task automatic bfm_send(input logic [31:0] data, input bit first, input bit last,
                          input bit do_realign, input logic [3:0] lstrb,
                          input logic [3:0] dstrb = 4'hF);
    bfm_beat_t b;
    b.data = data; b.dstrb = dstrb; b.first = first; b.last = last;
    b.realign = do_realign; b.lstrb = lstrb;
    bfm_q.push_back(b);
  endtask

  task automatic bfm_ready(input bit v); qready = v; endtask

  // Waits until everything queued has been offered and taken.
  task automatic bfm_idle(input int max_cycles = 400);
    for (int t = 0; t < max_cycles; t++) begin
      @(posedge clk);
      if (bfm_q.size() == 0 && !pvalid) break;
    end
    repeat (6) @(posedge clk);
  endtask

  // ---- the driver ------------------------------------------------------------
  logic bfm_hs;
  always @(posedge clk) bfm_hs <= (rst_n && !clr) ? (pvalid & pready) : 1'b0;

  always @(negedge clk) begin
    if (!rst_n) begin
      pvalid = 1'b0;
    end else begin
      if (bfm_hs && bfm_q.size() > 0) begin void'(bfm_q.pop_front()); pvalid = 1'b0; end
      if (!pvalid && bfm_q.size() > 0) begin
        pdata = bfm_q[0].data;  pstrb = bfm_q[0].dstrb; fst = bfm_q[0].first;
        lst   = bfm_q[0].last;  strb  = bfm_q[0].lstrb; ra  = bfm_q[0].realign;
        pvalid = 1'b1;
      end
    end
  end

  // ---- watchdog --------------------------------------------------------------
  // Yours to keep. It fires regardless of what the design does: one of the
  // faulty designs never accepts anything, and without this your testbench
  // hangs instead of reporting. A hang is not a verdict.
  initial begin
    #2_000_000;
    $display("RESULT: FAIL (watchdog: no verdict reached)");
    $finish;
  end
```

---

## What to produce

A single self-contained SystemVerilog file declaring

```systemverilog
module stream_realign_tb;
  // the provided plumbing, then your own stimulus and checking
endmodule
```

It must compile under Verilator 5.x with `--binary --timing`, instantiate the
design exactly once as `stream_realign`, and print exactly one `RESULT:` line
before finishing.

Say which clause a failure violates when you report one. A message naming the
clause is worth far more than a bare mismatch, both to you and to anyone reading
the result.
