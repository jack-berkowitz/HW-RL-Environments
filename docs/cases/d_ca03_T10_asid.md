# A frozen input, an unexercised clause, and a frontier model that fails it

**Case study — `d_ca03_sv39_mmu`, clause T10 / A10.**
Recorded by AGENT-DESIGN-43a92055. Every number below was reproduced from the
committed tree at the time of writing, not quoted from a report.

This is the first end-to-end case the benchmark has produced where the apparatus
argument closes: a defect in the *stimulus* concealed a clause, closing that gap
created a check, and a solicited frontier model fails the check. Each link is
separately checkable, and none of them is an opinion.

---

## The result

    chat.sv      PASS   1/1
    claude.sv    FAIL   0/1  -> "T10: the NON-GLOBAL page issued no page-table read"
    gemini.sv    SLANG  10 errors, not simulated

One of three solicited models fails on a clause that **did not exist a week ago**,
and could not have existed, because the stimulus could not reach it.

---

## Link 1 — the input was frozen, so the clause was unreachable

`d_ca03` pins **A10** from external authority:

> **A10. GLOBAL PAGES AND ASID.** A leaf with `G=1` is valid for every ASID. A
> leaf with `G=0` is valid only for the ASID current when it was installed.
> AUTHORITY: RISC-V Privileged Architecture.

A10 was in the contract, correctly stated, carrying a citation. And **nothing in
the scored sequence could tell whether a design implemented it.** Two independent
freezes, either of which alone would have been sufficient:

* **`asid_i` was driven at constant zero** for all 207 requests. With one ASID
  there is no second ASID to be wrong about.
* **The page-table constructor had no `G` argument at all** — PTE bit 5 was
  hardcoded to zero, so **no planted entry was ever global.**

So A10's two halves — "global works for every ASID" and "non-global works for
only one" — were *both* unreachable, for two different reasons, in a clause that
read as fully specified. A reader auditing the contract would have found A10
present, precise and sourced. A reader auditing the *stimulus* would have found
it untestable. Nobody was auditing the join.

**This is the general defect, and it is the reason for the whole apparatus: a
frozen input does not report a gap. It reports a pass.** Every check downstream of
`asid_i` returned "no failure", which is indistinguishable from "no test".

## Link 2 — the clause could not be scored on the delivered surface

Unfreezing `asid_i` is necessary and **not sufficient**, and the reason is
specific to this design:

> One page table serves every ASID here, because `satp_ppn_i` is fixed. So a
> design that ignores `asid_i` and reuses a stale non-global entry returns
> **exactly the same address** as one that re-walks.

The wrong design and the right design produce **identical output**. The
difference exists only in whether a page-table read happened — a `mem_*`
observation, not a T1-surface one. So A10 could not be enforced by comparing
results at all, which is presumably why nobody had noticed it was not being
enforced: the natural check is invisible.

**T10** was written as a stated exception to T2, scoring memory activity rather
than delivered values:

> After a flush, with a global leaf and a non-global leaf both installed under
> ASID 1:
> * the **GLOBAL** page, requested under ASID 2, must issue **NO** page-table read;
> * the **NON-GLOBAL** page, requested under ASID 2, **MUST** issue at least one.

Two directions, deliberately. A design that walks everything passes the second
and fails the first; a design that caches everything passes the first and fails
the second. Only a design that distinguishes `G=1` from `G=0` passes both.

## Link 3 — the model fails it

    claude.sv   FAIL   T10: the NON-GLOBAL page issued no page-table read

`claude`'s MMU **reuses a non-global TLB entry across an ASID change.** The
translation it returns is the same address the reference returns; on the T1
surface it is indistinguishable from correct. It is caught only because T10 reads
the memory port.

This is a **real functional defect**, not a formatting or interface failure. On
hardware running two address spaces it is a cross-process address leak: process B
receives process A's mapping because the entry was never invalidated for the new
ASID. It is the exact bug the RISC-V ASID mechanism exists to prevent.

`chat.sv` passes both directions.

---

## What the chain establishes

The links compose into an argument that no single link supports:

1. A clause can be **correct, precise, externally sourced, and completely
   unenforced.** A10 was all four.
2. The stimulus, not the contract, is where that hides — and a frozen input
   **reports a pass**, so the apparatus's own output is the thing concealing it.
3. Some clauses are **unenforceable on the delivered surface** and need an
   instrument aimed somewhere else. T10 reads `mem_*` because A10 is invisible in
   `lsu_paddr_o`. Without that exception the clause stays unscoreable no matter
   how good the stimulus is.
4. **A frontier model fails the clause once it is enforced.** That is what makes
   this a benchmark result rather than a housekeeping exercise: the gap was not
   theoretical, and closing it changed a verdict from PASS to FAIL for a real
   submission.

The counterfactual is worth stating plainly. Had the frozen `asid_i` never been
found, `claude.sv` would have been recorded as passing `d_ca03`, and the record
would have been **wrong in the direction that flatters the submission** — a clean
pass on a task whose contract explicitly requires the behaviour the design does
not implement.

---

## `gemini` and what it does *not* say about T5

`gemini.sv` is rejected by the synthesis frontend with 10 errors, the first at
line 113:

```systemverilog
always_comb begin
    lsu_perm_fault = 1'b0;
    lsu_perm_cause = 64'd0;

    logic R = lsu_hit_entry.pte_perms[1];   // <-- declaration after a statement
```

**T5 warns about an asymmetry, and this is not an instance of it.** T5 exists
because a design Verilator accepts can be rejected by slang, in which case a
bit-exact submission scores full correctness and produces no PPA number at all.
That is not what happened here. Declarations must precede statements in a
procedural block, and **both frontends reject this** — run with `--no-slang`,
Verilator fails too, at the same construct:

    COMPILE: %Error: sanitised_gemini.sv:113:11: syntax error, unexpected IDENTIFIER

So `gemini` is not a T5 case. It is invalid SystemVerilog that no tool accepts,
and calling it "rejected by slang" invites the reader to infer a
tool-disagreement story that the evidence does not support.

What T5 *did* buy is smaller and real: the gate reported the rejection **up
front, with the file and line**, instead of letting it surface later as an
unexplained missing PPA number. T5's value here is in **when** the failure was
named, not in catching an asymmetry that was not present.

**Scored honestly, `gemini` did not fail A10 or T10** — it never ran. Recording
it as a T10 failure would be counting a compile error as a functional result.

---

## Provenance

* Clause text: `domains/comp_arch/design/d_ca03_sv39_mmu/spec/sv39_mmu_iface.sv`,
  A10 at line 195, T9 at 483, T10 at 517. The freeze is documented in T10's own
  text: *"asid_i was driven at the constant zero for the whole sequence, and the
  page-table constructor had no G argument at all … A10 was pinned longhand and
  unexercised in both halves."*
* Stimulus: Sequence F, 207 requests, `vectors/vectors_sv39.hex`.
* Reference: PASS 207/207 at 1,269 cycles. Second source: PASS at 977 cycles.
* Verdicts reproduced with
  `scripts/sim_candidate.sh d_ca03 candidates/d_ca03/<model>.sv verilator`.
* **`d_ca03` was not simulable through the scored path until `084e87b`** — see
  F88. Three gaps, one of them mine: the task declared its cva6 closure in
  `orfs/config.mk` for synthesis and had no `ref/sim_flags_verilator.txt` for
  simulation. These are the first candidate verdicts this task has ever produced
  through the scored path.
