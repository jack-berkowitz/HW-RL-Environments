# Second source — the three differences, named BEFORE anything is written

**This file is the gate.** It is committed before the shim, before the
testbench, and before a line of the second source exists, so that a reader can
tell the difference between a requirement that constrained the design and a
description back-fitted to whatever got built. Differences named after the fact
satisfy the rule in form and remove all of its content: the file has three
differences, they are genuinely different, and the requirement did no work at
any point.

**The list is kept even where a difference does not survive.** On `d_dsp02` one
of three turned out to be unimplementable at sane width, and keeping the failed
claim — rather than swapping in a new one that worked — is what produced the
only real design-space result that exercise generated. Any of the three below
may fail the same way. If one does, it stays here with the reason, and the
shipped claim is stated as smaller than the declared one.

**What the second source is for.** It is a falsifier, never an oracle. Its job
is to fail the checker. When it does, rule 5's disambiguation runs *before*
anything is changed: run the failing input through the anchor; if the second
source disagrees with the anchor, the second source is wrong. On the evidence so
far that is the way it goes — `d_dsp02` went three for three, and no check was
loosened.

---

## D1 — miss tracking: merge against ALL outstanding lines, not just the one being serviced

**The anchor's choice, established from its source rather than assumed.**
`bsg_cache_non_blocking_mhu.sv:193`:

```systemverilog
assign is_secondary = (curr_miss_tag == miss_fifo_tag) & (curr_miss_index == miss_fifo_index);
```

`curr_miss_*` comes from `curr_dma_cmd_r` — the **single** miss currently being
processed. The anchor holds a FIFO of *requests* and detects a secondary only
against the one line it is servicing right now.

**The second source's choice.** A small file of per-line miss records (call them
what you like; the contract names no structure — spec L2). On allocation, a new
miss is compared against **every** outstanding record. A request for any line
already outstanding attaches to that record instead of allocating a new one.

**Why this is free.** Spec L2 states that how outstanding misses are tracked is
unconstrained, and C1 requires only that at least `MAX_MISSES` distinct line
misses be outstanding. Neither names a structure or a merge scope.

**Predicted witness, by measurement.** Stimulus: with memory held, issue misses
to lines L1, L2, L3 in that order, then a fourth request to **L1** — which is
outstanding but is not the line being serviced once L2/L3 are queued behind it.
Count fills issued.

| | fills for that stimulus |
|---|---|
| anchor | **2 or more** (the secondary to L1 is not recognised while L2/L3 are current) |
| second source | **exactly 3** — one per distinct line, never more |

Metric: memory fill count for a fixed stimulus, read off `mem_req_*`.

**This is the highest-risk of the three.** If the anchor turns out to merge more
broadly than its source suggests — for example if the FIFO is rescanned in a way
that catches L1 later anyway — the fill counts converge and the difference is
unobservable. A declared difference that turns out to be unobservable is not a
difference, and it will be recorded as failed rather than restated.

---

## D2 — replacement: true LRU per set, not tree pseudo-LRU

**The anchor's choice.** `bsg_lru_pseudo_tree_encode` and
`bsg_lru_pseudo_tree_backup` are instantiated in the MHU
(`mhu.sv:242`, `mhu.sv:259`) and are in the dependency closure.

**The second source's choice.** True LRU: a per-set ordering updated on every
access, evicting the genuinely least-recently-used way.

**Why this is free.** Spec L1 states replacement policy is unconstrained and
names LRU, tree-pseudo-LRU, round-robin and random as all conformant. Nothing in
the checker inspects which way is evicted.

**Predicted witness, by measurement.** Tree-PLRU and true LRU are identical at
`WAYS = 2` and diverge at `WAYS = 4`, so the witness runs at the scored
configuration. Stimulus: fill all four ways of one set, then touch them in an
order that leaves tree-PLRU's bits pointing at a different way than true LRU's
ordering does, then force a fifth miss to that set. Read the victim's address off
`mem_req_addr_o` on the writeback.

Metric: victim address for a fixed access sequence — the two policies name
different lines, and that is directly observable on the memory port.

**Risk.** Low on observability, moderate on construction: the divergent sequence
has to be derived rather than guessed, and a sequence where both policies happen
to agree would witness nothing. Deriving it is part of the work.

---

## D3 — dirty replacement: fetch the new line FIRST, write the victim back after

**The anchor's choice.** Not yet measured. Recorded as unmeasured on purpose —
the claim below is a concrete choice made on engineering grounds, not "whatever
the anchor does not do", because the latter is back-fitting with an extra step.

**The second source's choice.** On a replacement whose victim is dirty: buffer
the victim block, issue the **fill** first, satisfy the waiting requests as soon
as the line lands, and issue the **writeback** afterwards from the buffer.

**Engineering rationale.** It takes the writeback off the miss's critical path —
a standard victim-buffer arrangement — at the cost of one block of storage. That
is a real trade, which is what makes it a design choice rather than a coin flip.

**Why this is free.** Spec M3 requires at most one memory transaction
outstanding and M1/M2 fix each transaction's shape, but nothing orders the fill
and the writeback of a single replacement relative to each other.

**Predicted witness, by measurement.** Force a dirty replacement and record the
sequence of `mem_req_we_o` across the two transactions.

| | first transaction | second |
|---|---|---|
| second source | `we = 0` (fill) | `we = 1` (writeback) |
| anchor | to be measured | |

