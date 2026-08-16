<!-- ===================================================================
     DELETE THIS HEADER BEFORE PASTING.

     Purpose: the clean version of the spec-completeness pilot. Every author
     here has read the RTL, so no local author can write a testbench blind.
     A model can. Paste everything BELOW the marker into a fresh chat.

     Note before sending: this ships a port map derived from SHL-0.51
     licensed code plus a prose specification. No RTL. Lighter exposure
     than the recognition probe, same standing caveat -- fine internally,
     needs a licence review before any external release.

     Scoring, once the reply comes back, is a THREE-WAY split per failure:
       (a) driver bug        -- e.g. stimulus changed in the same timestep
                                as the sampling edge, which makes a correct
                                DUT look completely inert
       (b) unpromised reliance -- checks something the spec leaves open
                                (compare against conformant/README.md)
       (c) genuine spec gap  -- the spec really does not say
     Only (c) is a specification defect. Do not collapse these into a
     pass/fail number; the split is the entire result.
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

## What to produce

A single SystemVerilog file containing one module `tag_tracker_tb` that
instantiates `tag_tracker` and self-checks.

- Configure it with `TAG_W = 3`, `SLOTS = 8`, `N_MATCH = 1`,
  `payload_t = logic[31:0]`. Leave `FULL_RATE` and `CUT_POP_PATH` at 0.
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

============================ PASTE ABOVE THIS LINE ============================
