# Task: write a SystemVerilog testbench from a specification

You are given the **port map** and a **complete specification** for a hardware
module. **You will not be shown the RTL.** Write a self-checking testbench that
verifies the module against the specification.

Your testbench will be run against a known-correct implementation. It must
**pass**. It will also be run against faulty implementations, and a good
testbench catches those — but passing the correct one comes first: a testbench
that rejects correct hardware is worthless regardless of what else it catches.

---

## Port map

```systemverilog
module tag_tracker #(
    parameter int TAG_W  = 0,
    parameter int SLOTS  = 0,
    parameter bit FULL_RATE   = 0,
    parameter bit CUT_POP_PATH = 0,
    parameter int N_MATCH = 1,
    parameter type payload_t   = logic[31:0],

    localparam type tag_t    = logic[TAG_W-1:0]
) (
    input  logic    clk_i,
    input  logic    rst_ni,

    input  tag_t     push_tag_i,
    input  payload_t   push_data_i,
    input  logic    push_req_i,
    output logic    push_gnt_o,

    input  payload_t [N_MATCH-1:0] match_data_i,
    input  payload_t [N_MATCH-1:0] match_mask_i,
    input  logic  [N_MATCH-1:0] match_req_i,
    output logic  [N_MATCH-1:0] match_hit_o,
    output logic  [N_MATCH-1:0] match_gnt_o,

    input  tag_t     pop_tag_i,
    input  logic    pop_en_i,
    input  logic    pop_req_i,
    output payload_t   pop_data_o,
    output logic    pop_data_valid_o,
    output logic    pop_gnt_o,

    output logic    full_o,
    output logic    empty_o
);
```

---

## Specification

A capacity-bounded store of `(tag, payload)` entries with three access paths:
insertion, content-addressed search, and tag-ordered removal.

### Parameters

| name | meaning |
|---|---|
| `TAG_W` | width of a tag; tags range over `[0, 2**TAG_W)` |
| `SLOTS` | total entries storable across all tags |
| `N_MATCH` | number of independent search ports |
| `payload_t` | payload type |
| `FULL_RATE` | when 1, push and pop of the same tag may complete in the same cycle |
| `CUT_POP_PATH` | when 1, `push_gnt_o` does not depend combinationally on `pop_req_i` |

### Storage and ordering

**R1 — capacity.** The design shall accept `SLOTS` entries. Entries are shared
across tags: any distribution summing to `SLOTS` shall be accepted, including
`SLOTS` entries all carrying the same tag.

**R2 — per-tag FIFO order.** For a given tag, entries shall be removed in the
order they were inserted.

**R3 — no cross-tag ordering.** Order between entries of *different* tags is
**not specified** and shall not be checked.

### Push

**R4.** A push is requested with `push_req_i`, carrying `push_tag_i` and
`push_data_i`. The entry is committed on a cycle where
`push_req_i && push_gnt_o`.

**R5.** `push_gnt_o` shall be low when the store holds `SLOTS` entries.

**R6.** `push_gnt_o` may be low for reasons other than fullness — port conflict,
internal arbitration. A testbench shall not require `push_gnt_o` to be high
merely because space exists.

### Pop

**R7.** A pop is requested with `pop_req_i` and `pop_tag_i`. It completes on a
cycle where `pop_req_i && pop_gnt_o`.

**R8.** On a completing pop, `pop_data_valid_o` shall be high if at least one
entry with `pop_tag_i` is present, and low otherwise. When high, `pop_data_o`
shall carry the oldest entry for that tag (R2).

**R9.** `pop_en_i` selects removal. When `pop_en_i` is high on a completing pop
with `pop_data_valid_o` high, the entry is removed. When `pop_en_i` is low, the
entry is inspected and **not** removed.

**R10.** A pop of a tag with no entries shall complete with `pop_data_valid_o`
low. It is not an error. `pop_data_o` is then **unconstrained** and shall not be
checked.

### Search

**R11.** Search port `k` is requested with `match_req_i[k]`, carrying
`match_data_i[k]` and `match_mask_i[k]`. It completes on a cycle where
`match_req_i[k] && match_gnt_o[k]`.

**R12.** On a completing search, `match_hit_o[k]` shall be high if and only if
the store holds at least one entry whose payload satisfies

```
(payload & match_mask_i[k]) == (match_data_i[k] & match_mask_i[k])
```

Search is over payloads across all tags; it does not filter by tag.

**R13.** A mask of all zeros matches every stored entry, so `match_hit_o[k]`
shall be high whenever the store is non-empty.

### Status

**R14.** `empty_o` shall be high exactly when the store holds zero entries.
`full_o` shall be high exactly when it holds `SLOTS`.

