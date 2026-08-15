# nw_d01 `axis_width_adapter` — build notes

Verilator **5.046** and Icarus **13.0** (pinned in `refs.lock`) for every result
below.

## Oracle class A — the strong claim is available here

Unlike `ai_d01`, this task **is** anchored on externally-authored RTL:
Forencich `verilog-axis` @ `48ff7a7e…` (MIT), vendored at
`refs/verilog-axis/rtl/axis_adapter.v`. The checker was proven correct by
running it against RTL nobody on this project wrote, and proven sharp against
mutants of that same RTL. See `ref/PROVENANCE.md`.

## Spec decisions

**The contract is a byte-stream contract, not a beat contract.** Beats are an
artifact of the bus width; what must survive is the packet and its bytes. The
scoreboard therefore records the keep-enabled bytes of every accepted input beat
and compares the keep-enabled bytes of every accepted output beat in order. It
models nothing about segments or pipelining — those are exactly the free choices
a width adapter is allowed to make differently.

**`tuser` is specified as a per-packet sideband.** Upstream's own upsize and
downsize branches differ in what they present on non-last beats. Rather than
transcribe one branch's arbitrary choice into the contract, the spec checks
`tuser` only on the `tlast` beat and declares it unconstrained elsewhere. True
of both upstream branches and of the second source.

**Throughput is measured but NOT gated.** A throughput floor would encode one
implementation's pipelining into the contract and fail a differently-structured
correct adapter. Only correctness and liveness gate the verdict; throughput
prints as a `METRIC`.

**Input preconditions are stated and the checker obeys them.** `s_keep` is
contiguous from bit 0, only the last beat of a packet may be partial, and
`s_keep` is never all-zero. The checker must honour the contract it requires of
a producer — see § Step 5, where breaking it produced two false failures.

## Sizing

`S_BYTES`, `M_BYTES` ∈ {1,2,4,8}; with that set every one of the 16 pairs
satisfies the divides-evenly constraint, including pass-through. No
DEPTH×DEPTH comparison sweep exists here, so none of the synthesis blowup risk
that forced the `lsq` and cache cuts applies.

**A PPA baseline at one (S,M) is not comparable to another** — both the datapath
width and the segment count change.

## Step 4 — checker passes correct RTL

**All 16 width pairs PASS, zero coverage holes.** Verilator on all 16; Icarus
cross-checked on 1→4, 4→1, 2→8, 8→2, 4→4 and agreeing on every one.

Representative run (S=1, M=4):

```
METRIC: packets=901 bytes=18584 out_beats=5131
METRIC: active_cycles=30927 beats_per_100cyc=16
METRIC: backpressure_cycles=3039 input_stall_cycles=2437
// coverage: partial_last=711 full_last=260 single_beat=100 multi_beat=871
// coverage: bp=3039 in_stall=2437 reset_mid=1 gap=4708 minpkt=19 bigpkt=754
// coverage: reset_pending=1
TEST_RESULT: PASS
```

Icarus needed one change: `inside` expressions in the illegal-parameter guard
are unsupported, replaced with explicit comparisons.

## Step 5 — second source, and the two over-constraints it caught

**This is the step that earned its keep.** `tb/axis_width_adapter_alt_ref.sv`
is structurally different by design:

| upstream | second source |
|---|---|
| three code paths (bypass / upsize / downsize) | one path for every ratio |
| segment counter + segment-indexed assembly registers | circular byte FIFO with a per-byte end-of-packet tag |
| registered output, latency ≥ 1 | combinational output off FIFO state |
| `tlast` tracked as a beat attribute | `tlast` tracked as a **byte** attribute |

It failed the checker twice, and both times **the checker was wrong**:

1. **`cov_in_stall` was a coverage gate.** It required the DUT to deassert
   `s_ready` at least once. That is a requirement on how deeply the DUT buffers,
   and the spec constrains buffering nowhere — R2 says `s_ready` may be 0 or 1
   and says nothing about depth. The second source's 32-byte FIFO simply never
   fills when upsizing from `S_BYTES=1`, so it never backpressures and was
   failed for being *too good*. Demoted to a `METRIC`.

2. **`D8` demanded the DUT hold a completed output beat under backpressure.**
   A zero-storage pass-through cannot — and upstream's own `S==M` branch is
   exactly that, wiring `s_ready = m_ready` straight through. The precondition
   is now probed and recorded, and the coverage gate applies only where it is
   reachable.

Both are the same error: asserting a property of the *implementation* that the
spec never promised. Without the mandatory second source, both would have
shipped, and both would have failed correct submissions.

After the fixes: **all 16 pairs PASS for the second source, and all 16 still
PASS for the upstream reference.**

## Step 6 — mutation testing

