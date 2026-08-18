<!-- ===================================================================
     DELETE THIS HEADER BEFORE PASTING.

     Self-contained task file for v_nw03. Everything below the marker is
     paste-ready: port map, specification, output requirements. No RTL, no
     repo paths, no reference to this project.

     Note before sending: this ships a port map and prose only. The design
     it is derived from is MIT-licensed and nothing derived from it is
     included here, so the exposure is lighter than v_ca05's -- the same
     standing caveat applies, fine internally, licence review before any
     external release.

     Scoring, once the reply comes back, is a THREE-WAY split per failure:
       (a) driver bug         -- e.g. stimulus changed in the same timestep
                                 as the sampling edge, which makes a correct
                                 design look inert or deadlocked
       (b) unpromised reliance -- checks something §7 leaves open; compare
                                 against conformant/README.md
       (c) genuine spec gap   -- the specification really does not say
     Only (c) is a specification defect. Do not collapse these into a
     pass/fail number; the split is the entire result.

     Watch for one thing in particular. S6 ("ready is not a grant") is this
     task's load-bearing clause, the analogue of v_ca05's R4. A submission
     that treats a beat accepted at an input as a beat forwarded to the
     output will fail the golden, and that failure is (a) or (b), never (c).
     =================================================================== -->

============================ PASTE BELOW THIS LINE ============================

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

---

## Port map

```systemverilog
module frame_arb_mux #(
    parameter int S_COUNT    = 4,
    parameter int DATA_WIDTH = 32,
    parameter int USER_WIDTH = 1
) (
    input  logic                                     clk_i,
    input  logic                                     rst_i,

    input  logic [S_COUNT-1:0][DATA_WIDTH-1:0]       s_tdata_i,
    input  logic [S_COUNT-1:0][(DATA_WIDTH/8)-1:0]   s_tkeep_i,
    input  logic [S_COUNT-1:0]                       s_tvalid_i,
    output logic [S_COUNT-1:0]                       s_tready_o,
    input  logic [S_COUNT-1:0]                       s_tlast_i,
    input  logic [S_COUNT-1:0][USER_WIDTH-1:0]       s_tuser_i,

    output logic [DATA_WIDTH-1:0]                    m_tdata_o,
    output logic [(DATA_WIDTH/8)-1:0]                m_tkeep_o,
    output logic                                     m_tvalid_o,
    input  logic                                     m_tready_i,
    output logic                                     m_tlast_o,
    output logic [USER_WIDTH-1:0]                    m_tuser_o
);
```

---

## Specification

`S_COUNT` independent input streams carry framed data. One output stream carries
the same frames, one whole frame at a time. Signal semantics are AMBA
AXI4-Stream.

### Beats and frames

**S1 — beat.** A beat transfers on input `k` on a rising clock edge where
`s_tvalid_i[k] && s_tready_o[k]`. A beat transfers on the output on a rising
clock edge where `m_tvalid_o && m_tready_i`.

**S2 — frame.** A frame is a sequence of one or more beats on one input, ending
with the beat on which `s_tlast_i[k]` is high. **A frame may be a single beat**,
carrying `s_tlast_i[k]` high on its first and only beat.

### What the output carries

**S3 — frame atomicity.** Once a beat of some frame from input `k` has
transferred on the output, every subsequent output beat shall carry the next
beat of **that same frame**, until and including the beat on which `m_tlast_o`
is high. No beat originating from any other input may transfer on the output
between the first and last beat of a frame.

**S4 — payload integrity and order.** Each output beat shall carry the `tdata`,
`tkeep` and `tuser` of exactly one input beat, **unmodified and complete across
the full width of each field**, and the beats of an input shall appear on the
output in the order in which they transferred on that input. `m_tlast_o` shall
be high on exactly those output beats carrying an input beat that had
`s_tlast_i[k]` high.

**S5 — no loss, no duplication.** For every frame whose final beat — the one
carrying `s_tlast_i[k]` — has transferred on input `k`, every beat of that frame
shall transfer exactly once on the output.

**S5a — a frame abandoned at the source is NOT covered by S5.** If a source
transfers one or more beats of a frame and then stops offering before the beat
carrying `s_tlast_i[k]`, the design is **not required to emit any of that
frame's beats** and may hold them indefinitely. Complete every frame you start
before you stop driving, and do not read a held partial frame as a loss.

### Handshake

**S6 — READY IS NOT A GRANT.** `s_tready_o[k]` may be high on an input that is
not selected and whose frame will not be forwarded next. A beat transferring on
input `k` does **not** imply that input `k` has been selected, nor that its data
will appear on the output in that cycle or the next. There is no selection
output and none is inferable from `s_tready_o`.

