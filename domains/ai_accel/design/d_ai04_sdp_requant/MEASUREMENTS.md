# d_ai04 — step-0 anchor conformance audit

Anchor: `refs/nvdla_hw/vmod/nvdla/sdp/NV_NVDLA_SDP_CORE_Y_cvt.v`
(2,721 lines, 18 modules in one file, top at 2661, zero external dependencies)

Elaboration: `verilator --lint-only --top-module NV_NVDLA_SDP_CORE_Y_cvt`
→ **0 errors, 0 MODMISSING, 3 warnings.**

## Why every clause below is a measurement

The anchor is **Catapult HLS output**. Its readable part is the Mentor library
wrappers; the arithmetic is machine-generated. **The source is not a
specification and was not used as one.** F54 is the precedent from the other
direction: d_dsp01 satisfied rule 11 exactly, its anchor turned out to be
correctly rounded in no mode but RTZ, and the task was withdrawn rather than
faked. Every line below comes from a probe under `tb/audit/`.

The one exception, marked as such: the **handshake direction** is read, not
measured, because the wrappers are library code rather than synthesis output.
Both `SDP_Y_CVT_mgc_in_wire_wait_v1` and `SDP_Y_CVT_mgc_out_stdreg_wait_v1` are
pure passthroughs (`assign d=z; assign lz=ld; assign vd=vz;`), so `vz` is always
the incoming signal and `lz` always the outgoing one:

| port | dir | meaning |
|---|---|---|
| `chn_in_rsc_vz`  | in  | producer VALID |
| `chn_in_rsc_lz`  | out | design READY |
| `chn_out_rsc_vz` | in  | consumer READY |
| `chn_out_rsc_lz` | out | design VALID |

Probe 1 then confirmed this by getting a word through it, so it is not resting
on the reading alone.

## The measured contract

**Lanes.** 4 × 16b in → 4 × 32b out, one output word per input word, in order.

**`cfg_precision` selects between two unrelated behaviours.** Codes 0, 1 and 3
are **byte-identical to each other** on every vector tried; code 2 is a different
operation entirely.

### Integer modes (precision 0, 1, 3)

    out = sat_int32( round_nearest_ties_away( (x - offset) * scale / 2^truncate ) )

with `x` signed 16b, `offset` **signed 32b and SUBTRACTED**, `scale` signed 16b,
`truncate` 0–63. `bypass=1` gives `out = sext32(x)` with all config ignored.
`nan_to_zero` does nothing here.

### Float mode (precision 2)

    out = fp16_to_fp32(x)

`offset`, `scale`, `truncate` and `bypass` are **all ignored** — separately
confirmed, one vector each. `±inf` is **clamped to ±FLT_MAX**, not propagated.
NaN → NaN with the payload in the low mantissa bits; `nan_to_zero=1` → `+0`.

### Flow control

latency 1 cycle · sustained II = 1 · **capacity 3 words** behind a fully stalled
consumer · ready is **registered**, with no same-cycle path from `chn_out_rsc_vz`
· lossless and order-preserving across a stall.

## Evidence

