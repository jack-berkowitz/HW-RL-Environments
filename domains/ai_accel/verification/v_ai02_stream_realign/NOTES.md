# v_ai02 `stream_realign` — build notes

Tier-B. Anchor: PULP `hwpe-stream/rtl/streamer/hwpe_stream_source_realign.sv`,
SHL-0.51, four-file closure.

## Why this design, and why not the ones the catalog names first

The catalog points at "streamer split/merge/fifo". Those turned out to be the
wrong targets:

- **`hwpe_stream_split`** and **`hwpe_stream_merge`** are correct but purely
  combinational — a broadcast valid, a sliced payload and an AND of the readys.
  There is no state for a testbench to model.
- **`hwpe_stream_serialize`** is not usable. At `MODE=0` its `stream_cnt_en`
  gates `push_valid` off while the contiguous counter is below its limit, and
  that counter only advances on a transfer — so for any non-zero `nb_contig_m1`
  it **deadlocks by construction**. It was not built on.

`source_realign` is the one unit here with a real model behind it: it carries
bytes across beat boundaries so that a line which does not start on a beat
boundary is delivered as whole beats. A testbench has to model the rotation, the
beat being held, and the byte stream itself.

## Step 1 — semantic confirmation (measured, not read)

| question | measured |
|---|---|
| `realign_i` low | three beats pass through untouched |
| offset 1 (`strb_i` = 1110) | output bytes `01 02 03 04` then `05 06 07 08` — the line starts at byte 1 |
| offset 2 (`strb_i` = 1100) | output bytes `12 13 14 15` then `16 17 18 19` |
| beats out vs beats in | one fewer: a line's first beat is retained and produces nothing |

### The rotation is a popcount, and it is not taken modulo the beat width

`strb_rotate` is the **number of set bits** in the strobe, 0 through 4. A full
strobe gives **4**, not 0: the join then shifts by a whole beat and the output
is the *retained* beat, so the stream is delayed by exactly one beat and the
line begins at byte 0. An empty strobe gives 0, the current beat passes
straight through, and the line begins at byte 4 — the first beat is skipped
outright.

**My first model truncated this to two bits**, collapsing 4 onto 0, and got the
aligned case exactly backwards — it expected the current beat where the design
correctly gives the held one. Instrumenting the internals settled it in one run
after my arithmetic about the width truncations had twice disagreed with itself.

### `strb_i` has two distinct roles

It fixes the rotation at a line's first beat (R4), **and** on every beat it
gates whether an output is produced at all: `pop_valid` also requires `last_i`
or a non-zero `strb_i`. Driving an empty strobe through a whole line therefore
suppresses every output but the last. The specification says so now; the first
draft did not, and the reference testbench found it.

## Step 5c — the policy-divergent perturbation

`conformant/conformant_perturbations.sv` is an **independent implementation** —
an explicit popcount and a case-selected join, against the anchor's barrel
shifter with its width-truncated shift amounts — taking the opposite choice on
both named latitude clauses: **every beat waits for the sink**, the first one
included (the golden takes a line's first beat regardless, since it produces no
output), and it drives a fixed pattern on the output payload while `pop_valid_o`
is low.

It passed the reference testbench on the first run. **Policy independence is
18 of 18**: all eight defects re-derived on the divergent base are caught there
too, and both clean implementations pass.

It is also wired as the second DUT (`dut2/stream_realign_alt.sv`), generated
from the same source so the two cannot drift.

## Ports the port map does not carry

`strb_valid_i` and `line_length_i` are read **only** on the anchor's `DECOUPLED`
path, which this configuration does not pin. They are dead here, so they are not
in the port map: a port the design never reads is a port map that lies. `enable`
and `last_packet` are pinned inside the shim for the same reason — each opens a
behaviour axis this task does not scope.

## Step 5 — negative controls

**(b)** `negctl/stuck_dut.sv` (all four outputs tied low, generated from the
port map) and `negctl/reset_polarity_dut.sv` are both caught naming clauses X3
and R2, not by the watchdog.

**(a)** `negctl/null_tb.sv` is reported INVALID and EXCLUDED FROM SCORING by the
gate-mutant.

## Rule 4 — coverage floors

Every floor counts **stimulus**: beats offered, realigned lines driven, whether
the input strobe was ever partial, whether the sink was ever stalled, whether
pass-through was exercised, whether a line ended on an empty strobe, and whether
each of the five rotations was driven. None counts a DUT response.

## The difficulty pivot — the mutant set was rebuilt

The previous set was **total**: every defect held on every transaction of its
class, so it fired on the first one a testbench happened to drive. Catching it
required exercising the class, not checking the clause, and a submission that
passed the validity gate collected most of the set for free. The set was
measuring coverage and reporting it as verification.

The set is now **uniformly guarded** — ten defects, each a wrong behaviour
paired with a rare predicate over contract-level state. `mutants/README.md`
carries the guard for each.

The reference reached **three of ten** when the guarded set was first generated.
Seven phases were added to it rather than loosening the guards, because a mutant
the reference cannot reach is unverified rather than difficult: three lines run
without a clear between them, a strobe that changes popcount inside a line, a
stall taken while an output is actually being offered, a six-beat line ending on
an empty strobe, an empty strobe on a middle beat, a partial strobe on a last
beat, and pass-through exercised after realigning rather than before.

### L4, and the beat that is silently consumed

Driving an empty strobe deep inside a line made the reference fail the GOLDEN.
The anchor **retains** a silently consumed beat, so the next output joins
against it; the reference had assumed the previous retained beat stays. R5
already withheld byte-preservation from any line containing such a beat, but
nothing said what the retained beat becomes. That is now **L4**, and both
readings are conforming — the independently written implementation in
`conformant/` takes the other one. What L4 does not free is the COUNT: R2 is an
"if and only if", so no output beat is owed there under either reading, which is
exactly what `sr_m9` violates.

### An equivalent mutant, caught before it shipped

A defect that ignored `clear_i` from the second clear onward turned out to be
unobservable at this configuration: the only clear-sensitive state is the
rotation and the retained beat, and R1 makes the next line's first beat
overwrite both. It was replaced. A mutant nothing can detect is not difficult,
and it would have been scored against submissions as though it were.

### Step 5c earned its place again

`sr_m4` passed on the policy-divergent base. That base makes every beat wait for
the sink — the opposite choice on L1 — so the reference's stall, taken before
the line had produced anything, left `pop_valid_o` low: nothing was offered, so
nothing was being held off. The stall was real on the golden and imaginary on
the other implementation. The reference now waits for output beats before
stalling. 22 of 22.

## Watchdogs

| | |
|---|---|
| TB simulation-time limit | 2 ms |
| beats offered / accepted / output | 64 / 63 / 51 |
| `sim_timeout_s` | 60 s |