**S7 — source obligation (this constrains YOUR TESTBENCH, not the design).**
Once `s_tvalid_i[k]` is asserted it shall remain asserted, with `s_tdata_i[k]`,
`s_tkeep_i[k]`, `s_tlast_i[k]` and `s_tuser_i[k]` held stable, until the beat
transfers. The design's behaviour if you violate this is unspecified.

**S8 — backpressure.** `m_tready_i` may be low on any cycle, including mid-frame
and on the cycle carrying `m_tlast_o`, for arbitrarily many consecutive cycles.
No beat shall be lost, duplicated or reordered as a result, and no frame in
progress shall be abandoned.

### Selection

**S9 — selection order is unconstrained.** Which input is selected for the next
frame, and on what basis, is not specified. Do not require any particular order,
nor require that a given input be selected within any bound tighter than S10.

**S10 — bounded fairness.** Under **continuous offered load** — every input
holding `s_tvalid_i[k]` continuously with further complete frames available, and
`m_tready_i` held high throughout — **every input shall begin at least one frame
within any window of 16 consecutive completed output frames.**

### Latency and reset

**S11 — latency is unconstrained.** The number of cycles between a beat
transferring on an input and its appearance on the output is not specified, and
may vary between beats.

**S12 — reset.** `rst_i` is **synchronous and active high**. While `rst_i` is
high the design shall be returned to an idle state. On the first cycle after
`rst_i` is released, `m_tvalid_o` shall be low, and **no beat that transferred
on an input before or during reset shall appear on the output afterwards.**

### Explicitly out of scope — do not check these

1. **Selection order** — which input goes next, and any policy behind it,
   subject only to S10's window.
2. **Latency** between an input beat and its output beat.
3. **Promptness of `s_tready_o[k]`** — an input's ready may be low on any cycle,
   for reasons including but not limited to fullness or another input being
   served. Do not require ready to be high merely because the design is idle.
4. **`m_tdata_o`, `m_tkeep_o` and `m_tuser_o` while `m_tvalid_o` is low** —
   unconstrained. They may hold their previous value, be zero, or be arbitrary.
5. **Whether a new frame may begin on the output in the same cycle the previous
   frame's `m_tlast_o` beat transfers**, or whether idle cycles separate frames.
   Both are legal, and the number of idle cycles is unbounded.
6. **Internal structure** — arbiter type, buffering, register stages, whether
   inputs are buffered at all.
7. **Any particular pattern on `tkeep`.** It is a forwarded sideband and nothing
   more; the contract requires only that what arrived with a beat leaves with it.

---

---

## SystemVerilog constraints — read these first

Your file is compiled with **Verilator 5.x** (`--binary --timing`). These are
tool-enforced, not style advice. Each one has already caused a submitted
testbench to be rejected with none of its checking ever running:

- **Declarations come before statements.** Every variable declared in a
  `begin`/`end` block must appear before the first statement in that block.
  `int found = -1;` written after an assignment is a syntax error, not a warning.
- **Use `automatic` for anything declared inside a procedural block that you
  assign on each execution.** A declaration with an initialiser inside an
  `always` or `initial` block is **static**: `rec_t e = q.pop_front();` runs its
  initialiser once, at time zero, and never again — so `e` silently holds an
  all-zero value for the entire run and every comparison against it is
  meaningless. Write `automatic rec_t e = q.pop_front();`.
- **Never change a signal in the same timestep as the edge you sample it on.**
  `@(posedge clk); x = 1;` races the design's own sampling of `x` at that edge,
  and the usual symptom is that correct hardware looks inert or reports garbage.
  Drive from the opposite edge, or advance state with nonblocking assignment
  from the edge that consumed it.
- **Identify a result by bookkeeping, not by matching on its value.** Results
  repeat, so content matching is ambiguous and will mis-attribute.
- Do not use `#` delays for anything except the clock generator and the watchdog.
- No UVM, no `randsequence`, no DPI. Queues and associative arrays are fine.

---

## Provided plumbing

It moves beats and does nothing else. It has no notion of a frame, keeps no scoreboard, and draws no conclusion from any signal. Framing, ordering, integrity, fairness and every check are yours.

Paste this inside your module. It is correct as given and it has been run against the design; you may extend it, but you do not need to fix it.

