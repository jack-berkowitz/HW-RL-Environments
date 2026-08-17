<!-- ===================================================================
     DELETE THIS HEADER BEFORE PASTING.

     Self-contained task file for v_dsp02. Everything below the marker is
     paste-ready: port map, specification, output requirements. No RTL, no
     repo paths, no reference to this project.

     Scoring, once the reply comes back, is the SAME THREE-WAY split as
     v_ca05 and v_nw03:
       (a) driver bug          -- e.g. withdrawing in_valid_i before the
                                  operation is accepted, or sampling the
                                  outputs without qualifying on out_valid_o
       (b) unpromised reliance -- checks something section 10 leaves open;
                                  compare against conformant/README.md
       (c) genuine spec gap    -- the specification really does not say
     Only (c) is a specification defect.

     THE CLAUSE TO WATCH is S4 with section 10. cvfpu, RISC-V and IEEE
     754-2008 return the non-NaN operand from min(NaN, x); IEEE 754-2019
     withdrew that and its replacement PROPAGATES the NaN. A model that
     knows the 2019 standard and not the RISC-V lineage will write the
     other answer. If it does so having read section 10, that is (b) and
     the citation is decorative. If section 10 stops it, the citation is
     load-bearing. That is the measurement this task exists for.

     Note before sending: port map and prose only, no RTL. Same standing
     caveat -- fine internally, licence review before external release.
     =================================================================== -->

============================ PASTE BELOW THIS LINE ============================

# Task: write a SystemVerilog testbench from a specification

You are given the **port map** and a **complete specification** for a hardware
module. **You will not be shown the RTL.** Write a self-checking testbench that
verifies the module against the specification.

Your testbench will be run against a known-correct implementation. It must
**pass**. It will also be run against faulty implementations, and a good
testbench catches those -- but passing the correct one comes first: a testbench
that rejects correct hardware is worthless regardless of what else it catches.

It will additionally be run against implementations that are **correct but
different** -- they make different choices wherever the specification is silent.
Those must pass too.

---

## Port map

```systemverilog
module fp_noncomp (
    input  logic        clk_i,
    input  logic        rst_ni,

    input  logic [31:0] operand_a_i,
    input  logic [31:0] operand_b_i,
    input  logic [1:0]  op_i,
    input  logic [2:0]  op_mode_i,

    input  logic        in_valid_i,
    output logic        in_ready_o,

    output logic [31:0] result_o,
    output logic [9:0]  class_mask_o,
    output logic [4:0]  status_o,

    output logic        out_valid_o,
    input  logic        out_ready_i
);
```

---

## Specification

## 0. Operations

`op_i` selects the operation and `op_mode_i` selects the variant within it.

| `op_i` | operation |
|---|---|
| `2'd0` | SGNJ — sign injection |
| `2'd1` | MINMAX |
| `2'd2` | CMP — comparison |
| `2'd3` | CLASSIFY |

*Authority: **a design decision recorded by this task. THIS ENCODING IS NOT A
STANDARD AND MUST NOT BE CITED AS ONE.*** RISC-V distinguishes these four
operations by opcode and `funct7`, not by any operation field, so no external
encoding exists to cite and none is inherited here. The values above are dense
and ordered as this document presents the operations; any other assignment would
have been equally correct, and a later reader looking for the authority behind
them will find only this paragraph.*

| `op_i` | `op_mode_i` | variant |
|---|---|---|
| SGNJ | `3'd0` | sign of the result is the sign of `operand_b_i` |
| SGNJ | `3'd1` | sign of the result is the **inverted** sign of `operand_b_i` |
| SGNJ | `3'd2` | sign of the result is the **XOR** of the two operands' signs |
| MINMAX | `3'd0` | minimum |
| MINMAX | `3'd1` | maximum |
| CMP | `3'd0` | less than or equal |
| CMP | `3'd1` | less than |
| CMP | `3'd2` | equal |
| CLASSIFY | any | `op_mode_i` is ignored |

*Authority: the RISC-V `funct3` field of the F extension —
`FSGNJ.S`/`FSGNJN.S`/`FSGNJX.S` are `000`/`001`/`010`, `FMIN.S`/`FMAX.S` are
`000`/`001`, and `FLE.S`/`FLT.S`/`FEQ.S` are `000`/`001`/`010`.*

**Combinations not listed above are never driven and their behaviour is
unconstrained** (§10.6).

---

## 1. Operand format

**A1.** Both operands are IEEE 754 binary32: bit 31 sign, bits 30:23 biased
exponent, bits 22:0 trailing significand.
*Authority: IEEE 754-2019 §3.4.*

**A2 — the canonical quiet NaN is `32'h7FC0_0000`.** Wherever this contract
requires a NaN result, it requires exactly that value.
*Authority: RISC-V, which defines a single canonical NaN for the F extension.
IEEE 754 does not mandate any particular NaN payload, so this is pinned rather
than inherited.*

