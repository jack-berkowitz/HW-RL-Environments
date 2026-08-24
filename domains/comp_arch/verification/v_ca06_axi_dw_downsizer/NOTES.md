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