```systemverilog
// =============================================================================
// v_nw03 PROVIDED PLUMBING -- shipped inside the task text.
// =============================================================================
// This moves beats. It checks nothing, scores nothing, and decides nothing.
//
// WHAT IT DELIBERATELY DOES NOT DO, and why
// -----------------------------------------
// S6 -- "ready is not a grant" -- is this task's load-bearing clause, and the
// whole point of the exercise is whether a submission reads it. So this file:
//
//   * never inspects s_tready_o except to detect that the beat it is currently
//     offering has transferred, which is S1 and is stated in the specification;
//   * never reports, returns, counts or names a "grant", a "selection", or an
//     "acceptance" of anything larger than one beat;
//   * has no notion of a frame. bfm_send moves ONE beat. Framing, ordering,
//     atomicity, fairness and the whole scoreboard are the submission's job.
//
// A submission can still get S6 wrong in exactly the way the clause warns
// about, because nothing here tells it what a transferred input beat implies
// about the output.
//
// The three defects this replaces were all plumbing and none was about
// checking: a reset asserted in the same timestep as the edge it was sampled
// on, operands driven and sampled in one timestep, and a testbench that never
// gave the design a stable beat to take.
// =============================================================================

  // ---- clock -----------------------------------------------------------------
  logic clk;
  initial begin clk = 1'b0; forever #5 clk = ~clk; end

  // ---- reset -----------------------------------------------------------------
  logic rst;
  initial rst = 1'b1;

  // Asserts reset, holds it, and releases it OFF the sampling edge so nothing
  // you or the design samples changes in the same timestep as the change.
  task automatic bfm_reset(input int cycles = 4);
    @(negedge clk);
    rst = 1'b1;
    repeat (cycles) @(posedge clk);
    @(negedge clk);
    rst = 1'b0;
  endtask

  // ---- input side ------------------------------------------------------------
  // Offers ONE beat on input k and returns once that beat has transferred.
  // Every field is presented at the negative edge and held stable until the
  // transfer, which is the source obligation S7 states.
  //
  // Calling bfm_send again immediately presents the next beat with valid still
  // high, so back-to-back beats and continuous offered load are available.
  task automatic bfm_send(input int                          k,
                          input logic [DATA_WIDTH-1:0]       data,
                          input logic [(DATA_WIDTH/8)-1:0]   keep,
                          input logic                        last,
                          input logic [USER_WIDTH-1:0]       user);
    @(negedge clk);
    s_tdata[k]  = data;
    s_tkeep[k]  = keep;
    s_tlast[k]  = last;
    s_tuser[k]  = user;
    s_tvalid[k] = 1'b1;
    forever begin
      @(posedge clk);
      if (s_tready[k]) break;
    end
  endtask

  // Stops offering on input k.
  task automatic bfm_idle(input int k);
    @(negedge clk);
    s_tvalid[k] = 1'b0;
  endtask

  // ---- output side -----------------------------------------------------------
  // Sets the sink's ready. Changed at the negative edge, never at the edge the
  // design samples it on.
  task automatic bfm_ready(input logic value);
    @(negedge clk);
    m_tready = value;
  endtask

  // ---- watchdog (S13) --------------------------------------------------------
  // Yours to keep. It fires regardless of what the design does, which is what
  // S13 requires; one of the faulty designs never selects an input that a
  // correct one would.
  initial begin
    #20_000_000;
    $display("RESULT: FAIL (watchdog: no forward progress)");
    $finish;
  end
```

---

## What to produce

A single SystemVerilog file containing one module `frame_arb_mux_tb` that
instantiates `frame_arb_mux` and self-checks.

- Configure it with `S_COUNT = 4`, `DATA_WIDTH = 32`, `USER_WIDTH = 1`.
- **It must terminate on its own, unconditionally.** Include a watchdog: an
  independent `initial` block that reports failure and `$finish`es after a
  generous time limit, no matter what the design does. Your testbench will be
  run against deliberately faulty implementations, and **one of them never
  selects an input that a correct design would select.** A testbench that waits
  for that output with no timeout runs forever — it has not detected the fault,
  it has stopped, and it blocks the run for everything behind it.
- Print exactly one final line: `RESULT: PASS` or `RESULT: FAIL`.
- Print a diagnostic line per failure naming the requirement (`S1`…`S12`).
- It will be compiled with Verilator 5.x (`--binary --timing`). Keep to
  synthesisable-simulation SystemVerilog that Verilator accepts; queues and
  associative arrays are fine. Do not use UVM, `randsequence`, or DPI.
- Do not use `#` delays for anything except the clock generator and the
  watchdog.

Ground every check in a numbered requirement. If a behaviour is not specified
above, do not check it — the implementation is free to choose, and a check on an
unspecified behaviour will reject correct hardware.

============================ PASTE ABOVE THIS LINE ============================