**A3.** A NaN is **signalling** iff its exponent field is all ones, its
significand is non-zero, and bit 22 is `0`; it is **quiet** iff bit 22 is `1`.
*Authority: IEEE 754-2019 §6.2.1.*

---

## 2. SGNJ — sign injection

**S1.** The result takes bits 30:0 from `operand_a_i` **unchanged**, and its sign
bit from the variant selected by `op_mode_i` (§0). This holds for every operand
value, **including when `operand_a_i` is a NaN of either kind**: the payload is
copied through and is not canonicalised.
*Authority: RISC-V `FSGNJ.S` — the result takes all bits except the sign from
`rs1`.*

**S2.** SGNJ raises no exception flags, for any operand, including signalling
NaNs.
*Authority: RISC-V — the sign-injection instructions are non-arithmetic and do
not set floating-point exception flags.*

---

## 3. MINMAX

**S3 — both operands non-NaN.** The result is the lesser operand for minimum and
the greater for maximum, under the ordering of §5.11 of IEEE 754-2019, with the
one addition that **−0.0 compares less than +0.0** for this operation. So
`min(−0.0, +0.0)` is `−0.0` and `max(−0.0, +0.0)` is `+0.0`, whichever order the
operands are presented in.
*Authority: RISC-V, which requires `FMIN`/`FMAX` to treat −0.0 as less than
+0.0. IEEE 754's general comparison predicate treats them as equal, so this is a
point where the two differ and RISC-V governs.*

**S4 — exactly one operand is NaN.** The result is the **other** operand,
whether the NaN is quiet or signalling.
*Authority: RISC-V `FMIN.S`/`FMAX.S`, which implement IEEE 754-2008
`minNum`/`maxNum`. See §10 — the 2019 replacement behaves differently and is out
of scope.*

**S5 — both operands are NaN.** The result is the canonical quiet NaN (A2),
regardless of either operand's payload or kind.
*Authority: RISC-V.*

**S6 — flags.** `NV` is raised **iff at least one operand is a signalling NaN**.
A quiet NaN operand raises nothing. No other flag is ever raised.
*Authority: RISC-V — `FMIN`/`FMAX` use quiet comparisons, so only a signalling
NaN is invalid.*

---

## 4. CMP — comparison

**S7.** `result_o` is `32'h0000_0001` when the comparison holds and
`32'h0000_0000` when it does not. Bits 31:1 are zero in both cases.
*Authority: RISC-V — the comparison instructions write a single-bit boolean into
an integer register.*

**S8 — less-than and less-than-or-equal are SIGNALLING comparisons.** If either
operand is a NaN of **either kind**, the result is false and **`NV` is raised**.
*Authority: RISC-V `FLT.S`/`FLE.S`, which are defined as signalling comparisons;
IEEE 754-2019 §5.11 `compareSignaling`.*

**S9 — equal is a QUIET comparison.** If either operand is a NaN, the result is
false; `NV` is raised **only if an operand is a signalling NaN**. A quiet NaN
operand produces false and no flag.
*Authority: RISC-V `FEQ.S`, which is defined as a quiet comparison; IEEE
754-2019 §5.11 `compareQuiet`.*

**S10.** `−0.0` and `+0.0` compare **equal**, and neither is less than the other.
Note that this differs from MINMAX (S3), where −0.0 is ordered below +0.0.
*Authority: IEEE 754-2019 §5.11 — comparison treats the two zeros as equal.*

**S11.** No flag other than `NV` is ever raised by CMP.
*Authority: IEEE 754-2019 — comparison is exact and cannot overflow, underflow,
or be inexact.*

---

## 5. CLASSIFY

**S12.** `class_mask_o` is **one-hot over ten bits**, describing
`operand_a_i` only. `operand_b_i` is ignored.

| bit | class | | bit | class |
|---|---|---|---|---|
| 0 | −infinity | | 5 | +subnormal |
| 1 | −normal | | 6 | +normal |
| 2 | −subnormal | | 7 | +infinity |
| 3 | −zero | | 8 | signalling NaN |
| 4 | +zero | | 9 | quiet NaN |

*Authority: RISC-V `FCLASS.S`, whose destination register uses exactly this bit
assignment.*

**S13.** CLASSIFY raises no exception flags, including for a signalling NaN
operand.
*Authority: RISC-V — `FCLASS` does not set floating-point exception flags.*

---

## 6. Exception flags

**S14.** `status_o` is `{NV, DZ, OF, UF, NX}`, with `NV` at bit 4 and `NX` at
bit 0. **`DZ`, `OF`, `UF` and `NX` are zero for every operation in this
contract**, on every operand: no operation here divides, rounds, or can leave the
representable range.
*Authority: the RISC-V `fflags` bit layout for the field order; IEEE 754-2019 for
the always-zero part — every operation in this contract is either
non-arithmetic or exact.*

