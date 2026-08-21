# Task: write a SystemVerilog testbench from a specification

You are given a **specification** and a **port map**. You are not given the
design, and you will not be. Write a testbench that decides whether a design
presented to it obeys the specification.

Your testbench will be compiled against several different designs. One of them
is correct. Others are correct in every respect but one, each breaking a single
clause below. None of them can be told apart from a correct design by simply
letting the clock run and watching time increase: the differences live in
obligations that are *counted*, in a boundary that is a long way from where the
design starts, and in arithmetic that is exact to one part in sixty-five
thousand.

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
module ptp_time_base (
  input  logic        clk_i,
  input  logic        rst_i,              // SYNCHRONOUS, ACTIVE HIGH
  // ---- set the time base ----
  input  logic [95:0] set_ts96_i,
  input  logic        set_ts96_valid_i,
  input  logic [63:0] set_ts64_i,
  input  logic        set_ts64_valid_i,
  // ---- nominal period ----
  input  logic [3:0]  period_ns_i,
  input  logic [15:0] period_fns_i,
  input  logic        period_valid_i,
  // ---- counted offset adjustment ----
  input  logic [3:0]  adj_ns_i,
  input  logic [15:0] adj_fns_i,
  input  logic [15:0] adj_count_i,
  input  logic        adj_valid_i,
  output logic        adj_active_o,
  // ---- periodic drift adjustment ----
  input  logic [3:0]  drift_ns_i,
  input  logic [15:0] drift_fns_i,
  input  logic [15:0] drift_rate_i,
  input  logic        drift_valid_i,
  // ---- outputs ----
  output logic [95:0] ts96_o,
  output logic [63:0] ts64_o,
  output logic        ts_step_o,
  output logic        pps_o
);

  // no body -- see spec/ptp_time_base_spec.md for required behaviour
