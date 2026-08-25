# H1b / R1b — final clause text, hash impact, re-solicitation

**AGENT-DESIGN-43a92055.** For Jack's decision to land the mirror clause. Nothing
in this file is landed; the clause texts below are the exact strings to insert.

---

## 1. The exploit, restated as measured rather than argued

Both clauses are **stability** clauses: *if the consumer stalls, the producer must
hold*. Neither says the producer must ever offer. A design that gates its output
`valid` on the consumer's `ready` does not violate the consequent — it makes the
**antecedent unsatisfiable**, and no other clause objects.

Measured on both tasks, with controls that are otherwise the reference verbatim:

| task | control | result |
|---|---|---|
| d_dsp02 | `nc_h3_evades_antecedent` | FAIL — `phase=final`, *"H3 was never exercised"*, and nothing else |
| d_ca01 | `nc_r1_evades_antecedent` | FAIL 0/16 — *"R1 was never exercised"* the only distinct failure across all sixteen configs |

Neither fails the clause it evades. Both fail only the vacuity floor, which is
the signature of a suppressed antecedent rather than a violated consequent.

**The d_ca01 case settles whether this is a real gap or a pedantic one**, because
the repository already contains the other half of the symmetry:

* `conformant/c02_ready_gated_on_valid.sv` gates `req_ready_o` on `req_valid_i` —
  the **input** side. **L5 explicitly permits it**, with a stated reason. It is
  filed as CONFORMANT and it passes 16/16, including with the new floor.
* `nc_r1_evades_antecedent` gates `rsp_valid_o` on `rsp_ready_i` — the **output**
  side. The identical construction. Nothing permits it and nothing forbids it.

One side of the same handshake has a clause and a control. The other has neither.
That is not a judgement about how a clause reads; it is an asymmetry in the
contract that can be pointed at.

---

## 2. Final clause text

### d_dsp02 — insert as **H1b**, immediately after H1

```
// H1b. `out_valid` MUST NOT depend combinationally on `out_ready`. The consumer
//      may hold `out_ready` low indefinitely, and a design that waits for it
//      before asserting `out_valid` deadlocks against a consumer that waits for
//      `out_valid` before asserting `out_ready`.
//
//      This is H1's rule with the roles swapped, and it is stated because H3 is
//      otherwise satisfiable by NEVER OFFERING: a result that is never presented
//      to a stalled consumer cannot be withdrawn from one. H3 constrains what
//      happens once a result is offered; H1b is what makes H3 reachable.
```

### d_ca01 — insert as **R1b**, immediately after R1

```
// R1b. `rsp_valid_o` MUST NOT depend combinationally on `rsp_ready_i`. The
//      consumer may hold `rsp_ready_i` low indefinitely, and a design that waits
//      for it before asserting `rsp_valid_o` deadlocks against a consumer that
//      waits for `rsp_valid_o` before asserting `rsp_ready_i`.
//
//      L5 PERMITS the mirror of this on the request side -- `req_ready_o` may
//      depend combinationally on `req_valid_i`, because the harness never
//      derives `req_valid_i` from `req_ready_o`, so no deadlock is reachable
//      there. The response side is not symmetric: the harness DOES derive
//      `rsp_ready_i` from its own state, and R1 is otherwise satisfiable by
//      never offering. `conformant/c02_ready_gated_on_valid.sv` is the permitted
//      construction; the same construction on this side is not permitted.
```

**Why R1b names L5 explicitly.** Without it the two clauses read as contradicting
each other — one permits gating `ready` on `valid`, the other forbids it — and a
submission would be right to ask which applies. The asymmetry is real and has a
reason, so the clause states the reason rather than leaving a reader to infer it.

---

## 3. Hash impact

Both edits are inside `spec/*_iface.sv`, which is inside `task_text_hash`
(`spec/` + `probe/PASTE.md`). **Both hashes move.** `probe/PASTE.md` must be
regenerated in the same commit or the shipped prompt and the spec disagree.

**Recompute at the point of use — every value below has been stale at least once
tonight.** The recorded values are wrong in three different ways:

| task | recorded in `task.yaml` | live at HEAD | state |
|---|---|---|---|
| `d_dsp02` | `530f3e4189421457` | **`8420f4393a0a930d`** | stale |
| `d_ca01` | *(no `task_text_hash` key at all)* | **`aab70a4bfcf132e7`** | **absent** |
| `d_ai01` | `86b7d95729381055` | **`2b7c36c5b08e7965`** | three boundaries behind |

The three boundaries `d_ai01` missed are `f19cd10` (14:54), `28803d8` (15:44) and
`4045b56` (15:58) — all yours, all today, all **G-section only**, so no A/L/P/T
clause moved and they are non-behavioural for correctness.

**Recommendation: fix the records in the same commit that lands the clauses.**
Landing H1b/R1b on task files that cannot say what question was last asked means
the new boundary has no correct predecessor to record.

---

## 4. Re-solicitation

| task | candidates on disk | needs re-solicitation | why |
|---|---|---|---|
| `d_dsp02` | chat, claude, gemini | **YES** — all three | H1b changes the shipped text |
| `d_ca01` | chat, claude, gemini | **YES** — all three | R1b changes the shipped text |
| `d_ai01` | chat, claude, gemini | **NO** — but see §5 | untouched by this decision |

**Zero of the six current submissions exploits the gap.** All three d_dsp02
candidates pass H3 with `h3_guard_true=60`. So this is closing a live hole before
anything walks through it, not correcting a scored result — and nothing needs
re-scoring for correctness, only re-soliciting against the new text.

**One caveat that is not an argument against landing it.** Both clauses forbid a
*combinational dependency*, which the testbench cannot observe directly — it sees
`out_valid` low and cannot distinguish "gated on ready" from "no result yet". The
vacuity floor catches it (both controls fail), but it catches it as *"the clause
was never exercised"*, not as *"you violated H1b"*. **The clause is enforceable by
inspection and by control, and only partially by the harness.** That is still
better than a clause nothing objects to at all, and it is honest to say so.

---

## 5. Blocking, and it is worse than H1b: `d_ai01` cannot be scored at all

Not part of this decision, and it needs to be settled before the d_ai01
re-solicitation you are already holding:

**`d_ai01` has never been runnable through the scored path, and has zero sim
records.** `spec/fp16_gemm_array_iface.sv` is 492 lines and **contains no code** —
every line is a comment. `sim_candidate.sh` derives the DUT module by grepping
`^module` in `spec/*_iface.sv`, gets nothing, resolves the testbench to
`tb/_tb.sv`, and refuses.

It refuses *correctly* — it declines rather than scoring whichever file sorts
first — which is why this surfaced at all. But it means every d_ai01 number on
record came from an ad-hoc run outside the scored path (F22's defect), including
all seven controls' verdicts and the second source's 4/10 and 6/13.

Two fixes, and they are owned differently:

* **The immediate unblock is a runner change, no hash move** — derive the DUT
  module from the task directory or the reference rather than from a spec that
  may ship no declaration. `AGENT-PPA-2381f2fe`'s file.
* **The spec question is mine.** Every other design task's `spec/*_iface.sv`
  declares the module and its ports; `d_ai01`'s describes them in a comment table
  instead. Fixing that moves the hash, so it should ride in one boundary with
  whatever else d_ai01 needs — not land separately.

This is the same defect as `d_ca03`: a task that had never been run on a path,
with results about to be collected from that path.
