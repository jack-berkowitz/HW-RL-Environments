# v_ca04 `route_xbar` — build notes

Tier-B. Anchor: PULP `common_cells/src/stream_xbar.sv`, SHL-0.51, eight-file
closure.

## Why this design

Four inputs, four outputs, every input naming its own destination, and one
arbiter per output deciding between whoever turns up. A testbench cannot check
it beat by beat: it has to model, per (input, output) **pair**, which beats were
accepted and in what order; per output, how many transfers have passed since
each contender was last served; and globally, that every accepted beat is
delivered exactly once. Payloads carry their own source and sequence number, so
the true source of a delivered beat is known independently of what `out_idx_o`
claims — without that, R3 checks the design against its own assertion.

## Step 1 — semantic confirmation (measured, not read)

| question | measured |
|---|---|
| routing and source reporting | input 2 with selector 1 arrives on output 1 with `idx` 2, payload intact |
| arbitration order under a four-way tie | `0 1 2 3 0 1 2 3 0 1 2 3` — exact round robin, 3 transfers each |
| do distinct outputs run in parallel? | yes: four inputs to four outputs, `out_valid_o` 1111, all four inputs ready |
| head-of-line blocking? | none: with output 0 stalled, `in_ready_o` is 1110 — only the input bound for it stalls |
| is the decision locked in? | yes: with the output stalled, the granted index held for 8 cycles, 0 changes |

## A leak in the anchor, closed

The anchor carries built-in protocol assertions. When a testbench's stimulus
slips — dropping `valid` before `ready`, which my own first probe did — they
abort the simulation with `$stop` and print **the anchor's filename and module
path to stdout**. Two problems in one: the run produces no `RESULT` line, so the
submission fails on the *golden* and reads as "rejected correct hardware" when
the real fault is its own stimulus; and the abort names the design the task is
built on.

`AxiVldRdy` could not simply be turned off — it is passed down to `rr_arb_tree`
where it **gates the grant**, so it is functional, not just an assertion switch.
`dut/aa_asserts_off.sv` defines `COMMON_CELLS_ASSERTS_OFF` instead and is named
to sort first in the harness's lexicographic glob of `dut/*.sv`. The assertions
only check source-side obligations, which clause H2 states as obligations on the
submission.

## Step 5c — the policy-divergent perturbation

`conformant/conformant_perturbations.sv` is an **independent crossbar** — a
per-output held-beat register with an explicit scan, against the anchor's
demux-plus-arbiter-tree — taking the opposite choice on the named latitude:
it rotates **downward** (L2) and **registers every output** (L3), so a beat is
never delivered in the cycle it is accepted, where the golden's combinational
path often does exactly that.

**It passed the reference testbench on the first run.** Policy independence is
**18 of 18**: all eight defects re-derived on the divergent base are caught
there too, and both clean implementations pass.

The same artefact is wired as the second DUT (`dut2/route_xbar_alt.sv`),
generated from it so the two cannot drift. One artefact, two roles.

## Three defects the controls found in my own work

**The stimulus withdrew offers.** The first driver dropped `in_valid` at every
phase boundary — violating H2, the obligation this very spec places on the
source — and then re-presented a beat that had already been accepted. The design
took it again and the testbench reported the *design* delivering a beat twice.

**The driver missed edges.** Replacing that with a pumped loop was not enough:
every bare edge wait the stimulus did between phases, to change a ready line or
bring an input in, was an edge where a beat could be accepted unnoticed. The
driver is now an **always block**, so it services every edge regardless of what
the stimulus thread is doing.

**The stability check was off by one.** It paired *last* cycle's `valid` with
*this* cycle's `ready`, so the cycle on which a beat legitimately moved and a
stall began looked like a withdrawn offer. Both are now remembered together.

And the accept and deliver checks were merged into one ordered block: with no
register on the output path a beat can be accepted and delivered in the same
cycle, and two separate `always` blocks leave it to chance whether the accept is
recorded first — reporting an ordinary beat as "never accepted".

## The mutant that had to be earned twice

`xb_m5_lockin_off` first reported **NO DIFFERENCE OBSERVED** from the witness
harness, then **survived the reference testbench** after that was fixed.
Instrumenting rather than theorising showed why: an unlocked arbiter only
re-aims when the input already being offered **outranks** the one arriving. A
probe that brings contenders in from the lowest index upward never unseats
anything and sees nothing, however carefully it watches. The probe now brings
them in from the highest index down, on every output in turn.

## Rule 4 — coverage floors

Every floor counts **stimulus**: beats offered, phases with several inputs
contending for one output, phases with an output stalled, whether the contender
set was changed mid-stall, whether reset was asserted mid-run, and whether every
output was ever selected. None counts a DUT response, so a faulty design cannot
suppress the coverage that would convict it.

## Watchdogs

| | |
|---|---|
| TB simulation-time limit | 2 ms |
| beats offered / accepted / delivered | 616 / 616 / 616 |
| `sim_timeout_s` | 60 s |