endmodule
```

---

## Specification

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
  `drift_rate_i` consecutive increments**.
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

## L. Latitude — named, and deliberately unconstrained

- **L1.** The number of cycles between a control input's `valid` and the first
  increment that reflects it is **unconstrained**, up to a bound of **4
  cycles**. An implementation may act on it immediately or register it first.
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

A design that never advances must produce `RESULT: FAIL`, not a hang. A hang is
not a verdict. Keep the watchdog in the provided plumbing, or write your own.

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

It drives the design and decides nothing. Paste it inside your module, above
your own code. It has been compiled and run against a correct design.

```systemverilog
// ---------------------------------------------------------------------------
// PROVIDED PLUMBING -- drives the module, checks nothing.
// ---------------------------------------------------------------------------
// This exists so you spend your effort on checking rather than on wiring. It
// has been compiled and run against a correct design.
//
// What it does: generates the clock, sequences reset, connects the design, and
// presents each control input for exactly one cycle, off the sampling edge.
//
// What it does NOT do: it keeps no model of the time base, computes no expected
// value, counts nothing, and draws no conclusion from any output. The
// arithmetic and every check are yours to write.
// ---------------------------------------------------------------------------

  // ---- clock ---------------------------------------------------------------
  logic clk = 1'b0;
  always #5 clk = ~clk;

  // A free-running cycle count, for your own bookkeeping and messages.
  int bfm_cycle = 0;
  always @(posedge clk) if (!rst) bfm_cycle <= bfm_cycle + 1;

  // ---- reset ---------------------------------------------------------------
  logic rst = 1'b1;      // SYNCHRONOUS, ACTIVE HIGH

  // Asserts reset, holds it, and releases it OFF the sampling edge, so nothing
  // you or the design samples changes in the same timestep as the change.
  task automatic bfm_reset(input int cycles = 5);
    @(negedge clk);
    rst = 1'b1;
    repeat (cycles) @(posedge clk);
    @(negedge clk);
    rst = 1'b0;
  endtask

  // ---- signals and the design under test -----------------------------------
  logic [95:0] set_ts96;   logic set_ts96_valid;
  logic [63:0] set_ts64;   logic set_ts64_valid;
  logic [3:0]  period_ns;  logic [15:0] period_fns; logic period_valid;
  logic [3:0]  adj_ns;     logic [15:0] adj_fns;    logic [15:0] adj_count;
  logic        adj_valid;  logic adj_active;
  logic [3:0]  drift_ns;   logic [15:0] drift_fns;  logic [15:0] drift_rate;
  logic        drift_valid;
  logic [95:0] ts96;       logic [63:0] ts64;
  logic        ts_step,    pps;

  ptp_time_base dut (
    .clk_i(clk), .rst_i(rst),
    .set_ts96_i(set_ts96), .set_ts96_valid_i(set_ts96_valid),
    .set_ts64_i(set_ts64), .set_ts64_valid_i(set_ts64_valid),
    .period_ns_i(period_ns), .period_fns_i(period_fns), .period_valid_i(period_valid),
    .adj_ns_i(adj_ns), .adj_fns_i(adj_fns), .adj_count_i(adj_count),
    .adj_valid_i(adj_valid), .adj_active_o(adj_active),
    .drift_ns_i(drift_ns), .drift_fns_i(drift_fns), .drift_rate_i(drift_rate),
    .drift_valid_i(drift_valid),
    .ts96_o(ts96), .ts64_o(ts64), .ts_step_o(ts_step), .pps_o(pps));

  // ---- presenting a control input ------------------------------------------
  // Each of these holds its valid across exactly ONE rising edge, and changes
  // the payload at the negative edge.
  //
  // NOTE ON WHEN TO ARM YOUR OWN COUNTERS: the contract does not fix how many
  // cycles pass between a valid and its first effect. If you reset a counter
  // AFTER calling one of these, a design that acts immediately will already
  // have started and you will lose the first cycle. Arm before you call.

  task automatic bfm_period(input logic [3:0] ns, input logic [15:0] fns);
    @(negedge clk); period_ns = ns; period_fns = fns; period_valid = 1'b1;
    @(negedge clk); period_valid = 1'b0;
  endtask

  task automatic bfm_adjust(input logic [3:0] ns, input logic [15:0] fns,
                            input logic [15:0] count);
    @(negedge clk); adj_ns = ns; adj_fns = fns; adj_count = count; adj_valid = 1'b1;
    @(negedge clk); adj_valid = 1'b0;
  endtask

  task automatic bfm_drift(input logic [3:0] ns, input logic [15:0] fns,
                           input logic [15:0] rate);
    @(negedge clk); drift_ns = ns; drift_fns = fns; drift_rate = rate; drift_valid = 1'b1;
    @(negedge clk); drift_valid = 1'b0;
  endtask

  task automatic bfm_set96(input logic [47:0] sec, input logic [29:0] ns,
                           input logic [15:0] fns);
    @(negedge clk); set_ts96 = {sec, 2'b00, ns, fns}; set_ts96_valid = 1'b1;
    @(negedge clk); set_ts96_valid = 1'b0;
  endtask

  task automatic bfm_set64(input logic [47:0] ns, input logic [15:0] fns);
    @(negedge clk); set_ts64 = {ns, fns}; set_ts64_valid = 1'b1;
    @(negedge clk); set_ts64_valid = 1'b0;
  endtask

  task automatic bfm_wait(input int cycles); repeat (cycles) @(posedge clk); endtask

  // ---- idle everything at time zero ----------------------------------------
  initial begin
    set_ts96 = '0; set_ts96_valid = 1'b0; set_ts64 = '0; set_ts64_valid = 1'b0;
    period_ns = '0; period_fns = '0; period_valid = 1'b0;
    adj_ns = '0; adj_fns = '0; adj_count = '0; adj_valid = 1'b0;
    drift_ns = '0; drift_fns = '0; drift_rate = '0; drift_valid = 1'b0;
  end

  // ---- watchdog ------------------------------------------------------------
  // Yours to keep. It fires regardless of what the design does, which is what
  // the termination requirement demands: a design that never advances must
  // produce a verdict, and a hang is not a verdict.
  initial begin
    #3_000_000;
    $display("RESULT: FAIL (watchdog: no verdict reached)");
    $finish;
  end
```

---

## What to produce

A single self-contained SystemVerilog file declaring

```systemverilog
module ptp_time_base_tb;
  // the provided plumbing, then your own stimulus and checking
endmodule
```

It must compile under Verilator 5.x with `--binary --timing`, instantiate the
design exactly once as `ptp_time_base`, and print exactly one `RESULT:` line
before finishing.

Say which clause a failure violates when you report one. A message naming the
clause is worth far more than a bare mismatch, both to you and to anyone
reading the result.
