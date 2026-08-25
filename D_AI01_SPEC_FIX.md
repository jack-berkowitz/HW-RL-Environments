# d_ai01 spec fix — the port list, the PASTE.md consequence, and one question

**AGENT-DESIGN-43a92055.** For review before landing. Nothing here is landed.
Rides with H1b's boundary, since both hashes move anyway.

---

## What is wrong

`spec/fp16_gemm_array_iface.sv` is **492 lines and contains no code** — every
line is a comment. It is the only design spec in the repository that ships no
interface declaration. The ports exist as a table inside clause **V1**:

```
// V1. Ports, exactly:
//       clk_i               1
//       x_i                 [WIDTH][HEIGHT][16]   activations, per row per stage
//       ...
```

Two consequences, one already paid and one still open:

* **Paid.** `sim_candidate.sh` derived the DUT module by grepping `^module` in
  the spec, got an empty string, and refused. That is gap 1 of the four that kept
  d_ai01 off the scored path — now worked around by a task-directory fallback
  that prints its source, so the defect stays visible instead of becoming silent.
* **Open.** A submission is handed dimensions in prose and must reconstruct the
  declaration. All three candidates got the packed dimensions right, so this has
  not cost anything measurable — but "V1. Ports, exactly:" followed by a table is
  a weaker instrument than a declaration, and **the table and the reference could
  drift without anything noticing.** Nothing currently checks them against each
  other.

## The proposed addition

Appended to `spec/fp16_gemm_array_iface.sv`, after the clause text. **Copied
verbatim from `ref/fp16_gemm_array_top.sv`**, which is the artefact every
measurement was taken against — not retyped from V1's table, because the point is
to make the declaration authoritative rather than to add a second description:

```systemverilog
module fp16_gemm_array #(
  parameter int unsigned HEIGHT = 8,
  parameter int unsigned WIDTH  = 8
) (
  input  logic                                     clk_i,
  input  logic                                     rst_ni,
  input  logic [WIDTH-1:0][HEIGHT-1:0][15:0]       x_i,
  input  logic            [HEIGHT-1:0][15:0]       w_i,
  input  logic [WIDTH-1:0]            [15:0]       y_i,
  output logic [WIDTH-1:0]            [15:0]       z_o,
  input  logic [2:0]                               rnd_i,
  input  logic                                     accumulate_i,
  input  logic [WIDTH-1:0]                         row_clk_gate_en_i,
  input  logic                                     reg_enable_i,
  input  logic                                     flush_i,
  output logic [WIDTH-1:0][HEIGHT-1:0][4:0]        status_o
);
  // Declaration only. A submission replaces this module entirely.
endmodule
```

**Checked against V1's table, field by field: they agree.** Every width, every
packed dimension, every direction. So this addition changes no requirement — it
changes *where the requirement lives* and makes the runner able to read it.

## The PASTE.md consequence

`probe/PASTE.md` is the whole spec file inside one ```systemverilog fence
(lines 38–531). It is regenerated from the spec, so the diff is exactly the
addition above, arriving at the end of the fence. **No prose in PASTE.md changes
and no clause text moves.**

Net effect on a candidate reading the prompt: after `V1`'s table, they now also
see the declaration they are being asked to implement.

## Hash impact

Both files are inside `task_text_hash`, so the hash moves.

    recorded in task.yaml   86b7d95729381055     (three boundaries stale)
    live at HEAD            2b7c36c5b08e7965
    after this change       recompute at the point of use -- do not carry
                            a value quoted here

**The three boundaries d_ai01 already missed** — `f19cd10` 14:54, `28803d8`
15:44, `4045b56` 15:58, all yours, all G-section only, non-behavioural for
correctness — **should be recorded in `version_boundary` in the same commit.**
Landing a fifth boundary on a file that never recorded the previous three leaves
the new one with no correct predecessor.

## Is this behavioural? No — and that is checkable, not asserted

Nothing about the required behaviour changes. The declaration matches the table
the candidates already had and matches the reference they were scored against.
**The three existing candidates do not need re-scoring for correctness.**

They do need **re-soliciting**, because the shipped text changes and the hash is
what asserts "same question" — the same reason the d_dsp02 and d_ca01 candidates
need it for H1b. Timing them together is the whole argument for one boundary.

## The one question I am not deciding on my own

`ref/fp16_gemm_array_top.sv` declares `HEIGHT = 8, WIDTH = 8` as **parameter
defaults**. Putting that declaration in the spec makes those defaults part of the
shipped contract, and **P2 already names HEIGHT=8 as the scored configuration** —
so the two agree today.

They stop agreeing if the geometry ever moves. If the d_ai01 h4 probe comes back
clean and P2 goes to HEIGHT=4, the declaration's default must move with it, and
**there would then be two places stating the scored geometry.** `orfs/config.mk`
already carries a comment warning about exactly this drift, and it was itself
stale until tonight — it said the shim declares 16×16 when the shim declares 8×8.

Two options, and I would take the second:

1. **Ship the defaults as they are.** Simple, matches the reference exactly, and
   accepts a second place that has to move in step.
2. **Ship the declaration with no defaults** — `parameter int unsigned HEIGHT`,
   elaboration-time error if unset. The runner always passes a geometry, P1
   already says both 4 and 8 are legal, and T3 requires holding at both, so a
   default is a convenience the contract does not need. It removes the drift by
   removing the second statement of the scored geometry rather than by promising
   to keep two in step.

Option 2 costs a submission nothing — it is always elaborated with an explicit
geometry — and it is the option that does not depend on anyone remembering.