| clause | vector | expected if… | measured |
|---|---|---|---|
| offset SUBTRACTS | x=4 off=3 sc=1 | add → 7 | **1** |
| " (independent, 3 params) | x=4660 off=291 sc=37 tr=3 | add → 22898 | **20207** = (4660−291)·37/8 |
| ties away from zero | x=±3, ±7, ±1 at t=1 | half-up → −1 for −3 | **±2, ±4, ±1** |
| " not an arith shift | x=−9 t=2 (−2.25) | `>>>` → −3 | **−2** |
| " again, far out | x=−32768 sc=32767 t=63 | `>>>` → −1 | **0** |
| saturates int32 | (32767+65535)·32767 | wrap → 0xBFFE7E82 | **0x7FFFFFFF** |
| subtraction not pre-clipped | 0 − (−2^31) | wrap → 0x80000000 | **0x7FFFFFFF** |
| **full product kept ≥48b** | 0−(−2^31), sc=32767, t=46 | 32b intermediate → 0 | **1** |
| " | same, t=45 | → 0 | **2** |
| p2 is fp16→fp32 | 0x3C00 / 0x4100 / 0xC200 / 0x3800 | — | **1.0f / 2.5f / −3.0f / 0.5f** |
| p2 clamps inf | 0x7C00 (+inf) | propagate → 0x7F800000 | **0x7F7FFFFF** = FLT_MAX |
| nan_to_zero is float-only | 0x7E00, n2z=1, p0 | zeroed → 0 | **32256** (untouched) |
| bypass is int-only | 0x4100, byp=1, p2 | raw → 0x00004100 | **0x40200000** |
| p0 ≡ p1 ≡ p3 | x=4660 off=291 sc=37 t=3 | differ | **20207, 20207, 20207** |
| capacity | consumer stalled throughout | — | **3**, then 0 further, drains 3/3 in order |
| ready not combinational | toggle out_rdy within a cycle | comb → ready moves | **unchanged** |

## One correction to `docs/DESIGN_TASK_LANDSCAPE.md`

That document names the discriminating mechanism as *"the saturation bound
depends on the precision mode."* **Measurement refutes it.** Saturation is
int32 in every integer mode, and the integer modes are indistinguishable from
one another. The claim came from reading port names, which is the practice this
audit exists to avoid. The real discriminators are different ones, below.

## Viability

**VIABLE**, and on more axes than the landscape credited:

1. **derived width** (Mechanism A) — the product must be ≥48b and saturation
   applied *after* the shift. A 32-bit intermediate passes every small vector.
2. **rounding rule** (A/C) — the natural implementation `(v + (1<<(t-1))) >>> t`
   is round-half-**up** and is wrong on every negative tie. Measured behaviour is
   ties-**away**. This is d_dsp01's question asked of a block that answers it.
3. **registered ready at II=1** (B-adjacent) — a single output register gives
   II=1 on open flow and loses a word on the stall boundary. The third slot is
   invisible on the delivered surface and appears only at a stall edge.
4. **mode disjointness** — `bypass` int-only, `nan_to_zero` float-only, and in
   p2 the entire requant config inert. Four separate "does nothing here" clauses.
5. **inf → FLT_MAX** — nobody writes that unless the spec says so.

Item 3 is the reason this is not a pure Mechanism-C arithmetic task.

## Not measured

- whether p0/p1/p3 diverge on any vector at all (they did not on those tried;
  the difference is likely upstream lane packing, which is outside this module)
- the fp16 subnormal boundary, and fp32 rounding for values needing it
- reset behaviour mid-stream
- per-lane independence beyond "all four lanes carried the same value"

## The probes had the defect they were built to avoid

A2 found that `check_artefact_warnings.py` returned *"OK: no task-owned artefact
drew a warning"* when handed an **empty log** — true, useless, and identical to
a clean build. Their reading: validating an instrument against the inputs it was
designed for is not validating it, and the input that is neither a defect nor a
repair is where it breaks.

**Probes 2, 3 and 6 have that defect.** Their `shot()` task prints a `MEASURE:`
row unconditionally; on timeout the wait loop breaks and the row renders anyway,
in the shape of a result. Nothing in it says whether a transfer occurred.

It is worse than predicted. The expectation was that `got = 128'hx` would print
as `xxxxxxxx` and be visibly broken. **Verilator is 2-state, so `128'hx` is
zero, and a timed-out vector prints `0x00000000`** — demonstrated in probe 7
part A, which runs a real vector with the consumer held un-ready and shows the
old form and the new form side by side:

    OLD FORM  -> 0x00000000 (0)      <-- a data-shaped row, no transfer occurred
    degenerate   NO TRANSFER in 200 cycles -- THIS IS NOT A MEASUREMENT

**Zero is inside this DUT's legitimate output range**, so under the old form a
timeout and a genuine zero were byte-identical rows.

### One committed evidence row was at risk, and it was the load-bearing one

    | " again, far out | x=−32768 sc=32767 t=63 | `>>>` → −1 | **0** |

