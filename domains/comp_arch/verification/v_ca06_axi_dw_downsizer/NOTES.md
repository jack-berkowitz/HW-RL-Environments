# v_ca06 — AXI data-width downsizer

Anchor: `refs/axi/src/axi_dw_downsizer.sv` (PULP `axi`, SHL-0.51).
Scored configuration: **64-bit upstream → 16-bit downstream, ratio 4**,
`ADDR_W=32`, `ID_W=4`, `MAX_READS=4`.

## Step 1 — semantic confirmation, MEASURED not read

`probe/measure_reads.sv` and `probe/measure_writes.sv` drive the shim and report
what the anchor does. Every case is measured from a clean machine: a probe that
lets one case leave state behind reports the NEXT case's behaviour as this one's,
which it did until each case got its own reset.

### Reads

| upstream (burst, len, size, addr) | downstream AR | upstream R |
|---|---|---|
| INCR len=0 size=3 @1000 | 1 AR, len=3 size=1 | 1 beat, OKAY |
| INCR len=1 size=3 | 1 AR, len=7 size=1 | 2 beats, OKAY |
| INCR len=3 size=3 | 1 AR, len=15 size=1 | 4 beats, OKAY |
| INCR len=3 size=1 | 1 AR, len=3 size=1 | 4 beats, OKAY |
| INCR len=0 size=0 | 1 AR, len=0 **size=0** | 1 beat, OKAY |
| INCR len=1 size=3 **@1004** | 1 AR, **len=5** size=1 | 2 beats, OKAY |
| FIXED len=0 size=3 | 1 AR, len=3, **burst→INCR** | 1 beat, OKAY |
| FIXED len=1 size=3 | **0 ARs** | 2 beats, **SLVERR on EVERY beat** |
| WRAP len=3 size=3 | **0 ARs** | 4 beats, **SLVERR on EVERY beat** |

### Writes

Byte mapping, from a pattern where byte *i* of upstream beat *k* is `(k<<4)|i`:

    INCR len=0 size=3 strb=FF ->  0100/11  0302/11  0504/11  0706/11L
    INCR len=1 size=3 strb=FF ->  ... 0706/11  1110/11 ... 1716/11L
    INCR len=0 size=3 strb=0F ->  0100/11  0302/11  0504/00  0706/00L
    INCR len=0 size=3 strb=81 ->  0100/01  0302/00  0504/00  0706/10L
    INCR len=1 size=3 @1004   ->  0504/11  0706/11  1110/11 ... 1716/11L
    FIXED len=1 (multi)       ->  (no AW, no W beats), upstream B = SLVERR
    WRAP  len=3               ->  (no AW, no W beats), upstream B = SLVERR

## What the measurements settle

1. **Downstream `size` is `min(upstream size, downstream max)`** — not "always the
   downstream width". `size=0` stays `0`.
2. **Downstream `len` follows the BYTES COVERED, not the beat count.** At
   `size=3` aligned it is `(len+1)*4-1`; at `@0x1004` the same request gives
   **len=5, not 7**, because the first upstream beat contributes only bytes 4..7.
   A testbench carrying the simple formula is wrong exactly there and nowhere
   else.
3. **`FIXED` flips on a single beat.** `len=0` is accepted and converted to an
   INCR burst downstream; `len=1` is answered SLVERR. One beat changes the
   verdict.
4. **The error is manufactured, not forwarded.** WRAP and multi-beat FIXED issue
   **zero** downstream transactions and absorb the whole W burst. A monitor
   watching only the downstream port sees nothing at all.
5. **SLVERR lands on every beat**, not just the last, and the upstream still gets
   exactly `len+1` beats.
6. **Strobes split per byte lane**, and a downstream beat whose lanes are all
   unstrobed is **still emitted** — data present, strobe zero. Not suppressed.
7. Strobe lanes are selected by ADDRESS. An upstream beat whose strobe does not
   cover its address lanes produces zero-strobe downstream beats; the reference
   stimulus must drive lane-correct strobes or it is driving non-conformant AXI.

## Two probe faults, fixed rather than reported as behaviour

**The downstream slave backed up after one transaction**, so nine of ten read
cases reported "AR not accepted". Read as DUT behaviour that would have said the
unit accepts one transaction and then stalls forever.

**Two `always` blocks raced on the AW-id queue.** For a `len=0` downstream burst
the AW handshake and the final W beat land in the SAME cycle, so whether the
queue was non-empty came down to scheduling order. No B was returned, and the
measurement said single-beat `size=1` writes get no write response. They do. This
is the same defect class as the merged-block fix in v_nw04 and v_ca04 — shared
state written by two blocks on the same edge.

## Step 5c artefacts, built BEFORE the mutants

Deliberate ordering. The re-grade showed that what stopped the strongest
submissions was not mutant ingenuity but **latitude** — claude produced no score
at all on v_ca05 and v_nw02, both times for rejecting a legal variant, never for
missing a defect. So the legal implementations were written first, and the
reference testbench will be developed against six implementations rather than
fitted to one.

`dut2/dw_downsizer_alt.sv` is an independent implementation from the spec alone.
It holds **one transaction at a time per direction** — A4 makes `MAX_READS` an
upper bound, not an obligation — registers every path, buffers a whole upstream
`W` beat before emitting any downstream beat of it (L4), and drives a fixed
pattern on payloads while their valid is low (X2). The anchor does the opposite
on all four.

`conformant/` holds five perturbations, each turning a different named knob:

