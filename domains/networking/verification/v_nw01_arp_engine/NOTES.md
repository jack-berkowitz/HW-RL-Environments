# v_nw01 `arp_engine` — build notes

Tier-B. Anchor: Forencich `verilog-ethernet/rtl/arp.v`, MIT, five-file closure
(`arp_cache`, `arp_eth_rx`, `arp_eth_tx`, `lfsr`).

## Why this design

It is a protocol engine with real state: a cache it learns into, a lookup it
retries on a timer and eventually abandons, a subnet calculation that decides
*which* address it even asks for, and an obligation to answer other stations
asking for it. A testbench has to model all of that, and it has to speak the
28-byte ARP frame format in both directions to see any of it.

## The timers are pinned small, and that is the point

At the anchor's defaults a retry interval is **250 million** cycles and a
timeout **3.75 billion**. Neither boundary is reachable in simulation, so
neither could be stated as a checkable bound and the retry and timeout clauses
would be untestable — which is most of the interesting behaviour. They are
pinned to 64 and 256. The cache is pinned to **4** entries for the same reason:
at the anchor's default of 512 a testbench could never fill it.

## Step 1 — semantic confirmation (measured, not read)

| question | measured |
|---|---|
| uncached lookup | one broadcast request frame, `SHA`/`SPA` = ours, `THA` = 0 |
| a matching reply | resolves the lookup in 17 cycles with the reply's SHA, no error |
| the same address again | answered in **4** cycles with **no frame sent** — it is cached |
| unanswered lookup | **exactly 4** frames at cycles 127, 192, 257, 322 — 65 apart — then an error ~256 cycles after the last |
| a request for our IP | answered: `oper=2`, `SPA` ours, `TPA` the requester's, sent to the requester's MAC |
| an off-subnet lookup | one frame, asking for the **gateway** |

Every one of those is what ARP is supposed to do. Unlike the two anchors before
it, nothing here had to be worked around.

## A measured constant that should not have been a clause

The retries came out **65** cycles apart, which is the pinned interval plus a
cycle of handshake. The first draft of Q4 pinned 65 exactly. That is an
implementation artefact, not a contract: an engine that took 64 or 66 would be
just as correct. Q4 and Q5 are now **windows** — 64..80 and 256..300 — with the
*count* still exact. Both wrong-timer mutants sit well outside them.

## Step 5c — the policy-divergent perturbation

`conformant/conformant_perturbations.sv` does **not** instantiate the golden. It
shares the anchor's frame serialiser and deserialiser — mechanical byte packing
that clause F fixes completely and that carries none of the contract's
substance, said plainly rather than claimed as full independence — and
implements its own protocol engine, cache and retry logic.

It takes the opposite choice on all three named latitude clauses: a **fully
associative round-robin cache** against the golden's direct-mapped hash (L1), a
recognisable pattern on `resp_mac_o` when the error bit is set (L2), and
different timing throughout — 70-cycle retries, a hit answered the cycle after
the lookup (L3).

**It passed the reference testbench on the first run**, which is the evidence
that the testbench is checking the contract rather than the golden's state
machine, cache policy or phase. Policy independence is **18 of 18**.

## Step 5 — negative controls

**(b)** Both known-bad DUTs are caught naming clauses X3, Q2 and Q6.

The stuck DUT was **initially caught only by the watchdog, with zero
violations** — the testbench waited unbounded for the design to accept a lookup
or a payload byte, so a design that accepts nothing produced a hang instead of a
diagnosis. Those waits are now bounded and X3 was widened to cover forward
progress in both directions. This is the third task in a row where an unbounded
wait on an input turned a clause failure into a watchdog message; it is worth
treating as a standing check rather than a lesson relearned.

**(a)** The null testbench is reported INVALID and EXCLUDED FROM SCORING.

## A testbench bug worth recording

The first run failed four clauses at once — no request frame seen after a
lookup, a non-ARP sender apparently learned, no off-subnet request, and a
cleared cache apparently still answering. All four were **one** mistake: the
transmit monitor only completes a frame when its final payload byte moves, which
is at least 28 cycles after the header, and the stimulus waited 25. A design
cannot be judged to have sent nothing until it has had time to send something.
The provided plumbing says so in as many words.

## Rule 4 — coverage floors

Every floor counts **stimulus**: lookups driven, cached and uncached, replies
and requests fed in, whether a lookup was ever left unanswered, whether an
off-subnet address was asked for, whether a request for another station was
sent, whether a non-ARP frame was sent, and whether clear and reset were
exercised. None counts a DUT response.

## Watchdogs

| | |
|---|---|
| TB simulation-time limit | 8 ms |
| `sim_timeout_s` | 120 s |