Flags are reported **per operation**, alongside that operation's result. They do
not accumulate across operations.
*Authority: task intent — the port map exposes no accumulating status register
and no way to clear one.*

---

## 7. Handshake

**H1.** An operation is accepted on a rising clock edge where
`in_valid_i && in_ready_o`, carrying `operand_a_i`, `operand_b_i`, `op_i` and
`op_mode_i`.
*Authority: standard ready/valid handshake.*

**H2.** A result is delivered on a rising clock edge where
`out_valid_o && out_ready_i`, and **results are delivered in the order the
operations were accepted**.
*Authority: standard ready/valid handshake; the ordering requirement is task
intent, since the port map carries no tag with which a result could be matched
to an operation any other way.*

**H3.** `out_ready_i` may be low on any cycle, for arbitrarily many consecutive
cycles. No result shall be lost, duplicated or reordered as a result.
*Authority: standard ready/valid handshake.*

**H4 — source obligation (this constrains the TESTBENCH, not the design).** Once
`in_valid_i` is asserted it shall remain asserted, with all four operation inputs
held stable, until the operation is accepted. The design's behaviour if this is
violated is unspecified.
*Authority: standard ready/valid handshake — a source must not withdraw a
request before it is taken.*

---

## 8. Reset

**S15.** `rst_ni` is **synchronous and active low**. While `rst_ni` is low the
design shall be returned to an idle state. On the first cycle after release,
`out_valid_o` shall be low, and **no operation accepted before or during reset
shall produce a result afterwards.**
*Authority: polarity and synchronicity are fixed by the port map's `rst_ni`; the
discard requirement is task intent, stated because nothing else settles whether
work in flight survives a reset.*

---

## 9. Termination — a requirement on the submitted testbench

**S16.** The submitted testbench shall terminate on its own, unconditionally,
under every implementation it is run against, and shall include a watchdog that
reports failure and finishes after a generous time limit regardless of what the
design does.

The testbench will be run against deliberately faulty implementations. A
testbench that waits forever on one of them has not detected it — it has
stopped — and it blocks the grading run for everything queued behind it.
*Authority: stated task requirement.*

---

## 10. Named latitude

**The alternative this contract forecloses, and it is the important one.**

**S4 requires IEEE 754-2008 `minNum`/`maxNum` semantics, as RISC-V adopts them:
a quiet NaN operand is *ignored* and the other operand is returned.**

IEEE 754-2019 **withdrew** `minNum`/`maxNum` and replaced them with `minimum`
and `maximum`, which **propagate NaN**: under the 2019 operations,
`minimum(qNaN, 1.0)` is a NaN, not `1.0`. Both are defensible readings of "IEEE
minimum", they disagree on a case this contract exercises, and **the 2019
behaviour is out of scope.** A design implementing it fails S4, and a testbench
that expects it will reject correct hardware.

The remaining latitude — behaviour this contract does **not** constrain and a
testbench shall **not** check:

1. **Latency** between an operation being accepted and its result appearing.
   Unconstrained, and it may vary.
2. **`result_o`, `class_mask_o` and `status_o` while `out_valid_o` is low.**
   Unconstrained; they may hold, be zero, or be arbitrary.
3. **Promptness of `in_ready_o`.** It may be low on any cycle for any reason. A
   testbench shall not require it high merely because the design appears idle.
4. **`result_o` when `op_i` selects CLASSIFY.** The classification is delivered
   on `class_mask_o`; `result_o` is unconstrained for that operation.
5. **`class_mask_o` when `op_i` selects anything other than CLASSIFY.**
   Unconstrained.
6. **`op_mode_i` values not listed in §0 for the selected operation.** Never
   driven, and unconstrained.
7. **Internal structure** — pipeline depth, whether operations are pipelined at
   all, how the classifier is decomposed.

---
---

## What to produce

A single SystemVerilog file containing one module `fp_noncomp_tb` that
instantiates `fp_noncomp` and self-checks.

- The port map has **no parameters**; the format is binary32 and every width is
  fixed.
- **It must terminate on its own, unconditionally.** Include a watchdog: an
  independent `initial` block that reports failure and `$finish`es after a
  generous time limit, no matter what the design does.
- Print exactly one final line: `RESULT: PASS` or `RESULT: FAIL`.
- Print a diagnostic line per failure naming the requirement (`S1`...`S16`,
  `H1`...`H4`, `A1`...`A3`).
- It will be compiled with Verilator 5.x (`--binary --timing`). Keep to
  synthesisable-simulation SystemVerilog that Verilator accepts; queues and
  associative arrays are fine. Do not use UVM, `randsequence`, or DPI.
- Do not use `#` delays for anything except the clock generator and the
  watchdog.

Ground every check in a numbered requirement. If a behaviour is not specified
above, do not check it -- the implementation is free to choose, and a check on
an unspecified behaviour will reject correct hardware.

============================ PASTE ABOVE THIS LINE ============================
