# v_dsp02 `fp_noncomp` — evidence trail

**STATUS: PARTIAL.** Plumbing and specification are done and verified. The
reference testbench, second DUT, conformant set and mutant set are **not built**.
Nothing here is scoreable as a task yet, and the ceiling is unknown.

**Oracle class A.** Anchor `refs/cvfpu/src/fpnew_noncomp.sv`, PULP `cvfpu`,
SHL-0.51, sha `6e5267e2fe75198f91ef9304ddd56c0028eea526`.

---

## 1. Anchor — step 1 results

**Elaboration:** 16 configurations (`NumPipeRegs` 0–3 × `PipeConfig`
BEFORE/AFTER/INSIDE/DISTRIBUTED) at FP32, all exit 0 under Verilator 5.046.
Closure is `fpnew_pkg.sv` + `fpnew_classifier.sv` + `common_cells/registers.svh`.

**Semantic confirmation:** 30/30 directed known-answer cases drawn from RISC-V
semantics, no disagreements to adjudicate. All ten `fclass` classes; signed zero
under min/max; quiet-versus-signalling comparison; all three sign-injection
variants. The module is what the catalog claims over the corner space it claims.

**Provenance caveat.** Files present at the paths `refs.manifest.yaml` names, in
a repo `refs.lock` pins. Contents not verified against upstream at that SHA —
needs network, egress closed. Attests local state only.

### The anchor is modified in exactly one mechanical way

`dut/fpnew_noncomp.sv` is the anchor with its single
`` `include "common_cells/registers.svh" `` line replaced verbatim by that
file's contents. **`sim_verification.sh` passes no `-I` include path and the
verification half has no `sim_flags` equivalent**, so `dut/` has to be
self-contained. Verified mechanically: outside the inlined block the file is
line-for-line identical to the anchor with the include line removed, 526 lines
on both sides. A preprocessing step, not a semantic edit.

**Worth landing on the harness rather than repeating per task**: the design half
solved this with `ref/sim_flags_<sim>.txt` and the verification half never got
the equivalent. Every future verification anchor with an include will hit it.

---

## 2. The port map is flattened, and every field's authority is named

The anchor's ports carry package enums. Shipping the package would ship the
anchor's type names and its encodings, so the port map is flattened to plain bit
vectors. Rule 15 admits a standard clause, a stated task intent, or a recorded
design decision — and does not admit "because the anchor does it".

| field | authority |
|---|---|
| `op_mode_i[2:0]` | RISC-V `funct3` for the F extension. **Verified in the artefact**: the package encodes RNE/RTZ/RDN as `000`/`001`/`010` under a header reading "RISC-V FP-SPECIFIC", and the anchor's own comments say the sub-operation is selected "based on rm field". |
| `class_mask_o[9:0]` | RISC-V `FCLASS` rd bit assignment, verified bit-for-bit on all ten classes |
| `status_o[4:0]` | RISC-V `fflags`, `{NV,DZ,OF,UF,NX}` MSB first |
| `op_i[1:0]` | **no external authority exists** — see below |

### The four rule-15 flags, and what was done about each

1. **`operation_e`'s encoding has no authority.** RISC-V separates these four
   operations by opcode and `funct7`, not by an operation field. The anchor's
   own 5-bit enum places them at positions 10–13 of a list ordered by its
   internal unit grouping. Inheriting that would be inheriting an implementation
   detail. **This task decides its own encoding and records it as a decision**:
   0 SGNJ, 1 MINMAX, 2 CMP, 3 CLASSIFY.
2. **`RUP` on SGNJ is a fourth sign-injection variant with no RISC-V
   counterpart** — confirmed at step 1 to pass operand a through unchanged.
   **Not exposed**; §0 lists the legal `op_mode_i` values per operation and
   §10.6 puts everything else out of scope.
3. **`op_mod_i` has no authority** — it inverts the CMP boolean and selects
   integer sign-extension on SGNJ, neither backed by an instruction. **Tied off,
   not exposed.**
4. **`extension_bit_o`, `is_class_o`, `tag`/`aux`/`mask`, `busy_o`** are anchor
   pipeline plumbing with no external authority. **Not exposed** — a
   verification task must not ask a model to check signals whose contract cannot
   be stated. `is_boxed_i` has RISC-V NaN-boxing authority but is degenerate at
   FP32 in a 32-bit datapath, so it is tied high.

---

## 3. The rule-12 latitude item — the important clause

**S4 requires IEEE 754-2008 `minNum`/`maxNum` as RISC-V adopts them: a quiet NaN
operand is ignored and the other operand returned.**

IEEE 754-2019 **withdrew** `minNum`/`maxNum` and replaced them with `minimum`
and `maximum`, which **propagate** NaN — under the 2019 operations
`minimum(qNaN, 1.0)` is a NaN, not `1.0`. Both are defensible readings of "IEEE
minimum", they disagree on a case this contract exercises, and the 2019
behaviour is named out of scope in §10. Without that clause the spec would
silently inherit the anchor's choice, which is F14's exact shape.

**This is also the intended target of a mutant** when the set is built: the 2019
semantics implemented faithfully is a wrong answer under this contract, and it
is the most defensible wrong answer available.

---

## 4. Scored configuration (rule 18)

The port map declares no parameters. Bound inside the shim: `FpFormat=FP32`,
`NumPipeRegs=1`, `PipeConfig=BEFORE`, `op_mod_i=0`, `is_boxed_i=2'b11`.

`NumPipeRegs=1` is **not** the anchor's default of 0, and the reason is
load-bearing: at 0 the unit is combinational and `in_ready_o`/`out_valid_o`
degenerate into passthrough, so H1–H3 would have no state to be wrong about. One
stage makes the handshake a real contract term while leaving latency
unconstrained under §10.1.

---

## 5. The spec was checked against the artefact, not just written

Step 1 confirmed 30 cases. The specification then asserted five things step 1
had not covered, and each was verified through the **shim** — which also
exercises the flattened port map — before anything was built on top:

| clause | check | result |
|---|---|---|
| S1 | SGNJ on a **non-canonical** quiet NaN `7FD5A5A5` | `FFD5A5A5` — payload preserved, not canonicalised |
| S2, S13 | SGNJ and CLASSIFY on a signalling NaN | no flags raised |
| S14 | DZ/OF/UF/NX across **768** operations spanning 4 ops × 3 modes × 8 corner operands squared | zero throughout |
| H2 | three classify operations back to back | delivered in order |
| S15 | reset with an operation in flight and the output stalled | `out_valid_o` low after release |

`tb/audit/spec_conformance_probe.sv`. Writing a spec clause the golden does not
satisfy would have surfaced later as the reference testbench failing the
validity gate, and been read as a checker defect.

---

## 6. Wired into the scored path before content

`sim_verification.sh v_dsp02` resolves the task, builds the golden and runs a
placeholder testbench end to end. F22's order, not `d_dsp02`'s.

---

## 7. What is NOT built

Reference testbench, second DUT, conformant perturbations, mutant set,
`probe/BLIND_TB_TASK.md`. **No kill ceiling exists**, and the task must not be
described as scoreable.

**The failure mode to design against when the mutant set is built** is the
opposite of `v_nw03`'s. There the risk was an unfalsifiable liveness claim, and
the answer was a bounded window. Here there is no liveness property at all and
an enormous corner space, so the risk is **a mutant nobody kills because the
corner is unreachable from a spec-only reading**. Every clause above was written
to enumerate its corners explicitly — all ten classify classes, both NaN kinds
for every operation, both zeros in both orderings — so that a competent reader
knows which cases exist. A mutant must target a corner the specification names.
