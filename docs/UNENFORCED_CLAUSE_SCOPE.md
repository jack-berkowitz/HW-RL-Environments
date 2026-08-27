# Scope: the unenforced clauses, and what each one costs to close

**Scoping only. Nothing here is built.** Sizes are estimates against a working
template; the template is `d_nw03`'s B1, which is the one ceiling in the corpus
that is enforced.

## How the working ceiling is enforced, since everything below is measured against it

`d_nw03` closes B1 with four parts:

1. a **ceiling phase** in the testbench — stall every output, keep offering, and
   let the design absorb until it stops accepting;
2. a **settle guard** — `if (b1_guard >= 8000) fail("B1: the ceiling phase never
   settled -- the design kept accepting")`, so a design that never stops is
   caught rather than timing out anonymously;
3. the **assertion** — `b1_held <= 16 * M_COUNT`, plus a METRIC line printing the
   count so a passing run still reports the number;
4. a **control** — `nc_h_overbuffered`, 177 lines, which provides MORE than the
   ceiling and must fail.

**The mechanism that makes it work: measure at rest.** Stall everything, let the
design settle, then count what it swallowed. Internal storage becomes externally
visible through backpressure, with no sampling of a moving pointer.

---

## The three unenforced ceilings

### `d_ca04` B1 — and the measurement objection does not survive contact

The testbench declines to assert on occupancy and states why: *sampled on
`wr_clk` it sees a stale `rd_idx` and OVERSTATES occupancy.* That is correct.

**It is an objection to continuous occupancy tracking, not to the quantity.** The
d_nw03 mechanism does not sample a moving pointer: it stalls the read side
entirely, waits for the write side to stop accepting, and counts. At rest there
is no stale `rd_idx`, because nothing is moving. The clause is measurable by a
method the testbench did not try.

    tb work    a ceiling phase, settle guard, assertion, METRIC   ~60 lines
    control    over-buffer by 4 beats beyond LOG_DEPTH            ~120 lines
    clause     no change -- B1's text is already exact
    risk       LOW. The design is a FIFO; stalling the read side is already
               exercised by the existing C4 phase.

### `d_nw01` C3 — the largest of the three

At most 4 R beats and 4 W beats **per master port**, so the count is per-port and
the phase has to stall every master's response channels while slaves keep
answering.

    tb work    per-port counters, phase, guard, assertion, METRIC  ~110 lines
    control    a crossbar buffering a full burst per master        ~150 lines
    clause     no change
    risk       MEDIUM. Two channels (R and W) with separate ceilings, and
               NUM_MST is swept 2 and 4, so the phase runs per configuration.

### `d_ca01` C4 — the one I would not build as stated

At most two cache lines outside the tag and data arrays, plus one word of merged
store data per pending miss.

**"Outside the arrays" is not observable from the delivered surface.** Stalling
the response channel measures total holding, and the arrays legitimately hold
lines, so the measurement cannot separate the bounded resource from the unbounded
one. d_nw03 and d_ca04 have no such ambiguity — all their storage is buffer.

    tb work    not scopable as written
    control    not scopable as written
    clause     CHANGE NEEDED. Either bound TOTAL holding, which is measurable, or
               state the bound in terms the harness can see -- e.g. a cap on
               accepted-but-unanswered requests, which is already counted.
    risk       HIGH as stated, LOW after a clause change.

---

## `d_nw01`'s four unchecked clauses

C3 is above. The other three are cheap, and two of them are cheap because a
working implementation exists in a sibling task.

### H3 — output stability under stall. **Copy, do not write.**

No withdraw or payload-stability check exists on the crossbar outputs at all.
`d_ca01` and `d_nw03` both have one and they are the same shape: latch valid,
payload and ready; on the next edge, if valid was high and ready low, fail if
valid dropped or the payload moved.

    tb work    ~25 lines, ported from d_ca01:141-151        LOW risk
    control    a crossbar that drops valid on backpressure  ~90 lines
    ALSO NEEDS a never-exercised guard. Both sibling tasks carry one --
    "R1 was never exercised" -- because a design that never offers a response to
    a stalled consumer EMPTIES the clause rather than violating it.

### H1 — no `*_ready` combinational on its own `*_valid`

Its only appearance in the testbench is inside a comment describing the rule.
The measurement is an in-cycle toggle, the same one used in
`d_ai04`'s handshake probe and `d_dsp03`'s L4 probe: drive the valid, sample the
ready, toggle the valid with no edge between, sample again.

    tb work    ~30 lines, one phase per channel              LOW risk
    control    a crossbar gating ready on its own valid      ~90 lines
    NOTE       this is a STRUCTURAL property, not a behavioural one. It cannot be
               observed from a normal run; it needs a deliberate in-cycle probe,
               which is why it was never checked by accident.

### D3 — QoS, cache, prot and region carried through unmodified

`qos`, `cache`, `prot` and `region` appear ZERO times in the testbench. The
scoreboard already tracks each transaction end to end, so the fields can be
captured at the master side and compared at the slave side on the existing path.

    tb work    ~40 lines, field capture plus comparison      LOW risk
    control    a crossbar that zeroes qos                    ~90 lines
    clause     no change

---

## Totals

    d_ca04 B1   ~180 lines   LOW risk     no clause change
    d_nw01 C3   ~260 lines   MEDIUM       no clause change
    d_nw01 H3   ~115 lines   LOW          no clause change, needs an antecedent guard
    d_nw01 H1   ~120 lines   LOW          no clause change
    d_nw01 D3   ~130 lines   LOW          no clause change
    d_ca01 C4        ---     HIGH         CLAUSE CHANGE FIRST

Five of six are buildable as stated. One needs its clause rewritten before any
check can be honest about it.

**Every one of these moves a task_text_hash if the clause text changes, and none
of them does except `d_ca01` C4.** Testbench and control work does not move a
hash — `task_text_hash` covers `spec/` and `probe/PASTE.md` only.
