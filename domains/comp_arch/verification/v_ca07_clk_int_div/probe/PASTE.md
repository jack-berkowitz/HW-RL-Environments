# Write a testbench for `clk_ratio_div`

You are given a port map and a specification. **No implementation is shipped.**
Write a SystemVerilog testbench that decides whether an implementation of this
port map obeys the specification.

Your testbench will be run against several implementations. Some are correct.
Some are correct but differ wherever the specification is **silent** — those must
PASS. Some carry a single planted defect that violates a stated clause — those
must FAIL. A testbench that rejects a correct implementation is not scored,
however many defects it catches.

The unit is a runtime-configurable **integer clock divider**. Two things about
it are unlike the usual:

**The thing under test is a clock.** Correctness is about the intervals between
its edges — the period, the split within a period, and how long it is gated
across a reconfiguration. A testbench that samples `clk_o` as a value will not
see most of the contract.

**Do not clock your testbench from `clk_o`.** A faulty implementation can stop it
entirely, and a testbench clocked by it stops too — which is not a detection.
Drive and time everything from `clk_i`.

**Intervals have two endpoints, and one of them is easy to get wrong.** The
gating bound in G1 is measured **from the cycle `div_ready_o` rises**, not from
the cycle you asserted `div_valid_i`. The handshake wait in between is not
gating, and folding it in makes a conforming unit look like it breaks the bound.
This is not a trick: it is stated in G1 and repeated here because it is the
mistake most likely to make you reject correct hardware.

**G1 and L2 are a pair, and they are easy to conflate.** G1 is an EXACT upper
bound and it binds — a unit outside it is faulty. L2 says how long gating
*actually* lasts below that bound is free — a unit that resumes sooner is
correct, and requiring a particular duration rejects it. Check the bound; do not
check the duration. Two of the implementations you will be run against differ
from each other on exactly this: one sits at the bound, another resumes in
two-thirds of it, and both are conforming.

## Port map

```systemverilog
// ---------------------------------------------------------------------------
// v_ca07 -- PORT MAP. This is the whole of the design that ships.
//
// A runtime-configurable integer clock divider. Your testbench drives clk_i,
// rst_ni, en_i, div_i and div_valid_i, and observes clk_o, div_ready_o and
// cycl_count_o.
//
// DRIVE AND TIME EVERYTHING FROM clk_i. clk_o is the thing under test: a
// testbench clocked by it stops when a faulty design stops it, and a testbench
// that SAMPLES it rather than measuring its edges will not see most of the
// contract.
//
// The body is empty ON PURPOSE. No implementation is shipped.
// ---------------------------------------------------------------------------
module clk_ratio_div (
  input  logic       clk_i,
  input  logic       rst_ni,
  input  logic       en_i,
  input  logic       test_mode_en_i,
  input  logic [3:0] div_i,
  input  logic       div_valid_i,
  output logic       div_ready_o,
  output logic       clk_o,
  output logic [3:0] cycl_count_o
);
  // No implementation is shipped. See spec/clk_ratio_div_spec.md.
endmodule
```

## Specification

A runtime-configurable integer clock divider. It takes an input clock and
produces an output clock at a programmable ratio, and it changes ratio without
emitting a malformed pulse.

**Correctness here is about INTERVALS BETWEEN EDGES, not sampled values.** A
testbench that samples `clk_o` as a signal will not see most of what follows.
Every clause below is stated in whole `clk_i` cycles so it can be decided by
counting edges.

Every number given was measured on a conforming implementation. Where a bound
was chosen rather than derived it is named as such.

---

## 0. Scored configuration — pinned

| | |
|---|---|
| `div_i` width | 4 bits, so divisors **0 to 15** |
| divisor after reset | **0** |
| `rst_ni` | **asynchronous**, **active low** |
| output while `rst_ni` is low | gated |

`test_mode_en_i` is pinned low and no clause depends on it.

---

## P. The output clock

- **P1 — period.** For `div_i` of 2 or more, one `clk_o` period is exactly
  `div_i` `clk_i` cycles.
- **P2 — the duty split, which is NOT always 50%.** In each period `clk_o` is
  high for `floor(div_i / 2)` `clk_i` cycles and low for `ceil(div_i / 2)`.

  It is exactly 50% at **even** divisors only. At odd divisors the **low** phase
  is the longer one, by exactly one `clk_i` cycle.
  *Measured: div 3 gives high 1 / low 2, div 5 gives 2 / 3, div 7 gives 3 / 4.
  This is arithmetically forced — an odd number of input cycles cannot be split
  evenly — so an implementation claiming 50% everywhere is not merely different,
  it is impossible.*
- **P3 — 0 and 1 are a DEGENERATE PAIR, and the distinction is UNSCORED.** Both
  mean pass-through: `clk_o` has the same period as `clk_i`, one input cycle.
  *Measured for both.*

  **What this means for scoring, stated so it is not left to be inferred.**
  Pass-through itself IS scored — a unit that gives period 2 at `div_i = 1`
  violates this clause and will be caught. What is **not** scored is any
  difference **between** 0 and 1: they are observationally identical, so no
  testbench can distinguish them and no fault will ever be keyed on that
  distinction. You are not asked to tell them apart and you are not penalised for
  treating them as one value.

  Both remain in the scored configuration. Removing one would hide a real
  degenerate case that an implementation can get wrong in the same way for both.

---

## H. Reconfiguration, and its handshake

