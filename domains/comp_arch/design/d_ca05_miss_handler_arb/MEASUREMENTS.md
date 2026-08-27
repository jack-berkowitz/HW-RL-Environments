# d_ca05 — step-0 anchor conformance audit

Anchor: `refs/cva6/core/cache_subsystem/miss_handler.sv` (855 lines)
Probes: `tb/audit/ca05_elab_probe.sv`, `tb/audit/ca05_amo_flush_probe.sv`

## 1. The outstanding step is closed

`DESIGN_TASK_LANDSCAPE.md` recorded:

> *"I have not yet built the probe that proves it with types bound, which is the
> one step outstanding; on the evidence it is very likely clean, and **that is a
> prediction rather than a result**."*

It is now a result. Elaborated with every parameter bound the way the real parent
binds it (`std_nbdcache.sv:156`), the two `localparam type`s copied from
`std_nbdcache.sv:51/:57` where they are actually declared — they are **not** in
`std_cache_pkg`, which is why binding them was the question — and `CVA6Cfg` built
by `build_config_pkg::build_config()` from the real `cv64a6_imafdc_sv39` user
config rather than `cva6_cfg_empty`, whose zero DCACHE fields would make the
widths degenerate and prove nothing.

    MODMISSING 0 · %Error 0 · %Warning 42  (24 WIDTHEXPAND, 12 WIDTHTRUNC, 6 UNOPTFLAT)

**Confirmed non-vacuous** before being believed: 55 warning lines originate in
`miss_handler.sv` and 21 in `axi_adapter.sv`, including `miss_handler.sv:788`,
inside the arbiter. A clean lint that never read the DUT would show none.

Build constraint found: `--public-flat-rw` provokes a **Verilator internal
fault** on this design, via the UNOPTFLAT loop through
`i_bypass_arbiter.rsp_i`. Without the flag it builds; hierarchical references
still resolve.

## 2. What the probes measured

| # | question | result |
|---|---|---|
| Q1 | does an AMO force a whole-cache flush first? | **yes** — `IDLE → FLUSH_REQ_STATUS` on the same edge, 516 cycles, then the AMO is served |
| Q2a | does a *real* flush acknowledge? | **yes**, 1 pulse, 513 cycles |
| Q2b | does the AMO-induced flush acknowledge? | **no**, 0 pulses |
| Q3 | `flush_i` **and** `amo_req_i` in the same cycle? | **0 pulses** — see below |
| Q4 | does a concurrent miss defer a pending AMO? | **yes** — `state=MISS`, `serve_amo_q=0`, with `miss_valid=0100` confirmed at the DUT |
| Q5 | four ports requesting: is arbitration fair? | **no** — p0 takes 20/20 |
| Q6 | control, p0 idle | p1 takes 20/20, p2 and p3 **zero** |

### Q3 is the clause worth having

`miss_handler.sv:233-263` is a priority cascade of `if`s with **no `else`**, so
the last match wins — and the `flush_i` branch does not clear `serve_amo_d`:

    if (amo_req_i.req && !busy_i)  → FLUSH_REQ_STATUS, serve_amo_d = 1
    if (flush_i && !busy_i)        → FLUSH_REQ_STATUS   (serve_amo_d UNTOUCHED)
    for (i) if (miss_req_valid[i]) → MISS,              serve_amo_d = 0

and at `:404`, `flush_ack_o = ~serve_amo_q`.

So a **genuine flush request issued in the same cycle as an AMO completes
physically and is never acknowledged.** A requester that waits on `flush_ack_o`
waits forever. Measured, not inferred: 0 pulses, and the run returned to IDLE in
495 cycles, so the flush did happen.

Nobody writes that by accident, and it is invisible unless flush and AMO are
exercised *together* — the F86 conditional-antecedent family.

## 3. A correction to the landscape, and it would have killed the task

The landscape says:

> *"`NR_PORTS` is a real capability axis, and ignoring it is a plausible mistake —
> **a design that services one requester at a time is something a model writes**."*

**The anchor services one requester at a time.** Q5/Q6 show strict lowest-index
priority: with all four requesting, p0 takes every grant; with p0 idle, p1 takes
every grant and p2/p3 get none. A continuously-requesting low port starves every
higher port indefinitely.