**Risk.** If the anchor already fetches first, the difference is unobservable and
the claim fails. That outcome is acceptable and will be recorded; it is not a
reason to swap in a different difference afterwards.

---

## A candidate that was rejected before it was built — and it found a spec defect

**Rejected: no-write-allocate (write a store miss straight through to memory,
never allocating the line).**

Spec L4 as originally written named write-through as free, and it is not:
**the memory port cannot express it.** M1 and M2 make every memory transaction
block-granular — `BLOCK_WORDS` beats — and there is no single-word or byte-masked
write encoding anywhere on the port. A no-write-allocate design has no legal way
to send one modified word to memory.

So L4 named an alternative that does not exist at this interface. That is
rule 12's failure mode arriving inverted: not an alternative silently foreclosed,
but latitude advertised that the contract cannot honour. A submission reading L4
and choosing write-through would have found itself unable to build against the
port, having been told the choice was open.

**L4 is corrected in the interface** to state that write-allocate is the only
policy this port can express, that this follows from M1/M2 rather than being an
independent requirement, and that write-through is out of scope for that reason.

Recorded here rather than quietly fixed, because the defect was found by trying
to *use* the latitude. Reading L4 did not reveal it, and neither would auditing
the clause against a standard — the port and the clause have to be held against
each other. It is the same lesson as auditing the artefact rather than the prose,
one level along: **the latitude a spec advertises has to be checked against the
interface that has to carry it.**

---

## D3 AND D3′ HAVE BOTH FAILED. D3″ NAMED.

Two candidates for the third difference are now dead, and both failures are kept
here rather than replaced quietly, because between them they map the design space
more usefully than a difference that had simply worked.

**D3 — fetch first, write the victim back after. REFUTED BY MEASUREMENT.**
The anchor already does exactly that: traced across a dirty replacement, the
transaction order is `we=0` (fill) then `we=1` (writeback). Not a difference.

**D3′ — strictly in-order responses. REFUTED BY THE CONFORMANT SET, and it took
a spec correction with it.** Built as conformant perturbation `c03`, licensed by
R4's original text, which said flatly that in-order retirement was conformant. It
failed C2. The neutralised copy passed, so the wrapper was sound and the
perturbation was the cause — and the cause turned out to be a genuine conflict
between two clauses: a hit accepted *after* an outstanding miss is blocked behind
that miss under in-order retirement, and C2 requires that hit to be **answered**.

**R4 has been narrowed** and the artifact is now mutant `m06_responses_in_order`
— where it is the cleanly isolated C2 mutant, failing C2 and nothing else, which
`m05` does not manage. **So the second source cannot take this difference: it is
not conformant.**

**D3″ — EARLY FILL FORWARDING.** The second source returns the requested word
directly from the fill stream, on the beat that carries it, rather than after the
whole block has landed and been written into the data array.

*Why it is free:* L6 leaves latency unconstrained, and R4 as narrowed forbids only
holding a ready response behind an unready one — forwarding early does the
opposite.

*Engineering content:* it needs a comparator on the beat index and a bypass path
into the response port, and it buys the requester several cycles on every miss.
A real trade, not a coin flip.

*Predicted witness, by measurement:* `fill_latency_cycles`. The anchor replays a
queued miss against the data array only after the fill completes; the second
source answers at the beat carrying the word. The metric is already emitted.

*Risk, stated:* the anchor's exact fill-to-response latency has not been measured,
so the size of the gap is unknown. If it turns out the anchor already forwards,
D3″ fails too and is recorded like the other two. **Three failed candidates for
one difference would itself be the finding** — it would say the anchor's choices
on this axis are far less free than a reading of the spec suggests.

---

## D3″ MEASURED AND IT SURVIVES — the anchor does not forward

Measured before writing a line of it, which is the mistake D3 made and this does
not repeat.

**Method.** One isolated miss per word-offset within the block, each to a fresh
line, at the scored configuration. If the anchor forwards the requested word as
its beat arrives, latency rises with the offset. If it waits for the whole block
to land and then replays, latency is flat.

| requested word offset | 0 | 1 | 2 | 3 |
|---|---|---|---|---|
| fill-to-response latency, cycles | **13** | **13** | **13** | **13** |

**Flat. The anchor does not forward — it waits for the block, then replays.**

**The flat reading was not believed until the measurement was shown to move.**
A probe that reports a constant is indistinguishable from a probe insensitive to
what it claims to measure. Control: throttle the fill to one beat every four
cycles and re-run.

| | offset 0 | 1 | 2 | 3 |
|---|---|---|---|---|
| beats back-to-back | 13 | 13 | 13 | 13 |
| beats throttled 4x | **22** | **22** | **22** | **22** |

The measurement responds to fill timing — 13 → 22 — and stays flat across
offsets in both conditions. So the flatness is a property of the anchor, not of
the probe.

**D3″ stands, and its witness is now quantified rather than predicted:** the
anchor's fill-to-response latency is **13 cycles at the scored configuration and
independent of the requested word's offset**. A forwarding second source answers
offset 0 several cycles sooner and shows latency rising with offset. The metric
is `fill_latency_cycles`, already emitted.

**So the third difference is settled after two failures**, and the axis is not as
closed as it was starting to look. D3 failed because the anchor already did it;
D3′ failed because it was not conformant; D3″ is a genuine free choice the anchor
declines to take.
