# nw_d01 `axis_width_adapter` — provenance

## Oracle class: **A — external RTL oracle**

The checker was proven correct against **externally-authored, known-correct RTL
that nobody on this project wrote.** This is the strong evidence path, and for
this task the claim is available and is made.

| field | value |
|---|---|
| repo | `alexforencich/verilog-axis` |
| SHA | `48ff7a7e2ef782cf778d47910cf85835c64b1bce` |
| licence | **MIT** (verified in tree: `COPYING`) |
| file | `refs/verilog-axis/rtl/axis_adapter.v` |
| mode | `vendor` |
| pinned in | `refs.lock` |

## The shim is a shim

`axis_width_adapter_ref.sv` contains **no datapath logic**: no state, no
decisions about data, nothing that could change what the adapter does. It is
port renaming and parameter mapping around the vendored module.

**One non-identity mapping, called out rather than buried:** our interface uses
active-low `rst_n` (house convention) and upstream uses active-high `rst`, so
the shim inverts it. That is a single stateless inverter on a control input — an
encoding rename, not behaviour. It is the only gate in the file.

`tid`/`tdest` are disabled upstream (`ID_ENABLE=0`, `DEST_ENABLE=0`) and left
unconnected; they are not part of this task. `KEEP_ENABLE` is derived exactly as
upstream derives it, so a 1-byte datapath degenerates to "tkeep assumed 1" the
same way it does upstream.

## Second source

`nw_d01` is on the **mandatory second-source list**. `tb/axis_width_adapter_alt_ref.sv`
is an independently written implementation making deliberately different free
choices — one unified code path instead of upstream's three branches, a circular
byte FIFO with a per-byte end-of-packet tag instead of segment registers, and a
combinational output instead of a registered one.

**It is a falsifier, not an oracle.** It never grades a submission and the spec
is never validated against it. Its only job is to fail, and it did: see
`NOTES.md` § Step 5 for the two over-constraints it caught.

## Semantic confirmation (Phase 0 + this build)

The catalog row claims "AXI-Stream up/down width conversion, `tkeep`/`tlast`/
`tuser`". Confirmed:

* upstream branches on `M_BYTE_LANES` vs `S_BYTE_LANES` into bypass, upsize
  (`SEG_COUNT = M/S`) and downsize (`SEG_COUNT = S/M`) paths;
* it elaborates and passes the byte-stream checker in all 16 legal width pairs;
* `tuser` is carried per packet and is correct on the `tlast` beat in both
  directions, which is what the spec pins down.

## Spec decisions taken here rather than inherited

The upstream module's exact `tuser` behaviour on **non-last** beats differs
between its upsize and downsize branches. Rather than transcribe one branch's
choice into the contract, the spec declares `tuser` a **per-packet** sideband:
its value is checked only on the `tlast` beat, and is explicitly unconstrained
elsewhere. That is implementation-independent, true of both upstream branches,
and true of the second source.

Throughput is deliberately **not** gated — see `NOTES.md`.