Seven mutants of the **upstream reference RTL** (not of the shim), one bug each.
All elaborate and simulate. Upsize-branch mutants are inert in downsize configs
and vice versa, which is expected — a mutant must be killed in at least one
legal config, and each is.

| id | class | injected bug | killed in | diff rate |
|---|---|---|---|---|
| m01 | control-flow | upsize segment completion ignores `tlast`, so a packet ending mid-segment never closes its beat | S1→M4, D4 | 4 875 ppm |
| m02 | boundary | upsize segment compare `SEG_COUNT` instead of `SEG_COUNT-1` | S1→M4, D4 | 58 710 ppm |
| m03 | protocol-tlast | downsize buffered path clears `tlast` instead of propagating it, merging packets | S4→M1, D4 | 17 066 ppm |
| m04 | boundary | downsize end-of-beat test shifts one segment too far | S4→M1, D4 | 432 234 ppm |
| m05 | protocol-backpressure | `s_ready` asserted unconditionally, overwriting the skid buffer | S1→M4, D4 | 989 199 ppm |
| m06 | reset | reset clears the segment counter and input valid but **not** the output valid | S1→M4, **D8** | **11 ppm** |
| m07 | staleness | upsize latches the buffered `tuser` even when taking data straight from the port | S1→M4, D4 | 462 360 ppm |

### m06 survived, and fixing it is the most useful thing in this table

`m06` initially **survived every config**. The reason is precise: `D7` resets
mid-*packet*, when the adapter is still assembling and `m_valid` is low — so a
reset that fails to clear the output-valid register has nothing to preserve and
goes unnoticed. `D8` was added to back the output up until `m_valid` is
genuinely high and only then reset. `m06` now dies there deterministically.

**`m06` is also the sharpest argument that diff rate ≠ difficulty.** It diverges
on 11 ppm of cycles — about one cycle in ninety thousand — and is essentially
unreachable by random stimulus. It is killed reliably anyway, because a
*directed* check goes looking for exactly that state. A mutant set tuned on diff
rate alone would have discarded it as unkillable.

Writing `D8` also produced two false failures that were my bugs, not the DUT's,
and both are worth recording because a zero-storage pass-through exposes them
instantly: the probe loop initially **changed `s_data` while `s_valid` was high
and unaccepted**, and later **withdrew `s_valid` from an unaccepted beat**. Both
violate H2, the input contract the checker itself promises to honour, and a
combinational bypass faithfully propagates the violation to its output where the
H3 check blames the DUT. The checker must obey its own preconditions.

### Diff-rate band — now with two modules of data

`ai_d01` spread 0.18 %–56 %; `nw_d01` spreads **0.0011 %–98.9 %**.

* **m05 at 98.9 %** and **m04 at 43 %** are filler by the prompt's definition —
  they diverge on most or many cycles and any submission that looks at the
  output at all will catch them.
* **m06 at 11 ppm** sits below any sane floor and is nonetheless a good mutant.

So a diff-rate band applied as an automatic filter would reject the *best*
mutant here and keep the worst. My revised proposal: **use diff rate as a
report-only diagnostic, not a gate.** If a threshold is wanted, flag anything
above ~25 % for review as probable filler, and flag nothing at the bottom — a
very low rate is a signal to check that a *directed* test kills it, not a reason
to discard it. Recommend confirming against `ca_d08` before adopting.

## Step 7 — PPA baseline

sky130hd, 20 ns period, matching the house Tier-One designs so the number is
comparable. Synthesised at the shim's default **S_BYTES=1, M_BYTES=4**.
`ABC_CLOCK_PERIOD_IN_PS` is derived from this design's own SDC, so it cannot
drift and cannot hand ABC a 20 ps target. `VERILOG_FILES` lists both the shim
and the vendored upstream RTL — the shim alone has no logic.

### Result — sky130hd, S_BYTES=1 → M_BYTES=4, 20 ns target

| metric | value |
|---|---|
| design area (post-route) | **3 115 µm²** (15 % utilisation) |
| synthesised module area | 2 079 µm² |
| WNS | **+14.30 ns** — closes with room to spare |
| TNS | 0.00 |
| total power | 245 µW |
| sequential cells | 52 |
| reg→reg min period | 2.07 ns (fmax 483 MHz) |
| flow | completed to `6_finish`, exit 0 |

**It closes timing**, unlike `ai_d01`. Worst slack is +14.30 ns against a 20 ns
period, and reg→reg supports 483 MHz. That is the expected shape for this block:
the adapter is control logic and muxing over a narrow datapath with no
arithmetic in the path, so the clock target is nowhere near binding.

### What this pair says about PPA as a scoring axis

Set against `ai_d01` (275 995 µm², WNS −6.41 ns) the two tasks sit at opposite
ends, and that is useful rather than awkward:

