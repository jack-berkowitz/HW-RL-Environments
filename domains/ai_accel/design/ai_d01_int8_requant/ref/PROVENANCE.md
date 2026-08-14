# ai_d01 `int8_requant` — provenance

## Oracle class: **B — local model of record**

Per `DESIGN_CATALOG.md` § Oracle classes. **No external RTL oracle exists for
this task, and none is claimed.** The statement "the testbench passes
known-correct external RTL" is *not available here* and is not made anywhere in
this task's artifacts.

The substitute guarantee is the three things the catalog requires, each
recorded here and in `NOTES.md`:

1. **The model is derived from the documented algorithm, not transcribed from a
   reference implementation.** `ref/model/int8_requant_model.py` implements the
   published gemmlowp/TFLite fixed-point requantisation primitives
   (`SaturatingRoundingDoublingHighMul`, `RoundingDivideByPOT`) written from
   their arithmetic definition in plain Python integer arithmetic. It was not
   transcribed from NVDLA RTL, from gemmlowp C++, or from any other
   implementation.
2. **The model, its generator, and the vectors are committed**, so the oracle is
   reproducible and auditable by a reader who distrusts it. Regenerate with
   `python3 ref/model/int8_requant_model.py --emit-vectors tb/vectors`, and
   check it against its own property suite with `--selftest`.
3. **Mutation testing carries the sharpness argument alone.** There is no second
   signal. See `NOTES.md` for the full mutant table with measured diff rates.

## What each file is

| file | role | authority |
|---|---|---|
| `model/int8_requant_model.py` | golden model + vector generator | **ORACLE OF RECORD** |
| `../tb/vectors/*.hex` | committed golden vectors | derived from the model |
| `int8_requant_ref.sv` | locally-authored RTL | **NO authority** — see below |

### `int8_requant_ref.sv` is not upstream RTL and not a port shim

Class B tasks have no shim, because there is no upstream module to bridge. This
file exists only so that (a) a checker PASS proves the harness actually runs
rather than merely compiles, and (b) the mutants have a base to be derived from
by one edit each.

Where this file and the Python model disagree, **the model is right by
definition and the RTL is broken.**

## Upstream consulted (never authoritative)

| repo | SHA | licence | how it was used |
|---|---|---|---|
| `nvdla/hw` | `8e06b1b9d85aab65b40d43d08eec5ea4681ff715` | NVDLA Open HW | **cross-check only** |

Pinned in `refs.lock`; vendored at `refs/nvdla_hw/vmod/nvdla/sdp/`.

NVDLA's SDP performs the same accumulate → bias → scale → shift → clamp chain
with a per-channel multiplier and right shift, and truncates to int8 with
saturation. **That structural agreement is the entire cross-check**: it confirms
the task describes real inference hardware and that the port shape is
plausible. It does **not** validate individual vectors, because NVDLA's rounding
behaviour is a configuration option and is not guaranteed to be the
round-half-away-from-zero rule this task specifies for step 2.

No NVDLA source was copied, adapted, or consulted while writing the model's
arithmetic.

## Spec ambiguity resolved

`DESIGN_CATALOG.md` describes the rounding as "round-half-away-from-zero". That
is **imprecise, and the imprecision is load-bearing.** The two steps of the real
algorithm use *different* tie rules:

* **step 1** (`DHIMUL`): ties round toward **+∞** (`+3.5 → +4`, `−3.5 → −3`)
* **step 2** (`RSHIFT`): ties round **away from zero** (`+1.5 → +2`, `−1.5 → −2`)

The catalog's phrase describes step 2 only. This was found by the model's own
self-test, which initially asserted sign-symmetry across the whole pipeline and
failed. Both rules are now pinned explicitly and normatively in
`spec/int8_requant_iface.sv`, so the checker only tests what the spec states.
Mutants `m01` and `m02` target one tie rule each.
