# d_ca06 — build notes

## What this task is, and why it is different

A FIFO with three write ports and three read ports, all of which may be active
in the same cycle. Ordering is global.

**It is the only design task in the corpus with no vendored anchor.** Every
other one wraps upstream RTL at a pinned commit, so "correct" means agreeing
with hardware that people tape out, and the anchor is an authority independent
of whoever wrote the spec. Here the reference was hand-written and the contract
was derived *from* it.

That is a real weakening and it is worth stating plainly rather than in a
footnote: the spec and the reference have the same author, so a misreading
present in both cannot be caught by comparing them. Two things partly offset it,
and neither fully:

* the scoring testbench's behavioural model is written from the **spec**, not
  from the reference RTL, so the two agreeing is evidence the spec describes the
  implementation;
* the three negative controls establish that the scored surface discriminates.

Neither shows the *contract* is the right one, only that it is self-consistent.

## Every clause was measured, not assumed

The spec was written after probing the reference, because two of its behaviours
contradict the obvious design:

**Writes compact.** `write_valid = 3'b101` on an empty queue stores port 0 at
tail and port 2 at tail+1 — no gap for the idle port. Measured: `rd0=a0`,
`rd1=c2`.

**Reads do not.** With four entries `[11,22,33,44]` and `read_accept = 3'b101`,
head advances by **three** — past the highest accepted index, not by the count
of accepted reads. Entry `22` is never read and is gone. Measured: afterwards
`read_valid = 3'b001` and `read_data[0] = 44`.

So `read_accept` must be a prefix for every entry to be observed, and a
non-prefix accept silently loses data. The reference does not flag it.

**Acceptance ignores validity.** `write_accept[i] = i < vacancy` — it does not
read `write_valid`. On an empty queue with nothing offered, `write_accept` is
all ones. Port `i` needs `i+1` free slots even when the lower ports are idle.

## Why the negative controls are the ones they are

`nc_a_reads_compact` is the design a model is most likely to write: head
advancing by the count of accepted reads, so a non-prefix accept loses nothing.
It is the clause the task exists to test, and it fails on 10,578 mismatches.

`nc_b_accept_uses_valid` makes acceptance depend on `write_valid`, which is the
more *useful* design — it accepts strictly more traffic. It fails on 183
mismatches, all on `write_accept`, and the small count is the point: the
divergence only shows when a high port is offered against low vacancy.

`nc_c_writes_dont_compact` writes to `tail + i`, leaving a gap for an idle low
port. 3,968 mismatches.

## The synthesis shim

`ref/queue_top.sv` pins the scored geometry — `PTR_WIDTH=4`, `T=logic[31:0]`,
`PORTS=3` — because ORFS's `VERILOG_TOP_PARAMS` sets *value* parameters only and
`T` is a **type** parameter. A config line could not pin the width at all; it
would silently synthesise the module's own default `logic[63:0]` at `DEPTH=128`,
8,192 storage flops instead of 512, and label it the scored number. That is
d_ai01's drift defect with no way to express the fix in the config, so the
geometry lives in a file the build reads.

The scored geometry is deliberately smaller than the module's defaults: at 7 and
64 the design is 8,192 flops and three 128:1 64-bit muxes, which is a
place-and-route of a memory rather than a measurement of a queue.

## What is not done

The reference Fmax sweep has not run, so there is no pin, and under the pin rule
no candidate may be solicited until one is written into the spec. `task.yaml`
records both as NOT YET.