| id | clause | what it does |
|---|---|---|
| `dwc_c1_extra_latency` | L1, L2 | every design-driven ready gated, 4 cycles on / 4 off |
| `dwc_c2_admission_throttled` | A4, L2 | upstream address admission gated 8 on / 8 off |
| `dwc_c3_downstream_w_spilled` | L1, L5 | skid buffer on the downstream W channel: later, and gapped |
| `dwc_c4_garbage_when_invalid` | X2 | a recognisable junk pattern on every payload while its valid is low |
| `dwc_c5_response_intake_slow` | L2 | slow to accept downstream responses, 2 on / 2 off |

All six were verified **by measurement**, not by inspection: each was run through
both probes and its output compared against the golden's, field by field, and all
six are contract-identical.

## Four errors in my own apparatus, all found by that comparison

**Gating a ready alone desynchronises the handshake.** c1, c2 and c5 first masked
only the design-driven ready. The golden asserts its ready and considers the
transfer done; the master never sees it and re-offers; the transaction is
accepted three times. `dsAR=3` for one upstream request — the PERTURBATION
violated A2. Gating a ready is legal *behaviour*; masking one is not a legal
*implementation* of it. The valid presented to the golden and the ready presented
outward now carry the same gate, so no cycle exists in which the two sides
disagree. This is the discipline v_ca03's mutants already state, rediscovered on
the conformant side.

**A one-cycle gate can make acceptance impossible.** With `adm` true one cycle in
eight, a design whose ready is registered rather than combinational on valid can
never coincide with it, and nothing is ever accepted. That is not a slow design,
it is a broken one. The gates are multi-cycle windows now.

**An edit leaked between modules.** c2 and c5 ended up referencing `slow`, a
signal declared only in c1. Verilator created an implicit net, tied it low, and
`--lint-only` reported **zero errors** — the read address was simply never
presented, and c2 looked like a design that accepts nothing. `-Wall` reports it
as IMPLICIT/UNDRIVEN, and `-Wall` is the standard for this task from here. There
is now a check that every gate expression names a signal declared in its own
module.

**A third probe race.** `pend_b` was written by one always block and read by
another; for a `len=0` burst the increment and the read land in the same cycle,
so no B was returned. Merged into the single ordered block, as the AW/W capture
already had been. Third instance of this defect class in this task alone.

`dsB_sent` was also dropped from the comparison: it counts when the design drives
`m_bready`, which is L2 latitude, not a contract observable. Comparing it made
two legal implementations look different.

## The reference testbench

Developed against all six legal implementations, and it passes every one of
them: the anchor, the independent `dut2`, and the five conformant perturbations.
It rejects the all-outputs-high negative control.

Design consequences of being written against six rather than one:

* **No ready is ever required to be high.** Every wait carries a generous budget
  and fails only on timeout, naming the channel. Two of the six accept one
  transaction at a time and one throttles admission to eight cycles in sixteen.
* **Every payload is sampled only when its own valid is high** (X2), which
  `dwc_c4` exists to punish.
* **Transactions are driven one at a time for the exact checks**, because A4
  makes `MAX_READS` an upper bound and two implementations accept only one.
  Concurrency is *offered* in its own phase and checked only if it is taken;
  requiring it would reject a conforming design.
* **The downstream address transform is checked against the FORMULAS**, latched
  at the handshake, not against the anchor's choices.

## The reference found two defects in my own specification

**B2's length rule was wrong.** It divided the byte count: `total_bytes /
2^dsize - 1`. For `len=0 size=1` at an odd address the range is a single byte,
and that gives **minus one** where the answer is one beat. The rule is a count of
aligned downstream **blocks spanned**:

    ds_len = (aligned(last, dsize) - aligned(first, dsize)) / 2^dsize

Both readings agree on every aligned request, which is why the first eight
measured cases did not catch it. Re-checked against all of them plus the new
ones.

**B4 was too strong.** It required the downstream burst to be INCR always.
Measured: `FIXED len=0 size=3` becomes a four-beat INCR burst, but `FIXED len=0
size=1` and `size=0` produce a SINGLE-beat downstream burst whose type is
forwarded unchanged as FIXED. A single-beat burst transfers one block and its
type carries no meaning, so B4 now binds only where the downstream burst has more
than one beat, and **L6** names the single-beat case as latitude. Without that,
`dut2` — which always drives INCR — would have been rejected as non-conforming.

## Three more faults in my own apparatus

**The same lane bug, written three times.** The downstream lane of a byte is
`address mod bus_bytes`, not the loop index. At `size` 0 a beat advances one byte
at a time so the lane alternates, and using the index puts every byte in lane 0.
I wrote the wrong idiom in the testbench's read responder, again in its write
checker, and again in `dut2` — three independent instances of one
misunderstanding, each found by a different comparison.

**An `always_comb` that reads a queue another process pushes is not guaranteed
to re-evaluate on the push.** The first response went out and every later one
waited for some unrelated signal to move, so each transaction timed out at
exactly its wait budget and its beats surfaced during the *next* transaction. The
signature was distinctive: failures at exactly 20001-cycle intervals. The
downstream read responder is registered now.

**`dut2` had two bugs the probes could not see**: `m_rready` held high while an
upstream beat was pending, silently dropping every second downstream beat; and
its next-upstream-beat test used the bus width instead of the beat size, so at
`size` 1 it reused stale data. The probe comparison passed it because the probes
covered eight cases; the reference covers the `size` 0..3 by `len` 0..3 grid plus
unaligned, and caught both.