| | `ai_d01` int8_requant | `nw_d01` axis_width_adapter |
|---|---|---|
| area | 275 995 µm² | 3 115 µm² |
| timing at 20 ns | **fails**, −6.41 ns | **closes**, +14.30 ns |
| binding constraint | combinational arithmetic depth | none at this period |

`ai_d01` discriminates on timing closure — a naive un-pipelined design fails and
a pipelined one wins. `nw_d01` will not: at 20 ns essentially any correct
implementation closes, so its PPA signal is **area and power only**, and the
scoring for it should lean on those. If timing is wanted as a live axis for
`nw_d01`, the period has to come down a long way (reg→reg min period is 2.07 ns);
that is a scoring decision, not something to change quietly here.


## Open items

* Nothing blocking.
* The diff-rate recommendation above changed materially between `ai_d01` and
  `nw_d01`. Worth one more module before adopting anything.

---

# RE-DERIVATION — the reference had never passed the correctness gate

`ref/sim_flags_verilator.txt` was **empty**, so the vendored `verilog-axis`
search path the shim needs was never passed and the reference failed all 16
configs on `MODMISSING`. Every earlier "candidate beats reference" statement for
this task therefore compared a **gated candidate against an ungated reference**.

Fixed. Both now pass the same gate: **reference 16/16, candidate 16/16.** The
correctness side is sound. What changes is the PPA interpretation.

## Three-way decomposition, same as d_nw01

### 1. Off-spec configuration — CLEAN

Unlike `d_nw01`, where this shim chose `CUT_ALL_AX` and handed the reference 45 %
of its area in pipelining the spec never required, this shim sets
`ID_ENABLE = 0` and `DEST_ENABLE = 0`. The vendored adapter carries no feature
here that the spec did not ask for. **No off-spec area.**

### 2. Capability gap — REAL

Rig: `tb/audit/axis_width_adapter_capability_rig.sv`. Both sides saturated, no
backpressure, so the DUT is the only limit.

| S→M | reference | candidate | candidate / reference |
|---|---|---|---|
| 1→1 | 1000 | 500 | **0.50** |
| 1→4 | 1000 | 800 | 0.80 |
| 2→2 | 2000 | 1000 | **0.50** |
| 4→4 | 4000 | 2000 | **0.50** |
| 8→8 | 8000 | 4000 | **0.50** |
| 8→4 | 4000 | 2666 | 0.67 |

bytes per 1000 cycles. **At matched widths the candidate sustains exactly half
the reference's throughput** — the signature of a design that cannot accept a
new input beat while emitting an output beat. The narrow-to-wide cases follow
`k/(k+1)`: it spends one extra cycle per output beat.

Stalling is legal and the spec deliberately permits a zero-storage bypass, so
every correctness config still passes. This is a capability difference, and
nothing in the checker sees it.

### 3. Genuine optimisation — ESSENTIALLY NONE

PPA at the built config, **S_BYTES=1 M_BYTES=4**, where the candidate runs at
0.80 of the reference's rate:

| metric | reference | candidate | |
|---|---|---|---|
| synth area | 2 079 µm² | 2 117 µm² | candidate **1.8 % larger** |
| design area (post-route) | 3 115 µm² | 3 014 µm² | candidate 3.2 % smaller |
| total power | 245 µW | 184 µW | candidate 25 % lower |
| WNS | +14.30 ns | +13.71 ns | candidate slightly worse |

The two area numbers **disagree in sign** — the candidate is larger by synthesis
and smaller after place-and-route, both by about 3 %. That is noise, not a win.

Normalising for the throughput it actually delivers:

| | reference | candidate | |
|---|---|---|---|
| area per unit throughput | 3.12 | 3.77 | candidate **21 % worse** |
| power per unit throughput | 0.245 | 0.230 | candidate 6 % better |

## What this means for the v3 rebuild premise

`CATALOG_V3_HARD.md` opens by saying the rebuild was triggered because *a
frontier model beat the upstream reference on area and power for `nw_d01`*.
**That claim does not survive this re-derivation.** The area result is
noise-level and sign-dependent on which number is quoted, and the power result
is substantially a consequence of doing 20 % less work per cycle — normalised,
the candidate is worse on area and roughly level on power.

This does **not** invalidate the v3 rebuild: those tasks are harder and more
discriminating on their own merits, and the capability audits have earned their
place. But the specific empirical claim in the catalog's opening paragraph
should be corrected rather than repeated.

**Neither `nw_d01` nor `d_nw01` contains a demonstrated optimisation win.** In
both cases the apparent advantage decomposed into off-spec configuration
(d_nw01) or reduced capability (both), with nothing left over.

## Caveat that applies to every number above

WNS is **+14.30 ns and +13.71 ns** — the clock never bound, so neither design
was pushed and neither was optimised against a real constraint. These numbers
are not evidence about difficulty until rerun at a binding period.