So a fairness or no-starvation clause written from that framing would have been
**failed by the anchor itself** — exactly the shape that killed `d_dsp01` under
F54. `NR_PORTS` survives as an axis in the weaker, true form: all `NR_PORTS`
ports must be *servable* (Q6 proves p1 is, when p0 is idle). Fairness is not a
property of this anchor and must not be specified as one.

## 4. What the instruments did wrong, recorded because it is the same lesson twice

- The probe **refused two of its own rows** — `DID NOT RETURN TO IDLE in 40000
  cycles (state=d) -- NOT A MEASUREMENT` — rather than reporting `flush_acks = 0`
  as a result. That is the d_ai04 second-channel rule doing its job on its first
  outing: the zero was true and would have been read as confirmation.
- **Two wrong guesses** at why the DUT sat in `AMO_WAIT_RESP` before I
  instrumented the channel instead of reasoning about it. The monitor showed it
  in one line: `aw v/r=11 atop=20 | b v=1 | r v=0` forever. An ATOP write returns
  **both** B and R, and my R beat was qualified by a registered copy of
  `aw.atop` that is still stale in the cycle W handshakes.
- **Q4 first contradicted the reading**, and the reading was right. My stimulus
  was wrong: `run_until_idle()` returned on the cycle the FSM reached IDLE while
  `amo_req_i.req` was still high, so the FSM re-triggered its own AMO before the
  deassert landed, and Q4 sampled a leftover flush. Fixed by a `quiesce()` that
  deasserts everything and **prints the precondition it actually starts from**.
  A measurement that contradicts a reading is not automatically the truth.

## Not measured

- whether `NR_PORTS` other than 4 elaborates and behaves
- the MSHR address-match paths (`mshr_addr_matches_o`, `mshr_index_matches_o`)
- eviction of genuinely dirty lines — `data_i` was driven clean throughout
- `AMO_LR`/`AMO_SC` reservation behaviour; only `AMO_ADD` was exercised
- overlap with `d_ca01`'s scored surface, which the landscape flags as the risk
  to check first and which remains unchecked

# The two "Not measured" lines closed, before any spec clause was written

## MSHR matching, and the two things reading would have got wrong

`miss_handler.sv:509-519` compares a presented address against the in-flight
miss two ways at once:

    addr  match:  mshr_q.valid && mshr_addr_i[i][55:4] == mshr_q.addr[55:4]
    index match:  mshr_q.valid && mshr_addr_i[i][11:4] == mshr_q.addr[11:4]

With the MSHR holding `0x00000000012340`:

| port | presented | addr match | index match |
|---|---|---|---|
| p0 | `0x00000000012340` — identical | **1** | **1** |
| p1 | `0x0000000001234C` — same line, offset differs | **1** | **1** |
| p2 | `0xAABBBBCCC12340` — same index, different tag | 0 | **1** |
| p3 | `0x00000000099990` — different index | 0 | 0 |
| any | with no miss in flight | 0 | 0 |
| any | after the miss retired | 0 | 0 |

**An address match IMPLIES an index match.** The index field `[11:4]` is a subset
of the address field `[55:4]`, so the two assert *together* — they are not
alternatives. The comment in the anchor reads *"same as previous, but checking
only the index"*, and the natural implementation of that sentence makes them
mutually exclusive. Measurement says otherwise, and this is the clause a
submission is most likely to get wrong for a reason that looks like care.

**The port being served is NOT excluded, and the anchor's own comment says it
is.** Line 510 reads *"exclude the unit currently being served"*; port 0 was the
requester whose miss is in flight, and `addr_matches_o[0]` measures **1**.
Comment and code disagree and only one can be the contract. **The code is the
contract**, because the code is what the anchor does — recorded here so nobody
later reads the comment and calls the measurement a bug.

## The flush walk on the cache array

| quantity | measured |
|---|---|
| cycles, `flush_i` to IDLE | **513** |
| array requests (`\|req_o`) | **512** |
| array writes (`\|req_o && we_o`) | **256** |
| first / last `addr_o` | `0x000` / `0xff0` |
| `be_o.vldrty` bits seen | `11111111` |

256 writes over `NUM_WORDS = 256` sets, addresses stepping by 16 — which is
`2^OFFSET_WIDTH` — so the walk visits **every set exactly once** and asserts
`vldrty` for **all eight ways**. Two array accesses per set, one read and one
write.

That fixes the flush's cost as well as its effect: a design that walks the array
in a different number of accesses is visible on the array port even when the
final cache state is identical.
