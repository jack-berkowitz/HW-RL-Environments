# Task: write a SystemVerilog testbench from a specification

You are given a **specification** and a **port map**. You are not given the
design, and you will not be. Write a testbench that decides whether a design
presented to it obeys the specification.

Your testbench will be compiled against several different designs. One of them
is correct. Others are correct in every respect but one, each breaking a single
clause below. None of them can be told apart from a correct design by pushing
one beat through an idle crossbar: the differences live in what happens when
several inputs want the same output at once, when an output stops accepting,
and in whether a beat that has been offered can still be taken back.

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
module route_xbar #(
  parameter int unsigned N_IN    = 4,
  parameter int unsigned N_OUT   = 4,
  parameter int unsigned DATA_W  = 32,
  parameter int unsigned SEL_W   = 2,
  parameter int unsigned IDX_W   = 2
) (
  input  logic                       clk_i,
  input  logic                       rst_ni,
  // ---- input side ----
  input  logic [N_IN*DATA_W-1:0]     in_data_i,
  input  logic [N_IN*SEL_W-1:0]      in_sel_i,
  input  logic [N_IN-1:0]            in_valid_i,
  output logic [N_IN-1:0]            in_ready_o,
  // ---- output side ----
  output logic [N_OUT*DATA_W-1:0]    out_data_o,
  output logic [N_OUT*IDX_W-1:0]     out_idx_o,
  output logic [N_OUT-1:0]           out_valid_o,
  input  logic [N_OUT-1:0]           out_ready_i
);

  // no body -- see spec/route_xbar_spec.md for required behaviour