- **H1 — it is a real handshake.** A new divisor is offered with `div_valid_i`
  and taken with `div_ready_o`. `div_ready_o` is **not free-running**: it is low
  while `div_valid_i` is low.
  *Measured: held low across 20 cycles with `div_valid_i` deasserted. A testbench
  that treats it as always-ready is describing a different unit.*
- **H2 — an obligation on YOU, the source.** While `div_valid_i` is high, hold
  `div_i` stable until `div_ready_o` rises. The contract says nothing about what
  a unit does with a value that changes underneath an offer, and this document
  will not be extended to cover it.
- **H3 — a SAME-VALUE request is a no-op, and it is granted immediately.** If the
  offered `div_i` equals the divisor already in force, `div_ready_o` rises in the
  **same cycle** and the output is **not gated at all**.
  *Measured: 0 cycles to grant, and the output runs at full rate straight
  through. A real change takes longer and gates. One value changes the verdict.*
- **H4 — a request during a transition is DEFERRED, not refused.** A second
  change offered while a first is still gating is held off and then accepted; it
  is not rejected and it does not need re-offering.
  *Measured: granted 8 cycles later, where an uncontended change is granted in
  1 to 4.*

---

## G. Gating across a change

- **G1 — the bound, and where it is measured FROM.** On a change to a different
  divisor, `clk_o` is gated and then resumes. Counting from the cycle
  `div_ready_o` rises — **not** from the cycle you asserted `div_valid_i` — the
  gap to the first rising edge of the new clock is at most

  > **3 × (the new period in `clk_i` cycles)**

  where the period of divisor 0 or 1 is 1.

  **The origin is load-bearing.** Measured from the assertion of `div_valid_i`
  the bound does not hold, because the handshake wait — 1 to 4 cycles depending
  on phase — is not gating.
  *Verified across all 72 ordered pairs of divisors in 0..8: zero violations, and
  the bound is **exactly attained** on all 14 transitions to divisor 0 or 1,
  where the gap is 3 and the limit is 3. A unit that gates one cycle longer on
  those is outside the contract.*
- **G2 — gated means idle low.** While gated, `clk_o` stays low. It does not stop
  high and it does not emit a partial pulse.

---

## E. Enable

- **E1.** With `en_i` low the output is stopped: no rising edge occurs.
  *Measured: zero rising edges in 100 cycles.*
- **E2.** With `en_i` returned high the output resumes at the configured divisor.
- **E3.** Disabling does not truncate a pulse. `clk_o` is not observed high after
  `en_i` falls.
  *Measured at input-edge resolution: low on all 40 input edges after `en_i`
  fell.*

---

## C. The cycle counter

- **C1.** `cycl_count_o` advances once per `clk_i` cycle and wraps at the
  configured divisor, taking the values `0` to `div_i - 1`.
  *Measured: `1 2 3 0 1 2 3 0` at div 4; `2 0 1 2 0 1` at div 3.*
- **C2.** In pass-through — `div_i` of 0 or 1 — `cycl_count_o` is constantly `0`.
  *Measured.*
- **C3.** After a change is accepted, `cycl_count_o` counts over the **new**
  divisor's range immediately, without a partial cycle of the old one.
  *Measured across a 4 to 8 change: `0 1 2 3 4 5 6 7 0 1 …`.*

---

## R. Reset

- **R1.** `rst_ni` is **asynchronous** and **active low**. While it is low no
  rising edge appears on `clk_o`.
- **R2 — reset restores the DEFAULT divisor, not the last configured one.** After
  release the unit is in pass-through, whatever it was set to before.
  *Measured: configured to 4, reset, and the output returned at period 1.*

---

## X. What is excluded from measurement

- **X1.** Nothing is required of any output while `rst_ni` is low. This applies
  from the first rising clock edge onward; before any edge the registers hold no
  defined value.
- **X2.** The **sub-cycle** duty of `clk_o` in pass-through. There `clk_o`
  follows `clk_i`, so its high and low phases are the input clock's own and are
  not a property of this unit. Measure pass-through by period, not by duty.
- **X3.** Anything following a violation of H2 — a `div_i` that changes while
  `div_valid_i` is high and before `div_ready_o` rises.
- **X4.** `test_mode_en_i`, which is pinned low.

---

## L. Latitude — named, and deliberately unconstrained

- **L1 — the phase of `clk_o` relative to `clk_i`.** Which input edge a period
  begins on is free. Only the period and the split within it are fixed.
- **L2 — how long gating actually lasts**, below G1's bound. A unit that resumes
  sooner is conforming. Do not require a particular duration.
- **L3 — when `div_ready_o` rises** for a change to a different value. H3 fixes
  it only for the same-value case.
- **L4 — how long H4's deferral lasts.** That a second request is eventually
  accepted is fixed; when is not.
- **L5 — `cycl_count_o` while the output is gated or disabled.** C1 fixes its
  behaviour while the clock is running.

These five are the whole of the latitude in this contract. Everything else above
is exact.

---

## Termination — a requirement on your testbench

Your testbench shall terminate on its own, unconditionally, under every
implementation it is run against, and shall include a watchdog that reports
failure and finishes after a generous time limit regardless of what the design
does.

**A faulty implementation here can stop the output clock entirely.** A testbench
that waits for an edge on `clk_o` with no timeout runs forever — and a testbench
clocked BY `clk_o` stops with it. Drive and time everything from `clk_i`.

---

## What this contract does not say

It says nothing about divisors above 15, which the port cannot express. It says
nothing about changing `en_i` and `div_i` in the same cycle. It does not say
whether the unit is glitch-free by construction or by gating, only what the
output does.

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