That row measured exactly 0, and it is one of the three independent
confirmations that the rounding is to-nearest rather than an arithmetic shift —
it is the one that separates them, since floor of a tiny negative is −1 and
nearest is 0. If it had been a timeout, the shift-versus-nearest conclusion
would have rested on two rows, not three.

**Re-verified with a transfer counter: `xfers=1`, `0x00000000` on all four
lanes. The row stands.** Probe 7 part B re-runs the six load-bearing rows with
transfer counts printed beside each; all six report `xfers=1`.

### Two expectations in that re-check were mine and were wrong

The re-check carried two control vectors whose predicted values I miscalculated,
and the anchor was right both times:

| vector | predicted | actual | who was wrong |
|---|---|---|---|
| x=−32768 sc=32767 t=40 | −1 | **0** | mine — −1073709056/2^40 ≈ −0.00098, which rounds to 0 |
| x=−32768 sc=32767 t=30 | −1000 | **−1** | mine — the quotient is −0.99997, not −1000 |

Neither changes a clause. They are recorded because the same arithmetic produced
the predictions in the evidence table above, and a reader is entitled to know
the error rate of the hand that wrote them.

## Float-mode edges, measured before the spec was written

`Not measured` above listed *"the fp16 subnormal boundary"*. A spec clause
covering a case nobody measured is the d_dsp01 failure with extra steps, so
probe 8 pinned them first. All fifteen vectors carry a transfer count.

| case | in | out | reading |
|---|---|---|---|
| ±zero | `0x0000` / `0x8000` | `0x00000000` / `0x80000000` | signed zero preserved |
| smallest subnormal | `0x0001` | **`0x33800000`** | 2⁻²⁴ **exactly** — not flushed |
| mid subnormal | `0x0200` | `0x38000000` | exact |
| largest subnormal | `0x03FF` | `0x387FC000` | exact |
| negative subnormal | `0x8001` | `0xB3800000` | exact, sign preserved |
| smallest normal | `0x0400` | `0x38800000` | 2⁻¹⁴ |
| largest normal | `0x7BFF` / `0xFBFF` | `0x477FE000` / `0xC77FE000` | ±65504 |
| infinity | `0x7C00` / `0xFC00` | `0x7F7FFFFF` / `0xFF7FFFFF` | **±FLT_MAX, symmetric** |
| NaN | `0x7E00` / `0x7C01` / `0xFE00` | `0x7F800200` / `0x7F800001` / `0xFF800200` | `{sign, 8'hFF, 13'b0, mant[9:0]}` |
| NaN, `nan_to_zero` | `0x7E00` / `0xFE00` | `0x00000000` / `0x00000000` | both signs zeroed |
| inf, `nan_to_zero` | `0x7C00` | `0x7F7FFFFF` | **unaffected** — inf is not NaN |

**The subnormal result is a second derived quantity**, alongside the exact
product of F5. Every binary16 subnormal is a *normal* binary32 value, so an
implementation that shuffles the exponent and mantissa fields across is wrong:
the mantissa must be normalised and the exponent adjusted by the leading-zero
count. A field-copying converter passes every normal value and fails only in the
ten subnormal exponents.

That is now clause F7 in `spec/sdp_requant_iface.sv`, and it was not in the
landscape's mechanism list — which named four mechanisms, of which measurement
refuted one, rewrote one, and missed both of the derived quantities that make
this task worth setting.

## d_ai04's own records understate it in three places. 2026-08-27

First checkpoint on returning to this task. **Nothing was built. What was found
is that three records disagree with the tree, all in the same direction.**

| record | says | measured |
|---|---|---|
| `task.yaml` `ppa_status` | "THE REFERENCE Fmax SWEEP HAS NOT BEEN RUN" | `fmax_results/d_ai04_fmax.json` and `d_ai04_logs/` exist; G1 pins 33.75 ns from a measured 22.5 ns; `check_pin` reports `33.75 / 22.5 / 33.75 ok`; **a PPA record at the pin already exists** |
| `task.yaml` `submissions_status` | "NOT YET SOLICITED. No submission exists" | `candidates/d_ai04/` holds `chat.sv`, `claude.sv`, `gemini.sv`; **all three have sim records and all three PASS** |
| `TASK_CATALOG.md` row | "No PPA until its reference Fmax sweep sets the pin — G1 records it NOT YET SET" | G1 carries the pin and its full derivation, including `ceil(1.5 x 22.5 / 0.25) x 0.25 = 33.75` |

