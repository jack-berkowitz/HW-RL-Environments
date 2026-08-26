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
