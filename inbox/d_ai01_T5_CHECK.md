# d_ai01 second source — the T5 check, specified for someone with the toolchain

**Target:** `inbox/d_ai01_second_source_fp16_gemm_array.sv`
**Status:** **NOT RUN.** `slang` is not installed on the authoring host
(`which slang` → not found). This is the one gate the artifact has not passed.

T5 is the clause that turns a bit-exact design into **no PPA number at all**,
with the cause surfacing much later as an unexplained mid-pipeline failure. It
is worth running before anything downstream consumes this file.

---

## 1. What to run

Two elaborations, one per legal HEIGHT. **No parameter-override flag is
needed** — that is the whole reason the wrappers exist, so there is no judgement
call about override syntax.

```bash
yosys -p "read_slang --top d_ai01_ss_slang_top_h4 inbox/d_ai01_second_source_fp16_gemm_array.sv inbox/d_ai01_second_source_slang_top_h4.sv"
```

```bash
yosys -p "read_slang --top d_ai01_ss_slang_top_h8 inbox/d_ai01_second_source_fp16_gemm_array.sv inbox/d_ai01_second_source_slang_top_h8.sv"
```

**The one thing I could not verify:** whether `read_slang` takes `--top` and the
file list in that argument order. The contract quotes the invocation only as
`yosys read_slang --top fp16_gemm_array`. If the order is wrong, yosys will say
so plainly — that is a *harness* error, not a result. Fall back to standalone
slang, which checks the same frontend:

```bash
slang --top d_ai01_ss_slang_top_h4 inbox/d_ai01_second_source_fp16_gemm_array.sv inbox/d_ai01_second_source_slang_top_h4.sv
```

Both files are self-contained: no packages, no includes, no search paths, no
`sim_flags`. `fp16_gemm_array` and its helper `fp16_fma_exact` are in the one
file, in that order.

## 2. What counts as a pass

**Both** invocations must exit **0** and report **0 errors** — for `read_slang`,
the string the contract quotes is `Build succeeded: 0 errors`.

A pass at HEIGHT=8 alone is **not** sufficient and neither is HEIGHT=4: the
unroll budget scales with `HEIGHT × WIDTH`, so H=8 is the one that can blow it
while H=4 passes. T3 requires both regardless.

Warnings are not failures. Record them, do not act on them.

## 3. What each failure means

| Output | Whose defect | What to do |
|---|---|---|
| `error: unroll limit of 4000 exhausted [--unroll-limit=]` | **Mine.** D4's 7×12 chunking was not enough. T5 is vindicated. | Reduce the per-instance iteration count further. **Do not raise `--unroll-limit` to make it pass** — that changes the gate, and the scored pipeline runs the default. |
| `error: declaration must come before all statements in the block` | **Mine.** A declaration escaped the top of its block. T5 is vindicated. | Hoist it to module scope. |
| exit **133**, trace/breakpoint trap, **no message** | **Neither, and it is a new finding.** T5 attributes this to a parameter declared with no default. This module declares `HEIGHT = 8` and `WIDTH = 8`, and the wrappers pass both explicitly — so the documented cause is excluded. | Record it. It means the crash has a second trigger T5 does not name. |
| An error naming a construct **T5 does not warn about** | **Possibly the clause's.** T5's enumeration would be incomplete. | Record the error verbatim before touching the RTL. This is the *only* failure mode here that is evidence against the clause rather than for it. |
| An error located in a `*_slang_top_h*.sv` wrapper and not in the RTL | **The wrapper's.** They are mine and disposable. | Discard the wrapper and use `-GHEIGHT=…` overrides on `fp16_gemm_array` directly. |
| **Anything about argument order, an unrecognised option, a file read as an option, `--top` not accepted, or "no such command"** | **The harness's. NOTHING ABOUT THE RTL.** | See §3a. **Do not record a T5 result.** Re-invoke per §3a and only then read the outcome. |

### 3a. The ordering case, stated separately so it cannot be misfiled

**This is the one failure mode that could be mistaken for a result, so it gets
its own heading.** I could not verify whether `read_slang` accepts `--top` and
the file list in the order given in §1 — the contract quotes the invocation only
as `yosys read_slang --top fp16_gemm_array`, with no file list shown.

If the invocation is malformed, yosys or slang will say so in terms that are
about the *command*, not about the design: unknown option, unexpected argument,
a source file being read as an option, `--top` not recognised, no such command.

**None of that is a T5 outcome.** It is not a failure of my RTL, it is not a
finding about clause T5, and it must not be recorded as either. A build that
never elaborated the design has measured nothing — the same principle as rule 6
and G2's withheld PPA: an error from a run that did not do the work is not a
result about the work.

What to do, in order:

1. Try the standalone `slang` invocation in §1. It takes `--top` followed by
   source files and is the same frontend.
2. If that also refuses, drop the wrappers entirely and elaborate
   `fp16_gemm_array` directly with parameter overrides — the module carries
   defaults (`HEIGHT = 8`, `WIDTH = 8`), so `--top fp16_gemm_array` with no
   override already exercises HEIGHT=8, and only HEIGHT=4 needs one.
3. Only once the tool has actually elaborated the design do §3's rows apply.

The tell is simple: **if the message names a construct, a line number, or a file
in the design, it is a result. If it names an option or an argument, it is the
harness.**

**Read the asymmetry.** T5 is unusually well specified — it names the exact
error strings, the mechanism, and the reproduced history. So a T5 failure here
is almost certainly a defect in my RTL and counts as evidence **for** the
clause. Only the fourth row generates a finding about the text. I do not expect
this clause to be the one that produces one.

## 4. Constraint on any repair

A T5 fix is a **build** fix, not a behaviour fix, and the pre-commitment stands:
nothing about the delivered values may change. Anything that alters `z_o` or
`status_o` is out of scope for this repair and must come back to a fresh reader.

Verify with the three probes that ship alongside — they drive this file only and
touch nothing in `tb/` or `ref/`:

```bash
verilator --binary --timing -Wno-UNUSEDSIGNAL -Wno-UNUSEDPARAM -Wno-DECLFILENAME --top-module clause_check -Mdir /tmp/ck inbox/d_ai01_second_source_fp16_gemm_array.sv inbox/d_ai01_second_source_probe_clauses.sv -o ck && /tmp/ck/ck
```

Expected, unchanged: **`clause_check: 59 checks, 0 failures`**.

```bash
verilator --binary --timing -Wno-UNUSEDSIGNAL -Wno-UNUSEDPARAM -Wno-DECLFILENAME -Wno-WIDTHEXPAND --top-module timing_probe -GH=4 -Mdir /tmp/t4 inbox/d_ai01_second_source_fp16_gemm_array.sv inbox/d_ai01_second_source_probe_timing.sv -o t4 && /tmp/t4/t4
```

Expected, unchanged: `d(k)` = **15, 11, 7, 3** at H=4 and **31, 27, 23, 19, 15,
11, 7, 3** at H=8; `dfb` = **16** / **32**; status delay **2** at every k;
`0 failures`. Same for `ctrl_probe` at both heights.

Do not edit the free-choice log or the frozen predictions in the RTL header
while repairing. They are dated evidence, not documentation.

## 5. Already done, for completeness

Verilator 5.046, the simulator of record, `--lint-only -Wall`, at both legal
heights and on both wrappers: **clean, zero warnings**. That is not a substitute
for §1 — the entire point of T5 is that Verilator accepts what slang rejects.
