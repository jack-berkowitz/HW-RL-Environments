# v_dsp02 `fp_noncomp` — evidence trail

**STATUS: BUILT AND SCOREABLE.** Reference ceiling **6 of 6**; golden passes,
5/5 conformant perturbations survive, 6/6 mutants are caught, each on exactly
one clause. Second DUT built and **unwired** — see §4.

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

## 7. Second DUT, and a declared difference that did not survive

`dut2/fp_noncomp_alt.sv`, **built and unwired** — the harness gates on the
declaration and never compiles or runs it. It passes the reference testbench;
zero rule-5 adjudications, the second task running.

Two of the three declared differences are internal mechanism (a monotone key map
and one unsigned compare against the anchor's compare-then-correct; a direct
one-hot classify decode against the anchor's separate classifier module).

**The third was declared, measured, and did not survive.** It claimed that
registering the outputs instead of the inputs would give a different handshake
timing. Over 3178 cycles with random backpressure, `in_ready_o` and
`out_valid_o` differ on **zero** cycles: cvfpu's ready path is combinational
through every stage, so moving the register changes nothing an external observer
can see. The record is kept rather than back-fitted, per `CONVENTIONS.md` —
differences named after the fact describe whatever got built.

**What survived was found by measuring, not by declaring.** The two disagree on
1450 cycles and *every* disagreement is inside the latitude:

| output | cycles differing | all of which |
|---|---|---|
| `result_o` | 333 | had op = CLASSIFY (§10.4) |
| `class_mask_o` | 1117 | had op ≠ CLASSIFY (§10.5) |
| `status_o` | 0 | — |

The second DUT drives zero on the unconstrained outputs where the anchor drives
datapath residue, so it probes §10.4 and §10.5 from the opposite side to `fn_c4`
and `fn_c5`. That is a stronger property than the difference originally claimed.

## 8. Reachability — the constraint this mutant set was built under

`v_nw03`'s risk was an unfalsifiable liveness claim. Here there is no liveness
property and an enormous corner space, so the opposite risk applies: **a mutant
nobody kills because the corner is unreachable from a spec-only reading.** Every
mutant targets a corner a clause NAMES; the mapping is in `mutants/README.md`.
None had to be retired, but the check is the point, not the outcome.

## 9. What the apparatus got wrong, and what found it

Four defects, **none found by reading**:

1. **The reference testbench drove a combination its own spec forbids.** Phase D
   issued MINMAX with `op_mode_i = 2`, which §0 never lists and §10.6 puts out of
   scope; the golden returned a don't-care value and the run failed. That is the
   testbench violating the contract, and it confirms §10.6 is load-bearing.
2. **The witness harness hung on the ready perturbation.** It polled
   `out_valid_o` from the driver instead of capturing on the transfer edge, so a
   perturbation that *delays acceptance* made it miss the one-cycle pulse. Now
   monitor-based.
3. **The witness harness could not see the idle-line perturbation, twice.**
   First because it compared only outputs while valid was high; then, after an
   idle-line counter was added, because the sink was permanently ready so the
   pipeline was never idle and there were no idle cycles to observe. Fixed by
   adding periodic idle windows.
4. **The paste-ready file carried a doubled `);`** — a syntax error every
   submission would have inherited, making each look like a model failure. Caught
   only by byte-comparing the port map against the golden and linting it.

`fn_m4` also needed a checker change to attribute correctly: S8 and S9 differ
only in whether the comparison is signalling, so attributing an NV mismatch by
operation alone named the wrong clause. It is now mode-dependent.

## 10. Ceiling

**6 of 6**, and the caveat from `v_nw03` is repeated here and **not
discharged**: one author wrote the spec, the checker and the mutants, so the set
has only been challenged by what that author anticipated. The first submission
is the real test.

---

## THE RECIPE: build the discriminating mutants in the first pass

Across three tasks and twenty-four scored submissions, **seven of the twelve
misses came from mutant sets added *after* a blind run**, and the two that
nothing has ever caught — `fn_m8_max_subnormal_is_normal` here and
`tt_m8_peek_removes_last` on the sibling task — are both the same shape.

**The shape: a mutant sitting exactly on the boundary between two states a
clause distinguishes.**

| mutant | the boundary it sits on |
|---|---|
| `fn_m8` | the largest subnormal against the smallest normal — adjacent classes in a ten-class table |
| `tt_m8` | a tag holding exactly one entry against a tag holding more |
| `fm_m9` | served within the stated window against served eventually |
| `tt_m10` | the cycle a store becomes full against the cycle after |

A design that is wrong *everywhere* is caught by anyone. A design that is wrong
*only on the boundary* is caught only by a testbench that went looking for the
boundary, and that is the discrimination the whole exercise is for.

**Consequences, and the second one is a constraint on spec writing:**

1. **The initial mutant set includes boundary-of-a-named-clause mutants.** Do
   not build six straightforward ones and retrofit the hard ones after a blind
   run — that cost three tasks a full extra cycle each, and the retrofit is
   where all the discrimination turned out to live.

2. **Prefer clauses stated as checkable bounds and as explicit boundaries
   between named states**, because those are the only clauses that can carry a
   discriminating mutant. A qualitative promise cannot: it yields a mutant
   everybody catches or one nobody can. `fm_m9` exists only because S10 was
   written as a 16-frame window instead of "no input is starved"; the two
   submissions that missed it had both implemented "eventually".

**The check to apply while writing each clause:** *could a design satisfy this
everywhere except at one boundary?* If yes, that boundary is a mutant. If no,
the clause is probably qualitative and will not discriminate.
## The difficulty pivot — every defect is now guarded by an ordinal

The previous set was total within its class: each defect fired on the FIRST
operation of the class it targeted, so any testbench that drove that class at
all caught it, whether or not it was checking the clause.

There is no occupancy or burst here to key a guard on — the unit is
combinational at the contract level. What it has is the sequence of operations,
and clauses that hold on every one of them. Each defect now fires only from the
Nth operation of its own class since reset.

### The thresholds were raised, and the signal for that was unambiguous

At ordinals of 2 to 5 the reference killed all ten **without any change to the
reference at all**. A guard that costs the reference nothing is shallower than
what the reference already does, and it is not measuring anything.

Raised to 4-10, `fn_m9` went out of reach: the +0/-0 equality pair was compared
only once or twice in passing by the pool sweep. The REFERENCE was extended to
drive it eight times rather than the guard dialled back. That is the right
direction whenever the reference can be made to get there; loosening the guard
is the fallback, not the fix.