endmodule
```

---

## Specification

A fully connected crossbar for a valid/ready stream. Each input carries a
payload and a selector naming the output it is bound for; each output reports
which input its current beat came from. Several inputs may be bound for the
same output at once, and the crossbar decides between them.

Clauses marked **latitude** are choices the implementation is free to make;
your testbench must not require either answer.

---

## 0. Configuration — pinned

| parameter | value |
|---|---|
| `N_IN` | 4 |
| `N_OUT` | 4 |
| `DATA_W` | 32 |
| `SEL_W` | 2 |
| `IDX_W` | 2 |

`rst_ni` is **asynchronous**, **active low**. Per-port fields are packed
low-index first: input `k`'s payload is `in_data_i[k*DATA_W +: DATA_W]`, its
selector is `in_sel_i[k*SEL_W +: SEL_W]`, and output `j`'s source index is
`out_idx_o[j*IDX_W +: IDX_W]`.

## H. The handshake

- **H1.** A beat moves on input `k` in any cycle where `in_valid_i[k]` and
  `in_ready_o[k]` are both high at the rising edge. A beat moves on output `j`
  in any cycle where `out_valid_o[j]` and `out_ready_i[j]` are both high.
- **H2.** This is an obligation on **you**, the source: once `in_valid_i[k]` is
  asserted, `in_valid_i[k]`, `in_data_i[k]` and `in_sel_i[k]` must all be held
  unchanged until that beat has moved. A testbench that withdraws an offer is
  driving something this contract does not describe.
- **H3.** `in_ready_o[k]` **may depend on** `in_valid_i[k]`. It carries no
  meaning in a cycle where input `k` is not offering, and you must not read one
  into it.

## R. Routing

- **R1.** A beat accepted on input `k` while `in_sel_i[k]` is `j` is delivered
  on output `j`, and on no other output.
- **R2.** The payload is delivered **unmodified**.
- **R3.** On the cycle a beat moves on output `j`, `out_idx_o[j]` names the
  input that beat was accepted from.
- **R4.** Every accepted beat is delivered **exactly once**. None is lost and
  none is delivered twice.
- **R5.** Beats accepted from the **same input** and bound for the **same
  output** are delivered in the order they were accepted.

- **R6 — every delivered beat was accepted.** A beat appearing on an output
  shall be one that was accepted on some input. The unit delivers beats; it
  does not originate them.

  *This is not implied by R1 or R4. R1 governs WHICH output an accepted beat
  reaches and R4 governs HOW MANY TIMES it is delivered; both presuppose that
  the beat was accepted. A beat that entered the unit at no input satisfies
  both vacuously — there is no binding to be wrong about, and no first delivery
  to count a second against.*

  *Authority: task intent. The interface has no source of payload other than
  the input side, so a beat with no acceptance is not an under-specified case
  but an impossible one, and a design that produces it is wrong for a reason
  the other clauses cannot name.*

Nothing is promised about the relative order of beats from *different* inputs.

## A. Arbitration

- **A1.** In any cycle at most one input's beat moves on a given output.
- **A2 (the fairness bound).** Let *S* be a set of inputs that are all
  continuously offering beats bound for output `j`. Then **every member of *S*
  is served at least once in every |*S*| consecutive transfers on output `j`.**
  This is a bound, not a promise that each is served eventually.
- **A3.** Once `out_valid_o[j]` is asserted it stays asserted, and
  `out_data_o[j]` and `out_idx_o[j]` stay unchanged, until `out_ready_i[j]` is
  seen. The crossbar may not withdraw or re-aim a beat it has already offered.

## I. Independence

- **I1.** An output that is not ready does not prevent beats moving on any
  other output.
- **I2.** An input whose bound output is not ready does not prevent any other
  input from being accepted. There is **no head-of-line blocking across
  inputs**.

## X. Reset and liveness

- **X1.** `rst_ni` is asynchronous and active low. While it is low the crossbar
  accepts nothing and completes nothing.

  Reset governs what the unit **originates**, not what it merely passes
  through. A purely combinational path from an input to an output is not
  gated by reset, so driving that input while reset is asserted will drive
  the output too. To observe reset behaviour, hold the inputs quiet.
  **This applies from the first rising clock edge onward.** Before any clock
  edge has occurred the design's registers hold no defined value, so its
  outputs are unknown rather than low. Sampling them at time zero, before
  the first edge, tests nothing this contract promises.
- **X2.** After reset is released the crossbar holds no beat and owes no
  delivery.
- **X3 (liveness bound).** A beat offered on input `k` whose bound output is
  continuously ready, and which is competing with at most the other `N_IN-1`
  inputs, is accepted within **32** cycles.

---

## L. Latitude — named, and deliberately unconstrained

- **L1.** The **latency** from a beat being accepted on an input to its
  appearing on an output is unconstrained, subject to X3.
- **L2.** The **starting rotation** of the arbiter after reset — which member
  of a tied set is served first — is unconstrained. A2 fixes the window, not
  the phase.
- **L3.** Whether an output's `valid` and payload are combinational in the
  inputs or come from a register.

These three are the whole of the latitude in this contract.

---

## What this contract does not say

It says nothing about the relative order of beats from different inputs to the
same output beyond A2, and nothing about the order in which distinct outputs
deliver. It places no requirement on `out_data_o[j]` or `out_idx_o[j]` in a
cycle where `out_valid_o[j]` is low.

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

A design that never accepts anything must produce `RESULT: FAIL`, not a hang. A
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
// keeps each input offering the beat you have put in front of it -- holding the
// offer unchanged until it is taken, which is what clause H2 requires of a
// source, and starting the next one the moment it is.
//
// What it does NOT do: it chooses no payloads, keeps no model of what went
// where, counts nothing, and draws no conclusion from any signal. Routing,
// ordering, delivery, fairness and every check are yours to write.
//
// TWO THINGS WORTH KNOWING, both of which cost real time to find:
//
//   * The driver below is an ALWAYS BLOCK, not a loop you pump from your
//     stimulus. A pumped loop only services the edges it happens to be waiting
//     on, and every edge you wait on elsewhere -- to change a ready line, to
//     bring another input in -- is an edge where a beat can be accepted
//     unnoticed. Keep presenting a beat that has already been taken and the
//     design takes it again, which looks exactly like the design delivering it
//     twice.
//
//   * Sample a handshake AT the rising edge. `in_ready_o` read at the falling
//     edge is not necessarily the value the design used.
// ---------------------------------------------------------------------------

  localparam int N_IN = 4, N_OUT = 4, DW = 32, SW = 2, IW = 2;

  // ---- clock ---------------------------------------------------------------
  logic clk = 1'b0;
  always #5 clk = ~clk;

  int bfm_cycle = 0;
  always @(posedge clk) if (rst_n) bfm_cycle <= bfm_cycle + 1;

  // ---- reset ---------------------------------------------------------------
  logic rst_n = 1'b0;        // ASYNCHRONOUS, ACTIVE LOW

  task automatic bfm_reset(input int cycles = 5);
    @(negedge clk);
    rst_n = 1'b0;
    repeat (cycles) @(posedge clk);
    @(negedge clk);
    rst_n = 1'b1;
  endtask

  // ---- signals and the design under test -----------------------------------
  logic [N_IN*DW-1:0]  in_data;
  logic [N_IN*SW-1:0]  in_sel;
  logic [N_IN-1:0]     in_valid, in_ready;
  logic [N_OUT*DW-1:0] out_data;
  logic [N_OUT*IW-1:0] out_idx;
  logic [N_OUT-1:0]    out_valid, out_ready;

  route_xbar #(.N_IN(N_IN), .N_OUT(N_OUT), .DATA_W(DW), .SEL_W(SW), .IDX_W(IW)) dut (
    .clk_i(clk), .rst_ni(rst_n),
    .in_data_i(in_data), .in_sel_i(in_sel), .in_valid_i(in_valid), .in_ready_o(in_ready),
    .out_data_o(out_data), .out_idx_o(out_idx), .out_valid_o(out_valid),
    .out_ready_i(out_ready));

  // Convenience slicers.
  function automatic logic [DW-1:0] bfm_odata(input int j); return out_data[j*DW +: DW]; endfunction
  function automatic logic [IW-1:0] bfm_oidx (input int j); return out_idx [j*IW +: IW]; endfunction

  // ---- what you drive ------------------------------------------------------
  // Set bfm_offer[k] to keep input k offering. Put the payload and selector for
  // the NEXT beat in bfm_next_data[k] / bfm_next_sel[k]; the driver picks them
  // up when it starts a beat, and never mid-offer.
  logic [N_IN-1:0]  bfm_offer;
  logic [DW-1:0]    bfm_next_data [N_IN];
  logic [SW-1:0]    bfm_next_sel  [N_IN];

  // Registered handshake: bfm_accepted[k] is high for the cycle following the
  // rising edge on which input k's beat was taken.
  logic [N_IN-1:0]  bfm_accepted;
  always @(posedge clk) bfm_accepted <= (rst_n ? (in_valid & in_ready) : '0);

  always @(negedge clk) begin
    if (!rst_n) begin
      in_valid = '0;
    end else begin
      for (int k = 0; k < N_IN; k++) begin
        if (bfm_accepted[k]) in_valid[k] = 1'b0;          // that beat is gone
        if (!in_valid[k] && bfm_offer[k]) begin           // start the next one
          in_data[k*DW +: DW] = bfm_next_data[k];
          in_sel [k*SW +: SW] = bfm_next_sel[k];
          in_valid[k]         = 1'b1;
        end
      end
    end
  end

  task automatic bfm_ready(input logic [N_OUT-1:0] v); out_ready = v; endtask

  // ---- idle everything at time zero ----------------------------------------
  initial begin
    in_data = '0; in_sel = '0; in_valid = '0; out_ready = '1; bfm_offer = '0;
    for (int k = 0; k < N_IN; k++) begin bfm_next_data[k] = '0; bfm_next_sel[k] = '0; end
  end

  // ---- watchdog ------------------------------------------------------------
  // Yours to keep. It fires regardless of what the design does: one of the
  // faulty designs never accepts anything at all, and without this your
  // testbench hangs instead of reporting. A hang is not a verdict.
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
module route_xbar_tb;
  // the provided plumbing, then your own stimulus and checking
endmodule
```

It must compile under Verilator 5.x with `--binary --timing`, instantiate the
design exactly once as `route_xbar` with the parameters shown in the plumbing,
and print exactly one `RESULT:` line before finishing.

Say which clause a failure violates when you report one. A message naming the
clause is worth far more than a bare mismatch, both to you and to anyone
reading the result.