**Every one understates.** Fourth, fifth and sixth instances of the class filed
this week, and the first three found on a task the author had not touched since
writing them. The direction has not varied once across three tasks and roughly
two dozen sites.

**These are not cosmetic.** `ppa_status` is what a PPA owner reads to decide
whether a number may be recorded, and it says no while a record sits in `runs/`.
`submissions_status` is what anyone reads to decide whether to solicit, and it
says no submission exists while three passing ones sit in `candidates/`.
Soliciting again on that basis would have produced a fourth for no reason.

The two `task.yaml` fields are marked at the site, dated, with the original text
kept below the marker. The catalog row is a shared document and is reported
rather than edited.

### What is actually outstanding on d_ai04

Measured, not inferred, so the next checkpoint starts from a true statement:

    spec, ref, scoring tb, prompt, task.yaml   BUILT
    nine negative controls                     BUILT, all nine FAIL, reference PASSES
    reference Fmax sweep and G1 pin            DONE, 33.75 ns, check_pin ok
    reference PPA at the pin                   RECORDED
    three candidates                           SOLICITED, RUN, ALL PASS
    mutants/                                   ABSENT
    conformant/                                ABSENT
    task.yaml mutants: block (rule 21)         ABSENT
    candidate PPA at the pin                   not present for chat/claude/gemini

So the remaining design-side work is the mutant set and the conformant set — and
under Rule 21 each mutant must carry a recorded evidence TYPE, `witness` or
`bmc_cex`, not merely a kill.

## Re-scored at the current hash, and the re-solicitation reason is not correctness. 2026-08-28

The three candidates carried `task_text_hash 6254d37b17244bb0`; the current text
is `203bc8a580aa44d4`. Re-scored:

    chat    203bc8a580aa44d4  1/1  PASS   0 compile warnings
    claude  203bc8a580aa44d4  1/1  PASS   0 compile warnings
    gemini  203bc8a580aa44d4  1/1  PASS   0 compile warnings

**Correctness is unchanged and now current.** Three of three, at the text as it
stands.

**BUT THEY STILL NEED RE-SOLICITING, AND THE SPEC ALREADY SAYS WHY.** G1's own
paragraph records it: *"the three candidates solicited for this task were written
against it — they were told the target frequency was unknown — and are
re-solicited for that reason rather than because anything about the contract
changed."*

Nothing behavioural moved between the two hashes. The single change was G1's
pinned-period paragraph, from "THE PINNED PERIOD IS NOT YET SET ... no PPA number
may be reported" to 33.75 ns with its derivation. **A submitter told the frequency
target is unknown makes different area/timing tradeoffs than one told 33.75 ns**,
and that is a design input even though it is not a correctness clause.

### AND THIS UNDERCUTS THE DIFFICULTY-FLOOR MEASUREMENT I PROPOSED

I proposed deciding whether d_ai04 sits below the difficulty floor by building
the three candidates' PPA at the pin and looking for spread: tight cluster means
floor, spread means the band worth measuring.

**That measurement is compromised on these three submissions.** They were written
without a frequency target. A tight PPA cluster would then be consistent with two
different explanations — the task is easy, or nobody was optimising toward
anything — and the measurement cannot separate them. Spread would still be
informative; absence of spread would not be.

So the floor question needs the RE-SOLICITED set, not this one, and the order is:
re-solicit against `203bc8a580aa44d4` → score → PPA at 33.75 ns → then read the
spread. Building PPA on the current three first is not wasted (it is a reference
point and Agent 1 has it queued) but it cannot answer the floor question on its
own, and I should not have offered it as though it could.
