# d_ca04 `async_fifo_cdc` — build notes

First task of **Catalog v3**, and the first two-clock design task in the project.
Verilator **5.046**; Icarus **13.0** where noted (see § Simulator pinning).

## Oracle class A

Anchored on vendored PULP `common_cells/src/cdc_fifo_gray.sv` @ v1.39.0
(SHL-0.51). The checker was proven against RTL nobody on this project wrote and
sharpened against mutants of that same RTL. The shim is renaming and parameter
mapping only — not even a polarity inversion, since upstream already uses
active-low resets in both domains.

## Spec decisions

**The reset contract came from the upstream header, not from guesswork.**
`cdc_fifo_gray` states plainly that it *must not be used where warm reset is a
requirement*, that both resets must be asserted **simultaneously**, and that
de-assertion must be synchronised per-domain. The spec therefore says:

* R1 — both resets assert together (power-on reset). The design may rely on it.
* R2 — de-assertion is per-domain and **not** simultaneous; one side may leave
  reset several cycles before the other, and the checker deliberately staggers
  them rather than assuming simultaneity.
* R3 — warm reset is **out of scope**, never exercised, unconstrained.

Writing R3 the other way — requiring independent domain reset — would have
demanded hardware the anchor does not have and failed a correct submission.

**Latency and throughput are not constrained and not checked.** Crossing latency
depends on `SYNC_STAGES` and on the ratio of two unrelated clocks, so no fixed
number could be correct. Only liveness is bounded.

**Gray coding is normative, and stated as such.** The spec requires that any
multi-bit value crossing the boundary change at most one bit per increment and
pass through `SYNC_STAGES` flops. It also warns explicitly that a plain binary
counter through a synchroniser *will appear to work in a zero-delay simulation*
— which is exactly the trap, and exactly what mutants m01/m02 exploit.

## Two checker bugs found by running, both mine

**1. Cross-domain occupancy is not a measurable quantity.** The first version
asserted `wr_idx - rd_idx <= DEPTH` as the C4 overflow check. `wr_idx` advances
in the write domain and `rd_idx` in the read domain, so sampled on `wr_clk` the
difference sees a stale `rd_idx` and **overstates** occupancy. It reported
overflow on a correct FIFO.

C4 is now enforced through its observable consequences instead — wrong data
(C1/C3 comparison), lost beats (drain-completeness per phase), or phantom beats
(C5). Those are per-beat observations in a single domain and cannot race. The
occupancy number survives as a coverage estimate only, and is labelled as such.

This is the two-clock lesson in miniature: **a checker that measures across
domains produces failures indistinguishable from CDC bugs in the DUT.**

**2. In-flight write beats moved the goalposts during drain.** Clearing `wr_en`
stops new beats being offered, but a beat already asserted and holding for
`wr_ready` (which H2 requires) is still accepted afterwards and advances
`wr_idx`. Draining against a moving target left that last beat in the FIFO, and
the end-of-phase "`rd_valid` must be low" check failed on a correct DUT. The
write side is now quiesced before `wr_idx` is snapshotted.

## Step 4 — checker passes correct RTL

**All 18 legal configs PASS with zero coverage holes** (`DATA_W` ∈ {8,32,64} ×
`LOG_DEPTH` ∈ {2,3,4} × `SYNC_STAGES` ∈ {2,3}).

Seven clock-ratio phases run per config, and all seven must complete or it is a
coverage hole:

| phase | wr half-period | rd half-period | what it targets |
|---|---|---|---|
| A | 5000 ps | 5000 ps | equal rates |
| B | 2000 | 9000 | fast write, slow read — drives full |
| C | 9000 | 2000 | slow write, fast read — drives empty |
| D | 5000 | 5100 | **near-equal, slowly drifting** |
| E | 3000 | 7000 | odd non-integer ratio |
| F | 2500 | 8000 | write burst against a lazy reader |
| G | 8000 | 2500 | starved writer, hungry reader |

Phase D is the one that matters most and it is why the timescale is `1ps/1ps`:
a 5000:5100 ratio walks the two edges slowly past each other, which is where
false-full and false-empty bugs live. It is not expressible at 1 ns resolution.

```
METRIC: beats_checked=4208 phases=7 peak_occupancy_estimate=... (DEPTH=8)
// coverage: full=10978 empty=7465 wr_stall=10978 rd_stall=2392
// coverage: phases=7 depth_reached=12734 stagger=6
TEST_RESULT: PASS
```

## Simulator pinning — the question the catalog asked

`CATALOG_V3_HARD.md` (and v2 before it) asked that a two-clock task record which
simulator it is pinned to if the two disagree. The answer is more useful than
expected:

* **The vendored anchor cannot be built under Icarus.** `cdc_fifo_gray.sv` uses
  a `type` parameter (`parameter type T`) and `(* async *)` attributes on port
  connections. Icarus 13.0 rejects both. **The reference build is pinned to
  Verilator.**
