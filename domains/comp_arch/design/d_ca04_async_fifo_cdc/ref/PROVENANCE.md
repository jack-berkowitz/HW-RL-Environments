# d_ca04 `async_fifo_cdc` — provenance

## Oracle class: **A — external RTL oracle**

The checker was proven correct against **externally-authored, known-correct RTL
that nobody on this project wrote.** The claim is available for this task and is
made.

| field | value |
|---|---|
| repo | `pulp-platform/common_cells` |
| SHA | `9ca8a7655f741e7dd5736669a20a301325194c28` (tag `v1.39.0`) |
| licence | **SHL-0.51** (verified in tree) |
| file | `refs/common_cells/src/cdc_fifo_gray.sv` |
| support | `sync.sv`, `binary_to_gray.sv`, `gray_to_binary.sv`, `spill_register.sv` |
| mode | `vendor` |
| pinned in | `refs.lock` |

## The shim is a shim

`async_fifo_cdc_ref.sv` contains **no logic**: no state, no decisions, nothing
that could change behaviour. Port renaming and parameter mapping only.

Unlike `nw_d01`'s shim there is not even a polarity inversion — upstream already
uses active-low resets (`src_rst_ni` / `dst_rst_ni`) in both domains, so every
connection is wire-for-wire.

Parameter mapping: `DATA_W → WIDTH` (with `T` defaulting to
`logic [WIDTH-1:0]`), `LOG_DEPTH → LOG_DEPTH` (same 2**N convention),
`SYNC_STAGES → SYNC_STAGES`.

## The spec's reset contract is upstream's, not invented

The subtlest part of this task is reset, and the contract was taken directly
from the anchor's own header rather than guessed:

> *"This module must not be used if warm reset capability is a requirement …
> The `src_rst_ni` and `dst_rst_ni` signal must be asserted SIMULTANEOUSLY …
> The de-assertion of both reset must be synchronized to their respective clock
> domain."*

So the spec states simultaneous assertion, per-domain non-simultaneous
de-assertion, and warm reset explicitly out of scope. Requiring independent
domain reset would have demanded hardware the anchor does not have and would
have failed a correct submission.

## Second source

`tb/async_fifo_cdc_alt_ref.sv` — a classic dual-pointer async FIFO, structurally
different from upstream (single module rather than an `_src`/`_dst` split; a
real dual-port memory addressed by the read domain's own pointer rather than
exposing the whole array over an `async_data` port; standard
inverted-top-two-bits Gray full test).

**It is a falsifier, not an oracle.** It never grades a submission and the spec
is never validated against it. All 18 configs pass.

It also carries a second, unplanned role: being plain SystemVerilog, it
established that the *checker* is dual-simulator even though the *anchor* is
not. See `NOTES.md` § Simulator pinning.

## What this task's oracle does NOT cover

Stated here because it is a real limit on what a `d_ca04` result means:

The checker verifies the **functional** half of CDC correctness — Gray encoding
and decode, pointer comparison boundaries, full/empty derivation, reset
behaviour, and no loss/duplication/reordering at seven clock ratios including a
near-equal drifting one.

It cannot verify the **timing** half. Synchroniser depth is not observable in a
zero-delay event simulation: a mutant that forced `SYNC_STAGES` to 1 survived
the full suite and had to be withdrawn as functionally equivalent under
simulation semantics. Metastability is not modelled by any event simulator.
Catching that class of defect needs CDC static analysis or formal, neither of
which is in this flow.
