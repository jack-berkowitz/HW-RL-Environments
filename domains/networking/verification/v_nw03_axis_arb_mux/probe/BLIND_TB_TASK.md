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

**S5 — no loss, no duplication.** Every beat that transfers on an input shall
transfer exactly once on the output.

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