* **The checker itself is dual-simulator.** Given a plain-SystemVerilog DUT it
  builds and passes under Icarus — confirmed by running it against the second
  source, which reaches `TEST_RESULT: PASS` with 4208 beats checked under
  `vvp`.

So the limitation is a property of the *anchor*, not of the harness. A
submission — which is plain SystemVerilog — can be graded under either
simulator. Only reproducing the reference baseline needs Verilator.

## Step 5 — second source

`tb/async_fifo_cdc_alt_ref.sv` is a classic dual-pointer async FIFO:
single module rather than upstream's `_src`/`_dst` split, a real dual-port
memory with the read address driven by the read domain's own pointer rather
than upstream's "expose the whole array over an `async_data` port", and the
standard inverted-top-two-bits Gray full test.

**All 18 configs PASS.** No over-constraint found — unlike `nw_d01`, where the
second source caught two. It also did the job described above of establishing
that the harness is dual-simulator.

## Step 6 — mutation testing

Seven mutants of the **upstream anchor**, one bug each, all killed.

| id | class | injected bug | killing check |
|---|---|---|---|
| m01 | cdc-encoding | write pointer crosses as **binary, not Gray** | C5 phantom beat |
| m02 | cdc-encoding | read pointer crosses as binary, not Gray | C1/C3 data mismatch |
| m03 | boundary | full test compares against `PtrFull>>1` | C1/C3 data mismatch |
| m04 | control-flow | empty test inverted | C5 phantom at beat 0 |
| m05 | cdc-encoding | Gray **decode** skipped in the read domain | C5 phantom beat |
| m06 | boundary | payload written one entry past the pointer | C1/C3 data mismatch |
| m07 | reset | write pointer resets to 1 instead of 0 | C5 phantom at beat 0 |

### One mutant was withdrawn, and the reason is the most important finding here

The original m05 forced the synchroniser depth to a single stage
(`sync #(.STAGES(1))`). **It survived, and it should have.** Reducing
synchroniser depth does not change any logical value in a zero-delay RTL
simulation — it only shortens pointer latency, and this FIFO's full/empty tests
are pessimistic, so a shallower synchroniser is still functionally correct *in
simulation*. Metastability, the thing extra stages actually buy, is not
modelled by an event simulator at all.

So it is not a valid mutant for a simulation-based checker: it is functionally
equivalent under the semantics the checker can observe, and per the catalog's
own rule an equivalent mutant is not a bug and silently caps the kill rate. It
was replaced with a Gray-**decode** bug — same subsystem, genuinely observable.

**This bounds what `d_ca04` can score.** The checker verifies the *functional*
half of CDC correctness — Gray encoding, pointer decode, full/empty boundaries,
reset — and cannot verify the *timing* half: synchroniser depth, and whether
the crossing paths are constrained at all. A submission that used a 1-deep
synchroniser, or passed a plain binary pointer with enough luck in the encoding,
would pass this checker and fail in silicon. Catching that needs CDC static
analysis or formal, neither of which is in the flow. It should be stated when
`d_ca04` results are reported rather than left implicit.

The SDC does carry the upstream-prescribed crossing constraints
(`set_clock_groups -asynchronous`, `set_max_delay min(T_src,T_dst)`,
hold checks disabled), so the *reference* build is constrained correctly — but
nothing checks that a submission's crossings are.

## Step 7 — PPA

Two-clock SDC, and deliberately not the single-clock template with a second
`create_clock` bolted on: the domains are declared asynchronous to each other,
or STA reports every pointer crossing as a huge violation and the numbers mean
nothing. Crossing paths are bounded with `set_max_delay min(T_src,T_dst)` and
have hold checks disabled, per the anchor's own documented recipe.

Write clock 10 ns, read clock 13 ns, deliberately non-integer-ratio.

### Result — sky130hd, DATA_W=32 LOG_DEPTH=3 SYNC_STAGES=2

| metric | value |
|---|---|
| design area (post-route) | **19 695 µm²** (13 % utilisation) |
| synthesised module area | 15 361 µm² |
| WNS | **+5.22 ns** — closes |
| TNS | 0.00 |
| total power | 6.26 mW |
| write clock | 10 ns |
| read clock | 13 ns (deliberately non-integer ratio) |
| flow | completed to `6_finish` |

Closes on both domains. Area is ~6× `nw_d01`'s 3 115 µm², which is the expected
shape: the storage array plus two Gray pointer paths and their synchroniser
chains, against a width adapter's muxing.

**One SDC failure worth recording.** The first attempt used
`remove_from_collection` to exclude the clock ports from `all_inputs`. That is a
Synopsys DC command; OpenSTA does not implement it, and synthesis died at
`read_sdc` with `invalid command name`. Replaced with explicit per-domain port
lists, which is also more accurate — `rd_ready` and `rd_rst_n` genuinely belong
to the read domain and were previously being constrained against the write
clock.


## Open items

* PPA build result pending.
* The CDC timing-verification gap above is inherent to a simulation-only flow
  and is the main thing I would want a second opinion on before scoring this
  task.