### Reset

**R15.** While `rst_ni` is low the store shall be emptied; after release,
`empty_o` shall be high and `full_o` low.

### Explicitly out of scope — do not check these

1. **Arbitration policy** between push, pop and search in one cycle.
2. **Cross-tag ordering** (R3).
3. **`pop_data_o` when `pop_data_valid_o` is low** (R10).
4. **Combinational-vs-registered timing** of any output within its cycle, beyond
   what `CUT_POP_PATH` states.
5. **Internal structure** — linked list, per-tag FIFOs, CAM, anything.
6. **Latency**: the number of cycles between request and grant is unconstrained.

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
  and the usual symptom is that correct hardware looks inert. Drive from the
  opposite edge, or advance state with nonblocking assignment from the edge that
  consumed it.
- **Identify a result by bookkeeping, not by matching on its value.** Values
  repeat, so content matching is ambiguous and will mis-attribute.
- Do not use `#` delays for anything except the clock generator and the watchdog.
- No UVM, no `randsequence`, no DPI. Queues and associative arrays are fine.

---

## Provided plumbing

Clock, reset and watchdog, plus the timing discipline that keeps your stimulus
off the sampling edge. **No transactor is provided for the request/grant ports:
deciding when a request has actually completed is part of this task, and a
driver that answered it would answer the question instead of asking it.**

Paste this inside your module. It is correct as given and has been run against
the design.

```systemverilog
// ---------------------------------------------------------------------------
// PROVIDED PLUMBING -- clock, reset and watchdog only.
// ---------------------------------------------------------------------------
// NO TRANSACTOR IS PROVIDED FOR THE REQUEST/GRANT PORTS. Driving them, and
// deciding when a request has completed, is part of the task.
//
// What is provided is the timing discipline, because getting it wrong is
// silent: reset is asserted and released away from the sampling edge, and the
// helper below moves you to the point in the cycle where it is safe to change
// stimulus. It has been compiled and run against a correct implementation.
// ---------------------------------------------------------------------------
  // ---- clock -----------------------------------------------------------------
  logic clk;
  initial begin clk = 1'b0; forever #5 clk = ~clk; end

  // ---- reset (active low) ----------------------------------------------------
  logic rst_n;
  initial rst_n = 1'b0;

  task automatic bfm_reset(input int cycles = 4);
    @(negedge clk);
    rst_n = 1'b0;
    repeat (cycles) @(posedge clk);
    @(negedge clk);
    rst_n = 1'b1;
  endtask

  // ---- timing discipline -----------------------------------------------------
  // Advance to the point in the cycle where it is safe to change stimulus.
  // Drive your inputs immediately after calling this, never straight after a
  // @(posedge clk): an assignment in the same timestep as the sampling edge
  // races the design and makes correct hardware look inert.
  task automatic bfm_drive_point();
    @(negedge clk);
  endtask

  // Advance one full cycle and return after the design has sampled.
  task automatic bfm_tick();
    @(posedge clk);
  endtask

  // ---- watchdog --------------------------------------------------------------
  initial begin
    #20_000_000;
    $display("RESULT: FAIL (watchdog: no forward progress)");
    $finish;
  end
```

---

## What to produce

A single SystemVerilog file containing one module `tag_tracker_tb` that
instantiates `tag_tracker` and self-checks.

- Configure it with `TAG_W = 3`, `SLOTS = 8`, `N_MATCH = 1`,
  `payload_t = logic[31:0]`. Leave `FULL_RATE` and `CUT_POP_PATH` at 0.
- **It must terminate on its own, unconditionally.** Include a watchdog: an
  independent `initial` block that reports failure and `$finish`es after a
  generous time limit, no matter what the DUT does. Your testbench will be run
  against deliberately faulty implementations, and **one of them never grants a
  request it should grant**. A testbench that waits for that grant with no
  timeout runs forever — it does not detect the fault, it just stops, and it
  blocks the run for everything behind it.
- It must run to completion and `$finish` on its own.
- Print exactly one final line: `RESULT: PASS` or `RESULT: FAIL`.
- Print a diagnostic line per failure naming the requirement (`R1`…`R15`).
- It will be compiled with Verilator 5.x (`--binary --timing`). Keep to
  synthesisable-simulation SystemVerilog that Verilator accepts; queues and
  associative arrays are fine. Do not use UVM, `randsequence`, or DPI.
- Do not use `#` delays for anything except the clock generator.

Ground every check in a numbered requirement. If a behaviour is not specified
above, do not check it — the implementation is free to choose, and a check on an
unspecified behaviour will reject correct hardware.
