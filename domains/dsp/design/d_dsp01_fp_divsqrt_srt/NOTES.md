# d_dsp01 `fp_divsqrt_srt` -- **WITHDRAWN**

**Status: withdrawn, not deferred. This task has no `task.yaml` and must never
acquire one.** The directory is kept because it is the evidence.

## Why

The contract is bit-exact IEEE-754 binary32 divide and square root across all
five rounding modes with full subnormal support. The anchor --
`cvfpu/fpnew_divsqrt_multi` over `fpu_div_sqrt_mvp/div_sqrt_top_mvp`, the only
FP divider vendored in `refs/` -- **implements none of the five correctly.**

Reproduce:

```bash
python3 tb/audit/ieee754_model.py vectors/vectors.hex
```

```
model self-validation vs binary64 (RNE): n=180 disagreements=0

  driven |     RNE     RTZ     RDN     RUP     RMM       n
     RNE |   0.900   0.772   0.744   0.611   0.900     180
     RTZ |   0.698   1.000   0.736   0.604   0.698     182
     RDN |   0.737   0.715   0.419   0.914   0.737     186
     RUP |   0.738   0.786   0.909   0.428   0.738     187
     RMM |   0.701   1.000   0.679   0.652   0.701     187

subnormal DIV results: 81/112 bit-exact
flag disagreements over in-range DIV: 200/922
```

RDN and RUP are swapped (`defs_div_sqrt_mvp` numbers its modes
`NEAREST/TRUNC/PLUSINF/MINUSINF`; `fpnew_pkg` numbers them `RNE/RTZ/RDN/RUP`,
and `fpnew_divsqrt_multi` wires `rnd_mode_q` to `RM_SI` with no remap). RMM has
no downstream encoding and truncates. RNE is wrong on 10% of cases even where
the encodings line up -- `1.0/15.0` returns `3d888888`, correct is `3d888889`,
and 16 of those 18 misses involve no subnormal at all. Full write-up: **F54**.

The encoding swap is fixable in the shim. **The RNE error and the subnormal
errors are not**, and they are the task.

## Why not narrow the contract

RTZ-only with flags out of scope is exactly what the anchor supports (RTZ scores
1.000, including subnormal results). It was rejected: the spec was pinned to
IEEE 754-2019 clause by clause *before* the reference was measured, and moving
it afterwards to whatever the artifact happens to do is fitting the contract to
the artifact. It would also delete most of the difficulty -- one rounding mode
and no exception flags.

## Why not retarget

* `fpnew_divsqrt_th_32` is present in `refs/cvfpu/src` and is correctly rounded,
  but `pa_fdsu_top`, `pa_fpu_dp` and `pa_fpu_frbus` are not vendored. No network.
* `fpnew_fma` is correct and fully vendored, but fp32 FMA is **`d_dsp02`**,
  already built and SCOREABLE.
* No other FP divider exists in `refs/` (`bsg_idiv_iterative` and `serdiv` are
  integer).

## What is kept, and why

| path | why it survives |
|---|---|
| `spec/fp_divsqrt_srt_iface.sv` | The contract is sound and clause-cited. It is reusable the day a conforming divider is vendored. Nothing in it is wrong. |
| `ref/fp_divsqrt_srt_ref.sv` | Carries the F53 fix and the width assertion. The worked example of a shim that binds an ascending mask safely. |
| `tb/audit/capture_vectors_tb.sv` | The rule-11 capture rig, and the corrected handshake -- see below. Directly reusable for `d_dsp03` and `v_dsp01`. |
| `tb/audit/ieee754_model.py` | **The thing that caught it.** Self-validating exact binary32 rounding model. |
| `vectors/vectors.hex` | 2110 captured vectors. The evidence, and the input side is good even though the expected side is not. |

## Two harness defects found on the way, both worth carrying forward

**1. The format mask selected FP4.** `FpFmtConfig` is `logic [0:NUM_FP_FORMATS-1]`
-- ascending -- and `NUM_FP_FORMATS` is 9 here. `{{(N-1){1'b0}}, 1'b1}` sets
index 8, which is a 4-bit float. The divider elaborated 4 bits wide, returned 0,
and asserted `Done` in the same cycle as the start. It ran, it handshook, and it
answered everything with zero. The only evidence was one `WIDTHTRUNC` line among
133 warnings. Fixed by binding by index and asserting the resulting width.
**F53.** `d_dsp03` and `v_dsp01` take the same mask type and will meet this.

**2. The capture rig's handshake missed a one-cycle result window.**
`do @(negedge clk); while (!ir);` waits before it tests, so it could not see a
ready that was already high, held `in_valid_i` through the whole operation, and
exited only at the completion cycle -- where the anchor's FSM re-asserts
`in_ready` while presenting the result. The second `do/while` then skipped the
single negedge inside the result window and hung.

The diagnostic lesson is the sharper half: `$fwrite` output is buffered and lost
when the watchdog `$finish`es, **so a stall at vector 2000 and a stall at vector
0 both present as an empty file.** Reading the code produced two wrong theories.
A `nvec` progress trace localised it in one run.

## Not done, deliberately

No scoring testbench, no negative controls, no second source, no `sim_candidate.sh`
arm, no `task.yaml`, no `probe/PASTE.md`, no `candidates/` entry. Building any of
them on a reference that is wrong in four modes of five would have produced an
apparatus that validated cleanly and scored the wrong answers -- mutants killed,
controls failing, second source adjudicated wrong, all of it green. That is the
whole point of **F54**.

## Catalog correction owed (I do not own `TASK_CATALOG.md`)

Row `d_dsp01` reads `| B | not started |` with anchor `PULP fpu_div_sqrt_mvp +
cvfpu`. Two corrections:

1. **Class A, not B** -- both modules are vendored and elaborate clean. The
   difficulty was never availability.
2. **It should be marked withdrawn with a pointer to F54**, so it is not
   re-attempted. The anchor is not fixable from inside this repo.

Also relevant to whoever owns the catalog line proposing `fpnew_divsqrt` as a
**verification** task: that remains viable and is arguably now more attractive --
a unit with four known, characterised, reproducible conformance defects is a good
verification target. It is only as a *golden reference* that it is disqualified.
